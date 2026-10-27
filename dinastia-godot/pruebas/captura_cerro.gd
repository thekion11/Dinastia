extends Node
## El cerro y el teleférico (terreno + teleférico, sin la ciudad). NO corre con --headless:
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_cerro.tscn → /tmp/captura_cerro_N.png

var _n := 0
var _cam: Camera3D
var _tele: Teleferico
var _vistas: Array = []

func _ready() -> void:
	var b := CityBuilder.new()
	add_child(b)
	for m in b._terreno():
		b.add_child(m)
	_tele = Teleferico.montar(b)
	var base := _tele.base
	var cima := _tele.cima
	_tele._t = Teleferico.VIAJE * 0.42
	_tele._poner_cabinas(_tele._t)
	var cab: Vector3 = _tele.cabinas[0].position
	_vistas = [[Vector3(700, 420, 500), Vector3(1900, 140, 900)], [Vector3(base.x - 40, 14, base.z - 30), base + Vector3(0, 6, 0)],
		[cima + Vector3(-40, 14, 30), cima + Vector3(0, 6, 0)], [cab + Vector3(-30, 8, 30), cab + Vector3(0, -3, 0)],
		[cima + Vector3(-60, 40, 90), cima + Vector3(0, -60, -120)]]
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-40, 40, 0)
	add_child(sol)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.62, 0.74, 0.88)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.65, 0.72)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	_cam = Camera3D.new()
	_cam.far = 6000.0
	add_child(_cam)
	_cam.make_current()

func _process(_d: float) -> void:
	_n += 1
	var i := _n / 6
	var carpeta := OS.get_environment("CAPTURA_SALIDA") if OS.get_environment("CAPTURA_SALIDA") != "" else "/tmp"
	if _n % 6 == 0 and i >= 1 and i <= _vistas.size():
		get_viewport().get_texture().get_image().save_png("%s/captura_cerro_%d.png" % [carpeta, i - 1])
	if _n % 6 == 1:
		var k := clampi(_n / 6, 0, _vistas.size() - 1)
		_cam.position = _vistas[k][0]
		_cam.look_at(_vistas[k][1], Vector3.UP)
	if _n > 6 * (_vistas.size() + 2):
		get_tree().quit()
