extends Node
## EL MISMO ESTADIO EN TODAS PARTES: la misma toma en la ciudad (arriba) y en el
## visor del estadio / partido (abajo). Hoja: `pruebas/capturas/mismo_estadio.png`.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 960x540 res://pruebas/captura_mismo_estadio.tscn
var _n := 0
var _p: Node
var _cam: Camera3D
var _imgs: Array[Image] = []
const TOMAS := [[Vector3(95, 70, 125), Vector3(0, 5, 0)], [Vector3(-40, 22, 120), Vector3(0, 6, 70)], [Vector3(0, 30, -5), Vector3(0, 8, 60)]]

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _foto() -> void:
	var img := get_viewport().get_texture().get_image()
	img.resize(480, 270)
	_imgs.append(img)

func _toma(origen: Vector3, k: int) -> void:
	_cam.global_position = origen + TOMAS[k][0]
	_cam.look_at(origen + TOMAS[k][1], Vector3.UP)
	_cam.make_current()

func _process(_d: float) -> void:
	_n += 1
	if _n == 6:
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad:
				(h as VistaCiudad).set("_ciclo_activo", false)
				(h as VistaCiudad).set("_hora", 12.0)
				(h as VistaCiudad).call("_aplicar_hora")
				_cam = Camera3D.new()
				_cam.far = 3000.0
				h.add_child(_cam)
		_toma(CityBuilder.ESTADIO_EN, 0)
	for k in 3:
		if _n == 12 + k * 6:
			_foto()
			if k < 2:
				_toma(CityBuilder.ESTADIO_EN, k + 1)
	if _n == 30:
		for h in _p.get_children():
			if h is VistaCiudad:
				h.queue_free()
	if _n == 34:
		_p.call("_ver_estadio_propio")
		for h in _p.get_children():
			if h is VistaEstadio:
				_cam = Camera3D.new()
				_cam.far = 3000.0
				(h.get("_raiz3d") as Node3D).add_child(_cam)
				var rig: Node = h.get("_rig")
				if rig != null:
					rig.set_process(false)
		_toma(Vector3.ZERO, 0)
	for k in 3:
		if _n == 42 + k * 6:
			_foto()
			if k < 2:
				_toma(Vector3.ZERO, k + 1)
	if _n == 60:
		var hoja := Image.create(480 * 3, 270 * 2, false, Image.FORMAT_RGBA8)
		for k in _imgs.size():
			hoja.blit_rect(_imgs[k], Rect2i(0, 0, 480, 270), Vector2i((k % 3) * 480, (k / 3) * 270))
		hoja.save_png("res://pruebas/capturas/mismo_estadio.png")
		print("HOJA OK")
		get_tree().quit()
