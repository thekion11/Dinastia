class_name ProbarNativoKit
extends RefCounted
## (19-11-2026) LA PINTURA DE LA CABEZA EN C++ = GDScript (`nativo/src/kit_nativo.cpp`; gemelas `KitTextureFactory._caja_util_gd`, `_color_dominante_gd`, `_retenir_gd`, `_paint_barba_gd`).
## Imágenes de 1024×1024 al azar (RGBA8 con zonas transparentes y blandas, RGB8 y una de otro formato) con piel, pelo y barba de varios tonos; se comparan los resultados byte a byte.
## Devuelve {fallos, textos}.
static func _ruido(rng: RandomNumberGenerator, formato: int, w: int, h: int, bloques: bool) -> Image:
	var datos := PackedByteArray()
	var bpp := 4 if formato == Image.FORMAT_RGBA8 else 3
	datos.resize(w * h * bpp)
	var base := [rng.randi() % 256, rng.randi() % 256, rng.randi() % 256]
	for i in w * h:
		var y := i / w
		var x := i % w
		for c in 3:
			datos[i * bpp + c] = base[c] if (bloques and (x / 60 + y / 60) % 3 == 0) else rng.randi() % 256
		if bpp == 4:
			datos[i * bpp + 3] = 255 if (x / 40 + y / 40) % 5 != 0 else (rng.randi() % 60)
	return Image.create_from_data(w, h, false, formato, datos)

static func probar(nat: Object) -> Dictionary:
	var fallos: Array[String] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 1910
	var fab := KitTextureFactory.new()
	var comparadas := 0
	for caso in range(4):
		var formato := Image.FORMAT_RGBA8 if caso != 2 else Image.FORMAT_RGB8
		var img := _ruido(rng, formato, 1024, 1024, caso % 2 == 0)
		comparadas += 1
		if KitTextureFactory._caja_util_gd(img) != nat.kit_caja_util(img):
			fallos.append("caja útil distinta (caso %d)" % caso)
		for r: Rect2i in [KitTextureFactory.CACHETE_RECT, KitTextureFactory.PELAMBRE_RECT, Rect2i(100, 100, 600, 500)]:
			comparadas += 1
			if var_to_bytes(KitTextureFactory._color_dominante_gd(img, r)) != var_to_bytes(nat.kit_color_dominante(img, r)):
				fallos.append("color dominante distinto (caso %d, zona %s)" % [caso, r])
		if formato == Image.FORMAT_RGBA8:
			for pp in [[Color(0.8, 0.6, 0.5), Color(0.1, 0.07, 0.05)], [Color(0.35, 0.22, 0.15), Color(0.9, 0.8, 0.3)], [Color(1, 1, 1), Color(0, 0, 0)]]:
				var a := Image.create_from_data(1024, 1024, false, Image.FORMAT_RGBA8, img.get_data())
				var b := Image.create_from_data(1024, 1024, false, Image.FORMAT_RGBA8, img.get_data())
				fab._retenir_gd(a, pp[0], pp[1])
				var lp: float = maxf(KitTextureFactory._color_dominante_gd(b, KitTextureFactory.CACHETE_RECT).get_luminance(), 0.12)
				var lq: float = maxf(KitTextureFactory._color_dominante_gd(b, KitTextureFactory.PELAMBRE_RECT).get_luminance(), 0.05)
				var datos: PackedByteArray = nat.kit_retener(b.get_data(), 1024, 1024, pp[0], pp[1], lp, lq, KitTextureFactory.CABEZA_RECT, KitTextureFactory.MANOS_RECT)
				comparadas += 1
				if a.get_data() != datos:
					fallos.append("re-teñido distinto (caso %d, %s)" % [caso, pp])
			for barba in [0, 1, 3, 4, 7]:
				var a2 := Image.create_from_data(1024, 1024, false, Image.FORMAT_RGBA8, img.get_data())
				var b2 := Image.create_from_data(1024, 1024, false, Image.FORMAT_RGBA8, img.get_data())
				fab._paint_barba_gd(a2, Color(0.15, 0.1, 0.08), barba)
				if barba > 0:
					var hecha: Image = nat.kit_barba(b2, Color(0.15, 0.1, 0.08), barba, KitTextureFactory.BARBA_RECT)
					b2.blit_rect(hecha, Rect2i(0, 0, 1024, 1024), Vector2i.ZERO)
				comparadas += 1
				if a2.get_data() != b2.get_data():
					fallos.append("barba %d distinta (caso %d)" % [barba, caso])
	## El trofeo: la paleta recoloreada (RGBA8 y RGB8 al azar).
	for formato: int in [Image.FORMAT_RGBA8, Image.FORMAT_RGB8]:
		var paleta := _ruido(rng, formato, 256, 128, true)
		for cols in [[Color(0.95, 0.75, 0.2), Color(0.3, 0.3, 0.32)], [Color(0.8, 0.8, 0.85), Color(0.15, 0.1, 0.1)]]:
			var t_gd: Image = TrofeoModelo._textura_img_gd(paleta.duplicate() as Image, cols[0], cols[1])
			var t_c: Image = nat.trofeo_textura(paleta, cols[0], cols[1])
			comparadas += 1
			if t_c == null or t_gd.get_data() != t_c.get_data() or t_gd.get_format() != t_c.get_format():
				fallos.append("paleta del trofeo distinta (formato %d)" % formato)
	comparadas += 1
	var raro := Image.create(64, 64, false, Image.FORMAT_L8)
	if nat.kit_barba(raro, Color.BLACK, 3, Rect2i(0, 0, 10, 10)) != null or nat.kit_caja_util(raro).size.x >= 0 or nat.kit_color_dominante(raro, Rect2i(0, 0, 64, 64)).r >= 0.0:
		fallos.append("un formato no soportado debía dar la señal de «no soportado»")
	return {"fallos": fallos, "textos": ["kit de la cabeza: %d comparaciones en imágenes de 1024×1024" % comparadas]}
