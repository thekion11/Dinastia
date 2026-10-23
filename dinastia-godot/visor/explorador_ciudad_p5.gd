extends "res://visor/explorador_ciudad_p4.gd"
## (Parte 5 de 6 de `explorador_ciudad.gd`.)

## ¿Hay una fachada de manzana al alcance de este punto (3 m)? Devuelve la
## clave de la sala con el nombre propio, o vacío.
func edificio_en(p: Vector3) -> Dictionary:
	if cb == null:
		return {}
	## Entre casas no hay bares: las viviendas ya son sus propios lugares.
	for pc: Dictionary in cb.puntos_clic:
		if String(pc["k"]).begins_with("edificio_vivienda"):
			var q: Vector3 = pc["pos"]
			if Vector2(q.x - p.x, q.z - p.z).length() < 22.0:
				return {}
	for r: Rect2 in cb._frentes:
		var dx := maxf(maxf(r.position.x - p.x, 0.0), p.x - r.end.x)
		var dz := maxf(maxf(r.position.y - p.z, 0.0), p.z - r.end.y)
		if dx * dx + dz * dz > 3.2 * 3.2:
			continue
		var rot := _rotulo_en(p)
		if not rot.is_empty():
			## «💊 Farmacia» -> «Farmacia»: el nombre sin el icono.
			var texto := String(rot["texto"])
			var nombre_r := texto.substr(texto.find(" ") + 1)
			if SALA_DE_ROTULO.has(nombre_r):
				return {"k": "%s|%s" % [SALA_DE_ROTULO[nombre_r], nombre_r], "n": nombre_r}
		var h := absi(hash(Vector3i(floori(p.x / 14.0), 0, floori(p.z / 14.0))) + hash(r.position))
		var total := 0
		for e: Array in EDIFICIOS:
			total += int(e[1])
		var tiro := h % total
		for e: Array in EDIFICIOS:
			tiro -= int(e[1])
			if tiro < 0:
				var nombres: Array = e[3]
				var nombre: String = String((e[2] as Array)[0]) % String(nombres[(h / 7) % nombres.size()])
				return {"k": "%s|%s" % [e[0], nombre], "n": nombre}
	return {}

## Pausa el paseo (minijuego abierto): sin moverse, sin cartel, sin teclas.
func pausar(si: bool) -> void:
	set_physics_process(not si)
	set_process_unhandled_input(not si)
	if _capa != null:
		_capa.visible = not si

## El móvil en la mano y el botón E que brilla si hay algo cerca.
func _actualizar_mano(modo_mano: String, km_h: float, maxima: float, metros: float) -> void:
	if _movil != null:
		var calle := ""
		if cb != null and cb.expansion != null and estado == "calle":
			calle = cb.expansion.nombre_calle_en(cuerpo.position)
		_movil.poner(modo_mano if _con_movil else "pie", km_h, maxima, calle, metros)
	## EL GPS ESTILO GTA (17-10-2026): M lo esconde o lo vuelve a mostrar.
	if _minimapa != null:
		if Input.is_physical_key_pressed(KEY_M) != _m_antes:
			_m_antes = not _m_antes
			if _m_antes:
				_gps_oculto = not _gps_oculto
		_minimapa.visible = estado == "calle" and not _gps_oculto
		if _minimapa.visible:
			if _minimapa.red == null and cb != null:
				_minimapa.red = cb.expansion
			_minimapa.poner(cuerpo.position, rumbo if modo == "coche" else cuerpo.rotation.y, get_physics_process_delta_time())
	## Las paredes de oclusión, solo en la calle: dentro de un edificio taparían
	## lo que se ve por la puerta (`OclusoresCiudad`).
	if cb != null:
		OclusoresCiudad.activar(cb, estado == "calle")
	if _boton_e != null:
		var hay := _aviso.text.strip_edges() != ""
		_boton_e.modulate = Color(1.0, 0.82, 0.3, 1.0) if hay else Color(1, 1, 1, 0.55)
		_boton_e.visible = hay or es_tactil()
		_boton_e.tooltip_text = _aviso.text

func _mover_en_anden(delta: float) -> void:
	var e := _entrada()
	var corre := Input.is_physical_key_pressed(KEY_SHIFT)
	vel = (VEL_CORRER if corre else VEL_PIE) * clampf(e.y, -0.5, 1.0)
	rumbo -= e.x * delta * 2.6
	if _anim != null:
		_anim.speed_scale = absf(vel) / 1.4 if absf(vel) > 0.05 else 0.0
	_sonar_pasos(vel)
	var adelante := Vector3(sin(rumbo), 0, cos(rumbo))
	var p := cuerpo.position + adelante * vel * delta
	## No se atraviesa a la gente del andén: se la rodea (círculos, 16-10-2026).
	p = metro.apartar(p, 0.3)
	## Dentro del andén: ni a la vía ni fuera de la estación.
	var rel := p - _anden_c
	var la := clampf(rel.dot(_anden_lat), -_anden_medio.x, _anden_medio.x)
	var lo := clampf(rel.dot(_anden_lon), -_anden_medio.y, _anden_medio.y)
	cuerpo.position = _anden_c + _anden_lat * la + _anden_lon * lo
	cuerpo.rotation.y = rumbo
	_colocar_camara(delta)
	var k := metro.tren_parado_en(_linea, _idx)
	var eta := metro.eta_minima(_linea, _idx)
	var nombre := String(MetroCiudad.NOMBRES[_linea][_idx])
	_hud.text = Idiomas.t("Ⓜ %s · estación %s  ·  W/A/S/D · Mayús: correr · E: %s · Esc: mapa") % [
		_linea, nombre, Idiomas.t("subir al tren") if k >= 0 else Idiomas.t("salir a la calle")]
	if k >= 0:
		_aviso.text = Idiomas.t("🚇 Tren en el andén, puertas abiertas · E para subir")
	else:
		_aviso.text = Idiomas.t("Próximo tren: %s · E: salir a la calle") % ("llegando" if eta < 20.0 else "%d s" % int(eta))

func _viajar(delta: float) -> void:
	var l := metro.linea(_linea)
	var tren: Node3D = l["nodos"][_tren_k]
	_t_sacudida += delta
	var f := MetroCiudad.PISO_COCHE
	var t: MetroCiudad.Tren = l["trenes"][_tren_k]
	_actualizar_mano("tren", t.v * 3.6, MetroCiudad.VEL * 3.6, t.v * delta)
	var vaiven := sin(_t_sacudida * 9.0) * 0.012 * clampf(t.v / MetroCiudad.VEL, 0.0, 1.0)
	var local_pos := Vector3(0.45, f + 1.62 + vaiven, -5.0)
	var local_mira := Vector3(0.2, f + 1.45, 10.0)
	if _ventana:
		local_pos = Vector3(-0.6, f + 1.55 + vaiven, 0.0)
		local_mira = Vector3(6.0, f + 1.3, 0.5)
	camara.global_position = tren.global_transform * local_pos
	camara.look_at(tren.global_transform * local_mira, Vector3.UP)
	var parada := metro.estacion_del_tren(_linea, _tren_k)
	if parada >= 0 and _bajar_en_proxima and t.espera < MetroCiudad.PARADA - 1.0:
		_bajar_del_tren()
		return
	var prox := metro.proxima_de(_linea, _tren_k)
	_hud.text = Idiomas.t("🚇 %s · %s · %d km/h  ·  C: %s · Esc: mapa") % [_linea,
		(Idiomas.t("parado en %s") % String(MetroCiudad.NOMBRES[_linea][parada])) if parada >= 0 else (Idiomas.t("próxima: %s") % prox),
		int(t.v * 3.6), Idiomas.t("mirar al frente") if _ventana else Idiomas.t("mirar por la ventana")]
	if parada >= 0:
		_aviso.text = Idiomas.t("Puertas abiertas en %s · E: bajar aquí") % String(MetroCiudad.NOMBRES[_linea][parada])
	else:
		_aviso.text = Idiomas.t("Próxima estación: %s · E: %s") % [prox, Idiomas.t("no bajar") if _bajar_en_proxima else Idiomas.t("bajar en la próxima")]

func _choca_mueble(rel: Vector3) -> bool:
	var p := _INT_ORIGEN + rel
	for c: Vector3 in _int_circulos:
		var dx := p.x - c.x
		var dz := p.z - c.y
		var rr := c.z + 0.35
		if dx * dx + dz * dz < rr * rr:
			return true
	return false

func _mover_en_interior(delta: float) -> void:
	if not is_instance_valid(_int):
		_salir_del_edificio()
		return
	var e := _entrada()
	var corre := Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_joy_button_pressed(0, JOY_BUTTON_A)
	var objetivo := (3.4 if corre else 1.6) * clampf(e.y, -0.5, 1.0)
	_vel_pie = move_toward(_vel_pie, objetivo, (7.0 if absf(objetivo) > absf(_vel_pie) else 12.0) * delta)
	vel = _vel_pie
	rumbo -= e.x * delta * 2.6
	var t := _int.tam_sala()
	var rel := cuerpo.position - _INT_ORIGEN
	var nueva := rel + Vector3(sin(rumbo), 0, cos(rumbo)) * vel * delta
	## La puerta: pasar de la línea del hueco (|x| < 1,4) sale a la calle.
	if nueva.z > t.z * 0.5 - 0.2 and absf(nueva.x) < 1.4:
		_salir_del_edificio()
		return
	nueva.x = clampf(nueva.x, -t.x * 0.5 + 0.7, t.x * 0.5 - 0.7)
	nueva.z = clampf(nueva.z, -t.z * 0.5 + 0.7, t.z * 0.5 - 0.7)
	## Contra el mobiliario: se desliza por ejes, como en la calle.
	if _choca_mueble(nueva):
		if not _choca_mueble(Vector3(nueva.x, 0, rel.z)):
			nueva.z = rel.z
		elif not _choca_mueble(Vector3(rel.x, 0, nueva.z)):
			nueva.x = rel.x
		else:
			nueva = rel
			_vel_pie = 0.0
	cuerpo.position = _INT_ORIGEN + Vector3(nueva.x, 0.05, nueva.z)
	cuerpo.rotation.y = rumbo
	if _es_dt:
		_animar_dt(vel)
	elif _anim != null:
		_anim.speed_scale = absf(vel) / 1.4 if absf(vel) > 0.05 else 0.0
	_colocar_camara(delta)
	_hud.text = Idiomas.t("🏠 %s  ·  W/S/A/D para moverte · V: vista · E o la puerta: salir") % String(_int.call("_sala_nombre"))
	## ¿Alguien de la sala a mano para charlar?
	_int_cerca = {}
	var mejor := 1.9
	for lista: Array in [_int.get("_fijos"), _int.get("_caminantes")]:
		for f: Dictionary in lista:
			var d: Dictionary = f["d"]
			var n: Node3D = d.get("nodo")
			if n == null or not is_instance_valid(n):
				continue
			var dist := Vector2(n.global_position.x - cuerpo.position.x, n.global_position.z - cuerpo.position.z).length()
			if dist < mejor:
				mejor = dist
				if not f.has("charla"):
					f["charla"] = {"nodo": n}
				_int_cerca = f["charla"]
	_aviso.text = Idiomas.t("E: charlar") if not _int_cerca.is_empty() else ""
	if _t_burbuja > 0.0:
		_t_burbuja -= delta
		if _t_burbuja <= 0.0:
			_burbuja.visible = false
			if _cuadro != null:
				_cuadro.cerrar()

func _andar_solo(delta: float) -> void:
	if _auto.is_empty():
		_entrar_al_estadio()
		get_tree().create_timer(1.4).timeout.connect(func() -> void: EntradaClub.abrir(get_tree(), false))
		return
	var meta: Vector3 = _auto[0]
	var hacia := meta - cuerpo.position
	hacia.y = 0.0
	var d := hacia.length()
	if d < 0.08:
		_auto.pop_front()
		return
	rumbo = atan2(hacia.x, hacia.z)
	cuerpo.rotation.y = rumbo
	cuerpo.position += hacia / d * minf(d, VEL_PIE * delta)
	_animar_dt(VEL_PIE)
	## La cámara se queda donde estaba (detrás, en la calle) y le sigue con
	## la mirada: así se ve al DT cruzar la puerta.
	camara.look_at(cuerpo.position + Vector3(0, 1.3, 0), Vector3.UP)

## En la calle, con la puerta abierta y ya lejos: se cierra sola. Y si te
## vas a mitad de la charla con el portero, la charla se acaba.
func _cerrar_puerta_si_lejos() -> void:
	if _est.is_empty():
		return
	var pu: Vector3 = CityBuilder.ESTADIO_EN + (_est["puerta"] as Vector3)
	var lejos := Vector2(pu.x - cuerpo.position.x, pu.z - cuerpo.position.z).length() > 5.5
	if lejos and is_instance_valid(_menu_asc) and _menu_asc.has_meta("portero"):
		var g: Dictionary = _menu_asc.get_meta("portero")
		var pe := get_tree().get_first_node_in_group("personal_club") as PersonalEstadio
		if pe != null:
			pe.atender(g, Vector3.ZERO, false)
		_menu_asc.queue_free()
	if lejos and EntradaClub.abierta(get_tree()):
		EntradaClub.abrir(get_tree(), false)

func _conducir(e: Vector2, delta: float) -> void:
	if _motor_sonido == null:
		_motor_sonido = MotorCocheSonido.new()
		add_child(_motor_sonido)
	_motor_sonido.poner(vel, maxf(e.y, 0.0))
	var freno_mano := Input.is_physical_key_pressed(KEY_SPACE) or Input.is_joy_button_pressed(0, JOY_BUTTON_B)
	_volante = lerpf(_volante, e.x, clampf(delta * 6.0, 0.0, 1.0))
	if e.y > 0.0:
		var potencia := 15.0 * (1.0 - clampf(maxf(vel, 0.0) / VEL_COCHE, 0.0, 1.0) * 0.82) + 2.0
		vel = clampf(vel + e.y * potencia * delta, -8.0, VEL_COCHE)
	elif e.y < 0.0:
		if vel > 0.5:
			vel = maxf(vel - 24.0 * absf(e.y) * delta, 0.0)
		else:
			vel = clampf(vel + e.y * 7.0 * delta, -8.0, VEL_COCHE)
	else:
		vel = move_toward(vel, 0.0, (4.0 + absf(vel) * 0.12) * delta)
	if freno_mano:
		vel = move_toward(vel, 0.0, 20.0 * delta)
	var giro := 1.9 * (1.6 if freno_mano and absf(vel) > 4.0 else 1.0)
	## A más velocidad el volante gira menos (no se vuelca a 90 km/h).
	var cierre := clampf(absf(vel) / 8.0, 0.0, 1.0) * (1.0 - clampf(absf(vel) / VEL_COCHE, 0.0, 1.0) * 0.45)
	rumbo -= _volante * delta * giro * cierre * signf(vel if vel != 0.0 else 1.0)
	var acel_real := e.y if absf(vel) < VEL_COCHE else 0.0
	_cabeceo = lerpf(_cabeceo, clampf(-acel_real * 0.035 - (0.03 if freno_mano else 0.0), -0.06, 0.06), clampf(delta * 4.0, 0.0, 1.0))
	_balanceo = lerpf(_balanceo, clampf(_volante * absf(vel) * 0.0035, -0.07, 0.07), clampf(delta * 5.0, 0.0, 1.0))

## Lo que hay al alcance de la E: un peatón (a pie) o un lugar.
func _buscar_cerca() -> void:
	_cerca = {}
	var p := cuerpo.position
	## La puerta del club del estadio (a pie).
	if modo == "pie" and not _est.is_empty():
		var pu: Vector3 = CityBuilder.ESTADIO_EN + (_est["puerta"] as Vector3)
		## El portero: es él quien abre (8-10-2026).
		var port := _portero()
		if not port.is_empty() and Vector2(pu.x - p.x, pu.z - p.z).length() < 4.5:
			_cerca = {"tipo": "portero", "g": port, "n": String(port["nombre"])}
			_aviso.text = Idiomas.t("E: hablar con %s (%s)") % [String(port["nombre"]), Idiomas.t(String(port["puesto"]))]
			return
		if Vector2(pu.x - p.x, pu.z - p.z).length() < 3.5:
			_cerca = {"tipo": "puerta_estadio", "n": "el estadio"}
			_aviso.text = Idiomas.t("E: entrar al estadio por la puerta del club")
			return
		## La caseta de la galería, junto al complejo.
		var gb := GaleriaClub.boca_mundo(_est)
		if absf(gb.x - p.x) < 2.2 and p.z > gb.z - 5.0 and p.z < gb.z + 3.0:
			_cerca = {"tipo": "galeria", "n": "la galería"}
			_aviso.text = Idiomas.t("E: bajar a la galería del club (al estadio)")
			return
	## Una entrada de metro (a pie).
	if modo == "pie" and metro != null:
		for a: Dictionary in metro.accesos:
			var q: Vector3 = a["pie"]
			if Vector2(q.x - p.x, q.z - p.z).length() < 4.0:
				_cerca = {"tipo": "metro", "acc": a, "n": "Ⓜ %s · %s" % [a["linea"], a["nombre"]]}
				_aviso.text = Idiomas.t("E: entrar al metro (%s, estación %s)") % [a["linea"], a["nombre"]]
				return
	if modo == "pie" and trafico != null:
		for v: Dictionary in trafico._vehiculos:
			var n: Node3D = v["nodo"]
			if not is_instance_valid(n) or float(v["alto"]) < 0.1 or float(v["alto"]) > 0.3:
				continue
			if n.position.distance_to(p) < 3.5:
				_cerca = {"tipo": "peaton", "v": v, "n": "un vecino"}
				break
	if _cerca.is_empty():
		var alcance := 30.0 if modo == "coche" else 14.0
		var mejor := alcance
		for pc: Dictionary in cb.puntos_clic:
			var q: Vector3 = pc["pos"]
			var d := Vector2(q.x - p.x, q.z - p.z).length()
			if d < mejor and d < float(pc.get("radio", 99.0)):
				mejor = d
				_cerca = {"tipo": "lugar", "k": String(pc["k"]), "n": String(pc["n"])}
	## Cualquier fachada de manzana: se puede entrar (etapa 6). El tipo y el
	## nombre salen del tramo de calle, así que son siempre los mismos.
	if _cerca.is_empty() and modo == "pie":
		var ed := edificio_en(p)
		if not ed.is_empty():
			_cerca = {"tipo": "lugar", "k": String(ed["k"]), "n": String(ed["n"])}
	if _cerca.is_empty():
		_aviso.text = ""
	elif _cerca["tipo"] == "peaton":
		_aviso.text = Idiomas.t("E: hablar con %s") % _cerca["n"]
	else:
		_aviso.text = "E: %s" % _cerca["n"]

func _physics_process(delta: float) -> void:
	if cuerpo == null:
		return
	if estado in ["anden", "estadio", "interior", "puerta"]:
		_actualizar_mano("pie", 0.0, 1.0, 0.0)
	if estado == "anden":
		_mover_en_anden(delta)
		return
	if estado == "tren":
		_viajar(delta)
		return
	if estado == "estadio":
		_mover_en_estadio(delta)
		return
	if estado == "interior":
		_mover_en_interior(delta)
		return
	if estado == "puerta":
		_andar_solo(delta)
		return
	_cerrar_puerta_si_lejos()
	var e := _entrada()
	if modo == "coche":
		_conducir(e, delta)
	else:
		var corre := Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_joy_button_pressed(0, JOY_BUTTON_A)
		## Aceleración y frenada suaves: arrancar y parar no es instantáneo.
		var objetivo := (VEL_CORRER if corre else VEL_PIE) * clampf(e.y, -0.5, 1.0)
		vel = move_toward(vel, objetivo, (7.0 if absf(objetivo) > absf(vel) else 12.0) * delta)
		rumbo -= e.x * delta * 2.6
		if _es_dt:
			_animar_dt(vel)
		elif _anim != null:
			if _t_gesto_propio > 0.0 and absf(vel) < 0.05:
				_t_gesto_propio -= delta
			else:
				if _t_gesto_propio > 0.0 and _anim.has_animation("caminar"):
					_anim.play("caminar")
				_t_gesto_propio = 0.0
				_anim.speed_scale = absf(vel) / 1.4 if absf(vel) > 0.05 else 0.0
			_sonar_pasos(vel)
	var adelante := Vector3(sin(rumbo), 0, cos(rumbo))
	var r := RADIO_COCHE if modo == "coche" else RADIO_PIE
	## En pasos de 30 cm como mucho (17-10, caza de bugs): con un tirón de
	## fotogramas el coche avanzaba metros de golpe y se saltaba vallas finas.
	var paso_total := adelante * vel * delta
	var trozos := maxi(1, ceili(paso_total.length() / 0.3))
	for _k in trozos:
		if not _mover_un_trozo(paso_total / float(trozos), r):
			break
	cuerpo.rotation.y = rumbo
	if modo == "coche":
		cuerpo.rotation.x = _cabeceo
		cuerpo.rotation.z = _balanceo
	_colocar_camara(delta)
	## Qué hay cerca (puertas, metro, vecinos, fachadas): ~370 µs por búsqueda;
	## basta unas 8 veces por segundo o al dar medio metro (15-10-2026).
	_t_cerca -= delta
	if _t_cerca <= 0.0 or cuerpo.position.distance_squared_to(_p_cerca) > 0.25:
		_t_cerca = 0.12
		_p_cerca = cuerpo.position
		_buscar_cerca()
	## Gente alrededor: los peatones lejanos reaparecen cerca (a la espalda).
	_t_gente -= delta
	if _t_gente <= 0.0 and trafico != null and estado == "calle":
		var mira := -camara.global_transform.basis.z
		## La primera vez (al empezar a pasear) se llena el entorno de golpe.
		## Cuánta gente alrededor: menos en calidad media o con el motor ligero.
		var max_gente := 18 if (Calidad.motor_ligero or Calidad.elegida == Calidad.MEDIO) else 34
		trafico.reciclar_peatones(cuerpo.position, mira, 95.0, max_gente if _t_gente < -100.0 else 3, max_gente, _t_gente < -100.0)
		_t_gente = 1.2
	var corriendo := modo != "coche" and absf(vel) > VEL_PIE * 1.15
	_actualizar_mano("coche" if modo == "coche" else ("correr" if corriendo else "pie"), absf(vel) * 3.6,
		VEL_COCHE * 3.6 if modo == "coche" else VEL_CORRER * 3.6, absf(vel) * delta)
	_hud.text = (Idiomas.t("🚗 Conduciendo") if modo == "coche" else Idiomas.t("🚶 A pie")) + Idiomas.t("  ·  %d km/h  ·  W/S/A/D o mando · %sE: interactuar · Esc: volver al mapa") % [
		int(absf(vel) * 3.6), "" if modo == "coche" else Idiomas.t("Mayús: correr · V: vista · ")]
	## Dónde estás: el nombre de la calle (o el cruce).
	if cb != null and cb.expansion != null:
		var calle := cb.expansion.nombre_calle_en(cuerpo.position)
		if calle != "":
			_hud.text = "📍 %s\n%s" % [calle, _hud.text]
	if _t_burbuja > 0.0:
		_t_burbuja -= delta
		if _t_burbuja <= 0.0:
			_burbuja.visible = false
			if _cuadro != null:
				_cuadro.cerrar()

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
	if k == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		salir.emit()
	elif k == KEY_E:
		get_viewport().set_input_as_handled()
		_usar()
	elif k == KEY_V and modo == "coche" and estado == "calle":
		cam_coche = (cam_coche + 1) % 3
		_aviso.text = [Idiomas.t("Cámara: tercera persona"), Idiomas.t("Cámara: capó"), Idiomas.t("Cámara: primera persona")][cam_coche]
	elif k == KEY_V:
		primera_persona = not primera_persona
		_raton_en_primera_persona()
		_aviso.text = Idiomas.t("Primera persona") if primera_persona else Idiomas.t("Tercera persona")
	elif k == KEY_C and estado == "tren":
		_ventana = not _ventana
