class_name Banderas
extends RefCounted
## LAS BANDERAS NACIONALES (MEGAPLAN fase 4): dibujadas a mano en código, una
## por país del juego, simplificadas pero reconocibles de un vistazo (franjas,
## cantón, disco, cruz, estrella). Para el estudio del sorteo, la sala de
## prensa y donde haga falta una bandera de tela (`bandera.gdshader`, `dibujo`).
## No hay escudos ni símbolos oficiales detallados: solo los colores y la forma.
##
## BANDERAS DETALLADAS (26-10-2026, aprobado por el dueño): si existe el SVG de
## flag-icons (MIT, `assets/banderas/`, ver LEEME.txt) se usa ese, escalado al
## mismo ANCHO x ALTO de siempre para no mover ningún diseño; si falta, el
## dibujo de abajo. `solo_dibujo` fuerza el dibujo (pruebas y comparaciones).

const ANCHO := 96
const ALTO := 64
static var _cache := {}
static var solo_dibujo := false

## Código FIFA del juego -> nombre del SVG (ISO 3166-1 alfa-2; las naciones
## británicas, con su subcódigo).
const ISO := {
	"ALB": "al", "ALG": "dz", "ANG": "ao", "ARG": "ar", "ARM": "am", "AUS": "au", "AUT": "at", "BEL": "be",
	"BEN": "bj", "BFA": "bf", "BIH": "ba", "BOL": "bo", "BRA": "br", "BUL": "bg", "CAN": "ca", "CHI": "cl",
	"CIV": "ci", "CMR": "cm", "COD": "cd", "COL": "co", "CPV": "cv", "CRC": "cr", "CRO": "hr", "CUR": "cw",
	"CZE": "cz", "DEN": "dk", "ECU": "ec", "EGY": "eg", "ENG": "gb-eng", "ESP": "es", "FIN": "fi", "FRA": "fr",
	"GAB": "ga", "GAM": "gm", "GEO": "ge", "GER": "de", "GHA": "gh", "GRE": "gr", "GUI": "gn", "HON": "hn",
	"HUN": "hu", "IRL": "ie", "IRN": "ir", "ISR": "il", "ITA": "it", "JAM": "jm", "JPN": "jp", "KOR": "kr",
	"KSA": "sa", "KVX": "xk", "MAR": "ma", "MEX": "mx", "MKD": "mk", "MLI": "ml", "MNE": "me", "MOZ": "mz",
	"NED": "nl", "NGA": "ng", "NOR": "no", "NZL": "nz", "PAN": "pa", "PAR": "py", "PER": "pe", "POL": "pl",
	"POR": "pt", "QAT": "qa", "ROU": "ro", "RSA": "za", "SCO": "gb-sct", "SEN": "sn", "SRB": "rs", "SUI": "ch",
	"SUR": "sr", "SVK": "sk", "SVN": "si", "SWE": "se", "TOG": "tg", "TRI": "tt", "TUN": "tn", "TUR": "tr",
	"UKR": "ua", "URU": "uy", "USA": "us", "UZB": "uz", "VEN": "ve", "WAL": "gb-wls", "ZAM": "zm",
	## 27-10-2026: las 15 nacionalidades de jugadores que no tenían bandera, en PNG del paquete del dueño («Todas las banderas del mundo»).
	"BDI": "bi", "CAF": "cf", "GNB": "gw", "GNQ": "gq", "HAI": "ht", "JOR": "jo", "KOS": "xk", "MAD": "mg", "MLT": "mt", "PAL": "ps", "PHI": "ph", "RUS": "ru", "SLV": "sv", "SYR": "sy", "ZIM": "zw",
}

static func textura(codigo: String) -> ImageTexture:
	if _cache.has(codigo):
		return _cache[codigo]
	var img := _detallada(codigo)
	if img == null:
		img = Image.create(ANCHO, ALTO, false, Image.FORMAT_RGB8)
		_pintar(img, codigo)
	var t := ImageTexture.create_from_image(img)
	_cache[codigo] = t
	return t

## La bandera de flag-icons como imagen ANCHO x ALTO RGB8 (el mismo formato que
## el dibujo, para quien la duplica o la lee pixel a pixel), o null si no está.
static func _detallada(codigo: String) -> Image:
	if solo_dibujo or not ISO.has(codigo):
		return null
	var ruta := "res://assets/banderas/%s.svg" % ISO[codigo]
	if not ResourceLoader.exists(ruta):
		ruta = ruta.get_basename() + ".png"
	if not ResourceLoader.exists(ruta):
		return null
	var tex := load(ruta) as Texture2D
	if tex == null:
		return null
	var img := tex.get_image()
	if img == null or img.is_empty():
		return null
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGB8)
	img.resize(ANCHO, ALTO, Image.INTERPOLATE_LANCZOS)
	return img

static func _franjas(img: Image, colores: Array, vertical := false, pesos: Array = []) -> void:
	var total := 0.0
	for k in colores.size():
		total += float(pesos[k]) if k < pesos.size() else 1.0
	for y in ALTO:
		for x in ANCHO:
			var u := (float(x) / ANCHO) if vertical else (float(y) / ALTO)
			var acc := 0.0
			var c: Color = colores[colores.size() - 1]
			for k in colores.size():
				acc += (float(pesos[k]) if k < pesos.size() else 1.0) / total
				if u < acc:
					c = colores[k]
					break
			img.set_pixel(x, y, c)

static func _rect(img: Image, x0: int, y0: int, w: int, h: int, c: Color) -> void:
	img.fill_rect(Rect2i(x0, y0, w, h), c)

static func _disco(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	for y in range(maxi(0, int(cy - r)), mini(ALTO, int(cy + r) + 1)):
		for x in range(maxi(0, int(cx - r)), mini(ANCHO, int(cx + r) + 1)):
			if Vector2(x - cx, y - cy).length() <= r:
				img.set_pixel(x, y, c)

## Una estrella de cinco puntas (relleno por ángulo).
static func _estrella(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	for y in range(maxi(0, int(cy - r)), mini(ALTO, int(cy + r) + 1)):
		for x in range(maxi(0, int(cx - r)), mini(ANCHO, int(cx + r) + 1)):
			var d := Vector2(x - cx, y - cy)
			var a := fposmod(atan2(d.x, -d.y), TAU / 5.0) - TAU / 10.0
			var lim := r * (0.38 + 0.62 * pow(absf(cos(a * 2.5)), 6.0))
			if d.length() <= lim:
				img.set_pixel(x, y, c)

static func _pintar(img: Image, codigo: String) -> void:
	var B := Color.WHITE
	var rojo := Color("d52b1e")
	var azul := Color("0039a6")
	var amarillo := Color("fcd116")
	var verde := Color("009b3a")
	var negro := Color("111111")
	match codigo:
		"CHI":
			_franjas(img, [B, rojo])
			_rect(img, 0, 0, ANCHO / 3, ALTO / 2, azul)
			_estrella(img, ANCHO / 6.0, ALTO / 4.0, 9.0, B)
		"ARG":
			_franjas(img, [Color("74acdf"), B, Color("74acdf")])
			_disco(img, ANCHO / 2.0, ALTO / 2.0, 6.0, Color("f6b40e"))
		"BRA":
			_franjas(img, [verde])
			for y in ALTO:
				for x in ANCHO:
					if absf(float(x) - ANCHO / 2.0) / (ANCHO * 0.42) + absf(float(y) - ALTO / 2.0) / (ALTO * 0.40) <= 1.0:
						img.set_pixel(x, y, Color("fedf00"))
			_disco(img, ANCHO / 2.0, ALTO / 2.0, 13.0, Color("002776"))
		"URU":
			var cols: Array = []
			for k in 9:
				cols.append(B if k % 2 == 0 else Color("0038a8"))
			_franjas(img, cols)
			_rect(img, 0, 0, 34, 28, B)
			_disco(img, 17.0, 14.0, 8.0, Color("fcd116"))
		"COL":
			_franjas(img, [amarillo, Color("003893"), Color("ce1126")], false, [2, 1, 1])
		"ECU":
			_franjas(img, [amarillo, Color("034ea2"), Color("ed1c24")], false, [2, 1, 1])
			_disco(img, ANCHO / 2.0, ALTO / 2.0, 7.0, Color("6b4a2b"))
		"PER":
			_franjas(img, [Color("d91023"), B, Color("d91023")], true)
		"PAR":
			_franjas(img, [Color("d52b1e"), B, Color("0038a8")])
		"BOL":
			_franjas(img, [Color("d52b1e"), Color("f9e300"), Color("007934")])
		"VEN":
			_franjas(img, [Color("ffcc00"), Color("00247d"), Color("cf142b")])
			for k in 8:
				var a := PI * (0.15 + 0.7 * float(k) / 7.0)
				_disco(img, ANCHO / 2.0 - cos(a) * 18.0, ALTO / 2.0 + 6.0 - sin(a) * 12.0, 1.6, B)
		"ESP":
			_franjas(img, [Color("aa151b"), Color("f1bf00"), Color("aa151b")], false, [1, 2, 1])
		"ENG":
			_franjas(img, [B])
			_rect(img, ANCHO / 2 - 6, 0, 12, ALTO, Color("ce1124"))
			_rect(img, 0, ALTO / 2 - 6, ANCHO, 12, Color("ce1124"))
		"ITA":
			_franjas(img, [Color("009246"), B, Color("ce2b37")], true)
		"GER":
			_franjas(img, [negro, Color("dd0000"), Color("ffce00")])
		"FRA":
			_franjas(img, [Color("0055a4"), B, Color("ef4135")], true)
		"JPN":
			_franjas(img, [B])
			_disco(img, ANCHO / 2.0, ALTO / 2.0, 19.0, Color("bc002d"))
		"KOR":
			_franjas(img, [B])
			_disco(img, ANCHO / 2.0, ALTO / 2.0, 16.0, Color("003478"))
			for y in ALTO:
				for x in ANCHO:
					var d := Vector2(x - ANCHO / 2.0, y - ALTO / 2.0)
					if d.length() <= 16.0 and d.y < sin(d.x / 16.0 * PI) * 5.0:
						img.set_pixel(x, y, Color("cd2e3a"))
			for k: Vector2 in [Vector2(14, 12), Vector2(82, 12), Vector2(14, 52), Vector2(82, 52)]:
				_rect(img, int(k.x) - 7, int(k.y) - 5, 14, 2, negro)
				_rect(img, int(k.x) - 7, int(k.y) - 1, 14, 2, negro)
				_rect(img, int(k.x) - 7, int(k.y) + 3, 14, 2, negro)
		"KSA":
			_franjas(img, [Color("006c35")])
			_rect(img, 20, 42, 56, 3, B)
			_rect(img, 24, 22, 48, 8, Color("d8e6dd"))
		"EGY":
			_franjas(img, [Color("ce1126"), B, negro])
			_disco(img, ANCHO / 2.0, ALTO / 2.0, 6.0, Color("c09300"))
		"MAR":
			_franjas(img, [Color("c1272d")])
			_estrella(img, ANCHO / 2.0, ALTO / 2.0, 15.0, Color("006233"))
		"RSA":
			_franjas(img, [Color("de3831"), Color("002395")])
			_rect(img, 0, ALTO / 2 - 9, ANCHO, 18, B)
			_rect(img, 0, ALTO / 2 - 6, ANCHO, 12, Color("007a4d"))
			for y in ALTO:
				var ancho_t := int((1.0 - absf(float(y) - ALTO / 2.0) / (ALTO / 2.0)) * 36.0)
				for x in ancho_t:
					img.set_pixel(x, y, Color("ffb612") if x > ancho_t - 4 else negro)
		"AUS":
			_franjas(img, [Color("00008b")])
			_rect(img, 0, 0, 48, 32, Color("00008b"))
			_rect(img, 20, 0, 8, 32, B)
			_rect(img, 0, 12, 48, 8, B)
			_rect(img, 22, 0, 4, 32, Color("cf142b"))
			_rect(img, 0, 14, 48, 4, Color("cf142b"))
			for k: Vector2 in [Vector2(24, 48), Vector2(72, 16), Vector2(62, 34), Vector2(80, 30), Vector2(72, 54)]:
				_estrella(img, k.x, k.y, 4.5, B)
		"MEX":
			_franjas(img, [Color("006847"), B, Color("ce1126")], true)
			_disco(img, ANCHO / 2.0, ALTO / 2.0, 7.0, Color("8c5a2b"))
		"USA":
			var cols2: Array = []
			for k in 13:
				cols2.append(Color("b22234") if k % 2 == 0 else B)
			_franjas(img, cols2)
			_rect(img, 0, 0, 40, 34, Color("3c3b6e"))
			for fy in 5:
				for fx in 6:
					_disco(img, 4.0 + fx * 6.5, 4.0 + fy * 6.5, 1.2, B)
		## Las selecciones rivales sin liga en el mundo (17-10-2026).
		"POR":
			_franjas(img, [Color("046a38"), Color("da291c")], true, [2, 3])
			_disco(img, ANCHO * 0.4, ALTO * 0.5, 11.0, amarillo)
		"NED":
			_franjas(img, [Color("ae1c28"), B, Color("21468b")])
		"BEL":
			_franjas(img, [negro, Color("fdda24"), Color("ef3340")], true)
		"CRO":
			_franjas(img, [Color("ff0000"), B, Color("171796")])
			for i in 3:
				for k in 2:
					_rect(img, ANCHO / 2 - 9 + i * 6, ALTO / 2 - 9 + k * 6, 6, 6, Color("ff0000") if (i + k) % 2 == 0 else B)
		"DEN":
			_franjas(img, [Color("c8102e")])
			_rect(img, 0, ALTO / 2 - 5, ANCHO, 10, B)
			_rect(img, ANCHO / 3 - 5, 0, 10, ALTO, B)
		"SEN":
			_franjas(img, [Color("00853f"), Color("fdef42"), Color("e31b23")], true)
			_estrella(img, ANCHO / 2.0, ALTO / 2.0, 9.0, Color("00853f"))
		"NGA":
			_franjas(img, [Color("008751"), B, Color("008751")], true)
		"CMR":
			_franjas(img, [Color("007a5e"), Color("ce1126"), Color("fcd116")], true)
			_estrella(img, ANCHO / 2.0, ALTO / 2.0, 9.0, Color("fcd116"))
		"IRN":
			_franjas(img, [Color("239f40"), B, Color("da0000")])
		"CRC":
			_franjas(img, [Color("002b7f"), B, Color("ce1126"), B, Color("002b7f")], false, [1, 1, 2, 1, 1])
		"CAN":
			_franjas(img, [Color("d52b1e"), B, Color("d52b1e")], true, [1, 2, 1])
			_estrella(img, ANCHO / 2.0, ALTO / 2.0, 12.0, Color("d52b1e"))
		"NZL":
			_franjas(img, [Color("012169")])
			for e in [[0.72, 0.3], [0.62, 0.5], [0.82, 0.48], [0.72, 0.75]]:
				_estrella(img, ANCHO * float(e[0]), ALTO * float(e[1]), 5.0, Color("c8102e"))
		"QAT":
			_franjas(img, [B, Color("8a1538")], true, [1, 2])
		_:
			## Sin dibujo propio: dos franjas con colores sacados del código.
			var h := absi(codigo.hash())
			var c1 := Color.from_hsv(float(h % 360) / 360.0, 0.7, 0.75)
			var c2 := Color.from_hsv(float((h / 360) % 360) / 360.0, 0.6, 0.9)
			_franjas(img, [c1, B, c2])

## La bandera de un club: sus dos colores en franjas verticales, como las que
## cuelgan en una sala de prensa.
static func de_club(c: Club) -> ImageTexture:
	var clave := "club_%s_%s" % [c.color1, c.color2]
	if _cache.has(clave):
		return _cache[clave]
	var img := Image.create(ANCHO, ALTO, false, Image.FORMAT_RGB8)
	_franjas(img, [Color(c.color1), Color(c.color2), Color(c.color1)], true)
	var t := ImageTexture.create_from_image(img)
	_cache[clave] = t
	return t

## Un país por su nombre en la tabla de selecciones («Chile» -> «CHI»).
static func codigo_de(nombre: String) -> String:
	var t: Variant = Datos.tabla("PAIS_SELECCION")
	if t is Dictionary:
		for k: String in t:
			if Nombres.limpiar(String(t[k])) == Nombres.limpiar(nombre):
				return k
	return ""
