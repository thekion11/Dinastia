extends Node
## EL PANEL DE REPUTACIÓN (26-9-2026), en Mi Carrera, con algo de historia.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_reputacion.tscn
var _n := 0
var _p: Node

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	var m: Mundo = _p.get("mundo") if _n >= 10 else null
	if _n == 10:
		var r := m.roles
		r.anotar_reputacion("ganador", 8, "Título: Liga")
		r.anotar_reputacion("honesto", 6, "El parte médico filtrado del rival")
		r.anotar_reputacion("mediatico", 5, "El documental del vestuario")
		r.anotar_reputacion("negociador", 4, "Venta de un juvenil por el 130 % de su valor")
		r.anotar_reputacion("social", -3, "El amistoso benéfico")
		r.anotar_reputacion("formador", 12, "6 canteranos en el plantel")
		_p.call("_ir_a_chip", {"tab": "Club", "secc": "carrera", "label": "Mi Carrera"})
		_p.call("_refrescar")
	if _n == 16:
		var lista: Control = _p.get("_lista_club")
		var sc := lista.get_parent()
		while sc != null and not (sc is ScrollContainer):
			sc = sc.get_parent()
		for l in lista.find_children("*", "Label", true, false):
			if (l as Label).text.contains("REPUTACIÓN") and sc != null:
				(sc as ScrollContainer).scroll_vertical = int((l as Label).global_position.y - lista.global_position.y) - 10
				break
	if _n == 24:
		get_viewport().get_texture().get_image().save_png("res://pruebas/reputacion.png")
		get_tree().quit()
