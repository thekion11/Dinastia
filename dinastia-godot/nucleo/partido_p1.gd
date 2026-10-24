extends RefCounted
## [Capa 1/3 de `partido.gd`] fijar_clima, _momentum_push, momentum_local, limpiar_contexto, es_ex_de, _media_linea … (+7)

## Un partido, minuto a minuto.
##
## La formula es la del HTML, sin retocar. Y da LLEGADAS AL AREA, no goles:
##
##     p_ataque = 0.048 * (ata / ((ata + def_rival) / 1.9)) ^ 1.6 * local * clima
##     gol      = p_ataque  y ademas  azar < 0.30
##
## El exponente 1.6 es lo que hace que la diferencia de nivel se note de verdad
## sin volverla absoluta: un equipo un 20% mejor no gana el 20% mas de veces,
## gana bastante mas, pero el peor sigue teniendo su tarde. Y el 1.9 del
## denominador es lo que fija el numero medio de goles del campeonato. Los dos
## estan calibrados; no se tocan sin volver a correr el banco de pruebas.
##
## Quien quiera enterarse de lo que pasa se conecta a las senales. El simulador
## no sabe si hay una interfaz, una repeticion en 3D o nadie escuchando: por eso
## la misma clase sirve para jugar un partido en pantalla y para simular una
## temporada entera en modo headless.

## `asistente` (18-9-2026): puramente cosmético, para la dramatización 3D -no
## pesa en `goles_local/visita`, notas ni en nada que decida el partido, ver
## `_elegir_asistente()`-. `null` si el gol no tuvo con quién asistir (un once
## de un solo jugador, caso de prueba).
signal gol(club: Club, autor: Jugador, minuto: int, asistente: Jugador)
signal tarjeta(jugador: Jugador, roja: bool, minuto: int)
signal lesion(jugador: Jugador, semanas: int, minuto: int)
signal minuto_jugado(minuto: int)
signal cambio_hecho(sale: Jugador, entra: Jugador, minuto: int)
signal terminado(goles_local: int, goles_visita: int)
## Una llegada que no fue gol: "atajada" (la para el arquero), "poste" (pega en
## el palo) o "fallo" (la manda afuera). En el HTML esto ya narraba y sonaba
## -son los mismos umbrales r<0.55/r<0.62 de `ataque()` en juego.js-, pero aqui
## solo se contaba como remate (`remates_local/visita`) y no se avisaba a nadie:
## entre gol y gol la cronica del partido en vivo estaba muda. `autor` puede ser
## null si el once esta vacio, igual que en `_elegir_goleador()`.
signal remate(club: Club, autor: Jugador, tipo: String, minuto: int)
## Lo que decide EL ÁRBITRO por su cuenta, fuera del forcejeo normal del
## partido: una tarjeta de más, un penal dudoso, un gol anulado por nada.
## `_arb`/`registrarFalloArbitro()` del HTML. Solo narra -las tarjetas y el gol
## de penal YA se cuentan por las señales `tarjeta`/`gol`, esta es la frase que
## explica el porqué-.
signal decision_arbitral(texto: String, minuto: int)

const MINUTOS := 90
## LA PRÓRROGA (17-10-2026). Solo la juega el motor real del 3D en una
## eliminatoria empatada: `prorroga_externa()` lleva el final al 120' y da un
## cambio más (como el reglamento). Sin motor el empate va directo a penales.
var minutos_fin := MINUTOS
var cambios_extra := 0
const BASE_ATAQUE := 0.048
const EXPONENTE := 1.6
const REPARTO := 1.9
## Cuánto pesa la diferencia de calidad (ver `_probabilidad`).
const SENSIBILIDAD := 3.2
## De cada ataque que se genera, este porcentaje termina dentro. Es el `r<0.30`
## del HTML, y es facil de pasar por alto al portar: la formula de arriba NO da
## goles, da LLEGADAS. Portandola como si diera goles salian ocho por partido en
## vez de dos y medio. Lo caza la prueba de "goles por partido" del banco, que
## esta puesta justo para esto.
const CONVERSION := 0.30
## Los mismos cortes de `ataque()` en juego.js (linea ~2139 y ~2144), sobre el
## mismo `r` que decide el gol: entre CONVERSION y R_ATAJADA para la atajada,
## entre R_ATAJADA y R_POSTE para el palo, el resto para el fallo.
const R_ATAJADA := 0.55
const R_POSTE := 0.62

var local: Club
var visita: Club
var neutral: bool = false
var clima: float = 1.0   ## 1.0 = seco; por debajo, partido mas trabado
## El tiempo de ESTE partido (plan maestro C1, `Clima.del_partido()`): el de la
## ciudad del local en esa época del año. Se fija en `preparar()` si nadie lo
## fijó antes -la pantalla lo fija al abrir el partido dirigido para pintar el
## mismo cielo que se juega-.
var clima_info: Dictionary = {}
## Lo que le cuesta al visitante no estar hecho a ese clima (1.0 = nada).
var _f_clima_visita: float = 1.0

var goles_local: int = 0
var goles_visita: int = 0
## El peor déficit que sufrió cada lado en algún momento del partido -para
## `hubo_remontada_de()`, el logro oculto "remontada"-. Nunca positivo: 0 si
## nunca fue abajo, -3 si llegó a ir tres goles abajo en algún momento aunque
## después empatara o se pusiera arriba.
var peor_diferencia_local: int = 0
var peor_diferencia_visita: int = 0
var remates_local: int = 0
var remates_visita: int = 0
var minuto: int = 0
var terminado_ya: bool = false
## EL PARTIDO LO JUEGA EL MOTOR (13-10-2026). Con esto encendido, los goles,
## los remates, las tarjetas y la posesión NO se sortean aquí: los manda el
## motor real del 3D (`MotorJugable`) con `gol_externo()`, `remate_externo()`,
## `tarjeta_externa()` y `fijar_posesion()`. El reloj, las lesiones, los
## planes y todo lo demás siguen siendo de este objeto, que es el que va a
## la tabla.
var motor_externo := false
## Si ya se aplicó el plan del minuto 60. Ver `simular_minuto()`.
var _plan_aplicado: bool = false

## INSTRUCCIONES EFÍMERAS DE PARTIDO -`M.instr.riesgo`/`M.instr.tiempo` del
## HTML-: a diferencia de la pizarra (`Club.tactica`, persistente, se lleva de
## partido en partido), esto se resetea solo con cada `Partido` nuevo. Solo
## afectan al lado de `ctx_club_id` -las instrucciones son tuyas, no las das
## por el rival-. La ephemera "presión" del HTML NO se portó a propósito: el
## dial persistente `Club.tactica.presion` ya cubre esa misma decisión, y
## duplicarla como segundo control habría sido confuso, no fiel.
var instr_riesgo := false
var instr_tiempo := false

## EL LOG DE MOMENTUM -`M.mom` del HTML-: a diferencia de la posesión (media
## móvil lenta, ya portada y usada en la barra de arriba), esto es "quién está
## encima AHORA MISMO" según el ritmo reciente de ocasiones: +2/-2 en un gol,
## +1/-1 en cualquier remate (atajada, palo o fallo), sobre los últimos 12
## eventos. Positivo = a favor del LOCAL.
var momentum_eventos: Array[int] = []

## LAS ARENGAS. `impulsos` guarda hasta qué minuto le dura el subidón a cada
## jugador al que le hayas gritado desde la banda.
const ARENGA_BOOST := 1.12
const ARENGA_MINUTOS := 18
var impulsos: Dictionary = {}
## Cuanto pega la arenga. Viene de fuera porque `Partido` no conoce el arbol del
## entrenador: lo pone `Mundo` con `Entrenamiento.factor_instrucciones()`.
var _factor_arenga: float = 1.0
## El recorte de tarjetas por videoarbitraje y el parte medico del club. Los dos
## vienen de fuera porque `Partido` no conoce ni a la federacion ni al medico:
## los pone `Mundo` antes de jugar, igual que el factor de arenga.
## EL CONTEXTO DE LA SEMANA. Estatico y no por instancia porque los partidos de
## la liga los crea `Liga.jugar_jornada()`, que no conoce el mundo: pasarle un
## mundo a `Liga`, a `Copa` y a `Continental` solo para esto seria dar la vuelta
## al arbol entero. Lo fija `Mundo` al empezar cada semana y vale para todos los
## partidos de esa semana, que es exactamente su alcance.
##
## El videoarbitraje es una regla de LIGA -lo vota la asamblea- y por eso vale
## para todo el mundo. El parte medico es de TU club y solo se aplica a los
## tuyos: los otros 383 no llevan historial de lesiones.
static var ctx_factor_tarjetas: float = 1.0
static var ctx_medico: Medico = null
static var ctx_club_id: String = ""
static var ctx_anio: int = 0
static var ctx_semana: int = 0
## `Ciudad.penalizacion_cesped()` de tu estadio, 1.0 si está en condiciones o
## no tienes -Ciudad se crea con el primer terreno, no desde el arranque-.
## Solo pega cuando juegas de LOCAL: el pasto que se destroza es el tuyo.
static var ctx_cesped_local: float = 1.0
## Cuánto multiplica la superficie de TU estadio las lesiones cuando juegas de
## local (B6.5: el artificial castiga, el híbrido protege). 1.0 = natural.
static var ctx_lesion_local: float = 1.0
## Lo que la moda tactica le hace a cada dibujo esta temporada. Lo pone `Mundo`
## junto al resto del contexto: `Liga` crea sus partidos por dentro y no conoce
## el mundo.
static var ctx_moda: Dictionary = {}
## Lo que aporta el videoanalisis de esta semana, y a que club. Vale para UN
## partido: `Mundo` lo pone antes de la jornada y lo consume al acabarla.
static var ctx_analisis: float = 1.0

## `M.st` del HTML: lo que convierte un 1-0 sufrido en algo que se LEE distinto
## de un 1-0 cómodo. Ninguna de estas cifras toca el marcador -el motor de goles
## es exactamente el de antes-, son la lectura del partido.
##
## Se llevan en TODOS los partidos, no solo en el tuyo, aunque el HTML solo las
## lleve para el que se juega en vivo: cuestan seis tiradas de dados por minuto
## -milisegundos en una jornada entera- y así ningún camino se queda sin ellas
## por olvido (la copa, el continental, un amistoso futuro).
var posesion_local: float = 50.0
var tiros_puerta_local: int = 0
var tiros_puerta_visita: int = 0
var xg_local: float = 0.0
var xg_visita: float = 0.0
var corners_local: int = 0
var corners_visita: int = 0
var faltas_local: int = 0
var faltas_visita: int = 0
var fueras_local: int = 0
var fueras_visita: int = 0

var once_local: Array[Jugador] = []
var once_visita: Array[Jugador] = []
var cronica: Array[Dictionary] = []

## La fuerza de los dos onces no cambia durante el partido -forma, moral y
## fisico son semanales-, asi que se calcula al empezar y no en cada uno de los
## noventa minutos. Recalcularla cada minuto costaba el 60% del tiempo de
## simulacion sin cambiar un solo resultado.
##
## El dia que entren los cambios o las expulsiones que dejan a un equipo con
## diez, hay que llamar a `invalidar_fuerza()` al tocar el once. Esta puesta la
## puerta a proposito para que no haya que volver a tocar este bucle.
var _fza_local: Dictionary = {}
var _fza_visita: Dictionary = {}
var _todos: Array[Jugador] = []

## La nota de cada jugador durante el partido, por id. Arranca en 6 -el aprobado
## raso- y se mueve con lo que va haciendo: un gol sube, una roja hunde. Al
## acabar se cierra con el resultado del equipo y pasa al historial.
var _notas: Dictionary = {}
## LO QUE SUMA A LA VALORACIÓN (17-10-2026, M-141), aparte de la nota que mueve
## el resultado: asistencias, remates al arco o al palo, paradas del portero y
## tarjetas. Se apunta escuchando las propias señales del partido (sirve igual
## con el motor real y con la simulación) y NO usa `Azar`.
var _aportes: Dictionary = {}
var _titulares: Dictionary = {}

## `Previa.arbitro_de()`: {"nombre", "perfil", "descripcion"}. Se calcula UNA
## vez en `preparar()`, no en cada minuto -el hash es el mismo durante los
## noventa minutos, y no hay motivo para repetirlo-.
var arbitro: Dictionary = {}

# ---------------------------------------------------------------------------
#  LO QUE PUEDE HACER EL ENTRENADOR MIENTRAS SE JUEGA
# ---------------------------------------------------------------------------

## Cinco cambios, como en el HTML y como en el reglamento actual.
const MAX_CAMBIOS := 5

var cambios_local: int = 0
var cambios_visita: int = 0

## Los penales de una eliminatoria. Cinco cada uno y muerte súbita; la
## probabilidad de acertar (0,76) es la del HTML.
##
## No se resuelven con una moneda al aire a propósito: la tanda tiene que poder
## contarse tiro a tiro, porque es lo que hace que una eliminatoria se recuerde.
##
## MEMOIZADO. `partido_vivo.gd` puede resolverlos en directo en cuanto termina
## el partido, y `Copa.jugar_ronda()` los vuelve a pedir después, al avanzar la
## semana, sobre ese MISMO objeto -para saber quién pasa de ronda-. Sin caché
## cada llamada tiraba los penales de nuevo, y el visor podía anunciar un
## ganador que la tabla de la copa contradecía al ratito: el mismo bug que ya
## costó una depuración con `Liga.jugar_jornada(ya_jugado)`.
var _penales: Array = []
## true si la tanda se jugó en el césped (motor real): nadie la vuelve a sortear.
var penales_en_cesped := false

## EL ÚLTIMO PARTIDO DE TU CLUB, con su crónica (goles, minutos, autores):
## para que la Tribuna comente jugadas concretas (fase 5, «termómetro real»).
static var ultimo_mio: Dictionary = {}

## Cierra las notas de un partido MIRADO (en vivo o en 3D), que no pasa por
## `simular()`. Usa `valoraciones()` (la misma nota que ve el jugador en el
## resumen) y no tira del `Azar`, así no mueve el resto de la partida. Una sola
## vez por partido.
var _notas_cerradas := false

# ---------------------------------------------------------------------------
#  LA LEY DEL EX Y LA INVASIÓN DE CAMPO
# ---------------------------------------------------------------------------
#
# Dos cosas que pasan DENTRO del partido y que no son números: un futbolista al
# que echaste jugando contra ti, y una grada que se harta.

## Cuánto se agranda un ex contra su antiguo club. Un 12% es mucho para un solo
## jugador y es exactamente el punto: la ley del ex no es una superstición del
## fútbol, es que ese día juega distinto.
const LEY_DEL_EX := 1.12

## Los que fueron tuyos y hoy están enfrente. Se guarda al vender o rescindir,
## no se deduce: `club_formacion` dice dónde se formó, no de dónde lo echaste,
## y son cosas distintas —un canterano vendido a los 19 no tiene nada que
## demostrarte; uno al que rescindiste a los 30, sí—.
static var ex_de_mi_club: Dictionary = {}

# ---------------------------------------------------------------------------

## Cuándo se harta la grada. Minuto 70, perdiendo en casa y con el ánimo por los
## suelos: los tres a la vez, porque una invasión de campo que salta cada dos
## partidos deja de ser una noticia y se vuelve una molestia.
signal invasion_de_campo(minuto: int)

## El club cuya hinchada puede saltar al campo y su ánimo de hoy. Lo fija quien
## juega el partido del usuario (`fijar_hinchada()`); en los partidos del resto
## del mundo queda vacío y nunca hay invasión, igual que antes.
var _hinchada_club: Club = null
var _hinchada_animo := 60

const MINUTO_INVASION := 70
const ANIMO_PARA_INVASION := 30

var invasion_ya: bool = false

func fijar_clima(info: Dictionary) -> void:
	clima_info = info
	clima = Clima.factor(info)
	_f_clima_visita = 1.0 if neutral else Clima.factor_visita(info, visita.pais, local.pais)

func _momentum_push(valor: int, es_local: bool) -> void:
	momentum_eventos.append(valor if es_local else -valor)
	if momentum_eventos.size() > 12:
		momentum_eventos.remove_at(0)

## 50 = parejo, hacia 95 = el local manda del todo, hacia 5 = manda la visita.
func momentum_local() -> int:
	var s := 0
	for x in momentum_eventos:
		s += x
	return clampi(50 + s * 6, 5, 95)

static func limpiar_contexto() -> void:
	ctx_factor_tarjetas = 1.0
	ctx_medico = null
	ctx_club_id = ""
	ctx_anio = 0
	ctx_semana = 0
	ctx_lesion_local = 1.0

## ¿Este jugador tiene cuentas pendientes con el club de enfrente?
func es_ex_de(j: Jugador, rival: Club) -> bool:
	return rival != null and String(ex_de_mi_club.get(j.id, "")) == rival.id

func _media_linea(once: Array[Jugador], grupo: String) -> float:
	var suma := 0.0
	var n := 0
	for j in once:
		if Datos.grupo(j.pos_e) != grupo:
			continue
		## LA ARENGA. Si le has gritado desde la banda y todavía le dura, rinde un
		## 12% más. Va AQUÍ dentro y no como un bono al equipo porque el efecto es
		## de UNO: arengar al lateral que se está hundiendo no es lo mismo que
		## arengar a todos, y esa diferencia es toda la mecánica.
		## EL «BLOQUE» DEL ARBOL DEL ENTRENADOR pega aqui.
		##
		## `Entrenamiento.factor_instrucciones()` devolvia un 1,5 que no leia nadie:
		## el nodo que existe PARA que lo que dices en el banquillo se note no se
		## notaba en ninguna parte. Lo que se dice en vivo en este motor es la
		## arenga, asi que es la arenga la que pega mas fuerte.
		var impulso := 1.0
		## LA LEY DEL EX. Un futbolista al que echaste juega hoy contra ti un 12%
		## por encima de lo suyo. Es el unico modificador del motor que no sale de
		## un atributo: sale de una cuenta pendiente.
		var enfrente: Club = visita if once == once_local else local
		if es_ex_de(j, enfrente):
			impulso *= LEY_DEL_EX
		## Y la arenga MULTIPLICA, no sustituye: un ex al que ademas arengas juega
		## con las dos cosas. Asignar aqui en vez de multiplicar borraba la ley del
		## ex en cuanto le gritabas desde la banda.
		if int(impulsos.get(j.id, -1)) > minuto:
			var arenga := ARENGA_BOOST
			if _factor_arenga > 1.0:
				arenga = 1.0 + (ARENGA_BOOST - 1.0) * _factor_arenga
			impulso *= arenga
		## EL PIE. "D.d==='LAT'&&D.b&&j.pie&&D.b!==j.pie" del HTML: un lateral
		## que juega del lado contrario a su pie bueno rinde un 6% menos. Solo
		## pega en los laterales -un central o un delantero zurdo no pierde
		## nada por serlo-. `j.pie()` YA EXISTÍA -no se guarda, sale de un hash
		## estable del id con la misma proporción 76/24 del HTML, a propósito
		## para no sumar un campo persistido nuevo solo para este matiz- pero
		## hasta ahora solo lo leía `aptitud_en()`, usada en un único sitio de
		## la interfaz (la vista "cómo rendiría en otro puesto"): nunca en la
		## fuerza real del partido.
		if Datos.es_lateral(j.pos_e):
			var banda := Datos.banda(j.pos_e)
			if banda != "" and banda != j.pie():
				impulso *= 0.94
		suma += float(j.ovr) * (0.7 + 0.003 * j.forma) * (0.85 + 0.0015 * j.fisico) * (0.9 + 0.002 * j.moral) * impulso
		n += 1
	if n == 0:
		return 50.0
	return suma / float(n)

## Fuerza de ataque y defensa de un once. Los pesos por linea (0.55/0.38/0.07 en
## ataque, 0.5/0.3/0.2 en defensa) son los del HTML.
func fuerza(once: Array[Jugador], c: Club) -> Dictionary:
	var por := _media_linea(once, "POR")
	var defe := _media_linea(once, "DEF")
	var med := _media_linea(once, "MED")
	var del := _media_linea(once, "DEL")
	var ata := del * 0.55 + med * 0.38 + defe * 0.07
	var dfa := defe * 0.5 + por * 0.3 + med * 0.2
	ata *= c.tactica.multiplicador_ataque() * c.bonus_ataque
	dfa *= c.tactica.multiplicador_defensa() * c.bonus_defensa
	## Los rasgos del once suman poco pero suman: es lo que hace que fichar a un
	## killer o a una muralla se note aunque su media no sea la mas alta.
	var killer := 0
	var muralla := 0
	var cerebro := 0
	var veloz := 0
	for j in once:
		match j.rasgo:
			"killer": killer += 1
			"muralla": muralla += 1
			"cerebro": cerebro += 1
			"veloz": veloz += 1
	## LA MODA TACTICA. El dibujo que esta de moda rinde un 5% mas y el que paso
	## de moda un 5% menos. Poco a proposito: tiene que notarse en una temporada
	## larga sin decidir un partido por encima de los jugadores.
	ata *= ctx_moda.get(c.tactica.formacion, 1.0)
	dfa *= ctx_moda.get(c.tactica.formacion, 1.0)
	## Y el videoanalisis, solo para TU club: los otros 383 no ven videos.
	if c.id == ctx_club_id and ctx_analisis > 1.0:
		ata *= ctx_analisis
		dfa *= ctx_analisis
	ata *= 1.0 + 0.012 * killer + 0.008 * veloz + 0.005 * cerebro
	dfa *= 1.0 + 0.012 * muralla + 0.005 * cerebro
	return {"ata": ata, "def": dfa}

## Vuelve a medir los dos onces. Hay que llamarla si cambia alguno.
func invalidar_fuerza() -> void:
	_fza_local = fuerza(once_local, local)
	_fza_visita = fuerza(once_visita, visita)

## Enciende a un jugador. Devuelve "" si se hizo, o el motivo por el que no.
func arengar(j: Jugador) -> String:
	if j == null or terminado_ya:
		return "el partido ya terminó"
	if int(impulsos.get(j.id, -1)) > minuto:
		return "%s ya está encendido" % j.nombre
	impulsos[j.id] = minuto + ARENGA_MINUTOS
	j.cambiar_moral(3, "Partido")
	## Invalidar la fuerza o el subidón no llegaría al marcador hasta el
	## siguiente cambio: sería un botón decorativo.
	invalidar_fuerza()
	return ""

func con_impulso(j: Jugador) -> bool:
	return not terminado_ya and int(impulsos.get(j.id, -1)) > minuto

func _aporte(j: Jugador, v: float) -> void:
	if j != null:
		_aportes[j.id] = float(_aportes.get(j.id, 0.0)) + v

func _aporte_gol(_c: Club, _autor: Jugador, _m: int, asis: Jugador) -> void:
	_aporte(asis, 0.6)

func _aporte_remate(c: Club, autor: Jugador, tipo: String, _m: int) -> void:
	if tipo == "atajada":
		_aporte(autor, 0.2)
		## La parada, para el portero del otro.
		for j in (once_visita if c == local else once_local):
			if j.es_portero():
				_aporte(j, 0.2)
				break
	elif tipo == "poste":
		_aporte(autor, 0.15)
