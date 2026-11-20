extends "res://pruebas/banco/cobertura_p1.gd"
## [Banco · grupo «cobertura»] (18-11) Pruebas de COMPORTAMIENTO de clases que el banco casi no tocaba (informe
## `docs/04_auditorias/cobertura_lineas_2026-11-18.md`). Esta capa: las citas en persona (nacimiento, caducidad,
## lecturas, resolución y guardado) y el pulso de roles. La capa 1 (`cobertura_p1.gd`): actualizador, entrada al campeonato y roles.

func _mundo_citas(semilla: int, pais: String, quien := 3) -> Mundo:
	var m := Mundo.new()
	m.generar([pais], semilla)
	m.tomar_el_mando(m.ligas[0].clubes[quien].id)
	m.citas = Citas.new()
	return m

func _probar_citas_nacen_y_caducan() -> void:
	_titulo("CITAS: NACEN DE LO QUE PASA, CADUCAN EL DOMINGO Y TIENEN TOPE")
	_comprobar(Citas.nombre_ficticio("a|b") == Citas.nombre_ficticio("a|b") and Citas.nombre_ficticio("a|b") != Citas.nombre_ficticio("x|y"), "nombre_ficticio(): determinista por semilla y distinto entre semillas")
	var m := _mundo_citas(9001, "ESP")
	var ci := m.citas
	var c := m.mi_club()
	var vistas: Array[String] = []
	ci.noticia.connect(func(t: String, _x: String) -> void: vistas.append(t))
	ci.semana(m, m.semana + 1)
	_comprobar(ci.lista.size() <= Citas.MAX_SEMANA, "sin nada que pase no nacen más que el tope de citas: %d" % ci.lista.size())
	ci.lista.clear()
	## 1) La junta pide la palabra.
	m.junta.formar(c)
	m.junta.pendiente = {"quien": "Ana Soto", "exige": "titulos", "monto": 0, "tema": "exige el título.", "a": "Prometer", "b": "Paciencia"}
	var prox := m.semana + 1
	ci.semana(m, prox)
	var junta := ci.pendientes().filter(func(x: Dictionary) -> bool: return x["tipo"] == "junta")
	_comprobar(junta.size() == 1 and String(junta[0]["asunto"]).contains("Ana Soto") and int(junta[0]["semana"]) == prox and String(junta[0]["estado"]) == "pendiente", "la junta abierta convoca UNA cita en el despacho")
	ci.semana(m, prox)
	_comprobar(ci.pendientes().filter(func(x: Dictionary) -> bool: return x["tipo"] == "junta").size() == 1, "no se duplica en la misma semana")
	_comprobar(vistas.size() >= 1 and vistas[0].ends_with(Idiomas.t("Cita nueva")), "avisa con una noticia «Cita nueva»")
	## 2) Patrocinio: la mejor oferta de la primera zona por orden alfabético (se parte de la agenda vacía).
	ci.lista.clear()
	m.comercial.ofertas_zona = {"zb": [{"marca": "Alfa", "color": "#fff", "monto": 100000, "anios": 1}], "za": [{"marca": "Beta", "color": "#fff", "monto": 100000, "anios": 1}, {"marca": "Gamma", "color": "#fff", "monto": 300000, "anios": 2}]}
	ci.semana(m, prox)
	var pat := ci.pendientes().filter(func(x: Dictionary) -> bool: return x["tipo"] == "patrocinio")
	_comprobar(pat.size() == 1 and String(pat[0]["clave"]) == "za|1", "patrocinio: la zona «za» y su oferta más alta (clave %s)" % (pat[0]["clave"] if not pat.is_empty() else "—"))
	## 3) Agente.
	m.mercado_av.superagente = "Jorge Mendes Falso"
	ci.semana(m, prox)
	_comprobar(ci.pendientes().filter(func(x: Dictionary) -> bool: return x["tipo"] == "agente" and x["quien"] == "Jorge Mendes Falso").size() == 1, "agente: aparece cuando hay superagente")
	_comprobar(ci.pendientes().size() <= Citas.MAX_SEMANA, "nunca más de 3 citas nacidas en la semana (%d)" % ci.pendientes().size())
	## 4) Caducidad: al pasar a otra semana las pendientes se archivan.
	var ids_viejos: Array = ci.pendientes().map(func(x: Dictionary) -> String: return String(x["id"]))
	ci.objetivo = String(ids_viejos[0])
	ci.semana(m, prox + 1)
	var todas_caducadas := true
	for id: String in ids_viejos:
		todas_caducadas = todas_caducadas and String(ci.por_id(id)["estado"]) == "caducada"
	_comprobar(todas_caducadas and ci.objetivo == "", "pasada la semana caducan sin castigo y se suelta el «Ir»")
	## 5) Solo se guardan 12.
	for i in 20:
		ci._nueva(m, prox + 1, "agente", "X%d" % i, "c", "a", "")
	ci.semana(m, prox + 1)
	_comprobar(ci.lista.size() <= 12 + Citas.MAX_SEMANA, "el historial se recorta (%d)" % ci.lista.size())
	## 6) Asamblea: año múltiplo de 4, semana 3.
	var m2 := _mundo_citas(9002, "ARG", 5)
	m2.anio = 2028
	m2.citas.semana(m2, Citas.ASAMBLEA_SEMANA)
	_comprobar(m2.citas.pendientes().any(func(x: Dictionary) -> bool: return x["tipo"] == "asamblea" and int(x["dia"]) == 5), "asamblea: año 2028, semana 3, el sábado")
	var m3 := _mundo_citas(9003, "ARG", 5)
	m3.anio = 2027
	m3.directiva.confianza = 10
	m3.citas.semana(m3, Citas.ASAMBLEA_SEMANA)
	_comprobar(m3.citas.pendientes().any(func(x: Dictionary) -> bool: return x["tipo"] == "asamblea"), "asamblea: confianza por los suelos también la convoca")
	var m4 := _mundo_citas(9004, "ARG", 5)
	m4.anio = 2027
	m4.directiva.confianza = 80
	m4.citas.semana(m4, Citas.ASAMBLEA_SEMANA)
	_comprobar(not m4.citas.pendientes().any(func(x: Dictionary) -> bool: return x["tipo"] == "asamblea"), "asamblea: con confianza alta y año normal, no")
	## 7) Trofeo nuevo → celebración en el museo.
	var m5 := _mundo_citas(9005, "ITA", 1)
	m5.citas.semana(m5, 2)
	m5.roles.sumar_trofeo("Copa de prueba")
	m5.citas.semana(m5, 3)
	_comprobar(m5.citas.pendientes().any(func(x: Dictionary) -> bool: return x["tipo"] == "celebracion" and int(x["dia"]) == 0), "un trofeo nuevo convoca la celebración el lunes")
	## 8) Rama de otro deporte pide presupuesto en la semana 5.
	var m6 := _mundo_citas(9006, "ESP", 2)
	var clave := String((Hinchada.RAMAS[1] as Array)[0])
	if not m6.hinchada.tiene_rama(clave):
		m6.hinchada.anios_rama[clave] = 1
	var tiene := m6.hinchada.tiene_rama(clave)
	m6.citas.semana(m6, Citas.RAMA_SEMANA)
	_comprobar(not tiene or m6.citas.pendientes().any(func(x: Dictionary) -> bool: return x["tipo"] == "rama" and x["clave"] == clave), "rama «%s»: su coordinadora pide el extra en la semana 5" % clave)
	## 9) Sin club no hace nada.
	var vacio := Mundo.new()
	vacio.generar(["CHI"], 9007)
	var cv := Citas.new()
	cv.semana(vacio)
	_comprobar(cv.lista.is_empty(), "sin club propio no nacen citas")

func _probar_citas_lecturas_y_resolucion() -> void:
	_titulo("CITAS: HORA, LUGAR, OPCIONES Y RESOLVER CADA TIPO")
	var m := _mundo_citas(9101, "BRA", 4)
	var ci := m.citas
	var c := m.mi_club()
	m.junta.formar(c)
	m.junta.pendiente = {"quien": "Luis Reyes", "exige": "titulos", "monto": 0, "tema": "exige el título.", "a": "Prometer pelear", "b": "Pedir paciencia"}
	ci._nueva(m, m.semana, "junta", "Presi", "Presidente", "tema", "")
	var ct: Dictionary = ci.lista[0]
	var rel := Reloj.new()
	rel.anio = m.anio
	rel.semana = m.semana
	rel.dia = int(ct["dia"])
	rel.minuto = int(ct["hora"]) * 60
	_comprobar(ci.en_hora(ct, rel), "en hora: su día y su hora")
	rel.minuto = (int(ct["hora"]) + Citas.DURACION) * 60
	_comprobar(not ci.en_hora(ct, rel), "pasada la duración ya no está")
	rel.minuto = (int(ct["hora"]) - 1) * 60
	_comprobar(not ci.en_hora(ct, rel), "antes de la hora tampoco")
	rel.minuto = int(ct["hora"]) * 60
	rel.dia = (int(ct["dia"]) + 1) % 7
	_comprobar(not ci.en_hora(ct, rel) and not ci.en_hora({}, rel) and not ci.en_hora(ct, null), "otro día, cita vacía o sin reloj: no")
	_comprobar(ci.cuando(ct).contains("11:00") and ci.lugar(ct)["planta"] == 1 and ci.lugar(ct)["donde"] == "estadio", "cuando() y lugar() de la junta")
	_comprobar(ci.opciones(m, ct) == ["Prometer pelear", "Pedir paciencia"], "opciones de la junta: las de la propia junta")
	_comprobar(ci.por_id("no_existe").is_empty() and ci.por_id(String(ct["id"]))["tipo"] == "junta", "por_id()")
	for tipo: String in ["patrocinio", "agente", "rama", "celebracion", "asamblea", "entrevista", "politica"]:
		ci._nueva(m, m.semana, tipo, "q", "c", "a", "k")
		var o := ci.opciones(m, ci.lista.back())
		_comprobar(o.size() >= 2 and ((tipo != "asamblea" and tipo != "entrevista") or o.size() == 3), "opciones de «%s»: %d" % [tipo, o.size()])
	ci.lista.clear()
	## Resolver: junta.
	ci._nueva(m, m.semana, "junta", "Presi", "Presidente", "tema", "")
	var conf0 := m.directiva.confianza
	var r := ci.resolver(m, String(ci.lista[0]["id"]), 0)
	_comprobar(String(ci.lista[0]["estado"]) == "hecha" and r.has("titulo") and m.directiva.confianza >= conf0 + 1 and m.junta.pendiente.is_empty(), "junta: se resuelve, +1 de confianza y la junta se cierra")
	_comprobar(ci.resolver(m, String(ci.lista[0]["id"]), 0).is_empty() and ci.resolver(m, "no_existe", 0).is_empty(), "una cita hecha o inexistente no se resuelve otra vez")
	ci._nueva(m, m.semana, "junta", "Presi", "Presidente", "tema", "")
	_comprobar(String(ci.resolver(m, String(ci.lista.back()["id"]), 1)["texto"]) != "", "junta sin asunto pendiente: respuesta de cortesía")
	## Patrocinio: firma en persona con +5 %.
	m.comercial.zonas_firmadas.clear()
	m.comercial.ofertas_zona = {"za": [{"marca": "Beta", "color": "#fff", "monto": 1000000, "anios": 2}]}
	ci._nueva(m, m.semana, "patrocinio", "Dir", "marketing", "a", "za|0")
	var idp := String(ci.lista.back()["id"])
	r = ci.resolver(m, idp, 0)
	_comprobar(m.comercial.zonas_firmadas.has("za") and int(m.comercial.zonas_firmadas["za"]["monto"]) == 1050000, "patrocinio: la zona se firma con +5 %% (%d)" % int((m.comercial.zonas_firmadas.get("za", {}) as Dictionary).get("monto", 0)))
	ci._nueva(m, m.semana, "patrocinio", "Dir", "marketing", "a", "za|0")
	r = ci.resolver(m, String(ci.lista.back()["id"]), 0)
	_comprobar(String(r["texto"]).length() > 0 and m.comercial.zonas_firmadas.size() == 1, "patrocinio con la zona ya vendida: avisa y no firma otra")
	ci._nueva(m, m.semana, "patrocinio", "Dir", "marketing", "a", "za|0")
	var zf := m.comercial.zonas_firmadas.size()
	r = ci.resolver(m, String(ci.lista.back()["id"]), 1)
	_comprobar(m.comercial.zonas_firmadas.size() == zf, "patrocinio, «lo pienso»: no firma")
	## Agente.
	m.mercado_av.superagente = "Ag Ente"
	ci._nueva(m, m.semana, "agente", "Ag Ente", "Agente", "a", "")
	ci.resolver(m, String(ci.lista.back()["id"]), 0)
	_comprobar(ci.favor_agente == m.anio * 60 + m.semana, "agente: escucharlo deja un favor anotado")
	ci.favor_agente = -1
	ci._nueva(m, m.semana, "agente", "Ag Ente", "Agente", "a", "")
	ci.resolver(m, String(ci.lista.back()["id"]), 1)
	_comprobar(ci.favor_agente == -1, "agente: rechazarlo no deja favor")
	## Entrevista: moral por tono y por staff.
	var j: Jugador = c.plantilla[3]
	ci.entrevista(m, j)
	var ent: Dictionary = ci.lista.back()
	_comprobar(ent["tipo"] == "entrevista" and ent["clave"] == j.id and int(ent["dia"]) >= 0 and int(ent["dia"]) <= 5 and ent["quien"] == j.nombre, "entrevista(): cita para el nuevo fichaje")
	j.moral = 50
	r = ci.resolver(m, String(ent["id"]), 0, [-1, 2])
	_comprobar(j.moral == 50 + Citas.MORAL_ENTREVISTA[0] + 1, "entrevista tono seguro (+2) y trabajar con nadie en especial (+1): moral %d" % j.moral)
	ci.entrevista(m, j)
	var f0 := j.forma
	var a0 := j.adapt
	j.moral = 50
	ci.resolver(m, String(ci.lista.back()["id"]), 1, [-1, 0])
	_comprobar(j.moral == 50 + Citas.MORAL_ENTREVISTA[1] and j.forma == mini(100, f0 + 3) and j.adapt == a0, "entrevista evasiva y preparador físico: −1 de moral y +3 de forma")
	ci.entrevista(m, j)
	j.adapt = 20
	ci.resolver(m, String(ci.lista.back()["id"]), 2, [-1, 1])
	_comprobar(j.adapt == 35, "entrevista con el analista: +15 de adaptación")
	ci.entrevista(m, j)
	var id_i := String(ci.lista.back()["id"])
	c.plantilla.erase(j)
	_comprobar(String(ci.resolver(m, id_i, 0)["texto"]).length() > 0, "entrevista de alguien que ya no está: lo dice")
	c.plantilla.append(j)
	_comprobar(ci.opciones_entrevista(m, ci.lista.back(), 2).size() == 3 and ci.opciones_entrevista(m, ci.lista.back(), 0).size() == 3, "preguntas 1 y 3 de la entrevista: 3 opciones")
	var grupos := ci.grupos_entrevista(m)
	_comprobar(grupos.size() <= 2 and ci.opciones_entrevista(m, ci.lista.back(), 1).size() == grupos.size() + 1, "pregunta 2: un grupo por opción (hasta 2) más «con todos»")
	if not grupos.is_empty():
		ci.entrevista(m, j)
		ci.resolver(m, String(ci.lista.back()["id"]), 0, [0])
		_comprobar((grupos[0]["miembros"] as Array).has(j.id) and m.vestuario._clan_de[j.id] == grupos[0]["id"], "entrevista: entras al grupo elegido")
	## Asamblea: gana y pierde.
	m.prensa.animo = 80
	m.directiva.confianza = 80
	ci._nueva(m, m.semana, "asamblea", "Presi", "Asamblea", "a", "")
	r = ci.resolver(m, String(ci.lista.back()["id"]), 0)
	_comprobar(ci.asamblea_anio == m.anio and m.directiva.confianza == 82 and String(r["titulo"]) == Idiomas.t("La asamblea respalda al presidente"), "asamblea con grada contenta: respalda y +2 de confianza")
	m.prensa.animo = 10
	m.directiva.confianza = 5
	ci._nueva(m, m.semana, "asamblea", "Presi", "Asamblea", "a", "")
	r = ci.resolver(m, String(ci.lista.back()["id"]), 1)
	_comprobar(m.directiva.confianza == 50 and String(r["titulo"]) == Idiomas.t("Nuevo presidente") and not m.prensa.titular_pendiente.is_empty(), "asamblea perdida: nuevo presidente, confianza 50 y titular de prensa")
	## Rama: aprobar paga, sin caja no.
	var clave := String((Hinchada.RAMAS[0] as Array)[0])
	ci._nueva(m, m.semana, "rama", "Coord", "c", "a", clave)
	c.saldo = 0
	r = ci.resolver(m, String(ci.lista.back()["id"]), 0)
	_comprobar(not m.hinchada.bono_rama.has(clave), "rama sin caja: no hay bono")
	ci._nueva(m, m.semana, "rama", "Coord", "c", "a", clave)
	c.saldo = 900000000
	var s0 := c.saldo
	ci.resolver(m, String(ci.lista.back()["id"]), 0)
	_comprobar(m.hinchada.bono_rama.get(clave, -1) == m.anio and c.saldo < s0, "rama aprobada: se paga y queda el bono de la temporada")
	ci._nueva(m, m.semana, "rama", "Coord", "c", "a", clave)
	s0 = c.saldo
	ci.resolver(m, String(ci.lista.back()["id"]), 1)
	_comprobar(c.saldo == s0, "rama rechazada: no cuesta")
	## Celebración: sube el ánimo.
	m.prensa.animo = 40
	ci._nueva(m, m.semana, "celebracion", "Presi", "c", "a", "")
	ci.resolver(m, String(ci.lista.back()["id"]), 1)
	_comprobar(m.prensa.animo == 43, "celebración en privado: +3 de ánimo")
	## Política.
	ci._nueva(m, m.semana, "politica", "Jefe", "c", "a", c.pais)
	ci.resolver(m, String(ci.lista.back()["id"]), 0)
	_comprobar(int(m.politica.gobierno(c.pais, m.anio).get("apoyo_club", -1)) == m.anio, "política: apoyar al gobierno queda anotado")
	ci._nueva(m, m.semana, "politica", "Jefe", "c", "a", c.pais)
	_comprobar(String(ci.resolver(m, String(ci.lista.back()["id"]), 1)["texto"]) != "", "política: negarse da una respuesta")
	## Objetivo: al resolver la cita marcada, se suelta.
	ci._nueva(m, m.semana, "celebracion", "Presi", "c", "a", "")
	ci.objetivo = String(ci.lista.back()["id"])
	ci.resolver(m, ci.objetivo, 1)
	_comprobar(ci.objetivo == "", "resolver la cita marcada con «Ir» la suelta")

func _probar_citas_rueda_y_guardado() -> void:
	_titulo("CITAS: RUEDA DE PRENSA DESDE EL MÓVIL Y GUARDADO")
	var m := _mundo_citas(9201, "FRA", 2)
	var ci := m.citas
	_comprobar(ci.convocar_rueda(null) != "" and Citas.new().convocar_rueda(Mundo.new()) != "", "sin prensa no se puede convocar")
	var e1 := ci.convocar_rueda(m)
	_comprobar(e1 == "" or e1.contains("Ya hay"), "primera convocatoria: abierta (o ya había una): «%s»" % e1)
	m.prensa.pregunta_pendiente = {}
	var e2 := ci.convocar_rueda(m)
	_comprobar(e2.contains("esta semana") or e2.contains("Ya hay"), "segunda en la misma semana: no")
	ci._nueva(m, m.semana, "agente", "Ag", "Agente", "a", "")
	ci.objetivo = String(ci.lista[0]["id"])
	ci.favor_agente = 77
	ci.asamblea_anio = 2030
	var d := ci.a_dic()
	var otro := Citas.new()
	otro.desde_dic(JSON.parse_string(JSON.stringify(d)))
	_comprobar(otro.lista.size() == ci.lista.size() and otro.objetivo == ci.objetivo and otro.favor_agente == 77 and otro.asamblea_anio == 2030 and otro.rueda_semana == ci.rueda_semana, "a_dic()/desde_dic(): ida y vuelta por JSON")
	otro.lista[0]["estado"] = "caducada"
	_comprobar(ci.lista[0]["estado"] == "pendiente", "lo cargado es una copia, no comparte datos con la partida guardada")
	otro.desde_dic({})
	_comprobar(otro.lista.is_empty() and otro.objetivo == "" and otro.favor_agente == -1, "desde_dic({}) deja todo en blanco")

func _probar_roles_pulso_y_ascenso_de_ayudante() -> void:
	_titulo("ROLES: PULSO DE PARTIDOS, AYUDANTE, INTERINATO Y CANTERA")
	var m := _mundo_roles(8101)
	var r: Roles = m.roles
	r.prestigio = 50
	r.tras_partido(2, 0)
	_comprobar(r.prestigio == 51, "ganar sube 1 de prestigio")
	r.tras_partido(1, 1)
	_comprobar(r.prestigio == 51, "empatar no lo mueve")
	r.tras_partido(0, 1)
	_comprobar(r.prestigio == 50, "perder baja 1")
	var rep_antes := r.reputacion.historial.size()
	r.tras_partido(5, 0)
	r.tras_partido(0, 4)
	_comprobar(r.prestigio == 50, "una goleada a favor y otra en contra (±1): vuelve a 50 (%d)" % r.prestigio)
	_comprobar(r.reputacion.historial.size() >= rep_antes + 2, "las goleadas dejan anotada su reputación de «ganador»")
	## Ayudante: gana y asciende.
	var m2 := _mundo_roles(8102)
	var a: Roles = m2.roles
	a.arrancar_ayudante()
	var ascensos: Array[String] = []
	var cambios: Array[String] = []
	a.ascenso.connect(func(n: String) -> void: ascensos.append(n))
	a.rol_cambiado.connect(func(x: String, y: String) -> void: cambios.append(x + ">" + y))
	a.prestigio = Roles.PRESTIGIO_PARA_EL_BANCO
	a.dt_empleado["confianza"] = Roles.JEFE_ASCIENDE - 2
	a.tras_partido(2, 0)
	_comprobar(a.rol == Roles.DT and not a.es_ayudante(), "tras ganar con confianza y prestigio altos pasa a entrenador principal")
	_comprobar(ascensos == [Roles.DT] and cambios == ["ayudante>dt"] and bool(a.ayudante.get("ascendido", false)) and a.dt_empleado.is_empty(), "señales de ascenso y marca de «ascendido»")
	_comprobar(m2.directiva.confianza == 62 and a.prestigio >= Roles.PRESTIGIO_PARA_EL_BANCO + 8, "ascender: confianza directiva 62 y +8 de prestigio (%d)" % m2.directiva.confianza)
	## Ayudante: pierde mucho y lo echan del cuerpo técnico.
	var m3 := _mundo_roles(8103)
	var e: Roles = m3.roles
	e.arrancar_ayudante()
	var fuera: Array[String] = []
	e.fuera_del_cuerpo_tecnico.connect(func(j: String) -> void: fuera.append(j))
	var jefe := e.jefe_nombre()
	var p_ini := e.prestigio
	e.dt_empleado["confianza"] = Roles.JEFE_ECHA + 1
	e.tras_partido(0, 1)
	_comprobar(e.sin_club and e.rol == Roles.DT and fuera == [jefe] and e.ayudante.is_empty() and e.prestigio == p_ini - 1 - 3, "con la confianza del jefe por los suelos te sacan del cuerpo técnico (sin club, −1 y −3 de prestigio)")
	## Ayudante con empate: la confianza solo sube 1 y no hay ascenso.
	var m4 := _mundo_roles(8104)
	var f: Roles = m4.roles
	f.arrancar_ayudante()
	f.dt_empleado["confianza"] = 40
	f.tras_partido(1, 1)
	_comprobar(f.jefe_confianza() == 41 and f.es_ayudante(), "un empate: +1 de confianza del jefe")
	f.tras_partido(0, 1)
	_comprobar(f.jefe_confianza() == 39 and int(f.dt_empleado["malos"]) == 1, "una derrota: −2 y un «mal» más")
	f.tras_partido(3, 0)
	_comprobar(f.jefe_confianza() == 42 and int(f.dt_empleado["malos"]) == 0, "ganar: +3 y borra los «malos»")
	## Interinato: se resuelve a las cinco fechas.
	var m5 := _mundo_roles(8105)
	var i: Roles = m5.roles
	i.arrancar_interinato("CHI")
	var resultados: Array[bool] = []
	i.interinato_resuelto.connect(func(s: bool) -> void: resultados.append(s))
	_comprobar(i.en_interinato() and i.fechas_interinato_restantes() > 0, "recién empezado quedan fechas (%d)" % i.fechas_interinato_restantes())
	i.tras_jornada()
	_comprobar(resultados.is_empty() and i.en_interinato(), "con fechas por jugar no se resuelve")
	var liga := m5.liga_de(m5.mi_club())
	liga.jornada_actual = liga.jornadas()
	_comprobar(i.fechas_interinato_restantes() == 0, "sin fechas por jugar quedan 0")
	var prest0 := i.prestigio
	i.tras_jornada()
	_comprobar(resultados.size() == 1 and not i.en_interinato() and bool(i.interino["cumplido"]) and i.prestigio != prest0, "se cumple el contrato: veredicto emitido y el prestigio se mueve")
	_comprobar(i.fechas_interinato_restantes() == 0, "ya no es interino: 0 fechas")
	i.tras_jornada()
	_comprobar(resultados.size() == 1, "no se resuelve dos veces")
	## Cantera: meta cumplida y meta incumplida.
	var m6 := _mundo_roles(8106)
	var q: Roles = m6.roles
	q.arrancar_cantera()
	var av: Array[String] = []
	q.aviso.connect(func(t: String, _x: String) -> void: av.append(t))
	q.cantera["meta"] = 2
	q.cantera["subidos"] = ["a", "b"]
	var p0 := q.prestigio
	var conf0 := m6.directiva.confianza
	q._chequeo_cantera()
	_comprobar(q.prestigio == p0 + 8 and av.back() == "Objetivo de cantera cumplido" and m6.directiva.confianza >= conf0, "cantera cumplida: +8 de prestigio y aviso")
	_comprobar(int(q.cantera["meta"]) >= 3 and int(q.cantera["meta"]) <= 5 and (q.cantera["subidos"] as Array).is_empty(), "y se fija una meta nueva de 3 a 5 con el contador a cero")
	q.cantera["subidos"] = ["a"]
	q.cantera["meta"] = 4
	var conf1 := m6.directiva.confianza
	q._chequeo_cantera()
	_comprobar(av.back() == "Objetivo de cantera incumplido" and m6.directiva.confianza < conf1, "cantera incumplida: aviso y baja la confianza de la directiva")
	## Reputación de temporada: lealtad, formador y social.
	var antes := q.reputacion.historial.size()
	q._reputacion_de_temporada()
	_comprobar(q.reputacion.historial.size() >= antes + 3, "el cierre de temporada anota lealtad, formador y social")
	_comprobar(m6.mi_club().socios >= 0, "los socios no quedan negativos")
