class_name SubsueloDetalle
extends RefCounted
## EL DETALLE DEL SUBSUELO (27-10-2026): lo que hace que parezca un túnel de servicio y no cajas lisas.
## `materiales` da textura de hormigón al suelo y las paredes; `montar` añade franjas de peligro, abrazaderas,
## charcos, extintores, señales de salida, marcos de puerta con el color de cada red, ventiladores que giran
## y goteras. `s` es el `SubsueloCiudad` (sin tipo, como en `SubsueloMando`).

static func _ruido(semilla: int, freq: float, tipo: int) -> ImageTexture:
	var n := FastNoiseLite.new()
	n.seed = semilla
	n.noise_type = tipo
	n.frequency = freq
	n.fractal_octaves = 3
	var img := n.get_image(256, 256, false, false, true)
	img.convert(Image.FORMAT_RGB8)
	img.adjust_bcs(1.2, 0.35, 1.0)                ## poco contraste: mancha el hormigón sin parecer roca
	return ImageTexture.create_from_image(img)

## Hormigón con manchas en las paredes y el techo; suelo de losa más oscura y húmeda.
static func materiales(s) -> void:
	var pared: StandardMaterial3D = s._concreto
	pared.albedo_texture = _ruido(7, 0.045, FastNoiseLite.TYPE_SIMPLEX_SMOOTH)
	pared.albedo_color = Color(0.5, 0.52, 0.5)
	pared.uv1_triplanar = true
	pared.uv1_scale = Vector3(0.3, 0.3, 0.3)
	var suelo: StandardMaterial3D = s._suelo
	suelo.albedo_texture = _ruido(11, 0.05, FastNoiseLite.TYPE_CELLULAR)
	suelo.albedo_color = Color(0.4, 0.4, 0.4)
	suelo.uv1_triplanar = true
	suelo.uv1_scale = Vector3(0.35, 0.35, 0.35)
	suelo.roughness = 0.55

static func montar(s) -> void:
	_peligro(s)
	_abrazaderas(s)
	_charcos(s)
	_extintores_y_salidas(s)
	_marcos(s)
	_ventiladores(s)
	for p in [Vector3(14.0, 4.3, -1.0), Vector3(40.0, 4.3, 1.0), Vector3(21.0, 4.3, -20.0), Vector3(33.0, 4.3, 18.0), Vector3(75.0, 4.3, 24.0)]:
		_gotera(s, p)

## Franja amarilla y negra a los dos lados del canal del colector.
static func _peligro(s) -> void:
	var amarillo: StandardMaterial3D = s._mat(Color(0.9, 0.72, 0.05), 0.6)
	var negro: StandardMaterial3D = s._mat(Color(0.05, 0.05, 0.05), 0.6)
	for sz: float in [-1.45, 1.45]:
		s._caja(Vector3(32.0, 0.035, sz), Vector3(56.0, 0.02, 0.22), amarillo)
		for k in 28:
			s._caja(Vector3(5.5 + float(k) * 2.0, 0.045, sz), Vector3(0.5, 0.02, 0.22), negro)

static func _abrazaderas(s) -> void:
	var m: StandardMaterial3D = s._mat(Color(0.22, 0.23, 0.25), 0.4)
	for k in 9:
		var x := 9.0 + float(k) * 6.0
		for sz: float in [-2.45, 2.45]:
			s._caja(Vector3(x, 3.9, sz), Vector3(0.18, 0.7, 0.7), m)
			s._caja(Vector3(x, 4.3, sz), Vector3(0.12, 0.6, 0.12), m)

static func _charcos(s) -> void:
	var m: StandardMaterial3D = s._mat(Color(0.05, 0.07, 0.08), 0.04)
	m.metallic = 0.5
	for p in [Vector3(12.0, 0.04, 2.0), Vector3(27.0, 0.04, -1.9), Vector3(48.0, 0.04, 2.1), Vector3(21.0, 0.04, -14.0), Vector3(33.0, 0.04, 14.0), Vector3(47.0, 0.04, -20.0), Vector3(66.0, 0.04, 4.0)]:
		s._caja(p, Vector3(2.2 + float(int(p.x) % 3), 0.02, 1.2), m)

static func _extintores_y_salidas(s) -> void:
	var rojo: StandardMaterial3D = s._mat(Color(0.85, 0.08, 0.06), 0.4)
	for p in [Vector3(12.0, 0.5, -2.7), Vector3(21.0, 0.5, -5.0), Vector3(33.0, 0.5, 5.0), Vector3(47.0, 0.5, -5.0), Vector3(63.0, 0.5, -9.4), Vector3(62.0, 0.5, 15.0)]:
		var x: float = p.x
		s._caja(Vector3(x - 1.4 if int(x) % 2 == 0 else x + 1.4, 0.55, p.z), Vector3(0.22, 0.7, 0.22), rojo)
	for c in [[Vector3(6.2, 2.6, -2.85), "← SALIDA"], [Vector3(20.0, 2.6, -3.4), "SALIDA ↓"], [Vector3(33.0, 2.6, 3.6), "↑ SALIDA"], [Vector3(46.0, 2.6, -3.4), "SALIDA ↓"]]:
		var l: Label3D = s._rotulo(c[0], String(c[1]), 0.006, false, 0.0)
		l.modulate = Color(0.2, 1.0, 0.4)
		l.outline_size = 4

## Marcos de puerta en cada entrada de galería, con el color de la red.
static func _marcos(s) -> void:
	for c in [[21.0, -3.0, Color(0.95, 0.5, 0.1), "⚡ ELECTRICIDAD"], [33.0, 3.0, Color(0.2, 0.5, 0.95), "💧 AGUA POTABLE"],
			[47.0, -3.0, Color(0.9, 0.72, 0.1), "🔥 GAS"], [60.0, 0.0, Color(0.2, 0.9, 0.9), "CENTRO DE MANDO"]]:
		var x: float = c[0]
		var z: float = c[1]
		var col: Color = c[2]
		var m: StandardMaterial3D = s._mat(col, 0.5, 0.35)
		if z == 0.0:
			s._caja(Vector3(x, 3.9, 0), Vector3(0.3, 0.3, 6.0), m)
			s._caja(Vector3(x, 2.0, -2.9), Vector3(0.3, 4.0, 0.3), m)
			s._caja(Vector3(x, 2.0, 2.9), Vector3(0.3, 4.0, 0.3), m)
			var l0: Label3D = s._rotulo(Vector3(x - 0.2, 3.5, 0), String(c[3]), 0.0055, false, -PI * 0.5)
			l0.modulate = col
		else:
			s._caja(Vector3(x, 3.9, z), Vector3(6.0, 0.3, 0.3), m)
			s._caja(Vector3(x - 2.9, 2.0, z), Vector3(0.3, 4.0, 0.3), m)
			s._caja(Vector3(x + 2.9, 2.0, z), Vector3(0.3, 4.0, 0.3), m)
			var l: Label3D = s._rotulo(Vector3(x, 3.5, z - 0.2 * signf(z)), String(c[3]), 0.0055, false, 0.0 if z < 0.0 else PI)
			l.modulate = col

static func _ventilador(s, pos: Vector3, vel: float) -> void:
	var g := Girador.new()
	g.vel = vel
	g.position = pos
	g.rotation.x = PI * 0.5                       ## su eje (Z local) mira al suelo: las aspas giran en horizontal
	s.add_child(g)
	var m: StandardMaterial3D = s._mat(Color(0.3, 0.32, 0.34), 0.4)
	for a in 3:
		var pala := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.9, 0.18, 0.03)
		pala.mesh = bm
		pala.material_override = m
		pala.rotation.z = TAU * float(a) / 3.0
		pala.position = Vector3(cos(TAU * float(a) / 3.0), sin(TAU * float(a) / 3.0), 0) * 0.5
		g.add_child(pala)
	s._caja(pos + Vector3(0, 0.12, 0), Vector3(0.3, 0.2, 0.3), m)

static func _ventiladores(s) -> void:
	for c in [[Vector3(2.5, 4.35, 2.5), 5.0], [Vector3(66.0, 4.35, -6.0), 4.0], [Vector3(76.0, 4.35, 6.0), 4.0],
			[Vector3(62.0, 4.35, 20.0), 4.5], [Vector3(90.0, 4.35, 32.0), 4.5], [Vector3(21.0, 4.35, -30.0), 5.0]]:
		_ventilador(s, c[0], float(c[1]))

## Una gotera: unas gotas que caen del techo con un reflejo azul.
static func _gotera(s, pos: Vector3) -> void:
	var p := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, -1, 0)
	pm.spread = 2.0
	pm.initial_velocity_min = 0.2
	pm.initial_velocity_max = 0.5
	pm.gravity = Vector3(0, -9.0, 0)
	p.process_material = pm
	var bola := SphereMesh.new()
	bola.radius = 0.018
	bola.height = 0.05
	bola.radial_segments = 4
	bola.rings = 2
	bola.material = s._mat(Color(0.5, 0.75, 1.0), 0.1, 1.2)
	p.draw_pass_1 = bola
	p.amount = 4
	p.lifetime = 0.55
	p.visibility_aabb = AABB(Vector3(-1, -5, -1), Vector3(2, 6, 2))
	p.position = pos
	s.add_child(p)
