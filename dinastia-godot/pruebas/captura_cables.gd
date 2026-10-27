extends Node3D
## Línea de postes con cable combado. xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_cables.tscn → /tmp/cables_0.png
var _n := 0

func _ready() -> void:
	var b := CityBuilder.new()
	add_child(b)
	var ex := CiudadExpansion.new(b)
	var ts: Array[Transform3D] = []
	var ant := Vector3(-38, 0.24, 0)
	ex._prop_kenney("electricity-pole", ant, 0.0, 9.0)
	for k in 3:
		var sig := ant + Vector3(38, 0, 0)
		ex._prop_kenney("electricity-pole", sig, PI * 0.5, 9.0)
		ex._cable_entre(ant, sig, ts)
		ant = sig
	ex._multimesh(BoxMesh.new(), b._mat_simple(Color(0.06, 0.06, 0.07), 0.8), ts, Vector3.ONE)
	Mini3D.caja(self, Vector3(0, -0.1, 0), Vector3(300, 0.2, 60), Mini3D.mat(Color(0.35, 0.36, 0.35)))
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-45, 30, 0)
	add_child(sol)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.62, 0.74, 0.88)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.65, 0.68, 0.72)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(30, 3.2, 22)
	cam.look_at(Vector3(38, 4.4, 0), Vector3.UP)
	cam.make_current()

func _process(_d: float) -> void:
	_n += 1
	if _n == 12:
		get_viewport().get_texture().get_image().save_png("/tmp/cables_0.png")
		print("FIN. 0 fallos")
		get_tree().quit()
