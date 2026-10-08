extends Node
## LA PORTADA QUE CAMBIA SOLA Y LAS PARTÍCULAS NUEVAS (8-10-2026).
## Hoja: `pruebas/capturas/portada_rota.png` (antes · a mitad del fundido ·
## la siguiente variante · otra más).
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_portada_rota.tscn
var _t := 0.0
var _paso := 0
var _p: Node
var _imgs: Array[Image] = []

func _ready() -> void:
	_p = load("res://escenas/inicio.tscn").instantiate()
	add_child(_p)

func _foto() -> void:
	var img := get_viewport().get_texture().get_image()
	img.resize(640, 360)
	_imgs.append(img)
	print("FOTO ", _imgs.size(), " portada=", _p.get("_clave"))

func _process(d: float) -> void:
	_t += d
	var pasos := [2.5, 0.7, 1.4, 0.5, 2.0, 0.5]
	if _paso >= pasos.size() or _t < float(pasos[_paso]):
		return
	_t = 0.0
	_paso += 1
	match _paso:
		1:
			_foto()
			_p.call("_rotar_portada")     # lo que hace el reloj cada 30 s
		2:
			_foto()                       # a mitad del fundido
		3:
			_foto()                       # ya en la siguiente
			_p.call("_rotar_portada")
		4:
			pass
		5:
			_foto()
			_p.call("_rotar_portada")
		6:
			_foto()
			var hoja := Image.create(640 * 3, 360 * 2, false, Image.FORMAT_RGBA8)
			for k in _imgs.size():
				hoja.blit_rect(_imgs[k], Rect2i(0, 0, 640, 360), Vector2i((k % 3) * 640, (k / 3) * 360))
			hoja.save_png("res://pruebas/capturas/portada_rota.png")
			print("HOJA OK")
			get_tree().quit()
