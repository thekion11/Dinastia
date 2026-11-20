class_name AcabadoAjeno
## ACABADO DE LOS AVATARES CIVILES ELEGIBLES (19-11, «realismo de los personajes seleccionables del jugador»). Los modelos
## modulares (`FutbolistaQ.MODULARES_H/M`) traen materiales de METAL (metálico 0,40, rugosidad 0,27: brillos blancos y reflejos
## en cuadritos, como plástico) y normales PLANAS (cada triángulo con sus vértices: aspecto facetado). Al cargarlos:
##   - normales suavizadas entre triángulos que comparten vértice y forman menos de `ANGULO_DURO` (cuellos, suelas y
##     bordes de prenda de más de 60° quedan marcados); la malla lisa se guarda una vez por malla original;
##   - materiales mates por tipo (piel, ojo, pelo, cejas, tela), sin metálico;
##   - la PIEL toma el tono elegido en el creador (antes se ignoraba) con el mismo albedo físico que el resto del juego
##     (`VestidorQ.albedo_piel`).
const ANGULO_DURO := 60.0
## Pelos naturales para variar al personal (castaño, negro, castaño claro, rubio, canoso, castaño rojizo, castaño oscuro, rubio oscuro, gris).
const PELOS_NATURALES: Array[Color] = [Color(0.17, 0.11, 0.07), Color(0.04, 0.035, 0.03), Color(0.36, 0.22, 0.11), Color(0.62, 0.48, 0.24),
	Color(0.55, 0.55, 0.54), Color(0.38, 0.14, 0.07), Color(0.10, 0.07, 0.05), Color(0.30, 0.22, 0.12), Color(0.42, 0.40, 0.38)]
static var _lisas := {}   ## id de la malla original → ArrayMesh lisa
static var _mats := {}    ## clave → StandardMaterial3D

## `pelo` (opcional, alfa > 0): color del pelo; `variante` (opcional, > 0): da otro color a la ropa del mismo modelo (matiz y claridad según la
## variante), para que dos del personal con el mismo civil no se vean iguales (20-11: solo hay 7 modelos de hombre para 12 puestos).
static func aplicar(modelo: Node, piel := Color(0, 0, 0, 0), pelo := Color(0, 0, 0, 0), variante := 0) -> void:
	for n in modelo.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var m := mi.mesh as ArrayMesh
		if m == null:
			continue
		var lisa := _lisa(m)
		mi.mesh = lisa
		for s in lisa.get_surface_count():
			var mat := lisa.surface_get_material(s) as StandardMaterial3D
			if mat != null:
				mi.set_surface_override_material(s, _material(mat, piel, pelo, variante))

## La malla con normales suaves (o la misma si trae formas de mezcla, que no se rehacen aquí).
static func _lisa(m: ArrayMesh) -> ArrayMesh:
	var id := m.get_instance_id()
	if _lisas.has(id):
		return _lisas[id]
	if m.get_blend_shape_count() > 0:
		_lisas[id] = m
		return m
	var nueva := ArrayMesh.new()
	nueva.resource_name = m.resource_name
	for s in m.get_surface_count():
		var arr := m.surface_get_arrays(s)
		if arr[Mesh.ARRAY_NORMAL] != null and m.surface_get_primitive_type(s) == Mesh.PRIMITIVE_TRIANGLES:
			arr[Mesh.ARRAY_NORMAL] = suavizar(arr[Mesh.ARRAY_VERTEX], arr[Mesh.ARRAY_NORMAL])
			arr[Mesh.ARRAY_TANGENT] = null
		nueva.add_surface_from_arrays(m.surface_get_primitive_type(s), arr, [], {},
			m.surface_get_format(s) & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS)
		nueva.surface_set_material(s, m.surface_get_material(s))
		nueva.surface_set_name(s, m.surface_get_name(s))
	_lisas[id] = nueva
	return nueva

## Cada vértice toma la media de las normales de los vértices en su MISMA posición que no se aparten más de `ANGULO_DURO`.
static func suavizar(v: PackedVector3Array, n: PackedVector3Array) -> PackedVector3Array:
	## Rejilla relativa al tamaño (estas mallas vienen en unidades diminutas, ~0,02, y el nodo las escala ×100).
	var caja := AABB(v[0] if v.size() > 0 else Vector3.ZERO, Vector3.ZERO)
	for p in v:
		caja = caja.expand(p)
	var escala := 200000.0 / maxf(caja.get_longest_axis_size(), 1e-6)
	var grupos := {}
	for i in v.size():
		var k := Vector3i((v[i] * escala).round())
		if grupos.has(k):
			(grupos[k] as Array).append(i)   ## Array (por referencia): un PackedInt32Array se copiaría y perdería el append
		else:
			grupos[k] = [i]
	var umbral := cos(deg_to_rad(ANGULO_DURO))
	var sal := n.duplicate()
	for k in grupos:
		var g: Array = grupos[k]
		if g.size() < 2:
			continue
		for i in g:
			var suma := Vector3.ZERO
			for j in g:
				if n[i].dot(n[j]) >= umbral:
					suma += n[j]
			if suma.length_squared() > 1e-8:
				sal[i] = suma.normalized()
	return sal

static func _material(orig: StandardMaterial3D, piel: Color, pelo := Color(0, 0, 0, 0), variante := 0) -> StandardMaterial3D:
	var nom := orig.resource_name.to_lower()
	var es_piel := nom.contains("skin")
	var es_pelo := nom.contains("hair") and not nom.contains("eyebrow")
	## Los blancos (camisa, suela) y la ropa de seguridad (casco amarillo, chaleco naranja) se quedan como están.
	var es_ropa := not (es_piel or es_pelo or nom.contains("eye") or nom.contains("white") or nom.contains("yellow") or nom.contains("orange"))
	var clave := "%d|%s|%s|%d" % [orig.get_instance_id(), piel.to_html() if es_piel else "", pelo.to_html() if es_pelo and pelo.a > 0.0 else "",
		variante if (es_ropa or es_pelo) else 0]
	if _mats.has(clave):
		return _mats[clave]
	var m := orig.duplicate() as StandardMaterial3D
	m.metallic = 0.0
	m.metallic_specular = 0.35
	m.roughness = 0.82
	if es_piel:
		var base := piel if piel.a > 0.0 else orig.albedo_color
		var lin := base.srgb_to_linear()
		var k := VestidorQ.albedo_piel(0.2126 * lin.r + 0.7152 * lin.g + 0.0722 * lin.b)
		m.albedo_color = Color(lin.r * k, lin.g * k, lin.b * k).linear_to_srgb()
		m.roughness = 0.72
		m.metallic_specular = 0.25
	elif nom.contains("eyebrow"):
		m.roughness = 0.95
		m.metallic_specular = 0.1
	elif nom.contains("eye"):
		m.roughness = 0.12
		m.metallic_specular = 0.5
	elif nom.contains("hair"):
		m.roughness = 0.6
		m.metallic_specular = 0.3
		if es_pelo and pelo.a > 0.0:
			m.albedo_color = Color(pelo, 1.0)
		elif es_pelo and variante > 0:
			m.albedo_color = PELOS_NATURALES[variante % PELOS_NATURALES.size()]
	if es_ropa and variante > 0:
		## Otro tono de ropa: el matiz se mueve hasta ±0,1 y la claridad entre 0,8 y 1,2 según la variante (un traje sigue siendo un traje).
		var c := orig.albedo_color
		var k := variante % 5
		var h := fposmod(c.h + (k - 2) * 0.05, 1.0) if c.s > 0.18 else c.h
		m.albedo_color = Color.from_hsv(h, c.s, clampf(c.v * (0.8 + 0.1 * k), 0.08, 1.0))
	_mats[clave] = m
	return m
