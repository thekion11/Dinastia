class_name ContadorFps
extends CanvasLayer
## EL CONTADOR DE FPS (M-358, 20-10-2026). Opcional (Ajustes → Pantalla): una
## esquina con los fotogramas por segundo y los milisegundos del último segundo,
## por encima de todo y en todas las escenas (cuelga de la raíz del árbol, no de
## la pantalla, así que sigue al pasar al estadio, a la ciudad o a la Carrera).
## Sirve para medir en el hardware de verdad sin herramientas.
##   ContadorFps.poner(arbol, true/false)
##
## Desde el 26-10-2026 dentro va el Debug Menu de Calinou (MIT,
## `addons/debug_menu/`): además de los FPS da el tiempo de CPU y de GPU por
## fotograma, mínimos y máximos de los últimos 150 y gráficas, que es lo que
## hace falta para la medida de FPS en hardware real (M-337). Se abre en modo
## compacto; F9 pasa a detallado y a oculto (F3, su tecla de fábrica, es la
## táctica rápida del partido). Si el complemento no carga, queda la etiqueta
## de siempre.

const RUTA_MENU := "res://addons/debug_menu/debug_menu.tscn"
const ACCION_MENU := "cycle_debug_menu"

static var visible_pref := false
var _l: Label
var _menu: CanvasLayer
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
	_poner_menu()

## La acción se crea ANTES de instanciar el menú: él solo la crea (con F3) si no
## existe, así que basta con adelantarse.
func _poner_menu() -> void:
	if not InputMap.has_action(ACCION_MENU):
		InputMap.add_action(ACCION_MENU)
		var tecla := InputEventKey.new()
		tecla.keycode = KEY_F9
		InputMap.action_add_event(ACCION_MENU, tecla)
	var esc := load(RUTA_MENU) as PackedScene
	if esc == null:
		return
	_menu = esc.instantiate() as CanvasLayer
	if _menu == null:
		return
	_menu.name = "DebugMenu"
	add_child(_menu)
	## 1 = VISIBLE_COMPACT del complemento: FPS y milisegundos, sin gráficas.
	_menu.set("style", 1)
	_l.visible = false

## El texto que se ve ahora mismo (para las pruebas): el del menú si está.
func texto() -> String:
	if _menu != null and _menu.get("fps") is Label:
		return (_menu.get("fps") as Label).text
	return _l.text

func _process(delta: float) -> void:
	if _menu != null:
		return
	_t -= delta
	if _t > 0.0:
		return
	_t = 0.5
	var fps := Engine.get_frames_per_second()
	_l.text = "%d FPS · %.1f ms" % [fps, 1000.0 / maxf(fps, 1.0)]
	_l.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6) if fps >= 50 else (Color(1.0, 0.85, 0.4) if fps >= 28 else Color(1.0, 0.45, 0.4)))
