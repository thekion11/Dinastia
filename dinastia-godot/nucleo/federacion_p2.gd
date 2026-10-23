extends "res://nucleo/federacion_p1.gd"
## (Parte 2 de 3 de `federacion.gd`.)

## Vota la moción pendiente. `opcion` es "a" (a favor) o "b" (en contra).
##
## `asamblea` son los clubes con derecho a voto: los de tu país y tu división.
## Pásala COMPLETA, con tu club dentro: el HTML recorre la lista entera —el tuyo
## incluido, que además vota por su cuenta— y después suma tu voto aparte. Es
## una rareza suya, pero cambiarla movería el umbral de aprobación de las seis
## mociones a la vez, así que se porta tal cual.
func votar(opcion: String, mi: Club, asamblea: Array) -> Dictionary:
	if voto_pendiente.is_empty() or mi == null:
		return {}
	var v := voto_pendiente
	var id := String(v.get("id", ""))
	var reglas: Dictionary = VOTO_IA.get(id, {})

	var a_favor := 0
	var total := 0
	for x: Club in asamblea:
		total += 1
		var p := PROB_NEUTRA
		if not reglas.is_empty():
			p = float(reglas["grande"]) if x.rep >= int(reglas["umbral"]) else float(reglas["chico"])
		## El presidente hace campaña por lo suyo.
		if agenda_empuja(id):
			p = minf(p + EMPUJE_PRESIDENTE, 0.95)
		if Azar.suerte(p):
			a_favor += 1
	if opcion == "a":
		a_favor += 1
	else:
		total += 1
	## OJO: división REAL, no entera. Con `total / 2` sobre enteros, una asamblea
	## de 17 clubes aprobaría con 8 votos de 17, porque 17/2 da 8 y basta con
	## empatarlo. En coma flotante hace falta la mitad de verdad.
	var pasa := float(a_favor) > float(total) / 2.0

	var efecto := _aplicar_mocion(id, pasa, opcion, mi)
	var ganaste := (opcion == "a") == pasa
	aliados = clampi(aliados + (1 if ganaste else -1), -10, 10)
	votos.push_front({"id": id, "t": String(v.get("t", "")), "pasa": pasa,
		"vote_a": opcion == "a"})

	noticia.emit("Asamblea de la liga: " + String(v.get("t", "")),
		"Resultado: %d votos a favor de %d. La moción %s. %s Tu posición %s" % [
			a_favor, total, "SE APRUEBA" if pasa else "se rechaza", efecto,
			"salió ganadora: sumas peso político en la asamblea."
				if ganaste else "quedó en minoría."])
	votacion_resuelta.emit(id, pasa, ganaste, efecto)
	voto_pendiente = {}
	return {"id": id, "pasa": pasa, "ganaste": ganaste, "efecto": efecto,
		"a_favor": a_favor, "total": total, "aliados": aliados}

# ============================================================================
# LAS PUERTAS POR LAS QUE EL REGLAMENTO ENTRA AL JUEGO
# ============================================================================

## Multiplicador de los derechos de televisión de TU club. Lo aplica quien los
## cobra; que se decida aquí y no en Finanzas es a propósito: el reparto es una
## regla de la liga, no una partida contable.
func factor_tv() -> float:
	return reparto_tv

## Cuánto se recortan las tarjetas de un árbitro tarjetero por haber VAR. El
## HTML lo llama `_fVAR` y vale 0,5: con vídeo se protesta menos y se inventan
## menos faltas.
func factor_tarjetas() -> float:
	return 0.5 if var_activo else 1.0

## Cupo juvenil: multa si sacas un once sin sub-21, bonificación por cada uno que
## juegue. Devuelve el dinero neto (negativo si te multaron) y mueve la caja.
##
## Se le pasa el once REAL que saltó al campo, no la plantilla: el cupo es de
## minutos jugados, no de fichas guardadas en un cajón.
func revisar_cupo_juvenil(mi: Club, once: Array) -> int:
	if not cupo_juvenil or mi == null:
		return 0
	var juveniles: Array = []
	for j: Jugador in once:
		if j != null and j.edad <= 21:
			juveniles.append(j)
	if juveniles.is_empty():
		var multa := Eco.escalar(MULTA_SIN_JUVENIL, float(mi.rep))
		mi.mover_saldo(-multa)
		movimiento.emit("Multa: sin sub-21 en el once", -multa)
		castigo_directiva.emit(-2, "incumplir el cupo juvenil")
		noticia.emit("Multa por incumplir el cupo juvenil",
			"Saliste sin ningún sub-21 en el once y la federación te sanciona. El reglamento que votó la asamblea obliga a alinear al menos uno.")
		return -multa
	var bono := Eco.escalar(BONO_JUVENIL, float(mi.rep)) * juveniles.size()
	mi.mover_saldo(bono)
	movimiento.emit("Bonificación por minutos juveniles (%d)" % juveniles.size(), bono)
	for j: Jugador in juveniles:
		j.cambiar_moral(2, "Federación y sanciones")
	return bono

## ¿Cabe este extranjero en el plantel? Devuelve "" si sí, o el motivo si no.
## Lo consulta el mercado ANTES de cerrar un fichaje: rechazarlo después sería
## fichar y descubrir en la pantalla siguiente que no puede jugar.
func puede_fichar_extranjero(mi: Club, j: Jugador) -> String:
	## Las reglas del país del club (7-10-2026) y, encima, el tope que haya
	## votado la asamblea si es más estricto. Si el club decidió incumplirlas,
	## puede fichar: lo paga en multas (`revisar_leyes_pais`).
	if mi != null and mi.ley_politica == "incumplir":
		return ""
	return LeyesPais.motivo_fichaje(mi, j, {}, tope_extranjeros)

func infracciones_de(anio: int) -> Dictionary:
	return infracciones_ley.get(str(anio), {"plantel": 0, "alin": 0})

## SI EL CLUB CUMPLE LA LEY, EL CUERPO TÉCNICO LA HACE CUMPLIR (13-10-2026). Con
## la regla de juveniles (Chile: un sub-21 en el once) y ningún chico sano en el
## plantel, el once no podía cumplirla nunca: multa y −3 puntos cada semana, la
## caja a −90 M en una temporada. Ahora se sube a uno: el mejor de la academia
## o, si no hay, uno del filial.
func _cubrir_juveniles(m: Mundo, mi: Club) -> void:
	for edad: int in LeyesPais.reglas(mi.pais).get("juveniles", []):
		var hay := false
		for j: Jugador in mi.disponibles():
			if j.edad <= edad and not j.es_portero():
				hay = true
				break
		if hay:
			continue
		var subido: Jugador = null
		if m.academia != null:
			var mejor: Dictionary = {}
			for ch: Dictionary in m.academia.chicos:
				if int(ch["edad"]) <= edad and int(ch["edad"]) >= Academia.EDAD_ENTREGA_ANTICIPADA and String(ch.get("pos", "")) != "POR" and (mejor.is_empty() or float(ch["nivel"]) > float(mejor["nivel"])):
					mejor = ch
			if not mejor.is_empty():
				subido = m.academia._entregar(mejor, true)
		if subido == null:
			var grupos := [["DEF", "DFC"], ["MED", "MC"], ["DEL", "DC"]]
			var g: Array = grupos[Azar.ent(0, 2)]
			subido = m.crear_jugador(mi, String(g[0]), String(g[1]), Azar.ent(18, edad), clampi(mi.rep - 12, 45, 70))
			if subido != null:
				subido.anios_contrato = 2
				if not mi.plantilla.has(subido):
					mi.plantilla.append(subido)
		if subido != null:
			noticia.emit("🌱 Sube un chico del filial",
				"Para cumplir la norma de juveniles (%s), el cuerpo técnico sube a %s (%d años, %s)." % [
					String(LeyesPais.reglas(mi.pais).get("norma", "la liga")), subido.nombre, subido.edad, subido.pos_e])

func revisar_leyes_pais(m: Mundo, mi: Club) -> void:
	if mi == null or m == null:
		return
	var k := str(m.anio)
	var inf: Dictionary = infracciones_de(m.anio).duplicate()
	var norma := String(LeyesPais.reglas(mi.pais).get("norma", "el reglamento de la liga"))
	var exceso := LeyesPais.exceso_plantel(mi, tope_extranjeros)
	if exceso > 0:
		inf["plantel"] = int(inf["plantel"]) + 1
		var veces := int(inf["plantel"])
		var multa := int(Eco.escalar(MULTA_PLANTEL_LEY, float(mi.rep)) * exceso * (1.0 + 0.25 * float(veces - 1)))
		mi.mover_saldo(-multa)
		movimiento.emit("Multa: plantel fuera de reglamento (%d de más)" % exceso, -multa)
		enojo_arbitral += 1
		if veces == 1 or veces % 4 == 0:
			noticia.emit("📜 Multa por plantel fuera de reglamento",
				"Tienes %d jugador(es) de más para el cupo de tu liga. Multa de %s, y crece cada semana que sigas así. %s" % [exceso, Cesiones.dinero(multa), norma])
	if mi.ley_politica != "incumplir":
		_cubrir_juveniles(m, mi)
	var faltas := LeyesPais.infracciones_once(mi, mi.once())
	if not faltas.is_empty():
		inf["alin"] = int(inf["alin"]) + 1
		var n := int(inf["alin"])
		var multa2 := int(Eco.escalar(MULTA_ALINEACION, float(mi.rep)) * float(n))
		mi.mover_saldo(-multa2)
		movimiento.emit("Multa: alineación indebida", -multa2)
		enojo_arbitral += 2
		castigo_directiva.emit(-1, "alineación indebida")
		var textos: Array = []
		for f: Dictionary in faltas:
			textos.append(String(f["texto"]))
		var cuerpo := "Alineaste %s (%dª vez esta temporada): multa de %s." % [", ".join(textos), n, Cesiones.dinero(multa2)]
		if n >= 3:
			for l: Liga in m.ligas:
				if l.clubes.has(mi) and l.tabla_puntos.has(mi.id):
					l.sancionar(mi.id, PUNTOS_ALINEACION)
			cuerpo += " Por reincidir, el tribunal te quita %d puntos." % PUNTOS_ALINEACION
		noticia.emit("📜 Alineación indebida", cuerpo + " " + norma)
	infracciones_ley[k] = inf

## Las reglas que están en vigor ahora mismo, en frases. Es lo que se enseña en
## la pantalla de Federación: un puñado de banderas booleanas no le dice nada a
## nadie.
func reglas_vigentes(pais: String = "") -> Array:
	var l: Array = LeyesPais.resumen(pais) if pais != "" else []
	if not is_equal_approx(reparto_tv, 1.0):
		l.append("Reparto de TV al %d%% de lo normal" % int(round(reparto_tv * 100.0)))
	if cupo_juvenil:
		l.append("Obligatorio un sub-21 en el once")
	if tope_extranjeros > 0:
		l.append("Máximo %d extranjeros por plantel" % tope_extranjeros)
	if playoffs:
		l.append("El campeón se decide por playoffs")
	if superliga:
		l.append("Tu club juega la superliga separatista")
	if var_activo:
		l.append("VAR en toda la categoría")
	if licencia != "vigente":
		l.append("Licencia %s" % licencia)
	if l.is_empty():
		l.append("Reglamento estándar: nada que la asamblea haya cambiado todavía")
	return l

## Acepta una fila de `Liga.tabla()` o un Club suelto.
func _club_de(fila: Variant) -> Club:
	if fila is Club:
		return fila as Club
	if fila is Dictionary and (fila as Dictionary).has("club"):
		return (fila as Dictionary)["club"] as Club
	return null

## Un cruce. La fuerza es la reputación más la ventaja de haber acabado arriba, y
## cada punto de diferencia vale 2,2 puntos porcentuales, con el resultado
## acotado entre el 15% y el 85%: ni el más grande tiene el título asegurado ni
## el cuarto va de paseo.
func _duelo(a: Club, b: Club, ventaja: float) -> Dictionary:
	var fa := float(a.rep) + ventaja
	var fb := float(b.rep)
	var pa := clampf(0.5 + (fa - fb) * 0.022, 0.15, 0.85)
	var gana := a if Azar.suerte(pa) else b
	var pierde := b if gana == a else a
	## El marcador se inventa DESPUÉS de saber quién gana, y por eso nunca puede
	## salir un empate: al ganador se le da al menos un gol más que al otro.
	var ga := Azar.ent(0, 3)
	var gb := Azar.ent(0, maxi(0, ga - 1))
	return {
		"gana": gana, "pierde": pierde,
		"marcador": "%s %d-%d %s" % [Nombres.visible(gana.nombre),
			maxi(ga, gb + 1), mini(ga, gb), Nombres.visible(pierde.nombre)],
	}

# ============================================================================
# PLAYOFFS POR EL TÍTULO
# ============================================================================
#
# POR QUÉ ESTO NO USA `Copa`, que ya hace eliminatorias con penales:
#
#  - `Copa.preparar()` BARAJA a los participantes. Aquí el cruce no se sortea:
#    es 1º-4º y 2º-3º, y esa es la mitad de la gracia del formato.
#  - No hay forma de decirle a `Copa` que el primero de la tabla arranca con
#    ventaja. Sin esa ventaja, treinta fechas no valdrían absolutamente nada.
#  - `Partido` tiene mucha más varianza que el duelo del HTML. Con él, el líder
#    perdería el título casi la mitad de las veces; con esta fórmula lo pierde
#    en torno a una de cada cuatro, que es lo que mide el banco de pruebas y lo
#    que hace que el formato sea injusto sin ser una lotería.
#
# El día que los playoffs se jueguen en directo (dirigiendo tú la semifinal),
# `Copa` es el sitio: entonces el partido lo simula `Partido` y esta fórmula se
# queda solo para los cruces que no juegas.

## Juega la eliminatoria si la asamblea la votó. Devuelve {} si no hay playoffs
## —o si no hay cuatro equipos—, y si los hay, el detalle guardable de lo que
## pasó: los dos marcadores de semifinales, el de la final y quién levantó la copa.
##
## `tabla` es la de `Liga.tabla()`: filas con la clave "club". También acepta un
## array de Clubes pelados, que es como resulta cómodo llamarla desde una prueba.
func jugar_playoffs(tabla: Array, anio: int, mi_id: String = "") -> Dictionary:
	_campeon_ref = null
	if not playoffs or tabla.size() < 4:
		return {}
	var cuatro: Array[Club] = []
	for i in 4:
		var c := _club_de(tabla[i])
		if c == null:
			return {}
		cuatro.append(c)

	var s1 := _duelo(cuatro[0], cuatro[3], VENTAJA_PRIMERO)
	var s2 := _duelo(cuatro[1], cuatro[2], VENTAJA_SEGUNDO)
	## A la final el líder llega con menos ventaja que a la semifinal: acabar
	## primero pesa, pero cada vez menos. Si no, los playoffs serían el mismo
	## campeón de siempre con dos partidos de trámite.
	var ventaja := VENTAJA_FINAL if s1["gana"] == cuatro[0] else 0.0
	var fin := _duelo(s1["gana"], s2["gana"], ventaja)
	var campeon: Club = fin["gana"]
	_campeon_ref = campeon

	playoffs_ultimo = {
		"anio": anio,
		"semis": [String(s1["marcador"]), String(s2["marcador"])],
		"final": String(fin["marcador"]),
		"campeon": campeon.id,
		"campeon_nombre": Nombres.visible(campeon.nombre),
		"lider": cuatro[0].id,
		"lider_nombre": Nombres.visible(cuatro[0].nombre),
	}

	var mio := false
	for c in cuatro:
		if c.id == mi_id:
			mio = true
	var cola := " Tu equipo no llegó a los cuatro primeros."
	if mio:
		cola = " Lo ganaste tú: el mejor de la tabla no siempre levanta la copa, y esta vez fuiste tú." \
			if campeon.id == mi_id else \
			" Entraste en los playoffs y te quedaste sin el título. Así es este formato."
	noticia.emit("PLAYOFFS POR EL TÍTULO %d" % anio,
		"La federación decidió que el campeón se juega. Semifinales: %s · %s. FINAL: %s. Campeón: %s.%s" % [
			s1["marcador"], s2["marcador"], fin["marcador"],
			Nombres.visible(campeon.nombre), cola])
	if cuatro[0].id != campeon.id:
		noticia.emit("El líder se quedó sin corona",
			"%s terminó primero en la tabla pero perdió los playoffs. Con este formato, treinta fechas no garantizan nada." % Nombres.visible(cuatro[0].nombre))
	playoffs_jugados.emit(playoffs_ultimo)
	return playoffs_ultimo

## El campeón de la temporada: el de los playoffs si los hay, y si no, el líder.
## Es el `jugarPlayoffs(t1) || t1[0]` del HTML, y es la única línea que hay que
## cambiar en el cierre de temporada para que la votación signifique algo.
func campeon_de_liga(tabla: Array, anio: int, mi_id: String = "") -> Club:
	if tabla.is_empty():
		return null
	jugar_playoffs(tabla, anio, mi_id)
	if _campeon_ref != null:
		return _campeon_ref
	return _club_de(tabla[0])

# ============================================================================
# LICENCIA DE CLUB
# ============================================================================

## Los seis requisitos de licencia, con su estado y el dato que lo justifica.
## La lista es la del HTML; dos de ellos apuntaban a sitios que en Godot todavía
## no existen y se han enganchado a lo más parecido que sí existe:
##  - "patrimonio neto positivo" miraba la contabilidad completa; aquí mira la
##    caja, que es el único patrimonio que el club tiene portado.
##  - "plan de seguridad" miraba la seguridad privada de la ciudad deportiva;
##    aquí mira la calidad del estadio, que es la obra que paga accesos y luces.
## Las dos son sustituciones conscientes, no despistes: cuando se porten esos
## sistemas se cambian estas dos líneas y nada más.
func requisitos_licencia(mi: Club, obras: Instalaciones) -> Array:
	var minimo := 12000 if mi.division == 1 else 5000
	return [
		{"k": "aforo", "t": "Aforo mínimo de la categoría",
			"ok": mi.estadio_aforo >= minimo,
			"det": "%d butacas" % mi.estadio_aforo},
		{"k": "med", "t": "Centro médico nivel 1 o superior",
			"ok": obras.nivel("med") >= 1, "det": "nivel %d" % obras.nivel("med")},
		{"k": "acad", "t": "Academia juvenil operativa",
			"ok": obras.nivel("acad") >= 1, "det": "nivel %d" % obras.nivel("acad")},
		{"k": "caja", "t": "Caja sin mora prolongada",
			"ok": semanas_en_rojo < 4, "det": "%d semanas en rojo" % semanas_en_rojo},
		{"k": "patrim", "t": "Patrimonio neto positivo",
			"ok": mi.saldo > 0, "det": "caja de %d" % mi.saldo},
		{"k": "seg", "t": "Plan de seguridad del estadio",
			"ok": obras.nivel("cal") >= 1, "det": "calidad de estadio nivel %d" % obras.nivel("cal")},
	]

func _en_lista(l: Array) -> String:
	var m: Array = []
	for t: String in l:
		m.append(t.to_lower())
	return ", ".join(m)

## La revisión anual. Uno o dos incumplimientos son un aviso con pérdida del cupo
## internacional; tres o más, multa y licencia denegada.
##
## Es lo que hace que construir no sea opcional: puedes ganar la liga con un
## plantel caro y una ciudad deportiva de cartón, pero no dos años seguidos.
func auditoria_anual(mi: Club, obras: Instalaciones, anio: int) -> Dictionary:
	if mi == null or obras == null:
		return {}
	## Se limpia primero: el veto internacional es de UNA temporada, y si no se
	## borrara al empezar la revisión, un club que arregló sus papeles seguiría
	## castigado para siempre.
	sin_cupo_internacional = false
	var fallos: Array = []
	for r: Dictionary in requisitos_licencia(mi, obras):
		if not bool(r["ok"]):
			fallos.append(String(r["t"]))
	auditoria = {"anio": anio, "fallos": fallos}
	avisos = fallos.duplicate()

	if fallos.is_empty():
		licencia = "vigente"
		avisos = []
		noticia.emit("Auditoría federativa superada",
			"El club cumple los seis requisitos de licencia. Sin observaciones: puedes competir e inscribir jugadores con normalidad.")
	elif fallos.size() <= 2:
		licencia = "condicional"
		sin_cupo_internacional = true
		noticia.emit("Licencia CONDICIONAL",
			"La federación detectó %d incumplimiento(s): %s. Tienes una temporada para corregirlo o pierdes el cupo internacional." % [
				fallos.size(), _en_lista(fallos)])
	else:
		licencia = "denegada"
		sin_cupo_internacional = true
		var multa := Eco.escalar(MULTA_LICENCIA, float(mi.rep))
		mi.mover_saldo(-multa)
		movimiento.emit("Multa federativa por licencia denegada", -multa)
		castigo_directiva.emit(-16, "licencia denegada")
		noticia.emit("LICENCIA DENEGADA",
			"La federación rechaza la licencia por %d incumplimientos: %s. Multa, sin cupo internacional y con el mercado bajo lupa. Arréglalo esta temporada." % [
				fallos.size(), _en_lista(fallos)])
	licencia_revisada.emit(licencia, fallos)
	return {"estado": licencia, "fallos": fallos, "anio": anio}

func _jugador_de(mi: Club, pid: String) -> Jugador:
	if mi == null or pid == "":
		return null
	for j: Jugador in mi.plantilla:
		if j.id == pid:
			return j
	return null
