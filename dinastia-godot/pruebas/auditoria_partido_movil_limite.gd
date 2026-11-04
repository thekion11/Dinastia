extends Node
## CAZA DE FALLOS (4-11-2026, orden de la líder): el PARTIDO 3D al límite en el móvil.
##   godot --headless --path . res://pruebas/auditoria_partido_movil_limite.tscn
## 50 veces seguidas, a mitad de partido: abrir/cerrar la pausa, cambiar la calidad, girar la pantalla (vertical ↔ horizontal) y mandar «cambio de tamaño»; después ida y vuelta al segundo
## plano durante el DESCANSO, una TANDA DE PENALES (varias veces) y una REPETICIÓN de gol: el partido se pausa al salir, se reanuda al elegir el jugador y llega al final sin trabarse.
const LIENZO := Vector2(1600, 720)
var _n := 0
var _fallos := 0
var _ui: CarreraJugadorUI
var _pj: PartidoJugable
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

func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		_ui._crear()
	if _n == 20 and not _corriendo:
		_corriendo = true
		await _todo()
		ControlesTactiles.forzar = false
		PantallaMovil.dpi_forzado = 0.0
		PantallaMovil.ventana_forzada = Vector2i.ZERO
		PantallaMovil.lienzo_forzado = Vector2.ZERO
		AjustesTactil.restaurar()
		Calidad.elegida = Calidad.MINIMO
		print("===== FIN. %d fallos =====" % _fallos)
		get_tree().quit(0 if _fallos == 0 else 1)

func _marco(k: int) -> void:
	for i in k:
		await get_tree().process_frame

func _notif(que: int) -> void:
	get_tree().root.propagate_notification(que)
	await _marco(2)

func _abrir(eliminatoria := false) -> void:
	if is_instance_valid(_pj):
		_pj.queue_free()
		await _marco(2)
	var club := _ui.carrera.club(CarreraJugadorUI.mundo)
	var par := _ui._partido_de_la_semana(club)
	_pj = PartidoJugable.abrir(_ui, CarreraJugadorUI.mundo, _ui.carrera, par[0], par[1], 12.0, -1, null, eliminatoria)
	_pj.size = LIENZO
	(_pj.get_node("ControlesTactiles") as Control).size = LIENZO
	_pj.motor.autopiloto = true
	await _marco(10)

func _quieto_o_corre() -> bool:
	return (_pj._pausa == null) == _pj.motor.is_physics_processing()

func _todo() -> void:
	await _abrir()
	var ventana := get_window()
	var tam0 := ventana.size
	var hijos0 := _pj.get_child_count()
	var incoherentes := 0
	for i in 50:
		_pj._alternar_pausa()
		Calidad.elegida = [Calidad.MINIMO, Calidad.MEDIO, Calidad.ALTO][i % 3]
		Calidad.aplicar_viewport(_pj._vp, Calidad.elegida)
		ventana.size = Vector2i(1080, 2400) if i % 2 == 0 else Vector2i(2400, 1080)
		get_tree().root.propagate_notification(Node.NOTIFICATION_WM_SIZE_CHANGED)
		await _marco(1)
		if not _quieto_o_corre():
			incoherentes += 1
		if i % 5 == 4:
			_pj._alternar_pausa()   ## abre/cierra a ritmos distintos
			await _marco(1)
			if not _quieto_o_corre():
				incoherentes += 1
	if _pj._pausa != null:
		_pj._alternar_pausa()
	await _marco(2)
	ventana.size = tam0
	_comprobar(incoherentes == 0 and _quieto_o_corre(), "50 pausas abiertas/cerradas con calidad y giro de pantalla: el motor y la pausa siempre coherentes (%d incoherencias)" % incoherentes)
	_comprobar(_pj.get_child_count() <= hijos0 + 2, "…y no quedan capas de pausa sueltas (%d hijos, antes %d)" % [_pj.get_child_count(), hijos0])
	_comprobar(not _pj.motor.estado.is_empty() and _pj.motor.estado != "fin", "el partido sigue vivo (%s)" % _pj.motor.estado)
	await _descanso()
	await _tanda()
	await _repeticion()

func _ida_y_vuelta() -> void:
	await _notif(Node.NOTIFICATION_APPLICATION_PAUSED)
	var pauso := _pj._pausa != null
	await _notif(Node.NOTIFICATION_APPLICATION_RESUMED)
	if _pj._pausa != null:
		_pj._alternar_pausa()
	await _marco(1)
	_comprobar(pauso, "  (la app salió y el partido se pausó solo)")

func _descanso() -> void:
	await _abrir()
	var m: MotorJugable = _pj.motor
	m.set_physics_process(false)
	m.t = m.dur_mitad() - 0.05
	for i in 400:
		m.paso(1.0 / 30.0)
		if m.estado == "descanso":
			break
	_comprobar(m.estado == "descanso", "el partido llega al descanso")
	m.set_physics_process(true)
	await _ida_y_vuelta()
	await _marco(1)
	var t0 := Time.get_ticks_msec()
	while not (m.mitad == 2 and m.estado in ["juego", "saque"]) and Time.get_ticks_msec() - t0 < 60000:
		await _marco(1)
	_comprobar(m.mitad == 2 and m.estado in ["juego", "saque"], "tras salir y volver en el descanso, arranca la segunda parte (mitad %d, %s)" % [m.mitad, m.estado])

func _tanda() -> void:
	await _abrir(true)
	var m: MotorJugable = _pj.motor
	m.set_physics_process(false)
	m.mitad = 4
	m.prorroga = true
	m.goles = [1, 1]
	m._fin_de_mitad()
	_comprobar(m.estado == "tanda", "se llega a la tanda de penales (%s)" % m.estado)
	m.autopiloto = false
	m.set_physics_process(true)
	var idas := 0
	var tiro := 0.0
	var t0 := Time.get_ticks_msec()
	var f := 0
	while m.estado != "fin" and Time.get_ticks_msec() - t0 < 150000:
		f += 1
		if f % 120 == 60 and idas < 6:
			idas += 1
			await _ida_y_vuelta()
		if m.estado == "tanda" and m.tanda_me_toca_tirar() and String(m.tanda.get("fase", "")) == "apuntar":
			if tiro <= 0.0:
				Input.action_press("jugar_tiro")
			tiro += 1.0 / 60.0
			if tiro > 0.5:
				Input.action_release("jugar_tiro")
		elif tiro > 0.0:
			Input.action_release("jugar_tiro")
			tiro = 0.0
		await _marco(1)
	_comprobar(m.estado == "fin", "con %d idas y vueltas al segundo plano en la tanda, termina (%s)" % [idas, m.estado])
	_comprobar(not m.tanda.is_empty() and int(m.goles_tanda(0)) != int(m.goles_tanda(1)), "…y la tanda tiene ganador (%d-%d)" % [m.goles_tanda(0), m.goles_tanda(1)])

func _repeticion() -> void:
	await _abrir()
	var m: MotorJugable = _pj.motor
	var t0 := Time.get_ticks_msec()
	while m.estado != "juego" and Time.get_ticks_msec() - t0 < 20000:
		await _marco(1)
	m._gol(true)
	var vio := false
	for i in 600:
		await _marco(1)
		if _pj.realizando_gol():
			vio = true
			break
	_comprobar(vio, "el gol abre su realización/repetición")
	await _ida_y_vuelta()
	t0 = Time.get_ticks_msec()
	while _pj.realizando_gol() and Time.get_ticks_msec() - t0 < 60000:
		await _marco(1)
	t0 = Time.get_ticks_msec()
	while not (m.estado in ["juego", "saque"]) and Time.get_ticks_msec() - t0 < 60000:
		await _marco(1)
	_comprobar(not _pj.realizando_gol() and m.estado in ["juego", "saque"], "tras salir y volver en plena repetición, termina y el juego sigue (%s)" % m.estado)
