class_name TelefericoFlora
extends RefCounted
## LA FLORA Y LAS ROCAS DEL CERRO (27-10-2026, el dueño: «las placas cartón flotando parecen rotas; la ladera es marrón plana»): rocas
## de verdad (mallas facetadas generadas con ruido, tres formas y tamaños de 1 a 7 m, en grupos sobre las pendientes), matorral
## (esferas achatadas en olivas y verdes), árboles de hoja caduca en las laderas bajas y un camino en cinta que SIGUE el terreno
## (antes eran placas planas que flotaban sobre la ladera). Todo con MultiMesh y semilla fija; `CityBuilder.altura_en` pone cada
## pieza en el suelo.

const N_ARBUSTOS := 2400
const N_CADUCOS := 420
const N_GRUPOS_ROCA := 150

## Una roca facetada: esfera de pocos polígonos con los vértices desplazados por ruido y normales planas (cada cara se ve).
static func malla_roca(semilla: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var esf := SphereMesh.new()
	esf.radial_segments = 8
	esf.rings = 5
	esf.radius = 0.5
	esf.height = 1.0
	var arr := esf.get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var salida := PackedVector3Array()
	var memo := {}
	for p: Vector3 in v:
		var k := Vector3i(roundi(p.x * 100.0), roundi(p.y * 100.0), roundi(p.z * 100.0))
		if not memo.has(k):
			memo[k] = p * (1.0 + rng.randf_range(-0.32, 0.30)) * Vector3(1.0, rng.randf_range(0.6, 0.85), 1.0)
		salida.append(memo[k])
	arr[Mesh.ARRAY_VERTEX] = salida
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var st := SurfaceTool.new()
	st.create_from(m, 0)
	st.deindex()
	st.generate_normals()
	return st.commit()

static func _multi(t: Node3D, malla: Mesh, mat: Material, ts: Array[Transform3D], cols: Array[Color] = []) -> void:
	if ts.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not cols.is_empty()
	mm.mesh = malla
	mm.instance_count = ts.size()
	for i in ts.size():
		mm.set_instance_transform(i, ts[i])
		if not cols.is_empty():
			mm.set_instance_color(i, cols[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = mat
	t.add_child(mi)

static func _mat_color(rug: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.roughness = rug
	return m

## Altura del terreno TAL COMO LO DIBUJA LA MALLA (triángulos entre vértices de la rejilla), no la función continua: en las curvas
## de la ladera la malla queda por encima o por debajo de la función y lo que se apoya con `altura_en` se hunde o flota.
static func altura_malla(b: CityBuilder, x: float, z: float) -> float:
	var paso := CityBuilder.TERRENO_LADO / float(CityBuilder.TERRENO_CELDAS)
	var mitad := CityBuilder.TERRENO_LADO * 0.5
	var fx := (x + mitad) / paso
	var fz := (z + mitad) / paso
	var i := floorf(fx)
	var j := floorf(fz)
	var u := fx - i
	var v := fz - j
	var x0 := -mitad + i * paso
	var z0 := -mitad + j * paso
	var h00 := b.altura_en(x0, z0)
	var h10 := b.altura_en(x0 + paso, z0)
	var h01 := b.altura_en(x0, z0 + paso)
	if u + v <= 1.0:
		return h00 + (h10 - h00) * u + (h01 - h00) * v
	var h11 := b.altura_en(x0 + paso, z0 + paso)
	return h11 + (h01 - h11) * (1.0 - u) + (h10 - h11) * (1.0 - v)

static func _pendiente(b: CityBuilder, x: float, z: float) -> float:
	return absf(b.altura_en(x + 5.0, z) - b.altura_en(x - 5.0, z)) / 10.0 + absf(b.altura_en(x, z + 5.0) - b.altura_en(x, z - 5.0)) / 10.0

## Rocas, matorral y árboles de hoja caduca. `lejos(p)`: ¿está `p` en el camino o bajo el cable? (se deja libre).
static func montar(t: Node3D, b: CityBuilder, base: Vector3, cima: Vector3, rng: RandomNumberGenerator) -> void:
	var centro := CityBuilder.MONTE_CENTRO
	## ROCAS: tres mallas, en grupos de 2-6 de distintos tamaños, sobre las pendientes fuertes (donde el terreno es roca).
	var mallas: Array[ArrayMesh] = [malla_roca(11), malla_roca(23), malla_roca(37)]
	var por_malla: Array = [[], [], []]
	var col_malla: Array = [[], [], []]
	var n_rocas := 0
	var intentos := 0
	var grupos := 0
	while grupos < N_GRUPOS_ROCA and intentos < 8000:
		intentos += 1
		var ang := rng.randf() * TAU
		var r := sqrt(rng.randf()) * 950.0
		var x := centro.x + cos(ang) * r
		var z := centro.y + sin(ang) * r
		var h := b.altura_en(x, z)
		if h < 25.0 or TelefericoPaisaje._a_la_linea(Vector3(x, h, z), base, cima) < 16.0:
			continue
		if _pendiente(b, x, z) < 0.38 and rng.randf() > 0.15:
			continue
		grupos += 1
		for k in rng.randi_range(2, 6):
			var px := x + rng.randf_range(-9.0, 9.0)
			var pz := z + rng.randf_range(-9.0, 9.0)
			var esc := rng.randf_range(1.0, 3.2) * (rng.randf_range(1.5, 2.2) if rng.randf() < 0.12 else 1.0)
			var bas := Basis.from_euler(Vector3(rng.randf_range(-0.3, 0.3), rng.randf() * TAU, rng.randf_range(-0.3, 0.3))).scaled(Vector3(esc, esc * rng.randf_range(0.8, 1.2), esc * rng.randf_range(0.8, 1.3)))
			var v := rng.randi() % 3
			(por_malla[v] as Array).append(Transform3D(bas, Vector3(px, altura_malla(b, px, pz) + esc * 0.12, pz)))
			var g := rng.randf_range(0.42, 0.62)
			(col_malla[v] as Array).append(Color(g * 1.03, g, g * 0.94))
			n_rocas += 1
	var mat_roca := _mat_color(0.95)
	for i in 3:
		var ts: Array[Transform3D] = []
		ts.assign(por_malla[i])
		var cs: Array[Color] = []
		cs.assign(col_malla[i])
		_multi(t, mallas[i], mat_roca, ts, cs)
	## MATORRAL: esferas achatadas en tres tonos.
	var bola := SphereMesh.new()
	bola.radial_segments = 7
	bola.rings = 4
	bola.radius = 0.5
	bola.height = 0.8
	var ar_t: Array[Transform3D] = []
	var ar_c: Array[Color] = []
	intentos = 0
	while ar_t.size() < N_ARBUSTOS and intentos < 14000:
		intentos += 1
		var a2 := rng.randf() * TAU
		var r2 := sqrt(rng.randf()) * 1150.0
		var x2 := centro.x + cos(a2) * r2
		var z2 := centro.y + sin(a2) * r2
		var h2 := altura_malla(b, x2, z2)
		if h2 < 4.0 or _pendiente(b, x2, z2) > 0.7 or TelefericoPaisaje._a_la_linea(Vector3(x2, h2, z2), base, cima) < 10.0:
			continue
		if rng.randf() > clampf(1.2 - h2 / 330.0, 0.05, 1.0):
			continue
		var e := rng.randf_range(1.0, 2.6)
		ar_t.append(Transform3D(Basis.from_euler(Vector3(0, rng.randf() * TAU, 0)).scaled(Vector3(e * 1.3, e * rng.randf_range(0.7, 1.1), e * 1.1)), Vector3(x2, h2 + e * 0.25, z2)))
		var tono := rng.randf()
		ar_c.append(Color(0.2, 0.36, 0.16).lerp(Color(0.45, 0.5, 0.2), tono) if tono < 0.7 else Color(0.5, 0.36, 0.14))
	_multi(t, bola, _mat_color(0.95), ar_t, ar_c)
	## ÁRBOLES DE HOJA CADUCA en la falda (por debajo de 170 m): tronco y copa redonda, en verdes y amarillos de otoño.
	var tronco := CylinderMesh.new()
	tronco.top_radius = 0.35
	tronco.bottom_radius = 0.5
	tronco.height = 1.0
	tronco.radial_segments = 5
	tronco.rings = 0
	var copa := SphereMesh.new()
	copa.radial_segments = 8
	copa.rings = 5
	copa.radius = 0.5
	copa.height = 1.0
	var tr_t: Array[Transform3D] = []
	var cp_t: Array[Transform3D] = []
	var cp_c: Array[Color] = []
	intentos = 0
	while cp_t.size() < N_CADUCOS and intentos < 9000:
		intentos += 1
		var a3 := rng.randf() * TAU
		var r3 := sqrt(rng.randf()) * 1100.0
		var x3 := centro.x + cos(a3) * r3
		var z3 := centro.y + sin(a3) * r3
		var h3 := altura_malla(b, x3, z3)
		if h3 < 5.0 or h3 > 170.0 or _pendiente(b, x3, z3) > 0.5 or TelefericoPaisaje._a_la_linea(Vector3(x3, h3, z3), base, cima) < 20.0:
			continue
		var e3 := rng.randf_range(0.9, 1.5)
		tr_t.append(Transform3D(Basis.from_scale(Vector3(0.9, 3.6, 0.9) * e3), Vector3(x3, h3 + 1.8 * e3, z3)))
		cp_t.append(Transform3D(Basis.from_euler(Vector3(0, rng.randf() * TAU, 0)).scaled(Vector3(6.4, 6.0, 6.4) * e3), Vector3(x3, h3 + 6.2 * e3, z3)))
		var q := rng.randf()
		cp_c.append(Color(0.2, 0.42, 0.14).lerp(Color(0.62, 0.55, 0.14), q) if q < 0.9 else Color(0.62, 0.4, 0.12))
	var marron := StandardMaterial3D.new()
	marron.albedo_color = Color(0.3, 0.2, 0.12)
	_multi(t, tronco, marron, tr_t)
	_multi(t, copa, _mat_color(0.9), cp_t, cp_c)
	t.set_meta("rocas", n_rocas)
	t.set_meta("arbustos", ar_t.size())
	t.set_meta("caducos", cp_t.size())

## El camino en zigzag como una CINTA que sigue el terreno (5 m de ancho): una tira de triángulos con cada vértice a la altura
## del suelo en ese punto. `puntos`: la poligonal en planta (y se ignora).
static func cinta_camino(t: Node3D, b: CityBuilder, puntos: Array[Vector3], ancho: float) -> int:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var muestras: Array[Vector3] = []
	var dirs: Array[Vector3] = []
	for i in puntos.size() - 1:
		var a := Vector3(puntos[i].x, 0, puntos[i].z)
		var c := Vector3(puntos[i + 1].x, 0, puntos[i + 1].z)
		var n := maxi(1, int(a.distance_to(c) / 4.0))
		for k in n:
			muestras.append(a.lerp(c, float(k) / float(n)))
			dirs.append((c - a).normalized())
	muestras.append(Vector3(puntos[puntos.size() - 1].x, 0, puntos[puntos.size() - 1].z))
	dirs.append(dirs[dirs.size() - 1])
	var izq: Array[Vector3] = []
	var der: Array[Vector3] = []
	for i in muestras.size():
		var lado := Vector3(-dirs[i].z, 0, dirs[i].x) * ancho * 0.5
		var pi_ := muestras[i] + lado
		var pd := muestras[i] - lado
		izq.append(Vector3(pi_.x, altura_malla(b, pi_.x, pi_.z) + 0.15, pi_.z))
		der.append(Vector3(pd.x, altura_malla(b, pd.x, pd.z) + 0.15, pd.z))
	for i in muestras.size() - 1:
		for p: Vector3 in [izq[i], der[i], izq[i + 1], der[i], der[i + 1], izq[i + 1]]:
			st.set_normal(Vector3.UP)
			st.add_vertex(p)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.5, 0.41, 0.29)
	m.roughness = 1.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	t.add_child(mi)
	return muestras.size() - 1
