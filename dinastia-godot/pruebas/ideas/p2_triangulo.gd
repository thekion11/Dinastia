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
		await get_tree().process_frame
	## (18-11) Desde el HUD de TV en 2D (`0b9f2a5f`) el triángulo ya no es un nodo 3D: lo dibuja `NombresTV` (con `triangulo = true`)
	## sobre la cabeza del que manejas. Aquí se mira ese HUD: sus marcas (`_marcas`) y que el 3D ya no se monta.
	_comprobar(pj.find_child("TrianguloControlado", true, false) == null, "el triángulo 3D ya no se monta (lo dibuja el HUD en 2D)")
	var nombres := pj.get_node_or_null("NombresTV") as NombresTV
	_comprobar(nombres != null and nombres.triangulo, "el partido monta los nombres 2D con el triángulo")
	if nombres != null:
		var yo: Dictionary = pj.motor.usuario
		_comprobar(not yo.is_empty() and _yo(nombres) != {}, "con un jugador controlado, el triángulo se dibuja")
		var pie0: Vector2 = _yo(nombres).get("pie", Vector2.ZERO)
		if not yo.is_empty():
			var otro: Dictionary = {}
			for p: Dictionary in pj.motor.jugadores:
				if p != yo and bool(p["es_local"]) == bool(yo["es_local"]) and not bool(p["por"]):
					otro = p
					break
			pj.motor.usuario = otro
			for i in 4:
				await get_tree().physics_frame
				await get_tree().process_frame
			var m2: Dictionary = _yo(nombres)
			_comprobar(m2 != {} and (m2["pie"] as Vector2).distance_to(pie0) > 1.0, "al cambiar de jugador, el triángulo lo sigue")
			pj.motor.usuario = {}
			for i in 3:
				await get_tree().physics_frame
				await get_tree().process_frame
			_comprobar(_yo(nombres) == {}, "sin jugador controlado, se esconde")
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

## La marca del que manejas en el HUD 2D (vacía si no hay).
func _yo(n: NombresTV) -> Dictionary:
	for m: Dictionary in n._marcas:
		if bool(m["yo"]):
			return m
	return {}
