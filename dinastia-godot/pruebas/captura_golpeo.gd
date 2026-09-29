extends Node3D
## EL GOLPEO, EN SEIS FOTOGRAMAS DE LADO (29-9-2026, mapa de metas 16): para ver
## si la patada se lee como un golpeo de balón y no como un salto.
##   godot --path . --rendering-driver opengl3 --resolution 480x480 res://pruebas/captura_golpeo.tscn
const CLIPS := ["patear", "tiro_empeine", "tiro_canonazo"]
const N := 6
var _ap: AnimationPlayer
var _cam: Camera3D
var _c := 0
var _k := 0
var _espera := 0
var _imgs: Array[Image] = []
var _nodo: Node3D
func _ready() -> void:
	var amb := WorldEnvironment.new()
	var ent := Environment.new()
	ent.background_mode = Environment.BG_COLOR
	ent.background_color = Color(0.1, 0.16, 0.12)
	ent.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ent.ambient_light_color = Color(0.6, 0.6, 0.6)
	amb.environment = ent
	add_child(amb)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-50, -30, 0)
	add_child(luz)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(8, 8)
	suelo.mesh = pm
	var ms := StandardMaterial3D.new()
	ms.albedo_color = Color(0.2, 0.5, 0.25)
	suelo.material_override = ms
	add_child(suelo)
	var d := FutbolistaQ.crear(1.8, "male")
	_nodo = d["nodo"]
	add_child(_nodo)
	FutbolistaQ.terminar(d, true)
	VestidorQ.vestir_equipacion(d, Color("1d4fa3"), Color.WHITE, "liso", Color(0.8, 0.62, 0.5), Color(0.15, 0.1, 0.07))
	_ap = d["anim"]
	_cam = Camera3D.new()
	add_child(_cam)
	_cam.position = Vector3(3.2, 1.0, 0.0)
	_cam.look_at(Vector3(0, 0.85, 0))
	_cam.current = true
	_ap.play(CLIPS[0])
	_ap.pause()
func _process(_d: float) -> void:
	if _c >= CLIPS.size():
		return
	var clip: String = CLIPS[_c]
	var largo := _ap.get_animation(clip).length
	if _espera == 0:
		_ap.play(clip)
		_ap.seek(largo * float(_k) / float(N - 1) * 0.98, true)
		_ap.pause()
	_espera += 1
	if _espera < 4:
		return
	_espera = 0
	var img := get_viewport().get_texture().get_image()
	img.resize(240, 240)
	_imgs.append(img)
	_k += 1
	if _k >= N:
		_k = 0
		_c += 1
	if _c >= CLIPS.size():
		var hoja := Image.create(240 * N, 240 * CLIPS.size(), false, _imgs[0].get_format())
		for i in _imgs.size():
			hoja.blit_rect(_imgs[i], Rect2i(0, 0, 240, 240), Vector2i((i % N) * 240, (i / N) * 240))
		hoja.save_png("res://pruebas/capturas/golpeo_hoja.png")
		get_tree().quit()
