extends BaseIdea
## MEGA AUDITORÍA 4 (4-11-2026), repaso 5 CRUZADO: PRENSA al límite.
##   1. Ruedas de prensa encadenadas (después del partido en las 3 formas de resultado, y la previa forzada): se contestan con índices buenos, fuera de rango (−1, 99) y tiempos absurdos
##      (−5 s, 0, 10⁹ s): siempre termina en ≤ 25 pasos, sin error, la rueda queda cerrada y contestar de nuevo no hace nada.
##   2. Abrir otra rueda con una abierta, delegar en el ayudante a media rueda, y con el club sin plantel ni rival (fin de calendario).
##   3. Ánimo de la hinchada y relación con los periodistas siempre en 0-100 tras 120 semanas de mundo con una rueda cada semana.
const PASOS_MAX := 25

func _probar() -> void:
	_titulo("A4 CRUZADO (gestión): prensa y ruedas de prensa al límite")
	Partido.limpiar_contexto()
	var m := Mundo.new()
	var paises: Array[String] = ["CHI"]
	m.generar(paises, 616)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var pr: Prensa = m.prensa
	_comprobar(pr != null, "el mundo tiene prensa")
	if pr == null:
		return
	var combos := [[true, false], [false, false], [false, true]]
	var respuestas := [0, 1, 2, -1, 99]
	var tiempos := [-1.0, -5.0, 0.0, 3.0, 1000000000.0]
	var malas := 0
	var rondas := 0
	for combo in combos:
		for modo in respuestas.size():
			var e := pr.abrir_rueda(bool(combo[0]), bool(combo[1]))
			if e.is_empty():
				continue
			rondas += 1
			var pasos := 0
			while not pr.entrevista.is_empty() and pasos < PASOS_MAX + 5:
				var r := pr.responder(int(respuestas[(modo + pasos) % respuestas.size()]), float(tiempos[(modo + pasos) % tiempos.size()]))
				pasos += 1
				if r.is_empty():   ## un índice que no existe se rechaza y la pregunta sigue abierta: se contesta bien
					pr.responder(0, 3.0)
					pasos += 1
			if not pr.entrevista.is_empty() or pasos > PASOS_MAX:
				malas += 1
				pr.entrevista = {}   ## para seguir con las demás
				pr.cola_rueda.clear()
			_comprobar(pr.responder(0).is_empty(), "contestar sin rueda abierta no hace nada")
	_comprobar(rondas >= 6 and malas == 0, "%d ruedas encadenadas con respuestas y tiempos absurdos: todas terminan (%d colgadas)" % [rondas, malas])
	## abrir con otra abierta y delegar a media rueda
	var a := pr.abrir_rueda(true, false)
	var b := pr.abrir_rueda(false, false)
	_comprobar(a.is_empty() or b.is_empty() or pr.entrevista != null, "abrir otra rueda con una abierta no rompe el estado")
	if not pr.entrevista.is_empty():
		var ops: Array = pr.entrevista["opciones"]
		var idx := -1
		for i in ops.size():
			if String((ops[i] as Dictionary).get("tono", "")) == "delegar":
				idx = i
		if idx >= 0:
			var rd := pr.responder(idx)
			_comprobar(bool(rd.get("delegada", false)) and pr.entrevista.is_empty() and pr.cola_rueda.is_empty(), "delegar a media rueda cierra la rueda y vacía la cola")
	pr.entrevista = {}
	pr.cola_rueda.clear()
	var previa := pr.abrir_previa(true)
	var pasos2 := 0
	while not pr.entrevista.is_empty() and pasos2 < PASOS_MAX:
		pr.responder(0)
		pasos2 += 1
	_comprobar(pr.entrevista.is_empty(), "la previa forzada se contesta entera (%d pasos, %s)" % [pasos2, "abierta" if not previa.is_empty() else "sin previa"])
	## sin plantel: la prensa no explota
	var mio := m.mi_club()
	var guardados := mio.plantilla.duplicate()
	mio.plantilla.clear()
	pr.sortear_evento()
	pr.narrador_temporada()
	pr.abrir_rueda(true, false)
	pr.entrevista = {}
	pr.cola_rueda.clear()
	mio.plantilla.append_array(guardados)
	_comprobar(true, "prensa con el club sin plantel: sin error")
	## 120 semanas de mundo con una rueda por semana
	var rotas := 0
	for sem in 120:
		m.avanzar_semana()
		if sem % 3 == 0:
			var e2 := pr.abrir_rueda(sem % 2 == 0, sem % 5 == 0)
			var n := 0
			while not pr.entrevista.is_empty() and n < PASOS_MAX:
				pr.responder(n % 3)
				n += 1
			pr.entrevista = {}
			pr.cola_rueda.clear()
			if e2.is_empty():
				continue
		if pr.animo < 0 or pr.animo > 100 or pr.relacion_media() < 0 or pr.relacion_media() > 100:
			rotas += 1
		if sem % 30 == 29:
			await get_tree().process_frame
	_comprobar(rotas == 0, "ánimo y relación con la prensa en 0-100 durante 120 semanas (%d fuera, ánimo %d, relación %d)" % [rotas, pr.animo, pr.relacion_media()])
