class_name AnimExtra
extends "res://visor/anim_extra_p1.gd"
## (Parte 2 de 2 de `anim_extra.gd`.)

## Pedir el balón: brazo derecho arriba.
static func pedir_balon(esq: Skeleton3D, pre: String) -> Animation:
	var a := AnimQuaternius._nueva(1.2, false)
	_brazos(a, esq, pre, "d", [[0.0, 0, 6, 0], [0.25, 10, 160, 10], [0.9, 10, 155, 10], [1.2, 0, 6, 0]])
	_p(a, esq, "cuello", [[0.0, Vector3.ZERO], [0.3, Vector3(-10, 0, 0)], [1.2, Vector3.ZERO]], pre)
	return a

## Saludar al público: brazo arriba moviendo la mano.
static func saludar_publico(esq: Skeleton3D, pre: String) -> Animation:
	var a := AnimQuaternius._nueva(1.2, true)
	_brazos(a, esq, pre, "d", [[0.0, 10, 150, 20], [0.3, 10, 150, 45], [0.6, 10, 150, 20], [0.9, 10, 150, 45], [1.2, 10, 150, 20]])
	return a

## Pedir calma: manos abajo al frente, subiendo y bajando.
static func pedir_calma(esq: Skeleton3D, pre: String) -> Animation:
	var a := AnimQuaternius._nueva(1.0, true)
	for lado: String in ["i", "d"]:
		_brazos(a, esq, pre, lado, [[0.0, 35, 15, 35], [0.5, 25, 15, 25], [1.0, 35, 15, 35]])
	return a

## Manos a la cabeza: la ocasión que no fue.
static func manos_cabeza(esq: Skeleton3D, pre: String) -> Animation:
	var a := AnimQuaternius._nueva(2.0, false)
	for lado: String in ["i", "d"]:
		_brazos(a, esq, pre, lado, [[0.0, 0, 6, 0], [0.35, 30, 125, 120], [1.6, 30, 122, 120], [2.0, 0, 6, 0]])
	_p(a, esq, "cuello", [[0.0, Vector3.ZERO], [0.4, Vector3(-20, 0, 0)], [1.6, Vector3(-18, 0, 0)], [2.0, Vector3.ZERO]], pre)
	_p(a, esq, "espalda2", [[0.0, Vector3.ZERO], [0.4, Vector3(-10, 0, 0)], [2.0, Vector3.ZERO]], pre)
	return a

## Cabeza gacha, hombros caídos.
static func cabeza_gacha(esq: Skeleton3D, pre: String) -> Animation:
	var a := AnimQuaternius._nueva(2.0, true)
	_p(a, esq, "cuello", [[0.0, Vector3(34, 0, 0)], [1.0, Vector3(36, 6, 0)], [2.0, Vector3(34, 0, 0)]], pre)
	_p(a, esq, "espalda2", [[0.0, Vector3(12, 0, 0)], [2.0, Vector3(12, 0, 0)]], pre)
	for lado: String in ["i", "d"]:
		_brazos(a, esq, pre, lado, [[0.0, 4, 4, 8], [2.0, 4, 4, 8]])
	return a

## Mirar al cielo con los brazos abiertos.
static func mirar_cielo(esq: Skeleton3D, pre: String) -> Animation:
	var a := AnimQuaternius._nueva(2.0, false)
	_p(a, esq, "cuello", [[0.0, Vector3.ZERO], [0.5, Vector3(-38, 0, 0)], [1.6, Vector3(-36, 0, 0)], [2.0, Vector3.ZERO]], pre)
	_p(a, esq, "espalda2", [[0.0, Vector3.ZERO], [0.5, Vector3(-12, 0, 0)], [2.0, Vector3.ZERO]], pre)
	for lado: String in ["i", "d"]:
		_brazos(a, esq, pre, lado, [[0.0, 0, 6, 0], [0.5, 0, 60, 10], [1.6, 0, 58, 10], [2.0, 0, 6, 0]])
	return a

## Señalar adelante: "¡por ahí!".
static func senalar_adelante(esq: Skeleton3D, pre: String) -> Animation:
	var a := AnimQuaternius._nueva(1.4, false)
	_brazos(a, esq, pre, "d", [[0.0, 0, 6, 0], [0.3, 85, 8, 0], [1.1, 85, 8, 0], [1.4, 0, 6, 0]])
	_p(a, esq, "cuello", [[0.0, Vector3.ZERO], [0.3, Vector3(0, -10, 0)], [1.4, Vector3.ZERO]], pre)
	return a

## Señalar al cielo (la dedicatoria).
static func senalar_cielo(esq: Skeleton3D, pre: String) -> Animation:
	var a := AnimQuaternius._nueva(2.0, false)
	for lado: String in ["i", "d"]:
		_brazos(a, esq, pre, lado, [[0.0, 0, 6, 0], [0.4, 15, 165, 0], [1.6, 15, 162, 0], [2.0, 0, 6, 0]])
	_p(a, esq, "cuello", [[0.0, Vector3.ZERO], [0.4, Vector3(-30, 0, 0)], [1.6, Vector3(-28, 0, 0)], [2.0, Vector3.ZERO]], pre)
	return a

## Silbar con los dedos: la mano a la boca (el capitán llamando a alguien).
static func silbar_dedos(esq: Skeleton3D, pre: String) -> Animation:
	var a := AnimQuaternius._nueva(1.2, false)
	_brazos(a, esq, pre, "d", [[0.0, 0, 6, 0], [0.3, 50, 20, 140], [0.9, 50, 20, 140], [1.2, 0, 6, 0]])
	return a

## Su celebración de siempre (sin mirar qué animaciones hay: sirve para la ficha).
static func celebracion_firma(rasgo: String, id_jugador: String) -> String:
	var lista: Array = CELEBRA_POR_RASGO.get(rasgo, CELEBRA_POR_RASGO[""])
	return String(lista[absi(("celebra:" + id_jugador).hash()) % lista.size()])

## La que hace en ESTE gol: la suya dos de cada tres, otra de su carácter si no;
## de visita, el provocador provoca. Solo devuelve animaciones que existen.
static func celebracion(ap: AnimationPlayer, rasgo: String, id_jugador: String, de_visita: bool, rng: RandomNumberGenerator) -> String:
	var lista: Array = CELEBRA_POR_RASGO.get(rasgo, CELEBRA_POR_RASGO[""])
	var elegida := celebracion_firma(rasgo, id_jugador)
	var r := rng.randf()
	if de_visita and CELEBRA_DE_VISITA.has(rasgo) and r < 0.5:
		elegida = String(CELEBRA_DE_VISITA[rasgo])
	elif r > 0.66:
		elegida = String(lista[rng.randi() % lista.size()])
	if ap != null and not ap.has_animation(elegida):
		for n: String in lista:
			if ap.has_animation(n):
				return n
		return "celebrar"
	return elegida
