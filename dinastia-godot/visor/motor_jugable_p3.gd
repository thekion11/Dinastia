extends "res://visor/motor_jugable_p2.gd"
## [Capa 3/12 de `motor_jugable.gd`] _mio_mas_cercano, _control_de_equipo, _aplicar_cansancio, _anadido_de, segundos_anadidos, minutos_anadidos … (+15)

func _mio_mas_cercano(local: bool, menos: Dictionary) -> Dictionary:
	var b := balon.position + Vector3(vel_balon.x, 0, vel_balon.z) * 0.3
	var mejor: Dictionary = {}
	var md := 999.0
	for q: Dictionary in jugadores:
		if bool(q["es_local"]) != local or q == menos:
			continue
		if bool(q["por"]) and not _en_su_area(q, balon.position):
			continue
		var d := pos(q).distance_to(Vector3(b.x, 0, b.z))
		if d < md:
			md = d
			mejor = q
	return mejor

## CONTROL DEL EQUIPO, COMO EN FC: manejas al que lleva el balón; sin balón, al
## que va a recibir el pase o al más cercano a la pelota; `jugar_cambiar` salta
## al siguiente más cercano y durante un momento manda tu elección.
func _control_de_equipo() -> void:
	var mio := control_equipo == 0
	if not poseedor.is_empty() and bool(poseedor["es_local"]) == mio and not (bloqueo and poseedor != usuario and not usuario.is_empty()):
		if poseedor != usuario:
			_poner_usuario(poseedor)
		return
	var pedir := Input.is_action_just_pressed("jugar_cambiar")
	## BLOQUEO DE JUGADOR (L3 + R3): te quedas con el mismo hasta quitarlo.
	if bloqueo and not usuario.is_empty() and not pedir:
		return
	if pedir:
		bloqueo = false
		_manual_hasta = t + 1.5
	var cand := _mio_mas_cercano(mio, usuario if pedir else {})
	if cand.is_empty():
		return
	if usuario.is_empty() or pedir:
		_poner_usuario(cand)
		return
	if t < _manual_hasta:
		return
	var modo_cambio := Mando.ayuda("cambio")
	if modo_cambio == "manual":
		return
	if not pase_a.is_empty() and bool(pase_a["es_local"]) == mio and pase_a != usuario:
		_poner_usuario(pase_a)
		return
	if modo_cambio == "semi":
		return
	var b := balon.position
	if cand != usuario and pos(usuario).distance_to(b) - pos(cand).distance_to(b) > 5.0:
		_poner_usuario(cand)

## El cansancio en los atributos: cada segundo, de 100 % fresco a ~84 % fundido.
func _aplicar_cansancio() -> void:
	for p: Dictionary in jugadores:
		var base: Dictionary = p.get("attr_base", {})
		if base.is_empty():
			continue
		var f := 0.74 + 0.26 * forma_fisica(p)
		for k: String in base:
			if k != "fis":
				p["attr"][k] = float(base[k]) * f

func _anadido_de(m: int) -> float:
	return float(anadido[m - 1]) if anadido.size() >= m else 0.0

## Segundos de partido jugados en el añadido (-1 si no se está en él).
func segundos_anadidos() -> float:
	var d := dur_mitad()
	if t <= d:
		return -1.0
	return (t - d) / d * minutos_de_mitad() * 60.0

## Los minutos de añadido que enseña el cuarto árbitro en esta mitad.
func minutos_anadidos() -> int:
	return int(ceil(_anadido_de(mitad) / dur_mitad() * minutos_de_mitad()))

## Sortea el añadido: 1-3' la primera parte y 2-5' la segunda, más con goles,
## cambios o faltas (aquí, simple y con la semilla del partido). En la
## prórroga, 0-1' y 1-2'.
func sortear_anadido() -> void:
	var m1 := float(_rng.randi_range(1, 3))
	var m2 := float(_rng.randi_range(2, 5))
	## Los de la prórroga salen de los otros, sin tirar más dados: así un
	## partido de liga sigue la misma secuencia aleatoria que antes.
	var m3 := float(int(m1 + m2) % 2)
	var m4 := 1.0 + float(int(m2) % 2)
	var d3 := duracion_mitad / 3.0
	anadido = [m1 / 45.0 * duracion_mitad, m2 / 45.0 * duracion_mitad, m3 / 15.0 * d3, m4 / 15.0 * d3]

## Al empezar el añadido, el principal lo indica con los brazos (y el cuarto
## árbitro levanta el cartel: eso lo pone la vista).
func _revisar_anadido_arbitro() -> void:
	if estado != "juego" or _anadido_gesto.has(mitad) or anadido.is_empty():
		return
	if segundos_anadidos() >= 0.0 and minutos_anadidos() > 0:
		_anadido_gesto[mitad] = true
		_gesto_arbitro("arbitro_tiempo_anadido", 0.0, 1.8)

## La cartulina, en la mano que levanta el clip (la izquierda), creada la
## primera vez que hace falta.
func _poner_tarjeta(a: Dictionary, color: String) -> void:
	if color == "":
		if _tarjeta_arb != null:
			_tarjeta_arb.visible = false
		return
	if _tarjeta_arb == null or not is_instance_valid(_tarjeta_arb):
		_tarjeta_arb = null
		var esqs := (a["node"] as Node).find_children("*", "Skeleton3D", true, false)
		if esqs.is_empty():
			return
		var esq: Skeleton3D = esqs[0]
		if esq.find_bone("hand_l") < 0:
			return
		var ba := BoneAttachment3D.new()
		ba.bone_name = "hand_l"
		esq.add_child(ba)
		var k := 1.0 / maxf(esq.global_transform.basis.get_scale().y, 0.001) if esq.is_inside_tree() else 1.0
		var caja := BoxMesh.new()
		caja.size = Vector3(0.075, 0.105, 0.004)
		_tarjeta_arb = MeshInstance3D.new()
		_tarjeta_arb.name = "TarjetaArbitro"
		_tarjeta_arb.mesh = caja
		_tarjeta_arb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_tarjeta_arb.scale = Vector3.ONE * k
		_tarjeta_arb.position = Vector3(0, 0.13, 0.02) * k
		ba.add_child(_tarjeta_arb)
	var m := StandardMaterial3D.new()
	var c := Color(0.86, 0.08, 0.1) if color == "roja" else Color(1.0, 0.86, 0.1)
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 0.35
	m.roughness = 0.6
	_tarjeta_arb.material_override = m
	_tarjeta_arb.visible = true

## Devuelve true si el principal está gesticulando (no camina ese paso).
func _gestos_del_arbitro(a: Dictionary, delta: float) -> bool:
	var n: Node3D = a["node"]
	var i := 0
	while i < _gestos_arb.size():
		var g: Array = _gestos_arb[i]
		if float(g[0]) > _t_arb:
			i += 1
			continue
		_gestos_arb.remove_at(i)
		var extra: Dictionary = g[3]
		a["mira_gesto"] = extra.get("mira", null)
		a["mira_a"] = extra.get("mira_a", {})
		var ap: AnimationPlayer = a.get("anim")
		var clip := String(g[1])
		if is_instance_valid(ap) and ap.has_animation(clip):
			ap.play(clip, 0.15)
			ap.speed_scale = 1.0
			a["anim_actual"] = clip
		_arb_hasta = _t_arb + float(g[2])
		_poner_tarjeta(a, String(extra.get("tarjeta", "")))
		if clip == "arbitro_silbato":
			if String(extra.get("silbato", "silbato")) != "":
				gesto_arbitro.emit(String(extra.get("silbato", "silbato")))
		else:
			gesto_arbitro.emit(clip)
	if _t_arb >= _arb_hasta:
		if _tarjeta_arb != null and _tarjeta_arb.visible:
			_tarjeta_arb.visible = false
		return false
	## Mientras gesticula, de cara a lo que señala o a quien amonesta.
	var mira = a.get("mira_gesto")
	var quien: Dictionary = a.get("mira_a", {})
	if not quien.is_empty() and is_instance_valid(quien.get("node")):
		mira = (quien["node"] as Node3D).position
	if mira is Vector3:
		var d: Vector3 = (mira as Vector3) - n.position
		d.y = 0.0
		if d.length() > 0.3:
			n.rotation.y = lerp_angle(n.rotation.y, atan2(d.x, d.z), clampf(delta * 6.0, 0.0, 1.0))
	return true

## EL ÁRBITRO SIGUE LA JUGADA (29-9-2026). El principal va en diagonal, unos
## metros por detrás y a un lado del balón, sin meterse en la línea de pase;
## los asistentes corren su banda a la altura del balón, cada uno en su mitad.
## La z del penúltimo jugador del equipo que defiende la portería de ese lado
## (`lado` = signo de su z): la línea del fuera de juego. Contando al portero.
func linea_fuera_de_juego(lado: float) -> float:
	var zs: Array[float] = []
	for p: Dictionary in jugadores:
		if signf(_arco_propio(p).z) == signf(lado):
			zs.append(pos(p).z * signf(lado))
	if zs.size() < 2:
		return 0.0
	zs.sort()
	return zs[zs.size() - 2] * signf(lado)

func _anim(p: Dictionary, nombre: String, gesto: bool, dur_max := 1.4) -> void:
	var ap: AnimationPlayer = p.get("anim")
	if not is_instance_valid(ap) or not ap.has_animation(nombre):
		return
	if gesto:
		ap.play(nombre, 0.1)
		ap.speed_scale = 1.0
		p["gesto_hasta"] = t + minf(ap.get_animation(nombre).length, dur_max)
		p["anim_actual"] = nombre
	elif String(p.get("anim_actual", "")) != nombre:
		ap.play(nombre, 0.2)
		p["anim_actual"] = nombre

func _mover_arbitros(delta: float) -> void:
	if balon == null:
		return
	_t_arb += delta
	_revisar_anadido_arbitro()
	var b := balon.position
	for a: Dictionary in arbitros:
		var n: Node3D = a.get("node")
		if not is_instance_valid(n):
			continue
		if String(a.get("id", "")) == "arbitro" and _gestos_del_arbitro(a, delta):
			continue
		var obj: Vector3
		match String(a.get("id", "")):
			"arbitro":
				obj = Vector3(clampf(b.x - 9.0 * signf(b.x + 0.01), -26.0, 26.0), 0, clampf(b.z - 6.0, -40.0, 40.0))
			## M-107 (20-10): a la altura del PENÚLTIMO defensor (la línea del
			## fuera de juego), o del balón si está más cerca de la portería.
			"linea_a":
				obj = Vector3(-36.5, 0, clampf(minf(b.z, linea_fuera_de_juego(-1.0)), -50.0, 0.0))
			_:
				obj = Vector3(36.5, 0, clampf(maxf(b.z, linea_fuera_de_juego(1.0)), 0.0, 50.0))
		## En la tanda: el principal al borde del área chica y un asistente en la
		## línea de gol (fuera del plano del lanzador).
		if estado == "tanda":
			match String(a.get("id", "")):
				"arbitro":
					obj = Vector3(-7.5, 0, LARGO - 12.0)
				"linea_a":
					obj = Vector3(-36.5, 0, 0.0)
				_:
					obj = Vector3(PALO + 2.2, 0, LARGO - 0.3)
		var hacia := obj - n.position
		hacia.y = 0.0
		var v := minf(hacia.length() * 1.6, 6.5)
		var sp := 0.0
		if hacia.length() > 0.4:
			n.position += hacia.normalized() * v * delta
			sp = v
		## Siempre de cara al juego.
		var mira := b - n.position
		mira.y = 0.0
		if mira.length() > 0.5:
			n.rotation.y = lerp_angle(n.rotation.y, atan2(mira.x, mira.z), clampf(delta * 5.0, 0.0, 1.0))
		_anim(a, "parado" if sp < 0.5 else ("trotar" if sp < 4.5 else "correr"), false)

## Orden de lanzadores: de mejor a peor tiro, el portero al final.
func _orden_tanda(es_local: bool) -> Array:
	var campo: Array = []
	var porteros: Array = []
	for p: Dictionary in jugadores:
		if bool(p["es_local"]) != es_local:
			continue
		if bool(p["por"]):
			porteros.append(p)
		else:
			campo.append(p)
	campo.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["attr"]["tir"]) > float(b["attr"]["tir"]))
	return campo + porteros

func _empezar_tanda() -> void:
	estado = "tanda"
	_t_estado = 0.0
	poseedor = {}
	pase_a = {}
	_jugada = {}
	_tiro_vivo = {}
	vel_balon = Vector3.ZERO
	apuntando = false
	cargando = false
	usuario = {}
	tanda = {"tiros": [[], []], "orden": [_orden_tanda(true), _orden_tanda(false)],
		"empieza": _rng.randi() % 2, "fase": "entrar", "lanzador": {}, "portero": {}, "lado": 0, "cruzo": false}
	balon.position = TANDA_PUNTO
	for p: Dictionary in jugadores:
		p["gesto_hasta"] = 0.0
	aviso.emit("🥅 Tanda de penales")
	tanda_empieza.emit()
	cambio_estado.emit("tanda")

func _terminar() -> void:
	estado = "fin"
	aviso.emit("🏁 Final: %d-%d" % goles)
	cambio_estado.emit(estado)
	terminado.emit()

func _fin_de_mitad() -> void:
	var empate := int(goles[0]) == int(goles[1])
	## El silbato largo, con los brazos arriba (M-106).
	## (El sonido sale ya: tras el final el motor deja de correr.)
	gesto_arbitro.emit("fin")
	_gesto_arbitro("arbitro_silbato", 0.0, 1.2, {"silbato": ""})
	_gesto_arbitro("arbitro_tiempo_anadido", 1.2, 1.8)
	if mitad == 1 or mitad == 3:
		estado = "descanso"
		_t_estado = 0.0
		aviso.emit(("⏸ Descanso: %d-%d" if mitad == 1 else "⏱ Cambio de campo: %d-%d") % goles)
		cambio_estado.emit(estado)
	elif mitad == 2 and eliminatoria and empate:
		## LA PRÓRROGA: descanso corto y dos tiempos de 15'.
		estado = "descanso"
		_t_estado = 0.0
		prorroga = true
		aviso.emit("⏱ Prórroga: %d-%d" % goles)
		prorroga_empieza.emit()
		cambio_estado.emit("prorroga")
	elif mitad == 4 and empate:
		_empezar_tanda()
	else:
		_terminar()

func _gol(en_arco_visita: bool) -> void:
	## El arco de +Z es el de la visita: gol del local.
	var de_local := en_arco_visita
	_contar("gol_%s" % String(_tiro_vivo.get("clase", "sin_tiro")))
	_tiro_vivo = {}
	goles[0 if de_local else 1] += 1
	var autor := ultimo_toque
	var autor_id := String(autor.get("id", ""))
	var asist_id := ""
	## Gol en contra: el último toque fue de un defensor.
	if not autor.is_empty() and bool(autor["es_local"]) != de_local:
		autor_id = ""
	elif not penultimo_toque.is_empty() and bool(penultimo_toque["es_local"]) == de_local and penultimo_toque != autor:
		asist_id = String(penultimo_toque.get("id", ""))
	if not usuario.is_empty():
		if autor_id == String(usuario["id"]):
			stats["goles"] += 1
		if asist_id == String(usuario["id"]):
			stats["asist"] += 1
	vel_balon *= 0.15
	poseedor = {}
	estado = "gol"
	_t_estado = 0.0
	saque = {"gol_local": de_local}
	margen_gol = INF
	_sumar_anadido(0.75)
	lineas_gol = {}
	if autor_id != "" and String(_margen_recepcion.get("id", "")) == autor_id and t - float(_margen_recepcion.get("t", -99.0)) < 12.0:
		margen_gol = float(_margen_recepcion["m"])
		if _margen_recepcion.has("linea"):
			lineas_gol = {"linea": float(_margen_recepcion["linea"]), "atacante": float(_margen_recepcion["z"])}
	_margen_recepcion = {}
	gol.emit(de_local, autor_id, asist_id)
	cambio_estado.emit(estado)
	## El goleador celebra según su carácter: primero corre al córner (o a la
	## banda) y allí hace lo suyo; los compañeros llegan a abrazarlo.
	for q: Dictionary in jugadores:
		q["gesto_hasta"] = 0.0
	_goleador = autor if autor_id != "" else {}
	if not autor.is_empty() and autor_id != "":
		var ap: AnimationPlayer = autor.get("anim")
		var jd: Dictionary = autor.get("jugador", {})
		if is_instance_valid(ap):
			_celebra_anim = AnimExtra.celebracion(ap, String(jd.get("rasgo", "")), autor_id, not de_local, _rng)

## Postes, larguero, gol, y fuera del campo.
func _palos_y_lineas(antes: Vector3) -> void:
	var p := balon.position
	for signo: float in [-1.0, 1.0]:
		var linea := LARGO * signo
		## ¿Cruzó la línea de gol en este paso?
		if (antes.z - linea) * (p.z - linea) <= 0.0 and absf(p.z) >= LARGO - 0.001 and signf(p.z) == signo:
			## Poste: el balón pega en el palo si pasa a un radio de él.
			if p.y < LARGUERO + R and absf(absf(p.x) - PALO) < 0.12 + R:
				vel_balon.z = -vel_balon.z * 0.6
				vel_balon.x += signf(p.x) * 1.5
				balon.position.z = linea - signo * 0.2
				aviso.emit("¡AL PALO!")
				_cerrar_tiro("poste")
				return
			if absf(p.x) < PALO and absf(p.y - LARGUERO) < 0.12 + R:
				vel_balon.y = -absf(vel_balon.y) * 0.5
				vel_balon.z = -vel_balon.z * 0.5
				balon.position.z = linea - signo * 0.2
				aviso.emit("¡AL LARGUERO!")
				_cerrar_tiro("poste")
				return
			if absf(p.x) < PALO and p.y < LARGUERO:
				_gol(signo > 0.0)
				return
			## Fuera por la línea de fondo: córner o saque de puerta.
			_cerrar_tiro("fallo")
			var defiende_local := signo < 0.0   ## el local defiende -Z
			var toco_defensor := not ultimo_toque.is_empty() and bool(ultimo_toque["es_local"]) == defiende_local
			if toco_defensor:
				_empezar_saque("corner", not defiende_local, Vector3(signf(p.x) * (ANCHO - 0.3), R, linea - signo * 0.3))
			else:
				_empezar_saque("puerta", defiende_local, Vector3(signf(p.x) * 5.0, R, linea - signo * 5.5))
			return
	if absf(p.x) > ANCHO:
		var local_saca := ultimo_toque.is_empty() or not bool(ultimo_toque["es_local"])
		_empezar_saque("banda", local_saca, Vector3(signf(p.x) * (ANCHO - 0.2), R, clampf(p.z, -LARGO + 1.0, LARGO - 1.0)))

## ¿Hay un defensa del portero entre el rival y el arco?
func _hay_defensa_entre(gk: Dictionary, desde: Vector3, arco: Vector3) -> bool:
	var linea := arco - desde
	var largo := linea.length()
	for q: Dictionary in jugadores:
		if q == gk or bool(q["es_local"]) != bool(gk["es_local"]) or bool(q["por"]):
			continue
		var r := pos(q) - desde
		var u := r.dot(linea) / maxf(largo * largo, 0.01)
		if u > 0.05 and u < 0.95 and (r - linea * u).length() < 2.2:
			return true
	return false

## LA COLOCACIÓN DEL PORTERO (14-10-2026). Antes iba por la línea balón-centro
## del arco a 0,8-5,5 m, y con el balón en una banda dejaba el primer palo
## abierto. Ahora se pone en la BISECTRIZ del ángulo que forman el balón y los
## dos palos (tapa lo mismo a cada lado) y adelanta según dónde esté el balón:
## lejos, de líbero a 8-12 m (más con la línea alta); en tres cuartos, a 4-8;
## en el área, a 1,5-4; y nunca fuera del ancho del arco con margen.
static func colocacion_portero(b: Vector3, arco: Vector3, linea := 1) -> Vector3:
	var hacia := signf(arco.z)
	var bb := Vector3(b.x, 0, b.z)
	var dist := bb.distance_to(arco)
	var prof: float
	if dist > 45.0:
		prof = 8.0 + 2.0 * float(linea) + clampf((dist - 45.0) * 0.05, 0.0, 1.0)
	elif dist > 25.0:
		prof = lerpf(4.5, 8.0 + float(linea), (dist - 25.0) / 20.0)
	elif dist > 11.0:
		prof = lerpf(1.6, 4.5, (dist - 11.0) / 14.0)
	else:
		prof = lerpf(0.9, 1.6, dist / 11.0)
	var p1 := Vector3(-PALO, 0, arco.z)
	var p2 := Vector3(PALO, 0, arco.z)
	var bis := ((p1 - bb).normalized() + (p2 - bb).normalized()).normalized()
	var z_obj := arco.z - hacia * prof
	var obj := Vector3(0, 0, z_obj)
	## Con el balón por delante, en la bisectriz; si está por detrás de la
	## línea del portero (casi en el córner), pegado al primer palo.
	if absf(bis.z) > 0.05 and (z_obj - bb.z) * hacia > 0.0:
		var u := (z_obj - bb.z) / bis.z
		obj.x = bb.x + bis.x * u
	else:
		obj.x = signf(bb.x) * PALO * 0.8
	obj.x = clampf(obj.x, -PALO - 0.6, PALO + 0.6)
	return obj
