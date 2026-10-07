extends Node
## LOS MODOS DE PARTIDO (25-9-2026, plan maestro B2): el selector en la pestaña
## Partido, el Resumen a mitad de camino y el final.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_modos_partido.tscn
const ESPERA := 12
var _n := 0
var _pantalla: Node
var _res: ResumenPartido

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		_pantalla.call("_ir_a_pestana", "Partido")
	if _n == ESPERA + 4:
		## Hasta el fondo de la pestaña, donde está el selector: se busca el
		## botón "Jugar" y se le pide a su ScrollContainer que lo muestre.
		var lista: Node = _pantalla.get("_lista_partido")
		var jugar: Control = null
		for h in lista.get_children():
			if h is Button and (h as Button).text.contains("Jugar el partido"):
				jugar = h
		var nodo: Node = lista
		while nodo != null and not (nodo is ScrollContainer):
			nodo = nodo.get_parent()
		if nodo != null and jugar != null:
			(nodo as ScrollContainer).ensure_control_visible(jugar)
	if _n == ESPERA + 6:
		_guardar("res://pruebas/capturas/modos_selector.png")
		_pantalla.call("_fijar_modo_simulacion", _pantalla.call("_competicion_de_la_semana"), "resumen")
		_pantalla.call("_dirigir")
		for h in _pantalla.get_children():
			if h is ResumenPartido:
				_res = h
	if _n > ESPERA + 6 and _n < ESPERA + 400 and _res != null and _res._t >= 11.0 and not has_meta("medio"):
		set_meta("medio", true)
		_guardar("res://pruebas/capturas/modos_resumen_medio.png")
		_res._mostrar_todo()
		set_meta("fin_en", _n + 4)
	if has_meta("fin_en") and _n == int(get_meta("fin_en")):
		_guardar("res://pruebas/capturas/modos_resumen_final.png")
		## Deja la preferencia como estaba de fábrica.
		_pantalla.call("_fijar_modo_simulacion", _pantalla.call("_competicion_de_la_semana"), "completo")
		get_tree().quit()
	if _n == ESPERA + 900:
		print("no llegó al resumen")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	get_viewport().get_texture().get_image().save_png(ruta)
	print("captura: " + ruta)
