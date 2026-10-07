class_name Mercado
extends RefCounted
## El mercado de fichajes: cuánto piden, cuánto quieren venir y quién acepta.
##
## Son tres puertas distintas y hay que pasar las tres, que es exactamente como
## está en el HTML y lo que hace que fichar sea una decisión y no una compra:
##
##   1. El CLUB VENDEDOR pide un precio (`valor_pedido`) y decide si acepta la
##      oferta que le llega (`club_acepta`).
##   2. El JUGADOR decide si quiere venir (`deseo_de_venir`) y cuánto pide de
##      ficha (`ficha_que_pide`) — cuanto menos ganas tiene, más caro se pone.
##   3. El CLUB COMPRADOR tiene que poder pagar las dos cosas.
##
## Un club rico puede quedarse sin fichar a nadie si el jugador no quiere ir, y
## uno pobre puede llevarse una joya si el chico quiere jugar. Eso es lo que se
## pierde si se simplifica a "tienes el dinero, es tuyo".

signal traspaso(jugador: Jugador, de: Club, a: Club, monto: int)
## Alguien se fijó en un jugador tuyo y ofrece por él -queda en
## `ofertas_recibidas` hasta que la respondas, no es una venta automática-.
signal oferta_recibida(jugador: Jugador, club: Club, monto: int)

## `G.ofertasIn` del HTML: ofertas sobre tus jugadores, a la espera de que las
## aceptes o las rechaces desde el menú. `{jugador, club, monto, semana,
## clausula}` -objetos directos, no ids: ni Jugador ni Club apuntan de vuelta
## al Mundo, así que no hace falta buscar nada con `WeakRef` para guardarlos-.
var ofertas_recibidas: Array[Dictionary] = []

## La mesa de negociación abierta, si hay una -`G.negoc` del HTML-. Solo una a
## la vez, como en el original: abrir otra reemplaza la que hubiera.
var negociacion: Negociacion = null

## OJO: referencia DEBIL al mundo, no fuerte.
##
## El mundo guarda su mercado y el mercado necesita ver el mundo entero (el
## precio depende de la caja del club vendedor). Con dos referencias normales eso
## es un ciclo, y RefCounted no recoge ciclos: al salir del banco de pruebas se
## quedaban 16.580 objetos sin liberar, porque un Mundo que no muere se lleva
## consigo sus 384 clubes y sus 8.448 jugadores.
##
## Con WeakRef el mercado mira al mundo sin sujetarlo. Quien manda en la vida del
## mundo es quien lo creo, que es lo correcto.
var _ref: WeakRef

func _init(mundo: Mundo) -> void:
	_ref = weakref(mundo)

func _mundo() -> Mundo:
	return _ref.get_ref() as Mundo

## Lo que pide su club por él. Portado tal cual, con todos sus modificadores:
## el club rico no necesita vender, el ahogado rebaja, y las joyas de 20 años
## con techo alto son carísimas aunque hoy no rindan.
func valor_pedido(j: Jugador) -> int:
	var c: Club = _mundo().clubes.get(j.club_id)
	var p := float(j.valor)
	if c == null:
		return int(round(p))
	p *= 1.0 + clampf((float(c.rep) - 70.0) / 100.0, -0.25, 0.45)
	if float(c.saldo) < Eco.ref_caja(float(c.rep)) * 0.25:
		p *= 0.72                                    ## ahogado: acepta menos
	if j.anios_contrato <= 1:
		p *= 0.68                                    ## último año de contrato
	if j.pide_salir:
		p *= 0.75
	if j.edad <= 21 and j.pot >= j.ovr + 10:
		p *= 1.35                                    ## joya: carísima
	## JUEGO LIMPIO (26-9-2026, `Reputacion`): a quien tiene fama de honesto
	## le piden menos; a quien no, más. Solo cuando compras tú.
	var m := _mundo()
	if m != null and m.roles != null and j.club_id != m.mi_club_id:
		p *= m.roles.reputacion.mult_compras()
	return int(max(1000.0, round(p / 1000.0) * 1000.0))

## Las ganas que tiene de ir a `destino`, de 0 a 1, con los motivos para poder
## enseñárselos al jugador. Devolver solo el número sería la mitad del trabajo:
## lo que hace que una negociación se entienda es saber POR QUÉ dice que no.
func deseo_de_venir(j: Jugador, destino: Club) -> Dictionary:
	var suyo: Club = _mundo().clubes.get(j.club_id)
	var razones: Array[Dictionary] = []
	var p := 0.50
	if suyo != null:
		var d := float(destino.rep - suyo.rep)
		p += clampf(d * 0.020, -0.34, 0.26)
		if d <= -8.0:
			razones.append({"bien": false, "txt": "Viene de un club más grande: %d de reputación contra tus %d" % [suyo.rep, destino.rep]})
		elif d >= 8.0:
			razones.append({"bien": true, "txt": "Tu club es un salto de categoría para él"})
		if destino.pais == suyo.pais:
			if destino.division > suyo.division:
				p -= 0.30
				razones.append({"bien": false, "txt": "Bajaría de división"})
			elif destino.division < suyo.division:
				p += 0.16
				razones.append({"bien": true, "txt": "Subiría de división"})
		else:
			var t := Eco.tier_pais(destino.pais) - Eco.tier_pais(suyo.pais)
			p += clampf(t * 0.35, -0.24, 0.18)
			if t < -0.12:
				razones.append({"bien": false, "txt": "Cambiar de país para ir a una liga menor no le seduce"})
			elif t > 0.12:
				razones.append({"bien": true, "txt": "Daría el salto a una liga más fuerte"})
	if j.pide_salir:
		p += 0.20
		razones.append({"bien": true, "txt": "Ya pidió salir de su club"})
	if j.moral < 40:
		p += 0.10
		razones.append({"bien": true, "txt": "Está incómodo donde está"})
	if j.anios_contrato <= 1:
		p += 0.08
		razones.append({"bien": true, "txt": "Le queda un año de contrato"})
	## LO QUE PESA TU NOMBRE. `Entrenamiento.bono_fichajes()` sumaba un 10% por
	## «Ícono» y un 6% por «Negociador» y no la llamaba nadie: los dos nodos del
	## árbol que existen PARA fichar mejor no servían para fichar mejor.
	## Solo cuenta si el destino es TU club: la IA no tiene árbol de entrenador.
	var m := _mundo()
	if m != null and m.entrenamiento != null and destino != null and destino.id == m.mi_club_id:
		var tuyo := m.entrenamiento.bono_fichajes()
		if tuyo > 0.0:
			p += tuyo
			razones.append({"bien": true, "txt": "Tu nombre pesa: te escucha antes que a otros"})
		## EL PRESTIGIO DEL DT -`bonusReputacion().fichajes` del HTML, que
		## `deseoDeVenir()` suma aparte del bonus fijo de «Ícono»-. Es una curva
		## continua: un DT de prestigio 20 también se nota, pero en contra.
		if m.roles != null:
			var rep := m.roles.bono_reputacion_fichajes()
			if absf(rep) >= 0.01:
				p += rep
				razones.append({"bien": rep > 0.0,
					"txt": "Tu prestigio como entrenador le convence" if rep > 0.0
						else "Tu poco prestigio como entrenador le echa para atrás"})
	return {"p": clampf(p, 0.02, 0.98), "razones": razones}

## La ficha que pide. El recargo es la pieza clave: si no quiere venir, no dice
## que no, dice un número. Un jugador con pocas ganas puede pedir un 80% más.
func ficha_que_pide(j: Jugador, destino: Club, anios: int = 3) -> int:
	var d: float = deseo_de_venir(j, destino)["p"]
	var base := float(j.sueldo)
	## Contratos largos cuestan algo más por semana: el jugador cobra la
	## seguridad por adelantado.
	base *= 1.0 + float(anios - 3) * 0.04
	var recargo := 1.0 + clampf((0.5 - d) * 1.5, -0.15, 0.80)
	return int(max(30.0, round(base * recargo / 10.0) * 10.0))

## ¿Acepta el club vendedor esta oferta? Con el 90% de lo pedido casi siempre;
## por debajo del 70%, nunca. En medio hay una zona donde influye si necesita el
## dinero, que es donde el regateo tiene sentido.
func club_acepta(j: Jugador, monto: int) -> bool:
	var pedido := valor_pedido(j)
	if pedido <= 0:
		return true
	var ratio := float(monto) / float(pedido)
	if ratio >= 0.98:
		return true
	if ratio < 0.70:
		return false
	var c: Club = _mundo().clubes.get(j.club_id)
	var ahogado := c != null and float(c.saldo) < Eco.ref_caja(float(c.rep)) * 0.25
	var umbral := 0.80 if ahogado else 0.92
	return ratio >= umbral

## ¿Firma el jugador? Por debajo del 92% de lo que pide no hay ficha que valga,
## por mucho que le guste el proyecto: es la regla del HTML y evita que el
## regateo de la ficha sea infinito.
func jugador_firma(j: Jugador, destino: Club, sueldo_ofrecido: int, anios: int = 3) -> bool:
	var pide := ficha_que_pide(j, destino, anios)
	if float(sueldo_ofrecido) < float(pide) * 0.92:
		return false
	var d: float = deseo_de_venir(j, destino)["p"]
	## Pagar de más compra ganas, pero no las compra todas.
	var extra := clampf((float(sueldo_ofrecido) / float(pide) - 1.0) * 0.5, 0.0, 0.25)
	return Azar.suerte(clampf(d + extra, 0.03, 0.97))

## Ejecuta el traspaso. No comprueba nada: quien llama ya decidió. Esto solo
## mueve el dinero y al jugador, en ese orden y sin dejar estados a medias.
func fichar(j: Jugador, comprador: Club, monto: int, sueldo: int, anios: int) -> void:
	var vendedor: Club = _mundo().clubes.get(j.club_id)
	comprador.mover_saldo(-monto)
	if vendedor != null:
		vendedor.mover_saldo(monto)
		vendedor.soltar(j)
	j.sueldo = sueldo
	j.anios_contrato = Contratos.ajustar_anios(j, anios)
	j.pide_salir = false
	comprador.fichar(j)
	## Para el documental de la temporada (fase 5): los traspasos de tu club.
	var m := _mundo()
	if m != null and (comprador.id == m.mi_club_id or (vendedor != null and vendedor.id == m.mi_club_id)):
		fichajes_temporada.append({"nombre": j.nombre, "entra": comprador.id == m.mi_club_id,
			"otro": (vendedor.nombre if vendedor != null else "libre") if comprador.id == m.mi_club_id else comprador.nombre,
			"monto": monto, "ovr": j.ovr})
	traspaso.emit(j, vendedor, comprador, monto)

## Los traspasos de tu club en esta temporada (se vacía al cerrarla).
var fichajes_temporada: Array = []

# ---------------------------------------------------------------------------
#  EL MERCADO DE LA IA
# ---------------------------------------------------------------------------

## Mueve el mercado entre clubes de la IA una vez por semana.
##
## Sin esto el mundo se congela: los mismos jugadores en los mismos clubes
## durante veinte temporadas, y el jugador humano es el único que ficha. Con
## esto la tabla cambia sola de un año a otro, que es la mitad de la gracia de
## un manager.
##
## No se recorren los 384 clubes: se sortean unos pocos compradores por semana.
## Recorrerlos todos daría cientos de fichajes semanales -un mundo irreconocible
## en un mes- y costaría lo que cuesta mirar 8.000 jugadores.
func mover(compradores_por_semana: int = 6) -> Array[Dictionary]:
	var hechos: Array[Dictionary] = []
	var lista: Array = _mundo().clubes.values()
	if lista.size() < 4:
		return hechos
	for i in compradores_por_semana:
		var comprador: Club = lista[Azar.ent(0, lista.size() - 1)]
		if comprador.id == _mundo().mi_club_id:
			continue                       ## a tu club no le fichan solos
		if comprador.plantilla.size() >= 26:
			continue
		var objetivo := _buscar_objetivo(comprador)
		if objetivo == null:
			continue
		var pedido := valor_pedido(objetivo)
		## La IA no se arruina: solo gasta una parte de lo que tiene.
		if float(pedido) > float(comprador.saldo) * 0.45:
			continue
		if not club_acepta(objetivo, pedido):
			continue
		var sueldo := ficha_que_pide(objetivo, comprador)
		if not jugador_firma(objetivo, comprador, sueldo):
			continue
		var vendedor: Club = _mundo().clubes.get(objetivo.club_id)
		if vendedor != null and vendedor.plantilla.size() <= 19:
			continue                       ## nadie se queda sin plantilla
		fichar(objetivo, comprador, pedido, sueldo, Azar.ent(2, 5))
		hechos.append({"jugador": objetivo, "de": vendedor, "a": comprador, "monto": pedido})
	return hechos

## Busca a quién ficharía este club: alguien mejor que su plantilla actual, de
## otro club, y de un tamaño parecido. Se mira una muestra al azar en vez de los
## 8.000 jugadores del mundo, que es lo que permite que esto corra cada semana.
## CLUBES QUE SOLO FICHAN DE SU TIERRA: ver `Regiones` (26-9-2026, plan
## maestro C3). Aquí había una aproximación por "mismo país" porque `Jugador` no
## tenía región; ya la tiene, y la regla es la real (Euskal Herria).
func _buscar_objetivo(comprador: Club) -> Jugador:
	var lista: Array = _mundo().clubes.values()
	var media := comprador.media()
	var mejor: Jugador = null
	var mejor_v := media + 1.0
	for intento in 12:
		var otro: Club = lista[Azar.ent(0, lista.size() - 1)]
		if otro.id == comprador.id or otro.plantilla.is_empty():
			continue
		if otro.id == _mundo().mi_club_id:
			continue                       ## a ti te fichan negociando, no solos
		var j: Jugador = otro.plantilla[Azar.ent(0, otro.plantilla.size() - 1)]
		if j.edad > 33:
			continue
		## CON SENTIDO DE PUESTO (7-10-2026, la prueba larga): la IA compraba al
		## que mejorara su media sin mirar dónde juega, y en diez temporadas había
		## clubes con 6-7 porteros y otros sin un solo delantero. No compra un
		## cuarto portero ni deja al vendedor por debajo del mínimo de su línea.
		if _cuenta_linea(comprador, j.pos) >= int(MAXIMO_LINEA.get(j.pos, 9)):
			continue
		if _cuenta_linea(otro, j.pos) <= int(MINIMO_LINEA.get(j.pos, 2)):
			continue
		## Filosofía de cantera (C3): el Athletic solo mira a los de su tierra.
		if not Regiones.admite(comprador, j):
			continue
		if float(j.ovr) > mejor_v:
			mejor_v = float(j.ovr)
			mejor = j
	return mejor

const MINIMO_LINEA := {"POR": 2, "DEF": 5, "MED": 5, "DEL": 3}
const MAXIMO_LINEA := {"POR": 3, "DEF": 10, "MED": 10, "DEL": 7}

static func _cuenta_linea(c: Club, linea: String) -> int:
	var n := 0
	for x: Jugador in c.plantilla:
		if x.pos == linea:
			n += 1
	return n

# ---------------------------------------------------------------------------
#  VENDER: LISTA DE TRANSFERIBLES Y OFERTAS ENTRANTES
# ---------------------------------------------------------------------------
# `_buscar_objetivo()` de arriba excluye a propósito a tu club ("a ti te fichan
# negociando, no solos"): la IA nunca elige comprarte por su cuenta. Esto es lo
# que le da la otra mitad de "vender jugadores" al HTML -listarTransferible()
# y el sorteo de juego.js:2913-2932- que en Godot no tenía ningún equivalente,
# ni la marca ni el sorteo ni la bandeja de ofertas.
#
# Fuera de alcance a propósito, porque son sistemas propios que tampoco están
# portados todavía: el % de una venta futura pactado al vender (`pctVenta` del
# HTML) y la ficha de "ex mío" para cuando te toca enfrentar a quien vendiste.

## Pone a un jugador tuyo "en venta": listarTransferible() del HTML. No hace
## nada si ya estaba -ponerlo dos veces no debería doler el doble-.
func listar_transferible(j: Jugador) -> void:
	if j.transferible:
		return
	j.transferible = true
	j.moral = clampi(j.moral - 8, 10, 99)

## Una vez por semana, puede llegar una oferta por un jugador tuyo. Los que
## están en la lista de transferibles entran TRES veces en la bolsa -dos más
## que el resto de tu plantel con media 68+-, que es justo lo que el propio
## HTML dice que arregla: antes de esto, marcar a alguien de transferible no
## cambiaba nada.
func buscar_oferta_por_mi_jugador() -> void:
	if not Azar.suerte(0.40):
		return
	var mio := _mundo().mi_club()
	if mio == null:
		return
	var elegibles: Array[Jugador] = []
	var listados: Array[Jugador] = []
	for j in mio.plantilla:
		if j.ovr >= 68:
			elegibles.append(j)
		if j.transferible:
			listados.append(j)
	var bolsa: Array[Jugador] = elegibles + listados + listados
	if bolsa.is_empty():
		return
	var j: Jugador = bolsa[Azar.ent(0, bolsa.size() - 1)]
	var candidatos: Array[Club] = []
	for c in _mundo().clubes.values():
		if c.id == mio.id:
			continue
		if c.rep >= j.ovr - 14 and float(c.saldo) >= float(j.valor) * 1.6:
			candidatos.append(c)
	if candidatos.is_empty():
		return
	var comprador: Club = candidatos[Azar.ent(0, candidatos.size() - 1)]
	var monto := int(round(float(j.valor) * (0.85 + Azar.f() * 0.5)))
	## Fama de negociador: te ofrecen más por tus jugadores.
	if _mundo().roles != null:
		monto = int(round(float(monto) * _mundo().roles.reputacion.mult_ventas()))
	var es_clausula := false
	var cesiones := _mundo().cesiones
	if cesiones != null:
		var clausula := int(cesiones.clausulas.get(j.id, 0))
		## "La cláusula es ley": si la oferta ya la cubre casi entera, se paga
		## la cláusula exacta y la respuesta no puede ser un no -ver
		## responder_oferta()-.
		if clausula > 0 and float(monto) >= float(clausula) * 0.85:
			monto = clausula
			es_clausula = true
	ofertas_recibidas.append({"jugador": j, "club": comprador, "monto": monto,
		"semana": _mundo().semana, "clausula": es_clausula})
	oferta_recibida.emit(j, comprador, monto)

## Acepta o rechaza la oferta `idx` de `ofertas_recibidas`. Si es de cláusula,
## `acepta` se fuerza a `true` -no hay forma de decir que no a una cláusula-.
## Al aceptar: el dinero se mueve, el jugador cambia de club y se le apaga la
## marca de transferible. Al rechazar, a veces se lo toma mal.
func responder_oferta(idx: int, acepta: bool) -> void:
	if idx < 0 or idx >= ofertas_recibidas.size():
		return
	var o: Dictionary = ofertas_recibidas[idx]
	ofertas_recibidas.remove_at(idx)
	if bool(o.get("clausula", false)):
		acepta = true
	var j: Jugador = o["jugador"]
	var comprador: Club = o["club"]
	var monto: int = int(o["monto"])
	if acepta:
		var vendedor: Club = _mundo().clubes.get(j.club_id)
		## `Cesiones.vender()` es el `responderOferta()` de verdad -estaba escrito
		## y probado desde hacía tiempo, sin que nadie lo llamara: cobra menos hoy
		## si te reservas un % de su próxima venta (no aplica aquí, `ofertas_
		## recibidas` no negocia ese término todavía) y, sobre todo, LE PAGA a
		## quien te vendió a ti este jugador si en su día se guardó su propio
		## porcentaje -la primera versión de este método movía el dinero a mano y
		## se saltaba esa deuda entera-.
		var cesiones := _mundo().cesiones
		if cesiones != null:
			cesiones.vender(j, comprador, monto, 0)
		else:
			comprador.mover_saldo(-monto)
			if vendedor != null:
				vendedor.mover_saldo(monto)
				vendedor.soltar(j)
			comprador.fichar(j)
		j.moral = 70
		j.transferible = false
		j.pide_salir = false
		## Operación rentable = fama de negociador (idea 608); malvender, lo
		## contrario. Se compara con lo que vale el jugador.
		var m2 := _mundo()
		if m2 != null and m2.roles != null and j.valor > 0:
			var razon := float(monto) / float(j.valor)
			var d := clampi(int(round((razon - 1.0) * 20.0)), -5, 6)
			if d != 0:
				m2.roles.anotar_reputacion("negociador", d, "Venta de %s por el %d %% de su valor" % [j.nombre, int(razon * 100.0)])
		traspaso.emit(j, vendedor, comprador, monto)
	elif Azar.suerte(0.40):
		j.moral = clampi(j.moral - 10, 10, 99)

## `ofertas_recibidas` guarda objetos (`Jugador`/`Club`) directos, no ids -no
## hacía falta buscarlos porque ninguno de los dos apunta de vuelta al Mundo-,
## pero un guardado es texto, así que aquí sí hay que pasar por su id.
func a_dic() -> Dictionary:
	var lista: Array = []
	for o: Dictionary in ofertas_recibidas:
		lista.append({
			"jugador_id": (o["jugador"] as Jugador).id, "club_id": (o["club"] as Club).id,
			"monto": int(o["monto"]), "semana": int(o["semana"]), "clausula": bool(o["clausula"]),
		})
	return {"ofertas_recibidas": lista}

func desde_dic(d: Dictionary) -> void:
	ofertas_recibidas.clear()
	var m := _mundo()
	if m == null:
		return
	for o: Dictionary in d.get("ofertas_recibidas", []):
		var club: Club = m.clubes.get(String(o.get("club_id", "")))
		var j := _jugador_por_id(String(o.get("jugador_id", "")))
		## Entre que se guardó y se volvió a cargar no ha pasado nada -es la misma
		## sesión-, pero si algún día un guardado viejo apunta a alguien que ya no
		## está (retirado, vendido a un club que ya no existe), se descarta la
		## oferta en vez de reventar la carga por ella.
		if club == null or j == null:
			continue
		ofertas_recibidas.append({"jugador": j, "club": club, "monto": int(o.get("monto", 0)),
			"semana": int(o.get("semana", 0)), "clausula": bool(o.get("clausula", false))})

func _jugador_por_id(id: String) -> Jugador:
	if id == "":
		return null
	for c in _mundo().clubes.values():
		for j in c.plantilla:
			if j.id == id:
				return j
	return null

# ---------------------------------------------------------------------------
#  LA MESA DE NEGOCIACIÓN
# ---------------------------------------------------------------------------

## `abrirNegociacion()` del HTML: las puertas que hay que pasar ANTES de
## sentarse -rol, ventana de mercado, cupo de extranjeros, "no me quiere
## hablar hasta la semana X" tras una mesa rota-. Devuelve "" si se abrió.
func abrir_negociacion(j: Jugador) -> String:
	var m := _mundo()
	var mio := m.mi_club()
	if j == null or mio == null or j.club_id == mio.id:
		return "ese jugador ya es tuyo"
	if m.roles != null and not m.roles.puede_fichar():
		return String(m.roles.motivo_bloqueo("fichar"))
	if m.tiene_desafio("cantera"):
		return "Desafío «solo canteranos»: el mercado te queda vetado."
	if m.tiene_desafio("local") and j.pais != mio.pais:
		return "Desafío «un solo país»: no puedes fichar extranjeros."
	if j.no_negociar_hasta > 0 and m.semana < j.no_negociar_hasta:
		return "%s no se sienta a hablar de él hasta la semana %d" % [
			(m.clubes.get(j.club_id) as Club).nombre if m.clubes.has(j.club_id) else "Su club", j.no_negociar_hasta]
	## Si diriges un club con filosofía de cantera, la respetas tú también.
	if not Regiones.admite(mio, j):
		var mot := Regiones.motivo(mio)
		return mot[0].to_upper() + mot.substr(1)
	if m.federacion != null:
		var motivo_ext := m.federacion.puede_fichar_extranjero(mio, j)
		if motivo_ext != "":
			return motivo_ext
	negociacion = Negociacion.new(m, j)
	return ""

func cerrar_negociacion() -> void:
	negociacion = null
