extends Node
## CAZA DE FALLOS (4-11-2026, orden de la líder): el partido 3D jugable llevado al límite, con el mando táctil simulado.
## Un partido ENTERO (2 × 12 s de reloj de juego) mientras cada fotograma llegan toques al azar (uno y dos dedos, arrastres, soltar sin pulsar),
## acciones sueltas, pausas y reanudaciones, cambios de calidad a mitad y expulsiones del equipo del jugador hasta quedarse con 7.
## Después: un gol en cada calidad (la realización y la repetición terminan solas). Comprueba cada 10 fotogramas que nadie se vuelve NaN/infinito
## ni sale del mundo, y al final que el partido llegó a «fin» y que la pausa no dejó el motor parado.
##   godot --headless --path . res://pruebas/auditoria_partido3d_limite.tscn
## Termina en «===== FIN. n fallos =====»; los errores de script salen como SCRIPT ERROR en el registro.
const LIENZO := Vector2(1600, 720)
## Tope duro de fotogramas y tope SIN PROGRESO (el reloj del partido, el estado y el marcador sin moverse): el ritmo del ordenador cambia cuántos fotogramas hacen falta (CI: más goles con su celebración y repetición de ~1.500 fotogramas cada una).
const TOPE_FOTOGRAMAS := 60 * 600
const TOPE_SIN_PROGRESO := 60 * 120
var _n := 0
var _fase := 0
var _fallos := 0
var _ui: CarreraJugadorUI
var _pj: PartidoJugable
var _ct: ControlesTactiles
var _rng := RandomNumberGenerator.new()
var _expulsados_mios := 0
var _pausas := 0
var _calidades := 0
var _nivel_gol := 0
var _espera_gol := 0
var _marcador_antes := 0
var _susp := 0
var _banq := 0
var _entro := false
var _banq_entro := 0
var _firma_progreso := ""
var _f_progreso := 0
var _pj_viejo: PartidoJugable

func _comprobar(ok: bool, texto: String) -> void:
	print(("  ok     " if ok else "  FALLO  ") + texto)
	if not ok:
		_fallos += 1

func _ready() -> void:
	_rng.seed = 4711
	Input.emulate_mouse_from_touch = false   ## los toques al azar no deben pulsar los botones del menú de pausa (¡Controles! ¡Simular!)
	PartidoJugable.con_ceremonia = false
	ControlesTactiles.forzar = true
	PantallaMovil.dpi_forzado = 400.0
	PantallaMovil.ventana_forzada = Vector2i(2400, 1080)
	PantallaMovil.lienzo_forzado = LIENZO
	AjustesTactil.restaurar()
	CarreraJugadorUI.mundo = null
	_ui = load("res://escenas/carrera_jugador.tscn").instantiate()
	add_child(_ui)

func _accion(nombre: String, pulsa: bool) -> void:
	var e := InputEventAction.new()
	e.action = nombre
	e.pressed = pulsa
	Input.parse_input_event(e)

func _toque_al_azar() -> void:
	var dedo := _rng.randi_range(0, 2)
	var pos := Vector2(_rng.randf() * LIENZO.x, _rng.randf() * LIENZO.y)
	match _rng.randi_range(0, 3):
		0:
			var t := InputEventScreenTouch.new()
			t.index = dedo; t.position = pos; t.pressed = true
			Input.parse_input_event(t)
		1:
			var t2 := InputEventScreenTouch.new()
			t2.index = dedo; t2.position = pos; t2.pressed = false   ## soltar sin haber pulsado
			Input.parse_input_event(t2)
		2:
			var d := InputEventScreenDrag.new()
			d.index = dedo; d.position = pos; d.relative = Vector2(_rng.randf_range(-40, 40), _rng.randf_range(-40, 40))
			Input.parse_input_event(d)
		_:
			for acc in ["jugar_pase", "jugar_tiro", "jugar_pase_largo", "jugar_regate", "jugar_mod", "jugar_cambiar"]:
				if _rng.randf() < 0.15:
					_accion(acc, _rng.randf() < 0.5)

func _sano() -> String:
	var m = _pj.motor
	for p: Dictionary in m.jugadores:
		var pos: Vector3 = (p["node"] as Node3D).position
		if not (is_finite(pos.x) and is_finite(pos.y) and is_finite(pos.z)):
			return "jugador %s no finito" % p["id"]
		if absf(pos.x) > 200.0 or absf(pos.z) > 200.0:
			return "jugador %s fuera del mundo (%s)" % [p["id"], str(pos)]
	var b: Vector3 = m.balon.position
	if not (is_finite(b.x) and is_finite(b.y) and is_finite(b.z)) or absf(b.x) > 300.0 or absf(b.z) > 300.0 or b.y < -5.0:
		return "balón fuera del mundo (%s)" % str(b)
	return ""

func _soltar_todo() -> void:
	for acc in ["jugar_pase", "jugar_tiro", "jugar_pase_largo", "jugar_regate", "jugar_mod", "jugar_cambiar", "jugar_pausa"]:
		Input.action_release(acc)
	for dedo in 3:
		var t := InputEventScreenTouch.new()
		t.index = dedo; t.position = Vector2(10, 10); t.pressed = false
		Input.parse_input_event(t)

func _fin() -> void:
	_soltar_todo()
	ControlesTactiles.forzar = false
	PantallaMovil.dpi_forzado = 0.0
	PantallaMovil.ventana_forzada = Vector2i.ZERO
	PantallaMovil.lienzo_forzado = Vector2.ZERO
	AjustesTactil.restaurar()
	Calidad.elegida = Calidad.MINIMO
	Input.emulate_mouse_from_touch = true
	print("===== FIN. %d fallos =====" % _fallos)
	get_tree().quit(0 if _fallos == 0 else 1)

func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		_ui._crear()
	if _n == 20:
		var club := _ui.carrera.club(CarreraJugadorUI.mundo)
		var par := _ui._partido_de_la_semana(club)
		_pj = PartidoJugable.abrir(_ui, CarreraJugadorUI.mundo, _ui.carrera, par[0], par[1], 12.0)
		_ct = _pj.get_node_or_null("ControlesTactiles") as ControlesTactiles
		_pj.size = LIENZO
		_ct.size = LIENZO
		_pj.motor.autopiloto = false
		if OS.get_environment("SOLO_SUSP") != "":
			_fase = 2   ## (depuración) solo la suspensión por menos de 7
		if OS.get_environment("SOLO_BANQ") != "":
			_fase = 3   ## (depuración) solo el banquillo
		return
	if _n < 30 or (_pj == null and _fase < 2):
		return
	match _fase:
		0: _golazos()
		1: _fuzz()
		2: _suspension()
		3: _banquillo()
		4: _fin()

func _fuzz() -> void:
	var m = _pj.motor
	var f := _n - 30
	for i in _rng.randi_range(0, 3):
		_toque_al_azar()
	## Pausa y reanudación: la pausa se abre y se cierra sola.
	if f % 240 == 100:
		_accion("jugar_pausa", true)
		_accion("jugar_pausa", false)
		_pausas += 1
	if f % 240 == 130 and _pj._pausa != null:
		_accion("jugar_pausa", true)
		_accion("jugar_pausa", false)
	## Calidad a mitad de partido.
	if f % 300 == 150:
		Calidad.elegida = [Calidad.MINIMO, Calidad.MEDIO, Calidad.ALTO][_calidades % 3]
		Calidad.aplicar_viewport(_pj._vp, Calidad.elegida)
		_calidades += 1
	## Expulsiones de los míos hasta quedarse con 7 (nunca el portero); una sustitución forzada de vez en cuando.
	if f % 500 == 400 and m.estado == "juego":
		var mios: Array = m.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["es_local"]) == _pj._es_local_usuario)
		if mios.size() > 7:
			var cand: Array = mios.filter(func(p: Dictionary) -> bool: return not p["por"] and p != m.usuario)
			if not cand.is_empty():
				m._expulsar(cand[0])
				_expulsados_mios += 1
	if f % 700 == 350 and m.estado == "juego":
		m._revisar_cambio(true)
	if f % 600 == 0:
		print("    f=%d estado=%s mitad=%d min=%d marcador=%s mios_en_campo=%d" % [f, m.estado, m.mitad, m.minuto(), str(m.goles), m.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["es_local"]) == _pj._es_local_usuario).size()])
	if f % 10 == 0:
		var e := _sano()
		if e != "":
			_comprobar(false, "fotograma %d: %s" % [f, e])
			_fase = 4
			return
	var firma := "%s|%d|%.1f|%s|%d" % [m.estado, m.mitad, m.t, str(m.goles), 1 if _pj.realizando_gol() else 0]
	if firma != _firma_progreso:
		_firma_progreso = firma
		_f_progreso = f
	if m.estado == "fin" or f > TOPE_FOTOGRAMAS or (f - _f_progreso > TOPE_SIN_PROGRESO and _pj._pausa == null):
		_soltar_todo()
		print("    DIAG estado=%s pausa=%s fisica=%s apuntando=%s cargando=%s usuario_vacio=%s t=%.1f saque=%s" % [m.estado, str(_pj._pausa), str(m.is_physics_processing()), str(m.apuntando), str(m.cargando), str(m.usuario.is_empty()), m.t, str(m.get("_t_estado"))])
		_comprobar(m.estado == "fin", "el partido entero con toques al azar llega a «fin» (estado %s, %d fotogramas)" % [m.estado, f])
		_comprobar(_pausas >= 2 and _calidades >= 2, "hubo %d pausas y %d cambios de calidad a mitad de partido" % [_pausas, _calidades])
		_comprobar(_expulsados_mios >= 1, "%d expulsiones del equipo del jugador (quedan %d en el campo)" % [_expulsados_mios, m.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["es_local"]) == _pj._es_local_usuario).size()])
		_comprobar(_pj._pausa == null, "al final no queda una pausa abierta")
		var r := _pj.resultado()
		_comprobar(int(r["goles_local"]) >= 0 and int(r["goles_visita"]) >= 0, "el resultado es coherente (%d-%d)" % [r["goles_local"], r["goles_visita"]])
		_comprobar(not m.suspendido, "con 7 jugadores el partido NO se suspende")
		_fase = 2
		_susp = 0

## Un gol en cada calidad (MÍNIMO, MEDIO, ALTO): la realización y la repetición terminan solas y el partido sigue.
func _golazos() -> void:
	var m = _pj.motor
	var niveles := [Calidad.MINIMO, Calidad.MEDIO, Calidad.ALTO]
	if _nivel_gol >= niveles.size():
		_fase = 1
		_n = 30   ## el fuzz cuenta sus fotogramas desde aquí
		return
	if _espera_gol == 0:
		if m.estado != "juego":
			return
		Calidad.elegida = niveles[_nivel_gol]
		Calidad.aplicar_viewport(_pj._vp, Calidad.elegida)
		_marcador_antes = int(m.goles[0]) + int(m.goles[1])
		m._gol(true)
		_espera_gol = 1
		return
	_espera_gol += 1
	var termino: bool = not _pj.realizando_gol() and m.estado in ["juego", "saque"] and _espera_gol > 30
	if termino or _espera_gol > 60 * 90:
		_comprobar(termino, "gol con calidad %d: la realización y la repetición terminan solas (%d fotogramas, estado %s)" % [niveles[_nivel_gol], _espera_gol, m.estado])
		_comprobar(int(m.goles[0]) + int(m.goles[1]) == _marcador_antes + 1, "gol con calidad %d: el marcador sube uno (%d)" % [niveles[_nivel_gol], int(m.goles[0]) + int(m.goles[1])])
		_nivel_gol += 1
		_espera_gol = 0

## Menos de siete: partido NUEVO; se expulsa a los suyos de uno en uno y, al quedar 6, se suspende y se pierde 3-0 (o con el marcador si ya perdía por 3+).
func _suspension() -> void:
	_susp += 1
	if _susp == 1:
		_pj.queue_free()
		return
	if _susp == 5:
		var club := _ui.carrera.club(CarreraJugadorUI.mundo)
		var par := _ui._partido_de_la_semana(club)
		_pj = PartidoJugable.abrir(_ui, CarreraJugadorUI.mundo, _ui.carrera, par[0], par[1], 12.0)
		_pj.motor.autopiloto = true
		return
	if _susp < 60 or _pj == null:
		return
	var m = _pj.motor
	if _susp % 120 == 0: print("    susp=%d estado=%s" % [_susp, m.estado])
	var mios: Array = m.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["es_local"]) == _pj._es_local_usuario)
	if m.estado != "fin" and m.estado != "juego" and m.estado != "saque":
		return
	if m.estado == "fin" and mios.size() > 6:
		_comprobar(false, "el partido terminó con %d míos en el campo sin llegar a la suspensión" % mios.size())
		_fase = 3
		_banq = 0
		return
	if mios.size() > 6:
		var cand: Array = mios.filter(func(p: Dictionary) -> bool: return not p["por"] and p != m.usuario)
		if _susp % 20 == 0 and not cand.is_empty():
			m._expulsar(cand[0])
		return
	_comprobar(m.estado == "fin" and m.suspendido, "con menos de 7 el partido se suspende (estado %s)" % m.estado)
	var mi_lado := 0 if _pj._es_local_usuario else 1
	_comprobar(int(m.goles[mi_lado]) < int(m.goles[1 - mi_lado]) and int(m.goles[1 - mi_lado]) >= 3, "se da por perdido: marcador %d-%d" % [m.goles[0], m.goles[1]])
	_fase = 3
	_banq = 0

## Sustituciones REALES del usuario: parte del BANQUILLO (entra en el minuto 15). Antes de entrar se expulsa a dos de los suyos; al entrar se comprueba que
## el usuario tiene jugador; después se expulsa a ESE jugador (el usuario se queda sin futbolista) y se sigue con toques al azar sin errores ni NaN.
func _banquillo() -> void:
	_banq += 1
	if _banq == 1:
		_pj.queue_free()
		return
	if _banq == 5:
		var club := _ui.carrera.club(CarreraJugadorUI.mundo)
		var par := _ui._partido_de_la_semana(club)
		var yo := _ui.carrera.jugador(CarreraJugadorUI.mundo)
		yo.suspension = 1   ## sancionado para el once (no es titular): empieza en el banquillo y entra en su minuto
		_pj = PartidoJugable.abrir(_ui, CarreraJugadorUI.mundo, _ui.carrera, par[0], par[1], 12.0, 15)
		_ct = _pj.get_node_or_null("ControlesTactiles") as ControlesTactiles
		_pj.size = LIENZO
		_ct.size = LIENZO
		## (El partido corre solo y deprisa DENTRO de `abrir` hasta que el usuario entra.)
		_comprobar(not _pj.motor.usuario.is_empty() and _pj.motor.minuto() >= 15 and not _pj.motor.usuario_sustituido, "parte del banquillo: al abrir ya ha entrado, en el minuto %d" % _pj.motor.minuto())
		return
	if _banq < 60:
		return
	var m = _pj.motor
	for i in _rng.randi_range(0, 3):
		_toque_al_azar()
	var mios: Array = m.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["es_local"]) == _pj._es_local_usuario)
	if not _entro and not m.usuario.is_empty():
		_entro = true
		_comprobar(true, "el usuario entra desde el banquillo (minuto %d, %d de los suyos en el campo)" % [m.minuto(), mios.size()])
		_banq_entro = _banq
	if _entro and _banq - _banq_entro == 120:
		m._expulsar(m.usuario)
		_comprobar(m.usuario.is_empty(), "al expulsar al futbolista del usuario, el usuario se queda sin jugador y el partido sigue (%s)" % m.estado)
	if _banq % 10 == 0:
		var e := _sano()
		if e != "":
			_comprobar(false, "banquillo: %s" % e)
			_fase = 4
			return
	if (_entro and _banq - _banq_entro > 900) or m.estado == "fin" or _banq > 60 * 200:
		_comprobar(_entro, "el usuario llegó a entrar desde el banquillo")
		_fase = 4
