extends Node3D
## Banderas grandes del gol sobre una grada de relleno, vistas desde la cámara de TV (a ~80 m) y de cerca. → /tmp/bgrada_<n>.png
var _n := 0

func _ready() -> void:
	var amb := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.7, 0.85)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.6, 0.6)
	amb.environment = e
	add_child(amb)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-40, 30, 0)
	add_child(sol)
	Mini3D.caja(self, Vector3(0, -0.1, 0), Vector3(200, 0.2, 140), Mini3D.mat(Color(0.2, 0.5, 0.22)))
	for k in 8:   ## la grada de casa: escalones grises al fondo (x = +45)
		Mini3D.caja(self, Vector3(45 + k * 1.6, 0.5 + k * 0.9, 0), Vector3(1.6, 1.0 + k * 1.8, 60), Mini3D.mat(Color(0.55, 0.55, 0.6)))
	BanderasGrada.lanzar(self, Color(0.8, 0.07, 0.15), Color(1, 1, 1), [Vector3(52, 6, -16), Vector3(52, 6, 0), Vector3(52, 6, 16)], 30.0)
	var cam := Camera3D.new()
	add_child(cam)
	cam.make_current()
	cam.fov = 40.0
	cam.position = Vector3(-35, 14, 4)
	cam.look_at(Vector3(52, 9, 0), Vector3.UP)

func _process(_d: float) -> void:
	_n += 1
	if _n == 30:
		get_viewport().get_texture().get_image().save_png("/tmp/bgrada_0.png")
		var cam := get_viewport().get_camera_3d()
		cam.fov = 60.0
		cam.position = Vector3(30, 4, -8)
		cam.look_at(Vector3(52, 9, 0), Vector3.UP)
	if _n == 40:
		get_viewport().get_texture().get_image().save_png("/tmp/bgrada_1.png")
		get_tree().quit()
