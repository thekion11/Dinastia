class_name Competicion
extends Control
## La ficha de una competición, al estilo del panel que sale al buscar una liga
## en Google: la tabla completa, los últimos resultados, los próximos partidos y
## un selector para saltar a cualquier otra liga del mundo.
##
## Se abre pulsando la columna izquierda de la pantalla principal. Esa columna
## enseña lo justo -las posiciones y poco más, porque comparte sitio con el
## plantel y la ficha-; esto es el sitio donde MIRAR de verdad, sin que quepa
## solo lo imprescindible.
##
## Vive en su propio archivo y no dentro de `principal.gd` a propósito: ese
## archivo pasa de las cinco mil líneas y todo lo que pueda salir, sale.

signal cerrado

const COL_FONDO := Tema.FONDO
const COL_PANEL := Tema.PANEL
const COL_BORDE := Tema.BORDE
const COL_TEXTO := Tema.TEXTO
const COL_SUAVE := Tema.SUAVE
const COL_ACENTO := Tema.ACENTO
const COL_VERDE := Tema.BIEN
const COL_ROJO := Tema.MAL
const COL_ORO := Tema.ORO

var mundo: Mundo
var _liga: Liga
var _lista: VBoxContainer
var _selector: OptionButton

func abrir(m: Mundo, liga: Liga) -> void:
	mundo = m
	_liga = liga
	_construir()
	_pintar()

func _construir() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.color = COL_FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.color.a = 0.97
	add_child(fondo)

	var raiz := VBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.offset_left = 40; raiz.offset_top = 24
	raiz.offset_right = -40; raiz.offset_bottom = -24
	raiz.add_theme_constant_override("separation", 10)
	add_child(raiz)

	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 10)
	raiz.add_child(cab)
	## El selector de liga es lo que convierte esto en "el mundo" y no "mi liga":
	## desde aquí se mira cualquier campeonato sin salir de la pantalla.
	_selector = OptionButton.new()
	_selector.custom_minimum_size = Vector2(320, 34)
	_selector.clip_text = true
	for i in mundo.ligas.size():
		var l: Liga = mundo.ligas[i]
		_selector.add_item("%s  ·  %s" % [l.nombre, l.pais], i)
		if l == _liga:
			_selector.selected = i
	_selector.item_selected.connect(func(i: int) -> void:
		_liga = mundo.ligas[i]
		_pintar())
	cab.add_child(_selector)
	var hueco := Control.new()
	hueco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(hueco)
	var cerrar := Button.new()
	cerrar.text = "Cerrar"
	cerrar.custom_minimum_size = Vector2(110, 34)
	cerrar.pressed.connect(func() -> void: cerrado.emit())
	cab.add_child(cerrar)

	var caja := PanelContainer.new()
	var e := StyleBoxFlat.new()
	e.bg_color = COL_PANEL
	e.border_color = COL_BORDE
	e.set_border_width_all(1)
	e.set_corner_radius_all(8)
	caja.add_theme_stylebox_override("panel", e)
	caja.size_flags_vertical = Control.SIZE_EXPAND_FILL
	raiz.add_child(caja)
	var dentro := VBoxContainer.new()
	dentro.set_anchors_preset(Control.PRESET_FULL_RECT)
	dentro.offset_left = 14; dentro.offset_top = 12
	dentro.offset_right = -14; dentro.offset_bottom = -12
	caja.add_child(dentro)
	var s := ScrollContainer.new()
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dentro.add_child(s)
	_lista = VBoxContainer.new()
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista.add_theme_constant_override("separation", 3)
	s.add_child(_lista)

func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel"):
		cerrado.emit()
		get_viewport().set_input_as_handled()

# --- pintado ----------------------------------------------------------------

func _pintar() -> void:
	for n in _lista.get_children():
		_lista.remove_child(n)
		n.queue_free()
	var mio := mundo.mi_club()
	_titulo("%s  ·  jornada %d de %d" % [_liga.nombre, _liga.jornada_actual, _liga.jornadas()], COL_ORO, 15)
	_pintar_tabla_completa(mio)
	_pintar_ultimos()
	_pintar_proximos(mio)

## La tabla entera, con las columnas que la de la pantalla principal no tiene
## sitio para enseñar: goles a favor, en contra y diferencia.
func _pintar_tabla_completa(mio: Club) -> void:
	var g := GridContainer.new()
	g.columns = 9
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 4)
	_lista.add_child(g)
	for t in ["#", "CLUB", "PJ", "G", "E", "P", "GF", "GC", "PTS"]:
		_celda(g, t, COL_SUAVE, t != "CLUB" and t != "#", 11)
	var puesto := 0
	for f: Dictionary in _liga.tabla():
		puesto += 1
		var c: Club = f["club"]
		var propio := c == mio
		var color := COL_ACENTO if propio else COL_TEXTO
		## Las zonas: campeón y descenso. Es lo primero que se mira en una tabla
		## y en la pantalla principal no cabía.
		var col_puesto := COL_SUAVE
		if puesto == 1:
			col_puesto = COL_ORO
		elif puesto <= 4:
			col_puesto = COL_VERDE
		elif puesto > _liga.clubes.size() - 3:
			col_puesto = COL_ROJO
		_celda(g, str(puesto), col_puesto)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		fila.add_child(_escudo(c, 20))
		var nom := Label.new()
		nom.text = c.nombre
		nom.add_theme_font_size_override("font_size", 12)
		nom.add_theme_color_override("font_color", color)
		nom.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fila.add_child(nom)
		g.add_child(fila)
		for v in [f["pj"], f["g"], f["e"], f["p"], f["gf"], f["gc"], f["pts"]]:
			_celda(g, str(v), color, true)

## Los resultados de la última jornada jugada. `Liga.historial` los guarda desde
## esta tanda; antes viajaban en una señal y se perdían.
func _pintar_ultimos() -> void:
	if _liga.historial.is_empty():
		return
	_lista.add_child(HSeparator.new())
	_titulo("ÚLTIMOS RESULTADOS  ·  jornada %d" % _liga.historial.size(), COL_SUAVE, 11)
	var ultima: Array = _liga.historial[_liga.historial.size() - 1]
	for r: Dictionary in ultima:
		_fila_partido(r["local"], r["visita"], int(r["gl"]), int(r["gv"]))

## Lo que viene: el calendario ya está armado de principio a fin desde que se
## genera el mundo, así que enseñar las tres próximas jornadas no cuesta nada.
func _pintar_proximos(mio: Club) -> void:
	if not _liga.quedan_jornadas():
		return
	_lista.add_child(HSeparator.new())
	_titulo("PRÓXIMOS PARTIDOS", COL_SUAVE, 11)
	var hasta: int = mini(_liga.jornada_actual + 3, _liga.calendario.size())
	for j in range(_liga.jornada_actual, hasta):
		var et := Label.new()
		et.text = "Jornada %d" % (j + 1)
		et.add_theme_font_size_override("font_size", 10)
		et.add_theme_color_override("font_color", COL_ORO)
		_lista.add_child(et)
		for par: Array in _liga.calendario[j]:
			_fila_partido(par[0], par[1], -1, -1, mio)

func _fila_partido(local: Club, visita: Club, gl: int, gv: int, mio: Club = null) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	## Ancho FIJO y centrada. Con los nombres en EXPAND_FILL la fila se estiraba
	## los 1.600 px de la ventana y los escudos acababan pegados a los bordes,
	## a medio metro del marcador al que pertenecen: ilegible.
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	_lista.add_child(h)
	var tuyo := mio != null and (local == mio or visita == mio)
	var nl := Label.new()
	nl.text = local.nombre
	nl.add_theme_font_size_override("font_size", 12)
	## El ganador en verde: se lee la jornada entera de un vistazo, sin comparar
	## números uno a uno.
	nl.add_theme_color_override("font_color",
		COL_ACENTO if tuyo else (COL_VERDE if gl > gv else (COL_SUAVE if gl < gv else COL_TEXTO)))
	nl.custom_minimum_size = Vector2(230, 0)
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	nl.clip_text = true
	h.add_child(nl)
	## El escudo del local va DESPUÉS de su nombre: el nombre está alineado a la
	## derecha, así que escudo y nombre quedan pegados y el par se lee junto.
	h.add_child(_escudo(local, 18))
	var marc := Label.new()
	marc.text = "vs" if gl < 0 else "%d - %d" % [gl, gv]
	marc.add_theme_font_size_override("font_size", 12)
	marc.add_theme_color_override("font_color", COL_ORO if gl >= 0 else COL_SUAVE)
	marc.custom_minimum_size = Vector2(56, 0)
	marc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_child(marc)
	var nv := Label.new()
	nv.text = visita.nombre
	nv.add_theme_font_size_override("font_size", 12)
	nv.add_theme_color_override("font_color",
		COL_ACENTO if tuyo else (COL_VERDE if gv > gl else (COL_SUAVE if gv < gl else COL_TEXTO)))
	nv.custom_minimum_size = Vector2(230, 0)
	nv.clip_text = true
	## Y el de la visita ANTES del suyo, por lo mismo: los dos escudos quedan a
	## los lados del marcador, que es como se lee un resultado.
	h.add_child(_escudo(visita, 18))
	h.add_child(nv)

# --- utilidades -------------------------------------------------------------

func _titulo(txt: String, color: Color, tam: int) -> void:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	_lista.add_child(l)

func _celda(g: GridContainer, txt: String, color: Color, derecha: bool = false, tam: int = 12) -> void:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	if derecha:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	g.add_child(l)

func _escudo(c: Club, tam: int) -> TextureRect:
	var r := TextureRect.new()
	r.texture = Escudo.textura(c, tam)
	r.custom_minimum_size = Vector2(tam, tam)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r
