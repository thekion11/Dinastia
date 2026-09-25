extends Node3D
## Prueba de FutbolistaQ.crear()/terminar(): que el jugador Quaternius quede
## de pie, del alto correcto, con los pies en el cesped -sin animar todavia,
## solo la integracion de escala y posicion.
##
##   godot --path . --rendering-driver opengl3 --position 0,0 res://pruebas/diagnostico_futbolista_q.tscn

func _ready() -> void:
	var env := Node3D.new()
	add_child(env)
	var amb := WorldEnvironment.new()
	var ent := Environment.new()
	ent.background_mode = Environment.BG_COLOR
	ent.background_color = Color(0.05, 0.06, 0.07)
	ent.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ent.ambient_light_color = Color(0.3, 0.3, 0.32)
	ent.ambient_light_energy = 0.6
	amb.environment = ent
	env.add_child(amb)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-50, -30, 0)
	luz.light_energy = 1.2
	env.add_child(luz)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.0, 3.5)
	cam.fov = 40
	env.add_child(cam)
	cam.look_at(Vector3(0, 0.9, 0), Vector3.UP)
	cam.current = true
	var piso := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(6, 6)
	piso.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.5, 0.25)
	piso.material_override = mat
	env.add_child(piso)
	# Una marca en Y=0 y Y=1.85 para verificar a ojo la altura real contra la cuadricula.
	for h in [0.0, 0.9, 1.85]:
		var marca := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(6.2, 0.01, 0.01)
		marca.mesh = bm
		marca.position = Vector3(0, h, 0)
		var mm := StandardMaterial3D.new()
		mm.albedo_color = Color(1, 0, 0) if h == 1.85 else Color(1, 1, 0)
		mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		marca.material_override = mm
		env.add_child(marca)

	# Jugador de 1.85m, como pediria una ficha real de central.
	var d := FutbolistaQ.crear(1.85)
	if d.is_empty():
		print("FutbolistaQ.crear() fallo")
		get_tree().quit(1)
		return
	add_child(d["nodo"])
	FutbolistaQ.terminar(d)
	print("modelo escalado x%.4f, posicion final: %s" % [(d["modelo"] as Node3D).scale.x, (d["modelo"] as Node3D).position])

	get_tree().create_timer(0.3).timeout.connect(func():
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/futbolista_q_de_pie.png")
		print("captura guardada")
		print("FIN. 0 fallos")
		get_tree().quit(0))
