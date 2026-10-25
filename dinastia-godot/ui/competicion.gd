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
##
## PULIDO (25-10-2026): las filas y la leyenda viven en `CompeticionFilas`, las
## zonas reales (descenso, ascenso, promoción, continental) en
## `CompeticionZonas`; el selector también abre la copa nacional y los torneos
## continentales; todo pasa por `Idiomas.t`; y se maneja con mando: L1/R1 (o
## Q/E) cambian de competición, la cruceta desplaza y B cierra.

signal cerrado

const COL_FONDO := Tema.FONDO
const COL_PANEL := Tema.PANEL
const COL_BORDE := Tema.BORDE
const COL_TEXTO := Tema.TEXTO
const COL_SUAVE := Tema.SUAVE
const COL_ORO := Tema.ORO

## Cuánto baja la lista por pulsación de la cruceta: unas tres filas.
const PASO_SCROLL := 90

var mundo: Mundo
var _liga: Liga
## La copa (nacional o continental) que se está mirando; null = una liga.
var _copa: Copa
var _lista: VBoxContainer
var _scroll: ScrollContainer
var _selector: OptionButton
## Lo que hay en cada entrada del selector: una Liga o una Copa.
var _entradas: Array = []

func abrir(m: Mundo, liga: Liga) -> void:
	mundo = m
	_liga = liga
	_construir()
	_pintar()
	## Con mando o teclado hay que empezar con el foco en algún sitio: si no,
	## la cruceta no hace nada y parece que la pantalla se ha colgado.
	_selector.grab_focus.call_deferred()

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
	_selector.custom_minimum_size = Vector2(360, 34)
	_selector.clip_text = true
	_llenar_selector()
	_selector.item_selected.connect(_elegir)
	cab.add_child(_selector)
	var pista := Label.new()
	pista.text = Idiomas.t("L1/R1 o Q/E: cambiar de competición")
	pista.add_theme_font_size_override("font_size", 11)
	pista.add_theme_color_override("font_color", COL_SUAVE)
	pista.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pista.clip_text = true
	pista.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	cab.add_child(pista)
	var cerrar := Button.new()
	cerrar.text = Idiomas.t("Cerrar")
	cerrar.custom_minimum_size = Vector2(110, 34)
	cerrar.pressed.connect(func() -> void: cerrado.emit())
	cab.add_child(cerrar)

	var caja := PanelContainer.new()
	var e := StyleBoxFlat.new()
	e.bg_color = COL_PANEL
	e.border_color = COL_BORDE
	e.set_border_width_all(1)
	e.set_corner_radius_all(8)
	e.content_margin_left = 14; e.content_margin_right = 14
	e.content_margin_top = 12; e.content_margin_bottom = 12
	caja.add_theme_stylebox_override("panel", e)
	caja.size_flags_vertical = Control.SIZE_EXPAND_FILL
	raiz.add_child(caja)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	caja.add_child(_scroll)
	_lista = VBoxContainer.new()
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista.add_theme_constant_override("separation", 2)
	_scroll.add_child(_lista)

## Ligas primero (la tuya incluida, en su sitio), y después la copa nacional y
## los torneos continentales en curso o ya jugados.
func _llenar_selector() -> void:
	_selector.clear()
	_entradas.clear()
	for l: Liga in mundo.ligas:
		_selector.add_item("%s  ·  %s" % [Idiomas.t(l.nombre), l.pais], _entradas.size())
		_entradas.append(l)
	if mundo.copa != null and not mundo.copa.participantes.is_empty():
		_selector.add_item("🏆  " + Idiomas.t(mundo.copa.nombre), _entradas.size())
		_entradas.append(mundo.copa)
	for k: String in Continental.claves():
		var t: Continental = mundo.continentales.get(k)
		if t == null or t.participantes.is_empty():
			continue
		_selector.add_item("🌎  " + Idiomas.t(Continental.nombre_conti(k)), _entradas.size())
		_entradas.append(t)
	var i := _entradas.find(_copa if _copa != null else _liga)
	if i >= 0:
		_selector.selected = i

func _elegir(i: int) -> void:
	if i < 0 or i >= _entradas.size():
		return
	if _entradas[i] is Liga:
		_liga = _entradas[i]
		_copa = null
	else:
		_copa = _entradas[i]
	_pintar()
	_scroll.scroll_vertical = 0

## Va ANTES que el `_input` de la pantalla principal (los hijos reciben la
## entrada primero): si no se consumieran aquí, L1/R1 cambiarían de pestaña
## DETRÁS de esta ficha, que tapa toda la pantalla.
func _input(evento: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if evento.is_action_pressed("dinastia_tab_siguiente") or evento.is_action_pressed("dinastia_tab_anterior"):
		var paso := 1 if evento.is_action_pressed("dinastia_tab_siguiente") else -1
		var n := _selector.item_count
		if n > 0:
			var i := posmod(_selector.selected + paso, n)
			_selector.select(i)
			_elegir(i)
		get_viewport().set_input_as_handled()
	## La cruceta arriba/abajo desplaza la tabla: las filas no son botones (no
	## hay nada que pulsar en ellas) y sin esto, con mando, no se veía más allá
	## del décimo. Con el desplegable abierto, la cruceta es suya.
	elif not _selector.get_popup().visible and (evento.is_action_pressed("ui_down", true) or evento.is_action_pressed("ui_up", true)):
		_scroll.scroll_vertical += PASO_SCROLL if evento.is_action_pressed("ui_down", true) else -PASO_SCROLL
		get_viewport().set_input_as_handled()

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
	if _copa != null:
		CompeticionCopas.pintar(_lista, _copa, mio)
		return
	CompeticionFilas.titulo(_lista, Idiomas.t("%s  ·  jornada %d de %d") % [Idiomas.t(_liga.nombre),
		mini(_liga.jornada_actual, _liga.jornadas()), _liga.jornadas()], COL_ORO, 16)
	_pintar_tabla_completa(mio)
	_pintar_ultimos(mio)
	_pintar_proximos(mio)

## La tabla entera, con las columnas que la de la pantalla principal no tiene
## sitio para enseñar: goles a favor, en contra y diferencia.
func _pintar_tabla_completa(mio: Club) -> void:
	var tabla := _liga.tabla()
	var zonas := CompeticionZonas.de_liga(mundo, _liga, tabla)
	CompeticionFilas.cabecera(_lista, ["PJ", "G", "E", "P", "GF", "GC", "DG", "PTS"])
	var puesto := 0
	for f: Dictionary in tabla:
		puesto += 1
		var c: Club = f["club"]
		var dg := int(f["gf"]) - int(f["gc"])
		var cifras := [str(f["pj"]), str(f["g"]), str(f["e"]), str(f["p"]), str(f["gf"]), str(f["gc"]),
			("+%d" % dg) if dg > 0 else str(dg), str(f["pts"])]
		CompeticionFilas.fila_tabla(_lista, puesto, c, cifras, c == mio, puesto % 2 == 0,
			zonas.get(c.id, {}))
	CompeticionFilas.leyenda(_lista, zonas)

## Los resultados de la última jornada jugada. `Liga.historial` los guarda desde
## esta tanda; antes viajaban en una señal y se perdían.
func _pintar_ultimos(mio: Club) -> void:
	_lista.add_child(HSeparator.new())
	if _liga.historial.is_empty():
		CompeticionFilas.titulo(_lista, Idiomas.t("ÚLTIMOS RESULTADOS"), COL_SUAVE, 12)
		CompeticionFilas.titulo(_lista, Idiomas.t("Todavía no se ha jugado ninguna jornada."), COL_SUAVE, 13)
		return
	CompeticionFilas.titulo(_lista, Idiomas.t("ÚLTIMOS RESULTADOS  ·  jornada %d") % _liga.historial.size(), COL_SUAVE, 12)
	var ultima: Array = _liga.historial[_liga.historial.size() - 1]
	for r: Dictionary in ultima:
		CompeticionFilas.fila_partido(_lista, r["local"], r["visita"], int(r["gl"]), int(r["gv"]), mio)

## Lo que viene: el calendario ya está armado de principio a fin desde que se
## genera el mundo, así que enseñar las tres próximas jornadas no cuesta nada.
func _pintar_proximos(mio: Club) -> void:
	_lista.add_child(HSeparator.new())
	CompeticionFilas.titulo(_lista, Idiomas.t("PRÓXIMOS PARTIDOS"), COL_SUAVE, 12)
	if not _liga.quedan_jornadas():
		CompeticionFilas.titulo(_lista, Idiomas.t("La liga ha terminado: el calendario de la temporada que viene sale al cerrar el año."), COL_SUAVE, 13)
		return
	var hasta: int = mini(_liga.jornada_actual + 3, _liga.calendario.size())
	for j in range(_liga.jornada_actual, hasta):
		CompeticionFilas.titulo(_lista, Idiomas.t("Jornada %d") % (j + 1), COL_ORO, 11)
		for par: Array in _liga.calendario[j]:
			CompeticionFilas.fila_partido(_lista, par[0], par[1], -1, -1, mio)
