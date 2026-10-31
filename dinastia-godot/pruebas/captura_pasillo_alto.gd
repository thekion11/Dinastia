extends Node3D
## Primer plano de un pasillo de la bandeja alta (zancas y barandilla). → /tmp/pasillo_alto_<N>.png (N = 0 desde abajo, 1 desde un lado)
var _n := 0
var _cam: Camera3D
var _mundo := Vector3.ZERO
var _dir := Vector3.ZERO

func _ready() -> void:
	AjustesCiudad.guardar("tutorial_visto", true)
	Calidad.elegida = Calidad.ALTO
	var club := Club.new("pa_club", "Club PA")
	club.color1 = "#1f4f9a"
	club.color2 = "#f2f2f2"
	StadiumBuilder.build(self, {"forma": "cuenco", "niveles": 3, "techo": "anillo", "aforo": 40000}, 40000, 0.5, 4242, club)
	var y0 := StadiumBuilder.ALTURA_PIE + StadiumBuilder.subida_bandeja() / 2.0
	var mejor: MultiMeshInstance3D = null
	for n: Node in find_children("ZancasPasillo", "MultiMeshInstance3D", true, false):
		var deck := n.get_parent() as MeshInstance3D
		if deck.position.y > y0 + 0.5 and deck.mesh is BoxMesh and deck.get_parent() == self:
			mejor = n as MultiMeshInstance3D
			if deck.position.x > 0.0:
				break
	var deck2 := mejor.get_parent() as MeshInstance3D
	var xf := deck2.global_transform * mejor.multimesh.get_instance_transform(0)
	_mundo = xf.origin
	_dir = xf.basis.z.normalized()
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, 30, 0)
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
	_cam.fov = 55.0
	_cam.make_current()
	_vista(0)

func _vista(i: int) -> void:
	var a := _mundo + Vector3(0, 0.3, 0)
	var lado := Vector3.UP.cross(_dir).normalized()
	if i == 0:
		_cam.position = a - _dir * 5.0 + Vector3(0, 2.2, 0)
		_cam.look_at(a + _dir * 3.0, Vector3.UP)
	else:
		_cam.position = a + lado * 5.0 + Vector3(0, 2.0, 0)
		_cam.look_at(a, Vector3.UP)

func _process(_d: float) -> void:
	_n += 1
	if _n == 30:
		get_viewport().get_texture().get_image().save_png("/tmp/pasillo_alto_0.png")
		_vista(1)
	if _n == 40:
		get_viewport().get_texture().get_image().save_png("/tmp/pasillo_alto_1.png")
		get_tree().quit()
