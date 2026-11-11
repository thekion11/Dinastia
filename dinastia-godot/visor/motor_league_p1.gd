extends MotorJugable
## [Capa 1/2 de `motor_league.gd`] núcleo con balón, colocación, balón suelto y estado de equipo (fase 2). Cabecera completa en `motor_league.gd`.

const REACCION := 0.25        ## s entre decisiones del portador (L reacción del controlador, 100-300 ms)
const CONTROL := 0.3          ## s de control antes de poder soltarla (L: el muñeco necesita el toque de control)
const PASO_BALON := 0.01      ## L Ball: 10 ms

var equipos: Array = []       ## [LeagueEquipo local, LeagueEquipo visita]
var cfg_balon: Dictionary = LeagueNucleo.config_balon()
var cuenta := {"pase": 0, "panico": 0, "tiro": 0, "conducir": 0}
var _posee_id := ""
var _posee_desde := 0.0
var _resto_balon := 0.0
var _decision_league := 0.0
var _lado_medio := 0.0

static func ls(v: Vector3) -> Vector2:
	return Vector2(v.z, v.x)

static func mundo(v: Vector2, y := 0.0) -> Vector3:
	return Vector3(v.y, y, v.x)

static func lado_de(local: bool) -> float:
	return -dir_ataque(local)

func preparar(lista: Array, ball: Node3D, jugador_usuario_id: String, semilla: int = 1) -> void:
	super(lista, ball, jugador_usuario_id, semilla)
	LeagueLocomocion.precargar()   ## (11-11) las bibliotecas y el catálogo, antes del saque: sin tirón en el primer toque
	equipos = [LeagueEquipo.new(lado_de(true)), LeagueEquipo.new(lado_de(false))]
	_formas()

## La formación en el marco de League (x −1 atrás .. 1 delante, y −1..1 a lo ancho), sacada de la posición base de cada uno.
func _formas() -> void:
	for local: bool in [true, false]:
		var d := dir_ataque(local)
		var zmin := INF
		var zmax := -INF
		for p: Dictionary in jugadores:
			if bool(p["es_local"]) == local and not bool(p["por"]):
				var z := (p["base_pos"] as Vector3).z * d
				zmin = minf(zmin, z)
				zmax = maxf(zmax, z)
		for p: Dictionary in jugadores:
			if bool(p["es_local"]) != local:
				continue
			var b: Vector3 = p["base_pos"]
			var fx := -1.0 if bool(p["por"]) else lerpf(-0.75, 0.9, (b.z * d - zmin) / maxf(zmax - zmin, 1.0))
			p["ls_forma"] = Vector2(fx, clampf(b.x / 28.0, -1.0, 1.0) * -lado_de(local))

func paso(delta: float) -> void:
	if delta <= 0.1 and estado == "juego" and not equipos.is_empty():
		_estado_league(delta)
	super(delta)

func _ms_al_balon(local: bool) -> float:
	var mejor := INF
	var b := ls(balon.position)
	for p: Dictionary in jugadores:
		if bool(p["es_local"]) == local:
			mejor = minf(mejor, (ls(pos(p)) - b).length() / 7.0 * 1000.0)
	return mejor if mejor < INF else 5000.0

func _estado_league(delta: float) -> void:
	if not poseedor.is_empty():
		if String(poseedor["id"]) != _posee_id:
			_posee_id = String(poseedor["id"])
			_posee_desde = t
	else:
		_posee_id = ""
	var ml := _ms_al_balon(true)
	var mv := _ms_al_balon(false)
	var e0: LeagueEquipo = equipos[0]
	var e1: LeagueEquipo = equipos[1]
	e0.actualizar_posesion(ml, mv, delta)
	e1.actualizar_posesion(mv, ml, delta)
	## L Match::Process: el «lado de la posesión» es la suma de (posesión desvanecida − 0,5) · lado de cada equipo.
	var lado_pos := (e0.posesion_desvanecida - 0.5) * e0.lado + (e1.posesion_desvanecida - 0.5) * e1.lado
	LeagueEquipo.registrar(e0, ls(balon.position), lado_pos, delta)
	e0.acumular()
	_lado_medio = LeagueEquipo.media_f(e0.lado_hist, 6000.0)
	var tot: float = float(posesion[0]) + float(posesion[1])
	for i in 2:
		var e: LeagueEquipo = equipos[i]
		var p60: float = (float(posesion[i]) / tot) if tot > 0.0 else 0.5
		e.actualizar_tactica(goles[i], goles[1 - i], (minuto() * 60000.0), p60, _palancas(i == 0), delta)
		var xs := PackedFloat32Array()
		for q: Dictionary in jugadores:
			if bool(q["es_local"]) == (i == 0):
				xs.append(ls(pos(q)).x)
		var rival: Array = []
		if not poseedor.is_empty() and bool(poseedor["es_local"]) != (i == 0):
			rival = [ls(pos(poseedor)), ls(poseedor["vel"])]
		var b0 := ls(balon.position)
		e.calcular_trampa(b0, b0 + ls(vel_balon) * 0.7, rival, LeagueEquipo.linea_penultimo(xs, e.lado, b0.x))

## La pizarra del club (`Tactica`, 0..2 con 1 = neutro; ver `EstiloClub`) traducida a las palancas de League (0..1, 0,5 = neutro):
## amplitud → anchura del bloque; presión → foco defensivo del bloque y del medio; mentalidad → foco del medio en ataque;
## verticalidad → contraataque (carreras y apoyo adelantado); ritmo → regate ofensivo; amplitud (al revés) → imán al centro al
## conducir. (La presión de zona usa presión + «tras la pérdida»; la línea mueve el bloque ±4 m; ver `_destino_forma`.)
func _palancas(local: bool) -> Dictionary:
	var amp := float(_tac(local, "amplitud") - 1)
	var pre := float(_tac(local, "presion") - 1)
	var men := float(_tac(local, "mentalidad") - 1)
	return {"ow": 0.5 + amp * 0.5, "dw": 0.5 + amp * 0.5, "dmi": 0.5 + pre * 0.5, "dm": 0.5 + pre * 0.5,
		"om": 0.5 + men * 0.5, "omi": 0.5 + men * 0.25, "contra": 0.5 + float(_tac(local, "verticalidad") - 1) * 0.4}

## L dribble_offensiveness y dribble_centermagnet.
func _regate_palancas(local: bool) -> Vector2:
	return Vector2(clampf(0.5 + float(_tac(local, "ritmo") - 1) * 0.4, 0.0, 1.0), clampf(0.5 - float(_tac(local, "amplitud") - 1) * 0.4, 0.0, 1.0))

# ------------------------------------------------------------------ colocación

func _forma(p: Dictionary, en_posesion: bool) -> Vector3:
	if equipos.is_empty() or not p.has("ls_forma") or estado != "juego":
		return super(p, en_posesion)
	return mundo(_destino_forma(p, p["ls_forma"]))

## Destino de formación (marco League) de `p` con la casilla `forma` (la suya = estática; la del dueño de su rol = dinámica).
func _destino_forma(p: Dictionary, forma: Vector2) -> Vector2:
	var local := bool(p["es_local"])
	var e: LeagueEquipo = equipos[0 if local else 1]
	var e0: LeagueEquipo = equipos[0]
	var foco_p: Dictionary = poseedor if not poseedor.is_empty() else ultimo_toque
	var foco := ls(pos(foco_p)) if not foco_p.is_empty() else ls(balon.position)
	var yo := ls(pos(p))
	var urg := 1.0 - LeagueNucleo.normalizado((foco - yo).length(), 2.0, 30.0)
	var entrada := {"forma": forma, "puesto": _rol(p), "lado": e.lado, "pos": yo, "foco": foco,
		"balon_x_lento": e0.media_rapida(3500.0 * (1.0 - urg * 0.7)).x,
		"balon_y_lento": e0.media_rapida(4000.0 * (1.0 - urg * 0.5)).y,
		"balon_3s": e0.media_rapida(3000.0), "balon_2s": e0.media_rapida(2000.0),
		"posesion_desvanecida": e.posesion_desvanecida,
		"lado_posesion_medio": _lado_medio,
		"ofensividad": clampf(e.ofensividad + float(_tac(local, "mentalidad") - 1) * 0.15, 0.0, 1.0),
		"viva": e.viva, "contra": e.contra, "mezcla": e.mezcla_de(_rol(p)), "trampa_x": e.trampa_x}
	var r := LeagueNucleo.posicion_formacion(entrada)
	r.x += -e.lado * float(_tac(local, "linea") - 1) * 4.0   ## la línea de la pizarra adelanta o retrasa el bloque
	return r

# ------------------------------------------------------------------ con balón

func _imagenes_rivales(local: bool) -> Array:
	var r: Array = []
	for q: Dictionary in jugadores:
		if bool(q["es_local"]) != local:
			r.append([ls(pos(q)), ls(q["vel"]), bool(q["por"])])
	return r

func _ia_portador(p: Dictionary) -> void:
	if equipos.is_empty() or bool(p["por"]) or estado != "juego":
		super(p)
		return
	var local := bool(p["es_local"])
	var e: LeagueEquipo = equipos[0 if local else 1]
	var yo := ls(pos(p))
	var mov := ls(p["vel"])
	var rivales := _imagenes_rivales(local)
	var n: Node3D = p["node"]
	var mirada := Vector2(cos(n.rotation.y), sin(n.rotation.y))   ## (z, x) del frente del modelo
	## Conducción por el campo de fuerzas, siempre (el original la recalcula cada ciclo).
	var cercanos := rivales.duplicate()
	cercanos.sort_custom(func(a: Array, b: Array) -> bool: return ((a[0] as Vector2) - yo).length_squared() < ((b[0] as Vector2) - yo).length_squared())
	var rp := _regate_palancas(local)
	var rg := LeagueNucleo.regate(yo, mov, mirada, e.lado, cercanos.slice(0, 5), LeagueNucleo.mentalidad(_rol(p)), rp.x, rp.y)
	p["objetivo"] = mundo(yo + (rg[0] as Vector2) * 6.0)
	p["correr"] = float(rg[1]) >= LeagueNucleo.V_SPRINT
	var rival := _rival_mas_cercano(p)
	var arco := _arco_rival(p)
	if _intentar_regate(p, rival, Vector2(pos(p).x - arco.x, pos(p).z - arco.z).length()):   ## las fintas son nuestras
		return
	if t - _posee_desde < CONTROL or t < _decision_league:
		return
	_decision_league = t + REACCION
	var yo_d := {"pos": yo, "mov": mov, "lado": e.lado, "puesto": _rol(p), "tec_pase": float(p["attr"]["pas"]),
		"tec_tiro": float(p["attr"]["tir"]), "posee_ms": (t - _posee_desde) * 1000.0, "sit": LeagueNucleo.situacion(yo, mov, e.lado, rivales)}
	var mates: Array = []
	for q: Dictionary in jugadores:
		if q != p and bool(q["es_local"]) == local:
			var qp := ls(pos(q))
			mates.append({"i": q, "pos": qp, "mov": ls(q["vel"]), "puesto": _rol(q), "sit": LeagueNucleo.situacion(qp, ls(q["vel"]), e.lado, rivales)})
	var dec := LeagueNucleo.decidir(yo_d, mates, rivales, ls(vel_balon), e.posesion, _rng, int(REACCION / 0.01))
	_ejecutar(p, dec, mirada, e.lado)

func _ejecutar(p: Dictionary, dec: Dictionary, mirada: Vector2, lado: float) -> void:
	var accion := String(dec["accion"])
	cuenta[accion] = int(cuenta[accion]) + 1
	var d_arco := Vector2(pos(p).x, pos(p).z - _arco_rival(p).z).length()   ## diagnóstico: a qué distancia del arco rival se decide
	var tramo := "d<20" if d_arco < 20.0 else ("d20_35" if d_arco < 35.0 else ("d35_55" if d_arco < 55.0 else "d55+"))
	cuenta[tramo] = int(cuenta.get(tramo, 0)) + 1
	if bool(dec.get("zona", false)):   ## diagnóstico de la fase 4b: decisiones en zona de tiro y tiros que la cola dejó detrás
		cuenta["en_zona"] = int(cuenta.get("en_zona", 0)) + 1
		if accion != "tiro" and (dec.get("cola", []) as Array).any(func(x: Dictionary) -> bool: return String(x["accion"]) == "tiro"):
			cuenta["tiro_detras"] = int(cuenta.get("tiro_detras", 0)) + 1
	match accion:
		"pase":
			## L AI_GetPass: el pase LARGO va al espacio (+0,2 × la distancia hacia el arco rival); aquí, nuestro «al hueco».
			_pasar_a(p, dec["i"], int(dec["tipo"]) != LeagueNucleo.CORTO, int(dec["tipo"]) == LeagueNucleo.LARGO)
		"tiro":
			_tirar(p, Vector2(clampf(float(dec["y"]) / (PALO - 0.35), -1.0, 1.0), -0.45 if _rng.randf() < 0.6 else 0.55), clampf(float(dec["potencia"]), 0.0, 1.0))
		"panico":
			var dir := LeagueNucleo.dir_panico(mirada, lado)
			_ctx_golpeo = "despeje"
			_patear(p, pos(p) + mundo(dir * 30.0), LeagueNucleo.vel_pase(0.7) * 0.6, 4.0, 0.0, "patear")
			despejes[0 if bool(p["es_local"]) else 1] += 1

# ------------------------------------------------------------------ balón suelto

func _mover_balon(delta: float) -> void:
	if not poseedor.is_empty() or equipos.is_empty():
		super(delta)
		return
	var antes := balon.position
	var p := antes
	_resto_balon += delta
	while _resto_balon >= PASO_BALON:
		_resto_balon -= PASO_BALON
		var en_aire := p.y > R + 0.02 or absf(vel_balon.y) > 0.2
		if en_aire:   ## el efecto (Magnus) de nuestros golpeos se mantiene encima
			vel_balon += giro_balon.cross(vel_balon) * 0.012 * PASO_BALON
			giro_balon *= exp(-Balance.GIRO_AIRE * PASO_BALON)
		else:
			giro_balon *= pow(Balance.GIRO_SUELO, PASO_BALON * 60.0)
		var r := LeagueNucleo.fuerzas_balon(p, vel_balon, cfg_balon, PASO_BALON, R)
		p = r[0]
		vel_balon = r[1]
		p += vel_balon * PASO_BALON
		if absf(p.z) > LARGO and absf(p.x) < PALO and p.y < LARGUERO:   ## dentro de la red, el balón se muere
			vel_balon *= 0.85
			p.z = clampf(p.z, -LARGO - 1.8, LARGO + 1.8)
	balon.position = p
	if estado == "juego":
		_palos_y_lineas(antes)
