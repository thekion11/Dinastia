class_name BibliotecaCaras
extends RefCounted
## LA BIBLIOTECA MODULAR DE CARAS Y PELOS (5-10-2026). Pedido del usuario:
## «guarda los pelos y las caras que estás creando para que los personajes sean
## modulares (como el personaje que crea el jugador) y tener más variantes».
##
## Las piezas salen de `herramientas/biblioteca_caras.py`:
##   - CARAS (`datos/biblioteca_caras.json`): cada una mezcla 4 jugadores reales
##     del mismo tono (forma y textura promediadas): una persona NUEVA, no la
##     cara de nadie. 12 por tono, 6 tonos.
##   - PELOS (`datos/biblioteca_pelos.json`): cortes medidos en las fotos (forma
##     y nacimiento, sin color): rapado, degradado, tupé, normal, afro, melena...
## Las usan los jugadores ficticios (por su id: siempre la misma) y el creador
## de personaje (que deja elegir una a una).

const CARAS := "res://datos/biblioteca_caras.json"
const PELOS := "res://datos/biblioteca_pelos.json"
static var _caras: Dictionary = {}
static var _pelos: Dictionary = {}
static var _listo := false

static func _cargar() -> void:
	if _listo:
		return
	_listo = true
	for par: Array in [[CARAS, "_caras"], [PELOS, "_pelos"]]:
		if FileAccess.file_exists(String(par[0])):
			var j := JSON.new()
			if j.parse(FileAccess.get_file_as_string(String(par[0]))) == OK and j.data is Dictionary:
				if par[1] == "_caras":
					_caras = j.data
				else:
					_pelos = j.data

static func hay() -> bool:
	_cargar()
	return not _caras.is_empty()

static func caras() -> Array:
	_cargar()
	var k := _caras.keys()
	k.sort()
	return k

static func pelos() -> Array:
	_cargar()
	var k := _pelos.keys()
	k.sort()
	return k

static func entrada_cara(clave: String) -> Dictionary:
	_cargar()
	var e: Variant = _caras.get(clave)
	return e if e is Dictionary else {}

static func nombre_pelo(clave: String) -> String:
	_cargar()
	var e: Variant = _pelos.get(clave)
	return String((e as Dictionary).get("corte", "?")) if e is Dictionary else "?"

## El corte `clave` con un color de pelo (lo que espera `PeloCapas`).
static func pelo(clave: String, color: Color) -> Dictionary:
	_cargar()
	var e: Variant = _pelos.get(clave)
	if not (e is Dictionary):
		return {}
	var h := (e as Dictionary).duplicate(true)
	h["c"] = "#" + color.to_html(false)
	h["r"] = "#" + color.darkened(0.35).to_html(false)
	return h

## Las caras del tono de piel más parecido a `piel` (ordenadas).
static func del_tono(piel: Color) -> Array:
	_cargar()
	var l := piel.get_luminance() * 255.0
	## Tonos de la herramienta (claridad de la piel), de claro a oscuro.
	var tono := 0 if l >= 175 else (1 if l >= 150 else (2 if l >= 125 else (3 if l >= 100 else (4 if l >= 80 else 5))))
	var lista: Array = []
	for k: String in caras():
		if int((_caras[k] as Dictionary).get("tono", -1)) == tono:
			lista.append(k)
	return lista if not lista.is_empty() else caras()

## La cara número `i` del tono de `piel` ("" si no hay): el creador guarda el
## número, así sigue valiendo si después se cambia el tono de piel.
static func cara_de_tono(piel: Color, i: int) -> String:
	var lista := del_tono(piel)
	return "" if lista.is_empty() or i < 0 else String(lista[i % lista.size()])

## Cara y corte para un personaje, siempre los mismos para la misma semilla. La
## cara, del tono de piel más parecido a `piel`.
static func para(semilla: String, piel: Color, color_pelo: Color) -> Dictionary:
	_cargar()
	if _caras.is_empty():
		return {}
	var del := del_tono(piel)
	var h := absi(hash(semilla))
	var p := pelos()
	return {"cara": String(del[h % del.size()]),
		"pelo": String(p[(h / 7) % p.size()]) if not p.is_empty() else "",
		"color_pelo": "#" + color_pelo.to_html(false)}
