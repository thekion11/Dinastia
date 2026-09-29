extends Node
## EL PANEL DEL FONDO DE INVERSIÓN (26-9-2026), en Mi Carrera, con dos compras.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_fondo.tscn
var _n := 0
var _p: Node

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	var m: Mundo = _p.get("mundo") if _n >= 10 else null
	if _n == 10:
		m.fondo = FondoInversion.new()
		m.fondo.caja = int(round(Eco.ref_caja(70.0) * 2.5))
		var otros: Array = m.clubes.values().filter(func(x: Club) -> bool: return x.id != m.mi_club_id)
		otros.sort_custom(func(a: Club, b: Club) -> bool: return a.rep > b.rep)
		m.fondo.comprar(m, otros[3], 0.1)
		m.fondo.comprar(m, otros[8], 0.25)
		m.semana = 4
		m.fondo.semana(m)
		_p.call("_ir_a_chip", {"tab": "Club", "secc": "carrera", "label": "Mi Carrera"})
		_p.call("_refrescar")
	if _n == 16:
		var lista: Control = _p.get("_lista_club")
		var sc := lista.get_parent()
		while sc != null and not (sc is ScrollContainer):
			sc = sc.get_parent()
		for l in lista.find_children("*", "Label", true, false):
			if (l as Label).text.contains("FONDO DE INVERSIÓN") and sc != null:
				(sc as ScrollContainer).scroll_vertical = int((l as Label).global_position.y - lista.global_position.y) - 10
				break
	if _n == 24:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/fondo.png")
		get_tree().quit()
