class_name MejorasC4Pared
extends RefCounted
## LA PARED (12-11-2026, sesión 13; objetivo 4 «cadenas de pases» y decisión del líder: paredes y apoyos cerca del área). En C4 no había
## paredes: el portador conducía contra el bloque o soltaba un pase y se quedaba quieto. Con `C4_PARED`:
##   · IDA: a 18-40 m del arco rival, con un compañero libre a 4-12 m (sin rival a < 2,5 m, línea limpia) y espacio por delante del
##     portador, este le da un pase corto y queda «en pared» durante `PARED_T` s;
##   · DESMARQUE: el que la soltó arranca al espacio que tenía delante (8 m hacia el arco, corrido hacia el centro);
##   · VUELTA: el compañero, al recibir, se la devuelve DE PRIMERA al hueco, si el que corre sigue habilitado.
## Contadores: `c4_pared_ida`, `c4_pared_vuelta`, `c4_pared_ok` (el de la ida recibe la vuelta).
static var ACTIVA := OS.get_environment("C4_PARED") == "1"
const PARED_T := 2.5
const IDA_MIN := 4.0
const IDA_MAX := 12.0

static func _estado(m: Object) -> Dictionary:
	var e: Dictionary = m.get_meta("_c4_pared", {})
	if e.is_empty() or float(m.t) - float(e["t"]) > PARED_T:
		return {}
	return e

static func ida(m: Object, p: Dictionary, rng: RandomNumberGenerator) -> bool:
	if not ACTIVA:
		return false
	var local := bool(p["es_local"])
	var yo: Vector3 = m.pos(p)
	var arco: Vector3 = m._arco_rival(p)
	var dist := Vector2(yo.x - arco.x, yo.z - arco.z).length()
	if dist < 18.0 or dist > 40.0:
		return false
	var d: float = m.dir_ataque(local)
	var hueco := yo + Vector3(-signf(yo.x) * 2.0, 0.0, d * 8.0)
	if _rival_cerca(m, hueco, local, 3.0):
		return false   ## sin espacio por delante no hay pared
	var mejor: Dictionary = {}
	var mejor_d := 999.0
	for q: Dictionary in m.jugadores:
		if bool(q["es_local"]) != local or bool(q["por"]) or String(q["id"]) == String(p["id"]):
			continue
		var qp: Vector3 = m.pos(q)
		var dq := yo.distance_to(qp)
		if dq < IDA_MIN or dq > IDA_MAX or (qp.z - yo.z) * d < -1.5 or _rival_cerca(m, qp, local, 2.5) or m._linea_tapada(yo, qp, local):   ## v2: no hacia atrás
			continue
		if dq < mejor_d:
			mejor = q
			mejor_d = dq
	if mejor.is_empty() or rng.randf() > 0.3 + float(p["attr"]["pas"]) * 0.3:
		return false
	m._pasar_a(p, mejor)
	m.set_meta("_c4_pared", {"a": String(p["id"]), "b": String(mejor["id"]), "t": float(m.t), "hueco": hueco, "vuelta": false})
	m._contar("c4_pared_ida")
	return true

## El que soltó la ida corre al hueco (destino o Vector3.INF).
static func desmarque(m: Object, p: Dictionary) -> Vector3:
	var e := _estado(m)
	if e.is_empty() or String(e["a"]) != String(p["id"]):
		return Vector3.INF
	return e["hueco"]

## El compañero devuelve de primera; o el de la ida recibe la vuelta (cuenta y cierra).
static func vuelta(m: Object, p: Dictionary) -> bool:
	var e := _estado(m)
	if e.is_empty():
		return false
	if bool(e["vuelta"]):
		if String(e["a"]) == String(p["id"]):
			m._contar("c4_pared_ok")
			m.remove_meta("_c4_pared")
		return false
	if String(e["b"]) != String(p["id"]):
		return false
	var a: Dictionary = {}
	for q: Dictionary in m.jugadores:
		if String(q["id"]) == String(e["a"]):
			a = q
	if a.is_empty() or m._adelantado(a, p) or m._linea_tapada(m.pos(p), e["hueco"], bool(p["es_local"])):   ## v2: sin línea limpia al hueco, no hay vuelta
		m.remove_meta("_c4_pared")
		return false
	m._pasar_a(p, a, false, true)
	e["vuelta"] = true
	e["t"] = float(m.t)
	m.set_meta("_c4_pared", e)
	m._contar("c4_pared_vuelta")
	return true

static func _rival_cerca(m: Object, punto: Vector3, local: bool, r: float) -> bool:
	for q: Dictionary in m.jugadores:
		if bool(q["es_local"]) != local and m.pos(q).distance_to(punto) < r:
			return true
	return false

## EL APOYO DE CARA (12-11-2026, sesión 13, decisión del líder; `C4_APOYO`). Ninguna palanca movía las cadenas de 5+: el portador apretado
## (rival a < `APOYO_PRESION` m) no tenía a quién darla. El compañero de campo más cercano (a < 15 m) se ofrece de cara: a `APOYO_D` m del
## portador, del lado contrario al rival que aprieta y algo por detrás, probando tres ángulos hasta tener la línea de pase limpia.
## Destino o Vector3.INF. Contador: `c4_apoyo` (pasos en que alguien se ofrece, por cada 10).
static var APOYO := OS.get_environment("C4_APOYO") != "0"   ## ENCENDIDO (12-11, medido 12+12): pases por posesión, acierto y regates ganados suben y las pérdidas por entrada bajan en las dos tandas
const APOYO_PRESION := 3.0
const APOYO_D := 7.0
static var APOYO2 := OS.get_environment("C4_APOYO2") == "1"   ## el tercer hombre (12-11, en medición)
const APOYO2_D := 12.0
static func apoyo(m: Object, p: Dictionary) -> Vector3:
	if not APOYO or bool(p["por"]):
		return Vector3.INF
	var c: Dictionary = m.poseedor
	if c.is_empty() or bool(c["es_local"]) != bool(p["es_local"]) or bool(c["por"]):
		return Vector3.INF
	var rival: Dictionary = m._rival_mas_cercano(c)
	var pc: Vector3 = m.pos(c)
	if rival.is_empty() or m.pos(rival).distance_to(pc) > APOYO_PRESION:
		return Vector3.INF
	## ¿Es `p` el compañero de campo más cercano al portador (a < 15 m)? ¿O el segundo (a < 20 m, el «tercer hombre», `C4_APOYO2`)?
	var mi_d := pc.distance_to(m.pos(p))
	if mi_d > 20.0:
		return Vector3.INF
	var antes := 0
	for q: Dictionary in m.jugadores:
		if bool(q["es_local"]) == bool(p["es_local"]) and not bool(q["por"]) and String(q["id"]) != String(p["id"]) and String(q["id"]) != String(c["id"]):
			if pc.distance_to(m.pos(q)) < mi_d:
				antes += 1
	if antes > (1 if APOYO2 else 0) or (antes == 0 and mi_d > 15.0):
		return Vector3.INF
	var local := bool(p["es_local"])
	var d: float = m.dir_ataque(local)
	var lejos_rival: Vector3 = pc - m.pos(rival)
	lejos_rival.y = 0.0
	var base := (lejos_rival.normalized() + Vector3(0.0, 0.0, -d * 0.6)).normalized()   ## lejos del rival y algo por detrás: de cara
	if antes == 1:
		## El tercer hombre: por delante en diagonal, del otro lado, a `APOYO2_D` m; el que recibe el apoyo de cara tiene salida adelante.
		var lado := -signf(lejos_rival.x) if absf(lejos_rival.x) > 0.1 else (1.0 if pc.x < 0.0 else -1.0)
		var punto := pc + Vector3(lado * 0.6, 0.0, d).normalized() * APOYO2_D
		punto.x = clampf(punto.x, -float(m.ANCHO) + 1.0, float(m.ANCHO) - 1.0)
		return Vector3.INF if m._adelantado(p, c) else punto
	for ang: float in [0.0, 0.6, -0.6]:
		var punto := pc + base.rotated(Vector3.UP, ang) * APOYO_D
		punto.x = clampf(punto.x, -float(m.ANCHO) + 1.0, float(m.ANCHO) - 1.0)
		if not m._linea_tapada(pc, punto, local):
			if int(m.t * 10.0) % 10 == 0:
				m._contar("c4_apoyo")
			return punto
	return Vector3.INF

## LA COLOCACIÓN DE ATAQUE LEJOS DEL BALÓN (12-11-2026, sesión 13, decisión del líder; toca COLOCACIÓN, orden 23 del 3-11: SOLO en C4
## y con bandera `C4_ANCHO`). Las palancas cerca del balón (pared, tercer hombre) no movían las cadenas de 5+: el equipo atacaba
## estrecho. Con el equipo atacando, a los que están a más de `ANCHO_LEJOS` m del balón:
##   · AMPLITUD: los extremos y volantes de banda se pegan a su línea (a 3 m de la banda);
##   · el LATERAL del lado contrario al balón se incorpora `ANCHO_LATERAL` m;
##   · PROFUNDIDAD: el 9 se planta a la altura del último defensa rival (fija a los centrales, habilitado).
## Variante 2 (`C4_ANCHO=2`): además, los mediocentros lejos del balón se reparten los carriles interiores (±40 % del ancho).
static var ANCHO_MODO := int(OS.get_environment("C4_ANCHO")) if OS.get_environment("C4_ANCHO") != "" else 0
const ANCHO_LEJOS := 15.0
const ANCHO_LATERAL := 8.0
static func ancho(m: Object, p: Dictionary, r: Vector3) -> Vector3:
	if ANCHO_MODO <= 0 or r == Vector3.INF:
		return r
	var b: Vector3 = (m.balon as Node3D).position
	var yo: Vector3 = m.pos(p)
	if Vector2(yo.x - b.x, yo.z - b.z).length() < ANCHO_LEJOS:
		return r
	var local := bool(p["es_local"])
	var d: float = m.dir_ataque(local)
	var rol: String = m._rol(p)
	var lado := signf(r.x) if absf(r.x) > 0.5 else signf(yo.x + 0.01)
	var borde := float(m.ANCHO) - 3.0
	match rol:
		"ED", "EI":
			r.x = lado * borde
		"LD", "LI":
			if signf(b.x) != lado:
				r.z += d * ANCHO_LATERAL
				r.x = lado * maxf(absf(r.x), borde - 4.0)
		"DC":
			var ultimo := -INF
			for q: Dictionary in m.jugadores:
				if bool(q["es_local"]) != local and not bool(q["por"]):
					ultimo = maxf(ultimo, m.pos(q).z * d)
			if ultimo > -INF and ultimo * d * d > r.z * d:
				r.z = d * (ultimo - 0.6)
		"MC":
			if ANCHO_MODO >= 2:
				r.x = lado * maxf(absf(r.x), float(m.ANCHO) * 0.4)
	return r
