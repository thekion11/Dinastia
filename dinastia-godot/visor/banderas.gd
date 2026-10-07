class_name Banderas
extends RefCounted
## LAS BANDERAS NACIONALES (MEGAPLAN fase 4): dibujadas a mano en código, una
## por país del juego, simplificadas pero reconocibles de un vistazo (franjas,
## cantón, disco, cruz, estrella). Para el estudio del sorteo, la sala de
## prensa y donde haga falta una bandera de tela (`bandera.gdshader`, `dibujo`).
## No hay escudos ni símbolos oficiales detallados: solo los colores y la forma.

const ANCHO := 96
const ALTO := 64
static var _cache := {}

static func textura(codigo: String) -> ImageTexture:
	if _cache.has(codigo):
		return _cache[codigo]
	var img := Image.create(ANCHO, ALTO, false, Image.FORMAT_RGB8)
	_pintar(img, codigo)
	var t := ImageTexture.create_from_image(img)
	_cache[codigo] = t
	return t

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
