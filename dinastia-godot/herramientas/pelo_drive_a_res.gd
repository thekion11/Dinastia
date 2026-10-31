extends SceneTree
## Convierte los OBJ pequeños de `pelo_drive_extraer.py` en mallas `.res` (comprimidas, fuera de LFS) con normales hacia fuera.
##   POR_AQUI=/tmp/drive_pelo/out godot --headless --path . -s herramientas/pelo_drive_a_res.gd
## Salida: res://assets/characters/pelo_drive/pelo_NNN.res  (ancho 1,0, y = 0 arriba, centro en x/z; `PeloDrive` las coloca).
const SALIDA := "res://assets/characters/pelo_drive/"

func _init() -> void:
	var dir := OS.get_environment("POR_AQUI")
	DirAccess.make_dir_recursive_absolute(SALIDA)
	for f in DirAccess.get_files_at(dir):
		if not f.ends_with(".obj"):
			continue
		var pos := PackedVector3Array()
		var idx := PackedInt32Array()
		for l in FileAccess.get_file_as_string(dir + "/" + f).split("\n"):
			if l.begins_with("v "):
				var p := l.split(" ")
				pos.append(Vector3(float(p[1]), float(p[2]), float(p[3])))
			elif l.begins_with("f "):
				var p := l.split(" ")
				for k in range(1, 4):
					idx.append(int(p[k]) - 1)
		var nor := PackedVector3Array()
		nor.resize(pos.size())
		for t in range(0, idx.size(), 3):
			var n := (pos[idx[t + 1]] - pos[idx[t]]).cross(pos[idx[t + 2]] - pos[idx[t]])
			for k in 3:
				nor[idx[t + k]] += n
		var centro := Vector3.ZERO
		for p in pos:
			centro += p
		centro /= float(pos.size())
		centro.y -= 0.3   ## el «centro» de la cabeza queda por debajo del centro de la malla
		for i in nor.size():
			var n := nor[i].normalized()
			if n.dot(pos[i] - centro) < 0.0:
				n = -n
			nor[i] = n
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = pos
		arr[Mesh.ARRAY_NORMAL] = nor
		arr[Mesh.ARRAY_INDEX] = idx
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		var destino := SALIDA + f.get_basename() + ".res"
		ResourceSaver.save(m, destino, ResourceSaver.FLAG_COMPRESS)
		print("%s: %d vértices, %d triángulos, %d bytes" % [destino, pos.size(), idx.size() / 3, FileAccess.get_file_as_bytes(destino).size()])
	quit()
