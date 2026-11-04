extends Node
## A4 rendimiento (4-11-2026): qué recursos (texturas y mallas) de la ciudad pesan más en memoria. Recorre el árbol de la
## ciudad ya construida y suma, sin repetir, lo que usan sus materiales y mallas. Estima (no es el valor exacto del motor).
##   CALIDAD=minimo xvfb-run -a godot --path . --rendering-driver opengl3 res://pruebas/a4_rend_memoria.tscn
var _p: Node
var _n := 0

func _ready() -> void:
	Calidad.elegida = Calidad.MINIMO if OS.get_environment("CALIDAD") != "medio" else Calidad.MEDIO
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _bytes_tex(t: Texture2D) -> int:
	var w := t.get_width()
	var h := t.get_height()
	var bpp := 4.0
	if t is CompressedTexture2D or t is ImageTexture:
		var im := t.get_image() if t is ImageTexture or t is CompressedTexture2D else null
		if im != null:
			var f := im.get_format()
			if f == Image.FORMAT_L8 or f == Image.FORMAT_R8: bpp = 1.0
			elif f == Image.FORMAT_LA8 or f == Image.FORMAT_RG8: bpp = 2.0
			elif f == Image.FORMAT_RGB8: bpp = 3.0
			elif f >= Image.FORMAT_DXT1 and f <= Image.FORMAT_BPTC_RGBFU: bpp = 1.0
	return int(w * h * bpp * (1.34 if t.get_image() != null and t.get_image().has_mipmaps() else 1.0))

func _process(_d: float) -> void:
	_n += 1
	Engine.max_fps = 0
	if _n <= 12 or _n % 10 == 0 and _n < 60:
		print("MEM_FOTOGRAMA ", _n, " estática=", int(OS.get_static_memory_usage() / 1048576), " MB nodos=", int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), " recursos=", int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)))
	if _n == 5:
		_p.call("_ver_ciudad_propia")
	if _n == 60:
		var v: Node = null
		for h in _p.get_children():
			if h is VistaCiudad: v = h
		print("MEMORIA_ESTATICA ", int(OS.get_static_memory_usage() / 1048576), " MB; video ", int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576), " MB; texturas ", int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576), " MB")
		var texs := {}
		var mallas := {}
		var mats := {}
		for x in v.find_children("*", "GeometryInstance3D", true, false):
			var mats_x: Array = []
			if x is MeshInstance3D and (x as MeshInstance3D).mesh != null:
				var m: Mesh = (x as MeshInstance3D).mesh
				mallas[m.get_instance_id()] = m
				for s in m.get_surface_count(): mats_x.append(m.surface_get_material(s))
			elif x is MultiMeshInstance3D and (x as MultiMeshInstance3D).multimesh != null and (x as MultiMeshInstance3D).multimesh.mesh != null:
				var m2: Mesh = (x as MultiMeshInstance3D).multimesh.mesh
				mallas[m2.get_instance_id()] = m2
				for s in m2.get_surface_count(): mats_x.append(m2.surface_get_material(s))
			mats_x.append((x as GeometryInstance3D).material_override)
			for mt in mats_x:
				if mt is BaseMaterial3D:
					mats[mt.get_instance_id()] = mt
					for t in [mt.albedo_texture, mt.normal_texture, mt.roughness_texture, mt.metallic_texture, mt.emission_texture, mt.ao_texture]:
						if t != null: texs[t.get_instance_id()] = t
		var tb := 0
		var lista := []
		for id in texs:
			var b := _bytes_tex(texs[id])
			tb += b
			lista.append([b, texs[id]])
		lista.sort_custom(func(a, b): return a[0] > b[0])
		print("TEXTURAS únicas=", texs.size(), " materiales=", mats.size(), " ~", int(tb / 1048576), " MB")
		for i in mini(12, lista.size()):
			var t: Texture2D = lista[i][1]
			print("  TEX %6.1f MB  %dx%d  %s" % [lista[i][0] / 1048576.0, t.get_width(), t.get_height(), t.resource_path.get_file() if t.resource_path != "" else t.get_class()])
		var vb := 0
		var ml := []
		for id in mallas:
			var m3: Mesh = mallas[id]
			var b2 := 0
			for s in m3.get_surface_count():
				var arr := m3.surface_get_arrays(s)
				var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				b2 += vs.size() * 32
				if arr[Mesh.ARRAY_INDEX] != null: b2 += (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() * 4
			vb += b2
			ml.append([b2, m3])
		ml.sort_custom(func(a, b): return a[0] > b[0])
		print("MALLAS únicas=", mallas.size(), " ~", int(vb / 1048576), " MB")
		for i in mini(8, ml.size()):
			var m4: Mesh = ml[i][1]
			print("  MALLA %6.1f MB  %s %s" % [ml[i][0] / 1048576.0, m4.get_class(), m4.resource_name.left(30) if m4.resource_name != "" else m4.resource_path.get_file()])
		get_tree().quit()
