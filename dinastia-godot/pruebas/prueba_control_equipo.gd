extends Node
## CONTROLAR A MI EQUIPO EN EL PARTIDO DEL DT (14-10-2026): se pulsan los
## botones por código y se comprueba que pasa lo que tiene que pasar.
##   godot --headless --path . res://pruebas/prueba_control_equipo.tscn
var _fallos := 0
func _ok(c: bool, txt: String) -> void:
	print(("  ok    " if c else "  FALLO ") + txt)
	if not c:
		_fallos += 1

var _vista: VistaEstadio
var _motor: MotorJugable
var _paso := 0
var _t := 0
var _dato := {}

func _ready() -> void:
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, "ceremonia", false)
	cfg.set_value(CajonAjustes.SECCION, "intro", false)
	cfg.save(CajonAjustes.RUTA)
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	Partido.ctx_club_id = m.mi_club_id
	var par := m.proximo_partido()
	var partido := Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.8, par[1], partido)
	_motor = _vista.get("_motor")

func _pulsar(accion: String, si: bool) -> void:
	if si:
		Input.action_press(accion)
	else:
		Input.action_release(accion)

func _avanzar(n: int) -> void:
	for i in n:
		_motor.paso(1.0 / 60.0)

func _process(_d: float) -> void:
	_t += 1
	if _motor == null:
		_ok(false, "hay motor real")
		_fin()
		return
	match _paso:
		0:
			_vista.call("_alternar_control_motor")
			_avanzar(30)
			_ok(_motor.control_equipo == 0 and not _motor.autopiloto, "el control del equipo se enciende")
			_ok(not _motor.usuario.is_empty() and bool(_motor.usuario["es_local"]), "manejas a uno de los tuyos")
			## Dale el balón a tu jugador para probar.
			var u: Dictionary = _motor.usuario
			_motor.estado = "juego"
			_motor.poseedor = {}
			_motor.balon.position = _motor.pos(u) + Vector3(0, 0.11, 0.3)
			_motor.vel_balon = Vector3.ZERO
			_motor.call("_tomar", u)
			_dato["pos0"] = _motor.pos(u)
			_dato["u"] = u
			_pulsar("jugar_arriba", true)
			_paso = 1
		1:
			_avanzar(2)
			if _t > 40:
				_pulsar("jugar_arriba", false)
				var u: Dictionary = _dato["u"]
				var movido: float = (_motor.pos(u) as Vector3).distance_to(_dato["pos0"])
				_ok(movido > 2.0, "el stick mueve a tu jugador (%.1f m)" % movido)
				_ok(_motor.poseedor == u, "sigue con el balón al conducir")
				_dato["pases"] = int(_motor.pases[0])
				_pulsar("jugar_pase", true)
				_avanzar(1)
				_paso = 2
				_t = 0
		2:
			_avanzar(1)
			_pulsar("jugar_pase", false)
			if _t > 3:
				_ok(int(_motor.pases[0]) > int(_dato["pases"]) or _motor.poseedor != _dato["u"], "el botón de pase pasa el balón")
				_avanzar(90)
				## Cambiar de jugador con Q (como en FC, cuando defiendes: el
				## balón lo tiene un rival).
				_dato["antes"] = _motor.usuario
				for q: Dictionary in _motor.jugadores:
					if not bool(q["es_local"]) and not bool(q["por"]):
						_motor.balon.position = _motor.pos(q) + Vector3(0, 0.11, 0.3)
						_motor.poseedor = {}
						_motor.call("_tomar", q)
						break
				_pulsar("jugar_cambiar", true)
				_avanzar(1)
				_paso = 3
				_t = 0
		3:
			_avanzar(1)
			_pulsar("jugar_cambiar", false)
			if _t > 2:
				_ok(_motor.usuario != _dato["antes"], "Q cambia de jugador")
				## Tiro cargado desde la frontal.
				var u2: Dictionary = _motor.usuario
				(u2["node"] as Node3D).position = Vector3(0, 0, 30.0)
				_motor.balon.position = Vector3(0, 0.11, 30.4)
				_motor.vel_balon = Vector3.ZERO
				_motor.poseedor = {}
				_motor.call("_tomar", u2)
				_dato["tiros"] = int(_motor.tiros[0])
				_pulsar("jugar_tiro", true)
				_avanzar(1)
				_paso = 4
				_t = 0
		4:
			_avanzar(1)
			if _t == 20:
				_ok(_motor.cargando and _motor.carga > 0.2, "mantener tiro carga la potencia (%.2f)" % _motor.carga)
				_pulsar("jugar_tiro", false)
			if _t == 24:
				_ok(int(_motor.tiros[0]) > int(_dato["tiros"]), "al soltar, tira")
				_fin()

func _fin() -> void:
	for a in ["jugar_arriba", "jugar_pase", "jugar_cambiar", "jugar_tiro"]:
		Input.action_release(a)
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, "ceremonia", true)
	cfg.set_value(CajonAjustes.SECCION, "intro", true)
	cfg.set_value(CajonAjustes.SECCION, "control_equipo", false)
	cfg.save(CajonAjustes.RUTA)
	_probar_panel_controles()
	print("===== FIN CONTROL. %d fallos =====" % _fallos)
	get_tree().quit(0 if _fallos == 0 else 1)
	set_process(false)

## LA PANTALLA DE CONTROLES: reasignar el pase a la tecla G, que el InputMap lo
## lea, cambiar ayudas y esquema, y restaurar. Lo que tenía el jugador se
## devuelve al final.
func _probar_panel_controles() -> void:
	Mando.cargar()
	var antes_propio: Dictionary = Mando.propio.duplicate(true)
	var antes_esq := Mando.esquema
	var antes_ay: Dictionary = Mando.ayudas.duplicate()
	var panel := PanelControles.abrir(self)
	_ok(panel._lista.get_child_count() == Mando.MAPA.size(), "controles: una fila por acción")
	panel._escuchando = "jugar_pase"
	var ev := InputEventKey.new()
	ev.keycode = KEY_G
	ev.physical_keycode = KEY_G
	ev.pressed = true
	panel._input(ev)
	_ok(Mando.teclas_de("jugar_pase").has(KEY_G), "controles: el pase pasa a la G")
	var en_mapa := false
	for e in InputMap.action_get_events("jugar_pase"):
		if e is InputEventKey and ((e as InputEventKey).keycode == KEY_G or (e as InputEventKey).physical_keycode == KEY_G):
			en_mapa = true
	_ok(en_mapa, "controles: el InputMap ya usa la G")
	_ok(Mando.corto_de("jugar_pase").begins_with("G"), "controles: la guía en pantalla dice G (%s)" % Mando.corto_de("jugar_pase"))
	Mando.fijar_ayuda("pase", "manual")
	_ok(Mando.ayuda("pase") == "manual", "controles: pase manual")
	Mando.fijar_esquema("clasico")
	_ok(Mando.esquema == "clasico" and Mando.teclas_de("jugar_tiro").has(KEY_D), "controles: esquema clásico (D tira)")
	Mando.restaurar()
	_ok(Mando.esquema == "wasd" and Mando.teclas_de("jugar_tiro").has(KEY_K) and Mando.ayuda("pase") == "asistido",
		"controles: restaurar de fábrica")
	panel.cerrar()
	Mando.propio = antes_propio
	Mando.esquema = antes_esq
	Mando.ayudas = antes_ay
	Mando.guardar()
	Mando.aplicar()
