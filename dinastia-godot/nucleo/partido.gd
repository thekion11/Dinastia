class_name Partido
extends RefCounted
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
const BASE_ATAQUE := 0.048
const EXPONENTE := 1.6
const REPARTO := 1.9
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
## Lo que la moda tactica le hace a cada dibujo esta temporada. Lo pone `Mundo`
## junto al resto del contexto: `Liga` crea sus partidos por dentro y no conoce
## el mundo.
static var ctx_moda: Dictionary = {}
## Lo que aporta el videoanalisis de esta semana, y a que club. Vale para UN
## partido: `Mundo` lo pone antes de la jornada y lo consume al acabarla.
static var ctx_analisis: float = 1.0

static func limpiar_contexto() -> void:
	ctx_factor_tarjetas = 1.0
	ctx_medico = null
	ctx_club_id = ""
	ctx_anio = 0
	ctx_semana = 0

## Enciende a un jugador. Devuelve "" si se hizo, o el motivo por el que no.
func arengar(j: Jugador) -> String:
	if j == null or terminado_ya:
		return "el partido ya terminó"
	if int(impulsos.get(j.id, -1)) > minuto:
		return "%s ya está encendido" % j.nombre
	impulsos[j.id] = minuto + ARENGA_MINUTOS
	j.moral = clampi(j.moral + 3, 10, 99)
	## Invalidar la fuerza o el subidón no llegaría al marcador hasta el
	## siguiente cambio: sería un botón decorativo.
	invalidar_fuerza()
	return ""

func con_impulso(j: Jugador) -> bool:
	return not terminado_ya and int(impulsos.get(j.id, -1)) > minuto

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

## `Previa.arbitro_de()`: {"nombre", "perfil", "descripcion"}. Se calcula UNA
## vez en `preparar()`, no en cada minuto -el hash es el mismo durante los
## noventa minutos, y no hay motivo para repetirlo-.
var arbitro: Dictionary = {}

func _init(_local: Club, _visita: Club, _neutral: bool = false) -> void:
	local = _local
	visita = _visita
	neutral = _neutral

func preparar() -> void:
	once_local = local.once()
	once_visita = visita.once()
	## `Previa.arbitro_de(rival_id, semana)` -la MISMA que ya usa `vPrevia()`
	## para enseñarlo antes del partido-, no una copia: si se recalculara aparte
	## acá, el árbitro que se anuncia en la previa y el que de verdad pita
	## podrían ser dos personas distintas. Cuando el cruce es tuyo, "rival_id"
	## es el otro club -igual que le pasa `principal.gd` a `Previa`-; entre dos
	## clubes de la IA no hay un "rival" con sentido, así que se usa `visita.id`
	## sin más: solo hace falta que sea determinista, no que sea "el tuyo".
	var rival_id := visita.id
	if local.id == ctx_club_id:
		rival_id = visita.id
	elif visita.id == ctx_club_id:
		rival_id = local.id
	arbitro = Previa.arbitro_de(rival_id, ctx_semana)
	goles_local = 0
	goles_visita = 0
	peor_diferencia_local = 0
	peor_diferencia_visita = 0
	remates_local = 0
	remates_visita = 0
	## Las estadisticas tambien se ponen a cero: `preparar()` se puede llamar
	## dos veces sobre el mismo partido -lo hace `simular()` y lo hace cualquier
	## pantalla que lo rearme-, y sin esto la posesion y los corners se irian
	## acumulando de una simulacion a la siguiente.
	posesion_local = 50.0
	tiros_puerta_local = 0
	tiros_puerta_visita = 0
	xg_local = 0.0
	xg_visita = 0.0
	corners_local = 0
	corners_visita = 0
	faltas_local = 0
	faltas_visita = 0
	fueras_local = 0
	fueras_visita = 0
	cambios_local = 0
	cambios_visita = 0
	minuto = 0
	terminado_ya = false
	cronica.clear()
	_todos = once_local + once_visita
	_notas.clear()
	for j in _todos:
		_notas[j.id] = 6.0
	invalidar_fuerza()

## Vuelve a medir los dos onces. Hay que llamarla si cambia alguno.
func invalidar_fuerza() -> void:
	_fza_local = fuerza(once_local, local)
	_fza_visita = fuerza(once_visita, visita)

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

func simular_minuto() -> void:
	if terminado_ya:
		return
	minuto += 1
	## LOS PLANES SEGÚN EL MARCADOR. A partir del minuto 60 el entrenador aplica
	## lo que dejó preparado: ir a por el partido si va perdiendo, cerrarlo si va
	## ganando. Va en el 60 y no antes porque cambiar el plan en el 20 no es un
	## plan, es nerviosismo. Y solo se aplica UNA VEZ -`_plan_aplicado`- o cada
	## minuto se estaría reescribiendo la táctica sobre sí misma.
	if minuto == 60 and not _plan_aplicado:
		_plan_aplicado = true
		_aplicar_plan()
	var fl := _fza_local
	var fv := _fza_visita
	## Sin empuje de local en cancha neutral: es lo que hace que una final en
	## campo neutro se sienta distinta de una en casa.
	var bono_l := 1.0 if neutral else 1.08
	var bono_v := 1.0 if neutral else 0.94

	var p_l := _probabilidad(fl["ata"], fv["def"]) * bono_l * clima
	var p_v := _probabilidad(fv["ata"], fl["def"]) * bono_v * clima
	## Las instrucciones efímeras solo pegan de TU lado: "riesgo" (todo al
	## ataque) sube tu llegada un 18% y baja tu defensa un 16%; "tiempo"
	## (cerrar el partido) hace justo lo contrario -0.72/1.12-, los mismos
	## factores que `mAtk`/`mDef` en `simularMinuto()` del HTML.
	if instr_riesgo or instr_tiempo:
		var mult_ataque := (1.18 if instr_riesgo else 1.0) * (0.72 if instr_tiempo else 1.0)
		var mult_defensa := (0.84 if instr_riesgo else 1.0) * (1.12 if instr_tiempo else 1.0)
		if local.id == ctx_club_id:
			p_l *= mult_ataque
			p_v /= max(mult_defensa, 0.4)
		elif visita.id == ctx_club_id:
			p_v *= mult_ataque
			p_l /= max(mult_defensa, 0.4)

	## EL CÉSPED. Mismo lado que las instrucciones de arriba -solo pega en TU
	## partido, y solo cuando juegas de local: es tu pasto el que se rompe-.
	if local.id == ctx_club_id and ctx_cesped_local < 1.0:
		p_l *= ctx_cesped_local

	## La posesión no es un dato que el motor lleve: se DEDUCE de quién está
	## llegando más, con la misma media móvil del HTML -6% por minuto, para que
	## no salte de un lado al otro- y sus mismos topes (22-78: ningún partido
	## real acaba 95-5). El ritmo bajo suma porque jugar lento es tener la
	## pelota, que es justo lo que dice `ritmo===0?1.06:1` allá.
	var dominio := p_l / maxf(p_l + p_v, 0.0001)
	var empuje := 1.06 if local.tactica.ritmo == 0 else 1.0
	posesion_local = clampf(posesion_local * 0.94 + dominio * 100.0 * empuje * 0.06, 22.0, 78.0)
	## Córners, faltas y fueras de juego con las probabilidades por minuto del
	## HTML, tal cual. El local saca algún córner más y comete alguna falta
	## menos: no es simetría rota, es la ventaja de campo contada en detalle.
	if Azar.suerte(0.10):
		corners_local += 1
	if Azar.suerte(0.09):
		corners_visita += 1
	if Azar.suerte(0.16):
		faltas_local += 1
	if Azar.suerte(0.17):
		faltas_visita += 1
	if Azar.suerte(0.05):
		fueras_local += 1
	if Azar.suerte(0.05):
		fueras_visita += 1

	if Azar.suerte(p_l):
		_atacar(local, once_local, true)
	if Azar.suerte(p_v):
		_atacar(visita, once_visita, false)

	_incidencias()
	minuto_jugado.emit(minuto)
	if minuto >= MINUTOS:
		terminado_ya = true
		terminado.emit(goles_local, goles_visita)

func _probabilidad(ata: float, def_rival: float) -> float:
	var reparto: float = max((ata + def_rival) / REPARTO, 0.001)
	return BASE_ATAQUE * pow(ata / reparto, EXPONENTE)

## Una llegada al area. Se anota como remate siempre, y solo a veces como gol:
## el resto se reparte entre atajada, palo y fallo con el mismo `r` -un solo
## tiro de dados, como en el HTML, no uno para el gol y otro aparte para el
## resto- para que las proporciones no se descuadren.
func _atacar(c: Club, once: Array[Jugador], es_local: bool) -> void:
	## EL ÁRBITRO, antes que nada: en el HTML sus chequeos van al principio de
	## `ataque()`, sobre CADA llegada, sin que le importe si termina en gol,
	## atajada o fallo -son sucesos aparte, no una consecuencia del remate-.
	_chequeo_arbitral()
	## El xG de cada llegada: entre 0,09 y 0,31, como en el HTML. Sumado a lo
	## largo del partido es lo que permite decir "generamos para tres y metimos
	## uno" sin que sea una impresión, sino un número.
	var xg_de_esta := 0.09 + Azar.f() * 0.22
	if es_local:
		remates_local += 1
		xg_local += xg_de_esta
	else:
		remates_visita += 1
		xg_visita += xg_de_esta
	var r := Azar.f()
	if r < CONVERSION:
		## Un gol es, por definición, un tiro a puerta.
		if es_local:
			tiros_puerta_local += 1
		else:
			tiros_puerta_visita += 1
		_anotar(c, once, es_local)
		return
	var autor := _elegir_goleador(once)
	var tipo := "fallo"
	if r < R_ATAJADA:
		tipo = "atajada"
		## Y una atajada también: el portero solo ataja lo que iba dentro. El
		## palo NO cuenta -pega en el poste, no la para nadie-, igual que en el
		## HTML, que solo hace `puertaMi++` en el gol y en la atajada.
		if es_local:
			tiros_puerta_local += 1
		else:
			tiros_puerta_visita += 1
	elif r < R_POSTE:
		tipo = "poste"
	_momentum_push(1, es_local)
	remate.emit(c, autor, tipo, minuto)

func _anotar(c: Club, once: Array[Jugador], es_local: bool) -> void:
	var autor := _elegir_goleador(once)
	if es_local:
		goles_local += 1
	else:
		goles_visita += 1
	peor_diferencia_local = mini(peor_diferencia_local, goles_local - goles_visita)
	peor_diferencia_visita = mini(peor_diferencia_visita, goles_visita - goles_local)
	if autor != null:
		autor.anotar()
		_notas[autor.id] = minf(float(_notas.get(autor.id, 6.0)) + 1.1, 10.0)
	var asistente := _elegir_asistente(once, autor, minuto) if autor != null else null
	cronica.append({"min": minuto, "tipo": "gol", "club": c.id, "autor": autor.nombre if autor else "?"})
	_momentum_push(2, es_local)
	gol.emit(c, autor, minuto, asistente)

## `_arb`/`registrarFalloArbitro()` del HTML: cada árbitro tiene una personalidad
## y esa personalidad decide cosas por su cuenta -tarjetas de más, un penal que
## no era, un gol que anula por nada-. `ctx_factor_tarjetas` (el "_fVAR" del
## HTML) recorta las probabilidades a la mitad cuando la liga vota VAR, IGUAL
## que recorta las tarjetas normales en `_incidencias()`: el árbitro también
## se cuida más con la cámara encima.
func _chequeo_arbitral() -> void:
	if arbitro.is_empty():
		return
	var f_var := ctx_factor_tarjetas
	var nombre := String(arbitro.get("nombre", ""))
	match String(arbitro.get("perfil", "")):
		"tarjetero":
			if not Azar.suerte(0.010 * f_var):
				return
			var arr := once_local if Azar.suerte(0.5) else once_visita
			_tarjeta_arbitral(arr, "🟨 %s saca otra amarilla: " % nombre)
		"casero":
			if not Azar.suerte(0.008 * f_var):
				return
			## Siempre contra el que visita: es lo que hace "casero" casero.
			_tarjeta_arbitral(once_visita, "🟨 %s cobra para la casa: amarilla a " % nombre)
		"estricto":
			if not Azar.suerte(0.004 * f_var):
				return
			## 55%/45% a tu favor cuando el partido es tuyo -"_favMi" del HTML-;
			## sin nadie a quien favorecer -un cruce entre dos clubes de la IA-
			## se reparte parejo.
			var prob_local := 0.5
			if local.id == ctx_club_id:
				prob_local = 0.55
			elif visita.id == ctx_club_id:
				prob_local = 0.45
			if Azar.suerte(prob_local):
				decision_arbitral.emit("⚽ ¡GOL de penal! %s no dudó en cobrarlo." % nombre, minuto)
				_anotar(local, once_local, true)
			else:
				decision_arbitral.emit("⚽ Penal cobrado en contra. Con %s no se toca a nadie." % nombre, minuto)
				_anotar(visita, once_visita, false)
		"figura":
			if Azar.suerte(0.003 * f_var):
				decision_arbitral.emit(
					"⚖️ %s anula un gol por milímetros. Protestas en las dos bancas." % nombre, minuto)
		_:
			pass   ## "permisivo": no hace nada por su cuenta -deja jugar, es la gracia.

## Reparte una amarilla arbitral igual que `_incidencias()` reparte las
## normales -segunda amarilla con 18% de ir a la roja-, y la narra con la frase
## que le toca a esta personalidad.
func _tarjeta_arbitral(arr: Array[Jugador], frase: String) -> void:
	var j := _alguien(arr)
	if j == null:
		return
	j.amarillas += 1
	var roja := j.amarillas % 2 == 0 and Azar.suerte(0.18)
	if roja:
		j.suspension = maxi(j.suspension, 1)
	decision_arbitral.emit(frase + j.nombre, minuto)
	tarjeta.emit(j, roja, minuto)

## El goleador no se sortea plano: se pondera por lo cerca del area que juega y
## por su pegada. Si se sortea plano, los centrales marcan tanto como los nueves
## y la tabla de goleadores deja de tener sentido.
func _elegir_goleador(once: Array[Jugador]) -> Jugador:
	if once.is_empty():
		return null
	var pesos: Array[float] = []
	var total := 0.0
	for j in once:
		var base := 0.02
		match Datos.grupo(j.pos_e):
			"DEL": base = 1.0
			"MED": base = 0.42
			"DEF": base = 0.11
			"POR": base = 0.004
		base *= 0.5 + float(j.atributos.get("tir", 50)) / 100.0
		pesos.append(base)
		total += base
	var r := Azar.f() * total
	for i in once.size():
		r -= pesos[i]
		if r <= 0.0:
			return once[i]
	return once[once.size() - 1]

## El asistente (18-9-2026), igual de ponderado que el goleador pero por pase
## en vez de por remate -un mediocampista asiste mucho más que un central-.
## PURAMENTE COSMÉTICO: no toca `goles_local/visita`, no toca notas, no toca
## nada que ya decidiera el resultado del partido (eso ya pasó antes de
## llegar aquí). Solo alimenta la crónica y, vía `gol.emit()`, la
## dramatización 3D (`estadio.gd::_al_gol()` → `MatchPlayback::_jugada_gol()`),
## que hasta esta pieza no tenía forma de saber quién había dado el pase.
##
## NO USA `Azar`: esta es LA MISMA trampa que ya se pagó una vez con un feed
## cosmético y que `Sonido` documenta al elegir variante -si algo cosmético
## consume un número del generador determinista de la partida, todo lo que se
## sortea DESPUÉS (el próximo remate, la próxima tarjeta) sale corrido, y una
## temporada entera deja de ser reproducible por culpa de un dato que nadie
## mira dos veces. Se prueba: sin este cambio, `_probar_partidos()` medía un
## resultado distinto (137 vs 138 locales ganadores) solo por haber agregado
## esta elección -precisamente la prueba que existe para cazarlo-. Una
## semilla propia, derivada del propio gol (autor + minuto), es determinista
## sin tocar el generador compartido.
func _elegir_asistente(once: Array[Jugador], autor: Jugador, minuto: int) -> Jugador:
	var candidatos: Array[Jugador] = []
	for j in once:
		if j != autor:
			candidatos.append(j)
	if candidatos.is_empty():
		return null
	var pesos: Array[float] = []
	var total := 0.0
	for j in candidatos:
		var base := 0.05
		match Datos.grupo(j.pos_e):
			"MED": base = 1.0
			"DEL": base = 0.55
			"DEF": base = 0.22
			"POR": base = 0.02
		base *= 0.5 + float(j.atributos.get("pas", 50)) / 100.0
		pesos.append(base)
		total += base
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(autor.id if autor != null else "") + "_" + str(minuto))
	var r := rng.randf() * total
	for i in candidatos.size():
		r -= pesos[i]
		if r <= 0.0:
			return candidatos[i]
	return candidatos[candidatos.size() - 1]

## Tarjetas y lesiones. Las probabilidades por minuto salen de las del HTML
## repartidas sobre los 90: ~2,8 amarillas y ~0,2 lesiones por partido.
func _incidencias() -> void:
	## EL VAR RECORTA LAS TARJETAS. `Federacion.factor_tarjetas()` devolvia un 0,5
	## que no leia nadie: la asamblea podia votar el videoarbitraje y en el campo
	## se sacaban exactamente las mismas amarillas. Con video se protesta menos y
	## se inventan menos faltas, que es justo lo que el HTML llamaba `_fVAR`.
	if Azar.suerte(0.031 * ctx_factor_tarjetas):
		var l := _alguien(_todos)
		if l != null:
			l.amarillas += 1
			var roja := l.amarillas % 2 == 0 and Azar.suerte(0.18)
			if roja:
				l.suspension = max(l.suspension, 1)
			tarjeta.emit(l, roja, minuto)
	if Azar.suerte(0.0024):
		var h := _alguien(_todos)
		if h != null:
			## LA LESION LA DIAGNOSTICA `Medico`, no un numero suelto.
			##
			## Antes se sorteaban de una a ocho semanas aqui mismo y no se pasaba por
			## el parte medico: la lesion no tenia nombre, no entraba en el historial
			## y `severidad_en_partido()` -escrita para esto exactamente- no la
			## llamaba nadie. Ahora la lesion del campo es la misma que la del parte.
			var semanas := 0
			if ctx_medico != null and h.club_id == ctx_club_id:
				semanas = ctx_medico.lesionar(h, ctx_medico.severidad_en_partido(),
					"lesión en partido", ctx_anio, ctx_semana)
			else:
				semanas = Azar.ent(1, 8)
				if h.rasgo == "fragil":
					semanas += Azar.ent(1, 3)
				h.lesionar(semanas)
			lesion.emit(h, semanas, minuto)

# ---------------------------------------------------------------------------
#  LO QUE PUEDE HACER EL ENTRENADOR MIENTRAS SE JUEGA
# ---------------------------------------------------------------------------

## Cinco cambios, como en el HTML y como en el reglamento actual.
const MAX_CAMBIOS := 5

var cambios_local: int = 0
var cambios_visita: int = 0

## Mete a `entra` por `sale`. Devuelve por qué no se pudo, o cadena vacía si se
## hizo: quien llama necesita poder decírselo al jugador, no adivinarlo.
##
## Después de tocar el once hay que volver a medirlo. La fuerza está cacheada
## porque no cambia durante los noventa minutos, y un cambio es justo la
## excepción: sin `invalidar_fuerza()` el equipo seguiría jugando con la fuerza
## del once que ya no está en el campo, y el cambio no serviría para nada.
func cambiar(sale: Jugador, entra: Jugador) -> String:
	var es_local := once_local.has(sale)
	if not es_local and not once_visita.has(sale):
		return "%s no está en el campo" % sale.nombre
	var hechos := cambios_local if es_local else cambios_visita
	if hechos >= MAX_CAMBIOS:
		return "ya no quedan cambios"
	if not entra.disponible():
		return "%s no está en condiciones de entrar" % entra.nombre
	if once_local.has(entra) or once_visita.has(entra):
		return "%s ya está jugando" % entra.nombre
	var once := once_local if es_local else once_visita
	once[once.find(sale)] = entra
	if es_local:
		cambios_local += 1
	else:
		cambios_visita += 1
	_todos.append(entra)
	invalidar_fuerza()
	cronica.append({"min": minuto, "tipo": "cambio", "sale": sale.nombre, "entra": entra.nombre})
	cambio_hecho.emit(sale, entra, minuto)
	return ""

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

func penales() -> Array:
	if not _penales.is_empty():
		return _penales
	var l := 0
	var v := 0
	for i in 5:
		if Azar.suerte(0.76): l += 1
		if Azar.suerte(0.76): v += 1
	while l == v:
		if Azar.suerte(0.76): l += 1
		if Azar.suerte(0.76): v += 1
	cronica.append({"min": minuto, "tipo": "penales", "local": l, "visita": v})
	_penales = [l, v]
	return _penales

func _alguien(l: Array[Jugador]) -> Jugador:
	if l.is_empty():
		return null
	return l[Azar.ent(0, l.size() - 1)]

## Juega el partido entero de una vez. Es lo que usa la simulacion de temporadas
## y el banco de pruebas; en pantalla se llama a simular_minuto() con un reloj.
func simular() -> Dictionary:
	preparar()
	while not terminado_ya:
		simular_minuto()
	_cerrar_notas()
	return {"local": goles_local, "visita": goles_visita}

func _to_string() -> String:
	return "%s %d-%d %s" % [local.nombre, goles_local, goles_visita, visita.nombre]

## ¿Ganó `c` este partido después de haber estado tres goles abajo o más en
## algún momento? El logro oculto "remontada" (`Logros.marcar()`), que la
## propia tabla del HTML prometía -"Ganar un partido yendo tres goles
## abajo"- sin que nada en `juego.js` lo activara jamás: bug del original, no
## del porte, y se cierra aquí en vez de dejarlo matemáticamente imposible.
func hubo_remontada_de(c: Club) -> bool:
	if c == local:
		return goles_local > goles_visita and peor_diferencia_local <= -3
	if c == visita:
		return goles_visita > goles_local and peor_diferencia_visita <= -3
	return false

## Cierra las notas del partido y actualiza la forma.
##
## Portado del HTML: la nota base se mueve con el resultado del EQUIPO (+0,6 si
## ganas, -0,6 si pierdes) mas un margen de azar, y despues la forma se arrastra
## hacia esa nota con un 30% de peso. Eso es lo que hace que una racha se note en
## la forma sin que un solo partido malo hunda a nadie.
##
## Se llama al terminar, no minuto a minuto: una nota a mitad de partido no
## significa nada y ademas el resultado todavia no se sabe.
func _cerrar_notas() -> void:
	var gano_local := goles_local > goles_visita
	var empate := goles_local == goles_visita
	for j in _todos:
		var suyo := once_local.has(j)
		var bono := 0.0
		if not empate:
			bono = 0.6 if (gano_local == suyo) else -0.6
		var n: float = clampf(float(_notas.get(j.id, 6.0)) + bono + Azar.f() * 1.4 - 0.7, 3.0, 10.0)
		n = round(n * 10.0) / 10.0
		j.anotar_nota(n)
		j.forma = clampi(int(round(float(j.forma) * 0.7 + n * 10.0 * 0.3)), 20, 99)
		j.partidos += 1

## La nota de un jugador en este partido, para poder pintarla en directo.
func nota_de(j: Jugador) -> float:
	return float(_notas.get(j.id, 6.0))

## Aplica el plan que el entrenador dejó preparado para cómo vaya el marcador.
## Solo el club del jugador: los otros 383 ya tienen su propio automático, y
## simular la cabeza de 383 entrenadores sería gastar en algo que nadie ve.
func _aplicar_plan() -> void:
	for c in [local, visita]:
		if c == null or c.tactica == null:
			continue
		var mia: int = goles_local if c == local else goles_visita
		var suya: int = goles_visita if c == local else goles_local
		var cambio: Dictionary = c.tactica.plan_para(mia - suya)
		if cambio.is_empty():
			continue
		c.tactica.mentalidad = int(cambio["mentalidad"])
		c.tactica.linea = int(cambio["linea"])
		## Cambiar la táctica invalida la fuerza cacheada: sin esto el cambio se
		## guardaría pero el partido seguiría midiendo con los números viejos, y
		## el plan sería un adorno. Es la misma razón por la que `cambiar()` la
		## invalida al hacer una sustitución.
		invalidar_fuerza()

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

static func marcar_ex(j: Jugador, club_id: String) -> void:
	if j == null or club_id == "":
		return
	ex_de_mi_club[j.id] = club_id

## ¿Este jugador tiene cuentas pendientes con el club de enfrente?
func es_ex_de(j: Jugador, rival: Club) -> bool:
	return rival != null and String(ex_de_mi_club.get(j.id, "")) == rival.id

# ---------------------------------------------------------------------------

## Cuándo se harta la grada. Minuto 70, perdiendo en casa y con el ánimo por los
## suelos: los tres a la vez, porque una invasión de campo que salta cada dos
## partidos deja de ser una noticia y se vuelve una molestia.
const MINUTO_INVASION := 70
const ANIMO_PARA_INVASION := 30

var invasion_ya: bool = false

## Devuelve true si la grada acaba de invadir el campo. Lo mira el partido en
## vivo para parar el reloj y abrir el vestuario.
func chequear_invasion(animo: int, soy_local: bool, voy_perdiendo: bool) -> bool:
	if invasion_ya or terminado_ya:
		return false
	if minuto < MINUTO_INVASION or not soy_local or not voy_perdiendo:
		return false
	if animo > ANIMO_PARA_INVASION:
		return false
	## Una de cada cinco, aun cumpliendo las tres condiciones. Si fuera segura,
	## bastaría con ir perdiendo en casa para saber lo que va a pasar.
	if not Azar.suerte(0.2):
		return false
	invasion_ya = true
	## A los dos equipos se les caen las piernas: el frío de veinte minutos
	## parados con la policía en el campo no distingue de camisetas.
	for j in _todos:
		j.fisico = clampi(j.fisico - Azar.ent(3, 8), 10, 100)
		j.moral = clampi(j.moral - Azar.ent(2, 6), 10, 99)
	return true
