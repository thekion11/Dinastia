extends Node
## CAZA DE FALLOS (4-11-2026, orden de la líder): la VIDA DE LA APP EN EL MÓVIL durante el partido (`VidaApp`).
##   godot --headless --path . res://pruebas/auditoria_vida_app_limite.tscn
## Segundo plano / foco perdido / «atrás» / poca memoria / girar la pantalla con el partido 3D jugable y el simulado en vivo abiertos: el partido se pausa solo y no corre el reloj,
## se sueltan los botones táctiles, «atrás» abre y cierra la pausa (y no cierra el juego), tras minutos en segundo plano el primer fotograma no se traga el partido.
const LIENZO := Vector2(1600, 720)
var _n := 0
var _fallos := 0
var _ui: CarreraJugadorUI
var _pj: PartidoJugable
var _vivo: PartidoVivo
var _fase := 0
var _t_ref := 0.0
var _corriendo := false

func _comprobar(ok: bool, texto: String) -> void:
	print(("  ok     " if ok else "  FALLO  ") + texto)
	if not ok:
		_fallos += 1

func _ready() -> void:
	PartidoJugable.con_ceremonia = false
	ControlesTactiles.forzar = true
	PantallaMovil.dpi_forzado = 400.0
	PantallaMovil.ventana_forzada = Vector2i(2400, 1080)
	PantallaMovil.lienzo_forzado = LIENZO
	AjustesTactil.restaurar()
	CarreraJugadorUI.mundo = null
	_ui = load("res://escenas/carrera_jugador.tscn").instantiate()
	add_child(_ui)

func _notif(que: int) -> void:
	get_tree().root.propagate_notification(que)
	await get_tree().process_frame

func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		_ui._crear()
	if _n == 20:
		var club := _ui.carrera.club(CarreraJugadorUI.mundo)
		var par := _ui._partido_de_la_semana(club)
		_pj = PartidoJugable.abrir(_ui, CarreraJugadorUI.mundo, _ui.carrera, par[0], par[1], 120.0)
		_pj.size = LIENZO
		(_pj.get_node("ControlesTactiles") as Control).size = LIENZO
		_pj.motor.autopiloto = false
	if _n == 60 and not _corriendo:
		_corriendo = true
		await _jugable()
		await _en_vivo()
		_fin()

func _jugable() -> void:
	var m: MotorJugable = _pj.motor
	var va := _pj.get_node_or_null("VidaApp") as VidaApp
	_comprobar(va != null, "el partido 3D jugable lleva su VidaApp")
	_comprobar(not get_tree().quit_on_go_back, "con el partido abierto, «atrás» no cierra el juego por su cuenta")
	## Un dedo en el botón de tiro y el stick, y la app pasa a segundo plano.
	var ct := _pj.get_node("ControlesTactiles") as ControlesTactiles
	var t := InputEventScreenTouch.new()
	t.index = 1; t.position = ct.centro_de("TI"); t.pressed = true
	Input.parse_input_event(t)
	Input.action_press("jugar_tiro")
	_comprobar(_pj._pausa == null, "el partido empieza sin pausa")
	await _notif(Node.NOTIFICATION_APPLICATION_PAUSED)
	_comprobar(_pj._pausa != null, "la app pasa a segundo plano: el partido se pausa solo")
	_comprobar(not Input.is_action_pressed("jugar_tiro") and ct._dedos.is_empty(), "…y se sueltan los botones (no se vuelve con el tiro «pulsado»)")
	var t0: float = m.t
	for i in 30:
		m.paso(0.0)   ## (el motor no corre en pausa: su proceso está apagado)
	_comprobar(not m.is_physics_processing(), "…y el motor no corre")
	await _notif(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await _notif(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	_comprobar(_pj._pausa != null, "perder el foco varias veces seguidas no la quita ni la duplica")
	await _notif(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_comprobar(_pj._pausa == null and m.is_physics_processing(), "«atrás» con la pausa abierta la cierra (y el partido sigue)")
	await _notif(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_comprobar(_pj._pausa != null, "«atrás» con el partido en juego abre la pausa (no cierra el juego)")
	_alternar_cerrar()
	## Girar la pantalla / cambiar la ventana: se sueltan los dedos y no pasa nada.
	await _notif(Node.NOTIFICATION_WM_SIZE_CHANGED)
	_comprobar(ct._dedos.is_empty(), "girar la pantalla suelta los dedos")
	## Poca memoria: calidad mínima al momento.
	Calidad.elegida = Calidad.ALTO
	await _notif(Node.NOTIFICATION_OS_MEMORY_WARNING)
	_comprobar(Calidad.elegida == Calidad.MINIMO, "poca memoria del sistema: calidad mínima")
	## Tras minutos en segundo plano, el primer fotograma trae un delta enorme: no se traga el partido.
	var min_antes: float = m.minutos_usuario
	_pj._process(600.0)
	_comprobar(m.minutos_usuario - min_antes < 1.0 and m.t - t0 < 5.0, "un fotograma de 10 minutos no avanza el partido (minutos del jugador +%.2f)" % (m.minutos_usuario - min_antes))

func _alternar_cerrar() -> void:
	if _pj._pausa != null:
		_pj._alternar_pausa()

func _en_vivo() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var l := m.ligas[0]
	var p := Partido.new(l.clubes[0], l.clubes[1])
	_vivo = PartidoVivo.new()
	_vivo.con_3d = false
	add_child(_vivo)
	_vivo.abrir(p, l.clubes[0], m.vestuario)
	_comprobar(_vivo.get_node_or_null("VidaApp") != null, "el simulado en vivo lleva su VidaApp")
	_vivo.call("_poner_velocidad", 2)
	await _notif(Node.NOTIFICATION_APPLICATION_PAUSED)
	_comprobar(int(_vivo.get("_velocidad")) == 0, "en segundo plano el simulado en vivo se para (velocidad 0)")
	var min0 := p.minuto
	for i in 20:
		_vivo._process(1.0)
	_comprobar(p.minuto == min0, "y el reloj no corre mientras tanto (%d' → %d')" % [min0, p.minuto])
	_vivo.call("_poner_velocidad", 2)
	var min1 := p.minuto
	_vivo._process(600.0)   ## diez minutos de pantalla bloqueada de golpe
	_comprobar(p.minuto - min1 <= 3, "un fotograma de 10 minutos no se traga el partido (+%d minutos)" % (p.minuto - min1))
	_vivo.queue_free()

func _fin() -> void:
	ControlesTactiles.forzar = false
	PantallaMovil.dpi_forzado = 0.0
	PantallaMovil.ventana_forzada = Vector2i.ZERO
	PantallaMovil.lienzo_forzado = Vector2.ZERO
	AjustesTactil.restaurar()
	Calidad.elegida = Calidad.MINIMO
	print("===== FIN. %d fallos =====" % _fallos)
	get_tree().quit(0 if _fallos == 0 else 1)
