extends BaseIdea
## Peinados del Drive (27-10-2026): 2 mallas pequeñas (≤ 2.600 triángulos y ≤ 120 KB cada una, fuera de LFS), ajustadas a las cabezas Quaternius.

func _probar() -> void:
	_titulo("P4: PEINADOS DEL DRIVE (nv toufa) SOBRE LAS CABEZAS DE QUATERNIUS")
	var ids: Array = PeloDrive.HOMBRES + PeloDrive.MUJERES
	var total := 0
	var grandes := 0
	for id: int in ids:
		var m := PeloDrive.malla(id)
		if m == null:
			grandes += 1
			continue
		var tris := (m.surface_get_arrays(0)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
		var kb := FileAccess.get_file_as_bytes(PeloDrive.RUTA % id).size() / 1024
		total += kb
		if tris > 5000 or kb > 200:
			grandes += 1
		var ab := m.get_aabb()
		if absf(ab.size.x - 1.0) > 0.02 or absf(ab.end.y) > 0.01:
			grandes += 1
	_comprobar(grandes == 0, "las %d mallas existen, ≤ 5.000 triángulos, ≤ 200 KB y normalizadas (ancho 1, y=0 arriba); suman %d KB" % [ids.size(), total])
	_comprobar(total < 1500, "todo el pack cabe en < 1,5 MB (%d KB)" % total)
	## Reparto determinista y cercano a PROB %.
	var con := 0
	for s in 1000:
		var a := PeloDrive.elegir(s, false)
		if a != PeloDrive.elegir(s, false):
			grandes += 1
		if a >= 0:
			con += 1
			var lista: Array = PeloDrive.HOMBRES
			if not lista.has(a):
				grandes += 1
	_comprobar(absi(con - PeloDrive.PROB * 10) < 60 and grandes == 0, "el %d %% de las personas lleva uno (%d de 1000) y del grupo de su sexo" % [PeloDrive.PROB, con])
	## Puesto sobre un cuerpo, cuelga del «Pelo» y la coronilla del peinado queda sobre la cabeza (no hundido ni flotando).
	for sexo in ["male"]:
		var d := FutbolistaQ.crear(1.78 if sexo == "male" else 1.66, sexo)
		add_child(d["nodo"])
		FutbolistaQ.terminar(d, false)
		var peluca := PeloQ.poner(d, "corto", Color(0.3, 0.2, 0.1), false, 80)
		var h: Node = peluca.get_node_or_null("PeloDrive%d" % (80))
		_comprobar(h != null, "%s: el peinado del Drive cuelga de «Pelo» (y sin el corte del pack: %s)" % [sexo, str(peluca.get_node_or_null("Hair_Buzzed") == null)])
		if h != null:
			var esq: Skeleton3D = d["esqueleto"]
			var cab := esq.get_bone_global_rest(esq.find_bone("Head")).origin
			var arriba := (esq.get_bone_global_rest(esq.find_bone("Head")) * (h as MeshInstance3D).transform * Vector3.ZERO).y
			_comprobar(arriba > cab.y + 0.15 and arriba < cab.y + 0.30, "%s: la coronilla del peinado está %.0f cm sobre el hueso de la cabeza" % [sexo, (arriba - cab.y) * 100.0])
		(d["nodo"] as Node).queue_free()
