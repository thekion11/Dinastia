extends BaseIdea
## ROPA Y ACCESORIOS DE LOS PEATONES (26-10-2026, agente «pers»): lo que no se
## mide en una captura. Con el brazo caído (animación «parado» avanzada), la bolsa
## de mano cuelga POR FUERA de la pierna (antes, ancha de lado a lado, se metía
## en el muslo); la gorra no sube como un bombín por encima de la cabeza; la
## mochila no asoma por encima de los hombros.

func _probar() -> void:
	_titulo("PEATONES: bolsa, gorra y mochila sin atravesar ni flotar")
	var bolsas := 0
	var gorras := 0
	var mochilas := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for i in 40:
		var d := PeatonQ.crear(rng)
		if d.is_empty():
			continue
		add_child(d["nodo"])
		PeatonQ.terminar(d)
		var esq: Skeleton3D = d["esqueleto"]
		var ap: AnimationPlayer = d["anim"]
		if ap.has_animation("parado"):
			ap.play("parado")
			ap.advance(0.4)
		var modelo: Node3D = d["modelo"]
		var alto := modelo.scale.y
		for ba in esq.get_children():
			if not (ba is BoneAttachment3D):
				continue
			var hueso := String((ba as BoneAttachment3D).bone_name)
			var ib := esq.find_bone(hueso)
			if ib < 0 or ba.get_child_count() == 0:
				continue
			var n := ba.get_child(0) as Node3D
			if n == null:
				continue
			var pose := esq.global_transform * esq.get_bone_global_pose(ib)
			for mi in n.get_children():
				if not (mi is MeshInstance3D):
					continue
				var malla: Mesh = (mi as MeshInstance3D).mesh
				var centro := pose * (n.transform * (mi as MeshInstance3D).position)
				var raiz := (d["nodo"] as Node3D).global_position
				if malla is BoxMesh and is_equal_approx((malla as BoxMesh).size.y, 0.24) and hueso.begins_with("hand_"):
					bolsas += 1
					var fuera := absf(centro.x - raiz.x) - absf(pose.origin.x - raiz.x)
					_comprobar(fuera > 0.015, "peatón %d: la bolsa cuelga por fuera de la mano (%.3f m más afuera)" % [i, fuera])
					_comprobar((malla as BoxMesh).size.x < (malla as BoxMesh).size.z, "peatón %d: la bolsa es fina hacia la pierna" % i)
					## Que la mano la agarre (26-10-2026: se veía flotando bajo la mano).
					## En el espacio del hueso: +Y hacia los dedos; la palma, a ~7 cm.
					var boca := (n.transform * ((mi as MeshInstance3D).position - Vector3(0, (malla as BoxMesh).size.y * 0.5, 0))).y
					_comprobar(boca < 0.125, "peatón %d: la boca de la bolsa queda bajo la mano (%.3f m de la muñeca)" % [i, boca])
					for otra in n.get_children():
						if otra is MeshInstance3D and (otra as MeshInstance3D).mesh is TorusMesh:
							var asa := n.transform * (otra as MeshInstance3D).position
							var palma := n.transform * Vector3(0, 0.07, 0)
							_comprobar(asa.distance_to(palma) < 0.025, "peatón %d: el asa pasa por la palma (a %.3f m)" % [i, asa.distance_to(palma)])
				elif malla is SphereMesh and (malla as SphereMesh).is_hemisphere and hueso == "Head":
					gorras += 1
					## En el espacio del hueso de la cabeza (sigue a la cabeza aunque
					## se incline): lo alto de la copa contra lo alto de la malla.
					var tope := (n.transform * ((mi as MeshInstance3D).position + Vector3(0, (malla as SphereMesh).height, 0))).y
					var cabeza_alta := (1.767 if bool(d["mujer"]) else 1.81) - esq.get_bone_global_rest(ib).origin.y
					var sobra := tope - cabeza_alta
					var ancho_g := (malla as SphereMesh).radius * (mi as MeshInstance3D).scale.x
					_comprobar(ancho_g < 0.1, "peatón %d: la copa ciñe la cabeza (radio %.3f m < 0,1; la cabeza mide 0,07)" % [i, ancho_g])
					_comprobar(sobra > 0.0 and sobra < 0.06, "peatón %d: la gorra cubre la cabeza y sube %.3f m sobre ella (0-6 cm)" % [i, sobra])
				elif malla is BoxMesh and is_equal_approx((malla as BoxMesh).size.y, 0.3) and hueso == "spine_03":
					mochilas += 1
					var arriba := (pose * (n.transform * ((mi as MeshInstance3D).position + Vector3(0, 0.15, 0)))).y
					var hombro := (esq.global_transform * esq.get_bone_global_pose(esq.find_bone("neck_01"))).origin.y
					_comprobar(arriba < hombro, "peatón %d: la mochila no asoma sobre los hombros (%.3f < %.3f)" % [i, arriba, hombro])
		(d["nodo"] as Node).queue_free()
	_comprobar(bolsas >= 2, "hay bolsas en la muestra (%d)" % bolsas)
	_comprobar(gorras >= 2, "hay gorras en la muestra (%d)" % gorras)
	_comprobar(mochilas >= 2, "hay mochilas en la muestra (%d)" % mochilas)
