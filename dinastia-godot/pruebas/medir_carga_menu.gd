extends Node
## LA PANTALLA DE CARGA DEL MENÚ, EN LA PRÁCTICA (10-11-2026): llama a `CargaMenu.cambiar` como la entrada («Nuevo juego» → menú) y mide, desde la llamada: cuándo se ha DIBUJADO la pantalla de carga (lo que
## ve el jugador al pulsar), cuánto dura y cuándo desaparece; guarda capturas (FOTO_DIR) con la carga en pantalla y con el menú ya montado.
##   FOTO_DIR=/tmp/x PAIS=ESP CLUB=5 herramientas/hw_modesto.sh res://pruebas/medir_carga_menu.tscn
class Vigia extends Node:
	var t0 := 0
	var n := 0
	var t_pintada := 0
	var carga_vista := false
	var frames_con_carga := 0
	var t_ultimo := 0
	var hueco_max := 0
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		RenderingServer.frame_post_draw.connect(_dibujado)
	func _dibujado() -> void:
		n += 1
		var capa := get_tree().root.get_node_or_null("CargaMenu")
		if capa != null:
			frames_con_carga += 1
			var ahora := Time.get_ticks_msec()
			if t_ultimo > 0:
				hueco_max = maxi(hueco_max, ahora - t_ultimo)
				if ahora - t_ultimo > 400:
					print("HUECO %d ms, terminado en t=%d ms (avance del montaje %.2f, escena %s)" % [ahora - t_ultimo, ahora - t0, PedidoPartida.montaje_avance, str(get_tree().current_scene.name) if get_tree().current_scene != null else "-"])
			t_ultimo = ahora
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
			print("CARGA_MENU pantalla de carga dibujada a los %d ms de pulsar · desaparece a los %d ms · %d fotogramas dibujados con la carga puesta · mayor hueco entre fotogramas %d ms · escena actual: %s" % [t_pintada, Time.get_ticks_msec() - t0, frames_con_carga, hueco_max, str(get_tree().current_scene.name)])
			get_tree().quit()

func _ready() -> void:
	Calidad.elegida = Calidad.nivel_de_argumentos(Calidad.NIVEL_DEFECTO)
	var m := Mundo.new()
	var pais := OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "CHI"
	m.generar([pais], 4711)
	m.tomar_el_mando(m.ligas[0].clubes[int(OS.get_environment("CLUB")) % m.ligas[0].clubes.size()].id)
	PedidoPartida.mundo_pregenerado = m
	PantallaCarga.club = m.mi_club()
	if OS.get_environment("SIN_PRECARGA") == "":   ## como en el juego: el jugador pasó un rato en la portada y la entrada, y `Precarga` ya compiló los scripts del menú
		Precarga.empezar(get_tree())
		while not Precarga.menu_listo:
			await get_tree().process_frame
	var v := Vigia.new()
	get_tree().root.add_child.call_deferred(v)
	await get_tree().process_frame
	await get_tree().process_frame
	v.t0 = Time.get_ticks_msec()
	CargaMenu.cambiar(get_tree(), "res://escenas/principal.tscn")
