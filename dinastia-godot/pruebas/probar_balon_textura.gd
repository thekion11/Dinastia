extends SceneTree
## La textura del balón clásico con el plano precalculado (y la de la caché de disco) es la misma,
## byte a byte, que la de `_pixel_clasico` píxel a píxel (30-10-2026, rendimiento).

func _init() -> void:
	var fallos := 0
	var cp := Balon3D._icosaedro()
	var ch := Balon3D._caras_icosaedro(cp)
	for c: Array in [[Color.WHITE, Color.BLACK], [Color("#f2e8c9"), Color("#7a1020")]]:
		var ref := Image.create(Balon3D.ANCHO_TEX, Balon3D.ALTO_TEX, false, Image.FORMAT_RGB8)
		for y in Balon3D.ALTO_TEX:
			var th := (float(y) + 0.5) / float(Balon3D.ALTO_TEX) * PI
			for x in Balon3D.ANCHO_TEX:
				var ph := (float(x) + 0.5) / float(Balon3D.ANCHO_TEX) * TAU
				var d := Vector3(sin(ph) * sin(th), cos(th), cos(ph) * sin(th))
				ref.set_pixel(x, y, Balon3D._pixel_clasico(d, cp, ch, c[0], c[1], (c[0] as Color).darkened(0.45)))
		ref.generate_mipmaps()
		for img: Image in [Balon3D._textura_nueva(c[0], c[1], "clasico").get_image(), Balon3D.textura(c[0], c[1]).get_image()]:
			if img.get_data() != ref.get_data():
				fallos += 1
				print("FALLO balón ", c)
	print("FIN. %d fallos" % fallos)
	quit()
