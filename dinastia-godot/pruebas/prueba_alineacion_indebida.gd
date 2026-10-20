extends Node
## M-246 (20-10-2026): el aviso de ALINEACIÓN INDEBIDA sale en la pizarra cuando
## el once elegido se salta la ley de cupos del país (aquí, Chile: sin sub-21).
##   godot --headless --path . res://pruebas/prueba_alineacion_indebida.tscn
var _n := 0
var _p: Node

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n < 6:
		return
	var m: Mundo = _p.get("mundo")
	var c := m.mi_club()
	c.pais = "CHI"
	var viejos := c.plantilla.duplicate()
	viejos.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.edad > b.edad)
	var once: Array[Jugador] = []
	for j: Jugador in viejos:
		if once.size() < 11 and j.disponible():
			once.append(j)
	c.fijar_once(once)
	var infr := LeyesPais.infracciones_once(c, c._once_manual())
	var plantel: PantallaPlantel = _p.get("_ui_plantel")
	plantel._pintar_tactica(c)
	var lista: Node = _p.get("_lista_tactica")
	var hay := false
	for l in lista.find_children("*", "Label", true, false):
		if (l as Label).text.contains("ALINEACI"):
			hay = true
			print("AVISO: ", (l as Label).text.replace("\n", " | "))
	print(("  ok    " if (hay == not infr.is_empty()) and not infr.is_empty() else "  FALLO ") + "aviso de alineación indebida en la pizarra (%d infracciones)" % infr.size())
	get_tree().quit()
