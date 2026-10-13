extends Node
## Fila de peatones de cerca, de frente y de espalda (etapa 4: complexión y
## accesorios). Salida: pruebas/capturas/peatones_fila.png
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1600x700 res://pruebas/captura_peatones.tscn
var _n := 0
var _cam: Camera3D

func _ready() -> void:
	var raiz := Node3D.new()
	add_child(raiz)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.65, 0.78)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.82, 0.9)
	env.ambient_light_energy = 0.6
	we.environment = env
	raiz.add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-45, 30, 0)
	raiz.add_child(sol)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 20)
	suelo.mesh = pm
	raiz.add_child(suelo)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(OS.get_environment("SEMILLA")) if OS.get_environment("SEMILLA") != "" else 77
	var ds: Array = []
	for fila in 2:
		for i in 8:
			var d := PeatonQ.crear(rng)
			var nodo: Node3D = d["nodo"]
			nodo.position = Vector3((i - 3.5) * 1.5, 0, fila * 3.0 - 1.5)
			nodo.rotation.y = PI if fila == 1 else 0.0
			raiz.add_child(nodo)
			PeatonQ.terminar(d)
			ds.append(d)
	_cam = Camera3D.new()
	_cam.fov = 40
	raiz.add_child(_cam)
	_cam.position = Vector3(0, 1.5, float(OS.get_environment("DIST")) if OS.get_environment("DIST") != "" else 11.0)
	_cam.look_at(Vector3(0, 0.95, 0))

func _process(_d: float) -> void:
	_n += 1
	if _n == 12:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/peatones_fila.png")
		get_tree().quit()
