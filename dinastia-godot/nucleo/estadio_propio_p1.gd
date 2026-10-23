extends RefCounted
## [Capa 1/3 de `estadio_propio.gd`] en_obras, hecho, avanzar_semana, terminar_obra, _mismo, semanas_de … (+5)

## El estadio de TU club: el único del mundo que no sale de un hash.
##
## `Club.perfil_estadio()` deriva el recinto de cada club del hash de su id, y
## para los rivales está bien: así el estadio de Coquimbo es siempre el mismo
## partido tras partido. Pero el tuyo no puede ser una casualidad. Esta clase es
## la que te deja DISEÑARLO —forma, bandejas, techo, césped, butacas, focos,
## pantalla, vallas, la hora del día— y la que hace que cambiarlo cueste dinero,
## que es lo que separa un editor de skins de una decisión de club.
##
## EL CONTRATO CON EL VISOR 3D. `perfil()` devuelve exactamente las claves que
## consume `visor/stadium_builder.gd` y `visor/ambience.gd`:
##   build_pitch() -> cesped, cespedClaro, cespedOscuro, lineaCol, arcoCol,
##                    redCol, redTipo, corner, banquillo, tunel, escudoDonde
##   build()       -> forma, niveles, techo, asientoP, asiento1, asiento2,
##                    asiento3, vallas, focos, pantalla, bandejas (opcional),
##                    tramos (opcional), escudoDonde
##   altura_de()   -> niveles
##   Ambience      -> clima, focos
##   VistaEstadio  -> aforo, forma, niveles, techo
##   estadio.gd    -> sonidoGol (elige el efecto de `Sonido` en cada gol propio)
## Ni una clave de más ni una de menos respecto de lo que ya se lee ahí. Si el
## visor pide una clave que no está, no falla: pone su valor por defecto y el
## estadio sale distinto del que diseñaste, que es peor que un error.
##
## `bandejas` (16-9-2026, "el estadio por MÓDULOS", Fase 1 de 3 del ROADMAP:
## bandeja → componentes → tramo) es la ÚNICA clave opcional del contrato: solo
## aparece cuando `personalizar_bandejas` está activo, y solo entonces
## `StadiumBuilder.build()` la mira. Con el interruptor apagado -el caso de
## siempre, y el de CUALQUIER estadio rival- `perfil()` no cambia una sola
## clave respecto a como era antes de esta fase.
##
## `redTipo`/`corner`/`banquillo`/`tunel`/`escudoDonde` (16-9-2026, Fase 2:
## "Componentes") YA estaban en `ajustes`, ya se cobraban y ya se pintaban en
## el diseñador -pero `perfil()` nunca se las pasaba al visor, así que hasta
## esta fase no cambiaban nada en 3D. Los defaults que usa
## `StadiumBuilder` para estas 5 claves cuando faltan (siempre, para
## cualquier rival) son EXACTAMENTE el dibujo único que ya existía antes de
## esta fase -salvo `escudoDonde`, que no existía como dibujo: su default ahí
## es "sin", no el "cancha" de fábrica de `EST_DEF`, a propósito, para que
## nadie vea aparecer un escudo que nunca pidió.
##
## `tramos` (22-9-2026, Fase 3: "Tramo") es la SEGUNDA clave opcional del
## contrato, con el mismo criterio que `bandejas`: solo aparece cuando
## `personalizar_tramos` está activo. Es independiente de `personalizar_
## bandejas` -se puede mezclar patrones por tercios en una tribuna sin haber
## tocado el estilo global de ninguna, y viceversa-. El spike del 18-9
## (`LEEME.md`, "SPIKE CORRIDO CON PANTALLA REAL") confirmó que el corte se
## sostiene visualmente con una condición: `StadiumBuilder` tiene que generar
## la textura de esa tribuna con `uv1_scale.y=1` (sin repetir), no con el
## repetido-cada-20m de una tribuna de un solo patrón.
##
## EL AFORO NO ES SUYO. Lo gestiona `Instalaciones`: la obra "trib" da +15% por
## nivel y `aplicar()` lo escribe en `Club.estadio_aforo`. Aquí solo se LEE del
## club y se le aplica el factor de forma, que sí es una decisión de diseño (un
## óvalo cabe más gente que una herradura). Duplicar el aforo aquí sería la
## forma más rápida de que la taquilla y el estadio 3D dejaran de coincidir.

signal reforma_hecha(cambios: Dictionary, coste: int, aviso: String)
signal movimiento(concepto: String, monto: int)
signal renombrado(nombre: String)

## Nombre del recinto. Vacío = "Estadio " + el nombre del club, igual que el
## `G.estadioNom||('Estadio '+...)` del HTML. Bautizarlo no cuesta nada: es lo
## único de esta pantalla que es solo tuyo.
var nombre: String = ""

## El diseño entero, con LAS MISMAS CLAVES que `G.est` en el HTML, sembrado de
## la tabla `EST_DEF` exportada. Es un diccionario y no treinta campos con
## nombre a propósito: el catálogo de opciones vive en `tablas.json`, así que si
## el juego añade mañana un tipo de techo aparece solo, sin tocar esta clase.
var ajustes: Dictionary = {}

## LAS REFORMAS TARDAN (8-10-2026). Pedido: «el estadio al entrar, al jugar y
## fuera del 3D debe ser el mismo; solo cambia cuando el usuario lo cambia, y
## eso tarda tiempo de construcción». `ajustes` es el PROYECTO (lo que enseña
## el diseñador); mientras dura la obra, el estadio que se ve y se juega en
## todas partes es `obra["antes"]` (lo construido), con andamios. La pintura
## (cal, redes, banderas, la hora, el sonido del gol) no es obra: es al momento.
##   obra = {antes: {ajustes construidos}, semanas: int, total: int, capitulos: []}
var obra: Dictionary = {}

## Semanas de obra por capítulo (se toma el más largo del paquete).
const SEMANAS_OBRA := {
	"obra": 10, "bandeja": 12, "techo": 8, "fachada": 8, "focos": 4,
	"pantalla": 3, "superficie": 3, "butacas": 3, "cesped": 2,
	"mobiliario": 1, "vallas": 1, "personalizacion": 2, "personalizacion_tramos": 2,
}

## --- QUÉ CUESTA CADA REFORMA -----------------------------------------------
## El HTML no cobraba nada por rediseñar (era una maqueta: se tocaba un desplegable
## y el estadio cambiaba de alma gratis). Aquí sí se cobra, porque un estadio que
## se rehace gratis no es una decisión, es un menú de opciones.
##
## Los precios NO son inventados de cero: están anclados al catálogo de obras que
## ya está equilibrado en `Instalaciones.CATALOGO` —la tribuna vale 600.000 y la
## calidad del estadio 260.000—, y como todo coste operativo del juego pasan por
## `Eco.escalar()`, así que rehacer el recinto de un grande cuesta lo que su
## tamaño y no una cifra plana.
const PRECIO := {
	"obra": 480000.0,      ## mover el graderío de sitio: forma, pista, túnel
	"bandeja": 380000.0,   ## por cada bandeja NUEVA que se levanta
	"techo": 320000.0,
	"focos": 150000.0,
	"pantalla": 210000.0,
	"mobiliario": 70000.0,
	"vallas": 40000.0,
	"cesped": 60000.0,     ## resembrar: el patrón y el tono son la misma faena
	"butacas": 90000.0,    ## rebutacar el recinto entero
	"pintura": 0.0,        ## cal, redes, banderas y la hora del partido: gratis
	## Encender el modo "cada tribuna distinta" es una decisión de diseño, no un
	## interruptor gratis -si fuera pintura, cambiarlo y volver a apagarlo sería
	## una forma barata de esquivar el precio de una reforma real.
	"personalizacion": 90000.0,
	## Mismo criterio que "personalizacion" (bandejas) pero para "Mezclar
	## patrones por tercios" (tramos): una decisión más fina -12 campos contra
	## 8- así que vale más que el interruptor de bandejas, pero sigue muy por
	## debajo de una obra real (no se levanta ni un ladrillo, solo cambia la
	## textura de la grada).
	"personalizacion_tramos": 130000.0,
	## B6: revestir la fachada entera es obra de verdad; cambiar la
	## superficie del campo es levantar el césped y poner otro.
	"fachada": 420000.0,
	"superficie": 260000.0,
}

## A qué capítulo de obra pertenece cada opción del diseñador. Lo que no esté
## aquí es pintura, o sea gratis: es la respuesta segura si mañana aparece una
## opción nueva en el catálogo.
const CAPITULO := {
	"forma": "obra", "pista": "obra", "tunel": "obra",
	"niveles": "bandeja",
	"techo": "techo",
	"focos": "focos",
	"pantalla": "pantalla",
	"banquillo": "mobiliario",
	"vallas": "vallas",
	"cesped": "cesped", "cespedTono": "cesped",
	"asientoP": "butacas", "asiento1": "butacas", "asiento2": "butacas",
	"asiento3": "butacas", "mosaico": "butacas",
	"personalizar_bandejas": "personalizacion",
	"bandeja_sur_asientoP": "butacas", "bandeja_sur_techo": "techo",
	"bandeja_norte_asientoP": "butacas", "bandeja_norte_techo": "techo",
	"bandeja_este_asientoP": "butacas", "bandeja_este_techo": "techo",
	"bandeja_oeste_asientoP": "butacas", "bandeja_oeste_techo": "techo",
	"personalizar_tramos": "personalizacion_tramos",
	## Los 12 tercios son, en plata, la misma faena que rebutacar -eligen un
	## patrón de asiento, no levantan nada-, así que pagan el mismo capítulo
	## "butacas" que `asientoP`/`bandeja_<lado>_asientoP`.
	"tramo_sur_1": "butacas", "tramo_sur_2": "butacas", "tramo_sur_3": "butacas",
	"tramo_norte_1": "butacas", "tramo_norte_2": "butacas", "tramo_norte_3": "butacas",
	"tramo_este_1": "butacas", "tramo_este_2": "butacas", "tramo_este_3": "butacas",
	"tramo_oeste_1": "butacas", "tramo_oeste_2": "butacas", "tramo_oeste_3": "butacas",
	## B6. Los colores sueltos son pintura (gratis), salvo las butacas de una
	## tribuna, que se cambian una a una.
	"fachada": "fachada", "superficie": "superficie", "luzFocos": "focos",
	"bandeja_sur_col1": "butacas", "bandeja_sur_col2": "butacas",
	"bandeja_norte_col1": "butacas", "bandeja_norte_col2": "butacas",
	"bandeja_este_col1": "butacas", "bandeja_este_col2": "butacas",
	"bandeja_oeste_col1": "butacas", "bandeja_oeste_col2": "butacas",
	## COLORES POR SECCIÓN (28-9-2026): cada anillo de cada tribuna se repinta
	## por separado (butacas), y las vallas y la estructura de los focos son
	## pintura.
	"anillo_sur_1": "butacas", "anillo_sur_2": "butacas", "anillo_sur_3": "butacas", "anillo_sur_4": "butacas", "anillo_sur_5": "butacas",
	"anillo_norte_1": "butacas", "anillo_norte_2": "butacas", "anillo_norte_3": "butacas", "anillo_norte_4": "butacas", "anillo_norte_5": "butacas",
	"anillo_este_1": "butacas", "anillo_este_2": "butacas", "anillo_este_3": "butacas", "anillo_este_4": "butacas", "anillo_este_5": "butacas",
	"anillo_oeste_1": "butacas", "anillo_oeste_2": "butacas", "anillo_oeste_3": "butacas", "anillo_oeste_4": "butacas", "anillo_oeste_5": "butacas",
	"vallaCol": "fachada", "focosCol": "fachada",
}

## De qué tabla salen las opciones válidas de cada campo. Sirve para dos cosas:
## llenar los desplegables de la interfaz y, sobre todo, no dejar que llegue al
## visor una forma que no sabe construir —`geom_de_forma()` caería en su rama
## por defecto y te dibujaría un cuenco donde pediste una herradura.
const CATALOGO_DE := {
	"forma": "EST_FORMAS", "techo": "EST_TECHOS", "asientoP": "EST_ASIENTOS",
	"cesped": "EST_CESPED", "cespedTono": "EST_TONOS", "focos": "EST_FOCOS",
	"pantalla": "EST_PANTALLAS", "clima": "EST_CLIMAS", "banderas": "EST_BANDERAS",
	"corner": "EST_CORNER", "banquillo": "EST_BANQUILLOS", "tunel": "EST_TUNELES",
	"escudoDonde": "EST_ESCUDOS", "redTipo": "EST_REDTIPO",
	"lineaCol": "EST_LINEAS", "arcoCol": "EST_ARCOS", "redCol": "EST_REDES",
	"sonidoGol": "EST_SONIDOS",
	"bandeja_sur_asientoP": "EST_ASIENTOS", "bandeja_sur_techo": "EST_TECHOS",
	"bandeja_norte_asientoP": "EST_ASIENTOS", "bandeja_norte_techo": "EST_TECHOS",
	"bandeja_este_asientoP": "EST_ASIENTOS", "bandeja_este_techo": "EST_TECHOS",
	"bandeja_oeste_asientoP": "EST_ASIENTOS", "bandeja_oeste_techo": "EST_TECHOS",
	## Los tercios eligen patrón de butaca, nunca techo -el spike confirmó que
	## techo/fachada/altura siguen siendo del recinto entero, ver el contrato
	## de `perfil()` más arriba-, así que los 12 comparten el mismo catálogo
	## que `asientoP`.
	"tramo_sur_1": "EST_ASIENTOS", "tramo_sur_2": "EST_ASIENTOS", "tramo_sur_3": "EST_ASIENTOS",
	"tramo_norte_1": "EST_ASIENTOS", "tramo_norte_2": "EST_ASIENTOS", "tramo_norte_3": "EST_ASIENTOS",
	"tramo_este_1": "EST_ASIENTOS", "tramo_este_2": "EST_ASIENTOS", "tramo_este_3": "EST_ASIENTOS",
	"tramo_oeste_1": "EST_ASIENTOS", "tramo_oeste_2": "EST_ASIENTOS", "tramo_oeste_3": "EST_ASIENTOS",
}

## --- B6 (25-9-2026, plan maestro): EL ESTADIO POR SECCIONES ------------------
## Pedido del usuario (ROADMAP 2-sexies): *"cambiar colores por sección, arco,
## líneas, bandejas una por una, césped, pantalla, faros, luces nocturnas, LED,
## bancas, gradas, asientos"*. Los catálogos nuevos viven AQUÍ y no en
## `tablas.json` (que es la exportación del HTML y se regenera): así no se
## pierden al volver a exportar. Tampoco entran en `aleatorio()`, que recorre
## solo `CATALOGO_DE`: el botón "sorpréndeme" consume el mismo azar que antes.
const PALETA := [
	["", "Del club", "Hereda los colores de la camiseta."],
	["#ffffff", "Blanco"], ["#d8d8d8", "Gris claro"], ["#5a5f66", "Grafito"],
	["#1b1d22", "Negro"], ["#c9a227", "Dorado"], ["#b01e2d", "Rojo"],
	["#1f4fa3", "Azul"], ["#7fdcff", "Celeste"], ["#2b6b45", "Verde"],
	["#e8c21a", "Amarillo"], ["#e07b2a", "Naranja"], ["#6b2d8f", "Morado"],
	["#8a4a2b", "Terracota"],
]
const TABLAS_B6 := {
	"EST_FACHADAS": [
		["hormigon", "Hormigón visto", "El de siempre: gris, sobrio y barato de mantener."],
		["ladrillo", "Ladrillo", "Obra vista de estadio inglés de barrio."],
		["vidrio", "Muro cortina de vidrio", "Estadio de ciudad moderna: de noche brilla por dentro."],
		["membrana", "Membrana de lona", "Piel tensada sobre la estructura, como las arenas alemanas."],
		["metal", "Chapa metálica", "Paneles de acero con juntas marcadas."],
	],
	"EST_LUCES": [
		["neutra", "Blanca de televisión", "5.600 K: la de las transmisiones."],
		["calida", "Cálida", "Amarillenta, de estadio de los noventa."],
		["fria", "Fría", "Azulada, de LED moderno."],
		["club", "Del color del club", "Los focos se tiñen con el primer color de la camiseta."],
	],
	"EST_SUPERFICIES": [
		["natural", "Césped natural", "Lo clásico. Sufre con los conciertos y el mal tiempo."],
		["hibrido", "Césped híbrido", "Natural cosido con fibra: menos lesiones y aguanta el uso."],
		["artificial", "Césped artificial", "No se estropea nunca, pero castiga las articulaciones: más lesiones."],
	],
	"EST_PALETA": PALETA,
	## Paleta de las vallas LED (MEGAPLAN B6). Es programación de la pantalla,
	## no obra: gratis, como la pintura.
	"EST_LED": [
		["marcas", "Patrocinadores", "Cada marca con su color, como en la tele."],
		["club", "Colores del club", "Todo el anillo con los dos colores de la camiseta."],
		["neon", "Neón nocturno", "Paneles negros y letras de neón que cambian de color."],
		["oro", "Negro y oro", "Elegante, de final: blanco y dorado sobre negro."],
		["retro", "Cartel pintado", "Fondo blanco y letras de chapa, de estadio de los ochenta."],
		["arcoiris", "Multicolor", "Cada panel de un color distinto, en ola por todo el anillo."],
		["propia", "A tu gusto", "Eliges el color del fondo y el de las letras (abajo)."],
	],
}
## Las claves nuevas y su valor de fábrica. "" en un color = hereda.
const DEF_B6 := {
	"fachada": "hormigon", "fachadaCol": "", "techoCol": "", "luzFocos": "neutra",
	"banquilloCol": "", "superficie": "natural",
	"bandeja_sur_col1": "", "bandeja_sur_col2": "",
	"bandeja_norte_col1": "", "bandeja_norte_col2": "",
	"bandeja_este_col1": "", "bandeja_este_col2": "",
	"bandeja_oeste_col1": "", "bandeja_oeste_col2": "",
	"anillo_sur_1": "", "anillo_sur_2": "", "anillo_sur_3": "", "anillo_sur_4": "", "anillo_sur_5": "",
	"anillo_norte_1": "", "anillo_norte_2": "", "anillo_norte_3": "", "anillo_norte_4": "", "anillo_norte_5": "",
	"anillo_este_1": "", "anillo_este_2": "", "anillo_este_3": "", "anillo_este_4": "", "anillo_este_5": "",
	"anillo_oeste_1": "", "anillo_oeste_2": "", "anillo_oeste_3": "", "anillo_oeste_4": "", "anillo_oeste_5": "",
	"vallaCol": "", "focosCol": "", "ledPaleta": "marcas", "ledFondo": "", "ledTinta": "",
}
const CATALOGO_B6 := {
	"fachada": "EST_FACHADAS", "fachadaCol": "EST_PALETA", "techoCol": "EST_PALETA",
	"luzFocos": "EST_LUCES", "banquilloCol": "EST_PALETA", "superficie": "EST_SUPERFICIES",
	"bandeja_sur_col1": "EST_PALETA", "bandeja_sur_col2": "EST_PALETA",
	"bandeja_norte_col1": "EST_PALETA", "bandeja_norte_col2": "EST_PALETA",
	"bandeja_este_col1": "EST_PALETA", "bandeja_este_col2": "EST_PALETA",
	"bandeja_oeste_col1": "EST_PALETA", "bandeja_oeste_col2": "EST_PALETA",
	"anillo_sur_1": "EST_PALETA", "anillo_sur_2": "EST_PALETA", "anillo_sur_3": "EST_PALETA", "anillo_sur_4": "EST_PALETA", "anillo_sur_5": "EST_PALETA",
	"anillo_norte_1": "EST_PALETA", "anillo_norte_2": "EST_PALETA", "anillo_norte_3": "EST_PALETA", "anillo_norte_4": "EST_PALETA", "anillo_norte_5": "EST_PALETA",
	"anillo_este_1": "EST_PALETA", "anillo_este_2": "EST_PALETA", "anillo_este_3": "EST_PALETA", "anillo_este_4": "EST_PALETA", "anillo_este_5": "EST_PALETA",
	"anillo_oeste_1": "EST_PALETA", "anillo_oeste_2": "EST_PALETA", "anillo_oeste_3": "EST_PALETA", "anillo_oeste_4": "EST_PALETA", "anillo_oeste_5": "EST_PALETA",
	"vallaCol": "EST_PALETA", "focosCol": "EST_PALETA", "ledPaleta": "EST_LED",
	"ledFondo": "EST_PALETA", "ledTinta": "EST_PALETA",
}
## Cuánto multiplica cada superficie la probabilidad de lesión en TU campo.
const LESION_POR_SUPERFICIE := {"natural": 1.0, "hibrido": 0.85, "artificial": 1.3}
## Y cuánto del desgaste del césped (conciertos, `Ciudad.penalizacion_cesped`)
## llega al juego: el artificial no se estropea, el híbrido aguanta la mitad.
const DESGASTE_POR_SUPERFICIE := {"natural": 1.0, "hibrido": 0.5, "artificial": 0.0}

## LOS OCHO ESTILOS NUEVOS (B6.6): de 16 a 24. Mismo formato que `EST_PRESETS`.
const PRESETS_B6 := [
	["coliseo", "🏛️ Coliseo", "Óvalo de piedra clara, arcos en la fachada y anillo de luz cálida.",
		{"forma": "oval", "niveles": 3, "techo": "anillo", "fachada": "hormigon", "fachadaCol": "#d8d8d8",
		"luzFocos": "calida", "focos": "corona", "asientoP": "franjas", "cesped": "circular", "banderas": "club", "redTipo": "cuadrada", "escudoDonde": "fachada"}],
	["caja_inglesa", "📦 Caja inglesa", "Cuatro tribunas de ladrillo pegadas a la raya, techo a dos aguas.",
		{"forma": "rect", "niveles": 2, "techo": "parcial", "fachada": "ladrillo", "techoCol": "#1b1d22",
		"luzFocos": "neutra", "focos": "torres", "asientoP": "mosaico", "cesped": "rayasH", "clima": "lluvia", "redTipo": "cuadrada", "escudoDonde": "fachada"}],
	["ladera", "⛰️ Estadio de ladera", "Herradura abierta a la montaña, hormigón gris y viento de altura.",
		{"forma": "herradura", "niveles": 2, "techo": "sin", "fachada": "hormigon", "fachadaCol": "#5a5f66",
		"luzFocos": "fria", "focos": "torres", "cesped": "liso", "clima": "niebla", "redTipo": "rombo", "escudoDonde": "grada"}],
	["flotante", "🌊 Estadio flotante", "Cuenco blanco de vidrio sobre el agua, focos azules y halo LED.",
		{"forma": "cuenco", "niveles": 2, "techo": "visera", "fachada": "vidrio", "techoCol": "#d8d8d8",
		"luzFocos": "fria", "focos": "halo", "superficie": "hibrido", "asientoP": "degrade", "redTipo": "cuadrada", "escudoDonde": "cancha"}],
	["cupula", "🔘 Cúpula", "Cubierta total retráctil, membrana blanca y césped híbrido: aquí no llueve.",
		{"forma": "cuenco", "niveles": 4, "techo": "retractil", "fachada": "membrana", "techoCol": "#ffffff",
		"luzFocos": "neutra", "focos": "corona", "superficie": "hibrido", "redTipo": "cuadrada", "escudoDonde": "techo"}],
	["desierto", "🏜️ Estadio del desierto", "Chapa dorada, luz cálida y césped artificial que no se quema.",
		{"forma": "oval", "niveles": 3, "techo": "membrana", "fachada": "metal", "fachadaCol": "#c9a227",
		"techoCol": "#d8d8d8", "luzFocos": "calida", "focos": "mixto", "superficie": "artificial", "clima": "dia", "redTipo": "cuadrada", "escudoDonde": "fachada"}],
	["concreto", "🇦🇷 Hormigón sudamericano", "Caldera de hormigón crudo, paravalanchas y focos cálidos de los setenta.",
		{"forma": "caldera", "niveles": 3, "techo": "sin", "fachada": "hormigon", "fachadaCol": "#5a5f66",
		"luzFocos": "calida", "focos": "torres", "banderas": "tifo", "asientoP": "aros", "redTipo": "gruesa", "escudoDonde": "grada"}],
	["nipon", "🗾 Japonés moderno", "Fachada de lona sobre madera clara, techo en visera y luz fría.",
		{"forma": "oval", "niveles": 3, "techo": "visera", "fachada": "membrana", "fachadaCol": "#ffffff",
		"techoCol": "#8a4a2b", "luzFocos": "fria", "focos": "halo", "cesped": "damGrande", "redTipo": "rombo", "escudoDonde": "cancha"}],
]

## Las 4 tribunas, en el mismo orden e índices que `visor/stadium_builder.gd`
## comenta en su array `stands` (0=sur 1=norte 2=este 3=oeste) -mismo nombre a
## los dos lados del contrato para no tener que traducir un índice a un lado.
const LADOS_BANDEJA := ["sur", "norte", "este", "oeste"]

## Butacas por bandeja que el visor considera justificadas. Es el mismo número
## que usa `StadiumBuilder.niveles_de()`, y está aquí repetido a propósito: si
## el diseñador ofreciera una bandeja que el visor no va a dibujar, la pantalla
## de diseño estaría mintiendo.
const BUTACAS_POR_BANDEJA := 22000.0
## CINCO, NO TRES (23-9-2026). Pedido del usuario: *"habrá que hacerle más
## bandejas y variantes para cuando uno agrande el estadio (máximo 150.000)"*.
## El techo de aforo del juego cuadra con eso: `Instalaciones` da +15% por nivel
## de tribuna hasta el nivel 5 (×1,75) y la forma añade hasta ×1,14, así que un
## club grande llega a ~150.000. Con 22.000 butacas por bandeja, ese aforo pide
## siete bandejas; cinco es donde se corta, que es lo que tienen los estadios
## más grandes del mundo de verdad.
##
## Esto SOLO fue posible después de rehacer el graderío por bandejas en
## `StadiumBuilder`: con el modelo viejo -una rampa única de 11 m de fondo- una
## cuarta bandeja habría sido una pared de 65 grados. Ver `LEEME.md`, 23-9.
const NIVELES_MAX := 5

## EL ESTADIO REAL DE TU CLUB (26-9-2026): al tomar un club que representa a
## uno real, tu estadio arranca con la arquitectura del real (forma, bandejas,
## techo, pista, focos, fachada). Una sola vez por club: después es tuyo y lo
## que reformes no se pisa.
var real_de: String = ""

## Formas nuevas (MEGAPLAN B6), con el mismo formato que `EST_FORMAS` de
## `tablas.json` (que se regenera desde el HTML: por eso viven aquí).
const FORMAS_B6 := [
	["dos", "Dos tribunas", "Solo las laterales; detrás de los arcos, cielo abierto. Barato y con poco ruido.", 3, "lados", 0.72],
	["principal", "Tribuna de honor", "Cuatro tribunas y una principal con una bandeja más, la de los banquillos.", 6, "lados", 1.0],
	["estrecho", "Caja inglesa", "Cuatro tribunas pegadas al césped: poco aforo y mucho ruido.", 4, "lados", 0.85],
	["asimetrico", "Asimétrico", "Una tribuna de honor más alta y un fondo a cielo abierto.", 5, "lados", 0.92],
]

func en_obras() -> bool:
	return not obra.is_empty() and int(obra.get("semanas", 0)) > 0

## Lo que está CONSTRUIDO (lo que se ve y se juega).
func hecho() -> Dictionary:
	return obra["antes"] if en_obras() else ajustes

## Pasa una semana de obra. Devuelve true la semana en que termina: desde ahí
## el proyecto ES el estadio.
func avanzar_semana() -> bool:
	if not en_obras():
		return false
	obra["semanas"] = int(obra["semanas"]) - 1
	if int(obra["semanas"]) <= 0:
		obra = {}
		return true
	return false

## Termina la obra en curso de golpe (pruebas y herramientas). true siempre.
func terminar_obra() -> bool:
	obra = {}
	return true

## Compara respetando el tipo. Sin esto, un `false` guardado y un `"false"` del
## desplegable parecerían cambios distintos y se cobraría una reforma que no
## cambia nada.
func _mismo(a: Variant, b: Variant) -> bool:
	if a is bool or b is bool:
		return bool(a) == bool(b)
	if (a is int or a is float) and (b is int or b is float):
		return is_equal_approx(float(a), float(b))
	return String(a) == String(b)

## Semanas que tardaría este paquete de cambios (0 = es pintura).
func semanas_de(cambios: Dictionary) -> int:
	var sem := 0
	for campo: String in cambios:
		if not ajustes.has(campo) or _mismo(ajustes[campo], cambios[campo]):
			continue
		var cap := "bandeja" if campo == "niveles" else String(CAPITULO.get(campo, "pintura"))
		sem = maxi(sem, int(SEMANAS_OBRA.get(cap, 0)))
	return sem

func _sembrar_b6() -> void:
	for k: String in DEF_B6:
		if not ajustes.has(k):
			ajustes[k] = DEF_B6[k]

## Arranca del EST_DEF exportado. Si por lo que sea no está la tabla, se usa un
## diseño mínimo que el visor sepa construir: quedarse sin estadio por una tabla
## que falta sería el peor de los fallos posibles.
func _sembrar() -> void:
	var def: Variant = Datos.tabla("EST_DEF")
	if def is Dictionary:
		ajustes = (def as Dictionary).duplicate(true)
		_sembrar_b6()
	else:
		ajustes = {
			"forma": "cuenco", "niveles": 2, "techo": "anillo", "pista": false,
			"asientoP": "franjas", "asiento1": "", "asiento2": "", "asiento3": "#20272a",
			"cesped": "rayas", "cespedTono": "vivo", "lineaCol": "#ffffff",
			"arcoCol": "#ffffff", "redCol": "#ffffff", "focos": "torres",
			"pantalla": "dos", "clima": "noche", "banderas": "club", "vallas": true,
		}
		_sembrar_b6()

func _init() -> void:
	_sembrar()

func _tabla(nombre_tabla: String) -> Array:
	if TABLAS_B6.has(nombre_tabla):
		return TABLAS_B6[nombre_tabla]
	var t: Variant = Datos.tabla(nombre_tabla)
	if nombre_tabla == "EST_FORMAS" and t is Array:
		return (t as Array) + FORMAS_B6
	return t if t is Array else []

## Una fila del catálogo por su clave, con la primera como red de seguridad: es
## el `EST_TONOS.find(...)||EST_TONOS[0]` del HTML, y existe porque un tono que
## ya no está en la tabla no puede dejar el césped sin color.
func _fila(nombre_tabla: String, clave: String) -> Array:
	var filas := _tabla(nombre_tabla)
	for f: Array in filas:
		if f.size() > 0 and String(f[0]) == clave:
			return f
	if filas.is_empty():
		return []
	return filas[0] as Array
