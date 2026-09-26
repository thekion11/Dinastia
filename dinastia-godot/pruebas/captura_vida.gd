extends Node
## MI VIDA Y EL ÁRBOL DE HABILIDADES EN PANTALLA (26-9-2026).
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_vida.tscn
var _n := 0
var _p: Node

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _foto(nombre: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://pruebas/%s.png" % nombre)

func _process(_d: float) -> void:
	_n += 1
	var m: Mundo = _p.get("mundo") if _n >= 10 else null
	if _n == 10:
		m.roles.patrimonio = 180000
		m.vida.estres = 62
		m.vida.familia = 48
		m.vida.pendiente = {"tipo": "cumple", "texto": "Es el cumpleaños de Martina y cae el día del entrenamiento táctico.", "a": "Ir al cumpleaños", "b": "Quedarse en el entrenamiento"}
		m.entrenamiento.dt_puntos = 3
		m.entrenamiento.dt_aprender("pizarra")
		m.entrenamiento.dt_aprender("motivador")
		_p.call("_elegir_grupo", "vida")
		_p.call("_ir_a_chip", {"tab": "Vida", "secc": "bienestar", "label": "Bienestar"})
	if _n == 30:
		_foto("vida_bienestar")
		_p.call("_ir_a_chip", {"tab": "Vida", "secc": "hogar", "label": "Casa y auto"})
	if _n == 50:
		_foto("vida_hogar")
		_p.call("_ir_a_chip", {"tab": "Vida", "secc": "familia", "label": "Familia"})
	if _n == 70:
		_foto("vida_familia")
		_p.call("_ir_a_chip", {"tab": "Habilidades", "label": "Habilidades"})
	if _n == 80:
		var arbol: Node = null
		for x in _p.find_children("*", "ArbolHabilidades", true, false):
			arbol = x
		if arbol != null:
			arbol.call("_elegir", "bloque")
	if _n == 95:
		_foto("arbol_habilidades")
		var e: Entrenamiento = m.entrenamiento
		var capa: Control = ArbolHabilidades.abrir_en_grande(_p, e, func() -> void: pass)
		for x in capa.find_children("*", "ArbolHabilidades", true, false):
			x.call("_elegir", "bloque")
	if _n == 115:
		_foto("arbol_grande")
		get_tree().quit()
