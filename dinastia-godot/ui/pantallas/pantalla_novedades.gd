class_name PantallaNovedades
extends Control
## «NOVEDADES» (26-10-2026, plan §10 «notas de versión dentro del juego»; ideas
## 1091-1092 y M-429 «versionado sin número visible»). Una capa encima de lo que
## haya con las notas de `datos/novedades.json` (la versión más reciente
## primero) y el número de versión del proyecto. Se abre desde el pie del menú
## de modos; el botón lleva un punto mientras no hayas visto las de esta versión
## (se apunta en `user://novedades.cfg`). Esc, B o «Cerrar» la cierran.
##   PantallaNovedades.abrir(padre)   ·   PantallaNovedades.hay_sin_ver()

signal cerrada()

const RUTA := "res://datos/novedades.json"
const VISTAS := "user://novedades.cfg"

## La versión del juego tal como la declara el proyecto («0.9.0»).
static func version() -> String:
	return String(ProjectSettings.get_setting("application/config/version", ""))

## Las versiones del JSON, la más reciente primero. Vacío si falta o está roto:
## una pantalla de novedades no puede tumbar el menú.
static func leer(ruta: String = RUTA) -> Array:
	if not FileAccess.file_exists(ruta):
		return []
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	if not (d is Dictionary) or not ((d as Dictionary).get("versiones", null) is Array):
		return []
	return (d as Dictionary)["versiones"]

static func hay_sin_ver() -> bool:
	var cf := ConfigFile.new()
	cf.load(VISTAS)
	return String(cf.get_value("novedades", "vista", "")) != version()

static func marcar_vistas() -> void:
	var cf := ConfigFile.new()
	cf.load(VISTAS)
	cf.set_value("novedades", "vista", version())
	cf.save(VISTAS)

static func abrir(padre: Node) -> PantallaNovedades:
	var n := PantallaNovedades.new()
	n.name = "Novedades"
	padre.add_child(n)
	return n

var _cerrar: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.72)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(velo)
	## Centrado con un CenterContainer: con anclas al centro y `position` a mano
	## el panel salía arriba a la izquierda (la captura del 26-10 lo enseñó).
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var marco := PanelContainer.new()
	var vp := get_viewport_rect().size
	marco.custom_minimum_size = Vector2(minf(680.0, vp.x - 40.0), minf(560.0, vp.y - 60.0))
	var caja_estilo := StyleBoxFlat.new()
	caja_estilo.bg_color = Color("101712", 0.97)
	caja_estilo.border_color = Tema.ORO
	caja_estilo.set_border_width_all(1)
	caja_estilo.set_corner_radius_all(10)
	caja_estilo.set_content_margin_all(22)
	marco.add_theme_stylebox_override("panel", caja_estilo)
	centro.add_child(marco)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	marco.add_child(col)
	var cab := _etiqueta(26, Tema.ORO)
	cab.text = "✨ " + Idiomas.t("Novedades")
	col.add_child(cab)
	var ver := _etiqueta(13, Tema.SUAVE)
	ver.text = Idiomas.t("Versión %s") % version()
	col.add_child(ver)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 6)
	scroll.add_child(lista)
	var versiones := leer()
	if versiones.is_empty():
		var nada := _etiqueta(15, Tema.SUAVE)
		nada.text = Idiomas.t("No hay notas de versión.")
		lista.add_child(nada)
	for v: Variant in versiones:
		if v is Dictionary:
			_pintar_version(lista, v)
	_cerrar = Button.new()
	_cerrar.text = Idiomas.t("Cerrar")
	_cerrar.size_flags_horizontal = Control.SIZE_SHRINK_END
	_cerrar.custom_minimum_size = Vector2(140, 38)
	_cerrar.pressed.connect(cerrar)
	col.add_child(_cerrar)
	marcar_vistas()
	_cerrar.grab_focus.call_deferred()

func _pintar_version(lista: VBoxContainer, v: Dictionary) -> void:
	var t := _etiqueta(19, Tema.TEXTO)
	t.text = "%s  ·  %s" % [String(v.get("version", "")), String(v.get("fecha", ""))]
	lista.add_child(t)
	if String(v.get("titulo", "")) != "":
		var st := _etiqueta(15, Tema.ORO)
		st.text = Idiomas.t(String(v["titulo"]))
		st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lista.add_child(st)
	for s: Variant in v.get("secciones", []):
		if not (s is Dictionary):
			continue
		var ts := _etiqueta(14, Tema.SUAVE)
		ts.text = Idiomas.t(String((s as Dictionary).get("titulo", ""))).to_upper()
		lista.add_child(ts)
		for p: Variant in (s as Dictionary).get("puntos", []):
			var l := _etiqueta(15, Tema.TEXTO)
			l.text = "•  " + Idiomas.t(String(p))
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lista.add_child(l)
	lista.add_child(HSeparator.new())

func cerrar() -> void:
	cerrada.emit()
	queue_free()

func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel") or (ev is InputEventJoypadButton and (ev as InputEventJoypadButton).pressed
			and (ev as InputEventJoypadButton).button_index == JOY_BUTTON_B):
		get_viewport().set_input_as_handled()
		cerrar()

func _etiqueta(tam: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	return l
