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


const MODOS_SIMULACION := TablasMenu.MODOS_SIMULACION
const SECCION_SIMULACION := "simulacion"


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
## ninguna abierta: un `ui/principal/rueda_prensa.gd` (fase 0, paso 6b).
const _PrincipalRuedaPrensa := preload("res://ui/principal/rueda_prensa.gd")
var _rueda_pop: Control = null




const ETIQUETAS_ESTADIO := TablasMenu.ETIQUETAS_ESTADIO

static var _muestras: Dictionary = {}
const SECC_RECORDS := TablasMenu.SECC_RECORDS
var _secc_records: String = "records"

const VACIO_RECORDS := TablasMenu.VACIO_RECORDS


const BUSES_AUDIO := TablasMenu.BUSES_AUDIO

## AJUSTES (fase 0, paso 2): las tipografías, las ranuras y el límite de
## fotogramas viven en `PantallaAjustes`; estos puentes conservan el contrato
## que usan `preferencias.gd`, las pruebas y el resto de capas.
var _tipografia: String:
	get: return _ui_ajustes.tipografia
	set(v): _ui_ajustes.tipografia = v
var _fps_elegido: int:
	get: return _ui_ajustes.fps_elegido
	set(v): _ui_ajustes.fps_elegido = v

## `vQoL()`: la interfaz a tu medida. Dos interruptores y los favoritos.
##
## MODO EXPERTO no oculta funciones, oculta EXPLICACIONES. Las notas de "esto
## sirve para tal" son imprescindibles la primera temporada y estorban a partir
## de la quinta; quitarlas es la diferencia entre una pantalla que enseña y una
## que deja trabajar.
var _modo_experto: bool = false
var _favoritos: Array[String] = []
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
## El setter lo vuelca en `Tema.escala_texto`: así llega también a lo que se
## pinta con `Tema.etiqueta`/`Tema.rotulo` (móvil, avisos, pantallas nuevas).
var _escala_texto: float = 1.0:
	set(v):
		_escala_texto = v
		Tema.escala_texto = v
const ESCALAS_TEXTO := [0.85, 1.0, 1.15, 1.30]

## Paleta para daltonismo. El verde y el rojo del juego son EXACTAMENTE el par
## que un deuteranope no distingue, y este juego los usa para lo más importante
## que hay: si un número está bien o está mal. Se cambian por azul cielo y
## bermellón, el par de Okabe-Ito, que se separa en cualquier tipo de daltonismo.
##
## Se remapea dentro de `_texto()` en vez de en las mil llamadas: los colores son
## constantes y el sitio por donde pasan todas es uno solo.
## Igual que la escala: se vuelca en `Tema.daltonico` para `Tema.accesible()`.
var _daltonico: bool = false:
	set(v):
		_daltonico = v
		Tema.daltonico = v
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

const MANDO_BOTONES := TablasMenu.MANDO_BOTONES

const MANDO_PESTANAS := TablasMenu.MANDO_PESTANAS

const MANDO_BLOQUES := TablasMenu.MANDO_BLOQUES

