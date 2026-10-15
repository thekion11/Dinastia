extends Node3D
## Sonda: dónde quedan cadera y pies con el clip «sentado» respecto al origen
## de la persona (para sentar a la gente sobre el asiento de verdad).
func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	for i in 4:
		rng.seed = 100 + i
		var deporte: Array = [] if i < 2 else [Color.WHITE, Color.BLACK, true]
		var d := Mini3D.persona(self, rng, Vector3.ZERO, deporte)
		Mini3D.anim(d, OS.get_environment("CLIP") if OS.get_environment("CLIP") != "" else "sentado", "")
		for k in 20:
			await get_tree().process_frame
		var sk: Skeleton3D = (d["nodo"] as Node3D).find_children("*", "Skeleton3D", true, false)[0]
		var res := ""
		for hueso in ["hips", "Hips", "pelvis", "Pelvis", "foot.l", "Foot.L", "foot_l", "LeftFoot", "Head", "head"]:
			var b := sk.find_bone(hueso)
			if b >= 0:
				var g := sk.global_transform * sk.get_bone_global_pose(b)
				res += " %s=%s" % [hueso, str(g.origin.snapped(Vector3.ONE * 0.01))]
		print("SENTADO persona %d (deporte=%s):%s · estimada %.2f" % [i, str(i >= 2), res, InteriorInstalacion._altura_cadera(d["nodo"]) * 1.07])
		(d["nodo"] as Node3D).queue_free()
	get_tree().quit()
