extends BaseIdea
## SUSPENSIÓN POR ACUMULACIÓN DE AMARILLAS (27-10-2026, fila 811) y la sanción de partido que se cumple de verdad.

func _probar() -> void:
	_titulo("DISCIPLINA · 5 AMARILLAS = UN PARTIDO FUERA")
	var j := Jugador.new()
	j.nombre = "Prueba"
	var saltos := []
	for k in 11:
		j.amarillas += 1
		if Disciplina.acumula(j):
			saltos.append(j.amarillas)
	_comprobar(saltos == [5, 10], "se sanciona en la 5.ª y en la 10.ª amarilla (%s)" % str(saltos))
	var j2 := Jugador.new()
	j2.amarillas = 4
	_comprobar(not Disciplina.acumula(j2) and j2.suspension == 0, "con 4 no pasa nada")
	_comprobar(Disciplina.frase(j).contains("Prueba"), "la frase nombra al jugador")
	## --- Cumplir de verdad: cae en la semana N, se pierde el partido de la N+1 y vuelve en la N+2 ---
	var m := Mundo.new()
	m.generar(["CHI"], 31)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var mio: Club = m.ligas[0].clubes[1]   ## un club de la IA: el once del DT es manual y no se revalida aquí
	var estrella: Jugador = null
	for x: Jugador in mio.plantilla:
		if x.pos != "POR" and (estrella == null or x.ovr > estrella.ovr):
			estrella = x
	m.avanzar_semana()
	estrella.amarillas = 4
	estrella.amarillas += 1
	_comprobar(Disciplina.acumula(estrella) and estrella.suspension == 1, "la 5.ª amarilla lo sanciona")
	m.avanzar_semana()   ## su partido de esta semana ya estaba jugado a efectos de la tarjeta: la sanción NO se descuenta todavía
	_comprobar(estrella.suspension == 1, "la sanción que cae esta semana sigue en pie al acabar la jornada (%d)" % estrella.suspension)
	_comprobar(not mio.once().has(estrella) and not mio.disponibles().has(estrella), "y mientras tanto no entra en el once de su club")
	m.avanzar_semana()   ## la jornada siguiente: la cumple
	_comprobar(estrella.suspension == 0, "se cumple en la jornada siguiente")
	_comprobar(mio.disponibles().has(estrella) or estrella.lesion > 0, "y después vuelve a estar disponible")
	## Una roja deja de ser un trámite: antes la jornada que la veía la descontaba enseguida.
	var rival: Jugador = mio.plantilla[3]
	Disciplina.sanciona(rival)
	m.avanzar_semana()
	_comprobar(rival.suspension == 1, "la roja de esta semana también se cumple en la siguiente (%d)" % rival.suspension)
	m.avanzar_semana()
	_comprobar(rival.suspension == 0, "y luego se acaba")
	## Se guarda con la partida.
	var x := Jugador.new()
	x.susp_semana = 202607
	x.suspension = 1
	var y := Partida._dic_a_jugador(Partida._jugador_a_dic(x))
	_comprobar(y.suspension == 1 and y.susp_semana == 202607, "la semana de la sanción se guarda y se carga")
