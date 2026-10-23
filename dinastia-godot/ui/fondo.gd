class_name Fondo
extends "res://ui/fondo_p1.gd"
## (Parte 2 de 2 de `fondo.gd`.)

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
