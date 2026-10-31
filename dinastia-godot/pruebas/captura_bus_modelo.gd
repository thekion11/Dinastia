extends Node3D
## El autobús «Red» de cerca, a la altura de una persona: 3/4 delantero, costado de la acera y 3/4 trasero. → /tmp/busm_<n>.png
var _n := 0
const VISTAS := [[Vector3(7.5, 1.7, 9.0), Vector3(0, 1.6, 1.0)], [Vector3(-9.0, 1.7, 1.5), Vector3(0, 1.6, 0.5)], [Vector3(-7.0, 1.7, -10.0), Vector3(0, 1.6, -1.0)]]

func _ready() -> void:
	Mini3D.caja(self, Vector3(0, -0.1, 0), Vector3(60, 0.2, 60), Mini3D.mat(Color(0.35, 0.35, 0.37)))
	var bus := CityBuilder.autobus(Color(0.0, 0.47, 0.75), "122 · ESTADIO", "122")
	add_child(bus)
	var noche := OS.get_environment("NOCHE") == "1"
	if noche:
		AutobusModelo.encender(bus, 1.0)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-45, 35, 0)
	sol.light_energy = 0.12 if noche else 1.0
	sol.light_color = Color(0.6, 0.7, 1.0) if noche else Color.WHITE
	add_child(sol)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.03, 0.06) if noche else Color(0.62, 0.74, 0.88)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.18, 0.2, 0.3) if noche else Color(0.7, 0.7, 0.75)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var cam := Camera3D.new()
	cam.fov = 55.0
	add_child(cam)
	cam.make_current()

func _process(_d: float) -> void:
	_n += 1
	var i := _n / 6
	if i >= VISTAS.size() + 0:
		get_tree().quit()
		return
	var cam := get_viewport().get_camera_3d()
	if _n % 6 == 1:
		cam.global_position = VISTAS[i][0]
		cam.look_at(VISTAS[i][1], Vector3.UP)
	if _n % 6 == 5:
		get_viewport().get_texture().get_image().save_png("/tmp/busm_%s%d.png" % ["n" if OS.get_environment("NOCHE") == "1" else "", i])
