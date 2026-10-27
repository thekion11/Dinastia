extends Node
## Capturas del subsuelo de la ciudad (easter egg) desde siete puntos. NO corre con --headless:
##   herramientas/captura.sh res://pruebas/captura_subsuelo.tscn [--compat]
## Sale en /tmp/captura_subsuelo_N.png (variable CAPTURA_SALIDA para otra carpeta).
## SIN_LUZ=1 deja sin corriente el sector de la entrada (lámparas de emergencia en rojo).

const PUNTOS := [
	[Vector3(-2.5, 1.7, 0.0), Vector3(20, 1.5, 0)], [Vector3(20, 1.7, 0.0), Vector3(45, 1.5, 0)],
	[Vector3(21, 1.7, -5.0), Vector3(21, 2.0, -30)], [Vector3(33, 1.7, 6.0), Vector3(33, 2.0, 30)],
	[Vector3(47, 1.7, -5.0), Vector3(47, 2.0, -30)], [Vector3(62, 2.0, 4.0), Vector3(75, 2.0, -6)],
	[Vector3(92, 1.6, 0.0), Vector3(108, 1.2, 0)]]

var _n := 0
var _cam: Camera3D
var _sub: SubsueloCiudad

func _ready() -> void:
	var b := CityBuilder.new()
	add_child(b)
	var ex := CiudadExpansion.new(b)
	ex.armar_red()
	ex.armar_bloques()
	ex.armar_transporte()
	var v := RedesCiudadVista.crear(ex, 5)
	_sub = SubsueloCiudad.crear(b, v)
	_sub.visible = true
	if OS.get_environment("SIN_LUZ") == "1":
		v.modelo.averiar("luz", _sub.sector_entrada)
		v.modelo.recalcular()
	_sub._actualizar()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.55, 0.6)
	env.ambient_light_energy = 0.25
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	_cam = Camera3D.new()
	_cam.fov = 65.0
	add_child(_cam)
	_cam.make_current()
	var luz := OmniLight3D.new()
	luz.omni_range = 12.0
	luz.light_energy = 0.45
	_cam.add_child(luz)

func _process(_d: float) -> void:
	_n += 1
	var k := _n / 12 - 1
	if _n % 12 == 0 and k >= 0 and k < PUNTOS.size():
		var carpeta := OS.get_environment("CAPTURA_SALIDA") if OS.get_environment("CAPTURA_SALIDA") != "" else "/tmp"
		get_viewport().get_texture().get_image().save_png("%s/captura_subsuelo_%d.png" % [carpeta, k])
	if _n % 12 == 1 or _n == 1:
		var i := clampi(_n / 12, 0, PUNTOS.size() - 1)
		_cam.position = SubsueloCiudad.ORIGEN + (PUNTOS[i][0] as Vector3)
		_cam.look_at(SubsueloCiudad.ORIGEN + (PUNTOS[i][1] as Vector3), Vector3.UP)
	if _n > 12 * (PUNTOS.size() + 2):
		get_tree().quit()
