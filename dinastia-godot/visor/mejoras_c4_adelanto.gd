class_name MejorasC4Adelanto
extends RefCounted
## EL ADELANTO DEL PASE EN C4 (12-11-2026, líder; idea medida por la sesión 13). De ~38 pases fallados por partido, ~29 eran cortes y
## 19 de ellos con la línea LIMPIA: el pase se adelanta a donde VA a estar el receptor (vel × d/18, +7 m si es al hueco) y a ese punto
## llega antes un rival. Con `C4_ADELANTO=1` el pasador compara quién llega antes al punto adelantado (el balón y el receptor frente al
## rival más cercano, con su reacción) y, si gana el rival, prueba con la mitad del adelanto y, si tampoco, se la da al pie.
## Solo en C4 (gancho `_guia_pase` de la capa 1; el motor de siempre no cambia). Contadores: `c4_adelanto_medio`, `c4_adelanto_pie`.

static var MODO := OS.get_environment("C4_ADELANTO")
static var ACTIVO := MODO in ["1", "2", "3"]
## Con `C4_ADELANTO=2` (variante de medida) no toca los pases al hueco: el riesgo del pase al espacio se queda.
static var RESPETA_HUECO := MODO == "2"
## (12-11, sesión 15) `C4_ADELANTO=3`: solo en campo propio o con el marcador a favor, NUNCA en el último tercio (el riesgo que crea
## el peligro se queda). `C4_ADELANTO=4`: el adelanto no cambia; si el punto lo gana el rival, el pasador ELIGE OTRO compañero cuyo
## punto gane el nuestro (si no hay ninguno, el pase de siempre).
static var POR_ZONA := MODO == "3"
static var OTRO := MODO == "4"
const V_BALON := 15.0       ## m/s medio del pase raso
const V_RECEPTOR := 6.0     ## m/s del receptor yendo al punto
const V_RIVAL := 6.5        ## m/s del rival
const REACCION := 0.3       ## s que tarda el rival en arrancar
const MARGEN := 0.15        ## s de ventaja que tiene que sacar el nuestro

## El adelanto que usa C4: el de siempre (`base`) si nuestro receptor llega antes; si no, la mitad o al pie.
static func guia(m: Object, q: Dictionary, base: Vector3, al_hueco := false) -> Vector3:
	if not ACTIVO or base == Vector3.ZERO or (al_hueco and RESPETA_HUECO):
		return base
	var desde: Vector3 = (m.balon as Node3D).position
	if POR_ZONA and not _zona_segura(m, q, desde):
		return base
	var origen: Vector3 = m.pos(q)
	for f: float in [1.0, 0.5]:
		var g := base * f
		if _llega_antes(m, q, desde, origen, g):
			if f < 1.0:
				_contar(m, "c4_adelanto_medio")
			return g
	_contar(m, "c4_adelanto_pie")
	return Vector3.ZERO

## Campo propio o marcador a favor, y nunca en el último tercio (a < 2/3 de medio campo del arco rival).
static func _zona_segura(m: Object, q: Dictionary, desde: Vector3) -> bool:
	var local := bool(q["es_local"])
	var arco: Vector3 = m._arco_rival(q)
	var d := absf(arco.z - desde.z)
	var medio: float = m.LARGO
	if d < medio * 2.0 / 3.0:
		return false
	var g: Array = m.goles
	var a_favor := (int(g[0]) > int(g[1])) if local else (int(g[1]) > int(g[0]))
	return d > medio or a_favor

## `C4_ADELANTO=4`: si el punto adelantado de `q` lo gana un rival, otro compañero (8-32 m, línea limpia, no más atrás de 10 m que `q`)
## cuyo punto gane el nuestro; el más adelantado. Si no hay, `q`.
static func otro_receptor(m: Object, p: Dictionary, q: Dictionary, al_hueco: bool) -> Dictionary:
	if not OTRO:
		return q
	var desde: Vector3 = (m.balon as Node3D).position
	var dq: float = m.pos(q).distance_to(m.pos(p))
	var gq: Vector3 = m._guia_pase_base(q, dq, al_hueco)
	if gq == Vector3.ZERO or _llega_antes(m, q, desde, m.pos(q), gq):
		return q
	var local := bool(p["es_local"])
	var arco: Vector3 = m._arco_rival(p)
	var lim: float = absf(arco.z - m.pos(q).z) + 10.0
	var mejor := q
	var mejor_d := INF
	for r: Dictionary in m.jugadores:
		if r == p or r == q or bool(r["es_local"]) != local or bool(r["por"]):
			continue
		var rp: Vector3 = m.pos(r)
		var d: float = rp.distance_to(m.pos(p))
		var da := absf(arco.z - rp.z)
		if d < 8.0 or d > 32.0 or da > lim or da >= mejor_d or m._linea_tapada(m.pos(p), rp, local):
			continue
		if _llega_antes(m, r, desde, rp, m._guia_pase_base(r, d, false)):
			mejor = r
			mejor_d = da
	if mejor != q:
		_contar(m, "c4_adelanto_otro")
	else:
		_contar(m, "c4_adelanto_sin_otro")
	return mejor

static func _llega_antes(m: Object, q: Dictionary, desde: Vector3, origen: Vector3, g: Vector3) -> bool:
	var punto := origen + g
	var t_nuestro := maxf(Vector2(punto.x - desde.x, punto.z - desde.z).length() / V_BALON, Vector2(g.x, g.z).length() / V_RECEPTOR)
	var local := bool(q["es_local"])
	for r: Dictionary in m.jugadores:
		if bool(r["es_local"]) == local:
			continue
		var rp: Vector3 = m.pos(r)
		var t_rival := REACCION + maxf(Vector2(punto.x - rp.x, punto.z - rp.z).length() - 1.0, 0.0) / V_RIVAL
		if t_rival < t_nuestro + MARGEN:
			return false
	return true

static func _contar(m: Object, clave: String) -> void:
	if m.get("diag") is Dictionary:
		(m.diag as Dictionary)[clave] = int((m.diag as Dictionary).get(clave, 0)) + 1
