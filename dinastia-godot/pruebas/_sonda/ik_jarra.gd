extends Node3D
## Sonda temporal: busca los ángulos de «brazos en jarra» (mano en la cadera, codo afuera).
func _ready() -> void:
	var d := FutbolistaQ.crear(1.8, "male"); add_child(d["nodo"]); FutbolistaQ.terminar(d, false)
	var esq: Skeleton3D = d["esqueleto"]
	esq.reset_bone_poses()
	var pel := esq.find_bone("pelvis")
	for lado in ["i", "d"]:
		var ib := AnimQuaternius._idx(esq, "brazo_" + lado); var ic := AnimQuaternius._idx(esq, "antebrazo_" + lado)
		var ih := esq.find_bone("hand_" + ("l" if lado == "i" else "r"))
		var rb := esq.get_bone_rest(ib).basis.get_rotation_quaternion(); var rc := esq.get_bone_rest(ic).basis.get_rotation_quaternion()
		esq.force_update_all_bone_transforms()
		var p0 := esq.get_bone_global_pose(pel).origin
		var sx := signf(esq.get_bone_global_pose(ib).origin.x)
		var obj := p0 + Vector3(sx * 0.17, 0.08, float(OS.get_environment("DZ")))
		var mejor := [1e9]
		for paso in [15.0, 5.0, 2.0]:
			var c: Array = mejor.slice(1) if mejor.size() > 1 else [0.0, 0.0, 0.0, 90.0]
			var rango := 6 if paso == 15.0 else 3
			for a in range(-rango, rango + 1):
				for b in range(-rango, rango + 1):
					for e in range(-rango, rango + 1):
						for k in range(-3, 4):
							var g := Vector3(c[0] + a * paso, c[1] + b * paso, c[2] + e * paso)
							var codo: float = clampf(c[3] + k * paso, 30.0, 150.0)
							var ga := AnimQuaternius._ajustar("brazo_" + lado, g)
							esq.set_bone_pose_rotation(ib, rb * Quaternion.from_euler(ga * PI / 180.0))
							esq.set_bone_pose_rotation(ic, rc * Quaternion.from_euler(Vector3(codo, 0, 0) * PI / 180.0))
							esq.force_update_all_bone_transforms()
							var h := esq.get_bone_global_pose(ih).origin; var co := esq.get_bone_global_pose(ic).origin
							var coste := (h - obj).length_squared() * 100.0
							coste += pow(maxf(0.0, 0.42 - absf(co.x)), 2) * 80.0
							coste += pow(co.z - obj.z, 2) * 40.0
							coste += pow(maxf(0.0, co.y - (p0.y + 0.30)), 2) * 30.0
							if coste < mejor[0]: mejor = [coste, g.x, g.y, g.z, codo]
		print("JARRA ", lado, " ", mejor)
	get_tree().quit()
