class_name MochilaQ
extends RefCounted
## LA MOCHILA DE LOS PEATONES (27-10-2026, revisión del líder: «son cajas pegadas a la espalda»). Ahora: cuerpo de bordes redondeados
## (una caja subdividida cuyos vértices se empujan a un radio de 4,5 cm), bolsillo delantero redondeado, asa de la parte alta y DOS CORREAS
## que suben por la espalda, pasan por encima de cada hombro, bajan por el pecho y vuelven por debajo del brazo a la parte baja de la
## mochila, siguiendo el torso (medido en el hueso `spine_03` a x = 0,12: el hombro llega a y 0,29, el pecho a z 0,05 (y 0,24) … 0,12 (y 0,08), la espalda a −0,11 … −0,17; las correas van 1 cm por fuera de esa superficie). Todo en el
## espacio de ese hueso, en metros. Las mallas se construyen una vez y se comparten (3 mallas y 2 materiales por mochila).
const RADIO := 0.045

static var _cuerpo: ArrayMesh = null
static var _bolsillo: ArrayMesh = null
static var _correas: ArrayMesh = null

## Camino de una correa (x positivo = lado derecho del peatón; se refleja para el otro): por la espalda, sobre el hombro, por el pecho,
## se mete en el costado del torso (a la vista solo queda el tramo del hombro al pecho) y vuelve por la espalda al fondo de la mochila.
const CAMINO := [Vector3(0.10, 0.10, -0.178), Vector3(0.115, 0.20, -0.141), Vector3(0.12, 0.30, -0.03), Vector3(0.12, 0.25, 0.062),
	Vector3(0.12, 0.20, 0.091), Vector3(0.12, 0.12, 0.117), Vector3(0.12, 0.05, 0.134), Vector3(0.12, 0.0, 0.116), Vector3(0.12, -0.02, 0.0),
	Vector3(0.15, -0.04, -0.09), Vector3(0.13, -0.10, -0.16)]

## Caja de lados `t` con las esquinas y aristas redondeadas a `r`: se subdivide y cada vértice se lleva al punto más cercano de la caja
## interior (reducida en r) más r en la dirección de su normal.
static func caja_redonda(t: Vector3, r: float) -> ArrayMesh:
	var b := BoxMesh.new()
	b.size = t
	b.subdivide_width = 4
	b.subdivide_height = 4
	b.subdivide_depth = 4
	var arr := b.get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nm := PackedVector3Array()
	nm.resize(v.size())
	var h := t * 0.5 - Vector3.ONE * r
	for i in v.size():
		var p := v[i]
		var dentro := Vector3(clampf(p.x, -h.x, h.x), clampf(p.y, -h.y, h.y), clampf(p.z, -h.z, h.z))
		var n := (p - dentro).normalized()
		v[i] = dentro + n * r
		nm[i] = n
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = nm
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m

static func _malla_correas() -> ArrayMesh:
	if _correas != null:
		return _correas
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var caja := BoxMesh.new()
	caja.size = Vector3(0.04, 0.01, 1.0)   ## banda plana: 4 cm de ancho y 1 cm de grosor
	for lado in [1.0, -1.0]:
		for k in CAMINO.size() - 1:
			var a: Vector3 = CAMINO[k]
			var b: Vector3 = CAMINO[k + 1]
			a.x *= lado
			b.x *= lado
			var largo := a.distance_to(b)
			var dir := (b - a) / largo
			## El grosor mira hacia fuera del torso (desde su eje vertical).
			var medio := (a + b) * 0.5
			var fuera := Vector3(medio.x, 0.0, medio.z).normalized()
			var z := dir
			var x := fuera.cross(z).normalized()
			var y := z.cross(x).normalized()
			var base := Basis(x, y, z * 1.0).scaled_local(Vector3(1, 1, largo + 0.012))
			st.append_from(caja, 0, Transform3D(base, medio))
	st.generate_normals()
	_correas = st.commit()
	return _correas

## Cuelga la mochila del espacio del hueso `h` (en metros) con el color `col`.
static func poner(h: Node3D, col: Color) -> void:
	if _cuerpo == null:
		_cuerpo = caja_redonda(Vector3(0.28, 0.36, 0.15), RADIO)
		_bolsillo = caja_redonda(Vector3(0.20, 0.15, 0.07), 0.025)
	PeatonQ._pieza(h, _cuerpo, PeatonQ._m(col, 0.75), Vector3(0, -0.03, -0.19))
	PeatonQ._pieza(h, _bolsillo, PeatonQ._m(col.darkened(0.2), 0.75), Vector3(0, -0.10, -0.275))
	## El asa de arriba: un arco pequeño.
	var asa := TorusMesh.new()
	asa.inner_radius = 0.022
	asa.outer_radius = 0.03
	asa.rings = 10
	asa.ring_segments = 6
	PeatonQ._pieza(h, asa, PeatonQ._m(col.darkened(0.35), 0.6), Vector3(0, 0.155, -0.19), Vector3(90, 0, 0)).scale = Vector3(1.4, 1.4, 0.5)
	PeatonQ._pieza(h, _malla_correas(), PeatonQ._m(col.darkened(0.12), 0.7), Vector3.ZERO)
