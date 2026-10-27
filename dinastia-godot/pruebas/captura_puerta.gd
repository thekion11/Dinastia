extends Node3D
## Un vecino abre la puerta de una entrada. xvfb-run -a godot --path . --rendering-driver opengl3 res://pruebas/captura_puerta.tscn → /tmp/captura_puerta_N.png
var _n := 0
var _pv: PuertaVida
var _cam: Camera3D

func _ready() -> void:
	var b := CityBuilder.new()
	add_child(b)
	var ex := ExploradorCiudad.new()
	ex.cb = b
	add_child(ex)
	var suelo := Mini3D.caja(self, Vector3(0, -0.1, 0), Vector3(60, 0.2, 60), Mini3D.mat(Color(0.35, 0.35, 0.36)))
	suelo.name = "Suelo"
	Mini3D.caja(self, Vector3(0, 3, -0.3), Vector3(14, 6, 0.6), Mini3D.mat(Color(0.7, 0.62, 0.52)))
	Mini3D.caja(self, Vector3(0, 1.2, -0.05), Vector3(1.6, 2.4, 0.2), Mini3D.mat(Color(0.12, 0.12, 0.13)))
	_pv = PuertaVida.new()
	_pv.expl = ex
	add_child(_pv)
	PuertaVida.registrar(b, Vector3(0, 0, 0), Vector3(0, 0, 1))
	_pv.iniciar(0, true)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-40, 25, 0)
	add_child(sol)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.6, 0.72, 0.85)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.7, 0.72)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	_cam = Camera3D.new()
	add_child(_cam)
	_cam.position = Vector3(5, 1.9, 8)
	_cam.look_at(Vector3(0, 1.2, 0.5), Vector3.UP)
	_cam.make_current()

func _process(d: float) -> void:
	_n += 1
	## Los pasos de tiempo van por saltos para ver tres momentos: llegando, abriendo y entrando.
	if _n in [20, 90, 150]:
		get_viewport().get_texture().get_image().save_png("/tmp/captura_puerta_%d.png" % _n)
	if _n == 160:
		get_tree().quit()
