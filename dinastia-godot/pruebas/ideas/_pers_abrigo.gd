extends Node3D
## Captura (agente pers): el abrigo del DT, de frente, de lado y de espaldas.
var _n := 0

func _ready() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.2, 0.22, 0.26)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.7, 0.72)
	env.environment = e
	add_child(env)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-35, 20, 0)
	sol.light_energy = 1.2
	add_child(sol)
	var asp := [
		{"cuerpo": "female", "altura": 1.68, "ropa": "abrigo", "c_ropa": "6a1b2a", "pelo": "melena", "color_pelo": "7a5230"},
		{"ropa": "abrigo", "c_ropa": "3a3f4a", "corbata": true},
	]
	var giros := [0.0, 90.0, 180.0]
	for i in 6:
		var raiz := Node3D.new()
		raiz.position = Vector3((i - 2.5) * 0.85, 0, 0)
		raiz.rotation_degrees.y = giros[i % 3]
		add_child(raiz)
		PersonajeDT.crear(raiz, (asp[i / 3] as Dictionary).duplicate(), Color("c62828"), Color.WHITE)
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 40
	cam.position = Vector3(0, 1.0, 4.4)
	cam.look_at(Vector3(0, 0.9, 0), Vector3.UP)

func _process(_d: float) -> void:
	_n += 1
	if _n == 12:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/pers_abrigo.png")
		get_tree().quit()
