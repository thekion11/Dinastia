extends RefCounted
## (Parte 1 de 4 de `match_playback.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `match_playback.gd`, conserva la clase.)

## Reproduce el partido ya simulado. La simulacion NO se rehace aqui: el HTML
## decidio quien gano, quien marco y en que minuto. Esto solo lo DRAMATIZA, que
## es exactamente el mismo reparto de responsabilidades que ya usa el visor 2D
## del juego (mvTick/mvObjetivo dibujan, simularMinuto decide).
##
## El flujo del juego se deduce de dos cosas que si vienen en el JSON: la
## posesion final del local y la linea de eventos con su minuto y su equipo.

signal event_fired(text: String)
## Una jugada del catálogo empieza a escenificarse (para el rótulo de la TV).
signal jugada_ambiente(nombre: String, es_local: bool)
## El árbitro pide revisar una jugada: la pantalla abre la sala VAR.
signal revision_var(minuto: int, motivo: String)
const PROB_JUGADA_AMBIENTE := 0.4
var _jugadas_ambiente := true

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

## Acciones temporales por jugador: pid -> {"anim": String, "hasta": float}
var _acciones_activas: Dictionary = {}
## Gestos que llegan un poco después del suceso: [cuándo (elapsed), id, animación, duración]
var _gestos_pendientes: Array = []
var _anadido_mostrado := false

## CUERPOS QUE NO SE ATRAVIESAN (13-10-2026, «las físicas siguen siendo de lo
## peor»). La separación de arriba solo mira a los compañeros: un defensa se
## metía DENTRO del delantero que presionaba. Aquí, después de mover a todos,
## cada par (rivales y árbitro incluidos) que quede a menos de dos «radios de
## hombro» se aparta a medias por la línea que los une. 22+3 cuerpos: ~300
## comparaciones baratas por fotograma.
const RADIO_CUERPO := 0.31

## Empuje de separacion respecto a los companeros de equipo que esten
## demasiado cerca (radio `SEPARACION_RADIO`). Solo mira jugadores de campo
## del MISMO equipo -arbitros, porteros y el propio jugador quedan fuera, cada
## uno ya tiene su propia logica de posicionamiento-. Cuanto mas cerca, mas
## fuerte empuja -el radio nunca deja que dos jugadores lleguen a superponerse
## de verdad, solo evita que ambos apunten al mismo metro cuadrado.
const SEPARACION_RADIO := 3.2

## `conducir`: el Dribble_03 del mocap avanza ~1,15 m/s llevando el balón.
const VEL_CICLO := {"correr": 6.2, "trotar": 3.05, "caminar": 1.35, "conducir": 1.15}

## EL QUE LLEVA EL BALÓN (25-9-2026). Hasta hoy nadie "tenía" la pelota: el
## más cercano corría igual que los demás y el balón iba pegado a sus pies
## sin que las piernas hicieran nada con él. Ahora, cada fotograma, el jugador
## de campo que está encima del balón (a menos de `RADIO_PORTADOR`, balón a ras
## de césped) lo conduce con el mocap de regate; si un rival se le echa encima,
## amaga (`regate_finta`); si su equipo ataca y él está parado, lo pisa y
## protege (`regate_pausa`). Los tres son clips de captura real del mismo pack
## de fútbol, sin desplazamiento propio: el partido sigue moviendo al jugador.
const RADIO_PORTADOR := 1.4
## Distancia del rival a la que el portador amaga. Medido en un partido real
## (`pruebas/prueba_regates.gd`): el balón cambia de pies cada 1-2 s, así que
## el rival que sale a presionar rara vez llega a menos de 4 m; a 6 m ya viene
## encima y el amague se lee como respuesta a él.
const RADIO_PRESION := 6.0
const RADIO_IR_A_PRESIONAR := 16.0
var _presionador: Dictionary = {}
const PAUSA_ENTRE_REGATES := 5.0
var _portador: Dictionary = {}
var _proximo_regate: Dictionary = {}   ## id -> elapsed a partir del cual puede volver a amagar
var regates_hechos := 0                ## para las pruebas

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

func _buscar_portador(bola: Vector3) -> Dictionary:
	if not is_instance_valid(ball) or bola.y > 0.4:
		return {}
	var mejor: Dictionary = {}
	var mejor_d := RADIO_PORTADOR * RADIO_PORTADOR
	for p in players:
		if bool(p.get("arbitro", false)) or str(p.get("slot_code", "")) == "POR":
			continue
		var n: Node3D = p.get("node")
		if not is_instance_valid(n):
			continue
		var d := Vector2(n.position.x - bola.x, n.position.z - bola.z).length_squared()
		if d < mejor_d:
			mejor_d = d
			mejor = p
	return mejor

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

# ---------------------------------------------------------------- movimiento

func _esta_celebrando(p: Dictionary) -> bool:
	for c in _celebrando:
		if c["p"] == p:
			return true
	return false

func _objetivo_portero(base: Vector3, bola: Vector3, es_local: bool) -> Vector3:
	var x: float = clampf(bola.x * 0.30, -6.5, 6.5)
	var z: float = base.z
	var lejania: float = clampf(absf(bola.z - base.z) / MEDIO_LARGO, 0.0, 1.0)
	z += (-6.0 if es_local else 6.0) * lejania
	return Vector3(x, 0, z)

## La `Tactica` del equipo de este jugador -`null` si `estadio.gd` no la pasó
## (ej. una prueba vieja), y entonces todo lo que sigue se queda en los
## valores de siempre (equilibrada/media en todo, cero cambio de comportamiento).
func _tactica_de(es_local: bool) -> Tactica:
	return local_tactica if es_local else visita_tactica

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
