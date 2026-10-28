class_name CelebracionTrofeo
extends Node
## LA CELEBRACIÓN DE UN TÍTULO EN EL ESTADIO (27-10-2026, idea 327). Al ganar un título el once sale al campo con su equipación: se
## junta en el círculo central, el capitán levanta la copa del club (la de la competición, `TrofeoModelo`) entre cañones de confeti y,
## después, da la vuelta olímpica por la pista con todo el equipo detrás mientras la grada se pone de pie y salta (`OlaGrada`).
## Tres planos de cámara propios (corro, seguimiento de la vuelta y panorámica final) y un rótulo «¡CAMPEONES!». Cualquier tecla o clic la corta.
##   CelebracionTrofeo.iniciar(raiz3d, club, titulo, pantalla)  → el nodo (hijo de `raiz3d`); `terminado` al acabar o cortarla.
## `raiz3d` es la de una `VistaEstadio` ya abierta sin partido. No toca el motor de partido: mueve a mano a los jugadores que él mismo saca.

signal terminado

const T_CORRO := 7.0      ## s: del círculo central a la copa en alto
const T_VUELTA := 26.0    ## s: la vuelta olímpica (8 s para salir a la pista y el resto corriendo por ella)
const T_SALIDA := 8.0
const T_FINAL := 5.0      ## s: panorámica de despedida
const VEL_VUELTA := 5.5   ## m/s del capitán
const VEL_CICLO_TROTE := 3.05
const CONFETI_CANONES := 6

var _raiz: Node3D
var _club: Club
var _titulo := ""
var _pantalla: Control
var _jug: Array[Dictionary] = []   ## {nodo, anim, base, extra, destino}
var _capi: Dictionary = {}
var _copa: Node3D
var _cam: Camera3D
var _cam_previa: Camera3D
var _t := 0.0
var _rx := 39.0
var _rz := 57.0
var _rotulo: Label
var _grada_t := 0.0
var _cerrado := false
var _canones: Array[CPUParticles3D] = []

static func iniciar(raiz3d: Node3D, club: Club, titulo: String, pantalla: Control = null) -> CelebracionTrofeo:
	var c := CelebracionTrofeo.new()
	c.name = "CelebracionTrofeo"
	c._raiz = raiz3d
	c._club = club
	c._titulo = titulo
	c._pantalla = pantalla
	raiz3d.add_child(c)
	c._montar()
	return c

func _montar() -> void:
	var g := StadiumBuilder.geom_de_forma(String(_club.perfil_estadio().get("forma", "oval")))
	_rx = float(g["dx"]) - 6.0
	_rz = float(g["dz"]) - 8.0
	var l := Puente3D.once(_club.once())
	var spawner := PlayerSpawner.new()
	var filas := spawner.spawn_team(_raiz, l["xi"], l["jugadores"], Puente3D.formacion(_club.tactica.formacion), true,
		Puente3D.kit(_club), Puente3D.kit_portero(_club))
	var k := 0
	for f: Dictionary in filas:
		var n := f["node"] as Node3D
		var d := {"nodo": n, "anim": f["anim"], "base": n.position, "extra": 0.0, "id": String(f["id"]), "i": k,
			"capi": bool((f["jugador"] as Dictionary).get("capitan", false)) and String(f.get("slot_code", "")) != "POR"}
		_preparar_clips(d)
		var rot := n.get_node_or_null(NodePath(PlayerSpawner.ROTULO))
		if rot != null:
			(rot as Node3D).visible = false   ## sin nombres flotando: es una foto de equipo
		_jug.append(d)
		if d["capi"]:
			_capi = d
		k += 1
	if _capi.is_empty() and not _jug.is_empty():   ## el portero no levanta la copa: el primer jugador de campo con más fuerza
		var mejor := -1.0
		for f: Dictionary in filas:
			var jd := f["jugador"] as Dictionary
			if String(f.get("slot_code", "")) != "POR" and float(jd.get("ovr", 0)) > mejor:
				mejor = float(jd.get("ovr", 0))
				_capi = _jug[filas.find(f)]
		if _capi.is_empty():
			_capi = _jug[0]
		_capi["capi"] = true
	_poner_copa()
	_camara()
	_confeti()
	_rotulo_titulo()
	set_process(true)
	set_process_input(true)

func _preparar_clips(d: Dictionary) -> void:
	var ap := d["anim"] as AnimationPlayer
	var esq := FutbolistaQ.esqueleto_de(d["nodo"])
	for clip: String in ["celebrar_carrera", "puno_al_aire", "aplaudir", "baile"]:
		AnimExtra.asegurar(ap, esq, clip)

func _poner_copa() -> void:
	var receta := TrofeosReales.para_titulo(_titulo, _club.pais)
	var esq := FutbolistaQ.esqueleto_de(_capi["nodo"])
	if esq == null:
		return
	var escala_modelo := 1.0 / maxf(esq.global_transform.basis.get_scale().y, 0.01)
	var mano := PeatonQ._en_hueso(esq, "hand_r", escala_modelo)
	if mano == null:
		return
	if not receta.is_empty() and TrofeoModelo.disponible():
		_copa = TrofeoModelo.nodo(receta, 0.55)
	else:
		_copa = _copa_simple()
	_copa.position = Vector3(0, 0.12, 0)
	mano.add_child(_copa)

func _copa_simple() -> Node3D:
	var r := Node3D.new()
	var oro := StandardMaterial3D.new()
	oro.albedo_color = Color(0.95, 0.78, 0.25)
	oro.metallic = 0.9
	oro.roughness = 0.3
	var pie := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.03
	cm.bottom_radius = 0.07
	cm.height = 0.25
	pie.mesh = cm
	pie.material_override = oro
	pie.position.y = 0.125
	r.add_child(pie)
	var copa := MeshInstance3D.new()
	var cc := CylinderMesh.new()
	cc.top_radius = 0.11
	cc.bottom_radius = 0.04
	cc.height = 0.22
	copa.mesh = cc
	copa.material_override = oro
	copa.position.y = 0.36
	r.add_child(copa)
	return r

func _camara() -> void:
	_cam_previa = get_viewport().get_camera_3d()
	_cam = Camera3D.new()
	_cam.fov = 48.0
	_cam.far = 600.0
	_raiz.add_child(_cam)
	_cam.make_current()

func _confeti() -> void:
	var c1 := Color(_club.color1)
	var c2 := Color(_club.color2)
	var colores := Gradient.new()
	colores.colors = PackedColorArray([c1, c2, Color.WHITE, Color(0.98, 0.82, 0.25)])
	colores.offsets = PackedFloat32Array([0.0, 0.33, 0.66, 1.0])
	colores.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var papel := QuadMesh.new()
	papel.size = Vector2(0.14, 0.07)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
	for i in CONFETI_CANONES:
		var p := CPUParticles3D.new()
		p.mesh = papel
		p.material_override = mat
		p.emitting = false
		p.one_shot = true
		p.explosiveness = 0.9
		p.amount = 260
		p.lifetime = 5.5
		p.direction = Vector3.UP
		p.spread = 38.0
		p.initial_velocity_min = 11.0
		p.initial_velocity_max = 19.0
		p.gravity = Vector3(0, -3.2, 0)
		p.damping_min = 1.2
		p.damping_max = 2.4
		p.angular_velocity_min = -360.0
		p.angular_velocity_max = 360.0
		p.angle_max = 360.0
		p.color_initial_ramp = colores
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 1.2
		p.position = _posicion_canon(i)
		p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_raiz.add_child(p)
		_canones.append(p)

func _posicion_canon(i: int) -> Vector3:
	var ang := TAU * float(i) / float(CONFETI_CANONES) + 0.4
	return Vector3(cos(ang) * 20.0, 0.3, sin(ang) * 30.0)

func _disparar(cuales: Array[int]) -> void:
	for i in cuales:
		if i < _canones.size():
			_canones[i].restart()
			_canones[i].emitting = true

func _rotulo_titulo() -> void:
	if _pantalla == null:
		return
	_rotulo = Label.new()
	_rotulo.text = "🏆 %s\n%s" % [Idiomas.t("¡CAMPEONES!"), _titulo]
	_rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rotulo.add_theme_font_size_override("font_size", 38)
	_rotulo.add_theme_color_override("font_color", Color(1.0, 0.86, 0.45))
	_rotulo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_rotulo.add_theme_constant_override("outline_size", 10)
	_rotulo.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_rotulo.offset_top = 36
	_rotulo.offset_left = -400
	_rotulo.offset_right = 400
	_rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rotulo.modulate.a = 0.0
	_pantalla.add_child(_rotulo)

func _input(ev: InputEvent) -> void:
	if (ev is InputEventKey and ev.pressed) or (ev is InputEventMouseButton and ev.pressed):
		cortar()

## Fin anticipado (o normal): quita lo que puso y devuelve la cámara.
func cortar() -> void:
	if _cerrado:
		return
	_cerrado = true
	for d: Dictionary in _jug:
		if is_instance_valid(d["nodo"]):
			(d["nodo"] as Node3D).queue_free()
	for p in _canones:
		if is_instance_valid(p):
			p.queue_free()
	if is_instance_valid(_cam):
		_cam.queue_free()
	if is_instance_valid(_cam_previa):
		_cam_previa.make_current()
	if is_instance_valid(_rotulo):
		_rotulo.queue_free()
	terminado.emit()
	queue_free()

func _process(delta: float) -> void:
	if _cerrado:
		return
	_t += delta
	if _t > T_CORRO + T_VUELTA + T_FINAL:
		cortar()
		return
	if _t < T_CORRO:
		_corro(_t)
	else:
		_vuelta(_t - T_CORRO)
	_grada(delta)
	if is_instance_valid(_rotulo):
		_rotulo.modulate.a = clampf(minf(_t / 1.0, (T_CORRO + T_VUELTA + T_FINAL - _t) / 1.0), 0.0, 1.0)

## Fase 1: todos corren al círculo central; el capitán, al punto de la copa, que sube con el puño.
func _corro(t: float) -> void:
	var llegan := clampf(t / 3.0, 0.0, 1.0)
	var n := _jug.size()
	for d: Dictionary in _jug:
		var i := int(d["i"])
		var destino := Vector3.ZERO
		if not d["capi"]:
			var ang := PI * 0.5 + (float(i) / float(maxi(n - 1, 1)) - 0.5) * TAU * 0.78
			destino = Vector3(cos(ang) * 3.1, 0.0, -sin(ang) * 3.1) * (0.8 + 0.4 * float(i % 3) / 2.0) + Vector3(0, 0, -0.8)
		var base: Vector3 = d["base"]
		var pos := base.lerp(destino, ease(llegan, -2.0)) if llegan < 1.0 else destino
		_mover(d, pos, Vector3.ZERO, 4.0 if llegan < 1.0 else 0.0)
		if llegan < 1.0:
			_clip(d, "correr")
		else:
			_clip(d, "puno_al_aire" if d["capi"] else ("celebrar" if i % 2 == 0 else "aplaudir"))
	## Cañones: el primero al salir, el resto al levantar la copa.
	if t > 0.3 and t < 0.5:
		_disparar([0, 3])
	if t > 3.2 and t < 3.4:
		_disparar([1, 2, 4, 5])
	var cp := _capi["nodo"] as Node3D
	var orbita := 0.55 + t * 0.12
	_cam.global_position = cp.global_position + Vector3(sin(orbita) * 5.4, 2.7 - 0.5 * t / T_CORRO, cos(orbita) * 5.4)
	_cam.look_at(cp.global_position + Vector3(0, 2.0, 0), Vector3.UP)
	_cam.fov = lerpf(52.0, 40.0, t / T_CORRO)

## Fase 2 y 3: salen a la pista (T_SALIDA s) y dan la vuelta olímpica por la elipse; la cámara va por delante y al final se abre a una panorámica.
func _vuelta(t: float) -> void:
	var ang0 := PI * 0.5   ## el lado sur
	var u := maxf(minf(t, T_VUELTA) - T_SALIDA, 0.0) * VEL_VUELTA / _perimetro()
	var cap_pos := _en_elipse(ang0 - u * TAU)
	var salida := clampf(t / T_SALIDA, 0.0, 1.0)
	for d: Dictionary in _jug:
		var i := int(d["i"])
		var rezago := (0.0 if d["capi"] else 2.0 + float(i) * 0.7) / _perimetro()
		var ang := ang0 - (u - rezago) * TAU
		var lado := 0.0 if d["capi"] else (1.4 if i % 2 == 0 else -1.4)   ## de dos en dos, no en fila india
		var p := _en_elipse(ang) * (1.0 + lado / _rx * 0.5)
		if not d.has("fin_corro"):
			d["fin_corro"] = _pos_de(d)
		var corro_pos: Vector3 = d["fin_corro"]
		var pos := corro_pos.lerp(p, ease(salida, -2.0)) if salida < 1.0 else p
		var tang := _en_elipse(ang - 0.02) - _en_elipse(ang)
		var mira := (p - corro_pos) if salida < 1.0 else tang
		_mover(d, pos, mira, VEL_VUELTA)
		var ap := d["anim"] as AnimationPlayer
		var fiesta: bool = (d["capi"] or i % 3 == 0) and ap.has_animation("celebrar_carrera")
		_clip(d, "celebrar_carrera" if fiesta else ("correr" if salida < 1.0 else "trotar"))
	## Un cañón de confeti cada cuatro segundos, a la altura del capitán.
	if int(t) % 4 == 0 and fmod(t, 4.0) < 0.1:
		_disparar([int(t / 4.0) % CONFETI_CANONES, (int(t / 4.0) + 3) % CONFETI_CANONES])
	if t <= T_VUELTA:
		var tang := (_en_elipse(ang0 - (u + 0.01) * TAU) - cap_pos).normalized()
		var dentro := Vector3(cap_pos.x, 0, cap_pos.z).normalized() * -4.5
		_cam.global_position = cap_pos + tang * 6.0 + dentro + Vector3(0, 1.7, 0)
		_cam.look_at(cap_pos + tang * -2.0 + Vector3(0, 1.7, 0), Vector3.UP)
		_cam.fov = 40.0
	else:
		var s := (t - T_VUELTA) / T_FINAL
		var a := lerpf(0.2, 1.3, s)
		_cam.global_position = Vector3(sin(a) * 30.0, lerpf(12.0, 26.0, s), cos(a) * 36.0)
		_cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
		_cam.fov = 60.0

func _perimetro() -> float:
	return PI * (3.0 * (_rx + _rz) - sqrt((3.0 * _rx + _rz) * (_rx + 3.0 * _rz)))

func _en_elipse(ang: float) -> Vector3:
	return Vector3(cos(ang) * _rx, 0.0, sin(ang) * _rz)

func _pos_de(d: Dictionary) -> Vector3:
	return (d["nodo"] as Node3D).position

func _mover(d: Dictionary, pos: Vector3, dir: Vector3, vel: float) -> void:
	var n := d["nodo"] as Node3D
	var antes := n.position
	n.position = pos
	var mira := dir if dir.length() > 0.001 else (-pos if pos.length() > 0.5 else Vector3.ZERO)
	if d["capi"] and dir.length() <= 0.001:
		mira = Vector3(_cam.global_position.x - pos.x, 0, _cam.global_position.z - pos.z) if is_instance_valid(_cam) else mira
	if mira.length() > 0.001:
		var objetivo := atan2(mira.x, mira.z)
		n.rotation.y = lerp_angle(n.rotation.y, objetivo, 0.18)
	var ap := d["anim"] as AnimationPlayer
	if vel > 0.0:
		var visto := (pos - antes).length() / maxf(get_process_delta_time(), 0.001)
		ap.speed_scale = clampf(maxf(vel, visto * 0.6) / VEL_CICLO_TROTE, 0.7, 2.4) if not ap.current_animation.begins_with("celebrar") else 1.0
	else:
		ap.speed_scale = 1.0

func _clip(d: Dictionary, nombre: String) -> void:
	var ap := d["anim"] as AnimationPlayer
	if ap.has_animation(nombre) and ap.current_animation != nombre:
		ap.play(nombre, 0.25)

## La grada: de pie y saltando, relanzada cada pocos segundos mientras dura la fiesta.
func _grada(delta: float) -> void:
	_grada_t -= delta
	if _grada_t > 0.0:
		return
	_grada_t = 3.0
	OlaGrada.lanzar(_raiz, "protesta", Vector3.ZERO, 0)
	OlaGrada.lanzar(_raiz, "onda", Vector3(0, 0, 0), 0)
