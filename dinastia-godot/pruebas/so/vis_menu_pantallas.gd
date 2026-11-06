extends "res://pruebas/so/vis_base.gd"
## VISUALIZACIÓN · seis pantallas del menú de gestión, fotografiadas con el renderizador real en Compatibilidad (el de móvil/Web): cada una no
## está vacía, cada una es DISTINTA de la anterior (si el cambio de pestaña no cambia nada, es un fallo), se guardan en JPG y se comparan con la referencia.
func _nombre() -> String:
	return "vis_menu_pantallas"

const PESTANAS := ["Inicio", "Mi plantel", "Táctica", "Finanzas", "Mercado", "Ajustes"]

func _probar() -> void:
	_titulo("VISUALIZACIÓN · pantallas del menú, %s [%s]" % [_metodo(), sistema()])
	_respaldar_user()
	_comprobar(DisplayServer.get_name() != "headless", "hay pantalla (%s)" % DisplayServer.get_name())
	Animar._reducidas = 1
	var m := _mundo(20261026)
	PedidoPartida.mundo_pregenerado = m
	var p: Principal = load("res://escenas/principal.tscn").instantiate()
	add_child(p)
	await _frames(10)
	for t in get_tree().root.find_children("*", "Tutorial", true, false):
		(t as Tutorial)._terminar(false)
	CapasTutorial.poner_activas(false)
	var anterior: Array = []
	for i in PESTANAS.size():
		p._ir_a_pestana(PESTANAS[i])
		await _frames(30)
		var img := _foto()
		var nombre := "menu_%02d" % i
		_no_vacia(img, PESTANAS[i])
		_guardar(img, nombre)
		_comparar(img, nombre, 0.03, 0.20)
		var celdas := _celdas(img)
		if not anterior.is_empty():
			var dif := 0
			for k in celdas.size():
				dif += int((celdas[k] - anterior[k]).abs().length() / 1.7320508 > 0.03)
			_comprobar(dif >= 4, "«%s» se ve distinta de la anterior (%d celdas)" % [PESTANAS[i], dif])
		anterior = celdas
	p.queue_free()
	await _frames(2)
	_restaurar_user()
