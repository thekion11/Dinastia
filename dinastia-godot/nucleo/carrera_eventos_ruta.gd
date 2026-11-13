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
			c._op("Le respondes en tus redes.", {"seguidores": 600, "fama": 1, "relacion": -2})], true))
	if c.energia < 25:
		p.append(c._ev("ruta_fundido", "El preparador físico te para",
			"Te ve llegar arrastrando las piernas y te lleva aparte: así no puedes seguir.",
			[c._op("Aceptas dos días libres.", {"energia": 20}),
			c._op("Insistes en entrenar con el grupo.", {"relacion": 1, "lesion_riesgo": true})]))
	if not c.hitos.has("ruta_nino") and c.fama >= 25:
		p.append(c._ev("ruta_nino", "Un niño con tu camiseta",
			"A la salida del entreno te espera un niño con tu nombre a la espalda. Lleva una hora ahí.",
			[c._op("Le regalas tus botas.", {"seguidores": 500, "fama": 1, "moral": 3}),
			c._op("Le firmas la camiseta y te vas.", {"moral": 1})], true))
	if not c.hitos.has("ruta_veterano") and CarreraRuta.nivel(c) >= 4:
		p.append(c._ev("ruta_veterano", "El veterano te propone quedarte",
			"El más viejo del vestuario te ofrece una hora extra de trabajo tras el entreno, los dos solos.",
			[c._op("Te quedas con él.", {"ruta_xp": 60, "energia": -8, "relacion": 1}),
			c._op("Hoy no: estás cansado.", {"energia": 6})], true))
	var j := c.jugador(m)
	if not c.hitos.has("ruta_primo") and j != null and CarreraVida.ahorros(c) >= j.sueldo * 20:
		p.append(c._ev("ruta_primo", "Tu primo tiene un negocio",
			"Ha visto que te va bien y te pide un préstamo para abrir un bar con tu nombre en el cartel.",
			[c._op("Le prestas el dinero (ocho semanas de sueldo).", {"ruta_ahorros_semanas": -8, "moral": 3, "seguidores": 200}),
			c._op("Le dices que no mezclas familia y dinero.", {"moral": -2})], true))
	return p

## Los efectos propios de estos eventos (`CarreraJugador.resolver` hace el resto).
static func aplicar(c: CarreraJugador, m: Mundo, ef: Dictionary) -> void:
	if int(ef.get("ruta_xp", 0)) > 0:
		CarreraRuta.sumar_xp(c, int(ef["ruta_xp"]))
	var semanas := int(ef.get("ruta_ahorros_semanas", 0))
	var j := c.jugador(m)
	if semanas != 0 and j != null:
		CarreraRuta.asegurar(c)["ahorros"] = maxi(0, CarreraVida.ahorros(c) + semanas * j.sueldo)
