extends Node3D
## Peatones con maletín (M-183), de frente y de perfil. → /tmp/maletin_<n>.png
var _n := 0

func _ready() -> void:
	AjustesCiudad.guardar("tutorial_visto", true)
	Mini3D.caja(self, Vector3(0, -0.1, 0), Vector3(40, 0.2, 40), Mini3D.mat(Color(0.5, 0.5, 0.48)))
	for k in 3:
		var d := PeatonVida.nuevo(self, 40 + k * 9)
		(d["nodo"] as Node3D).position = Vector3(-1.2 + float(k) * 1.2, 0, 0)
		(d["nodo"] as Node3D).rotation.y = 0.5 * float(k - 1)
		PeatonVida.maletin({"nodo": d["nodo"], "id": k}, true)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-45, 25, 0)
	add_child(sol)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.62, 0.74, 0.88)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.7, 0.75)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var cam := Camera3D.new()
	cam.fov = 40.0
	add_child(cam)
	cam.make_current()
	cam.position = Vector3(3.0, 1.2, 4.2)
	cam.look_at(Vector3(0, 0.9, 0), Vector3.UP)

func _process(_d: float) -> void:
	_n += 1
	if _n == 12:
		get_viewport().get_texture().get_image().save_png("/tmp/maletin_0.png")
		get_tree().quit()
