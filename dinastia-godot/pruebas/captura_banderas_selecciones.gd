extends Node
## LAS BANDERAS DE LAS SELECCIONES SIN LIGA (17-10-2026): hoja con las 13
## nuevas en pruebas/capturas/banderas_selecciones.png (sin pantalla, sirve igual).

func _ready() -> void:
	var codigos := ["POR", "NED", "BEL", "CRO", "DEN", "SEN", "NGA", "CMR", "IRN", "CRC", "CAN", "NZL", "QAT"]
	var hoja := Image.create(96 * 7 + 8, 64 * 2 + 3, false, Image.FORMAT_RGBA8)
	hoja.fill(Color(0.1, 0.1, 0.1))
	for i in codigos.size():
		var img := Banderas.textura(codigos[i]).get_image()
		img.convert(Image.FORMAT_RGBA8)
		hoja.blit_rect(img, Rect2i(0, 0, 96, 64), Vector2i((i % 7) * 97 + 1, (i / 7) * 65 + 1))
	hoja.save_png("res://pruebas/capturas/banderas_selecciones.png")
	print("BANDERAS ok")
	get_tree().quit()
