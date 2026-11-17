extends Node
## CAPTURA del menú central con el botón «Avanzar» nuevo, las campanas rojas y (con DIA_PARTIDO=1) «Jugar / Saltar partido»:
##   PAIS=ESP herramientas/captura.sh res://pruebas/captura_menu_avance.tscn --compat      Salida: pruebas/capturas/menu_avance_<n>.png

func _frames(n := 6) -> void:
	for i in n:
		await get_tree().process_frame

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://pruebas/capturas"))
	var pais := OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "ESP"
	var m := Mundo.new()
	var ps: Array[String] = [pais]
	m.generar(ps, 88)
	m.tomar_el_mando(m.ligas[0].clubes[4].id)
	PedidoPartida.mundo_pregenerado = m
	PedidoPartida.modo_elegido = "dt"
	PedidoPartida.dt_nombre_elegido = "Prueba"
	PedidoPartida.dificultad_elegida = "normal"
	PedidoPartida.aplicado_a = 0
	AvanceDiasUI.sin_pantalla = true
	JornadaEventos._abierto = true   ## sin el diálogo de la presidencia al empezar la temporada
	var pr: Principal = load("res://escenas/principal.tscn").instantiate()
	add_child(pr)
	await _frames(8)
	for t in get_tree().root.find_children("*", "", true, false):
		if t is Tutorial:
			(t as Tutorial)._terminar(false)
	CampanasMenu.zonas = {"mercado": 2, "prensa": 1}
	pr._refrescar()
	await _frames(10)
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://pruebas/capturas/menu_avance_campanas.png"))
	CampanasMenu.limpiar()
	var dias: AvanceDiasUI = pr._avance.dias()
	for i in 40:
		if dias.partido_hoy():
			break
		await dias.pulsar()
		await _frames(2)
	pr._refrescar()
	await _frames(10)
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://pruebas/capturas/menu_avance_dia_partido.png"))
	get_tree().quit()
