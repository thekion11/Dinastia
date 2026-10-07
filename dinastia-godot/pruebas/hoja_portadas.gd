extends Node
## Hoja de contactos de las nueve portadas. Una portada que "carga" pero sale
## vacia no da error: hay que mirarla.
func _ready() -> void:
	var alto := 200
	var img := Image.create(1200, alto * Portada.NOMBRES.size(), false, Image.FORMAT_RGBA8)
	img.fill(Color("0d1117"))
	var vacias := 0
	for i in Portada.NOMBRES.size():
		var k: String = Portada.NOMBRES[i]
		var una := Image.new()
		if una.load_svg_from_string(Portada.svg_de(k), 1.0) != OK:
			print("  %-10s NO CARGA" % k)
			vacias += 1
			continue
		una.convert(Image.FORMAT_RGBA8)
		## Se mide cuanta tinta hay: una portada casi transparente es una portada
		## que no se dibujo, aunque el rasterizador diga que si.
		var opacos := 0
		for y in range(0, una.get_height(), 8):
			for x in range(0, una.get_width(), 8):
				if una.get_pixel(x, y).a > 0.5:
					opacos += 1
		print("  %-10s %dx%d  pixeles con tinta: %d" % [k, una.get_width(), una.get_height(), opacos])
		if opacos < 500:
			vacias += 1
		img.blit_rect(una, Rect2i(0, 0, 1200, alto), Vector2i(0, i * alto))
	img.save_png("res://pruebas/capturas/hoja_portadas.png")
	print("portadas con dibujo: %d de %d" % [Portada.NOMBRES.size() - vacias, Portada.NOMBRES.size()])
	get_tree().quit()
