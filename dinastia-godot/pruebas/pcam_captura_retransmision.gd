extends Node
## LA RETRANSMISIÓN EN FOTOS (25-10-2026, pulido de la tele), con el partido del DT y el motor real:
##   1. jugada pegada a la banda de la cámara (antes el balón quedaba por debajo del cuadro);
##   2-4. un remate de verdad que entra y su repetición: un fotograma de cada plano (tele, remate,
##        detrás del arco / línea de gol);
##   5. el inserto de la tarjeta (árbitro y amonestado de cerca);
##   6. el inserto del cartel del añadido.
## Salida: pruebas/capturas/pcam_tv_1..6 (JPG con captura.sh).
##   RESOLUCION=1280x720 herramientas/captura.sh res://pruebas/pcam_captura_retransmision.tscn
## Con SOLO_INSERTOS=1 delante, solo las dos últimas (pcam_tv_5 y 6). Las esperas de los
## insertos van por reloj real (sin GPU los fotogramas son lentos y el cartel dura 7,5 s).
var _n := 0
var _vista: VistaEstadio
var _fase := 0
var _espera := 0
var _fotos := 0
var _plano := ""
var _plano_desde := 0.0
var _cuarto: Node3D
var _hasta_ms := 0

func _ready() -> void:
	Calidad.elegida = Calidad.MEDIO
	_prefs(false)
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	Partido.ctx_club_id = m.mi_club_id
	var par := m.proximo_partido()
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]))

func _prefs(v: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, "ceremonia", v)
	cfg.set_value(CajonAjustes.SECCION, "intro", v)
	cfg.save(CajonAjustes.RUTA)

func _jugador(motor: MotorJugable, local: bool, codigo: String) -> Dictionary:
	for p: Dictionary in motor.jugadores:
		if bool(p["es_local"]) == local and String(p.get("slot_code", "")) == codigo:
			return p
	for p: Dictionary in motor.jugadores:
		if bool(p["es_local"]) == local and not bool(p["por"]):
			return p
	return {}

func _foto(que: String) -> void:
	_fotos += 1
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/pcam_tv_%d.png" % _fotos)
	var cam := get_viewport().get_camera_3d()
	print("FOTO pcam_tv_%d %s · cámara %s · fov %.1f · pos %s" % [_fotos, que, cam.name if cam else "-", cam.fov if cam else 0.0,
		str(cam.global_position.snapped(Vector3.ONE * 0.1)) if cam else ""])

func _process(_d: float) -> void:
	_n += 1
	if _n > 4000:
		print("TIEMPO AGOTADO fase %d fotos %d" % [_fase, _fotos])
		_salir()
		return
	var motor: MotorJugable = _vista.get("_motor")
	if motor == null:
		return
	var rig: CameraRig = _vista.get("_rig")
	var repe: Repeticion = _vista.get("_repe")
	if _espera > 0:
		_espera -= 1
		return
	match _fase:
		0:
			_espera = 40
			_fase = 4 if OS.get_environment("SOLO_INSERTOS") == "1" else 1
			if _fase == 4:
				_fotos = 4
		1:
			## La jugada por la banda de la cámara (+X), a 3 m de la línea.
			var p := _jugador(motor, true, "MD")
			(p["node"] as Node3D).position = Vector3(31.0, 0, 8.0)
			motor.balon.position = Vector3(31.4, 0.11, 8.6)
			motor.vel_balon = Vector3.ZERO
			motor.estado = "juego"
			motor.call("_tomar", p)
			_espera = 70
			_fase = 2
		2:
			_foto("banda (%s)" % rig.trans_plano)
			## Un remate de verdad: el 9 desde la frontal, el portero rival lejos.
			var dc := _jugador(motor, true, "DC")
			(dc["node"] as Node3D).position = Vector3(3.0, 0, 37.5)
			for q: Dictionary in motor.jugadores:
				if not bool(q["es_local"]) and bool(q["por"]):
					(q["node"] as Node3D).position = Vector3(14.0, 0, 50.0)
			motor.estado = "juego"
			motor.saque = {}
			motor.poseedor = {}
			motor.ultimo_toque = dc
			motor.balon.position = Vector3(2.6, 0.3, 38.4)
			motor.vel_balon = Vector3(-0.4, 2.2, 25.0)
			_fase = 3
		3:
			if repe != null and repe.reproduciendo and repe.plano_actual != "":
				if repe.plano_actual != _plano:
					_plano = repe.plano_actual
					_plano_desde = repe._rep_t
				var p_act: Dictionary = {}
				for q: Dictionary in repe.planos:
					if String(q["n"]) == _plano:
						p_act = q
				var tramo := float(p_act.get("hasta", 1.0)) - float(p_act.get("desde", 0.0))
				if repe._rep_t - float(p_act.get("desde", 0.0)) >= tramo * 0.45 and not has_meta(_plano):
					set_meta(_plano, true)
					_foto("repetición · plano %s · t %.2f / clave %.2f" % [_plano, repe._rep_t, repe.t_clave])
			elif repe != null and not repe.reproduciendo and _plano != "":
				_espera = 30
				_fase = 4
		4:
			var arb: Node3D = null
			for a: Dictionary in motor.arbitros:
				if String(a.get("id", "")) == "arbitro":
					arb = a["node"]
			var inf := _jugador(motor, false, "MC")
			(inf["node"] as Node3D).position = arb.position + Vector3(0.9, 0, 1.4)
			## Con el juego parado (como tras la falta): si no, el inserto se corta solo.
			motor.call("_empezar_saque", "falta", true, Vector3(arb.position.x + 2.0, 0.11, arb.position.z))
			print("inserto tarjeta: %s" % str(rig.inserto_tarjeta(arb, inf["node"], 6.0)))
			_hasta_ms = Time.get_ticks_msec() + 800
			_fase = 5
		5:
			if Time.get_ticks_msec() < _hasta_ms:
				return
			_foto("inserto %s" % rig.inserto)
			rig.quitar_inserto()
			_cuarto = CuartoArbitro.levantar(_vista.get("_raiz3d"), _vista.get("_spawner"), 3, _vista.get("_kit_arbitro"))
			_hasta_ms = Time.get_ticks_msec() + 700
			_fase = 6
		6:
			if Time.get_ticks_msec() < _hasta_ms:
				return
			print("inserto cartel: %s" % str(rig.inserto_cartel(_cuarto, 6.0)))
			_hasta_ms = Time.get_ticks_msec() + 900
			_fase = 7
		7:
			if Time.get_ticks_msec() < _hasta_ms:
				return
			_foto("inserto %s" % rig.inserto)
			_salir()

func _salir() -> void:
	_prefs(true)
	get_tree().quit()
