extends Node
## Averigua la ruta interna que usan las pistas de animacion del GLB real
## (AnimationPlayer.root_node, y el NodePath completo de una pista de
## "Idle"), para saber que reemplazar al re-apuntarlas a nuestro esqueleto.

func _ready() -> void:
	var d := FutbolistaQ.crear(1.80)
	add_child(d["nodo"])
	var ap: AnimationPlayer = d["anim"]
	var esq: Skeleton3D = d["esqueleto"]
	print("prefijo real (ap.get_path_to(esq)) = ", ap.get_path_to(esq))
	get_tree().quit(0)

func _buscar_ap(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r := _buscar_ap(c)
		if r:
			return r
	return null
