class_name RespaldoCurvo
extends RefCounted
## EL RESPALDO CURVO DE LA BUTACA CERCANA (27-10-2026, cola del líder). La butaca del modelo (`asientos_lod.glb`: tres asientos, 994
## vértices) llega con los respaldos planos. Aquí se deforma UNA vez la malla cargada: los vértices del respaldo (y > 0,45 y por detrás de
## z = −0,12; el asiento y los reposabrazos no se tocan) se adelantan hacia quien se sienta hasta 5 cm en los bordes de cada respaldo,
## con peso creciente con la altura: cóncavo, que abraza la espalda. Las normales se inclinan con la pendiente de la curva. Los asientos
## están centrados en x = −0,51, −0,05 y 0,42 (medido en el modelo: separadores a −0,75, −0,27, 0,17 y 0,65).
const CENTROS := [-0.51, -0.05, 0.42]
const MEDIO_ANCHO := 0.235
const FLECHA := 0.05
const Y_BASE := 0.45
const Y_TOPE := 0.75
const Z_MAX := -0.12

static var _cache: Dictionary = {}

static func curvar(malla: Mesh) -> Mesh:
	var id := malla.get_instance_id()
	if _cache.has(id):
		return _cache[id]
	var arr := malla.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	for i in v.size():
		var p := v[i]
		if p.y <= Y_BASE or p.z >= Z_MAX:
			continue
		var cx := 0.0
		var mejor := 9.0
		for c: float in CENTROS:
			if absf(p.x - c) < mejor:
				mejor = absf(p.x - c)
				cx = c
		var u := clampf((p.x - cx) / MEDIO_ANCHO, -1.0, 1.0)
		var peso := clampf((p.y - Y_BASE) / (Y_TOPE - Y_BASE), 0.0, 1.0)
		v[i].z += FLECHA * u * u * peso
		if nm.size() == v.size():
			var pendiente := 2.0 * FLECHA * u / MEDIO_ANCHO * peso
			nm[i] = Vector3(nm[i].x - pendiente * nm[i].z, nm[i].y, nm[i].z).normalized()
	arr[Mesh.ARRAY_VERTEX] = v
	if nm.size() == v.size():
		arr[Mesh.ARRAY_NORMAL] = nm
	var sal := ArrayMesh.new()
	sal.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	sal.surface_set_material(0, malla.surface_get_material(0))
	_cache[id] = sal
	return sal
