class_name MejorasC4Avance
extends RefCounted
## LLEGAR AL ÁREA CON EL BALÓN EN C4 (12-11-2026, sesión 15). Los goles de jugada son ~0,7 de ~4,4 por partido y los tiros desde
## dentro del área ~8: el portador llega a la frontal y, sin nadie encima, la toca hacia atrás (el «mejor pase» de siempre puntúa
## también los pases de seguridad). Con `C4_NO_ATRAS=1`, a menos de `DIST` m del arco rival, en juego y sin rival a menos de `PRESION`
## m, el pase que va más de `ATRAS` m hacia atrás no se da: sigue conduciendo hacia el área (o elige otra cosa). Solo en C4
## (`MotorCombinado._mejor_pase`); contador `c4_no_atras`.

static var ACTIVO := OS.get_environment("C4_NO_ATRAS") == "1"
static var DIST := float(OS.get_environment("C4_NO_ATRAS_D")) if OS.get_environment("C4_NO_ATRAS_D") != "" else 35.0
const PRESION := 3.0
const ATRAS := 3.0

## El pase que propone la decisión de siempre (`q`), o {} si en C4 sería un pase atrás evitable.
static func filtrar(m: Object, p: Dictionary, q: Dictionary) -> Dictionary:
	if not ACTIVO or q.is_empty() or String(m.estado) != "juego" or m.poseedor != p or bool(p["por"]):
		return q
	var arco: Vector3 = m._arco_rival(p)
	var yo: Vector3 = m.pos(p)
	var dy := absf(arco.z - yo.z)
	if dy > DIST or float(m._presion(p)) < PRESION:
		return q
	if absf(arco.z - m.pos(q).z) - dy < ATRAS:
		return q
	if m.get("diag") is Dictionary:
		(m.diag as Dictionary)["c4_no_atras"] = int((m.diag as Dictionary).get("c4_no_atras", 0)) + 1
	return {}

## MÁS 1 CONTRA 1 EN LA FRONTAL (sesión 15): con `C4_REGATE_AREA=k` (0 = apagada) las ganas de encarar al defensor a menos de 32 m del
## arco rival se multiplican por `k` (el de siempre ya les da ×1,25 ahí). Lo usa `MotorCombinado._intentar_regate`.
static var REGATE_AREA := float(OS.get_environment("C4_REGATE_AREA")) if OS.get_environment("C4_REGATE_AREA") != "" else 0.0

## RUPTURA DEL 9 (sesión 15): el pase al hueco (`_companero_al_hueco`, `MejorasC4Hueco`) solo encuentra receptor si alguien está a
## pocos metros de la última línea y habilitado. Con `C4_RUPTURA=1`, mientras un compañero (no el portero) tiene el balón a 25-55 m del
## arco rival con tiempo (sin rival a < 2 m) y lleva menos de `RUPTURA_T` s con él, el DC más cercano a la última línea se planta en
## ella (1 m por detrás, habilitado), cerrándose hacia el centro, y esprinta: está listo cuando el pasador decide. Contador `c4_ruptura`.
static var RUPTURA := OS.get_environment("C4_RUPTURA") == "1"
const RUPTURA_T := 3.0

static func ruptura(m: Object, p: Dictionary) -> Vector3:
	if not RUPTURA or String(m._rol(p)) != "DC":
		return Vector3.INF
	var b: Dictionary = m.poseedor
	if b.is_empty() or b == p or bool(b["por"]) or bool(b["es_local"]) != bool(p["es_local"]):
		return Vector3.INF
	if float(m.t) - float(b.get("tomo_en", -99.0)) > RUPTURA_T or float(m._presion(b)) < 2.0:
		return Vector3.INF
	var arco: Vector3 = m._arco_rival(p)
	var db := absf(arco.z - m.pos(b).z)
	if db < 25.0 or db > 55.0:
		return Vector3.INF
	var local := bool(p["es_local"])
	var d: float = m.dir_ataque(local)
	var linea: float = m._ultima_linea(not local)
	var yo: Vector3 = m.pos(p)
	if absf(yo.z - linea) > 12.0:
		return Vector3.INF
	var x := lerpf(yo.x, 0.0, 0.3)
	if float(p.get("_c4_ruptura_t", -99.0)) < float(b.get("tomo_en", 0.0)):   ## una vez por posesión del compañero
		p["_c4_ruptura_t"] = float(m.t)
		if m.get("diag") is Dictionary:
			(m.diag as Dictionary)["c4_ruptura"] = int((m.diag as Dictionary).get("c4_ruptura", 0)) + 1
	return Vector3(x, 0, linea - d * 1.0)

## RECHACE VIVO (sesión 15): el portero que no blocca rechaza la mitad de las veces hacia la línea de fondo (córner). Con
## `C4_RECHACE=p` (0 = apagada), ese rechace hacia el fondo, con probabilidad `p`, sale hacia delante (al área): hay segunda jugada
## para los que siguen el tiro (`C4_SEGUIR`). Solo sortea con la bandera encendida. Contador `c4_rechace_vivo`.
static var RECHACE := float(OS.get_environment("C4_RECHACE")) if OS.get_environment("C4_RECHACE") != "" else 0.0

static func rechace(m: Object, gk: Dictionary) -> void:
	if RECHACE <= 0.0 or not (m.poseedor as Dictionary).is_empty():
		return
	var propio: Vector3 = m._arco_propio(gk)
	var v: Vector3 = m.vel_balon
	if v.z * signf(propio.z) <= 0.0:
		return   ## ya sale hacia delante
	if (m._rng as RandomNumberGenerator).randf() >= RECHACE:
		return
	m.vel_balon = Vector3(v.x * 0.7, v.y, -v.z * 2.0 - signf(propio.z) * 2.0)
	if m.get("diag") is Dictionary:
		(m.diag as Dictionary)["c4_rechace_vivo"] = int((m.diag as Dictionary).get("c4_rechace_vivo", 0)) + 1

## DEFINIR DENTRO DEL ÁREA (sesión 15): con `C4_DEFINIR=1`, a menos de `DEFINIR_D` m del arco, el remate de la IA va al palo contrario al
## portero (si está corrido > 0,3 m) y raso; el error del tiro no cambia. Contador `c4_definir`.
static var DEFINIR := OS.get_environment("C4_DEFINIR") == "1"
static var DEFINIR_D := float(OS.get_environment("C4_DEFINIR_D")) if OS.get_environment("C4_DEFINIR_D") != "" else 17.0

static func definir(m: Object, p: Dictionary, dist: float, apunte: Vector2) -> Vector2:
	if not DEFINIR or dist >= DEFINIR_D:
		return apunte
	var gx := 0.0
	for q: Dictionary in m.jugadores:
		if bool(q["por"]) and bool(q["es_local"]) != bool(p["es_local"]):
			gx = (m.pos(q) as Vector3).x
	var r := apunte
	if absf(gx) > 0.3:
		r.x = -signf(gx) * maxf(absf(apunte.x), 0.7)
	r.y = minf(apunte.y, -0.45)
	if m.get("diag") is Dictionary:
		(m.diag as Dictionary)["c4_definir"] = int((m.diag as Dictionary).get("c4_definir", 0)) + 1
	return r

## EL ERROR DEL REMATE DENTRO DEL ÁREA (sesión 15): con `C4_ERROR_AREA=k` (0 = apagada) el error de todo remate que no sea penal a menos
## de 17 m del arco se multiplica por `k` (< 1 = más preciso; vale para la IA y para el humano). Contador `c4_error_area`.
static var ERROR_AREA := float(OS.get_environment("C4_ERROR_AREA")) if OS.get_environment("C4_ERROR_AREA") != "" else 0.0

static func error_tiro(m: Object, lejos: float, error: float, clase: String) -> float:
	if ERROR_AREA <= 0.0 or lejos >= 17.0 or clase == "penal":
		return error
	if m.get("diag") is Dictionary:
		(m.diag as Dictionary)["c4_error_area"] = int((m.diag as Dictionary).get("c4_error_area", 0)) + 1
	return error * ERROR_AREA

## EL PORTERO ANTE EL REMATE DESDE DENTRO DEL ÁREA (sesión 15): con `C4_PARADA_AREA=k` (0 = apagada) la probabilidad de parar un remate
## que sale a menos de 17 m de su arco se multiplica por `k`; los de lejos no cambian (que no suban los goles «tontos»). Contador
## `c4_parada_area`.
static var PARADA_AREA := float(OS.get_environment("C4_PARADA_AREA")) if OS.get_environment("C4_PARADA_AREA") != "" else 0.0

static func parada(m: Object, gk: Dictionary, desde: Vector3, prob: float) -> float:
	if PARADA_AREA <= 0.0:
		return prob
	var arco: Vector3 = m._arco_propio(gk)
	if Vector2(desde.x - arco.x, desde.z - arco.z).length() >= 17.0:
		return prob
	if m.get("diag") is Dictionary:
		(m.diag as Dictionary)["c4_parada_area"] = int((m.diag as Dictionary).get("c4_parada_area", 0)) + 1
	return prob * PARADA_AREA

## EL PORTERO PARA LO PARABLE (17-11-2026, alarma de goles de C4: 4,1 goles por partido y 46 % de gol de lo que va a puerta, real ~30 %). La
## sonda `pruebas/_sonda/sonda_goles_c4.tscn` mostró que, con el balón a su alcance, el portero fallaba la tirada en ~1 de cada 3: la fuerza del
## tiro recortaba la probabilidad igual al cuerpo que a la escuadra (un tiro de 30 m/s al cuerpo se paraba ~81 %). Con `C4_PARADA_CUERPO=f`
## (0 = apagada) la probabilidad no baja de `f·(1 − lat/alcance)`: al cuerpo, casi siempre; al límite de su estirada, como antes. Contador
## `c4_parada_cuerpo` (las veces que sube).
static var PARADA_CUERPO := float(OS.get_environment("C4_PARADA_CUERPO")) if OS.get_environment("C4_PARADA_CUERPO") != "" else 0.0

static func parada_cuerpo(m: Object, lat: float, alcance: float, prob: float) -> float:
	if PARADA_CUERPO <= 0.0 or alcance <= 0.0 or lat >= alcance:
		return prob
	var piso := PARADA_CUERPO * (1.0 - lat / alcance)
	if piso <= prob:
		return prob
	if m.get("diag") is Dictionary:
		(m.diag as Dictionary)["c4_parada_cuerpo"] = int((m.diag as Dictionary).get("c4_parada_cuerpo", 0)) + 1
	return piso

## EL ALCANCE DEL PORTERO (16-11, informe AAA H1). La sonda `futbol_plausible` medía en C4 ~6 goles por partido, 1,5 goles por gol
## esperado (xG propio) y un 11-27 % de gol en los remates de fuera del área (real ≈ 3-5 %). En `_reaccion_portero` el alcance crece con
## el tiempo que tarda el remate en llegar (`tz`) solo hasta 0,52 s y ahí se queda: un tiro de 25 m que tarda 1 s tenía el mismo alcance
## que uno de 12 m, y todo lo que iba pegado al palo entraba. `C4_ALCANCE_TIEMPO=v` (m/s; 0 = apagada) suma `v·(tz − 0,5)` metros de
## alcance (el portero se desplaza antes de estirarse), con tope `TOPE_TIEMPO`. `C4_ALCANCE_AREA=k` (0 = apagada; probada y descartada:
## con 1,5 y 2,0 el gol desde dentro casi no cambiaba) multiplica el alcance ante un remate a menos de 17 m. Contadores `c4_alcance_*`.
static var ALCANCE_TIEMPO := float(OS.get_environment("C4_ALCANCE_TIEMPO")) if OS.get_environment("C4_ALCANCE_TIEMPO") != "" else 0.0
const TOPE_TIEMPO := 2.0
static var ALCANCE_AREA := float(OS.get_environment("C4_ALCANCE_AREA")) if OS.get_environment("C4_ALCANCE_AREA") != "" else 0.0

static func alcance(m: Object, gk: Dictionary, desde: Vector3, a: float, tz: float) -> float:
	var r := a
	if ALCANCE_TIEMPO > 0.0 and tz > 0.5:
		r += minf(ALCANCE_TIEMPO * (tz - 0.5), TOPE_TIEMPO)
		_contar(m, "c4_alcance_tiempo")
	if ALCANCE_AREA > 0.0:
		var arco: Vector3 = m._arco_propio(gk)
		if Vector2(desde.x - arco.x, desde.z - arco.z).length() < 17.0:
			r *= ALCANCE_AREA
			_contar(m, "c4_alcance_area")
	return r

## LA PARADA POR TRAMOS (17-11-2026, decisión de Auditoría tras la sonda de goles: C4 daba 4,1 goles y 46 % de gol de lo que va a puerta con
## tiros a 20 m de media). Con `C4_PARADA_REAL=1` la probabilidad de GOL de lo que el portero alcanza (1 − prob) se multiplica por un factor que
## va de 1 a bocajarro (< 6 m: queda como estaba, el portero no es un superhéroe) a `PR_MED` desde 16 m; un tiro flojo (< 22 m/s) fuera del área
## chica se multiplica además hasta `PR_FLOJO`. Y desde 16 m el alcance crece hasta `PR_ALC` (un tiro de lejos da tiempo a estirarse).
## Contadores `c4_parada_real` y `c4_alcance_real`. Ajustes: `C4_PR_MED`, `C4_PR_FLOJO`, `C4_PR_ALC`.
static var PARADA_REAL := OS.get_environment("C4_PARADA_REAL") == "1"
static var PR_MED := float(OS.get_environment("C4_PR_MED")) if OS.get_environment("C4_PR_MED") != "" else 0.55
static var PR_FLOJO := float(OS.get_environment("C4_PR_FLOJO")) if OS.get_environment("C4_PR_FLOJO") != "" else 0.6
static var PR_ALC := float(OS.get_environment("C4_PR_ALC")) if OS.get_environment("C4_PR_ALC") != "" else 1.2

## 0 a bocajarro (< 6 m del arco), 1 desde 16 m.
static func _tramo(m: Object, gk: Dictionary, desde: Vector3) -> float:
	var arco: Vector3 = m._arco_propio(gk)
	return clampf((Vector2(desde.x - arco.x, desde.z - arco.z).length() - 6.0) / 10.0, 0.0, 1.0)

static func parada_real(m: Object, gk: Dictionary, desde: Vector3, prob: float) -> float:
	if not PARADA_REAL:
		return prob
	var w := _tramo(m, gk, desde)
	var f := lerpf(1.0, PR_MED, w)
	var v: float = (m.vel_balon as Vector3).length()
	if v < 22.0:
		f *= lerpf(1.0, PR_FLOJO, clampf((22.0 - v) / 8.0, 0.0, 1.0) * clampf(w * 2.5, 0.0, 1.0))
	_contar(m, "c4_parada_real")
	return 1.0 - (1.0 - clampf(prob, 0.0, 1.0)) * f

static func alcance_real(m: Object, gk: Dictionary, desde: Vector3, a: float) -> float:
	if not PARADA_REAL:
		return a
	_contar(m, "c4_alcance_real")
	return a * lerpf(1.0, PR_ALC, _tramo(m, gk, desde))

## Y lo que pasa DESPUÉS de la parada (medido: con más paradas subían los goles de rechace y los tiros, de 20 a 24): atrapa los tiros
## de hasta `PR_AGARRE_V` m/s (antes 22) y, estirado, también los flojos (con la mitad de probabilidad); y el rechace va hacia fuera
## (a córner) con probabilidad `PR_FUERA` (antes 0,5). Ajustes: `C4_PR_AGARRE_V`, `C4_PR_FUERA`.
static var PR_AGARRE_V := float(OS.get_environment("C4_PR_AGARRE_V")) if OS.get_environment("C4_PR_AGARRE_V") != "" else 28.0
static var PR_FUERA := float(OS.get_environment("C4_PR_FUERA")) if OS.get_environment("C4_PR_FUERA") != "" else 0.8

static func agarra(m: Object, gk: Dictionary, estirada: bool, fuerza: float, rng: RandomNumberGenerator) -> bool:
	if fuerza >= (22.0 if estirada else PR_AGARRE_V):
		return false
	var k := float(gk["attr"]["par"]) * 0.9 * GestoTecnico.agarre(m) * (0.5 if estirada else 1.0)
	var si := rng.randf() < k
	if si:
		_contar(m, "c4_agarra")
	return si

static func _contar(m: Object, k: String) -> void:
	if m.get("diag") is Dictionary:
		(m.diag as Dictionary)[k] = int((m.diag as Dictionary).get(k, 0)) + 1

## EL PASE ATRÁS DESDE EL FONDO (sesión 15): el extremo que llega al fondo (`C4_BANDA`) solo sabía centrar por arriba (`MejorasC4.centro`).
## Con `C4_PASE_ATRAS=1`, abierto (|x| > 9) y a menos de 10 m de la línea de fondo, con probabilidad `PASE_ATRAS_P` busca un compañero
## de campo en el área (a 6-16 m del arco y |x| < 9, habilitado, línea limpia) y se la da RASA (el pase de siempre); elige al más libre.
## Va antes que el centro por arriba. Contador `c4_pase_atras`.
static var PASE_ATRAS := OS.get_environment("C4_PASE_ATRAS") == "1"
const PASE_ATRAS_P := 0.6
static var PASE_ATRAS_Z := float(OS.get_environment("C4_PASE_ATRAS_Z")) if OS.get_environment("C4_PASE_ATRAS_Z") != "" else 10.0   ## m a la línea de fondo
static var PASE_ATRAS_ANCHO := PASE_ATRAS_Z > 12.0   ## con zona amplia: desde |x| > 7, receptor a 5-18 m y |x| < 11

static func pase_atras(m: Object, p: Dictionary, rng: RandomNumberGenerator) -> bool:
	if not PASE_ATRAS:
		return false
	var yo: Vector3 = m.pos(p)
	var arco: Vector3 = m._arco_rival(p)
	if absf(yo.x) < (7.0 if PASE_ATRAS_ANCHO else 9.0) or absf(arco.z - yo.z) > PASE_ATRAS_Z:
		return false
	if m.get("diag") is Dictionary:
		(m.diag as Dictionary)["c4_fondo_zona"] = int((m.diag as Dictionary).get("c4_fondo_zona", 0)) + 1
	var local := bool(p["es_local"])
	var mejor: Dictionary = {}
	var libre := 0.0
	for q: Dictionary in m.jugadores:
		if q == p or bool(q["es_local"]) != local or bool(q["por"]):
			continue
		var qp: Vector3 = m.pos(q)
		var da := Vector2(qp.x - arco.x, qp.z - arco.z).length()
		if da < (5.0 if PASE_ATRAS_ANCHO else 6.0) or da > (18.0 if PASE_ATRAS_ANCHO else 16.0) or absf(qp.x) > (11.0 if PASE_ATRAS_ANCHO else 9.0) or m._adelantado(q, p) or m._linea_tapada(yo, qp, local):
			continue
		var pr: float = m._presion(q)
		if pr > libre:
			libre = pr
			mejor = q
	if mejor.is_empty() or rng.randf() > PASE_ATRAS_P:
		return false
	if m.get("diag") is Dictionary:
		(m.diag as Dictionary)["c4_pase_atras"] = int((m.diag as Dictionary).get("c4_pase_atras", 0)) + 1
	m._pasar_a(p, mejor)
	return true

## LLEGADA AL ÁREA (sesión 15, OK del líder; toca COLOCACIÓN: solo C4 y con bandera). Cuando el extremo encara (`C4_BANDA`) el área
## está vacía: el pase atrás (`C4_PASE_ATRAS`) no encuentra a nadie y el centro va al aire. Con `C4_LLEGADA=1`, si un compañero tiene el
## balón abierto (|x| > 9) a menos de 25 m de la línea de fondo, atacan el área: el DC el primer palo, el extremo del otro lado el
## segundo palo y el MC el punto de penal (cada uno si está a < 35 m de su sitio). Contador `c4_llegada`.
static var LLEGADA := OS.get_environment("C4_LLEGADA") == "1"

static func llegada(m: Object, p: Dictionary) -> Vector3:
	if not LLEGADA:
		return Vector3.INF
	var b: Dictionary = m.poseedor
	if b.is_empty() or b == p or bool(b["por"]) or bool(b["es_local"]) != bool(p["es_local"]):
		return Vector3.INF
	var bp: Vector3 = m.pos(b)
	var arco: Vector3 = m._arco_rival(p)
	if absf(bp.x) < 9.0 or absf(arco.z - bp.z) > 25.0:
		return Vector3.INF
	var d: float = m.dir_ataque(bool(p["es_local"]))
	var lado := signf(bp.x)
	var rol := String(m._rol(p))
	var obj := Vector3.INF
	if rol == "DC":
		obj = Vector3(lado * 2.5, 0, arco.z - d * 6.0)
	elif (rol == "ED" or rol == "EI") and signf(m.pos(p).x) != lado:
		obj = Vector3(-lado * 3.0, 0, arco.z - d * 8.0)
	elif rol == "MC" and _mc_mas_cerca(m, p, arco):
		obj = Vector3(0, 0, arco.z - d * 11.0)
	if obj == Vector3.INF or (m.pos(p) as Vector3).distance_to(obj) > 35.0:
		return Vector3.INF
	if m.get("diag") is Dictionary and float(p.get("_c4_llegada_t", -99.0)) < float(b.get("tomo_en", 0.0)):
		p["_c4_llegada_t"] = float(m.t)
		(m.diag as Dictionary)["c4_llegada"] = int((m.diag as Dictionary).get("c4_llegada", 0)) + 1
	return obj

static func _mc_mas_cerca(m: Object, p: Dictionary, arco: Vector3) -> bool:
	var yo := (m.pos(p) as Vector3).distance_to(arco)
	for q: Dictionary in m.jugadores:
		if q != p and bool(q["es_local"]) == bool(p["es_local"]) and String(m._rol(q)) == "MC" and (m.pos(q) as Vector3).distance_to(arco) < yo:
			return false
	return true
