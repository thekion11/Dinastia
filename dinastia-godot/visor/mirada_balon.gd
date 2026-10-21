class_name MiradaBalon
extends RefCounted
## LA CABEZA SIGUE AL BALÓN (M-098, 21-10-2026). Un `LookAtModifier3D` en el
## hueso Head de cada jugador del partido, apuntando al balón: gira el cuello
## (con topes de 65° a los lados y 30° arriba/abajo, y medio segundo de
## suavizado) DESPUÉS de la animación, así corre, patea o celebra igual pero
## mirando la jugada. El modificador lo pone Godot: no cuesta script por
## fotograma. Se puede mover el eje con `eje` si un modelo nuevo mira a otro lado.
##   MiradaBalon.poner(jugadores_del_motor, balon)

static var eje := SkeletonModifier3D.BONE_AXIS_PLUS_Z

static func poner(jugadores: Array, balon: Node3D) -> int:
	if balon == null:
		return 0
	var n := 0
	for p: Dictionary in jugadores:
		var nodo: Node = p.get("node")
		if is_instance_valid(nodo) and poner_en(nodo, balon):
			n += 1
	return n

static func poner_en(nodo: Node, objetivo: Node3D) -> bool:
	var esqs := nodo.find_children("*", "Skeleton3D", true, false)
	if esqs.is_empty():
		return false
	var esq := esqs[0] as Skeleton3D
	if esq.find_bone("Head") < 0 or esq.get_node_or_null("MiradaBalon") != null:
		return false
	var m := LookAtModifier3D.new()
	m.name = "MiradaBalon"
	esq.add_child(m)
	m.bone_name = "Head"
	m.forward_axis = eje
	m.primary_rotation_axis = Vector3.AXIS_Y
	m.use_secondary_rotation = true
	m.use_angle_limitation = true
	m.symmetry_limitation = true
	m.primary_limit_angle = deg_to_rad(65.0)
	m.secondary_limit_angle = deg_to_rad(30.0)
	m.duration = 0.5
	m.influence = 0.85
	m.target_node = m.get_path_to(objetivo)
	return true
