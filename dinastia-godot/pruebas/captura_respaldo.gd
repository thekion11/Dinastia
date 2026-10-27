extends Node3D
## La butaca cercana (tres asientos) con el respaldo plano (arriba) y curvo (abajo), desde delante-arriba. → /tmp/respaldo_N.png
var _n := 0

func _ready() -> void:
	AjustesCiudad.guardar("tutorial_visto", true)
	var tmp: Node = (load("res://assets/ciudad/asientos_lod.glb") as PackedScene).instantiate()
	var malla: Mesh = StadiumBuilder._primera_malla(tmp)
	tmp.free()
	for k in 2:
		var mi := MeshInstance3D.new()
		mi.mesh = malla if k == 0 else RespaldoCurvo.curvar(malla)
		mi.position = Vector3(0, 0, -1.2 * float(k))
		add_child(mi)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-35, 60, 0)
	sol.light_energy = 0.6
	add_child(sol)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.62, 0.74, 0.88)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.65, 0.66, 0.7)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 40.0
	cam.position = Vector3(-0.05, 3.6, -0.55)
	cam.look_at(Vector3(-0.05, 0.3, -0.6), Vector3.BACK)
	cam.make_current()

func _process(_d: float) -> void:
	_n += 1
	if _n == 20:
		get_viewport().get_texture().get_image().save_png("/tmp/respaldo_0.png")
		get_tree().quit()
