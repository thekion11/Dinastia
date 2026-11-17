class_name EscaparateNoticia
extends RefCounted
## LA NOTICIA DEL ESCAPARATE (17-11-2026): lo último que llegó a la bandeja o, si no hay nada, una noticia GENERADA con datos del juego (el rival que viene, el
## estadio, la jornada, la estrella) para que la tarjeta NUNCA salga vacía («Sin noticias por ahora» está prohibido). Devuelve {titulo, cita, autor (Jugador o null)}.
## Los textos pasan por `Idiomas.t`; elige entre unas pocas redacciones según el club y la semana, para que no sea siempre la misma.

static func estrella_y_capitan(c: Club) -> Array:
	var orden := c.plantilla.duplicate()
	orden.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	return orden.slice(0, 2)

static func _rival_proximo(p: Principal) -> Dictionary:
	for e: Dictionary in EventosFecha.proximos(p.mundo, p._dia_semana, 8):
		if EventosFecha.es_partido(e) and e.get("rival") is Club:
			return e
	return {}

static func de(p: Principal, c: Club, liga: Liga) -> Dictionary:
	var estrellas := estrella_y_capitan(c)
	var bandeja: Array = p.get("_bandeja") if p.get("_bandeja") != null else []
	if not bandeja.is_empty():
		var n: Dictionary = bandeja[0]
		return {"titulo": String(n.get("titulo", "")), "cita": String(n.get("cuerpo", "")).strip_edges(), "autor": null, "jugadores": estrellas}
	var astro: Jugador = estrellas[0] if not estrellas.is_empty() else null
	var nombre := Nombres.visible(astro.nombre) if astro != null else c.nombre
	var variante := absi(hash("%s|%d" % [c.id, p.mundo.semana])) % 2
	var jornada := liga.jornada_actual if liga != null else 0
	var e := _rival_proximo(p)
	if jornada <= 0 or e.is_empty():
		var estadio := c.estadio_nombre if c.estadio_nombre != "" else Idiomas.t("Estadio de %s") % c.nombre
		if variante == 0:
			return {"titulo": Idiomas.t("Pretemporada: %s ya prepara la jornada 1") % c.nombre,
				"cita": Idiomas.t("Llegamos con hambre: cada entrenamiento en %s cuenta.") % estadio, "autor": astro, "jugadores": estrellas, "nombre": nombre}
		return {"titulo": Idiomas.t("%s entrena a tope antes del debut") % c.nombre,
			"cita": Idiomas.t("El plantel tiene ganas de que empiece la liga."), "autor": astro, "jugadores": estrellas, "nombre": nombre}
	var rival: Club = e["rival"]
	var en_casa := bool(e.get("local", true))
	var titulo := Idiomas.t("La previa: %s recibe a %s") % [c.nombre, rival.nombre] if en_casa else Idiomas.t("La previa: %s visita a %s") % [c.nombre, rival.nombre]
	var cita := Idiomas.t("No hay rival fácil en esta liga: vamos partido a partido.") if variante == 0 else Idiomas.t("Nos preparamos a fondo para %s.") % rival.nombre
	return {"titulo": titulo, "cita": cita, "autor": astro, "jugadores": estrellas, "nombre": nombre}
