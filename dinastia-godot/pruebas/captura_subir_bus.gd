extends Node3D
## Peatones que suben al autobús (orden 14): el bus para junto a la acera, los dos que esperan caminan a la puerta, suben el escalón y se adentran.
## BUS_PUERTA_ANTIGUA=1 pone la puerta en el lado de la calzada («antes»). → /tmp/subir_<antes|despues>_<n>.png
var _n := 0
var _pb: PasajerosBus
var _bus: Node3D
var _t := 0.0
var _hechas := 0
const MOMENTOS := [0.1, 1.2, 2.4, 3.6, 5.0]

func _ready() -> void:
	AjustesCiudad.guardar("tutorial_visto", true)
	var b := CityBuilder.new()
	add_child(b)
	Mini3D.caja(self, Vector3(0, -0.1, 0), Vector3(40, 0.2, 40), Mini3D.mat(Color(0.35, 0.35, 0.37)))
	Mini3D.caja(self, Vector3(-6.0, 0.1, 0), Vector3(5.0, 0.2, 40), Mini3D.mat(Color(0.72, 0.72, 0.7)))
	var para := Node3D.new()
	para.position = Vector3(-6.6, 0.2, -5.5)
	para.rotation.y = PI * 0.5
	add_child(para)
	ParaderoRed.montar(para, 3.8, 11, "Av. Prueba", 100)
	b.esperas_bus.append(Vector3(-4.8, 0.2, 4.0))
	_bus = CityBuilder.autobus(Color(0.2, 0.45, 0.8), "122", "122")
	_bus.position = Vector3(0, 0, -2.0)
	add_child(_bus)
	var ex := ExploradorCiudad.new()
	ex.cb = b
	ex.estado = "calle"
	var jug := Node3D.new()
	jug.position = Vector3(-8, 0, 4)
	ex.cuerpo = jug
	_pb = PasajerosBus.new()
	_pb.expl = ex
	add_child(_pb)
	_pb._poblar()
	_pb.set_process(false)   ## sin repoblar la parada: solo los dos primeros
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, 30, 0)
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
	cam.fov = 50.0
	add_child(cam)
	cam.make_current()
	cam.position = Vector3(-8.5, 3.4, 9.5)
	cam.look_at(Vector3(-2.2, 1.0, 3.0), Vector3.UP)

func _process(d: float) -> void:
	_n += 1
	if _n == 6:
		_pb.parada(_bus)
	if _n < 8:
		return
	_t += d
	_pb._mover(d)
	if _hechas < MOMENTOS.size() and _t >= float(MOMENTOS[_hechas]):
		get_viewport().get_texture().get_image().save_png("/tmp/subir_%s_%d.png" % ["antes" if OS.get_environment("BUS_PUERTA_ANTIGUA") != "" else "despues", _hechas])
		_hechas += 1
	if _hechas >= MOMENTOS.size():
		get_tree().quit()
