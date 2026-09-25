extends Node3D
## Hoja de contactos de perfil y de frente para revisar a ojo lo que marca
## `auditoria_biomecanica.gd`. FOTOS="anim:t,anim:t" (t en fracción 0-1).
##   godot --path . --rendering-driver opengl3 --resolution 360x360 res://pruebas/captura_biomecanica.tscn
var _ap: AnimationPlayer
var _fotos: Array = []
var _i := 0
var _espera := 0
var _imgs: Array[Image] = []
var _cam: Camera3D
const VISTAS := [Vector3(4.2, 1.1, 0.0), Vector3(0.0, 1.1, 4.2)]

func _ready() -> void:
	var amb := WorldEnvironment.new()
	var ent := Environment.new()
	ent.background_mode = Environment.BG_COLOR
	ent.background_color = Color(0.1, 0.16, 0.12)
	ent.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ent.ambient_light_color = Color(0.55, 0.55, 0.55)
	amb.environment = ent
	add_child(amb)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-50, -30, 0)
	add_child(luz)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(6, 6)
	suelo.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.45, 0.22, 0.75)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	suelo.material_override = mat
	add_child(suelo)
	_cam = Camera3D.new()
	add_child(_cam)
	_cam.fov = 42
	_cam.current = true
	var d := FutbolistaQ.crear(1.8, "male")
	add_child(d["nodo"])
	FutbolistaQ.terminar(d, true)
	VestidorQ.vestir_equipacion(d, Color("c8102e"), Color.WHITE, "liso", Color(0.8, 0.62, 0.5), Color(0.15, 0.1, 0.07))
	_ap = d["anim"]
	for par: String in OS.get_environment("FOTOS").split(","):
		var p := par.split(":")
		for v in VISTAS.size():
			_fotos.append([p[0], float(p[1]), v])

func _process(_d: float) -> void:
	if _espera > 0:
		_espera -= 1
		if _espera == 0:
			var img := get_viewport().get_texture().get_image()
			img.resize(240, 240)
			_imgs.append(img)
			_i += 1
			if _i >= _fotos.size():
				_hoja()
		return
	var f: Array = _fotos[_i]
	_cam.position = VISTAS[int(f[2])]
	_cam.look_at(Vector3(0, 0.75, 0), Vector3.UP)
	_ap.play(String(f[0]))
	_ap.seek(_ap.current_animation_length * float(f[1]), true)
	_ap.pause()
	_espera = 3

func _hoja() -> void:
	var cols := mini(8, _imgs.size())
	var filas := int(ceil(_imgs.size() / float(cols)))
	var hoja := Image.create(240 * cols, 240 * filas, false, Image.FORMAT_RGBA8)
	for k in _imgs.size():
		hoja.blit_rect(_imgs[k], Rect2i(0, 0, 240, 240), Vector2i((k % cols) * 240, (k / cols) * 240))
	hoja.save_png(OS.get_environment("SALIDA") if OS.get_environment("SALIDA") != "" else "res://pruebas/biomecanica.png")
	get_tree().quit()
