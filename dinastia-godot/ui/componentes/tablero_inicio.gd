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
const ANCHO_TARJETA := 190.0

static func pintar(raiz: VBoxContainer, c: Club, mundo: Mundo, liga: Liga, ir: Callable, ficha: Callable, dias_al_partido: int = 0) -> void:
	## (3-11, rediseño del menú central, pedido del dueño) El central queda liviano: el próximo partido en grande solo
	## 1-2 días antes (el resto de la semana, una línea); plantel, estrella, caja, estadio y competición tienen su
	## pantalla completa en el panel lateral (Plantel, Dinero, Competiciones…) y la confianza va en la cabecera.
	if dias_al_partido <= 2:
		raiz.add_child(_tarjeta_partido(c, mundo, liga, ir))
	else:
		raiz.add_child(_linea_partido(c, mundo, dias_al_partido, ir))
	raiz.add_child(_racha(c, liga))
	var tabla := ResumenInicio.tabla_corta(c, liga, ir)   ## (12-11, menú del PES) los 5 primeros, tu puesto y tus socios
	if tabla != null:
		raiz.add_child(tabla)
	var obj := ObjetivoDirectiva.fila(mundo, c, liga)   ## (10-11, idea del PES) el objetivo de la directiva con su barra de progreso
	if obj != null:
		raiz.add_child(obj)
		var sec := ObjetivoDirectiva.secundarios(mundo)   ## (10-11) una barra por objetivo secundario y el proyecto
		if sec != null:
			raiz.add_child(sec)

## El próximo partido en una línea (lo que se ve de lunes a miércoles): rival, en casa o fuera, y cuándo.
static func _linea_partido(c: Club, mundo: Mundo, dias: int, ir: Callable) -> Control:
	var par := mundo.proximo_partido()
	var b := Button.new()
	b.flat = true
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   ## en francés («Prochain : … à domicile · dans 5 jours») ensanchaba el panel en el móvil (A4-INT-019)
	b.add_theme_font_size_override("font_size", 13)
	if par.size() != 2:
		b.text = Idiomas.t("⚽ Semana sin partido: entrenamiento doble.")
	else:
		var rival: Club = par[1] if par[0] == c else par[0]
		b.text = "⚽ %s  %s  ·  %s  ·  %s" % [Idiomas.t("Próximo:"), rival.nombre, Idiomas.t("en casa") if par[0] == c else Idiomas.t("fuera"),
			Idiomas.t("en %d días") % dias]
	b.pressed.connect(func() -> void: ir.call("Partido"))
	return b

# --- piezas -------------------------------------------------------------------

## Una tarjeta: panel redondeado que CRECE con su contenido (un Button no lo
## hace: el texto se salía de la tarjeta) y un botón transparente encima que
## la hace pulsable entera. Devuelve [tarjeta, vbox de contenido, botón].
static func _caja_tarjeta(ir: Callable, destino: String, alto: float = 112.0) -> Array:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(ANCHO_TARJETA, alto)
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
	## Solo se corta en los espacios (29-9-2026): con WORD_SMART, en polaco o
	## francés salía "jedenas / tki" o "Moyenn / e", partiendo la palabra.
	var gr := _lbl(grande, 14, col)
	gr.autowrap_mode = TextServer.AUTOWRAP_WORD
	t.add_child(gr)
	var p := _lbl(pie, 11, COL_SUAVE)
	p.autowrap_mode = TextServer.AUTOWRAP_WORD
	p.clip_text = false
	t.add_child(p)

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
	## El parte del tiempo del partido (C1): el de la ciudad del local.
	var cl := Clima.del_partido(local.pais, mundo.semana, mundo.anio, local.id + visita.id)
	_titulo(v, "PRÓXIMO PARTIDO  ·  %s  ·  %s  ·  %s %s" % [liga.nombre if liga != null else "", "EN CASA" if local == c else "FUERA",
		Clima.icono(cl), String(cl["texto"])])
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
