class_name TablaCompeticion
extends RefCounted
## Pinta la columna "TABLA DE POSICIONES" del hub central: liga, grupo
## continental o cuadro de eliminatoria, según qué se esté jugando ahora
## mismo. Antes eran cinco funciones de `principal.gd`
## (`_pintar_tabla`/`_mi_grupo_nombre`/`_pintar_grupo`/`_pintar_cuadro`/
## `_pintar_tabla_liga`, ~115 líneas) sacadas tal cual, sin cambiar una coma
## de lo que pintan -esto es modularización, no reescritura-.
##
## PATRÓN DISTINTO AL DE `PanelMercado`, A PROPÓSITO (25-9-2026, pedido del
## usuario: "modular y mejorar el código... para que no sea tan frágil").
## Esto NO tiene estado propio, ni filtros, ni un botón que cambie nada -es
## pintar una tabla a partir de datos, punto-. Convertirlo en un nodo de
## escena con `inicializar()`/`pintar()`, como `PanelMercado`, habría sumado
## un ciclo de vida (¿cuándo se instancia? ¿quién lo libera? ¿qué pasa si se
## repinta dos veces seguidas antes de que el primer `queue_free()` corra?)
## para un caso que no lo necesita. Por eso es una clase ESTÁTICA
## (`RefCounted`, nunca se instancia) con funciones puras: reciben datos,
## devuelven o pintan, no guardan nada entre llamadas. Es la misma idea que
## ya usan `Escudo`/`Marca`/`Nombres` en este proyecto -no todo lo que se
## saca de `principal.gd` tiene que volverse un componente de interfaz-.
##
## `paleta`: los colores YA RESUELTOS -pasados por `_color_accesible()` y
## `_pal_*()` en Principal-, para que esta tabla respete el modo daltónico y
## el tema activo sin tener que conocer ninguno de los dos por su cuenta.
## Es la lección del bug de coherencia visual del propio 25-9: `PanelMercado`
## se conectó primero con los colores en crudo y hubo que corregirlo después;
## aquí se hace bien desde el principio.
##   {"suave", "texto", "acento", "verde", "rojo", "escala"}
##
## Los nombres se pintan tal cual: lo legal se resuelve en los DATOS (base
## ficticia por defecto, pack real opcional -ver `Datos`-), no en cada pantalla.

## Qué título le corresponde a la columna. Vive FUERA del `VBoxContainer` que
## pinta `pintar()` -el título no se mueve con el scroll, por diseño de
## `Principal._columna()`-, así que Principal se lo escribe a su Label fijo
## por separado, con el mismo dato.
static func titulo_de(mundo: Mundo, liga: Liga, mio: Club) -> String:
	if not mundo.partido_de_copa().is_empty() and mundo.copa != null:
		return mundo.copa.nombre.to_upper() + "  ·  " + mundo.copa.nombre_de_ronda().to_upper()
	var mi_conti := mundo.mi_continental()
	if Continental.toca_ronda(mundo.semana) >= 0 and mi_conti != null and mi_conti.en_curso():
		var nombre_c := Continental.nombre_conti(mi_conti.clave).to_upper()
		if mi_conti.en_fase_de_grupos():
			return "%s  ·  %s" % [nombre_c, _mi_grupo_nombre(mi_conti, mio)]
		return "%s  ·  %s" % [nombre_c, mi_conti.nombre_de_ronda().to_upper()]
	return liga.nombre.to_upper()

## El cuerpo de la columna: la tabla, el grupo o el cuadro, según toque. El
## orden de las comprobaciones es EL MISMO que usa `Principal._dirigir()` para
## decidir qué partido se juega -si los dos dijeran cosas distintas, la tabla
## mentiría sobre qué es lo que viene el domingo-.
static func pintar(lista: VBoxContainer, mundo: Mundo, liga: Liga, mio: Club,
		paleta: Dictionary) -> void:
	if not mundo.partido_de_copa().is_empty() and mundo.copa != null:
		_pintar_cuadro(lista, mundo.copa.vivos, mundo.copa.emparejamiento_de(mio), mio, paleta)
		return
	var mi_conti := mundo.mi_continental()
	if Continental.toca_ronda(mundo.semana) >= 0 and mi_conti != null and mi_conti.en_curso():
		if mi_conti.en_fase_de_grupos():
			_pintar_grupo(lista, mi_conti, mio, paleta)
		else:
			_pintar_cuadro(lista, mi_conti.vivos, mi_conti.emparejamiento_de(mio), mio, paleta)
		return
	_pintar_tabla_liga(lista, liga, mio, paleta)

static func _mi_grupo_nombre(t: Continental, mio: Club) -> String:
	for i in t.grupos.size():
		if (t.grupos[i] as Array).has(mio):
			return t.nombre_de_grupo(i).to_upper()
	return "FASE DE GRUPOS"

## La tabla de TU grupo, no la de los ocho: en fase de grupos lo único que
## decide tu vida son los tres rivales que te tocaron.
static func _pintar_grupo(lista: VBoxContainer, t: Continental, mio: Club,
		paleta: Dictionary) -> void:
	var indice := -1
	for i in t.grupos.size():
		if (t.grupos[i] as Array).has(mio):
			indice = i
	if indice < 0:
		_pintar_cuadro(lista, t.vivos, t.emparejamiento_de(mio), mio, paleta)
		return
	var g := _rejilla(lista, 6, paleta)
	for t2 in ["#", "CLUB", "PJ", "GF", "GC", "PTS"]:
		_celda(g, t2, paleta["suave"], t2 != "CLUB" and t2 != "#", 11, paleta)
	var puesto := 0
	for f: Dictionary in t.tabla_de_grupo(indice):
		puesto += 1
		var c: Club = f["club"]
		var propio := c == mio
		var color: Color = paleta["acento"] if propio else paleta["texto"]
		## Los dos primeros pasan: verlo en el color ahorra explicarlo.
		_celda(g, str(puesto), paleta["verde"] if puesto <= 2 else paleta["suave"], false, 12, paleta)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		fila.add_child(_escudo(c, 20))
		var nom := _texto(12, color, paleta)
		nom.text = c.nombre
		nom.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fila.add_child(nom)
		g.add_child(fila)
		for v in [f["pj"], f["gf"], f["gc"], f["pts"]]:
			_celda(g, str(v), color, true, 12, paleta)

## El cuadro de una eliminatoria: quién sigue vivo y contra quién juegas tú.
## No hay tabla que enseñar -en un torneo a un partido no existen los puntos-,
## así que lo que se enseña es lo único que importa: quién queda.
static func _pintar_cuadro(lista: VBoxContainer, vivos: Array, mi_par: Array,
		mio: Club, paleta: Dictionary) -> void:
	_limpiar(lista)
	if mi_par.size() == 2:
		var rival: Club = mi_par[1] if mi_par[0] == mio else mi_par[0]
		var t := _texto(11, paleta["oro"], paleta)
		t.text = "TU PARTIDO" + ("  ·  EN CASA" if mi_par[0] == mio else "  ·  FUERA")
		lista.add_child(t)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		lista.add_child(fila)
		fila.add_child(_escudo(rival, 28))
		var nr := _texto(15, paleta["texto"], paleta)
		nr.text = rival.nombre
		nr.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fila.add_child(nr)
		_dato(lista, "Reputación", "%d  contra tus %d" % [rival.rep, mio.rep],
			paleta["rojo"] if rival.rep > mio.rep else paleta["verde"], paleta)
		lista.add_child(HSeparator.new())
	var te := _texto(11, paleta["suave"], paleta)
	te.text = "SIGUEN VIVOS  (%d)" % vivos.size()
	lista.add_child(te)
	for c in vivos:
		var f2 := HBoxContainer.new()
		f2.add_theme_constant_override("separation", 6)
		lista.add_child(f2)
		f2.add_child(_escudo(c, 20))
		var n2 := _texto(12, paleta["acento"] if c == mio else paleta["texto"], paleta)
		n2.text = c.nombre
		n2.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		f2.add_child(n2)

static func _pintar_tabla_liga(lista: VBoxContainer, liga: Liga, mio: Club,
		paleta: Dictionary) -> void:
	var g := _rejilla(lista, 7, paleta)
	for t in ["#", "CLUB", "PJ", "G", "E", "P", "PTS"]:
		_celda(g, t, paleta["suave"], t != "CLUB" and t != "#", 11, paleta)
	var puesto := 0
	for f: Dictionary in liga.tabla():
		puesto += 1
		var c: Club = f["club"]
		var propio := c == mio
		var color: Color = paleta["acento"] if propio else paleta["texto"]
		_celda(g, str(puesto), paleta["acento"] if propio else paleta["suave"], false, 12, paleta)
		## Escudo y nombre en la misma celda: es lo que hace que la tabla se lea
		## de un vistazo, como una tabla de verdad y no una hoja de cálculo.
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		fila.add_child(_escudo(c, 20))
		var nom := _texto(12, color, paleta)
		nom.text = c.nombre
		nom.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fila.add_child(nom)
		g.add_child(fila)
		for v in [f["pj"], f["g"], f["e"], f["p"], f["pts"]]:
			_celda(g, str(v), color, true, 12, paleta)

# ── HELPERS DE UI, duplicados a propósito de `principal.gd` ────────────────
# Todos son puros: reciben datos y colores YA resueltos, no leen ningún
# estado de Principal. `escala` es `_escala_texto` -el tamaño de letra
# elegido en Ajustes-, que `PanelMercado` todavía no aplica (queda anotado
# como el mismo tipo de deuda que el bug de coherencia visual, para la
# próxima tanda que toque ese componente).

static func _texto(tam: int, color: Color, paleta: Dictionary) -> Label:
	var l := Label.new()
	var escala: float = float(paleta.get("escala", 1.0))
	l.add_theme_font_size_override("font_size", maxi(8, int(round(float(tam) * escala))))
	l.add_theme_color_override("font_color", color)
	return l

static func _limpiar(n: Node) -> void:
	for h in n.get_children():
		n.remove_child(h)
		h.queue_free()

static func _rejilla(lista: VBoxContainer, columnas: int, paleta: Dictionary) -> GridContainer:
	_limpiar(lista)
	var g := GridContainer.new()
	g.columns = columnas
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 3)
	lista.add_child(g)
	return g

static func _celda(g: GridContainer, texto: String, color: Color, derecha: bool,
		tam: int, paleta: Dictionary) -> Label:
	var l := _texto(tam, color, paleta)
	l.text = texto
	if derecha:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_child(l)
	return l

static func _dato(padre: Node, etiqueta: String, valor: String, color: Color,
		paleta: Dictionary) -> void:
	var h := HBoxContainer.new()
	var a := _texto(12, paleta["suave"], paleta)
	a.text = etiqueta
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	a.clip_text = true
	a.tooltip_text = etiqueta
	h.add_child(a)
	var b := _texto(12, color, paleta)
	b.text = valor
	h.add_child(b)
	padre.add_child(h)

## Blanco o negro sobre el color del escudo, según su luminosidad. Es el
## `lumTx` del HTML: sin esto, las iniciales de un club amarillo se leen en
## blanco y desaparecen. Puro -solo matemática de color-, cero riesgo al
## duplicarlo.
static func _tinta(fondo: Color) -> Color:
	var lum := 0.299 * fondo.r + 0.587 * fondo.g + 0.114 * fondo.b
	return Color("0c130e") if lum > 0.59 else Color("ffffff")

## El escudo de un club, calcado de `Principal._escudo()`. Depende solo de la
## clase estática `Escudo` y de matemática de color -nada de Principal-, así
## que duplicarlo es seguro y no crea una segunda fuente de verdad sobre CÓMO
## se ve un escudo, solo sobre dónde vive el código que lo arma.
static func _escudo(c: Club, alto: int = 22) -> Control:
	var caja := Control.new()
	caja.custom_minimum_size = Vector2(alto, alto)
	var t := TextureRect.new()
	t.texture = Escudo.textura(c, alto)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.add_child(t)
	var l := Label.new()
	var simbolo := Escudo.simbolo_de(c)
	if simbolo != "":
		l.text = simbolo
		l.add_theme_font_size_override("font_size", maxi(9, int(float(alto) * 0.55)))
	else:
		l.text = Escudo.iniciales(c)
		l.add_theme_font_size_override("font_size", maxi(8, alto / 2 - 2))
		l.add_theme_color_override("font_color", _tinta(Color(c.color1)))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.offset_top = -float(alto) * 0.10
	caja.add_child(l)
	return caja
