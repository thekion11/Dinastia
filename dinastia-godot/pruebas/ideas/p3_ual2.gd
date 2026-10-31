extends BaseIdea
## P3 (31-10-2026, idea del dueño: «buscar en GitHub más articulaciones y esqueletos»): 17 clips de la Universal Animation Library 2
## de Quaternius (CC0, mismo esqueleto) en `anims_ual2/ual2_elegidos.res`, cargados bajo demanda con `AnimExtra.asegurar`.

func _probar() -> void:
	_titulo("P3: CLIPS DE LA UAL2")
	_comprobar(ResourceLoader.exists(AnimQuaternius.RUTA_UAL2), "el recurso de la UAL2 existe")
	var d := PeatonVida.nuevo(self, 7)
	if d.is_empty():
		_comprobar(true, "(sin modelo de peatón en este entorno)")
		return
	var nodo: Node3D = d["nodo"]
	var ap: AnimationPlayer = nodo.find_children("*", "AnimationPlayer", true, false)[0]
	var esq := FutbolistaQ.esqueleto_de(nodo)
	var faltan: Array = []
	for k: String in AnimExtra.UAL2:
		if not AnimExtra.asegurar(ap, esq, k):
			faltan.append(k)
	_comprobar(faltan.is_empty(), "los %d clips cargan en un peatón (faltan: %s)" % [AnimExtra.UAL2.size(), str(faltan)])
	var a := ap.get_animation("brazos_cruzados")
	var ruta := str(a.track_get_path(0)) if a != null and a.get_track_count() > 0 else ""
	_comprobar(ruta.ends_with(":pelvis") and ap.get_node(ap.root_node).get_node_or_null(NodePath(ruta.substr(0, ruta.rfind(":")))) == esq,
		"y sus pistas apuntan a huesos de NUESTRO esqueleto (%s)" % ruta)
	_comprobar(a != null and a.loop_mode == Animation.LOOP_LINEAR and ap.get_animation("asentir").loop_mode == Animation.LOOP_NONE, "los «_Loop» se repiten y los gestos no")
	ap.play("brazos_cruzados")
	ap.advance(1.0)
	var antebrazo := esq.find_bone("lowerarm_l")
	var q := esq.get_bone_pose_rotation(antebrazo)
	_comprobar(not q.is_equal_approx(esq.get_bone_rest(antebrazo).basis.get_rotation_quaternion()), "al reproducirlo el brazo se mueve de verdad")
	_comprobar(not AnimExtra.UAL.has("telefono"), "y no se cargan en todos los futbolistas (`extender` solo usa la UAL1)")
