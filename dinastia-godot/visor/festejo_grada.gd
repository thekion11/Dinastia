class_name FestejoGrada
extends Node3D
## CONFETI, BENGALAS Y HUMO DE COLOR EN LA GRADA (17-10-2026, M-050). En los
## goles del local y en la salida de los equipos, la hinchada lanza papelitos
## con los colores del club y enciende unas bengalas con humo de color. Todo
## con partículas de GPU baratas (una llamada de dibujo por emisor, sin
## sombras) que se borran solas a los pocos segundos.
##
## Los emisores se colocan SOBRE la gente de verdad: se leen las posiciones del
## público (los MultiMesh con `hinchada.gdshader`) y se elige, para cada
## dirección, el hincha de abajo más cercano al campo. Así sirve para cualquier
## forma de estadio (con pista, a dos aguas, una sola bandeja…).
##
## Calidad: apagado con el motor ligero (la gama baja); en MEDIO solo confeti y
## la mitad; ALTO todo; ULTRA un 50 % más de papelitos.
##   FestejoGrada.lanzar(raiz, color1, color2, "gol" | "salida")

const DURA := 9.0
var _t := 0.0
var _dura := DURA

static func activo() -> bool:
	return not Calidad.motor_ligero

static func lanzar(raiz: Node3D, c1: Color, c2: Color, motivo := "gol", dura := DURA) -> FestejoGrada:
	if raiz == null or not activo():
		return null
	var sitios := _sitios_de_grada(raiz)
	if sitios.is_empty():
		return null
	var f := FestejoGrada.new()
	f.name = "FestejoGrada"
	f._dura = dura
	raiz.add_child(f)
	var medio := Calidad.elegida == Calidad.MEDIO
	var factor := 0.5 if medio else (1.5 if Calidad.elegida == Calidad.ULTRA else 1.0)
	## Un papelito negro sobre la grada no se ve: los colores muy oscuros se
	## cambian por dorado (y el humo, si el club no tiene un color vivo, es el
	## rojo de bengala de toda la vida).
	var colores := [_visible(c1), _visible(c2), Color(0.97, 0.97, 0.95)]
	var humo_a := c1 if c1.s > 0.35 and c1.v > 0.3 else (c2 if c2.s > 0.35 and c2.v > 0.3 else Color(0.92, 0.22, 0.2))
	var humo_b := c2 if c2.s > 0.35 and c2.v > 0.3 else humo_a
	## Papelitos en cuatro tramos de grada; en la salida, en todos los sitios.
	var n_conf := sitios.size() if motivo == "salida" else mini(4, sitios.size())
	for i in n_conf:
		f.add_child(_confeti(sitios[i], colores, int(420 * factor), dura))
	if not medio:
		## Bengalas con humo en dos o tres puntos (el fondo de la hinchada).
		for i in mini(3 if motivo == "salida" else 2, sitios.size()):
			var s: Vector3 = sitios[i]
			f.add_child(_bengala(s + Vector3(1.5, 0, 0), humo_a if i % 2 == 0 else humo_b, dura))
	return f

static func _visible(c: Color) -> Color:
	return Color(0.95, 0.76, 0.2) if c.get_luminance() < 0.12 else c

func _process(delta: float) -> void:
	_t += delta
	if _t > _dura + 6.0:
		queue_free()
	elif _t > _dura:
		for p in find_children("*", "GPUParticles3D", true, false):
			(p as GPUParticles3D).emitting = false

## Hasta 8 puntos de la grada baja, repartidos alrededor del campo.
static var _cache_sitios: Dictionary = {}
static func _sitios_de_grada(raiz: Node3D) -> Array:
	var clave := raiz.get_instance_id()
	if _cache_sitios.has(clave):
		return _cache_sitios[clave]
	var mejores: Array = []
	var dist: Array = []
	for i in 8:
		mejores.append(null)
		dist.append(INF)
	for n in raiz.find_children("*", "MultiMeshInstance3D", true, false):
		var mmi := n as MultiMeshInstance3D
		var sm := mmi.material_override as ShaderMaterial
		if sm == null or sm.shader == null or not sm.shader.resource_path.ends_with("hinchada.gdshader"):
			continue
		var mm := mmi.multimesh
		if mm == null:
			continue
		var paso := maxi(1, mm.instance_count / 400)
		var xf := mmi.global_transform
		for k in range(0, mm.instance_count, paso):
			var p: Vector3 = xf * mm.get_instance_transform(k).origin
			## Fuera del campo y por debajo de 9 m (la bandeja de abajo).
			if p.y > 9.0 or (absf(p.x) < 36.0 and absf(p.z) < 54.0):
				continue
			var ang := atan2(p.x, p.z)
			## Sectores de 45° centrados en los ejes: 4 = fondo +Z, 0 = fondo −Z,
			## 2 = lateral −X, 6 = lateral +X.
			var sector := int(floor((ang + PI + PI / 8.0) / TAU * 8.0)) % 8
			## Lo más cerca del campo y bajo: la primera fila.
			var d := Vector2(maxf(absf(p.x) - 34.0, 0.0), maxf(absf(p.z) - 52.5, 0.0)).length() + p.y * 0.5
			if d < float(dist[sector]):
				dist[sector] = d
				mejores[sector] = p
	var out: Array = []
	## Primero los fondos y los laterales (orden 4, 0, 2, 6), luego las esquinas.
	for s in [4, 0, 2, 6, 1, 5, 3, 7]:
		if mejores[s] != null:
			out.append(mejores[s])
	_cache_sitios[clave] = out
	return out

static func _confeti(sitio: Vector3, colores: Array, cantidad: int, dura: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "Confeti"
	p.amount = maxi(80, cantidad)
	p.lifetime = 4.5
	p.explosiveness = 0.25
	p.randomness = 0.6
	p.position = sitio + Vector3(0, 2.2, 0)
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-12, -8, -12), Vector3(24, 22, 24))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(5.0, 0.6, 5.0)
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 35.0
	pm.initial_velocity_min = 5.0
	pm.initial_velocity_max = 9.0
	pm.gravity = Vector3(0, -2.6, 0)
	pm.damping_min = 1.2
	pm.damping_max = 2.2
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.8
	pm.turbulence_noise_scale = 3.0
	pm.angle_min = -180.0
	pm.angle_max = 180.0
	pm.angular_velocity_min = -360.0
	pm.angular_velocity_max = 360.0
	pm.scale_min = 0.7
	pm.scale_max = 1.3
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.33, 0.34, 0.66, 0.67, 1.0])
	var c0: Color = colores[0]
	var c1: Color = colores[1]
	var c2: Color = colores[2]
	g.colors = PackedColorArray([c0, c0, c1, c1, c2, c2])
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_initial_ramp = gt
	p.process_material = pm
	var q := QuadMesh.new()
	## Más grandes que un papelito real (9 x 6 cm): desde la cámara de TV, a
	## 50-70 m, uno de verdad no llega a un píxel y la nube no se vería.
	q.size = Vector2(0.24, 0.16)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	q.material = m
	p.draw_pass_1 = q
	p.emitting = true
	return p

## Una bengala: chispas rojas muy vivas en la mano y una columna de humo del
## color del club que sube y se abre.
static func _bengala(sitio: Vector3, color: Color, dura: float) -> Node3D:
	var n := Node3D.new()
	n.name = "Bengala"
	n.position = sitio + Vector3(0, 1.7, 0)
	var chispa := GPUParticles3D.new()
	chispa.amount = 40
	chispa.lifetime = 0.6
	chispa.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pc := ParticleProcessMaterial.new()
	pc.direction = Vector3(0, 1, 0)
	pc.spread = 50.0
	pc.initial_velocity_min = 1.0
	pc.initial_velocity_max = 2.4
	pc.gravity = Vector3(0, -1.5, 0)
	pc.scale_min = 0.5
	pc.scale_max = 1.2
	chispa.process_material = pc
	var qc := QuadMesh.new()
	qc.size = Vector2(0.16, 0.16)
	var mc := StandardMaterial3D.new()
	mc.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mc.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mc.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mc.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mc.albedo_texture = Precipitacion._copo()
	mc.albedo_color = Color(1.0, 0.35, 0.18)
	qc.material = mc
	chispa.draw_pass_1 = qc
	n.add_child(chispa)
	var humo := GPUParticles3D.new()
	humo.amount = 36
	humo.lifetime = 5.5
	humo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	humo.visibility_aabb = AABB(Vector3(-10, -2, -10), Vector3(20, 20, 20))
	var ph := ParticleProcessMaterial.new()
	ph.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	ph.emission_sphere_radius = 0.4
	ph.direction = Vector3(0, 1, 0)
	ph.spread = 18.0
	ph.initial_velocity_min = 1.2
	ph.initial_velocity_max = 2.0
	ph.gravity = Vector3(0.35, 0.25, 0.0)
	ph.damping_min = 0.2
	ph.damping_max = 0.4
	ph.angle_min = -180.0
	ph.angle_max = 180.0
	var curva := Curve.new()
	curva.add_point(Vector2(0.0, 0.35))
	curva.add_point(Vector2(1.0, 1.0))
	var ct := CurveTexture.new()
	ct.curve = curva
	ph.scale_curve = ct
	var ga := Gradient.new()
	ga.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.0)])
	ga.offsets = PackedFloat32Array([0.0, 0.15, 1.0])
	var gat := GradientTexture1D.new()
	gat.gradient = ga
	ph.color_ramp = gat
	humo.process_material = ph
	var qh := QuadMesh.new()
	qh.size = Vector2(3.2, 3.2)
	var mh := StandardMaterial3D.new()
	mh.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mh.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mh.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mh.vertex_color_use_as_albedo = true
	mh.albedo_texture = Precipitacion._copo()
	mh.albedo_color = color.lerp(Color.WHITE, 0.15)
	mh.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	qh.material = mh
	humo.draw_pass_1 = qh
	n.add_child(humo)
	return n
