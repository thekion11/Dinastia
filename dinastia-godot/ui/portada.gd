class_name Portada
extends RefCounted
## Las nueve portadas del menú, portadas del HTML.
##
## Son franjas panorámicas de 1200×200 (casi 6:1) dibujadas con formas. En el
## HTML el lienzo empezó siendo de 400×200 y se recortaba con `slice`, así que
## solo se veía la banda central: se perdían el cielo y el césped. Por eso aquí
## el lienzo es panorámico de verdad y la escena se compone a lo ancho.
##
## DOS COSAS QUE NO SOBREVIVEN AL PORTE, y conviene tenerlas escritas:
##
## 1. **La animación.** El HTML usa `<animate>` de SVG (SMIL) para el parpadeo de
##    los focos, el humo que respira y los flashes de la grada. El rasterizador
##    de Godot dibuja el primer fotograma y ya. Las portadas quedan fijas, no
##    rotas: se ve la escena entera, sin el movimiento.
## 2. **El texto.** El rasterizador no dibuja `<text>`, así que el título y el
##    lema van encima como etiquetas de Godot. Además quedan más nítidos.
##
## El resto -degradados, focos, gente, tifos, humo- es geometría y se porta tal
## cual, así que la identidad visual de cada portada se mantiene.

const W := 1200
const H := 200
const CX := 600

const NOMBRES := ["clasica", "nocturna", "retro", "prensa", "neon", "tifo", "trofeo", "pizarra", "minimal",
	"andino", "vestuario", "cabina", "ejecutiva", "tunel", "lluvia", "datos", "graffiti", "marmol"]
const TITULOS := {
	"clasica": "Clásica", "nocturna": "Noche de copa", "retro": "Retro",
	"prensa": "Portada de prensa", "neon": "Neón", "tifo": "Tifo",
	"trofeo": "Vitrina", "pizarra": "Pizarra", "minimal": "Minimal",
	## Las nueve de más: propuestas de Gemini (Drive, "Visual gemini") que
	## llegaron como catálogo de texto, sin un solo trazo de código -acá se
	## dibujan con el mismo lenguaje que las nueve de arriba, para que no se
	## note la costura entre las que vinieron del HTML y las que no.
	"andino": "Atardecer andino", "vestuario": "Vestuario táctico", "cabina": "Cabina de prensa",
	"ejecutiva": "Sala ejecutiva", "tunel": "Túnel de campeones", "lluvia": "Bajo la lluvia",
	"datos": "Centro de datos", "graffiti": "Graffiti de barrio", "marmol": "Mármol y oro",
}

## El mismo generador estable del HTML: dos enteros entran, un número entre 0 y 1
## sale. Se usa para repartir la gente por la grada sin que cambie en cada
## repintado, que es lo que haría un azar de verdad.
static func _r(a: int, b: int) -> float:
	var h := (a * 73856093) ^ (b * 19349663)
	h = (h ^ (h >> 13)) & 0x7FFFFFFF
	return float(h % 1000) / 1000.0

static func svg_de(k: String) -> String:
	match k:
		"nocturna": return _nocturna()
		"retro": return _retro()
		"prensa": return _prensa()
		"neon": return _neon()
		"tifo": return _tifo()
		"trofeo": return _trofeo()
		"pizarra": return _pizarra()
		"minimal": return _minimal()
		"andino": return _andino()
		"vestuario": return _vestuario()
		"cabina": return _cabina()
		"ejecutiva": return _ejecutiva()
		"tunel": return _tunel()
		"lluvia": return _lluvia()
		"datos": return _datos()
		"graffiti": return _graffiti()
		"marmol": return _marmol()
	return _clasica()

static func _marco(defs: String, cuerpo: String) -> String:
	return '<svg width="%d" height="%d" viewBox="0 0 %d %d" xmlns="http://www.w3.org/2000/svg"><defs>%s</defs>%s</svg>' % [W, H, W, H, defs, cuerpo]

# --- las nueve --------------------------------------------------------------

## La de siempre: cielo, césped en perspectiva y las líneas del campo.
static func _clasica() -> String:
	var defs := """
<linearGradient id="ci" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#1b3a5c"/><stop offset="1" stop-color="#3d6f96"/></linearGradient>
<linearGradient id="ce" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#2f7a45"/><stop offset="1" stop-color="#17482a"/></linearGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#ci)"/>' % [W, H]
	c += '<path d="M0 118 Q%d 104 %d 118 L%d %d L0 %dZ" fill="url(#ce)"/>' % [CX, W, W, H, H]
	## Las rayas del césped en perspectiva: se estrechan hacia el fondo, que es
	## lo que da la sensación de profundidad sin dibujar nada en 3D.
	for i in 14:
		if i % 2 == 0:
			continue
		c += '<path d="M%d %d L%d 118 L%d 118 L%d %dZ" fill="#ffffff" opacity=".045"/>' % [
			i * 100 - 240, H, i * 62 + 40, i * 62 + 74, i * 100 - 140, H]
	c += '<path d="M0 132 Q%d 120 %d 132" stroke="#ffffff" stroke-width="2" fill="none" opacity=".5"/>' % [CX, W]
	c += '<ellipse cx="%d" cy="168" rx="118" ry="26" fill="none" stroke="#ffffff" stroke-width="2" opacity=".45"/>' % CX
	return _marco(defs, c)

## Noche de copa: ocho torres de luz, 430 personas en la grada y humo dorado.
static func _nocturna() -> String:
	var defs := """
<linearGradient id="cn" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#050a14"/><stop offset="1" stop-color="#0f1c26"/></linearGradient>
<radialGradient id="hz" cx="0.5" cy="0" r="1">
<stop offset="0" stop-color="#fff3c4" stop-opacity=".85"/><stop offset="1" stop-color="#fff3c4" stop-opacity="0"/></radialGradient>
<linearGradient id="cp" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#2f7a45"/><stop offset="1" stop-color="#17482a"/></linearGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#cn)"/>' % [W, H]
	## La gente primero, que va detrás de todo.
	var colores := ["#c9a227", "#e8ede9", "#8fa3b5", "#d4a08a"]
	for i in 430:
		var x := int(_r(i, 3) * float(W))
		var y := int(84.0 + _r(i, 7) * 38.0)
		c += '<circle cx="%d" cy="%d" r="%.1f" fill="%s" opacity="%.2f"/>' % [
			x, y, 0.9 + _r(i, 11) * 0.9, colores[i % 4], 0.3 + _r(i, 13) * 0.6]
	for i in 8:
		var x := 80 + i * 148
		c += '<rect x="%.1f" y="26" width="3" height="52" fill="#4a5560"/>' % (float(x) - 1.5)
		c += '<rect x="%d" y="16" width="22" height="11" rx="2" fill="#2b343d"/>' % (x - 11)
		for j in 4:
			c += '<circle cx="%.1f" cy="21.5" r="2.1" fill="#ffeeae"/>' % (float(x) - 7.5 + float(j) * 5.0)
		c += '<path d="M%d 24 L%d 140 L%d 140Z" fill="url(#hz)" opacity=".26"/>' % [x, x - 70, x + 70]
	for i in 8:
		c += '<ellipse cx="%d" cy="118" rx="52" ry="14" fill="#c9a227" opacity=".08"/>' % (80 + i * 150)
	c += '<path d="M0 138 Q%d 128 %d 138 L%d %d L0 %dZ" fill="url(#cp)"/>' % [CX, W, W, H, H]
	return _marco(defs, c)

## Retro: naranja quemado, sol de rayos y un horizonte de colinas.
static func _retro() -> String:
	var defs := """
<linearGradient id="rt" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#e8a13a"/><stop offset=".55" stop-color="#d4682c"/><stop offset="1" stop-color="#7a2f1f"/></linearGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#rt)"/>' % [W, H]
	c += '<g transform="translate(900,58)" opacity=".55">'
	for i in 16:
		var a1 := float(i) * PI / 8.0
		var a2 := (float(i) + 0.5) * PI / 8.0
		c += '<path d="M0 0 L%d %d L%d %dZ" fill="#ffd98a" opacity=".5"/>' % [
			int(cos(a1) * 620.0), int(sin(a1) * 620.0), int(cos(a2) * 620.0), int(sin(a2) * 620.0)]
	c += '</g><circle cx="900" cy="58" r="40" fill="#ffe9a3" opacity=".85"/>'
	c += '<path d="M-20 150 Q300 126 600 150 T%d 146 L%d %d L-20 %dZ" fill="#5d2216" opacity=".55"/>' % [W + 20, W + 20, H, H]
	## El punteado de impresión vieja: es lo que le da el aire de cartel de los 70.
	for i in 300:
		c += '<circle cx="%d" cy="%d" r="1.1" fill="#3a1408" opacity=".14"/>' % [
			int(_r(i, 23) * float(W)), int(_r(i, 29) * float(H))]
	return _marco(defs, c)

## Portada de prensa: papel de periódico con sus columnas y su mancha de tinta.
static func _prensa() -> String:
	var defs := """
<linearGradient id="pp" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#efe9dc"/><stop offset="1" stop-color="#d8d0bf"/></linearGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#pp)"/>' % [W, H]
	c += '<rect x="0" y="0" width="%d" height="6" fill="#1c1a17"/>' % W
	## Las columnas de texto se sugieren con rayas: a este tamaño el ojo las lee
	## como un periódico sin necesidad de una sola letra.
	for col in 5:
		var x := 40 + col * 232
		for l in 11:
			var ancho := int(120.0 + _r(col * 20 + l, 31) * 80.0)
			c += '<rect x="%d" y="%d" width="%d" height="4" rx="2" fill="#2a2722" opacity=".30"/>' % [
				x, 44 + l * 13, ancho, ]
	c += '<rect x="40" y="16" width="470" height="16" rx="2" fill="#1c1a17" opacity=".85"/>'
	c += '<ellipse cx="1010" cy="118" rx="120" ry="62" fill="#1c1a17" opacity=".10"/>'
	return _marco(defs, c)

## Neón: rejilla en fuga, sol partido y líneas rosas. El cartel ochentero.
static func _neon() -> String:
	var defs := """
<linearGradient id="nn" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#160a2e"/><stop offset=".62" stop-color="#3b1257"/><stop offset="1" stop-color="#0a0518"/></linearGradient>
<linearGradient id="sl" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#ffe14d"/><stop offset=".5" stop-color="#ff6a3d"/><stop offset="1" stop-color="#ff2b7a"/></linearGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#nn)"/>' % [W, H]
	c += '<circle cx="%d" cy="104" r="72" fill="url(#sl)"/>' % CX
	## El sol partido en franjas: cuatro cortes horizontales y ya es un sol de
	## sintetizador y no una pelota.
	for i in 4:
		c += '<rect x="%d" y="%d" width="180" height="6" fill="#160a2e"/>' % [CX - 90, 96 + i * 14]
	for i in 24:
		c += '<line x1="%d" y1="200" x2="%d" y2="120" stroke="#ff3d9a" stroke-width="1" opacity=".5"/>' % [
			-600 + i * 80, CX - 330 + i * 22]
	for i in 8:
		var y := 122.0 + float(i * i) * 1.15
		c += '<line x1="-60" y1="%.1f" x2="%d" y2="%.1f" stroke="#00e5ff" stroke-width="%.2f" opacity=".45"/>' % [
			y, W + 60, y, 0.5 + float(i) * 0.16]
	return _marco(defs, c)

## Tifo: la grada entera levantando un mosaico.
static func _tifo() -> String:
	var c := '<rect width="%d" height="%d" fill="#08110c"/>' % [W, H]
	## El mosaico: 24×9 cartulinas que dibujan una franja diagonal.
	var cols := 24
	var filas := 9
	c += '<g transform="translate(%.1f,18) scale(1.9)">' % ((float(W) - float(cols) * 8.1 * 1.9) / 2.0)
	for f in filas:
		for c2 in cols:
			var encendida := ((c2 + f) % 7) < 3
			var col := "#c9a227" if encendida else ("#123a22" if (c2 + f) % 2 == 0 else "#0d2a18")
			c += '<rect x="%.1f" y="%.1f" width="7.3" height="6.4" rx="1" fill="%s"/>' % [
				float(c2) * 8.1, float(f) * 7.1, col]
	c += '</g>'
	for i in 260:
		c += '<circle cx="%d" cy="%d" r="%.1f" fill="#e8ede9" opacity=".35"/>' % [
			int(_r(i, 41) * float(W)), int(150.0 + _r(i, 43) * 46.0), 1.0 + _r(i, 47) * 1.4]
	c += '<path d="M0 148 Q%d 138 %d 148 L%d %d L0 %dZ" fill="#0d1a12"/>' % [CX, W, W, H, H]
	return _marco("", c)

## Vitrina: la copa en el centro sobre terciopelo oscuro.
static func _trofeo() -> String:
	var defs := """
<linearGradient id="oro" x1="0" y1="0" x2="0.4" y2="1">
<stop offset="0" stop-color="#ffe9a3"/><stop offset=".45" stop-color="#d4a92c"/><stop offset="1" stop-color="#8a6414"/></linearGradient>
<radialGradient id="fo" cx="0.5" cy="0.45" r="0.75">
<stop offset="0" stop-color="#2a2118"/><stop offset="1" stop-color="#0b0906"/></radialGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#fo)"/>' % [W, H]
	c += '<ellipse cx="%d" cy="176" rx="150" ry="18" fill="#000000" opacity=".55"/>' % CX
	## La copa: base, pie, cuenco y asas. Cinco formas y se reconoce.
	c += '<rect x="%d" y="158" width="132" height="16" rx="4" fill="url(#oro)"/>' % (CX - 66)
	c += '<rect x="%d" y="128" width="26" height="32" fill="url(#oro)"/>' % (CX - 13)
	c += '<path d="M%d 46 h116 v34a58 58 0 0 1 -116 0Z" fill="url(#oro)"/>' % (CX - 58)
	c += '<path d="M%d 54 q-46 6 -30 40 q10 20 30 20" fill="none" stroke="url(#oro)" stroke-width="10"/>' % (CX - 58)
	c += '<path d="M%d 54 q46 6 30 40 q-10 20 -30 20" fill="none" stroke="url(#oro)" stroke-width="10"/>' % (CX + 58)
	## Destellos alrededor, que es lo que hace que el oro parezca oro.
	for i in 40:
		c += '<circle cx="%d" cy="%d" r="%.1f" fill="#ffe9a3" opacity="%.2f"/>' % [
			int(_r(i, 53) * float(W)), int(_r(i, 59) * float(H)), 0.6 + _r(i, 61) * 1.2, 0.15 + _r(i, 67) * 0.5]
	return _marco(defs, c)

## Pizarra: el esquema táctico dibujado con tiza.
static func _pizarra() -> String:
	var c := '<rect width="%d" height="%d" fill="#13332a"/>' % [W, H]
	c += '<rect x="24" y="14" width="%d" height="%d" rx="6" fill="none" stroke="#cfe6d8" stroke-width="2" opacity=".55"/>' % [W - 48, H - 28]
	c += '<line x1="%d" y1="14" x2="%d" y2="%d" stroke="#cfe6d8" stroke-width="2" opacity=".45"/>' % [CX, CX, H - 14]
	c += '<circle cx="%d" cy="%d" r="46" fill="none" stroke="#cfe6d8" stroke-width="2" opacity=".45"/>' % [CX, H / 2]
	## Un 4-3-3 de tiza, con las flechas de los desmarques.
	var puestos := [[90, 100], [230, 44], [230, 88], [230, 132], [230, 176],
		[380, 66], [380, 100], [380, 156], [520, 40], [520, 100], [520, 168]]
	for p: Array in puestos:
		c += '<circle cx="%d" cy="%d" r="11" fill="none" stroke="#f4d35e" stroke-width="2.4"/>' % [p[0], p[1]]
	for p: Array in [[520, 40], [520, 100], [520, 168]]:
		c += '<path d="M%d %d q60 -14 118 -4" stroke="#f4d35e" stroke-width="2" fill="none" opacity=".8" stroke-dasharray="7 5"/>' % [p[0] + 14, p[1]]
	return _marco("", c)

## Minimal: fondo liso y una sola línea. La que no compite con el texto.
##
## El degradado y el verde son los de `.pHmin`/`--acc` del HTML
## (`background:linear-gradient(160deg,#101512,#0a0d0b)`), no un azul-verde
## inventado para Godot: la mudanza cambia el motor, no cómo se ve el juego.
static func _minimal() -> String:
	var defs := """
<linearGradient id="mn" x1="0" y1="0" x2="1" y2="1">
<stop offset="0" stop-color="#101512"/><stop offset="1" stop-color="#0a0d0b"/></linearGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#mn)"/>' % [W, H]
	c += '<circle cx="%d" cy="%d" r="64" fill="none" stroke="#3fa06a" stroke-width="2" opacity=".55"/>' % [CX, H / 2]
	c += '<line x1="0" y1="%d" x2="%d" y2="%d" stroke="#3fa06a" stroke-width="2" opacity=".35"/>' % [H / 2, W, H / 2]
	return _marco(defs, c)

# --- las nueve de Gemini -----------------------------------------------------

## Atardecer andino: cordillera nevada a contraluz frente a un cielo violeta-
## naranja, con la silueta de un estadio moderno recortada abajo.
static func _andino() -> String:
	var defs := """
<linearGradient id="an" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#3a1f52"/><stop offset=".45" stop-color="#8a3a5c"/><stop offset=".75" stop-color="#d97a3a"/><stop offset="1" stop-color="#f2b25c"/></linearGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#an)"/>' % [W, H]
	c += '<circle cx="%d" cy="118" r="46" fill="#ffe9c4" opacity=".55"/>' % (CX + 90)
	## La cordillera: picos irregulares que no se repiten, con nieve arriba.
	var picos := "M-20 150"
	for i in 13:
		var x := -20 + i * 105
		var y := 60.0 + _r(i, 71) * 55.0
		picos += " L%d %.0f" % [x + 52, y]
	picos += " L%d 150Z" % (W + 20)
	c += '<path d="%s" fill="#241733" opacity=".92"/>' % picos
	for i in 13:
		var x := -20 + i * 105 + 52
		var y := 60.0 + _r(i, 71) * 55.0
		c += '<path d="M%d %.0f l14 10 l-28 0Z" fill="#f0e9e0" opacity=".8"/>' % [x, y]
	## El estadio, en silueta, recortado contra el horizonte ya oscuro.
	c += '<path d="M%d 150 q%d -34 %d 0 l0 50 l-%d 0Z" fill="#0b0710"/>' % [CX - 130, 130, 130, 260]
	for i in 9:
		c += '<rect x="%d" y="108" width="3" height="18" fill="#0b0710"/>' % (CX - 120 + i * 30)
	return _marco(defs, c)

## Vestuario táctico: la pizarra magnética del camerino, con imanes de
## formación y las camisetas colgando de los casilleros.
static func _vestuario() -> String:
	var c := '<rect width="%d" height="%d" fill="#15231c"/>' % [W, H]
	c += '<rect x="60" y="18" width="%d" height="120" rx="4" fill="#0d1712" stroke="#3fa06a" stroke-width="2" opacity=".85"/>' % (W - 400)
	c += '<line x1="%d" y1="18" x2="%d" y2="138" stroke="#3fa06a" stroke-width="1.4" opacity=".5"/>' % [(W - 400) / 2 + 60, (W - 400) / 2 + 60]
	var puestos := [[100, 118], [180, 48], [180, 92], [180, 132], [260, 68], [260, 108], [340, 88]]
	for p: Array in puestos:
		c += '<circle cx="%d" cy="%d" r="9" fill="none" stroke="#f4d35e" stroke-width="2.2"/>' % [p[0], p[1]]
	## Los casilleros a la derecha, con una camiseta de sombra en cada uno.
	for i in 5:
		var x := W - 320 + i * 68
		c += '<rect x="%d" y="20" width="58" height="120" fill="#1c2a22" stroke="#0d1712" stroke-width="2"/>' % x
		c += '<path d="M%d 46 l14-8 h20 l14 8 v10 l-10 4 v46 h-28 v-46 l-10-4Z" fill="#0d1712" opacity=".65"/>' % (x + 8)
	return _marco("", c)

## Cabina de prensa: monitores de estadísticas y el campo iluminado al fondo,
## visto desde arriba como desde la caseta de transmisión.
static func _cabina() -> String:
	var defs := """
<linearGradient id="cb" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#0a1420"/><stop offset="1" stop-color="#132133"/></linearGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#cb)"/>' % [W, H]
	c += '<path d="M0 150 L%d 100 L%d 100 L%d 150Z" fill="#0f2a18" opacity=".7"/>' % [CX - 150, CX + 150, W]
	for i in 6:
		c += '<line x1="%d" y1="150" x2="%d" y2="104" stroke="#1c4a2a" stroke-width="1" opacity=".5"/>' % [i * 200, CX + (i * 200 - CX) / 3]
	## Tres monitores con una gráfica de barras distinta cada uno.
	for m in 3:
		var x := 90 + m * 200
		c += '<rect x="%d" y="20" width="160" height="70" rx="4" fill="#050a12" stroke="#2c5a7a" stroke-width="1.5"/>' % x
		for i in 8:
			var alto := 6.0 + _r(m * 10 + i, 83) * 46.0
			c += '<rect x="%d" y="%.1f" width="12" height="%.1f" fill="#3fd0ff" opacity=".7"/>' % [x + 14 + i * 17, 84.0 - alto, alto]
	return _marco(defs, c)

## Sala ejecutiva: ventanal con el perfil de la ciudad, mesa de madera y el
## escudo del club en relieve al fondo.
static func _ejecutiva() -> String:
	var defs := """
<linearGradient id="ej" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#1c1712"/><stop offset="1" stop-color="#0d0a08"/></linearGradient>
<linearGradient id="ci2" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#2c3a52"/><stop offset="1" stop-color="#101820"/></linearGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#ej)"/>' % [W, H]
	c += '<rect x="70" y="14" width="%d" height="100" fill="url(#ci2)"/>' % (W - 140)
	## El perfil de rascacielos, con ventanas encendidas al azar.
	for i in 14:
		var x := 90 + i * 74
		var alto := 30.0 + _r(i, 91) * 60.0
		c += '<rect x="%d" y="%.1f" width="54" height="%.1f" fill="#0a1018"/>' % [x, 114.0 - alto, alto]
		for j in 3:
			if _r(i * 3 + j, 97) > 0.55:
				c += '<rect x="%.1f" y="%.1f" width="8" height="8" fill="#f2c96b" opacity=".8"/>' % [x + 10.0 + float(j) * 16.0, 100.0 - alto * 0.6]
	c += '<rect x="0" y="150" width="%d" height="%d" fill="#3a2a1a"/>' % [W, H - 150]
	c += '<circle cx="%d" cy="150" r="24" fill="none" stroke="#c9a227" stroke-width="2" opacity=".7"/>' % CX
	return _marco(defs, c)

## Túnel de campeones: perspectiva simétrica hacia la cancha, luces cenitales
## frías y las placas del pasillo.
static func _tunel() -> String:
	var c := '<rect width="%d" height="%d" fill="#101418"/>' % [W, H]
	## Los anillos del túnel, cada vez más chicos hacia el fondo.
	for i in 7:
		var t := float(i) / 6.0
		## `lerpf()` y no `lerp()`: el genérico devuelve Variant -sirve para
		## float, Vector2, Color...- y con `:=` el tipo queda inferido como
		## Variant, que este proyecto trata como error de compilación. Rompía
		## en silencio: ningún banco carga `ui/`, así que nadie lo vio hasta
		## que una prueba nueva abrió por fin la pantalla de inicio de verdad.
		var w := lerpf(float(W) + 40.0, 220.0, t)
		var h := lerpf(float(H) + 20.0, 90.0, t)
		var y := lerpf(-10.0, 60.0, t)
		c += '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="none" stroke="#3a4652" stroke-width="1.4" opacity="%.2f"/>' % [
			CX - w / 2.0, y, w, h, 0.15 + t * 0.35]
	c += '<rect x="%d" y="150" width="220" height="50" fill="#cfe6d8" opacity=".18"/>' % (CX - 110)
	for i in 4:
		c += '<rect x="%d" y="4" width="14" height="4" fill="#dff0ff" opacity="%.2f"/>' % [
			CX - 90 + i * 60, 0.4 + float(i) * 0.1]
	return _marco("", c)

## Césped bajo la lluvia: cancha empapada de noche, charcos que devuelven el
## reflejo de los reflectores y el vapor subiendo del pasto.
static func _lluvia() -> String:
	var defs := """
<linearGradient id="ll" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#050a10"/><stop offset="1" stop-color="#0a1a14"/></linearGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#ll)"/>' % [W, H]
	c += '<path d="M0 128 Q%d 116 %d 128 L%d %d L0 %dZ" fill="#0a1c14"/>' % [CX, W, W, H, H]
	## Los charcos: elipses claras con el reflejo dorado del foco encima.
	for i in 9:
		var x := int(_r(i, 101) * float(W))
		var y := 140 + int(_r(i, 103) * 46.0)
		c += '<ellipse cx="%d" cy="%d" rx="%.1f" ry="4" fill="#bcd8e6" opacity=".22"/>' % [x, y, 18.0 + _r(i, 107) * 20.0]
	for i in 2:
		var x := 260 + i * 680
		c += '<path d="M%d 24 L%d 200 L%d 200Z" fill="#fff3c4" opacity=".08"/>' % [x, x - 90, x + 90]
	## La lluvia: líneas finas cayendo en diagonal, todas con el mismo ángulo.
	for i in 90:
		var x := int(_r(i, 109) * float(W + 120)) - 60
		var y := int(_r(i, 113) * float(H))
		c += '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="#c9dde8" stroke-width="1" opacity=".25"/>' % [x, y, x - 8, y + 16]
	return _marco(defs, c)

## Centro de datos: mapas de calor y curvas de rendimiento sobre un panel
## analítico, con el brillo frío de las pantallas holográficas.
static func _datos() -> String:
	var defs := """
<linearGradient id="dt" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#04080f"/><stop offset="1" stop-color="#081522"/></linearGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#dt)"/>' % [W, H]
	## El mapa de calor: una cuadrícula de celdas con intensidad variable.
	var cols := 18
	var filas := 6
	c += '<g transform="translate(60,20)">'
	for f in filas:
		for col in cols:
			var v := _r(col * 7 + f, 127)
			var col_hex := "#0d2a3a" if v < 0.4 else ("#1c5a7a" if v < 0.7 else "#3fd0ff")
			c += '<rect x="%d" y="%d" width="26" height="16" rx="2" fill="%s" opacity="%.2f"/>' % [
				col * 29, f * 19, col_hex, 0.35 + v * 0.5]
	c += '</g>'
	## La curva de rendimiento, encima, como un electrocardiograma de rendimiento.
	var curva := "M60 170"
	for i in 22:
		var y := 170.0 - _r(i, 131) * 30.0
		curva += " L%d %.1f" % [60 + i * 48, y]
	c += '<path d="%s" fill="none" stroke="#7fffc4" stroke-width="1.6" opacity=".8"/>' % curva
	return _marco(defs, c)

## Graffiti de barrio: mural callejero sobre ladrillo, con los colores crudos
## de las barras y sin una sola curva perfecta.
static func _graffiti() -> String:
	var c := '<rect width="%d" height="%d" fill="#2a2420"/>' % [W, H]
	## El ladrillo: filas de rectángulos alternados con su junta de mortero.
	for f in 8:
		var offset := 0 if f % 2 == 0 else 30
		for i in 22:
			c += '<rect x="%d" y="%d" width="58" height="22" fill="#241f1c" stroke="#3a322c" stroke-width="1.5"/>' % [
				offset + i * 60 - 60, f * 24]
	## El mural encima: formas grandes de colores planos, como una tag pintada.
	var colores := ["#e0463c", "#f0b429", "#3fa06a", "#2c8fd4"]
	for i in 5:
		var x := 60 + i * 220
		var y := 40 + int(_r(i, 137) * 60.0)
		c += '<path d="M%d %d q60 -30 120 0 q-20 60 -60 70 q-50 -10 -60 -70Z" fill="%s" opacity=".85"/>' % [
			x, y, colores[i % 4]]
	c += '<rect x="0" y="0" width="%d" height="%d" fill="#000000" opacity=".18"/>' % [W, H]
	return _marco("", c)

## Mármol y oro: la textura del Salón de la Fama, mármol negro pulido con
## vetas finas y una placa dorada envejecida en el centro.
static func _marmol() -> String:
	var defs := """
<linearGradient id="mo" x1="0" y1="0" x2="1" y2="1">
<stop offset="0" stop-color="#0d0d0f"/><stop offset="1" stop-color="#1a1a1e"/></linearGradient>
<linearGradient id="orv" x1="0" y1="0" x2="1" y2="0">
<stop offset="0" stop-color="#8a6414"/><stop offset=".5" stop-color="#f0d98a"/><stop offset="1" stop-color="#8a6414"/></linearGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#mo)"/>' % [W, H]
	## Las vetas: curvas finas e irregulares, como el mármol de verdad.
	for i in 10:
		var y0 := _r(i, 139) * float(H)
		var ruta := "M-20 %.1f" % y0
		for j in 5:
			ruta += " Q%d %.1f %d %.1f" % [
				j * 320 + 140, y0 + (_r(i * 5 + j, 149) - 0.5) * 40.0, j * 320 + 320, y0 + (_r(i * 5 + j + 1, 151) - 0.5) * 40.0]
		c += '<path d="%s" fill="none" stroke="#c9c2b4" stroke-width="%.1f" opacity="%.2f"/>' % [
			ruta, 0.6 + _r(i, 157) * 1.0, 0.08 + _r(i, 163) * 0.10]
	c += '<rect x="%d" y="70" width="260" height="60" rx="3" fill="url(#orv)" opacity=".92"/>' % (CX - 130)
	c += '<rect x="%d" y="76" width="248" height="48" rx="2" fill="none" stroke="#5c4410" stroke-width="1.5"/>' % (CX - 124)
	return _marco(defs, c)

# ---------------------------------------------------------------------------

static var _cache: Dictionary = {}

## La portada rasterizada. Se cachea: son 430 círculos en la nocturna y no hay
## que volver a dibujarlos cada vez que se repinta el menú.
static func textura(k: String, ancho_px: int = 1200) -> Texture2D:
	var clave := "%s_%d" % [k, ancho_px]
	if _cache.has(clave):
		return _cache[clave]
	var img := Image.new()
	if img.load_svg_from_string(svg_de(k), float(ancho_px) / float(W)) != OK:
		return null
	var t := ImageTexture.create_from_image(img)
	_cache[clave] = t
	return t
