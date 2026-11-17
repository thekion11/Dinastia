extends Node
## CAPTURA (17-11): el menú del partido sobre el menú principal REAL: «Plan de juego» abre la pantalla de Táctica del juego a pantalla completa y, al
## cerrarla, vuelve la previa; las demás pestañas, a pantalla completa.  herramientas/captura.sh res://pruebas/captura_menu_partido_plan.tscn
var _p: Principal

## El diálogo de la directiva de la semana 1 (capa 58) taparía la captura: se esconde (solo en esta captura).
func _quitar_eventos() -> void:
	for h in get_tree().root.find_children("*", "Control", true, false):
		var g := String((h.get_script() as Script).resource_path) if h.get_script() != null else ""
		if (g.contains("rueda_prensa") or g.contains("evento_dialogo") or g.contains("sala_prensa")) and (h as Control).visible:
			print("escondo ", g)
			(h as Control).visible = false
	for cl in get_tree().root.find_children("*", "CanvasLayer", true, false):
		var guion := ""
		for h in cl.get_children():
			if h.get_script() != null:
				guion += String((h.get_script() as Script).resource_path) + " "
		print("capa ", (cl as CanvasLayer).layer, " ", guion)
		if (cl as CanvasLayer).layer == 58 or guion.contains("rueda") or guion.contains("evento"):
			(cl as CanvasLayer).visible = false

func _foto(nombre: String) -> void:
	_quitar_eventos()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://pruebas/capturas/menu_partido_%s.png" % nombre))
	print("captura ", nombre)

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://pruebas/capturas"))
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	for i in 5:
		await get_tree().process_frame
	var m := Mundo.new()
	m.generar(["BRA"], 5150)
	m.tomar_el_mando(m.ligas[0].clubes[4].id)
	for k in 4:
		m.avanzar_semana()
	_p.set("mundo", m)
	_p.call("_refrescar")
	for i in 20:
		await get_tree().process_frame
	for n in get_tree().root.find_children("*", "Control", true, false):   ## el diálogo de la directiva u otro evento que salga al empezar
		if n.get_script() != null and String((n.get_script() as Script).resource_path).ends_with("evento_dialogo.gd"):
			n.queue_free()
	await get_tree().process_frame
	var mio := m.mi_club()
	var rival: Club = m.ligas[0].clubes[9]
	var p := Partido.new(rival, mio)
	var menu: Control = load("res://ui/partido_menu/menu_partido.gd").mostrar(_p, p, mio, m.liga_de(rival), Clima.del_partido(rival.pais, m.semana, m.anio, rival.id + mio.id))
	await get_tree().create_timer(1.0).timeout
	menu.call("_abrir", "opciones")
	await get_tree().create_timer(0.4).timeout
	await _foto("BRA_opciones_completa")
	menu.call("_abrir", "plan")
	await get_tree().create_timer(1.5).timeout
	print("previa visible mientras la táctica: ", menu.visible)
	await _foto("BRA_plan_tactica")
	var pm = _p._menu_lateral.pantalla_abierta
	if pm != null:
		pm.cerrar()
	await get_tree().create_timer(1.0).timeout
	print("previa visible al cerrar la táctica: ", menu.visible)
	await _foto("BRA_vuelta_previa")
	get_tree().quit()
