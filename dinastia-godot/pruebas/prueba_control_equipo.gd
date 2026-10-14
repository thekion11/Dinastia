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
				_probar_reconocedor()
				_paso = 5
				_t = 0
		5:
			_paso_fc()

## LAS FILIGRANAS DEL STICK DERECHO (FC 26): el reconocedor de gestos.
func _probar_reconocedor() -> void:
	var r := func(seq: Array, lb := false, lt := false, rb := false) -> String:
		return String(ControlFC.reconocer(seq, lb, lt, rb).get("id", ""))
	_ok(r.call(["F", "FR", "R"]) == "bicicleta", "FC: un cuarto de vuelta desde adelante = bicicleta")
	_ok(r.call(["R", "FR", "F", "FL", "L"]) == "elastica", "FC: media luna por delante = elástica")
	_ok(r.call(["B", "BL", "L", "FL", "F", "FR", "R"]) == "ruleta", "FC: tres cuartos desde atrás = ruleta")
	_ok(r.call(["F", "N", "R"]) == "giro_berba", "FC: toque adelante y a un lado = giro de Berba")
	_ok(r.call(["B", "N", "F"]) == "sombrero", "FC: atrás y adelante = sombrerito")
	_ok(r.call(["L"]) == "finta_cuerpo", "FC: toque a un lado = finta de cuerpo")
	_ok(r.call(["F", "N", "B"], true) == "tacon_rodado", "FC: LB + adelante y atrás = tacón con balón rodado")
	_ok(ControlFC.estrellas(0.92) == 5 and ControlFC.estrellas(0.3) == 2, "FC: estrellas de filigrana según el regate")
	var filas := 0
	for parte: Array in ControlFC.MANUAL:
		filas += (parte[2] as Array).size()
	_ok(ControlFC.FILIGRANAS.size() >= 24 and ControlFC.MANUAL.size() == 6 and filas >= 55, "FC: %d filigranas y %d combinaciones en las partes del manual" % [ControlFC.FILIGRANAS.size(), filas])
	_ok(r.call(["F"], false, false, false) == "" and String(ControlFC.reconocer(["F"], false, false, false, true).get("id", "")) == "adelantar", "FC: corriendo, toque adelante = adelantar el balón")
	_ok(String(ControlFC.reconocer(["F", "N", "R"], false, false, false, true).get("id", "")) == "mcgeady", "FC: corriendo, adelante y a un lado = McGeady")
	_ok(r.call(["B", "N", "F", "N", "F"]) == "sombrerito_flair", "FC: atrás, arriba, arriba = amago de sombrerito")
	_ok(ControlFC.texto_fichas(["jugar_mod", "jugar_tiro"], "ps") == "R1 + ◯" and ControlFC.texto_fichas(["jugar_mod", "jugar_tiro"], "xbox") == "RB + B", "FC: las combinaciones se escriben en PlayStation y en Xbox")

## Pone el balón en los pies del jugador que manejas, en (x, z).
func _balon_a_usuario(x: float, z: float) -> Dictionary:
	var u: Dictionary = _motor.usuario
	_motor.estado = "juego"
	(u["node"] as Node3D).position = Vector3(x, 0, z)
	_motor.set("_tiro_vivo", {})
	_motor.set("_offside", {})
	u["vel"] = Vector3.ZERO
	_motor.balon.position = Vector3(x, 0.11, z + 0.4)
	_motor.vel_balon = Vector3.ZERO
	_motor.poseedor = {}
	_motor.call("_tomar", u)
	return u

func _balon_a_rival() -> Dictionary:
	for q: Dictionary in _motor.jugadores:
		if not bool(q["es_local"]) and not bool(q["por"]):
			_motor.estado = "juego"
			(q["node"] as Node3D).position = Vector3(0, 0, -10)
			## Sin tiro ni fuera de juego pendientes del paso anterior.
			_motor.set("_tiro_vivo", {})
			_motor.set("_offside", {})
			_motor.balon.position = Vector3(0, 0.11, -9.6)
			_motor.poseedor = {}
			_motor.call("_tomar", q)
			## Que no la suelte ni se la roben mientras se prueba la defensa.
			_motor.set("_decision_en", _motor.t + 30.0)
			for o: Dictionary in _motor.jugadores:
				if bool(o["es_local"]):
					o["enfriar"] = 3.0
			return q
	return {}

## Las combinaciones del manual, una por fotograma (lo que se pulsa vale en el
## fotograma en que se pulsa).
func _paso_fc() -> void:
	match _t:
		1:
			## RB + B (tiro con rosca) mantenido unos fotogramas.
			_balon_a_usuario(8.0, 30.0)
			_dato["tiros"] = int(_motor.tiros[0])
			_pulsar("jugar_mod", true)
			_pulsar("jugar_tiro", true)
			_avanzar(1)
		2, 3, 4, 5, 6, 7, 8, 9, 10:
			_avanzar(1)
		11:
			_ok(_motor._mods_carga == "rosca", "FC: RB + Tiro = tiro con rosca")
			_pulsar("jugar_tiro", false)
			_pulsar("jugar_mod", false)
			_avanzar(1)
		12:
			_ok(int(_motor.tiros[0]) > int(_dato["tiros"]), "FC: el tiro con rosca sale")
			## LB + B: vaselina, que sube.
			_balon_a_usuario(0.0, 36.0)
			_pulsar("jugar_cambiar", true)
			_pulsar("jugar_tiro", true)
			_avanzar(1)
		13, 14, 15, 16, 17, 18:
			_avanzar(1)
		19:
			_pulsar("jugar_tiro", false)
			_avanzar(1)
			_pulsar("jugar_cambiar", false)
			_ok(_motor.vel_balon.y > 2.5, "FC: LB + Tiro = vaselina (sube a %.1f m/s)" % _motor.vel_balon.y)
		20:
			## LB + A: la pared.
			_avanzar(30)
			_balon_a_usuario(0.0, 0.0)
			_pulsar("jugar_cambiar", true)
			_pulsar("jugar_pase", true)
			_avanzar(1)
		21:
			_pulsar("jugar_pase", false)
			_pulsar("jugar_cambiar", false)
			_avanzar(1)
			_ok(not _motor._pared.is_empty(), "FC: LB + Pase = pared (el que la da pide la devolución)")
		22:
			## A mantenido sin balón: contener (entre el rival y el arco).
			_avanzar(30)
			var r := _balon_a_rival()
			_dato["rival"] = r
			_pulsar("jugar_pase", true)
			_avanzar(1)
		23:
			_avanzar(1)
			var u: Dictionary = _motor.usuario
			var r: Dictionary = _dato["rival"]
			var obj: Vector3 = u.get("objetivo", Vector3.ZERO)
			var arco: Vector3 = _motor.call("_arco_propio", u)
			_ok(obj.distance_to(_motor.pos(r)) < 2.0 and obj.distance_to(arco) < _motor.pos(r).distance_to(arco), "FC: Pase mantenido sin balón = contener (entre el rival y tu arco)")
			_pulsar("jugar_pase", false)
			## RB mantenido: presiona el segundo jugador.
			_pulsar("jugar_mod", true)
			_avanzar(1)
		24:
			var u: Dictionary = _motor.usuario
			var ayuda: Dictionary = _motor.call("_segundo_presionador", u)
			_ok(not ayuda.is_empty() and (ayuda.get("objetivo", Vector3.ZERO) as Vector3).distance_to(_motor.pos(_dato["rival"])) < 0.5, "FC: RB mantenido = el compañero más cercano presiona")
			_pulsar("jugar_mod", false)
			## Cruceta arriba: más ofensiva.
			_dato["ment"] = int((_motor.tacticas[0] as Dictionary).get("mentalidad", 1))
			_pulsar("jugar_tac_arriba", true)
			_avanzar(1)
		25:
			_pulsar("jugar_tac_arriba", false)
			_avanzar(1)
			_ok(int((_motor.tacticas[0] as Dictionary).get("mentalidad", 1)) == mini(int(_dato["ment"]) + 1, 3), "FC: cruceta arriba = mentalidad más ofensiva")
			## Una filigrana que el jugador domina y otra que le queda grande.
			var u := _balon_a_usuario(0.0, 0.0)
			u["attr"]["reg"] = 0.95
			_motor.call("_filigrana", u, "bicicleta", 1.0)
			_ok(_motor.poseedor == u and float(u["regate_hasta"]) > _motor.t, "FC: la bicicleta sale con 5★ (sigue con el balón)")
			_avanzar(60)
			u = _balon_a_usuario(0.0, 0.0)
			u["attr"]["reg"] = 0.3
			_motor.call("_filigrana", u, "elastica", 1.0)
			_ok(_motor.poseedor != u, "FC: la elástica (5★) le queda grande a un jugador de 2★: pierde el balón")
			## L3 + R3 a la vez: bloqueo de jugador.
			_avanzar(30)
			_balon_a_usuario(0.0, 0.0)
			_pulsar("jugar_pedir", true)
			_pulsar("jugar_sombrero", true)
			_avanzar(1)
		26:
			_pulsar("jugar_pedir", false)
			_pulsar("jugar_sombrero", false)
			_avanzar(1)
			_ok(_motor.bloqueo, "FC: L3 + R3 = bloqueo de jugador")
			_motor.bloqueo = false
			## LB + RB + B: tiro potente con cámara lenta.
			_balon_a_usuario(4.0, 28.0)
			_pulsar("jugar_cambiar", true)
			_pulsar("jugar_mod", true)
			_pulsar("jugar_tiro", true)
			_avanzar(1)
		27, 28, 29, 30, 31, 32:
			_avanzar(1)
		33:
			_pulsar("jugar_tiro", false)
			_avanzar(1)
			_pulsar("jugar_cambiar", false)
			_pulsar("jugar_mod", false)
			_ok(_motor.lento > 0.0, "FC: LB + RB + Tiro = tiro potente con cámara lenta")
			var sv: Array = []
			for k in 20:
				_motor.set("_t_estado", float(k) * 0.1)
				sv.append(_motor.serenidad())
			_ok(sv.min() < 0.05 and sv.max() > 0.95, "FC: el círculo de serenidad del penal late entre grande y chico")
		34:
			## Doble toque de Y sin balón: el portero al palo largo.
			_avanzar(30)
			_balon_a_rival()
			_pulsar("jugar_filtrado", true)
			_avanzar(1)
		35:
			_pulsar("jugar_filtrado", false)
			_avanzar(1)
		36:
			_pulsar("jugar_filtrado", true)
			_avanzar(1)
		37:
			_pulsar("jugar_filtrado", false)
			_avanzar(1)
			_ok(float(_motor.get("_palo_largo_hasta")) > _motor.t, "FC: doble toque de Y = portero al palo largo")
			_fin()

func _fin() -> void:
	for a in ["jugar_arriba", "jugar_pase", "jugar_cambiar", "jugar_tiro", "jugar_mod", "jugar_tac_arriba", "jugar_pedir", "jugar_sombrero", "jugar_filtrado"]:
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
	_ok(panel.filas_de_acciones() == Mando.MAPA.size(), "controles: una fila por acción (%d)" % panel.filas_de_acciones())
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
	## El mando 3D: los iconos de Kenney de cada pieza existen (PlayStation y Xbox).
	var faltan: Array = []
	for disp: String in ["ps", "xbox"]:
		for pieza: String in ["A", "B", "X", "Y", "LB", "RB", "LT", "RT", "LS", "RS", "DPAD", "START", "BACK"]:
			var nombre := MandoGiratorio.nombre_icono(pieza, disp)
			var ruta := "res://assets/iconos_botones/%s/%s.png" % ["playstation" if disp == "ps" else "xbox", nombre]
			if nombre == "" or not ResourceLoader.exists(ruta):
				faltan.append(ruta)
	_ok(faltan.is_empty(), "mando 3D: están los iconos de cada botón %s" % str(faltan))
	_ok(panel._mando != null and panel._mando._giratorio != null, "mando 3D: el widget giratorio existe")
	panel.cerrar()
	Mando.propio = antes_propio
	Mando.esquema = antes_esq
	Mando.ayudas = antes_ay
	Mando.guardar()
	Mando.aplicar()
