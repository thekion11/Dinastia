class_name PaisTrazo
extends RefCounted
## EL LÁPIZ DE LOS MONUMENTOS de la pantalla de país: unas pocas primitivas (polígono,
## rectángulo, disco, cúpula, arcada, línea) en unas coordenadas pensadas para dibujar
## siluetas a mano sin hacer cuentas de píxeles.
##
## LAS COORDENADAS: todo se mide en ALTURAS del monumento, con el origen en el centro de
## su base y la Y hacia ARRIBA. (0, 1) es la punta de un monumento que llena su alto;
## (-0.3, 0) es el suelo a 0,3 alturas a la izquierda. Así cada silueta se escribe una vez
## y se dibuja a cualquier tamaño sin deformarse.
##
## EL BORDE SUAVE: `draw_colored_polygon` no tiene antialias, y una silueta grande con
## bordes de sierra se nota mucho a 1080p. Cada polígono se repasa con una polilínea de
## 1 px CON antialias del mismo color: es el truco barato que deja el borde limpio.
##
## Las capas de dibujos (`PaisDibujoObras`, `PaisDibujoEdificios`, `PaisDibujoPaisaje`)
## usan estas primitivas; `dibujar()` reparte por tipo.

static var ci: CanvasItem
static var base := Vector2.ZERO
static var alto := 100.0
static var col := Color.BLACK   ## la silueta
static var det := Color.WHITE   ## los detalles (ventanas, nieve, agua): un tono más claro
## Modo prueba: cuenta los polígonos que no se pueden triangular (Godot no los pinta y
## solo avisa por consola) y guarda la caja que ocupa el dibujo, para comprobar que
## cada silueta cabe en su hueco.
static var validar := false
static var malos := 0
static var caja := Rect2()
static var _caja_vacia := true
static var _girado := false

## Empieza a medir de cero (modo prueba).
static func reiniciar_medida() -> void:
	malos = 0
	caja = Rect2()
	_caja_vacia = true

## Cuántas alturas de ancho ocupa cada tipo (para encajarlo en su hueco sin salirse).
const ANCHO := {
	"obelisco": 0.4, "torre_reloj": 0.5, "celosia": 0.75, "estatua": 0.75, "moai": 1.5,
	"piramide": 2.5, "piramide_escalonada": 2.0, "columnas": 1.8, "arco": 1.4, "coliseo": 2.2,
	"torre_inclinada": 0.6, "pagoda": 1.4, "rascacielos": 0.8, "torre_tv": 0.5, "cupula": 1.9,
	"castillo": 1.6, "muralla": 2.6, "faro": 0.8, "noria": 1.1, "molino": 2.2, "mano": 1.3,
	"piedras": 2.4, "acueducto": 2.6, "opera": 2.4, "mitad_mundo": 0.6, "teleferico": 2.4,
	"agujas": 1.1, "esfinge": 2.4, "puente": 2.8, "presa": 2.8, "ruinas": 2.2, "platillo": 1.8,
	"montana": 2.4, "catarata": 2.2, "dunas": 2.8, "farallones": 2.6, "palmeras": 1.8,
}

## Las variantes que se salen de lo normal de su tipo (el Congreso de Brasilia es
## ancho, no una torre).
const ANCHO_VARIANTE := {"rascacielos/congreso": 1.7}

static func ancho_de(tipo: String, variante := "") -> float:
	return float(ANCHO_VARIANTE.get(tipo + "/" + variante, ANCHO.get(tipo, 1.5)))

## Dibuja un monumento entero. Devuelve false si el tipo no existe (la pantalla no se
## rompe: simplemente no hay silueta).
static func dibujar(lienzo: CanvasItem, tipo: String, variante: String, pie: Vector2, h: float,
		c_silueta: Color, c_detalle: Color) -> bool:
	ci = lienzo
	base = pie
	alto = h
	col = c_silueta
	det = c_detalle
	if PaisDibujoObras.dibujar(tipo, variante):
		return true
	if PaisDibujoEdificios.dibujar(tipo, variante):
		return true
	return PaisDibujoPaisaje.dibujar(tipo, variante)

## De coordenadas de monumento a píxeles.
static func px(x: float, y: float) -> Vector2:
	return base + Vector2(x * alto, -y * alto)

## Un polígono dado como lista plana x0, y0, x1, y1… (en alturas).
static func pol(xy: Array, detalle := false) -> void:
	var p := PackedVector2Array()
	for i in range(0, xy.size() - 1, 2):
		p.append(px(float(xy[i]), float(xy[i + 1])))
	poligono(p, detalle)

## Un polígono ya en píxeles, con el borde antialias.
static func poligono(p: PackedVector2Array, detalle := false) -> void:
	if p.size() < 3:
		return
	if validar:
		if Geometry2D.triangulate_polygon(p).is_empty():
			malos += 1
		## Lo girado va en coordenadas locales: no cuenta para la caja.
		for q: Vector2 in p if not _girado else PackedVector2Array():
			if _caja_vacia:
				caja = Rect2(q, Vector2.ZERO)
				_caja_vacia = false
			else:
				caja = caja.expand(q)
	var c := det if detalle else col
	ci.draw_colored_polygon(p, c)
	var cerrado := p.duplicate()
	cerrado.append(p[0])
	ci.draw_polyline(cerrado, c, 1.0, true)

static func rect(x0: float, y0: float, x1: float, y1: float, detalle := false) -> void:
	pol([x0, y0, x1, y0, x1, y1, x0, y1], detalle)

static func disco(x: float, y: float, r: float, detalle := false) -> void:
	elipse(x, y, r, r, 0.0, TAU, detalle)

## Un sector de elipse relleno (de `a0` a `a1`, en radianes, 0 = derecha, sube en
## sentido antihorario como en matemáticas). Media elipse de 0 a PI = una cúpula.
static func elipse(cx: float, cy: float, rx: float, ry: float, a0: float, a1: float, detalle := false) -> void:
	var p := PackedVector2Array()
	var n := maxi(10, int(absf(a1 - a0) * 12.0))
	var completo := absf(a1 - a0) >= TAU - 0.001
	if not completo:
		p.append(px(cx, cy))
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		p.append(px(cx + cos(a) * rx, cy + sin(a) * ry))
	if completo:
		p.remove_at(p.size() - 1)
	poligono(p, detalle)

## Una cúpula: media elipse apoyada en `y0`.
static func cupula(cx: float, y0: float, rx: float, ry: float, detalle := false) -> void:
	elipse(cx, y0, rx, ry, 0.0, PI, detalle)

## Lo macizo de una arcada: el muro entre `x0` y `x1`, de `y0` a `y1`, con `n` arcos de
## medio punto abiertos que arrancan a la altura `y_arranque`. Se dibujan los machones
## y las enjutas (lo que queda entre arco y arco) por separado: así el hueco del arco
## se ve de verdad, transparente, y no hay que «pintarlo» del color del cielo.
static func arcada(x0: float, x1: float, y0: float, y1: float, n: int, y_arranque: float,
		machon: float, detalle := false) -> void:
	var paso := (x1 - x0) / n
	var r := (paso - machon) * 0.5
	var y_clave := minf(y_arranque + r, y1)
	for i in n + 1:
		var xm := x0 + paso * i
		rect(maxf(x0, xm - machon * 0.5), y0, minf(x1, xm + machon * 0.5), y_arranque, detalle)
	if y1 > y_clave + 0.0001:
		rect(x0, y_clave, x1, y1, detalle)
	for i in n:
		var cx := x0 + paso * (i + 0.5)
		## La enjuta: del arranque a la clave, por fuera del medio círculo.
		var izq := PackedVector2Array()
		izq.append(px(cx - paso * 0.5, y_arranque))
		## La Y se recorta a la clave: si el muro es más bajo que el arco, el arco
		## queda rebajado en vez de salirse (y romper el polígono).
		for k in 9:
			var a := PI - PI * 0.5 * float(k) / 8.0
			izq.append(px(cx + cos(a) * r, minf(y_arranque + sin(a) * r, y_clave)))
		izq.append(px(cx - paso * 0.5, y_clave))
		poligono(izq, detalle)
		var der := PackedVector2Array()
		der.append(px(cx + paso * 0.5, y_arranque))
		der.append(px(cx + paso * 0.5, y_clave))
		for k in 9:
			var a := PI * 0.5 - PI * 0.5 * float(k) / 8.0
			der.append(px(cx + cos(a) * r, minf(y_arranque + sin(a) * r, y_clave)))
		poligono(der, detalle)

## Una línea con grosor en alturas (cables, tirantes, mástiles).
static func linea(x0: float, y0: float, x1: float, y1: float, grosor: float, detalle := false) -> void:
	ci.draw_line(px(x0, y0), px(x1, y1), det if detalle else col, maxf(1.0, grosor * alto), true)

## Una curva por puntos (lista plana como en `pol`), abierta.
static func trazo(xy: Array, grosor: float, detalle := false) -> void:
	var p := PackedVector2Array()
	for i in range(0, xy.size() - 1, 2):
		p.append(px(float(xy[i]), float(xy[i + 1])))
	ci.draw_polyline(p, det if detalle else col, maxf(1.0, grosor * alto), true)

## Un perfil de montaña: los puntos de la cresta de izquierda a derecha, y se cierra
## por abajo en el suelo.
static func cresta(xy: Array, detalle := false) -> void:
	var cerrado := xy.duplicate()
	cerrado.append_array([float(xy[xy.size() - 2]), 0.0, float(xy[0]), 0.0])
	pol(cerrado, detalle)

## Dibujos girados (la torre de Pisa, las aspas de un molino, los dedos de la Mano):
## se mueve el origen al punto (x, y) y se gira `grados`; `fin_giro()` lo deshace.
static func girar(x: float, y: float, grados: float) -> void:
	var c := px(x, y)
	ci.draw_set_transform(c, deg_to_rad(-grados), Vector2.ONE)
	base = Vector2.ZERO
	_girado = true

static func fin_giro(pie: Vector2) -> void:
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	base = pie
	_girado = false
