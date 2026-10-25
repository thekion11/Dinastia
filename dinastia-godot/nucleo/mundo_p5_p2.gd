extends "res://nucleo/mundo_p5_p1.gd"
## [Capa 5/9 de `mundo.gd`, tramo b] La semana, fases 5-13: memoria del partido, mercado,
## lesiones insólitas, obras, ojeo, prensa, vestuario y marca, carrera del DT y el club por dentro.
## El guion que las llama en orden está en `mundo_p5.gd` (`avanzar_semana`).

## FASE 5 · LA MEMORIA DEL PARTIDO DIRIGIDO y el contador del interinato.
func _semana_memoria_del_partido(ya_jugado: Partido) -> void:
	## La memoria del club: cara a cara, rachas y récords. Solo el partido que
	## dirigiste en directo trae el `Partido` completo con el once y los
	## goleadores -`Liga.jugar_jornada()` descarta esos datos para los que solo
	## se simulan por dentro, así que semanas sin dirigir no alimentan la
	## memoria. Es una limitación conocida, no un olvido.
	if ya_jugado != null and logros != null and mi_club() != null \
			and (ya_jugado.local == mi_club() or ya_jugado.visita == mi_club()):
		## Antes solo distinguía Copa/Liga: un continental dirigido en vivo
		## quedaba anotado como "Liga" en la memoria del club, mentira chica
		## pero mentira -ahora que `_dirigir()` sí puede llevarte a uno-.
		var competicion := "Liga"
		if _copa_es_de(ya_jugado):
			competicion = "Copa"
		elif _continental_es_de(mi_continental(), ya_jugado):
			competicion = "Continental"
		logros.tras_partido(ya_jugado, competicion, int(obras.ultima_asistencia))
	## El interinato se cuenta en fechas, no en semanas: `fechas_interinato_
	## restantes()` las saca del propio calendario de la liga, así que llamar de
	## más no adelanta ni atrasa nada -solo hay que no dejar de llamarla.
	if roles != null and mi_club() != null:
		roles.tras_jornada()

## FASE 6 · EL MERCADO de la IA, los libres y las normas del vestuario.
func _semana_mercado() -> void:
	mercado.mover()
	mercado.buscar_oferta_por_mi_jugador()
	if libres.is_empty():
		generar_libres()
	_procesar_libres()
	## El toque de queda: disciplina a cambio de humor. Cada seis semanas.
	if bool(normas.get("queda", false)) and semana % 6 == 0:
		var mio_normas := mi_club()
		if mio_normas != null:
			for j in mio_normas.plantilla:
				j.cambiar_moral(-1, "Normas y cuerpo técnico del club")

## FASE 7 · LESIONES ABSURDAS FUERA DE LA CANCHA (C8): raras, cortas y noticia. El
## toque de queda evita las de noche. Sin `Azar`.
func _semana_lesion_insolita() -> void:
	var absurda := LesionesAbsurdas.sortear(mi_club(), anio, semana, bool(normas.get("queda", false)))
	if absurda.is_empty():
		return
	var ja: Jugador = absurda["jugador"]
	ja.lesionar(int(absurda["semanas"]))
	if prensa != null:
		var txt := "%s. Estará %d semana%s de baja." % [String(absurda["texto"]), int(absurda["semanas"]),
			"" if int(absurda["semanas"]) == 1 else "s"]
		prensa.noticia.emit("🤕 Lesión insólita", txt)
		prensa.guardar_portada("¡INSÓLITO! " + String(absurda["texto"]).to_upper(), txt, "mal",
			{"img": "pid:" + ja.id, "sub": txt, "medio": "Canal Deportes", "nueva": true})
		if bool(absurda["noche"]):
			prensa.mentor_dice.emit("Lo de %s" % ja.nombre,
				"Esto pasó de noche. Un toque de queda en las normas del vestuario habría evitado el disgusto.")

## FASE 8 · LAS OBRAS avanzan una semana. Se hace antes de la prensa para que la
## noticia de "obra terminada" salga la misma semana en que termina.
func _semana_obras() -> void:
	var mio_obras := mi_club()
	if mio_obras == null:
		return
	for k in obras.avanzar_semana(mio_obras):
		obra_lista.emit(k)
	if prensa != null:
		for txt: String in obras.ultimos_imprevistos:
			prensa.noticia.emit("🚧 Imprevisto en la obra", txt)
	## La reforma del diseñador del estadio también es obra.
	if estadio != null and estadio.avanzar_semana():
		obra_lista.emit("reforma_estadio")

## FASE 9 · EL OJEO. El ojeador trae informes: descubre el techo real de un chico
## de otro club. Es lo unico que hace que fichar a ciegas y fichar informado se
## distingan.
func _semana_ojeo() -> void:
	_informes_de_ojeo()
	## El humor de la red de ojeadores por nombre -si nunca les haces caso,
	## renuncian y se pierde la cobertura de su país-.
	if ojeadores == null:
		return
	ojeadores.procesar_semana()
	## EL MODELO DE DATOS busca por su cuenta, y a partir del nivel dos se pelea
	## con el ojeo de siempre. El nivel del jefe de ojeadores decide si hay
	## guerra: sin vieja escuela en casa no hay con quien discutir.
	ojeadores.semana_analitica(staff.nivel("ojo") if staff != null else 0)
	## Y las sedes internacionales cuestan todas las semanas, se use o no la
	## joya que traen en pretemporada.
	if mi_club() != null:
		var mant := ojeadores.mantencion_academias(mi_club())
		if mant > 0:
			mi_club().mover_saldo(-mant)
			_anotar_movimiento("Academias internacionales", -mant)

## FASE 10 · EL PULSO DE LA SEMANA FUERA DEL CAMPO: prensa, redes, eventos, la
## presión del fondo y la hinchada.
func _semana_prensa_e_hinchada() -> void:
	if prensa == null:
		return
	prensa.semana()
	prensa.semana_redes()
	prensa.sortear_evento()
	## El vocero se va con el jugador: si lo vendes, el club se queda mudo.
	prensa.revisar_vocero(mi_club())
	## LA PRESION DEL FONDO. Si vendiste un porcentaje de un canterano, el que
	## lo compro quiere cobrar, y aparece a pedir que lo vendas. Decir que no
	## cuesta moral del chico: su entorno le come la cabeza.
	if cesiones != null and prensa.pendiente.is_empty():
		var pf := cesiones.presion_de_fondo()
		if not pf.is_empty():
			var jf: Jugador = pf["jugador"]
			prensa.pendiente = {
				"id": "fondo_presiona", "pid": jf.id,
				"txt": "💸 %s" % String(pf["texto"]),
				"opcion_a": "Ponerlo en el mercado", "opcion_b": "No se vende",
			}
			prensa.evento_creado.emit(prensa.pendiente)
	## La hinchada se mueve DESPUÉS de la prensa, que es quien acaba de
	## actualizar el ánimo: al revés reaccionaría al ánimo de la semana
	## pasada y los segmentos irían siempre un paso por detrás.
	if hinchada != null:
		hinchada.semana(prensa.animo)

## FASE 11 · EL UTILERO, LOS DÍAS SEÑALADOS, LA MARCA DE LAS FIGURAS y la gente.
func _semana_vestuario_y_marca() -> void:
	## EL UTILERO. Un punto de moral a todo el plantel cuando llega a nivel 3.
	## Es lo mas pequeño que hace un puesto del cuerpo tecnico, y es a proposito:
	## es el que se contrata cuando ya esta todo lo demas.
	if staff != null and mi_club() != null:
		var util := staff.bono_utilero()
		if util > 0:
			for j in mi_club().plantilla:
				j.cambiar_moral(util, "Normas y cuerpo técnico del club")
	## LOS DIAS SEÑALADOS y lo que dejan las figuras por su marca personal. Los
	## dos son del HTML y no estaban portados: la temporada eran cuarenta y dos
	## semanas iguales, y tener una estrella no daba un peso de mas.
	_procesar_fiesta()
	if mi_club() != null:
		var marca := ingreso_marca()
		if marca > 0:
			mi_club().mover_saldo(marca)
			_anotar_movimiento("Marca personal de tus figuras", marca)
	if gente != null:
		gente.semana()
	## EL DESCUENTO DEL CONTABLE en la nomina del cuerpo tecnico. Se refresca
	## cada semana porque el arbol puede crecer entre una y otra.
	if staff != null and entrenamiento != null:
		staff.factor_sueldos = entrenamiento.factor_sueldo_staff()

## FASE 12 · LA CARRERA DEL ENTRENADOR. El sueldo del entrenador va a SU
## bolsillo, no a la caja del club: son dos dineros distintos y esa separación
## es lo que hace que exista una carrera personal por encima de la gestión.
func _semana_carrera_del_dt() -> void:
	if roles == null:
		return
	roles.semana_patrimonio()
	## EL DESGASTE. Una semana en el cargo cansa; ganar descansa y la funa
	## quema. No te echa nunca: te deja trabajando peor, que es distinto.
	roles.semana_desgaste(_gano_la_ultima, prensa.funa if prensa != null else 0)
	## LA CARRERA POR DENTRO: el rival personal aparece solo cuando hay con
	## quien picarse, la leyenda viva visita cada seis semanas y los clubes
	## filiales reparten dividendos cada tres meses.
	roles.buscar_rival_dt()
	## QUE TE QUIERA OTRO CLUB. Lo unico del juego que te ofrece IRTE: sin
	## esto, la unica forma de cambiar de banquillo es que te echen.
	var of := roles.sortear_oferta_de_club()
	if not of.is_empty() and prensa != null:
		prensa.noticia.emit("Te quiere %s" % String(of["nombre"]),
			"Han llamado desde %s: te ofrecen su banquillo. Puedes contestar en Club › Legado." % String(of["nombre"]))
	roles.semana_leyenda_viva()
	roles.semana_filiales()

## FASE 13 · EL CLUB POR DENTRO: lo digital, la junta, las charlas y los trabajadores.
func _semana_club_por_dentro() -> void:
	if club_dentro != null and mi_club() != null:
		club_dentro.semana(mi_club(), prensa)
		## La app y la web CRECEN cada semana -"procesoClubIn()" del HTML corre
		## en el mismo proceso semanal que la prensa o la cantera, no en el
		## cierre de mes-, y crecen más rápido si vienes ganando en liga.
		for mov: Dictionary in club_dentro.crecer_digital(mi_club(), prensa):
			_anotar_movimiento(String(mov["concepto"]), int(mov["monto"]))
	if junta != null and mi_club() != null:
		junta.semana(mi_club(), anio, semana)
	if charlas != null and mi_club() != null:
		charlas.semana(mi_club(), anio, semana)
	if trabajadores != null and mi_club() != null:
		trabajadores.semana(mi_club(), obras, anio, semana, prensa)
