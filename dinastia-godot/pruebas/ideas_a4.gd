extends "res://pruebas/ideas_base.gd"
## Ideas del dueño (lote a, a4): finanzas, deuda, directorio y carrera. La ciudad vive en `ideas_a4b.gd`.

const _A4B := preload("res://pruebas/ideas_a4b.gd")

func ejecutar() -> void:
	_ideas_a_balance()
	_ideas_a_deuda()
	_ideas_a_insolvencia()
	_ideas_a_directorio()
	_ideas_a_carrera()
	_A4B.new(b).ejecutar()

func _textos(nodo: Node, salida: Array) -> void:
	if nodo is Label:
		salida.append((nodo as Label).text)
	for h in nodo.get_children():
		_textos(h, salida)

func _ideas_a_balance() -> void:
	var m := _mundo_ideas(2641)
	var c := m.mi_club()
	c.mover_saldo(90000000 - c.saldo)
	var paleta := {"suave": Color.GRAY, "verde": Color.GREEN, "rojo": Color.RED, "texto": Color.WHITE, "oro": Color.GOLD, "escala": 1.0}
	var fin := Finanzas.new(c, 0.0, 0, 0.0)
	var proy := fin.proyeccion_anual(19, 0)
	var lista := VBoxContainer.new()
	PanelFinanzas.pintar_balance_y_caja(lista, c, m, proy, paleta)
	var tx: Array = []
	_textos(lista, tx)
	var plantel := 0
	for j: Jugador in c.plantilla:
		plantel += j.valor
	var obras := 0
	for k: String in Instalaciones.CATALOGO:
		obras += m.obras.nivel(k) * int((Instalaciones.CATALOGO[k] as Array)[2]) / 2
	var activo := c.saldo + plantel + obras
	## Los textos van en parejas etiqueta/valor.
	var datos := {}
	for i in range(0, tx.size() - 1):
		datos[tx[i]] = tx[i + 1]
	_comprobar(String(datos.get("TOTAL ACTIVO", "")) == Eco.dinero(activo) and String(datos.get("Valor del plantel", "")) == Eco.dinero(plantel), "el balance suma caja + plantel + instalaciones: activo %s (642)" % Eco.dinero(activo))
	_comprobar(String(datos.get("PATRIMONIO NETO", "")) == Eco.dinero(activo) and String(datos.get("Pasivo exigible", "")) == "sin deuda", "sin deuda el patrimonio neto es todo el activo (642)")
	m.banco.pedir(0, c)
	var lista2 := VBoxContainer.new()
	PanelFinanzas.pintar_balance_y_caja(lista2, c, m, proy, paleta)
	var tx2: Array = []
	_textos(lista2, tx2)
	var d2 := {}
	for i in range(0, tx2.size() - 1):
		d2[tx2[i]] = tx2[i + 1]
	var deuda := int(m.banco.prestamos[0]["deuda"])
	var activo2 := c.saldo + plantel + obras
	_comprobar(String(d2.get("Pasivo exigible", "")) == Eco.dinero(deuda) and String(d2.get("PATRIMONIO NETO", "")) == Eco.dinero(activo2 - deuda), "con un crédito el pasivo es la deuda (%s) y el patrimonio es activo menos pasivo (642)" % Eco.dinero(deuda))
	var mensual := int(proy["resultado"]) / 12
	var saldo := c.saldo
	for i in 12:
		saldo += mensual
	_comprobar(String(d2.get("Dentro de 12 meses", "")) == Eco.dinero(saldo) and d2.has("Punto más bajo"), "el flujo de caja proyecta doce meses de resultado mensual y marca el punto más bajo (643)")
	lista.free()
	lista2.free()

func _ideas_a_deuda() -> void:
	var m := _mundo_ideas(2642)
	var c := m.mi_club()
	var bk: Banco = m.banco
	c.mover_saldo(1000000 - c.saldo)
	## Deuda con tasa e intereses visibles (647).
	var tasas := []
	for i in Banco.BANCOS.size():
		tasas.append(float(Banco.BANCOS[i][1]))
	_comprobar(tasas == [0.010, 0.014, 0.022], "hay tres bancos con tasa semanal 1,0%, 1,4% y 2,2% (647)")
	var s0 := c.saldo
	_comprobar(bk.pedir(1, c) == "" and bk.prestamos.size() == 1, "se pide un crédito y entra el dinero (647)")
	var p: Dictionary = bk.prestamos[0]
	var monto := int(p["deuda"])
	_comprobar(c.saldo == s0 + monto and int(p["cuota"]) == Banco.cuota_francesa(monto, 0.014, 40), "con cuota francesa fija (%d por semana) (647)" % int(p["cuota"]))
	var s1 := c.saldo
	bk.semana(c)
	var interes := int(round(float(monto) * 0.014))
	_comprobar(c.saldo == s1 - int(p["cuota"]) and int(p["deuda"]) == monto + interes - int(p["cuota"]) and int(p["restan"]) == 39, "cada semana se cobra la cuota y la deuda crece con su interés (%d) (647)" % interes)
	## Renegociación (649).
	var tasa0 := float(p["tasa"])
	var cuota0 := int(p["cuota"])
	var restan0 := int(p["restan"])
	_comprobar(bk.renegociar(0) == "" and absf(float(p["tasa"]) - tasa0 * 1.35) < 0.00001 and int(p["restan"]) == int(round(float(restan0) * 1.6)) and int(p["cuota"]) < cuota0 and bool(p["renegociado"]), "renegociar alarga el plazo x1,6, sube la tasa x1,35 y baja la cuota (%d → %d) (649)" % [cuota0, int(p["cuota"])])
	_comprobar(bk.renegociar(0) != "", "pero solo una vez (649)")
	## Bono social de la hinchada (664).
	var s2 := c.saldo
	_comprobar(bk.emitir_bono(c) == "" and c.saldo > s2 and bool(bk.prestamos[1]["bono"]) and absf(float(bk.prestamos[1]["tasa"]) - 0.005) < 0.00001, "se emite un bono social a la tasa baja de 0,5%% (664)")
	_comprobar(bk.emitir_bono(c) != "" and bk.pedir(0, c) != "", "y no caben más de dos líneas de deuda (664)")
	bk.prepagar(1, c)
	_comprobar(bk.emitir_bono(c) == "", "prepagar libera cupo (664)")
	## Mora, veedor y liquidación (654, 657).
	var bk2 := Banco.new()
	var rojo := Club.new()
	rojo.saldo = -5000000
	rojo.rep = 50
	var liquidados := []
	bk2.liquidado.connect(func() -> void: liquidados.append(1))
	for i in 3:
		bk2.semana(rojo)
	_comprobar(not bk2.en_mora() and bk2.estado(rojo)["estado"] == "SOBREGIRO", "las primeras semanas en rojo son sobregiro (654)")
	bk2.semana(rojo)
	_comprobar(bk2.en_mora() and bk2.estado(rojo)["estado"] == "EN MORA" and bk2.pedir(0, rojo) != "", "a la cuarta semana el club está en mora y ningún banco le abre una línea (654)")
	for i in 4:
		bk2.semana(rojo)
	_comprobar(bk2.hay_veedor() and not bk2.liquidado_ya, "a la octava semana llega el veedor (657)")
	for i in 4:
		bk2.semana(rojo)
	_comprobar(bk2.liquidado_ya and liquidados.size() == 1 and bk2.semanas_en_rojo == 12, "a las 12 semanas en rojo el club se liquida y salta la señal de fin (657)")
	rojo.saldo = 50000000
	var bk3 := Banco.new()
	bk3.semanas_en_rojo = 6
	bk3.semana(rojo)
	_comprobar(bk3.semanas_en_rojo == 0, "volver al azul pone a cero el contador (657)")

func _ideas_a_insolvencia() -> void:
	var m := _mundo_ideas(2643)
	var c := m.mi_club()
	var ins: Insolvencia = m.insolvencia
	var liga: Liga = m.liga_de(c)
	## Sanción deportiva por deuda (653) y administrador externo (658).
	liga.tabla_puntos[c.id]["pts"] = 30
	m.banco.semanas_en_rojo = Banco.SEM_VEEDOR
	var masa := c.masa_salarial()
	var n0 := c.plantilla.size()
	var caro: Jugador = c.plantilla[0]
	for j: Jugador in c.plantilla:
		if j.sueldo > caro.sueldo:
			caro = j
	for k: Club in m.clubes.values():
		if k != c:
			k.saldo = 900000000
			while k.plantilla.size() > 20:
				k.plantilla.pop_back()
	ins.semana(m)
	var fila = liga.tabla_puntos[c.id]
	_comprobar(int(fila["pts"]) + int(fila.get("sancion", 0)) * 0 <= 30 - Insolvencia.PUNTOS_SANCION or int(fila.get("sancion", 0)) == Insolvencia.PUNTOS_SANCION, "con veedor la federación resta %d puntos en la tabla (653)" % Insolvencia.PUNTOS_SANCION)
	_comprobar(ins.tope_salarial == int(round(float(masa) * Insolvencia.TOPE)), "el administrador fija un tope salarial del 80%% de la masa (%d) (658)" % ins.tope_salarial)
	_comprobar(c.plantilla.size() == n0 - 1 and not c.plantilla.has(caro), "y obliga a vender al jugador más caro para cumplirlo (658)")
	var pts := int(liga.tabla_puntos[c.id]["pts"])
	ins.semana(m)
	_comprobar(int(liga.tabla_puntos[c.id]["pts"]) == pts, "la sanción de puntos se aplica una sola vez por temporada (653)")
	## Reorganización para salvar al club (656).
	var antes_rep := c.rep
	m.banco.prestamos.append({"banco": "X", "deuda": 5000000, "tasa": 0.01, "cuota": 100000, "restan": 20, "renegociado": false, "bono": false})
	ins.pendiente = {"id": "refundacion", "texto": "", "a": "Refundar", "b": "Liquidar"}
	var res := ins.resolver(m, "a")
	_comprobar(m.banco.prestamos.is_empty() and m.banco.semanas_en_rojo == 0 and c.rep == maxi(5, antes_rep - 12) and ins.tope_salarial == 0 and String(res["titulo"]).contains("refunda"), "refundar el club perdona la deuda, pone a cero las semanas en rojo y cuesta 12 de reputación (656)")
	ins.pendiente = {"id": "refundacion", "texto": "", "a": "Refundar", "b": "Liquidar"}
	var res2 := ins.resolver(m, "b")
	_comprobar(String(res2["titulo"]) == "Sin refundación", "y rechazarla deja que se liquide (656)")

func _ideas_a_directorio() -> void:
	var m := _mundo_ideas(2644)
	var c := m.mi_club()
	var jt: Junta = m.junta
	jt.formar(c)
	## Accionistas con intereses distintos (688) y directorio con personalidad (697).
	_comprobar(jt.accionistas.size() == 3 and Junta.ESTILOS.has(String(jt.presidente["estilo"])), "el directorio tiene presidente con estilo (%s) y tres accionistas (688, 697)" % String(jt.presidente["estilo"]))
	var exigencias := {}
	var pct := 0
	for a: Dictionary in jt.accionistas:
		exigencias[String(a["exige"])] = true
		pct += int(a["pct"])
		_comprobar(Junta.EXIGENCIAS.has(String(a["exige"])) and int(a["pct"]) >= 12 and int(a["humor"]) == 60, "el accionista %s (%d%%) exige «%s» (688)" % [a["nombre"], a["pct"], Junta.EXIGENCIAS[a["exige"]]])
	var estilos := {}
	var exig_distintas := {}
	for k: Club in m.ligas[0].clubes:
		var j2 := Junta.new()
		j2.formar(k)
		estilos[String(j2.presidente["estilo"])] = true
		for a: Dictionary in j2.accionistas:
			exig_distintas[String(a["exige"])] = true
	_comprobar(estilos.size() >= 2 and exig_distintas.size() >= 3, "según el club cambian los estilos de presidente (%d) y las exigencias (%d) (688, 697)" % [estilos.size(), exig_distintas.size()])
	## La junta cada 13 semanas da la palabra al más descontento (688).
	jt.accionistas[1]["humor"] = 30
	jt.semana(c, m.anio, 13)
	_comprobar(not jt.pendiente.is_empty() and jt.pendiente["quien"] == jt.accionistas[1]["nombre"], "cada 13 semanas la junta le da la palabra al accionista más descontento (688)")
	var otros := [int(jt.accionistas[0]["humor"]), int(jt.accionistas[2]["humor"])]
	var h1 := int(jt.accionistas[1]["humor"])
	jt.resolver("a", c, m.directiva, m.prensa)
	_comprobar(int(jt.accionistas[1]["humor"]) == h1 + 18 and int(jt.accionistas[0]["humor"]) == otros[0] and int(jt.accionistas[2]["humor"]) == otros[1], "complacerle sube su humor 18 puntos y no toca el de los demás (688)")
	## Voto de censura (684).
	jt.accionistas[2]["humor"] = 20
	jt.pendiente = {"quien": jt.accionistas[2]["nombre"], "exige": "titulos", "monto": 0, "tema": "t", "a": "Prometer", "b": "Paciencia"}
	var conf0 := m.directiva.confianza
	var r := jt.resolver("b", c, m.directiva, m.prensa)
	_comprobar(bool(r["censura"]) and m.directiva.confianza == conf0 - 10 - 2 and int(jt.accionistas[2]["humor"]) == 40, "decirle que no a un accionista ya enfadado provoca una moción de censura que cuesta 10 de confianza (684)")
	## Paciencia del directorio como barra (701), despido (702).
	var d: Directiva = m.directiva
	d.confianza = 90
	var alta := d.humor()
	d.confianza = 30
	var media := d.humor()
	_comprobar(alta != media and alta.contains("diez años") and media.contains("impacientarse"), "la barra de confianza se traduce en frases distintas (701)")
	d.confianza = 60
	var avisos := []
	d.despedido.connect(func(motivo: String) -> void: avisos.append(motivo))
	d.mover_confianza(-90, "prueba")
	_comprobar(d.confianza == 0 and d.despedido_ya and avisos.size() == 1 and d.humor() == "Estás despedido", "al llegar a cero el directorio te despide y avisa (701)")
	## Socios que crecen o decrecen (685) y cuota social estable (686).
	var rep: Reputacion = m.roles.reputacion
	var antes := rep.socios_por_temporada(c)
	rep.registrar("social", 40, "prueba")
	var sube := rep.socios_por_temporada(c)
	rep.registrar("social", -90, "prueba")
	var baja := rep.socios_por_temporada(c)
	_comprobar(sube > antes and baja < 0, "cuidar a la gente suma socios por temporada (+%d) y despreciarla los resta (%d) (685)" % [sube, baja])
	var h: Hinchada = m.hinchada
	c.mover_saldo(900000000)
	var s0 := c.saldo
	var ing := h.campana_abonos(c, 80, 2)
	_comprobar(ing > 0 and c.saldo == s0 + ing and h.abonados > 0 and h.abonados < c.estadio_aforo, "la campaña de abonos fija abonados (%d) y cobra por adelantado (685)" % h.abonados)
	var h2 := Hinchada.new(m)
	h2.campana_abonos(c, 20, 0)
	_comprobar(h2.abonados < h.abonados, "y con la gente de mal humor hay menos abonados (%d contra %d) (685)" % [h2.abonados, h.abonados])
	var fin := Finanzas.new(c, 0.0, 0, 0.0)
	var s1 := c.saldo
	var q1 := fin.cuotas_socios()
	var q2 := fin.cuotas_socios()
	_comprobar(q1 == c.socios * 2 and q2 == q1 and c.saldo == s1 + q1 * 2, "las cuotas de socios son un ingreso fijo y predecible: socios × 2 cada semana (%d) (686)" % q1)
	c.socios += 1000
	_comprobar(fin.cuotas_socios_base() == q1 + 2000, "y crecen con el padrón (686)")

func _ideas_a_carrera() -> void:
	var m := _mundo_ideas(2645)
	var c := m.mi_club()
	var r: Roles = m.roles
	## Multipropiedad (667, 696).
	var otro: Club = m.ligas[1].clubes[2]
	_comprobar(r.comprar_filial(otro).begins_with("hace falta la habilidad"), "sin la habilidad «Magnate» no se compran clubes (667)")
	m.entrenamiento.dt_nodos["magnate"] = true
	r.patrimonio = 0
	_comprobar(r.comprar_filial(otro).begins_with("te faltan"), "con la habilidad hace falta patrimonio personal (667)")
	var precio := r.precio_filial(otro)
	r.patrimonio = precio * 3
	_comprobar(r.comprar_filial(c) != "" and r.comprar_filial(otro) == "" and r.patrimonio == precio * 2 and r.filiales.has(otro.id), "se compra un club de otro país y el patrimonio baja su precio (%d) (667, 696)" % precio)
	_comprobar(r.comprar_filial(otro) == "ya es tuyo", "pero no dos veces ni el propio club")
	m.semana = 12
	var p0 := r.patrimonio
	r.semana_filiales()
	_comprobar(r.patrimonio == p0 + otro.rep * otro.rep * 40, "cada 12 semanas el club filial paga dividendos según su tamaño (+%d) (667, 696)" % (r.patrimonio - p0))
	m.semana = 5
	var p1 := r.patrimonio
	r.semana_filiales()
	_comprobar(r.patrimonio == p1, "y no en otras semanas (667)")
	## Director deportivo con autonomía delegable (698).
	r.rol = Roles.DIR
	r.dt_empleado = {"nombre": "Don Pedro", "estilo": "motivador", "sintonia": 60, "confianza": 50}
	r.fijar_directriz("rotacion", true)
	_comprobar(bool(r.directrices["rotacion"]) and int(r.dt_empleado["sintonia"]) == 58, "delegar una directriz al DT empleado desgasta la relación (60 → 58) (698)")
	r.dt_empleado["sintonia"] = 100
	var obedece_alto := 0
	for i in 200:
		if r.dt_obedece():
			obedece_alto += 1
	r.dt_empleado["sintonia"] = 0
	var obedece_bajo := 0
	for i in 200:
		if r.dt_obedece():
			obedece_bajo += 1
	_comprobar(obedece_alto > obedece_bajo + 50 and obedece_bajo < 150, "el DT empleado hace caso según la sintonía: alta %d de 200, baja %d (698)" % [obedece_alto, obedece_bajo])
	## Ofertas de otros clubes (703) y reputación profesional (706).
	r.rol = Roles.DT
	r.prestigio = 40
	m.semana = 30
	var sin := 0
	for i in 600:
		r.oferta_de_club = {}
		r._ultima_oferta = 0
		if not r.sortear_oferta_de_club().is_empty():
			sin += 1
	r.sumar_prestigio(50)
	var con := 0
	for i in 600:
		r.oferta_de_club = {}
		r._ultima_oferta = 0
		if not r.sortear_oferta_de_club().is_empty():
			con += 1
	_comprobar(sin == 0 and r.prestigio == 90 and con >= 10, "con poco prestigio nadie te llama y con mucho llegan ofertas (%d en 600 semanas) (703, 706)" % con)
	var of := r.oferta_de_club
	r.oferta_de_club = {}
	r._ultima_oferta = 0
	while r.sortear_oferta_de_club().is_empty():
		r._ultima_oferta = 0
	of = r.oferta_de_club
	_comprobar(of.has("club_id") and int(of["mejora"]) > 0 and int(of["sueldo"]) > 0, "la oferta es de un club mejor y con sueldo (703)")
	var conf0 := m.directiva.confianza
	var msg := r.responder_oferta_de_club(false)
	_comprobar(m.directiva.confianza == conf0 + 4 and r.oferta_de_club.is_empty() and msg.contains("se agradece"), "rechazarla sube 4 puntos la confianza del directorio actual (703)")
	## Despido y búsqueda de un nuevo cargo (702) y currículum (709).
	r.prestigio = 50
	r.abrir_capitulo(c.id, c.nombre, 2026)
	r.sumar_trofeo("Liga")
	r.sumar_trofeo("Liga")
	r.sumar_trofeo("Copa")
	r.quedar_sin_banco()
	r.cerrar_capitulo(c.id, c.nombre, 2029, "despido")
	_comprobar(r.sin_club and r.historial.size() == 1 and r.historial[0]["club"] == c.nombre, "el despido te deja sin club y queda en el historial (702, 709)")
	var cv: Dictionary = r.curriculum[0]
	_comprobar(int(cv["desde"]) == 2026 and int(cv["hasta"]) == 2029 and cv["motivo"] == "despido" and int(cv["trofeos"]) == 3, "el currículum recoge años, motivo de salida y títulos (709)")
	var pal := r.palmares_por_tipo()
	var ligas := 0
	for f: Dictionary in pal:
		if String(f.get("titulo", f.get("nombre", ""))) == "Liga":
			ligas = int(f.get("n", f.get("veces", 0)))
	_comprobar(pal.size() == 2 and ligas == 2, "y el palmarés agrupa «Liga ×2, Copa ×1» (709)")
	var ofertas := r.ofertas_trabajo()
	var ids_ok := not ofertas.is_empty() and ofertas.size() <= 3
	for k: Club in ofertas:
		ids_ok = ids_ok and k.id != m.mi_club_id and k.division > 0
	_comprobar(ids_ok, "sin banco te ofrecen entre 1 y 3 clubes distintos del tuyo (702): %d" % ofertas.size())
	var nuevo := ofertas[0]
	_comprobar(r.aceptar_trabajo(nuevo.id) == "" and m.mi_club_id == nuevo.id and not r.sin_club and r.aceptar_trabajo("no_existe") != "", "se acepta un nuevo cargo y se asume el mando; un club inexistente se rechaza (702)")
