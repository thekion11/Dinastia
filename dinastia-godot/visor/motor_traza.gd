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
	var eq := int(e["eq"])
	if eq == -1:
		return
	var dentro := zona(m, eq) == "area"
	if dentro and not bool(e["en_area"]):
		m._contar("traza_entrada_area")
	e["en_area"] = dentro

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

## Un pase de la IA acaba de salir (ciclo 13: «el receptor que se ofrece»): lo clasifica en el instante de la patada por receptor `quieto`/`mueve` (velocidad < 1,0 m/s), línea `tapada`/`libre` (un rival a < 1,3 m del
## trayecto) y distancia `corto` (< 12 m) / `medio` (< 22 m) / `largo`; cuenta cuántos hay de cada clase y recuerda la clase para etiquetar el corte si el rival lo intercepta.
static func pase(m: MotorJugable, p: Dictionary, q: Dictionary, dist: float) -> void:
	var mueve := "mueve" if (q["vel"] as Vector3).length() >= 1.0 else "quieto"
	var linea := "tapada" if m._linea_tapada(m.pos(p), m.pos(q), bool(p["es_local"])) else "libre"
	var d := "corto" if dist < 12.0 else ("medio" if dist < 22.0 else "largo")
	var clase := "%s_%s_%s" % [mueve, linea, d]
	m._contar("traza_pase_" + clase)
	m.set_meta("_traza_pase", clase)
