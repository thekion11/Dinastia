extends BaseIdea
## P2 (3-11): el triángulo sobre el jugador controlado en `PartidoJugable`. Aparece sobre la cabeza de quien llevas, te sigue al cambiar de jugador
## y se esconde si no controlas a nadie. Captura opcional con CAPTURA=ruta.jpg (necesita renderizador).

func _ready() -> void:
	await get_tree().process_frame
	_titulo("P2 · TRIÁNGULO SOBRE EL JUGADOR CONTROLADO")
	PartidoJugable.con_ceremonia = false
	CarreraJugadorUI.mundo = null
	var ui: CarreraJugadorUI = load("res://escenas/carrera_jugador.tscn").instantiate()
	add_child(ui)
	ui._crear()
	var m: Mundo = CarreraJugadorUI.mundo
	var club := ui.carrera.club(m)
	var par := ui._partido_de_la_semana(club)
	var pj := PartidoJugable.abrir(ui, m, ui.carrera, par[0], par[1], 240.0)
	for i in 12:
		await get_tree().physics_frame
	var marca := pj.find_child("TrianguloControlado", true, false) as MeshInstance3D
	_comprobar(marca != null, "el partido monta el triángulo")
	if marca != null:
		var yo: Dictionary = pj.motor.usuario
		_comprobar(not yo.is_empty() and marca.visible, "con un jugador controlado, el triángulo se ve")
		if not yo.is_empty():
			var cabeza := (yo["node"] as Node3D).position + Vector3(0, 0, 0)
			var d := marca.position - cabeza
			_comprobar(d.y > 2.6 and d.y < 4.2 and Vector2(d.x, d.z).length() < 0.05, "flota sobre su cabeza (la punta a %.2f m de sus pies)" % d.y)
			var otro: Dictionary = {}
			for p: Dictionary in pj.motor.jugadores:
				if p != yo and bool(p["es_local"]) == bool(yo["es_local"]) and not bool(p["por"]):
					otro = p
					break
			pj.motor.usuario = otro
			for i in 4:
				await get_tree().physics_frame
			var c2 := (otro["node"] as Node3D).position + Vector3(0, 0, 0)
			_comprobar(Vector2(marca.position.x - c2.x, marca.position.z - c2.z).length() < 0.05, "al cambiar de jugador, el triángulo lo sigue")
			pj.motor.usuario = {}
			for i in 3:
				await get_tree().physics_frame
			_comprobar(not marca.visible, "sin jugador controlado, se esconde")
			pj.motor.usuario = yo
			for i in 3:
				await get_tree().physics_frame
	var ruta := OS.get_environment("CAPTURA")
	if ruta != "" and DisplayServer.get_name() != "headless":
		for i in 30:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_jpg(ruta, 0.9)
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)
