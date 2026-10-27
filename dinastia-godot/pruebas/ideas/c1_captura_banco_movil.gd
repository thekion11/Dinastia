extends Node
## La app «Banco» del móvil con la cartera del DT (pieza A de §2.2h): efectivo, tarjeta, PIN y últimos movimientos.
##   herramientas/captura.sh res://pruebas/ideas/c1_captura_banco_movil.tscn   → pruebas/capturas/banco_movil.jpg
var _n := 0
var _p: Node
var _tel: Telefono

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		var m: Mundo = _p.get("mundo")
		if m.roles != null:
			m.roles.patrimonio = 400
			m.roles.cartera.efectivo = 37
			m.roles.cartera.pagar_efectivo(4, "Bocadillo", 1)
			m.roles.cartera.pagar_tarjeta(m.roles, 63, "Gasolina", "0000", 1)
			m.roles.cartera.retirar(m.roles, 100, "0000", 1, 2)
		var pop := Telefono.abrir(_p, m)
		_tel = pop.find_children("*", "Telefono", true, false)[0]
		_tel.abrir_app("banco")
	if _n == 40:
		DirAccess.make_dir_recursive_absolute("res://pruebas/capturas")
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/banco_movil.png")
		print("CAPTURA OK")
		get_tree().quit()
