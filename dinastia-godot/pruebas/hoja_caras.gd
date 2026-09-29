extends Node
## Hoja de contactos de retratos, para ver de un vistazo si hay variedad de
## verdad o si todos salen iguales. Un generador de caras que no se mira en
## grande parece funcionar aunque no dibuje ni el pelo.
func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 1717)
	var c: Club = m.ligas[0].clubes[0]
	var cortes := {}
	var img := Image.create(6 * 128, 4 * 128, false, Image.FORMAT_RGBA8)
	img.fill(Color("161b22"))
	var i := 0
	for j: Jugador in c.plantilla:
		if i >= 24:
			break
		var lk := Cara.look_de(j)
		cortes[lk["pelo"]] = true
		var uno := Image.new()
		if uno.load_svg_from_string(Cara.svg_de(j, c.color1, c.color2), 2.0) != OK:
			continue
		uno.convert(Image.FORMAT_RGBA8)
		img.blit_rect(uno, Rect2i(0, 0, 128, 128), Vector2i((i % 6) * 128, (i / 6) * 128))
		i += 1
	img.save_png("res://pruebas/capturas/hoja_caras.png")
	print("retratos: %d, cortes distintos: %d -> %s" % [i, cortes.size(), cortes.keys()])
	get_tree().quit()
