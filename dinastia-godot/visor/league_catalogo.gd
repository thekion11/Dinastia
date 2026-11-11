class_name LeagueCatalogo
extends RefCounted
## CATÁLOGO ETIQUETADO DE ANIMACIONES DE LOCOMOCIÓN (11-11-2026, fase 4 del motor de League; `docs/04_auditorias/MOTOR_LEAGUE_SOCCER_PLAN.md`).
## Las 59 animaciones de movimiento del original viven en `datos/league_movimiento.json`. Para que otras sesiones puedan SUMAR
## animaciones gratuitas sin tocar código, cualquier archivo `datos/anims_extra/*.json` añade más entradas con las MISMAS
## etiquetas; la elección (`LeagueMovimiento.elegir`) las ve igual que a las del original. Formato en `datos/anims_extra/LEEME.md`.
##
## Etiquetas de cada clip (las que usa la búsqueda):
##   tipo      "arranque" | "frenada" | "giro" | "paso" | "cuerpo" (se deduce de la velocidad de entrada y salida y del giro)
##   entra     velocidad con la que se entra: 0 · 3,5 · 5 · 8 m/s (clase; se aceptan valores sueltos y se cuantizan)
##   sale      velocidad con la que se sale (ídem)
##   ang       dirección de salida respecto a la de entrada, rad, + a la izquierda
##   cuerpo    giro del cuerpo respecto a la marcha al terminar; cuerpo_ini: al empezar
##   pie       con qué pie empieza: "D" · "I" · "" (da igual)
##   largo     duración (s); v_entra / v_sale: velocidad real medida en el clip (m/s); pasos; reposo (0/1)
## Búsqueda general por etiquetas: `buscar(filtro, deseo)`; las de movimiento con todas las reglas del original, en `LeagueMovimiento`.

const CARPETA := "res://datos/anims_extra/"
const BIBLIOTECA_LEAGUE := "res://assets/characters/quaternius/anims_league/league.res"
const OBLIGATORIAS := ["nombre", "entra", "sale", "ang", "largo"]

static var _extras: Array = []
static var _cargado := false
static var _fuentes := {}   ## nombre del clip → {biblioteca, clip}

## Las entradas extra ya normalizadas (con las dos versiones, normal y espejo, si trae el clip espejo).
static func extras() -> Array:
	if not _cargado:
		_cargado = true
		var dir := DirAccess.open(CARPETA)
		if dir != null:
			var archivos := Array(dir.get_files())
			archivos.sort()
			for f: String in archivos:
				if f.ends_with(".json"):
					_sumar_archivo(CARPETA + f)
	return _extras

## Para las pruebas y para quien suma animaciones en tiempo de ejecución. Devuelve los errores (vacío = todo bien).
static func agregar(entradas: Array, biblioteca := BIBLIOTECA_LEAGUE) -> PackedStringArray:
	var errores := PackedStringArray()
	for e: Variant in entradas:
		var r := normalizar(e if e is Dictionary else {})
		if r.has("error"):
			errores.append(String(r["error"]))
			continue
		var base := String((e as Dictionary).get("clip", r["nombre"]))
		_registrar(r, biblioteca, base)
		var esp: String = String((e as Dictionary).get("clip_espejo", ""))
		if esp != "":   ## el espejo lo trae el propio archivo de animaciones (con el mismo nombre + «_espejo»)
			var m := _espejo(r)
			_registrar(m, biblioteca, esp)
	return errores

static func _registrar(r: Dictionary, biblioteca: String, clip: String) -> void:
	extras()
	_fuentes[String(r["nombre"])] = {"biblioteca": biblioteca, "clip": clip}
	_extras.append(r)

static func _sumar_archivo(ruta: String) -> void:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	if not (d is Dictionary) or not (d as Dictionary).get("clips") is Array:
		push_warning("LeagueCatalogo: %s no tiene la lista «clips»" % ruta)
		return
	var bib := String((d as Dictionary).get("biblioteca", BIBLIOTECA_LEAGUE))
	for e: Variant in (d as Dictionary)["clips"]:
		var err := agregar([e], bib)
		for m in err:
			push_warning("LeagueCatalogo (%s): %s" % [ruta, m])

## Completa y valida una entrada. Devuelve {error} si le falta algo o es incoherente.
static func normalizar(e: Dictionary) -> Dictionary:
	for k: String in OBLIGATORIAS:
		if not e.has(k):
			return {"error": "falta la etiqueta «%s» en %s" % [k, str(e.get("nombre", "?"))]}
	var n := String(e["nombre"])
	if not n.begins_with("ext_"):
		return {"error": "el nombre «%s» debe empezar por «ext_» (para no chocar con los del original)" % n}
	var largo := float(e["largo"])
	if largo < 0.05 or largo > 3.0:
		return {"error": "«%s»: la duración %.2f s no es creíble (0,05 a 3 s)" % [n, largo]}
	var pie := String(e.get("pie", ""))
	if pie != "" and pie != "D" and pie != "I":
		return {"error": "«%s»: el pie es D, I o vacío" % n}
	var ang := float(e["ang"])
	if absf(ang) > TAU:
		return {"error": "«%s»: el ángulo va en radianes (%.1f)" % [n, ang]}
	var r := {"nombre": n, "ext": true, "entra": LeagueMovimiento.rango(float(e["entra"])), "sale": LeagueMovimiento.rango(float(e["sale"])),
		"ang": ang, "cuerpo": float(e.get("cuerpo", ang)), "cuerpo_ini": float(e.get("cuerpo_ini", 0.0)),
		"reposo": int(e.get("reposo", 1)), "largo": largo, "pie": pie if pie != "" else "D",
		"pasos": int(e.get("pasos", 1)), "v_entra": float(e.get("v_entra", float(e["entra"]))), "v_sale": float(e.get("v_sale", float(e["sale"])))}
	r["tipo"] = tipo_de(r)
	return r

## El espejo de una entrada: ángulos de signo cambiado y el pie contrario.
static func _espejo(r: Dictionary) -> Dictionary:
	var m := r.duplicate()
	m["nombre"] = String(r["nombre"]) + "_espejo"
	for k: String in ["ang", "cuerpo", "cuerpo_ini"]:
		m[k] = -float(r[k])
	m["pie"] = "I" if String(r["pie"]) == "D" else "D"
	return m

## El tipo que se deduce de la velocidad de entrada y salida y del giro.
static func tipo_de(c: Dictionary) -> String:
	var e := float(c["entra"])
	var s := float(c["sale"])
	if e == LeagueMovimiento.IDLE and s > LeagueMovimiento.IDLE:
		return "arranque"
	if e > LeagueMovimiento.IDLE and s == LeagueMovimiento.IDLE:
		return "frenada"
	if absf(float(c["ang"])) >= 0.6:
		return "giro"
	return "cuerpo" if absf(float(c["cuerpo"])) > 0.2 else "paso"

## ¿De qué biblioteca y con qué nombre se carga el clip? {} si no es una extra.
static func fuente(nombre: String) -> Dictionary:
	extras()
	return _fuentes.get(nombre, {})

## El clip listo para la biblioteca del jugador, con las pistas reapuntadas a `prefijo` (las de otro esqueleto se retargetean
## antes, con `anim_quaternius.gd`; aquí solo se aceptan bibliotecas que ya usan nuestros nombres de hueso).
static func clip(nombre: String, prefijo: String) -> Animation:
	var f := fuente(nombre)
	if f.is_empty():
		return null
	var lib := load(String(f["biblioteca"])) as AnimationLibrary
	var clave := String(f["clip"])
	if lib == null or not lib.has_animation(clave):
		return null
	var a: Animation = lib.get_animation(clave).duplicate(true)
	a.loop_mode = Animation.LOOP_NONE
	for i in a.get_track_count():
		var ruta := str(a.track_get_path(i))
		a.track_set_path(i, NodePath("%s:%s" % [prefijo, ruta.substr(ruta.rfind(":") + 1)]))
	return a

## BÚSQUEDA POR ETIQUETAS. `filtro`: etiqueta → valor exacto (o Array de valores admitidos). `deseo`: etiqueta numérica → valor que
## se quiere; se ordenan por la distancia total (menor = mejor, `ang` y `cuerpo` por la diferencia angular). `entradas`: la lista
## donde buscar (por defecto, todas las de movimiento). Devuelve las entradas ordenadas, la mejor primero.
static func buscar(filtro: Dictionary, deseo := {}, entradas: Array = []) -> Array:
	var lista := entradas if not entradas.is_empty() else LeagueMovimiento.clips()
	var res: Array = []
	for c: Dictionary in lista:
		var ok := true
		for k: String in filtro:
			var v: Variant = filtro[k]
			var tiene: Variant = c.get(k, null)
			if k == "tipo" and tiene == null:
				tiene = tipo_de(c)
			if v is Array:
				ok = tiene in (v as Array)
			else:
				ok = tiene == v
			if not ok:
				break
		if ok:
			res.append(c)
	res.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _distancia(a, deseo) < _distancia(b, deseo))
	return res

static func _distancia(c: Dictionary, deseo: Dictionary) -> float:
	var d := 0.0
	for k: String in deseo:
		var quiere := float(deseo[k])
		var tiene := float(c.get(k, 0.0))
		d += absf(angle_difference(quiere, tiene)) if k == "ang" or k == "cuerpo" or k == "cuerpo_ini" else absf(quiere - tiene)
	return d

## Vuelve al estado de fábrica (las pruebas). También `LeagueMovimiento.reiniciar()`.
static func reiniciar() -> void:
	_extras.clear()
	_fuentes.clear()
	_cargado = false
