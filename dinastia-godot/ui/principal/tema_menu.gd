class_name TemaMenu
extends RefCounted
## (fase 6, paso 7 del plan §7.1: sale de `Principal`, ui/principal_p4.gd, el 27-10-2026). `p` es la pantalla principal;
## sus miembros se usan como `p.x` y `Principal` conserva puentes de una línea con los nombres de siempre.

var p: Principal

func _init(principal: Principal) -> void:
	p = principal

func _aplicar_tema() -> void:
	var t := p.theme if p.theme != null else Theme.new()
	## La fuente va en `default_font` del tema: baja por todo -etiquetas, botones,
	## pestanas, el registro- sin tener que decirselo a cada clase.
	t.default_font = p._fuente_de(p._tipografia)
	var panel := p._pal_panel()
	var texto := p._pal_texto()
	var suave := p._pal_suave()
	var borde := p._ui_ajustes._pal_borde()
	var forma: Array = Principal.FORMAS_TARJETA.get(p._forma_tarjeta, ["", 8, 1])
	var radio := int(forma[1])

	## El botón: un panel un pelo desplazado hacia el texto, para que se despegue
	## del fondo sin ser otro color. Encima aclara, pulsado se va al acento.
	var reposo := p._mezcla(panel, texto, 0.14)
	t.set_stylebox("normal", "Button", p._caja(reposo, borde, radio, 1))
	t.set_stylebox("hover", "Button", p._caja(p._mezcla(panel, texto, 0.24), borde, radio, 1))
	t.set_stylebox("pressed", "Button", p._caja(p._mezcla(panel, p.COL_ACENTO, 0.45), p.COL_ACENTO, radio, 1))
	t.set_stylebox("focus", "Button", p._caja(Color(0, 0, 0, 0), p.COL_ACENTO, radio, 2))
	t.set_stylebox("disabled", "Button", p._caja(p._mezcla(panel, texto, 0.05), borde, radio, 1))
	t.set_color("font_color", "Button", texto)
	t.set_color("font_hover_color", "Button", texto)
	t.set_color("font_pressed_color", "Button", texto)
	t.set_color("font_disabled_color", "Button", p._mezcla(suave, panel, 0.5))

	## Los desplegables y las casillas heredan del botón: en Godot son clases
	## distintas y si no se les dice nada se quedan con el tema oscuro de fábrica.
	for clase: String in ["OptionButton", "MenuButton", "CheckBox", "CheckButton"]:
		t.set_stylebox("normal", clase, p._caja(reposo, borde, radio, 1))
		t.set_stylebox("hover", clase, p._caja(p._mezcla(panel, texto, 0.24), borde, radio, 1))
		t.set_stylebox("pressed", clase, p._caja(p._mezcla(panel, p.COL_ACENTO, 0.45), p.COL_ACENTO, radio, 1))
		t.set_color("font_color", clase, texto)
		t.set_color("font_hover_color", clase, texto)

	## Las pestañas. El fondo de la hoja es EL panel, sin borde: encima van las
	## tarjetas, y dos bordes pegados uno dentro de otro se ven como un error.
	var hoja := p._caja(panel, borde, radio, 0)
	hoja.content_margin_left = 6
	hoja.content_margin_right = 6
	hoja.content_margin_top = 6
	hoja.content_margin_bottom = 6
	t.set_stylebox("panel", "TabContainer", hoja)
	t.set_stylebox("tabbar_background", "TabContainer", p._caja(Color(0, 0, 0, 0), borde, 0, 0))
	t.set_stylebox("tab_selected", "TabContainer", p._caja(p._mezcla(panel, p.COL_ACENTO, 0.30), p.COL_ACENTO, radio, 1))
	t.set_stylebox("tab_unselected", "TabContainer", p._caja(p._mezcla(panel, texto, 0.06), borde, radio, 1))
	t.set_stylebox("tab_hovered", "TabContainer", p._caja(p._mezcla(panel, texto, 0.18), borde, radio, 1))
	t.set_color("font_selected_color", "TabContainer", texto)
	t.set_color("font_unselected_color", "TabContainer", suave)
	t.set_color("font_hovered_color", "TabContainer", texto)

	t.set_stylebox("panel", "Panel", p._caja(panel, borde, radio, 1))
	t.set_stylebox("panel", "PanelContainer", p._caja(panel, borde, radio, 1))
	t.set_stylebox("panel", "PopupPanel", p._caja(p._mezcla(panel, texto, 0.05), borde, radio, 1))
	t.set_stylebox("panel", "PopupMenu", p._caja(p._mezcla(panel, texto, 0.05), borde, radio, 1))
	t.set_color("font_color", "PopupMenu", texto)
	t.set_color("font_hover_color", "PopupMenu", texto)

	## Los campos de texto. El fondo va al REVÉS que el botón -hacia el fondo, no
	## hacia el texto- porque un cuadro donde se escribe tiene que verse hundido.
	var hueco := p._caja(p._mezcla(panel, p._pal_fondo(), 0.55), borde, radio, 1)
	for clase2: String in ["LineEdit", "TextEdit", "SpinBox"]:
		t.set_stylebox("normal", clase2, hueco)
		t.set_color("font_color", clase2, texto)
		t.set_color("font_placeholder_color", clase2, suave)
		t.set_color("caret_color", clase2, p.COL_ACENTO)
	t.set_stylebox("focus", "LineEdit", p._caja(p._mezcla(panel, p._pal_fondo(), 0.55), p.COL_ACENTO, radio, 2))

	## Barras y deslizadores.
	t.set_stylebox("slider", "HSlider", p._caja(p._mezcla(panel, p._pal_fondo(), 0.5), borde, 3, 0))
	t.set_stylebox("grabber_area", "HSlider", p._caja(p.COL_ACENTO, p.COL_ACENTO, 3, 0))
	t.set_stylebox("grabber_area_highlight", "HSlider", p._caja(p.COL_ACENTO, p.COL_ACENTO, 3, 0))
	t.set_stylebox("background", "ProgressBar", p._caja(p._mezcla(panel, p._pal_fondo(), 0.5), borde, 3, 0))
	t.set_stylebox("fill", "ProgressBar", p._caja(p.COL_ACENTO, p.COL_ACENTO, 3, 0))

	t.set_color("default_color", "RichTextLabel", texto)
	t.set_color("font_color", "Label", texto)
	t.set_color("font_color", "ItemList", texto)
	t.set_stylebox("panel", "ItemList", p._caja(p._mezcla(panel, p._pal_fondo(), 0.4), borde, radio, 1))
	t.set_color("font_color", "Tree", texto)
	t.set_stylebox("panel", "Tree", p._caja(p._mezcla(panel, p._pal_fondo(), 0.4), borde, radio, 1))

	## La separación entre filas la sigue mandando la vista compacta: se vuelve a
	## poner aquí porque este `Theme` es el mismo objeto y el orden de llamadas
	## entre las dos funciones no está garantizado.
	var sep := Principal.SEPARACION_COMPACTA if p._vista_compacta else Principal.SEPARACION_NORMAL
	for clase3: String in ["BoxContainer", "VBoxContainer", "HBoxContainer"]:
		t.set_constant("separation", clase3, sep)
	p.theme = t
## Un escudo con sus iniciales encima, listo para meter en una fila.
##
## Las letras van FUERA del SVG porque el rasterizador de Godot no dibuja
## `<text>`: un SVG con texto carga sin error y sale sin las letras. Puestas
## como etiqueta encima quedan además más nítidas y con el color correcto según
## lo claro u oscuro que sea el escudo.
func _escudo(c: Club, alto: int = 22) -> Control:
	var caja := Control.new()
	caja.custom_minimum_size = Vector2(alto, alto)
	## Un escudo oscuro (club negro) desaparecía sobre el fondo oscuro: lleva detrás
	## un halo claro y redondo. Solo esos clubes: en las tablas son pocos nodos (s3).
	if EscudoMuestras.oscuro(c.color_escudo1()) and alto >= 16:
		var halo := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.86, 0.88, 0.92, 0.30)
		sb.set_corner_radius_all(alto)
		halo.add_theme_stylebox_override("panel", sb)
		halo.set_anchors_preset(Control.PRESET_FULL_RECT)
		halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caja.add_child(halo)
	var t := TextureRect.new()
	t.texture = Escudo.textura(c, alto)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.add_child(t)
	var l := Label.new()
	## EL SÍMBOLO ("ESC_SIM" del HTML) REEMPLAZA A LAS INICIALES, no se suman
	## las dos cosas -mismo "sym ? ... : ini" del HTML-. Es un emoji, así que
	## tampoco necesita el color de contraste que sí hace falta para que dos
	## letras se lean sobre cualquier fondo de escudo.
	var simbolo := Escudo.simbolo_de(c)
	if simbolo != "":
		l.text = simbolo
		l.add_theme_font_size_override("font_size", maxi(9, int(float(alto) * 0.55)))
	else:
		l.text = Escudo.iniciales(c)
		l.add_theme_font_size_override("font_size", maxi(8, alto / 2 - 2))
		## Contraste contra el FONDO REAL del escudo (`color_escudo1()`, que
		## respeta el color propio del escudo), no contra el color del club.
		l.add_theme_color_override("font_color", p._tinta(Color(c.color_escudo1())))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	## Las iniciales se suben un poco: el escudo es más alto que ancho y en el
	## centro geométrico quedan bajas respecto al centro visual.
	l.offset_top = -float(alto) * 0.10
	caja.add_child(l)
	return caja
## Abre el visor 3D del propio estadio, vacío -sin rival ni partido-, para
## mirarlo desde Club → Estadio en vez de tener que esperar al próximo partido
## en casa. Mismo patrón exacto que `partido_vivo._ver_estadio()`: se cuelga
## de la raíz y se libera solo al volver, `VistaEstadio` ya sabe dar tamaño a
## sí mismo. La ocupación de las gradas es la de verdad -la misma cuenta que
## usa el partido en vivo-, no un número fijo: un estadio medio vacío tiene
## que verse medio vacío también aquí.
## FUNDIDO DE ENTRADA (etapa 1, 8-10-2026): al abrir una escena 3D grande
## (ciudad, estadio, partido) la pantalla saltaba de golpe del menú al 3D, a
## veces con un fotograma a medio construir. Un velo negro por encima de todo
## que se aclara en medio segundo.
func _fundido_entrada() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 120
	p.get_tree().root.add_child(capa)
	var velo := ColorRect.new()
	velo.color = Color.BLACK
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(velo)
	var tw := velo.create_tween()
	tw.tween_interval(0.12)
	tw.tween_property(velo, "modulate:a", 0.0, 0.5)
	tw.tween_callback(capa.queue_free)
func _goleadores_de(clubes: Array) -> Array:
	var tiradores: Array = []
	for c: Club in clubes:
		for j: Jugador in c.plantilla:
			if j.goles > 0:
				tiradores.append({"nombre": j.nombre, "club": c.nombre, "goles": j.goles})
	tiradores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["goles"]) > int(b["goles"]))
	return tiradores.slice(0, 8)
## LO QUE ENSEÑA LA PANTALLA GIGANTE DEL ESTADIO (23-9-2026, pedido repetido:
## "una visualización de los puntos de la competencia... máximos goleadores").
##
## `VistaEstadio` es un VISOR: conoce clubes y partido, no el `Mundo` -y no
## debe conocerlo, igual que no conoce ni la economía ni el mercado-. Así que
## la tabla, los goleadores y los nombres se calculan aquí, que es donde el
## mundo está delante, y se le pasan ya masticados. Mismo patrón exacto que
## `perfil_estadio_de()` y `Comercial.color_balon()`, que ya viajaban así.
##
## `local` es el dueño del recinto: la tabla que se enseña es la de SU liga
## -un partido de copa entre divisiones distintas enseña la del anfitrión-,
## no la del club del usuario.
## `comp` (26-9-2026): "liga", "copa" o "conti". Antes la pantalla enseñaba
## SIEMPRE la liga del local, también en un partido de copa o de la copa
## continental; ahora enseña la competición que se está jugando.
func _datos_pantalla_estadio(local: Club, comp: String = "liga") -> Dictionary:
	var d: Dictionary = {
		"tabla": [], "goleadores": [], "liga": "", "jornada": 0, "recinto": "", "cruces": [],
	}
	if local == null or p.mundo == null:
		return d
	## El nombre propio del recinto solo vale para TU estadio: `mundo.estadio`
	## es el diseñador de tu club, y llamar a `nombre_de()` con un rival
	## devolvería el nombre que tú le pusiste al tuyo.
	if local.estadio_nombre != "":
		d["recinto"] = local.estadio_nombre
	elif local == p.mundo.mi_club() and p.mundo.estadio != null:
		d["recinto"] = p.mundo.estadio.nombre_de(local)
	else:
		d["recinto"] = "Estadio " + Nombres.visible(local.nombre)
	if comp == "copa" and p.mundo.copa != null:
		d["liga"] = "%s · %s" % [p.mundo.copa.nombre, p.mundo.copa.nombre_de_ronda()]
		for par: Array in p.mundo.copa.cruces():
			d["cruces"].append([Nombres.visible((par[0] as Club).nombre), Nombres.visible((par[1] as Club).nombre)])
		d["goleadores"] = _goleadores_de(p.mundo.copa.vivos)
		return d
	var conti := p.mundo.mi_continental()
	if comp == "conti" and conti != null:
		d["liga"] = "%s · %s" % [Continental.nombre_conti(conti.clave), conti.nombre_de_ronda()]
		if conti.en_fase_de_grupos():
			for gi in conti.grupos.size():
				if (conti.grupos[gi] as Array).has(local) or (conti.grupos[gi] as Array).has(p.mundo.mi_club()):
					d["titulo_tabla"] = "GRUPO " + conti.nombre_de_grupo(gi).to_upper()
					for f: Dictionary in conti.tabla_de_grupo(gi):
						var cg: Club = f["club"]
						d["tabla"].append({"id": cg.id, "nombre": cg.nombre, "pts": int(f["pts"]), "pj": int(f["pj"]), "dif": int(f["dif"])})
					break
		else:
			for par2: Array in conti.cruces():
				d["cruces"].append([Nombres.visible((par2[0] as Club).nombre), Nombres.visible((par2[1] as Club).nombre)])
		d["goleadores"] = _goleadores_de(conti.vivos)
		return d
	var l: Liga = p.mundo.liga_de(local)
	if l == null:
		return d
	d["liga"] = l.nombre
	d["jornada"] = l.jornada_actual
	var filas: Array = []
	for f: Dictionary in l.tabla():
		var c: Club = f["club"]
		filas.append({
			"id": c.id, "nombre": c.nombre, "pts": int(f["pts"]),
			"pj": int(f["pj"]), "dif": int(f["dif"]),
		})
	d["tabla"] = filas
	## Los goleadores de ESA liga, no del mundo entero: es la pantalla de ese
	## estadio, no un ranking global. Sin goles todavía (jornada 1) la lista
	## sale vacía y la pantalla simplemente no rota a ese panel.
	d["goleadores"] = _goleadores_de(l.clubes)
	return d

func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var e := StyleBoxFlat.new()
	## La paleta y la forma elegidas en Ajustes. Se leen aqui, en el unico sitio
	## por el que pasan todas las tarjetas del juego, para que cambiarlas repinte
	## la interfaz entera sin tocar ni una pantalla.
	e.bg_color = p._pal_panel()
	e.border_color = p._ui_ajustes._pal_borde()
	var forma: Array = Principal.FORMAS_TARJETA.get(p._forma_tarjeta, ["", 8, 1])
	e.set_border_width_all(int(forma[2]))
	e.set_corner_radius_all(int(forma[1]))
	panel.add_theme_stylebox_override("panel", e)
	## Marcada como tarjeta del juego. Media interfaz -las columnas, la cabecera,
	## la ficha- se construye UNA vez y luego solo se le cambia el contenido, asi
	## que cambiar de paleta no la tocaba: se queda esta marca para poder ir a
	## buscarlas y repintarlas sin reconstruir la pantalla entera.
	panel.set_meta("tarjeta", true)
	## El adorno del borde -escuadras, filete, cinta-. Va aqui y no en el
	## StyleBox porque un StyleBox solo sabe pintar un borde entero y uniforme.
	if p._marca_tarjeta != "ninguno":
		var mk := MarcaPanel.new()
		mk.poner(p._marca_tarjeta, p.COL_ACENTO)
		panel.add_child(mk)
	if not p._brillo_tarjetas:
		return panel
	var brillo := TextureRect.new()
	brillo.texture = p._textura_brillo_panel()
	brillo.set_anchors_preset(Control.PRESET_FULL_RECT)
	brillo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	## SIN esto, TextureRect pide como mínimo el tamaño NATIVO de la textura
	## (128px de alto) y estira el panel entero para dárselo -el brillo
	## crecía la tarjeta en vez de solo pintarla-.
	brillo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	brillo.stretch_mode = TextureRect.STRETCH_SCALE
	panel.add_child(brillo)
	return panel

func _con_scroll(padre: VBoxContainer) -> VBoxContainer:
	var s := ScrollContainer.new()
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	## AUTO y no DISABLED (etapa 1, 2.ª pasada): desactivado, una fila más ancha
	## que la columna AGRANDABA la columna entera y sacaba la ficha del jugador
	## de la pantalla (Editor, Libres). Ahora lo que no cabe se desplaza dentro.
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	padre.add_child(s)
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 2)
	s.add_child(lista)
	return lista
func _columna(padre: HBoxContainer, titulo: String, ratio: float) -> VBoxContainer:
	var caja := _panel()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.size_flags_stretch_ratio = ratio
	padre.add_child(caja)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 12; v.offset_top = 10; v.offset_right = -12; v.offset_bottom = -10
	caja.add_child(v)
	var t := p._texto(11, p.COL_SUAVE); t.text = titulo
	t.clip_text = true
	v.add_child(t)
	## Se deja a mano el último título creado para las columnas cuyo encabezado
	## cambia solo -la de la izquierda dice "PRIMERA DIVISION" o "COPA
	## LIBERTADORES · CUARTOS" según lo que se juegue el domingo-.
	p._ultimo_titulo_columna = t
	## `v` es la caja entera de la columna, por debajo del scroll: quien quiera
	## poner algo FIJO al pie -un botón que no se vaya con el desplazamiento-
	## lo cuelga de aquí.
	p._ultima_caja_columna = v
	return _con_scroll(v)

func _aplicar_fondo() -> void:
	if p._clima != null:
		p._clima.modo = p._clima_elegido
		p._clima.interactivo = p._clima_interactivo
		p._clima.ajustar_area(p.size if p.size.x > 0.0 else Vector2(1280, 720))
		p._clima.aplicar()
	if p._fondo_escena == null:
		return
	## EL FONDO ROTATIVO. El usuario pidió poder elegir entre uno fijo o que
	## "vaya cambiando". La rotación NO usa `Azar` -eso movería la simulación
	## entera, la trampa que ya costó una depuración con el feed de redes-:
	## sale de la semana de juego, que da un fondo distinto cada domingo,
	## siempre el mismo para la misma partida.
	if p._fondo_elegido == Principal.ROTAR_FONDO:
		var nombres: Array = Fondo.NOMBRES
		if nombres.is_empty():
			p._fondo_escena.texture = null
			return
		var i := (p.mundo.semana if p.mundo != null else 0) % nombres.size()
		p._fondo_escena.texture = Fondo.textura(String(nombres[i]))
		return
	p._fondo_escena.texture = Fondo.textura(p._fondo_elegido) if p._fondo_elegido != "" else null
func _con_contraste(c: Color) -> Color:
	var lf := p._pal_panel().get_luminance()
	## Con contraste alto, el salto mínimo de luminosidad es mayor.
	var salto := 0.6 if p._paleta == "contraste" else Principal.SALTO_LUMA
	if absf(lf - c.get_luminance()) >= salto:
		return c
	var destino := Color.BLACK if lf > 0.5 else Color.WHITE
	var r := c
	## Ocho pasos y se para. Si un color no llega ni al octavo -un gris exacto del
	## mismo tono que el panel- se devuelve el ultimo, que ya es lo mas separado
	## que se puede sin dejar de ser el mismo color.
	for i in 8:
		r = r.lerp(destino, 0.18)
		if absf(lf - r.get_luminance()) >= salto:
			return r
	return r
## Las dos mil llamadas a `_texto()` del juego piden COL_TEXTO o COL_SUAVE, que
## son claros porque el fondo por defecto es oscuro. Con una paleta CLARA -papel,
## cuaderno- ese texto quedaria blanco sobre blanco, invisible. Se traduce aqui,
## en el unico sitio por el que pasan todas las etiquetas, en vez de tocar dos mil
## llamadas: los colores con significado propio -el oro de un titulo, el rojo de
## una deuda- pasan de largo sin tocarse, que para eso son ellos los que informan.
func _color_de_paleta(c: Color) -> Color:
	if p._paleta == "bosque":
		return c
	if c == p.COL_TEXTO:
		return p._pal_texto()
	if c == p.COL_SUAVE:
		return p._pal_suave()
	## Los de FONDO son los de la paleta, no se «contrastan» (s3: pasaban por el
	## empuje de abajo, pensado para letras, y las píldoras salían gris claro con
	## letra blanca en cualquier paleta que no fuera la de por defecto).
	if c == p.COL_PANEL:
		return p._pal_panel()
	if c == p.COL_FONDO:
		return p._ui_ajustes._color_pal(1, p.COL_FONDO)
	if c == p.COL_BORDE:
		return p._ui_ajustes._pal_borde()
	return _con_contraste(c)
