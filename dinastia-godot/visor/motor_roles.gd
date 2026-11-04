class_name MotorRoles
extends RefCounted
## ROLES DINÁMICOS CON EL ALGORITMO HÚNGARO (03-11-2026, IA F2 de `docs/04_auditorias/terceros_ia_motor_2026-11-01.md`; idea de
## League-Soccer `CalculateDynamicRoles`, escrita aparte). Antes cada jugador volvía SIEMPRE a la posición de su puesto: si el lateral
## derecho se cruzaba al otro lado, volvía corriendo a su banda en vez de que los dos laterales intercambiaran el puesto. Ahora,
## cada 0,5 s y por LÍNEA (defensa, medios, ataque; nadie salta de línea), se reparten los puestos de la formación entre los
## jugadores de esa línea con el algoritmo húngaro (mínima distancia total a recorrer). Solo cambia la posición base que usa
## `_forma`; el rol de cada jugador (y sus reglas) no cambia. Para que no parpadee, solo se cambia el reparto si la mejora total
## supera `MEJORA_MIN` m. `SIN_ROLES_DIN=1` = cada uno a su puesto, como antes.
const REVISION := 0.5
const MEJORA_MIN := 5.0
static var _sin := OS.has_environment("SIN_ROLES_DIN")

static func _linea(rol: String) -> String:
	match rol:
		"DFC", "LD", "LI": return "def"
		"MC": return "med"
		"DC", "ED", "EI": return "del"
	return ""

## Algoritmo húngaro (Kuhn-Munkres, O(n³)) para una matriz cuadrada de costes. Devuelve, para cada fila i, la columna asignada.
static func hungaro(c: Array) -> Array:
	var n := c.size()
	var u: Array = []
	var v: Array = []
	var p: Array = []
	var way: Array = []
	u.resize(n + 1); v.resize(n + 1); p.resize(n + 1); way.resize(n + 1)
	for i in n + 1:
		u[i] = 0.0; v[i] = 0.0; p[i] = 0; way[i] = 0
	for i in range(1, n + 1):
		p[0] = i
		var j0 := 0
		var minv: Array = []
		var usado: Array = []
		minv.resize(n + 1); usado.resize(n + 1)
		for j in n + 1:
			minv[j] = INF; usado[j] = false
		while true:
			usado[j0] = true
			var i0: int = p[j0]
			var delta := INF
			var j1 := 0
			for j in range(1, n + 1):
				if not usado[j]:
					var cur: float = float(c[i0 - 1][j - 1]) - float(u[i0]) - float(v[j])
					if cur < float(minv[j]):
						minv[j] = cur
						way[j] = j0
					if float(minv[j]) < delta:
						delta = float(minv[j])
						j1 = j
			for j in n + 1:
				if usado[j]:
					u[p[j]] = float(u[p[j]]) + delta
					v[j] = float(v[j]) - delta
				else:
					minv[j] = float(minv[j]) - delta
			j0 = j1
			if int(p[j0]) == 0:
				break
		while true:
			var j1b: int = way[j0]
			p[j0] = p[j1b]
			j0 = j1b
			if j0 == 0:
				break
	var res: Array = []
	res.resize(n)
	for j in range(1, n + 1):
		res[int(p[j]) - 1] = j - 1
	return res

static func _coste(m: MotorJugable, jug: Dictionary, slot: Dictionary) -> float:
	var s: Vector3 = slot["base_pos"]
	var q := m.pos(jug)
	return Vector2(q.x - s.x, q.z - s.z).length()

## Reparto vigente del equipo: {id_del_jugador: id_del_dueño_del_puesto}.
static func reparto(m: MotorJugable, local: bool) -> Dictionary:
	var k := "_roles_%s" % ("l" if local else "v")
	var e: Dictionary = m.get_meta(k, {"t": -99.0, "mapa": {}})
	if m.t >= float(e["t"]) and m.t - float(e["t"]) < REVISION:
		return e["mapa"]
	var previo: Dictionary = e["mapa"]
	var mapa := {}
	var grupos := {"def": [], "med": [], "del": []}
	for q: Dictionary in m.jugadores:
		if bool(q["es_local"]) == local and not bool(q["por"]):
			var l := _linea(m._rol(q))
			if l != "":
				(grupos[l] as Array).append(q)
	for l: String in grupos:
		var g: Array = grupos[l]
		var n := g.size()
		for q: Dictionary in g:
			mapa[String(q["id"])] = String(previo.get(String(q["id"]), q["id"]))
		if n < 2:
			continue
		var c: Array = []
		for a: Dictionary in g:
			var fila: Array = []
			for b: Dictionary in g:
				fila.append(_coste(m, a, b))
			c.append(fila)
		var nueva: Array = hungaro(c)
		## Coste del reparto de ahora (el previo, mapeado a columnas) frente al óptimo.
		var coste_ahora := 0.0
		var coste_nuevo := 0.0
		for i in n:
			var dueno := String(mapa[String(g[i]["id"])])
			var col := i
			for j in n:
				if String(g[j]["id"]) == dueno:
					col = j
			coste_ahora += float(c[i][col])
			coste_nuevo += float(c[i][int(nueva[i])])
		if coste_ahora - coste_nuevo > MEJORA_MIN:
			for i in n:
				mapa[String(g[i]["id"])] = String(g[int(nueva[i])]["id"])
	m.set_meta(k, {"t": m.t, "mapa": mapa})
	return mapa

## La posición base que `_forma` usa para `p`: la de SU puesto, o la del que le toca ocupar ahora.
static func base(m: MotorJugable, p: Dictionary) -> Vector3:
	if _sin:
		return p["base_pos"]
	var dueno := String(reparto(m, bool(p["es_local"])).get(String(p["id"]), p["id"]))
	if dueno == String(p["id"]):
		return p["base_pos"]
	for q: Dictionary in m.jugadores:
		if String(q["id"]) == dueno:
			return q["base_pos"]
	return p["base_pos"]
