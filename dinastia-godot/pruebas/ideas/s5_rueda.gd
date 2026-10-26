extends BaseIdea
## LA RUEDA DE PRENSA QUE LEE EL MOMENTO (26-10-2026, sesión 5). Detrás de la pregunta de siempre, hasta
## tres más sacadas del contexto (el porqué del partido, la racha, el último fichaje, el próximo rival); la
## duración varía con lo que hay en juego; y se puede mandar al ayudante, con su coste.

func _probar() -> void:
	var m := _mundo(6161)
	var yo := m.mi_club()
	var pr := m.prensa
	Partido.limpiar_contexto()
	Partido.ctx_club_id = yo.id
	Partido.ctx_anio = m.anio
	Partido.ctx_semana = m.semana
	_titulo("RUEDA: el porqué del partido se vuelve pregunta")
	Partido.ultimo_mio = {}
	Partido.ultimas_causas = {"anio": m.anio, "semana": m.semana, "causas": [
		{"clave": "momentum", "signo": -1, "peso": 1.2, "texto": "…"}]}
	var p := PrensaContexto._del_porque(m, false, false)
	_comprobar(String(p.get("tema", "")) == "porque" and String(p["pregunta"]).contains(Idiomas.t("Hubo un tramo en que el rival les encerró en su área. ¿Qué falló ahí?")),
		"tras perder con el rival encima: %s" % String(p.get("pregunta", "—")))
	_comprobar((p.get("opciones", []) as Array).size() == 3, "con sus tres respuestas")
	Partido.ultimas_causas["semana"] = m.semana - 1
	_comprobar(PrensaContexto._del_porque(m, false, false).is_empty(), "el porqué de otra semana no se pregunta")
	## Y de verdad: un partido simulado deja sus causas para la rueda.
	var pj := Partido.new(yo, m.ligas[0].clubes[1])
	pj.simular()
	_comprobar(int(Partido.ultimas_causas.get("semana", -1)) == m.semana and (Partido.ultimas_causas.get("causas", []) as Array).size() == 3,
		"un partido de tu club deja sus tres causas para la rueda")
	_titulo("RUEDA: la racha, el fichaje y el próximo rival")
	_comprobar(PrensaContexto.racha_larga(["V", "D", "D", "D", "D"]) == -4 and PrensaContexto.racha_larga(["D", "V", "V", "V"]) == 3
		and PrensaContexto.racha_larga(["V", "E"]) == 0, "la racha se cuenta desde el final")
	var liga := m.liga_de(yo)
	var otro: Club = liga.clubes[2]
	for k in 4:
		liga.historial.append([{"local": yo, "visita": otro, "gl": 0, "gv": 1}])
	var rq := PrensaContexto._de_racha(PrensaContexto.racha_de(m, yo))
	_comprobar(String(rq.get("pregunta", "")).contains("4"), "cuatro derrotas seguidas: %s" % String(rq.get("pregunta", "—")))
	var antes := pr.fichajes_preguntados
	m.mercado.fichajes_temporada.append({"nombre": "Nuevo Fichaje", "entra": true, "otro": "libre", "monto": 0, "ovr": 75})
	var fq := PrensaContexto._del_fichaje(pr, m)
	_comprobar(String(fq.get("pregunta", "")).contains("Nuevo Fichaje"), "el fichaje que acaba de llegar: %s" % String(fq.get("pregunta", "—")))
	_comprobar(PrensaContexto._del_fichaje(pr, m).is_empty() and pr.fichajes_preguntados == antes + 1, "y no se pregunta dos veces por el mismo")
	var lider: Club = liga.tabla()[0]["club"]
	if lider == yo:
		lider = liga.tabla()[1]["club"]
	var rv := PrensaContexto._del_rival(m, yo, lider)
	_comprobar(not rv.is_empty(), "el próximo rival de arriba de la tabla: %s" % String(rv.get("pregunta", "—")))
	_titulo("RUEDA: la duración varía")
	_comprobar(PrensaContexto.cuantas(4, ["V", "E"], false, 3) == 0 and PrensaContexto.cuantas(4, ["V", "E"], false, 4) == 1
		and PrensaContexto.cuantas(4, ["D", "D", "D", "D"], true, 3) == 3, "un día tranquilo, corta o de una; en crisis y con mucho en juego, larga")
	var estado: int = Azar._rng.state
	PrensaContexto.preguntas_extra(pr, m, yo, false, false, 7)
	_comprobar(Azar._rng.state == estado, "leer el contexto no gasta ni un número del azar de la partida")
	_titulo("RUEDA: las preguntas se encadenan en la misma sala")
	Partido.ultimas_causas = {"anio": m.anio, "semana": m.semana, "causas": [{"clave": "momentum", "signo": -1, "peso": 1.2, "texto": "…"}]}
	m.mercado.fichajes_temporada.append({"nombre": "Otro Refuerzo", "entra": true, "otro": "libre", "monto": 0, "ovr": 70})
	pr.entrevista = {}
	pr.vocero = {}
	var e := pr.abrir_rueda(false, false)
	var total := int(e.get("total", 0))
	_comprobar(total >= 2 and total == 1 + pr.cola_rueda.size(), "con racha, fichaje y porqué la rueda tiene %d preguntas" % total)
	var ultima: Dictionary = (e["opciones"] as Array)[(e["opciones"] as Array).size() - 1]
	_comprobar(String(ultima.get("tono", "")) == "delegar", "y la primera trae la opción de mandar al ayudante")
	var respondidas := 0
	var vistas := {}
	var guarda := 0
	while pr.hay_rueda() and guarda < 12:
		guarda += 1
		vistas[int(pr.entrevista.get("numero", 0))] = true
		var r := pr.responder(0)
		respondidas += 1
		if pr.hay_rueda():
			_comprobar(bool(r.get("sigue", false)), "mientras queden preguntas, la sala sigue abierta (%d/%d)" % [int(pr.entrevista.get("numero", 0)), total])
	_comprobar(not pr.hay_rueda() and vistas.size() == total and respondidas >= total, "se responden las %d (%d respuestas con repreguntas) y se cierra" % [total, respondidas])
	_comprobar(not pr.titular_pendiente.is_empty(), "y deja la portada de mañana")
	_titulo("RUEDA: mandar al ayudante")
	pr.entrevista = {}
	var rel_antes := pr.relacion_con("ibarra")
	var conf_antes := m.directiva.confianza
	var rep_antes := m.roles.reputacion.valor("mediatico")
	e = pr.abrir_rueda(true, false)
	var i_del := (e["opciones"] as Array).size() - 1
	var rd := pr.responder(i_del)
	_comprobar(bool(rd.get("delegada", false)) and not pr.hay_rueda() and pr.cola_rueda.is_empty(), "habla el ayudante y la rueda entera se acaba")
	_comprobar(pr.relacion_con("ibarra") == clampi(rel_antes + PrensaContexto.DELEGAR_RELACION, 0, 100), "la sala lo anota (relación %d → %d)" % [rel_antes, pr.relacion_con("ibarra")])
	_comprobar(m.directiva.confianza < conf_antes or conf_antes <= 0, "la directiva también (confianza %d → %d)" % [conf_antes, m.directiva.confianza])
	_comprobar(String(pr.titular_pendiente.get("t", "")) == Idiomas.t("El DT no dio la cara: habló su ayudante"), "y la portada de mañana lo cuenta")
	_comprobar(m.roles.reputacion.valor("mediatico") < rep_antes, "y tu fama mediática baja (%d → %d)" % [rep_antes, m.roles.reputacion.valor("mediatico")])
	_titulo("RUEDA: con portavoz no hay ayudante que mandar")
	pr.entrevista = {}
	pr.vocero = {"nombre": "Portavoz"}
	e = pr.abrir_rueda(true, false)
	var hay_del := false
	for o: Dictionary in e["opciones"]:
		hay_del = hay_del or String(o.get("tono", "")) == "delegar"
	_comprobar(not hay_del, "con portavoz, la opción no sale (ya habla otro por ti)")
	pr.vocero = {}
	pr.entrevista = {}
	_comprobar("cola_rueda" in Partida._CAMPOS_PRENSA and "fichajes_preguntados" in Partida._CAMPOS_PRENSA, "la cola y los fichajes preguntados se guardan con la partida")
	_previa(m, yo, pr)

## LA PREVIA (26-10): la rueda ANTES del partido, corta y delegable.
func _previa(m: Mundo, yo: Club, pr: Prensa) -> void:
	_titulo("PREVIA: la rueda antes del partido")
	Partido.ultimo_mio = {}
	pr.entrevista = {}
	pr.vocero = {}
	var par := m.proximo_partido()
	var rival: Club = par[1] if par[0] == yo else par[0]
	var e := pr.abrir_previa(true)
	_comprobar(bool(e.get("previa", false)) and String(e["pregunta"]).contains(Nombres.visible(rival.nombre)), "se abre con el próximo rival: %s" % String(e.get("pregunta", "—")))
	_comprobar(pr.competicion_rueda == "previa" and pr.rival_rueda == rival.id, "y deja al plató el contexto «previa» con el rival (para la pared de los dos escudos)")
	var ops: Array = e["opciones"]
	_comprobar(String((ops[ops.size() - 1] as Dictionary).get("tono", "")) == "delegar", "se puede mandar al ayudante")
	_comprobar(int(e.get("total", 0)) <= 2, "y es corta: %d pregunta(s)" % int(e.get("total", 0)))
	var guarda := 0
	while pr.hay_rueda() and guarda < 6:
		guarda += 1
		pr.responder(0)
	_comprobar(not pr.hay_rueda(), "se responde y se cierra")
	## Con muchas bajas, la segunda pregunta es por el once.
	for j: Jugador in yo.plantilla.slice(0, 4):
		j.lesion = 3
	m.liga_de(yo).historial.clear()
	e = pr.abrir_previa(true)
	var temas: Array = [String(e.get("tema", ""))]
	for c: Dictionary in pr.cola_rueda:
		temas.append(String(c.get("tema", "")))
	_comprobar("previa_bajas" in temas, "con %d bajas pregunta por el once (%s)" % [PrensaContexto.bajas(yo), str(temas)])
	_comprobar(PrensaContexto.toca_previa(m, yo, rival, 1), "con 4 bajas, toca previa aunque sea un día tranquilo")
	pr.entrevista = {}
	pr.cola_rueda.clear()
	## El cierre de la semana: si no hubo rueda tras el resultado, sale la previa; y el azar gastado es el
	## mismo (una tirada) haya o no previa.
	## (Desde 1: con 0, `Azar.sembrar` siembra al azar.)
	var semilla := 1
	for s in range(1, 200):
		Azar.sembrar(s)
		if not Azar.suerte(0.5):
			semilla = s
			break
	Azar.sembrar(semilla)
	Azar.suerte(0.5)
	var estado_esperado: int = Azar._rng.state
	Azar.sembrar(semilla)
	pr.rueda_tras_resultado(true, false)
	_comprobar(pr.hay_rueda() and bool(pr.entrevista.get("previa", false)), "sin rueda tras el resultado, el cierre de semana abre la previa")
	_comprobar(Azar._rng.state == estado_esperado, "y gasta la misma tirada de azar que antes (ni una más)")
	pr.entrevista = {}
	pr.cola_rueda.clear()
	for j: Jugador in yo.plantilla.slice(0, 4):
		j.lesion = 0
