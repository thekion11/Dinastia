class_name AparienciaPersonal
extends RefCounted
## LA APARIENCIA PROPIA DE CADA PERSONA DEL CLUB (11-11, sesión 12; meta del plan «AVATARES»).
##
## Cuerpo técnico, directiva, médicos, utilero, prensa, cocina… cada puesto de cada club tiene una apariencia
## PREDETERMINADA que:
##  · es DETERMINISTA por club y puesto (mismo club → mismas caras, siempre; otro club → otras),
##  · NO SE REPITE entre las personas de un mismo club (firma = cuerpo + corte + color de pelo + piel + ojos),
##  · el JUGADOR NO PUEDE ELEGIRLA para su personaje: el personal usa colores de pelo RESERVADOS que el editor no
##    ofrece (`COLORES_PELO_PERSONAL`, distintos de `PersonajeDT.COLORES_PELO`) y `PersonajeDT.aspecto()` los
##    cambia por el castaño oscuro si un personaje de jugador los trae (p. ej. una partida editada a mano).
## El reparto de los puestos al azar no cambia el resto del juego: solo lo usa `PersonalEstadio`.

const COLORES_PELO_PERSONAL := ["3b2a1e", "6b3a1f", "8c5a2b", "c9a25c", "7d7d7a", "1b1b1d", "a8431c", "d9d2c2"]
const MAX_INTENTOS := 400

## ¿Es un color de pelo reservado al personal?
static func es_reservado(color_pelo: String) -> bool:
	return color_pelo.trim_prefix("#").to_lower() in COLORES_PELO_PERSONAL

## Aspecto de un PERSONAJE DE JUGADOR (lo llama `PersonajeDT.aspecto`): una partida vieja con un modelo base quitado
## (fantasía, anime…) vuelve al atleta, y los colores de pelo del personal no valen para el jugador.
static func sanear_de_jugador(a: Dictionary) -> Dictionary:
	if not FutbolistaQ.modelo_valido(String(a.get("modelo", ""))):
		a["modelo"] = ""
	if not bool(a.get("personal", false)) and es_reservado(String(a.get("color_pelo", ""))):
		a["color_pelo"] = "2a1c12"
	return a

## Lo que distingue a una persona de otra a simple vista.
static func firma(a: Dictionary) -> String:
	return "%s|%s|%s|%s|%s" % [a.get("cuerpo", ""), a.get("pelo", ""), a.get("color_pelo", ""), a.get("piel", ""), a.get("ojos", "")]

## Aspectos de TODO el personal de un club: `claves` en orden fijo (el de `PersonalEstadio.PUESTOS`) y
## `mujeres` {clave: bool} (el cuerpo sigue al nombre). Devuelve {clave: aspecto}.
static func generar(club_id: String, claves: Array, mujeres: Dictionary) -> Dictionary:
	var salida := {}
	var usadas := {}
	for clave: String in claves:
		var mujer := bool(mujeres.get(clave, false))
		var a := {}
		for intento in MAX_INTENTOS:
			a = _candidato(club_id, clave, intento, mujer)
			if not usadas.has(firma(a)):
				break
		usadas[firma(a)] = clave
		salida[clave] = a
	return salida

static func de(club_id: String, claves: Array, clave: String, mujer: bool) -> Dictionary:
	var mujeres := {}
	for c: String in claves:
		mujeres[c] = mujer if c == clave else false
	return (generar(club_id, claves, mujeres) as Dictionary).get(clave, {})

static func _candidato(club_id: String, clave: String, intento: int, mujer: bool) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s|%s|%d" % [club_id, clave, intento])
	var a: Dictionary = PersonajeDT.aleatorio(rng)
	if (String(a["cuerpo"]) == "female") != mujer:
		a["cuerpo"] = "female" if mujer else "male"
		a["altura"] = clampf(float(a["altura"]), 1.6, 1.74) if mujer else maxf(float(a["altura"]), 1.68)
	a["barba"] = bool(a["barba"]) and not mujer
	if mujer and String(a["pelo"]) in ["calvo", "rapado", "fade", "samurai"]:
		a["pelo"] = "melena"
	a["color_pelo"] = COLORES_PELO_PERSONAL[rng.randi() % COLORES_PELO_PERSONAL.size()]
	a["personal"] = true
	return a
