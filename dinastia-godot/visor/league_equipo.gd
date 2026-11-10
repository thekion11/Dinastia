class_name LeagueEquipo
extends RefCounted
## ESTADO POR EQUIPO DE LA IA DE LEAGUE-SOCCER (10-11-2026; L `team.cpp` Team::Process y `teamAIcontroller.cpp` Process).
## Lo que el original lleva en cada equipo y no cabe en una función pura: la POSESIÓN QUE SE DESVANECE (cuánto antes llega
## cada equipo al balón, suavizada a ±0,005 cada 10 ms), el HISTORIAL del balón (las medias de 2, 3, 3,5 y 4 s que mueven el
## bloque), el lado de la posesión de los últimos 6 s y la LÍNEA DE LA TRAMPA del fuera de juego. Todo en el marco de
## `LeagueNucleo` (x = largo, y = ancho). Paso fijo de 10 ms como el original (el motor lo llama con `avanzar`).

const PASO := 0.01
const HISTORIA := 600   ## 6 s de balón a 10 ms (la media más larga que pide League es la del lado de la posesión, 6 s)

var lado := 1.0                     ## signo del arco propio
var posesion := 1.0                 ## L teamPossessionAmount (0,5..1,5 aprox.)
var posesion_desvanecida := 1.0     ## L fadingTeamPossessionAmount
var ofensividad := 0.5              ## L offensivenessBias
var trampa_x := 0.0                 ## L offsideTrapX
var viva: Dictionary = LeagueNucleo.TACTICA_BASE.duplicate()
var contra := 0.5                   ## palanca «counter_attack»
var _resto := 0.0
var _mezclas := {}                  ## puesto → tácticas vivas con sus retoques (se vacía al cambiar las tácticas)
var _t_tactica := 0.0

## Historial compartido (el mismo para los dos equipos): se guarda en el de los locales y el visitante lo lee.
var balon_hist: PackedVector2Array = PackedVector2Array()
var lado_hist: PackedFloat32Array = PackedFloat32Array()

func _init(lado_propio: float) -> void:
	lado = lado_propio

## Sumas acumuladas del historial (se rehacen una vez por paso del motor con `acumular`): cada media sale en O(1).
var acum: PackedVector2Array = PackedVector2Array()

func acumular() -> void:
	acum.resize(balon_hist.size() + 1)
	var s := Vector2.ZERO
	acum[0] = s
	for i in balon_hist.size():
		s += balon_hist[i]
		acum[i + 1] = s

## Media del balón en los últimos `ms` (L Ball::GetAveragePosition), con las sumas de `acumular`.
func media_rapida(ms: float) -> Vector2:
	var total := acum.size() - 1
	var n := mini(total, maxi(1, int(ms / 10.0)))
	if n <= 0:
		return Vector2.ZERO
	return (acum[total] - acum[total - n]) / float(n)

## Media del balón en los últimos `ms` (L Ball::GetAveragePosition), recorriendo el historial.
static func media(hist: PackedVector2Array, ms: float) -> Vector2:
	var n := mini(hist.size(), maxi(1, int(ms / 10.0)))
	if n == 0:
		return Vector2.ZERO
	var s := Vector2.ZERO
	for i in n:
		s += hist[hist.size() - 1 - i]
	return s / float(n)

static func media_f(hist: PackedFloat32Array, ms: float) -> float:
	var n := mini(hist.size(), maxi(1, int(ms / 10.0)))
	if n == 0:
		return 0.0
	var s := 0.0
	for i in n:
		s += hist[hist.size() - 1 - i]
	return s / float(n)

## Guarda el balón y el lado de la posesión (−1/1 o 0) en el historial compartido, a paso fijo de 10 ms.
static func registrar(eq: LeagueEquipo, balon: Vector2, lado_posesion: float, dt: float) -> void:
	eq._resto += dt
	while eq._resto >= PASO:
		eq._resto -= PASO
		eq.balon_hist.append(balon)
		eq.lado_hist.append(lado_posesion)
		if eq.balon_hist.size() > HISTORIA:
			eq.balon_hist = eq.balon_hist.slice(eq.balon_hist.size() - HISTORIA)
			eq.lado_hist = eq.lado_hist.slice(eq.lado_hist.size() - HISTORIA)

## L Team::Process: posesión por tiempo de llegada al balón (ms) y su versión que se desvanece. `dt` real.
func actualizar_posesion(ms_yo: float, ms_rival: float, dt: float) -> void:
	posesion = (ms_rival + 1500.0) / (ms_yo + 1500.0)
	var pasos := maxi(1, int(round(dt / PASO)))
	for i in pasos:
		var tmp := posesion_desvanecida * 0.995 + clampf(posesion, 0.5, 1.5) * 0.005
		posesion_desvanecida = clampf(posesion_desvanecida + clampf(tmp - posesion_desvanecida, -0.005, 0.005), 0.5, 1.5)

## L UpdateTactics (una vez por segundo): marcador, reloj y posesión de los últimos 60 s.
func actualizar_tactica(goles: int, goles_rival: int, t_ms: float, posesion_60: float, usuario: Dictionary, dt: float) -> void:
	_t_tactica -= dt
	if _t_tactica > 0.0:
		return
	_t_tactica = 1.0
	viva = LeagueNucleo.tactica_viva(usuario)
	contra = clampf(float(usuario.get("contra", 0.5)), 0.0, 1.0)
	_mezclas.clear()
	ofensividad = LeagueNucleo.ofensividad(goles, goles_rival, t_ms, posesion_60)

func mezcla_de(puesto: String) -> Dictionary:
	if not _mezclas.has(puesto):
		_mezclas[puesto] = LeagueNucleo.mezclas(viva, puesto, contra)
	return _mezclas[puesto]

## L TeamAIController::Process: la línea que la defensa no cruza hacia atrás. `bola0` y `bola07` = balón ahora y en 0,7 s;
## `rival` = [pos, mov] del rival con la posesión; `linea_propia` = la del penúltimo propio (L AI_GetOffsideLine).
func calcular_trampa(bola0: Vector2, bola07: Vector2, rival: Array, linea_propia: float) -> void:
	var inicio := 30.0 + 20.0 * ofensividad
	var forzado := 6.0
	var peligro := (LeagueNucleo.MEDIO_LARGO - inicio) * lado
	var bx := bola0.x * lado
	var off := 20.0 + 10.0 * (1.0 - ofensividad)
	var sesgo := LeagueNucleo.normalizado(bx, LeagueNucleo.MEDIO_LARGO - inicio - off, LeagueNucleo.MEDIO_LARGO - forzado)
	bx += off * (1.0 - sesgo)
	bx *= lado
	if bx * lado > peligro * lado:
		peligro = bx
	if bola07.x * lado > peligro * lado:
		peligro = bola07.x
	if not rival.is_empty():
		var rp: Vector2 = rival[0]
		var rm: Vector2 = rival[1]
		var cautela := 4.0 * lado
		if (rp.x + rm.x * 0.15 + cautela) * lado > peligro * lado:
			peligro = rp.x + rm.x * 0.1 + cautela
	var holgura := 4.0
	if linea_propia * lado - holgura > peligro * lado:
		peligro = linea_propia - holgura * lado
	trampa_x = peligro

## L AI_GetOffsideLine para el propio equipo: el penúltimo hacia el arco propio (o el balón, si está más atrás).
static func linea_penultimo(xs: PackedFloat32Array, lado_: float, balon_x: float) -> float:
	var a := -INF
	var b := -INF
	for x in xs:
		var v := x * lado_
		if v > a:
			b = a
			a = v
		elif v > b:
			b = v
	var linea := (b if b > -INF else 0.0) * lado_
	if balon_x * lado_ > linea * lado_:
		linea = balon_x
	if linea * lado_ < 0.0:
		linea = 0.01 * -lado_
	return clampf(linea, -LeagueNucleo.MEDIO_LARGO, LeagueNucleo.MEDIO_LARGO)
