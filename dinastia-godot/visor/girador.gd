class_name Girador
extends Node3D
## Gira sobre su eje Z local a `vel` rad/s (las aspas de los molinos).
var vel := 1.2

func _process(delta: float) -> void:
	rotate_object_local(Vector3.FORWARD, vel * delta)
