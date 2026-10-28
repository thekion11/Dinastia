extends "res://ui/componentes/interior_instalacion_p6.gd"
## [Capa extra de `interior_instalacion.gd`, 27-10-2026, M-186] Salas propias de los comercios que antes abrían una tienda u oficina genérica:
## farmacia, banco, hotel (el vestíbulo), ferretería y floristería. Cada una con muebles del catálogo común y su gente.

const _BATA := [Color(0.95, 0.95, 0.96), Color(0.25, 0.3, 0.4), true]
const _TRAJE := [Color(0.18, 0.2, 0.3), Color(0.14, 0.15, 0.2), true]

## Farmacia (12 × 8 m): estanterías de medicinas al fondo, el mostrador con el farmacéutico, la cruz verde y dos sillas de espera.
func _farmacia() -> void:
	_tonos_sala = _MADERA_CLARA
	_sala(Vector3(12, 3.2, 8), Color(0.9, 0.92, 0.9), Color(0.96, 0.97, 0.96), "losa", Color(0.25, 0.65, 0.4))
	for k in 4:
		var x := -4.5 + float(k) * 3.0
		_poner("bookcaseClosedWide", Vector3(x, 0, -3.75), 0.0)
		for j in 3:
			_poner("comida/can-small", Vector3(x - 0.5 + float(j) * 0.5, 1.15, -3.75), 0.0, 0.8)
			_poner("comida/carton-small", Vector3(x - 0.45 + float(j) * 0.45, 0.62, -3.75), 0.0, 0.8)
	_poner("desk", Vector3(0.5, 0, -1.2), 0.0, 1.6)
	_poner("mini_mercado/cash-register", Vector3(1.2, _alto("desk", 1.6), -1.2), PI, 0.7)
	_trabajador(Vector3(0.2, 0, -2.2), 0.0, false, ["charla", "saludo_mano"], _BATA)
	_trabajador(Vector3(1.6, 0, -2.2), 0.0, false, ["charla"], _BATA)
	_trabajador(Vector3(0.9, 0, -0.1), PI, false, ["charla", "brazos_jarra"], _calle())
	## Espera y expositor de cuidado personal.
	_asiento("chairModernCushion", Vector3(-4.8, 0, 1.6), PI * 0.5, [0.0], _calle(), null, {"carpet": Color(0.3, 0.6, 0.45)})
	_asiento("chairModernCushion", Vector3(-4.8, 0, 2.6), PI * 0.5, [0.0], _calle(), null, {"carpet": Color(0.3, 0.6, 0.45)})
	_poner("sideTable", Vector3(-5.2, 0, 2.1))
	_poner("mini_mercado/shelf-bags", Vector3(4.6, 0, 1.5), -PI * 0.5, null, {"*": Color(0.95, 0.97, 0.95)})
	_planta(Vector3(5.2, 0, 3.2))
	_ventana(-1.0, -0.4, 1.4)
	## La cruz verde sobre el mostrador.
	var verde := Mini3D.mat(Color(0.15, 0.75, 0.4), 0.4, 0.6)
	Mini3D.caja(_raiz, Vector3(0, 2.55, -3.95), Vector3(0.9, 0.3, 0.06), verde)
	Mini3D.caja(_raiz, Vector3(0, 2.55, -3.95), Vector3(0.3, 0.9, 0.06), verde)
	_cartel(_sala_nombre().to_upper(), Vector3(2.4, 2.8, -3.95), 30)

## Banco (14 × 9 m): tres ventanillas con cristal y su cajero, la cola con cordones, los cajeros automáticos y la sala de espera.
func _banco() -> void:
	_tonos_sala = _MADERA_OSCURA
	_sala(Vector3(14, 3.4, 9), Color(0.78, 0.76, 0.72), Color(0.92, 0.91, 0.88), "losa", Color(0.2, 0.3, 0.5))
	for k in 3:
		var x := -4.0 + float(k) * 4.0
		_poner("desk", Vector3(x, 0, -2.2), 0.0, 1.5)
		Mini3D.caja(_raiz, Vector3(x, 1.2, -1.75), Vector3(1.7, 0.7, 0.03), Mini3D.mat(Color(0.7, 0.85, 0.95, 0.5), 0.1))
		_trabajador(Vector3(x, 0, -3.0), 0.0, false, ["charla", "saludo_mano"], _TRAJE)
		_poner("computerScreen", Vector3(x, _alto("desk", 1.5), -2.4), 0.0, 0.8)
	_trabajador(Vector3(-4.0, 0, -0.5), PI, false, ["charla", "brazos_jarra"], _calle())
	_trabajador(Vector3(0.0, 0, -0.4), PI, false, ["charla"], _calle())
	## Cordones de cola.
	var acero := Mini3D.mat(Color(0.75, 0.76, 0.8), 0.3, 0.7)
	var cinta := Mini3D.mat(Color(0.6, 0.12, 0.15), 0.8)
	for k in 4:
		Mini3D.cilindro(_raiz, Vector3(-1.5 + float(k) * 1.0, 0.45, 1.2), 0.04, 0.9, acero)
		if k < 3:
			Mini3D.caja(_raiz, Vector3(-1.0 + float(k) * 1.0, 0.75, 1.2), Vector3(0.95, 0.04, 0.03), cinta)
	## Cajeros automáticos en la pared derecha.
	for z: float in [-1.2, 0.4]:
		Mini3D.caja(_raiz, Vector3(6.55, 1.0, z), Vector3(0.7, 2.0, 0.8), Mini3D.mat(Color(0.2, 0.3, 0.55), 0.4))
		Mini3D.caja(_raiz, Vector3(6.2, 1.4, z), Vector3(0.04, 0.4, 0.5), Mini3D.mat(Color(0.5, 0.85, 1.0), 0.2, 1.2))
	_caminante([Vector3(5.4, 0, 1.6), Vector3(5.4, 0, -0.2), Vector3(5.4, 0, 1.6)], _calle())
	## Sala de espera.
	_asiento("loungeSofa", Vector3(-5.5, 0, 2.8), PI * 0.5, [-0.4, 0.45], _calle(), null, {"carpet": Color(0.2, 0.3, 0.5)})
	_poner("tableCoffeeGlass", Vector3(-3.9, 0, 2.8), PI * 0.5)
	_poner("books", Vector3(-3.9, _alto("tableCoffeeGlass"), 2.8), 0.4, 1.6)
	_planta(Vector3(-6.2, 0, -3.8))
	_planta(Vector3(6.2, 0, 3.6))
	_poner("lampSquareFloor", Vector3(-6.3, 0, 1.2))
	_cartel("🏦 " + _sala_nombre().to_upper(), Vector3(0, 2.9, -4.4), 36, Color(0.9, 0.85, 0.6))

## Hotel (16 × 11 m): el vestíbulo con la recepción, el conserje, sofás con mesa baja, el equipaje y los ascensores.
func _hotel() -> void:
	_tonos_sala = _MADERA_OSCURA
	_sala(Vector3(16, 3.8, 11), Color(0.72, 0.62, 0.5), Color(0.93, 0.9, 0.84), "parquet")
	_poner("deskCorner", Vector3(-1.0, 0, -4.0), 0.0, 1.5)
	_poner("desk", Vector3(1.8, 0, -4.0), 0.0, 1.5)
	_poner("computerScreen", Vector3(1.8, _alto("desk", 1.5), -4.1), 0.0, 0.8)
	_trabajador(Vector3(0.4, 0, -4.9), 0.0, false, ["saludo_mano", "charla"], _TRAJE)
	_trabajador(Vector3(2.4, 0, -4.9), 0.0, false, ["charla", "pedir_calma"], _TRAJE)
	_trabajador(Vector3(0.8, 0, -2.9), PI, false, ["charla", "brazos_jarra"], _calle())
	## Ascensores al fondo derecho (dos puertas de acero con su botón).
	for x: float in [5.0, 6.4]:
		Mini3D.caja(_raiz, Vector3(x, 1.2, -5.4), Vector3(1.2, 2.4, 0.1), Mini3D.mat(Color(0.72, 0.74, 0.78), 0.25, 0.0))
	Mini3D.caja(_raiz, Vector3(4.15, 1.2, -5.4), Vector3(0.1, 0.16, 0.05), Mini3D.mat(Color(1.0, 0.8, 0.3), 0.3, 1.5))
	## Zona de estar: dos sofás enfrentados, mesa y alfombra.
	Mini3D.caja(_raiz, Vector3(-4.2, 0.006, 1.6), Vector3(5.0, 0.012, 3.6), Mini3D.mat(Color(0.5, 0.18, 0.2), 0.95))
	_asiento("loungeDesignSofa", Vector3(-4.2, 0, 0.2), 0.0, [-0.5, 0.5], _calle(), null, {"carpet": Color(0.8, 0.72, 0.55)})
	_asiento("loungeDesignSofa", Vector3(-4.2, 0, 3.0), PI, [0.0], _calle(), null, {"carpet": Color(0.8, 0.72, 0.55)})
	_poner("tableCoffeeGlassSquare", Vector3(-4.2, 0, 1.6))
	_poner("lampRoundFloor", Vector3(-6.8, 0, 0.2))
	## Equipaje junto a la puerta.
	for k in 3:
		_poner("cardboardBoxClosed", Vector3(3.6 + float(k) * 0.55, 0, 4.4), 0.2 * float(k), 0.9, {"*": [Color(0.35, 0.2, 0.15), Color(0.2, 0.3, 0.4), Color(0.45, 0.35, 0.2)][k]})
	_caminante([Vector3(2.0, 0, 3.8), Vector3(2.0, 0, -1.2), Vector3(-1.5, 0, -1.2), Vector3(-1.5, 0, 3.8)], _calle())
	_planta(Vector3(-7.2, 0, -4.8))
	_planta(Vector3(7.2, 0, -4.8))
	_planta(Vector3(7.2, 0, 4.8))
	_poner("lampSquareCeiling", Vector3(0, 3.1, 0.5))
	_cartel("🏨 " + _sala_nombre().to_upper(), Vector3(0.5, 3.0, -5.35), 36, Color(1.0, 0.9, 0.6))

## Ferretería (14 × 10 m): pasillos de estantes con cajas, barriles, un banco de trabajo con la sierra y el mostrador.
func _ferreteria() -> void:
	_tonos_sala = _MADERA_CLARA
	_sala(Vector3(14, 3.4, 10), Color(0.62, 0.6, 0.57), Color(0.88, 0.85, 0.78), "losa", Color(0.75, 0.35, 0.15))
	var neutro := {"*": Color(0.9, 0.82, 0.7)}
	for z: float in [-3.2, -0.6]:
		for k in 3:
			_poner("mini_mercado/shelf-boxes", Vector3(-5.5 + float(k) * _medida("mini_mercado/shelf-boxes").x, 0, z), 0.0, null, neutro)
		_poner("mini_mercado/shelf-end", Vector3(-5.5 + 3.0 * _medida("mini_mercado/shelf-boxes").x, 0, z), -PI * 0.5, null, neutro)
	for k in 3:
		_poner("comida/barrel", Vector3(5.6, 0, -4.0 + float(k) * 0.9), 0.4 * float(k), 1.4, {"*": Color(0.3, 0.4, 0.55)})
		_poner("cardboardBoxOpen", Vector3(4.4, 0, -4.2 + float(k) * 0.8), 0.1, 1.2)
	_poner("table", Vector3(3.2, 0, 0.8), 0.0, 1.6, {"*": Color(0.55, 0.4, 0.25)})
	Mini3D.caja(_raiz, Vector3(3.2, 0.9, 0.8), Vector3(0.5, 0.18, 0.12), Mini3D.mat(Color(0.8, 0.2, 0.15), 0.6))
	for k in 4:
		_poner("comida/can", Vector3(-4.8 + float(k) * 0.3, 0.9, 3.6), 0.0, 1.2, {"*": [Color(0.8, 0.2, 0.2), Color(0.2, 0.5, 0.8), Color(0.9, 0.8, 0.2), Color(0.2, 0.7, 0.4)][k]})
	_poner("table", Vector3(-4.5, 0, 3.6), 0.0, 1.6)
	_caja_cobro(Vector3(-0.8, 0, 3.8), PI * 0.5, [Color(0.85, 0.45, 0.1), Color(0.2, 0.2, 0.25), true], true)
	_trabajador(Vector3(3.2, 0, -0.5), PI * 0.25, false, ["charla", "senalar_adelante"], [Color(0.85, 0.45, 0.1), Color(0.2, 0.2, 0.25), true])
	_caminante([Vector3(-5.5, 0, 1.5), Vector3(1.0, 0, 1.5), Vector3(1.0, 0, 2.6), Vector3(-5.5, 0, 2.6)], _calle())
	_planta(Vector3(6.2, 0, 4.2))
	_cartel("🔧 " + _sala_nombre().to_upper(), Vector3(0, 2.8, -4.95), 34)

## Floristería (10 × 8 m): mesas redondas con macetas y ramos en cubos, el mostrador de envolver y las plantas colgando de la pared.
func _floristeria() -> void:
	_tonos_sala = _MADERA_CLARA
	_sala(Vector3(10, 3.2, 8), Color(0.78, 0.7, 0.58), Color(0.95, 0.93, 0.88), "parquet", Color(0.3, 0.6, 0.35))
	var flores: Array[Color] = [Color(0.9, 0.2, 0.3), Color(0.98, 0.85, 0.2), Color(0.95, 0.5, 0.75), Color(0.6, 0.35, 0.85), Color(0.98, 0.98, 0.95)]
	for k in 3:
		var x := -3.0 + float(k) * 3.0
		_poner("tableRound", Vector3(x, 0, -0.8), 0.0, 1.1)
		var alto_m := _alto("tableRound", 1.1)
		for j in 3:
			var a := TAU * float(j) / 3.0
			var c := Vector3(x + cos(a) * 0.3, alto_m, -0.8 + sin(a) * 0.3)
			Mini3D.cilindro(_raiz, c + Vector3(0, 0.12, 0), 0.1, 0.24, Mini3D.mat(Color(0.7, 0.4, 0.25), 0.8))
			Mini3D.esfera(_raiz, c + Vector3(0, 0.42, 0), 0.18, Mini3D.mat(flores[(k + j) % flores.size()], 0.7))
	for k in 5:
		var x := -3.6 + float(k) * 1.8
		Mini3D.cilindro(_raiz, Vector3(x, 0.3, -3.5), 0.22, 0.6, Mini3D.mat(Color(0.5, 0.55, 0.6), 0.4, 0.0))
		for j in 4:
			Mini3D.esfera(_raiz, Vector3(x + (float(j) - 1.5) * 0.12, 0.8 + 0.06 * float(j % 2), -3.5 + (float(j % 2) - 0.5) * 0.12), 0.12, Mini3D.mat(flores[(k + j) % flores.size()], 0.7))
	_poner("pottedPlant", Vector3(-4.4, 0, 2.6))
	_poner("plantSmall2", Vector3(4.4, 0, 2.8))
	_poner("desk", Vector3(3.2, 0, 1.4), -PI * 0.5, 1.3)
	_poner("mini_mercado/cash-register", Vector3(3.3, _alto("desk", 1.3), 1.4), -PI * 0.5, 0.7)
	_trabajador(Vector3(4.1, 0, 1.4), -PI * 0.5, false, ["charla", "saludo_mano"], [Color(0.3, 0.55, 0.35), Color(0.25, 0.25, 0.3), true])
	_trabajador(Vector3(1.6, 0, 1.6), PI * 0.5, false, ["charla"], _calle())
	_ventana(-1.0, 0.8, 1.4)
	_cartel("🌷 " + _sala_nombre().to_upper(), Vector3(0, 2.8, -3.95), 32, Color(1.0, 0.85, 0.9))

## Correos (12 × 8 m): mostrador con dos ventanillas y su cola con cordones, la pared de casillas postales, paquetes apilados y el buzón.
func _correos() -> void:
	_tonos_sala = _MADERA_CLARA
	var uniforme := [Color(0.95, 0.8, 0.2), Color(0.2, 0.25, 0.4), true]
	_sala(Vector3(12, 3.2, 8), Color(0.74, 0.72, 0.68), Color(0.93, 0.92, 0.88), "losa", Color(0.95, 0.8, 0.2))
	for k in 3:
		_poner("bookcaseClosedWide", Vector3(-4.0 + float(k) * 4.0, 0, -3.75), 0.0)
		for j in 6:
			Mini3D.caja(_raiz, Vector3(-4.8 + float(k) * 4.0 + float(j % 3) * 0.55, 0.7 + float(j / 3) * 0.5, -3.52), Vector3(0.4, 0.34, 0.03), Mini3D.mat(Color(0.75, 0.78, 0.82), 0.4, 0.0))
	for x: float in [-1.5, 1.5]:
		_poner("desk", Vector3(x, 0, -1.4), 0.0, 1.5)
		_trabajador(Vector3(x, 0, -2.3), 0.0, false, ["charla", "saludo_mano"], uniforme)
		_poner("computerScreen", Vector3(x, _alto("desk", 1.5), -1.6), 0.0, 0.8)
	for k in 4:
		_poner("cardboardBoxClosed", Vector3(-5.2, float(k % 2) * 0.55, -2.0 + float(k / 2) * 0.7), 0.15 * float(k), 1.0)
	_poner("cardboardBoxClosed", Vector3(5.0, 0, -2.4), 0.3, 1.4)
	var acero := Mini3D.mat(Color(0.75, 0.76, 0.8), 0.3, 0.7)
	var cinta := Mini3D.mat(Color(0.8, 0.15, 0.15), 0.8)
	for k in 3:
		Mini3D.cilindro(_raiz, Vector3(-1.0 + float(k) * 1.0, 0.45, 0.8), 0.04, 0.9, acero)
		if k < 2:
			Mini3D.caja(_raiz, Vector3(-0.5 + float(k) * 1.0, 0.75, 0.8), Vector3(0.95, 0.04, 0.03), cinta)
	_trabajador(Vector3(0.0, 0, 0.2), PI, false, ["charla", "brazos_jarra"], _calle())
	_trabajador(Vector3(-1.8, 0, 0.1), PI, false, ["charla"], _calle())
	## El buzón rojo junto a la puerta.
	Mini3D.caja(_raiz, Vector3(5.2, 0.55, 3.0), Vector3(0.5, 1.1, 0.4), Mini3D.mat(Color(0.8, 0.1, 0.1), 0.5))
	Mini3D.cilindro(_raiz, Vector3(5.2, 1.12, 3.0), 0.25, 0.4, Mini3D.mat(Color(0.8, 0.1, 0.1), 0.5))
	_planta(Vector3(-5.5, 0, 3.4))
	_cartel("✉️ " + _sala_nombre().to_upper(), Vector3(0, 2.8, -3.95), 32, Color(1.0, 0.9, 0.4))

## Tienda de deportes (14 × 10 m): perchas de camisetas por colores, el expositor de balones y botas y la caja.
func _deportes() -> void:
	_tonos_sala = _MADERA_CLARA
	_sala(Vector3(14, 3.4, 10), Color(0.62, 0.64, 0.66), Color(0.94, 0.94, 0.95), "losa", Color(0.15, 0.4, 0.7))
	var tonos: Array[Color] = [Color(0.85, 0.15, 0.15), Color(0.15, 0.4, 0.85), Color(0.95, 0.8, 0.15), Color(0.2, 0.65, 0.35), Color(0.9, 0.9, 0.92)]
	for k in 4:
		_perchero(Vector3(-5.2 + float(k) * 3.4, 0, -4.65), 0.0, 2.8, tonos[k % 5], tonos[(k + 2) % 5])
	_perchero(Vector3(-6.6, 0, -1.0), PI * 0.5, 2.6, tonos[1], tonos[4])
	_perchero(Vector3(-6.6, 0, 2.0), PI * 0.5, 2.6, tonos[3], tonos[0])
	for k in 3:
		_poner("bookcaseOpenLow", Vector3(6.72, 0, -2.4 + float(k) * 1.2), -PI * 0.5)
		for b in 2:
			Mini3D.esfera(_raiz, Vector3(6.72, 0.9, -2.7 + float(k) * 1.2 + float(b) * 0.45), 0.11, Mini3D.mat(Color.WHITE if (k + b) % 2 == 0 else tonos[k], 0.5))
	for x: float in [-2.0, 1.2]:
		_poner("table", Vector3(x, 0, -1.2), 0.0, 2.0)
		for i in 5:
			Mini3D.caja(_raiz, Vector3(x - 0.5 + float(i) * 0.25, _alto("table", 2.0) + 0.06, -1.2), Vector3(0.2, 0.1, 0.3), Mini3D.mat(tonos[i % 5].lightened(0.1), 0.8))
	for k in 4:
		Mini3D.caja(_raiz, Vector3(2.5 + float(k) * 0.5, 0.2, 3.9), Vector3(0.38, 0.22, 0.26), Mini3D.mat(tonos[k % 5], 0.7))
	_caja_cobro(Vector3(4.6, 0, 2.6), PI * 0.5, [Color(0.15, 0.4, 0.85), Color(0.15, 0.15, 0.2), true], true)
	_trabajador(Vector3(-3.2, 0, 1.0), PI * 0.3, false, ["charla", "senalar_adelante"], [Color(0.15, 0.4, 0.85), Color(0.15, 0.15, 0.2), true])
	_caminante([Vector3(-5.0, 0, 3.4), Vector3(1.0, 0, 3.4), Vector3(1.0, 0, 1.0), Vector3(-5.0, 0, 1.0)], _calle())
	_planta(Vector3(-6.4, 0, 4.4))
	_cartel("⚽ " + _sala_nombre().to_upper(), Vector3(0, 2.95, -4.95), 36, Color(1.0, 0.95, 0.6))

## Pizzería (13 × 9 m): comedor con mesas de mantel y comensales, el horno con campana y el mostrador con las pizzas.
func _pizzeria() -> void:
	_tonos_sala = _MADERA_OSCURA
	var delantal := [Color(0.95, 0.95, 0.95), Color(0.2, 0.2, 0.22), true]
	_sala(Vector3(13, 3.2, 9), Color(0.55, 0.3, 0.2), Color(0.95, 0.88, 0.75), "parquet", Color(0.7, 0.18, 0.15))
	_poner("kitchenStove", Vector3(-4.6, 0, -3.8), 0.0, 1.3)
	_poner("hoodLarge", Vector3(-4.6, 1.9, -3.9), 0.0, 1.3)
	_poner("kitchenCabinet", Vector3(-3.1, 0, -3.8), 0.0, 1.3)
	_poner("kitchenFridgeLarge", Vector3(-6.0, 0, -3.8), 0.0, 1.2)
	_trabajador(Vector3(-4.2, 0, -2.9), PI, false, ["charla", "brazos_jarra"], delantal)
	_poner("desk", Vector3(0.6, 0, -3.1), 0.0, 1.8)
	for k in 3:
		_poner("comida/pizza", Vector3(-0.2 + float(k) * 0.8, _alto("desk", 1.8), -3.1), 0.4 * float(k), 1.2)
	_poner("comida/pizza-box", Vector3(2.0, _alto("desk", 1.8), -3.1), 0.2, 1.1)
	_trabajador(Vector3(0.6, 0, -4.0), 0.0, false, ["saludo_mano", "charla"], delantal)
	for p: Vector3 in [Vector3(-3.0, 0, 0.0), Vector3(1.0, 0, 0.5), Vector3(4.6, 0, 0.0), Vector3(-1.5, 0, 3.0), Vector3(3.2, 0, 3.0)]:
		_poner("tableCloth", p, 0.0, 1.2, {"*": Color(0.85, 0.2, 0.2) if int(p.x) % 2 == 0 else Color(0.95, 0.95, 0.9)})
		_poner("comida/pizza", p + Vector3(0, _alto("tableCloth", 1.2), 0), 0.3, 1.0)
		_poner("comida/soda-glass", p + Vector3(0.35, _alto("tableCloth", 1.2), 0.2), 0.0, 1.0)
		_asiento("chair", p + Vector3(-0.8, 0, 0), PI * 0.5, [0.0], _calle())
		_asiento("chair", p + Vector3(0.8, 0, 0), -PI * 0.5, [0.0], _calle())
	_poner("mini_arcade/vending-machine", Vector3(5.8, 0, -3.9), 0.0, 2.2)
	_planta(Vector3(-6.0, 0, 3.8))
	_ventana(1.0, 0.8, 1.4)
	_cartel("🍕 " + _sala_nombre().to_upper(), Vector3(0.5, 2.8, -4.45), 34, Color(1.0, 0.85, 0.6))

## Heladería (10 × 7 m): la vitrina de cubetas de colores, los conos, la barra con taburetes y una mesita al sol.
func _heladeria() -> void:
	_tonos_sala = _MADERA_CLARA
	var delantal := [Color(0.98, 0.7, 0.8), Color(0.95, 0.95, 0.95), true]
	_sala(Vector3(10, 3.2, 7), Color(0.92, 0.88, 0.84), Color(0.98, 0.9, 0.92), "losa", Color(0.5, 0.85, 0.8))
	var sabores: Array[Color] = [Color(0.95, 0.45, 0.6), Color(0.45, 0.8, 0.6), Color(0.45, 0.3, 0.2), Color(0.98, 0.9, 0.5), Color(0.95, 0.95, 0.9), Color(0.55, 0.65, 0.95)]
	Mini3D.caja(_raiz, Vector3(0, 0.55, -2.3), Vector3(5.0, 1.1, 0.9), Mini3D.mat(Color(0.95, 0.95, 0.97), 0.3))
	Mini3D.caja(_raiz, Vector3(0, 1.2, -2.3), Vector3(4.9, 0.3, 0.85), Mini3D.mat(Color(0.75, 0.9, 0.95, 0.55), 0.1))
	for k in 6:
		Mini3D.cilindro(_raiz, Vector3(-2.0 + float(k) * 0.8, 1.14, -2.3), 0.3, 0.12, Mini3D.mat(sabores[k], 0.6))
		Mini3D.esfera(_raiz, Vector3(-2.0 + float(k) * 0.8, 1.26, -2.3), 0.22, Mini3D.mat(sabores[k].lightened(0.15), 0.6))
	_trabajador(Vector3(-0.6, 0, -3.2), 0.0, false, ["charla", "saludo_mano"], delantal)
	_trabajador(Vector3(1.5, 0, -3.2), 0.0, false, ["charla"], delantal)
	for x: float in [-0.9, 0.0, 0.9]:
		_poner("comida/ice-cream-cne", Vector3(x, 1.28, -1.7), 0.0, 1.4)
	_poner("mini_mercado/cash-register", Vector3(2.0, 1.1, -2.3), 0.0, 0.7)
	for k in 3:
		_asiento("stoolBar", Vector3(-1.4 + float(k) * 1.0, 0, -0.6), 0.0, [0.0], _calle() if k != 1 else [])
	_poner("tableCoffeeGlass", Vector3(3.2, 0, 1.6), 0.0, 1.0)
	_asiento("chair", Vector3(2.4, 0, 1.6), -PI * 0.5, [0.0], _calle())
	_asiento("chair", Vector3(4.0, 0, 1.6), PI * 0.5, [0.0], _calle())
	_poner("comida/sundae", Vector3(3.2, _alto("tableCoffeeGlass"), 1.6), 0.0, 1.2)
	_planta(Vector3(-4.3, 0, 2.8))
	_ventana(-1.0, 0.8, 1.2)
	_cartel("🍦 " + _sala_nombre().to_upper(), Vector3(0, 2.8, -3.45), 34, Color(0.95, 0.4, 0.6))
