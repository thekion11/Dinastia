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
	## (17-11) El triángulo ya no es una malla 3D (`MarcadorJugador`, pixelada en el móvil): lo dibuja `NombresTV` en 2D sobre la cabeza del que llevas.
	_comprobar(pj.find_child("TrianguloControlado", true, false) == null, "ya no hay triángulo 3D (no se duplica con el 2D)")
	var nombres := pj.find_child("NombresTV", true, false) as NombresTV
	_comprobar(nombres != null and nombres.triangulo, "el partido monta los nombres y el triángulo en 2D")
	if nombres != null:
		var yo: Dictionary = pj.motor.usuario
		_comprobar(not yo.is_empty() and _marca_yo(nombres), "con un jugador controlado, se marca el suyo (triángulo sobre su cabeza)")
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
			_comprobar(_marca_yo(nombres), "al cambiar de jugador, el triángulo sigue marcando al nuevo")
			pj.motor.usuario = {}
			for i in 3:
				await get_tree().physics_frame
				await get_tree().process_frame
			_comprobar(not _marca_yo(nombres), "sin jugador controlado, se esconde")
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

## ¿Alguna de las marcas que dibuja `NombresTV` es la del jugador que llevas (`yo`)?
func _marca_yo(n: NombresTV) -> bool:
	for m: Dictionary in n._marcas:
		if bool(m.get("yo", false)):
			return true
	return false
