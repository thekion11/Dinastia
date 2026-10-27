extends Node3D
## Quien deja el banco se levanta y se va andando: 5 fotogramas. → /tmp/levantarse_N.png
var _n := 0
var _d: Dictionary
var _sacados := 0

func _ready() -> void:
	AjustesCiudad.guardar("tutorial_visto", true)
	Mini3D.caja(self, Vector3(0, -0.1, 0), Vector3(40, 0.2, 40), Mini3D.mat(Color(0.5, 0.5, 0.48)))
	Mini3D.caja(self, Vector3(0, 0.45, -0.1), Vector3(1.8, 0.1, 0.5), Mini3D.mat(Color(0.45, 0.32, 0.2)))
	Mini3D.caja(self, Vector3(0, 0.25, -0.1), Vector3(1.7, 0.4, 0.1), Mini3D.mat(Color(0.3, 0.3, 0.3)))
	_d = PeatonVida.nuevo(self, 90)
	var n: Node3D = _d["nodo"]
	var cadera := MetroCiudad.altura_cadera(n)
	n.position = Vector3(0, 0.5 + 0.08 - cadera * 0.99, 0.15)
	n.rotation.y = 0.0
	Mini3D.anim(_d, "sentado", "")
	AnimExtra.asegurar(_d["anim"], FutbolistaQ.esqueleto_de(n), "levantarse")
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
	cam.fov = 38.0
	cam.position = Vector3(4.2, 1.4, 1.5)
	cam.look_at(Vector3(0, 1.0, 0.6), Vector3.UP)
	cam.make_current()

func _process(_dt: float) -> void:
	_n += 1
	var n: Node3D = _d["nodo"]
	if _n == 20:
		_foto()
		Mini3D.anim(_d, "levantarse", "")
	if _n in [30, 40, 50]:
		_foto()
	if _n == 50:
		Mini3D.anim(_d, "caminar", "")
	if _n in [65, 85]:
		n.position += Vector3(0.9, 0, 0.5)
		n.rotation.y = 1.2
		_foto()
	if _n > 90:
		get_tree().quit()

func _foto() -> void:
	get_viewport().get_texture().get_image().save_png("/tmp/levantarse_%d.png" % _sacados)
	_sacados += 1
