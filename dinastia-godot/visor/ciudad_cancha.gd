class_name CiudadCancha
extends RefCounted
## LA CANCHA DE PENALES Y LOS PATOS DEL LAGO (27-10-2026, relleno de la ciudad). En un cuadrante libre de cada parque: una
## cancha de 16 × 9 m con sus rayas, las dos áreas, los puntos de penal, una portería a cada lado con red y un balón en
## el punto; y en el lago, patos de primitivas en pequeñas bandadas. Sin `_rng`: todo sale de la posición del parque.
const LARGO := 16.0
const ANCHO := 9.0

## Centro de la cancha: el cuadrante que no ocupan los juegos infantiles ni el lago.
static func centro(r: Rect2, c: Vector3, lago: bool) -> Vector3:
	return c + Vector3(-r.size.x * 0.27, 0.0, (-1.0 if lago else 1.0) * r.size.y * 0.27)

## ¿Cae `p` dentro de la cancha (con margen para que no crezcan árboles)?
static func ocupa(cc: Vector3, p: Vector3) -> bool:
	return absf(p.x - cc.x) < LARGO * 0.5 + 2.0 and absf(p.z - cc.z) < ANCHO * 0.5 + 2.0

static func montar(ex: CiudadExpansion, cc: Vector3) -> void:
	var b: Node3D = ex.b
	var cesped := ex.b._mat_simple(Color(0.36, 0.62, 0.28), 0.95)
	var raya := ex.b._mat_simple(Color(0.96, 0.96, 0.94), 0.7)
	var palo := ex.b._mat_simple(Color(0.95, 0.95, 0.95), 0.35)
	ex.b._caja_en(cc + Vector3(0, 0.115, 0), Vector3(LARGO, 0.03, ANCHO), cesped)
	var y := 0.14
	for s: float in [-1.0, 1.0]:
		ex.b._caja_en(cc + Vector3(0, y, s * ANCHO * 0.5), Vector3(LARGO, 0.02, 0.12), raya)
		ex.b._caja_en(cc + Vector3(s * LARGO * 0.5, y, 0), Vector3(0.12, 0.02, ANCHO), raya)
		## El área: 3 m de fondo, 5 m de ancho, y el punto de penal a 6 m de la línea.
		var xl := s * LARGO * 0.5
		ex.b._caja_en(cc + Vector3(xl - s * 3.0, y, 0), Vector3(0.1, 0.02, 5.0), raya)
		for z: float in [-2.5, 2.5]:
			ex.b._caja_en(cc + Vector3(xl - s * 1.5, y, z), Vector3(3.0, 0.02, 0.1), raya)
		var punto := ex.b._caja_en(cc + Vector3(xl - s * 6.0, y, 0), Vector3(0.3, 0.02, 0.3), raya)
		punto.rotation.y = PI * 0.25
		_porteria(ex, cc + Vector3(xl, 0.1, 0), s, palo)
	ex.b._caja_en(cc + Vector3(0, y, 0), Vector3(0.1, 0.02, ANCHO), raya)
	var balon := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.22
	sm.height = 0.44
	balon.mesh = sm
	balon.material_override = ex.b._mat_simple(Color(0.97, 0.97, 0.97), 0.5)
	balon.position = cc + Vector3(LARGO * 0.5 - 6.0, 0.34, 0)
	b.add_child(balon)

## Portería de 3 × 2 m con los palos hacia el campo (`s`: lado en X) y red por detrás.
static func _porteria(ex: CiudadExpansion, base: Vector3, s: float, palo: Material) -> void:
	var red := StandardMaterial3D.new()
	red.albedo_color = Color(1, 1, 1, 0.22)
	red.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	red.cull_mode = BaseMaterial3D.CULL_DISABLED
	var fondo := 1.1
	for z: float in [-1.5, 1.5]:
		ex.b._caja_en(base + Vector3(0, 1.0, z), Vector3(0.1, 2.0, 0.1), palo)
		ex.b._caja_en(base + Vector3(s * fondo, 0.9, z), Vector3(0.05, 1.8, 0.05), palo)
		ex.b._caja_en(base + Vector3(s * fondo * 0.5, 1.95, z), Vector3(fondo, 0.05, 0.05), palo)
	ex.b._caja_en(base + Vector3(0, 2.0, 0), Vector3(0.1, 0.1, 3.1), palo)
	ex.b._caja_en(base + Vector3(s * fondo, 0.95, 0), Vector3(0.02, 1.9, 3.0), red)
	ex.b._caja_en(base + Vector3(s * fondo * 0.5, 1.98, 0), Vector3(fondo, 0.02, 3.0), red)
	for z: float in [-1.5, 1.5]:
		ex.b._caja_en(base + Vector3(s * fondo * 0.5, 0.95, z), Vector3(fondo, 1.9, 0.02), red)

## Patos en el lago: cuatro bandadas de 1-3 patos, repartidas por la hash del centro.
static func patos(ex: CiudadExpansion, lago_c: Vector3, radio: float) -> void:
	var cuerpo := ex.b._mat_simple(Color(0.93, 0.9, 0.82), 0.8)
	var oscuro := ex.b._mat_simple(Color(0.45, 0.33, 0.2), 0.8)
	var verde := ex.b._mat_simple(Color(0.12, 0.45, 0.25), 0.6)
	var pico := ex.b._mat_simple(Color(0.95, 0.65, 0.1), 0.6)
	var h := absi(hash(Vector2(lago_c.x, lago_c.z)))
	var n := 0
	for g in 4:
		var ang := TAU * (float(g) + float((h >> g) % 7) / 7.0) / 4.0
		var dist := radio * (0.35 + 0.12 * float((h >> (g + 3)) % 4))
		var centro := lago_c + Vector3(cos(ang) * dist * 1.3, 0.0, sin(ang) * dist)
		for k in 1 + (h >> (g * 2)) % 3:
			var q := centro + Vector3(float(k) * 0.9 - 0.4, 0.0, float(k % 2) * 0.7)
			_pato(ex, q, float(n) * 1.9 + ang, cuerpo if n % 3 != 0 else oscuro, verde, pico)
			n += 1

static func _pato(ex: CiudadExpansion, p: Vector3, giro: float, cuerpo: Material, cabeza: Material, pico: Material) -> void:
	var raiz := Node3D.new()
	raiz.position = Vector3(p.x, 0.17, p.z)
	raiz.rotation.y = giro
	ex.b.add_child(raiz)
	var cu := MeshInstance3D.new()
	var s1 := SphereMesh.new()
	s1.radius = 0.2
	s1.height = 0.4
	cu.mesh = s1
	cu.material_override = cuerpo
	cu.scale = Vector3(1.0, 0.7, 1.5)
	raiz.add_child(cu)
	var cb := MeshInstance3D.new()
	var s2 := SphereMesh.new()
	s2.radius = 0.1
	s2.height = 0.2
	cb.mesh = s2
	cb.material_override = cabeza
	cb.position = Vector3(0, 0.22, 0.26)
	raiz.add_child(cb)
	var pi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.08, 0.03, 0.12)
	pi.mesh = bm
	pi.material_override = pico
	pi.position = Vector3(0, 0.2, 0.38)
	raiz.add_child(pi)
