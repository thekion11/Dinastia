class_name InteriorComercioExtra
extends RefCounted
## Género de más para los interiores de comercio de calle (supermercado y
## farmacia): productos sobre las góndolas, en carros y cestas, y la cruz
## verde de la farmacia. Sin azar: no toca el `_rng` del interior.

const GENERO := ["comida/soda-can", "comida/carton-small", "comida/bag", "comida/soda-bottle", "comida/bread", "comida/apple", "comida/cheese", "comida/bottle-oil"]
const MEDICINA := ["comida/carton-small", "comida/bag-flat", "comida/candy-bar-wrapper", "comida/carton-small", "comida/cup"]

## Una hilera de productos sobre el tablero de una góndola (largo en X).
static func hilera(ins: Node, p: Vector3, largo: float, lista: Array, desfase: int = 0) -> void:
	var n := maxi(3, int(largo / 0.32))
	for i in n:
		ins.call("_poner", lista[(i + desfase) % lista.size()], p + Vector3(-largo * 0.5 + (float(i) + 0.5) * largo / float(n), 0, 0), 0.4 * float(i))

## Cada carro y cesta con algo dentro.
static func carros(ins: Node, puntos: Array[Vector3]) -> void:
	var h := float(ins.call("_alto", "mini_mercado/shopping-cart"))
	for k in puntos.size():
		var p := puntos[k]
		ins.call("_poner", GENERO[(k + 1) % GENERO.size()], p + Vector3(0, h * 0.62, 0), 0.5 * float(k))
		ins.call("_poner", GENERO[(k + 4) % GENERO.size()], p + Vector3(0.12, h * 0.62, 0.2), 1.0 + float(k))

static func cestas(ins: Node, p: Vector3, n: int) -> void:
	for k in n:
		ins.call("_poner", GENERO[(k + 2) % GENERO.size()], p + Vector3(0.02, float(k) * 0.12 + 0.2, 0), 0.7 * float(k))

## Góndolas del supermercado: género encima de las tres filas.
static func supermercado(ins: Node) -> void:
	var alto := float(ins.call("_alto", "mini_mercado/shelf-boxes"))
	var ancho := float((ins.call("_medida", "mini_mercado/shelf-boxes") as Vector3).x)
	for j in 3:
		var z: float = [-4.6, -1.6, 1.2][j]
		hilera(ins, Vector3(-6.9 + ancho * 1.0, alto, z), ancho * 3.0 - 0.3, GENERO, j * 2)
	var cart: Array[Vector3] = []
	for k in 4:
		cart.append(Vector3(-6.2 - float(k) * 0.12, 0, 5.4))
	carros(ins, cart)
	cestas(ins, Vector3(-4.0, 0, 5.6), 3)
	## Bolsas de la compra junto a las cajas.
	for x: float in [3.2, 6.4]:
		ins.call("_poner", "comida/bag", Vector3(x + 0.45, 1.0, 2.0), 0.3)

## Farmacia/tienda de calle: medicinas sobre las góndolas y cruz verde.
static func tienda_calle(ins: Node) -> void:
	var alto := float(ins.call("_alto", "mini_mercado/shelf-boxes"))
	var ancho := float((ins.call("_medida", "mini_mercado/shelf-boxes") as Vector3).x)
	var lista: Array = MEDICINA if String(ins.get("clave")).contains("armacia") or String(ins.call("_sala_nombre")).to_lower().contains("farmacia") else GENERO
	for j in 2:
		var z: float = [-2.9, 0.0][j]
		hilera(ins, Vector3(-5.0 + ancho * 1.0, alto, z), ancho * 3.0 - 0.3, lista, j)
	cestas(ins, Vector3(2.6, 0, 4.3), 3)
	if lista == MEDICINA:
		var verde := Color(0.1, 0.7, 0.35)
		Mini3D.caja(ins.get("_raiz"), Vector3(0, 2.55, -4.9), Vector3(0.9, 0.26, 0.05), Mini3D.mat(verde, 0.6))
		Mini3D.caja(ins.get("_raiz"), Vector3(0, 2.55, -4.9), Vector3(0.26, 0.9, 0.05), Mini3D.mat(verde, 0.6))
