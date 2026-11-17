class_name RetratoJugador3D
extends SubViewportContainer
## EL JUGADOR GRANDE DE LA PREVIA, EN 3D (17-11-2026, orden del dueño: «llegar al realismo de la previa del PES 2020»). En vez de la figura plana, el
## futbolista REAL del partido (`PlayerSpawner._crear_jugador`: cuerpo, cara de la biblioteca, pelo, complexión) con la equipación COMPLETA del club
## (`Puente3D.kit`: diseño, patrocinador, escudo, dorsal), quieto y respirando, iluminado como en un estudio: luz principal cálida, relleno frío y un
## contraluz del color del club que le recorta la silueta contra el fondo. Fondo transparente: debajo se ve el fondo de la previa.
## Lo abre `MenuPartido` con `load()` (la memoria del menú no nombra clases del partido 3D). Sin pantalla (`--headless`) no se crea y queda la figura plana.

var club: Club
var jugador: Jugador
var colores: Array = []        ## [c1, c2] del uniforme elegido (vacío = el del club)
var gira := 0.0                ## hacia dónde mira (radianes): el de la izquierda mira un poco a la derecha, y al revés
var _vp: SubViewport
var _raiz: Node3D
var _cam: Camera3D

static func crear(c: Club, j: Jugador, cols: Array, giro: float) -> RetratoJugador3D:
	if DisplayServer.get_name() == "headless" or c == null or j == null:
		return null
	var r := RetratoJugador3D.new()
	r.club = c
	r.jugador = j
	r.colores = cols
	r.gira = giro
	r.stretch = true
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r._vp = SubViewport.new()
	r._vp.own_world_3d = true
	r._vp.transparent_bg = true
	r._vp.msaa_3d = Viewport.MSAA_4X
	if RenderingServer.get_current_rendering_method() != "gl_compatibility":
		r._vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	r._vp.mesh_lod_threshold = 0.0
	r.add_child(r._vp)
	r._montar()
	return r

func _montar() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.64, 0.74)
	env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.85   ## sin quemar los blancos (pantalón y medias)
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.06
	env.adjustment_saturation = 1.06
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)
	_raiz = Node3D.new()
	_vp.add_child(_raiz)
	_luces()
	vestir(colores)
	_cam = Camera3D.new()
	_cam.fov = 19.0   ## de media espinilla a la cabeza, como el PES
	_cam.position = Vector3(0, 1.2, 5.6)
	_cam.look_at_from_position(_cam.position, Vector3(0, 1.08, 0))
	_vp.add_child(_cam)

## Luz de estudio: principal cálida desde arriba y delante, relleno frío al otro lado y contraluz del color del club (el «recorte» del PES).
func _luces() -> void:
	var lado := -1.0 if gira > 0.0 else 1.0
	var key := DirectionalLight3D.new()
	key.light_color = Color(1.0, 0.95, 0.88)
	key.light_energy = 0.9
	key.shadow_enabled = true
	key.rotation_degrees = Vector3(-28, 32 * lado, 0)
	_raiz.add_child(key)
	var relleno := DirectionalLight3D.new()
	relleno.light_color = Color(0.72, 0.8, 1.0)
	relleno.light_energy = 0.22
	relleno.rotation_degrees = Vector3(-8, -60 * lado, 0)
	_raiz.add_child(relleno)
	var cc := Color(club.color_kit1()) if club != null else Color.WHITE
	var borde := cc.lerp(Color.WHITE, 0.55)
	for x: float in [-1.0, 1.0]:
		var rim := OmniLight3D.new()
		rim.light_color = borde if x == lado else Color(0.85, 0.88, 1.0)
		rim.light_energy = 1.3
		rim.omni_range = 4.5
		rim.position = Vector3(1.4 * x, 1.9, -1.6)
		_raiz.add_child(rim)

## Viste (o reviste) al jugador con esos colores; [] = el uniforme titular del club con su diseño completo.
func vestir(cols: Array) -> void:
	colores = cols
	for h in _raiz.get_children():
		if h is Node3D and not (h is Light3D):
			h.queue_free()
	var spawner = load("res://visor/player_spawner.gd").new()
	var kit: Dictionary = load("res://visor/puente3d.gd").kit(club)
	var c1 := Color(String(kit.get("c1", club.color1)))
	var c2 := Color(String(kit.get("c2", club.color2)))
	var titular := cols.is_empty() or (cols[0] as Color).is_equal_approx(c1)
	if not cols.is_empty():
		c1 = cols[0]
		c2 = cols[1]
	spawner.set("_kit_x", kit.get("x", {}) if titular and kit.get("x") is Dictionary else {})
	var nodo := Node3D.new()
	nodo.rotation.y = gira
	_raiz.add_child(nodo)
	var datos: Dictionary = load("res://visor/puente3d.gd").jugador(jugador)
	var look: Array = load("res://visor/player_spawner.gd")._look_de(datos)
	var d: Dictionary = spawner._crear_jugador(nodo, jugador.id, "DEL", "", c1, c2, String(kit.get("estilo", "liso")) if titular else "liso",
		maxi(jugador.dorsal, 1), look[0], look[1], look[2], Color(0, 0, 0, 0), datos)
	if spawner is Node:
		(spawner as Node).queue_free()
	var ap: AnimationPlayer = d.get("anim")
	if ap != null and ap.has_animation("parado"):
		ap.play("parado")
		ap.seek(fmod(float(absi(jugador.id.hash()) % 100) * 0.07, maxf(ap.current_animation_length, 0.1)), true)
