extends "res://nucleo/carrera_jugador_p1.gd"
## [Capa 2/3 de `carrera_jugador.gd`] _eventos_posibles y sus auxiliares (20-11, orden 63: partido en funciones por grupos).
## Va entre `carrera_jugador_p1.gd` y `carrera_jugador.gd`: la capa de arriba llama a `super` y llega aquí.

func _eventos_posibles(m: Mundo, j: Jugador) -> Array:
	var c := club(m)
	var nombre_club := c.nombre if c != null else "el club"
	var p: Array = []
	_eventos_de_inicio(p, j, nombre_club)
	_eventos_de_fama(p, j, m)
	_eventos_de_la_fase3(p, j, c)
	_eventos_de_cesion_y_nota(p, j, m)
	_eventos_de_capitania_y_lesion(p, j, m)
	_eventos_de_rival_y_extranjero(p, m, c)
	_eventos_de_vida(p, j, m)
	return p

## Eventos de inicio: el capitán, los penales, las faltas, la fiesta y el micrófono.
func _eventos_de_inicio(p: Array, j: Jugador, nombre_club: String) -> void:
	if not hitos.has("capitan_consejo"):
		p.append(_ev("capitan_consejo", "El capitán te llama aparte",
			"«Chico, aquí nadie te regala nada. Llega el primero, vete el último.» ¿Qué le contestas?",
			[_op("«Lo haré, capitán.» (relación con el vestuario)", {"relacion": 4, "fama": 0}),
			_op("«Yo ya sé lo que tengo que hacer.»", {"relacion": -5, "fama": 2})], true))
	if not hitos.has("penales") and j.atributos.get("tir", 0) >= 62:
		p.append(_ev("penales", "¿Quién tira los penales?",
			"El DT pregunta en el vestuario quién quiere hacerse cargo de los penales.",
			[_op("Levantas la mano.", {"lanzador_penales": true, "fama": 3, "relacion": 1}),
			_op("Mejor que los tire el veterano.", {"relacion": 3})], true))
	if not hitos.has("faltas") and j.atributos.get("tir", 0) >= 60 and j.atributos.get("pas", 0) >= 60:
		p.append(_ev("faltas", "Las faltas directas",
			"Después del entrenamiento te quedas pateando tiros libres. El DT te ve.",
			[_op("Le pides lanzarlas en el próximo partido.", {"lanzador_faltas": true, "relacion": 1}),
			_op("Sigues practicando sin decir nada.", {"attr_tir": 1})], true))
	p.append(_ev("fiesta", "Una fiesta antes del partido",
		"Tus amigos te invitan a una fiesta el viernes. El sábado juegas.",
		[_op("Vas, pero vuelves temprano.", {"energia": -10, "seguidores": 60}),
		_op("Te quedas hasta tarde.", {"energia": -35, "relacion": -6, "seguidores": 200, "fama": 1}),
		_op("No vas: descanso.", {"energia": 10, "relacion": 1})]))
	p.append(_ev("prensa", "Micrófono en la zona mixta",
		"Un periodista te pregunta si te ves de titular en %s.",
		[_op("«Trabajo para ganarme el puesto.»", {"relacion": 2, "fama": 1}),
		_op("«Si no juego, me buscaré otro club.»", {"relacion": -8, "fama": 5, "seguidores": 250}),
		_op("«Aquí manda el míster.»", {"relacion": 3})], false, {"texto_datos": [nombre_club]}))

## Provocaciones, el agente, las botas y la renovación.
func _eventos_de_fama(p: Array, j: Jugador, m: Mundo) -> void:
	p.append(_ev("provocacion", "Te provocan en Tribuna",
		"Un defensa del próximo rival publica: «Ese pibe no pasa de mí».",
		[_op("Le respondes con un emoji de reloj.", {"fama": 3, "seguidores": 300, "relacion": -1}),
		_op("No contestas: respondes en la cancha.", {"relacion": 2, "moral": 5})]))
	if fama >= 15 and agente == "":
		p.append(_ev("agente", "Un representante quiere llevarte",
			"Un agente con buena cartera te ofrece llevar tu carrera a cambio del 10 %.",
			[_op("Firmas con él.", {"agente": "sí", "fama": 2}),
			_op("Sigues sin agente.", {})]))
	if not hitos.has("botas") and seguidores >= 1500:
		p.append(_ev("botas", "Una marca de botas te llama",
			"Quieren que seas su cara joven. Pagan bien, pero hay sesiones de fotos.",
			[_op("Aceptas.", {"seguidores": 800, "fama": 4, "energia": -8}),
			_op("Ahora no, primero el fútbol.", {"relacion": 2})], true))
	if j.anios_contrato <= 1 and not hitos.has("renovacion_%d" % m.anio):
		p.append(_ev("renovacion_%d" % m.anio, "La renovación",
			"El club te ofrece renovar tres años con una subida de sueldo.",
			[_op("Firmas.", {"contrato": 3, "relacion": 4}),
			_op("Pides más dinero.", {"contrato": 3, "sueldo": 1.3, "relacion": -4}),
			_op("Esperas ofertas.", {"fama": 1})], true))

## Eventos de la fase 3: el debut, el primer gol, el mentor.
func _eventos_de_la_fase3(p: Array, j: Jugador, c: Club) -> void:
	## --- LOS EVENTOS DE LA FASE 3: cada uno sale de algo que te pasó de verdad.
	if not hitos.has("debut") and pj_carrera >= 1:
		p.append(_ev("debut", "Tu debut profesional",
			"Ya jugaste tu primer partido oficial. En el vestuario te hacen el pasillo y el utilero te guarda la camiseta.",
			[_op("La enmarcas para tu familia.", {"moral": 6, "seguidores": 120}),
			_op("Se la regalas al chico de la cantera que te alcanzaba los balones.", {"relacion": 3, "fama": 2, "seguidores": 200})], true))
	if not hitos.has("primer_gol") and goles_carrera >= 1:
		p.append(_ev("primer_gol", "¡Tu primer gol!",
			"La televisión repite tu gol una y otra vez. Te preguntan a quién se lo dedicas.",
			[_op("A tu familia, que te llevaba a entrenar.", {"moral": 8, "seguidores": 300}),
			_op("A la grada, que te apoyó desde el primer día.", {"fama": 4, "seguidores": 500}),
			_op("Le haces el gesto de silencio a la grada rival.", {"fama": 7, "seguidores": 900, "relacion": -4})], true))
	var veterano := _veterano(c, j)
	if not hitos.has("mentor") and j.edad <= 20 and veterano != null:
		p.append(_ev("mentor", "%s se ofrece a enseñarte",
			"El veterano del vestuario (%d años) te propone quedaros una hora más cada día después del entrenamiento.",
			[_op("Aceptas: aprender de él es oro.", {"attr_%s" % String(CarreraPortero.focos_para(j).get(foco, ["", "pos" if j.es_portero() else "tir"])[1]): 2, "energia": -10, "relacion": 3}),
			_op("Le das las gracias, pero prefieres descansar.", {"energia": 8})], true, {"titulo_datos": [veterano.nombre], "texto_datos": [veterano.edad]}))

## La cesión y el jugador del mes.
func _eventos_de_cesion_y_nota(p: Array, j: Jugador, m: Mundo) -> void:
	var pj_t := int(stats_temp["pj"])
	if not hitos.has("cesion_%d" % m.anio) and j.edad <= 21 and pj_t >= 6 and float(stats_temp["titular"]) / float(pj_t) < 0.3 and not CarreraTraspasos.destinos_cesion(self, m).is_empty():   ## (R-06) sin destino, no se ofrece
		p.append(_ev("cesion_%d" % m.anio, "El club te propone una cesión",
			"Casi no juegas de titular. Un club más modesto te quiere a préstamo hasta final de temporada para darte minutos.",
			[_op("Aceptas: necesitas jugar.", {"cesion": true}),
			_op("Te quedas a pelear el puesto.", {"relacion": -2, "moral": -3})], true))
	if not hitos.has("jugador_mes_%d" % m.anio) and (stats_temp["notas"] as Array).size() >= 4 and nota_media() >= 7.6:
		p.append(_ev("jugador_mes_%d" % m.anio, "Jugador del mes",
			"La liga te elige mejor jugador del mes con una media de %.1f. Te entregan el trofeo antes del partido.",
			[_op("Lo levantas ante tu grada.", {"fama": 6, "seguidores": 600, "moral": 6}),
			_op("Lo dedicas a tus compañeros.", {"fama": 4, "relacion": 4, "moral": 4})], true, {"texto_datos": [nota_media()]}))

## El brazalete, la lesión larga y la polémica.
func _eventos_de_capitania_y_lesion(p: Array, j: Jugador, m: Mundo) -> void:
	if not capitan and fama >= 45 and relacion_dt >= 65 and CarreraPremios.apto_capitan(self, m):   ## (13-11) tres años en el club y de los tres mejores
		p.append(_ev("brazalete", "El brazalete de capitán",
			"Se retira el capitán y el DT quiere que el brazalete sea tuyo.",
			[_op("Lo aceptas con orgullo.", {"capitan": true, "relacion": 5, "fama": 5}),
			_op("Pides que lo lleve alguien con más años en el club.", {"relacion": 3})], true))
	if j.lesion >= 4 and not hitos.has("lesion_larga_%d" % m.anio):
		p.append(_ev("lesion_larga_%d" % m.anio, "Una lesión larga",
			"El médico te da %d semanas de baja. Te propone dos caminos para la recuperación.",
			[_op("Recuperación prudente, sin prisas.", {"energia": 30, "moral": -4}),
			_op("Plan acelerado para volver antes.", {"lesion_menos": 2, "lesion_riesgo": true, "relacion": 2})], true, {"texto_datos": [j.lesion]}))
	if not hitos.has("polemica") and seguidores >= 5000:
		p.append(_ev("polemica", "Una polémica en las redes",
			"Alguien desentierra un mensaje tuyo de cuando tenías 15 años. Arde Tribuna.",
			[_op("Pides perdón en un vídeo sincero.", {"seguidores": -300, "relacion": 2, "fama": 1}),
			_op("No dices nada y esperas a que pase.", {"seguidores": -800, "fama": -2}),
			_op("Contestas con ironía.", {"seguidores": 1200, "fama": 3, "relacion": -5})], true))

## El ex del rival y la oferta del extranjero.
func _eventos_de_rival_y_extranjero(p: Array, m: Mundo, c: Club) -> void:
	var rival_ex := _rival_ex_club(m, c)
	if rival_ex != "" and not hitos.has("ex_%s_%d" % [rival_ex, m.anio]):
		p.append(_ev("ex_%s_%d" % [rival_ex, m.anio], "Vuelves a %s",
			"Esta semana te toca contra tu antiguo club. La prensa te pregunta cómo vas a celebrar si marcas.",
			[_op("«No celebraré: les tengo respeto.»", {"fama": 2, "seguidores": 250, "moral": 3}),
			_op("«Si marco, lo celebraré como siempre.»", {"fama": 4, "seguidores": 600, "moral": 5})], true, {"titulo_datos": [rival_ex]}))
	if not hitos.has("oferta_extranjero") and fama >= 55 and c != null:
		p.append(_ev("oferta_extranjero", "Te llaman del extranjero",
			"Un club grande de otra liga pregunta por ti. Tu agente dice que es ahora o nunca.",
			[_op("Le dices que escuche la oferta.", {"oferta_fuera": true, "fama": 2}),
			_op("Quieres triunfar primero aquí.", {"relacion": 4, "moral": 3})], true))

## La vida fuera del campo: licencia, retiro, el niño y la sobrecarga.
func _eventos_de_vida(p: Array, j: Jugador, m: Mundo) -> void:
	if not licencia and not hitos.has("licencia") and j.edad >= 30:
		p.append(_ev("licencia", "El curso de entrenador",
			"La federación abre el curso de la licencia C para futbolistas en activo. Son clases los lunes.",
			[_op("Te inscribes: algún día dirigirás.", {"licencia": true, "energia": -8}),
			_op("Ahora no: solo piensas en jugar.", {})], true))
	if not retiro_anunciado and j.edad >= 33 and not hitos.has("retiro_%d" % m.anio):
		p.append(_ev("retiro_%d" % m.anio, "¿Cuánto te queda?",
			"Tienes %d años. En el vestuario ya te llaman «el viejo». Tu familia te pregunta si este será el último año.",
			[_op("Anuncias que te retiras a final de temporada.", {"retiro": true, "fama": 4, "seguidores": 800}),
			_op("Sigues mientras el cuerpo aguante.", {"moral": 2})], true, {"texto_datos": [j.edad]}))
	if _rng.randf() < 0.3:
		p.append(_ev("nino_camiseta", "Un niño te espera a la salida",
			"Un chico de unos ocho años lleva una cartulina con tu nombre y te pide la camiseta.",
			[_op("Se la das y te sacas una foto con él.", {"moral": 4, "seguidores": 150, "fama": 1}),
			_op("Le firmas la cartulina: vas con prisa.", {"seguidores": 20})]))
	if energia < 30:
		p.append(_ev("sobrecarga", "Molestias en el isquio",
			"Llevas semanas sin parar. El médico te recomienda frenar.",
			[_op("Paras una semana.", {"energia": 40, "relacion": -1}),
			_op("Juegas infiltrado.", {"energia": -5, "lesion_riesgo": true})]))
