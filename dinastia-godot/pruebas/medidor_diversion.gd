class_name MedidorDiversion
extends RefCounted
## EL MEDIDOR DE DIVERSIÓN (11-11-2026, sesión 11). Mira un partido paso a paso desde FUERA (sin tocar el motor: lee sus contadores y
## sus señales) y saca cifras de JUGABILIDAD, no de realismo: ocasiones claras, regates y duelos, cadenas de pases, variedad de goles,
## cambios de marcador, juego seguido sin parar, palos y paradas. Lo usa `comparar_tres_motores.gd`; sirve para cualquier motor.
## Uso: `var med := MedidorDiversion.new(motor)`; tras cada `motor.paso(dt)`: `med.observar(dt)`; al final `med.resultado()`.

const AREA := 16.5            ## m del arco: tiro «de área»
const OCASION_RIVAL := 2.5    ## m al rival más cercano: sin presión inmediata
const LEJOS := 20.0           ## m: un gol de más lejos es «de lejos»
const CONTRA_S := 10.0        ## s desde que recupera: un gol así es «de contra»
const PARADO_S := 10.0        ## s desde una falta o un córner: gol «a balón parado»

var m: MotorJugable
var t := 0.0
var goles_tipo := {"cabeza": 0, "penal": 0, "lejos": 0, "contra": 0, "parado": 0, "jugada": 0}
var remates := {"atajada": 0, "poste": 0, "fallo": 0}
var tiros_area := 0
var ocasiones := 0
var cambios_resultado := 0     ## goles que cambian quién gana (empate → ventaja, igualada o remontada)
var remontadas := 0
var robos_duelo := 0           ## el balón cambia de equipo con el nuevo dueño a ≤ 2,5 m de donde estaba el anterior
var perdidas_otras := 0        ## cambia de equipo de lejos (pase cortado, error, balón suelto)
var cadenas: Array = []        ## pases seguidos de cada cadena (mínimo 1)
var tramos: Array = []         ## segundos de juego seguido (estado «juego») sin parar
var t_juego := 0.0
var t_total := 0.0
var paradas_de_juego := 0

var _marc := [0, 0]
var _tiros := [0, 0]
var _tiro := {"d": INF, "clase": "", "t": -99.0, "eq": -1}
var _reanuda := {"tipo": "", "t": -99.0}
var _estado_prev := ""
var _run := 0.0
var _eq := -1                  ## equipo del último poseedor
var _id := ""
var _cadena := 0
var _desde := [-99.0, -99.0]   ## desde cuándo posee cada equipo (por recuperación, no por saque)
var _prev_pos := Vector3.ZERO
var _prev_eq := -1

func _init(motor: MotorJugable) -> void:
	m = motor
	m.gol.connect(_al_gol)
	m.remate.connect(func(_l: bool, _id_: String, tipo: String) -> void:
		remates[tipo] = int(remates.get(tipo, 0)) + 1)

func observar(dt: float) -> void:
	t += dt
	t_total += dt
	_detectar_tiros()
	if m.estado == "juego":
		t_juego += dt
		_run += dt
	elif _run > 0.0:
		tramos.append(_run)
		_run = 0.0
	if m.estado == "saque" and _estado_prev != "saque":
		_reanuda = {"tipo": String((m.saque as Dictionary).get("tipo", "")), "t": t}
		paradas_de_juego += 1
		_cerrar_cadena()
		_eq = -1
		_id = ""
	_estado_prev = m.estado
	_posesion()

func _cerrar_cadena() -> void:
	if _cadena > 0:
		cadenas.append(_cadena)
	_cadena = 0

func _posesion() -> void:
	if m.poseedor.is_empty():
		return
	var eq := 0 if bool(m.poseedor["es_local"]) else 1
	var id := String(m.poseedor["id"])
	var pos: Vector3 = m.pos(m.poseedor)
	if _eq != -1 and eq != _eq:
		_cerrar_cadena()
		if _prev_eq == _eq and Vector2(pos.x - _prev_pos.x, pos.z - _prev_pos.z).length() <= OCASION_RIVAL:
			robos_duelo += 1
		else:
			perdidas_otras += 1
		_desde[eq] = t
	elif _eq == -1:
		_desde[eq] = -99.0   ## viene de un saque: no cuenta como contra
	elif id != _id:
		_cadena += 1
	_eq = eq
	_id = id
	_prev_eq = eq
	_prev_pos = pos

func _detectar_tiros() -> void:
	for eq in 2:
		while int(m.tiros[eq]) > int(_tiros[eq]):
			_tiros[eq] = int(_tiros[eq]) + 1
			var tv: Dictionary = m._tiro_vivo
			if tv.is_empty() or not tv.has("p"):
				continue
			var p: Dictionary = tv["p"]
			var d := m.dir_ataque(bool(p["es_local"]))
			var yo: Vector3 = m.pos(p)
			var dist := Vector2(yo.x, yo.z - d * m.LARGO).length()
			var cerca := INF
			for q: Dictionary in m.jugadores:
				if bool(q["es_local"]) != bool(p["es_local"]):
					cerca = minf(cerca, Vector2(m.pos(q).x - yo.x, m.pos(q).z - yo.z).length())
			var clase := String(tv.get("clase", "pie"))
			_tiro = {"d": dist, "clase": clase, "t": t, "eq": eq}
			if dist <= AREA and absf(yo.x) < 20.0:
				tiros_area += 1
				if clase != "penal" and cerca > OCASION_RIVAL:
					ocasiones += 1

func _al_gol(es_local: bool, _autor: String, _asist: String) -> void:
	_detectar_tiros()
	var eq := 0 if es_local else 1
	var antes := signi(_marc[0] - _marc[1])
	_marc[eq] += 1
	var despues := signi(_marc[0] - _marc[1])
	if despues != antes:
		cambios_resultado += 1
		if antes != 0:
			remontadas += 1
	var reciente := t - float(_tiro["t"]) < 8.0 and int(_tiro["eq"]) == eq
	var tipo := "jugada"
	if reciente and String(_tiro["clase"]) == "penal":
		tipo = "penal"
	elif String(_reanuda["tipo"]) in ["corner", "falta"] and t - float(_reanuda["t"]) < PARADO_S:
		tipo = "parado"
	elif reciente and String(_tiro["clase"]) == "cabeza":
		tipo = "cabeza"
	elif reciente and float(_tiro["d"]) >= LEJOS:
		tipo = "lejos"
	elif t - float(_desde[eq]) <= CONTRA_S:
		tipo = "contra"
	goles_tipo[tipo] = int(goles_tipo[tipo]) + 1

func resultado() -> Dictionary:
	_cerrar_cadena()
	if _run > 0.0:
		tramos.append(_run)
		_run = 0.0
	var largos := 0
	var suma := 0.0
	var maxc := 0
	for c: Variant in cadenas:
		suma += float(c)
		maxc = maxi(maxc, int(c))
		if int(c) >= 5:
			largos += 1
	var tr_suma := 0.0
	var tr_max := 0.0
	for x: Variant in tramos:
		tr_suma += float(x)
		tr_max = maxf(tr_max, float(x))
	var duelos := 0
	for k: String in ["hombro", "dividido", "agarron"]:
		duelos += int(m.duelos.get(k, 0))
	return {
		"ocasiones": ocasiones, "tiros_area": tiros_area,
		"regates": m.regates_ia, "regates_ok": m.regates_ia_ok, "duelos": duelos, "robos_duelo": robos_duelo, "perdidas_otras": perdidas_otras,
		"cadenas": cadenas.size(), "cadena_media": snappedf(suma / maxf(float(cadenas.size()), 1.0), 0.01), "cadena_max": maxc, "cadenas_5": largos,
		"goles_tipo": goles_tipo.duplicate(), "cambios_resultado": cambios_resultado, "remontadas": remontadas,
		"juego_seguido_medio": snappedf(tr_suma / maxf(float(tramos.size()), 1.0), 0.1), "juego_seguido_max": snappedf(tr_max, 0.1),
		"pct_juego": snappedf(100.0 * t_juego / maxf(t_total, 1.0), 0.1), "paradas_de_juego": paradas_de_juego,
		"palos": int(remates.get("poste", 0)), "paradas_portero": int(remates.get("atajada", 0)), "fallos": int(remates.get("fallo", 0)),
	}
