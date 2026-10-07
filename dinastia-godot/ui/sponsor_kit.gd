class_name SponsorKit
extends RefCounted
## LOS PATROCINADORES EN LA CAMISETA (26-9-2026). Pedido: *"falta poner los
## sponsors basado en los patrocinadores"*.
##
## De dónde sale cada marca:
##   - TU club: lo que firmaste. El pecho es el contrato de `Auspicio`; manga,
##     espalda y pantalón son las zonas de `Comercial.zonas_firmadas`. Sin
##     contrato, la zona va limpia (como un club de verdad sin sponsor).
##   - Los otros clubes: una marca de `MARCAS` elegida por el hash del club, así
##     que cada rival tiene siempre la misma camiseta. Los grandes casi siempre
##     llevan pecho y manga; los chicos a veces van sin nada.
##
## Cómo se dibuja: el rasterizador SVG de Godot no pinta texto, así que la
## palabra se escribe con una tipografía de bloques propia (5 × 7, en negrita
## redondeada y suavizada) al lado del logo de `Marca`. La MISMA imagen va a la
## vista 2D (se estampa sobre el pecho) y al shader 3D (`sponsor_tex`).

## Tipografía de bloques: 7 filas de 5 columnas por letra.
const FUENTE := {
	"A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"B": ["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."],
	"C": [".####", "#....", "#....", "#....", "#....", "#....", ".####"],
	"D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
	"E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
	"F": ["#####", "#....", "#....", "####.", "#....", "#....", "#...."],
	"G": [".####", "#....", "#....", "#.###", "#...#", "#...#", ".###."],
	"H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"I": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "#####"],
	"J": ["..###", "...#.", "...#.", "...#.", "...#.", "#..#.", ".##.."],
	"K": ["#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"],
	"L": ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
	"M": ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
	"N": ["#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#"],
	"O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"P": ["####.", "#...#", "#...#", "####.", "#....", "#....", "#...."],
	"Q": [".###.", "#...#", "#...#", "#...#", "#.#.#", "#..#.", ".##.#"],
	"R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
	"S": [".####", "#....", "#....", ".###.", "....#", "....#", "####."],
	"T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
	"U": ["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"V": ["#...#", "#...#", "#...#", "#...#", "#...#", ".#.#.", "..#.."],
	"W": ["#...#", "#...#", "#...#", "#.#.#", "#.#.#", "##.##", "#...#"],
	"X": ["#...#", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#...#"],
	"Y": ["#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."],
	"Z": ["#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"],
	"0": [".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###."],
	"1": ["..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."],
	"2": [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"],
	"3": ["####.", "....#", "....#", ".###.", "....#", "....#", "####."],
	"4": ["#...#", "#...#", "#...#", "#####", "....#", "....#", "....#"],
	"5": ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."],
	"6": [".###.", "#....", "#....", "####.", "#...#", "#...#", ".###."],
	"7": ["#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..."],
	"8": [".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."],
	"9": [".###.", "#...#", "#...#", ".####", "....#", "....#", ".###."],
	"&": [".##..", "#..#.", ".##..", ".##.#", "#..#.", "#..#.", ".##.#"],
	".": [".....", ".....", ".....", ".....", ".....", ".##..", ".##.."],
	"-": [".....", ".....", ".....", "#####", ".....", ".....", "....."],
	"'": ["..#..", "..#..", ".....", ".....", ".....", ".....", "....."],
}
const SIN_TILDE := {"Á": "A", "É": "E", "Í": "I", "Ó": "O", "Ú": "U", "Ü": "U", "Ñ": "N", "À": "A", "È": "E", "Ç": "C", "Ã": "A", "Õ": "O", "Â": "A", "Ê": "E", "Ô": "O"}

const ALTO := 128

static var _cache: Dictionary = {}

## La palabra de la marca: sin tildes y en mayúsculas.
static func normalizar(nombre: String) -> String:
	var s := Nombres.limpiar(nombre).to_upper()
	var r := ""
	for ch in s:
		r += String(SIN_TILDE.get(ch, ch))
	return r

## Los patrocinadores de un club: {zona: {marca, color}} con zona en pecho,
## manga, espalda y short. `mundo` puede ser null (entonces todos por hash).
static func de_club(c: Club, mundo: Mundo = null) -> Dictionary:
	var r := {}
	if c == null:
		return r
	if mundo != null and c.id == mundo.mi_club_id:
		if mundo.auspicio != null and not mundo.auspicio.contrato.is_empty():
			r["pecho"] = {"marca": Nombres.limpiar(String(mundo.auspicio.contrato.get("marca", ""))),
				"color": String(mundo.auspicio.contrato.get("color", "#e8b13a"))}
		if mundo.comercial != null:
			for z: String in ["manga", "espalda", "short"]:
				if mundo.comercial.zonas_firmadas.has(z):
					var f: Dictionary = mundo.comercial.zonas_firmadas[z]
					r[z] = {"marca": Nombres.limpiar(String(f.get("marca", ""))), "color": String(f.get("color", "#e8b13a"))}
		return r
	var marcas := Auspicio.marcas()
	if marcas.is_empty():
		return r
	var h := Marca._hash(c.id + "|sp")
	## Cuanto más grande el club, más zonas vendidas.
	var rep := clampf((float(c.rep) - 40.0) / 55.0, 0.0, 1.0)
	var zonas := [["pecho", 0.55 + rep * 0.45], ["manga", 0.2 + rep * 0.6], ["espalda", rep * 0.5], ["short", rep * 0.35]]
	for i in zonas.size():
		var z: Array = zonas[i]
		## Nadie vende la manga sin haber vendido el pecho.
		if i > 0 and not r.has("pecho"):
			break
		if float((h >> (i * 5)) % 100) / 100.0 < float(z[1]):
			var m: Array = marcas[(h / (i + 3) + i * 7) % marcas.size()]
			r[String(z[0])] = {"marca": Nombres.limpiar(String(m[0])), "color": String(m[1]) if m.size() > 1 else "#e8b13a"}
	return r

## El color de las letras sobre la camiseta: el de la marca si contrasta con el
## fondo; si no, blanco o casi negro.
static func color_letras(marca_hex: String, fondo: Color) -> Color:
	var m := Color(marca_hex)
	if absf(m.get_luminance() - fondo.get_luminance()) > 0.35:
		return m
	return Color("0f1412") if fondo.get_luminance() > 0.55 else Color.WHITE

## La imagen del sponsor (logo + palabra) sobre fondo transparente, del tamaño
## justo de lo que lleva: quien la estampa la encaja en su zona sin
## deformarla. Los nombres largos van en dos líneas (como los sponsors de
## verdad, que se leen desde la grada). `solo_logo` para la manga y el
## pantalón, donde no cabe la palabra.
static func imagen(marca: String, marca_hex: String, letras: Color, solo_logo: bool = false) -> Image:
	var k := "%s|%s|%s|%s" % [marca, marca_hex, letras.to_html(false), solo_logo]
	if _cache.has(k):
		return _cache[k]
	var logo_tex := Marca.textura(marca, marca_hex, 96)
	var img: Image
	if solo_logo:
		img = Image.create(ALTO, ALTO, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		if logo_tex != null:
			var li0 := logo_tex.get_image()
			li0.convert(Image.FORMAT_RGBA8)
			li0.resize(ALTO - 8, ALTO - 8, Image.INTERPOLATE_LANCZOS)
			img.blend_rect(li0, Rect2i(0, 0, li0.get_width(), li0.get_height()), Vector2i(4, 4))
		_cache[k] = img
		return img
	var lineas := lineas_de(normalizar(marca))
	var c := CELDA
	var bloque_w := 0
	for l: String in lineas:
		bloque_w = maxi(bloque_w, columnas(l) * c)
	var bloque_h := lineas.size() * 7 * c + (lineas.size() - 1) * 2 * c
	var lado := maxi(7 * c, bloque_h) if logo_tex != null else 0
	var w := lado + (c * 2 if logo_tex != null else 0) + bloque_w + 8
	var h := maxi(lado, bloque_h) + 8
	img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	if logo_tex != null:
		var li := logo_tex.get_image()
		li.convert(Image.FORMAT_RGBA8)
		li.resize(lado, lado, Image.INTERPOLATE_LANCZOS)
		img.blend_rect(li, Rect2i(0, 0, lado, lado), Vector2i(4, (h - lado) / 2))
	var x0 := 4 + lado + (c * 2 if logo_tex != null else 0)
	var y := float(h - bloque_h) * 0.5
	for l: String in lineas:
		## Cada línea centrada en el bloque.
		var x := float(x0 + (bloque_w - columnas(l) * c) / 2)
		for ch in l:
			if ch == " ":
				x += float(c) * 3.0
				continue
			if not FUENTE.has(ch):
				continue
			var g: Array = FUENTE[ch]
			for fy in 7:
				var fila := String(g[fy])
				for fx in 5:
					if fila[fx] == "#":
						_punto(img, x + float(fx * c), y + float(fy * c), float(c), letras)
			x += float(c) * 6.0
		y += float(c) * 9.0
	_cache[k] = img
	return img

## Tamaño de la celda de la tipografía en la imagen (px).
const CELDA := 12

## Una o dos líneas: se parte en el espacio más cercano a la mitad cuando el
## nombre pasa de 8 letras.
static func lineas_de(palabra: String) -> Array:
	var limpia := ""
	for ch in palabra:
		if ch == " " or FUENTE.has(ch):
			limpia += ch
	limpia = limpia.strip_edges()
	if limpia.length() <= 8 or not limpia.contains(" "):
		return [limpia]
	var mitad := limpia.length() / 2
	var mejor := -1
	for i in limpia.length():
		if limpia[i] == " " and (mejor < 0 or absi(i - mitad) < absi(mejor - mitad)):
			mejor = i
	return [limpia.substr(0, mejor).strip_edges(), limpia.substr(mejor + 1).strip_edges()]

## Columnas de la tipografía que ocupa una línea.
static func columnas(l: String) -> int:
	var n := 0
	for ch in l:
		n += 3 if ch == " " else (6 if FUENTE.has(ch) else 0)
	return maxi(n - 1, 1)

## Proporción ancho/alto de la imagen (para encajarla sin deformar).
static func aspecto(marca: String, marca_hex: String, letras: Color, solo_logo: bool = false) -> float:
	var img := imagen(marca, marca_hex, letras, solo_logo)
	return float(img.get_width()) / float(maxi(img.get_height(), 1))

## Un píxel de la tipografía: un cuadrado de esquinas redondeadas, un poco más
## grande que la celda para que las letras salgan macizas y sin rendijas.
static func _punto(img: Image, x: float, y: float, s: float, col: Color) -> void:
	## Un 18 % más grande que la celda: las letras salen macizas y en negrita,
	## sin las rendijas de plantilla que se veían de lejos.
	var g := s * 0.09
	var x0 := x - g
	var y0 := y - g
	var t := s + g * 2.0
	var r := t * 0.22
	for py in range(maxi(int(floorf(y0)), 0), mini(int(ceilf(y0 + t)) + 1, img.get_height())):
		for px in range(maxi(int(floorf(x0)), 0), mini(int(ceilf(x0 + t)) + 1, img.get_width())):
			var cx := clampf(float(px) + 0.5, x0 + r, x0 + t - r)
			var cy := clampf(float(py) + 0.5, y0 + r, y0 + t - r)
			var d := Vector2(float(px) + 0.5 - cx, float(py) + 0.5 - cy).length()
			var a := clampf(r + 0.5 - d, 0.0, 1.0)
			if a > 0.0:
				var prev := img.get_pixel(px, py)
				img.set_pixel(px, py, Color(col.r, col.g, col.b, maxf(prev.a, a)))

## Textura lista para el shader (con mipmaps, para que se lea de lejos).
static func textura(marca: String, marca_hex: String, letras: Color, solo_logo: bool = false) -> Texture2D:
	var img := imagen(marca, marca_hex, letras, solo_logo).duplicate() as Image
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
