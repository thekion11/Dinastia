extends SceneTree
## HORNEA LAS PERSONAS DEL PÚBLICO (14-10-2026, pedido: «el público del estadio
## deben ser personas reales, optimizadas»; 2.ª versión tras «no se ven tan bien»).
## Toma el mismo modelo humano que juega (FutbolistaQ), lo pone en poses de
## aficionado SENTADO (sentado, charla, aplauso, puño, pulgar, brazos cruzados,
## manos a la cabeza…), hornea cada pose a una malla ESTÁTICA con la piel puesta a
## mano (el motor no deja hornear aquí), la corta en la cadera con el borde plano
## (la butaca y la fila de delante tapan el resto) y la simplifica a dos niveles:
## «cerca» (~450 vértices) y «medio» (~160). Guarda un recurso por pose y nivel en
## `assets/ciudad/publico/` con las alturas del cuello y del pelo MEDIDAS en los
## huesos Head y pelvis (metadatos para `hinchada.gdshader`).
##
##   godot --headless --path . -s res://herramientas/hornear_publico.gd

## [clave, animación, fracción de la animación]
const POSES := [
	["quieto", "sentado", 0.5],
	["charla", "sentado_charla", 0.4],
	["aplaude", "aplaudir", 0.45],
	["aplaude_arriba", "aplauso_arriba", 0.4],
	["puno", "puno_al_aire", 0.45],
	["pulgar", "pulgar_arriba", 0.5],
	["cruzados", "cruzar_brazos", 0.6],
	["cabeza", "manos_cabeza", 0.6],
]
const OBJETIVOS := {"cerca": 450, "medio": 160, "lejos": 70}
const SALIDA := "res://assets/ciudad/publico/"
const ESCALA := 0.96

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(SALIDA)
	## Fuera las mallas de la versión anterior (otras claves de pose).
	var dir := DirAccess.open(SALIDA)
	for f in dir.get_files():
		if f.begins_with("hincha_"):
			dir.remove(f)
	var d := FutbolistaQ.crear(1.78, "male")
	var raiz: Node3D = d["nodo"]
	root.add_child(raiz)
	FutbolistaQ.terminar(d, true)
	var ap: AnimationPlayer = d["anim"]
	var cuerpo: MeshInstance3D = null
	for mi in raiz.find_children("*", "MeshInstance3D", true, false):
		if mi.name == "SuperHero_Male":
			cuerpo = mi
	var esq: Skeleton3D = cuerpo.get_parent() as Skeleton3D if cuerpo != null else null
	if esq == null:
		push_error("no hay cuerpo con esqueleto")
		quit(1)
		return
	var total := 0
	for pose: Array in POSES:
		var nombre: String = pose[0]
		var anim: String = pose[1]
		if not ap.has_animation(anim):
			push_warning("sin animación %s, se salta %s" % [anim, nombre])
			continue
		ap.play(anim)
		ap.seek(float(pose[2]) * ap.current_animation_length, true)
		ap.advance(0.0)
		await process_frame
		await process_frame
		var arr: Array = _vestir(cuerpo, esq)
		var pelvis_y := esq.get_bone_global_pose(esq.find_bone("pelvis")).origin.y
		var cabeza_y := esq.get_bone_global_pose(esq.find_bone("Head")).origin.y
		for nivel: String in OBJETIVOS:
			var r := _preparar(arr, int(OBJETIVOS[nivel]), pelvis_y, cabeza_y)
			if r.is_empty():
				continue
			var mesh: ArrayMesh = r["mesh"]
			mesh.set_meta("cuello_desde", r["cuello_desde"])
			mesh.set_meta("cuello_hasta", r["cuello_hasta"])
			mesh.set_meta("pelo_desde", r["pelo_desde"])
			mesh.set_meta("alto", r["alto"])
			ResourceSaver.save(mesh, "%shincha_%s_%s.res" % [SALIDA, nombre, nivel])
			total += 1
			print("%s %-7s %4d vértices, cuello %.2f, pelo %.2f, alto %.2f" % [nombre, nivel, r["vertices"], r["cuello_desde"], r["pelo_desde"], r["alto"]])
	print("HORNEADO ", total, " mallas")
	quit()

## Piel por CPU: matriz del hueso en la pose actual por la pose de enlace.
func _vestir(mi: MeshInstance3D, esq: Skeleton3D) -> Array:
	var arr: Array = mi.mesh.surface_get_arrays(0).duplicate(true)
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var hs = arr[Mesh.ARRAY_BONES]
	var ws = arr[Mesh.ARRAY_WEIGHTS]
	var piel: Skin = mi.skin
	var mats: Array[Transform3D] = []
	for i in piel.get_bind_count():
		var hueso := piel.get_bind_bone(i)
		if hueso < 0:
			hueso = esq.find_bone(piel.get_bind_name(i))
		mats.append(esq.get_bone_global_pose(hueso) * piel.get_bind_pose(i))
	var por: int = hs.size() / vs.size()
	for v in vs.size():
		var p := Vector3.ZERO
		var nn := Vector3.ZERO
		for k in por:
			var w: float = ws[v * por + k]
			if w <= 0.0:
				continue
			var m: Transform3D = mats[int(hs[v * por + k])]
			p += (m * vs[v]) * w
			nn += (m.basis * ns[v]) * w
		vs[v] = p
		ns[v] = nn.normalized()
	arr[Mesh.ARRAY_VERTEX] = vs
	arr[Mesh.ARRAY_NORMAL] = ns
	return arr

## Corta en la cadera (borde plano), centra y simplifica a ~`objetivo` vértices.
func _preparar(arr: Array, objetivo: int, pelvis_y: float, cabeza_y: float) -> Dictionary:
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var normales: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var corte := pelvis_y - 0.02
	var usados := {}
	var tris: Array[int] = []
	for t in range(0, idx.size(), 3):
		var ok := true
		for k in 3:
			if vs[idx[t + k]].y < corte - 0.1:
				ok = false
		if ok:
			for k in 3:
				tris.append(idx[t + k])
				usados[idx[t + k]] = true
	if tris.is_empty():
		return {}
	var mapa := {}
	var pos := PackedVector3Array()
	var nor := PackedVector3Array()
	var cx := 0.0
	var cz := 0.0
	for i in usados:
		cx += vs[i].x
		cz += vs[i].z
	cx /= float(usados.size())
	cz /= float(usados.size())
	var max_y := -1e9
	for i in usados.keys():
		mapa[i] = pos.size()
		var p := vs[i]
		## Borde plano: lo que baja de la cadera se aplasta en el plano de corte.
		var y := maxf(p.y, corte)
		pos.append(Vector3((p.x - cx) * ESCALA, (y - pelvis_y) * ESCALA + 0.12, (p.z - cz) * ESCALA))
		nor.append(normales[i] if p.y >= corte else Vector3.DOWN)
		max_y = maxf(max_y, pos[pos.size() - 1].y)
	var ind := PackedInt32Array()
	for i in tris:
		ind.append(mapa[i])
	var im := ImporterMesh.new()
	var a2 := []
	a2.resize(Mesh.ARRAY_MAX)
	a2[Mesh.ARRAY_VERTEX] = pos
	a2[Mesh.ARRAY_NORMAL] = nor
	a2[Mesh.ARRAY_INDEX] = ind
	im.add_surface(Mesh.PRIMITIVE_TRIANGLES, a2, [], {}, null, "cuerpo")
	im.generate_lods(25.0, 60.0, [])
	var mejor_ind: PackedInt32Array = ind
	var mejor_dif := 1 << 30
	var candidatos: Array = [ind]
	for l in im.get_surface_lod_count(0):
		candidatos.append(im.get_surface_lod_indices(0, l))
	for c: PackedInt32Array in candidatos:
		var u := {}
		for i in c:
			u[i] = true
		var dif := absi(u.size() - objetivo)
		if dif < mejor_dif:
			mejor_dif = dif
			mejor_ind = c
	var m2 := {}
	var pos2 := PackedVector3Array()
	var nor2 := PackedVector3Array()
	var ind2 := PackedInt32Array()
	for i in mejor_ind:
		if not m2.has(i):
			m2[i] = pos2.size()
			pos2.append(pos[i])
			nor2.append(nor[i])
		ind2.append(m2[i])
	var a3 := []
	a3.resize(Mesh.ARRAY_MAX)
	a3[Mesh.ARRAY_VERTEX] = pos2
	a3[Mesh.ARRAY_NORMAL] = nor2
	a3[Mesh.ARRAY_INDEX] = ind2
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a3)
	## El hueso Head está en la base del cráneo: el cuello acaba ~6 cm por debajo
	## y el pelo empieza ~12 cm por encima.
	var y_cabeza := (cabeza_y - pelvis_y) * ESCALA + 0.12
	return {"mesh": mesh, "vertices": pos2.size(), "alto": max_y,
		"cuello_desde": y_cabeza - 0.04, "cuello_hasta": y_cabeza + 0.03,
		"pelo_desde": y_cabeza + 0.115}
