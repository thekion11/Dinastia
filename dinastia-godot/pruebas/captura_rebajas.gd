extends Node
## ANTES / DESPUÉS DE LAS REBAJAS #1-#3 DEL PRESUPUESTO (28-10-2026): fotos del partido con la cámara de TV (el mundo congelado: el mismo cuadro) y con la de
## repetición, para ver que desde la TV no se nota. REBAJAS=0 apaga las tres (el «antes»). Guarda /tmp/rebajas_<antes|despues>_<tv|repe>.png
##   [REBAJAS=0] godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_rebajas.tscn
var _n := 0
var _ui: CarreraJugadorUI
var _pj: PartidoJugable
var _nombre := "despues"

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		print("sin pantalla no se captura nada")
		print("===== FIN. 0 fallos =====")
		get_tree().quit()
		return
	if OS.get_environment("REBAJAS") == "0":
		StadiumBuilder.butaca_detalle_filas = 99
		EntornoEstadio.optimizar_partido = false
		_nombre = "antes"
	PartidoJugable.con_ceremonia = false
	CarreraJugadorUI.mundo = null
	_ui = load("res://escenas/carrera_jugador.tscn").instantiate()
	add_child(_ui)

func _foto(cual: String) -> void:
	get_viewport().get_texture().get_image().save_png("/tmp/rebajas_%s_%s.png" % [_nombre, cual])

func _process(_d: float) -> void:
	_n += 1
	if _n == 5:
		_ui._crear()
	if _n == 15:
		var club := _ui.carrera.club(CarreraJugadorUI.mundo)
		var par := _ui._partido_de_la_semana(club)
		_pj = PartidoJugable.abrir(_ui, CarreraJugadorUI.mundo, _ui.carrera, par[0], par[1], 120.0)
	if _n == 100:
		Engine.time_scale = 0.0
	if _n == 110:
		_foto("tv")
		Engine.time_scale = 1.0
		print("REPE guardado: %.1f s" % _pj._repe.segundos_guardados())
	if _n == 112:
		print("REPE reproduce: ", _pj._repe.reproducir(3.0))
	if _n == 140:
		_foto("repe")
		print("===== FIN. 0 fallos =====")
		get_tree().quit()
