class_name PcAnimacion
extends Node
## SENTARSE AL PC Y ENTRAR EN ÉL (18-11-2026, pedido del dueño): al pulsar E en el aro de la oficina, la cámara en PRIMERA PERSONA
## (la única vista del juego, orden 45) hace el gesto completo: da los últimos pasos hacia el escritorio, se sienta (baja a la altura
## del sillón con un pequeño rebote), aparecen tus manos sobre el teclado, la pantalla se enciende con su luz azul y la cámara se
## acerca hasta llenar la vista; entonces un fundido a negro entrega el menú central. «Levantarse» es el camino inverso.
## Todo se mueve con tweens sobre la cámara del explorador (que está en pausa); no crea nada pesado: 2 antebrazos, 2 manos y 1 luz.

const T_PASOS := 0.75
const T_SENTAR := 0.65
const T_ENTRAR := 0.9
const T_FUNDIDO := 0.35
const T_LEVANTAR := 0.9
const ALTURA_OJO_SENTADO := 1.16
const ALTURA_MESA := 0.76
const FOV_ENTRAR := 52.0
const LUZ := 0.55   ## energía de la luz azul de la pantalla (más y quemaba las manos)

var _cam: Camera3D
var _fov0 := 75.0
var _pose_pie := Transform3D.IDENTITY
var _pose_sentado := Transform3D.IDENTITY
var _pose_pantalla := Transform3D.IDENTITY
var _extras: Node3D
var _luz: OmniLight3D
var _manos: Array[MeshInstance3D] = []
var _t_manos := 0.0
var _tecleando := false
var _pantalla: MeshInstance3D
var _fundido: CanvasLayer
var _velo: ColorRect

## ¿Hay con qué animar? (un explorador con su cámara dentro del árbol; sin él, el PC enciende de golpe como antes).
static func puede(explorador: Node) -> bool:
	if explorador == null or not is_instance_valid(explorador) or not explorador.is_inside_tree():
		return false
	var c = explorador.get("camara")
	return c is Camera3D and (c as Camera3D).is_inside_tree()

## Las tres poses de la cámara según el punto de uso (delante del escritorio, mirando hacia -Z).
func _preparar(explorador: Node3D, punto: Vector3) -> void:
	_cam = explorador.get("camara") as Camera3D
	_fov0 = _cam.fov
	_pose_pie = _cam.global_transform
	var sentado := Vector3(punto.x, punto.y + ALTURA_OJO_SENTADO, punto.z - 0.62)
	var pantalla := Vector3(punto.x, punto.y + 1.0, punto.z - 1.78)
	_pose_sentado = Transform3D(Basis.IDENTITY, sentado).looking_at(pantalla + Vector3(0, -0.05, 0), Vector3.UP)
	var cerca := Vector3(punto.x, punto.y + 1.03, punto.z - 1.12)
	_pose_pantalla = Transform3D(Basis.IDENTITY, cerca).looking_at(pantalla + Vector3(0, 0.0, 0), Vector3.UP)

static func _mezcla(a: Transform3D, b: Transform3D, k: float) -> Transform3D:
	var r := Transform3D()
	r.origin = a.origin.lerp(b.origin, k)
	r.basis = Basis(a.basis.get_rotation_quaternion().slerp(b.basis.get_rotation_quaternion(), k))
	return r

func _mover(a: Transform3D, b: Transform3D, seg: float, trans := Tween.TRANS_SINE, suavizado := Tween.EASE_IN_OUT, balanceo := 0.0) -> void:
	var tw := create_tween()
	tw.tween_method(_poner.bind(a, b, balanceo), 0.0, 1.0, seg).set_trans(trans).set_ease(suavizado)
	await tw.finished

func _poner(k: float, a: Transform3D, b: Transform3D, balanceo: float) -> void:
	if is_instance_valid(_cam):
		var t := _mezcla(a, b, k)
		t.origin.y += sin(k * TAU * 2.0) * balanceo * (1.0 - k)   ## el balanceo del andar
		_cam.global_transform = t

## Caminar hasta el sillón, sentarse, teclear, encender la pantalla y entrar en ella. Devuelve al terminar el fundido (el menú ya puede salir).
func sentarse(explorador: Node3D, punto: Vector3) -> void:
	_preparar(explorador, punto)
	_extras = Node3D.new()
	_extras.name = "PcSentado"
	explorador.add_child(_extras)
	_luz = OmniLight3D.new()
	_luz.light_color = Color(0.55, 0.78, 1.0)
	_luz.light_energy = 0.0
	_luz.omni_range = 2.6
	_luz.shadow_enabled = false
	_extras.add_child(_luz)
	_luz.global_position = Vector3(punto.x, punto.y + 1.05, punto.z - 1.55)
	_pantalla = _crear_pantalla(punto)
	## 1. los últimos pasos (con el balanceo del andar) hacia el escritorio, ya mirando a la pantalla apagada.
	var paso := Vector3(punto.x, punto.y + 1.58, punto.z - 0.35)
	var p_paso := Transform3D(Basis.IDENTITY, paso).looking_at(Vector3(punto.x, punto.y + 1.1, punto.z - 1.78), Vector3.UP)
	Sonido.toca("clic", Sonido.Bus.EFECTOS)
	await _mover(_pose_pie, p_paso, T_PASOS, Tween.TRANS_QUAD, Tween.EASE_OUT, 0.012)
	## 2. se sienta: baja con un rebote suave sobre el sillón.
	await _mover(_cam.global_transform, _pose_sentado, T_SENTAR, Tween.TRANS_BACK, Tween.EASE_OUT)
	Sonido.toca("clic", Sonido.Bus.EFECTOS)
	## 3. las manos sobre el teclado y la pantalla que se enciende.
	_poner_manos(punto)
	_tecleando = true
	var luz := create_tween().set_parallel(true)
	luz.tween_property(_pantalla.material_override, "albedo_color:a", 0.95, 0.5)
	luz.tween_property(_luz, "light_energy", LUZ, 0.45).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.4).timeout
	Sonido.toca("clic", Sonido.Bus.EFECTOS)
	## 4. la cámara se acerca a la pantalla (el campo de visión se cierra) y fundido a negro.
	var fov := create_tween()
	fov.tween_property(_cam, "fov", FOV_ENTRAR, T_ENTRAR).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _mover(_cam.global_transform, _pose_pantalla, T_ENTRAR)
	await _fundir(1.0)

## Con el menú ya encendido, el negro del fundido se retira (lo llama `PcOficina` tras `_mostrar_menu`).
func revelar() -> void:
	await _fundir(0.0, T_FUNDIDO)

## Al levantarse: el menú ya está apagado; se vuelve del fundido, se quita la luz y las manos y la cámara se pone de pie en su sitio.
func levantarse() -> void:
	if not is_instance_valid(_cam):
		return
	_tecleando = false
	await _fundir(1.0, 0.0)   ## el menú se acaba de apagar: arranca en negro...
	await _fundir(0.0, T_FUNDIDO)   ## ...y vuelve a la oficina, sentado frente a la pantalla
	var fov := create_tween()
	fov.tween_property(_cam, "fov", _fov0, T_LEVANTAR * 0.6).set_trans(Tween.TRANS_SINE)
	await _mover(_cam.global_transform, _pose_sentado, T_LEVANTAR * 0.35)
	_quitar_manos()
	Sonido.toca("clic", Sonido.Bus.EFECTOS)
	await _mover(_cam.global_transform, _pose_pie, T_LEVANTAR * 0.65, Tween.TRANS_QUAD, Tween.EASE_OUT)
	_cam.fov = _fov0
	if is_instance_valid(_extras):
		_extras.queue_free()
	if is_instance_valid(_fundido):
		_fundido.queue_free()

func _fundir(a: float, seg := T_FUNDIDO) -> void:
	if _fundido == null or not is_instance_valid(_fundido):
		_fundido = CanvasLayer.new()
		_fundido.layer = 90
		add_child(_fundido)
		_velo = ColorRect.new()
		_velo.color = Color(0.02, 0.03, 0.03, 0.0)
		_velo.set_anchors_preset(Control.PRESET_FULL_RECT)
		_velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fundido.add_child(_velo)
	var tw := create_tween()
	tw.tween_property(_velo, "color:a", a, seg)
	await tw.finished

## Dos antebrazos con manga y dos manos de piel apoyadas en el teclado (el teclado de la oficina está a 0,45 m del centro de la mesa).
func _poner_manos(punto: Vector3) -> void:
	var manga := StandardMaterial3D.new()
	manga.albedo_color = Color(0.1, 0.12, 0.16)
	manga.roughness = 0.9
	var piel := StandardMaterial3D.new()
	piel.albedo_color = Color(0.7, 0.52, 0.4)
	piel.roughness = 0.75
	for lado in [-1.0, 1.0]:
		var mano := MeshInstance3D.new()
		var m := BoxMesh.new()
		m.size = Vector3(0.078, 0.028, 0.1)
		mano.mesh = m
		mano.material_override = piel
		mano.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_extras.add_child(mano)
		mano.global_position = Vector3(punto.x + 0.1 * lado, punto.y + ALTURA_MESA + 0.06, punto.z - 1.3)
		mano.set_meta("base_y", mano.global_position.y)
		mano.set_meta("fase", 0.0 if lado < 0.0 else PI)
		_manos.append(mano)
		var brazo := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.058, 0.055, 0.3)
		brazo.mesh = b
		brazo.material_override = manga
		brazo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mano.add_child(brazo)
		brazo.position = Vector3(0.02 * lado, 0.05, 0.19)   ## el codo queda más cerca de ti y más alto
		brazo.rotation.x = -0.22

## El panel del monitor de la oficina (0,60 × 0,35 m, medido sobre el modelo): empieza apagado y se enciende con un degradado azul.
func _crear_pantalla(punto: Vector3) -> MeshInstance3D:
	var q := MeshInstance3D.new()
	var plano := QuadMesh.new()
	plano.size = Vector2(0.6, 0.35)
	q.mesh = plano
	var g := Gradient.new()
	g.set_color(0, Color(0.1, 0.38, 0.85))
	g.set_color(1, Color(0.02, 0.1, 0.32))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 8
	tex.height = 64
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.albedo_color = Color(1, 1, 1, 0.0)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	q.material_override = mat
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_extras.add_child(q)
	q.global_position = Vector3(punto.x, punto.y + 1.09, punto.z - 1.7)   ## mira hacia +Z (hacia ti)
	return q

func _quitar_manos() -> void:
	for m in _manos:
		if is_instance_valid(m):
			m.queue_free()
	_manos.clear()

func _process(delta: float) -> void:
	if not _tecleando:
		return
	_t_manos += delta
	for m in _manos:
		if is_instance_valid(m):
			var f := _t_manos * 17.0 + float(m.get_meta("fase", 0.0))
			m.global_position.y = float(m.get_meta("base_y", 0.0)) + maxf(0.0, sin(f)) * 0.014
			m.global_position.x += sin(_t_manos * 3.1 + float(m.get_meta("fase", 0.0))) * 0.0004
	if is_instance_valid(_luz):
		_luz.light_energy = LUZ + sin(_t_manos * 9.0) * 0.03
