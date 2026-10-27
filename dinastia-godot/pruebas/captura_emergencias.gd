extends Node
## Policía, bomberos y ambulancia (pieza E) en tres calles de prueba, al atardecer. NO corre con --headless:
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_emergencias.tscn → /tmp/captura_emerg_N.png

var _n := 0
var _cam: Camera3D
var _vistas: Array = []

func _suelo(c: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	pl.size = Vector2(420, 420)
	mi.mesh = pl
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.2, 0.21, 0.23)
	mi.material_override = m
	mi.position = c
	add_child(mi)
	for k in [-1, 1]:   ## las dos aceras y las casas de enfrente
		var ac := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(40, 0.3, 420)
		ac.mesh = b
		var mm := StandardMaterial3D.new()
		mm.albedo_color = Color(0.55, 0.53, 0.5)
		ac.material_override = mm
		ac.position = c + Vector3(float(k) * 32.0, 0.15, 0)
		add_child(ac)
		for z in range(-180, 200, 70):
			var ed := MeshInstance3D.new()
			var eb := BoxMesh.new()
			eb.size = Vector3(22, 14 + float(absi(z) % 3) * 6.0, 40)
			ed.mesh = eb
			var em := StandardMaterial3D.new()
			em.albedo_color = Color(0.72, 0.6, 0.5) if k < 0 else Color(0.62, 0.66, 0.72)
			ed.material_override = em
			ed.position = c + Vector3(float(k) * 56.0, eb.size.y * 0.5, float(z))
			add_child(ed)

func _escena(origen: Vector3, tipo: String, pasos: int) -> ServiciosVida:
	_suelo(origen + Vector3(0, 0, 150))
	ServiciosVida.estaciones = {}
	for uso in ["comisaria", "bomberos", "hospital"]:
		var c := origen + Vector3(0.0, 0.2, 0.0)
		ServiciosVida.estaciones[uso] = [c]
	var sv := ServiciosVida.new()
	add_child(sv)
	## El sitio, en la calle de x = origen.x (a 150 m al sur de las cocheras) sobre la acera.
	var pos := origen + Vector3(11.0, 0.0, 190.0)
	sv.iniciar(tipo, pos)
	for i in pasos:
		sv._process(0.1)
	sv.set_process(false)
	return sv

func _ready() -> void:
	var o1 := Vector3(0, 0, 0)
	var o2 := Vector3(1000, 0, 0)
	var o3 := Vector3(2000, 0, 0)
	_escena(o1, "incendio", 300)
	_escena(o2, "accidente", 330)
	var sv3 := _escena(o3, "robo", 85)
	var pp: Vector3 = (sv3.vehiculos[0]["nodo"] as Node3D).position
	## Las cuatro tomas: fuego de cerca, fuego desde lejos, accidente y un coche en camino.
	_vistas = [
		[o1 + Vector3(-22, 4.0, 218), o1 + Vector3(11, 3.5, 190)],
		[o1 + Vector3(-6, 17, 262), o1 + Vector3(11, 4, 190)],
		[o2 + Vector3(-18, 3.5, 214), o2 + Vector3(9, 1.5, 190)],
		[pp + Vector3(-11, 3.0, 17), pp + Vector3(0, 1.5, 0)]]
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-14, 60, 0)
	sol.light_energy = 0.55
	sol.light_color = Color(1.0, 0.72, 0.5)
	add_child(sol)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.2, 0.25, 0.4)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.32, 0.36, 0.5)
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
		get_viewport().get_texture().get_image().save_png("%s/captura_emerg_%d.png" % [carpeta, i - 1])
	if _n % 6 == 1:
		var k := clampi(_n / 6, 0, _vistas.size() - 1)
		_cam.position = _vistas[k][0]
		_cam.look_at(_vistas[k][1], Vector3.UP)
	if _n > 6 * (_vistas.size() + 2):
		get_tree().quit()
