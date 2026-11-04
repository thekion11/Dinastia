extends Node
## LA DIFICULTAD DE LA CPU EN EL PARTIDO JUGABLE DE LA CARRERA (caza de fallos, 4-11-2026): el nivel guardado en los ajustes vale para el equipo RIVAL (antes no hacía nada en este modo).
##   godot --headless --path . res://pruebas/dificultad_partido_jugable.tscn
var _n := 0
var _ui: CarreraJugadorUI
var _fallos := 0
var _guardado := ""

func _comprobar(ok: bool, texto: String) -> void:
	print(("  ok     " if ok else "  FALLO  ") + texto)
	if not ok:
		_fallos += 1

func _poner(nivel: String) -> void:
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, "dificultad_cpu8", nivel)
	cfg.save(CajonAjustes.RUTA)

func _ready() -> void:
	_guardado = VistaEstadio.dificultad_cpu_guardada()
	PartidoJugable.con_ceremonia = false
	CarreraJugadorUI.mundo = null
	_ui = load("res://escenas/carrera_jugador.tscn").instantiate()
	add_child(_ui)

func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		_ui._crear()
	if _n == 20:
		var club := _ui.carrera.club(CarreraJugadorUI.mundo)
		var par := _ui._partido_de_la_semana(club)
		for nivel in ["ultimate", "practicante", "debutante"]:
			_poner(nivel)
			var pj := PartidoJugable.abrir(_ui, CarreraJugadorUI.mundo, _ui.carrera, par[0], par[1], 20.0)
			var m: MotorJugable = pj.motor
			var rival := 1 if pj._es_local_usuario else 0
			_comprobar(m.dificultad_cpu == nivel and m.equipo_cpu() == rival, "%s: el rival (%s) es la CPU con ese nivel" % [nivel, "visita" if rival == 1 else "local"])
			var cpu_mas := 0
			var cpu_menos := 0
			var mios_igual := true
			for p: Dictionary in m.jugadores:
				if p["attr"].is_empty() or p["attr_puro"].is_empty() or bool(p["por"]):
					continue
				var dif: float = float(p["attr"]["pas"]) - float(p["attr_puro"]["pas"])
				if (0 if bool(p["es_local"]) else 1) == rival:
					if dif > 0.001: cpu_mas += 1
					elif dif < -0.001: cpu_menos += 1
				elif absf(dif) > 0.0001:
					mios_igual = false
			_comprobar(mios_igual, "%s: tu equipo no cambia" % nivel)
			if nivel == "ultimate":
				_comprobar(cpu_mas >= 8, "ultimate: la CPU pasa mejor (%d jugadores)" % cpu_mas)
			elif nivel == "practicante":
				_comprobar(cpu_menos >= 8, "practicante: la CPU pasa peor (%d jugadores)" % cpu_menos)
			else:
				_comprobar(cpu_mas == 0 and cpu_menos == 0, "debutante: nada cambia (el motor de siempre)")
			pj.queue_free()
			await get_tree().process_frame
		_poner(_guardado)
		print("===== FIN. %d fallos =====" % _fallos)
		set_process(false)
		get_tree().quit(0 if _fallos == 0 else 1)
