extends Node
## CAPTURA del menú central (pestaña elegida con PESTANA=0/1/2) con un club de un país distinto en cada corrida:
##   PAIS=ESP CLUB=4 PESTANA=0 NOMBRE=antes_esp herramientas/captura.sh res://pruebas/captura_menu_central.tscn
## Salida: pruebas/capturas/menu_central_<NOMBRE>.png (la herramienta la pasa a JPG).

func _frames(n := 6) -> void:
	for i in n:
		await get_tree().process_frame

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://pruebas/capturas"))
	var pais := OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "ESP"
	var idx := int(OS.get_environment("CLUB")) if OS.get_environment("CLUB") != "" else 4
	var m := Mundo.new()
	var ps: Array[String] = [pais]
	m.generar(ps, 88 + idx)
	m.tomar_el_mando(m.ligas[0].clubes[idx % m.ligas[0].clubes.size()].id)
	for _i in (int(OS.get_environment("JORNADAS")) if OS.get_environment("JORNADAS") != "" else 0):   ## con partidos jugados, para ver el último resultado
		m.avanzar_semana()
	PedidoPartida.mundo_pregenerado = m
	PedidoPartida.modo_elegido = "dt"
	PedidoPartida.dt_nombre_elegido = "Prueba"
	PedidoPartida.dificultad_elegida = "normal"
	PedidoPartida.aplicado_a = 0
	AvanceDiasUI.sin_pantalla = true
	JornadaEventos._abierto = true
	var t0 := Time.get_ticks_msec()
	var pr: Principal = load("res://escenas/principal.tscn").instantiate()
	add_child(pr)
	await _frames(10)
	for t in get_tree().root.find_children("*", "", true, false):
		if t is Tutorial:
			(t as Tutorial)._terminar(false)
	if OS.get_environment("PESTANA") != "":
		TableroInicio.pestana = int(OS.get_environment("PESTANA"))
		pr._refrescar()
	await _frames(12)
	print("APERTURA_MS ", Time.get_ticks_msec() - t0)
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://pruebas/capturas/menu_central_%s.png" % OS.get_environment("NOMBRE")))
	get_tree().quit()
