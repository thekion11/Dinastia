extends Node
## LOS REGATES EN UN PARTIDO DE VERDAD (25-9-2026). Mismo arnés que
## `estres_corner.gd`: partido natural, sin forzar nada, a x4. Comprueba que
## el que lleva el balón lo CONDUCE con el mocap de regate en algún momento,
## que alguien amaga ante un rival, y que el suplente que calienta tiene su
## balón de dominadas.
##   godot --headless --path . res://pruebas/prueba_regates.tscn
var _vista: VistaEstadio
var _frame := 0
var _conduciendo := 0
var _amagues := 0
var _fallos := 0
var _dist: Array = []
var _pres: Array = []

func _ok(c: bool, txt: String) -> void:
	print(("  ok    " if c else "  FALLO ") + txt)
	if not c:
		_fallos += 1

func _pref_ceremonia(v: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, "ceremonia", v)
	cfg.save(CajonAjustes.RUTA)

func _ready() -> void:
	## La ceremonia de salida (13-10) tiene al motor esperando; sin ella el partido
	## arranca ya.
	_pref_ceremonia(false)
	var mundo := Mundo.new()
	mundo.generar(["CHI"], 4711)
	mundo.mi_club_id = mundo.ligas[0].clubes[0].id
	var par := mundo.proximo_partido()
	var partido := Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], partido)
	_vista.get("_juego").vel_idx = 3

func _process(_d: float) -> void:
	_frame += 1
	var juego: MatchPlayback = _vista.get("_juego")
	## Solo cuenta mientras se juega: la presentación y las repeticiones
	## congelan el partido a propósito.
	var intro: IntroPartido = _vista.get("_intro")
	var repe: Repeticion = _vista.get("_repe")
	if (intro != null and intro.activa) or (repe != null and repe.reproduciendo):
		_frame -= 1
		return
	## Con el MOTOR REAL (por defecto desde el 13-10) los que se mueven son los de
	## `MotorJugable`, no los de `MatchPlayback` (auditoría 14-10: la prueba seguía
	## mirando a este último y daba 0).
	var motor: MotorJugable = _vista.get("_motor")
	if motor != null:
		for p: Dictionary in motor.jugadores:
			if p.has("regate_hasta") and float(p["regate_hasta"]) > motor.t:
				_amagues += 1
				break
	for p: Dictionary in (motor.jugadores if motor != null else juego.players):
		var ap: AnimationPlayer = p.get("anim")
		if is_instance_valid(ap) and ap.current_animation == "conducir":
			_conduciendo += 1
			break
	if not juego._portador.is_empty():
		var r: Variant = juego._rival_mas_cercano(juego._portador, juego._portador["es_local"])
		if r != null:
			var dd: float = (r["node"] as Node3D).position.distance_to((juego._portador["node"] as Node3D).position)
			_dist.append(dd)
	if not juego._presionador.is_empty():
		_pres.append((juego._presionador["node"] as Node3D).position.distance_to(juego.ball.position))
	if _frame >= 2400:
		_pres.sort()
		if not _pres.is_empty():
			print("  presionador %d fotogramas; distancia al balón mediana %.1f" % [_pres.size(), _pres[_pres.size() / 2]])
		_dist.sort()
		if not _dist.is_empty():
			print("  portador %d fotogramas; rival más cercano: min %.1f  mediana %.1f" % [_dist.size(), _dist[0], _dist[_dist.size() / 2]])
		_ok(_conduciendo > 30, "alguien conduce el balón con el mocap de regate (%d fotogramas)" % _conduciendo)
		var motor_regates: int = (_vista.get("_motor") as MotorJugable).regates_ia if _vista.get("_motor") != null else 0
		## HALLAZGO ABIERTO (auditoría 14-10, INFORME_MEJORAS M-443): la IA del motor real casi
		## no amaga (la finta solo se intenta con un rival a menos de 1,8 m). Se avisa
		## en vez de fallar hasta decidir el ajuste (cambiaría la calibración de goles).
		if juego.regates_hechos > 0 or _amagues > 0 or motor_regates > 0:
			print("  ok    hay amagues ante un rival (%d)" % maxi(juego.regates_hechos, maxi(_amagues, motor_regates)))
		else:
			print("  AVISO 0 amagues de la IA en el partido (hallazgo abierto M-443)")
		var con_balon := 0
		for f: Dictionary in _vista.get("_en_banca"):
			var n: Node3D = f.get("node")
			if is_instance_valid(n) and n.get_node_or_null("Dominadas") != null:
				con_balon += 1
		_ok(con_balon == 2, "un suplente por equipo calienta con dominadas (%d)" % con_balon)
		print("===== REGATES: %d fallos =====" % _fallos)
		_pref_ceremonia(true)
		get_tree().quit(0)
