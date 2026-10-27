class_name Creditos
extends RefCounted
## CRÉDITOS Y LICENCIAS DENTRO DEL JUEGO (M-309, 20-10-2026). La referencia
## completa (con lo que se excluye de cada versión) es `LICENCIAS.md`, que no
## viaja en las exportaciones (*.md): esto es lo que el jugador ve en Ajustes →
## Partida. Nombres propios y licencias no se traducen; solo los títulos.
## [qué, quién, licencia]
const LISTA := [
	["Godot Engine 4", "Juan Linietsky, Ariel Manzur y colaboradores (godotengine.org)", "MIT"],
	["Universal Base Characters, Universal Animation Library, Modular Character Outfits, muebles", "Quaternius (quaternius.com)", "CC0 1.0"],
	["Animated Characters, City Kit, Car Kit, City Kit Roads, Furniture Kit, Modular Buildings, Building Kit, Train Kit, Coaster Kit, Mini Market, Food Kit, Mini Arcade, Input Prompts", "Kenney (kenney.nl)", "CC0 1.0"],
	["Free mocap pack 05: Soccer", "Anderson Rohr", "uso libre según su autor"],
	["Face Mesh / Face Landmarker", "Copyright The MediaPipe Authors", "Apache License 2.0"],
	["Texturas de la Tierra (globo)", "NASA Blue Marble / Black Marble", "dominio público"],
	["Fronteras del globo", "Natural Earth (naturalearthdata.com)", "dominio público"],
	["City Builder Bits", "Kay Lousberg (kaylousberg.com)", "CC0 1.0"],
	["Animaciones de medio cuerpo (Mesh2Motion)", "Scott Petrovic y colaboradores (mesh2motion)", "CC0 1.0"],
	["Banderas (flag-icons)", "Panayiotis Lipiridis y colaboradores", "MIT"],
	["Antialiased Line2D, Debug Menu", "Hugo Locurcio y colaboradores", "MIT"],
	["Inter, Barlow Condensed, Bebas Neue, Cinzel, Gelasio, Noto Sans Symbols, Noto Emoji, Noto Sans JP, Noto Sans Math, Noto Sans Mono", "sus autores (fuentes de Google Fonts)", "SIL Open Font License 1.1"],
	["Sonidos de interfaz", "Kenney (kenney.nl) y VCSL, Versilian Community Sample Library (Sam Gossner)", "CC0 1.0"],
	["Música y 205 efectos de sonido del partido", "sintetizados por el propio juego", "—"],
]
## M-425 (27-10-2026): los créditos de las fotos de futbolistas reales. Solo existen en la versión con caras
## reales (el archivo no viaja en las públicas, ver `export_presets.cfg`).
const FOTOS := "res://datos/creditos_fotos.txt"

## Las líneas de cada foto («Nombre: foto de Autor, licencia, Wikidata Q…»), o vacío sin fotos reales.
static func fotos() -> PackedStringArray:
	if not FileAccess.file_exists(FOTOS):
		return PackedStringArray()
	var r := PackedStringArray()
	for l: String in FileAccess.get_file_as_string(FOTOS).split("\n"):
		if l.contains(": foto de "):
			r.append(l.strip_edges())
	return r

## Las líneas, ya montadas.
static func lineas() -> Array[String]:
	var l: Array[String] = []
	for c: Array in LISTA:
		l.append("%s — %s · %s" % [c[0], c[1], c[2]])
	return l
