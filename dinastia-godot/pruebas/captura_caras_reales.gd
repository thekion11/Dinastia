extends Node
## LAS CARAS REALES EN EL JUEGO (25-9-2026): con el pack real puesto, el club
## propio pasa a ser el que más fotos tiene, y se guardan el tablero de inicio
## y la ficha de su estrella (con el crédito de la foto).
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_caras_reales.tscn
const ESPERA := 12
var _n := 0
var _pantalla: Node
var _base_antes := false

func _ready() -> void:
	_base_antes = Datos.base_real
	Datos.usar_base_real(true)
	Cara.limpiar_cache()
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		var mundo: Mundo = _pantalla.get("mundo")
		var mejor_club: Club = null
		var mejor_n := -1
		for c: Club in mundo.clubes.values():
			var n := 0
			for j: Jugador in c.plantilla:
				if Cara.foto_real(j) != null:
					n += 1
			if n > mejor_n:
				mejor_n = n
				mejor_club = c
		print("club con más fotos: %s (%d)" % [mejor_club.nombre, mejor_n])
		mundo.mi_club_id = mejor_club.id
		_pantalla.call("_refrescar")
		_pantalla.call("_ir_a_pestana", "Inicio")
	if _n == ESPERA + 8:
		_guardar("res://pruebas/caras_reales_inicio.png")
		var mio: Club = _pantalla.get("mundo").mi_club()
		var estrella: Jugador = null
		for j: Jugador in mio.plantilla:
			if Cara.foto_real(j) != null and (estrella == null or j.ovr > estrella.ovr):
				estrella = j
		_pantalla.call("_ir_a_pestana", "Club")
		_pantalla.call("_ver_ficha", estrella)
	if _n == ESPERA + 16:
		_guardar("res://pruebas/caras_reales_ficha.png")
		Datos.usar_base_real(_base_antes)
		get_tree().quit()

func _guardar(ruta: String) -> void:
	get_viewport().get_texture().get_image().save_png(ruta)
	print("captura: " + ruta)
