class_name RutaLibre
## RUTAS QUE NO ATRAVIESAN NADA (20-11, orden del dueño: «deben moverse mejor, no atravesar objetos»). Las rutas del personal del club eran
## poligonales fijas (2-4 puntos por sala) y en 7 de cada 28 tramos cruzaban un tabique o un mueble (auditoría `auditoria_rutas_personal`).
## Aquí se rehacen contra lo que haya de verdad: `libre(p: Vector3) -> bool` dice si una persona (con su radio) cabe en `p`; el juego la
## responde con una cápsula contra la física del edificio y las pruebas, con una pared falsa. Un tramo que choca se sustituye por el camino
## más corto por una rejilla de `PASO` metros (A* de 8 vecinos, sin cortar esquinas) y se acorta después tirando de la cuerda.
const PASO := 0.25
const MAX_NODOS := 2500
const MUESTREO := 0.1
const MAX_CELDAS := 6000   ## tope del relleno de `alcanzable_cercano`

## ¿Cabe una persona de ese radio en `p`? Cápsula contra la física del edificio (el jugador no cuenta como mueble). Es el `libre` del juego.
## `despeje` = a qué altura del suelo empieza el cuerpo (12 cm: un bordillo de 15 cm ya cuenta como obstáculo; en la calle, 35 cm).
static func libre_fisico(espacio: PhysicsDirectSpaceState3D, radio: float, despeje := 0.12) -> Callable:
	var cap := CapsuleShape3D.new()
	cap.radius = radio
	cap.height = 1.6
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = cap
	q.collide_with_bodies = true
	return func(p: Vector3) -> bool:
		q.transform = Transform3D(Basis.IDENTITY, p + Vector3(0, despeje + 0.8, 0))   ## el suelo no cuenta
		for r: Dictionary in espacio.intersect_shape(q, 4):
			if not (r["collider"] is CharacterBody3D):
				return false
		return true

## ¿Se puede ir en línea recta de `a` a `b`? (se prueba cada 10 cm)
static func tramo_libre(a: Vector3, b: Vector3, libre: Callable) -> bool:
	var pasos := maxi(int(a.distance_to(b) / MUESTREO), 1)
	for s in pasos + 1:
		if not libre.call(a.lerp(b, float(s) / pasos)):
			return false
	return true

## El punto libre más cercano a `p` (en espiral, hasta `alcance` m); `p` si ya está libre; `p` también si no hay ninguno.
static func libre_cercano(p: Vector3, libre: Callable, alcance := 1.5) -> Vector3:
	if libre.call(p):
		return p
	var r := PASO
	while r <= alcance:
		var n := maxi(int(TAU * r / PASO), 8)
		for k in n:
			var q := p + Vector3(cos(TAU * k / n), 0.0, sin(TAU * k / n)) * r
			if libre.call(q):
				return q
		r += PASO
	return p

## Camino de `a` a `b` rodeando lo que no esté libre; el tramo recto si ya está libre; [a, b] si no hay camino (no se inventa nada).
static func camino(a: Vector3, b: Vector3, libre: Callable) -> Array[Vector3]:
	var res: Array[Vector3] = [a, b]
	if tramo_libre(a, b, libre):
		return res
	var y := a.y
	var ini := Vector2i(roundi(a.x / PASO), roundi(a.z / PASO))
	var fin := Vector2i(roundi(b.x / PASO), roundi(b.z / PASO))
	var memo := {}
	var celda_libre := func(c: Vector2i) -> bool:
		if not memo.has(c):
			memo[c] = libre.call(Vector3(c.x * PASO, y, c.y * PASO))
		return memo[c]
	memo[ini] = true   ## de donde se sale y adonde se llega se dan por buenos (el punto exacto ya lo saneó `libre_cercano`)
	memo[fin] = true
	var g := {ini: 0.0}
	var de := {}
	var monton: Array = [[_h(ini, fin), ini]]   ## montículo binario por f = g + heurística
	var cerrada := {}
	var expandidos := 0
	while not monton.is_empty() and expandidos < MAX_NODOS:
		var c: Vector2i = _sacar(monton)
		if cerrada.has(c):
			continue
		if c == fin:
			break
		cerrada[c] = true
		expandidos += 1
		_expandir_vecinos(c, fin, celda_libre, g, de, monton, cerrada)
	if not de.has(fin):
		return res
	return _trazar(de, ini, fin, a, b, y, libre)

## Expande los vecinos libres de `c` (A*): los que mejoran su coste entran en el montículo.
static func _expandir_vecinos(c: Vector2i, fin: Vector2i, celda_libre: Callable, g: Dictionary,
		de: Dictionary, monton: Array, cerrada: Dictionary) -> void:
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			if dx == 0 and dz == 0:
				continue
			var v := Vector2i(c.x + dx, c.y + dz)
			if cerrada.has(v) or not celda_libre.call(v):
				continue
			if dx != 0 and dz != 0 and not (celda_libre.call(Vector2i(c.x + dx, c.y)) and celda_libre.call(Vector2i(c.x, c.y + dz))):
				continue   ## sin cortar esquinas
			var coste: float = float(g[c]) + (1.4142 if dx != 0 and dz != 0 else 1.0)
			if not g.has(v) or coste < float(g[v]):
				g[v] = coste
				de[v] = c
				_empujar(monton, coste + _h(v, fin), v)

## Reconstruye el trayecto de celdas de `ini` a `fin` (siguiendo `de`) y lo rodea con la cuerda.
static func _trazar(de: Dictionary, ini: Vector2i, fin: Vector2i, a: Vector3, b: Vector3,
		y: float, libre: Callable) -> Array[Vector3]:
	var celdas: Array[Vector2i] = [fin]
	while celdas[-1] != ini:
		celdas.append(de[celdas[-1]])
	celdas.reverse()
	var pts: Array[Vector3] = [a]
	for k in range(1, celdas.size() - 1):
		pts.append(Vector3(celdas[k].x * PASO, y, celdas[k].y * PASO))
	pts.append(b)
	return _tirar_de_la_cuerda(pts, libre)

## Distancia octil (en celdas) hasta la meta.
static func _h(c: Vector2i, fin: Vector2i) -> float:
	var dx := absf(float(c.x - fin.x))
	var dz := absf(float(c.y - fin.y))
	return dx + dz - 0.5858 * minf(dx, dz)

static func _empujar(h: Array, f: float, c: Vector2i) -> void:
	h.append([f, c])
	var i := h.size() - 1
	while i > 0:
		var p := (i - 1) >> 1
		if float(h[p][0]) <= float(h[i][0]):
			break
		var t: Array = h[p]
		h[p] = h[i]
		h[i] = t
		i = p

static func _sacar(h: Array) -> Vector2i:
	var cima: Array = h[0]
	var ultimo: Array = h.pop_back()
	if not h.is_empty():
		h[0] = ultimo
		var i := 0
		var n := h.size()
		while true:
			var l := 2 * i + 1
			var m := i
			if l < n and float(h[l][0]) < float(h[m][0]):
				m = l
			if l + 1 < n and float(h[l + 1][0]) < float(h[m][0]):
				m = l + 1
			if m == i:
				break
			var t: Array = h[m]
			h[m] = h[i]
			h[i] = t
			i = m
	return cima[1]

## El punto libre MÁS CERCANO a `p` desde el que se puede llegar andando a `destino` (relleno por rejilla desde `destino`, hasta `MAX_CELDAS`).
## Sirve para un puesto que quedó en un hueco cerrado (entre un coche y la pared): se le busca el sitio de al lado con salida. `p` si no hay.
static func alcanzable_cercano(p: Vector3, destino: Vector3, libre: Callable) -> Vector3:
	var y := destino.y
	var ini := Vector2i(roundi(destino.x / PASO), roundi(destino.z / PASO))
	var visto := {ini: true}
	var cola: Array[Vector2i] = [ini]
	var mejor := Vector3(INF, y, INF)
	var d_mejor := INF
	var k := 0
	while k < cola.size() and cola.size() < MAX_CELDAS:
		var c := cola[k]
		k += 1
		var pc := Vector3(c.x * PASO, y, c.y * PASO)
		var d := Vector2(pc.x - p.x, pc.z - p.z).length()
		if d < d_mejor:
			d_mejor = d
			mejor = pc
		for dv: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var v := c + dv
			if not visto.has(v):
				visto[v] = true
				if libre.call(Vector3(v.x * PASO, y, v.y * PASO)):
					cola.append(v)
	return mejor if d_mejor < INF else p

## Quita los puntos de en medio que no hacen falta: desde cada punto, al más lejano que se ve en línea recta.
static func _tirar_de_la_cuerda(pts: Array[Vector3], libre: Callable) -> Array[Vector3]:
	var sal: Array[Vector3] = [pts[0]]
	var i := 0
	while i < pts.size() - 1:
		var j := pts.size() - 1
		while j > i + 1 and not tramo_libre(pts[i], pts[j], libre):
			j -= 1
		sal.append(pts[j])
		i = j
	return sal

## La ruta del personal rehecha: puntos libres y cada tramo sin atravesar nada. Devuelve {"ruta": Array, "cambios": int, "sin_camino": int}.
static func sanear(ruta: Array, libre: Callable) -> Dictionary:
	var sal: Array = []
	var cambios := 0
	var sin_camino := 0
	for k in ruta.size():
		var p: Vector3 = ruta[k]
		var q := libre_cercano(p, libre)
		if not q.is_equal_approx(p):
			cambios += 1
		if sal.is_empty():
			sal.append(q)
			continue
		var tramo := camino(sal[-1], q, libre)
		if tramo.size() == 2 and not tramo_libre(sal[-1], q, libre):
			if sal.size() == 1:
				## El puesto (primer punto) está en un hueco cerrado: se le busca el sitio de al lado con salida.
				var nuevo := alcanzable_cercano(sal[0], q, libre)
				if not nuevo.is_equal_approx(sal[0]):
					sal[0] = nuevo
					cambios += 1
					tramo = camino(nuevo, q, libre)
			if tramo.size() == 2 and not tramo_libre(sal[-1], q, libre):
				sin_camino += 1
		if tramo.size() > 2:
			cambios += 1
		for t in range(1, tramo.size()):
			sal.append(tramo[t])
	return {"ruta": sal, "cambios": cambios, "sin_camino": sin_camino}
