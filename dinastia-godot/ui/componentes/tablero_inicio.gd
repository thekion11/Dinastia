class_name TableroInicio
extends RefCounted
## EL TABLERO DE INICIO (25-9-2026, repaso estético con Soccer Manager 2026 y
## FC delante). Antes, Inicio era una columna de textos: "PRÓXIMO COMPROMISO",
## cuatro recuadros con una cifra y listas. Los managers de hoy abren con un
## tablero de tarjetas que se leen de un vistazo: el próximo partido con los dos
## escudos, anillos de valoración, la cara de tu estrella, la racha en colores.
##
## Mismo patrón que el resto de `ui/componentes/`: clase estática que pinta una
## vez por refresco, y lo que hace cada tarjeta al pulsarla le llega como
## `Callable` desde `principal.gd` (que sigue siendo quien navega).

const COL_TARJETA := Tema.TARJETA
const COL_BORDE := Color("26352b")
const COL_TEXTO := Tema.TEXTO
const COL_SUAVE := Tema.SUAVE
const COL_ORO := Tema.ORO
const COL_VERDE := Tema.ACENTO
const COL_ROJO := Tema.MAL

## `ir`: Callable(pestaña: String). `ficha`: Callable(j: Jugador).
static func pintar(raiz: VBoxContainer, c: Club, mundo: Mundo, liga: Liga, ir: Callable, ficha: Callable) -> void:
	raiz.add_child(_tarjeta_partido(c, mundo, liga, ir))
	var g := GridContainer.new()
	g.columns = 3
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	raiz.add_child(g)
	g.add_child(_tarjeta_plantel(c, ir))
	g.add_child(_tarjeta_directorio(mundo, ir))
	g.add_child(_tarjeta_posicion(c, liga, ir))
	g.add_child(_tarjeta_caja(c, ir))
	g.add_child(_tarjeta_foco(c, ficha))
	g.add_child(_tarjeta_estadio(c, ir))
	raiz.add_child(_racha(c, liga))

# --- piezas -------------------------------------------------------------------

## Una tarjeta: panel redondeado que CRECE con su contenido (un Button no lo
## hace: el texto se salía de la tarjeta) y un botón transparente encima que
## la hace pulsable entera. Devuelve [tarjeta, vbox de contenido, botón].
static func _caja_tarjeta(ir: Callable, destino: String, alto: float = 112.0) -> Array:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, alto)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var e := StyleBoxFlat.new()
	e.bg_color = COL_TARJETA
	e.border_color = COL_BORDE
	e.set_border_width_all(1)
	e.set_corner_radius_all(12)
	e.shadow_color = Color(0, 0, 0, 0.25)
	e.shadow_size = 4
	e.content_margin_left = 12; e.content_margin_right = 12
	e.content_margin_top = 9; e.content_margin_bottom = 9
	panel.add_theme_stylebox_override("panel", e)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(v)
	var b := Button.new()
	b.flat = true
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.add_child(b)
	## Al pasar el ratón, el borde se enciende en oro.
	b.mouse_entered.connect(func() -> void: e.border_color = COL_ORO.darkened(0.25))
	b.mouse_exited.connect(func() -> void: e.border_color = COL_BORDE)
	if destino != "" and ir.is_valid():
		b.pressed.connect(func() -> void: ir.call(destino))
	return [panel, v, b]

static func _lbl(texto: String, tam: int, col: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	## Sin recorte: un Label que puede recortarse pide ancho mínimo cero y, en
	## una fila, se queda en nada (los nombres del partido desaparecían).
	return l

static func _titulo(v: VBoxContainer, texto: String) -> void:
	v.add_child(_lbl(texto, 11, COL_SUAVE))

## Fila "anillo + textos" que comparten varias tarjetas.
static func _fila_anillo(v: VBoxContainer, anillo: Control, grande: String, pie: String, col: Color) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(h)
	h.add_child(anillo)
	var t := VBoxContainer.new()
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.alignment = BoxContainer.ALIGNMENT_CENTER
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(t)
	var gr := _lbl(grande, 14, col)
	gr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.add_child(gr)
	var p := _lbl(pie, 11, COL_SUAVE)
	p.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.clip_text = false
	t.add_child(p)

static func _color_nota(v: float) -> Color:
	return COL_VERDE if v >= 75.0 else (COL_ORO if v >= 60.0 else COL_ROJO)

# --- tarjetas -----------------------------------------------------------------

static func _tarjeta_partido(c: Club, mundo: Mundo, liga: Liga, ir: Callable) -> Control:
	var par := mundo.proximo_partido()
	var cc := _caja_tarjeta(ir, "Partido", 104.0)
	var v: VBoxContainer = cc[1]
	if par.size() != 2:
		_titulo(v, "PRÓXIMO PARTIDO")
		v.add_child(_lbl("Semana sin partido: entrenamiento doble.", 15, COL_TEXTO))
		return cc[0]
	var local: Club = par[0]
	var visita: Club = par[1]
	_titulo(v, "PRÓXIMO PARTIDO  ·  %s  ·  %s" % [liga.nombre if liga != null else "", "EN CASA" if local == c else "FUERA"])
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 18)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(h)
	for i in 2:
		var club: Club = local if i == 0 else visita
		var lado := HBoxContainer.new()
		lado.add_theme_constant_override("separation", 10)
		lado.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lado.alignment = BoxContainer.ALIGNMENT_END if i == 0 else BoxContainer.ALIGNMENT_BEGIN
		lado.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(lado)
		var esc := TextureRect.new()
		esc.texture = Escudo.textura(club, 52)
		esc.custom_minimum_size = Vector2(52, 52)
		esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		esc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var nombre := _lbl(club.nombre, 17, COL_ORO if club == c else COL_TEXTO)
		if i == 0:
			lado.add_child(nombre)
			lado.add_child(esc)
		else:
			lado.add_child(esc)
			lado.add_child(nombre)
		if i == 0:
			var vs := _lbl("VS", 14, COL_SUAVE)
			h.add_child(vs)
	return cc[0]

static func _tarjeta_plantel(c: Club, ir: Callable) -> Control:
	var cc := _caja_tarjeta(ir, "Mi plantel")
	var v: VBoxContainer = cc[1]
	_titulo(v, "PLANTEL")
	var medias: Array[int] = []
	var lesionados := 0
	var sancionados := 0
	for j: Jugador in c.plantilla:
		medias.append(j.ovr)
		if j.lesion > 0:
			lesionados += 1
		if j.suspension > 0:
			sancionados += 1
	medias.sort()
	medias.reverse()
	var suma := 0
	for k in mini(11, medias.size()):
		suma += medias[k]
	var media := float(suma) / maxf(1.0, float(mini(11, medias.size())))
	_fila_anillo(v, Anillo.crear(media, 99.0, _color_nota(media), 54.0),
		"Media del once", "%d jugadores · %d 🩹 · %d 🚫" % [c.plantilla.size(), lesionados, sancionados],
		COL_TEXTO)
	return cc[0]

static func _tarjeta_directorio(mundo: Mundo, ir: Callable) -> Control:
	var cc := _caja_tarjeta(ir, "Club")
	var v: VBoxContainer = cc[1]
	_titulo(v, "DIRECTORIO")
	var conf := float(mundo.directiva.confianza) if mundo.directiva != null else 50.0
	var col := COL_VERDE if conf >= 55.0 else (COL_ROJO if conf < 30.0 else COL_ORO)
	_fila_anillo(v, Anillo.crear(conf, 100.0, col, 54.0), "Confianza",
		mundo.directiva.objetivo if mundo.directiva != null else "", COL_TEXTO)
	return cc[0]

static func _tarjeta_posicion(c: Club, liga: Liga, ir: Callable) -> Control:
	var cc := _caja_tarjeta(ir, "Clubes")
	var v: VBoxContainer = cc[1]
	_titulo(v, "COMPETICIÓN")
	if liga == null:
		return cc[0]
	var tabla := liga.tabla()
	var mi_puesto := 0
	for i in tabla.size():
		if (tabla[i] as Dictionary)["club"] == c:
			mi_puesto = i + 1
	var filas: Array[int] = [0, 1, 2]
	if mi_puesto > 3:
		filas[2] = mi_puesto - 1
	for i: int in filas:
		if i >= tabla.size():
			continue
		var f: Dictionary = tabla[i]
		var club: Club = f["club"]
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(h)
		h.add_child(_lbl("%d" % (i + 1), 12, COL_SUAVE))
		var esc := TextureRect.new()
		esc.texture = Escudo.textura(club, 16)
		esc.custom_minimum_size = Vector2(16, 16)
		esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		esc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(esc)
		var n := _lbl(club.nombre, 12, COL_ORO if club == c else COL_TEXTO)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(n)
		h.add_child(_lbl("%d" % int(f["pts"]), 12, COL_TEXTO))
	return cc[0]

static func _tarjeta_caja(c: Club, ir: Callable) -> Control:
	var cc := _caja_tarjeta(ir, "Finanzas")
	var v: VBoxContainer = cc[1]
	_titulo(v, "CAJA")
	v.add_child(_lbl(Eco.dinero(c.saldo), 22, COL_VERDE if c.saldo >= 0 else COL_ROJO))
	var sueldos := 0
	for j: Jugador in c.plantilla:
		sueldos += j.sueldo
	v.add_child(_lbl("Sueldos: %s/sem" % Eco.dinero(sueldos), 11, COL_SUAVE))
	return cc[0]

## LA ESTRELLA, con su cara: la tarjeta "Foco" de Soccer Manager.
static func _tarjeta_foco(c: Club, ficha: Callable) -> Control:
	var mejor: Jugador = null
	for j: Jugador in c.plantilla:
		if mejor == null or j.ovr > mejor.ovr:
			mejor = j
	var cc := _caja_tarjeta(Callable(), "")
	var b: Button = cc[2]
	var v: VBoxContainer = cc[1]
	_titulo(v, "LA ESTRELLA")
	if mejor == null:
		return cc[0]
	if ficha.is_valid():
		b.pressed.connect(func() -> void: ficha.call(mejor))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(h)
	var cara := TextureRect.new()
	cara.texture = Cara.textura(mejor, c.color1, c.color2, 52)
	cara.custom_minimum_size = Vector2(52, 52)
	cara.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cara.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cara.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(cara)
	var t := VBoxContainer.new()
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.alignment = BoxContainer.ALIGNMENT_CENTER
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(t)
	var nom := _lbl(mejor.nombre, 13, COL_TEXTO)
	nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.add_child(nom)
	t.add_child(_lbl("%s · %d años" % [mejor.pos_e, mejor.edad], 11, COL_SUAVE))
	h.add_child(Anillo.crear(mejor.ovr, 99.0, _color_nota(mejor.ovr), 42.0))
	return cc[0]

static func _tarjeta_estadio(c: Club, ir: Callable) -> Control:
	var cc := _caja_tarjeta(ir, "Estadio")
	var v: VBoxContainer = cc[1]
	_titulo(v, "ESTADIO")
	var en := _lbl(c.estadio_nombre if c.estadio_nombre != "" else "Estadio " + c.nombre, 13, COL_TEXTO)
	en.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(en)
	v.add_child(_lbl("%s butacas" % _miles(c.estadio_aforo), 18, COL_ORO))
	if c.socios > 0:
		v.add_child(_lbl("%s socios" % _miles(c.socios), 11, COL_SUAVE))
	return cc[0]

## LA RACHA: los últimos cinco resultados en píldoras de colores, de izquierda
## (el más viejo) a derecha (el último), como en cualquier retransmisión.
static func _racha(c: Club, liga: Liga) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.add_child(_lbl("RACHA", 11, COL_SUAVE))
	var res: Array[String] = []
	if liga != null:
		for i in range(liga.historial.size() - 1, -1, -1):
			if res.size() >= 5:
				break
			for r: Dictionary in liga.historial[i]:
				if r["local"] != c and r["visita"] != c:
					continue
				var mios := int(r["gl"]) if r["local"] == c else int(r["gv"])
				var suyos := int(r["gv"]) if r["local"] == c else int(r["gl"])
				res.append("G" if mios > suyos else ("P" if mios < suyos else "E"))
	res.reverse()
	if res.is_empty():
		h.add_child(_lbl("todavía sin partidos", 11, COL_SUAVE))
	for r: String in res:
		var p := PanelContainer.new()
		var e := StyleBoxFlat.new()
		e.bg_color = COL_VERDE if r == "G" else (COL_ROJO if r == "P" else Color("6b7a70"))
		e.set_corner_radius_all(9)
		e.content_margin_left = 8; e.content_margin_right = 8
		e.content_margin_top = 1; e.content_margin_bottom = 1
		p.add_theme_stylebox_override("panel", e)
		p.add_child(_lbl(r, 12, Color.WHITE))
		h.add_child(p)
	return h

static func _miles(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out
