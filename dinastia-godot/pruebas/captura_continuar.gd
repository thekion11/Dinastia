extends Node
const ESPERA := 12
var _n := 0
var _pantalla: Node
func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 4141)
	m.tomar_el_mando(m.ligas[0].clubes[2].id)
	for s in 6:
		m.avanzar_semana()
	Partida.guardar(m, "partida")
	_pantalla = load("res://escenas/inicio.tscn").instantiate()
	add_child(_pantalla)
func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		_guardar("res://pruebas/pantalla_continuar.png")
		get_tree().quit()
func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s" % ruta)
