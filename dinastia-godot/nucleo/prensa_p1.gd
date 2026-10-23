extends RefCounted
## [Capa 1/8 de `prensa.gd`] variables, constantes y señales

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

## Hacia dónde quiere moverse cada demarcación (la vecina más ofensiva o la
## más natural para su perfil).
const _POSICION_DESEADA := {"DFC": "MCD", "LD": "CAD", "LI": "CAI", "CAD": "MD", "CAI": "MI",
	"MCD": "MC", "MC": "MCO", "MCO": "SD", "MD": "ED", "MI": "EI", "ED": "DC", "EI": "DC",
	"SD": "DC", "DC": "SD"}

## EFECTOS QUE DURAN (plan maestro B4). Cada uno: {id, semanas, pid}. Se aplican
## y descuentan en `semana()` y se guardan con la partida.
var efectos: Array = []


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

# --- texto libre -------------------------------------------------------------
## Lo que no es respuesta: cortar, derivar, "sin comentarios".
const _EVASIVAS := ["sin comentarios", "no voy a", "siguiente", "no hablo", "no tengo nada",
	"ya dije", "ya lo dije", "pregúntenle", "preguntenle", "pregunten a", "otro día", "no corresponde"]
## Lo que suena subido.
const _SOBERBIAS := ["somos los mejores", "que se preparen", "nadie nos", "ustedes no", "no saben",
	"vamos a ganar", "ganaremos", "campeones", "obvio", "yo decido", "mi decisión", "ridícul",
	"tendencios", "mentira", "no me importa", "lo sostengo", "cállense", "callense"]

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
