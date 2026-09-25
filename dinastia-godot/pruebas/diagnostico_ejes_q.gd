extends Node
## Antes de escribir ni una animacion para el esqueleto Quaternius, hay que
## saber como estan plantados los huesos en reposo -mismo principio que ya
## costo caro en AnimMixamo ("darlo por hecho es lo que hace que un
## personaje acabe corriendo con las rodillas del reves").
##
##   godot --headless --path . res://pruebas/diagnostico_ejes_q.tscn

func _ready() -> void:
	var d := FutbolistaQ.crear(1.80)
	add_child(d["nodo"])
	FutbolistaQ.terminar(d)
	var esq: Skeleton3D = d["esqueleto"]
	for hueso in ["pelvis", "spine_01", "spine_02", "spine_03", "neck_01", "Head",
			"clavicle_l", "upperarm_l", "lowerarm_l", "hand_l",
			"clavicle_r", "upperarm_r", "lowerarm_r", "hand_r",
			"thigh_l", "calf_l", "foot_l", "ball_l",
			"thigh_r", "calf_r", "foot_r", "ball_r"]:
		var i := esq.find_bone(hueso)
		if i < 0:
			print("FALTA: ", hueso)
			continue
		var e := esq.get_bone_rest(i).basis.get_euler() * (180.0 / PI)
		var pos := esq.get_bone_rest(i).origin
		print("%s: rot x=%.1f y=%.1f z=%.1f  pos=%s" % [hueso, e.x, e.y, e.z, pos])
	print("FIN. 0 fallos")
	get_tree().quit(0)
