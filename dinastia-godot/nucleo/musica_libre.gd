class_name MusicaLibre
extends RefCounted
## LAS PISTAS DE MÚSICA LIBRE (13-11-2026, orden del dueño: «integrar música libre y con permiso para comercializar»).
## Hasta hoy el juego no traía ni un fichero de música: `Musica` compone sus seis piezas en el momento (y sigue haciéndolo en los partidos,
## porque esas SÍ cambian con lo que pasa). Aquí viven las pistas GRABADAS, que suenan solo donde nada cambia con el juego: los menús, el club
## y el parón invernal. Todas CC0 (dominio público, uso comercial permitido); `res://audio/musica/catalogo.json` guarda de cada una el autor,
## la licencia, la dirección de origen y el SHA-256 del original; `LICENCIA_CC0.txt` explica el permiso. Para quitar una: borrar su .ogg y su fila.
## Solo entran licencias de `LICENCIAS_VALIDAS`: una pista con otra (p. ej. CC-BY, que obliga a citar) no suena hasta que se sumen sus créditos.
## No toca `Azar`: la rotación de pistas la lleva `Musica` con su propio contador.

const RUTA := "res://audio/musica/"
const LICENCIAS_VALIDAS := ["CC0 1.0"]

static var _pistas: Array = []
static var _leido := false

## Todas las pistas del catálogo que se pueden usar (archivo presente y licencia permitida). Se lee una vez.
static func pistas() -> Array:
	if _leido:
		return _pistas
	_leido = true
	_pistas = _filtrar(_leer_catalogo())
	return _pistas

## Las filas del catálogo, tal cual (vacío si falta o está roto).
static func _leer_catalogo() -> Array:
	if not FileAccess.file_exists(RUTA + "catalogo.json"):
		return []
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA + "catalogo.json"))
	if d is Dictionary and (d as Dictionary).get("pistas") is Array:
		return (d as Dictionary)["pistas"]
	return []

## Se queda con las filas completas, de licencia permitida y con el archivo en el proyecto.
static func _filtrar(filas: Array, comprobar_archivo := true) -> Array:
	var sal: Array = []
	for f: Variant in filas:
		if not (f is Dictionary):
			continue
		var d: Dictionary = f
		if str(d.get("id", "")) == "" or str(d.get("archivo", "")) == "" or str(d.get("autor", "")) == "":
			continue
		if not (str(d.get("licencia", "")) in LICENCIAS_VALIDAS) or not (d.get("usos", []) is Array):
			continue
		if comprobar_archivo and not ResourceLoader.exists(RUTA + str(d["archivo"])):
			continue
		sal.append(d)
	return sal

## Las pistas que pueden sonar en una situación libre («oficina», «paron»).
static func para(situacion: String) -> Array:
	return pistas().filter(func(d: Dictionary) -> bool: return situacion in (d["usos"] as Array))

## A qué situación libre corresponde lo que pide la interfaz (`Musica.ambientar`): los momentos de partido no tienen (suena lo compuesto).
static func situacion_libre(situacion: String) -> String:
	match situacion:
		"partido", "final", "celebracion", "grada":
			return ""
		"parón", "paron":
			return "paron"
		_:
			return "oficina"

## La pista n-ésima de una situación (rotando) o {} si no hay.
static func elegir(situacion: String, n: int) -> Dictionary:
	var l := para(situacion)
	return {} if l.is_empty() else l[posmod(n, l.size())]

static func cargar(d: Dictionary) -> AudioStream:
	return load(RUTA + str(d["archivo"])) as AudioStream

## El texto de los créditos para la pantalla de Ajustes: «Título — autor (licencia)».
static func creditos() -> PackedStringArray:
	var sal := PackedStringArray()
	for d: Dictionary in pistas():
		sal.append("%s — %s (%s)" % [d["titulo"], d["autor"], d["licencia"]])
	return sal
