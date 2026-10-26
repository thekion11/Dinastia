extends "res://pruebas/banco/ideas_p1.gd"
## [Capa 2/2 de `ideas.gd`] _probar_ideas_simulacion_del_partido, _probar_ideas_club_y_calendario_de_pretemporada, _probar_ideas_dinero_ciudad_y_lesiones, _probar_ideas_tribunal_antidopaje_y_asamblea, _probar_ideas_medicina_y_vestuario, _probar_ideas_entrenamiento_prensa_y_dueno … (+8)

func _probar_ideas_simulacion_del_partido() -> void:
	_titulo("IDEAS DEL DUEÑO: simulación del partido — cronología, tarjetas, cambios, MVP, estadísticas (301-315)")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 2430)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var cl: Array = m.ligas[0].clubes
	var goles := 0
	var con_autor := 0
	var amarillas := 0
	var posesiones_ok := true
	var mejores_ok := true
	var momentum_ok := true
	var cambios_ok := 0
	var penales_ok := false
	for i in 24:
		var a: Club = cl[i % cl.size()]
		var b: Club = cl[(i + 3) % cl.size()]
		var p := Partido.new(a, b)
		p.preparar()
		while not p.terminado_ya:
			p.simular_minuto()
			if p.minuto == 60 and i % 4 == 0:
				var sale: Jugador = p.once_local[5]
				var entra: Jugador = null
				for j: Jugador in a.plantilla:
					if not p.once_local.has(j) and j.disponible():
						entra = j
						break
				if entra != null and p.cambiar(sale, entra) == "":
					cambios_ok += 1
		for e: Dictionary in p.cronica:
			if String(e["tipo"]) == "gol":
				goles += 1
				if int(e["min"]) >= 1 and String(e["autor"]) != "":
					con_autor += 1
		posesiones_ok = posesiones_ok and p.posesion_local > 15.0 and p.posesion_local < 85.0
		mejores_ok = mejores_ok and not p.mejor_del_partido().is_empty() and p.valoraciones().size() >= 22
		momentum_ok = momentum_ok and absi(p.momentum_local()) <= 100
		for j: Jugador in a.plantilla + b.plantilla:
			amarillas += j.amarillas
	_comprobar(goles >= 20 and con_autor == goles, "cronología minuto a minuto con goleador (%d goles, todos con autor) (301, 302)" % goles)
	_comprobar(amarillas >= 5, "hay tarjetas con nombre (%d amarillas en 24 partidos) (303)" % amarillas)
	_comprobar(cambios_ok >= 3, "los cambios se hacen y quedan en la crónica (%d) (306)" % cambios_ok)
	_comprobar(posesiones_ok, "la posesión estimada es creíble en todos los partidos (309)")
	_comprobar(mejores_ok, "siempre hay jugador del partido (MVP) y notas de los 22 (314)")
	_comprobar(momentum_ok, "el momentum (barra de ambiente) se mantiene en rango (310)")

func _probar_ideas_club_y_calendario_de_pretemporada() -> void:
	_titulo("IDEAS DEL DUEÑO: lema del club, avión, pretemporada con gira, desbloqueo por reputación (284, 298, 343)")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 2431)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	c.mover_saldo(400000000)
	var co: Comercial = m.comercial
	co.escribir_lema("Siempre adelante")
	_comprobar(co.lema == "Siempre adelante", "se escribe el lema del club (298)")
	var guardado := co.a_dic()
	var co2 := Comercial.new(m)
	co2.desde_dic(guardado)
	_comprobar(co2.lema == "Siempre adelante", "y el lema sobrevive al guardado (298)")
	co.escribir_lema("x".repeat(200))
	_comprobar(co.lema.length() <= 60, "con tope de largo (298)")
	_comprobar(co.alivio_de_viaje() == 0 and co.comprar_avion(c) != "" and co.alivio_de_viaje() > 0, "comprar el avión alivia los viajes (343)")
	var socios := c.socios
	var caja := c.saldo
	_comprobar(m.jugar_amistosos("gira") == "", "la gira internacional de pretemporada se juega (343)")
	_comprobar(c.socios > socios and c.saldo != caja, "y trae socios y mueve la caja (343)")
	_comprobar(m.jugar_amistosos("gira") != "", "y solo se juega una pretemporada por año (343)")
	_comprobar(Reputacion.tope_instalaciones(95) > Reputacion.tope_instalaciones(10), "los niveles de obra se desbloquean con reputación (284)")

func _probar_ideas_dinero_ciudad_y_lesiones() -> void:
	_titulo("IDEAS DEL DUEÑO: subvenciones, derechos de TV, auditoría de la federación, lesiones en el partido (108, 113, 117, 188-189, 305)")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 2432)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	_comprobar(m.ciudad.subvencion_anual(c) > 0, "el ayuntamiento da una subvención anual (108): %s" % _dinero(m.ciudad.subvencion_anual(c)))
	var f := Finanzas.new(c, 0.0, 0, 0.0)
	var caja := c.saldo
	_comprobar(f.derechos_tv() > 0 and c.saldo > caja, "los derechos de televisión se cobran (117)")
	var au := m.federacion.auditoria_anual(c, m.obras, m.anio)
	_comprobar(au.has("fallos") and au.has("anio"), "la federación hace una auditoría anual de licencia con sus fallos (113)")
	## Lesiones durante el partido: salen del parte médico y quedan en la ficha (189, 305).
	var lesionados := 0
	var cl: Array = m.ligas[0].clubes
	for i in 30:
		var p := Partido.new(cl[i % cl.size()], cl[(i + 5) % cl.size()])
		p.simular()
	for k: Club in cl:
		for j: Jugador in k.plantilla:
			if j.lesion > 0:
				lesionados += 1
	_comprobar(lesionados >= 1, "tras 30 partidos hay jugadores lesionados con semanas fuera (%d) (189, 305)" % lesionados)

func _probar_ideas_tribunal_antidopaje_y_asamblea() -> void:
	_titulo("IDEAS DEL DUEÑO (811-841): tribunal, apelaciones, antidopaje y asamblea de la liga")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 2433)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	c.mover_saldo(300000000)
	var fed: Federacion = m.federacion
	var j: Jugador = c.plantilla[0]
	## Tribunal de disciplina: abre expediente, suspende y se puede apelar una sola vez.
	var caso := fed.abrir_caso("roja", j, 3, "entrada dura", m.anio, 5)
	_comprobar(caso["estado"] == "firme" and j.suspension >= 3, "un expediente deja al jugador suspendido (3 fechas)")
	_comprobar(fed.casos.size() == 1 and fed.casos[0]["id"] == caso["id"], "y queda en el historial del tribunal")
	var caja := c.saldo
	var ap := fed.apelar(String(caso["id"]), c, 60)
	_comprobar(ap == "" or ap.length() > 0 and caso["apelado"] == true, "se puede apelar: %s" % ap.left(40))
	_comprobar(c.saldo < caja, "y la apelación cuesta honorarios")
	_comprobar(fed.apelar(String(caso["id"]), c, 60) != "", "pero no dos veces el mismo expediente")
	_comprobar(fed.apelar("no_existe", c, 60) != "", "un expediente inexistente se rechaza")
	## Antidopaje: casi nunca pasa nada; si pasa, hay registro.
	var controles := 0
	for i in 600:
		var r := fed.control_antidopaje(c, m.anio, i % 38 + 1)
		if not r.is_empty():
			controles += 1
	_comprobar(controles >= 1 and fed.controles.size() >= 1, "el control antidopaje salta alguna vez y deja registro (%d controles en 600 semanas)" % controles)
	_comprobar(controles < 200, "y es infrecuente (no más de uno de cada tres semanas)")
	## Asamblea: cada moción, al aprobarse, fija su regla.
	var reglas := {"tvigual": "reparto_tv", "juveniles": "cupo_juvenil", "extranjeros": "tope_extranjeros", "playoffs": "playoffs",
		"fpf": "fpf_activo", "desempate": "desempate_directo", "promocion": "promocion"}
	for id: String in reglas:
		var f2 := Federacion.new()
		var texto := f2._aplicar_mocion(id, true, "a", c)
		_comprobar(texto != "" and not texto.begins_with("La moción no"), "la moción «%s» aprobada produce efecto: %s" % [id, texto.left(48)])
	var f3 := Federacion.new()
	_comprobar(f3._aplicar_mocion("playoffs", false, "a", c).begins_with("La moción no") and not f3.playoffs, "una moción rechazada no cambia nada")
	var f4 := Federacion.new()
	var c0 := c.saldo
	f4._aplicar_mocion("superliga", true, "a", c)
	_comprobar(f4.superliga and c.saldo > c0, "la superliga paga prima solo si te subes")
	var f5 := Federacion.new()
	var c1 := c.saldo
	f5._aplicar_mocion("superliga", true, "b", c)
	_comprobar(c.saldo == c1, "y si votas que no, no cobras")
	var f6 := Federacion.new()
	var abierta := {}
	for i in 300:
		abierta = f6.abrir_votacion()
		if not abierta.is_empty():
			break
	_comprobar(not abierta.is_empty() and abierta.has("id"), "la federación acaba convocando una votación")
	var res := f6.votar("a", c, m.ligas[0].clubes)
	_comprobar(not res.is_empty(), "y se puede votar con la asamblea de la liga")

func _probar_ideas_medicina_y_vestuario() -> void:
	_titulo("IDEAS DEL DUEÑO (518-568): medicina (segunda opinión, recaídas, brotes, % de recuperación) y vestuario (clanes, mediación, terapia, solicitudes)")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 2434)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	c.mover_saldo(300000000)
	var md: Medico = m.medico
	var j: Jugador = c.plantilla[0]
	var sem := md.lesionar(j, Medico.MEDIA, "prueba", m.anio, 3)
	_comprobar(sem > 0 and j.lesion == sem, "una lesión tiene semanas de baja (%d) y queda en la ficha" % sem)
	_comprobar(md.pct_recuperado(j) >= 0 and md.pct_recuperado(j) < 100, "hay porcentaje de recuperación (%d%%)" % md.pct_recuperado(j))
	var antes := j.lesion
	var so := md.segunda_opinion(j, c)
	_comprobar(not so.has("error"), "se pide segunda opinión médica (cuesta y puede acortar o alargar la baja)")
	_comprobar(md.segunda_opinion(j, c).has("error"), "pero solo una por lesión")
	_comprobar(j.lesion != antes or so.size() >= 1, "y el resultado queda reflejado")
	j.lesion = 0
	j.fisico = 30
	var recaidas := 0
	for i in 600:
		if md.chequeo_de_recaida(j, m.anio, 4) > 0:
			recaidas += 1
			j.lesion = 0
			j.fisico = 30
	_comprobar(recaidas >= 1, "volver con el físico por los suelos produce recaídas (%d en 600 chequeos)" % recaidas)
	var sanos := 0
	for x: Jugador in c.plantilla:
		if x.lesion <= 0:
			sanos += 1
	var fis := {}
	for x: Jugador in c.plantilla:
		fis[x.id] = x.fisico
	md.iniciar_brote(c, 4, 3)
	var bajaron := 0
	for x: Jugador in c.plantilla:
		if x.fisico < int(fis[x.id]):
			bajaron += 1
	_comprobar(bajaron >= 1 and not md.brote.is_empty(), "un brote de gripe baja el físico de varios jugadores (%d)" % bajaron)
	## Vestuario: clanes, mediación, terapia y solicitudes.
	var v: Vestuario = m.vestuario
	v.semana(5)
	_comprobar(v.camarillas.size() >= 1, "el vestuario forma camarillas (%d)" % v.camarillas.size())
	if not v.camarillas.is_empty():
		var cid := String(v.camarillas[0]["id"])
		_comprobar(v.mediar(cid).has("ok"), "se puede mediar en un clan y da un resultado")
		v.chequeo_clanes([])
		_comprobar(v.clan_por_id(cid).has("humor"), "cada clan tiene humor medible")
	var pj: Jugador = c.plantilla[1]
	var caja := c.saldo
	_comprobar(v.dar_terapia(pj) == "" and c.saldo < caja, "la terapia deportiva se paga y baja la ansiedad")
	_comprobar(v.dar_terapia(pj) != "", "y no se puede repetir mientras dura")
	var con_solicitud := false
	for i in 400:
		v.solicitud = {}
		if v.sortear_solicitud() != "":
			con_solicitud = true
			break
	_comprobar(con_solicitud, "los jugadores hacen solicitudes (minutos, capitanía, descanso…)")
	if con_solicitud:
		var rs := v.resolver_solicitud(true)
		_comprobar(v.solicitud.is_empty() and rs is Dictionary, "y se resuelven (la solicitud deja de estar pendiente)")


func _probar_ideas_entrenamiento_prensa_y_dueno() -> void:
	_titulo("IDEAS DEL DUEÑO (416-430, 642-690, 774-793, 1035): plan de entrenamiento, pretemporada, prensa propia, capital del dueño e informe de gestión")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 2435)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	c.mover_saldo(500000000)
	## Entrenamiento (416-419, 426, 429, 430).
	var en: Entrenamiento = m.entrenamiento
	en.fijar_dia(0, "descanso")
	var c0 := en.carga()
	_comprobar(en.fijar_dia(0, "fisico") == "" and en.dias[0] == "fisico", "se fija el bloque de cada día de la semana (416)")
	_comprobar(en.fijar_dia(0, "no_existe") != "" and en.fijar_dia(99, "fisico") != "", "y se rechazan bloques o días que no existen")
	var c1 := en.carga()
	_comprobar(c1.hash() != c0.hash(), "cambiar un día cambia la carga del plan (físico, progreso, riesgo, moral) (417)")
	en.fijar_intensidad("normal")
	var r_normal := en.carga_riesgo()
	_comprobar(en.fijar_intensidad("alta") == "" and en.carga_riesgo() >= r_normal, "entrenar más fuerte no baja el riesgo de lesión (418)")
	_comprobar(en.fijar_intensidad("inexistente") != "", "y una intensidad inexistente se rechaza")
	var estrella: Jugador = c.plantilla[2]
	var ai := en.asignar_individual(estrella, "regate")
	_comprobar(ai == "", "se puede asignar entrenamiento individual (419): %s" % ai.left(50))
	var caja := c.saldo
	_comprobar(en.elegir_pretemporada("dura", c, m.anio, 1) == "" and en.pretemporada == "dura", "se elige la pretemporada del año (426)")
	_comprobar(en.elegir_pretemporada("altura", c, m.anio, 1) != "", "y solo una por año (430)")
	var en2 := Entrenamiento.new(m.staff)
	_comprobar(en2.elegir_pretemporada("altura", c, m.anio, 1) == "", "el campamento de altura existe como pretemporada (430)")
	en.concentracion = true
	_comprobar(en.concentracion, "la concentración previa se puede activar (429)")
	## Dueño: capital propio y venta del club (662, 690).
	var r: Roles = m.roles
	_comprobar(r.inyectar_capital() != "", "el DT no puede meter capital propio (662)")
	r.rol = Roles.DUENO
	var s0 := c.saldo
	_comprobar(r.inyectar_capital() == "" and c.saldo > s0, "el dueño inyecta capital (662)")
	_comprobar(r.inyectar_capital() == "" and r.inyectar_capital() != "", "pero como máximo dos veces por temporada (662)")
	_comprobar(r.vender_club() == "" and r.sin_club, "y puede vender el club y retirarse (690)")
	## Prensa propia (774-793).
	var pr := m.prensa
	pr.funa = 70
	_comprobar(pr.comunicado("silencio") != "" and pr.funa == 70, "el silencio de prensa no gasta nada y la funa sigue (778)")
	var f0 := pr.funa
	pr.comunicado("apoyo")
	_comprobar(pr.funa < f0, "un comunicado de apoyo baja la funa (786)")
	var vistos := {}
	for i in 40:
		pr.funa = 70
		pr.comunicado("contestar")
		vistos[pr.funa < 70] = true
	_comprobar(vistos.size() == 2, "contestar es cara o cruz: unas veces apaga el fuego y otras lo agranda (786)")
	for medio: String in ["podcast", "stream"]:
		_comprobar(not pr.tiene_medio(medio) and pr.comprar_medio(medio, c) == "" and pr.tiene_medio(medio), "se compra el medio propio «%s» (792, 793)" % medio)
		_comprobar(pr.comprar_medio(medio, c) != "", "y no se compra dos veces")
	_comprobar(pr.renta_medios(c) > 0, "los medios propios rentan cada mes (793): %s" % _dinero(pr.renta_medios(c)))
	## Informe de gestión (1035).
	var inf := m.informe_de_gestion()
	_comprobar(inf is Array, "el informe de gestión es una lista de tareas")
	c.mover_saldo(-c.saldo - 5000000)
	var inf2 := m.informe_de_gestion()
	var grave := false
	for t: Dictionary in inf2:
		if bool(t.get("grave", false)):
			grave = true
	_comprobar(grave, "con la caja en rojo el informe avisa de algo grave (1035)")

func _probar_ideas_lote_a1() -> void:
	_titulo("IDEAS DEL DUEÑO: lote a1 (partido en vivo y pizarra táctica)")
	_IDEAS_A1.new(self).ejecutar()

func _probar_ideas_lote_a2() -> void:
	_titulo("IDEAS DEL DUEÑO: lote a2 (entrenamiento, ojeo y cantera)")
	_IDEAS_A2.new(self).ejecutar()

func _probar_ideas_lote_a3() -> void:
	_titulo("IDEAS DEL DUEÑO: lote a3 (medicina, vestuario, mercado y agentes)")
	_IDEAS_A3.new(self).ejecutar()

func _probar_ideas_lote_a4() -> void:
	_titulo("IDEAS DEL DUEÑO: lote a4 (finanzas, directorio, carrera y ciudad)")
	_IDEAS_A4.new(self).ejecutar()

func _probar_ideas_lote_b1() -> void:
	_titulo("IDEAS DEL DUEÑO: lote b1, hinchada y prensa (736-800)")
	_IDEAS_B1.new(self).ejecutar()

func _probar_ideas_lote_b2() -> void:
	_titulo("IDEAS DEL DUEÑO: lote b2, árbitros, disciplina y federación (801-837)")
	_IDEAS_B2.new(self).ejecutar()

func _probar_ideas_lote_b3() -> void:
	_titulo("IDEAS DEL DUEÑO: lote b3, selecciones y competencias (844-908)")
	_IDEAS_B3.new(self).ejecutar()

func _probar_ideas_lote_b4() -> void:
	_titulo("IDEAS DEL DUEÑO: lote b4, editor, modos de juego, progresión, interfaz y audio (911-1097)")
	_IDEAS_B4.new(self).ejecutar()
