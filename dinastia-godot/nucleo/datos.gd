extends Node
## Las 212 tablas de datos del juego, cargadas del JSON que exporto el HTML.
##
## Ninguna de estas tablas se ha reescrito a mano. Salieron del juego que ya
## funciona con `herramientas/exportar_datos.js`, que las recorre por nombre y
## las serializa. Transcribir a GDScript los 384 clubes, las ligas de 23 paises
## o los jugadores reales habria sido la forma mas segura de colar una errata
## invisible; asi, si el HTML cambia una tabla, se vuelve a exportar y ya esta.
##
## Se carga una sola vez al arrancar (es un autoload) y se consulta con `tabla()`,
## que avisa en voz alta si se pide algo que no existe en vez de devolver null
## en silencio y reventar tres funciones mas abajo.

const RUTA := "res://datos/tablas.json"

## BASE FICTICIA Y PACK REAL (25-9-2026).
##
## `tablas.json` es la BASE FICTICIA: 384 clubes, ligas, copas y árbitros con
## nombres inventados, sin jugadores reales ni equipaciones reales. Es lo único
## que viaja en una versión publicada.
##
## Lo real vive aparte, en un PACK (`pack_real.json`) que reemplaza tablas
## enteras cuando el jugador lo activa -el mismo modelo que usan los managers
## comerciales sin licencia: el juego sale limpio y la comunidad carga la base
## real por su cuenta-. Se busca en este orden, y gana el primero que exista:
##   1. `user://pack_real.json`      -el que instala el propio jugador-
##   2. `<carpeta del .exe>/pack_real.json`
##   3. `res://datos/pack_real.json` -el del proyecto; las exportaciones lo
##      excluyen en `export_presets.cfg`, así que solo existe en desarrollo-
##
## Formato: `{"formato": 1, "nombre": "...", "tablas": {"DATA_P1": [...], ...}}`.
## Cada tabla del pack sustituye a la de la base con el MISMO nombre y la misma
## forma; lo que el pack no trae se queda como en la base. Lo genera
## `herramientas/base_ficticia.py`.
const RUTAS_PACK := ["user://pack_real.json", "", "res://datos/pack_real.json"]

## El modo por defecto de una partida nueva, guardado en los ajustes del
## jugador (`inicio.gd` lo escribe al cambiar el selector).
const AJUSTE_SECCION := "datos"
const AJUSTE_CLAVE := "base_real"
const AJUSTES_RUTA := "user://ajustes.cfg"

var _tablas: Dictionary = {}
## Las tablas tal cual salen de `tablas.json`, sin pack encima.
var _base: Dictionary = {}
## Las tablas del pack real, o vacío si no hay ningún pack.
var _pack: Dictionary = {}
var _pack_nombre: String = ""
var _pack_ruta: String = ""
var cargado: bool = false
## true si ahora mismo las tablas llevan el pack real encima.
var base_real: bool = false

## Aviso para quien guarde cachés sacadas de las tablas (índices por nombre de
## club, por ejemplo): se emite cada vez que se cambia de base.
signal base_cambiada(real: bool)

func _ready() -> void:
	cargar()
	_cargar_pack()
	usar_base_real(preferencia_base_real())

func cargar() -> bool:
	var datos: Variant = _leer_json(RUTA)
	if not (datos is Dictionary):
		return false
	_base = datos
	_tablas = _base.duplicate()
	cargado = true
	return true

func _leer_json(ruta: String) -> Variant:
	var f := FileAccess.open(ruta, FileAccess.READ)
	if f == null:
		push_error("Datos: no puedo abrir %s (error %d)" % [ruta, FileAccess.get_open_error()])
		return null
	var crudo := f.get_as_text()
	f.close()
	var j := JSON.new()
	var err := j.parse(crudo)
	if err != OK:
		push_error("Datos: JSON invalido en %s, linea %d: %s" % [ruta, j.get_error_line(), j.get_error_message()])
		return null
	return j.data

## Busca el pack real en las tres rutas. No es un error que no haya ninguno:
## es justo el caso de una versión publicada.
func _cargar_pack() -> void:
	_pack = {}
	_pack_nombre = ""
	_pack_ruta = ""
	for ruta: String in RUTAS_PACK:
		if ruta == "":
			ruta = OS.get_executable_path().get_base_dir().path_join("pack_real.json")
		if not FileAccess.file_exists(ruta):
			continue
		var datos: Variant = _leer_json(ruta)
		if not (datos is Dictionary) or not ((datos as Dictionary).get("tablas") is Dictionary):
			push_warning("Datos: %s no tiene el formato de un pack (falta \"tablas\")" % ruta)
			continue
		var tablas: Dictionary = (datos as Dictionary)["tablas"]
		for nombre: String in tablas:
			## Solo se aceptan tablas que ya existen en la base: un pack no
			## puede inventarse tablas nuevas que el código no sabe leer.
			if _base.has(nombre) and typeof(tablas[nombre]) == typeof(_base[nombre]):
				_pack[nombre] = tablas[nombre]
			else:
				push_warning("Datos: el pack %s trae '%s' con otra forma o desconocida; se ignora" % [ruta, nombre])
		_pack_nombre = String((datos as Dictionary).get("nombre", "Base real"))
		_pack_ruta = ruta
		return

## Hay un pack real disponible en esta instalación.
func hay_pack_real() -> bool:
	return not _pack.is_empty()

func nombre_pack() -> String:
	return _pack_nombre

func ruta_pack() -> String:
	return _pack_ruta

## Pone o quita el pack real encima de la base. Sin pack, siempre queda la
## base ficticia aunque se pida la real. Devuelve el modo que quedó activo.
func usar_base_real(activar: bool) -> bool:
	var real := activar and hay_pack_real()
	_tablas = _base.duplicate()
	if real:
		for nombre: String in _pack:
			_tablas[nombre] = _pack[nombre]
	var cambio := real != base_real
	base_real = real
	Reales.invalidar()
	if cambio:
		base_cambiada.emit(real)
	return real

## Lo que eligió el jugador la última vez en el menú. Por defecto, la base
## ficticia: es la que se puede publicar y la que se ve en cualquier versión
## descargada.
func preferencia_base_real() -> bool:
	var c := ConfigFile.new()
	if c.load(AJUSTES_RUTA) != OK:
		return false
	return bool(c.get_value(AJUSTE_SECCION, AJUSTE_CLAVE, false))

func guardar_preferencia_base_real(real: bool) -> void:
	var c := ConfigFile.new()
	c.load(AJUSTES_RUTA)
	c.set_value(AJUSTE_SECCION, AJUSTE_CLAVE, real)
	c.save(AJUSTES_RUTA)

## Devuelve una tabla por nombre. Si no existe, lo dice: un fallo ruidoso es
## mucho mas barato que un diccionario vacio propagandose por el simulador.
func tabla(nombre: String) -> Variant:
	if not _tablas.has(nombre):
		push_error("Datos: no existe la tabla '%s'. Hay %d cargadas." % [nombre, _tablas.size()])
		return null
	return _tablas[nombre]

func tiene(nombre: String) -> bool:
	return _tablas.has(nombre)

func nombres() -> Array:
	var l := _tablas.keys()
	l.sort()
	return l

func cuantas() -> int:
	return _tablas.size()

## --- Atajos calientes -------------------------------------------------------
## El simulador consulta POSD (los pesos de cada demarcacion) para cada jugador
## de cada once en cada minuto de cada partido. Pasar por `tabla()` ahi dentro
## significaba un has() y un acceso a diccionario cientos de miles de veces por
## temporada. Se cachea una vez y se sirve directo.
##
## Es la misma leccion que el HTML pago cara con `plantelDe()`, que recorria los
## once mil jugadores del mundo entero cada vez que alguien pedia una plantilla
## y se comia el 93% del tiempo de ejecucion del juego.

var _posd: Dictionary = {}
var _grupo_de: Dictionary = {}   ## demarcacion -> POR/DEF/MED/DEL
var _lateral_de: Dictionary = {} ## demarcacion -> es un lateral (d==='LAT')
var _banda_de: Dictionary = {}   ## demarcacion -> "D"/"I"/"" (solo tiene sentido en un lateral)

func posd() -> Dictionary:
	if _posd.is_empty() and _tablas.has("POSD"):
		_posd = _tablas["POSD"]
		for dem: String in _posd:
			var entrada: Dictionary = _posd[dem]
			_grupo_de[dem] = String(entrada.get("g", "MED"))
			_lateral_de[dem] = String(entrada.get("d", "")) == "LAT"
			_banda_de[dem] = String(entrada.get("b", ""))
	return _posd

## Grupo (POR/DEF/MED/DEL) de una demarcacion concreta.
func grupo(demarcacion: String) -> String:
	if _grupo_de.is_empty():
		posd()
	return _grupo_de.get(demarcacion, "MED")

## Si la demarcacion es un lateral -"D.d==='LAT'" del HTML-: solo estas notan
## el pie habil del jugador.
func es_lateral(demarcacion: String) -> bool:
	if _lateral_de.is_empty():
		posd()
	return bool(_lateral_de.get(demarcacion, false))

## El lado del campo de una demarcacion, "D" o "I" -"D.b" del HTML-. Vacio si
## la demarcacion no tiene banda (no es un lateral).
func banda(demarcacion: String) -> String:
	if _banda_de.is_empty():
		posd()
	return String(_banda_de.get(demarcacion, ""))
