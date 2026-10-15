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
		## LOS AMAGOS DE LA IA (H-11 / M-443, 15-10-2026): antes era solo un
		## AVISO (0 fintas). Ahora la IA amaga al ver venir al defensor, una
		## vez por duelo; se comprueba que pase, que no sea un festival y que
		## alguno engañe de verdad al defensor.
		var mot: MotorJugable = _vista.get("_motor")
		if mot != null:
			var jugado := float(mot.mitad - 1) * mot.duracion_mitad + mot.t
			var por_min := float(mot.regates_ia) / maxf(jugado / mot.duracion_mitad * 45.0, 1.0)
			print("  motor: %.0f s jugados (minuto %d), %d fintas de la IA (%d engañan), %.2f por minuto de partido" % [
				jugado, mot.minuto(), mot.regates_ia, mot.regates_ia_ok, por_min])
			_ok(mot.regates_ia > 0 or _amagues > 0, "hay amagues de la IA ante un rival (%d)" % maxi(mot.regates_ia, _amagues))
			_ok(mot.regates_ia_ok > 0, "alguna finta de la IA deja clavado al defensor (%d)" % mot.regates_ia_ok)
			_ok(por_min < 1.2, "sin festival de fintas (%.2f por minuto de partido)" % por_min)
		else:
			_ok(juego.regates_hechos > 0 or _amagues > 0, "hay amagues ante un rival (%d)" % maxi(juego.regates_hechos, _amagues))
		var con_balon := 0
		for f: Dictionary in _vista.get("_en_banca"):
			var n: Node3D = f.get("node")
			if is_instance_valid(n) and n.get_node_or_null("Dominadas") != null:
				con_balon += 1
		_ok(con_balon == 2, "un suplente por equipo calienta con dominadas (%d)" % con_balon)
		print("===== REGATES: %d fallos =====" % _fallos)
		_pref_ceremonia(true)
		get_tree().quit(0)
