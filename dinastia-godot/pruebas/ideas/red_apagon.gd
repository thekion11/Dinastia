extends BaseIdea
## red · EL APAGÓN DE TORMENTA (`EventoApagon`, subsuelo, 27-10-2026; antes sin prueba, catálogo M-403). Con
## tormenta a las 20:00 salta el disyuntor y dos sectores distintos se quedan sin luz; reconectar sin rearmar no
## vale; rearmar y reconectar desde abajo lo arregla; si nadie baja, la cuadrilla repone la luz a las 08:00; y
## se guarda y se carga.

func _probar() -> void:
	_titulo("RED: el apagón de tormenta")
	var m := RedesCiudad.new(4242)
	var e := m.evento
	## Sin tormenta no salta; con tormenta, a las 20:00, salta en alguna de 40 noches (PROBABILIDAD 0,6).
	for i in 40:
		m.horas += 24
		e.tick(m, EventoApagon.HORA_INICIO, "despejado")
	_comprobar(not e.activo, "sin tormenta no salta")
	for i in 40:
		if e.activo:
			break
		m.horas += 24
		e.tick(m, EventoApagon.HORA_INICIO, "tormenta")
	_comprobar(e.activo and e.sectores.size() == 2 and e.sectores[0] != e.sectores[1], "con tormenta a las 20:00 salta en dos sectores distintos (%s)" % str(e.sectores))
	var sin_luz := true
	for s in e.sectores:
		sin_luz = sin_luz and m.esta_averiado("luz", s)
	_comprobar(sin_luz, "esos sectores quedan con la luz averiada")
	_comprobar(e.reconectar(m) == "falta_rearmar", "reconectar sin rearmar el disyuntor no vale")
	_comprobar(e.rearmar() == "ok" and e.rearmar() == "ya", "rearmar: la primera vez sí, la segunda «ya»")
	var sectores := e.sectores.duplicate()
	_comprobar(e.reconectar(m) == "ok" and not e.activo and e.resueltos == 1, "rearmado y reconectado, se arregla y cuenta como tuyo")
	var con_luz := true
	for s in sectores:
		con_luz = con_luz and not m.esta_averiado("luz", s)
	_comprobar(con_luz, "y vuelve la luz a esos sectores")
	## Otro apagón que nadie arregla: la cuadrilla a las 08:00.
	for i in 40:
		if e.activo:
			break
		m.horas += 24
		e.tick(m, EventoApagon.HORA_INICIO, "tormenta")
	e.tick(m, EventoApagon.HORA_CUADRILLA, "tormenta")
	_comprobar(not e.activo and e.por_cuadrilla == 1, "si nadie baja, la cuadrilla repone la luz a las 08:00")
	var e2 := EventoApagon.new()
	e2.desde_dic(e.a_dic())
	_comprobar(e2.resueltos == 1 and e2.por_cuadrilla == 1 and not e2.activo, "se guarda y se carga")
