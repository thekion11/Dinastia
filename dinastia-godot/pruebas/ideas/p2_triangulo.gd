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
	## (17-11) El triángulo 3D (`MarcadorJugador`, «TrianguloControlado») se cambió por uno 2D pequeño que pinta `NombresTV` (HUD de TV):
	## el 3D salía pixelado en el móvil y tapaba el centro. Se comprueba lo mismo que antes sobre el indicador nuevo.
	var nt := pj.find_child("NombresTV", true, false) as NombresTV
	_comprobar(nt != null and nt.triangulo, "el partido monta el triángulo (2D, en `NombresTV`)")
	_comprobar(pj.find_child("TrianguloControlado", true, false) == null, "y ya no el triángulo 3D grande")
	if nt != null:
		var yo: Dictionary = pj.motor.usuario
		var cam := get_viewport().get_camera_3d()
		_comprobar(not yo.is_empty() and _marca_yo(nt) != null, "con un jugador controlado, el triángulo se ve")
		if not yo.is_empty() and cam != null and _marca_yo(nt) != null:
			var m: Dictionary = _marca_yo(nt)
			var pie := cam.unproject_position((yo["node"] as Node3D).global_position)
			var cabeza: Vector2 = m["cabeza"]
			_comprobar((m["pie"] as Vector2).distance_to(pie) < 2.0 and cabeza.y < (m["pie"] as Vector2).y,
				"sobre su cabeza: pies a %.1f px de los del jugador, cabeza %.0f px más arriba" % [(m["pie"] as Vector2).distance_to(pie), (m["pie"] as Vector2).y - cabeza.y])
			var otro: Dictionary = {}
			for p: Dictionary in pj.motor.jugadores:
				if p != yo and bool(p["es_local"]) == bool(yo["es_local"]) and not bool(p["por"]):
					otro = p
					break
			pj.motor.usuario = otro
			for i in 4:
				await get_tree().physics_frame
				await get_tree().process_frame
			var m2: Variant = _marca_yo(nt)
			var pie2 := cam.unproject_position((otro["node"] as Node3D).global_position)
			_comprobar(m2 != null and ((m2 as Dictionary)["pie"] as Vector2).distance_to(pie2) < 2.0, "al cambiar de jugador, el triángulo lo sigue")
			pj.motor.usuario = {}
			for i in 3:
				await get_tree().physics_frame
				await get_tree().process_frame
			_comprobar(_marca_yo(nt) == null, "sin jugador controlado, se esconde")
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

## La marca del jugador que manejas (la que lleva el triángulo) en lo que pinta `NombresTV`, o null.
func _marca_yo(nt: NombresTV) -> Variant:
	for m: Dictionary in nt._marcas:
		if bool(m.get("yo", false)):
			return m
	return null
