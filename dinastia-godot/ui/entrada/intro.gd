class_name IntroMarca
extends "res://ui/entrada/intro_capas.gd"
## LA INTRO DE MARCA (fase 1 del MEGAPLAN, etapa 0 de la entrada, 25-10-2026). Lo primero que
## se ve al abrir el juego: un escudo que se traza en oro, la corona, «DINASTÍA» letra a letra,
## un destello con chispas, el lema y fundido a negro. 4,75 s en total (el plan pide ≤ 5).
## [Capa 3/3] El dibujo vive en `intro_dibujo.gd` y `intro_capas.gd`; aquí, el reloj, el salto, el sonido y el contrato.
##
## CONTRATO de las pantallas de la entrada (`ui/entrada/orquestador.gd`):
##   signal terminado(datos)  → al acabar, con `{}` (la intro no elige nada). Una sola vez.
##   signal volver()          → existe por el contrato, pero la intro NUNCA la emite: es la
##                              primera etapa y no tiene nada detrás.
##   configurar(estado)       → solo mira `estado["intro_vista"]`: si es true, un clic, una
##                              tecla, un toque o un botón del mando la saltan (fundido corto).
##                              La primera vez NO se puede saltar: es la presentación del juego.
##
## EL RELOJ. Avanza con el delta del fotograma, recortado a 0,1 s: un tirón al cargar (la
## primera compilación de los shaders) no se come el principio de la animación. Y para que
## eso nunca la alargue de más, hay un tope en tiempo REAL: a los 5 s de verdad termina sí o sí.
##
## EL SONIDO sale del autoload `Sonido` (todo sintetizado, respeta su volumen y su «apagado»):
## un roce al empezar el trazo, el acorde largo de `fin_temporada` como colchón y el «tin-TON»
## de `logro` en el destello. Se sintetizan en un hilo al entrar: pedirlos en el momento
## costaría un tirón justo en el fotograma más vistoso. Si a su hora aún no están, ese
## sonido no suena: mejor callar que dar un salto.

signal terminado(datos: Dictionary)
signal volver()

const TOPE_REAL := 5.0
## Fundido del salto: corto, pero no un corte en seco.
const SALIDA_RAPIDA := 0.28
const PISTAS := [[0.22, "deslizar"], [2.30, "fin_temporada"], [2.42, "logro"]]

var _vista := false
var _acabada := false
var _congelada := false
var _t_salto := -1.0
var _inicio_ms := 0
var _pistas_hechas := 0
var _tareas: Dictionary = {}   ## nombre del sonido → id de la tarea que lo sintetiza

func configurar(estado: Dictionary) -> void:
	_vista = bool(estado.get("intro_vista", false))

func _ready() -> void:
	## Anclas Y márgenes: con solo las anclas, los márgenes del tamaño 0 de antes de entrar al
	## árbol se quedaban y la intro medía 0×0 dentro del orquestador.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	## Que una pausa del árbol no la deje congelada a medias.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_montar()
	## Bajo un Control (el orquestador) las anclas bastan; colgada de un Node suelto (una
	## escena de prueba) no hay rectángulo padre y se quedaría en 0×0: sigue a la ventana.
	if not (get_parent() is Control):
		## Anclas arriba a la izquierda: con las de pantalla completa Godot pisaría el tamaño.
		set_anchors_preset(Control.PRESET_TOP_LEFT)
		_seguir_ventana()
		get_viewport().size_changed.connect(_seguir_ventana)
	_preparar_sonidos()
	_inicio_ms = Time.get_ticks_msec()
	_pintar()

func _seguir_ventana() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size

func _process(delta: float) -> void:
	if _acabada or _congelada:
		return
	avanzar(minf(delta, 0.1))
	var real := (Time.get_ticks_msec() - _inicio_ms) / 1000.0
	## Si los tirones la han retrasado, se adelanta el fundido para llegar al tope sin un corte.
	if real >= TOPE_REAL - SALIDA_RAPIDA - 0.05 and _t_salto < 0.0 and _t < T_SALIDA:
		_t_salto = _t
	if real >= TOPE_REAL:
		_acabar()

## Un paso del reloj (lo usa `_process` y la prueba, que lo mueve a mano).
func avanzar(delta: float) -> void:
	if _acabada:
		return
	_t += delta
	if _t_salto >= 0.0:
		_velo_extra = clampf((_t - _t_salto) / SALIDA_RAPIDA, 0.0, 1.0)
	else:
		_tocar_pistas()
	_pintar()
	if _t >= DURACION or (_t_salto >= 0.0 and _t - _t_salto >= SALIDA_RAPIDA):
		_acabar()

## Lleva la animación al instante `t` y, si `congelar`, la deja quieta ahí (capturas).
## Los sonidos de antes de `t` se dan por sonados.
func fijar_tiempo(t: float, congelar: bool = true) -> void:
	_t = clampf(t, 0.0, DURACION)
	_congelada = congelar
	while _pistas_hechas < PISTAS.size() and float(PISTAS[_pistas_hechas][0]) <= _t:
		_pistas_hechas += 1
	_pintar()

func tiempo() -> float:
	return _t

func acabada() -> bool:
	return _acabada

func se_puede_saltar() -> bool:
	return _vista

## Salta la intro si ya se vio; si no, no hace nada. Devuelve si saltó.
func saltar() -> bool:
	if not _vista or _acabada:
		return false
	if _t_salto < 0.0:
		_t_salto = _t
	return true

func _input(ev: InputEvent) -> void:
	if _acabada or not is_visible_in_tree() or not _es_pulsacion(ev):
		return
	## Se la queda aunque no salte: nada de lo que haya debajo debe enterarse.
	get_viewport().set_input_as_handled()
	saltar()

static func _es_pulsacion(ev: InputEvent) -> bool:
	if ev is InputEventKey:
		return (ev as InputEventKey).pressed and not (ev as InputEventKey).echo
	if ev is InputEventMouseButton:
		return (ev as InputEventMouseButton).pressed
	if ev is InputEventJoypadButton:
		return (ev as InputEventJoypadButton).pressed
	if ev is InputEventScreenTouch:
		return (ev as InputEventScreenTouch).pressed
	return false

func _acabar() -> void:
	if _acabada:
		return
	_acabada = true
	## Se queda en negro: el orquestador funde desde aquí a la etapa siguiente.
	_velo.color.a = 1.0
	set_process(false)
	terminado.emit({})

# --- sonido ---------------------------------------------------------------------

func _sonido() -> Node:
	return get_node_or_null("/root/Sonido")

func _preparar_sonidos() -> void:
	var s := _sonido()
	if s == null or not s.has_method("banco"):
		return
	for p: Array in PISTAS:
		var n := String(p[1])
		if not _tareas.has(n):
			_tareas[n] = WorkerThreadPool.add_task(s.banco.bind(n), false, "intro: sonido")

func _tocar_pistas() -> void:
	while _pistas_hechas < PISTAS.size() and float(PISTAS[_pistas_hechas][0]) <= _t:
		var n := String(PISTAS[_pistas_hechas][1])
		_pistas_hechas += 1
		var s := _sonido()
		if s == null:
			continue
		if _tareas.has(n):
			if not WorkerThreadPool.is_task_completed(_tareas[n]):
				continue
			WorkerThreadPool.wait_for_task_completion(_tareas[n])
			_tareas.erase(n)
		s.call("toca", n)

func _exit_tree() -> void:
	## Cada tarea del grupo de hilos hay que esperarla una vez (lo pide Godot para liberarla).
	for n: String in _tareas:
		WorkerThreadPool.wait_for_task_completion(_tareas[n])
	_tareas.clear()
