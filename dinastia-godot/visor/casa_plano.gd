class_name CasaPlano
extends RefCounted
## EL PLANO DE LA CASA DEL PERSONAJE, SIN CIUDAD (10-11, orden 33 «solo club»). La casa más básica, vista desde arriba:
## x hacia el este, z hacia el sur, metros. Solo datos y geometría 2D (nada de nodos): lo usa `CasaConstruccion` para
## levantarla en 3D, `CasaRecorrido` para caminarla y el banco para comprobar que ninguna habitación queda aislada.
## La colisión es la de siempre en 2D: un círculo (el cuerpo) contra cajas (paredes y muebles), deslizando por los lados.

const ANCHO := 11.0
const FONDO := 9.6
const ALTO := 2.7
const GROSOR := 0.16
const RADIO := 0.32          ## el cuerpo
const INICIO := Vector2(1.6, 2.4)
const RUMBO_INICIO := PI / 2.0   ## mira al este: la puerta de la calle queda a la espalda
const PUERTA_CALLE := Vector2(0.1, 2.4)   ## la puerta de la calle (pared oeste): con E se sale

## nombre, x0, z0, x1, z1, color del suelo
const SALAS := [
	["Sala", 0.0, 0.0, 6.0, 4.8, "b08a5e"],
	["Cocina", 6.0, 0.0, 11.0, 4.8, "cfd3d6"],
	["Pasillo", 0.0, 4.8, 11.0, 6.2, "d9cdb8"],
	["Dormitorio", 0.0, 6.2, 5.0, 9.6, "8f8a99"],
	["Baño", 5.0, 6.2, 8.0, 9.6, "bcd3dc"],
	["Estudio", 8.0, 6.2, 11.0, 9.6, "6e5a47"],
]

## Cada pared: eje ("h" = a lo largo de x, "v" = a lo largo de z), posición del eje, desde, hasta y los huecos de puerta.
const LINEAS := [
	["h", 0.0, 0.0, 11.0, []], ["h", 9.6, 0.0, 11.0, []], ["v", 0.0, 0.0, 9.6, []], ["v", 11.0, 0.0, 9.6, []],
	["h", 4.8, 0.0, 11.0, [[2.5, 3.5], [8.0, 9.0]]],
	["h", 6.2, 0.0, 11.0, [[3.5, 4.5], [6.0, 7.0], [9.0, 10.0]]],
	["v", 6.0, 0.0, 4.8, [[1.2, 3.4]]],
	["v", 5.0, 6.2, 9.6, []], ["v", 8.0, 6.2, 9.6, []],
]

## Las ventanas: lado, posición a lo largo de la pared, ancho, alto desde el suelo, alto de la ventana.
const VENTANAS := [
	["n", 1.8, 1.4, 1.1, 1.0], ["n", 8.34, 1.2, 1.25, 0.9], ["e", 2.4, 1.3, 1.1, 1.0], ["e", 8.0, 1.2, 1.1, 1.0],
	["s", 1.7, 1.2, 1.35, 0.8], ["s", 6.5, 0.9, 1.5, 0.7], ["o", 7.4, 0.9, 1.1, 1.0],
]

## Los muebles: pieza (kit «muebles» de Kenney, ver `Modulos`), x, z, giro (hacia dónde mira su frente; 0 = al sur), alto
## sobre el suelo y si es sólido. Los muebles de Kenney tienen el respaldo en -Z.
const MUEBLES := [
	## Sala
	["cabinetTelevision", 4.5, 0.33, 0.0, 0.0, true], ["televisionModern", 4.5, 0.33, 0.0, 0.62, false],
	["loungeSofa", 4.5, 3.7, PI, 0.0, true], ["tableCoffee", 4.3, 2.1, 0.0, 0.0, true],
	["rugRectangle", 4.5, 2.3, 0.0, 0.01, false], ["loungeChair", 0.55, 1.2, PI / 2.0, 0.0, true],
	["bookcaseOpen", 0.33, 3.3, PI / 2.0, 0.0, true], ["lampRoundFloor", 0.3, 0.3, 0.0, 0.0, true],
	["pottedPlant", 5.6, 0.35, 0.0, 0.0, true], ["pottedPlant", 0.4, 4.4, 0.0, 0.0, true],
	["rugDoormat", 0.85, 2.4, PI / 2.0, 0.01, false],
	## Cocina
	["kitchenFridge", 6.58, 0.37, 0.0, 0.0, true], ["kitchenCabinetDrawer", 7.46, 0.53, 0.0, 0.0, true],
	["kitchenStove", 8.34, 0.53, 0.0, 0.0, true], ["kitchenSink", 9.22, 0.53, 0.0, 0.0, true],
	["kitchenCabinet", 10.1, 0.53, 0.0, 0.0, true], ["kitchenCoffeeMachine", 10.1, 0.5, 0.0, 0.9, false],
	["table", 8.6, 2.9, 0.0, 0.0, true], ["chair", 7.95, 2.2, 0.0, 0.0, true], ["chair", 9.25, 2.2, 0.0, 0.0, true],
	["chair", 7.95, 3.6, PI, 0.0, true], ["chair", 9.25, 3.6, PI, 0.0, true],
	["washer", 10.5, 4.3, -PI / 2.0, 0.0, true], ["trashcan", 10.6, 3.3, 0.0, 0.0, true],
	["pottedPlant", 10.6, 1.6, 0.0, 0.0, true],
	## Pasillo
	["coatRackStanding", 0.5, 5.5, 0.0, 0.0, true], ["sideTable", 5.2, 5.1, 0.0, 0.0, true],
	["lampRoundTable", 5.0, 5.1, 0.0, 0.77, false], ["pottedPlant", 10.5, 5.5, 0.0, 0.0, true],
	## Dormitorio
	["bedDouble", 1.7, 8.395, PI, 0.0, true], ["cabinetBedDrawer", 0.45, 9.3, PI, 0.0, true],
	["cabinetBedDrawer", 2.95, 9.3, PI, 0.0, true], ["lampRoundTable", 0.45, 9.3, 0.0, 0.53, false],
	["lampRoundTable", 2.95, 9.3, 0.0, 0.53, false], ["bookcaseClosedDoors", 4.67, 7.6, -PI / 2.0, 0.0, true],
	["bookcaseClosedDoors", 4.67, 8.5, -PI / 2.0, 0.0, true], ["rugRectangle", 1.7, 7.4, 0.0, 0.01, false],
	["lampSquareFloor", 0.3, 6.5, 0.0, 0.0, true], ["pottedPlant", 4.5, 9.25, 0.0, 0.0, true],
	## Baño
	["bathtub", 6.45, 8.96, PI, 0.0, true], ["toilet", 7.44, 7.4, -PI / 2.0, 0.0, true],
	["bathroomSink", 5.37, 7.0, PI / 2.0, 0.0, true],
	## Estudio
	["desk", 10.53, 8.0, -PI / 2.0, 0.0, true], ["chairDesk", 9.8, 8.0, PI / 2.0, 0.0, true],
	["computerScreen", 10.62, 8.0, -PI / 2.0, 0.77, false], ["bookcaseClosedWide", 9.5, 9.27, PI, 0.0, true],
	["loungeChair", 8.6, 7.0, PI / 2.0, 0.0, true], ["pottedPlant", 8.4, 9.2, 0.0, 0.0, true],
]

static var _cache_obst: Array = []
static var _cache_muebles: Array = []

## Las paredes como cajas vistas desde arriba (x, z, ancho, fondo).
static func paredes() -> Array[Rect2]:
	var sal: Array[Rect2] = []
	var g := GROSOR
	for l: Array in LINEAS:
		var horizontal := String(l[0]) == "h"
		var eje := float(l[1])
		var tramos: Array = []
		var cursor := float(l[2])
		for h: Array in l[4]:
			tramos.append([cursor, float(h[0])])
			cursor = float(h[1])
		tramos.append([cursor, float(l[3])])
		for t: Array in tramos:
			var a := float(t[0]) - (g / 2.0 if is_equal_approx(float(t[0]), float(l[2])) else 0.0)
			var b := float(t[1]) + (g / 2.0 if is_equal_approx(float(t[1]), float(l[3])) else 0.0)
			if horizontal:
				sal.append(Rect2(a, eje - g / 2.0, b - a, g))
			else:
				sal.append(Rect2(eje - g / 2.0, a, g, b - a))
	return sal

## Los huecos de puerta como [eje, posición del eje, desde, hasta] (para dinteles y marcos).
static func huecos() -> Array:
	var sal: Array = []
	for l: Array in LINEAS:
		for h: Array in l[4]:
			sal.append([String(l[0]), float(l[1]), float(h[0]), float(h[1])])
	return sal

## La huella de cada mueble sólido: {rect, pieza}. Usa el tamaño real del modelo (`Modulos`), a escala de juego.
static func huellas_muebles() -> Array:
	if not _cache_muebles.is_empty():
		return _cache_muebles
	for m: Array in MUEBLES:
		if not bool(m[5]):
			continue
		var caja: AABB = Modulos.datos(String(m[0]))["caja"]
		var tam := Vector2(caja.size.x, caja.size.z) * Modulos.escala(String(m[0])).x
		if absf(sin(float(m[3]))) > 0.7:
			tam = Vector2(tam.y, tam.x)
		_cache_muebles.append({"rect": Rect2(Vector2(float(m[1]), float(m[2])) - tam / 2.0, tam), "pieza": String(m[0])})
	return _cache_muebles

## Todo lo que choca: paredes y muebles sólidos.
static func obstaculos() -> Array[Rect2]:
	if _cache_obst.is_empty():
		for r in paredes():
			_cache_obst.append(r)
		for h: Dictionary in huellas_muebles():
			_cache_obst.append(h["rect"])
	var sal: Array[Rect2] = []
	sal.assign(_cache_obst)
	return sal

static func vaciar_cache() -> void:
	_cache_obst = []
	_cache_muebles = []

## ¿Un círculo de radio `r` en `p` está libre de obstáculos y dentro de la casa?
static func libre(p: Vector2, obst: Array, r: float = RADIO) -> bool:
	if p.x < r or p.y < r or p.x > ANCHO - r or p.y > FONDO - r:
		return false
	for o: Rect2 in obst:
		var c := Vector2(clampf(p.x, o.position.x, o.end.x), clampf(p.y, o.position.y, o.end.y))
		if (p - c).length_squared() < r * r:
			return false
	return true

## Mueve el cuerpo de `desde` a `hasta` sin atravesar nada: en pasos cortos, y si el paso entero no cabe prueba cada eje por
## separado (así se desliza por las paredes en vez de quedarse pegado).
static func mover(desde: Vector2, hasta: Vector2, obst: Array, r: float = RADIO) -> Vector2:
	var total := hasta - desde
	var pasos := maxi(1, ceili(total.length() / 0.08))
	var p := desde
	var d := total / float(pasos)
	for _i in pasos:
		if libre(p + d, obst, r):
			p += d
		elif libre(p + Vector2(d.x, 0.0), obst, r):
			p += Vector2(d.x, 0.0)
		elif libre(p + Vector2(0.0, d.y), obst, r):
			p += Vector2(0.0, d.y)
		else:
			break
	return p

## Hasta qué distancia (como mucho `maxima`) se puede poner la cámara detrás de `p`, en la dirección `dir`, sin meterla en una pared.
static func distancia_camara(p: Vector2, dir: Vector2, maxima: float, obst: Array) -> float:
	var d := 0.0
	while d < maxima:
		if not libre(p + dir * (d + 0.1), obst, 0.18):
			break
		d += 0.1
	return d

## El nombre de la habitación en la que se está ("" si ninguna).
static func sala_en(p: Vector2) -> String:
	for s: Array in SALAS:
		if p.x >= float(s[1]) and p.x < float(s[3]) and p.y >= float(s[2]) and p.y < float(s[4]):
			return String(s[0])
	return ""

## Centro de una habitación.
static func centro_de(nombre: String) -> Vector2:
	for s: Array in SALAS:
		if String(s[0]) == nombre:
			return Vector2((float(s[1]) + float(s[3])) / 2.0, (float(s[2]) + float(s[4])) / 2.0)
	return INICIO

## Las celdas (de `celda` metros) a las que se llega caminando desde `desde`. Sirve para comprobar que ninguna habitación queda aislada.
static func alcanzables(desde: Vector2, celda: float = 0.2) -> Dictionary:
	var obst := obstaculos()
	var vistos := {}
	var cola: Array[Vector2i] = [Vector2i(roundi(desde.x / celda), roundi(desde.y / celda))]
	vistos[cola[0]] = true
	var i := 0
	while i < cola.size():
		var c := cola[i]
		i += 1
		for v: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n := c + v
			if vistos.has(n) or not libre(Vector2(n) * celda, obst):
				continue
			vistos[n] = true
			cola.append(n)
	return vistos

static func celda_de(p: Vector2, celda: float = 0.2) -> Vector2i:
	return Vector2i(roundi(p.x / celda), roundi(p.y / celda))
