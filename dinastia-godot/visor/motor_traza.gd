class_name MotorTraza
extends RefCounted
## TRAZA DE LA CONSTRUCCIÓN DEL ATAQUE (03-11-2026, ciclo 9 de la sesión líder: «mira por qué mueren los ataques antes del área»). Solo CUENTA, no decide ni usa
## números aleatorios (no cambia la huella): cada vez que un equipo pierde la posesión anota dónde estaba el balón (`propio`, `medio`, `ataque` = último tercio sin
## área, `area`) y por qué (`pase`: un pase suyo en vuelo lo corta el rival; `robo`: se lo quita en un duelo o rebote); y cuántas veces el balón entra en el área
## rival con ese equipo como último dueño (`traza_entrada_area`). Los contadores salen en `motor.diag` con prefijo `traza_` y `zz_medir_partido` los imprime (MEDIDA3).

static func _est(m: MotorJugable) -> Dictionary:
	if not m.has_meta("_traza"):
		m.set_meta("_traza", {"eq": -1, "en_area": false})
	return m.get_meta("_traza")

## Zona del balón vista desde el equipo `eq` (0 local, 1 visita): 0 = propio campo (primer tercio) … «area» = área rival.
static func zona(m: MotorJugable, eq: int) -> String:
	var local := eq == 0
	var d := m.dir_ataque(local)
	var b := m.balon.position
	var arco_z := m.LARGO * d
	if absf(b.x) < m.AREA_X and absf(b.z - arco_z) < m.AREA_Z:
		return "area"
	var progreso := (b.z * d + m.LARGO) / (2.0 * m.LARGO)
	return "propio" if progreso < 0.33 else ("medio" if progreso < 0.66 else "ataque")

## Llamar desde `_tomar` cuando el balón cambia de dueño.
static func tomar(m: MotorJugable, p: Dictionary) -> void:
	var nuevo := 0 if bool(p["es_local"]) else 1
	var e := _est(m)
	var antes := int(e["eq"])
	if antes != nuevo:
		m._contar("traza_posesiones")
		if antes != -1:
			## Causa de la pérdida (ciclo 10, afinada): `pase` = un pase suyo en vuelo lo corta el rival; `tiro` = un remate suyo en vuelo; `entrada` = entrada con éxito hace <0,2 s;
			## `suelto` = recoge un balón que ya no tenía dueño (rechace, despeje, toque largo, balón dividido); `directo` = se lo quitan con el balón aún en sus pies por otra vía.
			var tiro_suyo := not m._tiro_vivo.is_empty() and (0 if bool((m._tiro_vivo["p"] as Dictionary)["es_local"]) else 1) == antes
			var causa := ("pase_" + String(m.get_meta("_traza_pase", "otro"))) if m._pase_eq == antes else ("tiro" if tiro_suyo else ("entrada" if m.t - float(m.get_meta("_traza_ent", -9.0)) < 0.2 else (("saque_" + String(m.get_meta("_traza_saque_tipo", "otro"))) if m._t_estado < 4.0 else ("toque_largo" if m.t - float(m.get_meta("_traza_tl", -9.0)) < 0.2 else (_suelto(m, e, antes) if m.poseedor.is_empty() else "directo")))))
			m._contar("traza_perdida_%s_%s" % [zona(m, antes), causa])
			if causa.begins_with("pase_") and m.has_meta("_traza_geo"):
				cortar(m, p)
	e["eq"] = nuevo

## Llamar una vez por fotograma de juego: cuenta las entradas del balón al área rival (equipo = el último dueño).
static func paso(m: MotorJugable) -> void:
	var e := _est(m)
	## Cuándo y cómo se queda el balón sin dueño (ciclo 10): equipo que lo soltaba, instante y último gesto con el pie (`despeje`, `centro`, `filtrado`, `tiro`, «»).
	if not m.poseedor.is_empty():
		e["dueno_eq"] = 0 if bool(m.poseedor["es_local"]) else 1
		e["dueno_t"] = m.t
		e["dueno_rol"] = m._rol(m.poseedor)
	elif e.has("dueno_t") and float(e["dueno_t"]) > float(e.get("suelta_t", -9.0)):
		e["suelta_t"] = m.t
		e["suelta_eq"] = int(e["dueno_eq"])
		e["suelta_ctx"] = String(m._ctx_golpeo)
		e["suelta_rol"] = String(e.get("dueno_rol", ""))
		e["suelta_v"] = m.vel_balon.length()
	_linea(m, e)
	var eq := int(e["eq"])
	if eq == -1:
		return
	var dentro := zona(m, eq) == "area"
	if dentro and not bool(e["en_area"]):
		m._contar("traza_entrada_area")
		e["ent"] = {"eq": eq, "t": m.t, "tiros": int(m.tiros[eq])}
	e["en_area"] = dentro
	_fin_entrada(m, e, dentro)

## Subcausa de un balón suelto que recoge el rival: `despeje`/`centro`/`filtrado` si el último gesto del equipo fue ese y lo soltó hace menos de 3 s; si no, `control` (perdió el control: toque largo, duelo, rebote de entrada).
static func _suelto(m: MotorJugable, e: Dictionary, antes: int) -> String:
	if int(e.get("suelta_eq", -1)) == antes and m.t - float(e.get("suelta_t", -99.0)) < 3.0:
		var c := String(e.get("suelta_ctx", ""))
		if c in ["despeje", "centro", "filtrado", "tiro"]:   ## «tiro»: remate parado o desviado cuyo rebote recoge el rival (el remate ya estaba cerrado)
			return "suelto_" + c
	var dt := m.t - float(e.get("suelta_t", -99.0))
	var propio := int(e.get("suelta_eq", -1)) == antes
	var tiempo := "t0" if dt < 0.5 else ("t1" if dt < 2.0 else "t2")
	return "suelto_control_%s_%s%s" % ["propio" if propio else "ajeno", tiempo, ("_" + ("fuerte" if float(e.get("suelta_v", 0.0)) >= 9.0 else ("media" if float(e.get("suelta_v", 0.0)) >= 4.0 else "suave"))) if (propio and tiempo != "t0") else ""]   ## quién lo soltó, cuánto lleva suelto y, si no es inmediato, con qué velocidad salió el balón (fuerte ≥9, media ≥4, suave)

## Una reanudación de la IA (`banda`, `corner`, `falta`, `puerta`, `penal`): cuenta cuántas hay por tipo y recuerda el tipo para etiquetar la pérdida que siga.
static func saque(m: MotorJugable, tipo: String) -> void:
	m._contar("traza_saque_" + tipo)
	m.set_meta("_traza_saque_tipo", tipo)
	m.set_meta("_traza_saque_t", m.t)

## Un pase de la IA acaba de salir (ciclo 13: «el receptor que se ofrece»): lo clasifica en el instante de la patada por receptor `quieto`/`mueve` (velocidad < 1,0 m/s), línea `tapada`/`libre` (un rival a < 1,3 m del
## trayecto) y distancia `corto` (< 12 m) / `medio` (< 22 m) / `largo`; cuenta cuántos hay de cada clase y recuerda la clase para etiquetar el corte si el rival lo intercepta.
static func pase(m: MotorJugable, p: Dictionary, q: Dictionary, dist: float) -> void:
	var mueve := "mueve" if (q["vel"] as Vector3).length() >= 1.0 else "quieto"
	var linea := "tapada" if m._linea_tapada(m.pos(p), m.pos(q), bool(p["es_local"])) else "libre"
	var d := "corto" if dist < 12.0 else ("medio" if dist < 22.0 else "largo")
	var clase := "%s_%s_%s" % [mueve, linea, d]
	m._contar("traza_pase_" + clase)
	_progresion(m, p, q)
	if dist >= 22.0:
		_opcion_corta(m, p, q)
	m.set_meta("_traza_pase", clase)
	var rivales := {}
	for r: Dictionary in m.jugadores:
		if bool(r["es_local"]) != bool(p["es_local"]):
			rivales[String(r["id"])] = m.pos(r)
	m.set_meta("_traza_geo", {"t": m.t, "a": m.pos(p), "b": m.pos(q), "rivales": rivales})

## Un pase suyo lo corta el rival `p` (ciclo 14: mecánica de la intercepción): a qué distancia PERPENDICULAR de la línea del pase estaba `p` cuando salió el balón (`en_linea` < 1,2 m; `cerca` 1,2-3 m;
## `corriendo` > 3 m: tuvo que correr a la línea) y cuánto tardó en cortarlo (`rapido` < 0,3 s: apenas hubo tiempo de reaccionar; `normal` 0,3-1,0 s; `lento` > 1,0 s).
static func cortar(m: MotorJugable, p: Dictionary) -> void:
	var g: Dictionary = m.get_meta("_traza_geo")
	var pos0: Vector3 = (g["rivales"] as Dictionary).get(String(p["id"]), m.pos(p))
	var a: Vector3 = g["a"]
	var b: Vector3 = g["b"]
	var cerca_linea := Geometry3D.get_closest_point_to_segment(Vector3(pos0.x, 0.0, pos0.z), Vector3(a.x, 0.0, a.z), Vector3(b.x, 0.0, b.z))
	var perp := cerca_linea.distance_to(Vector3(pos0.x, 0.0, pos0.z))
	var dt := m.t - float(g["t"])
	m._contar("traza_corte_perp_" + ("en_linea" if perp < 1.2 else ("cerca" if perp < 3.0 else "corriendo")))
	m._contar("traza_corte_t_" + ("rapido" if dt < 0.3 else ("normal" if dt < 1.0 else "lento")))

## Forma de la línea de 4 al defender (ciclo 17, 3-11): una vez por segundo, cuando el RIVAL tiene el balón, anota (en decímetros, sin tocar el motor) la separación
## media entre defensas vecinos en el ancho, el ancho total de la línea y su desfase en profundidad. Referencia (FIFA Training Centre y manuales): 6-8 m entre defensas, línea plana.
static func _linea(m: MotorJugable, e: Dictionary) -> void:
	if m.poseedor.is_empty() or m.t - float(e.get("linea_t", -9.0)) < 1.0:
		return
	e["linea_t"] = m.t
	_bloque(m)
	for local: bool in [true, false]:
		if bool(m.poseedor["es_local"]) == local:
			continue
		var xs: Array = []
		var zs: Array = []
		for q: Dictionary in m.jugadores:
			if bool(q["es_local"]) == local and m._rol(q) in ["DFC", "LD", "LI"]:
				xs.append(m.pos(q).x)
				zs.append(m.pos(q).z)
		if xs.size() != 4:
			continue
		## Sin el defensa más cercano al balón (el que presiona sale de la línea): desfase de los otros tres.
		var ord: Array = []
		for q: Dictionary in m.jugadores:
			if bool(q["es_local"]) == local and m._rol(q) in ["DFC", "LD", "LI"]:
				ord.append([m.pos(q).distance_to(m.balon.position), m.pos(q).z])
		ord.sort_custom(func(u: Array, v: Array) -> bool: return u[0] < v[0])
		var z3 := [float(ord[1][1]), float(ord[2][1]), float(ord[3][1])]
		m.diag["traza_linea_prof3_dm"] = int(m.diag.get("traza_linea_prof3_dm", 0)) + int(10.0 * (maxf(z3[0], maxf(z3[1], z3[2])) - minf(z3[0], minf(z3[1], z3[2]))))
		xs.sort()
		zs.sort()
		m.diag["traza_linea_n"] = int(m.diag.get("traza_linea_n", 0)) + 1
		m.diag["traza_linea_ancho_dm"] = int(m.diag.get("traza_linea_ancho_dm", 0)) + int(10.0 * (float(xs[3]) - float(xs[0])))
		m.diag["traza_linea_prof_dm"] = int(m.diag.get("traza_linea_prof_dm", 0)) + int(10.0 * (float(zs[3]) - float(zs[0])))
		m.diag["traza_linea_centrales_dm"] = int(m.diag.get("traza_linea_centrales_dm", 0)) + int(10.0 * (float(xs[2]) - float(xs[1])))

## Ciclo 19: por qué se elige un pase LARGO. Para cada largo busca la mejor opción CORTA (compañero a 4-15 m con un rival a >= 3 m) y compara las notas: `sin_corta` (no había), `cercana` (la corta
## quedó a < 0,7 de nota del largo), `media` (< 2,0) o `lejana`. Si abundan `cercana`/`media`, el problema es el peso de la nota (avance frente a riesgo), no la falta de apoyos.
static func _opcion_corta(m: MotorJugable, p: Dictionary, elegido: Dictionary) -> void:
	var n_largo := MotorPaseMejora.nota_base(m, p, elegido)
	var mejor := -999.0
	var max_libre := 0.0
	var hay := false
	for q: Dictionary in m.jugadores:
		if q == p or q == elegido or bool(q["es_local"]) != bool(p["es_local"]) or bool(q["por"]):
			continue
		var d := m.pos(q).distance_to(m.pos(p))
		if d < 4.0 or d > 15.0:
			continue
		var r := MotorPaseMejora.nota_base(m, p, q)
		hay = true
		max_libre = maxf(max_libre, minf(float(r[1]), 3.0))
		if float(r[1]) >= 3.0:
			mejor = maxf(mejor, float(r[0]))
	if mejor < -900.0:
		m._contar("traza_largo_sin_corta")
		m._contar("traza_largo_sc_" + ("nadie" if not hay else ("lt1_5" if max_libre < 1.5 else ("lt2_2" if max_libre < 2.2 else "lt3"))))
		return
	var gap := float(n_largo[0]) - mejor
	m._contar("traza_largo_corta_" + ("mejor" if gap < 0.0 else ("cercana" if gap < 0.7 else ("media" if gap < 2.0 else "lejana"))))

## Ciclo 21 (compacidad): una vez por segundo, por equipo y según tenga o no el balón, largo del bloque (z del jugador de campo más adelantado menos el más retrasado, SIN portero), ancho (x máxima menos mínima) y,
## con balón, distancia del poseedor a su compañero más cercano. Todo en decímetros acumulados + número de muestras: `traza_blq_{con|sin}_{n,largo_dm,ancho_dm}`, `traza_blq_cerca_dm`.
static func _bloque(m: MotorJugable) -> void:
	for local: bool in [true, false]:
		var con := not m.poseedor.is_empty() and bool(m.poseedor["es_local"]) == local
		var zmin := 999.0
		var zmax := -999.0
		var xmin := 999.0
		var xmax := -999.0
		var cerca := 999.0
		for q: Dictionary in m.jugadores:
			if bool(q["es_local"]) != local or bool(q["por"]):
				continue
			var pq := m.pos(q)
			zmin = minf(zmin, pq.z)
			zmax = maxf(zmax, pq.z)
			xmin = minf(xmin, pq.x)
			xmax = maxf(xmax, pq.x)
			if con and q != m.poseedor:
				cerca = minf(cerca, pq.distance_to(m.pos(m.poseedor)))
		var k := "traza_blq_" + ("con" if con else "sin")
		m.diag[k + "_n"] = int(m.diag.get(k + "_n", 0)) + 1
		m.diag[k + "_largo_dm"] = int(m.diag.get(k + "_largo_dm", 0)) + int(10.0 * (zmax - zmin))
		m.diag[k + "_ancho_dm"] = int(m.diag.get(k + "_ancho_dm", 0)) + int(10.0 * (xmax - xmin))
		if con and cerca < 900.0:
			m.diag["traza_blq_cerca_dm"] = int(m.diag.get("traza_blq_cerca_dm", 0)) + int(10.0 * cerca)

## Ciclo 23 (llegadas al área): al disparar, cuántos compañeros (sin contar al tirador ni al portero) hay a < 18 m del centro del arco rival (`traza_area_n_{0,1,2,3mas}`) y, por separado, cuántos de esos tiros son
## desde dentro (`lejos` < 16,5 m). Al marcar, de dónde salió el gol (`traza_gol_zona_{dentro,frontal,lejos}`) y si tuvo asistencia de un compañero (`traza_gol_con_asist` / `_sin_asist`).
static func tiro(m: MotorJugable, p: Dictionary, lejos: float) -> void:
	var arco := m._arco_rival(p)
	var n := 0
	for q: Dictionary in m.jugadores:
		if q != p and bool(q["es_local"]) == bool(p["es_local"]) and not bool(q["por"]) and m.pos(q).distance_to(arco) < 18.0:
			n += 1
	m._contar("traza_area_n_" + (str(n) if n < 3 else "3mas"))
	m.set_meta("_traza_tiro_zona", "dentro" if lejos < 16.5 else ("frontal" if lejos < 25.0 else "lejos"))

static func gol(m: MotorJugable, de_local: bool) -> void:
	m._contar("traza_gol_zona_" + String(m.get_meta("_traza_tiro_zona", "sin")))
	m._contar("traza_gol_origen_" + (String(m.get_meta("_traza_saque_tipo", "otro")) if m.t - float(m.get_meta("_traza_saque_t", -99.0)) < 8.0 else "juego"))
	var a: Dictionary = m.penultimo_toque
	m._contar("traza_gol_con_asist" if (not a.is_empty() and bool(a["es_local"]) == de_local and a != m.ultimo_toque) else "traza_gol_sin_asist")

## Ciclo 24: cómo TERMINA cada entrada del balón en el área rival: `traza_ent_fin_{tiro, pierde (el rival toma el balón), sale_con_balon (el balón sale del área en pies del equipo: pase atrás o regate fuera), sale_suelto (balón suelto o del rival), tiempo (> 12 s)}`.
static func _fin_entrada(m: MotorJugable, e: Dictionary, dentro: bool) -> void:
	if not e.has("ent"):
		return
	var ent: Dictionary = e["ent"]
	var eq := int(ent["eq"])
	var fin := ""
	if int(m.tiros[eq]) > int(ent["tiros"]):
		fin = "tiro"
	elif not m.poseedor.is_empty() and (0 if bool(m.poseedor["es_local"]) else 1) != eq:
		fin = "pierde"
	elif not dentro:
		fin = "sale_con_balon" if (not m.poseedor.is_empty() and (0 if bool(m.poseedor["es_local"]) else 1) == eq) else "sale_suelto"
	elif m.t - float(ent["t"]) > 12.0:
		fin = "tiempo"
	if fin != "":
		m._contar("traza_ent_fin_" + fin)
		e.erase("ent")

## Zona de un PUNTO (no del balón) vista desde `eq`: `propio`/`medio`/`ataque` (último tercio sin área)/`area` (área rival).
static func zona_punto(m: MotorJugable, eq: int, pt: Vector3) -> String:
	var d := m.dir_ataque(eq == 0)
	if absf(pt.x) < m.AREA_X and absf(pt.z - m.LARGO * d) < m.AREA_Z:
		return "area"
	var progreso := (pt.z * d + m.LARGO) / (2.0 * m.LARGO)
	return "propio" if progreso < 0.33 else ("medio" if progreso < 0.66 else "ataque")

## Ciclo 29 (plan «construir hasta el área», C1): de cada pase de la IA, zona de origen → zona del receptor (`traza_prog_{origen}_{destino}`), y cuántos son progresivos (el balón gana ≥ 10 m hacia el arco rival).
static func _progresion(m: MotorJugable, p: Dictionary, q: Dictionary) -> void:
	var eq := 0 if bool(p["es_local"]) else 1
	m._contar("traza_prog_%s_%s" % [zona_punto(m, eq, m.pos(p)), zona_punto(m, eq, m.pos(q))])
	if (m.pos(q).z - m.pos(p).z) * m.dir_ataque(bool(p["es_local"])) >= 10.0:
		m._contar("traza_prog_progresivo")

## Ciclo 32 (C3, centros): al salir un centro de la IA cuenta cuántos compañeros (sin portero ni centrador) hay a < 18 m del arco (`traza_centro_n_{0,1,2,3mas}`) y cuántos centros hay (`traza_centro`). Referencia: ≈3 atacantes en el área al centrar.
static func centro(m: MotorJugable, p: Dictionary) -> void:
	var arco := m._arco_rival(p)
	var n := 0
	for q: Dictionary in m.jugadores:
		if q != p and bool(q["es_local"]) == bool(p["es_local"]) and not bool(q["por"]) and m.pos(q).distance_to(arco) < 18.0:
			n += 1
	m._contar("traza_centro")
	m.set_meta("_t_centro", m.t)   ## (12-11) C4 lo lee: tras un centro, el rematador va a donde baja el balón (`MejorasC4.punto_aereo`)
	m._contar("traza_centro_n_" + (str(n) if n < 3 else "3mas"))

