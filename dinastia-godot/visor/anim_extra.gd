class_name AnimExtra
extends "res://visor/anim_extra_p1.gd"
## [Capa 2/2 de `anim_extra.gd`] pedir_balon, saludar_publico, pedir_calma, manos_cabeza, cabeza_gacha, mirar_cielo … (+5)

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

## Clips de la UAL2 (31-10, CC0, `AnimQuaternius.RUTA_UAL2`): solo bajo demanda con `asegurar` (no van en `extender`, que los
## cargaría en los 22 futbolistas aunque nadie los use).
const UAL2 := {
	"brazos_cruzados": "Idle_FoldArms_Loop", "telefono": "Idle_TalkingPhone_Loop", "negar": "Idle_No_Loop", "asentir": "Yes",
	"cargar_caja": "Walk_Carry_Loop", "beber": "Consume", "apoyado_baranda": "Idle_Rail_Loop", "baranda_llama": "Idle_Rail_Call",
	"barrida_inicio": "Slide_Start", "barrida_desliza": "Slide_Loop", "barrida_fin": "Slide_Exit", "saque_mano": "OverhandThrow",
	"choque": "Hit_Knockback", "levantarse_suelo": "LayToIdle", "trepar": "ClimbUp_1m", "abrir_caja": "Chest_Open", "regar": "Farm_Watering",
}

## Carga UN clip de la UAL en el AnimationPlayer de un cuerpo si aún no lo tiene (las
## personas del prólogo, las citas, la familia y los vecinos no pasan por `extender`).
## Devuelve true si el clip existe tras la llamada. (§2.2e P3, 27-10-2026)
static func asegurar(ap: AnimationPlayer, esq: Skeleton3D, clave: String) -> bool:
	if ap == null or not (UAL.has(clave) or UAL2.has(clave)):
		return false
	if ap.has_animation(clave):
		return true
	var lib := ap.get_animation_library("")
	if lib == null:
		return false
	var prefijo := str(ap.get_path_to(esq)) if esq != null else ""
	var nombre_ual := String(UAL[clave] if UAL.has(clave) else UAL2[clave])
	var a: Animation = AnimQuaternius.cargar_real(nombre_ual, prefijo)
	if a == null and nombre_ual.ends_with("_Loop"):
		a = AnimQuaternius.cargar_real(nombre_ual.trim_suffix("_Loop"), prefijo)
	if a == null:
		return false
	## Un clip «…_Loop» se repite aunque en el pack se guarde sin el sufijo (la charla y el baile se quedaban en la última pose).
	a.loop_mode = Animation.LOOP_LINEAR if nombre_ual.ends_with("Loop") else Animation.LOOP_NONE
	lib.add_animation(clave, a)
	return true


## ------------------------------------------------- GESTOS DE LA RUEDA (§2.5)
## (30-10) El DT contesta a la prensa con el gesto de su TONO (`PrologoPasos.TONOS`):
## seguro = manos abiertas, evasivo = mano al cuello, humilde = manos juntas.
const GESTO_TONO := {"seguro": "manos_abiertas", "evasivo": "mano_cuello", "humilde": "manos_juntas"}
const CARA_TONO := {"seguro": "alegre", "evasivo": "neutral", "humilde": "concentrado"}

## Manos abiertas al frente, palmas a la vista y la barbilla arriba.
static func manos_abiertas(esq: Skeleton3D, pre: String) -> Animation:
	var a := AnimQuaternius._nueva(2.0, false)
	for lado: String in ["i", "d"]:
		_brazos(a, esq, pre, lado, [[0.0, 0, 6, 0], [0.4, 48, 22, 45], [1.5, 46, 26, 42], [2.0, 0, 6, 0]])
	_p(a, esq, "cuello", [[0.0, Vector3.ZERO], [0.4, Vector3(-8, 0, 0)], [1.5, Vector3(-8, 0, 0)], [2.0, Vector3.ZERO]], pre)
	return a

## Una mano a la nuca, la otra abajo, la mirada que se escapa de lado.
static func mano_cuello(esq: Skeleton3D, pre: String) -> Animation:
	var a := AnimQuaternius._nueva(2.2, false)
	_brazos(a, esq, pre, "d", [[0.0, 0, 6, 0], [0.45, 22, 118, 132], [1.7, 22, 116, 134], [2.2, 0, 6, 0]])
	_brazos(a, esq, pre, "i", [[0.0, 4, 6, 8], [2.2, 4, 6, 8]])
	_p(a, esq, "cuello", [[0.0, Vector3.ZERO], [0.5, Vector3(14, -16, 0)], [1.7, Vector3(12, -14, 0)], [2.2, Vector3.ZERO]], pre)
	return a

## Las manos juntas delante del pecho y la cabeza un poco baja.
static func manos_juntas(esq: Skeleton3D, pre: String) -> Animation:
	var a := AnimQuaternius._nueva(2.0, false)
	for lado: String in ["i", "d"]:
		_brazos(a, esq, pre, lado, [[0.0, 0, 6, 0], [0.4, 30, -20, 62], [1.5, 30, -20, 64], [2.0, 0, 6, 0]])
	_p(a, esq, "cuello", [[0.0, Vector3.ZERO], [0.4, Vector3(10, 0, 0)], [1.5, Vector3(10, 0, 0)], [2.0, Vector3.ZERO]], pre)
	return a

## Pone en el reproductor el gesto del tono (una vez) y devuelve su nombre ("" si no hay tono).
static func asegurar_gesto_tono(ap: AnimationPlayer, esq: Skeleton3D, tono: String) -> String:
	var g := String(GESTO_TONO.get(tono, ""))
	if g == "" or ap == null or esq == null:
		return ""
	if not ap.has_animation(g):
		var lib := ap.get_animation_library("")
		if lib == null:
			return ""
		var pre := str(ap.get_path_to(esq))
		var a: Animation = AnimExtra.new().call(g, esq, pre)
		_completar(a, esq, pre)
		lib.add_animation(g, a)
	return g

## Une trozos de clips de la UAL/UAL2 en uno solo `clave` (31-10, la barrida de verdad: entrar + deslizar + levantarse).
## `partes` = [[clave_ual, desde_s, hasta_s], …] (hasta < 0 = hasta el final). Las pistas se casan por ruta; entre trozos
## no hay mezcla (los clips de la UAL2 empiezan donde acaba el anterior). Devuelve true si quedó en la librería.
static func unir(ap: AnimationPlayer, esq: Skeleton3D, clave: String, partes: Array) -> bool:
	if ap == null or ap.has_animation(clave):
		return ap != null
	var lib := ap.get_animation_library("")
	if lib == null:
		return false
	var sal := Animation.new()
	var t0 := 0.0
	for pt: Array in partes:
		if not asegurar(ap, esq, String(pt[0])):
			return false
		var a := ap.get_animation(String(pt[0]))
		var desde := float(pt[1])
		var hasta := a.length if float(pt[2]) < 0.0 else minf(float(pt[2]), a.length)
		for i in a.get_track_count():
			var ruta := a.track_get_path(i)
			var tipo := a.track_get_type(i)
			var j := sal.find_track(ruta, tipo)
			if j < 0:
				j = sal.add_track(tipo)
				sal.track_set_path(j, ruta)
				sal.track_set_interpolation_type(j, a.track_get_interpolation_type(i))
			for k in a.track_get_key_count(i):
				var tk := a.track_get_key_time(i, k)
				if tk >= desde - 0.0001 and tk <= hasta + 0.0001:
					sal.track_insert_key(j, t0 + tk - desde, a.track_get_key_value(i, k))
		t0 += hasta - desde
	sal.length = t0
	sal.loop_mode = Animation.LOOP_NONE
	lib.add_animation(clave, sal)
	return true

## La barrida con los clips de la UAL2: arranca, se desliza medio segundo y se levanta (~1,8 s).
const BARRIDA_REAL := [["barrida_inicio", 0.0, -1.0], ["barrida_desliza", 0.0, 0.5], ["barrida_fin", 0.0, -1.0]]
