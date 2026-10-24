extends "res://ui/componentes/interior_instalacion_p3.gd"
## [Capa 4/7 de `interior_instalacion.gd`] _caja_cobro, _supermercado, _puesto_mercado, _mercado, _cine, _camiseta … (+15)

## Una caja de cobro del mini mercado (registradora en un extremo, cinta en el
## otro) con el cajero en su puesto, junto a la registradora, y un cliente al
## otro lado de la cinta si se pide.
func _caja_cobro(p: Vector3, giro: float, uniforme: Array, cliente: bool, tonos: Dictionary = {}) -> void:
	_poner("mini_mercado/cash-register", p, giro, null, tonos)
	var f := Vector3(sin(giro), 0, cos(giro))
	var lado := Vector3(cos(giro), 0, -sin(giro))
	_trabajador(p + f * 0.85 + lado * 0.45, giro + PI, false, ["saludo_mano", "charla"], uniforme)
	if cliente:
		_trabajador(p - f * 0.85 - lado * 0.2, giro, false, ["charla", "brazos_jarra"], _calle())

func _supermercado() -> void:
	_sala(Vector3(18, 3.8, 14), Color(0.86, 0.86, 0.84), Color(0.95, 0.95, 0.94), "losa", Color(0.2, 0.55, 0.35))
	var neutro := {"*": Color(0.95, 0.93, 0.9)}
	for z: float in [-4.6, -1.6, 1.2]:
		for k in 3:
			_poner("mini_mercado/shelf-boxes" if (k + int(z)) % 2 == 0 else "mini_mercado/shelf-bags", Vector3(-6.9 + float(k) * _medida("mini_mercado/shelf-boxes").x, 0, z), 0.0, null, neutro)
		_poner("mini_mercado/shelf-end", Vector3(-6.9 + 2.5 * _medida("mini_mercado/shelf-boxes").x + _medida("mini_mercado/shelf-end").z * 0.5, 0, z), -PI * 0.5, null, neutro)
	for z: float in [-5.6, -3.0, -0.4]:
		_poner("mini_mercado/freezers-standing", Vector3(8.5, 0, z), -PI * 0.5, null, neutro)
	for x: float in [1.4, 3.6]:
		_poner("mini_mercado/display-fruit", Vector3(x, 0, -3.2), 0.0, null, neutro)
	_poner("mini_mercado/display-bread", Vector3(1.4, 0, -5.4), 0.0, null, neutro)
	_poner("mini_mercado/freezer", Vector3(3.8, 0, -5.4), 0.0, null, neutro)
	_poner("mini_mercado/bottle-return", Vector3(-8.5, 0, 5.5), PI * 0.5, 1.6, neutro)
	## Dos cajas con su cajero sentado y la cola.
	for x: float in [3.2, 6.4]:
		_caja_cobro(Vector3(x, 0, 2.8), PI, [Color(0.85, 0.2, 0.15), Color(0.2, 0.22, 0.3), true], true, neutro)
	for k in 4:
		_poner("mini_mercado/shopping-cart", Vector3(-6.2 - float(k) * 0.12, 0, 5.4), 0.0, null, neutro)
	for k in 3:
		_caminante([Vector3(-8.0, 0, 3.0 - float(k) * 3.0), Vector3(0.4, 0, 3.0 - float(k) * 3.0), Vector3(0.4, 0, -0.1 - float(k) * 3.0), Vector3(-8.0, 0, -0.1 - float(k) * 3.0)], _calle())
	_planta(Vector3(8.4, 0, 6.4))
	_cartel("🛒 " + _sala_nombre().to_upper(), Vector3(0, 3.25, -6.95), 40)

## Un puesto del mercado: mostrador de 2,6 m con cajas de género, toldo de
## rayas, rótulo y el tendero detrás (mirando a +Z).
func _puesto_mercado(p: Vector3, datos: Array) -> void:
	var col: Color = datos[1]
	for k in 3:
		_poner("kitchenCabinet", p + Vector3(-0.86 + float(k) * 0.86, 0, 0), 0.0, null, {"wood": Color(0.6, 0.42, 0.26)})
	var largo := 2.58
	var tope := _alto("kitchenCabinet")
	## Cajas de madera inclinadas con el género.
	var caja_m := Mini3D.mat(Color(0.62, 0.45, 0.28), 0.8)
	var genero: Array = datos[2]
	for i in 4:
		var c := p + Vector3(-0.96 + float(i) * 0.64, tope, 0.05)
		Mini3D.caja(_raiz, c + Vector3(0, 0.05, 0), Vector3(0.58, 0.1, 0.5), caja_m)
		var cosa := "comida/" + String(genero[i % genero.size()])
		var m := _medida(cosa)
		var nx := clampi(int(0.5 / maxf(m.x, 0.06)), 1, 5)
		var nz := clampi(int(0.42 / maxf(m.z, 0.06)), 1, 4)
		for a in nx:
			for b in nz:
				_poner(cosa, c + Vector3((float(a) + 0.5) / float(nx) * 0.5 - 0.25, 0.1, (float(b) + 0.5) / float(nz) * 0.42 - 0.21), _rng.randf_range(-0.4, 0.4))
	## Una caja grande en el suelo, delante, con la pieza gorda (sandías, piñas...).
	for cosa: String in datos[3]:
		var cx := _rng.randf_range(-0.8, 0.8)
		Mini3D.caja(_raiz, p + Vector3(cx, 0.15, 0.75), Vector3(0.6, 0.3, 0.45), caja_m)
		for q in 2:
			_poner("comida/" + cosa, p + Vector3(cx - 0.14 + float(q) * 0.28, 0.3, 0.75), _rng.randf() * TAU)
	_poner("mini_mercado/cash-register", p + Vector3(largo * 0.5 + 0.55, 0, -0.2), -PI * 0.5, 1.2)
	## Postes, toldo a rayas y rótulo.
	var poste := Mini3D.mat(Color(0.3, 0.3, 0.32), 0.4)
	for s: float in [-1.0, 1.0]:
		Mini3D.cilindro(_raiz, p + Vector3(s * 1.45, 1.25, -0.9), 0.04, 2.5, poste)
	for r in 6:
		var toldo := Mini3D.caja(_raiz, p + Vector3(-1.25 + float(r) * 0.5, 2.45, -0.35), Vector3(0.5, 0.04, 1.3), Mini3D.mat(col if r % 2 == 0 else Color(0.97, 0.95, 0.9), 0.8))
		toldo.rotation.x = 0.2
	Mini3D.caja(_raiz, p + Vector3(0, 2.75, -0.9), Vector3(2.4, 0.45, 0.06), Mini3D.mat(col.darkened(0.2), 0.7))
	_cartel(String(datos[0]), p + Vector3(0, 2.75, -0.85), 30)
	_trabajador(p + Vector3(_rng.randf_range(-0.6, 0.6), 0, -0.75), 0.0, false, ["saludo_mano", "charla", "aplaudir"], [Color.WHITE, col.darkened(0.3), true])

## Mercado de abastos (22 × 16 m) y supermercado (18 × 14 m).
func _mercado() -> void:
	if clave.begins_with("edificio_mercado"):
		_supermercado()
		return
	_tonos_sala = _MADERA_OSCURA
	_sala(Vector3(22, 5.0, 16), Color(0.6, 0.57, 0.52), Color(0.88, 0.82, 0.72), "losa", Color(0.45, 0.55, 0.5))
	var puestos := [
		["🍎 FRUTAS", Color(0.95, 0.5, 0.1), ["apple", "orange", "pear", "lemon", "banana", "grapes"], ["pineapple", "watermelon"]],
		["🥬 VERDURAS", Color(0.3, 0.65, 0.2), ["tomato", "carrot", "eggplant", "corn", "broccoli", "cabbage"], ["pumpkin"]],
		["🐟 PESCADOS", Color(0.2, 0.45, 0.8), ["fish", "fish", "fish"], ["fish"]],
		["🥩 CARNES", Color(0.85, 0.15, 0.12), ["meat-raw", "whole-ham", "meat-raw"], ["whole-ham"]],
		["🧀 QUESOS", Color(0.95, 0.8, 0.2), ["cheese", "cheese"], ["cheese"]],
		["🥖 PAN", Color(0.7, 0.45, 0.25), ["loaf", "loaf-baguette", "croissant", "loaf-round"], ["cake"]],
	]
	var sitios := [Vector3(-7.5, 0, -4.6), Vector3(0, 0, -4.6), Vector3(7.5, 0, -4.6), Vector3(-6.5, 0, 1.4), Vector3(6.5, 0, 1.4), Vector3(0, 0, 1.0)]
	for k in puestos.size():
		_puesto_mercado(sitios[k], puestos[k])
	for k in 4:
		var z := -2.2 + float(k) * 0.5
		_caminante([Vector3(-9.5, 0, z), Vector3(9.5, 0, z)], _calle())
	_caminante([Vector3(-3.0, 0, 4.0), Vector3(-3.0, 0, -1.5), Vector3(3.0, 0, -1.5), Vector3(3.0, 0, 4.0)], _calle())
	_cartel("🍊 MERCADO DE ABASTOS", Vector3(0, 4.3, -7.95), 48)

## Cine (18 × 18 m): pantalla, gradas con butacas tapizadas y el público.
func _cine() -> void:
	_sala(Vector3(18, 6.0, 18), Color(0.32, 0.08, 0.1), Color(0.28, 0.1, 0.12), "moqueta", Color(0.18, 0.05, 0.07))
	_pantalla(Vector3(0, 3.2, -8.9), Vector2(13.0, 5.0), Color(0.75, 0.85, 1.0))
	_cartel("🎬 ESTRENO", Vector3(0, 3.2, -8.8), 96, Color(0.1, 0.1, 0.2))
	var butaca := Vector3(1.35, 2.0, 2.0)
	var tela := {"carpet": Color(0.65, 0.08, 0.1), "wood": Color(0.25, 0.08, 0.08)}
	var grada := Mini3D.mat(Color(0.22, 0.06, 0.08), 0.9)
	for i in 6:
		var y := float(i) * 0.38
		var z := -2.4 + float(i) * 1.15
		if i > 0:
			Mini3D.caja(_raiz, Vector3(0, y * 0.5, z), Vector3(13.6, y, 1.15), grada)
		for j in 16:
			var p := Vector3(-5.7 + float(j) * 0.76, y, z)
			_asiento("loungeChair", p, PI, [0.0] if _rng.randf() < 0.3 else [], _calle(), butaca, tela)
		## Luces de pasillo en cada escalón.
		for s: float in [-1.0, 1.0]:
			Mini3D.caja(_raiz, Vector3(s * 6.85, y + 0.02, z + 0.5), Vector3(0.1, 0.04, 0.1), Mini3D.mat(Color(1.0, 0.8, 0.4), 0.3, 2.0))
	for s: float in [-1.0, 1.0]:
		Mini3D.caja(_raiz, Vector3(s * 8.97, 2.4, 7.4), Vector3(0.05, 0.3, 0.9), Mini3D.mat(Color(0.2, 0.9, 0.3), 0.3, 1.5))
		_cartel("SALIDA", Vector3(s * 8.93, 2.4, 7.4), 20, Color.WHITE, -s * PI * 0.5)
	_caminante([Vector3(-7.6, 0, 7.5), Vector3(-7.6, 0, -5.5), Vector3(7.6, 0, -5.5), Vector3(7.6, 0, 7.5)])

## Una camiseta (colgada en una barra o plegada en una mesa) con dos colores.
func _camiseta(p: Vector3, giro: float, c1: Color, c2: Color, plegada: bool = false) -> void:
	var n := Node3D.new()
	n.position = p
	n.rotation.y = giro
	_raiz.add_child(n)
	var m1 := Mini3D.mat(c1, 0.85)
	var m2 := Mini3D.mat(c2, 0.85)
	if plegada:
		Mini3D.caja(n, Vector3(0, 0.03, 0), Vector3(0.34, 0.06, 0.28), m1)
		Mini3D.caja(n, Vector3(0, 0.062, -0.1), Vector3(0.12, 0.005, 0.05), m2)
		return
	Mini3D.caja(n, Vector3(0, -0.36, 0), Vector3(0.48, 0.62, 0.03), m1)
	Mini3D.caja(n, Vector3(0, -0.36, 0.017), Vector3(0.1, 0.62, 0.005), m2)
	for s: float in [-1.0, 1.0]:
		var manga := Mini3D.caja(n, Vector3(s * 0.3, -0.16, 0), Vector3(0.2, 0.18, 0.03), m1)
		manga.rotation.z = s * 0.5
	Mini3D.caja(n, Vector3(0, -0.06, 0.012), Vector3(0.14, 0.04, 0.01), m2)
	## Percha.
	Mini3D.caja(n, Vector3(0, -0.03, 0), Vector3(0.36, 0.02, 0.02), Mini3D.mat(Color(0.3, 0.2, 0.12), 0.6))

## Barra de ropa con camisetas colgadas, de `largo` m, mirando a `giro`.
func _perchero(p: Vector3, giro: float, largo: float, c1: Color, c2: Color) -> void:
	var lado := Vector3(cos(giro), 0, -sin(giro))
	var metal := Mini3D.mat(Color(0.7, 0.72, 0.75), 0.25)
	metal.metallic = 0.8
	for s: float in [-1.0, 1.0]:
		Mini3D.cilindro(_raiz, p + lado * (s * largo * 0.5) + Vector3(0, 0.8, 0), 0.02, 1.6, metal)
	var barra := Mini3D.cilindro(_raiz, p + Vector3(0, 1.6, 0), 0.015, largo, metal)
	barra.rotation = Vector3(0, giro, PI * 0.5)
	var n := int(largo / 0.56)
	for k in n:
		var x := (float(k) + 0.5) / float(n) * largo - largo * 0.5
		var alterna := k % 3 == 2
		_camiseta(p + lado * x + Vector3(0, 1.6, 0), giro + _rng.randf_range(-0.06, 0.06), c2 if alterna else c1, c1 if alterna else c2)

func _tienda_club() -> void:
	_tonos_sala = _MADERA_OSCURA
	## Pared del fondo y laterales con camisetas del club colgadas.
	for x: float in [-4.65, -1.55, 1.55, 4.65]:
		_perchero(Vector3(x, 0, -4.65), 0.0, 2.8, _c1, _c2)
	for z: float in [-2.0, 0.9]:
		_perchero(Vector3(-6.6, 0, z), PI * 0.5, 2.6, _c2, _c1)
	_perchero(Vector3(6.6, 0, -2.0), -PI * 0.5, 2.6, _c1, _c2)
	## Alfombra con los colores del club en el centro.
	Mini3D.caja(_raiz, Vector3(0, 0.006, 1.0), Vector3(4.0, 0.012, 2.4), Mini3D.mat(_c1.darkened(0.15), 0.95))
	Mini3D.caja(_raiz, Vector3(0, 0.008, 1.0), Vector3(3.6, 0.012, 2.0), Mini3D.mat(_c2, 0.95))
	Mini3D.caja(_raiz, Vector3(0, 0.01, 1.0), Vector3(3.3, 0.012, 1.7), Mini3D.mat(_c1, 0.95))
	## Mesas con camisetas plegadas en montones.
	for x: float in [-3.6, 0.0, 3.6]:
		var p := Vector3(x, 0, -1.5)
		_poner("table", p, 0.0, 2.2)
		var alto_m := _alto("table", 2.2)
		for i in 4:
			for pila in _rng.randi_range(2, 4):
				_camiseta(p + Vector3(-0.66 + float(i) * 0.44, alto_m + float(pila) * 0.06, _rng.randf_range(-0.1, 0.1)), _rng.randf_range(-0.1, 0.1), _c1 if (i + pila) % 3 != 2 else _c2, _c2 if (i + pila) % 3 != 2 else _c1, true)
	## Balones y bufandas en un expositor.
	## Expositor de balones y bufandas junto a la pared.
	for k in 3:
		_poner("bookcaseOpenLow", Vector3(-6.72, 0, 2.6 + float(k) * 0.82), PI * 0.5)
		for b in 2:
			Mini3D.esfera(_raiz, Vector3(-6.72, 0.88, 2.4 + float(k) * 0.82 + float(b) * 0.4), 0.11, Mini3D.mat(Color.WHITE if (k + b) % 2 == 0 else _c1, 0.5))
			Mini3D.caja(_raiz, Vector3(-6.72, 0.44, 2.4 + float(k) * 0.82 + float(b) * 0.4), Vector3(0.3, 0.06, 0.3), Mini3D.mat(_c2 if b == 0 else _c1, 0.9))
	## Caja con el dependiente con los colores del club.
	_caja_cobro(Vector3(4.8, 0, 2.6), PI * 0.5, [_c1, _c2, true], true)
	_trabajador(Vector3(-5.6, 0, -0.5), PI * 0.5, false, ["charla", "senalar_cielo"], [_c1, _c2, true])
	_trabajador(Vector3(1.9, 0, -0.4), PI * 0.8, false, ["charla"], _calle())
	for k in 3:
		var z := 0.5 + float(k) * 0.9
		_caminante([Vector3(-5.2, 0, z + 1.3), Vector3(2.4, 0, z + 1.3), Vector3(2.4, 0, -0.5), Vector3(-5.2, 0, -0.5)], _calle())

func _tienda_calle() -> void:
	var neutro := {"*": Color(0.95, 0.93, 0.9)}
	## Dos pasillos de góndolas con cabeceras.
	for z: float in [-2.9, 0.0]:
		for k in 3:
			_poner("mini_mercado/shelf-boxes" if k != 1 else "mini_mercado/shelf-bags", Vector3(-5.0 + float(k) * _medida("mini_mercado/shelf-boxes").x, 0, z), 0.0, null, neutro)
		_poner("mini_mercado/shelf-end", Vector3(-5.0 + 2.5 * _medida("mini_mercado/shelf-boxes").x + _medida("mini_mercado/shelf-end").z * 0.5, 0, z), -PI * 0.5, null, neutro)
	## Neveras contra la pared derecha, congelador y la caja.
	for z: float in [-3.7, -1.3]:
		_poner("mini_mercado/freezers-standing", Vector3(6.5, 0, z), -PI * 0.5, null, neutro)
	_poner("mini_mercado/freezer", Vector3(2.6, 0, -3.9), 0.0, null, neutro)
	_poner("mini_mercado/display-fruit", Vector3(2.6, 0, -1.6), 0.0, null, neutro)
	_caja_cobro(Vector3(4.6, 0, 2.6), PI * 0.5, [Color(0.2, 0.5, 0.8), Color(0.2, 0.22, 0.3), true], false, neutro)
	_poner("mini_mercado/shopping-cart", Vector3(-3.0, 0, 4.0), 0.3, null, neutro)
	_poner("mini_mercado/shopping-cart", Vector3(-3.5, 0, 4.1), 0.2, null, neutro)
	for k in 3:
		_poner("mini_mercado/shopping-basket", Vector3(2.6 + float(k) * 0.05, float(k) * 0.12, 4.3), 0.1 * float(k), null, neutro)
	_poner("mini_arcade/vending-machine", Vector3(-6.3, 0, 2.6), PI * 0.5, 2.2)
	_trabajador(Vector3(-2.0, 0, -1.45), PI * 0.5, false, ["charla", "brazos_jarra"], _calle())
	for k in 3:
		_caminante([Vector3(-5.6, 0, 1.4 + float(k) * 0.4), Vector3(1.4, 0, 1.4 + float(k) * 0.4), Vector3(1.4, 0, -1.45), Vector3(-5.6, 0, -1.45)], _calle())

## Tiendas (16 × 12 m): la del club con su ropa; las demás (centro comercial,
## gasolinera, farmacia...) con góndolas, neveras y caja del mini mercado.
func _tienda() -> void:
	_sala(Vector3(14, 3.4, 10), Color(0.88, 0.87, 0.85), Color(0.96, 0.96, 0.95), "losa")
	if clave == "com":
		_tienda_club()
	else:
		_tienda_calle()
	_planta(Vector3(-6.4, 0, 4.4))
	_planta(Vector3(6.4, 0, 4.4))
	_cartel("🛍️ " + _sala_nombre().to_upper(), Vector3(0, 2.95, -4.95), 36, Color(1.0, 0.9, 0.6) if clave == "com" else Color.WHITE)

## Cinta de correr; quien corre mira a −Z local (consola).
func _cinta(t: Transform3D, hierro: Color, acero: Color) -> void:
	_prim("caja", Vector3(0, 0.11, 0.05), Vector3(0.82, 0.22, 1.95), hierro, "goma", Vector3.ZERO, t)
	_prim("caja", Vector3(0, 0.225, 0.1), Vector3(0.52, 0.012, 1.7), Color(0.05, 0.05, 0.06), "goma", Vector3.ZERO, t)
	for s: float in [-1.0, 1.0]:
		_prim("caja", Vector3(s * 0.34, 0.23, 0.1), Vector3(0.14, 0.02, 1.7), acero, "metal", Vector3.ZERO, t)
		_prim("caja", Vector3(s * 0.36, 0.72, -0.78), Vector3(0.06, 1.0, 0.07), acero, "metal", Vector3(0.18, 0, 0), t)
		_prim("caja", Vector3(s * 0.36, 1.12, -0.5), Vector3(0.05, 0.05, 0.55), Color(0.2, 0.2, 0.22), "goma", Vector3.ZERO, t)
	_prim("caja", Vector3(0, 1.3, -0.82), Vector3(0.8, 0.32, 0.1), Color(0.2, 0.2, 0.22), "mate", Vector3(-0.5, 0, 0), t)
	_prim("caja", Vector3(0, 1.31, -0.77), Vector3(0.5, 0.2, 0.01), Color(0.2, 0.55, 0.85), "luz", Vector3(-0.5, 0, 0), t)

## Bici estática mirando a −Z local; devuelve el centro del sillín (global).
func _bici(t: Transform3D, hierro: Color, acero: Color) -> Vector3:
	_prim("caja", Vector3(0, 0.04, 0), Vector3(0.5, 0.08, 1.2), hierro, "goma", Vector3.ZERO, t)
	_prim("cil", Vector3(0, 0.33, -0.55), Vector3(0.5, 0.08, 0.5), acero, "metal", Vector3(0, 0, PI * 0.5), t)
	_prim("caja", Vector3(0, 0.33, -0.55), Vector3(0.1, 0.3, 0.3), Color(0.8, 0.15, 0.12), "goma", Vector3.ZERO, t)
	_prim("caja", Vector3(0, 0.45, -0.1), Vector3(0.08, 0.08, 0.9), hierro, "goma", Vector3(0.35, 0, 0), t)
	_prim("caja", Vector3(0, 0.55, 0.3), Vector3(0.07, 0.6, 0.07), hierro, "goma", Vector3(-0.25, 0, 0), t)
	_prim("caja", Vector3(0, 0.82, 0.38), Vector3(0.24, 0.07, 0.3), Color(0.08, 0.08, 0.09), "goma", Vector3.ZERO, t)
	_prim("caja", Vector3(0, 0.72, -0.38), Vector3(0.07, 0.75, 0.07), hierro, "goma", Vector3(0.3, 0, 0), t)
	_prim("caja", Vector3(0, 1.08, -0.28), Vector3(0.55, 0.05, 0.1), Color(0.2, 0.2, 0.22), "goma", Vector3.ZERO, t)
	for s: float in [-1.0, 1.0]:
		_prim("caja", Vector3(s * 0.25, 1.1, -0.18), Vector3(0.05, 0.05, 0.22), Color(0.2, 0.2, 0.22), "goma", Vector3.ZERO, t)
	_prim("caja", Vector3(0, 1.2, -0.38), Vector3(0.24, 0.15, 0.04), Color(0.2, 0.55, 0.85), "luz", Vector3(-0.4, 0, 0), t)
	_prim("cil", Vector3(0, 0.36, -0.05), Vector3(0.16, 0.06, 0.16), acero, "metal", Vector3(0, 0, PI * 0.5), t)
	for s: float in [-1.0, 1.0]:
		_prim("caja", Vector3(s * 0.14, 0.3, -0.05), Vector3(0.08, 0.025, 0.14), Color(0.08, 0.08, 0.09), "goma", Vector3.ZERO, t)
	return t * Vector3(0, 0.86, 0.38)

## Máquina de poleas: dos torres con su pila de placas, travesaño de dominadas
## y los cables con sus agarres.
func _poleas(t: Transform3D, hierro: Color, acero: Color, cromo: Color) -> void:
	for s: float in [-1.0, 1.0]:
		var x := s * 1.3
		for dx: float in [-0.22, 0.22]:
			_prim("caja", Vector3(x + dx, 1.15, 0), Vector3(0.08, 2.3, 0.08), hierro, "goma", Vector3.ZERO, t)
		_prim("caja", Vector3(x, 0.03, 0), Vector3(0.6, 0.06, 0.5), hierro, "goma", Vector3.ZERO, t)
		for k in 12:
			_prim("caja", Vector3(x, 0.1 + float(k) * 0.055, 0), Vector3(0.34, 0.05, 0.2), Color(0.25, 0.25, 0.27) if k % 2 == 0 else Color(0.3, 0.3, 0.32), "metal", Vector3.ZERO, t)
		_prim("caja", Vector3(x, 1.2, 0.0), Vector3(0.02, 1.8, 0.02), cromo, "metal", Vector3.ZERO, t)
		_prim("cil", Vector3(x - s * 0.22, 2.0, 0.1), Vector3(0.14, 0.04, 0.14), acero, "metal", Vector3(PI * 0.5, 0, 0), t)
		_prim("caja", Vector3(x - s * 0.35, 1.6, 0.25), Vector3(0.012, 0.85, 0.012), Color(0.1, 0.1, 0.1), "goma", Vector3(0.4, 0, -s * 0.15), t)
		_prim("caja", Vector3(x - s * 0.45, 1.2, 0.42), Vector3(0.14, 0.03, 0.03), Color(0.12, 0.12, 0.12), "goma", Vector3.ZERO, t)
	_prim("caja", Vector3(0, 2.3, 0), Vector3(3.1, 0.1, 0.1), hierro, "goma", Vector3.ZERO, t)
	_prim("cil", Vector3(0, 2.15, 0.15), Vector3(0.035, 1.6, 0.035), cromo, "metal", Vector3(0, 0, PI * 0.5), t)
	_prim("caja", Vector3(0, 2.3, 0.06), Vector3(1.2, 0.08, 0.01), _c1, "mate", Vector3.ZERO, t)

## Rack de mancuernas de dos baldas inclinadas (frente hacia +Z local), con
## diez pares de peso creciente.
func _rack_mancuernas(t: Transform3D, hierro: Color, cromo: Color) -> void:
	var largo := 3.2
	for x: float in [-largo * 0.5, 0.0, largo * 0.5]:
		_prim("caja", Vector3(x, 0.4, 0), Vector3(0.06, 0.8, 0.55), hierro, "goma", Vector3.ZERO, t)
	for b in 2:
		var y := 0.42 + float(b) * 0.36
		var z := 0.1 - float(b) * 0.2
		_prim("caja", Vector3(0, y, z), Vector3(largo, 0.04, 0.32), hierro, "goma", Vector3(0.2, 0, 0), t)
		for k in 10:
			var x := -largo * 0.5 + 0.17 + float(k) * 0.32
			var peso := float(k) / 9.0
			var r := 0.085 + peso * 0.05 - float(b) * 0.015
			_prim("cil", Vector3(x, y + r + 0.02, z), Vector3(0.035, 0.32, 0.035), cromo, "metal", Vector3(PI * 0.5, 0, 0), t)
			for s: float in [-1.0, 1.0]:
				_prim("cil", Vector3(x, y + r + 0.02, z + s * (0.12 + peso * 0.03)), Vector3(r * 2.0, 0.07 + peso * 0.04, r * 2.0), Color(0.1, 0.1, 0.11), "goma", Vector3(PI * 0.5, 0, 0), t)
	_prim("caja", Vector3(0, 0.95, -0.25), Vector3(largo, 0.1, 0.03), _c1, "mate", Vector3.ZERO, t)

## Banco plano de pesas, a lo largo de Z local.
func _banco_pesas(t: Transform3D, hierro: Color, acero: Color) -> void:
	_prim("caja", Vector3(0, 0.42, 0), Vector3(0.3, 0.08, 1.15), Color(0.1, 0.1, 0.12), "goma", Vector3.ZERO, t)
	for z: float in [-0.45, 0.45]:
		_prim("caja", Vector3(0, 0.19, z), Vector3(0.08, 0.38, 0.08), acero, "metal", Vector3.ZERO, t)
		_prim("caja", Vector3(0, 0.02, z), Vector3(0.45, 0.04, 0.08), acero, "metal", Vector3.ZERO, t)

## Jaula de sentadillas (frente +Z local) con la barra cargada en los ganchos
## y el árbol de discos al lado.
func _jaula(t: Transform3D, hierro: Color, cromo: Color) -> void:
	for x: float in [-0.6, 0.6]:
		for z: float in [-0.55, 0.55]:
			_prim("caja", Vector3(x, 1.15, z), Vector3(0.08, 2.3, 0.08), hierro, "goma", Vector3.ZERO, t)
		_prim("caja", Vector3(x, 2.28, 0), Vector3(0.08, 0.08, 1.18), hierro, "goma", Vector3.ZERO, t)
		_prim("caja", Vector3(x, 0.03, 0), Vector3(0.1, 0.06, 1.3), hierro, "goma", Vector3.ZERO, t)
	for z: float in [-0.55, 0.55]:
		_prim("caja", Vector3(0, 2.28, z), Vector3(1.28, 0.08, 0.08), hierro, "goma", Vector3.ZERO, t)
	_prim("caja", Vector3(0, 0.005, 0), Vector3(1.2, 0.01, 1.1), Color(0.45, 0.33, 0.22), "mate", Vector3.ZERO, t)
	_prim("cil", Vector3(0, 1.38, 0.55), Vector3(0.03, 2.2, 0.03), cromo, "metal", Vector3(0, 0, PI * 0.5), t)
	for s: float in [-1.0, 1.0]:
		for k in 2:
			_prim("cil", Vector3(s * (0.78 + float(k) * 0.06), 1.38, 0.55), Vector3(0.45 - float(k) * 0.12, 0.05, 0.45 - float(k) * 0.12),
				[Color(0.75, 0.15, 0.15), Color(0.2, 0.4, 0.8)][k], "goma", Vector3(0, 0, PI * 0.5), t)
	## Árbol de discos.
	var arbol := Vector3(-1.2, 0, -0.3)
	_prim("caja", arbol + Vector3(0, 0.55, 0), Vector3(0.06, 1.1, 0.06), hierro, "goma", Vector3.ZERO, t)
	_prim("caja", arbol + Vector3(0, 0.02, 0), Vector3(0.5, 0.04, 0.5), hierro, "goma", Vector3.ZERO, t)
	for k in 3:
		for s: float in [-1.0, 1.0]:
			var dm := 0.45 - float(k) * 0.1
			_prim("cil", arbol + Vector3(0, 0.3 + float(k) * 0.3, s * 0.08), Vector3(dm, 0.05, dm),
				[Color(0.75, 0.15, 0.15), Color(0.2, 0.4, 0.8), Color(0.9, 0.75, 0.15)][k], "goma", Vector3(PI * 0.5, 0, 0), t)

## Estantería en A con dos baldas de balones medicinales (frente +Z local).
func _estante_balones(t: Transform3D, hierro: Color) -> void:
	for x: float in [-0.7, 0.7]:
		_prim("caja", Vector3(x, 0.5, 0), Vector3(0.05, 1.0, 0.5), hierro, "goma", Vector3.ZERO, t)
	var cols := [Color(0.75, 0.2, 0.15), Color(0.2, 0.2, 0.22), Color(0.25, 0.45, 0.8), Color(0.9, 0.7, 0.15), Color(0.3, 0.6, 0.3)]
	for b in 2:
		var y := 0.25 + float(b) * 0.45
		_prim("caja", Vector3(0, y, 0), Vector3(1.4, 0.03, 0.4), hierro, "goma", Vector3.ZERO, t)
		for k in 5:
			var dm := 0.24 + float(k % 3) * 0.02
			_prim("esf", Vector3(-0.54 + float(k) * 0.27, y + 0.015 + dm * 0.5, 0), Vector3.ONE * dm, cols[(k + b * 2) % cols.size()], "goma", Vector3.ZERO, t)

## Posición de un hueso (pose actual) en el espacio de `nodo`.
static func _hueso_local(nodo: Node3D, sk: Skeleton3D, hueso: String) -> Vector3:
	var b := sk.find_bone(hueso)
	if b < 0:
		return Vector3.ZERO
	var t := sk.get_bone_global_pose(b)
	var n: Node = sk
	while n != null and n != nodo:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t.origin

## Persona tumbada boca arriba (la caída del pack, congelada en su último fotograma).
func _tumbado(p: Vector3, giro: float, deporte: Array) -> void:
	var d := Mini3D.persona(_raiz, _rng, p, deporte)
	if d.is_empty():
		return
	(d["nodo"] as Node3D).rotation.y = giro
	Mini3D.anim(d, "caida_lesion", "", 0.0)
	var ap: AnimationPlayer = d["anim"]
	ap.seek(ap.current_animation_length, true)
	## El clip acaba con el cuerpo lejos de su origen y girado: se mide dónde
	## quedan la cabeza y los pies y se recoloca para que el cuerpo quede
	## centrado en `p` con la cabeza hacia `giro`.
	var nodo: Node3D = d["nodo"]
	var esq: Array = nodo.find_children("*", "Skeleton3D", true, false)
	if esq.is_empty():
		return
	var sk: Skeleton3D = esq[0]
	var cab := _hueso_local(nodo, sk, "Head")
	var pies := (_hueso_local(nodo, sk, "foot_l") + _hueso_local(nodo, sk, "foot_r")) * 0.5
	var eje := cab - pies
	if Vector2(eje.x, eje.z).length() < 0.3:
		return
	var th := giro - atan2(eje.x, eje.z)
	var mitad := (cab + pies) * 0.5
	mitad.y = 0.0
	nodo.rotation.y = th
	nodo.position = p - Basis(Vector3.UP, th) * mitad

## Fuente de agua contra la pared izquierda con su garrafa y vasos.
func _fuente_agua(p: Vector3, acero: Color, cromo: Color) -> void:
	_prim("caja", p + Vector3(0, 0.5, 0), Vector3(0.36, 1.0, 0.36), Color(0.88, 0.88, 0.9))
	_prim("caja", p + Vector3(0.05, 0.85, 0), Vector3(0.3, 0.12, 0.3), acero, "metal")
	_prim("cil", p + Vector3(0, 1.22, 0), Vector3(0.28, 0.42, 0.28), Color(0.45, 0.68, 0.95), "luz")
	_prim("cil", p + Vector3(0, 1.0, 0), Vector3(0.1, 0.04, 0.1), Color(0.3, 0.5, 0.85))
	_prim("caja", p + Vector3(0.2, 0.92, 0), Vector3(0.04, 0.04, 0.04), cromo, "metal")
	_prim("cil", p + Vector3(0.05, 0.95, 0.35), Vector3(0.08, 0.3, 0.08), Color(0.92, 0.92, 0.94))

## Estantería abierta con toallas dobladas (blancas y del club).
func _toallero(p: Vector3) -> void:
	var madera := Color(0.62, 0.48, 0.32)
	for z: float in [-0.6, 0.6]:
		_prim("caja", p + Vector3(0, 0.8, z), Vector3(0.4, 1.6, 0.04), madera)
	for b in 4:
		var y := 0.15 + float(b) * 0.45
		_prim("caja", p + Vector3(0, y, 0), Vector3(0.4, 0.03, 1.2), madera)
		for k in 3:
			for n in 3 - (b + k) % 2:
				_prim("caja", p + Vector3(0.02, y + 0.05 + float(n) * 0.075, -0.38 + float(k) * 0.38), Vector3(0.3, 0.07, 0.32), Color(0.95, 0.95, 0.96) if (k + b) % 3 != 1 else _c1)
