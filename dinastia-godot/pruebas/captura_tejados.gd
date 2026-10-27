extends Node3D
## Los cuatro tipos de tejado desde el aire. xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_tejados.tscn → /tmp/tejados_N.png
var _n := 0
var _cam: Camera3D

func _ready() -> void:
	var b := CityBuilder.new()
	add_child(b)
	var ex := CiudadExpansion.new(b)
	var colocados := {}
	var sem := 100
	var x := 0.0
	while colocados.size() < 4 and sem < 400:
		var pisos_prueba := 3
		var t := TejadoTipo.tipo_de(sem, pisos_prueba)
		sem += 1
		if colocados.has(t):
			continue
		colocados[t] = true
		ex._bloque_modular(Vector3(x, 0.24, 0.0), 0.0, sem - 1, 20.0, 14.0, {"pisos": pisos_prueba, "w": 3, "d": 2})
		x += 22.0
	ex._modular_multimesh()
	var suelo := Mini3D.caja(self, Vector3(40, -0.2, -5), Vector3(160, 0.4, 80), Mini3D.mat(Color(0.3, 0.32, 0.3)))
	suelo.name = "Suelo"
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, 30, 0)
	add_child(sol)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.62, 0.74, 0.88)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.65, 0.68, 0.72)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	_cam = Camera3D.new()
	_cam.far = 600.0
	add_child(_cam)
	_cam.position = Vector3(33, 34, 38)
	_cam.look_at(Vector3(33, 6, -4), Vector3.UP)
	set_meta("cam", _cam)
	_cam.make_current()

func _process(_d: float) -> void:
	_n += 1
	if _n == 12:
		get_viewport().get_texture().get_image().save_png("/tmp/tejados_0.png")
		_cam.position = Vector3(44, 2.0, 30)   ## a pie de calle: puertas, arriates, carteles, aires y grafitis
		_cam.look_at(Vector3(44, 1.6, 0), Vector3.UP)
	if _n == 24:
		get_viewport().get_texture().get_image().save_png("/tmp/tejados_1.png")
		print("FIN. 0 fallos")
		get_tree().quit()
