extends Node
## Mide la altura real (Y global) de la cadera ("pelvis") en reposo de
## FutbolistaQ, para calibrar cuanto hay que bajar la raiz del modelo en una
## pose sentada (22-9-2026, "el banquillo se puede ver mejor" -pedido del
## usuario tras ver las capturas del banquillo de pie-). Sin medir esto se
## repite el mismo error ya documentado una vez con ALTO_PIVOTE del modelo
## viejo: un numero adivinado, no medido.
##
##   godot --path . --rendering-driver opengl3 --headless res://pruebas/diagnostico_altura_cadera_q.tscn

func _ready() -> void:
	var d: Dictionary = FutbolistaQ.crear(1.85, "male")
	if d.is_empty():
		print("MAL: no cargo FutbolistaQ")
		get_tree().quit(1)
		return
	add_child(d["nodo"])
	FutbolistaQ.terminar(d, true)
	var esq: Skeleton3D = d.get("esqueleto")
	if esq == null:
		## Buscar el Skeleton3D a mano si el diccionario no lo trae directo.
		esq = _buscar_esq(d["nodo"])
	if esq == null:
		print("MAL: no encontre el Skeleton3D")
		get_tree().quit(1)
		return
	var i := esq.find_bone("pelvis")
	if i < 0:
		print("MAL: no encontre el hueso 'pelvis'")
		get_tree().quit(1)
		return
	var xf := esq.global_transform * esq.get_bone_global_pose(i)
	print("cadera (pelvis) Y global: %.3f m  (altura del modelo: %.2f m)" % [xf.origin.y, 1.85])
	var pie_i := esq.find_bone("foot_l")
	if pie_i >= 0:
		var xf_pie := esq.global_transform * esq.get_bone_global_pose(pie_i)
		print("pie_i (foot_l) Y global: %.3f m" % xf_pie.origin.y)
	print("FIN. 0 fallos")
	get_tree().quit()

func _buscar_esq(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var r := _buscar_esq(c)
		if r:
			return r
	return null
