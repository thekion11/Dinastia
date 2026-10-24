extends RefCounted
## [Capa 1/3 de `cesiones.gd`] _init, _mundo, esta_cedido, _destino_para, _firmar_cesion, ceder_canterano … (+12)

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

func _init(mundo: Mundo) -> void:
	_ref = weakref(mundo)

func _mundo() -> Mundo:
	return _ref.get_ref() as Mundo

func esta_cedido(pid: String) -> bool:
	return cesiones.has(pid)

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

## Puntos internos a euros de pantalla, con las abreviaturas y la coma decimal
## española. Es el `fmt$` del HTML. Público y estático a propósito: `Prensa`
## tiene ahora mismo una copia privada de esto, y el día que se unifiquen basta
## con que llame aquí.
static func dinero(n: int) -> String:
	return Eco.dinero(n)

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

## Los datos de una cesión viva, o vacío. Para pintarla en la ficha del jugador
## sin tener que hurgar en el diccionario desde la interfaz.
func cesion_de(pid: String) -> Dictionary:
	return cesiones.get(pid, {})

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
