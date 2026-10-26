extends RefCounted
## [Capa 1/9 de `mundo.gd`] actual, _init, _anotar_movimiento, _rol_cambio_directiva

## El estado de una partida: los clubes, los jugadores y las ligas.
##
## Es lo que en el HTML era la variable global `G`, un objeto suelto que
## cualquiera de las 847 funciones podia modificar sin avisar. Aqui es un objeto
## con dueno: quien quiera cambiar algo pasa por sus metodos, y las senales
## avisan a la interfaz sin que el simulador sepa que existe una interfaz.

signal semana_avanzada(semana: int, anio: int)
signal temporada_terminada(anio: int, campeon: Club)

## El último mundo creado, para lo que se dibuja sin tener el mundo a mano (los
## patrocinadores de la camiseta, `SponsorKit`). Débil: no lo mantiene vivo.
static var _ultimo: WeakRef = null

var semilla: int = 0
var anio: int = 2026
var semana: int = 1
var clubes: Dictionary = {}       ## id -> Club
var ligas: Array[Liga] = []
var mi_club_id: String = ""

## El mercado necesita ver el mundo entero para tasar (el precio depende de la
## caja del club vendedor) y para buscar objetivos. Se crea con el mundo.
var mercado: Mercado

## La copa nacional de la temporada. Se juega en paralelo a la liga: una ronda
## cada cuatro jornadas, que es lo que hace que el calendario apriete de verdad.
var copa: Copa

## La directiva de TU club y tu cuerpo tecnico. Solo tuyos: los otros 383 clubes
## no necesitan que nadie les exija ni que les paguen un ayudante, y simularlo
## para todos seria gastar en algo que nadie va a ver nunca.
var directiva: Directiva
var staff: Staff = Staff.new()
var obras: Instalaciones = Instalaciones.new()
var entrenamiento: Entrenamiento
var cesiones: Cesiones
var vestuario: Vestuario
var selecciones: Selecciones
var cantera: Cantera
## Los chicos de 10 a 16 años de tu club, antes de ser jugadores (`Academia`).
var academia: Academia
var ojeadores: Ojeadores

## `G.libro` del HTML: el registro de movimientos de caja de tu club. Siete
## clases -Finanzas, Cesiones, Cantera, Federacion, Prensa, Selecciones,
## EstadioPropio- tienen una señal `movimiento(concepto, monto)` desde hace
## tiempo, y ninguna la escuchaba nadie: los pagos pasaban de verdad -la caja
## sí se movía- pero no quedaba ni rastro de POR QUÉ. Se llena en
## `_anotar_movimiento()`, conectada una vez por cada fuente.
var libro_financiero: Array[Dictionary] = []
const LIBRO_MAX := 60
## `Roles` necesita ver el mundo, asi que se crea en `generar()`, no aqui: en la
## declaracion todavia no existe el `self` que hay que pasarle.
var roles: Roles
var federacion: Federacion = Federacion.new()
var estadio: EstadioPropio = EstadioPropio.new()
## El reto elegido en el menú, si lo hay (`Retos`): {id, club, anio, juzgado, cumplido}.
var reto: Dictionary = {}
## El fondo de inversión (modo "fondo"); null en los demás modos.
var fondo: FondoInversion = null
var prensa: Prensa
var medico: Medico
## Los desafíos activos de esta partida (claves de la tabla `DESAFIOS`), del
## paso 5 del asistente del HTML. Se eligen una vez, al empezar, y no cambian
## -por eso viven como un simple array del Mundo y no como una clase propia
## con `_mundo()` en `WeakRef`, que es para lo que necesita ver el mundo por
## fuera de sí mismo.
var desafios: Array[String] = []

## `G.libres` del HTML: futbolistas sin club, fichables sin traspaso -solo una
## prima de fichaje y el sueldo-. Es del MUNDO, no de tu club -cualquier club
## podría fichar de aquí, aunque hoy solo lo hace el tuyo-, así que vive junto
## a `copa`/`continentales`, no dentro de `_restaurar_lo_tuyo()`.
var libres: Array[Jugador] = []
signal libre_estrella(j: Jugador)

## La gente que llena el estadio: segmentos, abonos y encuestas. Solo de TU
## club, como la prensa o el vestuario.
var hinchada: Hinchada
## `vGente()`: las diez personas del club. Ver `nucleo/gente.gd`.
var gente: Gente
## Las salas del edificio del club decoradas a tu gusto (estadio 2.0).
var interiores := InterioresClub.new()
## `vClubIn()`: vestuario, sala de prensa, palco y lo digital.
var club_dentro: ClubDentro
## El presidente del club, los accionistas y la junta trimestral (C5).
var junta: Junta
## Las charlas uno a uno con cada jugador y las promesas hechas (C7).
var charlas: Charlas
## La licencia de entrenador y sus exámenes (C7).
var licencia: Licencia
## Los trabajadores de las instalaciones y sus eventos (C10), y los asuntos de
## la cantera (C11).
var trabajadores: Trabajadores
## Las redes sociales (Tribuna): tu cuenta y la oficial del club (28-9-2026).
var redes: Redes
## LA CARRERA DE JUGADOR (29-9-2026): solo existe en ese modo.
var carrera_jugador: CarreraJugador = null
## Tu teléfono: personalización, foto de perfil y Mensajes (28-9-2026).
var movil: Movil
## Guerra de ofertas, superagente, fichaje impuesto, apuestas, transparencia.
var mercado_av: MercadoAvanzado
## Resta de puntos, administrador, tope salarial, cláusula del DT, refundación.
var insolvencia: Insolvencia
## Lo editado de las competiciones que se recrean cada temporada (la copa):
## {"copa_nombre", "copa_sede"}.
var ajustes_competicion: Dictionary = {}
var eventos_cantera: EventosCantera
var calendario: Calendario
var politica: Politica
var contratos: Contratos
var vida: VidaDT
## FASE 0 (25-10): el reloj único (día y hora dentro de la semana) y las necesidades
## del DT. Solo escuchan a la semana: no cambian la simulación (`nucleo/reloj.gd`).
var reloj: Reloj = Reloj.new()
var necesidades: Necesidades = Necesidades.new()
var maestria: Maestria
## El resultado de tu último partido de liga para `VidaDT`: 1, 0, -1, o 2 si no hubo.
var _resultado_semana: int = 2
## `vBanco()`: deuda, cuotas y el reloj de la liquidación.
var banco: Banco
## La marca del pecho: ofertas, firma y exigencia contractual.
var auspicio: Auspicio
## Epocas doradas y decadencias: un pais entero ganando o perdiendo una camada.
## Lo que se vende del club: kits, proveedor, zonas de patrocinio y naming.
var comercial: Comercial
## El club y su barrio: terrenos, negocios, vecinos, permisos y seguridad.
var ciudad: Ciudad
## Si tu club gano su ultimo partido. Lo escribe `_avisar_a_la_directiva()` y lo
## lee el desgaste del entrenador: ganar descansa.
var _gano_la_ultima: bool = false
var eras: Eras = Eras.new()   ## se recrea con el mundo en `generar()`

## El "fin de partida" del desafío invicto: no bloquea nada por dentro -el
## motor sigue, se puede seguir jugando si se quiere-, es la bandera que la
## interfaz lee para plantar "FIN DE LA PARTIDA" delante, igual que hace
## `despedido_ya` de Directiva.
var fin_partida: Dictionary = {}

## Cuántas temporadas seguidas llevas en el mismo club: lo que hace que el
## desafío "trotamundos" te eche solo a las dos. Se resetea al cambiar de
## club a mano (`tomar_el_mando`), no solo cuando el desafío te obliga.
var anios_en_club: int = 0

## "Crear tu Club" (`crearClubPortada()` del HTML): funda un club de cero
## tomando el puesto del colista de un país -en Chile, el colista de Ascenso;
## en el resto, el más flojo de su única división, porque ahí no hay Ascenso
## en los datos-, con su plantel entero rehecho a la reputación de fundación.
## No pisa nombres ni escudos de nadie más: solo cambia el club que ya iba a
## ser el peor de la tabla.
##
## Devuelve el club fundado, o null si no hay candidato en ese país -no
## debería pasar nunca con las 24 ligas generadas, pero un país vacío no
## puede reventar el fundador.
const REP_FUNDACION := 58

## `TIENDA_DEF` y `toggleTienda()` del HTML: líneas de producto que se lanzan
## pagando el montaje una vez y luego venden todos los meses. Lo que las hace
## interesantes es de qué dependen: de los SOCIOS (cada socio es un cliente) y
## del ÁNIMO de la hinchada, así que la tienda rinde cuando el equipo ilusiona.
##
## Del HTML entran tres de las cuatro: falta "Peluche de la mascota", que
## depende de un sistema de mascota que Godot no tiene. Documentado, no colado
## a medias.
## `G.normas` del HTML: el reglamento interno. Cuatro decisiones con efecto de
## verdad, no adornos -cada una cuesta o da algo, y ninguna es gratis-:
##  · multas    → un lío nocturno se cobra caro, pero al multado le baja la moral
##  · queda     → toque de queda: −1 de moral cada seis semanas a todo el plantel,
##                a cambio de que los polémicos den menos problemas
##  · conc      → concentración previa a cada partido de local: cuesta dinero y
##                da +2 de físico a todos
##  · primas    → primas por objetivos: se pagan al cumplir, y suben la moral
var normas := {"multas": true, "queda": false, "conc": false, "primas": false}
const NORMAS_DEF := [
	["multas", "Multas del reglamento interno",
		"Un lío fuera de la cancha se cobra caro. Entra dinero, pero al multado le baja la moral."],
	["queda", "Toque de queda",
		"Cuesta un punto de moral a todo el plantel cada seis semanas, y a cambio los jugadores conflictivos dan menos guerra."],
	["conc", "Concentración antes de jugar en casa",
		"Hotel y logística por cada partido de local. El plantel llega con dos puntos más de físico."],
	["primas", "Primas por objetivos",
		"Se pagan al cumplir lo que pide la directiva, y el vestuario lo celebra con seis puntos de moral."],
]

const TIENDA := {
	"buf": {"nombre": "Bufandas", "montaje": 60000, "por_socio": 2.2},
	"taza": {"nombre": "Tazones", "montaje": 40000, "por_socio": 1.4},
	"alb": {"nombre": "Álbum de figuritas", "montaje": 120000, "por_socio": 3.0},
}
var tienda: Dictionary = {}
var logros: Logros

## Los torneos continentales de la temporada, por clave de confederacion
## ("lib", "sud", "ucl", "uel"...). Se sortean al empezar cada temporada.
var continentales: Dictionary = {}

var _seq_jugador: int = 0
## Que el mundo generado al empezar -8.000 y pico jugadores, ninguno pasado
## por `crear_jugador()` con un `Entrenamiento` ya vivo- reciba UNA vez sus
## habilidades de nacimiento. No se guarda en la partida a propósito: si una
## carga la vuelve a disparar, `Entrenamiento.desde_dic()` -que corre justo
## después, en `partida.gd`- pisa el sorteo con los datos de verdad guardados.
var _habilidades_sembradas: bool = false
var _seq_club: int = 0

## `edad` y `ovr` a -1 significan "sortealos tu": lo usan los canteranos que
## suben a final de temporada, donde no hay una plantilla que respetar.
## Mientras `_poblar` arma una plantilla fija (ver arriba).
var _clave_fija := ""
var _n_fijo := 0

## HASTA HOY (22-9-2026): sin `pais`, TODO el mundo -los ~8.000 jugadores del
## arranque más cada canterano- salía con apellido chileno (`NOMBRES`/
## `APELLIDOS`, el fondo de fábrica), jugara en Alemania, Japón o Arabia
## Saudita. El usuario lo pidió explícito ("usa apellidos de los canteranos
## según su nacionalidad"), y la infraestructura para esto YA EXISTÍA -
## `POOLS_EU` (13 países) + `NOMBRES_BRA`/`APELLIDOS_BRA`- pero solo se
## usaba para el DT rival en la previa (`previa.gd::_nombre_dt()`) y para
## ojeadores extranjeros (`ojeadores.gd`), nunca para el jugador mismo, que
## es el 90% del mundo. Mismo criterio que `previa.gd`: `POOLS_EU` primero,
## BRA aparte; el resto (CHI/ARG/PER/URU/COL... hispanohablantes sin bolsa
## propia todavía) cae al fondo chileno de siempre -no a `NOMBRES_EXT`/
## `APELLIDOS_EXT` (para el DT "genérico" sin nacionalidad reconocida): un
## jugador peruano se lee mejor con un apellido hispano real que con uno
## inventado sin origen ninguno-. `ESP` se sumó a `POOLS_EU` en esta misma
## ronda (con sabor vasco a propósito -Etxeberria, Agirre, Garmendia...-,
## a pedido del usuario, mencionando el Athletic Club de Bilbao).
##
## Nunca devuelve el nombre de un futbolista real (`Nombres.vetado()`).
## SIN TOCAYOS (M-331, 20-10): un mundo de tres ligas tenía un 10 % de nombres
## repetidos («Lucas Barbosa» ×5). Ahora se vuelve a sortear (hasta 8 veces) si
## el nombre ya existe; con bolsas muy chicas, alguno se puede repetir igual.
var _nombres_usados: Dictionary = {}

static var _bolsas_extra: Dictionary = {}

const MOTIVOS_LIBRE := [
	"Rescindió por sueldos impagos", "Su club descendió y lo dejó libre",
	"No renovó y quedó sin equipo", "Volvió del extranjero sin club",
	"Se recuperó de una lesión larga y nadie lo llamó",
	"Rompió el contrato tras una pelea con su DT",
]

## Premio del campeón de liga. Es una cifra FIJA, no escalada al tamaño del
## club: viene así del HTML y es lo que hace que un título valga de verdad para
## un club chico. Escalarlo lo convertiría en un ingreso más de los grandes.
const PREMIO_LIGA := 500000

## --- LO QUE APORTA EL CUERPO TECNICO ---------------------------------------

## Jugadores de otros clubes cuyo potencial real ya conoces. Sin ojeador, la
## ficha de un rival solo enseña su media de hoy; con ojeador, su techo.
var ojeados: Dictionary = {}

signal informe_de_ojeo(j: Jugador, club_suyo: Club)
signal obra_lista(clave: String)

# ---------------------------------------------------------------------------
#  AMBIENTE: ESTACIÓN, CLIMA Y HORARIO
# ---------------------------------------------------------------------------
#
# `vEntrenoPlus()` del HTML. Son tres cosas pequeñas que juntas hacen que una
# temporada no se sienta como cuarenta y dos semanas iguales: que en invierno
# llueva, que en verano apriete el calor, y que elegir la hora del partido sea
# una decisión entre la taquilla y los derechos de televisión.

## Las cuatro estaciones repartidas en las 42 semanas.
const ESTACIONES := [
	["verano", "☀️"], ["otoño", "🍂"], ["invierno", "❄️"], ["primavera", "🌸"],
]

## Los cuatro horarios: [clave, hora, nombre, factor de público, factor de TV,
## explicación]. La decisión es siempre la misma y siempre incómoda: cuanto más
## paga la televisión, menos gente va al estadio.
const HORARIOS := [
	["tarde", "16:00", "Tarde de sábado", 1.0, 1.0, "El horario de toda la vida"],
	["noche", "21:30", "Noche de sábado", 1.08, 1.12, "Ambiente de caldera y mejor audiencia"],
	["mediodia", "12:30", "Mediodía de domingo", 0.82, 1.18, "A la televisión le encanta; a la hinchada no"],
	["lunes", "20:00", "Lunes por la noche", 0.68, 1.25, "Casi nadie va, pero pagan más los derechos"],
]
var horario: String = "tarde"

# ---------------------------------------------------------------------------
#  CAMPAÑAS PUBLICITARIAS Y GUERRA DE MARCAS
# ---------------------------------------------------------------------------
#
# El catálogo vive en `Finanzas` porque es cosa de dinero; el ESTADO vive aquí
# porque `Finanzas` se construye por club y por semana y no sobrevive de una a
# otra: no puede recordar qué campaña lanzaste este año.

## {anio, clave} de la última campaña lanzada. Una por temporada.
var campana: Dictionary = {}

# ---------------------------------------------------------------------------
#  LAS DOS VENTANAS DE MERCADO
# ---------------------------------------------------------------------------
#
# «Fichajes de última hora en el cierre de mercado» (idea 87). Hasta ahora se
# podía fichar cualquier semana del año, y eso quitaba de golpe dos cosas que
# son media gracia del género: la urgencia del último día y tener que aguantar
# medio año con la plantilla que armaste.
#
# Son las mismas dos ventanas del HTML —`sem<=6` y `18<=sem<=24`—: la de
# pretemporada, larga, y la de invierno, corta y cara.
const VENTANA_VERANO := 6
const VENTANA_INVIERNO_INI := 18
const VENTANA_INVIERNO_FIN := 24

# ---------------------------------------------------------------------------
#  LA SUPERCOPA Y LOS AMISTOSOS DE PRETEMPORADA
# ---------------------------------------------------------------------------
#
# Ideas 169 y 170. Las dos ocupan el hueco vacío del calendario -el que va entre
# que se cierra una temporada y arranca la siguiente- y las dos existen por lo
# mismo: hoy ese hueco es un botón de «temporada siguiente» y no pasa nada.

## El campeón de liga contra el campeón de copa, a partido único. Se juega al
## empezar la temporada nueva y da un título de verdad: cuenta para la vitrina,
## para el palmarés y para el prestigio.
const PREMIO_SUPERCOPA := 140000

var _campeon_liga_pasado: Club = null
var _campeon_copa_pasado: Club = null

## Los amistosos de pretemporada. No dan puntos ni dinero grande: dan FORMA, que
## es lo que le falta a un plantel que lleva un mes parado. Es la única forma de
## llegar afinado a la primera jornada.
const AMISTOSOS := [
	["local", "Triangular en casa", 0.0, 6],
	["gira", "Gira internacional", 220000.0, 11],
	["cantera", "Amistosos con la cantera", 0.0, 3],
]

var amistoso_hecho: bool = false

## Los días señalados del calendario. Son cuatro y siempre caen en la misma
## semana: la gracia no es la sorpresa, es que la temporada tenga fechas con
## nombre en vez de cuarenta y dos semanas iguales.
const FIESTAS := {
	3:  ["🎉", "Fiestas patrias", "La ciudad está de fiesta: más gente en la calle y en el estadio"],
	12: ["🎄", "Navidad", "Semana rara: entrenamientos cortos y la cabeza en otra parte"],
	20: ["🎊", "Aniversario del club", "El club cumple años y la hinchada se vuelca"],
	31: ["🌞", "Vacaciones de invierno", "Familias enteras al estadio"],
}

# ===========================================================================
#  LA MODA TÁCTICA Y LO QUE DE VERDAD TE FUNCIONA
# ===========================================================================
#
# Ideas 411 y 412: «evolución táctica por era: el fútbol de moda cambia con los
# años» y «estadística de eficacia por cada táctica utilizada».
#
# LAS DOS JUNTAS SON UNA SOLA COSA. Sin la primera, la mejor formación del juego
# es la mejor para siempre y se elige una vez en diez temporadas. Sin la segunda,
# el jugador no tiene forma de saber que la moda cambió: lo notaría perdiendo y
# sin entender por qué.

## Las eras del fútbol, en orden. Cada una favorece un dibujo y castiga otro, y
## duran entre cuatro y siete temporadas. Son las modas de verdad del fútbol
## moderno, puestas en fila.
const ERAS_TACTICAS := [
	["contragolpe", "La era del contragolpe", ["4-4-2", "5-3-2"], ["4-3-3"],
		"Se juega replegado y a la espalda. Los bloques bajos ganan partidos."],
	["posesion", "La era de la posesión", ["4-3-3", "3-5-2"], ["4-4-2"],
		"Manda el que tiene la pelota. Los equipos que solo esperan se ahogan."],
	["presion", "La era de la presión alta", ["4-2-3-1", "4-3-3"], ["5-3-2"],
		"Se roba arriba y se ataca en cinco segundos. Salir jugando desde atrás es un riesgo."],
	["bloque", "La era del bloque medio", ["4-2-3-1", "4-4-2"], ["3-5-2"],
		"Ni arriba ni atrás: se defiende en el centro y se sale rápido por fuera."],
]

## Cuánto pesa estar de moda. Un 5% arriba y un 5% abajo: lo justo para que se
## note en una temporada larga y no tanto como para que el dibujo elegido decida
## los partidos por encima de los jugadores.
const BONO_MODA := 1.05
const CASTIGO_MODA := 0.95

var era_tactica: int = 0
var era_hasta: int = 0

# ---------------------------------------------------------------------------
#  QUÉ TE FUNCIONA A TI
# ---------------------------------------------------------------------------
#
# El registro de lo que pasa con CADA dibujo que usas: partidos, puntos y goles.
# No dice cuál es el mejor del juego —eso depende de tu plantilla—: dice cuál te
# está funcionando a TI, que es la única pregunta que importa.

## formacion -> {pj, pg, pe, pp, gf, gc}
var eficacia_tactica: Dictionary = {}

# ---------------------------------------------------------------------------
#  ROTACIÓN Y VIDEOANÁLISIS
# ---------------------------------------------------------------------------
#
# Ideas 414 y 441: «rotación planificada para calendarios congestionados» y
# «video-análisis grupal antes de rivales difíciles».
#
# LA ROTACIÓN no es cambiar el once a mano —eso ya se puede—: es decirle al club
# que en las semanas de tres partidos guarde a los que están fundidos. Sin esto,
# una semana de liga + copa + continental te deja el plantel a treinta de físico
# y no hay forma de evitarlo salvo alinear a mano cada jornada.

## Cuánto físico hace falta para ser titular con la rotación puesta.
const FISICO_PARA_TITULAR := 62

var rotacion_activa: bool = false

# ---------------------------------------------------------------------------
#
# EL VIDEOANÁLISIS es la única preparación que se hace ANTES de saber cómo va el
# partido. Cuesta una sesión de la semana y da un empujón contra el rival de
# turno; contra uno mucho mejor que tú, da más: es para lo que se usa de verdad.

const SEMANAS_ENTRE_ANALISIS := 3
var _ultimo_analisis: int = -99
var bono_analisis: float = 1.0

static func actual() -> Mundo:
	return _ultimo.get_ref() as Mundo if _ultimo != null else null

func _init() -> void:
	_ultimo = weakref(self)
	reloj.seguir_a(semana_avanzada)       ## fase 0: el reloj sigue a la semana
	necesidades.seguir_a(reloj)          ## y las necesidades, al reloj

func _anotar_movimiento(concepto: String, monto: int) -> void:
	libro_financiero.append({"concepto": concepto, "monto": monto, "anio": anio, "semana": semana})
	while libro_financiero.size() > LIBRO_MAX:
		libro_financiero.pop_front()

## El rol puede cambiar SIN pasar por `tomar_el_mando()` -un ayudante que
## asciende, un director que compra el club-, así que `Directiva.puede_despedirte`
## no se puede fijar solo una vez: tiene que seguir al rol mientras dure la carrera
## en este club.
func _rol_cambio_directiva(_antes: String, _ahora: String) -> void:
	if directiva != null:
		directiva.puede_despedirte = roles.le_pueden_echar()
