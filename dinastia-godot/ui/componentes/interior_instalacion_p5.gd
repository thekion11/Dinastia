extends "res://ui/componentes/interior_instalacion_p4.gd"
## [Capa 5/7 de `interior_instalacion.gd`] _gimnasio, _analisis, _cocina, _comedor, _prensa, _museo

## Gimnasio y recuperación (16 × 12 m, 16-10-2026: «que parezca el gimnasio de
## un club de verdad y lleno de vida»). Zonas sobre suelo de goma: cardio al
## fondo (cintas y bicis ante el espejo, teles con datos), pista de césped con
## escalera de agilidad y conos, zona de fuerza a la derecha (poleas, rack de
## mancuernas, bancos, jaula de sentadillas, kettlebells), zona funcional en el
## centro (cajones, balones medicinales, fitballs), estiramientos y camilla del
## fisio a la izquierda, y delante el banco de vestuario y la mesa del
## preparador con la pantalla de GPS. Casi todo el equipo va en lotes
## (`_prim`, `_poner`): cientos de piezas a pocas llamadas de dibujo.
func _gimnasio() -> void:
	_tonos_sala = _MADERA_CLARA
	var goma := Color(0.17, 0.17, 0.19)
	_sala(Vector3(16, 4.2, 12), goma, Color(0.88, 0.88, 0.9), "moqueta", _c1.darkened(0.55))
	var dep := [_c1, _c2]
	var hierro := Color(0.12, 0.12, 0.13)
	var cromo := Color(0.78, 0.79, 0.82)
	var acero := Color(0.42, 0.44, 0.47)
	var blanco := Color(0.94, 0.94, 0.95)
	## --- Suelo por zonas: losetas de cardio, pista de césped, damero de
	## fuerza y la zona funcional con su borde del color del club.
	_prim("caja", Vector3(-2.2, 0.005, -4.7), Vector3(11.2, 0.01, 2.6), Color(0.22, 0.24, 0.29))
	for i in 11:
		_prim("caja", Vector3(-7.8 + float(i) * 1.12, 0.012, -4.7), Vector3(0.02, 0.005, 2.6), Color(0.13, 0.14, 0.17))
	_prim("caja", Vector3(-2.2, 0.006, -2.15), Vector3(11.2, 0.012, 1.7), Color(0.2, 0.42, 0.2))
	for z: float in [-2.97, -1.33]:
		_prim("caja", Vector3(-2.2, 0.014, z), Vector3(11.2, 0.006, 0.05), blanco)
	for i in 6:
		_prim("caja", Vector3(-7.4 + float(i) * 2.0, 0.014, -2.15), Vector3(0.05, 0.006, 1.6), blanco)
	for i in 4:
		for j in 9:
			var claro := (i + j) % 2 == 0
			_prim("caja", Vector3(4.1 + float(i) * 1.0, 0.007, -5.45 + float(j) * 1.0), Vector3(0.98, 0.014, 0.98),
				Color(0.26, 0.26, 0.28) if claro else Color(0.2, 0.2, 0.22))
	_prim("caja", Vector3(0.7, 0.006, 1.05), Vector3(5.2, 0.012, 3.7), Color(0.3, 0.31, 0.33))
	for s: float in [-1.0, 1.0]:
		_prim("caja", Vector3(0.7, 0.014, 1.05 + s * 1.82), Vector3(5.2, 0.006, 0.06), _c1)
		_prim("caja", Vector3(0.7 + s * 2.57, 0.014, 1.05), Vector3(0.06, 0.006, 3.7), _c1)
	## --- Paredes: franja del club, espejo largo, teles y altavoces.
	for z: float in [-5.99]:
		_prim("caja", Vector3(0, 2.75, z), Vector3(16, 0.18, 0.02), _c1)
	for s: float in [-1.0, 1.0]:
		_prim("caja", Vector3(s * 7.99, 2.75, 0), Vector3(0.02, 0.18, 12), _c1)
	Mini3D.caja(_raiz, Vector3(-2.2, 1.35, -5.98), Vector3(10.8, 2.1, 0.02), Mini3D.mat(Color(0.62, 0.68, 0.74), 0.04, 0.08))
	_prim("caja", Vector3(-2.2, 0.27, -5.97), Vector3(10.9, 0.06, 0.04), cromo, "metal")
	_prim("caja", Vector3(-2.2, 2.43, -5.97), Vector3(10.9, 0.06, 0.04), cromo, "metal")
	var datos_tv := ["RITMO  5:12 /km\nFC  152 ppm", "CARGA  ▲ 8 %\nRPE  6,4", "SPRINTS  118\nVEL. MÁX  33,1"]
	for k in 3:
		var x := -6.0 + float(k) * 3.0
		_pantalla(Vector3(x, 3.25, -5.95), Vector2(1.3, 0.72), Color(0.12, 0.3, 0.5))
		_cartel(String(datos_tv[k]), Vector3(x, 3.25, -5.9), 16, Color(0.85, 1.0, 0.9))
	for p: Vector3 in [Vector3(-7.72, 3.2, -5.72), Vector3(7.72, 3.2, -5.72), Vector3(-7.72, 3.2, 5.6), Vector3(7.72, 3.2, 5.6)]:
		_prim("caja", p + Vector3(0, -0.06, 0), Vector3(0.25, 0.04, 0.25), hierro)
		_poner("speakerSmall", p, atan2(-p.x, -p.z))
	_cartel("💪 " + _sala_nombre().to_upper(), Vector3(4.6, 3.55, -5.95), 34)
	_cartel("ESFUERZO · EQUIPO · VICTORIA", Vector3(-7.96, 3.2, 1.2), 30, _c1.lightened(0.25), PI * 0.5)
	## --- Cardio: cuatro cintas (tres en marcha) y tres bicis.
	for k in 4:
		var t := Transform3D(Basis.IDENTITY, Vector3(-7.0 + float(k) * 1.4, 0, -4.6))
		_cinta(t, hierro, acero)
		if k != 2:
			var d := Mini3D.persona(_raiz, _rng, t.origin + Vector3(0, 0.25, 0.15), dep)
			if not d.is_empty():
				(d["nodo"] as Node3D).rotation.y = PI
				Mini3D.anim(d, "trotar", "")
				(d["anim"] as AnimationPlayer).seek(_rng.randf(), true)
	_prim("caja", Vector3(-4.2 + 0.42, 1.38, -5.4), Vector3(0.5, 0.05, 0.3), blanco, "mate", Vector3(0, 0, 0.1))
	for k in 3:
		var t := Transform3D(Basis.IDENTITY, Vector3(-0.9 + float(k) * 1.25, 0, -4.75))
		var sillin := _bici(t, hierro, acero)
		if k != 1:
			_trabajador(Vector3(sillin.x, 0, sillin.z - 0.05), PI, true, [], dep, sillin.y)
	## --- Fuerza: poleas al fondo a la derecha con alguien haciendo press.
	_poleas(Transform3D(Basis.IDENTITY, Vector3(6.0, 0, -5.45)), hierro, acero, cromo)
	_trabajador(Vector3(6.0, 0, -4.55), 0.0, false, ["empujar", "empujar", "cansado"], dep)
	## Rack de mancuernas contra la pared derecha y su par de bancos.
	_rack_mancuernas(Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(7.5, 0, -1.6)), hierro, cromo)
	for z: float in [-2.6, -0.6]:
		_banco_pesas(Transform3D(Basis.IDENTITY, Vector3(5.3, 0, z)), hierro, acero)
	_trabajador(Vector3(5.3, 0, -2.6), PI * 0.5, true, [], dep, 0.46)
	_trabajador(Vector3(4.4, 0, -0.4), PI * 0.5, false, ["charla", "brazos_jarra", "pedir_calma"], dep)
	_poner("trashcan", Vector3(4.2, 0, -3.35), 0.0, 1.4)
	## Jaula de sentadillas con su barra, el árbol de discos y las kettlebells.
	_jaula(Transform3D(Basis.IDENTITY, Vector3(5.3, 0, 1.9)), hierro, cromo)
	var colores_kb := [Color(0.85, 0.3, 0.5), Color(0.25, 0.45, 0.85), Color(0.95, 0.8, 0.2), Color(0.55, 0.3, 0.7), Color(0.3, 0.7, 0.35), Color(0.9, 0.5, 0.15)]
	for k in 6:
		var r := 0.17 + float(k) * 0.018
		var p := Vector3(7.45, 0, 0.45 + float(k) * 0.33)
		_prim("esf", p + Vector3(0, r * 0.5, 0), Vector3.ONE * r, colores_kb[k], "goma")
		_prim("caja", p + Vector3(0, r * 1.0 + 0.04, 0), Vector3(0.03, 0.03, r * 0.75), hierro)
		for s: float in [-1.0, 1.0]:
			_prim("caja", p + Vector3(0, r * 0.9, s * r * 0.36), Vector3(0.03, 0.12, 0.03), hierro)
	_trabajador(Vector3(6.75, 0, 1.3), PI * 0.5, false, ["recoger_balon", "parado", "cansado"], dep)
	## --- Pista de césped: escalera de agilidad, conos y alguien que esprinta.
	for i in 12:
		_prim("caja", Vector3(-6.6 + float(i) * 0.42, 0.02, -2.15), Vector3(0.04, 0.012, 0.5), Color(0.98, 0.85, 0.1))
	for s: float in [-1.0, 1.0]:
		_prim("caja", Vector3(-6.6 + 11.0 * 0.21, 0.018, -2.15 + s * 0.25), Vector3(4.66, 0.008, 0.025), Color(0.98, 0.85, 0.1))
	for k in 6:
		var p := Vector3(-1.4 + float(k) * 0.8, 0, -2.15 + (0.52 if k % 2 == 0 else -0.52))
		_prim("cono", p + Vector3(0, 0.12, 0), Vector3(0.2, 0.24, 0.2), Color(1.0, 0.45, 0.08), "goma")
		_prim("caja", p + Vector3(0, 0.008, 0), Vector3(0.24, 0.016, 0.24), Color(1.0, 0.45, 0.08))
	_caminante([Vector3(-7.2, 0, -2.15), Vector3(2.8, 0, -2.15)], dep, true)
	if not _caminantes.is_empty():
		## Por el centro de la pista, sin el desvío al azar: entre los conos.
		_caminantes[-1]["puntos"] = [Vector3(-7.2, 0, -2.15), Vector3(2.8, 0, -2.15)]
		(_caminantes[-1]["d"]["nodo"] as Node3D).position.z = -2.15
	## --- Zona funcional: cajones pliométricos, balones medicinales y fitballs.
	var altos := [0.3, 0.5, 0.75]
	for k in 3:
		var p := Vector3(-1.2 + float(k) * 1.0, 0, -0.25)
		var h: float = altos[k]
		_prim("caja", p + Vector3(0, h * 0.5, 0), Vector3(0.75, h, 0.6), Color(0.62, 0.45, 0.3) if k != 1 else Color(0.15, 0.15, 0.17))
		_prim("caja", p + Vector3(0, h + 0.004, 0), Vector3(0.7, 0.01, 0.55), Color(0.2, 0.2, 0.22))
		_prim("caja", p + Vector3(0, h * 0.5, 0.302), Vector3(0.3, 0.12, 0.004), _c1)
	_trabajador(Vector3(-0.2, 0, 0.55), PI, false, ["saltar_inicio", "caer_salto", "saltar_inicio", "cansado"], dep)
	_estante_balones(Transform3D(Basis(Vector3.UP, PI), Vector3(2.75, 0, -0.35)), hierro)
	_prim("esf", Vector3(2.0, 0.13, 0.35), Vector3.ONE * 0.26, Color(0.75, 0.2, 0.15), "goma")
	var fit := [Color(0.25, 0.45, 0.8), _c1, Color(0.55, 0.57, 0.6), Color(0.25, 0.45, 0.8)]
	var sitios_fit := [Vector3(0.3, 0, 2.3), Vector3(1.35, 0, 2.55), Vector3(2.4, 0, 2.1), Vector3(2.75, 0, 1.2)]
	for k in 4:
		var dm := 0.65 if k != 3 else 0.55
		_prim("esf", (sitios_fit[k] as Vector3) + Vector3(0, dm * 0.5, 0), Vector3.ONE * dm, fit[k], "goma")
	_trabajador(Vector3(1.35, 0, 2.6), 0.0, true, [], dep, 0.6)
	## --- Estiramientos (izquierda): colchonetas, rulos y gomas.
	var mats := [Vector3(-5.3, 0, 0.4), Vector3(-3.4, 0, 0.4), Vector3(-5.3, 0, 2.0), Vector3(-3.4, 0, 2.0)]
	for k in 4:
		var p: Vector3 = mats[k]
		_prim("caja", p + Vector3(0, 0.02, 0), Vector3(1.8, 0.04, 0.85), _c1.darkened(0.15) if k % 2 == 0 else Color(0.25, 0.3, 0.38), "goma")
		_prim("cil", p + Vector3(0.75, 0.1, -0.3), Vector3(0.15, 0.6, 0.15), [Color(0.2, 0.2, 0.22), Color(0.3, 0.55, 0.85)][k % 2], "goma", Vector3(PI * 0.5, 0, 0))
	_prim("caja", Vector3(-3.0, 0.045, 0.62), Vector3(0.7, 0.01, 0.05), Color(0.9, 0.3, 0.3))
	_prim("caja", Vector3(-4.9, 0.045, 2.25), Vector3(0.6, 0.01, 0.05), Color(0.3, 0.75, 0.4))
	_trabajador(Vector3(-5.6, 0.04, 0.4), 0.0, false, ["agachado", "parado", "agachado", "agachado"], dep)
	_trabajador(Vector3(-3.3, 0.04, 0.35), PI * 0.3, false, ["atarse_botin"], dep)
	_tumbado(Vector3(-5.3, 0.04, 2.0), PI * 0.5, dep)
	_trabajador(Vector3(-3.6, 0.04, 2.0), PI * 0.15, false, ["brazos_al_frente", "cansado", "charla", "aplaudir"], dep)
	## --- Recuperación: fuente de agua, toallero, la camilla con el fisio.
	_fuente_agua(Vector3(-7.72, 0, -0.55), acero, cromo)
	_toallero(Vector3(-7.62, 0, 1.15))
	_prim("caja", Vector3(-6.8, 0.37, 3.7), Vector3(0.7, 0.06, 1.95), acero, "metal")
	for x: float in [-7.08, -6.52]:
		for z: float in [2.9, 4.5]:
			_prim("caja", Vector3(x, 0.18, z), Vector3(0.05, 0.36, 0.05), acero, "metal")
	_prim("caja", Vector3(-6.8, 0.48, 3.7), Vector3(0.72, 0.16, 1.95), Color(0.15, 0.2, 0.3), "goma")
	_prim("caja", Vector3(-6.8, 0.565, 4.45), Vector3(0.5, 0.01, 0.4), blanco)
	_tumbado(Vector3(-6.8, 0.56, 3.7), 0.0, dep)
	_trabajador(Vector3(-6.0, 0, 3.4), -PI * 0.5, false, ["charla", "pedir_calma", "brazos_jarra"], [Color(0.95, 0.95, 0.97), Color(0.14, 0.18, 0.32), true])
	_prim("caja", Vector3(-7.6, 0.4, 5.1), Vector3(0.5, 0.8, 0.45), blanco)
	_prim("caja", Vector3(-7.36, 0.6, 5.1), Vector3(0.02, 0.08, 0.08), Color(0.85, 0.15, 0.15))
	_planta(Vector3(-7.3, 0, 5.6))
	## --- Delante a la derecha: banco de vestuario, mochilas, la mesa del
	## preparador con su portátil y la pantalla de GPS.
	_asiento("benchCushionLow", Vector3(3.8, 0, 5.35), PI, [0.4], dep, Vector3(4.8, 2.2, 2.2), {"carpet": _c1.darkened(0.35), "wood": Color(0.62, 0.48, 0.32)})
	for k in 3:
		_prim("caja", Vector3(3.0 + float(k) * 0.35, 0.47, 5.35), Vector3(0.3, 0.05, 0.36), blanco if k != 1 else _c1)
	for k in 2:
		var p := Vector3(2.7 + float(k) * 2.1, 0, 4.95)
		_prim("caja", p + Vector3(0, 0.16, 0), Vector3(0.55, 0.32, 0.28), [Color(0.1, 0.1, 0.12), _c1.darkened(0.3)][k], "goma")
		_prim("cil", p + Vector3(0.38, 0.12, 0), Vector3(0.08, 0.24, 0.08), Color(0.25, 0.55, 0.9), "goma")
	var mesa_esc := 2.5
	_poner("kitchenBar", Vector3(6.5, 0, 4.82), -PI * 0.5, mesa_esc)
	_poner("kitchenBar", Vector3(6.5, 0, 3.75), -PI * 0.5, mesa_esc)
	var tope := _alto("kitchenBar", mesa_esc)
	_poner("laptop", Vector3(6.4, tope, 4.15), PI * 0.5, 2.0)
	_poner("comida/cup-coffee", Vector3(6.55, tope, 4.75), 0.3)
	_prim("caja", Vector3(6.5, tope + 0.01, 3.6), Vector3(0.22, 0.02, 0.3), blanco)
	_pantalla(Vector3(7.96, 2.0, 4.0), Vector2(2.2, 1.25), Color(0.08, 0.16, 0.22), -PI * 0.5)
	_cartel("GPS · SESIÓN DE HOY\nDistancia  6,8 km\nAlta intensidad  1.240 m\nSprints  22   ·   FC media  148", Vector3(7.9, 2.0, 4.0), 17, Color(0.6, 1.0, 0.75), -PI * 0.5)
	_trabajador(Vector3(5.7, 0, 4.2), PI * 0.5, false, ["senalar_adelante", "charla", "brazos_jarra", "aplaudir"], [_c1.darkened(0.5), Color(0.12, 0.12, 0.15), true])
	_poner("mini_arcade/vending-machine", Vector3(5.6, 0, 5.45), PI, 2.2)
	_planta(Vector3(2.6, 0, 5.6))
	_planta(Vector3(-2.6, 0, 5.6), false)
	_ventana(-1.0, -2.2, 2.0, false)

## Sala de vídeo / e-sports (14 × 10 m): ocho puestos mirando a la pantalla
## grande; en la de e-sports, además, máquinas recreativas y un sofá.
func _analisis() -> void:
	var esports := clave == "esports"
	_sala(Vector3(14, 3.4, 10), Color(0.2, 0.2, 0.24), Color(0.3, 0.32, 0.38), "moqueta", Color(0.16, 0.17, 0.2))
	_pantalla(Vector3(0, 1.65, -4.94), Vector2(5.6, 2.0), Color(0.2, 0.55, 0.3) if not esports else Color(0.55, 0.25, 0.7))
	_cartel("⚽ 4-3-3  ·  presión alta" if not esports else "🎮 TORNEO DEL CLUB", Vector3(0, 1.65, -4.87), 44)
	for i in 2:
		for j in 4:
			var p := Vector3(-4.5 + float(j) * 3.0, 0, -1.6 + float(i) * 2.4)
			_puesto(p, PI, true, true, [_c1, _c2] if esports else [])
	if esports:
		for z: float in [-3.6, -2.6, -1.6]:
			_poner("mini_arcade/arcade-machine", Vector3(6.45, 0, z), -PI * 0.5)
		_asiento("loungeSofa", Vector3(-6.55, 0, 2.6), PI * 0.5, [0.0], [_c1, _c2], null, {"carpet": Color(0.15, 0.15, 0.2)})
		_poner("mini_arcade/air-hockey", Vector3(5.6, 0, 2.6), PI * 0.5)
	else:
		_poner("bookcaseClosedDoors", Vector3(6.75, 0, -2.0), -PI * 0.5)
		Mini3D.caja(_raiz, Vector3(-6.97, 1.6, 1.0), Vector3(0.02, 1.2, 3.0), Mini3D.mat(Color(0.95, 0.95, 0.95), 0.6))
	_caminante([Vector3(-5.0, 0, -3.8), Vector3(5.0, 0, -3.8)])
	_cartel("📊 " + _sala_nombre().to_upper(), Vector3(0, 3.0, -4.94), 26)

## Una fila de muebles de cocina a lo largo de X (desde `x0`, de izquierda a
## derecha) contra la pared del fondo; devuelve la x donde acaba.
func _cocina(x0: float, z: float, piezas: Array, giro: float = 0.0, altos: bool = true) -> float:
	var x := x0
	for nombre: String in piezas:
		var m := _medida(nombre)
		x += m.x * 0.5
		_poner(nombre, Vector3(x, 0, z), giro)
		if altos and nombre != "kitchenFridgeLarge" and nombre != "kitchenFridge":
			if nombre == "kitchenStove" or nombre == "kitchenStoveElectric":
				_poner("hoodModern", Vector3(x, 1.55, z - m.z * 0.5 + 0.28), giro)
			else:
				_poner("kitchenCabinetUpper", Vector3(x, 1.5, z - m.z * 0.5 + 0.22), giro)
		x += m.x * 0.5
	return x

## Comedor (18 × 12 m): la cocina al fondo con su barra de servir y los
## cocineros; las mesas con los jugadores comiendo.
func _comedor() -> void:
	_tonos_sala = _MADERA_CLARA
	_sala(Vector3(18, 3.6, 12), Color(0.72, 0.64, 0.52), Color(0.96, 0.93, 0.86), "losa", Color(0.6, 0.48, 0.34))
	_cocina(-6.9, -6.0 + 0.45, ["kitchenFridgeLarge", "kitchenCabinet", "kitchenStove", "kitchenStove", "kitchenCabinetDrawer", "kitchenSink",
		"kitchenCabinet", "kitchenStoveElectric", "kitchenCabinet", "kitchenCabinetDrawer", "kitchenFridgeLarge"])
	var cocinero := [Color.WHITE, Color(0.2, 0.2, 0.22), true]
	for k in 3:
		_trabajador(Vector3(-4.0 + float(k) * 3.5, 0, -4.5), 0.0, false, ["charla", "pedir_calma", "saludo_mano"], cocinero)
	## Barra de servir con bandejas.
	var ancho := _medida("kitchenBar", 2.5).x
	for k in 8:
		_poner("kitchenBar", Vector3(-3.8 + float(k) * ancho, 0, -3.5), PI, 2.5, {"wood": Color(0.85, 0.86, 0.88), "woodDark": Color(0.6, 0.62, 0.65)})
	var tope := _alto("kitchenBar", 2.5)
	for k in 8:
		_poner(["comida/pot", "comida/bowl"][k % 2], Vector3(-3.8 + float(k) * ancho, tope, -3.5), 0.0)
	## Mesas con los jugadores comiendo.
	for i in 2:
		for j in 3:
			var p := Vector3(-5.5 + float(j) * 5.5, 0, -0.6 + float(i) * 3.0)
			_mesa_con_sillas(p, 0.0, "table", 2.2, 3, "chair", 0.6, [_c1, _c2], "comida/plate-dinner", ["comida/glass", "comida/salad", "comida/sandwich"])
	_ventana(-1.0, 0.8, 2.0)
	_ventana(1.0, 0.8, 2.0)
	_planta(Vector3(-8.4, 0, 5.4))
	_planta(Vector3(8.4, 0, 5.4))
	_cartel("🥗 " + _sala_nombre().to_upper(), Vector3(0, 3.05, -5.95), 34)

## Sala de prensa (14 × 11 m): panel de patrocinadores con los colores del club,
## mesa con el entrenador y un jugador, periodistas sentados y las cámaras.
func _prensa() -> void:
	_sala(Vector3(14, 3.6, 11), Color(0.22, 0.24, 0.32), Color(0.26, 0.3, 0.44), "moqueta")
	for i in 6:
		for j in 2:
			Mini3D.caja(_raiz, Vector3(-3.75 + float(i) * 1.5, 1.3 + float(j) * 1.1, -5.47), Vector3(1.48, 1.08, 0.04), Mini3D.mat(_c1 if (i + j) % 2 == 0 else _c2, 0.6))
	## La mesa sobre una tarima.
	Mini3D.caja(_raiz, Vector3(0, 0.1, -4.2), Vector3(6.0, 0.2, 2.2), Mini3D.mat(Color(0.12, 0.12, 0.15), 0.6))
	_poner("desk", Vector3(0, 0.2, -3.9), 0.0, Vector3(3.0, 2.0, 2.0), {"wood": Color(0.1, 0.1, 0.12), "woodDark": Color(0.1, 0.1, 0.12)})
	var tope := 0.2 + _alto("desk")
	for k in 2:
		var x := -0.8 + float(k) * 1.6
		_asiento("chairDesk", Vector3(x, 0.2, -4.75), 0.0, [0.0], [Color(0.1, 0.1, 0.12), Color(0.1, 0.1, 0.12), true] if k == 0 else [_c1, _c2])
		Mini3D.cilindro(_raiz, Vector3(x, tope + 0.15, -3.7), 0.012, 0.3, Mini3D.mat(Color(0.1, 0.1, 0.1), 0.3))
		Mini3D.esfera(_raiz, Vector3(x, tope + 0.32, -3.68), 0.035, Mini3D.mat(Color(0.15, 0.15, 0.15), 0.6))
		_poner("comida/soda-bottle", Vector3(x + 0.35, tope, -3.85), 0.0)
	## Periodistas sentados.
	for i in 3:
		for j in 6:
			var p := Vector3(-3.75 + float(j) * 1.5, 0, -1.3 + float(i) * 1.4)
			_asiento("chairModernCushion", p, PI, [0.0] if _rng.randf() < 0.75 else [], _calle(), null, {"carpet": Color(0.2, 0.2, 0.25)})
	## Las cámaras al fondo, a los lados del pasillo.
	for x: float in [-4.6, -2.6, 2.6, 4.6]:
		var cp := Vector3(x, 0, 3.9)
		Mini3D.cilindro(_raiz, cp + Vector3(0, 0.75, 0), 0.03, 1.5, Mini3D.mat(Color(0.2, 0.2, 0.2), 0.4))
		Mini3D.caja(_raiz, cp + Vector3(0, 1.6, 0), Vector3(0.3, 0.3, 0.55), Mini3D.mat(Color(0.12, 0.12, 0.13), 0.4))
		if absf(x) > 4.0:
			_trabajador(cp + Vector3(0, 0, 0.6), PI, false, ["charla", "brazos_jarra"], _calle())
	_cartel("🎙️ " + _sala_nombre().to_upper(), Vector3(0, 3.05, -5.45), 30)

## Museo (22 × 14 m): vitrinas con trofeos iluminadas, camisetas históricas,
## bancos y visitantes.
func _museo() -> void:
	_sala(Vector3(22, 5.0, 14), Color(0.42, 0.32, 0.26), Color(0.2, 0.2, 0.23), "parquet")
	var oro := Mini3D.mat(Color(0.95, 0.75, 0.25), 0.25)
	oro.metallic = 0.9
	var vidrio := Mini3D.mat(Color(0.8, 0.9, 1.0, 0.25), 0.05)
	for k in 5:
		var p := Vector3(-8.0 + float(k) * 4.0, 0, -2.2)
		Mini3D.caja(_raiz, p + Vector3(0, 0.5, 0), Vector3(1.4, 1.0, 1.4), Mini3D.mat(Color(0.12, 0.12, 0.14), 0.5))
		Mini3D.caja(_raiz, p + Vector3(0, 1.55, 0), Vector3(1.3, 1.1, 1.3), vidrio)
		Mini3D.cilindro(_raiz, p + Vector3(0, 1.25, 0), 0.1, 0.5, oro)
		Mini3D.esfera(_raiz, p + Vector3(0, 1.6, 0), 0.2, oro)
		var foco := SpotLight3D.new()
		foco.position = p + Vector3(0, 4.6, 0)
		foco.rotation.x = -PI * 0.5
		foco.light_energy = 3.0
		foco.spot_range = 6.0
		foco.spot_angle = 18.0
		_raiz.add_child(foco)
	## Camisetas históricas enmarcadas.
	for k in 6:
		var x := -8.75 + float(k) * 3.5
		Mini3D.caja(_raiz, Vector3(x, 2.4, -6.97), Vector3(1.3, 1.5, 0.04), Mini3D.mat(Color(0.1, 0.1, 0.1), 0.4))
		_camiseta(Vector3(x, 3.0, -6.93), 0.0, _c1 if k % 2 == 0 else _c2, _c2 if k % 2 == 0 else _c1)
	## Bancos para mirar y alfombra de pasillo.
	for x: float in [-6.0, 0.0, 6.0]:
		_asiento("benchCushionLow", Vector3(x, 0, 1.6), PI, [0.0] if _rng.randf() < 0.5 else [], _calle(), 2.6, {"carpet": Color(0.55, 0.12, 0.12), "wood": Color(0.25, 0.2, 0.18)})
	for p: Vector3 in [Vector3(-10.4, 0, 6.4), Vector3(10.4, 0, 6.4), Vector3(-10.4, 0, -6.4), Vector3(10.4, 0, -6.4)]:
		_planta(p)
	for k in 4:
		var z := 3.0 + float(k) * 0.8
		_caminante([Vector3(-9.5, 0, z), Vector3(-5.0, 0, -0.6), Vector3(5.0, 0, -0.6), Vector3(9.5, 0, z)], _calle())
	_trabajador(Vector3(10.2, 0, 3.6), -PI * 0.5, false, ["charla", "saludo_mano"], [Color(0.15, 0.15, 0.2), Color(0.15, 0.15, 0.2), true])
	_cartel("🏆 " + _sala_nombre().to_upper(), Vector3(0, 4.3, -6.95), 56, Color(1.0, 0.85, 0.4))
