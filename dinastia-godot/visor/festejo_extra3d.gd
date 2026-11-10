class_name FestejoExtra3D
extends RefCounted
## LOS FESTEJOS EXTRA EN 3D (10-11): champán en el VESTUARIO, DESFILE en autobús descapotable por una calle con gente y PASILLO de campeón que
## hace el rival. Los monta `FestejoCampo3D` (sus modelos reales con `_jugador`, sus cajas y materiales); aquí solo la escena de cada uno y
## su movimiento (`tick`, que llama `_process` del festejo). Coste contenido: edificios y público en MultiMesh (una llamada de dibujo cada uno).

## ---- CHAMPÁN EN EL VESTUARIO ----
static func champan(f: FestejoCampo3D, raiz: Node3D, sp, once: Array, c1: Color, c2: Color) -> void:
	f._caja(raiz, Vector3(0, -0.05, 0), Vector3(12, 0.1, 8), f._mat(Color(0.32, 0.34, 0.38), 0.6))   ## suelo
	f._caja(raiz, Vector3(0, 2.0, -2.6), Vector3(12, 4.0, 0.2), f._mat(Color(0.82, 0.84, 0.86)))   ## pared
	for i in 9:   ## taquillas con el color del club y una placa con el dorsal
		var x := -4.4 + i * 1.1
		f._caja(raiz, Vector3(x, 1.2, -2.3), Vector3(1.0, 2.4, 0.5), f._mat(c1.darkened(0.35), 0.5))
		f._caja(raiz, Vector3(x, 2.1, -2.04), Vector3(0.5, 0.22, 0.02), f._mat(c2, 0.5))
	f._caja(raiz, Vector3(0, 0.25, -1.6), Vector3(9.5, 0.08, 0.5), f._mat(Color(0.45, 0.32, 0.2), 0.7))   ## banco
	var luz := OmniLight3D.new()
	luz.position = Vector3(0, 3.6, 0.5)
	luz.omni_range = 9.0
	luz.light_energy = 2.2
	luz.light_color = Color(1, 0.93, 0.8)
	raiz.add_child(luz)
	var n := mini(once.size(), 7)
	for k in n:
		var x := (float(k) - float(n - 1) * 0.5) * 1.05
		var nodo := f._jugador(raiz, sp, once[k], Vector3(x, 0, -0.6 + (k % 2) * 0.5), 0.0, "celebrar_ls" if k % 2 == 0 else "celebrar", c1, c2, k * 0.4)
		if k % 2 == 0:   ## los que descorchan: el chorro de espuma dorada sale de las manos, hacia arriba y adelante
			var p := CPUParticles3D.new()
			p.amount = 45
			p.lifetime = 1.1
			p.position = Vector3(0.15, 1.9, 0.25)
			p.direction = Vector3(0.3 if k % 4 == 0 else -0.3, 1.0, 0.6)
			p.spread = 14.0
			p.initial_velocity_min = 3.2
			p.initial_velocity_max = 4.2
			p.gravity = Vector3(0, -6.0, 0)
			var sm := SphereMesh.new()
			sm.radius = 0.016
			sm.height = 0.032
			sm.radial_segments = 6
			sm.rings = 3
			p.mesh = sm
			p.material_override = f._mat(Color(1, 0.92, 0.6), 0.2, 0.6)
			nodo.add_child(p)

## ---- DESFILE EN AUTOBÚS DESCAPOTABLE ----
static func desfile(f: FestejoCampo3D, raiz: Node3D, sp, once: Array, c1: Color, c2: Color) -> Node3D:
	f._caja(raiz, Vector3(0, -0.05, 0), Vector3(80, 0.1, 9), f._mat(Color(0.22, 0.22, 0.25), 0.8))   ## la calzada
	for lado: float in [-1.0, 1.0]:
		f._caja(raiz, Vector3(0, 0.08, lado * 5.5), Vector3(80, 0.16, 2.0), f._mat(Color(0.5, 0.5, 0.52)))   ## aceras
	var azar := RandomNumberGenerator.new()
	azar.seed = 77
	## Edificios: un MultiMesh de cajas de alturas y tonos distintos a los dos lados.
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = 32
	var bm := BoxMesh.new()
	bm.size = Vector3(1, 1, 1)
	mm.mesh = bm
	for i in 32:
		var lado := -1.0 if i % 2 == 0 else 1.0
		var alto := azar.randf_range(5, 14)
		var ancho := azar.randf_range(3.5, 5.0)
		var x := -38.0 + float(i / 2) * 5.0
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(ancho, alto, 4.0)), Vector3(x, alto * 0.5, lado * 8.6)))
		var tono := azar.randf_range(0.28, 0.5)
		mm.set_instance_color(i, Color(tono, tono * 0.95, tono * 1.05))
	_multimesh(raiz, mm)
	## El público en las aceras, con los colores del club (otro MultiMesh).
	var gente := MultiMesh.new()
	gente.transform_format = MultiMesh.TRANSFORM_3D
	gente.use_colors = true
	gente.instance_count = 360
	var cm := CapsuleMesh.new()
	cm.radius = 0.22
	cm.height = 1.6
	cm.radial_segments = 6
	cm.rings = 2
	gente.mesh = cm
	for i in 360:
		var lado := -1.0 if i % 2 == 0 else 1.0
		var x := -38.0 + azar.randf() * 76.0
		gente.set_instance_transform(i, Transform3D(Basis(), Vector3(x, 0.95, lado * azar.randf_range(4.8, 6.3))))
		var r := azar.randf()
		gente.set_instance_color(i, c1 if r < 0.5 else (c2 if r < 0.8 else Color(0.2, 0.2, 0.22)))
	_multimesh(raiz, gente)
	var sol := DirectionalLight3D.new()   ## luz de tarde
	sol.rotation_degrees = Vector3(-35, -40, 0)
	sol.light_energy = 0.9
	sol.light_color = Color(1, 0.9, 0.78)
	raiz.add_child(sol)
	## El autobús: piso de abajo cerrado (color del club), piso de arriba descubierto con baranda, ruedas.
	var bus := Node3D.new()
	raiz.add_child(bus)
	f._caja(bus, Vector3(0, 1.35, 0), Vector3(9.0, 2.2, 2.5), f._mat(c1, 0.5))
	f._caja(bus, Vector3(0, 1.1, 1.26), Vector3(8.4, 0.5, 0.02), f._mat(Color(0.1, 0.12, 0.16), 0.2))   ## ventanas
	f._caja(bus, Vector3(0, 2.5, 0), Vector3(9.0, 0.12, 2.5), f._mat(c2, 0.5))   ## piso de arriba
	for z: float in [-1.2, 1.2]:
		f._caja(bus, Vector3(0, 3.05, z), Vector3(9.0, 0.08, 0.08), f._mat(c2, 0.4))   ## baranda
	for x: float in [-3.2, 3.2]:
		for z: float in [-1.25, 1.25]:
			var rueda := MeshInstance3D.new()
			var cil := CylinderMesh.new()
			cil.top_radius = 0.5
			cil.bottom_radius = 0.5
			cil.height = 0.3
			rueda.mesh = cil
			rueda.rotation_degrees = Vector3(90, 0, 0)
			rueda.position = Vector3(x, 0.5, z)
			rueda.material_override = f._mat(Color(0.08, 0.08, 0.09), 0.8)
			bus.add_child(rueda)
	var n := mini(once.size(), 7)
	for k in n:
		var x := (float(k) - float(n - 1) * 0.5) * 1.15
		var nodo := f._jugador(bus, sp, once[k], Vector3(x, 2.56, 0.3 - (k % 2) * 0.6), 0.0, "celebrar" if k % 2 == 0 else "celebrar_ls", c1, c2, k * 0.33)
		if k == n / 2:
			f._capitan = nodo
	f._papelitos(bus)
	return bus

static func _multimesh(raiz: Node3D, mm: MultiMesh) -> void:
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.9
	mmi.material_override = mat
	raiz.add_child(mmi)

## ---- PASILLO DE CAMPEÓN ----
## El rival, en dos filas enfrentadas, aplaude; el campeón pasa por el medio caminando. Devuelve los que caminan.
static func pasillo(f: FestejoCampo3D, raiz: Node3D, sp, once: Array, rival: Club, c1: Color, c2: Color) -> Array[Node3D]:
	var r1 := Color(rival.color1) if rival != null else Color(0.55, 0.1, 0.1)
	var r2 := Color(rival.color2) if rival != null else Color.WHITE
	var de_rival: Array = rival.once() if rival != null else []
	if de_rival.is_empty():
		de_rival = once
	for k in mini(de_rival.size(), 10):
		var fila := -1.0 if k % 2 == 0 else 1.0
		var x := -4.0 + float(k / 2) * 2.0
		f._jugador(raiz, sp, de_rival[k], Vector3(x, 0, fila * 1.3), PI if fila > 0 else 0.0, "aplaudir", r1, r2, k * 0.21)
	var caminan: Array[Node3D] = []
	for k in mini(once.size(), 5):
		caminan.append(f._jugador(raiz, sp, once[k], Vector3(-7.0 - k * 1.6, 0, 0), PI * 0.5, "caminar|trotar|run", c1, c2, k * 0.3))
	return caminan

## El paso del tiempo de los extras: el bus avanza por la calle; el campeón cruza el pasillo y vuelve a empezar.
static func tick(f: FestejoCampo3D, t: float) -> void:
	if f._bus != null:
		f._bus.position.x = fmod(t * 2.2, 40.0) - 20.0
	for k in f._caminan.size():
		var n := f._caminan[k]
		if is_instance_valid(n):
			n.position.x = fmod(t * 1.3 + 7.0 - k * 1.6 + 30.0, 16.0) - 8.0

## ---- TIFOS EN LA GRADA (finales) ----
## Dos lonas gigantes sobre el público: el ESCUDO del club y una de franjas con sus dos colores. Baratas: dos cuadros, una textura de 128 px
## (la del escudo, que ya existe) y otra de 8×1 px; no se montan en ULTRA BAJA (ahí no hay 3D).
static func tifos(raiz: Node3D, club: Club, c1: Color, c2: Color) -> int:
	var franjas := Image.create(8, 1, false, Image.FORMAT_RGB8)
	for x in 8:
		franjas.set_pixel(x, 0, c1 if x % 2 == 0 else c2)
	var texs: Array[Texture2D] = [Escudo.textura(club, 128), ImageTexture.create_from_image(franjas)]
	var puestas := 0
	for k in 2:
		if texs[k] == null:
			continue
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(12.0, 8.0) if k == 0 else Vector2(22.0, 7.0)
		mi.mesh = q
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = texs[k]
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST if k == 1 else BaseMaterial3D.TEXTURE_FILTER_LINEAR
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR if k == 0 else BaseMaterial3D.TRANSPARENCY_DISABLED
		mat.roughness = 0.95
		mi.material_override = mat
		mi.position = Vector3(-14.0, 6.0, -19.6) if k == 0 else Vector3(9.0, 5.6, -19.8)
		mi.rotation_degrees = Vector3(-18, 0, 0)   ## inclinada como la grada
		raiz.add_child(mi)
		puestas += 1
	return puestas
