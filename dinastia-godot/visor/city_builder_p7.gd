extends "res://visor/city_builder_p6.gd"
## (Parte 7 de 12 de `city_builder.gd`.)

## LA TERMINAL: "una estación o un eje vial mejor conectado" pedía el análisis.
## Las cuatro marquesinas eran paradas sueltas -sin ellas parecía que el
## transporte público no tenía de dónde salir-; la terminal es el origen: un
## cobertizo largo con varias dársenas, junto al acceso norte, que es donde de
## verdad convergen el estadio y el aparcamiento.
func _terminal_buses() -> void:
	var centro := Vector3(178.0, 0, -100.0)
	## DUPLICADO para conservar el metalico 0.4 ya afinado -mas apagado que el
	## 0.75 por defecto de la fabrica, que aqui se veria demasiado cromado.
	var metal: StandardMaterial3D = Texturas.metal(Color(0.10, 0.11, 0.13), 0.5).duplicate()
	metal.metallic = 0.4
	var acento := StandardMaterial3D.new()
	acento.albedo_color = _color_club("c1", Color(0.2, 0.5, 0.3))
	acento.roughness = 0.5
	var pav: StandardMaterial3D = Texturas.asfalto(Color(0.24, 0.25, 0.27)).duplicate()
	pav.roughness = 0.85

	var suelo := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	pl.size = Vector2(46, 16)
	suelo.mesh = pl
	suelo.material_override = pav
	suelo.position = centro + Vector3(0, 0.03, 0)
	add_child(suelo)

	## El cobertizo: techo largo sobre cuatro pilares, con la franja del club
	## a lo largo del alero -misma idea que la marquesina de cada instalación-.
	var techo := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(44.0, 0.4, 10.0)
	techo.mesh = tm
	techo.material_override = metal
	techo.position = centro + Vector3(0, 4.6, 0)
	add_child(techo)
	var franja := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(44.4, 0.5, 0.2)
	franja.mesh = fm
	franja.material_override = acento
	franja.position = centro + Vector3(0, 4.35, 5.1)
	add_child(franja)
	for i in range(5):
		var pil := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.3
		cm.bottom_radius = 0.3
		cm.height = 4.4
		pil.mesh = cm
		pil.material_override = metal
		pil.position = centro + Vector3(-20.0 + i * 10.0, 2.2, 4.4)
		add_child(pil)
	_cartel(centro + Vector3(0, 0, -9.0), "🚌 Terminal de buses", true)

## PARADAS DE AUTOBÚS a lo largo del anillo: "integrar paradas de autobús...
## le daría una sensación de mayor dinamismo funcional". Marquesina, banco y
## poste con señal, en los cuatro puntos donde de verdad haría falta parar:
## el estadio, el centro comercial, la zona industrial y el barrio.
func _paradas_bus() -> void:
	var sitios := [
		{"p": Vector3(RING_X - 13.0, 0, -170.0), "a": -PI * 0.5, "n": "Estadio"},
		{"p": Vector3(-RING_X + 13.0, 0, 110.0), "a": PI * 0.5, "n": "Centro comercial"},
		{"p": Vector3(RING_X - 13.0, 0, 140.0), "a": -PI * 0.5, "n": "Zona industrial"},
		{"p": Vector3(BARRIO_EN.x + 13.0, 0, RING_Z_SUR + 60.0), "a": -PI * 0.5, "n": "Barrio"},
	]
	var vidrio := StandardMaterial3D.new()
	vidrio.albedo_color = Color(0.72, 0.86, 0.92, 0.4)
	vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vidrio.metallic = 0.4
	vidrio.roughness = 0.1
	var metal: StandardMaterial3D = Texturas.metal(Color(0.08, 0.09, 0.1), 0.4).duplicate()
	metal.metallic = 0.6
	var acento := StandardMaterial3D.new()
	acento.albedo_color = _color_club("c1", Color(0.2, 0.5, 0.3))
	acento.roughness = 0.5

	for s in sitios:
		var raiz := Node3D.new()
		raiz.position = s["p"]
		raiz.rotation.y = float(s["a"])
		add_child(raiz)
		## Techo de la marquesina, con la franja del club por delante.
		var techo := MeshInstance3D.new()
		var tm := BoxMesh.new()
		tm.size = Vector3(7.5, 0.22, 3.0)
		techo.mesh = tm
		techo.material_override = metal
		techo.position = Vector3(0, 3.1, 0)
		raiz.add_child(techo)
		var franja := MeshInstance3D.new()
		var fm := BoxMesh.new()
		fm.size = Vector3(7.6, 0.5, 0.16)
		franja.mesh = fm
		franja.material_override = acento
		franja.position = Vector3(0, 2.85, 1.5)
		raiz.add_child(franja)
		## Trasera de cristal y dos pilares.
		var pared := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(7.5, 2.5, 0.1)
		pared.mesh = pm
		pared.material_override = vidrio
		pared.position = Vector3(0, 1.6, -1.4)
		raiz.add_child(pared)
		for lado in [-1.0, 1.0]:
			var pil := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.11
			cm.bottom_radius = 0.11
			cm.height = 3.0
			pil.mesh = cm
			pil.material_override = metal
			pil.position = Vector3(lado * 3.5, 1.5, 1.3)
			raiz.add_child(pil)
		## El banco.
		var banco := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(5.4, 0.16, 0.7)
		banco.mesh = bm
		banco.material_override = acento
		banco.position = Vector3(0, 0.75, -0.9)
		raiz.add_child(banco)
		_cartel(s["p"] + Vector3(0, 0, -6.0), "🚌 " + String(s["n"]), true)

	_terminal_buses()

# ---------------------------------------------------------------- perimetro

func _perimetro() -> void:
	## Cierra el recinto. Un complejo sin valla se ve como piezas sueltas flotando
	## en una explanada; con valla se lee como UN sitio.
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _color_club("c2", Color(0.75, 0.75, 0.75))
	mat.roughness = 0.6
	## La valla se calcula para que QUEPA todo: el estadio llega a z=-125 y la ultima
	## fila de edificios a z=195. Antes estaba en 150 y tres edificios se quedaban
	## fuera del recinto.
	## Se calcula desde el contenido REAL en vez de a ojo: 15 instalaciones en filas
	## de cuatro son cuatro filas, y la ultima cae en z = 115 + 3*32 = 211. Poner la
	## valla en 206 dejaba un edificio fuera del recinto.
	var filas: int = int(ceil(float(EDIFICIOS.size()) / 4.0))
	## Justo antes de la calle exterior (z=262, 16 m de ancho).
	var zFondo: float = FILA_0_Z + (filas - 1) * FILA_PASO + 14.0
	## HASTA -280 Y NO -128 (12-9-2026): desde que el estadio es el de verdad
	## y no una maqueta, ocupa de z=-260 a z=-120, así que con la valla vieja
	## el estadio quedaba FUERA de su propio recinto.
	var zFrente := -250.0
	var largo: float = zFondo - zFrente
	var centro: float = (zFondo + zFrente) * 0.5
	var lados := [
		{"p": Vector3(0, 1.5, zFrente), "s": Vector3(292, 3, 0.8)},
		{"p": Vector3(0, 1.5, zFondo),  "s": Vector3(292, 3, 0.8)},
		{"p": Vector3(-146, 1.5, centro), "s": Vector3(0.8, 3, largo)},
		{"p": Vector3(146, 1.5, centro),  "s": Vector3(0.8, 3, largo)},
	]
	for l in lados:
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = l["s"]
		m.mesh = bm
		m.material_override = mat
		m.position = l["p"]
		add_child(m)

## Un solar: la explanada de tierra, el bordillo que lo delimita y, si es tuyo,
## una franja del color del club en el bordillo.
func _solar(centro: Vector3, ancho: float, fondo: float, mio: bool) -> void:
	var suelo := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	pl.size = Vector2(ancho, fondo)
	suelo.mesh = pl
	var m: StandardMaterial3D = Texturas.hormigon(
		Color(0.42, 0.38, 0.30) if not mio else Color(0.30, 0.30, 0.31)).duplicate()
	m.roughness = 0.95
	suelo.material_override = m
	suelo.position = centro + Vector3(0, 0.06, 0)
	add_child(suelo)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = _color_club("c1", Color(0.3, 0.6, 0.4)) if mio else Color(0.62, 0.60, 0.56)
	mat.roughness = 0.7
	## Bordillo de 0,9 m: suficiente para leerse desde la cámara alta del mapa
	## sin taparlo todo cuando se baja a mirar la parcela de cerca.
	var lados := [
		{"p": Vector3(0, 0.45, fondo * 0.5), "s": Vector3(ancho, 0.9, 1.2)},
		{"p": Vector3(0, 0.45, -fondo * 0.5), "s": Vector3(ancho, 0.9, 1.2)},
		{"p": Vector3(-ancho * 0.5, 0.45, 0), "s": Vector3(1.2, 0.9, fondo)},
		{"p": Vector3(ancho * 0.5, 0.45, 0), "s": Vector3(1.2, 0.9, fondo)},
	]
	for l in lados:
		var b := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = l["s"]
		b.mesh = bm
		b.material_override = mat
		b.position = centro + (l["p"] as Vector3)
		add_child(b)

func _tabla_terrenos() -> Array:
	var t: Variant = Datos.tabla("TERRENOS")
	return t as Array if t is Array else []

func _nombre_terreno(clave: String) -> String:
	for f: Array in _tabla_terrenos():
		if f.size() > 1 and String(f[0]) == clave:
			return String(f[1])
	return clave.capitalize()

func _rio() -> void:
	var agua := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	## 7-10-2026: el río cruza la ciudad grande entera, de punta a punta.
	pl.size = Vector2(80, 2700)
	## SUBDIVIDIDO, o el oleaje no tiene dónde ocurrir: un `PlaneMesh` sin
	## subdividir tiene cuatro vértices, y un shader que mueve vértices sobre
	## cuatro puntos no produce olas, produce un plano inclinado que cabecea.
	pl.subdivide_width = 12
	pl.subdivide_depth = 300
	agua.mesh = pl
	var sh := load(RUTA_SHADER_AGUA)
	if sh != null:
		var sm := ShaderMaterial.new()
		sm.shader = sh
		sm.set_shader_parameter("color_hondo", Color(0.06, 0.16, 0.24))
		sm.set_shader_parameter("color_orilla", Color(0.18, 0.38, 0.44))
		## Con la ola de 0,55 m los valles bajaban del suelo y asomaba el
		## césped en mitad del río (visto al alargarlo, 7-10-2026).
		sm.set_shader_parameter("altura_ola", 0.16)
		agua.material_override = sm
		_agua_mat = sm
	else:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.16, 0.29, 0.38)
		m.metallic = 0.55
		m.roughness = 0.12
		agua.material_override = m
	agua.position = Vector3(RIO_X, 0.3, 0)
	add_child(agua)
	## Las dos orillas: sin ellas el agua es un rectángulo azul pegado sobre el
	## césped, y desde la cámara alta se nota que no hay cauce.
	var tierra := StandardMaterial3D.new()
	tierra.albedo_color = Color(0.44, 0.40, 0.31)
	tierra.roughness = 0.95
	for lado in [-1.0, 1.0]:
		var orilla := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(9.0, 1.6, 2700.0)
		orilla.mesh = bm
		orilla.material_override = tierra
		orilla.position = Vector3(RIO_X + lado * 44.0, 0.4, 0)
		add_child(orilla)

func _mallas_de(n: Node) -> Array[MeshInstance3D]:
	var salida: Array[MeshInstance3D] = []
	if n is MeshInstance3D:
		salida.append(n)
	for h in n.get_children():
		salida.append_array(_mallas_de(h))
	return salida

# ---------------------------------------------------------------- casa y complejo del usuario

## La caja real de un modelo importado, midiendo su AABB -nunca a ojo, cada
## exportador trae sus propias unidades. Mismo método que ya usó
## `RuedaPrensaEscena3D._montar_podio_generado()` para el podio generado.
func _caja_de(n: Node) -> AABB:
	var caja := AABB()
	var primero := true
	for m: MeshInstance3D in _mallas_de(n):
		var a: AABB = m.mesh.get_aabb() if m.mesh != null else AABB()
		a = m.transform * a
		if primero:
			caja = a
			primero = false
		else:
			caja = caja.merge(a)
	return caja

## LA CASA DE LA RIBERA: el modelo moderno que trajo el usuario ("ДОМ скетч").
## Antes se probó como edificio suelto dentro del recinto y se veía como una
## masa rota -el usuario pidió sacarla, con razón-. Aquí funciona por dos
## motivos que no son el modelo: tiene su PARCELA (bordillo, cartel, su propio
## suelo, no flotando en mitad del pavimento) y es lo bastante grande como
## para que se distinga su arquitectura -22 m de alto, no 7-. Y encaja con lo
## que la propia tabla dice del terreno: "ribera del río: vistas y polémica".
func _casa_ribera(centro: Vector3) -> void:
	var esc := load(RUTA_OFICINA_DT)
	if esc == null or not (esc is PackedScene):
		return
	var n: Node3D = (esc as PackedScene).instantiate()
	var raiz := Node3D.new()
	add_child(raiz)
	raiz.add_child(n)
	var caja := _caja_de(n)
	var alto: float = caja.size.y
	var escala := (22.0 / alto) if alto > 0.001 else 1.0
	raiz.scale = Vector3.ONE * escala
	## El origen del modelo no está en su base (el AABB empieza por debajo de
	## cero): sin corregirlo queda medio enterrado.
	raiz.position = centro + Vector3(0, -caja.position.y * escala, 0)
	raiz.rotation.y = PI * 0.5

func vestir_torre(n: Node, semilla: int) -> void:
	if _mats_torre.is_empty():
		var sh := load("res://visor/fachada_torre.gdshader") as Shader
		for i in TONOS_TORRE.size():
			var m := ShaderMaterial.new()
			m.shader = sh
			m.set_shader_parameter("pared", TONOS_TORRE[i])
			## Cristal oscuro y casi neutro (13-10-2026: el azul 0,2/0,34/0,5 se
			## leía como azul cielo con la exposición del día).
			m.set_shader_parameter("vidrio", Color(0.13, 0.16, 0.2).lerp(Color(0.16, 0.18, 0.17), float(i % 3) * 0.4))
			_mats_torre.append(m)
	var mat := _mats_torre[absi(semilla) % _mats_torre.size()]
	if n is MeshInstance3D:
		(n as MeshInstance3D).material_override = mat
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = mat

## Pilas de ruedas y piezas sueltas alrededor de `centro`.
func _desguace(centro: Vector3, semilla: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	## Todas las piezas y ruedas del kit al menos una vez (7-10-2026).
	for k in PIEZAS.size():
		_poner_extra(PIEZAS[k], centro + Vector3(-14.0 + float(k) * 2.1, 0, 11.0), 2.4, rng.randf() * TAU)
	for k in RUEDAS_TODAS.size():
		var rr := _poner_extra(RUEDAS_TODAS[k], centro + Vector3(-12.0 + float(k) * 2.6, 0.5, -11.0), 2.2, 0.0)
		if rr != null:
			rr.rotation.x = PI * 0.5
	for i in 6:
		var p := centro + Vector3(rng.randf_range(-12.0, 12.0), 0, rng.randf_range(-8.0, 8.0))
		var rueda: String = RUEDAS[rng.randi() % RUEDAS.size()]
		for k in rng.randi_range(2, 5):
			var r := _poner_extra(rueda, p + Vector3(0, k * 0.55, 0), 2.2, rng.randf() * TAU)
			if r != null:
				r.rotation.x = PI * 0.5
	for i in 18:
		_poner_extra(PIEZAS[rng.randi() % PIEZAS.size()],
			centro + Vector3(rng.randf_range(-14.0, 14.0), 0, rng.randf_range(-10.0, 10.0)),
			rng.randf_range(2.0, 2.8), rng.randf() * TAU)

## LA ZONA INDUSTRIAL del terreno sur. Ese solar era el único que se quedaba
## vacío pase lo que pase: ningún negocio de la tabla lo pide, así que no tenía
## nada encima ni aunque lo compraras. Ahora, en cuanto es tuyo, se llena de
## naves, contenedores y maquinaria: es terreno del club y tiene que notarse
## que lo es -y de paso deja de ser el agujero del mapa-.
func _zona_industrial() -> void:
	var p: Dictionary = PARCELAS.get("sur", {})
	if p.is_empty():
		return
	var c: Vector2 = p["pos"]
	var base := Vector3(c.x, 0, c.y)

	var naves: Array = []
	for ruta in RUTAS_NAVES:
		var esc: PackedScene = load(ruta)
		if esc != null:
			naves.append(esc)
	## Seis naves, repartidas entre los 16 modelos (con todos, la fila se
	## salía del terreno por el fondo).
	for i in range(mini(naves.size(), 6)):
		var nave: Node3D = (naves[(i * 5 + 2) % naves.size()] as PackedScene).instantiate()
		vestir_torre(nave, int(nave.get_instance_id()))
		nave.scale = Vector3.ONE * 7.0
		nave.position = base + Vector3(-32.0 + (i % 2) * 58.0, 0, -46.0 + (i / 2) * 56.0)
		nave.rotation.y = PI * 0.5
		add_child(nave)

	## Maquinaria aparcada y contenedores: lo que de verdad distingue una zona
	## industrial de un polígono de oficinas.
	var trastos := [
		{"r": "res://assets/ciudad/kenney_cars/tractor-shovel.glb", "p": Vector3(24, 0, 4), "e": 2.0},
		{"r": "res://assets/ciudad/kenney_cars/garbage-truck.glb", "p": Vector3(-6, 0, 28), "e": 2.0},
		{"r": "res://assets/ciudad/kenney_cars/delivery-flat.glb", "p": Vector3(30, 0, 34), "e": 2.0},
	]
	for t2 in trastos:
		var esc2: PackedScene = load(String(t2["r"]))
		if esc2 == null:
			continue
		var nodo: Node3D = esc2.instantiate()
		nodo.scale = Vector3.ONE * float(t2["e"])
		nodo.position = base + (t2["p"] as Vector3)
		nodo.rotation.y = 0.6
		add_child(nodo)

	## El desguace del fondo: piezas sueltas y pilas de ruedas del kit.
	_desguace(base + Vector3(44.0, 0, 60.0), 5510)
	var caja_esc: PackedScene = load("res://assets/ciudad/kenney_cars/box.glb")
	if caja_esc != null:
		var rng := RandomNumberGenerator.new()
		rng.seed = 33117
		for i in range(14):
			var caja: Node3D = caja_esc.instantiate()
			caja.scale = Vector3.ONE * rng.randf_range(2.2, 3.4)
			caja.position = base + Vector3(rng.randf_range(-8.0, 46.0), 0, rng.randf_range(-24.0, 14.0))
			caja.rotation.y = rng.randf() * TAU
			add_child(caja)

# ---------------------------------------------------------------- negocios

## El hotel del club: ocho plantas en la parcela norte, con las mismas ventanas
## que el resto de edificios para que se lea como parte del mismo mundo.
func _hotel() -> void:
	var pos := Vector3(268.0, 0, -218.0)
	var plantas := 8
	var alto := 6.0 * plantas
	var cuerpo := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(26.0, alto, 18.0)
	cuerpo.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.86, 0.82, 0.72)
	mat.roughness = 0.6
	mat.metallic = 0.05
	cuerpo.material_override = mat
	cuerpo.position = pos + Vector3(0, alto * 0.5, 0)
	add_child(cuerpo)
	_ventanas(pos, 26.0, 18.0, plantas)
	var techo := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(27.0, 0.6, 19.0)
	techo.mesh = tm
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = _color_club("c1", Color(0.2, 0.5, 0.3))
	techo.material_override = tmat
	techo.position = pos + Vector3(0, alto + 0.3, 0)
	add_child(techo)
	_cartel(pos + Vector3(0, 0, -14.0), "Hotel del club", true)
