class_name KitTextureFactory
extends "res://visor/kit_texture_factory_p1.gd"
## (Parte 2 de 2 de `kit_texture_factory.gd`.)

static func _color_dominante_gd(img: Image, r: Rect2i) -> Color:
	var cubos := {}
	var mejor := 0
	var mejor_k := -1
	for y in range(r.position.y + 16, r.end.y - 16, 5):
		for x in range(r.position.x + 10, r.end.x - 10, 5):
			var p := img.get_pixel(x, y)
			var k: int = (int(p.r * 7.99) << 6) | (int(p.g * 7.99) << 3) | int(p.b * 7.99)
			var n: int = int(cubos.get(k, 0)) + 1
			cubos[k] = n
			if n > mejor:
				mejor = n
				mejor_k = k
	if mejor_k < 0:
		return Color(0.2, 0.2, 0.2)
	# Del cubo se vuelve al color promediando SOLO sus propios pixeles: quedarse
	# con el centro del cubo daria un tono lavado que no es el del club.
	var acc := Vector3.ZERO
	var n2 := 0
	for y in range(r.position.y + 16, r.end.y - 16, 5):
		for x in range(r.position.x + 10, r.end.x - 10, 5):
			var p := img.get_pixel(x, y)
			var k: int = (int(p.r * 7.99) << 6) | (int(p.g * 7.99) << 3) | int(p.b * 7.99)
			if k == mejor_k:
				acc += Vector3(p.r, p.g, p.b)
				n2 += 1
	if n2 == 0:
		return Color(0.2, 0.2, 0.2)
	acc /= float(n2)
	return Color(acc.x, acc.y, acc.z)
