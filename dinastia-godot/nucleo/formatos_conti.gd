class_name FormatosConti
extends RefCounted
## LOS FORMATOS DE LOS TORNEOS CONTINENTALES, COMO TABLA (sesión 6, 10-11).
##
## Antes los ocho torneos tenían un solo formato escrito en el código (16 clubes, 4 grupos de 4, cuartos, semis y
## final, en las semanas 3-8-13-18-23-28). Ahora cada torneo trae SU formato en esta tabla y el motor
## (`Continental`) solo sabe leerla: añadir o cambiar un torneo es tocar una fila, no el código.
##
## Una fila tiene:
##   fase       «liga» (todos en una tabla, 8 partidos por club contra rivales sorteados por bombos),
##              «grupos» (grupos de 4 a doble vuelta) o «ko» (eliminación directa desde el principio).
##   plazas     cuántos clubes juegan el torneo entero.
##   fechas     (liga/grupos) partidos de la primera fase por club.
##   directos   (liga) los N primeros pasan directo al cuadro; playoff: los siguientes (puestos N+1…N+playoff) juegan
##              una eliminatoria previa. Sin playoff, los `directos` son todos los que pasan.
##   grupos_tam (grupos) tamaño de cada grupo.
##   ida_vuelta etapas a doble partido: «po» (playoff) y el número de clubes vivos antes de la ronda (16, 8, 4, 2).
##   semanas    la semana de la temporada en que se juega CADA partido, en orden. Ninguna cae en múltiplo de 4: ahí
##              se juega la copa nacional y el torneo no debe pisarle el partido a tu club.
##   cupos      [país, plazas] en el orden en que se reparten (sin lista: reparto a partes iguales).
##   premio_ronda lo que cobra el que gana una ronda, por clubes vivos antes de jugarla (cifras del HTML).
##
## El formato «clasico» es el de antes (16/4/3 fechas). NO se usa para torneos nuevos: sirve para abrir partidas
## guardadas con un continental a medias, que siguen su curso con las reglas con las que se sortearon.

const CLASICO := "clasico"
## Eliminación directa con los clubes que haya (menos de las plazas del formato, o un torneo montado a mano en una prueba).
const KO := "ko"
const KO_VIEJO := "ko_viejo"
## Eliminación directa con «byes»: si sobra un club en una ronda, pasa sin jugar (el último de la lista). La usan el Mundial
## de Clubes con pocos campeones y la Copa Intercontinental.
const BYES := "byes"

const SEMANAS_CLASICO := [3, 8, 13, 18, 23, 28]

## Los torneos que no traía la tabla CONFED: la tercera copa europea.
const CONFED_EXTRA := {
	"uecl": {"n": "Copa H0rizont3", "paises_de": "uel", "prem": 380000},
	"afr2": {"n": "Copa de la 5abana", "paises_de": "afr", "prem": 260000},
	## Los torneos de la FIFA (sin país propio): se arman cada temporada con los campeones continentales del año anterior.
	"mundial": {"n": "Mund1al de Clubes", "paises_de": "", "prem": 1800000},
	"interc": {"n": "Copa Intercontinent4l", "paises_de": "", "prem": 900000},
}
const FIFA := ["mundial", "interc"]

const FORMATOS := {
	"clasico": {
		"fase": "grupos", "plazas": 16, "grupos_tam": 4, "fechas": 3, "ida_vuelta": [],
		"semanas": [3, 8, 13, 18, 23, 28],
	},
	## Fase de liga de 36: 8 partidos, 1-8 a octavos, 9-24 a un playoff a ida y vuelta (de ahí 8 más a octavos).
	"ucl": {
		"fase": "liga", "plazas": 36, "fechas": 8, "directos": 8, "playoff": 16,
		"ida_vuelta": ["po", 16, 8, 4],
		"semanas": [2, 5, 7, 10, 13, 15, 17, 19, 21, 22, 25, 26, 27, 29, 30, 31, 33],
		"cupos": [["ESP", 5], ["ENG", 5], ["ITA", 5], ["GER", 5], ["FRA", 3], ["POR", 3], ["NED", 2], ["BEL", 1], ["CRO", 1], ["DEN", 1], ["TUR", 1], ["SCO", 1], ["SUI", 1], ["AUT", 1], ["GRE", 1]],
	},
	"uel": {
		"fase": "liga", "plazas": 36, "fechas": 8, "directos": 8, "playoff": 16,
		"ida_vuelta": ["po", 16, 8, 4],
		"semanas": [3, 6, 9, 11, 14, 17, 18, 19, 21, 23, 25, 26, 27, 29, 30, 31, 34],
		"cupos": [["ESP", 3], ["ENG", 3], ["ITA", 3], ["GER", 2], ["FRA", 2], ["POR", 2], ["NED", 1], ["BEL", 1], ["CRO", 1], ["DEN", 2], ["TUR", 1], ["SCO", 1], ["SUI", 1], ["AUT", 1], ["GRE", 1], ["SWE", 1], ["NOR", 1], ["POL", 1], ["CZE", 1], ["ROU", 1], ["SRB", 1], ["UKR", 1], ["ISR", 1], ["HUN", 1], ["SVK", 1], ["BUL", 1]],
	},
	## La Conference tiene fase de liga de 36 pero 6 partidos por club, como la real (la versión corta de la liga).
	"uecl": {
		"fase": "liga", "plazas": 36, "fechas": 6, "directos": 8, "playoff": 16,
		"ida_vuelta": ["po", 16, 8, 4],
		"semanas": [3, 6, 9, 13, 14, 17, 21, 22, 25, 26, 27, 29, 30, 31, 34],
		"cupos": [["ESP", 2], ["ENG", 2], ["ITA", 2], ["GER", 2], ["FRA", 2], ["POR", 2], ["NED", 2], ["BEL", 2], ["CRO", 2], ["DEN", 2], ["TUR", 1], ["SCO", 1], ["SUI", 1], ["AUT", 1], ["GRE", 1], ["SWE", 1], ["NOR", 1], ["POL", 1], ["CZE", 1], ["ROU", 1], ["SRB", 1], ["UKR", 1], ["ISR", 1], ["HUN", 1], ["SVK", 1], ["BUL", 1]],
	},
	## Libertadores: 32 en 8 grupos de 4 (seis fechas), octavos a ida y vuelta, y la final a partido único.
	"lib": {
		"fase": "grupos", "plazas": 32, "grupos_tam": 4, "fechas": 6, "ida_vuelta": [16, 8, 4],
		"semanas": [3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27],
		"cupos": [["ARG", 6], ["BRA", 6], ["COL", 3], ["URU", 3], ["PAR", 2], ["PER", 3], ["ECU", 3], ["BOL", 2]],
	},
	## Sudamericana: el mismo molde con otro reparto de plazas.
	"sud": {
		"fase": "grupos", "plazas": 32, "grupos_tam": 4, "fechas": 6, "ida_vuelta": [16, 8, 4],
		"semanas": [2, 3, 6, 9, 10, 13, 14, 17, 19, 21, 23, 25, 27],
		"cupos": [["ARG", 6], ["BRA", 6], ["COL", 3], ["URU", 2], ["PAR", 2], ["PER", 3], ["ECU", 3], ["BOL", 2]],
	},
	## Asia (la Elite): fase de liga de 24 con 8 partidos y los 16 primeros al cuadro (octavos a ida y vuelta).
	"asia": {
		"fase": "liga", "plazas": 24, "fechas": 8, "directos": 16, "playoff": 0, "ida_vuelta": [16],
		"semanas": [3, 6, 9, 11, 14, 17, 19, 22, 25, 26, 27, 29, 30],
	},
	## África: 16 en 4 grupos a doble vuelta, y desde cuartos todo a ida y vuelta, final incluida.
	"afr": {
		"fase": "grupos", "plazas": 16, "grupos_tam": 4, "fechas": 6, "ida_vuelta": [8, 4, 2],
		"semanas": [2, 5, 9, 11, 14, 18, 21, 22, 26, 27, 30, 31],
	},
	## África, segunda copa (la Confederación): el mismo molde que la grande con otro calendario.
	"afr2": {
		"fase": "grupos", "plazas": 16, "grupos_tam": 4, "fechas": 6, "ida_vuelta": [8, 4, 2],
		"semanas": [3, 6, 10, 13, 15, 19, 23, 25, 26, 29, 33, 34],
	},
	## Oceanía: 8 en 2 grupos de 4, semifinales a ida y vuelta y final única.
	"oce": {
		"fase": "grupos", "plazas": 8, "grupos_tam": 4, "fechas": 6, "ida_vuelta": [4],
		"semanas": [2, 3, 5, 6, 9, 10, 13, 14, 17],
	},
	## MUNDIAL DE CLUBES de 32: 8 grupos de 4 a una vuelta, y desde octavos todo a partido único (la final en cancha neutral).
	## Con menos clubes: 16 (4 grupos) u 8 (2 grupos). Las semanas son del arranque de la temporada: lo juegan los campeones
	## del año anterior.
	"mundial": {
		"fase": "grupos", "plazas": 32, "grupos_tam": 4, "fechas": 3, "ida_vuelta": [],
		"semanas": [2, 3, 5, 6, 7, 9, 10],
	},
	"mundial16": {
		"fase": "grupos", "plazas": 16, "grupos_tam": 4, "fechas": 3, "ida_vuelta": [],
		"semanas": [2, 3, 5, 6, 7, 9],
	},
	"mundial8": {
		"fase": "grupos", "plazas": 8, "grupos_tam": 4, "fechas": 3, "ida_vuelta": [],
		"semanas": [2, 3, 5, 6, 7],
	},
	## COPA INTERCONTINENTAL: Challenger Cup (Asia contra África) y Derbi de las Américas (Libertadores contra Concacaf) el
	## mismo día; sus ganadores se ven en la semifinal y el ganador juega la final contra el campeón de Europa, que espera.
	"interc": {
		"fase": "ko", "plazas": 5, "ida_vuelta": [],
		"semanas": [13, 14, 17],
	},
	## Norte y Centroamérica: 16 por eliminación directa, todas las rondas a ida y vuelta (la final también).
	"conc": {
		"fase": "ko", "plazas": 16, "ida_vuelta": [16, 8, 4, 2],
		"semanas": [3, 6, 10, 14, 17, 19, 22, 23],
	},
}

## Lo que paga cada ronda al que la gana (el dinero que ya existía: 8 y 4 vivos; las rondas nuevas, a la misma escala).
## La Libertadores y la Sudamericana pagan casi el doble: viene del HTML y se deja tal cual.
const PREMIO_RONDA := {16: 90000, 8: 180000, 4: 250000}
const PREMIO_RONDA_LIB := {16: 180000, 8: 350000, 4: 500000}

static func existe(k: String) -> bool:
	return FORMATOS.has(k)

static func formato(id: String) -> Dictionary:
	return FORMATOS.get(id, {})

## Plazas del formato del torneo `k` (las del torneo entero).
static func plazas(k: String) -> int:
	return int(formato(k).get("plazas", 16))

static func cupos(k: String) -> Array:
	return formato(k).get("cupos", [])

## ¿Esta etapa se juega a ida y vuelta? `etapa` es «po» o el número de clubes vivos antes de la ronda.
static func es_ida_vuelta(id: String, etapa: Variant) -> bool:
	for e: Variant in formato(id).get("ida_vuelta", []):
		if str(e) == str(etapa):
			return true
	return false

## Los partidos del torneo, en orden: un hueco por semana. Cada uno es
## {t: liga|grupos|po|ko, pata: 0 único | 1 ida | 2 vuelta, vivos: clubes vivos antes de la ronda, fecha: n.º de fecha}.
## `n_ko` solo se usa en el formato «ko» (eliminación directa con los clubes que haya).
static func huecos(id: String, n_ko: int = 0) -> Array:
	var f := formato(id)
	var salida: Array = []
	var fase := String(f.get("fase", "ko"))
	var vivos := n_ko
	if id == BYES:
		var n := n_ko
		while n > 1:
			salida.append({"t": "ko", "pata": 0, "vivos": n, "fecha": 0})
			n = (n + 1) / 2
		return salida
	if id == KO or id == KO_VIEJO:
		fase = "ko"
	elif fase == "liga":
		for i in int(f["fechas"]):
			salida.append({"t": "liga", "pata": 0, "vivos": 0, "fecha": i})
		var po := int(f.get("playoff", 0))
		if po > 0:
			_hueco_ko(salida, id, "po", po)
			vivos = int(f["directos"]) + po / 2
		else:
			vivos = int(f["directos"])
	elif fase == "grupos":
		for i in int(f["fechas"]):
			salida.append({"t": "grupos", "pata": 0, "vivos": 0, "fecha": i})
		vivos = (int(f["plazas"]) / int(f["grupos_tam"])) * 2
	else:
		vivos = int(f["plazas"])
	while vivos >= 2:
		_hueco_ko(salida, id, vivos, vivos)
		vivos /= 2
	return salida

static func _hueco_ko(salida: Array, id: String, etapa: Variant, vivos: int) -> void:
	var t := "po" if str(etapa) == "po" else "ko"
	if es_ida_vuelta(id, etapa):
		salida.append({"t": t, "pata": 1, "vivos": vivos, "fecha": 0})
		salida.append({"t": t, "pata": 2, "vivos": vivos, "fecha": 1})
	else:
		salida.append({"t": t, "pata": 0, "vivos": vivos, "fecha": 0})

## La semana de cada hueco. Para «ko» y «ko_viejo» (pocos clubes) se toman las primeras semanas de la tabla del
## torneo: así una prueba con dos clubes juega su final al principio del año, como siempre.
static func semanas(id: String, k: String, n_huecos: int) -> Array:
	var base: Array = SEMANAS_CLASICO if id == KO_VIEJO else formato(k if (id == KO or id == BYES) else id).get("semanas", SEMANAS_CLASICO)
	if id == CLASICO:
		return SEMANAS_CLASICO.duplicate()
	return base.slice(0, mini(n_huecos, base.size()))

static func premio_de_ronda(k: String, vivos_antes: int) -> int:
	var t: Dictionary = PREMIO_RONDA_LIB if (k == "lib" or k == "sud") else PREMIO_RONDA
	## El clásico (y los torneos viejos) pagaban 8 y 4 y nada más: las rondas nuevas (16) no tocan las cuentas de antes.
	return int(t.get(vivos_antes, 0))

## Union de las semanas de TODOS los torneos: ¿hay algún partido continental esta semana? (para el calendario)
static func hay_partido_en(semana: int) -> bool:
	for id: String in FORMATOS:
		if id == CLASICO:
			continue
		if (FORMATOS[id]["semanas"] as Array).has(semana):
			return true
	return false

## La tabla CONFED que usa el juego (la de los datos más los torneos que ella no trae).
static func tabla_confed() -> Dictionary:
	var base: Dictionary = {}
	if Datos.tiene("CONFED"):
		var t: Variant = Datos.tabla("CONFED")
		if t is Dictionary:
			base = t
	return confed(base)

static func paises_de(k: String) -> Array:
	var c: Dictionary = tabla_confed().get(k, {})
	var p: Variant = c.get("paises", [])
	return p if p is Array else []

## La tabla CONFED completa: la del juego más los torneos que ella no trae.
static func confed(base: Dictionary) -> Dictionary:
	var salida := base
	for k: String in CONFED_EXTRA:
		if salida.has(k):
			continue
		if salida == base:
			salida = base.duplicate()
		var fila: Dictionary = (CONFED_EXTRA[k] as Dictionary).duplicate()
		var origen: Dictionary = base.get(String(fila["paises_de"]), {})
		fila["paises"] = (origen.get("paises", []) as Array).duplicate()
		fila.erase("paises_de")
		salida[k] = fila
	return salida

## Las claves del torneo en orden: las de la tabla del juego más las que ella no trae.
static func claves(base: Array) -> Array:
	var salida := base.duplicate()
	for k: String in CONFED_EXTRA:
		if not salida.has(k):
			salida.append(k)
	return salida
