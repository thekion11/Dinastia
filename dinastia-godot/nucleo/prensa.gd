class_name Prensa
extends RefCounted
## La prensa y el despacho: lo que te preguntan y lo que te toca firmar.
##
## Es el sistema que convierte al entrenador en un personaje. El resto del juego
## te deja mover fichas; esto te obliga a decir cosas en voz alta y a cargar con
## lo que dijiste. Son dos mecanismos distintos que comparten materia prima —la
## opinión pública— y por eso viven juntos:
##
##   1. LA DECISIÓN PENDIENTE. Cada semana hay un 5% de que aparezca un tema en
##      tu mesa: un aumento, una gira, un documental, un agente que anda
##      ofreciendo a tu figura por Europa. Dos opciones, sin opción neutra.
##   2. LA RUEDA DE PRENSA. Después de tu partido, la mitad de las veces te
##      espera un micrófono con una pregunta incómoda y tres respuestas.
##
## LA GRACIA DE LA RUEDA no es qué respondes, es que además eliges CÓMO lo dices
## (`CUERPOS`), y las dos cosas se suman. La misma frase dicha con firmeza suma
## confianza y dicha con titubeo la hunde tres puntos y enciende a la prensa. Es
## lo que impide que exista una "respuesta correcta" que se aprende una vez.
##
## Las tres cifras de cada opción son, en este orden: moral del plantel,
## confianza de la directiva y porcentaje de socios. Vienen del HTML sin tocar.
##
## DÓNDE VIVE LO QUE TODAVÍA NO TIENE CASA. Varias decisiones dejan un rastro que
## en el HTML se guardaba en la variable global `G` y que aquí no tiene aún un
## sistema propio: el ánimo de la hinchada, la funa, las semanas de cámaras en el
## camarín, el dato robado del rival, el enojo del estamento arbitral. Todo eso
## se queda como campos públicos de esta clase en vez de perderse. Son estado de
## opinión pública, que es exactamente de lo que va este fichero, y el día que se
## porten el vestuario o los árbitros solo tienen que leerlos desde aquí: no hay
## que volver a tocar las decisiones.

## Lo que sale en el diario. La interfaz se engancha aquí; el simulador no sabe
## que hay una interfaz.
signal noticia(titulo: String, cuerpo: String)
## Dinero que entra o sale por una decisión, para el libro de movimientos.
signal movimiento(concepto: String, monto: int)
signal evento_creado(e: Dictionary)
signal evento_resuelto(id: String, opcion: String, titulo: String, cuerpo: String)
signal rueda_abierta(pregunta: String, opciones: Array)
signal rueda_respondida(titular: String, d_moral: int, d_confianza: int, d_socios: int)
signal humor_hinchada(animo: int, funa: int)
## El mentor comenta lo que pasa (plan maestro C1): un cambio de escudo, un
## partido con temporal... Lo pinta la pantalla con su cara.
signal mentor_dice(titulo: String, texto: String)

## --- LENGUAJE CORPORAL ------------------------------------------------------
## No importa solo lo que dices, sino cómo lo dices: si titubeas, los periodistas
## huelen sangre; si respondes con soberbia, los árbitros te miran distinto el
## domingo.
##
## La tabla (emoji, nombre, descripción) sale de `CUERPOS` en tablas.json, que es
## la misma del HTML. Los EFECTOS no están en esa tabla —en el HTML eran una
## cadena de if dentro de `responderPrensa`— y por eso se portan aquí abajo, en
## `_aplicar_cuerpo`.
const CUERPO_POR_DEFECTO := "firme"

var _ref: WeakRef

## --- LO QUE HAY SOBRE LA MESA ----------------------------------------------
## La decisión esperando tu firma, o vacío. Claves: id, pid (jugador implicado),
## txt, opcion_a, opcion_b.
var pendiente: Dictionary = {}
## La pregunta de la rueda, o vacío. Claves: pregunta, opciones[{txt, moral,
## confianza, socios}].
var entrevista: Dictionary = {}
var cuerpo: String = CUERPO_POR_DEFECTO

## --- LA OPINIÓN PÚBLICA -----------------------------------------------------
## Ánimo de la hinchada (0-100) y funa (0-100, cuánta gente pide tu cabeza).
var animo: int = 60
var funa: int = 0

## --- EL RASTRO QUE DEJAN LAS DECISIONES -------------------------------------
## Semanas que quedan de cámaras en el camarín tras firmar el documental o la
## pauta de televisión. Se descuenta en `semana()`.
var semanas_documental: int = 0
## El parte médico filtrado del próximo rival. Quien dirija el partido lo
## consume con `consumir_dato_del_rival()`: sale una sola vez, que es lo que
## pagaste.
var dato_del_rival: bool = false
## Prometiste ganar en conferencia. Presión extra en el próximo partido.
var presion_prometida: bool = false
## Cuántas veces has sonado soberbio ante el micrófono. El estamento arbitral
## lleva la cuenta.
var enojo_arbitral: int = 0
## Primas por objetivos encendidas en las normas del plantel.
var primas_activas: bool = false
## Tu reputación como entrenador, de 1 a 99. El HTML la tenía en `G.dt.rep`.
var rep_entrenador: int = 50
## Cláusulas de rescisión pactadas al blindar a un jugador: id -> monto. El
## mercado todavía no las mira, pero el número queda firmado y no se pierde.
var clausulas: Dictionary = {}
## Cesiones vivas: id de jugador -> {"de": club_id, "vuelve": año}. Las cierra
## `volver_de_cesion()` al cambiar de temporada.
var cesiones: Dictionary = {}
## El árbitro de la última derrota polémica, si la hubo. Lo escribe quien simule
## el partido llamando a `arbitro_dudoso()`; mientras esté puesto, el directorio
## puede preguntarte si reclamas.
var arbitro_polemico: String = ""
## El jugador cuyo pase dejaste correr: llegará una oferta grande por él.
var oferta_forzada: String = ""
## ¿Hay un abogado en el directorio? Abarata a la mitad la multa de un reclamo
## rechazado. En el HTML salía de `G.consejeros.leg`, que es un sistema aparte
## todavía sin portar; queda como interruptor para que la fórmula esté completa.
var abogado_en_directorio: bool = false
## "G.impuesto" del HTML: el pid de un jugador que TIENE que salir de titular
## -por la ocupación hostil del dueño o por el trato comercial del
## patrocinador-, o vacío si no hay ningún pacto vivo. Lo revisa
## `revisar_impuesto()` con el once real de cada partido.
var impuesto_pid: String = ""
## Año hasta el que aplica el pacto, o -1 si no tiene plazo -la ocupación
## hostil es así: el dueño no puso fecha de término-. El trato comercial sí
## vence al cerrar la temporada en la que se firmó.
var impuesto_hasta: int = -1

## Referencia DÉBIL al mundo, por la misma razón que en `Mercado`: el mundo
## guarda su prensa y la prensa necesita ver el mundo. Con dos referencias
## normales eso es un ciclo, y RefCounted no recoge ciclos: al terminar una
## partida se quedaría vivo un Mundo entero con sus 384 clubes dentro.
func _init(mundo: Mundo) -> void:
	_ref = weakref(mundo)

func _mundo() -> Mundo:
	return _ref.get_ref() as Mundo


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
			"se va a dedicar a la iglesia de su barrio",
			"se presenta a concejal en su ciudad",
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

## Hacia dónde quiere moverse cada demarcación (la vecina más ofensiva o la
## más natural para su perfil).
const _POSICION_DESEADA := {"DFC": "MCD", "LD": "CAD", "LI": "CAI", "CAD": "MD", "CAI": "MI",
	"MCD": "MC", "MC": "MCO", "MCO": "SD", "MD": "ED", "MI": "EI", "ED": "DC", "EI": "DC",
	"SD": "DC", "DC": "SD"}

## EFECTOS QUE DURAN (plan maestro B4). Cada uno: {id, semanas, pid}. Se aplican
## y descuentan en `semana()` y se guardan con la partida.
var efectos: Array = []

func _efecto(id: String, semanas: int, pid: String = "") -> void:
	efectos.append({"id": id, "semanas": semanas, "pid": pid})

func _aplicar_efectos(mio: Club) -> void:
	var siguen: Array = []
	for e: Dictionary in efectos:
		var j := _jugador(mio, String(e.get("pid", "")))
		match String(e["id"]):
			"vestuario_tenso":
				for x: Jugador in mio.plantilla:
					x.moral = clampi(x.moral - 1, 10, 99)
			"eco_viral":
				mover_animo(-1)
			"posicion_nueva":
				## Mientras se adapta, rinde un poco menos; al final, contento.
				if j != null:
					j.forma = clampi(j.forma - 1, 10, 99)
			"calendario_pagos":
				for x: Jugador in mio.plantilla:
					x.moral = clampi(x.moral - 2, 10, 99)
		e["semanas"] = int(e["semanas"]) - 1
		if int(e["semanas"]) > 0:
			siguen.append(e)
		else:
			_fin_de_efecto(String(e["id"]), j)
	efectos = siguen

func _fin_de_efecto(id: String, j: Jugador) -> void:
	match id:
		"vestuario_tenso":
			noticia.emit("El vestuario se calma", "Pasaron las semanas de tensión con el capitán. El grupo vuelve a remar.")
		"posicion_nueva":
			if j != null:
				j.moral = clampi(j.moral + 5, 10, 99)
				noticia.emit("%s ya es de su nueva posición" % j.nombre, "Terminó de adaptarse y está feliz con el cambio.")
		"calendario_pagos":
			noticia.emit("Atrasos saldados", "Se cumplió el calendario de pagos. El plantel vuelve a entrenar sin carteles.")

func hay_evento() -> bool:
	return not pendiente.is_empty()

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
					j.moral = clampi(j.moral - 8, 10, 99)
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
					x.moral = clampi(x.moral - 2, 10, 99)
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
				j.moral = clampi(j.moral + 10, 10, 99)
				salida = {"titulo": "Renovación mejorada",
					"cuerpo": "%s firma feliz. El camarín toma nota de quién paga." % j.nombre}
			else:
				j.moral = clampi(j.moral - 9, 10, 99)
				salida = {"titulo": "Portazo en la gerencia",
					"cuerpo": "Le recordaste que un contrato se respeta. %s entrena en silencio." % j.nombre}

		"benefico":
			if si:
				for x in mio.plantilla:
					x.fisico = clampi(x.fisico - 6, 10, 100)
					x.moral = clampi(x.moral + 3, 10, 99)
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
					x.moral = clampi(x.moral - 1, 10, 99)
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
						x.moral = clampi(x.moral + 3, 10, 99)
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
					x.moral = clampi(x.moral + 4, 10, 99)
				salida = {"titulo": "Gesto al camarín",
					"cuerpo": "Bono entregado y primas por objetivos activadas en las normas. El plantel responde en la cancha."}
			else:
				for x in mio.plantilla:
					x.moral = clampi(x.moral - 3, 10, 99)
				salida = {"titulo": "Sin bonos",
					"cuerpo": "\"El sueldo ya es el bono\". Caras largas en la práctica."}

		"tunel":
			if si:
				for x: Jugador in mio.plantilla:
					x.moral = clampi(x.moral + 3, 10, 99)
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
					j.moral = clampi(j.moral - 6, 10, 99)
					j.suspension = maxi(j.suspension, 1)
				_mover_funa(-5)
				if m != null and m.directiva != null:
					m.directiva.mover_confianza(2, "la sanción ejemplar")
				salida = {"titulo": "Sanción ejemplar",
					"cuerpo": "Un partido fuera y multa interna. La directiva aplaude; el jugador, no."}
			else:
				if j != null:
					j.moral = clampi(j.moral + 4, 10, 99)
				_mover_funa(10)
				_efecto("eco_viral", 2)
				salida = {"titulo": "Lo defiendes",
					"cuerpo": "\"Tiene derecho a una vida\". El vestuario lo agradece; las redes llevan dos semanas con el video."}

		"capitan":
			if si:
				for x: Jugador in mio.plantilla:
					x.moral = clampi(x.moral + 3, 10, 99)
				rep_entrenador = clampi(rep_entrenador - 2, 0, 100)
				salida = {"titulo": "Carga más liviana",
					"cuerpo": "Aflojas los entrenamientos una semana. El grupo sonríe; algún periodista dice que el capitán manda más que tú."}
			else:
				if j != null:
					j.moral = clampi(j.moral - 8, 10, 99)
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
				j.moral = clampi(j.moral + 6, 10, 99)
				_efecto("posicion_nueva", 3, j.id)
				salida = {"titulo": "%s, de %s" % [j.nombre, nueva],
					"cuerpo": "Ya figura como %s en su ficha. Unas semanas de adaptación y veremos si tenía razón." % nueva}
			else:
				if j != null:
					j.moral = clampi(j.moral - 6, 10, 99)
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
					j.moral = clampi(j.moral - 8, 10, 99)
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
						j.moral = clampi(j.moral + 6, 10, 99)

		"huelga_impagos":
			if si:
				_pagar(mio, -mio.masa_salarial() * 2, "Atrasos al plantel")
				for x: Jugador in mio.plantilla:
					x.moral = clampi(x.moral + 2, 10, 99)
				salida = {"titulo": "Atrasos pagados",
					"cuerpo": "Dos semanas de sueldo sobre la mesa. Se vuelve a entrenar mañana."}
			else:
				_efecto("calendario_pagos", 2)
				salida = {"titulo": "Calendario de pagos",
					"cuerpo": "Firman un acuerdo a dos semanas. Entrenan, pero con carteles en la valla."}

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
				j.moral = clampi(j.moral + 4, 10, 99)
				salida = {"titulo": "La joya se queda",
					"cuerpo": "%s agradece la confianza: \"quiero triunfar aquí\"." % j.nombre}

		"sub20":
			if j == null:
				pass
			elif si:
				## Vuelve fundido (físico a 45) pero con un punto más de techo:
				## el precio de crecer es una mala semana, no un mal año.
				j.fisico = 45
				j.moral = clampi(j.moral + 12, 10, 99)
				j.pot = clampi(j.pot + 1, j.ovr, 97)
				j.tasar()
				salida = {"titulo": "Orgullo de cantera",
					"cuerpo": "%s se fue con la Sub-20. Vuelve fundido pero más jugador." % j.nombre}
			else:
				j.moral = clampi(j.moral - 7, 10, 99)
				salida = {"titulo": "Retenido",
					"cuerpo": "%s se queda entrenando con el primer equipo, con cara larga." % j.nombre}

	pendiente = {}
	if String(salida["titulo"]) != "":
		noticia.emit(String(salida["titulo"]), String(salida["cuerpo"]))
	evento_resuelto.emit(String(e["id"]), op, String(salida["titulo"]), String(salida["cuerpo"]))
	return salida


# ===========================================================================
#  LA RUEDA DE PRENSA
# ===========================================================================

## Después de TU partido, la mitad de las veces te espera el micrófono.
##
## `penales` es la tanda, si la hubo, en el orden [local, visita]: sin ella una
## eliminatoria ganada desde los once metros se leería como un empate y te
## preguntarían por la falta de gol después de pasar de ronda.
func sortear_rueda(p: Partido, penales: Array = []) -> Dictionary:
	var m := _mundo()
	if m == null or p == null:
		return {}
	## Se tira el dado ANTES de mirar si ya hay entrevista abierta, igual que en
	## el HTML: mantiene el consumo de azar idéntico jornada a jornada.
	var toca := Azar.suerte(0.5)
	if not toca or not entrevista.is_empty():
		return {}
	var mio := m.mi_club()
	if mio == null or (p.local != mio and p.visita != mio):
		return {}

	var soy_local := p.local == mio
	var gf := p.goles_local if soy_local else p.goles_visita
	var gc := p.goles_visita if soy_local else p.goles_local
	var hubo_penales := penales.size() >= 2
	var pf := int(penales[0]) if hubo_penales else 0
	var pc := int(penales[1]) if hubo_penales else 0
	if hubo_penales and not soy_local:
		var t := pf
		pf = pc
		pc = t

	var gane := gf > gc or (hubo_penales and pf > pc)
	var empate := gf == gc and not hubo_penales
	return abrir_rueda(gane, empate)

## Abre una rueda con el guion que toca. Se puede llamar directa desde una prueba
## o desde un modo sin partido de por medio.
func abrir_rueda(gane: bool, empate: bool) -> Dictionary:
	var guion: Array = _GANE if gane else (_EMPATE if empate else _PERDI)
	entrevista = (Azar.uno(guion) as Dictionary).duplicate(true)
	cuerpo = CUERPO_POR_DEFECTO
	## LO QUE ES NOTICIA MANDA sobre la pregunta de siempre (C1): si cambiaste
	## el escudo o la camiseta, te preguntan por eso; si se jugó con temporal,
	## calor o altura, por el tiempo. El sorteo de arriba se hace igual, así
	## que el consumo de `Azar` no cambia.
	if cambio_identidad != "":
		entrevista = _pregunta_identidad(cambio_identidad)
		cambio_identidad = ""
	elif Clima.es_extremo(clima_ultimo) and _hash_de(str(_fecha()) + "clima") % 2 == 0:
		entrevista = _pregunta_clima(clima_ultimo, gane, empate)
	_poner_periodista(gane, empate)
	rueda_abierta.emit(String(entrevista["pregunta"]), entrevista["opciones"])
	return entrevista

func hay_rueda() -> bool:
	return not entrevista.is_empty()

## Elige el lenguaje corporal antes de responder. Devuelve la descripción de esa
## postura para poder enseñarla en pantalla.
func fijar_cuerpo(k: String) -> String:
	var t: Dictionary = Datos.tabla("CUERPOS")
	if t == null or not t.has(k):
		return ""
	cuerpo = k
	return String(t[k][2])

## Las cinco posturas, tal como las pinta la interfaz: clave -> [emoji, nombre,
## descripción].
func cuerpos() -> Dictionary:
	var t: Dictionary = Datos.tabla("CUERPOS")
	return t if t != null else {}

## Responde la pregunta `i`. Devuelve el resumen de lo que movió, o vacío si no
## había rueda abierta.
##
## Los tres efectos van a sitios distintos y por eso una respuesta nunca es
## redonda: la moral la cobra el plantel, la confianza la directiva y los socios
## la taquilla del mes que viene. Quedar bien con el vestuario puede costarte el
## despacho.
##
## `segundos` (B5): lo que tardaste en contestar, medido por la pantalla. Más de
## `TITUBEO_SEG` y la sala lo nota -"los periodistas huelen sangre"-. Con -1 (las
## pruebas, o quien no mida) no cuenta.
##
## Si la respuesta deja la puerta abierta -evasiva, titubeo, o soberbia ante
## quien vive del titular-, el MISMO periodista repregunta: la rueda sigue
## abierta con la repregunta en `entrevista` y el resultado trae "sigue": true.
func responder(i: int, segundos: float = -1.0) -> Dictionary:
	if entrevista.is_empty():
		return {}
	var opciones: Array = entrevista["opciones"]
	if i < 0 or i >= opciones.size():
		return {}
	var m := _mundo()
	var mio: Club = m.mi_club() if m != null else null
	var o: Dictionary = opciones[i]

	var d_moral := int(o["moral"])
	var d_conf := int(o["confianza"])
	var d_socios := int(o["socios"])
	var extra := _aplicar_cuerpo(d_moral, d_conf, d_socios)
	d_moral = int(extra["moral"])
	d_conf = int(extra["confianza"])
	d_socios = int(extra["socios"])
	var tono := String(o.get("tono", "calma"))
	var titubeo := segundos >= TITUBEO_SEG
	var de_tono := _aplicar_tono(tono, titubeo)
	d_moral += int(de_tono["moral"])
	d_conf += int(de_tono["confianza"])
	extra["texto"] = String(extra["texto"]) + String(de_tono["texto"])

	## EL VOCERO AMORTIGUA. Si habla otro por ti, la rueda deja de ser tuya: ni
	## te luces ni te hundes. Es la contrapartida que el HTML prometia en el
	## texto del boton y no cobraba en ninguna cuenta.
	## EL DESGASTE DEL ENTRENADOR. Con la cabeza fundida lo que dices sale peor,
	## y esa es la unica consecuencia de quemarse: no te echa nadie, trabajas peor.
	if m != null and m.roles != null and m.roles.quemado():
		var f_des := m.roles.factor_desgaste()
		d_moral = int(round(float(d_moral) * f_des))
		d_conf = int(round(float(d_conf) * f_des))
	if not vocero.is_empty():
		d_moral = int(round(float(d_moral) * AMORTIGUA_VOCERO))
		d_conf = int(round(float(d_conf) * AMORTIGUA_VOCERO))
		d_socios = int(round(float(d_socios) * AMORTIGUA_VOCERO))

	if mio != null:
		for j in mio.plantilla:
			j.moral = clampi(j.moral + d_moral, 10, 99)
		## Los socios se mueven en PORCENTAJE, no en número: una declaración
		## afortunada le suma más gente a un club grande que a uno chico, que es
		## lo que corresponde. El suelo de 500 impide que una mala racha deje al
		## club literalmente sin masa social.
		mio.socios = clampi(int(round(float(mio.socios) * (1.0 + float(d_socios) / 100.0))), 500, 300000)
	if m != null and m.directiva != null and d_conf != 0:
		m.directiva.mover_confianza(d_conf, "rueda de prensa")

	var titular := String(o["txt"])
	## Quien da la cara. Con vocero el titular no lleva tu nombre, y esa es
	## justo la otra mitad del trato: menos desgaste, menos control.
	var quien := "🎙 Rueda de prensa"
	if not vocero.is_empty():
		quien = "🎙 Rueda de prensa · habla %s" % String(vocero.get("nombre", ""))
	var per := String(entrevista.get("periodista", ""))
	var paso := int(entrevista.get("paso", 0))
	_recordar(per, titular, tono)
	var sigue := paso == 0 and _toca_repreguntar(per, tono, titubeo)
	if sigue:
		entrevista = _repregunta(per, titular, tono, titubeo)
	else:
		_preparar_titular(per, titular, tono)
		entrevista = {}
		cuerpo = CUERPO_POR_DEFECTO
	noticia.emit(quien, "«%s».%s" % [titular, String(extra["texto"])])
	rueda_respondida.emit(titular, d_moral, d_conf, d_socios)
	return {"titular": titular, "moral": d_moral, "confianza": d_conf,
		"socios": d_socios, "extra": String(extra["texto"]), "tono": tono,
		"titubeo": titubeo, "sigue": sigue}

## Cómo lo dijiste, sumado a lo que dijiste.
##
## Cada postura tiene su moneda de cambio y ninguna es gratis: el firme es sólido
## pero anodino, el cercano compra hinchada a costa de no decir nada, el soberbio
## te hace grande ante la directiva y te pone a los árbitros en contra, y el
## dubitativo es un desastre completo. El seco es la salida para cuando no hay
## nada bueno que decir.
func _aplicar_cuerpo(dm: int, dc: int, ds: int) -> Dictionary:
	var texto := ""
	match cuerpo:
		"firme":
			dc += 1
			dm += 1
			texto = " Te viste sólido."
		"dubitativo":
			dc -= 3
			dm -= 1
			_mover_funa(Azar.ent(4, 10))
			texto = " Titubeaste al responder y la prensa lo notó: mañana te preguntan por tu continuidad."
		"soberbio":
			dc += 2
			ds += 1
			enojo_arbitral += 1
			texto = " Sonaste soberbio: el estamento arbitral tomó nota para el próximo partido."
		"cercano":
			dm += 2
			ds += 1
			_mover_funa(-Azar.ent(2, 6))
			texto = " Caíste bien: la hinchada agradece el tono."
		"seco":
			dc -= 1
			dm += 1
			texto = " Corto y sin regalar titulares."
	return {"moral": dm, "confianza": dc, "socios": ds, "texto": texto}


# ===========================================================================
#  LA RUEDA A FONDO (25-9-2026, plan maestro B5)
# ===========================================================================
## Pedido: *"mejoras en las entrevistas"*. Hasta hoy la rueda era UNA pregunta de
## "Prensa" sin cara, tres botones y a casa. Ahora:
##   - pregunta un PERIODISTA concreto de los cinco de `PERIODISTAS`, y cada uno
##     trata distinto lo que dices (el crítico no te perdona la soberbia, el
##     sensacionalista vive de ella);
##   - cada respuesta tiene un TONO -calma, soberbia o evasiva- con su propio
##     efecto, aparte de las cifras de la opción;
##   - hay MEMORIA: el periodista recuerda tu última frase y, si fue soberbia y
##     hoy perdiste, te la devuelve;
##   - hay REPREGUNTA cuando dejas la puerta abierta;
##   - cuenta el TIEMPO: si tardas más de `TITUBEO_SEG`, se nota;
##   - al día siguiente sale el TITULAR citando tu frase, escrito a su manera;
##   - se puede responder con TEXTO LIBRE: un clasificador local por palabras
##     clave decide el tono (sin IA en línea: ver ROADMAP, B5);
##   - y al terminar el partido dirigido, la entrevista corta A PIE DE CAMPO.
## Nada de esto consume `Azar`: quién pregunta y cómo sale del hash de la fecha.

const TITUBEO_SEG := 10.0

## clave de periodista -> {frase, tono, fecha (anio*100+semana)}.
var memoria: Dictionary = {}
## La portada que saldrá con tu frase, o vacío. Claves: t, c, tipo.
var titular_pendiente: Dictionary = {}
## La entrevista a pie de campo abierta, o vacío (no se guarda: dura segundos).
var pie: Dictionary = {}

func periodista_de(clave: String) -> Array:
	for f: Array in PERIODISTAS:
		if String(f[0]) == clave:
			return f
	return PERIODISTAS[2]

func _fecha() -> int:
	var m := _mundo()
	return (m.anio * 100 + m.semana) if m != null else 0

## Quién pregunta hoy. Tras una derrota, uno de cada tres días le toca al
## crítico, que es el que más ganas tiene.
func _poner_periodista(gane: bool, empate: bool) -> void:
	var h := _hash_de("%d|%s" % [_fecha(), String(entrevista.get("pregunta", ""))])
	var f: Array = PERIODISTAS[h % PERIODISTAS.size()]
	if not gane and not empate and h % 3 == 0:
		f = periodista_de("ibarra")
	var clave := String(f[0])
	entrevista["periodista"] = clave
	entrevista["quien"] = "%s · %s" % [String(f[1]), String(f[2])]
	entrevista["perfil"] = String(f[3])
	entrevista["paso"] = 0
	## La pregunta ya no la hace "Prensa": la hace él.
	var q := String(entrevista.get("pregunta", ""))
	if q.begins_with("Prensa: "):
		q = q.substr(8)
	var mem: Dictionary = memoria.get(clave, {})
	if not mem.is_empty() and _fecha() - int(mem.get("fecha", 0)) >= 1:
		if String(mem.get("tono", "")) == "soberbia" and not gane:
			## LA FRASE QUE VUELVE. Lo dijiste subido; hoy toca tragártelo.
			q = "'Hace poco dijo «%s». Hoy no ganaron. ¿Se arrepiente de esa frase?'" % String(mem["frase"])
			entrevista["opciones"] = [
				{"txt": "Me equivoqué en el tono; el trabajo sigue", "moral": 1, "confianza": 1, "socios": 1, "tono": "calma"},
				{"txt": "No vine a hablar del pasado", "moral": -1, "confianza": 0, "socios": -1, "tono": "evasiva"},
				{"txt": "Lo sostengo: al final de la temporada hablamos", "moral": 1, "confianza": -1, "socios": 0, "tono": "soberbia"},
			]
			entrevista["memoria"] = true
		elif String(mem.get("tono", "")) == "evasiva":
			q = "'La última vez no me contestó; a ver hoy. %s" % q.trim_prefix("'")
			entrevista["memoria"] = true
	entrevista["pregunta"] = q

## El tono, aparte de las cifras de la opción. Mueve la relación con quien
## pregunta, y la soberbia la apunta el estamento arbitral.
func _aplicar_tono(tono: String, titubeo: bool) -> Dictionary:
	var per := String(entrevista.get("periodista", ""))
	var perfil := String(entrevista.get("perfil", ""))
	var dm := 0
	var dc := 0
	var texto := ""
	match tono:
		"calma":
			_mover_relacion(per, 2)
			funa = maxi(0, funa - 1)
		"soberbia":
			## El cuerpo "soberbio" ya lo apunta en `_aplicar_cuerpo`: dos veces
			## por la misma frase sería cobrarla doble.
			if cuerpo != "soberbio":
				enojo_arbitral += 1
			_mover_relacion(per, 3 if perfil == "sensacionalista" else -3)
			dm += 1
			texto = " La frase se va a repetir toda la semana."
		"evasiva":
			_mover_relacion(per, -2)
			_mover_funa(1)
			texto = " No contestaste, y eso también es una respuesta."
	if titubeo:
		dc -= 1
		_mover_funa(2)
		texto += " Tardaste en contestar: en la sala se notó."
	return {"moral": dm, "confianza": dc, "texto": texto}

func _mover_relacion(clave: String, d: int) -> void:
	if clave == "":
		return
	relaciones[clave] = clampi(relacion_con(clave) + d, 0, 100)

func _recordar(clave: String, frase: String, tono: String) -> void:
	if clave == "":
		return
	memoria[clave] = {"frase": frase.substr(0, 90), "tono": tono, "fecha": _fecha()}

## Repregunta si dejaste la puerta abierta. Con portavoz no: él cierra el tema.
func _toca_repreguntar(clave: String, tono: String, titubeo: bool) -> bool:
	if clave == "" or not vocero.is_empty():
		return false
	var perfil := String(periodista_de(clave)[3])
	return titubeo or tono == "evasiva" or (tono == "soberbia" and perfil in ["crítico", "sensacionalista"])

func _repregunta(clave: String, frase: String, tono: String, titubeo: bool) -> Dictionary:
	var f := periodista_de(clave)
	var q := ""
	var ops: Array = []
	if titubeo:
		q = "'Se ha tomado su tiempo para contestar. ¿Duda usted de su propio proyecto?'"
		ops = [
			{"txt": "No dudo: hay un plan y el plantel lo conoce", "moral": 1, "confianza": 2, "socios": 0, "tono": "calma"},
			{"txt": "No voy a entrar en eso", "moral": 0, "confianza": -2, "socios": -1, "tono": "evasiva"},
			{"txt": "Dudar es cosa de ustedes", "moral": 1, "confianza": -1, "socios": 0, "tono": "soberbia"},
		]
	elif tono == "evasiva":
		q = "'Con todo respeto, eso no es una respuesta. Se lo pregunto otra vez.'"
		ops = [
			{"txt": "Tiene razón: se lo digo claro, confío en este grupo", "moral": 1, "confianza": 1, "socios": 1, "tono": "calma"},
			{"txt": "Ya respondí. Siguiente pregunta", "moral": -1, "confianza": -1, "socios": -1, "tono": "evasiva"},
			{"txt": "Las respuestas las doy en la cancha", "moral": 2, "confianza": 0, "socios": 0, "tono": "soberbia"},
		]
	else:
		q = "'«%s». ¿No teme que esa frase se le vuelva en contra?'" % frase
		ops = [
			{"txt": "Lo matizo: hablo de ambición, no de desprecio", "moral": 0, "confianza": 1, "socios": 1, "tono": "calma"},
			{"txt": "No tengo nada más que añadir", "moral": 0, "confianza": -1, "socios": -1, "tono": "evasiva"},
			{"txt": "Lo digo y lo sostengo", "moral": 2, "confianza": 0, "socios": 1, "tono": "soberbia"},
		]
	return {"pregunta": q, "opciones": ops, "periodista": clave, "perfil": String(f[3]),
		"quien": "%s · %s (repregunta)" % [String(f[1]), String(f[2])], "paso": 1}

## La portada de mañana, escrita a la manera de quien preguntó.
func _preparar_titular(clave: String, frase: String, tono: String) -> void:
	if clave == "":
		return
	var f := periodista_de(clave)
	var perfil := String(f[3])
	var cita := "«%s»" % frase.substr(0, 70)
	var t := ""
	match perfil:
		"sensacionalista":
			t = {"soberbia": "%s: el DT enciende la polémica" % cita, "evasiva": "El DT esquiva y la sala se queda con las ganas"}.get(tono, "%s, la frase del día" % cita)
		"crítico":
			t = {"soberbia": "Soberbia en la sala: %s" % cita, "evasiva": "Sin respuestas: el DT se escondió tras el micrófono"}.get(tono, "%s. Palabras; faltan hechos" % cita)
		"aliado":
			t = {"soberbia": "Un DT con carácter: %s" % cita, "evasiva": "El DT prefirió la prudencia"}.get(tono, "%s: el DT pone la cara" % cita)
		"táctico":
			t = "%s: lo que hay detrás de la idea del DT" % cita
		_:
			t = "El DT: %s" % cita
	var tipo: String = {"calma": "bien", "soberbia": "neutro", "evasiva": "mal"}.get(tono, "neutro")
	titular_pendiente = {"t": t, "c": "Lo firma %s en %s." % [String(f[1]), String(f[2])], "tipo": tipo, "medio": String(f[2])}

## Sale al día siguiente de la rueda (la llama `semana()` y, si la hay, la
## pantalla al pasar el día). Devuelve el titular, o vacío si no había.
# --- el escudo, la camiseta y el tiempo (C1) ----------------------------------
## La última identidad conocida del club: {esc, kit, col}. Vacía = aún no se
## tomó la foto (la primera semana solo la toma, no da noticia).
var identidad: Dictionary = {}
## "escudo", "camiseta" o "escudo y camiseta" hasta que la rueda lo pregunte.
var cambio_identidad: String = ""
## El tiempo de tu último partido, para la rueda. Lo escribe `Mundo`.
var clima_ultimo: Dictionary = {}
## De qué competición es la rueda abierta ("liga" por defecto) y sus clubes,
## para que la pared de la sala muestre los escudos que tocan. No se guardan:
## la rueda se contesta en la misma sesión.
var competicion_rueda: String = "liga"
var clubes_rueda: Array = []

static func firma_identidad(c: Club) -> Dictionary:
	return {
		"esc": "|".join([c.esc_color1, c.esc_color2, c.esc_forma, c.esc_patron, c.esc_simbolo, c.esc_especial]),
		"kit": "|".join([c.kit_color1, c.kit_color2, c.kit_estilo]),
		"col": "|".join([c.color1, c.color2]),
	}

## Cambiar el escudo o la camiseta es de las decisiones más sensibles de un
## club: la gente se lo toma como algo suyo. Se revisa una vez por semana;
## devuelve lo que cambió ("" si nada).
func revisar_identidad(c: Club) -> String:
	if c == null:
		return ""
	var ahora := firma_identidad(c)
	if identidad.is_empty():
		identidad = ahora
		return ""
	var escudo: bool = ahora["esc"] != identidad["esc"] or ahora["col"] != identidad["col"]
	var camiseta: bool = ahora["kit"] != identidad["kit"] or ahora["col"] != identidad["col"]
	identidad = ahora
	if not escudo and not camiseta:
		return ""
	var que := "escudo y camiseta" if escudo and camiseta else ("escudo" if escudo else "camiseta")
	cambio_identidad = que
	## La afición se divide; cuánto, depende del día: un hash, no `Azar`.
	var h := _hash_de("%s|%d|%s" % [c.id, _fecha(), que])
	var d := (h % 11) - 6            ## de -6 a +4: tocar la identidad suele doler
	mover_animo(d)
	var reaccion := "La hinchada lo celebra en redes." if d > 0 else ("Hay división en la grada." if d > -3 else "Buena parte de la hinchada lo rechaza: «con la historia no se juega».")
	var tit := "El club cambia su %s" % que
	guardar_portada(tit.to_upper(), reaccion, "bien" if d > 0 else "mal", {"img": "escudo", "sub": reaccion, "nueva": true})
	noticia.emit("🗞️ " + tit, reaccion)
	mentor_dice.emit("Sobre el nuevo %s" % que,
		"Esto se va a comentar toda la semana. Prepárate: en la próxima rueda de prensa te van a preguntar por el %s, y lo que digas pesa tanto como el cambio." % que)
	return que

func _pregunta_identidad(que: String) -> Dictionary:
	return {"pregunta": "Prensa: 'El club estrena %s. Hay hinchas molestos: ¿por qué tocar algo tan sagrado?'" % que, "opciones": [
		{"txt": "Respetamos la historia; esto la pone al día", "moral": 0, "confianza": 1, "socios": 1, "tono": "calma"},
		{"txt": "El que no lo entienda, ya lo entenderá", "moral": 0, "confianza": 1, "socios": -2, "tono": "soberbia"},
		{"txt": "Eso es cosa del departamento de marketing", "moral": 0, "confianza": -1, "socios": -1, "tono": "evasiva"},
	]}

func _pregunta_clima(info: Dictionary, gane: bool, empate: bool) -> Dictionary:
	var que := String(info.get("texto", "el tiempo")).to_lower()
	var q := "Prensa: '¿Cuánto influyó el tiempo (%s) en el resultado?'" % que
	if gane:
		q = "Prensa: 'Con %s, ¿fue un triunfo de carácter más que de fútbol?'" % que
	return {"pregunta": q, "opciones": [
		{"txt": "Es igual para los dos: no es excusa", "moral": 1, "confianza": 1, "socios": 0, "tono": "calma"},
		{"txt": "Así no se puede jugar al fútbol", "moral": -1 if not gane else 0, "confianza": -1, "socios": 0, "tono": "soberbia"},
		{"txt": "Prefiero hablar del partido", "moral": 0, "confianza": 0, "socios": -1, "tono": "evasiva"},
	]}

func publicar_titular_pendiente() -> String:
	if titular_pendiente.is_empty():
		return ""
	var t := String(titular_pendiente["t"])
	guardar_portada(t, String(titular_pendiente["c"]), String(titular_pendiente["tipo"]),
		{"img": "dt", "medio": String(titular_pendiente.get("medio", "")), "sub": String(titular_pendiente["c"])})
	noticia.emit("🗞️ " + t, String(titular_pendiente["c"]))
	titular_pendiente = {}
	return t

# --- texto libre -------------------------------------------------------------
## Lo que no es respuesta: cortar, derivar, "sin comentarios".
const _EVASIVAS := ["sin comentarios", "no voy a", "siguiente", "no hablo", "no tengo nada",
	"ya dije", "ya lo dije", "pregúntenle", "preguntenle", "pregunten a", "otro día", "no corresponde"]
## Lo que suena subido.
const _SOBERBIAS := ["somos los mejores", "que se preparen", "nadie nos", "ustedes no", "no saben",
	"vamos a ganar", "ganaremos", "campeones", "obvio", "yo decido", "mi decisión", "ridícul",
	"tendencios", "mentira", "no me importa", "lo sostengo", "cállense", "callense"]

## El tono de una frase escrita. Menos de ocho letras tampoco es una respuesta.
func clasificar_respuesta(texto: String) -> String:
	var t := texto.strip_edges().to_lower()
	if t.length() < 8:
		return "evasiva"
	for k: String in _SOBERBIAS:
		if t.contains(k):
			return "soberbia"
	for k: String in _EVASIVAS:
		if t.contains(k):
			return "evasiva"
	return "calma"

## La opción que sale de un texto libre: el tono pone la base y lo que nombras
## la matiza -hablar de la gente suma socios, del grupo suma moral, de los
## árbitros los pone en tu contra-.
func opcion_de_texto(texto: String) -> Dictionary:
	var tono := clasificar_respuesta(texto)
	var base: Dictionary = {"calma": [1, 1, 0], "soberbia": [2, 1, 1], "evasiva": [-1, 0, -1]}
	var v: Array = base[tono]
	var t := texto.to_lower()
	var dm := int(v[0])
	var dc := int(v[1])
	var ds := int(v[2])
	if t.contains("hinch") or t.contains("afici") or t.contains("la gente") or t.contains("cantera") or t.contains("juvenil"):
		ds += 1
	if t.contains("plantel") or t.contains("grupo") or t.contains("jugadores") or t.contains("equipo"):
		dm += 1
	if (t.contains("directiv") or t.contains("directorio") or t.contains("presidente")) and tono != "calma":
		dc -= 1
	return {"txt": texto.strip_edges().substr(0, 120), "moral": dm, "confianza": dc, "socios": ds,
		"tono": tono, "arbitros": t.contains("árbitr") or t.contains("arbitr")}

func responder_texto(texto: String, segundos: float = -1.0) -> Dictionary:
	if entrevista.is_empty() or texto.strip_edges() == "":
		return {}
	var o := opcion_de_texto(texto)
	## Hablar de los árbitros en una rueda nunca sale gratis.
	if bool(o["arbitros"]):
		enojo_arbitral += 1
	(entrevista["opciones"] as Array).append(o)
	return responder((entrevista["opciones"] as Array).size() - 1, segundos)

# --- a pie de campo ------------------------------------------------------------
## La entrevista corta al terminar el partido que dirigiste: una pregunta y
## tres salidas. Mueve poco -ánimo de la hinchada y moral- porque es caliente y
## todos lo saben; lo que cuenta es la frase, que va al registro.
func pie_de_campo(gane: bool, empate: bool, gf: int, gc: int) -> Dictionary:
	var f := periodista_de("navarrete")
	var q := ""
	var ops: Array = []
	if gane:
		q = "¡Victoria por %d-%d! ¿Qué le dice a la gente que vino hoy?" % [gf, gc]
		ops = [
			{"txt": "Gracias a ellos: este triunfo es de todos", "tono": "calma", "animo": 2, "moral": 1},
			{"txt": "Que se vayan acostumbrando", "tono": "soberbia", "animo": 1, "moral": 1},
			{"txt": "Ahora toca descansar", "tono": "evasiva", "animo": 0, "moral": 0},
		]
	elif empate:
		q = "Empate %d-%d. ¿Sabe a poco?" % [gf, gc]
		ops = [
			{"txt": "Sumamos; el equipo dio la cara", "tono": "calma", "animo": 1, "moral": 1},
			{"txt": "El árbitro nos quitó el partido", "tono": "soberbia", "animo": 1, "moral": 0, "arbitros": true},
			{"txt": "Lo analizaremos en frío", "tono": "evasiva", "animo": 0, "moral": 0},
		]
	else:
		q = "Derrota %d-%d, duro golpe. ¿Qué pasó hoy?" % [gf, gc]
		ops = [
			{"txt": "Lo asumo yo: hoy no estuvimos", "tono": "calma", "animo": 1, "moral": 1},
			{"txt": "Los jugadores tendrán que dar explicaciones", "tono": "soberbia", "animo": 0, "moral": -2},
			{"txt": "No es momento de hablar", "tono": "evasiva", "animo": -1, "moral": 0},
		]
	pie = {"pregunta": q, "opciones": ops, "quien": "%s · %s, a pie de campo" % [String(f[1]), String(f[2])]}
	return pie

# --- al paso: los medios nuevos (C6) -------------------------------------------
## Pedido: *"entrevistas en medios de comunicación más nuevos y sin tanta
## preparación, más naturales"*. Un streamer a la salida del entrenamiento, un
## podcast en el aeropuerto, el canal de un hincha en la puerta del estadio: una
## pregunta que no esperas, casi nunca de fútbol. Lo que dices mueve SEGUIDORES
## (el alcance del club en redes) y un poco el ánimo; nada de confianza de la
## directiva: nadie en el palco ve esos directos. Una vez cada ~8 semanas, por
## hash (sin `Azar`).
const MEDIOS_NUEVOS := [
	["Kike en Directo", "streamer", "a la salida del entrenamiento"],
	["El Vestuario Pod", "podcast", "en el aeropuerto"],
	["Hincha TV", "canal de un hincha", "en la puerta del estadio"],
	["Fútbol en 60 segundos", "vídeos cortos", "en el aparcamiento"],
	["La Previa Live", "streaming", "en el supermercado"],
]
const PREGUNTAS_AL_PASO := [
	["¿Qué música suena en el vestuario?", [
		["Lo elige el capitán, y no siempre acierta", "calma", 900, 1],
		["Silencio: aquí se viene a trabajar", "soberbia", -300, 0],
		["Eso pregúntaselo al utilero", "evasiva", 400, 0]]],
	["¿Quién es el peor bailarín del plantel?", [
		["El portero, sin discusión", "calma", 1200, 1],
		["Yo no bailo y ellos tampoco deberían", "soberbia", -200, 0],
		["No voy a buscarme problemas", "evasiva", 300, 0]]],
	["Te vimos haciendo la compra: ¿el entrenador cocina?", [
		["Cocino fatal, pero lo intento", "calma", 1000, 1],
		["Mi vida privada es privada", "soberbia", -400, -1],
		["Solo compraba agua", "evasiva", 200, 0]]],
	["¿Contestas los mensajes de los hinchas?", [
		["Los leo todos, hasta los que me insultan", "calma", 1500, 2],
		["No tengo tiempo para eso", "soberbia", -800, -2],
		["A veces", "evasiva", 200, 0]]],
	["¿A qué jugador del plantel te llevarías a una isla desierta?", [
		["Al capitán: sabría organizarnos", "calma", 900, 1],
		["A ninguno, me iría solo", "soberbia", -300, 0],
		["A todos, que ninguno se enfade", "evasiva", 600, 0]]],
	["Dicen que eres supersticioso: ¿cierto?", [
		["La misma corbata desde hace diez partidos", "calma", 1300, 1],
		["El fútbol es trabajo, no suerte", "soberbia", 0, 0],
		["Sin comentarios", "evasiva", 100, 0]]],
]
## La entrevista al paso de esta semana, lista para enseñar, o vacío.
var al_paso: Dictionary = {}

func revisar_al_paso(anio: int, sem: int) -> Dictionary:
	if not al_paso.is_empty() or not pie.is_empty():
		return {}
	var h := _hash_de("alpaso|%d|%d" % [anio, sem])
	if h % 8 != 0:
		return {}
	var medio: Array = MEDIOS_NUEVOS[(h / 8) % MEDIOS_NUEVOS.size()]
	var q: Array = PREGUNTAS_AL_PASO[(h / 64) % PREGUNTAS_AL_PASO.size()]
	var ops: Array = []
	for o: Array in q[1]:
		ops.append({"txt": String(o[0]), "tono": String(o[1]), "seguidores": int(o[2]), "animo": int(o[3]), "moral": 0})
	al_paso = {"pregunta": String(q[0]), "opciones": ops,
		"quien": "%s · %s, %s" % [String(medio[0]), String(medio[1]), String(medio[2])], "rotulo": "📱 Al paso"}
	return al_paso

## Pasa la entrevista al paso a la "entrevista abierta" que contesta la
## pantalla (la misma de pie de campo).
func abrir_al_paso() -> Dictionary:
	if al_paso.is_empty():
		return {}
	pie = al_paso
	al_paso = {}
	return pie

## `i` = -1: pasas de largo ante la cámara.
func responder_pie(i: int) -> Dictionary:
	if pie.is_empty():
		return {}
	var ops: Array = pie["opciones"]
	pie = {}
	if i < 0 or i >= ops.size():
		mover_animo(-1)
		noticia.emit("🎤 A pie de campo", "Pasaste de largo ante la cámara. La imagen, sin palabras, se vio igual.")
		return {"titular": "", "tono": "evasiva"}
	var o: Dictionary = ops[i]
	mover_animo(int(o.get("animo", 0)))
	## Los medios nuevos mueven seguidores, no confianza (C6).
	if o.has("seguidores"):
		seguidores = maxi(0, seguidores + int(o["seguidores"]))
	var dm := int(o.get("moral", 0))
	var m := _mundo()
	var mio: Club = m.mi_club() if m != null else null
	if dm != 0 and mio != null:
		for j in mio.plantilla:
			j.moral = clampi(j.moral + dm, 10, 99)
	if bool(o.get("arbitros", false)):
		enojo_arbitral += 1
	var frase := String(o["txt"])
	var donde := "🎤 A pie de campo"
	if o.has("seguidores"):
		donde = "📱 Al paso"
	noticia.emit(donde, "«%s»." % frase + (" %+d seguidores." % int(o["seguidores"]) if o.has("seguidores") else ""))
	return {"titular": frase, "tono": String(o["tono"])}


# ===========================================================================
#  LOS GUIONES DE LA RUEDA
# ===========================================================================
## Tres barajas según cómo acabó el partido. Las preguntas de la derrota son las
## que de verdad muerden —te preguntan por tu puesto y por los silbidos— y por
## eso son las únicas donde una respuesta puede restar tres puntos de golpe.
##
## Las cifras de cada opción son [moral del plantel, confianza de la directiva,
## % de socios] y están portadas del HTML sin retocar. La regla que las ordena:
## la respuesta cómoda da poco, la valiente da más y la soberbia o esquiva resta.

const _GANE := [
	{"pregunta": "Prensa: '¿Es este el triunfo que confirma la levantada?'", "opciones": [
		{"txt": "Paso a paso, con humildad", "moral": 2, "confianza": 1, "socios": 0, "tono": "calma"},
		{"txt": "Sí: que se preparen los de arriba", "moral": 4, "confianza": 2, "socios": 3, "tono": "soberbia"},
		{"txt": "Las conclusiones las saco en privado", "moral": -1, "confianza": 1, "socios": -1, "tono": "evasiva"},
	]},
	{"pregunta": "Prensa: 'La gente pide más minutos para los juveniles, ¿los verá?'", "opciones": [
		{"txt": "Los chicos empujan fuerte, tendrán su chance", "moral": 3, "confianza": 0, "socios": 2, "tono": "calma"},
		{"txt": "Juega el que está mejor, sin regalos", "moral": 1, "confianza": 2, "socios": -1, "tono": "calma"},
		{"txt": "Esa decisión es solo mía", "moral": -2, "confianza": 1, "socios": -2, "tono": "soberbia"},
	]},
]

const _EMPATE := [
	{"pregunta": "Prensa: '¿Sabe a poco este empate?'", "opciones": [
		{"txt": "Sumar siempre sirve", "moral": 1, "confianza": 0, "socios": 0, "tono": "calma"},
		{"txt": "Sí, merecimos más y lo dije en el camarín", "moral": 2, "confianza": 1, "socios": 1, "tono": "calma"},
		{"txt": "Prefiero no evaluar en caliente", "moral": -1, "confianza": 0, "socios": -1, "tono": "evasiva"},
	]},
	{"pregunta": "Prensa: '¿Le preocupa la falta de gol?'", "opciones": [
		{"txt": "Las ocasiones están, el gol va a llegar", "moral": 2, "confianza": 0, "socios": 0, "tono": "calma"},
		{"txt": "Trabajaremos definición toda la semana", "moral": 1, "confianza": 1, "socios": 0, "tono": "calma"},
		{"txt": "Pregunta tendenciosa. Siguiente", "moral": -3, "confianza": 0, "socios": -2, "tono": "soberbia"},
	]},
]

const _PERDI := [
	{"pregunta": "Prensa: '¿Está en riesgo su puesto tras esta derrota?'", "opciones": [
		{"txt": "Respondo con trabajo, no con excusas", "moral": 1, "confianza": 2, "socios": 0, "tono": "calma"},
		{"txt": "El plantel está conmigo, saldremos juntos", "moral": 3, "confianza": 0, "socios": 1, "tono": "calma"},
		{"txt": "Eso pregúntenselo al directorio", "moral": -2, "confianza": -2, "socios": -1, "tono": "evasiva"},
	]},
	{"pregunta": "Prensa: 'Los hinchas silbaron al equipo, ¿los entiende?'", "opciones": [
		{"txt": "Tienen razón: hoy no los representamos", "moral": 2, "confianza": 1, "socios": 2, "tono": "calma"},
		{"txt": "El apoyo se necesita en las malas", "moral": -1, "confianza": 0, "socios": -3, "tono": "soberbia"},
		{"txt": "No escuché silbidos", "moral": -3, "confianza": -1, "socios": -2, "tono": "evasiva"},
	]},
]


# ===========================================================================
#  EL PULSO SEMANAL Y LOS GANCHOS PARA EL RESTO DEL JUEGO
# ===========================================================================

## Lo que hay que llamar una vez por semana, junto al resto del calendario.
##
## Aparte de descontar las cámaras, aquí está la deriva del ánimo de la hinchada
## hacia su punto de reposo (55) y los dos sucesos que dispara cuando se va a un
## extremo: el banderazo en la práctica y los lienzos contra el club. Son la
## prueba visible de que la opinión pública existe; sin ellos el número sería
## decorativo.
func semana() -> void:
	var m := _mundo()
	var mio: Club = m.mi_club() if m != null else null
	## LAS CÁMARAS EN EL VESTUARIO. `hay_camaras()` estaba escrita y no la leía
	## nadie: aceptabas el documental, cobrabas, y las cámaras no hacían nada.
	## Ahora sí: al plantel le incomoda que lo graben, y ese es el precio de la
	## plata. Es poco por semana, pero seis semanas seguidas se notan.
	if mio != null and not efectos.is_empty():
		_aplicar_efectos(mio)
	publicar_titular_pendiente()
	revisar_identidad(mio)
	if m != null:
		revisar_al_paso(m.anio, m.semana)
	if semanas_documental > 0:
		semanas_documental -= 1
		if mio != null:
			for j in mio.plantilla:
				if j.rasgo == "fragil" or j.rasgo == "cerebro":
					j.moral = clampi(j.moral - 1, 10, 99)
	## EL PUNTO DE REPOSO NO ES 55 FIJO: lo mueve el AMBIENTE del estadio -la
	## forma del recinto, el techo, la pista de atletismo, las banderas- y las
	## luces y pantallas del estadio premium. `EstadioPropio.ambiente()` llevaba
	## meses calculado, enseñado en la pantalla del estadio y sin efecto ninguno:
	## elegir una caldera de 20.000 en vez de un óvalo de 30.000 no cambiaba nada.
	var reposo := 55.0
	if m != null:
		if m.estadio != null:
			reposo += float(m.estadio.ambiente())
		if m.comercial != null:
			reposo += float(m.comercial.bono_ambiente())
	animo = clampi(int(round(float(animo) + (reposo - float(animo)) * 0.03)), 0, 100)
	if mio == null:
		return
	if animo > 82 and Azar.suerte(0.09):
		for j in mio.plantilla:
			j.moral = clampi(j.moral + 2, 10, 99)
		noticia.emit("Banderazo en la práctica",
			"Cientos de hinchas coparon el entrenamiento con bombos y lienzos de aliento. El plantel se agranda.")
	elif animo < 22 and Azar.suerte(0.14):
		for j in mio.plantilla:
			j.moral = clampi(j.moral - 2, 10, 99)
		noticia.emit("Lienzos contra el club",
			"Amanecieron rayados frente al estadio: 'jugadores sin sangre'. Semana tensa en la ciudad deportiva.")

## Lo llama quien simule el partido cuando el arbitraje fue un escándalo y
## perdiste. Mientras esté puesto, el directorio puede preguntarte si reclamas.
func arbitro_dudoso(nombre: String) -> void:
	arbitro_polemico = Nombres.visible(nombre)

## El parte médico robado sale UNA vez: es lo que compraste.
func consumir_dato_del_rival() -> bool:
	var s := dato_del_rival
	dato_del_rival = false
	return s

## La promesa hecha en conferencia se cobra en el próximo partido y se apaga.
func consumir_presion() -> bool:
	var s := presion_prometida
	presion_prometida = false
	return s

## ¿Hay cámaras en el camarín esta semana? Seis semanas después del documental,
## dos después de la pauta de televisión.
func hay_camaras() -> bool:
	return semanas_documental > 0

## Devuelve a los cedidos cuyo año se cumplió. Se llama al cambiar de temporada.
##
## Sin esto, aceptar la cesión sería vender al chico para siempre y el jugador se
## enteraría un año tarde: el texto promete que "vuelve hecho jugador".
func volver_de_cesion(anio: int) -> Array[Jugador]:
	var m := _mundo()
	var vueltos: Array[Jugador] = []
	if m == null:
		return vueltos
	for pid: String in cesiones.keys():
		var d: Dictionary = cesiones[pid]
		if anio < int(d["vuelve"]):
			continue
		var casa: Club = m.clubes.get(String(d["de"]))
		if casa == null:
			cesiones.erase(pid)
			continue
		for c: Club in m.clubes.values():
			var j := _jugador(c, pid)
			if j == null:
				continue
			c.soltar(j)
			casa.fichar(j)
			vueltos.append(j)
			noticia.emit("Vuelve de la cesión",
				"%s termina su préstamo y se reincorpora a la pretemporada." % j.nombre)
			break
		cesiones.erase(pid)
	return vueltos


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

func _jugador(c: Club, pid: String) -> Jugador:
	if pid == "" or c == null:
		return null
	for j in c.plantilla:
		if j.id == pid:
			return j
	return null

## Contra quién juegas esta semana, si es que juegas. Sirve para el soborno del
## parte médico: sin partido a la vista no hay a quién espiar.
func _rival_de_la_semana(m: Mundo, mio: Club) -> Club:
	var par := m.proximo_partido()
	if par.size() != 2:
		par = m.partido_de_copa()
	if par.size() != 2:
		return null
	return par[1] if par[0] == mio else par[0]


## Saca a un futbolista del plantel porque lo deja. No es una venta: no entra un
## peso, y por eso el evento del retiro prematuro duele de verdad.
func _retirar_de_golpe(mio: Club, j: Jugador) -> void:
	var m := _mundo()
	if m != null and m.cantera != null:
		m.cantera.registrar_retiro(j, mio)
	mio.plantilla.erase(j)


## "if(G.impuesto&&G.impuesto.pid){...}" del HTML: el trato -de la ocupación
## hostil o del patrocinador- que obliga a alinear a un jugador concreto. Se
## revisa TRAS cada partido tuyo, con el once que de verdad saliste a jugar
## -`Mundo._avisar_a_la_directiva()` es quien lo llama, justo al lado de la
## revisión del cupo juvenil, que sigue el mismo patrón-.
func revisar_impuesto(mio: Club, xi: Array[Jugador], anio: int) -> void:
	if impuesto_pid == "":
		return
	if impuesto_hasta >= 0 and anio > impuesto_hasta:
		impuesto_pid = ""
		impuesto_hasta = -1
		noticia.emit("Se acabó el compromiso comercial",
			"El acuerdo que te obligaba a alinear a un jugador concreto llegó a su fin. Vuelves a elegir el once sin condiciones.")
		return
	var imp := _jugador(mio, impuesto_pid)
	if imp == null:
		impuesto_pid = ""
		impuesto_hasta = -1
		return
	var jugo := xi.any(func(x: Jugador) -> bool: return x.id == imp.id)
	if jugo or imp.lesion > 0 or imp.suspension > 0:
		return
	var cobro := Eco.escalar(140000.0, float(mio.rep))
	_pagar(mio, -cobro, "Penalización del patrocinador: %s fuera del once" % imp.nombre)
	var m := _mundo()
	if m != null and m.directiva != null:
		m.directiva.mover_confianza(-3, "%s fuera del once pese al pacto" % imp.nombre)
	noticia.emit("El patrocinador te lo cobra",
		"Dejaste a %s fuera del once y el acuerdo comercial exigía que jugara. Descuento de %s y una llamada incómoda del directorio." % [imp.nombre, _dinero(cobro)])


## El precio de un viaje largo: los que vinieron de fuera llegan sin piernas.
func _fatigar_por_viaje(mio: Club) -> void:
	var m := _mundo()
	for j: Jugador in mio.plantilla:
		if j.pais == mio.pais:
			continue
		var golpe := Azar.ent(4, 9)
		## Las instalaciones y el preparador fisico amortiguan el viaje: es para
		## lo que sirven, y sin esto seria un castigo que no se puede prevenir.
		## "fisico" y no "pf": `Staff.PUESTOS` llama así al preparador físico. Con
		## "pf" -la clave del HTML, `G.staff.pf`- el nivel salía siempre 0 y el
		## preparador no aliviaba ningún viaje, sin un solo error.
		if m != null and m.staff != null:
			golpe -= m.staff.nivel("fisico")
		j.fisico = clampi(j.fisico - maxi(1, golpe), 10, 100)

func _pagar(c: Club, monto: int, concepto: String) -> void:
	if monto == 0:
		return
	c.mover_saldo(monto)
	movimiento.emit(concepto, monto)

## Público desde que `Mundo` cobra la promesa de la rueda de prensa: ese cobro
## depende del RESULTADO, y el resultado solo lo conoce `Mundo`.
func mover_animo(d: int) -> void:
	animo = clampi(animo + d, 0, 100)
	humor_hinchada.emit(animo, funa)

## La misma subida/bajada, para quien esté fuera de esta clase -por ejemplo,
## fichar un embajador del club sube el ánimo, y ese evento vive en Directiva-.
func sumar_animo(d: int) -> void:
	mover_animo(d)

## El HTML sumaba funa sin acotar por arriba (solo la restaba con clamp), así que
## podía pasar de 100 y quedarse ahí para siempre. Aquí se acota por los dos
## lados: es una escala 0-100 y todo lo que la lea espera esa escala.
## EL MEDIATICO APAGA EL FUEGO AL DOBLE DE VELOCIDAD.
##
## `Entrenamiento.factor_apagar_funa()` devolvia un 2,0 que no leia nadie: se
## podia gastar un punto del arbol en «Mediatico» y la funa bajaba exactamente
## igual de despacio. Solo se aplica cuando la funa BAJA -apagar un incendio es
## lo que la habilidad promete-; encenderlo cuesta lo mismo para todos.
func _mover_funa(d: int) -> void:
	if d < 0:
		var m := _mundo()
		if m != null and m.entrenamiento != null:
			d = int(round(float(d) * m.entrenamiento.factor_apagar_funa()))
	funa = clampi(funa + d, 0, 100)
	humor_hinchada.emit(animo, funa)

## La cesión de un canterano. Las tres condiciones son las del HTML: solo hasta
## los 21, solo si no está ya cedido, y solo si te queda plantel para jugar
## (más de 18). El destino es un club que no sea mejor que el tuyo por más de
## cuatro puntos de reputación: a un chico se le presta para que juegue, no para
## que se siente en un banco mejor.
func _ceder(m: Mundo, mio: Club, j: Jugador) -> bool:
	if j.edad > 21 or cesiones.has(j.id) or mio.plantilla.size() <= 18:
		return false
	var candidatos: Array[Club] = []
	for c: Club in m.clubes.values():
		if c.id != mio.id and c.rep <= mio.rep + 4:
			candidatos.append(c)
	if candidatos.is_empty():
		return false
	var destino: Club = Azar.uno(candidatos)
	cesiones[j.id] = {"de": mio.id, "vuelve": m.anio + 1}
	mio.soltar(j)
	destino.fichar(j)
	return true

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

# ---------------------------------------------------------------------------
#  LAS REDES (`vSocial()`)
# ---------------------------------------------------------------------------
#
# El termómetro de lo que se dice de ti fuera del estadio. `funa` y `animo` ya
# existían y se movían solos; lo que faltaba era la VOZ: los mensajes concretos
# que la gente escribe, que es lo que convierte un número en una sensación.
#
# El feed no se inventa de la nada: cada mensaje sale de algo que pasó de
# verdad -un resultado, un fichaje, una funa- y por eso se escribe desde fuera
# con `publicar()`, no aquí dentro con un sorteo.

## Los mensajes, el más reciente primero. Se recortan a cincuenta: nadie baja
## más de eso y guardar la historia entera engorda el fichero de partida.
const POSTS_MAX := 50
var posts: Array = []

## Seguidores. Suben con los títulos y los buenos resultados, bajan con la funa.
var seguidores: int = 1200

## Los perfiles que hablan. Cada uno escribe distinto, que es lo que hace que el
## feed se lea como gente y no como un generador.
const VOCES := [
	["hincha", "@hincha_de_siempre", "🧣"],
	["analista", "@tacticoDeSofa", "📊"],
	["periodista", "@prensa_deportiva", "🎙️"],
	["troll", "@elQueSabeMas", "🔥"],
]

func publicar(texto: String, voz: String = "hincha", empuje: float = 1.0) -> void:
	var perfil: Array = VOCES[0]
	for v: Array in VOCES:
		if String(v[0]) == voz:
			perfil = v
	## Los "me gusta" salen de los seguidores, no de un número al azar: si el
	## club crece, sus publicaciones crecen con él, y eso es lo que hace que
	## subir de seguidores signifique algo.
	##
	## Y NO SE USA `Azar` AQUÍ. `Azar` es el generador determinista del que
	## depende la simulación entera: consumirlo para un adorno desplaza la
	## secuencia y cambia los partidos. Pasó de verdad -el banco cazó que el
	## prestigio del entrenador dejaba de moverse en diez jornadas- y es la clase
	## de fallo que no se encuentra mirando el código, porque el código de al
	## lado está bien. Las cifras salen de un hash del propio texto: estables,
	## distintas entre mensajes, y sin tocar el azar del juego.
	var h := 0
	for i in texto.length():
		h = (h * 31 + texto.unicode_at(i)) & 0x7FFFFFFF
	var base := maxi(10, int(float(seguidores) * 0.02 * empuje))
	posts.push_front({
		"usuario": String(perfil[1]), "avatar": String(perfil[2]),
		"texto": texto, "likes": base + h % maxi(1, base * 2),
		"rt": int(base / 4) + (h >> 7) % maxi(1, base),
	})
	while posts.size() > POSTS_MAX:
		posts.pop_back()

## El pulso semanal de las redes. Los seguidores siguen al ánimo con inercia:
## se gana audiencia despacio y se pierde deprisa, como en la vida.
func semana_redes() -> void:
	## Tampoco aquí se toca `Azar`: ver la nota de `publicar()`. La variación
	## sale de la propia semana, que ya es distinta cada vez.
	var d := int(round(float(animo - 55) * 2.4)) - funa * 3
	var m := _mundo()
	var ruido := ((m.semana * 37 + m.anio * 11) % 130) - 40 if m != null else 0
	seguidores = maxi(200, seguidores + d + ruido)
	## EL COMMUNITY MANAGER. Suma un porcentaje fijo todas las semanas, pase lo
	## que pase en la cancha: es el unico crecimiento de seguidores que no depende
	## de ganar, y por eso vale la pena pagarlo en un club chico.
	if m != null and m.staff != null:
		var empuje := m.staff.empuje_redes()
		if empuje > 0.0:
			seguidores += int(round(float(seguidores) * empuje))

## Las tres respuestas del gabinete. Devuelve el texto de lo que pasó.
##
## No hay una buena: apoyar calma la funa pero gasta credibilidad, callar no
## cuesta nada hoy y deja que la bola crezca, y contestar puede apagar el fuego
## o echarle gasolina. Es la misma lógica que la charla del entretiempo.
func comunicado(tipo: String) -> String:
	match tipo:
		"apoyo":
			funa = maxi(0, funa - Azar.ent(6, 12))
			mover_animo(Azar.ent(2, 5))
			publicar("El club cierra filas con el entrenador. Veremos cuánto dura.", "periodista", 1.4)
			return "Comunicado de apoyo: la funa baja y la hinchada lo agradece, pero has gastado un cartucho."
		"silencio":
			## Callar es gratis HOY. La funa sigue su curso.
			publicar("Ni una palabra desde el club. El silencio también dice cosas.", "analista", 1.0)
			return "Silencio de prensa: no gastas nada, pero la bola sigue rodando sola."
		"contestar":
			## La jugada de riesgo: la mitad de las veces apaga el fuego y la
			## otra mitad lo dobla.
			if Azar.suerte(0.5):
				funa = maxi(0, funa - Azar.ent(10, 20))
				mover_animo(Azar.ent(3, 7))
				publicar("Respuesta directa y sin anestesia. La hinchada lo celebra.", "hincha", 2.0)
				return "Contestaste y salió bien: la funa se desinfla y el vestuario lo nota."
			funa = mini(100, funa + Azar.ent(8, 16))
			mover_animo(-Azar.ent(2, 6))
			publicar("Le contestaron a la prensa y ahora hay tres titulares más.", "troll", 2.2)
			return "Contestaste y salió mal: ahora hay tres titulares donde había uno."
	return ""

# ---------------------------------------------------------------------------
#  LOS PERIODISTAS Y LOS MEDIOS PROPIOS (`vPrensa()`)
# ---------------------------------------------------------------------------
#
# `funa` y `animo` miden el ruido; esto le pone CARA. Son cinco personas con
# nombre, medio y una manera de tratarte, y la relación con cada una se gana o
# se pierde. El crítico va a por ti desde el día uno y el aliado te suaviza las
# derrotas: eso convierte "la prensa" en gente concreta.
#
# Los medios PROPIOS son la respuesta a eso: si no te gusta cómo lo cuentan,
# cuéntalo tú. Cuestan una vez y rentan cada mes.

## clave, nombre, medio, perfil, cómo te trata.
const PERIODISTAS := [
	["ibarra", "P. Ibarra", "El Pelotazo", "crítico",
		"Va a por ti desde el día uno. Cualquier tropiezo es portada."],
	["solis", "C. Solís", "Radio Tribuna", "aliado",
		"Te tiene simpatía: suaviza las derrotas si le das material."],
	["urrutia", "F. Urrutia", "Diario La Banda", "neutral",
		"Cuenta lo que pasa, sin bando."],
	["navarrete", "M. Navarrete", "Canal Deportes", "sensacionalista",
		"Vive del titular grande, sea verdad o no."],
	["pizarro", "L. Pizarro", "Podcast Fuera de Juego", "táctico",
		"Analiza de verdad. Si le explicas tu idea, la defiende."],
]

## clave, nombre, coste, renta mensual, qué es.
const MEDIOS_PROPIOS := [
	["podcast", "Podcast oficial del club", 260000, 18000,
		"Contenido semanal: fideliza socios y da voz a tu versión"],
	["revista", "Revista del club", 180000, 9000,
		"A la vieja usanza: llega a los socios de siempre"],
	["docu", "Productora de documentales", 640000, 31000,
		"Series tras bambalinas que se venden fuera"],
	["stream", "Canal de streaming propio", 900000, 52000,
		"Partidos de cantera y contenido de pago: suscriptores todo el año"],
]

## clave de periodista -> relación de 0 a 100. Vacío significa "todos en 50".
var relaciones: Dictionary = {}
## claves de los medios comprados.
var medios: Dictionary = {}

func relacion_con(clave: String) -> int:
	return int(relaciones.get(clave, 50))

## Atender a un periodista: le das material y mejora la relación. Uno por
## semana; si atendieras a los cinco no habría que elegir a quién cuidar.
func atender(clave: String) -> String:
	if relaciones.get("_semana_atendido", -1) == _semana_actual():
		return "ya has atendido a alguien esta semana"
	relaciones["_semana_atendido"] = _semana_actual()
	relaciones[clave] = clampi(relacion_con(clave) + Azar.ent(5, 12), 0, 100)
	## Un periodista contento escribe mejor de ti, y eso baja el ruido.
	if relacion_con(clave) >= 70:
		funa = maxi(0, funa - 2)
	return "Le das media hora y algo de material. La relación mejora."

func _semana_actual() -> int:
	var m := _mundo()
	return m.semana if m != null else 0

## Cuánto amortigua la prensa amiga. Es la media de las relaciones, convertida
## en un factor: con toda la prensa a favor, la funa pesa un 30% menos.
func amortiguador_prensa() -> float:
	if relaciones.is_empty():
		return 1.0
	var s := 0
	var n := 0
	for f: Array in PERIODISTAS:
		s += relacion_con(String(f[0]))
		n += 1
	if n == 0:
		return 1.0
	var media := float(s) / float(n)
	var f := 1.3 - media / 100.0 * 0.6
	## LA SALA DE PRENSA DEL CLUB TAMBIEN AMORTIGUA. `Instalaciones.imagen_en_prensa()`
	## devolvia el nivel de la sala y no lo leia nadie: se podia subir la obra al
	## cinco y el ruido pegaba exactamente igual. Un 4% por nivel.
	var m := _mundo()
	if m != null and m.obras != null:
		f -= float(m.obras.imagen_en_prensa()) * 0.04
	return clampf(f, 0.55, 1.3)

func tiene_medio(clave: String) -> bool:
	return medios.has(clave)

func comprar_medio(clave: String, c: Club) -> String:
	if tiene_medio(clave):
		return "ya lo tienes"
	for f: Array in MEDIOS_PROPIOS:
		if String(f[0]) != clave:
			continue
		var coste := Eco.escalar(float(f[2]), float(c.rep))
		if c.saldo < coste:
			return "cuesta %s y no hay caja" % Cesiones.dinero(coste)
		c.mover_saldo(-coste)
		medios[clave] = true
		return ""
	return "ese medio no existe"

## Lo que rentan los medios propios cada mes.
func renta_medios(c: Club) -> int:
	var n := 0
	for f: Array in MEDIOS_PROPIOS:
		if tiene_medio(String(f[0])):
			n += Eco.escalar(float(f[3]), float(c.rep))
	return n

# ---------------------------------------------------------------------------
#  LA MESA DE DEBATE Y EL RANKING DE ENTRENADORES (`vDebate()`)
# ---------------------------------------------------------------------------
#
# "No cambia un resultado, pero sí lo que el directorio escucha en el desayuno"
# —lo dice la propia pantalla del HTML—. Cinco tertulianos que miran el mismo
# club desde cinco sitios distintos, y un escalafón que premia rendir POR
# ENCIMA de lo que tu club permite, no acabar arriba.

const TERTULIANOS := [
	["exdt", "Ex entrenador", "Habla de pizarra y desconfía de los jóvenes"],
	["periodista", "Periodista de toda la vida", "Le importa el club, no tú"],
	["exjugador", "Ex jugador ídolo", "Defiende al vestuario por encima de todo"],
	["datos", "Analista de datos", "Solo cree en los números"],
	["polemista", "Polemista", "Vive de encender el fuego"],
]

## Qué dice cada uno esta semana. Depende del ESTADO REAL del club -puesto,
## racha, ánimo-, no de un sorteo: si dijeran cosas al azar, se notaría a la
## segunda semana y dejarían de leerse.
func mesa_de_debate() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	var m := _mundo()
	if m == null or m.mi_club() == null:
		return salida
	var c := m.mi_club()
	var liga := m.liga_de(c)
	var puesto := 0
	var n := 0
	if liga != null:
		for f: Dictionary in liga.tabla():
			n += 1
			if f["club"] == c:
				puesto = n
	var arriba := puesto > 0 and puesto <= 4
	var abajo := puesto > 0 and puesto > n - 4
	var jovenes := 0
	for j in c.plantilla:
		if j.edad <= 21 and j.partidos > 3:
			jovenes += 1
	for f2: Array in TERTULIANOS:
		var frase := ""
		match String(f2[0]):
			"exdt":
				frase = ("Con esos chicos no se gana nada; ya se verá en marzo." if jovenes >= 3
					else "Ordenado atrás. Eso es lo primero, lo demás viene solo.")
			"periodista":
				frase = ("El club está donde tiene que estar. El entrenador es lo de menos." if arriba
					else "Aquí ha habido épocas peores, y también se salió de ellas.")
			"exjugador":
				frase = ("Ese vestuario está vivo. Se nota que corren por alguien." if animo >= 60
					else "Al vestuario lo veo solo. Y cuando el vestuario está solo, pasa lo que pasa.")
			"datos":
				frase = ("Los números lo sostienen: genera más de lo que concede." if arriba
					else "Los números no engañan, y ahora mismo no dan.")
			"polemista":
				frase = ("Que alguien explique qué es esto, porque yo no lo entiendo." if (abajo or funa > 45)
					else "Ganan, sí. Pero que no se relajen, que aquí se olvida rápido.")
		salida.append({"nombre": String(f2[1]), "perfil": String(f2[2]), "frase": frase})
	return salida

## El escalafón de entrenadores del país. La nota premia rendir POR ENCIMA de lo
## que el club permite: un séptimo con el decimoquinto presupuesto vale más que
## un tercero con el primero. Es la única métrica del juego que mide al
## entrenador y no al club.
func ranking_entrenadores() -> Array[Dictionary]:
	var m := _mundo()
	var salida: Array[Dictionary] = []
	if m == null or m.mi_club() == null:
		return salida
	var mio := m.mi_club()
	for l: Liga in m.ligas:
		if l.pais != mio.pais:
			continue
		## El puesto REAL en la tabla contra el puesto ESPERADO por reputación.
		var por_rep := l.clubes.duplicate()
		por_rep.sort_custom(func(a: Club, b: Club) -> bool: return a.rep > b.rep)
		var esperado := {}
		for i in por_rep.size():
			esperado[(por_rep[i] as Club).id] = i + 1
		var puesto := 0
		for f: Dictionary in l.tabla():
			puesto += 1
			var c: Club = f["club"]
			var esp := int(esperado.get(c.id, puesto))
			var nota := clampi(60 + (esp - puesto) * 7 + int(round(float(int(f["pts"])) - float(int(f["pj"])) * 1.3) * 1.6), 10, 99)
			salida.append({
				"club": c, "nota": nota, "puesto": puesto, "esperado": esp,
				"mio": c == mio,
			})
	salida.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["nota"]) > int(b["nota"]))
	return salida

# ===========================================================================
#  EL VOCERO, LA TELEVISIÓN, LAS PORTADAS Y EL AÑO CONTADO (`vPrensa()`)
# ===========================================================================
#
# Lo que faltaba de la sala de prensa. Las cuatro piezas se parecen poco entre
# sí y comparten una cosa: ninguna cambia un resultado, y las cuatro cambian
# cómo se cuenta lo que pasó.

## Quién habla por ti: {"id", "nombre"}. Vacío significa que das tú la cara.
var vocero: Dictionary = {}

## Cuánto amortigua el vocero los vaivenes de la rueda de prensa. El HTML lo
## prometía en el texto -"menos desgaste para ti, pero también menos control
## sobre el mensaje"- y no lo cumplía en ninguna cuenta. Aquí sí: con vocero, la
## rueda mueve la mitad, para bien y para mal. Es exactamente el trato.
const AMORTIGUA_VOCERO := 0.5

## Nombrar o quitar al vocero. Solo un capitán o un líder de vestuario sirve:
## poner a hablar al último fichaje de dieciocho años no lo aguantaría nadie.
func nombrar_vocero(mio: Club) -> String:
	if not vocero.is_empty():
		vocero = {}
		return "Vuelves a dar tú la cara en cada rueda de prensa."
	if mio == null or mio.plantilla.is_empty():
		return "no hay plantilla"
	var candidatos: Array[Jugador] = []
	for j: Jugador in mio.plantilla:
		if j.capitan or j.rasgo == "lider":
			candidatos.append(j)
	if candidatos.is_empty():
		return "hace falta un capitán o un líder de vestuario: nadie más tiene el peso para hablar por el club"
	var elegido: Jugador = candidatos[Azar.ent(0, candidatos.size() - 1)]
	vocero = {"id": elegido.id, "nombre": elegido.nombre}
	noticia.emit("Nuevo vocero del club",
		"%s hablará por ti en las ruedas de prensa. Menos desgaste para ti, pero también menos control sobre el mensaje." % elegido.nombre)
	return "%s habla por ti desde hoy." % elegido.nombre

## El vocero se va con el jugador. Si lo vendes, lo cedes o se retira, el club
## se queda sin quien hable: no avisarlo dejaría un nombre fantasma en pantalla.
func revisar_vocero(mio: Club) -> void:
	if vocero.is_empty() or mio == null:
		return
	for j: Jugador in mio.plantilla:
		if j.id == String(vocero.get("id", "")):
			return
	var quien := String(vocero.get("nombre", "el vocero"))
	vocero = {}
	noticia.emit("El club se queda sin vocero",
		"%s ya no está en el plantel. A partir de la próxima rueda vuelves a dar tú la cara." % quien)

# ---------------------------------------------------------------------------
#  DERECHOS DE TELEVISIÓN: EN BLOQUE O POR TU CUENTA
# ---------------------------------------------------------------------------
#
# La decisión más rentable y más impopular del juego. En bloque cobras lo que
# reparte la liga; por tu cuenta ganas un 35% MÁS si tu club vende y pierdes un
# 30% si no, y en los dos casos la asamblea te lo apunta.

var tv_individual: bool = false

## A partir de qué reputación vendes tú solo. Por debajo, sin la fuerza del
## bloque, la televisión te ofrece menos de lo que la liga te reparte.
const REP_VENDE_SOLO := 80

func negociar_tv(individual: bool, mio: Club) -> String:
	if tv_individual == individual:
		return "ya estás en ese modelo"
	tv_individual = individual
	if not individual:
		noticia.emit("Vuelves al reparto en bloque",
			"El club vuelve a negociar la televisión junto al resto de la liga. Menos techo, más seguridad.")
		return "Vuelves al reparto en bloque."
	var m := _mundo()
	if m != null and m.federacion != null:
		m.federacion.aliados = clampi(m.federacion.aliados - 2, -10, 10)
	if mio != null and mio.rep >= REP_VENDE_SOLO:
		noticia.emit("Contrato de TV individual",
			"Negociaste por tu cuenta y te fue bien: tu marca vende. Los derechos suben un 35%, pero los clubes pequeños te lo van a cobrar en la asamblea.")
		return "Los derechos suben un 35%."
	noticia.emit("Contrato de TV individual",
		"Negociaste por tu cuenta y te fue mal: sin la fuerza del bloque, los derechos caen un 30%.")
	return "Los derechos caen un 30%."

## El multiplicador que sale de esta decisión. En bloque no toca nada.
func factor_tv() -> float:
	if not tv_individual:
		return 1.0
	var m := _mundo()
	var mio: Club = m.mi_club() if m != null else null
	if mio != null and mio.rep >= REP_VENDE_SOLO:
		return 1.35
	return 0.70

# ---------------------------------------------------------------------------
#  EL ARCHIVO DE PORTADAS
# ---------------------------------------------------------------------------
#
# Las portadas ya se escribían después de cada partido grande y se perdían en
# cuanto pasabas de pantalla. Guardarlas cuesta un array y convierte la sala de
# prensa en la hemeroteca del ciclo: se ve de un vistazo si el año fue de
# titulares buenos o de titulares malos.

const PORTADAS_MAX := 60
var portadas: Array = []                ## {t, c, tipo, anio, semana}, la más nueva primero

## `extra` (26-9-2026, plan maestro C20): lo que necesita la portada dibujada
## como periódico -"img": "dt" | "escudo" | "pid:<id>" (quién sale en la foto),
## "sub": la bajada, "medio": la cabecera-. Opcional: una portada vieja sin
## estas claves se dibuja igual, con valores por defecto.
func guardar_portada(titulo: String, cuerpo_texto: String, tipo: String, extra: Dictionary = {}) -> void:
	var m := _mundo()
	var d := {
		"t": titulo, "c": cuerpo_texto, "tipo": tipo,
		"anio": m.anio if m != null else 0,
		"semana": m.semana if m != null else 0,
	}
	d.merge(extra)
	portadas.push_front(d)
	while portadas.size() > PORTADAS_MAX:
		portadas.pop_back()

# ---------------------------------------------------------------------------
#  EL AÑO CONTADO
# ---------------------------------------------------------------------------
#
# Un párrafo, no una tabla. Toda la información ya está repartida por seis
# pantallas: el puesto, los títulos, las rachas, los récords, el goleador. Aquí
# se cuenta como se lo contaría alguien, que es la única forma de que un
# resultado deportivo se lea como una temporada y no como una fila.

func narrador_temporada() -> String:
	var m := _mundo()
	if m == null or m.mi_club() == null:
		return "Todavía no hay temporada que contar."
	var mio := m.mi_club()
	var partes: PackedStringArray = []

	var puesto := 0
	for l: Liga in m.ligas:
		if not l.clubes.has(mio):
			continue
		var n := 0
		for f: Dictionary in l.tabla():
			n += 1
			if f["club"] == mio:
				puesto = n
				break
	if puesto > 0:
		partes.append("La temporada %d de %s terminó en el puesto %d." % [m.anio, mio.nombre, puesto])
	else:
		partes.append("La temporada %d de %s todavía se está jugando." % [m.anio, mio.nombre])

	if m.roles != null:
		var del_anio: PackedStringArray = []
		for t: Dictionary in m.roles.trofeos:
			if int(t.get("anio", 0)) == m.anio:
				del_anio.append(String(t.get("titulo", "")))
		if del_anio.size() > 0:
			partes.append("Se levantaron %d título%s: %s." % [
				del_anio.size(), "" if del_anio.size() == 1 else "s",
				", ".join(del_anio)])
		else:
			partes.append("Sin títulos esta vez.")

	if m.logros != null:
		var r: Dictionary = m.logros.rachas
		if int(r.get("invicto_max", 0)) >= 8:
			partes.append("Hubo una racha de %d partidos sin perder que hizo soñar a la ciudad." % int(r["invicto_max"]))
		if int(r.get("sin_ganar_max", 0)) >= 6:
			partes.append("También hubo un bache de %d partidos sin ganar que puso todo en duda." % int(r["sin_ganar_max"]))
		var rec: Dictionary = m.logros.rec
		var mg: Variant = rec.get("mayor_goleada")
		if mg is Dictionary and int((mg as Dictionary).get("anio", 0)) == m.anio:
			partes.append("La noche grande fue el %s a %s." % [
				String((mg as Dictionary).get("marcador", "")), String((mg as Dictionary).get("rival", ""))])
		var pd: Variant = rec.get("peor_derrota")
		if pd is Dictionary and int((pd as Dictionary).get("anio", 0)) == m.anio:
			partes.append("La peor, el %s con %s." % [
				String((pd as Dictionary).get("marcador", "")), String((pd as Dictionary).get("rival", ""))])
		## El hombre gol. `rec["goles"]` va por id de jugador con {nombre, n} -no
		## por nombre-, que es la trampa que ya costó una lectura en vacío.
		var mejor := ""
		var mejor_n := 0
		var goles: Dictionary = rec.get("goles", {})
		for pid: String in goles:
			var g: Dictionary = goles[pid]
			if int(g.get("n", 0)) > mejor_n:
				mejor_n = int(g.get("n", 0))
				mejor = String(g.get("nombre", ""))
		if mejor != "" and mejor_n > 0:
			partes.append("%s fue el hombre gol con %d tantos." % [mejor, mejor_n])

	var media := relacion_media()
	if media > 60:
		partes.append("La prensa cerró el año de tu lado.")
	elif media < 40:
		partes.append("La prensa cerró el año afilando los cuchillos.")
	else:
		partes.append("La prensa mantuvo la distancia.")
	return " ".join(partes)

## La media de las relaciones con los cinco periodistas, de 0 a 100.
func relacion_media() -> int:
	var s := 0
	for f: Array in PERIODISTAS:
		s += relacion_con(String(f[0]))
	return int(round(float(s) / float(maxi(1, PERIODISTAS.size()))))

# ---------------------------------------------------------------------------
#  EL TITULAR DEL LUNES
# ---------------------------------------------------------------------------
#
# El titular NO usa `Azar`. Es decoración: elegir la frase con la RNG del juego
# desplazaría la simulación entera y dos partidas idénticas dejarían de serlo.
# Se deriva de un hash del marcador, la semana y el rival, que da variedad
# suficiente y es reproducible. Es la misma regla que sigue `publicar()`.

const _TIT_GANE := [
	["\"Una máquina\": el equipo pisa fuerte y la ciudad sueña",
		"Exhibición de fútbol y carácter. El plantel responde a su gente."],
	["\"Golpe de autoridad\"",
		"Sólido atrás, letal arriba: así se construyen los campeones."],
]
const _TIT_EMPATE := [
	["\"Sabor a poco\"", "Un punto que no conforma a nadie en las tribunas."],
]
const _TIT_PERDI := [
	["\"Preocupación en la interna\"",
		"La derrota abre preguntas: ¿alcanza este plantel para pelear arriba?"],
	["\"Noche para el olvido\"",
		"Sin ideas y sin actitud: la crítica apunta a la conducción."],
]

func _hash_de(clave: String) -> int:
	var h := 2166136261
	for i in clave.length():
		h = (h * 31 + clave.unicode_at(i)) & 0x7FFFFFFF
	return h

## El titular y su cuerpo, firmados por uno de los periodistas de la casa.
func titular_prensa(gane: bool, empate: bool, clasico: bool, semilla: String, nombre_clasico: String = "") -> Dictionary:
	var pool: Array = _TIT_GANE if gane else (_TIT_EMPATE if empate else _TIT_PERDI)
	var h := _hash_de(semilla)
	var t: Array = pool[h % pool.size()]
	var p: Array = PERIODISTAS[(h / 7) % PERIODISTAS.size()]
	return {
		## Con nombre propio si lo tiene: "SUPERCLÁSICO: ..." (C4).
		"tit": ((nombre_clasico.trim_prefix("el ").to_upper() + ": ") if nombre_clasico != "" else ("CLÁSICO: " if clasico else "")) + String(t[0]),
		"cuerpo": "%s — %s, %s." % [String(t[1]), String(p[1]), String(p[2])],
	}

## Cuántas veces de cada diez sale portada. El HTML tira un 0,4; aquí se compara
## contra el mismo hash para no tocar la RNG.
const PORTADA_DE_CADA := 10
const PORTADAS_QUE_SALEN := 4

## LA RUEDA DESPUÉS DE TU PARTIDO, sin necesitar el `Partido` completo.
##
## `sortear_rueda()` pedía un `Partido` y por eso no la llamaba nadie: el bucle
## de la semana solo tiene el marcador. Toda la sala de prensa —tres barajas de
## preguntas, cinco lenguajes corporales, trece decisiones— existía y no se
## abría una sola vez en una partida de verdad. Esta es la puerta que faltaba.
func rueda_tras_resultado(gane: bool, empate: bool) -> Dictionary:
	## El dado se tira SIEMPRE, aunque ya haya una rueda abierta: así el consumo
	## de azar es el mismo jornada a jornada, que es la regla de toda la casa.
	var toca := Azar.suerte(0.5)
	if not toca or not entrevista.is_empty():
		return {}
	return abrir_rueda(gane, empate)

## La portada del lunes: la escribe el resultado y la archiva la hemeroteca.
func portada_tras_resultado(gane: bool, empate: bool, clasico: bool, semilla: String, marcador: String = "", nombre_clasico: String = "") -> void:
	var h := _hash_de(semilla + "|portada")
	if h % PORTADA_DE_CADA >= PORTADAS_QUE_SALEN:
		return
	var t := titular_prensa(gane, empate, clasico, semilla, nombre_clasico)
	var tipo := "bien" if gane else ("neutro" if empate else "mal")
	guardar_portada(String(t["tit"]), String(t["cuerpo"]), tipo, {"img": "dt", "sub": marcador, "nueva": true})
	noticia.emit("🗞️ " + String(t["tit"]), String(t["cuerpo"]))

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

## Quién habla esta semana y qué dice. Devuelve {nombre, seguidores, texto, tono}.
func opinion_influencer() -> Dictionary:
	var m := _mundo()
	var mio: Club = m.mi_club() if m != null else null
	if mio == null:
		return {}
	var lista: Variant = Datos.tabla("INFLUENCERS")
	if not (lista is Array) or (lista as Array).is_empty():
		return {}
	var quienes: Array = lista as Array
	var anio := m.anio
	var sem := m.semana
	var i: Array = quienes[_hash_de("inf%d%d" % [anio, sem]) % quienes.size()]

	## La racha REAL, leída de `Logros`. Si el creador dijera cualquier cosa se
	## notaría a la segunda semana y se dejaría de leer. El HTML miraba los
	## últimos cinco resultados; aquí se miran las rachas, que es la misma
	## información ya contada y sin guardar una lista aparte para esto.
	var g := 0
	var p := 0
	if m.logros != null:
		g = int(m.logros.rachas.get("ganando", 0))
		p = int(m.logros.rachas.get("sin_ganar", 0))
	var tono := "bien" if g >= 3 else ("mal" if p >= 2 else "neutro")
	var pool: Array = _INFLU_BIEN if tono == "bien" else (_INFLU_MAL if tono == "mal" else _INFLU_NEUTRO)
	return {
		"nombre": String(i[1]),
		"seguidores": String(i[2]) if i.size() > 2 else "",
		"texto": String(pool[_hash_de("op%d" % sem) % pool.size()]),
		"tono": tono,
	}

## Invitarlo al club o dejarlo hablando solo. Devuelve lo que pasó.
func responder_influencer(invitar: bool, c: Club) -> String:
	if not invitar:
		rep_entrenador = clampi(rep_entrenador - 2, 0, 100)
		return "Lo dejaste hablando solo. Se nota en el índice de prensa."
	if c == null:
		return "no hay club"
	var coste := Eco.escalar(COSTE_INVITAR, float(c.rep))
	if c.saldo < coste:
		return "invitarlo cuesta %s y no hay caja" % Cesiones.dinero(coste)
	c.mover_saldo(-coste)
	movimiento.emit("Acción con creadores de contenido", -coste)
	var ganados := int(round(float(seguidores) * 0.06))
	seguidores += ganados
	rep_entrenador = clampi(rep_entrenador + 4, 0, 100)
	noticia.emit("Puertas abiertas",
		"Invitaste a un creador a un entrenamiento. El club ganó %d seguidores y algo de cariño en redes." % ganados)
	return "El club gana %d seguidores." % ganados


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

func _reputacion_de_decision(m: Mundo, id: String, si: bool) -> void:
	if m == null or m.roles == null or not REPUTACION_DE.has(id):
		return
	for r: Array in REPUTACION_DE[id]:
		var d: int = int(r[1]) if si else int(r[2])
		m.roles.anotar_reputacion(String(r[0]), d, String(r[3]))
