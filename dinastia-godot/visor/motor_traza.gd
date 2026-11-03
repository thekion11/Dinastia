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
			var causa := "pase" if m._pase_eq == antes else "robo"
			m._contar("traza_perdida_%s_%s" % [zona(m, antes), causa])
	e["eq"] = nuevo

## Llamar una vez por fotograma de juego: cuenta las entradas del balón al área rival (equipo = el último dueño).
static func paso(m: MotorJugable) -> void:
	var e := _est(m)
	var eq := int(e["eq"])
	if eq == -1:
		return
	var dentro := zona(m, eq) == "area"
	if dentro and not bool(e["en_area"]):
		m._contar("traza_entrada_area")
	e["en_area"] = dentro
