class_name DisenosKitEstructura
extends RefCounted
## LA PARTE DE LA CAMISETA 2D QUE NO CAMBIA (2-11-2026): para un tamaño, de frente o de espaldas, con un cuello dado, estos datos no dependen de los colores ni del diseño:
## qué píxeles pintan (la silueta), su luz (volumen del torso, arrugas, costuras, trama), el valor (u, v) con el que el diseño elige el color de la tela y qué es cada píxel
## (tela, ribete del cuello, interior del cuello, tapeta y botones del polo, puño, escudo o marca). `DisenosKit._imagen_camiseta` solo recorre esta lista.
## `tipo`: 0 tela del diseño · 1 color de trim × `fac` · 2 interior del cuello · 3 trim liso · 4 botón · 5 segundo color (escudo).
static var _cache: Dictionary = {}

static func de(escala: float, espalda: bool, cuello: int, detalle: bool) -> Dictionary:
	var k := "%.4f|%d|%d|%d" % [escala, int(espalda), cuello, int(detalle)]
	if _cache.has(k):
		return _cache[k]
	var m := DisenosKit._mascara_camiseta(escala)
	var w := m.get_width()
	var h := m.get_height()
	var xs := PackedInt32Array()
	var ys := PackedInt32Array()
	var al := PackedFloat64Array()
	var uu := PackedFloat64Array()
	var vv := PackedFloat64Array()
	var luzs := PackedFloat64Array()
	var tipos := PackedByteArray()
	var facs := PackedFloat64Array()
	for py in h:
		for px in w:
			var a := m.get_pixel(px, py).a
			if a <= 0.01:
				continue
			var sx := float(px) / escala
			var sy := float(py) / escala
			var manga := sx < 18.0 or sx > 46.0
			var u := clampf((sx - 32.0) / 14.0, -1.0, 1.0) if not manga else signf(sx - 32.0) * 1.05
			var v := clampf(1.0 - (sy - 6.0) / 40.0, 0.0, 1.0)
			var tipo := 0
			var fac := 1.0
			var pico := cuello == 0 and not espalda
			var borde_cuello := (7.5 - (sy - 4.0) * 0.9) if pico else (6.0 - pow(maxf(sy - 4.0, 0.0), 1.4) * 0.9)
			var grosor := 2.4 if cuello == 3 else 1.2
			var cuello_v := absf(sx - 32.0) < borde_cuello and sy < (12.0 if pico else 7.0) and not manga
			var ribete_cuello := not manga and sy < (12.5 if pico else 8.0 + (1.2 if cuello == 3 else 0.0)) and absf(absf(sx - 32.0) - borde_cuello) < grosor and sy > 3.5
			if ribete_cuello:
				tipo = 1
				fac = 0.92 + 0.08 * float(int(sx * 2.0) % 2)
			elif cuello_v and sy < (11.0 if not espalda else 6.5):
				tipo = 2
			if cuello == 2 and not espalda and not manga and absf(sx - 32.0) < 1.1 and sy > 5.5 and sy < 13.5:
				tipo = 3
				if absf(sx - 32.0) < 0.45 and (absf(sy - 9.0) < 0.45 or absf(sy - 12.0) < 0.45):
					tipo = 4
			var dist_puno := minf(absf(sx - 10.0 - (sy - 10.0) * 0.28), absf(sx - 54.0 + (sy - 10.0) * 0.28))
			if manga and dist_puno < 1.6 and sy > 12.0:
				tipo = 1
				fac = 0.9 + 0.1 * float(int(sy * 2.0) % 2)
			var luz := 1.0
			if not manga:
				var cx := (sx - 32.0) / 14.0
				luz = 0.78 + 0.28 * sqrt(maxf(0.0, 1.0 - cx * cx)) - 0.06 * cx
				luz += 0.07 * exp(-pow((sy - 16.0) / 6.0, 2.0)) - 0.05 * clampf((sy - 38.0) / 8.0, 0.0, 1.0)
				luz -= 0.045 * (DisenosKit._ruido(sx * 0.35, sy * 0.12) - 0.5) * (0.6 + clampf((sy - 30.0) / 16.0, 0.0, 1.0))
				if absf(sx - 32.0) > 11.0 and sy > 12.0 and sy < 22.0:
					luz -= 0.12 * (absf(sx - 32.0) - 11.0) / 3.0
			else:
				luz = 0.82 + 0.08 * (1.0 - clampf(absf(sy - 12.0) / 10.0, 0.0, 1.0))
			if (absf(sx - 18.0) < 0.35 or absf(sx - 46.0) < 0.35) and sy > 9.0:
				luz *= 0.8
			if not manga and sy > 43.0 and (absf(sy - 43.8) < 0.25 or absf(sy - 44.8) < 0.25):
				luz *= 0.82
			if detalle and not manga and not espalda:
				var ex := (sx - 38.5) / 3.2
				var ey := (sy - 15.5) / 3.8
				var ancho_e := 1.0 if ey < 0.0 else sqrt(maxf(0.0, 1.0 - ey * ey))
				if absf(ex) < ancho_e and ey > -1.0 and ey < 1.0:
					tipo = 5 if absf(ex) < ancho_e - 0.25 and ey > -0.75 else 3
					if absf(ex) < 0.3 and absf(ey) < 0.35:
						tipo = 3
				var mx := (sx - 25.5) / 2.6
				var my := (sy - 15.8) / 1.6
				if absf(mx) < 1.0 and absf(my - (mx * mx * 0.6 - 0.25)) < 0.3 - mx * 0.1:
					tipo = 3
			luz *= 1.0 + 0.03 * (float((px + py) % 3 == 0) - 0.33)
			xs.append(px)
			ys.append(py)
			al.append(a)
			uu.append(u)
			vv.append(v)
			luzs.append(luz)
			tipos.append(tipo)
			facs.append(fac)
	var r := {"w": w, "h": h, "x": xs, "y": ys, "a": al, "u": uu, "v": vv, "luz": luzs, "tipo": tipos, "fac": facs}
	_cache[k] = r
	return r
