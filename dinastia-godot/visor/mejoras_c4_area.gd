class_name MejorasC4Area
extends RefCounted
## CERRAR AL REMATADOR DENTRO DEL ÁREA (16-11-2026, informe AAA H1, criterios A1.3-A1.5; solo en C4). La sonda `futbol_plausible`
## medía ~6 goles por partido y un 39 % de gol en los remates desde dentro del área (real ≈ 13-15 %); el portero no era la causa
## (`C4_ALCANCE_AREA` no movía la cifra) y en remates aislados C4 y el motor de siempre daban lo mismo: el rematador llegaba LIBRE.
## Con el balón del rival a menos de `DIST` m del arco propio (solo jugadores de campo; el primer presionador sigue con lo suyo):
##   · el SEGUNDO presionador se planta en la línea balón → centro del arco, a `CIERRE` m del balón (tapa el remate: lo cuenta
##     `MotorTiroLimpio` como bloqueo y baja las ganas de tirar);
##   · cada rival de campo dentro del área (a menos de `AREA` m del arco) lo toma el compañero libre MÁS CERCANO a él (a menos de
##     `ALCANCE` m), que se pone a `MARCA` m entre él y el arco, esprintando.
## APAGADA (`C4_CIERRE_AREA=1` la enciende): medida sin efecto en los goles (ver `docs/04_auditorias/H1_perfil_manejo_2026-11-16.md`).
## Contador `c4_cierre_area` (pasos en que alguien cierra).
static var ACTIVO := OS.get_environment("C4_CIERRE_AREA") == "1"
const DIST := 24.0
const CIERRE := 1.8
const AREA := 18.0
const ALCANCE := 9.0
const MARCA := 0.9

static func _plano(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

## Destino del defensor `p` (o `Vector3.INF` si no le toca).
static func objetivo(m: MotorJugable, p: Dictionary) -> Vector3:
	if not ACTIVO or bool(p["por"]):
		return Vector3.INF
	var c: Dictionary = m.poseedor
	var local := bool(p["es_local"])
	if c.is_empty() or bool(c["es_local"]) == local or m.estado != "juego":
		return Vector3.INF
	var arco := m._arco_propio(p)
	var pc := m.pos(c)
	if _plano(pc, arco) > DIST:
		return Vector3.INF
	var pp := MotorPresion.papeles(m, local)
	var yo := String(p.get("id", ""))
	if yo == "" or yo == String(pp[0]):
		return Vector3.INF
	if yo == String(pp[1]):
		p["correr"] = true
		_contar(m)
		return pc + (Vector3(arco.x, 0, arco.z) - Vector3(pc.x, 0, pc.z)).normalized() * CIERRE
	## Marca de cerca al rival del área que le toca (el compañero libre más cercano a cada rival).
	var mio := m.pos(p)
	var mejor: Dictionary = {}
	var md := ALCANCE
	for q: Dictionary in m.jugadores:
		if bool(q["es_local"]) == local or bool(q["por"]) or q == c or _plano(m.pos(q), arco) > AREA:
			continue
		var d := _plano(m.pos(q), mio)
		if d >= md or not _soy_el_mas_cercano(m, p, q, d, pp):
			continue
		md = d
		mejor = q
	if mejor.is_empty():
		return Vector3.INF
	var pq := m.pos(mejor)
	p["correr"] = true
	_contar(m)
	return pq + (Vector3(arco.x, 0, arco.z) - Vector3(pq.x, 0, pq.z)).normalized() * MARCA

static func _soy_el_mas_cercano(m: MotorJugable, p: Dictionary, q: Dictionary, d: float, pp: Array) -> bool:
	var local := bool(p["es_local"])
	for o: Dictionary in m.jugadores:
		if o == p or bool(o["es_local"]) != local or bool(o["por"]):
			continue
		var oid := String(o.get("id", ""))
		if oid == String(pp[0]) or oid == String(pp[1]) or (o == m.usuario and not m.autopiloto):
			continue
		if _plano(m.pos(o), m.pos(q)) < d:
			return false
	return true

static func _contar(m: MotorJugable) -> void:
	m.diag["c4_cierre_area"] = int(m.diag.get("c4_cierre_area", 0)) + 1

## EL TIRO NO LO CONTROLA UN COMPAÑERO (16-11, informe AAA H1). Instrumentando la parada (`MotorParada`) en 3 partidos de C4: de 8,3
## paradas decididas por partido, 4 se anulaban porque otro tocaba el balón antes de llegar al portero, 2,3 de ellas un compañero del
## rematador: el balón suelto lo toma el más cercano a menos de 0,9 m y un tiro de 25 m/s se «controlaba» con la probabilidad del
## regate (≈ 85 %); el compañero quedaba solo a pocos metros del portero, que ya se había vencido, y remataba a quemarropa.
## Con `C4_TIRO_COMPANERO=1` (APAGADA: en 12+12 partidos no bajó los goles de forma medible) un compañero del que remató no puede hacerse con el remate mientras va a más de
## `VEL_TIRO` m/s: el tiro sigue su camino (si se frena o rebota, sí puede). Contador `c4_tiro_companero` (remates en que pasó).
static var TIRO_COMPANERO := OS.get_environment("C4_TIRO_COMPANERO") == "1"
const VEL_TIRO := 12.0

static func puede_tomar_tiro(m: MotorJugable, p: Dictionary) -> bool:
	if not TIRO_COMPANERO:
		return true
	var tv: Dictionary = m._tiro_vivo
	var tirador: Dictionary = tv.get("p", {})
	if tirador.is_empty() or p == tirador or bool(p["es_local"]) != bool(tirador["es_local"]) or m.vel_balon.length() < VEL_TIRO:
		return true
	if not tv.has("_companero"):
		tv["_companero"] = true   ## una vez por remate (cada paso lo pregunta)
		m.diag["c4_tiro_companero"] = int(m.diag.get("c4_tiro_companero", 0)) + 1
	return false

## EL REMATE APRETADO DENTRO DEL ÁREA (16-11, informe AAA H1). Con `C4_PRESION_AREA=k` (0 = apagada) el error de un remate (no penal)
## desde menos de 17 m crece con lo cerca que tenga al rival más próximo: ×(1 + k·cercanía), cercanía = 1 a 1 m o menos y 0 a
## `PRESION_LIBRE` m o más. El que remata solo no cambia (siguen las ocasiones claras). Contador `c4_presion_area`.
static var presion_area := float(OS.get_environment("C4_PRESION_AREA")) if OS.get_environment("C4_PRESION_AREA") != "" else 0.0
const PRESION_LIBRE := 4.0

static func error_presion(m: MotorJugable, p: Dictionary, lejos: float, error: float, clase: String) -> float:
	if presion_area <= 0.0 or lejos >= 17.0 or clase == "penal":
		return error
	var cerca := clampf((PRESION_LIBRE - m._presion(p)) / (PRESION_LIBRE - 1.0), 0.0, 1.0)
	if cerca <= 0.0:
		return error
	m.diag["c4_presion_area"] = int(m.diag.get("c4_presion_area", 0)) + 1
	return error * (1.0 + presion_area * cerca)
