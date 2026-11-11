class_name MejorasC4
extends RefCounted
## MEJORAS DE C4 (11-11-2026, ideas del dueño tras elegir C4: «mayores desmarques y balones largos creen mayores jugadas, afinar las
## jugadas de balón parado y los sprints sin balón»). Solo para el motor combinado C4 (`MotorCombinado` con colocación y locomoción
## nuestras): el motor de siempre no las ve (las huellas de `igualdad_motor` no cambian). Cada una con su bandera para medirla sola
## con `pruebas/comparar_tres_motores.tscn` (MOTORES=combinado_c4):
##   C4_DESMARQUES=0/1  dos carreras al espacio a la vez (también mediapuntas y extremos) y menos descanso entre carreras
##   C4_SPRINTS=0/1     el que está lejos de su sitio (atacando o replegando) corre de verdad
##   C4_LARGOS=0/1      balón largo al que hace la carrera, también desde lejos (antes el pase al hueco solo salía a < 48 m del arco)
##   C4_BALON_PARADO=0/1 centros desde la banda con gente en el área (antes ≈0,3 por partido: casi nunca se llegaba a esa decisión)
##                      y córneres por desvío (los remates bloqueados que salen por el fondo son córner: 4,5 → ~9 por partido)
## Los valores por defecto son los que ganaron en la medición (ver `docs/04_auditorias/MOTOR_LEAGUE_SOCCER_PLAN.md`, «Mejoras de C4»).

static var DESMARQUES := _bandera("C4_DESMARQUES", true)
static var SPRINTS := _bandera("C4_SPRINTS", true)
static var LARGOS := _bandera("C4_LARGOS", true)
static var BALON_PARADO := _bandera("C4_BALON_PARADO", true)
static var CENTROS := _bandera("C4_CENTROS", true)   ## solo la parte de los centros (para medirla aparte de los córneres)
const CORNER_DESVIO := 0.2          ## probabilidad de que un remate fallado que sale por el fondo sea córner (MotorCorner)
const CENTRO_BANDA := 13.0          ## a más de esto del eje...
const CENTRO_FONDO := 30.0          ## ...y a menos de esto de la línea de fondo, se puede centrar

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
	if BALON_PARADO:
		m.set_meta("corner_desvio", CORNER_DESVIO)
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

## Centro desde la banda (de jugadores de banda o delanteros abiertos) cuando hay al menos 2 compañeros en el área: al punto de penal o
## al segundo palo, alto, con el error del pase. El remate de cabeza lo resuelve el motor como siempre. Devuelve true si centró.
static func centro(m: Object, p: Dictionary, rng: RandomNumberGenerator) -> bool:
	if not (BALON_PARADO and CENTROS):
		return false
	var yo: Vector3 = m.pos(p)
	var arco: Vector3 = m._arco_rival(p)
	if absf(yo.x) < CENTRO_BANDA or absf(arco.z - yo.z) > CENTRO_FONDO:
		return false
	var en_area := 0
	for q: Dictionary in m.jugadores:
		if q != p and bool(q["es_local"]) == bool(p["es_local"]) and not bool(q["por"]) and m.pos(q).distance_to(arco) < 17.0:
			en_area += 1
	if en_area < 2 or rng.randf() > 0.55:
		return false
	var d: float = m.dir_ataque(bool(p["es_local"]))
	var err := (1.0 - float(p["attr"]["pas"])) * 6.0
	var lejos := rng.randf() < 0.45   ## al segundo palo
	var x := (-signf(yo.x) * rng.randf_range(2.0, 5.0)) if lejos else rng.randf_range(-3.0, 3.0)
	var destino := Vector3(x + rng.randf_range(-err, err), 1.7, arco.z - d * rng.randf_range(5.0, 11.0))
	m._ctx_golpeo = "centro"
	MotorTraza.centro(m as MotorJugable, p)
	m._patear(p, destino, 17.0, 0.0, -signf(yo.x) * 6.0 * -d, "pase")
	m.pase_a = m._companero_cerca(p, destino)
	return true
