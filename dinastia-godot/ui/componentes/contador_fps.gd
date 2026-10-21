class_name ContadorFps
extends CanvasLayer
## EL CONTADOR DE FPS (M-358, 20-10-2026). Opcional (Ajustes → Pantalla): una
## esquina con los fotogramas por segundo y los milisegundos del último segundo,
## por encima de todo y en todas las escenas (cuelga de la raíz del árbol, no de
## la pantalla, así que sigue al pasar al estadio, a la ciudad o a la Carrera).
## Sirve para medir en el hardware de verdad sin herramientas.
##   ContadorFps.poner(arbol, true/false)

static var visible_pref := false
var _l: Label
var _t := 0.0

static func poner(arbol: SceneTree, activo: bool) -> void:
	visible_pref = activo
	if arbol == null:
		return
	var viejo := arbol.root.get_node_or_null("ContadorFps")
	if activo and viejo == null:
		var c := ContadorFps.new()
		c.name = "ContadorFps"
		arbol.root.add_child.call_deferred(c)
	elif not activo and viejo != null:
		viejo.queue_free()

func _ready() -> void:
	layer = 120
	_l = Label.new()
	_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_l.position = Vector2(8, 4)
	_l.add_theme_font_size_override("font_size", 12)
	_l.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	_l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_l.add_theme_constant_override("outline_size", 4)
	add_child(_l)

func _process(delta: float) -> void:
	_t -= delta
	if _t > 0.0:
		return
	_t = 0.5
	var fps := Engine.get_frames_per_second()
	_l.text = "%d FPS · %.1f ms" % [fps, 1000.0 / maxf(fps, 1.0)]
	_l.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6) if fps >= 50 else (Color(1.0, 0.85, 0.4) if fps >= 28 else Color(1.0, 0.45, 0.4)))
