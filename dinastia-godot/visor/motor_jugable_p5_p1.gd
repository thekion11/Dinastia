extends "res://visor/motor_jugable_p4.gd"
## (Parte 1 de 2 de `motor_jugable_p5.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `motor_jugable_p5.gd`, conserva la clase.)

## (16-11, paso a C++, orden del dueño «50 % del tiempo de CPU en C++») `_duelos`: las parejas de rivales a 1,3 m o menos las da `duelos_parejas` de una
## vez (gemela `_parejas_gd`). Equivale al doble bucle de antes porque dentro de él nadie cambia de sitio, de equipo ni de puesto (los empujones solo apuntan
## la fuerza y, si se pita algo, el bucle se corta); lo que sí cambia (contacto, gestos) se mira pareja a pareja en `_duelos_parejas`, en el mismo orden:
## «libre» de «a» al llegar a ella, «libre» de «c», distancia y duelo; tras un duelo, se salta al siguiente «a». Igualdad de las listas: `probar_nativo`.
static var duelos_gd := false
static var comparar_duelos := false
static var duelos_comparados := 0
static var duelos_distintos := 0

# ---------------------------------------------------------------- movimiento

## (17-11) Las velocidades de cada ciclo (antes `CICLO_ANIM` aquí) y su margen de escala viven en `CicloCarrera.CICLO` (y en `CICLOS` de nativo/src/pasos_nativo.cpp).
## [Capa 5/12 de `motor_jugable.gd`] _duelo_agarron, _duelos, _mover_jugadores, _actualizar_balon_visual, _rol, _pitar_offside … (+3)

## AGARRÓN: el defensor llega por detrás (o pegado al costado de atrás) del
## que lleva el balón o va a recibirlo, a menos de 1 m. Una tirada por
## encuentro según su agresividad; si agarra, forcejean.
func _duelo_agarron(a: Dictionary, c: Dictionary, d: float) -> bool:
	if d > 1.0:
		return false
	var obj: Dictionary = {}
	var ag: Dictionary = {}
	if poseedor == a or pase_a == a:
		obj = a
		ag = c
	elif poseedor == c or pase_a == c:
		obj = c
		ag = a
	else:
		return false
	if ag == usuario and not autopiloto:
		return false
	var vo := _plano(obj["vel"])
	var so := vo.length()
	if so < 2.0:
		return false
	var rel := _plano(pos(ag) - pos(obj))
	if rel.dot(vo / so) > -0.15:
		return false
	obj["contacto_hasta"] = t + 1.6
	ag["contacto_hasta"] = t + 1.6
	var agr := float(ag["agresividad"])
	if _rng.randf() >= 0.12 + agr * 0.5:
		return false
	duelos["agarron"] += 1
	_anim(ag, "duelo_agarron", true, 0.8)
	_anim(obj, "duelo_forcejeo", true, 0.7)
	var no := _fuerza(obj) * 0.45 + float(obj["equilibrio"]) * 0.3 + _rng.randf_range(-0.25, 0.25)
	var ng := _fuerza(ag) * 0.55 + agr * 0.15 + _rng.randf_range(-0.25, 0.25)
	if no >= ng:
		_ganador(obj, ag)
	else:
		_ganador(ag, obj)
	var frena := clampf(0.6 + (no - ng) * 0.9, 0.35, 0.95)
	_empujar(obj, -rel, 0.0, frena, 0.7)
	_empujar(ag, rel, 0.0, 0.8, 0.7)
	ag["enfriar"] = maxf(float(ag["enfriar"]), 0.5)
	## Cuanto más lo retiene, más fácil que pite.
	if _rng.randf() < (0.06 + agr * 0.16 + (1.0 - frena) * 0.35) * _escala_falta():
		if _rng.randf() < 0.35:
			_caer(obj)
		_falta(ag, obj, 0.08 + agr * 0.2, "agarron", "agarron")
		return true
	## Sin falta, si lo frena del todo le roba la cartera.
	if poseedor == obj and ng > no + 0.2:
		duelos["balon_perdido"] += 1
		obj["enfriar"] = maxf(float(obj["enfriar"]), 0.6)
		poseedor = {}
		_jugada = {}
		ultimo_toque = obj
		vel_balon = vo.normalized() * 2.5
		ag["enfriar"] = 0.0
	return true

## Busca y resuelve los duelos del fotograma (antes de `_disputas`, para que
## el balón dividido se decida antes de que «el más cercano» lo controle).
func _duelos() -> void:
	if not duelos_activos or estado != "juego" or balon == null:
		return
	_duelo_dividido()
	if estado != "juego":
		return
	var nat := Nativo.obj()
	var pr := PackedInt32Array([-1])
	if nat != null and not duelos_gd and nat.has_method("duelos_parejas"):
		pr = nat.duelos_parejas(jugadores)
	if pr.size() == 1:
		pr = _parejas_gd()
	if comparar_duelos:
		duelos_comparados += 1
		if nat != null and var_to_bytes(nat.duelos_parejas(jugadores)) != var_to_bytes(_parejas_gd()):
			duelos_distintos += 1
	_duelos_parejas(pr)

func _duelos_parejas(pr: PackedInt32Array) -> void:
	var ia := -1
	var a_libre := false
	var cortado := -1
	for k in range(0, pr.size(), 2):
		var i := pr[k]
		if i == cortado:
			continue
		var a: Dictionary = jugadores[i]
		if i != ia:
			ia = i
			a_libre = _libre_para_duelo(a)
		if not a_libre:
			continue
		var c: Dictionary = jugadores[pr[k + 1]]
		if not _libre_para_duelo(c):
			continue
		var rel := _plano(pos(c) - pos(a))
		var d := rel.length()
		if d > 1.3:
			continue
		if _duelo_hombro(a, c, rel, d) or _duelo_agarron(a, c, d):
			if estado != "juego":
				return
			cortado = i

## Gemela GDScript de `duelos_parejas`: las parejas (i < j, rivales, ningún portero) a 1,3 m o menos, en el orden del doble bucle de siempre.
func _parejas_gd() -> PackedInt32Array:
	var r := PackedInt32Array()
	var n := jugadores.size()
	for i in n:
		var a: Dictionary = jugadores[i]
		if bool(a["por"]):
			continue
		for j in range(i + 1, n):
			var c: Dictionary = jugadores[j]
			if bool(c["por"]) or bool(a["es_local"]) == bool(c["es_local"]):
				continue
			if _plano(pos(c) - pos(a)).length() > 1.3:
				continue
			r.append(i)
			r.append(j)
	return r

func _mover_fisica(delta: float, bpos: Vector3) -> PackedFloat64Array:
	var nat := Nativo.obj()
	if nat != null and nat.has_method("mover_jugadores_fisica"):
		var cl := _coste_aguante(true)
		var cv := _coste_aguante(false)
		return nat.mover_jugadores_fisica(jugadores, bpos, delta, t, not poseedor.is_empty(), poseedor.get("id", ""), bool(poseedor.get("es_local", false)),
			A_MAX, ANCHO, LARGO, GIRO_RAPIDO, PackedFloat64Array([cl, cv]))
	return _mover_fisica_gd(delta, bpos)

func _coste_aguante(local: bool) -> float:
	return 1.0 + 0.35 * float(_tac(local, "presion") - 1) + 0.15 * float(_tac(local, "ritmo") - 1)

func _mover_fisica_gd(delta: float, bpos: Vector3) -> PackedFloat64Array:
	var salida := PackedFloat64Array()
	salida.resize(jugadores.size() * 4)
	var idx := -1
	for p: Dictionary in jugadores:
		idx += 1
		var n: Node3D = p["node"]
		if not is_instance_valid(n) or not p.has("objetivo"):
			continue
		salida[idx * 4] = 1.0
		var np: Vector3 = n.position   ## (13-11, rendimiento) una lectura y una escritura de la posición del nodo por jugador y paso (antes 5-9 llamadas nativas)
		var obj: Vector3 = p["objetivo"] if float(p.get("levanta_hasta", 0.0)) <= t else np   ## en el suelo tras la barrida (31-10)
		obj.y = 0.0
		var dif := obj - Vector3(np.x, 0, np.z)
		var dist := dif.length()
		var rit := float(p["attr"]["rit"])
		## La velocidad pesa más (13-10-2026): de ~6,7 m/s a ~8,3 m/s según el ritmo.
		var tope := (4.4 + rit * 4.2) * (1.0 if bool(p.get("correr", false)) else 0.62) * (0.7 + 0.3 * float(p["aguante"]))
		if poseedor == p:
			tope *= 0.88
		## Regate técnico, proteger o bregar: más despacio (lo pone el control).
		tope *= float(p.get("freno", 1.0))
		## Tras un choque o con un rival agarrándolo, va más despacio un rato.
		if float(p.get("freno_duelo_hasta", 0.0)) > t:
			tope *= float(p.get("freno_duelo", 1.0))
		var deseada := Vector3.ZERO
		if dist > 0.25:
			deseada = dif / dist * minf(tope, dist * 2.5)
		var vel: Vector3 = p["vel"]
		## INERCIA DE VERDAD (14-10-2026): antes la velocidad saltaba a la
		## nueva dirección en dos décimas, como un patinador. Ahora el rumbo
		## gira con un tope que baja con la velocidad (a toda carrera se abre
		## la curva) y, si el giro es grande, primero frena; frena (11 m/s²)
		## más rápido de lo que acelera (6 m/s², 8 con buen ritmo).
		var sp0 := vel.length()
		var sp_des := deseada.length()
		if sp0 > 0.6 and sp_des > 0.1:
			var dir0 := vel / sp0
			var dir1 := deseada / sp_des
			var ang := dir0.signed_angle_to(dir1, Vector3.UP)
			var giro_rad := lerpf(9.0, 2.6, clampf(sp0 / 8.0, 0.0, 1.0))
			## RB + LT: cambios de dirección firmes (gira cerrado sin frenar tanto).
			if bool(p.get("giro_firme", false)):
				giro_rad *= 2.4
			var giro_max := giro_rad * delta
			var dir := dir0.rotated(Vector3.UP, clampf(ang, -giro_max, giro_max))
			## Giro brusco: se frena para girar (cambio de dirección real).
			var objetivo_sp := sp_des * (1.0 - 0.6 * clampf((absf(ang) - 0.5) / 2.0, 0.0, 1.0))
			var acel := (6.0 + rit * 2.0) if objetivo_sp > sp0 else 11.0
			vel = dir * move_toward(sp0, objetivo_sp, acel * delta)
		else:
			vel = vel.move_toward(deseada, (6.0 + rit * 2.0) * delta if sp_des > sp0 else 11.0 * delta)
		## TOPE DE ACELERACIÓN TOTAL (19-10-2026): frenar, girar y arrancar a la
		## vez no pasa de A_MAX m/s² (más con giro firme), lo que aguanta un
		## cuerpo en un recorte. Antes la suma llegaba a 25-30 (tirones en la
		## sonda). Con 14 el juego se quedaba sin chispa (la mitad de goles).
		var a_max := (A_MAX * 1.35 if bool(p.get("giro_firme", false)) else A_MAX) * delta
		var dv: Vector3 = vel - (p["vel"] as Vector3)
		if dv.length() > a_max:
			vel = (p["vel"] as Vector3) + dv.normalized() * a_max
		p["vel"] = vel
		np += vel * delta
		## EL EMPUJÓN DEL DUELO: un desplazamiento lateral que sube en una
		## décima y se apaga solo (sin saltos: tope de 22 m/s²).
		var emp_obj: Vector3 = p.get("empujon_obj", Vector3.ZERO)
		var emp: Vector3 = p.get("empujon", Vector3.ZERO)
		if emp_obj != Vector3.ZERO or emp != Vector3.ZERO:
			emp = emp.move_toward(emp_obj, 22.0 * delta)
			p["empujon_obj"] = emp_obj * exp(-7.0 * delta) if emp_obj.length() > 0.05 else Vector3.ZERO
			p["empujon"] = emp if emp.length() > 0.02 or emp_obj != Vector3.ZERO else Vector3.ZERO
			np += emp * delta
		np = Vector3(clampf(np.x, -ANCHO - 2.0, ANCHO + 2.0), np.y, clampf(np.z, -LARGO - 2.0, LARGO + 2.0))
		n.position = np
		var sp := vel.length()
		## RECORRER HACIA ATRÁS (13-10-2026): el defensa que se repliega cerca
		## de la jugada no da la espalda al balón; retrocede mirándolo.
		var hacia_b := bpos - np
		hacia_b.y = 0.0
		var atras := false
		var giro_antes := n.rotation.y
		var corre_recto := false
		if float(p.get("mirar_hasta", 0.0)) > t:
			## Un giro mandado (golpeo, filigrana): manda sobre todo lo demás.
			n.rotation.y = rotate_toward(n.rotation.y, float(p["mirar"]), GIRO_RAPIDO * delta)
		elif sp > 0.5 and sp < 4.2 and poseedor != p and not bool(p["por"]) and hacia_b.length() < 18.0 \
				and not poseedor.is_empty() and bool(poseedor["es_local"]) != bool(p["es_local"]) \
				and vel.normalized().dot(hacia_b.normalized()) < -0.35:
			atras = true
			n.rotation.y = rotate_toward(n.rotation.y, atan2(hacia_b.x, hacia_b.z), 7.0 * delta)
		elif (bool(p["por"]) or bool(p.get("jockey", false))) and poseedor != p and sp < 6.0 and hacia_b.length() > 0.5:
			## El portero no da la espalda al balón: se mueve de lado o atrás.
			n.rotation.y = rotate_toward(n.rotation.y, atan2(hacia_b.x, hacia_b.z), 8.0 * delta)
		elif sp > 0.4:
			n.rotation.y = rotate_toward(n.rotation.y, atan2(vel.x, vel.z), 9.0 * delta)
			corre_recto = true
		elif poseedor != p:
			var hacia := bpos - np
			n.rotation.y = rotate_toward(n.rotation.y, atan2(hacia.x, hacia.z), 4.0 * delta)
		## Al girar corriendo de frente, el cuerpo se inclina hacia dentro de la curva (31-10, §2.2e P2); de lado o atrás, no.
		if delta > 0.0:
			n.rotation.z = MovimientoNatural.inclinacion(n.rotation.z, angle_difference(giro_antes, n.rotation.y) / delta if corre_recto else 0.0, sp, delta)
			n.rotation.x = MovimientoNatural.cabeceo(n.rotation.x, (sp - float(p.get("sp_antes", sp))) / delta if corre_recto else 0.0, delta)
			p["sp_antes"] = sp
		## Aguante: el sprint cansa, andar recupera.
		if bool(p.get("correr", false)) and sp > 5.0:
			## Presionar arriba cansa: el equipo de presión alta se funde antes
			## (el precio de la pizarra ofensiva, que se nota con el cansancio real).
			var coste := 1.0 + 0.35 * float(_tac(bool(p["es_local"]), "presion") - 1) + 0.15 * float(_tac(bool(p["es_local"]), "ritmo") - 1)
			p["aguante"] = maxf(0.2, float(p["aguante"]) - delta * 0.012 * (1.4 - float(p["attr"]["fis"])) * coste)
		else:
			p["aguante"] = minf(1.0, float(p["aguante"]) + delta * 0.006)
		salida[idx * 4 + 1] = sp
		salida[idx * 4 + 2] = 1.0 if atras else 0.0
		salida[idx * 4 + 3] = hacia_b.length()
	return salida

## (15-11, paso a C++) El movimiento de los 22 corre en `mover_jugadores_fisica` (extensión nativa, misma aritmética; `igualdad` en `pruebas/probar_nativo.tscn`);
## sin ella, `_mover_fisica_gd`. Las dos devuelven [válido, velocidad, va_atrás, distancia_al_balón] por jugador para el bucle de animación de abajo.
func _mover_jugadores(delta: float) -> void:
	var bpos := balon.position   ## (13-11, rendimiento) el balón no se mueve dentro de este bucle
	var res := _mover_fisica(delta, bpos)
	for idx in jugadores.size():
		_animar_uno(idx, res)

## La animación de un jugador según su movimiento (el cuerpo del bucle de `_mover_jugadores`; `res` = [válido, velocidad, va_atrás, distancia_al_balón] por jugador).
func _animar_uno(idx: int, res: PackedFloat64Array) -> void:
	var p: Dictionary = jugadores[idx]
	if is_zero_approx(res[idx * 4]):
		return
	var n: Node3D = p["node"]
	var sp := res[idx * 4 + 1]
	var atras := res[idx * 4 + 2] > 0.5
	var hacia_b_len := res[idx * 4 + 3]
	var vel: Vector3 = p["vel"]
	## La animación según la velocidad (salvo que haya un gesto en curso).
	if float(p.get("levantar_en", 0.0)) > 0.0:
		if t < float(p["levantar_en"]):
			return   ## en el suelo: se queda en la última pose de la caída
		p["levantar_en"] = 0.0
		_anim(p, String(p.get("levantar_con", "levantarse_suelo")), true, 1.8)
	if float(p.get("gesto_hasta", 0.0)) > t:
		return
	var anim := CicloCarrera.ciclo(sp, String(p.get("anim_actual", "")))   ## (17-11) con histéresis: sin tartamudeo a 5 m/s
	## Con el balón en los pies se conduce (no se trota); el portero espera
	## en guardia; el que está fundido se nota parado.
	if poseedor == p and sp >= 0.5 and sp < 6.5:
		anim = "conducir"
	elif atras:
		anim = "trotar_atras"
	elif bool(p.get("jockey", false)) and poseedor != p and sp < 4.5:
		anim = "marcar"
	elif sp < 0.5 and bool(p["por"]) and hacia_b_len < 32.0:
		anim = "portero_listo"
	elif bool(p["por"]) and poseedor != p and sp >= 0.5 and sp < 6.0:
		var fr := Vector3(sin(n.rotation.y), 0, cos(n.rotation.y))
		var der := Vector3(-fr.z, 0, fr.x)
		var lat := vel.dot(der)
		var fon := vel.dot(fr)
		if absf(lat) >= absf(fon) * 0.8:
			anim = "portero_lateral_der" if lat > 0.0 else "portero_lateral_izq"
		elif fon < 0.0:
			anim = "trotar_atras"
	elif sp < 0.5 and cansancio_real and forma_fisica(p) < 0.6:
		anim = "cansado"
	_anim(p, anim, false)
	var ap: AnimationPlayer = p.get("anim")
	if is_instance_valid(ap):
		ap.speed_scale = CicloCarrera.escala(anim, sp)   ## (17-11) margen por ciclo: la zancada va con el cuerpo, sin patinar

func _actualizar_balon_visual(_delta: float) -> void:
	if balon == null:
		return
	var p := balon.position
	var despl := Vector2(p.x - _ultima_pos_balon.x, p.z - _ultima_pos_balon.z)
	if despl.length_squared() > 0.000001 and despl.length() < 3.0:
		var eje := Vector3(despl.y, 0.0, -despl.x).normalized()
		balon.global_rotate(eje, despl.length() / R)
	_ultima_pos_balon = p

func _rol(p: Dictionary) -> String:
	var s := String(p.get("slot_code", ""))
	match s:
		"DC", "SD", "DEL": return "DC"
		"ED", "MD": return "ED"
		"EI", "MI": return "EI"
		"MC", "MCO", "MCD": return "MC"
		"LD", "CAD": return "LD"
		"LI", "CAI": return "LI"
		"DFC": return "DFC"
	return s

## ¿El que recibe estaba adelantado en el pase? Pita y saca el rival.
func _pitar_offside(p: Dictionary) -> bool:
	if _offside.is_empty():
		return false
	var mismo := bool(p["es_local"]) == bool(_offside["local"])
	var adelantado := mismo and (_offside["ids"] as Dictionary).has(String(p.get("id", "")))
	_offside_previo = _offside
	_offside = {}
	if not adelantado:
		return false
	if OS.get_environment("DEPURAR_OFF") != "":
		Registro.depurar("OFFSIDE", "de %s(%s) tras %s de %s (por=%s z=%.1f) hace %.1fs, recibe en z=%.1f" % [String(p.get("slot_code","")), _rol(p),
			String(_offside_previo.get("anim", "")), String(_offside_previo.get("de", "")), str(_offside_previo.get("por", false)),
			float(_offside_previo.get("z", 0.0)), t - float(_offside_previo.get("t", 0.0)), pos(p).z * dir_ataque(bool(p["es_local"]))])
	fueras_de_juego[0 if bool(p["es_local"]) else 1] += 1
	if p == usuario:
		stats["fueras_de_juego"] += 1
	var nombre := String((p.get("jugador", {}) as Dictionary).get("nombre", "un atacante"))
	## Que se note la pizarra (20-10-2026): si la defensa juega con la trampa,
	## el aviso lo dice y se cuenta para el resumen.
	var defiende := 1 if bool(p["es_local"]) else 0
	if int((tacticas[defiende] as Dictionary).get("trampa", 0)) == 1:
		trampa_cazados[defiende] += 1
		aviso.emit("🚩 Fuera de juego de %s: ¡la trampa funciona!" % nombre)
	else:
		aviso.emit("🚩 Fuera de juego de %s" % nombre)
	var lugar := pos(p)
	_gesto_arbitro("arbitro_silbato", 0.0, 0.9, {"mira": lugar})
	_gesto_arbitro("senalar_falta", 0.9, 1.6, {"mira": lugar - Vector3(0, 0, dir_ataque(bool(p["es_local"])) * 10.0)})
	_empezar_saque("falta", not bool(p["es_local"]), Vector3(clampf(lugar.x, -ANCHO + 1.0, ANCHO - 1.0), R,
		clampf(lugar.z, -LARGO + 1.0, LARGO - 1.0)))
	return true

## (16-11, M6-23) Un futbolista con modelo sin clips trae `anim` nulo: comprobarlo como en el resto del motor.
func _tiene_clip(p: Dictionary, clip: String) -> bool:
	var ap: AnimationPlayer = p.get("anim")
	return is_instance_valid(ap) and ap.has_animation(clip)

func _tomar(p: Dictionary) -> void:
	if poseedor == p or MotorReglas.doble_toque(self as Object as MotorJugable, p):   ## (16-11, M6-20) doble toque del que sacó
		return
	MotorTraza.tomar(self as Object as MotorJugable, p)   ## traza de posesiones (ciclo 9, solo cuenta)
	if not _tiro_vivo.is_empty() and _tiro_vivo["p"] != p:
		## Un tiro fuerte que se topa con un defensor no se controla: se
		## desvía (muchas veces a córner), como un bloqueo de verdad.
		var tirador: Dictionary = _tiro_vivo["p"]
		_contar("tiro_bloqueado")   ## (17-11) para la sonda de goles; no toca el azar
		_cerrar_tiro("fallo")
		if bool(tirador["es_local"]) != bool(p["es_local"]) and not bool(p["por"]) and vel_balon.length() > 14.0:
			_anim(p, LeagueAnim.bloqueo(balon.position.y), true, 0.9)   ## el cuerpo que bloquea (01-11, League-Soccer)
			vel_balon = Vector3(-vel_balon.x * 0.3 + _rng.randf_range(-6, 6), _rng.randf_range(0.5, 3.0), vel_balon.z * _rng.randf_range(0.2, 0.5))
			penultimo_toque = ultimo_toque
			ultimo_toque = p
			p["enfriar"] = 0.5
			return
	if _pase_eq >= 0:
		if (0 if bool(p["es_local"]) else 1) == _pase_eq:
			pases_ok[_pase_eq] += 1
		elif OS.get_environment("DEPURAR_PASES") != "":   ## (3-11) también los cortes sin receptor (`pase_a` vacío): receptor -1 m
			Registro.depurar("PASE PERDIDO", "recibía %s a %.1f m del balón; lo cortó %s a %.1f m; balón a %.1f m/s, alto %.1f" % [String(pase_a.get("slot_code", "NINGUNO")),
				pos(pase_a).distance_to(balon.position) if not pase_a.is_empty() else -1.0, String(p.get("slot_code", "")), pos(p).distance_to(balon.position), vel_balon.length(), balon.position.y])
		_pase_eq = -1
	if _pitar_offside(p):
		return
	if not _margenes_pase.is_empty() and bool(_margenes_pase["local"]) == bool(p["es_local"]):
		var mid := String(p.get("id", ""))
		if (_margenes_pase["m"] as Dictionary).has(mid):
			_margen_recepcion = {"id": mid, "m": float(_margenes_pase["m"][mid]), "t": t,
				"linea": float(_margenes_pase.get("linea", 0.0)), "z": float((_margenes_pase.get("z", {}) as Dictionary).get(mid, 0.0))}
	_margenes_pase = {}
	## Tu pase llegó si lo controla uno de los tuyos.
	if _pase_usuario_vivo and not _pase_usuario_de.is_empty() and p != _pase_usuario_de and bool(p["es_local"]) == bool(_pase_usuario_de["es_local"]):
		stats["pases_ok"] += 1
	_pase_usuario_vivo = false
	if poseedor.is_empty() or bool(poseedor["es_local"]) != bool(p["es_local"]):
		_jugada = {}
	penultimo_toque = ultimo_toque if ultimo_toque != p else penultimo_toque
	if ultimo_toque.is_empty() or bool(ultimo_toque["es_local"]) != bool(p["es_local"]): _eq_tomo_en[0 if bool(p["es_local"]) else 1] = t   ## (10-11) el EQUIPO acaba de recuperar: ventana de la contrapresión (antes por jugador: con tantos cambios de posesión siempre estaba abierta)
	ultimo_toque = p
	## El control: con el pecho si viene alto, orientado con el pie si viene
	## fuerte y él casi parado; el portero blocando.
	var alto := balon.position.y
	var fuerte := vel_balon.length()
	p["tomo_en"] = t
	if bool(p["por"]) and _en_su_area(p, balon.position):   ## (16-11, M6-10) fuera del área no se bloca con las manos
		_anim(p, "blocaje_alto" if alto > 1.4 else ("blocaje_rasante" if fuerte > 6.0 else "recoger_balon"), true, 0.8)
	elif alto > 0.9:
		_anim(p, "control_pecho" if _tiene_clip(p, "control_pecho") else "golpe_pecho", true, 0.6)   ## (01-11: League-Soccer)
	elif fuerte > 7.0 and (p["vel"] as Vector3).length() < 2.0:
		_anim(p, "control_pie" if _tiene_clip(p, "control_pie") else "parada_pie", true, 0.6)
	if MotorControl.se_le_va(self as Object as MotorJugable, p):   ## el primer toque se escapa (U5, 01-11)
		return
	poseedor = p
	pase_a = {}
	vel_balon = Vector3.ZERO
	_decision_en = t + 0.35 + _rng.randf() * 0.4
	if p == usuario:
		stats["toques"] += 1
