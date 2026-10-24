extends "res://nucleo/prensa_p3.gd"
## [Capa 4/8 de `prensa.gd`] resolver_1

## (Parte 4 de 7 de `prensa.gd`.)

## Firma la decisión. `op` es "a" o "b". Devuelve {titulo, cuerpo} con lo que
## salió publicado, o vacío si no había nada que firmar.
##
## No hay opción neutra a propósito: las dos ramas mueven algo. Un "ya veremos"
## convertiría todo esto en un botón de cerrar ventana.
## Tramo 1 de 2 de `resolver` (la norma de 450 líneas la troceó).
func resolver_1(op: String) -> Array:
	if pendiente.is_empty():
		return [true, {}]
	var m := _mundo()
	var mio: Club = m.mi_club() if m != null else null
	if mio == null:
		pendiente = {}
		return [true, {}]
	var e := pendiente
	var si := op == "a"
	_reputacion_de_decision(m, String(e["id"]), si)
	var j: Jugador = _jugador(mio, String(e.get("pid", "")))
	var rep := float(mio.rep)
	var salida := {"titulo": "", "cuerpo": ""}

	match String(e["id"]):
		"fondo_presiona":
			## Ceder es listarlo y cobrar; negarse le baja la moral al chico, porque
			## su entorno lleva semanas diciendole que el club le frena la carrera.
			if si and j != null:
				if m != null and m.mercado != null:
					m.mercado.listar_transferible(j)
				salida = {"titulo": "Sale al mercado",
					"cuerpo": "%s queda listado como transferible. El fondo respira y tu plantilla se queda mas corta." % j.nombre}
			elif j != null:
				if m != null and m.cesiones != null:
					m.cesiones.rechazar_presion(j)
				salida = {"titulo": "No se vende",
					"cuerpo": "Le dices al fondo que %s se queda. Tomaron nota, y el jugador también." % j.nombre}

		"retiro_joven":
			## No se compra la decisión: lo único que se puede negociar es CUÁNDO.
			## Y aun pidiéndolo bien, cuatro de cada diez se van igual: es lo que
			## hace que este evento se recuerde.
			if si and j != null:
				if Azar.suerte(0.6):
					j.cambiar_moral(-8, "Prensa y declaraciones")
					salida = {"titulo": "Se queda hasta junio",
						"cuerpo": "%s acepta terminar la temporada antes de retirarse. Juega, pero ya no está aquí del todo." % j.nombre}
				else:
					_retirar_de_golpe(mio, j)
					salida = {"titulo": "Se va igual",
						"cuerpo": "%s escuchó, dio las gracias y se fue. A veces no hay nada que ofrecer." % j.nombre}
			elif j != null:
				_retirar_de_golpe(mio, j)
				mover_animo(-4)
				salida = {"titulo": "Cuelga las botas",
					"cuerpo": "%s deja el fútbol con %d años. El club se queda sin él y sin un peso de traspaso: hay que rehacer la plantilla a mitad de temporada." % [j.nombre, j.edad]}

		"virus_fifa":
			## Reclamar el aplazamiento cuesta relación con la federación y sale
			## bien la mitad de las veces. Jugar con juveniles es seguro y caro.
			if si:
				if m != null and m.federacion != null:
					m.federacion.aliados = clampi(m.federacion.aliados - 1, -10, 10)
				if Azar.suerte(0.5):
					salida = {"titulo": "Partido aplazado",
						"cuerpo": "La federación acepta mover el derbi. Te lo van a recordar la próxima vez que pidas algo."}
				else:
					_fatigar_por_viaje(mio)
					salida = {"titulo": "Reclamación rechazada",
						"cuerpo": "La federación dice que el calendario no se toca. Tus internacionales llegan de madrugada y el domingo se juega igual."}
			else:
				_fatigar_por_viaje(mio)
				mover_animo(2)
				salida = {"titulo": "Se juega con los de casa",
					"cuerpo": "Sacas a los juveniles sin quejarte. La grada lo agradece; las piernas, no."}

		"filtracion_agente":
			## Las dos ramas cuestan. Desmentir alimenta el tema una semana más;
			## callar lo da por cierto en el vestuario.
			if si:
				_mover_funa(Azar.ent(6, 14))
				rep_entrenador = clampi(rep_entrenador + 3, 0, 100)
				salida = {"titulo": "Sales a desmentir",
					"cuerpo": "Diste la cara y sonaste firme, pero el tema aguanta una semana más en todos los programas."}
			else:
				for x: Jugador in mio.plantilla:
					x.cambiar_moral(-2, "Prensa y declaraciones")
				if m != null and m.directiva != null:
					m.directiva.mover_confianza(-4, "los correos filtrados")
				salida = {"titulo": "Silencio",
					"cuerpo": "No dijiste nada y el vestuario leyó los correos igual que todo el mundo. La directiva tampoco los ha olvidado."}

		"hostil":
			## Aceptar salva el puesto -sube confianza YA- y trae dos costos que se
			## notan después: un titular impuesto sin plazo (`impuesto_hasta = -1`,
			## lo revisa `revisar_impuesto()` cada partido) y una purga al azar del
			## cuerpo técnico. Resistir es gratis en el acto y carísimo en confianza.
			if si:
				if m != null and m.directiva != null:
					m.directiva.mover_confianza(14, "aceptaste las condiciones del nuevo dueño")
				impuesto_pid = String(e.get("pid", ""))
				impuesto_hasta = -1
				if m != null and m.staff != null:
					m.staff.purgar_al_azar(mio)
				salida = {"titulo": "Aceptaste las condiciones",
					"cuerpo": "Conservas el puesto y el dueño te respalda, pero perdiste parte de tu cuerpo técnico de confianza y tienes un titular impuesto para el mercado asiático."}
			else:
				if m != null and m.directiva != null:
					m.directiva.mover_confianza(-22, "te plantaste ante el nuevo dueño")
				_pagar(mio, Eco.escalar(320000.0, rep), "El dueño mantiene el presupuesto pese al plante")
				salida = {"titulo": "Te plantaste",
					"cuerpo": "El dueño te dejó el presupuesto intacto por ahora, pero la confianza del directorio se desplomó: estás en la cuerda floja."}

		"comercial":
			## A diferencia de "hostil", este pacto SÍ vence -al cierre de la
			## temporada en la que se firma- y la rama de negarse cuesta plata y
			## confianza en el acto en vez de dejar una obligación pendiente.
			if si:
				impuesto_pid = String(e.get("pid", ""))
				impuesto_hasta = m.anio if m != null else -1
				_pagar(mio, Eco.escalar(215000.0, rep), "Trato comercial: fichaje impuesto")
				salida = {"titulo": "Aceptaste el trato comercial",
					"cuerpo": "Entra plata de patrocinio, pero tienes un titular fijo que no elegiste: si lo dejas fuera del once, el patrocinador te lo cobra."}
			else:
				if m != null and m.directiva != null:
					m.directiva.mover_confianza(-9, "rechazaste el trato comercial")
				_pagar(mio, -Eco.escalar(105000.0, rep), "Descuento del área comercial")
				salida = {"titulo": "El once lo eliges tú",
					"cuerpo": "El área comercial te descontó el bono por rechazar el trato y la junta tomó nota."}

		"aumento":
			if j == null:
				pass
			elif si:
				j.sueldo = int(round(float(j.sueldo) * 1.25))
				j.cambiar_moral(10, "Prensa y declaraciones")
				salida = {"titulo": "Renovación mejorada",
					"cuerpo": "%s firma feliz. El camarín toma nota de quién paga." % j.nombre}
			else:
				j.cambiar_moral(-9, "Prensa y declaraciones")
				salida = {"titulo": "Portazo en la gerencia",
					"cuerpo": "Le recordaste que un contrato se respeta. %s entrena en silencio." % j.nombre}

		"benefico":
			if si:
				for x in mio.plantilla:
					x.fisico = clampi(x.fisico - 6, 10, 100)
					x.cambiar_moral(3, "Prensa y declaraciones")
				rep_entrenador = clampi(rep_entrenador + 1, 1, 99)
				salida = {"titulo": "Aplausos de pie",
					"cuerpo": "El amistoso benéfico llenó el estadio chico. La ciudad habla bien del club."}
			else:
				salida = {"titulo": "Piernas frescas",
					"cuerpo": "Rechazaste el amistoso con elegancia: la semana fue de recuperación."}

		"gira":
			if si:
				_pagar(mio, -Eco.escalar(300000.0, rep), "Mini-gira por el norte")
				for x in mio.plantilla:
					x.forma = clampi(x.forma + 6, 20, 99)
				salida = {"titulo": "Gira redonda",
					"cuerpo": "Tres días de trabajo y mar: el plantel vuelve enchufado."}
			else:
				salida = {"titulo": "Sin gira", "cuerpo": "La caja lo agradece."}

		"docu":
			if si:
				_pagar(mio, Eco.escalar(600000.0, rep), "Derechos del documental")
				semanas_documental = 6
				salida = {"titulo": "Luces y cámaras",
					"cuerpo": "Firmaste el documental. Seis semanas de micrófonos abiertos en el camarín…"}
			else:
				salida = {"titulo": "Puertas cerradas", "cuerpo": "La intimidad del grupo no se vende."}

		"agente":
			if j == null:
				pass
			elif si:
				## La cláusula se redondea a decenas de millar, como en el HTML:
				## una cifra de rescisión con céntimos no la firma nadie.
				var clau := int(round(float(j.valor) * 3.0 / 10000.0)) * 10000
				clausulas[j.id] = clau
				j.sueldo = int(round(float(j.sueldo) * 1.1))
				salida = {"titulo": "Blindado",
					"cuerpo": "%s firma mejora con cláusula de %s. El agente guarda los dientes." % [j.nombre, _dinero(clau)]}
			else:
				oferta_forzada = j.id
				for x in mio.plantilla:
					x.cambiar_moral(-1, "Prensa y declaraciones")
				salida = {"titulo": "Puerta entreabierta",
					"cuerpo": "Dejaste correr el rumor: llegará una oferta grande por %s. El camarín murmura." % j.nombre}

		"tv":
			if si:
				_pagar(mio, Eco.escalar(200000.0, rep), "Pauta televisiva")
				mover_animo(4)
				semanas_documental = maxi(semanas_documental, 2)
				salida = {"titulo": "Estrella de la semana",
					"cuerpo": "Saliste en horario prime. La hinchada te celebra; el camarín aguanta dos semanas de micrófonos."}
			else:
				salida = {"titulo": "Perfil bajo", "cuerpo": "Que hable la cancha."}

	match String(e["id"]):
		"espia":
			if si:
				_pagar(mio, -Eco.escalar(80000.0, rep), "Informe reservado del rival")
				dato_del_rival = true
				salida = {"titulo": "Dato en el bolsillo",
					"cuerpo": "El parte llegó en un sobre sin remitente: dos bajas sensibles al frente. Tu equipo saldrá con ventaja."}
			else:
				## Rechazar el sobre no es gratis ni inútil: los líderes del
				## vestuario lo ven, y la moral de un líder pesa en la cancha.
				for x in mio.plantilla:
					if x.rasgo == "lider":
						x.cambiar_moral(3, "Prensa y declaraciones")
				salida = {"titulo": "Juego limpio",
					"cuerpo": "Rechazaste el sobre. En el camarín, los referentes toman nota del gesto."}

		"provoca":
			if si:
				mover_animo(3)
				presion_prometida = true
				salida = {"titulo": "Respuesta con altura y filo",
					"cuerpo": "\"Ideas tenemos; lo que no tenemos es tiempo para fantasmas\". La hinchada celebra, pero ahora hay que ganar."}
			else:
				salida = {"titulo": "Silencio de campeón",
					"cuerpo": "Sin declaraciones. La cancha hablará el fin de semana."}

		"aniversario":
			if si:
				_pagar(mio, -Eco.escalar(150000.0, rep), "Fiesta de aniversario")
				mover_animo(8)
				mio.socios += 400
				salida = {"titulo": "Cumpleaños a estadio lleno",
					"cuerpo": "Leyendas, fuegos artificiales y camiseta conmemorativa. La ciudad entera es del club esta semana."}
			else:
				salida = {"titulo": "Aniversario austero",
					"cuerpo": "Un video institucional y a otra cosa. La caja lo agradece."}

		"huelgaBono":
			if si:
				_pagar(mio, -Eco.escalar(100000.0, rep), "Bono al plantel")
				primas_activas = true
				for x in mio.plantilla:
					x.cambiar_moral(4, "Prensa y declaraciones")
				salida = {"titulo": "Gesto al camarín",
					"cuerpo": "Bono entregado y primas por objetivos activadas en las normas. El plantel responde en la cancha."}
			else:
				for x in mio.plantilla:
					x.cambiar_moral(-3, "Prensa y declaraciones")
				salida = {"titulo": "Sin bonos",
					"cuerpo": "\"El sueldo ya es el bono\". Caras largas en la práctica."}

		"tunel":
			if si:
				for x: Jugador in mio.plantilla:
					x.cambiar_moral(3, "Prensa y declaraciones")
				if Azar.suerte(0.3):
					_mover_funa(6)
					salida = {"titulo": "La provocación se filtra",
						"cuerpo": "Tu frase en el túnel la captó un micrófono de ambiente. El equipo salió encendido, pero la prensa ya tiene titular."}
				else:
					salida = {"titulo": "Guerra psicológica",
						"cuerpo": "El DT rival se quedó blanco. Tus jugadores lo vieron y salieron a la cancha dos metros más arriba."}
			else:
				if m != null and m.federacion != null:
					m.federacion.enojo_arbitral += 1
				if Azar.suerte(0.35):
					_pagar(mio, -Eco.escalar(40000.0, rep), "Multa por presionar al árbitro")
					salida = {"titulo": "El árbitro lo pone en el acta",
						"cuerpo": "Tu comentario terminó en el informe arbitral. Multa, y el tribunal ya te mira con lupa."}
				else:
					salida = {"titulo": "Recado entregado",
						"cuerpo": "El árbitro no dijo nada, pero lo escuchó. El tribunal, si se entera, no lo va a olvidar."}

		"viral":
			if si:
				if j != null:
					j.cambiar_moral(-6, "Prensa y declaraciones")
					j.suspension = maxi(j.suspension, 1)
				_mover_funa(-5)
				if m != null and m.directiva != null:
					m.directiva.mover_confianza(2, "la sanción ejemplar")
				salida = {"titulo": "Sanción ejemplar",
					"cuerpo": "Un partido fuera y multa interna. La directiva aplaude; el jugador, no."}
			else:
				if j != null:
					j.cambiar_moral(4, "Prensa y declaraciones")
				_mover_funa(10)
				_efecto("eco_viral", 2)
				salida = {"titulo": "Lo defiendes",
					"cuerpo": "\"Tiene derecho a una vida\". El vestuario lo agradece; las redes llevan dos semanas con el video."}

		"capitan":
			if si:
				for x: Jugador in mio.plantilla:
					x.cambiar_moral(3, "Prensa y declaraciones")
				rep_entrenador = clampi(rep_entrenador - 2, 0, 100)
				salida = {"titulo": "Carga más liviana",
					"cuerpo": "Aflojas los entrenamientos una semana. El grupo sonríe; algún periodista dice que el capitán manda más que tú."}
			else:
				if j != null:
					j.cambiar_moral(-8, "Prensa y declaraciones")
				rep_entrenador = clampi(rep_entrenador + 3, 0, 100)
				_efecto("vestuario_tenso", 3)
				salida = {"titulo": "\"Aquí mando yo\"",
					"cuerpo": "Dejas claro quién decide. Autoridad ganada, pero el vestuario va a estar tenso unas semanas."}

		"silencio":
			if si:
				_pagar(mio, -Eco.escalar(50000.0, rep), "Homenaje y camiseta conmemorativa")
				mover_animo(6)
				mio.socios += 200
				salida = {"titulo": "Un homenaje a la altura",
					"cuerpo": "Minuto de silencio, su nombre en la camiseta y la barra cantando su canción. Nadie en el estadio lo va a olvidar."}
			else:
				mover_animo(2)
				salida = {"titulo": "Minuto de silencio",
					"cuerpo": "Respeto total en el estadio. Sencillo y digno."}

		"cambio_posicion":
			var nueva := String(e.get("dato", "MC"))
			if si and j != null:
				if not j.pos_sec.has(nueva):
					j.pos_sec.append(nueva)
				j.cambiar_moral(6, "Prensa y declaraciones")
				_efecto("posicion_nueva", 3, j.id)
				salida = {"titulo": "%s, de %s" % [j.nombre, nueva],
					"cuerpo": "Ya figura como %s en su ficha. Unas semanas de adaptación y veremos si tenía razón." % nueva}
			else:
				if j != null:
					j.cambiar_moral(-6, "Prensa y declaraciones")
				salida = {"titulo": "Cada uno en su sitio",
					"cuerpo": "Le dices que no. Lo entiende, pero se le nota en la cara."}

		"sponsor_rueda":
			if si:
				_pagar(mio, Eco.escalar(120000.0, rep), "Mención del patrocinador")
				rep_entrenador = clampi(rep_entrenador - 3, 0, 100)
				_mover_funa(3)
				salida = {"titulo": "La frase más cara",
					"cuerpo": "Nombraste la bebida entre táctica y táctica. Cobrado; los memes, gratis."}
			else:
				if m != null and m.directiva != null:
					m.directiva.mover_confianza(-3, "el desplante al patrocinador")
				salida = {"titulo": "Yo hablo de fútbol",
					"cuerpo": "El patrocinador llamó al presidente. El presidente te llamó a ti."}

		"apuestas":
			if si:
				if j != null:
					j.suspension = maxi(j.suspension, 3)
					j.cambiar_moral(-8, "Prensa y declaraciones")
				salida = {"titulo": "Apartado mientras se investiga",
					"cuerpo": "Tres partidos fuera por decisión del club. Si sale limpio, habrá que pedirle perdón."}
			else:
				_mover_funa(12)
				if Azar.suerte(0.4):
					_pagar(mio, -Eco.escalar(150000.0, rep), "Multa de la federación (apuestas)")
					if j != null:
						j.suspension = maxi(j.suspension, 4)
					salida = {"titulo": "La federación actúa",
						"cuerpo": "Aparecieron más mensajes. Multa para el club y cuatro partidos de sanción. Defenderlo en público salió caro."}
				else:
					salida = {"titulo": "Se archiva",
						"cuerpo": "La fiscalía no encuentra nada. Tu respaldo fue polémico, pero el jugador no lo va a olvidar."}
					if j != null:
						j.cambiar_moral(6, "Prensa y declaraciones")
		"huelga_impagos":
			if si:
				_pagar(mio, -mio.masa_salarial() * 2, "Atrasos al plantel")
				for x: Jugador in mio.plantilla:
					x.cambiar_moral(2, "Prensa y declaraciones")
				salida = {"titulo": "Atrasos pagados",
					"cuerpo": "Dos semanas de sueldo sobre la mesa. Se vuelve a entrenar mañana."}
			else:
				_efecto("calendario_pagos", 2)
				salida = {"titulo": "Calendario de pagos",
					"cuerpo": "Firman un acuerdo a dos semanas. Entrenan, pero con carteles en la valla."}
	return [false, m, mio, e, si, j, rep, salida]
