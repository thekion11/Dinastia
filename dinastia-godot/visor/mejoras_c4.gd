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
static var PACIENCIA := _bandera("C4_PACIENCIA", true)   ## (12-11, sesión 13) menos tiros lejanos: se pasa o se conduce
static var BANDA := _bandera("C4_BANDA", true)   ## (12-11, sesión 13) el de banda con espacio encara hacia el fondo para centrar
## Paciencia ante el tiro (perillas para barrer; valores por defecto = los que ganaron la medición).
static var PAC_D := _num("C4_PAC_D", 22.0)           ## desde aquí (m al arco) se pide paciencia
static var PAC_BASE := _num("C4_PAC_BASE", 0.55)     ## probabilidad de tirar a PAC_D m...
static var PAC_CAIDA := _num("C4_PAC_CAIDA", 0.035)  ## ...que baja esto por metro (a 30 m ≈ 0,27; a 38 m ≈ 0,02)
static var PAC_MEJOR := _num("C4_PAC_MEJOR", 0.35)   ## por esto si un compañero está mejor colocado
static var PAC_ESPACIO := _num("C4_PAC_ESPACIO", 0.6) ## por esto si tiene espacio para seguir conduciendo
static var CORNER_DESVIO := _num("C4_DESVIO", 0.2)   ## (perilla C4_DESVIO) probabilidad de que un remate fallado que sale por el fondo sea córner (MotorCorner)
const CENTRO_BANDA := 13.0          ## a más de esto del eje...
const CENTRO_FONDO := 30.0          ## ...y a menos de esto de la línea de fondo, se puede centrar

const SPRINT_LEJOS := 9.0          ## a más de esto de su sitio, corre
const CARRERAS_A_LA_VEZ := 2
const DESCANSO_CARRERA := 2.0      ## el de siempre: 4 s
const ROLES_CARRERA := ["DC", "ED", "EI", "SD", "MCO", "MD", "MI"]
const LARGO_MIN := 22.0            ## distancia del pase largo
const LARGO_MAX := 55.0

static func _num(nombre: String, defecto: float) -> float:
	var v := OS.get_environment(nombre)
	return defecto if v == "" else float(v)

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

## PACIENCIA ANTE EL TIRO LEJANO (12-11-2026, sesión 13). Con la decisión de siempre se tira casi en cuanto se decide a menos de ~45 m
## (`MotorTiroLimpio.alcance(30) × 1,5` y umbral 0,05): C4 hacía ~45 tiros por partido, 28-31 de lejos, y el balón casi no llegaba a la
## banda ni al área. Desde `PAC_D` m el tiro pasa a ser un sorteo que baja con la distancia, sube con el tiro del jugador y baja si
## un compañero está mejor colocado (más cerca del arco, libre y con la línea de pase limpia) o si hay espacio para seguir. Si no tira,
## sigue la decisión de siempre (pase al hueco, mejor pase o conducir). Devuelve las ganas (o −1: no tira).
static func ganas_tiro(m: Object, p: Dictionary, dist: float, ganas: float, presion: float, rng: RandomNumberGenerator) -> float:
	if not PACIENCIA or ganas <= 0.0 or dist < PAC_D:
		return ganas
	var prob := maxf(PAC_BASE - (dist - PAC_D) * PAC_CAIDA, 0.02) * (0.6 + float(p["attr"]["tir"]) * 0.8)
	if presion > 5.0:
		prob *= PAC_ESPACIO
	if prob > 0.03 and not _companero_mejor(m, p, dist).is_empty():
		prob *= PAC_MEJOR
	return ganas if rng.randf() < prob else -1.0

## PASE AL MEJOR COLOCADO (12-11, sesión 13, con la paciencia): a `PAC_D`-45 m del arco, si un compañero está mejor colocado, se le pasa
## (antes, sin presión y cerca del arco, se seguía conduciendo y casi nunca se le daba). Se llama al decidir, antes de la decisión de siempre.
static var PASE_MEJOR := _bandera("C4_PASE_MEJOR", false)   ## medido el 12-11: no mejora a la paciencia sola (descartado, queda apagado)
static func pase_al_mejor(m: Object, p: Dictionary, rng: RandomNumberGenerator) -> bool:
	if not (PACIENCIA and PASE_MEJOR):
		return false
	var yo: Vector3 = m.pos(p)
	var arco: Vector3 = m._arco_rival(p)
	var dist := Vector2(yo.x - arco.x, yo.z - arco.z).length()
	if dist < PAC_D or dist > 45.0:
		return false
	var q := _companero_mejor(m, p, dist)
	if q.is_empty() or rng.randf() > 0.45 + float(p["attr"]["pas"]) * 0.35:
		return false
	m._pasar_a(p, q)
	return true

## El compañero de campo más cerca del arco (6 m o más que el portador), sin rival a menos de 3 m, habilitado y con la línea de pase
## limpia; {} si no hay.
static func _companero_mejor(m: Object, p: Dictionary, dist: float) -> Dictionary:
	var local := bool(p["es_local"])
	var yo: Vector3 = m.pos(p)
	var arco: Vector3 = m._arco_rival(p)
	var mejor: Dictionary = {}
	var mejor_d := dist - 6.0
	for q: Dictionary in m.jugadores:
		if String(q["id"]) == String(p["id"]) or bool(q["es_local"]) != local or bool(q["por"]):
			continue
		var qp: Vector3 = m.pos(q)
		var qd := Vector2(qp.x - arco.x, qp.z - arco.z).length()
		if qd > mejor_d or yo.distance_to(qp) > 40.0:
			continue
		var libre := true
		for r: Dictionary in m.jugadores:
			if bool(r["es_local"]) != local and m.pos(r).distance_to(qp) < 3.0:
				libre = false
				break
		if libre and not m._adelantado(q, p) and not m._linea_tapada(yo, qp, local):
			mejor = q
			mejor_d = qd
	return mejor

## ENCARAR POR LA BANDA (12-11-2026, sesión 13; se probó el 12-11 sin la paciencia y no sirvió porque antes se tiraba de lejos). El
## portador abierto (|x| > 13 m), a 8-40 m del fondo y sin un rival delante en su carril, conduce pegado a la banda hacia el fondo en vez
## de ir al centro: así llega a la zona del centro (`centro`, < 30 m del fondo). Se llama después de la decisión de siempre.
static func encarar_banda(m: Object, p: Dictionary) -> void:
	if not BANDA or String((m.poseedor as Dictionary).get("id", "")) != String(p["id"]):
		return
	var yo: Vector3 = m.pos(p)
	var arco: Vector3 = m._arco_rival(p)
	var d: float = m.dir_ataque(bool(p["es_local"]))
	var al_fondo := (arco.z - yo.z) * d
	if absf(yo.x) < 13.0 or al_fondo < 8.0 or al_fondo > 40.0:
		return
	for r: Dictionary in m.jugadores:
		if bool(r["es_local"]) == bool(p["es_local"]):
			continue
		var rp: Vector3 = m.pos(r)
		if (rp.z - yo.z) * d > 0.0 and (rp.z - yo.z) * d < 5.0 and absf(rp.x - yo.x) < 2.5:
			return   ## tapado: que decida (regate o pase) la lógica de siempre
	var x := signf(yo.x) * clampf(absf(yo.x), 15.0, float(m.ANCHO) - 3.0)
	p["objetivo"] = Vector3(x, 0.0, yo.z + d * 6.0)
	p["correr"] = true

## IR AL BALÓN AÉREO (12-11-2026, sesión 13). El receptor de un pase corre a `_punto_de_recepcion`: dónde rueda el balón en ~0,6 s,
## proyectado en el SUELO. Con un centro el balón aún va por el aire y el rematador llega tarde al radio del cabezazo (0,8 m con el
## balón a 1,5-2,4 m): casi no había remates de cabeza. Con el balón en el aire se predice (tiro parabólico, sin arrastre) dónde baja a la
## altura de la cabeza (`AEREO_ALTO`) si cae cerca de un área, o al pecho si no. Devuelve Vector3.INF si el balón no va por el aire.
static var AEREO := _bandera("C4_AEREO", true)
static var SOLO_AREA := _bandera("C4_AEREO_AREA", true)
static var SOLO_CENTRO := _bandera("C4_AEREO_CENTRO", true)   ## solo en los 3 s tras un centro   ## solo balones que caen cerca de un área
static var RADIO_CABEZA := _num("C4_RADIO_CABEZA", 0.8)   ## alcance del cabezazo en C4 (0,8 = el de siempre)
const AEREO_ALTO := 1.9
const AEREO_PECHO := 0.6
static func punto_aereo(m: Object) -> Vector3:
	if not AEREO:
		return Vector3.INF
	if SOLO_CENTRO and not _tras_centro(m):
		return Vector3.INF   ## solo tras un centro o un córner (medido: con todos los balones altos bajaban los goles de pie)
	var b: Vector3 = (m.balon as Node3D).position
	var v: Vector3 = m.vel_balon
	if b.y < 1.0 and v.y < 2.0:
		return Vector3.INF
	var g: float = m.G
	var cae_t := _t_altura(b.y, v.y, g, AEREO_PECHO)
	if cae_t < 0.0:
		return Vector3.INF
	var cae := Vector3(b.x + v.x * cae_t, 0.0, b.z + v.z * cae_t)
	if absf(absf(cae.z) - float(m.LARGO)) > 20.0:
		return Vector3.INF if SOLO_AREA else cae   ## lejos del área, el de siempre (medido: en todo el campo bajaban los goles de pie)
	var alto_t := _t_altura(b.y, v.y, g, AEREO_ALTO)
	return Vector3(b.x + v.x * alto_t, 0.0, b.z + v.z * alto_t) if alto_t > 0.0 else cae

## Tiempo (s) en que el balón, bajando, pasa por la altura `h` (−1 si no llega a ella).
static func _t_altura(y: float, vy: float, g: float, h: float) -> float:
	var disc := vy * vy + 2.0 * g * (y - h)
	if disc < 0.0:
		return -1.0
	var r := (vy + sqrt(disc)) / g
	return r if r > 0.0 else -1.0

## ¿Hace menos de 3 s de un centro en juego o de un córner?
static func _tras_centro(m: Object) -> bool:
	var t: float = m.t
	if t - float(m.get_meta("_t_centro", -99.0)) < 3.0:
		return true
	return String(m.get_meta("_traza_saque_tipo", "")) == "corner" and t - float(m.get_meta("_traza_saque_t", -99.0)) < 3.0
