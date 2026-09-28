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
	[Vector3(-5.5, 2.4, 9.5), Vector3(0.0, 3.0, -8.0), 55.0],
	[Vector3(1.35, 1.45, 2.5), Vector3(0.0, 1.0, 0.0), 36.0],
	## Por encima del hombro derecho (el DT mira a +Z girado 0,35 rad): se ve
	## el móvil encendido en su mano.
	[Vector3(-0.95, 1.95, -1.15), Vector3(0.1, 0.95, 0.45), 40.0],
]
const SEG_PLANO := 5.0

var _cam: Camera3D
var _funda: MeshInstance3D
var _sol: DirectionalLight3D
var _env: Environment
var _cielo: ShaderMaterial
var _farolas: Array[OmniLight3D] = []
var _brazo: _BrazoMovil
var _esq: Skeleton3D
var _taza: Node3D
var _taza_xf := Transform3D.IDENTITY
var _mat_pantalla: StandardMaterial3D
var _atardecer := false
## La cámara libre: se arrastra para girar y la rueda acerca.
var libre := false
var _yaw := 0.6
var _pitch := 0.25
var _dist := 4.5
var m_actual: Mundo
var _t := 0.0
var _plano := -1

## El color de la funda del móvil 3D, el mismo que el del móvil de la pantalla.
func aplicar_funda(m: Mundo) -> void:
	if _funda == null:
		return
	var col := Color("1a1a1a")
	if m != null and m.movil != null:
		col = m.movil.color_funda(m.mi_club())
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.45
	_funda.material_override = mat

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

# --- lo vivo: naturaleza e interacción -----------------------------------------------

## El césped de briznas (sin crecer bajo la terraza, la casa, la piscina ni
## el auto) y una bandada de pájaros.
func _naturaleza(vivienda: String) -> void:
	var evitar: Array = [Rect2(-6.2, -3.1, 9.4, 6.2), Rect2(-40.0, -60.0, 80.0, 52.5), Rect2(-12.8, -2.8, 6.4, 4.6)]
	if vivienda == "mansion":
		evitar.append(Rect2(-6.4, -7.2, 10.8, 4.2))
	CasaNaturaleza.cesped(self, Vector2(-24.0, -8.0), Vector2(24.0, 22.0), 26000, evitar, 11)
	CasaNaturaleza.pajaros(self, Vector3(0, 0, -12), 7, 3)

## ☕ TOMAR UN CAFÉ: la mano izquierda coge la taza de la mesita, se la lleva
## a la boca, bebe y la deja. Dura unos cuatro segundos.
func tomar_cafe() -> void:
	if _brazo != null and not _brazo.bebiendo():
		_brazo.cafe_desde = Time.get_ticks_msec()

## 🌅 MIRAR EL PAISAJE: deja el móvil a un lado un rato y levanta la vista.
func mirar_paisaje() -> void:
	if _brazo != null:
		_brazo.mirar_hasta = Time.get_ticks_msec() + 6000

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
	## El cielo con nubes que se mueven y el disco del sol (`CasaNaturaleza`).
	_cielo = CasaNaturaleza.material_cielo()
	cielo.sky_material = _cielo
	_env = e
	e.background_mode = Environment.BG_SKY
	e.sky = cielo
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.9
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	## MÁS REALISMO (28-9-2026, "falta realismo al ambiente"): sombras de
	## contacto (SSAO), un poco de resplandor en lo que brilla, y la bruma de
	## la tarde que aclara y azula lo lejano -los cerros del fondo-.
	e.ssao_enabled = true
	e.ssao_radius = 1.2
	e.ssao_intensity = 1.6
	e.glow_enabled = true
	e.glow_intensity = 0.35
	e.fog_enabled = true
	e.fog_light_color = Color(0.78, 0.8, 0.84)
	e.fog_density = 0.0035
	e.fog_aerial_perspective = 0.5
	e.adjustment_enabled = true
	e.adjustment_saturation = 1.08
	e.adjustment_contrast = 1.05
	we.environment = e
	add_child(we)
	## El sol bajo de la tarde, de lado: es la hora de mirar el móvil en casa.
	var sol := DirectionalLight3D.new()
	_sol = sol
	sol.rotation_degrees = Vector3(-28.0, -55.0, 0.0)
	sol.light_energy = 1.25
	sol.light_color = Color(1.0, 0.9, 0.78)
	sol.shadow_enabled = true
	sol.shadow_blur = 1.5
	sol.directional_shadow_max_distance = 60.0
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
	## El césped con manchas: ruido de dos verdes repetido, no un color plano.
	var m := StandardMaterial3D.new()
	var ruido := FastNoiseLite.new()
	ruido.frequency = 0.03
	var tex := NoiseTexture2D.new()
	tex.noise = ruido
	tex.seamless = true
	tex.width = 256
	tex.height = 256
	var g := Gradient.new()
	g.set_color(0, Color(0.22, 0.36, 0.15))
	g.set_color(1, Color(0.4, 0.55, 0.26))
	tex.color_ramp = g
	m.albedo_texture = tex
	m.uv1_scale = Vector3(40, 40, 1)
	m.roughness = 1.0
	mi.material_override = m
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
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for a: Vector3 in arboles:
		CasaNaturaleza.arbol(self, a, rng.randf_range(5.5, 7.5), rng)

func _auto(transporte: String) -> void:
	var ruta := String(AUTOS.get(transporte, ""))
	if ruta == "":
		return
	## Los autos del kit miran a +Z: se deja de lado en la entrada, a la
	## izquierda de la terraza.
	_modelo(ruta, 1.5, -9.5, -0.5, PI * 0.5)

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

## La piscina de la mansión: bordillo de piedra y agua que refleja el cielo.
func _piscina() -> void:
	var piedra := _mat(Color(0.82, 0.8, 0.76), 0.8)
	_caja(Vector3(-1.0, 0.06, -5.2), Vector3(10.4, 0.12, 3.6), piedra)
	## El agua con oleaje y reflejo (`CasaNaturaleza.material_agua`).
	_caja(Vector3(-1.0, 0.1, -5.2), Vector3(9.6, 0.06, 2.9), CasaNaturaleza.material_agua())

## Lejos: cerros bajos y una fila de árboles. La bruma los aclara.
func _fondo_lejano() -> void:
	var cerro := _mat(Color(0.3, 0.42, 0.25), 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for i in 7:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 1.0
		sm.height = 2.0
		mi.mesh = sm
		mi.material_override = cerro
		var ang := -PI * 0.5 + (float(i) - 3.0) * 0.35
		mi.position = Vector3(sin(ang) * 170.0 + rng.randf_range(-20, 20), -8.0, -cos(ang) * 170.0 - 40.0)
		mi.scale = Vector3(rng.randf_range(60, 95), rng.randf_range(22, 38), rng.randf_range(40, 60))
		add_child(mi)
	## La arboleda del fondo, con árboles de copa de verdad y en dos filas
	## irregulares (una fila recta delataba el decorado).
	for i in 22:
		var x := -58.0 + i * 5.4 + rng.randf_range(-2.0, 2.0)
		var z := -30.0 - rng.randf_range(0.0, 14.0)
		CasaNaturaleza.arbol(self, Vector3(x, 0, z), rng.randf_range(6.0, 11.0), rng)
	## Y a los lados del jardín, más cerca.
	for x in [-16.0, -20.0, 14.0, 19.0]:
		CasaNaturaleza.arbol(self, Vector3(x, 0, rng.randf_range(-4.0, 10.0)), rng.randf_range(5.0, 8.0), rng)

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

## Pone el móvil donde `_BrazoMovil` decidió (en la palma, en pose de
## lectura), cada vez que se actualiza el esqueleto.
class _SostenMovil extends Node:
	var esq: Skeleton3D
	var pivote: Node3D
	var brazo: _BrazoMovil
	func colocar() -> void:
		if esq == null or pivote == null or brazo == null:
			return
		pivote.global_transform = esq.global_transform * brazo.movil_xf

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

## EL BRAZO CON EL MÓVIL. Corre después de la animación: dobla el brazo
## derecho hasta dejar la mano delante del pecho y baja la cabeza hacia ella.
## Trabaja en el espacio del esqueleto: el eje de cada hueso es su Y (va al
## hijo), así que se gira cada uno para que apunte a su dirección objetivo.
class _BrazoMovil extends SkeletonModifier3D:
	## LA ANIMACIÓN (28-9-2026): en un ciclo de diez segundos, siete mira el
	## móvil pasando publicaciones con el pulgar (la mano sube y baja un
	## poco, a golpes) y tres levanta la cabeza a mirar el jardín, bajando un
	## poco el móvil, antes de volver a la pantalla.
	var _t0 := Time.get_ticks_msec()
	## Cuánto se dobla cada falange (radianes, en el eje X local del hueso).
	const CURVA_DEDO := 0.55
	## +1: en reposo la palma derecha mira hacia ABAJO. Medido, no supuesto
	## (28-9-2026): al cerrar los dedos (+X, `CURVA_DEDO`) la punta del medio
	## se mueve hacia -Y. Con -1 el dorso quedaba contra el móvil ("la mano
	## está al revés").
	const SIGNO_PALMA := 1.0
	## Dónde va el móvil, en el espacio del esqueleto (lo lee `_SostenMovil`).
	var movil_xf := Transform3D.IDENTITY
	## Las interacciones: cuándo empezó a beber (ms) y hasta cuándo mira el
	## paisaje (ms).
	var cafe_desde := -100000
	var mirar_hasta := 0
	const DURA_CAFE := 4200.0

	func bebiendo() -> bool:
		return float(Time.get_ticks_msec() - cafe_desde) < DURA_CAFE

	## Cuánto está el brazo izquierdo arriba (0 → 1 → 0): sube, bebe, baja.
	func _peso_cafe() -> float:
		var t := float(Time.get_ticks_msec() - cafe_desde) / 1000.0
		if t < 0.0 or t > DURA_CAFE / 1000.0:
			return 0.0
		return smoothstep(0.0, 0.9, t) * (1.0 - smoothstep(3.2, 4.2, t))

	func _girar(esq: Skeleton3D, hueso: String, hijo: String, obj: Vector3, peso: float) -> void:
		var h := esq.find_bone(hueso)
		var hj := esq.find_bone(hijo)
		if h < 0 or hj < 0 or peso <= 0.001:
			return
		var g := esq.get_bone_global_pose(h)
		var dir := (esq.get_bone_global_pose(hj).origin - g.origin).normalized()
		var o := obj.normalized()
		if dir.length() < 0.5 or dir.is_equal_approx(o):
			return
		var q := Quaternion(dir, o)
		q = Quaternion.IDENTITY.slerp(q, peso)
		esq.set_bone_global_pose(h, Transform3D(Basis(q) * g.basis, g.origin))

	## EL AGARRE (28-9-2026, "aún el teléfono no queda del todo bien en la
	## mano"). Primero se decide el móvil: delante de la cara, con la pantalla
	## mirándola y algo inclinado hacia atrás. Después se gira la MUÑECA para
	## que la palma quede contra su dorso y los dedos rodeen el borde hacia la
	## izquierda y un poco hacia arriba, como se agarra con una mano. Los ejes
	## de la mano salen de la geometría de reposo (ver abajo): suponer que el
	## Y del hueso iba hacia los dedos dejaba la mano apuntando al suelo.
	func _agarre(esq: Skeleton3D) -> void:
		var im := esq.find_bone("hand_r")
		if im < 0:
			return
		var mano := esq.get_bone_global_pose(im)
		## LA POSE DE LECTURA, fija en el espacio del personaje (mira a +Z, su
		## izquierda es +X): pantalla inclinada ~45° mirando arriba y hacia la
		## cara, el largo del móvil hacia arriba y adelante. Sacarla de "la
		## dirección a la cabeza" dejaba el móvil tumbado, porque la mano está
		## casi debajo de la barbilla (medido: esa dirección salía vertical).
		var n := Vector3(0.0, 0.72, -0.69).normalized()
		var largo := Vector3(0.0, 0.69, 0.72).normalized()
		var bm := Basis(largo.cross(n), largo, n)
		## Los dedos rodean el canto izquierdo, un poco hacia arriba.
		var dedos := (Vector3(1, 0, 0) * 0.92 + largo * 0.3).normalized()
		var pn := (bm.z - dedos * bm.z.dot(dedos)).normalized()
		## Los ejes de la mano, medidos en la pose de reposo y no supuestos:
		## los dedos van de la muñeca al nudillo del medio y el lado de la
		## mano del meñique al índice. En T la palma derecha mira abajo, así
		## que su normal es -(dedos × lado).
		var rest := esq.get_bone_global_rest(im)
		var inv := rest.basis.orthonormalized().inverse()
		var i_medio := esq.find_bone("middle_01_r")
		var i_indice := esq.find_bone("index_01_r")
		var i_menique := esq.find_bone("pinky_01_r")
		if i_medio < 0 or i_indice < 0 or i_menique < 0:
			return
		var f_g := (esq.get_bone_global_rest(i_medio).origin - rest.origin).normalized()
		var s_g := (esq.get_bone_global_rest(i_indice).origin - esq.get_bone_global_rest(i_menique).origin).normalized()
		var n_g := -f_g.cross(s_g).normalized() * SIGNO_PALMA
		var f_l := (inv * f_g).normalized()
		var n_l := (inv * n_g)
		n_l = (n_l - f_l * n_l.dot(f_l)).normalized()
		var L := Basis(f_l, n_l, f_l.cross(n_l))
		var W := Basis(dedos, pn, dedos.cross(pn))
		var R := (W * L.inverse()).orthonormalized().scaled(mano.basis.get_scale())
		esq.set_bone_global_pose(im, Transform3D(R, mano.origin))
		## El centro de la palma medido DESPUÉS de girar la muñeca (entre ella y
		## el nudillo del medio), y el móvil apoyado delante, hacia la cara.
		var nudillo := esq.get_bone_global_pose(i_medio).origin
		var palma := mano.origin.lerp(nudillo, 0.6)
		movil_xf = Transform3D(bm, palma + bm.z * 0.022 + dedos * 0.01)
	func _process_modification() -> void:
		var esq := get_skeleton()
		if esq == null:
			return
		var t := float(Time.get_ticks_msec() - _t0) / 1000.0
		var c := fmod(t, 10.0)
		var mira := smoothstep(6.8, 7.6, c) * (1.0 - smoothstep(9.2, 10.0, c))
		## "Mirar el paisaje" la fuerza unos segundos, entrando y saliendo suave.
		var falta := float(mirar_hasta - Time.get_ticks_msec()) / 1000.0
		if falta > 0.0:
			mira = maxf(mira, smoothstep(0.0, 0.8, 6.0 - falta) * smoothstep(0.0, 0.8, falta))
		## El pulgar: un golpe corto cada 1,3 s, no una onda continua.
		var fase := fmod(t, 1.3) / 1.3
		var toque := (sin(fase * TAU) * 0.5 + 0.5) * (1.0 if fase < 0.35 else 0.0) * 0.06 * (1.0 - mira)
		var objetivos := [
			["upperarm_r", "lowerarm_r", Vector3(-0.16, -0.78, 0.6)],
			["lowerarm_r", "hand_r", Vector3(0.36, 0.42 + toque - 0.3 * mira, 0.86)],
		]
		for o: Array in objetivos:
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
		_agarre(esq)
		## El brazo izquierdo con la taza: de la rodilla a la boca.
		var pc := _peso_cafe()
		if pc > 0.0:
			_girar(esq, "upperarm_l", "lowerarm_l", Vector3(0.12, -0.72, 0.68), pc)
			_girar(esq, "lowerarm_l", "hand_l", Vector3(-0.42, 0.8, 0.42), pc)
		## Los dedos cerrados alrededor del móvil (la mano del reposo va
		## abierta y parecía que lo ofrecía). El pulgar queda libre encima.
		for dedo: String in ["index", "middle", "ring", "pinky"]:
			for f in ["01", "02", "03"]:
				var hd := esq.find_bone("%s_%s_r" % [dedo, f])
				if hd >= 0:
					var r := esq.get_bone_pose_rotation(hd)
					esq.set_bone_pose_rotation(hd, r * Quaternion(Vector3(1, 0, 0), CURVA_DEDO))
		## La cabeza: hacia la pantalla, o arriba y a un lado cuando mira el
		## jardín.
		var cb := esq.find_bone("Head")
		if cb >= 0:
			var gc := esq.get_bone_global_pose(cb)
			var cabeceo := lerpf(0.38, -0.05, mira) - 0.3 * _peso_cafe()
			var giro := lerpf(-0.2, 0.3, mira)
			esq.set_bone_global_pose(cb, Transform3D(Basis(Vector3(1, 0, 0), cabeceo).rotated(Vector3.UP, giro) * gc.basis, gc.origin))

# --- la pantalla completa -----------------------------------------------------

## Abre la escena sobre `p` (principal), con las últimas noticias de la
## bandeja convertidas en publicaciones de redes.
static func abrir(p: Control, m: Mundo, _bandeja: Array = []) -> Control:
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
	escena.m_actual = m
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

	## LO QUE SE PUEDE HACER EN LA ESCENA (28-9-2026, "la escena debe ser
	## animada y poder interactuar"). La zona del 3D recoge el arrastre y la
	## rueda para la cámara libre.
	var zona := Control.new()
	zona.set_anchors_preset(Control.PRESET_FULL_RECT)
	zona.mouse_filter = Control.MOUSE_FILTER_PASS
	zona.gui_input.connect(func(ev: InputEvent) -> void:
		if not escena.libre:
			return
		if ev is InputEventMouseMotion and ((ev as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			escena.arrastrar((ev as InputEventMouseMotion).relative)
		elif ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			var bi := (ev as InputEventMouseButton).button_index
			if bi == MOUSE_BUTTON_WHEEL_UP:
				escena.acercar(-0.4)
			elif bi == MOUSE_BUTTON_WHEEL_DOWN:
				escena.acercar(0.4)
		elif ev is InputEventScreenDrag:
			escena.arrastrar((ev as InputEventScreenDrag).relative))
	pop.add_child(zona)
	var acciones := HBoxContainer.new()
	acciones.add_theme_constant_override("separation", 8)
	acciones.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	acciones.offset_left = 36
	acciones.offset_top = -124
	acciones.offset_bottom = -84
	pop.add_child(acciones)
	var b_cafe := Button.new()
	b_cafe.text = "☕ Tomar un café"
	b_cafe.pressed.connect(escena.tomar_cafe)
	acciones.add_child(b_cafe)
	var b_mirar := Button.new()
	b_mirar.text = "🌅 Mirar el paisaje"
	b_mirar.pressed.connect(escena.mirar_paisaje)
	acciones.add_child(b_mirar)
	var b_cam := Button.new()
	b_cam.text = "🎥 Cámara libre"
	b_cam.toggle_mode = true
	b_cam.toggled.connect(func(si: bool) -> void:
		escena.libre = si
		b_cam.text = "🎬 Planos de cine" if si else "🎥 Cámara libre")
	acciones.add_child(b_cam)
	var b_hora := Button.new()
	b_hora.text = "🌙 Atardecer"
	b_hora.pressed.connect(func() -> void:
		b_hora.text = "☀️ De día" if escena.alternar_hora() else "🌙 Atardecer")
	acciones.add_child(b_hora)
	## El móvil de verdad: Tribuna, interactivo (publicar, responder, me gusta).
	if m.redes != null:
		var tel := Telefono.crear(m, p.get("_bandeja") if p.get("_bandeja") != null else [])
		tel.estetica_cambiada.connect(escena.aplicar_funda.bind(m))
		tel.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
		tel.offset_left = -Telefono.ANCHO - 30
		tel.offset_right = -30
		tel.offset_top = 76
		tel.offset_bottom = -24
		pop.add_child(tel)
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
