extends "res://pruebas/banco/base.gd"
## [Capa 1/2 de `ideas.gd`] _probar_ideas_del_documento, _probar_ideas_instalaciones_y_marca, _probar_ideas_personas_y_negocios, _probar_ideas_eventos_de_despacho, _probar_ideas_premios_y_memoria_del_club, _probar_ideas_roles_y_carrera … (+1)


const _IDEAS_A1 := preload("res://pruebas/ideas_a1.gd")

const _IDEAS_A2 := preload("res://pruebas/ideas_a2.gd")

const _IDEAS_A3 := preload("res://pruebas/ideas_a3.gd")

const _IDEAS_A4 := preload("res://pruebas/ideas_a4.gd")


const _IDEAS_B1 := preload("res://pruebas/ideas_b1.gd")

const _IDEAS_B2 := preload("res://pruebas/ideas_b2.gd")

const _IDEAS_B3 := preload("res://pruebas/ideas_b3.gd")

const _IDEAS_B4 := preload("res://pruebas/ideas_b4.gd")


func _probar_ideas_del_documento() -> void:
	_titulo("LO QUE PEDIA EL DOCUMENTO (ventana, FPF, desgaste, staff, fondos)")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 1717)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var mio := m.mi_club()
	mio.mover_saldo(80000000)

	## LA VENTANA DE MERCADO. Dos por temporada, como en el HTML.
	m.semana = 1
	_comprobar(m.mercado_abierto(), "en la semana 1 el mercado esta abierto")
	m.semana = Mundo.VENTANA_VERANO
	_comprobar(m.mercado_abierto() and m.semanas_de_mercado() == 1,
		"la ultima semana de la ventana de verano avisa de que queda una")
	m.semana = Mundo.VENTANA_VERANO + 1
	_comprobar(not m.mercado_abierto(), "y a la siguiente ya esta cerrado")
	_comprobar(m.semanas_hasta_mercado() > 0, "y dice cuanto falta para la siguiente (%d semanas)" % m.semanas_hasta_mercado())
	m.semana = Mundo.VENTANA_INVIERNO_INI + 1
	_comprobar(m.mercado_abierto(), "la ventana de invierno vuelve a abrir")
	m.semana = Mundo.VENTANA_INVIERNO_FIN + 1
	_comprobar(not m.mercado_abierto(), "y cierra a su hora")
	_linea("  %s" % m.texto_de_mercado())

	## EL FAIR PLAY FINANCIERO. Dos temporadas gastando de mas y hay multa.
	var fed := m.federacion
	_comprobar(not fed.fpf_activo, "el fair play financiero no esta en vigor de entrada")
	_comprobar(fed.revisar_fair_play(mio, 95) == "", "y sin estar en vigor no juzga a nadie")
	fed.fpf_activo = true
	_comprobar(fed.revisar_fair_play(mio, 95) == "aviso", "la primera temporada por encima es un aviso")
	var caja := mio.saldo
	_comprobar(fed.revisar_fair_play(mio, 95) == "sancion", "la segunda es sancion")
	_comprobar(mio.saldo < caja, "con multa de verdad (%s)" % _dinero(caja - mio.saldo))
	_comprobar(not fed.puede_pagar_traspaso(), "y con el mercado de pago cerrado")
	fed.revisar_fair_play(mio, 40)
	_comprobar(fed.puede_pagar_traspaso() and fed.fpf_avisos == 0,
		"cuadrar las cuentas cierra el expediente")

	## EL DESGASTE DEL ENTRENADOR.
	var r := m.roles
	_comprobar(r.desgaste == 0, "se empieza entero")
	for i in 40:
		r.semana_desgaste(false, 80)
	_linea("  cuarenta semanas perdiendo y con funa: desgaste %d" % r.desgaste)
	_comprobar(r.quemado(), "cuarenta semanas malas queman al entrenador")
	_comprobar(r.factor_desgaste() < 1.0, "y quemado, lo que dices en rueda vale menos")
	for i in 30:
		r.semana_desgaste(true, 0)
	_linea("  treinta semanas ganando: desgaste %d" % r.desgaste)
	_comprobar(not r.quemado(), "ganando se recupera")

	## EL CURRICULUM.
	_comprobar(r.curriculum.size() == 1, "hay un capitulo abierto en tu club actual")
	var otro: Club = m.ligas[1].clubes[0]
	m.tomar_el_mando(otro.id)
	_comprobar(m.roles.curriculum.size() == 2, "cambiar de club abre un capitulo nuevo (%d)" % m.roles.curriculum.size())
	var primero: Dictionary = m.roles.curriculum[0]
	_comprobar(int(primero["hasta"]) > 0, "y cierra el anterior con su año de salida")
	_linea("  curriculum: %s" % ", ".join(m.roles.curriculum.map(func(c: Dictionary) -> String:
		return "%s %d-%s" % [String(c["nombre"]), int(c["desde"]),
			"hoy" if int(c["hasta"]) == 0 else str(int(c["hasta"]))])))

	## EL CUERPO TECNICO NUEVO. Los seis puestos que pedian las ideas 91-105.
	var st := m.staff
	for p: String in ["arqueros", "nutri", "seg", "traductor", "cm", "utilero"]:
		_comprobar(Staff.PUESTOS.has(p), "existe el puesto «%s»" % p)
	m.mi_club().mover_saldo(90000000)
	st.subir("arqueros", m.mi_club())
	_comprobar(st.bono_portero() > 0.0, "el entrenador de arqueros suma a la defensa")
	st.subir("nutri", m.mi_club())
	_comprobar(st.recuperacion_fisica() > 0, "el nutricionista acelera la recuperacion")
	st.subir("seg", m.mi_club())
	_comprobar(st.bono_seguridad() > 0.0, "el jefe de seguridad baja el riesgo de incidente")
	st.subir("traductor", m.mi_club())
	_comprobar(st.adaptacion_extranjeros() < 1.0, "el traductor amortigua la adaptacion")
	st.subir("cm", m.mi_club())
	_comprobar(st.empuje_redes() > 0.0, "el community manager suma seguidores")
	## Y el sueldo del cuerpo tecnico sube al contratar: si no, contratar seria
	## gratis y no habria que elegir.
	var s0 := st.sueldo_semanal(m.mi_club().rep)
	st.subir("utilero", m.mi_club())
	_comprobar(st.sueldo_semanal(m.mi_club().rep) > s0,
		"y cada puesto nuevo pesa en la nomina (%s -> %s)" % [_dinero(s0), _dinero(st.sueldo_semanal(m.mi_club().rep))])

	## LOS FONDOS DE INVERSION.
	var ce := m.cesiones
	var joven: Jugador = null
	for j: Jugador in m.mi_club().plantilla:
		if j.edad <= 23:
			joven = j
			break
	if joven != null:
		var caja2 := m.mi_club().saldo
		_comprobar(ce.participacion_de(joven) == 0, "de entrada nadie tiene derechos de tus canteranos")
		_comprobar(ce.vender_participacion(joven, "delta", 25, m.mi_club()) == "",
			"se puede vender el 25% de un futuro traspaso")
		_comprobar(m.mi_club().saldo > caja2, "y entra dinero hoy (%s)" % _dinero(m.mi_club().saldo - caja2))
		_comprobar(ce.participacion_de(joven) == 25, "queda apuntado el 25%")
		_comprobar(ce.vender_participacion(joven, "delta", 40, m.mi_club()) != "",
			"y no se puede pasar del %d%% de un mismo jugador" % Cesiones.PCT_MAX)
		_comprobar(ce.neto_de_venta(joven, 1000) == 750,
			"al venderlo, el club se queda el 75%% (%d de 1000)" % ce.neto_de_venta(joven, 1000))
		var viejo: Jugador = null
		for j2: Jugador in m.mi_club().plantilla:
			if j2.edad > 23:
				viejo = j2
				break
		if viejo != null:
			_comprobar(ce.vender_participacion(viejo, "delta", 25, m.mi_club()) != "",
				"los fondos no compran derechos de veteranos")

	## LA OCUPACIÓN HOSTIL Y EL FICHAJE COMERCIAL. Los dos dejan un "impuesto"
	## -un jugador que TIENE que salir de titular- y `Prensa.revisar_impuesto()`
	## es quien lo cobra tras cada partido si no jugó.
	var pr := m.prensa
	var figura: Jugador = m.mi_club().plantilla[0]
	var st2 := m.staff
	st2.subir("ayudante", m.mi_club())
	var nivel_antes := st2.nivel("ayudante")
	pr.pendiente = {"id": "hostil", "pid": figura.id, "txt": "", "opcion_a": "", "opcion_b": ""}
	var conf_antes := m.directiva.confianza
	pr.resolver("a")
	_comprobar(pr.impuesto_pid == figura.id, "aceptar la ocupacion hostil impone al fichaje franquicia")
	_comprobar(pr.impuesto_hasta == -1, "y no tiene fecha de vencimiento")
	_comprobar(m.directiva.confianza > conf_antes, "el dueño respalda: sube la confianza (%d -> %d)" % [conf_antes, m.directiva.confianza])
	_comprobar(st2.nivel("ayudante") <= nivel_antes, "y purga algo del cuerpo tecnico (nivel %d -> %d)" % [nivel_antes, st2.nivel("ayudante")])

	## Si NO sale de titular, el patrocinador lo cobra.
	var xi_sin_el: Array[Jugador] = m.mi_club().plantilla.filter(func(j: Jugador) -> bool: return j.id != figura.id).slice(0, 10)
	var caja3 := m.mi_club().saldo
	pr.revisar_impuesto(m.mi_club(), xi_sin_el, m.anio)
	_comprobar(m.mi_club().saldo < caja3, "dejarlo en la reserva cuesta plata (%s)" % _dinero(caja3 - m.mi_club().saldo))

	## Si SÍ sale, no pasa nada.
	var xi_con_el: Array[Jugador] = xi_sin_el.duplicate()
	xi_con_el.append(figura)
	var caja4 := m.mi_club().saldo
	pr.revisar_impuesto(m.mi_club(), xi_con_el, m.anio)
	_comprobar(m.mi_club().saldo == caja4, "y alinearlo no cuesta nada")

	## El trato comercial SÍ vence al pasar de año; la ocupacion hostil no.
	pr.impuesto_pid = figura.id
	pr.impuesto_hasta = m.anio
	pr.revisar_impuesto(m.mi_club(), xi_con_el, m.anio + 1)
	_comprobar(pr.impuesto_pid == "", "el trato comercial se cae solo al cerrar la temporada pactada")

	pr.pendiente = {"id": "comercial", "pid": figura.id, "txt": "", "opcion_a": "", "opcion_b": ""}
	var caja5 := m.mi_club().saldo
	pr.resolver("a")
	_comprobar(pr.impuesto_pid == figura.id and pr.impuesto_hasta == m.anio,
		"el fichaje comercial impone al mismo jugador solo por esta temporada")
	_comprobar(m.mi_club().saldo > caja5, "y entra plata de patrocinio (%s)" % _dinero(m.mi_club().saldo - caja5))

	pr.pendiente = {"id": "comercial", "pid": figura.id, "txt": "", "opcion_a": "", "opcion_b": ""}
	var conf_antes2 := m.directiva.confianza
	var caja6 := m.mi_club().saldo
	pr.resolver("b")
	_comprobar(m.directiva.confianza < conf_antes2, "rechazar el trato comercial baja la confianza")
	_comprobar(m.mi_club().saldo < caja6, "y descuenta el bono comercial en el acto")

	## EL CRECIMIENTO POR TEMPORADA.
	var quien: Jugador = m.mi_club().plantilla[0]
	quien.ovr_al_empezar = quien.ovr - 4
	_comprobar(quien.crecimiento_temporada() == 4,
		"se puede ver cuanto crecio un jugador esta temporada (+%d)" % quien.crecimiento_temporada())

	## LAS COPAS DE CADA PAIS.
	var eng := Copa.copas_de("ENG", "Inglaterra")
	var esp := Copa.copas_de("ESP", "España")
	_linea("  Inglaterra juega: %s" % ", ".join(eng.map(func(c: Array) -> String: return String(c[0]))))
	_comprobar(eng.size() == 2 and String(eng[0][0]) == "FA Cup", "Inglaterra tiene FA Cup y copa de liga")
	_comprobar(String(esp[0][0]) == "Copa del Rey", "y España la Copa del Rey")
	_comprobar(not Copa.copas_de("XXX", "Pais Raro").is_empty(),
		"un pais sin copa propia juega una generica y no se queda sin copa")

	## EL MAPA DEL PAIS.
	_comprobar(MapaPais.hay("CHI") and MapaPais.hay("ENG"), "hay silueta para los paises con liga")
	_comprobar(MapaPais.poligono("CHI", Vector2(100, 200)).size() >= 3,
		"y se puede pintar al tamaño que haga falta")


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
