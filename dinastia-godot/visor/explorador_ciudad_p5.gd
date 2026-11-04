extends "res://visor/explorador_ciudad_p5_p1.gd"
## (Parte 2 de 2 de `explorador_ciudad_p5.gd`.)

func _unhandled_input(ev: InputEvent) -> void:
	## En primera persona el ratón mira (cursor capturado).
	if ev is InputEventMouseMotion and primera_persona and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rumbo -= (ev as InputEventMouseMotion).relative.x * 0.003
		return
	if not (ev is InputEventKey) or not (ev as InputEventKey).pressed or (ev as InputEventKey).echo:
		if ev is InputEventJoypadButton and (ev as InputEventJoypadButton).pressed and (ev as InputEventJoypadButton).button_index == JOY_BUTTON_X:
			_usar()
		return
	var k := (ev as InputEventKey).keycode
	if k == KEY_ESCAPE and MapaTransporte.cerrar(self):   ## Esc cierra el mapa del transporte si está abierto
		get_viewport().set_input_as_handled()
	elif k == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		salir.emit()
	elif k == KEY_N:   ## el mapa del transporte público (completo / autobuses / metro)
		get_viewport().set_input_as_handled()
		MapaTransporte.alternar(self)
	elif k == KEY_E:
		get_viewport().set_input_as_handled()
		_usar()
	elif k == KEY_T and vida != null:
		get_viewport().set_input_as_handled()
		vida.abrir_telefono()
	elif k == KEY_F and estado == "calle":   ## mejora D: bajarse del coche / volver a subir
		get_viewport().set_input_as_handled()
		_aviso.text = AparcarCoche.alternar(self)
	elif k == KEY_H and modo == "coche" and estado == "calle":   ## mejora E: el claxon (y la gente se aparta, mejora G)
		get_viewport().set_input_as_handled()
		Sonido.toca("claxon", Sonido.Bus.AMBIENTE)
		if trafico != null:
			trafico.asustar(cuerpo.position + Vector3(sin(rumbo), 0, cos(rumbo)) * 8.0, 12.0)
	elif k == KEY_V and modo == "coche" and estado == "calle":
		cam_coche = (cam_coche + 1) % 3
		_aviso.text = [Idiomas.t("Cámara: tercera persona"), Idiomas.t("Cámara: capó"), Idiomas.t("Cámara: primera persona")][cam_coche]
	elif k == KEY_V:
		primera_persona = not primera_persona
		_raton_en_primera_persona()
		_aviso.text = Idiomas.t("Primera persona") if primera_persona else Idiomas.t("Tercera persona")
	elif k == KEY_C and estado == "tren":
		_ventana = not _ventana
