class_name MejorasC4Bloqueo
extends RefCounted
## EL BLOQUEO DEL REMATE (17-11-2026, orden de Auditoría tras la sonda de goles de C4: el exceso de goles es el atacante solo dentro del área, no el
## portero). Con `C4_BLOQUEO_REMATE=1`:
##  - COLOCACIÓN: con un rival con el balón a menos de `ZONA` m del arco, el defensor de campo más cercano a él se mete en la línea del tiro, a
##    `DELANTE` m del rematador hacia el centro del arco (contador `c4_tapa_linea`);
##  - CUERPO: al salir el tiro, un rival de campo a menos de `CERCA` m del rematador y a menos de `ANCHO_CUERPO` m de la línea del tiro lo
##    bloquea con probabilidad `BLOQUEO_P`·(1 − distancia a la línea / `ANCHO_CUERPO`) (contador `tiro_bloqueado`, como el bloqueo de siempre).
## La precisión bajo presión ya la cubre `C4_PRESION_AREA` (AAA): se combina con ella, no se repite.
static var ACTIVO := OS.get_environment("C4_BLOQUEO_REMATE") == "1"
static var BLOQUEO_P := float(OS.get_environment("C4_BLOQUEO_P")) if OS.get_environment("C4_BLOQUEO_P") != "" else 0.5
const ZONA := 22.0
const DELANTE := 1.4
const CERCA := 2.5
const ANCHO_CUERPO := 0.9

## Tras la IA de los equipos: el defensor más cercano al rematador tapa la línea del tiro.
static func tapar_linea(m: Object) -> void:
	if not ACTIVO:
		return
	var pr: Dictionary = m.poseedor
	if pr.is_empty() or bool(pr["por"]):
		return
	var arco: Vector3 = m._arco_rival(pr)
	var yo: Vector3 = m.pos(pr)
	if Vector2(yo.x - arco.x, yo.z - arco.z).length() > ZONA:
		return
	var mejor: Dictionary = {}
	var md := 999.0
	for q: Dictionary in m.jugadores:
		if bool(q["es_local"]) == bool(pr["es_local"]) or bool(q["por"]) or q == m.usuario:
			continue
		var d: float = (m.pos(q) as Vector3).distance_to(yo)
		if d < md:
			md = d
			mejor = q
	if mejor.is_empty() or md > 8.0:
		return
	var hacia := Vector3(arco.x - yo.x, 0, arco.z - yo.z).normalized()
	mejor["objetivo"] = yo + hacia * DELANTE
	mejor["correr"] = true
	m._contar("c4_tapa_linea")

## Justo después de `_tirar`: ¿un cuerpo en la línea bloquea el remate?
static func bloqueo_cuerpo(m: Object, p: Dictionary, rng: RandomNumberGenerator) -> void:
	if not ACTIVO or (m._tiro_vivo as Dictionary).is_empty() or String(m._tiro_vivo.get("clase", "")) == "penal":
		return
	var yo: Vector3 = m.pos(p)
	var v: Vector3 = m.vel_balon
	var dir := Vector2(v.x, v.z)
	if dir.length() < 1.0:
		return
	dir = dir.normalized()
	var mejor: Dictionary = {}
	var mejor_lat := ANCHO_CUERPO
	for q: Dictionary in m.jugadores:
		if bool(q["es_local"]) == bool(p["es_local"]) or bool(q["por"]):
			continue
		var rel := Vector2((m.pos(q) as Vector3).x - yo.x, (m.pos(q) as Vector3).z - yo.z)
		var delante := rel.dot(dir)
		if delante <= 0.2 or rel.length() > CERCA:
			continue
		var lat := absf(rel.cross(dir))
		if lat < mejor_lat:
			mejor_lat = lat
			mejor = q
	if mejor.is_empty() or rng.randf() >= BLOQUEO_P * (1.0 - mejor_lat / ANCHO_CUERPO):
		return
	m._contar("tiro_bloqueado")
	m._cerrar_tiro("fallo")
	m._anim(mejor, LeagueAnim.bloqueo(m.balon.position.y), true, 0.9)
	m.vel_balon = Vector3(-v.x * 0.3 + rng.randf_range(-6, 6), rng.randf_range(0.5, 3.0), v.z * rng.randf_range(-0.4, 0.3))
	m.penultimo_toque = m.ultimo_toque
	m.ultimo_toque = mejor
	mejor["enfriar"] = 0.5
