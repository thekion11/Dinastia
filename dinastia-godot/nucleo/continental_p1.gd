extends Copa
## [Capa 1/3 de `continental.gd`] estado, tabla CONFED, claves, crear, sortear, de_club

## Los torneos internacionales de clubes: Libertadores, Champions, Sudamericana, Europa League, Conference y las copas de
## Asia, África, Oceanía y Concacaf.
##
## Por qué hereda de `Copa` y no es un sistema aparte: un torneo continental es una eliminación directa entre clubes de
## varios países. Los cruces, la tanda de penales, la final en cancha neutral y el «este partido lo dirigió el entrenador,
## no lo vuelvas a simular» ya están resueltos en `copa.gd`. Lo que el continental añade es la primera fase (grupos o fase
## de liga), la ida y vuelta y una tabla de premios distinta.
##
## FORMATO: cada torneo trae el suyo en `FormatosConti` (una tabla), no en el código. Un «hueco» del calendario es un
## partido de cada club y `ronda` cuenta los huecos ya jugados. Antes todos eran de 16 clubes, 4 grupos y las semanas
## 3-8-13-18-23-28; ese formato sigue existiendo como «clasico» para abrir partidas guardadas a medias.
##
## LOS PREMIOS SON CIFRAS FIJAS, no escaladas al tamaño del club: los 900.000 de la Libertadores valen lo mismo para
## Boca que para Ñublense, y por eso una campaña internacional le cambia el año a un club chico.
##
## Diferencia deliberada con el HTML: allí solo cobraba el club del jugador. Aquí cada club tiene su saldo y cobra el que le toca.

signal grupos_terminados(clasificados: Array)
## El sorteo de la fase de grupos o de liga, para la cinemática del bombo. `grupos` es un Array de Array[Club]. La de
## eliminatorias la hereda de `Copa`.
signal sorteo_grupos(grupos: Array)

## Fallback del premio al campeón si alguien pide una clave que no está en CONFED.
const PREMIO_POR_DEFECTO := 450000
## Pasar de la primera fase al cuadro paga el 28 % del premio del campeón.
const CUOTA_CUARTOS := 0.28

## El reparto de plazas de Sudamérica está escrito desde Chile (premisa del juego, igual que el HTML).
const PAIS_ANFITRION := PlazasConti.PAIS_ANFITRION

## Solo las copas grandes entran en el bucle de `confed_de`. 'sud', 'uel' y 'uecl' comparten países con 'lib' y 'ucl': si
## estuvieran aquí, a un club chileno le saldría la Sudamericana como torneo natural de su continente.
const PRINCIPALES := ["lib", "ucl", "asia", "afr", "oce", "conc"]

## Clave de la confederación ("lib", "ucl", "asia"...). Manda sobre el premio y el nombre: no se toca tras `crear()`.
var clave: String = "lib"
var premio: int = PREMIO_POR_DEFECTO

## El id del formato con el que se sorteó (ver `FormatosConti`): el de su clave, «clasico», «ko» o «ko_viejo».
var formato: String = FormatosConti.CLASICO
## Los grupos de la primera fase, cada uno un Array de Club. En la fase de liga hay UN solo «grupo» con todos.
var grupos: Array[Array] = []
## club_id -> {pts, pj, gf, gc}. Solo de la primera fase.
var marcador: Dictionary = {}
## Fechas de la primera fase ya jugadas.
var fecha: int = 0
## Los que salieron de la primera fase hacia el cuadro principal, en el orden del cuadro. Ver `clasificados()`.
var _de_grupos: Array[Club] = []
## Fase de liga: las fechas sorteadas ([[local, visita], …] por fecha) y los puestos 1-N que pasan directo.
var _dias: Array = []
var _directos: Array[Club] = []
## Ida y vuelta: lo que pasó en la ida de la ronda en curso ([{local, visita, gl, gv}]).
var _ida: Array = []
## Los huecos del calendario (se calculan una vez) y sus semanas.
var _huecos: Array = []

## Falso cuando no hubo clubes para llenar el formato y se juega a eliminación directa desde el principio.
var por_grupos: bool = false


## --- LA TABLA CONFED -------------------------------------------------------

static func _confed() -> Dictionary:
	return FormatosConti.tabla_confed()

## Las claves en el orden de la tabla del juego más las que ella no trae (la Conference). Se pide a la tabla en vez de
## listarlas aquí para que añadir una confederación al HTML no obligue a tocar esto.
static func claves() -> Array:
	var base: Array = []
	if Datos.tiene("CONTI_KEYS"):
		var k: Variant = Datos.tabla("CONTI_KEYS")
		if k is Array:
			base = (k as Array).duplicate()
	if base.is_empty():
		base = (Datos.tabla("CONFED") as Dictionary).keys() if Datos.tiene("CONFED") else []
	return FormatosConti.claves(base)

static func paises_de(k: String) -> Array:
	return FormatosConti.paises_de(k)

## El nombre pasa por `Nombres.limpiar` porque en las tablas viene en leetspeak ("Champi0ns Le4gue").
static func nombre_conti(k: String) -> String:
	var c: Dictionary = _confed().get(k, {})
	return Nombres.de_tabla(String(c.get("n", k)))

static func premio_de(k: String) -> int:
	var c: Dictionary = _confed().get(k, {})
	return int(c.get("prem", PREMIO_POR_DEFECTO))

## Qué copa continental le toca a un país. 'lib' es la red de seguridad del HTML.
static func confed_de(pais: String) -> String:
	for k: String in PRINCIPALES:
		if paises_de(k).has(pais):
			return k
	return "lib"


## ¿Hay algún partido continental esta semana? (para el calendario y la interfaz: ¿juega alguien?). Devuelve 0 si lo hay y -1
## si no; el número ya no es «la ronda»: cada torneo tiene SU calendario, que se pregunta con `toca(semana)`.
static func toca_ronda(semana_de_liga: int) -> int:
	return 0 if FormatosConti.hay_partido_en(semana_de_liga) else -1

## Crea el torneo vacío. Es una fábrica y no un `_init` propio para no repetir la firma del constructor de `Copa`.
static func crear(k: String) -> Continental:
	var t: Continental
	match k:
		"mundial": t = MundialClubes.new(nombre_conti(k))
		"interc": t = CopaIntercontinental.new(nombre_conti(k))
		_: t = Continental.new(nombre_conti(k))
	t.clave = k
	t.premio = premio_de(k)
	return t

static func _mas_reputado(a: Club, b: Club) -> bool:
	return PlazasConti.mas_reputado(a, b)


## --- QUIÉN SE CLASIFICA (ver `PlazasConti`) --------------------------------

static func orden_de_pais(clubes: Array, ligas: Array, pais: String) -> Array[Club]:
	return PlazasConti.orden_de_pais(clubes, ligas, pais)

static func plazas(clubes: Array, ligas: Array, campeon_copa: Club = null) -> Dictionary:
	return PlazasConti.plazas(clubes, ligas, campeon_copa)

## Monta los torneos de la temporada. Devuelve clave -> Continental, que es lo que en el HTML era `G.conti`.
##
## Se salta las confederaciones sin clubes suficientes: el mundo de Godot se puede generar con dos ligas para una prueba.
static func sortear(clubes: Array, ligas: Array, campeon_copa: Club = null) -> Dictionary:
	var reparto := plazas(clubes, ligas, campeon_copa)
	var salida := {}
	for k: String in claves():
		if not reparto.has(k):
			continue
		var lista: Array[Club] = reparto[k]
		if lista.size() < 4:
			continue
		var t := crear(k)
		t.preparar(lista)
		salida[k] = t
	return salida

## En qué torneo continental está un club, o null. Es el `contiDeClub` del HTML. Las plazas no se repiten dentro de una
## confederación, así que es uno solo (salvo los torneos de la FIFA, que se miran aparte: `mi_continental` los prefiere si toca).
static func de_club(torneos: Dictionary, c: Club) -> Continental:
	if c == null:
		return null
	for t: Continental in torneos.values():
		if t.participa(c):
			return t
	return null
