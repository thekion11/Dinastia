class_name EscudoEmblemas
extends RefCounted
## LO QUE IDENTIFICA A CADA ESCUDO (orden 15, 27-10-2026, pedido del dueño: «que se parezcan más a los reales»): una FIGURA sencilla (cañón, ave, corona,
## media luna, torre, estrella, cacique…) y/o unas LETRAS («U», «OM», «CABJ»), dibujadas en vectores sobre el escudo. El SVG que rasteriza Godot no admite
## texto, así que las letras salen de una tipografía de trazos propia (rectas y arcos sencillos). Ninguna figura copia un logo: son siluetas genéricas.
## Cada figura vive en una caja de 40×40 y se pinta con `{F}` (relleno o trazo) y `{D}` (detalle, el otro color).
static var activo := true   ## las pruebas y las capturas lo apagan para ver el «antes»

const FIGURAS := {
	"canon": '<path d="M3 21 L28 10 L32 17 L7 29 Z" fill="{F}"/><circle cx="13" cy="29" r="7" fill="{F}"/><circle cx="13" cy="29" r="2.4" fill="{D}"/><circle cx="31" cy="13" r="4" fill="{F}"/>',
	"ave": '<circle cx="14" cy="11" r="5" fill="{F}"/><path d="M10 10 L2 12 L10 14 Z" fill="{F}"/><path d="M16 14 C26 14 31 20 33 28 L39 25 L37 34 L28 36 C20 36 15 31 14 23 C13 19 12 17 13 14 Z" fill="{F}"/><path d="M19 22 C23 22 27 26 27 31 C22 31 19 28 19 22 Z" fill="{D}"/><path d="M22 36 V39 M27 36 V39" stroke="{F}" stroke-width="2.2"/><circle cx="14" cy="10" r="1.3" fill="{D}"/>',
	"aguila": '<path d="M20 13 C17 6 8 3 1 7 C3 11 3 14 5 18 C6 15 8 14 11 15 C10 18 12 20 14 21 C14 24 16 26 18 26 L16 37 L20 34 L24 37 L22 26 C24 26 26 24 26 21 C28 20 30 18 29 15 C32 14 34 15 35 18 C37 14 37 11 39 7 C32 3 23 6 20 13 Z" fill="{F}"/><path d="M20 15 L17 10 L20 4 L23 10 Z" fill="{F}"/><path d="M20 4 L24 7 L20 8 Z" fill="{D}"/>',
	"corona": '<path d="M4 30 L4 13 L12 21 L20 7 L28 21 L36 13 L36 30 Z" fill="{F}"/><rect x="4" y="31" width="32" height="5" fill="{F}"/><circle cx="20" cy="22" r="2.5" fill="{D}"/>',
	"media_luna": '<path d="M27 3 A17 17 0 1 0 27 37 A12.5 15 0 1 1 27 3 Z" fill="{F}"/><path d="M31 13 L32.6 17.4 L37 17.5 L33.6 20.3 L34.8 24.6 L31 22 L27.2 24.6 L28.4 20.3 L25 17.5 L29.4 17.4 Z" fill="{F}"/>',
	"torre": '<path d="M8 37 L8 11 L12.5 11 L12.5 6 L17 6 L17 11 L23 11 L23 6 L27.5 6 L27.5 11 L32 11 L32 37 Z" fill="{F}"/><path d="M16 37 L16 28 A4 4 0 0 1 24 28 L24 37 Z" fill="{D}"/>',
	"estrella": '<path d="M20 2 L25 14.5 L38.5 15.4 L28.2 24 L31.5 37 L20 29.8 L8.5 37 L11.8 24 L1.5 15.4 L15 14.5 Z" fill="{F}"/>',
	"estrellas3": '<path d="M20 4 L22.6 10.6 L29.6 11 L24.2 15.5 L26 22.4 L20 18.6 L14 22.4 L15.8 15.5 L10.4 11 L17.4 10.6 Z" fill="{F}"/><path d="M8 20 L10.6 26.6 L17.6 27 L12.2 31.5 L14 38.4 L8 34.6 L2 38.4 L3.8 31.5 L-1.6 27 L5.4 26.6 Z" fill="{F}"/><path d="M32 20 L34.6 26.6 L41.6 27 L36.2 31.5 L38 38.4 L32 34.6 L26 38.4 L27.8 31.5 L22.4 27 L29.4 26.6 Z" fill="{F}"/>',
	"cacique": '<g fill="{F}"><ellipse cx="20" cy="9" rx="3.2" ry="9" transform="rotate(0 20 24)"/><ellipse cx="20" cy="9" rx="3.2" ry="9" transform="rotate(-32 20 24)"/><ellipse cx="20" cy="9" rx="3.2" ry="9" transform="rotate(32 20 24)"/><ellipse cx="20" cy="9" rx="3.2" ry="9" transform="rotate(-62 20 24)"/><ellipse cx="20" cy="9" rx="3.2" ry="9" transform="rotate(62 20 24)"/><circle cx="20" cy="25" r="11.5"/></g><path d="M8.5 22 H31.5" stroke="{D}" stroke-width="3.6"/><circle cx="15.5" cy="27" r="1.5" fill="{D}"/><circle cx="24.5" cy="27" r="1.5" fill="{D}"/><path d="M16 32 Q20 35 24 32" stroke="{D}" stroke-width="1.8" fill="none"/>',
	"oso": '<circle cx="9" cy="9" r="5.5" fill="{F}"/><circle cx="31" cy="9" r="5.5" fill="{F}"/><circle cx="20" cy="22" r="14" fill="{F}"/><ellipse cx="20" cy="27" rx="6.5" ry="5" fill="{D}"/><circle cx="14" cy="18" r="1.8" fill="{D}"/><circle cx="26" cy="18" r="1.8" fill="{D}"/><circle cx="20" cy="25" r="2" fill="{F}"/>',
	"ancla": '<path d="M18 3 H22 V9 H27 V13 H22 V30 C28 29 31 25 32 21 L28.5 22 L34 15.5 L38 23 L34.5 22.5 C32.5 31 27 37 20 37 C13 37 7.5 31 5.5 22.5 L2 23 L6 15.5 L11.5 22 L8 21 C9 25 12 29 18 30 V13 H13 V9 H18 Z" fill="{F}"/>',
	"balon": '<circle cx="20" cy="20" r="17" fill="{F}"/><path d="M20 11 L28 17 L25 26 L15 26 L12 17 Z" fill="{D}"/><path d="M20 11 V3 M28 17 L36 14 M25 26 L31 33 M15 26 L9 33 M12 17 L4 14" stroke="{D}" stroke-width="2.2"/>',
	"rayo": '<path d="M25 1 L7 22 L17.5 22 L13 39 L33 15 L22 15 Z" fill="{F}"/>',
	"flor_lis": '<path d="M20 3 C27 9 27 20 20 27 C13 20 13 9 20 3 Z" fill="{F}"/><path d="M19 22 C12 12 4 14 4 22 C4 28 11 29 17 26 Z M21 22 C28 12 36 14 36 22 C36 28 29 29 23 26 Z" fill="{F}"/><rect x="11" y="28" width="18" height="4" rx="1" fill="{F}"/><path d="M17 33 H23 L21 38 H19 Z" fill="{F}"/>',
	"cruz": '<path d="M16 2 H24 V16 H38 V24 H24 V38 H16 V24 H2 V16 H16 Z" fill="{F}"/>',
	"tridente": '<path d="M20 38 V8 M9 6 V17 Q9 25 20 25 Q31 25 31 17 V6 M20 2 V14" stroke="{F}" stroke-width="3.6" fill="none" stroke-linecap="round" stroke-linejoin="round"/>',
	"sol": '<circle cx="20" cy="20" r="9" fill="{F}"/><path d="M20 1 V8 M20 32 V39 M1 20 H8 M32 20 H39 M6.5 6.5 L11.5 11.5 M28.5 28.5 L33.5 33.5 M33.5 6.5 L28.5 11.5 M11.5 28.5 L6.5 33.5" stroke="{F}" stroke-width="3" stroke-linecap="round"/>',
	"montana": '<path d="M1 36 L14 11 L21 22 L27 14 L39 36 Z" fill="{F}"/><path d="M14 11 L18 18 L14 16.5 L10.5 18 Z" fill="{D}"/>',
	"cuernos": '<path d="M4 8 C4 22 10 30 20 30 C30 30 36 22 36 8 C32 18 28 22 20 22 C12 22 8 18 4 8 Z" fill="{F}"/><circle cx="20" cy="31" r="5" fill="{F}"/>',
	"lobo": '<path d="M6 6 L14 14 L26 14 L34 6 L35 22 L28 33 L22 37 L18 37 L12 33 L5 22 Z" fill="{F}"/><path d="M14 22 L18 25 M26 22 L22 25" stroke="{D}" stroke-width="2.4"/><path d="M18 31 L20 34 L22 31 Z" fill="{D}"/>',
	"leon": '<circle cx="20" cy="20" r="17" fill="{F}"/><circle cx="20" cy="21" r="10.5" fill="{D}"/><path d="M14 18 H17 M23 18 H26 M20 21 V26 M16.5 27.5 Q20 30 23.5 27.5" stroke="{F}" stroke-width="2" fill="none" stroke-linecap="round"/>',
	"banda_h": '<rect x="1" y="14" width="38" height="12" fill="{F}"/>',
	"mano": '<path d="M12 36 V18 L8 20 V12 H11 V6 H15 V12 H17 V3 H21 V12 H23 V5 H27 V14 H29 V9 H33 V26 Q33 36 24 36 Z" fill="{F}"/>',
}

## Trazos de las letras en una caja de 4 × 6 (x derecha, y abajo). Cada letra es una lista de líneas quebradas (o círculos con «o»).
const LETRAS := {
	"A": [[[0, 6], [2, 0], [4, 6]], [[0.8, 4], [3.2, 4]]],
	"B": [[[0, 0], [0, 6], [2.7, 6], [3.8, 5], [3.8, 3.9], [2.7, 3], [0, 3]], [[0, 0], [2.7, 0], [3.6, 0.9], [3.6, 2.1], [2.7, 3]]],
	"C": [[[4, 1], [3, 0], [1, 0], [0, 1], [0, 5], [1, 6], [3, 6], [4, 5]]],
	"D": [[[0, 0], [0, 6], [2.4, 6], [4, 4.6], [4, 1.4], [2.4, 0], [0, 0]]],
	"E": [[[4, 0], [0, 0], [0, 6], [4, 6]], [[0, 3], [3, 3]]],
	"F": [[[4, 0], [0, 0], [0, 6]], [[0, 3], [3, 3]]],
	"G": [[[4, 1], [3, 0], [1, 0], [0, 1], [0, 5], [1, 6], [3, 6], [4, 5], [4, 3.2], [2.2, 3.2]]],
	"H": [[[0, 0], [0, 6]], [[4, 0], [4, 6]], [[0, 3], [4, 3]]],
	"I": [[[0.5, 0], [3.5, 0]], [[2, 0], [2, 6]], [[0.5, 6], [3.5, 6]]],
	"J": [[[4, 0], [4, 4.8], [3, 6], [1, 6], [0, 5]]],
	"K": [[[0, 0], [0, 6]], [[4, 0], [0, 3.4]], [[1.4, 2.4], [4, 6]]],
	"L": [[[0, 0], [0, 6], [4, 6]]],
	"M": [[[0, 6], [0, 0], [2, 3.6], [4, 0], [4, 6]]],
	"N": [[[0, 6], [0, 0], [4, 6], [4, 0]]],
	"Ñ": [[[0, 6], [0, 1.4], [4, 6], [4, 1.4]], [[0.6, -0.9], [1.6, -1.5], [2.4, -0.5], [3.4, -1.1]]],
	"O": [[[1, 0], [3, 0], [4, 1], [4, 5], [3, 6], [1, 6], [0, 5], [0, 1], [1, 0]]],
	"P": [[[0, 6], [0, 0], [2.8, 0], [4, 1], [4, 2.6], [2.8, 3.6], [0, 3.6]]],
	"Q": [[[1, 0], [3, 0], [4, 1], [4, 5], [3, 6], [1, 6], [0, 5], [0, 1], [1, 0]], [[2.4, 4], [4.2, 6.4]]],
	"R": [[[0, 6], [0, 0], [2.8, 0], [4, 1], [4, 2.6], [2.8, 3.6], [0, 3.6]], [[2, 3.6], [4, 6]]],
	"S": [[[4, 1], [3, 0], [1, 0], [0, 1], [0, 2.2], [1, 3], [3, 3], [4, 3.8], [4, 5], [3, 6], [1, 6], [0, 5]]],
	"T": [[[0, 0], [4, 0]], [[2, 0], [2, 6]]],
	"U": [[[0, 0], [0, 5], [1, 6], [3, 6], [4, 5], [4, 0]]],
	"V": [[[0, 0], [2, 6], [4, 0]]],
	"W": [[[0, 0], [1, 6], [2, 2.4], [3, 6], [4, 0]]],
	"X": [[[0, 0], [4, 6]], [[4, 0], [0, 6]]],
	"Y": [[[0, 0], [2, 3], [4, 0]], [[2, 3], [2, 6]]],
	"Z": [[[0, 0], [4, 0], [0, 6], [4, 6]]],
	"0": [[[1, 0], [3, 0], [4, 1], [4, 5], [3, 6], [1, 6], [0, 5], [0, 1], [1, 0]], [[3.4, 0.8], [0.6, 5.2]]],
	"1": [[[0.8, 1.4], [2.4, 0], [2.4, 6]], [[0.8, 6], [4, 6]]],
	"2": [[[0, 1], [1, 0], [3, 0], [4, 1], [4, 2.4], [0, 6], [4, 6]]],
	"3": [[[0, 0.8], [1, 0], [3, 0], [4, 1], [4, 2.2], [3, 3], [1.4, 3]], [[3, 3], [4, 3.8], [4, 5], [3, 6], [1, 6], [0, 5.2]]],
	"4": [[[3, 6], [3, 0], [0, 4.2], [4.2, 4.2]]],
	"5": [[[4, 0], [0.4, 0], [0, 3], [2.4, 2.6], [4, 3.6], [4, 5], [3, 6], [1, 6], [0, 5]]],
	"6": [[[3.6, 0.6], [2.6, 0], [1, 0], [0, 1], [0, 5], [1, 6], [3, 6], [4, 5], [4, 3.8], [3, 3], [1, 3], [0, 3.8]]],
	"7": [[[0, 0], [4, 0], [1.6, 6]]],
	"8": [[[1, 0], [3, 0], [4, 1], [4, 2], [3, 3], [1, 3], [0, 2], [0, 1], [1, 0]], [[1, 3], [0, 4], [0, 5], [1, 6], [3, 6], [4, 5], [4, 4], [3, 3]]],
	"9": [[[0.4, 5.4], [1.4, 6], [3, 6], [4, 5], [4, 1], [3, 0], [1, 0], [0, 1], [0, 2.2], [1, 3], [3, 3], [4, 2.2]]],
	"-": [[[0.5, 3], [3.5, 3]]],
	".": [[[2, 6], [2, 6.01]]],
}

## Las letras de `texto` en el SVG del escudo, centradas en (cx, cy) y encajadas en `ancho` × `alto`. `color` es el relleno del trazo y `borde` el contorno.
static func letras_svg(texto: String, cx: float, cy: float, ancho: float, alto: float, color: String, borde: String) -> String:
	var t := texto.to_upper().strip_edges()
	var n := t.length()
	if n == 0:
		return ""
	var gap := 1.5
	var largo := float(n) * 4.0 + float(n - 1) * gap
	var s := minf(ancho / largo, alto / 6.0)
	var x0 := cx - largo * s * 0.5
	var y0 := cy - 3.0 * s
	var trazos := ""
	for i in n:
		var ch := t.substr(i, 1)
		if not LETRAS.has(ch):
			continue
		var ox := x0 + float(i) * (4.0 + gap) * s
		for linea: Array in LETRAS[ch]:
			var d := ""
			for k in linea.size():
				var p: Array = linea[k]
				d += ("M" if k == 0 else "L") + "%.2f %.2f " % [ox + float(p[0]) * s, y0 + float(p[1]) * s]
			trazos += '<path d="%s"/>' % d.strip_edges()
	var grosor := maxf(s * 0.95, 0.9)
	var g := 'stroke-linecap="round" stroke-linejoin="round" fill="none"'
	return '<g %s stroke="%s" stroke-width="%.2f" opacity=".9">%s</g><g %s stroke="%s" stroke-width="%.2f">%s</g>' % [g, borde, grosor + 1.6, trazos, g, color, grosor, trazos]

## La figura `clave` colocada en (cx, cy) con `lado` unidades de alto; "" si no existe o están apagadas.
static func figura_svg(clave: String, cx: float, cy: float, lado: float, color: String, detalle: String) -> String:
	if not FIGURAS.has(clave):
		return ""
	var s := lado / 40.0
	var cuerpo := String(FIGURAS[clave]).replace("{F}", color).replace("{D}", detalle)
	return '<g transform="translate(%.2f %.2f) scale(%.3f) translate(-20 -20)">%s</g>' % [cx, cy, s, cuerpo]

## Las capas del escudo de un club: sombra fina, figura y letras. `fondo` es el color del campo, para elegir el que contrasta.
static func capa_de(c: Club, fondo: String) -> String:
	if not activo:
		return ""
	var fig := AspectoClub.emblema(c)
	var letras := AspectoClub.letras(c)
	var color_letras := ""
	if letras.contains("/"):   ## «CABJ/#0b3d91»: las letras con su color
		color_letras = letras.get_slice("/", 1)
		letras = letras.get_slice("/", 0)
	if fig == "" and letras == "":
		return ""
	var claro := Color(fondo).get_luminance() > 0.5
	var tinta := "#14171c" if claro else "#ffffff"
	var borde := "#ffffff" if claro else "#14171c"
	var acento := AspectoClub.esc(c, 1, "")
	if acento == "" or absf(Color(acento).get_luminance() - Color(fondo).get_luminance()) < 0.28:
		acento = tinta
	var out := ""
	if color_letras != "":
		tinta = color_letras
		borde = "#ffffff" if Color(color_letras).get_luminance() < 0.5 else "#14171c"
	if fig != "" and letras != "":
		out += figura_svg(fig, 32.0, 25.0, 25.0, acento, fondo)
		out += letras_svg(letras, 32.0, 49.0, 30.0, 11.0, tinta, borde)
	elif fig != "":
		out += figura_svg(fig, 32.0, 33.0, 32.0, acento, fondo)
	else:
		var col := color_letras if color_letras != "" else acento
		out += letras_svg(letras, 32.0, 33.0, 38.0, 24.0, col, "#14171c" if Color(col).get_luminance() > 0.5 else "#ffffff")
	return out
