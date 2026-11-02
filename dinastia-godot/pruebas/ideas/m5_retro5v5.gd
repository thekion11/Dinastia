extends BaseIdea
## El minijuego retro 5v5 (soccer5v5, MIT; 01-11-2026): se abre encima con el resto en pausa, la CPU juega sola, y al cerrarlo el
## gestor se apaga y la pausa vuelve como estaba. Y nada de nombres reales en sus plantillas.

func _probar() -> void:
	_titulo("MINIJUEGO RETRO 5 CONTRA 5")
	_comprobar(GameManager.current_state == null, "el gestor del minijuego NO arranca solo con el juego")
	var r := Retro5v5.abrir(get_tree())
	for i in 20:
		await get_tree().process_frame
	_comprobar(get_tree().paused, "al abrirlo, el resto del juego queda en pausa")
	_comprobar(GameManager.current_state != null, "y su partido arranca (estado %s)" % (GameManager.current_state.name if GameManager.current_state != null else "ninguno"))
	var balon := r.find_child("Ball", true, false) as Node2D
	var p0 := balon.position if balon != null else Vector2.ZERO
	## El saque espera al jugador 1: «pase» (F) cuando llega al estado de saque.
	var pulsada := 0
	for i in 300:
		await get_tree().physics_frame
		if pulsada > 0:
			pulsada -= 1
			if pulsada == 0:
				Input.action_release("p1_pass")
		elif GameManager.current_state is GameStateKickoff:
			Input.action_press("p1_pass")   ## pulsada unos cuadros, como una persona (soltarla al cuadro siguiente no se ve)
			pulsada = 8
	_linea("estado al final: %s" % (GameManager.current_state.get_script().get_global_name() if GameManager.current_state != null else "ninguno"))
	_comprobar(balon != null and balon.position.distance_to(p0) > 1.0, "la CPU juega: el balón se mueve (%.1f px)" % (balon.position.distance_to(p0) if balon != null else 0.0))
	r.cerrar()
	for i in 3:
		await get_tree().process_frame
	_comprobar(not get_tree().paused and GameManager.current_state == null, "al cerrarlo (Esc), el gestor se apaga y la pausa vuelve como estaba")
	## La recreativa de la ciudad: el modelo de Kenney a 1,85 m y su punto de la E.
	var gs := GDScript.new()
	gs.source_code = "extends Node3D\nvar puntos_clic: Array = []\n"
	gs.reload()
	var falsa := Node3D.new()
	falsa.set_script(gs)
	add_child(falsa)
	var puesta := RecreativaRetro.montar(falsa, Vector3(3, 0, 4))
	var punto: Array = (falsa.get("puntos_clic") as Array).filter(func(pc: Dictionary) -> bool: return pc["k"] == RecreativaRetro.CLAVE)
	_comprobar(puesta and punto.size() == 1, "la recreativa se monta con su punto de la E (%s)" % str(punto.size()))
	falsa.queue_free()
	var datos := FileAccess.get_file_as_string("res://minijuegos/retro5v5/assets/json/squads.json")
	var reales := ["REAL MADRID", "MBAPPE", "BELLINGHAM", "HAALAND", "MESSI", "BARCELONA\"", "LIVERPOOL\"", "EDATHODIKA", "HABEEB"]
	_comprobar(reales.all(func(n: String) -> bool: return not datos.contains(n)), "sin clubes ni jugadores reales en sus plantillas")
