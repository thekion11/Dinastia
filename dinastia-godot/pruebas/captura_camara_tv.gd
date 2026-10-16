extends Node
## LA TRANSMISIÓN INTELIGENTE Y LAS ESTADÍSTICAS (16-10-2026), con la cámara
## real del partido del DT: plano normal, jugada en el área (cierra), córner
## (ocasión), balón largo hacia delante (abre), el panel de estadísticas y el
## rótulo de la tele. Salida: pruebas/capturas/camara_tv_1..6 (JPG con captura.sh).
##   RESOLUCION=1280x720 herramientas/captura.sh res://pruebas/captura_camara_tv.tscn
var _n := 0
var _vista: VistaEstadio
var _fase := 0
var _espera := 0
var _fotos := 0

func _ready() -> void:
	Calidad.elegida = Calidad.MEDIO
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
	_vista.abrir(par[0], 0.85, par[1], partido)

func _jugador(local: bool, codigo: String) -> Dictionary:
	var motor: MotorJugable = _vista.get("_motor")
	for p: Dictionary in motor.jugadores:
		if bool(p["es_local"]) == local and String(p.get("slot_code", "")) == codigo:
			return p
	for p: Dictionary in motor.jugadores:
		if bool(p["es_local"]) == local and not bool(p["por"]):
			return p
	return {}

func _foto(nombre: String) -> void:
	_fotos += 1
	var rig: CameraRig = _vista.get("_rig")
	var cam: Camera3D = rig.cameras[rig.current_index]
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/camara_tv_%d.png" % _fotos)
	print("FOTO camara_tv_%d %s · cámara %s · plano %s · fov %.1f · pos %s · cerca %.2f abre %.2f" % [_fotos, nombre,
		rig.current_name(), rig.trans_plano, cam.fov, str(cam.global_position.snapped(Vector3.ONE * 0.1)), rig.trans_cerca, rig.trans_abre])

func _process(_d: float) -> void:
	_n += 1
	var motor: MotorJugable = _vista.get("_motor")
	if motor == null:
		return
	if _espera > 0:
		_espera -= 1
		return
	match _fase:
		0:
			_espera = 40
			_fase = 1
		1:
			_foto("normal")
			## La jugada entra en el área: el delantero con el balón a 17 m.
			var p := _jugador(true, "DC")
			(p["node"] as Node3D).position = Vector3(6.0, 0, 35.0)
			motor.balon.position = Vector3(6.0, 0.11, 35.6)
			motor.vel_balon = Vector3.ZERO
			motor.call("_tomar", p)
			_espera = 6
			_fase = 2
		2:
			_foto("area")
			motor.call("_empezar_saque", "corner", true, Vector3(33.8, 0.11, 52.3))
			_espera = 14
			_fase = 3
		3:
			_foto("corner")
			## Un balón largo hacia delante desde campo propio: la contra.
			var q := _jugador(true, "MC")
			motor.estado = "juego"
			motor.saque = {}
			motor.poseedor = {}
			motor.ultimo_toque = q
			motor.balon.position = Vector3(-4.0, 0.11, -46.0)
			motor.vel_balon = Vector3(1.0, 0.0, 16.0)
			_espera = 7
			_fase = 4
		4:
			_foto("contra")
			_vista.abrir_estadisticas()
			_espera = 12
			_fase = 5
		5:
			_foto("panel")
			var ps: Variant = _vista.get("_panel_stats")
			if ps != null:
				(ps as PanelEstadisticas).cerrar()
			RotuloEstadisticas.mostrar(_vista, "descanso", _vista.partido, motor, _vista.get("_stats"))
			_espera = 10
			_fase = 6
		6:
			_foto("rotulo")
			var cfg := ConfigFile.new()
			cfg.load(CajonAjustes.RUTA)
			cfg.set_value(CajonAjustes.SECCION, "ceremonia", true)
			cfg.set_value(CajonAjustes.SECCION, "intro", true)
			cfg.save(CajonAjustes.RUTA)
			get_tree().quit()
	if _n > 1500:
		print("TIEMPO AGOTADO fase %d" % _fase)
		get_tree().quit()
