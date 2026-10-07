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
	pj._simular_resto()
	var res := pj.resultado()
	pj._cerrar()
	print("FLUJO semana %d -> %d  pj %d  partidos_jugables %d  resultado %d-%d  nota %.1f  guardado %s" % [sem, m.semana, int(ui.carrera.stats_temp["pj"]), ui.carrera.partidos_jugables, int(res["goles_local"]), int(res["goles_visita"]), float(res["nota"]), str(FileAccess.file_exists("user://partidas/carrera_jugador.json") or Partida.listar().size() > 0)])
	var m2 := Partida.cargar("carrera_jugador")
	print("CARGA carrera=%s jugador=%s" % [str(m2 != null and m2.carrera_jugador != null), m2.carrera_jugador.jugador(m2).nombre if m2 != null and m2.carrera_jugador != null else "-"])
	get_tree().quit()
