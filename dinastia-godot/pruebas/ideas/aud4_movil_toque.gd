extends BaseIdea
## A4-INT · en el móvil (2400×1080 a 400 ppp) todo botón mide ≥ 7 mm (~49 px del lienzo): los del tema, los de estilo propio y los que nacen después. En PC no cambia nada.
func _probar() -> void:
	_titulo("AUDITORÍA 4 · toques de 7 mm en el móvil")
	get_window().size = Vector2i(2400, 1080)
	get_window().content_scale_factor = EscalaMovil.ZOOM_MOVIL
	PantallaMovil.dpi_forzado = 400.0
	PantallaMovil.ventana_forzada = Vector2i(2400, 1080)
	var p: Node = load("res://escenas/principal.tscn").instantiate()
	add_child(p)
	for i in 10:
		await get_tree().process_frame
	var alto := EscalaMovil.alto_toque(p)
	_comprobar(alto >= 40.0 and alto <= EscalaMovil.MAX_TOQUE, "alto de toque en el lienzo: %.1f px" % alto)
	var b := Button.new()
	b.text = "x"
	b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())   ## estilo propio: no pasa por el tema
	p.add_child(b)
	_comprobar(b.custom_minimum_size.y >= alto, "un botón nuevo con estilo propio se estira a %.1f (tiene %.1f)" % [alto, b.custom_minimum_size.y])
	var cortos := 0
	for n in p.find_children("*", "Button", true, false):
		if (n as Button).get_combined_minimum_size().y < alto - 1.0:
			cortos += 1
	_comprobar(cortos == 0, "botones existentes más bajos de 7 mm: %d" % cortos)
	var t := Theme.new()
	var sb := StyleBoxFlat.new()
	t.set_stylebox("normal", "Button", sb)
	EscalaMovil.ampliar_toque(t, 0.0)
	_comprobar(sb.content_margin_top < 0.0, "sin móvil (alto 0) el tema no cambia")
	PantallaMovil.dpi_forzado = 0.0
	PantallaMovil.ventana_forzada = Vector2i.ZERO
	_comprobar(EscalaMovil.alto_toque(p) == 0.0, "en PC no hay alto de toque")
	get_window().content_scale_factor = 1.0
	p.queue_free()
