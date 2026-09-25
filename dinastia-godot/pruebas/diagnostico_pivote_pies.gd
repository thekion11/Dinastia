extends Node
## El usuario reporto y una captura real confirmo (postura_parado_lado_zoom_pies.png,
## 21-9-2026): los pies del modelo viejo quedan hundidos en el cesped, sin zapato
## visible. `Futbolista.escalar()` sube el modelo `altura * ALTO_PIVOTE` con
## `ALTO_PIVOTE := 0.5` -un numero puesto "a ojo" ("a media altura"), no medido-.
## Mide el pivote REAL usando la posicion global del hueso del pie/dedo en la
## pose de reposo -mas confiable que el AABB de una malla con Skeleton (ese
## devuelve la caja SIN deformar, no sirve aqui).

func _ready() -> void:
	var d := Futbolista.crear(1.80)
	add_child(d["nodo"])
	Futbolista.terminar(d)
	var raiz: Node3D = d["nodo"]
	var esq: Skeleton3D = d["esqueleto"]
	## Deshace el offset Y que aplico escalar(), para medir con el origen del
	## modelo en Y=0 -la misma referencia que usa ALTO_PIVOTE.
	raiz.position.y = 0.0
	raiz.force_update_transform()

	for hueso in ["mixamorig_Hips", "mixamorig_LeftFoot", "mixamorig_LeftToeBase", "mixamorig_RightFoot", "mixamorig_RightToeBase"]:
		var i := esq.find_bone(hueso)
		if i < 0:
			print(hueso, ": no encontrado")
			continue
		var pose_local := esq.get_bone_global_pose(i)
		var pos_mundo: Vector3 = esq.global_transform * pose_local.origin
		print("%s: y_mundo=%.4f" % [hueso, pos_mundo.y])

	## altura conocida del modelo (medida con ESCALA_A_METRO): 1.80m para
	## Futbolista.crear(1.80). El pivote real = cuanto hay que subir el origen
	## (fraccion de la altura) para que el punto mas bajo del pie llegue a Y=0.
	print("FIN. 0 fallos")
	get_tree().quit(0)
