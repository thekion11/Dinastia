extends Node
## Las 15 maestrías en pantalla (26-9-2026).
var _n := 0
var _p: Node

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	var m: Mundo = _p.get("mundo") if _n >= 10 else null
	if _n == 10:
		m.maestria.puntos = 12
		for k: String in ["ataque", "defensa", "liderazgo", "finanzas"]:
			m.maestria.niveles[k] = [30, 12, 7, 21][["ataque", "defensa", "liderazgo", "finanzas"].find(k)]
		_p.call("_elegir_grupo", "vida")
		_p.call("_ir_a_chip", {"tab": "Habilidades", "label": "Habilidades"})
	if _n == 30:
		var lista: Control = _p.get("_lista_habilidades")
		var sc := lista.get_parent() as ScrollContainer
		if sc != null:
			sc.scroll_vertical = 520
	if _n == 45:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/maestrias.png")
		get_tree().quit()
