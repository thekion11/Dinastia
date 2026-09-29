extends Node
## Mira de cerca y aislado el modelo "oficina_dt.glb" (casa boceto que trajo
## el usuario) antes de confiar en como se ve dentro de la ciudad: la primera
## captura de la ciudad lo mostro como una masa de formas superpuestas, y hay
## que saber si es un problema de escala/posicion o si el modelo en si mismo
## no sirve para verse desde fuera -viene de un pack llamado "interior", asi
## que podria ser habitaciones vueltas del reves, no una fachada-.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_oficina_dt.tscn

var _n := 0

func _ready() -> void:
	var we := Calidad.entorno(Calidad.ALTO, Calidad.DIA)
	add_child(we)
	add_child(Calidad.sol(Calidad.ALTO, Calidad.DIA))
	var esc := load("res://assets/ciudad/oficina_dt.glb")
	var n: Node3D = (esc as PackedScene).instantiate()
	add_child(n)
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(12, 8, 12)
	cam.look_at(Vector3(0, 2, 0), Vector3.UP)
	print("nodo raiz: ", n.name, " hijos: ", n.get_child_count())
	_listar(n, 0)
	var caja := AABB()
	var primero := true
	for m in _mallas(n):
		var a: AABB = (m as MeshInstance3D).mesh.get_aabb() if (m as MeshInstance3D).mesh != null else AABB()
		a = (m as MeshInstance3D).transform * a
		if primero:
			caja = a
			primero = false
		else:
			caja = caja.merge(a)
	print("AABB tamano=", caja.size, " posicion=", caja.position)

func _mallas(n: Node) -> Array:
	var s: Array = []
	if n is MeshInstance3D:
		s.append(n)
	for h in n.get_children():
		s.append_array(_mallas(h))
	return s

func _listar(n: Node, prof: int) -> void:
	if prof > 3:
		return
	print("  ".repeat(prof), n.name, " (", n.get_class(), ")")
	for h in n.get_children():
		_listar(h, prof + 1)

func _process(_d: float) -> void:
	_n += 1
	if _n == 20:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/pantalla_oficina_dt_aislada.png")
		print("captura guardada")
	if _n == 24:
		get_tree().quit()
