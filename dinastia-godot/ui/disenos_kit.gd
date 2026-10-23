class_name DisenosKit
extends "res://ui/disenos_kit_p2.gd"
## (Parte 3 de 3 de `disenos_kit.gd`.)

static func _imagen_camiseta(clave: String, cols: Array[Color], trim: int, ancho_px: int, espalda: bool = false, sp: Dictionary = {}, cuello: int = 0) -> Image:
	var ss := 2 if ancho_px <= 200 else 1
	var escala := float(ancho_px * ss) / 64.0
	var m := _mascara_camiseta(escala)
	var w := m.get_width()
	var h := m.get_height()
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var d := diseno(clave)
	var c_trim: Color = cols[clampi(trim, 0, 4)]
	var detalle := ancho_px >= 96
	for py in h:
		for px in w:
			var al := m.get_pixel(px, py).a
			if al <= 0.01:
				continue
			var sx := float(px) / escala
			var sy := float(py) / escala
			var manga := sx < 18.0 or sx > 46.0
			## La manga va con u = ±1,05 (fuera del torso), igual que en el 3D.
			var u := clampf((sx - 32.0) / 14.0, -1.0, 1.0) if not manga else signf(sx - 32.0) * 1.05
			var v := clampf(1.0 - (sy - 6.0) / 40.0, 0.0, 1.0)
			var col := color_en(d, cols, u, v)
			## Cuello en pico, acanalado.
			## De espaldas el cuello es redondo y bajo.
			## El corte: pico (0) delante; redondo, polo y mao, redondos.
			var pico := cuello == 0 and not espalda
			var borde_cuello := (7.5 - (sy - 4.0) * 0.9) if pico else (6.0 - pow(maxf(sy - 4.0, 0.0), 1.4) * 0.9)
			var grosor := 2.4 if cuello == 3 else 1.2
			var cuello_v := absf(sx - 32.0) < borde_cuello and sy < (12.0 if pico else 7.0) and not manga
			var ribete_cuello := not manga and sy < (12.5 if pico else 8.0 + (1.2 if cuello == 3 else 0.0)) and absf(absf(sx - 32.0) - borde_cuello) < grosor and sy > 3.5
			if ribete_cuello:
				col = c_trim * (0.92 + 0.08 * float(int(sx * 2.0) % 2))
			elif cuello_v and sy < (11.0 if not espalda else 6.5):
				## Por dentro del pico se ve la tela de atrás, en sombra.
				col = cols[0] * 0.55
			## Polo: la tapeta con dos botones.
			if cuello == 2 and not espalda and not manga and absf(sx - 32.0) < 1.1 and sy > 5.5 and sy < 13.5:
				col = c_trim
				if absf(sx - 32.0) < 0.45 and (absf(sy - 9.0) < 0.45 or absf(sy - 12.0) < 0.45):
					col = cols[0].darkened(0.3)
			## Puños acanalados.
			var dist_puno := minf(absf(sx - 10.0 - (sy - 10.0) * 0.28), absf(sx - 54.0 + (sy - 10.0) * 0.28))
			if manga and dist_puno < 1.6 and sy > 12.0:
				col = c_trim * (0.9 + 0.1 * float(int(sy * 2.0) % 2))
			var luz := 1.0
			if not manga:
				## Volumen del torso: cilindro con la luz arriba a la izquierda.
				var cx := (sx - 32.0) / 14.0
				luz = 0.78 + 0.28 * sqrt(maxf(0.0, 1.0 - cx * cx)) - 0.06 * cx
				## Brillo del pecho y caída hacia el bajo.
				luz += 0.07 * exp(-pow((sy - 16.0) / 6.0, 2.0)) - 0.05 * clampf((sy - 38.0) / 8.0, 0.0, 1.0)
				## Arrugas suaves de tela (más en la cintura).
				luz -= 0.045 * (_ruido(sx * 0.35, sy * 0.12) - 0.5) * (0.6 + clampf((sy - 30.0) / 16.0, 0.0, 1.0))
				## Sombra bajo las mangas.
				if absf(sx - 32.0) > 11.0 and sy > 12.0 and sy < 22.0:
					luz -= 0.12 * (absf(sx - 32.0) - 11.0) / 3.0
			else:
				luz = 0.82 + 0.08 * (1.0 - clampf(absf(sy - 12.0) / 10.0, 0.0, 1.0))
			## Costuras: hombros, laterales y doble pespunte del bajo.
			if (absf(sx - 18.0) < 0.35 or absf(sx - 46.0) < 0.35) and sy > 9.0:
				luz *= 0.8
			if not manga and sy > 43.0 and (absf(sy - 43.8) < 0.25 or absf(sy - 44.8) < 0.25):
				luz *= 0.82
			if detalle and not manga and not espalda:
				## Escudo: izquierda del pecho (derecha del dibujo).
				var ex := (sx - 38.5) / 3.2
				var ey := (sy - 15.5) / 3.8
				var ancho_e := 1.0 if ey < 0.0 else sqrt(maxf(0.0, 1.0 - ey * ey))
				if absf(ex) < ancho_e and ey > -1.0 and ey < 1.0:
					col = cols[1] if absf(ex) < ancho_e - 0.25 and ey > -0.75 else c_trim
					if absf(ex) < 0.3 and absf(ey) < 0.35:
						col = c_trim
				## Marca: un "ala" a la derecha del pecho (izquierda del dibujo).
				var mx := (sx - 25.5) / 2.6
				var my := (sy - 15.8) / 1.6
				if absf(mx) < 1.0 and absf(my - (mx * mx * 0.6 - 0.25)) < 0.3 - mx * 0.1:
					col = c_trim
			## Trama del tejido.
			var trama := 1.0 + 0.03 * (float((px + py) % 3 == 0) - 0.33)
			luz *= trama
			out.set_pixel(px, py, Color(clampf(col.r * luz, 0.0, 1.0), clampf(col.g * luz, 0.0, 1.0), clampf(col.b * luz, 0.0, 1.0), al))
	_estampar_sponsors(out, escala, cols[0], sp, espalda)
	if ss > 1:
		out.resize(w / ss, h / ss, Image.INTERPOLATE_LANCZOS)
	return out

## La camiseta 2D de un diseño, con el cuello y los puños del color de trim.
## REALISMO (26-9-2026, pedido: "se ven poco realistas"):
##   - se dibuja al doble de tamaño y se reduce (bordes suaves, sin escalones);
##   - volumen: el torso más oscuro hacia los costados, brillo en el pecho y los
##     hombros, sombra bajo las mangas y arrugas suaves de tela;
##   - confección: cuello en pico acanalado, puños acanalados, costuras de
##     hombro y laterales, doble pespunte en el bajo;
##   - escudo del club (izquierda del pecho) y marca de ropa (derecha);
##   - la trama del tejido, un punto fino que se nota de cerca.
static func textura_camiseta(clave: String, cols: Array[Color], trim: int = 1, ancho_px: int = 128) -> Texture2D:
	var k := "%s|%s|%d|%d" % [clave, ",".join(cols.map(func(c: Color) -> String: return c.to_html(false))), trim, ancho_px]
	if _cache.has(k):
		return _cache[k]
	var out := _imagen_camiseta(clave, cols, trim, ancho_px)
	var t := ImageTexture.create_from_image(out)
	_cache[k] = t
	return t

## El color de un botín: `z` de 0 (talón) a 1 (punta), `alto` de 0 (suela) a 1.
static func _color_botin(dibujo: int, c1: Color, c2: Color, z: float, alto: float) -> Color:
	match dibujo:
		1: return c2 if z > 0.72 else c1
		2: return c2 if z < 0.25 else c1
		3: return c2 if absf(alto - 0.5) < 0.14 else c1
		4: return c1.lerp(c2, z)
		5: return c2 if fposmod(z * 6.0, 1.0) < 0.3 else c1
		6: return c2 if _ruido(z * 5.0, alto * 3.0) > 0.55 else c1
		7: return c2 if alto > 0.5 else c1
		8: return c2 if absf(alto - 0.45 - sin(z * 6.0) * 0.18) < 0.1 else c1
	return c1

## La equipación entera en 2D (camiseta, pantalón, medias y botines), de
## frente o de espaldas con el número.
static func textura_completa(kit: Dictionary, espalda: bool = false, ancho_px: int = 160) -> Texture2D:
	var cols := colores(kit)
	var ss := 2
	var camiseta := _imagen_camiseta(String(kit.get("dis", "liso")), cols, int(kit.get("trim", 1)), ancho_px * ss, espalda, kit.get("sp", {}), int(kit.get("cuello", 0)))
	var w := camiseta.get_width()
	var escala := float(w) / 64.0
	var h := int(escala * 112.0)
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var pant: Dictionary = kit.get("pant", {})
	var med: Dictionary = kit.get("med", {})
	var bot: Dictionary = kit.get("bot", {})
	var pc1 := _col(pant.get("c1", "ffffff"))
	var pc2 := _col(pant.get("c2", "000000"))
	var mc1 := _col(med.get("c1", "ffffff"))
	var mc2 := _col(med.get("c2", "000000"))
	var bm: Array = BOTINES[indice_de(BOTINES, String(bot.get("mod", "clasico")))]
	var bc1 := _col(bot.get("c1", bm[3]))
	var bc2 := _col(bot.get("c2", bm[4]))
	var bc3 := _col(bot.get("c3", bm[5]))
	var pdis := String(pant.get("dis", "liso"))
	var mdis := String(med.get("dis", "lisas"))
	for py in range(int(40.0 * escala), h):
		var sy := float(py) / escala
		for px in w:
			var sx := float(px) / escala
			var col := Color(0, 0, 0, 0)
			var luz := 1.0
			## Pantalón: de 44 a 64, con la entrepierna y bajos acampanados.
			var abre := (sy - 44.0) * 0.12
			var entrepierna := sy > 54.0 and absf(sx - 32.0) < (sy - 54.0) * 0.3
			if sy >= 44.0 and sy < 64.0 and sx > 18.5 - abre and sx < 45.5 + abre and not entrepierna:
				var lado := sx < 32.0
				var ex := clampf(absf(sx - 32.0) / (13.5 + abre), 0.0, 1.0)
				col = pc1
				match pdis:
					"lateral": col = pc2 if ex > 0.85 else pc1
					"doble_lateral": col = pc2 if (ex > 0.78 and ex < 0.84) or ex > 0.9 else pc1
					"ribete": col = pc2 if sy > 61.5 else pc1
					"bicolor": col = pc2 if not lado else pc1
					"degrade": col = pc1.lerp(pc2, clampf((sy - 44.0) / 20.0, 0.0, 1.0))
				## Volumen de cada pernera, cintura elástica y pliegues.
				var cpierna := (sx - (25.0 if lado else 39.0)) / 8.0
				luz = 0.8 + 0.22 * sqrt(maxf(0.0, 1.0 - cpierna * cpierna * 0.8))
				if sy < 46.0:
					luz *= 0.88 + 0.06 * float(int(sy * 3.0) % 2)
				luz -= 0.05 * (_ruido(sx * 0.4, sy * 0.2) - 0.5)
			## Medias: de 66 a 96, con la pantorrilla más ancha.
			elif sy >= 66.0 and sy < 96.0:
				var anchom := 4.2 + 0.9 * sin(clampf((sy - 66.0) / 18.0, 0.0, 1.0) * PI)
				var ci := 25.0
				var cd := 39.0
				if absf(sx - ci) < anchom or absf(sx - cd) < anchom:
					var t := (sy - 66.0) / 30.0
					col = mc1
					match mdis:
						"aros": col = mc2 if fposmod(t * 8.0, 1.0) < 0.4 else mc1
						"franja": col = mc2 if t < 0.18 else mc1
						"dos_franjas": col = mc2 if (t > 0.05 and t < 0.12) or (t > 0.17 and t < 0.24) else mc1
						"bicolor": col = mc2 if t > 0.55 else mc1
						"rombos": col = mc2 if absf(fposmod(t * 6.0, 1.0) - 0.5) + absf(fposmod((sx - 21.0) / 8.0, 1.0) - 0.5) < 0.35 else mc1
					var cm := (sx - (ci if sx < 32.0 else cd)) / anchom
					luz = 0.78 + 0.25 * sqrt(maxf(0.0, 1.0 - cm * cm))
					## Canalé de la media y la vuelta de arriba.
					luz *= 0.96 + 0.04 * float(int(sx * 2.5) % 2)
					if t < 0.07:
						luz *= 0.9
			## Botines: de 96 a 105, con brillo, cordones y tacos.
			if sy >= 95.5 and sy < 105.0:
				var izq := sx < 32.0
				var z := (30.0 - sx) / 14.0 if izq else (sx - 34.0) / 14.0
				var alto := (104.0 - sy) / 8.5
				var techo := 0.95 - smoothstep(0.35, 1.0, z) * 0.5
				if z >= -0.05 and z <= 1.0 and alto >= 0.0 and alto <= techo:
					col = _color_botin(int(bm[2]), bc1, bc2, z, alto)
					luz = 0.85 + 0.35 * exp(-pow((alto - 0.62) / 0.15, 2.0)) * smoothstep(0.2, 0.7, z)
					if alto < 0.14:
						col = bc3
						luz = 0.9
					## Cordones.
					if z > 0.45 and z < 0.8 and alto > techo - 0.16 and int(z * 20.0) % 2 == 0:
						col = Color(0.95, 0.95, 0.95)
				elif z >= 0.0 and z <= 0.95 and alto < 0.0 and alto > -0.1 and fposmod(z * 6.0, 1.0) < 0.35:
					col = bc3 * 0.8
			if col.a > 0.0:
				out.set_pixel(px, py, Color(clampf(col.r * luz, 0.0, 1.0), clampf(col.g * luz, 0.0, 1.0), clampf(col.b * luz, 0.0, 1.0), 1.0))
	## La camiseta, encima del pantalón (el bajo cae por delante de la cintura).
	out.blend_rect(camiseta, Rect2i(0, 0, w, camiseta.get_height()), Vector2i(0, 0))
	out.resize(w / ss, h / ss, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(out)

## Una miniatura de botín (galería).
static func textura_botin(clave: String, c1: Color, c2: Color, c3: Color, ancho_px: int = 72) -> Texture2D:
	var k := "bot|%s|%s|%s|%s|%d" % [clave, c1.to_html(false), c2.to_html(false), c3.to_html(false), ancho_px]
	if _cache.has(k):
		return _cache[k]
	var bm: Array = BOTINES[indice_de(BOTINES, clave)]
	var w := ancho_px
	var h := int(float(ancho_px) * 0.5)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for py in h:
		for px in w:
			var z := float(px) / float(w)
			var alto := 1.0 - float(py) / float(h)
			## Silueta de botín: contrafuerte alto atrás, el hueco del tobillo,
			## el empeine que baja y la puntera redondeada.
			var techo: float
			if z < 0.12:
				techo = 0.88
			elif z < 0.3:
				techo = lerpf(0.88, 0.72, (z - 0.12) / 0.18)
			elif z < 0.88:
				techo = lerpf(0.72, 0.44, (z - 0.3) / 0.58)
			else:
				techo = 0.44 * sqrt(maxf(0.0, 1.0 - pow((z - 0.88) / 0.12, 2.0)))
			if alto > techo or (z < 0.03 and alto > 0.2):
				continue
			var col := _color_botin(int(bm[2]), c1, c2, z, alto)
			if alto < 0.13:
				col = c3
			## Tacos.
			if alto < 0.04 and fposmod(z * 7.0, 1.0) > 0.5:
				continue
			img.set_pixel(px, py, col)
	var t := ImageTexture.create_from_image(img)
	_cache[k] = t
	return t

## Uniforms del shader para esta equipación (los usa `VestidorQ`).
static func uniforms(kit: Dictionary, dorsal: int) -> Dictionary:
	var cols := colores(kit)
	var d := diseno(String(kit.get("dis", "liso")))
	var pant: Dictionary = kit.get("pant", {})
	var med: Dictionary = kit.get("med", {})
	var bot: Dictionary = kit.get("bot", {})
	var bm: Array = BOTINES[indice_de(BOTINES, String(bot.get("mod", "clasico")))]
	var acc: Dictionary = kit.get("acc", {})
	var u := {
		"familia": int(d[2]), "prm": Vector4(float(d[3]), float(d[4]), float(d[5]), float(d[6])),
		"n_cols": int(d[7]), "trim": int(kit.get("trim", 1)),
		"cols": PackedColorArray(cols),
		"color_pantalon": _col(pant.get("c1", "ffffff")), "pant_c2": _col(pant.get("c2", "000000")),
		"pant_dis": indice_de(PANTALONES, String(pant.get("dis", "liso"))),
		"color_medias": _col(med.get("c1", "ffffff")), "med_c2": _col(med.get("c2", "000000")),
		"med_dis": indice_de(MEDIAS, String(med.get("dis", "lisas"))),
		"color_botines": _col(bot.get("c1", bm[3])), "bot_c2": _col(bot.get("c2", bm[4])), "bot_c3": _col(bot.get("c3", bm[5])),
		"bot_dis": int(bm[2]),
		"dorsal": dorsal, "color_num": _col(kit.get("num", "ffffff")),
		"cuello": int(kit.get("cuello", 0)),
		"civil": bool(kit.get("civil", false)),
		## La ropa de calle tapa casi todo el relieve; la camiseta de juego,
		## ajustada, deja ver algo de forma (26-9-2026).
		"alisar": 1.0 if bool(kit.get("civil", false)) else 0.55,
		"holgura": 0.045 if bool(kit.get("civil", false)) else 0.02,
		## Ropa de calle (13-10-2026): manga corta y tatuaje en el antebrazo.
		"manga_corta": bool(kit.get("manga_corta", false)),
		"tatuaje": int(kit.get("tatuaje", 0)),
	}
	for a: Array in ACCESORIOS:
		var k := String(a[0])
		u["acc_" + k] = _col(acc[k]) if acc.has(k) else Color(0, 0, 0, 0)
	u["marca_forma"] = int(MARCA_FORMA.get(String(kit.get("marca", "propia")), 0))
	if kit.get("escudo_tex") is Texture2D:
		u["hay_escudo"] = true
		u["escudo_tex"] = kit["escudo_tex"]
	else:
		u["hay_escudo"] = false
	## Los patrocinadores (pecho, manga, espalda y pantalón).
	var sp: Dictionary = kit.get("sp", {})
	for z: String in ["pecho", "manga", "espalda", "short"]:
		u["hay_sp_" + z] = sp.has(z)
		if sp.has(z):
			var info: Dictionary = sp[z]
			var fondo: Color = cols[0]
			if z == "short":
				fondo = _col(pant.get("c1", "ffffff"))
			var hx := String(info.get("color", "#ffffff"))
			var solo := z == "manga" or z == "short"
			u["sp_" + z] = SponsorKit.textura(String(info.get("marca", "")), hx, SponsorKit.color_letras(hx, fondo), solo)
			u["sp_asp_" + z] = SponsorKit.aspecto(String(info.get("marca", "")), hx, SponsorKit.color_letras(hx, fondo), solo)
	return u
