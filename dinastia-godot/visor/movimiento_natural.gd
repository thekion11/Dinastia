class_name MovimientoNatural
extends RefCounted
## MOVIMIENTO NATURAL DE LOS PEATONES (calidad visual P1-P3 «MEJORAR», 27-10-2026, orden del dueño). Antes: el peatón frenado
## (por el jugador, un semáforo, el de delante) seguía moviendo las piernas sin avanzar, arrancaba a velocidad plena de golpe y
## giraba en las esquinas de un fotograma al siguiente. Ahora:
##   - ARRANQUE y PARADA: la velocidad sube en `ARRANQUE` s y el clip sigue esa velocidad (sin patinar); si no avanza, pasa a «parado».
##   - GIRO: el cuerpo gira con suavidad hacia donde va a ir (mira 0,5 m por delante en la ruta), no de golpe.
const ARRANQUE := 0.45
const GIRO := 7.0
const ANTICIPO := 0.5
const MIN_CAMBIO := 0.4   ## segundos mínimos entre «anda» y «parado» (evita parpadeos si el frenado oscila)
const NATURAL := 1.02     ## m/s que avanza el pie apoyado en el clip «caminar» (`ExploradorCiudadP1.VEL_NATURAL_CLIP`)

## Hacia dónde mira el cuerpo este fotograma: gira hacia `objetivo` con suavidad.
static func girar(actual: float, objetivo: float, delta: float) -> float:
	return lerp_angle(actual, objetivo, 1.0 - exp(-GIRO * delta))

## Lo que avanza el peatón `v` este fotograma (`avance` es lo que le dejan; `pedido`, lo que querría): aplica la rampa de
## arranque y mantiene el clip en sintonía. Devuelve el avance real.
static func marcha(v: Dictionary, avance: float, pedido: float, delta: float) -> float:
	var anda := avance > pedido * 0.3
	var k := float(v.get("k", 1.0))
	k = move_toward(k, 1.0 if anda else 0.0, delta / ARRANQUE if anda else 1.0)
	v["k"] = k
	var t := float(v.get("t_anda", 0.0)) - delta
	var ya := bool(v.get("anda", true))
	if anda != ya and t <= 0.0:
		v["anda"] = anda
		v["t_anda"] = MIN_CAMBIO
		_clip(v, "caminar" if anda else "parado", k)
	else:
		v["t_anda"] = maxf(t, 0.0)
		if anda and ya and k < 1.0:
			_velocidad(v, float(v["vel"]) * maxf(k, 0.4))
	if anda and ya and k >= 1.0 and bool(v.get("rampa", false)):
		v["rampa"] = false
		_velocidad(v, float(v["vel"]))
	if k < 1.0:
		v["rampa"] = true
	return minf(avance, pedido * k)

static func _reproductor(v: Dictionary) -> AnimationPlayer:
	var ap: AnimationPlayer = v.get("ap_mn")
	if ap != null and is_instance_valid(ap):
		return ap
	var nodo: Node3D = v["nodo"]
	if not is_instance_valid(nodo):
		return null
	var lista := nodo.find_children("*", "AnimationPlayer", true, false)
	if lista.is_empty():
		return null
	ap = lista[0]
	v["ap_mn"] = ap
	return ap

static func _velocidad(v: Dictionary, vel: float) -> void:
	var ap := _reproductor(v)
	if ap != null and ap.current_animation == "caminar":
		ap.speed_scale = clampf(vel / NATURAL, 0.5, 1.8)

static func _clip(v: Dictionary, nombre: String, k: float) -> void:
	var ap := _reproductor(v)
	if ap == null or not ap.has_animation(nombre):
		return
	ap.play(nombre, 0.25)
	if nombre == "caminar":
		ap.speed_scale = clampf(float(v["vel"]) * maxf(k, 0.4) / NATURAL, 0.5, 1.8)
	else:
		ap.speed_scale = 1.0

## INCLINACIÓN AL GIRAR (P2, 31-10): quien gira corriendo se inclina hacia dentro de la curva, como un corredor (ángulo físico
## atan(v·ω/g), rebajado a `INCLINA_K` y con tope `INCLINA_MAX`: el giro del juego es más cerrado que el de una persona). Andando
## no se inclina (se gira a pasos): entra entre 2 y 4,5 m/s; corriendo a 5 m/s y girando a tope, ~11° (tope 11,5°). `giro` es la velocidad de giro del cuerpo (rad/s, + = a la
## izquierda). Devuelve el balanceo (rotation.z del cuerpo, que mira a +Z: + inclina a la derecha), suavizado.
const INCLINA_K := 0.3
const INCLINA_MAX := 0.2
const INCLINA_SUAVE := 5.0

static func inclinacion(actual: float, giro: float, vel: float, delta: float) -> float:
	var obj := clampf(-atan(vel * giro / 9.8) * INCLINA_K, -INCLINA_MAX, INCLINA_MAX) * smoothstep(2.0, 4.5, absf(vel))
	return lerpf(actual, obj, 1.0 - exp(-INCLINA_SUAVE * delta))

## ECHARSE ADELANTE AL ACELERAR (31-10, veredicto del dueño «mejorar»): quien arranca o acelera se echa hacia delante (como un
## velocista al salir) y quien frena en seco, un poco atrás. `acel` en m/s² (+ = gana velocidad). Devuelve rotation.x del cuerpo
## (mira a +Z: + echa la cabeza adelante), suavizado. Topes: 8° adelante, 4° atrás.
const ADELANTE_K := 0.025
const ADELANTE_MAX := 0.14
const ATRAS_MAX := 0.07

static func cabeceo(actual: float, acel: float, delta: float) -> float:
	var obj := clampf(acel * ADELANTE_K, -ATRAS_MAX, ADELANTE_MAX)
	return lerpf(actual, obj, 1.0 - exp(-INCLINA_SUAVE * delta))

## LA CABEZA SIGUE AL JUGADOR: dos de cada tres peatones que pasan a menos de `MIRA_A` m giran la cabeza hacia ti (mismo
## `LookAtModifier3D` que la mirada al balón, con tope de giro menor) y la sueltan al alejarte, con la influencia subiendo y bajando
## en medio segundo para que el cuello no salte. Sin cuerpo propio no hace nada.
const MIRA_A := 8.0
const MIRA_FUERZA := 0.8

static func mirada(v: Dictionary, jugador: Node3D, dist2: float, delta: float) -> void:
	var nodo: Node3D = v["nodo"]
	if not is_instance_valid(nodo) or jugador == null:
		return
	var m: LookAtModifier3D = v.get("mira_mod")
	var k := float(v.get("mira_k", 0.0))
	var cerca := dist2 < MIRA_A * MIRA_A and not v.has("pausa") and int(nodo.get_instance_id()) % 3 != 0
	if m == null:
		if not cerca or not MiradaBalon.poner_en(nodo, jugador):
			return
		var esq := FutbolistaQ.esqueleto_de(nodo)
		m = esq.get_node_or_null("MiradaBalon")
		if m == null:
			return
		m.primary_limit_angle = deg_to_rad(55.0)
		m.secondary_limit_angle = deg_to_rad(20.0)
		m.influence = 0.0
		v["mira_mod"] = m
	if k <= 0.0 and not cerca:
		return
	k = move_toward(k, 1.0 if cerca else 0.0, delta * 2.0)
	v["mira_k"] = k
	m.influence = MIRA_FUERZA * k
	m.active = k > 0.0
