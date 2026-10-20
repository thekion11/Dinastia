extends Node
## EL FLUJO DE LA CARRERA DE JUGADOR (29-9-2026): crear, jugar un partido (simulado
## a toda velocidad), cerrar la semana, guardar y volver a cargar.
##   godot --headless --path . res://pruebas/prueba_carrera_flujo.tscn
func _ready() -> void:
	CarreraJugadorUI.mundo = null
	var ui: CarreraJugadorUI = load("res://escenas/carrera_jugador.tscn").instantiate()
	add_child(ui)
	ui._crear()
	var m := CarreraJugadorUI.mundo
	var sem := m.semana
	ui._jugar_partido()
	var pj: PartidoJugable = ui.find_children("*", "PartidoJugable", true, false)[0]
	## 20-10: el cambio con cartel y palmada (forzado: el DT siempre te cambia).
	pj.motor.prob_cambio_extra = 1.0
	pj._simular_resto()
	var escena := pj.find_children("EscenaCambio*", "EscenaCambio", true, false)
	var cartel := pj.find_children("CuartoArbitro*", "CuartoArbitro", true, false)
	print("CAMBIO sustituido=%s escena=%d cartel=%d sale_visible=%s %s" % [str(pj.motor.usuario_sustituido), escena.size(), cartel.size(),
		str(escena.size() > 0 and (escena[0] as EscenaCambio)._sale.visible),
		"OK" if not pj.motor.usuario_sustituido or (escena.size() == 1 and cartel.size() == 1) else "FALLO"])
	var res := pj.resultado()
	pj._cerrar()
	print("FLUJO semana %d -> %d  pj %d  partidos_jugables %d  resultado %d-%d  nota %.1f  guardado %s" % [sem, m.semana, int(ui.carrera.stats_temp["pj"]), ui.carrera.partidos_jugables, int(res["goles_local"]), int(res["goles_visita"]), float(res["nota"]), str(FileAccess.file_exists("user://partidas/carrera_jugador.json") or Partida.listar().size() > 0)])
	var m2 := Partida.cargar("carrera_jugador")
	print("CARGA carrera=%s jugador=%s" % [str(m2 != null and m2.carrera_jugador != null), m2.carrera_jugador.jugador(m2).nombre if m2 != null and m2.carrera_jugador != null else "-"])
	get_tree().quit()
