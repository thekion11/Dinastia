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
		var vistas := 0
		for parada in 40:   ## se avanza hasta la 3.ª parada, o hasta un partido en el primer club (para ver los escudos)
			var res := AvanceDias.avanzar(m, est, dia, rodar)
			var es_partido := not (res["plan"]["partido"] as Dictionary).is_empty()
			var ver := es_partido if k == 0 else (vistas >= 2 or es_partido)
			if not ver:
				vistas += 1
				dia = int(res["dia"])
				continue
			var unix0 := Calendario.unix_de(m.anio, m.semana, dia)
			var s := PantallaAvanzar.mostrar(raiz, m, unix0, res)
			await get_tree().create_timer(0.9).timeout
			await _foto("%s_corre" % paises[k])
			while s._fase == 0:
				await get_tree().create_timer(0.2).timeout
			await get_tree().create_timer(0.9).timeout
			await _foto("%s_rotulo" % paises[k])
			s.queue_free()
			break
		raiz.queue_free()
	get_tree().quit()
