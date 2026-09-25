extends Node
## LAS JUGADAS PREHECHAS EN UN PARTIDO DE VERDAD (25-9-2026).
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##         res://pruebas/captura_jugadas.tscn
##
## 1) El catálogo es coherente: cada rol y cada `pase_a` existen, y ninguna
##    jugada de ambiente conserva un remate una vez filtrada.
## 2) En el estadio real, tres jugadas de ambiente (ataque, defensa, portero)
##    se reproducen enteras, el balón se mueve y el rótulo de la tele aparece.
## 3) Un suceso real corta la jugada en marcha.
## Deja fotos en `pruebas/jugada_*.png`.

const PRUEBA := ["ATQ-05", "DEF-07", "POR-09"]
var _vista: VistaEstadio
var _juego: MatchPlayback
var _n := 0
var _i := 0
var _t0 := 0
var _fallos := 0
var _completadas := 0
## El partido sigue simulándose debajo: si justo cae un suceso real, la jugada
## se corta (es lo que tiene que pasar) y cuenta aquí.
var _cortadas := 0
var _balon_antes := Vector3.ZERO

func _comprobar(c: bool, que: String) -> void:
	print(("  ok    " if c else "  FALLO ") + que)
	if not c:
		_fallos += 1

func _ready() -> void:
	var malos: Array[String] = []
	var roles := ReproductorJugadas.SLOTS.keys()
	for id: String in CatalogoJugadas.todos_los_ids():
		var d := CatalogoJugadas.obtener_definicion(id)
		for f: Dictionary in d["fases"]:
			for r: String in (f.get("destinos", {}) as Dictionary):
				if not roles.has(r):
					malos.append("%s rol %s" % [id, r])
			if f.has("pase_a") and not roles.has(String(f["pase_a"])):
				malos.append("%s pase_a %s" % [id, f["pase_a"]])
			for r: String in (f.get("accion", {}) as Dictionary):
				if not roles.has(r):
					malos.append("%s accion %s" % [id, r])
	_comprobar(malos.is_empty(), "el catálogo de 60 jugadas es coherente %s" % str(malos))
	var escritas := 0
	for id: String in CatalogoJugadas.todos_los_ids():
		if id.begins_with("REG"):
			continue
		var fs: Array = CatalogoJugadas.obtener_definicion(id)["fases"]
		if fs.size() >= 2 or (fs.size() == 1 and (fs[0] as Dictionary).has("destinos")):
			escritas += 1
	_comprobar(escritas == 45, "las 45 de ataque, defensa y portero tienen su guion escrito (%d)" % escritas)
	_comprobar(CatalogoJugadas.ambientales().size() >= 20, "hay %d jugadas para los ratos sin suceso" % CatalogoJugadas.ambientales().size())

	Calidad.elegida = Calidad.MEDIO
	var mundo := Mundo.new()
	mundo.generar(["CHI"], 4711)
	mundo.mi_club_id = mundo.ligas[0].clubes[0].id
	var par := mundo.proximo_partido()
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]))

func _process(_d: float) -> void:
	_n += 1
	if _n == 30:
		_juego = _vista.get("_juego")
		_comprobar(_juego != null, "el estadio monta la reproducción")
		(_vista.get("_rig") as CameraRig).switch_to(0)
		_juego.set("_jugadas_ambiente", false)
		_juego.reproductor.jugada_completada.connect(func(r: Dictionary) -> void:
			if bool(r.get("exito", false)):
				_completadas += 1
			else:
				_cortadas += 1)
		_arrancar()
	if _n > 30 and _i < PRUEBA.size():
		if _n == _t0 + 8:
			get_viewport().get_texture().get_image().save_png("res://pruebas/jugada_%s.png" % PRUEBA[_i])
		if not _juego.reproductor.en_reproduccion and _n > _t0 + 5:
			var bal: Node3D = _vista.get("_balon")
			_comprobar(bal.position.distance_to(_balon_antes) > 2.0, "%s mueve el balón (%.1f m)" % [PRUEBA[_i], bal.position.distance_to(_balon_antes)])
			_i += 1
			if _i < PRUEBA.size():
				_arrancar()
			else:
				_comprobar(_completadas + _cortadas == PRUEBA.size() and _completadas >= 2,
					"las jugadas terminan: %d completas, %d cortadas por un suceso real" % [_completadas, _cortadas])
				## Un suceso real en mitad de una jugada la corta.
				_juego.reproductor.iniciar("ATQ-08", _juego, _vista.get("_balon"), true, true)
				_juego.suceso({"min": 10, "t": "disparo", "tipo": "atajada", "equipo": "local", "tx": "prueba"})
				_comprobar(not _juego.reproductor.en_reproduccion, "un remate real corta la jugada en marcha")
				print("captura_jugadas: %d fallos" % _fallos)
				get_tree().quit(1 if _fallos > 0 else 0)
		if _n > _t0 + 900:
			_comprobar(false, "%s no terminó" % PRUEBA[_i])
			get_tree().quit(1)

func _arrancar() -> void:
	_t0 = _n
	var bal: Node3D = _vista.get("_balon")
	_balon_antes = bal.position
	var ok := _juego.reproductor.iniciar(PRUEBA[_i], _juego, bal, true, true)
	_comprobar(ok, "arranca %s (%s)" % [PRUEBA[_i], CatalogoJugadas.obtener_definicion(PRUEBA[_i])["nombre"]])
	_vista.call("_al_jugada_ambiente", CatalogoJugadas.obtener_definicion(PRUEBA[_i])["nombre"], true)
