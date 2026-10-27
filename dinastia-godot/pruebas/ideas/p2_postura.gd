extends BaseIdea
## P2 «MEJORAR» (27-10-2026): la postura de los peatones: hombros caídos, cabeza adelantada y manos relajadas (dedos doblados hacia la palma).

func _probar() -> void:
	_titulo("P2: POSTURA Y ANATOMÍA DE LOS PEATONES")
	var d := PeatonVida.nuevo(self, 77)
	if d.is_empty():
		_comprobar(true, "(sin modelo de peatón en este entorno)")
		return
	var esq := FutbolistaQ.esqueleto_de(d["nodo"])
	var m := esq.get_node_or_null("PosturaQ") as PosturaQ
	_comprobar(m != null, "cada peatón lleva su PosturaQ")
	if m == null:
		return
	m.active = false
	var pose := {}
	for k in m._huesos.size():
		pose[m._huesos[k]] = esq.get_bone_pose_rotation(m._huesos[k])
	var hombro_i := esq.find_bone("upperarm_l")
	var hombro_d := esq.find_bone("upperarm_r")
	var cab := esq.find_bone("Head")
	var punta := esq.find_bone("index_04_leaf_l")
	var mano := esq.find_bone("hand_l")
	var antes := _medir(esq, [hombro_i, hombro_d, cab, punta, mano])
	m._process_modification()
	var despues := _medir(esq, [hombro_i, hombro_d, cab, punta, mano])
	_comprobar(m._huesos.size() >= 20, "toca %d huesos (hombros, cuello, dedos)" % m._huesos.size())
	var caida_i := (antes[0] as Vector3).y - (despues[0] as Vector3).y
	var caida_d := (antes[1] as Vector3).y - (despues[1] as Vector3).y
	_comprobar(caida_i > 0.002 and caida_d > 0.002, "los hombros caen (%.1f y %.1f cm)" % [caida_i * 100.0, caida_d * 100.0])
	var adelanto := (despues[2] as Vector3).z - (antes[2] as Vector3).z
	_comprobar(adelanto > 0.003, "la cabeza se adelanta %.1f cm" % [adelanto * 100.0])
	var dist0 := (antes[3] as Vector3).distance_to(antes[4] as Vector3)
	var dist1 := (despues[3] as Vector3).distance_to(despues[4] as Vector3)
	_comprobar(dist1 < dist0 - 0.005, "los dedos se doblan hacia la palma (la punta del índice se acerca %.1f cm a la mano)" % [(dist0 - dist1) * 100.0])

func _medir(esq: Skeleton3D, huesos: Array) -> Array:
	var sal := []
	for i: int in huesos:
		sal.append(esq.get_bone_global_pose(i).origin)
	return sal
