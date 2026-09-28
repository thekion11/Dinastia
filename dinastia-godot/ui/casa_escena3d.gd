class_name CasaEscena3D
extends Node3D
## TU CASA (28-9-2026, pendiente "la casa moderna y el móvil 3D en Mi Vida y
## en las cinemáticas"). Desde MI VIDA → Casa y auto, "Ver tu casa" abre una
## escena a pantalla completa: tu DT (el del creador de personaje) en la
## terraza, con el móvil en la mano leyendo lo que dicen de él las redes, la
## casa en la que vives detrás y el auto que usas aparcado al lado.
##
## LA CASA DEPENDE DE DÓNDE VIVES (`VidaDT.VIVIENDAS`):
##   pensión / departamento → un bloque de departamentos;
##   casa / casa con jardín → la casa de dos plantas del complejo residencial;
##   mansión               → LA CASA MODERNA (`oficina_dt.glb`). En el mapa de
##                            la ciudad se leía como una masa rota, pero aquí,
##                            de fondo y a escala de casa, luce lo que es.
## EL MÓVIL (`assets/objetos/movil.glb`): un teléfono genérico, sin marca a la
## vista, en la mano derecha. El brazo se dobla con `_BrazoMovil`, un
## modificador de esqueleto que corre DESPUÉS de la animación de estar de pie:
## así respira y se mueve como siempre pero con el móvil delante de la cara.

const RUTA_MOVIL := "res://assets/objetos/movil.glb"
## [modelo, alto en metros, dónde queda su frente]. Casa y casa con jardín no
## usan modelo: se levantan aquí (`_casa_propia`), porque el complejo
## residencial del paquete de la ciudad, de cerca, se lee como un amasijo de
## tejados (se vio en captura).
const CASAS := {
	"pension": ["res://assets/ciudad/kenney_buildings/building-skyscraper-c.glb", 30.0, -14.0],
	"depto": ["res://assets/ciudad/kenney_buildings/building-skyscraper-a.glb", 36.0, -14.0],
	"mansion": ["res://assets/ciudad/oficina_dt.glb", 20.0, -9.0],
}
const AUTOS := {
	"usado": "res://assets/ciudad/kenney_cars/sedan.glb",
	"familiar": "res://assets/ciudad/kenney_cars/suv.glb",
	"deportivo": "res://assets/ciudad/kenney_cars/sedan-sports.glb",
	"chofer": "res://assets/ciudad/kenney_cars/suv-luxury.glb",
}
## Planos: [posición, a dónde mira, fov]. Corta cada pocos segundos.
const PLANOS := [
	[Vector3(-5.5, 2.4, 9.5), Vector3(0.0, 3.5, -8.0), 55.0],
	[Vector3(1.1, 1.75, 2.6), Vector3(0.0, 1.45, 0.0), 38.0],
	## Por encima del hombro derecho (el DT mira a +Z girado 0,35 rad): se ve
	## el móvil en su mano.
	[Vector3(-1.05, 2.15, -1.4), Vector3(0.03, 1.25, 0.36), 40.0],
]
const SEG_PLANO := 5.0

var _cam: Camera3D
var _t := 0.0
var _plano := -1

## Monta la escena. `vivienda` y `transporte` son las claves de `VidaDT`.
func montar(vivienda: String, transporte: String, asp: Dictionary, c1: Color, c2: Color) -> void:
	_entorno()
	_suelo()
	_casa(vivienda)
	_auto(transporte)
	_terraza()
	_dt(asp, c1, c2)
	_cam = Camera3D.new()
	add_child(_cam)
	_cam.make_current()
	_cortar(0)

func _process(delta: float) -> void:
	_t += delta
	var i := int(_t / SEG_PLANO) % PLANOS.size()
	if i != _plano:
		_cortar(i)
	## Un travelling lento dentro de cada plano, para que no sea una foto.
	var f := fmod(_t, SEG_PLANO) / SEG_PLANO
	var pl: Array = PLANOS[_plano]
	_cam.position = (pl[0] as Vector3) + Vector3(0.35, 0.0, -0.25) * f
	_cam.look_at(pl[1])

func _cortar(i: int) -> void:
	_plano = i
	var pl: Array = PLANOS[i]
	_cam.fov = float(pl[2])
	_cam.position = pl[0]
	_cam.look_at(pl[1])

# --- el decorado --------------------------------------------------------------

func _entorno() -> void:
	var we := WorldEnvironment.new()
	var e := Environment.new()
	var cielo := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.32, 0.52, 0.82)
	sm.sky_horizon_color = Color(0.86, 0.74, 0.62)
	sm.ground_horizon_color = Color(0.55, 0.5, 0.45)
	cielo.sky_material = sm
	e.background_mode = Environment.BG_SKY
	e.sky = cielo
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.9
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = e
	add_child(we)
	## El sol bajo de la tarde, de lado: es la hora de mirar el móvil en casa.
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-28.0, -55.0, 0.0)
	sol.light_energy = 1.25
	sol.light_color = Color(1.0, 0.9, 0.78)
	sol.shadow_enabled = true
	add_child(sol)

func _mat(c: Color, rug: float = 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rug
	return m

func _caja(pos: Vector3, tam: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tam
	mi.mesh = b
	mi.material_override = m
	mi.position = pos
	add_child(mi)
	return mi

func _suelo() -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(400, 400)
	mi.mesh = pm
	mi.material_override = _mat(Color(0.3, 0.46, 0.22), 1.0)
	add_child(mi)

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

## LA CÚPULA DEL PANORAMA. La casa moderna viene de una escena "vista
## panorámica" y trae dentro su propio cielo: una media esfera blanca de
## 100 m que lo tapaba todo (se vio en captura). Se oculta cualquier malla
## que ocupe casi todo el ancho y el fondo del modelo y sea alta como una
## cúpula; la casa y la roca quedan.
static func _quitar_cupula(n: Node3D) -> void:
	var total := AABB()
	var primero := true
	var cajas := {}
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		var a := _xf_hasta(m, n) * m.get_aabb()
		cajas[m] = a
		total = a if primero else total.merge(a)
		primero = false
	if cajas.size() < 2:
		return
	for m: MeshInstance3D in cajas:
		var a: AABB = cajas[m]
		if a.size.x >= total.size.x * 0.85 and a.size.z >= total.size.z * 0.85 and a.size.y >= a.size.x * 0.35:
			m.visible = false

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

## La transformación de `m` relativa a `raiz` (sin la de `raiz`), sin
## depender de estar en el árbol.
static func _xf_hasta(m: Node3D, raiz: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var n: Node = m
	while n != null and n != raiz:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t

func _casa(vivienda: String) -> void:
	if not CASAS.has(vivienda):
		_casa_propia(vivienda == "jardin")
		return
	var d: Array = CASAS[vivienda]
	_modelo(String(d[0]), float(d[1]), 0.0, float(d[2]), 0.0, vivienda == "mansion")

## La casa de barrio: dos plantas, tejado a dos aguas, ventanas con marco y
## puerta. Con jardín, además, la reja baja, el quincho (la parrilla techada)
## y más árboles.
func _casa_propia(jardin: bool) -> void:
	var muro := _mat(Color(0.93, 0.89, 0.8), 0.9)
	var zocalo := _mat(Color(0.55, 0.5, 0.45), 0.9)
	var teja := _mat(Color(0.62, 0.28, 0.2), 0.8)
	var vidrio := _mat(Color(0.35, 0.5, 0.62), 0.15)
	var marco := _mat(Color(0.97, 0.97, 0.97), 0.6)
	var z := -9.0
	_caja(Vector3(0, 3.0, z - 4.0), Vector3(12.0, 6.0, 8.0), muro)
	_caja(Vector3(0, 0.3, z - 4.0), Vector3(12.2, 0.6, 8.2), zocalo)
	## El tejado: dos faldones inclinados.
	for lado in [-1.0, 1.0]:
		## Girar en X baja el lado +Z: el faldón de delante (+1) cae hacia
		## la calle y el de atrás hacia el fondo.
		var f := _caja(Vector3(0, 7.3, z - 4.0 + lado * 2.08), Vector3(12.8, 0.25, 4.9), teja)
		f.rotation_degrees.x = 32.0 * lado
	## Ventanas de las dos plantas y la puerta.
	for fila in [1.6, 4.4]:
		for x in [-4.0, -1.4, 1.4, 4.0]:
			if fila < 3.0 and absf(x) < 2.0:
				continue
			_caja(Vector3(x, fila, z + 0.02), Vector3(1.3, 1.3, 0.06), marco)
			_caja(Vector3(x, fila, z + 0.06), Vector3(1.1, 1.1, 0.04), vidrio)
	_caja(Vector3(0, 1.1, z + 0.04), Vector3(1.2, 2.2, 0.08), _mat(Color(0.38, 0.24, 0.15), 0.7))
	var arboles := [Vector3(-9.0, 0, -6.0), Vector3(8.5, 0, -7.5)]
	if jardin:
		arboles.append_array([Vector3(-11.0, 0, -12.0), Vector3(11.5, 0, -12.5), Vector3(6.0, 0, -3.0)])
		## La reja baja y el quincho con su parrilla.
		var reja := _mat(Color(0.15, 0.15, 0.16), 0.5)
		for i in 13:
			_caja(Vector3(-12.0 + i * 2.0, 0.55, 4.0), Vector3(0.08, 1.1, 0.08), reja)
		_caja(Vector3(0, 1.05, 4.0), Vector3(24.0, 0.06, 0.06), reja)
		_caja(Vector3(8.0, 2.6, -2.0), Vector3(4.2, 0.18, 3.2), teja)
		for px in [6.2, 9.8]:
			for pz in [-3.4, -0.6]:
				_caja(Vector3(px, 1.3, pz), Vector3(0.18, 2.6, 0.18), _mat(Color(0.45, 0.3, 0.2), 0.8))
		_caja(Vector3(8.0, 0.55, -3.2), Vector3(1.6, 1.1, 0.6), _mat(Color(0.6, 0.35, 0.28), 0.9))
	var tronco := _mat(Color(0.35, 0.25, 0.17), 0.9)
	var copa := _mat(Color(0.22, 0.45, 0.2), 1.0)
	for a: Vector3 in arboles:
		_caja(a + Vector3(0, 1.4, 0), Vector3(0.35, 2.8, 0.35), tronco)
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 1.9
		sm.height = 3.6
		mi.mesh = sm
		mi.material_override = copa
		mi.position = a + Vector3(0, 3.9, 0)
		add_child(mi)

func _auto(transporte: String) -> void:
	var ruta := String(AUTOS.get(transporte, ""))
	if ruta == "":
		return
	## Los autos del kit miran a +Z: se deja de lado en la entrada, a la
	## izquierda de la terraza.
	_modelo(ruta, 1.5, -9.5, -0.5, PI * 0.5)

## La terraza de madera: tablones, una baranda baja, una tumbona y una
## planta. Es lo que se ve en primer plano detrás del DT.
func _terraza() -> void:
	var madera := _mat(Color(0.55, 0.38, 0.24), 0.7)
	var madera2 := _mat(Color(0.47, 0.32, 0.2), 0.7)
	for i in 14:
		_caja(Vector3(-1.5, 0.12, -2.8 + i * 0.4), Vector3(9.0, 0.08, 0.38), madera if i % 2 == 0 else madera2)
	var metal := _mat(Color(0.18, 0.19, 0.2), 0.4)
	for x in [-5.9, 2.9]:
		_caja(Vector3(x, 0.6, 0.0), Vector3(0.06, 0.9, 5.6), metal)
		for z in [-2.6, -0.9, 0.9, 2.6]:
			_caja(Vector3(x, 0.55, z), Vector3(0.08, 0.9, 0.08), metal)
	## La tumbona.
	var tela := _mat(Color(0.92, 0.9, 0.85), 0.95)
	_caja(Vector3(-2.6, 0.38, -1.4), Vector3(0.7, 0.12, 1.7), tela)
	var resp := _caja(Vector3(-2.6, 0.68, -2.3), Vector3(0.7, 0.1, 0.8), tela)
	resp.rotation_degrees.x = -55.0
	## La maceta con su planta.
	_caja(Vector3(2.2, 0.45, -2.2), Vector3(0.55, 0.6, 0.55), _mat(Color(0.3, 0.3, 0.32), 0.6))
	var hojas := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.55
	sm.height = 1.1
	hojas.mesh = sm
	hojas.material_override = _mat(Color(0.2, 0.42, 0.18), 1.0)
	hojas.position = Vector3(2.2, 1.2, -2.2)
	add_child(hojas)

func _dt(asp: Dictionary, c1: Color, c2: Color) -> void:
	var d := PersonajeDT.crear(self, asp, c1, c2)
	if d.is_empty():
		return
	var n: Node3D = d["nodo"]
	n.position = Vector3(0.0, 0.16, 0.0)
	n.rotation.y = 0.35
	var ap: AnimationPlayer = d["anim"]
	if ap.has_animation("parado"):
		ap.play("parado")
	var esqs := n.find_children("*", "Skeleton3D", true, false)
	if esqs.is_empty():
		return
	var esq := esqs[0] as Skeleton3D
	esq.add_child(_BrazoMovil.new())
	var i := esq.find_bone("hand_r")
	if i < 0 or not ResourceLoader.exists(RUTA_MOVIL):
		return
	var ba := BoneAttachment3D.new()
	ba.bone_name = "hand_r"
	esq.add_child(ba)
	var movil: Node3D = (load(RUTA_MOVIL) as PackedScene).instantiate()
	var soporte := Node3D.new()
	ba.add_child(soporte)
	soporte.add_child(movil)
	## El modelo mide 1,84 de largo: a 16 cm. Largo (X del modelo) a lo largo
	## de la mano (Y del hueso) y la pantalla hacia la cara.
	movil.scale = Vector3.ONE * (0.16 / 1.84)
	soporte.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	soporte.position = Vector3(0.0, 0.09, 0.03)

## EL BRAZO CON EL MÓVIL. Corre después de la animación: dobla el brazo
## derecho hasta dejar la mano delante del pecho y baja la cabeza hacia ella.
## Trabaja en el espacio del esqueleto: el eje de cada hueso es su Y (va al
## hijo), así que se gira cada uno para que apunte a su dirección objetivo.
class _BrazoMovil extends SkeletonModifier3D:
	const OBJETIVOS := [
		["upperarm_r", "lowerarm_r", Vector3(-0.18, -0.92, 0.3)],
		["lowerarm_r", "hand_r", Vector3(0.42, 0.5, 0.76)],
	]
	func _process_modification() -> void:
		var esq := get_skeleton()
		if esq == null:
			return
		for o: Array in OBJETIVOS:
			var h := esq.find_bone(String(o[0]))
			var hijo := esq.find_bone(String(o[1]))
			if h < 0 or hijo < 0:
				continue
			var g := esq.get_bone_global_pose(h)
			var dir := (esq.get_bone_global_pose(hijo).origin - g.origin).normalized()
			var obj := (o[2] as Vector3).normalized()
			if dir.length() < 0.5 or dir.is_equal_approx(obj):
				continue
			var q := Quaternion(dir, obj)
			esq.set_bone_global_pose(h, Transform3D(Basis(q) * g.basis, g.origin))
		## La cabeza, mirando la pantalla.
		var c := esq.find_bone("Head")
		if c >= 0:
			var gc := esq.get_bone_global_pose(c)
			esq.set_bone_global_pose(c, Transform3D(Basis(Vector3(1, 0, 0), 0.38).rotated(Vector3.UP, -0.2) * gc.basis, gc.origin))

# --- la pantalla completa -----------------------------------------------------

## Abre la escena sobre `p` (principal), con las últimas noticias de la
## bandeja convertidas en publicaciones de redes.
static func abrir(p: Control, m: Mundo, bandeja: Array) -> Control:
	var pop := Control.new()
	pop.set_anchors_preset(Control.PRESET_FULL_RECT)
	pop.mouse_filter = Control.MOUSE_FILTER_STOP
	p.add_child(pop)
	var fondo := ColorRect.new()
	fondo.color = Color(0.03, 0.035, 0.04)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	pop.add_child(fondo)
	var vp_cont := SubViewportContainer.new()
	vp_cont.stretch = true
	vp_cont.set_anchors_preset(Control.PRESET_FULL_RECT)
	vp_cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pop.add_child(vp_cont)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp_cont.add_child(vp)
	var escena := CasaEscena3D.new()
	vp.add_child(escena)
	var c := m.mi_club()
	var viv := m.vida.vivienda if m.vida != null else "casa"
	var tra := m.vida.transporte if m.vida != null else "micro"
	escena.montar(viv, tra, m.roles.aspecto_3d() if m.roles != null else {},
		Color(c.color1) if c != null else Color("1f5fa8"), Color(c.color2) if c != null else Color.WHITE)

	## El rótulo de abajo a la izquierda: dónde vives.
	var rot := Tema.etiqueta(Tema.TAM_DESTACADO + 4, Tema.TEXTO, "%s %s" % [
		String(VidaDT.VIVIENDAS.get(viv, ["", 0, 0, "🏠"])[3]), String(VidaDT.VIVIENDAS.get(viv, ["Tu casa"])[0])])
	rot.add_theme_constant_override("outline_size", 8)
	rot.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	rot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	rot.offset_left = 36
	rot.offset_top = -70
	rot.offset_bottom = -30
	pop.add_child(rot)

	## Las redes, en un panel con forma de pantalla de móvil.
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Tema.caja(Color(0.06, 0.07, 0.09, 0.9), 22, Color(0.3, 0.32, 0.36)))
	panel.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_left = -400
	panel.offset_right = -30
	panel.offset_top = 80
	panel.offset_bottom = -40
	pop.add_child(panel)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(sc)
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 10)
	sc.add_child(lista)
	lista.add_child(Tema.etiqueta(Tema.TAM_DESTACADO, Tema.ORO, "📱 Lo que dicen de ti"))
	for post: Dictionary in publicaciones(m, bandeja):
		lista.add_child(_tarjeta_post(post))

	var cerrar := Button.new()
	cerrar.text = "✕ Volver"
	cerrar.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	cerrar.offset_left = -130
	cerrar.offset_right = -30
	cerrar.offset_top = 24
	cerrar.offset_bottom = 60
	cerrar.pressed.connect(pop.queue_free)
	pop.add_child(cerrar)
	return pop

## Usuarios inventados para las publicaciones (ninguno es real).
const USUARIOS := ["@hinchadefierro", "@tactica_pura", "@la_grada_habla", "@cronista_del_ascenso",
	"@datosyfutbol", "@elcorner_de_ana", "@puro_barrio_fc", "@mister_de_sofa", "@vozdelsocio",
	"@periodistadeturno", "@abuela_futbolera", "@memesdelgol"]
const REACCIONES_BIEN := ["Qué nivel, míster.", "Esto es lo que queríamos.", "Hay proyecto 🔥", "Me tapo la boca: tenía razón."]
const REACCIONES_MAL := ["Así no, míster.", "Explícame esto 🙄", "Hay que dar explicaciones.", "Paciencia se llama la señora."]
const REACCIONES_NEUTRAS := ["A ver en qué termina.", "Ojo con esto.", "Tema del día.", "Se viene debate."]

## Las últimas noticias como publicaciones: [usuario, texto, reacción, me
## gusta, compartidos]. Sin noticias, una publicación de bienvenida.
static func publicaciones(m: Mundo, bandeja: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d|%d" % [m.anio, m.semana])
	var fama := 1.0
	var c := m.mi_club()
	if c != null:
		fama = 0.3 + float(c.rep) / 40.0
	for i in mini(bandeja.size(), 8):
		var n: Dictionary = bandeja[i]
		var tit := String(n.get("titulo", ""))
		var cuerpo := String(n.get("cuerpo", ""))
		var bueno := tit.contains("✅") or tit.contains("🏆") or tit.contains("💼") or tit.to_lower().contains("gana") or tit.to_lower().contains("cumplido")
		var malo := tit.contains("❌") or tit.contains("⚠") or tit.to_lower().contains("pierde") or tit.to_lower().contains("fallido") or tit.to_lower().contains("lesion")
		var reacciones: Array = REACCIONES_BIEN if bueno else (REACCIONES_MAL if malo else REACCIONES_NEUTRAS)
		out.append({"usuario": USUARIOS[rng.randi() % USUARIOS.size()],
			"texto": "%s %s" % [tit, cuerpo.substr(0, 110) + ("…" if cuerpo.length() > 110 else "")],
			"reaccion": String(reacciones[rng.randi() % reacciones.size()]),
			"me_gusta": int(rng.randf_range(40.0, 900.0) * fama),
			"compartidos": int(rng.randf_range(5.0, 160.0) * fama),
			"tono": "bien" if bueno else ("mal" if malo else "")})
	if out.is_empty():
		out.append({"usuario": "@vozdelsocio", "texto": "Semana tranquila en %s." % (c.nombre if c != null else "el club"),
			"reaccion": "Que siga así.", "me_gusta": 12, "compartidos": 1, "tono": ""})
	return out

static func _tarjeta_post(post: Dictionary) -> PanelContainer:
	var pc := PanelContainer.new()
	var borde := Tema.BIEN if String(post["tono"]) == "bien" else (Color("e5534b") if String(post["tono"]) == "mal" else Color(0.25, 0.27, 0.3))
	pc.add_theme_stylebox_override("panel", Tema.caja(Color(0.1, 0.11, 0.14), 12, borde))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	pc.add_child(v)
	v.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.ORO, String(post["usuario"])))
	var t := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, String(post["texto"]))
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var r := Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE, "💬 " + String(post["reaccion"]))
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(r)
	v.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "♥ %d   ⟳ %d" % [int(post["me_gusta"]), int(post["compartidos"])]))
	return pc
