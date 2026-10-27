extends BaseIdea
## f4p · CITAS EN PERSONA (fase 4, bloque 1): nacen de lo que ya pasa (junta, zona de
## patrocinio, superagente, votación), llegan al móvil, se ven en la Agenda, la persona
## está en su sitio solo en su hora, resolverlas hace lo de siempre con el bono de ir en
## persona, caducan el domingo sin castigo, y sobreviven a guardar y cargar.

func _probar() -> void:
	_titulo("f4p: citas en persona")
	var m := _mundo(31)
	m.reloj.sincronizar(m.anio, m.semana)
	var c := m.mi_club()
	## Al generar el mundo ya hay ofertas de zona → una cita de patrocinio en la semana 1.
	var pend := m.citas.pendientes()
	_comprobar(pend.size() >= 1 and pend[0]["tipo"] == "patrocinio", "al nacer el mundo hay una cita con una marca (%d)" % pend.size())
	_comprobar(m.movil.mensajes.size() >= 1 and String(m.movil.mensajes[0]["de"]) == String(pend[0]["quien"]), "y el mensaje llegó al móvil")
	_comprobar(Movil.texto(m.movil.mensajes[0]).contains("16:00"), "el mensaje dice la hora (%s)" % Movil.texto(m.movil.mensajes[0]).left(60))
	var ct: Dictionary = pend[0]
	_comprobar(m.citas.cuando(ct).contains("16:00") and m.citas.opciones(m, ct).size() == 2, "la Agenda sabe cuándo y hay dos respuestas")
	## En su hora, y solo en su hora.
	m.reloj.dia = int(ct["dia"])
	m.reloj.minuto = int(ct["hora"]) * 60 + 20
	_comprobar(m.citas.en_hora(ct, m.reloj), "a su hora la persona está en el sitio")
	m.reloj.minuto = (int(ct["hora"]) + 3) * 60
	_comprobar(not m.citas.en_hora(ct, m.reloj), "tres horas después ya no")
	## Firmar en persona: la zona queda firmada con el +5 %.
	var partes := String(ct["clave"]).split("|")
	var monto0 := int((m.comercial.ofertas_zona[partes[0]][int(partes[1])] as Dictionary)["monto"])
	var r := m.citas.resolver(m, String(ct["id"]), 0)
	_comprobar(not r.is_empty() and m.comercial.zonas_firmadas.has(partes[0]), "firmar en la cita vende la zona")
	var monto1 := int(m.comercial.zonas_firmadas[partes[0]]["monto"])
	_comprobar(monto1 > monto0 and monto1 <= int(monto0 * 1.06), "con el +5 % por hacerlo en persona (%d → %d)" % [monto0, monto1])
	_comprobar(m.citas.por_id(String(ct["id"]))["estado"] == "hecha" and m.citas.pendientes().size() == pend.size() - 1, "la cita queda hecha")
	## La junta: con un asunto abierto, el presidente te cita en su despacho.
	m.junta.formar(c)
	m.junta.pendiente = m.junta._tema(c, m.junta.accionistas[0])
	m.citas.semana(m, m.semana)
	var cj := {}
	for x: Dictionary in m.citas.pendientes():
		if x["tipo"] == "junta":
			cj = x
	_comprobar(not cj.is_empty() and String(cj["quien"]) == String(m.junta.presidente["nombre"]), "la junta abierta trae una cita con el presidente")
	var conf0 := m.directiva.confianza
	var rj := m.citas.resolver(m, String(cj["id"]), 1)
	_comprobar(not rj.is_empty() and m.junta.pendiente.is_empty(), "resolverla en persona cierra la junta como en el PC")
	_comprobar(m.directiva.confianza >= conf0 - 20 and rj["texto"].contains("+1"), "y suma el +1 de confianza por dar la cara")
	## El superagente y la votación.
	m.mercado_av.superagente = "Teo Varela"
	var sem_voto := Politica.semana_votacion(c.pais) - 1
	var antes := m.semana
	m.semana = sem_voto
	m.citas.semana(m, sem_voto)
	var tipos: Array = []
	for x: Dictionary in m.citas.pendientes():
		tipos.append(x["tipo"])
	_comprobar(tipos.has("agente") and tipos.has("politica"), "agente y gabinete citan en su semana (%s)" % [tipos])
	_comprobar(m.citas.pendientes().size() <= Citas.MAX_SEMANA, "nunca más de %d citas por semana" % Citas.MAX_SEMANA)
	for x: Dictionary in m.citas.pendientes():
		if x["tipo"] == "agente":
			m.citas.resolver(m, String(x["id"]), 0)
	_comprobar(m.citas.favor_agente == m.anio * 60 + m.semana, "escuchar al agente deja un favor pendiente")
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
	## La entrevista de contratación (bloque 4): mañana a las 10:00 en tu oficina, mueve la moral.
	m.reloj._al_dia()   ## el reloj vuelve a la semana del mundo antes de fijar el día
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
	## Fotos a Tribuna (bloque 6): una publicación «paseo» suma seguidores.
	var seg0 := int(m.redes.cuentas["dt"]["seguidores"])
	var pub := m.redes.publicar(m, "paseo", ["#MiCiudad"])
	_comprobar(not pub.has("error") and String(pub.get("tipo", "")) == "paseo" and int(m.redes.cuentas["dt"]["seguidores"]) >= seg0, "una foto del paseo se publica en Tribuna y suma seguidores")
	## Caducan el domingo sin castigo.
	m.semana = sem_voto + 1
	var saldo := c.saldo
	m.citas.semana(m, m.semana + 1)
	var vivas := 0
	for x: Dictionary in m.citas.lista:
		if x["estado"] == "pendiente" and int(x["semana"]) == sem_voto:
			vivas += 1
	_comprobar(vivas == 0 and c.saldo == saldo and m.directiva.confianza >= conf0 - 20, "las citas de la semana pasada caducan sin castigo")
	m.semana = antes
	## Guardar y cargar.
	var d := m.citas.a_dic()
	var c2 := Citas.new()
	c2.desde_dic(d)
	_comprobar(c2.lista.size() == m.citas.lista.size() and c2.favor_agente == m.citas.favor_agente, "las citas sobreviven a guardar y cargar")
	var inst := Partida.instantanea(m)
	_comprobar(inst.has("citas"), "y van en la instantánea de la partida")
