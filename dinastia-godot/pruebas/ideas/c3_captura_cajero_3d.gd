extends Node3D
## El cajero 3D suelto (pieza B de §2.2h), de frente y de tres cuartos, con luz de día. `herramientas/captura.sh res://pruebas/ideas/c3_captura_cajero_3d.tscn`
var _n := 0
var _cam: Camera3D

func _ready() -> void:
	var cb := CityBuilder.new()
	add_child(cb)
	var ex := CiudadExpansion.new(cb)
	CajeroCiudad.montar(ex, Vector3.ZERO, 0.0)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(12, 12)
	suelo.mesh = pm
	add_child(suelo)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, 30, 0)
	add_child(sol)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.6, 0.75, 0.9)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.75)
	add_child(env)
	_cam = Camera3D.new()
	add_child(_cam)
	_cam.position = Vector3(1.6, 1.5, 3.4)
	_cam.look_at(Vector3(0, 1.2, 0))

func _process(_d: float) -> void:
	_n += 1
	if _n == 8:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/cajero_3d.png")
		print("CAPTURA OK")
		get_tree().quit()
