extends BaseIdea
## SEÑALES SIN DESCONECTAR (M-386, 28-10-2026): abrir y cerrar un partido jugable no debe dejar conexiones nuevas en el mundo (que vive toda la partida), ni
## objetos de más. Cada vuelta: abrir el partido de la semana, simularlo, cerrarlo SIN avanzar la semana. La primera vuelta calienta cachés; se compara la
## 2.ª con la 4.ª.

func _conexiones(o: Object) -> int:
	var n := 0
	for s: Dictionary in o.get_signal_list():
		n += o.get_signal_connection_list(String(s["name"])).size()
	return n

func _ready() -> void:
	await get_tree().process_frame
	_titulo("SEÑALES SIN DESCONECTAR EN EL PARTIDO JUGABLE")
	PartidoJugable.con_ceremonia = false
	CarreraJugadorUI.mundo = null
	var ui: CarreraJugadorUI = load("res://escenas/carrera_jugador.tscn").instantiate()
	add_child(ui)
	ui._crear()
	var m: Mundo = CarreraJugadorUI.mundo
	var club := ui.carrera.club(m)
	var medidas: Array = []
	for vuelta in int(OS.get_environment("VUELTAS")) if OS.get_environment("VUELTAS") != "" else 4:
		var par := ui._partido_de_la_semana(club)
		var pj := PartidoJugable.abrir(ui, m, ui.carrera, par[0], par[1], 240.0)
		await get_tree().process_frame
		if OS.get_environment("SIN_SIM") == "":
			pj._simular_resto()
		pj.queue_free()
		for i in 3:
			await get_tree().process_frame
		medidas.append({"mundo": _conexiones(m), "ui": _conexiones(ui), "objetos": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
			"huerfanos": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
			"nodos": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), "recursos": int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))})
		print("  vuelta %d: %s" % [vuelta + 1, str(medidas[vuelta])])
	_comprobar(int(medidas[3]["mundo"]) == int(medidas[1]["mundo"]), "el mundo no gana conexiones entre la 2.ª y la 4.ª vuelta (%d -> %d)" % [medidas[1]["mundo"], medidas[3]["mundo"]])
	_comprobar(int(medidas[3]["ui"]) == int(medidas[1]["ui"]), "la interfaz de la carrera tampoco (%d -> %d)" % [medidas[1]["ui"], medidas[3]["ui"]])
	_comprobar(int(medidas[3]["huerfanos"]) <= int(medidas[1]["huerfanos"]), "sin nodos huérfanos nuevos (%d -> %d)" % [medidas[1]["huerfanos"], medidas[3]["huerfanos"]])
	## CONOCIDO (28-10-2026): cada partido abierto y cerrado deja ~400 objetos sin nodo ni recurso (los nodos y los recursos se quedan estables: 137 y 1100).
	## Posible ciclo de referencias en el partido; sin resolver. Esta barrera solo impide que empeore.
	var crece := (int(medidas[3]["objetos"]) - int(medidas[1]["objetos"])) / 2
	_comprobar(int(medidas[3]["nodos"]) == int(medidas[1]["nodos"]) and int(medidas[3]["recursos"]) == int(medidas[1]["recursos"]),
		"los nodos y los recursos vivos no crecen (%d y %d)" % [medidas[3]["nodos"], medidas[3]["recursos"]])
	_comprobar(crece <= 450, "los objetos sueltos crecen como mucho lo conocido por partido (+%d por vuelta, tope 450)" % crece)
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)
