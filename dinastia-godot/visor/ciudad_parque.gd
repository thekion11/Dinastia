class_name CiudadParque
extends RefCounted
## EL PARQUE LLENO DE VIDA (27-10-2026, relleno de la ciudad, pedido del líder: «lo que más se vea a pie»). El parque tenía césped, paseos en cruz, parterres, columpios y tres
## puestos; los bancos eran tablas planas y no había dónde sentarse a comer ni papeleras. Ahora, a lo largo de los dos paseos (la franja de ±6 m donde no crecen árboles):
## bancos del kit (`muebles/bench`), mesas de pícnic con sillas y comida encima (`muebles/tableRound`, `chairRounded`, `comida`) y papeleras (`montana_rusa/trash`, CC0).
## No usa `_rng` (todo sale de la geometría): no mueve el azar de lo que viene después.
const BANCO := "res://assets/kenney/muebles/bench.glb"
const MESA := "res://assets/kenney/muebles/tableRound.glb"
const SILLA := "res://assets/kenney/muebles/chairRounded.glb"
const PAPELERA := "res://assets/kenney/montana_rusa/trash.glb"
const COMIDA := ["croissant", "cup-coffee", "cake", "donut-sprinkles", "bread", "cupcake"]
const SUELO := 0.2

static func rellenar(ex: CiudadExpansion, r: Rect2, c: Vector3) -> void:
	var largo := r.size.x * 0.5 - 4.0
	var ancho := r.size.y * 0.5 - 4.0
	var n := 0
	## Cuatro brazos de los paseos: eje (dx, dz), con el largo que le toca.
	for brazo: Array in [[1.0, 0.0, largo], [-1.0, 0.0, largo], [0.0, 1.0, ancho], [0.0, -1.0, ancho]]:
		var dir := Vector3(float(brazo[0]), 0.0, float(brazo[1]))
		var lado := Vector3(-dir.z, 0.0, dir.x)
		var maximo := float(brazo[2])
		var giro := atan2(dir.x, dir.z)
		for d: float in [15.0, 24.0, 33.0]:
			if d > maximo:
				continue
			var base := c + dir * d
			## Un banco a cada lado del paseo, de cara a él.
			for s: float in [-1.0, 1.0]:
				var q := base + lado * s * 3.1
				ex._pieza_kit(BANCO, Vector3(q.x, SUELO, q.z), ex._escala_ancho(BANCO, 1.6), giro + (PI * 0.5 if s > 0.0 else -PI * 0.5))
			## Cada dos paradas, una papelera junto al banco; y en la primera de cada brazo, una mesa de pícnic.
			if n % 2 == 0:
				var p := base + lado * 3.1 + dir * 1.4
				ex._pieza_kit(PAPELERA, Vector3(p.x, SUELO, p.z), ex._escala_ancho(PAPELERA, 0.7), 0.0)
			if d == 24.0:
				_picnic(ex, base - lado * 4.2, n)
			n += 1

## Una mesa redonda con cuatro sillas y dos platos encima.
static func _picnic(ex: CiudadExpansion, centro: Vector3, k: int) -> void:
	ex._pieza_kit(MESA, Vector3(centro.x, SUELO, centro.z), ex._escala_ancho(MESA, 1.6), 0.0)
	for i in 4:
		var ang := TAU * float(i) / 4.0 + 0.4
		var q := centro + Vector3(cos(ang), 0.0, sin(ang)) * 1.5
		ex._pieza_kit(SILLA, Vector3(q.x, SUELO, q.z), ex._escala_ancho(SILLA, 0.8), -ang - PI * 0.5)
	for j in 2:
		var plato: String = COMIDA[(k + j * 3) % COMIDA.size()]
		ex._pieza_kit("res://assets/kenney/comida/%s.glb" % plato, Vector3(centro.x + (-0.3 if j == 0 else 0.3), SUELO + 0.78, centro.z), 3.5, float(k * 90 + j * 140) * PI / 180.0)
