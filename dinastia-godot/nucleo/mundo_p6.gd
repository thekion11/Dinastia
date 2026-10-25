extends "res://nucleo/mundo_p5.gd"
## [Capa 7/9 de `mundo.gd`] temporada_en_curso, jugar_temporada, _rodar_era, _segunda_de, jugar_promocion, _mover_de_liga … (+5)

func temporada_en_curso() -> bool:
	for l in ligas:
		if l.quedan_jornadas():
			return true
	return false

func jugar_temporada() -> void:
	while temporada_en_curso():
		avanzar_semana()
	var campeon: Club = null
	if not ligas.is_empty():
		var t := ligas[0].tabla()
		if not t.is_empty():
			## `Federacion.campeon_de_liga()`, no `t[0]["club"]` directo: el
			## propio docstring de `federacion.gd` describe este bug exacto del
			## HTML -"se votaban los playoffs... y en diciembre el campeón
			## seguía siendo el primero de la tabla"- como algo que "este
			## proyecto ya pagó", pero seguía sin arreglar AQUÍ. Cuando no se
			## votó playoffs, `campeon_de_liga()` devuelve exactamente
			## `t[0]["club"]`: mismo resultado, cero riesgo.
			campeon = federacion.campeon_de_liga(t, anio, mi_club_id)
	temporada_terminada.emit(anio, campeon)

## Cada temporada se mira si la moda cambia. Va al cierre del año, con el resto.
func _rodar_era() -> void:
	if era_hasta == 0:
		era_hasta = anio + Azar.ent(4, 7)
		return
	if anio < era_hasta:
		return
	era_tactica = (era_tactica + 1) % ERAS_TACTICAS.size()
	era_hasta = anio + Azar.ent(4, 7)
	var e := era_actual()
	if prensa != null:
		prensa.noticia.emit("Cambia la moda: %s" % String(e[1]),
			"%s Los que juegan con %s salen ganando; los de %s van a sufrir." % [
				String(e[4]), ", ".join(e[2]), ", ".join(e[3])])

func _segunda_de(pais: String) -> Liga:
	for l in ligas:
		if l.pais == pais and l.division() == 2:
			return l
	return null

## La promoción: dos partidos (ida en casa del de Ascenso, vuelta en la del de
## Primera). Gana el global; con empate, se queda el de Primera (la ventaja
## de categoría, como en muchos reglamentos). Devuelve {ganador, ida, vuelta}.
func jugar_promocion(de_primera: Club, de_ascenso: Club) -> Dictionary:
	var ida := Partido.new(de_ascenso, de_primera)
	ida.preparar()
	while not ida.terminado_ya:
		ida.simular_minuto()
	var vuelta := Partido.new(de_primera, de_ascenso)
	vuelta.preparar()
	while not vuelta.terminado_ya:
		vuelta.simular_minuto()
	var g_primera := ida.goles_visita + vuelta.goles_local
	var g_ascenso := ida.goles_local + vuelta.goles_visita
	var ganador: Club = de_ascenso if g_ascenso > g_primera else de_primera
	var txt := "%s %d-%d %s en el global (ida %d-%d, vuelta %d-%d)." % [de_primera.nombre, g_primera, g_ascenso, de_ascenso.nombre,
		ida.goles_local, ida.goles_visita, vuelta.goles_local, vuelta.goles_visita]
	if prensa != null:
		prensa.noticia.emit("⚔️ Promoción: %s" % ("¡%s sube!" % de_ascenso.nombre if ganador == de_ascenso else "%s se salva" % de_primera.nombre), txt)
	return {"ganador": ganador, "texto": txt}

## Cambia a un club de liga. Hay que mover TRES cosas a la vez: la lista de la
## liga que lo pierde, la de la que lo gana, y su propia división.
##
## La división no es una etiqueta: de ella dependen los derechos de televisión
## (300.000 en Primera contra 58.000 en Segunda) y el patrocinio. Moverlo de
## lista sin cambiarle la división dejaría a un club recién descendido cobrando
## como si siguiera arriba, que es justo el castigo que el descenso tiene que ser.
func _mover_de_liga(c: Club, desde: Liga, hasta: Liga) -> void:
	desde.clubes.erase(c)
	if not hasta.clubes.has(c):
		hasta.clubes.append(c)
	c.division = hasta.division()
	## Y la TABLA, que son cuatro cosas y no tres.
	##
	## `Liga.tabla()` recorre `clubes` y busca a cada uno en `tabla_puntos`. Moviendo
	## solo la lista, el recien llegado no tenia fila y la tabla reventaba con
	## "Invalid access to key 'cNN'". No saltaba casi nunca porque `nueva_temporada()`
	## llama despues a `preparar()`, que la reconstruye entera — pero cualquiera que
	## pidiera la tabla ENTRE el ascenso y esa llamada se la encontraba rota. Y eso
	## es justo lo que hace el veredicto de la directiva cuando TU club sube o baja.
	desde.tabla_puntos.erase(c.id)
	if not hasta.tabla_puntos.has(c.id):
		hasta.tabla_puntos[c.id] = {"pts": 0, "pj": 0, "gf": 0, "gc": 0, "g": 0, "e": 0, "p": 0}

## Reparte los premios de la liga y mueve a los clubes entre divisiones.
##
## Se le pasan las tablas ya calculadas en vez de volver a pedirlas: son la misma
## foto que ha usado el resto del cierre, y recalcularlas aquí podría dar otra si
## algo las hubiera tocado en medio. Es la nota que dejó el propio HTML.
## Es solo la mitad «de liga» del cierre: no avanza el año. La llama
## `nueva_temporada()`; desde fuera se usa `cerrar_temporada()` (mundo_p7).
func _cerrar_campeonato() -> Dictionary:
	var resumen := {"campeones": [], "suben": [], "bajan": [], "directiva": {}}
	## LAS RAMAS TERMINAN SU TEMPORADA (C12).
	if hinchada != null and mi_club() != null and prensa != null:
		for rr: Dictionary in hinchada.temporada_ramas(mi_club(), anio):
			var p := int(rr["puesto"])
			var txt := ("¡Campeón!" if p == 1 else ("%d.º: al podio." % p if p <= 3 else "%d.º puesto." % p))
			prensa.noticia.emit("🏅 %s" % String(rr["rama"]), "Temporada terminada: %s" % txt)
			if p == 1 and String(rr["clave"]) == "femenino":
				prensa.guardar_portada("¡EL FEMENINO, CAMPEÓN!", "La rama femenina del club gana la liga.", "bien",
					{"img": "escudo", "sub": "La rama femenina gana la liga y el club suma reputación y socios.", "nueva": true})
	var tablas := {}
	## El puesto de TU club, con la foto de antes de mover a nadie.
	var mi_puesto := 0
	for l in ligas:
		tablas[l] = l.tabla()
		var t: Array = tablas[l]
		if t.is_empty():
			continue
		## Playoffs solo si se votaron -y solo pesan sobre TU liga: la
		## asamblea que los vota es la de tu federación, las demás siguen
		## coronando al primero de la tabla, que es lo que ya hacían-.
		## `campeon_de_liga()` cae en `t[0]["club"]` sola cuando no se
		## votaron, así que esto no cambia nada salvo cuando de verdad toca.
		var es_mi_liga := mi_club() != null and l.pais == mi_club().pais and l.division() == 1
		var campeon: Club = federacion.campeon_de_liga(t, anio, mi_club_id) if es_mi_liga else t[0]["club"]
		campeon.mover_saldo(PREMIO_LIGA)
		## Ganar la liga sube la reputación del club, y la reputación es la que
		## mueve la caja, la taquilla y lo que puedes fichar el año siguiente.
		campeon.rep = clampi(campeon.rep + 1, 40, 96)
		resumen["campeones"].append({"liga": l, "club": campeon})
		## Se apunta el campeon de TU liga para la Supercopa del ano que viene: al
		## empezar la temporada nueva la tabla ya esta a cero y no habria a quien
		## preguntarle quien gano.
		if mi_club() != null and l.pais == mi_club().pais and l.division() == 1:
			_campeon_liga_pasado = campeon
		if campeon == mi_club() and logros != null:
			logros.celebrar_titulo(l.nombre)
		if mi_club() != null and l.clubes.has(mi_club()):
			var n := 1
			for fila: Dictionary in t:
				if fila["club"] == mi_club():
					break
				n += 1
			mi_puesto = n

	## La gala de fin de año: equipo ideal, mejor joven, mejor entrenador. Tiene
	## que ir AQUÍ, antes del bloque de ascensos/descensos de abajo: por dentro
	## vuelve a pedir `liga_de(mi_club()).tabla()`, y si ya se hubiera movido de
	## liga esa tabla sería la de la liga NUEVA, recién estrenada a cero puntos
	## -la misma trampa que ya pagó `mi_puesto` unas líneas más arriba.
	if logros != null:
		resumen["logros"] = logros.cerrar_temporada()
	## Las epocas doradas se sortean al cerrar el ano, antes de que la camada
	## siguiente nazca: si fuera despues, el pais estrenaria su epoca con una
	## generacion ya repartida y el bono llegaria un ano tarde.
	if eras != null:
		eras.cierre_de_temporada()
	## Y la moda tactica, que cambia cada cuatro a siete temporadas: sin esto, el
	## mejor dibujo del juego lo es para siempre y se elige una vez en diez años.
	_rodar_era()

	## LA MARCA DEL PECHO MIRA LA TABLA. La exigencia contractual se cobra aqui,
	## con `mi_puesto` ya calculado sobre la foto de ANTES de mover a nadie de
	## liga: si se leyera despues, un descendido tendria el puesto de su liga
	## nueva y la marca le daria las gracias por un top 1 que no existio.
	if auspicio != null:
		var cierre_ausp := auspicio.cierre(mi_puesto)
		if cierre_ausp != "":
			resumen["auspicio"] = cierre_ausp

	## Los dos últimos de Primera bajan y los dos primeros de Segunda suben, por
	## cada país que tenga las dos divisiones.
	for primera in ligas:
		if primera.division() != 1:
			continue
		var segunda := _segunda_de(primera.pais)
		if segunda == null:
			continue
		var t1: Array = tablas.get(primera, primera.tabla())
		var t2: Array = tablas.get(segunda, segunda.tabla())
		if t1.size() < 3 or t2.size() < 3:
			continue
		## Cuántos bajan y suben: lo que diga la Primera (editable, 2 por defecto).
		var n_cambio := clampi(primera.plazas_descenso, 1, mini(t1.size(), t2.size()) - 2)
		var bajan: Array[Club] = []
		var suben: Array[Club] = []
		for i_c in n_cambio:
			bajan.append(t1[t1.size() - 1 - i_c]["club"])
			suben.append(t2[i_c]["club"])
		## LA PROMOCIÓN (reglamento fino, si la asamblea la aprobó): el
		## antepenúltimo de Primera contra el tercero de Ascenso, ida y vuelta.
		if federacion != null and federacion.promocion and t1.size() >= n_cambio + 2 and t2.size() >= n_cambio + 2:
			var arriba: Club = t1[t1.size() - 1 - n_cambio]["club"]
			var abajo: Club = t2[n_cambio]["club"]
			var prom := jugar_promocion(arriba, abajo)
			resumen["promocion"] = prom
			if prom["ganador"] == abajo:
				bajan.append(arriba)
				suben.append(abajo)
		## M-219: el intervenido por deudas baja (o no sube) por despacho.
		if insolvencia != null:
			var castigo := insolvencia.descenso_administrativo(self, t1, t2, bajan, suben)
			if not castigo.is_empty():
				resumen["administrativo"] = (resumen.get("administrativo", []) as Array) + castigo
		for c in bajan:
			_mover_de_liga(c, primera, segunda)
		for c in suben:
			_mover_de_liga(c, segunda, primera)
		resumen["bajan"].append_array(bajan)
		resumen["suben"].append_array(suben)

	## Y la cuenta que de verdad importa: si cumpliste lo que te pidieron.
	##
	## OJO: el puesto se saca de `mi_puesto`, calculado ARRIBA con la foto de las
	## tablas de antes de mover a nadie. Mirarlo aqui seria mirar la liga NUEVA de
	## tu club si acabas de ascender o descender, donde todavia no has jugado nada
	## y por tanto eres primero por diferencia de goles cero. Al que acaba de bajar
	## le saldria que cumplio.
	## Los puntos de habilidad de la temporada, antes del veredicto: si te echan,
	## al menos tu plantel se queda con lo que ganó jugando.
	if entrenamiento != null and mi_club() != null:
		entrenamiento.repartir_puntos(mi_club())
	if copa != null and copa.campeon == mi_club() and logros != null:
		logros.celebrar_titulo(copa.nombre)
	if directiva != null and not directiva.despedido_ya and mi_puesto > 0:
		resumen["directiva"] = directiva.tras_temporada(mi_puesto, mi_puesto == 1,
			copa != null and copa.campeon == mi_club())
		## Las primas por objetivos del reglamento interno: se pagan al cumplir,
		## no antes. Es lo que las hace una apuesta y no un gasto fijo.
		if bool(normas.get("primas", false)) and bool(resumen["directiva"].get("cumplido", false)):
			var mio_p := mi_club()
			var prima_total := Eco.escalar(800000, mio_p.rep)
			mio_p.mover_saldo(-prima_total)
			_anotar_movimiento("Primas por objetivos al plantel", -prima_total)
			for j in mio_p.plantilla:
				j.cambiar_moral(6, "Normas y cuerpo técnico del club")
			resumen["primas_pagadas"] = prima_total
	## El pulso de la carrera: prestigio, ascensos, y si el interino no se
	## resolvió por fechas (interinato de menos de cinco semanas jugadas al
	## cerrar la temporada), por temporada terminada.
	if roles != null:
		resumen["roles"] = roles.tras_temporada(resumen.get("directiva", {}))
	## EL RETO (26-9-2026): se juzga al cerrar su temporada.
	if not reto.is_empty() and mi_club() != null:
		var yo := mi_club()
		var subio := false
		var bajo := false
		for x: Variant in resumen["suben"]:
			if (x is Club and x == yo) or (x is Dictionary and (x as Dictionary).get("club") == yo):
				subio = true
		for x2: Variant in resumen["bajan"]:
			if (x2 is Club and x2 == yo) or (x2 is Dictionary and (x2 as Dictionary).get("club") == yo):
				bajo = true
		var rr := Retos.juzgar(self, mi_puesto, bajo, subio)
		if not rr.is_empty():
			resumen["reto"] = rr
			if prensa != null:
				prensa.noticia.emit(String(rr["titulo"]), String(rr["texto"]))
	return resumen

## Cierra la temporada: cumpleanos, retiros y un campeonato nuevo.
## LOS CONTRATOS VENCEN (28-9-2026, informe externo: "sin validación de fin
## de contrato"). `anios_contrato` no bajaba nunca: el aviso "sin renovar, se
## van gratis" no se cumplía y nadie quedaba libre. Ahora cada temporada le
## resta un año; al llegar a cero:
##   - en un club de la máquina, casi siempre renueva (los veteranos menos);
##   - en TU club, si no lo renovaste, se va a la bolsa de libres y es noticia.
## La decisión sale de un hash (jugador + año), no de `Azar`: así no cambia
## ninguna otra tirada de la simulación. Devuelve true si el jugador se va.
func _vence_contrato(j: Jugador, c: Club) -> bool:
	j.anios_contrato -= 1
	if j.anios_contrato > 0:
		return false
	var h := absi(hash("%s|%d" % [j.id, anio]))
	if c.id != mi_club_id:
		var sigue := 0.5 if j.edad >= 33 else 0.88
		if float(h % 1000) / 1000.0 < sigue:
			j.anios_contrato = Contratos.ajustar_anios(j, 1 + (h / 1000) % 3)
			return false
	j.club_id = ""
	j.motivo_libre = "Terminó su contrato con %s" % c.nombre
	libres.append(j)
	if libres.size() > 80:
		libres.pop_front()
	if c.id == mi_club_id and prensa != null:
		prensa.noticia.emit("Se va libre: %s" % j.nombre,
			"Se le acabó el contrato y no se renovó. Deja %s sin que el club cobre nada." % c.nombre)
	return true

## Sube canteranos hasta completar la plantilla, y los sube EN EL PUESTO QUE
## FALTA, comparando con el plan de plantilla. Rellenando al azar, en diez
## temporadas un club acababa con seis porteros y sin lateral izquierdo, porque
## los retiros no se reparten por igual entre las demarcaciones.
##
## Ojo con el orden: la edad y la media se le pasan a `crear_jugador`, no se le
## ponen despues. Poniendolas despues el jugador ya venia tasado con otra edad y
## el valor salia mal; el fallo no se ve hasta que alguien mira una ficha.
func _subir_de_cantera(c: Club) -> void:
	var plan: Array = Datos.tabla("PLAN_PLANTEL")
	var faltan: Array[String] = []
	for entrada: Array in plan:
		var demarcacion := String(entrada[0])
		var tiene := 0
		for j in c.plantilla:
			if j.pos_e == demarcacion:
				tiene += 1
		for k in maxi(0, int(entrada[1]) - tiene):
			faltan.append(demarcacion)
	## Una línea VACÍA se repone aunque el plantel esté lleno (la prueba larga
	## encontró un club sin delanteros con 25 fichas); el resto, hasta 24.
	var lineas := {}
	for j0 in c.plantilla:
		lineas[j0.pos] = true
	for demarcacion in faltan:
		var vacia := not lineas.has(Datos.grupo(demarcacion))
		if c.plantilla.size() >= 24 and not vacia:
			continue
		lineas[Datos.grupo(demarcacion)] = true
		var edad := Azar.ent(17, 20)
		## El canterano entra flojo y con techo: media baja, potencial alto. Es
		## lo que hace que la cantera sea una apuesta y no una fuente de cracks.
		var ovr := c.rep - 20 + Azar.ent(0, 8)
		## Pero no todo hueco se tapa con un juvenil (25-10, paquete cant): con
		## solo chicos de 17-20 el mundo bajaba de 26,9 a 25,6 años de media en
		## cinco temporadas. Dos de cada cinco son un repuesto hecho, de 22-30.
		if Azar.suerte(0.4):
			edad = Azar.ent(22, 30)
			ovr = c.rep - 12 + Azar.ent(-5, 3)
		var nuevo := crear_jugador(c, Datos.grupo(demarcacion), demarcacion, edad, ovr)
		## EL CLUB QUE VIVE DE SU CANTERA (C3) la cuida más: sus chicos
		## suben con más techo. Sin `Azar` extra: es un ajuste fijo.
		if not Regiones.filosofia(c).is_empty():
			nuevo.ovr = mini(nuevo.ovr + 4, 90)
			nuevo.pot = clampi(nuevo.pot + 6, nuevo.ovr, 97)
			nuevo.tasar()
		c.plantilla.append(nuevo)

func _nombre_pais_de(pais: String) -> String:
	var t: Dictionary = Datos.tabla("PAIS_SELECCION")
	return String(t.get(pais, pais)) if t != null else pais

func jugar_supercopa() -> Dictionary:
	if _campeon_liga_pasado == null or _campeon_copa_pasado == null:
		return {}
	if _campeon_liga_pasado == _campeon_copa_pasado:
		## El mismo club ganó las dos: no hay Supercopa que jugar, y el doblete
		## ya se celebró en su momento.
		return {}
	var a := _campeon_liga_pasado
	var b := _campeon_copa_pasado
	var p := Partido.new(a, b)
	var r := p.simular()
	var gl: int = r["local"]
	var gv: int = r["visita"]
	## Partido único: si acaba en empate, decide la reputación —no hay prórroga
	## que simular y un título no puede quedar sin dueño.
	var gana: Club = a if gl > gv else (b if gv > gl else (a if a.rep >= b.rep else b))
	gana.mover_saldo(PREMIO_SUPERCOPA)
	var nombre := "Supercopa de %s" % _nombre_pais_de(gana.pais)
	if gana == mi_club():
		if logros != null:
			logros.celebrar_titulo(nombre)
		if roles != null:
			roles.sumar_trofeo(nombre)
	if prensa != null:
		prensa.noticia.emit(nombre,
			"%s %d-%d %s. %s levanta el primer título del año." % [a.nombre, gl, gv, b.nombre, gana.nombre])
	return {"nombre": nombre, "campeon": gana, "local": a, "visita": b, "gl": gl, "gv": gv}
