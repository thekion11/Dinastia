extends "res://nucleo/cantera_p2.gd"
## (Parte 3 de 4 de `cantera.gd`.)

func _chequeo_fugas() -> Array[Dictionary]:
	var m := _mundo()
	var sucesos: Array[Dictionary] = []
	if m == null:
		return sucesos
	var mio := m.mi_club()
	if mio == null:
		return sucesos
	## Se copia la lista antes de recorrerla: dentro del bucle se saca gente de
	## la plantilla, y modificar el array que estás recorriendo se salta jugadores.
	for j in mio.plantilla.duplicate():
		if not Azar.suerte(riesgo_fuga(j)):
			continue
		var destino := _grande_que_se_lo_lleva(m, mio, j)
		if destino == null:
			continue
		var compensacion := int(round(float(j.valor) * DERECHOS_FORMACION))
		mio.mover_saldo(compensacion)
		movimiento.emit("Derechos de formación: %s" % j.nombre, compensacion)
		mio.soltar(j)
		destino.fichar(j)
		canterano_robado.emit(j, destino, compensacion)
		noticia.emit("Te roban un canterano",
			"%s se lleva a %s (%d años, proyección %d) aprovechando que no tenía contrato profesional. Solo cobras los derechos de formación. Con residencia, academia y becas esto pasa mucho menos." % [
				destino.nombre, j.nombre, j.edad, j.pot])
		sucesos.append({"tipo": "fuga", "jugador": j, "destino": destino, "monto": compensacion})
	return sucesos

## Cada semana la prensa mide si el chico está a la altura del apellido que le
## colgaron. Si rinde, lo bendicen; si no, lo entierran. A las seis semanas malas
## le pasan factura, y a los ocho aciertos se lo quitan de encima para siempre.
func _proceso_etiquetas() -> Array[Dictionary]:
	var m := _mundo()
	var sucesos: Array[Dictionary] = []
	if m == null or m.mi_club() == null:
		return sucesos
	for j in m.mi_club().plantilla:
		var e: Dictionary = _fichas.get(j.id, {}).get("etiqueta", {})
		if e.is_empty() or bool(e.get("libre", false)):
			continue
		var anios := m.anio - int(e.get("desde", m.anio))
		var rinde := j.partidos >= 4 and j.media_notas(3) >= 6.6
		if rinde:
			e["cumple"] = int(e.get("cumple", 0)) + 1
			e["presion"] = maxi(0, int(e.get("presion", 0)) - 1)
		elif anios >= 1 and j.partidos >= 6:
			e["presion"] = int(e.get("presion", 0)) + 1
		if int(e["presion"]) == 6:
			var _m0 := j.moral
			j.moral = clampi(j.moral - 14, 5, 99)
			j.anotar_moral(j.moral - _m0, "Cantera")
			etiqueta_pesa.emit(j, String(e.get("ref", "")))
			noticia.emit("El peso de un apellido",
				"La prensa se cansó de esperar a %s. «El nuevo %s no aparece», titulan hoy. El chico entrenó cabizbajo toda la semana: la etiqueta que le pusieron a los diecisiete le pesa como una mochila de piedras." % [
					j.nombre, String(e.get("ref", ""))])
			sucesos.append({"tipo": "etiqueta_pesa", "jugador": j})
		if int(e.get("cumple", 0)) >= 8:
			e["libre"] = true
			var _m0 := j.moral
			j.moral = clampi(j.moral + 12, 5, 99)
			j.anotar_moral(j.moral - _m0, "Cantera")
			etiqueta_superada.emit(j, String(e.get("ref", "")))
			noticia.emit("Ya no es «el nuevo» nadie",
				"%s se sacó la etiqueta de encima a fuerza de partidos. Hoy la prensa escribe su nombre solo, sin compararlo con %s." % [
					j.nombre, String(e.get("ref", ""))])
			sucesos.append({"tipo": "etiqueta_superada", "jugador": j})
	return sucesos

## El pulso semanal de la cantera: quién se va y a quién le pesa el apellido.
## Devuelve lo que ha pasado, para que quien llame pueda contarlo o ignorarlo.
func procesar_semana() -> Array[Dictionary]:
	var sucesos: Array[Dictionary] = []
	sucesos.append_array(_chequeo_fugas())
	sucesos.append_array(_proceso_etiquetas())
	return sucesos
func etiqueta_de(j: Jugador) -> Dictionary:
	return _fichas.get(j.id, {}).get("etiqueta", {}) if j != null else {}

## La ficha de origen completa (icono, frase e historia), para poder contarla en
## la ficha del jugador. Devuelve vacío si el chico no tiene origen sorteado.
func origen_de(j: Jugador) -> Dictionary:
	var clave := String(_fichas.get(j.id, {}).get("origen", "")) if j != null else ""
	if clave == "":
		return {}
	var origenes: Variant = Datos.tabla("ORIGENES")
	if not (origenes is Array):
		return {}
	for o: Array in origenes:
		if String(o[0]) == clave:
			return {"id": clave, "icono": String(o[1]), "frase": String(o[2]), "historia": String(o[3])}
	return {}

## Un chico que llega de la Academia (10-16 años, `Academia`) es tan canterano
## como uno de la camada: se anota igual, con su año, para el linaje, las
## etiquetas y la cuenta de debutantes del modo director de cantera.
func registrar_de_academia(j: Jugador, anio: int) -> void:
	var f := _ficha(j.id)
	f["camada"] = anio
	f["origen"] = "academia"

func es_canterano(j: Jugador) -> bool:
	return j != null and _fichas.get(j.id, {}).has("camada")


# ===========================================================================
#  LA PROMESA DEL COMPATRIOTA
# ===========================================================================

## Le prometiste traerle a alguien de su país. En el HTML esto se guardaba y
## nadie lo comprobaba nunca: era una frase gratis en una negociación. Aquí se
## apunta el año y al cerrar la temporada se pasa factura.
func prometer_compatriota(j: Jugador) -> void:
	var m := _mundo()
	if j == null or m == null:
		return
	_ficha(j.id)["promesa_compa"] = m.anio

func tiene_promesa(j: Jugador) -> bool:
	return j != null and int(_fichas.get(j.id, {}).get("promesa_compa", 0)) > 0

## Se pasa la cuenta de las promesas. Se llama al cerrar la temporada.
##
## La plantilla se lee UNA vez y se comprueba sobre esa lista: pedirla otra vez
## dentro del bucle era recorrer el plantel entero tantas veces como promesas
## hubiera, para nada. Es la nota que dejó el propio HTML.
func chequeo_promesas() -> Array[Dictionary]:
	var m := _mundo()
	var salida: Array[Dictionary] = []
	if m == null or m.mi_club() == null:
		return salida
	var plantel := m.mi_club().plantilla
	for j in plantel:
		if not tiene_promesa(j):
			continue
		var cumplida := false
		for x in plantel:
			if x.id != j.id and x.pais == j.pais:
				cumplida = true
				break
		if cumplida:
			j.cambiar_moral(8, "Cantera")
			noticia.emit("Promesa cumplida: %s" % j.nombre,
				"Le prometiste traer a alguien de su país y ahora tiene con quién hablar en su idioma. Se le nota en el ánimo.")
		else:
			## EL TRADUCTOR AMORTIGUA EL GOLPE. Con uno bueno, el extranjero que se
			## quedo sin compatriota se siente solo pero no se hunde, y sobre todo no
			## pide salir: es exactamente para lo que se le paga.
			var amortigua := m.staff.adaptacion_extranjeros() if m.staff != null else 1.0
			j.cambiar_moral(-(int(round(16.0 * amortigua))), "Cantera")
			j.pide_salir = amortigua > 0.5
			noticia.emit("Promesa incumplida: %s" % j.nombre,
				"Pasó la temporada y nunca llegó ese compatriota que le prometiste. Se siente solo, la moral se le cayó y ya pidió salir.")
		_ficha(j.id)["promesa_compa"] = 0
		promesa_resuelta.emit(j, cumplida)
		salida.append({"jugador": j, "cumplida": cumplida})
	return salida


# ===========================================================================
#  LOS REPRESENTANTES
# ===========================================================================
#
# Cada jugador tiene agente y el agente tiene perfil. Un tiburón te cobra un 20%
# más en cada mesa y se lleva el 12% de comisión; un formador negocia por debajo
# del mercado porque le interesa que su chico juegue. No es un adorno: es lo que
# hace que dos jugadores idénticos cuesten distinto según quién firme por ellos.
#
# LA TABLA NO SE DUPLICA. `Prensa.agente_de()` ya la lee de `AGENTES` y
# `AG_PERFIL` con el hash del id, que es lo que garantiza que el mismo futbolista
# tenga siempre al mismo representante. Aquí se delega en ella y lo que se añade
# es lo que faltaba: qué hace ese perfil en la mesa de negociación y qué pasa
# cuando una agencia controla a media plantilla.

## El agente de un jugador. Delega en `Prensa`, que es donde está la tabla.
## Si todavía no hay prensa (mundo generado pero sin club tomado), devuelve un
## representante neutro para que ninguna fórmula se quede sin factor.
func agente_de(j: Jugador) -> Dictionary:
	var m := _mundo()
	if m != null and m.prensa != null and j != null:
		return m.prensa.agente_de(j)
	return {"nombre": "un representante", "perfil": "discreto", "etiqueta": "discreto", "f": 1.0, "com": 0.10}

## Cuánto multiplica este agente lo que su cliente pide. El tiburón un 20% más,
## el formador un 5% menos. Va en renovaciones, primas de fichaje y finiquitos.
func factor_pide(j: Jugador) -> float:
	return float(agente_de(j).get("f", 1.0))

## La comisión que se lleva de una operación. Se paga APARTE del traspaso: es el
## dinero que desaparece de la caja sin que llegue a nadie del club, y es la
## razón de que un fichaje cueste siempre más de lo que dice el titular.
func comision(j: Jugador, monto: int) -> int:
	return int(round(float(monto) * float(agente_de(j).get("com", 0.10))))

## Lo que pide para renovar: el sueldo actual con recargo por moral baja y por
## rendir por encima del club, todo multiplicado por su agente.
func pide_para_renovar(j: Jugador) -> int:
	var m := _mundo()
	var rep := 70
	if m != null and m.mi_club() != null:
		rep = m.mi_club().rep
	var f := 1.1
	f += 0.35 if j.moral < 50 else 0.15
	if j.ovr >= rep:
		f += 0.20
	return int(round(float(j.sueldo) * f * factor_pide(j)))

## `renovarJug()` del HTML: se le firma lo que pide. Con cláusula de salida
## acepta un 10% MENOS de sueldo -le pones precio de salida, y a cambio cobra
## menos-, que es la única decisión de verdad que hay aquí.
##
## `pide_para_renovar()` llevaba tiempo escrita y nadie la llamaba: se podía
## calcular lo que pedía un jugador, pero no había forma de decirle que sí.
func renovar(j: Jugador, con_clausula: bool = false) -> Dictionary:
	var m := _mundo()
	if m == null or j == null or j.club_id != m.mi_club_id:
		return {"error": "ese jugador no es tuyo"}
	var pedido := pide_para_renovar(j)
	j.sueldo = int(round(float(pedido) * 0.9)) if con_clausula else pedido
	j.anios_contrato = Contratos.ajustar_anios(j, Azar.ent(2, 4))
	var clausula := 0
	if con_clausula and m.cesiones != null:
		clausula = m.cesiones.pactar_clausula(j)
	## El agente mediático se apunta el tanto en la prensa y el jugador queda
	## contento: el mismo +3 de moral que el HTML.
	var ag := agente_de(j)
	if String(ag.get("perfil", "")) == "mediatico":
		j.cambiar_moral(3, "Cantera")
	noticia.emit("Renovado: %s" % Nombres.visible(j.nombre),
		"Firma por %d temporadas a %d/sem%s. Negoció su agente %s (%s)." % [
			j.anios_contrato, j.sueldo,
			" con cláusula de salida" if con_clausula else "",
			String(ag.get("nombre", "?")), String(ag.get("perfil", ""))])
	return {"ok": true, "sueldo": j.sueldo, "anios": j.anios_contrato, "clausula": clausula}

## Semanas de contrato que le quedan: lo que falta de esta temporada más las
## enteras que vienen. Mínimo cuatro, porque nadie firma una salida por cero.
func semanas_de_contrato(j: Jugador) -> int:
	var m := _mundo()
	var total := SEMANAS_TEMPORADA
	if m != null and m.mi_club() != null:
		var l := m.liga_de(m.mi_club())
		if l != null and l.jornadas() > 0:
			total = l.jornadas()
	var restantes := total - (m.semana if m != null else 1)
	return maxi(4, restantes + maxi(0, j.anios_contrato - 1) * total)

## Lo que cuesta rescindirle el contrato. El 0,6 es lo que se arregla de verdad:
## nadie paga el 100% de lo que queda, pero un tiburón te deja mucho más cerca
## del 100% que un formador. Si el jugador ya se quiere ir, la salida es barata.
func finiquito(j: Jugador) -> int:
	var base := float(semanas_de_contrato(j)) * float(j.sueldo) * 0.6 * factor_pide(j)
	if j.pide_salir:
		base *= 0.55
	return int(max(1000.0, round(base / 1000.0) * 1000.0))

## Lo que cuesta la rescisión completa: finiquito más la comisión de salida.
func coste_rescision(j: Jugador) -> Dictionary:
	var fin := finiquito(j)
	var com := comision(j, fin)
	return {"finiquito": fin, "comision": com, "total": fin + com}

## Prima de fidelidad -ofrecerFidelidad() del HTML-: se paga por adelantado y
## el jugador no pide salida en tres temporadas. "" si se hizo, o el motivo por
## el que no.
func ofrecer_fidelidad(j: Jugador, c: Club) -> String:
	if j == null or c == null or j.club_id != c.id:
		return "ese jugador no es tuyo"
	if j.fidelidad_hasta > 0:
		return "ya tiene cláusula de fidelidad"
	var m := _mundo()
	var costo := int(round(float(j.sueldo) * 26.0))
	if c.saldo < costo:
		return "caja insuficiente: cuesta %d" % costo
	c.mover_saldo(-costo)
	j.fidelidad_hasta = (m.anio if m != null else 0) + 3
	j.cambiar_moral(14, "Cantera")
	noticia.emit("Prima de fidelidad: %s" % Nombres.visible(j.nombre),
		"Firma su cláusula de fidelidad hasta %d: no pedirá salir mientras siga vigente." % j.fidelidad_hasta)
	return ""

func confianza_de(agente: String) -> int:
	return int(confianza_agentes.get(agente, 0))

## Los representantes con más de un cliente en tu plantel, del que más manda al
## que menos. Es la foto que explica por qué el vestuario se mueve solo.
func agencias_del_plantel() -> Array[Dictionary]:
	var m := _mundo()
	if m == null or m.mi_club() == null:
		return []
	var por_agente := {}
	for j in m.mi_club().plantilla:
		var ag := agente_de(j)
		var n := String(ag.get("nombre", ""))
		if not por_agente.has(n):
			por_agente[n] = {"agente": ag, "jugadores": []}
		(por_agente[n]["jugadores"] as Array).append(j)
	var salida: Array[Dictionary] = []
	for n: String in por_agente:
		var d: Dictionary = por_agente[n]
		d["confianza"] = confianza_de(n)
		salida.append(d)
	salida.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (a["jugadores"] as Array).size() > (b["jugadores"] as Array).size())
	return salida

## Sortea la exigencia semanal de un representante. Devuelve el evento creado o
## vacío si esta semana no toca.
##
## Solo aparece si una agencia controla a DOS o más de tus jugadores: la presión
## de un agente con un solo cliente no es presión, es una conversación.
func sortear_guerra_agentes() -> Dictionary:
	var m := _mundo()
	if m == null or not exigencia.is_empty() or not Azar.suerte(0.055):
		return {}
	var mio := m.mi_club()
	if mio == null or mio.plantilla.size() < 8:
		return {}
	var fuertes: Array[Dictionary] = []
	for a in agencias_del_plantel():
		if (a["jugadores"] as Array).size() >= 2:
			fuertes.append(a)
	if fuertes.is_empty():
		return {}
	var elegida: Dictionary = Azar.uno(fuertes.slice(0, mini(3, fuertes.size())))
	var suyos: Array = elegida["jugadores"]
	var orden := suyos.duplicate()
	orden.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	var estrella: Jugador = orden[0]
	var nombre := String(elegida["agente"].get("nombre", ""))
	var etiqueta := String(elegida["agente"].get("etiqueta", "discreto"))
	var tipo := String(Azar.uno(["canterano", "mejora", "comision", "exclusiva"]))
	var ids: Array[String] = []
	for j: Jugador in suyos:
		ids.append(j.id)
	exigencia = {"tipo": tipo, "agente": nombre, "pid": estrella.id, "ids": ids,
		"perfil": String(elegida["agente"].get("perfil", "discreto"))}
	match tipo:
		"canterano":
			exigencia["txt"] = "%s (%s) controla a %d de tus jugadores. Te exige fichar a un canterano de su agencia o «no responde por el ánimo» de %s y compañía." % [
				nombre, etiqueta, suyos.size(), estrella.nombre]
			exigencia["opcion_a"] = "Fichar a su canterano"
			exigencia["opcion_b"] = "Que se olvide"
		"mejora":
			exigencia["txt"] = "%s exige mejorarle el contrato a %s ya mismo. Amenaza con bajar el rendimiento de sus representados si no lo haces." % [
				nombre, estrella.nombre]
			exigencia["opcion_a"] = "Mejorar el contrato"
			exigencia["opcion_b"] = "Aguantar la presión"
		"comision":
			exigencia["txt"] = "%s te pide una comisión extra por debajo de la mesa para «facilitar» la próxima operación. Es plata que no aparece en ningún libro." % nombre
			exigencia["opcion_a"] = "Pagar la comisión"
			exigencia["opcion_b"] = "Denunciarlo internamente"
		_:
			exigencia["txt"] = "%s te ofrece exclusividad: primero te muestra a ti a todos sus jugadores, pero espera que le compres al menos uno por temporada." % nombre
			exigencia["opcion_a"] = "Aceptar la exclusiva"
			exigencia["opcion_b"] = "Prefiero manos libres"
	agente_presiona.emit(exigencia)
	return exigencia

func hay_exigencia() -> bool:
	return not exigencia.is_empty()

func _mover_confianza(agente: String, d: int) -> void:
	confianza_agentes[agente] = clampi(confianza_de(agente) + d, -10, 10)

func _castigar_clientes(m: Mundo, castigo: int) -> void:
	var mio := m.mi_club()
	if mio == null:
		return
	for id: String in exigencia.get("ids", []):
		var x := _jugador(mio, id)
		if x != null:
			x.cambiar_moral(-castigo, "Cantera")
