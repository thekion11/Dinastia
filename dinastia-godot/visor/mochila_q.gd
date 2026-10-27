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
const CAMINO := [Vector3(0.10, 0.10, -0.178), Vector3(0.11, 0.18, -0.141), Vector3(0.115, 0.245, -0.03), Vector3(0.115, 0.215, 0.062),
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
	var pts: Array[Vector3] = []
	for k in CAMINO.size() - 1:   ## Catmull-Rom: la correa es una curva suave, no un zigzag de tramos rectos
		var p0: Vector3 = CAMINO[maxi(k - 1, 0)]
		var p1: Vector3 = CAMINO[k]
		var p2: Vector3 = CAMINO[k + 1]
		var p3: Vector3 = CAMINO[mini(k + 2, CAMINO.size() - 1)]
		for j in 4:
			var t := j / 4.0
			pts.append(0.5 * (2.0 * p1 + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t + (3.0 * p1 - p0 - 3.0 * p2 + p3) * t * t * t))
	pts.append(CAMINO[CAMINO.size() - 1])
	for lado in [1.0, -1.0]:
		## Cinta continua: cara exterior, cara interior y dos cantos; 4 cm de ancho y 1 cm de grosor.
		var cs: Array[Array] = []
		for k in pts.size():
			var c := pts[k]
			c.x *= lado
			var t := (pts[mini(k + 1, pts.size() - 1)] - pts[maxi(k - 1, 0)])
			t.x *= lado
			t = t.normalized()
			var fuera := Vector3(c.x, 0.0, c.z).normalized()
			var lado_v := t.cross(fuera).normalized()
			var n := lado_v.cross(t).normalized()
			cs.append([c + n * 0.005 + lado_v * 0.02, c + n * 0.005 - lado_v * 0.02, c - n * 0.005 - lado_v * 0.02, c - n * 0.005 + lado_v * 0.02])
		for k in pts.size() - 1:
			for e in 4:   ## 0 exterior, 1 canto, 2 interior, 3 canto
				var e2 := (e + 1) % 4
				var a0: Vector3 = cs[k][e]
				var a1: Vector3 = cs[k][e2]
				var b0: Vector3 = cs[k + 1][e]
				var b1: Vector3 = cs[k + 1][e2]
				for v in [a0, a1, b1, a0, b1, b0]:
					st.add_vertex(v)
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
