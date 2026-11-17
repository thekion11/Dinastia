extends Node
## CAPTURAS del menú del partido (cada pestaña) con clubes de países distintos:  herramientas/captura.sh res://pruebas/captura_menu_partido.tscn --compat
## Salida: pruebas/capturas/menu_partido_<país>_<pestaña>.png (la herramienta las pasa a JPG).

func _foto(nombre: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://pruebas/capturas/menu_partido_%s.png" % nombre))

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
		var menu := MenuPartido.mostrar(self, p, mio, liga, clima)
		await get_tree().create_timer(0.8).timeout
		for tab in (["previa", "uniforme", "estadio", "plan", "opciones", "camara"] if k == 0 else ["previa", "uniforme"]):
			(menu._botones[tab] as Button).button_pressed = true
			menu._abrir(tab)
			await get_tree().create_timer(0.3).timeout
			await _foto("%s_%s" % [paises[k], tab])
		menu.queue_free()
	get_tree().quit()
