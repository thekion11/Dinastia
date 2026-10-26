extends Node
## SESIÓN 6 (26-10-2026): «Novedades» encima del menú de modos y la lista de los
## logros a largo plazo en la pestaña Logros (con una carrera a medias).
##   herramientas/captura.sh res://pruebas/captura_s6_novedades.tscn
var _n := 0
var _menu: PantallaModos
var _p: Node

func _ready() -> void:
	_menu = PantallaModos.new()
	add_child(_menu)

func _foto(n: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % n)

func _process(_d: float) -> void:
	_n += 1
	if _n == 30:
		for b in _menu.find_children("*", "Button", true, false):
			if (b as Button).text.contains("Novedades"):
				(b as Button).pressed.emit()
	if _n == 40:
		_foto("s6_novedades")
		_menu.queue_free()
		_p = load("res://escenas/principal.tscn").instantiate()
		add_child(_p)
	if _n == 52:
		var lg: Logros = _p.get("mundo").logros
		lg.carrera = {"pj": 312, "pg": 171}
		lg.rachas["ganando_max"] = 7
		lg.canteranos_debutados = {"a": true, "b": true, "c": true}
		_p.call("_ir_a_pestana", "Logros")
	if _n == 58:
		var lista: Control = _p.get("_lista_logros")
		var sc := lista.get_parent()
		while sc != null and not (sc is ScrollContainer):
			sc = sc.get_parent()
		for l in lista.find_children("*", "Label", true, false):
			if (l as Label).text.contains("A LARGO PLAZO") and sc != null:
				(sc as ScrollContainer).ensure_control_visible(l)
				(sc as ScrollContainer).scroll_vertical += 260
	if _n == 64:
		_foto("s6_logros_largos")
		get_tree().quit()
