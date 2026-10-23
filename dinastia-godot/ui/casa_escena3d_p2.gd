extends "res://ui/casa_escena3d_p1.gd"
## [Capa 2/3 de `casa_escena3d.gd`] _caja_de, _modelo, _casa, _piscina, _auto, _pieza … (+15)

static func _caja_de(n: Node3D) -> AABB:
	var ab := AABB()
	var primero := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null or not m.visible:
			continue
		var a := _xf_hasta(m, n) * m.get_aabb()
		ab = a if primero else ab.merge(a)
		primero = false
	return Transform3D(Basis.from_scale(n.scale).rotated(Vector3.UP, n.rotation.y), Vector3.ZERO) * ab

## Carga un modelo, lo escala a `alto` metros y lo apoya en el suelo con el
## frente (su cara +Z) en `frente_z`.
func _modelo(ruta: String, alto: float, x: float, frente_z: float, giro: float = 0.0, panorama: bool = false) -> Node3D:
	if not ResourceLoader.exists(ruta):
		return null
	var esc := load(ruta)
	if not (esc is PackedScene):
		return null
	var n: Node3D = (esc as PackedScene).instantiate()
	var raiz := Node3D.new()
	add_child(raiz)
	raiz.add_child(n)
	raiz.rotation.y = giro
	if panorama:
		_quitar_cupula(n)
	var caja := _caja_de(raiz)
	if caja.size.y <= 0.001:
		return raiz
	var s := alto / caja.size.y
	raiz.scale = Vector3.ONE * s
	caja = _caja_de(raiz)
	## La casa moderna se apoya por SU origen (el suelo de la casa), no por
	## lo más bajo: la roca sobre la que está se hunde bajo el césped en vez
	## de quedar flotando delante como una losa.
	var y := 0.0 if panorama else -caja.position.y
	raiz.position = Vector3(x - (caja.position.x + caja.size.x * 0.5), y, frente_z - (caja.position.z + caja.size.z))
	return raiz

func _casa(vivienda: String) -> void:
	if not CASAS.has(vivienda):
		_casa_propia(vivienda == "jardin")
		return
	var d: Array = CASAS[vivienda]
	_modelo(String(d[0]), float(d[1]), 0.0, float(d[2]), 0.0, vivienda == "mansion")

## La piscina de la mansión: bordillo de piedra y agua que refleja el cielo.
func _piscina() -> void:
	var piedra := _mat(Color(0.82, 0.8, 0.76), 0.8)
	_caja(Vector3(-1.0, 0.06, -5.2), Vector3(10.4, 0.12, 3.6), piedra)
	## El agua con oleaje y reflejo (`CasaNaturaleza.material_agua`).
	_caja(Vector3(-1.0, 0.1, -5.2), Vector3(9.6, 0.06, 2.9), CasaNaturaleza.material_agua())

func _auto(transporte: String) -> void:
	var ruta := String(AUTOS.get(transporte, ""))
	if ruta == "":
		return
	## Los autos del kit miran a +Z: se deja de lado en la entrada, a la
	## izquierda de la terraza.
	_modelo(ruta, 1.5, -9.5, -0.5, PI * 0.5)

func _pieza(padre: Node3D, pos: Vector3, tam: Vector3, m: Material, giro_x: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tam
	mi.mesh = b
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees.x = giro_x
	padre.add_child(mi)
	return mi

## EL SILLÓN DE EXTERIOR ("falta realismo en la silla"): estructura de teca
## con patas, apoyabrazos y respaldo inclinado, y cojines gruesos de lona
## (cápsulas aplastadas, que dan el canto redondeado que una caja no tiene).
## El asiento queda a 0,45 m de la tarima, la altura que usa la pose
## "sentado" (`AnimQuaternius.ALTO_ASIENTO_OFFSET`).
func _sillon(pos: Vector3, giro: float) -> void:
	var s := Node3D.new()
	s.position = pos
	s.rotation.y = giro
	add_child(s)
	var teca := _mat(Color(0.45, 0.3, 0.18), 0.55)
	var lona := _mat(Color(0.9, 0.86, 0.77), 1.0)
	for x in [-0.4, 0.4]:
		for z in [-0.34, 0.34]:
			_pieza(s, Vector3(x, 0.2, z), Vector3(0.06, 0.4, 0.06), teca)
		## Apoyabrazos.
		_pieza(s, Vector3(x, 0.62, 0.0), Vector3(0.1, 0.05, 0.82), teca)
		_pieza(s, Vector3(x, 0.52, 0.34), Vector3(0.05, 0.2, 0.05), teca)
	_pieza(s, Vector3(0, 0.3, 0), Vector3(0.86, 0.06, 0.74), teca)
	## El respaldo, inclinado hacia atrás.
	_pieza(s, Vector3(0, 0.62, -0.36), Vector3(0.74, 0.6, 0.05), teca, -12.0)
	## Cojines: asiento y respaldo.
	var asiento := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.08
	cap.height = 0.74
	asiento.mesh = cap
	asiento.material_override = lona
	asiento.rotation_degrees.z = 90.0
	asiento.scale = Vector3(0.9, 1.0, 4.2)
	asiento.position = Vector3(0, 0.39, 0.02)
	s.add_child(asiento)
	var resp := MeshInstance3D.new()
	var cap2 := CapsuleMesh.new()
	cap2.radius = 0.07
	cap2.height = 0.7
	resp.mesh = cap2
	resp.material_override = lona
	resp.rotation_degrees = Vector3(-12.0, 0.0, 90.0)
	resp.scale = Vector3(1.0, 1.0, 3.8)
	resp.position = Vector3(0, 0.72, -0.28)
	s.add_child(resp)

func _cilindro(padre: Node3D, pos: Vector3, r: float, alto: float, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = alto
	mi.mesh = cm
	mi.material_override = m
	mi.position = pos
	padre.add_child(mi)
	return mi

## La terraza de madera: tablones con su veta (cada uno un tono), baranda de
## metal, alfombra, el sillón de exterior donde se sienta el DT, una mesita
## con su taza y una maceta.
func _terraza() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 14:
		var tono := Color(0.52, 0.36, 0.23).darkened(rng.randf_range(-0.08, 0.12))
		_caja(Vector3(-1.5, 0.12, -2.8 + i * 0.4), Vector3(9.0, 0.08, 0.38), _mat(tono, 0.65))
	var metal := _mat(Color(0.18, 0.19, 0.2), 0.4)
	metal.metallic = 0.6
	for x in [-5.9, 2.9]:
		_caja(Vector3(x, 1.05, 0.0), Vector3(0.05, 0.05, 5.6), metal)
		for z in [-2.6, -1.3, 0.0, 1.3, 2.6]:
			_caja(Vector3(x, 0.6, z), Vector3(0.05, 0.9, 0.05), metal)
	## La alfombra bajo el sillón.
	_caja(Vector3(0.1, 0.165, 0.2), Vector3(2.4, 0.01, 1.8), _mat(Color(0.72, 0.45, 0.32), 1.0))
	_caja(Vector3(0.1, 0.17, 0.2), Vector3(2.1, 0.01, 1.5), _mat(Color(0.86, 0.8, 0.68), 1.0))
	_sillon(Vector3(0.0, 0.16, 0.0), 0.35)
	## La mesita redonda a su izquierda, con la taza.
	var mesa := Node3D.new()
	mesa.position = Vector3(0.95, 0.16, 0.15)
	add_child(mesa)
	var teca := _mat(Color(0.42, 0.28, 0.17), 0.55)
	_cilindro(mesa, Vector3(0, 0.5, 0), 0.28, 0.04, teca)
	_cilindro(mesa, Vector3(0, 0.25, 0), 0.03, 0.5, metal)
	_cilindro(mesa, Vector3(0, 0.01, 0), 0.18, 0.02, metal)
	## La taza (se puede tomar: "☕ Tomar un café").
	_taza = Node3D.new()
	_taza.position = Vector3(0.06, 0.565, 0.03)
	mesa.add_child(_taza)
	_cilindro(_taza, Vector3.ZERO, 0.04, 0.09, _mat(Color(0.95, 0.95, 0.93), 0.3))
	_cilindro(_taza, Vector3(0, 0.042, 0), 0.034, 0.005, _mat(Color(0.25, 0.14, 0.08), 0.2))
	var asa := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.012
	tm.outer_radius = 0.022
	asa.mesh = tm
	asa.material_override = _mat(Color(0.95, 0.95, 0.93), 0.3)
	asa.rotation_degrees.x = 90.0
	asa.position = Vector3(0.045, 0, 0)
	_taza.add_child(asa)
	_taza_xf = _taza.transform
	## La maceta con su planta.
	var maceta := _mat(Color(0.3, 0.3, 0.32), 0.6)
	_cilindro(self, Vector3(2.2, 0.45, -2.2), 0.3, 0.6, maceta)
	var hojas := _mat(Color(0.2, 0.42, 0.18), 1.0)
	for k in 5:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.35
		sm.height = 0.7
		mi.mesh = sm
		mi.material_override = hojas
		mi.position = Vector3(2.2 + cos(k * 1.3) * 0.22, 1.0 + k * 0.12, -2.2 + sin(k * 1.3) * 0.22)
		add_child(mi)
	## Dos farolas de jardín: apagadas de día, encendidas al atardecer.
	for fx: Vector3 in [Vector3(-5.6, 0, 2.6), Vector3(2.6, 0, 2.6)]:
		_caja(fx + Vector3(0, 0.75, 0), Vector3(0.07, 1.5, 0.07), metal)
		var globo := MeshInstance3D.new()
		var gs := SphereMesh.new()
		gs.radius = 0.12
		gs.height = 0.24
		globo.mesh = gs
		var gm := StandardMaterial3D.new()
		gm.albedo_color = Color(1.0, 0.95, 0.85)
		gm.emission_enabled = true
		gm.emission = Color(1.0, 0.8, 0.5)
		gm.emission_energy_multiplier = 0.0
		globo.material_override = gm
		globo.position = fx + Vector3(0, 1.58, 0)
		add_child(globo)
		var luz := OmniLight3D.new()
		luz.position = fx + Vector3(0, 1.5, 0)
		luz.light_color = Color(1.0, 0.8, 0.55)
		luz.light_energy = 0.0
		luz.omni_range = 7.0
		luz.set_meta("globo", gm)
		add_child(luz)
		_farolas.append(luz)

# --- lo vivo: naturaleza e interacción -----------------------------------------------

## El césped de briznas (sin crecer bajo la terraza, la casa, la piscina ni
## el auto) y una bandada de pájaros.
func _naturaleza(vivienda: String) -> void:
	var evitar: Array = [Rect2(-6.2, -3.1, 9.4, 6.2), Rect2(-40.0, -60.0, 80.0, 52.5), Rect2(-12.8, -2.8, 6.4, 4.6)]
	if vivienda == "mansion":
		evitar.append(Rect2(-6.4, -7.2, 10.8, 4.2))
	CasaNaturaleza.cesped(self, Vector2(-24.0, -8.0), Vector2(24.0, 22.0), 26000, evitar, 11)
	CasaNaturaleza.pajaros(self, Vector3(0, 0, -12), 7, 3)

## Una pantalla de redes dibujada a mano: fondo oscuro, barra de arriba y
## tarjetas claras con una "foto" de color, una debajo de otra.
static func _textura_feed() -> ImageTexture:
	## Se dibuja en vertical (60×128, como se lee un móvil) y se gira para
	## que el largo de la imagen caiga en el largo del móvil (X de la malla).
	var img := Image.create(60, 128, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.07, 0.08, 0.1))
	img.fill_rect(Rect2i(0, 0, 60, 10), Color(0.12, 0.14, 0.18))
	var fotos := [Color(0.85, 0.45, 0.2), Color(0.25, 0.55, 0.85), Color(0.3, 0.7, 0.4)]
	for k in 3:
		var y := 13 + k * 38
		img.fill_rect(Rect2i(4, y, 52, 35), Color(0.93, 0.94, 0.96))
		img.fill_rect(Rect2i(7, y + 3, 46, 18), fotos[k])
		for r in 3:
			img.fill_rect(Rect2i(7, y + 24 + r * 4, 40 - r * 10, 2), Color(0.55, 0.57, 0.62))
	img.rotate_90(COUNTERCLOCKWISE)
	return ImageTexture.create_from_image(img)

## La taza sigue a la mano izquierda mientras bebe; si no, vuelve a la mesa.
func _animar_taza() -> void:
	if _taza == null or _esq == null or _brazo == null:
		return
	if _brazo.bebiendo():
		var ih := _esq.find_bone("hand_l")
		if ih >= 0:
			var mano := _esq.global_transform * _esq.get_bone_global_pose(ih)
			var im := _esq.find_bone("middle_01_l")
			var nudillo := (_esq.global_transform * _esq.get_bone_global_pose(im)).origin if im >= 0 else mano.origin
			## En el hueco de la mano, un poco hacia la palma, derecha.
			_taza.global_transform = Transform3D(Basis.IDENTITY, mano.origin.lerp(nudillo, 0.7) + Vector3(0, 0.02, 0.03))
			return
	_taza.transform = _taza_xf

func _dt(asp: Dictionary, c1: Color, c2: Color) -> void:
	var d := PersonajeDT.crear(self, asp, c1, c2)
	if d.is_empty():
		return
	var n: Node3D = d["nodo"]
	## SENTADO EN EL SILLÓN ("debería estar en esa silla y haber una
	## animación"): la pose "sentado" de los suplentes, con la raíz bajada lo
	## que baja la cadera (`ALTO_ASIENTO_OFFSET`) sobre la tarima.
	n.position = Vector3(0.0, 0.16 + AnimQuaternius.ALTO_ASIENTO_OFFSET, 0.05)
	n.rotation.y = 0.35
	var ap: AnimationPlayer = d["anim"]
	if ap.has_animation("sentado"):
		ap.play("sentado")
	var esqs := n.find_children("*", "Skeleton3D", true, false)
	if esqs.is_empty():
		return
	var esq := esqs[0] as Skeleton3D
	var brazo := _BrazoMovil.new()
	esq.add_child(brazo)
	_brazo = brazo
	_esq = esq
	var i := esq.find_bone("hand_r")
	if i < 0 or not ResourceLoader.exists(RUTA_MOVIL):
		return
	## EL MÓVIL EN LA MANO (28-9-2026, "ve el tema de la mano, no se ve bien,
	## parece una tablet"). Colgado del hueso de la mano heredaba su giro y
	## quedaba de canto, apaisado y enorme. Ahora vive en un pivote propio que
	## cada vez que se actualiza el esqueleto se pone en la palma, en
	## VERTICAL (el largo hacia arriba) y con la pantalla mirando a la cara.
	var movil: Node3D = (load(RUTA_MOVIL) as PackedScene).instantiate()
	var mallas := movil.find_children("*", "MeshInstance3D", true, false)
	if mallas.is_empty():
		return
	var malla := mallas[0] as MeshInstance3D
	var pivote := Node3D.new()
	add_child(pivote)
	malla.get_parent().remove_child(malla)
	## Sin el dueño del .glb: si no, `add_child` avisa de dueño inconsistente (banco).
	malla.owner = null
	for h in malla.find_children("*", "", true, true):
		h.owner = null
	movil.queue_free()
	pivote.add_child(malla)
	## Medido en la malla: largo en X (1,84), grosor en Y (-0,106..0, la
	## pantalla en -Y; en +Y está el bulto de la cámara) y ancho en Z (0,89).
	## Largo → Y del pivote, pantalla (-Y) → Z del pivote (hacia la cara).
	var ab := malla.get_aabb()
	var escala := 0.15 / maxf(ab.size.x, 0.001)
	var b := Basis(Vector3(0, 1, 0), Vector3(0, 0, -1), Vector3(-1, 0, 0)).scaled(Vector3.ONE * escala)
	malla.transform = Transform3D(b, -(b * ab.get_center()))
	## La pantalla encendida, pegada a la cara -Y.
	var pantalla := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(ab.size.x * 0.92, ab.size.z * 0.88)
	pantalla.mesh = q
	var mp := StandardMaterial3D.new()
	_mat_pantalla = mp
	mp.albedo_texture = _textura_feed()
	mp.emission_enabled = true
	mp.emission_texture = mp.albedo_texture
	mp.emission_energy_multiplier = 0.8
	mp.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pantalla.material_override = mp
	pantalla.rotation_degrees.x = 90.0
	pantalla.position = Vector3(ab.get_center().x, ab.position.y - 0.003, ab.get_center().z)
	malla.add_child(pantalla)
	## LA FUNDA (se elige en Ajustes del móvil): cubre el dorso y los cantos.
	_funda = MeshInstance3D.new()
	var bf := BoxMesh.new()
	bf.size = Vector3(0.078, 0.156, 0.008)
	_funda.mesh = bf
	_funda.position = Vector3(0, 0, -0.006)
	pivote.add_child(_funda)
	aplicar_funda(m_actual)
	var sosten := _SostenMovil.new()
	sosten.esq = esq
	sosten.pivote = pivote
	sosten.brazo = brazo
	add_child(sosten)
	esq.skeleton_updated.connect(sosten.colocar)
	## La taza también se coloca tras el esqueleto, no en `_process` (ahí la
	## mano todavía está en la pose del fotograma anterior).
	esq.skeleton_updated.connect(_animar_taza)

func _cortar(i: int) -> void:
	_plano = i
	var pl: Array = PLANOS[i]
	_cam.fov = float(pl[2])
	## `look_at_from_position` vale también con la escena aún fuera del árbol.
	_cam.look_at_from_position(pl[0], pl[1])

## Monta la escena. `vivienda` y `transporte` son las claves de `VidaDT`.
func montar(vivienda: String, transporte: String, asp: Dictionary, c1: Color, c2: Color) -> void:
	_entorno()
	_suelo()
	_fondo_lejano()
	_casa(vivienda)
	if vivienda == "mansion":
		_piscina()
	_auto(transporte)
	_terraza()
	_naturaleza(vivienda)
	_dt(asp, c1, c2)
	_cam = Camera3D.new()
	add_child(_cam)
	_cam.make_current()
	_cortar(0)

func _process(delta: float) -> void:
	_t += delta
	## La pantalla del móvil 3D pasa publicaciones a golpes, como con el pulgar.
	if _mat_pantalla != null:
		var paso: float = floor(_t / 1.3) + smoothstep(0.0, 0.25, fmod(_t, 1.3))
		_mat_pantalla.uv1_offset = Vector3(fmod(paso * 0.12, 1.0), 0, 0)
	if libre:
		var obj := Vector3(0.0, 1.0, 0.1)
		_cam.fov = 50.0
		_cam.position = obj + Vector3(sin(_yaw) * cos(_pitch), sin(_pitch), cos(_yaw) * cos(_pitch)) * _dist
		_cam.look_at(obj)
		return
	var i := int(_t / SEG_PLANO) % PLANOS.size()
	if i != _plano:
		_cortar(i)
	## Un travelling lento dentro de cada plano, para que no sea una foto.
	var f := fmod(_t, SEG_PLANO) / SEG_PLANO
	var pl: Array = PLANOS[_plano]
	_cam.position = (pl[0] as Vector3) + Vector3(0.35, 0.0, -0.25) * f
	_cam.look_at(pl[1])

## ☕ TOMAR UN CAFÉ: la mano izquierda coge la taza de la mesita, se la lleva
## a la boca, bebe y la deja. Dura unos cuatro segundos.
func tomar_cafe() -> void:
	if _brazo != null and not _brazo.bebiendo():
		_brazo.cafe_desde = Time.get_ticks_msec()

## 🌅 MIRAR EL PAISAJE: deja el móvil a un lado un rato y levanta la vista.
func mirar_paisaje() -> void:
	if _brazo != null:
		_brazo.mirar_hasta = Time.get_ticks_msec() + 6000

## 🌙 / ☀️ Del día al atardecer y vuelta: el sol baja y se tiñe, el cielo se
## vuelve naranja, baja la luz ambiente y se encienden las farolas.
func alternar_hora() -> bool:
	_atardecer = not _atardecer
	var a := _atardecer
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_sol, "rotation_degrees:x", -7.0 if a else -28.0, 2.5)
	tw.tween_property(_sol, "light_color", Color(1.0, 0.6, 0.35) if a else Color(1.0, 0.9, 0.78), 2.5)
	tw.tween_property(_sol, "light_energy", 0.7 if a else 1.25, 2.5)
	tw.tween_property(_env, "ambient_light_energy", 0.45 if a else 0.9, 2.5)
	tw.tween_method(func(c: Color) -> void: _cielo.set_shader_parameter("arriba", c),
		_cielo.get_shader_parameter("arriba") if _cielo.get_shader_parameter("arriba") != null else Color(0.3, 0.52, 0.84),
		Color(0.2, 0.25, 0.48) if a else Color(0.3, 0.52, 0.84), 2.5)
	tw.tween_method(func(c: Color) -> void: _cielo.set_shader_parameter("horizonte", c),
		_cielo.get_shader_parameter("horizonte") if _cielo.get_shader_parameter("horizonte") != null else Color(0.86, 0.8, 0.72),
		Color(0.98, 0.55, 0.3) if a else Color(0.86, 0.8, 0.72), 2.5)
	for luz in _farolas:
		tw.tween_property(luz, "light_energy", 2.2 if a else 0.0, 2.0)
		tw.tween_property(luz.get_meta("globo"), "emission_energy_multiplier", 3.0 if a else 0.0, 2.0)
	return a

## Cámara libre: arrastrar gira alrededor del DT, la rueda acerca y aleja.
func arrastrar(rel: Vector2) -> void:
	_yaw -= rel.x * 0.008
	_pitch = clampf(_pitch + rel.y * 0.006, 0.05, 1.2)

func acercar(paso: float) -> void:
	_dist = clampf(_dist + paso, 1.6, 14.0)
