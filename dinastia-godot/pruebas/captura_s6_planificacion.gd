extends Node
## SESIÓN 6 (26-10-2026): el plantel con el planificador, el tablón de la liga y los
## banquillos calientes abiertos (al empezar: el termómetro aún no mide).
##   herramientas/captura.sh res://pruebas/captura_s6_planificacion.tscn
var _p: Node
var _n := 0

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		var m: Mundo = _p.get("mundo")
		m.mi_club().once()[0].anios_contrato = 1
		PanelPlanificacion.abiertos = {"plan": true, "tablon": true, "termo": true}
		_p.call("_ir_a_pestana", "Mi plantel")
		_p.call("_refrescar")
	if _n == 18:
		var lista: Control = _p.get("_lista_plantel")
		var sc := lista.get_parent()
		while sc != null and not (sc is ScrollContainer):
			sc = sc.get_parent()
		for b in lista.find_children("*", "Button", true, false):
			if (b as Button).text.contains("PLANIFICADOR") and sc != null:
				(sc as ScrollContainer).ensure_control_visible(b)
				(sc as ScrollContainer).scroll_vertical += 300
	if _n == 24:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/s6_planificacion.png")
		get_tree().quit()
