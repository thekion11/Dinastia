class_name CameraRig
extends "res://visor/camera_rig_p1.gd"
## (Parte 2 de 2 de `camera_rig.gd`.)

func ajustar_altura(delta_y: float) -> void:
	if current_index >= 0 and current_index < cameras.size():
		var cam: Camera3D = cameras[current_index]
		cam.position.y = clampf(cam.position.y + delta_y, 1.2, 110.0)
		camera_changed.emit("%s (Y: %.1fm)" % [current_name(), cam.position.y])

func ayuda() -> String:
	return "1-%d / Tab: Cámaras  ·  +/- / Rueda: Zoom  ·  RePág/AvPág: Altura" % cameras.size()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			ajustar_zoom(-2.5)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			ajustar_zoom(2.5)
			get_viewport().set_input_as_handled()

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			cycle()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
			ajustar_zoom(-3.0)
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
			ajustar_zoom(3.0)
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_PAGEUP:
			ajustar_altura(1.5)
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_PAGEDOWN:
			ajustar_altura(-1.5)
			get_viewport().set_input_as_handled()
			return
		var idx: int = int(event.keycode) - int(KEY_1)
		if idx >= 0 and idx < cameras.size():
			switch_to(idx)
			get_viewport().set_input_as_handled()
