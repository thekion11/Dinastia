extends "res://ui/disenos_kit_p3.gd"
## [Capa 4/5 de `disenos_kit.gd`] color_en, _mascara_camiseta, _estampar_sponsors

## LA TABLA DE LAS FAMILIAS (FASE 0, 25-10-2026): familia → su fórmula (`_fam_*`, en las capas
## 2 y 3). Antes era un `match` de 330 líneas dentro de `color_en`; ahora cada fórmula es una función corta
## con su nombre y `color_en` solo la busca aquí. Familia nueva = una fila aquí + su `_fam_*` (y el shader).
## Es `static var` y no `const` porque GDScript no admite Callables en una constante; se arma al cargar el
## script (no a mitad de un dibujo) y nadie la modifica.
static var FORMULAS: Dictionary = {
	1: _fam_franjas, 2: _fam_aros, 3: _fam_banda, 4: _fam_panos_v, 5: _fam_bloques_h,
	6: _fam_franja_pecho, 7: _fam_canesu, 8: _fam_cuadros, 9: _fam_degrade, 10: _fam_chevron,
	11: _fam_cruz, 12: _fam_paneles_lado, 13: _fam_franja_central, 14: _fam_tiza, 15: _fam_ondas,
	16: _fam_zigzag, 17: _fam_lunares, 18: _fam_rombos, 19: _fam_escamas, 20: _fam_rayos,
	21: _fam_anillos, 22: _fam_camuflaje, 23: _fam_arcoiris, 24: _fam_marco, 25: _fam_pinceladas,
	26: _fam_tartan, 27: _fam_diamantes, 28: _fam_franjas_crecientes, 29: _fam_pixel,
	30: _fam_puntos_degradados, 31: _fam_curvas_nivel, 32: _fam_marmol, 33: _fam_fragmentos,
	34: _fam_mangas, 35: _fam_diagonal_partida, 36: _fam_relampago, 37: _fam_cuadricula,
	38: _fam_estrellas, 39: _fam_franjas_degradadas, 40: _fam_faja_rayas, 41: _fam_resplandor,
	42: _fam_puntos_diagonal, 43: _fam_v_ancha, 44: _fam_raglan, 45: _fam_doble_faja,
	46: _fam_franjas_asim, 47: _fam_pecho_zigzag, 48: _fam_panal, 49: _fam_triangulos,
	50: _fam_olas_v, 51: _fam_cebra, 52: _fam_rayas_diag, 53: _fam_espiga, 54: _fam_codigo_barras,
	55: _fam_circulo, 56: _fam_cuello_v, 57: _fam_costados_rayados, 58: _fam_llamas, 59: _fam_mosaico,
	60: _fam_rombo_central, 61: _fam_vichy, 62: _fam_estela
}

## El color del diseño en (u, v) del torso: el INTÉRPRETE de la tabla. Los 12 de siempre (familias 100-111)
## usan la fórmula vieja en las coordenadas de reposo `x`, `y`; el resto, la fórmula de su familia en FORMULAS;
## una familia sin fórmula (o el liso, 0) da el color de fondo.
static func color_en(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var f := int(d[2])
	if f >= 100:
		return cols[0].lerp(cols[1], _legado(f - 100, u * 0.215, 1.0 + v * 0.52))
	var formula: Callable = FORMULAS.get(f, Callable())
	return formula.call(d, cols, u, v) if formula.is_valid() else cols[0]

## La silueta de la camiseta (la misma de `Jersey.svg_de`), en blanco.
static func _mascara_camiseta(escala: float) -> Image:
	var svg := '<svg width="64" height="52" viewBox="0 0 64 52" xmlns="http://www.w3.org/2000/svg"><path d="M20 4 8 10l4 10 6-3v29h28V17l6 3 4-10L44 4l-6 3h-12z" fill="#fff"/></svg>'
	var img := Image.new()
	img.load_svg_from_string(svg, escala)
	return img

## Los patrocinadores sobre la camiseta 2D: el del pecho entre el escudo y el
## bajo, el de la manga en la manga izquierda del jugador y el de la espalda
## debajo del número. Se estampan con la luz del tejido (se multiplican por la
## luminosidad que ya tiene la tela) para que no parezcan pegatinas.
static func _estampar_sponsors(out: Image, escala: float, fondo: Color, sp: Dictionary, espalda: bool) -> void:
	var zonas: Array = []
	if not espalda and sp.has("pecho"):
		zonas.append(["pecho", Rect2(20.0, 20.0, 24.0, 9.5), false])
	if not espalda and sp.has("manga"):
		zonas.append(["manga", Rect2(47.5, 10.0, 5.5, 5.5), true])
	if espalda and sp.has("espalda"):
		zonas.append(["espalda", Rect2(23.0, 8.5, 18.0, 5.0), false])
	for z: Array in zonas:
		var info: Dictionary = sp[String(z[0])]
		var letras := SponsorKit.color_letras(String(info.get("color", "#ffffff")), fondo)
		var img := SponsorKit.imagen(String(info.get("marca", "")), String(info.get("color", "#ffffff")), letras, bool(z[2])).duplicate() as Image
		var zona: Rect2 = z[1]
		## Encajar sin deformar, centrado en la zona.
		var asp := float(img.get_width()) / float(img.get_height())
		var r := zona
		if asp > zona.size.x / zona.size.y:
			r.size.y = zona.size.x / asp
		else:
			r.size.x = zona.size.y * asp
		r.position = zona.position + (zona.size - r.size) * 0.5
		var rw := int(r.size.x * escala)
		var rh := int(r.size.y * escala)
		img.resize(maxi(rw, 1), maxi(rh, 1), Image.INTERPOLATE_LANCZOS)
		var ox := int(r.position.x * escala)
		var oy := int(r.position.y * escala)
		for py in img.get_height():
			for px in img.get_width():
				var src := img.get_pixel(px, py)
				if src.a <= 0.02:
					continue
				var tx := ox + px
				var ty := oy + py
				if tx < 0 or ty < 0 or tx >= out.get_width() or ty >= out.get_height():
					continue
				var dst := out.get_pixel(tx, ty)
				if dst.a <= 0.01:
					continue
				## La luz de la tela en ese punto, respecto del color base.
				var luz := clampf(dst.get_luminance() / maxf(fondo.get_luminance(), 0.05), 0.75, 1.15)
				var c := dst.lerp(Color(src.r * luz, src.g * luz, src.b * luz), src.a * 0.96)
				c.a = dst.a
				out.set_pixel(tx, ty, c)
