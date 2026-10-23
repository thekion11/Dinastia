extends "res://visor/explorador_ciudad_p2.gd"
## (Parte 3 de 6 de `explorador_ciudad.gd`.)

func _colocar_camara(delta: float) -> void:
	## PLANO DE CONVERSACIÓN (13-10-2026): mientras alguien te habla, la cámara
	## se pone tras tu hombro y encuadra su cara (antes tu espalda la tapaba).
	if _hablando_con != null and is_instance_valid(_hablando_con) and _t_burbuja > 0.0 \
			and estado in ["calle", "interior"] and modo != "coche" and not primera_persona:
		var yo := cuerpo.position
		var el := _hablando_con.global_position
		var dir := Vector3(el.x - yo.x, 0, el.z - yo.z)
		if dir.length() > 0.2:
			dir = dir.normalized()
			var lado := dir.cross(Vector3.UP)
			var plano := yo - dir * 0.9 + lado * 0.6 + Vector3(0, 1.7, 0)
			var k := 1.0 if delta >= 1.0 else minf(1.0, delta * 5.0)
			camara.position = camara.position.lerp(plano, k)
			## Se mira algo por debajo de la cara: así queda en el tercio de arriba
			## y el cuadro de diálogo no la tapa.
			camara.look_at(el + Vector3(0, 1.2, 0) - lado * 0.25, Vector3.UP)
			return
	## EN COCHE (V cambia): 1 = capó, 2 = interior con volante dibujado.
	if modo == "coche" and cam_coche > 0:
		var dir_c := Vector3(sin(rumbo), 0, cos(rumbo))
		var der := Vector3(cos(rumbo), 0, -sin(rumbo))
		if cam_coche == 1:
			camara.position = cuerpo.position + Vector3(0, 1.25, 0) + dir_c * 2.15
			cuerpo.visible = true
		else:
			## PRIMERA PERSONA (17-10-2026): los ojos del conductor dentro de una
			## cabina 3D (salpicadero, volante que gira, pilares, retrovisor) que
			## va pegada a la cámara; con la velocidad, un leve temblor.
			var tiembla := Vector3(0, sin(_t_cabina * 23.0) * 0.004 * clampf(absf(vel) / 20.0, 0.0, 1.0), 0)
			camara.position = cuerpo.position + Vector3(0, 1.12, 0) + dir_c * 0.05 + der * 0.34 + tiembla
			cuerpo.visible = false
		var mira_dir := dir_c.rotated(Vector3.UP, -_volante * (0.18 if cam_coche == 1 else 0.28))
		camara.look_at(camara.position + mira_dir * 8.0 + Vector3(0, -0.2, 0), Vector3.UP)
		camara.rotate_object_local(Vector3.FORWARD, -_balanceo * 0.6)
		_t_cabina += delta if delta < 1.0 else 0.0
		_cabina_3d(cam_coche == 2)
		_fov_hacia(70.0 if cam_coche == 2 else 68.0, delta)
		_volante_ui(false)
		return
	_cabina_3d(false)
	_volante_ui(false)
	if modo == "coche" and not cuerpo.visible:
		cuerpo.visible = true
	## PRIMERA PERSONA (V): la cámara en los ojos, el cuerpo escondido.
	if primera_persona and (modo != "coche"):
		var dir_fp := Vector3(sin(rumbo), 0, cos(rumbo))
		camara.position = cuerpo.position + Vector3(0, 1.62, 0) + dir_fp * 0.18
		camara.look_at(camara.position + dir_fp * 5.0 + Vector3(0, -0.15, 0), Vector3.UP)
		cuerpo.visible = false
		return
	if modo != "coche" and not cuerpo.visible and not _sentado_fp():
		cuerpo.visible = true
	var atras := 5.5
	var alto := 2.6
	var adelante := Vector3(sin(rumbo), 0, cos(rumbo))
	## EN COCHE, CÁMARA DE PERSECUCIÓN (17-10-2026): sigue al coche con retraso
	## en el giro (en las curvas se ve el costado), se aleja y abre el ángulo
	## con la velocidad, y mira por delante del capó.
	if modo == "coche":
		var rapidez := clampf(absf(vel) / 25.0, 0.0, 1.0)
		_cam_yaw = lerp_angle(_cam_yaw, rumbo, clampf(delta * (2.2 + rapidez * 1.5), 0.0, 1.0)) if delta < 1.0 else rumbo
		adelante = Vector3(sin(_cam_yaw), 0, cos(_cam_yaw))
		atras = lerpf(8.0, 11.5, rapidez)
		alto = lerpf(3.0, 3.8, rapidez)
		_fov_hacia(lerpf(66.0, 80.0, rapidez), delta)
	else:
		_fov_hacia(65.0, delta)
	var deseo := cuerpo.position - adelante * atras + Vector3(0, alto, 0)
	if estado == "anden" and not _acc.is_empty() and not bool(_acc["elevada"]):
		## BAJO TIERRA la cámara no puede salirse del vestíbulo: se queda entre
		## la vía y la pared del fondo, y bajo el techo.
		var rel := deseo - _anden_c
		var l_lat := clampf(rel.dot(_anden_lat), -5.0, 3.0)
		var l_lon := clampf(rel.dot(_anden_lon), -29.0, 29.0)
		deseo = _anden_c + _anden_lat * l_lat + _anden_lon * l_lon
		deseo.y = minf(cuerpo.position.y + alto, MetroCiudad.PROF_TUNEL + 5.6)
	elif estado == "interior" and is_instance_valid(_int):
		## Dentro de la sala la cámara no sale de las paredes ni pasa del techo.
		var t := _int.tam_sala()
		deseo.x = clampf(deseo.x, _INT_ORIGEN.x - t.x * 0.5 + 0.3, _INT_ORIGEN.x + t.x * 0.5 - 0.3)
		deseo.z = clampf(deseo.z, _INT_ORIGEN.z - t.z * 0.5 + 0.3, _INT_ORIGEN.z + t.z * 0.5 - 0.3)
		deseo.y = minf(deseo.y, _INT_ORIGEN.y + t.y - 0.3)
	elif estado == "calle":
		## La cámara no se mete dentro de los edificios: si el punto de detrás
		## cae en una huella, se acerca al personaje hasta el último sitio libre
		## (etapa 1, 8-10-2026).
		var desde := cuerpo.position + Vector3(0, alto, 0)
		var paso := (deseo - desde)
		var largo := paso.length()
		if largo > 0.01 and not libre_obst(deseo, 0.3):
			var bueno := desde
			var k := 0.5
			while k <= largo:
				var q := desde + paso / largo * k
				if not libre_obst(q, 0.3):
					break
				bueno = q
				k += 0.5
			deseo = bueno
	camara.position = camara.position.lerp(deseo, clampf(delta * (8.0 if modo == "coche" else 5.0), 0.0, 1.0)) if delta < 1.0 else deseo
	if modo == "coche":
		camara.look_at(cuerpo.position + Vector3(0, 1.2, 0) + Vector3(sin(rumbo), 0, cos(rumbo)) * (5.0 + absf(vel) * 0.25), Vector3.UP)
		## La sacudida del choque (M-172), que se apaga en medio segundo.
		if _sacudida_golpe > 0.0:
			camara.position += Vector3(randf_range(-1.0, 1.0), randf_range(-0.5, 0.5), randf_range(-1.0, 1.0)) * _sacudida_golpe * 0.18
			_sacudida_golpe = maxf(_sacudida_golpe - (delta if delta < 1.0 else 0.0) * 2.0, 0.0)
	else:
		camara.look_at(cuerpo.position + Vector3(0, 1.4, 0) + adelante * 4.0, Vector3.UP)

func _salir_del_edificio() -> void:
	_fundido()
	if is_instance_valid(_int):
		_int.queue_free()
	if is_instance_valid(_int_raiz):
		_int_raiz.queue_free()
	_int = null
	_int_raiz = null
	estado = "calle"
	_t_gente = -1000.0   ## al volver a la calle se llena el entorno
	_bajo_tierra(false)
	_vel_pie = 0.0
	cuerpo.visible = not primera_persona
	cuerpo.position = _calle_pos
	rumbo = _calle_rumbo
	cuerpo.rotation.y = rumbo
	_colocar_camara(1.0)

func _portero() -> Dictionary:
	var pe := get_tree().get_first_node_in_group("personal_club") as PersonalEstadio
	if pe == null:
		return {}
	var g := pe.buscar("portero")
	if g.is_empty() or not is_instance_valid(g["nodo"]) or not (g["nodo"] as Node3D).visible:
		return {}
	return g

func _salir_del_estadio() -> void:
	_fundido()
	Optimizar.butacas_livianas(cb, true)
	estado = "calle"
	_t_gente = -1000.0   ## al volver a la calle se llena el entorno
	cb.mostrar_rotulos(_rotulos_antes)
	var pu: Vector3 = _est["puerta"]
	cuerpo.position = CityBuilder.ESTADIO_EN + pu + Vector3(0, 0, 3.2)
	cuerpo.position.y = altura_suelo(cuerpo.position.x, cuerpo.position.z)
	rumbo = 0.0
	_aviso.text = ""
	## El portero despide con la mano.
	var port := _portero()
	if not port.is_empty():
		var pe := get_tree().get_first_node_in_group("personal_club") as PersonalEstadio
		pe.atender(port, cuerpo.position - CityBuilder.ESTADIO_EN, true)
		pe.gesto(port, ["saludo_mano", "saludar_publico"])
		port["quieto"] = false
		_burbuja.text = "💬 " + Idiomas.t("¡Hasta luego, míster!")
		## Pequeña: el portero está a dos pasos de la cámara.
		_burbuja.pixel_size = 0.0035
		_burbuja.position = (port["nodo"] as Node3D).global_position + Vector3(0, 2.25, 0)
		_burbuja.visible = true
		_t_burbuja = 3.0

## El ascensor del edificio del club: misma x y z, otra planta. Los sótanos
## van sin sol ni niebla (como el metro).
func _ir_a_planta(p: int) -> void:
	var antes := _planta
	_planta = p
	cuerpo.position.y = RecorridoClub.y_de(p)
	_zona_est = "?"
	if (antes < 0) != (p < 0):
		_bajo_tierra(p < 0)

func _subir_al_tren(k: int) -> void:
	estado = "tren"
	_tren_k = k
	_bajar_en_proxima = false
	_ventana = false
	cuerpo.visible = false
	_luz_cam.visible = true

func _usar_en_anden() -> void:
	var k := metro.tren_parado_en(_linea, _idx)
	if k >= 0:
		_subir_al_tren(k)
		return
	## Salir a la calle por donde se entró (o por la boca de esta estación).
	estado = "calle"
	_t_gente = -1000.0   ## al volver a la calle se llena el entorno
	_luz_cam.visible = false
	_bajo_tierra(false)
	var pie: Vector3 = _acc.get("pie", cuerpo.position)
	cuerpo.position = Vector3(pie.x, altura_suelo(pie.x, pie.z), pie.z)
	_colocar_camara(1.0)

# ============================================================== EL METRO

## Del pie de la escalera (o de la boca) al andén.
func _entrar_al_anden(a: Dictionary) -> void:
	_acc = a
	_linea = String(a["linea"])
	_idx = int(a["idx"])
	var l := metro.linea(_linea)
	var dir: Vector3 = l["dir"]
	var p: Vector3 = l["estaciones"][_idx]
	_anden_lon = dir.abs()
	_anden_lat = Vector3(dir.z, 0, -dir.x).abs()
	if bool(a["elevada"]):
		var lado := float(a.get("lado", 1.0))
		_anden_c = p + _anden_lat * lado * MetroCiudad.ANDEN_LAT
		_anden_c.y = MetroCiudad.ALTO_VIADUCTO + 0.6 + MetroCiudad.PISO_COCHE
		_anden_medio = Vector2(MetroCiudad.ANDEN_ANCHO * 0.5 - 0.4, MetroCiudad.ANDEN_LARGO * 0.5 - 1.0)
	else:
		_anden_c = p + _anden_lat * MetroCiudad.ANDEN_LAT * 1.6
		_anden_c.y = MetroCiudad.PROF_TUNEL + MetroCiudad.PISO_COCHE
		_anden_medio = Vector2(MetroCiudad.ANDEN_ANCHO * 1.1 - 0.5, MetroCiudad.ANDEN_LARGO * 0.5 - 1.0)
	estado = "anden"
	cuerpo.visible = true
	cuerpo.position = a["anden"] if bool(a["elevada"]) else _anden_c
	cuerpo.position.y = _anden_c.y
	_luz_cam.visible = not bool(a["elevada"])
	_bajo_tierra(not bool(a["elevada"]))
	if not bool(a["elevada"]):
		rumbo = atan2(_anden_lon.x, _anden_lon.z)
	_colocar_camara(1.0)

func _bajar_del_tren() -> void:
	var parada := metro.estacion_del_tren(_linea, _tren_k)
	if parada < 0:
		return
	var l := metro.linea(_linea)
	var a := {"linea": _linea, "idx": parada, "elevada": bool(l["elevada"]), "nombre": String(MetroCiudad.NOMBRES[_linea][parada]), "lado": 1.0}
	## La salida a la calle de la estación de llegada.
	for acc: Dictionary in metro.accesos:
		if String(acc["linea"]) == _linea and int(acc["idx"]) == parada and float(acc.get("lado", 1.0)) > 0.0:
			a["pie"] = acc["pie"]
			a["anden"] = acc["anden"]
	if not a.has("anden"):
		a["anden"] = Vector3.ZERO
	_entrar_al_anden(a)
	if bool(a["elevada"]):
		var tren: Node3D = l["nodos"][_tren_k]
		cuerpo.position = Vector3(cuerpo.position.x, _anden_c.y, cuerpo.position.z)
		## Aparece frente a la puerta del coche central.
		var rel := tren.global_position - _anden_c
		var lo := clampf(rel.dot(_anden_lon), -_anden_medio.y, _anden_medio.y)
		cuerpo.position = _anden_c + _anden_lon * lo

func _entrar_en_edificio(k: String) -> void:
	_fundido()
	_int_raiz = Node3D.new()
	_int_raiz.name = "InteriorPaseo"
	_int_raiz.position = _INT_ORIGEN
	cb.add_child(_int_raiz)
	_int = InteriorInstalacion.en_mundo(_int_raiz, k, null)
	if _int == null:
		_int_raiz.queue_free()
		return
	_capa.add_child(_int)   ## (oculto: solo para que la gente se mueva)
	## El mobiliario es sólido: círculos sacados de la propia sala (mesas, sofás,
	## mostradores, estanterías...), sin paredes ni suelo.
	_int_circulos = Optimizar.obstaculos(_int_raiz, [] as Array[Rect2], 0.4, 0.5)
	_calle_pos = cuerpo.position
	_calle_rumbo = rumbo
	estado = "interior"
	_bajo_tierra(true)
	_vel_pie = 0.0
	var t := _int.tam_sala()
	cuerpo.position = _INT_ORIGEN + Vector3(0, 0.05, t.z * 0.5 - 1.6)
	rumbo = PI
	cuerpo.rotation.y = rumbo
	cuerpo.visible = not primera_persona
	_cerca = {}
	_aviso.text = ""
	_colocar_camara(1.0)

# ============================================================== EL ESTADIO (2.0)

## Cruza la puerta del club: ya dentro, en el vestuario.
func _entrar_al_estadio() -> void:
	_fundido()
	Optimizar.butacas_livianas(cb, false)
	estado = "estadio"
	_planta = 0
	## Los rótulos flotantes del mapa se ven a través de las paredes: fuera.
	_rotulos_antes = cb._rotulos.visible if cb._rotulos != null else true
	cb.mostrar_rotulos(false)
	var pu: Vector3 = _est["puerta"]
	cuerpo.position = CityBuilder.ESTADIO_EN + pu + Vector3(0, 0, -2.2)
	rumbo = PI
	_zona_est = ""
	_aviso.text = ""
	Sonido.toca("puerta", Sonido.Bus.EFECTOS)

## El portero ya abrió: el DT sube el escalón y entra andando.
func _cruzar_puerta() -> void:
	var pu: Vector3 = CityBuilder.ESTADIO_EN + (_est["puerta"] as Vector3)
	## Hacia la puerta sin dar la vuelta (si ya está pegado, entra recto).
	_auto = [Vector3(pu.x, cuerpo.position.y, maxf(cuerpo.position.z - 0.3, pu.z + 0.6)), Vector3(pu.x, cuerpo.position.y, pu.z - 1.6)]
	estado = "puerta"
	_aviso.text = ""

func _entrada() -> Vector2:
	var x := float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
	var y := float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)) - float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))
	var jx := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var jy := -Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	if absf(jx) > 0.2:
		x = jx
	if absf(jy) > 0.2:
		y = jy
	if _tactil_vec != Vector2.ZERO:
		x = clampf(_tactil_vec.x, -1.0, 1.0)
		y = clampf(_tactil_vec.y, -1.0, 1.0)
	return Vector2(x, y)

## Arriba de la escalera mecánica: a la calle, delante de la caseta.
func _subir_de_la_galeria() -> void:
	_fundido()
	estado = "calle"
	_t_gente = -1000.0   ## al volver a la calle se llena el entorno
	_planta = 0
	_bajo_tierra(false)
	cb.mostrar_rotulos(_rotulos_antes)
	cuerpo.position = GaleriaClub.boca_mundo(_est) + Vector3(0, 0, 1.6)
	cuerpo.position.y = altura_suelo(cuerpo.position.x, cuerpo.position.z)
	rumbo = 0.0
	_aviso.text = ""
	_colocar_camara(1.0)

func _sonar_pasos(v: float) -> void:
	if modo != "pie" or absf(v) < 0.3:
		return
	_hasta_paso -= absf(v) * get_physics_process_delta_time()
	if _hasta_paso <= 0.0:
		_hasta_paso = 1.1 if absf(v) > 3.0 else 0.7
		Sonido.toca("paso", Sonido.Bus.EFECTOS)
static func estilo_caminata() -> String:
	return String(AjustesCiudad.valor("caminata", "formal"))

func _animar_dt(v: float) -> void:
	_sonar_pasos(v)
	if not _es_dt or _anim == null:
		return
	## Un gesto en curso (al charlar) no se corta mientras estés quieto.
	if _t_gesto_propio > 0.0:
		_t_gesto_propio -= get_physics_process_delta_time()
		if absf(v) < 0.05:
			return
		_t_gesto_propio = 0.0
	var quiere := "parado"
	if absf(v) > 3.0 and _anim.has_animation("correr"):
		quiere = "correr"
	var vel_anim := 1.0
	if quiere == "parado" and absf(v) > 0.05 and _anim.has_animation("caminar"):
		var est: Array = ESTILOS_CAMINATA.get(estilo_caminata(), ESTILOS_CAMINATA["formal"])
		quiere = String(est[0]) if _anim.has_animation(String(est[0])) else "caminar"
		vel_anim = float(est[1])
	if _anim.current_animation != quiere and _anim.has_animation(quiere):
		_anim.play(quiere, 0.25)
	_anim.speed_scale = vel_anim
