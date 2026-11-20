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
	if not remate.is_connected(_tras_remate_visual):
		remate.connect(_tras_remate_visual)   ## (12-11) la reacción del que falla (`LeagueAcciones`, solo se ve)
	equipos = [LeagueEquipo.new(lado_de(true)), LeagueEquipo.new(lado_de(false))]
	_formas()

func _tras_remate_visual(_local: bool, autor_id: String, tipo: String) -> void:
	LeagueAcciones.tras_remate(self as Object as MotorLeague, autor_id, tipo)

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

## (16-11, paso a C++) Lo que `_estado_league` y `_estado_sin_balon` piden de las posiciones, calculado en una sola pasada (`league_estado_base`; ver estado_nativo.cpp). Vacío = a mano, con las gemelas GDScript.
var _base_liga: PackedFloat64Array = PackedFloat64Array()

func _estado_league(delta: float) -> void:
	if not poseedor.is_empty():
		if String(poseedor["id"]) != _posee_id:
			_posee_id = String(poseedor["id"])
			_posee_desde = t
	else:
		_posee_id = ""
	var e0: LeagueEquipo = equipos[0]
	var e1: LeagueEquipo = equipos[1]
	var b0 := ls(balon.position)
	var nat := Nativo.obj()
	_base_liga = nat.league_estado_base(jugadores, b0, e0.lado, e1.lado) if nat != null and nat.has_method("league_estado_base") else PackedFloat64Array()
	var ml := _base_liga[0] if not _base_liga.is_empty() else _ms_al_balon(true)
	var mv := _base_liga[1] if not _base_liga.is_empty() else _ms_al_balon(false)
	e0.actualizar_posesion(ml, mv, delta)
	e1.actualizar_posesion(mv, ml, delta)
	## L Match::Process: el «lado de la posesión» es la suma de (posesión desvanecida − 0,5) · lado de cada equipo.
	var lado_pos := (e0.posesion_desvanecida - 0.5) * e0.lado + (e1.posesion_desvanecida - 0.5) * e1.lado
	_lado_medio = e0.registrar_acumular(b0, lado_pos, delta)
	var tot: float = float(posesion[0]) + float(posesion[1])
	for i in 2:
		var e: LeagueEquipo = equipos[i]
		if e.tactica_pendiente(delta):   ## (16-11) las palancas y el reloj solo se arman cuando toca (una vez por segundo)
			var p60: float = (float(posesion[i]) / tot) if tot > 0.0 else 0.5
			e.aplicar_tactica(goles[i], goles[1 - i], (minuto() * 60000.0), p60, _palancas(i == 0))
		var rival: Array = []
		if not poseedor.is_empty() and bool(poseedor["es_local"]) != (i == 0):
			rival = [ls(pos(poseedor)), ls(poseedor["vel"])]
		e.calcular_trampa(b0, b0 + ls(vel_balon) * 0.7, rival, float(_base_liga[3 + i]) if not _base_liga.is_empty() else _linea_penultimo(i == 0, false, e.lado, b0.x))

## El más cercano de todos al balón (índice de `_base_liga`, o a mano) y el de cada equipo a un punto (`league_cercanos_equipos`, o `[]`).
func _designado_base(b0: Vector2) -> Dictionary:
	if _base_liga.is_empty():
		return _mas_cercano_a_todos(b0)
	var k := int(_base_liga[2])
	return jugadores[k] if k >= 0 else {}

func _cercanos_equipos(punto: Vector2) -> PackedInt32Array:
	var nat := Nativo.obj()
	if nat != null and nat.has_method("league_cercanos_equipos"):
		return nat.league_cercanos_equipos(jugadores, punto)
	return PackedInt32Array()

## Línea del fuera de juego del rival del equipo `i` a 240 ms (`_linea_penultimo(not local, true, -lado, b0.x)`).
func _linea_rival(i: int, local: bool, lado: float, b0: Vector2) -> float:
	return float(_base_liga[5 + i]) if not _base_liga.is_empty() else _linea_penultimo(not local, true, -lado, b0.x)

## Gemela GDScript de `league_cortar_candidatos`: los del otro equipo que `local_pasa` (no porteros, no el usuario con el mando, sin orden de cortar vigente) a 10 m del balón previsto.
func _candidatos_cortar_gd(local_pasa: bool, bola: Vector2) -> PackedInt32Array:
	var r := PackedInt32Array()
	for k in jugadores.size():
		var p: Dictionary = jugadores[k]
		if bool(p["es_local"]) == local_pasa or bool(p["por"]) or (p == usuario and not autopiloto) or float(p.get("ls_cortar_hasta", 0.0)) > t:
			continue
		if ls(pos(p)).distance_to(bola) > 10.0:
			continue
		r.append(k)
	return r

## Gemela GDScript de `league_interferir_candidatos`: los defensores que pueden entrar al balón (otro equipo, no porteros, no el usuario con el mando, sin enfriar ni en un gesto, a 10 m del balón).
func _candidatos_interferir_gd(rival: Dictionary, bola: Vector2) -> PackedInt32Array:
	var r := PackedInt32Array()
	for k in jugadores.size():
		var p: Dictionary = jugadores[k]
		if bool(p["es_local"]) == bool(rival["es_local"]) or bool(p["por"]) or (p == usuario and not autopiloto):
			continue
		if float(p["enfriar"]) > 0.0 or float(p.get("gesto_hasta", 0.0)) > t:
			continue
		if ls(pos(p)).distance_to(bola) > 10.0:
			continue
		r.append(k)
	return r

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

func _anim_league() -> bool:   ## (16-11) `_anim` de este motor pasa por LeagueAcciones y LeagueLocomocion (`animar_jugadores` lo copia)
	return true

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
	var ofens := clampf(e.ofensividad + float(_tac(local, "mentalidad") - 1) * 0.15, 0.0, 1.0)
	var nat := Nativo.obj()
	var r: Vector2
	if nat != null and nat.has_method("league_destino_forma"):   ## (16-11, paso a C++) misma cuenta que `LeagueEquipo.destino_forma_gd`
		r = nat.league_destino_forma(e0.acum, foco, yo, forma, _rol(p), e.lado, e.posesion_desvanecida, ofens, _lado_medio, e.trampa_x, e.mezcla_de(_rol(p)))
	else:
		r = LeagueEquipo.destino_forma_gd(e0, e, foco, yo, forma, _rol(p), ofens, _lado_medio)
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
	if not poseedor.is_empty() or not _ley_league():
		super(delta)
		return
	var antes := balon.position
	var p := antes
	var nat := Nativo.obj()
	if nat != null and nat.has_method("balon_avanzar"):   ## (16-11, paso a C++) el bucle de pasos de 10 ms; misma cuenta que `_avanzar_balon_gd`
		var r: Array = nat.balon_avanzar(p, vel_balon, giro_balon, _resto_balon, delta, cfg_balon, PackedFloat64Array([PASO_BALON, R, R + 0.02, 0.2, 0.012, Balance.GIRO_AIRE, Balance.GIRO_SUELO, LARGO, PALO, LARGUERO]))
		p = r[0]
		vel_balon = r[1]
		giro_balon = r[2]
		_resto_balon = r[3]
	else:
		p = _avanzar_balon_gd(p, delta)
	balon.position = p
	if estado == "juego":
		_palos_y_lineas(antes)

## (16-11, informe M6-06 y M6-24) ¿Mueve el balón suelto la física de League? En League, sí (una vez preparado); el combinado lo
## decide por su pieza `fisica_balon` (sin vaciar `equipos` mientras se mueve el balón y se emiten señales).
func _ley_league() -> bool:
	return not equipos.is_empty()

## Con la física de League, quien predice el balón usa su ley (`LeyBalon`): antes los pases se pedían con la de siempre y en C4
## se quedaban cortos (un pase manual de 12 m rodaba 8). El pase muere como mucho `SOBRA_LEAGUE` m pasado el destino: con el
## roce cuadrático de League, la «sobra» larga de la ley de siempre pediría velocidades de tiro.
const SOBRA_LEAGUE := 2.5
func _velocidad_pase(dist: float, sobra: float) -> float:
	return LeyBalon.velocidad_league(dist + minf(sobra, SOBRA_LEAGUE), cfg_balon) if _ley_league() else super(dist, sobra)

## (16-11, H1 A1.2) El pase manual va «al punto exacto hacia donde apuntas»: muere `SOBRA_MANUAL` m pasado ese punto (con el
## medio metro que el balón sale por delante del pie, un 12 m para a ~12,5 m; con 1 m de sobra paraba a 13,5, en el borde de A1.2).
const SOBRA_MANUAL := 0.0
func _velocidad_pase_manual(dist: float) -> float:
	return LeyBalon.velocidad_league(dist + SOBRA_MANUAL, cfg_balon) if _ley_league() else super(dist)

## El raso más largo que llega con la fuerza máxima del pase de la IA (≈ 23 m con el césped seco); más lejos, a media altura.
func _raso_max() -> float:
	return LeyBalon.rodando_league(26.0 * MotorPaseMejora.vel_k, cfg_balon) - 2.0 if _ley_league() else super()

## En el aire, el arrastre de League (0,017·|v|·v, el doble del de siempre) frena también la subida y el balón cae antes: integrado
## con su paso de 10 ms, el envío cae donde se apunta lanzándolo e^{0,78·K·x} veces más rápido (x = vh·tv; error < 4 % entre
## 16 y 55 m y alturas de 2 a 7 m). Tope: 36 m/s o +25 % (como la de siempre), lo que sea mayor.
func _compensa_aire(vh: float, tv: float) -> float:
	if not _ley_league():
		return super(vh, tv)
	return minf(exp(0.78 * float(cfg_balon["arrastre"]) * vh * tv), maxf(1.25, 36.0 / maxf(vh, 1.0)))

## Dónde conviene recibir el pase: donde estará el balón en 0,72 s (lo que pedía la fórmula de siempre), con lo que frena de verdad.
func _punto_de_recepcion() -> Vector3:
	if not _ley_league():
		return super()
	var b := balon.position
	var v := Vector3(vel_balon.x, 0, vel_balon.z)
	var sp := v.length()
	if sp < 1.0:
		return b
	return Vector3(b.x, 0, b.z) + v / sp * LeyBalon.recorrido_league(sp, 0.72, cfg_balon)

## Gemela GDScript del bucle de `balon_avanzar` (respaldo sin la extensión y referencia de `probar_nativo`).
func _avanzar_balon_gd(p: Vector3, delta: float) -> Vector3:
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
	return p

## Gemela GDScript de `balon_prediccion` (respaldo sin la extensión y referencia de `probar_nativo`): la trayectoria ya en el marco de League (z arriba).
static func prediccion_gd(bp0: Vector3, bv0: Vector3, cfg: Dictionary, hay_poseedor: bool, vel_poseedor: Vector3, total: int) -> PackedVector3Array:
	var bp := bp0
	var bv := bv0
	var sal := PackedVector3Array()
	sal.resize(total + 1)
	sal[0] = Vector3(bp.z, bp.x, bp.y)
	for k in range(1, total + 1):
		if not hay_poseedor:
			var r := LeagueNucleo.fuerzas_balon(bp, bv, cfg, 0.01, R)
			bp = r[0]; bv = r[1]
			bp += bv * 0.01
		else:
			bp += vel_poseedor * 0.01
		sal[k] = Vector3(bp.z, bp.x, bp.y)
	return sal

## Gemela GDScript de `league_mas_cercano` (y el caso con excluidos): una pasada buscando el mínimo, sin armar ni ordenar la lista (15-11, FPS: 86 → ~25 µs por paso).
func _mas_cercano_uno_gd(punto: Vector2, local: bool, excluir: Array) -> Array:
	var mejor := INF
	var sel: Dictionary = {}
	for q: Dictionary in jugadores:
		if bool(q["es_local"]) == local and (excluir.is_empty() or not excluir.has(q)):
			var d := (ls(pos(q)) - punto).length_squared()
			if d < mejor:
				mejor = d
				sel = q
	return [] if sel.is_empty() else [sel]

## Los `cuantos` jugadores del equipo más cercanos a `punto` (sin los de `excluir`), de más cerca a más lejos.
func _mas_cercano_al(punto: Vector2, local: bool, excluir: Array, cuantos: int) -> Array:
	var nat := Nativo.obj()
	if nat != null and cuantos == 1 and excluir.is_empty() and nat.has_method("league_mas_cercano"):   ## (16-11, paso a C++) misma pasada que `_mas_cercano_uno_gd`
		var k: int = nat.league_mas_cercano(jugadores, punto, local)
		return [] if k < 0 else [jugadores[k]]
	if nat != null and nat.has_method("league_mas_cercanos"):   ## (16-11, paso a C++) varios o con excluidos: misma lista que `_mas_cercano_varios_gd` (con 16 o menos candidatos; si no, devuelve [-2])
		var ids := PackedStringArray()
		for e: Dictionary in excluir:
			if e.has("id"):
				ids.append(String(e["id"]))
		var ks: PackedInt32Array = nat.league_mas_cercanos(jugadores, punto, local, cuantos, ids)
		if ks.size() != 1 or ks[0] != -2:
			var r: Array = []
			for k: int in ks:
				r.append(jugadores[k])
			return r
	return _mas_cercano_varios_gd(punto, local, excluir, cuantos)

func _mas_cercano_varios_gd(punto: Vector2, local: bool, excluir: Array, cuantos: int) -> Array:
	if cuantos == 1:
		return _mas_cercano_uno_gd(punto, local, excluir)
	var c: Array = []
	for q: Dictionary in jugadores:
		if bool(q["es_local"]) == local and not excluir.has(q):
			c.append([(ls(pos(q)) - punto).length_squared(), q])
	c.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	return c.slice(0, cuantos).map(func(x: Array) -> Dictionary: return x[1])

## (16-11, paso a C++) Piezas de `_estado_sin_balon` y `_estado_league`: cada una usa la extensión si está y, si no, su gemela `*_gd` (misma cuenta; `probar_nativo`).
func _indexar_jugadores(destino: Dictionary) -> void:
	var nat := Nativo.obj()
	if nat != null and nat.has_method("league_indexar"):
		nat.league_indexar(jugadores, destino)
	else:
		_indexar_gd(destino)

func _indexar_gd(destino: Dictionary) -> void:
	destino.clear()
	for q: Dictionary in jugadores:
		destino[String(q["id"])] = q

func _mas_cercano_a_todos(punto: Vector2) -> Dictionary:
	var nat := Nativo.obj()
	if nat != null and nat.has_method("league_mas_cercano_todos"):
		var k: int = nat.league_mas_cercano_todos(jugadores, punto)
		return jugadores[k] if k >= 0 else {}
	return _mas_cercano_a_todos_gd(punto)

func _mas_cercano_a_todos_gd(punto: Vector2) -> Dictionary:
	var mejor := INF
	var sel: Dictionary = {}
	for q: Dictionary in jugadores:
		var d := (ls(pos(q)) - punto).length()
		if d < mejor:
			mejor = d
			sel = q
	return sel

## `LeagueEquipo.linea_penultimo` de los jugadores con `es_local == local` (con su velocidad por 0,24 s si `con_vel`).
func _linea_penultimo(local: bool, con_vel: bool, lado: float, balon_x: float) -> float:
	var nat := Nativo.obj()
	if nat != null and nat.has_method("league_linea_penultimo"):
		return nat.league_linea_penultimo(jugadores, local, con_vel, lado, balon_x)
	return _linea_penultimo_gd(local, con_vel, lado, balon_x)

func _linea_penultimo_gd(local: bool, con_vel: bool, lado: float, balon_x: float) -> float:
	var xs := PackedFloat32Array()
	for q: Dictionary in jugadores:
		if bool(q["es_local"]) == local:
			xs.append(ls(pos(q)).x + ls(q["vel"]).x * 0.24 if con_vel else ls(pos(q)).x)
	return LeagueEquipo.linea_penultimo(xs, lado, balon_x)

## (16-11, informe M6-24) El combinado con nuestra locomoción no usa el toque de conducción de League (antes apagaba `fase3`, estática, mientras se emitían señales).
func _sin_toque_league() -> bool:
	return false
