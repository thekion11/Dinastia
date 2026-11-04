class_name MotorRegiones
extends RefCounted
## EL MAPA DE REGIONES NUMERADAS CON OCUPACIÓN (03-11-2026, pedido del dueño tras ver el vídeo: «basarte en un mapa de coordenadas y asignación
## de número por jugador»). Idea clásica de los juegos de fútbol sencillos (Buckland, *Simple Soccer*: el campo es una rejilla de regiones numeradas
## y cada jugador tiene una «región de casa») unida a un mapa de OCUPACIÓN: el campo es una rejilla de `COLS`×`FILAS` regiones numeradas
## (0..39: número = fila·COLS + columna; fila 0 = la línea de fondo del lado y columna 0 = x negativa) y, en cada fotograma, un jugador que
## defiende no puede compartir región con un compañero que ya la reclamó: el siguiente se corre a la región libre más cercana (por anillos).
## Cada región mide ≈ 13,6 × 13,1 m. Así dos defensas no se amontonan en el mismo hueco aunque los dos quieran marcar al rival del lado del balón.
## No toca al que presiona ni al segundo. `SIN_REGIONES=1` = sin mapa de ocupación.
const COLS := 5
const FILAS := 8
static var _sin := OS.has_environment("SIN_REGIONES")

static func ancho_reg(m: MotorJugable) -> float:
	return 2.0 * m.ANCHO / COLS

static func largo_reg(m: MotorJugable) -> float:
	return 2.0 * m.LARGO / FILAS

## Número de la región que contiene el punto (x, z).
static func numero(m: MotorJugable, x: float, z: float) -> int:
	var c := clampi(int(floor((x + m.ANCHO) / ancho_reg(m))), 0, COLS - 1)
	var f := clampi(int(floor((z + m.LARGO) / largo_reg(m))), 0, FILAS - 1)
	return f * COLS + c

## Centro de la región `n`.
static func centro(m: MotorJugable, n: int) -> Vector3:
	var c := n % COLS
	var f := n / COLS
	return Vector3(-m.ANCHO + (c + 0.5) * ancho_reg(m), 0.0, -m.LARGO + (f + 0.5) * largo_reg(m))

## Región de casa de `p`: la de su puesto (el dinámico de `MotorRoles`).
static func casa(m: MotorJugable, p: Dictionary) -> int:
	var b: Vector3 = MotorRoles.base(m, p)
	return numero(m, b.x, b.z)

static func _ocup(m: MotorJugable, local: bool) -> Dictionary:
	var k := "_regiones_%s" % ("l" if local else "v")
	var e: Dictionary = m.get_meta(k, {"t": -99.0, "mapa": {}})
	if e["t"] != m.t:
		e = {"t": m.t, "mapa": {}}
		m.set_meta(k, e)
	return e["mapa"]

## Devuelve un objetivo que no comparte región con un compañero que ya la reclamó este fotograma: el mismo `obj` si su región está libre; si no, el centro de
## la región libre más cercana (±2 columnas y ±1 fila para no cambiar de línea; si no hay, `obj`). Registra la región reclamada.
static func libre(m: MotorJugable, p: Dictionary, obj: Vector3) -> Vector3:
	if _sin:
		return obj
	var mapa := _ocup(m, bool(p["es_local"]))
	var yo := String(p["id"])
	var n := numero(m, obj.x, obj.z)
	if not mapa.has(n) or mapa[n] == yo:
		mapa[n] = yo
		return obj
	var mejor := -1
	var md := INF
	for dc in range(-2, 3):
		for df in range(-1, 2):   ## solo ±1 fila: nadie salta de línea (no se intercalan)
			var c := n % COLS + dc
			var f := n / COLS + df
			if c < 0 or c >= COLS or f < 0 or f >= FILAS:
				continue
			var k := f * COLS + c
			if mapa.has(k) and mapa[k] != yo:
				continue
			var d := centro(m, k).distance_to(obj)
			if d < md:
				md = d
				mejor = k
	if mejor < 0:
		return obj
	mapa[mejor] = yo
	return centro(m, mejor)
