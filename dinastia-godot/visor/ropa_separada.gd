class_name RopaSeparada
extends RefCounted
## EL MODELO CON LA ROPA APARTE (26-9-2026). Pedido: *"también hazlo de otro
## modelo 3D con ropa aparte"*.
##
## Hasta ahora la equipación se PINTA sobre la piel del cuerpo (y el shader la
## infla un poco). Esto hace la otra versión: camiseta, pantalón y medias son
## MALLAS PROPIAS, colgadas del mismo esqueleto, así que tienen volumen de
## verdad y silueta propia:
##   - la camiseta queda holgada, con la manga que se abre hacia el puño y el
##     bajo que cae por encima del pantalón;
##   - el pantalón se abre en las perneras;
##   - las medias, ajustadas, cubren la espinillera.
## Se sacan de la malla del cuerpo (los triángulos de cada zona de prenda, con
## sus huesos y pesos) y se separan por la normal. Por eso se mueven igual que
## el jugador en todas las animaciones, sin pesos que pintar a mano.
## El dibujo es el mismo shader (`equipacion_q.gdshader`, `prenda` = 1, 2, 3).

## Las prendas: [nombre, uniforme `prenda`]
const PRENDAS := [["Camiseta", 1], ["Pantalon", 2], ["Medias", 3]]

static var _cache: Dictionary = {}   ## id de la malla del cuerpo -> {prenda: ArrayMesh}

## ¿Qué prenda cubre este punto de reposo? 0 ninguna.
static func prenda_en(p: Vector3) -> int:
	var ax := absf(p.x)
	var brazo := ax > 0.215 and p.y > 1.2
	if brazo:
		return 1 if ax < 0.44 else 0
	if p.y >= 0.955 and p.y < 1.535:
		return 1
	if p.y >= 0.6 and p.y < 1.03:
		return 2
	if p.y >= 0.09 and p.y < 0.48:
		return 3
	return 0

## Cuánto se separa la tela del cuerpo en ese punto (m).
static func holgura_en(prenda: int, p: Vector3) -> float:
	var ax := absf(p.x)
	match prenda:
		1:
			if ax > 0.215 and p.y > 1.2:
				## Manga: pegada al hombro, abierta en el puño.
				return 0.016 + 0.03 * smoothstep(0.24, 0.43, ax)
			## Torso: más suelta abajo que en el pecho.
			return 0.02 + 0.018 * smoothstep(1.3, 1.0, p.y)
		2:
			return 0.024 + 0.03 * smoothstep(0.85, 0.61, p.y)
		3:
			return 0.006
	return 0.0

## Las mallas de las prendas para el cuerpo `malla` (superficie `sup`).
static func mallas(malla: ArrayMesh, sup: int) -> Dictionary:
	var id := malla.get_instance_id()
	if _cache.has(id):
		return _cache[id]
	var arr := malla.surface_get_arrays(sup)
	var pos: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nor: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var n := pos.size()
	var huesos: Variant = arr[Mesh.ARRAY_BONES]
	var pesos: Variant = arr[Mesh.ARRAY_WEIGHTS]
	var por_v := 4
	if huesos != null and n > 0:
		por_v = (huesos as Array).size() / n if huesos is Array else (huesos.size() / n)
	var zona := PackedInt32Array()
	zona.resize(n)
	for i in n:
		zona[i] = prenda_en(pos[i])
	var r := {}
	for pr: Array in PRENDAS:
		var cual: int = pr[1]
		var mapa := {}
		var nuevos := PackedInt32Array()
		for t in range(0, idx.size(), 3):
			var a := idx[t]
			var b := idx[t + 1]
			var c := idx[t + 2]
			if zona[a] != cual or zona[b] != cual or zona[c] != cual:
				continue
			for v in [a, b, c]:
				if not mapa.has(v):
					mapa[v] = mapa.size()
				nuevos.append(int(mapa[v]))
		if nuevos.is_empty():
			continue
		var orden: Array = []
		orden.resize(mapa.size())
		for v: int in mapa:
			orden[int(mapa[v])] = v
		var out := []
		out.resize(Mesh.ARRAY_MAX)
		var p2 := PackedVector3Array()
		var n2 := PackedVector3Array()
		for v: int in orden:
			var p: Vector3 = pos[v]
			var nn: Vector3 = nor[v]
			var q := p + nn * holgura_en(cual, p)
			## El bajo de la camiseta cae un poco.
			if cual == 1 and p.y < 1.03 and absf(p.x) < 0.215:
				q.y -= 0.012 * smoothstep(1.03, 0.96, p.y)
			p2.append(q)
			n2.append(nn)
		out[Mesh.ARRAY_VERTEX] = p2
		out[Mesh.ARRAY_NORMAL] = n2
		out[Mesh.ARRAY_INDEX] = nuevos
		for canal in [Mesh.ARRAY_TANGENT, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_TEX_UV2, Mesh.ARRAY_COLOR]:
			if arr[canal] != null:
				out[canal] = _subconjunto(arr[canal], orden, _ancho(canal))
		if huesos != null and pesos != null:
			out[Mesh.ARRAY_BONES] = _subconjunto(huesos, orden, por_v)
			out[Mesh.ARRAY_WEIGHTS] = _subconjunto(pesos, orden, por_v)
		var am := ArrayMesh.new()
		var flags := 0
		if por_v == 8:
			flags = Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out, [], {}, flags)
		am.set_meta("prenda", cual)
		r[cual] = am
	_cache[id] = r
	return r

static func _ancho(canal: int) -> int:
	return 4 if canal == Mesh.ARRAY_TANGENT else 1

## Los elementos `orden` de un array empaquetado (`ancho` valores por vértice).
static func _subconjunto(src: Variant, orden: Array, ancho: int) -> Variant:
	if src is PackedVector2Array:
		var o := PackedVector2Array()
		for v: int in orden:
			o.append((src as PackedVector2Array)[v])
		return o
	if src is PackedVector3Array:
		var o3 := PackedVector3Array()
		for v: int in orden:
			o3.append((src as PackedVector3Array)[v])
		return o3
	if src is PackedColorArray:
		var oc := PackedColorArray()
		for v: int in orden:
			oc.append((src as PackedColorArray)[v])
		return oc
	if src is PackedFloat32Array:
		var of := PackedFloat32Array()
		for v: int in orden:
			for k in ancho:
				of.append((src as PackedFloat32Array)[v * ancho + k])
		return of
	if src is PackedInt32Array:
		var oi := PackedInt32Array()
		for v: int in orden:
			for k in ancho:
				oi.append((src as PackedInt32Array)[v * ancho + k])
		return oi
	return src

## Viste `cuerpo` con las prendas aparte, con el material `mat` del cuerpo
## (se duplica por prenda). Quita las que hubiera de antes.
static func vestir(cuerpo: MeshInstance3D, sup: int, mat: ShaderMaterial) -> void:
	var padre := cuerpo.get_parent()
	if padre == null:
		return
	for h in padre.get_children():
		if h.has_meta("prenda_aparte"):
			h.queue_free()
	var ms := mallas(cuerpo.mesh as ArrayMesh, sup)
	for pr: Array in PRENDAS:
		var cual: int = pr[1]
		if not ms.has(cual):
			continue
		var mi := MeshInstance3D.new()
		mi.name = "Prenda" + String(pr[0])
		mi.set_meta("prenda_aparte", true)
		mi.mesh = ms[cual]
		mi.skin = cuerpo.skin
		padre.add_child(mi)
		mi.transform = cuerpo.transform
		mi.skeleton = mi.get_path_to(cuerpo.get_node(cuerpo.skeleton)) if not cuerpo.skeleton.is_empty() else NodePath("")
		mi.material_override = material_de(mat, cual)

static var _mats: Dictionary = {}

static func material_de(mat: ShaderMaterial, cual: int) -> ShaderMaterial:
	var k := "%d|%d" % [mat.get_instance_id(), cual]
	if _mats.has(k):
		return _mats[k]
	var m := mat.duplicate() as ShaderMaterial
	m.set_shader_parameter("prenda", cual)
	m.set_shader_parameter("holgura", 0.0)
	_mats[k] = m
	return m

## ¿Lleva ya la ropa aparte?
static func vestido(cuerpo: MeshInstance3D) -> bool:
	var padre := cuerpo.get_parent()
	if padre == null:
		return false
	for h in padre.get_children():
		if h.has_meta("prenda_aparte") and not h.is_queued_for_deletion():
			return true
	return false
