extends Node3D
## ¿Hacia qué lado va cada movimiento? Compara la pelvis con la mano izquierda
## de reposo (que marca el lado izquierdo del jugador).
func _ready() -> void:
	var d := FutbolistaQ.crear(1.8, "male")
	var raiz: Node3D = d["nodo"]
	add_child(raiz)
	FutbolistaQ.terminar(d, true)
	var esq: Skeleton3D = raiz.find_children("*", "Skeleton3D", true, false)[0]
	var ap: AnimationPlayer = d["anim"]
	var mano_i := esq.get_bone_global_rest(esq.find_bone("hand_l")).origin
	var pel0 := esq.get_bone_global_rest(esq.find_bone("pelvis")).origin
	print("mano izquierda en reposo: ", mano_i, "  pelvis: ", pel0)
	var hom := esq.get_bone_global_rest(esq.find_bone("upperarm_r")).origin
	var homi := esq.get_bone_global_rest(esq.find_bone("upperarm_l")).origin
	var pre := str(ap.get_node(ap.root_node).get_path_to(esq))
	var lib := AnimationLibrary.new()
	var casos := {"dx+": ["d", Vector3(80, 0, 0)], "dx-": ["d", Vector3(-80, 0, 0)], "dz+": ["d", Vector3(0, 0, 80)], "dz-": ["d", Vector3(0, 0, -80)],
		"ix+": ["i", Vector3(80, 0, 0)], "ix-": ["i", Vector3(-80, 0, 0)], "iz+": ["i", Vector3(0, 0, 80)], "iz-": ["i", Vector3(0, 0, -80)], "d0": ["d", Vector3.ZERO], "i0": ["i", Vector3.ZERO]}
	for n: String in casos:
		var lado: String = casos[n][0]
		var an := AnimQuaternius._nueva(1.0, false)
		var b0 := AnimExtra._brazo(lado, 60, 10)
		AnimQuaternius._pista(an, esq, "brazo_" + lado, [[0.0, b0], [1.0, b0]], pre)
		AnimQuaternius._pista(an, esq, "antebrazo_" + lado, [[0.0, casos[n][1]], [1.0, casos[n][1]]], pre)
		lib.add_animation(n, an)
	ap.add_animation_library("sd", lib)
	for n: String in casos:
		ap.play("sd/" + n)
		ap.seek(0.5, true)
		var dd := n.begins_with("d")
		var m := esq.get_bone_global_pose(esq.find_bone("hand_r" if dd else "hand_l")).origin - (hom if dd else homi)
		print("%s  mano rel. hombro: lado %.2f alto %.2f adelante %.2f  dist %.2f" % [n, m.x, m.y, m.z, m.length()])
	get_tree().quit()
