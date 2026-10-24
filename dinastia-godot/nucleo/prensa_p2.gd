extends "res://nucleo/prensa_p1.gd"
## [Capa 2/8 de `prensa.gd`] _init, _mundo, _dinero, agente_de, _rival_de_la_semana, _eventos_nuevos … (+10)

## Cuántas veces de cada diez sale portada. El HTML tira un 0,4; aquí se compara
## contra el mismo hash para no tocar la RNG.
const PORTADA_DE_CADA := 10
const PORTADAS_QUE_SALEN := 4

# ---------------------------------------------------------------------------
#  LOS QUE MUEVEN MASAS (`vDebate()`)
# ---------------------------------------------------------------------------
#
# Cinco creadores con más audiencia que cualquier periódico del juego. Opinan de
# lo mismo que la mesa de debate y no valen lo mismo: al tertuliano lo escucha el
# directorio, a estos los escucha la calle, y por eso lo que mueven no es la
# confianza sino los seguidores del club.
#
# La opinión NO usa `Azar`: sale de un hash de la semana y de la racha real de
# los últimos cinco partidos. Es decoración, y la decoración no toca la RNG.

const COSTE_INVITAR := 60000.0

const _INFLU_BIEN := [
	"Este equipo se ha convertido en algo serio. Lo digo yo, que critico todo.",
	"El proyecto funciona. Aguanten al técnico, por favor.",
	"Hoy salí del estadio con los pelos de punta.",
]
const _INFLU_MAL := [
	"No es solo perder, es CÓMO se pierde. Bochorno.",
	"Cambien lo que haya que cambiar, pero cambien algo ya.",
	"Llevo diez años yendo y no había visto un equipo tan sin alma.",
]
const _INFLU_NEUTRO := [
	"Ni tan mal ni tan bien. El club necesita decidir qué quiere ser.",
	"Hay materia prima. Falta paciencia, que es lo que nunca hay.",
	"Ojo con la cantera, que ahí está la respuesta.",
]


## LO QUE DECIDES HACE TU FAMA (26-9-2026, `Reputacion`): cada decisión del
## despacho que dice algo de ti queda anotada. [faceta, delta si "a", delta si "b", motivo]
const REPUTACION_DE := {
	"espia": [["honesto", -12, 6, "El parte médico filtrado del rival"]],
	"benefico": [["social", 6, -2, "El amistoso benéfico"]],
	"provoca": [["mediatico", 4, -1, "Respuesta al DT rival"], ["honesto", -2, 2, "Respuesta al DT rival"]],
	"docu": [["mediatico", 5, -2, "El documental del vestuario"]],
	"aumento": [["leal", 3, -2, "El aumento de tu figura"]],
	"agente": [["negociador", 3, -1, "El agente que ofreció a tu figura"]],
	"apuestas": [["honesto", 5, -3, "La investigación de apuestas"]],
	"lobby_arbitral": [["honesto", -4, 3, "El encuentro con la comisión arbitral"]],
	"huelga_impagos": [["leal", 2, -4, "Los sueldos impagos"]],
	"aniversario": [["social", 4, -1, "El aniversario del club"]],
	"silencio": [["mediatico", -3, 2, "El silencio ante la prensa"]],
	"reclamo": [["honesto", 2, -1, "El reclamo formal"]],
	"tv": [["mediatico", 4, -1, "La oferta de la televisión"]],
	"viral": [["mediatico", 3, 0, "El vídeo viral"]],
}

## Referencia DÉBIL al mundo, por la misma razón que en `Mercado`: el mundo
## guarda su prensa y la prensa necesita ver el mundo. Con dos referencias
## normales eso es un ciclo, y RefCounted no recoge ciclos: al terminar una
## partida se quedaría vivo un Mundo entero con sus 384 clubes dentro.
func _init(mundo: Mundo) -> void:
	_ref = weakref(mundo)

func _mundo() -> Mundo:
	return _ref.get_ref() as Mundo

## El `fmt$` del HTML: puntos internos a euros de pantalla, con las abreviaturas
## y la coma decimal española.
##
## OJO, una diferencia deliberada con el HTML: allí los textos de las decisiones
## imprimían la cifra SIN escalar (€3,6M de gira para todo el mundo) mientras el
## cobro sí se escalaba al tamaño del club, así que a un grande le decían un
## precio y le cobraban otro. Aquí se imprime lo que se cobra. No cambia ninguna
## fórmula: cambia que el número de la pantalla sea verdad.
func _dinero(n: int) -> String:
	return Eco.dinero(n)


# ===========================================================================
#  AUXILIARES
# ===========================================================================

## El agente de un jugador. Es ESTABLE: sale del hash de su id, no de un sorteo,
## para que el mismo futbolista tenga siempre al mismo representante partida tras
## partida. El nombre pasa por `Nombres.limpiar` porque en la tabla está en
## leetspeak ("R. M4ldini").
func agente_de(j: Jugador) -> Dictionary:
	var lista: Array = Datos.tabla("AGENTES")
	var perfiles: Dictionary = Datos.tabla("AG_PERFIL")
	if lista == null or lista.is_empty() or perfiles == null:
		return {"nombre": "un representante", "perfil": "discreto", "f": 1.0, "com": 0.10}
	var h := 3
	for i in j.id.length():
		h = (h * 17 + j.id.unicode_at(i)) & 0xFFFFFFFF
	var fila: Array = lista[h % lista.size()]
	var perfil := String(fila[1])
	var p: Dictionary = perfiles.get(perfil, {})
	return {
		"nombre": Nombres.de_tabla(String(fila[0])),
		"perfil": perfil,
		"etiqueta": String(p.get("d", perfil)),
		"f": float(p.get("f", 1.0)),
		"com": float(p.get("com", 0.10)),
	}

## Contra quién juegas esta semana, si es que juegas. Sirve para el soborno del
## parte médico: sin partido a la vista no hay a quién espiar.
func _rival_de_la_semana(m: Mundo, mio: Club) -> Club:
	var par := m.proximo_partido()
	if par.size() != 2:
		par = m.partido_de_copa()
	if par.size() != 2:
		return null
	return par[1] if par[0] == mio else par[0]

## LOS NUEVE EVENTOS DEL PLAN MAESTRO (25-9-2026, bloque B4). Sacados de
## `instruciones profundas/instrucciones_extras.txt` y del plan, y revisados
## contra el código antes de escribirlos: ninguno existía. Todos tienen dos
## salidas que mueven algo, y varios dejan un efecto que dura semanas
## (`efectos`, se descuenta en `semana()`).
func _eventos_nuevos(pool: Array[Dictionary], m: Mundo, mio: Club, fig: Jugador, rival: Club, rep: float) -> void:
	## Juegos mentales en el túnel: solo si hay partido esta semana.
	if rival != null:
		pool.append({"id": "tunel", "pid": "",
			"txt": "🚇 En el túnel, antes de salir, te cruzas con el DT de %s y con el árbitro, que tiene fama de localista. Tienes diez segundos." % rival.nombre,
			"opcion_a": "Susurrarle una provocación al DT", "opcion_b": "Dejarle caer algo al árbitro"})
	## El video viral de la noche anterior.
	var fiesteros := mio.plantilla.filter(func(x: Jugador) -> bool: return x.edad <= 27)
	if not fiesteros.is_empty():
		var q: Jugador = fiesteros[Azar.ent(0, fiesteros.size() - 1)]
		pool.append({"id": "viral", "pid": q.id,
			"txt": "📱 Circula un video de %s bailando en una discoteca a las 4 de la mañana, dos días antes del partido. Ya lo vio medio país." % q.nombre,
			"opcion_a": "Sanción ejemplar", "opcion_b": "Defenderlo en público"})
	## El capitán pide hablar en nombre del grupo.
	var capi: Jugador = null
	for x: Jugador in mio.plantilla:
		if x.capitan:
			capi = x
	if capi != null:
		pool.append({"id": "capitan", "pid": capi.id,
			"txt": "🗣️ %s, el capitán, pide hablar a solas: el vestuario siente que los entrenamientos son demasiado duros y que no se les escucha." % capi.nombre,
			"opcion_a": "Escuchar y aflojar la carga", "opcion_b": "\"Aquí mando yo\""})
	## El minuto de silencio.
	pool.append({"id": "silencio", "pid": "",
		"txt": "🕯️ Murió un hincha histórico del club, socio desde hace 60 años. La barra pide un homenaje antes del próximo partido en casa.",
		"opcion_a": "Homenaje con camiseta conmemorativa", "opcion_b": "Minuto de silencio y nada más"})
	## Un jugador pide cambiar de posición.
	var inquietos := mio.plantilla.filter(func(x: Jugador) -> bool: return x.pos != "POR" and x.edad <= 29)
	if not inquietos.is_empty():
		var q2: Jugador = inquietos[Azar.ent(0, inquietos.size() - 1)]
		var nueva := String(_POSICION_DESEADA.get(q2.pos_e, "MC"))
		pool.append({"id": "cambio_posicion", "pid": q2.id, "dato": nueva,
			"txt": "🔄 %s (%s) te pide jugar de %s. Dice que ahí rinde más y que en su puesto actual se aburre." % [q2.nombre, q2.pos_e, nueva],
			"opcion_a": "Probarlo de %s" % nueva, "opcion_b": "Su sitio es el de siempre"})
	## El patrocinador que exige aparecer en la rueda de prensa.
	pool.append({"id": "sponsor_rueda", "pid": "",
		"txt": "🥤 El patrocinador principal exige que menciones su bebida energética en la próxima rueda de prensa. Pagan %s por la frase." % _dinero(Eco.escalar(120000.0, rep)),
		"opcion_a": "Decir la frase", "opcion_b": "Yo hablo de fútbol"})
	## Apuestas ilegales.
	var sospechoso: Jugador = mio.plantilla[Azar.ent(0, mio.plantilla.size() - 1)]
	pool.append({"id": "apuestas", "pid": sospechoso.id,
		"txt": "🎲 La fiscalía investiga apuestas ilegales en tu liga y el nombre de %s aparece en unos mensajes. Todavía no hay cargos." % sospechoso.nombre,
		"opcion_a": "Apartarlo mientras se investiga", "opcion_b": "Presunción de inocencia"})
	## La huelga por sueldos impagos: solo con la caja en rojo.
	if mio.saldo < 0:
		pool.append({"id": "huelga_impagos", "pid": "",
			"txt": "✊ Con la caja en rojo, el plantel anuncia que no entrena hasta cobrar los atrasos. El sindicato ya habló con la prensa.",
			"opcion_a": "Pagar los atrasos ya", "opcion_b": "Negociar un calendario de pagos"})
	## El derbi con amenaza de seguridad.
	if rival != null and m != null and m.es_clasico(mio, rival):
		pool.append({"id": "derbi_amenaza", "pid": "",
			"txt": "🚨 La policía avisa de una amenaza creíble de enfrentamientos en el clásico contra %s. Recomienda reforzar el operativo." % rival.nombre,
			"opcion_a": "Reforzar la seguridad (%s)" % _dinero(Eco.escalar(90000.0, rep)), "opcion_b": "Operativo normal"})

## Arma la baraja de temas posibles. Los cuatro primeros están siempre; el resto
## solo aparece si el mundo da pie —que tu figura tenga un agente tiburón, que
## tengas partido esta semana, que haya un canterano con techo—, y eso es lo que
## hace que las decisiones parezcan salir de TU club y no de una lista.
func _pool(m: Mundo, mio: Club) -> Array[Dictionary]:
	var rep := float(mio.rep)
	var orden := mio.plantilla.duplicate()
	orden.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	var fig: Jugador = orden[0]

	var jovenes := mio.plantilla.filter(func(j: Jugador) -> bool: return j.edad <= 19)
	jovenes.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.pot > b.pot)
	var jov: Jugador = jovenes[0] if not jovenes.is_empty() else null

	var pool: Array[Dictionary] = [
		{"id": "aumento", "pid": fig.id,
			"txt": "💼 %s pide un aumento del 25%% a mitad de contrato y su agente ya filtró la molestia a la prensa." % fig.nombre,
			"opcion_a": "Ceder al aumento", "opcion_b": "Un contrato se respeta"},
		{"id": "benefico", "pid": "",
			"txt": "🤝 Invitan al club a un amistoso benéfico a mitad de semana. Suma prestigio, pero cansa piernas.",
			"opcion_a": "Aceptar el amistoso", "opcion_b": "Priorizar el descanso"},
		{"id": "gira", "pid": "",
			"txt": "✈️ Un empresario ofrece organizar una mini-gira por el norte: %s y el plantel vuelve afinado." % _dinero(Eco.escalar(300000.0, rep)),
			"opcion_a": "Pagar la gira", "opcion_b": "Rechazar"},
		{"id": "docu", "pid": "",
			"txt": "🎬 Una productora quiere grabar un documental del camarín. Pagan %s, pero las cámaras alborotan." % _dinero(Eco.escalar(600000.0, rep)),
			"opcion_a": "Aceptar cámaras", "opcion_b": "El camarín es sagrado"},
	]

	var ag := agente_de(fig)
	if String(ag.get("perfil", "")) == "tiburon":
		pool.append({"id": "agente", "pid": fig.id,
			"txt": "🦈 El agente %s ofreció a %s en Europa a tus espaldas. La prensa ya lo sabe." % [ag["nombre"], fig.nombre],
			"opcion_a": "Blindarlo (cláusula alta)", "opcion_b": "Escuchar ofertas"})

	var rival := _rival_de_la_semana(m, mio)
	if rival != null:
		pool.append({"id": "espia", "pid": "",
			"txt": "🕵️ Un contacto ofrece el parte médico filtrado de %s por %s." % [rival.nombre, _dinero(Eco.escalar(80000.0, rep))],
			"opcion_a": "Pagar el dato", "opcion_b": "No jugamos así"})

	pool.append({"id": "provoca", "pid": "",
		"txt": "🎙️ El DT rival te provocó en conferencia: \"ese equipo no tiene ideas\". Los periodistas esperan tu respuesta.",
		"opcion_a": "Responder con todo", "opcion_b": "Que hable la cancha"})
	pool.append({"id": "aniversario", "pid": "",
		"txt": "🎂 Se acerca el aniversario del club. Organizar la fiesta con partido de leyendas cuesta %s." % _dinero(Eco.escalar(150000.0, rep)),
		"opcion_a": "Tirar la casa por la ventana", "opcion_b": "Austeridad"})
	pool.append({"id": "huelgaBono", "pid": "",
		"txt": "✊ El plantel, encabezado por los referentes, pide un bono por la buena campaña.",
		"opcion_a": "Conceder el gesto", "opcion_b": "El sueldo ya es el bono"})

	if arbitro_polemico != "":
		pool.append({"id": "reclamo", "pid": "",
			"txt": "⚖️ La derrota con %s dejó jugadas polémicas. El directorio pregunta si reclamas formalmente a la asociación." % arbitro_polemico,
			"opcion_a": "Reclamo formal", "opcion_b": "Pasar la página"})

	## EL LOBBY INSTITUCIONAL CON ÁRBITROS. Complemento PROACTIVO de "reclamo"
	## -que es reactivo, después de un partido puntual-: aquí el directorio va a
	## limar el enojo ACUMULADO en el tribunal (`Federacion.enojo_arbitral`, el
	## mismo número que ya encarece cada apelación en `Federacion.apelar()`
	## y que la pestaña Federación ya mostraba sin que hubiera ninguna forma de
	## bajarlo). Solo aparece si hay algo de verdad que limar -sin enojo
	## acumulado, ir a "hacer relaciones públicas" no tendría nada que ofrecer-.
	if m.federacion != null and m.federacion.enojo_arbitral > 0:
		pool.append({"id": "lobby_arbitral", "pid": "",
			"txt": "🏛️ La comisión arbitral invita al directorio a un encuentro institucional antes de la próxima asamblea. Ir puede limar el enojo acumulado en el tribunal, pero si trasciende que fuiste a \"hablar\" con ellos, la prensa rival lo llama presión.",
			"opcion_a": "Asistir al encuentro", "opcion_b": "No mezclarse con el tribunal"})

	if jov != null and jov.pot >= 78 and not cesiones.has(jov.id):
		pool.append({"id": "prestamoJuv", "pid": jov.id,
			"txt": "📄 Un club grande ofrece %s por llevarse a préstamo un año a %s con minutos garantizados." % [_dinero(Eco.escalar(400000.0, rep)), jov.nombre],
			"opcion_a": "Aceptar la cesión", "opcion_b": "Se queda en casa"})

	pool.append({"id": "tv", "pid": "",
		"txt": "📺 Un programa deportivo ofrece %s por una semana de cámaras con el DT." % _dinero(Eco.escalar(200000.0, rep)),
		"opcion_a": "Aceptar la pauta", "opcion_b": "Bajo perfil"})

	if jov != null:
		pool.append({"id": "sub20", "pid": jov.id,
			"txt": "🇨🇱 La Sub-20 convoca a %s para una gira juvenil. Crece afuera, pero vuelve fundido." % jov.nombre,
			"opcion_a": "Liberarlo con orgullo", "opcion_b": "Retenerlo en el club"})

	## LOS TRES QUE PEDÍA EL DOCUMENTO DE INSTRUCCIONES Y NO ESTABAN.
	##
	## Los tres comparten una cosa: no se resuelven con dinero. Son las
	## situaciones donde el juego deja de ser una hoja de cálculo y te obliga a
	## decidir algo que no tiene una opción obviamente mejor.

	## EL RETIRO PREMATURO. Un titular de veintipocos lo deja por la religión,
	## la política o el negocio familiar. No se puede comprar la decisión: solo
	## se puede pedirle que espere a junio, y aun así puede decir que no.
	var maduros := mio.plantilla.filter(func(x: Jugador) -> bool:
		return x.edad >= 24 and x.edad <= 29 and x.ovr >= mio.rep - 6)
	if not maduros.is_empty():
		var quien: Jugador = maduros[Azar.ent(0, maduros.size() - 1)]
		var motivo := String(Azar.uno([
			"se va a entrenar a los niños de la escuelita de su barrio",
			"abre una escuela de fútbol en su ciudad",
			"vuelve al negocio familiar, que su padre ya no puede llevar",
			"dice que no disfruta desde hace dos años y no quiere seguir fingiendo",
		]))
		pool.append({"id": "retiro_joven", "pid": quien.id,
			"txt": "🚪 %s (%d años) te comunica que deja el fútbol profesional: %s. No pide traspaso, pide irse." % [
				quien.nombre, quien.edad, motivo],
			"opcion_a": "Pedirle que acabe la temporada", "opcion_b": "Dejarlo marchar hoy"})

	## EL VIRUS FIFA GEOPOLÍTICO. Tus internacionales se quedan atrapados fuera.
	## Es el único evento del juego que te quita jugadores sin lesión y sin
	## sanción, y por eso da tanta rabia: no hiciste nada mal.
	var fuera := mio.plantilla.filter(func(x: Jugador) -> bool: return x.pais != mio.pais)
	if fuera.size() >= 2:
		pool.append({"id": "virus_fifa", "pid": "",
			"txt": "✈️ Cierre de aeropuertos en plena fecha internacional: %d de tus internacionales están atrapados fuera y el derbi es el domingo. Puedes reclamar el aplazamiento o jugarlo con lo que haya." % fuera.size(),
			"opcion_a": "Reclamar el aplazamiento", "opcion_b": "Se juega con juveniles"})

	## LA VENGANZA DEL EXREPRESENTANTE. Filtra tus correos. No hay opción buena:
	## desmentir alimenta el tema y callar lo da por cierto.
	pool.append({"id": "filtracion_agente", "pid": "",
		"txt": "📧 Un representante al que dejaste fuera de una operación filtra correos tuyos criticando a la directiva y a dos jugadores del plantel. Están publicados desde esta mañana.",
		"opcion_a": "Desmentir en rueda de prensa", "opcion_b": "No dar explicaciones"})

	## LA OCUPACIÓN HOSTIL DE LA DIRECTIVA. Un multimillonario compra el club a
	## mitad de temporada y no pide permiso para nada: pone directores propios,
	## purga a tu gente de confianza e impone un fichaje franquicia. Aceptar
	## salva el puesto; plantarte deja el presupuesto intacto pero te dinamita
	## la confianza del directorio.
	pool.append({"id": "hostil", "pid": fig.id,
		"txt": "💰 OCUPACIÓN HOSTIL. Un multimillonario compra el club a mitad de temporada. Trae sus propios directores deportivos, exige echar a tu cuerpo técnico de confianza y te impone alinear siempre a %s para abrir mercado en Asia." % fig.nombre,
		"opcion_a": "Aceptar las condiciones", "opcion_b": "Plantarte y resistir"})

	## FICHAJE POR INTERESES COMERCIALES. La junta te obliga a alinear a un
	## recién llegado solo para vender camisetas en su continente. A diferencia
	## de la ocupación hostil, este pacto tiene fecha de vencimiento: se cae
	## solo al cerrar la temporada.
	pool.append({"id": "comercial", "pid": fig.id,
		"txt": "🏷️ FICHAJE POR INTERESES COMERCIALES. La junta te obliga a alinear como titular a %s, solo para vender camisetas en su continente. Si lo dejas en la reserva, te descuentan el bono comercial." % fig.nombre,
		"opcion_a": "Alinearlo siempre", "opcion_b": "Decidir yo el once"})

	## "FONDO DE INVERSIÓN BUITRE" YA EXISTE Y ES MÁS RICO QUE ESTA IDEA:
	## `Cesiones.presion_de_fondo()` -condicionado a que TÚ hayas vendido antes
	## un porcentaje del pase de un canterano con `vender_participacion()`- ya
	## presiona periódicamente para que lo vendas, y `Mundo.avanzar_semana()` ya
	## lo inyecta como decisión pendiente (ver `"fondo_presiona"` en
	## `resolver()`). Añadir aquí una segunda versión sin ese requisito
	## previo habría creado dos mecánicas de "fondo buitre" incompatibles
	## sobre el mismo nombre. Se revisó ANTES de escribir código -la lección de
	## habs/pie de esta misma sesión-, no después.

	_eventos_nuevos(pool, m, mio, fig, rival, rep)
	return pool


# ===========================================================================
#  LA DECISIÓN PENDIENTE
# ===========================================================================

## El sorteo semanal. Devuelve el evento creado, o vacío si esta semana no toca.
##
## Las tres puertas son las del HTML y cada una está por algo: no se acumulan
## decisiones (si ya hay una sin firmar no llega otra), no aparecen en la
## pretemporada ni en el cierre —semanas 3 a 38—, y solo un 5% de las semanas.
## Ese 5% es lo que hace que abrir el club y encontrarte un tema sea un
## acontecimiento; con un 30% sería una tarea semanal más.
func sortear_evento() -> Dictionary:
	var m := _mundo()
	if m == null:
		return {}
	if not pendiente.is_empty() or m.semana < 3 or m.semana > 38 or not Azar.suerte(0.05):
		return {}
	var mio := m.mi_club()
	if mio == null or mio.plantilla.size() < 5:
		return {}
	var opciones := _pool(m, mio)
	if opciones.is_empty():
		return {}
	pendiente = Azar.uno(opciones)
	evento_creado.emit(pendiente)
	noticia.emit("Decisión pendiente", "Hay un tema esperando tu firma en el despacho.")
	return pendiente

func _efecto(id: String, semanas: int, pid: String = "") -> void:
	efectos.append({"id": id, "semanas": semanas, "pid": pid})

func _jugador(c: Club, pid: String) -> Jugador:
	if pid == "" or c == null:
		return null
	for j in c.plantilla:
		if j.id == pid:
			return j
	return null

## Público desde que `Mundo` cobra la promesa de la rueda de prensa: ese cobro
## depende del RESULTADO, y el resultado solo lo conoce `Mundo`.
func mover_animo(d: int) -> void:
	animo = clampi(animo + d, 0, 100)
	humor_hinchada.emit(animo, funa)

func _fin_de_efecto(id: String, j: Jugador) -> void:
	match id:
		"vestuario_tenso":
			noticia.emit("El vestuario se calma", "Pasaron las semanas de tensión con el capitán. El grupo vuelve a remar.")
		"posicion_nueva":
			if j != null:
				j.cambiar_moral(5, "Prensa y declaraciones")
				noticia.emit("%s ya es de su nueva posición" % j.nombre, "Terminó de adaptarse y está feliz con el cambio.")
		"calendario_pagos":
			noticia.emit("Atrasos saldados", "Se cumplió el calendario de pagos. El plantel vuelve a entrenar sin carteles.")

func _aplicar_efectos(mio: Club) -> void:
	var siguen: Array = []
	for e: Dictionary in efectos:
		var j := _jugador(mio, String(e.get("pid", "")))
		match String(e["id"]):
			"vestuario_tenso":
				for x: Jugador in mio.plantilla:
					x.cambiar_moral(-1, "Prensa y declaraciones")
			"eco_viral":
				mover_animo(-1)
			"posicion_nueva":
				## Mientras se adapta, rinde un poco menos; al final, contento.
				if j != null:
					j.forma = clampi(j.forma - 1, 10, 99)
			"calendario_pagos":
				for x: Jugador in mio.plantilla:
					x.cambiar_moral(-2, "Prensa y declaraciones")
		e["semanas"] = int(e["semanas"]) - 1
		if int(e["semanas"]) > 0:
			siguen.append(e)
		else:
			_fin_de_efecto(String(e["id"]), j)
	efectos = siguen

func hay_evento() -> bool:
	return not pendiente.is_empty()

func _reputacion_de_decision(m: Mundo, id: String, si: bool) -> void:
	if m == null or m.roles == null or not REPUTACION_DE.has(id):
		return
	for r: Array in REPUTACION_DE[id]:
		var d: int = int(r[1]) if si else int(r[2])
		m.roles.anotar_reputacion(String(r[0]), d, String(r[3]))


## Saca a un futbolista del plantel porque lo deja. No es una venta: no entra un
## peso, y por eso el evento del retiro prematuro duele de verdad.
func _retirar_de_golpe(mio: Club, j: Jugador) -> void:
	var m := _mundo()
	if m != null and m.cantera != null:
		m.cantera.registrar_retiro(j, mio)
	mio.plantilla.erase(j)
