extends "res://nucleo/prensa_p4_p1.gd"
## [Capa 5/8 de `prensa.gd`] resolver_2, resolver

## Tramo 2 de 2 de `resolver` (la norma de 450 líneas la troceó).
func resolver_2(op: String, m: Mundo, mio: Club, e: Dictionary, si: bool, j: Jugador, rep: float, salida: Dictionary) -> Array:

	match String(e["id"]):
		"derbi_amenaza":
			if si:
				_pagar(mio, -Eco.escalar(90000.0, rep), "Operativo de seguridad del clásico")
				salida = {"titulo": "Clásico en paz",
					"cuerpo": "Más efectivos, controles en los accesos y ningún incidente. Nadie lo nota, que es la idea."}
			elif Azar.suerte(0.35):
				_pagar(mio, -Eco.escalar(200000.0, rep), "Multa por incidentes en el clásico")
				mover_animo(-5)
				salida = {"titulo": "Incidentes en el clásico",
					"cuerpo": "Hubo enfrentamientos a la salida. Multa de la federación y una semana de portadas que nadie quería."}
			else:
				## Sin vallas extra ni cacheos eternos, la grada lo vive más cerca.
				mover_animo(2)
				salida = {"titulo": "Sin incidentes",
					"cuerpo": "Esta vez no pasó nada, y la grada vivió el clásico sin vallas de más. Esta vez."}

		"reclamo":
			var arb := arbitro_polemico if arbitro_polemico != "" else "el árbitro"
			## Se limpia SIEMPRE, reclames o no: el tema se cierra esta semana y
			## no puede volver a salir en la baraja de la semana que viene.
			arbitro_polemico = ""
			if si:
				## Reclamar es una apuesta perdedora siete de cada diez veces, y
				## eso es lo que la hace una decisión: la multa NO se escala al
				## tamaño del club, así que al chico le duele de verdad.
				if Azar.suerte(0.3):
					var multa := 100000 if abogado_en_directorio else 200000
					_pagar(mio, -multa, "Multa de la asociación")
					salida = {"titulo": "Reclamo rechazado",
						"cuerpo": "La asociación desestimó el reclamo contra %s y además multó al club por las declaraciones." % arb}
				else:
					mover_animo(3)
					salida = {"titulo": "Reclamo acogido",
						"cuerpo": "La asociación reconoció errores de %s. No cambia el resultado, pero la hinchada siente justicia." % arb}
			else:
				salida = {"titulo": "Página pasada",
					"cuerpo": "Guardaste el video de las jugadas en un cajón. A lo que sigue."}

		"lobby_arbitral":
			if si:
				_pagar(mio, -Eco.escalar(120000.0, rep), "Encuentro institucional con la comisión arbitral")
				if m.federacion != null:
					m.federacion.enojo_arbitral = maxi(0, m.federacion.enojo_arbitral - 1)
				## Tres de cada diez veces se filtra: el costo político de ir a
				## "hacer relaciones públicas" con el tribunal, aunque igual funcione.
				if Azar.suerte(0.3):
					_mover_funa(Azar.ent(5, 10))
					if m.directiva != null:
						m.directiva.mover_confianza(-6, "se filtró el encuentro con la comisión arbitral")
					salida = {"titulo": "Se filtró el encuentro",
						"cuerpo": "Un asistente le contó todo a la prensa rival: \"fueron a comprar árbitros\", tituló un matutino. El tribunal, de todos modos, quedó con mejor cara para la próxima apelación."}
				else:
					salida = {"titulo": "Encuentro discreto",
						"cuerpo": "Nadie se enteró de la cena institucional. El tribunal recuerda mejor al club para la próxima apelación."}
			else:
				salida = {"titulo": "Distancia prudente",
					"cuerpo": "El directorio prefiere no acercarse al tribunal. El enojo acumulado sigue como estaba."}

		"prestamoJuv":
			if j == null:
				pass
			elif si and _ceder(m, mio, j):
				_pagar(mio, Eco.escalar(400000.0, rep), "Préstamo con cargo: %s" % j.nombre)
				salida = {"titulo": "Cesión millonaria",
					"cuerpo": "%s se va un año con minutos garantizados y %s para la caja. Vuelve hecho jugador." % [
						j.nombre, _dinero(Eco.escalar(400000.0, rep))]}
			else:
				j.cambiar_moral(4, "Prensa y declaraciones")
				salida = {"titulo": "La joya se queda",
					"cuerpo": "%s agradece la confianza: \"quiero triunfar aquí\"." % j.nombre}

		"sub20":
			if j == null:
				pass
			elif si:
				## Vuelve fundido (físico a 45) pero con un punto más de techo:
				## el precio de crecer es una mala semana, no un mal año.
				j.fisico = 45
				j.cambiar_moral(12, "Prensa y declaraciones")
				j.pot = clampi(j.pot + 1, j.ovr, 97)
				j.tasar()
				salida = {"titulo": "Orgullo de cantera",
					"cuerpo": "%s se fue con la Sub-20. Vuelve fundido pero más jugador." % j.nombre}
			else:
				j.cambiar_moral(-7, "Prensa y declaraciones")
				salida = {"titulo": "Retenido",
					"cuerpo": "%s se queda entrenando con el primer equipo, con cara larga." % j.nombre}

	pendiente = {}
	if String(salida["titulo"]) != "":
		noticia.emit(String(salida["titulo"]), String(salida["cuerpo"]))
	evento_resuelto.emit(String(e["id"]), op, String(salida["titulo"]), String(salida["cuerpo"]))
	return [true, salida]
	return [false, salida]

func resolver(op: String) -> Dictionary:
	var _r1 = resolver_1(op)
	if _r1[0]:
		return _r1[1]
	var m: Mundo = _r1[1]
	var mio: Club = _r1[2]
	var e: Dictionary = _r1[3]
	var si: bool = _r1[4]
	var j: Jugador = _r1[5]
	var rep: float = _r1[6]
	var salida: Dictionary = _r1[7]
	var _r2 = resolver_2(op, m, mio, e, si, j, rep, salida)
	return _r2[1]
	salida = _r2[1]
