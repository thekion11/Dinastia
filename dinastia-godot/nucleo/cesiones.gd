class_name Cesiones
extends RefCounted
## Cesiones, cláusulas y todo lo que un traspaso deja firmado para más adelante.
##
## Es el sistema de la LETRA PEQUEÑA. `Mercado` resuelve la parte de delante de
## un fichaje —cuánto piden, si quiere venir, si el club acepta— y ahí se acaba
## su trabajo: paga y mueve al jugador. Pero un traspaso de verdad no se agota
## el día que se firma. Deja obligaciones vivas que hay que cobrar y pagar años
## después, y eso es lo que vive aquí:
##
##   · LA CESIÓN. El chico se va un año a jugar a otro sitio y VUELVE. Puede
##     llevar opción de compra (el otro decide) u obligación (el otro no decide).
##   · LA CLÁUSULA DE RESCISIÓN. Un número que se salta la mesa de negociación
##     entera: quien lo pone encima, se lleva al jugador aunque su club diga que
##     no. Funciona en las dos direcciones, y por eso blindar a tu figura no es
##     una etiqueta bonita sino un seguro.
##   · EL % DE UNA FUTURA VENTA. Cobras menos hoy a cambio de una parte de lo
##     que el otro saque mañana. Tiene dos caras: la tuya cuando vendes
##     (`registrar_plusvalia`) y la del club al que le compraste cuando el que
##     vende eres tú (`pactar_porcentaje_de_venta`).
##   · EL PAGO A PLAZOS, LOS BONOS POR OBJETIVOS y los DERECHOS DE FORMACIÓN,
##     que son las otras tres formas de que un fichaje siga costando dinero
##     mucho después de la foto con la camiseta.
##
## POR QUÉ TODO ESTO JUNTO Y NO REPARTIDO. Son cosas distintas con una misma
## forma: un compromiso que sobrevive al traspaso, se guarda indexado por id de
## jugador y se revisa cada temporada. Repartirlos entre `Mercado`, `Finanzas` y
## `Prensa` obligaría a los tres a llevar su propio calendario de vencimientos.
##
## LA TRAMPA GORDA DEL HTML, que aquí está arreglada: había DOS resolutores de
## cesiones. `resolverCesiones()` miraba las que ya habían vencido (`vuelve <=
## año`) y `finTempJugadores()` devolvía a casa las que vencían el año siguiente
## (`vuelve <= año+1`). Como las dos corrían en el mismo cierre de temporada y la
## segunda pillaba a todas antes de que la primera las viera vencidas, la opción
## de compra NUNCA se ejecutaba: daba igual pactarla con obligación, el jugador
## volvía siempre. Aquí hay un único resolutor (`resolver`), corre una vez, y
## cada cesión termina de la forma en que se firmó.

signal noticia(titulo: String, cuerpo: String)
## Dinero que entra o sale de TU club, para el libro de movimientos. Los
## movimientos entre clubes de la IA no se anuncian: no los lee nadie.
signal movimiento(concepto: String, monto: int)
signal cedido(j: Jugador, destino: Club, tipo: String)
signal vuelto_de_cesion(j: Jugador, casa: Club, subida: int)
signal opcion_ejecutada(j: Jugador, comprador: Club, monto: int)
signal clausula_pagada(j: Jugador, de: Club, a: Club, monto: int)
signal vendido(j: Jugador, comprador: Club, neto: int)

## --- LAS TRES FORMAS DE CEDER ----------------------------------------------
## Sin opción: se va a jugar y vuelve, punto. Es la del canterano.
const CESION_SIMPLE := ""
## Con opción: el club de destino DECIDE al final si lo compra.
const CESION_OPCION := "opcion"
## Con obligación: el club de destino NO decide, lo compra sí o sí.
const CESION_OBLIGA := "obliga"

## Nadie puede bajar de 18 fichas cediendo gente. Es el suelo del HTML y no es
## un capricho: por debajo de ahí el once automático empieza a sacar lesionados.
const PLANTEL_MINIMO := 18
## Hasta los 21 se cede para que juegue. Más arriba ya no es formación, es
## deshacerse de alguien, y para eso está la lista de transferibles.
const EDAD_CANTERANO := 21

## Los dos factores de cláusula del HTML. El de fichaje/renovación (2,2 veces el
## valor) sale de la casilla "con cláusula" de la mesa; el de blindaje (3 veces)
## es el que se firma cuando un agente anda ofreciendo a tu figura por Europa y
## le pagas para que cierre la boca.
const FACTOR_CLAUSULA := 2.2
const FACTOR_BLINDAJE := 3.0
## Una cifra de rescisión se firma en decenas de millar. Una cláusula con
## céntimos no la escribe ningún abogado.
const REDONDEO_CLAUSULA := 10000.0

## Cada cuántas semanas vence una cuota de traspaso: una vez por temporada, la
## última semana. En el HTML es `G.sem % 42 === 0`.
const SEMANAS_ENTRE_CUOTAS := 42

## A los seis años, un porcentaje de futura venta caduca. Si no caducara, una
## partida de veinte temporadas arrastraría cientos de papeles vivos por
## jugadores que ya se retiraron.
const ANIOS_PLUSVALIA := 6

## OJO: referencia DÉBIL al mundo, como en `Mercado` y en `Prensa`. El mundo
## guarda sus cesiones y las cesiones necesitan ver el mundo entero (hay que
## buscar al cedido por todos los clubes y mover dinero entre dos cajas). Con
## dos referencias normales eso es un ciclo, y RefCounted no recoge ciclos: un
## Mundo que no muere se lleva consigo sus 384 clubes y sus 8.448 jugadores.
## Ya han caído cuatro clases en esta trampa; esta no.
var _ref: WeakRef

## --- LO QUE HAY FIRMADO ----------------------------------------------------
## Cesiones vivas: id de jugador -> {de, club, vuelve, tipo, opcion, sueldo_pct}.
## `de` es el dueño al que tiene que volver, `club` dónde está jugando.
var cesiones: Dictionary = {}

## Cláusulas de rescisión pactadas: id de jugador -> monto. Solo las EXPLÍCITAS.
## Las demás las inventa `clausula_de()` a partir del id, y no se guardan porque
## no hace falta: el mismo jugador da siempre el mismo número.
var clausulas: Dictionary = {}

## Lo que le debes al club que te lo vendió: id de jugador -> {pct, club}. Se
## cobra solo, de tu caja, el día que tú lo vendas.
var porcentajes: Dictionary = {}

## Lo que te deben a ti: [{pid, nombre, pct, club, beneficiario, desde}]. `club`
## es a quién se lo vendiste; en cuanto salga de ahí, cobras.
var plusvalias: Array[Dictionary] = []

## Traspasos que estás pagando a plazos: [{club, total, resta, cuota, jugador}].
var cuotas: Array[Dictionary] = []

## Bonos por objetivos pactados al fichar: id de jugador -> {monto, meta, club}.
var bonos: Dictionary = {}

## Lo que llevas movido bajo cuerda. No se pierde: es la mecha que la federación
## enciende el día que a alguien se le ocurre auditar los libros.
var riesgo_opaco: int = 0

func _init(mundo: Mundo) -> void:
	_ref = weakref(mundo)

func _mundo() -> Mundo:
	return _ref.get_ref() as Mundo


# ===========================================================================
#  CESIONES
# ===========================================================================

## Cede a un canterano para que sume minutos. Las tres condiciones son las del
## HTML: hasta los 21, que no esté ya cedido, y que te quede plantel.
##
## El destino no puede sacarte más de cuatro puntos de reputación. A un chico se
## le presta para que JUEGUE: mandarlo a un club mucho mejor que el tuyo es
## mandarlo a un banco mejor, que es exactamente lo contrario de lo que buscas.
func ceder_canterano(j: Jugador) -> Dictionary:
	var m := _mundo()
	if m == null:
		return {}
	var mio: Club = m.clubes.get(j.club_id)
	if mio == null:
		return {}
	if j.edad > EDAD_CANTERANO:
		return {"error": "Solo se cede a los que todavía se están formando: hasta los %d años." % EDAD_CANTERANO}
	if esta_cedido(j.id):
		return {"error": "Ya está cedido: primero tiene que volver."}
	if mio.plantilla.size() <= PLANTEL_MINIMO:
		return {"error": "Plantel muy corto para ceder jugadores."}
	var destino := _destino_para(m, mio, j, 4, false)
	if destino == null:
		return {"error": "Nadie lo quiere ahora mismo."}
	_firmar_cesion(j, mio, destino, CESION_SIMPLE, 0, 0.0)
	noticia.emit("Cedido a préstamo",
		"%s jugará esta temporada en %s para sumar minutos." % [j.nombre, destino.nombre])
	return {"destino": destino, "tipo": CESION_SIMPLE, "opcion": 0, "sueldo_pct": 0.0}

## Cede con opción o con obligación de compra. Aquí ya no es formación: es una
## venta a plazo fijo, y por eso el filtro de destino es otro (hasta seis puntos
## por encima de tu reputación, y que el club sea de su nivel).
##
## Los dos números salen del HTML tal cual y dicen mucho de cómo funciona esto:
## la OBLIGACIÓN se paga más barata (0,85 del valor) porque es dinero seguro, y
## la OPCIÓN más cara (1,1) porque el otro puede no ejercerla. Y quien se obliga
## a comprar paga el sueldo entero mientras tanto; quien solo tiene una opción,
## entre el 40% y el 80%.
func ceder_con_opcion(j: Jugador, tipo: String) -> Dictionary:
	var m := _mundo()
	if m == null:
		return {}
	var mio: Club = m.clubes.get(j.club_id)
	if mio == null:
		return {}
	if esta_cedido(j.id):
		return {"error": "Ya está cedido: primero tiene que volver."}
	if mio.plantilla.size() <= PLANTEL_MINIMO:
		return {"error": "Plantel muy corto para ceder."}
	var destino := _destino_para(m, mio, j, 6, true)
	if destino == null:
		return {"error": "Nadie lo quiere ahora mismo."}
	var obliga := tipo == CESION_OBLIGA
	var opcion := int(round(float(j.valor) * (0.85 if obliga else 1.1)))
	var sueldo_pct := 1.0 if obliga else float(Azar.ent(4, 8)) / 10.0
	_firmar_cesion(j, mio, destino, CESION_OBLIGA if obliga else CESION_OPCION, opcion, sueldo_pct)
	var letra := "Con OBLIGACIÓN de compra por %s al final." % dinero(opcion) if obliga \
		else "Con opción de compra de %s." % dinero(opcion)
	noticia.emit("Cesión a %s" % destino.nombre,
		"%s se va cedido una temporada. %s Pagan el %d%% del sueldo." % [
			j.nombre, letra, int(round(sueldo_pct * 100.0))])
	return {"destino": destino, "tipo": tipo, "opcion": opcion, "sueldo_pct": sueldo_pct}

func _firmar_cesion(j: Jugador, casa: Club, destino: Club, tipo: String, opcion: int, sueldo_pct: float) -> void:
	## El año de vuelta se guarda como número, no como "una temporada": así una
	## partida cargada a media temporada sabe cuándo vence sin tener que
	## reconstruir cuánto llevaba fuera.
	cesiones[j.id] = {
		"de": casa.id, "club": destino.id, "vuelve": _mundo().anio + 1,
		"tipo": tipo, "opcion": opcion, "sueldo_pct": sueldo_pct,
	}
	casa.soltar(j)
	destino.fichar(j)
	cedido.emit(j, destino, tipo)

## A quién se lo prestas. `margen` es cuánta reputación puede sacarte el destino;
## `por_nivel` añade el filtro de la cesión con opción (el club tiene que estar a
## la altura del jugador, o no tiene sentido que se plantee comprarlo).
func _destino_para(m: Mundo, mio: Club, j: Jugador, margen: int, por_nivel: bool) -> Club:
	var candidatos: Array[Club] = []
	for c: Club in m.clubes.values():
		if c.id == mio.id or c.division <= 0:
			continue
		if c.rep > mio.rep + margen:
			continue
		if por_nivel and c.rep < j.ovr - 18:
			continue
		candidatos.append(c)
	if candidatos.is_empty():
		return null
	return Azar.uno(candidatos) as Club

func esta_cedido(pid: String) -> bool:
	return cesiones.has(pid)

## Los datos de una cesión viva, o vacío. Para pintarla en la ficha del jugador
## sin tener que hurgar en el diccionario desde la interfaz.
func cesion_de(pid: String) -> Dictionary:
	return cesiones.get(pid, {})

## Los que este club tiene fuera, con el jugador ya resuelto. La interfaz
## necesita el objeto, no el id, y buscarlo es trabajo de aquí.
func cedidos_de(club_id: String) -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	for pid: String in cesiones:
		var d: Dictionary = cesiones[pid]
		if String(d["de"]) != club_id:
			continue
		var par := _localizar(pid)
		if par.is_empty():
			continue
		salida.append({"jugador": par[0], "club": par[1], "cesion": d})
	return salida

## Lo que te AHORRAS por semana en sueldos gracias a los que tienes cedidos.
##
## En el HTML `sueldoPct` se guardaba en la cesión y no lo leía nadie: el texto
## te prometía que el otro club pagaba el 70% del sueldo y tú seguías pagándolo
## entero. Esto es el lector que faltaba; quien pague la nómina se lo resta.
func ahorro_salarial(club_id: String) -> int:
	var total := 0
	for pid: String in cesiones:
		var d: Dictionary = cesiones[pid]
		if String(d["de"]) != club_id:
			continue
		var par := _localizar(pid)
		if par.is_empty():
			continue
		var j: Jugador = par[0]
		total += int(round(float(j.sueldo) * float(d.get("sueldo_pct", 0.0))))
	return total

## EL ÚNICO RESOLUTOR. Se llama al cambiar de temporada, con el año YA avanzado
## (la misma convención que `Prensa.volver_de_cesion`, para que la migración sea
## un cambio de línea y no un cambio de orden).
##
## Cada cesión acaba de una de tres formas, y las tres están cerradas: se ejecuta
## la compra, se ejerce la opción, o el jugador vuelve a casa. No hay una cuarta
## en la que se quede fuera para siempre.
func resolver(anio: int) -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	var m := _mundo()
	if m == null:
		return salida
	for pid: String in cesiones.keys():
		var d: Dictionary = cesiones[pid]
		if anio < int(d["vuelve"]):
			continue
		cesiones.erase(pid)
		var par := _localizar(pid)
		if par.is_empty():
			continue                      ## se retiró o desapareció: no hay nada que devolver
		var j: Jugador = par[0]
		var donde: Club = par[1]
		var casa: Club = m.clubes.get(String(d["de"]))
		var comprador: Club = m.clubes.get(String(d.get("club", "")))
		if casa == null:
			continue                      ## su club ya no existe: se queda donde está
		var op := int(d.get("opcion", 0))
		var tipo := String(d.get("tipo", CESION_SIMPLE))
		## La opción solo se puede ejercer si el jugador sigue DONDE se le cedió.
		## Si alguien lo movió por el camino, la cesión se cierra devolviéndolo:
		## no se le puede cobrar una opción de compra a un club que ya no lo tiene.
		if op > 0 and comprador != null and donde == comprador \
				and _ejerce_la_opcion(j, comprador, tipo, op):
			comprador.mover_saldo(-op)
			casa.mover_saldo(op)
			if casa.id == m.mi_club_id:
				movimiento.emit("Opción de compra ejecutada: %s" % j.nombre, op)
			noticia.emit("Ejecutan la opción por %s" % j.nombre,
				"%s se queda con %s pagando %s. Buena operación." % [comprador.nombre, j.nombre, dinero(op)])
			opcion_ejecutada.emit(j, comprador, op)
			salida.append({"jugador": j, "comprado": true, "club": comprador, "monto": op})
			continue
		## Vuelve. Y vuelve MEJOR: es el sentido entero de ceder a un chico, y si
		## no se notara al volver, ceder sería regalar una temporada.
		if donde != casa:
			donde.soltar(j)
			casa.fichar(j)
		var subida := Azar.ent(1, 4)
		j.ajustar_media(subida)
		noticia.emit("Vuelve de la cesión: %s" % j.nombre,
			"%s regresa con %d punto(s) más de media tras una temporada con minutos." % [j.nombre, subida])
		vuelto_de_cesion.emit(j, casa, subida)
		salida.append({"jugador": j, "comprado": false, "club": casa, "subida": subida})
	return salida

## ¿El club de destino se lo queda? Con obligación no hay nada que decidir. Con
## opción, mira las tres cosas que miraría de verdad: si le sobra el dinero (1,4
## veces la opción, no justo), si el chico está a su altura, y la moneda al aire
## del 55% que impide que la decisión sea automática y previsible.
func _ejerce_la_opcion(j: Jugador, comprador: Club, tipo: String, opcion: int) -> bool:
	if tipo == CESION_OBLIGA:
		return true
	if tipo != CESION_OPCION:
		return false
	return float(comprador.saldo) >= float(opcion) * 1.4 \
		and j.ovr >= comprador.rep - 6 \
		and Azar.suerte(0.55)


# ===========================================================================
#  CLÁUSULAS DE RESCISIÓN
# ===========================================================================

## La cláusula de un jugador. Si se pactó una, esa; si no, la que le corresponde
## por contrato tipo.
##
## Ese reparto por hash es lo que hace que el mercado tenga sorpresas: tres de
## cada diez futbolistas del mundo llevan cláusula sin que nadie la negociara, y
## entre 1,7 y 2,2 veces su valor. Eso significa que en algún club modesto hay
## una joya con la puerta abierta, y encontrarla es trabajo del ojeador. Es
## ESTABLE, no sorteada: el mismo jugador tiene siempre la misma cláusula, en
## esta partida y en la siguiente. Si se sorteara, mirar dos veces la misma ficha
## daría dos números distintos.
func clausula_de(j: Jugador) -> int:
	if clausulas.has(j.id):
		return int(clausulas[j.id])
	var h := 0
	for i in j.id.length():
		h += j.id.unicode_at(i)
	if h % 10 >= 3:
		return 0
	var f := 1.7 + float(h % 6) / 10.0
	return int(round(float(j.valor) * f / REDONDEO_CLAUSULA)) * int(REDONDEO_CLAUSULA)

## Pacta la cláusula que sale de la mesa (fichaje o renovación con la casilla
## marcada). Devuelve el monto firmado.
func pactar_clausula(j: Jugador, factor: float = FACTOR_CLAUSULA) -> int:
	var monto := int(round(float(j.valor) * factor / REDONDEO_CLAUSULA)) * int(REDONDEO_CLAUSULA)
	clausulas[j.id] = monto
	return monto

## Blindar a la figura: cláusula al triple de su valor y un 10% más de ficha. Es
## lo que firmas cuando su agente anda ofreciéndolo por Europa a tus espaldas.
func blindar(j: Jugador) -> int:
	var monto := pactar_clausula(j, FACTOR_BLINDAJE)
	j.sueldo = int(round(float(j.sueldo) * 1.1))
	return monto

func quitar_clausula(pid: String) -> void:
	clausulas.erase(pid)

## Lo que te costaría llevártelo pagando la cláusula: el número y la comisión de
## su agente, que también sale de tu caja.
func coste_de_clausula(j: Jugador) -> Dictionary:
	var clau := clausula_de(j)
	if clau <= 0:
		return {"clausula": 0, "comision": 0, "total": 0}
	var com := comision_de_agente(j, clau)
	return {"clausula": clau, "comision": com, "total": clau + com}

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
	j.anios_contrato = Azar.ent(2, 4)
	j.moral = clampi(j.moral + 6, 10, 99)
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
			movimiento.emit("Al fondo de inversion por %s (%d%%)" % [j.nombre, pct_fondo], -del_fondo)
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

## Los bonos por objetivos. Se revisa cada semana sobre los partidos jugados: el
## día que llega a la marca pactada, el club anterior cobra.
func revisar_bonos(mio: Club) -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	if bonos.is_empty() or mio == null:
		return salida
	var m := _mundo()
	for j in mio.plantilla:
		if not bonos.has(j.id):
			continue
		var b: Dictionary = bonos[j.id]
		if j.partidos < int(b["meta"]):
			continue
		var monto := int(b["monto"])
		mio.mover_saldo(-monto)
		var otro: Club = m.clubes.get(String(b["club"])) if m != null else null
		if otro != null:
			otro.mover_saldo(monto)
		movimiento.emit("Bono por objetivos: %s" % j.nombre, -monto)
		noticia.emit("Bono activado: %s" % j.nombre,
			"Llegó a %d partidos y se gatilla el bono de %s para su club anterior." % [
				int(b["meta"]), dinero(monto)])
		salida.append({"jugador": j, "monto": monto})
		bonos.erase(j.id)
	return salida


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

## Cómo se llama su representante, para poder nombrarlo en la noticia. Que la
## comisión tenga cara y nombre es la mitad de lo que hace que el agente exista.
func nombre_del_agente(j: Jugador) -> String:
	var m := _mundo()
	if m == null or m.prensa == null:
		return "su representante"
	return String(m.prensa.agente_de(j).get("nombre", "su representante"))

## Dónde está un jugador ahora mismo. Devuelve [Jugador, Club] o vacío.
##
## Recorre los clubes porque las cesiones guardan IDS, no referencias: un cedido
## sobrevive a guardar y cargar la partida, y una referencia directa no. Se puede
## permitir el paseo porque esto corre sobre unas pocas fichas vivas y una vez
## por temporada, no dentro del bucle de la simulación.
func _localizar(pid: String) -> Array:
	var m := _mundo()
	if m == null or pid == "":
		return []
	for c: Club in m.clubes.values():
		for j in c.plantilla:
			if j.id == pid:
				return [j, c]
	return []

## Puntos internos a euros de pantalla, con las abreviaturas y la coma decimal
## española. Es el `fmt$` del HTML. Público y estático a propósito: `Prensa`
## tiene ahora mismo una copia privada de esto, y el día que se unifiquen basta
## con que llame aquí.
static func dinero(n: int) -> String:
	return Eco.dinero(n)


# ===========================================================================
#  GUARDAR Y CARGAR
# ===========================================================================

## Todo va indexado por id de jugador, nunca por referencia: un guardado tiene
## que sobrevivir a que el cedido cambie de club, se retire o desaparezca, y
## `resolver()` ya sabe qué hacer cuando no encuentra a nadie.
func a_dic() -> Dictionary:
	return {
		"cesiones": cesiones,
		"clausulas": clausulas,
		"porcentajes": porcentajes,
		"plusvalias": plusvalias,
		"cuotas": cuotas,
		"bonos": bonos,
		"opaco": riesgo_opaco,
		"fondos": fondos_a_dic(),
	}

func desde_dic(d: Dictionary) -> void:
	cesiones = d.get("cesiones", {})
	clausulas = d.get("clausulas", {})
	porcentajes = d.get("porcentajes", {})
	riesgo_opaco = int(d.get("opaco", 0))
	bonos = d.get("bonos", {})
	## Las dos listas se copian elemento a elemento porque salen del guardado
	## como Array sin tipar y aquí están declaradas Array[Dictionary]: asignarlas
	## de golpe revienta al cargar, no al guardar, que es cuando peor viene.
	plusvalias.clear()
	for x: Dictionary in d.get("plusvalias", []):
		plusvalias.append(x)
	cuotas.clear()
	for x: Dictionary in d.get("cuotas", []):
		cuotas.append(x)
	fondos_desde_dic(d.get("fondos", {}))

# ===========================================================================
#  FONDOS DE INVERSIÓN: EL DINERO DE HOY CONTRA EL JUGADOR DE MAÑANA
# ===========================================================================
#
# «Negociar con empresas que poseen un porcentaje de los derechos de tus
# juveniles; estos fondos te presionarán para vender a tus promesas
# prematuramente a cambio de liquidez inmediata». Del documento de instrucciones.
#
# CÓMO FUNCIONA Y POR QUÉ ES UNA TRAMPA BUENA. Un fondo te da dinero HOY por un
# porcentaje de lo que cobres cuando vendas a un canterano. La cifra es
# tentadora justo cuando peor estás de caja, que es exactamente cuando peor se
# decide. Y a partir de ahí el fondo tiene voz: cada cierto tiempo aparece
# pidiendo que vendas, y decir que no cuesta.
#
# LA DIFERENCIA CON `Cesiones.registrar_plusvalia()`: allí el porcentaje te lo
# guardas TÚ de una venta que hiciste. Aquí lo vende un tercero, sobre un chico
# que sigue siendo tuyo, y lo cobra alguien que no quiere lo mejor para el club.

const FONDOS := [
	["horizonte", "Horizonte Capital", 0.9, "Discretos. Pagan menos y molestan poco."],
	["meridian", "Meridian Sports Group", 1.15, "Agresivos: pagan bien y llaman todos los meses."],
	["delta", "Delta Futures", 1.0, "Los de siempre. Ni gangas ni sustos."],
]

## Cuánto del futuro traspaso se puede vender. Más de la mitad y el club dejaría
## de ganar dinero con su propia cantera, que es su única ventaja estructural.
const PCT_MAX := 50
## Cada cuántas semanas el fondo aparece a presionar.
const SEMANAS_PRESION := 14

## pid -> {fondo, pct, cobrado, anio}
var participaciones: Dictionary = {}
var _ultima_presion: int = 0

## Lo que un fondo pone hoy por un porcentaje del futuro traspaso. Se paga por
## debajo del valor proporcional -un 62%- porque el fondo asume el riesgo de que
## el chico no llegue: si pagaran lo mismo, vender sería gratis.
func oferta_de_fondo(j: Jugador, clave: String, pct: int) -> int:
	var mult := 1.0
	for f: Array in FONDOS:
		if String(f[0]) == clave:
			mult = float(f[2])
	return int(round(float(j.valor) * float(pct) / 100.0 * 0.62 * mult))

func participacion_de(j: Jugador) -> int:
	if not participaciones.has(j.id):
		return 0
	return int((participaciones[j.id] as Dictionary)["pct"])

## Vender un porcentaje. Devuelve "" si se hizo, o el motivo.
func vender_participacion(j: Jugador, clave: String, pct: int, c: Club) -> String:
	var m := _mundo()
	if j == null or c == null:
		return "no hay a quién vender"
	if j.club_id != c.id:
		return "solo puedes vender derechos de los tuyos"
	if j.edad > 23:
		return "los fondos solo compran derechos de futbolistas jóvenes"
	var ya := participacion_de(j)
	if ya + pct > PCT_MAX:
		return "no se puede pasar del %d%% de un mismo jugador (ya hay un %d%% vendido)" % [PCT_MAX, ya]
	var monto := oferta_de_fondo(j, clave, pct)
	c.mover_saldo(monto)
	movimiento.emit("Venta de derechos: %s" % j.nombre, monto)
	participaciones[j.id] = {
		"fondo": clave, "pct": ya + pct, "cobrado": monto,
		"anio": m.anio if m != null else 0,
	}
	noticia.emit("Entra dinero de un fondo",
		"Vendiste el %d%% del próximo traspaso de %s por %s. El club respira hoy; el día que lo vendas, ese porcentaje no es tuyo." % [
			pct, j.nombre, Cesiones.dinero(monto)])
	return ""

## Lo que el club se queda de verdad al venderlo. Lo consulta el mercado antes
## de aceptar una oferta: enseñar el precio bruto cuando la mitad se la lleva un
## fondo sería mentir en la pantalla donde más duele.
func neto_de_venta(j: Jugador, bruto: int) -> int:
	var pct := participacion_de(j)
	if pct <= 0:
		return bruto
	return int(round(float(bruto) * (1.0 - float(pct) / 100.0)))

## El fondo aparece a presionar. Devuelve el evento, o vacío.
func presion_de_fondo() -> Dictionary:
	var m := _mundo()
	if m == null or participaciones.is_empty():
		return {}
	if m.semana - _ultima_presion < SEMANAS_PRESION:
		return {}
	var mio := m.mi_club()
	if mio == null:
		return {}
	var candidatos: Array[Jugador] = []
	for j: Jugador in mio.plantilla:
		if participaciones.has(j.id):
			candidatos.append(j)
	if candidatos.is_empty():
		return {}
	_ultima_presion = m.semana
	var j2: Jugador = candidatos[Azar.ent(0, candidatos.size() - 1)]
	var p: Dictionary = participaciones[j2.id]
	var nombre_fondo := "el fondo"
	for f: Array in FONDOS:
		if String(f[0]) == String(p["fondo"]):
			nombre_fondo = String(f[1])
	return {
		"jugador": j2, "fondo": nombre_fondo, "pct": int(p["pct"]),
		"texto": "%s tiene el %d%% de %s y quiere cobrar: pide que lo pongas en el mercado esta temporada." % [
			nombre_fondo, int(p["pct"]), j2.nombre],
	}

## Decirle que no al fondo. No es gratis: bajan la moral del chico -su entorno
## le come la cabeza- y el fondo no vuelve a poner un peso en este club.
func rechazar_presion(j: Jugador) -> String:
	if j == null:
		return "no hay a quién retener"
	j.moral = clampi(j.moral - Azar.ent(5, 12), 10, 99)
	if participaciones.has(j.id):
		(participaciones[j.id] as Dictionary)["enfadado"] = true
	noticia.emit("El fondo se lo toma mal",
		"Te niegas a vender a %s. Su entorno lleva semanas diciéndole que el club le está frenando la carrera." % j.nombre)
	return ""

func fondos_a_dic() -> Dictionary:
	return {"participaciones": participaciones.duplicate(true), "ultima": _ultima_presion}

func fondos_desde_dic(d: Dictionary) -> void:
	participaciones = (d.get("participaciones", {}) as Dictionary).duplicate(true)
	_ultima_presion = int(d.get("ultima", 0))
