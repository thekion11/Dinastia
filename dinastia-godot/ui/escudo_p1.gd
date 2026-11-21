extends "res://ui/escudo_p1_p1.gd"
## (Parte 2 de 2 de `escudo_p1.gd`.)

## El patrón que va recortado dentro de la silueta. Son los diez del HTML, con
## sus mismas coordenadas y opacidades.
static func _patron_svg(p: String, c2: String, c3: String = "") -> String:
	var r_patron_svg_1: Variant = _patron_svg_1(p, c2, c3)
	if r_patron_svg_1 != null:
		return r_patron_svg_1
	var r_patron_svg_2: Variant = _patron_svg_2(c2, p)
	if r_patron_svg_2 != null:
		return r_patron_svg_2
	var r_patron_svg_3: Variant = _patron_svg_3(c2, p)
	if r_patron_svg_3 != null:
		return r_patron_svg_3
	var r_patron_svg_4: Variant = _patron_svg_4(c2, p)
	if r_patron_svg_4 != null:
		return r_patron_svg_4
	var r_patron_svg_5: Variant = _patron_svg_5(c2, p)
	if r_patron_svg_5 != null:
		return r_patron_svg_5
	return ""


static func _patron_svg_4(c2: String, p: String) -> Variant:
	match p:
		"barras":
			return '<rect x="-4" y="14" width="72" height="12" fill="%s" opacity=".9"/>' % c2 \
				+ '<rect x="-4" y="44" width="72" height="12" fill="%s" opacity=".9"/>' % c2
		## Marco grueso pegado al borde -"bordure" heraldico-.
		"borde":
			return '<rect x="2" y="2" width="60" height="8" fill="%s" opacity=".85"/>' % c2 \
				+ '<rect x="2" y="60" width="60" height="8" fill="%s" opacity=".85"/>' % c2 \
				+ '<rect x="2" y="2" width="8" height="66" fill="%s" opacity=".85"/>' % c2 \
				+ '<rect x="54" y="2" width="8" height="66" fill="%s" opacity=".85"/>' % c2
		## Escalera diagonal de cuadrados superpuestos.
		"escalera":
			var sc := ""
			for i in 6:
				sc += '<rect x="%d" y="%d" width="12" height="12" fill="%s" opacity=".85"/>' % [i * 10 - 4, i * 10, c2]
			return sc
		## Pila heraldica: triangulo ancho que cae desde el borde superior.
		"pila":
			return '<path d="M6 -4 L58 -4 L32 55 Z" fill="%s" opacity=".9"/>' % c2
		## Estrella de 8 puntas -16 vertices alternando radio 30/13, centro
		## (32,34)-, calculada a mano con trigonometria, sin pasar por Figma.
		"estrella8":
			return '<path d="M32 4 L37 22 L53 13 L44 29 L62 34 L44 39 L53 55 L37 46 L32 64 L27 46 L11 55 L20 39 L2 34 L20 29 L11 13 L27 22 Z" fill="%s" opacity=".9"/>' % c2
		## Manchas irregulares -posiciones y radios fijos, no aleatorios, para
		## que el mismo club siempre salga igual-.
		"manchas":
			var ma := ""
			for bl in [[14, 14, 10], [46, 20, 7], [30, 45, 12], [10, 55, 6], [52, 52, 8]]:
				ma += '<circle cx="%d" cy="%d" r="%d" fill="%s" opacity=".8"/>' % [bl[0], bl[1], bl[2], c2]
			return ma
		## Flor de lis estilizada: ovalo central + dos circulos laterales + banda -sin
		## rotacion, para no depender de soporte de "transform" en el rasterizador SVG-.
		"florlis":
			return '<path d="M32 6 A7 20 0 1 1 32 46 A7 20 0 1 1 32 6 Z" fill="%s" opacity=".88"/>' % c2 \
				+ '<circle cx="18" cy="32" r="9" fill="%s" opacity=".8"/>' % c2 \
				+ '<circle cx="46" cy="32" r="9" fill="%s" opacity=".8"/>' % c2 \
				+ '<rect x="22" y="48" width="20" height="10" fill="%s" opacity=".85"/>' % c2
		## Trebol de 4 hojas: 4 circulos sueltos, no fusionados -un patron
		## recortado no necesita ser un solo path, ver nota de arriba-.
		"trebol":
			var tr := ""
			for pt in [Vector2(32, 24), Vector2(43, 35), Vector2(32, 46), Vector2(21, 35)]:
				tr += '<circle cx="%d" cy="%d" r="11" fill="%s" opacity=".82"/>' % [pt.x, pt.y, c2]
			return tr
		## Media luna: el truco clasico de dos arcos SVG (uno grande, uno mas
		## angosto y desplazado) en vez de una resta booleana.
	return null

static func _patron_svg_5(c2: String, p: String) -> Variant:
	match p:
		"medialuna":
			return '<path d="M32 4 A30 30 0 1 0 32 64 A22 26 0 1 1 32 4 Z" fill="%s" opacity=".9"/>' % c2
	return null


## El BORDE de un escudo de verdad (14-10-2026): un aro del color que contrasta con
## el campo -el secundario, o blanco/oscuro si los dos colores se parecen-, y por
## fuera una línea de sombra que lo separa del fondo.
static func _borde_de(c: Club) -> String:
	var a := Color(c.color_escudo1())
	var b := Color(c.color_escudo2())
	if absf(a.get_luminance() - b.get_luminance()) > 0.25:
		return c.color_escudo2()
	return "#f4f1e6" if a.get_luminance() < 0.55 else "#1a1d22"

## El SVG completo del escudo, sin texto.
static func svg_de(c: Club) -> String:
	var f := forma_de(c)
	var p := patron_de(c)
	var d := silueta(f)
	## El brillo diagonal es lo que hace que un escudo parezca metal y no una
	## pegatina plana. Son cuatro paradas de un degradado, y cambian mucho.
	return """<svg width="64" height="70" viewBox="0 0 64 70" xmlns="http://www.w3.org/2000/svg">
<defs>
<clipPath id="cl"><path d="%s"/></clipPath>
<linearGradient id="br" x1="0" y1="0" x2="0.3" y2="1">
<stop offset="0" stop-color="#ffffff" stop-opacity=".32"/>
<stop offset=".42" stop-color="#ffffff" stop-opacity=".04"/>
<stop offset=".58" stop-color="#000000" stop-opacity=".06"/>
<stop offset="1" stop-color="#000000" stop-opacity=".34"/></linearGradient>
</defs>
<path d="%s" fill="%s"/>
<g clip-path="url(#cl)">%s<path d="%s" fill="none" stroke="%s" stroke-width="5.5"/><path d="%s" fill="none" stroke="#000" stroke-opacity=".28" stroke-width="7.5"/></g>
%s
<path d="%s" fill="url(#br)"/>
<path d="%s" fill="none" stroke="#00000055" stroke-width="1.4"/>
<path d="%s" transform="translate(32 35) scale(.86) translate(-32 -35)" fill="none" stroke="#ffffff" stroke-opacity=".55" stroke-width="1.1"/>
</svg>""" % [d, d, c.color_escudo1(), _patron_svg(p, c.color_escudo2(), AspectoClub.esc(c, 2, "")), d, _borde_de(c), d, load("res://ui/escudo_emblemas.gd").capa_de(c, c.color_escudo1()), d, d, d]
