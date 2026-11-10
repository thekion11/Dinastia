extends Node
## LA PANTALLA DE CARGA DEL MENÚ, EN LA PRÁCTICA (10-11-2026): llama a `CargaMenu.cambiar` como la entrada («Nuevo juego» → menú) y mide, desde la llamada: cuándo se ha DIBUJADO la pantalla de carga (lo que
## ve el jugador al pulsar), cuánto dura y cuándo desaparece; guarda capturas (FOTO_DIR) con la carga en pantalla y con el menú ya montado.
##   FOTO_DIR=/tmp/x PAIS=ESP CLUB=5 herramientas/hw_modesto.sh res://pruebas/medir_carga_menu.tscn
class Vigia extends Node:
	var t0 := 0
	var n := 0
	var t_pintada := 0
	var carga_vista := false
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		RenderingServer.frame_post_draw.connect(_dibujado)
	func _dibujado() -> void:
		n += 1
		var capa := get_tree().root.get_node_or_null("CargaMenu")
		if capa != null and not carga_vista:
			carga_vista = true
			t_pintada = Time.get_ticks_msec() - t0
			if OS.get_environment("FOTO_DIR") != "":
				get_viewport().get_texture().get_image().save_jpg(OS.get_environment("FOTO_DIR") + "/carga_1_pintada.jpg", 0.85)
	func _process(_d: float) -> void:
		var capa := get_tree().root.get_node_or_null("CargaMenu")
		if carga_vista and capa == null:
			if OS.get_environment("FOTO_DIR") != "":
				get_viewport().get_texture().get_image().save_jpg(OS.get_environment("FOTO_DIR") + "/carga_3_menu.jpg", 0.85)
			print("CARGA_MENU pantalla de carga dibujada a los %d ms de pulsar · desaparece a los %d ms · escena actual: %s" % [t_pintada, Time.get_ticks_msec() - t0, str(get_tree().current_scene.name)])
			get_tree().quit()

func _ready() -> void:
	Calidad.elegida = Calidad.nivel_de_argumentos(Calidad.NIVEL_DEFECTO)
	var m := Mundo.new()
	var pais := OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "CHI"
	m.generar([pais], 4711)
	m.tomar_el_mando(m.ligas[0].clubes[int(OS.get_environment("CLUB")) % m.ligas[0].clubes.size()].id)
	PedidoPartida.mundo_pregenerado = m
	PantallaCarga.club = m.mi_club()
	var v := Vigia.new()
	get_tree().root.add_child.call_deferred(v)
	await get_tree().process_frame
	await get_tree().process_frame
	v.t0 = Time.get_ticks_msec()
	CargaMenu.cambiar(get_tree(), "res://escenas/principal.tscn")
