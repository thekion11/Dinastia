class_name TarjetaModo
extends RefCounted
## La "carátula" de cada tarjeta del menú de modos, portada de
## `dibujarPortadaModo()` del HTML (v3.0 · MENÚ DE MODOS).
##
## El HTML la dibuja en un <canvas> con degradado diagonal + tres líneas +
## un círculo. Igual que `Escudo`/`Cara`, aquí se construye como SVG y se
## rasteriza con `Image.load_svg_from_string()` en vez de reimplementar el
## trazado a mano con `_draw()`: es la misma foto, más barato de mantener.

static var _cache: Dictionary = {}

static func _svg(c1: String, c2: String, w: int, h: int) -> String:
	var fw := float(w)
	var fh := float(h)
	## Mismas proporciones que el canvas del HTML: tres líneas casi horizontales
	## alrededor de 0.32·alto, y un círculo a la derecha en (0.8·ancho, 0.32·alto)
	## con radio 0.22·alto.
	var lineas := ""
	for i in 3:
		var y := fh * 0.32 + float(i) * 10.0
		lineas += '<line x1="0" y1="%.1f" x2="%.1f" y2="%.1f"/>' % [y, fw, y - 8.0]
	## La tarjeta del HTML es UNA sola pieza redondeada -imagen y texto bajo el
	## mismo `border-radius`-, pero aquí la carátula es una textura aparte por
	## encima de un `PanelContainer` con las esquinas redondeadas: sin recortar
	## la textura, sus esquinas de arriba salían cuadradas y se notaba la
	## costura contra el panel redondeado de debajo. Se recorta con un
	## `clipPath` a las mismas esquinas superiores -proporcional al ancho, para
	## que no se note el radio si la tarjeta se estira a otro tamaño-.
	var r := minf(fw, fh) * 0.09
	var recorte := "M%.1f,0 H%.1f A%.1f,%.1f 0 0 1 %.1f,%.1f V%.1f H0 V%.1f A%.1f,%.1f 0 0 1 %.1f,0 Z" % [
		r, fw - r, r, r, fw, r, fh, r, r, r, r]
	return """<svg width="%d" height="%d" viewBox="0 0 %d %d" xmlns="http://www.w3.org/2000/svg">
<defs>
<linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
<stop offset="0" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient>
<clipPath id="c"><path d="%s"/></clipPath>
</defs>
<g clip-path="url(#c)">
<rect width="%d" height="%d" fill="url(#g)"/>
<g stroke="#ffffff" stroke-opacity="0.22" stroke-width="2" fill="none">%s</g>
<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#ffffff" fill-opacity="0.16"/>
</g>
</svg>""" % [w, h, w, h, c1, c2, recorte, w, h, lineas, fw * 0.8, fh * 0.32, fh * 0.22]

## Se rasteriza a 2x para que quede nítida al estirarse en la tarjeta.
static func textura(c1: String, c2: String, ancho: int = 280, alto: int = 100) -> Texture2D:
	var clave := "%s_%s_%d_%d" % [c1, c2, ancho, alto]
	if _cache.has(clave):
		return _cache[clave]
	var img := Image.new()
	if img.load_svg_from_string(_svg(c1, c2, ancho, alto), 2.0) != OK:
		return null
	var t := ImageTexture.create_from_image(img)
	_cache[clave] = t
	return t
