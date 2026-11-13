class_name EstadioSonidos
extends RefCounted
## SONIDOS DEL PARTIDO QUE NO SONABAN (13-11-2026, informe `sonidos_sin_pedir_2026-11-13.md`): cada uno suena donde el jugador VE el hecho
## (aviso del árbitro, gesto, atajada, ola de la grada, final). `Sonido.toca` no toca `Azar` (las huellas no cambian), respeta el
## interruptor de sonido y los volúmenes. Lo frecuente lleva ENFRIAMIENTO en segundos de reloj real (`con_espera`).
static var _ultimo := {}

## Suena `nombre` si pasaron `espera` s desde la última vez que sonó con esta función.
static func con_espera(nombre: String, espera: float, bus: Sonido.Bus = Sonido.Bus.EFECTOS) -> void:
	var ahora := Time.get_ticks_msec()
	if ahora - int(_ultimo.get(nombre, -1000000)) < int(espera * 1000.0):
		return
	_ultimo[nombre] = ahora
	Sonido.toca(nombre, bus)

## Lo que dice el árbitro / el narrador del motor (`aviso`): el texto lo escribe `motor_jugable*`.
static func aviso(texto: String) -> void:
	if texto == "Saque de banda":
		Sonido.toca("fuera_de_banda")
	elif texto == "Saque de puerta":
		Sonido.toca("saque_puerta")
	elif texto == "Córner":
		Sonido.toca("fuera_terreno_juego")   ## el balón salió por la línea de fondo
	elif texto == "¡Atajada!":
		Sonido.toca("atajada_pies")
	elif texto == "¡Qué parada!":
		Sonido.toca("atajada_punos")
	elif texto.begins_with("🟥 ¡Roja! Segunda amarilla"):
		Sonido.toca("segunda_amarilla")
	elif texto == "🔥 ¡Presión de equipo!":
		con_espera("presion_alta", 20.0, Sonido.Bus.AMBIENTE)

## El gesto del árbitro (`gesto_arbitro`): el tiempo añadido y la amonestación hablada.
static func gesto(g: String) -> void:
	if g == "arbitro_tiempo_anadido":
		Sonido.toca("tiempo_anadido")
	elif g == "arbitro_amonestar_hablar":
		Sonido.toca("amonestacion_verbal")

## Un penal de la tanda: gol o fallo (antes el fallo sonaba como «ocasión»).
static func penal_de_tanda(marcado: bool) -> void:
	Sonido.toca("gol" if marcado else "penal_fallado", Sonido.Bus.AMBIENTE)

## El VAR anuló el gol.
static func var_anulado() -> void:
	Sonido.toca("var_anulado")

## Pitido final y, unos segundos después, la gente saliendo del estadio.
static func final_del_partido() -> void:
	Sonido.toca("pitido_final")
	var arbol := Engine.get_main_loop() as SceneTree
	if arbol != null:
		arbol.create_timer(4.0).timeout.connect(func() -> void: Sonido.toca("multitud_saliendo", Sonido.Bus.AMBIENTE))

## El goleador celebra solo y, unos segundos después, sus compañeros se le echan encima (`_ia_celebracion` del motor).
static func celebracion() -> void:
	var arbol := Engine.get_main_loop() as SceneTree
	if arbol == null:
		return
	arbol.create_timer(0.7).timeout.connect(func() -> void: Sonido.toca("celebracion_individual", Sonido.Bus.AMBIENTE))
	arbol.create_timer(2.4).timeout.connect(func() -> void: Sonido.toca("celebracion_grupal", Sonido.Bus.AMBIENTE))

## Antes del saque inicial: la gente entrando a la grada.
static func antes_del_saque() -> void:
	Sonido.toca("multitud_entrando", Sonido.Bus.AMBIENTE)

## El clima del estadio: viento y calor además del ambiente de siempre.
static func clima(c: String) -> void:
	if c == "tarde":
		Sonido.toca("calor_extremo", Sonido.Bus.AMBIENTE)
	elif c == "nieve" or c == "niebla":
		Sonido.toca("viento_fuerte", Sonido.Bus.AMBIENTE)

## Las olas de la grada traen su sonido (`OlaGrada.lanzar`).
static func ola(tipo: String) -> void:
	if tipo == "ola":
		Sonido.toca("ola_mexicana", Sonido.Bus.AMBIENTE)
	elif tipo == "protesta":
		con_espera("protesta_masiva", 8.0, Sonido.Bus.AMBIENTE)
