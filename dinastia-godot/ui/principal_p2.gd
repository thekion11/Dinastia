extends "res://ui/principal_p1.gd"
## [Capa 2/17 de `principal.gd`] _ayudante

## FASE 0 (separar `Principal`): cada responsabilidad que sale de las capas va
## a una clase propia en `ui/principal/` con su estado y una interfaz corta.
## Principal las posee y les delega; los métodos viejos quedan como puentes.
## Se cargan con `preload` y sin `class_name` para que no dependan de la caché
## de clases (un `class_name` nuevo sin reimportar rompería esta pantalla).
## Las que conectan señales del mundo son `Node` hijos (ver la cabecera de
## `sorteos.gd`), y se cuelgan aquí mismo, al crearse la pantalla. Se declaran
## en esta capa (no en la de cada puente) para que todas las de encima las vean.
const _PrincipalSorteos := preload("res://ui/principal/sorteos.gd")
var _sorteos := _ayudante(_PrincipalSorteos.new(self)) as _PrincipalSorteos
const _PrincipalNoticias := preload("res://ui/principal/noticias.gd")
var _noticias := _ayudante(_PrincipalNoticias.new(self)) as _PrincipalNoticias
const _PrincipalPreferencias := preload("res://ui/principal/preferencias.gd")
var _prefs := _PrincipalPreferencias.new(self)
const _PrincipalCicloPartida := preload("res://ui/principal/ciclo_partida.gd")
var _partida := _PrincipalCicloPartida.new(self)
## Puente de solo lectura para las pantallas que miran la pila de deshacer
## (Opciones enseña cuántos pasos quedan; Ajustes la vacía al cambiar de mundo).
var _pila_deshacer: Array[Dictionary]:
	get:
		return _partida.pila_deshacer
const _PrincipalGuia := preload("res://ui/principal/guia_tutorial.gd")
var _guia := _PrincipalGuia.new(self)

## Cuelga un ayudante `Node` de esta pantalla y lo devuelve. Se llama desde el
## inicializador de la variable: así existe antes de `_ready()` y de cualquier
## llamada de una prueba, y se libera junto con Principal.
func _ayudante(n: Node) -> Node:
	add_child(n)
	return n

## El fondo de cada `.card` del HTML no es un color plano: trae un degradado
## cenital sutil (`linear-gradient(180deg, panel+12%blanco, panel 42%)`) que
## le da un aire de placa con brillo, no de rectángulo pintado. `StyleBoxFlat`
## de Godot no admite degradados, así que se superpone una textura aparte
## -blanco semitransparente arriba, cero abajo- que ignora el ratón: el mismo
## efecto, sin tapar ningún control de debajo.
static var _brillo_panel: Texture2D = null

## ELEGIR CLUB: MAPA DEL PAÍS Y ESCUDOS, no un desplegable de 383 líneas.
##
## «La forma de elegir el club debe estar mejor visualmente; cuando se selecciona
## un país debe aparecer un mapa y enmarcar el país que seleccionaste, y ahí se
## despliegan los clubes». Del documento de instrucciones.
##
## Hasta ahora era un `OptionButton` con los trescientos ochenta y tres clubes
## del mundo en una lista plana: para encontrar el tuyo había que bajar por un
## menú interminable, y todos se veían exactamente igual.
##
## AHORA SON DOS PASOS. Primero el país -con su silueta dibujada y el número de
## clubes-, y dentro los clubes de ese país con su escudo, su reputación, su
## división y su aforo, que es lo que de verdad se compara al elegir dónde
## empezar. El desplegable de arriba sigue existiendo para cambiar rápido.
var _dlg_club: Window = null
var _pais_elegido: String = ""

## LOS CINCO MODOS DE MIRAR UN PARTIDO (plan maestro B2): [clave, rótulo, qué es].
const MODOS_SIMULACION := [
	["instantaneo", "⚡ Instantáneo", "Solo el resultado, al momento."],
	["resumen", "📋 Resumen", "Las jugadas clave, una a una, en 20 segundos."],
	["vivo", "📻 En vivo", "Crónica, cambios, arengas y charla, sin 3D."],
	["destacados", "🎬 3D destacados", "El estadio a x4, frena en cada ocasión."],
	["completo", "🏟 3D completo", "El partido entero en el estadio."],
]
const SECCION_SIMULACION := "simulacion"

## Para no repetir el aviso del cierre de mercado cada vez que se repinta.
var _mercado_avisado: int = -1

## El registro es texto enriquecido y no pasa por el traductor de etiquetas:
## se traduce cada tramo de texto entre etiquetas BBCode (título y cuerpo de
## la noticia van en tramos distintos).
var _re_tramos_bb: RegEx

# --- pintado ----------------------------------------------------------------

var _panel_obj: PanelObjetivos

## PINTAR SOLO LO QUE SE VE (29-9-2026, auditoría). `_refrescar` repintaba las
## ~40 pantallas del juego en cada clic, se vieran o no: 2-4 segundos por
## refresco medidos sin gráfica (entrenamiento 0,5 s, estadio 0,4 s, ficha
## 0,4 s...). Ahora las pestañas que no están a la vista quedan PENDIENTES y se
## pintan el cuadro en que aparecen (`_process`). `pintar_todo` lo desactiva.
var pintar_todo := false
var _pendientes := {}   ## Control -> Callable

## La columna de la izquierda SIGUE A LA COMPETICIÓN DEL PRÓXIMO PARTIDO.
##
## Antes enseñaba siempre la tabla de liga, y eso hacía que la semana de
## Libertadores se sintiera igual que la semana catorce de campeonato. Si el
## domingo juegas la copa, lo que quieres ver es el cuadro; si es fase de
## grupos, tu grupo; y solo si toca liga, la tabla. Cambiar de torneo tiene que
## NOTARSE sin leer un texto que lo diga.


## Por qué columna se ordena el plantel y en qué sentido. `vJugadores()` del
## HTML deja ordenar por seis columnas; aquí se guarda entre repintados para que
## avanzar una semana no te devuelva al orden por media.
var _orden_plantel: String = "ovr"
var _orden_plantel_desc: bool = true

## La pestaña del club: lo que te exige la directiva y el cuerpo técnico que
## puedes contratar. Es la pantalla donde se gasta el dinero que no va a fichajes.
## LA PESTAÑA "CLUB", PARTIDA EN SECCIONES (10-9-2026). Tenía doce bloques
## seguidos en un solo scroll -directiva, cuerpo técnico, ojeadores, analítica,
## academias, obras, equipación, cargo, carrera-, que es justo lo que el
## usuario pidió romper ("deben existir más submenús"). Cada sección es ahora
## un chip del menú de nivel 2; el dispatch vive en `_pintar_club()`.
var _secc_club: String = "directorio"

# --- el despacho: lo que hay que resolver AHORA ----------------------------

## La decisión pendiente y la rueda de prensa, en una franja bajo la cabecera.
##
## Van fuera de las pestañas a propósito. Si una decisión se esconde en una
## pestaña, el jugador no la ve, la semana avanza sin resolverla y el sistema
## entero deja de existir para él. Lo que hay que decidir hoy tiene que estar
## delante.
## EL DESPACHO, COMPACTADO (10-9-2026). Antes apilaba hasta cuatro tarjetas
## enteras -representante, decisión, rueda de prensa- y entre las tres se
## comían media pantalla: el menú quedaba empujado casi al borde de abajo. El
## usuario lo dijo mirándolo: "esas notificaciones siento que podemos hacer
## que se vean de otra forma".
##
## Ahora es una FILA de avisos y solo se despliega el que estés mirando. Nada
## se pierde -los mismos asuntos, las mismas decisiones- pero ocupa una línea
## en vez de media pantalla.
##
## La única excepción es quedarse sin banco: esa tapa a todas a propósito,
## porque hasta que no firmes en algún sitio no hay club que gestionar.
var _aviso_abierto: int = 0
## La cinemática de pantalla completa de la rueda de prensa, o null si no hay
## ninguna abierta. Ver `_abrir_rueda_pantalla_completa()`.
var _rueda_pop: Control = null
## Lo que la repregunta cambia sin rehacer el plató (B5).
var _rueda_quien: Label
var _rueda_pregunta: Label
var _rueda_opciones: VBoxContainer
var _rueda_reloj: ProgressBar
var _rueda_desde := 0

## LA DECISIÓN, CONTADA COMO UN ACONTECIMIENTO (25-9-2026, plan maestro B4).
## A la izquierda, la cara de quien está en el lío -o el icono grande del tema
## si no hay un jugador-; suena y late la primera vez que aparece; y al firmar,
## la consecuencia sale en un aviso además del registro.
var _decision_mostrada := ""

## LOS ESTILOS COMPLETOS DEL ESTADIO -"✨ ESTILOS COMPLETOS" de
## `vEstadioDiseno()`-. `EstadioPropio.presets()` traía los ocho estilos del
## HTML (bombonera, catedral inglesa, arena moderna...) con su coste ya
## calculado, y NINGUNA pantalla lo llamaba: el patrón de siempre, sistema
## escrito sin botón. Van también "🎲 Sorpréndeme" y "↺ Volver a fábrica".
##
## Sorpréndeme PROPONE y no aplica: en el HTML era gratis y automático, aquí
## una reforma cuesta, y nadie paga una obra que no ha visto. Y solo toca
## `Azar` al PULSAR -es una decisión del jugador-: pedir la propuesta en cada
## repintado consumiría números y movería la simulación entera.
var _propuesta_estadio: Dictionary = {}

## Qué tribuna se está editando cuando "Personalizar cada tribuna" está activo.
## Solo estado de interfaz -no se guarda, como `_secc_ajustes`-: al volver a
## esta pantalla siempre se empieza mirando la tribuna Sur.
var _bandeja_actual: String = "sur"

## Los nombres bonitos de cada campo. `campo.capitalize()` daba "Cespedtono" y
## "Escudodonde", que es lo que pasa cuando una clave interna se enseña tal cual.
const ETIQUETAS_ESTADIO := {
	"forma": "Forma", "techo": "Techo", "focos": "Focos", "pantalla": "Pantallas",
	"cesped": "Corte del césped", "cespedTono": "Tono del césped",
	"lineaCol": "Color de las líneas", "arcoCol": "Color de los arcos",
	"redCol": "Color de las redes", "redTipo": "Tejido de la red",
	"asientoP": "Butacas", "banderas": "Banderas", "escudoDonde": "Dónde va el escudo",
	"corner": "Banderines de córner", "banquillo": "Banquillos", "tunel": "Túnel",
	"clima": "Clima", "sonidoGol": "Sonido del gol",
	"fachada": "Fachada", "fachadaCol": "Color de la fachada", "techoCol": "Color del techo",
	"luzFocos": "Luz de los focos", "superficie": "Superficie", "banquilloCol": "Color de los banquillos",
	"vallaCol": "Marco de las vallas", "ledPaleta": "Pantallas LED", "ledFondo": "Fondo de las LED", "ledTinta": "Letras de las LED", "focosCol": "Estructura de los focos",
	"anillo_sur_1": "Anillo 1 — Sur", "anillo_sur_2": "Anillo 2 — Sur", "anillo_sur_3": "Anillo 3 — Sur", "anillo_sur_4": "Anillo 4 — Sur", "anillo_sur_5": "Anillo 5 — Sur",
	"anillo_norte_1": "Anillo 1 — Norte", "anillo_norte_2": "Anillo 2 — Norte", "anillo_norte_3": "Anillo 3 — Norte", "anillo_norte_4": "Anillo 4 — Norte", "anillo_norte_5": "Anillo 5 — Norte",
	"anillo_este_1": "Anillo 1 — Este", "anillo_este_2": "Anillo 2 — Este", "anillo_este_3": "Anillo 3 — Este", "anillo_este_4": "Anillo 4 — Este", "anillo_este_5": "Anillo 5 — Este",
	"anillo_oeste_1": "Anillo 1 — Oeste", "anillo_oeste_2": "Anillo 2 — Oeste", "anillo_oeste_3": "Anillo 3 — Oeste", "anillo_oeste_4": "Anillo 4 — Oeste", "anillo_oeste_5": "Anillo 5 — Oeste",
	"bandeja_sur_col1": "Color 1 — Tribuna Sur", "bandeja_sur_col2": "Color 2 — Tribuna Sur",
	"bandeja_norte_col1": "Color 1 — Tribuna Norte", "bandeja_norte_col2": "Color 2 — Tribuna Norte",
	"bandeja_este_col1": "Color 1 — Tribuna Este", "bandeja_este_col2": "Color 2 — Tribuna Este",
	"bandeja_oeste_col1": "Color 1 — Tribuna Oeste", "bandeja_oeste_col2": "Color 2 — Tribuna Oeste",
	"bandeja_sur_asientoP": "Butacas — Tribuna Sur", "bandeja_sur_techo": "Techo — Tribuna Sur",
	"bandeja_norte_asientoP": "Butacas — Tribuna Norte", "bandeja_norte_techo": "Techo — Tribuna Norte",
	"bandeja_este_asientoP": "Butacas — Tribuna Este", "bandeja_este_techo": "Techo — Tribuna Este",
	"bandeja_oeste_asientoP": "Butacas — Tribuna Oeste", "bandeja_oeste_techo": "Techo — Tribuna Oeste",
	"tramo_sur_1": "Tercio 1 — Tribuna Sur", "tramo_sur_2": "Tercio 2 — Tribuna Sur",
	"tramo_sur_3": "Tercio 3 — Tribuna Sur",
	"tramo_norte_1": "Tercio 1 — Tribuna Norte", "tramo_norte_2": "Tercio 2 — Tribuna Norte",
	"tramo_norte_3": "Tercio 3 — Tribuna Norte",
	"tramo_este_1": "Tercio 1 — Tribuna Este", "tramo_este_2": "Tercio 2 — Tribuna Este",
	"tramo_este_3": "Tercio 3 — Tribuna Este",
	"tramo_oeste_1": "Tercio 1 — Tribuna Oeste", "tramo_oeste_2": "Tercio 2 — Tribuna Oeste",
	"tramo_oeste_3": "Tercio 3 — Tribuna Oeste",
}

static var _muestras: Dictionary = {}
## RÉCORDS, PARTIDO EN APARTADOS SIN TOCAR LA FUNCIÓN (10-9-2026).
##
## `_pintar_records()` son ~185 líneas con ocho secciones seguidas. Para darle
## a HISTORIA los apartados que pidió el usuario había dos caminos:
## reescribirla entera metiendo un `if` por bloque -caro y con riesgo de
## romper una pantalla que funciona-, o pintarla como siempre y ESCONDER
## después lo que no toca. Se eligió lo segundo.
##
## Funciona porque cada sección empieza por un Label con un título conocido:
## se recorre la lista una vez, y cada hijo hereda la visibilidad del último
## título que se cruzó. Si mañana se añade una sección nueva, basta con
## sumar su título aquí.
const SECC_RECORDS := {
	"records": ["RACHAS", "MARCAS DEL CLUB"],
	"vitrina": ["GOLEADORES HISTÓRICOS DE TU ERA", "MÁS PARTIDOS DISPUTADOS"],
	"rivales": ["CARA A CARA"],
	"memoria": ["SALÓN DE LA FAMA DEL CLUB", "UN DÍA COMO HOY", "ARCHIVO DE PLANTELES"],
}
var _secc_records: String = "records"

const VACIO_RECORDS := {
	"memoria": "📜 Aquí quedará la memoria del club: el salón de la fama, lo que pasó un día como hoy y el plantel de cada temporada. Se llena a medida que juegas.",
	"rivales": "⚔️ El cara a cara con cada rival aparece en cuanto te enfrentes a él.",
	"vitrina": "🏆 Los goleadores de tu era y los que más partidos juegan aparecen al avanzar la temporada.",
	"records": "📈 Las rachas y las marcas del club se registran desde el primer partido.",
}

## `GLOSARIO` del HTML (`juego.js`, 20 términos): tabla estática, ya exportada
## en `datos/tablas.json` como cualquier otra -no se transcribe a mano-. Sin
## búsqueda por ahora: con 20 entradas una lista fija se lee entera de un
## vistazo, y el proyecto no tenía hasta hoy ningún campo de texto interactivo
## que replicar con fidelidad.
## `vEditor()`: LA ÚNICA PANTALLA QUE NO JUEGA.
##
## Cambia los DATOS: nombres de club, colores, reputación, aforo, y de cada
## jugador su nombre, media, techo, edad, dorsal, puesto, rasgo, atributos y
## cara. Y un importador de CSV para meter una liga entera de golpe.
##
## POR QUÉ ESTÁ. El mundo se genera solo y los nombres van censurados letra a
## número. Quien quiera SU liga —los nombres bien escritos, las plantillas que
## él conoce— tiene que poder escribirla, y a mano son cuatrocientos clubes.
var _editor: Editor
var _ed_filtro: String = ""
var _ed_club: String = ""
var _ed_jugador: String = ""
var _ed_censura: bool = true
var _ed_csv: String = ""
var _ed_confirmar_regen: String = ""

## `vAjustes()` del HTML tiene más de veinte controles, pero la mayoría no
## tienen NADA a lo que engancharse en Godot todavía -tamaño de texto, paleta
## daltónica, cabeceras ilustradas, ranuras múltiples de guardado: cambiarlos
## no cambiaría nada de verdad, y un interruptor que no hace nada falla el
## mismo estándar que una pantalla que falta-. Solo entran los dos que sí
## tienen un efecto real y ya existente para enganchar.
## `vAudio()`: los tres buses por separado y los botones de probar. Los tres
## existen desde que se escribió `Sonido`, pero la pantalla solo daba un SÍ/NO:
## quien quería el ambiente del estadio sin los pitidos de la interfaz tenía que
## apagarlo todo. Y los botones de probar no son un adorno — sin ellos, ajustar
## un volumen a ciegas es imposible: no oyes el cambio hasta la semana siguiente.
const BUSES_AUDIO := [
	[Sonido.Bus.EFECTOS, "Efectos", "gol", "Goles, remates, silbatos y postes."],
	[Sonido.Bus.AMBIENTE, "Ambiente", "ovacion", "El murmullo y la ovación de la grada."],
	[Sonido.Bus.INTERFAZ, "Interfaz", "clic", "Los avisos y los clics de los menús."],
]

## LAS TRES RANURAS MANUALES de `vAjustes()`. `Partida` guarda por NOMBRE desde
## el porte —`guardar(m, nombre)`, `listar()`, `borrar()`— y el juego solo usaba
## una ranura fija: toda esa capacidad estaba escrita y era inalcanzable.
##
## Tres y no más porque tres es lo que se usa de verdad: la partida en curso,
## una copia antes de una decisión gorda, y una vieja por si acaso.
const RANURAS := ["ranura1", "ranura2", "ranura3"]

## `vQoL()`: la interfaz a tu medida. Dos interruptores y los favoritos.
##
## MODO EXPERTO no oculta funciones, oculta EXPLICACIONES. Las notas de "esto
## sirve para tal" son imprescindibles la primera temporada y estorban a partir
## de la quinta; quitarlas es la diferencia entre una pantalla que enseña y una
## que deja trabajar.
var _modo_experto: bool = false
var _favoritos: Array[String] = []
## Que año del archivo de planteles está desplegado. Cero, ninguno: si se
## abrieran todos a la vez, veinte temporadas serían seiscientas filas.
var _plantel_abierto: int = 0
const FAVORITOS_MAX := 6

## `vAjustesDispositivo()`: lo que depende de la máquina, no de la partida.
##
## En el HTML esto era zoom de CSS y detección de mando; en Godot son ajustes de
## VENTANA y de escala de interfaz de verdad, así que no se "porta" la
## implementación, se porta la intención: que el juego se adapte a la pantalla
## que tienes delante.
##
## El zoom no se guarda en la partida a propósito: es de la máquina, y llevarlo
## en el guardado significaría que abrir una partida en otro ordenador te
## cambiaría el tamaño de la letra.
var _zoom_interfaz: float = 1.0
## El ColorRect del fondo, para poder repintarlo al cambiar de paleta sin
## reconstruir la escena entera.
var _fondo_raiz: ColorRect = null
## El modo television es un zoom fuerte de golpe, no un ajuste fino: se mira
## desde el sofa, a tres metros, y ahi no vale ir subiendo de cinco en cinco.
var _modo_tv: bool = false
const ZOOM_TV := 1.35

# ---------------------------------------------------------------------------
#  DESHACER Y VISTA COMPACTA (`vQoL()`)
# ---------------------------------------------------------------------------
#
# DESHACER: la pila y sus reglas viven en `ui/principal/ciclo_partida.gd`
# (fase 0); el puente `_pila_deshacer` está en `principal_p10.gd`.

## LA TIPOGRAFIA. Siete, y la primera es la de siempre.
##
## Se resuelven con `SystemFont`, que pide fuentes al sistema operativo por
## nombre y va probando la lista hasta que una existe. Por eso cada entrada
## lleva varios nombres: «Segoe UI» es de Windows, «Helvetica Neue» de macOS y
## «DejaVu Sans» de Linux, y la ultima de cada lista es el nombre generico, que
## el sistema siempre sabe resolver por algo.
##
## LA TRAMPA DE LOS EMOJI. La interfaz esta llena de simbolos -⚙, ⚽, 🎨- que la
## fuente de fabrica de Godot trae dentro. Una fuente del sistema puede no
## traerlos, asi que a todas se les cuelga «Segoe UI Emoji» y compania como
## repuesto; y por si aun asi fallara, «Del juego» -la de siempre- se queda como
## primera opcion y por defecto.
const TIPOGRAFIAS := {
	"juego":     ["Del juego (por defecto)", []],
	"sistema":   ["Del sistema", ["Segoe UI", "Helvetica Neue", "Cantarell", "sans-serif"]],
	"diario":    ["De diario (serif)", ["Georgia", "Times New Roman", "Liberation Serif", "serif"]],
	"estrecha":  ["Estrecha (cabe mas)", ["Arial Narrow", "Roboto Condensed", "DejaVu Sans Condensed", "sans-serif"]],
	"redonda":   ["Redonda y grande", ["Verdana", "Tahoma", "DejaVu Sans", "sans-serif"]],
	"informe":   ["De informe (mono)", ["Consolas", "Menlo", "DejaVu Sans Mono", "monospace"]],
	"titular":   ["De titular", ["Impact", "Haettenschweiler", "DejaVu Sans Bold", "sans-serif"]],
}

## Los nombres de repuesto para los simbolos. Se anaden al final de cualquier
## lista: si la fuente elegida no tiene el engranaje, lo saca de aqui.
const REPUESTO_SIMBOLOS := ["Segoe UI Emoji", "Segoe UI Symbol", "Apple Color Emoji", "Noto Color Emoji"]

var _tipografia: String = "juego"
static var _fuentes: Dictionary = {}

## LA VISTA COMPACTA. No es un tema aparte: es el mismo `Theme` con las
## separaciones y los márgenes apretados. Se aplica a la raíz, así que baja por
## todos los contenedores de golpe y no hay que tocar una sola pantalla.
##
## No toca los tamaños de letra a propósito. Encoger la letra hace que quepa más
## y que no se lea nada; lo que sobra en esta interfaz es el aire entre filas.
var _vista_compacta: bool = false

const SEPARACION_NORMAL := 4
const SEPARACION_COMPACTA := 1


# ---------------------------------------------------------------------------
#  ACCESIBILIDAD Y TRASPASO DE LA PARTIDA (`vAjustes()`)
# ---------------------------------------------------------------------------

## Multiplicador del tamaño de letra. Es distinto del zoom de interfaz: el zoom
## agranda la ventana entera —botones, márgenes y todo—, y esto agranda SOLO el
## texto, que es lo que hace falta cuando el problema es leer, no alcanzar.
##
## Funciona porque toda la interfaz pasa por `_texto()`: un multiplicador ahí
## llega a las mil y pico etiquetas del juego sin tocar una sola pantalla.
var _escala_texto: float = 1.0
const ESCALAS_TEXTO := [0.85, 1.0, 1.15, 1.30]

## Paleta para daltonismo. El verde y el rojo del juego son EXACTAMENTE el par
## que un deuteranope no distingue, y este juego los usa para lo más importante
## que hay: si un número está bien o está mal. Se cambian por azul cielo y
## bermellón, el par de Okabe-Ito, que se separa en cualquier tipo de daltonismo.
##
## Se remapea dentro de `_texto()` en vez de en las mil llamadas: los colores son
## constantes y el sitio por donde pasan todas es uno solo.
var _daltonico: bool = false
const COL_VERDE_DALT := Color("56b4e9")
const COL_ROJO_DALT := Color("d55e00")
const COL_ORO_DALT := Color("e69f00")


# ---------------------------------------------------------------------------
#  MANDO, TÁCTIL Y FOTOGRAMAS
# ---------------------------------------------------------------------------
#
# «Táctil en móvil, mouse, teclado, control inalámbrico o con conexión de cable,
# todos deben ser compatibles, además configuración en ajustes de fotogramas».
# Es del documento de instrucciones, y de las cuatro formas de jugar solo había
# dos: ratón y teclado.
#
# EL TÁCTIL se resuelve en `project.godot` con `emulate_mouse_from_touch`: toda
# la interfaz son botones, así que convertir el toque en clic la hace jugable
# entera de un plumazo.
#
# EL MANDO no. Godot mueve el foco entre controles con las acciones `ui_*`, y
# las trae mapeadas a teclado pero NO a joypad. Se añaden aquí, en código, para
# no depender de que el mapa de entrada del proyecto se toque a mano: cruceta y
# stick izquierdo para moverse, A para pulsar, B para volver, gatillos para
# cambiar de pestaña.

## Las acciones de navegación con mando. Cada una es [accion, boton o eje].
const MANDO_BOTONES := [
	["ui_accept", JOY_BUTTON_A],
	["ui_cancel", JOY_BUTTON_B],
	["ui_up", JOY_BUTTON_DPAD_UP],
	["ui_down", JOY_BUTTON_DPAD_DOWN],
	["ui_left", JOY_BUTTON_DPAD_LEFT],
	["ui_right", JOY_BUTTON_DPAD_RIGHT],
]

## Las dos que no existen en Godot y hacen falta aquí: cambiar de pestaña con
## los gatillos, que es lo que convierte un menú de dieciocho pestañas en algo
## manejable desde el sofá.
const MANDO_PESTANAS := [
	["dinastia_tab_anterior", JOY_BUTTON_LEFT_SHOULDER, KEY_Q],
	["dinastia_tab_siguiente", JOY_BUTTON_RIGHT_SHOULDER, KEY_E],
]

## BUG REAL, encontrado y corregido el 11-9-2026: el comentario de `_input()`
## de más abajo decía "L1/R1... cambian de BLOQUE MAESTRO", pero L1/R1 ya
## estaban tomados por `MANDO_PESTANAS` de aquí arriba -el chip, nivel 2-, así
## que ese chequeo nunca se disparaba con un mando: quedaba código muerto, y
## el jugador con mando no tenía NINGUNA forma de cambiar de bloque maestro
## (nivel 1, los seis bloques fijos) sin tocar la pantalla. Con L1/R1 ya
## ocupados, el gatillo de hombro que queda libre es el analógico -L2/R2-, un
## nivel más abajo en el mando y en la jerarquía del menú al mismo tiempo.
const MANDO_BLOQUES := [
	["dinastia_bloque_anterior", JOY_AXIS_TRIGGER_LEFT],
	["dinastia_bloque_siguiente", JOY_AXIS_TRIGGER_RIGHT],
]

## Lo acumulado del desliz en curso. Se reinicia al levantar el dedo.
var _arrastre_x: float = 0.0
var _arrastre_y: float = 0.0

## EL LÍMITE DE FOTOGRAMAS. En un portátil, dejar el juego a 300 fps calienta la
## máquina para dibujar la misma tabla trescientas veces por segundo. Treinta
## basta para una interfaz; sesenta para el estadio en 3D.
const FPS_OPCIONES := [30, 60, 120, 0]
var _fps_elegido: int = 60
