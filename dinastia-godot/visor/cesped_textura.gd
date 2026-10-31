class_name CespedTextura
extends RefCounted
## LA TEXTURA DEL CORTE DEL CÉSPED (franjas, damero, círculos…), píxel a píxel. Salió de
## `StadiumBuilder._make_grass_texture` (30-10-2026), que ahora la guarda en caché.

static func nueva(patron: String, claro: Color, oscuro: Color) -> Image:
	var n := 256
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	for y in range(n):
		for x in range(n):
			var u := float(x) / n
			var v := float(y) / n
			var band := 0
			match patron:
				## ~6 m por franja (20 a lo largo), como el corte real.
				"rayas":
					band = int(v * 20.0)
				"rayasH":
					band = int(u * 20.0)
				"damero":
					band = int(u * 10.0) + int(v * 10.0)
				"damGrande":
					band = int(u * 5.0) + int(v * 5.0)
				## (`Club` sortea "circulos": antes no casaba y salía liso.)
				"circular", "circulos":
					band = int(Vector2(u - 0.5, v - 0.5).length() * 16.0)
				"diagonal":
					band = int((u + v) * 10.0)
				"espiga":
					band = int((u + fmod(v * 6.0, 1.0)) * 8.0)
				"cruz":
					band = 1 if (absf(u - 0.5) < 0.12 or absf(v - 0.5) < 0.12) else 0
				"abanico":
					band = int(atan2(v - 0.5, u - 0.5) * 6.0)
				"rombos":
					band = int((absf(u - 0.5) + absf(v - 0.5)) * 14.0)
				## (25-10-2026, «rayas, sin bloques»): «mitades» eran DOS bloques lisos
				## de 58 m, y desde la tele el campo se leía partido en dos losas. La
				## cortadora deja igual sus franjas dentro de cada mitad: van suaves
				## (a un 30 %, el nivel intermedio que entiende `cesped_mascara`).
				"mitades":
					var lado := claro if v < 0.5 else oscuro
					var otro := oscuro if v < 0.5 else claro
					img.set_pixel(x, y, lado.lerp(otro, 0.3) if int(v * 20.0) % 2 == 1 else lado)
					continue
				## "liso" (y lo desconocido): en un campo de verdad el corte
				## siempre se nota un poco -franjas muy suaves, un tercio-. (Hasta el
				## 25-10 la máscara del shader era de dos niveles y «liso» salía con
				## las mismas franjas fuertes que «rayas».)
				_:
					band = int(v * 20.0)
					img.set_pixel(x, y, oscuro.lerp(claro, 0.3) if band % 2 == 0 else oscuro)
					continue
			img.set_pixel(x, y, claro if band % 2 == 0 else oscuro)
	return img
