extends Control
## EL INFORME DEL RIVAL (17-10-2026): media temporada jugada para que haya
## tabla, racha y goleadores; foto en pruebas/capturas/informe_rival.png (JPG
## con herramientas/captura.sh). Sin pantalla comprueba solo los datos.

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	for i in 8:
		m.ligas[0].jugar_jornada()
	var par := m.proximo_partido()
	var p := Partido.new(par[0], par[1])
	var rival: Club = p.visita if p.local == m.mi_club() else p.local
	var d := InformeRival.datos(rival, m.mi_club(), m.liga_de(rival))
	var ok := int(d["puesto"]) > 0 and (d["racha"] as Array).size() == 5 and (d["mejores"] as Array).size() == 3 and not (d["consejos"] as Array).is_empty()
	print("INFORME puesto %d racha %s mejores %d consejos %s -> %s" % [int(d["puesto"]), str(d["racha"]), (d["mejores"] as Array).size(), str(d["consejos"]), "ok" if ok else "FALLO"])
	if DisplayServer.get_name() != "headless":
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		InformeRival.mostrar(self, p, m.mi_club(), m.liga_de(rival), m)
		for i in 30:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/informe_rival.png")
	get_tree().quit(0 if ok else 1)
