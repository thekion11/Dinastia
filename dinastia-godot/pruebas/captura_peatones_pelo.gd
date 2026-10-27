extends Node3D
## 12 peatones en fila con la cámara a pie (cabeza y hombros). SIN_PELO_DRIVE=1 = antes. → /tmp/peatones_pelo_<antes|despues>_<0|1>.png
var _n := 0
var _cam: Camera3D

func _ready() -> void:
	AjustesCiudad.guardar("tutorial_visto", true)
	Mini3D.caja(self, Vector3(0, -0.1, 0), Vector3(60, 0.2, 60), Mini3D.mat(Color(0.5, 0.5, 0.48)))
	for k in 12:
		var d := PeatonVida.nuevo(self, 200 + k)
		var n := d["nodo"] as Node3D
		n.position = Vector3(float(k % 6) * 1.1, 0, -float(k / 6) * 1.6)
		n.rotation.y = 0.35
		Mini3D.anim(d, "parado", "")
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-45, 30, 0)
	add_child(sol)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.62, 0.74, 0.88)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.65, 0.66, 0.7)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	_cam = Camera3D.new()
	add_child(_cam)
	_cam.fov = 28.0
	_cam.make_current()
	_cam.position = Vector3(2.75, 1.7, 8.5)
	_cam.look_at(Vector3(2.75, 1.55, -0.8), Vector3.UP)

func _process(_d: float) -> void:
	_n += 1
	var tag := "antes" if OS.get_environment("SIN_PELO_DRIVE") != "" else "despues"
	if _n == 25:
		get_viewport().get_texture().get_image().save_png("/tmp/peatones_pelo_%s_0.png" % tag)
		_cam.position = Vector3(2.75, 1.7, 3.5)
		_cam.look_at(Vector3(2.75, 1.58, -0.8), Vector3.UP)
		_cam.fov = 18.0
	if _n == 40:
		get_viewport().get_texture().get_image().save_png("/tmp/peatones_pelo_%s_1.png" % tag)
		get_tree().quit()
