class_name VistaJuego
extends RefCounted
## LA CÁMARA DEL JUEGO (12-11-2026, decisión del dueño): al mover al personaje (el avatar) por el club, el estadio y la casa, SOLO existe
## la visión en PRIMERA PERSONA. Las demás vistas (tercera persona, planos lejanos) quedan para las capturas, los vídeos y las herramientas
## fuera del juego: se encienden con la variable de entorno `DINASTIA_CAMARAS=1` (o poniendo `primera_persona = false` desde una prueba).
## Sin ella, la tecla V ya no cambia de vista.

static func solo_primera_persona() -> bool:
	return OS.get_environment("DINASTIA_CAMARAS") != "1"

## La vista con la que se empieza a caminar.
static func inicial() -> bool:
	return solo_primera_persona()

## ¿Se puede cambiar de vista con V? Solo fuera del juego.
static func puede_cambiar() -> bool:
	return not solo_primera_persona()

## MIRAR EN PRIMERA PERSONA (12-11): el arrastre del dedo en la parte DERECHA de la pantalla (la izquierda es de la cruceta), el ratón
## capturado y el stick derecho giran la vista (x) y la suben o bajan (y). Devuelve (giro, cabeceo) en radianes para sumar.
const SENS_DEDO := 0.006
const SENS_RATON := 0.003
const SENS_STICK := 2.4
const CABECEO_MIN := -0.75   ## mirar al suelo
const CABECEO_MAX := 0.55    ## mirar arriba

static func mirada_por_evento(ev: InputEvent, ancho_pantalla: float) -> Vector2:
	if ev is InputEventScreenDrag and (ev as InputEventScreenDrag).position.x > ancho_pantalla * 0.42:
		var r := (ev as InputEventScreenDrag).relative
		return Vector2(r.x, r.y) * SENS_DEDO
	if ev is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		return (ev as InputEventMouseMotion).relative * SENS_RATON
	return Vector2.ZERO

static func mirada_stick(delta: float) -> Vector2:
	var v := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if v.length() < 0.2:
		return Vector2.ZERO
	return v * SENS_STICK * delta

static func cabeceo(actual: float, d: float) -> float:
	return clampf(actual - d, CABECEO_MIN, CABECEO_MAX)
