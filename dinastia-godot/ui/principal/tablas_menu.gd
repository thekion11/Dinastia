class_name TablasMenu
extends RefCounted
## Las tablas fijas de la pantalla principal (paletas, formas, rótulos del estadio, récords, mando...).
## Salen de `Principal` en la fase 6, paso 7 del plan §7.1 (27-10-2026); `Principal` las sigue
## exponiendo con el mismo nombre (`const X := TablasMenu.X`), así que nadie más cambia.

## Los nombres largos de cada atributo -`AT_LARGO` en vistas.js-, compartidos
## entre la ficha y el comparador para no mantener la misma tabla dos veces.
const NOMBRES_ATRIBUTOS := {
	"rit": "Ritmo", "tir": "Tiro", "pas": "Pase", "reg": "Regate", "def": "Defensa", "fis": "Físico",
	"div": "Estirada", "par": "Paradas", "saq": "Saque", "ref": "Reflejos", "vel": "Salidas", "pos": "Colocación",
}

## LOS CINCO MODOS DE MIRAR UN PARTIDO (plan maestro B2): [clave, rótulo, qué es].
const MODOS_SIMULACION := [
	["instantaneo", "⚡ Instantáneo", "Solo el resultado, al momento."],
	["resumen", "📋 Resumen", "Las jugadas clave, una a una, en 20 segundos."],
	["vivo", "📻 En vivo", "Crónica, cambios, arengas y charla, sin 3D."],
	["destacados", "🎬 3D destacados", "El estadio a x4, frena en cada ocasión."],
	["completo", "🏟 3D completo", "El partido entero en el estadio."],
]

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

const VACIO_RECORDS := {
	"memoria": "📜 Aquí quedará la memoria del club: el salón de la fama, lo que pasó un día como hoy y el plantel de cada temporada. Se llena a medida que juegas.",
	"rivales": "⚔️ El cara a cara con cada rival aparece en cuanto te enfrentes a él.",
	"vitrina": "🏆 Los goleadores de tu era y los que más partidos juegan aparecen al avanzar la temporada.",
	"records": "📈 Las rachas y las marcas del club se registran desde el primer partido.",
}

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

## clave -> [nombre, fondo, panel, borde, texto, texto suave]
const PALETAS := {
	"bosque":   ["Bosque (por defecto)", "0c1510", "141c16", "ffffff12", "e9eeea", "8ea595"],
	"pizarra":  ["Pizarra", "10141a", "181d25", "ffffff14", "e8ecf2", "8e97a5"],
	"carbon":   ["Carbón", "0e0e10", "17171a", "ffffff10", "ececec", "9a9a9e"],
	"vino":     ["Vino", "17090d", "231218", "ffffff14", "f2e8ea", "a88e93"],
	"marino":   ["Marino", "081420", "0f2030", "ffffff14", "e6eef5", "8ba0b0"],
	"tierra":   ["Tierra", "16110b", "221a12", "ffffff12", "f0e9df", "a8917a"],
	"papel":    ["Papel (claro)", "e8e5dd", "f5f3ec", "00000018", "1e2420", "5a6259"],
	"cuaderno": ["Cuaderno de gestión", "e3e0d4", "f2efe3", "00000022", "23281f", "60664f"],
	"neon":     ["Neón", "0a0612", "150d22", "ffffff18", "efe8ff", "9c8fb8"],
	## CONTRASTE ALTO (s3, 26-10-2026; accesibilidad básica): negro puro, texto
	## blanco, el suave casi blanco y bordes marcados. Se enciende también desde
	## Ajustes → Accesibilidad (`AjustesAcceso.contraste`).
	"contraste": ["Contraste alto", "000000", "000000", "ffffffb0", "ffffff", "d8e0dc"],
	## LAS SEIS DE GEMINI (`ModuloEsteticaUI` del documento "Visual gemini" en
	## Drive, 11-9-2026): a diferencia de las nueve de arriba -que solo cambian
	## de tinte y dejan el borde en blanco/negro translúcido, neutro- estas
	## traen un borde de un color saturado propio, que es justo lo que se ve
	## en las capturas que mandó el usuario. Se integran como seis paletas MÁS,
	## no como un sistema aparte: la nota de arriba ("las paletas no pisan el
	## color del club") sigue valiendo -el acento del club sigue viniendo de
	## `COL_ACENTO`/`_con_contraste()`, esto solo tiñe fondo/panel/borde-.
	"esports":    ["eSports", "0d1620", "121b27", "10b981cc", "e8f5ee", "7fae95"],
	"ejecutivo":  ["Ejecutivo", "141a26", "1b2333", "f59e0bcc", "f5ecd9", "b3a37f"],
	"cibernetico":["Cibernético", "0d0818", "150f24", "00e5ffcc", "eafcff", "8fb8c2"],
	"transmision":["Transmisión", "0c1220", "121a2c", "ef4444cc", "fbecec", "c28f8f"],
	"pizarra_gr": ["Pizarra gris", "0e131c", "141a24", "374151", "e6e9ee", "8b93a0"],
	"minimo":     ["Mínimo", "0a0c10", "0f1216", "1f2937", "e3e6e8", "7a828c"],
}

## Cuánto se redondean las tarjetas. Es el detalle que más cambia el «carácter»
## de una interfaz sin tocar un solo color.
const FORMAS_TARJETA := {
	"redonda":  ["Redondeada", 8, 1],
	"suave":    ["Muy suave", 14, 1],
	"recta":    ["Recta", 0, 1],
	"marcada":  ["Borde marcado", 6, 2],
	"sinborde": ["Sin borde", 8, 0],
}

## LA PESTAÑA "GENTE", PARTIDA EN SUBMENÚS (10-9-2026). Antes cuatro funciones
## sin relación -personas de carne y hueso, identidad visual, explotación
## comercial, y "el club por dentro" (vestuario/prensa/palco)- se apilaban las
## cuatro seguidas bajo un nombre que solo describe a la primera: nadie que
## busque "cambiar el patrocinador de la camiseta" mira en una pestaña
## llamada "Gente". Mismo mecanismo de chips que ya usa Ajustes
## (`SECCIONES_AJUSTES`), clonado en vez de inventar uno nuevo.
const SECCIONES_GENTE := [
	["personas", "👥 Personas"],
	["identidad", "🎨 Identidad y camiseta"],
	["comercial", "💰 Comercial"],
	["interno", "🚪 El club por dentro"],
]

## Tres pantallas del HTML compartían un solo chip y una sola lista: `vSocial`
## (feed + funa + gabinete de comunicación), `vPrensa` (periodistas, medios
## propios, vocero, derechos de TV, portadas, año contado) y `vDebate` (mesa
## de televisión, ranking de entrenadores, el influencer que mueve seguidores).
## Se pinta TODO seguido, como siempre, y esto esconde lo que no toca -mismo
## truco que `_filtrar_records()`, apoyado en que cada sección empieza con un
## Label de título conocido-. El bloque de arriba de todo -seguidores, funa,
## ánimo, prestigio DT- no lleva título propio y por eso se ve siempre: es la
## cabecera de la pantalla, no una sección.
const SECC_REDES := {
	"redes": ["GABINETE DE COMUNICACIÓN", "LO QUE SE DICE"],
	"prensa": ["🎙️ LA PRENSA", "📡 MEDIOS PROPIOS", "🎤 QUIÉN DA LA CARA",
		"📺 DERECHOS DE TELEVISIÓN", "🗞️ ARCHIVO DE PORTADAS", "📖 EL AÑO CONTADO"],
	"debate": ["📺 MESA DE DEBATE", "🏅 RANKING DE ENTRENADORES", "📱 LO QUE DICEN LOS QUE MUEVEN MASAS"],
}
