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

## Correos (10 × 7 m): la pared de casillas, el mostrador con dos empleados, la cola con su cinta, la máquina de números, la mesa de embalaje y los paquetes.
func _correos() -> void:
	_tonos_sala = _MADERA_CLARA
	var uniforme := [Color(0.95, 0.8, 0.2), Color(0.2, 0.25, 0.4), true]
	_sala(Vector3(10, 3.2, 7), Color(0.74, 0.72, 0.68), Color(0.93, 0.92, 0.88), "losa", Color(0.95, 0.8, 0.2))
	for k in 3:
		_poner("bookcaseClosedWide", Vector3(-3.2 + float(k) * 3.2, 0, -3.25), 0.0)
		for j in 9:
			Mini3D.caja(_raiz, Vector3(-3.9 + float(k) * 3.2 + float(j % 3) * 0.55, 0.55 + float(j / 3) * 0.42, -3.02), Vector3(0.42, 0.32, 0.03), Mini3D.mat(Color(0.75, 0.78, 0.82), 0.4, 0.0))
	## Mostrador largo con dos ventanillas y los empleados detrás.
	_poner("desk", Vector3(-1.0, 0, -1.3), 0.0, 1.6)
	_poner("desk", Vector3(1.2, 0, -1.3), 0.0, 1.6)
	_poner("desk", Vector3(3.0, 0, -1.3), 0.0, 1.6)
	for x: float in [-1.0, 1.2]:
		_trabajador(Vector3(x, 0, -2.2), 0.0, false, ["charla", "saludo_mano"], uniforme)
		_poner("computerScreen", Vector3(x, _alto("desk", 1.6), -1.5), 0.0, 0.8)
		_poner("mini_mercado/cash-register", Vector3(x + 0.5, _alto("desk", 1.6), -1.4), PI, 0.6)
	## La cola con cinta y cuatro clientes.
	var acero := Mini3D.mat(Color(0.75, 0.76, 0.8), 0.3, 0.7)
	var cinta := Mini3D.mat(Color(0.8, 0.15, 0.15), 0.8)
	for k in 5:
		Mini3D.cilindro(_raiz, Vector3(-1.4 + float(k) * 0.9, 0.45, 1.0), 0.04, 0.9, acero)
		if k < 4:
			Mini3D.caja(_raiz, Vector3(-0.95 + float(k) * 0.9, 0.75, 1.0), Vector3(0.88, 0.04, 0.03), cinta)
	for k in 4:
		_trabajador(Vector3(-0.8 + float(k % 2) * 0.1, 0, -0.2 + float(k) * 0.45), PI, false, ["charla", "brazos_jarra"], _calle())
	## Máquina de números junto a la puerta, con su pantalla.
	Mini3D.caja(_raiz, Vector3(3.9, 0.7, 1.6), Vector3(0.5, 1.4, 0.4), Mini3D.mat(Color(0.2, 0.3, 0.55), 0.4))
	Mini3D.caja(_raiz, Vector3(3.9, 1.15, 1.39), Vector3(0.32, 0.22, 0.02), Mini3D.mat(Color(1.0, 0.85, 0.2), 0.3, 1.2))
	_cartel("N° 47", Vector3(3.9, 1.55, 1.39), 16, Color(1.0, 0.9, 0.3))
	## Mesa de embalaje, paquetes y sacas, el buzón y la espera.
	_poner("table", Vector3(-4.0, 0, 0.6), 0.0, 1.5)
	for k in 3:
		_poner("cardboardBoxClosed", Vector3(-4.0 + float(k - 1) * 0.35, _alto("table", 1.5), 0.6), 0.2 * float(k), 0.8)
	for k in 5:
		_poner("cardboardBoxClosed", Vector3(-4.4 + float(k % 3) * 0.6, float(k / 3) * 0.5, -1.2 + float(k % 2) * 0.1), 0.1 * float(k), 1.0)
	Mini3D.caja(_raiz, Vector3(4.4, 0.55, -0.5), Vector3(0.5, 1.1, 0.4), Mini3D.mat(Color(0.8, 0.1, 0.1), 0.5))
	Mini3D.cilindro(_raiz, Vector3(4.4, 1.12, -0.5), 0.25, 0.4, Mini3D.mat(Color(0.8, 0.1, 0.1), 0.5))
	_asiento("chairModernCushion", Vector3(2.6, 0, 2.5), PI, [0.0], _calle(), null, {"carpet": Color(0.2, 0.3, 0.55)})
	_asiento("chairModernCushion", Vector3(3.3, 0, 2.5), PI, [0.0], [], null, {"carpet": Color(0.2, 0.3, 0.55)})
	_planta(Vector3(-4.4, 0, 2.8))
	_ventana(-1.0, 1.4, 1.2)
	_cartel("✉️ " + _sala_nombre().to_upper(), Vector3(0, 2.8, -3.45), 32, Color(1.0, 0.9, 0.4))

## Tienda de deportes (11 × 8 m): zapatillas en estantes, maniquíes con camiseta, el canasto de balones, perchas, el banco de prueba y la caja.
func _deportes() -> void:
	_tonos_sala = _MADERA_CLARA
	_sala(Vector3(11, 3.4, 8), Color(0.62, 0.64, 0.66), Color(0.94, 0.94, 0.95), "losa", Color(0.15, 0.4, 0.7))
	var tonos: Array[Color] = [Color(0.85, 0.15, 0.15), Color(0.15, 0.4, 0.85), Color(0.95, 0.8, 0.15), Color(0.2, 0.65, 0.35), Color(0.9, 0.9, 0.92)]
	## Pared del fondo: estantes con cajas de zapatillas y una percha.
	for k in 3:
		_poner("bookcaseOpen", Vector3(-3.6 + float(k) * 2.4, 0, -3.7), 0.0, 1.2)
		for fila in 3:
			for j in 3:
				Mini3D.caja(_raiz, Vector3(-3.95 + float(k) * 2.4 + float(j) * 0.36, 0.45 + float(fila) * 0.5, -3.7), Vector3(0.3, 0.2, 0.24), Mini3D.mat(tonos[(k + fila + j) % 5], 0.7))
	_perchero(Vector3(3.6, 0, -3.7), 0.0, 2.2, tonos[0], tonos[4])
	_perchero(Vector3(-5.2, 0, -0.6), PI * 0.5, 2.6, tonos[1], tonos[3])
	_perchero(Vector3(-5.2, 0, 2.2), PI * 0.5, 2.6, tonos[2], tonos[0])
	## Maniquíes con equipación (cuerpo, cabeza y peana).
	for k in 3:
		var x := -2.6 + float(k) * 2.6
		var camiseta := Mini3D.mat(tonos[k], 0.6)
		Mini3D.cilindro(_raiz, Vector3(x, 0.03, -1.0), 0.32, 0.06, Mini3D.mat(Color(0.2, 0.2, 0.22), 0.5))
		Mini3D.cilindro(_raiz, Vector3(x, 0.45, -1.0), 0.07, 0.8, Mini3D.mat(Color(0.8, 0.8, 0.82), 0.5))
		Mini3D.caja(_raiz, Vector3(x, 1.2, -1.0), Vector3(0.5, 0.6, 0.26), camiseta)
		Mini3D.cilindro(_raiz, Vector3(x, 0.8, -1.0), 0.2, 0.36, Mini3D.mat(Color(0.15, 0.15, 0.2), 0.7))
		Mini3D.esfera(_raiz, Vector3(x, 1.68, -1.0), 0.12, Mini3D.mat(Color(0.85, 0.85, 0.87), 0.4))
	## Canasto de balones.
	Mini3D.cilindro(_raiz, Vector3(3.6, 0.35, -0.4), 0.55, 0.7, Mini3D.mat(Color(0.3, 0.3, 0.34), 0.7))
	for k in 7:
		Mini3D.esfera(_raiz, Vector3(3.6 + cos(float(k) * 0.9) * 0.28, 0.78 + float(k % 2) * 0.1, -0.4 + sin(float(k) * 0.9) * 0.28), 0.12, Mini3D.mat(Color.WHITE if k % 3 != 0 else tonos[k % 5], 0.5))
	## Banco para probarse zapatillas con cajas abiertas.
	_poner("benchCushion", Vector3(-1.0, 0, 2.0), 0.0, 1.2)
	for k in 3:
		Mini3D.caja(_raiz, Vector3(-1.6 + float(k) * 0.6, 0.12, 2.9), Vector3(0.32, 0.2, 0.22), Mini3D.mat(tonos[k], 0.7))
	_asiento("benchCushion", Vector3(-1.0, 0, 2.0), 0.0, [0.0], _calle(), 1.2)
	## Caja con el dependiente.
	_poner("desk", Vector3(3.4, 0, 2.6), -PI * 0.5, 1.5)
	_caja_cobro(Vector3(3.9, 0, 2.6), PI * 0.5, [Color(0.15, 0.4, 0.85), Color(0.15, 0.15, 0.2), true], true)
	_trabajador(Vector3(1.0, 0, 1.2), PI * 0.3, false, ["charla", "senalar_adelante"], [Color(0.15, 0.4, 0.85), Color(0.15, 0.15, 0.2), true])
	_caminante([Vector3(-4.0, 0, 3.2), Vector3(0.0, 0, 3.2), Vector3(0.0, 0, 0.6), Vector3(-4.0, 0, 0.6)], _calle())
	_planta(Vector3(-4.8, 0, 3.4))
	_cartel("⚽ " + _sala_nombre().to_upper(), Vector3(0, 2.95, -3.95), 36, Color(1.0, 0.95, 0.6))

## Pizzería (11 × 8 m): comedor con mesas a su altura y comensales, el horno de leña al fondo, la barra con taburetes y la nevera.
func _pizzeria() -> void:
	_tonos_sala = _MADERA_OSCURA
	var delantal := [Color(0.95, 0.95, 0.95), Color(0.2, 0.2, 0.22), true]
	_sala(Vector3(11, 3.2, 8), Color(0.55, 0.3, 0.2), Color(0.95, 0.88, 0.75), "parquet", Color(0.7, 0.18, 0.15))
	## Horno de leña de ladrillo: base, cúpula, boca con fuego y chimenea.
	var ladrillo := Mini3D.mat(Color(0.62, 0.28, 0.2), 0.9)
	Mini3D.caja(_raiz, Vector3(-3.6, 0.6, -3.3), Vector3(2.0, 1.2, 1.2), ladrillo)
	Mini3D.esfera(_raiz, Vector3(-3.6, 1.35, -3.3), 0.95, ladrillo)
	Mini3D.caja(_raiz, Vector3(-3.6, 1.1, -2.72), Vector3(0.7, 0.5, 0.1), Mini3D.mat(Color(0.05, 0.03, 0.02), 0.9))
	Mini3D.caja(_raiz, Vector3(-3.6, 0.95, -2.7), Vector3(0.5, 0.18, 0.05), Mini3D.mat(Color(1.0, 0.5, 0.1), 0.5, 2.2))
	Mini3D.cilindro(_raiz, Vector3(-3.6, 2.6, -3.3), 0.22, 1.6, ladrillo)
	_trabajador(Vector3(-2.4, 0, -2.4), PI * 0.8, false, ["charla", "brazos_jarra"], delantal)
	## Barra con las pizzas a la vista y taburetes.
	_poner("desk", Vector3(1.6, 0, -3.1), 0.0, 1.8)
	_poner("desk", Vector3(3.4, 0, -3.1), 0.0, 1.8)
	for k in 3:
		_poner("comida/pizza", Vector3(0.9 + float(k) * 0.9, _alto("desk", 1.8), -3.1), 0.4 * float(k), 1.2)
	_poner("comida/pizza-box", Vector3(3.6, _alto("desk", 1.8), -3.1), 0.2, 1.1)
	_trabajador(Vector3(1.8, 0, -3.9), 0.0, false, ["saludo_mano", "charla"], delantal)
	for k in 3:
		_asiento("stoolBar", Vector3(1.0 + float(k) * 1.0, 0, -2.0), PI, [0.0], _calle() if k != 1 else [])
	_poner("kitchenFridgeLarge", Vector3(5.0, 0, -3.7), 0.0, 1.2)
	## Comedor: mesas de verdad (con su mantel encima) y la pizza a la altura de la mesa.
	for p: Vector3 in [Vector3(-3.4, 0, 0.0), Vector3(0.4, 0, 0.8), Vector3(3.8, 0, 0.4), Vector3(-2.4, 0, 3.0), Vector3(2.2, 0, 3.1)]:
		_poner("table", p, 0.0, 1.3)
		var top := _alto("table", 1.3)
		Mini3D.caja(_raiz, p + Vector3(0, top + 0.01, 0), Vector3(0.95, 0.02, 0.95), Mini3D.mat(Color(0.85, 0.2, 0.2) if int(p.x * 2.0) % 2 == 0 else Color(0.95, 0.95, 0.9), 0.9))
		_poner("comida/pizza", p + Vector3(0, top + 0.02, 0), 0.3, 0.9)
		_poner("comida/soda-glass", p + Vector3(0.33, top + 0.02, 0.2), 0.0, 1.0)
		_asiento("chair", p + Vector3(-0.8, 0, 0), PI * 0.5, [0.0], _calle())
		_asiento("chair", p + Vector3(0.8, 0, 0), -PI * 0.5, [0.0], _calle() if int(p.z) % 2 == 0 else [])
	_poner("mini_arcade/vending-machine", Vector3(5.0, 0, 0.5), -PI * 0.5, 2.2)
	_planta(Vector3(-4.7, 0, 3.4))
	_cartel("🍕 " + _sala_nombre().to_upper(), Vector3(1.0, 2.8, -3.95), 32, Color(1.0, 0.85, 0.6))

## Heladería (8 × 6 m): la vitrina de cubetas, la pizarra de sabores, los conos, los taburetes de la barra y mesitas con sus sillas.
func _heladeria() -> void:
	_tonos_sala = _MADERA_CLARA
	var delantal := [Color(0.98, 0.7, 0.8), Color(0.95, 0.95, 0.95), true]
	_sala(Vector3(8, 3.2, 6), Color(0.92, 0.88, 0.84), Color(0.98, 0.9, 0.92), "losa", Color(0.5, 0.85, 0.8))
	var sabores: Array[Color] = [Color(0.95, 0.45, 0.6), Color(0.45, 0.8, 0.6), Color(0.45, 0.3, 0.2), Color(0.98, 0.9, 0.5), Color(0.95, 0.95, 0.9), Color(0.55, 0.65, 0.95)]
	var nombres := ["Frutilla", "Menta", "Chocolate", "Limón", "Vainilla", "Arándano"]
	Mini3D.caja(_raiz, Vector3(-0.4, 0.55, -1.9), Vector3(4.4, 1.1, 0.9), Mini3D.mat(Color(0.95, 0.95, 0.97), 0.3))
	Mini3D.caja(_raiz, Vector3(-0.4, 1.2, -1.9), Vector3(4.3, 0.3, 0.85), Mini3D.mat(Color(0.75, 0.9, 0.95, 0.55), 0.1))
	for k in 6:
		Mini3D.cilindro(_raiz, Vector3(-2.2 + float(k) * 0.72, 1.14, -1.9), 0.27, 0.12, Mini3D.mat(sabores[k], 0.6))
		Mini3D.esfera(_raiz, Vector3(-2.2 + float(k) * 0.72, 1.26, -1.9), 0.2, Mini3D.mat(sabores[k].lightened(0.15), 0.6))
	_trabajador(Vector3(-1.2, 0, -2.8), 0.0, false, ["charla", "saludo_mano"], delantal)
	_trabajador(Vector3(0.8, 0, -2.8), 0.0, false, ["charla"], delantal)
	for x: float in [-0.5, 0.2, 0.9]:
		_poner("comida/ice-cream-cne", Vector3(x, 1.28, -1.45), 0.0, 1.4)
	_poner("mini_mercado/cash-register", Vector3(1.6, 1.1, -1.9), 0.0, 0.7)
	## La pizarra de sabores en la pared del fondo, con cada nombre en su color.
	Mini3D.caja(_raiz, Vector3(0.0, 2.1, -2.93), Vector3(3.6, 1.0, 0.05), Mini3D.mat(Color(0.12, 0.2, 0.2), 0.8))
	_cartel("SABORES", Vector3(0.0, 2.45, -2.9), 20, Color(1.0, 0.9, 0.95))
	for k in 6:
		_cartel(String(nombres[k]), Vector3(-1.2 + float(k % 3) * 1.2, 2.12 - float(k / 3) * 0.28, -2.9), 14, sabores[k].lightened(0.2))
	## Barra con taburetes y clientes.
	for k in 3:
		_asiento("stoolBar", Vector3(-1.6 + float(k) * 1.0, 0, -0.7), 0.0, [0.0], _calle() if k != 1 else [])
	## Mesitas con sillas y copas de helado.
	for p: Vector3 in [Vector3(2.4, 0, 0.3), Vector3(2.4, 0, 2.0), Vector3(-1.6, 0, 1.9)]:
		_poner("tableRound", p, 0.0, 0.9)
		_poner("comida/sundae", p + Vector3(0, _alto("tableRound", 0.9), 0), 0.0, 1.2)
		_asiento("chair", p + Vector3(-0.7, 0, 0), PI * 0.5, [0.0], _calle())
		_asiento("chair", p + Vector3(0.7, 0, 0), -PI * 0.5, [0.0], _calle() if int(p.z * 10.0) % 2 == 0 else [])
	_planta(Vector3(-3.4, 0, 2.4))
	_cartel("🍦 " + _sala_nombre().to_upper(), Vector3(0, 2.8, -2.95), 34, Color(0.95, 0.4, 0.6))

## Peña del club (10 × 7 m): bufandas y banderines con los colores del club, la barra con taburetes, la tele con el partido, el estante de trofeos
## y mesas con hinchas. Los colores salen de `_c1` y `_c2` (los del club cuando la sala se abre con club).
func _pena() -> void:
	_tonos_sala = _MADERA_OSCURA
	var delantal := [_c1, Color(0.15, 0.15, 0.18), true]
	_sala(Vector3(10, 3.2, 7), Color(0.5, 0.34, 0.24), Color(0.93, 0.9, 0.84), "parquet", _c1)
	## Pared del fondo: banderines en cuerda, bufandas colgadas y el escudo grande.
	for k in 9:
		var x := -4.0 + float(k)
		Mini3D.caja(_raiz, Vector3(x, 2.55 - 0.07 * absf(float(k) - 4.0) * 0.0, -3.45), Vector3(0.42, 0.3, 0.02), Mini3D.mat(_c1 if k % 2 == 0 else _c2, 0.8))
	for k in 6:
		Mini3D.caja(_raiz, Vector3(-4.2 + float(k) * 1.6, 1.7, -3.46), Vector3(0.22, 1.0, 0.02), Mini3D.mat(_c1 if k % 2 == 0 else _c2, 0.9))
		Mini3D.caja(_raiz, Vector3(-4.2 + float(k) * 1.6, 1.7, -3.455), Vector3(0.22, 0.14, 0.02), Mini3D.mat(_c2 if k % 2 == 0 else _c1, 0.9))
	Mini3D.cilindro(_raiz, Vector3(0.0, 1.9, -3.46), 0.55, 0.04, Mini3D.mat(_c2, 0.6)).rotation.x = PI * 0.5
	Mini3D.cilindro(_raiz, Vector3(0.0, 1.9, -3.44), 0.42, 0.04, Mini3D.mat(_c1, 0.6)).rotation.x = PI * 0.5
	## Barra, taburetes y el camarero.
	_poner("desk", Vector3(-2.6, 0, -2.2), 0.0, 1.8)
	_poner("desk", Vector3(-1.0, 0, -2.2), 0.0, 1.8)
	_trabajador(Vector3(-1.8, 0, -3.0), 0.0, false, ["charla", "saludo_mano"], delantal)
	for k in 4:
		_asiento("stoolBar", Vector3(-3.0 + float(k) * 0.9, 0, -1.3), PI, [0.0], _calle() if k != 2 else [])
	_poner("comida/soda-bottle", Vector3(-2.6, _alto("desk", 1.8), -2.2), 0.0, 0.8)
	_poner("comida/glass", Vector3(-1.2, _alto("desk", 1.8), -2.2), 0.0, 1.0)
	## La tele con el partido y el estante de trofeos y camisetas firmadas.
	_poner("cabinetTelevision", Vector3(3.0, 0, -3.1), 0.0, 1.3)
	_poner("televisionModern", Vector3(3.0, _alto("cabinetTelevision", 1.3), -3.1), 0.0, 1.5)
	_poner("bookcaseClosedDoors", Vector3(4.5, 0, -1.6), -PI * 0.5, 1.1)
	for k in 3:
		_poner("comida/cup", Vector3(4.6, 0.62 + float(k) * 0.42, -1.1 - float(k) * 0.35), 0.0, 0.9, {"*": Color(0.95, 0.78, 0.2)})
	## Mesas con hinchas, la dianas y el futbolín al lado de la puerta.
	for p: Vector3 in [Vector3(0.6, 0, 0.2), Vector3(-3.0, 0, 1.8), Vector3(2.6, 0, 1.4)]:
		_poner("table", p, 0.0, 1.2)
		var top := _alto("table", 1.2)
		Mini3D.caja(_raiz, p + Vector3(0, top + 0.01, 0), Vector3(0.9, 0.02, 0.9), Mini3D.mat(_c1, 0.9))
		_poner("comida/mug", p + Vector3(0.2, top + 0.02, 0.1), 0.0, 0.7)
		_poner("comida/mug", p + Vector3(-0.25, top + 0.02, -0.15), 0.0, 0.7)
		_asiento("chair", p + Vector3(-0.8, 0, 0), PI * 0.5, [0.0], _calle())
		_asiento("chair", p + Vector3(0.8, 0, 0), -PI * 0.5, [0.0], _calle())
	Mini3D.cilindro(_raiz, Vector3(-4.8, 1.6, 0.5), 0.3, 0.03, Mini3D.mat(Color(0.1, 0.1, 0.12), 0.7)).rotation.z = PI * 0.5
	Mini3D.cilindro(_raiz, Vector3(-4.78, 1.6, 0.5), 0.2, 0.03, Mini3D.mat(_c1, 0.7)).rotation.z = PI * 0.5
	Mini3D.cilindro(_raiz, Vector3(-4.76, 1.6, 0.5), 0.07, 0.03, Mini3D.mat(_c2, 0.7)).rotation.z = PI * 0.5
	_planta(Vector3(4.5, 0, 2.8))
	_cartel("⚽ " + _sala_nombre().to_upper(), Vector3(0, 2.95, -3.45), 30, _c2)
