extends Node
## Capturas de la Estación Central con trenes (suelo y cielo mínimos). NO corre con --headless:
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://pruebas/captura_estacion.tscn
## Sale en /tmp/captura_estacion_N.png (CAPTURA_SALIDA cambia la carpeta). Vistas: aérea, andén con el tren parado, entrada.

var _n := 0
var _est: EstacionCentral
var _cam: Camera3D
const VISTAS := [
	[Vector3(0, 80, 90), Vector3(0, 0, -5), 14.0],      ## aérea, tren llegando
	[Vector3(-14, 4.5, -6), Vector3(0, 3, 4), 20.0],    ## andén 1 con el tren parado
	[Vector3(30, 30, 60), Vector3(0, 4, -5), 24.0],     ## desde la calle, tren parado
	[Vector3(0, 12, -2), Vector3(0, 4, -38), 55.0]]     ## mirando al túnel, tren saliendo

func _ready() -> void:
	var b := CityBuilder.new()
	add_child(b)
	var suelo := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	pl.size = Vector2(400, 400)
	suelo.mesh = pl
	var ms := StandardMaterial3D.new()
	ms.albedo_color = Color(0.32, 0.33, 0.33)
	suelo.material_override = ms
	suelo.position = Vector3(0, 0.1, 0)
	add_child(suelo)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.78, 0.72)
	var vid := StandardMaterial3D.new()
	vid.albedo_color = Color(0.4, 0.6, 0.7, 0.6)
	vid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_est = EstacionCentral.montar(b, Vector3(0, 0.2, 0), 96.0, 96.0, {"claro": mat, "vidrio": vid, "piedra": mat})
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, 30, 0)
	add_child(sol)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.7, 0.85)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.65, 0.7)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	_cam = Camera3D.new()
	_cam.far = 600.0
	add_child(_cam)
	_cam.make_current()

func _process(_d: float) -> void:
	_n += 1
	var i := _n / 6
	if _n % 6 == 0 and i >= 1 and i <= VISTAS.size():
		var carpeta := OS.get_environment("CAPTURA_SALIDA") if OS.get_environment("CAPTURA_SALIDA") != "" else "/tmp"
		get_viewport().get_texture().get_image().save_png("%s/captura_estacion_%d.png" % [carpeta, i - 1])
	if _n % 6 == 1:
		var k := clampi(_n / 6, 0, VISTAS.size() - 1)
		_est._t = float(VISTAS[k][2]) if k != 0 else 5.0
		_est._process(0.0)
		_cam.position = VISTAS[k][0]
		_cam.look_at(VISTAS[k][1], Vector3.UP)
	if _n > 6 * (VISTAS.size() + 2):
		get_tree().quit()
