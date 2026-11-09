extends Node3D
## Captura de las camisetas retiradas del museo, sin pasar por el explorador: una sala de prueba y la cámara mirando a la pared del fondo (−Z).
## xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_camisetas_museo.tscn
var _n := 0

func _ready() -> void:
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-50, 20, 0)
	add_child(luz)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.1, 0.1, 0.12)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.8, 0.8, 0.85)
	add_child(env)
	var sala := Node3D.new()
	add_child(sala)
	PiezasObra._caja(sala, Vector3(0, -0.05, 0), Vector3(6, 0.1, 8), PiezasObra._mat(Color(0.55, 0.38, 0.24), 0.8), false)
	PiezasObra._caja(sala, Vector3(0, 1.7, -3.95), Vector3(6, 3.4, 0.1), PiezasObra._mat(Color(0.75, 0.75, 0.72), 0.9), false)
	var ret: Array = [{"dorsal": 7, "nombre": "Carlos Valdivia", "anio": 2027}, {"dorsal": 10, "nombre": "Iván Pizarro", "anio": 2029}, {"dorsal": 5, "nombre": "Ricardo Ledesma", "anio": 2031}]
	CamisetasMuseo.poner(sala, Rect2(-2.5, -3.8, 5.0, 7.0), 0.0, Color(0.15, 0.55, 0.32), ret)
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(0, 1.7, 1.0)
	cam.look_at(Vector3(0, 1.9, -4.0))

func _process(_d: float) -> void:
	_n += 1
	if _n == 20:
		get_viewport().get_texture().get_image().save_jpg("/tmp/camisetas_museo.jpg", 0.88)
		print("CAPTURA OK")
		get_tree().quit()
