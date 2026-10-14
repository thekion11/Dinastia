extends Node
## EL CÉSPED DE CERCA (14-10-2026): tres alturas de cámara sobre el campo, con
## y sin las capas de volumen. Salida: pruebas/capturas/cesped_volumen.png
##   xvfb-run -a godot --path . --resolution 1280x720 res://pruebas/captura_cesped.tscn
var _n := 0
var _vista: VistaEstadio
var _fotos: Array[Image] = []
var _cam: Camera3D
const TOMAS := [[Vector3(6, 0.45, 20), Vector3(8, 0.0, 23.5)], [Vector3(4, 1.7, 14), Vector3(9, 0.0, 24)], [Vector3(0, 6.0, 4), Vector3(10, 0.0, 22)]]

func _ready() -> void:
	Calidad.elegida = Calidad.ULTRA
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var c: Club = m.ligas[0].clubes[0]
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(c, 0.85)
	_cam = Camera3D.new()
	_cam.fov = 55
	add_child(_cam)

func _process(_d: float) -> void:
	_n += 1
	var intro: Variant = _vista.get("_intro")
	if intro != null and is_instance_valid(intro) and intro.activa:
		intro.terminar()
	var i := (_n - 12) / 6
	if _n < 12 or i >= TOMAS.size() * 2:
		if i >= TOMAS.size() * 2:
			var hoja := Image.create(640 * 3, 360 * 2, false, _fotos[0].get_format())
			for k in _fotos.size():
				hoja.blit_rect(_fotos[k], Rect2i(0, 0, 640, 360), Vector2i((k % 3) * 640, (k / 3) * 360))
			hoja.save_png("res://pruebas/capturas/cesped_volumen.png")
			print("HOJA guardada")
			get_tree().quit()
		return
	var toma: Array = TOMAS[i % TOMAS.size()]
	_cam.position = toma[0]
	_cam.look_at(toma[1])
	_cam.current = true
	var capas := _vista.find_child("CespedCapas", true, false)
	if capas != null:
		capas.set_process(i >= TOMAS.size())
		(capas as Node3D).visible = false if i < TOMAS.size() else (capas as Node3D).visible
	if (_n - 12) % 6 == 5:
		var img := get_viewport().get_texture().get_image()
		img.resize(640, 360)
		_fotos.append(img)
