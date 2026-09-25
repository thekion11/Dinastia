extends Node
## Lista TODOS los huesos del modelo actual (futbolista_cr7.glb) para saber si
## tiene dedos articulados o no -sin eso, ninguna animacion puede mover los
## dedos aunque quisiera-.
##
##   godot --headless --path . res://pruebas/diagnostico_huesos_actual.tscn

func _ready() -> void:
	var d := Futbolista.crear(1.80)
	add_child(d["nodo"])
	Futbolista.terminar(d)
	var esq: Skeleton3D = d["esqueleto"]
	print("huesos totales: ", esq.get_bone_count())
	for i in esq.get_bone_count():
		print("  hueso %d: %s" % [i, esq.get_bone_name(i)])
	print("--- reposo de dedos y pies (para ver si la garra viene de fabrica) ---")
	for clave in ["mixamorig_LeftHand", "mixamorig_LeftHandIndex1", "mixamorig_LeftHandIndex2",
			"mixamorig_LeftHandIndex3", "mixamorig_RightHand", "mixamorig_RightHandIndex1",
			"mixamorig_LeftToeBase", "mixamorig_RightToeBase"]:
		var idx := esq.find_bone(clave)
		if idx >= 0:
			var e := esq.get_bone_rest(idx).basis.get_euler() * (180.0 / PI)
			print("  %s: x=%.1f y=%.1f z=%.1f" % [clave, e.x, e.y, e.z])
	print("FIN. 0 fallos")
	get_tree().quit(0)
