class_name TrofeosReales
extends RefCounted
## QUÉ COPA ES CADA TÍTULO (orden 15 e, 27-10-2026). Un título del juego es un texto («Liga», «Copa Chile», «Copa Libertadores»…) y su copa, una
## receta de `datos/trofeos_modelos.json` (se arma con `TrofeoModelo`). El nombre se busca en las tablas del juego (liga de cada país, `COPA_NOM`,
## `CONFED`), así sirve igual con la base real que con la ficticia; la receta, en cambio, no lleva ningún nombre.
const RUTA := "res://datos/trofeos_modelos.json"
static var _recetas: Dictionary = {}

static func _cargar() -> void:
	if not _recetas.is_empty() or not FileAccess.file_exists(RUTA):
		return
	var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA))
	if j is Dictionary:
		_recetas = (j as Dictionary).get("recetas", {})

static func ids() -> Array:
	_cargar()
	return _recetas.keys()

static func receta(id: String) -> Dictionary:
	_cargar()
	return _recetas.get(id, _recetas.get("generico", {}))

## El id de receta de un título. `pais` es el del club (para «Liga» a secas). "generico" si no se reconoce.
static func id_de(titulo: String, pais: String) -> String:
	var limpio := Nombres.limpiar(titulo)
	if limpio == "Mundial de Clubes":
		return "mundial"
	if limpio == "Liga" and pais != "":
		return "liga:" + pais
	var ligas: Dictionary = Datos.tabla("PAISES_LIGAS")
	for p: String in ligas:
		if Nombres.limpiar(String((ligas[p] as Dictionary).get("liga", ""))) == limpio:
			return "liga:" + p
	var copas: Dictionary = Datos.tabla("COPA_NOM")
	for p: String in copas:
		if Nombres.limpiar(String(copas[p])) == limpio:
			return "copa:" + p
	var conf: Dictionary = Datos.tabla("CONFED")
	for k: String in conf:
		if Nombres.limpiar(String((conf[k] as Dictionary).get("n", ""))) == limpio:
			return "conf:" + k
	return "generico"

static func para_titulo(titulo: String, pais: String) -> Dictionary:
	return receta(id_de(titulo, pais))
