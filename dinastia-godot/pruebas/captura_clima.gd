extends Node
## EL CLIMA SE VE Y LAS BANDERAS ONDEAN (25-9-2026, plan maestro B11): el mismo
## estadio con lluvia, nieve y tormenta.
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_clima.tscn
const CLIMAS := ["lluvia", "nieve", "tormenta"]
var _n := 0
var _i := 0
var _vista: VistaEstadio
var _mundo: Mundo
var _imgs: Array[Image] = []

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4321)
	_mundo.tomar_el_mando(_mundo.clubes.values()[0].id)

func _abrir() -> void:
	var c := _mundo.mi_club()
	var perfil: Dictionary = c.perfil_estadio().duplicate()
	perfil["clima"] = CLIMAS[_i]
	perfil["banderas"] = "paises"
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(c, 0.8, null, null, perfil)

func _process(_d: float) -> void:
	_n += 1
	if _n == 5:
		_abrir()
	if _n == 60:
		var img := get_viewport().get_texture().get_image()
		img.resize(640, 360)
		_imgs.append(img)
		_vista.queue_free()
		_i += 1
		if _i >= CLIMAS.size():
			var hoja := Image.create(640 * CLIMAS.size(), 360, false, Image.FORMAT_RGBA8)
			for k in _imgs.size():
				hoja.blit_rect(_imgs[k], Rect2i(0, 0, 640, 360), Vector2i(k * 640, 0))
			hoja.save_png("res://pruebas/capturas/clima_visible.png")
			print("captura: clima_visible.png")
			get_tree().quit()
		else:
			_n = 0
