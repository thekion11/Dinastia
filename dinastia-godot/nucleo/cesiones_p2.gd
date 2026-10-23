extends "res://nucleo/cesiones_p1.gd"
## (Parte 2 de 3 de `cesiones.gd`.)

# ===========================================================================
#  AUXILIARES
# ===========================================================================

## La comisión del representante sobre una operación. El porcentaje sale del
## perfil de su agente, que lo sabe `Prensa` (es estable, del hash de su id). Si
## la prensa todavía no existe se usa el 10% del agente discreto, que es el
## neutro de la tabla: mejor una comisión razonable que ninguna.
func comision_de_agente(j: Jugador, monto: int) -> int:
	var com := 0.10
	var m := _mundo()
	if m != null and m.prensa != null:
		com = float(m.prensa.agente_de(j).get("com", 0.10))
	return int(round(float(monto) * com))

## Lo que te costaría llevártelo pagando la cláusula: el número y la comisión de
## su agente, que también sale de tu caja.
func coste_de_clausula(j: Jugador) -> Dictionary:
	var clau := clausula_de(j)
	if clau <= 0:
		return {"clausula": 0, "comision": 0, "total": 0}
	var com := comision_de_agente(j, clau)
	return {"clausula": clau, "comision": com, "total": clau + com}

## Cómo se llama su representante, para poder nombrarlo en la noticia. Que la
## comisión tenga cara y nombre es la mitad de lo que hace que el agente exista.
func nombre_del_agente(j: Jugador) -> String:
	var m := _mundo()
	if m == null or m.prensa == null:
		return "su representante"
	return String(m.prensa.agente_de(j).get("nombre", "su representante"))

## Derechos de formación: el club donde se hizo futbolista cobra un porcentaje
## cuando el chico se transfiere a un tercero. Diez puntos hasta los 21, seis
## hasta los 23, tres hasta los 25, y a partir de ahí nada: lo que se premia es
## haber formado a alguien joven, no haber tenido a un veterano.
##
## Es la otra mitad de tener cantera. Sin esto, el club formador ve pasar por
## delante millones que salieron de su trabajo.
func derechos_de_formacion(j: Jugador, comprador: Club) -> float:
	var m := _mundo()
	if m == null or j.club_formacion == "":
		return 0.0
	if j.club_formacion == j.club_id or j.club_formacion == comprador.id:
		return 0.0                       ## nadie se indemniza a sí mismo
	if not m.clubes.has(j.club_formacion):
		return 0.0
	if j.edad > 25:
		return 0.0
	if j.edad <= 21:
		return 0.10
	return 0.06 if j.edad <= 23 else 0.03

func pagar_derechos_formacion(j: Jugador, monto_base: int, comprador: Club) -> int:
	var pct := derechos_de_formacion(j, comprador)
	if pct <= 0.0:
		return 0
	var m := _mundo()
	var formador: Club = m.clubes.get(j.club_formacion)
	var comp := int(round(float(monto_base) * pct / 1000.0)) * 1000
	if comp <= 0 or formador == null:
		return 0
	comprador.mover_saldo(-comp)
	formador.mover_saldo(comp)
	if comprador.id == m.mi_club_id:
		movimiento.emit("Derechos de formación a %s: %s" % [formador.nombre, j.nombre], -comp)
	elif formador.id == m.mi_club_id:
		movimiento.emit("Derechos de formación por %s" % j.nombre, comp)
		noticia.emit("Cobras derechos de formación",
			"%s se formó aquí y acaba de cambiar de club: te corresponden %s." % [j.nombre, dinero(comp)])
	return comp

## El clausulazo: pagas y te lo llevas. No pasa por la mesa, no hay negociación,
## y el club vendedor no tiene voz. Devuelve vacío con un motivo si no se puede.
##
## El sueldo sube un 15% porque nadie se deja rescindir por lo mismo que cobraba,
## y el rol se lo asigna quien llame: entrar por la puerta de atrás no puede
## dejarlo sin papel en el plantel.
func pagar_clausula(j: Jugador, comprador: Club) -> Dictionary:
	var m := _mundo()
	if m == null:
		return {"error": "Sin mundo."}
	var vendedor: Club = m.clubes.get(j.club_id)
	if vendedor == null or vendedor.id == comprador.id:
		return {"error": "Ya es tuyo."}
	var c := coste_de_clausula(j)
	var clau := int(c["clausula"])
	if clau <= 0:
		return {"error": "%s no tiene cláusula de rescisión." % j.nombre}
	if comprador.saldo < int(c["total"]):
		return {"error": "Caja insuficiente: %s (cláusula + comisión)." % dinero(int(c["total"]))}
	comprador.mover_saldo(-clau)
	vendedor.mover_saldo(clau)
	var com := int(c["comision"])
	var ag := nombre_del_agente(j)
	comprador.mover_saldo(-com)
	if comprador.id == m.mi_club_id:
		movimiento.emit("Cláusula de %s (%s)" % [j.nombre, vendedor.nombre], -clau)
		movimiento.emit("Comisión del agente %s" % ag, -com)
	var formacion := pagar_derechos_formacion(j, clau, comprador)
	vendedor.soltar(j)
	comprador.fichar(j)
	quitar_clausula(j.id)
	j.sueldo = int(round(float(j.sueldo) * 1.15))
	j.anios_contrato = Contratos.ajustar_anios(j, Azar.ent(2, 4))
	j.cambiar_moral(6, "Cesiones")
	j.pide_salir = false
	noticia.emit("¡Clausulazo!",
		"Pagaste la cláusula de %s. Su agente %s se lleva %s. Bienvenido al club." % [j.nombre, ag, dinero(com)])
	clausula_pagada.emit(j, vendedor, comprador, clau)
	return {"clausula": clau, "comision": com, "formacion": formacion, "de": vendedor}

## La otra cara: un club de la IA que se fija en tu jugador y descubre que tiene
## cláusula. Si lo que iba a ofrecer llega al 85% del número, no ofrece: PAGA la
## cláusula, y entonces la oferta que te llega ya no se puede rechazar.
##
## `factor` es el recargo del mercado del momento (la fiebre de fichajes del
## HTML lo pone en 1,2). Devuelve el monto y si es obligatoria; monto 0 significa
## que no hay clausulazo y la oferta sigue su camino normal.
func oferta_por_clausula(j: Jugador, monto: int, factor: float = 1.0) -> Dictionary:
	var clau := clausula_de(j)
	if clau <= 0:
		return {"monto": 0, "obligatoria": false}
	if float(monto) * factor < float(clau) * 0.85:
		return {"monto": 0, "obligatoria": false}
	return {"monto": clau, "obligatoria": true}


# ===========================================================================
#  EL % DE UNA FUTURA VENTA
# ===========================================================================

## Cuando COMPRAS y le concedes al vendedor una parte de tu próxima venta. Es una
## deuda tuya: no la ves hasta el día que vendes, y ese día se cobra sola.
##
## En el HTML esto se guardaba en `j.pctVenta` y durante mucho tiempo no lo
## cobraba nadie: era dinero que el juego prometía al club vendedor y nunca salía
## de tu caja. El cobro está en `vender()`, que es el único sitio por donde puede
## pasar una venta.
func pactar_porcentaje_de_venta(j: Jugador, pct: int, club_vendedor: String) -> void:
	if pct <= 0 or club_vendedor == "":
		return
	porcentajes[j.id] = {"pct": clampi(pct, 0, 50), "club": club_vendedor}

func porcentaje_pendiente(pid: String) -> Dictionary:
	return porcentajes.get(pid, {})

## Cuando VENDES guardándote una parte de lo que saquen mañana. Cobras menos hoy
## (lo aplica `vender`) y cobras solo si el chico explota.
func registrar_plusvalia(j: Jugador, pct: int, club_comprador: String, beneficiario: String) -> void:
	if pct <= 0:
		return
	plusvalias.append({
		"pid": j.id, "nombre": j.nombre, "pct": pct,
		"club": club_comprador, "beneficiario": beneficiario, "desde": _mundo().anio,
	})

## La revisión anual: ¿alguno de "los nuestros" cambió de club?
##
## UNA DIFERENCIA DELIBERADA CON EL HTML, y conviene tenerla escrita: allí la
## plusvalía aparecía de la nada (`mov(cobro)` sumaba a tu caja y nadie pagaba),
## porque el HTML solo llevaba la contabilidad de TU club y los otros 383 tenían
## el saldo puesto a mano. Aquí se simulan los 384, así que un ingreso sin
## contrapartida infla el dinero del mundo entero temporada tras temporada. Paga
## quien lo acaba de vender, que es lo que dice el contrato. Ni una fórmula
## cambia: cambia que el dinero salga de algún sitio.
func cobrar_plusvalias(anio: int) -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	var m := _mundo()
	if m == null:
		return salida
	for i in range(plusvalias.size() - 1, -1, -1):
		var x: Dictionary = plusvalias[i]
		var par := _localizar(String(x["pid"]))
		if par.is_empty():
			plusvalias.remove_at(i)
			continue
		var j: Jugador = par[0]
		var ahora: Club = par[1]
		if ahora.id == String(x["club"]):
			if anio - int(x["desde"]) > ANIOS_PLUSVALIA:
				plusvalias.remove_at(i)
			continue
		var pct := int(x["pct"])
		var cobro := int(round(float(j.valor) * float(pct) / 100.0))
		var quien: Club = m.clubes.get(String(x["beneficiario"]))
		var paga: Club = m.clubes.get(String(x["club"]))
		if quien != null and cobro > 0:
			quien.mover_saldo(cobro)
			if paga != null:
				paga.mover_saldo(-cobro)
			if quien.id == m.mi_club_id:
				movimiento.emit("Plusvalía por la venta de %s (%d%%)" % [j.nombre, pct], cobro)
				noticia.emit("Cobras una plusvalía",
					"%s cambió de club y te llevas el %d%% de la operación: %s. Aquella venta barata acabó saliendo bien." % [
						j.nombre, pct, dinero(cobro)])
			salida.append({"jugador": j, "pct": pct, "monto": cobro, "beneficiario": quien})
		plusvalias.remove_at(i)
	return salida

func participacion_de(j: Jugador) -> int:
	if not participaciones.has(j.id):
		return 0
	return int((participaciones[j.id] as Dictionary)["pct"])


# ===========================================================================
#  LA VENTA
# ===========================================================================

## Vender a un jugador con toda la letra pequeña resuelta de una vez.
##
## Es el `responderOferta` del HTML. Tiene tres pasos y el orden importa:
##
##   1. Si te guardas un `pct_futuro` de su próxima venta, HOY COBRAS MENOS. El
##      1,2% menos por cada punto de porcentaje: quedarte el 50% te cuesta el 60%
##      del traspaso. Ese descuento es lo que hace que la decisión sea una
##      apuesta y no una ganancia gratis.
##   2. Entra el dinero, ya descontado.
##   3. Y si cuando TÚ lo fichaste el vendedor se guardó su parte, se le paga
##      ahora, de ese mismo ingreso. Ese cobro se calcula sobre el neto, no sobre
##      el bruto: es la letra del HTML y es peor para ti de lo que parece.
func vender(j: Jugador, comprador: Club, monto: int, pct_futuro: int = 0) -> Dictionary:
	var m := _mundo()
	if m == null:
		return {}
	var vendedor: Club = m.clubes.get(j.club_id)
	if vendedor == null or comprador == null or vendedor.id == comprador.id:
		return {}
	var pct := clampi(pct_futuro, 0, 50)
	var neto := int(round(float(monto) * (1.0 - float(pct) * 0.012)))
	vendedor.mover_saldo(neto)
	comprador.mover_saldo(-neto)
	var mio := vendedor.id == m.mi_club_id
	## SE APUNTA QUE FUE TUYO. La ley del ex necesita saber de donde lo echaste,
	## no donde se formo: un canterano vendido a los 19 no tiene nada que
	## demostrarte; el titular que sacaste a los 30, si.
	if mio:
		Partido.marcar_ex(j, vendedor.id)
	if mio:
		var coletilla := " (con %d%% de futura venta)" % pct if pct > 0 else ""
		movimiento.emit("Venta: %s a %s%s" % [j.nombre, comprador.nombre, coletilla], neto)
	if pct > 0:
		registrar_plusvalia(j, pct, comprador.id, vendedor.id)

	## LO QUE SE LLEVA EL FONDO. Si vendiste un porcentaje de su futuro traspaso
	## cuando hacia falta caja, hoy toca pagarlo: es la letra pequena de aquel
	## dinero facil, y se cobra AQUI y no en la pantalla, para que se descuente
	## tambien cuando la venta la cierra la IA o una clausula.
	var pct_fondo := participacion_de(j)
	if pct_fondo > 0 and mio:
		var del_fondo := int(round(float(neto) * float(pct_fondo) / 100.0))
		if del_fondo > 0:
			vendedor.mover_saldo(-del_fondo)
			movimiento.emit("Al fondo de inversión por %s (%d%%)" % [j.nombre, pct_fondo], -del_fondo)
			noticia.emit("El fondo cobra su parte",
				"De los %s de la venta de %s, %s se van al fondo que compro el %d%% de sus derechos." % [
					Cesiones.dinero(neto), j.nombre, Cesiones.dinero(del_fondo), pct_fondo])
		participaciones.erase(j.id)

	## La deuda pendiente por él, si la hay.
	var pagado := 0
	var d := porcentaje_pendiente(j.id)
	if not d.is_empty() and int(d.get("pct", 0)) > 0:
		var dueno: Club = m.clubes.get(String(d["club"]))
		var suyo := int(d["pct"])
		pagado = int(round(float(neto) * float(suyo) / 100.0))
		if pagado > 0:
			vendedor.mover_saldo(-pagado)
			if dueno != null:
				dueno.mover_saldo(pagado)
			if mio:
				var nombre_dueno := dueno.nombre if dueno != null else "su club anterior"
				movimiento.emit("%% de venta futura a %s: %s" % [nombre_dueno, j.nombre], -pagado)
				noticia.emit("Te toca pagar el porcentaje pactado",
					"%s se había guardado el %d%% de la próxima venta de %s. De los %s que entran, %s salen directos para ellos." % [
						nombre_dueno, suyo, j.nombre, dinero(neto), dinero(pagado)])
		porcentajes.erase(j.id)

	vendedor.soltar(j)
	comprador.fichar(j)
	## Se va contento a un sitio nuevo: la moral vuelve al punto neutro. Y lo que
	## quedaba firmado sobre él en tu club deja de tener sentido.
	j.moral = 70
	j.pide_salir = false
	cesiones.erase(j.id)
	bonos.erase(j.id)
	if mio:
		noticia.emit("Venta concretada",
			"%s parte a %s por %s.%s" % [j.nombre, comprador.nombre, dinero(neto),
				" Te guardaste el %d%% de su próxima venta." % pct if pct > 0 else ""])
	vendido.emit(j, comprador, neto)
	return {"neto": neto, "bruto": monto, "pct": pct, "pagado_a_terceros": pagado}


# ===========================================================================
#  LO QUE SE FIRMA AL CERRAR UN FICHAJE
# ===========================================================================

## Una oferta estructurada en blanco, con la parte fija ya puesta en el 70% de lo
## que piden, igual que abre la mesa el HTML.
static func nueva_oferta(pedido: int) -> Dictionary:
	return {
		"fijo": int(round(float(pedido) * 0.7 / 1000.0)) * 1000,
		"cuotas": 0, "bonos": 0, "pct": 0, "opaco": 0, "firma": 0,
		"clausula": false, "intercambio": "",
	}

## Lo que el club vendedor PERCIBE que le estás ofreciendo. Es el número que hay
## que comparar con lo que piden, no la suma de las partes.
##
## Cada coeficiente dice qué le merece a un club cada forma de cobrar: el dinero
## a plazos vale un 82%, los bonos un 35% (puede que no lleguen nunca), el
## porcentaje de futura venta un 45% de la parte proporcional del valor de hoy, y
## lo de bajo cuerda vale MÁS que su cifra (1,2) porque no paga comisión ni
## impuestos. Ahí está la tentación: la vía sucia es la única que rinde más de lo
## que cuesta.
func valor_percibido(oferta: Dictionary, j: Jugador) -> int:
	var m := _mundo()
	var inter: Jugador = null
	if m != null and String(oferta.get("intercambio", "")) != "":
		var par := _localizar(String(oferta["intercambio"]))
		if not par.is_empty():
			inter = par[0]
	return int(round(
		float(oferta.get("fijo", 0))
		+ float(oferta.get("cuotas", 0)) * 0.82
		+ float(oferta.get("bonos", 0)) * 0.35
		+ float(oferta.get("pct", 0)) / 100.0 * float(j.valor) * 0.45
		+ float(oferta.get("opaco", 0)) * 1.2
		+ (float(inter.valor) * 0.88 if inter != null else 0.0)))

## Lo que sale de tu caja EL MISMO DÍA. Hace falta aparte del percibido porque
## son cosas distintas: puedes tener acordado un traspaso de veinte millones a
## plazos y no poder pagarlo hoy. Cuenta la prima de fichaje y la comisión del
## agente, que en el HTML faltaban y por eso el aviso de "no te alcanza" mentía y
## la caja se iba a negativo sin que nadie hubiera avisado.
func coste_inmediato(oferta: Dictionary, j: Jugador) -> int:
	var fijo := int(oferta.get("fijo", 0))
	return fijo + int(oferta.get("opaco", 0)) + int(oferta.get("firma", 0)) \
		+ comision_de_agente(j, fijo)

## Escribe en el jugador y en los libros TODO lo que se pactó en la mesa y no es
## el traspaso en sí. Se llama justo después de mover al jugador (de
## `Mercado.fichar`, por ejemplo): esto no ficha a nadie, firma los papeles.
func registrar_compromisos(j: Jugador, oferta: Dictionary, comprador: Club, vendedor: Club) -> Dictionary:
	var m := _mundo()
	var mio := m != null and comprador.id == m.mi_club_id
	var salida := {"cuotas": 0, "bono": 0, "clausula": 0, "opaco": 0,
		"formacion": 0, "pct": 0, "comision": 0}

	## El dinero a plazos: entre tres y seis vencimientos, uno por temporada.
	var a_plazos := int(oferta.get("cuotas", 0))
	if a_plazos > 0:
		var n := Azar.ent(3, 6)
		cuotas.append({"club": vendedor.id, "total": a_plazos, "resta": n,
			"cuota": int(round(float(a_plazos) / float(n))), "jugador": j.nombre})
		salida["cuotas"] = a_plazos

	## El bono por objetivos: se gatilla cuando llegue a los partidos pactados.
	var bono := int(oferta.get("bonos", 0))
	if bono > 0:
		bonos[j.id] = {"monto": bono, "meta": Azar.ent(15, 25), "club": vendedor.id}
		salida["bono"] = bono

	var pct := int(oferta.get("pct", 0))
	if pct > 0:
		pactar_porcentaje_de_venta(j, pct, vendedor.id)
		salida["pct"] = pct

	if bool(oferta.get("clausula", false)):
		salida["clausula"] = pactar_clausula(j)

	## Bajo cuerda. Sale de la caja igual que lo demás, pero no aparece en ningún
	## contrato: por eso se apunta en `riesgo_opaco` y no en el libro.
	var opaco := int(oferta.get("opaco", 0))
	if opaco > 0:
		comprador.mover_saldo(-opaco)
		vendedor.mover_saldo(opaco)
		riesgo_opaco += opaco
		salida["opaco"] = opaco
		if mio:
			movimiento.emit("Pago reservado: %s" % j.nombre, -opaco)

	salida["formacion"] = pagar_derechos_formacion(j, int(oferta.get("fijo", 0)), comprador)

	var prima := int(oferta.get("firma", 0))
	if prima > 0:
		comprador.mover_saldo(-prima)
		if mio:
			movimiento.emit("Prima de fichaje: %s" % j.nombre, -prima)

	## La comisión del representante se cobra AQUÍ y no en la mesa. Tiene que
	## salir del mismo sitio que la cuenta `coste_inmediato`, o el aviso de "no
	## te alcanza" estaría contando un dinero que después no paga nadie: en el
	## HTML esa comisión sí salía de la caja, y perderla al portar habría hecho
	## que fichar saliera un 8-12% más barato sin que se notara en ningún sitio.
	var com := comision_de_agente(j, int(oferta.get("fijo", 0)))
	if com > 0:
		comprador.mover_saldo(-com)
		if mio:
			movimiento.emit("Comisión del agente %s" % nombre_del_agente(j), -com)
	salida["comision"] = com
	return salida

## Los vencimientos de los traspasos a plazos. Se llama cada semana; solo hace
## algo la última de la temporada.
func pagar_cuotas(semana: int, pagador: Club) -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	if semana % SEMANAS_ENTRE_CUOTAS != 0 or cuotas.is_empty() or pagador == null:
		return salida
	var m := _mundo()
	for i in range(cuotas.size() - 1, -1, -1):
		var p: Dictionary = cuotas[i]
		var cuota := int(p["cuota"])
		pagador.mover_saldo(-cuota)
		var acreedor: Club = m.clubes.get(String(p["club"])) if m != null else null
		if acreedor != null:
			acreedor.mover_saldo(cuota)
		movimiento.emit("Cuota de traspaso: %s" % String(p["jugador"]), -cuota)
		salida.append({"jugador": String(p["jugador"]), "monto": cuota})
		p["resta"] = int(p["resta"]) - 1
		if int(p["resta"]) <= 0:
			cuotas.remove_at(i)
			noticia.emit("Traspaso saldado",
				"Pagada la última cuota por %s." % String(p["jugador"]))
	return salida
