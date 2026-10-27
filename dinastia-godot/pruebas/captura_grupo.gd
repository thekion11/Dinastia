extends Node3D
## Tres vecinos charlando en corro (GrupoVida). → /tmp/grupo.png
var _n := 0
var _gv: GrupoVida

func _ready() -> void:
	AjustesCiudad.guardar("tutorial_visto", true)
	var b := CityBuilder.new()
	add_child(b)
	var ex := ExploradorCiudad.new()
	ex.cb = b
	add_child(ex)
	Mini3D.caja(self, Vector3(50, -0.1, 50), Vector3(40, 0.2, 40), Mini3D.mat(Color(0.5, 0.5, 0.48)))
	_gv = GrupoVida.new()
	_gv.expl = ex
	add_child(_gv)
	PuertaVida.registrar(b, Vector3(50, 0, 50), Vector3(0, 0, 1))
	_gv.iniciar(0)
	_gv._mover(float((_gv._grupos[0] as Dictionary)["dur"]) + 0.1)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, 20, 0)
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
	cam.fov = 45.0
	cam.position = Vector3(50, 2.6, 58.0)
	cam.look_at(Vector3(50, 1.1, 53), Vector3.UP)
	cam.make_current()

func _process(delta: float) -> void:
	_n += 1
	_gv._mover(delta)
	if _n == 40:
		get_viewport().get_texture().get_image().save_png("/tmp/grupo.png")
		get_tree().quit()
