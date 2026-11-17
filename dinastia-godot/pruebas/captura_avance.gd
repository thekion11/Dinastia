extends Node
## CAPTURAS de la pantalla «Avanzar» y de la pantalla de evento (avance por días). Varios clubes de países distintos:
##   herramientas/captura.sh res://pruebas/captura_avance.tscn --compat      (CLUBES=0,5,9 PAISES=CHI,ESP,JPN opcionales)
## Salida: pruebas/capturas/avance_<n>.png (la herramienta las pasa a JPG).

func _foto(nombre: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://pruebas/capturas/avance_%s.png" % nombre))

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://pruebas/capturas"))
	var paises := ["CHI", "ESP", "JPN"] if OS.get_environment("PAISES") == "" else Array(OS.get_environment("PAISES").split(","))
	var idx := [3, 0, 6] if OS.get_environment("CLUBES") == "" else Array(OS.get_environment("CLUBES").split(",")).map(func(x: String) -> int: return int(x))
	for k in paises.size():
		var m := Mundo.new()
		var ps: Array[String] = [String(paises[k])]
		m.generar(ps, 500 + k)
		m.tomar_el_mando(m.ligas[0].clubes[int(idx[k]) % m.ligas[0].clubes.size()].id)
		var raiz := Control.new()
		raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(raiz)
		var est := DisparadoresDia.nuevo_estado()
		var dia := -1
		var rodar := func() -> void: m.avanzar_semana()
		for parada in 3:   ## se salta hasta la tercera parada para que no sea siempre la misma
			var res := AvanceDias.avanzar(m, est, dia, rodar)
			if parada < 2:
				dia = -1 if not (res["plan"]["partido"] as Dictionary).is_empty() else int(res["dia"])
				if dia == -1:
					rodar.call()
				continue
			var unix0 := Calendario.unix_de(m.anio, m.semana, dia)
			var s := PantallaAvanzar.mostrar(raiz, m, unix0, res)
			await get_tree().create_timer(0.9).timeout
			await _foto("%s_corre" % paises[k])
			while s._fase == 0:
				await get_tree().create_timer(0.2).timeout
			await get_tree().create_timer(0.7).timeout
			await _foto("%s_rotulo" % paises[k])
			s.queue_free()
			var plan: Dictionary = res["plan"]
			if not (plan["pantallas"] as Array).is_empty() or not (plan["avisos"] as Dictionary).is_empty():
				pass
		var ev := {"tipo": "ultimatum", "clase": EventosDia.PANTALLA, "causa": {"id": "ultimatum", "datos": {"confianza": 18}}}
		var t := EventoDiaPantalla.mostrar(raiz, ev)
		await get_tree().create_timer(1.6).timeout
		await _foto("%s_evento" % paises[k])
		t.queue_free()
		raiz.queue_free()
	get_tree().quit()
