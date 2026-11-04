extends BaseIdea
## A4-M3D (repaso 5 cruzado, 4-11-2026): el estadio del partido se construye y se libera varias veces (jugar
## partido tras partido en una sesión) sin que crezcan nodos, objetos ni memoria.
func _medir() -> Dictionary:
	return {"nodos": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), "objetos": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"huerfanos": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), "mem": int(OS.get_static_memory_usage() / 1048576)}

func _probar() -> void:
	_titulo("CICLOS DE ESTADIO")
	## El autoload Sonido sintetiza sus ~820 sonidos en un hilo durante los primeros segundos: sin esperar a que
	## termine, esa carga (objetos y MB) parece una fuga del estadio.
	get_node("/root/Sonido")._generar_todo()
	var m := _mundo(5)
	m.tomar_el_mando(m.ligas[0].clubes[2].id)
	var mio := m.mi_club()
	var tras: Array = []
	var n := int(OS.get_environment("CICLOS")) if OS.get_environment("CICLOS") != "" else 5
	for i in n:
		var raiz := Node3D.new()
		add_child(raiz)
		await StadiumBuilder.build(raiz, m.estadio.perfil(mio), 40000, 0.8, 1, mio)
		await get_tree().process_frame
		remove_child(raiz)
		raiz.free()
		await get_tree().process_frame
		await get_tree().process_frame
		tras.append(_medir())
		_linea("ciclo %d: %s" % [i + 1, tras[i]])
	var u: Dictionary = tras[tras.size() - 1]
	var k: Dictionary = tras[1]
	_comprobar(u["nodos"] <= k["nodos"] + 20, "los nodos no crecen entre ciclos (%d → %d)" % [k["nodos"], u["nodos"]])
	_comprobar(u["huerfanos"] <= k["huerfanos"] + 20, "no se acumulan huérfanos (%d → %d)" % [k["huerfanos"], u["huerfanos"]])
	_comprobar(u["objetos"] <= k["objetos"] + 12 * (n - 2), "los objetos no crecen entre ciclos (%d → %d)" % [k["objetos"], u["objetos"]])
	_comprobar(u["mem"] <= k["mem"] + 2 * (n - 2), "la memoria estática no crece entre ciclos (%d → %d MB)" % [k["mem"], u["mem"]])
