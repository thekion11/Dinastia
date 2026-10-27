extends Node
## Un coche adelanta a un autobús parado en su parada (M-171). NO corre con --headless:
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_adelantar.tscn → /tmp/captura_adel_N.png

var _n := 0
var _cam: Camera3D
var _vistas: Array = []

func _ready() -> void:
	var suelo := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	pl.size = Vector2(500, 120)
	suelo.mesh = pl
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.22, 0.23, 0.25)
	suelo.material_override = m
	suelo.position = Vector3(150, 0, 0)
	add_child(suelo)
	var t := TraficoCiudad.new()
	add_child(t)
	t.set_process(false)
	var r1 := t.agregar_ruta(PackedVector3Array([Vector3(0, 0.2, 6), Vector3(600, 0.2, 6), Vector3(600, 0.2, 60), Vector3(0, 0.2, 60)]))
	var bus := CityBuilder.autobus(Color(0.2, 0.5, 0.8), "27 · CENTRO", "27")
	t.agregar_vehiculo(bus, r1, 120.0, 9.0)
	t.agregar_paradas_al_ultimo([130.0], 40.0)
	var r2 := t.agregar_ruta(PackedVector3Array([Vector3(0, 0.2, 6), Vector3(600, 0.2, 6), Vector3(600, 0.2, 60), Vector3(0, 0.2, 60)]))   ## la ruta del coche: otra distinta, como en la ciudad
	var ps := load("res://assets/ciudad/kenney_cars/sedan.glb") as PackedScene
	var coche: Node3D = ps.instantiate()
	coche.scale = Vector3.ONE * 2.3
	t.agregar_vehiculo(coche, r2, 40.0, 12.0)
	var vb: Dictionary = t._vehiculos[0]
	var vc: Dictionary = t._vehiculos[1]
	for i in 600:
		t._process(1.0 / 30.0)
		if float(vb.get("espera", 0.0)) > 0.0 and coche.position.x > bus.position.x - 1.0:
			break   ## el coche a la altura del autobús parado, ya abierto hacia el eje
	var pb: Vector3 = bus.position
	var pc: Vector3 = coche.position
	print("bus ", pb, " coche ", pc, " lat ", vc.get("lat"))
	_vistas = [[pb + Vector3(-24, 5, -14), pb + Vector3(4, 1, 0)], [pb + Vector3(2, 38, 0.5), pb + Vector3(2, 0, 0)], [pb + Vector3(-9, 2.2, -8), pb + Vector3(0, 1.2, 0)]]
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-45, 50, 0)
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
	_cam.far = 2000.0
	add_child(_cam)
	_cam.make_current()

func _process(_d: float) -> void:
	_n += 1
	var i := _n / 6
	var carpeta := OS.get_environment("CAPTURA_SALIDA") if OS.get_environment("CAPTURA_SALIDA") != "" else "/tmp"
	if _n % 6 == 0 and i >= 1 and i <= _vistas.size():
		get_viewport().get_texture().get_image().save_png("%s/captura_adel_%d.png" % [carpeta, i - 1])
	if _n % 6 == 1:
		var k := clampi(_n / 6, 0, _vistas.size() - 1)
		_cam.position = _vistas[k][0]
		_cam.look_at(_vistas[k][1], Vector3.UP)
	if _n > 6 * (_vistas.size() + 2):
		get_tree().quit()
