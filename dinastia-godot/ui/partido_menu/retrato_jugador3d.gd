class_name RetratoJugador3D
extends SubViewportContainer
## EL JUGADOR GRANDE DE LA PREVIA, EN 3D (17-11-2026, orden del dueño: «llegar al realismo de la previa del PES 2020»). En vez de la figura plana, el
## futbolista REAL del partido (`PlayerSpawner._crear_jugador`: cuerpo, cara de la biblioteca, pelo, complexión) con la equipación COMPLETA del club
## (`Puente3D.kit`: diseño, patrocinador, escudo, dorsal), de cuerpo entero y en pose de espera (brazos cruzados o relajados, según el jugador), con luz de
## estudio de tres puntos (principal suave, relleno al ~40 % y contraluz de borde del color del club) y exposición fija. Fondo transparente.
## PRESUPUESTO (Auditoría, 17-11): el modelo se monta en DIFERIDO (`montar`, lo llama `MenuPartido` un cuadro después de abrir, para que el menú salga al
## instante), se deja posar y la vista se dibuja UNA vez y queda quieta (UPDATE_ONCE): con el menú abierto no cuesta nada por cuadro.
## Lo abre `MenuPartido` con `load()` (la memoria del menú no nombra clases del partido 3D). Sin pantalla (`--headless`) no se crea y queda la figura plana.

signal listo

var club: Club
var jugador: Jugador
var colores: Array = []        ## [c1, c2] del uniforme elegido (vacío = el del club)
var gira := 0.0                ## hacia dónde mira (radianes): el de la izquierda mira hacia el centro de la pantalla, y al revés
var _vp: SubViewport
var _raiz: Node3D
var _cam: Camera3D
var _ap: AnimationPlayer
var _esq: Skeleton3D
var _t := 0.0
var hecho := false            ## ya está dibujado y quieto

const ALTO_VISTA := 1.38       ## (Auditoría) de 3/4, de medio muslo (~0,62 m) a un palmo sobre la cabeza: la cara grande y nítida, como el PES
const CENTRO_Y := 1.33
const ALTURA := 1.84           ## los dos a la MISMA escala (y la misma línea de base), sea cual sea su altura real
const GIRO_TORSO := 0.35       ## ~20° hacia el centro de la pantalla; la cabeza vuelve a mirar a cámara
const DISTANCIA := 6.0
const _RUTA_PLAYER_SPAWNER := "res://visor/player_spawner.gd"
const _RUTA_PUENTE3D := "res://visor/puente3d.gd"
## La luz del estudio (las pruebas la varían para comparar).
static var luz := {"key": 0.65, "relleno": 0.2, "rim": 0.7, "exp": 0.72, "amb": 0.2}   ## (Auditoría) más suave sobre la piel: con 0,9/1,3/0,85 las pieles claras salían blancas

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
	r.modulate.a = 0.0
	r._vp = SubViewport.new()
	r._vp.own_world_3d = true
	r._vp.transparent_bg = true
	r._vp.msaa_3d = Viewport.MSAA_DISABLED if Calidad.elegida <= Calidad.MINIMO else Viewport.MSAA_4X   ## en ULTRA BAJA sin MSAA (R01); (Auditoría) sin dientes de sierra en los brazos: se dibuja una vez (o a 30 Hz), el coste es pequeño
	r._vp.mesh_lod_threshold = 0.0
	r._vp.render_target_update_mode = SubViewport.UPDATE_DISABLED   ## nada que dibujar hasta que el modelo esté montado
	r.add_child(r._vp)
	return r

## Monta la escena (luces, cámara y el futbolista). Se llama en diferido: es lo que cuesta.
func montar() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.64, 0.74)
	env.ambient_light_energy = float(luz["amb"])
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = float(luz["exp"])   ## fija: los blancos (pantalón y medias) no se queman y la cara y el dorsal se leen
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
	_cam.fov = rad_to_deg(2.0 * atan(ALTO_VISTA * 0.5 / DISTANCIA))
	_cam.position = Vector3(0, CENTRO_Y, DISTANCIA)
	_cam.look_at_from_position(_cam.position, Vector3(0, CENTRO_Y, 0))
	_vp.add_child(_cam)

## Luz de estudio: principal suave desde arriba y delante, relleno frío al ~40 % al otro lado y contraluz de borde del color del club (el «recorte» del PES).
func _luces() -> void:
	var lado := -1.0 if gira > 0.0 else 1.0
	var key := DirectionalLight3D.new()
	key.light_color = Color(1.0, 0.95, 0.88)
	key.light_energy = float(luz["key"])
	key.shadow_enabled = Calidad.elegida > Calidad.MINIMO   ## en ULTRA BAJA sin sombra
	key.shadow_blur = 2.0
	key.rotation_degrees = Vector3(-28, 32 * lado, 0)
	_raiz.add_child(key)
	var relleno := DirectionalLight3D.new()
	relleno.light_color = Color(0.78, 0.84, 1.0)
	relleno.light_energy = float(luz["relleno"])
	relleno.rotation_degrees = Vector3(-8, -60 * lado, 0)
	_raiz.add_child(relleno)
	var cc := Color(club.color_kit1()) if club != null else Color.WHITE
	var borde := cc.lerp(Color.WHITE, 0.55)
	for x: float in [-1.0, 1.0]:
		var rim := OmniLight3D.new()
		rim.light_color = borde if x == lado else Color(0.85, 0.88, 1.0)
		rim.light_energy = float(luz["rim"])
		rim.omni_range = 4.5
		rim.position = Vector3(1.4 * x, 1.9, -1.6)
		_raiz.add_child(rim)

## La pose de espera: brazos cruzados (tapa las manos, como en la previa del PES); si el modelo no la tiene, de pie relajado.
func _pose(ap: AnimationPlayer, esq: Skeleton3D) -> String:
	if esq != null and AnimExtra.asegurar(ap, esq, "brazos_cruzados"):
		return "brazos_cruzados"
	return "parado"

## Viste (o reviste) al jugador con esos colores; [] = el uniforme titular del club con su diseño completo.
func vestir(cols: Array) -> void:
	colores = cols
	if _raiz == null:
		return
	for h in _raiz.get_children():
		if h is Node3D and not (h is Light3D):
			h.queue_free()
	var spawner = load(_RUTA_PLAYER_SPAWNER).new()
	var kit: Dictionary = load(_RUTA_PUENTE3D).kit(club)
	var c1 := Color(String(kit.get("c1", club.color1)))
	var c2 := Color(String(kit.get("c2", club.color2)))
	var titular := cols.is_empty() or (cols[0] as Color).is_equal_approx(c1)
	if not cols.is_empty():
		c1 = cols[0]
		c2 = cols[1]
	spawner.set("_kit_x", kit.get("x", {}) if titular and kit.get("x") is Dictionary else {})
	var nodo := Node3D.new()
	nodo.rotation.y = GIRO_TORSO * signf(gira)
	_raiz.add_child(nodo)
	var datos: Dictionary = load(_RUTA_PUENTE3D).jugador(jugador)
	var look: Array = load(_RUTA_PLAYER_SPAWNER)._look_de(datos)
	var d: Dictionary = spawner._crear_jugador(nodo, jugador.id, "DEL", "", c1, c2, String(kit.get("estilo", "liso")) if titular else "liso",
		maxi(jugador.dorsal, 1), look[0], look[1], look[2], Color(0, 0, 0, 0), datos)
	if spawner is Node:
		(spawner as Node).queue_free()
	var alto := float(d.get("altura", ALTURA)) if d.has("altura") else ALTURA
	nodo.scale = Vector3.ONE * (ALTURA / maxf(alto, 1.0))
	_ap = d.get("anim")
	var esqs := nodo.find_children("*", "Skeleton3D", true, false)
	_esq = esqs[0] if not esqs.is_empty() else null
	if _ap != null:
		var pose := _pose(_ap, _esq)
		if _ap.has_animation(pose):
			_ap.play(pose)
			_ap.seek(minf(1.2, _ap.current_animation_length * 0.5), true)
	_mirar_a_camara()
	_congelar.call_deferred()

## Deja que la pose se aplique, dibuja la vista una vez y la deja quieta.
func _congelar() -> void:
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	await get_tree().process_frame
	await get_tree().process_frame
	## (Auditoría) De MEDIA para arriba, una espera muy suave (la animación a media velocidad) redibujada a 30 Hz; abajo, congelado (0 coste).
	var vivo := Calidad.elegida >= Calidad.MEDIA and not Animar.reducidas()
	if _ap != null:
		if vivo:
			_ap.speed_scale = 0.5
		else:
			_ap.pause()
	## Sobremuestreo (Auditoría: dientes de sierra en hombros y cuello): quieto, al doble (se dibuja UNA vez); con la espera a 30 Hz, a 1,5.
	_vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	_vp.scaling_3d_scale = 1.5 if vivo else 2.0
	_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	set_process(vivo)
	if modulate.a < 1.0:
		create_tween().tween_property(self, "modulate:a", 1.0, 0.25)
	hecho = true
	listo.emit()

func _ready() -> void:
	set_process(false)

func _process(delta: float) -> void:
	_t += delta
	if _t >= 1.0 / 30.0:
		_t = 0.0
		_vp.render_target_update_mode = SubViewport.UPDATE_ONCE

## El torso va girado hacia el centro; el cuello y la cabeza deshacen ese giro para mirar a cámara. Va como modificador del esqueleto (corre DESPUÉS
## de la animación cada vez que se actualiza y no se acumula), así vale tanto quieto como con la espera suave.
## El ajuste de los brazos cruzados (eje local del hueso y grados): las pruebas lo varían para comparar.
static var brazos := {"eje": Vector3.UP, "grados": 25.0}   ## (Auditoría) el cruce baja al estómago: en X delante del pecho tapaba el escudo
class MirarCamara extends SkeletonModifier3D:
	var giro := 0.0
	var cruzados := false   ## el ajuste de los brazos solo con los brazos cruzados
	func _process_modification() -> void:
		var esq := get_skeleton()
		if esq == null:
			return
		var g := float(RetratoJugador3D.brazos["grados"])
		if not is_zero_approx(g) and cruzados:
			for par: Array in [["upperarm_l", 1.0], ["upperarm_r", -1.0]]:
				var k := esq.find_bone(String(par[0]))
				if k >= 0:
					esq.set_bone_pose_rotation(k, esq.get_bone_pose_rotation(k) * Quaternion(RetratoJugador3D.brazos["eje"], deg_to_rad(g) * float(par[1])))
		for par: Array in [["neck_01", 0.45], ["Head", 0.55]]:
			var i := esq.find_bone(String(par[0]))
			if i >= 0:
				esq.set_bone_pose_rotation(i, Quaternion(Vector3.UP, -giro * float(par[1])) * esq.get_bone_pose_rotation(i))

func _mirar_a_camara() -> void:
	if _esq == null or _esq.has_node("MirarCamara"):
		return
	var m := MirarCamara.new()
	m.name = "MirarCamara"
	m.giro = GIRO_TORSO * signf(gira)
	m.cruzados = _ap != null and _ap.current_animation == "brazos_cruzados"
	_esq.add_child(m)
