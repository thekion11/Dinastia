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
var _t := 0.0
var _plano := -1

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
	sm.sun_angle_max = 20.0
	sm.ground_horizon_color = Color(0.55, 0.5, 0.45)
	cielo.sky_material = sm
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
	_cilindro(mesa, Vector3(0.06, 0.565, 0.03), 0.04, 0.09, _mat(Color(0.95, 0.95, 0.93), 0.3))
	_cilindro(mesa, Vector3(0.06, 0.607, 0.03), 0.034, 0.005, _mat(Color(0.25, 0.14, 0.08), 0.2))
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
	var agua := StandardMaterial3D.new()
	agua.albedo_color = Color(0.18, 0.55, 0.72, 0.85)
	agua.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	agua.roughness = 0.05
	agua.metallic = 0.3
	_caja(Vector3(-1.0, 0.1, -5.2), Vector3(9.6, 0.06, 2.9), agua)

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
	var tronco := _mat(Color(0.33, 0.24, 0.16), 0.9)
	var copa := _mat(Color(0.18, 0.36, 0.17), 1.0)
	for i in 26:
		var x := -60.0 + i * 4.8 + rng.randf_range(-1.5, 1.5)
		var z := -34.0 - rng.randf_range(0.0, 10.0)
		var alto := rng.randf_range(5.0, 9.0)
		_caja(Vector3(x, alto * 0.3, z), Vector3(0.4, alto * 0.6, 0.4), tronco)
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = alto * 0.28
		cm.height = alto * 0.75
		mi.mesh = cm
		mi.material_override = copa
		mi.position = Vector3(x, alto * 0.55 + alto * 0.3, z)
		add_child(mi)

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
	## La pantalla encendida: un feed de tarjetas claras con su barra de
	## arriba, que brilla un poco (se ve desde el plano por encima del hombro).
	var pantalla := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.66, 0.78)
	pantalla.mesh = q
	var mp := StandardMaterial3D.new()
	mp.albedo_texture = _textura_feed()
	mp.emission_enabled = true
	mp.emission_texture = mp.albedo_texture
	mp.emission_energy_multiplier = 0.8
	mp.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pantalla.material_override = mp
	## La cara -Y del modelo (en +Y está el bulto de la cámara trasera).
	pantalla.rotation_degrees.x = 90.0
	## El modelo no está centrado: su grosor va de y=-0,106 a y=0.
	pantalla.position = Vector3(0.0, -0.109, 0.028)
	## Se cuelga de la MALLA, no de la raíz del modelo: las medidas de arriba
	## son las de la malla, que dentro del .glb lleva su propio giro.
	var mallas := movil.find_children("*", "MeshInstance3D", true, false)
	(mallas[0] as Node3D if not mallas.is_empty() else movil).add_child(pantalla)

## Una pantalla de redes dibujada a mano: fondo oscuro, barra de arriba y
## tarjetas claras con una "foto" de color. Horizontal (el largo del móvil
## va en X), así que las tarjetas van en columnas.
static func _textura_feed() -> ImageTexture:
	var img := Image.create(128, 60, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.07, 0.08, 0.1))
	img.fill_rect(Rect2i(0, 0, 10, 60), Color(0.12, 0.14, 0.18))
	var fotos := [Color(0.85, 0.45, 0.2), Color(0.25, 0.55, 0.85), Color(0.3, 0.7, 0.4)]
	for k in 3:
		var x := 14 + k * 38
		img.fill_rect(Rect2i(x, 4, 34, 52), Color(0.93, 0.94, 0.96))
		img.fill_rect(Rect2i(x + 3, 7, 28, 22), fotos[k])
		for r in 3:
			img.fill_rect(Rect2i(x + 3, 33 + r * 7, 28 - r * 6, 3), Color(0.55, 0.57, 0.62))
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
	func _process_modification() -> void:
		var esq := get_skeleton()
		if esq == null:
			return
		var t := float(Time.get_ticks_msec() - _t0) / 1000.0
		var c := fmod(t, 10.0)
		var mira := smoothstep(6.8, 7.6, c) * (1.0 - smoothstep(9.2, 10.0, c))
		## El pulgar: un golpe corto cada 1,3 s, no una onda continua.
		var fase := fmod(t, 1.3) / 1.3
		var toque := (sin(fase * TAU) * 0.5 + 0.5) * (1.0 if fase < 0.35 else 0.0) * 0.06 * (1.0 - mira)
		var objetivos := [
			["upperarm_r", "lowerarm_r", Vector3(-0.18, -0.92, 0.3)],
			["lowerarm_r", "hand_r", Vector3(0.42, 0.5 + toque - 0.3 * mira, 0.76)],
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
		## La cabeza: hacia la pantalla, o arriba y a un lado cuando mira el
		## jardín.
		var cb := esq.find_bone("Head")
		if cb >= 0:
			var gc := esq.get_bone_global_pose(cb)
			var cabeceo := lerpf(0.38, -0.05, mira)
			var giro := lerpf(-0.2, 0.3, mira)
			esq.set_bone_global_pose(cb, Transform3D(Basis(Vector3(1, 0, 0), cabeceo).rotated(Vector3.UP, giro) * gc.basis, gc.origin))

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
