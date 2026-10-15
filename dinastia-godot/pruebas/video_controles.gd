extends Control
## VÍDEO de la pantalla de controles navegada como con un mando: bajar por
## las filas, cambiar de sección, cambiar de mando, reasignar y guardar.
##   xvfb-run -a godot --path . --resolution 1280x720 --write-movie pruebas/capturas/controles.avi --fixed-fps 30 res://pruebas/video_controles.tscn
var _n := 0
var _panel: PanelControles

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel = PanelControles.abrir(self)

func _tecla(k: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = k
	e.physical_keycode = k
	e.pressed = true
	Input.parse_input_event(e)
	var s := e.duplicate()
	s.pressed = false
	Input.parse_input_event(s)

func _accion(nombre: String) -> void:
	var e := InputEventAction.new()
	e.action = nombre
	e.pressed = true
	Input.parse_input_event(e)
	var s := InputEventAction.new()
	s.action = nombre
	s.pressed = false
	Input.parse_input_event(s)

func _process(_d: float) -> void:
	_n += 1
	var guion := {
		40: "ui_right", 52: "ui_down", 62: "ui_down", 72: "ui_down", 82: "ui_down", 92: "ui_down", 102: "ui_up",
		120: "pagina", 150: "ui_right", 160: "ui_down", 170: "ui_down", 180: "ui_down",
		200: "ps", 230: "ui_down", 240: "ui_down", 260: "pagina", 290: "ui_right", 300: "ui_down", 310: "ui_down",
		330: "teclado", 360: "ui_down", 372: "ui_down",
		400: "asignar", 430: "ui_accept", 450: "tecla_g", 480: "guardar", 520: "ui_accept",
	}
	if not guion.has(_n):
		if _n > 570:
			get_tree().quit()
		return
	var que: String = guion[_n]
	match que:
		"pagina": _tecla(KEY_PAGEDOWN)
		"ps": _panel._chips_disp["ps"].emit_signal("pressed")
		"teclado": _panel._chips_disp["teclado"].emit_signal("pressed")
		"asignar":
			_panel._ir_a("asignar")
		"tecla_g": _tecla(KEY_G)
		"guardar": _panel._pedir_guardar()
		_: _accion(que)
