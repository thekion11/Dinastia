class_name InteriorInstalacion
extends "res://ui/componentes/interior_instalacion_p6.gd"
## [Capa 7/7 de `interior_instalacion.gd`] _peluqueria, _libreria, _taller, _recreativos, _construir_sala, _cerrar … (+6)

## Peluquería (11 × 8 m): tres sillones frente a los espejos, el sofá de espera
## y la recepción.
func _peluqueria() -> void:
	_tonos_sala = _MADERA_CLARA
	_sala(Vector3(11, 3.2, 8), Color(0.92, 0.9, 0.92), Color(0.8, 0.88, 0.92), "losa")
	var cuero := {"carpet": Color(0.12, 0.12, 0.14), "metalMedium": Color(0.75, 0.76, 0.78)}
	for k in 3:
		var x := -3.4 + float(k) * 3.4
		Mini3D.caja(_raiz, Vector3(x, 1.6, -3.97), Vector3(1.1, 1.3, 0.03), Mini3D.mat(Color(0.5, 0.58, 0.64), 0.05, 0.05))
		Mini3D.caja(_raiz, Vector3(x, 1.6, -3.985), Vector3(1.2, 1.4, 0.02), Mini3D.mat(Color(0.2, 0.2, 0.22), 0.4))
		_poner("sideTable", Vector3(x, 0, -3.78))
		_poner("comida/soda-bottle", Vector3(x - 0.3, _alto("sideTable"), -3.8), 0.0, 0.3)
		_poner("comida/glass", Vector3(x + 0.3, _alto("sideTable"), -3.8))
		_asiento("chairDesk", Vector3(x, 0, -2.5), PI, [0.0], _calle(), null, cuero)
		_trabajador(Vector3(x + 0.15, 0, -1.6), PI, false, ["charla", "brazos_jarra"], [Color(0.1, 0.1, 0.12), Color(0.1, 0.1, 0.12), true])
		_poner("lampWall", Vector3(x, 2.35, -3.9), 0.0)
	## Espera: sofá, mesa con revistas y planta.
	_asiento("loungeSofa", Vector3(-5.5 + 0.42, 0, 2.0), PI * 0.5, [-0.4, 0.45], _calle(), null, {"carpet": Color(0.55, 0.22, 0.3)})
	_poner("tableCoffeeGlass", Vector3(-3.9, 0, 2.0), PI * 0.5)
	_poner("books", Vector3(-3.9, _alto("tableCoffeeGlass"), 2.0), 0.7, 1.6)
	_poner("coatRackStanding", Vector3(-5.0, 0, 3.5))
	## Recepción.
	_poner("desk", Vector3(4.1, 0, 2.2), -PI * 0.5)
	_poner("mini_arcade/cash-register", Vector3(4.0, _alto("desk"), 2.4), -PI * 0.5, 0.6)
	_trabajador(Vector3(4.85, 0, 2.2), -PI * 0.5, false, ["saludo_mano", "charla"], [Color(0.1, 0.1, 0.12), Color(0.1, 0.1, 0.12), true])
	_planta(Vector3(5.0, 0, 3.5))
	_planta(Vector3(5.0, 0, -0.6), false)
	_poner("lampSquareFloor", Vector3(-5.1, 0, 0.6))
	_ventana(-1.0, -1.2, 1.4)
	_cartel("✂️ " + _sala_nombre().to_upper(), Vector3(0, 2.75, -3.95), 30)

## Librería (12 × 9 m): estanterías llenas, mesas de novedades, rincón de
## lectura y el mostrador.
func _libreria() -> void:
	_tonos_sala = _MADERA_OSCURA
	_sala(Vector3(12, 3.4, 9), Color(0.6, 0.44, 0.3), Color(0.88, 0.83, 0.72), "parquet")
	## Estanterías en el fondo y en la pared izquierda, con libros.
	for k in 7:
		var x := -5.2 + float(k) * 1.62
		if x > 5.0:
			break
		_poner("bookcaseClosedWide", Vector3(x, 0, -4.25), 0.0)
		for b in 3:
			for q in 3:
				_poner("books", Vector3(x - 0.5 + float(q) * 0.5, 0.06 + float(b) * 0.52, -4.25), _rng.randf_range(-0.1, 0.1), 2.0)
	for z: float in [-2.6, -1.0, 0.6]:
		_poner("bookcaseClosedWide", Vector3(-5.75, 0, z), PI * 0.5)
		for b in 3:
			_poner("books", Vector3(-5.75, 0.06 + float(b) * 0.52, z + _rng.randf_range(-0.4, 0.4)), PI * 0.5, 2.0)
	## Mesas de novedades.
	for p: Vector3 in [Vector3(-2.4, 0, -1.6), Vector3(1.0, 0, -1.6)]:
		_poner("table", p, 0.0, 2.0)
		for k in 8:
			_poner("books", p + Vector3(-0.6 + float(k % 4) * 0.4, _alto("table", 2.0), -0.2 + float(k / 4) * 0.4), _rng.randf_range(-0.3, 0.3), 2.0)
	## Rincón de lectura.
	_poner("rugRound", Vector3(4.0, 0, -1.4), 0.0, 2.0, {"carpet": Color(0.55, 0.35, 0.3), "carpetDarker": Color(0.45, 0.28, 0.24)})
	_asiento("loungeChair", Vector3(3.4, 0, -2.2), 0.6, [0.0], _calle(), null, {"carpet": Color(0.35, 0.45, 0.32)})
	_asiento("loungeChair", Vector3(4.9, 0, -1.6), -0.9, [], [], null, {"carpet": Color(0.35, 0.45, 0.32)})
	_poner("sideTable", Vector3(4.6, 0, -2.9), 0.0, 1.2)
	_poner("lampRoundFloor", Vector3(5.4, 0, -3.2))
	## Mostrador.
	_poner("desk", Vector3(4.3, 0, 2.4), -PI * 0.5)
	_poner("mini_arcade/cash-register", Vector3(4.2, _alto("desk"), 2.6), -PI * 0.5, 0.6)
	_trabajador(Vector3(5.05, 0, 2.4), -PI * 0.5, false, ["saludo_mano", "charla"], [Color(0.4, 0.25, 0.2), Color(0.2, 0.2, 0.25)])
	_planta(Vector3(5.4, 0, 4.0))
	_planta(Vector3(-5.4, 0, 3.9))
	_ventana(1.0, 0.6, 1.4)
	_caminante([Vector3(-4.6, 0, -3.3), Vector3(2.4, 0, -3.3), Vector3(2.4, 0, -0.4), Vector3(-4.6, 0, -0.4)], _calle())
	_caminante([Vector3(-4.6, 0, 1.6), Vector3(2.6, 0, 1.6)], _calle())
	_cartel("📚 " + _sala_nombre().to_upper(), Vector3(0, 2.95, -4.45), 30)

## Taller (16 × 12 m, 5 m de alto): coche en el elevador, otro en el suelo,
## banco de trabajo, neumáticos, bidones y la oficina del jefe.
func _taller() -> void:
	_tonos_sala = {"wood": Color(0.55, 0.57, 0.6), "woodDark": Color(0.4, 0.42, 0.45)}
	_sala(Vector3(16, 5.0, 12), Color(0.45, 0.45, 0.47), Color(0.75, 0.77, 0.79), "hormigon", Color(0.25, 0.38, 0.6))
	## El elevador con un coche del kit a 1,6 m.
	var gris := Mini3D.mat(Color(0.35, 0.36, 0.38), 0.4)
	var amarillo := Mini3D.mat(Color(0.92, 0.75, 0.1), 0.5)
	for s: float in [-1.0, 1.0]:
		Mini3D.caja(_raiz, Vector3(-3.5 + s * 1.5, 1.3, -1.5), Vector3(0.3, 2.6, 0.3), amarillo)
		Mini3D.caja(_raiz, Vector3(-3.5 + s * 0.8, 1.52, -1.5), Vector3(1.4, 0.08, 0.2), gris)
	var coche := "coches/sedan"
	var m := _medida(coche, 1.0)
	var esc := 4.4 / maxf(m.x, m.z)
	_poner(coche, Vector3(-3.5, 1.6, -1.5), 0.0 if m.z >= m.x else PI * 0.5, esc)
	var otro := "coches/suv"
	var m2 := _medida(otro, 1.0)
	_poner(otro, Vector3(3.6, 0, -0.6), (0.0 if m2.z >= m2.x else PI * 0.5) + 0.25, 4.6 / maxf(m2.x, m2.z))
	## Banco de trabajo, panel de herramientas y cajas.
	_cocina(-1.2, -6.0 + 0.45, ["kitchenCabinetDrawer", "kitchenCabinetDrawer", "kitchenCabinet", "kitchenCabinetDrawer", "kitchenCabinet"], 0.0, false)
	Mini3D.caja(_raiz, Vector3(1.0, 1.9, -5.97), Vector3(4.3, 1.4, 0.04), Mini3D.mat(Color(0.5, 0.52, 0.55), 0.5))
	for k in 14:
		Mini3D.caja(_raiz, Vector3(-0.9 + float(k) * 0.3, 1.9 + _rng.randf_range(-0.3, 0.3), -5.93), Vector3(0.05, _rng.randf_range(0.25, 0.5), 0.03), Mini3D.mat(Color(0.12, 0.12, 0.14) if k % 3 else Color(0.8, 0.15, 0.1), 0.3))
	_poner("cardboardBoxClosed", Vector3(5.2, 0, -5.5), 0.2)
	_poner("cardboardBoxClosed", Vector3(5.7, 0, -5.4), -0.3)
	_poner("cardboardBoxClosed", Vector3(5.45, _alto("cardboardBoxClosed"), -5.45), 0.5)
	## Neumáticos apilados y bidones.
	var goma := Mini3D.mat(Color(0.07, 0.07, 0.08), 0.85)
	for k in 5:
		var rueda := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.18
		tm.outer_radius = 0.34
		rueda.mesh = tm
		rueda.material_override = goma
		rueda.position = Vector3(-7.3, 0.08 + float(k) * 0.17, -5.3)
		rueda.scale = Vector3(1, 1.4, 1)
		_raiz.add_child(rueda)
	for k in 3:
		Mini3D.cilindro(_raiz, Vector3(7.4, 0.45, -3.0 + float(k) * 0.65), 0.29, 0.9, Mini3D.mat([Color(0.75, 0.15, 0.1), Color(0.15, 0.3, 0.6), Color(0.2, 0.45, 0.2)][k], 0.5))
	## La oficina del jefe, junto a la entrada.
	_puesto(Vector3(-6.5, 0, 3.6), PI * 0.5, true, true, [Color(0.15, 0.3, 0.6), Color(0.15, 0.3, 0.6), true])
	_poner("bookcaseClosedDoors", Vector3(-7.75, 0, 1.8), PI * 0.5, null, {"wood": Color(0.65, 0.67, 0.7)})
	_poner("washerDryerStacked", Vector3(7.5, 0, 3.2), -PI * 0.5)
	_trabajador(Vector3(-2.0, 0, -0.2), PI * 0.75, false, ["charla", "brazos_jarra"], [Color(0.15, 0.3, 0.6), Color(0.15, 0.3, 0.6), true])
	_trabajador(Vector3(0.9, 0, -4.9), 0.0, false, ["charla", "pedir_calma"], [Color(0.15, 0.3, 0.6), Color(0.15, 0.3, 0.6), true])
	_caminante([Vector3(-0.8, 0, 2.6), Vector3(6.4, 0, 2.6), Vector3(6.4, 0, -3.6), Vector3(-0.8, 0, -3.6)], [Color(0.15, 0.3, 0.6), Color(0.15, 0.3, 0.6), true])
	## Franjas amarillas en el suelo del elevador.
	for s: float in [-1.0, 1.0]:
		Mini3D.caja(_raiz, Vector3(-3.5 + s * 2.0, 0.005, -1.5), Vector3(0.12, 0.01, 5.0), amarillo)
	_cartel("🔧 " + _sala_nombre().to_upper(), Vector3(-3.5, 4.2, -5.95), 40)

## SALA DE RECREATIVOS (16-10-2026, kit Mini Arcade de Kenney a ×2,4): 16 × 12 m,
## moqueta oscura y neones. Fila de máquinas en el fondo, pinballs a la izquierda,
## grúas, rueda de premios y la taquilla a la derecha, dos mesas de air hockey en
## medio y las máquinas de baile junto a la entrada. Las máquinas miran a +Z
## local (como en el bar); quien juega se pone delante, mirando a la pantalla.
func _recreativos() -> void:
	_sala(Vector3(16, 3.6, 12), Color(0.16, 0.1, 0.22), Color(0.2, 0.17, 0.28), "moqueta", Color(0.1, 0.08, 0.14))
	var ropa := [Color(0.85, 0.15, 0.45), Color(0.12, 0.12, 0.16), true]
	## Fondo: siete máquinas de pantalla y dos canastas.
	for k in 7:
		var x := -6.4 + float(k) * 1.12
		_poner("mini_arcade/arcade-machine", Vector3(x, 0, -5.3), 0.0)
		if k in [0, 2, 3, 5]:
			_trabajador(Vector3(x, 0, -4.15), PI, false, ["charla"], _calle())
	for x: float in [3.2, 5.2]:
		_poner("mini_arcade/basketball-game", Vector3(x, 0, -4.7), 0.0)
	_trabajador(Vector3(3.2, 0, -3.05), PI, false, ["aplaudir", "charla"], _calle())
	## Izquierda: pinballs contra la pared, mirando a la sala.
	for k in 4:
		var z := -2.6 + float(k) * 1.35
		_poner("mini_arcade/pinball", Vector3(-7.05, 0, z), PI * 0.5)
		if k % 2 == 0:
			_trabajador(Vector3(-5.9, 0, z), -PI * 0.5, false, ["charla"], _calle())
	## Derecha: grúas, rueda de premios y máquina de tickets.
	for k in 3:
		var z2 := -4.4 + float(k) * 1.7
		_poner("mini_arcade/claw-machine", Vector3(7.1, 0, z2), -PI * 0.5)
	_trabajador(Vector3(5.8, 0, -2.7), PI * 0.5, false, ["charla", "aplaudir"], _calle())
	_poner("mini_arcade/prize-wheel", Vector3(7.55, 0, 0.6), -PI * 0.5)
	_poner("mini_arcade/ticket-machine", Vector3(7.45, 0, 1.75), -PI * 0.5)
	## La taquilla de premios junto a la entrada, con su empleada.
	_poner("mini_arcade/cash-register", Vector3(5.6, 0, 3.9), -PI * 0.5)
	_poner("mini_arcade/prizes", Vector3(7.5, 0, 4.3), -PI * 0.5)
	_poner("mini_arcade/prizes", Vector3(5.6, 0, 5.5), PI)
	_trabajador(Vector3(6.75, 0, 3.6), -PI * 0.5, false, ["saludo_mano", "charla"], ropa)
	_trabajador(Vector3(4.2, 0, 3.9), PI * 0.5, false, ["charla", "brazos_jarra"], _calle())
	## En medio, dos mesas de air hockey con una pareja jugando en cada una.
	for x2: float in [-2.6, 1.4]:
		_poner("mini_arcade/air-hockey", Vector3(x2, 0, 0.2), 0.0)
		if x2 < 0.0 or _rng.randf() < 0.7:
			for s: float in [-1.0, 1.0]:
				_trabajador(Vector3(x2 + s * 1.65, 0, 0.2), -s * PI * 0.5, false, ["aplaudir", "charla", "brazos_jarra"], _calle())
	## Junto a la entrada: dos máquinas de baile, una con alguien encima.
	for k in 2:
		var z3 := 2.6 + float(k) * 1.9
		_poner("mini_arcade/dance-machine", Vector3(-6.7, 0, z3), PI * 0.5)
	_trabajador(Vector3(-6.0, 0.1, 2.6), -PI * 0.5, false, ["aplaudir", "saludo_mano"], _calle())
	_poner("mini_arcade/vending-machine", Vector3(-3.2, 0, 5.4), PI)
	_poner("mini_arcade/vending-machine", Vector3(-2.0, 0, 5.4), PI)
	## Neones a lo largo de las paredes y carteles luminosos.
	var neones := [Mini3D.mat(Color(1.0, 0.2, 0.7), 0.4, 3.0), Mini3D.mat(Color(0.2, 0.85, 1.0), 0.4, 3.0)]
	Mini3D.caja(_raiz, Vector3(0, 3.25, -5.97), Vector3(15.6, 0.06, 0.04), neones[0])
	Mini3D.caja(_raiz, Vector3(0, 0.25, -5.97), Vector3(15.6, 0.04, 0.04), neones[1])
	for lado: float in [-1.0, 1.0]:
		Mini3D.caja(_raiz, Vector3(lado * 7.97, 3.25, 0), Vector3(0.04, 0.06, 11.6), neones[1 if lado < 0.0 else 0])
	_cartel("🕹️ " + _sala_nombre().to_upper(), Vector3(-2.6, 2.75, -5.9), 40, Color(1.0, 0.5, 0.9))
	_cartel("★ RÉCORDS ★", Vector3(4.2, 2.6, -5.9), 22, Color(0.5, 0.95, 1.0))
	_cuadro(Vector3(4.2, 1.95, -5.95), Vector2(2.2, 0.8), Color(0.1, 0.1, 0.25))
	## Gente que va de máquina en máquina.
	for k in 3:
		var z4 := -1.9 + float(k) * 2.6
		_caminante([Vector3(-4.6, 0, z4), Vector3(4.4, 0, z4), Vector3(4.4, 0, z4 + 1.2), Vector3(-4.6, 0, z4 + 1.2)], _calle())

## Levanta la sala según `tipo` en `_raiz` (la usa la ventana y también el paseo).
func _construir_sala() -> void:
	## Ropa corta de deporte solo donde se hace deporte (13-10-2026).
	Mini3D.sala_deportiva = tipo in ["gimnasio", "piscina"]
	match tipo:
		"oficina": _oficina()
		"hospital": _hospital()
		"comisaria": _comisaria()
		"bomberos": _bomberos()
		"aula": _aula()
		"estacion": _estacion()
		"mercado": _mercado()
		"cine": _cine()
		"tienda": _tienda()
		"gimnasio": _gimnasio()
		"analisis": _analisis()
		"comedor": _comedor()
		"prensa": _prensa()
		"museo": _museo()
		"piscina": _piscina()
		"vivienda": _vivienda()
		"bar": _bar()
		"panaderia": _panaderia()
		"peluqueria": _peluqueria()
		"libreria": _libreria()
		"taller": _taller()
		"recreativos": _recreativos()
	_vaciar_lotes()
	## De vuelta al valor de siempre: los minijuegos y la ciudad lo usan.
	Mini3D.sala_deportiva = true

func _cerrar() -> void:
	cerrado.emit()
	queue_free()

func _interfaz(nombre: String) -> void:
	var banda := ColorRect.new()
	banda.color = Color(0, 0, 0, 0.5)
	banda.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	banda.offset_bottom = 56
	banda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banda)
	_titulo = Label.new()
	_titulo.text = "🚪 %s  ·  %d personas  ·  arrastra para girar, rueda para acercar, Esc para salir" % [nombre, _raiz.find_children("*", "Skeleton3D", true, false).size()]
	_titulo.add_theme_font_size_override("font_size", 20)
	_titulo.position = Vector2(20, 14)
	_titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_titulo)
	var salir := Button.new()
	salir.text = "Salir"
	salir.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	salir.offset_left = -110
	salir.offset_right = -20
	salir.offset_top = 10
	salir.offset_bottom = 46
	salir.pressed.connect(_cerrar)
	add_child(salir)
	if _minijuego.is_valid():
		var jugar := Button.new()
		jugar.text = "🎮 Jugar aquí"
		jugar.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		jugar.offset_left = -260
		jugar.offset_right = -120
		jugar.offset_top = 10
		jugar.offset_bottom = 46
		jugar.pressed.connect(func() -> void:
			var f := _minijuego
			_cerrar()
			f.call())
		add_child(jugar)

func _colocar_camara() -> void:
	if _cam == null:
		return
	## Vista de casa de muñecas (15-10-2026): sin techo y con la fachada baja,
	## desde arriba y por delante, a la distancia que abarca la sala entera.
	var d := maxf(_tam.x * 0.72, _tam.z * 1.1) * _dist
	var elev := 0.74
	var objetivo := Vector3(0, 0.6, -_tam.z * 0.08)
	var pos := objetivo + Vector3(sin(_ang) * cos(elev), sin(elev), cos(_ang) * cos(elev)) * d
	## Que no se salga del lado abierto de la sala: siempre por delante.
	if pos.z < _tam.z * 0.25:
		pos.z = _tam.z * 0.25 + absf(pos.z - _tam.z * 0.25) * 0.3
	_cam.position = pos
	_cam.look_at(objetivo, Vector3.UP)

func _montar() -> void:
	_rng.seed = hash(clave) + Time.get_ticks_msec()
	## (la base de la clave decide qué sala; lo que va tras «|» es solo el nombre)
	var sala: Array = _sala_de(clave)
	tipo = String(sala[0])
	if club != null:
		_c1 = Color(club.color1)
		_c2 = Color(club.color2)
	_v = Mini3D.vista(self, Calidad.DIA)
	_cam = _v["cam"]
	_raiz = _v["raiz"]
	## Dentro no hay cielo: fondo oscuro, luz ambiente suave y lámparas, y
	## oclusión ambiental para que los muebles se asienten en el suelo.
	(_v["sol"] as DirectionalLight3D).visible = false
	for we in _raiz.get_children():
		if we is WorldEnvironment:
			var env: Environment = (we as WorldEnvironment).environment
			env.background_mode = Environment.BG_COLOR
			env.background_color = Color(0.05, 0.05, 0.06)
			env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			env.ambient_light_color = Color(0.9, 0.88, 0.85)
			env.ambient_light_energy = 0.5
			env.tonemap_exposure = 1.0
			env.ssao_enabled = true
			env.ssao_radius = 0.8
			env.ssao_intensity = 1.6
			env.ssao_power = 1.4
	_construir_sala()
	_interfaz(String(sala[1]))
	_colocar_camara()

func _process(delta: float) -> void:
	for f: Dictionary in _fijos:
		if (f["gestos"] as Array).is_empty():
			continue
		f["t"] = float(f["t"]) - delta
		if float(f["t"]) <= 0.0:
			f["t"] = _rng.randf_range(3.0, 7.0)
			var g: Array = f["gestos"]
			Mini3D.anim(f["d"], String(g[_rng.randi() % g.size()]), String(f["base"]))
	for c: Dictionary in _caminantes:
		var n: Node3D = c["d"]["nodo"]
		if float(c["espera"]) > 0.0:
			c["espera"] = float(c["espera"]) - delta
			if float(c["espera"]) <= 0.0:
				Mini3D.anim(c["d"], String(c["clip"]), "")
			continue
		var pts: Array = c["puntos"]
		var dest: Vector3 = pts[int(c["i"])]
		var dd := dest - n.position
		dd.y = 0.0
		if dd.length() < 0.2:
			c["i"] = (int(c["i"]) + 1) % pts.size()
			c["espera"] = _rng.randf_range(0.8, 3.0)
			Mini3D.anim(c["d"], ["parado", "charla", "saludo_mano"][_rng.randi() % 3], "parado")
			continue
		n.rotation.y = lerp_angle(n.rotation.y, atan2(dd.x, dd.z), clampf(delta * 6.0, 0.0, 1.0))
		n.position += dd.normalized() * minf(float(c["vel"]) * delta, dd.length())
	if _girando and not _arrastre:
		_ang += delta * 0.06
	_colocar_camara()

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_arrastre = mb.pressed
			_girando = false
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_dist = clampf(_dist - 0.06, 0.55, 1.4)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_dist = clampf(_dist + 0.06, 0.55, 1.4)
		accept_event()
	elif ev is InputEventMouseMotion and _arrastre:
		_ang -= (ev as InputEventMouseMotion).relative.x * 0.005
		accept_event()
	elif ev is InputEventScreenDrag:
		_ang -= (ev as InputEventScreenDrag).relative.x * 0.005
		_girando = false
		accept_event()

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and (ev as InputEventKey).pressed and (ev as InputEventKey).keycode == KEY_ESCAPE:
		_cerrar()
		get_viewport().set_input_as_handled()
