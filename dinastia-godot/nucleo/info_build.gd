class_name InfoBuild
## QUÉ VERSIÓN DESCARGÓ EL JUGADOR (2-11-2026). El CI escribe `res://datos/build_info.json` justo antes de
## exportar cada versión (herramientas/ajustar_presets.py + acción `exportar`): variante (windows, linux,
## android…), nombre, modo, commit y fecha. En el editor o en un build local sin ese archivo no hay
## nada que mostrar y la insignia no aparece. El icono de color de la versión viaja en
## `res://assets/logo/variante/icono_256.png` (se genera en el CI con herramientas/marca_iconos.py).

const RUTA := "res://datos/build_info.json"
const ICONO := "res://assets/logo/variante/icono_256.png"

## Los datos del build; vacío si no hay archivo o está roto.
static func datos(ruta: String = RUTA) -> Dictionary:
	if not FileAccess.file_exists(ruta):
		return {}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	return d as Dictionary if d is Dictionary else {}

## «Windows · 0.9.0 · a1b2c3d» (con el sufijo si lo hay); vacío si no hay datos.
static func etiqueta(ruta: String = RUTA) -> String:
	var d := datos(ruta)
	if d.is_empty():
		return ""
	var partes: Array = [String(d.get("nombre", d.get("variante", "")))]
	partes.append(String(ProjectSettings.get_setting("application/config/version", "")) + String(d.get("sufijo", "")))
	var c := String(d.get("commit", ""))
	if c != "":
		partes.append(c.substr(0, 7))
	var sin_vacios := PackedStringArray()
	for p: String in partes:
		if p != "":
			sin_vacios.append(p)
	return " · ".join(sin_vacios)

## El icono de color de la versión, o null si el build no lo trae.
static func icono() -> Texture2D:
	return load(ICONO) as Texture2D if ResourceLoader.exists(ICONO) else null
