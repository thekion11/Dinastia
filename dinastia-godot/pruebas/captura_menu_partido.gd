extends Node
## CAPTURAS del menú del partido (cada pestaña) con clubes de países distintos:  herramientas/captura.sh res://pruebas/captura_menu_partido.tscn --compat
## Salida: pruebas/capturas/menu_partido_<país>_<pestaña>.png (la herramienta las pasa a JPG).

func _foto(nombre: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://pruebas/capturas/menu_partido_%s.png" % nombre))
	print("captura ", nombre, " ", Time.get_ticks_msec())

## Uniforme: hasta que los dos futbolistas 3D estén dibujados; Estadio y Cámara: hasta que llegue la foto del estadio (tope 3 min sin GPU).
func _esperar_vistas(menu: MenuPartido, tab: String) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 180000:
		var falta := false
		if tab == "uniforme":
			for r in menu._cuerpo.find_children("*", "SubViewportContainer", true, false):
				falta = falta or (r.get("hecho") == false)
		elif tab in ["estadio", "camara"]:
			for mi in menu._cuerpo.find_children("*", "MiniaturaMenu", true, false):
				falta = falta or (mi.get("foto") == null and not mi.is_queued_for_deletion())
		if not falta:
			break
		await get_tree().process_frame
	if tab in ["uniforme", "estadio", "camara"]:
		print("MEDIDA %s: vistas 3D listas en %d ms" % [tab, Time.get_ticks_msec() - t0])
	await get_tree().create_timer(0.3).timeout

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://pruebas/capturas"))
	var paises := ["ARG", "ENG", "JPN"]
	for k in paises.size():
		var m := Mundo.new()
		var ps: Array[String] = [String(paises[k])]
		m.generar(ps, 900 + k)
		var liga: Liga = m.ligas[0]
		m.tomar_el_mando(liga.clubes[2 + k].id)
		var par: Array = liga.calendario[0][0] if k == 0 else liga.calendario[0][1]
		var mio := m.mi_club()
		var rival: Club = liga.clubes[(2 + k + 5) % liga.clubes.size()]
		var p := Partido.new(mio, rival)
		var clima := Clima.del_partido(mio.pais, m.semana, m.anio, mio.id + rival.id)
		var t0 := Time.get_ticks_usec()
		var mem0 := Performance.get_monitor(Performance.MEMORY_STATIC)
		var menu := MenuPartido.mostrar(self, p, mio, liga, clima)
		await get_tree().process_frame
		print("MEDIDA %s: abrir el menú hasta el primer cuadro %.0f ms" % [paises[k], (Time.get_ticks_usec() - t0) / 1000.0])
		for f in menu.find_children("*", "SubViewportContainer", true, false):
			while f.has_signal("listo") and not f.hecho:
				await get_tree().process_frame
		print("MEDIDA %s: retratos 3D listos a los %.0f ms · memoria +%.1f MB" % [paises[k], (Time.get_ticks_usec() - t0) / 1000.0, (Performance.get_monitor(Performance.MEMORY_STATIC) - mem0) / 1048576.0])
		await get_tree().create_timer(0.5).timeout
		for tab in (["previa", "uniforme", "estadio", "saque", "plan", "opciones", "camara"] if k == 0 else ["previa", "uniforme", "estadio", "camara"]):
			if tab == "previa":
				menu.cerrar_panel()
			else:
				menu._abrir(tab)
			await get_tree().create_timer(1.3 if tab == "saque" else 0.3).timeout
			await _esperar_vistas(menu, tab)
			await _foto("%s_%s" % [paises[k], tab])
		menu.queue_free()
		if k == 1:
			await _pausa(p)
	get_tree().quit()

## La pausa del partido (sobre un césped de relleno: la escena del estadio es demasiado pesada para esta captura).
func _pausa(p: Partido) -> void:
	var fondo := ColorRect.new()
	fondo.color = Color("1f6a3a")
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var capa := Control.new()
	capa.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(capa)
	capa.add_child(fondo)
	p.minuto = 63
	p.goles_local = 2
	p.goles_visita = 1
	MenuPausaPartido.abrir(capa, p)
	await get_tree().create_timer(0.4).timeout
	await _foto("pausa")
	capa.queue_free()
