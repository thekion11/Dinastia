extends Node
## LA JUNTA DE ACCIONISTAS EN EL DESPACHO (26-9-2026, plan maestro C5).
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_junta.tscn
var _n := 0
var _p: Node

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		var m: Mundo = _p.get("mundo")
		m.junta.semana(m.mi_club(), m.anio, Junta.CADA)
		m.federacion.revisar_presidencia(m.anio)
		_p.call("_refrescar")
		_p.call("_ir_a_pestana", "Inicio")
	if _n == 18:
		get_viewport().get_texture().get_image().save_png("res://pruebas/junta.png")
		get_tree().quit()
