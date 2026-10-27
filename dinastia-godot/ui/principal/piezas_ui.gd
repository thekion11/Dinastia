class_name PiezasUI
extends RefCounted
## (fase 6, paso 7 del plan §7.1: sale de `Principal`, ui/principal_p3.gd, el 27-10-2026). `p` es la pantalla principal;
## sus miembros se usan como `p.x` y `Principal` conserva puentes de una línea con los nombres de siempre.

var p: Principal

func _init(principal: Principal) -> void:
	p = principal

func _limpiar(n: Node) -> void:
	for h in n.get_children():
		n.remove_child(h)
		h.queue_free()


# ---------------------------------------------------------------------------
#  EL TEMA DE LA PALETA
# ---------------------------------------------------------------------------
#
# `_panel()` pinta las tarjetas que crea el juego, pero NO pinta lo que dibuja
# Godot por su cuenta: el fondo de las pestañas, los botones, los desplegables,
# las barras. Eso sale del tema oscuro que trae el motor de fábrica, y con una
# paleta clara quedaba la mitad de arriba en crema y la mitad de abajo en gris
# oscuro, con el texto ya traducido a oscuro y por tanto ilegible.
#
# Se arregla en el sitio donde se arregla de verdad: un `Theme` colgado de la
# raíz. Baja por todos los hijos de golpe, así que las nueve paletas valen para
# la interfaz entera sin tocar ni una pantalla.
func _traducir_bbcode(bb: String) -> String:
	if Idiomas.idioma == "es":
		return bb
	if p._re_tramos_bb == null:
		p._re_tramos_bb = RegEx.create_from_string("\\]([^\\[]+)")
	var salida := bb
	for m: RegExMatch in p._re_tramos_bb.search_all(bb):
		var tramo := m.get_string(1)
		var limpio := tramo.strip_edges()
		if limpio == "":
			continue
		var tr_ := Idiomas.t(limpio)
		if tr_ != limpio:
			salida = salida.replace(tramo, tramo.replace(limpio, tr_))
	return salida
func _acento_de(c: Club) -> Color:
	if c == null:
		return Color("3fa06a")
	## El acento va POR SEPARADO del color del club si se ha elegido uno: es la
	## cuarta capa de la identidad -club, uniforme, escudo e interfaz-.
	var col := Color(c.color_acento())
	if col.get_luminance() < 0.10:
		return Color("e0e0e0")
	## Y si el color del club es muy apagado, se le sube la saturacion: un acento
	## que no se distingue del texto normal no es un acento.
	if col.s < 0.25:
		col.s = 0.45
	return col.lightened(0.15) if col.get_luminance() < 0.35 else col

func _caja(fondo: Color, borde: Color, radio: int, grosor: int) -> StyleBoxFlat:
	var e := StyleBoxFlat.new()
	e.bg_color = fondo
	e.border_color = borde
	e.set_border_width_all(grosor)
	e.set_corner_radius_all(radio)
	e.content_margin_left = 8
	e.content_margin_right = 8
	e.content_margin_top = 4
	e.content_margin_bottom = 4
	return e
func _boton(texto: String, accion: Callable, padre: Node = null) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(0, 32)
	## Un Button pide de ancho mínimo lo que mida su texto, y varios botones
	## largos en fila desbordan la ventana sin dar ningún error: solo se ve en
	## una captura. Con `clip_text` la fila puede encoger; el tooltip guarda el
	## texto entero para cuando no quepa.
	b.clip_text = true
	b.tooltip_text = texto
	## Con `clip_text` a secas un botón puede encoger hasta CERO y desaparecer:
	## la primera vez que se probó esto, la fila entera de acciones se quedó en
	## siete rayas de un píxel. El mínimo garantiza que siempre se lea algo.
	b.custom_minimum_size.x = 92
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	## Y el reparto del ancho va POR LARGO DEL ROTULO. Todos los botones de la
	## fila expandian igual, asi que "Guardar" sobraba sitio mientras "Temporada
	## siguiente" se quedaba en "Temporada s". Con esto cada uno pide lo suyo.
	b.size_flags_stretch_ratio = clampf(float(texto.length()) / 12.0, 0.95, 1.9)
	b.pressed.connect(accion)
	(padre if padre != null else p._botones).add_child(b)
	return b

## `padre` por defecto es `_ficha` -de ahí salió esta función, para la ficha
## del jugador-, pero cualquier otra pestaña con la misma "etiqueta … valor"
## puede pasar la suya. Pasarlo mal es un bug silencioso: sin error, la fila
## sale dibujada en el sitio equivocado y desaparece en el próximo repintado.
## Una fila "etiqueta ......... valor".
##
## La etiqueta se RECORTA si no cabe, y esa línea no es cosmética: sin ella un
## Label pide de ancho mínimo lo que mida su texto, ese mínimo sube por el
## HBoxContainer de columnas, y la tercera columna se sale de la ventana entera
## -el contrato y el sueldo del jugador salían cortados por el borde derecho-.
## El valor NO se recorta a propósito: es el dato, y un dato a medias engaña
## más que un dato que no cabe.
func _dato(etiqueta: String, valor: String, color: Color, padre: Node = null) -> void:
	var h := HBoxContainer.new()
	var a := p._texto(12, p.COL_SUAVE)
	a.text = etiqueta
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	a.clip_text = true
	a.tooltip_text = etiqueta
	h.add_child(a)
	var b := p._texto(12, color)
	b.text = valor
	## Aire a la derecha (s3; petición 6 de la sesión 2): la barra de
	## desplazamiento de la columna tapaba el final de la cifra.
	b.add_theme_stylebox_override("normal", Principal.AIRE_CIFRA)
	h.add_child(b)
	## Hueco a la derecha del ancho de la barra de desplazamiento: las columnas
	## van dentro de un ScrollContainer y su barra vertical tapaba el final del
	## valor («Rol actual» en Legado, cifras de finanzas).
	var hueco := Control.new()
	hueco.custom_minimum_size = Vector2(14, 0)
	hueco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(hueco)
	(padre if padre != null else p._ficha).add_child(h)

func _celda(g: GridContainer, texto: String, color: Color, derecha: bool = false, tam: int = 12) -> Label:
	var l := p._texto(tam, color)
	l.text = texto
	if derecha:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_child(l)
	return l

func _bloque(padre: VBoxContainer, titulo: String, ratio: float) -> VBoxContainer:
	var caja := p._panel()
	caja.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caja.size_flags_stretch_ratio = ratio
	padre.add_child(caja)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 12; v.offset_top = 10; v.offset_right = -12; v.offset_bottom = -10
	caja.add_child(v)
	var t := p._texto(11, p.COL_SUAVE); t.text = titulo
	t.set_meta("titulo_bloque", true)
	v.add_child(t)
	return v
