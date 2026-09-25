class_name Fondo
extends RefCounted
## Los fondos de pantalla completa del juego.
##
## POR QUÉ NO SE REUTILIZAN LAS PORTADAS. `Portada` dibuja franjas de 1200×200
## (casi 6:1) pensadas para el banner del menú. Estirarlas a 1600×900 obliga a
## recortar: cubriendo el alto, de 1200 de ancho solo se verían unos 350, o sea
## un tercio de la escena. Ese error exacto -lienzo con una relación y hueco con
## otra, `slice` recortando arte sin dar ningún aviso- ya se pagó una vez en este
## proyecto con las portadas del HTML, y la queja que llegó fue "los fondos están
## mal enfocados y se ven incompletos". Así que estos se dibujan a 16:9 de
## nacimiento y se componen a lo alto, no a lo ancho.
##
## LA OTRA REGLA, Y LA MÁS IMPORTANTE: esto va DETRÁS de una interfaz densa.
## Un fondo bonito que deja la tabla ilegible es un fondo malo. Por eso los tres
## paneles siguen siendo opacos y aquí todo es oscuro, poco saturado y de bajo
## contraste, con una viñeta encima que hunde los bordes. Se tiene que notar que
## hay algo detrás; no se tiene que poder leer.
##
## El rasterizador de Godot NO dibuja `<text>` ni anima `<animate>`, igual que en
## `Portada`. Aquí no hace falta ninguna de las dos cosas: son escenas quietas.

const W := 1600
const H := 900

## Las nueve de `Portada`, redibujadas para pantalla completa, más cinco nuevas.
## El orden es el del menú de ajustes.
const NOMBRES := [
	"cesped", "nocturna", "retro", "prensa", "neon", "tifo", "trofeo", "pizarra", "minimal",
	"tunel", "lluvia", "amanecer", "autocar", "tiza",
	"ciudad", "montana", "playa", "nieve", "juntas", "mapa", "vestuario", "bufandas",
	"diario", "aeropuerto",
]
const TITULOS := {
	"cesped": "Césped", "nocturna": "Noche de copa", "retro": "Retro",
	"prensa": "Sala de prensa", "neon": "Neón", "tifo": "Tifo",
	"trofeo": "Vitrina", "pizarra": "Pizarra", "minimal": "Minimal",
	"tunel": "Túnel de vestuario", "lluvia": "Banquillo bajo la lluvia",
	"amanecer": "Grada vacía al amanecer", "autocar": "Llegada del autocar",
	"tiza": "Pizarra de tiza",
	"ciudad": "La ciudad detras de la grada", "montana": "Estadio de pueblo",
	"playa": "Cancha de arena", "nieve": "Partido bajo la nieve",
	"juntas": "Sala de juntas", "mapa": "Mapa del ojeador",
	"vestuario": "Vestuario vacio", "bufandas": "Bufandas al viento",
	"diario": "Portada del diario", "aeropuerto": "Aeropuerto de madrugada",
}

## El mismo generador estable que usa `Portada`: dos enteros entran, un número
## entre 0 y 1 sale. Reparte gente y ventanas sin que la escena cambie en cada
## repintado, que es lo que haría un azar de verdad.
static func _r(a: int, b: int) -> float:
	var h := (a * 73856093) ^ (b * 19349663)
	h = (h ^ (h >> 13)) & 0x7FFFFFFF
	return float(h % 1000) / 1000.0

static var _cache: Dictionary = {}

## La textura lista para poner en un `TextureRect`. Se cachea porque rasterizar
## un SVG de 1600×900 cuesta, y el fondo se pide en cada repintado de pantalla.
static func textura(k: String) -> Texture2D:
	if _cache.has(k):
		return _cache[k]
	var img := Image.new()
	if img.load_svg_from_string(svg_de(k), 1.0) != OK:
		return null
	var t := ImageTexture.create_from_image(img)
	_cache[k] = t
	return t

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
		"tunel": return _tunel()
		"lluvia": return _lluvia()
		"amanecer": return _amanecer()
		"autocar": return _autocar()
		"tiza": return _tiza()
		"ciudad": return _ciudad()
		"montana": return _montana()
		"playa": return _playa()
		"nieve": return _nieve()
		"juntas": return _juntas()
		"mapa": return _mapa()
		"vestuario": return _vestuario()
		"bufandas": return _bufandas()
		"diario": return _diario()
		"aeropuerto": return _aeropuerto()
	return _cesped()

## La viñeta va en TODOS. Es lo que hace que un fondo con detalle no pelee con la
## interfaz: oscurece los bordes y el centro queda de apoyo, no de protagonista.
static func _vineta() -> String:
	return '<rect width="%d" height="%d" fill="url(#vin)"/><rect width="%d" height="%d" fill="#0c1510" opacity=".26"/>' % [W, H, W, H]

static func _marco(defs: String, cuerpo: String) -> String:
	var vd := """
<radialGradient id="vin" cx="0.5" cy="0.45" r="0.8">
<stop offset="0.45" stop-color="#000000" stop-opacity="0"/>
<stop offset="1" stop-color="#000000" stop-opacity="0.6"/></radialGradient>"""
	return '<svg width="%d" height="%d" viewBox="0 0 %d %d" xmlns="http://www.w3.org/2000/svg"><defs>%s%s</defs>%s%s</svg>' % [
		W, H, W, H, vd, defs, cuerpo, _vineta()]

# --- piezas compartidas ------------------------------------------------------

## Una grada llena vista de frente, como una nube de puntos. Dibujar 400 círculos
## sale más barato -y más creíble- que dibujar personas.
static func _gente(x0: int, y0: int, ancho: int, alto: int, filas: int, semilla: int, opac: String) -> String:
	var c := ""
	var por_fila := int(ancho / 13)
	for f in filas:
		for i in por_fila:
			var rr := _r(semilla + f * 31, i)
			if rr < 0.28:
				continue
			var x := x0 + i * 13 + int(rr * 8.0)
			var y := y0 + int(float(f) * float(alto) / float(filas))
			## Tipo explícito: indexar un array devuelve Variant y `:=` no puede
			## inferirlo. Es la trampa nº38 del proyecto y no da error hasta que
			## se reimporta.
			var tono: String = ["#d8d3c8", "#9fb0a4", "#c2a98f", "#8ea595", "#e6e1d6"][int(rr * 5.0) % 5]
			c += '<circle cx="%d" cy="%d" r="3" fill="%s" opacity="%s"/>' % [x, y, tono, opac]
	return c

## Una torre de luz con su halo. El halo es lo que vende la noche.
static func _foco(x: int, y: int, escala: float) -> String:
	var w := int(84.0 * escala)
	var h := int(46.0 * escala)
	var c := '<rect x="%d" y="%d" width="6" height="%d" fill="#20302a"/>' % [x - 3, y, int(260.0 * escala)]
	c += '<rect x="%d" y="%d" width="%d" height="%d" rx="6" fill="#26362f"/>' % [x - w / 2, y - h, w, h]
	for i in 4:
		for j in 2:
			c += '<circle cx="%d" cy="%d" r="%d" fill="#fff6d5" opacity=".92"/>' % [
				x - w / 2 + 12 + i * int(float(w - 24) / 3.0), y - h + 14 + j * 18, int(6.0 * escala)]
	c += '<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="url(#halo)"/>' % [x, y - h / 2, int(200.0 * escala), int(150.0 * escala)]
	return c

# --- los catorce -------------------------------------------------------------

## Césped en perspectiva: la de siempre, pero mirando al campo desde la tribuna.
static func _cesped() -> String:
	var defs := """
<linearGradient id="ci" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#16304a"/><stop offset="1" stop-color="#2d5570"/></linearGradient>
<linearGradient id="ce" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#2c7040"/><stop offset="1" stop-color="#0f3520"/></linearGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#ci)"/>' % [W, H]
	c += '<path d="M0 300 Q800 262 1600 300 L1600 900 L0 900Z" fill="url(#ce)"/>'
	## Las rayas se estrechan hacia el fondo: es lo que da profundidad sin 3D.
	for i in 18:
		if i % 2 == 0:
			continue
		c += '<path d="M%d 900 L%d 300 L%d 300 L%d 900Z" fill="#ffffff" opacity=".035"/>' % [
			i * 170 - 700, i * 92 + 30, i * 92 + 76, i * 170 - 520]
	c += '<path d="M0 380 Q800 342 1600 380" stroke="#ffffff" stroke-width="3" fill="none" opacity=".28"/>'
	c += '<ellipse cx="800" cy="640" rx="300" ry="92" fill="none" stroke="#ffffff" stroke-width="3" opacity=".22"/>'
	c += '<path d="M560 900 L560 780 L1040 780 L1040 900" fill="none" stroke="#ffffff" stroke-width="3" opacity=".2"/>'
	return _marco(defs, c)

## Noche de copa: seis torres, grada llena y humo dorado subiendo.
static func _nocturna() -> String:
	var defs := """
<linearGradient id="ci" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#050b16"/><stop offset="1" stop-color="#14243a"/></linearGradient>
<linearGradient id="ce" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#1f5c36"/><stop offset="1" stop-color="#0a2417"/></linearGradient>
<radialGradient id="halo" cx="0.5" cy="0.5" r="0.5">
<stop offset="0" stop-color="#fff3cf" stop-opacity=".5"/>
<stop offset="1" stop-color="#fff3cf" stop-opacity="0"/></radialGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#ci)"/>' % [W, H]
	## Estrellas: pocas y pequeñas, o compiten con la interfaz.
	for i in 90:
		var x := int(_r(i, 7) * float(W))
		var y := int(_r(i, 13) * 300.0)
		c += '<circle cx="%d" cy="%d" r="1.4" fill="#ffffff" opacity="%.2f"/>' % [x, y, 0.2 + _r(i, 21) * 0.5]
	for i in 6:
		c += _foco(120 + i * 272, 150, 1.0)
	## La grada, en dos anillos que se van oscureciendo con la distancia.
	c += '<path d="M0 470 L1600 470 L1600 620 L0 620Z" fill="#0d1a24"/>'
	c += _gente(0, 486, W, 120, 8, 3, ".5")
	c += '<path d="M0 610 Q800 578 1600 610 L1600 900 L0 900Z" fill="url(#ce)"/>'
	c += '<ellipse cx="800" cy="790" rx="330" ry="86" fill="none" stroke="#ffffff" stroke-width="3" opacity=".18"/>'
	return _marco(defs, c)

## Retro: papel viejo, grano y dos tintas. La foto de un álbum de los setenta.
static func _retro() -> String:
	var defs := """
<linearGradient id="pa" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#3a3123"/><stop offset="1" stop-color="#241d15"/></linearGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#pa)"/>' % [W, H]
	c += '<path d="M0 420 Q800 386 1600 420 L1600 900 L0 900Z" fill="#2f3a25"/>'
	for i in 22:
		c += '<rect x="%d" y="420" width="34" height="480" fill="#000000" opacity=".05"/>' % (i * 74)
	c += _gente(0, 250, W, 150, 9, 11, ".24")
	## El grano: manchas grandes y muy tenues, no ruido pixel a pixel -eso en
	## SVG serían miles de nodos y el rasterizado se iría a segundos.
	for i in 130:
		var x := int(_r(i, 3) * float(W))
		var y := int(_r(i, 5) * float(H))
		c += '<circle cx="%d" cy="%d" r="%d" fill="#d8c9a0" opacity=".035"/>' % [x, y, 6 + int(_r(i, 9) * 22.0)]
	c += '<ellipse cx="800" cy="700" rx="340" ry="90" fill="none" stroke="#d8c9a0" stroke-width="3" opacity=".18"/>'
	return _marco(defs, c)

## Sala de prensa: el panel de patrocinadores y los flashes.
static func _prensa() -> String:
	var defs := """
<linearGradient id="pn" x1="0" y1="0" x2="1" y2="1">
<stop offset="0" stop-color="#13202b"/><stop offset="1" stop-color="#0a1319"/></linearGradient>
<radialGradient id="fl" cx="0.5" cy="0.5" r="0.5">
<stop offset="0" stop-color="#ffffff" stop-opacity=".7"/>
<stop offset="1" stop-color="#ffffff" stop-opacity="0"/></radialGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#pn)"/>' % [W, H]
	## El backdrop: rejilla de logos repetidos, que es lo que se ve detrás de
	## cualquier rueda de prensa del mundo.
	for f in 6:
		for i in 11:
			var x := 60 + i * 142 + (70 if f % 2 == 1 else 0)
			var y := 120 + f * 118
			c += '<rect x="%d" y="%d" width="92" height="30" rx="4" fill="#1d3140" opacity=".85"/>' % [x, y]
			c += '<circle cx="%d" cy="%d" r="11" fill="#26506a" opacity=".7"/>' % [x + 118, y + 15]
	## La mesa y los micrófonos, en sombra.
	c += '<rect x="0" y="740" width="%d" height="160" fill="#08111a"/>' % W
	for i in 7:
		c += '<rect x="%d" y="666" width="7" height="78" fill="#16242e"/>' % (520 + i * 84)
		c += '<ellipse cx="%d" cy="662" rx="15" ry="19" fill="#1c2f3b"/>' % (523 + i * 84)
	for i in 5:
		c += '<circle cx="%d" cy="%d" r="70" fill="url(#fl)" opacity=".35"/>' % [
			int(_r(i, 41) * float(W)), 300 + int(_r(i, 43) * 380.0)]
	return _marco(defs, c)

## Neón: la estética de cartel nocturno. Es el más saturado de los catorce, y
## aun así va por debajo del 40% de opacidad.
static func _neon() -> String:
	var defs := """
<linearGradient id="nb" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#150b26"/><stop offset="1" stop-color="#06121f"/></linearGradient>
<radialGradient id="ng" cx="0.5" cy="0.5" r="0.5">
<stop offset="0" stop-color="#ff3ea5" stop-opacity=".5"/>
<stop offset="1" stop-color="#ff3ea5" stop-opacity="0"/></radialGradient>
<radialGradient id="nc" cx="0.5" cy="0.5" r="0.5">
<stop offset="0" stop-color="#2ee6d6" stop-opacity=".45"/>
<stop offset="1" stop-color="#2ee6d6" stop-opacity="0"/></radialGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#nb)"/>' % [W, H]
	c += '<ellipse cx="330" cy="300" rx="330" ry="240" fill="url(#ng)"/>'
	c += '<ellipse cx="1270" cy="560" rx="360" ry="260" fill="url(#nc)"/>'
	## La retícula en fuga: dos puntos de luz y un suelo de rejilla.
	for i in 26:
		c += '<line x1="800" y1="470" x2="%d" y2="900" stroke="#2ee6d6" stroke-width="1.5" opacity=".16"/>' % (i * 128 - 800)
	for i in 9:
		var y := 500 + i * i * 5
		c += '<line x1="0" y1="%d" x2="%d" y2="%d" stroke="#ff3ea5" stroke-width="1.5" opacity=".13"/>' % [y, W, y]
	c += '<circle cx="800" cy="330" r="120" fill="none" stroke="#ffffff" stroke-width="3" opacity=".2"/>'
	return _marco(defs, c)

## Tifo: la grada entera convertida en bandera, con las banderas grandes.
static func _tifo() -> String:
	var defs := """
<linearGradient id="tf" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#12202a"/><stop offset="1" stop-color="#08131a"/></linearGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#tf)"/>' % [W, H]
	## El mosaico: cada cuadro es un hincha con su cartulina. Las franjas salen
	## de comparar la posición con una diagonal, que es como se monta de verdad.
	for f in 16:
		for i in 40:
			var x := i * 40
			var y := 120 + f * 30
			var franja := ((i + f) / 5) % 2 == 0
			var col := "#c9a227" if franja else "#1c3f5a"
			c += '<rect x="%d" y="%d" width="38" height="28" fill="%s" opacity=".5"/>' % [x, y, col]
	c += '<rect x="0" y="600" width="%d" height="300" fill="#08131a" opacity=".9"/>' % W
	## Dos banderas grandes ondeando por delante.
	c += '<path d="M120 900 L120 560 Q260 520 400 566 L400 900Z" fill="#c9a227" opacity=".35"/>'
	c += '<path d="M1180 900 L1180 590 Q1330 548 1470 596 L1470 900Z" fill="#2e6ea0" opacity=".35"/>'
	return _marco(defs, c)

## Vitrina: el trofeo grande y la sala en penumbra.
static func _trofeo() -> String:
	var defs := """
<linearGradient id="vt" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#1a1508"/><stop offset="1" stop-color="#0a0d10"/></linearGradient>
<linearGradient id="or" x1="0" y1="0" x2="1" y2="1">
<stop offset="0" stop-color="#f0d98a"/><stop offset="0.5" stop-color="#c9a227"/>
<stop offset="1" stop-color="#7d5f12"/></linearGradient>
<radialGradient id="halo" cx="0.5" cy="0.5" r="0.5">
<stop offset="0" stop-color="#ffe9a8" stop-opacity=".35"/>
<stop offset="1" stop-color="#ffe9a8" stop-opacity="0"/></radialGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#vt)"/>' % [W, H]
	c += '<ellipse cx="800" cy="430" rx="420" ry="330" fill="url(#halo)"/>'
	## La copa, centrada: cáliz, asas, tallo y peana.
	c += '<path d="M700 250 L900 250 L878 430 Q800 486 722 430Z" fill="url(#or)"/>'
	c += '<path d="M700 262 Q612 262 612 330 Q612 392 704 400" fill="none" stroke="url(#or)" stroke-width="17"/>'
	c += '<path d="M900 262 Q988 262 988 330 Q988 392 896 400" fill="none" stroke="url(#or)" stroke-width="17"/>'
	c += '<rect x="774" y="466" width="52" height="72" fill="url(#or)"/>'
	c += '<rect x="700" y="538" width="200" height="34" rx="5" fill="url(#or)"/>'
	c += '<rect x="668" y="572" width="264" height="46" rx="5" fill="#2a2416"/>'
	## Las vitrinas laterales, fuera de foco.
	for i in 4:
		c += '<rect x="%d" y="640" width="150" height="120" rx="6" fill="#141a1d" opacity=".8"/>' % (60 + i * 190)
		c += '<rect x="%d" y="640" width="150" height="120" rx="6" fill="#1f2a2e" opacity=".8"/>' % (1010 + i * 150)
	return _marco(defs, c)

## Pizarra: el dibujo táctico sobre fieltro verde oscuro.
static func _pizarra() -> String:
	var defs := """
<linearGradient id="pz" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#12281c"/><stop offset="1" stop-color="#081410"/></linearGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#pz)"/>' % [W, H]
	## El campo visto desde arriba.
	c += '<rect x="180" y="90" width="1240" height="720" rx="8" fill="none" stroke="#ffffff" stroke-width="3" opacity=".26"/>'
	c += '<line x1="800" y1="90" x2="800" y2="810" stroke="#ffffff" stroke-width="3" opacity=".26"/>'
	c += '<circle cx="800" cy="450" r="118" fill="none" stroke="#ffffff" stroke-width="3" opacity=".26"/>'
	c += '<rect x="180" y="250" width="150" height="400" fill="none" stroke="#ffffff" stroke-width="3" opacity=".26"/>'
	c += '<rect x="1270" y="250" width="150" height="400" fill="none" stroke="#ffffff" stroke-width="3" opacity=".26"/>'
	## Un 4-3-3 con las flechas de movimiento, que es lo que hace que parezca
	## una pizarra usada y no un campo vacío.
	var pos := [[300, 450], [470, 190], [470, 370], [470, 530], [470, 710],
		[720, 250], [720, 450], [720, 650], [1000, 190], [1010, 450], [1000, 710]]
	for p: Array in pos:
		c += '<circle cx="%d" cy="%d" r="22" fill="#c9a227" opacity=".62"/>' % [int(p[0]), int(p[1])]
	for p2: Array in [[1000, 190], [1010, 450], [1000, 710]]:
		c += '<path d="M%d %d L%d %d" stroke="#ffffff" stroke-width="3" opacity=".3" stroke-dasharray="12 9"/>' % [
			int(p2[0]) + 30, int(p2[1]), int(p2[0]) + 210, int(p2[1])]
	return _marco(defs, c)

## Minimal: solo el degradado de la casa y una circunferencia. El más discreto,
## y el que conviene a quien encuentre los demás ruidosos.
static func _minimal() -> String:
	var defs := """
<linearGradient id="mn" x1="0" y1="0" x2="1" y2="1">
<stop offset="0" stop-color="#0f1c16"/><stop offset="0.55" stop-color="#0c1510"/>
<stop offset="1" stop-color="#12241a"/></linearGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#mn)"/>' % [W, H]
	c += '<circle cx="1250" cy="240" r="330" fill="none" stroke="#3fa06a" stroke-width="2" opacity=".14"/>'
	c += '<circle cx="1250" cy="240" r="210" fill="none" stroke="#3fa06a" stroke-width="2" opacity=".1"/>'
	c += '<path d="M0 720 Q400 660 800 720 T1600 720" stroke="#3fa06a" stroke-width="2" fill="none" opacity=".12"/>'
	return _marco(defs, c)

# --- las cinco nuevas --------------------------------------------------------

## Túnel de vestuario: el pasillo y la boca de luz al fondo. Es la imagen del
## minuto antes de salir, y por eso el punto de fuga va bajo y centrado.
static func _tunel() -> String:
	var defs := """
<linearGradient id="tu" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#0a1014"/><stop offset="1" stop-color="#050809"/></linearGradient>
<radialGradient id="boca" cx="0.5" cy="0.5" r="0.5">
<stop offset="0" stop-color="#dff0e4" stop-opacity=".9"/>
<stop offset="0.6" stop-color="#8fc4a4" stop-opacity=".35"/>
<stop offset="1" stop-color="#8fc4a4" stop-opacity="0"/></radialGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#tu)"/>' % [W, H]
	## Las paredes en fuga hacia la salida.
	c += '<path d="M0 0 L560 300 L560 640 L0 900Z" fill="#0e171c"/>'
	c += '<path d="M1600 0 L1040 300 L1040 640 L1600 900Z" fill="#0e171c"/>'
	c += '<path d="M0 0 L1600 0 L1040 300 L560 300Z" fill="#080e11"/>'
	c += '<path d="M0 900 L560 640 L1040 640 L1600 900Z" fill="#121a1d"/>'
	## Los azulejos del pasillo, cada vez más juntos hacia el fondo.
	for i in 9:
		var t := float(i) / 9.0
		var xi := int(560.0 * t)
		var yt := int(300.0 * t)
		c += '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="#2a3a40" stroke-width="2" opacity=".5"/>' % [xi, yt, xi, 900 - yt]
		c += '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="#2a3a40" stroke-width="2" opacity=".5"/>' % [W - xi, yt, W - xi, 900 - yt]
	## La boca de luz: el campo esperando.
	c += '<rect x="560" y="300" width="480" height="340" fill="url(#boca)"/>'
	c += '<rect x="560" y="300" width="480" height="340" fill="none" stroke="#1b2b31" stroke-width="4"/>'
	## Las luces del techo.
	for i in 4:
		c += '<ellipse cx="800" cy="%d" rx="%d" ry="7" fill="#cfe3d6" opacity=".22"/>' % [70 + i * 58, 210 - i * 40]
	return _marco(defs, c)

## Banquillo bajo la lluvia: el techo del refugio, la lluvia en diagonal y el
## campo empapado devolviendo la luz.
static func _lluvia() -> String:
	var defs := """
<linearGradient id="ll" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#1a2530"/><stop offset="1" stop-color="#0a1218"/></linearGradient>
<linearGradient id="ch" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#20402c"/><stop offset="1" stop-color="#0c2016"/></linearGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#ll)"/>' % [W, H]
	c += '<path d="M0 420 Q800 396 1600 420 L1600 900 L0 900Z" fill="url(#ch)"/>'
	## Los charcos: elipses claras que reflejan el cielo.
	for i in 9:
		var x := int(_r(i, 61) * float(W))
		var y := 520 + int(_r(i, 67) * 340.0)
		c += '<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="#7fa8bd" opacity=".1"/>' % [x, y, 40 + int(_r(i, 71) * 90.0), 10 + int(_r(i, 73) * 14.0)]
	## La lluvia, toda con la misma inclinación: si cada gota cayera a su aire
	## parecería nieve.
	for i in 320:
		var x2 := int(_r(i, 17) * 1800.0) - 100
		var y2 := int(_r(i, 19) * float(H))
		var largo := 16 + int(_r(i, 23) * 26.0)
		c += '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="#cfe0ea" stroke-width="1.4" opacity=".2"/>' % [x2, y2, x2 - int(float(largo) * 0.35), y2 + largo]
	## El techo del banquillo y los asientos, en primer plano y muy oscuros.
	c += '<path d="M0 0 L1600 0 L1600 150 Q800 196 0 150Z" fill="#070c0f"/>'
	c += '<rect x="0" y="150" width="%d" height="14" fill="#101a20"/>' % W
	for i in 12:
		c += '<rect x="%d" y="700" width="96" height="70" rx="8" fill="#0d1519" opacity=".9"/>' % (30 + i * 130)
	return _marco(defs, c)

## Grada vacía al amanecer: el estadio a las siete de la mañana, sin nadie.
static func _amanecer() -> String:
	var defs := """
<linearGradient id="am" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#2a2740"/><stop offset="0.45" stop-color="#7a5560"/>
<stop offset="0.75" stop-color="#c98f66"/><stop offset="1" stop-color="#e8b87f"/></linearGradient>
<linearGradient id="ac" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#2c5e3c"/><stop offset="1" stop-color="#0e2a1a"/></linearGradient>
<radialGradient id="sol" cx="0.5" cy="0.5" r="0.5">
<stop offset="0" stop-color="#ffe0ad" stop-opacity=".8"/>
<stop offset="1" stop-color="#ffe0ad" stop-opacity="0"/></radialGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#am)"/>' % [W, H]
	c += '<circle cx="1210" cy="430" r="240" fill="url(#sol)"/>'
	c += '<circle cx="1210" cy="430" r="52" fill="#ffeec4" opacity=".75"/>'
	## La grada de enfrente, vacía: filas de asientos, sin un alma. El vacío se
	## dibuja con orden -líneas perfectas- porque eso es lo que se ve sin gente.
	c += '<path d="M0 300 L1600 300 L1600 560 L0 560Z" fill="#1a2028" opacity=".92"/>'
	for f in 11:
		for i in 80:
			c += '<rect x="%d" y="%d" width="14" height="12" rx="2" fill="#2c3a46" opacity=".75"/>' % [i * 20 + (10 if f % 2 == 1 else 0), 306 + f * 23]
	c += '<path d="M0 556 Q800 528 1600 556 L1600 900 L0 900Z" fill="url(#ac)"/>'
	## El rocío y las sombras largas del amanecer.
	for i in 7:
		c += '<path d="M%d 900 L%d 600" stroke="#000000" stroke-width="%d" opacity=".08"/>' % [i * 240, i * 240 + 190, 60]
	c += '<ellipse cx="800" cy="760" rx="360" ry="92" fill="none" stroke="#ffffff" stroke-width="3" opacity=".16"/>'
	return _marco(defs, c)

## Llegada del autocar: la calle, las bengalas y el bus entrando al estadio.
static func _autocar() -> String:
	var defs := """
<linearGradient id="au" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#0b1018"/><stop offset="1" stop-color="#171c22"/></linearGradient>
<radialGradient id="beng" cx="0.5" cy="0.5" r="0.5">
<stop offset="0" stop-color="#ff7a3d" stop-opacity=".65"/>
<stop offset="1" stop-color="#ff7a3d" stop-opacity="0"/></radialGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#au)"/>' % [W, H]
	## El humo naranja de las bengalas, detrás de todo.
	for i in 5:
		c += '<circle cx="%d" cy="%d" r="%d" fill="url(#beng)"/>' % [
			160 + i * 330, 330 + int(_r(i, 91) * 200.0), 190 + int(_r(i, 93) * 110.0)]
	## La multitud a los lados, en contraluz: solo siluetas.
	c += _gente(0, 470, 520, 200, 9, 101, ".45")
	c += _gente(1080, 470, 520, 200, 9, 103, ".45")
	## El autocar, de frente y bajo.
	c += '<rect x="520" y="330" width="560" height="330" rx="26" fill="#101a20"/>'
	c += '<rect x="548" y="360" width="504" height="150" rx="12" fill="#1b2c36" opacity=".9"/>'
	for i in 6:
		c += '<rect x="%d" y="372" width="66" height="126" rx="6" fill="#25404e" opacity=".85"/>' % (566 + i * 82)
	c += '<rect x="520" y="600" width="560" height="60" rx="8" fill="#0a1116"/>'
	c += '<circle cx="620" cy="672" r="46" fill="#080d11"/><circle cx="980" cy="672" r="46" fill="#080d11"/>'
	## Los faros: los dos únicos puntos verdaderamente claros de la escena.
	c += '<ellipse cx="576" cy="616" rx="34" ry="17" fill="#ffeec4" opacity=".85"/>'
	c += '<ellipse cx="1024" cy="616" rx="34" ry="17" fill="#ffeec4" opacity=".85"/>'
	c += '<path d="M576 616 L300 900 L860 900Z" fill="#ffeec4" opacity=".07"/>'
	c += '<path d="M1024 616 L740 900 L1300 900Z" fill="#ffeec4" opacity=".07"/>'
	c += '<rect x="0" y="820" width="%d" height="80" fill="#080c10"/>' % W
	return _marco(defs, c)

## Pizarra de tiza: la de verdad, la de vestuario, con el trazo sucio.
static func _tiza() -> String:
	var defs := """
<linearGradient id="tz" x1="0" y1="0" x2="1" y2="1">
<stop offset="0" stop-color="#1c2422"/><stop offset="1" stop-color="#0f1614"/></linearGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#tz)"/>' % [W, H]
	## Las manchas de borrar: lo que hace que una pizarra parezca usada.
	for i in 16:
		c += '<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="#ffffff" opacity=".022"/>' % [
			int(_r(i, 31) * float(W)), int(_r(i, 37) * float(H)),
			90 + int(_r(i, 39) * 150.0), 30 + int(_r(i, 41) * 60.0)]
	## Un esquema de jugada a mano alzada: círculos, cruces y flechas curvas.
	for i in 6:
		c += '<circle cx="%d" cy="%d" r="26" fill="none" stroke="#e8efe9" stroke-width="4" opacity=".3"/>' % [
			230 + i * 160, 300 + int(_r(i, 51) * 260.0)]
	for i in 5:
		var x := 1050 + int(_r(i, 53) * 400.0)
		var y := 250 + int(_r(i, 57) * 380.0)
		c += '<path d="M%d %d L%d %d M%d %d L%d %d" stroke="#e8a4a4" stroke-width="4" opacity=".3"/>' % [
			x - 20, y - 20, x + 20, y + 20, x + 20, y - 20, x - 20, y + 20]
	c += '<path d="M300 640 Q640 470 980 620" stroke="#c9a227" stroke-width="5" fill="none" opacity=".35" stroke-dasharray="20 14"/>'
	c += '<path d="M960 596 L992 622 L956 646" fill="none" stroke="#c9a227" stroke-width="5" opacity=".35"/>'
	## La bandeja de abajo, con la tiza.
	c += '<rect x="0" y="846" width="%d" height="54" fill="#26201a"/>' % W
	c += '<rect x="120" y="856" width="76" height="16" rx="8" fill="#e8efe9" opacity=".6"/>'
	c += '<rect x="230" y="858" width="52" height="14" rx="7" fill="#c9a227" opacity=".5"/>'
	return _marco(defs, c)

# --- los diez nuevos ---------------------------------------------------------
#
# Misma regla que los catorce de arriba: oscuros, poco saturados, con la viñeta
# encima. Lo que cambia es el SITIO —el juego ya no transcurre solo en un campo:
# hay una sala de juntas, un aeropuerto, un mapa de ojeadores y un vestuario, y
# el fondo puede decir en cuál de esos sitios te sientes.

## La ciudad al otro lado de la grada. Es el fondo de "club grande": el estadio
## no está en un descampado, está metido en una ciudad que lo mira.
static func _ciudad() -> String:
	var defs := """
<linearGradient id="ci" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#0a1018"/><stop offset="0.55" stop-color="#111c26"/>
<stop offset="1" stop-color="#0b1310"/></linearGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#ci)"/>' % [W, H]
	## Tres filas de torres, de más lejana a más cercana: la profundidad la da el
	## que las de atrás sean más claras y más bajas, no el tamaño.
	for capa in 3:
		var base := 470 + capa * 60
		var tono: String = ["#16222c", "#111a22", "#0c1319"][capa]
		var opac: String = ["22", "16", "10"][capa]
		var x := -40
		while x < W:
			var an := 46 + int(_r(capa * 7 + x, 11) * 70.0)
			var al := 90 + int(_r(capa * 13 + x, 17) * (140.0 + float(capa) * 90.0))
			c += '<rect x="%d" y="%d" width="%d" height="%d" fill="%s"/>' % [x, base - al, an, al + 200, tono]
			## Ventanas encendidas. No todas: una torre con todas las luces dadas
			## no parece un edificio, parece una rejilla.
			var col := 0
			while col * 14 + 8 < an:
				var f := 0
				while f * 18 + 14 < al:
					if _r(x + col * 3 + capa, f * 5 + 23) > 0.62:
						c += '<rect x="%d" y="%d" width="6" height="8" fill="#d9c48a" opacity=".%s"/>' % [
							x + 6 + col * 14, base - al + 10 + f * 18, opac]
					f += 1
				col += 1
			x += an + 10 + int(_r(x, capa) * 26.0)
	## Y delante, el borde de la grada con su gente: el estadio está AQUÍ, la
	## ciudad está allá.
	c += '<rect x="0" y="672" width="%d" height="%d" fill="#0d1512"/>' % [W, H - 672]
	c += _gente(0, 700, W, 130, 5, 411, ".22")
	c += _foco(250, 300, 0.8) + _foco(1330, 300, 0.8)
	return _marco(defs, c)

## Estadio de pueblo entre cerros. El fondo de empezar desde abajo: no hay focos,
## hay tarde, hay monte y hay una tribuna de tablones.
static func _montana() -> String:
	var defs := """
<linearGradient id="mo" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#20303a"/><stop offset="0.5" stop-color="#2a3a34"/>
<stop offset="1" stop-color="#16221c"/></linearGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#mo)"/>' % [W, H]
	for capa in 3:
		var y := 330 + capa * 70
		var tono: String = ["#1c2b2a", "#182320", "#131c18"][capa]
		var d := "M-20 %d" % (y + 120)
		var x := -20
		while x < W + 40:
			d += " L%d %d" % [x, y + int(_r(capa * 5, x / 90) * 150.0) - 40]
			x += 90
		d += " L%d %d L-20 %d Z" % [W + 40, H, H]
		c += '<path d="%s" fill="%s"/>' % [d, tono]
	## La tribuna: cuatro tablones y la gente escasa que cabe en ellos.
	c += '<rect x="120" y="640" width="620" height="150" fill="#2b2419" opacity=".8"/>'
	for f in 4:
		c += '<rect x="120" y="%d" width="620" height="8" fill="#3b3122" opacity=".9"/>' % (652 + f * 34)
	c += _gente(140, 646, 580, 120, 4, 733, ".3")
	c += '<rect x="0" y="790" width="%d" height="%d" fill="#1b2a1e"/>' % [W, H - 790]
	c += '<rect x="0" y="790" width="%d" height="4" fill="#e9eeea" opacity=".18"/>' % W
	return _marco(defs, c)

## Cancha de arena al atardecer. El fútbol de antes de que hubiera clubes.
static func _playa() -> String:
	var defs := """
<linearGradient id="pl" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#3a2a24"/><stop offset="0.42" stop-color="#6b4433"/>
<stop offset="0.58" stop-color="#2a2a30"/><stop offset="1" stop-color="#1a1a1e"/></linearGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#pl)"/>' % [W, H]
	c += '<circle cx="1120" cy="360" r="86" fill="#c98a4a" opacity=".5"/>'
	## El reflejo en el agua: bandas horizontales que se estrechan al alejarse.
	for i in 22:
		c += '<rect x="%d" y="%d" width="%d" height="3" fill="#c98a4a" opacity=".%02d"/>' % [
			1120 - 20 - int(_r(i, 3) * 70.0), 420 + i * 9,
			40 + int(_r(i, 7) * 90.0), maxi(2, 16 - i / 2)]
	c += '<rect x="0" y="620" width="%d" height="%d" fill="#241c16"/>' % [W, H - 620]
	## Dos porterías de palos clavados y la línea que alguien pisó en la arena.
	for px in [220, 1300]:
		c += '<rect x="%d" y="600" width="5" height="120" fill="#3a2e22"/>' % px
		c += '<rect x="%d" y="600" width="5" height="120" fill="#3a2e22"/>' % (px + 130)
		c += '<rect x="%d" y="598" width="139" height="5" fill="#3a2e22"/>' % px
	c += '<path d="M-20 700 Q800 660 1620 700" stroke="#c9b79a" stroke-width="3" fill="none" opacity=".2"/>'
	return _marco(defs, c)

## Partido bajo la nieve. Lo que hace la escena no es el blanco: es el vaho de
## los focos y que la gente de la grada se ve BORROSA, tapada.
static func _nieve() -> String:
	var defs := """
<linearGradient id="nv" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#1b2430"/><stop offset="1" stop-color="#0e1419"/></linearGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#nv)"/>' % [W, H]
	c += _foco(300, 180, 1.0) + _foco(1300, 180, 1.0)
	c += _gente(0, 320, W, 200, 6, 919, ".12")
	c += '<rect x="0" y="560" width="%d" height="%d" fill="#c9d4d8" opacity=".16"/>' % [W, H - 560]
	## Los copos quietos del dibujo. Los que se MUEVEN los pone la capa animada
	## de encima, que es otra cosa y se elige aparte.
	for i in 220:
		c += '<circle cx="%d" cy="%d" r="%d" fill="#ffffff" opacity=".%02d"/>' % [
			int(_r(i, 61) * float(W)), int(_r(i, 67) * float(H)),
			1 + int(_r(i, 71) * 3.0), 10 + int(_r(i, 73) * 22.0)]
	## Las líneas del campo tapadas a medias por la nieve: se ven a trozos.
	c += '<path d="M100 760 L1500 760" stroke="#ffffff" stroke-width="5" opacity=".2" stroke-dasharray="60 40"/>'
	return _marco(defs, c)

## La sala de juntas. El fondo de las pantallas de dinero: mesa larga, sillas
## vacías y la ciudad al fondo. Aquí no se juega, aquí se decide.
static func _juntas() -> String:
	var defs := """
<linearGradient id="jt" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#14181c"/><stop offset="1" stop-color="#0b0e10"/></linearGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#jt)"/>' % [W, H]
	## El ventanal.
	c += '<rect x="80" y="90" width="1440" height="380" fill="#101a22"/>'
	for i in 5:
		c += '<rect x="%d" y="90" width="6" height="380" fill="#0a0d10"/>' % (80 + i * 288)
	for i in 90:
		c += '<rect x="%d" y="%d" width="5" height="7" fill="#d9c48a" opacity=".13"/>' % [
			100 + int(_r(i, 81) * 1400.0), 300 + int(_r(i, 83) * 160.0)]
	## La mesa, en perspectiva de un punto.
	c += '<path d="M340 640 L1260 640 L1460 880 L140 880 Z" fill="#241d16"/>'
	c += '<path d="M340 640 L1260 640 L1250 656 L350 656 Z" fill="#33291e"/>'
	for i in 8:
		var x := 300 + i * 145
		c += '<rect x="%d" y="560" width="86" height="84" rx="8" fill="#171c1a"/>' % x
	## El vaso de agua y la carpeta que siempre hay.
	c += '<rect x="700" y="690" width="120" height="80" rx="4" fill="#2c2a24" opacity=".9"/>'
	c += '<circle cx="900" cy="712" r="14" fill="#3a4a4e" opacity=".8"/>'
	return _marco(defs, c)

## El mapa del ojeador: el mundo con las rutas de los viajes marcadas. Es el
## fondo de las pantallas de mercado y de la red de ojeadores.
static func _mapa() -> String:
	var defs := """
<linearGradient id="mp" x1="0" y1="0" x2="1" y2="1">
<stop offset="0" stop-color="#101a1e"/><stop offset="1" stop-color="#0a1214"/></linearGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#mp)"/>' % [W, H]
	## La retícula de meridianos y paralelos.
	for i in 20:
		c += '<line x1="%d" y1="0" x2="%d" y2="%d" stroke="#3f6f66" stroke-width="1" opacity=".12"/>' % [i * 84, i * 84, H]
	for i in 12:
		c += '<line x1="0" y1="%d" x2="%d" y2="%d" stroke="#3f6f66" stroke-width="1" opacity=".12"/>' % [i * 82, W, i * 82]
	## Masas de tierra sugeridas: nubes de puntos, no contornos. Un mapa exacto
	## detrás de una tabla se lee como ruido; una insinuación, no.
	for i in 900:
		var x := int(_r(i, 91) * float(W))
		var y := int(_r(i, 97) * float(H))
		## Un ruido suave decide dónde hay tierra: manchas grandes, no confeti.
		if _r(x / 60, y / 60) < 0.45:
			continue
		c += '<circle cx="%d" cy="%d" r="2" fill="#5f9c8a" opacity=".16"/>' % [x, y]
	## Las rutas: arcos entre puntos con su chincheta.
	var nodos := [Vector2i(280, 560), Vector2i(520, 300), Vector2i(880, 480), Vector2i(1180, 260), Vector2i(1380, 620)]
	for i in nodos.size() - 1:
		var a: Vector2i = nodos[i]
		var b: Vector2i = nodos[i + 1]
		c += '<path d="M%d %d Q%d %d %d %d" stroke="#c9a227" stroke-width="2" fill="none" opacity=".3" stroke-dasharray="10 8"/>' % [
			a.x, a.y, (a.x + b.x) / 2, mini(a.y, b.y) - 90, b.x, b.y]
	for n: Vector2i in nodos:
		c += '<circle cx="%d" cy="%d" r="6" fill="#c9a227" opacity=".55"/>' % [n.x, n.y]
		c += '<circle cx="%d" cy="%d" r="14" fill="none" stroke="#c9a227" stroke-width="2" opacity=".25"/>' % [n.x, n.y]
	return _marco(defs, c)

## El vestuario vacío: taquillas, un banco y las camisetas colgadas. El sitio
## donde se habla con el plantel.
static func _vestuario() -> String:
	var defs := """
<linearGradient id="vs" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#141a18"/><stop offset="1" stop-color="#0a0f0d"/></linearGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#vs)"/>' % [W, H]
	## Las taquillas: nueve huecos con su camiseta y su número.
	for i in 9:
		var x := 90 + i * 158
		c += '<rect x="%d" y="200" width="138" height="440" rx="6" fill="#1b2320"/>' % x
		c += '<rect x="%d" y="208" width="122" height="330" fill="#0e1412"/>' % (x + 8)
		## La camiseta colgada: dos hombros y un cuerpo, que es todo lo que hace
		## falta para que se lea como una camiseta.
		var col: String = ["#2f4a58", "#4a2f34", "#2f4a3a", "#4a4430"][i % 4]
		c += '<path d="M%d 250 L%d 236 L%d 236 L%d 250 L%d 268 L%d 262 L%d 400 L%d 400 L%d 262 L%d 268 Z" fill="%s" opacity=".55"/>' % [
			x + 34, x + 54, x + 84, x + 104, x + 116, x + 100, x + 100, x + 38, x + 38, x + 22, col]
		c += '<rect x="%d" y="560" width="122" height="70" fill="#151b19"/>' % (x + 8)
	## El banco corrido de delante.
	c += '<rect x="40" y="700" width="%d" height="26" rx="6" fill="#33291e"/>' % (W - 80)
	for i in 6:
		c += '<rect x="%d" y="726" width="16" height="90" fill="#1d1712"/>' % (120 + i * 260)
	c += '<rect x="0" y="816" width="%d" height="%d" fill="#0f1412"/>' % [W, H - 816]
	return _marco(defs, c)

## Bufandas al viento. El fondo del hincha: sin campo, sin jugadores, solo la
## grada haciendo lo suyo antes de que empiece.
static func _bufandas() -> String:
	var defs := """
<linearGradient id="bf" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#161d24"/><stop offset="1" stop-color="#0b1014"/></linearGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#bf)"/>' % [W, H]
	c += _gente(0, 120, W, 700, 16, 1301, ".14")
	## Las bufandas en alto: rectángulos girados y con dos franjas, que es lo que
	## las hace bufandas y no trapos.
	for i in 34:
		var x := int(_r(i, 101) * float(W))
		var y := 180 + int(_r(i, 103) * 560.0)
		var an := 70 + int(_r(i, 107) * 60.0)
		var giro := int(_r(i, 109) * 60.0) - 30
		var col: String = ["#b4472f", "#2f5fb4", "#c9a227", "#2f9c6a", "#e6e1d6"][i % 5]
		c += '<g transform="translate(%d %d) rotate(%d)">' % [x, y, giro]
		c += '<rect x="0" y="0" width="%d" height="20" rx="3" fill="%s" opacity=".42"/>' % [an, col]
		c += '<rect x="0" y="7" width="%d" height="6" fill="#0d1210" opacity=".3"/>' % an
		c += '</g>'
	return _marco(defs, c)

## La portada del diario del día siguiente. El fondo de las pantallas de prensa:
## columnas de texto insinuadas, una foto grande y el hueco del titular.
static func _diario() -> String:
	var defs := """
<linearGradient id="dr" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#2a2721"/><stop offset="1" stop-color="#191712"/></linearGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#dr)"/>' % [W, H]
	c += '<rect x="90" y="60" width="1420" height="800" fill="#d9d2c2" opacity=".13"/>'
	## La cabecera y el filete doble de debajo.
	c += '<rect x="130" y="100" width="700" height="46" fill="#e6e1d6" opacity=".2"/>'
	c += '<rect x="130" y="168" width="1340" height="4" fill="#e6e1d6" opacity=".18"/>'
	c += '<rect x="130" y="176" width="1340" height="2" fill="#e6e1d6" opacity=".12"/>'
	## La foto: un recuadro con la silueta de una celebración.
	c += '<rect x="130" y="210" width="620" height="380" fill="#0f1512" opacity=".5"/>'
	for i in 5:
		c += '<circle cx="%d" cy="%d" r="34" fill="#8ea595" opacity=".18"/>' % [220 + i * 120, 420 + int(_r(i, 111) * 60.0)]
		c += '<rect x="%d" y="456" width="46" height="130" rx="18" fill="#8ea595" opacity=".18"/>' % (197 + i * 120)
	## Las columnas de texto: renglones de largo irregular, que es lo que hace
	## que se lean como texto y no como un peine.
	for col in 3:
		var x := 790 + col * 235
		for f in 26:
			var an := 120 + int(_r(col * 17 + f, 113) * 90.0)
			c += '<rect x="%d" y="%d" width="%d" height="6" fill="#e6e1d6" opacity=".10"/>' % [x, 220 + f * 24, an]
	for f in 8:
		var an2 := 380 + int(_r(f, 117) * 220.0)
		c += '<rect x="130" y="%d" width="%d" height="7" fill="#e6e1d6" opacity=".10"/>' % [630 + f * 26, an2]
	return _marco(defs, c)

## El aeropuerto de madrugada. Es el fondo del mercado: la gira, el fichaje que
## llega en un vuelo raro y el ojeador que siempre está volviendo de algún sitio.
static func _aeropuerto() -> String:
	var defs := """
<linearGradient id="ae" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#0e1420"/><stop offset="0.6" stop-color="#131c26"/>
<stop offset="1" stop-color="#0a0f14"/></linearGradient>"""
	var c := '<rect width="%d" height="%d" fill="url(#ae)"/>' % [W, H]
	## El ventanal curvo de la terminal.
	c += '<path d="M0 520 Q800 300 1600 520 L1600 0 L0 0 Z" fill="#0c1219" opacity=".7"/>'
	for i in 16:
		var x := i * 100
		c += '<line x1="%d" y1="0" x2="%d" y2="%d" stroke="#2a3a44" stroke-width="2" opacity=".3"/>' % [
			x, x, 520 - int(220.0 * (1.0 - absf(float(x) / 800.0 - 1.0)))]
	## La pista: luces de balizamiento perdiéndose al fondo.
	for i in 24:
		var t := float(i) / 24.0
		c += '<circle cx="%d" cy="%d" r="%d" fill="#e0a83a" opacity=".%02d"/>' % [
			int(800.0 - (1.0 - t) * 760.0), int(560.0 + (1.0 - t) * 260.0),
			2 + int((1.0 - t) * 4.0), 12 + int(t * 26.0)]
		c += '<circle cx="%d" cy="%d" r="%d" fill="#e0a83a" opacity=".%02d"/>' % [
			int(800.0 + (1.0 - t) * 760.0), int(560.0 + (1.0 - t) * 260.0),
			2 + int((1.0 - t) * 4.0), 12 + int(t * 26.0)]
	## El avión: cuerpo, cola y ala, de perfil y lejos.
	c += '<path d="M1020 470 L1300 470 Q1350 470 1360 486 L1020 486 Z" fill="#1e2a30" opacity=".9"/>'
	c += '<path d="M1030 470 L1060 424 L1084 424 L1070 470 Z" fill="#1e2a30" opacity=".9"/>'
	c += '<path d="M1140 486 L1200 520 L1230 520 L1190 486 Z" fill="#182228" opacity=".9"/>'
	for i in 9:
		c += '<circle cx="%d" cy="477" r="3" fill="#d9c48a" opacity=".22"/>' % (1090 + i * 26)
	## Los paneles de vuelos, abajo a la izquierda.
	c += '<rect x="90" y="600" width="420" height="180" rx="6" fill="#0a1014" opacity=".9"/>'
	for f in 6:
		c += '<rect x="106" y="%d" width="%d" height="8" fill="#4ac98a" opacity=".22"/>' % [
			616 + f * 27, 120 + int(_r(f, 121) * 240.0)]
	return _marco(defs, c)
