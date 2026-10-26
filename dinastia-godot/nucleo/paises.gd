class_name Paises
extends RefCounted
## LOS NOMBRES DE TODOS LOS PAÍSES DEL JUEGO (26-10-2026, fila 26 de la propuesta
## s4). `datos/paises.json` trae los 87 países que el juego conoce por su bandera
## con su nombre en los 9 idiomas (Unicode CLDR, Unicode License V3; Inglaterra,
## Escocia y Gales a mano), generado por `herramientas/paises_cldr.py`. Las
## traducciones van también en `idiomas_extra.json` (clave: el nombre en castellano),
## así que `Idiomas.t` las encuentra igual que cualquier texto.
##   Paises.nombre("CIV") -> "Costa de Marfil" (o su traducción)

const RUTA := "res://datos/paises.json"
static var _tabla: Dictionary = {}

static func tabla() -> Dictionary:
	if _tabla.is_empty() and FileAccess.file_exists(RUTA):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA))
		if d is Dictionary:
			_tabla = (d as Dictionary).get("paises", {})
	return _tabla

static func conocido(codigo: String) -> bool:
	return tabla().has(codigo)

## El nombre en castellano (la clave de traducción), o el código si no se conoce.
static func nombre_es(codigo: String) -> String:
	return String((tabla().get(codigo, {}) as Dictionary).get("es", codigo))

## El nombre en el idioma del juego.
static func nombre(codigo: String) -> String:
	return Idiomas.t(nombre_es(codigo))

## ISO 3166-1 alfa-2 (o subcódigo británico), el del archivo de la bandera.
static func iso(codigo: String) -> String:
	return String((tabla().get(codigo, {}) as Dictionary).get("iso", ""))
