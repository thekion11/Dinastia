extends Node3D
## LOS MOVIMIENTOS NUEVOS, UNO A UNO (25-9-2026).
##
##   godot --path . --rendering-driver opengl3 --resolution 480x480 \
##         res://pruebas/captura_movimientos.tscn
##
## Monta un `FutbolistaQ` con el catálogo completo (`construir(..., true)`) y
## comprueba que existe CADA animación que pide `match_playback.gd` -antes
## faltaban nueve y se descartaban en silencio-. Deja una hoja de contactos con
## cada movimiento en su momento clave: `pruebas/movimientos_nuevos.png`.

const PEDIDAS := ["parado", "caminar", "trotar", "correr", "patear", "cabezazo", "celebrar",
	"celebrar_rodillas", "celebrar_carrera", "atajar_izq", "atajar_der", "atajar_bajo", "portero_listo",
	"lamento", "rabia", "falta_barrida", "falta_empujon", "senalar_falta", "mostrar_tarjeta",
	"mostrar_roja", "pase", "saque_banda", "marcar", "dolor"]
const FOTOS := [["cabezazo", 0.5], ["celebrar", 0.25], ["atajar_izq", 0.75], ["atajar_der", 0.7], ["atajar_bajo", 0.75], ["portero_listo", 0.5],
	["celebrar_rodillas", 0.5], ["celebrar_carrera", 0.5], ["lamento", 0.6], ["rabia", 0.25],
	["falta_barrida", 0.5], ["falta_empujon", 0.5], ["senalar_falta", 0.5], ["mostrar_roja", 0.55],
	["pase", 0.45], ["saque_banda", 0.35], ["marcar", 0.5], ["dolor", 0.7]]

var _ap: AnimationPlayer
var _i := 0
var _espera := 0
var _fallos := 0
var _imgs: Array[Image] = []

func _ready() -> void:
	var amb := WorldEnvironment.new()
	var ent := Environment.new()
	ent.background_mode = Environment.BG_COLOR
	ent.background_color = Color(0.1, 0.16, 0.12)
	ent.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ent.ambient_light_color = Color(0.5, 0.5, 0.5)
	amb.environment = ent
	add_child(amb)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-50, -30, 0)
	add_child(luz)
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(3.4, 1.3, 4.6)
	cam.fov = 45
	cam.look_at(Vector3(0.3, 0.7, 0), Vector3.UP)
	cam.current = true
	var d := FutbolistaQ.crear(1.8, "male")
	add_child(d["nodo"])
	FutbolistaQ.terminar(d, true)
	VestidorQ.vestir_equipacion(d, Color("c8102e"), Color.WHITE, "liso", Color(0.8, 0.62, 0.5), Color(0.15, 0.1, 0.07))
	_ap = d["anim"]
	var faltan: Array[String] = []
	for n: String in PEDIDAS:
		if not _ap.has_animation(n):
			faltan.append(n)
	print(("  ok    " if faltan.is_empty() else "  FALLO ") + "existen las %d animaciones que pide el partido %s" % [PEDIDAS.size(), str(faltan)])
	if not faltan.is_empty():
		_fallos += 1

func _process(_d: float) -> void:
	if _espera > 0:
		_espera -= 1
		if _espera == 0:
			var img := get_viewport().get_texture().get_image()
			img.resize(240, 240)
			_imgs.append(img)
			_i += 1
			if _i >= FOTOS.size():
				_hoja()
		return
	var f: Array = FOTOS[_i]
	if _ap.has_animation(String(f[0])):
		_ap.play(String(f[0]))
		_ap.seek(_ap.current_animation_length * float(f[1]), true)
		_ap.pause()
	_espera = 3

func _hoja() -> void:
	var hoja := Image.create(240 * 9, 240 * 2, false, Image.FORMAT_RGBA8)
	for k in _imgs.size():
		hoja.blit_rect(_imgs[k], Rect2i(0, 0, 240, 240), Vector2i((k % 9) * 240, (k / 9) * 240))
	hoja.save_png("res://pruebas/movimientos_nuevos.png")
	print("captura_movimientos: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
