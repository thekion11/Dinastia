class_name TelefericoPaisaje
extends RefCounted
## EL PAISAJE DEL CERRO (27-10-2026): lo que hace que la montaña no sea «un monte marrón liso»: un camino en zigzag por la ladera
## (de la estación de abajo al mirador), unos 500 pinos repartidos por las laderas (dos MultiMesh: copas y troncos), rocas sueltas
## en lo alto y las torres del cable en A con sus balancines. Todo se apoya en `CityBuilder.altura_en`, determinista (semilla fija).

const N_PINOS := 1700
const N_ROCAS := 140
const ZIGZAGS := 7

static func _multi(t: Node3D, malla: Mesh, mat: Material, ts: Array[Transform3D]) -> void:
	if ts.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = malla
	mm.instance_count = ts.size()
	for i in ts.size():
		mm.set_instance_transform(i, ts[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = mat
	t.add_child(mi)

## Distancia en planta de `p` al segmento a-b.
static func _a_la_linea(p: Vector3, a: Vector3, b: Vector3) -> float:
	var q := Geometry3D.get_closest_point_to_segment(Vector3(p.x, 0, p.z), Vector3(a.x, 0, a.z), Vector3(b.x, 0, b.z))
	return Vector2(p.x - q.x, p.z - q.z).length()

static func montar(t: Node3D, b: CityBuilder, base: Vector3, cima: Vector3) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4201027
	## EL CAMINO EN ZIGZAG: tramos de 12 m a ras de suelo que van de lado a lado de la línea del cable.
	var dir := Vector2(cima.x - base.x, cima.z - base.z)
	var largo := dir.length()
	var eje := dir / largo
	var lat := Vector2(-eje.y, eje.x)
	var puntos: Array[Vector3] = []
	var pasos := int(largo / 12.0)
	for i in pasos + 1:
		var u := float(i) / float(pasos)
		var ola := absf(fposmod(u * float(ZIGZAGS) * 2.0, 2.0) - 1.0) * 2.0 - 1.0     ## triángulo −1..1 (zigzag)
		var xz := Vector2(base.x, base.z) + eje * largo * u + lat * ola * 75.0 * sin(u * PI)
		puntos.append(Vector3(xz.x, 0.0, xz.y))
	var n_camino := TelefericoFlora.cinta_camino(t, b, puntos, 3.6)    ## una cinta que sigue el terreno (antes, placas planas que flotaban)
	## PINOS: cono oscuro sobre un tronco; no en el camino ni bajo el cable, y más ralos cuanto más alto.
	var copas: Array[Transform3D] = []
	var troncos: Array[Transform3D] = []
	var colores: Array[Color] = []
	var intentos := 0
	var centro := CityBuilder.MONTE_CENTRO
	while copas.size() < N_PINOS and intentos < 16000:
		intentos += 1
		var ang := rng.randf() * TAU
		var r := sqrt(rng.randf()) * 1300.0
		var x := centro.x + cos(ang) * r
		var z := centro.y + sin(ang) * r
		var p := Vector3(x, TelefericoFlora.altura_malla(b, x, z), z)
		var pend := absf(b.altura_en(x + 6.0, z) - b.altura_en(x - 6.0, z)) / 12.0
		if p.y < 6.0 or pend > 0.85 or _a_la_linea(p, base, cima) < 24.0 or Vector2(x, z).length() < 1500.0:
			continue
		if rng.randf() > clampf(1.3 - p.y / 400.0, 0.0, 1.0):
			continue
		var esc := rng.randf_range(0.8, 1.5)
		copas.append(Transform3D(Basis.from_scale(Vector3(4.6, 11.0, 4.6) * esc), p + Vector3(0, 5.5 * esc + 1.2, 0)))
		troncos.append(Transform3D(Basis.from_scale(Vector3(0.7, 2.6, 0.7) * esc), p + Vector3(0, 1.3 * esc, 0)))
		var tono := rng.randf()
		colores.append(Color(0.08, 0.26, 0.12).lerp(Color(0.18, 0.38, 0.14), tono))
	var cono := CylinderMesh.new()
	cono.top_radius = 0.0
	cono.bottom_radius = 0.5
	cono.height = 1.0
	cono.radial_segments = 7
	cono.rings = 0
	var tronco := CylinderMesh.new()
	tronco.top_radius = 0.5
	tronco.bottom_radius = 0.5
	tronco.height = 1.0
	tronco.radial_segments = 5
	tronco.rings = 0
	var marron := StandardMaterial3D.new()
	marron.albedo_color = Color(0.3, 0.2, 0.12)
	TelefericoFlora._multi(t, cono, TelefericoFlora._mat_color(0.95), copas, colores)
	_multi(t, tronco, marron, troncos)
	TelefericoFlora.montar(t, b, base, cima, rng)
	t.set_meta("pinos", copas.size())
	t.set_meta("camino", n_camino)
