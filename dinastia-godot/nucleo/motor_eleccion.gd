class_name MotorEleccion
extends RefCounted
## QUÉ MOTOR DEL PARTIDO SE JUEGA, A CIEGAS (11-11-2026, encargo del dueño; sesión 11, `docs/04_auditorias/comparar_tres_motores_2026-11-11.md`).
## Tres motores: «siempre» (el nuestro, `MotorJugable`), «league» (`MotorLeague`) y «combinado» (`MotorCombinado`: League con piezas
## configurables). En Ajustes el dueño elige «Por defecto», «A», «B» o «C» SIN saber cuál es cuál: el reparto de letras se baraja
## una vez, se guarda en `user://motor_ciego.json` y solo se revela si él lo pide. Al acabar el partido vota de 1 a 5 («¿cuánto te
## divirtió?») y el voto se guarda con el motor REAL detrás.
## Es una clase LIGERA (datos y archivo, sin nombrar ninguna clase del partido): el menú puede usarla (regla de la memoria del menú).
## POR DEFECTO = el motor de siempre (selección vacía): el juego no cambia mientras el dueño no elija una letra.
##   MOTOR_PARTIDO=siempre|league|combinado fuerza el motor (pruebas y sondas; gana a la selección guardada).

## Cuatro motores a ciegas (A-D, decisión del líder 11-11): el nuestro, League, C1 (League + nuestra decisión con balón) y C4 (C1 + nuestra colocación sin balón
## y nuestra locomoción, con la caché de 0,1 s). C2 y C3 solo viven en el comparador (`TODOS`, `MotorCombinado.VARIANTES`), no en Ajustes.
const MOTORES: Array[String] = ["siempre", "league", "combinado", "combinado_c4"]
const LETRAS: Array[String] = ["A", "B", "C", "D"]
const TODOS: Array[String] = ["siempre", "league", "combinado", "combinado_c2", "combinado_c3", "combinado_c4"]   ## los que sabe crear la fábrica
const NOMBRES := {"siempre": "El nuestro (MotorJugable)", "league": "League-Soccer (MotorLeague)", "combinado": "Combinado C1 (MotorCombinado)",
	"combinado_c2": "Combinado C2 (MotorCombinado)", "combinado_c3": "Combinado C3 (MotorCombinado)", "combinado_c4": "Combinado C4 (MotorCombinado)"}

static var ruta := "user://motor_ciego.json"   ## (las pruebas lo cambian para no pisar el guardado del jugador)
static var _datos: Dictionary = {}
static var _cargado := false

static func _vacio() -> Dictionary:
	return {"orden": [], "seleccion": "", "revelado": false, "votos": []}

static func cargar(forzar := false) -> Dictionary:
	if _cargado and not forzar:
		return _datos
	_datos = _vacio()
	_cargado = true
	if FileAccess.file_exists(ruta):
		var f := FileAccess.open(ruta, FileAccess.READ)
		if f != null:
			var j: Variant = JSON.parse_string(f.get_as_text())
			if j is Dictionary:
				for k: String in _datos:
					if (j as Dictionary).has(k):
						_datos[k] = (j as Dictionary)[k]
	if not _orden_valido(_datos["orden"]):
		_datos["orden"] = []
	if not LETRAS.has(String(_datos["seleccion"])):
		_datos["seleccion"] = ""
	return _datos

static func guardar() -> void:
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(_datos, " "))

## Para las pruebas: olvida lo cargado (y, si se pide, también el archivo).
static func reiniciar(borrar_archivo := false) -> void:
	_cargado = false
	_datos = {}
	if borrar_archivo and FileAccess.file_exists(ruta):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))

static func _orden_valido(o: Variant) -> bool:
	if not o is Array or (o as Array).size() != MOTORES.size():
		return false
	for m: String in MOTORES:
		if not (o as Array).has(m):
			return false
	return true

## Baraja el reparto de letras (A, B, C ↔ motores). Con `semilla` ≥ 0 es reproducible (pruebas); si no, al azar.
static func barajar(semilla := -1) -> void:
	var d := cargar()
	var rng := RandomNumberGenerator.new()
	if semilla >= 0:
		rng.seed = semilla
	else:
		rng.randomize()
	var o: Array = MOTORES.duplicate()
	for i in range(o.size() - 1, 0, -1):   ## Fisher-Yates
		var j := rng.randi_range(0, i)
		var x: Variant = o[i]
		o[i] = o[j]
		o[j] = x
	d["orden"] = o
	guardar()

## El reparto actual (se baraja la primera vez que hace falta).
static func orden() -> Array:
	var d := cargar()
	if (d["orden"] as Array).is_empty():
		barajar()
	return d["orden"]

static func seleccion() -> String:   ## "" (por defecto), "A", "B" o "C"
	return String(cargar()["seleccion"])

static func elegir(letra: String) -> void:
	var d := cargar()
	d["seleccion"] = letra if LETRAS.has(letra) else ""
	if letra != "":
		orden()
	guardar()

static func revelado() -> bool:
	return bool(cargar()["revelado"])

static func revelar() -> void:
	orden()
	cargar()["revelado"] = true
	guardar()

static func ocultar() -> void:
	cargar()["revelado"] = false
	guardar()

## El motor REAL que toca jugar: la variable de entorno, si no la letra elegida, si no el de siempre.
static func motor_activo() -> String:
	var env := OS.get_environment("MOTOR_PARTIDO")
	if TODOS.has(env):
		return env
	var s := seleccion()
	if s == "":
		return "siempre"
	return String(orden()[LETRAS.find(s)])

static func motor_de_letra(letra: String) -> String:
	return String(orden()[LETRAS.find(letra)]) if LETRAS.has(letra) else "siempre"

static func letra_de(motor: String) -> String:
	return LETRAS[orden().find(motor)] if MOTORES.has(motor) else ""

## ¿Se está probando a ciegas (hay letra elegida y no hay motor forzado por entorno)? Solo entonces se pide el voto.
static func a_ciegas() -> bool:
	return seleccion() != "" and not TODOS.has(OS.get_environment("MOTOR_PARTIDO"))

# ------------------------------------------------------------------ votos

## Guarda un voto (1-5) con el motor real detrás y datos del partido (para cruzarlo con las cifras de diversión).
static func votar(puntos: int, motor: String, extra := {}) -> void:
	var d := cargar()
	var v := {"motor": motor, "puntos": clampi(puntos, 1, 5), "fecha": Time.get_datetime_string_from_system()}
	for k: String in extra:
		v[k] = extra[k]
	(d["votos"] as Array).append(v)
	guardar()

## Por motor: {"votos": n, "media": x}.
static func resumen_votos() -> Dictionary:
	var r := {}
	for m: String in MOTORES:
		r[m] = {"votos": 0, "media": 0.0}
	var suma := {}
	for v: Variant in cargar()["votos"]:
		if v is Dictionary and r.has(String((v as Dictionary).get("motor", ""))):
			var m := String((v as Dictionary)["motor"])
			(r[m] as Dictionary)["votos"] = int((r[m] as Dictionary)["votos"]) + 1
			suma[m] = float(suma.get(m, 0.0)) + float((v as Dictionary).get("puntos", 0))
	for m: String in suma:
		(r[m] as Dictionary)["media"] = snappedf(float(suma[m]) / float((r[m] as Dictionary)["votos"]), 0.01)
	return r
