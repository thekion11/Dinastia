extends "res://ui/estadio_p5_p1.gd"
## (Parte 2 de 2 de `estadio_p5.gd`.)

func _despejar_rotulos(delta: float) -> void:
	if not PlayerSpawner.mostrar_nombres:
		return
	_t_despeje -= delta
	if _t_despeje > 0.0:
		return
	_t_despeje = 0.1
	var bpos := _balon.global_position if is_instance_valid(_balon) else Vector3.ZERO
	PlayerSpawner.despejar_rotulos(_en_campo, get_viewport().get_camera_3d(), bpos, get_viewport().get_visible_rect().size.y)

func _energia_motor(f: Dictionary) -> float:
	if _motor == null:
		return -1.0
	var id := String(f.get("id", ""))
	for p: Dictionary in _motor.jugadores:
		if p.get("node") == f.get("node") or (id != "" and String(p.get("id", "")) == id):
			return _motor.forma_fisica(p)
	return -1.0
