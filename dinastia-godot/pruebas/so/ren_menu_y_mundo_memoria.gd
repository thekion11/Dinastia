extends BaseSO
## RENDIMIENTO · memoria y nodos sin gráfica (valen en --headless, Web y Android): generar tres mundos seguidos no acumula memoria (fuga), el menú
## principal montado y desmontado devuelve los nodos y no crece sin tope, y las cifras caben en el tope del sistema (el móvil, mucho más estricto).
## Es medir recuentos y megabytes, NUNCA el tiempo de fotograma.
func _nombre() -> String:
	return "ren_menu_y_mundo_memoria"

func _mb() -> float:
	return OS.get_static_memory_usage() / 1048576.0

func _probar() -> void:
	_titulo("RENDIMIENTO · memoria y nodos [%s]" % sistema())
	_respaldar_user()
	var base := _mb()
	var tope_arranque := presupuesto(_nombre(), "arranque_mb")
	_comprobar(base < tope_arranque, "memoria estática al empezar %.0f MB < %.0f MB" % [base, tope_arranque])
	var picos: Array[float] = []
	for i in 3:
		var m := Mundo.new()
		m.generar(["CHI", "ARG"], 100 + i)
		m.tomar_el_mando(m.ligas[0].clubes[0].id)
		m.avanzar_semana()
		picos.append(_mb())
		m = null
		await _frames(3)
	print("  INFO  memoria tras cada mundo: ", str(picos.map(func(x): return snappedf(x, 1.0))))
	_comprobar(picos[2] - picos[0] < presupuesto(_nombre(), "fuga_tres_mundos_mb"), "tres mundos seguidos: el tercero ocupa %.0f MB más que el primero (sin fuga)" % (picos[2] - picos[0]))
	var nodos0 := get_tree().get_node_count()
	PedidoPartida.mundo_pregenerado = _mundo(7)
	var p: Node = load("res://escenas/principal.tscn").instantiate()
	add_child(p)
	await _frames(10)
	var nodos1 := get_tree().get_node_count()
	var tope_nodos := int(presupuesto(_nombre(), "nodos_menu"))
	_comprobar(nodos1 - nodos0 < tope_nodos, "el menú principal añade %d nodos (< %d)" % [nodos1 - nodos0, tope_nodos])
	_comprobar(nodos1 - nodos0 > int(presupuesto(_nombre(), "nodos_menu_minimo")), "…y no está vacío (%d nodos)" % (nodos1 - nodos0))
	var mem_menu := _mb()
	_comprobar(mem_menu < tope_arranque + 600.0, "con el menú montado, %.0f MB" % mem_menu)
	p.queue_free()
	await _frames(5)
	var nodos2 := get_tree().get_node_count()
	_comprobar(nodos2 <= nodos0 + 60, "al cerrar el menú los nodos vuelven a lo de antes (%d → %d)" % [nodos0, nodos2])
	_restaurar_user()
