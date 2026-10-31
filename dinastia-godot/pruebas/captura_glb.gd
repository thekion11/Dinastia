extends Node3D
## Un glb de regalo desde 4 lados. GLB=res://... ESCALA=1 ALTO=y_de_la_cámara DIST=distancia. → /tmp/glb_N.png (0 = +Z, 1 = +X, 2 = -Z, 3 = -X)
var _n := 0
var _cam: Camera3D
var _c := Vector3.ZERO
var _d := 5.0

func _ready() -> void:
	AjustesCiudad.guardar("tutorial_visto", true)
	Mini3D.caja(self, Vector3(0, -0.05, 0), Vector3(80, 0.1, 80), Mini3D.mat(Color(0.4, 0.45, 0.4)))
	var ps := load(OS.get_environment("GLB")) as PackedScene
	var n := ps.instantiate() as Node3D
	var e := float(OS.get_environment("ESCALA")) if OS.get_environment("ESCALA") != "" else 1.0
	n.scale = Vector3.ONE * e
	add_child(n)
	var ab := AABB()
	var primero := true
	for m in n.find_children("*", "MeshInstance3D", true, false):
		var a: AABB = (m as MeshInstance3D).global_transform * (m as MeshInstance3D).get_aabb()
		ab = a if primero else ab.merge(a)
		primero = false
	_c = ab.get_center()
	_d = float(OS.get_environment("DIST")) if OS.get_environment("DIST") != "" else maxf(ab.size.x, maxf(ab.size.y, ab.size.z)) * 1.8
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-45, 35, 0)
	add_child(sol)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.62, 0.74, 0.88) if OS.get_environment("NOCHE") != "1" else Color(0.02, 0.03, 0.06)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.7, 0.72) if OS.get_environment("NOCHE") != "1" else Color(0.05, 0.06, 0.1)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	if OS.get_environment("NOCHE") == "1":
		sol.light_energy = 0.04
	_cam = Camera3D.new()
	add_child(_cam)
	_cam.fov = 40.0
	_cam.make_current()
	_vista(0)

func _vista(i: int) -> void:
	var dir := [Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(-1, 0, 0)][i] as Vector3
	var alto := float(OS.get_environment("ALTO")) if OS.get_environment("ALTO") != "" else _c.y
	_cam.position = Vector3(_c.x, alto, _c.z) + dir * _d
	_cam.look_at(_c, Vector3.UP)

func _process(_dt: float) -> void:
	_n += 1
	var pref := OS.get_environment("PREFIJO") if OS.get_environment("PREFIJO") != "" else "/tmp/glb"
	for i in 4:
		if _n == 15 + i * 8:
			get_viewport().get_texture().get_image().save_png("%s_%d.png" % [pref, i])
			if i < 3:
				_vista(i + 1)
	if _n > 52:
		get_tree().quit()
