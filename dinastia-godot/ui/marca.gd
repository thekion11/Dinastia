class_name Marca
extends RefCounted
## EL LOGO DE UN PATROCINADOR. Hasta hoy "MARCAS" en `tablas.json` era, letra
## por letra, `[nombre, color]` -dos campos, sin ningún arte-, y en toda la
## interfaz una marca se mostraba como una palabra pintada del color de la
## tabla. Se nota en la pantalla de finanzas y en cualquier sitio donde
## aparezca un sponsor: no hay nada que "se lea como marca" desde lejos, y la
## nueva sala de prensa necesita justo eso para el fondo tras el podio.
##
## MISMA TÉCNICA QUE `Escudo`, a propósito: forma + patrón salen del hash del
## NOMBRE de la marca -no de un id, las marcas no tienen uno-, así que
## "Cerveza Andin4" tiene siempre el mismo logo en cualquier club que la firme
## y en cualquier partida. Y las formas son DISTINTAS de las de `Escudo`
## -insignia, sello, cinta, hexágono- para que un sponsor nunca se confunda
## con un escudo de club cuando aparecen uno al lado del otro.
##
## LA MISMA TRAMPA DEL TEXTO: `Image.load_svg_from_string()` no dibuja
## `<text>`. Aquí no hace falta ninguna letra dentro del SVG -el logo es una
## marca abstracta, como la mayoría de los sponsors reales-; el nombre se
## sigue mostrando aparte, como ya hacía la pantalla de finanzas.

const FORMAS := ["insignia", "sello", "cinta", "hexagono"]
## Motivos deliberadamente más simples que los diez patrones de `Escudo`: un
## sponsor real rara vez lleva más de un elemento gráfico encima del color.
const PATRONES := ["solido", "anillo", "cuna", "diagonal", "rayos", "punto"]

const SILUETAS := {
	## Insignia redonda con una muesca inferior, como una medalla.
	"insignia": "M32 2a30 30 0 1 1 -0.1 0Z M20 54 L32 68 L44 54Z",
	"sello":    "M32 2 44 8 58 6 56 20 66 30 56 40 58 54 44 52 32 62 20 52 6 54 8 40 -2 30 8 20 6 6 20 8Z",
	"cinta":    "M6 6h52v40l-26 18-26-18Z",
	"hexagono": "M20 3h24l16 29-16 29H20L4 32Z",
}

static var _cache: Dictionary = {}

## djb2, igual que `Escudo._hash()`: mismo algoritmo en todo el proyecto para
## que cualquiera pueda reconocerlo sin sorpresas.
static func _hash(s: String) -> int:
	var h := 5381
	for i in s.length():
		h = ((h << 5) + h + s.unicode_at(i)) & 0x7FFFFFFF
	return h

static func forma_de(nombre: String) -> String:
	return FORMAS[_hash(nombre) % FORMAS.size()]

static func patron_de(nombre: String) -> String:
	return PATRONES[(_hash(nombre) >> 4) % PATRONES.size()]

static func silueta(forma: String) -> String:
	return String(SILUETAS.get(forma, SILUETAS["insignia"]))

## Las iniciales para poner ENCIMA del logo con una `Label` -mismo patrón que
## `Escudo.iniciales()`-. Hasta tres letras, una por palabra.
static func iniciales(nombre: String) -> String:
	var s := ""
	for palabra: String in nombre.split(" ", false):
		if palabra.is_empty():
			continue
		var ch := palabra[0]
		if ch.is_valid_int() or ch == ch.to_upper():
			s += ch.to_upper()
		if s.length() >= 3:
			break
	return s if not s.is_empty() else "?"

static func _patron_svg(p: String, oscuro: String) -> String:
	match p:
		"anillo":
			return '<circle cx="32" cy="32" r="17" fill="none" stroke="%s" stroke-width="7" opacity=".9"/>' % oscuro
		"cuna":
			return '<path d="M2 46 32 16 62 46 62 60 32 34 2 60Z" fill="%s" opacity=".85"/>' % oscuro
		"diagonal":
			return '<path d="M-4 40 L26 -4 L44 -4 L14 40 Z" fill="%s" opacity=".85"/>' % oscuro \
				+ '<path d="M20 68 L50 24 L68 24 L38 68 Z" fill="%s" opacity=".55"/>' % oscuro
		"rayos":
			var r := ""
			for i in 6:
				var a1 := float(i) * TAU / 6.0
				var a2 := (float(i) + 0.4) * TAU / 6.0
				r += '<path d="M32 32 L%.2f %.2f L%.2f %.2f Z" fill="%s" opacity=".5"/>' % [
					32.0 + 34.0 * cos(a1), 32.0 + 34.0 * sin(a1),
					32.0 + 34.0 * cos(a2), 32.0 + 34.0 * sin(a2), oscuro]
			return r
		"punto":
			return '<circle cx="32" cy="32" r="11" fill="%s" opacity=".92"/>' % oscuro
	return ""

## El SVG completo, cuadrado 64x64 -a diferencia del escudo (64x70, más alto
## que ancho), un logo de sponsor se lee mejor en un marco cuadrado, que es
## como se usan casi todos en la interfaz-.
static func svg_de(nombre: String, color_hex: String) -> String:
	var f := forma_de(nombre)
	var p := patron_de(nombre)
	var d := silueta(f)
	var base := Color(color_hex)
	var oscuro := base.darkened(0.45).to_html(false)
	return """<svg width="64" height="64" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
<defs>
<clipPath id="cl"><path d="%s"/></clipPath>
<linearGradient id="br" x1="0" y1="0" x2="0.3" y2="1">
<stop offset="0" stop-color="#ffffff" stop-opacity=".3"/>
<stop offset=".5" stop-color="#ffffff" stop-opacity=".03"/>
<stop offset="1" stop-color="#000000" stop-opacity=".3"/></linearGradient>
</defs>
<path d="%s" fill="#%s"/>
<g clip-path="url(#cl)">%s</g>
<path d="%s" fill="url(#br)"/>
<path d="%s" fill="none" stroke="#00000055" stroke-width="1.4"/>
</svg>""" % [d, d, base.to_html(false), _patron_svg(p, oscuro), d, d]

## El logo ya rasterizado, listo para un `TextureRect` o como textura base de
## un material 3D. Igual que `Escudo.textura()`: 4x y se encoge, para que las
## curvas no salgan dentadas.
static func textura(nombre: String, color_hex: String, alto_px: int = 48) -> Texture2D:
	var clave := "%s_%s_%d" % [nombre, color_hex, alto_px]
	if _cache.has(clave):
		return _cache[clave]
	var img := Image.new()
	if img.load_svg_from_string(svg_de(nombre, color_hex), float(alto_px) * 4.0 / 64.0) != OK:
		return null
	var t := ImageTexture.create_from_image(img)
	_cache[clave] = t
	return t

static func limpiar_cache() -> void:
	_cache.clear()
