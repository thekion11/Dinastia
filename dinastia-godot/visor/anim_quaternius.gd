class_name AnimQuaternius
extends "res://visor/anim_quaternius_p2.gd"
## (Parte 3 de 3 de `anim_quaternius.gd`.)

## La rabia: cabeza atrás mirando al cielo, brazos que caen de golpe y una
## patada al aire.
static func rabia(esq: Skeleton3D, prefijo: String) -> Animation:
	var a := _nueva(1.8, false)
	_pista(a, esq, "espalda2", [[0.0, Vector3.ZERO], [0.35, Vector3(-16, 0, 0)], [0.9, Vector3(10, 0, 0)], [1.8, Vector3.ZERO]], prefijo)
	_pista(a, esq, "cuello", [[0.0, Vector3.ZERO], [0.35, Vector3(-30, 0, 0)], [0.9, Vector3(20, 0, 0)], [1.8, Vector3(6, 0, 0)]], prefijo)
	_pista(a, esq, "brazo_i", [[0.0, Vector3(0, 0, 6)], [0.35, Vector3(-30, 0, 40)], [0.7, Vector3(20, 0, 2)], [1.8, Vector3(0, 0, 6)]], prefijo)
	_pista(a, esq, "brazo_d", [[0.0, Vector3(0, 0, -6)], [0.35, Vector3(-30, 0, -40)], [0.7, Vector3(20, 0, -2)], [1.8, Vector3(0, 0, -6)]], prefijo)
	## La patada al aire: arma la pierna atrás con la rodilla doblada y la
	## suelta adelante casi estirada, el tobillo en punta como al chutar. La
	## pierna de apoyo cede un poco la rodilla para absorber el golpe.
	_pierna_anat(a, esq, "d", [[0.0, 0, RODILLA_REPOSO, 0], [0.8, -15, 75, 20], [1.05, 55, 12, 25], [1.4, 0, RODILLA_REPOSO, 0], [1.8, 0, RODILLA_REPOSO, 0]], prefijo)
	_pierna_apoyada(a, esq, "i", [[0.0, 0.0, 0.0], [0.8, -0.03, 0.0], [1.05, -0.04, 0.02], [1.4, 0.0, 0.0], [1.8, 0.0, 0.0]], prefijo)
	_pista_pos(a, esq, "cadera", [[0.0, Vector3.ZERO], [0.8, Vector3(0, -0.03, 0)], [1.05, Vector3(0, -0.04, 0.02)], [1.4, Vector3.ZERO], [1.8, Vector3.ZERO]], prefijo, true)
	return a

## El árbitro señala la falta: brazo derecho extendido hacia el costado, a la
## altura del hombro, y lo sostiene.
static func senalar_falta(esq: Skeleton3D, prefijo: String) -> Animation:
	var a := _nueva(1.8, false)
	_pista(a, esq, "brazo_d", [[0.0, Vector3(0, 0, -6)], [0.3, Vector3(-6, 0, -80)], [1.5, Vector3(-6, 0, -82)], [1.8, Vector3(0, 0, -6)]], prefijo)
	_pista(a, esq, "brazo_i", [[0.0, Vector3(0, 0, 6)], [1.8, Vector3(0, 0, 6)]], prefijo)
	_pista(a, esq, "cuello", [[0.0, Vector3.ZERO], [0.3, Vector3(0, -30, 0)], [1.5, Vector3(0, -30, 0)], [1.8, Vector3.ZERO]], prefijo)
	return a

## La barrida: la cadera baja casi al suelo, la pierna de delante estirada
## hacia el balón y la de atrás recogida debajo; el tronco se echa atrás y un
## brazo busca el suelo.
static func falta_barrida(esq: Skeleton3D, prefijo: String) -> Animation:
	var a := _nueva(1.2, false)
	_pista_pos(a, esq, "cadera", [[0.0, Vector3.ZERO], [0.3, Vector3(0, -0.56, 0.15)], [0.85, Vector3(0, -0.58, 0.25)], [1.2, Vector3(0, -0.2, 0.2)]], prefijo, true)
	_pista(a, esq, "espalda2", [[0.0, Vector3.ZERO], [0.3, Vector3(-28, 0, 0)], [0.85, Vector3(-24, 0, 0)], [1.2, Vector3(-6, 0, 0)]], prefijo)
	## Pierna de delante estirada hacia el balón; la de atrás, doblada debajo.
	## Las dos por IK siguiendo a la cadera: la de delante busca el balón a ras
	## de césped, la de atrás deja el pie apoyado detrás.
	_pierna_apoyada(a, esq, "d", [[0.0, 0.0, 0.0, 0.0, 0.0], [0.3, -0.56, 0.15, 1.0, 0.07], [0.85, -0.58, 0.25, 1.05, 0.06], [1.2, -0.2, 0.2, 0.45, 0.0]], prefijo)
	_pierna_apoyada(a, esq, "i", [[0.0, 0.0, 0.0, 0.0, 0.0], [0.3, -0.56, 0.15, -0.28, 0.04], [0.85, -0.58, 0.25, -0.18, 0.04], [1.2, -0.2, 0.2, 0.0, 0.0]], prefijo)
	_pista(a, esq, "brazo_i", [[0.0, Vector3(0, 0, 6)], [0.3, Vector3(-40, 0, 30)], [1.2, Vector3(0, 0, 6)]], prefijo)
	_pista(a, esq, "brazo_d", [[0.0, Vector3(0, 0, -6)], [0.3, Vector3(20, 0, -40)], [1.2, Vector3(0, 0, -6)]], prefijo)
	return a

## El dolor de una lesión: agachado, las manos a la rodilla, la cabeza baja.
static func dolor(esq: Skeleton3D, prefijo: String) -> Animation:
	var a := _nueva(3.0, false)
	## Agachado sobre la pierna sana; la lastimada, adelantada y sin cargar
	## peso. La cadera se va atrás para equilibrar el tronco inclinado.
	_pista_pos(a, esq, "cadera", [[0.0, Vector3.ZERO], [0.5, Vector3(0, -0.27, -0.10)], [3.0, Vector3(0, -0.29, -0.10)]], prefijo, true)
	_pierna_apoyada(a, esq, "i", [[0.0, 0.0, 0.0], [0.5, -0.27, -0.10, -0.06], [3.0, -0.29, -0.10, -0.06]], prefijo)
	_pierna_apoyada(a, esq, "d", [[0.0, 0.0, 0.0], [0.5, -0.27, -0.10, 0.20, 0.02], [3.0, -0.29, -0.10, 0.20, 0.02]], prefijo)
	_pista(a, esq, "espalda1", [[0.0, Vector3.ZERO], [0.5, Vector3(34, 0, 0)], [3.0, Vector3(36, 0, 0)]], prefijo)
	_pista(a, esq, "cuello", [[0.0, Vector3.ZERO], [0.5, Vector3(30, 0, 0)], [1.5, Vector3(24, 10, 0)], [3.0, Vector3(30, 0, 0)]], prefijo)
	_pista(a, esq, "brazo_i", [[0.0, Vector3(0, 0, 6)], [0.5, Vector3(52, 0, 10)]], prefijo)
	_pista(a, esq, "brazo_d", [[0.0, Vector3(0, 0, -6)], [0.5, Vector3(52, 0, -10)]], prefijo)
	_pista(a, esq, "antebrazo_i", [[0.0, Vector3.ZERO], [0.5, Vector3(30, 0, 0)]], prefijo)
	_pista(a, esq, "antebrazo_d", [[0.0, Vector3.ZERO], [0.5, Vector3(30, 0, 0)]], prefijo)
	return a

static func _firma(esq: Skeleton3D) -> int:
	var partes := PackedStringArray()
	for i in esq.get_bone_count():
		partes.append(esq.get_bone_name(i) + str(esq.get_bone_rest(i)))
	return hash("|".join(partes))

static func parado(esq: Skeleton3D, prefijo: String) -> Animation:
	var a := _nueva(3.2, true)
	_pista_pos(a, esq, "cadera", [[0.0, Vector3.ZERO], [1.6, Vector3(0, 0.012, 0)], [3.2, Vector3.ZERO]], prefijo)
	_pista(a, esq, "espalda1", [[0.0, Vector3(0, 0, 0)], [1.6, Vector3(-2, 0, 0)], [3.2, Vector3.ZERO]], prefijo)
	_pista(a, esq, "cabeza", [[0.0, Vector3(0, -3, 0)], [1.6, Vector3(0, 3, 0)], [3.2, Vector3(0, -3, 0)]], prefijo)
	_pista(a, esq, "brazo_i", [[0.0, Vector3(0, 0, 4)], [1.6, Vector3(0, 0, 7)], [3.2, Vector3(0, 0, 4)]], prefijo)
	_pista(a, esq, "brazo_d", [[0.0, Vector3(0, 0, -4)], [1.6, Vector3(0, 0, -7)], [3.2, Vector3(0, 0, -4)]], prefijo)
	return a

static func _pierna(a: Animation, esq: Skeleton3D, mus: String, rod: String, pie: String,
		off: float, dur: float, muslo: float, rodilla: float, prefijo: String) -> void:
	var fases := [
		[0.00,  muslo,        rodilla * 0.16,  -14.0],
		[0.25, -muslo * 0.35,  rodilla * 0.10,   4.0],
		[0.50, -muslo * 0.80,  rodilla * 0.30,  22.0],
		[0.75,  muslo * 0.55,  rodilla,         -8.0],
		[1.00,  muslo,         rodilla * 0.16, -14.0],
	]
	var km: Array = []
	var kr: Array = []
	var kp: Array = []
	for fase in fases:
		var t: float = fmod(float(fase[0]) * dur + off, dur)
		km.append([t, Vector3(fase[1], 0, 0)])
		kr.append([t, Vector3(fase[2], 0, 0)])
		kp.append([t, Vector3(fase[3], 0, 0)])
	km.append([dur, km[0][1]])
	kr.append([dur, kr[0][1]])
	kp.append([dur, kp[0][1]])
	_pista(a, esq, mus, km, prefijo)
	_pista(a, esq, rod, kr, prefijo)
	_pista(a, esq, pie, kp, prefijo)

## Ciclo de zancada, mismo diseno de 4 tiempos que `AnimMixamo.correr()`
## (contacto -> apoyo -> impulso -> recogida), recalibrado a los ejes de
## este esqueleto.
static func correr(esq: Skeleton3D, prefijo: String, dur: float, f: float) -> Animation:
	var a := _nueva(dur, true)
	var t1 := dur * 0.25
	var t2 := dur * 0.5
	var t3 := dur * 0.75
	var muslo: float = 42.0 * f
	var rodilla: float = 75.0 * f
	var brazo: float = 38.0 * f

	_pista_pos(a, esq, "cadera", [
		[0.0, Vector3(0, -0.025 * f, 0)], [t1, Vector3(0, 0.03 * f, 0)],
		[t2, Vector3(0, -0.025 * f, 0)], [t3, Vector3(0, 0.03 * f, 0)],
		[dur, Vector3(0, -0.025 * f, 0)]], prefijo)
	_pista(a, esq, "espalda3", [[0.0, Vector3(-4.0 * f, 0, 0)]], prefijo)
	_pista(a, esq, "espalda1", [
		[0.0, Vector3(0, 5.0 * f, 0)], [t2, Vector3(0, -5.0 * f, 0)], [dur, Vector3(0, 5.0 * f, 0)]], prefijo)

	_pierna(a, esq, "muslo_i", "pierna_i", "pie_i", 0.0, dur, muslo, rodilla, prefijo)
	_pierna(a, esq, "muslo_d", "pierna_d", "pie_d", t2, dur, muslo, rodilla, prefijo)

	## Brazos en contrafase de las piernas -brazo_i adelante cuando pierna_i
	## atras, como al correr de verdad-. Eje Z fijo en BRAZO_ABAJO_Z (via
	## `_ajustar`), eje X hace el vaiven adelante-atras.
	_pista(a, esq, "brazo_i", [
		[0.0, Vector3(-brazo, 0, 0)], [t2, Vector3(brazo, 0, 0)], [dur, Vector3(-brazo, 0, 0)]], prefijo)
	_pista(a, esq, "brazo_d", [
		[0.0, Vector3(brazo, 0, 0)], [t2, Vector3(-brazo, 0, 0)], [dur, Vector3(brazo, 0, 0)]], prefijo)
	_pista(a, esq, "antebrazo_i", [
		[0.0, Vector3(0, 0, 0)], [t2, Vector3(0, 0, 0)]], prefijo)
	_pista(a, esq, "antebrazo_d", [
		[0.0, Vector3(0, 0, 0)], [t2, Vector3(0, 0, 0)]], prefijo)
	return a

## Copia del clip con las rotaciones de los dedos acercadas a la pose de
## reposo (mano abierta) en `cuanto` (0 = igual, 1 = abierta del todo).
static func _relajar_dedos(anim: Animation, esq: Skeleton3D, cuanto: float) -> Animation:
	var a := anim.duplicate(true) as Animation
	for t in a.get_track_count():
		if a.track_get_type(t) != Animation.TYPE_ROTATION_3D:
			continue
		var ruta := str(a.track_get_path(t))
		var hueso := ruta.get_slice(":", ruta.get_slice_count(":") - 1)
		if not (hueso.begins_with("index") or hueso.begins_with("middle") or hueso.begins_with("ring") \
				or hueso.begins_with("pinky") or hueso.begins_with("thumb")):
			continue
		var i := esq.find_bone(hueso)
		if i < 0:
			continue
		var reposo := esq.get_bone_rest(i).basis.get_rotation_quaternion()
		for k in a.track_get_key_count(t):
			var q: Quaternion = a.track_get_key_value(t, k)
			a.track_set_key_value(t, k, q.slerp(reposo, cuanto))
	return a

## El reposo del clip abre los brazos como un superhéroe: se acercan al
## cuerpo `ang` radianes (giro local sobre Z del brazo).
static func _brazos_al_cuerpo(anim: Animation, ang: float) -> Animation:
	for t in anim.get_track_count():
		if anim.track_get_type(t) != Animation.TYPE_ROTATION_3D:
			continue
		var ruta := str(anim.track_get_path(t))
		var hueso := ruta.get_slice(":", ruta.get_slice_count(":") - 1)
		if hueso != "upperarm_l" and hueso != "upperarm_r":
			continue
		var giro := Quaternion(Vector3(0, 0, 1), ang if hueso.ends_with("_l") else -ang)
		for k in anim.track_get_key_count(t):
			var q: Quaternion = anim.track_get_key_value(t, k)
			anim.track_set_key_value(t, k, q * giro)
	return anim

static func sentado(esq: Skeleton3D, prefijo: String) -> Animation:
	var a := _nueva(3.4, true)
	_pista_pos(a, esq, "cadera", [[0.0, Vector3.ZERO], [1.7, Vector3(0, 0.01, 0)], [3.4, Vector3.ZERO]], prefijo)
	_pista(a, esq, "espalda1", [[0.0, Vector3(-4, 0, 0)], [1.7, Vector3(-6, 0, 0)], [3.4, Vector3(-4, 0, 0)]], prefijo)
	_pista(a, esq, "cabeza", [[0.0, Vector3(0, -3, 0)], [1.7, Vector3(0, 3, 0)], [3.4, Vector3(0, -3, 0)]], prefijo)
	## Cadera 90° (muslo horizontal sobre el asiento) y rodilla 95° (la
	## pantorrilla cae al piso, el pie algo por detrás de la rodilla), pie
	## plano. CORREGIDO 25-9-2026: antes eran muslo +90 / pierna -100 en ejes
	## crudos, que en este esqueleto es muslo hacia ATRÁS y rodilla doblada al
	## revés -desde la cámara de TV lo tapaba el propio banco-. Ver
	## `_pierna_anat()`.
	for lado: String in ["i", "d"]:
		_pierna_anat(a, esq, lado, [[0.0, 90, 95, 90 - (95 - RODILLA_REPOSO)]], prefijo)
	## Brazos apoyados hacia adelante, sobre las rodillas -antebrazo doblado,
	## no colgando a los costados como de pie-.
	## CORREGIDO 26-9-2026 (plan maestro C2): con 18°/60° las manos quedaban
	## a la altura del muslo y se hundían en él. Más adelante y algo abiertos,
	## las manos caen SOBRE las rodillas.
	_pista(a, esq, "brazo_i", [[0.0, Vector3(34, 0, 12)]], prefijo)
	_pista(a, esq, "brazo_d", [[0.0, Vector3(34, 0, -12)]], prefijo)
	_pista(a, esq, "antebrazo_i", [[0.0, Vector3(48, 0, 0)]], prefijo)
	_pista(a, esq, "antebrazo_d", [[0.0, Vector3(48, 0, 0)]], prefijo)
	return a

## El remate. Mismo diseno de tres tiempos que `AnimMixamo.patear()` -armar,
## soltar, acompanar-, recalibrado a los ejes propios de este esqueleto. Solo
## eje X en todo (pierna de golpeo, pierna de apoyo, los dos brazos de
## contrapeso): es el eje que se confirmo IGUAL de un lado y del otro con la
## sonda, asi que aqui no hace falta pelear con el espejo de Z como en el
## brazo caido de `parado()`/`correr()` -el baseline de Z ya lo pone
## `_ajustar()` solo, esta animacion no le suma nada mas en Z-.
static func patear(esq: Skeleton3D, prefijo: String) -> Animation:
	var a := _nueva(0.85, false)
	_pista(a, esq, "espalda3", [[0.0, Vector3(-6, 0, 0)], [0.32, Vector3(-16, 0, 0)],
		[0.46, Vector3(6, 0, 0)], [0.85, Vector3(-4, 0, 0)]], prefijo)
	# pierna derecha: la que golpea -arma atras, dispara adelante, acompana-
	_pista(a, esq, "muslo_d", [[0.0, Vector3(-10, 0, 0)], [0.32, Vector3(-52, 0, 0)],
		[0.48, Vector3(58, 0, 0)], [0.85, Vector3(6, 0, 0)]], prefijo)
	_pista(a, esq, "pierna_d", [[0.0, Vector3(14, 0, 0)], [0.32, Vector3(92, 0, 0)],
		[0.48, Vector3(6, 0, 0)], [0.85, Vector3(18, 0, 0)]], prefijo)
	_pista(a, esq, "pie_d", [[0.0, Vector3(0, 0, 0)], [0.32, Vector3(24, 0, 0)],
		[0.48, Vector3(-22, 0, 0)], [0.85, Vector3(0, 0, 0)]], prefijo)
	# pierna izquierda: la de apoyo, casi quieta
	_pista(a, esq, "muslo_i", [[0.0, Vector3(6, 0, 0)], [0.48, Vector3(-8, 0, 0)], [0.85, Vector3(0, 0, 0)]], prefijo)
	_pista(a, esq, "pierna_i", [[0.0, Vector3(12, 0, 0)], [0.48, Vector3(26, 0, 0)], [0.85, Vector3(10, 0, 0)]], prefijo)
	# los dos brazos contrapesan el latigazo, solo en X -sin sumar Z, que es
	# donde este esqueleto espeja entre lados-.
	_pista(a, esq, "brazo_i", [[0.0, Vector3(-14, 0, 0)], [0.34, Vector3(-58, 0, 0)],
		[0.5, Vector3(-20, 0, 0)], [0.85, Vector3(-10, 0, 0)]], prefijo)
	_pista(a, esq, "brazo_d", [[0.0, Vector3(10, 0, 0)], [0.34, Vector3(34, 0, 0)],
		[0.5, Vector3(6, 0, 0)], [0.85, Vector3(8, 0, 0)]], prefijo)
	return a

## El festejo de gol: correr con los brazos abiertos y saltar, en bucle -la
## clasica-. Calco de `AnimMixamo.celebrar()`, mismo criterio que `cabezazo()`
## para "espalda" (-> `espalda2`) y para el Z de los brazos (ya venia
## pre-espejado en el original: 96/-96, 128/-128, se copia tal cual). El
## antebrazo del original solo gira 16 grados en Z -un detalle cosmetico
## minusculo, sin verificar con sonda en este esqueleto-, asi que se omite en
## vez de arriesgar un eje sin medir por un movimiento que apenas se nota.
static func celebrar(esq: Skeleton3D, prefijo: String) -> Animation:
	var a := _nueva(1.6, true)
	_pista_pos(a, esq, "cadera", [[0.0, Vector3.ZERO], [0.4, Vector3(0, 0.24, 0)],
		[0.8, Vector3.ZERO], [1.2, Vector3(0, 0.1, 0)], [1.6, Vector3.ZERO]], prefijo)
	_pista(a, esq, "espalda2", [[0.0, Vector3(4, 0, 0)], [0.4, Vector3(-12, 0, 0)], [1.6, Vector3(4, 0, 0)]], prefijo)
	_pista(a, esq, "cabeza", [[0.0, Vector3(-14, 0, 0)], [0.8, Vector3(-18, 8, 0)], [1.6, Vector3(-14, 0, 0)]], prefijo)
	_pista(a, esq, "brazo_i", [[0.0, Vector3(-20, 0, 96)], [0.4, Vector3(-30, 0, 128)],
		[0.8, Vector3(-20, 0, 96)], [1.6, Vector3(-20, 0, 96)]], prefijo)
	_pista(a, esq, "brazo_d", [[0.0, Vector3(-20, 0, -96)], [0.4, Vector3(-30, 0, -128)],
		[0.8, Vector3(-20, 0, -96)], [1.6, Vector3(-20, 0, -96)]], prefijo)
	_pista(a, esq, "muslo_i", [[0.0, Vector3(18, 0, 0)], [0.4, Vector3(46, 0, 0)], [0.8, Vector3(-18, 0, 0)],
		[1.2, Vector3(30, 0, 0)], [1.6, Vector3(18, 0, 0)]], prefijo)
	_pista(a, esq, "muslo_d", [[0.0, Vector3(-18, 0, 0)], [0.4, Vector3(30, 0, 0)], [0.8, Vector3(18, 0, 0)],
		[1.2, Vector3(-14, 0, 0)], [1.6, Vector3(-18, 0, 0)]], prefijo)
	_pista(a, esq, "pierna_i", [[0.0, Vector3(-40, 0, 0)], [0.4, Vector3(-88, 0, 0)], [1.6, Vector3(-40, 0, 0)]], prefijo)
	_pista(a, esq, "pierna_d", [[0.0, Vector3(-30, 0, 0)], [0.8, Vector3(-70, 0, 0)], [1.6, Vector3(-30, 0, 0)]], prefijo)
	return a

## El salto de cabeza. Calco directo de `AnimMixamo.cabezazo()` -mismo diseno,
## mismos numeros donde el hueso equivalente existe- con dos ajustes: "espalda"
## (un solo hueso en el modelo viejo) pasa a `espalda2` (el tramo medio de la
## columna en este esqueleto de 3 tramos), y los brazos se escriben con el
## signo de Z YA MIRADO A MANO por lado -14/-14 y 58/-58, igual que el
## original- en vez de dejarselo a `_ajustar()`: esa funcion solo mueve el
## PISO (la constante `BRAZO_ABAJO_Z`), no espeja los deltas que le manda cada
## animacion, así que cada animacion tiene que mirar sus propios deltas de Z
## igual que ya hacia el fichero Mixamo (confirmado con la sonda: Z sube/baja
## el brazo con el mismo signo en el input pero en direcciones reales
## opuestas entre lados).
static func cabezazo(esq: Skeleton3D, prefijo: String) -> Animation:
	var a := _nueva(1.0, false)
	_pista_pos(a, esq, "cadera", [[0.0, Vector3.ZERO], [0.35, Vector3(0, 0.22, 0)],
		[0.62, Vector3(0, 0.26, 0)], [1.0, Vector3.ZERO]], prefijo)
	_pista(a, esq, "espalda2", [[0.0, Vector3(0, 0, 0)], [0.4, Vector3(22, 0, 0)],
		[0.6, Vector3(-26, 0, 0)], [1.0, Vector3(0, 0, 0)]], prefijo)
	_pista(a, esq, "cuello", [[0.0, Vector3(0, 0, 0)], [0.4, Vector3(16, 0, 0)],
		[0.58, Vector3(-20, 0, 0)], [1.0, Vector3(0, 0, 0)]], prefijo)
	_pista(a, esq, "brazo_i", [[0.0, Vector3(-40, 0, 14)], [0.4, Vector3(-40, 0, 58)], [1.0, Vector3(-40, 0, 14)]], prefijo)
	_pista(a, esq, "brazo_d", [[0.0, Vector3(-40, 0, -14)], [0.4, Vector3(-40, 0, -58)], [1.0, Vector3(-40, 0, -14)]], prefijo)
	## En el aire: una rodilla sube (impulso) y la otra cuelga casi estirada
	## con el pie en punta; al caer, las dos amortiguan.
	_pierna_anat(a, esq, "i", [[0.0, 10, 25, 0], [0.45, 55, 80, 20], [0.8, 15, 30, 5], [1.0, 0, RODILLA_REPOSO, 0]], prefijo)
	_pierna_anat(a, esq, "d", [[0.0, 10, 25, 0], [0.45, 5, 18, 25], [0.8, 12, 30, 5], [1.0, 0, RODILLA_REPOSO, 0]], prefijo)
	return a

static func _construir(esq: Skeleton3D, prefijo: String, acciones_experimentales: bool) -> AnimationLibrary:
	var lib := AnimationLibrary.new()
	var a_mano := {
		"parado": parado(esq, prefijo),
		"caminar": correr(esq, prefijo, 1.05, 0.3),
		"trotar": correr(esq, prefijo, 0.72, 0.55),
		"correr": correr(esq, prefijo, 0.52, 1.0),
	}
	for clave in a_mano:
		var real: Animation = cargar_real(String(CLIP_REAL[clave]), prefijo)
		## Manos relajadas (13-10-2026): los clips llevan el puño cerrado de
		## superhéroe; parado y andando, los dedos van a medio cerrar.
		if real != null:
			real = _relajar_dedos(real, esq, 0.5)
			if clave == "parado":
				real = _brazos_al_cuerpo(real, -0.2)
		lib.add_animation(clave, real if real != null else a_mano[clave])
	## TIPOS DE CAMINATA (14-10-2026): los otros pasos reales del pack, para que
	## el personaje del jugador pueda andar «normal», agachado o a trote.
	for clave: String in CLIP_CAMINATA:
		var extra: Animation = cargar_real(String(CLIP_CAMINATA[clave]), prefijo)
		if extra != null:
			lib.add_animation(clave, _relajar_dedos(extra, esq, 0.5))
	## "sentado" no tiene equivalente en la Universal Animation Library
	## (ninguno de los 43 clips gratis es una pose sentada) -se queda a mano,
	## sin intentar `cargar_real()` primero.
	lib.add_animation("sentado", sentado(esq, prefijo))
	if acciones_experimentales:
		var a_mano_futbol := {
			"patear": patear(esq, prefijo),
			"celebrar": celebrar(esq, prefijo),
		}
		for clave in a_mano_futbol:
			var real: Animation = cargar_futbol_global(CLIP_FUTBOL[clave], esq, prefijo)
			lib.add_animation(clave, real if real != null else a_mano_futbol[clave])
		lib.add_animation("cabezazo", cabezazo(esq, prefijo))
		for clave in CLIP_FUTBOL_NUEVO:
			var real: Animation = cargar_futbol_global(CLIP_FUTBOL_NUEVO[clave], esq, prefijo)
			if real != null:
				lib.add_animation(clave, real)
		for clave: String in CLIP_RECORTES:
			## Los 22 jugadores comparten la ruta al esqueleto, así que el
			## recorte se hace una vez por partida y se reutiliza.
			var cc := "%s|%s" % [clave, prefijo]
			if not _cache_recortes.has(cc):
				var r: Array = CLIP_RECORTES[clave]
				var entera: Animation = cargar_futbol_global(String(r[0]), esq, prefijo)
				var rp := esq.get_bone_rest(esq.find_bone("pelvis")).origin
				_cache_recortes[cc] = recortar(entera, float(r[1]), float(r[2]), bool(r[3]), bool(r[4]), rp) if entera != null else null
			if _cache_recortes[cc] != null:
				lib.add_animation(clave, _cache_recortes[cc])
		lib.add_animation("lamento", lamento(esq, prefijo))
		lib.add_animation("rabia", rabia(esq, prefijo))
		lib.add_animation("senalar_falta", senalar_falta(esq, prefijo))
		lib.add_animation("falta_barrida", falta_barrida(esq, prefijo))
		lib.add_animation("dolor", dolor(esq, prefijo))
		## EL PORTAFOLIO GRANDE (26-9-2026): clips de la UAL, espejos de cada
		## movimiento de fútbol y expresiones a mano.
		AnimExtra.extender(lib, esq, prefijo)
	return lib

static func _en_cache(esq: Skeleton3D, prefijo: String, acciones_experimentales: bool) -> AnimationLibrary:
	var clave := "%s|%s|%d" % [prefijo, acciones_experimentales, _firma(esq)]
	if _bibliotecas.has(clave):
		return _bibliotecas[clave]
	var lib := _construir(esq, prefijo, acciones_experimentales)
	_bibliotecas[clave] = lib
	return lib

static func construir(esq: Skeleton3D, ruta_esqueleto: String = "", acciones_experimentales: bool = false) -> AnimationLibrary:
	var prefijo := ruta_esqueleto if ruta_esqueleto != "" else str(esq.name)
	return _en_cache(esq, prefijo, acciones_experimentales)
