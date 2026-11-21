class_name PanelPlantel
extends "res://ui/componentes/panel_plantel_p1.gd"
## (Parte 2 de 2 de `panel_plantel.gd`.)

## Calcado de `Principal._comparar_plantel()`, con `orden`/`orden_desc` como
## parámetros en vez de leídos de estado propio -pura del todo-. Mismo cuidado
## que ya costó un bug real el 11-9: con empate, ninguna combinación de `a`/`b`
## puede devolver `true`, o Godot rompe el orden con "bad comparison function".
static func _comparar(a: Jugador, b: Jugador, orden: String, orden_desc: bool) -> bool:
	var x := b if orden_desc else a
	var y := a if orden_desc else b
	match orden:
		"nombre": return x.nombre.naturalnocasecmp_to(y.nombre) < 0
		"pos": return x.pos_e < y.pos_e
		"edad": return x.edad < y.edad
		"pot": return x.pot < y.pot
		"valor": return x.valor < y.valor
		_: return x.ovr < y.ovr

static func _texto(tam: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	return l

static func _limpiar(n: Node) -> void:
	for h in n.get_children():
		n.remove_child(h)
		h.queue_free()

## Calcado de `Principal._dinero()`, con el mismo factor `Eco.ECO`.
static func _dinero(monto: int) -> String:
	return Eco.dinero(monto)
