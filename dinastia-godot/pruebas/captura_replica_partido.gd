extends Node
## CAPTURA de «Jugar momento» de verdad: el partido jugable abierto desde un minuto de un partido ya jugado (PAIS=ARG herramientas/captura.sh res://pruebas/captura_replica_partido.tscn --compat).

func _frames(n := 6) -> void:
	for i in n:
		await get_tree().process_frame

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://pruebas/capturas"))
	var pais := OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "ARG"
	var m := Mundo.new()
	var ps: Array[String] = [pais]
	m.generar(ps, 91)
	m.tomar_el_mando(m.ligas[0].clubes[5].id)
	PedidoPartida.mundo_pregenerado = m
	PedidoPartida.modo_elegido = "dt"
	PedidoPartida.dt_nombre_elegido = "Prueba"
	PedidoPartida.dificultad_elegida = "normal"
	PedidoPartida.aplicado_a = 0
	JornadaEventos._abierto = true
	var pr: Principal = load("res://escenas/principal.tscn").instantiate()
	add_child(pr)
	await _frames(8)
	for t in get_tree().root.find_children("*", "", true, false):
		if t is Tutorial:
			(t as Tutorial)._terminar(false)
	var liga: Liga = m.liga_de(m.mi_club())
	var rival: Club = liga.clubes[0] if liga.clubes[0] != m.mi_club() else liga.clubes[1]
	var orig := Partido.new(m.mi_club(), rival)
	orig.preparar()
	while not orig.terminado_ya:
		orig.simular_minuto()
	var minuto := 30
	for e: Dictionary in orig.cronica:
		if String(e.get("tipo", "")) == "gol":
			minuto = int(e["min"])
			break
	ReplicaPartido.abrir(pr, orig, minuto)
	await get_tree().create_timer(9.0).timeout
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://pruebas/capturas/replica_momento.png"))
	print("MINUTO ", minuto, " vivo: ", pr.find_children("*", "PartidoVivo", true, false).size())
	get_tree().quit()
