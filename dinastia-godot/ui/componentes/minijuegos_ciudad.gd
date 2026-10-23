class_name MinijuegosCiudad
extends "res://ui/componentes/minijuegos_ciudad_p2.gd"
## (Parte 3 de 3 de `minijuegos_ciudad.gd`.)

func _kart(delta: float) -> void:
	## Cuenta atrás: 3, 2, 1, ¡YA!
	if _cuenta > -1.0:
		_cuenta -= delta
		_semaforo.text = str(int(ceil(_cuenta))) if _cuenta > 0.5 else ("¡YA!" if _cuenta > -1.0 else "")
		_semaforo.add_theme_color_override("font_color", Color(1, 0.3, 0.2) if _cuenta > 0.5 else Color(0.3, 1, 0.4))
	if _cuenta <= -1.0 and _semaforo.text != "":
		_semaforo.text = ""
	var arranca := _cuenta <= 0.5
	## Rivales: siguen la trazada con algo de vaivén.
	var total := _largo_pista()
	var delante := 0
	for r: Dictionary in _rivales:
		if arranca and not _fin_kart:
			r["v"] = move_toward(float(r["v"]), float(r["tope"]), 9.0 * delta)
			r["s"] = float(r["s"]) + float(r["v"]) * delta
		var c := _centro_pista(float(r["s"]))
		var dir: Vector3 = c["dir"]
		var lat := Vector3(-dir.z, 0, dir.x)
		var rn: Node3D = r["n"]
		rn.position = (c["p"] as Vector3) + lat * (float(r["lado"]) + sin(float(r["s"]) * 0.05) * 1.2)
		rn.rotation.y = atan2(dir.x, dir.z)
		if float(r["s"]) > _mi_total:
			delante += 1
	if _fin_kart:
		_colocar_kart(delta)
		return
	var x := float(Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A))
	var y := float(Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W)) - float(Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S))
	if not arranca:
		y = 0.0
		x = 0.0
	if y != 0.0:
		_empezado = true
	var en_pista := _fuera_de_eje(_kp) < ANCHO_PISTA * 0.5
	var tope := KART_VEL if en_pista else KART_VEL * 0.35
	_kv = clampf(_kv + y * 16.0 * delta, -6.0, maxf(tope, _kv))
	if y == 0.0:
		_kv = move_toward(_kv, 0.0, 6.0 * delta)
	if _kv > tope:
		_kv = move_toward(_kv, tope, 22.0 * delta)
	## Girar a la izquierda con la flecha izquierda (rumbo +x = derecha en pantalla).
	_kr -= x * 1.9 * delta * clampf(absf(_kv) / 8.0, 0.0, 1.0) * signf(_kv if _kv != 0.0 else 1.0)
	var antes := _kp
	_kp += Vector3(sin(_kr), 0, cos(_kr)) * _kv * delta
	## Las barreras de neumáticos: no se atraviesan.
	if _fuera_de_eje(_kp) > ANCHO_PISTA * 0.5 + 2.4:
		_kp = antes
		_kv *= -0.3
	## Inclinación en las curvas y algo de vibración fuera del asfalto.
	_kart_n.rotation.z = lerpf(_kart_n.rotation.z, x * 0.06 * clampf(_kv / KART_VEL, 0.0, 1.0), delta * 6.0)
	_colocar_kart(delta)
	if not en_pista and absf(_kv) > 3.0:
		_kart_n.position.y = _rng.randf_range(0.0, 0.05)
	var dp := _progreso(_kp) - _progreso(antes)
	if dp > total * 0.5:
		dp -= total
	elif dp < -total * 0.5:
		dp += total
	_mi_total += dp
	if _empezado:
		_crono += delta
	## Vuelta: pasar por la recta de arriba y luego cruzar la meta (x = 0 abajo).
	if _kp.z < -RADIO * 0.5:
		_paso_arriba = true
	if _paso_arriba and _kp.z > 0.0 and antes.x < 0.5 and _kp.x >= 0.5:
		_vueltas += 1
		_paso_arriba = false
	_titulo.text = Idiomas.t("🏎️ Karting · vuelta %d de 3 · %.1f s · posición %d.º de 4 · récord: %s") % [mini(_vueltas + 1, 3), _crono, delante + 1,
		("%.1f s" % records["karting"]) if float(records["karting"]) > 0.0 else "—"]
	if _vueltas >= 3:
		_fin_kart = true
		var mejor := float(records["karting"])
		var puesto := "¡Ganaste la carrera!" if delante == 0 else "Llegaste %d.º." % (delante + 1)
		if mejor <= 0.0 or _crono < mejor:
			records["karting"] = _crono
			_aviso.text = Idiomas.t("%s ¡Nuevo récord del circuito: %.1f s!") % [puesto, _crono]
		else:
			_aviso.text = Idiomas.t("%s Tiempo: %.1f s (récord %.1f s).") % [puesto, _crono, mejor]

func _process(delta: float) -> void:
	match juego:
		"autografos":
			_autografos(delta)
		"pesca":
			_pesca(delta)
		"karting":
			_kart(delta)

func _firmar(h: Dictionary) -> void:
	_puntos += 1
	h["estado"] = "firmado"
	h["t"] = 1.3
	(h["firma"] as Label3D).visible = false
	Mini3D.anim(h["d"], ["celebrar", "puno_al_aire", "aplaudir", "baile"][_rng.randi() % 4], "")
	## Te giras hacia él y firmas.
	var n: Node3D = h["d"]["nodo"]
	if not _yo.is_empty():
		var yo: Node3D = _yo["nodo"]
		var tw := create_tween()
		tw.tween_property(yo, "rotation:y", atan2(n.position.x, n.position.z), 0.15)
		Mini3D.anim(_yo, "saludo_mano", "parado")
	Sonido.toca("cambio", Sonido.Bus.INTERFAZ)

func _firmar_en(pos: Vector2) -> void:
	if not _activo:
		return
	var mejor := {}
	var dist := 70.0
	for h: Dictionary in _hinchas:
		if String(h["estado"]) != "espera":
			continue
		var n: Node3D = h["d"]["nodo"]
		for alto: float in [1.0, 1.6, 2.2]:
			var q := _cam.unproject_position(n.position + Vector3(0, alto, 0))
			if q.distance_to(pos) < dist:
				dist = q.distance_to(pos)
				mejor = h
	if not mejor.is_empty():
		_firmar(mejor)

func _gui_input(ev: InputEvent) -> void:
	var pos := Vector2(-1, -1)
	if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		pos = (ev as InputEventMouseButton).position
	elif ev is InputEventScreenTouch and (ev as InputEventScreenTouch).pressed:
		pos = (ev as InputEventScreenTouch).position
	if pos.x < 0.0:
		return
	match juego:
		"autografos":
			_firmar_en(pos)
		"pesca":
			_tirar()
	accept_event()

func _firmar_mas_cercano() -> void:
	if not _activo:
		return
	var mejor := {}
	var menos := INF
	for h: Dictionary in _hinchas:
		if String(h["estado"]) == "espera" and float(h["t"]) < menos:
			menos = float(h["t"])
			mejor = h
	if not mejor.is_empty():
		_firmar(mejor)

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and (ev as InputEventKey).pressed and not (ev as InputEventKey).echo:
		var k := (ev as InputEventKey).keycode
		if k == KEY_SPACE or k == KEY_E:
			if juego == "pesca":
				_tirar()
			elif juego == "autografos":
				_firmar_mas_cercano()
			get_viewport().set_input_as_handled()
		elif k == KEY_ESCAPE:
			queue_free()
			get_viewport().set_input_as_handled()
