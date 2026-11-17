class_name AnimLejana
extends Node
## (14-11, orden del dueño: «la animación pausada a 30 m») Con las siluetas de `ImpostorLejano`, el jugador a más de `LEJOS` m de la cámara no
## dibuja su cuerpo, así que su esqueleto no hace falta a 60 Hz: su `AnimationPlayer` pasa a modo manual y avanza en saltos de `PASO` s
## (5 veces menos trabajo). No se detiene nunca (las señales de fin de animación y los gestos siguen llegando, solo con retraso de hasta
## `PASO`); al volver a menos de `CERCA` m recupera su ritmo normal ANTES de que su cuerpo reaparezca (la silueta se cambia a 30 m).
const LEJOS := 36.0
const CERCA := 33.0
const PASO := 0.2
const MEDIO := 1.0 / 30.0   ## s: el paso con el cuerpo barato de media distancia (la mitad de 60 Hz)
var _ap: AnimationPlayer
var _cuerpo: Node3D
var _lejos := false
var _acum := 0.0

static func poner(cuerpo: Node3D, ap: AnimationPlayer) -> void:
	if cuerpo == null or ap == null:
		return
	var n := AnimLejana.new()
	n.name = "AnimLejana"
	n._ap = ap
	n._cuerpo = cuerpo
	cuerpo.add_child(n)

func _process(delta: float) -> void:
	if not is_instance_valid(_ap):
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null or not _cuerpo.is_inside_tree():
		return
	ImpostorLejano.vigilar(get_viewport())
	## (17-11) A saltos desde que deja el cuerpo completo (`LEJOS`): a media frecuencia (30 Hz) con el cuerpo barato de media distancia y a
	## `PASO` cuando ya es silueta (el umbral de `ImpostorLejano`, por tamaño en pantalla).
	var d2 := cam.global_position.distance_squared_to(_cuerpo.global_position)
	var paso := PASO if d2 > ImpostorLejano.distancia * ImpostorLejano.distancia else MEDIO
	if not _lejos and d2 > LEJOS * LEJOS:
		_lejos = true
		_acum = 0.0
		_ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	elif _lejos and d2 < CERCA * CERCA:
		_lejos = false
		_ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE
	if _lejos:
		_acum += delta
		if _acum >= paso:
			_ap.advance(_acum)
			_acum = 0.0

func _exit_tree() -> void:
	if _lejos and is_instance_valid(_ap):
		_ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE
