extends Node3D
## CAPTURAS POSE A POSE de las animaciones de 100STYLE (sesión 10, 11-11-2026): 8 jugadores en fila, cada uno en una fase del ciclo,
## vistos (a) de cerca y (b) con la CÁMARA REAL de la transmisión (FOV 33°, 17 m de altura, 46 m de distancia; recorte alrededor de la
## fila). Se buscan brazos que atraviesen el cuerpo y pies que floten o se crucen.
##   CLIPS=Neutral_FW_1,Neutral_FR_1 SALIDA=res://docs... herramientas/captura.sh res://pruebas/captura_anims_100style.tscn
var LIB := "res://assets/characters/quaternius/anims_100style/100style.res"
const FASES := 8
const SEP := 1.4
var _clips: PackedStringArray
var _salida := "res://pruebas/capturas/"
var _jugadores: Array = []
var _cam: Camera3D

func _ready() -> void:
	var c := OS.get_environment("CLIPS")
	_clips = c.split(",") if c != "" else PackedStringArray(["Neutral_FW_1", "Neutral_FR_1", "Neutral_BW_1", "Neutral_SW_1", "Neutral_SR_1", "Neutral_ID_1"])
	if OS.get_environment("SALIDA") != "":
		_salida = OS.get_environment("SALIDA")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_salida))
	if OS.get_environment("BIBLIOTECA") != "":
		LIB = OS.get_environment("BIBLIOTECA")
	var lib: AnimationLibrary = load(LIB)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(120, 120)
	suelo.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.17, 0.42, 0.18)
	suelo.material_override = mat
	add_child(suelo)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-55, -30, 0)
	luz.shadow_enabled = true
	add_child(luz)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.7, 0.9)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.6, 0.6, 0.65)
	add_child(env)
	for i in FASES:
		var d := FutbolistaQ.crear(1.8, "male")
		add_child(d["nodo"])
		(d["nodo"] as Node3D).position = Vector3((i - (FASES - 1) / 2.0) * SEP, 0, 0)
		(d["nodo"] as Node3D).rotation_degrees.y = 90.0   # mira hacia +X (de izquierda a derecha en cámara lateral)
		FutbolistaQ.terminar(d)
		(d["anim"] as AnimationPlayer).add_animation_library("x100", lib)
		_jugadores.append(d)
	_cam = Camera3D.new()
	add_child(_cam)
	_cam.current = true
	_correr()

func _correr() -> void:
	for nombre in _clips:
		var pre := OS.get_environment("PREFIJO")   # vacío = e100_ ; «-» = sin prefijo
		var clave := "x100/" + ("" if pre == "-" else (pre if pre != "" else "e100_")) + nombre
		for i in FASES:
			var ap: AnimationPlayer = _jugadores[i]["anim"]
			if not ap.has_animation(clave):
				print("FALTA ", clave)
				continue
			ap.play(clave)
			ap.seek(ap.get_animation(clave).length * float(i) / float(FASES), true)
			ap.pause()
		for _k in 3:
			await get_tree().process_frame
		await _vista("cerca", Vector3(0, 1.0, 13.0), Vector3(0, 0.9, 0), 28.0, nombre, Rect2())
		await _vista("camara_real", Vector3(0, 17.0, 46.0), Vector3(0, 0.0, 0), 33.0, nombre, Rect2(0.35, 0.34, 0.30, 0.34))
		await get_tree().process_frame
	print("===== CAPTURAS 100STYLE: ", _clips.size(), " clips")
	get_tree().quit()

func _vista(nombre_vista: String, desde: Vector3, mira: Vector3, fov: float, clip: String, recorte: Rect2) -> void:
	_cam.position = desde
	_cam.fov = fov
	_cam.look_at(mira, Vector3.UP)
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	if recorte.size != Vector2.ZERO:
		var w := img.get_width()
		var h := img.get_height()
		img = img.get_region(Rect2i(int(recorte.position.x * w), int(recorte.position.y * h), int(recorte.size.x * w), int(recorte.size.y * h)))
	img.save_jpg(_salida + "%s_%s.jpg" % [clip, nombre_vista], 0.9)
