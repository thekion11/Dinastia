class_name ExploradorEstadio
extends "res://visor/explorador_estadio_p1.gd"
## [Capa 2/2 de `explorador_estadio.gd`] _rotulos, _physics_process, _raton_en_primera_persona, _unhandled_input, _exit_tree

func _rotulos() -> void:
	OcultarEstadioDentro.actualizar(self, planta, String(zona_en(cuerpo.position).get("nombre", "")), camara, _datos, en_viaje)   ## (10-11) dentro del edificio no se dibuja el estadio de fuera (y en el vestuario, solo si se ve la boca del túnel)
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
		_boton_e.visible = hay
	_hud.text = "📍 %s · %s %d  ·  %s" % [Idiomas.t(nombre), Idiomas.t("Planta"), planta, Idiomas.t("W/S/A/D o mando · Mayús: correr · E: usar · Esc: salir")]

func _physics_process(delta: float) -> void:
	if cuerpo == null:
		return
	_raton_en_primera_persona()
	var st := VistaJuego.mirada_stick(delta) if primera_persona and not is_instance_valid(_menu) else Vector2.ZERO   ## (12-11) stick derecho
	rumbo -= st.x
	mirada_v = VistaJuego.cabeceo(mirada_v, st.y)
	if en_viaje:   ## (9-11) el ascensor sube o baja: solo se mueve la cámara con el cuerpo
		_colocar_camara(delta)
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
## Captura el cursor en primera persona (para mirar con el ratón) y lo suelta fuera. (12-11) Con un diálogo, el ascensor o el panel de
## decorar abiertos, el cursor queda libre para pulsarlos; en el móvil no hay cursor que capturar.
func _raton_en_primera_persona() -> void:
	var quiero := Input.MOUSE_MODE_CAPTURED if primera_persona and not is_instance_valid(_menu) and DisplayServer.get_name() != "headless" \
		and not EscalaMovil.es_movil() else Input.MOUSE_MODE_VISIBLE
	if Input.mouse_mode != quiero:
		Input.mouse_mode = quiero

func _unhandled_input(ev: InputEvent) -> void:
	## (12-11) Mirar: ratón capturado, o arrastrar el dedo por la derecha de la pantalla; también arriba y abajo (`VistaJuego`).
	var mira := VistaJuego.mirada_por_evento(ev, get_viewport().get_visible_rect().size.x) if primera_persona and not is_instance_valid(_menu) else Vector2.ZERO
	if mira != Vector2.ZERO:
		rumbo -= mira.x
		mirada_v = VistaJuego.cabeceo(mirada_v, mira.y)
		return
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		salir.emit()
	elif ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_V and VistaJuego.puede_cambiar():   ## (12-11) en el juego, solo primera persona
		primera_persona = not primera_persona
		_raton_en_primera_persona()
	elif (ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_E) \
			or (ev is InputEventJoypadButton and ev.pressed and ev.button_index == JOY_BUTTON_X):
		get_viewport().set_input_as_handled()
		usar()

func _exit_tree() -> void:
	OcultarEstadioDentro.devolver(self)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
