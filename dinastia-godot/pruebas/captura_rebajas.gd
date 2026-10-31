extends Node
## ANTES / DESPUÉS DE LAS REBAJAS #1-#3 DEL PRESUPUESTO (28-10-2026): fotos del partido con la cámara de TV (el mundo congelado: el mismo cuadro) y con una cámara a pie de campo (como los planos laterales de las repeticiones), para ver que desde la TV no se nota. REBAJAS=0 apaga las tres (el «antes»). Guarda /tmp/rebajas_<antes|despues>_<tv|repe>.png
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
	if OS.get_environment("GRADA") == "0":   ## sin trocear la grada: para comprobar que el culling por trozos no deja butacas sin dibujar
		OptimizarGrada.activo = false
		_nombre = "sin_trozos"
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
		## Una cámara a pie de campo, pegada a la banda y mirando a la grada, como los planos laterales de las repeticiones (las repeticiones de verdad
		## eligen plano según la jugada y no salen iguales de una vez a otra): el mismo cuadro con y sin rebajas.
		var cam := Camera3D.new()
		cam.fov = 62.0
		_pj._raiz.add_child(cam)
		cam.global_position = Vector3(0.0, 1.7, 33.0)
		cam.look_at(Vector3(0.0, 4.0, 44.0), Vector3.UP)
		cam.make_current()
	if _n == 114:
		_foto("repe")
		Engine.time_scale = 1.0
		print("===== FIN. 0 fallos =====")
		get_tree().quit()
