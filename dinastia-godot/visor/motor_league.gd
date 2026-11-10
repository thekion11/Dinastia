class_name MotorLeague
extends "res://visor/motor_league_p1.gd"
## EL MOTOR DE LEAGUE-SOCCER COMO BASE DEL PARTIDO (10-11-2026, orden del dueño; plan, fases y cifras en
## `docs/04_auditorias/MOTOR_LEAGUE_SOCCER_PLAN.md`). PROTOTIPO detrás de una bandera: `MOTOR_LEAGUE=1` (o
## `MotorLeague.activo = true`); apagada, el partido es exactamente el de siempre (`MotorJugable`).
##
## Qué cambia (el NÚCLEO pasa a ser el de League-Soccer, portado en `LeagueNucleo` y `LeagueEquipo`):
##   - DECISIÓN CON BALÓN: la de su `ElizaController::GetOnTheBallCommands` (cada compañero se puntúa por su situación táctica
##     —espacio delante, espacio propio y cercanía al arco— y por las probabilidades del pase corto, largo o alto; pánico de los
##     defensores; tiro a tres puntos del arco; si no, conducción por campo de fuerzas).
##   - COLOCACIÓN SIN BALÓN: su `TeamAIController::GetAdaptedFormationPosition` (bloque que se estira y se encoge con la posesión
##     que se desvanece, foco en el balón con retardo, línea de la trampa del fuera de juego).
##   - FÍSICA DEL BALÓN SUELTO: su `ApplyBallMotionForces` a paso fijo de 10 ms (independiente de los fps: más determinista).
## Qué se queda (lo NUESTRO montado encima): reglas, saques, faltas, árbitro y VAR, porteros, regates y fintas, la ejecución de
## cada golpeo (`_pasar_a`, `_tirar`, `_patear`: error por atributos, pie malo, clima, animaciones), duelos y cuerpos, el
## control del usuario, las estrategias rápidas y la pizarra (traducidas a sus palancas), cámaras, celebraciones y sonido.

static var activo := OS.get_environment("MOTOR_LEAGUE") == "1"

## La fábrica que usan el estadio y el partido jugable: con la bandera apagada, el motor de siempre.
static func crear() -> MotorJugable:
	return MotorLeague.new() if activo else MotorJugable.new()


# ================================================================== FASE 3: IA SIN BALÓN (10-11)
## Cada jugador sin balón sigue la estrategia de su puesto (L default_def / default_mid / default_off): mezcla de su posición
## de formación estática y la dinámica (roles intercambiados, `MotorRoles`) según lo lejos que está la acción; apoyo por campo
## de fuerzas cuando su equipo tiene la posesión; componente defensiva sobre el rival que marca al hombre; trampa del fuera
## de juego; velocidad «perezosa». Encima, la CAZA del portador (los 3 más cercanos que no marcan a nadie), la PRESIÓN DE ZONA
## al perder el balón (un segundo presionador 0,7-2,3 s), las CARRERAS al espacio y el APOYO ADELANTADO del original.
## Se recalcula cada `CADENCIA` s por jugador (escalonado); entre medias sigue el último destino.

const CADENCIA := 0.1
static var toque_original := OS.get_environment("LS_TOQUE") != "0"   ## LS_TOQUE=0: sin el toque de conducción del original (fase 4c)
static var fase3 := OS.get_environment("LS_FASE3") != "0"   ## LS_FASE3=0: sin la IA sin balón de League (solo la fase 2)
const DIFICULTAD := 0.8            ## L `_default_Difficulty` (la de la CPU se traducirá en la fase 6)
const PRED_MS := [200, 250, 350, 500, 650, 700]
const PRED_TOTAL := 70             ## balón previsto cada 10 ms durante 700 ms (L Ball::Predict)
static var designado_disputa := OS.get_environment("LS_DESIG") == "1"   ## el desvío de la fase 3 (sustituido por la 4a)

var _ls_marca: Array = [{}, {}]       ## por equipo: id propio → id rival marcado al hombre
var _ls_t_marca: Array = [0.0, 0.2]
var _ls_presiona: Array = [{}, {}]    ## L teamPressurePlayer
var _ls_presion_hasta: Array = [0.0, 0.0]
var _ls_zona_hasta: Array = [0.0, 0.0]
var _ls_zona_refresco: Array = [0.0, 0.0]
var _ls_tenia: Array = [false, false]
var _ls_corredor: Array = [{}, {}]    ## L attackingRunPlayer
var _ls_corre_hasta: Array = [0.0, 0.0]
var _ls_t_carrera: Array = [0.0, 0.0]
var _ls_adelantado: Array = [{}, {}]  ## L forwardSupportPlayer
var _ls_t_adelantado: Array = [0.0, 0.0]
var _ls_linea_rival: Array = [0.0, 0.0]   ## línea del fuera de juego del rival (240 ms) que no hay que pasar
var _ls_pred3: PackedVector3Array = PackedVector3Array()   ## balón previsto cada 10 ms (marco League, z arriba)
var cuenta_toques := {"interferir": 0, "barrida": 0}
var _ls_pred: Dictionary = {}         ## ms → posición prevista del balón (marco League)
var _ls_designado: Dictionary = {}    ## L GetDesignatedPossessionPlayer
var _ls_por_id: Dictionary = {}
var _ls_desig_eq: Array = [{}, {}]  ## L Team::GetDesignatedTeamPossessionPlayer: el de cada equipo que antes llega al balón

func _estado_league(delta: float) -> void:
	super(delta)
	_estado_sin_balon(delta)
	if fase3:
		_interferir()

static func _ls3(v: Vector3) -> Vector3:
	return Vector3(v.z, v.x, v.y)

## FASE 4a (10-11): ROBOS POR ALCANCE (L PlayerController::_InterfereCommand y _SlidingCommand + el filtro de animaciones).
## Un defensor que puede ganar el duelo (L CouldWinABallDuelLikeliness: no tener al rival entre él y el balón) entra si una
## animación de interferir (o de barrida, más exigente) toca el balón previsto en su cuadro; el duelo lo resuelve `_entrada`.
func _interferir() -> void:
	if estado != "juego":
		return
	if poseedor.is_empty():
		_cortar_pase()
		return
	var rival: Dictionary = poseedor
	var i := 1 if bool(rival["es_local"]) else 0
	var e: LeagueEquipo = equipos[i]
	var bola: Vector2 = _ls_pred[200]
	var rp := ls(pos(rival)) + ls(rival["vel"]) * 0.1
	for p: Dictionary in jugadores:
		if bool(p["es_local"]) == bool(rival["es_local"]) or bool(p["por"]) or (p == usuario and not autopiloto):
			continue
		if float(p["enfriar"]) > 0.0 or float(p.get("gesto_hasta", 0.0)) > t:
			continue
		var yo := ls(pos(p))
		if yo.distance_to(bola) > 10.0:
			continue
		var mov := ls(p["vel"])
		var a_rival := (rp - (yo + mov * 0.1)).normalized()
		var r_bola := (bola - rp).normalized()
		var gana := 1.0 - (a_rival.dot(r_bola) * 0.5 + 0.5)
		## Se mira HACIA EL BALÓN (simplificado): el original elige la animación girada a la dirección deseada, con giros incluidos.
		var mirada := (bola - yo).normalized()
		var dist_b := (yo + mov * 0.2).distance_to(bola)
		if gana >= 0.7 and e.posesion < 0.6 and dist_b > 0.7 and dist_b < 1.6 \
				and not LeagueToques.alcanza("sliding", yo, mirada, mov.length(), _ls_pred3).is_empty():
			cuenta_toques["barrida"] = int(cuenta_toques["barrida"]) + 1
			_entrada(p, true)
			return
		if gana >= 0.2 and not LeagueToques.alcanza("interfere", yo, mirada, mov.length(), _ls_pred3).is_empty():
			cuenta_toques["interferir"] = int(cuenta_toques["interferir"]) + 1
			_entrada(p, false)
			return

func _equipo_con_balon() -> int:
	if not poseedor.is_empty():
		return 0 if bool(poseedor["es_local"]) else 1
	if not ultimo_toque.is_empty():
		return 0 if bool(ultimo_toque["es_local"]) else 1
	return -1

func _mas_cercano_al(punto: Vector2, local: bool, excluir: Array, cuantos: int) -> Array:
	var c: Array = []
	for q: Dictionary in jugadores:
		if bool(q["es_local"]) == local and not excluir.has(q):
			c.append([(ls(pos(q)) - punto).length_squared(), q])
	c.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	return c.slice(0, cuantos).map(func(x: Array) -> Dictionary: return x[1])

func _estado_sin_balon(_delta: float) -> void:
	_ls_por_id.clear()
	for q: Dictionary in jugadores:
		_ls_por_id[String(q["id"])] = q
	## Balón previsto (L Ball::Predict): con la física portada, o con el portador.
	var bp := balon.position
	var bv := vel_balon
	var cfg := cfg_balon
	_ls_pred3.resize(PRED_TOTAL + 1)
	_ls_pred3[0] = _ls3(bp)
	for k in range(1, PRED_TOTAL + 1):
		if poseedor.is_empty():
			var r := LeagueNucleo.fuerzas_balon(bp, bv, cfg, 0.01, R)
			bp = r[0]; bv = r[1]
			bp += bv * 0.01
		else:
			bp += (poseedor["vel"] as Vector3) * 0.01
		_ls_pred3[k] = _ls3(bp)
	for objetivo_ms: int in PRED_MS:
		var v3 := _ls_pred3[objetivo_ms / 10]
		_ls_pred[objetivo_ms] = Vector2(v3.x, v3.y)
	var b0 := ls(balon.position)
	var mejor := INF
	_ls_designado = poseedor
	if poseedor.is_empty():
		for q: Dictionary in jugadores:
			var d := (ls(pos(q)) - b0).length()
			if d < mejor:
				mejor = d; _ls_designado = q
	var con_balon := _equipo_con_balon()
	for i in 2:
		var local := i == 0
		var d_eq := _mas_cercano_al(_ls_pred[200], local, [], 1)
		_ls_desig_eq[i] = d_eq[0] if not d_eq.is_empty() else {}
		var e: LeagueEquipo = equipos[i]
		var tiene := con_balon == i
		## Línea del fuera de juego del RIVAL a 240 ms (L AI_GetOffsideLine(opp, 240)): no pasarla al apoyar.
		var xs := PackedFloat32Array()
		for q: Dictionary in jugadores:
			if bool(q["es_local"]) != local:
				xs.append(ls(pos(q)).x + ls(q["vel"]).x * 0.24)
		_ls_linea_rival[i] = LeagueEquipo.linea_penultimo(xs, -e.lado, b0.x)
		if t >= float(_ls_t_marca[i]):   ## L CalculateManMarking cada 0,4 s, escalonado por equipo
			_ls_t_marca[i] = t + 0.4
			_ls_marca[i] = _calcular_marcajes(local, e.lado, b0)
		_presion_zona(i, local, e, tiene, b0)
		if tiene:
			_carreras(i, local, e)
		_ls_tenia[i] = tiene

func _calcular_marcajes(local: bool, lado: float, b0: Vector2) -> Dictionary:
	var mios: Array = []
	var rivales: Array = []
	for q: Dictionary in jugadores:
		var fila := [String(q["id"]), ls(pos(q)), ls(q["vel"]), bool(q["por"]), q == poseedor]
		if bool(q["es_local"]) == local:
			mios.append(fila)
		else:
			rivales.append(fila)
	return LeagueSinBalon.marcajes(mios, rivales, lado, b0)

## L TeamAIController: presión de zona al perder el balón y presión de equipo (un segundo presionador).
func _presion_zona(i: int, local: bool, e: LeagueEquipo, tiene: bool, b0: Vector2) -> void:
	var pres := clampf(0.5 + float(_tac(local, "presion") - 1) * 0.35 + float(_tac(local, "tras_perdida") - 1) * 0.25, 0.0, 1.0)   ## L team_pressure
	if bool(_ls_tenia[i]) and not tiene:
		var prim := _mas_cercano_al(b0, local, [], 1)
		var d_prim := (ls(pos(prim[0])) - b0).length() if not prim.is_empty() else 1000.0
		var terr := clampf(b0.x * -e.lado / LeagueNucleo.MEDIO_LARGO, -1.0, 1.0)
		if LeagueReglas.empezar_presion_zona(pres, terr, d_prim):
			_ls_zona_hasta[i] = t + LeagueReglas.duracion_presion_zona(pres)
			_aplicar_presion(i, local, e)
			_ls_zona_refresco[i] = t + 0.25
	if float(_ls_zona_hasta[i]) > 0.0:
		if tiene or t > float(_ls_zona_hasta[i]):
			_ls_zona_hasta[i] = 0.0
			_ls_presion_hasta[i] = t
			_ls_presiona[i] = {}
		elif t >= float(_ls_zona_refresco[i]):
			_aplicar_presion(i, local, e)
			_ls_zona_refresco[i] = t + 0.25

## L ApplyTeamPressure: el más cercano (distancia + castigo por rol) al rival con el balón, sin contar al primer defensor ni al portero.
func _aplicar_presion(i: int, local: bool, e: LeagueEquipo) -> void:
	var previo: Dictionary = _ls_presiona[i] if float(_ls_presion_hasta[i]) > t else {}
	_ls_presion_hasta[i] = t + 0.5
	if poseedor.is_empty() or bool(poseedor["es_local"]) == local:
		_ls_presiona[i] = {}
		return
	var objetivo := ls(pos(poseedor)) + ls(poseedor["vel"]) * 0.24 + Vector2(e.lado * 1.0, 0.0)
	var prim := _mas_cercano_al(ls(balon.position), local, [], 1)
	var mejor := 1000.0
	var nota_previo := 10000.0
	var elegido := {}
	for q: Dictionary in jugadores:
		if bool(q["es_local"]) != local or bool(q["por"]) or (not prim.is_empty() and q == prim[0]):
			continue
		var nota := (ls(pos(q)) - objetivo).length() + (1.0 - LeagueNucleo.mentalidad(_rol(q)))
		if q == previo:
			nota_previo = nota
		if nota < mejor:
			mejor = nota; elegido = q
	if not previo.is_empty() and nota_previo <= mejor + 1.5:
		elegido = previo
	_ls_presiona[i] = elegido

## L TeamAIController::Process: carreras al espacio (cada 0,5 s) y el apoyo adelantado (cada 1,5 s).
func _carreras(i: int, local: bool, e: LeagueEquipo) -> void:
	var portador: Dictionary = poseedor if not poseedor.is_empty() and bool(poseedor["es_local"]) == local else {}
	if portador.is_empty():
		return
	var pp := ls(pos(portador))
	if t >= float(_ls_t_carrera[i]) and t >= float(_ls_corre_hasta[i]):
		_ls_t_carrera[i] = t + 0.5
		var foco := Vector2(pp.x - e.lado * 26.0, pp.y)
		var corredor := {}
		var md := INF
		for q: Dictionary in jugadores:
			if bool(q["es_local"]) == local and not bool(q["por"]) and q != portador and q != usuario:
				var d := (ls(pos(q)) - foco).length()
				if d < md:
					md = d; corredor = q
		if not corredor.is_empty():
			var dist := (ls(pos(corredor)) - pp).length()
			var nota := pow(1.0 - LeagueNucleo.normalizado(dist, 0.0, 40.0), 0.5)
			var sitio := ls(pos(corredor)) * Vector2(1.0, 0.8) + Vector2(-e.lado * 10.0, 0.0)
			var densidad := 1.0
			for r: Dictionary in _mas_cercano_al(sitio, not local, [], 4):
				densidad -= pow(LeagueNucleo.curva(1.0 - LeagueNucleo.normalizado((ls(pos(r)) - sitio).length(), 0.0, 15.0), 1.0), 0.5) * 0.3
			if nota * densidad >= LeagueReglas.umbral_carrera(e.contra):
				_ls_corredor[i] = corredor
				_ls_corre_hasta[i] = t + LeagueReglas.duracion_carrera_ms(e.contra) / 1000.0
	if t >= float(_ls_t_adelantado[i]):
		_ls_t_adelantado[i] = t + 1.5
		var lead := 0.5 + e.contra * 2.0
		var c := _mas_cercano_al(pp + Vector2(-e.lado * lead, 0.0), local, [portador], 1)
		_ls_adelantado[i] = c[0] if not c.is_empty() else {}

func _ia_ataque_sin_balon(p: Dictionary) -> Vector3:
	return _sin_balon(p) if _con_league(p) else super(p)

func _ia_defensa(p: Dictionary) -> Vector3:
	return _sin_balon(p) if _con_league(p) else super(p)

func _con_league(p: Dictionary) -> bool:
	return fase3 and not equipos.is_empty() and estado == "juego" and p.has("ls_forma") and not _ls_pred.is_empty()

func _sin_balon(p: Dictionary) -> Vector3:
	if float(p.get("ls_cortar_hasta", 0.0)) > t and p.has("ls_cortar"):   ## va a cortar el pase (fase 4a)
		p["correr"] = true
		return p["ls_cortar"]
	if float(p.get("ls_t", -1.0)) > t and p.has("ls_obj"):
		p["correr"] = bool(p["ls_corre"])
		return p["ls_obj"]
	p["ls_t"] = t + CADENCIA
	var r := _calcular_sin_balon(p)
	p["ls_obj"] = mundo(r[0])
	p["ls_corre"] = float(r[1]) >= LeagueNucleo.CAMBIO_TROTE_SPRINT
	p["correr"] = bool(p["ls_corre"])
	return p["ls_obj"]

## La estrategia del puesto (L RequestInput de default_def/mid/off) más la caza del portador (L ElizaController). → [destino, velocidad].
func _calcular_sin_balon(p: Dictionary) -> Array:
	var local := bool(p["es_local"])
	var i := 0 if local else 1
	var e: LeagueEquipo = equipos[i]
	var lado := e.lado
	var yo := ls(pos(p))
	var mov := ls(p["vel"])
	var puesto := _rol(p)
	var g := LeagueSinBalon.grupo(puesto)
	var mente := LeagueNucleo.mentalidad(puesto)
	var desig: Dictionary = _ls_designado if not _ls_designado.is_empty() else p
	var dist_accion := (yo - ls(pos(desig))).length()
	## Estática (su casilla) y dinámica (la del dueño de su rol, roles intercambiados con el húngaro de `MotorRoles`).
	var estatica := _destino_forma(p, p["ls_forma"])
	var dueno: Dictionary = _ls_por_id.get(String(MotorRoles.reparto(self as Object as MotorJugable, local).get(String(p["id"]), p["id"])), p)
	var dinamica := estatica if dueno == p or not dueno.has("ls_forma") else _destino_forma(p, dueno["ls_forma"])
	var sb := LeagueSinBalon.sesgo_estatico(g, dist_accion)
	var deseada := estatica * sb + dinamica * (1.0 - sb)
	## Apoyo ofensivo.
	var ab := LeagueSinBalon.sesgo_ataque(g, e.posesion_desvanecida, mente)
	var mio_con: Dictionary = poseedor if not poseedor.is_empty() and bool(poseedor["es_local"]) == local else {}
	if ab > 0.0 and not mio_con.is_empty():
		var corre: bool = ab > float(LeagueSinBalon.ESTRATEGIA[g][5]) and _ls_corredor[i] == p and t < float(_ls_corre_hasta[i])
		var principal := ls(pos(mio_con)) + ls(mio_con["vel"]) * 0.1
		var rivales: Array = []
		for r: Dictionary in _mas_cercano_al(principal * 0.3 + (yo + mov * 0.1) * 0.7, not local, [], 3):
			rivales.append([ls(pos(r)), ls(r["vel"])])
		var mates: Array = []
		for c: Dictionary in _mas_cercano_al(yo + mov * 0.1, local, [p], 5):
			mates.append([ls(pos(c)), ls(c["vel"])])
		var apoyo := LeagueSinBalon.apoyo({"base": deseada, "pos": yo, "mov": mov, "lado": lado, "mente": mente, "puesto": puesto,
			"correr": corre, "adelantado": _ls_adelantado[i] == p, "principal": principal, "es_principal": mio_con == p,
			"rivales": rivales, "companeros": mates, "posesion_desv": e.posesion_desvanecida,
			"balon_pred": [_ls_pred[200], _ls_pred[350], _ls_pred[500], _ls_pred[650]], "linea_offside": _ls_linea_rival[i],
			"red": LeagueReglas.red_apoyo(0.5 + float(_tac(local, "amplitud") - 1) * 0.25)})
		deseada = deseada * (1.0 - ab) + apoyo * ab
	## Componente defensiva sobre su marca y trampa del fuera de juego.
	var marca: Dictionary = _ls_por_id.get(String((_ls_marca[i] as Dictionary).get(String(p["id"]), "")), {})
	if not marca.is_empty():
		var rp := ls(pos(marca)) + ls(marca["vel"]) * 0.5
		deseada = LeagueSinBalon.componente_defensiva(deseada, LeagueSinBalon.sesgo_defensa(g, mente, e.posesion_desvanecida), rp, marca == poseedor, lado, e.trampa_x, yo + mov * 0.14)
	if bool(LeagueSinBalon.ESTRATEGIA[g][7]):
		deseada.x = LeagueNucleo.trampa_offside(deseada.x, lado, e.trampa_x)
	var fresco := clampf(float(p.get("aguante", 1.0)), 0.0, 1.0)
	var vmed := mov.length()
	var trabajo := clampf(float((p["attr"] as Dictionary).get("fis", 0.5)), 0.0, 1.0)
	var rival_con: Dictionary = poseedor if not poseedor.is_empty() and bool(poseedor["es_local"]) != local else {}
	var accion_r := ls(pos(rival_con)) if not rival_con.is_empty() else _ls_pred[200] as Vector2
	var v := LeagueSinBalon.velocidad_perezosa((deseada - yo).length() * LeagueNucleo.DIST_A_VEL, fresco, (yo - accion_r).length(), e.posesion_desvanecida, mente, vmed, trabajo)
	## Caza (solo sin la mejor posesión): el presionador de equipo va al balón; si no marca a nadie y es de los 3 más cercanos, intercepta.
	if _equipo_con_balon() != i and not rival_con.is_empty():
		var op := ls(pos(rival_con)) + ls(rival_con["vel"]) * 0.12
		if _ls_presiona[i] == p and float(_ls_presion_hasta[i]) > t:
			return [op, LeagueNucleo.V_SPRINT]
		var cerca_caza := (op - (yo + mov * 0.04)).length() < LeagueSinBalon.umbral_caza(mente, fresco, vmed, DIFICULTAD)
		## DESVÍO DOCUMENTADO (10-11): el que antes llega al balón de su equipo SIEMPRE disputa (L forceMagnet + extraHaste). En el
		## original solo si no marca a nadie, pero allí además «interfiere» en cuanto el balón entra en el alcance de una animación
		## de entrada (`_InterfereCommand`); nuestras entradas piden estar a ~1,25 m y, sin esto, nadie llegaba a entrar.
		if designado_disputa and cerca_caza and _ls_desig_eq[i] == p:
			return [op, LeagueNucleo.V_SPRINT]
		if marca.is_empty() and cerca_caza:
			if _mas_cercano_al(op - ls(rival_con["vel"]) * 0.02, local, [], 3).has(p):
				var dp := LeagueSinBalon.posicion_defensa(ls(pos(rival_con)), ls(rival_con["vel"]), yo, lado)
				if LeagueSinBalon.necesita_defender(lado, yo, dp):
					return [dp, clampf((dp - yo).length() * LeagueNucleo.DIST_A_VEL, 0.0, LeagueNucleo.V_SPRINT)]
	return [deseada, LeagueNucleo.rango_velocidad(clampf(v, 0.0, LeagueNucleo.V_SPRINT))]

## FASE 4a (10-11): CORTAR EL PASE (L: interferir y controlar sobre el balón en vuelo). Con un pase en camino, el rival que tiene
## una animación de interferir o de control que alcanza el balón previsto va a ese punto (lo marca `ls_cortar`); quién se queda
## el balón lo decide lo nuestro (`_disputas`/`_tomar`) al llegar.
func _cortar_pase() -> void:
	if pase_a.is_empty() or ultimo_toque.is_empty() or Vector2(vel_balon.x, vel_balon.z).length() < 2.0:
		return
	var local_pasa := bool(ultimo_toque["es_local"])
	var bola: Vector2 = _ls_pred[200]
	for p: Dictionary in jugadores:
		if bool(p["es_local"]) == local_pasa or bool(p["por"]) or (p == usuario and not autopiloto) or float(p.get("ls_cortar_hasta", 0.0)) > t:
			continue
		var yo := ls(pos(p))
		if yo.distance_to(bola) > 10.0:
			continue
		var mov := ls(p["vel"])
		var mirada := (bola - yo).normalized()
		for tipo: String in ["interfere", "trap"]:
			var a := LeagueToques.alcanza(tipo, yo, mirada, mov.length(), _ls_pred3)
			if not a.is_empty():
				p["ls_cortar"] = mundo(a["punto"])
				p["ls_cortar_hasta"] = t + float(a["ms"]) / 1000.0 + 0.2
				cuenta_toques["cortar"] = int(cuenta_toques.get("cortar", 0)) + 1
				break

## FASE 4a (10-11): EL RIVAL FASTIDIA LA CONDUCCIÓN (L humanoid_utils.cpp GetBallControlVector, `opponentAnnoyanceFactor`). Con un
## rival a 0,5-1,5 m, a más velocidad y con menos serenidad y equilibrio, el toque se alarga hasta 3 m: el balón se escapa del pie
## y se puede robar o interferir (en el original es la fuente principal de pérdidas al conducir). Serenidad = regate (`reg`, no
## tenemos «calmness»), equilibrio = el nuestro. Solo con el balón en los pies; el balón suelto sigue en la capa 1.
func _mover_balon(delta: float) -> void:
	var c: Dictionary = poseedor
	var toques := int(c.get("toques", 0)) if not c.is_empty() else -1
	super(delta)
	if not fase3 or c.is_empty() or poseedor != c or int(c.get("toques", 0)) == toques or estado != "juego":
		return
	var yo := ls(pos(c))
	var cerca := INF
	for q: Dictionary in jugadores:
		if bool(q["es_local"]) != bool(c["es_local"]):
			cerca = minf(cerca, (ls(pos(q)) - yo).length())
	var vel := (c["vel"] as Vector3).length()
	var fastidio := (1.0 - LeagueNucleo.normalizado(cerca, 0.5, 1.5)) \
		* (1.0 - (float(c["attr"]["reg"]) * 0.5 + float(c.get("equilibrio", 0.6)) * 0.3)) \
		* LeagueNucleo.curva(LeagueNucleo.normalizado(vel, LeagueNucleo.V_PARADO, LeagueNucleo.V_SPRINT), 0.7)
	var plano := Vector3(vel_balon.x, 0.0, vel_balon.z)
	if plano.length() < 0.01:
		return
	if fastidio > 0.0:
		cuenta_toques["fastidio"] = int(cuenta_toques.get("fastidio", 0)) + 1
	if not toque_original:
		## (Fase 4a) solo el fastidio: +3 m de toque como mucho en ~0,5 s.
		if fastidio > 0.0:
			vel_balon += plano.normalized() * fastidio * 3.0 / 0.5
		return
	## FASE 4c (10-11): EL TOQUE DE CONDUCCIÓN DEL ORIGINAL (L humanoid_utils.cpp GetBallControlVector). El balón se deja donde
	## llegará el jugador tras un retardo que crece con la velocidad (L desiredDelayTime = (v/8)²·0,6 + 0,25 s), más el frente del
	## pie y el fastidio del rival (L FFO + opponentAnnoyanceFactor·3). A toda velocidad son toques LARGOS al espacio (~7 m).
	## La dirección es la de su conducción (L desiredMovement: el campo de fuerzas, `objetivo`). La rapidez sale de la distancia
	## con el roce del césped portado (dv/dt = −(k·v² + c), k 0,06, c 1,55 → x = ln(1 + k·v0²/c) / 2k).
	var hacia: Vector3 = (c.get("objetivo", pos(c) + plano) as Vector3) - pos(c)
	hacia.y = 0.0
	var dir := hacia.normalized() if hacia.length() > 0.1 else plano.normalized()
	var retardo := pow(LeagueNucleo.normalizado(vel, 0.0, LeagueNucleo.V_SPRINT), 2.0) * 0.6 + 0.25
	var distancia := vel * retardo + 0.45 + fastidio * 3.0
	var k := float(cfg_balon["roce"])
	var cc := float(cfg_balon["roce_lineal"])
	var v0 := sqrt((exp(2.0 * k * distancia) - 1.0) * cc / k)
	vel_balon = dir * v0
	cuenta_toques["toque_largo"] = int(cuenta_toques.get("toque_largo", 0)) + (1 if distancia > 3.0 else 0)

## FASE 4c (10-11): LOCOMOCIÓN VISUAL DEL ORIGINAL (`LeagueLocomocion`): ciclos de conducir y arranques, frenadas y giros.
func _mover_jugadores(delta: float) -> void:
	super(delta)
	if fase3:
		LeagueLocomocion.paso(self, delta)

## Mientras dura un clip del original o el cuerpo va girado, los ciclos normales no lo pisan; un gesto de verdad sí.
func _anim(p: Dictionary, nombre: String, gesto: bool, dur_max := 1.4) -> void:
	if LeagueLocomocion.bloquea(p, t, nombre, gesto):
		return
	super(p, nombre, gesto, dur_max)
