extends SceneTree
## HORNEA LAS PERSONAS DEL PÚBLICO (14-10-2026, pedido: «el público del estadio
## deben ser personas reales, optimizadas»). Toma el mismo modelo humano que juega
## (FutbolistaQ), lo pone en varias poses reales (de pie con los brazos caídos,
## aplaudiendo, celebrando, señalando…), hornea cada pose a una malla ESTÁTICA, la
## corta a la altura de la cadera (el resto lo tapan la butaca y la fila de
## delante) y la simplifica con el simplificador de mallas del motor a dos niveles:
## «cerca» (~400 vértices) y «medio» (~140). Guarda un recurso por pose y nivel en
## `assets/ciudad/publico/`, con las alturas del cuello y del pelo en sus metadatos
## para el shader `hinchada.gdshader`.
##
##   godot --headless --path . -s res://herramientas/hornear_publico.gd
##
## (Se corre una vez y se sube el resultado: el juego no hornea nada al arrancar.)

const POSES := [
	["quieto", "parado", 0.30],
	["aplaude", "aplaudir", 0.45],
	["celebra", "celebrar", 0.50],
	["puno", "puno_al_aire", 0.40],
	["senala", "senalar_cielo", 0.50],
	["saluda", "saludar_publico", 0.60],
]
const OBJETIVOS := {"cerca": 420, "medio": 150}
const SALIDA := "res://assets/ciudad/publico/"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(SALIDA)
	var d := FutbolistaQ.crear(1.78, "male")
	var raiz: Node3D = d["nodo"]
	root.add_child(raiz)
	FutbolistaQ.terminar(d, true)
	var ap: AnimationPlayer = d["anim"]
	var cuerpo: MeshInstance3D = null
	for mi in raiz.find_children("*", "MeshInstance3D", true, false):
		if mi.name == "SuperHero_Male":
			cuerpo = mi
	if cuerpo == null:
		push_error("no hay cuerpo")
		quit(1)
		return
	var esq: Skeleton3D = cuerpo.get_parent() as Skeleton3D
	if esq == null:
		push_error("el cuerpo no cuelga del esqueleto")
		quit(1)
		return
	var total := 0
	var altura_ref := -1.0
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
		if altura_ref < 0.0:
			var lo := 1e9
			var hi := -1e9
			for v: Vector3 in arr[Mesh.ARRAY_VERTEX]:
				lo = minf(lo, v.y)
				hi = maxf(hi, v.y)
			altura_ref = hi - lo
			print("altura del modelo en esta pose: ", altura_ref)
		for nivel: String in OBJETIVOS:
			var r := _preparar(arr, int(OBJETIVOS[nivel]))
			if r.is_empty():
				continue
			var mesh: ArrayMesh = r["mesh"]
			mesh.set_meta("cuello_desde", r["cuello_desde"])
			mesh.set_meta("cuello_hasta", r["cuello_hasta"])
			mesh.set_meta("pelo_desde", r["pelo_desde"])
			mesh.set_meta("alto", r["alto"])
			var ruta := "%shincha_%s_%s.res" % [SALIDA, nombre, nivel]
			ResourceSaver.save(mesh, ruta)
			total += 1
			print("%s %-7s %4d vértices, alto %.2f, cuello %.2f, pelo %.2f" % [nombre, nivel, r["vertices"], r["alto"], r["cuello_desde"], r["pelo_desde"]])
	print("HORNEADO ", total, " mallas")
	quit()

## Piel por CPU: el motor no deja hornear aquí (la referencia de la piel solo
## existe con pantalla), así que se aplica a mano: matriz del hueso en la pose
## actual por la pose de enlace de la piel.
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

## Corta por la cadera, centra y simplifica a ~`objetivo` vértices.
func _preparar(arr: Array, objetivo: int) -> Dictionary:
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var alto_modelo := -1e9
	var bajo := 1e9
	for v in vs:
		alto_modelo = maxf(alto_modelo, v.y)
		bajo = minf(bajo, v.y)
	## La cadera, al ~53 % de la altura de pie (la pose puede subir los brazos: se
	## mide con la altura del tronco, no con el máximo).
	var altura_pie := 1.78
	var cadera := bajo + altura_pie * 0.52
	## Sin las piernas: solo triángulos enteros por encima de la cadera.
	var usados := {}
	var tris: Array[int] = []
	for t in range(0, idx.size(), 3):
		var ok := true
		for k in 3:
			if vs[idx[t + k]].y < cadera:
				ok = false
		if ok:
			for k in 3:
				tris.append(idx[t + k])
				usados[idx[t + k]] = true
	if tris.is_empty():
		return {}
	## Se recompacta: solo los vértices usados, centrados y con la cadera a +0,12.
	var mapa := {}
	var pos := PackedVector3Array()
	var nor := PackedVector3Array()
	var normales: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var cx := 0.0
	var cz := 0.0
	var n := 0
	for i in usados:
		cx += vs[i].x
		cz += vs[i].z
		n += 1
	cx /= float(n)
	cz /= float(n)
	var escala := 0.96
	var max_y := -1e9
	for i in usados.keys():
		mapa[i] = pos.size()
		var p := vs[i]
		pos.append(Vector3((p.x - cx) * escala, (p.y - cadera) * escala + 0.12, (p.z - cz) * escala))
		nor.append(normales[i])
		max_y = maxf(max_y, pos[pos.size() - 1].y)
	var ind := PackedInt32Array()
	for i in tris:
		ind.append(mapa[i])
	## Simplificar: ImporterMesh genera niveles de detalle con meshoptimizer.
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
	## Recompactar otra vez con el nivel elegido.
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
	## Alturas para el shader: la cabeza mide ~0,23 de la altura de pie y el cuello
	## queda a ~0,86 de ella; se miden en el modelo en reposo (escala incluida).
	var h_pie := altura_pie * escala
	var y_cabeza_base := (altura_pie * 0.86 - altura_pie * 0.52) * escala + 0.12
	return {"mesh": mesh, "vertices": pos2.size(), "alto": max_y,
		"cuello_desde": y_cabeza_base - 0.06, "cuello_hasta": y_cabeza_base + 0.02,
		"pelo_desde": y_cabeza_base + h_pie * 0.085}
