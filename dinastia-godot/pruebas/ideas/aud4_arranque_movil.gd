extends BaseIdea
## A4-INT · EL ARRANQUE EN FRÍO en el móvil: hay pantalla de arranque con el logo del juego (no el de Godot ni negro) mientras cargan los autoloads y el primer menú, y el menú inicial (2400×1080 a 400 ppp, MÍNIMA)
## sale con botones ≥ 7 mm y nada fuera de la pantalla (salvo las filas que se deslizan). Mide el tiempo de montar la escena de inicio (referencia, sin dibujar).
func _probar() -> void:
	_titulo("AUDITORÍA 4 · ARRANQUE EN FRÍO EN EL MÓVIL")
	_respaldar_user()
	var imagen := String(ProjectSettings.get_setting("application/boot_splash/image", ""))
	_comprobar(imagen != "" and ResourceLoader.exists(imagen), "la pantalla de arranque lleva el logo del juego (%s)" % imagen)
	_comprobar(bool(ProjectSettings.get_setting("application/boot_splash/show_image", true)), "y se enseña (show_image)")
	var fondo: Color = ProjectSettings.get_setting("application/boot_splash/bg_color", Color.BLACK)
	_comprobar(fondo != Color.BLACK, "con un fondo propio, no negro puro (%s)" % fondo.to_html(false))
	AyudaMovil.poner(Vector2i(2400, 1080), get_window())
	var calidad_antes := Calidad.elegida
	Calidad.elegida = Calidad.MINIMO
	var t0 := Time.get_ticks_msec()
	var esc: Node = load("res://escenas/inicio.tscn").instantiate()
	add_child(esc)
	for i in 8:
		await get_tree().process_frame
	var ms := Time.get_ticks_msec() - t0
	_linea("      montar el menú inicial hasta el 8.º fotograma: %d ms (sin dibujar, con scripts sin precompilar)" % ms)
	_comprobar(ms < 15000, "el menú inicial está listo en %d ms (< 15 s)" % ms)
	var alto := EscalaMovil.alto_toque(esc)
	var g := AyudaMovil.problemas(esc, alto).filter(func(x: String) -> bool: return x.begins_with("toque") or x.begins_with("botón") or x.begins_with("texto fuera") or x.begins_with("texto por debajo"))
	_comprobar(g.is_empty(), "menú inicial en el móvil: %d problemas %s" % [g.size(), str(g.slice(0, 4))])
	esc.queue_free()
	await get_tree().process_frame
	AyudaMovil.quitar(get_window())
	Calidad.elegida = calidad_antes
	_restaurar_user()
