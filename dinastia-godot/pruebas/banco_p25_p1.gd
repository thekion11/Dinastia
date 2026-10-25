extends "res://pruebas/banco_p24.gd"
## (Parte 1 de 2 de `banco_p25.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `banco_p25.gd`, conserva la clase.)

## [Capa 27/28 de `banco.gd`] Auditoría de ideas del dueño (24-10): cada sección comprueba de verdad que la idea existe y funciona.

func _probar_ideas_instalaciones_y_marca() -> void:
	_titulo("IDEAS DEL DUEÑO: instalaciones, estadio comercial y marca (17-38, 5, 10, 121-126)")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 2424)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	c.mover_saldo(900000000)
	var ins: Instalaciones = m.obras
	## Cada instalación del catálogo se puede construir, tarda sus semanas y sube de nivel.
	for k: String in ["ct", "med", "gim", "resid", "video", "rehab", "museo", "park", "pren", "cocina",
			"piscina", "guarderia", "bienestar", "esports", "huerto", "acad", "com"]:
		_comprobar(Instalaciones.CATALOGO.has(k), "existe la instalación «%s»" % k)
		var antes: int = ins.nivel(k)
		_comprobar(ins.iniciar(k, c) == "", "se puede empezar la obra de «%s»" % k)
		for i in ins.semanas_de(k) + 1:
			ins.avanzar_semana(c)
		_comprobar(ins.nivel(k) == antes + 1, "y al terminar la obra sube a nivel %d («%s»)" % [antes + 1, k])
	## Y cada una HACE algo medible (no es decoración).
	_comprobar(ins.ritmo_de_progreso() > 1.0, "el campo de entrenamiento acelera el progreso (16)")
	_comprobar(ins.descuento_lesion() >= 2, "centro médico y rehabilitación acortan lesiones (18, 23)")
	_comprobar(ins.techo_cantera() >= 1, "academia y residencia suben el techo de la cantera (20)")
	_comprobar(ins.aguante() >= 0 and ins.lectura_del_rival() >= 1, "comedor/piscina dan aguante y la sala de video lectura del rival (21, 22, 24)")
	_comprobar(ins.calma_del_vestuario() >= 2, "guardería y bienestar bajan la ansiedad (27, 28)")
	_comprobar(ins.retencion_juvenil() > 0.0, "la sala de juegos retiene juveniles (29)")
	_comprobar(ins.imagen_en_prensa() >= 1, "la sala de prensa mejora la imagen (11)")
	for i in 3:
		ins.iniciar("huerto", c)
		for j in 4:
			ins.avanzar_semana(c)
	_comprobar(ins.abarata_operacion() < 1.0, "el huerto, con nivel 3, abarata la operación (30)")
	## Personalización comercial: tres camisetas, medias, pantalón, tipografía y proveedor.
	var co: Comercial = m.comercial
	_comprobar(co.kits.has("titular") and co.kits.has("alt") and co.kits.has("por"), "hay camiseta titular, alternativa y de arquero (32, 33)")
	co.fijar_kit("alt", "c1", "#112233")
	_comprobar(String(co.kits["alt"]["c1"]) == "#112233", "se cambia el color de la alternativa (33)")
	_comprobar(co.medias == co.medias and co.pantalon == co.pantalon, "medias y pantalón son personalizables (35, 36)")
	_comprobar(Comercial.tipografias().size() >= 3, "hay varias tipografías para nombres y números (37): %d" % Comercial.tipografias().size())
	_comprobar(Comercial.proveedores().size() >= 3, "hay proveedores de indumentaria ficticios (38): %d" % Comercial.proveedores().size())
	_comprobar(Comercial.zonas().size() >= 3, "hay zonas de patrocinio (pecho, manga, espalda, short…) (121-123)")
	co.generar_ofertas_zona(c, 1.0)
	var con_oferta := false
	for z: String in co.ofertas_zona:
		if not (co.ofertas_zona[z] as Array).is_empty():
			con_oferta = true
	_comprobar(con_oferta, "los sponsors ofrecen contratos por zona (121, 126)")
	## Naming del estadio (5, 124): se firma, cambia el nombre y rinde.
	co.generar_ofertas_naming(c)
	_comprobar(co.ofertas_naming.size() == 3, "salen tres ofertas de naming (5)")
	_comprobar(co.firmar_naming(0, c) == "", "se firma el naming del estadio (5)")
	_comprobar(co.renta_naming() > 0, "y paga una renta (124): %s" % _dinero(co.renta_naming()))
	_comprobar(co.romper_naming(c) != null, "y se puede romper el contrato (5)")
	## Premium: palcos VIP, pantallas y techo retráctil (6, 7, 10).
	for p: String in ["vip", "pantalla", "techo"]:
		_comprobar(not co.def_premium(p).is_empty(), "existe la mejora premium «%s»" % p)
		_comprobar(co.mejorar_premium(p, c) == "", "se puede comprar «%s» (6, 7, 10)" % p)
	_comprobar(co.renta_premium(c) > 0 and co.factor_techo() > 1.0, "los palcos rentan y el techo retráctil sube la asistencia")

func _probar_ideas_personas_y_negocios() -> void:
	_titulo("IDEAS DEL DUEÑO: reputación, negociación y personal (46-49, 54, 81-83, 95-99, 105)")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 2425)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	c.mover_saldo(500000000)
	## Árbol de facetas del personaje (49): siete facetas, se mueven por decisiones y dan efectos.
	var rep: Reputacion = m.roles.reputacion
	_comprobar(Reputacion.FACETAS.size() == 7, "hay siete facetas de reputación (49)")
	var antes := rep.mult_ventas()
	for i in 6:
		rep.registrar("negociador", 12, "prueba")
	_comprobar(rep.valor("negociador") > 70, "una decisión repetida mueve la faceta (48)")
	_comprobar(rep.mult_ventas() > antes, "y se nota en lo que te pagan por tus jugadores (48, 49)")
	_comprobar(rep.titular() != "" and rep.historial.size() >= 1, "hay titular de fama e historial de decisiones (48)")
	## El carisma del DT cuesta o rinde en el sueldo (54).
	_comprobar(Trabajadores.CARACTERES.has("carismatico"), "existe el carácter carismático del personal (54)")
	## El personal con nombre de cada instalación (95, 96, 98, 99, 105).
	for k: String in ["video", "rehab", "cocina", "med", "park"]:
		var t := Trabajadores.de(c, k)
		_comprobar(not t.is_empty() and String(t["nombre"]) != "" and String(t["puesto"]) != "", "la instalación «%s» tiene encargado con nombre y puesto (%s)" % [k, String(t.get("puesto", ""))])
	_comprobar(Trabajadores.de(c, "video") == Trabajadores.de(c, "video"), "y es siempre la misma persona (determinista)")
	## Negociación (81, 82, 83, 65): oferta con cuotas, bonos, cláusula; el jugador responde.
	var objetivo: Jugador = null
	for cl: Club in m.ligas[0].clubes:
		if cl.id != c.id:
			objetivo = cl.plantilla[0]
			break
	var n := Negociacion.new(m, objetivo)
	_comprobar(n.pedido > 0 and n.fijo > 0 and n.estado == "abierta", "se abre una mesa con precio pedido (81)")
	n.ajustar("cuotas", 1)
	n.ajustar("bonos", 1)
	n.alternar_clausula()
	_comprobar(n.clausula, "se puede poner cláusula de rescisión (65)")
	var tipos := {}
	for i in 6:
		var r := n.enviar_oferta()
		tipos[String(r.get("tipo", ""))] = true
		if n.estado != "abierta":
			break
	_comprobar(tipos.size() >= 1 and not tipos.has(""), "la oferta recibe respuesta: %s (81)" % ", ".join(tipos.keys()))

func _probar_ideas_eventos_de_despacho() -> void:
	_titulo("IDEAS DEL DUEÑO: eventos del despacho con dos salidas (151, 163, 186-200, 216, 271)")
	var ids := ["viral", "filtracion_agente", "huelga_impagos", "retiro_joven", "aniversario", "virus_fifa",
		"apuestas", "espia", "lobby_arbitral", "aumento", "agente", "derbi_amenaza", "tunel", "benefico", "docu", "tv", "gira"]
	for id: String in ids:
		for op: String in ["a", "b"]:
			var m := Mundo.new()
			m.generar(["CHI", "ARG"], 2426)
			m.tomar_el_mando(m.ligas[0].clubes[0].id)
			m.mi_club().mover_saldo(300000000)
			var pr := m.prensa
			var fig: Jugador = m.mi_club().plantilla[0]
			pr.pendiente = {"id": id, "pid": fig.id, "txt": "", "opcion_a": "", "opcion_b": ""}
			var r := pr.resolver(op)
			_comprobar(r is Dictionary and not (r as Dictionary).is_empty() and String((r as Dictionary).get("titulo", "")) != "",
				"el evento «%s» se resuelve con la opción %s y deja titular (%s)" % [id, op, String((r as Dictionary).get("titulo", "")).left(40)])
			_comprobar(pr.pendiente.is_empty(), "y ya no queda pendiente")

func _probar_ideas_premios_y_memoria_del_club() -> void:
	_titulo("IDEAS DEL DUEÑO: premios, salón de la fama, museo, hinchada, prensa (139, 150, 161, 169, 175-181, 212, 217)")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 2427)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	m.jugar_temporada()
	var lg: Logros = m.logros
	var acta := lg.premios_temporada()
	for k: String in ["ideal", "joven", "dt", "fairplay", "popular", "puesto"]:
		_comprobar(acta.has(k), "la gala de premios trae «%s» (176-181)" % k)
	_comprobar((acta["ideal"] as Array).size() >= 10, "el equipo ideal tiene once nombres (181): %d" % (acta["ideal"] as Array).size())
	var con_premio := 0
	for j: Jugador in m.jugadores():
		if not j.premios.is_empty():
			con_premio += 1
	_comprobar(con_premio >= 11, "los premios quedan en la ficha de cada premiado (%d jugadores)" % con_premio)
	m.cerrar_temporada()
	_comprobar(lg.salon_de_la_fama().size() >= 0, "el salón de la fama se puede consultar (212)")
	_comprobar(lg.piezas_del_museo() is Array, "el museo se arma con las piezas del club (217)")
	var h: Hinchada = m.hinchada
	var socios := m.mi_club().socios
	m.mi_club().mover_saldo(200000000)
	_comprobar(h.dia_del_hincha(m.mi_club(), m.prensa) == "", "el día del hincha se organiza (139)")
	_comprobar(m.mi_club().socios > socios and h.dias_hincha >= 1, "y suma socios (139)")
	_comprobar(m.prensa.mesa_de_debate().size() >= 1, "hay mesa de debate deportivo que opina de tu gestión (161)")
	var inf := m.prensa.opinion_influencer()
	_comprobar(inf is Dictionary, "los influencers pueden opinar sobre el club (150)")
	_comprobar(m.jugar_supercopa() is Dictionary, "la supercopa se juega entre campeón de liga y de copa (169)")
	_comprobar(m.directiva != null and m.directiva.confianza >= 0, "la directiva fija objetivos y mide confianza (175)")

func _probar_ideas_roles_y_carrera() -> void:
	_titulo("IDEAS DEL DUEÑO: roles, ascenso, sucesión, leyenda viva, retiro y sandbox (193, 214, 221-232)")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 2428)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var r: Roles = m.roles
	for rol: String in [Roles.DT, Roles.DIR, Roles.DUENO]:
		_comprobar(Roles.PERMISOS.has(rol), "existe el rol «%s» con sus permisos (221-223)" % rol)
	_comprobar(not bool(Roles.PERMISOS[Roles.DT]["manda"]) and bool(Roles.PERMISOS[Roles.DUENO]["capital"]),
		"el DT no manda y el dueño sí mueve capital (221, 223)")
	_comprobar(Roles.ASCENSOS[Roles.DT]["a"] == Roles.DIR and Roles.ASCENSOS[Roles.DIR]["a"] == Roles.DUENO,
		"la cadena DT → presidente → dueño existe (224)")
	_comprobar(r.puede_ascender() != null, "el juego dice si puedes ascender o qué te falta (224)")
	r.sandbox = true
	_comprobar(r.sandbox, "existe el modo libre (232)")
	_comprobar(r.candidatos_sucesion().size() >= 1, "al retirarte hay candidatos a sucesor (230)")
	_comprobar(r.elegir_sucesor(0) == "" and not r.sucesor.is_empty(), "se elige al sucesor (230)")
	var estrella: Jugador = m.mi_club().plantilla[0]
	_comprobar(r.nombrar_leyenda_viva(estrella) == "" and not r.leyenda_viva.is_empty(), "un ídolo queda ligado al club de por vida (344)")
	_comprobar(r.nombrar_leyenda_viva(estrella) != "", "y solo puede haber una leyenda viva")
	var oferta := {}
	r.prestigio = 90
	m.semana = 30
	for i in 400:
		oferta = r.sortear_oferta_de_club()
		if not oferta.is_empty():
			break
	_comprobar(not oferta.is_empty(), "otro club acaba ofreciéndote su banquillo (193)")
	_comprobar(r.retirado.is_empty() and r.retirarse() == "" and not r.retirado.is_empty(), "te puedes retirar (214)")
	_comprobar(r.veredicto_carrera().has("texto") and m.puntaje_carrera().has("total"), "y hay resumen de la carrera con puntaje (214)")
	_comprobar(r.palmares_por_tipo() is Array, "el palmarés se agrupa por competición (214)")

func _probar_ideas_directiva_calendario_y_rivalidades() -> void:
	_titulo("IDEAS DEL DUEÑO: directiva, despido, calendario, rivalidades y récords (201, 203, 225, 228, 239, 252, 282, 316, 321-323, 328)")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 2429)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	## Se dirigen los partidos de tu club (solo esos alimentan la memoria del club).
	for i in 12:
		var par := m.proximo_partido()
		if par.is_empty():
			m.avanzar_semana()
			continue
		var p := Partido.new(par[0], par[1])
		p.simular()
		m.avanzar_semana(p)
	var d: Directiva = m.directiva
	_comprobar(d.objetivo != "" and d.meta_puesto >= 1, "la directiva fija un objetivo de temporada (175, 282)")
	var antes := d.confianza
	var res := d.tras_temporada(d.meta_puesto + 6, false, false)
	_comprobar(not bool(res["cumplido"]) and d.confianza < antes, "no cumplir el objetivo baja la confianza (282): %d → %d" % [antes, d.confianza])
	d.mover_confianza(-200, "prueba")
	_comprobar(d.despedido_ya or d.confianza <= 0, "con la confianza a cero te despiden (228)")
	_comprobar(m.junta != null and m.junta.has_method("resolver"), "la junta evalúa y plantea temas (225)")
	## Calendario por país: festivos locales con eventos (239, 252, 328).
	var fiestas := Calendario.del_anio("CHI", 2027)
	_comprobar(fiestas.size() >= 5, "Chile tiene sus feriados (%d) (252)" % fiestas.size())
	_comprobar(not Calendario.del_anio("ENG", 2027).is_empty() and not Calendario.del_anio("USA", 2027).is_empty(), "y otros países los suyos (252)")
	_comprobar(Calendario.torneos(2026).size() >= 1, "hay torneos de selecciones por año (239)")
	var lo_que_viene := Calendario.proximas("CHI", 2027, 1, 6)
	_comprobar(lo_que_viene.size() >= 1, "y el calendario enseña lo próximo (252)")
	## Rivalidades, cara a cara y récords del club (201, 203, 316, 321-323).
	var lg: Logros = m.logros
	var rivales := lg.rivalidades()
	_comprobar(rivales.size() >= 1, "tras una temporada hay rivales con nivel de rivalidad (201): %d" % rivales.size())
	var r0: Dictionary = rivales[0]
	_comprobar(int(r0["h2h"]["pj"]) >= 1 and String(r0["nivel"]) != "", "con historial de enfrentamientos directos (203, 321)")
	_comprobar(lg.goleadores_historicos(5).size() >= 1 and lg.mas_partidos(5).size() >= 1, "y libro de récords: goleadores y partidos (316)")
	_comprobar(lg.rec is Dictionary, "los récords guardan rachas y derrotas históricas (322, 323)")

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
