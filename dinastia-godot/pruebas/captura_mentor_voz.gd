extends Node
## EL MENTOR FUERA DEL TUTORIAL (26-9-2026, plan maestro C1): cambias el escudo
## y te lo comenta, con su cara, abajo a la izquierda.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_mentor_voz.tscn
var _n := 0
var _p: Node

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		var m: Mundo = _p.get("mundo")
		m.prensa.revisar_identidad(m.mi_club())
		m.mi_club().esc_forma = "redondo" if m.mi_club().esc_forma != "redondo" else "clasico"
		m.prensa.revisar_identidad(m.mi_club())
	if _n == 16:
		get_viewport().get_texture().get_image().save_png("res://pruebas/mentor_voz.png")
		get_tree().quit()
