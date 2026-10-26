class_name CineGol
extends Node
## LA REALIZACIÓN DEL GOL (13-10-2026, como en el vídeo de FC 26), sacada de
## `VistaEstadio` el 16-10-2026 para que la use también la Carrera de Jugador
## (`PartidoJugable`) sin copiar código. Cuatro planos:
##   1. El goleador, de cerca, a la altura del pecho, siguiéndolo (la carrera al
##      córner y el abrazo los hace el motor: `MotorJugable._ia_celebracion`).
##      A los 0,7 s, la carta del goleador (`CartaGoleador`).
##   2. El banquillo del que marcó (señal `banquillo`, para que salte), con un
##      barrido del escudo.
##   3. La grada: un paneo lento por la tribuna, con otro barrido.
##   4. Barrido final, vuelve la cámara de antes y `terminado` (quien lo usa
##      lanza entonces la repetición).
## Se crea DENTRO del mundo 3D (hijo de `raiz`) para que `get_viewport()` sea
## el del partido aunque viva en un `SubViewport`; la interfaz (carta y
## barridos) va al `ui` que se le pasa. Lo mueve `paso()`: quien lo usa decide
## cuándo corre (el modo entrenador lo congela con su reloj); con `auto`, solo.

signal banquillo
signal terminado

const DURACION := 7.0
## El barrido de marca tapa el centro de la pantalla a mitad de su recorrido: arranca ANTES
## del corte para que el cambio de plano quede escondido detrás de la franja (25-10-2026; antes
## se veía el corte en seco y después pasaba la franja).
const BARRIDO := 0.35
const BARRIDO_FINAL := 0.5

var t := -1.0
var auto := false
var _ui: Control
var _club: Club
var _es_local := true
var _autor: Node3D
var _carta: Callable
var _carta_mostrada := false
var _dx := 49.0
var _cam: Camera3D
var _previa: Camera3D

## `carta`: devuelve {dorsal, nombre, tiros, goles} (o {} sin carta) cuando el
## plano encuadra al goleador, así los contadores ya incluyen este gol.
## `es_local`: si marcó el local (su banquillo está en -Z).
static func iniciar(ui: Control, raiz: Node3D, club: Club, es_local: bool, autor: Node3D, carta: Callable,
		dx: float) -> CineGol:
	var n := CineGol.new()
	n.name = "CineGol"
	n._ui = ui
	n._club = club
	n._es_local = es_local
	n._autor = autor
	n._carta = carta
	n._dx = dx
	raiz.add_child(n)
	n._cam = Camera3D.new()
	n._cam.fov = 38.0
	n._cam.far = 700.0
	raiz.add_child(n._cam)
	n._previa = n.get_viewport().get_camera_3d()
	n._cam.current = true
	n.t = 0.0
	return n

func activo() -> bool:
	return t >= 0.0

func _process(delta: float) -> void:
	if auto:
		paso(delta)

func paso(delta: float) -> void:
	if t < 0.0 or not is_instance_valid(_cam):
		return
	t += delta
	var autor := _autor if is_instance_valid(_autor) else null
	## La carta del goleador, en cuanto el plano lo encuadra.
	if not _carta_mostrada and t > 0.7:
		_carta_mostrada = true
		var d: Dictionary = _carta.call() if _carta.is_valid() else {}
		if not d.is_empty() and is_instance_valid(_ui):
			CartaGoleador.mostrar(_ui, _club, int(d.get("dorsal", 0)), String(d.get("nombre", "")),
				int(d.get("tiros", 1)), int(d.get("goles", 1)), autor)
	## Los barridos, medio barrido antes de cada corte.
	for corte in [3.4, 5.4]:
		if t - delta < corte - BARRIDO * 0.5 and t >= corte - BARRIDO * 0.5:
			barrido(_ui, _club, BARRIDO)
	if t < 3.4:
		## 1) El goleador, de cerca, a la altura del pecho, siguiéndolo.
		if autor != null:
			var a := autor.global_position
			var fwd := Vector3(sin(autor.global_rotation.y), 0, cos(autor.global_rotation.y))
			var deseo := a + fwd * 6.8 + Vector3(fwd.z, 0, -fwd.x) * 2.2 + Vector3(0, 1.9, 0)
			_cam.global_position = _cam.global_position.lerp(deseo, clampf(delta * 3.0, 0, 1)) if t > 0.05 else deseo
			_cam.look_at(a + Vector3(0, 1.3, 0), Vector3.UP)
	elif t < 5.4:
		## 2) El banquillo del que marcó (de pie, saltando).
		if t - delta < 3.4:
			banquillo.emit()
		var z := (-1.0 if _es_local else 1.0) * 14.0
		_cam.global_position = Vector3(27.5, 2.0, z + (-5.0 if _es_local else 5.0))
		_cam.look_at(Vector3(34.6, 1.3, z), Vector3.UP)
	elif t < DURACION + BARRIDO_FINAL * 0.5:
		## 3) La grada: un paneo lento por la tribuna (sigue un poco bajo el barrido final).
		if t - delta < DURACION and t >= DURACION:
			barrido(_ui, _club, BARRIDO_FINAL)
		var f := minf((t - 5.4) / 1.6, 1.0 + BARRIDO_FINAL * 0.3)
		_cam.global_position = Vector3(-_dx * 0.42, 2.6, lerpf(-14.0, 14.0, f))
		_cam.look_at(Vector3(-_dx, 8.5, lerpf(-18.0, 18.0, f)), Vector3.UP)
	else:
		## 4) Con la franja tapando la pantalla, vuelta (y la repetición).
		_fin()

## Corta en seco (otro gol encima, el final del partido...): sin barrido ni
## `terminado` (no lanza la repetición).
func cortar() -> void:
	if t >= 0.0:
		_fin(false)

func _fin(avisar := true) -> void:
	t = -1.0
	if is_instance_valid(_previa) and _previa != _cam:
		_previa.current = true
	if is_instance_valid(_cam):
		_cam.queue_free()
	if avisar:
		terminado.emit()
	queue_free()

## EL BARRIDO DE MARCA: una franja inclinada con el color y el escudo del club
## que cruza la pantalla (como la estrella girando de la transmisión del vídeo,
## pero nuestra).
static func barrido(ui: Control, c: Club, seg: float) -> void:
	if c == null or not is_instance_valid(ui):
		return
	var vp := ui.get_viewport().get_visible_rect().size
	var banda := Panel.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(c.color1)
	st.border_color = Color(c.color2)
	st.border_width_left = 14
	st.border_width_right = 14
	st.skew = Vector2(0.35, 0)
	banda.add_theme_stylebox_override("panel", st)
	banda.size = Vector2(vp.x * 0.7, vp.y + 40.0)
	banda.position = Vector2(-banda.size.x - 200.0, -20.0)
	banda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banda.z_index = 140
	var esc := TextureRect.new()
	esc.texture = Escudo.textura(c, 256)
	esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	esc.size = Vector2(220, 220)
	esc.position = Vector2(banda.size.x * 0.5 - 110.0, banda.size.y * 0.5 - 110.0)
	banda.add_child(esc)
	ui.add_child(banda)
	var tw := banda.create_tween()
	tw.tween_property(banda, "position:x", vp.x + 200.0, seg).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(banda.queue_free)
