class_name HomenajeCampo3D
extends SubViewportContainer
## EL HOMENAJE EN 3D EN EL CAMPO (orden del dueño, 9-11; hecho el 10-11): tras el partido de despedida, la ceremonia (`CeremoniaDespedida`, a pantalla
## completa) proyecta esta escena: el césped de noche bajo los focos, la grada llena con los colores del club, y en el círculo central los
## HOMENAJEADOS (el mismo modelo 3D que juega, `PlayerSpawner._crear_jugador`) celebrando junto a su CAMISETA RETIRADA enmarcada (el número
## en grande y su apellido). La cámara gira despacio y caen papelitos dorados. Mundo propio en un `SubViewport`: no toca nada del juego.
## Sin pantalla (`--headless`) no se monta nada (`montar` devuelve null).
const MAX_FIGURAS := 3
const PUBLICO := 900   ## espectadores de la grada (un MultiMesh: una sola llamada de dibujo)
const RADIO_CAMARA := 9.0

var _vp: SubViewport
var _cam: Camera3D
var _t := 0.0
var figuras := 0   ## cuántos jugadores 3D se montaron (lo lee la prueba)

## `filas`: [{j: Jugador, dorsal: int}]; `c1`/`c2`: colores del club. Devuelve el contenedor listo para añadir a la interfaz.
static func montar(filas: Array, c1: Color, c2: Color) -> HomenajeCampo3D:
	if DisplayServer.get_name() == "headless":
		return null
	var h := HomenajeCampo3D.new()
	h.stretch = true
	h.custom_minimum_size = Vector2(1100, 380)
	h._vp = SubViewport.new()
	h._vp.own_world_3d = true
	h._vp.msaa_3d = Viewport.MSAA_2X
	h.add_child(h._vp)
	h._escena(filas, c1, c2)
	return h

func _escena(filas: Array, c1: Color, c2: Color) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.03, 0.06)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.6, 0.7)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = Calidad.elegida > Calidad.MINIMO   ## (10-11) el brillo y la sombra de los focos solo con calidad por encima de la mínima
	env.glow_intensity = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)
	var raiz := Node3D.new()
	_vp.add_child(raiz)
	_cesped(raiz)
	_grada(raiz, c1, c2)
	_focos(raiz)
	_figuras(raiz, filas, c1, c2)
	_papelitos(raiz)
	_cam = Camera3D.new()
	_cam.fov = 42.0
	_vp.add_child(_cam)
	_colocar_camara()

func _mat(c: Color, rugosidad := 0.9, emision := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rugosidad
	if emision > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emision
	return m

func _caja(padre: Node3D, pos: Vector3, tam: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	padre.add_child(mi)
	return mi

## El césped a franjas, la línea de medio campo y el círculo central.
func _cesped(raiz: Node3D) -> void:
	for k in 10:
		var tono := Color(0.13, 0.36, 0.16) if k % 2 == 0 else Color(0.16, 0.42, 0.19)
		_caja(raiz, Vector3(-27.0 + 6.0 * k, -0.05, 0.0), Vector3(6.0, 0.1, 40.0), _mat(tono))
	var blanco := _mat(Color(0.92, 0.94, 0.92), 0.6)
	_caja(raiz, Vector3(0, 0.005, 0), Vector3(0.14, 0.01, 40.0), blanco)
	var aro := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 4.45
	tm.outer_radius = 4.6
	tm.rings = 48
	aro.mesh = tm
	aro.scale = Vector3(1, 0.04, 1)
	aro.material_override = blanco
	raiz.add_child(aro)

## Una grada al fondo con el público como puntos de color (MultiMesh), con los colores del club.
func _grada(raiz: Node3D, c1: Color, c2: Color) -> void:
	_caja(raiz, Vector3(0, 4.5, -24.0), Vector3(70, 11, 6), _mat(Color(0.12, 0.13, 0.15)))
	_caja(raiz, Vector3(0, 9.2, -21.5), Vector3(70, 0.4, 2.0), _mat(Color(0.2, 0.2, 0.22)))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = PUBLICO
	var bm := BoxMesh.new()
	bm.size = Vector3(0.38, 0.55, 0.3)
	mm.mesh = bm
	var azar := RandomNumberGenerator.new()
	azar.seed = 1907
	for i in PUBLICO:
		var fila := i / 90
		var x := -31.0 + float(i % 90) * 0.69 + azar.randf_range(-0.12, 0.12)
		var t := Transform3D(Basis(), Vector3(x, 0.6 + fila * 1.05, -18.5 - fila * 0.5))
		mm.set_instance_transform(i, t)
		var r := azar.randf()
		mm.set_instance_color(i, c1 if r < 0.45 else (c2 if r < 0.75 else Color(0.25, 0.22, 0.2)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.95
	mmi.material_override = mat
	raiz.add_child(mmi)

## Dos torres de focos y la luz de la noche sobre el círculo central.
func _focos(raiz: Node3D) -> void:
	var luna := DirectionalLight3D.new()
	luna.rotation_degrees = Vector3(-40, 30, 0)
	luna.light_energy = 0.35
	luna.light_color = Color(0.7, 0.75, 0.95)
	raiz.add_child(luna)
	for lado: float in [-1.0, 1.0]:
		var torre := Vector3(18.0 * lado, 14.0, -12.0)
		_caja(raiz, torre + Vector3(0, -7.0, 0), Vector3(0.5, 14.0, 0.5), _mat(Color(0.3, 0.3, 0.32)))
		_caja(raiz, torre, Vector3(3.2, 1.6, 0.4), _mat(Color(1, 0.97, 0.88), 0.4, 3.0))
		var foco := SpotLight3D.new()
		foco.position = torre
		foco.spot_range = 40.0
		foco.spot_angle = 22.0
		foco.light_energy = 6.0
		foco.light_color = Color(1, 0.96, 0.88)
		foco.shadow_enabled = Calidad.elegida > Calidad.MINIMO
		raiz.add_child(foco)
		foco.transform = Transform3D(Basis(), torre).looking_at(Vector3(0, 0.8, 0), Vector3.UP)

## Los homenajeados en el círculo central, celebrando, y a su espalda la camiseta retirada enmarcada.
func _figuras(raiz: Node3D, filas: Array, c1: Color, c2: Color) -> void:
	var spawner = load("res://visor/player_spawner.gd").new()
	var n := mini(filas.size(), MAX_FIGURAS)
	for k in n:
		var f: Dictionary = filas[k]
		var j: Jugador = f["j"]
		var x := (float(k) - float(n - 1) * 0.5) * 1.6
		var nodo := Node3D.new()
		nodo.position = Vector3(x, 0, 0.6)
		raiz.add_child(nodo)
		var datos := Puente3D.jugador(j)
		var look: Array = load("res://visor/player_spawner.gd")._look_de(datos)
		var puesto := "POR" if j.pos_e == "POR" else "DEL"
		var d: Dictionary = spawner._crear_jugador(nodo, j.id, puesto, "", c1, c2, "liso", maxi(int(f.get("dorsal", j.dorsal)), 1),
			look[0], look[1], look[2], Color(0, 0, 0, 0), datos)
		if not d.is_empty():
			figuras += 1
			var ap: AnimationPlayer = d.get("anim")
			if ap != null and ap.has_animation("celebrar"):
				ap.play("celebrar")
		_camiseta(raiz, Vector3(x, 0, -1.4), int(f.get("dorsal", 0)), j.nombre, c1, c2)
	if spawner is Node:
		(spawner as Node).queue_free()

## La camiseta retirada, enmarcada en un atril dorado: el número en grande y el apellido.
func _camiseta(raiz: Node3D, base: Vector3, dorsal: int, nombre: String, c1: Color, c2: Color) -> void:
	var oro := _mat(Color(0.95, 0.78, 0.3), 0.25)
	oro.metallic = 0.85
	_caja(raiz, base + Vector3(0, 1.1, 0), Vector3(0.08, 2.2, 0.08), oro)
	_caja(raiz, base + Vector3(0, 2.35, 0), Vector3(1.25, 1.45, 0.06), oro)
	_caja(raiz, base + Vector3(0, 2.35, 0.03), Vector3(1.15, 1.35, 0.04), _mat(Color(0.06, 0.07, 0.08)))
	var tela := _mat(c1, 0.8)
	_caja(raiz, base + Vector3(0, 2.3, 0.07), Vector3(0.62, 0.78, 0.03), tela)
	_caja(raiz, base + Vector3(0, 2.6, 0.07), Vector3(0.98, 0.22, 0.03), tela)
	for par: Array in [[str(dorsal) if dorsal > 0 else "★", 140, Vector3(0, 2.28, 0.1)], [nombre.split(" ")[-1].to_upper(), 46, Vector3(0, 2.62, 0.1)]]:
		var l := Label3D.new()
		l.text = String(par[0])
		l.font_size = int(par[1])
		l.pixel_size = 0.0035
		l.modulate = c2 if c2.get_luminance() > 0.35 or c1.get_luminance() < 0.35 else Color(1, 1, 1)
		l.outline_size = 8
		l.position = base + (par[2] as Vector3)
		raiz.add_child(l)

## Papelitos dorados que caen sobre el círculo central.
func _papelitos(raiz: Node3D) -> void:
	var p := CPUParticles3D.new()
	p.amount = 220
	p.lifetime = 5.0
	p.preprocess = 3.0
	p.position = Vector3(0, 9.0, 0)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(8, 0.5, 5)
	p.gravity = Vector3(0, -1.6, 0)
	p.direction = Vector3(0, -1, 0)
	p.spread = 30.0
	p.angular_velocity_min = -180.0
	p.angular_velocity_max = 180.0
	var qm := QuadMesh.new()
	qm.size = Vector2(0.08, 0.05)
	p.mesh = qm
	var mat := _mat(Color(1.0, 0.82, 0.3), 0.3, 0.6)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	p.material_override = mat
	p.color_ramp = null
	raiz.add_child(p)

func _colocar_camara() -> void:
	var ang := sin(_t * 0.18) * 0.55
	var pos := Vector3(sin(ang) * RADIO_CAMARA, 2.6 + sin(_t * 0.3) * 0.25, cos(ang) * RADIO_CAMARA)
	_cam.transform = Transform3D(Basis(), pos).looking_at(Vector3(0, 1.45, -0.2), Vector3.UP)   ## sin `look_at`: vale también antes de entrar en la escena

func _process(d: float) -> void:
	if _cam == null:
		return
	_t += d
	_colocar_camara()
