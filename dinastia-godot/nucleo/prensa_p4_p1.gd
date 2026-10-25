extends "res://nucleo/prensa_p3.gd"
## [Capa 4/8 de `prensa.gd`] Decision y los eventos del despacho, primera tanda (contratos, dueños y caja)
##
## FASE 0 (25-10-2026): `resolver` era un `match` de ~370 líneas por id de evento, troceado en dos tramos
## que se pasaban ocho valores en un Array. Ahora cada evento es una función `_ev_<id>(d)` que recibe la
## `Decision` y devuelve lo publicado ({titulo, cuerpo}, o vacío si no hay nada que contar), y la tabla de
## despacho de `prensa_p4.gd` las une. Mismo orden de efectos y de sorteos que antes, comprobado con
## `pruebas/ideas/f0e_resolver.gd` (todas las ramas, con "a" y "b" y ocho semillas de `Azar`).

## Lo que necesita cada salida para decidir. Se arma una vez en `resolver` y viaja a la función del evento,
## en vez de pasar seis argumentos que la mitad de los eventos no usa.
class Decision extends RefCounted:
	var m: Mundo
	var mio: Club
	var e: Dictionary         ## el evento pendiente tal como se sorteó (id, pid, dato…)
	var si: bool              ## true = opción "a"
	var j: Jugador            ## el jugador del evento, o null si no tiene o ya no está en el plantel
	var rep: float            ## reputación del club: escala lo que se cobra y lo que se paga

## Ceder es listarlo y cobrar; negarse le baja la moral al chico, porque
## su entorno lleva semanas diciendole que el club le frena la carrera.
func _ev_fondo_presiona(d: Decision) -> Dictionary:
	if d.si and d.j != null:
		if d.m.mercado != null:
			d.m.mercado.listar_transferible(d.j)
		return {"titulo": "Sale al mercado",
			"cuerpo": "%s queda listado como transferible. El fondo respira y tu plantilla se queda mas corta." % d.j.nombre}
	if d.j != null:
		if d.m.cesiones != null:
			d.m.cesiones.rechazar_presion(d.j)
		return {"titulo": "No se vende",
			"cuerpo": "Le dices al fondo que %s se queda. Tomaron nota, y el jugador también." % d.j.nombre}
	return {}

## No se compra la decisión: lo único que se puede negociar es CUÁNDO.
## Y aun pidiéndolo bien, cuatro de cada diez se van igual: es lo que
## hace que este evento se recuerde.
func _ev_retiro_joven(d: Decision) -> Dictionary:
	if d.j == null:
		return {}
	if d.si:
		if Azar.suerte(0.6):
			d.j.cambiar_moral(-8, "Prensa y declaraciones")
			return {"titulo": "Se queda hasta junio",
				"cuerpo": "%s acepta terminar la temporada antes de retirarse. Juega, pero ya no está aquí del todo." % d.j.nombre}
		_retirar_de_golpe(d.mio, d.j)
		return {"titulo": "Se va igual",
			"cuerpo": "%s escuchó, dio las gracias y se fue. A veces no hay nada que ofrecer." % d.j.nombre}
	_retirar_de_golpe(d.mio, d.j)
	mover_animo(-4)
	return {"titulo": "Cuelga las botas",
		"cuerpo": "%s deja el fútbol con %d años. El club se queda sin él y sin un peso de traspaso: hay que rehacer la plantilla a mitad de temporada." % [d.j.nombre, d.j.edad]}

## Reclamar el aplazamiento cuesta relación con la federación y sale
## bien la mitad de las veces. Jugar con juveniles es seguro y caro.
func _ev_virus_fifa(d: Decision) -> Dictionary:
	if d.si:
		if d.m.federacion != null:
			d.m.federacion.aliados = clampi(d.m.federacion.aliados - 1, -10, 10)
		if Azar.suerte(0.5):
			return {"titulo": "Partido aplazado",
				"cuerpo": "La federación acepta mover el derbi. Te lo van a recordar la próxima vez que pidas algo."}
		_fatigar_por_viaje(d.mio)
		return {"titulo": "Reclamación rechazada",
			"cuerpo": "La federación dice que el calendario no se toca. Tus internacionales llegan de madrugada y el domingo se juega igual."}
	_fatigar_por_viaje(d.mio)
	mover_animo(2)
	return {"titulo": "Se juega con los de casa",
		"cuerpo": "Sacas a los juveniles sin quejarte. La grada lo agradece; las piernas, no."}

## Las dos ramas cuestan. Desmentir alimenta el tema una semana más;
## callar lo da por cierto en el vestuario.
func _ev_filtracion_agente(d: Decision) -> Dictionary:
	if d.si:
		_mover_funa(Azar.ent(6, 14))
		rep_entrenador = clampi(rep_entrenador + 3, 0, 100)
		return {"titulo": "Sales a desmentir",
			"cuerpo": "Diste la cara y sonaste firme, pero el tema aguanta una semana más en todos los programas."}
	for x: Jugador in d.mio.plantilla:
		x.cambiar_moral(-2, "Prensa y declaraciones")
	if d.m.directiva != null:
		d.m.directiva.mover_confianza(-4, "los correos filtrados")
	return {"titulo": "Silencio",
		"cuerpo": "No dijiste nada y el vestuario leyó los correos igual que todo el mundo. La directiva tampoco los ha olvidado."}

## Aceptar salva el puesto -sube confianza YA- y trae dos costos que se
## notan después: un titular impuesto sin plazo (`impuesto_hasta = -1`,
## lo revisa `revisar_impuesto()` cada partido) y una purga al azar del
## cuerpo técnico. Resistir es gratis en el acto y carísimo en confianza.
func _ev_hostil(d: Decision) -> Dictionary:
	if d.si:
		if d.m.directiva != null:
			d.m.directiva.mover_confianza(14, "aceptaste las condiciones del nuevo dueño")
		impuesto_pid = String(d.e.get("pid", ""))
		impuesto_hasta = -1
		if d.m.staff != null:
			d.m.staff.purgar_al_azar(d.mio)
		return {"titulo": "Aceptaste las condiciones",
			"cuerpo": "Conservas el puesto y el dueño te respalda, pero perdiste parte de tu cuerpo técnico de confianza y tienes un titular impuesto para el mercado asiático."}
	if d.m.directiva != null:
		d.m.directiva.mover_confianza(-22, "te plantaste ante el nuevo dueño")
	_pagar(d.mio, Eco.escalar(320000.0, d.rep), "El dueño mantiene el presupuesto pese al plante")
	return {"titulo": "Te plantaste",
		"cuerpo": "El dueño te dejó el presupuesto intacto por ahora, pero la confianza del directorio se desplomó: estás en la cuerda floja."}

## A diferencia de "hostil", este pacto SÍ vence -al cierre de la
## temporada en la que se firma- y la rama de negarse cuesta plata y
## confianza en el acto en vez de dejar una obligación pendiente.
func _ev_comercial(d: Decision) -> Dictionary:
	if d.si:
		impuesto_pid = String(d.e.get("pid", ""))
		impuesto_hasta = d.m.anio
		_pagar(d.mio, Eco.escalar(215000.0, d.rep), "Trato comercial: fichaje impuesto")
		return {"titulo": "Aceptaste el trato comercial",
			"cuerpo": "Entra plata de patrocinio, pero tienes un titular fijo que no elegiste: si lo dejas fuera del once, el patrocinador te lo cobra."}
	if d.m.directiva != null:
		d.m.directiva.mover_confianza(-9, "rechazaste el trato comercial")
	_pagar(d.mio, -Eco.escalar(105000.0, d.rep), "Descuento del área comercial")
	return {"titulo": "El once lo eliges tú",
		"cuerpo": "El área comercial te descontó el bono por rechazar el trato y la junta tomó nota."}

func _ev_aumento(d: Decision) -> Dictionary:
	if d.j == null:
		return {}
	if d.si:
		d.j.sueldo = int(round(float(d.j.sueldo) * 1.25))
		d.j.cambiar_moral(10, "Prensa y declaraciones")
		return {"titulo": "Renovación mejorada",
			"cuerpo": "%s firma feliz. El camarín toma nota de quién paga." % d.j.nombre}
	d.j.cambiar_moral(-9, "Prensa y declaraciones")
	return {"titulo": "Portazo en la gerencia",
		"cuerpo": "Le recordaste que un contrato se respeta. %s entrena en silencio." % d.j.nombre}

func _ev_benefico(d: Decision) -> Dictionary:
	if not d.si:
		return {"titulo": "Piernas frescas",
			"cuerpo": "Rechazaste el amistoso con elegancia: la semana fue de recuperación."}
	for x: Jugador in d.mio.plantilla:
		x.fisico = clampi(x.fisico - 6, 10, 100)
		x.cambiar_moral(3, "Prensa y declaraciones")
	rep_entrenador = clampi(rep_entrenador + 1, 1, 99)
	return {"titulo": "Aplausos de pie",
		"cuerpo": "El amistoso benéfico llenó el estadio chico. La ciudad habla bien del club."}

func _ev_gira(d: Decision) -> Dictionary:
	if not d.si:
		return {"titulo": "Sin gira", "cuerpo": "La caja lo agradece."}
	_pagar(d.mio, -Eco.escalar(300000.0, d.rep), "Mini-gira por el norte")
	for x: Jugador in d.mio.plantilla:
		x.forma = clampi(x.forma + 6, 20, 99)
	return {"titulo": "Gira redonda",
		"cuerpo": "Tres días de trabajo y mar: el plantel vuelve enchufado."}

func _ev_docu(d: Decision) -> Dictionary:
	if not d.si:
		return {"titulo": "Puertas cerradas", "cuerpo": "La intimidad del grupo no se vende."}
	_pagar(d.mio, Eco.escalar(600000.0, d.rep), "Derechos del documental")
	semanas_documental = 6
	return {"titulo": "Luces y cámaras",
		"cuerpo": "Firmaste el documental. Seis semanas de micrófonos abiertos en el camarín…"}

func _ev_agente(d: Decision) -> Dictionary:
	if d.j == null:
		return {}
	if d.si:
		## La cláusula se redondea a decenas de millar, como en el HTML:
		## una cifra de rescisión con céntimos no la firma nadie.
		var clau := int(round(float(d.j.valor) * 3.0 / 10000.0)) * 10000
		clausulas[d.j.id] = clau
		d.j.sueldo = int(round(float(d.j.sueldo) * 1.1))
		return {"titulo": "Blindado",
			"cuerpo": "%s firma mejora con cláusula de %s. El agente guarda los dientes." % [d.j.nombre, _dinero(clau)]}
	oferta_forzada = d.j.id
	for x: Jugador in d.mio.plantilla:
		x.cambiar_moral(-1, "Prensa y declaraciones")
	return {"titulo": "Puerta entreabierta",
		"cuerpo": "Dejaste correr el rumor: llegará una oferta grande por %s. El camarín murmura." % d.j.nombre}

func _ev_tv(d: Decision) -> Dictionary:
	if not d.si:
		return {"titulo": "Perfil bajo", "cuerpo": "Que hable la cancha."}
	_pagar(d.mio, Eco.escalar(200000.0, d.rep), "Pauta televisiva")
	mover_animo(4)
	semanas_documental = maxi(semanas_documental, 2)
	return {"titulo": "Estrella de la semana",
		"cuerpo": "Saliste en horario prime. La hinchada te celebra; el camarín aguanta dos semanas de micrófonos."}

func _ev_espia(d: Decision) -> Dictionary:
	if d.si:
		_pagar(d.mio, -Eco.escalar(80000.0, d.rep), "Informe reservado del rival")
		dato_del_rival = true
		return {"titulo": "Dato en el bolsillo",
			"cuerpo": "El parte llegó en un sobre sin remitente: dos bajas sensibles al frente. Tu equipo saldrá con ventaja."}
	## Rechazar el sobre no es gratis ni inútil: los líderes del
	## vestuario lo ven, y la moral de un líder pesa en la cancha.
	for x: Jugador in d.mio.plantilla:
		if x.rasgo == "lider":
			x.cambiar_moral(3, "Prensa y declaraciones")
	return {"titulo": "Juego limpio",
		"cuerpo": "Rechazaste el sobre. En el camarín, los referentes toman nota del gesto."}

func _ev_provoca(d: Decision) -> Dictionary:
	if not d.si:
		return {"titulo": "Silencio de campeón",
			"cuerpo": "Sin declaraciones. La cancha hablará el fin de semana."}
	mover_animo(3)
	presion_prometida = true
	return {"titulo": "Respuesta con altura y filo",
		"cuerpo": "\"Ideas tenemos; lo que no tenemos es tiempo para fantasmas\". La hinchada celebra, pero ahora hay que ganar."}

func _ev_aniversario(d: Decision) -> Dictionary:
	if not d.si:
		return {"titulo": "Aniversario austero",
			"cuerpo": "Un video institucional y a otra cosa. La caja lo agradece."}
	_pagar(d.mio, -Eco.escalar(150000.0, d.rep), "Fiesta de aniversario")
	mover_animo(8)
	d.mio.socios += 400
	return {"titulo": "Cumpleaños a estadio lleno",
		"cuerpo": "Leyendas, fuegos artificiales y camiseta conmemorativa. La ciudad entera es del club esta semana."}

func _ev_huelga_bono(d: Decision) -> Dictionary:
	if d.si:
		_pagar(d.mio, -Eco.escalar(100000.0, d.rep), "Bono al plantel")
		primas_activas = true
		for x: Jugador in d.mio.plantilla:
			x.cambiar_moral(4, "Prensa y declaraciones")
		return {"titulo": "Gesto al camarín",
			"cuerpo": "Bono entregado y primas por objetivos activadas en las normas. El plantel responde en la cancha."}
	for x: Jugador in d.mio.plantilla:
		x.cambiar_moral(-3, "Prensa y declaraciones")
	return {"titulo": "Sin bonos",
		"cuerpo": "\"El sueldo ya es el bono\". Caras largas en la práctica."}
