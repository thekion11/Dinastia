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

var _tablas: Dictionary = {}
var cargado: bool = false

func _ready() -> void:
	cargar()

func cargar() -> bool:
	var f := FileAccess.open(RUTA, FileAccess.READ)
	if f == null:
		push_error("Datos: no puedo abrir %s (error %d)" % [RUTA, FileAccess.get_open_error()])
		return false
	var crudo := f.get_as_text()
	f.close()
	var j := JSON.new()
	var err := j.parse(crudo)
	if err != OK:
		push_error("Datos: JSON invalido en la linea %d: %s" % [j.get_error_line(), j.get_error_message()])
		return false
	_tablas = j.data
	cargado = true
	return true

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
