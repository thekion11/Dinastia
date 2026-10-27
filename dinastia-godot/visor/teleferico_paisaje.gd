class_name TelefericoPaisaje
extends RefCounted
## EL PAISAJE DEL CERRO (27-10-2026): lo que hace que la montaña no sea «un monte marrón liso»: un camino en zigzag por la ladera
## (de la estación de abajo al mirador), unos 500 pinos repartidos por las laderas (dos MultiMesh: copas y troncos), rocas sueltas
## en lo alto y las torres del cable en A con sus balancines. Todo se apoya en `CityBuilder.altura_en`, determinista (semilla fija).

const N_PINOS := 950
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
	var tramos: Array[Transform3D] = []
	var puntos: Array[Vector3] = []
	var pasos := int(largo / 12.0)
	for i in pasos + 1:
		var u := float(i) / float(pasos)
		var ola := absf(fposmod(u * float(ZIGZAGS) * 2.0, 2.0) - 1.0) * 2.0 - 1.0     ## triángulo −1..1 (zigzag)
		var xz := Vector2(base.x, base.z) + eje * largo * u + lat * ola * 75.0 * sin(u * PI)
		puntos.append(Vector3(xz.x, b.altura_en(xz.x, xz.y) + 0.3, xz.y))
	for i in puntos.size() - 1:
		var a := puntos[i]
		var c := puntos[i + 1]
		var d := c - a
		var bas := Basis.looking_at(d.normalized(), Vector3.UP)
		tramos.append(Transform3D(bas.scaled(Vector3(5.5, 0.3, d.length() + 1.5)), (a + c) * 0.5))
	var camino := StandardMaterial3D.new()
	camino.albedo_color = Color(0.66, 0.56, 0.4)
	camino.roughness = 1.0
	_multi(t, BoxMesh.new(), camino, tramos)
	## PINOS: cono oscuro sobre un tronco; no en el camino ni bajo el cable, y más ralos cuanto más alto.
	var copas: Array[Transform3D] = []
	var troncos: Array[Transform3D] = []
	var rocas: Array[Transform3D] = []
	var intentos := 0
	var centro := CityBuilder.MONTE_CENTRO
	while copas.size() < N_PINOS and intentos < 16000:
		intentos += 1
		var ang := rng.randf() * TAU
		var r := sqrt(rng.randf()) * 1300.0
		var x := centro.x + cos(ang) * r
		var z := centro.y + sin(ang) * r
		var p := Vector3(x, b.altura_en(x, z), z)
		var pend := absf(b.altura_en(x + 6.0, z) - b.altura_en(x - 6.0, z)) / 12.0
		if p.y < 6.0 or pend > 0.85 or _a_la_linea(p, base, cima) < 24.0 or Vector2(x, z).length() < 1500.0:
			continue
		if rng.randf() > clampf(1.3 - p.y / 400.0, 0.0, 1.0):
			continue
		var esc := rng.randf_range(0.8, 1.5)
		copas.append(Transform3D(Basis.from_scale(Vector3(4.6, 11.0, 4.6) * esc), p + Vector3(0, 5.5 * esc + 1.2, 0)))
		troncos.append(Transform3D(Basis.from_scale(Vector3(0.7, 2.6, 0.7) * esc), p + Vector3(0, 1.3 * esc, 0)))
	## ROCAS: bloques irregulares grises en las laderas altas.
	intentos = 0
	while rocas.size() < N_ROCAS and intentos < 6000:
		intentos += 1
		var ang2 := rng.randf() * TAU
		var r2 := sqrt(rng.randf()) * 900.0
		var x2 := centro.x + cos(ang2) * r2
		var z2 := centro.y + sin(ang2) * r2
		var p2 := Vector3(x2, b.altura_en(x2, z2), z2)
		if p2.y < 60.0 or _a_la_linea(p2, base, cima) < 14.0:
			continue
		var bas2 := Basis.from_euler(Vector3(rng.randf() * 0.6, rng.randf() * TAU, rng.randf() * 0.6)).scaled(Vector3(rng.randf_range(2.5, 7.0), rng.randf_range(1.5, 4.5), rng.randf_range(2.5, 6.0)))
		rocas.append(Transform3D(bas2, p2 + Vector3(0, 0.6, 0)))
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
	var verde := StandardMaterial3D.new()
	verde.albedo_color = Color(0.11, 0.3, 0.14)
	verde.roughness = 0.95
	var marron := StandardMaterial3D.new()
	marron.albedo_color = Color(0.3, 0.2, 0.12)
	var gris := StandardMaterial3D.new()
	gris.albedo_color = Color(0.47, 0.46, 0.44)
	gris.roughness = 0.95
	_multi(t, cono, verde, copas)
	_multi(t, tronco, marron, troncos)
	_multi(t, BoxMesh.new(), gris, rocas)
	t.set_meta("pinos", copas.size())
	t.set_meta("rocas", rocas.size())
	t.set_meta("camino", tramos.size())

## Una torre en A del cable: dos patas que convergen, tres travesaños y el balancín con las ruedas del cable (arriba en `p`).
static func torre(t: Node3D, b: CityBuilder, p: Vector3, giro: float, mat: Material) -> void:
	var suelo := b.altura_en(p.x, p.z)
	var alto := p.y - suelo
	var lado := Vector3(cos(giro), 0, -sin(giro))
	for s: float in [-1.0, 1.0]:
		var pie := Vector3(p.x, suelo - 1.0, p.z) + lado * s * 3.2
		var cabeza := Vector3(p.x, p.y, p.z) + lado * s * 0.7
		var d := cabeza - pie
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.7, d.length(), 0.7)
		mi.mesh = bm
		mi.material_override = mat
		mi.position = (pie + cabeza) * 0.5
		var eje := d.normalized()
		var x := eje.cross(Vector3.FORWARD)
		if x.length() < 0.01:
			x = eje.cross(Vector3.RIGHT)
		x = x.normalized()
		mi.basis = Basis(x, eje, x.cross(eje))
		t.add_child(mi)
	for k in 3:
		var f := 0.22 + float(k) * 0.24
		var y := suelo + alto * f
		var ancho := lerpf(6.2, 1.8, f) * 0.95
		var cb := MeshInstance3D.new()
		var bm2 := BoxMesh.new()
		bm2.size = Vector3(ancho, 0.35, 0.35)
		cb.mesh = bm2
		cb.material_override = mat
		cb.position = Vector3(p.x, y, p.z)
		cb.rotation.y = giro
		t.add_child(cb)
	var brazo := MeshInstance3D.new()
	var bm3 := BoxMesh.new()
	bm3.size = Vector3(7.4, 0.5, 0.6)
	brazo.mesh = bm3
	brazo.material_override = mat
	brazo.position = Vector3(p.x, p.y + 0.3, p.z)
	brazo.rotation.y = giro
	t.add_child(brazo)
