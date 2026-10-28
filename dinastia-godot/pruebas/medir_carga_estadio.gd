extends Node
## LA PRIMERA CARGA DEL ESTADIO (MEGAPLAN fase 2): cuánto tarda abrirlo la
## primera vez y la segunda (con las cachés de caras y pelo ya llenas).
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://pruebas/medir_carga_estadio.tscn
var _n := 0
var _listo := false
var _guardados: Array[Resource] = []
var _mundo: Mundo
var _vista: VistaEstadio

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 777)
	_mundo.tomar_el_mando(_mundo.ligas[0].clubes[0].id)
	## PRECALENTAR=1: como en el juego, con las animaciones del personaje ya armadas por el hilo de `Precarga` (M-348).
	if OS.get_environment("PRECALENTAR") != "":
		for r: String in Precarga.FIJOS:   ## lo que ya habría leído `Precarga` en el menú
			if ResourceLoader.exists(r):
				_guardados.append(load(r))
		var id := PrecalentarAnim.lanzar()
		while not PrecalentarAnim.terminado():
			await get_tree().process_frame
		WorkerThreadPool.wait_for_task_completion(id)
	## CARAS=1: los dos onces del partido ya precalentados (sin espera entre uno y otro: mide lo que cuesta DESPUÉS, no el ritmo en el menú).
	if OS.get_environment("CARAS") != "":
		PrecalentarCaras.presupuesto_ms = 0.0
		PrecalentarCaras.por_fotograma = 80
		var t0 := Time.get_ticks_msec()
		var par0 := _mundo.proximo_partido()
		PrecalentarCaras.partido(par0[0], par0[1])
		while is_instance_valid(PrecalentarCaras._activa):
			await get_tree().process_frame
		print("MEDIDA jugadores precalentados: %d, en %d ms" % [PrecalentarCaras._hechos.size(), Time.get_ticks_msec() - t0])
	_listo = true
	CityBuilder._medir_tiempos = OS.get_environment("TIEMPOS") != ""

func _abrir() -> int:
	var par := _mundo.proximo_partido()
	var t := Time.get_ticks_msec()
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]))
	return Time.get_ticks_msec() - t

func _process(_d: float) -> void:
	if not _listo:
		return
	_n += 1
	if _n == 3:
		print("MEDIDA primera apertura: %d ms" % _abrir())
	if _n == 8:
		_vista.queue_free()
	if _n == 10:
		print("MEDIDA segunda apertura: %d ms" % _abrir())
	if _n == 14:
		get_tree().quit()
