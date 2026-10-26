extends "res://nucleo/prensa_p4_p1.gd"
## [Capa 5/8 de `prensa.gd`] los eventos del despacho, segunda tanda (vestuario, árbitros y cantera),
## la tabla de despacho y `resolver`

## Juegos mentales en el túnel: provocar al DT enciende al equipo y a veces se filtra; dejarle un recado
## al árbitro suma enojo en el tribunal y a veces acaba en el acta.
func _ev_tunel(d: Decision) -> Dictionary:
	if d.si:
		for x: Jugador in d.mio.plantilla:
			x.cambiar_moral(3, "Prensa y declaraciones")
		if Azar.suerte(0.3):
			_mover_funa(6)
			return {"titulo": "La provocación se filtra",
				"cuerpo": "Tu frase en el túnel la captó un micrófono de ambiente. El equipo salió encendido, pero la prensa ya tiene titular."}
		return {"titulo": "Guerra psicológica",
			"cuerpo": "El DT rival se quedó blanco. Tus jugadores lo vieron y salieron a la cancha dos metros más arriba."}
	if d.m.federacion != null:
		d.m.federacion.enojo_arbitral += 1
	if Azar.suerte(0.35):
		_pagar(d.mio, -Eco.escalar(40000.0, d.rep), "Multa por presionar al árbitro")
		return {"titulo": "El árbitro lo pone en el acta",
			"cuerpo": "Tu comentario terminó en el informe arbitral. Multa, y el tribunal ya te mira con lupa."}
	return {"titulo": "Recado entregado",
		"cuerpo": "El árbitro no dijo nada, pero lo escuchó. El tribunal, si se entera, no lo va a olvidar."}

func _ev_viral(d: Decision) -> Dictionary:
	if d.si:
		if d.j != null:
			d.j.cambiar_moral(-6, "Prensa y declaraciones")
			d.j.suspension = maxi(d.j.suspension, 1)
		_mover_funa(-5)
		if d.m.directiva != null:
			d.m.directiva.mover_confianza(2, "la sanción ejemplar")
		return {"titulo": "Sanción ejemplar",
			"cuerpo": "Un partido fuera y multa interna. La directiva aplaude; el jugador, no."}
	if d.j != null:
		d.j.cambiar_moral(4, "Prensa y declaraciones")
	_mover_funa(10)
	_efecto("eco_viral", 2)
	return {"titulo": "Lo defiendes",
		"cuerpo": "\"Tiene derecho a una vida\". El vestuario lo agradece; las redes llevan dos semanas con el video."}

func _ev_capitan(d: Decision) -> Dictionary:
	if d.si:
		for x: Jugador in d.mio.plantilla:
			x.cambiar_moral(3, "Prensa y declaraciones")
		rep_entrenador = clampi(rep_entrenador - 2, 0, 100)
		return {"titulo": "Carga más liviana",
			"cuerpo": "Aflojas los entrenamientos una semana. El grupo sonríe; algún periodista dice que el capitán manda más que tú."}
	if d.j != null:
		d.j.cambiar_moral(-8, "Prensa y declaraciones")
	rep_entrenador = clampi(rep_entrenador + 3, 0, 100)
	_efecto("vestuario_tenso", 3)
	return {"titulo": "\"Aquí mando yo\"",
		"cuerpo": "Dejas claro quién decide. Autoridad ganada, pero el vestuario va a estar tenso unas semanas."}

func _ev_silencio(d: Decision) -> Dictionary:
	if d.si:
		_pagar(d.mio, -Eco.escalar(50000.0, d.rep), "Homenaje y camiseta conmemorativa")
		mover_animo(6)
		d.mio.socios += 200
		return {"titulo": "Un homenaje a la altura",
			"cuerpo": "Minuto de silencio, su nombre en la camiseta y la barra cantando su canción. Nadie en el estadio lo va a olvidar."}
	mover_animo(2)
	return {"titulo": "Minuto de silencio",
		"cuerpo": "Respeto total en el estadio. Sencillo y digno."}

func _ev_cambio_posicion(d: Decision) -> Dictionary:
	var nueva := String(d.e.get("dato", "MC"))
	if d.si and d.j != null:
		if not d.j.pos_sec.has(nueva):
			d.j.pos_sec.append(nueva)
		d.j.cambiar_moral(6, "Prensa y declaraciones")
		_efecto("posicion_nueva", 3, d.j.id)
		return {"titulo": "%s, de %s" % [d.j.nombre, nueva],
			"cuerpo": "Ya figura como %s en su ficha. Unas semanas de adaptación y veremos si tenía razón." % nueva}
	if d.j != null:
		d.j.cambiar_moral(-6, "Prensa y declaraciones")
	return {"titulo": "Cada uno en su sitio",
		"cuerpo": "Le dices que no. Lo entiende, pero se le nota en la cara."}

func _ev_sponsor_rueda(d: Decision) -> Dictionary:
	if d.si:
		_pagar(d.mio, Eco.escalar(120000.0, d.rep), "Mención del patrocinador")
		rep_entrenador = clampi(rep_entrenador - 3, 0, 100)
		_mover_funa(3)
		return {"titulo": "La frase más cara",
			"cuerpo": "Nombraste la bebida entre táctica y táctica. Cobrado; los memes, gratis."}
	if d.m.directiva != null:
		d.m.directiva.mover_confianza(-3, "el desplante al patrocinador")
	return {"titulo": "Yo hablo de fútbol",
		"cuerpo": "El patrocinador llamó al presidente. El presidente te llamó a ti."}

func _ev_apuestas(d: Decision) -> Dictionary:
	if d.si:
		if d.j != null:
			d.j.suspension = maxi(d.j.suspension, 3)
			d.j.cambiar_moral(-8, "Prensa y declaraciones")
		return {"titulo": "Apartado mientras se investiga",
			"cuerpo": "Tres partidos fuera por decisión del club. Si sale limpio, habrá que pedirle perdón."}
	_mover_funa(12)
	if Azar.suerte(0.4):
		_pagar(d.mio, -Eco.escalar(150000.0, d.rep), "Multa de la federación (apuestas)")
		if d.j != null:
			d.j.suspension = maxi(d.j.suspension, 4)
		return {"titulo": "La federación actúa",
			"cuerpo": "Aparecieron más mensajes. Multa para el club y cuatro partidos de sanción. Defenderlo en público salió caro."}
	if d.j != null:
		d.j.cambiar_moral(6, "Prensa y declaraciones")
	return {"titulo": "Se archiva",
		"cuerpo": "La fiscalía no encuentra nada. Tu respaldo fue polémico, pero el jugador no lo va a olvidar."}

func _ev_huelga_impagos(d: Decision) -> Dictionary:
	if not d.si:
		_efecto("calendario_pagos", 2)
		return {"titulo": "Calendario de pagos",
			"cuerpo": "Firman un acuerdo a dos semanas. Entrenan, pero con carteles en la valla."}
	_pagar(d.mio, -d.mio.masa_salarial() * 2, "Atrasos al plantel")
	for x: Jugador in d.mio.plantilla:
		x.cambiar_moral(2, "Prensa y declaraciones")
	return {"titulo": "Atrasos pagados",
		"cuerpo": "Dos semanas de sueldo sobre la mesa. Se vuelve a entrenar mañana."}

func _ev_derbi_amenaza(d: Decision) -> Dictionary:
	if d.si:
		_pagar(d.mio, -Eco.escalar(90000.0, d.rep), "Operativo de seguridad del clásico")
		return {"titulo": "Clásico en paz",
			"cuerpo": "Más efectivos, controles en los accesos y ningún incidente. Nadie lo nota, que es la idea."}
	if Azar.suerte(0.35):
		_pagar(d.mio, -Eco.escalar(200000.0, d.rep), "Multa por incidentes en el clásico")
		mover_animo(-5)
		return {"titulo": "Incidentes en el clásico",
			"cuerpo": "Hubo enfrentamientos a la salida. Multa de la federación y una semana de portadas que nadie quería."}
	## Sin vallas extra ni cacheos eternos, la grada lo vive más cerca.
	mover_animo(2)
	return {"titulo": "Sin incidentes",
		"cuerpo": "Esta vez no pasó nada, y la grada vivió el clásico sin vallas de más. Esta vez."}

func _ev_reclamo(d: Decision) -> Dictionary:
	var arb := arbitro_polemico if arbitro_polemico != "" else "el árbitro"
	## Se limpia SIEMPRE, reclames o no: el tema se cierra esta semana y
	## no puede volver a salir en la baraja de la semana que viene.
	arbitro_polemico = ""
	if not d.si:
		return {"titulo": "Página pasada",
			"cuerpo": "Guardaste el video de las jugadas en un cajón. A lo que sigue."}
	## Reclamar es una apuesta perdedora siete de cada diez veces, y
	## eso es lo que la hace una decisión: la multa NO se escala al
	## tamaño del club, así que al chico le duele de verdad.
	if Azar.suerte(0.3):
		var multa := 100000 if abogado_en_directorio else 200000
		_pagar(d.mio, -multa, "Multa de la asociación")
		return {"titulo": "Reclamo rechazado",
			"cuerpo": "La asociación desestimó el reclamo contra %s y además multó al club por las declaraciones." % arb}
	mover_animo(3)
	return {"titulo": "Reclamo acogido",
		"cuerpo": "La asociación reconoció errores de %s. No cambia el resultado, pero la hinchada siente justicia." % arb}

func _ev_lobby_arbitral(d: Decision) -> Dictionary:
	if not d.si:
		return {"titulo": "Distancia prudente",
			"cuerpo": "El directorio prefiere no acercarse al tribunal. El enojo acumulado sigue como estaba."}
	_pagar(d.mio, -Eco.escalar(120000.0, d.rep), "Encuentro institucional con la comisión arbitral")
	if d.m.federacion != null:
		d.m.federacion.enojo_arbitral = maxi(0, d.m.federacion.enojo_arbitral - 1)
	## Tres de cada diez veces se filtra: el costo político de ir a
	## "hacer relaciones públicas" con el tribunal, aunque igual funcione.
	if Azar.suerte(0.3):
		_mover_funa(Azar.ent(5, 10))
		if d.m.directiva != null:
			d.m.directiva.mover_confianza(-6, "se filtró el encuentro con la comisión arbitral")
		return {"titulo": "Se filtró el encuentro",
			"cuerpo": "Un asistente le contó todo a la prensa rival: \"fueron a comprar árbitros\", tituló un matutino. El tribunal, de todos modos, quedó con mejor cara para la próxima apelación."}
	return {"titulo": "Encuentro discreto",
		"cuerpo": "Nadie se enteró de la cena institucional. El tribunal recuerda mejor al club para la próxima apelación."}

## Si la cesión no se puede (`_ceder` dice que no: mayor de 21, ya cedido o plantel corto), el chico se
## queda como si hubieras dicho que no.
func _ev_prestamo_juv(d: Decision) -> Dictionary:
	if d.j == null:
		return {}
	if d.si and _ceder(d.m, d.mio, d.j):
		_pagar(d.mio, Eco.escalar(400000.0, d.rep), "Préstamo con cargo: %s" % d.j.nombre)
		return {"titulo": "Cesión millonaria",
			"cuerpo": "%s se va un año con minutos garantizados y %s para la caja. Vuelve hecho jugador." % [
				d.j.nombre, _dinero(Eco.escalar(400000.0, d.rep))]}
	d.j.cambiar_moral(4, "Prensa y declaraciones")
	return {"titulo": "La joya se queda",
		"cuerpo": "%s agradece la confianza: \"quiero triunfar aquí\"." % d.j.nombre}

func _ev_sub20(d: Decision) -> Dictionary:
	if d.j == null:
		return {}
	if d.si:
		## Vuelve fundido (físico a 45) pero con un punto más de techo:
		## el precio de crecer es una mala semana, no un mal año.
		d.j.fisico = 45
		d.j.cambiar_moral(12, "Prensa y declaraciones")
		d.j.pot = clampi(d.j.pot + 1, d.j.ovr, 97)
		d.j.tasar()
		return {"titulo": "Orgullo de cantera",
			"cuerpo": "%s se fue con la Sub-20. Vuelve fundido pero más jugador." % d.j.nombre}
	d.j.cambiar_moral(-7, "Prensa y declaraciones")
	return {"titulo": "Retenido",
		"cuerpo": "%s se queda entrenando con el primer equipo, con cara larga." % d.j.nombre}

## LA TABLA DE DESPACHO: id del evento -> la función que lo resuelve. Todo evento que pueda quedar en
## `pendiente` (los de `_pool`, más "fondo_presiona", que inyecta `Mundo.avanzar_semana`) tiene que estar
## aquí; uno que no esté se cierra sin publicar nada, como hacía el `match` sin rama. Se arma en cada
## llamada -una por decisión firmada- para que las referencias a métodos las compruebe el analizador y la
## prensa no se guarde Callables a sí misma.
func _resolvedores() -> Dictionary:
	return {
		"fondo_presiona": _ev_fondo_presiona, "retiro_joven": _ev_retiro_joven,
		"virus_fifa": _ev_virus_fifa, "filtracion_agente": _ev_filtracion_agente,
		"hostil": _ev_hostil, "comercial": _ev_comercial,
		"aumento": _ev_aumento, "benefico": _ev_benefico, "gira": _ev_gira, "docu": _ev_docu,
		"agente": _ev_agente, "tv": _ev_tv, "espia": _ev_espia, "provoca": _ev_provoca,
		"aniversario": _ev_aniversario, "huelgaBono": _ev_huelga_bono,
		"tunel": _ev_tunel, "viral": _ev_viral, "capitan": _ev_capitan, "silencio": _ev_silencio,
		"cambio_posicion": _ev_cambio_posicion, "sponsor_rueda": _ev_sponsor_rueda,
		"apuestas": _ev_apuestas, "huelga_impagos": _ev_huelga_impagos,
		"derbi_amenaza": _ev_derbi_amenaza, "reclamo": _ev_reclamo, "lobby_arbitral": _ev_lobby_arbitral,
		"prestamoJuv": _ev_prestamo_juv, "sub20": _ev_sub20,
	}

## Firma la decisión. `op` es "a" o "b". Devuelve {titulo, cuerpo} con lo que
## salió publicado, o vacío si no había nada que firmar.
##
## No hay opción neutra a propósito: las dos ramas mueven algo. Un "ya veremos"
## convertiría todo esto en un botón de cerrar ventana.
func resolver(op: String) -> Dictionary:
	if pendiente.is_empty():
		return {}
	var m := _mundo()
	var mio: Club = m.mi_club() if m != null else null
	if mio == null:
		pendiente = {}
		return {}
	var d := Decision.new()
	d.m = m
	d.mio = mio
	d.e = pendiente
	d.si = op == "a"
	var id := String(d.e["id"])
	## La fama se anota antes de mover nada y el jugador se busca antes de que el evento pueda sacarlo
	## del plantel (retiro, cesión): la función del evento lo recibe ya resuelto.
	_reputacion_de_decision(m, id, d.si)
	d.j = _jugador(mio, String(d.e.get("pid", "")))
	d.rep = float(mio.rep)

	var salida := {"titulo": "", "cuerpo": ""}
	var tabla := _resolvedores()
	if tabla.has(id):
		var publicada: Dictionary = (tabla[id] as Callable).call(d)
		if not publicada.is_empty():
			salida = publicada

	pendiente = {}
	if String(salida["titulo"]) != "":
		noticia.emit(String(salida["titulo"]), String(salida["cuerpo"]))
	evento_resuelto.emit(id, op, String(salida["titulo"]), String(salida["cuerpo"]))
	return salida
