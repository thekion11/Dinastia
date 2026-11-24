extends BaseIdea
## f4p · CITAS EN PERSONA (fase 4, bloque 1): nacen de lo que ya pasa (junta, zona de
## patrocinio, superagente, votación), llegan al móvil, se ven en la Agenda, la persona
## está en su sitio solo en su hora, resolverlas hace lo de siempre con el bono de ir en
## persona, caducan el domingo sin castigo, y sobreviven a guardar y cargar.

var _pend = []
var _ct = {}
var _sem_voto = 0
var _antes = 0
var _conf0 = 0

func _probar() -> void:
	_titulo("f4p: citas en persona")
	var m := _mundo(31)
	m.reloj.sincronizar(m.anio, m.semana)
	var c := m.mi_club()
	_citas_01_al_generar_el_mundo_ya_h(m, c)
	_citas_02_en_su_hora_y_solo_en_su_(m, c)
	_citas_03_firmar_en_persona_la_zon(m, c)
	_citas_04_la_junta_con_un_asunto_a(m, c)
	_citas_05_el_superagente_y_la_vota(m, c)
	_citas_06_2_5_apoyar_al_gobierno_l(m, c)
	_citas_07_el_favor_abarata_la_pr_x(m, c)
	_citas_08_la_entrevista_de_contrat(m, c)
	_citas_09_2_5_la_entrevista_comple(m, c)
	_citas_10_fotos_a_tribuna_bloque_6(m, c)
	_citas_11_convocar_una_rueda_de_pr(m, c)
	_citas_12_la_asamblea_de_socios_bl(m, c)
	_citas_13_caducan_el_domingo_sin_c(m, c)
	_citas_14_guardar_y_cargar(m, c)

func _citas_01_al_generar_el_mundo_ya_h(m: Mundo, c: Club) -> void:
	## Al generar el mundo ya hay ofertas de zona → una cita de patrocinio en la semana 1.
	_pend = m.citas.pendientes()
	_comprobar(_pend.size() >= 1 and _pend[0]["tipo"] == "patrocinio", "al nacer el mundo hay una cita con una marca (%d)" % _pend.size())
	_comprobar(m.movil.mensajes.size() >= 1 and String(m.movil.mensajes[0]["de"]) == String(_pend[0]["quien"]), "y el mensaje llegó al móvil")
	_comprobar(Movil.texto(m.movil.mensajes[0]).contains("16:00"), "el mensaje dice la hora (%s)" % Movil.texto(m.movil.mensajes[0]).left(60))
	_ct = _pend[0]
	_comprobar(m.citas.cuando(_ct).contains("16:00") and m.citas.opciones(m, _ct).size() == 2, "la Agenda sabe cuándo y hay dos respuestas")

func _citas_02_en_su_hora_y_solo_en_su_(m: Mundo, c: Club) -> void:
	## En su hora, y solo en su hora.
	m.reloj.dia = int(_ct["dia"])
	m.reloj.minuto = int(_ct["hora"]) * 60 + 20
	_comprobar(m.citas.en_hora(_ct, m.reloj), "a su hora la persona está en el sitio")
	m.reloj.minuto = (int(_ct["hora"]) + 3) * 60
	_comprobar(not m.citas.en_hora(_ct, m.reloj), "tres horas después ya no")

func _citas_03_firmar_en_persona_la_zon(m: Mundo, c: Club) -> void:
	## Firmar en persona: la zona queda firmada con el +5 %.
	var partes := String(_ct["clave"]).split("|")
	var monto0 := int((m.comercial.ofertas_zona[partes[0]][int(partes[1])] as Dictionary)["monto"])
	var r := m.citas.resolver(m, String(_ct["id"]), 0)
	_comprobar(not r.is_empty() and m.comercial.zonas_firmadas.has(partes[0]), "firmar en la cita vende la zona")
	var monto1 := int(m.comercial.zonas_firmadas[partes[0]]["monto"])
	_comprobar(monto1 > monto0 and monto1 <= int(monto0 * 1.06), "con el +5 %% por hacerlo en persona (%d → %d)" % [monto0, monto1])
	_comprobar(m.citas.por_id(String(_ct["id"]))["estado"] == "hecha" and m.citas.pendientes().size() == _pend.size() - 1, "la cita queda hecha")

func _citas_04_la_junta_con_un_asunto_a(m: Mundo, c: Club) -> void:
	## La junta: con un asunto abierto, el presidente te cita en su despacho.
	m.junta.formar(c)
	m.junta.pendiente = m.junta._tema(c, m.junta.accionistas[0])
	m.citas.semana(m, m.semana)
	var cj := {}
	for x: Dictionary in m.citas.pendientes():
		if x["tipo"] == "junta":
			cj = x
	_comprobar(not cj.is_empty() and String(cj["quien"]) == String(m.junta.presidente["nombre"]), "la junta abierta trae una cita con el presidente")
	_conf0 = m.directiva.confianza
	var rj := m.citas.resolver(m, String(cj["id"]), 1)
	_comprobar(not rj.is_empty() and m.junta.pendiente.is_empty(), "resolverla en persona cierra la junta como en el PC")
	_comprobar(m.directiva.confianza >= _conf0 - 20 and rj["texto"].contains("+1"), "y suma el +1 de confianza por dar la cara")

func _citas_05_el_superagente_y_la_vota(m: Mundo, c: Club) -> void:
	## El superagente y la votación.
	m.mercado_av.superagente = "Teo Varela"
	_sem_voto = Politica.semana_votacion(c.pais) - 1
	_antes = m.semana
	m.semana = _sem_voto
	m.citas.semana(m, _sem_voto)
	var tipos: Array = []
	for x: Dictionary in m.citas.pendientes():
		tipos.append(x["tipo"])
	_comprobar(tipos.has("agente") and tipos.has("politica"), "agente y gabinete citan en su semana (%s)" % [tipos])
	_comprobar(m.citas.pendientes().size() <= Citas.MAX_SEMANA, "nunca más de %d citas por semana" % Citas.MAX_SEMANA)
	for x: Dictionary in m.citas.pendientes():
		if x["tipo"] == "agente":
			m.citas.resolver(m, String(x["id"]), 0)
	_comprobar(m.citas.favor_agente == m.anio * 60 + m.semana, "escuchar al agente deja un favor pendiente")

func _citas_06_2_5_apoyar_al_gobierno_l(m: Mundo, c: Club) -> void:
	## §2.5: apoyar al gobierno lo hace aliado (sus ayudas +25 %, su tasa −25 %); si pierde, el nuevo recela.
	for x: Dictionary in m.citas.pendientes():
		if x["tipo"] == "politica":
			m.citas.resolver(m, String(x["id"]), 0)
	var gob := m.politica.gobierno(c.pais, m.anio)
	var s0 := c.saldo
	m.politica._efecto(c, "deporte", null, Politica.relacion(gob))
	var con_apoyo := c.saldo - s0
	s0 = c.saldo
	m.politica._efecto(c, "deporte", null, 0)
	var sin_apoyo := c.saldo - s0
	s0 = c.saldo
	m.politica._efecto(c, "seguridad", null, 1)
	var tasa_aliado := s0 - c.saldo
	s0 = c.saldo
	m.politica._efecto(c, "seguridad", null, -1)
	var tasa_recelo := s0 - c.saldo
	_comprobar(Politica.relacion(gob) == 1 and con_apoyo == int(round(sin_apoyo * 1.25)) and tasa_aliado < tasa_recelo,
		"apoyar al gobierno lo hace aliado: ayuda %d → %d; la tasa con aliado %d y con recelo %d" % [sin_apoyo, con_apoyo, tasa_aliado, tasa_recelo])
	_comprobar(Politica.relacion({"desde": m.anio, "recelo_club": m.anio}) == -1 and Politica.relacion({"desde": m.anio}) == 0,
		"si gana otro partido el nuevo gobierno recela; sin apoyo, neutral")
	var g_antes := m.politica.gobierno(c.pais, m.anio)
	g_antes["proxima"] = m.anio
	var partido_antes := String(g_antes["partido"])
	m.politica.semana(c, m.anio, Politica.semana_votacion(c.pais), null)
	var g_nuevo := m.politica.gobierno(c.pais, m.anio)
	var esperado := 1 if String(g_nuevo["partido"]) == partido_antes else -1
	_comprobar(Politica.relacion(g_nuevo) == esperado, "tras la votación el apoyo pesa: %s (%d)" % ["repite, sigue aliado" if esperado == 1 else "gana otro, recela", esperado])

func _citas_07_el_favor_abarata_la_pr_x(m: Mundo, c: Club) -> void:
	## El favor abarata la próxima mesa (bloque 3): −5 % en lo pedido y +10 puntos de aceptación.
	var otro: Club = null
	for cl: Club in m.ligas[0].clubes:
		if cl != c and not cl.plantilla.is_empty():
			otro = cl
			break
	if otro != null:
		var neg := Negociacion.new(m, otro.plantilla[0])
		_comprobar(neg.con_favor_agente() and is_equal_approx(neg.descuento_persona(), 0.95) and is_equal_approx(neg.bono_persona(), 0.10), "con el favor, la mesa pide un 5 % menos y acepta 10 puntos más")
		m.citas.favor_agente = -1
		_comprobar(not neg.con_favor_agente() and is_equal_approx(neg.descuento_persona(), 1.0), "sin favor, la mesa de siempre")
		m.citas.favor_agente = m.anio * 60 + m.semana

func _citas_08_la_entrevista_de_contrat(m: Mundo, c: Club) -> void:
	## La entrevista de contratación (bloque 4): mañana a las 10:00 en tu oficina, mueve la moral.
	m.reloj._al_dia()   ## el reloj vuelve a la semana del mundo _antes de fijar el día
	m.reloj.dia = 1
	var j: Jugador = c.plantilla[0]
	m.citas.entrevista(m, j)
	var ce := {}
	for x: Dictionary in m.citas.pendientes():
		if x["tipo"] == "entrevista":
			ce = x
	_comprobar(not ce.is_empty() and int(ce["dia"]) == 2 and String(ce["quien"]) == j.nombre and m.citas.opciones(m, ce).size() == 3, "el fichaje te cita mañana a las 10:00 con tres tonos")
	var moral0 := j.moral
	var re := m.citas.resolver(m, String(ce["id"]), 0)
	_comprobar(not re.is_empty() and j.moral == mini(moral0 + 2, 100), "el tono seguro sube la moral del recién llegado (+2)")

func _citas_09_2_5_la_entrevista_comple(m: Mundo, c: Club) -> void:
	## §2.5: la entrevista completa son tres preguntas (tono, grupo del vestuario, staff).
	var j2: Jugador = c.plantilla[1]
	m.citas.entrevista(m, j2)
	var ce2 := {}
	for x: Dictionary in m.citas.pendientes():
		if x["tipo"] == "entrevista":
			ce2 = x
	var grupos := m.citas.grupos_entrevista(m)
	_comprobar(m.citas.opciones_entrevista(m, ce2, 1).size() == grupos.size() + 1 and m.citas.opciones_entrevista(m, ce2, 2).size() == 3,
		"la entrevista pregunta también por el grupo del vestuario (%d + «con todos») y por el staff (3)" % grupos.size())
	var forma0 := j2.forma
	var ad0 := j2.adapt
	var mo2 := j2.moral
	m.citas.resolver(m, String(ce2["id"]), 2, [grupos.size(), 0])
	_comprobar(j2.forma == mini(forma0 + 3, 100) and j2.adapt == ad0 and j2.moral == mini(mo2 + 1, 100),
		"humilde + «con todos» + preparador físico: +1 de moral y +3 de forma")
	if not grupos.is_empty():
		var j3: Jugador = c.plantilla[2]
		m.citas.entrevista(m, j3)
		var ce3 := {}
		for x: Dictionary in m.citas.pendientes():
			if x["tipo"] == "entrevista":
				ce3 = x
		var cl: Dictionary = m.citas.grupos_entrevista(m)[0]
		m.citas.resolver(m, String(ce3["id"]), 0, [0, 1])
		_comprobar((cl["miembros"] as Array).has(j3.id) and String(m.vestuario._clan_de.get(j3.id, "")) == String(cl["id"]) and j3.adapt >= 15,
			"presentado a «%s»: entra en ese grupo; con el analista, +15 de adaptación" % String(cl["nombre"]))

func _citas_10_fotos_a_tribuna_bloque_6(m: Mundo, c: Club) -> void:
	## Fotos a Tribuna (bloque 6): una publicación «paseo» suma seguidores.
	var seg0 := int(m.redes.cuentas["dt"]["seguidores"])
	var pub := m.redes.publicar(m, "paseo", ["#MiCiudad"])
	_comprobar(not pub.has("error") and String(pub.get("tipo", "")) == "paseo" and int(m.redes.cuentas["dt"]["seguidores"]) >= seg0, "una foto del paseo se publica en Tribuna y suma seguidores")

func _citas_11_convocar_una_rueda_de_pr(m: Mundo, c: Club) -> void:
	## Convocar una rueda de prensa desde el móvil: una por semana, y no si ya hay una abierta.
	m.prensa.entrevista = {}
	_comprobar(m.citas.convocar_rueda(m) == "" and m.prensa.hay_rueda(), "convocar abre una rueda de prensa")
	_comprobar(m.citas.convocar_rueda(m) != "", "con una abierta no se convoca otra")
	m.prensa.entrevista = {}
	_comprobar(m.citas.convocar_rueda(m) != "", "y solo una extra por semana")

func _citas_12_la_asamblea_de_socios_bl(m: Mundo, c: Club) -> void:
	## La asamblea de socios (bloque 6): cada 4 temporadas; perderla cambia al presidente, no al DT.
	var anio0 := m.anio
	m.anio = 2028
	m.citas.asamblea_anio = -1
	m.citas.semana(m, Citas.ASAMBLEA_SEMANA)
	var ca := {}
	for x: Dictionary in m.citas.pendientes():
		if x["tipo"] == "asamblea":
			ca = x
	_comprobar(not ca.is_empty() and m.citas.opciones(m, ca).size() == 3, "en año de asamblea el presidente convoca a los socios (tres discursos)")
	var pres0 := String(m.junta.presidente["nombre"])
	m.prensa.animo = 20
	m.directiva.confianza = 30
	var ra := m.citas.resolver(m, String(ca["id"]), 0)
	_comprobar(not ra.is_empty() and String(m.junta.presidente["nombre"]) != pres0 and m.directiva.confianza == 50, "con la grada en contra, el discurso seguro pierde: presidente nuevo y confianza 50")
	m.citas.asamblea_anio = -1
	m.citas.semana(m, Citas.ASAMBLEA_SEMANA)
	for x: Dictionary in m.citas.pendientes():
		if x["tipo"] == "asamblea":
			ca = x
	var pres1 := String(m.junta.presidente["nombre"])
	m.prensa.animo = 80
	m.directiva.confianza = 70
	m.citas.resolver(m, String(ca["id"]), 0)
	_comprobar(String(m.junta.presidente["nombre"]) == pres1 and m.directiva.confianza == 72, "con la grada a favor, el presidente sigue (+2 de confianza)")
	m.anio = anio0

func _citas_13_caducan_el_domingo_sin_c(m: Mundo, c: Club) -> void:
	## Caducan el domingo sin castigo.
	m.semana = _sem_voto + 1
	var saldo := c.saldo
	m.citas.semana(m, m.semana + 1)
	var vivas := 0
	for x: Dictionary in m.citas.lista:
		if x["estado"] == "pendiente" and int(x["semana"]) == _sem_voto:
			vivas += 1
	_comprobar(vivas == 0 and c.saldo == saldo and m.directiva.confianza >= _conf0 - 20, "las citas de la semana pasada caducan sin castigo")
	m.semana = _antes

func _citas_14_guardar_y_cargar(m: Mundo, c: Club) -> void:
	## Guardar y cargar.
	var d := m.citas.a_dic()
	var c2 := Citas.new()
	c2.desde_dic(d)
	_comprobar(c2.lista.size() == m.citas.lista.size() and c2.favor_agente == m.citas.favor_agente, "las citas sobreviven a guardar y cargar")
	var inst := Partida.instantanea(m)
	_comprobar(inst.has("citas"), "y van en la instantánea de la partida")

