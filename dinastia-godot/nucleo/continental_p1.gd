extends Copa
## [Capa 1/2 de `continental.gd`] _confed, claves, paises_de, nombre_conti, premio_de, confed_de … (+19)

## Los torneos internacionales de clubes: Libertadores, Champions, Sudamericana,
## Europa League, y las copas de Asia, África, Oceanía y Concacaf.
##
## Por qué hereda de `Copa` y no es un sistema aparte: un torneo continental es
## una eliminación directa entre clubes de varios países. Los cruces, la tanda de
## penales, la final en cancha neutral y el "este partido lo dirigió el
## entrenador, no lo vuelvas a simular" ya están resueltos en `copa.gd`. Lo único
## que el continental añade por delante es la fase de grupos, y por detrás una
## tabla de premios distinta. Duplicar la eliminatoria para cambiar dos cifras es
## como se acaban teniendo dos motores de copa que se van separando solos.
##
## FORMATO (el del HTML, tal cual): 16 clubes, cuatro grupos de cuatro, tres
## fechas, y los ocho que salen juegan cuartos, semifinal y final. Las seis
## rondas caen en las semanas 3, 8, 13, 18, 23 y 28, intercaladas con la liga.
##
## LOS PREMIOS SON CIFRAS FIJAS, no escaladas al tamaño del club. Es a propósito
## y viene del HTML: los 900.000 de la Libertadores valen lo mismo para Boca que
## para Ñublense, y por eso una campaña internacional le cambia el año a un club
## chico. Escalarlos los convertiría en un ingreso más de los grandes.
##
## Diferencia deliberada con el HTML: allí `mov()` solo sabía mover el dinero de
## TU club, así que los premios continentales solo los cobraba el jugador humano.
## Aquí cada club tiene su propio saldo y cobra el que le toca, igual que ya hace
## `Copa` con el campeón de la copa nacional. Las cifras no cambian; cambia que
## el mundo también vive de lo que gana.

signal grupos_terminados(clasificados: Array)
## El sorteo de la fase de grupos, para la cinemática del bombo. `grupos` es un
## Array de Array[Club]. La de eliminatorias la hereda de `Copa`.
signal sorteo_grupos(grupos: Array)

## Las semanas de liga tras las que se juega cada ronda continental. Es el
## `contiEn` del HTML: la posición dentro del array ES el número de ronda, así
## que el orden importa más que los valores.
const CONTI_EN := [3, 8, 13, 18, 23, 28]

const PLAZAS := 16
const GRUPOS := 4
const FECHAS_DE_GRUPO := 3

## Fallback del premio al campeón si alguien pide una clave que no está en
## CONFED. En el HTML había además otro fallback distinto (300.000) para el
## premio de cuartos; los dos son código muerto mientras las claves salgan de la
## propia tabla, así que aquí hay uno solo.
const PREMIO_POR_DEFECTO := 450000
## Pasar de la fase de grupos paga el 28% del premio del campeón.
const CUOTA_CUARTOS := 0.28

## El reparto de plazas está escrito desde Chile, igual que el HTML: el país
## anfitrión se lleva tres plazas de Libertadores (una de ellas para el campeón
## de la copa nacional) y tres de Sudamericana. No es una casualidad del sorteo,
## es la premisa del juego.
const PAIS_ANFITRION := "CHI"
const CUPOS_SUDAMERICA := [["ARG", 3], ["BRA", 3], ["COL", 2], ["URU", 1], ["PAR", 1], ["PER", 1], ["ECU", 1], ["BOL", 1]]
const CUPOS_UCL := [["ESP", 4], ["ENG", 4], ["ITA", 3], ["GER", 3], ["FRA", 2]]
const CUPOS_UEL := [["ESP", 3], ["ENG", 3], ["ITA", 3], ["GER", 3], ["FRA", 4]]

## Solo las copas grandes entran en el bucle de `confed_de`. 'sud' y 'uel'
## comparten países con 'lib' y 'ucl': si estuvieran aquí, a un club chileno le
## saldría la Sudamericana como torneo natural de su continente, que es la
## segunda copa y no la de referencia.
const PRINCIPALES := ["lib", "ucl", "asia", "afr", "oce", "conc"]

## Clave de la confederación ("lib", "ucl", "asia"...). Manda sobre el premio y
## sobre el nombre, así que no se toca después de `crear()`.
var clave: String = "lib"
var premio: int = PREMIO_POR_DEFECTO

## Los cuatro grupos, cada uno un Array de cuatro Club.
var grupos: Array[Array] = []
## club_id -> {pts, pj, gf, gc}. Solo de la fase de grupos.
var marcador: Dictionary = {}
## Fechas de grupo ya jugadas (0..3).
var fecha: int = 0
## Los ocho que salieron de la fase de grupos, en el orden del cuadro. Ver `clasificados()`.
var _de_grupos: Array[Club] = []

## Falso cuando no hubo clubes para llenar los 16 y se juega a eliminación
## directa desde el principio. Ver `preparar()`.
var por_grupos: bool = false


## --- LA TABLA CONFED -------------------------------------------------------

static func _confed() -> Dictionary:
	if not Datos.tiene("CONFED"):
		return {}
	var t: Variant = Datos.tabla("CONFED")
	return t if t is Dictionary else {}

## Las ocho claves en el orden del HTML. Se pide a la tabla en vez de listarlas
## aquí para que añadir una confederación al HTML no obligue a tocar esto.
static func claves() -> Array:
	if Datos.tiene("CONTI_KEYS"):
		var k: Variant = Datos.tabla("CONTI_KEYS")
		if k is Array:
			return (k as Array).duplicate()
	return _confed().keys()

static func paises_de(k: String) -> Array:
	var c: Dictionary = _confed().get(k, {})
	var p: Variant = c.get("paises", [])
	return p if p is Array else []

## El nombre pasa por `Nombres.limpiar` porque en las tablas viene en leetspeak
## ("Champi0ns Le4gue"). Mostrarlo crudo es el fallo que ya se pagó en el HTML.
static func nombre_conti(k: String) -> String:
	var c: Dictionary = _confed().get(k, {})
	return Nombres.de_tabla(String(c.get("n", k)))

static func premio_de(k: String) -> int:
	var c: Dictionary = _confed().get(k, {})
	return int(c.get("prem", PREMIO_POR_DEFECTO))

## Qué copa continental le toca a un país. 'lib' es la red de seguridad del
## HTML: un país nuevo que nadie metió en CONFED no se queda sin torneo.
static func confed_de(pais: String) -> String:
	for k: String in PRINCIPALES:
		if paises_de(k).has(pais):
			return k
	return "lib"

## La copa chica de una confederación, o "" si no tiene. Solo Sudamérica y
## Europa tienen dos torneos en el juego.
static func segunda_copa(k: String) -> String:
	if k == "lib":
		return "sud"
	if k == "ucl":
		return "uel"
	return ""

## Qué ronda continental toca esta semana de liga, o -1 si ninguna. Lo usa el
## calendario para intercalar los seis partidos internacionales.
static func toca_ronda(semana_de_liga: int) -> int:
	return CONTI_EN.find(semana_de_liga)

## Crea el torneo vacío. Es una fábrica y no un `_init` propio para no tener que
## repetir la firma del constructor de `Copa`: aquí solo se le pone nombre,
## clave y premio, y el resto lo monta `preparar()`.
static func crear(k: String) -> Continental:
	var t := Continental.new(nombre_conti(k))
	t.clave = k
	t.premio = premio_de(k)
	return t

## Reputación, y el id como desempate. El id no está de adorno: `sort_custom` no
## es estable, así que sin un criterio final dos clubes con la misma reputación
## podrían salir en distinto orden en dos ejecuciones de la MISMA semilla, y ahí
## se acaba la repetibilidad sobre la que vive el banco de pruebas.
static func _mas_reputado(a: Club, b: Club) -> bool:
	if a.rep != b.rep:
		return a.rep > b.rep
	return a.id < b.id


## --- QUIÉN SE CLASIFICA ----------------------------------------------------

## El orden de mérito de un país: la tabla de su Primera si ya se ha jugado algo,
## y la reputación si el mundo está recién generado.
##
## En el HTML esto eran dos funciones distintas (`rankRep` al arrancar la
## temporada y `ordenPais` al cerrarla) y en cada sitio había que acordarse de
## cuál tocaba. Aquí es una sola que mira si hay partidos jugados: da lo mismo en
## los dos momentos y no se puede equivocar de criterio.
##
## `clubes` es la lista de todos los clubes del mundo y `ligas` la de todas las
## ligas. Se pasan sueltos y no el `Mundo` entero a propósito: así este fichero
## no depende de `mundo.gd`, que sí va a depender de este, y no se monta un ciclo
## de clases que a GDScript se le atraganta.
static func orden_de_pais(clubes: Array, ligas: Array, pais: String) -> Array[Club]:
	for l: Liga in ligas:
		if l.pais != pais or l.division() != 1:
			continue
		var t := l.tabla()
		if not t.is_empty() and int(t[0].get("pj", 0)) > 0:
			var salida: Array[Club] = []
			for f: Dictionary in t:
				salida.append(f["club"])
			return salida
		break
	var pool: Array[Club] = []
	for c: Club in clubes:
		if c.pais == pais and c.division == 1:
			pool.append(c)
	pool.sort_custom(_mas_reputado)
	return pool

## Reparte `n` plazas de la lista ordenada de un país saltándose a quien ya tiene
## plaza. Es el `take` del HTML, y lo importante es que el conjunto `usado` se
## comparte entre la copa grande y la chica de la misma confederación: por eso a
## la Sudamericana le llega el cuarto de Argentina y no el primero.
static func _tomar(destino: Array[Club], candidatos: Array[Club], n: int, usado: Dictionary) -> void:
	var puestas := 0
	for c: Club in candidatos:
		if puestas >= n:
			break
		if usado.has(c.id):
			continue
		destino.append(c)
		usado[c.id] = true
		puestas += 1

## Completa una copa hasta las 16 plazas con los mejores clubes que queden de su
## confederación.
##
## El HTML rellenaba Libertadores y Sudamericana con los clubes de "división 0"
## (los importados a mano, que no juegan liga). Aquí no hay división 0, así que
## se tira de los que sí existen: los de Segunda de la confederación y los de
## países sin cupo asignado, VEN entre ellos, que está en la lista de la
## Libertadores pero no tiene plaza propia en la tabla de cupos.
static func _rellenar(lista: Array[Club], clubes: Array, k: String, usado: Dictionary) -> void:
	if lista.size() >= PLAZAS:
		return
	var paises := paises_de(k)
	var extra: Array[Club] = []
	for c: Club in clubes:
		if usado.has(c.id) or not paises.has(c.pais):
			continue
		extra.append(c)
	extra.sort_custom(_mas_reputado)
	for c: Club in extra:
		if lista.size() >= PLAZAS:
			break
		lista.append(c)
		usado[c.id] = true

static func _orden(clubes: Array, ligas: Array, cache: Dictionary, pais: String) -> Array[Club]:
	if cache.has(pais):
		return cache[pais]
	var lista := orden_de_pais(clubes, ligas, pais)
	cache[pais] = lista
	return lista

## El cuadro de plazas de las ocho copas: clave -> Array[Club] de 16.
##
## `campeon_copa` es el campeón de la copa nacional, que se lleva una plaza
## directa. Trampa que el HTML no llegó a ver: allí el campeón de copa entraba a
## la Libertadores fuera cual fuera su país, porque la partida siempre empezaba
## en Chile. Dirigiendo en España eso metía al ganador de la Copa del Rey en la
## Libertadores, así que aquí solo entra si su país pertenece de verdad a la
## confederación; si no, la plaza vuelve al tercero de la liga anfitriona.
static func plazas(clubes: Array, ligas: Array, campeon_copa: Club = null) -> Dictionary:
	var cache := {}
	var salida := {}

	## Sudamérica: Libertadores primero y Sudamericana después, compartiendo el
	## conjunto de clasificados. El orden de estas dos llamadas ES el reparto.
	var usado_sur := {}
	var lib: Array[Club] = []
	var sud: Array[Club] = []
	_tomar(lib, _orden(clubes, ligas, cache, PAIS_ANFITRION), 2, usado_sur)
	if campeon_copa != null and not usado_sur.has(campeon_copa.id) \
			and paises_de("lib").has(campeon_copa.pais):
		lib.append(campeon_copa)
		usado_sur[campeon_copa.id] = true
	else:
		_tomar(lib, _orden(clubes, ligas, cache, PAIS_ANFITRION), 1, usado_sur)
	for fila: Array in CUPOS_SUDAMERICA:
		_tomar(lib, _orden(clubes, ligas, cache, String(fila[0])), int(fila[1]), usado_sur)
	_rellenar(lib, clubes, "lib", usado_sur)
	_tomar(sud, _orden(clubes, ligas, cache, PAIS_ANFITRION), 3, usado_sur)
	for fila: Array in CUPOS_SUDAMERICA:
		_tomar(sud, _orden(clubes, ligas, cache, String(fila[0])), int(fila[1]), usado_sur)
	_rellenar(sud, clubes, "sud", usado_sur)
	salida["lib"] = lib
	salida["sud"] = sud

	## Europa: mismo mecanismo. Fíjate en que Francia da dos plazas de Champions
	## y cuatro de Europa League, y España cuatro y tres. Está así en el HTML.
	var usado_eu := {}
	var ucl: Array[Club] = []
	var uel: Array[Club] = []
	for fila: Array in CUPOS_UCL:
		_tomar(ucl, _orden(clubes, ligas, cache, String(fila[0])), int(fila[1]), usado_eu)
	_rellenar(ucl, clubes, "ucl", usado_eu)
	for fila: Array in CUPOS_UEL:
		_tomar(uel, _orden(clubes, ligas, cache, String(fila[0])), int(fila[1]), usado_eu)
	_rellenar(uel, clubes, "uel", usado_eu)
	salida["ucl"] = ucl
	salida["uel"] = uel

	## Asia, África, Oceanía y Concacaf no tienen cupos escritos: se reparten las
	## 16 plazas a partes iguales entre sus países y se redondea hacia arriba,
	## que es lo que hace que con tres países entren seis de cada uno y sobren
	## dos. Oceanía es un solo país, así que se lleva las 16.
	for k: String in ["asia", "afr", "oce", "conc"]:
		var paises := paises_de(k)
		if paises.is_empty():
			continue
		var cupo := PLAZAS if paises.size() <= 1 else ceili(float(PLAZAS) / float(paises.size()))
		var usado := {}
		var pool: Array[Club] = []
		for p in paises:
			_tomar(pool, _orden(clubes, ligas, cache, String(p)), cupo, usado)
		_rellenar(pool, clubes, k, usado)
		salida[k] = pool

	for k: String in salida.keys():
		var lista: Array[Club] = salida[k]
		if lista.size() > PLAZAS:
			lista.resize(PLAZAS)
	return salida

## Monta las ocho copas de la temporada. Devuelve clave -> Continental, que es lo
## que en el HTML era `G.conti`.
##
## Se salta las confederaciones sin clubes suficientes: el mundo de Godot se
## puede generar con dos ligas para una prueba, y entonces la Champions de Asia
## no tiene a quién invitar. En el HTML esto no podía pasar porque siempre se
## generaban los 24 países.
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

## En qué torneo continental está un club, o null. Es el `contiDeClub` del HTML,
## que además de la interfaz lo usa la negociación de fichajes: ofrecerle
## Libertadores a alguien que no la juega vale un 14% de convencimiento.
static func de_club(torneos: Dictionary, c: Club) -> Continental:
	if c == null:
		return null
	for t: Continental in torneos.values():
		if t.participa(c):
			return t
	return null


## --- EL TORNEO -------------------------------------------------------------

## Reparte los 16 en cuatro grupos. NO se barajan: el orden en que llegan es el
## del reparto de plazas (campeón de Chile, subcampeón, campeón de copa, los tres
## de Argentina...), y el "uno para cada grupo por turnos" del HTML es
## precisamente lo que evita que los tres brasileños caigan juntos. Barajar antes
## rompería ese sembrado sin que se note hasta que un grupo sale imposible.
##
## Con menos de 16 clubes no hay fase de grupos: se juega a eliminación directa
## desde el principio con lo que haya, que es exactamente para lo que sirve
## `Copa`. Pasa en los mundos de prueba, no en una partida de verdad.
func preparar(clubes: Array[Club]) -> void:
	fecha = 0
	grupos.clear()
	marcador.clear()
	_de_grupos.clear()
	por_grupos = clubes.size() >= PLAZAS
	if not por_grupos:
		super.preparar(clubes)
		return
	participantes.clear()
	for i in PLAZAS:
		participantes.append(clubes[i])
	for i in GRUPOS:
		grupos.append([])
	for i in participantes.size():
		grupos[i % GRUPOS].append(participantes[i])
	for c in participantes:
		marcador[c.id] = {"pts": 0, "pj": 0, "gf": 0, "gc": 0}
	vivos = []
	ronda = 0
	campeon = null
	historial.clear()
	sorteo_grupos.emit(grupos.duplicate())

func participa(c: Club) -> bool:
	return c != null and participantes.has(c)

func en_fase_de_grupos() -> bool:
	return por_grupos and fecha < FECHAS_DE_GRUPO

## Se sobrescribe porque durante los grupos `vivos` está vacío: el cuadro no
## existe hasta que termina la tercera fecha, y la versión de `Copa` daría el
## torneo por acabado antes de empezar.
func en_curso() -> bool:
	if campeon != null:
		return false
	if en_fase_de_grupos():
		return true
	return vivos.size() >= 2

func nombre_de_ronda() -> String:
	if en_fase_de_grupos():
		return "Grupos · Fecha %d" % (fecha + 1)
	return super.nombre_de_ronda()

func nombre_de_grupo(i: int) -> String:
	return "Grupo %s" % "ABCD".substr(i, 1) if i >= 0 and i < GRUPOS else "Grupo"

## El calendario de un grupo de cuatro, tal cual el `fixGrupo` del HTML: cada uno
## juega tres partidos, nadie repite rival y el primero de la lista es siempre
## local. El reparto de localías no es simétrico y se deja como está, porque es
## lo que hace que el sembrado (el primero de cada grupo es el mejor clasificado)
## valga de algo.
static func _cruces_de_grupo(g: Array, r: int) -> Array:
	if g.size() < 4:
		return []
	var a: Club = g[0]
	var b: Club = g[1]
	var c: Club = g[2]
	var d: Club = g[3]
	match r:
		0: return [[a, d], [b, c]]
		1: return [[a, c], [d, b]]
		_: return [[a, b], [c, d]]

## El cruce en el que juega tu club esta ronda, [local, visita], o vacío. Lo pide
## la interfaz para dirigir ESE partido antes de que se simulen los otros siete.
func emparejamiento_de(c: Club) -> Array:
	if campeon != null:
		return []
	if en_fase_de_grupos():
		for g in grupos:
			if not g.has(c):
				continue
			for par: Array in _cruces_de_grupo(g, fecha):
				if par[0] == c or par[1] == c:
					return par
			return []
		return []
	return super.emparejamiento_de(c)
