class_name EstudioPersonaje
extends Control
## EL ESTUDIO DEL PERSONAJE (25-10-2026): tu personaje en 3D en vivo, sobre una
## tarima con el aro del color del club, girando despacio. Lo usan la etapa de
## entrada (`PantallaPersonaje`) y el creador del menú (`CreadorPersonaje`).
##   - Arrastrar (ratón o dedo): girarlo a mano. Al soltarlo, a los 3 s vuelve
##     a girar solo (si el giro está encendido).
##   - Rueda o los botones «Cuerpo / Cara»: de cuerpo entero al primer plano.
##   - El fondo es un degradado 2D con el color del club (el visor 3D va con
##     fondo transparente encima): un foco de estudio, no una caja negra.
## El cuadro 3D se rehace un instante después del último cambio (`mostrar`),
## para no reconstruir el modelo veinte veces mientras se arrastra un deslizador.

const RETARDO := 0.16
const GIRO := 0.45            ## rad/s
const VOLVER_A_GIRAR := 3.0   ## s sin tocarlo

var c1 := Color("1f5fa8")
var c2 := Color.WHITE
var girar := true
var _asp: Dictionary = {}
var _pendiente := -1.0
var _vp: SubViewport
var _cam: Camera3D
var _pivote: Node3D
var _actual: Dictionary = {}
var _arrastrando := false
var _quieto := VOLVER_A_GIRAR
var _zoom := 0.0              ## 0 cuerpo entero, 1 primer plano
var _zoom_obj := 0.0
var _fondo: TextureRect
var _aro: StandardMaterial3D
var _b_cuerpo: Button
var _b_cara: Button
var _b_giro: Button

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_fondo = TextureRect.new()
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fondo.stretch_mode = TextureRect.STRETCH_SCALE
	_fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fondo)
	var cont := SubViewportContainer.new()
	cont.stretch = true
	cont.set_anchors_preset(Control.PRESET_FULL_RECT)
	cont.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(cont)
	_vp = SubViewport.new()
	_vp.transparent_bg = true
	_vp.msaa_3d = Viewport.MSAA_4X
	_vp.own_world_3d = true
	cont.add_child(_vp)
	_montar_escena()
	_montar_botones()
	colores(c1, c2)
	if not _asp.is_empty():
		_rearmar()

## Los colores del club: el aro de la tarima, el foco del fondo y el chándal.
func colores(a: Color, b: Color) -> void:
	c1 = a
	c2 = b
	if _fondo == null:
		return
	## Un color de club muy oscuro (negro, granate) no se vería: se aclara.
	var luz := c1 if c1.get_luminance() > 0.28 else c1.lightened(0.35)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([luz.darkened(0.45).lerp(Color("1b2620"), 0.35), Color("111a15"), Color("080d0a")])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.42)
	t.fill_to = Vector2(0.5, 1.12)
	t.width = 256
	t.height = 256
	_fondo.texture = t
	if _aro != null:
		_aro.albedo_color = luz
		_aro.emission = luz

## El aspecto a enseñar. `ya`: sin esperar (al abrir).
func mostrar(asp: Dictionary, ya := false) -> void:
	_asp = asp.duplicate()
	if ya and _pivote != null:
		_rearmar()
	else:
		_pendiente = RETARDO

func enfocar(cara: bool) -> void:
	_zoom_obj = 1.0 if cara else 0.0
	if cara and _pivote != null:
		## De frente para ver la cara: el giro se para y el muñeco se vuelve.
		girar = false
		_pivote.rotation.y = wrapf(_pivote.rotation.y, -PI, PI)
		create_tween().tween_property(_pivote, "rotation:y", 0.0, 0.35).set_trans(Tween.TRANS_SINE)
	_pintar_botones()

func _montar_escena() -> void:
	var mundo3 := Node3D.new()
	_vp.add_child(mundo3)
	_cam = Camera3D.new()
	_cam.fov = 30
	mundo3.add_child(_cam)
	## Luz de tres puntos: principal cálida con sombra, relleno frío y un
	## contraluz que despega la silueta del fondo.
	var luces := [[Vector3(-32, 28, 0), 1.0, Color(1.0, 0.95, 0.88), true],
		[Vector3(-12, -45, 0), 0.32, Color(0.8, 0.88, 1.0), false],
		[Vector3(-25, 165, 0), 0.75, Color(1.0, 0.97, 0.92), false]]
	for l: Array in luces:
		var luz := DirectionalLight3D.new()
		luz.rotation_degrees = l[0]
		luz.light_energy = float(l[1])
		luz.light_color = l[2]
		luz.shadow_enabled = bool(l[3])
		mundo3.add_child(luz)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.57, 0.62)
	e.ambient_light_energy = 0.42
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_exposure = 0.95
	e.tonemap_white = 6.0
	env.environment = e
	mundo3.add_child(env)
	## La tarima: disco oscuro mate con un aro que brilla del color del club.
	var tarima := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.72
	cm.bottom_radius = 0.78
	cm.height = 0.07
	tarima.mesh = cm
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(0.06, 0.07, 0.08)
	mt.roughness = 0.95
	mt.metallic_specular = 0.2
	tarima.material_override = mt
	tarima.position.y = -0.035
	mundo3.add_child(tarima)
	var aro := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.735
	tm.outer_radius = 0.77
	aro.mesh = tm
	_aro = StandardMaterial3D.new()
	_aro.emission_enabled = true
	_aro.emission_energy_multiplier = 1.4
	aro.material_override = _aro
	mundo3.add_child(aro)
	_pivote = Node3D.new()
	mundo3.add_child(_pivote)
	_colocar_camara()

## Cámara entre el cuerpo entero y el primer plano, según la estatura.
func _colocar_camara() -> void:
	var h := float(_asp.get("altura", 1.78))
	var z := ease(_zoom, -1.6)
	var mira := Vector3(0, lerpf(h * 0.5, h * 0.92, z), 0)
	var desde := Vector3(0, lerpf(h * 0.58, h * 0.94, z), lerpf(4.6, 1.15, z))
	_cam.transform = Transform3D(Basis.looking_at(mira - desde, Vector3.UP), desde)

func _montar_botones() -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	fila.position = Vector2(14, 14)
	add_child(fila)
	_b_cuerpo = ControlesPersonaje.chip(Idiomas.t("Cuerpo entero"), true, func() -> void: enfocar(false))
	_b_cara = ControlesPersonaje.chip(Idiomas.t("Cara"), false, func() -> void: enfocar(true))
	_b_giro = ControlesPersonaje.chip(Idiomas.t("⟳ Girar"), true, func() -> void:
		girar = not girar
		_quieto = VOLVER_A_GIRAR
		_pintar_botones())
	for b: Button in [_b_cuerpo, _b_cara, _b_giro]:
		fila.add_child(b)

## Los chips reflejan el estado.
func _pintar_botones() -> void:
	if _b_cuerpo == null:
		return
	for par: Array in [[_b_cuerpo, _zoom_obj < 0.5], [_b_cara, _zoom_obj >= 0.5], [_b_giro, girar]]:
		ControlesPersonaje.estilar_chip(par[0], bool(par[1]))

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_arrastrando = mb.pressed
			_quieto = 0.0
		elif mb.pressed and mb.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			_zoom_obj = clampf(_zoom_obj + (0.12 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else -0.12), 0.0, 1.0)
			_pintar_botones()
			accept_event()
	elif ev is InputEventMouseMotion and _arrastrando:
		_pivote.rotation.y += (ev as InputEventMouseMotion).relative.x * 0.01
		_quieto = 0.0
	elif ev is InputEventScreenDrag:
		_pivote.rotation.y += (ev as InputEventScreenDrag).relative.x * 0.01
		_quieto = 0.0
	elif ev is InputEventMagnifyGesture:
		_zoom_obj = clampf(_zoom_obj + ((ev as InputEventMagnifyGesture).factor - 1.0), 0.0, 1.0)

func _process(delta: float) -> void:
	if _pivote == null:
		return
	_quieto += delta
	if girar and not _arrastrando and _quieto >= VOLVER_A_GIRAR:
		_pivote.rotation.y += delta * GIRO
	if absf(_zoom - _zoom_obj) > 0.001:
		_zoom = move_toward(_zoom, _zoom_obj, delta * 2.2)
		_colocar_camara()
	if _pendiente > 0.0:
		_pendiente -= delta
		if _pendiente <= 0.0:
			_rearmar()

func _rearmar() -> void:
	if _pivote == null or not _pivote.is_inside_tree():
		return
	if not _actual.is_empty() and is_instance_valid(_actual.get("nodo")):
		(_actual["nodo"] as Node).queue_free()
	_actual = PersonajeDT.crear(_pivote, _asp, c1, c2)
	_colocar_camara()

## Para las pruebas: el modelo que se ve ahora ({} si aún no se armó).
func modelo() -> Dictionary:
	return _actual
