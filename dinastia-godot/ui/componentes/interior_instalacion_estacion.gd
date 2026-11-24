extends "res://ui/componentes/interior_instalacion_p3.gd"
## La estación (`_estacion`) y sus secciones: capa aparte (la norma de 450 líneas). Las secciones llaman a _prim, _texto y _sala de la capa 3.

func _estacion() -> void:
	_tonos_sala = _MADERA_OSCURA
	_sala(Vector3(24, 7.0, 15), Color(0.74, 0.7, 0.63), Color(0.88, 0.83, 0.74), "losa", Color(0.5, 0.4, 0.32))
	_estacion_suelo()
	_estacion_columnas()
	_estacion_lamparas()
	_estacion_fondo()
	_estacion_taquillas()
	_estacion_quiosco()
	_estacion_cafeteria()
	_estacion_bancos()
	_estacion_reloj()
	_estacion_plantas()
## Sección de la estación: suelo (el mismo orden de llamadas que antes, dentro de _estacion).
func _estacion_suelo() -> void:
	var laton := Color(0.78, 0.62, 0.3)
	## --- Suelo: cenefa oscura junto a las paredes y la rosa de los vientos.
	for s: float in [-1.0, 1.0]:
		_prim("caja", Vector3(0, 0.005, s * 7.0), Vector3(23.0, 0.01, 0.35), Color(0.42, 0.36, 0.3))
		_prim("caja", Vector3(s * 11.5, 0.005, 0), Vector3(0.35, 0.01, 14.0), Color(0.42, 0.36, 0.3))
	var rosa := Vector3(0, 0, 1.2)
	_prim("cil", rosa + Vector3(0, 0.004, 0), Vector3(2.8, 0.008, 2.8), Color(0.3, 0.33, 0.3))
	_prim("cil", rosa + Vector3(0, 0.008, 0), Vector3(2.5, 0.008, 2.5), Color(0.86, 0.82, 0.72))
	for k in 8:
		var largo := 2.3 if k % 2 == 0 else 1.5
		_prim("caja", rosa + Vector3(0, 0.012, 0), Vector3(0.16, 0.006, largo), Color(0.55, 0.18, 0.14) if k % 2 == 0 else Color(0.2, 0.2, 0.22), "mate", Vector3(0, float(k) * PI * 0.25, 0))
	_prim("cil", rosa + Vector3(0, 0.016, 0), Vector3(0.36, 0.006, 0.36), laton, "metal")


## Sección de la estación: columnas (el mismo orden de llamadas que antes, dentro de _estacion).
func _estacion_columnas() -> void:
	var laton := Color(0.78, 0.62, 0.3)
	var crema := Color(0.9, 0.86, 0.78)
	## --- Columnas con basa, anillo de latón y capitel.
	for p: Vector3 in [Vector3(-8.4, 0, -2.6), Vector3(-3.2, 0, -2.6), Vector3(3.2, 0, -2.6), Vector3(8.4, 0, -2.6), Vector3(-3.2, 0, 3.4), Vector3(3.2, 0, 3.4)]:
		_prim("caja", p + Vector3(0, 0.2, 0), Vector3(0.95, 0.4, 0.95), Color(0.62, 0.58, 0.52))
		_prim("cil", p + Vector3(0, 3.2, 0), Vector3(0.62, 5.6, 0.62), crema)
		_prim("cil", p + Vector3(0, 2.3, 0), Vector3(0.68, 0.08, 0.68), laton, "metal")
		_prim("caja", p + Vector3(0, 6.12, 0), Vector3(0.82, 0.24, 0.82), crema)
		_prim("caja", p + Vector3(0, 6.35, 0), Vector3(1.0, 0.22, 1.0), Color(0.8, 0.76, 0.68))


## Sección de la estación: lamparas (el mismo orden de llamadas que antes, dentro de _estacion).
func _estacion_lamparas() -> void:
	var hierro := Color(0.16, 0.16, 0.18)
	var laton := Color(0.78, 0.62, 0.3)
	## --- Lámparas colgadas: cable, campana de latón y globo encendido.
	for p: Vector3 in [Vector3(-6.0, 0, -0.6), Vector3(6.0, 0, -0.6), Vector3(-6.0, 0, 4.6), Vector3(6.0, 0, 4.6), Vector3(0, 0, 4.8)]:
		_prim("cil", p + Vector3(0, 6.2, 0), Vector3(0.025, 1.6, 0.025), hierro)
		_prim("cono", p + Vector3(0, 5.3, 0), Vector3(0.5, 0.22, 0.5), laton, "metal")
		_prim("esf", p + Vector3(0, 5.0, 0), Vector3.ONE * 0.62, Color(1.0, 0.95, 0.82), "luz")


## Sección de la estación: fondo (el mismo orden de llamadas que antes, dentro de _estacion).
func _estacion_fondo() -> void:
	var acero := Color(0.68, 0.7, 0.73)
	var oscuro := Color(0.06, 0.07, 0.09)
	var ambar := Color(1.0, 0.78, 0.22)
	## --- El fondo: panel de salidas, las bocas de los andenes y los tornos.
	_prim("caja", Vector3(0, 5.0, -7.42), Vector3(9.4, 2.5, 0.12), Color(0.3, 0.3, 0.33), "metal")
	_prim("caja", Vector3(0, 5.0, -7.36), Vector3(9.0, 2.2, 0.04), oscuro)
	_texto("SALIDAS", Vector3(-4.2, 5.88, -7.32), 26, Color(1.0, 1.0, 1.0), 0.0, false, HORIZONTAL_ALIGNMENT_LEFT)
	for col: Array in [["HORA", -4.2], ["DESTINO", -2.9], ["VÍA", 0.75], ["OBSERVACIONES", 1.75]]:
		_texto(String(col[0]), Vector3(float(col[1]), 5.55, -7.32), 15, Color(0.7, 0.75, 0.8), 0.0, false, HORIZONTAL_ALIGNMENT_LEFT)
	_texto("10:15\n10:22\n10:30\n10:41\n10:55", Vector3(-4.2, 4.62, -7.32), 21, ambar, 0.0, false, HORIZONTAL_ALIGNMENT_LEFT)
	_texto("PUERTO\nALTO NORTE\nRIBERA\nAEROPUERTO\nCOSTA AZUL", Vector3(-2.9, 4.62, -7.32), 21, ambar, 0.0, false, HORIZONTAL_ALIGNMENT_LEFT)
	_texto("2\n1\n3\n1\n2", Vector3(0.75, 4.62, -7.32), 21, ambar, 0.0, false, HORIZONTAL_ALIGNMENT_LEFT)
	_texto("A TIEMPO\nEMBARCANDO\nRETRASO 5'\nA TIEMPO\nA TIEMPO", Vector3(1.75, 4.62, -7.32), 21, Color(0.55, 1.0, 0.6), 0.0, false, HORIZONTAL_ALIGNMENT_LEFT)
	var vias := ["VÍA 1 · 10:22 ALTO NORTE", "VÍA 2 · 10:15 PUERTO", "VÍA 3 · 10:30 RIBERA"]
	for k in 3:
		var x := -2.6 + float(k) * 2.6
		## La boca del andén (oscura, con el andén iluminado al fondo) y su marco.
		_prim("caja", Vector3(x, 1.5, -7.47), Vector3(2.0, 3.0, 0.03), Color(0.16, 0.17, 0.21))
		_prim("caja", Vector3(x, 2.75, -7.452), Vector3(1.9, 0.05, 0.01), Color(0.95, 0.95, 0.88), "luz")
		_prim("caja", Vector3(x, 1.25, -7.452), Vector3(1.9, 0.3, 0.01), Color(0.75, 0.75, 0.78))
		_prim("caja", Vector3(x, 1.1, -7.451), Vector3(1.9, 0.04, 0.01), Color(0.85, 0.15, 0.15))
		_prim("caja", Vector3(x, 0.35, -7.455), Vector3(2.0, 0.7, 0.01), Color(0.32, 0.33, 0.36))
		_prim("caja", Vector3(x, 0.72, -7.45), Vector3(2.0, 0.05, 0.01), Color(0.95, 0.8, 0.15))
		for s: float in [-1.0, 1.0]:
			_prim("caja", Vector3(x + s * 1.05, 1.55, -7.42), Vector3(0.1, 3.1, 0.12), acero, "metal")
		_prim("caja", Vector3(x, 3.08, -7.42), Vector3(2.2, 0.12, 0.12), acero, "metal")
		_prim("caja", Vector3(x, 3.42, -7.4), Vector3(2.0, 0.42, 0.1), oscuro)
		_texto(String(vias[k]), Vector3(x, 3.42, -7.34), 15, Color(0.55, 1.0, 0.6), 0.0, false)
	## Tornos: cinco cuerpos de acero; los dos del centro abiertos (por ahí pasa
	## la gente), el resto con sus aletas de cristal cerradas.
	var zt := -4.6
	for k in 5:
		var x := -3.0 + float(k) * 1.5
		_prim("caja", Vector3(x, 0.5, zt), Vector3(0.28, 1.0, 1.25), acero, "metal")
		_prim("caja", Vector3(x, 1.02, zt), Vector3(0.32, 0.05, 1.28), Color(0.14, 0.14, 0.16))
		_prim("caja", Vector3(x, 1.055, zt + 0.38), Vector3(0.18, 0.02, 0.16), Color(0.3, 0.95, 0.4), "luz")
		_prim("caja", Vector3(x, 1.055, zt - 0.38), Vector3(0.18, 0.02, 0.16), Color(0.95, 0.3, 0.25), "luz")
		for s: float in [-1.0, 1.0]:
			var paso := x + s * 0.75
			if absf(paso) < 1.0 or absf(paso) > 3.5:
				continue
			_prim("caja", Vector3(x + s * 0.37, 0.72, zt), Vector3(0.46, 0.62, 0.025), Color(0.7, 0.8, 0.88), "luz")
	for s: float in [-1.0, 1.0]:
		_prim("caja", Vector3(s * 3.9, 0.55, zt), Vector3(1.1, 0.04, 0.04), acero, "metal")
		for x: float in [3.4, 4.4]:
			_prim("cil", Vector3(s * x, 0.55, zt), Vector3(0.06, 1.1, 0.06), acero, "metal")
	_prim("caja", Vector3(0, 0.006, zt + 0.95), Vector3(7.0, 0.012, 0.3), Color(0.95, 0.8, 0.15))
	_trabajador(Vector3(4.1, 0, -3.9), PI * 0.85, false, ["brazos_jarra", "charla", "senalar_adelante"], [Color(0.12, 0.14, 0.22), Color(0.12, 0.14, 0.22), true])
	_cartel("🚉 " + _sala_nombre().to_upper(), Vector3(0, 6.55, -7.4), 52)


## Sección de la estación: taquillas (el mismo orden de llamadas que antes, dentro de _estacion).
func _estacion_taquillas() -> void:
	var hierro := Color(0.16, 0.16, 0.18)
	var acero := Color(0.68, 0.7, 0.73)
	var azul_rotulo := Color(0.12, 0.24, 0.48)
	## --- Taquillas (fondo a la izquierda): tres puestos tras el cristal, el
	## mostrador, el rótulo y la fila con sus postes de cinta.
	for k in 3:
		_puesto(Vector3(-9.6 + float(k) * 2.4, 0, -6.0), 0.0)
	for k in 4:
		_prim("caja", Vector3(-10.8 + float(k) * 2.4, 1.45, -5.55), Vector3(0.08, 1.4, 0.12), Color(0.35, 0.25, 0.18))
	Mini3D.caja(_raiz, Vector3(-7.2, 1.45, -5.55), Vector3(7.2, 1.3, 0.03), Mini3D.mat(Color(0.8, 0.9, 1.0, 0.25), 0.05))
	_prim("caja", Vector3(-7.2, 0.38, -5.55), Vector3(7.3, 0.76, 0.12), Color(0.35, 0.25, 0.18))
	_prim("caja", Vector3(-7.2, 0.78, -5.42), Vector3(7.3, 0.04, 0.3), Color(0.5, 0.36, 0.24))
	_prim("caja", Vector3(-7.2, 2.4, -5.55), Vector3(7.3, 0.55, 0.14), azul_rotulo)
	_cartel("BILLETES · INFORMACIÓN", Vector3(-7.2, 2.4, -5.47), 30)
	for x: float in [-7.5, -5.9]:
		for k in 4:
			var p := Vector3(x, 0, -4.4 + float(k) * 0.7)
			_prim("cil", p + Vector3(0, 0.47, 0), Vector3(0.05, 0.94, 0.05), acero, "metal")
			_prim("cil", p + Vector3(0, 0.015, 0), Vector3(0.3, 0.03, 0.3), hierro, "metal")
			if k < 3:
				_prim("caja", p + Vector3(0, 0.86, 0.35), Vector3(0.02, 0.06, 0.7), Color(0.6, 0.12, 0.14), "goma")
	_trabajador(Vector3(-9.6, 0, -4.95), PI, false, ["charla", "brazos_jarra"], _calle())
	_trabajador(Vector3(-7.2, 0, -4.95), PI, false, ["charla", "saludo_mano"], _calle())
	for z: float in [-3.75, -3.0]:
		_trabajador(Vector3(-6.7, 0, z), PI, false, ["brazos_jarra", "charla", "parado"], _calle())
	_maleta(Vector3(-6.35, 0, -3.0), 0.3, Color(0.55, 0.15, 0.18), true)
	## Máquinas de billetes y la consigna (pared izquierda).
	_poner("mini_arcade/ticket-machine", Vector3(-11.5, 0, -1.6), PI * 0.5)
	_poner("mini_arcade/ticket-machine", Vector3(-11.5, 0, -0.6), PI * 0.5)
	for i in 4:
		for j in 3:
			var p := Vector3(-11.72, 0.42 + float(j) * 0.62, 1.7 + float(i) * 0.62)
			_prim("caja", p, Vector3(0.55, 0.6, 0.6), Color(0.42, 0.45, 0.5), "metal")
			_prim("caja", p + Vector3(0.28, 0, 0), Vector3(0.01, 0.52, 0.52), Color(0.78, 0.6, 0.2) if (i + j) % 4 == 1 else Color(0.62, 0.66, 0.7))
			_prim("caja", p + Vector3(0.29, 0.12, 0.17), Vector3(0.01, 0.08, 0.1), Color(0.3, 0.9, 0.4), "luz")
	_prim("caja", Vector3(-11.72, 2.2, 2.63), Vector3(0.56, 0.06, 2.6), hierro)
	_cartel("CONSIGNA", Vector3(-11.9, 2.6, 2.63), 30, Color.WHITE, PI * 0.5)


## Sección de la estación: quiosco (el mismo orden de llamadas que antes, dentro de _estacion).
func _estacion_quiosco() -> void:
	## --- Quiosco (fondo a la derecha): mostrador con prensa y golosinas.
	var ancho := _medida("kitchenBar", 2.5).x
	for k in 3:
		_poner("kitchenBar", Vector3(6.2 + float(k) * ancho, 0, -4.8), 0.0, 2.5)
	var tope := _alto("kitchenBar", 2.5)
	for k in 8:
		_poner("books", Vector3(5.9 + float(k) * 0.28, tope, -4.8), _rng.randf_range(-0.2, 0.2), 1.8)
	for k in 4:
		_poner(["comida/chocolate", "comida/candy-bar", "comida/soda-can", "comida/lollypop"][k], Vector3(8.3 + float(k) * 0.22, tope, -4.75), _rng.randf() * TAU)
	for x: float in [6.6, 7.4, 8.2]:
		_poner("bookcaseOpen", Vector3(x, 0, -7.25), 0.0)
		for b in 3:
			_poner("books", Vector3(x, 0.42 + float(b) * 0.5, -7.25), 0.0)
	_prim("caja", Vector3(7.5, 2.6, -4.55), Vector3(3.6, 0.45, 0.1), Color(0.62, 0.12, 0.14))
	_cartel("PRENSA · REVISTAS", Vector3(7.5, 2.6, -4.48), 26)
	_trabajador(Vector3(7.2, 0, -5.8), 0.0, false, ["saludo_mano", "charla"], _calle())
	_trabajador(Vector3(6.9, 0, -3.95), PI, false, ["charla", "brazos_jarra"], _calle())
	for z: float in [-1.8, -0.7]:
		_poner("mini_arcade/vending-machine", Vector3(11.45, 0, z), -PI * 0.5, 2.2)


## Sección de la estación: cafeteria (el mismo orden de llamadas que antes, dentro de _estacion).
func _estacion_cafeteria() -> void:
	var hierro := Color(0.16, 0.16, 0.18)
	var oscuro := Color(0.06, 0.07, 0.09)
	## --- Cafetería (delante a la derecha): barra, cafetera, vitrina, carta y
	## mesas altas con gente tomando algo.
	var bar_ancho := _medida("kitchenBar", 2.5).x
	for k in 3:
		_poner("kitchenBar", Vector3(9.7, 0, 2.2 + float(k) * bar_ancho), -PI * 0.5, 2.5, {"wood": Color(0.42, 0.26, 0.16), "woodDark": Color(0.3, 0.18, 0.1)})
	var tope_bar := _alto("kitchenBar", 2.5)
	var z_fin := 2.2 + 2.0 * bar_ancho
	for k in 3:
		_poner("kitchenCabinet", Vector3(11.65, 0, 2.3 + float(k) * 1.0), -PI * 0.5)
	var tope_mueble := _alto("kitchenCabinet")
	_poner("kitchenCoffeeMachine", Vector3(11.65, tope_mueble, 2.4), -PI * 0.5)
	_poner("kitchenCoffeeMachine", Vector3(11.65, tope_mueble, 3.2), -PI * 0.5)
	for k in 6:
		_poner("comida/cup-saucer", Vector3(11.6, tope_mueble, 3.9 + float(k % 3) * 0.14), 0.0)
	## Vitrina de bollería sobre la barra.
	_prim("caja", Vector3(9.7, tope_bar + 0.2, z_fin - 0.3), Vector3(0.5, 0.4, 1.0), Color(0.82, 0.9, 0.95), "luz")
	for k in 6:
		_poner(["comida/croissant", "comida/donut-sprinkles", "comida/muffin"][k % 3], Vector3(9.7 + (0.1 if k < 3 else -0.1), tope_bar + 0.02, z_fin - 0.65 + float(k % 3) * 0.3), 0.0)
	for k in 3:
		_poner("comida/cup-coffee", Vector3(9.55, tope_bar, 2.4 + float(k) * 0.5), _rng.randf() * TAU)
	_prim("caja", Vector3(11.96, 3.1, 3.4), Vector3(0.04, 1.3, 2.6), oscuro)
	_texto("☕ CAFETERÍA\nCafé  1,20 · Cortado  1,40\nCroissant  1,50 · Bocadillo  3,50", Vector3(11.92, 3.1, 3.4), 22, Color(1.0, 0.92, 0.75), -PI * 0.5, false)
	_trabajador(Vector3(10.85, 0, 3.0), -PI * 0.5, false, ["charla", "saludo_mano", "brazos_jarra"], [Color(0.95, 0.95, 0.93), Color(0.15, 0.12, 0.1), true])
	_asiento("stoolBar", Vector3(8.95, 0, 4.0), PI * 0.5, [0.0], _calle())
	_poner("stoolBar", Vector3(8.95, 0, 3.1), PI * 0.5)
	for z: float in [2.4, 4.8]:
		var p := Vector3(7.3, 0, z)
		_prim("cil", p + Vector3(0, 0.015, 0), Vector3(0.5, 0.03, 0.5), hierro, "metal")
		_prim("cil", p + Vector3(0, 0.55, 0), Vector3(0.07, 1.08, 0.07), hierro, "metal")
		_prim("cil", p + Vector3(0, 1.1, 0), Vector3(0.75, 0.04, 0.75), Color(0.85, 0.82, 0.76))
		_poner("comida/cup-coffee", p + Vector3(0.12, 1.12, 0.05), _rng.randf() * TAU)
		_poner("comida/croissant", p + Vector3(-0.12, 1.12, -0.08), _rng.randf() * TAU)
	_trabajador(Vector3(6.75, 0, 2.4), PI * 0.5, false, ["charla", "brazos_jarra", "saludo_mano"], _calle())
	_trabajador(Vector3(7.8, 0, 2.55), -PI * 0.5, false, ["charla", "pedir_calma"], _calle())
	_trabajador(Vector3(7.35, 0, 5.3), PI, false, ["charla", "parado"], _calle())


## Sección de la estación: bancos (el mismo orden de llamadas que antes, dentro de _estacion).
func _estacion_bancos() -> void:
	## --- Bancos de espera, espalda con espalda, con alguna maleta al lado.
	for x: float in [-5.9, 5.9]:
		for s: float in [-1.0, 1.0]:
			for k in 4:
				var p := Vector3(x - 1.2 + float(k) * 0.8, 0, 0.3 + s * 0.24)
				_asiento("bench", p, 0.0 if s > 0.0 else PI, [0.0] if _rng.randf() < 0.4 else [], _calle())
	_maleta(Vector3(-7.45, 0, 1.2), 0.2, Color(0.2, 0.3, 0.45), true)
	_maleta(Vector3(4.35, 0, -0.55), -0.4, Color(0.12, 0.12, 0.14), false)
	_maleta(Vector3(7.5, 0, 1.15), 1.4, Color(0.75, 0.55, 0.2), true)
	## Viajeros con maleta mirando el panel.
	var cols_maleta := [Color(0.2, 0.25, 0.35), Color(0.6, 0.12, 0.15), Color(0.25, 0.45, 0.35)]
	for k in 3:
		var p: Vector3 = [Vector3(-2.3, 0, -3.3), Vector3(2.2, 0, -3.2), Vector3(5.5, 0, -2.9)][k]
		_trabajador(p, PI + float(k - 1) * 0.25, false, ["charla", "brazos_jarra", "senalar_cielo"], _calle())
		_maleta(p + Vector3(0.42, 0, 0.12), 0.1 * float(k), cols_maleta[k], k != 1)


## Sección de la estación: reloj (el mismo orden de llamadas que antes, dentro de _estacion).
func _estacion_reloj() -> void:
	var hierro := Color(0.16, 0.16, 0.18)
	var azul_rotulo := Color(0.12, 0.24, 0.48)
	## --- Reloj de doble esfera colgado sobre el vestíbulo (a un lado: en medio
	## tapaba el panel de salidas desde la puerta).
	var pr := Vector3(-5.8, 4.3, -1.0)
	_prim("cil", pr + Vector3(0, 1.7, 0), Vector3(0.05, 2.6, 0.05), hierro, "metal")
	_prim("cil", pr, Vector3(1.3, 0.2, 1.3), Color(0.2, 0.2, 0.22), "metal", Vector3(PI * 0.5, 0, 0))
	_reloj(Transform3D(Basis.IDENTITY, pr + Vector3(0, 0, 0.1)), 0.58, 10.27)
	_reloj(Transform3D(Basis(Vector3.UP, PI), pr - Vector3(0, 0, 0.1)), 0.58, 10.27)
	## Cartel de dirección colgado: andenes hacia el fondo, salida hacia la puerta.
	var pc := Vector3(0, 3.3, 3.0)
	for s: float in [-1.0, 1.0]:
		_prim("cil", pc + Vector3(s * 1.3, 1.9, 0), Vector3(0.02, 3.4, 0.02), hierro)
	_prim("caja", pc, Vector3(3.6, 0.6, 0.08), azul_rotulo)
	_prim("caja", pc, Vector3(3.7, 0.68, 0.06), Color(0.9, 0.9, 0.92))
	_texto("↑  ANDENES · VÍAS 1-3", pc + Vector3(0, 0, 0.05), 30, Color.WHITE, 0.0, false)
	_texto("↓  SALIDA · TAXI · BUS", pc - Vector3(0, 0, 0.05), 30, Color.WHITE, PI, false)
	## Anuncios iluminados en las paredes laterales.
	for s: float in [-1.0, 1.0]:
		var p := Vector3(s * 11.95, 3.6, -3.8)
		_prim("caja", p, Vector3(0.08, 1.8, 2.9), Color(0.25, 0.25, 0.27), "metal")
		_prim("caja", p - Vector3(s * 0.05, 0, 0), Vector3(0.02, 1.6, 2.7), Color(0.35, 0.6, 0.85) if s < 0.0 else Color(0.9, 0.55, 0.25), "luz")
	_texto("VISITA LA COSTA\nen tren, sin prisas", Vector3(-11.88, 3.6, -3.8), 30, Color.WHITE, PI * 0.5)
	_texto("NUEVO AEROPUERTO\nun tren cada 15'", Vector3(11.88, 3.6, -3.8), 30, Color.WHITE, -PI * 0.5)


## Sección de la estación: plantas (el mismo orden de llamadas que antes, dentro de _estacion).
func _estacion_plantas() -> void:
	var cols_maleta := [Color(0.2, 0.25, 0.35), Color(0.6, 0.12, 0.15), Color(0.25, 0.45, 0.35)]
	## --- Plantas, papeleras y la gente que va y viene.
	for p: Vector3 in [Vector3(-11.2, 0, 6.7), Vector3(11.2, 0, 6.7), Vector3(-11.2, 0, -6.9), Vector3(11.2, 0, -6.9)]:
		_planta(p)
	for p: Vector3 in [Vector3(-4.4, 0, -2.6), Vector3(4.4, 0, -2.6), Vector3(-2.4, 0, 3.4)]:
		_poner("trashcan", p, 0.0, 1.4)
	## Rutas fijas (sin desvío): a los tornos abiertos y de vuelta, cruzando el
	## vestíbulo entre las columnas y los bancos, y de la puerta a la cafetería.
	var rutas := [
		[Vector3(-0.75, 0, 6.2), Vector3(-0.75, 0, -6.3)],
		[Vector3(0.75, 0, -6.3), Vector3(0.75, 0, 6.2)],
		[Vector3(-10.4, 0, -1.4), Vector3(10.2, 0, -1.4)],
		[Vector3(9.8, 0, -1.25), Vector3(-10.2, 0, -1.25)],
		[Vector3(-7.6, 0, 2.15), Vector3(-1.6, 0, 5.6), Vector3(1.6, 0, 5.6), Vector3(5.4, 0, 2.15)],
		[Vector3(1.4, 0, 6.0), Vector3(5.6, 0, 3.6), Vector3(5.6, 0, 6.2)],
	]
	for k in rutas.size():
		var ruta: Array = rutas[k]
		_caminante(ruta, _calle(), k == 2)
		if _caminantes.is_empty():
			continue
		var c: Dictionary = _caminantes[-1]
		c["puntos"] = ruta
		var a: Vector3 = ruta[0]
		var b: Vector3 = ruta[1]
		(c["d"]["nodo"] as Node3D).position = a.lerp(b, _rng.randf_range(0.15, 0.85))
		c["i"] = 1
		## Algunos tiran de su maleta de ruedas.
		if k == 1 or k == 3:
			_maleta_de(c["d"]["nodo"], cols_maleta[k % 3])
