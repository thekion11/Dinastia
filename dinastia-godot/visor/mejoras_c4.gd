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
static var AEREO := _bandera("C4_AEREO", false)   ## medido el 12-11 (12+12 partidos): más cabezazos pero −1 gol de pie por partido; DESCARTADO, apagado
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

## FALTA LATERAL ENSAYADA (12-11-2026, sesión 13). La IA tiraba directo toda falta a menos de 30 m (también desde la banda, sin ángulo)
## y desde más lejos daba un pase corto, aunque los rematadores ya estaban colocados en el área como en un córner. En C4, desde un
## costado (|x| > FALTA_X) a menos de 40 m, o centrada a 30-40 m, se centra al área: al primer palo, al penal o al segundo palo, con el
## error del pase del lanzador. Las faltas centradas y cercanas se siguen tirando a puerta.
static var FALTA := _bandera("C4_FALTA", true)
const FALTA_X := 14.0
static func falta_ensayada(m: Object, p: Dictionary, lugar: Vector3, rng: RandomNumberGenerator) -> bool:
	if not FALTA:
		return false
	var arco: Vector3 = m._arco_rival(p)
	var dist := Vector2(lugar.x - arco.x, lugar.z - arco.z).length()
	var lateral := absf(lugar.x) > FALTA_X
	if dist > 40.0 or (not lateral and dist < 30.0):
		return false
	var sa := signf(arco.z)
	var err := (1.0 - float(p["attr"]["pas"])) * 5.0
	var zona := rng.randi() % 3   ## 0 primer palo, 1 penal, 2 segundo palo
	var x := [signf(lugar.x) * 2.5, 0.0, -signf(lugar.x) * 3.5][zona] as float if lateral else rng.randf_range(-3.0, 3.0)
	var destino := Vector3(x + rng.randf_range(-err, err), 1.7, arco.z - sa * [5.5, 10.0, 7.0][zona])
	m._ctx_golpeo = "centro"
	m._patear(p, destino, 18.0, 0.0, -signf(lugar.x) * 7.0 * -sa, "pase")
	m.pase_a = m._companero_cerca(p, destino)
	m._contar("c4_falta_ensayada")
	return true

## RITMO EN EL ÚLTIMO TERCIO (12-11-2026, sesión 13). Con espacio, el portador decide cada 1,5-2,5 s; con la paciencia ya no tira de
## lejos y conduce todo ese tiempo contra el bloque rival (las pérdidas por entrada en el último tercio subieron). En C4, a menos de
## `RITMO_D` m del arco la espera hasta la próxima decisión se multiplica por `RITMO_K`: pase, regate o tiro llegan antes.
static var RITMO := _bandera("C4_RITMO", false)
static var RITMO_K := _num("C4_RITMO_K", 0.55)
const RITMO_D := 35.0
static func ritmo_ultimo_tercio(m: Object, p: Dictionary, decision_en: float) -> float:
	if not RITMO:
		return decision_en
	var yo: Vector3 = m.pos(p)
	var arco: Vector3 = m._arco_rival(p)
	if Vector2(yo.x - arco.x, yo.z - arco.z).length() > RITMO_D:
		return decision_en
	var t: float = m.t
	return t + (decision_en - t) * RITMO_K

## SAQUE DE BANDA ENSAYADO (12-11-2026, sesión 13). La IA buscaba el receptor más seguro (`MotorSaque.receptor`), casi siempre de
## espaldas o hacia atrás. En C4, en campo rival, se busca primero al compañero que está por DELANTE del saque (6-20 m), libre (sin rival
## a < 2,5 m) y habilitado, y se le lanza al pie, adelantado a su carrera.
static var BANDA_SAQUE := _bandera("C4_BANDA_SAQUE", false)
static func banda_ensayada(m: Object, p: Dictionary, lugar: Vector3, rng: RandomNumberGenerator) -> bool:
	if not BANDA_SAQUE:
		return false
	var local := bool(p["es_local"])
	var d: float = m.dir_ataque(local)
	if lugar.z * d < 0.0:
		return false   ## solo en campo rival
	var mejor: Dictionary = {}
	var mejor_z := -INF
	for q: Dictionary in m.jugadores:
		if String(q["id"]) == String(p["id"]) or bool(q["es_local"]) != local or bool(q["por"]):
			continue
		var qp: Vector3 = m.pos(q)
		var delante := (qp.z - lugar.z) * d
		if delante < 3.0 or qp.distance_to(lugar) < 6.0 or qp.distance_to(lugar) > 20.0 or m._adelantado(q, p):
			continue
		var libre := true
		for r: Dictionary in m.jugadores:
			if bool(r["es_local"]) != local and m.pos(r).distance_to(qp) < 2.5:
				libre = false
				break
		if libre and delante > mejor_z:
			mejor = q
			mejor_z = delante
	if mejor.is_empty() or rng.randf() > 0.7:
		return false
	m._pasar_a(p, mejor, false, true)
	m._anim(p, AnimExtra.variante(p["anim"], "saque_banda", String(p.get("id", "")), rng), true)
	m._contar("c4_banda_ensayada")
	return true

## CONTENER EN EL ÚLTIMO TERCIO (12-11-2026, sesión 13, decisión del líder). La IA entra en cuanto el portador queda a ~1,25 m: en el
## último tercio eso mataba la jugada antes del regate o la pared (~3,5 pérdidas por entrada por partido ahí). En C4, a menos de
## `CONTENER_D` m de su arco, el defensor solo entra con el radio de siempre si es buen momento (`MotorEntrada`: de espaldas, control
## largo, pegado a la banda) o si es el ÚLTIMO hombre; si no, contiene y temporiza (radio × `CONTENER_K`). v2: solo cuenta «de espaldas»
## (el control largo se daba casi siempre al conducir y la primera versión no cambiaba nada: medido el 12-11).
static var CONTENER := _bandera("C4_CONTENER", false)   ## medido el 12-11 (12+12, v1 y v2, K 0,6 y 0,4): sin efecto en intentos ni goles; DESCARTADO, apagado
static var CONTENER_K := _num("C4_CONTENER_K", 0.6)
const CONTENER_D := 32.0
static func radio_entrada(m: Object, p: Dictionary, victima: Dictionary, base: float, r: float) -> float:
	if not CONTENER:
		return r
	var arco: Vector3 = m._arco_rival(victima)   ## el arco que defiende `p`
	var pv: Vector3 = m.pos(victima)
	if Vector2(pv.x - arco.x, pv.z - arco.z).length() > CONTENER_D or _de_espaldas(m, p, victima):
		return r   ## lejos de su arco, o el portador de espaldas (buen momento): entra como siempre
	var yo_d := Vector2(m.pos(p).x - arco.x, m.pos(p).z - arco.z).length()
	for q: Dictionary in m.jugadores:
		if bool(q["es_local"]) == bool(p["es_local"]) and not bool(q["por"]) and String(q["id"]) != String(p["id"]):
			if Vector2(m.pos(q).x - arco.x, m.pos(q).z - arco.z).length() < yo_d - 1.0:
				return r * CONTENER_K   ## hay cobertura detrás: contener
	return r   ## último hombre: entra

## ¿El portador está de espaldas al defensor? (como `MotorEntrada`; el control largo no cuenta aquí: al conducir casi siempre se cumplía)
static func _de_espaldas(m: Object, p: Dictionary, victima: Dictionary) -> bool:
	var n: Node3D = victima["node"]
	var hacia: Vector3 = m.pos(p) - m.pos(victima)
	hacia.y = 0.0
	if hacia.length() < 0.05:
		return false
	return Vector3(sin(n.rotation.y), 0.0, cos(n.rotation.y)).dot(hacia.normalized()) < -0.2

## SEGUIR EL TIRO (12-11-2026, sesión 13; objetivo 6, portero y rechaces). Tras un remate, los `SEGUIR_N` compañeros más cerca de la zona
## del rechace (delante del área chica) corren a ella durante `SEGUIR_T` s: el rechace del portero tiene quien lo empuje.
## Devuelve el destino o Vector3.INF si `p` no sigue el tiro.
static var SEGUIR := _bandera("C4_SEGUIR", false)   ## APAGADO el 12-11 mientras se arregla: en `prueba_partido_motor` (CHI, 4711) disparaba las tarjetas (5 rojas, partido suspendido)
const SEGUIR_N := 2
const SEGUIR_T := 2.0
static func seguir_tiro(m: Object, p: Dictionary) -> Vector3:
	if not SEGUIR:
		return Vector3.INF
	var tv: Dictionary = m._tiro_vivo
	if tv.is_empty() or float(m.t) - float(tv["t"]) > SEGUIR_T:
		return Vector3.INF
	var tirador: Dictionary = tv["p"]
	if bool(tirador["es_local"]) != bool(p["es_local"]) or String(tirador["id"]) == String(p["id"]):
		return Vector3.INF
	var arco: Vector3 = m._arco_rival(tirador)
	var d: float = m.dir_ataque(bool(p["es_local"]))
	var zona := Vector3(clampf(m.pos(tirador).x * 0.3, -4.0, 4.0), 0.0, arco.z - d * 7.0)
	var clave := "%s@%.2f" % [String(tirador["id"]), float(tv["t"])]
	if String(m.get_meta("_c4_sigue_clave", "")) != clave:
		var cand: Array = []
		for q: Dictionary in m.jugadores:
			if bool(q["es_local"]) == bool(p["es_local"]) and not bool(q["por"]) and String(q["id"]) != String(tirador["id"]):
				cand.append([m.pos(q).distance_to(zona), String(q["id"])])
		cand.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
		var ids: Array = []
		for i in mini(SEGUIR_N, cand.size()):
			if float(cand[i][0]) < 25.0:
				ids.append(cand[i][1])
		m.set_meta("_c4_sigue_clave", clave)
		m.set_meta("_c4_sigue_ids", ids)
	if not (String(p["id"]) in (m.get_meta("_c4_sigue_ids", []) as Array)):
		return Vector3.INF
	var i := (m.get_meta("_c4_sigue_ids", []) as Array).find(String(p["id"]))
	return zona + Vector3((-3.0 if i == 0 else 3.0), 0.0, 0.0)

## Diagnóstico de `seguir_tiro`: «seguidor» si el infractor sigue el tiro, «a_seguidor» si la víctima lo sigue (en los 4 s tras el tiro), "" si no.
static func seguidor_en(m: Object, infractor: Dictionary, victima: Dictionary) -> String:
	var ids: Array = m.get_meta("_c4_sigue_ids", [])
	var clave := String(m.get_meta("_c4_sigue_clave", "@-99"))
	if ids.is_empty() or float(m.t) - float(clave.get_slice("@", 1)) > 4.0:
		return ""
	if String(infractor["id"]) in ids:
		return "seguidor"
	return "a_seguidor" if String(victima["id"]) in ids else ""

## NO ENTRAR POR DETRÁS (12-11-2026, sesión 13). Con los sprints sin balón de C4, el defensor que repliega llega lanzado por la espalda
## y entra de pie: en C4 las tarjetas eran casi todas «de pie + por detrás + a gran velocidad» (5-7 por partido frente a 3,5 del motor
## de siempre; con expulsiones reales, hasta 3 en un partido y el partido suspendido de `prueba_partido_motor`). En C4 el que viene por
## detrás de un portador que se aleja (la misma regla que `puntos_falta`) no entra de pie: acompaña (las cargas y duelos siguen).
static var NO_DETRAS := _bandera("C4_NO_DETRAS", true)
static var NO_DETRAS_V := _num("C4_NO_DETRAS_V", 5.0)   ## solo si el defensor llega a más de esto (m/s; 0 = siempre: tarjetas 0,5 por partido, demasiado pocas)
static func por_detras(m: Object, p: Dictionary, victima: Dictionary) -> bool:
	if not NO_DETRAS:
		return false
	var vi: Vector3 = victima.get("vel", Vector3.ZERO)
	vi.y = 0.0
	var desde: Vector3 = m.pos(victima) - m.pos(p)
	desde.y = 0.0
	var vp: Vector3 = p.get("vel", Vector3.ZERO)
	vp.y = 0.0
	if vp.length() < NO_DETRAS_V:
		return false   ## por detrás pero sin llegar lanzado: puede entrar
	return vi.length() > 1.5 and desde.length() > 0.05 and vi.normalized().dot(desde.normalized()) > 0.6
