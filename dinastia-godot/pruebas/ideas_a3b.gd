extends "res://pruebas/ideas_base.gd"
## Ideas del dueño (lote a, a3b): mercado, cesiones, negociación, agentes y reglas de plantilla.

func ejecutar() -> void:
	_ideas_a_fichajes_y_cesiones()
	_ideas_a_negociacion()
	_ideas_a_agentes()
	_ideas_a_reglas_y_asuntos()

func _ideas_a_fichajes_y_cesiones() -> void:
	var m := _mundo_ideas(2631)
	var c := m.mi_club()
	c.mover_saldo(900000000)
	## Libres todo el año (583): con el mercado cerrado se ficha igual.
	m.semana = 10
	_comprobar(not m.roles.ventana_abierta(), "la semana 10 el mercado está cerrado")
	if m.libres.is_empty():
		m.generar_libres()
	var antes := c.plantilla.size()
	var fichado := false
	var firmado: Jugador = null
	for i in 12:
		if m.libres.is_empty():
			m.generar_libres()
		var objetivo: Jugador = m.libres[0]
		var res := m.fichar_libre(0, c)
		if res.has("ok"):
			fichado = true
			firmado = objetivo
			break
		_comprobar(res.has("rechazado") or res.has("error"), "o firma o rechaza, nunca queda en el aire")
	_comprobar(fichado and c.plantilla.size() == antes + 1 and c.plantilla.has(firmado) and firmado.club_id == c.id and not m.libres.has(firmado), "con el mercado cerrado se ficha a un libre y entra al plantel (583)")
	## Cesiones con opción y con obligación (584, 585).
	var j: Jugador = c.plantilla[4]
	j.edad = 25
	j.ovr = c.rep - 4
	j.tasar()
	var cd := m.cesiones.ceder_con_opcion(j, Cesiones.CESION_OBLIGA)
	_comprobar(not cd.has("error") and m.cesiones.esta_cedido(j.id) and j.club_id == (cd["destino"] as Club).id, "se cede con obligación de compra al club de destino (584)")
	var ces := m.cesiones.cesion_de(j.id)
	_comprobar(String(ces["tipo"]) == "obliga" and int(ces["opcion"]) == int(round(float(j.valor) * 0.85)) and float(ces["sueldo_pct"]) == 1.0, "la obligación fija el 85%% del valor y el destino paga todo el sueldo (584, 585)")
	_comprobar(m.cesiones.ahorro_salarial(c.id) == int(round(float(j.sueldo) * float(ces["sueldo_pct"]))), "el ahorro salarial del club cedente es el sueldo pagado por el destino (%d) (585)" % m.cesiones.ahorro_salarial(c.id))
	var casa_saldo := c.saldo
	var dest: Club = cd["destino"]
	var dest_saldo := dest.saldo
	var out := m.cesiones.resolver(m.anio + 1)
	_comprobar(out.size() == 1 and bool(out[0]["comprado"]) and dest.plantilla.has(j) and c.saldo == casa_saldo + int(ces["opcion"]) and dest.saldo == dest_saldo - int(ces["opcion"]), "al terminar la cesión con obligación el destino compra y paga %s (584)" % str(ces["opcion"]))
	var j2: Jugador = c.plantilla[6]
	j2.edad = 25
	var cd2 := m.cesiones.ceder_con_opcion(j2, Cesiones.CESION_OPCION)
	var ces2 := m.cesiones.cesion_de(j2.id)
	_comprobar(String(ces2["tipo"]) == "opcion" and int(ces2["opcion"]) == int(round(float(j2.valor) * 1.1)) and float(ces2["sueldo_pct"]) < 1.0 and float(ces2["sueldo_pct"]) >= 0.4, "la cesión con opción pide el 110%% del valor y el destino paga solo una parte del sueldo (%.0f%%) (584, 585)" % (float(ces2["sueldo_pct"]) * 100.0))
	var out2 := m.cesiones.resolver(m.anio + 1)
	_comprobar(out2.size() == 1 and (j2.club_id == c.id) == (not bool(out2[0]["comprado"])), "y al final el jugador o se compra o vuelve a casa (584)")
	## Porcentaje de futura venta como moneda (587).
	var obj: Jugador = (m.ligas[0].clubes[3] as Club).plantilla[2]
	var cl_vendedor := m.clubes.get(obj.club_id) as Club
	m.cesiones.pactar_porcentaje_de_venta(obj, 20, cl_vendedor.id)
	_comprobar(int(m.cesiones.porcentaje_pendiente(obj.id)["pct"]) == 20, "al fichar se pacta un 20% de la futura venta (587)")
	m.mercado.fichar(obj, c, 1000, obj.sueldo, 3)
	var c0 := c.saldo
	var v0 := cl_vendedor.saldo
	var comprador: Club = (m.ligas[0].clubes[5] as Club)
	comprador.mover_saldo(900000000)
	var venta := m.cesiones.vender(obj, comprador, 1000000, 0)
	_comprobar(int(venta["pagado_a_terceros"]) == 200000 and cl_vendedor.saldo == v0 + 200000 and c.saldo == c0 + 800000, "al vender, el club original cobra su 20%% (%s) y tú el resto (587)" % str(venta["pagado_a_terceros"]))
	var obj2: Jugador = c.plantilla[8]
	var c1 := c.saldo
	var venta2 := m.cesiones.vender(obj2, comprador, 1000000, 25)
	_comprobar(int(venta2["neto"]) == 700000 and c.saldo == c1 + 700000 and m.cesiones.plusvalias.size() == 1, "y guardarte un 25% de la próxima venta te hace cobrar 30%% menos hoy y deja una plusvalía pendiente (587)")
	## Pago en cuotas (590).
	var obj3: Jugador = (m.ligas[0].clubes[7] as Club).plantilla[1]
	var vend3 := m.clubes.get(obj3.club_id) as Club
	var of := Cesiones.nueva_oferta(1000000)
	of["cuotas"] = 600000
	var comp := m.cesiones.registrar_compromisos(obj3, of, c, vend3)
	_comprobar(int(comp["cuotas"]) == 600000 and m.cesiones.cuotas.size() == 1, "una parte del traspaso queda a plazos (590)")
	var cuota := int((m.cesiones.cuotas[0] as Dictionary)["cuota"])
	var s0 := c.saldo
	var e0 := vend3.saldo
	_comprobar(m.cesiones.pagar_cuotas(1, c).is_empty() and c.saldo == s0, "las cuotas no se pagan fuera de fin de temporada (590)")
	var pagos := m.cesiones.pagar_cuotas(Cesiones.SEMANAS_ENTRE_CUOTAS, c)
	_comprobar(pagos.size() == 1 and c.saldo == s0 - cuota and vend3.saldo == e0 + cuota, "cada fin de temporada sale una cuota de tu caja hacia el vendedor (%d) (590)" % cuota)
	## Terceros propietarios (593).
	var joven: Jugador = c.plantilla[10]
	joven.edad = 20
	joven.tasar()
	var of_f := m.cesiones.oferta_de_fondo(joven, "meridian", 20)
	_comprobar(of_f == int(round(float(joven.valor) * 0.2 * 0.62 * 1.15)), "un fondo ofrece menos del valor proporcional por un 20%% de los derechos (%s) (593)" % str(of_f))
	var s1 := c.saldo
	_comprobar(m.cesiones.vender_participacion(joven, "delta", 20, c) == "" and c.saldo > s1 and m.cesiones.participacion_de(joven) == 20, "se vende el 20% de sus derechos y entra dinero (593)")
	_comprobar(m.cesiones.vender_participacion(joven, "delta", 40, c) != "" and m.cesiones.neto_de_venta(joven, 1000) == 800, "no se pasa del 50%% y el neto de una venta descuenta la parte del fondo (593)")
	m.semana = 30
	var presion := m.cesiones.presion_de_fondo()
	_comprobar(not presion.is_empty() and presion["jugador"] == joven and int(presion["pct"]) == 20, "el fondo aparece a presionar para vender (593)")
	var mo0 := joven.moral
	m.cesiones.rechazar_presion(joven)
	_comprobar(joven.moral < mo0, "y negarse le baja la moral al chico (593)")
	## Guerra de ofertas (594).
	var estrella: Jugador = c.plantilla[2]
	estrella.ovr = 80
	for k: Club in m.clubes.values():
		k.mover_saldo(900000000)
		k.rep = 80
	var rival_inicial: Club = (m.ligas[0].clubes[9] as Club)
	m.mercado.ofertas_recibidas = [{"jugador": estrella, "club": rival_inicial, "monto": 1000000, "semana": m.semana, "clausula": false}]
	var total := 0
	for i in 40:
		total += m.mercado_av.guerra_de_ofertas(m)
	var pujas_ok := 0
	var mayor := true
	for o: Dictionary in m.mercado.ofertas_recibidas:
		if bool(o.get("puja", false)):
			pujas_ok += 1
			mayor = mayor and int(o["monto"]) > 1000000 and (o["club"] as Club) != rival_inicial
	_comprobar(total >= 1 and total <= MercadoAvanzado.MAX_PUJAS and pujas_ok == total and mayor, "otros clubes entran en la guerra con pujas cada vez mayores, hasta un tope de %d (%d pujas) (594)" % [MercadoAvanzado.MAX_PUJAS, total])
	## Jugador que rechaza tu club por falta de proyecto (595).
	var clubes_pais: Array = []
	for k: Club in m.clubes.values():
		if k.pais == c.pais and k.division == c.division and k != c:
			clubes_pais.append(k)
	var grande: Club = clubes_pais[0]
	var chico: Club = clubes_pais[1]
	grande.rep = 90
	chico.rep = 30
	var objetivo: Jugador = grande.plantilla[1]
	objetivo.pide_salir = false
	objetivo.moral = 70
	objetivo.anios_contrato = 3
	var dc := m.mercado.deseo_de_venir(objetivo, chico)
	var dg := m.mercado.deseo_de_venir(objetivo, grande)
	var razon := false
	for r: Dictionary in dc["razones"]:
		if String(r["txt"]).begins_with("Viene de un club más grande"):
			razon = true
	_comprobar(float(dc["p"]) < float(dg["p"]) and razon, "un jugador de un grande desea menos venir a un club modesto (%.0f%% contra %.0f%%) y dice por qué (595)" % [float(dc["p"]) * 100.0, float(dg["p"]) * 100.0])

func _ideas_a_negociacion() -> void:
	var m := _mundo_ideas(2632)
	var c := m.mi_club()
	c.mover_saldo(900000000)
	var obj: Jugador = (m.ligas[0].clubes[2] as Club).plantilla[3]
	var n := Negociacion.new(m, obj)
	## Intercambio más diferencia en dinero (586).
	var v0 := n.valor_percibido()
	var otro: Jugador = c.plantilla[5]
	n.poner_intercambio(otro)
	_comprobar(n.valor_percibido() - v0 == int(round(float(otro.valor) * 0.88)) and n.intercambio == otro, "añadir un jugador en la mesa suma el 88%% de su valor a la oferta (586)")
	n.poner_intercambio(otro)
	_comprobar(n.intercambio == null and n.valor_percibido() == v0, "y se puede retirar (586)")
	## Pago en cuotas, bonos y porcentaje valen distinto (590, 587).
	var base := n.valor_percibido()
	n.ajustar("cuotas", 2)
	var con_cuotas := n.valor_percibido() - base
	_comprobar(con_cuotas > 0 and con_cuotas < n.cuotas, "las cuotas valen para el vendedor menos que su cifra (%d de %d) (590)" % [con_cuotas, n.cuotas])
	n.ajustar("pct", 2)
	_comprobar(n.pct == 10 and n.valor_percibido() > base + con_cuotas, "el porcentaje de futura venta también cuenta como moneda (587)")
	## Paciencia del vendedor (610): ofertas ridículas la agotan.
	var n2 := Negociacion.new(m, (m.ligas[0].clubes[3] as Club).plantilla[2])
	var p0 := n2.paciencia
	n2.fijo = 1000
	n2.cuotas = 0
	n2.rival_id = ""
	var rondas := 0
	while n2.estado == "abierta" and rondas < 10:
		n2.enviar_oferta()
		rondas += 1
	_comprobar(n2.estado == "rota" and rondas <= p0 + 1 and p0 >= 3 and n2.paciencia <= 0, "con ofertas ridículas la paciencia del vendedor (%d) llega a cero y la mesa se rompe en %d rondas (610)" % [p0, rondas])
	## Competencia con otros clubes por el mismo objetivo (459).
	var con_rival := 0
	for i in 200:
		var rid := Negociacion._rival_en_juego(m, obj)
		if rid != "":
			con_rival += 1
			if rid == c.id or rid == obj.club_id or not m.clubes.has(rid):
				con_rival -= 1000
	_comprobar(con_rival >= 10 and con_rival < 200, "otro club puja a veces por el mismo objetivo, nunca el tuyo ni el vendedor (%d de 200 mesas) (459)" % con_rival)
	## Renovación preventiva (611).
	var j: Jugador = c.plantilla[2]
	j.anios_contrato = 1
	var pide := m.cantera.pide_para_renovar(j)
	var r1 := m.cantera.renovar(j)
	_comprobar(bool(r1.get("ok", false)) and j.sueldo == pide and j.anios_contrato >= 2, "renovar firma lo que pide (%d) y alarga el contrato a %d años (611)" % [pide, j.anios_contrato])
	var j3: Jugador = c.plantilla[3]
	j3.anios_contrato = 1
	var pide3 := m.cantera.pide_para_renovar(j3)
	var r3 := m.cantera.renovar(j3, true)
	_comprobar(j3.sueldo == int(round(float(pide3) * 0.9)) and int(r3["clausula"]) > 0, "con cláusula de salida acepta un 10%% menos de sueldo (611)")
	_comprobar(m.cantera.renovar((m.ligas[0].clubes[4] as Club).plantilla[0]).has("error"), "y solo se renueva a los propios (611)")
	## Reputación limpia y rentable en las negociaciones (608, 628).
	var rep: Reputacion = m.roles.reputacion
	var mc := rep.mult_compras()
	rep.registrar("honesto", 30, "prueba")
	_comprobar(rep.mult_compras() < mc, "la reputación limpia hace que los vendedores pidan menos (%.3f → %.3f) (628)" % [mc, rep.mult_compras()])
	var mv := rep.mult_ventas()
	rep.registrar("negociador", 20, "prueba")
	_comprobar(rep.mult_ventas() > mv, "las operaciones rentables mejoran lo que te pagan por vender (608)")
	var pedido_antes := m.mercado.valor_pedido(obj)
	rep.registrar("honesto", 40, "prueba")
	_comprobar(m.mercado.valor_pedido(obj) < pedido_antes, "y el precio que pide un rival por su jugador baja (%d → %d) (628)" % [pedido_antes, m.mercado.valor_pedido(obj)])

func _ideas_a_agentes() -> void:
	var m := _mundo_ideas(2633)
	var c := m.mi_club()
	c.mover_saldo(900000000)
	var cn: Cantera = m.cantera
	## Agentes con cartera propia (616).
	var ags := cn.agencias_del_plantel()
	var suma := 0
	var orden_ok := true
	for i in ags.size():
		suma += (ags[i]["jugadores"] as Array).size()
		if i > 0:
			orden_ok = orden_ok and (ags[i - 1]["jugadores"] as Array).size() >= (ags[i]["jugadores"] as Array).size()
	_comprobar(ags.size() >= 2 and suma == c.plantilla.size() and orden_ok, "tu plantel se reparte entre %d agencias con carteras de clientes ordenadas (616)" % ags.size())
	var same := true
	for j: Jugador in ags[0]["jugadores"]:
		same = same and String(cn.agente_de(j)["nombre"]) == String(ags[0]["agente"]["nombre"])
	_comprobar(same and cn.agente_de(c.plantilla[0]) == cn.agente_de(c.plantilla[0]), "el mismo jugador siempre tiene el mismo agente (616)")
	## Presión del agente (598) y confianza (617).
	var exig := {}
	for i in 600:
		exig = cn.sortear_guerra_agentes()
		if not exig.is_empty():
			break
	_comprobar(not exig.is_empty() and cn.hay_exigencia() and String(exig["txt"]) != "" and String(exig["opcion_a"]) != "" and (exig["ids"] as Array).size() >= 2, "una agencia con varios clientes presiona con una exigencia (%s) (598)" % String(exig.get("tipo", "")))
	var ag := String(exig["agente"])
	cn.exigencia = {"tipo": "exclusiva", "agente": ag, "pid": "", "ids": []}
	var c0 := cn.confianza_de(ag)
	var r := cn.resolver_agente("a")
	_comprobar(cn.confianza_de(ag) > c0 and cn.exclusiva == ag and not cn.hay_exigencia() and r.has("titulo"), "aceptar al agente sube su confianza (%d → %d) y le da exclusiva (617)" % [c0, cn.confianza_de(ag)])
	cn.exigencia = {"tipo": "exclusiva", "agente": ag, "pid": "", "ids": []}
	var c1 := cn.confianza_de(ag)
	cn.resolver_agente("b")
	_comprobar(cn.confianza_de(ag) < c1 and cn.exclusiva == "", "y plantarse la baja y quita la exclusiva (617)")
	## Comisión bajo la mesa como decisión ética (623).
	cn.exigencia = {"tipo": "comision", "agente": ag, "pid": "", "ids": []}
	var caja := c.saldo
	var turbio0 := cn.turbio
	cn.resolver_agente("a")
	_comprobar(c.saldo < caja and cn.turbio == turbio0 + 1 and cn.confianza_de(ag) > c1, "pagar la comisión bajo la mesa cuesta caja, suma un punto de «turbio» y gana confianza (623)")
	cn.exigencia = {"tipo": "comision", "agente": ag, "pid": "", "ids": []}
	var pres0: int = m.roles.prestigio
	cn.resolver_agente("b")
	_comprobar(m.roles.prestigio == pres0 + 3, "denunciarla da prestigio (623)")
	## Superagente (620).
	var av: MercadoAvanzado = m.mercado_av
	_comprobar(av._montar(m, "superagente") and av.pendiente["id"] == "superagente" and av.clientes.size() == 3, "aparece un superagente que lleva a tus tres mejores jugadores (620)")
	var cliente := m.jugador_por_id(String(av.pendiente["jugador"]))
	var s0 := cliente.sueldo
	var res := av.resolver(m, "a")
	_comprobar(cliente.sueldo == int(round(float(s0) * 1.15)) and String(res["titulo"]).begins_with("💰"), "ceder al superagente sube el sueldo de su cliente un 15%% (620)")
	av._montar(m, "superagente")
	var cli2 := m.jugador_por_id(String(av.pendiente["jugador"]))
	var mo := cli2.moral
	av.resolver(m, "b")
	_comprobar(cli2.moral == clampi(mo - 10, 0, 100) and av.pendiente.is_empty(), "plantarse le cuesta 10 de moral y a veces lo hace pedir la salida (620)")

func _ideas_a_reglas_y_asuntos() -> void:
	var m := _mundo_ideas(2634)
	var c := m.mi_club()
	c.mover_saldo(900000000)
	var fed: Federacion = m.federacion
	## Cupo de extranjeros por liga (602, 603).
	var r_chi := LeyesPais.reglas("CHI")
	var r_esp := LeyesPais.reglas("ESP")
	_comprobar(int(r_chi["plantel"]) == 6 and int(r_chi["cancha"]) == 5 and String(r_esp["criterio"]) == "no_ue" and int(r_esp["plantel"]) == 3, "cada liga tiene su cupo: Chile 6 extranjeros (5 en cancha), España 3 extracomunitarios (602)")
	var extra := 0
	for x: Jugador in c.plantilla:
		x.pais = c.pais
	for i in 8:
		c.plantilla[i].pais = "BRA"
	LeyesPais.tick += 1
	_comprobar(LeyesPais.cuantos_cupo(c) == 8 and LeyesPais.exceso_plantel(c) == 2, "con 8 extranjeros en Chile el exceso de plantel es 2 (603)")
	_comprobar(LeyesPais.exceso_plantel(c, 3) == 5, "y si la asamblea vota un tope más estricto manda el más estricto (603)")
	var forastero := Jugador.new()
	forastero.pais = "BRA"
	var propio := Jugador.new()
	propio.pais = c.pais
	_comprobar(LeyesPais.motivo_fichaje(c, forastero, m.clubes, 0).begins_with("Cupo lleno") and LeyesPais.motivo_fichaje(c, propio, m.clubes, 0) == "", "con el cupo lleno no se ficha a otro extranjero, pero sí a un nacional (603)")
	## Juveniles obligatorios (603).
	fed.cupo_juvenil = true
	var sin_jov: Array = []
	for x: Jugador in c.plantilla:
		x.edad = 26
		if sin_jov.size() < 11:
			sin_jov.append(x)
	var s0 := c.saldo
	var multa := fed.revisar_cupo_juvenil(c, sin_jov)
	_comprobar(multa < 0 and c.saldo < s0, "alinear un once sin ningún sub-21 con el cupo juvenil votado cuesta una multa (603)")
	sin_jov[0].edad = 19
	var s1 := c.saldo
	var bono := fed.revisar_cupo_juvenil(c, sin_jov)
	_comprobar(bono > 0 and c.saldo > s1, "y alinear a un sub-21 da una bonificación (603)")
	## Fair play financiero (625).
	fed.fpf_activo = true
	_comprobar(fed.revisar_fair_play(c, 90) == "aviso" and fed.puede_pagar_traspaso(), "el primer año por encima del 70%% de masa salarial es un aviso (625)")
	var s2 := c.saldo
	_comprobar(fed.revisar_fair_play(c, 90) == "sancion" and c.saldo < s2 and not fed.puede_pagar_traspaso(), "el segundo año es sanción: multa y no se pagan traspasos (625)")
	_comprobar(fed.revisar_fair_play(c, 50) == "" and fed.puede_pagar_traspaso(), "y volver a las cuentas en regla levanta el castigo (625)")
	## Fichaje impuesto por el dueño (630, 631).
	var av: MercadoAvanzado = m.mercado_av
	m.libres.clear()
	m.generar_libres()
	m.libres[0].edad = 33
	m.libres[0].ovr = 99
	var directiva: Directiva = m.directiva
	_comprobar(av._montar(m, "impuesto") and av.pendiente["id"] == "impuesto", "la directiva te impone el fichaje de un veterano libre (630)")
	var objetivo := m.jugador_por_id(String(av.pendiente["jugador"]))
	if objetivo == null:
		objetivo = m.libres[0]
	var conf0 := directiva.confianza
	var res := av.resolver(m, "b")
	_comprobar(directiva.confianza == conf0 - 6 and String(res["titulo"]).begins_with("🚫"), "negarte baja 6 puntos la paciencia del directorio (%d → %d) (631)" % [conf0, directiva.confianza])
	var fichado := false
	for i in 12:
		if m.libres.is_empty():
			m.generar_libres()
		m.libres[0].edad = 33
		m.libres[0].ovr = 99
		av._montar(m, "impuesto")
		var pid := String(av.pendiente["jugador"])
		var antes := c.plantilla.size()
		var cf := directiva.confianza
		var rr := av.resolver(m, "a")
		if c.plantilla.size() == antes + 1 and directiva.confianza == cf + 4 and String(rr["titulo"]).begins_with("✍️"):
			fichado = true
			break
	_comprobar(fichado, "aceptar ficha al libre y gana 4 puntos de confianza del directorio (630)")
	## Jugador de tu plantel en apuestas (637).
	av._montar(m, "apuestas")
	var ap := m.jugador_por_id(String(av.pendiente["jugador"]))
	var res2 := av.resolver(m, "a")
	_comprobar(ap.suspension >= 3 and String(res2["titulo"]).contains("sancionado"), "sancionar al apostador lo deja tres partidos fuera (637)")
	var cinco := false
	for i in 80:
		av._montar(m, "apuestas")
		var ap2 := m.jugador_por_id(String(av.pendiente["jugador"]))
		ap2.suspension = 0
		av.resolver(m, "b")
		if ap2.suspension == 5:
			cinco = true
			break
	_comprobar(cinco, "taparlo puede salir a la luz y acabar en cinco partidos de suspensión (637)")
	## Agente libre estrella cada cierto tiempo (613).
	var estrellas := []
	m.libre_estrella.connect(func(e: Jugador) -> void: estrellas.append(e))
	for i in 400:
		m._procesar_libres()
	_comprobar(estrellas.size() >= 3 and estrellas.size() < 60 and not m.libres.is_empty(), "de vez en cuando aparece un libre estrella (%d en 400 semanas) (613)" % estrellas.size())
	_comprobar((estrellas[0] as Jugador).ovr >= 60, "y es bueno (media %d) (613)" % (estrellas[0] as Jugador).ovr)
