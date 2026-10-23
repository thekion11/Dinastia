extends Node3D
## (Parte 1 de 3 de `casa_escena3d.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `casa_escena3d.gd`, conserva la clase.)

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

func _mat(c: Color, rug: float = 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rug
	return m

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

func _caja(pos: Vector3, tam: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tam
	mi.mesh = b
	mi.material_override = m
	mi.position = pos
	add_child(mi)
	return mi

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
