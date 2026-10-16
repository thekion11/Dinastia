extends Node
## LA CEREMONIA Y EL GOL EN LA CARRERA DE JUGADOR (16-10-2026). Comprueba que el
## partido jugable reutiliza la ceremonia del modo entrenador (antes del saque,
## con «Saltar»), y que un gol del jugador lanza la realización (`CineGol`: carta
## del goleador, banquillo, grada) y la repetición, con el motor en espera, y
## que luego el partido sigue y termina como siempre.
##   godot --headless --path . res://pruebas/prueba_carrera_ceremonia.tscn
## Con pantalla guarda además las fotos (pruebas/capturas/carrera_ceremonia_*,
## carrera_gol_*):
##   herramientas/captura.sh res://pruebas/prueba_carrera_ceremonia.tscn
var _fallos := 0
var _ui: CarreraJugadorUI
var _pj: PartidoJugable
var _paso := 0
var _t := 0.0
var _fotos := {}
var _con_fotos := false
var _pref_antes: Variant = null
var _vio_carta := false
var _vio_repe := false

func _ok(c: bool, txt: String) -> void:
	print(("  ok    " if c else "  FALLO ") + txt)
	if not c:
		_fallos += 1

func _ready() -> void:
	_con_fotos = DisplayServer.get_name() != "headless" and OS.get_environment("SIN_FOTOS") == ""
	## La ceremonia depende del ajuste del estadio: encendida para la prueba y
	## luego se deja como estaba.
	if FileAccess.file_exists(CajonAjustes.RUTA):
		_pref_antes = FileAccess.get_file_as_string(CajonAjustes.RUTA)
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, "ceremonia", true)
	cfg.set_value(CajonAjustes.SECCION, "repeticiones", true)
	cfg.save(CajonAjustes.RUTA)
	PartidoJugable.con_ceremonia = true
	CarreraJugadorUI.mundo = null
	_ui = load("res://escenas/carrera_jugador.tscn").instantiate()
	add_child(_ui)
	_ui._crear()
	var club := _ui.carrera.club(CarreraJugadorUI.mundo)
	var par := _ui._partido_de_la_semana(club)
	_pj = PartidoJugable.abrir(_ui, CarreraJugadorUI.mundo, _ui.carrera, par[0], par[1], 60.0)
	_pj.motor.autopiloto = true
	print("CEREMONIA")
	_ok(_pj.ceremonia_activa(), "el partido empieza con la ceremonia")
	_ok(not _pj.motor.is_physics_processing(), "el motor espera mientras dura")
	_ok(is_instance_valid(_pj._btn_saltar) and _pj._btn_saltar.visible, "hay botón «Saltar»")
	_ok(not _pj._hud.is_empty() and not _pj._hud[0].visible, "el marcador se esconde en la ceremonia")
	_ok(_pj.motor.duracion_gol >= CineGol.DURACION, "la celebración del motor dura lo que la realización (%.1f s)" % _pj.motor.duracion_gol)

func _foto(nombre: String) -> void:
	if not _con_fotos or _fotos.has(nombre):
		return
	_fotos[nombre] = true
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % nombre)
	print("FOTO %s" % nombre)

func _cer_t() -> float:
	return float(_pj._ceremonia._t) if _pj.ceremonia_activa() else -1.0

func _process(delta: float) -> void:
	_t += delta
	if _t > 240.0:
		_ok(false, "tiempo agotado en el paso %d" % _paso)
		_salir()
		return
	match _paso:
		0:
			## La ceremonia: vuelo, salida con los niños, carta de alineación.
			var ct := _cer_t()
			if _con_fotos:
				if ct >= 3.0:
					_foto("carrera_ceremonia_1")
				if ct >= 11.0:
					_foto("carrera_ceremonia_2")
				if ct >= 17.0:
					_foto("carrera_ceremonia_3")
			if ct >= (17.5 if _con_fotos else 1.0) or ct < 0.0:
				_pj.saltar_ceremonia()
				_ok(not _pj.ceremonia_activa(), "«Saltar» termina la ceremonia")
				_ok(_pj.motor.is_physics_processing(), "el motor arranca al terminar")
				_ok(_pj._hud[0].visible, "vuelve el marcador")
				_ok(_pj._cam.current, "vuelve la cámara del jugador")
				_ok(_pj.motor.minuto() == 0 and _pj.motor.goles == [0, 0], "el partido sigue en el saque inicial")
				_paso = 1
				_t = 0.0
		1:
			## Un poco de juego (que la repetición tenga qué grabar) y un gol
			## del jugador, cerca del área.
			if _t > (8.0 if _con_fotos else 2.5):
				var m := _pj.motor
				var yo := m.usuario
				_ok(not yo.is_empty(), "el jugador del usuario está en el campo")
				var d := MotorJugable.dir_ataque(bool(yo["es_local"]))
				(yo["node"] as Node3D).position = Vector3(4.0, 0, 40.0 * d)
				m.ultimo_toque = yo
				m.call("_gol", bool(yo["es_local"]))
				print("GOL")
				_ok(_pj.realizando_gol(), "el gol lanza la realización")
				_ok(_pj._repe.congelar, "la repetición deja de grabar en el gol")
				_ok(int(m.stats["goles"]) == 1, "el gol cuenta para el jugador")
				_ok(not _pj._hud_abajo[0].visible, "tu ficha de abajo deja sitio a la carta del goleador")
				var rot_fuera := true
				for f: Dictionary in m.jugadores + ([m.extra] if not m.extra.is_empty() else []):
					var n: Node3D = f.get("node")
					if is_instance_valid(n) and n.has_node(PlayerSpawner.ROTULO) and (n.get_node(PlayerSpawner.ROTULO) as Node3D).visible:
						rot_fuera = false
				_ok(rot_fuera, "sin nombres sobre los jugadores en la realización")
				_paso = 2
				_t = 0.0
		2:
			var cine := _pj._cine
			var c_t := cine.t if is_instance_valid(cine) else -1.0
			if not _vio_carta and not _pj.find_children("*", "CartaGoleador", true, false).is_empty():
				_vio_carta = true
			if c_t >= 1.8:
				_foto("carrera_gol_1")
			if c_t >= 4.4:
				_foto("carrera_gol_2")
			if c_t >= 6.2:
				_foto("carrera_gol_3")
			if not is_instance_valid(cine):
				_ok(_vio_carta, "sale la carta del goleador")
				_vio_repe = _pj._repe.reproduciendo
				_ok(_vio_repe, "tras la realización, la repetición")
				_ok(not _pj.motor.is_physics_processing(), "el motor espera durante la repetición")
				_paso = 3
				_t = 0.0
		3:
			if _t > 3.0:
				_foto("carrera_gol_repeticion")
			if not _pj._repe.reproduciendo:
				_ok(not _pj._repe.congelar, "la repetición vuelve a grabar")
				_ok(_pj.motor.is_physics_processing(), "el partido sigue tras la repetición")
				_ok(_pj._cam.current, "vuelve la cámara del jugador tras el gol")
				_ok(_pj._hud_abajo[0].visible, "vuelve tu ficha de abajo")
				_paso = 4
				_t = 0.0
		4:
			if _t > 1.0:
				_pj._simular_resto()
				_ok(_pj.motor.estado == "fin", "el resto se simula hasta el final")
				var res := _pj.resultado()
				_ok(int(res["goles"]) >= 1, "el resultado guarda el gol del jugador (%d)" % int(res["goles"]))
				_ok(not _pj.realizando_gol(), "simulando no se lanzan realizaciones")
				_pj._cerrar()
				_salir()

func _salir() -> void:
	set_process(false)
	## Los ajustes, tal como estaban.
	if _pref_antes == null:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CajonAjustes.RUTA))
	else:
		var f := FileAccess.open(CajonAjustes.RUTA, FileAccess.WRITE)
		if f != null:
			f.store_string(String(_pref_antes))
	print("===== FIN. %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
