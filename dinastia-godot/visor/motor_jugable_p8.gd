extends "res://visor/motor_jugable_p7.gd"
## [Capa 8/12 de `motor_jugable.gd`] _forma, _zona_de_llegada, _ia_ataque_sin_balon, _gatillo_presion, _linea_defensiva, _ia_defensa … (+7)

## La forma del equipo: la posición de la formación, movida con el balón.
func _forma(p: Dictionary, en_posesion: bool) -> Vector3:
	var base: Vector3 = p["base_pos"]
	var b := balon.position
	var d := dir_ataque(bool(p["es_local"]))
	## La pizarra (con todo a 1, lo de siempre): la línea adelanta o retrasa el
	## bloque, la mentalidad lo empuja y la amplitud abre a los de banda.
	var loc := bool(p["es_local"])
	var lin := float(_tac(loc, "linea") - 1)
	var men := float(_tac(loc, "mentalidad") - 1)
	var amp := float(_tac(loc, "amplitud") - 1)
	var z := base.z * 0.55 + b.z * 0.45 + (d * (9.0 + men * 3.0) if en_posesion else -d * 3.0)
	z += d * (lin * 3.5 + men * 2.0)
	var x := base.x * (0.8 + (amp * 0.12 if en_posesion else 0.0)) + b.x * 0.22
	## Nadie se mete detrás de su propio arco ni más allá del rival.
	z = clampf(z, -LARGO + 4.0, LARGO - 4.0)
	return Vector3(clampf(x, -ANCHO + 2.0, ANCHO - 2.0), 0, z)

func _zona_de_llegada(p: Dictionary) -> Vector3:
	if not LLEGADA or poseedor.is_empty() or poseedor == p or bool(poseedor["es_local"]) != bool(p["es_local"]):
		return Vector3.INF
	var arco := _arco_rival(p)
	var pb := pos(poseedor)
	if pb.distance_to(arco) > 32.0:
		return Vector3.INF
	## Los dos apoyos cercanos siguen ofreciéndose al portador.
	if pos(p).distance_to(pb) < 9.0:
		return Vector3.INF
	var dz := dir_ataque(bool(p["es_local"]))
	var lado := signf(pb.x) if absf(pb.x) > 3.0 else 1.0
	var rol := _rol(p)
	var px := pos(p).x
	match rol:
		"DC":
			## Con el balón en la banda, al primer palo; si no, al punto de penal.
			if absf(pb.x) > 12.0:
				return Vector3(lado * 3.5, 0, arco.z - dz * 6.5)
			return Vector3(-lado * 1.5, 0, arco.z - dz * 10.5)
		"ED", "EI":
			## El extremo del lado contrario cierra al segundo palo; el del lado
			## del balón se queda abierto (apoyo o centro).
			if signf(px) != lado:
				return Vector3(-lado * 5.0, 0, arco.z - dz * 7.5)
			return Vector3.INF
		"MC":
			## Solo el más adelantado de los medios llega a la frontal.
			var mas_adelantado := true
			for q: Dictionary in jugadores:
				if q != p and bool(q["es_local"]) == bool(p["es_local"]) and _rol(q) == "MC" \
						and (pos(q).z - pos(p).z) * dz > 0.0:
					mas_adelantado = false
					break
			if mas_adelantado:
				return Vector3(-lado * 4.0, 0, arco.z - dz * 17.0)
	return Vector3.INF

func _ia_ataque_sin_balon(p: Dictionary) -> Vector3:
	p["correr"] = false
	## Si la jugada prehecha le da un destino a su puesto, va ahí.
	if not _jugada.is_empty() and bool(_jugada["local"]) == bool(p["es_local"]):
		var dest: Dictionary = _jugada.get("destinos", {})
		var rol := _rol(p)
		if dest.has(rol):
			p["correr"] = true
			## El desmarque de la jugada respeta la línea del fuera de juego
			## mientras el balón no sale (sin esto, 10-13 por partido).
			var dz := dir_ataque(bool(p["es_local"]))
			var linea := _ultima_linea(not bool(p["es_local"]))
			var dd: Vector3 = dest[rol]
			if (dd.z - linea) * dz > -0.5 and (dd.z - balon.position.z) * dz > 0.0:
				dd.z = linea - dz * 0.6
			return dd
	var obj := _forma(p, true)
	## Apoyo: los dos más cercanos al portador se ofrecen en ángulo.
	if not poseedor.is_empty():
		var d := pos(p).distance_to(pos(poseedor))
		if d < 14.0:
			var lado := signf(pos(p).x - pos(poseedor).x)
			if lado == 0.0:
				lado = 1.0
			obj = pos(poseedor) + Vector3(lado * 9.0, 0, dir_ataque(bool(p["es_local"])) * 5.0)
	## LLEGADA AL ÁREA (20-10-2026, más chispa): con el balón de un compañero
	## en el último tercio, el ataque ocupa el área como en el fútbol de verdad
	## (antes casi nadie pisaba el área y no había a quién centrar).
	var zona := _zona_de_llegada(p)
	if zona != Vector3.INF:
		obj = zona
		p["correr"] = true
	## Los delanteros atacan el espacio a la espalda de la defensa.
	var linea := _ultima_linea(not bool(p["es_local"]))
	var dz := dir_ataque(bool(p["es_local"]))
	if _rol(p) in ["DC", "ED", "EI", "SD"]:
		obj.z = clampf(linea - dz * 0.6, -LARGO + 6.0, LARGO - 6.0) if (linea - pos(p).z) * dz > -8.0 else obj.z
	## Y NADIE se queda en fuera de juego esperando (MEGAPLAN fase 3): el
	## central que subió al córner o el lateral que se proyectó vuelven a
	## estar habilitados mientras el balón no pase la línea.
	var tope := maxf(linea * dz, balon.position.z * dz) - 0.6
	if obj.z * dz > tope:
		obj.z = tope * dz
	return obj

## ¿Toca apretar al que lleva el balón? Los gatillos clásicos de la presión:
##   · acaba de recibir y aún no se ha acomodado (medio segundo);
##   · está pegado a la banda (la línea es un defensor más);
##   · está de espaldas al juego, mirando a su propio arco;
##   · lo tiene un defensa o el portero cerca de su área (salida de balón).
func _gatillo_presion(dueno: Dictionary) -> bool:
	var q := pos(dueno)
	if t - float(dueno.get("tomo_en", -9.0)) < 0.6:
		return true
	if absf(q.x) > 28.0:
		return true
	var propio := _arco_propio(dueno)
	var mira := Vector3(sin(float(dueno.get("mirar", 0.0))), 0, cos(float(dueno.get("mirar", 0.0))))
	if mira.dot((propio - q).normalized()) > 0.6:
		return true
	return q.distance_to(propio) < 24.0 and _rol(dueno) in ["DFC", "LD", "LI", "POR"]

func _linea_defensiva(local: bool) -> float:
	var eq := 0 if local else 1
	if _linea_def_t[eq] == t:
		return _linea_def[eq]
	var d := dir_ataque(local)
	var b := balon.position
	## Base: la forma de los defensores (z media), como hasta ahora.
	var suma := 0.0
	var n := 0
	for q: Dictionary in jugadores:
		if bool(q["es_local"]) == local and _rol(q) in ["DFC", "LD", "LI"]:
			suma += _forma(q, false).z
			n += 1
	var z := suma / float(n) if n > 0 else -d * 30.0
	var trampa := int((tacticas[eq] as Dictionary).get("trampa", 0)) == 1
	## El portador rival: ¿libre y de cara, o apretado?
	if not poseedor.is_empty() and bool(poseedor["es_local"]) != local:
		var libre := _presion(poseedor) > 4.0
		if libre:
			z -= d * 4.0
		elif trampa:
			z += d * 3.0
	## Balón que viaja hacia el campo del rival (pase atrás o despeje): se sube.
	if poseedor.is_empty() and vel_balon.z * d > 3.0:
		z += d * (5.0 if trampa else 2.5)
	## Nunca por delante del balón (la línea no deja el balón a su espalda)…
	var lim_balon := b.z - d * 1.5
	if (z - lim_balon) * d > 0.0:
		z = lim_balon
	## …ni dentro del área chica.
	var fondo := -d * (LARGO - 6.0)
	if (z - fondo) * d < 0.0:
		z = fondo
	## Movimiento suave: sube despacio, recula rápido (como una defensa de verdad).
	if _linea_def_t[eq] >= 0.0 and _linea_def[eq] != INF:
		var dt_ := clampf(t - float(_linea_def_t[eq]), 0.0, 0.5)
		var sube := (z - float(_linea_def[eq])) * d > 0.0
		var vel := (6.0 if trampa else 4.0) if sube else 7.5
		z = move_toward(float(_linea_def[eq]), z, vel * dt_)
	_linea_def[eq] = z
	_linea_def_t[eq] = t
	return z

func _ia_defensa(p: Dictionary) -> Vector3:
	p["correr"] = false
	var b := balon.position
	var arco := _arco_propio(p)
	var cercanos: Array = []
	for q: Dictionary in jugadores:
		if bool(q["es_local"]) == bool(p["es_local"]) and not bool(q["por"]) and not (q == usuario and not autopiloto):
			cercanos.append([pos(q).distance_to(b), q])
	cercanos.sort_custom(func(a: Array, c: Array) -> bool: return float(a[0]) < float(c[0]))
	## El más cercano presiona; el segundo cubre entre el balón y el arco.
	## Presión baja: lejos de su área se temporiza; presión alta: van dos.
	var pres := _tac(bool(p["es_local"]), "presion")
	## GATILLOS DE PRESIÓN (21-10-2026, M-124): hay momentos en que hasta un
	## equipo que espera sale a morder (`_gatillo_presion`).
	var gatillo := false
	if not poseedor.is_empty() and bool(poseedor["es_local"]) != bool(p["es_local"]):
		gatillo = _gatillo_presion(poseedor)
	if not cercanos.is_empty() and cercanos[0][1] == p:
		if pres == 0 and not gatillo and b.distance_to(arco) > 42.0 and pos(p).distance_to(b) > 9.0:
			return b + (arco - b).normalized() * 5.0
		p["correr"] = true
		return b + (arco - b).normalized() * 0.8
	if cercanos.size() > 1 and cercanos[1][1] == p:
		if pres == 2 or (pres == 1 and gatillo):
			p["correr"] = true
			return b + (arco - b).normalized() * 2.5
		return b + (arco - b).normalized() * 7.0
	## Los demás: zona, marcando al rival más cercano.
	var obj := _forma(p, false)
	var rival: Dictionary = {}
	var md := 11.0
	for q: Dictionary in jugadores:
		if bool(q["es_local"]) != bool(p["es_local"]) and not bool(q["por"]):
			var d := pos(q).distance_to(obj)
			if d < md:
				md = d
				rival = q
	if not rival.is_empty():
		## Marca a distancia de zona: entre el rival y el arco, a 2,4 m.
		obj = pos(rival) + (arco - pos(rival)).normalized() * 2.4
	## La defensa no persigue a cada delantero hacia su arco: se queda en la
	## línea común (M-123) y solo cierra por dentro hacia el que marca.
	if _rol(p) in ["DFC", "LD", "LI"] and not _SIN_LINEA:
		obj.z = _linea_defensiva(bool(p["es_local"]))
	return obj

# ---------------------------------------------------------------- IA

func _ia_equipos(delta: float) -> void:
	var b := balon.position
	var equipo_con_balon := -1
	if not poseedor.is_empty():
		equipo_con_balon = 0 if bool(poseedor["es_local"]) else 1
	elif not ultimo_toque.is_empty():
		equipo_con_balon = 0 if bool(ultimo_toque["es_local"]) else 1
	## Quién va a por el balón suelto: el más rápido de cada equipo en llegar.
	var persigue := [{}, {}]
	if poseedor.is_empty():
		var destino := b + Vector3(vel_balon.x, 0, vel_balon.z) * 0.35
		## Con un pase en camino, el rival solo sale a cortarlo si llega antes
		## que el receptor al punto donde se recibe (sin esto cortaba cuatro de
		## cada diez pases: el que persigue siempre iba a la línea del balón).
		var recep := _punto_de_recepcion() if not pase_a.is_empty() else Vector3.ZERO
		var d_recep := pos(pase_a).distance_to(recep) if not pase_a.is_empty() else 0.0
		for eq in 2:
			var md := 999.0
			for p: Dictionary in jugadores:
				if (0 if bool(p["es_local"]) else 1) != eq or bool(p["por"]):
					continue
				var d := pos(p).distance_to(Vector3(destino.x, 0, destino.z))
				if not pase_a.is_empty() and bool(pase_a["es_local"]) != bool(p["es_local"]) \
						and pos(p).distance_to(recep) > d_recep * 0.8:
					continue
				if d < md:
					md = d
					persigue[eq] = p
	## La jugada prehecha del equipo que ataca.
	if not poseedor.is_empty():
		_guiar_jugada(delta)
	for p: Dictionary in jugadores:
		if p == usuario and not autopiloto:
			continue
		var eq := 0 if bool(p["es_local"]) else 1
		if bool(p["por"]):
			## Si lo manejas con R3 (o lo mandaste al palo largo), manda tu orden.
			if float(p.get("mandado_hasta", 0.0)) > t:
				continue
			p["objetivo"] = _ia_portero(p)
			continue
		if p == poseedor:
			_ia_portador(p)
			continue
		if not pase_a.is_empty() and p == pase_a:
			p["objetivo"] = _punto_de_recepcion()
			p["correr"] = true
			continue
		if poseedor.is_empty() and p == persigue[eq]:
			p["objetivo"] = b + Vector3(vel_balon.x, 0, vel_balon.z) * 0.35
			p["correr"] = true
			continue
		if equipo_con_balon == eq:
			p["objetivo"] = _ia_ataque_sin_balon(p)
		else:
			p["objetivo"] = _ia_defensa(p)

## El stick (o las teclas) en el plano del campo: según la cámara o el campo.
func _a_mundo(v: Vector2, d: float) -> Vector3:
	var mundo := Vector3(-v.x * d, 0, -v.y * d)
	if camara != null and is_instance_valid(camara) and Mando.ayuda("direccion") == "camara":
		var f := -camara.global_basis.z
		f.y = 0.0
		var r := camara.global_basis.x
		r.y = 0.0
		if f.length() > 0.01 and r.length() > 0.01:
			mundo = r.normalized() * v.x + f.normalized() * (-v.y)
	return mundo

## TÁCTICAS RÁPIDAS (cruceta): mentalidad arriba/abajo, presión de equipo 45 s
## y laterales al ataque. Solo con todo el equipo en tus manos.
func _tacticas_rapidas() -> void:
	if control_equipo < 0:
		return
	var eq := control_equipo
	var tc: Dictionary = tacticas[eq]
	var cambio := ""
	if _presion_equipo_hasta > 0.0 and t > _presion_equipo_hasta:
		_presion_equipo_hasta = 0.0
		tc["presion"] = int(_tac_base[eq].get("presion", 1))
		cambio = "presion"
		aviso.emit("Presión de equipo: se acaba")
	if Input.is_action_just_pressed("jugar_tac_arriba"):
		tc["mentalidad"] = mini(int(tc.get("mentalidad", 1)) + 1, 2)
		cambio = "mentalidad"
		aviso.emit("⚔ Mentalidad: %s" % ["defensiva", "equilibrada", "ofensiva"][int(tc["mentalidad"])])
	elif Input.is_action_just_pressed("jugar_tac_abajo"):
		tc["mentalidad"] = maxi(int(tc.get("mentalidad", 1)) - 1, 0)
		cambio = "mentalidad"
		aviso.emit("🛡 Mentalidad: %s" % ["defensiva", "equilibrada", "ofensiva"][int(tc["mentalidad"])])
	elif Input.is_action_just_pressed("jugar_tac_izquierda"):
		_tac_base[eq] = tc.duplicate()
		tc["presion"] = 2
		cambio = "presion"
		_presion_equipo_hasta = t + 45.0
		aviso.emit("🔥 ¡Presión de equipo!")
	elif Input.is_action_just_pressed("jugar_tac_derecha"):
		tc["amplitud"] = 2 if int(tc.get("amplitud", 1)) < 2 else 1
		cambio = "amplitud"
		aviso.emit("↗ Laterales al ataque" if int(tc["amplitud"]) == 2 else "Laterales en su sitio")
	tacticas[eq] = tc
	if cambio != "":
		tactica_rapida.emit(eq, cambio, int(tc[cambio]))

## La pared: el que la dio corre al espacio mientras dure.
func _seguir_pared() -> void:
	if _pared.is_empty():
		return
	if t > float(_pared["hasta"]):
		_pared = {}
		return
	var de: Dictionary = _pared["de"]
	if de == usuario or de == poseedor:
		return
	var dd := dir_ataque(bool(de["es_local"]))
	de["objetivo"] = pos(de) + Vector3(0, 0, dd * 8.0)
	de["correr"] = true

func _mi_portero(p: Dictionary) -> Dictionary:
	for q: Dictionary in jugadores:
		if bool(q["por"]) and bool(q["es_local"]) == bool(p["es_local"]):
			return q
	return {}

## El portero que mandas con R3 o con el doble toque de Y (palo largo).
func _seguir_portero_mandado() -> void:
	if usuario.is_empty():
		return
	var gk := _mi_portero(usuario)
	if gk.is_empty() or gk == usuario or gk == poseedor:
		return
	if t < _palo_largo_hasta:
		var arco := _arco_propio(gk)
		var largo := -signf(balon.position.x + 0.01)
		gk["objetivo"] = Vector3(largo * PALO * 0.55, 0, arco.z - signf(arco.z) * 0.8)

## `para_cambio`: el cambio manual con el stick derecho (vale cualquiera, cerca o lejos).
func _companero_en_direccion(p: Dictionary, dir: Vector3, para_cambio := false) -> Dictionary:
	var mejor: Dictionary = {}
	var mejor_nota := -99.0
	var yo := pos(p)
	for q: Dictionary in jugadores:
		if q == p or bool(q["es_local"]) != bool(p["es_local"]) or bool(q["por"]):
			continue
		var v := pos(q) - yo
		var dist := v.length()
		if (dist < 3.0 and not para_cambio) or dist > (70.0 if para_cambio else 45.0):
			continue
		var alineado := v.normalized().dot(dir.normalized())
		var nota := alineado * 3.0 - dist * 0.03
		## PASE ASISTIDO (20-10-2026, al jugarlo Claude: 4 de 26 pases llegaban):
		## entre los que están hacia donde apuntas, mejor el que tiene la línea
		## limpia, como hace la IA. Solo si está razonablemente en la dirección.
		if not para_cambio and alineado > 0.5 and _linea_tapada(yo, pos(q), bool(p["es_local"])):
			nota -= 1.2
		if nota > mejor_nota:
			mejor_nota = nota
			mejor = q
	return mejor
