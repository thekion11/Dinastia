extends Node
## FOTOS DE LA RUTA (15-11-2026): crear, ofertas, hoy, yo, ruta y cada pantalla de dentro. OUT = carpeta (fuera del repo).
##   OUT=... [MOVIL=1] godot --path . --resolution 1920x1080 res://pruebas/captura_ruta.tscn
var _ui: CarreraJugadorUI
var _dir := "user://fotos_ruta"
var _n := 0

func _foto(nombre: String) -> void:
	for _i in 8:
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	_n += 1
	var ruta := "%s/%02d_%s.jpg" % [_dir, _n, nombre]
	get_viewport().get_texture().get_image().save_jpg(ruta, 0.9)
	print("foto ", ruta)

func _ready() -> void:
	RutaEstilo.sin_animar = true
	if OS.get_environment("OUT") != "":
		_dir = OS.get_environment("OUT")
	DirAccess.make_dir_recursive_absolute(_dir)
	if OS.get_environment("MOVIL") == "1":
		EscalaMovil.forzar = true
		EscalaMovil.poner(get_tree(), EscalaMovil.ZOOM_MOVIL)
	CarreraJugadorUI.mundo = null
	_ui = load("res://escenas/carrera_jugador.tscn").instantiate()
	add_child(_ui)
	await _foto("crear")
	_ui._buscar_club()
	await _foto("ofertas")
	_ui._firmar(null)
	var c := _ui.carrera
	c.ruta["puntos"] = 3
	for pest: String in ["hoy", "yo", "ruta"]:
		_ui._pestana = pest
		_ui._pintar_semana()
		await _foto(pest)
	for id: String in RutaSub.SUBS:
		_ui._pestana = String(RutaSub.SUBS[id][0])
		_ui._sub = id
		_ui._pintar_semana()
		await _foto("sub_" + id)
	get_tree().quit()
