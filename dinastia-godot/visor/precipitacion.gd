class_name Precipitacion
extends RefCounted
## EL CLIMA SE VE (25-9-2026, plan maestro B11). Hasta hoy la lluvia, la nieve y
## la tormenta del estadio solo se OÍAN (sonido de ambiente) y oscurecían el
## cielo; sobre el campo no caía nada. Esto pone partículas sobre el terreno:
##  - lluvia: gotas estiradas que caen rápido, en diagonal por el viento;
##  - tormenta: más lluvia, más viento y relámpagos (un destello de luz cada
##    pocos segundos, con su trueno);
##  - nieve: copos que bajan despacio, meciéndose.
## La cantidad baja con la calidad gráfica (`Calidad`), porque las partículas
## son de lo más caro en un PC modesto.

const ALTO := 34.0

static func montar(root: Node3D, clima: String, dx: float, dz: float, nivel: int = Calidad.ALTO) -> Node3D:
	if clima not in ["lluvia", "tormenta", "nieve"]:
		return null
	var cont := Node3D.new()
	cont.name = "Precipitacion"
	root.add_child(cont)
	var factor := 1.0 if nivel >= Calidad.ALTO else 0.45
	if nivel >= Calidad.ULTRA:
		factor = 1.5
	## Dos capas: una sobre todo el campo (se ve de lejos, en los planos
	## abiertos) y otra que sigue a la cámara (las gotas y copos que pasan
	## por delante del objetivo: sin ella, desde la tribuna apenas se notaba).
	## Las partículas nacen repartidas en TODA la altura (caja alta), no en un
	## techo: `preprocess` no siempre adelanta la simulación (en el render de
	## compatibilidad no lo hace) y la nieve, que cae a 3 m/s, tardaba diez
	## segundos en llegar al campo.
	var lejos := _emisor(clima, Vector3(dx + 6.0, ALTO * 0.5, dz + 6.0), factor)
	lejos.position = Vector3(0, ALTO * 0.5, 0)
	lejos.visibility_aabb = AABB(Vector3(-dx - 10, -ALTO, -dz - 10), Vector3(dx * 2 + 20, ALTO * 2.0, dz * 2 + 20))
	cont.add_child(lejos)
	var cerca := _emisor(clima, Vector3(14.0, 6.0, 14.0), factor * 0.35, true)
	cerca.position = Vector3(0, 2.0, 0)
	cerca.visibility_aabb = AABB(Vector3(-20, -30, -20), Vector3(40, 40, 40))
	var sigue := SigueCamara.new()
	sigue.add_child(cerca)
	cont.add_child(sigue)
	if clima == "tormenta":
		cont.add_child(Relampagos.new())
	return cont

static func _emisor(clima: String, caja: Vector3, factor: float, cerca: bool = false) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = caja
	var malla := QuadMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	var area := caja.x * caja.z / (60.0 * 40.0)
	if clima == "nieve":
		p.amount = maxi(900, int(9000 * factor * area)) if not cerca else maxi(700, int(2200 * factor))
		## Tiene que vivir lo que tarda en bajar: ~34 m a unos 3 m/s.
		p.lifetime = 5.0 if cerca else 12.0
		pm.direction = Vector3(0, -1, 0)
		pm.initial_velocity_min = 2.0
		pm.initial_velocity_max = 3.5
		pm.gravity = Vector3(0.4, -0.6, 0.0)
		pm.turbulence_enabled = true
		pm.turbulence_noise_strength = 1.4
		pm.turbulence_noise_scale = 6.0
		pm.scale_min = 0.6
		pm.scale_max = 1.4
		## De lejos un copo real mide menos de un píxel: la capa lejana los
		## dibuja más grandes para que la nevada se lea en los planos abiertos.
		malla.size = Vector2(0.07, 0.07) if cerca else Vector2(0.2, 0.2)
		mat.albedo_color = Color(1, 1, 1, 0.95)
		mat.albedo_texture = _copo()
	else:
		var tormenta := clima == "tormenta"
		p.amount = maxi(300, int((9000 if tormenta else 6500) * factor * area))
		p.lifetime = 0.7 if cerca else 1.3
		pm.direction = Vector3(0.15 if tormenta else 0.06, -1, 0)
		pm.spread = 3.0
		pm.initial_velocity_min = 24.0
		pm.initial_velocity_max = 30.0
		pm.gravity = Vector3(2.5 if tormenta else 0.8, -20.0, 0.0)
		## Las de al lado de la cámara, más finas y tenues: de cerca una gota
		## gruesa se lee como una barra blanca.
		malla.size = Vector2(0.012, 0.45) if cerca else Vector2(0.035, 0.9)
		mat.albedo_color = Color(0.82, 0.88, 0.96, 0.28 if cerca else 0.5)
		## Gotas estiradas en la dirección de caída, no cuadraditos.
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	malla.material = mat
	p.draw_pass_1 = malla
	p.process_material = pm
	p.preprocess = p.lifetime
	return p

## Un punto blanco redondo y difuminado: sin él cada copo era un cuadrado.
static var _tex_copo: Texture2D = null
static func _copo() -> Texture2D:
	if _tex_copo == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 32
		t.height = 32
		_tex_copo = t
	return _tex_copo

## Mantiene sus hijos sobre la cámara activa (la que sea: TV, tribuna, dron).
class SigueCamara:
	extends Node3D
	func _process(_d: float) -> void:
		var cam := get_viewport().get_camera_3d()
		if cam != null:
			global_position = cam.global_position

## Destellos de tormenta: una luz direccional que se enciende un instante, dos
## veces a veces, cada 6-16 s, y el trueno llega un poco después.
class Relampagos:
	extends Node3D
	var _luz: DirectionalLight3D
	var _rng := RandomNumberGenerator.new()
	var _proximo := 3.0
	var _t := 0.0

	func _ready() -> void:
		name = "Relampagos"
		_rng.randomize()
		_luz = DirectionalLight3D.new()
		_luz.rotation_degrees = Vector3(-60, 20, 0)
		_luz.light_color = Color(0.82, 0.88, 1.0)
		_luz.light_energy = 0.0
		_luz.shadow_enabled = false
		add_child(_luz)

	func _process(delta: float) -> void:
		_t += delta
		if _t < _proximo:
			return
		_t = 0.0
		_proximo = _rng.randf_range(6.0, 16.0)
		var tw := create_tween()
		tw.tween_property(_luz, "light_energy", 3.2, 0.05)
		tw.tween_property(_luz, "light_energy", 0.0, 0.12)
		if _rng.randf() < 0.5:
			tw.tween_interval(0.08)
			tw.tween_property(_luz, "light_energy", 2.4, 0.04)
			tw.tween_property(_luz, "light_energy", 0.0, 0.2)
		tw.tween_interval(_rng.randf_range(0.4, 1.6))
		tw.tween_callback(func() -> void: Sonido.toca("trueno", Sonido.Bus.AMBIENTE))
