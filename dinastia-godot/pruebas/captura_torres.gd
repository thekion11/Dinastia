extends Node3D
## Las torres de focos del estadio. SIN_TORRE_DRIVE=1 = antes; NOCHE=1 = de noche. → /tmp/torres_<antes|despues>[_noche]_<0|1>.png (0 = toma alta de TV, 1 = una torre de cerca)
var _n := 0
var _cam: Camera3D
var _torre := Vector3.ZERO

func _ready() -> void:
	AjustesCiudad.guardar("tutorial_visto", true)
	Calidad.elegida = Calidad.ALTO
	var club := Club.new("tf_club", "Club TF")
	club.color1 = "#1f4f9a"
	club.color2 = "#f2f2f2"
	StadiumBuilder.build(self, {"forma": "cuenco", "niveles": 2, "techo": "anillo", "focos": "torres", "aforo": 40000}, 40000, 0.4, 4242, club)
	var noche := OS.get_environment("NOCHE") == "1"
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-45, 35, 0)
	sol.light_energy = 0.04 if noche else 1.0
	add_child(sol)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.62, 0.74, 0.88) if not noche else Color(0.02, 0.03, 0.06)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.7, 0.72) if not noche else Color(0.05, 0.06, 0.1)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var mejor := 1e9
	for hijo in get_children():
		if hijo is MeshInstance3D and (hijo as MeshInstance3D).mesh is CylinderMesh and (hijo as MeshInstance3D).position.y > 10.0:
			pass
	## La torre de la esquina +X +Z: la más alta de las que cuelgan de la raíz (del modelo o el poste de siempre).
	var mx := -1.0
	for hijo in get_children():
		if hijo is Node3D and (hijo.name == "TorreFocos" or (hijo is MeshInstance3D and (hijo as MeshInstance3D).mesh is CylinderMesh and (hijo as MeshInstance3D).position.y > 10.0)):
			var p := (hijo as Node3D).position
			var base := Vector3(p.x, 0, p.z)
			if base.x > 0.0 and base.z > 0.0 and base.x + base.z > mx:
				mx = base.x + base.z
				_torre = base
	_cam = Camera3D.new()
	add_child(_cam)
	_cam.fov = 55.0
	_cam.make_current()
	_vista(0)

func _vista(i: int) -> void:
	if i == 0:
		_cam.position = Vector3(-60, 22, -70)
		_cam.look_at(Vector3(_torre.x * 0.8, 18, _torre.z * 0.8), Vector3.UP)
	else:
		_cam.position = _torre + Vector3(-12, 22, -16)
		_cam.look_at(_torre + Vector3(0, 28, 0), Vector3.UP)

func _process(_d: float) -> void:
	_n += 1
	var tag := ("antes" if OS.get_environment("SIN_TORRE_DRIVE") != "" else "despues") + ("_noche" if OS.get_environment("NOCHE") == "1" else "")
	if _n == 20:
		get_viewport().get_texture().get_image().save_png("/tmp/torres_%s_0.png" % tag)
		_vista(1)
	if _n == 30:
		get_viewport().get_texture().get_image().save_png("/tmp/torres_%s_1.png" % tag)
		get_tree().quit()
