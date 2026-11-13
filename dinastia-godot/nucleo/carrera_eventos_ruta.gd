class_name CarreraEventosRuta
extends RefCounted
## LOS EVENTOS QUE NACEN DE «LA RUTA» (13-11-2026): decisiones que salen de lo
## nuevo del modo (la racha, tu rival, la energía, la fama, tu nivel y tus
## ahorros). Mismo formato que los demás eventos de la carrera.

static func eventos(c: CarreraJugador, m: Mundo) -> Array:
	var p: Array = []
	var r := CarreraRuta.asegurar(c)
	if int(r["racha"]) >= 3:
		p.append(c._ev("ruta_racha", "La prensa te pone por las nubes",
			"Tres partidos seguidos a gran nivel y ya te comparan con los grandes. El DT lee los titulares con el ceño fruncido.",
			[c._op("Pides calma: «Solo llevo tres partidos».", {"relacion": 2, "moral": 1}),
			c._op("Disfrutas el momento y concedes entrevistas.", {"fama": 2, "seguidores": 400, "relacion": -1})]))
	if not c.hitos.has("ruta_rival") and not (r["rival"] as Dictionary).is_empty() and int(c.stats_temp["pj"]) >= 4:
		p.append(c._ev("ruta_rival", "Tu rival habla de ti",
			"En una entrevista, tu rival suelta que este año el duelo es suyo y que tú aún estás verde.",
			[c._op("Contestas en el campo.", {"moral": 4, "relacion": 1}),
			c._op("Le respondes en tus redes.", {"seguidores": 600, "fama": 1, "relacion": -2, "ruta_marca": "pique"})], true))
	## EN CADENA: si le contestaste en redes, el duelo se calienta unas semanas después.
	if not c.hitos.has("ruta_pique") and semanas_desde(c, m, "pique") >= 4:
		p.append(c._ev("ruta_pique", "El duelo se calienta",
			"Tu respuesta en redes corrió como la pólvora. Media liga está pendiente de vuestro duelo.",
			[c._op("Lo usas de gasolina: este año el duelo vale doble.", {"moral": 3, "ruta_marca": "duelo_doble"}),
			c._op("Bajas el tono con un mensaje de respeto.", {"relacion": 2, "seguidores": 150})], true))
	if c.energia < 25:
		p.append(c._ev("ruta_fundido", "El preparador físico te para",
			"Te ve llegar arrastrando las piernas y te lleva aparte: así no puedes seguir.",
			[c._op("Aceptas dos días libres.", {"energia": 20}),
			c._op("Insistes en entrenar con el grupo.", {"relacion": 1, "lesion_riesgo": true})]))
	if not c.hitos.has("ruta_nino") and c.fama >= 25:
		p.append(c._ev("ruta_nino", "Un niño con tu camiseta",
			"A la salida del entreno te espera un niño con tu nombre a la espalda. Lleva una hora ahí.",
			[c._op("Le regalas tus botas.", {"seguidores": 500, "fama": 1, "moral": 3, "ruta_marca": "botas"}),
			c._op("Le firmas la camiseta y te vas.", {"moral": 1})], true))
	if not c.hitos.has("ruta_veterano") and CarreraRuta.nivel(c) >= 4:
		p.append(c._ev("ruta_veterano", "El veterano te propone quedarte",
			"El más viejo del vestuario te ofrece una hora extra de trabajo tras el entreno, los dos solos.",
			[c._op("Te quedas con él.", {"ruta_xp": 60, "energia": -8, "relacion": 1, "ruta_marca": "veterano"}),
			c._op("Hoy no: estás cansado.", {"energia": 6})], true))
	## EN CADENA: el niño de las botas vuelve doce semanas después, con su equipo entero.
	if not c.hitos.has("ruta_escuela") and semanas_desde(c, m, "botas") >= 12:
		p.append(c._ev("ruta_escuela", "El niño de las botas vuelve",
			"Juega con tus botas en el equipo de su barrio y ha traído a todos sus compañeros. Su entrenador te pide que les dirijas un entreno.",
			[c._op("Les das la tarde entera.", {"seguidores": 800, "fama": 2, "moral": 4, "energia": -6}),
			c._op("Les firmas un balón y les deseas suerte.", {"seguidores": 150, "moral": 1})], true))
	## EN CADENA: diez semanas de horas extra con el veterano y te deja su último consejo.
	if not c.hitos.has("ruta_legado") and semanas_desde(c, m, "veterano") >= 10:
		p.append(c._ev("ruta_legado", "El consejo del veterano",
			"Tras semanas quedándoos los dos solos, el veterano te dice que ya no tiene nada que enseñarte, salvo una cosa: elegir.",
			[c._op("«Enséñame a leer el juego.»", {"ruta_xp": 120, "relacion": 1}),
			c._op("«Enséñame a mandar en el vestuario.»", {"relacion": 4, "moral": 3})], true))
	## (13-11 noche) Los que nacen de los logros, del corte del duelo y de los puntos sin gastar.
	if not c.hitos.has("ruta_docu") and CarreraLogros.ganados(c).size() >= 5:
		p.append(c._ev("ruta_docu", "Un documental sobre ti",
			"Una productora quiere grabar tu día a día: llevas cinco logros y tu historia vende.",
			[c._op("Les abres la puerta de tu casa.", {"seguidores": 1200, "fama": 2, "energia": -6, "ruta_marca": "docu"}),
			c._op("Dices que tu historia aún no ha empezado.", {"relacion": 2, "moral": 2})], true))
	## EN CADENA: catorce semanas después se estrena.
	if not c.hitos.has("ruta_estreno") and semanas_desde(c, m, "docu") >= 14:
		p.append(c._ev("ruta_estreno", "El estreno del documental",
			"Se estrena esta semana y el club te deja ir a la gala, que cae la víspera del partido.",
			[c._op("Vas a la gala.", {"fama": 3, "seguidores": 2000, "energia": -10, "relacion": -2}),
			c._op("Lo ves en casa y descansas.", {"energia": 8, "moral": 2})], true))
	if not c.hitos.has("ruta_burla") and CarreraDuelo.por_remontar(c):
		p.append(c._ev("ruta_burla", "Tu rival se ríe en la tele",
			"Va por delante en vuestro duelo y lo dice en directo: «Este año ni se acerca».",
			[c._op("Recortas el vídeo y lo pegas en tu taquilla.", {"moral": 5, "energia": -4}),
			c._op("Apagas la tele: a lo tuyo.", {"relacion": 1, "energia": 4})], true))
	if not c.hitos.has("ruta_estancado") and int(r["puntos"]) >= 3:
		p.append(c._ev("ruta_estancado", "El preparador te ve estancado",
			"Tienes puntos de talento sin usar y te lo dice claro: lo que no se trabaja, se pierde.",
			[c._op("Te quedas a trabajar esta semana.", {"ruta_xp": 40, "energia": -5}),
			c._op("Prefieres guardarlos para más adelante.", {"moral": 1})], true))
	var j := c.jugador(m)
	if not c.hitos.has("ruta_primo") and j != null and CarreraVida.ahorros(c) >= j.sueldo * 20:
		p.append(c._ev("ruta_primo", "Tu primo tiene un negocio",
			"Ha visto que te va bien y te pide un préstamo para abrir un bar con tu nombre en el cartel.",
			[c._op("Le prestas el dinero (ocho semanas de sueldo).", {"ruta_ahorros_semanas": -8, "moral": 3, "seguidores": 200, "ruta_marca": "bar"}),
			c._op("Le dices que no mezclas familia y dinero.", {"moral": -2})], true))
	## EN CADENA: si le prestaste, quince semanas después el bar da noticias.
	if not c.hitos.has("ruta_bar") and semanas_desde(c, m, "bar") >= 15:
		p.append(c._ev("ruta_bar", "El bar de tu primo",
			"El bar con tu nombre se llena cada día de partido. Tu primo quiere saber qué haces con tu parte.",
			[c._op("Recuperas lo prestado, con un extra (doce semanas de sueldo).", {"ruta_ahorros_semanas": 12}),
			c._op("Lo dejas dentro: que el bar lleve tu cara.", {"seguidores": 900, "fama": 2, "moral": 2})], true))
	return p

## Semanas desde que una decisión dejó la marca `cual` (-1 si no la hay).
static func semanas_desde(c: CarreraJugador, m: Mundo, cual: String) -> int:
	var marcas: Variant = CarreraRuta.asegurar(c).get("marcas")
	if not marcas is Dictionary or not (marcas as Dictionary).has(cual):
		return -1
	return (m.anio * 60 + m.semana) - int((marcas as Dictionary)[cual])

static func tiene_marca(c: CarreraJugador, cual: String) -> bool:
	var marcas: Variant = CarreraRuta.asegurar(c).get("marcas")
	return marcas is Dictionary and (marcas as Dictionary).has(cual)

static func quitar_marca(c: CarreraJugador, cual: String) -> void:
	var marcas: Variant = CarreraRuta.asegurar(c).get("marcas")
	if marcas is Dictionary:
		(marcas as Dictionary).erase(cual)

## Los efectos propios de estos eventos (`CarreraJugador.resolver` hace el resto).
static func aplicar(c: CarreraJugador, m: Mundo, ef: Dictionary) -> void:
	if int(ef.get("ruta_xp", 0)) > 0:
		CarreraRuta.sumar_xp(c, int(ef["ruta_xp"]))
	if String(ef.get("ruta_marca", "")) != "":
		var r := CarreraRuta.asegurar(c)
		if not r.get("marcas") is Dictionary:
			r["marcas"] = {}
		(r["marcas"] as Dictionary)[String(ef["ruta_marca"])] = m.anio * 60 + m.semana
	var semanas := int(ef.get("ruta_ahorros_semanas", 0))
	var j := c.jugador(m)
	if semanas != 0 and j != null:
		CarreraRuta.asegurar(c)["ahorros"] = maxi(0, CarreraVida.ahorros(c) + semanas * j.sueldo)
