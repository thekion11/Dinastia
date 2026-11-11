class_name MejorasC4
extends RefCounted
## MEJORAS DE C4 (11-11-2026, ideas del dueño tras elegir C4: «mayores desmarques y balones largos creen mayores jugadas, afinar las
## jugadas de balón parado y los sprints sin balón»). Solo para el motor combinado C4 (`MotorCombinado` con colocación y locomoción
## nuestras): el motor de siempre no las ve (las huellas de `igualdad_motor` no cambian). Cada una con su bandera para medirla sola
## con `pruebas/comparar_tres_motores.tscn` (MOTORES=combinado_c4):
##   C4_DESMARQUES=0/1  dos carreras al espacio a la vez (también mediapuntas y extremos) y menos descanso entre carreras
##   C4_SPRINTS=0/1     el que está lejos de su sitio (atacando o replegando) corre de verdad
##   C4_LARGOS=0/1      balón largo al que hace la carrera, también desde lejos (antes el pase al hueco solo salía a < 48 m del arco)
## Los valores por defecto son los que ganaron en la medición (ver `docs/04_auditorias/MOTOR_LEAGUE_SOCCER_PLAN.md`, «Mejoras de C4»).

static var DESMARQUES := _bandera("C4_DESMARQUES", true)
static var SPRINTS := _bandera("C4_SPRINTS", true)
static var LARGOS := _bandera("C4_LARGOS", true)

const SPRINT_LEJOS := 9.0          ## a más de esto de su sitio, corre
const CARRERAS_A_LA_VEZ := 2
const DESCANSO_CARRERA := 2.0      ## el de siempre: 4 s
const ROLES_CARRERA := ["DC", "ED", "EI", "SD", "MCO", "MD", "MI"]
const LARGO_MIN := 22.0            ## distancia del pase largo
const LARGO_MAX := 55.0

static func _bandera(nombre: String, defecto: bool) -> bool:
	var v := OS.get_environment(nombre)
	return defecto if v == "" else v == "1"

## Pone en el motor lo que lee `MotorCarreras` (por metadatos: el motor de siempre no los tiene).
static func preparar(m: Object) -> void:
	if DESMARQUES:
		m.set_meta("carreras_n", CARRERAS_A_LA_VEZ)
		m.set_meta("carreras_descanso", DESCANSO_CARRERA)
		m.set_meta("carreras_roles", ROLES_CARRERA)

## Sprints sin balón: si el destino queda lejos, se corre.
static func sprint(m: Object, p: Dictionary, obj: Vector3) -> void:
	if SPRINTS and obj != Vector3.INF:
		var yo: Vector3 = m.pos(p)
		if Vector2(obj.x - yo.x, obj.z - yo.z).length() > SPRINT_LEJOS:
			p["correr"] = true

## Los que hacen ahora una carrera al espacio en el equipo de `local`.
static func corredores(m: Object, local: bool) -> Array:
	var ids: Array = []
	for i in int(m.get_meta("carreras_n", 1)):
		var k := "_carrera_%s%s" % ["l" if local else "v", "" if i == 0 else str(i)]
		if m.has_meta(k):
			var e: Dictionary = m.get_meta(k)
			if String(e["id"]) != "" and float(m.t) <= float(e["hasta"]):
				ids.append(String(e["id"]))
	return ids

## Balón largo al que corre al espacio: lejos del arco rival (cerca ya lo hace el pase al hueco de siempre), con la línea de pase
## limpia y el receptor habilitado. Devuelve true si pateó.
static func balon_largo(m: Object, p: Dictionary, rng: RandomNumberGenerator) -> bool:
	if not LARGOS:
		return false
	var local := bool(p["es_local"])
	var yo: Vector3 = m.pos(p)
	var arco: Vector3 = m._arco_rival(p)
	if Vector2(yo.x - arco.x, yo.z - arco.z).length() < 45.0:
		return false
	var d: float = m.dir_ataque(local)
	var ids := corredores(m, local)
	if ids.is_empty():
		return false
	for q: Dictionary in m.jugadores:
		if not (String(q["id"]) in ids) or q == p:
			continue
		var qp: Vector3 = m.pos(q)
		var dist := yo.distance_to(qp)
		if dist < LARGO_MIN or dist > LARGO_MAX or (qp.z - yo.z) * d < 8.0 or m._adelantado(q, p):
			continue
		var espacio := qp + Vector3(0, 0, d * 6.0)
		if m._linea_tapada(yo, espacio, local):
			continue
		if rng.randf() < 0.25 + float(p["attr"]["pas"]) * 0.35:
			m._pasar_a(p, q, true, true)
			return true
	return false
