extends Node
## Solo la cabina (CabinaCoche) con una calle de pega, para iterar el diseño sin cargar la ciudad. NO corre con --headless:
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_cabina_sola.tscn → /tmp/cabina_sola.png
var _n := 0

func _ready() -> void:
	var cam := Camera3D.new()
	cam.fov = 70.0
	add_child(cam)
	cam.make_current()
	cam.position = Vector3(0, 1.12, 0)
	var cab := Node3D.new()
	cam.add_child(cab)
	var r := CabinaCoche.montar(cab)
	(r["volante"] as Node3D).basis = Basis(Vector3.RIGHT, deg_to_rad(70.0))
	(r["kmh"] as Label3D).text = "48 km/h"
	var suelo := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	pl.size = Vector2(200, 200)
	suelo.mesh = pl
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.3, 0.3, 0.32)
	suelo.material_override = m
	add_child(suelo)
	for k in 6:
		var b := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(10, 14 + k * 3, 10)
		b.mesh = bm
		var mb := StandardMaterial3D.new()
		mb.albedo_color = Color(0.8, 0.6 + k * 0.05, 0.5)
		b.material_override = mb
		b.position = Vector3(-20 if k % 2 == 0 else 20, 7, -20 - k * 14)
		add_child(b)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, 30, 0)
	add_child(sol)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.6, 0.75, 0.9)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.65, 0.7)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

func _process(_d: float) -> void:
	_n += 1
	if _n == 8:
		get_viewport().get_texture().get_image().save_png("/tmp/cabina_sola.png")
		get_tree().quit()
