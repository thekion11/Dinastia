extends "res://pruebas/medir_partido_p1.gd"
## (Parte 2 de 2 de `medir_partido.gd`.)

func _por_hijos() -> void:
	var raiz: Node3D = _vista.get("_raiz3d")
	if not _ph_listo:
		## Congelar: todo en pausa menos esta medición.
		process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().paused = true
		_ph_listo = true
		_ph_espera = -6
		return
	if _ph_espera < 0:
		_ph_espera += 1
		if OS.get_environment("ESTABILIDAD") != "":
			print("ESTABLE llamadas=%d tris=%d" % [_medida().x, _medida().y])
			if _ph_espera == 0:
				_ph_espera = -20
				_ph_estables += 1
				if _ph_estables > 2:
					get_tree().quit()
			return
		if _ph_espera == 0:
			_ph_base = _medida()
			for h in raiz.get_children():
				if h is Node3D and (h as Node3D).visible:
					_ph_cola.append([h, 0])
			print("POR_HIJOS (congelado) base llamadas=%d tris=%d" % [_ph_base.x, _ph_base.y])
		return
	if _ph_actual == null:
		if _ph_cola.is_empty():
			_ph_res.sort_custom(func(a: Array, b: Array) -> bool: return float(a[2]) > float(b[2]))
			for r: Array in _ph_res.slice(0, 40):
				print("HIJO %-60s llamadas=%5d tris=%8d" % [r[0], r[1], r[2]])
			_ph_res.sort_custom(func(a: Array, b: Array) -> bool: return int(a[1]) > int(b[1]))
			for r: Array in _ph_res.slice(0, 25):
				print("LLAMADAS %-56s llamadas=%5d tris=%8d" % [r[0], r[1], r[2]])
			_fin = true
			get_tree().quit()
			return
		var sig: Array = _ph_cola.pop_front()
		if not is_instance_valid(sig[0]):
			return
		_ph_actual = sig
		(sig[0] as Node3D).visible = false
		_ph_espera = 0
		return
	_ph_espera += 1
	if _ph_espera < 3:
		return
	var n: Node3D = _ph_actual[0]
	var nivel: int = _ph_actual[1]
	var m := _medida()
	var dl := int(_ph_base.x - m.x)
	var dt := int(_ph_base.y - m.y)
	var ruta := str(raiz.get_path_to(n))
	_ph_res.append(["%s%s" % ["  ".repeat(nivel), ruta.right(56)], dl, dt])
	n.visible = true
	if nivel < 3 and (dt > 40000 or dl > 15):
		for h in n.get_children():
			if h is Node3D and (h as Node3D).visible:
				_ph_cola.append([h, nivel + 1])
	_ph_actual = null

## LISTA_MM=1 (3-11): todas las multimallas y mallas visibles agrupadas por nombre base, con instancias y triángulos potenciales (instancias × malla).
func _lista_multimallas() -> void:
	var grupos := {}
	for n in _vista.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		if not g.is_visible_in_tree():
			continue
		var t := 0
		var inst := 1
		if g is MultiMeshInstance3D:
			var mm := (g as MultiMeshInstance3D).multimesh
			if mm == null or mm.mesh == null:
				continue
			for i in mm.mesh.get_surface_count():
				var a := mm.mesh.surface_get_arrays(i)
				var idx = a[Mesh.ARRAY_INDEX]
				t += (idx.size() if idx != null else (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
			inst = mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count
			t *= inst
		elif g is MeshInstance3D and (g as MeshInstance3D).mesh != null:
			var m := (g as MeshInstance3D).mesh
			for i in m.get_surface_count():
				var a2 := m.surface_get_arrays(i)
				var idx2 = a2[Mesh.ARRAY_INDEX]
				t += (idx2.size() if idx2 != null else (a2[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
		var base := String(g.name)
		while base.length() > 0 and (base[base.length() - 1].is_valid_int() or base[base.length() - 1] == "_" or base[base.length() - 1] == "@"):
			base = base.left(base.length() - 1)
		var clave := "%s %s" % ["MM" if g is MultiMeshInstance3D else "malla", base]
		if not grupos.has(clave):
			grupos[clave] = [0, 0, 0]
		grupos[clave][0] += 1
		grupos[clave][1] += inst
		grupos[clave][2] += t
	var claves := grupos.keys()
	claves.sort_custom(func(x, y): return grupos[x][2] > grupos[y][2])
	for k in claves.slice(0, 30):
		print("LISTA %-40s nodos=%4d instancias=%6d tris_pot=%9d" % [k, grupos[k][0], grupos[k][1], grupos[k][2]])
