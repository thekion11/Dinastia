extends Node
## EL DISEÑADOR DE EQUIPACIÓN EN PANTALLA (26-9-2026).
var _n := 0
var _p: Node
var _d: Node

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_dt: float) -> void:
	_n += 1
	if _n == 10:
		_d = DisenadorKit.abrir(_p, _p.get("mundo"))
		_d.set("_kit", {"dis": "rombos_escoceses", "cols": ["1f3a93", "ffffff", "d0202a", "f2c230", "111111"], "trim": 3, "num": "f2c230",
			"pant": {"dis": "lateral", "c1": "1f3a93", "c2": "f2c230"}, "med": {"dis": "aros", "c1": "ffffff", "c2": "1f3a93"},
			"bot": {"mod": "rayo", "c1": "1b1b1b", "c2": "d4af37", "c3": "d4af37"}, "acc": {"munequeras": "f2c230"}})
		_d.call("_rehacer")
	if _n == 70:
		get_viewport().get_texture().get_image().save_png("res://pruebas/disenador_camiseta.png")
		(_d.get("_pestanas") as TabContainer).current_tab = 3
	if _n == 85:
		get_viewport().get_texture().get_image().save_png("res://pruebas/disenador_botines.png")
		get_tree().quit()
