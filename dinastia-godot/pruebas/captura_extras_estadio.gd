extends Node3D
## ESTADIO CON OBRAS, PALCOS, PRENSA, MUSEO, TIENDA Y MASCOTA (26-9-2026).
var _n := 0
var _cam: Camera3D

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 77)
	var c: Club = m.ligas[0].clubes[0]
	var est := c.perfil_estadio()
	est["en_obra"] = ["trib", "museo"]
	est["inst"] = {"cal": 6, "com": 4, "pren": 2, "museo": 3}
	est["exterior"] = true
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.72, 0.9)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.7, 0.72)
	env.environment = e
	add_child(env)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-45, 35, 0)
	sol.light_energy = 1.1
	add_child(sol)
	StadiumBuilder.build(self, est, 45000, 0.8, 7, c)
	_cam = Camera3D.new()
	_cam.far = 900.0
	add_child(_cam)
	_cam.position = Vector3(-150, 95, 150)
	_cam.look_at(Vector3(-20, 5, 20), Vector3.UP)
	_cam.current = true

func _process(_d: float) -> void:
	_n += 1
	if _n == 20:
		get_viewport().get_texture().get_image().save_png("res://pruebas/extras_estadio_dron.png")
		_cam.position = Vector3(20, 25, -60)
		_cam.look_at(Vector3(-40, 22, 10), Vector3.UP)
	if _n == 35:
		get_viewport().get_texture().get_image().save_png("res://pruebas/extras_estadio_palcos.png")
		_cam.position = Vector3(-29.0, 1.9, -9.5)
		_cam.fov = 40
		_cam.look_at(Vector3(-35.6, 1.4, -12.0), Vector3.UP)
	if _n == 50:
		get_viewport().get_texture().get_image().save_png("res://pruebas/extras_estadio_mascota.png")
		get_tree().quit()
