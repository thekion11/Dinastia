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
	["Música y 205 efectos de sonido", "sintetizados por el propio juego", "—"],
]

## Las líneas, ya montadas.
static func lineas() -> Array[String]:
	var l: Array[String] = []
	for c: Array in LISTA:
		l.append("%s — %s · %s" % [c[0], c[1], c[2]])
	return l
