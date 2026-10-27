extends Node3D
## El paradero de Santiago (ParaderoRed) con la cámara a pie. ANTES=1 dibuja la marquesina de antes (techo negro, trasera de cristal, banca verde).
##   → /tmp/paradero_<antes|despues>_N.png  (0 = de frente a 7 m, 1 = el poste del cartel de cerca, 2 = 3/4 desde la calle)
var _n := 0
var _cam: Camera3D

func _ready() -> void:
	AjustesCiudad.guardar("tutorial_visto", true)
	Mini3D.caja(self, Vector3(0, -0.1, 0), Vector3(60, 0.2, 60), Mini3D.mat(Color(0.35, 0.35, 0.37)))
	Mini3D.caja(self, Vector3(0, 0.05, -4.0), Vector3(30, 0.3, 8), Mini3D.mat(Color(0.78, 0.78, 0.76)))
	var raiz := Node3D.new()
	raiz.position = Vector3(0, 0.2, -3.0)
	add_child(raiz)
	if OS.get_environment("ANTES") == "1":
		var metal := Mini3D.mat(Color(0.08, 0.09, 0.1), 0.4)
		var vidrio := Mini3D.mat(Color(0.72, 0.86, 0.92, 0.4), 0.1)
		var acento := Mini3D.mat(Color(0.2, 0.5, 0.3), 0.5)
		Mini3D.caja(raiz, Vector3(0, 3.1, 0), Vector3(7.5, 0.22, 3.0), metal)
		Mini3D.caja(raiz, Vector3(0, 2.85, 1.5), Vector3(7.6, 0.5, 0.16), acento)
		Mini3D.caja(raiz, Vector3(0, 1.6, -1.4), Vector3(7.5, 2.5, 0.1), vidrio)
		for lado in [-1.0, 1.0]:
			Mini3D.caja(raiz, Vector3(lado * 3.5, 1.5, 1.3), Vector3(0.22, 3.0, 0.22), metal)
		Mini3D.caja(raiz, Vector3(0, 0.61, -0.9), Vector3(5.4, 0.16, 0.7), acento)
	else:
		ParaderoRed.montar(raiz, 7.5, 1234)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, -30, 0)
	add_child(sol)
	if OS.get_environment("NOCHE") == "1":   ## de noche: sol casi apagado, ambiente azul oscuro y una farola cerca
		sol.light_energy = 0.05
		var farola := OmniLight3D.new()
		farola.position = Vector3(-3.0, 4.5, -1.0)
		farola.omni_range = 14.0
		farola.light_energy = 2.0
		farola.light_color = Color(1.0, 0.85, 0.6)
		add_child(farola)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.62, 0.74, 0.88) if OS.get_environment("NOCHE") != "1" else Color(0.02, 0.03, 0.06)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.65, 0.66, 0.7) if OS.get_environment("NOCHE") != "1" else Color(0.06, 0.07, 0.12)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	_cam = Camera3D.new()
	add_child(_cam)
	_cam.fov = 60.0
	_cam.make_current()
	_vista(0)

func _vista(i: int) -> void:
	match i:
		0:
			_cam.position = Vector3(0, 1.7, 4.2)
			_cam.look_at(Vector3(0, 1.4, -3.0), Vector3.UP)
		1:
			_cam.position = Vector3(5.5, 1.7, 1.8)
			_cam.look_at(Vector3(4.6, 2.3, -2.1), Vector3.UP)
		_:
			_cam.position = Vector3(-5.0, 1.7, 3.0)
			_cam.look_at(Vector3(0.5, 1.2, -3.0), Vector3.UP)

func _process(_d: float) -> void:
	_n += 1
	var tag := ("antes" if OS.get_environment("ANTES") == "1" else "despues") + ("_noche" if OS.get_environment("NOCHE") == "1" else "")
	for i in 3:
		if _n == 20 + i * 10:
			get_viewport().get_texture().get_image().save_png("/tmp/paradero_%s_%d.png" % [tag, i])
			_vista(i + 1)
	if _n > 55:
		get_tree().quit()
