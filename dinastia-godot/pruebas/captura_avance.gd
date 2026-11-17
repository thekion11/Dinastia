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
	await _sinteticos()
	get_tree().quit()

## Eventos que NO son partido, con su arte (res falso como el de `AvanceDias.avanzar`): ultimátum, jugador del mes, golpe de caja, mercado, cantera y fecha del país.
func _sinteticos() -> void:
	var m := Mundo.new()
	var ps: Array[String] = ["ESP", "ARG"]
	m.generar(ps, 77)
	m.tomar_el_mando(m.ligas[0].clubes[4].id)
	var j: Jugador = m.mi_club().plantilla[2]
	j.goles = 6
	j.asistencias = 2
	j.notas = [7.8, 8.1, 7.6] as Array[float]
	var lista := [
		{"tipo": "ultimatum", "clase": "pantalla", "origen": "disparador", "causa": {"id": "ultimatum", "datos": {"confianza": 18}}},
		{"tipo": "jugador_del_mes", "clase": "pantalla", "origen": "disparador", "es_mio": true, "nombre": Nombres.visible(j.nombre), "jugador_id": j.id, "club": m.mi_club().nombre, "causa": {"id": "jugador_del_mes", "datos": {}}},
		{"tipo": "golpe_caja", "clase": "aviso", "origen": "disparador", "titulo": "Multa de la federación", "texto": "La federación te multa por incidentes en la grada.", "causa": {"id": "golpe_caja", "datos": {"importe": 500000, "semanas": 2}}},
		{"tipo": "mercado_cierra", "clase": "aviso", "origen": "calendario", "icono": "🔒", "etiqueta": "Mercado", "texto": "Cierra el mercado de fichajes", "causa": {}},
		{"tipo": "evento_cantera", "clase": "aviso", "origen": "disparador", "texto": "Un chico de la academia quiere dejar el fútbol.", "causa": {"id": "evento_cantera", "datos": {}}},
		{"tipo": "fecha_pais", "subtipo": "independencia", "clase": "pantalla", "origen": "pais", "pais": "ESP", "nombre": "Día de la independencia", "texto": "Se celebra la independencia del país.", "causa": {}}]
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(raiz)
	for ev: Dictionary in lista:
		var unix0 := Calendario.unix_de(m.anio, m.semana, 0)
		var pas: Array = []
		for d in 4:
			pas.append({"dia": d + 1, "mes": 1, "dia_mes": 1})
		var res := {"dia": 4, "eventos": [ev], "plan": EventosDia.plan_de_parada([ev]), "pasados": pas, "fin": false}
		var s := PantallaAvanzar.mostrar(raiz, m, unix0, res)
		while s._fase == 0:
			await get_tree().create_timer(0.2).timeout
		await get_tree().create_timer(0.8).timeout
		await _foto("sint_%s" % String(ev["tipo"]))
		s.queue_free()
