class_name MejorasC4Adelanto
extends RefCounted
## EL ADELANTO DEL PASE EN C4 (12-11-2026, líder; idea medida por la sesión 13). De ~38 pases fallados por partido, ~29 eran cortes y
## 19 de ellos con la línea LIMPIA: el pase se adelanta a donde VA a estar el receptor (vel × d/18, +7 m si es al hueco) y a ese punto
## llega antes un rival. Con `C4_ADELANTO=1` el pasador compara quién llega antes al punto adelantado (el balón y el receptor frente al
## rival más cercano, con su reacción) y, si gana el rival, prueba con la mitad del adelanto y, si tampoco, se la da al pie.
## Solo en C4 (gancho `_guia_pase` de la capa 1; el motor de siempre no cambia). Contadores: `c4_adelanto_medio`, `c4_adelanto_pie`.

static var ACTIVO := OS.get_environment("C4_ADELANTO") in ["1", "2"]
## Con `C4_ADELANTO=2` (variante de medida) no toca los pases al hueco: el riesgo del pase al espacio se queda.
static var RESPETA_HUECO := OS.get_environment("C4_ADELANTO") == "2"
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
	var origen: Vector3 = m.pos(q)
	for f: float in [1.0, 0.5]:
		var g := base * f
		if _llega_antes(m, q, desde, origen, g):
			if f < 1.0:
				_contar(m, "c4_adelanto_medio")
			return g
	_contar(m, "c4_adelanto_pie")
	return Vector3.ZERO

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
