class_name CiudadServicios
extends RefCounted
## BOMBEROS, COCHERAS Y DESGUACE CON VIDA (27-10-2026, relleno de la ciudad; P2-9 y P2-10 de la auditoría): los camiones en los portones,
## portones de verdad en la nave de las cocheras y el desguace con su valla, coches apilados y montones de neumáticos. Cada función se
## llama desde `CiudadExpansion._instalacion` con el centro `c` y el tamaño `w` × `f` de la manzana.
const COCHES := "res://assets/ciudad/kenney_cars/%s.glb"
const EXTRA := "res://assets/ciudad/kenney_cars_extra/%s.glb"

## Un modelo suelto. NO usa `CiudadExpansion._kit`: ese consume el azar de la ciudad (`_rng`) y movería todo lo que se genera después.
static func _coche(ex: CiudadExpansion, ruta: String, pos: Vector3, esc: float, giro: float, inclina := 0.0) -> void:
	var ps := load(ruta) as PackedScene
	if ps == null:
		return
	var n: Node3D = ps.instantiate()
	n.scale = Vector3.ONE * esc
	n.position = pos
	n.rotation = Vector3(0.0, giro, inclina)
	ex.b.add_child(n)

static func _valla(ex: CiudadExpansion, c: Vector3, w: float, f: float, con_sur := false) -> void:
	var b := ex.b
	var mat := b._mat_simple(Color(0.34, 0.36, 0.38), 0.6)
	b._caja_en(c + Vector3(0, 1.0, -f * 0.5 + 1.5), Vector3(w - 3.0, 2.0, 0.12), mat)
	for sx: float in [-1.0, 1.0]:
		b._caja_en(c + Vector3(sx * (w * 0.5 - 1.5), 1.0, 0), Vector3(0.12, 2.0, f - 3.0), mat)
	if con_sur:
		b._caja_en(c + Vector3(0, 1.0, f * 0.5 - 1.5), Vector3(w - 3.0, 2.0, 0.12), mat)

## Dos camiones y una ambulancia en el patio, de cara a los portones (que están al sur).
static func bomberos(ex: CiudadExpansion, c: Vector3, w: float, f: float) -> void:
	var z := f * 0.3 + 8.0
	_coche(ex, COCHES % "firetruck", c + Vector3(-w * 0.22, 0.2, z), 2.4, PI)
	_coche(ex, COCHES % "firetruck", c + Vector3(0.0, 0.2, z), 2.4, PI)
	_coche(ex, COCHES % "ambulance", c + Vector3(w * 0.22, 0.2, z), 2.2, PI)

## Cuatro portones con marco amarillo en la fachada sur de la nave y una valla de seguridad en los lados.
static func cocheras(ex: CiudadExpansion, c: Vector3, w: float, f: float) -> void:
	var b := ex.b
	var puerta := b._mat_simple(Color(0.14, 0.15, 0.17), 0.6)
	var marco := b._mat_simple(Color(0.95, 0.75, 0.15), 0.5)
	var zf := c.z + f * 0.1 + 0.1
	for k in 4:
		var x := c.x - w * 0.3 + float(k) * w * 0.2
		b._caja_en(Vector3(x, 3.6, zf), Vector3(w * 0.16, 7.2, 0.15), puerta)
		b._caja_en(Vector3(x, 7.35, zf + 0.05), Vector3(w * 0.17, 0.3, 0.2), marco)
		for sx: float in [-1.0, 1.0]:
			b._caja_en(Vector3(x + sx * w * 0.082, 3.6, zf + 0.05), Vector3(0.25, 7.2, 0.2), marco)
	_valla(ex, c, w, f)

## El patio del desguace: valla, coches siniestrados apilados y tumbados, y neumáticos.
static func desguace(ex: CiudadExpansion, c: Vector3, w: float, f: float) -> void:
	_valla(ex, c, w, f)
	var h := absi(hash(Vector2(c.x * 0.8, c.z * 1.3)))
	var tipos := ["sedan", "taxi", "van", "hatchback-sports", "suv", "police", "sedan-sports"]
	for fila in 3:
		for k in 4:
			var t: String = tipos[(h + fila * 4 + k) % tipos.size()]
			var p := c + Vector3(-w * 0.34 + float(k) * w * 0.17, 0.2, -f * 0.05 + float(fila) * f * 0.2)
			_coche(ex, COCHES % t, p, 2.4, float((h + k) % 4) * 0.4, 0.0)
			if (h + fila + k) % 3 == 0:
				_coche(ex, COCHES % tipos[(h + k + 2) % tipos.size()], p + Vector3(0, 2.6, 0), 2.4, 0.7, 0.18)
	for k in 8:
		var q := c + Vector3(w * 0.34 + float(k % 2) * 1.6, 0.2 + float(k / 4) * 1.0, -f * 0.3 + float((k / 2) % 2) * 2.4 + float(k / 4) * 0.4)
		_coche(ex, EXTRA % "debris-tire", q, 3.0, float(k) * 0.9)
