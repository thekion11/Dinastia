class_name CamaraTactil
extends RefCounted
## LA CÁMARA DEL PARTIDO EN EL MÓVIL (4-11-2026, orden del dueño por la líder: «el jugador controlado se ve como un punto»). La cámara de siempre va a 12,5 m de altura y 15 m detrás del jugador (≈19,5 m): en un
## teléfono el jugador mide ≈8 % de la altura de la pantalla. Con los controles táctiles puestos (o si se elige en Ajustes → Dispositivo) se acerca a `CERCA` (≈11 m) y mira menos hacia el balón (`PESO_BALON`): el jugador mide ≈14 % de la altura. Cuando el balón
## se aleja del jugador que llevas (de `LEJOS_INI` a `LEJOS_FIN` m) la cámara pasa a seguir al BALÓN (punto de mira casi sobre él y distancia de siempre): con el balón a la espalda del jugador la cámara
## de detrás del jugador no lo podía enseñar (ni en PC), y sin balón a la vista no se juega en el móvil. En cuanto el balón vuelve cerca del jugador, la cámara vuelve a él. Solo multiplica la distancia de la cámara «detrás del jugador»; no toca la de los
## lanzamientos, el penal, el portero ni el apuntado.
const CERCA := 0.6
const PESO_CERCA := 0.12               ## cuánto se desplaza el punto de mira hacia el balón con el balón cerca del jugador (0,35 en la de siempre)
const PESO_LEJOS := 0.9                ## y con el balón lejos: casi sobre el balón
const ZOOM_LEJOS := 0.95               ## distancia relativa con el balón lejos (1 = la de siempre)
const LEJOS_INI := 14.0
const LEJOS_FIN := 30.0

## ¿Va la cámara cercana en este partido? (se lee una vez y se guarda en el nodo del partido)
static func cercana(pj: Node) -> bool:
	if not pj.has_meta("_cam_cercana"):
		pj.set_meta("_cam_cercana", AjustesTactil.camara_cercana(HudTactil.activo(pj)))
	return bool(pj.get_meta("_cam_cercana"))

## 0 = balón cerca del jugador (cámara tensa sobre él), 1 = balón lejos (cámara sobre el balón).
static func lejania(motor: MotorJugable) -> float:
	if motor.usuario.is_empty():
		return 0.0
	var d := motor.pos(motor.usuario).distance_to(motor.balon.position)
	return smoothstep(LEJOS_INI, LEJOS_FIN, d)

## Factor (0,6-0,95) que multiplica la distancia de la cámara «detrás del jugador».
static func zoom(pj: Node, motor: MotorJugable) -> float:
	if not cercana(pj):
		return 1.0
	return lerpf(CERCA, ZOOM_LEJOS, lejania(motor))

## Cuánto se desplaza el punto de mira desde el jugador hacia el balón (0,35 de siempre).
static func peso_balon(pj: Node, motor: MotorJugable) -> float:
	if not cercana(pj):
		return 0.35
	return lerpf(PESO_CERCA, PESO_LEJOS, lejania(motor))
