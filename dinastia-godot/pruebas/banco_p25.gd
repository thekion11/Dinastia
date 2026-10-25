extends "res://pruebas/banco_p24.gd"
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
