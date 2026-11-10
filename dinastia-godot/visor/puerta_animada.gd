class_name PuertaAnimada
extends Node3D
## LA PUERTA QUE SE ABRE AL ACERCARSE (10-11, reestructuración «solo club», paso 2). Es la BISAGRA de una hoja de `PuertasClub`: cerrada tapa el hueco
## y, cuando la cámara del paseo (que va detrás del jugador) se acerca a menos de `RADIO` en la misma planta, gira hasta quedar abierta contra el
## tabique; al alejarse se vuelve a cerrar. Solo es visual: no choca, así que nunca bloquea el paso. Sin cámara (pruebas sin pantalla) se queda abierta.
const RADIO := 3.2
const ABIERTA := PI
const VELOCIDAD := 4.0   ## radianes por segundo (≈0,8 s de cerrada a abierta)

var centro_local := Vector3.ZERO   ## el centro del hueco, en coordenadas del edificio (lo pone `PuertasClub`)

func _ready() -> void:
	rotation.y = ABIERTA

## El ángulo que toca con un observador en `punto` (global): abierta si está cerca y en la misma planta, cerrada si no.
func abrir_ahora_segun(punto: Vector3) -> float:
	var centro: Vector3 = (get_parent() as Node3D).to_global(centro_local) if is_inside_tree() and get_parent() is Node3D else centro_local
	var d := Vector2(punto.x - centro.x, punto.z - centro.z).length()
	return ABIERTA if d < RADIO and absf(punto.y - centro.y) < 2.6 else 0.0

func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam == null:
		return
	var meta := abrir_ahora_segun(cam.global_position)
	rotation.y = move_toward(rotation.y, meta, VELOCIDAD * delta)
