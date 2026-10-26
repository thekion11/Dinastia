extends Node
## LAS OCASIONES JUGABLES (26-10-2026, sesión 5) con la cámara real del partido del DT: la pausa con los tres
## botones y la cámara a pie de campo, el tiro elegido en marcha, el aviso del resultado y el interruptor en el
## panel previo al partido. Salida: pruebas/capturas/s5_ocasion_1..4 (JPG con captura.sh).
##   RESOLUCION=1280x720 herramientas/captura.sh res://pruebas/captura_s5_ocasion.tscn
##   (SOLO_PANEL=1 delante: solo el panel previo, sin el partido.)
var _vista: VistaEstadio
var _fase := 0
var _espera := 0
var _fotos := 0
var _m: Mundo

func _ready() -> void:
	Calidad.elegida = Calidad.MEDIO
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, "ceremonia", false)
	cfg.set_value(CajonAjustes.SECCION, "intro", false)
	cfg.set_value(CajonAjustes.SECCION, OcasionJugable.PREF, true)
	cfg.save(CajonAjustes.RUTA)
	_m = Mundo.new()
	_m.generar(["CHI"], 4711)
	_m.tomar_el_mando(_m.ligas[0].clubes[0].id)
	Partido.ctx_club_id = _m.mi_club_id
	if OS.get_environment("SOLO_PANEL") != "":
		_fotos = 3
		_fase = 5
		return
	var par := _m.proximo_partido()
	var partido := Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], partido)

func _foto(nombre: String) -> void:
	_fotos += 1
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/s5_ocasion_%d.png" % _fotos)
	print("FOTO s5_ocasion_%d %s" % [_fotos, nombre])

func _process(_d: float) -> void:
	var motor: MotorJugable = _vista.get("_motor") if is_instance_valid(_vista) else null
	if _espera > 0:
		_espera -= 1
		return
	match _fase:
		0:
			if motor == null or motor.estado != "juego":
				return
			_espera = 30
			_fase = 1
		1:
			var oc: OcasionJugable = _vista.get("_ocasion")
			if oc == null:
				print("FALLO: sin ocasiones en el estadio")
				get_tree().quit(1)
				return
			## Una llegada clara: el delantero local con el balón a 19 m, con espacio.
			var p := _jugador(motor, "DC")
			for q: Dictionary in motor.jugadores:
				if not bool(q["es_local"]) and not bool(q["por"]) and motor.pos(q).z > 25.0 and absf(motor.pos(q).x) < 8.0:
					(q["node"] as Node3D).position.x += 9.0 * (1.0 if motor.pos(q).x >= 0.0 else -1.0)
			(p["node"] as Node3D).position = Vector3(3.0, 0, 34.0)
			motor.balon.position = Vector3(3.0, 0.11, 34.6)
			motor.vel_balon = Vector3.ZERO
			motor.call("_tomar", p)
			oc._proxima = 0
			_espera = 20
			_fase = 2
		2:
			var oc2: OcasionJugable = _vista.get("_ocasion")
			if not oc2.congela():
				print("AVISO: la ocasión no se abrió todavía")
				_espera = 10
				return
			_foto("eligiendo")
			oc2.elegir("tiro")
			_espera = 12
			_fase = 3
		3:
			_foto("tiro")
			_fase = 4
		4:
			var oc3: OcasionJugable = _vista.get("_ocasion")
			if oc3.activa():
				return
			_espera = 4
			_fase = 5
		5:
			if is_instance_valid(_vista):
				_foto("resultado")
				_vista.queue_free()
			_vista = null
			var c := Control.new()
			c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			add_child(c)
			var par := _m.proximo_partido()
			var p2 := Partido.new(par[0], par[1])
			InformeRival.mostrar(c, p2, _m.mi_club(), _m.liga_de(p2.visita), _m)
			_espera = 20
			_fase = 6
		6:
			_foto("panel previo")
			get_tree().quit(0)

func _jugador(motor: MotorJugable, codigo: String) -> Dictionary:
	for p: Dictionary in motor.jugadores:
		if bool(p["es_local"]) and String(p.get("slot_code", "")) == codigo:
			return p
	for p: Dictionary in motor.jugadores:
		if bool(p["es_local"]) and not bool(p["por"]):
			return p
	return {}
