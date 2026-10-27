extends Node3D
## Autobús con cristales tintados y gente dentro. → /tmp/bus_interior.png
var _n := 0

func _ready() -> void:
	AjustesCiudad.guardar("tutorial_visto", true)
	Mini3D.caja(self, Vector3(0, -0.1, 0), Vector3(60, 0.2, 60), Mini3D.mat(Color(0.4, 0.4, 0.42)))
	var bus := CityBuilder.autobus(Color(0.85, 0.3, 0.2), "Centro", "12")
	add_child(bus)
	bus.set_meta("pasajeros", [3, 9, 12, 21, 34, 55, 70])
	InteriorBus.actualizar(bus)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, -40, 0)
	add_child(sol)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.62, 0.74, 0.88)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.62, 0.66)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(9.0, 3.2, 3.0)
	cam.look_at(Vector3(0, 2.0, 0), Vector3.UP)
	cam.make_current()

func _process(_d: float) -> void:
	_n += 1
	if _n == 40:
		get_viewport().get_texture().get_image().save_png("/tmp/bus_interior.png")
		get_tree().quit()
