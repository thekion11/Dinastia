class_name ExploradorCiudad
extends "res://visor/explorador_ciudad_p5.gd"
## [Capa 6/6 de `explorador_ciudad.gd`] _exit_tree

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if trafico != null and is_instance_valid(trafico):
		trafico.jugador = null
	_bajo_tierra(false)
	_rotulos_de_paseo(false)
