extends "res://nucleo/selecciones_p1.gd"
## [Capa 2/3 de `selecciones.gd`] _prenomina, _resolver, convocados, prenominados, caps_de, racha_de … (+16)

## Los 30 preseleccionados: los mejores elegibles sanos del mundo entero.
func _prenomina() -> void:
	var m := _mundo()
	var lista := _elegibles_sanos(m)
	lista.sort_custom(_mejor_media)
	if lista.size() > TOPE_PRENOMINA:
		lista.resize(TOPE_PRENOMINA)
	prenomina_ids.clear()
	var mios: Array[String] = []
	for j in lista:
		prenomina_ids.append(j.id)
		if j.club_id == m.mi_club_id:
			mios.append(j.nombre)
	var sel := nombre_seleccion()
	noticia.emit("Prenómina de " + sel,
		"La selección de %s publica una lista preliminar de %d jugadores rumbo a la próxima fecha internacional." % [sel, lista.size()]
		+ (" De tu club: %s." % ", ".join(mios) if not mios.is_empty() else " Sin jugadores de tu club en el corte inicial."))
	prenomina_publicada.emit(lista)

## Ids a jugadores en UNA pasada por el mundo. Buscar cada id por separado sería
## recorrer los miles de jugadores dieciocho veces: es exactamente el error que
## le costó al HTML el 93% de su tiempo de ejecución con `plantelDe()`.
func _resolver(ids: Array[String]) -> Array[Jugador]:
	var salida: Array[Jugador] = []
	var m := _mundo()
	if m == null or ids.is_empty():
		return salida
	var quiero := {}
	for id in ids:
		quiero[id] = null
	for c: Club in m.clubes.values():
		for j in c.plantilla:
			if quiero.has(j.id):
				quiero[j.id] = j
	for id in ids:
		var j: Jugador = quiero[id]
		if j != null:
			salida.append(j)
	return salida

# ---------------------------------------------------------------------------
#  LISTAS PARA LA PANTALLA
# ---------------------------------------------------------------------------

func convocados() -> Array[Jugador]:
	return _resolver(nomina_ids)

func prenominados() -> Array[Jugador]:
	return _resolver(prenomina_ids)

# ---------------------------------------------------------------------------
#  LO QUE PUEDE HACER EL ENTRENADOR
# ---------------------------------------------------------------------------

func caps_de(j: Jugador) -> int:
	return int(_caps.get(j.id, 0)) if j != null else 0

func racha_de(j: Jugador) -> int:
	return int(_racha.get(j.id, 0)) if j != null else 0

## Lo que le cuesta a TU club la gira. Solo a los tuyos: el físico de los
## jugadores de la IA no lo recupera nadie (`Entrenamiento` solo procesa tu
## plantel), así que restárselo sería una sangría permanente que no se ve en
## ninguna pantalla. En el HTML pasa lo mismo y por el mismo motivo.
func _desgastar(j: Jugador, mio: Club, anio: int, semana_n: int) -> void:
	var racha := racha_de(j) + 1
	_racha[j.id] = racha
	var sobreuso := racha >= FECHAS_PARA_SOBREUSO
	j.fisico = clampi(j.fisico - DESGASTE_FIFA - (DESGASTE_SOBREUSO if sobreuso else 0), 10, 100)
	if not Azar.suerte(RIESGO_GIRA + (RIESGO_EXTRA_SOBREUSO if sobreuso else 0.0)):
		return

	var m := _mundo()
	var sev := Medico.MEDIA if Azar.suerte(PROB_LESION_MEDIA) else Medico.LEVE
	var sem := 0
	var tipo := "molestia"
	if m.medico != null:
		sem = m.medico.lesionar(j, sev, "jugando con su selección", anio, semana_n)
		tipo = m.medico.diagnostico(j)
	else:
		## Sin parte médico (todavía no has tomado un club) no hay diagnóstico,
		## pero la baja existe igual: el jugador vuelve roto de la gira.
		sem = Azar.ent(1, 3)
		j.lesionar(sem)
	if sem <= 0:
		return

	## El programa de protección de clubes de la FIFA: te paga el sueldo del
	## lesionado. Se escala al tamaño de tu club como cualquier ingreso
	## operativo, que es lo que hace `esc$` en el HTML.
	var compensacion := Eco.escalar(float(j.sueldo) * float(COMPENSACION_BASE + sem), float(mio.rep))
	if compensacion > 0:
		mio.mover_saldo(compensacion)
		movimiento.emit("Compensación de la federación internacional por lesión en gira: " + j.nombre, compensacion)
	noticia.emit(
		("⚠️ Sobrecarga en la selección: " if sobreuso else "Lesionado en la selección: ") + j.nombre,
		"%s vuelve tocado de la gira: %s (%d sem)." % [j.nombre, tipo.to_lower(), sem]
		+ (" Es su %dª convocatoria seguida sin descanso: la selección lo exprime y el club paga las consecuencias." % racha if sobreuso else "")
		+ (" El club recibe la ayuda del programa de protección de clubes de la federación internacional." if compensacion > 0 else ""))
	vuelve_tocado.emit(j, sem, sobreuso)

func _anotar_resultado(linea: String) -> void:
	resultados.push_front(linea)
	while resultados.size() > MAX_RESULTADOS:
		resultados.remove_at(resultados.size() - 1)

## El partido de la fecha FIFA. El rival sale del escalafón mundial evitando que
## te enfrentes a ti mismo, y el marcador es un sorteo puro: la selección no
## tiene plantilla que simular, y fingir un partido de verdad con jugadores que
## no están en ningún club sería inventar un motor entero para una línea de texto.
func _jugar_amistoso(sel: String) -> void:
	var rivales: Array = []
	for n: String in _tabla_selecciones():
		if _txt(n) != sel:
			rivales.append(_txt(n))
	if rivales.is_empty():
		return
	var rival := String(Azar.uno(rivales))
	var g1 := Azar.ent(0, 3)
	var g2 := Azar.ent(0, 3)
	var linea := "%s %d - %d %s" % [sel, g1, g2, rival]
	_anotar_resultado(linea)
	noticia.emit("Fecha internacional: " + linea,
		"Cierra la ventana internacional. Los que fueron vuelven con %s." % ("el ánimo arriba" if g1 >= g2 else "la mochila pesada"))

## La nómina de 18 y el partido. Aquí es donde la selección se lleva a los tuyos.
func _fecha_fifa(anio: int, semana_n: int) -> void:
	var m := _mundo()
	var mio := m.mi_club()
	var sel := nombre_seleccion()

	var candidatos := _candidatos_fifa(m, mio, sel)
	var convocados := _convocar(candidatos)
	nomina_ids.clear()
	for j in convocados:
		nomina_ids.append(j.id)
	_avisar_cortados(mio, convocados)
	_cortar_racha(mio, candidatos, convocados)
	var mios := _convocados_de_club(mio, convocados, anio, semana_n)
	_jugar_amistoso(sel)
	_avisar_convocados(sel, mios, convocados)

## Los candidatos de la fecha: el filtro de descanso y la lista ordenada por media.
func _candidatos_fifa(m: Mundo, mio: Club, sel: String) -> Array[Jugador]:
	## Primero el filtro, con el pedido de descanso resuelto dentro: la
	## federación decide una sola vez por jugador y por fecha, gane o pierda.
	var candidatos: Array[Jugador] = []
	for j in _elegibles_sanos(m):
		if mio != null and j.club_id == mio.id and _descanso.has(j.id):
			_descanso.erase(j.id)
			var figura := j.ovr >= mio.rep + MARGEN_FIGURA
			if Azar.suerte(RESPETA_A_LA_FIGURA if figura else RESPETA_AL_SUPLENTE):
				_racha[j.id] = 0
				noticia.emit("La federación respeta el pedido",
					"El cuerpo técnico de %s decide no citar a %s esta fecha internacional, atendiendo el pedido de descanso del club." % [sel, j.nombre])
				continue
			noticia.emit("La federación ignora el pedido",
				"Pediste que %s descansara y la federación lo citó igual. Vuelve el lunes, y verás cómo." % j.nombre)
		candidatos.append(j)
	candidatos.sort_custom(_mejor_media)
	return candidatos

## Los 18 por líneas: cada línea se queda con sus mejores.
func _convocar(candidatos: Array[Jugador]) -> Array[Jugador]:
	var cupos := CUPOS.duplicate()
	var convocados: Array[Jugador] = []
	for j in candidatos:
		if int(cupos.get(j.pos, 0)) > 0:
			convocados.append(j)
			cupos[j.pos] = int(cupos[j.pos]) - 1
		if convocados.size() >= TOPE_NOMINA:
			break
	return convocados

## Los que estaban en la prenómina y no llegaron.
func _avisar_cortados(mio: Club, convocados: Array[Jugador]) -> void:
	var cortados: Array[String] = []
	for j in prenominados():
		if mio != null and j.club_id == mio.id and not convocados.has(j):
			cortados.append(j.nombre)
	if not cortados.is_empty():
		noticia.emit("Quedaron fuera de la nómina final",
			"Estaban en la prenómina pero no llegaron a la lista definitiva: %s. El cuerpo técnico prefirió otras variantes." % ", ".join(cortados))

## Al que no va se le corta la racha: el sobreuso castiga fechas seguidas.
func _cortar_racha(mio: Club, candidatos: Array[Jugador], convocados: Array[Jugador]) -> void:
	for j in candidatos:
		if mio != null and j.club_id == mio.id and not convocados.has(j):
			_racha[j.id] = 0

## Los convocados del club: caps, moral y desgaste.
func _convocados_de_club(mio: Club, convocados: Array[Jugador], anio: int, semana_n: int) -> Array[Jugador]:
	var mios: Array[Jugador] = []
	for j in convocados:
		_caps[j.id] = caps_de(j) + 1
		j.cambiar_moral(MORAL_CONVOCADO, "Selección nacional")
		if mio == null or j.club_id != mio.id:
			continue
		mios.append(j)
		_desgastar(j, mio, anio, semana_n)
	return mios

## Avisos de los convocados de tu club y la convocatoria.
func _avisar_convocados(sel: String, mios: Array[Jugador], convocados: Array[Jugador]) -> void:
	if not mios.is_empty():
		var nombres: Array[String] = []
		for j in mios:
			nombres.append(j.nombre)
		noticia.emit("Convocados de tu club",
			"Se van con %s: %s. Vuelven con la moral arriba y con el depósito vacío." % [sel, ", ".join(nombres)])
	convocatoria.emit(convocados, mios)


## El pulso semanal de la selección. Se llama siempre; decide ella si toca algo.
func semana(anio: int, semana_n: int) -> void:
	if _mundo() == null:
		return
	if hay_prenomina(semana_n):
		_prenomina()
	if hay_fecha_fifa(semana_n):
		_fecha_fifa(anio, semana_n)
	FechaSeleccion.semana(_mundo(), self, cargo, hay_fecha_fifa(semana_n))   ## (10-11) el partido de la selección que diriges
