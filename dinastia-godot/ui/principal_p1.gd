extends Control
## (Parte 1 de 18 de `principal.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `principal.gd`, conserva la clase.)

## Las pantallas que viven en `ui/pantallas/` (mapa de metas 15).
var _ui_plantel := PantallaPlantel.new(self)
var _ui_ficha := PantallaFicha.new(self)
var _ui_despacho := PantallaDespacho.new(self)
var _ui_club_vida := PantallaClubVida.new(self)
var _ui_club_estadio := PantallaClubEstadio.new(self)
var _ui_cantera := PantallaCantera.new(self)
var _ui_legado := PantallaLegado.new(self)
var _ui_ciudad := PantallaCiudad.new(self)
var _ui_editor := PantallaEditor.new(self)
var _ui_opciones := PantallaOpciones.new(self)
var _ui_ajustes := PantallaAjustes.new(self)
var _ui_identidad := PantallaIdentidad.new(self)
var _ui_gente := PantallaGente.new(self)
var _ui_finanzas := PantallaFinanzas.new(self)
## La pantalla del juego: plantel, mercado, tabla y ficha de jugador.
##
## Todo se construye con nodos Control por código. En el HTML esto eran cadenas
## de texto con etiquetas dentro (`vPlantel()` devolvía HTML como string y el
## navegador lo parseaba en cada repintado). Aquí son nodos de verdad.
##
## No sabe nada de cómo se simula un partido ni de cómo se tasa un jugador: se lo
## pregunta al núcleo y pinta la respuesta. Por eso el mismo núcleo corre igual
## aquí que en el banco de pruebas headless, donde no hay pantalla ninguna.

## La paleta es la misma del HTML (`css/estilo.css`, `:root`), no una inventada
## para Godot: la mudanza tiene que dejar el juego IGUAL de verlo, y mejorar
## solo por dentro (clases de verdad, nativo en vez de DOM). `--bg`, `--panel`,
## `--line`, `--tx`, `--mut`, `--verde`, `--rojo`, `--oro` calcados tal cual.
const COL_FONDO := Tema.FONDO
## Los paneles son casi opacos, no translúcidos: el fondo se intuye por los
## bordes y entre columnas, pero la tabla, el registro y la ficha se leen igual
## de bien con cualquiera de los catorce fondos detrás. Un 0,94 deja pasar lo
## justo para que se note que hay algo, sin que compita con el texto.
const COL_PANEL := Color("141c16", 0.94)
const COL_BORDE := Tema.BORDE
const COL_TEXTO := Tema.TEXTO
const COL_SUAVE := Tema.SUAVE
## El acento de la interfaz sale del color del club que diriges: es lo que hace
## que dirigir a Colo-Colo y dirigir a la U no se vean igual. Con el negro se
## hace una excepcion, como en el HTML: sobre fondo oscuro un acento negro no se
## ve, asi que se cambia por un gris claro. Sin club -o con uno sin acento claro-
## el valor por defecto es el `--acc` del HTML, no un azul inventado.
var COL_ACENTO := Color("3fa06a")
const COL_VERDE := Tema.BIEN
const COL_ROJO := Tema.MAL
const COL_ORO := Tema.ORO

## Los nombres largos de cada atributo -`AT_LARGO` en vistas.js-, compartidos
## entre la ficha y el comparador para no mantener la misma tabla dos veces.
const NOMBRES_ATRIBUTOS := {
	"rit": "Ritmo", "tir": "Tiro", "pas": "Pase", "reg": "Regate", "def": "Defensa", "fis": "Físico",
	"div": "Estirada", "par": "Paradas", "saq": "Saque", "ref": "Reflejos", "vel": "Salidas", "pos": "Colocación",
}

## La pantalla de inicio deja aquí la partida cargada antes de cambiar de
## escena -no hay otra forma de pasarle un argumento a una escena que arranca
## sola por `run/main_scene`-. Si sigue vacía, se entra con mundo nuevo.
static var mundo_a_cargar: Mundo = null
## Lo mismo, pero para el modo de carrera elegido en la pantalla previa
## (`ui/seleccion_modo.gd`). Vacío = el DT clásico de siempre, para que abrir
## `principal.tscn` directo -como sigue haciendo el banco de capturas- no
## dependa de haber pasado por esa pantalla.
static var modo_elegido: String = ""
## La tarjeta "Tutorial" del menú: la próxima carrera arranca con el recorrido
## guiado aunque ya se haya visto (ver `ui/componentes/tutorial.gd`).
static var tutorial_pedido: bool = false
## "Crear tu Club" desde el menú: la elección de club abre con el panel de
## fundar arriba y destacado (26-9-2026).
static var fundar_pedido: bool = false
## El reto elegido en el menú (`Retos`): la elección de club lo monta sola.
static var reto_pedido: String = ""
static var dt_nombre_elegido: String = "Míster"
static var dificultad_elegida: String = "normal"
## Del asistente completo (`ui/eleccion_club.gd`): el mundo YA generado -las 24
## ligas- y con `tomar_el_mando()` ya hecho sobre el club que se eligió a mano.
## A esto solo le falta aplicar dificultad y modo, que es lo que hace
## `_arrancar_con()`. Se comprueba ANTES que `mundo_a_cargar` en `_ready()`
## porque son mutuamente excluyentes -nunca deberían venir los dos a la vez-
## y da igual el orden real; se listan así porque es el camino más nuevo.
static var mundo_pregenerado: Mundo = null
## Los desafíos marcados en `ui/eleccion_club.gd`, paso 5 del asistente del
## HTML. Vacío = partida normal, igual que los demás canales.
static var desafios_elegidos: Array[String] = []

var mundo: Mundo
var _seleccionado: Jugador
## Si alguna vez se tradujo a otro idioma en esta sesión. Mientras siga en
## falso y el idioma sea castellano, `_traducir_pantalla` no recorre nada -es
## la mayoría de las partidas, que nunca tocan el selector de idioma-.
var _traduccion_activa := false
## Id del jugador con la rescisión a medio confirmar -"doble toque" del HTML,
## como vender el club o borrar la partida: la primera pulsación solo avisa,
## la segunda ejecuta-. Se limpia sola en cuanto se ve otra ficha.
var _confirmar_rescision_id: String = ""
## El mismo doble toque, para "Vender el club" -`vista.confVender` del HTML-.
var _confirmar_venta_club: bool = false
## `Q.comp` del HTML: hasta tres jugadores -tuyos o de cualquier club- puestos
## a comparar desde su ficha. Vive solo en memoria, como en el HTML -no es
## parte de la partida, se vacía sola al cerrar el juego-.
var _comparar_ids: Array[String] = []
var _libres_filtro := "todos"
## El resultado de la última ronda enviada en la mesa de negociación, para
## poder mostrarlo bajo el panel hasta la próxima ronda -Negociacion.
## enviar_oferta() devuelve el qué pasó, pero no lo guarda: aquí es donde vive
## mientras se ve en pantalla.
var _negociacion_ultimo: Dictionary = {}
## Que el aviso de "fin de partida" (desafío invicto) salga una sola vez y no
## en cada repintado -_refrescar() se llama todo el rato.
var _fin_partida_avisado := false

var _cabecera: Label
var _lbl_caja: Label
var _saldo_mostrado := -1
var _lbl_fecha: Label
var _escudo_cabecera: Control
var _sub: Label
var _selector: OptionButton
var _botones: HBoxContainer
var _pestanas: TabContainer
var _lista_plantel: VBoxContainer
## El panel de mercado vive ahora como componente propio (ui/componentes/panel_mercado.gd).
## Se comunica con Principal exclusivamente por señales; el estado de filtros
## y el último resultado de negociación son internos al componente.
var _panel_mercado: PanelMercado = null
var _lista_copa: VBoxContainer
var _lista_club: VBoxContainer
var _lista_conti: VBoxContainer
var _lista_medico: VBoxContainer
var _lista_logros: VBoxContainer
var _lista_entren: VBoxContainer
var _lista_fed: VBoxContainer
var _lista_estadio: VBoxContainer
var _lista_seleccion: VBoxContainer
var _lista_cantera: VBoxContainer
var _lista_contratos: VBoxContainer
var _lista_comparar: VBoxContainer
var _lista_records: VBoxContainer
var _lista_legado: VBoxContainer
## `vInicio()`: la portada del club, lo primero que se mira al abrir la semana.
var _lista_inicio: VBoxContainer
## `vSocial()`: el termómetro de lo que se dice de ti fuera del estadio.
var _lista_redes: VBoxContainer
var _lista_vida: VBoxContainer
var _lista_habilidades: VBoxContainer
var _secc_vida: String = "bienestar"
## `vGente()`: las diez personas que llevan aquí más años que tú.
var _lista_gente: VBoxContainer
## La retirada no se puede deshacer, así que el boton pide confirmacion como el
## de vender el club: primero avisa, y solo el segundo clic la ejecuta.
var _confirmar_retiro: bool = false
var _lista_finanzas: VBoxContainer
var _lista_camarin: VBoxContainer
var _lista_partido: VBoxContainer
var _lista_calendario: VBoxContainer
var _lista_ciudad: VBoxContainer
var _lista_editor: VBoxContainer
var _lista_glosario: VBoxContainer
var _lista_ajustes: VBoxContainer
var _lista_correo: VBoxContainer
var _lista_libres: VBoxContainer
var _lista_premios: VBoxContainer
var _lista_clubes: VBoxContainer
var _lista_desafios: VBoxContainer
var _lista_tactica: VBoxContainer
var _clubes_pais := ""
var _clubes_ficha: Club = null
var _autoguardado := false
## `vCorreo()` del HTML lee `G.noticias`, poblado por su función
## `noticia(titulo,cuerpo)` en **372 sitios** del juego. Aquí el motor solo
## dispara los ~20 avisos que ya conecta `_conectar_noticias()` -ponerlos al
## día con los 372 sería motor nuevo, no interfaz-, así que esta bandeja es
## fiel al MECANISMO (filtrar, marcar leído, orden más-nuevo-primero) con la
## cobertura que el motor realmente tiene hoy. Vive solo en esta sesión de
## juego, no en el guardado -igual que `_autoguardado`, no toca el esquema de
## `Mundo` que prueba a fondo "GUARDAR Y CARGAR"-.
var _bandeja: Array[Dictionary] = []
const BANDEJA_MAX := 60
var _correo_filtro := "todo"

## Los cinco grupos del HTML (`TABS_ORDEN`/`subsDe()`: club/plantel/partido/
## finanzas/mundo), portados como agrupación de verdad y no solo de nombre:
## antes las 18 pestañas vivían todas al mismo nivel, en una tira que había
## que desplazar con flechas -nada que ver con la barra de cinco del HTML,
## cada una con su propio submenú-. Los NOMBRES de cada pestaña siguen siendo
## los de siempre (`_hoja(_pestanas, "Mercado")`...): esto solo cambia cómo se
## llega a ellas, no lo que pintan, así que ningún banco de pruebas ni captura
## que ya buscaba una pestaña por su título dejó de servir.
## EL MENÚ CENTRAL DE DOBLE NIVEL (10-9-2026, formato pedido por el usuario).
##
## Nivel 1: SEIS bloques maestros fijos, ni uno más -esa fue su condición-.
## Nivel 2: chips dinámicos del bloque activo, en un carril que se desplaza a
## dedo (Android) o con L2/R2 (mando), porque HISTORIA sola trae diez.
##
## Un chip no es una pestaña: es {tab, secc, label}. `tab` es la pestaña real
## del `TabContainer` -los títulos internos NO se tocan, porque medio archivo
## y las capturas los buscan por nombre-, `secc` es la sección dentro de esa
## pestaña (el mismo mecanismo de chips que ya usaban Ajustes y Gente), y
## `label` es lo único que ve el jugador. Así se puede reorganizar el menú
## entero sin renombrar una sola pestaña ni romper `_ir_a_pestana()`.
const GRUPOS := [
	{"id": "central", "icono": "🏠", "nombre": "CENTRAL", "tabs": [
		{"tab": "Inicio", "label": "Inicio"},
		{"tab": "Club", "secc": "carrera", "label": "Mi Carrera"},
		{"tab": "Correo", "label": "Correo"},
		{"tab": "Glosario", "label": "Glosario"},
		{"tab": "Federación", "label": "Normas"},
	]},
	{"id": "club", "icono": "⚽", "nombre": "CLUB", "tabs": [
		{"tab": "Estadio", "label": "Estadio"},
		{"tab": "Club", "secc": "infra", "label": "Infraestructura"},
		{"tab": "Ciudad", "label": "Diseño 3D"},
		{"tab": "Gente", "secc": "interno", "label": "El club por dentro"},
		{"tab": "Club", "secc": "directorio", "label": "Directorio"},
	]},
	{"id": "gente", "icono": "👥", "nombre": "GENTE", "tabs": [
		{"tab": "Club", "secc": "staff", "label": "Personal del Club"},
		{"tab": "Gente", "secc": "personas", "label": "La gente del club"},
		{"tab": "Gente", "secc": "identidad", "label": "Identidad Visual"},
		{"tab": "Gente", "secc": "kits", "label": "Equipación"},
		## Mismo chip de siempre, con la etiqueta corregida: llevaba a la pantalla
		## correcta -clima del vestuario, camarillas, capitán- pero con el
		## nombre de otra cosa. "Muro" es `vMuro()` del HTML -el muro de
		## campeones-, y ESE ya vive en HISTORIA → Memoria (`Logros.muro`,
		## sección "SALÓN DE LA FAMA DEL CLUB"): un chip más ahí habría sido la
		## duplicidad que pidió evitar el usuario.
		{"tab": "Camarín", "label": "Camarín"},
	]},
	{"id": "historia", "icono": "📈", "nombre": "HISTORIA", "tabs": [
		{"tab": "Legado", "label": "Historia"},
		{"tab": "Récords", "secc": "records", "label": "Récords"},
		{"tab": "Récords", "secc": "memoria", "label": "Memoria"},
		{"tab": "Récords", "secc": "rivales", "label": "Rivales"},
		{"tab": "Récords", "secc": "vitrina", "label": "Vitrina"},
		{"tab": "Cantera", "label": "Linaje"},
		{"tab": "Logros", "label": "Logros"},
		{"tab": "Desafíos", "label": "Desafíos"},
		{"tab": "Premios", "label": "Premios"},
	]},
	{"id": "operaciones", "icono": "📊", "nombre": "OPERACIONES", "tabs": [
		{"tab": "Estadio", "label": "Hinchada y Socios"},
		{"tab": "Redes", "secc": "redes", "label": "Feed de Redes"},
		## Las tres vivían amontonadas bajo un solo chip -"Feed de Redes"- que
		## pintaba de un tirón el feed, la sala de prensa (periodistas, medios
		## propios, vocero, derechos de TV, portadas) y la mesa de debate: tres
		## pantallas del HTML (`vSocial`, `vPrensa`, `vDebate`) sin ninguna
		## separación. El motor de las tres ya estaba escrito en `prensa.gd`
		## desde antes; solo faltaban chips propios -mismo patrón que
		## `_filtrar_records()` para Récords-.
		{"tab": "Redes", "secc": "prensa", "label": "Sala de Prensa"},
		{"tab": "Redes", "secc": "debate", "label": "El Ruido de Fuera"},
		{"tab": "Comparar", "label": "Comparar"},
	]},
	## MI VIDA (26-9-2026): tu vida de entrenador fuera del club y tu árbol de
	## habilidades, que es tuyo y no del club.
	{"id": "vida", "icono": "🧑", "nombre": "MI VIDA", "tabs": [
		{"tab": "Vida", "secc": "bienestar", "label": "Bienestar"},
		{"tab": "Vida", "secc": "hogar", "label": "Casa y auto"},
		{"tab": "Vida", "secc": "familia", "label": "Familia"},
		{"tab": "Habilidades", "label": "Habilidades"},
	]},
	{"id": "ajustes", "icono": "⚙️", "nombre": "AJUSTES", "tabs": [
		{"tab": "Ajustes", "secc": "pantalla", "label": "Dispositivo"},
		{"tab": "Ajustes", "secc": "audio", "label": "Sonido"},
		{"tab": "Ajustes", "secc": "aspecto", "label": "Interfaz"},
		{"tab": "Editor", "label": "Editor"},
	]},
]

## LOS HUBS CONTEXTUALES. El día a día -plantel, partido, plata, tabla- no
## entra por la barra de arriba: entra tocando la zona de la pantalla que ya
## habla de eso, como en FC26. Es la decisión que permitió dejar el nivel 1 en
## seis bloques exactos sin que ninguna pantalla quedara inalcanzable.
const HUBS := {
	"plantel": {"titulo": "👔 PLANTEL", "tabs": [
		"Mi plantel", "Táctica", "Entrenar", "Enfermería", "Camarín", "Cantera", "Contratos"]},
	"partido": {"titulo": "⚽ PARTIDO", "tabs": ["Partido", "Calendario"]},
	"dinero": {"titulo": "💰 DINERO", "tabs": ["Finanzas", "Mercado", "Libres"]},
	"competiciones": {"titulo": "🏆 COMPETICIONES", "tabs": [
		"Clubes", "Copa", "Continental", "Selección", "Federación"]},
}
var _fila_grupos: HBoxContainer
var _fila_sub: HBoxContainer
var _grupo_actual: String = "central"
## El despacho: la decision pendiente y la rueda de prensa. Van arriba del todo,
## por encima de las pestanas, porque son cosas que hay que resolver AHORA — si
## se esconden en una pestana, el jugador no las ve y el sistema no existe.
var _despacho: VBoxContainer
var _lista_tabla: VBoxContainer
## El encabezado de la columna izquierda, que cambia con la competición que se
## juega esa semana. `_ultimo_titulo_columna` es solo el puente para cogerlo al
## construirla.
var _titulo_tabla: Label
var _ultimo_titulo_columna: Label
var _ultima_caja_columna: VBoxContainer

## El fondo de pantalla. `""` significa "ninguno": el verde plano de siempre,
## para quien prefiera la interfaz sin nada detrás.
var _fondo_escena: TextureRect
var _fondo_elegido: String = "nocturna"

## El clima elegido y si sigue al raton. Van aparte del fondo dibujado: se
## combinan, no se sustituyen.
var _clima: FondoAnimado = null
var _clima_elegido: String = "motas"
var _clima_interactivo: bool = true

## La clave que marca "no quiero uno fijo, quiero que vaya cambiando". Va
## como valor especial de `_fondo_elegido` y no como un booleano aparte para
## que el guardado de preferencias siga siendo el mismo campo de siempre.
const ROTAR_FONDO := "*rotar*"

# ---------------------------------------------------------------------------
#  EL CALENDARIO EN DÍAS
# ---------------------------------------------------------------------------
#  El motor lleva SEMANAS, no días: `Mundo.semana` es un entero y todo -la
#  jornada, la moral, el mercado, las obras- late a ese ritmo. El usuario
#  pidió ver la fecha y poder avanzar de a un día, como en su HTML.
#
#  La solución no toca el motor: el DÍA es de la interfaz. Avanzar un día
#  mueve el calendario dentro de la semana, y al pasar del domingo se llama
#  al `_avanzar_semana()` de siempre, que es el que hace correr el mundo. Así
#  se ve un calendario de verdad sin partir en dos la simulación -que es
#  exactamente el tipo de cambio que este proyecto no puede permitirse-.
var _fila_dias: HBoxContainer
const DIAS_CORTOS := ["lun", "mar", "mié", "jue", "vie", "sáb", "dom"]
## La tira de días usa el nombre entero y el número (pedido del usuario,
## 25-9-2026: "los nombres de los días están recortados").
const DIAS_LARGOS := ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
const MESES_LARGOS := ["enero", "febrero", "marzo", "abril", "mayo", "junio",
	"julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"]
const MESES_CORTOS := ["ene", "feb", "mar", "abr", "may", "jun",
	"jul", "ago", "sep", "oct", "nov", "dic"]
## La temporada arranca el 1 de febrero, como el calendario chileno.
const DIA_INICIO_TEMPORADA := {"mes": 2, "dia": 1}
var _dia_semana: int = 0
var _dia_pintado: int = -1
var _ficha: VBoxContainer
var _registro: RichTextLabel

## UNA PÍLDORA DEL MENÚ. Es la estética que el usuario mandó de su propio
## HTML: cápsula muy redondeada, oscura y con borde tenue cuando está en
## reposo, y CLARA con letra oscura cuando está activa -el contraste
## invertido es lo que hace que se lea de un vistazo cuál estás mirando-.
##
## El ancho mínimo sale del largo del rótulo: en un `HBoxContainer` dentro de
## un `ScrollContainer`, un botón sin ancho propio colapsa a cero y el carril
## sale como una fila de rectángulos vacíos -ya pasó una vez hoy-.
## LOS ESTILOS DE MENÚ (10-9-2026). El usuario los pidió "compatibles y
## modulares": el mismo menú, la misma navegación y los mismos chips, con
## tres vestidos distintos. Como TODO el menú pasa por `_pildora()`, cambiar
## de estilo es cambiar una constante y repintar -no hay tres menús, hay uno
## con tres pieles-.
const ESTILOS_MENU := [
	["pildora", "Píldoras redondeadas"],
	["compacto", "Compacto (más aire)"],
	["barra", "Barra clásica (recta)"],
]
var _estilo_menu: String = "pildora"

## EL MENÚ CENTRAL CAMBIA DE ESTÉTICA CADA 10 MINUTOS (29-9-2026, mapa de
## metas 24). Pedido: que de forma nativa vaya rotando entre sus diseños. Cada
## diseño junta lo que ya se elegía por separado en Ajustes → Interfaz:
## [paleta, estilo del menú, forma de las tarjetas, fondo]. Cuenta tiempo de
## juego (el temporizador se para si el juego se pausa) y se puede apagar.
const DISENOS_CENTRAL := [
	["bosque", "pildora", "redonda", "nocturna"],
	["esports", "barra", "recta", "neon"],
	["ejecutivo", "pildora", "suave", "trofeo"],
	["marino", "compacto", "marcada", "tunel"],
	["transmision", "barra", "redonda", "tifo"],
	["vino", "pildora", "suave", "vestuario"],
	["cibernetico", "compacto", "recta", "ciudad"],
	["tierra", "pildora", "redonda", "amanecer"],
]
const ROTAR_CADA := 600.0
var _rotar_diseno := true
var _diseno_i := 0
var _reloj_diseno: Timer

## EL MENÚ COMO PÁGINAS. El usuario lo pidió así: "debe poder moverse hacia
## los lados como si fueran páginas... es nuestro centro de mando". Cambiar
## de bloque desliza el contenido hacia el lado del que viene -a la izquierda
## si vas hacia adelante, a la derecha si vuelves- y lo desvanece un punto.
var _marco_paginas: MarginContainer
## La columna de la ficha, para mudarla a los menús a pantalla completa.
var _col_derecha: Control
var _menu_lateral: MenuLateral

# --- tutorial guiado (ui/componentes/tutorial.gd) ---------------------------

## Los controles que el tutorial señala, por clave. Se guardan al construir la
## pantalla; los que ya tenían variable propia se resuelven en el momento.
var _tut_nodos: Dictionary = {}
var _tutorial: Tutorial = null

## El mismo buscar-por-título que ya usaban capturas y pruebas desde fuera
## (`tabs.get_tab_title(i)`); centralizado aquí porque ahora también lo usa la
## barra de grupos.
## El buscador global. Busca primero entre JUGADORES y luego entre clubes,
## porque el 90% de las veces se busca a una persona; si no aparece ninguno, se
## prueba con clubes antes de rendirse.
##
## No es "contiene el texto" a secas: se prefiere el que EMPIEZA por lo escrito.
## Buscando "vidal" uno quiere a Vidal, no al primero de los cuarenta que lleven
## esas cinco letras en algún sitio del apellido.
var _buscador: LineEdit

## Se dispara con CUALQUIER cambio de pestaña -tocando el submenú, o a mano
## desde una captura/prueba que hace `tabs.current_tab = i` directamente-, así
## que la barra de grupos nunca queda desincronizada de lo que en verdad se
## está viendo.
## Lo que se ve cambió (pestaña o ficha): lo escucha el panel de objetivos.
signal vista_cambiada

## SUELO DE CONTRASTE. Los colores que quedan -el acento del club, el oro de un
## titulo, el rojo de una deuda- no se traducen: significan algo y hay que
## respetarlos. Pero un acento CLARO -el blanco de Colo-Colo, el amarillo de un
## Boca- sobre una paleta clara desaparece, y el nombre de tu propio equipo en la
## tabla se volvia ilegible justamente por ser el tuyo.
##
## Asi que no se cambia el color: se empuja hacia el lado contrario del panel
## hasta que se separa lo justo. El tono se reconoce igual -sigue siendo el rojo
## de tu club, mas oscuro- y se lee.
const SALTO_LUMA := 0.42
