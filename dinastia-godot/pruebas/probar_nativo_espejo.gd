class_name ProbarNativoEspejo
extends RefCounted
## (19-11-2026) EL ESPEJO DE LAS ANIMACIONES EN C++ = GDScript (`nativo/src/espejo_nativo.cpp`; gemela `AnimExtra._espejar_gd`). Esqueletos de mentira con pares `_l`/`_r`
## y huesos sueltos, y clips con rotaciones (de un lado, del otro y de huesos sin par) y posiciones; se comparan, byte a byte, las pistas del clip espejado: ruta,
## tipo, tiempos y valores. Devuelve {fallos, textos}.
static func _volcar(a: Animation) -> Array:
	if a == null:
		return []
	var sal: Array = [a.length, a.loop_mode, a.get_track_count()]
	for t in a.get_track_count():
		var fila: Array = [str(a.track_get_path(t)), a.track_get_type(t), a.track_get_key_count(t)]
		for k in a.track_get_key_count(t):
			fila.append(a.track_get_key_time(t, k))
			fila.append(a.track_get_key_value(t, k))
		sal.append(fila)
	return sal

static func probar(nat: Object) -> Dictionary:
	var fallos: Array[String] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 2609
	var comparados := 0
	var claves := 0
	for caso in range(5):
		var n: int = [2, 7, 24, 60, 95][caso]
		var esq := Skeleton3D.new()
		var nombres: Array[String] = []
		for i in n:
			var nom := "hueso%d" % i
			if i % 3 == 1:
				nom = "brazo%d_l" % (i / 3)
			elif i % 3 == 2 and i > 1:
				nom = "brazo%d_r" % (i / 3 - 0 if caso % 2 == 0 else i / 3 - 1)
			if nombres.has(nom):
				nom += "x%d" % i
			nombres.append(nom)
			esq.add_bone(nom)
			if i > 0:
				esq.set_bone_parent(i, rng.randi() % i)
			esq.set_bone_rest(i, Transform3D(Basis(Quaternion(Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized(), rng.randf_range(0.0, 1.5))), Vector3(rng.randf_range(-0.3, 0.3), rng.randf_range(0.0, 0.4), rng.randf_range(-0.3, 0.3))))
		var clip := Animation.new()
		clip.length = [0.4, 1.0, 1.3][caso % 3]
		clip.loop_mode = caso % 3
		for i in n:
			if i % 4 == 3 and caso != 0:
				continue   ## huesos sin pista
			var t := clip.add_track(Animation.TYPE_ROTATION_3D)
			clip.track_set_path(t, NodePath("Armature/Skeleton3D:%s" % nombres[i]))
			for k in 5:
				clip.rotation_track_insert_key(t, clip.length * float(k) / 4.0, Quaternion(Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized(), rng.randf_range(0.0, 2.5)))
			if i % 5 == 0:
				var tp := clip.add_track(Animation.TYPE_POSITION_3D)
				clip.track_set_path(tp, NodePath("Armature/Skeleton3D:%s" % nombres[i]))
				for k in 4:
					clip.position_track_insert_key(tp, clip.length * float(k) / 3.0, Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(0.0, 1.0), rng.randf_range(-0.2, 0.2)))
		var a_gd: Animation = AnimExtra._espejar_gd(clip, esq, "Armature/Skeleton3D")
		var a_c: Animation = nat.anim_espejar(clip, esq, "Armature/Skeleton3D")
		comparados += 1
		if var_to_bytes(_volcar(a_gd)) != var_to_bytes(_volcar(a_c)):
			fallos.append("clip espejado distinto con %d huesos" % n)
		claves += int(_volcar(a_gd).size())
		esq.free()
	## Un clip sin rotaciones devuelve null en las dos.
	var esq2 := Skeleton3D.new()
	esq2.add_bone("a")
	var vacio := Animation.new()
	comparados += 1
	if AnimExtra._espejar_gd(vacio, esq2, "x") != null or nat.anim_espejar(vacio, esq2, "x") != null:
		fallos.append("el clip sin rotaciones debía dar null")
	esq2.free()
	return {"fallos": fallos, "textos": ["espejo: %d clips comparados (2 a 95 huesos)" % comparados]}
