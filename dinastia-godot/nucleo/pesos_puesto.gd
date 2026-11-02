class_name PesosPuesto
extends RefCounted
## LA TABLA `POSD` LISTA PARA LEER DEPRISA (30-10-2026, rendimiento). `Jugador.media_en` y
## `Club.once` la consultaban cientos de veces por partido simulado, cada vez abriendo
## diccionarios y convirtiendo números: era más de la mitad del coste de preparar un
## partido. Aquí se guarda, por demarcación, la lista de atributos con sus pesos (en
## el MISMO orden que el diccionario, así la suma sale idéntica bit a bit), su grupo
## y si es de portero. Si `Datos` recarga la tabla (otro diccionario), se rehace.

static var _posd: Variant = null
static var _pesos: Dictionary = {}    ## demarcación → [PackedStringArray, PackedFloat64Array]
static var _grupo: Dictionary = {}    ## demarcación → "POR"/"DEF"/"MED"/"DEL" ("" si no existe)

static func _tabla() -> Dictionary:
	var posd: Variant = Datos.tabla("POSD")
	if not is_same(posd, _posd):
		_posd = posd
		_pesos.clear()
		_grupo.clear()
	return posd if posd is Dictionary else {}

## [claves, pesos] de la demarcación, o [] si la tabla no la tiene.
static func de(demarcacion: String) -> Array:
	var posd := _tabla()
	var e: Variant = _pesos.get(demarcacion)
	if e != null:
		return e
	if not posd.has(demarcacion):
		return []
	var pesos: Dictionary = posd[demarcacion]["p"]
	var ks := PackedStringArray()
	var ws := PackedFloat64Array()
	for k: String in pesos:
		ks.append(k)
		ws.append(float(pesos[k]))
	var r := [ks, ws]
	_pesos[demarcacion] = r
	return r

## El grupo de la demarcación (`POSD[x].g`), "" si no existe.
static func grupo(demarcacion: String) -> String:
	var posd := _tabla()
	var g: Variant = _grupo.get(demarcacion)
	if g != null:
		return g
	var s := String((posd.get(demarcacion, {}) as Dictionary).get("g", ""))
	_grupo[demarcacion] = s
	return s

static func es_portero(demarcacion: String) -> bool:
	return grupo(demarcacion) == "POR"
