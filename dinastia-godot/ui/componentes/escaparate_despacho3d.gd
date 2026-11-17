class_name EscaparateDespacho3D
extends RefCounted
## EL ESCRITORIO DEL DESPACHO EN 3D (17-11-2026, orden del dueño: «con el motor»): una escena pequeña con un escritorio de madera, monitor, lámpara cálida y los papeles según los asuntos por decidir:
## 0 = ordenado (teclado, taza y una pila pequeña), 1 = pendientes (papeles sueltos y una carpeta abierta), 2 = desbordado (pilas altas y papeles por todas partes, nota roja). Se renderiza UNA vez por estado
## y color de club (SubViewport persistente con `UPDATE_ONCE`) y la tarjeta solo enseña su textura. Sin pantalla (`--headless`) devuelve null y la tarjeta usa el dibujo plano.

## (17-11, cierre) APAGADO detrás de esta bandera: en la captura de software el render salió negro y no se pudo verificar en una GPU real; mientras tanto la tarjeta usa el dibujo plano de siempre. Se enciende con `true` cuando se compruebe en el equipo del dueño.
const ACTIVO := false

static var _vistas := {}

static func textura(padre: Node, estado: int, color: Color) -> Texture2D:
	if not ACTIVO or DisplayServer.get_name() == "headless" or padre == null or not padre.is_inside_tree():
		return null
	var k := "%d|%s" % [estado, color.to_html(false)]
	if _vistas.has(k):
		return _vistas[k]
	var tex := ImageTexture.create_from_image(Image.create(8, 8, false, Image.FORMAT_RGBA8))   ## de momento un marcador; cuando se dibuja se copia la imagen y se libera la escena
	_vistas[k] = tex
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.size = Vector2i(560, 360)
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	padre.get_tree().root.add_child(vp)
	_montar(vp, estado, color)
	var dibujos := [0]   ## tras 6 fotogramas DIBUJADOS de verdad (no por tiempo: con la carga de la ventana pueden tardar) se copia la imagen
	var contar := func() -> void: pass
	contar = func() -> void:
		dibujos[0] += 1
		if dibujos[0] < 6:
			return
		RenderingServer.frame_post_draw.disconnect(contar)
		if is_instance_valid(vp):
			var img := vp.get_texture().get_image()
			if img != null and not img.is_empty():
				img.convert(Image.FORMAT_RGBA8)
				var suma := 0.0   ## si la escena salió negra (sin gráfica útil), no se usa: la tarjeta se queda con el dibujo plano de debajo
				for i in 40:
					suma += img.get_pixel((i * 53) % img.get_width(), (i * 31) % img.get_height()).get_luminance()
				if suma / 40.0 > 0.04:
					tex.set_image(img)
			vp.queue_free()
	RenderingServer.frame_post_draw.connect(contar)
	return tex

static func _mat(c: Color, emisivo := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	if emisivo > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emisivo
	return m

static func _caja(raiz: Node3D, tam: Vector3, pos: Vector3, c: Color, yaw := 0.0, emisivo := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	mi.mesh = bm
	mi.material_override = _mat(c, emisivo)
	mi.position = pos
	mi.rotation.y = yaw
	raiz.add_child(mi)
	return mi

static func _montar(vp: SubViewport, estado: int, color: Color) -> void:
	var raiz := Node3D.new()
	vp.add_child(raiz)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = color.darkened(0.55)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.82, 0.78)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	raiz.add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-52, 28, 0)
	sol.light_energy = 1.0
	raiz.add_child(sol)
	var lampara := OmniLight3D.new()
	lampara.position = Vector3(0.7, 1.35, 0.1)
	lampara.light_color = Color(1.0, 0.86, 0.6)
	lampara.light_energy = 1.6
	lampara.omni_range = 3.0
	raiz.add_child(lampara)
	var cam := Camera3D.new()
	cam.fov = 42.0
	raiz.add_child(cam)
	cam.look_at_from_position(Vector3(0.0, 1.55, 2.3), Vector3(0.0, 0.8, 0.0))
	_caja(raiz, Vector3(8, 0.05, 6), Vector3(0, -0.02, 0), Color("2b2623"))   ## el suelo
	_caja(raiz, Vector3(8, 3, 0.1), Vector3(0, 1.5, -0.9), color.darkened(0.35))   ## la pared del fondo, del color del club
	var madera := Color("8a5a33")
	_caja(raiz, Vector3(2.3, 0.08, 1.0), Vector3(0, 0.74, 0), madera)
	for x in [-1.05, 1.05]:
		for z in [-0.4, 0.4]:
			_caja(raiz, Vector3(0.08, 0.72, 0.08), Vector3(x, 0.36, z), madera.darkened(0.3))
	_caja(raiz, Vector3(0.66, 0.4, 0.03), Vector3(-0.35, 1.1, -0.3), Color("1c2430"))   ## el monitor y su pantalla
	_caja(raiz, Vector3(0.6, 0.34, 0.01), Vector3(-0.35, 1.1, -0.28), Color("8fc2ea") if estado < 2 else Color("e5484d"), 0.0, 0.9)
	_caja(raiz, Vector3(0.08, 0.3, 0.06), Vector3(-0.35, 0.93, -0.3), Color("2b323b"))
	_caja(raiz, Vector3(0.03, 0.55, 0.03), Vector3(0.7, 1.0, -0.2), Color("2b323b"))   ## la lámpara
	_caja(raiz, Vector3(0.3, 0.12, 0.2), Vector3(0.7, 1.3, -0.1), color.lightened(0.15), 0.0, 0.4)
	_caja(raiz, Vector3(0.1, 0.1, 0.1), Vector3(0.95, 0.83, 0.2), color)   ## taza
	var rng := RandomNumberGenerator.new()
	rng.seed = 100 + estado
	if estado == 0:
		_caja(raiz, Vector3(0.5, 0.02, 0.17), Vector3(-0.35, 0.79, 0.25), Color("30363d"))   ## teclado
		_caja(raiz, Vector3(0.26, 0.03, 0.2), Vector3(0.3, 0.8, 0.2), Color("f4f1e8"))   ## una pila pequeña
	else:
		var papeles := 4 if estado == 1 else 14
		for i in papeles:
			var alto := 0.0 if estado == 1 else float(i % 4) * 0.03
			_caja(raiz, Vector3(0.28, 0.012, 0.2), Vector3(rng.randf_range(-0.95, 0.6), 0.79 + alto, rng.randf_range(-0.05, 0.4)), Color("f4f1e8") if i % 3 else Color("e9e2c8"), rng.randf_range(-0.6, 0.6))
		_caja(raiz, Vector3(0.34, 0.018, 0.24), Vector3(0.38, 0.8, 0.28), Color("d9b44a"), 0.25)   ## la carpeta abierta
		_caja(raiz, Vector3(0.34, 0.018, 0.24), Vector3(0.74, 0.8, 0.3), Color("e6c35c"), -0.2)
		_caja(raiz, Vector3(0.1, 0.01, 0.1), Vector3(-0.1, 0.8 + (0.0 if estado == 1 else 0.12), 0.0), Color("ffc857") if estado == 1 else Color("e5484d"))   ## la nota
	if estado == 2:
		for k in 4:
			_caja(raiz, Vector3(0.3, 0.12 + k * 0.1, 0.22), Vector3(-0.9 + k * 0.42, 0.8 + (0.12 + k * 0.1) * 0.5, 0.32 - k * 0.02), Color("f4f1e8"), rng.randf_range(-0.2, 0.2))
