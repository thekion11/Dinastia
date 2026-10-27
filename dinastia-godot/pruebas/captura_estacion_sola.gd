extends Node
## La Estación Central sola (sin la ciudad: cabe en memoria). Con el tren parado y los pasajeros andando por el andén.
##   herramientas/captura.sh res://pruebas/captura_estacion_sola.tscn → /tmp/estacion_sola_N.png (CAPTURA_SALIDA cambia la carpeta)
## `ESTACION_T` (variable de entorno) = instante del ciclo del tren 1 en segundos de juego (por defecto 21: recién parado).

var _n := 0
var _cam: Camera3D
var _est: EstacionCentral
var _vistas: Array = []

func _ready() -> void:
	var b := CityBuilder.new()
	add_child(b)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.8, 0.8, 0.78)
	_est = EstacionCentral.montar(b, Vector3(0, 0.0, 0), 96.0, 96.0, {"claro": m, "vidrio": m, "piedra": m})
	EstacionCentral.reloj = null
	_est._t = float(OS.get_environment("ESTACION_T")) if OS.get_environment("ESTACION_T") != "" else 21.0
	var z1: float = _est._trenes[0]["z1"]
	_vistas = [[Vector3(-14, 9, z1 + 16), Vector3(0, 1, z1 - 8)], [Vector3(22, 7, z1 - 9), Vector3(-6, 1.5, z1 - 9)],
		[Vector3(24, 6, -672), Vector3(-8, 2, -706)], [Vector3(70, 30, -470), Vector3(0, 0, -700)]]
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, 30, 0)
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
	_cam.far = 1500.0
	add_child(_cam)
	_cam.make_current()

func _process(_d: float) -> void:
	_n += 1
	var i := _n / 8
	var carpeta := OS.get_environment("CAPTURA_SALIDA") if OS.get_environment("CAPTURA_SALIDA") != "" else "/tmp"
	if _n % 8 == 0 and i >= 1 and i <= _vistas.size():
		get_viewport().get_texture().get_image().save_png("%s/estacion_sola_%d.png" % [carpeta, i - 1])
	if _n % 8 == 1:
		var k := clampi(_n / 8, 0, _vistas.size() - 1)
		_cam.position = _vistas[k][0]
		_cam.look_at(_vistas[k][1], Vector3.UP)
	if _n > 8 * (_vistas.size() + 2):
		get_tree().quit()
