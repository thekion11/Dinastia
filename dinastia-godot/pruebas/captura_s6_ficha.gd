extends Node
## SESIÓN 6 (26-10-2026): la ficha propia con el radar de líneas suaves y el
## plegable «¿por qué sube o baja?» abierto, y la pizarra táctica.
##   herramientas/captura.sh res://pruebas/captura_s6_ficha.tscn
var _p: Node
var _n := 0

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _foto(n: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % n)

func _boton_porque(n: Node) -> Button:
	for b in n.find_children("*", "Button", true, false):
		if (b as Button).text.contains("¿POR QUÉ"):
			return b
	return null

func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		var mundo: Mundo = _p.get("mundo")
		var joven: Jugador = mundo.mi_club().plantilla[0]
		for j: Jugador in mundo.mi_club().plantilla:
			if j.edad < joven.edad:
				joven = j
		FichaPorque.abierto = true
		_p.call("_ver_ficha", joven)
	if _n == 14:
		_foto("s6_ficha_radar")
		var b := _boton_porque(_p.get("_ficha"))
		var sc := b.get_parent()
		while sc != null and not (sc is ScrollContainer):
			sc = sc.get_parent()
		if sc != null:
			(sc as ScrollContainer).ensure_control_visible(b)
			(sc as ScrollContainer).scroll_vertical += 200
	if _n == 18:
		_foto("s6_ficha_porque")
		_p.call("_ir_a_pestana", "Táctica")
	if _n == 26:
		_foto("s6_pizarra")
		FichaPorque.abierto = false
		get_tree().quit()
