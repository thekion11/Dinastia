class_name ExploradorEstadio
extends "res://visor/explorador_estadio_p1.gd"
## (Parte 2 de 2 de `explorador_estadio.gd`.)

func _rotulos() -> void:
	## La puerta del club se abre sola al acercarse desde dentro.
	if planta == 0 and _datos.has("puerta"):
		var pl: Vector3 = _datos["puerta"]
		EntradaClub.abrir(get_tree(), Vector2(cuerpo.position.x - pl.x, cuerpo.position.z - pl.z).length() < 1.9)
	var z := zona_en(cuerpo.position)
	var nombre := String(z.get("nombre", ""))
	var g := _persona_cerca()
	if not g.is_empty():
		_aviso.text = Idiomas.t("E: hablar con %s (%s)") % [String(g["nombre"]), Idiomas.t(String(g["puesto"]))]
		_zona_actual = "·" + nombre
	elif RecorridoClub.junto_a_la_grada(cuerpo.position, planta):
		_aviso.text = Idiomas.t("E: sentarse en la grada")
		_zona_actual = "·grada"
	elif planta == GaleriaClub.PLANTA and nombre == "Pasillo" and _junto_a_la_persiana():
		## La puerta de la galería: aquí está cerrada (el complejo está en la ciudad).
		if _zona_actual != "·galeria":
			_zona_actual = "·galeria"
			_aviso.text = Idiomas.t("La galería al complejo se recorre desde la ciudad (Ciudad 3D → a pie)")
	elif nombre != _zona_actual:
		_zona_actual = nombre
		_mostrar_lugar(Idiomas.t(nombre))
		_aviso.text = RecorridoClub.aviso_de(nombre, club_nombre)
		if RecorridoClub.sala_decorable(nombre):
			_aviso.text += "  ·  " + Idiomas.t("E: decorar")
		if nombre == "Banda" and not _rugido_hecho:
			_rugido_hecho = true
			Sonido.toca("salida_tunel", Sonido.Bus.AMBIENTE)
	if _boton_e != null:
		var hay := not g.is_empty() or _zona_actual in ["·grada", "Ascensor"] or RecorridoClub.sala_decorable(_zona_actual)
		_boton_e.modulate = Color(1.0, 0.82, 0.3, 1.0) if hay else Color(1, 1, 1, 0.55)
		_boton_e.visible = hay or ExploradorCiudad.es_tactil()
	_hud.text = "📍 %s · %s %d  ·  %s" % [Idiomas.t(nombre), Idiomas.t("Planta"), planta, Idiomas.t("W/S/A/D o mando · Mayús: correr · E: usar · Esc: salir")]

func _physics_process(delta: float) -> void:
	if cuerpo == null:
		return
	if not _ruta.is_empty():
		_caminar_ruta(delta)
		_colocar_camara(delta)
		return
	if sentado:
		## Sentado: A/D giran la mirada (hasta 70° a cada lado).
		_mirada = clampf(_mirada - _entrada().x * delta * 1.4, -1.2, 1.2)
		var dir := Vector3(sin(rumbo + _mirada), 0, cos(rumbo + _mirada))
		camara.position = cuerpo.position + Vector3(0, 1.2, 0) + Vector3(sin(rumbo), 0, cos(rumbo)) * 0.1
		camara.look_at(camara.position + dir * 10.0 + Vector3(0, -1.6, 0), Vector3.UP)
		return
	var corre := Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_joy_button_pressed(0, JOY_BUTTON_A)
	paso(_entrada(), corre, delta)
	_colocar_camara(delta)
	_rotulos()
## Captura el cursor en primera persona (para mirar con el ratón) y lo suelta fuera.
func _raton_en_primera_persona() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if primera_persona and DisplayServer.get_name() != "headless" else Input.MOUSE_MODE_VISIBLE

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion and primera_persona and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rumbo -= (ev as InputEventMouseMotion).relative.x * 0.003
		return
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		salir.emit()
	elif ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_V:
		primera_persona = not primera_persona
		_raton_en_primera_persona()
	elif (ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_E) \
			or (ev is InputEventJoypadButton and ev.pressed and ev.button_index == JOY_BUTTON_X):
		get_viewport().set_input_as_handled()
		usar()

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
