class_name TelonesPintados
extends RefCounted
## TRAPOS PINTADOS DE LA HINCHADA (15-11-2026, pasada de estadio).
##
## Los telones de `stadium_builder_p7._telones` eran tela LISA de un color: con la cámara de TV se leían como
## losas celestes (el blanco refleja el cielo) puestas encima de la grada, no como trapos. Un trapo de verdad
## es una sábana PINTADA: rayas del club, bandas, la banda diagonal, cuadros o letras gruesas a brocha.
## Aquí se pinta ese dibujo en una imagen pequeña (256×96, con mipmaps) y se pone de albedo sobre la tela de
## siempre (`Texturas.tela`, que da la trama y el relieve). Cinco patrones; caché por colores y patrón, así un
## estadio entero cuesta como mucho 5 texturas. Las letras son trazos sin texto legible (no hay que traducir
## nada ni inventar lemas en 9 idiomas).

const ANCHO := 256
const ALTO := 96
const PATRONES := 5

static var _cache := {}

## Material de un trapo. `girado` = el plano del telón tiene el largo sobre su eje Z (tribunas laterales).
static func material(c1: Color, c2: Color, patron: int, girado: bool) -> StandardMaterial3D:
	var p := posmod(patron, PATRONES)
	var clave := "%s|%s|%d|%s" % [c1.to_html(false), c2.to_html(false), p, girado]
	if _cache.has(clave):
		return _cache[clave]
	var m: StandardMaterial3D = Texturas.tela(Color.WHITE).duplicate()
	m.albedo_color = Color(0.92, 0.92, 0.92)   ## tela vieja: nunca blanco puro bajo los focos
	m.albedo_texture = ImageTexture.create_from_image(_imagen(c1, c2, p, girado))
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_cache[clave] = m
	return m

static func _imagen(c1: Color, c2: Color, p: int, girado: bool) -> Image:
	var nat := Nativo.obj()
	if nat != null and nat.has_method("telon_imagen"):   ## (19-11) el trapo entero (patrón, desgaste y giro), en C++ (`nativo/src/texturas_nativo.cpp`); gemela: `_imagen_gd`
		var im: Image = nat.telon_imagen(c1, c2, p, girado)
		im.generate_mipmaps()
		return im
	return _imagen_gd(c1, c2, p, girado)

static func _imagen_gd(c1: Color, c2: Color, p: int, girado: bool) -> Image:
	var img := Image.create(ANCHO, ALTO, false, Image.FORMAT_RGB8)
	## Contraste mínimo: si los dos colores del club se parecen (azul y azul marino), el segundo pasa a claro.
	## Y si el del club ya es claro (blanco, celeste pálido), el dibujo va en negro sobre él.
	var claro: Color = c2
	if absf(c2.get_luminance() - c1.get_luminance()) <= 0.25:
		if c1.get_luminance() > 0.5:
			claro = c1
			c1 = Color(0.07, 0.07, 0.08)
		else:
			claro = c1.lightened(0.75)
	match p:
		0: _rayas(img, c1, claro, true)
		1: _bandas(img, c1, claro)
		2: _diagonal(img, c1, claro)
		3: _cuadros(img, c1, claro)
		_: _letras(img, c1, claro)
	_desgaste(img)
	if girado:
		img = _transponer(img)
	img.generate_mipmaps()
	return img

static func _rayas(img: Image, a: Color, b: Color, verticales: bool) -> void:
	for x in ANCHO:
		for y in ALTO:
			var t := x if verticales else y
			img.set_pixel(x, y, a if (t / 24) % 2 == 0 else b)

static func _bandas(img: Image, a: Color, b: Color) -> void:
	## Tres bandas horizontales (claro, club, claro): la de siempre en la reja de la popular.
	for y in ALTO:
		var c := a if y >= ALTO / 3 and y < 2 * ALTO / 3 else b
		for x in ANCHO:
			img.set_pixel(x, y, c)

static func _diagonal(img: Image, a: Color, b: Color) -> void:
	## Fondo claro con la banda cruzada del club (como la camiseta de tantos clubes sudamericanos).
	for x in ANCHO:
		for y in ALTO:
			var d := float(x) - float(y) * (float(ANCHO) / float(ALTO)) * 0.6
			img.set_pixel(x, y, a if absf(d - 60.0) < 34.0 else b)

static func _cuadros(img: Image, a: Color, b: Color) -> void:
	for x in ANCHO:
		for y in ALTO:
			img.set_pixel(x, y, a if ((x / 32) + (y / 32)) % 2 == 0 else b)

static func _letras(img: Image, a: Color, b: Color) -> void:
	## Fondo claro, una franja del club arriba y abajo y en medio «letras» gruesas a brocha (trazos sin texto).
	img.fill(b)
	img.fill_rect(Rect2i(0, 0, ANCHO, 12), a)
	img.fill_rect(Rect2i(0, ALTO - 12, ANCHO, 12), a)
	var rng := RandomNumberGenerator.new()
	rng.seed = a.to_rgba32() ^ 0x5bd1
	var x := 14
	while x < ANCHO - 26:
		var w := rng.randi_range(14, 22)
		var y0 := 24
		var h := ALTO - 48
		img.fill_rect(Rect2i(x, y0, 5, h), a)                           ## palo de la letra
		match rng.randi_range(0, 3):
			0: img.fill_rect(Rect2i(x, y0, w, 5), a); img.fill_rect(Rect2i(x, y0 + h / 2, w - 4, 5), a)
			1: img.fill_rect(Rect2i(x + w - 5, y0, 5, h), a); img.fill_rect(Rect2i(x, y0 + h / 2, w, 5), a)
			2: img.fill_rect(Rect2i(x, y0, w, 5), a); img.fill_rect(Rect2i(x, y0 + h - 5, w, 5), a)
			_: img.fill_rect(Rect2i(x, y0 + h - 5, w, 5), a)
		x += w + rng.randi_range(6, 10)
		if rng.randf() < 0.2:
			x += 12   ## espacio entre palabras

## Manchas de pintura y suciedad: ±6 % de brillo en manchas de 8 px, para que no parezca impreso.
static func _desgaste(img: Image) -> void:
	for bx in range(0, ANCHO, 8):
		for by in range(0, ALTO, 8):
			var f := 1.0 + 0.06 * (fposmod(sin(float(bx) * 12.99 + float(by) * 78.23) * 43758.55, 2.0) - 1.0)
			for x in range(bx, mini(bx + 8, ANCHO)):
				for y in range(by, mini(by + 8, ALTO)):
					var c := img.get_pixel(x, y)
					img.set_pixel(x, y, Color(c.r * f, c.g * f, c.b * f))

static func _transponer(img: Image) -> Image:
	var t := Image.create(ALTO, ANCHO, false, Image.FORMAT_RGB8)
	for x in ANCHO:
		for y in ALTO:
			t.set_pixel(y, x, img.get_pixel(x, y))
	return t
