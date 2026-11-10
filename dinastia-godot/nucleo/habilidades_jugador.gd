class_name HabilidadesJugador
extends RefCounted
## LAS HABILIDADES INDIVIDUALES CON ESTRELLAS (orden del dueño, 9-11; hecho el 10-11; idea de la «Información del jugador» del PES 2020, con nombres
## y reglas PROPIAS). Cada habilidad sale de los atributos del jugador (rit/tir/pas/reg/def/fis o, si es portero, div/par/saq/ref/vel/pos), de su
## demarcación (solo las que tienen sentido en su puesto), de su rasgo y, en «Liderazgo», de la capitanía y la edad. No se guarda nada: es una
## lectura determinista (mismo jugador = mismas estrellas), así que vale para partidas viejas sin migrar. 0-3 estrellas: solo se enseñan las de 1+.
const UMBRALES := [74.0, 81.0, 88.0]   ## puntuación mínima para 1, 2 y 3 estrellas
const MAXIMO := 6                      ## cuántas se enseñan como mucho (las mejores)

## [id, nombre, pesos {atributo: peso}, puestos ("*" = todos los de campo; o lista de demarcaciones / grupos), rasgo que suma]
const CATALOGO := [
	["regate_prof", "Regate en profundidad", {"reg": 0.6, "rit": 0.4}, ["DEL", "MED", "LD", "LI", "CAD", "CAI"], "veloz"],
	["amago", "Bicicleta y amago", {"reg": 0.85, "rit": 0.15}, ["DEL", "MCO", "MD", "MI"], ""],
	["pase_hueco", "Pase al hueco", {"pas": 0.8, "reg": 0.2}, ["MED", "SD", "DC", "ED", "EI"], "cerebro"],
	["primer_toque", "Pase al primer toque", {"pas": 0.7, "reg": 0.3}, ["*"], "cerebro"],
	["centro", "Centro preciso", {"pas": 0.7, "rit": 0.3}, ["LD", "LI", "CAD", "CAI", "MD", "MI", "ED", "EI"], ""],
	["disparo_lejano", "Disparo lejano", {"tir": 0.75, "fis": 0.25}, ["MED", "DEL"], "killer"],
	["rosca", "Tiro con rosca", {"tir": 0.6, "pas": 0.4}, ["MCO", "MD", "MI", "DEL"], ""],
	["cabeza", "Remate de cabeza", {"fis": 0.6, "tir": 0.4}, ["DC", "SD", "DFC"], "muralla"],
	["primera", "Definición de primera", {"tir": 0.85, "reg": 0.15}, ["DEL", "MCO"], "killer"],
	["penaltis", "Especialista en penaltis", {"tir": 0.7, "pas": 0.3}, ["DEL", "MED"], "killer"],
	["marcaje", "Marcaje al hombre", {"def": 0.8, "fis": 0.2}, ["DEF", "MCD"], "muralla"],
	["repliegue", "Repliegue", {"def": 0.45, "rit": 0.3, "fis": 0.25}, ["MED", "LD", "LI", "CAD", "CAI", "ED", "EI"], ""],
	["intercepcion", "Intercepción", {"def": 0.7, "pas": 0.3}, ["DEF", "MCD", "MC"], "cerebro"],
	["despeje", "Despeje acrobático", {"def": 0.6, "fis": 0.4}, ["DFC", "LD", "LI"], "muralla"],
	["lucha", "Espíritu de lucha", {"fis": 0.65, "def": 0.35}, ["*"], "muralla"],
	["revulsivo", "Revulsivo", {"rit": 0.55, "tir": 0.45}, ["DEL", "MCO"], "veloz"],
	["saque_largo", "Saque largo", {"saq": 0.8, "pos": 0.2}, ["POR"], ""],
	["parada_penal", "Parada de penaltis", {"ref": 0.6, "div": 0.4}, ["POR"], ""],
	["salida", "Salida rápida", {"vel": 0.6, "pos": 0.4}, ["POR"], ""],
	["reflejos", "Reflejos felinos", {"ref": 0.8, "par": 0.2}, ["POR"], ""],
	["liderazgo", "Liderazgo", {}, ["*", "POR"], "lider"],
]

## ¿La habilidad cabe en la demarcación del jugador?
static func cabe(puestos: Array, j: Jugador) -> bool:
	var grupo := PesosPuesto.grupo(j.pos_e)
	if grupo == "":
		grupo = j.pos
	if puestos.has(j.pos_e) or puestos.has(grupo):
		return true
	return puestos.has("*") and grupo != "POR"

## La puntuación (aprox. 20-99) de una habilidad para el jugador; -1 si no le corresponde.
static func puntuacion(j: Jugador, fila: Array) -> float:
	if not cabe(fila[3], j):
		return -1.0
	var s := 0.0
	var pesos: Dictionary = fila[2]
	if String(fila[0]) == "liderazgo":
		s = float(j.ovr) - 6.0 + (9.0 if j.capitan else 0.0) + clampf(float(j.edad - 24), 0.0, 9.0)
	else:
		var suma := 0.0
		for k: String in pesos:
			s += float(j.atributos.get(k, j.ovr)) * float(pesos[k])
			suma += float(pesos[k])
		s /= maxf(suma, 0.01)
	if String(fila[4]) != "" and j.rasgo == String(fila[4]):
		s += 6.0
	## Un poco de carácter propio (−2..+2), fijo por jugador y habilidad: dos jugadores con los mismos números no salen calcados.
	s += float(absi(hash(j.id + String(fila[0]))) % 5) - 2.0
	return s

static func estrellas_de(puntos: float) -> int:
	var n := 0
	for u: float in UMBRALES:
		if puntos >= u:
			n += 1
	return n

## Las habilidades del jugador con 1+ estrellas, de mejor a peor: [{id, nombre, estrellas, puntos}] (como mucho `MAXIMO`).
static func de(j: Jugador) -> Array:
	var salida: Array = []
	if j == null:
		return salida
	for fila: Array in CATALOGO:
		var p := puntuacion(j, fila)
		var n := estrellas_de(p)
		if n > 0:
			salida.append({"id": String(fila[0]), "nombre": String(fila[1]), "estrellas": n, "puntos": p})
	salida.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["puntos"]) > float(b["puntos"]))
	return salida.slice(0, MAXIMO)
