class_name MatchPlayback
extends RefCounted

## Reproduce el partido ya simulado. La simulacion NO se rehace aqui: el HTML
## decidio quien gano, quien marco y en que minuto. Esto solo lo DRAMATIZA, que
## es exactamente el mismo reparto de responsabilidades que ya usa el visor 2D
## del juego (mvTick/mvObjetivo dibujan, simularMinuto decide).
##
## El flujo del juego se deduce de dos cosas que si vienen en el JSON: la
## posesion final del local y la linea de eventos con su minuto y su equipo.

signal event_fired(text: String)

const LARGO := 105.0
const ANCHO := 68.0
const MEDIO_LARGO := 52.5
const MEDIO_ANCHO := 34.0

## Los 5 puestos que juegan de defensa central o lateral -mismos codigos que
## `visor/puente3d.gd::ALTURA`. Se usa en mas de un lugar (marca al hombre,
## fuera de juego), de ahi que sea constante de clase y no local repetida.
const PUESTOS_DEFENSA := ["DFC", "LD", "LI", "CAD", "CAI"]

var events: Array = []
var next_event_idx := 0
var seconds_per_minute := 1.1
var local_goals := 0
var visita_goals := 0
var duration_min := 90
var posesion_local := 50.0

var players: Array = []
var players_by_id: Dictionary = {}
var ball: Node3D
var elapsed := 0.0
var _ultimo_min := -1
var _rng := RandomNumberGenerator.new()

## Tiempo (seg) desde que arranca "patear"/"cabezazo" hasta que el pie/cabeza
## conecta con el balon a mitad del swing -no es el fotograma 0-. Estimado
## a partir de la duracion total de esas animaciones (0.9s en `_ejecutar_accion`),
## no medido cuadro a cuadro contra el clip real.
const CONTACTO_PATADA := 0.35

## Disparo con el vuelo del balon calculado pero aun no lanzado -esperando a
## `CONTACTO_PATADA` para sincronizar con la animacion del rematador-.
## {} cuando no hay ninguno pendiente.
var _disparo_pendiente: Dictionary = {}

## Velocidad de reproduccion. 0 = en pausa. Las teclas la cambian desde main.
const VELOCIDADES := [0.0, 0.5, 1.0, 2.0, 4.0]
var vel_idx := 2

func velocidad() -> float:
	return VELOCIDADES[vel_idx]

func etiqueta_velocidad() -> String:
	if vel_idx == 0:
		return "PAUSA"
	return "x%s" % str(VELOCIDADES[vel_idx]).trim_suffix(".0")

func pausar_o_seguir() -> void:
	vel_idx = 2 if vel_idx == 0 else 0

func mas_rapido() -> void:
	vel_idx = mini(vel_idx + 1, VELOCIDADES.size() - 1)

func mas_lento() -> void:
	vel_idx = maxi(vel_idx - 1, 0)

# Estado del juego que se recalcula cada minuto simulado
var fase := "medio"           # "ataqueLocal" | "ataqueVisita" | "medio"
var ball_target := Vector3(0, 0.11, 0)
var _celebrando: Array = []

## RONDA 4 (17-9-2026): "que las tácticas se noten jugando". `Tactica` (el
## mismo objeto que ya pesa en el resultado real via
## `multiplicador_ataque()`/`_defensa()`) hasta ahora era invisible en el 3D
## -el visor movia a los 22 con numeros fijos, sin mirar ni una sola vez la
## pizarra que el jugador arma en Club → Táctica-. `null` = comportamiento
## identico al de antes de esta ronda (equilibrada/media en todo).
var local_tactica: Tactica = null
var visita_tactica: Tactica = null

## JUGADAS PREHECHAS (18-9-2026), primera pieza: mientras un jugador tenga una
## entrada vigente aqui (pid -> hasta ese `elapsed`), `_mover()` usa el destino
## del guion en vez de `_objetivo_jugador()` -el resto del equipo sigue leyendo
## la táctica normal, solo el/los jugadores puntuales de ESTA jugada actúan "a
## propósito" durante su ventana. No reemplaza el reparto por tácticas, es una
## excepción corta y puntual sobre él.
var _guion_destino: Dictionary = {}
var _guion_hasta: Dictionary = {}
var reproductor: ReproductorJugadas = ReproductorJugadas.new()

## SEGUNDA JUGADA PREHECHA (21-9-2026): el corner. Espera a que el sacador
## "llegue" al banderin (mismo guion corto que ya usa `_jugada_gol()` para el
## asistidor) antes de patear -no un remate instantaneo desde donde sea-.
## {} cuando no hay ninguno pendiente. Solo uno a la vez: si cae un segundo
## corner mientras el primero sigue en marcha, se deja pasar -es mas raro que
## dos corners casi seguidos short-circuiteen la puesta en escena que perder
## uno.
var _corner_pendiente: Dictionary = {}

## TERCERA JUGADA PREHECHA (21-9-2026): el tiro libre. Mismo mecanismo que
## `_corner_pendiente`, dict separado para no interferir con un corner que
## pudiera estar en marcha a la vez.
var _tirolibre_pendiente: Dictionary = {}

func setup(events_in: Array, all_players: Array, duration: int, posesion: float, ball_node: Node3D,
		tactica_local: Tactica = null, tactica_visita: Tactica = null) -> void:
	events = events_in
	duration_min = maxi(duration, 1)
	posesion_local = clampf(posesion, 10.0, 90.0)
	players = all_players
	ball = ball_node
	local_tactica = tactica_local
	visita_tactica = tactica_visita
	for p in players:
		players_by_id[p["id"]] = p
		## MOVIMIENTO MENOS ROBOTICO (17-9-2026): dos numeros por jugador,
		## calculados UNA vez aqui y no en cada fotograma -por rendimiento, y
		## porque tienen que ser estables durante todo el partido, no cambiar
		## de golpe-. `_fase` desincroniza el balanceo de cada jugador (si no,
		## los 22 se mecen exactamente igual, a la vez, y eso se lee tan
		## robotico como no mecerse); `_vel_mult` les da un ritmo propio -no
		## todos corren igual de rapido, ni en la vida real ni aqui-. Los dos
		## salen del hash del id, asi que el mismo jugador se mueve siempre
		## igual (repetible, no aleatorio de verdad).
		var h: int = hash(str(p.get("id", "")))
		p["_fase"] = float(h % 6283) / 1000.0  # 0..2*PI aprox
		p["_vel_mult"] = 0.90 + float((h / 7) % 1000) / 1000.0 * 0.22  # 0.90..1.12
		p["_vel"] = Vector3.ZERO
	# Semilla fija: el mismo partido se ve igual cada vez que lo abres.
	_rng.seed = hash("dinastia") + duration_min * 7 + int(posesion_local)

func current_minute() -> int:
	return mini(int(elapsed / seconds_per_minute), duration_min)

# ------------------------------------------------------------------- reloj

func tick(delta_real: float) -> void:
	# En pausa el reloj se detiene pero los jugadores siguen animados en el sitio,
	# asi la escena no se congela como una foto.
	var delta := delta_real * velocidad()
	if delta <= 0.0:
		_mover(delta_real * 0.15)
		reproductor.avanzar(delta_real)
		return
	elapsed += delta
	var m := elapsed / seconds_per_minute

	while next_event_idx < events.size() and float(events[next_event_idx]["min"]) <= m:
		_disparar(events[next_event_idx])
		next_event_idx += 1

	var min_ahora := current_minute()
	if min_ahora != _ultimo_min and not reproductor.en_reproduccion:
		_ultimo_min = min_ahora
		_recalcular_fase(null)

	if not _disparo_pendiente.is_empty():
		_disparo_pendiente["restante"] -= delta
		if _disparo_pendiente["restante"] <= 0.0:
			if ball is Balon3D:
				(ball as Balon3D).enviar(_disparo_pendiente["objetivo"], _disparo_pendiente["duracion"], _disparo_pendiente["altura"], _disparo_pendiente["es_gol"])
			_disparo_pendiente = {}

	if not _corner_pendiente.is_empty():
		_corner_pendiente["restante"] -= delta
		if _corner_pendiente["restante"] <= 0.0:
			var sacador = players_by_id.get(_corner_pendiente["sacador_id"])
			var n: Node3D = null
			if sacador != null:
				_ejecutar_accion(sacador, "patear", 0.9)
				n = sacador.get("node")
				if is_instance_valid(n):
					n.look_at(Vector3(0, n.position.y, float(_corner_pendiente["z_arco"])), Vector3.UP)
			## BUG REAL ENCONTRADO EN LA PRIMERA PRUEBA (21-9-2026): sin esto, el
			## centro salia desde donde HUBIERA quedado la pelota del remate
			## "fallo" original -que vuela por su cuenta via `_disparo_pendiente`,
			## sin relacion con el banderin- en vez de desde los pies del
			## sacador. `enviar()` siempre usa la posicion ACTUAL del balon como
			## origen (ver `Balon3D.enviar()`), asi que hay que reposicionarlo a
			## proposito antes de patear -el sacador ya tuvo la ventana de
			## `_jugada_corner()` para llegar de verdad al banderin.
			if ball is Balon3D:
				var origen_centro: Vector3 = _corner_pendiente["pos_saque"]
				if is_instance_valid(n):
					origen_centro = n.position
				## `detener()` primero: sin esto, `avanzar()` -llamado cada
				## fotograma por `_mover()`, mas abajo en este mismo tick()- seguia
				## interpolando desde el vuelo del remate "fallo" original (su
				## `_t` no habia llegado a 1.0 todavia) y pisaba esta posicion en
				## el mismo frame -confirmado con una captura real donde el
				## centro salia desde cualquier lado menos el banderin.
				(ball as Balon3D).detener()
				(ball as Balon3D).position = Vector3(origen_centro.x, 0.11, origen_centro.z)
			## Mismo principio que el disparo normal: la pelota no sale en el
			## fotograma 0 de "patear", espera a `CONTACTO_PATADA`.
			_disparo_pendiente = {
				"objetivo": _corner_pendiente["destino"], "duracion": _corner_pendiente["duracion"],
				"altura": _corner_pendiente["altura"], "es_gol": false, "restante": CONTACTO_PATADA,
			}
			_corner_pendiente = {}

	if not _tirolibre_pendiente.is_empty():
		_tirolibre_pendiente["restante"] -= delta
		if _tirolibre_pendiente["restante"] <= 0.0:
			var pateador = players_by_id.get(_tirolibre_pendiente["sacador_id"])
			var n2: Node3D = null
			if pateador != null:
				_ejecutar_accion(pateador, "patear", 0.9)
				n2 = pateador.get("node")
				if is_instance_valid(n2):
					n2.look_at(Vector3(0, n2.position.y, float(_tirolibre_pendiente["z_arco"])), Vector3.UP)
			## Mismo bug ya corregido en el corner, mismo arreglo: reposicionar
			## el balon junto al pateador -`detener()` primero, o `avanzar()`
			## lo pisa en el mismo fotograma.
			if ball is Balon3D:
				var origen_tl: Vector3 = _tirolibre_pendiente["pos_saque"]
				if is_instance_valid(n2):
					origen_tl = n2.position
				(ball as Balon3D).detener()
				(ball as Balon3D).position = Vector3(origen_tl.x, 0.11, origen_tl.z)
			_disparo_pendiente = {
				"objetivo": _tirolibre_pendiente["destino"], "duracion": _tirolibre_pendiente["duracion"],
				"altura": _tirolibre_pendiente["altura"], "es_gol": false, "restante": CONTACTO_PATADA,
			}
			_tirolibre_pendiente = {}

	_mover(delta)
	reproductor.avanzar(delta)

func ejecutar_jugada_prehecha(codigo: String, es_local: bool = true) -> bool:
	if not is_instance_valid(ball):
		return false
	return reproductor.iniciar(codigo, self, ball, es_local)

## Acciones temporales por jugador: pid -> {"anim": String, "hasta": float}
var _acciones_activas: Dictionary = {}

## Elige hacia donde va el juego este minuto. Si acaba de pasar algo (ev != null)
## manda el suceso: tras un remate la pelota esta en el area, no en el medio.
func _recalcular_fase(ev) -> void:
	var r := _rng.randf() * 100.0
	var p := posesion_local
	if r < p * 0.72:
		fase = "ataqueLocal"
	elif r < p * 0.72 + (100.0 - p) * 0.72:
		fase = "ataqueVisita"
	else:
		fase = "medio"

	if ev != null:
		var equipo = ev.get("equipo")
		if equipo == "local":
			fase = "ataqueLocal"
		elif equipo == "visita":
			fase = "ataqueVisita"

	var es_gol: bool = ev != null and (ev["t"] == "golMi" or ev["t"] == "golR")
	## CORRECCION (17-9-2026): el evento real que manda `estadio.gd::_al_remate()`
	## viaja como `"t": "disparo"` con el resultado en `"tipo"` (atajada/poste/
	## fallo) -no como `"t": "atajada"` directo-. Comparar contra `ev["t"]` aqui
	## dejaba esta rama muerta para TODO remate real que no fuera gol: el balon
	## nunca volaba al arco en una atajada/poste/fallo, solo en el gol (que si
	## compara "t" porque golMi/golR SI son el tipo real del evento).
	var tipo_ev: String = str(ev.get("tipo", "")) if ev != null else ""
	var es_atajada: bool = tipo_ev == "atajada"
	var es_poste: bool = tipo_ev == "poste"
	var es_fallo: bool = tipo_ev == "fallo"

	var z := 0.0
	var ancho_z := 0.0
	match fase:
		"ataqueLocal":
			# el local ataca hacia -Z (arco rival en -52.5)
			if es_gol:
				ball_target = Vector3(_rng.randf_range(-3.0, 3.0), _rng.randf_range(0.3, 2.0), -53.3)
			elif es_atajada:
				ball_target = Vector3(_rng.randf_range(-2.8, 2.8), _rng.randf_range(0.3, 1.8), -51.8)
			elif es_poste:
				var l_poste: float = 3.66 if _rng.randf() > 0.5 else -3.66
				ball_target = Vector3(l_poste, _rng.randf_range(0.2, 2.4), -52.5)
			elif es_fallo:
				var l_fuera: float = (_rng.randf_range(4.5, 7.5)) * (1.0 if _rng.randf() > 0.5 else -1.0)
				ball_target = Vector3(l_fuera, _rng.randf_range(0.5, 3.5), -54.5)
			else:
				z = -30.0
				ancho_z = 14.0
				ball_target = Vector3(_rng.randf_range(-24.0, 24.0), 0.11, z + _rng.randf_range(-ancho_z, ancho_z))
		"ataqueVisita":
			# la visita ataca hacia +Z (arco local en +52.5)
			if es_gol:
				ball_target = Vector3(_rng.randf_range(-3.0, 3.0), _rng.randf_range(0.3, 2.0), 53.3)
			elif es_atajada:
				ball_target = Vector3(_rng.randf_range(-2.8, 2.8), _rng.randf_range(0.3, 1.8), 51.8)
			elif es_poste:
				var l_poste: float = 3.66 if _rng.randf() > 0.5 else -3.66
				ball_target = Vector3(l_poste, _rng.randf_range(0.2, 2.4), 52.5)
			elif es_fallo:
				var l_fuera: float = (_rng.randf_range(4.5, 7.5)) * (1.0 if _rng.randf() > 0.5 else -1.0)
				ball_target = Vector3(l_fuera, _rng.randf_range(0.5, 3.5), 54.5)
			else:
				z = 30.0
				ancho_z = 14.0
				ball_target = Vector3(_rng.randf_range(-24.0, 24.0), 0.11, z + _rng.randf_range(-ancho_z, ancho_z))
		_:
			z = 0.0
			ancho_z = 18.0
			ball_target = Vector3(_rng.randf_range(-24.0, 24.0), 0.11, z + _rng.randf_range(-ancho_z, ancho_z))

	if ball is Balon3D and not reproductor.en_reproduccion:
		var origen: Vector3 = (ball as Balon3D).position
		var dist := origen.distance_to(ball_target)
		var duracion := clampf(dist / 12.0, 0.3, 2.2)
		var altura: float
		var es_remate_fase: bool = es_gol or es_atajada or es_poste or es_fallo
		if es_gol:
			altura = _rng.randf_range(0.4, 0.85)
			duracion = maxf(duracion, 0.8)
		elif es_atajada or es_poste or es_fallo:
			altura = _rng.randf_range(0.3, 0.8)
			duracion = maxf(duracion, 0.7)
		else:
			altura = _rng.randf_range(0.06, 0.28)
		if es_remate_fase:
			## `_disparar()` recien va a arrancar la animacion "patear"/"cabezazo"
			## del rematador -ver `_ejecutar_accion()`-. Si el balon sale aqui
			## mismo, vuela desde el fotograma 0 (el jugador recien empezando a
			## levantar la pierna), no desde el instante real de contacto. Se
			## guarda el vuelo ya calculado y `tick()` lo dispara recien pasado
			## `CONTACTO_PATADA`.
			_disparo_pendiente = {
				"objetivo": ball_target, "duracion": duracion,
				"altura": altura, "es_gol": es_gol, "restante": CONTACTO_PATADA,
			}
		else:
			## EL PASE TIENE GESTO: quien está pegado al balón le pega con el
			## interior del pie. Antes el balón salía solo, sin que nadie lo tocara.
			var pasador := _mas_cercano_a(origen, 2.6)
			if not pasador.is_empty():
				_ejecutar_accion(pasador, "pase", 0.8)
				var np: Node3D = pasador.get("node")
				if is_instance_valid(np):
					np.look_at(Vector3(ball_target.x, np.position.y, ball_target.z), Vector3.UP)
			(ball as Balon3D).enviar(ball_target, duracion, altura, es_gol)

## El jugador de campo más cercano a un punto, si está a menos de `radio`.
func _mas_cercano_a(punto: Vector3, radio: float) -> Dictionary:
	var mejor: Dictionary = {}
	var d_mejor := radio
	for p in players:
		if bool(p.get("arbitro", false)) or bool(p.get("banca", false)):
			continue
		var n: Node3D = p.get("node")
		if not is_instance_valid(n):
			continue
		var d := Vector2(n.position.x - punto.x, n.position.z - punto.z).length()
		if d < d_mejor:
			d_mejor = d
			mejor = p
	return mejor

func _buscar_portero(es_local: bool) -> Dictionary:
	for p in players:
		if p.get("es_local") == es_local and str(p.get("slot_code", "")) == "POR":
			return p
	return {}

func _ejecutar_accion(p: Dictionary, anim_name: String, duracion: float) -> void:
	var pid = p.get("id")
	if pid == null:
		return
	_acciones_activas[pid] = {"anim": anim_name, "hasta": elapsed + duracion}
	var ap: AnimationPlayer = p.get("anim")
	if is_instance_valid(ap) and ap.has_animation(anim_name):
		ap.play(anim_name)
		ap.speed_scale = 1.0

func _desolar_defensa(es_local_defensa: bool) -> void:
	for p in players:
		if p.get("es_local") == es_local_defensa and not bool(p.get("arbitro", false)):
			var slot := str(p.get("slot_code", ""))
			if slot == "POR" or slot in ["DFC", "LI", "LD", "DEF"]:
				var anim_lamento := "lamento" if _rng.randf() > 0.4 else "rabia"
				_ejecutar_accion(p, anim_lamento, 2.4)

func _disparar(ev: Dictionary) -> void:
	event_fired.emit("%d'  %s" % [int(ev["min"]), ev["tx"]])
	_recalcular_fase(ev)

	var t_ev: String = str(ev.get("t", ""))
	var tipo_ev: String = str(ev.get("tipo", ""))
	## El lesionado se duele, agachado y con las manos en la rodilla.
	if t_ev == "lesion":
		var lesionado = players_by_id.get(ev.get("jugadorId"))
		if lesionado != null:
			_ejecutar_accion(lesionado, "dolor", 3.0)
	var es_gol: bool = t_ev == "golMi" or t_ev == "golR"
	## Mismo arreglo que en `_recalcular_fase()`: el remate real llega como
	## `"t": "disparo"`, no como `"t": "atajada"/"poste"/"fallo"` directo.
	var es_remate: bool = es_gol or t_ev == "disparo" or tipo_ev in ["remate", "atajada", "poste", "fallo"]
	var pid = ev.get("jugadorId")
	var p_remate = players_by_id.get(pid) if pid != null else null

	# Animar al rematador ejecutando el tiro
	if es_remate and p_remate != null:
		var es_aereo: bool = _rng.randf() < 0.25
		_ejecutar_accion(p_remate, "cabezazo" if es_aereo else "patear", 0.9)
		# Orientar hacia la portería rival
		var node_rem: Node3D = p_remate.get("node")
		if is_instance_valid(node_rem):
			var z_arco: float = -52.5 if p_remate.get("es_local") else 52.5
			node_rem.look_at(Vector3(0, node_rem.position.y, z_arco), Vector3.UP)

	# Reacción del portero defensor
	var es_local_atacando: bool = fase == "ataqueLocal"
	var por_defensor = _buscar_portero(not es_local_atacando)
	if not por_defensor.is_empty():
		if tipo_ev == "atajada" or (es_gol and _rng.randf() < 0.75) or tipo_ev == "poste":
			var lado_der := ball_target.x > 0 if not es_local_atacando else ball_target.x < 0
			var anim_atajada := "atajar_der" if lado_der else "atajar_izq"
			## Balón a ras de suelo y centrado: el portero se agacha, no vuela.
			if ball_target.y < 0.6 and absf(ball_target.x) < 1.6:
				anim_atajada = "atajar_bajo"
			_ejecutar_accion(por_defensor, anim_atajada, 1.9)

	## JUGADAS PREHECHAS, segunda pieza (21-9-2026): un remate desviado
	## ("fallo") es, en la realidad, a menudo un balon que sale por el fondo
	## -un corner-. La simulacion portada del HTML no distingue esto (no hay
	## un tipo "corner" en el JSON, solo golMi/golR/atajada/poste/fallo), asi
	## que esto NO decide nada nuevo sobre el resultado -sigue siendo un
	## "fallo" a todos los efectos del marcador y las estadisticas, exactamente
	## el mismo principio que ya usa `_jugada_gol()` (dramatizar lo decidido,
	## no redecidir nada)-, solo una fraccion de esos fallos (30%, sorteado con
	## `_rng` propio, NUNCA `Azar`) se viste como un saque de esquina en vez de
	## un simple "se fue afuera". Un solo corner a la vez -no se pisa uno en
	## marcha con otro-, y la pelota debe estar libre (no en pleno vuelo de
	## otro disparo).
	## BUG REAL ENCONTRADO EN LA PRUEBA DE ESTRES (21-9-2026): exigir tambien
	## `_disparo_pendiente.is_empty()` aqui bloqueaba el corner el 100% de las
	## veces en un partido real -`_recalcular_fase(ev)`, un poco mas arriba en
	## esta misma funcion, YA deja `_disparo_pendiente` ocupado con el vuelo
	## del propio remate "fallo" que se esta procesando, asi que la condicion
	## nunca podia ser verdadera-. Confirmado con un partido natural de 2000
	## fotogramas (`pruebas/estres_corner.gd`, nuevo): 2 fallos reales, cero
	## corners, ambos con `disparo_vacio=false`. No hace falta esa guarda: el
	## corner sobreescribe `_disparo_pendiente` mas tarde en `tick()`, cuando
	## el vuelo del fallo original ya se lanzo hace rato.
	if tipo_ev == "fallo" and _corner_pendiente.is_empty() and _rng.randf() < 0.30:
		_jugada_corner(es_local_atacando)

	# Faltas y tarjetas
	if t_ev in ["warn", "falta"]:
		if p_remate != null:
			_ejecutar_accion(p_remate, "falta_barrida" if _rng.randf() > 0.35 else "falta_empujon", 1.2)
		var arb = players_by_id.get("arbitro")
		if arb != null:
			var gesto := "senalar_falta"
			if t_ev == "warn":
				gesto = "mostrar_roja" if bool(ev.get("roja", false)) else "mostrar_tarjeta"
			_ejecutar_accion(arb, gesto, 2.4 if gesto == "mostrar_roja" else 1.8)

		## JUGADAS PREHECHAS, tercera pieza (21-9-2026): el tiro libre. Mismo
		## principio que el corner -no redecide nada, `ev` sigue siendo un
		## "warn"/"falta" normal a todos los efectos-, solo que esta vez el
		## equipo que se viste es el CONTRARIO al que cometio la falta (`ev.
		## equipo` es de quien la comete, per `_a_la_tarjeta()` en estadio.gd),
		## y solo si la falta cayo en zona de disparo directo -no tiene sentido
		## un tiro libre "de verdad" desde el propio campo-.
		var equipo_falta: String = str(ev.get("equipo", ""))
		var atacante_es_local: bool = equipo_falta == "visita"
		var z_arco_propio: float = MEDIO_LARGO if equipo_falta == "local" else -MEDIO_LARGO
		var dist_arco := ball_target.distance_to(Vector3(0, 0, z_arco_propio))
		if _tirolibre_pendiente.is_empty() and dist_arco < 30.0 and _rng.randf() < 0.35:
			_jugada_tiro_libre(atacante_es_local, z_arco_propio)

	if es_gol:
		if ev.get("equipo") == "local":
			local_goals += 1
		elif ev.get("equipo") == "visita":
			visita_goals += 1
		if p_remate != null:
			_jugada_gol(p_remate, ev.get("asistidorId"))
			_celebrar(p_remate, ev.get("asistidorId"))
		_desolar_defensa(not es_local_atacando)

## JUGADAS PREHECHAS, primera pieza (18-9-2026): hasta ahora el asistidor de un
## gol quedaba TOTALMENTE ajeno a su propio pase -seguia con el reparto tactico
## normal, que en el instante del gol lo puede tener a 20 metros del área-. Esto
## le da al asistidor un destino puntual, cerca del rematador, por una ventana
## corta: no es una animacion nueva (usa correr/trotar, que `_animar()` ya elige
## solo con la velocidad), es la primera "jugada" con guion propio en vez de
## reparto de zona. `_recalcular_fase()` ya decidio hacia donde vuela el balon
## un poco antes en `_disparar()`; esta ventana cubre ese vuelo y un poco mas.
func _jugada_gol(p_remate: Dictionary, asistidor_id) -> void:
	if asistidor_id == null or asistidor_id == "" or not players_by_id.has(asistidor_id):
		return
	var a: Dictionary = players_by_id[asistidor_id]
	var n_a: Node3D = a.get("node")
	var n_r: Node3D = p_remate.get("node")
	if not is_instance_valid(n_a) or not is_instance_valid(n_r):
		return
	var hacia := n_r.position - n_a.position
	hacia.y = 0.0
	if hacia.length() > 0.01:
		hacia = hacia.normalized()
	else:
		hacia = Vector3.FORWARD
	var destino: Vector3 = n_r.position - hacia * 3.5
	_guion_destino[asistidor_id] = destino
	## 1.6s, no 1.3: pensado para que la carrera se alcance a LEER en una
	## grabación corta, no solo a medirse en el banco.
	_guion_hasta[asistidor_id] = elapsed + 1.6

## TERCERA JUGADA PREHECHA -EN REALIDAD LA SEGUNDA "DE VERDAD", `_celebrar()`
## no arma una escena nueva, solo pone una animacion- (21-9-2026): el corner.
## Manda a UN jugador del equipo que ataca al banderin mas cercano al lugar
## por donde salio el balon, y a dos o tres companeros mas al area a buscar el
## centro -mismo mecanismo de `_guion_destino`/`_guion_hasta` que ya usa
## `_jugada_gol()` para el asistidor, aplicado a mas de un jugador a la vez
## por primera vez-. `tick()` se encarga de patear recien cuando el sacador
## haya tenido tiempo de llegar (ver `_corner_pendiente` mas arriba).
func _jugada_corner(es_local_ataca: bool) -> void:
	var candidatos: Array = []
	for p in players:
		if p.get("es_local") == es_local_ataca and not bool(p.get("arbitro", false)) \
				and str(p.get("slot_code", "")) != "POR" and is_instance_valid(p.get("node")):
			candidatos.append(p)
	if candidatos.size() < 3:
		return

	## El corner cae en la esquina de la porteria que este equipo ataca -mismo
	## convenio de ejes que el resto del archivo: el local ataca hacia -Z, la
	## visita hacia +Z (ver `_recalcular_fase()`)-, del lado por el que salio
	## el balon (signo de `ball_target.x`, o derecha por defecto si salio
	## justo por el medio).
	var z_arco: float = -MEDIO_LARGO if es_local_ataca else MEDIO_LARGO
	var lado_x: float = signf(ball_target.x) if absf(ball_target.x) > 0.5 else 1.0
	var banderin := Vector3(lado_x * MEDIO_ANCHO, 0, z_arco)

	## El sacador: el candidato mas cercano al banderin -en un equipo real
	## suele sacarlo un extremo o lateral de ese costado, y "el mas cerca" es
	## una aproximacion barata y razonable sin tener que leer la demarcacion.
	var sacador: Dictionary = {}
	var sid = null
	var mejor_dist := INF
	for p in candidatos:
		var n: Node3D = p.get("node")
		var d := n.position.distance_to(banderin)
		if d < mejor_dist:
			mejor_dist = d
			sacador = p
			sid = p.get("id")
	if sid == null:
		return

	## Dentro del terreno de verdad, no exactamente sobre la linea -el jugador
	## no puede pararse en el aire fuera de la cancha. `z_arco` nunca es 0 (es
	## siempre ±MEDIO_LARGO), asi que `signf()` da siempre ±1 aqui.
	var pos_saque := Vector3(lado_x * (MEDIO_ANCHO - 0.6), 0, z_arco - signf(z_arco) * 0.6)
	_guion_destino[sid] = pos_saque
	_guion_hasta[sid] = elapsed + 1.6

	## Dos o tres companeros de verdad buscando el area: primer palo, centro
	## del area chica, segundo palo -los tres puntos que de verdad se disputan
	## en un corner real, no posiciones al azar-.
	var objetivos_area := [
		Vector3(lado_x * 3.0, 0, z_arco - signf(z_arco) * 8.5),
		Vector3(0.0, 0, z_arco - signf(z_arco) * 6.5),
		Vector3(-lado_x * 5.5, 0, z_arco - signf(z_arco) * 9.5),
	]
	var restantes: Array = []
	for p in candidatos:
		if p.get("id") != sid:
			restantes.append(p)
	var cuantos := mini(objetivos_area.size(), restantes.size())
	for i in cuantos:
		var idx := _rng.randi_range(0, restantes.size() - 1)
		var corredor: Dictionary = restantes[idx]
		restantes.remove_at(idx)
		var cid = corredor.get("id")
		_guion_destino[cid] = objetivos_area[i]
		## Un pelin mas que el sacador: tienen que estar ya ubicados cuando
		## llegue el centro, y quedarse un momento disputando el area.
		_guion_hasta[cid] = elapsed + 2.2

	## El centro en si: se arma como `_corner_pendiente`, que `tick()` resuelve
	## recien cuando el sacador haya tenido el tiempo de la ventana de arriba
	## para llegar -no antes-. Apunta al objetivo del medio (el mas disputado
	## de los tres) con una parabola alta, como un centro de verdad.
	var origen_aprox: Vector3 = pos_saque
	var destino_centro: Vector3 = objetivos_area[1] + Vector3(0, 1.6, 0)
	var dist := origen_aprox.distance_to(destino_centro)
	_corner_pendiente = {
		"sacador_id": sid, "z_arco": z_arco, "destino": destino_centro, "pos_saque": pos_saque,
		"duracion": clampf(dist / 10.0, 0.9, 2.0), "altura": 2.6,
		"restante": 1.6,
	}

## CUARTA JUGADA PREHECHA (21-9-2026): el tiro libre directo. Manda al
## pateador mas cercano al punto de la falta a colocarse sobre el balon, y a
## dos o tres defensores del equipo que la cometio a formar una barrera entre
## el balon y su propio arco -la distancia real de una barrera, 9.15m, no un
## numero inventado-. `tick()` resuelve el disparo igual que el corner: espera
## la ventana, patea, reposiciona el balon junto al pateador (mismo bug ya
## corregido ahi, mismo arreglo aqui) y lo manda al arco.
func _jugada_tiro_libre(atacante_es_local: bool, z_arco_propio: float) -> void:
	var atacantes: Array = []
	var defensores: Array = []
	for p in players:
		if bool(p.get("arbitro", false)) or str(p.get("slot_code", "")) == "POR" \
				or not is_instance_valid(p.get("node")):
			continue
		if p.get("es_local") == atacante_es_local:
			atacantes.append(p)
		else:
			defensores.append(p)
	if atacantes.size() < 1 or defensores.size() < 2:
		return

	var punto_falta: Vector3 = Vector3(ball_target.x, 0, ball_target.z)
	var arco_pos := Vector3(0, 0, z_arco_propio)

	## El pateador: el atacante mas cercano al punto de la falta -en la
	## realidad no siempre es el mejor pateador del equipo, pero "el que ya
	## esta mas cerca" es la misma aproximacion barata que ya usa el corner
	## para el sacador, y es razonable sin leer atributos de tiro libre.
	var sid = null
	var mejor_dist := INF
	for p in atacantes:
		var n: Node3D = p.get("node")
		var d := n.position.distance_to(punto_falta)
		if d < mejor_dist:
			mejor_dist = d
			sid = p.get("id")
	if sid == null:
		return
	_guion_destino[sid] = punto_falta - (punto_falta - arco_pos).normalized() * 1.8
	_guion_hasta[sid] = elapsed + 1.6

	## La barrera: 9.15m (10 yardas reales) desde el balon hacia el propio
	## arco, dos o tres defensores repartidos a los lados del punto central de
	## la barrera -perpendicular a la linea balon-arco, no en fila india.
	var hacia_arco := (arco_pos - punto_falta)
	hacia_arco.y = 0.0
	if hacia_arco.length() < 0.01:
		hacia_arco = Vector3.FORWARD
	hacia_arco = hacia_arco.normalized()
	var centro_barrera: Vector3 = punto_falta + hacia_arco * 9.15
	var lateral := Vector3(-hacia_arco.z, 0, hacia_arco.x)
	var def_ordenados := defensores.duplicate()
	def_ordenados.sort_custom(func(a, b):
		return (a.get("node") as Node3D).position.distance_to(punto_falta) \
			< (b.get("node") as Node3D).position.distance_to(punto_falta))
	var offsets := [0.0, -1.1, 1.1]
	var cuantos_b := mini(offsets.size(), def_ordenados.size())
	for i in cuantos_b:
		var d2: Dictionary = def_ordenados[i]
		var did = d2.get("id")
		_guion_destino[did] = centro_barrera + lateral * offsets[i]
		_guion_hasta[did] = elapsed + 1.8

	var dist_tiro := punto_falta.distance_to(arco_pos)
	_tirolibre_pendiente = {
		"sacador_id": sid, "z_arco": z_arco_propio, "pos_saque": punto_falta,
		"destino": Vector3(arco_pos.x + _rng.randf_range(-3.0, 3.0), _rng.randf_range(0.3, 2.2), arco_pos.z),
		"duracion": clampf(dist_tiro / 22.0, 0.6, 1.6), "altura": _rng.randf_range(0.4, 1.4),
		"restante": 1.6,
	}

func _celebrar(p: Dictionary, asistidor) -> void:
	var r_celeb := _rng.randf()
	var anim_celeb: String = "celebrar_rodillas" if r_celeb > 0.6 else ("celebrar_carrera" if r_celeb > 0.3 else "celebrar")
	_ejecutar_accion(p, anim_celeb, 3.8)
	_celebrando.append({"p": p, "hasta": elapsed + 4.2})
	if asistidor != null and players_by_id.has(asistidor):
		var a = players_by_id[asistidor]
		_ejecutar_accion(a, "celebrar", 3.4)
		_celebrando.append({"p": a, "hasta": elapsed + 3.6})

# ---------------------------------------------------------------- movimiento

func _esta_celebrando(p: Dictionary) -> bool:
	for c in _celebrando:
		if c["p"] == p:
			return true
	return false

func _mover(delta: float) -> void:
	if is_instance_valid(ball) and ball is Balon3D:
		(ball as Balon3D).avanzar(delta)

	var vivas: Array = []
	for c in _celebrando:
		if elapsed < c["hasta"]:
			vivas.append(c)
	_celebrando = vivas

	var bola: Vector3 = ball.position if is_instance_valid(ball) else Vector3.ZERO

	for p in players:
		var node: Node3D = p["node"]
		if not is_instance_valid(node):
			continue
		var ap: AnimationPlayer = p["anim"]
		var es_local: bool = p["es_local"]
		var base: Vector3 = p["base_pos"]
		var es_por: bool = str(p.get("slot_code", "")) == "POR"

		## Jugador nuevo (entra por cambio a mitad de partido, `_al_cambio()` en
		## `estadio.gd`): no paso por `setup()`, asi que estos campos no
		## existen todavia. Se siembran aqui mismo, una sola vez, ANTES de
		## calcular el objetivo -`_objetivo_jugador()` ya necesita `_reaccion`.
		if not p.has("_vel"):
			var h: int = hash(str(p.get("id", "")))
			p["_fase"] = float(h % 6283) / 1000.0
			p["_vel_mult"] = 0.90 + float((h / 7) % 1000) / 1000.0 * 0.22
			## RONDA 2 (17-9-2026): cuanto tarda ESTE jugador en reaccionar a
			## un cambio de fase del juego -1.8 a 3.2 s. Sin esto los 22 se
			## reposicionan en el mismo fotograma exacto en que cambia `fase`,
			## que es la parte MAS robotica de todas: da igual lo suave que
			## sea el movimiento de cada uno si los 22 deciden a la vez, como
			## una sola mente. Un rango de reaccion, no un numero fijo: no
			## todos los futbolistas leen el juego igual de rapido.
			p["_reaccion"] = 1.8 + float((h / 13) % 1000) / 1000.0 * 1.4
			p["_empuje_actual"] = 0.0
			p["_vel"] = Vector3.ZERO

		var objetivo: Vector3
		var pid_guion = p.get("id")
		## JUGADAS PREHECHAS: el guion manda por encima de TODO lo demas -incluida
		## la celebracion-. `_celebrar()` marca tambien al asistidor como
		## "celebrando" (linea que ya existia antes de esta pieza), y esa rama iba
		## ANTES en la cadena de prioridad: sin este chequeo primero, el destino de
		## la jugada quedaba calculado pero nunca se usaba, el asistidor se iba
		## derecho a la banda a celebrar como si el pase no fuera suyo.
		if pid_guion != null and float(_guion_hasta.get(pid_guion, -1.0)) > elapsed:
			objetivo = _guion_destino[pid_guion]
			objetivo.x = clampf(objetivo.x, -MEDIO_ANCHO + 0.5, MEDIO_ANCHO - 0.5)
			objetivo.z = clampf(objetivo.z, -MEDIO_LARGO + 0.5, MEDIO_LARGO - 0.5)
		elif bool(p.get("arbitro", false)):
			objetivo = _objetivo_arbitro(p, base, bola)
		elif _esta_celebrando(p):
			objetivo = Vector3(sign(base.x) * 32.0, 0, base.z * 0.4)
		elif es_por:
			objetivo = _objetivo_portero(base, bola, es_local)
		else:
			objetivo = _objetivo_jugador(base, bola, es_local, p, delta)
			## RONDA 3 (17-9-2026): SEPARACION entre companeros. La formula de
			## `_objetivo_jugador()` atrae a TODOS los de un lado hacia la
			## misma zona de la pelota -sin nada que los separe, dos o tres
			## companeros terminan apuntando casi al mismo punto, que es
			## exactamente lo que NUNCA pasa en un equipo real (nadie quiere
			## la pelota pegado a otro). Un empuje corto y barato -once
			## comparaciones como mucho por jugador- alcanza para que el
			## bloque se vea repartido en vez de amontonado.
			objetivo += _separacion(p, es_local)

		## BALANCEO SUTIL: sin esto, un jugador "quieto" en su ranura de
		## formacion se queda literalmente clavado -ni el mejor jugador del
		## mundo se para como una estatua-. Un vaivén de un par de decimas de
		## metro, desincronizado por jugador via `_fase`, rompe la sensacion
		## de bot sin mover a nadie fuera de su zona real. RONDA 2: mas quieto
		## cuanto mas cerca de la pelota -un jugador disputando el balon no
		## se balancea igual que uno esperando lejos de la jugada.
		var p_fase: float = p.get("_fase", 0.0)
		var dist_bola: float = node.position.distance_to(bola)
		var foco: float = clampf(dist_bola / 14.0, 0.12, 1.0)
		objetivo.x += sin(elapsed * 0.6 + p_fase) * 0.35 * foco
		objetivo.z += cos(elapsed * 0.47 + p_fase * 1.3) * 0.35 * foco

		## CORRECCION REAL (17-9-2026), reportada por el usuario como
		## movimiento "horrible": la separacion de la ronda 3 se sumaba SIN
		## volver a acotar a los limites de cancha, y se recalcula entera
		## cada fotograma sin ningun suavizado -si dos o tres companeros
		## quedan cerca (normal en un area), el empuje puede mandar el
		## objetivo fuera de la cancha y, como se recalcula de cero cada
		## fotograma, temblar en vez de asentarse. El clamp final es la red
		## de seguridad que faltaba.
		objetivo.x = clampf(objetivo.x, -MEDIO_ANCHO + 0.5, MEDIO_ANCHO - 0.5)
		objetivo.z = clampf(objetivo.z, -MEDIO_LARGO + 0.5, MEDIO_LARGO - 0.5)

		## RONDA 5 (17-9-2026): PRESIÓN. Cuando este jugador defiende -su equipo
		## no tiene la fase de ataque- un equipo con `presion` ALTA corre más
		## rápido a cerrar al rival; uno con presión BAJA deja jugar, no
		## persigue. Nada de esto se aplica si el propio equipo ataca -la
		## presión es una decisión SIN balón, no una prisa general.
		var tac_p := _tactica_de(es_local)
		var defendiendo := (fase == "ataqueVisita" and es_local) or (fase == "ataqueLocal" and not es_local)
		var mult_presion := 1.0
		if tac_p != null and defendiendo and not es_por and not bool(p.get("arbitro", false)):
			mult_presion = 1.0 + (float(tac_p.presion) - 1.0) * 0.12

		## RONDA 7 (17-9-2026): RITMO. Un equipo de ritmo alto juega mas rapido
		## de transicion -no solo cuando presiona, TODO el movimiento sin
		## balon es mas vivo-; uno de ritmo bajo controla, se mueve con mas
		## pausa. A diferencia de la presion (solo sin el balon en juego
		## rival), el ritmo pesa siempre que el equipo NO tiene la pelota
		## -con ella, quien decide el paso es quien la lleva, no la pizarra.
		var mult_ritmo := 1.0
		if tac_p != null and not es_por and not bool(p.get("arbitro", false)):
			mult_ritmo = 1.0 + (float(tac_p.ritmo) - 1.0) * 0.08

		var antes := node.position
		var vel_mult: float = p.get("_vel_mult", 1.0)
		## AJUSTE (18-9-2026): sin jugada ni presion rival ("medio", nadie ataca)
		## el bloque se mueve mas pausado -antes corria al mismo paso que en
		## plena jugada aunque el balon estuviera parado en el circulo central,
		## que es justo lo que el usuario leyo como "no se ve la jugada
		## planificada": si todo se mueve igual de rapido todo el tiempo, nada
		## resalta cuando de verdad pasa algo.
		var tiene_guion := pid_guion != null and float(_guion_hasta.get(pid_guion, -1.0)) > elapsed
		var mult_calma := 0.62 if (fase == "medio" and not tiene_guion and not _esta_celebrando(p)) else 1.0
		var paso: float = (5.8 if _esta_celebrando(p) else 3.4 * mult_calma) * vel_mult * mult_presion * mult_ritmo
		var dir := objetivo - antes
		dir.y = 0.0
		var dist := dir.length()

		## INERCIA: antes el jugador saltaba a velocidad máxima en el instante
		## que cambiaba de objetivo -frenar en seco y arrancar en seco es lo
		## que más se lee como control remoto, no como un cuerpo con masa-.
		## Ahora hay una velocidad DESEADA (más lenta cuanto más cerca del
		## objetivo, para no pasarse de largo y volver) y la velocidad de
		## verdad la persigue con una aceleración limitada.
		var vel_deseada := Vector3.ZERO
		if dist > 0.05:
			var frenado := clampf(dist / 1.8, 0.25, 1.0)
			vel_deseada = dir.normalized() * (paso * frenado)
		var acel: float = (18.0 if _esta_celebrando(p) else 11.0) * delta
		var vel_actual: Vector3 = p["_vel"]
		vel_actual = vel_actual.move_toward(vel_deseada, acel)
		p["_vel"] = vel_actual
		node.position += vel_actual * delta

		var vel := vel_actual.length()
		_animar(p, ap, vel, _esta_celebrando(p))
		if vel > 0.35:
			var ang_deseado := atan2(vel_actual.x, vel_actual.z)
			node.rotation.y = rotate_toward(node.rotation.y, ang_deseado, 8.5 * delta)

## Empuje de separacion respecto a los companeros de equipo que esten
## demasiado cerca (radio `SEPARACION_RADIO`). Solo mira jugadores de campo
## del MISMO equipo -arbitros, porteros y el propio jugador quedan fuera, cada
## uno ya tiene su propia logica de posicionamiento-. Cuanto mas cerca, mas
## fuerte empuja -el radio nunca deja que dos jugadores lleguen a superponerse
## de verdad, solo evita que ambos apunten al mismo metro cuadrado.
const SEPARACION_RADIO := 3.2

func _separacion(yo: Dictionary, es_local: bool) -> Vector3:
	var empuje := Vector3.ZERO
	var pos_yo: Vector3 = (yo["node"] as Node3D).position
	for otro in players:
		if otro == yo:
			continue
		if bool(otro.get("arbitro", false)) or otro.get("es_local") != es_local:
			continue
		if str(otro.get("slot_code", "")) == "POR":
			continue
		var n2: Node3D = otro.get("node")
		if not is_instance_valid(n2):
			continue
		var delta_pos := pos_yo - n2.position
		delta_pos.y = 0.0
		var d := delta_pos.length()
		if d > 0.001 and d < SEPARACION_RADIO:
			empuje += (delta_pos / d) * (SEPARACION_RADIO - d) * 0.5
	## Techo al empuje total (17-9-2026, corrigiendo el reporte de
	## movimiento "horrible"): con tres o mas companeros cerca a la vez -un
	## area en un corner, por ejemplo- la suma sin techo podia mandar el
	## objetivo varios metros de un salto, y como se recalcula entero cada
	## fotograma eso se lee como temblor, no como gente abriendose espacio.
	if empuje.length() > 1.6:
		empuje = empuje.normalized() * 1.6
	return empuje

## La `Tactica` del equipo de este jugador -`null` si `estadio.gd` no la pasó
## (ej. una prueba vieja), y entonces todo lo que sigue se queda en los
## valores de siempre (equilibrada/media en todo, cero cambio de comportamiento).
func _tactica_de(es_local: bool) -> Tactica:
	return local_tactica if es_local else visita_tactica

## Mismo criterio que mvObjetivo() en el HTML: la ranura de formacion, empujada
## por la fase del juego y atraida hacia la pelota para compactar el bloque.
## `p`/`delta` (ronda 2, 17-9-2026): el empuje real de la fase no se aplica de
## golpe, se PERSIGUE con la reaccion propia de este jugador
## (`p["_reaccion"]`, sembrada en `_mover()`) -es lo que evita que los 22
## cambien de intencion en el mismo fotograma exacto, la parte mas
## "colmena" de todo el movimiento viejo.
##
## RONDA 4 (17-9-2026): "que las tácticas se noten jugando". Hasta ahora esta
## funcion ignoraba por completo la pizarra (`Tactica`, la misma que decide
## fuerza_ataque/defensa en el partido de verdad) -mentalidad, línea y
## amplitud aquí abajo son las primeras tres perillas que YA se ven en el 3D:
##   MENTALIDAD escala cuánto empuja la fase de ataque -un equipo ofensivo
##     manda más gente arriba cuando ataca, uno defensivo se queda compacto.
##   LÍNEA sube o baja el bloque entero hacia la porteria rival o la propia,
##     independiente de la fase -es la altura de la línea defensiva de
##     siempre, la misma palabra que usa el jugador en Club → Táctica.
##   AMPLITUD abre o cierra el ancho que ocupa cada jugador respecto al
##     centro del campo -un equipo amplio se pega más a las bandas.
func _objetivo_jugador(base: Vector3, bola: Vector3, es_local: bool, p: Dictionary, delta: float) -> Vector3:
	var tac := _tactica_de(es_local)
	var dir_ataque: float = -1.0 if es_local else 1.0

	var mult_mentalidad := 1.0
	var offset_linea := 0.0
	var mult_amplitud := 1.0
	if tac != null:
		## [-1, 0, 1] para BAJO/MEDIO/ALTO -mismo enum `Tactica.Nivel`/`Mentalidad`.
		mult_mentalidad = 1.0 + (float(tac.mentalidad) - 1.0) * 0.3
		offset_linea = dir_ataque * (float(tac.linea) - 1.0) * 3.5
		mult_amplitud = 1.0 + (float(tac.amplitud) - 1.0) * 0.16
		## RONDA 8 (17-9-2026): FUERA DE JUEGO. La trampa del fuera de juego es
		## justo eso -una trampa-: la defensa sube el bloque MÁS de lo que le
		## tocaría por `linea`, pegada casi a la mitad de cancha, para dejar a
		## los delanteros rivales adelantados cuando llega el pase. Solo afecta
		## a los 5 puestos de defensa, y solo cuando ese equipo defiende -no
		## tiene sentido "hacer trampa del offside" atacando.
		var defensor := str(p.get("slot_code", "")) in PUESTOS_DEFENSA
		var def_ahora := (fase == "ataqueVisita" and es_local) or (fase == "ataqueLocal" and not es_local)
		if tac.fuera_de_juego and defensor and def_ahora:
			offset_linea += dir_ataque * 4.5
		## RONDA 9 (17-9-2026): SALIDA CORTA. Un equipo que arma desde atrás
		## necesita a sus centrales SEPARADOS entre sí para abrir un carril de
		## pase por dentro -pegados al medio, el rival tapa las dos opciones
		## con una sola presión-. Solo mientras este equipo tiene la pelota
		## (ataca) y solo para los defensores: no tiene sentido abrirse a lo
		## ancho defendiendo, eso ya lo decide `amplitud`.
		var atacando_ahora := (fase == "ataqueLocal" and es_local) or (fase == "ataqueVisita" and not es_local)
		if tac.salida_corta and defensor and atacando_ahora:
			mult_amplitud *= 1.22

	var empuje_obj := 0.0
	if fase == "ataqueLocal":
		empuje_obj = (-13.5 if es_local else -9.5) * mult_mentalidad
	elif fase == "ataqueVisita":
		empuje_obj = (9.5 if es_local else 13.5) * mult_mentalidad
	var reaccion: float = p.get("_reaccion", 2.5)
	var empuje: float = p.get("_empuje_actual", 0.0)
	empuje = move_toward(empuje, empuje_obj, (13.5 / reaccion) * delta)
	p["_empuje_actual"] = empuje
	var z: float = base.z + empuje + offset_linea
	var x: float = base.x * mult_amplitud
	x += (bola.x - x) * 0.18
	z += (bola.z - z) * 0.22
	var objetivo := Vector3(clampf(x, -MEDIO_ANCHO + 1.0, MEDIO_ANCHO - 1.0),
		0, clampf(z, -MEDIO_LARGO + 2.0, MEDIO_LARGO - 2.0))

	## RONDA 6 (17-9-2026): MARCA AL HOMBRE. Con el interruptor activo, un
	## defensor central o lateral deja de repartirse el espacio en zona y
	## empieza a seguir al rival más cercano de verdad -es la diferencia
	## visual más grande entre "defensa por zonas" y "marca individual", y
	## hasta ahora la casilla existía en Club → Táctica sin cambiar nada en
	## el campo. Solo los 5 puestos defensivos, y solo mientras el equipo
	## defiende -en ataque nadie marca a nadie.
	if tac != null and tac.marca_al_hombre and str(p.get("slot_code", "")) in PUESTOS_DEFENSA:
		var defendiendo := (fase == "ataqueVisita" and es_local) or (fase == "ataqueLocal" and not es_local)
		if defendiendo:
			## `Variant` explicito, no `:=` -inferir tipo desde un retorno
			## Variant es advertencia-como-error en este proyecto, y por eso
			## el propio `_rival_mas_cercano()` de mas abajo tambien declara
			## su retorno como `Variant` en vez de un tipo concreto.
			var rival: Variant = _rival_mas_cercano(p, es_local)
			if rival != null:
				var pos_rival: Vector3 = (rival["node"] as Node3D).position
				## 45% hacia el rival marcado, 55% zona: sigue a la persona
				## pero sin abandonar del todo la lectura del bloque -un
				## marcaje 100% individual saca a los centrales de su area
				## con cualquier movimiento del delantero, y eso ya no se
				## lee como táctica, se lee como un error de posicionamiento.
				objetivo = objetivo.lerp(Vector3(pos_rival.x, 0, pos_rival.z), 0.45)
				objetivo.x = clampf(objetivo.x, -MEDIO_ANCHO + 1.0, MEDIO_ANCHO - 1.0)
				objetivo.z = clampf(objetivo.z, -MEDIO_LARGO + 2.0, MEDIO_LARGO - 2.0)

	## APOYO CERCANO (18-9-2026): hasta ahora, sin una jugada con guion activa,
	## TODOS los del mismo lado tiran de la pelota con el mismo 18%/22% de
	## `_objetivo_jugador()` -reparto de zona parejo, nadie decide nada en
	## particular-. Eso es exactamente lo que el usuario pidió que dejara de
	## pasar: que el movimiento sin balón tenga sentido por sí solo, no solo
	## durante una jugada prehecha. Aquí el compañero de campo MÁS CERCANO al
	## balón, cuando su equipo ataca, recibe un tirón extra hacia una posición
	## de apoyo -a un lado del balón, no encima, y un poco adelantado en la
	## dirección de ataque- para leerse como "alguien ofrece un pase", no como
	## el bloque entero flotando hacia la pelota a la vez. Solo ese jugador: el
	## resto sigue con el reparto de zona de siempre, que es lo que evita que
	## se lea como una segunda "jugada con guion" encubierta.
	var atacando_de_verdad := (fase == "ataqueLocal" and es_local) or (fase == "ataqueVisita" and not es_local)
	if atacando_de_verdad and str(p.get("slot_code", "")) != "POR" and not bool(p.get("arbitro", false)):
		var yo_nodo: Node3D = p.get("node")
		if is_instance_valid(yo_nodo) and yo_nodo.position.distance_to(bola) < 18.0:
			var mas_cercano: Variant = _companero_mas_cercano_al_balon(es_local, bola)
			if mas_cercano != null and str(mas_cercano.get("id", "")) == str(p.get("id", "")):
				var lado: float = 1.0 if base.x >= 0.0 else -1.0
				var apoyo := Vector3(bola.x + lado * 6.0, 0, bola.z + dir_ataque * 4.0)
				apoyo.x = clampf(apoyo.x, -MEDIO_ANCHO + 1.0, MEDIO_ANCHO - 1.0)
				apoyo.z = clampf(apoyo.z, -MEDIO_LARGO + 2.0, MEDIO_LARGO - 2.0)
				objetivo = objetivo.lerp(apoyo, 0.5)
	return objetivo

## El compañero de campo (mismo equipo, sin árbitro ni portero) más cercano al
## BALÓN -no a un jugador en particular-, para decidir cuál de los cercanos
## hace el movimiento de apoyo. `null` si no hay ninguno (no debería pasar en
## un partido real, solo en una prueba con un `players` incompleto).
func _companero_mas_cercano_al_balon(es_local: bool, bola: Vector3) -> Variant:
	var mejor: Variant = null
	var mejor_d := INF
	for otro in players:
		if bool(otro.get("arbitro", false)) or otro.get("es_local") != es_local:
			continue
		if str(otro.get("slot_code", "")) == "POR":
			continue
		var n: Node3D = otro.get("node")
		if not is_instance_valid(n):
			continue
		var d := n.position.distance_squared_to(bola)
		if d < mejor_d:
			mejor_d = d
			mejor = otro
	return mejor

## El rival de campo mas cercano a `yo` -para la marca al hombre-. Arbitros,
## porteros y el propio equipo quedan fuera. `null` si no hay ninguno vivo
## (no deberia pasar en un partido de verdad, pero una prueba puede armar un
## `players` incompleto).
func _rival_mas_cercano(yo: Dictionary, es_local: bool) -> Variant:
	var pos_yo: Vector3 = (yo["node"] as Node3D).position
	var mejor: Variant = null
	var mejor_d := INF
	for otro in players:
		if bool(otro.get("arbitro", false)) or otro.get("es_local") == es_local:
			continue
		if str(otro.get("slot_code", "")) == "POR":
			continue
		var n2: Node3D = otro.get("node")
		if not is_instance_valid(n2):
			continue
		var d := pos_yo.distance_squared_to(n2.position)
		if d < mejor_d:
			mejor_d = d
			mejor = otro
	return mejor

## El arbitro sigue la jugada pero por fuera, en diagonal, y sin meterse en el
## medio; los jueces de linea se deslizan por su banda a la altura del balon,
## cada uno en su mitad del campo. Es como se colocan de verdad, y ademas evita
## que un arbitro con el mismo criterio que un jugador acabe dentro del area.
func _objetivo_arbitro(p: Dictionary, base: Vector3, bola: Vector3) -> Vector3:
	if str(p["id"]) == "arbitro":
		var d := Vector3(bola.x, 0, bola.z) - Vector3(base.x, 0, base.z)
		var lejos := Vector3(bola.x - 9.0, 0, bola.z + 9.0)
		if d.length() < 1.0:
			lejos = base
		return Vector3(clampf(lejos.x, -30.0, 30.0), 0, clampf(lejos.z, -46.0, 46.0))
	var mitad: float = -1.0 if str(p["id"]) == "linea_a" else 1.0
	var z: float = clampf(bola.z, 0.0, 50.0) if mitad > 0.0 else clampf(bola.z, -50.0, 0.0)
	return Vector3(base.x, 0, z)

func _objetivo_portero(base: Vector3, bola: Vector3, es_local: bool) -> Vector3:
	var x: float = clampf(bola.x * 0.30, -6.5, 6.5)
	var z: float = base.z
	var lejania: float = clampf(absf(bola.z - base.z) / MEDIO_LARGO, 0.0, 1.0)
	z += (-6.0 if es_local else 6.0) * lejania
	return Vector3(x, 0, z)

const VEL_CICLO := {"correr": 6.2, "trotar": 3.05, "caminar": 1.35}

func _animar(p: Dictionary, ap: AnimationPlayer, vel: float, celebrando: bool) -> void:
	if not is_instance_valid(ap):
		return
	var pid = p.get("id")
	if pid != null and _acciones_activas.has(pid):
		var acc: Dictionary = _acciones_activas[pid]
		if elapsed < acc["hasta"]:
			var nom: String = acc["anim"]
			if ap.current_animation != nom and ap.has_animation(nom):
				ap.play(nom)
				ap.speed_scale = 1.0
			return
		else:
			_acciones_activas.erase(pid)

	var realista := ap.has_animation("correr")
	var es_por: bool = str(p.get("slot_code", "")) == "POR"
	var quiere: String
	if celebrando:
		quiere = "celebrar" if realista else "jump"
	elif vel > 2.6:
		quiere = "correr" if realista else "run"
	elif vel > 1.1:
		quiere = "trotar" if realista else "run"
	elif vel > 0.35:
		quiere = "caminar" if realista else "run"
	elif es_por and realista and ap.has_animation("portero_listo"):
		quiere = "portero_listo"
	else:
		quiere = "parado" if realista else "idle"
	if ap.current_animation != quiere and ap.has_animation(quiere):
		ap.play(quiere)
	if VEL_CICLO.has(quiere):
		## Documento maestro: TimeScale = velocidad real / velocidad de ciclo,
		## acotado para que el pie no deslice ni se convierta en un dibujo.
		ap.speed_scale = clampf(vel / float(VEL_CICLO[quiere]), 0.6, 1.4)
	else:
		ap.speed_scale = 1.0

## Dispara un suceso VENIDO DE FUERA, en el momento en que ocurre.
##
## El diseño original de esta clase era reproducir un partido ya jugado: se le
## daba la lista entera de sucesos y el reloj los iba sacando por minuto. Aquí el
## partido se está jugando de verdad mientras se mira, así que los sucesos llegan
## de las señales de `Partido` cuando pasan, no antes.
##
## Se expone así, con nombre propio, en vez de dejar que quien llama toque
## `_disparar()`: los dos usos conviven -una repetición sigue funcionando igual-
## y queda claro cuál es la puerta de entrada para el modo en vivo.
func suceso(ev: Dictionary) -> void:
	_disparar(ev)
