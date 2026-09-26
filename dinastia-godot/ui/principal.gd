class_name Principal
extends Control
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

func _acento_de(c: Club) -> Color:
	if c == null:
		return Color("3fa06a")
	## El acento va POR SEPARADO del color del club si se ha elegido uno: es la
	## cuarta capa de la identidad -club, uniforme, escudo e interfaz-.
	var col := Color(c.color_acento())
	if col.get_luminance() < 0.10:
		return Color("e0e0e0")
	## Y si el color del club es muy apagado, se le sube la saturacion: un acento
	## que no se distingue del texto normal no es un acento.
	if col.s < 0.25:
		col.s = 0.45
	return col.lightened(0.15) if col.get_luminance() < 0.35 else col
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

func _aplicar_fondo() -> void:
	if _clima != null:
		_clima.modo = _clima_elegido
		_clima.interactivo = _clima_interactivo
		_clima.ajustar_area(size if size.x > 0.0 else Vector2(1280, 720))
		_clima.aplicar()
	if _fondo_escena == null:
		return
	## EL FONDO ROTATIVO. El usuario pidió poder elegir entre uno fijo o que
	## "vaya cambiando". La rotación NO usa `Azar` -eso movería la simulación
	## entera, la trampa que ya costó una depuración con el feed de redes-:
	## sale de la semana de juego, que da un fondo distinto cada domingo,
	## siempre el mismo para la misma partida.
	if _fondo_elegido == ROTAR_FONDO:
		var nombres: Array = Fondo.NOMBRES
		if nombres.is_empty():
			_fondo_escena.texture = null
			return
		var i := (mundo.semana if mundo != null else 0) % nombres.size()
		_fondo_escena.texture = Fondo.textura(String(nombres[i]))
		return
	_fondo_escena.texture = Fondo.textura(_fondo_elegido) if _fondo_elegido != "" else null

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

## La fecha de hoy, derivada: inicio de temporada + semanas corridas + días.
func fecha_de_hoy() -> Dictionary:
	return fecha_del_dia(_dia_semana)

## La fecha de cualquier día (0 = lunes) de la semana en curso.
func fecha_del_dia(dia: int) -> Dictionary:
	return Calendario.fecha(mundo.anio if mundo != null else 2026, mundo.semana if mundo != null else 1, dia)

func fecha_larga() -> String:
	var f := fecha_de_hoy()
	var dow := int(f.get("weekday", 1))
	## `weekday` de Godot es 0=domingo; aquí la semana empieza en lunes.
	var idx := (dow + 6) % 7
	## Entera y sin abreviar: "lunes 26 de enero de 2026".
	return "%s %d de %s de %d" % [String(DIAS_LARGOS[idx]).to_lower(), int(f["day"]),
		MESES_LARGOS[int(f["month"]) - 1], int(f["year"])]

## Los siete días con el de hoy encendido. El sábado lleva el balón porque es
## cuando cae la jornada: sin esa marca, la tira sería un adorno.
func _pintar_dias() -> void:
	if _fila_dias == null:
		return
	_limpiar(_fila_dias)
	var hay_partido := mundo != null and (not mundo.proximo_partido().is_empty()
		or not mundo.partido_de_copa().is_empty())
	for i in DIAS_CORTOS.size():
		var es_hoy := i == _dia_semana
		var dia_de_partido := i == 5 and hay_partido
		## C13: el día nacional, de memoria o festivo, con su icono y el nombre
		## al pasar el ratón.
		var fechas_dia := Calendario.del_dia(mundo.mi_club().pais if mundo != null and mundo.mi_club() != null else "CHI",
			mundo.anio if mundo != null else 2026, mundo.semana if mundo != null else 1, i)
		var marca := ""
		for fd: Dictionary in fechas_dia:
			marca += " " + Calendario.icono(String(fd["tipo"]))
		var b := _pildora("%s %d%s%s" % [DIAS_LARGOS[i], int(fecha_del_dia(i).get("day", 1)), marca, "  ⚽" if dia_de_partido else ""], 11, 26)
		if not fechas_dia.is_empty():
			b.tooltip_text = "\n".join(fechas_dia.map(func(fd: Dictionary) -> String: return String(fd["nombre"])))
		b.button_pressed = es_hoy
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if es_hoy and _dia_pintado != _dia_semana:
			_dia_pintado = _dia_semana
			(func() -> void: Animar.pulso(b, 1.1)).call_deferred()
		if dia_de_partido and not es_hoy:
			b.add_theme_color_override("font_color", _color_de_paleta(COL_ORO))
		## Tocar un día futuro avanza hasta ahí; uno pasado no hace nada -el
		## tiempo no vuelve atrás, y un botón que miente es peor que uno que
		## no está-.
		var destino := i
		b.disabled = destino <= _dia_semana
		b.pressed.connect(func() -> void:
			while _dia_semana < destino:
				_avanzar_dia())
		_fila_dias.add_child(b)

## Avanza UN día. Si con eso se pasa del domingo, la semana del motor corre de
## verdad -es el único punto donde esto toca la simulación-.
func _avanzar_dia() -> void:
	if mundo == null or not mundo.temporada_en_curso():
		_escribir("[color=#e05555]La temporada está terminada. Pulsa «Temporada siguiente».[/color]")
		return
	if _dia_semana >= 6:
		_dia_semana = 0
		_avanzar_semana()
		return
	_dia_semana += 1
	## LA PORTADA DEL DÍA SIGUIENTE (B5): la frase de la rueda, citada.
	if mundo.prensa != null and not mundo.prensa.titular_pendiente.is_empty():
		var tit := mundo.prensa.publicar_titular_pendiente()
		Aviso.mostrar(self, "prensa", "🗞️", "La portada de hoy", tit)
	_refrescar()
var _ficha: VBoxContainer
var _registro: RichTextLabel

func _ready() -> void:
	## El mando se prepara ANTES de construir la interfaz: las acciones `ui_*`
	## tienen que existir cuando aparezca el primer boton para que el foco se
	## pueda mover con la cruceta desde el primer momento.
	_preparar_mando()
	## Las preferencias se leen ANTES de `_construir()`: la paleta decide el color
	## del fondo raiz y los FPS el limite del motor, y ambos se fijan ahi.
	_cargar_preferencias()
	Engine.max_fps = _fps_elegido
	_construir()
	if Principal.mundo_a_cargar != null:
		mundo = Principal.mundo_a_cargar
		Principal.mundo_a_cargar = null
		_conectar_noticias()
		_seleccionado = null
		_llenar_selector()
		_escribir("[color=#3fa06a]Partida cargada:[/color] %s, %d, semana %d." % [
			mundo.mi_club().nombre, mundo.anio, mundo.semana])
		_refrescar()
	elif Principal.mundo_pregenerado != null:
		var m := Principal.mundo_pregenerado
		Principal.mundo_pregenerado = null
		var modo := Principal.modo_elegido if Principal.modo_elegido != "" else "dt"
		_arrancar_con(m)
		_quizas_tutorial(modo)
	else:
		_nuevo_mundo()

# --- construcción -----------------------------------------------------------

func _construir() -> void:
	## El fondo. Debajo va el color plano de siempre -si la textura fallara al
	## rasterizar, la pantalla sigue siendo legible en vez de quedarse en negro-
	## y encima la escena elegida en Ajustes.
	var fondo := ColorRect.new()
	fondo.color = _pal_fondo()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	_fondo_raiz = fondo
	## El tema de la paleta se cuelga de la raiz ANTES de crear ningun control:
	## lo que se pinte despues ya nace con los colores elegidos.
	_aplicar_tema()
	_fondo_escena = TextureRect.new()
	_fondo_escena.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo_escena.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	## COVERED y no SCALE: los fondos son 16:9 igual que la ventana, así que no
	## recorta casi nada, pero si alguien juega en 21:9 es mejor perder un poco
	## de borde que deformar la escena entera.
	_fondo_escena.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_fondo_escena.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fondo_escena)
	## Y encima del dibujo, el clima: lluvia, nieve, confeti. Va aparte del fondo
	## porque son dos catalogos que se combinan, no uno con veinticuatro entradas
	## multiplicadas por diez.
	_clima = FondoAnimado.new()
	_clima.modo = _clima_elegido
	_clima.interactivo = _clima_interactivo
	add_child(_clima)
	resized.connect(func() -> void:
		if _clima != null:
			_clima.ajustar_area(size))
	_aplicar_fondo()
	## VELO DE LECTURA DE LA CABECERA (25-9-2026). El análisis externo: "el
	## texto de cabecera sobre el fondo de focos se lee mal". La línea gris de
	## la jornada, los sueldos y la confianza cae justo sobre los focos del
	## fondo de estadio -puntos casi blancos-. Un degradado negro que se apaga
	## hacia la mitad de la pantalla oscurece solo la franja de arriba, sirve
	## para los 24 fondos elegibles y no tapa nada: ignora el ratón.
	var velo := TextureRect.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(0, 0, 0, 0.62))
	grad.set_color(1, Color(0, 0, 0, 0.0))
	var tex_velo := GradientTexture2D.new()
	tex_velo.gradient = grad
	tex_velo.fill_from = Vector2(0.5, 0.0)
	tex_velo.fill_to = Vector2(0.5, 1.0)
	tex_velo.width = 4
	tex_velo.height = 64
	velo.texture = tex_velo
	velo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	velo.stretch_mode = TextureRect.STRETCH_SCALE
	velo.anchor_right = 1.0
	velo.anchor_bottom = 0.48
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(velo)

	var raiz := VBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_theme_constant_override("separation", 10)
	raiz.offset_left = 18; raiz.offset_top = 14
	raiz.offset_right = -18; raiz.offset_bottom = -14
	add_child(raiz)

	## La cabecera con el escudo del club al lado del nombre. Es lo primero que se
	## ve al abrir el juego y es lo que hace que sea TU club y no "el club".
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 10)
	raiz.add_child(cab)
	_escudo_cabecera = Control.new()
	_escudo_cabecera.custom_minimum_size = Vector2(44, 44)
	cab.add_child(_escudo_cabecera)
	_cabecera = _texto(26, COL_TEXTO)
	_cabecera.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cab.add_child(_cabecera)
	## LA DERECHA DE LA CABECERA, como en el HTML del usuario: la plata en
	## grande y la fecha debajo, separadas del nombre del club por todo el
	## ancho. Antes esos dos datos vivían perdidos en la línea de texto
	## corrido de abajo, entre la jornada y la media del plantel.
	var empuje := Control.new()
	empuje.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(empuje)
	var caja_plata := VBoxContainer.new()
	caja_plata.alignment = BoxContainer.ALIGNMENT_CENTER
	caja_plata.add_theme_constant_override("separation", 0)
	cab.add_child(caja_plata)
	_lbl_caja = _texto(20, COL_VERDE)
	_lbl_caja.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	caja_plata.add_child(_lbl_caja)
	_lbl_fecha = _texto(11, COL_SUAVE)
	_lbl_fecha.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	caja_plata.add_child(_lbl_fecha)
	## EL BUSCADOR GLOBAL, de `vQoL()`. Va en la cabecera y no escondido en una
	## pestaña porque su gracia es estar SIEMPRE a mano: son ~9.000 jugadores en
	## 384 clubes, y buscar a uno por nombre yendo de pestaña en pestaña es
	## imposible. Escribes, Enter, y se abre su ficha o la de su club.
	## Un gris más claro que COL_SUAVE: es la línea que dice cómo vas -objetivo
	## y confianza-, y sobre los fondos con focos no se leía.
	_sub = _texto(13, COL_SUAVE.lightened(0.35))
	raiz.add_child(_sub)
	_despacho = VBoxContainer.new()
	_despacho.add_theme_constant_override("separation", 4)
	raiz.add_child(_despacho)

	_botones = HBoxContainer.new()
	_botones.add_theme_constant_override("separation", 8)
	raiz.add_child(_botones)
	_selector = OptionButton.new()
	## 250 y no más: el selector, los siete botones de acción y sus separaciones
	## sumaban más que la ventana, y como esta fila vive en la RAÍZ, ese exceso
	## empujaba TODO lo de abajo -incluidas las tres columnas- fuera del borde
	## derecho. Se veía en captura: la ficha del jugador cortada por la mitad.
	## 208 y no 250: el boton del mapa que se añadio al lado ocupa 34 mas 8 de
	## separacion, y esta fila vive en la RAIZ -lo que se pase de ancho empuja
	## TODO lo de abajo fuera del borde derecho y corta la ficha del jugador por
	## la mitad-. Se descuentan exactamente esos 42 pixeles.
	_selector.custom_minimum_size = Vector2(208, 34)
	_selector.clip_text = true
	## Y `fit_to_longest_item = false`, que es lo que de verdad lo arregla.
	##
	## `clip_text` deja que el TEXTO se recorte, pero un OptionButton sigue
	## PIDIENDO de ancho minimo lo que mide su item mas largo -aqui «Colo-Colo ·
	## Primera Division» y compañia-: pedia 386 px con un minimo declarado de 208,
	## la fila entera sumaba 1.286 sobre un viewport logico de 1.280 y todo lo de
	## abajo se salia por la derecha. Se veia como la ficha del jugador cortada.
	_selector.fit_to_longest_item = false
	_selector.item_selected.connect(_al_elegir_club)
	_botones.add_child(_selector)
	## Y el boton que abre el selector DE VERDAD: mapa del pais, escudos y datos
	## del club. El desplegable de al lado se queda para cambiar rapido entre dos
	## que ya conoces, que es para lo unico que servia.
	var b_mapa := Button.new()
	b_mapa.text = "🌎"
	b_mapa.tooltip_text = "Elegir club con el mapa: países, escudos y datos de cada equipo"
	b_mapa.custom_minimum_size = Vector2(34, 34)
	b_mapa.pressed.connect(_abrir_elegir_club)
	_botones.add_child(b_mapa)
	## EL MENÚ DE CALENDARIO. Antes estos cuatro eran botones sueltos en la
	## fila, y con el buscador al lado la fila entera ya no entraba ni
	## recortada: cada botón se veía a media palabra ("Dirigir el parti",
	## "Temporada sig"...) -lo notó el usuario jugando-. Agruparlos en un
	## desplegable libera cuatro anchos de golpe y de paso les da la casa que
	## pedía: "un menú que sea el de calendario".
	var menu_calendario := MenuButton.new()
	menu_calendario.text = "📅 Calendario"
	menu_calendario.custom_minimum_size = Vector2(0, 32)
	menu_calendario.clip_text = true
	menu_calendario.tooltip_text = "Jugar el partido, avanzar semana, jugar la temporada o pasar a la siguiente"
	menu_calendario.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_calendario.size_flags_stretch_ratio = 1.3
	var pop_calendario := menu_calendario.get_popup()
	pop_calendario.add_item("Jugar el partido", 0)
	pop_calendario.add_item("Avanzar semana", 1)
	pop_calendario.add_item("Jugar la temporada", 2)
	pop_calendario.add_item("Temporada siguiente", 3)
	pop_calendario.id_pressed.connect(_al_elegir_calendario)
	_botones.add_child(menu_calendario)
	## "Un día" tiene botón PROPIO y no una entrada más del desplegable: es la
	## acción que más se repite en un manager -pasar el rato hasta el sábado-
	## y esconderla tras dos clics la volvería incómoda. Pedido del usuario.
	var b_dia := Button.new()
	b_dia.text = "⏭ Un día"
	b_dia.tooltip_text = "Avanza un día del calendario. Al pasar el domingo corre la semana entera."
	b_dia.custom_minimum_size = Vector2(84, 32)
	b_dia.pressed.connect(_avanzar_dia)
	_botones.add_child(b_dia)
	_tut_nodos["un_dia"] = b_dia
	_tut_nodos["calendario"] = menu_calendario
	## Las otras dos puertas contextuales, como iconos: el partido de esta
	## semana y la plata. Van aquí y no en la cabecera porque la cabecera es
	## un solo Label y partirla en zonas clicables habría costado más de lo
	## que da.
	var b_hub_partido := Button.new()
	b_hub_partido.text = "⚽"
	b_hub_partido.tooltip_text = "Partido y calendario"
	b_hub_partido.custom_minimum_size = Vector2(34, 32)
	b_hub_partido.pressed.connect(func() -> void: _abrir_hub("partido"))
	_botones.add_child(b_hub_partido)
	_tut_nodos["partido"] = b_hub_partido
	var b_hub_dinero := Button.new()
	b_hub_dinero.text = "💰"
	b_hub_dinero.tooltip_text = "Finanzas, mercado y agentes libres"
	b_hub_dinero.custom_minimum_size = Vector2(34, 32)
	b_hub_dinero.pressed.connect(func() -> void: _abrir_hub("dinero"))
	_botones.add_child(b_hub_dinero)
	_tut_nodos["dinero"] = b_hub_dinero
	_tut_nodos["guardar"] = _boton("Guardar", _guardar)
	_boton("Cargar", _cargar)
	_boton("Otro mundo", _nuevo_mundo)
	## El buscador va en la fila de acciones, no en la cabecera: ahí arriba lo
	## tapaba el aviso de mercado, que flota en la esquina derecha.
	_buscador = LineEdit.new()
	## "Buscar jugador o club…" no entraba en 150 px y se leía "Buscar jugador
	## o clu" (lo notó el análisis externo). El texto largo va al tooltip.
	_buscador.placeholder_text = "🔎 Buscar…"
	_buscador.tooltip_text = "Buscar un jugador o un club por nombre (Enter para abrir su ficha)"
	## 150 y no 210: cada píxel de esta fila sale del ancho de las tres columnas
	## de abajo, y a 210 volvía a cortarse la ficha del jugador por el borde.
	_buscador.custom_minimum_size = Vector2(150, 32)
	_buscador.add_theme_font_size_override("font_size", 12)
	_buscador.text_submitted.connect(_buscar_global)
	_botones.add_child(_buscador)

	## EL MENÚ CENTRAL, A ANCHO COMPLETO (10-9-2026). Vivía dentro de la
	## columna del medio -unos 620 px- y por eso TODO se recortaba: "CENTRA",
	## "HISTORI", "OPERACI". El usuario mandó la captura de su propio HTML,
	## donde el menú cruza la ventana entera y los rótulos entran enteros; esa
	## es la diferencia, no el tamaño de la fuente. Ahora cuelga de `raiz`,
	## encima de las tres columnas, con el ancho de la pantalla.
	_fila_grupos = HBoxContainer.new()
	_fila_grupos.add_theme_constant_override("separation", 6)
	raiz.add_child(_fila_grupos)
	## EL CARRIL DE CHIPS (nivel 2), en un `ScrollContainer` horizontal: en
	## Android se arrastra con el dedo y en PC se desplaza con L2/R2. Vertical
	## apagado, o al primer chip alto la barra empieza a crecer hacia abajo.
	var carril := ScrollContainer.new()
	carril.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	carril.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	carril.custom_minimum_size = Vector2(0, 36)
	carril.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	raiz.add_child(carril)
	_fila_sub = HBoxContainer.new()
	_fila_sub.add_theme_constant_override("separation", 6)
	carril.add_child(_fila_sub)

	## LA TIRA DE DÍAS, calcada de la del HTML del usuario: los siete días con
	## el de hoy encendido y el del partido marcado. Es lo que convierte
	## "semana 12" en una fecha que uno entiende sin pensar.
	_fila_dias = HBoxContainer.new()
	_fila_dias.add_theme_constant_override("separation", 4)
	raiz.add_child(_fila_dias)

	var columnas := HBoxContainer.new()
	columnas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columnas.add_theme_constant_override("separation", 12)
	raiz.add_child(columnas)

	## Columna 1: la tabla de lo que se juega esta semana -liga, copa o el grupo
	## continental-. El título cambia con ella, por eso se guarda.
	_lista_tabla = _columna(columnas, "TABLA DE POSICIONES", 1.9)
	_titulo_tabla = _ultimo_titulo_columna
	## Pulsar la columna abre la ficha completa de la competición. Es la columna
	## que menos sitio tiene -comparte pantalla con el plantel y la ficha- y la
	## que más gente quiere mirar con calma, así que se le da una salida.
	var abrir_comp := Button.new()
	abrir_comp.flat = true
	abrir_comp.text = "Ver la competición  ▸"
	abrir_comp.add_theme_font_size_override("font_size", 11)
	abrir_comp.add_theme_color_override("font_color", _color_de_paleta(COL_ACENTO))
	abrir_comp.pressed.connect(_abrir_competicion)
	_ultima_caja_columna.add_child(abrir_comp)
	## Y EL HUB DE COMPETICIONES, estilo FC26: la tabla no lleva solo a SU
	## competición, lleva a todas las del club -liga, copa, continental,
	## selección, federación-. Es una de las cuatro puertas contextuales que
	## permiten que el nivel 1 se quede en seis bloques.
	var abrir_hub_comp := Button.new()
	abrir_hub_comp.flat = true
	abrir_hub_comp.text = "🏆 Todas las competiciones  ▸"
	abrir_hub_comp.add_theme_font_size_override("font_size", 11)
	abrir_hub_comp.add_theme_color_override("font_color", _color_de_paleta(COL_ORO))
	abrir_hub_comp.pressed.connect(func() -> void: _abrir_hub("competiciones"))
	_ultima_caja_columna.add_child(abrir_hub_comp)

	## Columna 2: plantel y mercado, en pestañas. Son la misma lista de jugadores
	## mirada de dos maneras, así que comparten el mismo pintado y el mismo clic.
	var caja := _panel()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.size_flags_stretch_ratio = 2.6
	columnas.add_child(caja)
	var caja_v := VBoxContainer.new()
	caja_v.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja_v.offset_left = 6; caja_v.offset_top = 4
	caja_v.offset_right = -6; caja_v.offset_bottom = -6
	caja_v.add_theme_constant_override("separation", 4)
	caja.add_child(caja_v)

	## EL MARCO DE PÁGINAS. `_pestanas` no se puede mover a mano -es hijo de un
	## Container y este le reimpone la posición en cada `sort_children`-, así
	## que el desliz se hace con los MÁRGENES de este marco, que sí se
	## respetan. Es lo que permite que cambiar de bloque se sienta como pasar
	## una página y no como un corte seco.
	_marco_paginas = MarginContainer.new()
	_marco_paginas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caja_v.add_child(_marco_paginas)
	_pestanas = TabContainer.new()
	_pestanas.tabs_visible = false
	_pestanas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_marco_paginas.add_child(_pestanas)
	_lista_plantel = _hoja(_pestanas, "Mi plantel")
	## ── PESTAÑA MERCADO ─────────────────────────────────────────────────────
	## El componente se instancia aquí y se engancha por señales. Principal no
	## vuelve a llamar a ninguna función interna del mercado: todo el pintado
	## lo hace PanelMercado, y lo que afecta al mundo lo recibe Principal.
	var _hoja_mercado := _hoja(_pestanas, "Mercado")
	_panel_mercado = PanelMercado.new()
	_panel_mercado.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel_mercado.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hoja_mercado.add_child(_panel_mercado)
	_panel_mercado.fichar_pedido.connect(_abrir_negociacion)
	_panel_mercado.oferta_respondida.connect(_responder_oferta_mercado)
	_panel_mercado.oferta_enviada.connect(_enviar_oferta_negociacion)
	_panel_mercado.negociacion_cancelada.connect(_cancelar_negociacion)
	_panel_mercado.rol_ajustado.connect(_al_ajustar_rol_neg)
	_panel_mercado.campo_ajustado.connect(_al_ajustar_campo_neg)
	_panel_mercado.intercambio_elegido.connect(func(j: Jugador) -> void:
		if mundo.mercado.negociacion != null:
			mundo.mercado.negociacion.poner_intercambio(j)
			_refrescar())
	_panel_mercado.refrescar_pedido.connect(_refrescar)
	_panel_mercado.escrito.connect(_escribir)
	_lista_copa = _hoja(_pestanas, "Copa")
	_lista_club = _hoja(_pestanas, "Club")
	_lista_conti = _hoja(_pestanas, "Continental")
	_lista_medico = _hoja(_pestanas, "Enfermería")
	_lista_logros = _hoja(_pestanas, "Logros")
	_lista_entren = _hoja(_pestanas, "Entrenar")
	_lista_fed = _hoja(_pestanas, "Federación")
	_lista_estadio = _hoja(_pestanas, "Estadio")
	_lista_seleccion = _hoja(_pestanas, "Selección")
	_lista_cantera = _hoja(_pestanas, "Cantera")
	_lista_contratos = _hoja(_pestanas, "Contratos")
	_lista_comparar = _hoja(_pestanas, "Comparar")
	_lista_inicio = _hoja(_pestanas, "Inicio")
	_lista_gente = _hoja(_pestanas, "Gente")
	_lista_records = _hoja(_pestanas, "Récords")
	_lista_legado = _hoja(_pestanas, "Legado")
	_lista_finanzas = _hoja(_pestanas, "Finanzas")
	_lista_camarin = _hoja(_pestanas, "Camarín")
	_lista_ciudad = _hoja(_pestanas, "Ciudad")
	_lista_editor = _hoja(_pestanas, "Editor")
	_lista_glosario = _hoja(_pestanas, "Glosario")
	_lista_ajustes = _hoja(_pestanas, "Ajustes")
	_lista_correo = _hoja(_pestanas, "Correo")
	_lista_redes = _hoja(_pestanas, "Redes")
	_lista_vida = _hoja(_pestanas, "Vida")
	_lista_habilidades = _hoja(_pestanas, "Habilidades")
	_lista_libres = _hoja(_pestanas, "Libres")
	_lista_premios = _hoja(_pestanas, "Premios")
	_lista_clubes = _hoja(_pestanas, "Clubes")
	_lista_desafios = _hoja(_pestanas, "Desafíos")
	_lista_tactica = _hoja(_pestanas, "Táctica")
	## `partido:['partido']` del HTML. Hasta esta tanda era un atajo de dos
	## líneas al botón de arriba; ahora es la PREVIA (`vPrevia()`): con quién
	## juegas, quién pita, quién dirige enfrente, cómo se miden las plantillas y
	## qué dicen las casas de apuestas. Se repinta en `_pintar_partido()`.
	_lista_partido = _hoja(_pestanas, "Partido")
	## `vCalendario` no existe en el HTML -esto es una pantalla nueva, pedida
	## por el usuario con una captura de referencia de otro manager (grilla de
	## partidos marcados con el escudo del rival, desde la que se simula de
	## corrido o se salta el partido sin dirigirlo)-. Se apoya en datos que ya
	## existen (`Liga.calendario`) en vez de inventar un sistema de fechas
	## nuevo.
	_lista_calendario = _hoja(_pestanas, "Calendario")

	_construir_grupos()
	_pestanas.tab_changed.connect(_al_cambiar_pestana)
	_elegir_grupo("central")

	## Columna 3: la ficha del jugador seleccionado, y debajo lo que va pasando.
	var der := VBoxContainer.new()
	der.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	der.size_flags_stretch_ratio = 1.9
	der.add_theme_constant_override("separation", 12)
	columnas.add_child(der)
	_ficha = _bloque(der, "FICHA DEL JUGADOR", 2.0)
	## CON SCROLL PROPIO (25-9-2026). La ficha completa -atributos, contrato,
	## cabeza, habilidades, notas- pide unos 1.060 px de alto y la columna no
	## tenía scroll: estiraba la fila entera y, con la ventana a 1280x720
	## lógicos, todo lo de abajo de las tres columnas quedaba fuera de la
	## pantalla sin forma de llegar (el botón "Jugar el partido", el final de la
	## tabla). Medido con `pruebas/captura_modos_partido.gd`.
	_ficha = _con_scroll(_ficha)
	## LA PUERTA AL PLANTEL. Tocar la zona del jugador lleva al hub con todo
	## lo que se hace con futbolistas -plantel, táctica, entrenar, enfermería,
	## camarín, cantera, contratos-, en vez de tener siete pestañas más
	## arriba. Es la idea que pidió el usuario mirando FC26.
	var b_plantel := Button.new()
	b_plantel.text = "👔 Plantel y cuerpo del equipo  ▸"
	b_plantel.flat = true
	b_plantel.add_theme_font_size_override("font_size", 11)
	b_plantel.add_theme_color_override("font_color", _color_de_paleta(COL_ACENTO))
	b_plantel.pressed.connect(func() -> void: _abrir_hub("plantel"))
	_ultima_caja_columna.add_child(b_plantel)
	_tut_nodos["plantel"] = b_plantel
	var caja_reg := _bloque(der, "LO QUE VA PASANDO", 1.0)
	_registro = RichTextLabel.new()
	_registro.bbcode_enabled = true
	_registro.scroll_following = true
	_registro.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_registro.add_theme_font_size_override("normal_font_size", 12)
	caja_reg.add_child(_registro)

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

func _pildora(texto: String, tam: int = 12, alto: int = 32) -> Button:
	var b := Button.new()
	b.text = texto
	b.toggle_mode = true
	if _estilo_menu == "compacto":
		tam = maxi(10, tam - 1)
		alto = maxi(22, alto - 4)
	b.add_theme_font_size_override("font_size", tam)
	b.custom_minimum_size = Vector2(float(texto.length()) * (float(tam) * 0.62) + 30.0, alto)
	## "barra" = esquinas rectas y una línea de acento debajo del activo, que
	## es como se veían las pestañas antes de que todo fuera cápsulas.
	var radio := 3 if _estilo_menu == "barra" else int(alto / 2)
	var reposo := StyleBoxFlat.new()
	reposo.bg_color = _mezcla(_color_de_paleta(COL_PANEL), _color_de_paleta(COL_TEXTO), 0.07)
	reposo.border_color = _color_de_paleta(COL_BORDE)
	reposo.set_border_width_all(1)
	reposo.set_corner_radius_all(radio)
	reposo.content_margin_left = 14
	reposo.content_margin_right = 14
	var encima := reposo.duplicate() as StyleBoxFlat
	encima.bg_color = _mezcla(_color_de_paleta(COL_PANEL), _color_de_paleta(COL_TEXTO), 0.18)
	var activa := StyleBoxFlat.new()
	activa.bg_color = _color_de_paleta(COL_TEXTO)
	activa.set_corner_radius_all(radio)
	activa.content_margin_left = 14
	activa.content_margin_right = 14
	b.add_theme_stylebox_override("normal", reposo)
	b.add_theme_stylebox_override("hover", encima)
	b.add_theme_stylebox_override("focus", encima)
	b.add_theme_stylebox_override("pressed", activa)
	b.add_theme_color_override("font_color", _color_de_paleta(COL_TEXTO))
	b.add_theme_color_override("font_hover_color", _color_de_paleta(COL_TEXTO))
	## La píldora activa lleva letra OSCURA sobre fondo claro: es el mismo
	## truco del HTML y lo que hace que no haga falta ningún subrayado.
	b.add_theme_color_override("font_pressed_color", _color_de_paleta(COL_FONDO))
	b.add_theme_color_override("font_hover_pressed_color", _color_de_paleta(COL_FONDO))
	return b

## La barra de cinco -un botón por grupo, con el mismo icono que `#tabs` del
## HTML-. Se toca una sola vez; el submenú de abajo cambia solo.
## CUÁNTO HAY SIN RESOLVER EN CADA BLOQUE. Todo sale de datos que el motor ya
## lleva -no hay contador nuevo que mantener-, y por eso no puede
## desincronizarse: si el correo tiene tres sin leer, es porque `_bandeja`
## tiene tres sin leer.
func _pendientes_de_grupo(gid: String) -> int:
	if mundo == null:
		return 0
	var n := 0
	match gid:
		"central":
			for m: Dictionary in _bandeja:
				if not bool(m.get("leido", false)):
					n += 1
		"gente":
			if mundo.cantera != null and mundo.cantera.hay_exigencia():
				n += 1
		"operaciones":
			if mundo.prensa != null and mundo.prensa.hay_rueda():
				n += 1
			if mundo.mercado != null:
				n += mundo.mercado.ofertas_recibidas.size()
	return n

## Repinta SOLO los rótulos de los seis bloques, para que el punto de aviso
## aparezca y desaparezca al avanzar la semana. Se hace aparte de
## `_reconstruir_grupos()` porque eso reconstruye botones enteros y esto
## corre en cada repintado: cambiar seis textos es gratis, recrear seis
## botones con sus estilos no.
func _actualizar_badges() -> void:
	if _fila_grupos == null:
		return
	for i in mini(_fila_grupos.get_child_count(), GRUPOS.size()):
		var b := _fila_grupos.get_child(i) as Button
		if b == null:
			continue
		var g: Dictionary = GRUPOS[i]
		var rotulo := String(g["icono"]) if _estilo_menu == "compacto" \
			else "%s  %s" % [String(g["icono"]), String(g["nombre"])]
		if _pendientes_de_grupo(String(g["id"])) > 0:
			rotulo += "  ●"
		b.text = rotulo

## Vuelve a montar la fila de bloques con el estilo actual. Hace falta porque
## `_construir_grupos()` corre UNA vez al armar la escena, y cambiar de
## estilo de menú tiene que verse sin reiniciar la partida.
func _reconstruir_grupos() -> void:
	_limpiar(_fila_grupos)
	_construir_grupos()
	_actualizar_fila_grupos()
	_reconstruir_fila_sub()
	_pintar_dias()

func _construir_grupos() -> void:
	for g: Dictionary in GRUPOS:
		## En "compacto" el bloque va SOLO con su icono: seis iconos ocupan un
		## tercio de la fila y dejan el ancho para los chips, que es donde de
		## verdad hay que leer. El tooltip guarda el nombre entero.
		var rotulo := String(g["icono"]) if _estilo_menu == "compacto" \
			else "%s  %s" % [String(g["icono"]), String(g["nombre"])]
		## EL AVISO DE NOVEDAD. Un punto al lado del bloque que tiene algo sin
		## resolver -correo sin leer, un representante esperando, contratos que
		## vencen-. Es lo que convierte la barra en un tablero: sin esto hay
		## que entrar a los seis bloques para descubrir dónde pasa algo.
		var pend := _pendientes_de_grupo(String(g["id"]))
		if pend > 0:
			rotulo += "  ●"
		var b := _pildora(rotulo, 13, 38)
		b.tooltip_text = String(g["nombre"])
		## YA NO se recortan ni se estiran: la barra vive a ancho completo de
		## pantalla, no dentro de la columna del medio, así que los seis
		## rótulos entran enteros y cada píldora mide lo que mide su texto.
		var gid := String(g["id"])
		b.pressed.connect(func() -> void: _elegir_grupo(gid))
		_fila_grupos.add_child(b)

func _grupo_por_id(gid: String) -> Dictionary:
	for g: Dictionary in GRUPOS:
		if String(g["id"]) == gid:
			return g
	return {}

## De qué bloque maestro es una pestaña. Con los hubs contextuales hay
## pestañas que NO pertenecen a ningún bloque -Táctica, Mercado, Copa...-: esas
## devuelven "" y la barra de arriba se queda como esté, sin saltar a otro
## bloque a la fuerza.
## FALLA VISUAL ARREGLADA (26-9-2026, recorrido D4): varias pestañas viven en
## más de un grupo -"Club" está en CENTRAL (Mi Carrera) y en CLUB
## (Infraestructura, Directorio); "Estadio" en CLUB y en OPERACIONES-, y esto
## devolvía siempre el PRIMER grupo: entrabas por CLUB › Infraestructura y el
## menú encendía CENTRAL. Ahora manda, por orden: el grupo en el que ya estás si
## tiene esa pestaña; si no, el grupo cuyo chip coincide con la sección abierta;
## y solo al final, el primero que la tenga.
func _grupo_de_pestana(titulo: String) -> String:
	for g: Dictionary in GRUPOS:
		if String(g["id"]) != _grupo_actual:
			continue
		for chip: Dictionary in (g["tabs"] as Array):
			if String(chip["tab"]) == titulo and _seccion_activa(chip):
				return String(g["id"])
	for g: Dictionary in GRUPOS:
		for chip: Dictionary in (g["tabs"] as Array):
			if String(chip["tab"]) == titulo and chip.has("secc") and _seccion_activa(chip):
				return String(g["id"])
	for g: Dictionary in GRUPOS:
		for chip: Dictionary in (g["tabs"] as Array):
			if String(chip["tab"]) == titulo:
				return String(g["id"])
	return ""

## Abre un chip: primero fija la sección dentro de la pestaña -si el chip
## trae `secc`- y después salta a la pestaña. El orden importa: al revés, la
## pestaña se pintaría con la sección vieja y habría que repintar dos veces.
func _ir_a_chip(chip: Dictionary) -> void:
	var secc := String(chip.get("secc", ""))
	## «Equipación» es su propia pantalla, entera: el diseñador.
	if secc == "kits" and mundo != null and mundo.mi_club() != null:
		var dz := DisenadorKit.abrir(self, mundo)
		dz.cerrado.connect(_refrescar)
		return
	if secc != "":
		match String(chip["tab"]):
			"Club": _secc_club = secc
			"Gente": _secc_gente = secc
			"Ajustes": _secc_ajustes = secc
			"Récords": _secc_records = secc
			"Redes": _secc_redes = secc
			"Vida": _secc_vida = secc
	_ir_a_pestana(String(chip["tab"]))
	## OJO: `_elegir_grupo("central")` corre dentro de `_construir()`, cuando
	## `mundo` todavía es null -la escena se arma antes de que le pasen la
	## partida-. Sin este candado, arrancar el juego tiraba "Nonexistent
	## function 'mi_club' in base 'Nil'" antes de pintar nada.
	if mundo != null:
		_refrescar()

## EL MENÚ COMO PÁGINAS. El usuario lo pidió así: "debe poder moverse hacia
## los lados como si fueran páginas... es nuestro centro de mando". Cambiar
## de bloque desliza el contenido hacia el lado del que viene -a la izquierda
## si vas hacia adelante, a la derecha si vuelves- y lo desvanece un punto.
var _marco_paginas: MarginContainer

func _paso_pagina(v: float) -> void:
	if _marco_paginas == null:
		return
	_marco_paginas.add_theme_constant_override("margin_left", int(v))
	_marco_paginas.add_theme_constant_override("margin_right", int(-v))

func _animar_pagina(direccion: int) -> void:
	if _marco_paginas == null or direccion == 0:
		return
	var desde := 46.0 * float(direccion)
	_paso_pagina(desde)
	_marco_paginas.modulate.a = 0.25
	var tw := create_tween().set_parallel(true)
	tw.tween_method(_paso_pagina, desde, 0.0, 0.20).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_marco_paginas, "modulate:a", 1.0, 0.20)

func _indice_grupo(gid: String) -> int:
	for i in GRUPOS.size():
		if String(GRUPOS[i]["id"]) == gid:
			return i
	return 0

## Pasa al bloque de al lado. Es lo que usan L1/R1 del mando, las flechas del
## teclado y el arrastre con el dedo en Android: una sola puerta para las
## tres formas de pedir lo mismo.
func _bloque_vecino(paso: int) -> void:
	var i := _indice_grupo(_grupo_actual)
	var siguiente := (i + paso + GRUPOS.size()) % GRUPOS.size()
	_elegir_grupo(String(GRUPOS[siguiente]["id"]))

# --- tutorial guiado (ui/componentes/tutorial.gd) ---------------------------

## Los controles que el tutorial señala, por clave. Se guardan al construir la
## pantalla; los que ya tenían variable propia se resuelven en el momento.
var _tut_nodos: Dictionary = {}
var _tutorial: Tutorial = null

## Arranca el recorrido la primera vez que alguien empieza una carrera, o
## siempre si se pidió desde la tarjeta "Tutorial" del menú.
func _quizas_tutorial(modo: String) -> void:
	if not Principal.tutorial_pedido and Tutorial.visto():
		return
	Principal.tutorial_pedido = false
	abrir_tutorial(modo)

func abrir_tutorial(modo: String = "") -> void:
	if is_instance_valid(_tutorial):
		_tutorial.queue_free()
	if modo == "":
		modo = mundo.roles.modo_actual() if mundo != null and mundo.roles != null else "dt"
	_tutorial = Tutorial.new()
	add_child(_tutorial)
	_tutorial.iniciar(self, modo, mundo.mi_club().nombre if mundo != null and mundo.mi_club() != null else "tu club")
	_tutorial.terminado.connect(func(_completo: bool) -> void:
		Tutorial.marcar_visto()
		_tutorial = null)

func tutorial_objetivo(clave: String) -> Control:
	match clave:
		"estado": return _sub
		"grupos": return _fila_grupos
		"chips": return _fila_sub.get_parent() as Control
		"ficha": return _ficha
		"tabla": return _lista_tabla
		"registro": return _registro
	return _tut_nodos.get(clave) as Control

## Lo que completa un paso sin pulsar "Siguiente": que el jugador haya hecho
## eso mismo que la tarjeta le pedía.
func tutorial_hecho(clave: String) -> bool:
	var titulo := _pestanas.get_tab_title(_pestanas.current_tab) if _pestanas.get_tab_count() > 0 else ""
	## Las misiones del tutorial inmersivo: una pestaña concreta, una sección
	## concreta de una pestaña, o la ficha de un jugador concreto.
	if clave.begins_with("tab:"):
		return titulo == clave.substr(4)
	if clave.begins_with("chip:"):
		var partes := clave.substr(5).split("|")
		return titulo == partes[0] and _seccion_activa({"tab": partes[0], "secc": partes[1] if partes.size() > 1 else ""})
	if clave.begins_with("ficha:"):
		return _seleccionado != null and _seleccionado.id == clave.substr(6)
	match clave:
		"grupo": return _grupo_actual != "central"
		"ficha": return _seleccionado != null
		"plantel": return (HUBS["plantel"]["tabs"] as Array).has(titulo)
		"dinero": return (HUBS["dinero"]["tabs"] as Array).has(titulo)
		"partido": return (HUBS["partido"]["tabs"] as Array).has(titulo)
	return false

## "Muéstramelo": hace por el jugador lo que pide el paso.
func tutorial_accion(clave: String) -> void:
	if clave.begins_with("tab:"):
		_ir_a_pestana(clave.substr(4))
		_refrescar()
		return
	if clave.begins_with("chip:"):
		var partes := clave.substr(5).split("|")
		_ir_a_chip({"tab": partes[0], "secc": partes[1] if partes.size() > 1 else ""})
		return
	if clave.begins_with("ficha:"):
		var id := clave.substr(6)
		for j: Jugador in mundo.mi_club().plantilla:
			if j.id == id:
				_ver_ficha(j)
		return
	match clave:
		"ficha":
			if not mundo.mi_club().plantilla.is_empty():
				_ver_ficha(mundo.mi_club().plantilla[0])
		"grupo_club": _elegir_grupo("club")
		"plantel": _ir_a_pestana("Mi plantel")
		"dinero": _ir_a_pestana("Finanzas")
		"partido": _ir_a_pestana("Partido")

## Cambia de bloque maestro: entra siempre por su primer chip -índice 0-, que
## es lo que pidió el usuario ("al cambiar de pestaña madre, el nivel 2 se
## reinicia al primer chip").
func _elegir_grupo(gid: String) -> void:
	var antes := _indice_grupo(_grupo_actual)
	var ahora := _indice_grupo(gid)
	if gid != _grupo_actual:
		_animar_pagina(1 if ahora > antes else -1)
	_grupo_actual = gid
	_actualizar_fila_grupos()
	_reconstruir_fila_sub()
	var chips: Array = _grupo_por_id(gid).get("tabs", [])
	if not chips.is_empty():
		_ir_a_chip(chips[0])

func _actualizar_fila_grupos() -> void:
	for i in _fila_grupos.get_child_count():
		var b: Button = _fila_grupos.get_child(i)
		b.button_pressed = (String(GRUPOS[i]["id"]) == _grupo_actual)

## EL CARRIL DE CHIPS (nivel 2). Un chip queda marcado cuando coinciden LAS
## DOS cosas: su pestaña y su sección. Sin mirar la sección, los cinco chips
## que comparten la pestaña "Club" se encenderían todos a la vez.
func _reconstruir_fila_sub() -> void:
	_limpiar(_fila_sub)
	var titulo_actual := ""
	if _pestanas.get_tab_count() > 0:
		titulo_actual = _pestanas.get_tab_title(_pestanas.current_tab)
	for chip: Dictionary in (_grupo_por_id(_grupo_actual).get("tabs", []) as Array):
		var b := _pildora(String(chip["label"]), 12, 30)
		b.button_pressed = (String(chip["tab"]) == titulo_actual) and _seccion_activa(chip)
		var destino := chip
		b.pressed.connect(func() -> void: _ir_a_chip(destino))
		_fila_sub.add_child(b)
		## LA CASCADA. Cada chip entra un pelo después que el anterior -35 ms-,
		## así el carril "se abre" en vez de aparecer de golpe. Es lo que hace
		## que cambiar de bloque se sienta un gesto y no un parpadeo. El
		## desfase es corto a propósito: con 10 chips el último entra a los
		## 350 ms, todavía antes de que la mano llegue a tocar nada.
		b.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_interval(0.035 * float(_fila_sub.get_child_count() - 1))
		tw.tween_property(b, "modulate:a", 1.0, 0.14)

func _seccion_activa(chip: Dictionary) -> bool:
	var secc := String(chip.get("secc", ""))
	if secc == "":
		return true
	match String(chip["tab"]):
		"Club": return _secc_club == secc
		"Gente": return _secc_gente == secc
		"Ajustes": return _secc_ajustes == secc
		"Récords": return _secc_records == secc
		"Redes": return _secc_redes == secc
		"Vida": return _secc_vida == secc
	return true

## UN HUB CONTEXTUAL. Se abre tocando la zona de la pantalla que ya habla de
## eso -el plantel, el marcador, la caja, la tabla- y ofrece sus pestañas como
## botones grandes. No es una pestaña más: es una puerta, y por eso se cierra
## sola en cuanto eliges.
func _abrir_hub(clave: String) -> void:
	var hub: Dictionary = HUBS.get(clave, {})
	if hub.is_empty():
		return
	var capa := PanelContainer.new()
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(COL_FONDO.r, COL_FONDO.g, COL_FONDO.b, 0.93)
	capa.add_theme_stylebox_override("panel", estilo)
	add_child(capa)

	var caja := VBoxContainer.new()
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.add_theme_constant_override("separation", 10)
	capa.add_child(caja)
	var t := _texto(20, COL_ORO)
	t.text = String(hub["titulo"])
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(t)
	var flow := HFlowContainer.new()
	flow.alignment = FlowContainer.ALIGNMENT_CENTER
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	caja.add_child(flow)
	for titulo: String in (hub["tabs"] as Array):
		var b := Button.new()
		b.text = titulo
		b.custom_minimum_size = Vector2(180, 44)
		b.add_theme_font_size_override("font_size", 14)
		var destino := titulo
		b.pressed.connect(func() -> void:
			capa.queue_free()
			_ir_a_pestana(destino)
			_refrescar())
		flow.add_child(b)
	var cerrar := Button.new()
	cerrar.text = "✕  Cerrar"
	cerrar.custom_minimum_size = Vector2(0, 34)
	cerrar.pressed.connect(func() -> void: capa.queue_free())
	caja.add_child(cerrar)
	## La entrada con un desliz corto hacia arriba: es lo que hace que el hub
	## se sienta una capa que sube y no un cambio de pantalla seco.
	caja.modulate.a = 0.0
	caja.position.y += 18.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(caja, "modulate:a", 1.0, 0.16)
	tw.tween_property(caja, "position:y", caja.position.y - 18.0, 0.16).set_trans(Tween.TRANS_CUBIC)

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

func _buscar_global(texto: String) -> void:
	## Se compara limpio por los dos lados: con la cubierta activa "Fernand0"
	## tiene que salir buscando "fernando" (y también buscando "fernand0").
	var q := Nombres.limpiar(texto.strip_edges()).to_lower()
	if q.length() < 2:
		return
	var mejor: Jugador = null
	var mejor_empieza := false
	for c: Club in mundo.clubes.values():
		for j in c.plantilla:
			var n := Nombres.limpiar(j.nombre).to_lower()
			if not n.contains(q):
				continue
			var empieza := n.begins_with(q)
			if mejor == null or (empieza and not mejor_empieza) or (empieza == mejor_empieza and j.ovr > mejor.ovr):
				mejor = j
				mejor_empieza = empieza
	if mejor != null:
		_escribir("[color=#3fa06a]Encontrado:[/color] %s, de %s." % [
			mejor.nombre, (mundo.clubes.get(mejor.club_id) as Club).nombre if mundo.clubes.has(mejor.club_id) else "sin club"])
		_ver_ficha(mejor)
		_buscador.text = ""
		return
	for c2: Club in mundo.clubes.values():
		if Nombres.limpiar(c2.nombre).to_lower().contains(q):
			_clubes_ficha = c2
			_ir_a_pestana("Clubes")
			_refrescar()
			_buscador.text = ""
			return
	_escribir("[color=#8ea595]No hay ningún jugador ni club que se llame así.[/color]")

func _ir_a_pestana(titulo: String) -> void:
	for i in _pestanas.get_tab_count():
		if _pestanas.get_tab_title(i) == titulo:
			_pestanas.current_tab = i
			return

## Se dispara con CUALQUIER cambio de pestaña -tocando el submenú, o a mano
## desde una captura/prueba que hace `tabs.current_tab = i` directamente-, así
## que la barra de grupos nunca queda desincronizada de lo que en verdad se
## está viendo.
func _al_cambiar_pestana(_idx: int) -> void:
	var titulo := _pestanas.get_tab_title(_pestanas.current_tab)
	var gid := _grupo_de_pestana(titulo)
	## "" = pestaña de hub contextual (Táctica, Mercado, Copa...). No pertenece
	## a ningún bloque maestro, así que la barra de arriba se queda donde
	## estaba en vez de saltar a un bloque que no tiene nada que ver.
	if gid != "" and gid != _grupo_actual:
		_grupo_actual = gid
		_actualizar_fila_grupos()
	_reconstruir_fila_sub()
	## El contenido de la pestaña entra escalonado (plan maestro B11).
	_animar_pestana.call_deferred()

func _animar_pestana() -> void:
	var pag := _pestanas.get_current_tab_control()
	if pag == null:
		return
	## Cada hoja es VBox > ScrollContainer > VBox (la lista): se anima la lista.
	for h in pag.get_children():
		if h is ScrollContainer and h.get_child_count() > 0:
			Animar.escalonar(h.get_child(0))
			return
	Animar.escalonar(pag)

## TODA la interfaz pasa por aqui, y por eso los dos ajustes de accesibilidad
## -el tamano del texto y la paleta para daltonismo- se aplican en este punto y
## no en las mil y pico llamadas repartidas por el archivo.
func _texto(tam: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", maxi(8, int(round(float(tam) * _escala_texto))))
	l.add_theme_color_override("font_color", _color_accesible(_color_de_paleta(color)))
	return l

## Las dos mil llamadas a `_texto()` del juego piden COL_TEXTO o COL_SUAVE, que
## son claros porque el fondo por defecto es oscuro. Con una paleta CLARA -papel,
## cuaderno- ese texto quedaria blanco sobre blanco, invisible. Se traduce aqui,
## en el unico sitio por el que pasan todas las etiquetas, en vez de tocar dos mil
## llamadas: los colores con significado propio -el oro de un titulo, el rojo de
## una deuda- pasan de largo sin tocarse, que para eso son ellos los que informan.
func _color_de_paleta(c: Color) -> Color:
	if _paleta == "bosque":
		return c
	if c == COL_TEXTO:
		return _pal_texto()
	if c == COL_SUAVE:
		return _pal_suave()
	return _con_contraste(c)

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

func _con_contraste(c: Color) -> Color:
	var lf := _pal_panel().get_luminance()
	if absf(lf - c.get_luminance()) >= SALTO_LUMA:
		return c
	var destino := Color.BLACK if lf > 0.5 else Color.WHITE
	var r := c
	## Ocho pasos y se para. Si un color no llega ni al octavo -un gris exacto del
	## mismo tono que el panel- se devuelve el ultimo, que ya es lo mas separado
	## que se puede sin dejar de ser el mismo color.
	for i in 8:
		r = r.lerp(destino, 0.18)
		if absf(lf - r.get_luminance()) >= SALTO_LUMA:
			return r
	return r

## El fondo de cada `.card` del HTML no es un color plano: trae un degradado
## cenital sutil (`linear-gradient(180deg, panel+12%blanco, panel 42%)`) que
## le da un aire de placa con brillo, no de rectángulo pintado. `StyleBoxFlat`
## de Godot no admite degradados, así que se superpone una textura aparte
## -blanco semitransparente arriba, cero abajo- que ignora el ratón: el mismo
## efecto, sin tapar ningún control de debajo.
static var _brillo_panel: Texture2D = null
static func _textura_brillo_panel() -> Texture2D:
	if _brillo_panel != null:
		return _brillo_panel
	## OJO: `Gradient.set_color(i, ...)` indexa por PUNTO, no por offset -y
	## `add_point()` desplaza los índices de los puntos que venían después-.
	## `set_color(1, ...)` tras un `add_point()` de en medio no toca el punto
	## final: se queda en su blanco opaco de fábrica, y el "brillo" salía
	## opaco de arriba abajo en vez de apagarse a los 2/5. Se fijan las tres
	## paradas de una vez, sin el índice cambiante de por medio.
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.42, 1.0])
	g.colors = PackedColorArray([
		Color(1, 1, 1, 0.10), Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_LINEAR
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(0, 1)
	t.width = 4
	t.height = 128
	_brillo_panel = t
	return t

func _panel() -> PanelContainer:
	var p := PanelContainer.new()
	var e := StyleBoxFlat.new()
	## La paleta y la forma elegidas en Ajustes. Se leen aqui, en el unico sitio
	## por el que pasan todas las tarjetas del juego, para que cambiarlas repinte
	## la interfaz entera sin tocar ni una pantalla.
	e.bg_color = _pal_panel()
	e.border_color = _pal_borde()
	var forma: Array = FORMAS_TARJETA.get(_forma_tarjeta, ["", 8, 1])
	e.set_border_width_all(int(forma[2]))
	e.set_corner_radius_all(int(forma[1]))
	p.add_theme_stylebox_override("panel", e)
	## Marcada como tarjeta del juego. Media interfaz -las columnas, la cabecera,
	## la ficha- se construye UNA vez y luego solo se le cambia el contenido, asi
	## que cambiar de paleta no la tocaba: se queda esta marca para poder ir a
	## buscarlas y repintarlas sin reconstruir la pantalla entera.
	p.set_meta("tarjeta", true)
	## El adorno del borde -escuadras, filete, cinta-. Va aqui y no en el
	## StyleBox porque un StyleBox solo sabe pintar un borde entero y uniforme.
	if _marca_tarjeta != "ninguno":
		var mk := MarcaPanel.new()
		mk.poner(_marca_tarjeta, COL_ACENTO)
		p.add_child(mk)
	if not _brillo_tarjetas:
		return p
	var brillo := TextureRect.new()
	brillo.texture = _textura_brillo_panel()
	brillo.set_anchors_preset(Control.PRESET_FULL_RECT)
	brillo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	## SIN esto, TextureRect pide como mínimo el tamaño NATIVO de la textura
	## (128px de alto) y estira el panel entero para dárselo -el brillo
	## crecía la tarjeta en vez de solo pintarla-.
	brillo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	brillo.stretch_mode = TextureRect.STRETCH_SCALE
	p.add_child(brillo)
	return p

func _columna(padre: HBoxContainer, titulo: String, ratio: float) -> VBoxContainer:
	var caja := _panel()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.size_flags_stretch_ratio = ratio
	padre.add_child(caja)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 12; v.offset_top = 10; v.offset_right = -12; v.offset_bottom = -10
	caja.add_child(v)
	var t := _texto(11, COL_SUAVE); t.text = titulo
	t.clip_text = true
	v.add_child(t)
	## Se deja a mano el último título creado para las columnas cuyo encabezado
	## cambia solo -la de la izquierda dice "PRIMERA DIVISION" o "COPA
	## LIBERTADORES · CUARTOS" según lo que se juegue el domingo-.
	_ultimo_titulo_columna = t
	## `v` es la caja entera de la columna, por debajo del scroll: quien quiera
	## poner algo FIJO al pie -un botón que no se vaya con el desplazamiento-
	## lo cuelga de aquí.
	_ultima_caja_columna = v
	return _con_scroll(v)

func _bloque(padre: VBoxContainer, titulo: String, ratio: float) -> VBoxContainer:
	var caja := _panel()
	caja.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caja.size_flags_stretch_ratio = ratio
	padre.add_child(caja)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 12; v.offset_top = 10; v.offset_right = -12; v.offset_bottom = -10
	caja.add_child(v)
	var t := _texto(11, COL_SUAVE); t.text = titulo
	v.add_child(t)
	return v

func _hoja(tabs: TabContainer, titulo: String) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.name = titulo
	tabs.add_child(v)
	return _con_scroll(v)

func _con_scroll(padre: VBoxContainer) -> VBoxContainer:
	var s := ScrollContainer.new()
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	padre.add_child(s)
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 2)
	s.add_child(lista)
	return lista

func _boton(texto: String, accion: Callable, padre: Node = null) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(0, 32)
	## Un Button pide de ancho mínimo lo que mida su texto, y varios botones
	## largos en fila desbordan la ventana sin dar ningún error: solo se ve en
	## una captura. Con `clip_text` la fila puede encoger; el tooltip guarda el
	## texto entero para cuando no quepa.
	b.clip_text = true
	b.tooltip_text = texto
	## Con `clip_text` a secas un botón puede encoger hasta CERO y desaparecer:
	## la primera vez que se probó esto, la fila entera de acciones se quedó en
	## siete rayas de un píxel. El mínimo garantiza que siempre se lea algo.
	b.custom_minimum_size.x = 92
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	## Y el reparto del ancho va POR LARGO DEL ROTULO. Todos los botones de la
	## fila expandian igual, asi que "Guardar" sobraba sitio mientras "Temporada
	## siguiente" se quedaba en "Temporada s". Con esto cada uno pide lo suyo.
	b.size_flags_stretch_ratio = clampf(float(texto.length()) / 12.0, 0.95, 1.9)
	b.pressed.connect(accion)
	(padre if padre != null else _botones).add_child(b)
	return b

func _limpiar(n: Node) -> void:
	for h in n.get_children():
		n.remove_child(h)
		h.queue_free()

## Las columnas se alinean con un GridContainer, no rellenando con espacios: la
## fuente es proporcional y un "%-22s" no alinea nada.
func _rejilla(lista: VBoxContainer, columnas: int) -> GridContainer:
	_limpiar(lista)
	var g := GridContainer.new()
	g.columns = columnas
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 3)
	lista.add_child(g)
	return g

func _celda(g: GridContainer, texto: String, color: Color, derecha: bool = false, tam: int = 12) -> Label:
	var l := _texto(tam, color)
	l.text = texto
	if derecha:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_child(l)
	return l

## Una fila de jugador que se puede pulsar. El botón va en la primera celda y
## ocupa el ancho: así toda la fila responde al clic sin tener que inventar un
## control nuevo ni capturar eventos a mano.
## EL RETRATO DE UN JUGADOR, EN UN SOLO SITIO. Antes cada pantalla lo montaba
## por su cuenta -cuatro trozos de código casi iguales- y por eso la mayoría
## simplemente no lo ponía: en cantera, enfermería, camarín, contratos,
## selección o el árbol genealógico un futbolista era una línea de texto.
##
## Y eso se notaba justo donde más duele: un jugador REAL con su foto de verdad
## encontrada en Commons aparecía con foto en el plantel y sin ella en la
## enfermería, como si fuera otra persona. `Cara.textura()` ya resuelve foto real
## primero y dibujo procedural después; lo único que faltaba era llamarla desde
## todas partes.
func _retrato(j: Jugador, tam: int = 26) -> TextureRect:
	var equipo: Club = mundo.clubes.get(j.club_id)
	var r := TextureRect.new()
	r.texture = Cara.textura(j, equipo.color1 if equipo else "#2b6b45",
		equipo.color2 if equipo else "#ffffff", tam)
	r.custom_minimum_size = Vector2(tam, tam)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

func _fila_jugador(g: GridContainer, j: Jugador, columnas: Array, colores: Array) -> void:
	## La cara del jugador delante del nombre. Es lo que pedia el usuario hace
	## meses ("en la plantilla debe aparecer la cara del jugador") y es lo que
	## convierte una lista de nombres en un plantel.
	var celda := HBoxContainer.new()
	celda.add_theme_constant_override("separation", 5)
	var equipo: Club = mundo.clubes.get(j.club_id)
	var retrato := TextureRect.new()
	retrato.texture = Cara.textura(j, equipo.color1 if equipo else "#2b6b45",
		equipo.color2 if equipo else "#ffffff", 22)
	retrato.custom_minimum_size = Vector2(22, 22)
	retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	celda.add_child(retrato)
	var b := Button.new()
	b.text = columnas[0]
	b.flat = true
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_color_override("font_color", _color_de_paleta(colores[0]))
	## Pulsar a un jugador hace DOS cosas: enseña su ficha a la derecha y salta
	## al plantel en el centro. Antes solo hacía lo primero, así que tocar a
	## alguien desde la enfermería o la cantera te dejaba mirando su ficha con
	## la pestaña equivocada delante, y había que ir a buscarlo a mano.
	b.pressed.connect(func() -> void:
		_ver_ficha(j)
		_ir_a_pestana("Mi plantel"))
	celda.add_child(b)
	g.add_child(celda)
	for i in range(1, columnas.size()):
		_celda(g, columnas[i], colores[i], i >= 2)

# --- acciones ---------------------------------------------------------------

## El mundo completo -las 24 ligas, ~9.600 jugadores-, igual que genera el
## HTML siempre (`crear()` recorre TODO `PAISES_LIGAS`, nunca un subconjunto).
## Antes esta pantalla se conformaba con 3 países "porque no había nada que
## hacer con los otros 21", pero eso ya no es cierto: Selecciones y Cantera
## recorren el mundo entero buscando elegibles y candidatos, y las copas
## continentales necesitan clubes de muchos países para tener sentido. Y
## generarlo entero no cuesta lo que costaba en el navegador: 376 ms medidos
## aquí contra los "3,2 s" que el propio HTML dejó anotados en un comentario.
func _nuevo_mundo() -> void:
	mundo = Mundo.new()
	Escudo.limpiar_cache()
	Cara.limpiar_cache()
	mundo.generar([], 0)
	## Tomar el mando no es solo elegir club: es que la directiva te ponga un
	## objetivo y empiece a mirarte. Sin eso puedes acabar decimosexto veinte anos
	## seguidos y no pasa nada. Se abre esta escena directo -bancos, capturas- sin
	## pasar por el asistente: toca el primero de Chile, como siempre.
	mundo.tomar_el_mando(mundo.ligas[0].clubes[0].id)
	_arrancar_con(mundo)

## El camino compartido entre "Nueva partida directa" (arriba) y "vengo del
## asistente con un mundo ya generado y un club ya elegido"
## (`ui/eleccion_club.gd`, que deja `Principal.mundo_pregenerado`): aplicar
## dificultad y modo, conectar el registro, y pintar. Separado para no repetir
## estas seis líneas en dos sitios que tenían que estar siempre de acuerdo.
func _arrancar_con(m: Mundo) -> void:
	mundo = m
	_fin_partida_avisado = false
	## La dificultad: por ahora solo escala la caja inicial (el "plata" del
	## HTML, hasta 60% más en fácil o 45% menos en leyenda), que es lo que se
	## nota desde el primer minuto. Sigue sin escalar los premios de la
	## temporada ni las pretensiones salariales -"prem" y "pide" del HTML-,
	## que están repartidos en Finanzas y Mercado y quedan para otra tanda.
	var dif: Variant = Datos.tabla("DIF")
	if dif is Dictionary and (dif as Dictionary).has(Principal.dificultad_elegida):
		var plata := float((dif as Dictionary)[Principal.dificultad_elegida].get("plata", 1.0))
		mundo.mi_club().saldo = int(round(float(mundo.mi_club().saldo) * plata))
	## Los desafíos: "pobreza" pisaría la caja de la dificultad si fuera antes,
	## así que van después -es la letra pequeña ganándole a la general, como en
	## el HTML, donde `aplicarDesafios()` también corre después de fijar el
	## saldo por dificultad.
	if not Principal.desafios_elegidos.is_empty():
		mundo.desafios = Principal.desafios_elegidos.duplicate()
		mundo.aplicar_desafios()
		Principal.desafios_elegidos = []
	## El modo de carrera elegido en la pantalla previa. Si viene vacío -se
	## abrió esta escena directo, sin pasar por seleccion_modo.gd, como hacen
	## los bancos de prueba y las capturas- se queda el DT clásico de siempre.
	if Principal.modo_elegido != "":
		mundo.roles.arrancar(Principal.modo_elegido, Principal.dt_nombre_elegido)
		Principal.modo_elegido = ""
	_conectar_noticias()
	_seleccionado = null
	_llenar_selector()
	_escribir("[color=#8ea595]Mundo nuevo.[/color] Semilla [color=#3fa06a]%d[/color]" % mundo.semilla)
	_refrescar()

## La selección avisa de lo suyo (prenómina, convocatoria, lesión de gira,
## nacionalización) por señal en vez de por estado que alguna pantalla mire cada
## semana -no tiene pestaña de despacho propia como Prensa-, así que sin esto
## esas noticias pasaban de verdad pero nadie se enteraba nunca.
func _conectar_noticias() -> void:
	## `Directiva.despedido` se emite desde `mover_confianza()` -tras_partido(),
	## en mundo.gd linea 997- en cuanto la confianza toca fondo, que puede pasar
	## a MITAD de temporada por una mala racha, no solo al cerrarla. El banco de
	## pruebas ya comprobaba "una racha de derrotas acaba en despido", pero
	## nadie escuchaba la señal aquí: el despido ocurría de verdad dentro del
	## motor y el jugador seguía dirigiendo un club que ya lo había echado,
	## semana tras semana, sin un solo aviso -y `nueva_temporada()` tampoco lo
	## contaba nunca, porque se salta el veredicto de directiva si
	## `despedido_ya` ya estaba puesto (mundo.gd linea 715)-. Mismo aviso que ya
	## usa el cierre de temporada, para que se sienta igual de definitivo.
	if mundo.directiva != null:
		mundo.directiva.despedido.connect(func(motivo: String) -> void:
			_escribir("[color=#e05555][b]ESTÁS DESPEDIDO.[/b][/color] La directiva pierde la paciencia (%s) y te destituye a mitad de temporada. Elige tu próximo club entre las ofertas de abajo." % motivo)
			_anotar("ESTÁS DESPEDIDO.", "La directiva pierde la paciencia (%s) y te destituye a mitad de temporada." % motivo)
			## El momento más definitivo del juego: si algo merece interrumpir,
			## es que te acaben de echar.
			Aviso.mostrar(self, "alerta", "🚪", "ESTÁS DESPEDIDO",
				"La directiva te destituye tras la %s. Elige tu próximo club entre las ofertas de abajo." % motivo, "despido")
			## `Roles.gd` lo deja escrito en su propio comentario -"lo llama quien
			## atienda `Directiva.despedido`, DESPUÉS de comprobar
			## `le_pueden_echar()`"- y nadie lo llamaba NUNCA, ni siquiera al
			## vender el club: toda la pantalla de "sin banco" -ofertas de otros
			## clubes, `_pintar_sin_banco()`, ya escrita y probada- era
			## inalcanzable. `despedido` solo se emite con `puede_despedirte` ya
			## en true (sincronizado desde `le_pueden_echar()` en `mundo.gd`), así
			## que la comprobación que pide el comentario ya está hecha antes de
			## llegar aquí.
			mundo.roles.quedar_sin_banco())
	## `Banco.liquidado`: "el único sistema del juego que puede TERMINAR una
	## partida sin que pierdas un partido" -según su propio comentario de
	## cabecera- y NADIE la escuchaba (hallazgo de la auditoría de conectores
	## del 13-9-2026): doce semanas con la caja en rojo liquidaban el club
	## por dentro y el jugador seguía dirigiéndolo como si nada, sin aviso ni
	## consecuencia en pantalla. Mismo tratamiento que un despido -tiene el
	## mismo peso narrativo, "tu etapa aquí se acaba"- reusando
	## `quedar_sin_banco()`, que ya deja la pantalla de ofertas probada.
	if mundo.banco != null:
		mundo.banco.liquidado.connect(func() -> void:
			_escribir("[color=#e05555][b]EL CLUB SE LIQUIDA.[/b][/color] La deuda pudo más: la asociación toma el control y tu etapa aquí se acaba. Elige tu próximo club entre las ofertas de abajo.")
			_anotar("EL CLUB SE LIQUIDA.", "La deuda pudo más: la asociación liquida el club y tu etapa aquí se acaba.")
			Aviso.mostrar(self, "alerta", "💀", "EL CLUB SE LIQUIDA",
				"La deuda pudo más: la asociación toma el control y tu etapa aquí se acaba. Elige tu próximo club entre las ofertas de abajo.", "descenso_administrativo")
			mundo.roles.quedar_sin_banco())
	if mundo.selecciones != null:
		mundo.selecciones.noticia.connect(func(titulo: String, cuerpo: String) -> void:
			_escribir("[color=#c9a227][b]%s[/b][/color] %s" % [titulo, cuerpo])
			_anotar(titulo, cuerpo))
	if mundo.cantera != null:
		mundo.cantera.noticia.connect(func(titulo: String, cuerpo: String) -> void:
			_escribir("[color=#4caf6d][b]%s[/b][/color] %s" % [titulo, cuerpo])
			_anotar(titulo, cuerpo))
	if mundo.academia != null:
		mundo.academia.noticia.connect(func(titulo: String, cuerpo: String) -> void:
			_escribir("[color=#4caf6d][b]%s[/b][/color] %s" % [titulo, cuerpo])
			_anotar(titulo, cuerpo))
		mundo.academia.movimiento.connect(mundo._anotar_movimiento)
	if mundo.ojeadores != null:
		## El modelo de datos y las academias hablan por su propia senal: son
		## hallazgos y llegadas, no informes de ojeo, y se leen distinto.
		mundo.ojeadores.noticia_ojeo.connect(func(titulo: String, cuerpo: String) -> void:
			_escribir("[color=#c9a227][b]%s.[/b][/color] %s" % [titulo, cuerpo])
			_anotar(titulo, cuerpo))
		mundo.ojeadores.movimiento_ojeo.connect(mundo._anotar_movimiento)
		mundo.ojeadores.noticia.connect(func(titulo: String, cuerpo: String) -> void:
			_escribir("[color=#c9a227][b]%s[/b][/color] %s" % [titulo, cuerpo])
			_anotar(titulo, cuerpo))
	if mundo.logros != null:
		mundo.logros.logro_desbloqueado.connect(func(_clave: String, icono: String, titulo: String, descripcion: String) -> void:
			_escribir("[color=#c9a227][b]%s Logro: %s[/b][/color] %s" % [icono, titulo, descripcion])
			_anotar("%s Logro: %s" % [icono, titulo], descripcion)
			## Y el aviso deslizante con su sonido. Una línea más en el registro
			## se pierde entre las quince de la semana: un logro que no se
			## celebra no es un logro, es una fila de una tabla.
			Aviso.mostrar(self, "logro", icono, titulo, descripcion))
		mundo.logros.record_batido.connect(func(clave: String, _ficha: Dictionary) -> void:
			_escribir("[color=#c9a227][b]Nuevo récord del club:[/b][/color] %s" % Nombres.limpiar(clave).capitalize())
			_anotar("Nuevo récord del club:", Nombres.limpiar(clave).capitalize())
			Aviso.mostrar(self, "record", "📈", "Nuevo récord del club", Nombres.limpiar(clave).capitalize()))
		mundo.logros.efemeride_nueva.connect(func(_anio: int, texto: String) -> void:
			_escribir("[color=#8ea595]%s[/color]" % texto)
			_anotar("Un día como hoy", texto))
		mundo.logros.perfil_subio_de_nivel.connect(func(_nivel: int, nombre: String, lema: String) -> void:
			_escribir("[color=#4caf6d][b]Subes de nivel: %s.[/b][/color] %s" % [nombre, lema])
			_anotar("Subes de nivel: %s." % nombre, lema)
			Aviso.mostrar(self, "nivel", "⭐", "Subes de nivel: %s" % nombre, lema))
		mundo.logros.canterano_debuta.connect(func(j: Jugador) -> void:
			_escribir("[color=#4caf6d][b]Debut de la casa:[/b][/color] %s se estrena con el primer equipo." % j.nombre)
			_anotar("Debut de la casa:", "%s se estrena con el primer equipo." % j.nombre))
		## Antes solo sonaba la fanfarria: `celebrar_titulo()` la llama para la
		## liga, la copa nacional Y los continentales, pero solo la liga tenía
		## una línea propia en el registro (`_nueva_temporada()`, más abajo, con
		## el premio). Ganar la copa o una Champions/Libertadores -que además se
		## corona A MITAD DE TEMPORADA, según su propio comentario en
		## `mundo.gd:avanzar_semana()`, no al cerrar el año- pasaba con un solo
		## efecto de sonido y nada en el registro: había que entrar a Logros a
		## enterarse de qué se había ganado.
		mundo.logros.titulo_celebrado.connect(func(nombre: String) -> void:
			_escribir("[color=#c9a227][b]🏆 ¡CAMPEÓN![/b][/color] %s." % nombre)
			_anotar("🏆 ¡CAMPEÓN!", "%s." % nombre)
			## El aviso ya toca "trofeo" por su tipo: llamarlo aquí además lo
			## haría sonar dos veces.
			Aviso.mostrar(self, "titulo", "🏆", nombre, "Lo levantaste tú. Queda en la vitrina para siempre."))
		## La gala se calculaba entera y se guardaba sin que nadie la anunciara:
		## el jugador podía ganar el premio a mejor entrenador del año y no
		## enterarse jamás. Ahora avisa, y el detalle está en la pestaña Premios.
		mundo.logros.premios_entregados.connect(func(acta: Dictionary) -> void:
			var ganados: Array = acta.get("ganados", [])
			var cuerpo_gala := "Se entregan los premios de la temporada %d. " % int(acta.get("anio", 0))
			cuerpo_gala += ("Tu club se lleva: %s." % ", ".join(PackedStringArray(ganados))) if not ganados.is_empty() else "Tu club se va de vacío."
			_escribir("[color=#c9a227][b]🎬 Gala de fin de año.[/b][/color] %s" % cuerpo_gala)
			_anotar("🎬 Gala de fin de año.", cuerpo_gala))
	## `mercado` se crea una sola vez por partida en `Mundo.generar()` -no lo
	## recrea `tomar_el_mando()`-, así que si tomas otro club (despido, oferta
	## aceptada, "trotamundos") `_conectar_noticias()` vuelve a pasar por aquí
	## sobre el MISMO objeto: sin este candado cada oferta y cada traspaso de
	## la IA se habría anotado y sonado una vez más por cada club que tomaste.
	if mundo.mercado != null and not mundo.mercado.has_meta("_ui_conectado"):
		mundo.mercado.set_meta("_ui_conectado", true)
		mundo.mercado.oferta_recibida.connect(func(j: Jugador, c: Club, monto: int) -> void:
			Sonido.toca("moneda")
			_escribir("[color=#c9a227][b]📨 Oferta por %s.[/b][/color] %s ofrece %s. Respóndela en Mercado." % [
				j.nombre, c.nombre, _dinero(monto)])
			_anotar("📨 Oferta por %s." % j.nombre, "%s ofrece %s. Respóndela en Mercado." % [c.nombre, _dinero(monto)])
			Aviso.mostrar(self, "mercado", "📨", "Oferta por %s" % j.nombre,
				"%s ofrece %s. Tienes que responder." % [c.nombre, _dinero(monto)], "oferta"))
		## Los traspasos entre dos clubes de la IA -`_buscar_objetivo()` nunca
		## elige al tuyo como comprador ni como vendedor-: la señal existía desde
		## siempre pero no la escuchaba nadie, así que el mercado se movía en
		## silencio. Los tuyos no pasan por aquí: `_intentar_fichar()` y
		## `responder_oferta()` ya escriben su propio aviso.
		mundo.mercado.traspaso.connect(func(j: Jugador, de: Club, a: Club, _monto: int) -> void:
			## TU FICHAJE SE PRESENTA (C7): la tarjeta con su cara y tu camiseta.
			if a == mundo.mi_club():
				PresentacionFichaje.mostrar.call_deferred(self, mundo, j, de)
				return
			if de == mundo.mi_club():
				return
			_escribir("[color=#8ea595]🔁 %s pasa de %s a %s.[/color]" % [
				j.nombre, de.nombre if de else "?", a.nombre]))
	## `Mundo._informes_de_ojeo()` existía desde antes de esta tanda y ya
	## marcaba `ojeados[j.id]`, pero la señal no la escuchaba nadie: el ojeador
	## trabajaba en silencio y el informe no se veía en ningún sitio. Esto es
	## una versión reducida de la "RED DE OJEADORES CON NOMBRE Y SESGO" del
	## HTML -un ojeador de carne y hueso por país, con su propio sesgo y sus
	## renuncias-, que sigue sin portar: no hay pantalla dedicada ("Ojeadores"
	## en el menú del HTML) ni ojeadores individuales, solo el aviso de que
	## llegó un informe.
	## Esta va directo en `mundo`, no en un sub-sistema: `mundo` en sí es el
	## MISMO objeto durante toda la partida -solo cambia al cargar otra o
	## empezar de cero-, así que también hay que guardarla con candado o se
	## duplica cada vez que cambias de club sin salir de la partida.
	if not mundo.has_meta("_ui_conectado_ojeo"):
		mundo.set_meta("_ui_conectado_ojeo", true)
		mundo.informe_de_ojeo.connect(func(j: Jugador, club_suyo: Club) -> void:
			var cuerpo_oj := "%s · %s · %d años · media %d con proyección %d." % [club_suyo.nombre, j.pos_e, j.edad, j.ovr, j.pot]
			_escribir("[color=#c9a227][b]🔎 Informe de ojeo: %s.[/b][/color] %s" % [j.nombre, cuerpo_oj])
			_anotar("🔎 Informe de ojeo: %s." % j.nombre, cuerpo_oj))
	## LOS INGRESOS DE COPA. `Copa.campeon_proclamado` y `ronda_terminada` se
	## emitían desde siempre sin que nadie las escuchara: el premio entraba en la
	## caja en silencio y avanzar de ronda -que es lo que da el dinero- no se
	## notaba. Aquí solo interesa TU club: los otros 383 también cobran.
	## `copa` tampoco se recrea al cambiar de club dentro de la misma partida
	## -solo `_montar_copa()` la crea, y solo si es null-: mismo candado que
	## `mercado` arriba, para no celebrar el mismo título o la misma ronda dos
	## veces si cambias de club a mitad de temporada.
	if mundo.copa != null and not mundo.copa.has_meta("_ui_conectado"):
		mundo.copa.set_meta("_ui_conectado", true)
		mundo.copa.campeon_proclamado.connect(func(campeon: Club) -> void:
			if campeon == mundo.mi_club():
				Aviso.mostrar(self, "dinero", "🏆", "Campeón de %s" % mundo.copa.nombre,
					"Además del título, entran %s de premio." % _dinero(Copa.PREMIO)))
		mundo.copa.ronda_terminada.connect(func(nombre_ronda: String, resultados: Array) -> void:
			for r: Dictionary in resultados:
				var gano: Club = r.get("pasa")
				if gano == mundo.mi_club():
					Aviso.mostrar(self, "dinero", "🎟️", "Pasas de ronda",
						"%s superada. Cada eliminatoria que se gana es taquilla y premio." % nombre_ronda, "ronda_superada")
					return)
	## Lo mismo para Champions/Libertadores -mismo bug, sin arreglar hasta hoy
	## (14-9-2026): ver `_conectar_mi_continental()`, llamada desde
	## `_conectar_sorteos()` mas abajo porque comparten el mismo ciclo de vida
	## (hay que reconectar tras cada resorteo, no solo la primera vez).
	## `Instalaciones.avanzar_semana()` devuelve las obras que acaban de
	## terminar, y `Mundo.avanzar_semana()` (línea 540) las reemite como
	## `obra_lista` con un comentario explícito: "para que la noticia de 'obra
	## terminada' salga la misma semana en que termina". La intención estaba
	## escrita desde que se creó la señal; nadie la conectó nunca. Construir un
	## nivel de instalación cuesta semanas y millones y hoy no avisa de nada:
	## solo se nota si el jugador entra a mirar la pestaña Club por su cuenta.
	## Misma razón que `informe_de_ojeo`: señal del propio `mundo`, candado
	## propio para no avisar la misma obra terminada dos veces.
	if not mundo.has_meta("_ui_conectado_obra"):
		mundo.set_meta("_ui_conectado_obra", true)
		mundo.obra_lista.connect(func(clave: String) -> void:
			var nombre_obra: String = String(Instalaciones.CATALOGO[clave][0]) if Instalaciones.CATALOGO.has(clave) else clave
			var cuerpo_obra := "%s llega a nivel %d." % [nombre_obra, mundo.obras.nivel(clave)]
			_escribir("[color=#c9a227][b]🏗️ Obra terminada:[/b][/color] %s" % cuerpo_obra)
			_anotar("🏗️ Obra terminada:", cuerpo_obra)
			## Una obra son semanas de espera y millones: cuando por fin termina, se
			## avisa. Es de lo poco que el jugador PIDIÓ que pasara y luego olvidó.
			Aviso.mostrar(self, "dinero", "🏗️", "Obra terminada", cuerpo_obra, "inauguracion_obra"))
	## `procesoLibres()` del HTML: rarísima vez (4%) aparece un agente libre de
	## calidad. Es lo bastante especial para tener su propio aviso -no el
	## genérico de "hay agentes libres nuevos", que sería ruido cada semana-.
	## Misma razón otra vez: candado propio para el agente libre de lujo.
	if not mundo.has_meta("_ui_conectado_libre"):
		mundo.set_meta("_ui_conectado_libre", true)
		mundo.libre_estrella.connect(func(j: Jugador) -> void:
			var cuerpo_le := "%s (%d años, media %d) quedó sin club. %s. No estará mucho tiempo disponible." % [
				j.nombre, j.edad, j.ovr, j.motivo_libre]
			_escribir("[color=#c9a227][b]⭐ Agente libre de lujo en el mercado.[/b][/color] %s" % cuerpo_le)
			_anotar("⭐ Agente libre de lujo en el mercado.", cuerpo_le))
	## `Medico.revisar_semana()` corre cada semana desde `Mundo.avanzar_semana()`
	## -linea 492- pero devuelve una lista que nadie recogia, "para que la
	## interfaz lo cuente sin tener que rastrear a nadie" segun su propio
	## comentario, y ademas ninguna de sus cuatro señales estaba conectada: la
	## enfermeria solo se veia entrando a la pestaña a mirar, nunca avisaba de
	## nada por su cuenta.
	if mundo.medico != null:
		mundo.medico.lesion_nueva.connect(func(j: Jugador, semanas: int, tipo: String, causa: String) -> void:
			if j.club_id == mundo.mi_club_id:
				var cuerpo_l := "%s (%s), %d semana%s fuera." % [tipo, causa, semanas, "" if semanas == 1 else "s"]
				_escribir("[color=#e05555]🩹 %s se lesiona: %s[/color]" % [j.nombre, cuerpo_l])
				_anotar("🩹 %s se lesiona" % j.nombre, cuerpo_l)
				## Solo las GRAVES interrumpen. Un tirón de dos semanas es
				## rutina; perder a alguien un mes y medio cambia la temporada,
				## y es justo lo que se pasa por alto leyendo el registro.
				if semanas >= 6:
					Aviso.mostrar(self, "alerta", "🚑", "Lesión grave: %s" % j.nombre,
						"%s. Se pierde %d semanas." % [tipo, semanas], "medico_parte")
				## LA VENTANA DE EMERGENCIA. `Roles.gd` lo deja escrito en su propio
				## comentario -"quien lleve las lesiones la abre llamando a
				## abrir_emergencia()"- y nadie la llamaba: perder a un titular 12+
				## semanas con el mercado cerrado nunca destrababa el fichaje de
				## emergencia que el motor ya sabe conceder (banner, consumo con
				## `usar_emergencia()`, gatillo en `puede_fichar()`, todo ya escrito
				## y sin nadie que lo encendiera). Mismo umbral y misma doble
				## condición del HTML (`ventanaEmergencia()`): titular del once, o
				## un nivel cercano al del club aunque no lo fuera.
				if semanas >= 12 and not mundo.mercado_abierto() and mundo.roles != null:
					var mio := mundo.mi_club()
					if mio != null and (mio.once().has(j) or j.ovr >= mio.rep - 6):
						mundo.roles.abrir_emergencia(j.id))
		mundo.medico.recaida.connect(func(j: Jugador, semanas: int, tipo: String) -> void:
			if j.club_id == mundo.mi_club_id:
				var cuerpo_r := "vuelve a caer de %s, %d semana%s más." % [tipo, semanas, "" if semanas == 1 else "s"]
				_escribir("[color=#e05555]🩹 Recaída de %s:[/color] %s" % [j.nombre, cuerpo_r])
				_anotar("🩹 Recaída de %s" % j.nombre, cuerpo_r))
		mundo.medico.recuperado.connect(func(j: Jugador) -> void:
			if j.club_id == mundo.mi_club_id:
				_escribir("[color=#4caf6d]✅ %s recibe el alta médica.[/color]" % j.nombre)
				_anotar("✅ Alta médica", "%s recibe el alta médica." % j.nombre))
		mundo.medico.informe_listo.connect(func(j: Jugador, informe: Dictionary) -> void:
			var cuerpo_i := "Riesgo: %s. Lesiones graves: %d." % [String(informe.get("riesgo", "?")), int(informe.get("graves", 0))]
			_escribir("[color=#c9a227][b]🩺 Informe médico de %s.[/b][/color] %s" % [j.nombre, cuerpo_i])
			_anotar("🩺 Informe médico de %s." % j.nombre, cuerpo_i))
	## Estas cinco emiten `noticia` desde hace tiempo -44 sitios entre las
	## cinco- y hasta hoy no las escuchaba nadie: pasaban de verdad y no se
	## veían en ninguna pantalla.
	##
	## OJO: `federacion` NO se recrea al tomar el mando de otro club -lo dice
	## su propio comentario en `Mundo`-, asi que `_conectar_noticias()` pasa por
	## aqui mas de una vez sobre el MISMO objeto. Eso SI se comprobaba para
	## `movimiento` (con `is_connected`, porque es un metodo con nombre, siempre
	## el mismo Callable) pero NO para `noticia`: cada `func(...)` de abajo es un
	## Callable NUEVO en cada paso, asi que `is_connected` nunca lo hubiera
	## encontrado y Godot tampoco avisa con error -son lambdas distintas, no la
	## misma conexion repetida-. El resultado real, encontrado en la auditoria
	## del 14-9-2026: cada vez que tomabas otro club (despido, oferta aceptada,
	## "trotamundos"), cada noticia de la federacion -votaciones, licencia,
	## tribunal, control antidopaje- se imprimia una vez mas de las que tocaba.
	## Mismo candado que ya usan `cesiones`, `mercado`, `eras` y `roles` aqui
	## abajo para el mismo problema.
	if mundo.federacion != null and not mundo.federacion.has_meta("_ui_conectado"):
		mundo.federacion.set_meta("_ui_conectado", true)
		mundo.federacion.noticia.connect(func(titulo: String, cuerpo: String) -> void:
			_escribir("[color=#c9a227][b]%s[/b][/color] %s" % [titulo, cuerpo])
			_anotar(titulo, cuerpo))
		## El dinero de la federacion -multas del cupo juvenil, bonificaciones por
		## minutos de sub-21- YA va al libro: `Mundo.tomar_el_mando()` conecta
		## `federacion.movimiento` a `_anotar_movimiento` con su propio candado
		## `is_connected()` (es una de las "siete fuentes" del libro, junto a
		## estadio/cesiones/cantera/prensa/selecciones). Repetir la conexión aquí
		## -encontrado 14-9-2026- no duplicaba el dinero -Godot rechaza la segunda
		## conexion sin conectarla-, pero SÍ imprimía un ERROR real en cada
		## partida nueva desde el primer segundo, siempre. Quitado: no hace falta,
		## el núcleo ya lo tiene cubierto.
		## `castigo_directiva`/`escandalo` (auditoría 14-9-2026): el propio
		## comentario de cabecera de `Federacion` pide conectarlas -"no son suyas,
		## solo dice cuánto se mueven y por qué"- y nadie lo hacía: licencia
		## denegada, dopaje, incumplir el cupo juvenil y el fair play financiero no
		## le movían un punto a la confianza de la directiva ni a la funa de la
		## hinchada, pese a que el texto de la propia noticia ya lo prometía
		## ("la hinchada... te lo van a cobrar"). El texto ya lo cuenta `noticia`;
		## aquí solo se aplica el número, sin aviso aparte, igual que hace
		## `movimiento` con la caja.
		mundo.federacion.castigo_directiva.connect(func(delta: int, motivo: String) -> void:
			if mundo.directiva != null:
				mundo.directiva.mover_confianza(delta, motivo))
		mundo.federacion.escandalo.connect(func(funa: int, motivo: String) -> void:
			if mundo.prensa != null:
				mundo.prensa._mover_funa(funa))
	## `cesiones` vive desde `generar()`, igual que `federacion` -ver el
	## comentario de `federacion.movimiento` más abajo-, así que sus tres
	## señales necesitan el mismo candado o se duplican al cambiar de club.
	if mundo.cesiones != null and not mundo.cesiones.has_meta("_ui_conectado"):
		mundo.cesiones.set_meta("_ui_conectado", true)
		mundo.cesiones.noticia.connect(func(titulo: String, cuerpo: String) -> void:
			_escribir("[color=#3fa06a][b]%s[/b][/color] %s" % [titulo, cuerpo])
			_anotar(titulo, cuerpo))
		## QUE ALGUIEN PAGUE LA CLÁUSULA DE UNO DE LOS TUYOS es de las peores
		## noticias que puede recibir un entrenador, y hasta ahora era una línea
		## gris entre otras quince. Merece interrumpir.
		mundo.cesiones.clausula_pagada.connect(func(j: Jugador, de: Club, a: Club, monto: int) -> void:
			if de == mundo.mi_club():
				Aviso.mostrar(self, "alerta", "💥", "Te pagaron la cláusula",
					"%s se va a %s por %s. No hubo nada que negociar." % [j.nombre, a.nombre, _dinero(monto)])
			elif a == mundo.mi_club():
				Aviso.mostrar(self, "mercado", "✍️", "Clausulazo",
					"%s es tuyo: pagaste su cláusula de %s." % [j.nombre, _dinero(monto)], "oferta_aceptada"))
		## Y las plusvalías: dinero que entra sin hacer nada, porque te guardaste
		## un porcentaje al vender. Es la recompensa de una decisión vieja.
		mundo.cesiones.vendido.connect(func(j: Jugador, comprador: Club, neto: int) -> void:
			Aviso.mostrar(self, "dinero", "💰", "Venta cerrada",
				"%s se va a %s. Entran %s." % [j.nombre, comprador.nombre, _dinero(neto)], "venta"))
	## `estadio` -como `federacion` y `cesiones`- vive desde que se crea el Mundo,
	## no se recrea al cambiar de club: mismo candado por el mismo motivo.
	## `reforma_hecha` (14-9-2026): `reformar()` siempre devuelve "" en éxito, así
	## que cuando el jugador pide más bandejas de las que `Instalaciones` permite
	## hoy, la reforma se aplicaba RECORTADA -"se quedó en N bandeja(s)"- y pagaba
	## el coste completo sin que la interfaz dijera una palabra del recorte: el
	## aviso solo viajaba dentro de esta señal, sin conectar.
	if mundo.estadio != null and not mundo.estadio.has_meta("_ui_conectado"):
		mundo.estadio.set_meta("_ui_conectado", true)
		mundo.estadio.reforma_hecha.connect(func(_aplicados: Dictionary, _coste: int, aviso: String) -> void:
			if aviso != "":
				_escribir("[color=#c9a227]🏟️ %s[/color]" % aviso)
				_anotar("🏟️ Reforma recortada", aviso))
	_conectar_sorteos()
	## EL BANCO. La deuda es el único sistema que puede terminar la partida sin
	## perder un partido, así que sus avisos van con marco propio y sonido: si
	## pasaran como una línea más del registro, el jugador llegaría a la semana
	## doce sin haberse enterado de nada.
	if mundo.banco != null:
		mundo.banco.aviso.connect(func(titulo: String, texto: String) -> void:
			_escribir("[color=#e05555][b]%s.[/b][/color] %s" % [titulo, texto])
			_anotar(titulo, texto)
			Aviso.mostrar(self, "alerta", "🏦", titulo, texto))
		## El libro de movimientos lo lleva `Mundo`, no la pantalla: es el mismo
		## sitio donde se anotan taquilla, sueldos y fichajes.
		mundo.banco.movimiento.connect(mundo._anotar_movimiento)
	## LA HINCHADA (13-9-2026, hallazgo de la auditoría de conectores): tenía
	## sus dos señales -campañas de abonos, la barra plantándose, encuestas a
	## los socios- escritas y disparándose de verdad desde hace tiempo, y
	## NINGUNA llegaba a la pantalla -mismo patrón que ya se vio con
	## selecciones/cantera/logros/cesiones en sesiones anteriores: el motor
	## corría solo y en silencio-. Se crea de nuevo en cada `tomar_el_mando()`
	## (igual que `banco`/`ciudad`/`comercial`, arriba), así que no hace falta
	## candado.
	if mundo.hinchada != null:
		mundo.hinchada.noticia.connect(func(titulo: String, texto: String) -> void:
			_escribir("[color=#c9a227][b]%s.[/b][/color] %s" % [titulo, texto])
			_anotar(titulo, texto))
		mundo.hinchada.movimiento.connect(mundo._anotar_movimiento)
	## EL AUSPICIO. La pretemporada abre el mercado de marcas y sin aviso pasaria
	## desapercibido: es el unico ingreso grande del club que hay que ir a firmar.
	## LAS EPOCAS DORADAS. Una generacion entera de un pais entero, con fecha de
	## caducidad: si pasara sin aviso, no habria forma de aprovecharla.
	## LA CARRERA POR DENTRO: el rival personal que aparece solo, la leyenda que
	## se queda de por vida y los dividendos de tus clubes. Sin aviso, las tres
	## pasarian en silencio en una pestana que no se mira cada semana.
	## `roles` se crea una sola vez en `generar()` -`tomar_el_mando()` reusa el
	## mismo objeto, solo le cambia el capítulo (ver `roles.rol_cambiado` un
	## poco más arriba, que ya se guarda con `is_connected`)-: mismo candado
	## aquí, con clave propia para no chocar con el otro bloque de `roles` más
	## abajo (aviso/ascenso/interinato), que se guarda aparte.
	if mundo.roles != null and not mundo.roles.has_meta("_ui_conectado_carrera"):
		mundo.roles.set_meta("_ui_conectado_carrera", true)
		mundo.roles.noticia_carrera.connect(func(titulo: String, texto: String) -> void:
			_escribir("[color=#c9a227][b]%s.[/b][/color] %s" % [titulo, texto])
			_anotar(titulo, texto))
	## LO COMERCIAL: zonas de camiseta, naming del estadio y palcos. Cada firma
	## y cada contrato que caduca son noticia: si pasaran callados, la pantalla
	## estaria llena de contratos que aparecen y desaparecen solos.
	## LA CIUDAD: permisos que se resuelven, sanciones que caducan y negocios que
	## se inauguran. El permiso tarda semanas y llega solo: sin aviso, el jugador
	## no se entera de que ya puede ampliar el estadio.
	if mundo.ciudad != null:
		mundo.ciudad.noticia.connect(func(titulo: String, texto: String) -> void:
			_escribir("[color=#c9a227][b]%s.[/b][/color] %s" % [titulo, texto])
			_anotar(titulo, texto)
			Aviso.mostrar(self, "contrato", "🏙️", titulo, texto, "patrocinio_nuevo"))
		mundo.ciudad.movimiento.connect(mundo._anotar_movimiento)
	if mundo.junta != null and not mundo.junta.movimiento.is_connected(mundo._anotar_movimiento):
		mundo.junta.movimiento.connect(mundo._anotar_movimiento)
	if mundo.comercial != null:
		mundo.comercial.noticia.connect(func(titulo: String, texto: String) -> void:
			_escribir("[color=#c9a227][b]%s.[/b][/color] %s" % [titulo, texto])
			_anotar(titulo, texto))
		mundo.comercial.movimiento.connect(mundo._anotar_movimiento)
	## `eras` es del MUNDO, no de tu club -se crea una vez en `generar()` y su
	## propio comentario dice que no se recrea al tomar el mando-, así que
	## necesita el mismo candado que `mercado`, `copa` y `cesiones`.
	if mundo.eras != null and not mundo.eras.has_meta("_ui_conectado"):
		mundo.eras.set_meta("_ui_conectado", true)
		mundo.eras.noticia.connect(func(titulo: String, texto: String) -> void:
			_escribir("[color=#c9a227][b]%s.[/b][/color] %s" % [titulo, texto])
			_anotar(titulo, texto)
			Aviso.mostrar(self, "logro", "🌍", titulo, texto))
	if mundo.auspicio != null:
		mundo.auspicio.noticia.connect(func(titulo: String, texto: String) -> void:
			_escribir("[color=#e0a832][b]%s.[/b][/color] %s" % [titulo, texto])
			_anotar(titulo, texto)
			Aviso.mostrar(self, "contrato", "👕", titulo, texto, "patrocinio_nuevo"))
	if mundo.entrenamiento != null:
		mundo.entrenamiento.noticia.connect(func(titulo: String, cuerpo: String) -> void:
			_escribir("[color=#3fa06a][b]%s[/b][/color] %s" % [titulo, cuerpo])
			_anotar(titulo, cuerpo))
		## Otra señal muda: cada diez semanas ganas un punto para tu árbol y no
		## te enterabas de nada. Un punto sin gastar es de las pocas cosas del
		## juego que no caducan, así que merece aviso propio y no solo registro.
		mundo.entrenamiento.punto_dt_ganado.connect(func(total: int) -> void:
			Aviso.mostrar(self, "nivel", "🎓", "Punto de entrenador",
				"Tienes %d punto(s) para gastar en tus habilidades, en Club › Legado." % total))
		## `progreso` se emite cada vez que el entrenamiento semanal sube o baja el
		## OVR de un jugador -menores de 24 progresando, veteranos de 31+ apagándose-
		## y hasta hoy (14-9-2026) nadie la escuchaba: la única forma de enterarse
		## era abrir la ficha de cada jugador y comparar el número a ojo. Sin
		## `Aviso` modal a propósito -puede dispararse varias veces la misma
		## semana- , va al registro como el resto de novedades del plantel.
		mundo.entrenamiento.progreso.connect(func(j: Jugador, antes: int, ahora: int) -> void:
			if ahora == antes:
				return
			if ahora > antes:
				_anotar("📈 %s mejora" % j.nombre, "Sube de %d a %d de media." % [antes, ahora])
			else:
				_anotar("📉 %s decae" % j.nombre, "Baja de %d a %d de media." % [antes, ahora]))
	if mundo.prensa != null:
		mundo.prensa.noticia.connect(func(titulo: String, cuerpo: String) -> void:
			_escribir("[color=#8ea595][b]%s[/b][/color] %s" % [titulo, cuerpo])
			_anotar(titulo, cuerpo))
		## EL MENTOR COMENTA (C1): su cara y dos frases sobre lo que acaba de
		## pasar, fuera del tutorial.
		if mundo.junta != null:
			mundo.junta.noticia.connect(func(titulo: String, cuerpo: String) -> void:
				_escribir("[color=#c9a227][b]%s[/b][/color] %s" % [titulo, cuerpo])
				_anotar(titulo, cuerpo))
		mundo.prensa.mentor_dice.connect(func(titulo: String, texto: String) -> void:
			MentorVoz.decir(self, mundo, titulo, texto))
		## LA PORTADA DEL LUNES, COMO PERIÓDICO (C20): si la semana dejó una
		## portada nueva, se abre sola (se puede desactivar en la propia hoja).
		mundo.semana_avanzada.connect(func(_s: int, _a: int) -> void:
			call_deferred("_portada_nueva")
			call_deferred("_al_paso_nuevo"))
		for con_mentor: Object in [mundo.calendario, mundo.politica, mundo.vida]:
			if con_mentor != null:
				con_mentor.mentor.connect(func(titulo: String, texto: String) -> void:
					MentorVoz.decir(self, mundo, titulo, texto))
		for fuente: Object in [mundo.trabajadores, mundo.eventos_cantera, mundo.calendario, mundo.politica, mundo.contratos, mundo.vida, mundo.maestria]:
			if fuente != null:
				fuente.noticia.connect(func(titulo: String, cuerpo: String) -> void:
					_escribir("[color=#c9a227][b]%s[/b][/color] %s" % [titulo, cuerpo])
					_anotar(titulo, cuerpo))
				if fuente.has_signal("movimiento"):
					fuente.movimiento.connect(mundo._anotar_movimiento)
		if mundo.licencia != null:
			mundo.licencia.noticia.connect(func(titulo: String, cuerpo: String) -> void:
				_escribir("[color=#c9a227][b]%s[/b][/color] %s" % [titulo, cuerpo])
				_anotar(titulo, cuerpo)
				Aviso.mostrar(self, "nivel", "🎓", titulo, cuerpo))
		if mundo.charlas != null:
			mundo.charlas.noticia.connect(func(titulo: String, cuerpo: String) -> void:
				_escribir("[color=#4caf6d][b]%s[/b][/color] %s" % [titulo, cuerpo])
				_anotar(titulo, cuerpo))
	if mundo.vestuario != null:
		mundo.vestuario.noticia.connect(func(titulo: String, cuerpo: String) -> void:
			_escribir("[color=#4caf6d][b]%s[/b][/color] %s" % [titulo, cuerpo])
			_anotar(titulo, cuerpo))
		## `clan_enfadado`/`rol_incumplido`: el castigo de moral/ansiedad SIEMPRE se
		## aplica, pero `noticia` (arriba) solo sale un 45%/18% de las veces -a
		## propósito, representa que la interna se filtra a la prensa o no-. Hasta
		## hoy (14-9-2026) esas dos señales no tenían NINGÚN canal propio, así que
		## el otro 55%/82% de las veces la moral bajaba sin que nada lo explicara.
		## Van solo al correo -no al registro ni a un Aviso modal-, porque cuando SÍ
		## coincide con la filtración mediática ya se cuenta por partida doble.
		mundo.vestuario.clan_enfadado.connect(func(clan: Dictionary, lider: Jugador) -> void:
			_anotar("😠 Camarilla de %s enfadada" % lider.nombre,
				"«%s» baja el ánimo por tener a %s fuera del once. Moral y ansiedad del grupo, afectadas." % [
					String(clan.get("nombre", "")), lider.nombre]))
		mundo.vestuario.rol_incumplido.connect(func(j: Jugador, ratio: float) -> void:
			_anotar("😞 %s, descontento con su rol" % j.nombre,
				"Lleva %d%% de titularidades, por debajo de lo prometido. Pierde moral." % int(round(ratio * 100.0))))
	## El pulso de la carrera -Roles- no tenia NINGUN gancho hasta hoy: ni
	## tras_partido() ni tras_jornada() ni tras_temporada() se llamaban nunca,
	## asi que el interinato no se resolvia solo, un ayudante no ascendia nunca
	## y el prestigio no se movia. Son justo los eventos que hacen que dirigir
	## de interino o de ayudante SE SIENTA distinto de dirigir de DT.
	## Mismo `roles` reutilizado, clave propia para este segundo bloque -ver
	## el comentario de `roles.noticia_carrera` más arriba-.
	if mundo.roles != null and not mundo.roles.has_meta("_ui_conectado_rol"):
		mundo.roles.set_meta("_ui_conectado_rol", true)
		mundo.roles.aviso.connect(func(titulo: String, texto: String) -> void:
			_escribir("[color=#c9a227][b]%s[/b][/color] %s" % [titulo, texto])
			_anotar(titulo, texto))
		mundo.roles.ascenso.connect(func(nuevo_rol: String) -> void:
			_escribir("[color=#4caf6d][b]Asciendes.[/b][/color] Tu nuevo cargo: %s." % nuevo_rol.capitalize())
			_anotar("Asciendes.", "Tu nuevo cargo: %s." % nuevo_rol.capitalize()))
		mundo.roles.interinato_resuelto.connect(func(salvado: bool) -> void:
			if salvado:
				_escribir("[color=#4caf6d][b]Salvaste al club.[/b][/color] El interinato termina y vuelves a tener proyecto.")
				_anotar("Salvaste al club.", "El interinato termina y vuelves a tener proyecto.")
			else:
				_escribir("[color=#e05555][b]No alcanzó.[/b][/color] Se acaban tus cinco fechas de interino sin salvar al club.")
				_anotar("No alcanzó.", "Se acaban tus cinco fechas de interino sin salvar al club."))
		mundo.roles.sin_banco.connect(func(club: String) -> void:
			_escribir("[color=#8ea595][b]Sin banco.[/b][/color] Ya no diriges en %s." % club)
			_anotar("Sin banco.", "Ya no diriges en %s." % club))

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

func _abrir_elegir_club() -> void:
	if _dlg_club != null and is_instance_valid(_dlg_club):
		_dlg_club.queue_free()
	_dlg_club = Window.new()
	_dlg_club.title = "Elegir club"
	_dlg_club.size = Vector2i(880, 620)
	_dlg_club.transient = true
	_dlg_club.exclusive = true
	_dlg_club.close_requested.connect(func() -> void:
		_dlg_club.queue_free()
		_dlg_club = null)
	add_child(_dlg_club)
	var fondo := ColorRect.new()
	fondo.color = _pal_fondo()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dlg_club.add_child(fondo)
	var caja := MarginContainer.new()
	caja.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.add_theme_constant_override("margin_left", 14)
	caja.add_theme_constant_override("margin_right", 14)
	caja.add_theme_constant_override("margin_top", 12)
	caja.add_theme_constant_override("margin_bottom", 12)
	_dlg_club.add_child(caja)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	caja.add_child(col)
	_pais_elegido = mundo.mi_club().pais if mundo.mi_club() != null else ""
	_pintar_elegir_club(col)
	_dlg_club.popup_centered()

func _pintar_elegir_club(col: VBoxContainer) -> void:
	for h in col.get_children():
		h.queue_free()

	var t := _texto(14, COL_ACENTO)
	t.text = "¿DÓNDE QUIERES EMPEZAR?"
	col.add_child(t)

	## Los países que tienen liga, con cuántos clubes hay en cada uno.
	var por_pais := {}
	for l: Liga in mundo.ligas:
		por_pais[l.pais] = int(por_pais.get(l.pais, 0)) + l.clubes.size()
	var nombres: Dictionary = Datos.tabla("PAIS_SELECCION")

	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	col.add_child(flow)
	for p: String in por_pais:
		var pais := p
		var b := Button.new()
		b.text = "%s  (%d)" % [String(nombres.get(pais, pais)) if nombres != null else pais, int(por_pais[pais])]
		b.add_theme_font_size_override("font_size", 11)
		b.toggle_mode = true
		b.button_pressed = _pais_elegido == pais
		b.clip_text = true
		b.custom_minimum_size = Vector2(120, 26)
		b.pressed.connect(func() -> void:
			_pais_elegido = pais
			_pintar_elegir_club(col))
		flow.add_child(b)

	if _pais_elegido == "":
		return

	## EL MAPA. Se pinta con el color del club que ya diriges, para que el país
	## no sea un dibujo suelto sino EL sitio donde está tu club.
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	fila.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(fila)

	var marco := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = _pal_panel()
	estilo.border_color = COL_ACENTO
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(8)
	estilo.content_margin_left = 10
	estilo.content_margin_right = 10
	estilo.content_margin_top = 10
	estilo.content_margin_bottom = 10
	marco.add_theme_stylebox_override("panel", estilo)
	marco.custom_minimum_size = Vector2(240, 0)
	fila.add_child(marco)
	var colm := VBoxContainer.new()
	colm.add_theme_constant_override("separation", 6)
	marco.add_child(colm)
	var tn := _texto(13, COL_TEXTO)
	tn.text = String(nombres.get(_pais_elegido, _pais_elegido)) if nombres != null else _pais_elegido
	tn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	colm.add_child(tn)
	var lienzo := Control.new()
	lienzo.custom_minimum_size = Vector2(200, 240)
	colm.add_child(lienzo)
	var pol := MapaPais.poligono(_pais_elegido, Vector2(200, 240))
	if pol.size() >= 3:
		var forma := Polygon2D.new()
		forma.polygon = pol
		forma.color = COL_ACENTO
		lienzo.add_child(forma)
		## El contorno por encima, más claro: una silueta plana se lee como una
		## mancha, y con borde se reconoce el país.
		var borde := Line2D.new()
		borde.points = pol
		borde.closed = true
		borde.width = 2.0
		borde.default_color = COL_TEXTO
		lienzo.add_child(borde)
	else:
		var sin := _texto(10, COL_SUAVE)
		sin.text = "(sin silueta para este país)"
		colm.add_child(sin)

	## LOS CLUBES DEL PAÍS, con lo que de verdad se compara al elegir: escudo,
	## reputación, división y aforo.
	var lista := ScrollContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fila.add_child(lista)
	var colc := VBoxContainer.new()
	colc.add_theme_constant_override("separation", 3)
	colc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_child(colc)

	var clubes: Array[Club] = []
	for l2: Liga in mundo.ligas:
		if l2.pais == _pais_elegido:
			for c2: Club in l2.clubes:
				clubes.append(c2)
	clubes.sort_custom(func(a: Club, b: Club) -> bool: return a.rep > b.rep)
	for c3: Club in clubes:
		var club := c3
		var f := HBoxContainer.new()
		f.add_theme_constant_override("separation", 8)
		colc.add_child(f)
		var esc := TextureRect.new()
		esc.texture = Escudo.textura(club, 26)
		esc.custom_minimum_size = Vector2(26, 26)
		esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		f.add_child(esc)
		var b2 := Button.new()
		var mio := club.id == mundo.mi_club_id
		b2.text = "%s%s" % ["★ " if mio else "", club.nombre]
		b2.flat = true
		b2.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b2.add_theme_font_size_override("font_size", 13)
		b2.add_theme_color_override("font_color", _color_de_paleta(COL_ORO if mio else COL_TEXTO))
		b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b2.clip_text = true
		b2.pressed.connect(func() -> void:
			_tomar_club(club.id))
		f.add_child(b2)
		var d := _texto(11, COL_SUAVE)
		d.text = "D%d  ·  rep %d  ·  %s butacas" % [club.division, club.rep, _miles(club.estadio_aforo)]
		d.custom_minimum_size = Vector2(190, 0)
		f.add_child(d)

func _tomar_club(id: String) -> void:
	mundo.tomar_el_mando(id)
	_conectar_noticias()
	_seleccionado = null
	_llenar_selector()
	if _dlg_club != null and is_instance_valid(_dlg_club):
		_dlg_club.queue_free()
		_dlg_club = null
	_escribir("[color=#3fa06a][b]Tomas el mando de %s.[/b][/color] %s" % [
		mundo.mi_club().nombre, mundo.directiva.objetivo if mundo.directiva != null else ""])
	_refrescar()

func _llenar_selector() -> void:
	_selector.clear()
	var i := 0
	for l in mundo.ligas:
		for c in l.clubes:
			_selector.add_item("%s  ·  %s" % [c.nombre, l.nombre])
			_selector.set_item_metadata(i, c.id)
			if c.id == mundo.mi_club_id:
				_selector.select(i)
			i += 1

## El menú "📅 Calendario" -antes cuatro botones sueltos que ya no entraban en
## la fila-. `match` dentro de un lambda pasado como argumento le rompía el
## parser a `principal.gd` entero -"Expected expression for match pattern",
## y de ahí en cascada TODAS las demás llamadas de la pantalla fallaban con
## "Nonexistent function"-, así que el manejador vive aquí, con nombre propio.
func _al_elegir_calendario(id: int) -> void:
	match id:
		0: _dirigir()
		1: _avanzar_semana()
		2: _jugar_temporada()
		3: _nueva_temporada()

func _al_elegir_club(indice: int) -> void:
	mundo.tomar_el_mando(String(_selector.get_item_metadata(indice)))
	## tomar_el_mando() crea una Seleccion nueva -la del pais de este club-, asi
	## que hay que volver a engancharle el aviso de noticias.
	_conectar_noticias()
	_seleccionado = null
	_refrescar()

## Abre el partido de esta jornada en directo. Al terminar, el resultado que
## salga en la pantalla es el que va a la tabla: el mundo simula el resto de la
## jornada pero NO vuelve a jugar el tuyo.
func _dirigir() -> void:
	if not mundo.temporada_en_curso():
		_escribir("[color=#e05555]La temporada está terminada.[/color]")
		return
	## Si esta semana hay copa, manda la copa: es la que se juega a un solo
	## partido y la que se puede perder para siempre.
	var par := mundo.partido_de_copa()
	var es_copa := not par.is_empty()
	## SI NO HAY COPA, ¿HAY CONTINENTAL? Hasta esta tanda `_dirigir()` nunca
	## miraba esto: `partido_continental()` no existía, así que un partido de
	## Libertadores/Champions/etc. jamás se podía dirigir en vivo -se
	## auto-simulaba solo, sin que el jugador se enterara de que existía esa
	## fecha-. El motor de abajo (`Continental.jugar_ronda(ya_jugado)`) ya
	## sabía recibirlo; solo faltaba esta puerta.
	var conti: Continental = null
	if not es_copa:
		conti = mundo.mi_continental()
		par = mundo.partido_continental()
		if par.is_empty():
			conti = null
	if conti == null and not es_copa:
		par = mundo.proximo_partido()
	if par.is_empty():
		_escribir("[color=#8ea595]Tu club descansa esta jornada.[/color]")
		return
	## La eliminatoria -penales, sin revancha- es la copa siempre, y el
	## continental solo cuando ya salió de la fase de grupos.
	var es_eliminatoria := es_copa or (conti != null and not conti.en_fase_de_grupos())
	if es_copa:
		_escribir("[color=#c9a227]%s — %s.[/color]" % [mundo.copa.nombre, mundo.copa.nombre_de_ronda()])
	elif conti != null:
		_escribir("[color=#c9a227]%s — %s.[/color]" % [Continental.nombre_conti(conti.clave), conti.nombre_de_ronda()])
	var p := Partido.new(par[0], par[1])
	## EL TIEMPO DE LA CIUDAD (plan maestro C1): el mismo que se juega y el
	## mismo cielo que se ve. Sale del país del local y la época del año.
	var info_clima := Clima.del_partido(p.local.pais, mundo.semana, mundo.anio, p.local.id + p.visita.id)
	p.fijar_clima(info_clima)
	_escribir("[color=#8ea595]%s Parte del tiempo: %s.[/color]" % [Clima.icono(info_clima), String(info_clima["texto"])])
	var consejo := Clima.consejo(info_clima, p.local == mundo.mi_club())
	if consejo != "":
		MentorVoz.decir(self, mundo, "%s %s" % [Clima.icono(info_clima), String(info_clima["texto"])], consejo)
	## El nodo «Bloque» del arbol hace que lo que dices desde el banquillo pegue
	## un 50% mas. En este motor eso es la arenga.
	if mundo.entrenamiento != null:
		p._factor_arenga = mundo.entrenamiento.factor_instrucciones()
	## CÓMO SE MIRA (25-9-2026, plan maestro B2). Los cinco modos juegan el
	## MISMO `Partido` con los mismos `simular_minuto()`: solo cambia la vista.
	var modo := _modo_simulacion(_competicion_de_la_semana())
	if modo == "instantaneo" or modo == "resumen":
		p.preparar()
		p.fijar_hinchada(mundo.mi_club(), mundo.prensa.animo if mundo.prensa != null else 60)
		var res := ResumenPartido.mostrar(self, p, mundo.mi_club(), es_eliminatoria, modo == "resumen")
		res.cerrado.connect(func() -> void:
			res.queue_free()
			_cerrar_partido_dirigido(p))
		return
	var vivo := PartidoVivo.new()
	vivo.con_3d = modo != "vivo"
	vivo.destacados = modo == "destacados"
	vivo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(vivo)
	## El perfil del ESTADIO LOCAL -que puede ser el tuyo o el del rival, según
	## quién juegue en casa-, no siempre "el tuyo": `perfil_estadio_de()` ya
	## decide sola cuándo corresponde tu diseño y cuándo el genérico por hash.
	## El BALÓN sí es siempre el tuyo -`Comercial` es tu departamento comercial,
	## el rival no tiene uno propio en este juego-.
	## Lo de la PANTALLA GIGANTE va antes de `abrir()`: `PartidoVivo` abre el
	## visor 3D de entrada, así que asignarlo después llegaría tarde.
	vivo.datos_pantalla = _datos_pantalla_estadio(p.local, "copa" if es_copa else ("conti" if conti != null else "liga"))
	vivo.abrir(p, mundo.mi_club(), mundo.vestuario, es_eliminatoria, mundo.roles,
		_velocidad_partido, _perfil_con_clima(p),
		Comercial.color_balon(mundo.comercial.balon, mundo.mi_club()))
	vivo.cerrado.connect(func() -> void:
		vivo.queue_free()
		_cerrar_partido_dirigido(p))

## El estadio del local, con el cielo del día (no el que se eligió en el
## diseñador: el clima lo pone la ciudad).
func _perfil_con_clima(p: Partido) -> Dictionary:
	var perfil := mundo.perfil_estadio_de(p.local).duplicate()
	if not p.clima_info.is_empty():
		perfil["clima"] = String(p.clima_info["clave"])
	return perfil

## Se avanza la semana con el partido ya jugado en la mano. Si se avanzara sin
## él, la jornada se volvería a simular por dentro y en la tabla aparecería un
## marcador distinto del que se acaba de ver. Lo usan todos los modos.
func _cerrar_partido_dirigido(p: Partido) -> void:
	## A PIE DE CAMPO (B5): antes de volver al despacho, una pregunta con el
	## partido todavía caliente. No en "instantáneo": quien lo eligió quiere el
	## resultado y nada más.
	if mundo.prensa != null and _modo_simulacion(_competicion_de_la_semana()) != "instantaneo":
		var mio := mundo.mi_club()
		var local := p.local == mio
		var gf := p.goles_local if local else p.goles_visita
		var gc := p.goles_visita if local else p.goles_local
		var pie := PieDeCampo.mostrar(self, mundo.prensa, gf > gc, gf == gc, gf, gc)
		pie.cerrado.connect(func() -> void: _seguir_tras_partido(p))
		return
	_seguir_tras_partido(p)

func _seguir_tras_partido(p: Partido) -> void:
	mundo.avanzar_semana(p)
	_escribir("[color=#3fa06a]J%d  %s %d-%d %s[/color]" % [
		mundo.liga_de(mundo.mi_club()).jornada_actual,
		p.local.nombre, p.goles_local, p.goles_visita, p.visita.nombre])
	_refrescar()

## LOS CINCO MODOS DE MIRAR UN PARTIDO (plan maestro B2): [clave, rótulo, qué es].
const MODOS_SIMULACION := [
	["instantaneo", "⚡ Instantáneo", "Solo el resultado, al momento."],
	["resumen", "📋 Resumen", "Las jugadas clave, una a una, en 20 segundos."],
	["vivo", "📻 En vivo", "Crónica, cambios, arengas y charla, sin 3D."],
	["destacados", "🎬 3D destacados", "El estadio a x4, frena en cada ocasión."],
	["completo", "🏟 3D completo", "El partido entero en el estadio."],
]
const SECCION_SIMULACION := "simulacion"

## La competición del partido de esta semana, con el mismo orden que
## `_dirigir()`: copa, después continental, después liga.
func _competicion_de_la_semana() -> String:
	if not mundo.partido_de_copa().is_empty():
		return "copa"
	if mundo.mi_continental() != null and not mundo.partido_continental().is_empty():
		return "conti"
	return "liga"

## El modo elegido para una competición (se guarda por separado: la copa en 3D
## y la liga en resumen, por ejemplo). Por defecto, 3D completo, que es lo que
## hacía "Dirigir" hasta hoy.
func _modo_simulacion(comp: String) -> String:
	var cfg := ConfigFile.new()
	if cfg.load(CajonAjustes.RUTA) != OK:
		return "completo"
	return String(cfg.get_value(SECCION_SIMULACION, comp, "completo"))

func _fijar_modo_simulacion(comp: String, modo: String) -> void:
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(SECCION_SIMULACION, comp, modo)
	cfg.save(CajonAjustes.RUTA)

## El selector, encima del botón de jugar: cinco fichas y la explicación de la
## elegida. Cambiarla la guarda para esa competición.
func _selector_modo_partido(padre: Node) -> void:
	var comp := _competicion_de_la_semana()
	var nombre_comp: String = {"copa": "la copa", "conti": "el torneo continental", "liga": "la liga"}[comp]
	var t := _texto(11, COL_SUAVE)
	t.text = "CÓMO QUIERES VER LOS PARTIDOS DE %s" % nombre_comp.to_upper()
	padre.add_child(t)
	var fila := HFlowContainer.new()
	fila.add_theme_constant_override("h_separation", 6)
	fila.add_theme_constant_override("v_separation", 6)
	padre.add_child(fila)
	var actual := _modo_simulacion(comp)
	var desc := _texto(11, COL_SUAVE)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var grupo := ButtonGroup.new()
	for m: Array in MODOS_SIMULACION:
		var clave := String(m[0])
		var b := Button.new()
		b.text = String(m[1])
		b.toggle_mode = true
		b.button_group = grupo
		b.button_pressed = clave == actual
		b.tooltip_text = String(m[2])
		b.custom_minimum_size = Vector2(0, 30)
		b.pressed.connect(func() -> void:
			_fijar_modo_simulacion(comp, clave)
			desc.text = String(m[2]))
		fila.add_child(b)
		if clave == actual:
			desc.text = String(m[2])
	padre.add_child(desc)

## Para no repetir el aviso del cierre de mercado cada vez que se repinta.
var _mercado_avisado: int = -1

func _avanzar_semana() -> void:
	if not mundo.temporada_en_curso():
		_escribir("[color=#e05555]La temporada está terminada. Pulsa «Temporada siguiente».[/color]")
		return
	var mio := mundo.mi_club()
	var liga := _liga_de(mio)
	var caja_antes := mio.saldo
	## EL CIERRE DEL MERCADO TIENE QUE NOTARSE. Un mercado que cierra en
	## silencio es un boton que un dia deja de funcionar; avisado con dos
	## semanas, es una fecha limite y cambia como se juega esa quincena.
	if mundo.mercado_abierto() and mundo.semanas_de_mercado() <= 2 and _mercado_avisado != mundo.semana:
		_mercado_avisado = mundo.semana
		var q := mundo.semanas_de_mercado()
		Aviso.mostrar(self, "mercado", "⏳", "El mercado cierra",
			"Queda%s %d semana%s para el cierre. Lo que no fiches ahora, no lo fichas hasta la próxima ventana." % [
				"" if q == 1 else "n", q, "" if q == 1 else "s"], "mercado_cierra")
	## Se escucha esta jornada para contar lo que le pasó a TU club, que es lo
	## único que interesa de las 190 jornadas que se juegan en el mundo.
	var visto := {"txt": ""}
	var oyente := func(_n: int, resultados: Array) -> void:
		for r: Dictionary in resultados:
			if r["local"] == mio or r["visita"] == mio:
				var casa: bool = r["local"] == mio
				var rival: Club = r["visita"] if casa else r["local"]
				var gf: int = r["gl"] if casa else r["gv"]
				var gc: int = r["gv"] if casa else r["gl"]
				var col := "#4caf6d" if gf > gc else ("#e05555" if gf < gc else "#8ea595")
				visto["txt"] = "[color=%s]J%d  %s %d-%d %s[/color]  [color=#8ea595]%s[/color]" % [
					col, liga.jornada_actual, mio.nombre, gf, gc, rival.nombre,
					"en casa" if casa else "fuera"]
	liga.jornada_terminada.connect(oyente)
	mundo.avanzar_semana()
	liga.jornada_terminada.disconnect(oyente)
	if visto["txt"] != "":
		_escribir(visto["txt"])
	if mundo.semana % Finanzas.SEMANAS_DEL_MES == 1 and mundo.semana > 1:
		var delta := mio.saldo - caja_antes
		_escribir("[color=#c9a227]Cierre de mes:[/color] la caja %s %s" % [
			"sube" if delta >= 0 else "baja", _dinero(absi(delta))])
	_autoguardar_si_toca()
	_refrescar()

## El interruptor de Ajustes → Guardado. Silencioso a propósito -uno por
## semana durante toda una carrera sería puro ruido en el registro-, en la
## misma ranura que ya usa el botón "Guardar" de arriba.
func _autoguardar_si_toca() -> void:
	if _autoguardado:
		Partida.guardar(mundo, RANURA)

func _jugar_temporada() -> void:
	if not mundo.temporada_en_curso():
		_escribir("[color=#e05555]La temporada ya está terminada.[/color]")
		return
	var t0 := Time.get_ticks_msec()
	mundo.jugar_temporada()
	var t := _liga_de(mundo.mi_club()).tabla()
	var puesto := 1
	for fila: Dictionary in t:
		if fila["club"] == mundo.mi_club():
			break
		puesto += 1
	_escribir("[color=#3fa06a]Temporada %d completa en %d ms.[/color] Campeón: [b]%s[/b]. Acabas [b]%d.º[/b]." % [
		mundo.anio, Time.get_ticks_msec() - t0, t[0]["club"].nombre, puesto])
	_autoguardar_si_toca()
	_refrescar()

func _nueva_temporada() -> void:
	if mundo.temporada_en_curso():
		_escribir("[color=#e05555]Todavía queda calendario por jugar.[/color]")
		return
	var resumen := mundo.nueva_temporada()
	## `mundo.nueva_temporada()` resortea los continentales por dentro
	## (`_sortear_continentales()`, instancias NUEVAS cada vez): sin esta llamada,
	## el sorteo y el aviso de campeón/ronda de Champions-Libertadores solo
	## funcionaban en la primera temporada de la partida. Ver el comentario de
	## `_conectar_sorteos()`.
	_conectar_sorteos()
	_seleccionado = null
	## El cierre de temporada es el momento más importante del año y tiene que
	## contarse entero: quién ganó, quién sube y quién baja. Sin esto la
	## temporada acababa y no pasaba nada.
	for c: Dictionary in resumen["campeones"]:
		var l: Liga = c["liga"]
		var club: Club = c["club"]
		if l.division() == 1 and l.pais == mundo.mi_club().pais:
			_escribir("[color=#c9a227]CAMPEÓN de %s: [b]%s[/b].[/color]  Premio %s" % [
				l.nombre, club.nombre, _dinero(Mundo.PREMIO_LIGA)])
	if not resumen["suben"].is_empty():
		_escribir("[color=#4caf6d]Ascienden:[/color] %s" % _nombres(resumen["suben"]))
		if (resumen["suben"] as Array).has(mundo.mi_club()):
			Sonido.toca("ascenso")
			Aviso.mostrar(self, "titulo", "⬆️", "¡ASCENSO!",
				"Subes de categoría. Otra liga, otros rivales y otros derechos de televisión.")
	if not resumen["bajan"].is_empty():
		_escribir("[color=#e05555]Descienden:[/color] %s  [color=#8ea595](la televisión les pasa de 300.000 a 58.000)[/color]" % _nombres(resumen["bajan"]))
		if (resumen["bajan"] as Array).has(mundo.mi_club()):
			Sonido.toca("descenso")
			Aviso.mostrar(self, "alerta", "⬇️", "DESCENSO",
				"Bajas de categoría. La televisión pasa de 300.000 a 58.000 y habrá que rehacer el plantel.")
	## El veredicto de la directiva. Es lo unico del cierre que puede acabar con
	## la partida, asi que va lo ultimo y con su propio color.
	var v: Dictionary = resumen.get("directiva", {})
	if not v.is_empty():
		if v["cumplido"]:
			_escribir("[color=#4caf6d]Objetivo CUMPLIDO:[/color] %s. Acabaste %d.º (te pedían %d.º). Confianza %d." % [
				v["objetivo"], v["puesto"], v["meta"], v["confianza"]])
		else:
			_escribir("[color=#e05555]Objetivo FALLADO:[/color] %s. Acabaste %d.º y te pedían %d.º. Confianza %d." % [
				v["objetivo"], v["puesto"], v["meta"], v["confianza"]])
		if v["despedido"]:
			_escribir("[color=#e05555][b]ESTÁS DESPEDIDO.[/b][/color] Elige otro club en la lista de arriba para empezar de nuevo.")
	if resumen.get("trotamundos", false):
		_escribir("[color=#c9a227][b]🧳 Toca hacer las maletas.[/b][/color] Dos temporadas cumplidas: el desafío trotamundos te obliga a cambiar de club. Elige tu próximo destino en la lista de arriba.")
	_escribir("[color=#8ea595]Empieza la %d. Todos cumplen un año, algunos se retiran y sube gente de la cantera.[/color]" % mundo.anio)
	## LOS CONTRATOS QUE VENCEN. Es el aviso más útil de todo el cierre de
	## temporada y el que más fácil se pasa por alto: un contrato que se acaba y
	## no se renueva es un jugador que se pierde gratis. Se avisa aquí, con la
	## pretemporada por delante para hacer algo al respecto.
	var acaban: Array[Jugador] = []
	for j: Jugador in mundo.mi_club().plantilla:
		if j.anios_contrato <= 1:
			acaban.append(j)
	if not acaban.is_empty():
		acaban.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
		var cuerpo_c := "%s%s. Renuévalos en Contratos o los pierdes gratis." % [
			acaban[0].nombre,
			" y %d más" % (acaban.size() - 1) if acaban.size() > 1 else ""]
		Aviso.mostrar(self, "contrato", "📄", "Terminan contrato: %d" % acaban.size(), cuerpo_c, "contrato_vence")
		_escribir("[color=#c9a227][b]📄 Terminan contrato %d jugador(es):[/b][/color] %s." % [
			acaban.size(), _nombres_jugadores(acaban)])
		_anotar("📄 Terminan contrato: %d" % acaban.size(), cuerpo_c)
	_autoguardar_si_toca()
	_refrescar()

func _nombres_jugadores(l: Array[Jugador]) -> String:
	var n: Array[String] = []
	for j in l:
		n.append(j.nombre)
	return ", ".join(n)

func _nombres(clubes: Array) -> String:
	var l: Array[String] = []
	for c: Club in clubes:
		l.append(c.nombre)
	return ", ".join(l)

## Una sola ranura por ahora, con el nombre de tu club. Cuando haya menú de
## partidas se aprovecha `Partida.listar()`, que ya devuelve club, año y fecha.
const RANURA := "partida"

func _guardar() -> void:
	if Partida.guardar(mundo, RANURA):
		_escribir("[color=#4caf6d]Partida guardada.[/color] %s, %d, semana %d." % [
			mundo.mi_club().nombre, mundo.anio, mundo.semana])
	else:
		_escribir("[color=#e05555]No se pudo guardar.[/color]")

func _cargar() -> void:
	var m := Partida.cargar(RANURA)
	if m == null:
		_escribir("[color=#c9a227]No hay ninguna partida guardada todavía.[/color]")
		return
	mundo = m
	_conectar_noticias()
	_seleccionado = null
	_llenar_selector()
	_escribir("[color=#3fa06a]Partida cargada:[/color] %s, %d, semana %d." % [
		mundo.mi_club().nombre, mundo.anio, mundo.semana])
	_refrescar()

func _liga_de(c: Club) -> Liga:
	for l in mundo.ligas:
		if l.clubes.has(c):
			return l
	return mundo.ligas[0]

## LO QUE ENSEÑA LA PANTALLA GIGANTE DEL ESTADIO (23-9-2026, pedido repetido:
## "una visualización de los puntos de la competencia... máximos goleadores").
##
## `VistaEstadio` es un VISOR: conoce clubes y partido, no el `Mundo` -y no
## debe conocerlo, igual que no conoce ni la economía ni el mercado-. Así que
## la tabla, los goleadores y los nombres se calculan aquí, que es donde el
## mundo está delante, y se le pasan ya masticados. Mismo patrón exacto que
## `perfil_estadio_de()` y `Comercial.color_balon()`, que ya viajaban así.
##
## `local` es el dueño del recinto: la tabla que se enseña es la de SU liga
## -un partido de copa entre divisiones distintas enseña la del anfitrión-,
## no la del club del usuario.
## `comp` (26-9-2026): "liga", "copa" o "conti". Antes la pantalla enseñaba
## SIEMPRE la liga del local, también en un partido de copa o de la copa
## continental; ahora enseña la competición que se está jugando.
func _datos_pantalla_estadio(local: Club, comp: String = "liga") -> Dictionary:
	var d: Dictionary = {
		"tabla": [], "goleadores": [], "liga": "", "jornada": 0, "recinto": "", "cruces": [],
	}
	if local == null or mundo == null:
		return d
	## El nombre propio del recinto solo vale para TU estadio: `mundo.estadio`
	## es el diseñador de tu club, y llamar a `nombre_de()` con un rival
	## devolvería el nombre que tú le pusiste al tuyo.
	if local.estadio_nombre != "":
		d["recinto"] = local.estadio_nombre
	elif local == mundo.mi_club() and mundo.estadio != null:
		d["recinto"] = mundo.estadio.nombre_de(local)
	else:
		d["recinto"] = "Estadio " + Nombres.visible(local.nombre)
	if comp == "copa" and mundo.copa != null:
		d["liga"] = "%s · %s" % [mundo.copa.nombre, mundo.copa.nombre_de_ronda()]
		for par: Array in mundo.copa.cruces():
			d["cruces"].append([Nombres.visible((par[0] as Club).nombre), Nombres.visible((par[1] as Club).nombre)])
		d["goleadores"] = _goleadores_de(mundo.copa.vivos)
		return d
	var conti := mundo.mi_continental()
	if comp == "conti" and conti != null:
		d["liga"] = "%s · %s" % [Continental.nombre_conti(conti.clave), conti.nombre_de_ronda()]
		if conti.en_fase_de_grupos():
			for gi in conti.grupos.size():
				if (conti.grupos[gi] as Array).has(local) or (conti.grupos[gi] as Array).has(mundo.mi_club()):
					d["titulo_tabla"] = "GRUPO " + conti.nombre_de_grupo(gi).to_upper()
					for f: Dictionary in conti.tabla_de_grupo(gi):
						var cg: Club = f["club"]
						d["tabla"].append({"id": cg.id, "nombre": cg.nombre, "pts": int(f["pts"]), "pj": int(f["pj"]), "dif": int(f["dif"])})
					break
		else:
			for par2: Array in conti.cruces():
				d["cruces"].append([Nombres.visible((par2[0] as Club).nombre), Nombres.visible((par2[1] as Club).nombre)])
		d["goleadores"] = _goleadores_de(conti.vivos)
		return d
	var l: Liga = mundo.liga_de(local)
	if l == null:
		return d
	d["liga"] = l.nombre
	d["jornada"] = l.jornada_actual
	var filas: Array = []
	for f: Dictionary in l.tabla():
		var c: Club = f["club"]
		filas.append({
			"id": c.id, "nombre": c.nombre, "pts": int(f["pts"]),
			"pj": int(f["pj"]), "dif": int(f["dif"]),
		})
	d["tabla"] = filas
	## Los goleadores de ESA liga, no del mundo entero: es la pantalla de ese
	## estadio, no un ranking global. Sin goles todavía (jornada 1) la lista
	## sale vacía y la pantalla simplemente no rota a ese panel.
	d["goleadores"] = _goleadores_de(l.clubes)
	return d

func _goleadores_de(clubes: Array) -> Array:
	var tiradores: Array = []
	for c: Club in clubes:
		for j: Jugador in c.plantilla:
			if j.goles > 0:
				tiradores.append({"nombre": j.nombre, "club": c.nombre, "goles": j.goles})
	tiradores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["goles"]) > int(b["goles"]))
	return tiradores.slice(0, 8)

func _escribir(bbcode: String) -> void:
	_registro.append_text(_bbcode_accesible(bbcode) + "\n")

## Complementa a `_escribir()`, no lo reemplaza: `_escribir()` sigue pintando
## el registro exactamente igual que antes -no se le tocó una línea, cero
## riesgo de que una captura ya verificada cambie de aspecto-, esto solo
## archiva la misma noticia en la bandeja de "Correo" para poder filtrarla y
## marcarla leída más tarde.
func _anotar(titulo: String, cuerpo: String) -> void:
	_bandeja.push_front({"titulo": titulo, "cuerpo": cuerpo, "semana": mundo.semana, "anio": mundo.anio, "leida": false})
	if _bandeja.size() > BANDEJA_MAX:
		_bandeja.resize(BANDEJA_MAX)

# --- pintado ----------------------------------------------------------------

func _refrescar() -> void:
	var c := mundo.mi_club()
	## Tu personaje 3D, a mano para la banda de cualquier estadio (la vista
	## del partido no tiene el mundo delante).
	PersonajeDT.del_usuario = mundo.roles.aspecto_3d()
	PersonajeDT.club_usuario = c.id if c != null else ""
	## Entrenadora: si tu personaje es mujer, toda la interfaz te trata como tal.
	Genero.fijar(String(PersonajeDT.aspecto(PersonajeDT.del_usuario)["cuerpo"]) == "female")
	var liga := _liga_de(c)
	var acento_antes := COL_ACENTO
	COL_ACENTO = _acento_de(c)
	## El acento sale de la identidad del club y tine tambien el tema -pestana
	## activa, boton pulsado, barras-. Al cambiar de club o de colores hay que
	## rehacerlo; comparando primero, para no reconstruir un Theme entero en cada
	## refresco cuando no ha cambiado nada.
	if acento_antes != COL_ACENTO:
		_aplicar_tema()
	_cabecera.text = c.nombre
	_limpiar(_escudo_cabecera)
	var e := _escudo(c, 44)
	e.set_anchors_preset(Control.PRESET_FULL_RECT)
	_escudo_cabecera.add_child(e)
	var dir_txt := ""
	if mundo.directiva != null:
		dir_txt = "  ·  %s  ·  confianza %d" % [mundo.directiva.objetivo, mundo.directiva.confianza]
	## La plata y la fecha ya no van en el texto corrido: viven arriba a la
	## derecha, en grande. Aquí queda lo que de verdad es contexto.
	## La caja CUENTA hasta su nuevo valor (plan maestro B11): un cobro o un
	## pago se ve moverse, y late una vez.
	if _saldo_mostrado != -1 and _saldo_mostrado != c.saldo and _lbl_caja.is_inside_tree():
		Animar.contar(_lbl_caja, float(_saldo_mostrado), float(c.saldo), func(v: float) -> String: return _dinero(int(v)))
		Animar.pulso(_lbl_caja, 1.06)
	else:
		_lbl_caja.text = _dinero(c.saldo)
	_saldo_mostrado = c.saldo
	_lbl_fecha.text = "%s  ·  semana %d" % [fecha_larga(), mundo.semana]
	_sub.text = "%s  ·  Jornada %d de %d  ·  Sueldos %s/sem  ·  Media %.1f%s" % [
		liga.nombre, liga.jornada_actual, liga.jornadas(),
		_dinero(c.masa_salarial()), c.media(), dir_txt]
	## El desafío invicto no bloquea nada por dentro -se puede seguir jugando,
	## como en el HTML-, solo avisa UNA vez de que la racha se acabó.
	if not mundo.fin_partida.is_empty() and not _fin_partida_avisado:
		_fin_partida_avisado = true
		_escribir("[color=#e05555][b]💀 FIN DE LA PARTIDA.[/b][/color] Cayó la primera derrota y con ella el desafío del invicto (semana %d de %d). Puedes seguir jugando, pero el desafío ya está perdido." % [
			int(mundo.fin_partida.get("semana", 0)), int(mundo.fin_partida.get("anio", 0))])
	## LA TABLA, MODULARIZADA (25-9-2026, pedido explícito del usuario: "que no
	## sea tan frágil"). Las cinco funciones que pintaban esto viven ahora en
	## `ui/componentes/tabla_competicion.gd`, como clase estática -no como
	## componente de escena, ver el porqué en su propio comentario de cabecera-.
	## Los colores van YA resueltos (paleta + modo daltónico), la lección del
	## bug de coherencia visual que se encontró y arregló en `PanelMercado`
	## esa misma sesión, aplicada desde el principio esta vez.
	_titulo_tabla.text = TablaCompeticion.titulo_de(mundo, liga, c)
	TablaCompeticion.pintar(_lista_tabla, mundo, liga, c, {
		"suave":  _pal_suave(),
		"texto":  _pal_texto(),
		"acento": COL_ACENTO,
		"verde":  _color_accesible(COL_VERDE),
		"rojo":   _color_accesible(COL_ROJO),
		"oro":    _color_accesible(COL_ORO),
		"escala": _escala_texto,
	})
	_pintar_plantel(c)
	## El panel de mercado se actualiza con la paleta del club activo para que
	## el color de acento refleje siempre al equipo que se dirige.
	##
	## PUNTO 3, COHERENCIA VISUAL (25-9-2026): `verde`/`rojo`/`oro` viajaban
	## SIN pasar por `_color_accesible()` -el remapeo a la paleta Okabe-Ito
	## ("modo daltónico" de Ajustes) que el resto del juego sí respeta desde
	## que se centralizó "en `_texto()` en vez de en las mil llamadas"-. Con el
	## modo activado, la interfaz entera cambiaba de verde/rojo/oro a azul
	## cielo/bermellón/ámbar MENOS la pestaña Mercado -"mercado abierto",
	## "ganas de venir", si el fichaje es pagable, seguían en los colores
	## viejos-, justo la clase de incoherencia entre un componente nuevo y el
	## resto de la interfaz que el pedido de mejora señalaba.
	if _panel_mercado != null:
		_panel_mercado.inicializar(mundo, {
			"acento": COL_ACENTO,
			"texto":  _pal_texto(),
			"suave":  _pal_suave(),
			"verde":  _color_accesible(COL_VERDE),
			"rojo":   _color_accesible(COL_ROJO),
			"oro":    _color_accesible(COL_ORO),
		}, _negociacion_ultimo)
	_pintar_copa(c)
	_pintar_club(c)
	_pintar_conti(c)
	_pintar_medico(c)
	_pintar_logros()
	_pintar_entrenamiento(c)
	_pintar_federacion(c)
	_pintar_estadio(c)
	_pintar_seleccion(c)
	_pintar_cantera(c)
	_pintar_contratos(c)
	_pintar_comparar()
	_pintar_records()
	_filtrar_records()
	_pintar_legado()
	_pintar_inicio(c)
	## Las otras tres viven DENTRO de `_pintar_gente()` ahora -un chip por
	## sección, solo se pinta la que está activa- en vez de apilarse las
	## cuatro siempre, aunque solo una se vea.
	_pintar_gente()
	_pintar_finanzas(c)
	_pintar_camarin(c)
	_pintar_ciudad(c)
	_pintar_editor()
	_pintar_glosario()
	_pintar_ajustes()
	_pintar_correo()
	_pintar_redes()
	_filtrar_redes()
	_pintar_vida()
	_pintar_habilidades()
	_pintar_libres(c)
	_pintar_premios()
	_pintar_clubes()
	_pintar_desafios()
	_pintar_tactica(c)
	_pintar_partido(c)
	_pintar_calendario(c)
	_pintar_dias()
	_actualizar_badges()
	_pintar_despacho()
	_ver_ficha(_seleccionado if _seleccionado != null else _jugador_de_la_semana(c))
	## LO ÚLTIMO DE TODO: traducir. Ver `nucleo/idiomas.gd` -la interfaz se pinta
	## siempre en castellano y se traduce al final, para no tener que marcar dos
	## mil cadenas con `tr()` en un archivo de diez mil líneas-.
	_traducir_pantalla(self)
	## Y la música, que también depende de lo que esté pasando.
	Musica.ambientar(_situacion_musical())

## A quién enseña la ficha cuando no has elegido a nadie.
##
## Antes se quedaba vacía o clavada en el mismo jugador semana tras semana, y un
## plantel de veinticuatro se convertía en uno. Rotar por rotar tampoco sirve:
## lo que se enseña es a quien tiene ALGO que contar esta semana, y solo si no
## hay nadie así se pasa el turno por la plantilla.
func _jugador_de_la_semana(c: Club) -> Jugador:
	if c.plantilla.is_empty():
		return null
	## 1 · El que está roto: es lo primero que uno querría saber al abrir.
	for j in c.plantilla:
		if j.lesion > 0:
			return j
	## 2 · El que está en racha: mejor nota media de las tres últimas, y solo si
	## de verdad ha jugado.
	var mejor: Jugador = null
	var mejor_nota := 6.8
	for j in c.plantilla:
		if j.notas.size() < 3:
			continue
		var ultimas := j.notas.slice(maxi(0, j.notas.size() - 3))
		var s := 0.0
		for x in ultimas:
			s += float(x)
		var media := s / float(ultimas.size())
		if media > mejor_nota:
			mejor_nota = media
			mejor = j
	if mejor != null:
		return mejor
	## 3 · Y si no hay noticia, el turno rota con la semana: cada una le toca a
	## uno distinto, y en un año pasan todos por la ficha.
	return c.plantilla[(mundo.semana + mundo.anio) % c.plantilla.size()]

## La columna de la izquierda SIGUE A LA COMPETICIÓN DEL PRÓXIMO PARTIDO.
##
## Antes enseñaba siempre la tabla de liga, y eso hacía que la semana de
## Libertadores se sintiera igual que la semana catorce de campeonato. Si el
## domingo juegas la copa, lo que quieres ver es el cuadro; si es fase de
## grupos, tu grupo; y solo si toca liga, la tabla. Cambiar de torneo tiene que
## NOTARSE sin leer un texto que lo diga.
## LOS SORTEOS. Solo se enseña la cinemática de los torneos donde JUEGA tu club:
## el bombo de un continental que no te toca sería una espera sin premio.
##
## Y se encolan. Al empezar temporada se sortean varios continentales a la vez, y
## sin cola la segunda cinemática pisaría a la primera -o peor, se abrirían dos
## superpuestas y el juego se quedaría con dos capas modales encima.
var _cola_sorteos: Array = []
var _sorteo_abierto: bool = false

## Conecta la cinemática de sorteo (todos los continentales: es un espectáculo,
## no un peaje) y el resultado de TU club en el suyo (ver
## `_conectar_mi_continental()`). Hay que volver a llamarla tras CADA
## resorteo -al tomar el mando y en cada cierre de temporada, ver
## `_nueva_temporada()`-, porque `Continental.sortear()` siempre crea
## instancias NUEVAS: conectar solo la primera vez dejaba sin sorteo visible y
## sin aviso de resultado la Champions/Libertadores desde la segunda temporada
## en adelante. El candado por objeto es necesario además porque `mundo.copa`
## SÍ persiste entre cambios de club -mismo bug ya cazado hoy en
## `federacion.noticia`-: sin él, cada despido/trotamundos/oferta aceptada
## sumaba OTRA conexión sobre el mismo `copa`, y una sola eliminatoria abría la
## MISMA cinemática de sorteo una vez por cada cambio de club de la partida.
func _conectar_sorteos() -> void:
	for k: String in mundo.continentales:
		var t: Continental = mundo.continentales[k]
		if t.has_meta("_ui_conectado_sorteo"):
			continue
		t.set_meta("_ui_conectado_sorteo", true)
		var clave := k
		t.sorteo_grupos.connect(func(grupos: Array) -> void:
			_encolar_sorteo({"tipo": "grupos", "clave": clave, "grupos": grupos}))
		t.sorteo_eliminatoria.connect(func(ronda: String, parejas: Array) -> void:
			_encolar_sorteo({"tipo": "cruces", "clave": clave, "ronda": ronda, "parejas": parejas}))
	if mundo.copa != null and not mundo.copa.has_meta("_ui_conectado_sorteo"):
		mundo.copa.set_meta("_ui_conectado_sorteo", true)
		mundo.copa.sorteo_eliminatoria.connect(func(ronda: String, parejas: Array) -> void:
			_encolar_sorteo({"tipo": "cruces", "clave": "copa", "ronda": ronda, "parejas": parejas}))
	_conectar_mi_continental()

## El resultado de TU club en SU torneo continental -mismo trato que ya tiene
## `copa` en `_conectar_noticias()`, portado aquí el 14-9-2026-: campeón, ronda
## superada y el premio de pasar de la fase de grupos. `Continental extends
## Copa` hereda las tres señales de siempre; hasta hoy ninguna estaba
## conectada -ganar el trofeo más grande del juego no avisaba de nada-.
func _conectar_mi_continental() -> void:
	var c := mundo.mi_continental()
	if c == null or c.has_meta("_ui_conectado"):
		return
	c.set_meta("_ui_conectado", true)
	c.campeon_proclamado.connect(func(campeon: Club) -> void:
		if campeon == mundo.mi_club():
			Aviso.mostrar(self, "dinero", "🏆", "Campeón de %s" % c.nombre,
				"El trofeo continental es tuyo. Entra el premio de campeón a la caja."))
	c.ronda_terminada.connect(func(nombre_ronda: String, resultados: Array) -> void:
		for r: Dictionary in resultados:
			if r.get("pasa") == mundo.mi_club():
				Aviso.mostrar(self, "dinero", "🎟️", "Pasas de ronda en %s" % c.nombre,
					"%s superada. Cada eliminatoria continental que se gana es premio." % nombre_ronda, "ronda_superada")
				return)
	c.grupos_terminados.connect(func(clasificados: Array) -> void:
		if clasificados.has(mundo.mi_club()):
			Aviso.mostrar(self, "dinero", "🎟️", "Clasificas a cuartos de %s" % c.nombre,
				"Terminas entre los ocho de la fase de grupos: cobras el premio de clasificación.", "ronda_superada"))

func _encolar_sorteo(d: Dictionary) -> void:
	if not _sorteo_me_toca(d):
		return
	_cola_sorteos.append(d)
	_siguiente_sorteo()

## Solo si tu club está dentro. Es la diferencia entre una ceremonia y un peaje.
func _sorteo_me_toca(d: Dictionary) -> bool:
	var mio := mundo.mi_club()
	if mio == null:
		return false
	if String(d["tipo"]) == "grupos":
		for g: Array in d["grupos"]:
			if g.has(mio):
				return true
		return false
	for par: Array in d["parejas"]:
		if par[0] == mio or par[1] == mio:
			return true
	return false

func _siguiente_sorteo() -> void:
	if _sorteo_abierto or _cola_sorteos.is_empty():
		return
	_sorteo_abierto = true
	var d: Dictionary = _cola_sorteos.pop_front()
	var v := Sorteo.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(v)
	v.terminado.connect(func() -> void:
		v.queue_free()
		_sorteo_abierto = false
		_refrescar()
		_siguiente_sorteo())
	if String(d["tipo"]) == "grupos":
		v.abrir_grupos(String(d["clave"]), d["grupos"], mundo.mi_club())
	else:
		v.abrir_eliminatoria(String(d["clave"]), String(d["ronda"]), d["parejas"], mundo.mi_club())

## La ficha completa de la competición, encima de todo. Sale de `principal.gd`
## para no engordar más este archivo, que ya pasa de las cinco mil líneas.
func _abrir_competicion() -> void:
	var v := Competicion.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(v)
	v.abrir(mundo, _liga_de(mundo.mi_club()))
	v.cerrado.connect(func() -> void:
		v.queue_free()
		_refrescar())


## Por qué columna se ordena el plantel y en qué sentido. `vJugadores()` del
## HTML deja ordenar por seis columnas; aquí se guarda entre repintados para que
## avanzar una semana no te devuelva al orden por media.
var _orden_plantel: String = "ovr"
var _orden_plantel_desc: bool = true

func _pintar_plantel(c: Club) -> void:
	PanelPlantel.pintar(_lista_plantel, c, mundo, _orden_plantel, _orden_plantel_desc, COL_ACENTO,
		func(color: Color) -> Color: return _color_de_paleta(color),
		func(g: GridContainer, j: Jugador, columnas: Array, colores: Array) -> void:
			_fila_jugador(g, j, columnas, colores),
		func(clave: String) -> void:
			## Nombre y posición se leen de la A a la Z; los números, de mayor a
			## menor. Es lo que uno espera sin pensarlo.
			if _orden_plantel == clave:
				_orden_plantel_desc = not _orden_plantel_desc
			else:
				_orden_plantel = clave
				_orden_plantel_desc = clave not in ["nombre", "pos"]
			_refrescar())


## `vLibres()`/`nuevoLibre()`/`ficharLibre()` del HTML: futbolistas sin club,
## sin traspaso -solo prima de fichaje y sueldo-. A diferencia del comparador
## y de la lista de objetivos del mercado, el HTML enseña aquí la media Y la
## proyección sin tapar nada -son jugadores disponibles de verdad, no un rival
## que hay que ojear-, así que la fila los muestra directos también.
func _pintar_libres(c: Club) -> void:
	_limpiar(_lista_libres)
	if mundo.libres.is_empty():
		mundo.generar_libres()
	var t := _texto(11, COL_SUAVE)
	t.text = "MERCADO DE AGENTES LIBRES  ·  sin traspaso, solo prima de fichaje y sueldo"
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_libres.add_child(t)

	var filtros := HBoxContainer.new()
	filtros.add_theme_constant_override("separation", 6)
	_lista_libres.add_child(filtros)
	var b_todos := Button.new()
	b_todos.text = "Todos"
	b_todos.toggle_mode = true
	b_todos.button_pressed = _libres_filtro == "todos"
	b_todos.pressed.connect(func() -> void: _libres_filtro = "todos"; _pintar_libres(c))
	filtros.add_child(b_todos)
	for dem: String in Datos.posd().keys():
		var bd := Button.new()
		bd.text = dem
		bd.toggle_mode = true
		bd.button_pressed = _libres_filtro == dem
		bd.pressed.connect(func() -> void: _libres_filtro = dem; _pintar_libres(c))
		filtros.add_child(bd)
	_lista_libres.add_child(HSeparator.new())

	if mundo.roles != null and not mundo.roles.puede_fichar():
		var av := _texto(12, COL_SUAVE)
		av.text = String(mundo.roles.motivo_bloqueo("fichar"))
		av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_libres.add_child(av)
		_lista_libres.add_child(HSeparator.new())

	var lista := mundo.libres.filter(func(j: Jugador) -> bool:
		return _libres_filtro == "todos" or j.pos_e == _libres_filtro)
	if lista.is_empty():
		var nada := _texto(12, COL_SUAVE)
		nada.text = "No hay agentes libres de ese puesto ahora mismo."
		_lista_libres.add_child(nada)
		return
	for j: Jugador in lista:
		var motivo_bloqueo := _motivo_fichaje_bloqueado(j)
		var factor_agente := 1.0
		if mundo.prensa != null:
			factor_agente = float(mundo.prensa.agente_de(j).get("f", 1.0))
		var prima := int(round(float(j.sueldo) * 6.0 * factor_agente))
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		_lista_libres.add_child(fila)
		var retrato := TextureRect.new()
		retrato.texture = Cara.textura(j, "#2b6b45", "#ffffff", 30)
		retrato.custom_minimum_size = Vector2(30, 30)
		retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fila.add_child(retrato)
		var b_nom := Button.new()
		b_nom.text = "%s  (%s)" % [j.nombre, j.pos_e]
		b_nom.flat = true
		b_nom.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b_nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b_nom.pressed.connect(func() -> void: _ver_ficha(j))
		fila.add_child(b_nom)
		var med := _texto(14, COL_TEXTO)
		med.text = "%d / %d" % [j.ovr, j.pot]
		fila.add_child(med)
		var boton := Button.new()
		boton.text = "Ofrecer contrato"
		boton.disabled = motivo_bloqueo != "" or prima > c.saldo
		boton.pressed.connect(func() -> void: _fichar_libre(j))
		fila.add_child(boton)
		var det := _texto(11, COL_SUAVE)
		det.text = "%d años · %s · pide %s/sem · prima %s%s" % [
			j.edad, j.pais, _dinero(j.sueldo), _dinero(prima),
			"  ·  ya dijo que no una vez" if j.rechazos_libre > 0 else ""]
		_lista_libres.add_child(det)
		if j.motivo_libre != "":
			var mot := _texto(11, COL_SUAVE)
			mot.text = j.motivo_libre + "."
			mot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_lista_libres.add_child(mot)
		_lista_libres.add_child(HSeparator.new())

## `vTactica()` del HTML: el pizarrón FUERA del partido. Hasta hoy la táctica
## solo se podía tocar EN VIVO, con el reloj corriendo, y el once lo armaba
## siempre el automático: `Club.fijar_once()` existía y no la llamaba ninguna
## pantalla, así que la decisión más básica de un manager -a quién saco- no se
## podía tomar antes de jugar. Y `once_elegido` ni siquiera se guardaba.
## El bloque de roles de `vTacticaAvanzada()`: qué papel le pides a cada titular
## dentro del dibujo. El sistema entero -tabla `ROLES`, aptitud por atributos,
## bonificador agregado y guardado- estaba escrito en `Vestuario` desde hace
## tanto que casi lo doy por muerto: `bonus_roles()` no aparecía en ningún grep
## fuera de su propio archivo. Y sin embargo VIVE, porque `factores()` lo llama
## ahí dentro y `Mundo.aplicar_bonificadores()` lleva el resultado al club. Lo
## único que faltaba era esto: la pantalla para elegirlos.
##
## La aptitud es lo que hace que la decisión importe. No se mide contra el resto
## del plantel sino contra la propia media del jugador: un central de 80 con 90
## de marca es un gran central marcador y un mal central de salida, y el mismo
## número te dice las dos cosas.
## EL PIZARRÓN, de `vTactica()`. La lista de once nombres dice QUIÉN juega; el
## pizarrón dice CÓMO están puestos, que es una información distinta y la que de
## verdad se mira al montar un equipo.
##
## Las coordenadas no se inventan: la tabla `FORMS` que exportó el HTML trae la
## posición de cada ranura en porcentaje del campo (`[puesto, x, y]`), así que
## el dibujo sale de los mismos datos que usa el motor para armar el once. Si un
## día cambia una formación, el pizarrón cambia con ella sin tocar nada aquí.
func _pintar_pizarron(c: Club) -> void:
	## La pizarra con fichas de jugador (cara, anillo, puesto, apellido): ver
	## `ui/componentes/pizarra_tactica.gd`.
	PizarraTactica.pintar(_lista_tactica, c, _ver_ficha)

	if not _modo_experto:
		var ex := _texto(10, COL_SUAVE)
		ex.text = "En rojo, el que juega fuera de su puesto: rinde por debajo aunque su media diga otra cosa."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_tactica.add_child(ex)
	_lista_tactica.add_child(HSeparator.new())

## LAS JUGADAS ENSAYADAS Y LOS PLANES, de `vTacticaAvanzada()`.
##
## Lo que hace que elegir importe es la EFECTIVIDAD: cada jugada pide unas
## habilidades concretas y el número dice si tienes a la gente para ella. Poner
## "todos al área" sin un cabeceador es tirar los córners a la nada, y aquí se
## ve antes de hacerlo.
func _pintar_balon_parado(c: Club) -> void:
	var once := c.once()
	var t := _texto(11, COL_SUAVE)
	t.text = "BALÓN PARADO"
	_lista_tactica.add_child(t)
	if not _modo_experto:
		var ex := _texto(10, COL_SUAVE)
		ex.text = "El número es cuánto le va esa jugada a ESTE once: depende de si tienes gente con las habilidades que pide."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_tactica.add_child(ex)

	for bloque in [["Córners", Tactica.CORNERS, c.tactica.corner, "corner"],
			["Tiros libres", Tactica.LIBRES, c.tactica.libre, "libre"]]:
		var tb := _texto(11, COL_ACENTO)
		tb.text = String(bloque[0]).to_upper()
		_lista_tactica.add_child(tb)
		var lista: Array = bloque[1]
		var actual := String(bloque[2])
		var prop := String(bloque[3])
		for f: Array in lista:
			var clave := String(f[0])
			var ef := Tactica.efectividad(once, f[3], mundo.entrenamiento)
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 6)
			_lista_tactica.add_child(fila)
			var b := Button.new()
			b.text = String(f[1])
			b.toggle_mode = true
			b.button_pressed = clave == actual
			b.add_theme_font_size_override("font_size", 11)
			b.clip_text = true
			b.custom_minimum_size = Vector2(160, 0)
			b.tooltip_text = String(f[2])
			b.pressed.connect(func() -> void:
				c.tactica.set(prop, clave)
				_refrescar())
			fila.add_child(b)
			var e := _texto(11, COL_VERDE if ef >= 1.1 else (COL_ROJO if ef < 0.95 else COL_SUAVE))
			e.text = "×%.2f" % ef
			e.custom_minimum_size = Vector2(44, 0)
			fila.add_child(e)
			var d := _texto(10, COL_SUAVE)
			d.text = String(f[2])
			d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			d.clip_text = true
			fila.add_child(d)

	## LOS PLANES. Se aplican solos en el minuto 60 según cómo vaya el marcador.
	## En el 60 y no antes: cambiar el plan en el 20 no es un plan, es
	## nerviosismo.
	var tp := _texto(11, COL_ACENTO)
	tp.text = "PLANES SEGÚN EL MARCADOR"
	_lista_tactica.add_child(tp)
	if not _modo_experto:
		var ep := _texto(10, COL_SUAVE)
		ep.text = "Se aplican solos en el minuto 60, sin que tengas que estar mirando."
		ep.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_tactica.add_child(ep)
	for par in [["Si voy perdiendo", "plan_perdiendo"], ["Si voy ganando", "plan_ganando"]]:
		var prop2 := String(par[1])
		var fila2 := HBoxContainer.new()
		fila2.add_theme_constant_override("separation", 6)
		_lista_tactica.add_child(fila2)
		var et := _texto(12, COL_SUAVE)
		et.text = String(par[0])
		et.custom_minimum_size = Vector2(120, 0)
		fila2.add_child(et)
		for f2: Array in Tactica.PLANES:
			var clave2 := String(f2[0])
			var b2 := Button.new()
			b2.text = String(f2[1])
			b2.toggle_mode = true
			b2.button_pressed = String(c.tactica.get(prop2)) == clave2
			b2.add_theme_font_size_override("font_size", 11)
			b2.clip_text = true
			b2.tooltip_text = String(f2[2])
			b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b2.pressed.connect(func() -> void:
				c.tactica.set(prop2, clave2)
				_refrescar())
			fila2.add_child(b2)
	_lista_tactica.add_child(HSeparator.new())

func _pintar_roles_tacticos(c: Club) -> void:
	var v := mundo.vestuario
	if v == null:
		return
	var once: Array = c.once()
	if once.is_empty():
		return
	var t := _texto(11, COL_SUAVE)
	t.text = "ROLES DEL ONCE"
	_lista_tactica.add_child(t)
	var tabla := v.tabla_roles_tacticos()
	for j: Jugador in once:
		var actual := v.rol_tactico(j)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_lista_tactica.add_child(fila)
		fila.add_child(_retrato(j, 22))
		var nom := _texto(12, COL_TEXTO)
		nom.text = "%s  %s" % [j.pos_e, j.nombre]
		nom.custom_minimum_size = Vector2(150, 0)
		fila.add_child(nom)
		## Solo los roles de SU línea: ofrecer "pivote" a un portero no es una
		## opción, es ruido que alarga el desplegable a dieciséis entradas.
		var op := OptionButton.new()
		op.add_theme_font_size_override("font_size", 11)
		op.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var claves: Array = v.roles_de_grupo(Datos.grupo(j.pos_e))
		claves.sort()
		var elegido := 0
		for n in claves.size():
			var clave := String(claves[n])
			op.add_item(String((tabla[clave] as Array)[0]), n)
			if clave == actual:
				elegido = n
		op.selected = elegido
		var jug := j
		var lista := claves
		op.item_selected.connect(func(idx: int) -> void:
			v.fijar_rol_tactico(jug, String(lista[idx]))
			_refrescar())
		fila.add_child(op)
		## El número que justifica todo el bloque: por debajo de 1,00 le estás
		## pidiendo algo que no sabe hacer.
		var apt := v.aptitud_rol(j, actual)
		var ap := _texto(12, COL_VERDE if apt >= 1.02 else (COL_ROJO if apt < 0.95 else COL_SUAVE))
		ap.text = "%.2f" % apt
		ap.custom_minimum_size = Vector2(38, 0)
		fila.add_child(ap)

	## El efecto agregado, que es lo que de verdad llega al partido. Un once
	## entero de llegadores suma mucho ataque y regala la espalda: sin este
	## resumen, esa consecuencia no se ve en ninguna parte.
	var b: Dictionary = v.bonus_roles(once)
	var res := _texto(11, COL_SUAVE)
	res.text = "Efecto sobre el equipo:  ataque ×%.3f   ·   defensa ×%.3f" % [float(b["att"]), float(b["def"])]
	_lista_tactica.add_child(res)
	_lista_tactica.add_child(HSeparator.new())

## LA MODA TÁCTICA Y LO QUE TE FUNCIONA A TI.
##
## Arriba, qué se lleva este año y qué pasó de moda: sin esto, el mejor dibujo
## del juego lo sería para siempre. Abajo, la tabla que contesta la única
## pregunta que de verdad importa —«¿me funciona a mí el 4-3-3?»—, que no la
## puede contestar ninguna otra pantalla porque depende de TU plantilla.
func _pintar_moda_tactica(c: Club) -> void:
	_lista_tactica.add_child(HSeparator.new())
	var e := mundo.era_actual()
	var t := _texto(11, COL_SUAVE)
	t.text = "📈 %s" % String(e[1]).to_upper()
	_lista_tactica.add_child(t)
	var d := _texto(11, COL_SUAVE)
	d.text = String(e[4])
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_tactica.add_child(d)
	_dato("Se lleva", ", ".join(e[2]), COL_VERDE, _lista_tactica)
	_dato("Pasó de moda", ", ".join(e[3]), COL_ROJO, _lista_tactica)
	var mio_f := c.tactica.formacion if c.tactica != null else ""
	var f := mundo.factor_moda(mio_f)
	_dato("Tu dibujo (%s)" % mio_f,
		"de moda: +5%" if f > 1.0 else ("pasado de moda: −5%" if f < 1.0 else "ni una cosa ni otra"),
		COL_VERDE if f > 1.0 else (COL_ROJO if f < 1.0 else COL_SUAVE), _lista_tactica)

	var rank := mundo.ranking_tactico()
	if rank.is_empty():
		return
	_lista_tactica.add_child(HSeparator.new())
	var tr := _texto(11, COL_SUAVE)
	tr.text = "📊 LO QUE TE HA FUNCIONADO"
	_lista_tactica.add_child(tr)
	var g := GridContainer.new()
	g.columns = 5
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista_tactica.add_child(g)
	for cab: String in ["Dibujo", "PJ", "G-E-P", "Goles", "Pts/partido"]:
		_celda(g, cab, COL_SUAVE, cab != "Dibujo" and cab != "G-E-P")
	for fila: Dictionary in rank:
		var es_mio := String(fila["formacion"]) == mio_f
		_celda(g, "%s%s" % ["▸ " if es_mio else "", String(fila["formacion"])],
			COL_ORO if es_mio else COL_TEXTO, false)
		_celda(g, str(int(fila["pj"])), COL_SUAVE, true)
		_celda(g, "%d-%d-%d" % [int(fila["pg"]), int(fila["pe"]), int(fila["pp"])], COL_SUAVE, false)
		_celda(g, "%d:%d" % [int(fila["gf"]), int(fila["gc"])], COL_SUAVE, true)
		_celda(g, "%.2f" % float(fila["ppp"]),
			COL_VERDE if float(fila["ppp"]) >= 1.7 else (COL_ROJO if float(fila["ppp"]) < 1.0 else COL_TEXTO), true)
	if not _modo_experto:
		var ex := _texto(10, COL_SUAVE)
		ex.text = "Puntos por partido con cada dibujo, desde que llevas el club. No dice cuál es el mejor del juego: dice cuál le sienta bien a ESTA plantilla."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_tactica.add_child(ex)

func _pintar_tactica(c: Club) -> void:
	_limpiar(_lista_tactica)
	## El pizarrón va PRIMERO: es lo que se viene a mirar aquí. Las perillas y los
	## interruptores se tocan una vez cada varias semanas; el once se mira cada
	## domingo.
	_pintar_pizarron(c)
	var t := _texto(11, COL_SUAVE)
	t.text = "FORMACIÓN"
	_lista_tactica.add_child(t)
	var forms: Dictionary = Datos.tabla("FORMS")
	var fila_f: HBoxContainer = null
	var i_f := 0
	for nombre_f: String in forms.keys():
		if i_f % 5 == 0:
			fila_f = HBoxContainer.new()
			fila_f.add_theme_constant_override("separation", 4)
			_lista_tactica.add_child(fila_f)
		var bf := Button.new()
		bf.text = nombre_f
		bf.toggle_mode = true
		bf.button_pressed = c.tactica.formacion == nombre_f
		bf.add_theme_font_size_override("font_size", 11)
		bf.pressed.connect(func() -> void:
			c.tactica.formacion = nombre_f
			## Cambiar de dibujo invalida el once elegido: las ranuras son otras.
			c.limpiar_once()
			_refrescar())
		fila_f.add_child(bf)
		i_f += 1
	_lista_tactica.add_child(HSeparator.new())

	## Las seis perillas, con los mismos tres niveles que usa el partido en vivo.
	var perillas := [
		["Mentalidad", "mentalidad", ["Defensiva", "Equilibrada", "Ofensiva"]],
		["Presión", "presion", ["Baja", "Media", "Alta"]],
		["Ritmo", "ritmo", ["Lento", "Medio", "Alto"]],
		["Línea", "linea", ["Baja", "Media", "Adelantada"]],
		["Amplitud", "amplitud", ["Estrecha", "Media", "Abierta"]],
	]
	var tp := _texto(11, COL_SUAVE)
	tp.text = "PIZARRA"
	_lista_tactica.add_child(tp)
	for p: Array in perillas:
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_lista_tactica.add_child(fila)
		var et := _texto(12, COL_SUAVE)
		et.text = String(p[0])
		et.custom_minimum_size = Vector2(90, 0)
		fila.add_child(et)
		var prop := String(p[1])
		var opciones: Array = p[2]
		for n in opciones.size():
			var b := Button.new()
			b.text = String(opciones[n])
			b.toggle_mode = true
			b.button_pressed = int(c.tactica.get(prop)) == n
			b.add_theme_font_size_override("font_size", 11)
			var valor := n
			b.pressed.connect(func() -> void:
				c.tactica.set(prop, valor)
				_refrescar())
			fila.add_child(b)

	## Los cuatro interruptores. Hasta esta tanda tampoco se guardaban.
	var interruptores := [
		["Salida corta", "salida_corta"], ["Marca al hombre", "marca_al_hombre"],
		["Trampa del fuera de juego", "fuera_de_juego"], ["Tiro lejano", "tiro_lejano"],
	]
	for it: Array in interruptores:
		var fila2 := HBoxContainer.new()
		fila2.add_theme_constant_override("separation", 6)
		_lista_tactica.add_child(fila2)
		var et2 := _texto(12, COL_SUAVE)
		et2.text = String(it[0])
		et2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila2.add_child(et2)
		var prop2 := String(it[1])
		var b2 := Button.new()
		b2.text = "SÍ" if bool(c.tactica.get(prop2)) else "NO"
		b2.add_theme_font_size_override("font_size", 11)
		b2.pressed.connect(func() -> void:
			c.tactica.set(prop2, not bool(c.tactica.get(prop2)))
			_refrescar())
		fila2.add_child(b2)
	_lista_tactica.add_child(HSeparator.new())

	_pintar_roles_tacticos(c)
	_pintar_balon_parado(c)

	## `vNormas()` del HTML: el reglamento interno. Va aquí, en Táctica, porque
	## son decisiones del mismo tipo -cómo se dirige al grupo- y ninguna de las
	## dos daba para pestaña propia.
	var tn := _texto(11, COL_SUAVE)
	tn.text = "REGLAMENTO INTERNO"
	_lista_tactica.add_child(tn)
	for norma: Array in Mundo.NORMAS_DEF:
		var clave := String(norma[0])
		var activa := bool(mundo.normas.get(clave, false))
		var fila_n := HBoxContainer.new()
		fila_n.add_theme_constant_override("separation", 6)
		_lista_tactica.add_child(fila_n)
		var en := _texto(12, COL_TEXTO if activa else COL_SUAVE)
		en.text = String(norma[1])
		en.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila_n.add_child(en)
		var bn := Button.new()
		bn.text = "SÍ" if activa else "NO"
		bn.add_theme_font_size_override("font_size", 11)
		bn.pressed.connect(func() -> void:
			mundo.normas[clave] = not bool(mundo.normas.get(clave, false))
			_refrescar())
		fila_n.add_child(bn)
		var dn := _texto(11, COL_SUAVE)
		dn.text = String(norma[2])
		dn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_tactica.add_child(dn)
	_lista_tactica.add_child(HSeparator.new())

	## EL ONCE. Se marca con un botón por jugador: los once primeros marcados
	## salen. Si el once no llega a once o alguien se lesiona, `Club.once()` se
	## vuelve al automático solo -su propia red de seguridad-, así que aquí no
	## hace falta impedir nada, solo contarlo.
	var to := _texto(11, COL_SUAVE)
	to.text = "EL ONCE  ·  %d de 11 elegidos%s" % [
		c.once_elegido.size(),
		"" if c.once_elegido.size() == 11 else "   (con menos de once manda el automático)"]
	_lista_tactica.add_child(to)
	var fila_b := HBoxContainer.new()
	fila_b.add_theme_constant_override("separation", 6)
	_lista_tactica.add_child(fila_b)
	_boton("Que lo arme el ayudante", func() -> void:
		c.limpiar_once()
		_refrescar(), fila_b)
	_boton("Vaciar", func() -> void:
		c.once_elegido.clear()
		_refrescar(), fila_b)

	var g := GridContainer.new()
	g.columns = 7
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 8)
	_lista_tactica.add_child(g)
	for enc in ["", "", "NOMBRE", "POS", "MED", "FORMA", "ESTADO"]:
		_celda(g, enc, COL_SUAVE, enc in ["MED", "FORMA"], 11)
	var orden := c.plantilla.duplicate()
	orden.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	for j: Jugador in orden:
		var dentro := c.once_elegido.has(j.id)
		var b := Button.new()
		b.text = "✔" if dentro else "＋"
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = not j.disponible() and not dentro
		b.pressed.connect(func() -> void:
			if dentro:
				c.once_elegido.erase(j.id)
			elif c.once_elegido.size() < 11:
				c.once_elegido.append(j.id)
			_refrescar())
		g.add_child(b)
		g.add_child(_retrato(j, 22))
		var col := COL_ACENTO if dentro else (COL_ROJO if not j.disponible() else COL_TEXTO)
		_celda(g, j.nombre, col, false, 12)
		_celda(g, j.pos_e, COL_SUAVE, false, 11)
		_celda(g, str(j.ovr), col, true, 12)
		_celda(g, str(j.forma), COL_SUAVE, true, 11)
		var estado := "listo"
		if j.lesion > 0:
			estado = "lesionado %d sem" % j.lesion
		elif j.suspension > 0:
			estado = "sancionado %d" % j.suspension
		_celda(g, estado, COL_ROJO if not j.disponible() else COL_SUAVE, false, 11)

	## Al final del todo: la moda de la era y la tabla de lo que te funciona. Van
	## abajo porque son lectura, no mandos: el pizarron y las perillas primero.
	_pintar_moda_tactica(c)

## `vDesafios()` del HTML: el puntaje de la carrera y los ocho desafíos. Se
## eligen al empezar la partida y no cambian, pero hasta hoy, una vez dentro,
## no había forma de recordar cuáles llevabas ni de ver para qué servían -el
## multiplicador es la única razón de elegir uno duro-.
func _pintar_desafios() -> void:
	_limpiar(_lista_desafios)
	var p := mundo.puntaje_carrera()
	var t := _texto(11, COL_SUAVE)
	t.text = "PUNTAJE DE CARRERA"
	_lista_desafios.add_child(t)
	var total := _texto(22, COL_ORO)
	total.text = _miles(int(p["total"]))
	_lista_desafios.add_child(total)
	var mult := _texto(12, COL_SUAVE)
	mult.text = "%s de base  ×  %.2f de multiplicador" % [_miles(int(p["base"])), float(p["multiplicador"])]
	_lista_desafios.add_child(mult)
	_lista_desafios.add_child(HSeparator.new())

	var td := _texto(11, COL_SUAVE)
	td.text = "DE DÓNDE SALE"
	_lista_desafios.add_child(td)
	_dato("Títulos  (× 1.000)", "%d  →  %s" % [int(p["titulos"]), _miles(int(p["titulos"]) * 1000)], COL_TEXTO, _lista_desafios)
	_dato("Prestigio  (× 40)", "%d  →  %s" % [int(p["prestigio"]), _miles(int(p["prestigio"]) * 40)], COL_TEXTO, _lista_desafios)
	_dato("Logros  (× 300)", "%d  →  %s" % [int(p["logros"]), _miles(int(p["logros"]) * 300)], COL_TEXTO, _lista_desafios)
	_dato("Temporadas  (× 120)", "%d  →  %s" % [int(p["temporadas"]), _miles(int(p["temporadas"]) * 120)], COL_TEXTO, _lista_desafios)
	_lista_desafios.add_child(HSeparator.new())

	var tt := _texto(11, COL_SUAVE)
	tt.text = "LOS OCHO DESAFÍOS"
	_lista_desafios.add_child(tt)
	var tabla: Variant = Datos.tabla("DESAFIOS")
	if not (tabla is Array):
		return
	for fila: Array in (tabla as Array):
		var clave := String(fila[0])
		var activo := mundo.desafios.has(clave)
		var fila_ui := HBoxContainer.new()
		fila_ui.add_theme_constant_override("separation", 8)
		_lista_desafios.add_child(fila_ui)
		var nom := _texto(12, COL_VERDE if activo else COL_SUAVE)
		nom.text = "%s %s%s" % [String(fila[2]), String(fila[1]), "   ✓ activo" if activo else ""]
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila_ui.add_child(nom)
		var x := _texto(12, COL_ORO if activo else COL_SUAVE)
		x.text = "×%.2f" % float(fila[4])
		fila_ui.add_child(x)
		var desc := _texto(11, COL_SUAVE)
		desc.text = String(fila[3])
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_desafios.add_child(desc)
	if not mundo.fin_partida.is_empty():
		_lista_desafios.add_child(HSeparator.new())
		var fin := _texto(12, COL_ROJO)
		fin.text = "💀 Partida marcada como terminada: cayó la primera derrota con el desafío del invicto activo (semana %d de %d). Puedes seguir jugando, pero el desafío está perdido." % [
			int(mundo.fin_partida.get("semana", 0)), int(mundo.fin_partida.get("anio", 0))]
		fin.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_desafios.add_child(fin)

## Cuatro pantallas del HTML en una sola pestaña, porque son la misma pregunta
## hecha a distinta profundidad -"¿qué hay ahí fuera?"-: `vLigas()` (la tabla de
## cualquier liga del mundo), `vClubes()` (el directorio de clubes),
## `vFichaClub()` (el plantel de uno concreto) y `vGoleadores()` (los artilleros
## de esa liga). Hasta hoy solo se veía TU liga y ningún plantel ajeno.
##
## No hace falta ni un dato nuevo: todo sale de `mundo.ligas` y de las
## plantillas que ya existen.
func _pintar_clubes() -> void:
	_limpiar(_lista_clubes)
	if _clubes_pais == "":
		_clubes_pais = mundo.mi_club().pais
	_pintar_rivalidades()

	var paises: Array[String] = []
	for l in mundo.ligas:
		if not paises.has(l.pais):
			paises.append(l.pais)
	paises.sort()
	var t := _texto(11, COL_SUAVE)
	t.text = "LIGAS DEL MUNDO"
	_lista_clubes.add_child(t)
	## Los países no caben en una fila: se reparten en filas de ocho.
	var fila_pais: HBoxContainer = null
	for i in paises.size():
		if i % 8 == 0:
			fila_pais = HBoxContainer.new()
			fila_pais.add_theme_constant_override("separation", 4)
			_lista_clubes.add_child(fila_pais)
		var pais := paises[i]
		var bp := Button.new()
		bp.text = pais
		bp.toggle_mode = true
		bp.button_pressed = pais == _clubes_pais
		bp.add_theme_font_size_override("font_size", 11)
		bp.pressed.connect(func() -> void:
			_clubes_pais = pais
			_clubes_ficha = null
			_pintar_clubes())
		fila_pais.add_child(bp)
	_lista_clubes.add_child(HSeparator.new())

	for l in mundo.ligas:
		if l.pais != _clubes_pais:
			continue
		var tl := _texto(12, COL_ORO)
		tl.text = l.nombre
		_lista_clubes.add_child(tl)
		var g := GridContainer.new()
		g.columns = 7
		g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_theme_constant_override("h_separation", 10)
		_lista_clubes.add_child(g)
		for enc in ["#", "CLUB", "PJ", "G", "E", "P", "PTS"]:
			_celda(g, enc, COL_SUAVE, enc != "CLUB" and enc != "#", 11)
		var puesto := 1
		for fila: Dictionary in l.tabla():
			var club: Club = fila["club"]
			_celda(g, str(puesto), COL_SUAVE, false, 11)
			## El nombre es un botón: pulsarlo abre su plantel abajo. Eso es
			## `vFichaClub()`, que en el HTML es una pantalla aparte.
			var b := Button.new()
			b.text = club.nombre
			b.flat = true
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.add_theme_font_size_override("font_size", 12)
			b.add_theme_color_override("font_color", _color_de_paleta(COL_ACENTO if club == mundo.mi_club() else COL_TEXTO))
			b.pressed.connect(func() -> void:
				_clubes_ficha = null if _clubes_ficha == club else club
				_pintar_clubes())
			g.add_child(b)
			for clave in ["pj", "g", "e", "p", "pts"]:
				_celda(g, str(int(fila.get(clave, 0))), COL_TEXTO if clave == "pts" else COL_SUAVE, true, 11)
			puesto += 1
		_lista_clubes.add_child(HSeparator.new())

	if _clubes_ficha != null:
		_pintar_ficha_club(_clubes_ficha)
	_pintar_goleadores(_clubes_pais)

## `vFichaClub()`: el plantel de un club cualquiera, con lo que se sabe de él.
## Las medias de los ajenos pasan por el mismo filtro de ojeo que el resto del
## juego -si no lo has visto jugar, no sabes exactamente cuánto vale-.
## `vRivalidades()`: el mapa de a quién le tienes ganas y por qué. No hay un
## contador nuevo detrás: la rivalidad se DEDUCE del cara a cara que `Logros` ya
## lleva partido a partido, más los clásicos de origen. Un contador aparte sería
## otra cosa que mantener al día y que puede desincronizarse.
func _pintar_rivalidades() -> void:
	if mundo.logros == null:
		return
	var lista := mundo.logros.rivalidades()
	if lista.is_empty():
		return
	_lista_clubes.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "🔥 MAPA DE RIVALIDADES"
	_lista_clubes.add_child(t)
	var ex := _texto(10, COL_SUAVE)
	ex.text = "La rivalidad no se declara: se construye. Sube con cada cruce y, sobre todo, con cada derrota."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_clubes.add_child(ex)
	for i in mini(8, lista.size()):
		var f: Dictionary = lista[i]
		var c: Club = f["club"]
		var v := int(f["valor"])
		var h: Dictionary = f["h2h"]
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_lista_clubes.add_child(fila)
		fila.add_child(_escudo(c, 22))
		var nom := _texto(12, COL_TEXTO)
		nom.text = "%s  ·  %s" % [c.nombre, String(f["nivel"])]
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nom.clip_text = true
		fila.add_child(nom)
		## El cara a cara en crudo, que es lo que justifica el número: quien mira
		## esto quiere saber si le gana o le pierde, no solo cuánto le odia.
		var hh := _texto(11, COL_SUAVE)
		hh.text = "%d PJ  ·  %d-%d-%d  ·  %d:%d" % [
			int(h["pj"]), int(h["pg"]), int(h["pe"]), int(h["pp"]), int(h["gf"]), int(h["gc"])]
		hh.custom_minimum_size = Vector2(150, 0)
		fila.add_child(hh)
		var val := _texto(13, COL_ROJO if v >= 60 else COL_ORO)
		val.text = str(v)
		val.custom_minimum_size = Vector2(30, 0)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		fila.add_child(val)

## "Es el Superclásico" / "Es el Clásico Universitario" / "Es un clásico tuyo".
func _frase_clasico(a: Club, b: Club) -> String:
	var n := HistoriaClub.nombre_clasico(a.nombre, b.nombre)
	if n == "":
		return "Es un clásico tuyo"
	return "Es " + n if n.begins_with("el ") else "Es el " + n

## C4: la historia del club (generada en la base ficticia, real con el pack).
func _historia_de(club: Club) -> Dictionary:
	var del_pais: Array = []
	for o: Club in mundo.clubes.values():
		if o.pais == club.pais:
			del_pais.append(o)
	return HistoriaClub.de(club, del_pais)

func _pintar_ficha_club(club: Club) -> void:
	var t := _texto(13, COL_ORO)
	t.text = "%s  ·  reputación %d  ·  aforo %s" % [club.nombre, club.rep, _miles(club.estadio_aforo)]
	_lista_clubes.add_child(t)
	var hi_c := _historia_de(club)
	for linea: String in ["📜 " + HistoriaClub.resumen(hi_c), HistoriaClub.texto_historia(hi_c), HistoriaClub.texto_clasicos(hi_c)]:
		if linea.strip_edges() == "":
			continue
		var hist := _texto(11, COL_TEXTO)
		hist.text = linea
		hist.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_clubes.add_child(hist)
	var sub := _texto(11, COL_SUAVE)
	sub.text = "%d jugadores  ·  media %.1f  ·  masa salarial %s/sem" % [
		club.plantilla.size(), club.media(), _dinero(club.masa_salarial())]
	_lista_clubes.add_child(sub)
	## LO QUE FALTABA DE `vFichaClub()`: la media del MEJOR ONCE, la forma, quién
	## lo entrena y si es clásico tuyo. Mirar la ficha de un rival es prepararse
	## un partido, y la media de la plantilla entera engaña —incluye a los nueve
	## suplentes que no van a jugar—.
	var once := club.once()
	var media_once := 0.0
	for j2 in once:
		media_once += float(j2.ovr)
	if not once.is_empty():
		media_once /= float(once.size())
	_dato("Media del mejor once", "%.1f" % media_once, COL_TEXTO, _lista_clubes)
	if mundo.roles != null and club == mundo.mi_club() and not mundo.roles.dt_empleado.is_empty():
		_dato("Entrenador", mundo.roles.dt_nombre(), COL_TEXTO, _lista_clubes)
	## El aviso de clásico: cambia cómo se juega ese partido -aforo, ánimo,
	## presión- y por eso tiene que verse aquí y no solo el día del choque.
	if club != mundo.mi_club() and mundo.es_clasico(mundo.mi_club(), club):
		var cl := _texto(12, COL_ORO)
		cl.text = "⚔️  %s: estadio lleno, prensa encima y el doble de presión." % _frase_clasico(mundo.mi_club(), club)
		cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_clubes.add_child(cl)
	var g := GridContainer.new()
	g.columns = 7
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 10)
	_lista_clubes.add_child(g)
	## Los AÑOS DE CONTRATO son la columna que convierte una plantilla ajena en
	## una lista de la compra: al que le queda uno se le puede precontratar.
	for enc in ["NOMBRE", "POS", "EDAD", "MED", "GOLES", "VALOR", "CONTR."]:
		_celda(g, enc, COL_SUAVE, enc in ["EDAD", "MED", "GOLES", "VALOR", "CONTR."], 11)
	var orden := club.plantilla.duplicate()
	orden.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	for j: Jugador in orden:
		var med := str(j.ovr) if club == mundo.mi_club() else (
			mundo.ojeadores.ovr_texto(j) if mundo.ojeadores != null else str(j.ovr))
		_fila_jugador(g, j,
			[j.nombre, j.pos_e, str(j.edad), med, str(j.goles), _dinero(j.valor),
				"%d año%s" % [j.anios_contrato, "" if j.anios_contrato == 1 else "s"]],
			[COL_TEXTO, COL_SUAVE, COL_SUAVE, COL_TEXTO,
				COL_VERDE if j.goles > 0 else COL_SUAVE, COL_SUAVE,
				COL_ORO if j.anios_contrato <= 1 else COL_SUAVE])
	_lista_clubes.add_child(HSeparator.new())

## `vGoleadores()`: la tabla de artilleros del país elegido. Se arma recorriendo
## las plantillas, que es donde viven los goles: no hace falta un registro
## aparte que mantener al día.
func _pintar_goleadores(pais: String) -> void:
	var todos: Array[Jugador] = []
	for l in mundo.ligas:
		if l.pais != pais:
			continue
		for club: Club in l.clubes:
			for j: Jugador in club.plantilla:
				if j.goles > 0:
					todos.append(j)
	var t := _texto(11, COL_SUAVE)
	t.text = "GOLEADORES  ·  %s" % pais
	_lista_clubes.add_child(t)
	if todos.is_empty():
		var nada := _texto(12, COL_SUAVE)
		nada.text = "Todavía no hay goles en esta liga."
		_lista_clubes.add_child(nada)
		return
	todos.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.goles > b.goles)
	var g := GridContainer.new()
	g.columns = 5
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 10)
	_lista_clubes.add_child(g)
	for enc in ["#", "", "JUGADOR", "CLUB", "GOLES"]:
		_celda(g, enc, COL_SUAVE, enc == "GOLES", 11)
	for i in mini(15, todos.size()):
		var j: Jugador = todos[i]
		var suyo: Club = mundo.clubes.get(j.club_id)
		_celda(g, str(i + 1), COL_SUAVE, false, 11)
		g.add_child(_retrato(j, 22))
		var b := Button.new()
		b.text = j.nombre
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 12)
		b.pressed.connect(func() -> void: _ver_ficha(j))
		g.add_child(b)
		_celda(g, suyo.nombre if suyo else "—", COL_SUAVE, false, 11)
		_celda(g, str(j.goles), COL_VERDE, true, 12)

## `vPremios()` del HTML: la gala de fin de año. El acta la calcula entera
## `Logros.premios_temporada()` desde hace tiempo -equipo ideal, mejor joven,
## mejor entrenador, fair play, club más popular, mejor hinchada, mejor
## estadio- y hasta hoy no se veía en ningún sitio: se calculaba, se guardaba y
## ahí moría. Esto es solo la vitrina de lo que ya se entregaba a puerta
## cerrada.
func _pintar_premios() -> void:
	_limpiar(_lista_premios)
	var lg := mundo.logros
	if lg == null or lg.premios.is_empty():
		var vacio := _texto(12, COL_SUAVE)
		vacio.text = "Las galas se celebran al cerrar cada temporada. Todavía no hay ninguna."
		vacio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_premios.add_child(vacio)
		return
	for acta: Dictionary in lg.premios:
		var t := _texto(13, COL_ORO)
		t.text = "GALA %d" % int(acta.get("anio", 0))
		_lista_premios.add_child(t)
		## Lo que se llevó TU club va primero y en verde: es lo que el jugador
		## viene a mirar. Si no ganó nada, se dice, en vez de dejar un hueco.
		var ganados: Array = acta.get("ganados", [])
		if ganados.is_empty():
			var nada := _texto(12, COL_SUAVE)
			nada.text = "Tu club se fue de vacío esta temporada."
			_lista_premios.add_child(nada)
		else:
			for premio in ganados:
				var g := _texto(12, COL_VERDE)
				g.text = "🏆  %s" % String(premio)
				g.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				_lista_premios.add_child(g)
		## `str()` y no `String()`: es la trampa 37 del proyecto -el constructor
		## `String()` revienta con tipos que `str()` traga sin quejarse-.
		_dato("🎩 Mejor entrenador", str(acta.get("dt", "—")), COL_VERDE if bool(acta.get("dt_es_mio", false)) else COL_TEXTO, _lista_premios)
		_dato("🌱 Mejor joven", str(acta.get("joven", "—")), COL_TEXTO, _lista_premios)
		_dato("🤝 Fair Play", str(acta.get("fairplay", "—")), COL_VERDE if bool(acta.get("fairplay_es_mio", false)) else COL_TEXTO, _lista_premios)
		_dato("❤️ Club más popular", str(acta.get("popular", "—")), COL_TEXTO, _lista_premios)
		_dato("📣 Mejor hinchada", str(acta.get("hinchada", "—")), COL_VERDE if bool(acta.get("hinchada_es_mia", false)) else COL_TEXTO, _lista_premios)
		_dato("🏟️ Mejor estadio", str(acta.get("estadio", "—")), COL_VERDE if bool(acta.get("estadio_es_mio", false)) else COL_TEXTO, _lista_premios)
		var ti := _texto(11, COL_SUAVE)
		ti.text = "EQUIPO IDEAL"
		_lista_premios.add_child(ti)
		var ideal := _texto(12, COL_TEXTO)
		## `acta["ideal"]` es un ARRAY de nombres, no un texto: `String()` de un
		## array no existe y reventaba en silencio al cerrar la temporada.
		var once_ideal: Array = acta.get("ideal", [])
		ideal.text = ", ".join(PackedStringArray(once_ideal)) if not once_ideal.is_empty() else "—"
		ideal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_premios.add_child(ideal)
		_lista_premios.add_child(HSeparator.new())

## `vPrevia()` del HTML: la pantalla de antes del partido. Todo lo que enseña
## es DERIVADO -no toca ni guarda nada-, así que se puede repintar cuantas veces
## haga falta sin consecuencias. Usa el mismo emparejamiento que `_dirigir()`
## (la copa manda sobre la liga) para no enseñar un rival y jugar contra otro.
## LOS JUEGOS MENTALES de `vPrevia()`. `Prensa` ENCIENDE dos banderas —el sobre
## con el informe del rival y la promesa hecha en conferencia— y hasta ahora no
## las apagaba nadie: `consumir_dato_del_rival()` y `consumir_presion()` estaban
## escritas, probadas y sin una sola llamada en todo el proyecto. Pagabas 80.000
## por espiar al rival y no pasaba absolutamente nada.
##
## Aquí es donde tienen que cobrarse las dos: en la previa, que es el momento en
## que la información sirve para algo.
func _pintar_juegos_mentales(rival: Club) -> void:
	if mundo.prensa == null:
		return
	var p := mundo.prensa
	## EL NODO «LECTURA» DEL ARBOL da el informe del rival SIEMPRE, sin tener que
	## comprarlo. `ve_tactica_rival()` estaba escrita y no la llamaba nadie: la
	## habilidad que existe para leer al rival no leia nada.
	var por_arbol := mundo.entrenamiento != null and mundo.entrenamiento.ve_tactica_rival()
	if not p.dato_del_rival and not p.presion_prometida and not por_arbol:
		return
	var t := _texto(11, COL_ORO)
	t.text = "🎭 JUEGOS MENTALES"
	_lista_partido.add_child(t)
	if p.dato_del_rival or por_arbol:
		## El informe del rival: el once que va a sacar y sus dos bajas. Se
		## consume al MIRAR la previa, no al jugar: lo que compraste fue saberlo
		## antes de decidir tu alineación, y si se gastara al pitido inicial
		## llegaría tarde para lo único que sirve.
		var e := _texto(12, COL_VERDE)
		e.text = "📄 Informe reservado: sabes con qué sale %s." % rival.nombre
		_lista_partido.add_child(e)
		var once := rival.once()
		var media := 0.0
		for j in once:
			media += float(j.ovr)
		if not once.is_empty():
			media /= float(once.size())
		_dato("Once probable del rival", "media %.1f" % media, COL_TEXTO, _lista_partido)
		var nombres: Array[String] = []
		for j2 in once:
			nombres.append("%s (%s)" % [j2.nombre, j2.pos_e])
		var l := _texto(11, COL_SUAVE)
		l.text = ", ".join(nombres)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_partido.add_child(l)
		var bajas: Array[String] = []
		for j3 in rival.plantilla:
			if j3.lesion > 0 or j3.suspension > 0:
				bajas.append(j3.nombre)
		if not bajas.is_empty():
			_dato("Bajas del rival", ", ".join(bajas), COL_VERDE, _lista_partido)
		## EXTENSIÓN TÁCTICA (22-9-2026, Fase 3 del ROADMAP: "extender el
		## espionaje... a información táctica"). Mismo informe, más datos: con
		## qué mentalidad/presión/línea sale el rival, no solo su once. Lee
		## `rival.tactica` directo -el mismo dial que decide `multiplicador_
		## ataque()`/`multiplicador_defensa()` en el partido real, así que esto
		## nunca puede quedar desincronizado de lo que de verdad va a pasar-.
		##
		## CAVEAT HONESTO, no escondido: ningún club de la IA cambia su
		## `tactica` fuera de un partido en curso (`Tactica.plan_para()`, según
		## el marcador) o de un DT EMPLEADO en TU propio club
		## (`Roles.aplicar_directrices()`, que nunca toca un rival). Así que
		## para casi cualquier rival esto va a leer "Equilibrada / Media /
		## Media" siempre -el valor de fábrica de `Tactica`-, partido tras
		## partido. Es dato real y no inventado -si mañana algún club de la IA
		## sale con una mentalidad propia, este informe la va a leer
		## corectamente sin tocar una línea más-, pero se documenta la
		## limitación en vez de venderlo como más dinámico de lo que es: darle
		## personalidad táctica real a la IA tocaría el balance de CADA
		## partido de la liga (multiplicador_ataque/defensa), una decisión de
		## diseño más grande que esta pantalla, no tomada hoy sin que el
		## usuario la pida.
		var tact := rival.tactica
		## `: String =`, no `:=` -indexar un Array literal sin tipar no deja
		## que el analizador infiera el tipo ("Cannot infer the type... doesn't
		## have a set type"), un error de PARSEO real que se lleva puesto todo
		## `principal.gd` -no solo esta función-. Ya documentado una vez en
		## `ui/escudo.gd` (ver LEEME.md, "GENERADOR DE ESCUDOS, SEGUNDA
		## TANDA"), y esta vez lo atrapó `captura_previa.gd` con pantalla real
		## -el banco headless no carga `principal.gd`, así que "0 fallos" no
		## lo vio-.
		var ment_nombre: String = ["Defensiva", "Equilibrada", "Ofensiva"][tact.mentalidad]
		var nivel_nombre := ["Baja", "Media", "Alta"]
		_dato("Mentalidad del rival", ment_nombre, COL_TEXTO, _lista_partido)
		_dato("Presión del rival", nivel_nombre[tact.presion], COL_TEXTO, _lista_partido)
		_dato("Línea defensiva del rival", nivel_nombre[tact.linea], COL_TEXTO, _lista_partido)
		p.consumir_dato_del_rival()
	if p.presion_prometida:
		var pr := _texto(12, COL_ORO)
		pr.text = "🗣️ Prometiste ganar en rueda de prensa. Si no ganas, la hinchada te lo va a cobrar."
		pr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_partido.add_child(pr)
	_lista_partido.add_child(HSeparator.new())

func _pintar_partido(c: Club) -> void:
	_limpiar(_lista_partido)
	if not mundo.temporada_en_curso():
		var fin := _texto(13, COL_SUAVE)
		fin.text = "La temporada está terminada. Pulsa «Temporada siguiente»."
		_lista_partido.add_child(fin)
		return
	var par := mundo.partido_de_copa()
	var es_copa := not par.is_empty()
	if not es_copa:
		par = mundo.proximo_partido()
	if par.is_empty():
		var descansa := _texto(13, COL_SUAVE)
		descansa.text = "Tu club descansa esta jornada."
		_lista_partido.add_child(descansa)
		return

	var local: Club = par[0]
	var visita: Club = par[1]
	var de_local := local == c
	var rival: Club = visita if de_local else local

	var cab := _texto(11, COL_SUAVE)
	cab.text = mundo.copa.nombre.to_upper() if es_copa else "JORNADA %d  ·  %s" % [
		_liga_de(c).jornada_actual, _liga_de(c).nombre]
	_lista_partido.add_child(cab)
	var vs := _texto(17, COL_TEXTO)
	vs.text = "%s   vs   %s" % [local.nombre, visita.nombre]
	_lista_partido.add_child(vs)
	var donde := _texto(12, COL_SUAVE)
	donde.text = "Juegas de %s  ·  %s" % ["LOCAL" if de_local else "VISITA", rival.nombre]
	_lista_partido.add_child(donde)
	if mundo.es_clasico(c, rival):
		var clasico := _texto(13, COL_ORO)
		var nom_cl := HistoriaClub.nombre_clasico(c.nombre, rival.nombre)
		clasico.text = "🔥 ¡%s!" % (nom_cl.to_upper() if nom_cl != "" else "ES CLÁSICO")
		_lista_partido.add_child(clasico)
	## LA FRASE DE LA PARED, justo antes de salir. Es lo que el HTML prometia
	## en la pantalla del club por dentro -"se lee en el tunel antes de cada
	## partido"- y no cumplia en ninguna parte.
	if mundo.club_dentro != null and mundo.club_dentro.frase != "":
		var fr := _texto(13, Color(mundo.club_dentro.color_ct2(c)))
		fr.text = "«%s»" % mundo.club_dentro.frase
		fr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_lista_partido.add_child(fr)
		var fr2 := _texto(10, COL_SUAVE)
		fr2.text = "En la pared del túnel"
		fr2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_lista_partido.add_child(fr2)
	_lista_partido.add_child(HSeparator.new())

	_pintar_juegos_mentales(rival)

	var arb := Previa.arbitro_de(rival.id, mundo.semana)
	_dato("👨‍⚖️ Árbitro", "%s — %s" % [String(arb["nombre"]), String(arb["descripcion"])], COL_SUAVE, _lista_partido)
	var dtr := Previa.dt_de(rival)
	_dato("🎩 DT rival", "%s — %s" % [String(dtr["nombre"]), String(dtr["descripcion"])], COL_SUAVE, _lista_partido)
	_lista_partido.add_child(HSeparator.new())

	## Las fuerzas salen de un `Partido` de mentira, montado solo para medir: es
	## el mismo cálculo que usará el de verdad, así que lo que dice la previa es
	## lo que va a pasar en el campo.
	var medidor := Partido.new(local, visita)
	medidor.preparar()
	var f_local := medidor.fuerza(medidor.once_local, local)
	var f_visita := medidor.fuerza(medidor.once_visita, visita)
	var f_mia: Dictionary = f_local if de_local else f_visita
	var f_suya: Dictionary = f_visita if de_local else f_local
	var ti := _texto(11, COL_SUAVE)
	ti.text = "INFORME"
	_lista_partido.add_child(ti)
	_dato("Tu ataque vs su defensa", "%d / %d" % [int(round(f_mia["ata"])), int(round(f_suya["def"]))], COL_TEXTO, _lista_partido)
	_dato("Tu defensa vs su ataque", "%d / %d" % [int(round(f_mia["def"])), int(round(f_suya["ata"]))], COL_TEXTO, _lista_partido)

	var cuo := Previa.cuotas(f_mia, f_suya, de_local)
	var tc := _texto(11, COL_SUAVE)
	tc.text = "🎰 CASA DE APUESTAS"
	_lista_partido.add_child(tc)
	_dato("Ganas tú", "%.2f" % float(cuo["cuota_gano"]), COL_TEXTO, _lista_partido)
	_dato("Empate", "%.2f" % float(cuo["cuota_empate"]), COL_SUAVE, _lista_partido)
	_dato("Gana %s" % rival.nombre, "%.2f" % float(cuo["cuota_pierdo"]), COL_TEXTO, _lista_partido)
	var lectura := _texto(11, COL_SUAVE)
	var p_gano: float = cuo["p_gano"]
	var p_pierdo: float = cuo["p_pierdo"]
	var p_empate: float = cuo["p_empate"]
	if p_gano > p_pierdo + 0.08 and p_gano > p_empate:
		lectura.text = "Las cuotas te tienen como favorito: si el resultado no acompaña, la prensa y la hinchada lo van a leer peor de lo normal."
	elif p_pierdo > p_gano + 0.08 and p_pierdo > p_empate:
		lectura.text = "Vas de underdog en las apuestas: sumar acá se festeja como una machada."
	else:
		lectura.text = "Cuotas parejas: partido de pronóstico cerrado, sin favorito claro para las casas."
	lectura.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_partido.add_child(lectura)

	## El informe del rival no es gratis: en el HTML pide la habilidad `lectura`
	## del DT o haberlo espiado. Aquí lo abre la sala de vídeo -`Instalaciones.
	## lectura_del_rival()`, que ya existía y no la miraba nadie-: si has
	## construido el análisis, ves su plan; si no, no.
	if mundo.obras.lectura_del_rival() > 0:
		_lista_partido.add_child(HSeparator.new())
		var tv := _texto(11, COL_SUAVE)
		tv.text = "👁️ INFORME DEL RIVAL  (sala de vídeo)"
		_lista_partido.add_child(tv)
		_dato("Sistema previsto", rival.tactica.formacion, COL_TEXTO, _lista_partido)
		_dato("Mentalidad", ["Defensiva", "Equilibrada", "Ofensiva"][rival.tactica.mentalidad], COL_TEXTO, _lista_partido)
		_dato("Punto débil", "la última línea" if f_suya["def"] < f_suya["ata"] else "la generación de juego", COL_TEXTO, _lista_partido)

	## `vAlineacion()` del HTML: los dos onces tal como van a salir, con su
	## ranura en la formación y su dorsal. El `medidor` de arriba ya los tiene
	## armados -es el mismo `preparar()` que usará el partido de verdad-, así
	## que enseñarlos no cuesta ni un cálculo más.
	_lista_partido.add_child(HSeparator.new())
	var ta := _texto(11, COL_SUAVE)
	ta.text = "LOS ONCES"
	_lista_partido.add_child(ta)
	var g := GridContainer.new()
	g.columns = 4
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 12)
	_lista_partido.add_child(g)
	_celda(g, "", COL_SUAVE)
	_celda(g, "%s  (%s)" % [local.nombre, local.tactica.formacion], COL_ACENTO if de_local else COL_TEXTO, false, 12)
	_celda(g, "", COL_SUAVE)
	_celda(g, "%s  (%s)" % [visita.nombre, visita.tactica.formacion], COL_TEXTO if de_local else COL_ACENTO, false, 12)
	for i in maxi(medidor.once_local.size(), medidor.once_visita.size()):
		if i < medidor.once_local.size():
			var jl: Jugador = medidor.once_local[i]
			g.add_child(_retrato(jl, 22))
			_celda(g, "%s  %s" % [jl.pos_e, jl.nombre], COL_TEXTO, false, 11)
		else:
			_celda(g, "", COL_SUAVE)
			_celda(g, "", COL_SUAVE)
		if i < medidor.once_visita.size():
			var jv: Jugador = medidor.once_visita[i]
			g.add_child(_retrato(jv, 22))
			_celda(g, "%s  %s" % [jv.pos_e, jv.nombre], COL_TEXTO, false, 11)
		else:
			_celda(g, "", COL_SUAVE)
			_celda(g, "", COL_SUAVE)

	_lista_partido.add_child(HSeparator.new())
	_selector_modo_partido(_lista_partido)
	_boton("▶ Jugar el partido", _dirigir, _lista_partido)

## `vCalendario` -pantalla nueva, sin equivalente en el HTML-: el usuario la
## pidió después de ver una referencia de otro manager (grilla con los
## próximos partidos marcados, escudo del rival, desde la que se simula de
## corrido o se salta el partido entero sin dirigirlo). En vez de inventar un
## sistema de fechas nuevo, lee el mismo `Liga.calendario` que ya arma la
## temporada entera desde el sorteo.
## C13: lo que viene en el calendario del país (fiestas, memoria, festividades)
## y el gran torneo del año, si lo hay.
func _pintar_proximas_fechas(c: Club) -> void:
	var t := _texto(11, COL_SUAVE)
	t.text = "PRÓXIMAS FECHAS EN %s" % c.pais
	_lista_calendario.add_child(t)
	for f: Dictionary in Calendario.proximas(c.pais, mundo.anio, mundo.semana, 5):
		var l := _texto(12, COL_ROJO if String(f["tipo"]) == "memoria" else COL_TEXTO)
		var faltan := int(f["faltan"])
		var cuando := "%d de %s" % [int(f["dia"]), MESES_LARGOS[int(f["mes"]) - 1]]
		## "11 de septiembre" ya es la fecha: no repetirla.
		var nom := String(f["nombre"])
		l.text = "%s %s%s  (%s)" % [Calendario.icono(String(f["tipo"])), cuando,
			"" if nom == cuando else " · " + nom, "esta semana" if faltan < 7 else "en %d días" % faltan]
		l.tooltip_text = String(f["texto"])
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		_lista_calendario.add_child(l)
	for tor: Dictionary in Calendario.torneos(mundo.anio):
		var sedes: Array = tor["sedes"]
		var l2 := _texto(12, COL_ORO)
		l2.text = "🌍 %s %d: del %d/%d al %d/%d%s" % [String(tor["nombre"]), mundo.anio,
			int(tor["desde"][1]), int(tor["desde"][0]), int(tor["hasta"][1]), int(tor["hasta"][0]),
			(" · sede: " + ", ".join(sedes)) if not sedes.is_empty() else ""]
		_lista_calendario.add_child(l2)
	_lista_calendario.add_child(HSeparator.new())

func _pintar_calendario(c: Club) -> void:
	_limpiar(_lista_calendario)
	if not mundo.temporada_en_curso():
		var fin := _texto(13, COL_SUAVE)
		fin.text = "La temporada está terminada. Pulsa «Temporada siguiente»."
		_lista_calendario.add_child(fin)
		return

	_pintar_proximas_fechas(c)
	## PRÓXIMO PARTIDO, con el MISMO orden que usa `_dirigir()` -copa antes que
	## liga-: mostrar aquí un partido distinto del que se juega al pulsar el
	## botón sería peor que no mostrar nada.
	var tp := _texto(11, COL_SUAVE)
	tp.text = "PRÓXIMO PARTIDO"
	_lista_calendario.add_child(tp)
	var par := mundo.partido_de_copa()
	var es_copa := not par.is_empty()
	if not es_copa:
		par = mundo.proximo_partido()
	if par.is_empty():
		var descansa := _texto(13, COL_SUAVE)
		descansa.text = "Tu club descansa esta jornada."
		_lista_calendario.add_child(descansa)
	else:
		var local: Club = par[0]
		var visita: Club = par[1]
		var de_local := local == c
		var rival: Club = visita if de_local else local
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		_lista_calendario.add_child(fila)
		fila.add_child(_escudo(rival, 36))
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(info)
		var nom := _texto(15, COL_TEXTO)
		nom.text = rival.nombre
		info.add_child(nom)
		var sub := _texto(11, COL_SUAVE)
		sub.text = "%s  ·  %s" % [
			mundo.copa.nombre if es_copa else _liga_de(c).nombre,
			"Local" if de_local else "Visitante"]
		info.add_child(sub)
		## Si además hay ronda continental esta misma semana -`CONTI_EN` no
		## evita que caiga junto a una jornada normal, ver nota en el LEEME-,
		## se avisa aparte: el botón de abajo dirige lo mismo que dirigiría
		## `_dirigir()`, nunca el continental, así que mostrarlo como "el
		## próximo partido" habría sido mentir.
		var mi_conti := mundo.mi_continental()
		if Continental.toca_ronda(mundo.semana) >= 0 and mi_conti != null and mi_conti.en_curso():
			var av := _texto(10, COL_ORO)
			av.text = "También hay ronda de %s esta semana." % Continental.nombre_conti(mi_conti.clave)
			av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			info.add_child(av)
		if mundo.es_clasico(c, rival):
			var clasico := _texto(12, COL_ORO)
			var nom_cl2 := HistoriaClub.nombre_clasico(c.nombre, rival.nombre)
			clasico.text = "🔥 ¡%s!" % (nom_cl2 if nom_cl2 != "" else "Es clásico")
			_lista_calendario.add_child(clasico)
		var filab := HBoxContainer.new()
		filab.add_theme_constant_override("separation", 6)
		_lista_calendario.add_child(filab)
		_selector_modo_partido(_lista_calendario)
		_lista_calendario.move_child(filab, _lista_calendario.get_child_count() - 1)
		_boton("▶ Jugar el partido", _dirigir, filab)

	_lista_calendario.add_child(HSeparator.new())
	_boton("⏭⏭ Simular toda la temporada", _jugar_temporada, _lista_calendario)
	_lista_calendario.add_child(HSeparator.new())

	## EL CALENDARIO DE LIGA COMPLETO. Se recorre `Liga.calendario` a mano -no
	## `emparejamiento_de()`, que solo conoce la jornada ACTUAL- desde hoy
	## hasta el final: son datos que ya existen enteros desde que se sorteó la
	## temporada, así que enseñarlos no inventa nada nuevo, solo lo hace
	## visible.
	var liga := _liga_de(c)
	var tl := _texto(11, COL_SUAVE)
	tl.text = "CALENDARIO DE %s" % liga.nombre.to_upper()
	_lista_calendario.add_child(tl)
	for i in range(liga.jornada_actual, liga.calendario.size()):
		var jornada: Array = liga.calendario[i]
		for pareja: Array in jornada:
			var loc: Club = pareja[0]
			var vis: Club = pareja[1]
			if loc != c and vis != c:
				continue
			var de_loc := loc == c
			var riv: Club = vis if de_loc else loc
			var actual := i == liga.jornada_actual
			var fj := HBoxContainer.new()
			fj.add_theme_constant_override("separation", 8)
			_lista_calendario.add_child(fj)
			var lj := _texto(11, COL_ORO if actual else COL_SUAVE)
			lj.text = "J%d" % (i + 1)
			lj.custom_minimum_size = Vector2(34, 0)
			fj.add_child(lj)
			fj.add_child(_escudo(riv, 20))
			var nj := _texto(12, COL_TEXTO if actual else COL_SUAVE)
			nj.text = "%s  (%s)" % [riv.nombre, "L" if de_loc else "V"]
			nj.clip_text = true
			nj.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fj.add_child(nj)
			break

func _fichar_libre(j: Jugador) -> void:
	var idx := mundo.libres.find(j)
	if idx < 0:
		return
	var r := mundo.fichar_libre(idx, mundo.mi_club())
	if r.has("error"):
		_escribir("[color=#e05555]No se pudo: %s.[/color]" % String(r["error"]))
	elif r.get("rechazado", false):
		if r.get("expulsado", false):
			_escribir("[color=#c9a227]%s rechaza tu oferta y decide esperar en otro sitio.[/color] Ya no está en el mercado de libres." % j.nombre)
		else:
			_escribir("[color=#c9a227]%s rechaza tu oferta.[/color] Puedes volver a intentarlo." % j.nombre)
	else:
		Sonido.toca("fichaje")
		_escribir("[color=#4caf6d]FICHADO LIBRE: %s.[/color] Sin traspaso, con la prima de fichaje ya pagada." % j.nombre)
	_refrescar()

func _abrir_negociacion(j: Jugador) -> void:
	var motivo := mundo.mercado.abrir_negociacion(j)
	if motivo != "":
		_escribir("[color=#e05555]No se pudo abrir la mesa: %s.[/color]" % motivo)
		return
	_negociacion_ultimo = {}
	_ir_a_pestana("Mercado")
	_refrescar()

func _enviar_oferta_negociacion() -> void:
	var n := mundo.mercado.negociacion
	if n == null:
		return
	var j := n.jugador
	var res := n.enviar_oferta()
	_negociacion_ultimo = res
	var tipo := String(res.get("tipo", ""))
	match tipo:
		"sin_caja":
			_escribir("[color=#e05555]No te alcanza:[/color] la parte fija más la comisión cuesta %s." % _dinero(int(res.get("hace_falta", 0))))
		"club_pide_mas":
			_escribir("[color=#c9a227]↩️ Contraoferta de %s.[/color] Faltan unos %s y prefieren %s." % [
				(mundo.clubes.get(j.club_id) as Club).nombre if mundo.clubes.has(j.club_id) else "el club",
				_dinero(int(res.get("falta", 0))), String(res.get("prefiere", ""))])
		"rota":
			_escribir("[color=#e05555]❌ Negociación rota.[/color] El club se levantó de la mesa por %s." % j.nombre)
			mundo.mercado.cerrar_negociacion()
		"rival_traspaso", "rival_firma":
			var rc: Club = res.get("club")
			_escribir("[color=#e05555]💥 Fichaje perdido:[/color] %s cerró el traspaso de %s por %s mientras seguías negociando." % [
				rc.nombre if rc else "otro club", j.nombre, _dinero(int(res.get("precio", 0)))])
			mundo.mercado.cerrar_negociacion()
		"jugador_no":
			_escribir("[color=#c9a227]%s todavía no firma.[/color] %s" % [j.nombre, String(res.get("motivo", ""))])
		"jugador_rota":
			_escribir("[color=#e05555]❌ %s dice que no.[/color] %s No se sienta a hablar de él por un tiempo." % [j.nombre, String(res.get("motivo", ""))])
			mundo.mercado.cerrar_negociacion()
		"cerrado":
			var r: Dictionary = res.get("resumen", {})
			Sonido.toca("fichaje")
			_escribir("[color=#4caf6d][b]✅ Fichaje cerrado:[/b][/color] %s firma por %d temporadas con ficha de %s/semana." % [
				j.nombre, int(r.get("anios", n.anios)), _dinero(int(r.get("sueldo", n.sueldo)))])
			mundo.mercado.cerrar_negociacion()
			_negociacion_ultimo = {}
	_refrescar()

func _cancelar_negociacion() -> void:
	mundo.mercado.cerrar_negociacion()
	_negociacion_ultimo = {}
	_refrescar()

## El estado de la copa: en qué ronda va, quién sigue vivo y cómo cayó cada
## eliminatoria. Se pinta al revés que la liga -de la ronda más reciente hacia
## atrás- porque lo que interesa es lo que acaba de pasar.
func _pintar_copa(mio: Club) -> void:
	_limpiar(_lista_copa)
	if mundo.copa == null:
		var vacio := _texto(12, COL_SUAVE)
		vacio.text = "La copa se sortea al empezar la temporada."
		_lista_copa.add_child(vacio)
		return
	var c := mundo.copa
	var cab := _texto(14, COL_ORO)
	if c.campeon != null:
		cab.text = "%s — campeón: %s" % [c.nombre, c.campeon.nombre]
	elif c.en_curso():
		cab.text = "%s — %s  (%d equipos vivos)" % [c.nombre, c.nombre_de_ronda(), c.vivos.size()]
	else:
		cab.text = c.nombre
	_lista_copa.add_child(cab)

	if c.en_curso():
		var cruce := c.emparejamiento_de(mio)
		var estado := _texto(12, COL_VERDE if not cruce.is_empty() else COL_ROJO)
		if not cruce.is_empty():
			estado.text = "Te toca: %s  vs  %s" % [cruce[0].nombre, cruce[1].nombre]
		else:
			estado.text = "%s ya está eliminado." % mio.nombre
		_lista_copa.add_child(estado)

	for i in range(c.historial.size() - 1, -1, -1):
		var ronda: Dictionary = c.historial[i]
		_lista_copa.add_child(HSeparator.new())
		var t := _texto(11, COL_SUAVE)
		t.text = String(ronda["ronda"]).to_upper()
		_lista_copa.add_child(t)
		var g := GridContainer.new()
		g.columns = 3
		g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_theme_constant_override("h_separation", 10)
		_lista_copa.add_child(g)
		for r: Dictionary in ronda["resultados"]:
			var mio_juega: bool = r["local"] == mio or r["visita"] == mio
			var col := COL_ACENTO if mio_juega else COL_TEXTO
			_celda(g, String(r["local"].nombre), col if r["pasa"] == r["local"] else COL_SUAVE)
			var marcador := "%d-%d" % [r["gl"], r["gv"]]
			if not r["penales"].is_empty():
				marcador += "  (%d-%d pen.)" % [r["penales"][0], r["penales"][1]]
			_celda(g, marcador, col, true)
			_celda(g, String(r["visita"].nombre), col if r["pasa"] == r["visita"] else COL_SUAVE)

## Candidatos: gente de otros clubes que mejora tu plantel. Se mira una muestra,
## no los 8.448 del mundo: recorrerlos todos para repintar una lista de 30 sería
## tirar el trabajo que costó que la simulación fuera rápida.
func _objetivos(mio: Club) -> Array[Jugador]:
	var media := mio.media()
	var vistos := {}
	var salida: Array[Jugador] = []
	var clubes: Array = mundo.clubes.values()
	for intento in 400:
		if salida.size() >= 30:
			break
		var otro: Club = clubes[Azar.ent(0, clubes.size() - 1)]
		if otro.id == mio.id or otro.plantilla.is_empty():
			continue
		var j: Jugador = otro.plantilla[Azar.ent(0, otro.plantilla.size() - 1)]
		if vistos.has(j.id) or float(j.ovr) < media:
			continue
		vistos[j.id] = true
		salida.append(j)
	salida.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	return salida

## La ficha. Es la pantalla donde el jugador decide, así que enseña las TRES
## puertas del fichaje juntas -lo que pide su club, lo que pide él de ficha y las
## ganas que tiene de venir- y no solo el precio.
## `_paleta_ficha()`: los colores YA resueltos que reciben `FichaJugadorInfo` y
## `TablaCompeticion` -mismo criterio, misma lección del bug de coherencia
## visual del 25-9-2026 (`PanelMercado` no la tenía desde el principio y hubo
## que corregirla después).
func _paleta_ficha() -> Dictionary:
	return {
		"suave": _pal_suave(), "texto": _pal_texto(), "acento": COL_ACENTO,
		"verde": _color_accesible(COL_VERDE), "rojo": _color_accesible(COL_ROJO),
		"oro": _color_accesible(COL_ORO), "escala": _escala_texto,
	}

func _ver_ficha(j: Jugador) -> void:
	if j == null or (_seleccionado != null and j.id != _seleccionado.id):
		_confirmar_rescision_id = ""
	_seleccionado = j
	## La pestaña Entrenar muestra el árbol de habilidades DEL SELECCIONADO, pero
	## no pasa por aquí cuando se pulsa una fila del plantel -eso llama solo a
	## _ver_ficha(), no a _refrescar()-, así que sin esto el árbol se quedaba con
	## el jugador anterior hasta la siguiente semana.
	_pintar_entrenamiento(mundo.mi_club())
	for n in _ficha.get_children():
		if n is Label and n.text == "FICHA DEL JUGADOR":
			continue
		_ficha.remove_child(n)
		n.queue_free()
	if j == null:
		var vacio := _texto(12, COL_SUAVE)
		vacio.text = "Pulsa un jugador de la lista para ver su ficha."
		_ficha.add_child(vacio)
		return

	var mio := mundo.mi_club()
	var suyo: Club = mundo.clubes.get(j.club_id)
	var propio := suyo == mio

	## La ficha con su cara grande: es la pantalla donde se decide si se ficha a
	## alguien, y una cara pega el nombre a una persona.
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 10)
	_ficha.add_child(cab)
	var retrato := TextureRect.new()
	retrato.texture = Cara.textura(j, suyo.color1 if suyo else "#2b6b45",
		suyo.color2 if suyo else "#ffffff", 64)
	retrato.custom_minimum_size = Vector2(64, 64)
	retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cab.add_child(retrato)
	var nom := _texto(19, COL_TEXTO)
	nom.text = j.nombre
	nom.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cab.add_child(nom)
	var det := _texto(12, COL_SUAVE)
	det.text = "%s · %d años · %s · %s" % [
		j.pos_e, j.edad, suyo.nombre if suyo else "sin club",
		Nombres.limpiar(String((Datos.tabla("RASGOS") as Dictionary).get(j.rasgo, ["sin rasgo"])[0])) if j.rasgo != "" else "sin rasgo"]
	_ficha.add_child(det)
	var credito := Cara.credito_foto(j)
	if credito != "":
		var cr := _texto(9, COL_SUAVE)
		cr.text = credito
		cr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_ficha.add_child(cr)

	## La proyección de un rival no se ve gratis: `vComparador()` en vistas.js
	## la esconde con un "?" salvo que sea tuyo o ya lo hayas ojeado
	## (`j.club===G.miClub||j.ojeado`), y hasta esta tanda la ficha de Godot
	## enseñaba el potencial de CUALQUIERA sin condición -el ojeo pasaba a
	## alimentar `mundo.ojeados` desde el primer día, pero nada lo leía-.
	var conoce_potencial := j.club_id == mundo.mi_club_id or mundo.ojeados.has(j.id)
	## MODO CIEGO (`cegado()` del HTML): con `Ojeadores.modo_ciego` activado y un
	## rival que no conoces, ni la grilla de atributos se enseña -se cambia por
	## el informe cualitativo de `_pintar_ficha_ciega()`, mejor/peor cualidad y
	## fiabilidad en vez de números-. Hasta esta tanda la ficha SIEMPRE pintaba
	## los atributos exactos de cualquiera, ajuste o no.
	var cegado_ficha := not propio and mundo.ojeadores != null and mundo.ojeadores.modo_ciego and not conoce_potencial
	if cegado_ficha:
		FichaJugadorInfo.pintar_ciega(_ficha, j, mundo, _paleta_ficha())
	else:
		var g := GridContainer.new()
		g.columns = 4
		g.add_theme_constant_override("h_separation", 10)
		g.add_theme_constant_override("v_separation", 3)
		_ficha.add_child(g)
		## Los atributos, que son la razón de que un central de 90 de ritmo no
		## sea un central de 90.
		for k: String in j.atributos:
			_celda(g, String(NOMBRES_ATRIBUTOS.get(k, k)), COL_SUAVE, false, 11)
			var v := int(j.atributos[k])
			_celda(g, str(v), COL_VERDE if v >= 80 else (COL_TEXTO if v >= 65 else COL_SUAVE), true, 12)

	_ficha.add_child(HSeparator.new())
	## La media de un rival tampoco se ve exacta salvo que lo conozcas bien
	## -ovrTxt() del HTML-: sale un rango que se cierra cuanto mejor cubierto
	## esté su país por tu red de ojeadores, o del todo si ya lo ojeaste.
	var media_txt := str(j.ovr) if propio else (mundo.ojeadores.ovr_texto(j) if mundo.ojeadores != null else str(j.ovr))
	_dato("Media / potencial", "%s / %s" % [media_txt, str(j.pot) if conoce_potencial else "?"], COL_TEXTO)
	## CUANTO HA CRECIDO ESTA TEMPORADA. Es la unica linea de la ficha que dice
	## si tu academia y tu plan de entrenamiento sirven de algo: mirando solo la
	## media de hoy no se distingue a un chico que crece de uno que se estanco.
	if propio and j.ovr_al_empezar > 0:
		var crec := j.crecimiento_temporada()
		_dato("Este año", "%+d de media (empezó en %d)" % [crec, j.ovr_al_empezar],
			COL_VERDE if crec > 0 else (COL_ROJO if crec < 0 else COL_SUAVE))
	_dato("Forma", str(j.forma), COL_TEXTO)
	_dato("Moral", str(j.moral), COL_VERDE if j.moral >= 60 else COL_ROJO)
	_dato("Contrato", "%d año%s" % [j.anios_contrato, "" if j.anios_contrato == 1 else "s"],
		COL_ROJO if j.anios_contrato <= 1 else COL_TEXTO)
	## C9: el tipo de contrato y su límite legal (norma FIFA).
	_dato("Régimen", Contratos.tipo(j, mundo.cesiones != null and mundo.cesiones.esta_cedido(j.id)), COL_SUAVE)
	_dato("Valor de tasación", _dinero(j.valor), COL_TEXTO)
	## LOS DERECHOS DE FORMACIÓN. `Cesiones.derechos_de_formacion()` se COBRA de
	## verdad en cada traspaso, pero no se veía en ninguna pantalla: podías
	## vender a un chico de veinte y llevarte un 10% menos de lo que esperabas
	## sin entender por qué. Ahora se avisa ANTES, que es cuando sirve.
	if mundo.cesiones != null and j.club_formacion != "" and j.club_formacion != j.club_id:
		var pct := mundo.cesiones.derechos_de_formacion(j, mio)
		if pct > 0.0:
			var formador: Club = mundo.clubes.get(j.club_formacion)
			_dato("Derechos de formación", "%d%% para %s" % [
				int(round(pct * 100.0)), formador.nombre if formador else "su club formador"],
				COL_ORO)
	_dato("Sueldo actual", _dinero(j.sueldo) + " / semana", COL_TEXTO)
	## El detalle de la baja -antes solo decía "lesión, N semanas" o
	## "sancionado" a secas-: `Medico.diagnostico()` ya sabe el TIPO exacto
	## (esguince, rotura...) desde que se porta el parte médico, y `j.suspension`
	## ya llevaba la cuenta de fechas sin que ninguna pantalla la mostrara.
	if j.lesion > 0:
		var tipo := mundo.medico.diagnostico(j) if mundo.medico != null else ""
		_dato("Estado", ("%s: vuelve en %d semana(s)" % [tipo, j.lesion]) if tipo != "" else
			"lesión, %d semanas" % j.lesion, COL_ROJO)
	elif j.suspension > 0:
		_dato("Estado", "Suspendido %d fecha(s)" % j.suspension, COL_ROJO)
	if j.adapt > 0:
		_dato("Adaptándose a su nueva posición", "%d semana(s) rindiendo por debajo" % j.adapt, COL_ORO)
	## `Perfil` del HTML: una fila propia con el rasgo -ademas del que ya sale
	## resumido en la cabecera-. La descripcion larga (RASGOS[rasgo][1]) va en
	## la biografia de mas abajo, junto al nombre, igual que hace el HTML.
	if j.rasgo != "":
		var rdesc: Array = (Datos.tabla("RASGOS") as Dictionary).get(j.rasgo, ["sin rasgo", ""])
		_dato("Perfil", "✦ %s" % Nombres.limpiar(String(rdesc[0])), COL_ORO)
	## `Últimas notas` del HTML: se ve siempre, propio o ajeno.
	_dato("Últimas notas", " · ".join(PackedStringArray(j.notas.map(func(n: float) -> String: return "%.1f" % n))) if not j.notas.is_empty() else "—", COL_TEXTO)

	## El informe individual -ojearJug() del HTML-: paga y a partir de ahí ese
	## jugador se ve exacto para siempre, media y proyección incluidas.
	if not propio and mundo.ojeadores != null and not mundo.ojeados.has(j.id):
		var costo_oj := mundo.ojeadores.costo_informe()
		var bo := Button.new()
		bo.text = "Pedir informe de ojeo  %s" % _dinero(costo_oj)
		bo.disabled = costo_oj > mundo.ojeadores.presupuesto and (mio == null or costo_oj > mio.saldo)
		bo.pressed.connect(func() -> void: _pedir_informe_ojeo(j))
		_ficha.add_child(bo)

	## compararJug(pid) del HTML: funciona igual para un jugador propio que
	## ajeno -por eso va aquí, antes de que la ficha se bifurque-.
	var en_comparador := _comparar_ids.has(j.id)
	var bc2 := Button.new()
	bc2.text = "Quitar del comparador" if en_comparador else "Comparar"
	bc2.disabled = not en_comparador and _comparar_ids.size() >= 3
	bc2.pressed.connect(func() -> void: _alternar_comparar(j))
	_ficha.add_child(bc2)

	if propio:
		var pal := _paleta_ficha()
		FichaJugadorInfo.pintar_estadisticas(_ficha, j, pal)
		FichaJugadorInfo.pintar_perfil_y_premios(_ficha, j, pal)
		FichaJugadorInfo.pintar_cabeza(_ficha, j, mundo, pal)
		FichaJugadorInfo.pintar_promesa(_ficha, j, mundo, pal)
		FichaJugadorAcciones.pintar_desarrollo(_ficha, j, mundo, func() -> void:
			var problema := mundo.entrenamiento.alternar_prioritario(j)
			if problema != "":
				_escribir("[color=#e05555]%s[/color]" % problema)
			_ver_ficha(j))
		FichaJugadorInfo.pintar_habilidades(_ficha, j, mundo, pal)
		FichaJugadorAcciones.pintar_reconversion(_ficha, j, mundo, pal,
			func(destino: String) -> void: _reconvertir(j, destino))
		FichaJugadorInfo.pintar_historial_medico(_ficha, j, mundo, pal)
		FichaJugadorAcciones.pintar_marca(_ficha, j, mio, mundo, pal, func() -> void:
			var problema := mundo.cantera.ofrecer_fidelidad(j, mio)
			if problema != "":
				_escribir("[color=#e05555]%s[/color]" % problema)
			_refrescar()
			_ver_ficha(j))
		FichaJugadorAcciones.pintar_charla(_ficha, j, mundo, pal)
		FichaJugadorInfo.pintar_vida_personal(_ficha, j, mundo, pal)
		FichaJugadorInfo.pintar_historial(_ficha, j, pal)
		FichaJugadorAcciones.pintar_venta(_ficha, j, mio, mundo, pal, _confirmar_rescision_id,
			func() -> void:
				j.transferible = false
				_escribir("[color=#8ea595]%s ya no está en la lista de transferibles.[/color]" % j.nombre)
				_refrescar()
				_ver_ficha(j),
			func() -> void: _listar_transferible(j),
			func() -> void: _rescindir(j, int((mundo.cantera.coste_rescision(j) as Dictionary)["total"])))
		return
	## SEGUIR A UN OBJETIVO. Va aquí arriba, junto a comparar, porque son la
	## misma clase de gesto: apuntar a alguien para volver a él más tarde.
	if mundo.ojeadores != null:
		var sigo := mundo.ojeadores.sigue(j)
		var bs := Button.new()
		bs.text = "👁️ Dejar de seguir" if sigo else "👁️ Seguir"
		bs.pressed.connect(func() -> void:
			mundo.ojeadores.alternar_seguimiento(j)
			_refrescar()
			_ver_ficha(j))
		_ficha.add_child(bs)
	var pal_ajeno := _paleta_ficha()
	FichaJugadorInfo.pintar_estadisticas(_ficha, j, pal_ajeno)
	FichaJugadorInfo.pintar_habilidades(_ficha, j, mundo, pal_ajeno)
	FichaJugadorAcciones.pintar_similares(_ficha, j, mio, mundo, pal_ajeno,
		func(quien: Jugador) -> void: _ver_ficha(quien))

	## Las tres puertas del fichaje.
	_ficha.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "PARA FICHARLO"
	_ficha.add_child(t)
	var pedido := mundo.mercado.valor_pedido(j)
	var d: Dictionary = mundo.mercado.deseo_de_venir(j, mio)
	var ficha_pide := mundo.mercado.ficha_que_pide(j, mio)
	_dato("Piden por él", _dinero(pedido), COL_TEXTO if pedido <= mio.saldo else COL_ROJO)
	_dato("Pide de ficha", _dinero(ficha_pide) + " / semana", COL_TEXTO)
	_dato("Ganas de venir", "%d%%" % int(float(d["p"]) * 100.0),
		COL_VERDE if float(d["p"]) > 0.6 else (COL_ORO if float(d["p"]) > 0.35 else COL_ROJO))
	for r: Dictionary in d["razones"]:
		var l := _texto(11, COL_VERDE if r["bien"] else COL_ROJO)
		l.text = ("+ " if r["bien"] else "− ") + String(r["txt"])
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_ficha.add_child(l)

	## Si el rol no deja fichar -ayudante, cantera- o un desafío activo lo
	## prohíbe -"solo canteranos", "un solo país" con un extranjero-, ni la
	## mesa de negociación ni el clausulazo son tuyos: son las dos puertas de
	## la MISMA decisión, y dejar una abierta habría sido un permiso a medias.
	var motivo_no := _motivo_fichaje_bloqueado(j)
	if motivo_no == "":
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_ficha.add_child(fila)
		_boton("Ofrecer lo que piden", func() -> void: _intentar_fichar(j, pedido, ficha_pide), fila)
		_boton("Ofrecer un 15% menos", func() -> void: _intentar_fichar(j, int(pedido * 0.85), ficha_pide), fila)
		_boton("Negociar en la mesa", func() -> void: _abrir_negociacion(j), fila)
	else:
		var no := _texto(11, COL_SUAVE)
		no.text = motivo_no
		no.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_ficha.add_child(no)

	## El clausulazo: la puerta de atrás. Ni mesa ni negociación -si tiene
	## cláusula y hay caja, se paga y es tuyo, gane o pierda el club vendedor.
	if mundo.cesiones != null and motivo_no == "":
		var clau := mundo.cesiones.clausula_de(j)
		if clau > 0:
			var coste := mundo.cesiones.coste_de_clausula(j)
			_ficha.add_child(HSeparator.new())
			var tc := _texto(11, COL_ORO)
			tc.text = "TIENE CLÁUSULA DE RESCISIÓN"
			_ficha.add_child(tc)
			_dato("Cláusula", _dinero(clau), COL_TEXTO)
			_dato("Comisión del agente", _dinero(int(coste["comision"])), COL_SUAVE)
			var total := int(coste["total"])
			var bc := Button.new()
			bc.text = "Pagar la cláusula  %s" % _dinero(total)
			bc.disabled = total > mio.saldo
			bc.pressed.connect(func() -> void: _pagar_clausula(j))
			_ficha.add_child(bc)

	## El informe médico: `Medico.informe()` estaba completo -riesgo, lesiones
	## graves, hasta el precio escalado al valor del jugador- pero sin ningún
	## botón que lo llamara en ningún sitio del juego.
	if mundo.medico != null:
		var ya_tiene := not (mundo.medico.informe_de(j) as Dictionary).is_empty()
		_ficha.add_child(HSeparator.new())
		if ya_tiene:
			var inf: Dictionary = mundo.medico.informe_de(j)
			var tm := _texto(11, COL_SUAVE)
			tm.text = "INFORME MÉDICO"
			_ficha.add_child(tm)
			_dato("Riesgo declarado", String(inf.get("riesgo", "?")), COL_TEXTO)
			_dato("Lesiones graves en su historial", str(int(inf.get("graves", 0))), COL_TEXTO)
		else:
			var costo := mundo.medico.costo_informe(j, mio.rep)
			var bm := Button.new()
			bm.text = "Pedir informe médico  %s" % _dinero(costo)
			bm.disabled = costo > mio.saldo
			bm.pressed.connect(func() -> void: _pedir_informe_medico(j))
			_ficha.add_child(bm)

	## El informe de personalidad -informePersonal() del HTML-: a diferencia
	## del médico, este cuenta cómo es FUERA de la cancha -profesionalidad,
	## cómo encaja en un vestuario, qué tan fácil es convencerlo de mudarse-.
	if mundo.ojeadores != null:
		var ya_pers := not mundo.ojeadores.informe_personalidad_de(j).is_empty()
		_ficha.add_child(HSeparator.new())
		if ya_pers:
			var infp: Dictionary = mundo.ojeadores.informe_personalidad_de(j)
			var tp := _texto(11, COL_SUAVE)
			tp.text = "INFORME DE PERSONALIDAD"
			_ficha.add_child(tp)
			_dato("Profesionalidad", "%d/100" % int(infp.get("prof", 0)), COL_TEXTO)
			_dato("En el vestuario", String(infp.get("vestuario", "?")), COL_TEXTO)
			_dato("Mudarse de país", String(infp.get("mudanza", "?")), COL_TEXTO)
		else:
			var costo_p := mundo.ojeadores.costo_informe_personalidad(mio.rep)
			var bp := Button.new()
			bp.text = "Pedir informe de personalidad  %s" % _dinero(costo_p)
			bp.disabled = costo_p > mio.saldo
			bp.pressed.connect(func() -> void:
				var problema := mundo.ojeadores.informe_personalidad(j, mio)
				if problema != "":
					_escribir("[color=#e05555]%s[/color]" % problema)
				_refrescar()
				_ver_ficha(j))
			_ficha.add_child(bp)

	## `HISTORIA` del HTML: la biografía se enseña siempre, sea o no tuyo -a
	## diferencia de `perfilHumano()`, que es cosa del vestuario propio y solo
	## se ve en `_pintar_vida_personal_ficha()`.
	_ficha.add_child(HSeparator.new())
	var bio_ajeno := _texto(11, COL_SUAVE)
	bio_ajeno.text = FichaJugadorInfo.bio_de(j, mundo)
	bio_ajeno.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ficha.add_child(bio_ajeno)




func _reconvertir(j: Jugador, pe: String) -> void:
	var posd: Dictionary = (Datos.tabla("POSD") as Dictionary).get(pe, {})
	var r := j.reconvertir(pe)
	if r.is_empty():
		return
	_apuntar_deshacer("reconvertir a %s de %s" % [j.nombre, pe])
	var d := int(r["despues"]) - int(r["antes"])
	_escribir("[color=#c9a227]🔁 Reconversión:[/color] %s pasa a jugar de %s. Su media queda en %d (%s%d). Necesita %d semana(s) para asentarse en el puesto." % [
		j.nombre, String(posd.get("n", pe)).to_lower(), r["despues"], "+" if d >= 0 else "", d, int(r["semanas"])])
	_refrescar()
	_ver_ficha(j)


func _pedir_informe_medico(j: Jugador) -> void:
	var mio := mundo.mi_club()
	var problema := mundo.medico.informe(j, mio, mundo.anio)
	if problema != "":
		_escribir("[color=#e05555]No se pudo pedir el informe: %s.[/color]" % problema)
		return
	_refrescar()
	_ver_ficha(j)

func _pedir_informe_ojeo(j: Jugador) -> void:
	var problema := mundo.ojeadores.ojear(j)
	if problema != "":
		_escribir("[color=#e05555]No se pudo pedir el informe: %s.[/color]" % problema)
		return
	_escribir("[color=#c9a227]Informe recibido:[/color] %s revela su media y su potencial reales." % j.nombre)
	_refrescar()
	_ver_ficha(j)



func _listar_transferible(j: Jugador) -> void:
	mundo.mercado.listar_transferible(j)
	_escribir("[color=#c9a227]En venta:[/color] %s queda listado como transferible. Se lo tomó mal, pero a partir de ahora van a llegar ofertas por él." % j.nombre)
	_refrescar()

## Doble toque: la primera pulsación solo arma la confirmación y repinta el
## botón con la advertencia -"vista.confResc" del HTML-. La segunda, con el
## mismo jugador todavía armado, ejecuta de verdad.
func _rescindir(j: Jugador, total: int) -> void:
	if _confirmar_rescision_id != j.id:
		_confirmar_rescision_id = j.id
		_ver_ficha(j)
		return
	_confirmar_rescision_id = ""
	var mio := mundo.mi_club()
	if mio == null or total > mio.saldo:
		return
	_apuntar_deshacer("rescindir a %s" % j.nombre)
	## Y queda apuntado que fue tuyo: si lo ficha un rival, el dia que se crucen
	## juega con la cuenta pendiente encima.
	Partido.marcar_ex(j, mio.id)
	## El golpe de moral a la plantilla, con más peso si era capitán -HTML añade
	## también "ídolo" (`j.idolo>=62`), que Godot no tiene portado todavía; el
	## capitanazgo solo es una aproximación honesta, no el mismo cálculo-. Se
	## mide ANTES de soltarlo: una vez fuera del club ya no es capitán de nadie.
	var pesado := j.capitan
	mio.mover_saldo(-total)
	mio.soltar(j)
	j.club_id = ""
	j.transferible = false
	j.capitan = false
	var golpe := Azar.ent(7, 13) if pesado else Azar.ent(1, 4)
	var clan: Dictionary = mundo.vestuario.clan_de(j) if mundo.vestuario != null else {}
	var miembros: Array = clan.get("miembros", [])
	for x in mio.plantilla:
		var cerca: bool = miembros.has(x.id)
		x.moral = clampi(x.moral - golpe * (2 if cerca else 1), 10, 99)
	if not clan.is_empty():
		clan["humor"] = clampi(int(clan.get("humor", 0)) - Azar.ent(10, 25), -100, 100)
	## El agente no olvida quién le rompió un contrato: la misma confianza que
	## `Cantera` ya consulta al ofertar por cualquiera de sus representados.
	if mundo.cantera != null:
		var nombre_agente := String(mundo.cantera.agente_de(j).get("nombre", ""))
		if nombre_agente != "":
			mundo.cantera.confianza_agentes[nombre_agente] = mundo.cantera.confianza_de(nombre_agente) - 2
	if mundo.prensa != null:
		mundo.prensa.animo = clampi(mundo.prensa.animo - (Azar.ent(8, 16) if pesado else Azar.ent(1, 4)), 0, 100)
		if pesado:
			mundo.prensa.funa = clampi(mundo.prensa.funa + Azar.ent(10, 20), 0, 100)
	_escribir("[color=#e05555][b]Rescindido:[/b][/color] %s deja el club. Finiquito y comisión: %s." % [j.nombre, _dinero(total)])
	_seleccionado = null
	_refrescar()

## `padre` por defecto es `_ficha` -de ahí salió esta función, para la ficha
## del jugador-, pero cualquier otra pestaña con la misma "etiqueta … valor"
## puede pasar la suya. Pasarlo mal es un bug silencioso: sin error, la fila
## sale dibujada en el sitio equivocado y desaparece en el próximo repintado.
## Una fila "etiqueta ......... valor".
##
## La etiqueta se RECORTA si no cabe, y esa línea no es cosmética: sin ella un
## Label pide de ancho mínimo lo que mida su texto, ese mínimo sube por el
## HBoxContainer de columnas, y la tercera columna se sale de la ventana entera
## -el contrato y el sueldo del jugador salían cortados por el borde derecho-.
## El valor NO se recorta a propósito: es el dato, y un dato a medias engaña
## más que un dato que no cabe.
func _dato(etiqueta: String, valor: String, color: Color, padre: Node = null) -> void:
	var h := HBoxContainer.new()
	var a := _texto(12, COL_SUAVE)
	a.text = etiqueta
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	a.clip_text = true
	a.tooltip_text = etiqueta
	h.add_child(a)
	var b := _texto(12, color)
	b.text = valor
	h.add_child(b)
	(padre if padre != null else _ficha).add_child(h)

## "" si se puede fichar/ceder a `j`, o el motivo exacto por el que no -el rol
## primero (ver `Roles.motivo_bloqueo`), y si el rol deja, los desafíos
## activos: "cantera" lo cierra del todo, "local" solo si `j` es extranjero.
## Un solo sitio para las tres puertas -ficha, clausulazo, ceder- que antes
## repetían la misma condición cada una a su manera.
func _motivo_fichaje_bloqueado(j: Jugador) -> String:
	## LA VENTANA DE MERCADO, la primera puerta de todas. Va aqui porque este es
	## el unico punto por el que pasan la ficha, el clausulazo y las cesiones: si
	## se comprobara en cada pantalla, tarde o temprano una se quedaria sin
	## comprobar y se ficharia en marzo.
	## EL EXPEDIENTE DE FAIR PLAY cierra el mercado de PAGO, no el mercado
	## entero: se puede seguir fichando libres, que es exactamente lo que hace un
	## club sancionado de verdad.
	if mundo.federacion != null and not mundo.federacion.puede_pagar_traspaso() and j != null and j.club_id != "":
		return "Sancionado por fair play financiero: esta ventana solo puedes fichar agentes libres."
	## EN MORA CON EL BANCO. `Banco.estado()` ya prometía "Fichajes inhibidos"
	## a partir de la cuarta semana en rojo, y nada lo hacía cumplir: se podía
	## fichar con normalidad con un veedor concursal encima. Misma frontera
	## que el fair play de arriba -bloquea el mercado de PAGO, no los libres-.
	if mundo.banco != null and mundo.banco.en_mora() and j != null and j.club_id != "":
		return "En mora con el banco (%d semanas en rojo): esta ventana solo puedes fichar agentes libres." % mundo.banco.semanas_en_rojo
	if not mundo.mercado_abierto():
		return "Mercado cerrado. Vuelve a abrir en %d semanas: hasta entonces, la plantilla es la que hay." % mundo.semanas_hasta_mercado()
	if mundo.roles != null and not mundo.roles.puede_fichar():
		return String(mundo.roles.motivo_bloqueo("fichar"))
	if mundo.tiene_desafio("cantera"):
		return "Desafío «solo canteranos»: el mercado te queda vetado. Todo refuerzo tiene que salir de tu academia."
	if mundo.tiene_desafio("local") and j != null and j.pais != mundo.mi_club().pais:
		return "Desafío «un solo país»: no puedes fichar extranjeros."
	return ""

## El intento de fichaje pasa por las tres puertas en orden y cuenta cuál se
## cerró. Decir solo "no se pudo" sería inútil: lo que hace que la siguiente
## oferta sea mejor es saber si falló el precio, la ficha o las ganas.
func _intentar_fichar(j: Jugador, monto: int, sueldo: int) -> void:
	var mio := mundo.mi_club()
	if monto > mio.saldo:
		_escribir("[color=#e05555]No hay caja: piden %s y tienes %s.[/color]" % [_dinero(monto), _dinero(mio.saldo)])
		return
	if not mundo.mercado.club_acepta(j, monto):
		_escribir("[color=#e05555]%s rechaza los %s por %s.[/color]" % [
			mundo.clubes[j.club_id].nombre, _dinero(monto), j.nombre])
		return
	if not mundo.mercado.jugador_firma(j, mio, sueldo):
		_escribir("[color=#c9a227]%s no firma: el club aceptó, pero él no se ve aquí.[/color]" % j.nombre)
		return
	mundo.mercado.fichar(j, mio, monto, sueldo, 3)
	Sonido.toca("fichaje")
	_escribir("[color=#4caf6d]FICHADO: %s por %s (%s/semana).[/color]" % [
		j.nombre, _dinero(monto), _dinero(sueldo)])
	_refrescar()

func _pagar_clausula(j: Jugador) -> void:
	var r := mundo.cesiones.pagar_clausula(j, mundo.mi_club())
	if r.has("error"):
		_escribir("[color=#e05555]No se puede: %s.[/color]" % String(r["error"]))
		return
	Sonido.toca("fichaje")
	_escribir("[color=#4caf6d]¡Clausulazo![/color] %s es tuyo por %s más %s de comisión." % [
		j.nombre, _dinero(int(r["clausula"])), _dinero(int(r["comision"]))])
	_refrescar()

func _dinero(n: int) -> String:
	return Eco.dinero(n)

## Los colores que recibe `PanelClubDentro`: los mismos `COL_*` de siempre,
## sin traducir -los traduce `_texto()`, que es quien pinta-.
func _paleta_club_dentro() -> Dictionary:
	return {"suave": COL_SUAVE, "acento": COL_ACENTO, "verde": COL_VERDE, "texto": COL_TEXTO,
		"oro": COL_ORO, "rojo": COL_ROJO}

func _miles(n: int) -> String:
	var s := str(n)
	var salida := ""
	var cuenta := 0
	for i in range(s.length() - 1, -1, -1):
		salida = s[i] + salida
		cuenta += 1
		if cuenta % 3 == 0 and i > 0:
			salida = "." + salida
	return salida

## La pestaña del club: lo que te exige la directiva y el cuerpo técnico que
## puedes contratar. Es la pantalla donde se gasta el dinero que no va a fichajes.
## LA PESTAÑA "CLUB", PARTIDA EN SECCIONES (10-9-2026). Tenía doce bloques
## seguidos en un solo scroll -directiva, cuerpo técnico, ojeadores, analítica,
## academias, obras, equipación, cargo, carrera-, que es justo lo que el
## usuario pidió romper ("deben existir más submenús"). Cada sección es ahora
## un chip del menú de nivel 2; el dispatch vive en `_pintar_club()`.
var _secc_club: String = "directorio"

func _pintar_club(c: Club) -> void:
	_limpiar(_lista_club)
	match _secc_club:
		"directorio": _club_directorio(c)
		"staff": _club_staff(c)
		"infra": _club_infra(c)
		"carrera": _club_carrera(c)
		_: _club_directorio(c)

## EL DIRECTORIO: quién te puso ahí, qué te pide y cuánto te aguanta.
func _club_directorio(c: Club) -> void:
	var d := mundo.directiva
	if d != null:
		var t := _texto(11, COL_SUAVE); t.text = "LA DIRECTIVA"
		_lista_club.add_child(t)
		var obj := _texto(15, COL_ORO); obj.text = d.objetivo
		obj.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_club.add_child(obj)
		var meta := _texto(12, COL_SUAVE)
		meta.text = "Te piden acabar %s.º o mejor." % d.meta_puesto
		_lista_club.add_child(meta)

		## La confianza en barra, no en número: "34" no le dice nada a nadie, y
		## "tu puesto está en el aire" sí.
		var barra := ProgressBar.new()
		barra.min_value = 0
		barra.max_value = 100
		barra.value = d.confianza
		barra.custom_minimum_size = Vector2(0, 18)
		barra.show_percentage = false
		_lista_club.add_child(barra)
		var humor := _texto(13, COL_VERDE if d.confianza >= 45 else (COL_ORO if d.confianza > Directiva.UMBRAL_DESPIDO else COL_ROJO))
		humor.text = "%s  (%d de 100)" % [d.humor(), d.confianza]
		humor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_club.add_child(humor)
		if not d.trofeos.is_empty():
			var tr := _texto(12, COL_ORO)
			tr.text = "Vitrina: " + ", ".join(d.trofeos)
			_lista_club.add_child(tr)
		_lista_club.add_child(HSeparator.new())
		_pintar_consejeros(d, c)
		_pintar_embajador(d)

## EL PERSONAL CONTRATADO: cuerpo técnico, red de ojeadores, analítica y
## academias. Todo lo que se paga en nómina y no juega.
func _club_staff(c: Club) -> void:
	var t2 := _texto(11, COL_SUAVE)
	t2.text = "CUERPO TÉCNICO  ·  nómina %s/semana" % _dinero(mundo.staff.sueldo_semanal(c.rep))
	_lista_club.add_child(t2)
	## C9: la jornada legal del personal del país, con su norma.
	var jl := _texto(11, COL_SUAVE)
	var fe := Contratos.factor_estructura(c.pais, mundo.anio, mundo.semana)
	jl.text = "⚖️ Jornada legal del personal: %s%s" % [Contratos.texto_jornada(c.pais, mundo.anio, mundo.semana),
		"" if is_equal_approx(fe, 1.0) else "  (la estructura cuesta un %+d%%)" % int(round((fe - 1.0) * 100.0))]
	jl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_club.add_child(jl)
	## El bono de productividad: una vez por temporada, sube la moral de TODO el
	## plantel, y sube más cuanto mejor vayas. Premiar a la gente yendo primero
	## es una fiesta; hacerlo yendo último se agradece y poco más.
	if mundo.staff.escalones_contratados() > 0:
		var fila_bono := HBoxContainer.new()
		fila_bono.add_theme_constant_override("separation", 8)
		_lista_club.add_child(fila_bono)
		var ya := mundo.staff.anio_bono == mundo.anio
		var lb := _texto(12, COL_SUAVE)
		lb.text = "Bono de productividad" if not ya else "Bono de productividad  ·  ya repartido este año"
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila_bono.add_child(lb)
		var coste_bono := mundo.staff.coste_bono(c.rep)
		var bb := Button.new()
		bb.text = "Repartir  %s" % _dinero(coste_bono)
		bb.add_theme_font_size_override("font_size", 11)
		bb.disabled = ya or coste_bono > c.saldo
		bb.pressed.connect(func() -> void: _bono_staff(c))
		fila_bono.add_child(bb)
	for puesto: String in Staff.PUESTOS:
		var datos: Array = Staff.PUESTOS[puesto]
		var n := mundo.staff.nivel(puesto)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		_lista_club.add_child(fila)
		var nom := _texto(12, COL_TEXTO)
		## Las estrellas se leen de un vistazo; "nivel 3 de 5" hay que pararse a
		## leerlo.
		nom.text = "%s  %s" % ["★".repeat(n) + "·".repeat(Staff.NIVEL_MAX - n), datos[0]]
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(nom)
		if n >= Staff.NIVEL_MAX:
			var tope := _texto(11, COL_VERDE); tope.text = "al máximo"
			fila.add_child(tope)
		else:
			var coste := mundo.staff.coste_subir(puesto, c.rep)
			var b := Button.new()
			b.text = "Contratar  %s" % _dinero(coste)
			b.add_theme_font_size_override("font_size", 11)
			b.disabled = coste > c.saldo or (mundo.roles != null and not mundo.roles.puede_contratar_staff())
			b.pressed.connect(func() -> void: _contratar(puesto))
			fila.add_child(b)
		var que := _texto(11, COL_SUAVE)
		que.text = "    " + String(datos[1])
		que.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_club.add_child(que)
	_pintar_ojeadores(c)
	_pintar_analitica(c)
	_pintar_academias(c)

## LA INFRAESTRUCTURA: las obras del club y la equipación que se ve en el
## campo. Lo que se construye, no lo que se contrata.
func _club_infra(c: Club) -> void:
	_pintar_obras(c)
	_pintar_equipacion(c)

## MI CARRERA: qué eres en este club, qué te dejan tocar y qué llevas hecho.
## `_pintar_rol()` ya llama a `_pintar_carrera(r)` por dentro: aquí no se
## vuelve a llamar o saldría dos veces.
func _club_carrera(_c: Club) -> void:
	_pintar_rol()

## `contratarConsejero(k)` del HTML: hasta dos asesores del directorio a la
## vez, con un costo de entrada y un honorario semanal.
func _pintar_consejeros(d: Directiva, _c: Club) -> void:
	var t := _texto(11, COL_SUAVE)
	t.text = "CONSEJEROS DEL DIRECTORIO  ·  %d de %d  ·  %s/semana en honorarios" % [
		d.consejeros.size(), Directiva.MAX_CONSEJEROS, _dinero(d.honorarios_semanales())]
	_lista_club.add_child(t)
	for k: String in Directiva.CONSEJEROS:
		var info: Dictionary = Directiva.CONSEJEROS[k]
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		_lista_club.add_child(fila)
		var contratado := d.tiene_consejero(k)
		var nom := _texto(12, COL_VERDE if contratado else COL_TEXTO)
		if contratado:
			var o: Dictionary = d.consejeros[k]
			nom.text = "%s  ·  %s (%d años)" % [String(info["nombre"]), String(o["nombre"]), int(o["edad"])]
		else:
			nom.text = String(info["nombre"])
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(nom)
		var b := Button.new()
		b.add_theme_font_size_override("font_size", 11)
		if contratado:
			b.text = "Cesar"
		else:
			b.text = "Contratar  %s" % _dinero(Directiva.COSTO_CONTRATAR_CONSEJERO)
			b.disabled = d.consejeros.size() >= Directiva.MAX_CONSEJEROS or _c.saldo < Directiva.COSTO_CONTRATAR_CONSEJERO
		b.pressed.connect(func() -> void: _alternar_consejero(k))
		fila.add_child(b)
		var desc := _texto(11, COL_SUAVE)
		desc.text = "    " + String(info["desc"])
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_club.add_child(desc)
	_lista_club.add_child(HSeparator.new())

func _alternar_consejero(k: String) -> void:
	var problema := mundo.directiva.alternar_consejero(k)
	if problema != "":
		_escribir("[color=#e05555]%s[/color]" % problema)
		return
	_refrescar()

## "EMBAJADOR DEL CLUB" de `vDirectorio()`: una leyenda retirada -de cualquier
## club- que puedes fichar como ídolo institucional. `Directiva.embajador`
## reutiliza los mismos datos que ya guardaba `Cantera.leyendas` para el
## linaje; aquí solo hacía falta la pantalla.
func _pintar_embajador(d: Directiva) -> void:
	var t := _texto(11, COL_SUAVE); t.text = "EMBAJADOR DEL CLUB"
	_lista_club.add_child(t)
	if not d.embajador.is_empty():
		var e: Dictionary = d.embajador
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		_lista_club.add_child(fila)
		var nom := _texto(12, COL_VERDE)
		nom.text = "⭐ %s  ·  ídolo · %s · %s/semana · la hinchada suma socios" % [
			String(e.get("nombre", "")), String(e.get("pos", "")), _dinero(int(e.get("sueldo", 0)))]
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fila.add_child(nom)
		_boton("Cesar  %s" % _dinero(Directiva.FINIQUITO_EMBAJADOR), _cesar_embajador, fila)
	else:
		var cantera := mundo.cantera
		var candidatas: Array[Dictionary] = Directiva.candidatas_embajador(cantera.leyendas, mundo.anio) if cantera != null else []
		if candidatas.is_empty():
			var av := _texto(11, COL_SUAVE)
			av.text = "Sin leyendas disponibles todavía."
			_lista_club.add_child(av)
		for l: Dictionary in candidatas:
			var fila2 := HBoxContainer.new()
			fila2.add_theme_constant_override("separation", 8)
			_lista_club.add_child(fila2)
			var nom2 := _texto(12, COL_TEXTO)
			nom2.text = "⭐ %s  ·  %s · nivel %d en su época" % [
				String(l.get("nombre", "")), String(l.get("pos", "")), int(l.get("nivel", 80))]
			nom2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila2.add_child(nom2)
			var costo := 400000 + int(l.get("nivel", 80)) * 8000
			_boton("Firmar  %s" % _dinero(costo), func() -> void: _contratar_embajador(l), fila2)
	_lista_club.add_child(HSeparator.new())

func _contratar_embajador(l: Dictionary) -> void:
	var problema := mundo.directiva.contratar_embajador(l)
	if problema != "":
		_escribir("[color=#e05555]%s[/color]" % problema)
		return
	if mundo.prensa != null:
		mundo.prensa.sumar_animo(6)
	_escribir("[color=#c9a227][b]Vuelve una leyenda:[/b][/color] %s firma como embajador del club." % String(l.get("nombre", "")))
	_refrescar()

func _cesar_embajador() -> void:
	var nombre := String(mundo.directiva.embajador.get("nombre", ""))
	var problema := mundo.directiva.cesar_embajador()
	if problema != "":
		_escribir("[color=#e05555]%s[/color]" % problema)
		return
	_escribir("[color=#8ea595]Fin de una era: %s deja el rol institucional.[/color]" % nombre)
	_refrescar()

## `toggleRed()` del HTML: qué países cubre tu red de ojeadores, con nombre y
## sesgo de cada uno. Cuántos puedes cubrir a la vez sale del nivel de
## "ojeador" en el cuerpo técnico, justo arriba de esta sección.
func _pintar_ojeadores(c: Club) -> void:
	var oj := mundo.ojeadores
	if oj == null:
		return
	## LA LISTA DE SEGUIMIENTO, de `vOjeo()`. Va lo primero: es lo que se viene
	## a mirar aquí semana tras semana, por delante de la red de ojeadores, que
	## se toca una vez cada varios meses.
	var seguidos := oj.lista_seguimiento()
	if not seguidos.is_empty():
		_lista_club.add_child(HSeparator.new())
		var ts := _texto(11, COL_SUAVE)
		ts.text = "👁️ EN SEGUIMIENTO  ·  %d" % seguidos.size()
		_lista_club.add_child(ts)
		for j: Jugador in seguidos:
			var suyo: Club = mundo.clubes.get(j.club_id)
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 6)
			_lista_club.add_child(fila)
			fila.add_child(_retrato(j, 22))
			var b := Button.new()
			b.text = "%s  ·  %d años  ·  %s" % [j.nombre, j.edad, suyo.nombre if suyo else "libre"]
			b.flat = true
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.clip_text = true
			b.custom_minimum_size = Vector2(120, 0)
			b.add_theme_font_size_override("font_size", 12)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.pressed.connect(func() -> void: _ver_ficha(j))
			fila.add_child(b)
			## Lo que se sigue de alguien es si sube o si baja de precio, así
			## que la media y lo que piden por él son las dos cifras que van.
			var med := _texto(11, COL_TEXTO)
			med.text = oj.ovr_texto(j)
			med.custom_minimum_size = Vector2(56, 0)
			fila.add_child(med)
			var pide := _texto(11, COL_SUAVE)
			pide.text = _dinero(mundo.mercado.valor_pedido(j))
			pide.custom_minimum_size = Vector2(70, 0)
			fila.add_child(pide)
	_lista_club.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "RED DE OJEADORES  ·  %d de %d países  ·  presupuesto %s" % [oj.red.size(), oj.max_paises(), _dinero(oj.presupuesto)]
	_lista_club.add_child(t)
	## "MERCADO A CIEGAS": tenía el MISMO interruptor duplicado aquí y en
	## Ajustes → Accesibilidad -mismo booleano, `oj.modo_ciego`, dos pantallas
	## sin relación entre sí que nunca se enteraban una de la otra-. El usuario
	## lo marcó jugando ("evitar la duplicidad en los menús"): se toca desde UN
	## solo sitio -Ajustes, que trae además la explicación completa- y aquí
	## queda solo el estado y el atajo para llegar.
	var fila_ciego := HBoxContainer.new()
	fila_ciego.add_theme_constant_override("separation", 8)
	_lista_club.add_child(fila_ciego)
	var txt_ciego := _texto(11, COL_TEXTO)
	txt_ciego.text = "Mercado a ciegas: %s." % ("activado" if oj.modo_ciego else "desactivado")
	txt_ciego.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila_ciego.add_child(txt_ciego)
	var b_ciego := Button.new()
	b_ciego.text = "Ir a Ajustes"
	b_ciego.add_theme_font_size_override("font_size", 11)
	b_ciego.pressed.connect(func() -> void:
		_secc_ajustes = "acceso"
		_ir_a_pestana("Ajustes"))
	fila_ciego.add_child(b_ciego)
	if oj.max_paises() <= 0:
		var av := _texto(11, COL_SUAVE)
		av.text = "Contrata un jefe de ojeadores para poder cubrir países."
		_lista_club.add_child(av)
	for pais: String in oj.ojeadores:
		var o: Dictionary = oj.ojeadores[pais]
		var s: Dictionary = Ojeadores.SESGOS.get(o["sesgo"], Ojeadores.SESGOS["fiel"])
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		_lista_club.add_child(fila)
		var nom := _texto(12, COL_TEXTO)
		nom.text = "%s  ·  %s  ·  %s  ·  precisión %d/3  ·  humor %d" % [
			String(o["nombre"]), pais, String(s["nombre"]), int(o["precision"]), int(o["humor"])]
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fila.add_child(nom)
		_boton("Retirar", func() -> void: _alternar_pais_ojeo(pais), fila)
	var paises: Array[String] = []
	for l: Liga in mundo.ligas:
		if not paises.has(l.pais) and not oj.ojeadores.has(l.pais):
			paises.append(l.pais)
	paises.sort()
	if not paises.is_empty():
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 6)
		flow.add_theme_constant_override("v_separation", 6)
		_lista_club.add_child(flow)
		for pais2: String in paises:
			var bp := Button.new()
			bp.text = pais2
			bp.add_theme_font_size_override("font_size", 11)
			bp.custom_minimum_size = Vector2(52, 28)
			bp.disabled = oj.red.size() >= oj.max_paises()
			bp.pressed.connect(func() -> void: _alternar_pais_ojeo(pais2))
			flow.add_child(bp)

## `vOjeo()`: EL DEPARTAMENTO DE ANÁLISIS DE DATOS.
##
## La otra forma de encontrar futbolistas. El ojeo dice lo BUENO que es alguien;
## el modelo dice lo INFRAVALORADO que está, que no es la misma pregunta. Y a
## partir del nivel dos, con un jefe de ojeadores de la vieja escuela en casa, la
## tensión sube sola: esto no es una mejora, es tomar partido.
func _pintar_analitica(c: Club) -> void:
	var oj := mundo.ojeadores
	if oj == null:
		return
	_lista_club.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "📊 DEPARTAMENTO DE ANÁLISIS DE DATOS"
	_lista_club.add_child(t)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	_lista_club.add_child(fila)
	var l := _texto(12, COL_TEXTO)
	l.text = "Modelo propio  ·  nivel %d de %d" % [oj.analitica_nivel, Ojeadores.ANALITICA_MAX]
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.tooltip_text = "Cruza minutos, duelos y distancia recorrida para encontrar lo que el ojo no ve."
	fila.add_child(l)
	var b := Button.new()
	var tope := oj.analitica_nivel >= Ojeadores.ANALITICA_MAX
	b.text = "AL MÁXIMO" if tope else "Ampliar · %s" % _dinero(oj.coste_analitica(c))
	b.add_theme_font_size_override("font_size", 11)
	b.disabled = tope or c.saldo < oj.coste_analitica(c)
	b.clip_text = true
	b.custom_minimum_size = Vector2(140, 0)
	b.pressed.connect(func() -> void: _mejorar_analitica(c))
	fila.add_child(b)

	if oj.analitica_nivel >= 1 and mundo.staff != null and mundo.staff.nivel("ojo") >= 2:
		_dato("Tensión con el ojeo tradicional", "%d%%" % oj.analitica_tension,
			COL_ROJO if oj.analitica_tension >= Ojeadores.TENSION_CRITICA else COL_ORO, _lista_club)

	var vivos := oj.hallazgos_vivos()
	if vivos.is_empty():
		if not _modo_experto:
			var vac := _texto(10, COL_SUAVE)
			vac.text = "El modelo todavía no ha señalado a nadie. Necesita al menos un nivel y unas semanas de datos."
			vac.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_lista_club.add_child(vac)
	else:
		var th := _texto(10, COL_SUAVE)
		th.text = "Últimos hallazgos del modelo:"
		_lista_club.add_child(th)
		for h: Dictionary in vivos:
			var j: Jugador = h["jugador"]
			var suyo: Club = mundo.clubes.get(j.club_id)
			var fh := HBoxContainer.new()
			fh.add_theme_constant_override("separation", 6)
			_lista_club.add_child(fh)
			var bj := Button.new()
			bj.text = "%s  ·  %s, %d años" % [j.nombre, suyo.nombre if suyo else "libre", j.edad]
			bj.flat = true
			bj.alignment = HORIZONTAL_ALIGNMENT_LEFT
			bj.add_theme_font_size_override("font_size", 12)
			bj.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bj.clip_text = true
			bj.pressed.connect(func() -> void: _ver_ficha(j))
			fh.add_child(bj)
			var mj := _texto(11, COL_ORO)
			mj.text = oj.ovr_texto(j)
			mj.custom_minimum_size = Vector2(60, 0)
			fh.add_child(mj)

## LAS ACADEMIAS INTERNACIONALES. La apuesta más larga del juego: la sede que
## abres hoy da su primer futbolista el año que viene. Cuesta de construir y
## cuesta todas las semanas, y a cambio cada pretemporada llega una joya local.
func _pintar_academias(c: Club) -> void:
	var oj := mundo.ojeadores
	if oj == null:
		return
	_lista_club.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "🏫 ACADEMIAS INTERNACIONALES  ·  %d de %d" % [oj.academias.size(), Ojeadores.ACADEMIAS_MAX]
	_lista_club.add_child(t)
	if not _modo_experto:
		var ex := _texto(10, COL_SUAVE)
		ex.text = "Construir cuesta %s y mantenerla %s a la semana por sede. Cada pretemporada llega una joya local con proyección alta, directa a tu plantel." % [
			_dinero(Eco.escalar(Ojeadores.COSTE_ACADEMIA, float(c.rep))),
			_dinero(Eco.escalar(Ojeadores.MANTENCION_ACADEMIA, float(c.rep)))]
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_club.add_child(ex)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	_lista_club.add_child(flow)
	var paises: Array[String] = []
	for l: Liga in mundo.ligas:
		if l.pais != c.pais and not paises.has(l.pais):
			paises.append(l.pais)
	for p: String in paises:
		var pais := p
		var tengo := oj.tiene_academia(pais)
		var bp := Button.new()
		bp.text = ("🏫 " if tengo else "") + pais
		bp.add_theme_font_size_override("font_size", 11)
		bp.toggle_mode = true
		bp.button_pressed = tengo
		bp.custom_minimum_size = Vector2(64, 28)
		bp.disabled = not tengo and oj.academias.size() >= Ojeadores.ACADEMIAS_MAX
		bp.pressed.connect(func() -> void: _alternar_academia(pais, c))
		flow.add_child(bp)
	if not oj.academias.is_empty():
		_dato("Mantención semanal", _dinero(oj.mantencion_academias(c)), COL_ROJO, _lista_club)

func _mejorar_analitica(c: Club) -> void:
	var problema := mundo.ojeadores.mejorar_analitica(c)
	if problema != "":
		_escribir("[color=#e05555]No se puede ampliar: %s.[/color]" % problema)
	_refrescar()

func _alternar_academia(pais: String, c: Club) -> void:
	var problema := mundo.ojeadores.alternar_academia(pais, c)
	if problema != "":
		_escribir("[color=#e05555]No se puede: %s.[/color]" % problema)
	_refrescar()

func _alternar_pais_ojeo(pais: String) -> void:
	var problema := mundo.ojeadores.alternar_pais(pais)
	if problema != "":
		_escribir("[color=#e05555]%s.[/color]" % problema)
		return
	_refrescar()

func _contratar(puesto: String) -> void:
	var problema := mundo.staff.subir(puesto, mundo.mi_club())
	if problema != "":
		_escribir("[color=#e05555]No se puede contratar: %s.[/color]" % problema)
		return
	var datos: Array = Staff.PUESTOS[puesto]
	_escribir("[color=#4caf6d]Contratado: %s, nivel %d.[/color] %s." % [
		datos[0], mundo.staff.nivel(puesto), datos[1]])
	_refrescar()

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

func _pintar_despacho() -> void:
	_limpiar(_despacho)
	if mundo.roles != null and mundo.roles.sin_club:
		_pintar_sin_banco()
		return
	## LA RUEDA DE PRENSA YA NO ES UN "ASUNTO" MÁS DE LA LISTA -el usuario lo
	## pidió explícitamente: "eso debería tener su propio lugar", comparándolo
	## con la conferencia de prensa de FC26, que ocupa la pantalla entera-.
	## Antes vivía encogida dentro de esta tarjeta compartiendo espacio con la
	## barra superior y la tabla de posiciones; ahora se abre como cinemática
	## de pantalla completa, mismo patrón que `Sorteo` (`_siguiente_sorteo()`
	## más arriba): un `Control` de pantalla completa colgado directo de
	## `self`, por encima de todo, y nada más se dibuja mientras está abierta.
	if mundo.prensa != null and mundo.prensa.hay_rueda() and _rueda_pop == null:
		_abrir_rueda_pantalla_completa(mundo.prensa.entrevista)
	var asuntos: Array = []
	if mundo.cantera != null and mundo.cantera.hay_exigencia():
		asuntos.append({"et": "🦈 Un representante presiona", "col": COL_VERDE, "id": "agente"})
	if mundo.prensa != null and mundo.prensa.hay_evento():
		asuntos.append({"et": "📌 Hay que decidir", "col": COL_ORO, "id": "decision"})
	if mundo.vestuario != null and not mundo.vestuario.solicitud.is_empty():
		asuntos.append({"et": "🗣️ Te busca un jugador", "col": COL_VERDE, "id": "solicitud"})
	if mundo.junta != null and not mundo.junta.pendiente.is_empty():
		asuntos.append({"et": "🏛️ Junta de accionistas", "col": COL_ORO, "id": "junta"})
	if mundo.eventos_cantera != null and not mundo.eventos_cantera.pendiente.is_empty():
		asuntos.append({"et": "🌱 Asunto de la academia", "col": COL_VERDE, "id": "cantera"})
	if mundo.trabajadores != null and not mundo.trabajadores.pendiente.is_empty():
		asuntos.append({"et": "🏢 Asunto del personal", "col": COL_ORO, "id": "personal"})
	if mundo.vida != null and not mundo.vida.pendiente.is_empty():
		asuntos.append({"et": "🏠 Pasa en casa", "col": COL_ORO, "id": "vida"})
	if asuntos.is_empty():
		return
	_aviso_abierto = clampi(_aviso_abierto, 0, asuntos.size() - 1)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	_despacho.add_child(fila)
	var cab := _texto(11, COL_SUAVE)
	cab.text = "🔔 %d asunto%s" % [asuntos.size(), "" if asuntos.size() == 1 else "s"]
	fila.add_child(cab)
	for i in asuntos.size():
		var a: Dictionary = asuntos[i]
		var b := _pildora(String(a["et"]), 11, 26)
		b.button_pressed = (i == _aviso_abierto)
		var idx := i
		b.pressed.connect(func() -> void:
			_aviso_abierto = idx
			_pintar_despacho())
		fila.add_child(b)

	match String((asuntos[_aviso_abierto] as Dictionary)["id"]):
		"agente": _pintar_exigencia_agente(mundo.cantera.exigencia)
		"decision": _pintar_decision(mundo.prensa.pendiente)
		"solicitud": _pintar_solicitud_plantel()
		"junta": _pintar_junta()
		"cantera": _pintar_asunto_cantera()
		"personal": _pintar_asunto_personal()
		"vida": _pintar_asunto_vida()

## MI VIDA: lo que pasa en casa, con sus dos salidas.
func _pintar_asunto_vida() -> void:
	var p := mundo.vida.pendiente
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", Tema.caja(Tema.TARJETA, Tema.RADIO, Tema.ORO))
	_despacho.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	caja.add_child(v)
	v.add_child(Tema.rotulo("Mi vida"))
	var t := Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, String(p["texto"]))
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	v.add_child(fila)
	for op: String in ["a", "b"]:
		var b := Button.new()
		b.text = String(p[op])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		b.pressed.connect(_resolver_vida.bind(op))
		fila.add_child(b)

func _resolver_vida(op: String) -> void:
	var r := mundo.vida.resolver(op, mundo.roles, mundo.mi_club(), mundo.prensa, mundo.anio, mundo.semana)
	Aviso.mostrar(self, "vida", "🏠", "Mi vida", r)
	_refrescar()

## UN ASUNTO DEL PERSONAL DE UNA INSTALACIÓN (26-9-2026): quién, qué pasa y
## las dos salidas. Debajo, cómo está su equipo.
func _pintar_asunto_personal() -> void:
	var p := mundo.trabajadores.pendiente
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", Tema.caja(Tema.TARJETA, Tema.RADIO, Tema.ORO))
	_despacho.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	caja.add_child(v)
	var inst := String(Instalaciones.CATALOGO.get(String(p["inst"]), ["Instalación"])[0])
	v.add_child(Tema.rotulo("%s · %s" % [inst, String(p["nombre"])]))
	var t := Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, String(p["texto"]))
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var eq := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "👥 " + mundo.trabajadores.texto_equipo(mundo.mi_club(), mundo.obras, String(p["inst"])).replace("\n", "\n👥 "))
	eq.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(eq)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	v.add_child(fila)
	for op: String in ["a", "b"]:
		var b := Button.new()
		b.text = String(p[op])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		b.pressed.connect(_resolver_personal.bind(op))
		fila.add_child(b)

func _resolver_personal(op: String) -> void:
	var r := mundo.trabajadores.resolver(op, mundo.mi_club(), mundo.obras, mundo.prensa)
	Aviso.mostrar(self, "nivel", "🏢", String(r.get("titulo", "")), String(r.get("cuerpo", "")))
	_refrescar()

## UN ASUNTO DE LA ACADEMIA (C11): el tema y las dos salidas.
func _pintar_asunto_cantera() -> void:
	var p := mundo.eventos_cantera.pendiente
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", Tema.caja(Tema.TARJETA, Tema.RADIO, Tema.BIEN))
	_despacho.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	caja.add_child(v)
	v.add_child(Tema.rotulo("Academia · %s" % String(p["nombre"])))
	var t := Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, String(p["tema"]))
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	v.add_child(fila)
	for op: String in ["a", "b"]:
		var b := Button.new()
		b.text = String(p[op])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		b.pressed.connect(_resolver_cantera.bind(op))
		fila.add_child(b)

func _resolver_cantera(op: String) -> void:
	var r := mundo.eventos_cantera.resolver(op, mundo.academia, mundo.mi_club())
	Aviso.mostrar(self, "nivel", "🌱", String(r.get("titulo", "")), String(r.get("cuerpo", "")))
	_refrescar()

## LA JUNTA DE ACCIONISTAS (plan maestro C5): quién habla, cuánto pesa, qué pide
## y las dos salidas. Debajo, la mesa entera con el humor de cada uno.
func _pintar_junta() -> void:
	var jt := mundo.junta
	var p := jt.pendiente
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", Tema.caja(Tema.TARJETA, Tema.RADIO, Tema.ORO))
	_despacho.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	caja.add_child(v)
	v.add_child(Tema.rotulo("Junta de accionistas · preside %s (%s)" % [String(jt.presidente.get("nombre", "")), String(jt.presidente.get("estilo", ""))]))
	var t := Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, "%s %s" % [String(p["quien"]), String(p["tema"])])
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	v.add_child(fila)
	for op: String in ["a", "b"]:
		var b := Button.new()
		b.text = String(p[op])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		b.pressed.connect(func() -> void:
			var r := mundo.junta.resolver(op, mundo.mi_club(), mundo.directiva, mundo.prensa)
			Aviso.mostrar(self, "contrato", "🏛️", String(r.get("titulo", "")), String(r.get("cuerpo", "")))
			_refrescar())
		fila.add_child(b)
	var partes: PackedStringArray = []
	for a: Dictionary in jt.accionistas:
		var cara: String = "🙂" if int(a["humor"]) >= 60 else ("😠" if int(a["humor"]) < 35 else "😐")
		partes.append("%s %s %d%% (%s)" % [cara, String(a["nombre"]), int(a["pct"]), String(Junta.EXIGENCIAS.get(String(a["exige"]), ""))])
	var mesa := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "  ·  ".join(partes))
	mesa.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(mesa)

## Los clubes que te quieren después de un despido. `ofertas_trabajo()` garantiza
## que SIEMPRE haya al menos uno -por hundido que esté tu prestigio-, así que
## esta pantalla nunca deja al jugador sin salida; por eso puede permitirse ser
## la que tapa a todas las demás.
func _pintar_sin_banco() -> void:
	var r := mundo.roles
	var v := _marco_aviso(COL_ROJO)
	var t := _texto(11, COL_ROJO)
	t.text = "ESTÁS SIN BANCO"
	v.add_child(t)
	var txt := _texto(13, COL_TEXTO)
	txt.text = "Te quedaste sin club. Elige dónde seguir tu carrera: el prestigio y la vitrina te acompañan, lo que construiste en el club anterior se queda allí."
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(txt)
	for c in r.ofertas_trabajo():
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		v.add_child(fila)
		var esc := _escudo(c, 26)
		esc.custom_minimum_size = Vector2(26, 26)
		fila.add_child(esc)
		var nom := _texto(12, COL_TEXTO)
		## La reputación del club contra la tuya es LA decisión: firmar por
		## encima de tu prestigio es un salto, por debajo es un refugio.
		var salto := "  ·  por encima de tu prestigio" if c.rep > r.prestigio else ""
		nom.text = "%s  ·  división %d  ·  reputación %d%s" % [c.nombre, c.division, c.rep, salto]
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(nom)
		var b := Button.new()
		b.text = "Firmar"
		b.add_theme_font_size_override("font_size", 11)
		var id := c.id
		b.pressed.connect(func() -> void: _aceptar_trabajo(id))
		fila.add_child(b)

func _aceptar_trabajo(club_id: String) -> void:
	var problema := mundo.roles.aceptar_trabajo(club_id)
	if problema != "":
		_escribir("[color=#e05555]%s.[/color]" % problema)
	_refrescar()

## Un representante presiona por varios de sus clientes a la vez. Va en el
## despacho y no en la pestaña Cantera porque, como la decisión de prensa, es
## algo que hay que resolver AHORA -escondida en una pestaña, la semana pasa
## sin que el jugador la vea y el sistema deja de existir para él.
func _pintar_exigencia_agente(e: Dictionary) -> void:
	var v := _marco_aviso(COL_VERDE)
	var t := _texto(11, COL_VERDE)
	t.text = "UN REPRESENTANTE PRESIONA"
	v.add_child(t)
	var txt := _texto(13, COL_TEXTO)
	txt.text = String(e.get("txt", ""))
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(txt)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	v.add_child(fila)
	_boton(String(e.get("opcion_a", "Sí")), func() -> void: _resolver_agente("a"), fila)
	_boton(String(e.get("opcion_b", "No")), func() -> void: _resolver_agente("b"), fila)

func _resolver_agente(op: String) -> void:
	var r := mundo.cantera.resolver_agente(op)
	_escribir("[color=#4caf6d][b]%s[/b][/color] %s" % [
		String(r.get("titulo", "Resuelto")), String(r.get("cuerpo", ""))])
	_refrescar()

func _marco_aviso(color: Color) -> VBoxContainer:
	var caja := PanelContainer.new()
	var e := StyleBoxFlat.new()
	## EL AVISO, CON MÁS VIDA (10-9-2026, pedido del usuario: "las
	## notificaciones deben ser mejores visualmente"). Tres cambios sobre el
	## marco plano de antes:
	##  · el fondo se tiñe UN POCO del color del aviso -un 8%-, así una
	##    decisión urgente se distingue de una rueda de prensa sin leer nada;
	##  · la barra lateral pasa de 4 a 6 px y las esquinas se redondean más,
	##    para que combine con las píldoras del menú nuevo;
	##  · entra con un desliz corto desde la izquierda, que es lo que hace
	##    que se note que ACABA de aparecer y no que estaba ahí desde antes.
	e.bg_color = _mezcla(_pal_panel(), color, 0.08)
	e.border_color = color
	e.set_border_width_all(1)
	e.border_width_left = 6
	e.set_corner_radius_all(10)
	e.content_margin_left = 14
	e.content_margin_right = 14
	e.content_margin_top = 10
	e.content_margin_bottom = 10
	e.shadow_color = Color(0, 0, 0, 0.25)
	e.shadow_size = 4
	caja.add_theme_stylebox_override("panel", e)
	_despacho.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	caja.add_child(v)
	caja.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(caja, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_SINE)
	return v

## LA DECISIÓN, CONTADA COMO UN ACONTECIMIENTO (25-9-2026, plan maestro B4).
## A la izquierda, la cara de quien está en el lío -o el icono grande del tema
## si no hay un jugador-; suena y late la primera vez que aparece; y al firmar,
## la consecuencia sale en un aviso además del registro.
var _decision_mostrada := ""

func _pintar_decision(e: Dictionary) -> void:
	var v := _marco_aviso(COL_ORO)
	var t := _texto(11, COL_ORO)
	t.text = "HAY QUE DECIDIR"
	v.add_child(t)
	var fila_cuerpo := HBoxContainer.new()
	fila_cuerpo.add_theme_constant_override("separation", 12)
	v.add_child(fila_cuerpo)
	var txt_evento := String(e.get("txt", ""))
	var j: Jugador = null
	var pid := String(e.get("pid", ""))
	if pid != "" and mundo.mi_club() != null:
		for x: Jugador in mundo.mi_club().plantilla:
			if x.id == pid:
				j = x
	if j != null:
		fila_cuerpo.add_child(_retrato(j, 56))
	else:
		## El primer carácter del texto es el emoji del tema (🎙️, 🕯️, 🚨...).
		var icono := Label.new()
		icono.text = txt_evento.substr(0, 2).strip_edges() if txt_evento != "" else "❗"
		icono.add_theme_font_size_override("font_size", 34)
		icono.custom_minimum_size = Vector2(56, 56)
		icono.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icono.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fila_cuerpo.add_child(icono)
	var txt := _texto(13, COL_TEXTO)
	txt.text = txt_evento
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila_cuerpo.add_child(txt)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	v.add_child(fila)
	_boton(String(e.get("opcion_a", "Sí")), func() -> void: _resolver("a"), fila)
	_boton(String(e.get("opcion_b", "No")), func() -> void: _resolver("b"), fila)
	var clave := "%s|%s" % [String(e.get("id", "")), pid]
	if clave != _decision_mostrada:
		_decision_mostrada = clave
		Sonido.toca("notificacion" if Sonido.NOMBRES.has("notificacion") else "cambio", Sonido.Bus.INTERFAZ)
		var caja := v.get_parent() as Control
		if caja != null:
			(func() -> void: Animar.pulso(caja, 1.03)).call_deferred()

func _resolver(op: String) -> void:
	var r := mundo.prensa.resolver(op)
	var titulo := String(r.get("titulo", "Decisión tomada"))
	var cuerpo := String(r.get("cuerpo", ""))
	## Al registro ya lo escribe `Prensa.noticia` (ver `_conectar_noticias()`):
	## escribirlo aquí también lo duplicaba. Aquí solo el aviso destacado.
	if not r.is_empty():
		Aviso.mostrar(self, "contrato", "📰", titulo, cuerpo)
	_refrescar()

## `SOLICITUDES` del HTML: un jugador te viene a pedir algo -más minutos, un
## sueldo mejor, la cinta de capitán...- y hay que decirle que sí o que no. El
## motor (`Vestuario.sortear_solicitud`/`resolver_solicitud`) llevaba tiempo
## escrito sin que ninguna pantalla lo mostrara nunca.
func _pintar_solicitud_plantel() -> void:
	var v := mundo.vestuario
	var j := v.jugador_de_solicitud()
	if j == null:
		return
	var d := v.def_solicitud(String(v.solicitud.get("k", "")))
	if d.is_empty():
		return
	var marco := _marco_aviso(COL_VERDE)
	var t := _texto(11, COL_VERDE)
	t.text = "TE BUSCA UN JUGADOR"
	marco.add_child(t)
	var txt := _texto(13, COL_TEXTO)
	txt.text = "%s (%d años, media %d) %s" % [j.nombre, j.edad, j.ovr, String(d[1]).to_lower()]
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	marco.add_child(txt)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	marco.add_child(fila)
	_boton("✅  %s" % String(d[2]), func() -> void: _resolver_solicitud(true), fila)
	_boton("❌  %s" % String(d[3]), func() -> void: _resolver_solicitud(false), fila)

func _resolver_solicitud(si: bool) -> void:
	var r := mundo.vestuario.resolver_solicitud(si)
	if r.is_empty():
		return
	## "compa": `Vestuario` no conoce `Cantera` -son dos clases del motor sin
	## relación entre sí-, así que el llamado cruzado se hace aquí, que es
	## quien tiene acceso a las dos.
	if si and String(r.get("clave", "")) == "compa" and mundo.cantera != null:
		mundo.cantera.prometer_compatriota(r["jugador"] as Jugador)
	_escribir("[color=#c9a227][b]%s[/b][/color] %s" % [
		String(r.get("titulo", "")), String(r.get("cuerpo", ""))])
	_refrescar()

## LA RUEDA DE PRENSA, DE PANTALLA COMPLETA.
##
## El usuario la comparó con la conferencia de prensa de FC26 -pantalla
## entera, cámara y todo lo demás oculto mientras dura- y marcó que "eso
## debería tener su propio lugar". La primera versión la encogía dentro de
## la misma tarjetita de "asuntos pendientes" que comparte con el agente que
## presiona o el jugador que te busca: un `SubViewport` de 900×360 compitiendo
## por espacio con la barra superior y la tabla de posiciones. Ahora es una
## cinemática de pantalla completa, MISMO PATRÓN que `Sorteo`
## (`_siguiente_sorteo()`, más arriba en este archivo): un `Control` colgado
## directo de `self`, por encima de todo, que se cierra solo al responder.
##
## SIGUE SIN INVENTAR DIÁLOGO. La pregunta, las opciones y el "cómo lo dices"
## son exactamente los mismos datos de siempre (`Prensa.entrevista`); esto
## solo cambia DÓNDE se presentan.
func _abrir_rueda_pantalla_completa(e: Dictionary) -> void:
	var pop := Control.new()
	pop.set_anchors_preset(Control.PRESET_FULL_RECT)
	pop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(pop)
	_rueda_pop = pop

	var fondo := ColorRect.new()
	fondo.color = Color(0.035, 0.038, 0.045)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	pop.add_child(fondo)

	var raiz := VBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.offset_left = 48.0; raiz.offset_right = -48.0
	raiz.offset_top = 28.0; raiz.offset_bottom = -28.0
	raiz.add_theme_constant_override("separation", 10)
	pop.add_child(raiz)

	var t := _texto(13, COL_ACENTO)
	t.text = "🎙️ RUEDA DE PRENSA"
	raiz.add_child(t)

	## EL PLATÓ 3D. Con pantalla completa ya no hace falta encogerlo a 220 px
	## de alto: se le da la mayor parte del espacio -`SIZE_EXPAND_FILL`- y una
	## resolución de `SubViewport` bastante mayor, para que se note el salto.
	var caja := Control.new()
	caja.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caja.clip_contents = true
	raiz.add_child(caja)

	var vp_cont := SubViewportContainer.new()
	vp_cont.stretch = true
	vp_cont.set_anchors_preset(Control.PRESET_FULL_RECT)
	vp_cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_child(vp_cont)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = false
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.size = Vector2i(1600, 720)
	vp_cont.add_child(vp)
	var escena := RuedaPrensaEscena3D.new()
	vp.add_child(escena)
	var mio := mundo.mi_club()
	## QUIÉN HABLA DE VERDAD (14-9-2026). Si el jugador no es él mismo el
	## entrenador -ayudante de campo, director deportivo, dueño con el banco
	## delegado-, `Roles.dt_empleado` no está vacío: es ESE quien da la rueda
	## de prensa, no el jugador -mostrar tu propia cara ahí sería que el dueño
	## del club diera la conferencia técnica en tu lugar-. El empleado no
	## tiene editor de aspecto propio -nadie personaliza a alguien que no
	## eres tú-, así que `CaraDT.look_de_nombre()` le da uno determinístico
	## por su nombre: el mismo empleado siempre sale igual.
	var nombre_dt := ""
	var look_dt := {}
	if mundo.roles != null:
		if not mundo.roles.dt_empleado.is_empty():
			nombre_dt = mundo.roles.dt_nombre()
			look_dt = CaraDT.look_de_nombre(nombre_dt)
		else:
			nombre_dt = mundo.roles.nombre
			look_dt = mundo.roles.look_efectivo()
	## EL FONDO: los escudos de tu liga, no sponsors genéricos (14-9-2026). La
	## rueda de prensa solo se abre tras un partido de LIGA
	## (`Mundo.rueda_tras_resultado()`, ver `nucleo/prensa.gd`), así que la
	## competencia correspondiente es siempre tu propia liga.
	var clubes_competencia: Array = []
	## Tras una copa o un continental (C1), los escudos de ESA competición.
	if mundo.prensa != null and mundo.prensa.competicion_rueda != "liga" and not mundo.prensa.clubes_rueda.is_empty():
		clubes_competencia = mundo.prensa.clubes_rueda
	elif mio != null:
		var liga := mundo.liga_de(mio)
		if liga != null:
			clubes_competencia = liga.clubes
	if mio != null:
		escena.montar(mio, COL_ACENTO, Calidad.ALTO, look_dt, clubes_competencia)

	## LA PLACA DEL DT, arriba a la izquierda -mismo "chyron" con foto y
	## nombre que pone cualquier transmisión de verdad cuando habla alguien-.
	if not nombre_dt.is_empty():
		var placa := PanelContainer.new()
		placa.set_anchors_preset(Control.PRESET_TOP_LEFT)
		placa.offset_left = 14.0; placa.offset_top = 14.0
		placa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb_placa := StyleBoxFlat.new()
		sb_placa.bg_color = Color(0, 0, 0, 0.6)
		sb_placa.content_margin_left = 8.0; sb_placa.content_margin_right = 12.0
		sb_placa.content_margin_top = 6.0; sb_placa.content_margin_bottom = 6.0
		sb_placa.corner_radius_top_left = 6; sb_placa.corner_radius_top_right = 6
		sb_placa.corner_radius_bottom_left = 6; sb_placa.corner_radius_bottom_right = 6
		placa.add_theme_stylebox_override("panel", sb_placa)
		caja.add_child(placa)
		var fila_placa := HBoxContainer.new()
		fila_placa.add_theme_constant_override("separation", 8)
		placa.add_child(fila_placa)
		var foto_dt := TextureRect.new()
		foto_dt.texture = CaraDT.textura(look_dt, 36)
		foto_dt.custom_minimum_size = Vector2(36, 36)
		foto_dt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		foto_dt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fila_placa.add_child(foto_dt)
		var nom_dt := _texto(12, COL_TEXTO)
		nom_dt.text = nombre_dt
		nom_dt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fila_placa.add_child(nom_dt)

	## EL SUBTÍTULO, sobre la imagen -el "lower third" de la foto de Ancelotti
	## que mandó el usuario-. Alto fijo con `offset_top` negativo, no un
	## preset a secas: un `Control` no recorta a sus hijos solo, y un preset
	## sin offset propio da alto CERO justo donde termina la caja, así que el
	## contenido se derrama hacia abajo -se vio en la primera captura, tapando
	## los controles de más abajo-.
	var subt := PanelContainer.new()
	subt.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	subt.offset_top = -84.0
	subt.offset_bottom = 0.0
	subt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.72)
	sb.content_margin_left = 18.0; sb.content_margin_right = 18.0
	sb.content_margin_top = 10.0; sb.content_margin_bottom = 10.0
	subt.add_theme_stylebox_override("panel", sb)
	caja.add_child(subt)
	var col_subt := VBoxContainer.new()
	col_subt.add_theme_constant_override("separation", 3)
	subt.add_child(col_subt)
	var quien := _texto(11, COL_ACENTO)
	col_subt.add_child(quien)
	var q := _texto(15, COL_TEXTO)
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col_subt.add_child(q)
	_rueda_quien = quien
	_rueda_pregunta = q

	raiz.add_child(_fila_posturas())
	_rueda_opciones = _fila_opciones_rueda(e)
	raiz.add_child(_rueda_opciones)
	raiz.add_child(_fila_texto_libre())
	## EL RELOJ DE LA SALA (B5, "lenguaje corporal"): una barra que se llena en
	## `Prensa.TITUBEO_SEG` segundos. Cuando se llena, contestar ya cuenta como
	## titubeo. Se ve para que no sea una trampa.
	var reloj := ProgressBar.new()
	reloj.show_percentage = false
	reloj.custom_minimum_size = Vector2(0, 6)
	reloj.max_value = Prensa.TITUBEO_SEG
	raiz.add_child(reloj)
	_rueda_reloj = reloj
	_pintar_pregunta_rueda(e)

## La pregunta en pantalla y el reloj a cero. La usa también la repregunta,
## que cambia el texto sin rehacer el plató 3D.
func _pintar_pregunta_rueda(e: Dictionary) -> void:
	var quien_txt := String(e.get("quien", "Periodista"))
	var per := String(e.get("periodista", ""))
	if per != "":
		var rel := mundo.prensa.relacion_con(per)
		var trato := "te aprecia" if rel >= 65 else ("no te quiere" if rel <= 35 else "sin bando")
		quien_txt += "  ·  %s, %s" % [String(e.get("perfil", "")), trato]
	if bool(e.get("memoria", false)):
		quien_txt += "  ·  🧠 recuerda lo que dijiste"
	_rueda_quien.text = "🎙️ " + quien_txt.to_upper()
	_rueda_pregunta.text = String(e.get("pregunta", ""))
	_rueda_desde = Time.get_ticks_msec()
	if is_instance_valid(_rueda_reloj):
		_rueda_reloj.value = 0.0
		_rueda_reloj.modulate = Color.WHITE
		var tw := _rueda_reloj.create_tween()
		tw.tween_property(_rueda_reloj, "value", Prensa.TITUBEO_SEG, Prensa.TITUBEO_SEG)
		tw.tween_callback(func() -> void:
			if is_instance_valid(_rueda_reloj):
				_rueda_reloj.modulate = Tema.MAL)
		_rueda_reloj.set_meta("tween", tw)

func _segundos_rueda() -> float:
	return float(Time.get_ticks_msec() - _rueda_desde) / 1000.0

## Responder con tus palabras. El tono lo decide `Prensa.clasificar_respuesta()`
## por palabras clave, en local: nada sale del ordenador.
func _fila_texto_libre() -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	var campo := LineEdit.new()
	campo.placeholder_text = "…o responde con tus propias palabras"
	campo.max_length = 120
	campo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(campo)
	var b := Button.new()
	b.text = "Responder"
	fila.add_child(b)
	var enviar := func(_t: String = "") -> void:
		if campo.text.strip_edges() != "":
			var dicho := campo.text
			campo.clear()   ## si llega la repregunta, el campo vuelve vacío
			_tras_responder(mundo.prensa.responder_texto(dicho, _segundos_rueda()))
	b.pressed.connect(func() -> void: enviar.call())
	campo.text_submitted.connect(enviar)
	return fila

## "Cómo lo dices". Vive aparte de `_abrir_rueda_pantalla_completa()` porque
## se repinta sola al tocar una postura -sin cerrar ni reabrir el plató 3D
## entero, que sería tirar y rehacer el `SubViewport` por nada-.
func _fila_posturas() -> HBoxContainer:
	var posturas := HBoxContainer.new()
	posturas.add_theme_constant_override("separation", 6)
	var et := _texto(11, COL_SUAVE)
	et.text = "Cómo lo dices:"
	et.custom_minimum_size = Vector2(96, 0)
	posturas.add_child(et)
	var lista_cuerpos: Dictionary = mundo.prensa.cuerpos()
	for k: String in lista_cuerpos:
		var datos: Array = lista_cuerpos[k]
		var b := Button.new()
		b.text = "%s %s" % [String(datos[0]), String(datos[1])]
		b.toggle_mode = true
		b.button_pressed = (k == mundo.prensa.cuerpo)
		b.add_theme_font_size_override("font_size", 11)
		b.pressed.connect(func() -> void:
			mundo.prensa.fijar_cuerpo(k)
			_repintar_posturas())
		posturas.add_child(b)
	return posturas

## Repinta solo la fila de posturas -el botón que se marca al tocar una-, sin
## tocar el plató 3D ni las opciones.
func _repintar_posturas() -> void:
	if _rueda_pop == null:
		return
	var raiz := _rueda_pop.get_child(1) as VBoxContainer
	if raiz == null or raiz.get_child_count() < 3:
		return
	var vieja := raiz.get_child(2)
	raiz.remove_child(vieja)
	vieja.queue_free()
	raiz.add_child(_fila_posturas())
	raiz.move_child(raiz.get_child(raiz.get_child_count() - 1), 2)

func _fila_opciones_rueda(e: Dictionary) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	var ops: Array = e.get("opciones", [])
	for i in ops.size():
		var op: Variant = ops[i]
		var b2 := Button.new()
		## Las opciones del guion son DICCIONARIOS -{txt, moral, confianza,
		## socios}-, no arrays ni cadenas: `String(op)` reventaba en cada rueda
		## de prensa y el boton se quedaba sin texto. No se veia porque la rueda
		## no llegaba a abrirse nunca en una partida de verdad.
		if op is Dictionary:
			b2.text = String((op as Dictionary).get("txt", ""))
		elif op is Array:
			b2.text = String((op as Array)[0])
		else:
			b2.text = str(op)
		b2.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b2.custom_minimum_size = Vector2(0, 42)
		b2.add_theme_font_size_override("font_size", 13)
		b2.pressed.connect(func() -> void: _responder(i))
		col.add_child(b2)
	return col

func _responder(i: int) -> void:
	_tras_responder(mundo.prensa.responder(i, _segundos_rueda()))

func _tras_responder(r: Dictionary) -> void:
	if r.is_empty():
		return
	## La frase y el "cómo" ya los escribe `Prensa.noticia`; aquí solo lo que
	## movió, que es lo que no dice la noticia.
	var col := "#4caf6d" if int(r.get("confianza", 0)) >= 0 else "#e05555"
	_escribir("[color=%s]🎙 moral %+d · confianza %+d · socios %+d[/color]" % [
		col, int(r.get("moral", 0)), int(r.get("confianza", 0)), int(r.get("socios", 0))])
	## LA REPREGUNTA: el mismo plató, otra pregunta y otras opciones.
	if bool(r.get("sigue", false)) and _rueda_pop != null and mundo.prensa.hay_rueda():
		var e := mundo.prensa.entrevista
		var viejas := _rueda_opciones
		_rueda_opciones = _fila_opciones_rueda(e)
		viejas.add_sibling(_rueda_opciones)
		viejas.queue_free()
		_pintar_pregunta_rueda(e)
		Animar.aparecer(_rueda_opciones)
		Sonido.toca("cambio", Sonido.Bus.INTERFAZ)
		return
	## Se cierra la cinemática -ya respondiste, no hay nada más que ver- y se
	## vuelve al juego normal.
	if _rueda_pop != null:
		_rueda_pop.queue_free()
		_rueda_pop = null
	_refrescar()

# --- las tres pestañas nuevas ----------------------------------------------

## La enfermería: quién está fuera, con qué y cuánto le queda, y qué se puede
## hacer al respecto. Es la pantalla que hace que contratar al jefe médico y
## pagar una terapia signifiquen algo.
## EL BALANCE DEL DEPARTAMENTO MÉDICO, de `vMedico()`. La pantalla enseñaba los
## partes uno a uno pero no respondía a la pregunta que de verdad se hace el
## jugador: ¿mi cuerpo médico es bueno o estoy tirando el dinero? Eso solo se
## contesta con el ACUMULADO de la temporada y comparándolo con la liga.
func _pintar_balance_medico(c: Club) -> void:
	var med := mundo.medico
	var r: Dictionary = med.ranking_liga(c, _liga_de(c))
	var g := GridContainer.new()
	g.columns = 4
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 12)
	_lista_medico.add_child(g)
	var enfermeria := 0
	for j in c.plantilla:
		if j.lesion > 0:
			enfermeria += 1
	for par in [["En la enfermería", str(enfermeria)], ["Días perdidos", str(med.dias_perdidos)],
			["En la liga", "%d.º de %d" % [int(r["puesto"]), int(r["total"])]],
			["Media de la liga", "%d sem" % int(r["media"])]]:
		var col := VBoxContainer.new()
		g.add_child(col)
		var et := _texto(10, COL_SUAVE)
		et.text = String(par[0])
		col.add_child(et)
		var va := _texto(16, COL_TEXTO)
		va.text = String(par[1])
		col.add_child(va)
	## El veredicto en una frase. Un puesto en una tabla no dice qué hacer; esto
	## sí, y es lo que convierte la pantalla en una decisión.
	var mejor := int(r["mias"]) < int(r["media"])
	var v := _texto(11, COL_VERDE if mejor else COL_ORO)
	v.text = ("Tu cuerpo médico pierde menos semanas que la media de la liga. Se nota la inversión."
		if mejor else
		"Pierdes más semanas por lesión que la media. Mira el jefe médico, el centro médico y la carga de entrenamiento.")
	v.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_medico.add_child(v)
	if not med.brote.is_empty():
		var b := _texto(12, COL_ROJO)
		b.text = "🤒 Brote activo: %d tocados, %d semana(s) más." % [
			int(med.brote.get("n", 0)), int(med.brote.get("semanas", 0))]
		_lista_medico.add_child(b)
	## LOS DE RIESGO: quién llega justo al domingo. Es la lista que evita la
	## lesión antes de que pase, que es más útil que el parte de la que ya pasó.
	var riesgo: Array[Jugador] = []
	for j2 in c.plantilla:
		if j2.lesion <= 0 and (j2.fisico < 62 or j2.rasgo == "fragil"):
			riesgo.append(j2)
	riesgo.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.fisico < b.fisico)
	if not riesgo.is_empty():
		_lista_medico.add_child(HSeparator.new())
		var tr := _texto(11, COL_SUAVE)
		tr.text = "EN RIESGO ESTA SEMANA"
		_lista_medico.add_child(tr)
		for i in mini(8, riesgo.size()):
			var j3: Jugador = riesgo[i]
			_dato("%s%s  ·  físico %d" % ["🩹 " if j3.rasgo == "fragil" else "⚠️ ", j3.nombre, j3.fisico],
				"no debería jugar" if j3.fisico < 50 else "al límite",
				COL_ROJO if j3.fisico < 50 else COL_ORO, _lista_medico)
	_lista_medico.add_child(HSeparator.new())

func _pintar_medico(c: Club) -> void:
	_limpiar(_lista_medico)
	if mundo.medico == null:
		return
	var nivel := mundo.staff.nivel("medico")
	var t := _texto(11, COL_SUAVE)
	t.text = "PARTE MÉDICO  ·  jefe médico: %s" % ("★".repeat(nivel) if nivel > 0 else "sin contratar")
	_lista_medico.add_child(t)
	_pintar_balance_medico(c)
	var tocados := c.plantilla.filter(func(j: Jugador) -> bool: return j.lesion > 0 or j.suspension > 0)
	if tocados.is_empty():
		var vacio := _texto(13, COL_VERDE)
		vacio.text = "Enfermería vacía: los %d están disponibles." % c.plantilla.size()
		_lista_medico.add_child(vacio)
	tocados.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.lesion > b.lesion)
	for j: Jugador in tocados:
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		_lista_medico.add_child(fila)
		fila.add_child(_retrato(j, 24))
		var nom := _texto(12, COL_ROJO)
		var diag := mundo.medico.diagnostico(j) if j.lesion > 0 else "sancionado"
		nom.text = "%s  ·  %s" % [j.nombre, diag]
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(nom)
		if j.lesion > 0:
			var pct := _texto(11, COL_SUAVE)
			pct.text = "%d%% recuperado" % mundo.medico.pct_recuperado(j)
			fila.add_child(pct)
			var coste := mundo.medico.costo_terapia(j, c.rep)
			var b := Button.new()
			b.text = "Terapia  %s" % _dinero(coste)
			b.add_theme_font_size_override("font_size", 11)
			b.disabled = coste > c.saldo
			b.pressed.connect(func() -> void: _terapia(j))
			fila.add_child(b)
			## La segunda opinión: puede acortar el plazo, alargarlo o
			## confirmarlo. Cuanto mejor es tu cuerpo médico, menos hay que
			## corregir -pero también menos sustos-, que es lo que la convierte
			## en una apuesta y no en un botón de "curar más rápido".
			var coste_op := mundo.medico.coste_segunda_opinion(j, c)
			var b2 := Button.new()
			b2.text = "2.ª opinión  %s" % _dinero(coste_op)
			b2.add_theme_font_size_override("font_size", 11)
			b2.disabled = coste_op > c.saldo
			b2.pressed.connect(func() -> void: _segunda_opinion(j))
			fila.add_child(b2)

	## Y el riesgo de los que están sanos pero cargados: es lo que permite rotar
	## antes de romper a alguien, en vez de enterarse cuando ya está roto.
	_lista_medico.add_child(HSeparator.new())
	var t2 := _texto(11, COL_SUAVE)
	t2.text = "RIESGO DE LESIÓN"
	_lista_medico.add_child(t2)
	var sanos := c.plantilla.filter(func(j: Jugador) -> bool: return j.lesion <= 0)
	sanos.sort_custom(func(a: Jugador, b: Jugador) -> bool:
		return mundo.medico.riesgo_por_fatiga(a) > mundo.medico.riesgo_por_fatiga(b))
	for i in mini(8, sanos.size()):
		var j2: Jugador = sanos[i]
		var r := mundo.medico.riesgo_declarado(j2)
		var col2 := COL_ROJO if r == "alto" else (COL_ORO if r.begins_with("medio") else COL_SUAVE)
		var l := _texto(12, col2)
		l.text = "%s  ·  riesgo %s  ·  físico %d" % [j2.nombre, r, j2.fisico]
		_lista_medico.add_child(l)

func _terapia(j: Jugador) -> void:
	var problema := mundo.medico.terapia(j, mundo.mi_club())
	if problema != "":
		_escribir("[color=#e05555]No se puede: %s.[/color]" % problema)
		return
	_escribir("[color=#4caf6d]Terapia para %s:[/color] le quedan %d semanas." % [j.nombre, j.lesion])
	_refrescar()

## Los logros. Se enseñan los conseguidos y los que faltan; los que dependen de
## un sistema que todavía no está portado salen marcados aparte, en vez de
## fingir que se pueden conseguir.
func _pintar_logros() -> void:
	_limpiar(_lista_logros)
	if mundo.logros == null:
		return
	var lg := mundo.logros

	## El perfil de gestor: la carrera que sobrevive a esta partida. Va primero
	## porque es lo único de esta pestaña que no se pierde ni empezando de cero.
	var perfil := Logros.perfil_leer()
	var nivel := Logros.perfil_nivel(int(perfil["xp"]))
	var tp := _texto(13, COL_ACENTO)
	tp.text = "%s  ·  %d XP" % [String(nivel["nombre"]), int(nivel["xp"])]
	_lista_logros.add_child(tp)
	var barra := ProgressBar.new()
	barra.min_value = 0
	barra.max_value = 100
	barra.value = int(nivel["pct"])
	barra.custom_minimum_size = Vector2(0, 14)
	barra.show_percentage = false
	_lista_logros.add_child(barra)
	var lema := _texto(11, COL_SUAVE)
	lema.text = String(nivel["lema"]) + (("  ·  faltan %d XP para %s" % [int(nivel["faltan"]), String(nivel["siguiente"])]) if String(nivel["siguiente"]) != "" else "")
	lema.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_logros.add_child(lema)
	_lista_logros.add_child(HSeparator.new())

	var cat := lg.catalogo()
	var hechos := 0
	for f: Dictionary in cat:
		if f["conseguido"]:
			hechos += 1
	var t := _texto(13, COL_ORO)
	t.text = "%d de %d logros" % [hechos, cat.size()]
	_lista_logros.add_child(t)
	for f: Dictionary in cat:
		var col := COL_VERDE if f["conseguido"] else (COL_BORDE if f["pendiente"] else COL_SUAVE)
		var l := _texto(12, col)
		var marca := "hecho" if f["conseguido"] else ("—" if f["pendiente"] else "por hacer")
		l.text = "%s %s  ·  %s" % [String(f["icono"]), String(f["titulo"]), marca]
		_lista_logros.add_child(l)
		var d := _texto(11, COL_BORDE if f["pendiente"] else COL_SUAVE)
		d.text = "     " + String(f["descripcion"]) + ("   (su sistema aún no está portado)" if f["pendiente"] else "")
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_logros.add_child(d)

	if not lg.muro.is_empty():
		_lista_logros.add_child(HSeparator.new())
		var tm := _texto(11, COL_SUAVE)
		tm.text = "VITRINA"
		_lista_logros.add_child(tm)
		for i in range(lg.muro.size() - 1, maxi(-1, lg.muro.size() - 6), -1):
			var trofeo: Dictionary = lg.muro[i]
			var lt := _texto(12, COL_ORO)
			lt.text = "%d  ·  %s" % [int(trofeo.get("anio", 0)), String(trofeo.get("titulo", ""))]
			_lista_logros.add_child(lt)

	var goleadores := lg.goleadores_historicos(5)
	if not goleadores.is_empty():
		_lista_logros.add_child(HSeparator.new())
		var tg := _texto(11, COL_SUAVE)
		tg.text = "MÁXIMOS GOLEADORES DE TU ERA"
		_lista_logros.add_child(tg)
		for fila: Dictionary in goleadores:
			var lg2 := _texto(12, COL_TEXTO)
			lg2.text = "%s  ·  %d goles" % [String(fila["nombre"]), int(fila["goles"])]
			_lista_logros.add_child(lg2)

	if not lg.rec.is_empty():
		_lista_logros.add_child(HSeparator.new())
		var tr := _texto(11, COL_SUAVE)
		tr.text = "RÉCORDS DEL CLUB"
		_lista_logros.add_child(tr)
		if lg.rec.has("mayor_goleada"):
			var f2: Dictionary = lg.rec["mayor_goleada"]
			var lr := _texto(12, COL_VERDE)
			lr.text = "Mayor goleada: %s a %s (%d)" % [String(f2.get("marcador", "")), String(f2.get("rival", "")), int(f2.get("anio", 0))]
			_lista_logros.add_child(lr)
		if lg.rec.has("peor_derrota"):
			var f3: Dictionary = lg.rec["peor_derrota"]
			var lr2 := _texto(12, COL_ROJO)
			lr2.text = "Peor derrota: %s ante %s (%d)" % [String(f3.get("marcador", "")), String(f3.get("rival", "")), int(f3.get("anio", 0))]
			_lista_logros.add_child(lr2)
	_pintar_logros_ocultos(lg)
	_pintar_ranking_canteras()
	_pintar_palmares_por_anio(lg)
	_pintar_museo(lg)

## EL MUSEO DEL CLUB. `Instalaciones` deja construirlo y cobra ingresos por él
## desde el porte, pero no tenía CONTENIDO: se pagaba un edificio cuyo interior
## no existía en ninguna pantalla.
##
## Las piezas no se guardan aparte: se deducen de lo que el club ya tiene
## anotado —trofeos, récords, goleadores— igual que el salón de la fama. Una
## lista paralela sería otro sitio más que mantener al día.
func _pintar_museo(lg: Logros) -> void:
	if mundo.obras == null or mundo.obras.nivel("museo") <= 0:
		return
	var piezas := lg.piezas_del_museo()
	_lista_logros.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "🏛️ MUSEO DEL CLUB  ·  nivel %d  ·  %d pieza(s)" % [mundo.obras.nivel("museo"), piezas.size()]
	_lista_logros.add_child(t)
	if piezas.is_empty():
		var vac := _texto(11, COL_SUAVE)
		vac.text = "El museo está construido pero las vitrinas están vacías. Gana algo y se irán llenando solas."
		vac.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_logros.add_child(vac)
	else:
		for p: Dictionary in piezas:
			var l := _texto(12, COL_ORO)
			l.text = "%s  %s" % [String(p["icono"]), String(p["titulo"])]
			_lista_logros.add_child(l)
			var d := _texto(10, COL_SUAVE)
			d.text = "     %s" % String(p["detalle"])
			d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_lista_logros.add_child(d)

	## EL COMPARADOR DE GENERACIONES. No compara jugadores uno a uno —eso sería
	## inventarse datos de gente retirada— sino la media del mejor plantel que
	## has tenido contra la del de ahora, que es la pregunta de verdad.
	var comp: Dictionary = lg.comparador_de_generaciones()
	if comp.is_empty():
		return
	var tc := _texto(11, COL_SUAVE)
	tc.text = "⚖️ AQUEL EQUIPO Y ESTE"
	_lista_logros.add_child(tc)
	_dato("Tu mejor plantilla", "%d  ·  quedó %d.º  ·  figura: %s" % [
		int(comp["anio"]), int(comp["puesto"]), String(comp["mvp"])], COL_ORO, _lista_logros)
	_dato("Media del plantel de hoy", "%.1f" % float(comp["media_actual"]), COL_TEXTO, _lista_logros)

## `vHistoria()`: el palmarés temporada a temporada y la foto de cada plantilla.
## `Logros.muro` guarda cada título con EL ONCE que lo levantó, y `planteles` la
## plantilla entera de cada año con su MVP. Las dos cosas se escribían desde el
## porte y no se veían: era memoria que el club acumulaba para nadie.
func _pintar_palmares_por_anio(lg: Logros) -> void:
	if lg.muro.is_empty() and lg.planteles.is_empty():
		return
	_lista_logros.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "📜 TEMPORADA A TEMPORADA"
	_lista_logros.add_child(t)
	## Se agrupan los títulos por año para que un año con tres copas salga en una
	## sola línea y no en tres: lo que se lee aquí es la HISTORIA, no el listado.
	var por_anio := {}
	for e: Dictionary in lg.muro:
		var a := int(e.get("anio", 0))
		if not por_anio.has(a):
			por_anio[a] = []
		(por_anio[a] as Array).append(String(e.get("titulo", "")))
	## De más reciente a más antiguo: lo que pasó el año pasado importa más.
	var anios := []
	for p: Dictionary in lg.planteles:
		anios.append(int(p.get("anio", 0)))
	for a2: int in por_anio:
		if not anios.has(a2):
			anios.append(a2)
	anios.sort()
	anios.reverse()
	for a3: int in anios:
		var titulos: Array = por_anio.get(a3, [])
		var puesto := ""
		var mvp := ""
		for p2: Dictionary in lg.planteles:
			if int(p2.get("anio", 0)) == a3:
				puesto = "%d.º" % int(p2.get("puesto", 0))
				mvp = String(p2.get("mvp", ""))
		var partes: Array[String] = []
		if puesto != "":
			partes.append(puesto)
		if not titulos.is_empty():
			partes.append("🏆 " + ", ".join(PackedStringArray(titulos)))
		if mvp != "":
			partes.append("figura: %s" % mvp)
		_dato(str(a3), "  ·  ".join(partes) if not partes.is_empty() else "—",
			COL_ORO if not titulos.is_empty() else COL_SUAVE, _lista_logros)

## LOS LOGROS OCULTOS. No se anuncian y no se listan: hasta que caen se ven como
## "???". Esa es toda la gracia —premian cosas que casi nunca pasan y que nadie
## va a perseguir porque no sabe que existen—, así que enseñar el enunciado los
## estropearía.
func _pintar_logros_ocultos(lg: Logros) -> void:
	var lista := lg.catalogo_oculto()
	if lista.is_empty():
		return
	_lista_logros.add_child(HSeparator.new())
	var caidos := 0
	for f: Dictionary in lista:
		if bool(f["conseguido"]):
			caidos += 1
	var t := _texto(11, COL_SUAVE)
	t.text = "🎖️ LOGROS OCULTOS  ·  %d/%d" % [caidos, lista.size()]
	_lista_logros.add_child(t)
	var ex := _texto(10, COL_SUAVE)
	ex.text = "Estos no se anuncian: aparecen solos cuando pasa algo que casi nunca pasa."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_logros.add_child(ex)
	for f2: Dictionary in lista:
		var hecho := bool(f2["conseguido"])
		var l := _texto(12, COL_ORO if hecho else COL_SUAVE)
		l.text = "%s  %s — %s" % ["🎖️" if hecho else "❔", String(f2["titulo"]), String(f2["descripcion"])]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_logros.add_child(l)

## EL RANKING DE CANTERAS. Mide quién forma de verdad -cantidad Y techo juntos-
## y, sobre todo, dónde estás tú. Es la única pantalla del juego que compara tu
## trabajo de cantera con el de los otros 383 clubes.
func _pintar_ranking_canteras() -> void:
	if mundo.cantera == null:
		return
	var r := mundo.cantera.ranking_canteras()
	if r.is_empty():
		return
	_lista_logros.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "🌱 RANKING DE CANTERAS"
	_lista_logros.add_child(t)
	var mio := mundo.mi_club()
	var mi_puesto := 0
	for i in r.size():
		if (r[i] as Dictionary)["club"] == mio:
			mi_puesto = i + 1
	for i in mini(10, r.size()):
		var f: Dictionary = r[i]
		var c: Club = f["club"]
		var propio := c == mio
		_dato("%d.  %s" % [i + 1, c.nombre],
			"%d juveniles  ·  %d" % [int(f["juveniles"]), int(f["nota"])],
			COL_ACENTO if propio else COL_TEXTO, _lista_logros)
	## Si no estás entre los diez, se dice en qué puesto estás: un ranking en el
	## que no te encuentras no sirve de nada.
	if mi_puesto > 10:
		var p := _texto(11, COL_ACENTO)
		p.text = "Tu club va %d.º de %d." % [mi_puesto, r.size()]
		_lista_logros.add_child(p)

## La copa continental: en qué torneo estás y cómo va.
func _pintar_conti(c: Club) -> void:
	_limpiar(_lista_conti)
	if mundo.continentales.is_empty():
		var vacio := _texto(12, COL_SUAVE)
		vacio.text = "Las copas continentales se sortean al empezar la temporada."
		_lista_conti.add_child(vacio)
		return
	var mia := mundo.mi_continental()
	for k: String in mundo.continentales:
		var t: Continental = mundo.continentales[k]
		var propia := t == mia
		var cab := _texto(13, COL_ACENTO if propia else COL_SUAVE)
		var estado := ("campeón: " + t.campeon.nombre) if t.campeon != null else t.nombre_de_ronda()
		cab.text = "%s%s  —  %s" % ["> " if propia else "   ", Continental.nombre_conti(k), estado]
		_lista_conti.add_child(cab)
		if not propia:
			continue
		if t.en_fase_de_grupos():
			for i in t.grupos.size():
				var g := _texto(11, COL_SUAVE)
				g.text = "  " + t.nombre_de_grupo(i)
				_lista_conti.add_child(g)
				for fila: Dictionary in t.tabla_de_grupo(i):
					var club: Club = fila["club"]
					var l := _texto(12, COL_ACENTO if club == c else COL_TEXTO)
					l.text = "    %s  ·  %d pts" % [club.nombre, int(fila.get("pts", 0))]
					_lista_conti.add_child(l)
		var cruce := t.emparejamiento_de(c)
		if cruce.size() == 2:
			var l2 := _texto(12, COL_VERDE)
			l2.text = "  Te toca: %s  vs  %s" % [cruce[0].nombre, cruce[1].nombre]
			_lista_conti.add_child(l2)
		var prem := _texto(11, COL_ORO)
		prem.text = "  Premio al campeón: %s  (fijo, no escalado al tamaño del club)" % _dinero(t.premio)
		_lista_conti.add_child(prem)

## Las obras del club, dentro de la pestaña Club.
##
## Se enseña el nivel, lo que hace, lo que cuesta y —si está en marcha— cuántas
## semanas faltan. Ese último dato es el que hace que el sistema tenga sentido:
## las obras no son instantáneas a propósito, así que hay que poder ver en qué
## punto va cada una para decidir qué se empieza después.
func _pintar_obras(c: Club) -> void:
	_lista_club.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "OBRAS  ·  %d niveles construidos  ·  aforo %s" % [
		mundo.obras.construido(), _miles(c.estadio_aforo)]
	_lista_club.add_child(t)
	if not mundo.obras.obras.is_empty():
		for k: String in mundo.obras.obras:
			var falta := int(mundo.obras.obras[k])
			var l := _texto(12, COL_ORO)
			l.text = "  En obra: %s  —  %d semana%s" % [
				String(Instalaciones.CATALOGO[k][0]), falta, "" if falta == 1 else "s"]
			_lista_club.add_child(l)
	for clave: String in Instalaciones.CATALOGO:
		var datos: Array = Instalaciones.CATALOGO[clave]
		var n := mundo.obras.nivel(clave)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		_lista_club.add_child(fila)
		var nom := _texto(12, COL_TEXTO)
		nom.text = "%s  %s" % ["*".repeat(n) + ".".repeat(mundo.obras.maximo(clave) - n), String(datos[0])]
		if n > 0:
			nom.tooltip_text = Trabajadores.texto_de(c, clave)
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(nom)
		if mundo.obras.en_obra(clave):
			var enc := _texto(11, COL_ORO)
			enc.text = "en obra"
			fila.add_child(enc)
		elif n >= mundo.obras.maximo(clave):
			var tope := _texto(11, COL_VERDE)
			tope.text = "al máximo"
			fila.add_child(tope)
		else:
			var precio := mundo.obras.coste(clave, c.rep)
			var b := Button.new()
			b.text = "Construir  %s  (%d sem)" % [_dinero(precio), mundo.obras.semanas_de(clave)]
			b.add_theme_font_size_override("font_size", 11)
			b.disabled = precio > c.saldo or (mundo.roles != null and not mundo.roles.puede_construir())
			b.pressed.connect(func() -> void: _empezar_obra(clave))
			fila.add_child(b)
		var que := _texto(11, COL_SUAVE)
		que.text = "    " + String(datos[1])
		if n > 0 and mundo.trabajadores != null:
			## El equipo entero, con habilidad y ánimo (26-9-2026).
			que.text += "\n    👥 " + mundo.trabajadores.texto_equipo(c, mundo.obras, clave).replace("\n", "\n    👥 ")
		que.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_club.add_child(que)

## Devuelve "" si arrancó o el motivo. La usan el panel y el mapa 3D (B7).
func _empezar_obra(clave: String) -> String:
	if mundo.roles != null and not mundo.roles.puede_construir():
		return "tu cargo no puede autorizar obras"
	var problema := mundo.obras.iniciar(clave, mundo.mi_club())
	if problema != "":
		_escribir("[color=#e05555]No se puede empezar la obra: %s.[/color]" % problema)
		return problema
	var datos: Array = Instalaciones.CATALOGO[clave]
	_escribir("[color=#c9a227]Obra iniciada:[/color] %s, nivel %d. Estará lista en %d semanas." % [
		String(datos[0]), mundo.obras.nivel(clave) + 1, mundo.obras.semanas_de(clave)])
	_refrescar()
	return ""

## Un escudo con sus iniciales encima, listo para meter en una fila.
##
## Las letras van FUERA del SVG porque el rasterizador de Godot no dibuja
## `<text>`: un SVG con texto carga sin error y sale sin las letras. Puestas
## como etiqueta encima quedan además más nítidas y con el color correcto según
## lo claro u oscuro que sea el escudo.
func _escudo(c: Club, alto: int = 22) -> Control:
	var caja := Control.new()
	caja.custom_minimum_size = Vector2(alto, alto)
	var t := TextureRect.new()
	t.texture = Escudo.textura(c, alto)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.add_child(t)
	var l := Label.new()
	## EL SÍMBOLO ("ESC_SIM" del HTML) REEMPLAZA A LAS INICIALES, no se suman
	## las dos cosas -mismo "sym ? ... : ini" del HTML-. Es un emoji, así que
	## tampoco necesita el color de contraste que sí hace falta para que dos
	## letras se lean sobre cualquier fondo de escudo.
	var simbolo := Escudo.simbolo_de(c)
	if simbolo != "":
		l.text = simbolo
		l.add_theme_font_size_override("font_size", maxi(9, int(float(alto) * 0.55)))
	else:
		l.text = Escudo.iniciales(c)
		l.add_theme_font_size_override("font_size", maxi(8, alto / 2 - 2))
		l.add_theme_color_override("font_color", _tinta(Color(c.color1)))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	## Las iniciales se suben un poco: el escudo es más alto que ancho y en el
	## centro geométrico quedan bajas respecto al centro visual.
	l.offset_top = -float(alto) * 0.10
	caja.add_child(l)
	return caja

## Blanco o negro sobre el color del escudo, según su luminosidad. Es el `lumTx`
## del HTML: sin esto, las iniciales de un club amarillo se leen en blanco y
## desaparecen.
func _tinta(fondo: Color) -> Color:
	var lum := 0.299 * fondo.r + 0.587 * fondo.g + 0.114 * fondo.b
	return Color("0c130e") if lum > 0.59 else Color("ffffff")

## EL LOGO DE UN SPONSOR, mismo patrón que `_escudo()` de arriba: la textura
## de `Marca` debajo y las iniciales encima con el color de contraste que
## corresponda. Antes de esto un sponsor era solo una palabra pintada del
## color de la tabla -ver la nota de `Marca` para el porqué-.
func _marca(nombre: String, color_hex: String, alto: int = 28) -> Control:
	var caja := Control.new()
	caja.custom_minimum_size = Vector2(alto, alto)
	var t := TextureRect.new()
	t.texture = Marca.textura(nombre, color_hex, alto)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.add_child(t)
	var l := Label.new()
	l.text = Marca.iniciales(nombre)
	l.add_theme_font_size_override("font_size", maxi(8, alto / 2 - 2))
	l.add_theme_color_override("font_color", _tinta(Color(color_hex)))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.add_child(l)
	return caja

# --- las cuatro pantallas que faltaban -------------------------------------
#
# Cuatro sistemas enteros estaban en el motor, probados y guardados, y no se
# podían tocar jugando. Un sistema sin pantalla no existe para quien juega, por
# muy bien que funcione por dentro.

## EL DESPACHO DEL ENTRENADOR: el plan de la semana y el árbol de habilidades.
## `vEntrenoPlus()` del HTML, la parte que faltaba: la PRETEMPORADA y la
## CONCENTRACIÓN de la semana. `Entrenamiento.elegir_pretemporada()` estaba
## escrita entera -con su coste, sus efectos de físico y base, y su riesgo de
## romper a alguien- y no la llamaba ninguna pantalla; `concentracion` lo mismo:
## el proceso semanal ya la cobraba y daba +3 de físico, pero no había forma de
## encenderla. Dos decisiones de gestión escritas y apagadas.
func _pintar_pretemporada(c: Club, e: Entrenamiento) -> void:
	var t := _texto(11, COL_SUAVE)
	t.text = "PRETEMPORADA"
	_lista_entren.add_child(t)
	if e.pretemporada != "":
		var hecha := _texto(12, COL_VERDE)
		var nombre_p := e.pretemporada
		for fila: Array in e.pretemporadas():
			if String(fila[0]) == e.pretemporada:
				nombre_p = String(fila[1])
		hecha.text = "Ya hecha este año: %s. La próxima, la temporada que viene." % nombre_p
		hecha.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_entren.add_child(hecha)
	else:
		for fila: Array in e.pretemporadas():
			var clave := String(fila[0])
			var coste := Eco.escalar(float(fila[2]), float(c.rep)) if float(fila[2]) > 0.0 else 0
			var fila_p := HBoxContainer.new()
			fila_p.add_theme_constant_override("separation", 8)
			_lista_entren.add_child(fila_p)
			var lp := _texto(12, COL_TEXTO)
			lp.text = String(fila[1])
			lp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila_p.add_child(lp)
			var bp := Button.new()
			bp.text = "Elegir" if coste == 0 else "Elegir  %s" % _dinero(coste)
			bp.add_theme_font_size_override("font_size", 11)
			bp.disabled = coste > c.saldo
			bp.pressed.connect(func() -> void: _elegir_pretemporada(clave, c))
			fila_p.add_child(bp)
			var dp := _texto(10, COL_SUAVE)
			dp.text = String(fila[3])
			dp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_lista_entren.add_child(dp)

	## La concentración: se paga cada semana y da físico. Es un grifo abierto,
	## así que se enseña lo que cuesta al lado del interruptor.
	var fila_c := HBoxContainer.new()
	fila_c.add_theme_constant_override("separation", 8)
	_lista_entren.add_child(fila_c)
	var lc := _texto(12, COL_TEXTO if e.concentracion else COL_SUAVE)
	lc.text = "Concentrar al plantel cada semana  ·  %s" % _dinero(Eco.escalar(Entrenamiento.COSTE_CONCENTRACION, float(c.rep)))
	lc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila_c.add_child(lc)
	var bc := Button.new()
	bc.text = "SÍ" if e.concentracion else "NO"
	bc.add_theme_font_size_override("font_size", 11)
	bc.pressed.connect(func() -> void:
		e.concentracion = not e.concentracion
		_refrescar())
	fila_c.add_child(bc)
	var dc := _texto(10, COL_SUAVE)
	dc.text = "Hotel y trabajo aislado toda la semana: tres puntos de físico para todos, todas las semanas que la dejes puesta."
	dc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_entren.add_child(dc)
	_lista_entren.add_child(HSeparator.new())

func _elegir_pretemporada(clave: String, c: Club) -> void:
	var err := mundo.entrenamiento.elegir_pretemporada(clave, c, mundo.anio, mundo.semana)
	if err != "":
		_escribir("[color=#e05555]No se pudo: %s.[/color]" % err)
	else:
		_escribir("[color=#4caf6d][b]Pretemporada elegida.[/b][/color] El plantel arranca el año con ella.")
	_refrescar()

## MENTORÍAS: un veterano apadrina a un chico. Es lo que hace que un jugador de
## 33 que ya no es titular siga valiendo para algo -y la única forma de que un
## canterano crezca más rápido de lo que le toca-.
func _pintar_mentorias(c: Club, e: Entrenamiento) -> void:
	var t := _texto(11, COL_SUAVE)
	t.text = "MENTORÍAS  ·  %d de %d" % [e.mentorias.size(), Entrenamiento.MAX_MENTORIAS]
	_lista_entren.add_child(t)
	for i in e.mentorias.size():
		var m: Dictionary = e.mentorias[i]
		var maestro := mundo.jugador_por_id(String(m["maestro"]))
		var pupilo := mundo.jugador_por_id(String(m["pupilo"]))
		if maestro == null or pupilo == null:
			continue
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		_lista_entren.add_child(fila)
		## Las dos caras, maestro y pupilo: la pareja se entiende de un vistazo.
		fila.add_child(_retrato(maestro, 24))
		fila.add_child(_retrato(pupilo, 24))
		var l := _texto(12, COL_TEXTO)
		l.text = "%s (%d) → %s (%d)  ·  %d semanas, +%d de media" % [
			maestro.nombre, maestro.ovr, pupilo.nombre, pupilo.ovr,
			int(m["semanas"]), int(m["subidas"])]
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(l)
		var idx := i
		_boton("Romper", func() -> void:
			e.romper_mentoria(idx)
			_refrescar(), fila)
	## Para crear una hace falta elegir dos: se usa el jugador seleccionado en la
	## ficha como una de las dos mitades, que es la forma de no inventar un
	## selector nuevo en una pantalla que ya tiene bastante.
	if e.mentorias.size() < Entrenamiento.MAX_MENTORIAS:
		if _seleccionado == null or _seleccionado.club_id != c.id:
			var pista := _texto(11, COL_SUAVE)
			pista.text = "Para crear una: pulsa en el plantel a un veterano (%d+ años y %d+ de media) o a un chico (hasta %d), y aquí aparecerá con quién emparejarlo." % [
				Entrenamiento.MENTOR_EDAD, Entrenamiento.MENTOR_MEDIA, Entrenamiento.PUPILO_EDAD]
			pista.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_lista_entren.add_child(pista)
		else:
			var sel := _seleccionado
			var es_mentor := e.puede_ser_mentor(sel)
			var es_pupilo := e.puede_ser_pupilo(sel)
			if not es_mentor and not es_pupilo:
				var no := _texto(11, COL_SUAVE)
				no.text = "%s no puede ser ni maestro (%d+ años y %d+ de media) ni pupilo (hasta %d años)." % [
					sel.nombre, Entrenamiento.MENTOR_EDAD, Entrenamiento.MENTOR_MEDIA, Entrenamiento.PUPILO_EDAD]
				no.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				_lista_entren.add_child(no)
			else:
				var papel := "maestro" if es_mentor else "pupilo"
				var tp := _texto(11, COL_SUAVE)
				tp.text = "%s puede ser %s. Empareja con:" % [sel.nombre, papel]
				_lista_entren.add_child(tp)
				for otro: Jugador in c.plantilla:
					var vale := e.puede_ser_pupilo(otro) if es_mentor else e.puede_ser_mentor(otro)
					if not vale or otro == sel:
						continue
					var fila2 := HBoxContainer.new()
					fila2.add_theme_constant_override("separation", 8)
					_lista_entren.add_child(fila2)
					var l2 := _texto(12, COL_SUAVE)
					l2.text = "%s  ·  %d años  ·  media %d" % [otro.nombre, otro.edad, otro.ovr]
					l2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					fila2.add_child(l2)
					var maestro_f: Jugador = sel if es_mentor else otro
					var pupilo_f: Jugador = otro if es_mentor else sel
					_boton("Emparejar", func() -> void:
						var err := e.crear_mentoria(maestro_f, pupilo_f)
						if err != "":
							_escribir("[color=#e05555]No se pudo: %s.[/color]" % err)
						_refrescar(), fila2)
	_lista_entren.add_child(HSeparator.new())

## `🎓 ENTRENAMIENTO INDIVIDUAL` del HTML: trabajo específico de cinco a nueve
## semanas para que un jugador aprenda una habilidad de verdad -no puntos de
## entrenador, una habilidad del catálogo `ESPECIALES`-. El motor
## (`asignar_individual`/`plan_de`/`especial`, resuelto cada semana en
## `_trabajo_individual()`) llevaba escrito desde siempre; esta pantalla es la
## que le faltaba.
func _pintar_entrenamiento_individual(c: Club, e: Entrenamiento) -> void:
	_lista_entren.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "🎓 ENTRENAMIENTO INDIVIDUAL  (%d/%d)" % [e.individual.size(), Entrenamiento.MAX_INDIVIDUALES]
	_lista_entren.add_child(t)
	var intro := _texto(10, COL_SUAVE)
	intro.text = "Trabajo específico para un jugador concreto. En cinco a nueve semanas aprende una habilidad nueva de verdad."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_entren.add_child(intro)
	## Los que ya tienen plan, con su progreso -igual que el HTML, arriba de la
	## lista de asignar-.
	for j: Jugador in c.plantilla:
		var plan := e.plan_de(j)
		if plan.is_empty():
			continue
		var esp := e.especial(String(plan.get("clave", "")))
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		_lista_entren.add_child(fila)
		var et := _texto(11, COL_TEXTO)
		et.text = "%s — %s" % [j.nombre, String(esp[1]) if esp.size() > 1 else String(plan["clave"])]
		et.clip_text = true
		et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(et)
		var sem := _texto(11, COL_SUAVE)
		sem.text = "%d sem" % int(plan.get("semanas", 0))
		fila.add_child(sem)
		var bc := Button.new()
		bc.text = "Cancelar"
		bc.add_theme_font_size_override("font_size", 11)
		bc.pressed.connect(func() -> void:
			mundo.entrenamiento.asignar_individual(j, String(plan["clave"]))
			_refrescar())
		fila.add_child(bc)
	## A quién asignar: los catorce con más margen hasta su potencial -no solo
	## los jóvenes, cualquiera que todavía pueda crecer-, igual que `vEntreno()`.
	var tg := _texto(11, COL_SUAVE)
	tg.text = "ASIGNAR A UN JUGADOR"
	_lista_entren.add_child(tg)
	var candidatos := c.plantilla.duplicate()
	candidatos.sort_custom(func(a: Jugador, b: Jugador) -> bool: return (b.pot - b.ovr) < (a.pot - a.ovr))
	var lleno := e.individual.size() >= Entrenamiento.MAX_INDIVIDUALES
	for j: Jugador in candidatos.slice(0, 14):
		var plan_j := e.plan_de(j)
		var fila_j := HBoxContainer.new()
		fila_j.add_theme_constant_override("separation", 6)
		_lista_entren.add_child(fila_j)
		var nom := _texto(11, COL_SUAVE)
		nom.text = "%s  (%d años · %d→%d)" % [j.nombre, j.edad, j.ovr, j.pot]
		nom.clip_text = true
		nom.custom_minimum_size = Vector2(170, 0)
		fila_j.add_child(nom)
		var flow_j := HFlowContainer.new()
		flow_j.add_theme_constant_override("h_separation", 4)
		flow_j.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila_j.add_child(flow_j)
		for esp2: Array in e.especiales():
			var clave2 := String(esp2[0])
			var be := Button.new()
			be.text = String(esp2[1])
			be.tooltip_text = String(esp2[2]) if esp2.size() > 2 else ""
			be.add_theme_font_size_override("font_size", 10)
			be.toggle_mode = true
			be.button_pressed = (String(plan_j.get("clave", "")) == clave2)
			be.disabled = lleno and plan_j.is_empty()
			be.pressed.connect(func() -> void:
				mundo.entrenamiento.asignar_individual(j, clave2)
				_refrescar())
			flow_j.add_child(be)

## LA ESTACIÓN, EL CLIMA Y EL HORARIO, de `vEntrenoPlus()`. Tres cosas pequeñas
## que juntas hacen que una temporada no sean cuarenta y dos semanas iguales.
##
## El horario es la única que es una DECISIÓN, y de las buenas: cuanto más paga
## la televisión, menos gente va al estadio. No hay opción correcta —depende de
## si te falta caja o te sobra— y eso es exactamente lo que se busca.
func _pintar_ambiente_y_horario() -> void:
	var est := mundo.estacion()
	var t := _texto(11, COL_SUAVE)
	t.text = "LA SEMANA"
	_lista_entren.add_child(t)
	_dato("Estación", "%s %s" % [String(est[1]), String(est[0]).capitalize()], COL_TEXTO, _lista_entren)
	_dato("Tiempo previsto", mundo.clima().capitalize(), COL_TEXTO, _lista_entren)

	var th := _texto(11, COL_SUAVE)
	th.text = "HORARIO DEL PARTIDO EN CASA"
	_lista_entren.add_child(th)
	for h: Array in Mundo.HORARIOS:
		var clave := String(h[0])
		var elegido := mundo.horario == clave
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_lista_entren.add_child(fila)
		var b := Button.new()
		b.text = "%s  ·  %s" % [String(h[1]), String(h[2])]
		b.toggle_mode = true
		b.button_pressed = elegido
		b.add_theme_font_size_override("font_size", 11)
		b.clip_text = true
		b.custom_minimum_size = Vector2(200, 0)
		b.pressed.connect(func() -> void:
			mundo.horario = clave
			_refrescar())
		fila.add_child(b)
		## Los dos números que importan, uno al lado del otro: es la única forma
		## de que la decisión se vea como lo que es, un intercambio.
		var pub := _texto(11, COL_VERDE if float(h[3]) >= 1.0 else COL_ROJO)
		pub.text = "público ×%.2f" % float(h[3])
		pub.custom_minimum_size = Vector2(90, 0)
		fila.add_child(pub)
		var tv := _texto(11, COL_VERDE if float(h[4]) > 1.0 else COL_SUAVE)
		tv.text = "TV ×%.2f" % float(h[4])
		tv.custom_minimum_size = Vector2(70, 0)
		fila.add_child(tv)
		var d := _texto(10, COL_SUAVE)
		d.text = String(h[5])
		d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		d.clip_text = true
		## La nota de cada horario es una frase completa ("El horario de la
		## tarde..."), y en una columna angosta se corta a media palabra sin
		## avisar -encontrado con una captura real, queja del usuario ("se
		## siente recortada")-. El tooltip es la frase entera, como ya manda
		## la regla de "clip_text siempre con su texto de repuesto".
		d.tooltip_text = String(h[5])
		fila.add_child(d)
	_lista_entren.add_child(HSeparator.new())

## LA PRETEMPORADA. Tres formas de llegar a la primera jornada, y hay que elegir
## una: el triangular en casa es gratis y da poco, la gira internacional cuesta
## y se paga sola si el club es grande, y los amistosos con la cantera dan menos
## forma al primer equipo y el doble a los chicos.
##
## Existe porque el hueco entre temporadas era un botón de «siguiente» donde no
## pasaba nada, y llegar a la primera jornada con el plantel frío no se podía
## evitar de ninguna manera.
func _pintar_amistosos(c: Club) -> void:
	_lista_entren.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "🧳 PRETEMPORADA"
	_lista_entren.add_child(t)
	if mundo.amistoso_hecho:
		var ya := _texto(11, COL_VERDE)
		ya.text = "✔ Pretemporada jugada. La próxima, al empezar el año que viene."
		ya.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_entren.add_child(ya)
		return
	if not _modo_experto:
		var ex := _texto(10, COL_SUAVE)
		ex.text = "Una por temporada. No da puntos: da FORMA, que es lo que le falta a un plantel que lleva un mes parado."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_entren.add_child(ex)
	for a: Array in Mundo.AMISTOSOS:
		var clave := String(a[0])
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_lista_entren.add_child(fila)
		var n := _texto(12, COL_TEXTO)
		n.text = String(a[1])
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		fila.add_child(n)
		var f := _texto(11, COL_ORO)
		f.text = "+%d forma" % int(a[3])
		f.custom_minimum_size = Vector2(78, 0)
		fila.add_child(f)
		var b := Button.new()
		var coste := Eco.escalar(float(a[2]), float(c.rep)) if float(a[2]) > 0.0 else 0
		b.text = "gratis" if coste == 0 else _dinero(coste)
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = coste > c.saldo
		b.custom_minimum_size = Vector2(104, 0)
		b.pressed.connect(func() -> void:
			var p := mundo.jugar_amistosos(clave)
			if p != "":
				_escribir("[color=#e05555]No se pudo: %s.[/color]" % p)
			_refrescar())
		fila.add_child(b)

func _pintar_entrenamiento(c: Club) -> void:
	_limpiar(_lista_entren)
	var e := mundo.entrenamiento
	if e == null:
		return
	_pintar_ambiente_y_horario()
	_pintar_pretemporada(c, e)
	_pintar_mentorias(c, e)
	_pintar_entrenamiento_individual(c, e)
	_pintar_amistosos(c)

	## LA ROTACIÓN Y EL VIDEOANÁLISIS. Los dos son preparación: se deciden antes
	## de saber cómo va el partido, que es lo que los diferencia de todo lo demás
	## de esta pantalla.
	_lista_entren.add_child(HSeparator.new())
	var tr := _texto(11, COL_SUAVE)
	tr.text = "🔁 ROTACIÓN Y VIDEOANÁLISIS"
	_lista_entren.add_child(tr)
	var fila_r := HBoxContainer.new()
	fila_r.add_theme_constant_override("separation", 8)
	_lista_entren.add_child(fila_r)
	var et_r := _texto(12, COL_TEXTO)
	et_r.text = "Rotación automática"
	et_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et_r.tooltip_text = "En las semanas cargadas, los que lleguen por debajo de %d de físico dejan sitio a los frescos de su puesto." % Mundo.FISICO_PARA_TITULAR
	fila_r.add_child(et_r)
	var b_r := Button.new()
	b_r.text = "SÍ" if mundo.rotacion_activa else "NO"
	b_r.pressed.connect(func() -> void:
		mundo.rotacion_activa = not mundo.rotacion_activa
		_refrescar())
	fila_r.add_child(b_r)
	if not _modo_experto:
		var ex_r := _texto(10, COL_SUAVE)
		ex_r.text = "Con liga, copa y continental en la misma quincena, el plantel llega a treinta de físico y no hay forma de evitarlo alineando a mano cada jornada."
		ex_r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_entren.add_child(ex_r)

	var b_v := Button.new()
	b_v.text = "📽️ Videoanálisis del rival de esta semana" if mundo.puede_analizar() \
		else "📽️ Videoanálisis (hecho hace poco)"
	b_v.add_theme_font_size_override("font_size", 11)
	b_v.disabled = not mundo.puede_analizar()
	b_v.tooltip_text = "Cuesta dos de físico a todo el plantel y da un empujón para ESTE partido. Contra un rival mejor que tú vale más."
	b_v.pressed.connect(func() -> void:
		var p := mundo.analizar_rival()
		if p != "":
			_escribir("[color=#e05555]No se puede: %s.[/color]" % p)
		_refrescar())
	_lista_entren.add_child(b_v)
	if mundo.bono_analisis > 1.0:
		_dato("Lección hecha", "+%d%% para el próximo partido" % int(round((mundo.bono_analisis - 1.0) * 100.0)),
			COL_VERDE, _lista_entren)

	## Lo primero, el resumen de lo que le estás haciendo al plantel esta semana.
	## Es el único número honesto del menú: todo lo demás son etiquetas bonitas.
	var carga: Dictionary = e.carga()
	var t := _texto(11, COL_SUAVE)
	t.text = "PLAN DE LA SEMANA"
	_lista_entren.add_child(t)
	var res := _texto(12, COL_ROJO if float(carga["riesgo"]) > 9.0 else (COL_ORO if float(carga["riesgo"]) > 7.0 else COL_VERDE))
	res.text = "Físico %+.1f  ·  progreso %+.1f  ·  riesgo de lesión %.1f  ·  moral %+.1f" % [
		float(carga["fis"]), float(carga["ovr"]), float(carga["riesgo"]), float(carga["moral"])]
	res.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_entren.add_child(res)

	_perilla_texto(_lista_entren, "Foco", Entrenamiento.FOCOS, e.foco,
		func(k: String) -> void:
			e.fijar_foco(k)
			_refrescar())
	_perilla_texto(_lista_entren, "Intensidad", Entrenamiento.INTENSIDADES, e.intensidad,
		func(k: String) -> void:
			e.fijar_intensidad(k)
			_refrescar())

	## Los días de la semana. Cada uno con su bloque, y se cambia pulsando.
	_lista_entren.add_child(HSeparator.new())
	var dias: Array = e.nombres_de_dias()
	var catalogo: Array = e.bloques()
	for i in e.dias.size():
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_lista_entren.add_child(fila)
		var dia := _texto(11, COL_SUAVE)
		dia.text = String(dias[i]) if i < dias.size() else "Día %d" % (i + 1)
		dia.custom_minimum_size = Vector2(80, 0)
		fila.add_child(dia)
		var b := OptionButton.new()
		b.add_theme_font_size_override("font_size", 11)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for k in catalogo.size():
			var f: Array = catalogo[k]
			b.add_item("%s  %s" % [String(f[2]), String(f[1])])
			b.set_item_metadata(k, String(f[0]))
			if String(f[0]) == e.dias[i]:
				b.select(k)
		b.item_selected.connect(func(idx: int) -> void:
			e.fijar_dia(i, String(b.get_item_metadata(idx)))
			_refrescar())
		fila.add_child(b)

	## Y el árbol de habilidades del jugador seleccionado. Va aquí y no en la
	## ficha porque es una decisión de entrenamiento, no un dato del jugador.
	_lista_entren.add_child(HSeparator.new())
	var t2 := _texto(11, COL_SUAVE)
	if _seleccionado == null:
		t2.text = "HABILIDADES  ·  elige un jugador en el plantel"
		_lista_entren.add_child(t2)
		return
	var j := _seleccionado
	t2.text = "HABILIDADES DE %s  ·  %d punto%s" % [
		j.nombre.to_upper(), e.puntos(j), "" if e.puntos(j) == 1 else "s"]
	_lista_entren.add_child(t2)
	var suyas: Array = e.habilidades(j)
	if not suyas.is_empty():
		var ya := _texto(12, COL_VERDE)
		var nombres: Array[String] = []
		for k: String in suyas:
			nombres.append(e.nombre_habilidad(k))
		ya.text = "Ya sabe: " + ", ".join(nombres)
		ya.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_entren.add_child(ya)
	for clave: String in e.disponibles(j):
		var fila2 := HBoxContainer.new()
		fila2.add_theme_constant_override("separation", 8)
		_lista_entren.add_child(fila2)
		var nom := _texto(12, COL_TEXTO)
		nom.text = e.nombre_habilidad(clave)
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila2.add_child(nom)
		var motivo := e.motivo(j, clave)
		if motivo == "":
			var b2 := Button.new()
			b2.text = "Aprender"
			b2.add_theme_font_size_override("font_size", 11)
			b2.pressed.connect(func() -> void: _aprender(j, clave))
			fila2.add_child(b2)
		else:
			## Se dice POR QUÉ no puede, no solo que no puede: sin el motivo, el
			## jugador prueba a ciegas y el árbol parece roto.
			var no := _texto(11, COL_SUAVE)
			no.text = motivo
			fila2.add_child(no)

func _aprender(j: Jugador, clave: String) -> void:
	var problema := mundo.entrenamiento.aprender(j, clave)
	if problema != "":
		_escribir("[color=#e05555]No puede aprenderla: %s.[/color]" % problema)
		return
	_escribir("[color=#4caf6d]%s aprende %s.[/color]" % [
		j.nombre, mundo.entrenamiento.nombre_habilidad(clave)])
	_refrescar()

## Una perilla de tres o más opciones a partir de un diccionario clave -> [nombre, ...].
func _perilla_texto(padre: VBoxContainer, etiqueta: String, catalogo: Dictionary,
		actual: String, al_cambiar: Callable) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	padre.add_child(h)
	var l := _texto(11, COL_SUAVE)
	l.text = etiqueta
	l.custom_minimum_size = Vector2(80, 0)
	h.add_child(l)
	for k: String in catalogo:
		var datos: Array = catalogo[k]
		var b := Button.new()
		b.text = String(datos[0])
		b.toggle_mode = true
		b.button_pressed = (k == actual)
		b.add_theme_font_size_override("font_size", 11)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void: al_cambiar.call(k))
		h.add_child(b)

## LA FEDERACIÓN: el reglamento vigente y la votación pendiente.
## `vFederacion()` del HTML tiene cuatro bloques y en Godot solo se veía uno
## (reglamento y votación). Los otros tres estaban ESCRITOS Y CORRIENDO en
## `federacion.gd` desde hace tiempo, sin una sola línea que los enseñara:
## `requisitos_licencia()`/`auditoria_anual()` (te pueden denegar la licencia y
## dejarte sin cupo internacional), `casos`/`apelar()` (el tribunal) y
## `controles` (antidopaje). El caso más sangrante: al abrir un caso, el propio
## motor emite la noticia "Puedes apelar desde Federación" -una pantalla que no
## existía-. Le prometía al jugador algo que no podía cumplir.
## EL HISTORIAL DE LA FEDERACIÓN: cómo has votado y cómo te tratan los árbitros.
## `Federacion` guardaba las dos cosas desde el porte —`votos` y
## `enojo_arbitral`— y no se veían por ningún lado, así que el jugador no podía
## saber por qué le pitaban cada vez peor.
func _pintar_historial_federacion(f: Federacion) -> void:
	_lista_fed.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "RELACIÓN CON EL ARBITRAJE"
	_lista_fed.add_child(t)
	## El enojo arbitral sube cada vez que apelas y pierdes, y baja la
	## probabilidad de que te acojan la siguiente. Es un coste ACUMULADO y
	## escondido: verlo es lo que hace que apelar sea una decisión y no un botón.
	var e := f.enojo_arbitral
	_dato("Apelaciones perdidas acumuladas", str(e),
		COL_ROJO if e >= 3 else (COL_ORO if e > 0 else COL_VERDE), _lista_fed)
	var frase := _texto(11, COL_SUAVE)
	if e == 0:
		frase.text = "El tribunal no tiene nada anotado contra el club. Las apelaciones salen a precio normal."
	elif e < 3:
		frase.text = "Ya han quedado constancias de que el club recurre. Cada apelación nueva es un poco más difícil."
	else:
		frase.text = "El tribunal considera que el club abusa del recurso: apelar ahora sale muy caro y casi nunca prospera."
	frase.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_fed.add_child(frase)
	_dato("Peso político en la asamblea", str(f.aliados),
		COL_VERDE if f.aliados > 0 else (COL_ROJO if f.aliados < 0 else COL_SUAVE), _lista_fed)

	if f.votos.is_empty():
		return
	_lista_fed.add_child(HSeparator.new())
	var tv := _texto(11, COL_SUAVE)
	tv.text = "HISTORIAL DE VOTACIONES"
	_lista_fed.add_child(tv)
	for i in mini(8, f.votos.size()):
		var v: Dictionary = f.votos[i]
		var paso := bool(v.get("pasa", false))
		var vote_a := bool(v.get("vote_a", false))
		## Lo interesante no es si la moción pasó, sino si TÚ estabas del lado
		## que ganó: eso es lo que mide tu peso real en la liga.
		var acerte := paso == vote_a
		_dato(String(v.get("t", "")),
			"%s  ·  %s" % ["aprobada" if paso else "rechazada", "votaste a favor" if vote_a else "votaste en contra"],
			COL_VERDE if acerte else COL_SUAVE, _lista_fed)

func _pintar_licencia_y_tribunal(c: Club, f: Federacion) -> void:
	var col_lic := COL_VERDE
	if f.licencia == "condicional":
		col_lic = COL_ORO
	elif f.licencia == "denegada":
		col_lic = COL_ROJO
	var tl := _texto(11, COL_SUAVE)
	tl.text = "LICENCIA DE CLUB"
	_lista_fed.add_child(tl)
	var est := _texto(14, col_lic)
	est.text = f.licencia.to_upper()
	_lista_fed.add_child(est)
	var cumple := 0
	var reqs := f.requisitos_licencia(c, mundo.obras)
	for r: Dictionary in reqs:
		var ok := bool(r["ok"])
		if ok:
			cumple += 1
		_dato("%s  %s" % ["✅" if ok else "❌", String(r["t"])], String(r["det"]),
			COL_VERDE if ok else COL_ROJO, _lista_fed)
	var resumen := _texto(11, COL_SUAVE)
	resumen.text = "Cumples %d de %d requisitos. Uno o dos incumplimientos son un aviso y te dejan sin cupo internacional; tres o más, multa y licencia denegada." % [cumple, reqs.size()]
	resumen.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_fed.add_child(resumen)
	_lista_fed.add_child(HSeparator.new())

	var tt := _texto(11, COL_SUAVE)
	tt.text = "TRIBUNAL DE DISCIPLINA"
	_lista_fed.add_child(tt)
	if f.casos.is_empty():
		var sin := _texto(12, COL_SUAVE)
		sin.text = "Sin expedientes abiertos. Tampoco te has metido en líos."
		_lista_fed.add_child(sin)
	else:
		for caso: Dictionary in f.casos:
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 8)
			_lista_fed.add_child(fila)
			var firme := String(caso.get("estado", "firme")) == "firme"
			var l := _texto(12, COL_TEXTO if firme else COL_SUAVE)
			l.text = "%s  ·  %s  ·  %d fecha(s)  ·  %s" % [
				String(caso.get("nombre", "?")), String(caso.get("motivo", "")),
				int(caso.get("fechas", 0)), String(caso.get("estado", ""))]
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila.add_child(l)
			## Apelar una vez por caso, como manda `apelar()`: el segundo intento
			## lo rechaza ella misma, pero un botón que no se puede pulsar dice
			## la verdad mejor que un mensaje de error.
			if firme and not bool(caso.get("apelado", false)):
				var id_caso := String(caso.get("id", ""))
				_boton("Apelar", func() -> void: _apelar_caso(id_caso), fila)
	_lista_fed.add_child(HSeparator.new())

	if not f.controles.is_empty():
		var tc := _texto(11, COL_SUAVE)
		tc.text = "CONTROLES ANTIDOPAJE"
		_lista_fed.add_child(tc)
		for i in mini(6, f.controles.size()):
			var ctrl: Dictionary = f.controles[f.controles.size() - 1 - i]
			var positivo := bool(ctrl.get("positivo", false))
			_dato("%s  (S%d/%d)" % [String(ctrl.get("nombre", "?")), int(ctrl.get("semana", 0)), int(ctrl.get("anio", 0))],
				"POSITIVO" if positivo else "negativo", COL_ROJO if positivo else COL_VERDE, _lista_fed)
		_lista_fed.add_child(HSeparator.new())

func _bono_staff(c: Club) -> void:
	var liga := _liga_de(c)
	var puesto := 1
	var tabla := liga.tabla()
	for fila: Dictionary in tabla:
		if fila["club"] == c:
			break
		puesto += 1
	var r := mundo.staff.repartir_bono(c, mundo.anio, puesto, tabla.size())
	if r.has("error"):
		_escribir("[color=#e05555]No se pudo: %s.[/color]" % String(r["error"]))
	else:
		Sonido.toca("moneda")
		_escribir("[color=#4caf6d][b]Bono al cuerpo técnico.[/b][/color] %s repartidos entre %d escalón(es) yendo %d.º: la moral del plantel sube %d puntos." % [
			_dinero(int(r["coste"])), int(r["escalones"]), puesto, int(r["moral"])])
		_anotar("Bono al cuerpo técnico.", "%s repartidos. La moral del plantel sube %d puntos." % [
			_dinero(int(r["coste"])), int(r["moral"])])
	_refrescar()

func _segunda_opinion(j: Jugador) -> void:
	var r := mundo.medico.segunda_opinion(j, mundo.mi_club())
	if r.has("error"):
		_escribir("[color=#e05555]No se pudo: %s.[/color]" % String(r["error"]))
	else:
		var delta := int(r["delta"])
		var color := "#4caf6d" if delta < 0 else ("#e05555" if delta > 0 else "#8ea595")
		_escribir("[color=%s][b]🩺 Segunda opinión: %s.[/b][/color] %s Se queda en %d semana(s)." % [
			color, j.nombre, String(r["texto"]), int(r["semanas"])])
		_anotar("🩺 Segunda opinión: %s." % j.nombre, String(r["texto"]))
	_refrescar()

func _renovar(j: Jugador, con_clausula: bool) -> void:
	var r := mundo.cantera.renovar(j, con_clausula)
	if r.has("error"):
		_escribir("[color=#e05555]No se pudo renovar: %s.[/color]" % String(r["error"]))
	else:
		_escribir("[color=#4caf6d]RENOVADO: %s.[/color] %d temporadas a %s/sem%s." % [
			j.nombre, int(r["anios"]), _dinero(int(r["sueldo"])),
			" con cláusula de %s" % _dinero(int(r["clausula"])) if con_clausula else ""])
		Sonido.toca("fichaje")
	_refrescar()

func _apelar_caso(id_caso: String) -> void:
	var r := mundo.federacion.apelar(id_caso, mundo.mi_club(),
		mundo.roles.prestigio if mundo.roles != null else 50)
	_escribir("[color=#c9a227][b]⚖️ Apelación.[/b][/color] %s" % r)
	_anotar("⚖️ Apelación.", r)
	_refrescar()

## C15: EL GOBIERNO DEL PAÍS. Partidos y personas inventados; la estructura
## del Estado y los plazos, reales.
func _pintar_gobierno(c: Club) -> void:
	if mundo.politica == null:
		return
	var g := mundo.politica.gobierno(c.pais, mundo.anio)
	var pos: Array = Politica.POSTURAS[String(g["postura"])]
	var l := _texto(12, COL_TEXTO)
	var prox := int(g["proxima"])
	l.text = "🗳️ Gobierno de %s: %s (%s) · prioridad: %s%s" % [c.pais, String(g["lider"]), String(g["partido"]),
		String(pos[0]).to_lower(), (" · elecciones en %d" % prox) if prox > 0 else " · sin elecciones nacionales"]
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.tooltip_text = String(pos[1])
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	_lista_fed.add_child(l)
	var b := Button.new()
	b.text = "🧑‍🏫 ¿Cómo funciona el Estado aquí?"
	b.add_theme_font_size_override("font_size", 13)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.pressed.connect(func() -> void:
		MentorVoz.decir(self, mundo, "Cómo se gobierna %s" % c.pais, Politica.explicacion(c.pais)))
	_lista_fed.add_child(b)
	_lista_fed.add_child(HSeparator.new())

func _pintar_federacion(c: Club) -> void:
	_limpiar(_lista_fed)
	var f := mundo.federacion
	## EL PRESIDENTE (C5): quién manda y qué empuja.
	if not f.presidente.is_empty():
		var ag: Array = Federacion.AGENDAS[String(f.presidente["agenda"])]
		var tp := _texto(12, COL_ORO)
		tp.text = "🏛️ Presidente: %s · corriente %s · mandato hasta %d" % [String(f.presidente["nombre"]), String(ag[0]).to_lower(), int(f.presidente["hasta"])]
		tp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_fed.add_child(tp)
		var lema := _texto(11, COL_SUAVE)
		lema.text = String(ag[2]) + " Sus propuestas salen antes en la asamblea y hace campaña por ellas."
		lema.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_fed.add_child(lema)
	_pintar_gobierno(c)
	_pintar_licencia_y_tribunal(c, f)
	_pintar_historial_federacion(f)
	var t := _texto(11, COL_SUAVE)
	t.text = "REGLAMENTO VIGENTE"
	_lista_fed.add_child(t)
	for regla in f.reglas_vigentes():
		var l := _texto(12, COL_TEXTO)
		l.text = "· " + String(regla)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_fed.add_child(l)

	if f.voto_pendiente.is_empty():
		_lista_fed.add_child(HSeparator.new())
		var nada := _texto(12, COL_SUAVE)
		nada.text = "No hay ninguna votación abierta. La federación convoca cada tanto."
		nada.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_fed.add_child(nada)
		return

	## La votación pendiente. Tu voto no decide solo: hay una asamblea, y por eso
	## se puede votar a favor y perder — que es lo que hace que votar signifique
	## algo en vez de ser un interruptor.
	_lista_fed.add_child(HSeparator.new())
	var v: Dictionary = f.voto_pendiente
	var t2 := _texto(11, COL_ORO)
	t2.text = "VOTACIÓN ABIERTA"
	_lista_fed.add_child(t2)
	var q := _texto(13, COL_TEXTO)
	## La tabla VOTACIONES guarda el título en "t", no en "titulo" -esa clave
	## nunca existió-, así que esto mostraba el id interno en crudo ("tvigual")
	## en vez de "Reparto igualitario de los derechos de TV". Corregido 14-9-2026.
	q.text = String(v.get("t", v.get("id", "")))
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_fed.add_child(q)
	var d := _texto(12, COL_SUAVE)
	d.text = String(v.get("texto", v.get("desc", "")))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_fed.add_child(d)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	_lista_fed.add_child(fila)
	## `Federacion.votar()` -portado tal cual del HTML- solo distingue "a" (a
	## favor) de cualquier otra cosa (en contra): mandar "si" nunca es igual a
	## "a", así que el botón "A favor" jamás sumaba tu voto explícito y el
	## mensaje de "ganaste/perdiste" salía invertido cada vez que votabas a
	## favor. Corregido 14-9-2026. "Abstenerse" no existe en el original -es
	## un tercer botón agregado en la migración- y hoy cae en la misma rama que
	## "En contra" (cuenta igual, sin el bono de "a favor"): si alguna vez se
	## quiere que abstenerse no cuente en el total, hace falta un tercer caso en
	## `votar()`, decisión de diseño que no tocamos aquí.
	_boton("A favor", func() -> void: _votar("a"), fila)
	_boton("En contra", func() -> void: _votar("b"), fila)
	_boton("Abstenerse", func() -> void: _votar("abs"), fila)

func _votar(opcion: String) -> void:
	var asamblea: Array = mundo.liga_de(mundo.mi_club()).clubes
	var r := mundo.federacion.votar(opcion, mundo.mi_club(), asamblea)
	var paso := bool(r.get("pasa", false))
	var contigo := bool(r.get("ganaste", false))
	_escribir("[color=%s]La votación %s.[/color] %s" % [
		"#4caf6d" if contigo else "#e05555",
		"sale adelante" if paso else "se rechaza",
		"Salió lo que querías." if contigo else "La asamblea votó al revés que tú."])
	if String(r.get("efecto", "")) != "":
		_escribir("[color=#8ea595]%s[/color]" % String(r["efecto"]))
	_refrescar()

## TU ESTADIO: lo que se puede reformar y lo que cuesta.
## `vHinchada()` del HTML: los cinco grupos de la afición, el plan de abonos y
## la encuesta abierta. La idea que lo sostiene es que **no se puede contentar a
## todos a la vez**: el abono popular llena el estadio y gana al barrio pero
## recauda poco; el premium da dinero y enfada a las familias.
func _pintar_hinchada(c: Club) -> void:
	var h := mundo.hinchada
	if h == null:
		return
	_lista_estadio.add_child(HSeparator.new())
	if h.abonados > 0:
		_dato("Abonados", "%s  ·  %s" % [_miles(h.abonados), h.nombre_abono()], COL_TEXTO, _lista_estadio)
	if mundo.prensa != null:
		var fp := h.fair_play(mundo.prensa.funa, mundo.prensa.animo)
		_dato("Fair play de la hinchada", "%d / 100" % fp,
			COL_VERDE if fp >= 70 else (COL_ROJO if fp < 35 else COL_ORO), _lista_estadio)
	## EL DÍA DEL HINCHA. Es la única acción del juego que sube TODOS los
	## segmentos a la vez: bajar el precio de la entrada contenta al que paga,
	## esto contenta al que viene. Por eso vale lo que vale.
	_dato("Días del hincha organizados", str(h.dias_hincha), COL_TEXTO, _lista_estadio)
	var coste_dh := Eco.escalar(Hinchada.COSTE_DIA_HINCHA, float(c.rep))
	var bdh := Button.new()
	bdh.text = "🎪 Organizar un día del hincha  ·  %s" % _dinero(coste_dh)
	bdh.disabled = c.saldo < coste_dh
	bdh.pressed.connect(func() -> void: _organizar_dia_hincha(c))
	_lista_estadio.add_child(bdh)
	_pintar_penas_y_ramas(c, h)

	## La encuesta, si la hay. Va arriba porque es lo único que pide respuesta.
	if not h.encuesta.is_empty():
		var te := _texto(11, COL_ORO)
		te.text = "📊 ENCUESTA A LOS SOCIOS"
		_lista_estadio.add_child(te)
		var pr := _texto(13, COL_TEXTO)
		pr.text = String(h.encuesta["pregunta"])
		pr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_estadio.add_child(pr)
		var opciones: Array = h.encuesta["opciones"]
		var pcts: Array = h.encuesta["pct"]
		for i in opciones.size():
			var fila_e := HBoxContainer.new()
			fila_e.add_theme_constant_override("separation", 8)
			_lista_estadio.add_child(fila_e)
			var lo := _texto(12, COL_SUAVE)
			lo.text = "%s  ·  %d%%" % [String(opciones[i]), int(pcts[i])]
			lo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila_e.add_child(lo)
			var idx := i
			_boton("Hacer esto", func() -> void: _responder_encuesta(idx), fila_e)

	var ts := _texto(11, COL_SUAVE)
	ts.text = "SEGMENTOS DE LA HINCHADA"
	_lista_estadio.add_child(ts)
	var tabla: Variant = Datos.tabla("SEGMENTOS")
	if tabla is Array:
		for fila: Array in (tabla as Array):
			var clave := String(fila[0])
			var v := int(h.segmentos.get(clave, 50))
			_dato(String(fila[1]), "%d" % v,
				COL_VERDE if v > 70 else (COL_ROJO if v < 35 else COL_ORO), _lista_estadio)
			var d := _texto(10, COL_SUAVE)
			d.text = String(fila[2])
			d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_lista_estadio.add_child(d)

	var ta := _texto(11, COL_SUAVE)
	ta.text = "ABONOS DE TEMPORADA  ·  la campaña se lanza sola al empezar cada año"
	ta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_estadio.add_child(ta)
	var planes: Variant = Datos.tabla("PLANES_ABONO")
	if planes is Array:
		for fila2: Array in (planes as Array):
			var clave2 := String(fila2[0])
			var elegido := h.abono == clave2
			var fila_a := HBoxContainer.new()
			fila_a.add_theme_constant_override("separation", 8)
			_lista_estadio.add_child(fila_a)
			var la := _texto(12, COL_ACENTO if elegido else COL_SUAVE)
			la.text = "%s  ×%.2f" % [String(fila2[1]).strip_edges(), float(fila2[2])]
			la.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila_a.add_child(la)
			var ba := Button.new()
			ba.text = "Elegido" if elegido else "Elegir"
			ba.disabled = elegido
			ba.add_theme_font_size_override("font_size", 11)
			ba.pressed.connect(func() -> void:
				h.fijar_abono(clave2)
				_refrescar())
			fila_a.add_child(ba)
			var da := _texto(10, COL_SUAVE)
			da.text = String(fila2[3])
			da.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_lista_estadio.add_child(da)

	## PRECIOS DINÁMICOS. La otra palanca de la taquilla, además del precio fijo:
	## cobrar más el día que viene el líder y menos el día que viene el colista.
	## No es dinero gratis —subirle la entrada a la gente el día del clásico
	## cuesta ánimo—, y por eso es un interruptor y no una mejora.
	var fila_pd := HBoxContainer.new()
	fila_pd.add_theme_constant_override("separation", 8)
	_lista_estadio.add_child(fila_pd)
	var lpd := _texto(12, COL_TEXTO)
	lpd.text = "Precios dinámicos"
	lpd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lpd.tooltip_text = "Sube en los partidos grandes, baja en los flojos."
	fila_pd.add_child(lpd)
	var bpd := Button.new()
	bpd.text = "SÍ" if h.precio_dinamico else "NO"
	bpd.add_theme_font_size_override("font_size", 11)
	bpd.pressed.connect(func() -> void:
		var msg := h.alternar_precio_dinamico()
		_escribir("[color=#c9a227]%s[/color]" % msg)
		_refrescar())
	fila_pd.add_child(bpd)
	## Lo que se cobraría en el próximo partido en casa, para que el interruptor
	## no sea una promesa abstracta: se ve la cifra antes de encenderlo.
	var par_pd := _liga_de(c).emparejamiento_de(c)
	if par_pd.size() == 2 and par_pd[0] == c:
		var rival_pd: Club = par_pd[1]
		var base_pd := int(round(c.precio_entrada))
		var hoy_pd := h.precio_efectivo(base_pd, rival_pd.rep)
		var epd := _texto(10, COL_VERDE if hoy_pd > base_pd else (COL_ROJO if hoy_pd < base_pd else COL_SUAVE))
		epd.text = "Próximo partido en casa contra %s (rep %d): se cobraría %d en vez de %d." % [
			rival_pd.nombre, rival_pd.rep, hoy_pd, base_pd]
		epd.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_estadio.add_child(epd)

func _responder_encuesta(indice: int) -> void:
	var r := mundo.hinchada.responder_encuesta(indice)
	if r.has("error"):
		return
	var d_animo := int(r["animo"])
	if mundo.prensa != null:
		mundo.prensa.sumar_animo(d_animo)
	if bool(r["acerto"]):
		_escribir("[color=#4caf6d][b]📊 Hiciste lo que pedía la mayoría.[/b][/color] El ánimo sube %d y los socios se sienten escuchados." % d_animo)
	else:
		_escribir("[color=#e05555][b]📊 Fuiste por otro lado.[/b][/color] El ánimo baja %d: la gente había votado otra cosa." % absi(d_animo))
	_refrescar()

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

func _pintar_estilos_estadio(c: Club) -> void:
	var e := mundo.estadio
	if e == null:
		return
	_lista_estadio.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "✨ ESTILOS COMPLETOS"
	_lista_estadio.add_child(t)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	_lista_estadio.add_child(flow)
	for p: Dictionary in e.presets():
		var clave := String(p["clave"])
		var coste := e.coste_preset(c, clave, mundo.obras)
		var b := Button.new()
		b.text = "%s  ·  %s" % [Nombres.limpiar(String(p["nombre"])), _dinero(coste)]
		b.tooltip_text = Nombres.limpiar(String(p["desc"]))
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = coste > c.saldo
		b.pressed.connect(_aplicar_estilo_estadio.bind(clave))
		flow.add_child(b)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	_lista_estadio.add_child(fila)
	var sorpresa := Button.new()
	sorpresa.text = "🎲 Sorpréndeme"
	sorpresa.add_theme_font_size_override("font_size", 11)
	sorpresa.pressed.connect(func() -> void:
		_propuesta_estadio = mundo.estadio.aleatorio(mundo.mi_club(), mundo.obras)
		_refrescar())
	fila.add_child(sorpresa)
	var fabrica := Button.new()
	fabrica.text = "↺ Volver al estadio de fábrica"
	fabrica.add_theme_font_size_override("font_size", 11)
	fabrica.pressed.connect(_estadio_de_fabrica)
	fila.add_child(fabrica)
	if not _propuesta_estadio.is_empty():
		var coste_prop := e.presupuesto(c, _propuesta_estadio, mundo.obras)
		var prop := _texto(11, COL_ORO)
		prop.text = "Propuesta: %s. Coste %s." % [_resumen_propuesta(_propuesta_estadio), _dinero(coste_prop)]
		prop.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_estadio.add_child(prop)
		var fila2 := HBoxContainer.new()
		fila2.add_theme_constant_override("separation", 6)
		_lista_estadio.add_child(fila2)
		var si := Button.new()
		si.text = "Construirla"
		si.disabled = coste_prop > c.saldo
		si.pressed.connect(_aplicar_propuesta_estadio)
		fila2.add_child(si)
		var no := Button.new()
		no.text = "Descartar"
		no.pressed.connect(func() -> void:
			_propuesta_estadio = {}
			_refrescar())
		fila2.add_child(no)

func _aplicar_estilo_estadio(clave: String) -> void:
	var coste := mundo.estadio.coste_preset(mundo.mi_club(), clave, mundo.obras)
	var problema := mundo.estadio.aplicar_preset(mundo.mi_club(), clave, mundo.obras)
	if problema != "":
		_escribir("[color=#e05555]No se puede: %s.[/color]" % problema)
	else:
		_escribir("[color=#4caf6d]Estadio rehecho:[/color] estilo «%s». Coste %s." % [
			Nombres.limpiar(String(mundo.estadio.preset(clave).get("nombre", clave))), _dinero(coste)])
	_refrescar()

func _aplicar_propuesta_estadio() -> void:
	var cambios := _propuesta_estadio
	var coste := mundo.estadio.presupuesto(mundo.mi_club(), cambios, mundo.obras)
	var problema := mundo.estadio.reformar(mundo.mi_club(), cambios, mundo.obras)
	if problema != "":
		_escribir("[color=#e05555]No se puede: %s.[/color]" % problema)
	else:
		_escribir("[color=#4caf6d]Estadio sorpresa construido.[/color] Coste %s." % _dinero(coste))
		_propuesta_estadio = {}
	_refrescar()

## "↺ Volver a fábrica": los valores de `EST_DEF` como una reforma más. Solo
## los campos que el catálogo sabe reformar -más bandejas, pista y vallas- y
## solo los que de verdad cambian: aquí toda obra se paga, también la que
## deshace lo hecho, y no hay por qué cobrar por dejar algo como ya estaba.
func _estadio_de_fabrica() -> void:
	var def: Variant = Datos.tabla("EST_DEF")
	if not (def is Dictionary):
		return
	var cambios := {}
	for k: String in (def as Dictionary):
		var valido: bool = EstadioPropio.CATALOGO_DE.has(k) or ["niveles", "pista", "vallas"].has(k)
		if valido and mundo.estadio.ajustes.has(k) and mundo.estadio.ajustes[k] != (def as Dictionary)[k]:
			cambios[k] = (def as Dictionary)[k]
	if cambios.is_empty():
		_escribir("[color=#8ea595]El estadio ya está como vino de fábrica.[/color]")
		return
	var coste := mundo.estadio.presupuesto(mundo.mi_club(), cambios, mundo.obras)
	var problema := mundo.estadio.reformar(mundo.mi_club(), cambios, mundo.obras)
	if problema != "":
		_escribir("[color=#e05555]No se puede: %s.[/color]" % problema)
	else:
		_escribir("[color=#4caf6d]Estadio devuelto a fábrica.[/color] Coste %s." % _dinero(coste))
	_refrescar()

## Abre el visor 3D del propio estadio, vacío -sin rival ni partido-, para
## mirarlo desde Club → Estadio en vez de tener que esperar al próximo partido
## en casa. Mismo patrón exacto que `partido_vivo._ver_estadio()`: se cuelga
## de la raíz y se libera solo al volver, `VistaEstadio` ya sabe dar tamaño a
## sí mismo. La ocupación de las gradas es la de verdad -la misma cuenta que
## usa el partido en vivo-, no un número fijo: un estadio medio vacío tiene
## que verse medio vacío también aquí.
func _ver_estadio_propio() -> void:
	var c := mundo.mi_club()
	if c == null:
		return
	var f := Finanzas.new(c)
	var gente := float(f.asistencia()) / float(maxi(c.estadio_aforo, 1))
	## VistaEstadio pinta el 3D DIRECTO en el viewport raíz y a propósito no
	## trae ningún fondo opaco -es lo que deja ver el estadio de verdad, ver
	## el comentario en `estadio.gd::_construir()`-, pero eso significa que
	## cualquier Control que siga encima -la barra superior, las pestañas,
	## esta misma lista de Estadio- lo tapa entero: en un mismo viewport los
	## Control se pintan SIEMPRE sobre el 3D, sin importar el orden en que se
	## añadieron los nodos. `partido_vivo._ver_estadio()` no tiene este
	## problema porque su propia pantalla ya deja hueco de sobra; esta sí
	## está cubierta de paneles, así que hay que esconderlos a mano mientras
	## el visor está abierto y devolverlos tal cual al volver -guardando
	## cuáles estaban visibles, no asumiendo que todos lo estaban-.
	var ocultados: Array = []
	for h in get_children():
		if h is Control and (h as Control).visible:
			(h as Control).visible = false
			ocultados.append(h)
	var vista := VistaEstadio.new()
	## Sin partido la pantalla gigante enseña bienvenida + tabla + goleadores,
	## que es lo que hace un estadio de verdad un día entre semana. Va antes de
	## `abrir()`, que es donde se monta.
	vista.datos_pantalla = _datos_pantalla_estadio(c)
	add_child(vista)
	vista.abrir(c, clampf(gente, 0.05, 1.0), null, null, mundo.perfil_estadio_de(c),
		Comercial.color_balon(mundo.comercial.balon, c))
	vista.cerrado.connect(func() -> void:
		vista.queue_free()
		for h in ocultados:
			if is_instance_valid(h):
				(h as Control).visible = true)

func _resumen_propuesta(cambios: Dictionary) -> String:
	var partes: Array[String] = []
	for k: String in ["forma", "techo", "focos", "cesped", "niveles"]:
		if cambios.has(k):
			partes.append("%s %s" % [String(ETIQUETAS_ESTADIO.get(k, k)).to_lower(), str(cambios[k])])
	return ", ".join(partes)

## Qué tribuna se está editando cuando "Personalizar cada tribuna" está activo.
## Solo estado de interfaz -no se guarda, como `_secc_ajustes`-: al volver a
## esta pantalla siempre se empieza mirando la tribuna Sur.
var _bandeja_actual: String = "sur"

func _pintar_estadio(c: Club) -> void:
	_limpiar(_lista_estadio)
	var e := mundo.estadio
	var p := mundo.perfil_estadio_de(c)
	var t := _texto(13, COL_ORO)
	t.text = c.estadio_nombre if c.estadio_nombre != "" else e.nombre_de(c)
	_lista_estadio.add_child(t)
	## PONERLE NOMBRE AL ESTADIO, de `vEstadio()`. Es lo más barato que puede
	## hacer un club por su identidad y lo primero que hace cualquiera al llegar
	## a uno nuevo. Vacío vuelve al nombre por defecto: no se puede quedar sin.
	var fila_n := HBoxContainer.new()
	fila_n.add_theme_constant_override("separation", 6)
	_lista_estadio.add_child(fila_n)
	var campo_nombre := LineEdit.new()
	campo_nombre.placeholder_text = "Ponle nombre al estadio…"
	campo_nombre.text = c.estadio_nombre
	campo_nombre.add_theme_font_size_override("font_size", 11)
	campo_nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	campo_nombre.text_submitted.connect(func(v: String) -> void:
		c.estadio_nombre = v.strip_edges()
		_refrescar())
	fila_n.add_child(campo_nombre)
	var bn := Button.new()
	bn.text = "Guardar"
	bn.add_theme_font_size_override("font_size", 11)
	bn.pressed.connect(func() -> void:
		c.estadio_nombre = campo_nombre.text.strip_edges()
		_refrescar())
	fila_n.add_child(bn)
	## VER EL DISEÑO DE VERDAD, no solo leerlo en desplegables. Hasta ahora
	## `VistaEstadio` -el visor 3D completo, con gradas, césped y focos- solo se
	## abría desde el partido en vivo (`partido_vivo.gd`): para ver cómo había
	## quedado una reforma había que esperar al próximo partido en casa. El
	## mismo visor sirve vacío -`abrir(club)`, su primer modo, pensado para
	## justo esto- así que se engancha aquí también, sin duplicar nada.
	var ver3d := Button.new()
	ver3d.text = "👁️ Ver mi estadio en 3D"
	ver3d.add_theme_font_size_override("font_size", 11)
	ver3d.pressed.connect(_ver_estadio_propio)
	fila_n.add_child(ver3d)
	_pintar_estilos_estadio(c)
	## LA HINCHADA. `Prensa.animo` y `Prensa.funa` se mueven solos desde hace
	## tiempo -banderazos si el ánimo pasa de 82, lienzos si baja de 22- y no se
	## veían en ninguna pantalla: el jugador notaba los efectos sin saber nunca
	## el número. Van aquí, que es donde vive la gente que llena esto.
	if mundo.prensa != null:
		var animo := mundo.prensa.animo
		var col_animo := COL_VERDE if animo >= 70 else (COL_ROJO if animo <= 35 else COL_ORO)
		_dato("Ánimo de la hinchada", "%d / 100" % animo, col_animo, _lista_estadio)
		var funa := mundo.prensa.funa
		if funa > 0:
			_dato("Presión en redes (funa)", "%d / 100" % funa,
				COL_ROJO if funa > 55 else COL_SUAVE, _lista_estadio)
		var lectura := _texto(11, COL_SUAVE)
		if animo >= 82:
			lectura.text = "El estadio empuja: a este nivel salen banderazos antes de los partidos."
		elif animo <= 22:
			lectura.text = "Ambiente enrarecido: a este nivel aparecen lienzos en contra."
		else:
			lectura.text = "La gente responde a los resultados. Ganar en casa y no subir la entrada es lo que más lo mueve."
		lectura.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_estadio.add_child(lectura)
	_dato("Socios", _miles(c.socios), COL_TEXTO, _lista_estadio)
	_pintar_hinchada(c)
	_lista_estadio.add_child(HSeparator.new())
	var sub := _texto(12, COL_SUAVE)
	sub.text = "%s de %d bandeja%s  ·  techo %s  ·  %s butacas  ·  ambiente %d" % [
		String(p.get("forma", "?")).capitalize(), int(p.get("niveles", 1)),
		"" if int(p.get("niveles", 1)) == 1 else "s", String(p.get("techo", "?")),
		_miles(int(p.get("aforo", 0))), e.ambiente()]
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_estadio.add_child(sub)
	var nota := _texto(11, COL_SUAVE)
	nota.text = "Las bandejas y el aforo se amplían construyendo tribunas en Club → Obras. Aquí se decide cómo SE VE."
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_estadio.add_child(nota)
	_lista_estadio.add_child(HSeparator.new())

	## LOS DIECISIETE CAMPOS, no seis. `EstadioPropio.CATALOGO_DE` los tiene todos
	## desde el porte -forma, techo, césped, tono, líneas, arcos, redes, córner,
	## banquillos, túnel, dónde va el escudo, clima, banderas, focos, pantallas y
	## hasta el sonido del gol- y la pantalla solo exponía seis. Todo lo demás
	## estaba escrito, probado, con su coste calculado, y era inalcanzable.
	##
	## Se agrupan por bloques porque diecisiete desplegables seguidos son una
	## lista de la compra: así se lee como lo que es, un estadio por partes.
	for bloque: Array in [
			["LA ESTRUCTURA", ["forma", "fachada", "fachadaCol", "techo", "techoCol", "focos", "luzFocos", "pantalla"]],
			["EL CAMPO", ["superficie", "cesped", "cespedTono", "lineaCol", "arcoCol", "redCol", "redTipo"]],
			["LA GRADA", ["asientoP", "banderas", "escudoDonde", "corner"]],
			## Sin "clima" (26-9-2026): el tiempo lo pone la ciudad, no el
			## diseñador. Elegir "lluvia" como se elige un color era ilógico.
			["LOS DETALLES", ["banquillo", "banquilloCol", "tunel", "sonidoGol"]],
		]:
		var tb := _texto(11, COL_ACENTO)
		tb.text = String(bloque[0])
		_lista_estadio.add_child(tb)
		for campo: String in (bloque[1] as Array):
			_fila_diseno_estadio(e, p, campo)

	## LAS TRIBUNAS, cada una con su propio estilo (16-9-2026, Fase 1 de "el
	## estadio por MÓDULOS" del ROADMAP). Con el interruptor apagado -el caso de
	## siempre- esto no pinta nada más que el aviso: activar es el paso que dice
	## "quiero decidir esto tribuna por tribuna" y por eso cuesta.
	_lista_estadio.add_child(HSeparator.new())
	var tt := _texto(11, COL_ACENTO)
	tt.text = "LAS TRIBUNAS"
	_lista_estadio.add_child(tt)
	_fila_interruptor_estadio(e.ajustes, "personalizar_bandejas", "Personalizar cada tribuna",
		"Cada una de las 4 tribunas con su propio patrón, colores de butaca y techo, en vez de un solo estilo para todo el recinto.")
	if bool(e.ajustes.get("personalizar_bandejas", false)):
		var fila_lado := HBoxContainer.new()
		fila_lado.add_theme_constant_override("separation", 6)
		_lista_estadio.add_child(fila_lado)
		var l_lado := _texto(11, COL_SUAVE)
		l_lado.text = "Tribuna"
		l_lado.custom_minimum_size = Vector2(130, 0)
		fila_lado.add_child(l_lado)
		var sel_lado := OptionButton.new()
		sel_lado.add_theme_font_size_override("font_size", 11)
		sel_lado.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var etiquetas_lado := {"sur": "Sur", "norte": "Norte", "este": "Este", "oeste": "Oeste"}
		for i in EstadioPropio.LADOS_BANDEJA.size():
			var lado: String = EstadioPropio.LADOS_BANDEJA[i]
			sel_lado.add_item(String(etiquetas_lado.get(lado, lado.capitalize())))
			sel_lado.set_item_metadata(i, lado)
			if lado == _bandeja_actual:
				sel_lado.select(i)
		sel_lado.item_selected.connect(func(idx: int) -> void:
			_bandeja_actual = String(sel_lado.get_item_metadata(idx))
			_pintar_estadio(c))
		fila_lado.add_child(sel_lado)
		_fila_diseno_estadio(e, p, "bandeja_%s_asientoP" % _bandeja_actual)
		_fila_diseno_estadio(e, p, "bandeja_%s_techo" % _bandeja_actual)
		_fila_diseno_estadio(e, p, "bandeja_%s_col1" % _bandeja_actual)
		_fila_diseno_estadio(e, p, "bandeja_%s_col2" % _bandeja_actual)

	## LOS TERCIOS: estilos mixtos DENTRO de una misma tribuna (18/22-9-2026,
	## Fase 3 de "el estadio por MÓDULOS", la última de las tres). El spike del
	## 18-9 confirmó que el corte se sostiene visualmente -ver LEEME.md-, esta
	## es la pantalla real. Interruptor PROPIO, independiente del de arriba: se
	## puede mezclar por tercios una tribuna sin haber activado "Personalizar
	## cada tribuna" en ninguna, y viceversa. Reusa el mismo selector
	## `_bandeja_actual` que el bloque de arriba -es la misma pregunta ("¿qué
	## tribuna estoy mirando?") para las dos reformas, no hace falta un
	## segundo estado que se pueda desincronizar del primero.
	_fila_interruptor_estadio(e.ajustes, "personalizar_tramos", "Mezclar patrones por tercios",
		"Cada tribuna se puede partir en 3 tercios con su propio patrón de butaca, en vez de uno solo de punta a punta.")
	if bool(e.ajustes.get("personalizar_tramos", false)):
		var fila_lado_t := HBoxContainer.new()
		fila_lado_t.add_theme_constant_override("separation", 6)
		_lista_estadio.add_child(fila_lado_t)
		var l_lado_t := _texto(11, COL_SUAVE)
		l_lado_t.text = "Tribuna"
		l_lado_t.custom_minimum_size = Vector2(130, 0)
		fila_lado_t.add_child(l_lado_t)
		var sel_lado_t := OptionButton.new()
		sel_lado_t.add_theme_font_size_override("font_size", 11)
		sel_lado_t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var etiquetas_lado_t := {"sur": "Sur", "norte": "Norte", "este": "Este", "oeste": "Oeste"}
		for i in EstadioPropio.LADOS_BANDEJA.size():
			var lado_t: String = EstadioPropio.LADOS_BANDEJA[i]
			sel_lado_t.add_item(String(etiquetas_lado_t.get(lado_t, lado_t.capitalize())))
			sel_lado_t.set_item_metadata(i, lado_t)
			if lado_t == _bandeja_actual:
				sel_lado_t.select(i)
		sel_lado_t.item_selected.connect(func(idx: int) -> void:
			_bandeja_actual = String(sel_lado_t.get_item_metadata(idx))
			_pintar_estadio(c))
		fila_lado_t.add_child(sel_lado_t)
		for tercio in [1, 2, 3]:
			_fila_diseno_estadio(e, p, "tramo_%s_%d" % [_bandeja_actual, tercio])

	## Los dos interruptores. No son desplegables y por eso se quedaron fuera
	## del catálogo: la pista de atletismo aleja la grada del campo y le quita
	## ambiente, y las vallas perimetrales son la diferencia entre un recinto de
	## los ochenta y uno moderno. Ambos estaban implementados y sin manera de
	## tocarlos.
	_lista_estadio.add_child(HSeparator.new())
	var ti := _texto(11, COL_ACENTO)
	ti.text = "EL RECINTO"
	_lista_estadio.add_child(ti)
	_fila_interruptor_estadio(e.ajustes, "pista", "Pista de atletismo",
		"Aleja la grada del campo: -3,5 de ambiente.")
	_fila_interruptor_estadio(e.ajustes, "vallas", "Vallas perimetrales",
		"Separan a la hinchada del césped. Estética de otra época.")

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

## Un interruptor del diseñador: los campos que son sí o no y no tienen catálogo.
func _fila_interruptor_estadio(p: Dictionary, campo: String, titulo: String, nota: String) -> void:
	if not p.has(campo):
		return
	var cb := CheckBox.new()
	cb.add_theme_font_size_override("font_size", 11)
	cb.text = titulo
	cb.button_pressed = bool(p[campo])
	cb.tooltip_text = nota
	cb.toggled.connect(func(activo: bool) -> void:
		_reformar_valor(campo, activo))
	_lista_estadio.add_child(cb)
	var n := _texto(10, COL_SUAVE)
	n.text = nota
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_estadio.add_child(n)

## Un desplegable del diseñador. Sale aparte porque ahora hay diecisiete y
## repetir veinte líneas por cada uno sería insostenible.
func _fila_diseno_estadio(e: EstadioPropio, p: Dictionary, campo: String) -> void:
	var ops: Array = e.opciones(campo)
	if ops.is_empty():
		return
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	_lista_estadio.add_child(fila)
	var l := _texto(11, COL_SUAVE)
	l.text = String(ETIQUETAS_ESTADIO.get(campo, campo.capitalize()))
	l.custom_minimum_size = Vector2(130, 0)
	l.clip_text = true
	fila.add_child(l)
	var b := OptionButton.new()
	b.add_theme_font_size_override("font_size", 11)
	b.clip_text = true
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in ops.size():
		var o: Dictionary = ops[i]
		b.add_item(String(o["nombre"]))
		b.set_item_metadata(i, String(o["clave"]))
		## Los colores se eligen viéndolos (B6.1): una muestra junto al nombre.
		if String(o["clave"]).begins_with("#"):
			b.set_item_icon(i, _muestra_color(Color(String(o["clave"]))))
		if String(o["clave"]) == String(e.ajustes.get(campo, p.get(campo, ""))):
			b.select(i)
	b.item_selected.connect(func(idx: int) -> void:
		_reformar(campo, String(b.get_item_metadata(idx))))
	fila.add_child(b)
	## ESCUCHAR ANTES DE PAGAR -el "▶" de cada sonido en el HTML-. Elegir en el
	## desplegable ya COBRA la reforma, así que probar tiene que ir aparte: un
	## menú con los ocho que solo los toca, sin comprar nada.
	if campo == "sonidoGol":
		var escuchar := MenuButton.new()
		escuchar.text = "▶ Escuchar"
		escuchar.tooltip_text = "Probar cualquier sonido de gol sin pagar la reforma"
		escuchar.add_theme_font_size_override("font_size", 11)
		var pop := escuchar.get_popup()
		for i in ops.size():
			pop.add_item(String((ops[i] as Dictionary)["nombre"]), i)
		pop.id_pressed.connect(_probar_sonido_gol.bind(ops))
		fila.add_child(escuchar)

static var _muestras: Dictionary = {}
func _muestra_color(c: Color) -> Texture2D:
	var k := c.to_html(false)
	if not _muestras.has(k):
		var img := Image.create(14, 14, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0.6))
		img.fill_rect(Rect2i(1, 1, 12, 12), c)
		_muestras[k] = ImageTexture.create_from_image(img)
	return _muestras[k]

## Con nombre propio y no como lambda: un `match` o varias líneas dentro de un
## lambda pasado como argumento ya rompió el parser de este archivo una vez.
func _probar_sonido_gol(id: int, ops: Array) -> void:
	if id >= 0 and id < ops.size():
		Sonido.toca("gol_" + String((ops[id] as Dictionary)["clave"]))

func _reformar(campo: String, valor: String) -> void:
	_reformar_valor(campo, valor)

## La reforma de verdad. Acepta Variant porque el diseñador ya no es solo de
## desplegables: `pista` y `vallas` son booleanos y `reformar()` los admite.
func _reformar_valor(campo: String, valor: Variant) -> void:
	var cambios := {campo: valor}
	var coste := mundo.estadio.presupuesto(mundo.mi_club(), cambios, mundo.obras)
	var problema := mundo.estadio.reformar(mundo.mi_club(), cambios, mundo.obras)
	if problema != "":
		_escribir("[color=#e05555]No se puede reformar: %s.[/color]" % problema)
		_refrescar()
		return
	var visible: String = String(valor)
	if valor is bool:
		visible = "sí" if bool(valor) else "no"
	_escribir("[color=#4caf6d]Reforma hecha:[/color] %s → %s. Coste %s." % [
		String(ETIQUETAS_ESTADIO.get(campo, campo.capitalize())), visible, _dinero(coste)])
	_refrescar()

## LA SELECCIÓN: a quién te llevan, el escalafón mundial, y la nacionalización
## deportiva de tus extranjeros con residencia.
## EL MUNDIAL, EL MUNDIAL DE CLUBES Y LOS CAMPEONES CONTINENTALES, de
## `vSeleccion()`. `Selecciones` los guarda los tres desde el porte —los juega,
## los resuelve y los archiva— y no se veía ninguno: el Mundial de Clubes es el
## techo del juego, el sitio al que solo llegas ganando tu continente, y pasaba
## sin que quedara constancia en ninguna pantalla.
func _pintar_palmares_mundial(s: Selecciones) -> void:
	if not s.mundial.is_empty():
		_lista_seleccion.add_child(HSeparator.new())
		var t := _texto(11, COL_SUAVE)
		t.text = "COPA DEL MUNDO"
		_lista_seleccion.add_child(t)
		_dato("Último campeón", "%s (%d)" % [String(s.mundial.get("campeon", "—")), int(s.mundial.get("anio", 0))],
			COL_ORO, _lista_seleccion)

	if not s.mundial_clubes.is_empty():
		_lista_seleccion.add_child(HSeparator.new())
		var t2 := _texto(11, COL_SUAVE)
		t2.text = "MUNDIAL DE CLUBES"
		_lista_seleccion.add_child(t2)
		var mio := bool(s.mundial_clubes.get("mio", false))
		_dato("Campeón", "%s (%d)" % [String(s.mundial_clubes.get("campeon", "—")), int(s.mundial_clubes.get("anio", 0))],
			COL_ORO if mio else COL_TEXTO, _lista_seleccion)
		var relato := String(s.mundial_clubes.get("relato", ""))
		if relato != "":
			var r := _texto(11, COL_ORO if mio else COL_SUAVE)
			r.text = relato
			r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_lista_seleccion.add_child(r)

	if not s.campeones_continentales.is_empty():
		_lista_seleccion.add_child(HSeparator.new())
		var t3 := _texto(11, COL_SUAVE)
		t3.text = "CAMPEONES CONTINENTALES"
		_lista_seleccion.add_child(t3)
		var ex := _texto(10, COL_SUAVE)
		ex.text = "Son los que se clasifican al Mundial de Clubes del año siguiente."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_seleccion.add_child(ex)
		var mi_id := mundo.mi_club_id
		for f: Dictionary in s.campeones_continentales:
			var propio := String(f.get("club_id", "")) == mi_id
			_dato("%s %d" % [String(f.get("torneo", "")), int(f.get("anio", 0))],
				String(f.get("campeon", "")), COL_ACENTO if propio else COL_TEXTO, _lista_seleccion)

func _pintar_seleccion(c: Club) -> void:
	_limpiar(_lista_seleccion)
	var s := mundo.selecciones
	if s == null:
		return
	_pintar_palmares_mundial(s)
	var t := _texto(13, COL_ORO)
	t.text = "%s  ·  fuerza %d" % [s.nombre_seleccion(), s.fuerza(s.nombre_seleccion())]
	_lista_seleccion.add_child(t)

	## Lo tuyo primero: la nómina si ya está cerrada, si no la prenómina, si no
	## nada. Es la misma jerarquía que usa el HTML -lo más cocinado manda.
	var mios_nomina := s.convocados().filter(func(j: Jugador) -> bool: return j.club_id == c.id)
	var mios_pre := s.prenominados().filter(func(j: Jugador) -> bool: return j.club_id == c.id)
	if not mios_nomina.is_empty():
		var l := _texto(12, COL_VERDE)
		var nombres: Array[String] = []
		for j: Jugador in mios_nomina:
			nombres.append("%s (%d caps)" % [j.nombre, s.caps_de(j)])
		l.text = "Convocados ahora: " + ", ".join(nombres)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_seleccion.add_child(l)
	elif not mios_pre.is_empty():
		var l2 := _texto(12, COL_ORO)
		var nombres2: Array[String] = []
		for j: Jugador in mios_pre:
			nombres2.append(j.nombre)
		l2.text = "En la prenómina: " + ", ".join(nombres2)
		l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_seleccion.add_child(l2)
	else:
		var vacio := _texto(12, COL_SUAVE)
		vacio.text = "Nadie de tu club convocado en este momento."
		_lista_seleccion.add_child(vacio)


	## PEDIR QUE NO SE LO LLEVEN. `Selecciones.pedir_descanso()` estaba escrita
	## desde el porte y no tenía un solo botón: la única defensa del club contra
	## una convocatoria que te devuelve al jugador reventado no existía.
	##
	## Se pide por los CONVOCADOS y por los prenominados: cuando ya viajó es
	## tarde, y cuando todavía no está en ninguna lista no hay nada que pedir.
	var pedibles: Array[Jugador] = []
	for j: Jugador in mios_nomina:
		pedibles.append(j)
	for j2: Jugador in mios_pre:
		if not pedibles.has(j2):
			pedibles.append(j2)
	if not pedibles.is_empty():
		var td := _texto(11, COL_SUAVE)
		td.text = "PEDIR DESCANSO"
		_lista_seleccion.add_child(td)
		if not _modo_experto:
			var ed := _texto(10, COL_SUAVE)
			ed.text = "Le pides a la federación que no se lo lleve. No siempre te hacen caso, y al jugador no le suele gustar que decidas por él."
			ed.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_lista_seleccion.add_child(ed)
		for jd: Jugador in pedibles:
			var quien := jd
			var pedido := s.pidio_descanso(jd)
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 6)
			_lista_seleccion.add_child(fila)
			var n := _texto(12, COL_ORO if pedido else COL_TEXTO)
			var nac := s.nacionalidad_deportiva(jd)
			n.text = "%s  ·  %s%s" % [jd.nombre, jd.pais,
				"  (nacionalizado %s)" % nac if nac != "" else ""]
			n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			n.clip_text = true
			fila.add_child(n)
			var b := Button.new()
			b.text = "Pedido" if pedido else "Pedir descanso"
			b.add_theme_font_size_override("font_size", 11)
			b.disabled = pedido
			b.custom_minimum_size = Vector2(120, 0)
			b.pressed.connect(func() -> void:
				var problema := s.pedir_descanso(quien)
				if problema != "":
					_escribir("[color=#e05555]No se pudo pedir: %s.[/color]" % problema)
				else:
					_escribir("[color=#c9a227]Pedido presentado por %s.[/color] La federación decidirá; no siempre hacen caso." % quien.nombre)
				_refrescar())
			fila.add_child(b)
	if not s.resultados.is_empty():
		_lista_seleccion.add_child(HSeparator.new())
		var tr := _texto(11, COL_SUAVE)
		tr.text = "ÚLTIMOS RESULTADOS"
		_lista_seleccion.add_child(tr)
		for linea: String in s.resultados:
			var lr := _texto(12, COL_TEXTO)
			lr.text = linea
			_lista_seleccion.add_child(lr)

	## La nacionalización: solo si hay algún candidato, para no ensuciar la
	## pantalla con una sección vacía la primera temporada.
	var candidatos := s.candidatos_a_nacionalizar()
	if not candidatos.is_empty():
		_lista_seleccion.add_child(HSeparator.new())
		var tn := _texto(11, COL_SUAVE)
		tn.text = "NACIONALIZACIÓN DEPORTIVA"
		_lista_seleccion.add_child(tn)
		for fila: Dictionary in candidatos:
			var j: Jugador = fila["jugador"]
			var fila_h := HBoxContainer.new()
			fila_h.add_theme_constant_override("separation", 8)
			_lista_seleccion.add_child(fila_h)
			var nom := _texto(12, COL_TEXTO)
			nom.text = "%s  ·  %d temporadas en el país" % [j.nombre, int(fila["temporadas"])]
			nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila_h.add_child(nom)
			var costo := s.costo_nacionalizacion(j)
			var b := Button.new()
			b.text = "Nacionalizar  %s" % _dinero(costo)
			b.add_theme_font_size_override("font_size", 11)
			b.disabled = costo > c.saldo
			b.pressed.connect(func() -> void: _nacionalizar(j))
			fila_h.add_child(b)

	_lista_seleccion.add_child(HSeparator.new())
	var tm := _texto(11, COL_SUAVE)
	tm.text = "MÁS INTERNACIONALES DEL MUNDO"
	_lista_seleccion.add_child(tm)
	for fila2: Dictionary in s.mas_convocados(8):
		var j2: Jugador = fila2["jugador"]
		var col := COL_ACENTO if j2.club_id == c.id else COL_TEXTO
		var lm := _texto(12, col)
		lm.text = "%s  ·  %d caps" % [j2.nombre, int(fila2["caps"])]
		_lista_seleccion.add_child(lm)

	_lista_seleccion.add_child(HSeparator.new())
	var te := _texto(11, COL_SUAVE)
	te.text = "ESCALAFÓN MUNDIAL"
	_lista_seleccion.add_child(te)
	for fila3: Dictionary in s.ranking(14):
		var propia := String(fila3["nombre"]) == s.nombre_seleccion()
		var le := _texto(12, COL_ACENTO if propia else COL_SUAVE)
		le.text = "%s%s  ·  %d" % ["> " if propia else "   ", String(fila3["nombre"]), int(fila3["fuerza"])]
		_lista_seleccion.add_child(le)

func _nacionalizar(j: Jugador) -> void:
	var problema := mundo.selecciones.nacionalizar(j)
	if problema != "":
		_escribir("[color=#e05555]No se puede nacionalizar: %s.[/color]" % problema)
		return
	_refrescar()

## LA CANTERA: las categorías inferiores, quién está listo para debutar, y las
## becas que evitan que un grande se lleve gratis a un chico sin ficha profesional.
## `vLinaje()` del HTML: las dinastías del club. `Cantera.familias()` lleva
## tiempo agrupando hijos de leyenda y parejas de hermanos, y su propio
## comentario dice que existe "para poder enseñarlas juntas en una pantalla" —
## una pantalla que no se había hecho. Las dinastías se construían solas y no se
## veían: el hijo de tu viejo capitán era un canterano más de la lista.
## FONDOS DE INVERSIÓN. Dinero hoy a cambio de un porcentaje del traspaso de un
## canterano mañana.
##
## Es la palanca más peligrosa del juego y por eso está aquí, en Cantera, al
## lado de los chicos: la cifra que ofrecen es tentadora justo cuando peor estás
## de caja, que es exactamente cuando peor se decide. Y a partir de que firmas,
## el fondo tiene voz: aparece cada tanto pidiendo que lo vendas.
func _pintar_fondos(c: Club) -> void:
	var ce := mundo.cesiones
	if ce == null:
		return
	_lista_cantera.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "💸 FONDOS DE INVERSIÓN"
	_lista_cantera.add_child(t)
	if not _modo_experto:
		var ex := _texto(10, COL_SUAVE)
		ex.text = "Compran un porcentaje del PRÓXIMO traspaso de un chico y te lo pagan hoy. Pagan por debajo de lo que vale porque asumen el riesgo, y el día que lo vendas ese porcentaje ya no es tuyo. Como mucho el %d%% de cada jugador." % Cesiones.PCT_MAX
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_cantera.add_child(ex)

	var jovenes: Array[Jugador] = []
	for j: Jugador in c.plantilla:
		if j.edad <= 23:
			jovenes.append(j)
	jovenes.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.valor > b.valor)
	if jovenes.is_empty():
		var vac := _texto(10, COL_SUAVE)
		vac.text = "No tienes ningún futbolista de 23 años o menos: los fondos solo compran derechos de jóvenes."
		vac.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_cantera.add_child(vac)
		return

	for i in mini(6, jovenes.size()):
		var j2: Jugador = jovenes[i]
		var vendido := ce.participacion_de(j2)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_lista_cantera.add_child(fila)
		var n := _texto(12, COL_ORO if vendido > 0 else COL_TEXTO)
		n.text = "%s  ·  %d años  ·  %s" % [j2.nombre, j2.edad, _dinero(j2.valor)]
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		fila.add_child(n)
		if vendido > 0:
			var v := _texto(11, COL_ROJO)
			v.text = "%d%% vendido" % vendido
			v.custom_minimum_size = Vector2(90, 0)
			fila.add_child(v)
		if vendido >= Cesiones.PCT_MAX:
			continue
		## Un solo tramo del 25%: si se pudiera elegir el porcentaje al punto, la
		## decisión se convertiría en un cálculo y no en una apuesta.
		for f: Array in Cesiones.FONDOS:
			var clave := String(f[0])
			var b := Button.new()
			b.text = "%s  %s" % [String(f[1]).split(" ")[0], _dinero(ce.oferta_de_fondo(j2, clave, 25))]
			b.add_theme_font_size_override("font_size", 10)
			b.clip_text = true
			b.tooltip_text = "%s  ·  vende el 25%% del próximo traspaso de %s" % [String(f[3]), j2.nombre]
			b.custom_minimum_size = Vector2(120, 0)
			b.pressed.connect(func() -> void:
				var p := ce.vender_participacion(j2, clave, 25, mundo.mi_club())
				if p != "":
					_escribir("[color=#e05555]No se pudo: %s.[/color]" % p)
				_refrescar())
			fila.add_child(b)

## `vLinajeExtra()`: EL MAPA DEL TALENTO. Qué países atraviesan una época dorada
## y cuáles una decadencia.
##
## Es la única pantalla del juego que dice DÓNDE hay que estar, y tiene fecha de
## caducidad escrita: una época dura entre cuatro y nueve años y después se
## apaga. Sin esto, el mundo es plano y poner ojeadores en un país o en otro solo
## cambia lo que cuesta el billete.
func _pintar_mapa_del_talento() -> void:
	if mundo.eras == null:
		return
	var mapa := mundo.eras.mapa_del_talento(mundo.anio)
	_lista_cantera.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "🌍 EL MAPA DEL TALENTO"
	_lista_cantera.add_child(t)
	if mapa.is_empty():
		var vac := _texto(11, COL_SUAVE)
		vac.text = "Ningún país atraviesa hoy una época marcada. Las generaciones irrepetibles aparecen solas, cada varios años, y duran lo que duran."
		vac.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_cantera.add_child(vac)
		return
	for e: Dictionary in mapa:
		var dorada := bool(e["dorada"])
		var n := _texto(12, COL_ORO if dorada else COL_ROJO)
		n.text = "%s %s  ·  %s" % ["✨" if dorada else "🥀", String(e["pais"]),
			"Época dorada" if dorada else "Decadencia"]
		_lista_cantera.add_child(n)
		var d := _texto(10, COL_SUAVE)
		d.text = "%d–%d (quedan %d año%s)  ·  %s  %s" % [
			int(e["desde"]), int(e["hasta"]), int(e["quedan"]),
			"" if int(e["quedan"]) == 1 else "s",
			String(e["texto"]), String(e["consejo"])]
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_cantera.add_child(d)

func _pintar_linaje(c: Club) -> void:
	_pintar_fondos(c)
	_pintar_mapa_del_talento()
	if mundo.cantera == null:
		return
	var fams := mundo.cantera.familias()
	## Solo las de TU club: las de los otros 383 son ruido.
	var mias := {}
	for clave: String in fams:
		var miembros: Array = fams[clave]
		var aqui: Array[Jugador] = []
		for j: Jugador in miembros:
			if j.club_id == c.id:
				aqui.append(j)
		if not aqui.is_empty():
			mias[clave] = aqui
	if mias.is_empty():
		return
	_lista_cantera.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "ÁRBOL GENEALÓGICO  ·  %d familia(s) en el plantel" % mias.size()
	_lista_cantera.add_child(t)
	for clave: String in mias:
		var titulo := ""
		if clave.begins_with("L:"):
			titulo = "⭐ Estirpe de %s" % Nombres.visible(clave.substr(2))
		else:
			var primero: Jugador = (mias[clave] as Array)[0]
			var partes := primero.nombre.split(" ")
			titulo = "👨‍👦 Hermanos %s" % Nombres.visible(partes[partes.size() - 1])
		var lt := _texto(12, COL_ORO)
		lt.text = titulo
		_lista_cantera.add_child(lt)
		for j: Jugador in mias[clave]:
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 8)
			_lista_cantera.add_child(fila)
			fila.add_child(_retrato(j, 24))
			var b := Button.new()
			b.text = j.nombre
			b.flat = true
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.add_theme_font_size_override("font_size", 12)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.pressed.connect(func() -> void: _ver_ficha(j))
			fila.add_child(b)
			var d := _texto(11, COL_SUAVE)
			d.text = "%d años  ·  %s  ·  media %d" % [j.edad, j.pos_e, j.ovr]
			fila.add_child(d)
			## EL APELLIDO QUE PESA. `Cantera` le cuelga una etiqueta al hijo de
			## una leyenda y cada semana mide si está a la altura: si rinde lo
			## bendicen, si no lo entierran. Todo eso corría sin que se viera
			## nada, así que la presión existía y el jugador no sabía por qué al
			## chico se le hundía la moral.
			var et: Dictionary = mundo.cantera.etiqueta_de(j)
			if not et.is_empty():
				var presion := int(et.get("presion", 0))
				var e2 := _texto(11, COL_ROJO if presion >= 4 else (COL_VERDE if int(et.get("cumple", 0)) >= 4 else COL_SUAVE))
				e2.text = "«el nuevo %s»  ·  presión %d/6" % [String(et.get("ref", "—")), presion]
				e2.tooltip_text = "La prensa lo compara con su padre en cada partido. A las seis semanas malas le pasa factura; a los ocho aciertos se lo quitan de encima para siempre."
				fila.add_child(e2)

func _pintar_cantera(c: Club) -> void:
	_limpiar(_lista_cantera)
	var ct := mundo.cantera
	if ct == null:
		return
	## LA ACADEMIA (10-16 años) va primero: es la cantera ANTES de la cantera,
	## y la que decide cómo llegan los que aparecen más abajo.
	PanelAcademia.pintar(_lista_cantera, mundo, _paleta_ficha(), func(error: String) -> void:
		if error != "":
			_escribir("[color=#e05555]%s.[/color]" % error.capitalize())
		_refrescar())

	## "LEYENDAS DEL CLUB" -su propia tarjeta en `vHistoria()` de vistas.js-:
	## `Cantera.leyendas` alimenta de verdad la camada anual (`registrar_retiro()`
	## mete a cada figura retirada, `camada_anual()` puede darle un hijo con su
	## apellido años después) pero hasta esta tanda no había ni una fila en
	## ningún sitio del juego que dijera qué leyendas tiene el club esperando:
	## el jugador nunca se enteraba de que Fulano se retiró como figura y que su
	## hijo podría debutar en unos años.
	var leyendas_del_club: Array[Dictionary] = []
	for l: Dictionary in ct.leyendas:
		if String(l.get("club_id", "")) == c.id:
			leyendas_del_club.append(l)
	if not leyendas_del_club.is_empty():
		var tley := _texto(11, COL_ORO)
		tley.text = "LEYENDAS DEL CLUB"
		_lista_cantera.add_child(tley)
		for l: Dictionary in leyendas_del_club:
			var lf := _texto(12, COL_SUAVE if bool(l.get("usado", false)) else COL_TEXTO)
			lf.text = "%s  ·  %s  ·  nivel %d%s" % [
				String(l.get("nombre", "")), String(l.get("pos", "")), int(l.get("nivel", 0)),
				"  · su hijo ya debutó" if bool(l.get("usado", false)) else "  · puede tener un hijo en %d" % int(l.get("anio_hijo", 0))]
			lf.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_lista_cantera.add_child(lf)
		_lista_cantera.add_child(HSeparator.new())

	var camada := ct.camada_actual()
	if not camada.is_empty():
		var tc := _texto(11, COL_ORO)
		tc.text = "LA CAMADA DE ESTE AÑO"
		_lista_cantera.add_child(tc)
		for j: Jugador in camada:
			_lista_cantera.add_child(_fila_canterano(j, ct, c))
		_lista_cantera.add_child(HSeparator.new())

	var listos := ct.candidatos_a_debutar()
	if not listos.is_empty():
		var tl := _texto(11, COL_VERDE)
		tl.text = "LISTOS PARA DEBUTAR"
		_lista_cantera.add_child(tl)
		var nombres: Array[String] = []
		for j: Jugador in listos:
			nombres.append(j.nombre)
		var ll := _texto(12, COL_TEXTO)
		ll.text = ", ".join(nombres)
		ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_cantera.add_child(ll)
		_lista_cantera.add_child(HSeparator.new())

	var cats := ct.por_categoria(c)
	for clave: String in cats:
		var datos: Dictionary = cats[clave]
		var jugadores: Array = datos["jugadores"]
		if jugadores.is_empty():
			continue
		var tcat := _texto(11, COL_SUAVE)
		tcat.text = String(datos["nombre"]).to_upper()
		_lista_cantera.add_child(tcat)
		for j: Jugador in jugadores:
			_lista_cantera.add_child(_fila_canterano(j, ct, c))
	## Las dinastías van al final: se leen después de la camada, que es lo que
	## se viene a mirar aquí todas las semanas.
	_pintar_linaje(c)

func _fila_canterano(j: Jugador, ct: Cantera, c: Club) -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	fila.add_child(_retrato(j, 24))
	var listo := ct.listo_para_debutar(j)
	var nom := _texto(12, COL_VERDE if listo else COL_TEXTO)
	var linaje: Dictionary = ct.linaje_de(j)
	var etiqueta := (" · hijo de %s" % String(linaje.get("padre", ""))) if not linaje.is_empty() else ""
	nom.text = "%s  ·  %d años  ·  %d/%d%s" % [j.nombre, j.edad, j.ovr, j.pot, etiqueta]
	nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fila.add_child(nom)
	## EL RIESGO DE FUGA. `riesgo_fuga()` corría desde el principio -se resuelve
	## solo en el pulso semanal de la cantera- pero no se veía en ninguna parte,
	## y sin verlo la beca es un gasto sin motivo: lo que la justifica es
	## exactamente este número, que baja dos puntos al becar. Cuanto mejor es el
	## chico (más `pot` sobre `ovr`), más se lo quieren llevar.
	## DE DÓNDE SALIÓ. `Cantera.origen_de()` estaba escrita, el dato se sorteaba
	## y se guardaba en la ficha de cada chico… y no la llamaba NADIE, ni
	## siquiera dentro del propio núcleo. Es una línea de historia por canterano
	## -de un potrero, de un colegio, del hijo del utilero- que existía y no se
	## leía en ninguna parte.
	var org: Dictionary = ct.origen_de(j)
	if not org.is_empty():
		var o := _texto(11, COL_SUAVE)
		o.text = "%s %s" % [String(org.get("icono", "")), String(org.get("frase", ""))]
		o.tooltip_text = String(org.get("historia", ""))
		o.custom_minimum_size = Vector2(150, 0)
		o.clip_text = true
		fila.add_child(o)
	var fuga := ct.riesgo_fuga(j)
	if fuga > 0.0:
		var rf := _texto(11, COL_ROJO if fuga >= 0.05 else COL_SUAVE)
		rf.text = "fuga %.1f%%" % (fuga * 100.0)
		rf.tooltip_text = "Probabilidad de que se lo lleve otro club esta semana. La beca la baja, y las instalaciones de cantera también."
		rf.custom_minimum_size = Vector2(64, 0)
		fila.add_child(rf)
	if ct.tiene_beca(j):
		var tag := _texto(11, COL_VERDE)
		tag.text = "becado"
		fila.add_child(tag)
	else:
		var costo := ct.coste_beca()
		var b := Button.new()
		b.text = "Becar  %s" % _dinero(costo)
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = costo > c.saldo
		b.pressed.connect(func() -> void: _becar(j))
		fila.add_child(b)
	return fila

func _becar(j: Jugador) -> void:
	var problema := mundo.cantera.becar(j)
	if problema != "":
		_escribir("[color=#e05555]No se puede becar: %s.[/color]" % problema)
		return
	_escribir("[color=#4caf6d]%s tiene beca.[/color] Menos riesgo de que se lo lleven gratis." % j.nombre)
	_refrescar()

## CONTRATOS: cesiones, cláusulas de rescisión y a quién prestar. La letra
## pequeña de un fichaje, que hasta hoy corría sola por dentro y no se podía
## ni ver ni decidir desde ningún lado.
## Los ROLES PROMETIDOS de `vContratos()`: qué papel le has jurado a cada uno.
##
## `Vestuario` lleva la promesa, la ventana de cumplimiento y el castigo de moral
## desde hace tanto que solo la renovación escribía ahí: fuera de la mesa de
## negociación no había forma de cambiarle el papel a nadie. Y es media mitad del
## sistema, porque prometer titular a un suplente y no darle minutos es
## exactamente lo que revienta un vestuario.
##
## `acepta_rol()` es lo que hace que no sea un desplegable tonto: el mejor de su
## puesto no acepta menos que titular, y a un quinto no le puedes prometer ser
## intocable porque sabe que no lo vas a cumplir.
func _pintar_roles_prometidos(c: Club) -> void:
	var v := mundo.vestuario
	if v == null:
		return
	var tabla := v.tabla_roles()
	if tabla.is_empty():
		return
	var t := _texto(11, COL_SUAVE)
	t.text = "ROLES PROMETIDOS"
	_lista_contratos.add_child(t)
	var ex := _texto(10, COL_SUAVE)
	ex.text = "Lo que le has prometido a cada uno. Bajarle el escalafón cuesta moral en el acto; subírselo la sube. Y prometer sin cumplir se paga después."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_contratos.add_child(ex)
	var plantel := c.plantilla.duplicate()
	plantel.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	for j: Jugador in plantel:
		var actual := v.rol_plantel(j)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_lista_contratos.add_child(fila)
		fila.add_child(_retrato(j, 22))
		var nom := _texto(12, COL_TEXTO)
		nom.text = "%s  %s  ·  %d" % [j.pos_e, j.nombre, j.ovr]
		nom.custom_minimum_size = Vector2(170, 0)
		fila.add_child(nom)
		var op := OptionButton.new()
		op.add_theme_font_size_override("font_size", 11)
		op.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var elegido := 0
		for n in tabla.size():
			var f: Array = tabla[n]
			op.add_item(String(f[1]), n)
			if String(f[0]) == actual:
				elegido = n
			## Los que no aceptaría salen en la lista pero apagados: ver lo que
			## NO puedes ofrecerle explica su sitio en el plantel mejor que
			## cualquier texto.
			if not bool(v.acepta_rol(j, String(f[0]))["ok"]):
				op.set_item_disabled(n, true)
		op.selected = elegido
		var jug := j
		var filas := tabla
		op.item_selected.connect(func(idx: int) -> void:
			_cambiar_rol_prometido(jug, String((filas[idx] as Array)[0])))
		fila.add_child(op)
		## Los minutos que exige el papel: es la promesa concreta, y lo que se
		## va a comprobar cuando toque.
		var def := v.def_rol(actual)
		if not def.is_empty():
			var mn := _texto(11, COL_SUAVE)
			mn.text = "%d%% min." % int(def[3])
			mn.custom_minimum_size = Vector2(56, 0)
			fila.add_child(mn)
	_lista_contratos.add_child(HSeparator.new())

func _cambiar_rol_prometido(j: Jugador, rol: String) -> void:
	var r: Dictionary = mundo.vestuario.cambiar_rol(j, rol)
	var txt := String(r.get("txt", ""))
	if txt != "":
		var col := "#4caf6d" if bool(r.get("ok", false)) else "#e05555"
		_escribir("[color=%s][b]%s.[/b][/color] %s" % [col, j.nombre, txt])
	_refrescar()

## LA GUERRA DE AGENTES. `Cantera.sortear_guerra_agentes()` corre CADA SEMANA
## desde `Mundo` y presiona de verdad: un representante con dos o más clientes
## tuyos te exige cosas. Pero `agencias_del_plantel()` -quién controla a quién y
## cuánto confía en ti- no la llamaba ninguna pantalla, así que la presión te
## llegaba sin que pudieras ver de dónde venía ni prepararte.
func _pintar_agencias(c: Club) -> void:
	if mundo.cantera == null:
		return
	var lista := mundo.cantera.agencias_del_plantel()
	if lista.is_empty():
		return
	var t := _texto(11, COL_SUAVE)
	t.text = "🕴️ AGENCIAS DEL PLANTEL"
	_lista_contratos.add_child(t)
	var ex := _texto(10, COL_SUAVE)
	ex.text = "Un representante con dos o más clientes tuyos tiene con qué apretarte. Aquí se ve quién los tiene."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_contratos.add_child(ex)
	for f: Dictionary in lista:
		var jugadores: Array = f["jugadores"]
		var ag: Dictionary = f["agente"]
		var conf := int(f.get("confianza", 50))
		## En rojo los que tienen fuerza para exigir: dos clientes o más es
		## exactamente el umbral que usa el sorteo semanal.
		var peligro := jugadores.size() >= 2
		var l := _texto(12, COL_ROJO if peligro and conf < 45 else COL_TEXTO)
		l.text = "%s  ·  %s  ·  %d jugador(es)  ·  confianza %d" % [
			String(ag.get("nombre", "un representante")), String(ag.get("perfil", "")),
			jugadores.size(), conf]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_contratos.add_child(l)
		var nombres: Array[String] = []
		for j: Jugador in jugadores:
			nombres.append(j.nombre)
		var n := _texto(10, COL_SUAVE)
		n.text = "    " + ", ".join(nombres)
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_contratos.add_child(n)
	_lista_contratos.add_child(HSeparator.new())

func _pintar_contratos(c: Club) -> void:
	_limpiar(_lista_contratos)
	_pintar_agencias(c)
	_pintar_roles_prometidos(c)
	var ce := mundo.cesiones
	if ce == null:
		return

	var fuera := ce.cedidos_de(c.id)
	if not fuera.is_empty():
		var tf := _texto(11, COL_SUAVE)
		var ahorro := ce.ahorro_salarial(c.id)
		tf.text = "CEDIDOS FUERA  ·  te ahorras %s/semana" % _dinero(ahorro)
		_lista_contratos.add_child(tf)
		for fila: Dictionary in fuera:
			var j: Jugador = fila["jugador"]
			var destino: Club = fila["club"]
			var d: Dictionary = fila["cesion"]
			var tipo := String(d.get("tipo", ""))
			var letra := "opción de compra" if tipo == Cesiones.CESION_OPCION \
				else ("obligación de compra" if tipo == Cesiones.CESION_OBLIGA else "préstamo simple")
			var l := _texto(12, COL_TEXTO)
			l.text = "%s  ·  en %s  ·  %s  ·  vuelve en %d" % [j.nombre, destino.nombre, letra, int(d.get("vuelve", 0))]
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_lista_contratos.add_child(l)
		_lista_contratos.add_child(HSeparator.new())

	## A quién prestar: juveniles hasta 21 -formación, cesión simple- y gente que
	## no juega -ya no es formación, es venta a plazo con opción u obligación.
	var candidatos_prestamo := c.plantilla.filter(func(j: Jugador) -> bool:
		return not ce.esta_cedido(j.id) and j.edad <= Cesiones.EDAD_CANTERANO)
	var candidatos_venta := c.plantilla.filter(func(j: Jugador) -> bool:
		return not ce.esta_cedido(j.id) and j.edad > Cesiones.EDAD_CANTERANO and j.partidos == 0)
	## Ceder es una decisión de mercado como fichar o vender: el mismo permiso.
	var puede_ceder := mundo.roles == null or mundo.roles.puede_fichar()
	if not puede_ceder:
		var np := _texto(12, COL_SUAVE)
		np.text = String(mundo.roles.motivo_bloqueo("fichar"))
		np.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_contratos.add_child(np)
		_lista_contratos.add_child(HSeparator.new())
	elif not candidatos_prestamo.is_empty() or not candidatos_venta.is_empty():
		var tc := _texto(11, COL_SUAVE)
		tc.text = "A QUIÉN CEDER"
		_lista_contratos.add_child(tc)
		for j: Jugador in candidatos_prestamo:
			var fila2 := HBoxContainer.new()
			fila2.add_theme_constant_override("separation", 8)
			_lista_contratos.add_child(fila2)
			var nom := _texto(12, COL_TEXTO)
			nom.text = "%s  ·  %d años  ·  cantera" % [j.nombre, j.edad]
			nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila2.add_child(nom)
			_boton("Ceder a préstamo", func() -> void: _ceder_canterano(j), fila2)
		for j: Jugador in candidatos_venta:
			var fila3 := HBoxContainer.new()
			fila3.add_theme_constant_override("separation", 6)
			_lista_contratos.add_child(fila3)
			var nom2 := _texto(12, COL_SUAVE)
			nom2.text = "%s  ·  %d años  ·  0 partidos" % [j.nombre, j.edad]
			nom2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila3.add_child(nom2)
			_boton("Con opción", func() -> void: _ceder_con_opcion(j, Cesiones.CESION_OPCION), fila3)
			_boton("Con obligación", func() -> void: _ceder_con_opcion(j, Cesiones.CESION_OBLIGA), fila3)
		_lista_contratos.add_child(HSeparator.new())

	## RENOVACIONES. `Cantera.pide_para_renovar()` llevaba tiempo sabiendo
	## calcular lo que pide cada uno -sueldo actual, recargo por moral baja y por
	## rendir por encima del club, y el multiplicador de su agente- y no había
	## forma de decirle que sí. Un contrato que se acaba y no se puede renovar es
	## un jugador que se pierde solo.
	##
	## Se listan los que entran en su último año, que son los que urgen.
	if ce != null and mundo.cantera != null and puede_ceder:
		var por_renovar := c.plantilla.filter(func(j: Jugador) -> bool: return j.anios_contrato <= 1)
		var tr := _texto(11, COL_SUAVE)
		tr.text = "RENOVACIONES  ·  último año de contrato"
		_lista_contratos.add_child(tr)
		if por_renovar.is_empty():
			var sin := _texto(12, COL_SUAVE)
			sin.text = "Nadie termina contrato esta temporada."
			_lista_contratos.add_child(sin)
		for j: Jugador in por_renovar:
			var pide := mundo.cantera.pide_para_renovar(j)
			var fila_r := HBoxContainer.new()
			fila_r.add_theme_constant_override("separation", 6)
			_lista_contratos.add_child(fila_r)
			var nr := _texto(12, COL_TEXTO)
			nr.text = "%s  ·  %d años  ·  media %d  ·  cobra %s → pide %s" % [
				j.nombre, j.edad, j.ovr, _dinero(j.sueldo), _dinero(pide)]
			nr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila_r.add_child(nr)
			_boton("Renovar", func() -> void: _renovar(j, false), fila_r)
			## Con cláusula cobra un 10% menos: le pones precio de salida y a
			## cambio te ahorras ficha. Es la decisión, no un adorno.
			_boton("Con cláusula (−10%)", func() -> void: _renovar(j, true), fila_r)
		_lista_contratos.add_child(HSeparator.new())

	## Las cláusulas de tu plantel: la protección va al revés que un fichaje, se
	## paga para que NADIE pueda llevarse a tu figura por la puerta de atrás.
	var tcl := _texto(11, COL_SUAVE)
	tcl.text = "CLÁUSULAS DE RESCISIÓN"
	_lista_contratos.add_child(tcl)
	var orden := c.plantilla.duplicate()
	orden.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	for j: Jugador in orden:
		var clau := ce.clausula_de(j)
		var fila4 := HBoxContainer.new()
		fila4.add_theme_constant_override("separation", 8)
		_lista_contratos.add_child(fila4)
		var nom3 := _texto(12, COL_TEXTO if clau > 0 else COL_SUAVE)
		nom3.text = "%s  ·  %s" % [j.nombre, _dinero(clau) if clau > 0 else "sin cláusula"]
		nom3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila4.add_child(nom3)
		var b := Button.new()
		b.text = "Blindar" if clau > 0 else "Pactar cláusula"
		b.add_theme_font_size_override("font_size", 11)
		b.pressed.connect(func() -> void: _pactar_clausula_propia(j))
		fila4.add_child(b)

## `vComparador()` de vistas.js -un archivo aparte de juego.js que esta sesión
## no había mirado hasta ahora, y donde vive el render real de las 33
## sub-pestañas de "Club"-: hasta tres jugadores lado a lado, con el mejor
## valor de cada fila resaltado en verde. Fuera de alcance a propósito: la
## fila "Ansiedad" del HTML no tiene equivalente -Godot no tiene portado
## `j.mente.ansiedad`, es un sistema propio, no un olvido de esta fila-. El
## "modo ciego" sí se portó después (`Ojeadores.modo_ciego`): esta tabla en
## particular no usa la palabra cualitativa de `ovr_palabra()` -el HTML tampoco
## lo hace aquí-, sino un simple "?" en la fila Media, igual que ya hacía la
## fila Proyección para quien no conocías.
func _pintar_comparar() -> void:
	_limpiar(_lista_comparar)
	var jugadores: Array[Jugador] = []
	for id in _comparar_ids:
		var j := mundo.jugador_por_id(id)
		if j != null:
			jugadores.append(j)
	## Si alguno se vendió, se retiró o fue rescindido entre medio, desaparece
	## solo del comparador -no queda un id muerto señalando a nadie-.
	_comparar_ids.clear()
	for j in jugadores:
		_comparar_ids.append(j.id)

	if jugadores.is_empty():
		var vacio := _texto(12, COL_SUAVE)
		vacio.text = "Abre la ficha de cualquier jugador y pulsa «Comparar» para ponerlo aquí. Puedes enfrentar hasta tres a la vez, de tu club o de cualquier otro."
		vacio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_comparar.add_child(vacio)
		return

	var cabecera := HBoxContainer.new()
	cabecera.add_theme_constant_override("separation", 12)
	_lista_comparar.add_child(cabecera)
	for j in jugadores:
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cabecera.add_child(col)
		var retrato := TextureRect.new()
		var suyo: Club = mundo.clubes.get(j.club_id)
		retrato.texture = Cara.textura(j, suyo.color1 if suyo else "#2b6b45", suyo.color2 if suyo else "#ffffff", 48)
		retrato.custom_minimum_size = Vector2(48, 48)
		retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		retrato.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(retrato)
		var nom := _texto(11, COL_TEXTO)
		nom.text = _apellido(j.nombre)
		nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(nom)
		var bq := Button.new()
		bq.text = "✕"
		bq.custom_minimum_size = Vector2(0, 26)
		bq.pressed.connect(func() -> void: _alternar_comparar(j))
		col.add_child(bq)
	_lista_comparar.add_child(HSeparator.new())

	var g := GridContainer.new()
	g.columns = 1 + jugadores.size()
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 3)
	_lista_comparar.add_child(g)

	## `mostrar_de` es aparte de `valor_de` para que Valor/Sueldo comparen el
	## número de verdad (`j.valor`/`j.sueldo`) y no la cadena ya formateada
	## ("7.4M EUR" nunca es `is int`, así que comparar cadenas dejaba a los
	## tres empatados en 0 y los resaltaba a los tres, o a ninguno).
	var conoce := func(j: Jugador) -> bool: return j.club_id == mundo.mi_club_id or mundo.ojeados.has(j.id)
	## `cegado()` del HTML: en "mercado a ciegas" ni la Media se enseña de
	## quien no conoces -aquí se ve un "?", no la palabra cualitativa de
	## `ovr_palabra()`, tal cual hace el HTML en ESTA tabla en particular-.
	var cegado := func(j: Jugador) -> bool:
		return mundo.ojeadores != null and mundo.ojeadores.modo_ciego and not conoce.call(j)
	var edad_de := func(j: Jugador) -> Variant: return j.edad
	var valor_de := func(j: Jugador) -> Variant: return j.valor
	var sueldo_de := func(j: Jugador) -> Variant: return j.sueldo
	var como_dinero := func(v: Variant) -> String: return _dinero(int(v))
	_fila_comparar(g, jugadores, "Media", func(j: Jugador) -> Variant: return "?" if cegado.call(j) else j.ovr)
	_fila_comparar(g, jugadores, "Proyección", func(j: Jugador) -> Variant: return j.pot if conoce.call(j) else "?")
	_fila_comparar(g, jugadores, "Edad", edad_de, false)
	_fila_comparar(g, jugadores, "Valor", valor_de, true, como_dinero)
	_fila_comparar(g, jugadores, "Sueldo", sueldo_de, false, como_dinero)
	var claves := jugadores[0].atributos.keys() if not jugadores.is_empty() else []
	for k: String in claves:
		var clave := k
		_fila_comparar(g, jugadores, String(NOMBRES_ATRIBUTOS.get(clave, clave)),
			func(j: Jugador) -> Variant: return int(j.atributos.get(clave, 0)) if j.atributos.has(clave) else "—")
	_fila_comparar(g, jugadores, "Forma", func(j: Jugador) -> Variant: return j.forma)
	_fila_comparar(g, jugadores, "Físico", func(j: Jugador) -> Variant: return j.fisico)
	_fila_comparar(g, jugadores, "Goles", func(j: Jugador) -> Variant: return j.goles)
	_fila_comparar(g, jugadores, "Partidos", func(j: Jugador) -> Variant: return j.partidos)

	if mundo.entrenamiento != null:
		_lista_comparar.add_child(HSeparator.new())
		var th := _texto(11, COL_SUAVE)
		th.text = "HABILIDADES"
		_lista_comparar.add_child(th)
		for j in jugadores:
			var claves_hab: Array = mundo.entrenamiento.habilidades(j)
			var nombres: Array[String] = []
			for k2 in claves_hab:
				nombres.append(mundo.entrenamiento.nombre_habilidad(String(k2)))
			var fh := HBoxContainer.new()
			_lista_comparar.add_child(fh)
			var eq := _texto(11, COL_TEXTO)
			eq.text = _apellido(j.nombre)
			eq.custom_minimum_size = Vector2(90, 0)
			fh.add_child(eq)
			var vh := _texto(11, COL_SUAVE)
			vh.text = ", ".join(nombres) if not nombres.is_empty() else "—"
			vh.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			vh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fh.add_child(vh)

	var vaciar := func() -> void:
		_comparar_ids.clear()
		_pintar_comparar()
	_boton("Vaciar comparador", vaciar, _lista_comparar)

## Una fila del comparador: etiqueta a la izquierda, un valor por jugador, con
## el mejor resaltado en verde -`mayor_mejor=false` para Edad y Sueldo, donde
## menos es mejor-. Los valores no numéricos (el "?" de una proyección sin
## ojear) cuentan como 0 y nunca ganan el resaltado, igual que `+v||0` en el
## HTML.
func _fila_comparar(g: GridContainer, jugadores: Array[Jugador], etiqueta: String, valor_de: Callable,
		mayor_mejor: bool = true, formatear: Callable = Callable()) -> void:
	_celda(g, etiqueta, COL_SUAVE)
	var valores: Array = []
	var numeros: Array[float] = []
	for j in jugadores:
		var v: Variant = valor_de.call(j)
		valores.append(v)
		numeros.append(float(v) if (v is int or v is float) else 0.0)
	var mejor := numeros[0]
	for n in numeros:
		if (mayor_mejor and n > mejor) or (not mayor_mejor and n < mejor):
			mejor = n
	## Igual que `(+v||0)===mejor` en el HTML: si todos empatan -incluido un
	## "?" contra otro "?"- se resaltan todos, no ninguno. No es un caso raro
	## que valga la pena tratar distinto, es lo que ya hacía el original.
	for i in valores.size():
		var texto: String = formatear.call(valores[i]) if formatear.is_valid() else str(valores[i])
		_celda(g, texto, COL_VERDE if numeros[i] == mejor else COL_TEXTO, true)

func _apellido(nombre: String) -> String:
	var partes := nombre.split(" ")
	return partes[partes.size() - 1] if not partes.is_empty() else nombre

func _alternar_comparar(j: Jugador) -> void:
	if _comparar_ids.has(j.id):
		_comparar_ids.erase(j.id)
	elif _comparar_ids.size() < 3:
		_comparar_ids.append(j.id)
	_pintar_comparar()
	_ver_ficha(j)

## `vRecords()` de vistas.js: rachas, marcas, goleadores e historial cara a
## cara. Todo esto ya lo llevaba `Logros` -`h2h`, `rachas`, `rec`, `efemerides`,
## `planteles`- desde que se enganchó la memoria del club, probado y guardado,
## pero la pestaña Logros solo enseñaba la vitrina de títulos y el top 5 de
## goleadores: el resto vivía en el guardado sin que nadie lo viera nunca.
## `vLegado()`: lo que queda de ti cuando te vas. Es la ÚNICA pantalla del juego
## que no habla del club sino del entrenador: el club se pierde al cambiar de
## banco, esto te sigue. Cuatro bloques, en el orden del HTML — el resumen, el
## palmarés, la escalera de rol y los homenajes— más el epílogo, que solo aparece
## a partir de la tercera temporada porque antes no hay carrera que resumir.
## `vInicio()`: la portada del club. Es la pantalla que el HTML abre por defecto
## cada semana y la que aquí no existía: se entraba directamente al Estadio y
## había que ir tabulando para saber si tenías gente lesionada o cómo iba la
## caja.
##
## No repite información: la RESUME y la enlaza. Los cuatro recuadros son atajos
## -pulsarlos lleva a la pestaña donde de verdad se decide-, que es lo que hace
## que una portada sirva para algo en vez de ser un adorno de bienvenida.
## EL INFORME DE GESTIÓN. Lo primero de la pantalla de Inicio: las seis cosas
## que hay que mirar cada lunes, juntas y con el botón que lleva a arreglarlas.
##
## No añade ninguna mecánica: junta lo que ya está repartido por ocho pestañas.
## Este juego tiene dieciocho, y sin esto un jugador nuevo no sabe cuáles mirar
## y uno veterano se olvida siempre de la misma.
func _pintar_informe() -> void:
	var lineas := mundo.informe_de_gestion()
	var t := _texto(11, COL_SUAVE)
	t.text = "📋 INFORME DE LA SEMANA"
	_lista_inicio.add_child(t)
	for f: Dictionary in lineas:
		var grave := bool(f["grave"])
		var tab := String(f.get("tab", ""))
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_lista_inicio.add_child(fila)
		var n := _texto(12, COL_ROJO if grave else COL_TEXTO)
		n.text = "%s %s" % ["●" if grave else "○", String(f["txt"])]
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fila.add_child(n)
		if tab == "":
			continue
		var b := Button.new()
		b.text = tab
		b.add_theme_font_size_override("font_size", 10)
		b.clip_text = true
		b.custom_minimum_size = Vector2(92, 24)
		b.pressed.connect(func() -> void: _ir_a_pestana(tab))
		fila.add_child(b)
	_lista_inicio.add_child(HSeparator.new())

func _pintar_inicio(c: Club) -> void:
	_limpiar(_lista_inicio)
	var liga := _liga_de(c)
	## EL TABLERO (25-9-2026): próximo partido con los dos escudos, anillos de
	## valoración, la cara de la estrella y la racha. Ver `TableroInicio`.
	TableroInicio.pintar(_lista_inicio, c, mundo, liga, _ir_a_pestana, _ver_ficha)
	_lista_inicio.add_child(HSeparator.new())
	_pintar_informe()
	_lista_inicio.add_child(HSeparator.new())

	## LOS ACCESOS RÁPIDOS. Se marcan en Ajustes y salen aquí, que es donde se
	## usan: entras al club y saltas a lo tuyo sin recorrer seis grupos.
	if not _favoritos.is_empty():
		var tfav := _texto(11, COL_SUAVE)
		tfav.text = "⭐ ACCESOS RÁPIDOS"
		_lista_inicio.add_child(tfav)
		var rej := HBoxContainer.new()
		rej.add_theme_constant_override("separation", 4)
		_lista_inicio.add_child(rej)
		for tab: String in _favoritos:
			var b := Button.new()
			b.text = tab
			b.add_theme_font_size_override("font_size", 11)
			b.clip_text = true
			b.custom_minimum_size = Vector2(70, 0)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.pressed.connect(func() -> void: _ir_a_pestana(tab))
			rej.add_child(b)
		_lista_inicio.add_child(HSeparator.new())

	## ÚLTIMOS RESULTADOS. Sale de `Liga.historial`, que se guarda desde la misma
	## tanda que la pantalla de competición: antes el resultado viajaba en una
	## señal y se perdía.
	var tr := _texto(11, COL_SUAVE)
	tr.text = "ÚLTIMOS RESULTADOS"
	_lista_inicio.add_child(tr)
	var puestos := 0
	for i in range(liga.historial.size() - 1, -1, -1):
		if puestos >= 5:
			break
		for r: Dictionary in liga.historial[i]:
			if r["local"] != c and r["visita"] != c:
				continue
			var gl := int(r["gl"])
			var gv := int(r["gv"])
			var mios := gl if r["local"] == c else gv
			var suyos := gv if r["local"] == c else gl
			var col := COL_VERDE if mios > suyos else (COL_ROJO if mios < suyos else COL_SUAVE)
			_dato("J%d  %s %d-%d %s" % [i + 1, (r["local"] as Club).nombre, gl, gv, (r["visita"] as Club).nombre],
				"✔" if mios > suyos else ("✕" if mios < suyos else "="), col, _lista_inicio)
			puestos += 1
	if puestos == 0:
		var vac := _texto(12, COL_SUAVE)
		vac.text = "Aún sin partidos jugados."
		_lista_inicio.add_child(vac)
	_lista_inicio.add_child(HSeparator.new())

	## CORREO RECIENTE: los tres últimos de la bandeja, con el punto de "sin
	## leer". Es el gancho para que el correo no se quede sin abrir nunca.
	var tc := _texto(11, COL_SUAVE)
	tc.text = "CORREO RECIENTE"
	_lista_inicio.add_child(tc)
	if _bandeja.is_empty():
		var vac2 := _texto(12, COL_SUAVE)
		vac2.text = "Sin novedades."
		_lista_inicio.add_child(vac2)
	else:
		for i in mini(3, _bandeja.size()):
			var m: Dictionary = _bandeja[i]
			var b := Button.new()
			b.text = ("●  " if not bool(m.get("leida", false)) else "     ") + String(m.get("titulo", ""))
			b.flat = true
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.clip_text = true
			b.custom_minimum_size = Vector2(120, 0)
			b.add_theme_font_size_override("font_size", 12)
			b.add_theme_color_override("font_color", _color_de_paleta(COL_TEXTO if not bool(m.get("leida", false)) else COL_SUAVE))
			b.pressed.connect(func() -> void: _ir_a_pestana("Correo"))
			_lista_inicio.add_child(b)

## La frase de "qué toca esta semana". Sale del mismo sitio que decide qué se
## juega al pulsar «Dirigir el partido», para que las dos no puedan discrepar.
func _texto_proximo_compromiso(c: Club) -> String:
	if not mundo.partido_de_copa().is_empty() and mundo.copa != null:
		return "%s · %s" % [mundo.copa.nombre, mundo.copa.nombre_de_ronda()]
	var liga := _liga_de(c)
	var par := liga.emparejamiento_de(c)
	if par.is_empty():
		return "Semana sin partido: entrenamiento doble."
	var rival: Club = par[0] if par[0] != c else par[1]
	var de_local: bool = par[0] == c
	return "vs %s  ·  %s  ·  jornada %d de %s" % [
		rival.nombre, "Local" if de_local else "Visita",
		liga.jornada_actual + 1, liga.nombre]

func _pintar_legado() -> void:
	_limpiar(_lista_legado)
	var r := mundo.roles
	if r == null:
		return
	var p: Dictionary = mundo.puntaje_carrera()

	## C4: LA HISTORIA DEL CLUB, antes que la tuya.
	var hi := _historia_de(mundo.mi_club())
	var th := _texto(11, COL_SUAVE)
	th.text = "HISTORIA DEL CLUB"
	_lista_legado.add_child(th)
	for linea: String in [HistoriaClub.resumen(hi), HistoriaClub.texto_historia(hi), HistoriaClub.texto_clasicos(hi), String(hi["epoca"])]:
		if linea.strip_edges() == "":
			continue
		var lh := _texto(12, COL_TEXTO)
		lh.text = linea
		lh.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_legado.add_child(lh)
	_lista_legado.add_child(HSeparator.new())

	var t := _texto(11, COL_SUAVE)
	t.text = "TU LEGADO"
	_lista_legado.add_child(t)
	var g := GridContainer.new()
	g.columns = 4
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 14)
	_lista_legado.add_child(g)
	for par in [["Temporadas", str(mundo.anio - 2026 + 1)], ["Títulos", str(r.trofeos.size())],
			["Prestigio", str(r.prestigio)], ["Puntaje", _miles(int(p["total"]))]]:
		var col := VBoxContainer.new()
		g.add_child(col)
		var et := _texto(10, COL_SUAVE)
		et.text = String(par[0])
		col.add_child(et)
		var va := _texto(16, COL_ORO)
		va.text = String(par[1])
		col.add_child(va)
	## El multiplicador solo se enseña si es distinto de 1: si no, es una línea
	## que dice "×1.0" y no significa nada.
	if absf(float(p["multiplicador"]) - 1.0) > 0.001:
		_dato("Multiplicador de desafíos", "×%.2f sobre %s de base" % [float(p["multiplicador"]), _miles(int(p["base"]))],
			COL_VERDE, _lista_legado)
	if not r.filosofia.is_empty():
		var fi := _texto(12, COL_ACENTO)
		fi.text = "📚 Tu escuela táctica: %s  (%s)" % [String(r.filosofia["nombre"]), String(r.filosofia.get("formacion", ""))]
		fi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_legado.add_child(fi)
	_lista_legado.add_child(HSeparator.new())

	var tp := _texto(11, COL_SUAVE)
	tp.text = "PALMARÉS POR COMPETICIÓN"
	_lista_legado.add_child(tp)
	var palmares := r.palmares_por_tipo()
	if palmares.is_empty():
		var vac := _texto(12, COL_SUAVE)
		vac.text = "Sin títulos todavía."
		_lista_legado.add_child(vac)
	else:
		for f: Dictionary in palmares:
			_dato("🏆 %s" % String(f["titulo"]), "×%d" % int(f["veces"]), COL_ORO, _lista_legado)
	_lista_legado.add_child(HSeparator.new())

	var tc := _texto(11, COL_SUAVE)
	tc.text = "📈 CARRERA PROFESIONAL"
	_lista_legado.add_child(tc)
	_dato("Rol actual", r.nombre_del_cargo().capitalize(), COL_TEXTO, _lista_legado)
	## LA LICENCIA Y EL MINIJUEGO (C7).
	if mundo.licencia != null:
		var lic := _texto(12, COL_TEXTO)
		lic.text = "🎓 %s" % mundo.licencia.nombre()
		_lista_club.add_child(lic)
		var motivo := mundo.licencia.puede_presentarse(mundo.anio, mundo.semana)
		if motivo == "":
			_boton("Presentarse al examen de %s" % Licencia.NIVELES[mundo.licencia.nivel + 1], _abrir_examen, _lista_club)
		else:
			var m2 := _texto(11, COL_SUAVE)
			m2.text = motivo
			_lista_club.add_child(m2)
		_boton("🎯 Minijuego: tanda de penales en el entrenamiento", _abrir_penales, _lista_club)

	var escalon := r.siguiente_escalon()
	if escalon != "":
		var e := _texto(11, COL_SUAVE)
		e.text = escalon
		e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_legado.add_child(e)
	if r.puede_ascender() != "":
		_boton("📈 Ascender a %s" % Roles.PERMISOS[r.puede_ascender()]["cargo"], _ascender_rol, _lista_legado)
	_lista_legado.add_child(HSeparator.new())

	## LA OFERTA DE OTRO CLUB. Va arriba del legado porque es lo unico de esta
	## pantalla que caduca: si no contestas, sigue ahi, pero es la decision mas
	## grande que se toma en todo el juego.
	if not r.oferta_de_club.is_empty():
		_lista_legado.add_child(HSeparator.new())
		var to := _texto(11, COL_ORO)
		to.text = "☎️ TE QUIEREN EN OTRO CLUB"
		_lista_legado.add_child(to)
		var no := _texto(13, COL_ORO)
		no.text = String(r.oferta_de_club["nombre"])
		_lista_legado.add_child(no)
		_dato("Salto de categoría", "+%d de reputación" % int(r.oferta_de_club["mejora"]),
			COL_VERDE, _lista_legado)
		_dato("Tu sueldo allí", "%s / semana" % _dinero(int(r.oferta_de_club["sueldo"])),
			COL_ORO, _lista_legado)
		var eo := _texto(10, COL_SUAVE)
		eo.text = "Aceptar cierra tu capítulo aquí y abre otro: el currículum se lo lleva todo. Rechazar sube la confianza de esta directiva, que se entera igual."
		eo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_legado.add_child(eo)
		var fila_o := HBoxContainer.new()
		fila_o.add_theme_constant_override("separation", 6)
		_lista_legado.add_child(fila_o)
		for par_o: Array in [[true, "Aceptar y marcharme"], [false, "Quedarme aquí"]]:
			var si_o: bool = par_o[0]
			var bo := Button.new()
			bo.text = String(par_o[1])
			bo.add_theme_font_size_override("font_size", 11)
			bo.clip_text = true
			bo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bo.pressed.connect(func() -> void:
				var msg := r.responder_oferta_de_club(si_o)
				_escribir("[color=#c9a227]%s[/color]" % msg)
				if si_o:
					_conectar_noticias()
					_seleccionado = null
					_llenar_selector()
				_refrescar())
			fila_o.add_child(bo)

	_pintar_desgaste(r)
	_pintar_rival_dt(r)
	_pintar_leyenda_viva(r)
	_pintar_patrimonio_dt(r)
	_pintar_filiales(r)
	_pintar_acceso_arbol()
	_pintar_homenajes(r)
	_pintar_sucesion(r)
	_pintar_fin_de_carrera(r)
	_pintar_epilogo(r)

## EL DESGASTE Y EL CURRÍCULUM. Las dos cosas que hacen que esto sea una carrera
## y no una partida: lo que te cuesta el cargo, y por dónde has pasado.
func _pintar_desgaste(r: Roles) -> void:
	_lista_legado.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "🔥 DESGASTE EN EL CARGO"
	_lista_legado.add_child(t)
	_dato("Nivel", "%d de 100" % r.desgaste,
		COL_ROJO if r.quemado() else (COL_ORO if r.desgaste >= 55 else COL_VERDE), _lista_legado)
	var d := _texto(10, COL_ROJO if r.quemado() else COL_SUAVE)
	if r.quemado():
		d.text = "Estás quemado. Duermes mal y se te nota: lo que dices en rueda de prensa vale la mitad. Cambiar de aire lo arregla; seguir aquí, no."
	elif r.desgaste >= 55:
		d.text = "Se te empieza a notar el ciclo. Ganar descansa; la funa quema el doble."
	else:
		d.text = "Entero. Cada semana en el cargo cansa un poco; ganar lo compensa."
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_legado.add_child(d)

	if r.curriculum.is_empty():
		return
	_lista_legado.add_child(HSeparator.new())
	var tc := _texto(11, COL_SUAVE)
	tc.text = "📄 CURRÍCULUM"
	_lista_legado.add_child(tc)
	for i in range(r.curriculum.size() - 1, -1, -1):
		var c: Dictionary = r.curriculum[i]
		var hasta := int(c.get("hasta", 0))
		var l := _texto(12, COL_ORO if hasta == 0 else COL_TEXTO)
		l.text = "%s  ·  %d–%s" % [String(c.get("nombre", "")), int(c.get("desde", 0)),
			"hoy" if hasta == 0 else str(hasta)]
		_lista_legado.add_child(l)
		if hasta != 0:
			var m := _texto(10, COL_SUAVE)
			m.text = "     %d título(s) al irte  ·  %s" % [int(c.get("trofeos", 0)), String(c.get("motivo", ""))]
			_lista_legado.add_child(m)

## `vCarrera()`: EL RIVAL PERSONAL. No se elige y no se puede quitar: nace del
## club con el que más te has picado, y a partir de ahí cada cruce se cuenta
## aparte. Es la única estadística del juego que no es del club, es tuya.
func _pintar_rival_dt(r: Roles) -> void:
	if r.rival_dt.is_empty():
		return
	_lista_legado.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "👔 TU RIVAL"
	_lista_legado.add_child(t)
	var c: Club = mundo.clubes.get(String(r.rival_dt.get("club_id", "")))
	var n := _texto(13, COL_ROJO)
	n.text = "%s  ·  %s" % [String(r.rival_dt.get("nombre", "")), c.nombre if c else "?"]
	_lista_legado.add_child(n)
	var e := _texto(10, COL_SUAVE)
	e.text = String(r.rival_dt.get("estilo", ""))
	e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_legado.add_child(e)
	var pj := int(r.rival_dt.get("pj", 0))
	_dato("Cara a cara desde %d" % int(r.rival_dt.get("desde", 0)),
		"%d–%d–%d en %d duelo%s" % [int(r.rival_dt.get("g", 0)), int(r.rival_dt.get("e", 0)),
			int(r.rival_dt.get("p", 0)), pj, "" if pj == 1 else "s"],
		COL_TEXTO, _lista_legado)
	var tension := int(r.rival_dt.get("tension", 0))
	_dato("Tensión", "%d de 100" % tension,
		COL_ROJO if tension >= 80 else (COL_ORO if tension >= 60 else COL_SUAVE), _lista_legado)
	if tension >= 80 and not _modo_experto:
		var av := _texto(10, COL_ROJO)
		av.text = "Está a punto de salirse de la cancha. El próximo cruce puede acabar en el túnel y con los micrófonos abiertos."
		av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_legado.add_child(av)

## LA LEYENDA VIVA. Un ex jugador ligado al club de por vida. No entrena, no
## fila y no sale en ninguna estadística: viene, habla con los chicos y está.
func _pintar_leyenda_viva(r: Roles) -> void:
	_lista_legado.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "🕰️ LEYENDA VIVA DEL CLUB"
	_lista_legado.add_child(t)
	if not r.leyenda_viva.is_empty():
		var n := _texto(13, COL_ORO)
		n.text = "%s  ·  %s" % [String(r.leyenda_viva.get("nombre", "")), String(r.leyenda_viva.get("pos", ""))]
		_lista_legado.add_child(n)
		_dato("Ligado al club desde", str(int(r.leyenda_viva.get("desde", 0))), COL_SUAVE, _lista_legado)
		var d := _texto(10, COL_SUAVE)
		d.text = "Cada seis semanas se sienta con un juvenil del plantel. Le sube la moral y a veces algo más."
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_legado.add_child(d)
		return
	## Solo veteranos de la casa: nombrar leyenda a un fichaje de enero sería
	## un chiste, y el juego se lo tomaría en serio.
	var mio := mundo.mi_club()
	var candidatos: Array[Jugador] = []
	if mio != null:
		for j: Jugador in mio.plantilla:
			if j.edad >= 32 and j.club_formacion == mio.id:
				candidatos.append(j)
	if candidatos.is_empty():
		var vac := _texto(10, COL_SUAVE)
		vac.text = "Todavía no hay a quién nombrar. Hace falta un veterano de 32 años o más formado en la casa."
		vac.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_legado.add_child(vac)
		return
	var ex := _texto(10, COL_SUAVE)
	ex.text = "Nombrar a alguien lo liga al club de por vida. La hinchada lo agradece de inmediato."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_legado.add_child(ex)
	for j: Jugador in candidatos:
		var quien := j
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_lista_legado.add_child(fila)
		var l := _texto(12, COL_TEXTO)
		l.text = "%s  ·  %s, %d años" % [j.nombre, j.pos_e, j.edad]
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.clip_text = true
		fila.add_child(l)
		var b := Button.new()
		b.text = "Nombrar"
		b.add_theme_font_size_override("font_size", 11)
		b.custom_minimum_size = Vector2(90, 0)
		b.pressed.connect(func() -> void:
			var msg := r.nombrar_leyenda_viva(quien)
			if msg != "":
				_escribir("[color=#e05555]No se pudo: %s.[/color]" % msg)
			_refrescar())
		fila.add_child(b)

## LOS CLUBES FILIALES. `Entrenamiento.puede_comprar_filiales()` estaba escrita
## desde el porte y no la llamaba nadie: la habilidad «Magnate» del árbol se
## podía comprar con un punto y no servía absolutamente para nada.
func _pintar_filiales(r: Roles) -> void:
	if mundo.entrenamiento == null:
		return
	var puede := mundo.entrenamiento.puede_comprar_filiales()
	if not puede and r.filiales.is_empty():
		return
	_lista_legado.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "🏦 TUS CLUBES"
	_lista_legado.add_child(t)
	if not r.filiales.is_empty():
		for cid: String in r.filiales:
			var c: Club = mundo.clubes.get(cid)
			if c == null:
				continue
			_dato(c.nombre, "rep %d  ·  dividendo %s cada %d semanas" % [
				c.rep, _dinero(c.rep * c.rep * 40), Roles.SEMANAS_DIVIDENDO],
				COL_ORO, _lista_legado)
	if not puede:
		var av := _texto(10, COL_SUAVE)
		av.text = "Para comprar un club hace falta la habilidad «Magnate» del árbol de entrenador."
		av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_legado.add_child(av)
		return
	if not _modo_experto:
		var ex := _texto(10, COL_SUAVE)
		ex.text = "Se compran con TU dinero, no con el del club. Cuesta tres veces la caja de referencia del club y devuelve dividendos cada tres meses."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_legado.add_child(ex)
	## Los cinco más baratos que todavía no son tuyos: la lista entera serían
	## trescientos ochenta y tres botones.
	var comprables: Array[Club] = []
	for c2: Club in mundo.clubes.values():
		if c2.id == mundo.mi_club_id or r.filiales.has(c2.id):
			continue
		comprables.append(c2)
	comprables.sort_custom(func(a: Club, b: Club) -> bool: return a.rep < b.rep)
	for i in mini(5, comprables.size()):
		var c3: Club = comprables[i]
		var precio := r.precio_filial(c3)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_lista_legado.add_child(fila)
		var l2 := _texto(12, COL_TEXTO)
		l2.text = "%s  ·  rep %d" % [c3.nombre, c3.rep]
		l2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l2.clip_text = true
		fila.add_child(l2)
		var b2 := Button.new()
		b2.text = _dinero(precio)
		b2.add_theme_font_size_override("font_size", 11)
		b2.disabled = r.patrimonio < precio
		b2.custom_minimum_size = Vector2(110, 0)
		b2.pressed.connect(func() -> void:
			var msg := r.comprar_filial(c3)
			if msg != "":
				_escribir("[color=#e05555]No se pudo comprar: %s.[/color]" % msg)
			_refrescar())
		fila.add_child(b2)

## LA SUCESIÓN. A quién le dejas el club. No cambia tu partida —ya se acabó— y
## por eso importa: es lo único que solo sirve para decidir cómo quieres que se
## recuerde lo que hiciste.
func _pintar_sucesion(r: Roles) -> void:
	if r.retirado.is_empty():
		return
	_lista_legado.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "🪑 LA SUCESIÓN"
	_lista_legado.add_child(t)
	if not r.sucesor.is_empty():
		var n := _texto(13, COL_ORO)
		n.text = String(r.sucesor.get("nombre", ""))
		_lista_legado.add_child(n)
		var d := _texto(11, COL_SUAVE)
		d.text = "%s El directorio le da un margen de %d partidos." % [
			String(r.sucesor.get("desc", "")), int(r.sucesor.get("margen", 0))]
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_legado.add_child(d)
		return
	var ex := _texto(10, COL_SUAVE)
	ex.text = "Te retiraste. Lo último que decides es a quién le dejas el banquillo."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_legado.add_child(ex)
	var lista := r.candidatos_sucesion()
	for i in lista.size():
		var idx := i
		var cand: Dictionary = lista[i]
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_lista_legado.add_child(fila)
		var l := _texto(12, COL_TEXTO)
		l.text = "%s  ·  margen %d partidos" % [String(cand["nombre"]), int(cand["margen"])]
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.clip_text = true
		l.tooltip_text = String(cand["desc"])
		fila.add_child(l)
		var b := Button.new()
		b.text = "Elegir"
		b.add_theme_font_size_override("font_size", 11)
		b.custom_minimum_size = Vector2(80, 0)
		b.pressed.connect(func() -> void:
			r.elegir_sucesor(idx)
			_refrescar())
		fila.add_child(b)
		var d2 := _texto(10, COL_SUAVE)
		d2.text = String(cand["desc"])
		d2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_legado.add_child(d2)

## `vCarrera()`: tu patrimonio personal y en qué lo inviertes.
##
## Hasta ahora el entrenador no cobraba: el club pagaba sueldos y él no tenía
## bolsillo. Y sin bolsillo no hay carrera personal, solo gestión de un club.
##
## Lo que se compra aquí NO mejora al equipo: mejora al ENTRENADOR, y te sigue
## cuando cambias de banquillo. Es dinero tuyo, no del club, y esa separación es
## todo el sentido de la pantalla.
func _pintar_patrimonio_dt(r: Roles) -> void:
	_lista_legado.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "💼 TU PATRIMONIO"
	_lista_legado.add_child(t)
	_dato("Ahorros", _dinero(r.patrimonio), COL_ORO, _lista_legado)
	_dato("Tu sueldo", "%s / semana" % _dinero(r.sueldo_semanal()), COL_TEXTO, _lista_legado)
	_dato("Semanas dirigiendo", str(r.semanas_trabajadas), COL_SUAVE, _lista_legado)
	var lic := ["ninguna", "Licencia B", "Licencia A", "Licencia PRO"]
	_dato("Titulación", String(lic[clampi(r.licencia, 0, 3)]),
		COL_VERDE if r.licencia > 0 else COL_SUAVE, _lista_legado)
	if not _modo_experto:
		var ex := _texto(10, COL_SUAVE)
		ex.text = "Es dinero TUYO, no del club. Lo que compres aquí te sigue cuando cambies de banquillo."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_legado.add_child(ex)
	for f: Array in Roles.COMPRAS_DT:
		var clave := String(f[0])
		var tengo := r.tiene(clave)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_lista_legado.add_child(fila)
		var n := _texto(12, COL_VERDE if tengo else COL_TEXTO)
		n.text = "%s%s" % ["✔  " if tengo else "     ", String(f[1])]
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		n.tooltip_text = String(f[3])
		fila.add_child(n)
		var b := Button.new()
		b.text = "Puesto" if tengo else _dinero(int(f[2]))
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = tengo or r.patrimonio < int(f[2])
		b.custom_minimum_size = Vector2(96, 0)
		b.pressed.connect(func() -> void: _comprar_dt(clave))
		fila.add_child(b)
		if not tengo and not _modo_experto:
			var d := _texto(10, COL_SUAVE)
			d.text = "     %s" % String(f[3])
			d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_lista_legado.add_child(d)

func _comprar_dt(clave: String) -> void:
	var problema := mundo.roles.comprar_dt(clave)
	if problema != "":
		_escribir("[color=#e05555]No se pudo: %s.[/color]" % problema)
	_refrescar()

## El ÁRBOL DE CARRERA DEL ENTRENADOR de `vCarrera()`: cinco ramas, un punto
## cada diez semanas, y nodos encadenados por requisito. Otro sistema entero
## escrito, probado y sin una sola llamada desde la interfaz —los puntos se
## acumulaban solos temporada tras temporada sin que hubiera dónde gastarlos.
##
## Va en Legado y no en el Club porque es de la CARRERA: como el prestigio y la
## vitrina, te sigue cuando cambias de banquillo.
## MI VIDA (26-9-2026).
func _pintar_vida() -> void:
	if _lista_vida == null or not _lista_vida.is_visible_in_tree():
		return
	PanelVida.pintar(_lista_vida, self, mundo, _secc_vida)

## EL ÁRBOL DE HABILIDADES, COMO ESQUEMA (26-9-2026): columnas por rama, nodos
## y líneas de requisito, y la ficha de la elegida debajo.
func _pintar_habilidades() -> void:
	if _lista_habilidades == null or not _lista_habilidades.is_visible_in_tree():
		return
	_limpiar(_lista_habilidades)
	var e := mundo.entrenamiento
	if e == null:
		return
	var cab := HBoxContainer.new()
	_lista_habilidades.add_child(cab)
	## El título se recorta en vez de ensanchar el panel (recorrido D4): con
	## las columnas laterales abiertas empujaba la ficha fuera de pantalla.
	var tit := Tema.etiqueta(Tema.TAM_DESTACADO + 2, Tema.ORO, "🎓 HABILIDADES")
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tit.clip_text = true
	tit.custom_minimum_size.x = 60
	cab.add_child(tit)
	var pts := Tema.etiqueta(Tema.TAM_CUERPO, Tema.ORO if e.dt_puntos > 0 else Tema.SUAVE,
		"%d punto%s por gastar" % [e.dt_puntos, "" if e.dt_puntos == 1 else "s"])
	cab.add_child(pts)
	if e.dt_puntos > 0:
		(func() -> void: Animar.pulso(pts, 1.15)).call_deferred()
	var grande := Button.new()
	grande.text = "⛶ En grande"
	grande.pressed.connect(func() -> void: ArbolHabilidades.abrir_en_grande(self, e, _refrescar))
	cab.add_child(grande)
	var arbol := ArbolHabilidades.crear(e)
	_lista_habilidades.add_child(arbol)
	_lista_habilidades.add_child(arbol.ficha())
	## Las 15 maestrías de 30 niveles, debajo del árbol.
	PanelMaestrias.pintar(_lista_habilidades, mundo, self)
	arbol.aprendida.connect(func(_k: String) -> void:
		Aviso.mostrar(self, "nivel", "🎓", "Habilidad aprendida", e.dt_nombre(_k))
		_refrescar())
	Animar.aparecer(arbol)

## En Legado queda un resumen con el acceso al árbol, que vive en MI VIDA.
func _pintar_acceso_arbol() -> void:
	var e := mundo.entrenamiento
	if e == null:
		return
	var hb := HBoxContainer.new()
	_lista_legado.add_child(hb)
	var t := _texto(12, COL_ORO if e.dt_puntos > 0 else COL_SUAVE)
	t.text = "🎓 Habilidades de entrenador · %d punto(s) por gastar" % e.dt_puntos
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(t)
	var b := Button.new()
	b.text = "Ver el árbol"
	b.pressed.connect(func() -> void:
		_elegir_grupo("vida")
		_ir_a_chip({"tab": "Habilidades", "label": "Habilidades"}))
	hb.add_child(b)
	_lista_legado.add_child(HSeparator.new())

func _pintar_arbol_dt() -> void:
	var e := mundo.entrenamiento
	if e == null:
		return
	var t := _texto(11, COL_SUAVE)
	t.text = "🎓 TUS HABILIDADES DE ENTRENADOR"
	_lista_legado.add_child(t)
	var pts := _texto(14, COL_ORO if e.dt_puntos > 0 else COL_SUAVE)
	pts.text = "%d punto(s) por gastar  ·  se gana uno cada %d semanas" % [
		e.dt_puntos, Entrenamiento.SEMANAS_POR_PUNTO_DT]
	_lista_legado.add_child(pts)
	for rama: String in e.dt_ramas():
		var tr := _texto(10, COL_ACENTO)
		tr.text = rama.to_upper()
		_lista_legado.add_child(tr)
		for clave: String in (e.dt_ramas()[rama] as Array):
			var tengo := e.dt_tiene(clave)
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 6)
			_lista_legado.add_child(fila)
			var nom := _texto(12, COL_VERDE if tengo else COL_TEXTO)
			nom.text = "%s  %s" % [e.dt_icono(clave), e.dt_nombre(clave)]
			nom.custom_minimum_size = Vector2(170, 0)
			fila.add_child(nom)
			var desc := _texto(11, COL_SUAVE)
			desc.text = e.dt_descripcion(clave)
			desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			fila.add_child(desc)
			if tengo:
				var ya := _texto(11, COL_VERDE)
				ya.text = "✔"
				ya.custom_minimum_size = Vector2(70, 0)
				fila.add_child(ya)
				continue
			## Cuando no se puede, el botón dice POR QUÉ en vez de estar gris y
			## mudo: "antes: Pizarra fina" y "te faltan 2 punto(s)" son dos
			## problemas distintos y el jugador tiene que poder distinguirlos.
			var motivo := e.dt_motivo(clave)
			var b := Button.new()
			b.text = "%d pto(s)" % e.dt_coste(clave) if motivo == "" else motivo
			b.add_theme_font_size_override("font_size", 10)
			b.disabled = motivo != ""
			b.custom_minimum_size = Vector2(140, 0)
			var k := clave
			b.pressed.connect(func() -> void: _aprender_dt(k))
			fila.add_child(b)
	_lista_legado.add_child(HSeparator.new())

## El mensaje de éxito lo escribe `entrenamiento.noticia`, ya conectada; aquí
## solo se saca el motivo cuando falla.
func _aprender_dt(clave: String) -> void:
	var problema := mundo.entrenamiento.dt_aprender(clave)
	if problema != "":
		_escribir("[color=#e05555]No puedes aprender eso: %s.[/color]" % problema)
	_refrescar()

## Las leyendas de TU club, con el botón de homenaje. Se filtran por club a
## propósito: homenajear en el Madrid a una leyenda del Boca no significa nada.
func _pintar_homenajes(r: Roles) -> void:
	var th := _texto(11, COL_SUAVE)
	th.text = "🎖️ HOMENAJES"
	_lista_legado.add_child(th)
	var c := mundo.mi_club()
	var mias: Array[Dictionary] = []
	if mundo.cantera != null:
		for l: Dictionary in mundo.cantera.leyendas:
			if String(l.get("club", "")) == c.id and mias.size() < 6:
				mias.append(l)
	if mias.is_empty():
		var vac := _texto(12, COL_SUAVE)
		vac.text = "Sin leyendas registradas en este club todavía."
		_lista_legado.add_child(vac)
	else:
		var coste := Eco.escalar(Roles.COSTE_HOMENAJE, c.rep)
		for l2: Dictionary in mias:
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 8)
			_lista_legado.add_child(fila)
			var nom := _texto(12, COL_TEXTO)
			nom.text = "%s  ·  %s · nivel %d" % [String(l2.get("nombre", "")), String(l2.get("pos", "")), int(l2.get("nivel", 1))]
			nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila.add_child(nom)
			var b := Button.new()
			b.text = "Homenajear  %s" % _dinero(coste)
			b.add_theme_font_size_override("font_size", 11)
			b.disabled = c.saldo < coste
			var quien := String(l2.get("nombre", ""))
			b.pressed.connect(func() -> void: _homenajear(quien))
			fila.add_child(b)
		var nota := _texto(10, COL_SUAVE)
		nota.text = "Un homenaje llena el estadio, sube el ánimo y la moral del plantel, y deja al club un poco más grande."
		nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_legado.add_child(nota)
	_lista_legado.add_child(HSeparator.new())

func _pintar_fin_de_carrera(r: Roles) -> void:
	var tf := _texto(11, COL_SUAVE)
	tf.text = "🏁 FIN DE CARRERA"
	_lista_legado.add_child(tf)
	if not r.retirado.is_empty():
		var ya := _texto(12, COL_ORO)
		ya.text = "Te retiraste en %d con %d título(s) y %s puntos." % [
			int(r.retirado.get("anio", 0)), r.trofeos.size(), _miles(int(r.retirado.get("puntaje", 0)))]
		ya.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_legado.add_child(ya)
	else:
		var av := _texto(11, COL_SUAVE)
		av.text = "Cuando quieras cerrar la historia, puedes anunciar tu retirada y ver el balance completo de tu carrera. No se puede deshacer."
		av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_legado.add_child(av)
		_boton("¿SEGURO? Anunciar mi retirada" if _confirmar_retiro else "🏁 Anunciar mi retirada",
			_retirarse, _lista_legado)

## `epilogoHTML()`: el resumen con veredicto. Antes de la tercera temporada no
## sale, porque juzgar una carrera de dos años es ruido.
func _pintar_epilogo(r: Roles) -> void:
	var anios := mundo.anio - 2026
	if anios < 3:
		return
	_lista_legado.add_child(HSeparator.new())
	var te := _texto(11, COL_SUAVE)
	te.text = "📖 TU CARRERA HASTA AQUÍ"
	_lista_legado.add_child(te)
	var invicto := int(mundo.logros.rachas.get("invicto_max", 0)) if mundo.logros != null else 0
	## Los canteranos que DEBUTARON, no los que subieron a la lista: subir a un
	## chico al primer equipo y no ponerlo nunca no es hacer cantera.
	var canteranos := mundo.logros.canteranos_debutados.size() if mundo.logros != null else 0
	var g := GridContainer.new()
	g.columns = 3
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 14)
	_lista_legado.add_child(g)
	for par in [["Temporadas", str(anios)], ["Títulos", str(r.trofeos.size())],
			["Clubes", str(r.historial.size() + 1)], ["Prestigio", str(r.prestigio)],
			["Invicto máx.", str(invicto)], ["Canteranos", str(canteranos)]]:
		var col := VBoxContainer.new()
		g.add_child(col)
		var et := _texto(10, COL_SUAVE)
		et.text = String(par[0])
		col.add_child(et)
		var va := _texto(15, COL_TEXTO)
		va.text = String(par[1])
		col.add_child(va)
	var v: Dictionary = r.veredicto_carrera()
	var tonos := {"oro": COL_ORO, "verde": COL_VERDE, "ambar": COL_ACENTO, "suave": COL_SUAVE}
	var frase := _texto(13, tonos.get(String(v["tono"]), COL_SUAVE))
	frase.text = String(v["texto"])
	frase.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_legado.add_child(frase)
	## La vitrina cierra el epílogo: los doce últimos, que es lo que cabe sin
	## que la lista se coma la pantalla.
	if not r.trofeos.is_empty():
		var ult := r.trofeos.slice(maxi(0, r.trofeos.size() - 12))
		var partes: Array[String] = []
		for tro: Dictionary in ult:
			partes.append("🏆 %s %s" % [String(tro.get("titulo", "")), str(tro.get("anio", ""))])
		var vit := _texto(11, COL_ORO)
		vit.text = "  ·  ".join(partes)
		vit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_legado.add_child(vit)

func _homenajear(nombre: String) -> void:
	var problema := mundo.roles.homenajear(nombre)
	if problema != "":
		_escribir("[color=#e05555]No se pudo hacer el homenaje: %s.[/color]" % problema)
	_refrescar()

func _retirarse() -> void:
	if not _confirmar_retiro:
		_confirmar_retiro = true
		_refrescar()
		return
	_confirmar_retiro = false
	var problema := mundo.roles.retirarse()
	if problema != "":
		_escribir("[color=#e05555]%s.[/color]" % problema)
	_refrescar()

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

func _filtrar_records() -> void:
	var titulos: Array = []
	for k: String in SECC_RECORDS:
		titulos.append_array(SECC_RECORDS[k] as Array)
	var visibles: Array = SECC_RECORDS.get(_secc_records, [])
	## Antes del primer título no hay sección: eso se ve siempre -es la
	## cabecera de la pantalla-.
	var mostrando := true
	for n in _lista_records.get_children():
		var l := n as Label
		if l != null and titulos.has(l.text):
			mostrando = visibles.has(l.text)
		if n is CanvasItem:
			(n as CanvasItem).visible = mostrando
	## FALLA VISUAL (recorrido D4): al empezar una partida Memoria, Rivales y
	## Vitrina salían en blanco -sus secciones solo se pintan cuando hay datos-.
	## Una página en blanco parece un error; esto dice qué va a aparecer ahí.
	var alguno := false
	for n in _lista_records.get_children():
		if n is CanvasItem and (n as CanvasItem).visible and not n.is_queued_for_deletion():
			alguno = true
			break
	if not alguno:
		var vacio := _texto(13, COL_SUAVE)
		vacio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vacio.text = String(VACIO_RECORDS.get(_secc_records, "Todavía no hay nada que mostrar aquí: se llena al jugar."))
		_lista_records.add_child(vacio)

const VACIO_RECORDS := {
	"memoria": "📜 Aquí quedará la memoria del club: el salón de la fama, lo que pasó un día como hoy y el plantel de cada temporada. Se llena a medida que juegas.",
	"rivales": "⚔️ El cara a cara con cada rival aparece en cuanto te enfrentes a él.",
	"vitrina": "🏆 Los goleadores de tu era y los que más partidos juegan aparecen al avanzar la temporada.",
	"records": "📈 Las rachas y las marcas del club se registran desde el primer partido.",
}

func _pintar_records() -> void:
	_limpiar(_lista_records)
	var lg := mundo.logros
	if lg == null:
		return

	var tr := _texto(11, COL_SUAVE)
	tr.text = "RACHAS"
	_lista_records.add_child(tr)
	var gr := GridContainer.new()
	gr.columns = 4
	gr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gr.add_theme_constant_override("h_separation", 14)
	_lista_records.add_child(gr)
	var r: Dictionary = lg.rachas
	for par in [["Invicto máximo", "invicto_max"], ["Más victorias seguidas", "ganando_max"],
			["Peor sequía", "sin_ganar_max"], ["Racha actual", "invicto"]]:
		var col := VBoxContainer.new()
		gr.add_child(col)
		var et := _texto(10, COL_SUAVE)
		et.text = String(par[0])
		col.add_child(et)
		var va := _texto(16, COL_TEXTO)
		va.text = str(int(r.get(par[1], 0)))
		col.add_child(va)
	_lista_records.add_child(HSeparator.new())

	var rec: Dictionary = lg.rec
	if rec.has("mayor_goleada"):
		var tm := _texto(11, COL_SUAVE)
		tm.text = "MARCAS DEL CLUB"
		_lista_records.add_child(tm)
		var mg: Dictionary = rec["mayor_goleada"]
		_dato("Mayor goleada", "%s con %s (%d)" % [String(mg.get("marcador", "")), String(mg.get("rival", "")), int(mg.get("anio", 0))], COL_VERDE, _lista_records)
		if rec.has("peor_derrota"):
			var pd: Dictionary = rec["peor_derrota"]
			_dato("Peor derrota", "%s con %s (%d)" % [String(pd.get("marcador", "")), String(pd.get("rival", "")), int(pd.get("anio", 0))], COL_ROJO, _lista_records)
		if rec.has("mas_goles"):
			var mgo: Dictionary = rec["mas_goles"]
			_dato("Más goles en un partido", "%d vs %s (%d)" % [int(mgo.get("g", 0)), String(mgo.get("rival", "")), int(mgo.get("anio", 0))], COL_TEXTO, _lista_records)
		if rec.has("mas_publico"):
			var mp: Dictionary = rec["mas_publico"]
			_dato("Récord de público", "%s vs %s (%d)" % [_miles(int(mp.get("n", 0))), String(mp.get("rival", "")), int(mp.get("anio", 0))], COL_TEXTO, _lista_records)
		_lista_records.add_child(HSeparator.new())

	## `vMemoria()`: el salón de la fama. No es una lista guardada aparte -sería
	## otro sitio más que mantener al día-: sale de los goles, los partidos y los
	## títulos que ya se llevan anotados. Estar en el once de un título pesa
	## mucho, que es lo que separa a un buen jugador de uno que se recuerda.
	var fama := lg.salon_de_la_fama(12)
	if not fama.is_empty():
		var tf := _texto(11, COL_SUAVE)
		tf.text = "SALÓN DE LA FAMA DEL CLUB"
		_lista_records.add_child(tf)
		for i in fama.size():
			var f3: Dictionary = fama[i]
			var col_f := COL_ORO if int(f3["titulos"]) > 0 else COL_TEXTO
			_dato("%d.  %s%s" % [i + 1, "🏆 " if int(f3["titulos"]) > 0 else "", String(f3["nombre"])],
				String(f3["motivo"]), col_f, _lista_records)
		_lista_records.add_child(HSeparator.new())

	var goleadores := lg.goleadores_historicos(10)
	if not goleadores.is_empty():
		var tg := _texto(11, COL_SUAVE)
		tg.text = "GOLEADORES HISTÓRICOS DE TU ERA"
		_lista_records.add_child(tg)
		for i in goleadores.size():
			var f: Dictionary = goleadores[i]
			_dato("%d.  %s" % [i + 1, String(f["nombre"])], str(int(f["goles"])), COL_TEXTO, _lista_records)
		_lista_records.add_child(HSeparator.new())

	var mas_pj := lg.mas_partidos(10)
	if not mas_pj.is_empty():
		var tp := _texto(11, COL_SUAVE)
		tp.text = "MÁS PARTIDOS DISPUTADOS"
		_lista_records.add_child(tp)
		for i in mas_pj.size():
			var f2: Dictionary = mas_pj[i]
			_dato("%d.  %s" % [i + 1, String(f2["nombre"])], str(int(f2["partidos"])), COL_TEXTO, _lista_records)
		_lista_records.add_child(HSeparator.new())

	if not lg.h2h.is_empty():
		var th := _texto(11, COL_SUAVE)
		th.text = "CARA A CARA"
		_lista_records.add_child(th)
		var g2 := GridContainer.new()
		g2.columns = 5
		g2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g2.add_theme_constant_override("h_separation", 10)
		_lista_records.add_child(g2)
		for t2 in ["CLUB", "PJ", "G", "E", "P"]:
			_celda(g2, t2, COL_SUAVE, t2 != "CLUB", 11)
		var ids := lg.h2h.keys()
		ids.sort_custom(func(a: String, b: String) -> bool: return int(lg.h2h[a]["pj"]) > int(lg.h2h[b]["pj"]))
		for id: String in ids:
			var h: Dictionary = lg.h2h[id]
			var rival: Club = mundo.clubes.get(id)
			## Los clásicos se marcan: `es_clasico()` ya existía -se portó para
			## el desafío "derbis"- y no la miraba ninguna pantalla. Un cara a
			## cara sin saber cuál de esos rivales es EL rival es media tabla.
			var es_derbi := rival != null and mundo.es_clasico(mundo.mi_club(), rival)
			_celda(g2, ("🔥 %s" % rival.nombre) if es_derbi else (rival.nombre if rival != null else "?"),
				COL_ORO if es_derbi else COL_TEXTO)
			_celda(g2, str(int(h["pj"])), COL_TEXTO, true)
			_celda(g2, str(int(h["pg"])), COL_VERDE, true)
			_celda(g2, str(int(h["pe"])), COL_SUAVE, true)
			_celda(g2, str(int(h["pp"])), COL_ROJO, true)
		_lista_records.add_child(HSeparator.new())

	if not lg.efemerides.is_empty():
		var te := _texto(11, COL_SUAVE)
		te.text = "UN DÍA COMO HOY"
		_lista_records.add_child(te)
		var efes: Array = lg.efemerides
		for i in range(efes.size() - 1, maxi(-1, efes.size() - 11), -1):
			var e: Dictionary = efes[i]
			var le := _texto(11, COL_SUAVE)
			le.text = "S%d/%d  ·  %s" % [int(e.get("semana", 0)), int(e.get("anio", 0)), String(e.get("texto", ""))]
			le.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_lista_records.add_child(le)
		_lista_records.add_child(HSeparator.new())

	if not lg.planteles.is_empty():
		var tpl := _texto(11, COL_SUAVE)
		tpl.text = "ARCHIVO DE PLANTELES"
		_lista_records.add_child(tpl)
		if not _modo_experto:
			var epl := _texto(10, COL_SUAVE)
			epl.text = "Pulsa un año para abrir aquel plantel entero: quién estaba, con qué dorsal, cuánto jugó y cuánto marcó."
			epl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_lista_records.add_child(epl)
		var pls: Array = lg.planteles
		for i in range(pls.size() - 1, maxi(-1, pls.size() - 9), -1):
			var p: Dictionary = pls[i]
			var anio_p := int(p.get("anio", 0))
			var abierto := _plantel_abierto == anio_p
			var bp := Button.new()
			bp.text = "%s%d  ·  %dº  ·  MVP: %s" % ["▾ " if abierto else "▸ ", anio_p,
				int(p.get("puesto", 0)), String(p.get("mvp", "—"))]
			bp.flat = true
			bp.alignment = HORIZONTAL_ALIGNMENT_LEFT
			bp.add_theme_font_size_override("font_size", 12)
			bp.add_theme_color_override("font_color", _color_de_paleta(COL_ORO if abierto else COL_TEXTO))
			bp.pressed.connect(func() -> void:
				_plantel_abierto = 0 if _plantel_abierto == anio_p else anio_p
				_refrescar())
			_lista_records.add_child(bp)
			if not abierto:
				continue
			var rej := GridContainer.new()
			rej.columns = 6
			rej.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_lista_records.add_child(rej)
			for cab: String in ["#", "Pos", "Nombre", "Media", "PJ", "Goles"]:
				_celda(rej, cab, COL_SUAVE, cab != "Nombre" and cab != "Pos")
			for reg: Variant in (p.get("jugadores", []) as Array):
				## LOS ARCHIVOS VIEJOS guardaban una cadena "Fulano (78)" y no un
				## registro. Se siguen leyendo: una partida de hace veinte
				## temporadas no debería perder su memoria por un cambio de
				## formato.
				if reg is Dictionary:
					var d: Dictionary = reg
					_celda(rej, str(int(d.get("d", 0))) if int(d.get("d", 0)) > 0 else "·", COL_SUAVE, true)
					_celda(rej, String(d.get("pos", "")), COL_SUAVE, false)
					_celda(rej, String(d.get("n", "")), COL_TEXTO, false)
					_celda(rej, str(int(d.get("ovr", 0))), COL_TEXTO, true)
					_celda(rej, str(int(d.get("pj", 0))), COL_SUAVE, true)
					_celda(rej, str(int(d.get("g", 0))), COL_ORO if int(d.get("g", 0)) > 0 else COL_SUAVE, true)
				else:
					_celda(rej, "·", COL_SUAVE, true)
					_celda(rej, "", COL_SUAVE, false)
					_celda(rej, str(reg), COL_TEXTO, false)
					_celda(rej, "—", COL_SUAVE, true)
					_celda(rej, "—", COL_SUAVE, true)
					_celda(rej, "—", COL_SUAVE, true)


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

func _editor_de() -> Editor:
	if _editor == null or _editor._mundo() != mundo:
		_editor = Editor.new(mundo)
	return _editor

## `vCiudad()`: EL CLUB Y SU BARRIO.
##
## Es la parte del juego que ocurre fuera del campo y de la caja. Todo lo demás
## escala con ganar partidos; esto no: los negocios anexos ingresan TODAS las
## semanas del año, jueguen o no, y tienen un freno que no es dinero —el permiso
## municipal y la relación con los vecinos—, así que no basta con tener caja.
func _pintar_ciudad(c: Club) -> void:
	var ci := mundo.ciudad
	if ci == null:
		return
	_limpiar(_lista_ciudad)
	var t := _texto(11, COL_SUAVE)
	t.text = "🏙️ EL CLUB Y SU CIUDAD"
	_lista_ciudad.add_child(t)
	## EL VISOR 3D DE LA CIUDAD DEPORTIVA, por fin alcanzable desde el juego
	## (12-9-2026): `CityBuilder` llevaba desde el 2-09-2026 viviendo solo en
	## el proyecto viejo, nunca portado. Mismo patrón que el botón de estadio.
	var ver3d := Button.new()
	ver3d.text = "🏙️ Ver la ciudad en 3D"
	ver3d.add_theme_font_size_override("font_size", 11)
	ver3d.pressed.connect(_ver_ciudad_propia)
	_lista_ciudad.add_child(ver3d)
	_pintar_luces_ciudad(ci)

	var n_neg := 0
	for k: String in ci.negocios:
		if bool(ci.negocios[k]):
			n_neg += 1
	_dato("Negocios abiertos", "%d de %d" % [n_neg, Ciudad.lista_negocios().size()],
		COL_TEXTO, _lista_ciudad)
	_dato("Ingreso semanal", _dinero(ci.renta_negocios(c, mundo.prensa.animo if mundo.prensa else 60)),
		COL_VERDE, _lista_ciudad)
	_dato("Relación con los vecinos", "%d de 100" % ci.vecinos,
		COL_ROJO if ci.vecinos < 35 else (COL_VERDE if ci.vecinos > 70 else COL_ORO), _lista_ciudad)
	_dato("Estado del césped", "%d de 100" % ci.cesped,
		COL_ROJO if ci.cesped < Ciudad.CESPED_MINIMO_CONCIERTO else COL_VERDE, _lista_ciudad)
	if not ci.sancion.is_empty():
		var av := _texto(12, COL_ROJO)
		av.text = "🚫 Próximo partido a puertas cerradas." if String(ci.sancion["tipo"]) == "cerradas" \
			else "🚧 Aforo reducido al 40%% durante %d semana(s)." % int(ci.sancion["semanas"])
		av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_ciudad.add_child(av)
	if not ci.permiso.is_empty():
		_dato("Permiso en trámite", "resolución en %d semana(s)  ·  %d%% estimado" % [
			int(ci.permiso["semanas"]), int(round(float(ci.permiso["prob"]) * 100.0))],
			COL_ORO, _lista_ciudad)

	_pintar_terrenos(ci, c)
	_pintar_negocios(ci, c)
	_pintar_conciertos(ci, c)
	_pintar_municipalidad(ci, c)
	_pintar_sostenibilidad(ci, c)
	_pintar_seguridad(ci, c)

## EL ALUMBRADO PÚBLICO: de qué color se ve tu ciudad de noche. Es la única
## decisión de la pantalla que no cuesta dinero ni da ingresos, y aun así es de
## las que más cambian cómo se ve el juego -de noche las farolas son lo único
## que dibuja el trazado de la ciudad-. Siete tonos con nombre para el que solo
## quiere algo que quede bien, y un selector libre para el que quiere el suyo.
func _pintar_luces_ciudad(ci: Ciudad) -> void:
	var t := _texto(11, COL_SUAVE)
	t.text = "💡 ALUMBRADO PÚBLICO"
	_lista_ciudad.add_child(t)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 5)
	flow.add_theme_constant_override("v_separation", 5)
	_lista_ciudad.add_child(flow)
	for par: Array in Ciudad.paletas_luces():
		var hex := String(par[0])
		var b := Button.new()
		b.text = ("● " if ci.luces == hex else "") + String(par[1])
		b.add_theme_font_size_override("font_size", 11)
		b.add_theme_color_override("font_color", Color(hex))
		b.pressed.connect(func() -> void:
			ci.luces = hex
			_refrescar())
		flow.add_child(b)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	_lista_ciudad.add_child(fila)
	var et := _texto(11, COL_TEXTO)
	et.text = "O elige el tuyo"
	et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(et)
	var cp := ColorPickerButton.new()
	cp.color = Color(ci.luces)
	cp.custom_minimum_size = Vector2(84, 24)
	cp.edit_alpha = false
	cp.color_changed.connect(func(nuevo: Color) -> void:
		ci.luces = "#" + nuevo.to_html(false))
	fila.add_child(cp)

## Mismo motivo y mismo arreglo que `_ver_estadio_propio()`: `VistaCiudad`
## tampoco trae fondo opaco -para que el 3D se vea de verdad-, así que hay
## que esconder el resto de la pantalla mientras está abierta.
func _ver_ciudad_propia() -> void:
	var c := mundo.mi_club()
	if c == null or mundo.obras == null:
		return
	var ocultados: Array = []
	for h in get_children():
		if h is Control and (h as Control).visible:
			(h as Control).visible = false
			ocultados.append(h)
	var vista := VistaCiudad.new()
	add_child(vista)
	vista.construir = _empezar_obra
	var prox := mundo.proximo_partido()
	vista.dia_partido = not prox.is_empty() and prox[0] == c
	vista.abrir(c, mundo.obras, mundo.ciudad, mundo.perfil_estadio_de(c))
	vista.cerrado.connect(func() -> void:
		vista.queue_free()
		for h in ocultados:
			if is_instance_valid(h):
				(h as Control).visible = true
		_refrescar())
	## Clic en el estadio, o el botón "Editar mi estadio": mismo cierre que
	## "Volver" -devuelve la pestaña de Club, que quedaba oculta- y además
	## salta directo a Estadio con el diseñador ya pintado, en vez de dejar al
	## jugador en la pestaña en la que estaba antes de entrar a la ciudad.
	vista.editar_estadio_pedido.connect(func() -> void:
		vista.queue_free()
		for h in ocultados:
			if is_instance_valid(h):
				(h as Control).visible = true
		_ir_a_pestana("Estadio")
		_pintar_estadio(c))

func _pintar_terrenos(ci: Ciudad, c: Club) -> void:
	_lista_ciudad.add_child(HSeparator.new())
	var t := _texto(11, COL_ACENTO)
	t.text = "🗺️ TERRENOS"
	_lista_ciudad.add_child(t)
	for f: Array in Ciudad.lista_terrenos():
		var clave := String(f[0])
		var mio := ci.tiene_terreno(clave)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_lista_ciudad.add_child(fila)
		var n := _texto(12, COL_VERDE if mio else COL_TEXTO)
		n.text = "%s%s" % ["✔  " if mio else "     ", String(f[1])]
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		n.tooltip_text = String(f[3])
		fila.add_child(n)
		var b := Button.new()
		var precio := ci.precio_terreno(clave, c)
		b.text = "Tuyo" if mio else _dinero(precio)
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = mio or c.saldo < precio
		b.custom_minimum_size = Vector2(110, 0)
		b.pressed.connect(func() -> void:
			var p := ci.comprar_terreno(clave, mundo.mi_club())
			if p != "":
				_escribir("[color=#e05555]No se pudo: %s.[/color]" % p)
			_refrescar())
		fila.add_child(b)
		if not _modo_experto and not mio:
			var d := _texto(10, COL_SUAVE)
			d.text = "     %s" % String(f[3])
			d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_lista_ciudad.add_child(d)

func _pintar_negocios(ci: Ciudad, c: Club) -> void:
	_lista_ciudad.add_child(HSeparator.new())
	var t := _texto(11, COL_ACENTO)
	t.text = "🏗️ NEGOCIOS ANEXOS"
	_lista_ciudad.add_child(t)
	if not _modo_experto:
		var ex := _texto(10, COL_SUAVE)
		ex.text = "Ingresan todas las semanas del año, jueguen o no. Es lo que separa a un club que sobrevive de uno que crece."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_ciudad.add_child(ex)
	for f: Array in Ciudad.lista_negocios():
		var clave := String(f[0])
		var hecho := ci.tiene_negocio(clave)
		var terr: Variant = f[3]
		var falta := terr != null and String(terr) != "" and not ci.tiene_terreno(String(terr))
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_lista_ciudad.add_child(fila)
		var n := _texto(12, COL_VERDE if hecho else (COL_SUAVE if falta else COL_TEXTO))
		n.text = "%s%s" % ["✔  " if hecho else "     ", String(f[1])]
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		n.tooltip_text = String(f[4])
		fila.add_child(n)
		var r := _texto(11, COL_ORO)
		r.text = "+%s/sem" % _dinero(Eco.escalar(Ciudad.RENTA_NEGOCIO_BASE * float(f[5]), float(c.rep)))
		r.custom_minimum_size = Vector2(96, 0)
		fila.add_child(r)
		var b := Button.new()
		var coste := Eco.escalar(float(f[2]), float(c.rep))
		b.text = "Operando" if hecho else _dinero(coste)
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = hecho or falta or c.saldo < coste
		b.custom_minimum_size = Vector2(110, 0)
		b.pressed.connect(func() -> void:
			var p := ci.construir_negocio(clave, mundo.mi_club())
			if p != "":
				_escribir("[color=#e05555]No se puede: %s.[/color]" % p)
			_refrescar())
		fila.add_child(b)
		if falta:
			var dt := Ciudad.def_terreno(String(terr))
			var av := _texto(10, COL_ORO)
			av.text = "     Requiere antes: %s" % (String(dt[1]) if not dt.is_empty() else String(terr))
			_lista_ciudad.add_child(av)

## LOS CONCIERTOS. La decisión más honesta de la pantalla: dinero hoy contra
## rendimiento el domingo.
func _pintar_conciertos(ci: Ciudad, c: Club) -> void:
	_lista_ciudad.add_child(HSeparator.new())
	var t := _texto(11, COL_ACENTO)
	t.text = "🎤 EVENTOS NO DEPORTIVOS"
	_lista_ciudad.add_child(t)
	_dato("Conciertos realizados", str(ci.conciertos), COL_TEXTO, _lista_ciudad)
	var bruto := int(round(float(c.estadio_aforo) * Finanzas.ingreso_por_espectador(9.0) * 1.8))
	if not _modo_experto:
		var ex := _texto(10, COL_SUAVE)
		ex.text = "Un concierto llena la caja de golpe (%s) pero destroza el campo y molesta al barrio. Con el césped por debajo de %d, tus jugadores pierden precisión." % [
			_dinero(bruto), Ciudad.CESPED_MINIMO_CONCIERTO]
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_ciudad.add_child(ex)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	_lista_ciudad.add_child(fila)
	var b := Button.new()
	b.text = "🎤 Arrendar para un concierto"
	b.add_theme_font_size_override("font_size", 11)
	b.clip_text = true
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.disabled = ci.cesped < Ciudad.CESPED_MINIMO_CONCIERTO
	b.pressed.connect(func() -> void:
		var p := ci.arrendar_estadio(mundo.mi_club())
		if p != "":
			_escribir("[color=#e05555]No se puede: %s.[/color]" % p)
		_refrescar())
	fila.add_child(b)
	var br := Button.new()
	br.text = "🌱 Resembrar  ·  %s" % _dinero(ci.coste_resiembra(c))
	br.add_theme_font_size_override("font_size", 11)
	br.clip_text = true
	br.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	br.disabled = ci.cesped >= 100
	br.pressed.connect(func() -> void:
		var p := ci.reparar_cesped(mundo.mi_club())
		if p != "":
			_escribir("[color=#e05555]No se puede: %s.[/color]" % p)
		_refrescar())
	fila.add_child(br)

func _pintar_municipalidad(ci: Ciudad, c: Club) -> void:
	_lista_ciudad.add_child(HSeparator.new())
	var t := _texto(11, COL_ACENTO)
	t.text = "🏛️ MUNICIPALIDAD Y VECINOS"
	_lista_ciudad.add_child(t)
	var lectura := _texto(11, COL_SUAVE)
	if ci.vecinos < 35:
		lectura.text = "El barrio está en pie de guerra: cualquier permiso te lo van a tumbar."
	elif ci.vecinos > 70:
		lectura.text = "El barrio te quiere: los permisos salen casi solos."
	else:
		lectura.text = "Relación tibia con el vecindario."
	lectura.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_ciudad.add_child(lectura)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 4)
	_lista_ciudad.add_child(fila)
	for op: Array in [
			["obra", "🏗️ Obra social  ·  %s" % _dinero(Eco.escalar(Ciudad.COSTE_OBRA_SOCIAL, float(c.rep)))],
			["reunion", "🗣️ Reunión vecinal"],
			["entradas", "🎟️ Entradas para el barrio"]]:
		var que := String(op[0])
		var b := Button.new()
		b.text = String(op[1])
		b.add_theme_font_size_override("font_size", 10)
		b.clip_text = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			var p := ci.gestion_vecinal(que, mundo.mi_club())
			if p != "":
				_escribir("[color=#e05555]No se pudo: %s.[/color]" % p)
			_refrescar())
		fila.add_child(b)
	if not _modo_experto:
		var eg := _texto(10, COL_SUAVE)
		eg.text = "Una gestión al mes. La reunión es gratis y puede salir mal: es la única de las tres que se puede volver en contra."
		eg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_ciudad.add_child(eg)

	var tp := _texto(10, COL_SUAVE)
	tp.text = "Ampliación del estadio"
	_lista_ciudad.add_child(tp)
	if ci.permiso_ok:
		_dato("Permiso municipal", "vigente ✔", COL_VERDE, _lista_ciudad)
	else:
		var ex := _texto(10, COL_SUAVE)
		ex.text = "Para pasar del nivel 5 de tribunas hace falta permiso municipal. Hoy no lo tienes."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_ciudad.add_child(ex)
		var b := Button.new()
		b.text = "🏛️ Solicitar permiso  ·  %s" % _dinero(Eco.escalar(Ciudad.COSTE_PERMISO, float(c.rep)))
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = not ci.permiso.is_empty()
		b.pressed.connect(func() -> void:
			var p := ci.pedir_permiso(mundo.mi_club())
			if p != "":
				_escribir("[color=#e05555]No se pudo: %s.[/color]" % p)
			_refrescar())
		_lista_ciudad.add_child(b)
	_dato("Subvención estimada al cierre", _dinero(ci.subvencion_anual(c)), COL_VERDE, _lista_ciudad)

func _pintar_sostenibilidad(ci: Ciudad, c: Club) -> void:
	_lista_ciudad.add_child(HSeparator.new())
	var t := _texto(11, COL_ACENTO)
	t.text = "🌿 SOSTENIBILIDAD"
	_lista_ciudad.add_child(t)
	_dato("Cubierta solar", "%s%s" % ["●".repeat(ci.paneles), "○".repeat(Ciudad.PANELES_MAX - ci.paneles)],
		COL_VERDE if ci.paneles > 0 else COL_SUAVE, _lista_ciudad)
	if ci.paneles > 0:
		_dato("Ahorro energético", "%s/semana" % _dinero(ci.ahorro_energetico(c)), COL_VERDE, _lista_ciudad)
	_dato("Certificación ecológica", "certificado ✔" if ci.certificado else "sin certificar",
		COL_VERDE if ci.certificado else COL_SUAVE, _lista_ciudad)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	_lista_ciudad.add_child(fila)
	var bp := Button.new()
	bp.text = "☀️ Paneles solares" if ci.paneles >= Ciudad.PANELES_MAX else \
		"☀️ Paneles  ·  %s" % _dinero(Eco.escalar(Ciudad.COSTE_PANELES, float(c.rep)) * (ci.paneles + 1))
	bp.add_theme_font_size_override("font_size", 11)
	bp.clip_text = true
	bp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bp.disabled = ci.paneles >= Ciudad.PANELES_MAX
	bp.pressed.connect(func() -> void:
		var p := ci.instalar_paneles(mundo.mi_club())
		if p != "":
			_escribir("[color=#e05555]No se puede: %s.[/color]" % p)
		_refrescar())
	fila.add_child(bp)
	var bc := Button.new()
	bc.text = "🌿 Certificar  ·  %s" % _dinero(Eco.escalar(Ciudad.COSTE_CERTIFICACION, float(c.rep)))
	bc.add_theme_font_size_override("font_size", 11)
	bc.clip_text = true
	bc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bc.disabled = ci.certificado or ci.paneles < 2
	bc.pressed.connect(func() -> void:
		var p := ci.certificar(mundo.mi_club())
		if p != "":
			_escribir("[color=#e05555]No se puede: %s.[/color]" % p)
		_refrescar())
	fila.add_child(bc)

func _pintar_seguridad(ci: Ciudad, c: Club) -> void:
	_lista_ciudad.add_child(HSeparator.new())
	var t := _texto(11, COL_ACENTO)
	t.text = "🛡️ SEGURIDAD DEL ESTADIO"
	_lista_ciudad.add_child(t)
	for op: Array in [["privada", "Seguridad privada", ci.seg_privada],
			["camaras", "Cámaras y protocolo", ci.seg_camaras]]:
		var que := String(op[0])
		var niv: int = op[2]
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_lista_ciudad.add_child(fila)
		var n := _texto(12, COL_TEXTO)
		n.text = "%s  %s%s" % [String(op[1]), "●".repeat(niv), "○".repeat(Ciudad.SEGURIDAD_MAX - niv)]
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		fila.add_child(n)
		var b := Button.new()
		var coste := Eco.escalar(200000.0 if que == "privada" else 260000.0, float(c.rep)) * (niv + 1)
		b.text = "MÁX" if niv >= Ciudad.SEGURIDAD_MAX else _dinero(coste)
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = niv >= Ciudad.SEGURIDAD_MAX or c.saldo < coste
		b.custom_minimum_size = Vector2(110, 0)
		b.pressed.connect(func() -> void:
			var p := ci.mejorar_seguridad(que, mundo.mi_club())
			if p != "":
				_escribir("[color=#e05555]No se puede: %s.[/color]" % p)
			_refrescar())
		fila.add_child(b)
	var riesgo := ci.riesgo_incidente(
		mundo.prensa.animo if mundo.prensa else 60,
		mundo.prensa.funa if mundo.prensa else 0)
	_dato("Riesgo de incidente por partido en casa", "%d%%" % int(round(riesgo * 100.0)),
		COL_ROJO if riesgo > 0.08 else COL_SUAVE, _lista_ciudad)
	if not _modo_experto:
		var ex := _texto(10, COL_SUAVE)
		ex.text = "Un incidente grave cuesta puertas cerradas o aforo reducido, y eso es taquilla que no vuelve. Sube con el mal ambiente y la funa."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_ciudad.add_child(ex)

func _pintar_editor() -> void:
	_limpiar(_lista_editor)
	var ed := _editor_de()
	var t := _texto(11, COL_SUAVE)
	t.text = "🛠️ EDITOR"
	_lista_editor.add_child(t)
	if not _modo_experto:
		var ex := _texto(10, COL_SUAVE)
		ex.text = "Renombra, repinta y reconstruye el mundo del juego: clubes, escudos, plantillas, atributos, puestos y caras. Los cambios van al guardado como cualquier otra cosa."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_editor.add_child(ex)

	_pintar_editor_clubes(ed)
	_pintar_editor_jugadores(ed)
	_pintar_editor_csv(ed)

func _pintar_editor_clubes(ed: Editor) -> void:
	_lista_editor.add_child(HSeparator.new())
	var t := _texto(11, COL_ACENTO)
	t.text = "CLUBES"
	_lista_editor.add_child(t)
	var busca := LineEdit.new()
	busca.text = _ed_filtro
	busca.placeholder_text = "Buscar en todo el mundo… (vacío: los de tu país)"
	busca.add_theme_font_size_override("font_size", 12)
	busca.text_submitted.connect(func(x: String) -> void:
		_ed_filtro = x.strip_edges()
		_refrescar())
	_lista_editor.add_child(busca)

	var mio := mundo.mi_club()
	var lista: Array[Club] = []
	for c: Club in mundo.clubes.values():
		if _ed_filtro == "":
			if mio != null and c.pais == mio.pais:
				lista.append(c)
		elif Nombres.limpiar(c.nombre).to_lower().contains(_ed_filtro.to_lower()):
			lista.append(c)
	lista.sort_custom(func(a: Club, b: Club) -> bool: return a.rep > b.rep)

	for i in mini(30, lista.size()):
		var c2: Club = lista[i]
		var abierto := _ed_club == c2.id
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_lista_editor.add_child(fila)
		var esc := TextureRect.new()
		esc.texture = Escudo.textura(c2, 20)
		esc.custom_minimum_size = Vector2(20, 20)
		esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fila.add_child(esc)
		var b := Button.new()
		b.text = "%s%s  ·  %s D%d  ·  rep %d" % ["▾ " if abierto else "▸ ",
			c2.nombre, c2.pais, c2.division, c2.rep]
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 12)
		b.add_theme_color_override("font_color", _color_de_paleta(COL_ORO if abierto else COL_TEXTO))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		b.pressed.connect(func() -> void:
			_ed_club = "" if abierto else c2.id
			_ed_confirmar_regen = ""
			_refrescar())
		fila.add_child(b)
		if not abierto:
			continue

		var campo := LineEdit.new()
		campo.text = c2.nombre
		campo.add_theme_font_size_override("font_size", 12)
		campo.text_submitted.connect(func(x: String) -> void:
			var p := ed.renombrar_club(c2, x)
			if p != "":
				_escribir("[color=#e05555]%s.[/color]" % p)
			_refrescar())
		_lista_editor.add_child(campo)
		for par: Array in [["Color 1", "color1"], ["Color 2", "color2"]]:
			var prop := String(par[1])
			var f2 := HBoxContainer.new()
			f2.add_theme_constant_override("separation", 6)
			_lista_editor.add_child(f2)
			var e2 := _texto(11, COL_TEXTO)
			e2.text = String(par[0])
			e2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			f2.add_child(e2)
			var cp := ColorPickerButton.new()
			cp.color = Color(String(c2.get(prop)))
			cp.custom_minimum_size = Vector2(84, 24)
			cp.edit_alpha = false
			cp.color_changed.connect(func(nuevo: Color) -> void:
				c2.set(prop, "#" + nuevo.to_html(false))
				Escudo.limpiar_cache()
				_refrescar())
			f2.add_child(cp)
		_fila_mas_menos("Reputación", str(c2.rep),
			func(d: int) -> void: ed.mover_reputacion(c2, d * 2), _lista_editor)
		_fila_mas_menos("Aforo", _miles(c2.estadio_aforo),
			func(d: int) -> void: ed.mover_aforo(c2, d * 5000), _lista_editor)
		var br := Button.new()
		var pidiendo := _ed_confirmar_regen == c2.id
		br.text = "¿SEGURO? Se pierde la plantilla entera" if pidiendo else "🎲 Regenerar plantel"
		br.add_theme_font_size_override("font_size", 11)
		br.add_theme_color_override("font_color", _color_de_paleta(COL_ROJO if pidiendo else COL_TEXTO))
		br.pressed.connect(func() -> void:
			if not pidiendo:
				_ed_confirmar_regen = c2.id
				_refrescar()
				return
			_ed_confirmar_regen = ""
			var p := ed.regenerar_plantel(c2)
			if p != "":
				_escribir("[color=#e05555]No se puede: %s.[/color]" % p)
			else:
				_escribir("[color=#c9a227]Plantel de %s regenerado.[/color]" % c2.nombre)
			_refrescar())
		_lista_editor.add_child(br)

func _pintar_editor_jugadores(ed: Editor) -> void:
	var c := mundo.mi_club()
	if c == null:
		return
	_lista_editor.add_child(HSeparator.new())
	var t := _texto(11, COL_ACENTO)
	t.text = "JUGADORES DE TU PLANTEL"
	_lista_editor.add_child(t)
	for j: Jugador in c.plantilla:
		var quien := j
		var abierto := _ed_jugador == j.id
		var b := Button.new()
		b.text = "%s%s  ·  %s  ·  %d años  ·  media %d" % ["▾ " if abierto else "▸ ",
			j.nombre, j.pos_e, j.edad, j.ovr]
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 12)
		b.add_theme_color_override("font_color", _color_de_paleta(COL_ORO if abierto else COL_TEXTO))
		b.clip_text = true
		b.pressed.connect(func() -> void:
			_ed_jugador = "" if abierto else quien.id
			_refrescar())
		_lista_editor.add_child(b)
		if abierto:
			_pintar_editor_ficha(ed, quien, c)

func _pintar_editor_ficha(ed: Editor, j: Jugador, c: Club) -> void:
	var cara := TextureRect.new()
	cara.texture = Cara.textura(j, c.color_kit1(), c.color_kit2(), 56)
	cara.custom_minimum_size = Vector2(56, 56)
	cara.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cara.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_lista_editor.add_child(cara)

	var campo := LineEdit.new()
	campo.text = j.nombre
	campo.add_theme_font_size_override("font_size", 12)
	campo.text_submitted.connect(func(x: String) -> void:
		var p := ed.fijar_campo(j, "nombre", x)
		if p != "":
			_escribir("[color=#e05555]%s.[/color]" % p)
		_refrescar())
	_lista_editor.add_child(campo)

	_fila_mas_menos("Media", str(j.ovr),
		func(d: int) -> void: ed.fijar_campo(j, "ovr", j.ovr + d), _lista_editor)
	_fila_mas_menos("Proyección", str(j.pot),
		func(d: int) -> void: ed.fijar_campo(j, "pot", j.pot + d), _lista_editor)
	_fila_mas_menos("Edad", str(j.edad),
		func(d: int) -> void: ed.fijar_campo(j, "edad", j.edad + d), _lista_editor)
	_fila_mas_menos("Dorsal", str(j.dorsal),
		func(d: int) -> void: ed.fijar_campo(j, "dorsal", j.dorsal + d), _lista_editor)

	_rejilla_editor("Puesto", Editor.demarcaciones(), j.pos_e,
		func(v: String) -> void: ed.fijar_campo(j, "pos_e", v))
	_rejilla_editor("Rasgo", [""] + _rasgos_disponibles(), j.rasgo,
		func(v: String) -> void: ed.fijar_campo(j, "rasgo", v))
	var bandera: Dictionary = Datos.tabla("BANDERA")
	_rejilla_editor("País", bandera.keys(), j.pais,
		func(v: String) -> void: ed.fijar_campo(j, "pais", v))

	var ta := _texto(10, COL_SUAVE)
	ta.text = "Atributos  ·  la media se recalcula sola"
	_lista_editor.add_child(ta)
	for k: String in j.atributos:
		var clave := k
		_fila_mas_menos(clave, str(int(j.atributos[k])),
			func(d: int) -> void: ed.mover_atributo(j, clave, d * 3), _lista_editor)

	## LA CARA. Los quince rasgos salen de un hash del id; aquí se pisan los que
	## se toquen, y solo esos. Es lo que permite arreglar una cara sin tener que
	## redefinirla entera.
	var tl := _texto(10, COL_SUAVE)
	tl.text = "Aspecto"
	_lista_editor.add_child(tl)
	var look := Cara.look_de(j)
	_rejilla_colores_editor(ed, j, "piel", Cara.PIELES, String(look["piel"]))
	_rejilla_colores_editor(ed, j, "peloC", Cara.PELOS, String(look["peloC"]))
	_rejilla_editor("Corte", Cara.CORTES, String(look["pelo"]),
		func(v: String) -> void: ed.fijar_look(j, "pelo", v))
	_rejilla_editor("Accesorio", Cara.ACCESORIOS, String(look["acc"]),
		func(v: String) -> void: ed.fijar_look(j, "acc", v))
	var fila_b := HBoxContainer.new()
	fila_b.add_theme_constant_override("separation", 4)
	_lista_editor.add_child(fila_b)
	for par: Array in [["barba", "Barba", 8], ["nariz", "Nariz", 4], ["boca", "Boca", 3],
			["ojos", "Ojos", 4], ["cara", "Cara", 4], ["menton", "Mandíbula", 3]]:
		var clave2 := String(par[0])
		var tope: int = par[2]
		var bb := Button.new()
		bb.text = "%s ▸" % String(par[1])
		bb.add_theme_font_size_override("font_size", 10)
		bb.custom_minimum_size = Vector2(66, 22)
		bb.pressed.connect(func() -> void:
			ed.fijar_look(j, clave2, (int(Cara.look_de(j).get(clave2, 0)) + 1) % tope))
		fila_b.add_child(bb)
	var fila_s := HBoxContainer.new()
	fila_s.add_theme_constant_override("separation", 4)
	_lista_editor.add_child(fila_s)
	for par2: Array in [["pecas", "Pecas"], ["lunar", "Lunar"], ["cicatriz", "Cicatriz"]]:
		var clave3 := String(par2[0])
		var bs := Button.new()
		bs.text = String(par2[1])
		bs.add_theme_font_size_override("font_size", 10)
		bs.toggle_mode = true
		bs.button_pressed = bool(look.get(clave3, false))
		bs.custom_minimum_size = Vector2(66, 22)
		bs.pressed.connect(func() -> void:
			ed.fijar_look(j, clave3, not bool(Cara.look_de(j).get(clave3, false))))
		fila_s.add_child(bs)

	var b_azar := Button.new()
	b_azar.text = "🎲 Aleatorio"
	b_azar.add_theme_font_size_override("font_size", 11)
	b_azar.tooltip_text = "Un aspecto entero nuevo de una sola vez, no rasgo a rasgo."
	b_azar.pressed.connect(func() -> void:
		ed.aleatorizar_look(j)
		_refrescar())
	_lista_editor.add_child(b_azar)

func _rasgos_disponibles() -> Array:
	var t: Variant = Datos.tabla("RASGOS")
	if t is Dictionary:
		return (t as Dictionary).keys()
	return []

## Una fila "etiqueta  −  valor  +". Es el patrón de todo el editor: no se
## escriben números a mano porque un campo de texto que hay que validar en cada
## pulsación es más frágil que dos botones.
func _fila_mas_menos(etiqueta: String, valor: String, accion: Callable, padre: Node) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	padre.add_child(fila)
	var et := _texto(11, COL_TEXTO)
	et.text = etiqueta
	et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et.clip_text = true
	fila.add_child(et)
	var bm := Button.new()
	bm.text = "−"
	bm.add_theme_font_size_override("font_size", 12)
	bm.custom_minimum_size = Vector2(30, 22)
	bm.pressed.connect(func() -> void:
		accion.call(-1)
		_refrescar())
	fila.add_child(bm)
	var v := _texto(12, COL_ORO)
	v.text = valor
	v.custom_minimum_size = Vector2(58, 0)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fila.add_child(v)
	var bp := Button.new()
	bp.text = "+"
	bp.add_theme_font_size_override("font_size", 12)
	bp.custom_minimum_size = Vector2(30, 22)
	bp.pressed.connect(func() -> void:
		accion.call(1)
		_refrescar())
	fila.add_child(bp)

func _rejilla_editor(titulo: String, opciones: Array, actual: String, accion: Callable) -> void:
	var lt := _texto(10, COL_SUAVE)
	lt.text = titulo
	_lista_editor.add_child(lt)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 4)
	_lista_editor.add_child(flow)
	var vistas := {}
	for op: Variant in opciones:
		var clave := String(op)
		if vistas.has(clave):
			continue
		vistas[clave] = true
		var b := Button.new()
		b.text = clave if clave != "" else "—"
		b.add_theme_font_size_override("font_size", 10)
		b.toggle_mode = true
		b.button_pressed = actual == clave
		b.clip_text = true
		b.custom_minimum_size = Vector2(58, 22)
		b.pressed.connect(func() -> void:
			accion.call(clave)
			_refrescar())
		flow.add_child(b)

func _rejilla_colores_editor(ed: Editor, j: Jugador, clave: String, colores: Array, actual: String) -> void:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 3)
	_lista_editor.add_child(flow)
	for col: Variant in colores:
		var hex := String(col)
		var b := Button.new()
		b.custom_minimum_size = Vector2(24, 22)
		b.text = "✔" if actual == hex else " "
		b.add_theme_font_size_override("font_size", 10)
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color(hex)
		estilo.corner_radius_top_left = 3
		estilo.corner_radius_top_right = 3
		estilo.corner_radius_bottom_left = 3
		estilo.corner_radius_bottom_right = 3
		b.add_theme_stylebox_override("normal", estilo)
		b.add_theme_stylebox_override("hover", estilo)
		b.add_theme_stylebox_override("pressed", estilo)
		b.pressed.connect(func() -> void:
			ed.fijar_look(j, clave, hex)
			_refrescar())
		flow.add_child(b)

## EL IMPORTADOR. Formato del HTML sin tocar, para que una base hecha para el
## HTML se pueda pegar aquí tal cual.
func _pintar_editor_csv(ed: Editor) -> void:
	_lista_editor.add_child(HSeparator.new())
	var t := _texto(11, COL_ACENTO)
	t.text = "IMPORTAR UNA BASE (CSV)"
	_lista_editor.add_child(t)
	var ex := _texto(10, COL_SUAVE)
	ex.text = "Una línea por futbolista: Club;Nombre;POS;Edad;Media[;País;Proyección;Pie]. POS admite grupos (POR/DEF/MED/DEL) o puestos concretos. Con %d filas o más de un mismo club, se REEMPLAZA su plantilla; con menos, se añaden." % Editor.FILAS_PARA_REEMPLAZAR
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_editor.add_child(ex)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	_lista_editor.add_child(fila)
	var etc := _texto(11, COL_TEXTO)
	etc.text = "Censurar los nombres importados"
	etc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etc.tooltip_text = "Sustituye algunas letras por números, como hace el resto del juego con los nombres generados."
	fila.add_child(etc)
	var bc := Button.new()
	bc.text = "SÍ" if _ed_censura else "NO"
	bc.pressed.connect(func() -> void:
		_ed_censura = not _ed_censura
		_refrescar())
	fila.add_child(bc)

	var caja := TextEdit.new()
	caja.text = _ed_csv
	caja.placeholder_text = "C0lo-C0lo;Arturo Vidal;MED;38;79\nB0ca Juni0rs;Edinson Cavani;DEL;39;80;URU;80"
	caja.custom_minimum_size = Vector2(0, 120)
	caja.add_theme_font_size_override("font_size", 11)
	caja.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	caja.text_changed.connect(func() -> void: _ed_csv = caja.text)
	_lista_editor.add_child(caja)

	var bi := Button.new()
	bi.text = "📥 Importar"
	bi.add_theme_font_size_override("font_size", 11)
	bi.pressed.connect(func() -> void: _importar_csv(ed))
	_lista_editor.add_child(bi)
	var bp := Button.new()
	bp.text = "📋 Pegar desde el portapapeles"
	bp.add_theme_font_size_override("font_size", 11)
	bp.pressed.connect(func() -> void:
		_ed_csv = DisplayServer.clipboard_get()
		_refrescar())
	_lista_editor.add_child(bp)

	_lista_editor.add_child(HSeparator.new())
	var te := _texto(11, COL_ACENTO)
	te.text = "EXPORTAR LA BASE (CSV)"
	_lista_editor.add_child(te)
	var ee := _texto(10, COL_SUAVE)
	ee.text = "Mismo formato que el importador, con el pie hábil de regalo -no se puede reimportar, es calculado, no guardado- y sin habilidades -esas viven en el árbol de entrenamiento de cada club, no en el jugador-. Se copia al portapapeles."
	ee.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_editor.add_child(ee)
	var fila_ex := HBoxContainer.new()
	fila_ex.add_theme_constant_override("separation", 8)
	_lista_editor.add_child(fila_ex)
	var b_mi := Button.new()
	b_mi.text = "Mi liga"
	b_mi.add_theme_font_size_override("font_size", 11)
	b_mi.pressed.connect(func() -> void: _exportar_csv(ed, true))
	fila_ex.add_child(b_mi)
	var b_todo := Button.new()
	b_todo.text = "Todo el mundo"
	b_todo.add_theme_font_size_override("font_size", 11)
	b_todo.pressed.connect(func() -> void: _exportar_csv(ed, false))
	fila_ex.add_child(b_todo)

## `solo_mi_liga`, no `todo` -a un botón "Todo el mundo" nombrar el parámetro
## al revés de lo que dice fue justo el bug que cazó la captura de pruebas:
## el nombre invertido hacía fácil pasar el booleano equivocado sin que nada
## avisara.
func _exportar_csv(ed: Editor, solo_mi_liga: bool) -> void:
	var texto := ed.exportar_csv(solo_mi_liga)
	if texto == "":
		_escribir("[color=#c9a227]No hay nada que exportar.[/color]")
		return
	DisplayServer.clipboard_set(texto)
	_escribir("[color=#4caf6d]Base exportada.[/color] Copiada al portapapeles (%d líneas)." % (texto.count("\n") + 1))

func _importar_csv(ed: Editor) -> void:
	if _ed_csv.strip_edges() == "":
		_escribir("[color=#c9a227]No hay nada que importar.[/color]")
		return
	var r := ed.importar_csv(_ed_csv, _ed_censura)
	if r.has("error"):
		_escribir("[color=#e05555]No se pudo importar: %s.[/color]" % String(r["error"]))
		_refrescar()
		return
	_escribir("[color=#4caf6d]Importadas %d fichas en %d club(es).[/color]" % [
		int(r["filas"]), int(r["clubes"])])
	for p: String in (r["problemas"] as Array):
		_escribir("[color=#e0a832]  %s[/color]" % p)
	_refrescar()

func _pintar_glosario() -> void:
	_limpiar(_lista_glosario)
	var gl: Array = Datos.tabla("GLOSARIO")
	if gl == null:
		return
	for par in gl:
		var termino := _texto(13, COL_TEXTO)
		termino.text = String(par[0])
		_lista_glosario.add_child(termino)
		var definicion := _texto(11, COL_SUAVE)
		definicion.text = String(par[1])
		definicion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_glosario.add_child(definicion)
		_lista_glosario.add_child(HSeparator.new())

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

## LA MÚSICA. Seis piezas sintetizadas, como todo el audio del juego: ni un solo
## fichero, ni una licencia de terceros que arrastrar en el paquete.
##
## Va aparte del mezclador de efectos a propósito. La música se apaga entera
## mucho más a menudo que los efectos —hay gente que juega a esto con un podcast
## de fondo—, y tenerla en el mismo grupo obligaba a bajar el silbato para no oír
## el arpegio.
## RECORRE LA PANTALLA Y TRADUCE. Ver la explicación larga en `nucleo/idiomas.gd`.
##
## Solo toca `Label`, `Button` y `OptionButton`, que es donde vive el esqueleto
## de la interfaz. NO toca `RichTextLabel` -ahí va la narración, que sigue en
## castellano- ni `LineEdit` -ahí escribe el usuario-.
##
## Guarda en metadatos del propio nodo el texto castellano original (`_i18n_src`)
## y lo último que ESTA función escribió (`_i18n_out`): si el texto actual
## coincide con lo último que ella misma puso, nadie lo tocó desde entonces y
## usa el castellano guardado como fuente; si NO coincide, es que un repintado
## puso texto castellano fresco (nombre de jugador, cifra...) y lo adopta como
## la nueva fuente. SIN esto, un nodo que se construye UNA sola vez y nunca se
## repinta -"Guardar"/"Cargar"/"Otro mundo" de la fila de acciones, tooltips-
## se quedaba pegado en el último idioma elegido para siempre, sin volver al
## castellano al cambiar de vuelta: bug real, sospechado el 10-9-2026 en una
## captura ("Save"/"Load"/"New world" seguían en inglés tras forzar `idioma="es"`)
## y confirmado y corregido aquí el 12-9-2026.
func _traducir_pantalla(n: Node) -> void:
	if n == self:
		if Idiomas.idioma == "es" and not _traduccion_activa:
			return
		if Idiomas.idioma != "es":
			_traduccion_activa = true
	if n is Label:
		var l := n as Label
		var actual := l.text
		var fue_mio: bool = l.has_meta("_i18n_out") and String(l.get_meta("_i18n_out")) == actual
		var base: String = String(l.get_meta("_i18n_src")) if fue_mio else actual
		var nuevo := base if Idiomas.idioma == "es" else Idiomas.t(base)
		l.set_meta("_i18n_src", base)
		l.set_meta("_i18n_out", nuevo)
		l.text = nuevo
	elif n is OptionButton:
		## El desplegable, por dentro: cada entrada por separado. El texto del
		## botón lo pinta Godot con la entrada elegida, así que no hay que tocarlo.
		var ob := n as OptionButton
		var outs: Array = ob.get_meta("_i18n_out") if ob.has_meta("_i18n_out") else []
		var srcs: Array = ob.get_meta("_i18n_src") if ob.has_meta("_i18n_src") else []
		var nuevos_src: Array = []
		var nuevos_out: Array = []
		for i in ob.item_count:
			var actual_i := ob.get_item_text(i)
			var fue_mio_i: bool = i < outs.size() and String(outs[i]) == actual_i
			var base_i: String = String(srcs[i]) if (fue_mio_i and i < srcs.size()) else actual_i
			var nuevo_i := base_i if Idiomas.idioma == "es" else Idiomas.t(base_i)
			ob.set_item_text(i, nuevo_i)
			nuevos_src.append(base_i)
			nuevos_out.append(nuevo_i)
		ob.set_meta("_i18n_src", nuevos_src)
		ob.set_meta("_i18n_out", nuevos_out)
	elif n is Button:
		var b := n as Button
		var actual2 := b.text
		var fue_mio2: bool = b.has_meta("_i18n_out") and String(b.get_meta("_i18n_out")) == actual2
		var base2: String = String(b.get_meta("_i18n_src")) if fue_mio2 else actual2
		var nuevo2 := base2 if Idiomas.idioma == "es" else Idiomas.t(base2)
		b.set_meta("_i18n_src", base2)
		b.set_meta("_i18n_out", nuevo2)
		## Si el boton repartia ancho por el largo de su rotulo -la fila de
		## acciones-, el reparto se rehace con el rotulo NUEVO: "Temporada
		## siguiente" y "Next season" no piden lo mismo.
		if nuevo2 != actual2 and b.size_flags_stretch_ratio != 1.0:
			b.size_flags_stretch_ratio = clampf(float(nuevo2.length()) / 12.0, 0.95, 1.9)
		b.text = nuevo2
	if n.has_method("get_tooltip_text") and n is Control:
		var ctrl := n as Control
		var actual_tip := ctrl.tooltip_text
		if actual_tip != "":
			var fue_mio_tip: bool = ctrl.has_meta("_i18n_tip_out") and String(ctrl.get_meta("_i18n_tip_out")) == actual_tip
			var base_tip: String = String(ctrl.get_meta("_i18n_tip_src")) if fue_mio_tip else actual_tip
			var nuevo_tip := base_tip if Idiomas.idioma == "es" else Idiomas.t(base_tip)
			ctrl.set_meta("_i18n_tip_src", base_tip)
			ctrl.set_meta("_i18n_tip_out", nuevo_tip)
			ctrl.tooltip_text = nuevo_tip
	for h in n.get_children():
		_traducir_pantalla(h)

## EL SELECTOR DE IDIOMA. Dice la cobertura de verdad -cuántas frases hay
## traducidas- en vez de prometer un juego entero en otro idioma: la narración
## sigue en castellano y eso hay que verlo antes de cambiar, no después.
func _pintar_idioma() -> void:
	_lista_ajustes.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "IDIOMA"
	_lista_ajustes.add_child(t)
	var ex := _texto(10, COL_SUAVE)
	ex.text = "Están traducidos los menús, las pestañas, los botones y los títulos. Las noticias, las preguntas de la prensa y los diálogos del vestuario siguen en castellano: son varios miles de frases y traducirlas a medias se lee peor que no traducirlas."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_ajustes.add_child(ex)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 4)
	_lista_ajustes.add_child(flow)
	for k: String in Idiomas.NOMBRES:
		var clave := k
		var ficha: Array = Idiomas.NOMBRES[k]
		var b := Button.new()
		b.text = "%s  %s" % [String(ficha[1]), String(ficha[0])]
		b.add_theme_font_size_override("font_size", 11)
		b.toggle_mode = true
		b.button_pressed = Idiomas.idioma == clave
		b.clip_text = true
		b.custom_minimum_size = Vector2(150, 26)
		b.tooltip_text = "Idioma original, sin traducir nada." if clave == "es" else "%d frases de interfaz traducidas." % Idiomas.cobertura(clave)
		b.pressed.connect(func() -> void:
			Idiomas.idioma = clave
			_refrescar())
		flow.add_child(b)

## LA MONEDA (25-9-2026). Solo cambia cómo se escribe el dinero: el tipo de
## cambio es fijo y el motor no se entera (ver `Eco.MONEDAS`).
func _pintar_moneda() -> void:
	_lista_ajustes.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "MONEDA"
	_lista_ajustes.add_child(t)
	var ex := _texto(10, COL_SUAVE)
	ex.text = "Cambia cómo se muestra el dinero en todo el juego. Es un tipo de cambio fijo: tu caja y el valor de tu plantel no suben ni bajan por elegir otra."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_ajustes.add_child(ex)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 4)
	_lista_ajustes.add_child(flow)
	for k: String in Eco.MONEDAS:
		var codigo := k
		var b := Button.new()
		b.text = "%s  %s" % [codigo, String(Eco.MONEDAS[codigo]["nombre"])]
		b.add_theme_font_size_override("font_size", 11)
		b.toggle_mode = true
		b.button_pressed = Eco.moneda == codigo
		b.clip_text = true
		b.custom_minimum_size = Vector2(190, 26)
		b.pressed.connect(func() -> void:
			Eco.elegir_moneda(codigo)
			_refrescar())
		flow.add_child(b)

func _pintar_musica() -> void:

	_lista_ajustes.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "MÚSICA"
	_lista_ajustes.add_child(t)
	if not _modo_experto:
		var ex := _texto(10, COL_SUAVE)
		ex.text = "Compuesta por el juego, no grabada: por eso cambia con lo que pasa —hay una pieza para los últimos minutos y otra para la vuelta olímpica— y por eso no pesa nada."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_ajustes.add_child(ex)

	var f1 := HBoxContainer.new()
	f1.add_theme_constant_override("separation", 8)
	_lista_ajustes.add_child(f1)
	var e1 := _texto(12, COL_TEXTO)
	e1.text = "Música"
	e1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	f1.add_child(e1)
	var b1 := Button.new()
	b1.text = "SÍ" if Musica.encendida else "NO"
	b1.pressed.connect(func() -> void:
		Musica.encendida = not Musica.encendida
		if Musica.encendida:
			Musica.ambientar(_situacion_musical())
		else:
			Musica.parar()
		_refrescar())
	f1.add_child(b1)

	var f2 := HBoxContainer.new()
	f2.add_theme_constant_override("separation", 8)
	_lista_ajustes.add_child(f2)
	var e2 := _texto(12, COL_TEXTO if Musica.encendida else COL_SUAVE)
	e2.text = "Volumen"
	e2.custom_minimum_size = Vector2(70, 0)
	f2.add_child(e2)
	var sl := HSlider.new()
	sl.min_value = 0.0
	sl.max_value = 1.0
	sl.step = 0.05
	sl.value = Musica.volumen
	sl.editable = Musica.encendida
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pct := _texto(11, COL_SUAVE)
	pct.text = "%d%%" % int(round(Musica.volumen * 100.0))
	pct.custom_minimum_size = Vector2(38, 0)
	sl.value_changed.connect(func(v: float) -> void:
		Musica.volumen = v
		pct.text = "%d%%" % int(round(v * 100.0))
		## El volumen sí se aplica al arrastrar: es lo único que se puede juzgar
		## oyéndolo, y la pieza ya está sonando.
		Musica.aplicar_volumen())
	f2.add_child(sl)
	f2.add_child(pct)

	var f3 := HBoxContainer.new()
	f3.add_theme_constant_override("separation", 8)
	_lista_ajustes.add_child(f3)
	var e3 := _texto(12, COL_TEXTO if Musica.encendida else COL_SUAVE)
	e3.text = "Que la elija el juego"
	e3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	e3.tooltip_text = "Encendido, la pieza cambia con lo que pasa: oficina en los menús, tensión en los últimos minutos, gloria al levantar algo. Apagado, suena siempre la que elijas."
	f3.add_child(e3)
	var b3 := Button.new()
	b3.text = "SÍ" if Musica.automatica else "NO"
	b3.disabled = not Musica.encendida
	b3.pressed.connect(func() -> void:
		Musica.automatica = not Musica.automatica
		Musica.ambientar(_situacion_musical())
		_refrescar())
	f3.add_child(b3)

	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 4)
	_lista_ajustes.add_child(flow)
	for k: String in Musica.PIEZAS:
		var clave := k
		var p: Dictionary = Musica.PIEZAS[k]
		var b := Button.new()
		b.text = String(p["nombre"])
		b.add_theme_font_size_override("font_size", 10)
		b.toggle_mode = true
		b.button_pressed = Musica.pieza == clave and not Musica.automatica
		b.disabled = not Musica.encendida
		b.clip_text = true
		b.custom_minimum_size = Vector2(168, 24)
		b.tooltip_text = String(p["desc"])
		b.pressed.connect(func() -> void:
			## Elegir una a mano apaga el automático: si no, el siguiente cambio
			## de pantalla te la quitaría y parecería que el botón no funciona.
			Musica.automatica = false
			Musica.pieza = clave
			Musica.poner(clave)
			_refrescar())
		flow.add_child(b)

## Qué le toca sonar según lo que está pasando en la partida. Es la única regla
## de la música que sabe algo del juego, y por eso vive aquí y no en `Musica`.
func _situacion_musical() -> String:
	if mundo == null:
		return "menu"
	var c := mundo.mi_club()
	if c == null:
		return "menu"
	## Las tres últimas jornadas del año: tensión. Es lo único que sabe la música
	## de la partida, y con esto basta —el resto de situaciones las manda quien
	## llama, no una regla que hay que mantener al día.
	var liga := _liga_de(c)
	if liga != null and liga.jornada_actual >= liga.jornadas() - 2:
		return "final"
	return "menu"

func _pintar_mezclador() -> void:

	for b: Array in BUSES_AUDIO:
		var bus: int = b[0]
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		_lista_ajustes.add_child(fila)
		var et := _texto(12, COL_TEXTO if Sonido.encendido else COL_SUAVE)
		et.text = String(b[1])
		et.custom_minimum_size = Vector2(70, 0)
		fila.add_child(et)
		var sl := HSlider.new()
		sl.min_value = 0.0
		sl.max_value = 1.0
		sl.step = 0.05
		sl.value = float(Sonido.volumen.get(bus, 0.5))
		sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sl.editable = Sonido.encendido
		var pct := _texto(11, COL_SUAVE)
		pct.text = "%d%%" % int(round(sl.value * 100.0))
		pct.custom_minimum_size = Vector2(38, 0)
		## El número se actualiza al arrastrar, pero el sonido de prueba NO suena
		## en cada paso del deslizador: serían veinte pitidos por gesto.
		sl.value_changed.connect(func(v: float) -> void:
			Sonido.volumen[bus] = v
			pct.text = "%d%%" % int(round(v * 100.0)))
		fila.add_child(sl)
		fila.add_child(pct)
		var bp := Button.new()
		bp.text = "▶"
		bp.tooltip_text = String(b[3])
		bp.add_theme_font_size_override("font_size", 11)
		bp.disabled = not Sonido.encendido
		var muestra := String(b[2])
		bp.pressed.connect(func() -> void: Sonido.toca(muestra, bus))
		fila.add_child(bp)

## LAS TRES RANURAS MANUALES de `vAjustes()`. `Partida` guarda por NOMBRE desde
## el porte —`guardar(m, nombre)`, `listar()`, `borrar()`— y el juego solo usaba
## una ranura fija: toda esa capacidad estaba escrita y era inalcanzable.
##
## Tres y no más porque tres es lo que se usa de verdad: la partida en curso,
## una copia antes de una decisión gorda, y una vieja por si acaso.
const RANURAS := ["ranura1", "ranura2", "ranura3"]

## LAS PEÑAS Y LAS RAMAS: las dos formas de que el club sea más que un equipo.
##
## Las peñas suman socios donde no llegas. Las ramas CUESTAN todos los meses y
## no dan dinero: dan reputación. Es deliberado que sean un gasto puro —un club
## que solo hace lo que da dinero no es un club, es una empresa— y sostener el
## femenino aunque no pague es de las decisiones que definen qué llevas.
func _pintar_penas_y_ramas(c: Club, h: Hinchada) -> void:
	_lista_estadio.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "🧣 PEÑAS  ·  %d" % h.penas.size()
	_lista_estadio.add_child(t)
	if not h.penas.is_empty():
		var nombres: Array[String] = []
		for p: Dictionary in h.penas:
			nombres.append("%s (%s socios)" % [String(p.get("ciudad", "")), _miles(int(p.get("socios", 0)))])
		var l := _texto(11, COL_SUAVE)
		l.text = ", ".join(nombres)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_estadio.add_child(l)
	var coste_p := Eco.escalar(Hinchada.COSTE_PENA, float(c.rep))
	var bp := Button.new()
	bp.text = "Fundar una peña  ·  %s" % _dinero(coste_p)
	bp.disabled = c.saldo < coste_p
	bp.pressed.connect(func() -> void: _fundar_pena(c))
	_lista_estadio.add_child(bp)

	var tr := _texto(11, COL_SUAVE)
	tr.text = "🏛️ RAMAS DEL CLUB  ·  cuestan %s/mes" % _dinero(h.coste_ramas(c))
	_lista_estadio.add_child(tr)
	if not _modo_experto:
		var ex := _texto(10, COL_SUAVE)
		ex.text = "No dan dinero: dan reputación. Sostenerlas cuando aprieta la caja es una decisión de verdad."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_estadio.add_child(ex)
	for f: Array in Hinchada.RAMAS:
		var clave := String(f[0])
		var abierta := h.tiene_rama(clave)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_lista_estadio.add_child(fila)
		var n := _texto(12, COL_VERDE if abierta else COL_TEXTO)
		n.text = "%s  %s" % [String(f[1]), String(f[2])]
		n.custom_minimum_size = Vector2(150, 0)
		n.tooltip_text = String(f[7])
		fila.add_child(n)
		var rep := _texto(11, COL_ORO)
		rep.text = ("%d temp." % int(h.anios_rama.get(clave, 0))) if abierta else "+%d rep" % int(f[5])
		rep.custom_minimum_size = Vector2(58, 0)
		fila.add_child(rep)
		var mens := _texto(11, COL_SUAVE)
		mens.text = "%s/mes" % _dinero(Eco.escalar(float(f[4]), float(c.rep)))
		mens.custom_minimum_size = Vector2(80, 0)
		fila.add_child(mens)
		var b := Button.new()
		var coste_r := Eco.escalar(float(f[3]), float(c.rep))
		b.text = "Cerrar" if abierta else _dinero(coste_r)
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = not abierta and c.saldo < coste_r
		b.custom_minimum_size = Vector2(96, 0)
		b.pressed.connect(func() -> void: _alternar_rama(clave, c, abierta))
		fila.add_child(b)
		if not _modo_experto:
			var d := _texto(10, COL_SUAVE)
			d.text = "     %s" % String(f[7])
			d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			d.clip_text = true
			fila.add_child(d)
	_pintar_palmares_ramas(h)

## EL PALMARÉS DE LAS RAMAS (C12): títulos y podios de cada temporada.
func _pintar_palmares_ramas(h: Hinchada) -> void:
	if h.palmares_ramas.is_empty():
		return
	var t := _texto(11, COL_ORO)
	t.text = "🏅 PALMARÉS DE LAS RAMAS"
	_lista_estadio.add_child(t)
	for d: Dictionary in h.palmares_ramas.slice(0, 8):
		var l := _texto(11, COL_TEXTO)
		l.text = "%d · %s · %s" % [int(d["anio"]), String(d["rama"]), "🏆 Campeón" if int(d["puesto"]) == 1 else "🥉 Podio (%d.º)" % int(d["puesto"])]
		_lista_estadio.add_child(l)

func _fundar_pena(c: Club) -> void:
	var r := mundo.hinchada.fundar_pena(c)
	if r.length() > 40 or r == "":
		_escribir("[color=#e05555]No se pudo fundar: %s.[/color]" % r)
	else:
		_escribir("[color=#3fa06a][b]Nueva peña en %s.[/b][/color] Gente que se organiza sola para seguir al club desde lejos." % r)
		_anotar("Nueva peña en %s" % r, "El club llega a donde no llegaba.")
	_refrescar()

func _alternar_rama(clave: String, c: Club, abierta: bool) -> void:
	var problema := mundo.hinchada.cerrar_rama(clave, c) if abierta else mundo.hinchada.abrir_rama(clave, c)
	if problema != "":
		_escribir("[color=#e05555]No se pudo: %s.[/color]" % problema)
	else:
		var d := mundo.hinchada.def_rama(clave)
		if abierta:
			_escribir("[color=#e05555]Se cierra la rama de %s.[/color] El club pierde reputación, y la gente de esa sección no lo va a olvidar." % String(d[2]))
		else:
			_escribir("[color=#3fa06a]Se abre la rama de %s.[/color] %s" % [String(d[2]), String(d[7])])
	_refrescar()

func _organizar_dia_hincha(c: Club) -> void:
	var problema := mundo.hinchada.dia_del_hincha(c, mundo.prensa)
	if problema != "":
		_escribir("[color=#e05555]No se pudo organizar: %s.[/color]" % problema)
		_refrescar()
		return
	_escribir("[color=#c9a227][b]🎪 Día del hincha.[/b][/color] Puertas abiertas, entrenamiento a la vista de todos, firma de autógrafos y partido de leyendas. El estadio fue una fiesta y los socios lo van a recordar.")
	_anotar("Día del hincha", "El club abrió las puertas y la gente respondió. Todos los segmentos de la hinchada suben.")
	Aviso.mostrar(self, "logro", "🎪", "Día del hincha", "El estadio fue una fiesta.")
	_refrescar()

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

## La tabla de atajos que le faltaba a `vAjustes()`. Se escribió recién ahora
## -no antes- porque hasta corregir el bug de L1/R1 de más abajo (`_input()`)
## una tabla como esta habría podido documentar un comportamiento con mando
## que en los hechos no existía. Solo referencia: no cambia ningún ajuste.
func _pintar_atajos() -> void:
	_lista_ajustes.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "ATAJOS DE TECLADO Y MANDO"
	_lista_ajustes.add_child(t)
	for fila_a: Array in [
			["Cambiar de chip (dentro del bloque)", "Q  /  E", "L1  /  R1"],
			["Cambiar de bloque maestro", "Ctrl+Q  /  Ctrl+E", "L2  /  R2"],
			["Moverse por la pantalla", "Flechas", "Cruceta o stick izq."],
			["Aceptar / Volver", "Enter / Esc", "A / B"],
	]:
		var f := HBoxContainer.new()
		f.add_theme_constant_override("separation", 8)
		_lista_ajustes.add_child(f)
		var et := _texto(11, COL_TEXTO)
		et.text = String(fila_a[0])
		et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		et.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		f.add_child(et)
		var tec := _texto(11, COL_SUAVE)
		tec.text = String(fila_a[1])
		tec.custom_minimum_size = Vector2(120, 0)
		f.add_child(tec)
		var man := _texto(11, COL_SUAVE)
		man.text = String(fila_a[2])
		man.custom_minimum_size = Vector2(120, 0)
		f.add_child(man)
	var nota := _texto(10, COL_SUAVE)
	nota.text = "En pantalla táctil, un desliz horizontal largo también cambia de bloque maestro."
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_ajustes.add_child(nota)

func _pintar_dispositivo() -> void:
	var t := _texto(11, COL_SUAVE)
	t.text = "PANTALLA Y DISPOSITIVO"
	_lista_ajustes.add_child(t)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	_lista_ajustes.add_child(fila)
	var et := _texto(12, COL_TEXTO)
	et.text = "Pantalla completa"
	et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(et)
	var completa := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	var b := Button.new()
	b.text = "SÍ" if completa else "NO"
	b.pressed.connect(func() -> void:
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED if completa else DisplayServer.WINDOW_MODE_FULLSCREEN)
		_refrescar())
	fila.add_child(b)

	var fila2 := HBoxContainer.new()
	fila2.add_theme_constant_override("separation", 8)
	_lista_ajustes.add_child(fila2)
	var et2 := _texto(12, COL_TEXTO)
	et2.text = "Tamaño de la interfaz"
	et2.custom_minimum_size = Vector2(150, 0)
	fila2.add_child(et2)
	var sl := HSlider.new()
	sl.min_value = 0.8
	sl.max_value = 1.4
	sl.step = 0.05
	sl.value = _zoom_interfaz
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pct := _texto(11, COL_SUAVE)
	pct.text = "%d%%" % int(round(_zoom_interfaz * 100.0))
	pct.custom_minimum_size = Vector2(44, 0)
	sl.value_changed.connect(func(v: float) -> void:
		_zoom_interfaz = v
		pct.text = "%d%%" % int(round(v * 100.0))
		## `content_scale_factor` escala la interfaz ENTERA de golpe. Tocar el
		## tamaño de fuente de cada etiqueta a mano sería repintar todo y dejaría
		## los anchos mínimos descuadrados.
		get_tree().root.content_scale_factor = v)
	fila2.add_child(sl)
	fila2.add_child(pct)
	var ex := _texto(10, COL_SUAVE)
	ex.text = "No se guarda con la partida: es de esta máquina, no de este club."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_ajustes.add_child(ex)

	## MODO TELEVISIÓN. Para HDMI y pantallas grandes: se mira desde el sofá, a
	## tres metros, y lo que a medio metro es cómodo a tres metros no se lee. Es
	## un zoom fuerte de golpe, no un ajuste fino.
	var fila_tv := HBoxContainer.new()
	fila_tv.add_theme_constant_override("separation", 8)
	_lista_ajustes.add_child(fila_tv)
	var et_tv := _texto(12, COL_TEXTO)
	et_tv.text = "Modo televisión"
	et_tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et_tv.tooltip_text = "Para HDMI y pantallas grandes: todo más grande, pensado para mirarse desde lejos."
	fila_tv.add_child(et_tv)
	var b_tv := Button.new()
	b_tv.text = "SÍ" if _modo_tv else "NO"
	b_tv.pressed.connect(func() -> void:
		_modo_tv = not _modo_tv
		_zoom_interfaz = ZOOM_TV if _modo_tv else 1.0
		get_tree().root.content_scale_factor = _zoom_interfaz
		_refrescar())
	fila_tv.add_child(b_tv)

	## ROPA APARTE (26-9-2026): camiseta, pantalón y medias como mallas propias
	## con volumen en el partido 3D (en el diseñador siempre).
	var fila_ra := HBoxContainer.new()
	fila_ra.add_theme_constant_override("separation", 8)
	_lista_ajustes.add_child(fila_ra)
	var et_ra := _texto(12, COL_TEXTO)
	et_ra.text = "Ropa 3D en piezas separadas"
	et_ra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et_ra.tooltip_text = "La equipación con volumen propio (más realista). Cuesta tres mallas más por jugador en el partido."
	fila_ra.add_child(et_ra)
	var b_ra := Button.new()
	b_ra.text = "SÍ" if VestidorQ.ropa_aparte else "NO"
	b_ra.pressed.connect(func() -> void:
		VestidorQ.ropa_aparte = not VestidorQ.ropa_aparte
		_guardar_preferencias()
		_refrescar())
	fila_ra.add_child(b_ra)

	## CALIDAD GRÁFICA. Manda en el visor 3D del estadio, que es lo único del
	## juego que puede ir lento: la interfaz son etiquetas y no cuesta nada.
	## `Calidad` ya tenía los tres niveles montados desde el porte del visor.
	var tc := _texto(10, COL_SUAVE)
	tc.text = "Calidad gráfica del estadio en 3D"
	_lista_ajustes.add_child(tc)
	var fila_c := HBoxContainer.new()
	fila_c.add_theme_constant_override("separation", 4)
	_lista_ajustes.add_child(fila_c)
	for nivel: Array in [
			[Calidad.ULTRA, "Ultra", "Todos los efectos, sombras y reflejos"],
			[Calidad.ALTO, "Alta", "El equilibrio: sombras sí, lo más caro no"],
			[Calidad.MEDIO, "Media", "Sin efectos pesados: máxima fluidez"],
		]:
		var clave: int = nivel[0]
		var b_c := Button.new()
		b_c.text = String(nivel[1])
		b_c.add_theme_font_size_override("font_size", 11)
		b_c.toggle_mode = true
		b_c.button_pressed = Calidad.elegida == clave
		b_c.tooltip_text = String(nivel[2])
		b_c.custom_minimum_size = Vector2(70, 0)
		b_c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b_c.pressed.connect(func() -> void:
			Calidad.elegida = clave
			_refrescar())
		fila_c.add_child(b_c)
	var ad := CheckButton.new()
	ad.text = "Ajustar sola para mantener 40 FPS en el partido"
	ad.tooltip_text = "Si tu equipo no llega a 40 FPS, el partido apaga por escalones la oclusión ambiental, acorta las sombras y baja la resolución del 3D."
	ad.button_pressed = Calidad.adaptativa
	ad.add_theme_font_size_override("font_size", 11)
	ad.toggled.connect(func(si: bool) -> void: Calidad.adaptativa = si)
	_lista_ajustes.add_child(ad)
	if not _modo_experto:
		var ec := _texto(10, COL_SUAVE)
		ec.text = "Si el estadio en 3D se siente lento, baja la calidad. La interfaz no cambia: son etiquetas y no cuestan nada."
		ec.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_ajustes.add_child(ec)
	_lista_ajustes.add_child(HSeparator.new())

## "Velocidad de partido por defecto" de `vAjustes()`: con qué velocidad
## arranca cada partido dirigido en vivo. Antes de esta tanda el juego lo
## arrancaba siempre en "Normal" sin que hubiera dónde cambiarlo -no era un
## dato guardado, era un número fijo dentro de `PartidoVivo`-.
func _pintar_velocidad_partido() -> void:
	_lista_ajustes.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "VELOCIDAD DE PARTIDO POR DEFECTO"
	_lista_ajustes.add_child(t)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	_lista_ajustes.add_child(fila)
	## Del 1 al 3: "Pausa" (índice 0) no tiene sentido como velocidad de
	## arranque -nadie quiere que el partido empiece parado-, igual que el
	## HTML se salta esa opción en este mismo selector.
	for i in range(1, PartidoVivo.VELOCIDADES.size()):
		var idx := i
		var b := Button.new()
		b.text = String(PartidoVivo.VELOCIDADES[i]["txt"])
		b.toggle_mode = true
		b.button_pressed = (_velocidad_partido == idx)
		b.custom_minimum_size = Vector2(90, 30)
		b.pressed.connect(func() -> void:
			_velocidad_partido = idx
			_refrescar())
		fila.add_child(b)

func _pintar_qol() -> void:
	var t := _texto(11, COL_SUAVE)
	t.text = "LA INTERFAZ A TU MEDIDA"
	_lista_ajustes.add_child(t)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	_lista_ajustes.add_child(fila)
	var et := _texto(12, COL_TEXTO)
	et.text = "Modo experto"
	et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et.tooltip_text = "Oculta las explicaciones y los consejos de todas las pantallas. No quita ninguna función."
	fila.add_child(et)
	var b := Button.new()
	b.text = "SÍ" if _modo_experto else "NO"
	b.pressed.connect(func() -> void:
		_modo_experto = not _modo_experto
		_refrescar())
	fila.add_child(b)
	if not _modo_experto:
		var ex := _texto(10, COL_SUAVE)
		ex.text = "Con el modo experto encendido desaparecen las notas explicativas como esta."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_ajustes.add_child(ex)

	## ANIMACIONES REDUCIDAS (plan maestro B11): apaga las mini animaciones de
	## la interfaz (entradas escalonadas, cifras que cuentan, latidos).
	var fila_an := HBoxContainer.new()
	fila_an.add_theme_constant_override("separation", 8)
	_lista_ajustes.add_child(fila_an)
	var et_an := _texto(12, COL_TEXTO)
	et_an.text = "Animaciones reducidas"
	et_an.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et_an.tooltip_text = "Sin entradas escalonadas, cifras que cuentan ni latidos: todo aparece al instante."
	fila_an.add_child(et_an)
	var b_an := Button.new()
	b_an.text = "SÍ" if Animar.reducidas() else "NO"
	b_an.pressed.connect(func() -> void:
		Animar.fijar_reducidas(not Animar.reducidas())
		_refrescar())
	fila_an.add_child(b_an)

	## LA VISTA COMPACTA. Aprieta las filas de todas las pantallas a la vez: en
	## una tabla de veinte jugadores es la diferencia entre ver media plantilla y
	## verla entera sin desplazarse.
	var fila_vc := HBoxContainer.new()
	fila_vc.add_theme_constant_override("separation", 8)
	_lista_ajustes.add_child(fila_vc)
	var et_vc := _texto(12, COL_TEXTO)
	et_vc.text = "Vista compacta"
	et_vc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et_vc.tooltip_text = "Filas más juntas: cabe más información en pantalla."
	fila_vc.add_child(et_vc)
	var b_vc := Button.new()
	b_vc.text = "SÍ" if _vista_compacta else "NO"
	b_vc.pressed.connect(func() -> void:
		_vista_compacta = not _vista_compacta
		_aplicar_vista_compacta()
		_refrescar())
	fila_vc.add_child(b_vc)

	## DESHACER. La pila guarda la partida entera antes de las decisiones que se
	## toman con el dedo: vender a alguien y rescindir un contrato.
	var fila_dh := HBoxContainer.new()
	fila_dh.add_theme_constant_override("separation", 8)
	_lista_ajustes.add_child(fila_dh)
	var et_dh := _texto(12, COL_TEXTO)
	et_dh.text = "Deshacer la última decisión"
	et_dh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et_dh.tooltip_text = "Se guarda la partida entera antes de vender o rescindir. Como mucho tres pasos atrás."
	fila_dh.add_child(et_dh)
	var b_dh := Button.new()
	b_dh.text = "↩ Deshacer (%d)" % _pila_deshacer.size() if not _pila_deshacer.is_empty() else "↩ Nada que deshacer"
	b_dh.disabled = _pila_deshacer.is_empty()
	b_dh.pressed.connect(func() -> void: _deshacer())
	fila_dh.add_child(b_dh)
	if not _pila_deshacer.is_empty() and not _modo_experto:
		var ed := _texto(10, COL_SUAVE)
		ed.text = "Lo último: %s." % String((_pila_deshacer[_pila_deshacer.size() - 1] as Dictionary)["motivo"])
		ed.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_ajustes.add_child(ed)

	## LOS FAVORITOS. Seis atajos a las pestañas que más usas, que salen en la
	## portada del club. Seis y no doce: si caben todas deja de ser una elección.
	var tf := _texto(11, COL_SUAVE)
	tf.text = "⭐ ACCESOS RÁPIDOS  ·  %d de %d" % [_favoritos.size(), FAVORITOS_MAX]
	_lista_ajustes.add_child(tf)
	var ef := _texto(10, COL_SUAVE)
	ef.text = "Aparecen en Inicio. Marca aquí las pestañas a las que más vuelves."
	ef.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_ajustes.add_child(ef)
	var rej := GridContainer.new()
	rej.columns = 4
	rej.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista_ajustes.add_child(rej)
	## BUG REAL, encontrado por accidente probando otra cosa (11-9-2026):
	## `g["tabs"]` no es una lista de strings -lo era antes de que existieran
	## los chips `{tab, secc, label}`-, así que `for tab: String in ...`
	## reventaba con "Trying to assign value of type 'Dictionary' to a
	## variable of type 'String'" en cuanto alguien abriera esta sección.
	## Ningún banco lo vio nunca -no carga `ui/`- y ninguna captura de esta
	## sesión había entrado a Ajustes → Juego hasta ahora. Se extrae el
	## nombre de pestaña de cada chip, sin repetir: varios chips comparten
	## la misma pestaña (distinto `secc`) y un botón por chip habría
	## duplicado "Club" media docena de veces.
	var vistas: Array[String] = []
	for g: Dictionary in GRUPOS:
		for chip: Dictionary in (g["tabs"] as Array):
			var tab := String(chip["tab"])
			if vistas.has(tab):
				continue
			vistas.append(tab)
			var fav := _favoritos.has(tab)
			var bt := Button.new()
			bt.text = ("★ " if fav else "") + tab
			bt.toggle_mode = true
			bt.button_pressed = fav
			bt.add_theme_font_size_override("font_size", 11)
			bt.clip_text = true
			bt.custom_minimum_size = Vector2(90, 0)
			bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bt.disabled = not fav and _favoritos.size() >= FAVORITOS_MAX
			bt.pressed.connect(func() -> void: _alternar_favorito(tab))
			rej.add_child(bt)
	_lista_ajustes.add_child(HSeparator.new())


# ---------------------------------------------------------------------------
#  DESHACER Y VISTA COMPACTA (`vQoL()`)
# ---------------------------------------------------------------------------
#
# DESHACER. El HTML guardaba `JSON.stringify(G)` antes de dos decisiones -responder
# a una oferta y rescindir a un jugador- y las devolvía con un `JSON.parse`. Aquí
# el retrato es `Partida.instantanea()`, que es exactamente el mismo diccionario
# que se escribe en el guardado, y volver atrás es reconstruir el mundo desde él.
# No es un "ctrl+z" general y no pretende serlo: son las dos decisiones que se
# toman con el dedo y se lamentan al segundo siguiente.
#
# TRES COMO MUCHO. Cada retrato es la partida entera; con diez, la memoria se
# llenaría de mundos muertos. El HTML también corta en tres.
const DESHACER_MAX := 3
var _pila_deshacer: Array[Dictionary] = []

## Guarda el estado ANTES de hacer algo. `motivo` es lo que se le enseña al
## jugador cuando lo deshaga.
func _apuntar_deshacer(motivo: String) -> void:
	if mundo == null:
		return
	_pila_deshacer.append({"motivo": motivo, "estado": Partida.instantanea(mundo)})
	while _pila_deshacer.size() > DESHACER_MAX:
		_pila_deshacer.pop_front()

func _deshacer() -> void:
	if _pila_deshacer.is_empty():
		_escribir("[color=#c9a227]No hay nada que deshacer.[/color]")
		return
	var u: Dictionary = _pila_deshacer.pop_back()
	var m := Partida.desde_instantanea(u["estado"])
	if m == null:
		_escribir("[color=#e05555]No se pudo deshacer.[/color]")
		return
	mundo = m
	_conectar_noticias()
	_seleccionado = null
	_llenar_selector()
	_escribir("[color=#3fa06a]Deshecho:[/color] %s." % String(u["motivo"]))
	_refrescar()


# ---------------------------------------------------------------------------
#  EL TEMA DE LA PALETA
# ---------------------------------------------------------------------------
#
# `_panel()` pinta las tarjetas que crea el juego, pero NO pinta lo que dibuja
# Godot por su cuenta: el fondo de las pestañas, los botones, los desplegables,
# las barras. Eso sale del tema oscuro que trae el motor de fábrica, y con una
# paleta clara quedaba la mitad de arriba en crema y la mitad de abajo en gris
# oscuro, con el texto ya traducido a oscuro y por tanto ilegible.
#
# Se arregla en el sitio donde se arregla de verdad: un `Theme` colgado de la
# raíz. Baja por todos los hijos de golpe, así que las nueve paletas valen para
# la interfaz entera sin tocar ni una pantalla.

## Mezcla dos colores. Los tonos de los botones -reposo, encima, pulsado- no se
## escriben a mano nueve veces: se derivan del panel y del texto de cada paleta,
## que es lo que hace que añadir una paleta cueste una línea.
func _mezcla(a: Color, b: Color, t: float) -> Color:
	return Color(lerpf(a.r, b.r, t), lerpf(a.g, b.g, t), lerpf(a.b, b.b, t), a.a)

func _caja(fondo: Color, borde: Color, radio: int, grosor: int) -> StyleBoxFlat:
	var e := StyleBoxFlat.new()
	e.bg_color = fondo
	e.border_color = borde
	e.set_border_width_all(grosor)
	e.set_corner_radius_all(radio)
	e.content_margin_left = 8
	e.content_margin_right = 8
	e.content_margin_top = 4
	e.content_margin_bottom = 4
	return e

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

func _fuente_de(clave: String) -> Font:
	if not TIPOGRAFIAS.has(clave) or clave == "juego":
		return null
	if _fuentes.has(clave):
		return _fuentes[clave]
	var f := SystemFont.new()
	var nombres: Array = (TIPOGRAFIAS[clave] as Array)[1]
	f.font_names = PackedStringArray(nombres + REPUESTO_SIMBOLOS)
	## Sin esto, un texto pequeno con una serif se ve sucio: la rejilla de pixeles
	## y los remates finos pelean, y a 10 px gana la rejilla.
	f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	_fuentes[clave] = f
	return f

func _pintar_tipografia() -> void:
	var lt := _texto(10, COL_SUAVE)
	lt.text = "Tipografia"
	_lista_ajustes.add_child(lt)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 4)
	_lista_ajustes.add_child(flow)
	for k: String in TIPOGRAFIAS:
		var clave := k
		var b := Button.new()
		b.text = String((TIPOGRAFIAS[k] as Array)[0])
		b.add_theme_font_size_override("font_size", 10)
		b.toggle_mode = true
		b.button_pressed = _tipografia == clave
		b.clip_text = true
		b.custom_minimum_size = Vector2(132, 24)
		## Cada boton se escribe CON su fuente: se elige mirando, igual que las
		## paletas. Un nombre de fuente no dice nada; verla, si.
		var f := _fuente_de(clave)
		if f != null:
			b.add_theme_font_override("font", f)
		b.pressed.connect(func() -> void:
			_tipografia = clave
			_aplicar_aspecto()
			_refrescar())
		flow.add_child(b)

func _aplicar_tema() -> void:
	var t := theme if theme != null else Theme.new()
	## La fuente va en `default_font` del tema: baja por todo -etiquetas, botones,
	## pestanas, el registro- sin tener que decirselo a cada clase.
	t.default_font = _fuente_de(_tipografia)
	var panel := _pal_panel()
	var texto := _pal_texto()
	var suave := _pal_suave()
	var borde := _pal_borde()
	var forma: Array = FORMAS_TARJETA.get(_forma_tarjeta, ["", 8, 1])
	var radio := int(forma[1])

	## El botón: un panel un pelo desplazado hacia el texto, para que se despegue
	## del fondo sin ser otro color. Encima aclara, pulsado se va al acento.
	var reposo := _mezcla(panel, texto, 0.14)
	t.set_stylebox("normal", "Button", _caja(reposo, borde, radio, 1))
	t.set_stylebox("hover", "Button", _caja(_mezcla(panel, texto, 0.24), borde, radio, 1))
	t.set_stylebox("pressed", "Button", _caja(_mezcla(panel, COL_ACENTO, 0.45), COL_ACENTO, radio, 1))
	t.set_stylebox("focus", "Button", _caja(Color(0, 0, 0, 0), COL_ACENTO, radio, 2))
	t.set_stylebox("disabled", "Button", _caja(_mezcla(panel, texto, 0.05), borde, radio, 1))
	t.set_color("font_color", "Button", texto)
	t.set_color("font_hover_color", "Button", texto)
	t.set_color("font_pressed_color", "Button", texto)
	t.set_color("font_disabled_color", "Button", _mezcla(suave, panel, 0.5))

	## Los desplegables y las casillas heredan del botón: en Godot son clases
	## distintas y si no se les dice nada se quedan con el tema oscuro de fábrica.
	for clase: String in ["OptionButton", "MenuButton", "CheckBox", "CheckButton"]:
		t.set_stylebox("normal", clase, _caja(reposo, borde, radio, 1))
		t.set_stylebox("hover", clase, _caja(_mezcla(panel, texto, 0.24), borde, radio, 1))
		t.set_stylebox("pressed", clase, _caja(_mezcla(panel, COL_ACENTO, 0.45), COL_ACENTO, radio, 1))
		t.set_color("font_color", clase, texto)
		t.set_color("font_hover_color", clase, texto)

	## Las pestañas. El fondo de la hoja es EL panel, sin borde: encima van las
	## tarjetas, y dos bordes pegados uno dentro de otro se ven como un error.
	var hoja := _caja(panel, borde, radio, 0)
	hoja.content_margin_left = 6
	hoja.content_margin_right = 6
	hoja.content_margin_top = 6
	hoja.content_margin_bottom = 6
	t.set_stylebox("panel", "TabContainer", hoja)
	t.set_stylebox("tabbar_background", "TabContainer", _caja(Color(0, 0, 0, 0), borde, 0, 0))
	t.set_stylebox("tab_selected", "TabContainer", _caja(_mezcla(panel, COL_ACENTO, 0.30), COL_ACENTO, radio, 1))
	t.set_stylebox("tab_unselected", "TabContainer", _caja(_mezcla(panel, texto, 0.06), borde, radio, 1))
	t.set_stylebox("tab_hovered", "TabContainer", _caja(_mezcla(panel, texto, 0.18), borde, radio, 1))
	t.set_color("font_selected_color", "TabContainer", texto)
	t.set_color("font_unselected_color", "TabContainer", suave)
	t.set_color("font_hovered_color", "TabContainer", texto)

	t.set_stylebox("panel", "Panel", _caja(panel, borde, radio, 1))
	t.set_stylebox("panel", "PanelContainer", _caja(panel, borde, radio, 1))
	t.set_stylebox("panel", "PopupPanel", _caja(_mezcla(panel, texto, 0.05), borde, radio, 1))
	t.set_stylebox("panel", "PopupMenu", _caja(_mezcla(panel, texto, 0.05), borde, radio, 1))
	t.set_color("font_color", "PopupMenu", texto)
	t.set_color("font_hover_color", "PopupMenu", texto)

	## Los campos de texto. El fondo va al REVÉS que el botón -hacia el fondo, no
	## hacia el texto- porque un cuadro donde se escribe tiene que verse hundido.
	var hueco := _caja(_mezcla(panel, _pal_fondo(), 0.55), borde, radio, 1)
	for clase2: String in ["LineEdit", "TextEdit", "SpinBox"]:
		t.set_stylebox("normal", clase2, hueco)
		t.set_color("font_color", clase2, texto)
		t.set_color("font_placeholder_color", clase2, suave)
		t.set_color("caret_color", clase2, COL_ACENTO)
	t.set_stylebox("focus", "LineEdit", _caja(_mezcla(panel, _pal_fondo(), 0.55), COL_ACENTO, radio, 2))

	## Barras y deslizadores.
	t.set_stylebox("slider", "HSlider", _caja(_mezcla(panel, _pal_fondo(), 0.5), borde, 3, 0))
	t.set_stylebox("grabber_area", "HSlider", _caja(COL_ACENTO, COL_ACENTO, 3, 0))
	t.set_stylebox("grabber_area_highlight", "HSlider", _caja(COL_ACENTO, COL_ACENTO, 3, 0))
	t.set_stylebox("background", "ProgressBar", _caja(_mezcla(panel, _pal_fondo(), 0.5), borde, 3, 0))
	t.set_stylebox("fill", "ProgressBar", _caja(COL_ACENTO, COL_ACENTO, 3, 0))

	t.set_color("default_color", "RichTextLabel", texto)
	t.set_color("font_color", "Label", texto)
	t.set_color("font_color", "ItemList", texto)
	t.set_stylebox("panel", "ItemList", _caja(_mezcla(panel, _pal_fondo(), 0.4), borde, radio, 1))
	t.set_color("font_color", "Tree", texto)
	t.set_stylebox("panel", "Tree", _caja(_mezcla(panel, _pal_fondo(), 0.4), borde, radio, 1))

	## La separación entre filas la sigue mandando la vista compacta: se vuelve a
	## poner aquí porque este `Theme` es el mismo objeto y el orden de llamadas
	## entre las dos funciones no está garantizado.
	var sep := SEPARACION_COMPACTA if _vista_compacta else SEPARACION_NORMAL
	for clase3: String in ["BoxContainer", "VBoxContainer", "HBoxContainer"]:
		t.set_constant("separation", clase3, sep)
	theme = t

## LA VISTA COMPACTA. No es un tema aparte: es el mismo `Theme` con las
## separaciones y los márgenes apretados. Se aplica a la raíz, así que baja por
## todos los contenedores de golpe y no hay que tocar una sola pantalla.
##
## No toca los tamaños de letra a propósito. Encoger la letra hace que quepa más
## y que no se lea nada; lo que sobra en esta interfaz es el aire entre filas.
var _vista_compacta: bool = false

const SEPARACION_NORMAL := 4
const SEPARACION_COMPACTA := 1

func _aplicar_vista_compacta() -> void:
	var sep := SEPARACION_COMPACTA if _vista_compacta else SEPARACION_NORMAL
	var t := theme if theme != null else Theme.new()
	for clase: String in ["BoxContainer", "VBoxContainer", "HBoxContainer"]:
		t.set_constant("separation", clase, sep)
	t.set_constant("margin_top", "MarginContainer", sep)
	t.set_constant("margin_bottom", "MarginContainer", sep)
	theme = t

func _alternar_favorito(tab: String) -> void:
	if _favoritos.has(tab):
		_favoritos.erase(tab)
	elif _favoritos.size() < FAVORITOS_MAX:
		_favoritos.append(tab)
	_refrescar()

func _pintar_ranuras() -> void:
	var t := _texto(11, COL_SUAVE)
	t.text = "RANURAS DE GUARDADO"
	_lista_ajustes.add_child(t)
	var ex := _texto(10, COL_SUAVE)
	ex.text = "Aparte del autoguardado. Sirven para dejar una copia antes de una decisión de la que no se vuelve."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_ajustes.add_child(ex)
	## Se lista una vez y se busca en memoria: `Partida.listar()` abre y lee la
	## cabecera de cada fichero, y llamarlo tres veces sería leer el disco tres
	## veces para pintar tres filas.
	var guardadas := {}
	for f: Dictionary in Partida.listar():
		guardadas[String(f.get("fichero", ""))] = f
	for i in RANURAS.size():
		var nombre := String(RANURAS[i])
		var hay: Dictionary = guardadas.get(nombre, {})
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_lista_ajustes.add_child(fila)
		var et := _texto(12, COL_TEXTO if not hay.is_empty() else COL_SUAVE)
		et.text = "Ranura %d" % (i + 1)
		et.custom_minimum_size = Vector2(70, 0)
		fila.add_child(et)
		var desc := _texto(11, COL_SUAVE)
		desc.text = "%s · %d, semana %d" % [String(hay.get("club", "")), int(hay.get("anio", 0)), int(hay.get("semana", 0))] if not hay.is_empty() else "vacía"
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc.clip_text = true
		fila.add_child(desc)
		var bg := Button.new()
		bg.text = "Guardar"
		bg.add_theme_font_size_override("font_size", 11)
		bg.pressed.connect(func() -> void: _guardar_en(nombre))
		fila.add_child(bg)
		var bc := Button.new()
		bc.text = "Cargar"
		bc.add_theme_font_size_override("font_size", 11)
		bc.disabled = hay.is_empty()
		bc.pressed.connect(func() -> void: _cargar_de(nombre))
		fila.add_child(bc)
	_lista_ajustes.add_child(HSeparator.new())

func _guardar_en(nombre: String) -> void:
	if Partida.guardar(mundo, nombre):
		_escribir("[color=#4caf6d]Guardado en %s.[/color] %s, %d, semana %d." % [
			nombre, mundo.mi_club().nombre, mundo.anio, mundo.semana])
	else:
		_escribir("[color=#e05555]No se pudo guardar en %s.[/color]" % nombre)
	_refrescar()

func _cargar_de(nombre: String) -> void:
	var m := Partida.cargar(nombre)
	if m == null:
		_escribir("[color=#c9a227]Esa ranura está vacía.[/color]")
		return
	mundo = m
	_conectar_noticias()
	_escribir("[color=#4caf6d]Partida cargada de %s.[/color]" % nombre)
	_refrescar()


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

func _color_accesible(c: Color) -> Color:
	if not _daltonico:
		return c
	if c == COL_VERDE:
		return COL_VERDE_DALT
	if c == COL_ROJO:
		return COL_ROJO_DALT
	if c == COL_ORO:
		return COL_ORO_DALT
	return c

## Lo mismo para el registro, que pinta con BBCode y no pasa por `_texto()`.
func _bbcode_accesible(t: String) -> String:
	if not _daltonico:
		return t
	return t.replace("#4caf6d", "#56b4e9").replace("#e05555", "#d55e00").replace("#c9a227", "#e69f00")


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

func _preparar_mando() -> void:
	for par: Array in MANDO_BOTONES:
		var accion := String(par[0])
		if not InputMap.has_action(accion):
			InputMap.add_action(accion)
		var ev := InputEventJoypadButton.new()
		ev.button_index = par[1]
		if not InputMap.action_has_event(accion, ev):
			InputMap.action_add_event(accion, ev)
	## El stick izquierdo, además de la cruceta: en un mando moderno la gente
	## usa el stick y se queda mirando por qué no pasa nada.
	for eje: Array in [["ui_up", JOY_AXIS_LEFT_Y, -1.0], ["ui_down", JOY_AXIS_LEFT_Y, 1.0],
			["ui_left", JOY_AXIS_LEFT_X, -1.0], ["ui_right", JOY_AXIS_LEFT_X, 1.0]]:
		var ev2 := InputEventJoypadMotion.new()
		ev2.axis = eje[1]
		ev2.axis_value = eje[2]
		if not InputMap.action_has_event(String(eje[0]), ev2):
			InputMap.action_add_event(String(eje[0]), ev2)
	for par2: Array in MANDO_PESTANAS:
		var accion2 := String(par2[0])
		if not InputMap.has_action(accion2):
			InputMap.add_action(accion2)
		var eb := InputEventJoypadButton.new()
		eb.button_index = par2[1]
		if not InputMap.action_has_event(accion2, eb):
			InputMap.action_add_event(accion2, eb)
		var et := InputEventKey.new()
		et.keycode = par2[2]
		if not InputMap.action_has_event(accion2, et):
			InputMap.action_add_event(accion2, et)
	for par3: Array in MANDO_BLOQUES:
		var accion3 := String(par3[0])
		if not InputMap.has_action(accion3):
			InputMap.add_action(accion3)
		var ea := InputEventJoypadMotion.new()
		ea.axis = par3[1]
		ea.axis_value = 1.0
		if not InputMap.action_has_event(accion3, ea):
			InputMap.action_add_event(accion3, ea)

func _input(evento: InputEvent) -> void:
	## Los gatillos cambian de pestaña. Se mira aquí y no en `_unhandled_input`
	## porque los contenedores de la interfaz se comen los eventos de navegación
	## antes de que lleguen abajo.
	if evento.is_action_pressed("dinastia_tab_siguiente"):
		_saltar_pestana(1)
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("dinastia_tab_anterior"):
		_saltar_pestana(-1)
		get_viewport().set_input_as_handled()
	## L2/R2 y Ctrl+Q/E cambian de BLOQUE MAESTRO, no de chip: es el nivel de
	## arriba. NO son L1/R1 -esos ya los toma `dinastia_tab_siguiente`/
	## `anterior`, dos líneas más arriba, para el chip- porque un mismo botón
	## físico no puede disparar dos acciones a la vez: con L1/R1 aquí también,
	## esta rama nunca se habría alcanzado (quedó comprobado: era justo el bug
	## que tenía este bloque antes de corregirlo).
	elif evento.is_action_pressed("dinastia_bloque_siguiente"):
		_bloque_vecino(1)
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("dinastia_bloque_anterior"):
		_bloque_vecino(-1)
		get_viewport().set_input_as_handled()
	elif evento is InputEventKey and evento.pressed and not evento.echo:
		var k := evento as InputEventKey
		if k.keycode == KEY_E and k.ctrl_pressed:
			_bloque_vecino(1)
			get_viewport().set_input_as_handled()
		elif k.keycode == KEY_Q and k.ctrl_pressed:
			_bloque_vecino(-1)
			get_viewport().set_input_as_handled()
	## EL ARRASTRE CON EL DEDO (Android). Un desliz horizontal largo pasa de
	## bloque, como en FC26. El umbral de 90 px y el 1,6 de proporción están
	## para que un scroll vertical con el pulgar torcido no cambie de página
	## sin querer: tiene que ser un gesto claramente lateral.
	elif evento is InputEventScreenDrag:
		var dr := evento as InputEventScreenDrag
		_arrastre_x += dr.relative.x
		_arrastre_y += absf(dr.relative.y)
		if absf(_arrastre_x) > 90.0 and absf(_arrastre_x) > _arrastre_y * 1.6:
			_bloque_vecino(-1 if _arrastre_x > 0.0 else 1)
			_arrastre_x = 0.0
			_arrastre_y = 0.0
	elif evento is InputEventScreenTouch and not (evento as InputEventScreenTouch).pressed:
		_arrastre_x = 0.0
		_arrastre_y = 0.0

## Lo acumulado del desliz en curso. Se reinicia al levantar el dedo.
var _arrastre_x: float = 0.0
var _arrastre_y: float = 0.0

## Salta al chip de al lado dentro del bloque actual (los gatillos de
## siempre). Ahora los chips son diccionarios {tab, secc, label}, así que la
## posición se busca comparando pestaña Y sección, no el título a secas.
func _saltar_pestana(d: int) -> void:
	var chips: Array = _grupo_por_id(_grupo_actual).get("tabs", [])
	if chips.is_empty():
		return
	var titulo := _pestanas.get_tab_title(_pestanas.current_tab)
	var i := 0
	for k in chips.size():
		var chip: Dictionary = chips[k]
		if String(chip["tab"]) == titulo and _seccion_activa(chip):
			i = k
			break
	_ir_a_chip(chips[(i + d + chips.size()) % chips.size()])

## EL LÍMITE DE FOTOGRAMAS. En un portátil, dejar el juego a 300 fps calienta la
## máquina para dibujar la misma tabla trescientas veces por segundo. Treinta
## basta para una interfaz; sesenta para el estadio en 3D.
const FPS_OPCIONES := [30, 60, 120, 0]
var _fps_elegido: int = 60

func _pintar_fotogramas() -> void:
	var t := _texto(11, COL_SUAVE)
	t.text = "FOTOGRAMAS POR SEGUNDO"
	_lista_ajustes.add_child(t)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 4)
	_lista_ajustes.add_child(fila)
	for v: int in FPS_OPCIONES:
		var valor := v
		var b := Button.new()
		b.text = "sin límite" if valor == 0 else "%d" % valor
		b.add_theme_font_size_override("font_size", 11)
		b.toggle_mode = true
		b.button_pressed = _fps_elegido == valor
		b.custom_minimum_size = Vector2(72, 0)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			_fps_elegido = valor
			Engine.max_fps = valor
			_refrescar())
		fila.add_child(b)
	if not _modo_experto:
		var ex := _texto(10, COL_SUAVE)
		ex.text = "Bajarlo alarga la batería del portátil y baja la temperatura. Para una interfaz, 30 se ve igual de bien; el estadio en 3D agradece 60."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_ajustes.add_child(ex)

	var fm := _texto(10, COL_SUAVE)
	fm.text = "Mando conectado: %s  ·  cruceta o stick para moverte, A para pulsar, B para volver, gatillos para cambiar de pestaña." % (
		", ".join(Input.get_connected_joypads().map(func(i: int) -> String: return Input.get_joy_name(i)))
		if not Input.get_connected_joypads().is_empty() else "ninguno")
	fm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_ajustes.add_child(fm)
	_lista_ajustes.add_child(HSeparator.new())



# ===========================================================================
#  EL ASPECTO A TU MEDIDA
# ===========================================================================
#
# Nueve paletas, cinco formas de tarjeta, cuatro densidades y el brillo del
# panel. Ninguna toca una sola regla del juego: todo esto es cómo se ve.
#
# POR QUÉ TANTAS OPCIONES. Es una petición directa del usuario -«me gusta
# demasiado lo de poder configurar, de tener muchísimas opciones»- y es
# coherente con lo que ya hace el juego en otros sitios: catorce fondos, ocho
# formas de escudo por diez patrones, doce estampados de camiseta. Un juego de
# gestión se mira dos horas seguidas; que se vea como uno quiere no es un
# capricho, es la diferencia entre aguantarlo y disfrutarlo.
#
# LAS PALETAS NO PISAN EL COLOR DEL CLUB. El acento sigue saliendo de tu
# identidad (`_acento_de()`); lo que cambia aquí es el FONDO, el panel y el
# borde, que es el lienzo sobre el que se pinta ese acento.

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

var _paleta: String = "bosque"
## "Velocidad de partido por defecto" de `vAjustes()`: índice de
## `PartidoVivo.VELOCIDADES` con el que arranca cada partido dirigido en vivo.
## 2 = "Normal", el mismo valor con el que ya arrancaba siempre -así que no
## guardar esto todavía no cambiaba nada, solo faltaba poder elegirlo-.
var _velocidad_partido: int = 2
var _forma_tarjeta: String = "redonda"
var _brillo_tarjetas: bool = true
## El adorno del borde de cada tarjeta. Ver `MarcaPanel`.
var _marca_tarjeta: String = "esquinas"

func _color_pal(i: int, por_defecto: Color) -> Color:
	var p: Array = PALETAS.get(_paleta, [])
	if p.size() <= i:
		return por_defecto
	return Color(String(p[i]))

## Los cuatro colores del lienzo. Se leen a través de estas funciones y no de la
## constante para que cambiar de paleta repinte todo de una vez.
func _pal_fondo() -> Color: return _color_pal(1, COL_FONDO)
## El panel conserva el 0,94 de opacidad de siempre: es lo que deja ver el
## fondo de pantalla por debajo sin que la tabla pierda contraste.
func _pal_panel() -> Color:
	var c := _color_pal(2, COL_PANEL)
	c.a = 0.94
	return c
func _pal_borde() -> Color: return _color_pal(3, COL_BORDE)
func _pal_texto() -> Color: return _color_pal(4, COL_TEXTO)
func _pal_suave() -> Color: return _color_pal(5, COL_SUAVE)

## EL CLIMA. Diez, y ninguno es un fondo: son una capa de partículas que va
## por encima del dibujo, así que cualquiera de los veinticuatro fondos puede
## tener lluvia o confeti sin dibujar doscientos cuarenta fondos.
func _pintar_clima() -> void:
	var lc := _texto(10, COL_SUAVE)
	lc.text = "Clima encima del fondo"
	_lista_ajustes.add_child(lc)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 4)
	_lista_ajustes.add_child(flow)
	for k: String in FondoAnimado.MODOS:
		var clave := k
		var b := Button.new()
		b.text = String(FondoAnimado.MODOS[k])
		b.add_theme_font_size_override("font_size", 10)
		b.toggle_mode = true
		b.button_pressed = _clima_elegido == clave
		b.clip_text = true
		b.custom_minimum_size = Vector2(118, 24)
		b.pressed.connect(func() -> void:
			_clima_elegido = clave
			_aplicar_fondo()
			_refrescar())
		flow.add_child(b)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	_lista_ajustes.add_child(fila)
	var et := _texto(12, COL_TEXTO)
	et.text = "El clima sigue al ratón"
	et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et.tooltip_text = "El cursor inclina el viento: la lluvia se tuerce hacia donde miras y el confeti se va detrás. Apagado, cae recto."
	fila.add_child(et)
	var b2 := Button.new()
	b2.text = "SÍ" if _clima_interactivo else "NO"
	b2.pressed.connect(func() -> void:
		_clima_interactivo = not _clima_interactivo
		_aplicar_fondo()
		_refrescar())
	fila.add_child(b2)

func _pintar_aspecto() -> void:
	var t := _texto(11, COL_SUAVE)
	t.text = "🎨 ASPECTO DE LA INTERFAZ"
	_lista_ajustes.add_child(t)
	if not _modo_experto:
		var ex := _texto(10, COL_SUAVE)
		ex.text = "Nada de esto cambia una sola regla del juego. El color de acento sigue saliendo de la identidad de tu club: lo que se elige aquí es el lienzo."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_ajustes.add_child(ex)

	var lp := _texto(10, COL_SUAVE)
	lp.text = "Paleta"
	_lista_ajustes.add_child(lp)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 4)
	_lista_ajustes.add_child(flow)
	for k: String in PALETAS:
		var clave := k
		var datos: Array = PALETAS[k]
		var b := Button.new()
		b.text = String(datos[0])
		b.add_theme_font_size_override("font_size", 10)
		b.toggle_mode = true
		b.button_pressed = _paleta == clave
		b.clip_text = true
		b.custom_minimum_size = Vector2(104, 24)
		## El botón se pinta con SU paleta: se elige mirando, no leyendo.
		var muestra := StyleBoxFlat.new()
		muestra.bg_color = Color(String(datos[2]))
		muestra.border_color = Color(String(datos[3]))
		muestra.set_border_width_all(1)
		muestra.set_corner_radius_all(4)
		b.add_theme_stylebox_override("normal", muestra)
		b.add_theme_color_override("font_color", Color(String(datos[4])))
		b.pressed.connect(func() -> void:
			_paleta = clave
			_aplicar_aspecto()
			_refrescar())
		flow.add_child(b)

	var lf := _texto(10, COL_SUAVE)
	lf.text = "Forma de las tarjetas"
	_lista_ajustes.add_child(lf)
	var flow2 := HFlowContainer.new()
	flow2.add_theme_constant_override("h_separation", 4)
	_lista_ajustes.add_child(flow2)
	for k2: String in FORMAS_TARJETA:
		var clave2 := k2
		var b2 := Button.new()
		b2.text = String((FORMAS_TARJETA[k2] as Array)[0])
		b2.add_theme_font_size_override("font_size", 10)
		b2.toggle_mode = true
		b2.button_pressed = _forma_tarjeta == clave2
		b2.clip_text = true
		b2.custom_minimum_size = Vector2(96, 24)
		b2.pressed.connect(func() -> void:
			_forma_tarjeta = clave2
			## La forma tambien manda en el radio de los botones y las pestanas, que
			## viven en el tema y no se rehacen al repintar.
			_aplicar_aspecto()
			_refrescar())
		flow2.add_child(b2)

	_pintar_tipografia()
	var lm := _texto(10, COL_SUAVE)
	lm.text = "Marca de las tarjetas"
	_lista_ajustes.add_child(lm)
	var flow3 := HFlowContainer.new()
	flow3.add_theme_constant_override("h_separation", 4)
	flow3.add_theme_constant_override("v_separation", 4)
	_lista_ajustes.add_child(flow3)
	for k3: String in MarcaPanel.ESTILOS:
		var clave3 := k3
		var b3 := Button.new()
		b3.text = String(MarcaPanel.ESTILOS[k3])
		b3.add_theme_font_size_override("font_size", 10)
		b3.toggle_mode = true
		b3.button_pressed = _marca_tarjeta == clave3
		b3.clip_text = true
		b3.custom_minimum_size = Vector2(130, 24)
		b3.pressed.connect(func() -> void:
			_marca_tarjeta = clave3
			_aplicar_aspecto()
			_refrescar())
		flow3.add_child(b3)

	var fila_b := HBoxContainer.new()
	fila_b.add_theme_constant_override("separation", 8)
	_lista_ajustes.add_child(fila_b)
	var et_b := _texto(12, COL_TEXTO)
	et_b.text = "Brillo en las tarjetas"
	et_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et_b.tooltip_text = "El degradado cenital que le da aire de placa metálica. Sin él, las tarjetas son rectángulos planos."
	fila_b.add_child(et_b)
	var b_b := Button.new()
	b_b.text = "SÍ" if _brillo_tarjetas else "NO"
	b_b.pressed.connect(func() -> void:
		_brillo_tarjetas = not _brillo_tarjetas
		_aplicar_aspecto()
		_refrescar())
	fila_b.add_child(b_b)
	_lista_ajustes.add_child(HSeparator.new())

## Repinta el lienzo. Solo hace falta al cambiar de paleta: el resto se aplica
## solo al reconstruir las pantallas.
func _aplicar_aspecto() -> void:
	if _fondo_raiz != null:
		_fondo_raiz.color = _pal_fondo()
	_aplicar_tema()
	_repintar_tarjetas(self)

## Recorre la pantalla y le da a cada tarjeta el color y la forma de la paleta
## nueva. Tambien enciende o apaga su brillo: es el hijo `TextureRect` que le
## cuelga `_panel()`, y se oculta en vez de borrarlo para que volver a encender
## el brillo no exija reconstruir nada.
func _repintar_tarjetas(n: Node) -> void:
	if n is PanelContainer and n.has_meta("tarjeta"):
		var p := n as PanelContainer
		var e := StyleBoxFlat.new()
		e.bg_color = _pal_panel()
		e.border_color = _pal_borde()
		var forma: Array = FORMAS_TARJETA.get(_forma_tarjeta, ["", 8, 1])
		e.set_border_width_all(int(forma[2]))
		e.set_corner_radius_all(int(forma[1]))
		p.add_theme_stylebox_override("panel", e)
		var tiene_marca := false
		for h in p.get_children():
			if h is TextureRect and (h as TextureRect).texture == _brillo_panel:
				(h as TextureRect).visible = _brillo_tarjetas
			elif h is MarcaPanel:
				(h as MarcaPanel).poner(_marca_tarjeta, COL_ACENTO)
				tiene_marca = true
		## Una tarjeta creada cuando la marca estaba en «ninguno» no tiene el nodo:
		## se le cuelga ahora, o encender las escuadras solo valdria para lo que se
		## pintara despues.
		if not tiene_marca and _marca_tarjeta != "ninguno":
			var mk2 := MarcaPanel.new()
			mk2.poner(_marca_tarjeta, COL_ACENTO)
			p.add_child(mk2)
	for h2 in n.get_children():
		_repintar_tarjetas(h2)

func _pintar_accesibilidad() -> void:
	var t := _texto(11, COL_SUAVE)
	t.text = "ACCESIBILIDAD"
	_lista_ajustes.add_child(t)

	var fila_tx := HBoxContainer.new()
	fila_tx.add_theme_constant_override("separation", 6)
	_lista_ajustes.add_child(fila_tx)
	var et_tx := _texto(12, COL_TEXTO)
	et_tx.text = "Tamaño del texto"
	et_tx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila_tx.add_child(et_tx)
	for e: float in ESCALAS_TEXTO:
		var esc := e
		var b := Button.new()
		b.text = "%d%%" % int(round(esc * 100.0))
		b.add_theme_font_size_override("font_size", 11)
		b.toggle_mode = true
		b.button_pressed = is_equal_approx(_escala_texto, esc)
		b.custom_minimum_size = Vector2(52, 0)
		b.pressed.connect(func() -> void:
			_escala_texto = esc
			_refrescar())
		fila_tx.add_child(b)

	var fila_d := HBoxContainer.new()
	fila_d.add_theme_constant_override("separation", 8)
	_lista_ajustes.add_child(fila_d)
	var et_d := _texto(12, COL_TEXTO)
	et_d.text = "Paleta para daltonismo"
	et_d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et_d.tooltip_text = "El verde y el rojo del juego pasan a azul cielo y bermellón, que se distinguen con cualquier daltonismo."
	fila_d.add_child(et_d)
	var b_d := Button.new()
	b_d.text = "SÍ" if _daltonico else "NO"
	b_d.pressed.connect(func() -> void:
		_daltonico = not _daltonico
		_refrescar())
	fila_d.add_child(b_d)

	## EL MERCADO A CIEGAS. `Ojeadores.modo_ciego` estaba escrito, probado, con
	## su escala de palabras y hasta con una captura de pantalla propia en las
	## pruebas —y no había un solo botón para encenderlo en toda la interfaz.
	if mundo.ojeadores != null:
		var fila_c := HBoxContainer.new()
		fila_c.add_theme_constant_override("separation", 8)
		_lista_ajustes.add_child(fila_c)
		var et_c := _texto(12, COL_TEXTO)
		et_c.text = "Mercado a ciegas"
		et_c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		et_c.tooltip_text = "Sin medias numéricas de los rivales: solo palabras («crack», «bueno», «del montón») hasta que los ojees a fondo."
		fila_c.add_child(et_c)
		var b_c := Button.new()
		b_c.text = "SÍ" if mundo.ojeadores.modo_ciego else "NO"
		b_c.pressed.connect(func() -> void:
			mundo.ojeadores.modo_ciego = not mundo.ojeadores.modo_ciego
			_refrescar())
		fila_c.add_child(b_c)
		if not _modo_experto:
			var ec := _texto(10, COL_SUAVE)
			ec.text = "Con esto encendido, la media de un jugador ajeno no es un número hasta que un ojeador lo mira tres veces. Cambia por completo cómo se ficha."
			ec.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_lista_ajustes.add_child(ec)
	_lista_ajustes.add_child(HSeparator.new())

## SACAR Y METER LA PARTIDA. El HTML pegaba el guardado en un `<textarea>` porque
## el navegador no le dejaba tocar el disco. Aquí sí se puede, así que se hacen
## las dos cosas: se escribe un archivo suelto en una carpeta que se puede abrir
## y se copia el mismo contenido al portapapeles, que es lo que hace falta para
## mandárselo a alguien por chat.
const FICHERO_EXPORTADO := "user://dinastia-exportada.txt"

func _pintar_traspaso_partida() -> void:
	var t := _texto(11, COL_SUAVE)
	t.text = "SACAR Y METER LA PARTIDA"
	_lista_ajustes.add_child(t)
	var ex := _texto(10, COL_SUAVE)
	ex.text = "Exportar deja la partida en un archivo de texto y la copia al portapapeles. Importar lee lo que tengas copiado. Sirve para llevártela a otro ordenador o para guardarla fuera del juego."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_ajustes.add_child(ex)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	_lista_ajustes.add_child(fila)
	var be := Button.new()
	be.text = "Exportar"
	be.add_theme_font_size_override("font_size", 11)
	be.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	be.pressed.connect(func() -> void: _exportar_partida())
	fila.add_child(be)
	var bi := Button.new()
	bi.text = "Importar lo copiado"
	bi.add_theme_font_size_override("font_size", 11)
	bi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bi.pressed.connect(func() -> void: _importar_partida())
	fila.add_child(bi)
	_lista_ajustes.add_child(HSeparator.new())

func _exportar_partida() -> void:
	## Se exporta el retrato en base64 y no el JSON en claro: el JSON de una
	## partida son varios megabytes de texto que ningún chat deja pegar de una
	## pieza, y comprimido cabe. Es el mismo formato del guardado en disco.
	var datos := Partida.instantanea(mundo)
	var crudo := JSON.stringify(datos).to_utf8_buffer()
	var comprimido := crudo.compress(FileAccess.COMPRESSION_DEFLATE)
	var cabecera := PackedByteArray()
	cabecera.resize(4)
	cabecera.encode_u32(0, crudo.size())
	var texto := Marshalls.raw_to_base64(cabecera + comprimido)
	var f := FileAccess.open(FICHERO_EXPORTADO, FileAccess.WRITE)
	if f != null:
		f.store_string(texto)
		f.close()
	DisplayServer.clipboard_set(texto)
	_escribir("[color=#4caf6d]Partida exportada.[/color] Copiada al portapapeles y escrita en %s (%d KB de texto)." % [
		ProjectSettings.globalize_path(FICHERO_EXPORTADO), texto.length() / 1024])

func _importar_partida() -> void:
	var texto := DisplayServer.clipboard_get().strip_edges()
	if texto.length() < 32:
		_escribir("[color=#e05555]No hay ninguna partida en el portapapeles.[/color] Copia primero el texto exportado.")
		return
	var bruto := Marshalls.base64_to_raw(texto)
	if bruto.size() < 8:
		_escribir("[color=#e05555]Lo copiado no es una partida de DINASTÍA.[/color]")
		return
	var tamano := bruto.decode_u32(0)
	var cuerpo_b := bruto.slice(4)
	var crudo := cuerpo_b.decompress(tamano, FileAccess.COMPRESSION_DEFLATE)
	if crudo.is_empty():
		_escribir("[color=#e05555]La partida copiada está incompleta o dañada.[/color]")
		return
	var leido: Variant = JSON.parse_string(crudo.get_string_from_utf8())
	if not (leido is Dictionary):
		_escribir("[color=#e05555]La partida copiada no se entiende.[/color]")
		return
	var m := Partida.desde_instantanea(leido as Dictionary)
	if m == null:
		_escribir("[color=#e05555]No se pudo abrir la partida copiada.[/color]")
		return
	mundo = m
	_conectar_noticias()
	_seleccionado = null
	_pila_deshacer.clear()
	_llenar_selector()
	_escribir("[color=#3fa06a]Partida importada:[/color] %s, %d, semana %d." % [
		mundo.mi_club().nombre, mundo.anio, mundo.semana])
	_refrescar()

## LAS SECCIONES DE AJUSTES. La pantalla llegó a medir 1.700 px de alto: para
## llegar al tamaño de letra había que bajar por delante del mezclador, de los
## veinticuatro fondos, de los diez climas y de las nueve paletas.
##
## No se quita ni una opción —son justo lo que hace falta que haya— pero se
## reparten en seis grupos y solo se pinta el que estás mirando. De paso se
## pinta seis veces menos en cada refresco.
const SECCIONES_AJUSTES := [
	["audio", "🔊 Sonido y música"],
	["aspecto", "🎨 Aspecto"],
	["pantalla", "🖥 Pantalla"],
	["juego", "🎮 Juego"],
	["acceso", "♿ Accesibilidad"],
	["partida", "💾 Partida"],
]

var _secc_ajustes: String = "audio"

func _pintar_ajustes() -> void:
	_limpiar(_lista_ajustes)
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 4)
	chips.add_theme_constant_override("v_separation", 4)
	_lista_ajustes.add_child(chips)
	for s: Array in SECCIONES_AJUSTES:
		var clave := String(s[0])
		var b := Button.new()
		b.text = String(s[1])
		b.add_theme_font_size_override("font_size", 11)
		b.toggle_mode = true
		b.button_pressed = _secc_ajustes == clave
		b.clip_text = true
		b.custom_minimum_size = Vector2(126, 26)
		b.pressed.connect(func() -> void:
			_secc_ajustes = clave
			_pintar_ajustes())
		chips.add_child(b)
	_lista_ajustes.add_child(HSeparator.new())

	match _secc_ajustes:
		"audio":
			var t1 := _texto(11, COL_SUAVE)
			t1.text = "SONIDO"
			_lista_ajustes.add_child(t1)
			var fila1 := HBoxContainer.new()
			_lista_ajustes.add_child(fila1)
			var et1 := _texto(13, COL_TEXTO)
			et1.text = "Sonidos del partido"
			et1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila1.add_child(et1)
			var b1 := Button.new()
			b1.text = "SÍ" if Sonido.encendido else "NO"
			b1.pressed.connect(func() -> void:
				Sonido.encendido = not Sonido.encendido
				_refrescar())
			fila1.add_child(b1)
			_pintar_mezclador()
			_pintar_musica()
		"aspecto":
			## El tutorial se repite desde aquí: la última tarjeta del propio
			## recorrido lo promete ("AJUSTES → Interfaz").
			var tut := Button.new()
			tut.text = "📖 Repetir el tutorial"
			tut.custom_minimum_size = Vector2(0, 32)
			tut.pressed.connect(func() -> void: abrir_tutorial())
			_lista_ajustes.add_child(tut)
			_lista_ajustes.add_child(HSeparator.new())
			_pintar_fondos_ajustes()
			_pintar_clima()
			_lista_ajustes.add_child(HSeparator.new())
			_pintar_aspecto()
		"pantalla":
			_pintar_fotogramas()
			_pintar_dispositivo()
			_pintar_atajos()
		"juego":
			_pintar_idioma()
			_pintar_moneda()
			_pintar_velocidad_partido()
			_pintar_qol()
		"acceso":
			_pintar_accesibilidad()
		"partida":
			_pintar_ranuras()
			_pintar_traspaso_partida()
			var t2 := _texto(11, COL_SUAVE)
			t2.text = "GUARDADO"
			_lista_ajustes.add_child(t2)
			var fila2 := HBoxContainer.new()
			_lista_ajustes.add_child(fila2)
			var et2 := _texto(13, COL_TEXTO)
			et2.text = "Autoguardado"
			et2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila2.add_child(et2)
			var b2 := Button.new()
			b2.text = "SÍ" if _autoguardado else "NO"
			b2.pressed.connect(func() -> void:
				_autoguardado = not _autoguardado
				_refrescar())
			fila2.add_child(b2)
			var ex2 := _texto(11, COL_SUAVE)
			ex2.text = "Guarda solo al avanzar cada semana o cerrar temporada, en la misma ranura de \"Guardar\"."
			ex2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_lista_ajustes.add_child(ex2)
			_lista_ajustes.add_child(HSeparator.new())
			var t3 := _texto(11, COL_SUAVE)
			t3.text = "ACERCA DE"
			_lista_ajustes.add_child(t3)
			var ac := _texto(11, COL_SUAVE)
			ac.text = "DINASTÍA Fútbol Manager · motor Godot. Los nombres de clubes y futbolistas generados usan sustitución letra→número; los datos reales que sí tienen nombre e imagen vienen de fuentes con licencia libre. La música y todos los efectos están sintetizados por el propio juego: no hay ni un fichero de audio."
			ac.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_lista_ajustes.add_child(ac)

	## Esta pantalla se repinta sola al tocar una pestaña de sección, sin pasar
	## por `_refrescar()`, asi que se traduce aqui tambien.
	_traducir_pantalla(_lista_ajustes)
	## Cada cambio de esta pantalla vuelve a pintarla; guardar aqui recoge los
	## ajustes sin tener que colgar un guardado de cada boton.
	_guardar_preferencias()

## El selector de los veinticuatro fondos. Estaba suelto dentro de
## `_pintar_ajustes()`; sale a su función para que la sección de aspecto se lea.
func _pintar_fondos_ajustes() -> void:
	var tf := _texto(11, COL_SUAVE)
	tf.text = "FONDO DE PANTALLA"
	_lista_ajustes.add_child(tf)
	var ef := _texto(10, COL_SUAVE)
	ef.text = "Va detrás de la interfaz. Los paneles siguen siendo opacos: un fondo que deja la tabla ilegible es un fondo malo."
	ef.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_ajustes.add_child(ef)
	var op := OptionButton.new()
	op.add_theme_font_size_override("font_size", 11)
	op.clip_text = true
	## Sin esto el desplegable pide el ancho de su entrada más larga -386 px- y
	## empuja la raíz fuera de la ventana. Trampa ya pagada en este proyecto.
	op.fit_to_longest_item = false
	## EL ESTILO DEL MENÚ, arriba del fondo: es lo que más cambia la cara del
	## juego de un vistazo.
	var te := _texto(11, COL_SUAVE)
	te.text = "ESTILO DEL MENÚ"
	_lista_ajustes.add_child(te)
	var fila_estilo := HFlowContainer.new()
	fila_estilo.add_theme_constant_override("h_separation", 4)
	_lista_ajustes.add_child(fila_estilo)
	for e: Array in ESTILOS_MENU:
		var clave := String(e[0])
		var be := Button.new()
		be.text = String(e[1])
		be.add_theme_font_size_override("font_size", 11)
		be.toggle_mode = true
		be.button_pressed = _estilo_menu == clave
		be.custom_minimum_size = Vector2(160, 26)
		be.pressed.connect(func() -> void:
			_estilo_menu = clave
			_reconstruir_grupos()
			_guardar_preferencias()
			_pintar_ajustes())
		fila_estilo.add_child(be)
	_lista_ajustes.add_child(HSeparator.new())

	op.add_item("Sin fondo (verde plano)", 0)
	## La segunda entrada es la rotación: fijo o "que vaya cambiando", que es
	## como lo pidió el usuario. Va arriba del todo, antes de los 24 fondos,
	## porque es una decisión distinta -no es "cuál", es "uno o todos"-.
	op.add_item("🔀 Ir cambiando cada semana", 1)
	var elegido := 0
	if _fondo_elegido == ROTAR_FONDO:
		elegido = 1
	for i in Fondo.NOMBRES.size():
		var k := String(Fondo.NOMBRES[i])
		op.add_item(String(Fondo.TITULOS.get(k, k)), i + 2)
		if k == _fondo_elegido:
			elegido = i + 2
	op.selected = elegido
	op.item_selected.connect(func(idx: int) -> void:
		if idx == 0:
			_fondo_elegido = ""
		elif idx == 1:
			_fondo_elegido = ROTAR_FONDO
		else:
			_fondo_elegido = String(Fondo.NOMBRES[idx - 2])
		_aplicar_fondo())
	_lista_ajustes.add_child(op)
## `vCorreo()` del HTML: bandeja filtrable sobre `G.noticias`. Aquí lee
## `_bandeja`, que `_anotar()` llena en paralelo a cada `_escribir()` de
## `_conectar_noticias()` -ver el comentario de esa función-. Tocar una fila
## la marca leída, igual que el HTML.
## `vSocial()`: el termómetro de redes y el gabinete de comunicación.
##
## `funa` y `animo` ya se movían solos desde el porte y no había dónde verlos
## juntos ni nada que hacer al respecto. Lo que se añade no es un número más:
## son las tres respuestas del gabinete, que son una decisión de las buenas —no
## hay opción correcta, y contestar puede apagar el fuego o doblarlo.
## `vGente()`: las diez personas del club. No mueve ninguna estadística del
## partido y ese es el punto: es lo que hace que el club sea un SITIO y no una
## hoja de cálculo con escudo.
##
## Tres charlas por semana y no diez: si se pudiera hablar con todos, dejaría de
## ser una elección y sería una ronda de clics. Y los efectos son pequeños a
## propósito —por debajo de 60 de confianza no dan nada—, porque el día que
## hablar con el utilero suba dos puntos de media esto se convierte en otra
## pestaña que hay que exprimir cada lunes.
## `vClubIn()`: el club por dentro. Tres espacios que se compran y dos cosas
## digitales. Cada uno pega en un sitio distinto —moral, funa, patrocinio— y esa
## es la razón de que exista la pantalla: cuando no llega para los tres, hay que
## decidir qué clase de club quieres ser.
## `vIdentidad()`: los colores del club. Es el cambio más pequeño del juego y el
## que más se ve: `Club.color1` tiñe el escudo, la equipación del visor 3D y el
## COLOR DE ACENTO de toda la interfaz (`_acento_de()`), así que tocarlo aquí
## repinta el juego entero.
##
## Hasta ahora los colores existían y no se guardaban: cambiarlos duraba hasta
## cerrar. Ya van en la partida.
## `vIdentidad()`: LAS CUATRO CAPAS. Club, uniforme, escudo e interfaz, cada una
## por su lado.
##
## Antes esto eran dos selectores de color y ya. El HTML separa cuatro capas a
## propósito: el uniforme no arrastra el color del menú ni el del escudo, y lo
## que no tocas lo hereda del club. Esa herencia es lo que hace que un equipo
## recién tomado ya se vea suyo sin elegir nada, y lo que hace que el botón de
## "volver a los colores del club" signifique algo.
# ---------------------------------------------------------------------------
#  LAS PREFERENCIAS SE QUEDAN
# ---------------------------------------------------------------------------
#
# Doce ajustes de interfaz -paleta, forma de tarjeta, brillo, fondo, tamano de
# letra, zoom, modo TV, modo experto, daltonismo, FPS- vivian solo en memoria:
# los elegias, y al cerrar el juego volvia todo a como estaba. Con una sola
# opcion eso se aguanta; con doce es una pelea cada vez que abres.
#
# NO VAN EN LA PARTIDA, van en un archivo aparte. Son tuyos, no de tu club: si
# te gusta la paleta de cuaderno te gusta en todas tus carreras, y una partida
# que viaja a otro ordenador no tiene por que llevarse el tamano de letra de
# nadie.
const PREFS := "user://preferencias.cfg"

## La firma de lo guardado la ultima vez. Esta pantalla se repinta en CADA
## refresco del juego -no solo al tocar un ajuste-, asi que sin esto se escribiria
## el archivo en cada clic sin que hubiera cambiado nada.
var _firma_prefs: String = ""

func _guardar_preferencias() -> void:
	var firma := "%s|%s|%s|%s|%.2f|%s|%.2f|%s|%d|%s|%s|%s|%s|%s|%s|%s|%s|%.2f|%s|%s|%s|%d" % [_paleta, _forma_tarjeta,
		_brillo_tarjetas, _fondo_elegido, _escala_texto, _daltonico, _zoom_interfaz,
		_modo_tv, _fps_elegido, _modo_experto, Sonido.encendido, _clima_elegido,
		_clima_interactivo, _marca_tarjeta, _tipografia, Idiomas.idioma,
		Musica.encendida, Musica.volumen, Musica.pieza, Musica.automatica, _estilo_menu,
		_velocidad_partido]
	if firma == _firma_prefs:
		return
	_firma_prefs = firma
	var cf := ConfigFile.new()
	cf.set_value("aspecto", "paleta", _paleta)
	cf.set_value("aspecto", "forma_tarjeta", _forma_tarjeta)
	cf.set_value("aspecto", "brillo_tarjetas", _brillo_tarjetas)
	cf.set_value("aspecto", "fondo", _fondo_elegido)
	cf.set_value("aspecto", "clima", _clima_elegido)
	cf.set_value("aspecto", "marca_tarjeta", _marca_tarjeta)
	cf.set_value("aspecto", "tipografia", _tipografia)
	cf.set_value("aspecto", "estilo_menu", _estilo_menu)
	cf.set_value("juego", "idioma", Idiomas.idioma)
	cf.set_value("juego", "velocidad_partido", _velocidad_partido)
	cf.set_value("musica", "encendida", Musica.encendida)
	cf.set_value("musica", "volumen", Musica.volumen)
	cf.set_value("musica", "pieza", Musica.pieza)
	cf.set_value("musica", "automatica", Musica.automatica)
	cf.set_value("aspecto", "clima_interactivo", _clima_interactivo)
	cf.set_value("texto", "escala", _escala_texto)
	cf.set_value("texto", "daltonico", _daltonico)
	cf.set_value("pantalla", "zoom", _zoom_interfaz)
	cf.set_value("pantalla", "modo_tv", _modo_tv)
	cf.set_value("pantalla", "ropa_aparte", VestidorQ.ropa_aparte)
	cf.set_value("pantalla", "fps", _fps_elegido)
	cf.set_value("juego", "modo_experto", _modo_experto)
	cf.set_value("sonido", "encendido", Sonido.encendido)
	cf.save(PREFS)

func _cargar_preferencias() -> void:
	var cf := ConfigFile.new()
	if cf.load(PREFS) != OK:
		return
	## Cada lectura se valida contra lo que existe HOY. Un archivo de una version
	## vieja puede nombrar una paleta que ya no esta, y quedarse sin colores por
	## eso seria peor que ignorar la linea.
	var p := String(cf.get_value("aspecto", "paleta", _paleta))
	if PALETAS.has(p):
		_paleta = p
	var f := String(cf.get_value("aspecto", "forma_tarjeta", _forma_tarjeta))
	if FORMAS_TARJETA.has(f):
		_forma_tarjeta = f
	_brillo_tarjetas = bool(cf.get_value("aspecto", "brillo_tarjetas", _brillo_tarjetas))
	var fo := String(cf.get_value("aspecto", "fondo", _fondo_elegido))
	## `ROTAR_FONDO` no está en `Fondo.NOMBRES` -es un valor especial, no un
	## fondo-, así que hay que dejarlo pasar aparte o al reabrir el juego se
	## perdería la rotación y volvería a uno fijo.
	if fo == "" or fo == ROTAR_FONDO or Fondo.NOMBRES.has(fo):
		_fondo_elegido = fo
	var em := String(cf.get_value("aspecto", "estilo_menu", _estilo_menu))
	for e: Array in ESTILOS_MENU:
		if String(e[0]) == em:
			_estilo_menu = em
	var cl := String(cf.get_value("aspecto", "clima", _clima_elegido))
	if FondoAnimado.MODOS.has(cl):
		_clima_elegido = cl
	_clima_interactivo = bool(cf.get_value("aspecto", "clima_interactivo", _clima_interactivo))
	var mt := String(cf.get_value("aspecto", "marca_tarjeta", _marca_tarjeta))
	if MarcaPanel.ESTILOS.has(mt):
		_marca_tarjeta = mt
	var tp := String(cf.get_value("aspecto", "tipografia", _tipografia))
	if TIPOGRAFIAS.has(tp):
		_tipografia = tp
	var idi := String(cf.get_value("juego", "idioma", Idiomas.idioma))
	if idi == "es" or Idiomas.NOMBRES.has(idi):
		Idiomas.idioma = idi
	_velocidad_partido = clampi(int(cf.get_value("juego", "velocidad_partido", _velocidad_partido)), 1, 3)
	Musica.encendida = bool(cf.get_value("musica", "encendida", Musica.encendida))
	Musica.volumen = clampf(float(cf.get_value("musica", "volumen", Musica.volumen)), 0.0, 1.0)
	var mp := String(cf.get_value("musica", "pieza", Musica.pieza))
	if mp == "" or Musica.PIEZAS.has(mp):
		Musica.pieza = mp
	Musica.automatica = bool(cf.get_value("musica", "automatica", Musica.automatica))
	_escala_texto = clampf(float(cf.get_value("texto", "escala", _escala_texto)), 0.7, 1.6)
	_daltonico = bool(cf.get_value("texto", "daltonico", _daltonico))
	_zoom_interfaz = clampf(float(cf.get_value("pantalla", "zoom", _zoom_interfaz)), 0.7, 1.6)
	_modo_tv = bool(cf.get_value("pantalla", "modo_tv", _modo_tv))
	VestidorQ.ropa_aparte = bool(cf.get_value("pantalla", "ropa_aparte", VestidorQ.ropa_aparte))
	_fps_elegido = clampi(int(cf.get_value("pantalla", "fps", _fps_elegido)), 30, 240)
	_modo_experto = bool(cf.get_value("juego", "modo_experto", _modo_experto))
	Sonido.encendido = bool(cf.get_value("sonido", "encendido", Sonido.encendido))

func _pintar_identidad(c: Club) -> void:

	## EL DISEÑADOR DE EQUIPACIÓN (26-9-2026): 70 diseños, 5 colores, pantalón,
	## medias, 30 botines, accesorios y color de números, con vista 3D.
	var bd := Button.new()
	bd.text = "🎽  Abrir el diseñador de equipación"
	bd.custom_minimum_size = Vector2(0, 44)
	bd.add_theme_font_size_override("font_size", 16)
	bd.pressed.connect(func() -> void:
		var dz := DisenadorKit.abrir(self, mundo)
		dz.cerrado.connect(_refrescar))
	_lista_gente.add_child(bd)
	_lista_gente.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "🎨 IDENTIDAD VISUAL"
	_lista_gente.add_child(t)
	if not _modo_experto:
		var ex := _texto(10, COL_SUAVE)
		ex.text = "Cada cosa se pinta por separado: el uniforme no arrastra el color del menú ni el del escudo. Lo que no toques, lo hereda del club."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_gente.add_child(ex)

	## LA VISTA PREVIA. Escudo y camiseta juntos, con lo que hay puesto ahora
	## mismo: sin esto hay que salir de la pantalla para ver si acertaste.
	var previa := HBoxContainer.new()
	previa.add_theme_constant_override("separation", 14)
	previa.alignment = BoxContainer.ALIGNMENT_CENTER
	_lista_gente.add_child(previa)
	var esc_img := TextureRect.new()
	esc_img.texture = Escudo.textura(c, 54)
	esc_img.custom_minimum_size = Vector2(54, 54)
	## SIN ESTO EL ESCUDO SALÍA GIGANTE. `Escudo.textura()` rasteriza a 4x -para
	## que las curvas no salgan dentadas al escalar, ver su propio comentario-,
	## así que la textura real mide unos 220 px de lado aunque se pidan 54. Sin
	## `expand_mode = EXPAND_IGNORE_SIZE` -el que SÍ lleva el resto de usos de
	## `Escudo.textura()` en este mismo archivo, por ejemplo `_escudo()`-, el
	## `TextureRect` reporta como tamaño mínimo el de la textura real, no el de
	## `custom_minimum_size`, y esa fila entera se inflaba a esa altura -se
	## llevaba con ella el color de acento de al lado, que salía como un
	## rectángulo blanco altísimo por simple herencia de la altura de la fila-.
	esc_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	esc_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	previa.add_child(esc_img)
	var kit_img := TextureRect.new()
	kit_img.texture = Jersey.textura_procedural(c.color_kit1(), c.color_kit2(),
		Jersey.kit_de(c, c.kit_estilo), 58)
	kit_img.custom_minimum_size = Vector2(58, 58)
	kit_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	kit_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	previa.add_child(kit_img)
	var muestra_ui := ColorRect.new()
	muestra_ui.color = _acento_de(c)
	muestra_ui.custom_minimum_size = Vector2(46, 46)
	previa.add_child(muestra_ui)

	_fila_color_identidad(c, "1 · Color principal del club", "color1")
	_fila_color_identidad(c, "1 · Color secundario del club", "color2")

	var tk := _texto(11, COL_ACENTO)
	tk.text = "2 · UNIFORME%s" % ("" if c.kit_color1 == "" and c.kit_color2 == "" else "  ·  propio")
	_lista_gente.add_child(tk)
	_fila_color_identidad(c, "Color 1 de la camiseta", "kit_color1")
	_fila_color_identidad(c, "Color 2 de la camiseta", "kit_color2")
	_rejilla_identidad(c, "kit_estilo", Jersey.KITS, "Diseño")
	_boton_heredar(c, ["kit_color1", "kit_color2"], "Volver a los colores del club")

	var te := _texto(11, COL_ACENTO)
	te.text = "3 · ESCUDO%s" % ("" if c.esc_color1 == "" and c.esc_color2 == "" else "  ·  propio")
	_lista_gente.add_child(te)
	_fila_color_identidad(c, "Fondo del escudo", "esc_color1")
	_fila_color_identidad(c, "Borde y patrón", "esc_color2")
	_rejilla_identidad(c, "esc_forma", Escudo.FORMAS, "Forma")
	_rejilla_identidad(c, "esc_patron", Escudo.PATRONES, "Patrón interior")
	## "ESC_SIM" del HTML: un emoji en vez de las iniciales. El campo llevaba
	## semanas guardándose -`Club.esc_simbolo` ya viaja en el guardado- sin que
	## `Escudo` lo leyera ni hubiera dónde elegirlo. `Datos.tabla("ESC_SIM")`
	## trae un "" propio en el índice 0 -el mismo "por sorteo" que ya antepone
	## `_rejilla_identidad`-, así que se recorta para no duplicar ese botón.
	var lista_sim: Array = Datos.tabla("ESC_SIM")
	_rejilla_identidad(c, "esc_simbolo",
		lista_sim.slice(1) if lista_sim != null and lista_sim.size() > 1 else [], "Símbolo (reemplaza las iniciales)")
	if not _modo_experto:
		var ee := _texto(10, COL_SUAVE)
		ee.text = "Veintiseis formas × treinta patrones × dos colores: miles de escudos distintos."
		ee.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_gente.add_child(ee)
	_boton_heredar(c, ["esc_color1", "esc_color2"], "Volver a los colores del club")
	_rejilla_especiales(c)

	var tu := _texto(11, COL_ACENTO)
	tu.text = "4 · INTERFAZ%s" % ("" if c.ui_acento == "" else "  ·  propia")
	_lista_gente.add_child(tu)
	_fila_color_identidad(c, "Color de acento (botones y menú)", "ui_acento")
	_boton_heredar(c, ["ui_acento"], "Usar el color del club")

	var b_todo := Button.new()
	b_todo.text = "🎨 Igualar todo a los colores del club"
	b_todo.add_theme_font_size_override("font_size", 11)
	b_todo.pressed.connect(func() -> void:
		c.igualar_identidad()
		Escudo.limpiar_cache()
		_refrescar())
	_lista_gente.add_child(b_todo)

	## LAS TRES CAMISETAS. Vivían dentro del chip "Comercial" -Club→Equipación
	## solo tenía una VISTA PREVIA sin controles, y el editor de verdad estaba
	## enterrado junto a proveedor/zonas/naming, sin relación temática-. Un
	## editor de camiseta es identidad visual, así que se pinta aquí, donde ya
	## está el resto del escudo y los colores del club.
	if mundo.comercial != null:
		_lista_gente.add_child(HSeparator.new())
		_pintar_kits(mundo.comercial, c)

## Una fila de color. `prop` puede ser un color del club (siempre tiene valor) o
## uno de los heredables (vacío = "el del club"), y el selector arranca con el
## color EFECTIVO en los dos casos: enseñar negro para "sin elegir" haría creer
## que el escudo es negro.
func _fila_color_identidad(c: Club, etiqueta: String, prop: String) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	_lista_gente.add_child(fila)
	var et := _texto(12, COL_TEXTO)
	et.text = etiqueta
	et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et.clip_text = true
	et.tooltip_text = etiqueta
	fila.add_child(et)
	var actual := String(c.get(prop))
	if actual == "":
		match prop:
			"kit_color1": actual = c.color_kit1()
			"kit_color2": actual = c.color_kit2()
			"esc_color1": actual = c.color_escudo1()
			"esc_color2": actual = c.color_escudo2()
			"ui_acento": actual = c.color_acento()
			_: actual = c.color1
	var cp := ColorPickerButton.new()
	cp.color = Color(actual)
	cp.custom_minimum_size = Vector2(90, 26)
	cp.edit_alpha = false
	## `color_changed` y no `popup_closed`: se ve el cambio mientras eliges, que
	## es la única forma de acertar con un color.
	cp.color_changed.connect(func(nuevo: Color) -> void:
		c.set(prop, "#" + nuevo.to_html(false))
		Escudo.limpiar_cache()
		_refrescar())
	fila.add_child(cp)

## Una rejilla de opciones para un campo de texto (estampado, forma, patrón).
## Incluye un botón vacío al principio: "el que le tocó por sorteo" también es
## una elección válida y hay que poder volver a ella.
func _rejilla_identidad(c: Club, prop: String, opciones: Array, titulo: String) -> void:
	var lt := _texto(10, COL_SUAVE)
	lt.text = titulo
	_lista_gente.add_child(lt)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 4)
	_lista_gente.add_child(flow)
	var actual := String(c.get(prop))
	for op: Variant in ([""] + Array(opciones)):
		var clave := String(op)
		var b := Button.new()
		b.text = clave if clave != "" else "por sorteo"
		b.add_theme_font_size_override("font_size", 10)
		b.toggle_mode = true
		b.button_pressed = actual == clave
		b.clip_text = true
		b.custom_minimum_size = Vector2(72, 24)
		b.pressed.connect(func() -> void:
			c.set(prop, clave)
			Escudo.limpiar_cache()
			_refrescar())
		flow.add_child(b)

## El picker de escudos especiales (22-9-2026): a diferencia de
## `_rejilla_identidad()` -que alcanza con mostrar el nombre de la clave
## ("cruz", "tablero")-, un especial es una imagen de Canva sin relacion
## visible con su id ("wolf_1" no dice nada), asi que cada boton lleva la
## miniatura real en vez de texto. Solo se listan los YA desbloqueados -ver
## `Escudo.especiales_desbloqueados()`- mas un "Ninguno" para volver al
## generador procedural de arriba, la misma logica que el "por sorteo" de
## `_rejilla_identidad()`.
func _rejilla_especiales(c: Club) -> void:
	var desbloqueados: Array = Escudo.especiales_desbloqueados()
	var total: int = Escudo.ESPECIALES.size()
	var lt := _texto(11, COL_ACENTO)
	lt.text = "Escudo especial (coleccionable)"
	_lista_gente.add_child(lt)
	if not _modo_experto:
		var info := _texto(10, COL_SUAVE)
		info.text = "%d de %d desbloqueados según tu nivel de perfil de gestor -suben solos jugando temporadas y ganando títulos-. No reemplazan al generador de arriba: son una alternativa que podés elegir o no." % [desbloqueados.size(), total]
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_gente.add_child(info)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 4)
	_lista_gente.add_child(flow)

	var b_ninguno := Button.new()
	b_ninguno.text = "Ninguno\n(procedural)"
	b_ninguno.add_theme_font_size_override("font_size", 9)
	b_ninguno.toggle_mode = true
	b_ninguno.button_pressed = c.esc_especial == ""
	b_ninguno.custom_minimum_size = Vector2(64, 64)
	b_ninguno.pressed.connect(func() -> void:
		c.esc_especial = ""
		_refrescar())
	flow.add_child(b_ninguno)

	for id: String in desbloqueados:
		var b := Button.new()
		b.toggle_mode = true
		b.button_pressed = c.esc_especial == id
		b.custom_minimum_size = Vector2(64, 64)
		b.tooltip_text = id
		var tex := Escudo.textura_especial(id)
		if tex != null:
			var ic := TextureRect.new()
			ic.texture = tex
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ic.set_anchors_preset(Control.PRESET_FULL_RECT)
			ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(ic)
		b.pressed.connect(func() -> void:
			c.esc_especial = id
			_refrescar())
		flow.add_child(b)

func _boton_heredar(c: Club, props: Array, texto: String) -> void:
	var b := Button.new()
	b.text = texto
	b.add_theme_font_size_override("font_size", 10)
	var vacios := true
	for p: String in props:
		if String(c.get(p)) != "":
			vacios = false
	b.disabled = vacios
	b.pressed.connect(func() -> void:
		for p2: String in props:
			c.set(p2, "")
		Escudo.limpiar_cache()
		_refrescar())
	_lista_gente.add_child(b)

## `vIdentidadPlus()`: LO QUE SE VENDE DEL CLUB.
##
## Aquí no se decide cómo juega el equipo: se decide cuánto vale la camiseta.
## Todo lo de esta pantalla paga, y todo lo de esta pantalla cuesta algo que no
## es dinero —el nombre del estadio, el aspecto del uniforme, la paciencia de la
## hinchada—, que es lo que la hace una pantalla de decisiones y no una lista de
## mejoras.
func _pintar_comercial(c: Club) -> void:
	var co := mundo.comercial
	if co == null:
		return
	_lista_gente.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "💰 EXPLOTACIÓN COMERCIAL"
	_lista_gente.add_child(t)
	_dato("Entra cada semana", _dinero(co.renta_semanal(c)), COL_VERDE, _lista_gente)

	## Las camisetas se editan en el chip "Identidad" ahora, junto al escudo y
	## los colores del club -no aquí, junto a proveedor/zonas/naming, que es
	## puro trato comercial y no aspecto visual-.
	_pintar_proveedor(co, c)
	_pintar_zonas(co, c)
	_pintar_naming(co, c)
	_pintar_premium(co, c)
	_pintar_detalles(co, c)

## LAS TRES CAMISETAS. La de arquero existe por una razón que no es estética: en
## el campo tiene que distinguirse de las otras veintiuna.
func _pintar_kits(co: Comercial, c: Club) -> void:
	var tk := _texto(11, COL_ACENTO)
	tk.text = "👕 LAS TRES CAMISETAS"
	_lista_gente.add_child(tk)
	var muestras := HBoxContainer.new()
	muestras.add_theme_constant_override("separation", 12)
	muestras.alignment = BoxContainer.ALIGNMENT_CENTER
	_lista_gente.add_child(muestras)
	for cual: String in ["titular", "alt", "por"]:
		var img := TextureRect.new()
		img.texture = Jersey.textura_procedural(co.color_kit(cual, 1, c),
			co.color_kit(cual, 2, c), co.estilo_kit(cual, c), 56)
		img.custom_minimum_size = Vector2(56, 56)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.tooltip_text = {"titular": "Titular", "alt": "Alternativa", "por": "De arquero"}[cual]
		muestras.add_child(img)
	for par: Array in [["titular", "Titular"], ["alt", "Alternativa"], ["por", "De arquero"]]:
		var cual2 := String(par[0])
		var tt := _texto(10, COL_SUAVE)
		tt.text = String(par[1])
		_lista_gente.add_child(tt)
		for n: int in [1, 2]:
			var num := n
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 6)
			_lista_gente.add_child(fila)
			var et := _texto(11, COL_TEXTO)
			et.text = "Color %d" % num
			et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila.add_child(et)
			var cp := ColorPickerButton.new()
			cp.color = Color(co.color_kit(cual2, num, c))
			cp.custom_minimum_size = Vector2(84, 24)
			cp.edit_alpha = false
			cp.color_changed.connect(func(nuevo: Color) -> void:
				co.fijar_kit(cual2, "c%d" % num, "#" + nuevo.to_html(false))
				_refrescar())
			fila.add_child(cp)
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 4)
		flow.add_theme_constant_override("v_separation", 4)
		_lista_gente.add_child(flow)
		for k: String in Jersey.KITS:
			var estilo := k
			var b := Button.new()
			b.text = estilo
			b.add_theme_font_size_override("font_size", 10)
			b.toggle_mode = true
			b.button_pressed = co.estilo_kit(cual2, c) == estilo
			b.clip_text = true
			b.custom_minimum_size = Vector2(66, 22)
			b.pressed.connect(func() -> void:
				co.fijar_kit(cual2, "estilo", estilo)
				_refrescar())
			flow.add_child(b)

	## MEDIAS, SHORT Y TIPOGRAFÍA. No salen en ninguna miniatura y salen en el
	## campo: es donde de verdad se ven.
	var tm := _texto(10, COL_SUAVE)
	tm.text = "Medias, short y tipografía de los dorsales"
	_lista_gente.add_child(tm)
	for par2: Array in [["medias", "Color de las medias"], ["pantalon", "Color del short"]]:
		var prop := String(par2[0])
		var fila2 := HBoxContainer.new()
		fila2.add_theme_constant_override("separation", 6)
		_lista_gente.add_child(fila2)
		var et2 := _texto(11, COL_TEXTO)
		et2.text = String(par2[1])
		et2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila2.add_child(et2)
		var actual := String(co.get(prop))
		var cp2 := ColorPickerButton.new()
		cp2.color = Color(actual if actual != "" else c.color_kit2())
		cp2.custom_minimum_size = Vector2(84, 24)
		cp2.edit_alpha = false
		cp2.color_changed.connect(func(nuevo: Color) -> void:
			co.set(prop, "#" + nuevo.to_html(false))
			_refrescar())
		fila2.add_child(cp2)
	var flow_t := HFlowContainer.new()
	flow_t.add_theme_constant_override("h_separation", 4)
	_lista_gente.add_child(flow_t)
	for f: Array in Comercial.tipografias():
		var clave := String(f[0])
		var b2 := Button.new()
		b2.text = String(f[1])
		b2.add_theme_font_size_override("font_size", 10)
		b2.toggle_mode = true
		b2.button_pressed = co.tipografia == clave
		b2.custom_minimum_size = Vector2(72, 22)
		b2.pressed.connect(func() -> void:
			co.tipografia = clave
			_refrescar())
		flow_t.add_child(b2)

## EL PROVEEDOR. La marca propia no paga nada y se queda el margen entero: es la
## opción del club que no quiere deberle nada a nadie.
func _pintar_proveedor(co: Comercial, c: Club) -> void:
	var t := _texto(11, COL_ACENTO)
	t.text = "🏭 PROVEEDOR DE INDUMENTARIA"
	_lista_gente.add_child(t)
	_dato("Aporta al año", _dinero(co.renta_proveedor(c)), COL_VERDE, _lista_gente)
	for f: Array in Comercial.proveedores():
		var clave := String(f[0])
		var elegido := co.proveedor == clave
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_lista_gente.add_child(fila)
		var n := _texto(12, COL_ACENTO if elegido else COL_TEXTO)
		n.text = "%s%s" % ["✔  " if elegido else "     ", Nombres.limpiar(String(f[1]))]
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		n.tooltip_text = String(f[3])
		fila.add_child(n)
		var m := _texto(11, COL_ORO)
		m.text = "×%.2f" % float(f[2]) if float(f[2]) > 0.0 else "—"
		m.custom_minimum_size = Vector2(50, 0)
		fila.add_child(m)
		var b := Button.new()
		b.text = "Firmado" if elegido else "Firmar"
		b.disabled = elegido
		b.add_theme_font_size_override("font_size", 11)
		b.custom_minimum_size = Vector2(84, 0)
		b.pressed.connect(func() -> void:
			co.proveedor = clave
			_refrescar())
		fila.add_child(b)

## LAS CINCO ZONAS. Son contratos INDEPENDIENTES y todos ingresan a la vez, que
## es exactamente por qué las camisetas modernas están como están.
func _pintar_zonas(co: Comercial, c: Club) -> void:
	var t := _texto(11, COL_ACENTO)
	t.text = "💸 PATROCINIOS POR ZONA"
	_lista_gente.add_child(t)
	_dato("Total de las zonas", "%s/semana" % _dinero(co.renta_zonas()), COL_VERDE, _lista_gente)
	for z: Array in Comercial.zonas():
		var clave := String(z[0])
		if co.zonas_firmadas.has(clave):
			var f: Dictionary = co.zonas_firmadas[clave]
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 6)
			_lista_gente.add_child(fila)
			var n := _texto(12, Color(String(f.get("color", "#e8b13a"))))
			n.text = "%s  ·  %s" % [String(f["marca"]), String(z[1])]
			n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			n.clip_text = true
			n.tooltip_text = "%s al año, firmado en %d por %d temporada(s)" % [
				_dinero(int(f["monto"])), int(f["desde"]), int(f["anios"])]
			fila.add_child(n)
			var mm := _texto(11, COL_VERDE)
			mm.text = "%s/año" % _dinero(int(f["monto"]))
			mm.custom_minimum_size = Vector2(90, 0)
			fila.add_child(mm)
			var br := Button.new()
			br.text = "Romper"
			br.add_theme_font_size_override("font_size", 10)
			br.custom_minimum_size = Vector2(72, 0)
			br.pressed.connect(func() -> void:
				var p := co.romper_zona(clave, mundo.mi_club())
				if p != "":
					_escribir("[color=#e05555]No se pudo: %s.[/color]" % p)
				_refrescar())
			fila.add_child(br)
			continue
		var libre := _texto(11, COL_SUAVE)
		libre.text = "%s  ·  libre" % String(z[1])
		_lista_gente.add_child(libre)
		for i in (co.ofertas_zona.get(clave, []) as Array).size():
			var idx := i
			var o: Dictionary = (co.ofertas_zona[clave] as Array)[i]
			var fila2 := HBoxContainer.new()
			fila2.add_theme_constant_override("separation", 6)
			_lista_gente.add_child(fila2)
			var n2 := _texto(11, Color(String(o.get("color", "#e8b13a"))))
			n2.text = "     %s  ·  %d año(s)" % [String(o["marca"]), int(o["anios"])]
			n2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			n2.clip_text = true
			fila2.add_child(n2)
			var b2 := Button.new()
			b2.text = "%s/año" % _dinero(int(o["monto"]))
			b2.add_theme_font_size_override("font_size", 10)
			b2.custom_minimum_size = Vector2(110, 0)
			b2.pressed.connect(func() -> void:
				var p := co.firmar_zona(clave, idx)
				if p != "":
					_escribir("[color=#e05555]No se pudo firmar: %s.[/color]" % p)
				_refrescar())
			fila2.add_child(b2)
	var bb := Button.new()
	bb.text = "🔄 Salir a buscar ofertas"
	bb.add_theme_font_size_override("font_size", 11)
	bb.pressed.connect(func() -> void:
		co.generar_ofertas_zona(mundo.mi_club(), mundo.roles.multiplicador_sponsor() if mundo.roles != null else 1.0)
		_refrescar())
	_lista_gente.add_child(bb)

## EL NAMING. Lo más rentable que existe y lo que más duele: la hinchada lo paga
## en ánimo el día que se firma.
func _pintar_naming(co: Comercial, c: Club) -> void:
	var t := _texto(11, COL_ACENTO)
	t.text = "🏟️ NOMBRE DEL ESTADIO"
	_lista_gente.add_child(t)
	if not co.naming.is_empty():
		var n := _texto(13, Color(String(co.naming.get("color", "#e8b13a"))))
		n.text = String(co.naming.get("nombre", ""))
		_lista_gente.add_child(n)
		_dato("Contrato", "%s/año  ·  %d años desde %d" % [
			_dinero(int(co.naming["monto"])), int(co.naming["anios"]), int(co.naming["desde"])],
			COL_VERDE, _lista_gente)
		var br := Button.new()
		br.text = "Recuperar el nombre  ·  %s" % _dinero(int(round(float(int(co.naming["monto"])) * 0.6)))
		br.add_theme_font_size_override("font_size", 11)
		br.pressed.connect(func() -> void:
			var p := co.romper_naming(mundo.mi_club())
			if p != "":
				_escribir("[color=#e05555]No se pudo: %s.[/color]" % p)
			_refrescar())
		_lista_gente.add_child(br)
		return
	if not _modo_experto:
		var ex := _texto(10, COL_SUAVE)
		ex.text = "Vender el nombre del estadio es de lo más rentable que existe… y de lo que más duele a la hinchada."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_gente.add_child(ex)
	if co.ofertas_naming.is_empty():
		var bb := Button.new()
		bb.text = "Escuchar ofertas por el nombre"
		bb.add_theme_font_size_override("font_size", 11)
		bb.pressed.connect(func() -> void:
			co.generar_ofertas_naming(mundo.mi_club())
			_refrescar())
		_lista_gente.add_child(bb)
		return
	for i in co.ofertas_naming.size():
		var idx := i
		var o: Dictionary = co.ofertas_naming[i]
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_lista_gente.add_child(fila)
		var n2 := _texto(12, Color(String(o.get("color", "#e8b13a"))))
		n2.text = "%s  ·  %d años" % [String(o["nombre"]), int(o["anios"])]
		n2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n2.clip_text = true
		fila.add_child(n2)
		var b := Button.new()
		b.text = "%s/año" % _dinero(int(o["monto"]))
		b.add_theme_font_size_override("font_size", 10)
		b.custom_minimum_size = Vector2(110, 0)
		b.pressed.connect(func() -> void:
			var p := co.firmar_naming(idx, mundo.mi_club())
			if p != "":
				_escribir("[color=#e05555]No se pudo: %s.[/color]" % p)
			_refrescar())
		fila.add_child(b)

## EL ESTADIO PREMIUM. No es ladrillo —eso son las Obras— sino ESPECTÁCULO. El
## techo salva la taquilla cuando llueve y las luces suben el ambiente de verdad.
func _pintar_premium(co: Comercial, c: Club) -> void:
	var t := _texto(11, COL_ACENTO)
	t.text = "✨ ESTADIO PREMIUM"
	_lista_gente.add_child(t)
	for f: Array in Comercial.premium():
		var clave := String(f[0])
		var niv := co.nivel_premium(clave)
		var tope: int = int(f[2])
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_lista_gente.add_child(fila)
		var n := _texto(12, COL_TEXTO)
		n.text = "%s  %s%s" % [String(f[1]), "●".repeat(niv), "○".repeat(tope - niv)]
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		n.tooltip_text = String(f[4])
		fila.add_child(n)
		var b := Button.new()
		var lleno := niv >= tope
		var coste := co.coste_premium(clave, c)
		b.text = "MÁX" if lleno else _dinero(coste)
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = lleno or c.saldo < coste
		b.custom_minimum_size = Vector2(110, 0)
		b.pressed.connect(func() -> void:
			var p := co.mejorar_premium(clave, mundo.mi_club())
			if p != "":
				_escribir("[color=#e05555]No se puede: %s.[/color]" % p)
			_refrescar())
		fila.add_child(b)
	_dato("Rentan por semana", _dinero(co.renta_premium(c)), COL_VERDE, _lista_gente)
	if co.nivel_premium("techo") > 0:
		_dato("Techo retráctil", "+%d%% de asistencia" % int(round((co.factor_techo() - 1.0) * 100.0)),
			COL_VERDE, _lista_gente)
	if co.bono_ambiente() > 0:
		_dato("Luces y pantallas", "+%d de ambiente" % co.bono_ambiente(), COL_VERDE, _lista_gente)

## LOS DETALLES. Ninguno cambia un resultado salvo el avión, y por eso están
## todos juntos al final: son las cosas que hacen que el club sea ESE club.
func _pintar_detalles(co: Comercial, c: Club) -> void:
	var t := _texto(11, COL_ACENTO)
	t.text = "🎺 DETALLES DEL CLUB"
	_lista_gente.add_child(t)
	var campo := LineEdit.new()
	campo.text = co.lema
	campo.placeholder_text = "Lema del club. Ej: «Nunca caminarás solo»"
	campo.max_length = 60
	campo.add_theme_font_size_override("font_size", 12)
	campo.text_submitted.connect(func(x: String) -> void:
		co.escribir_lema(x)
		_refrescar())
	campo.focus_exited.connect(func() -> void: co.escribir_lema(campo.text))
	_lista_gente.add_child(campo)
	_rejilla_comercial(co, "festejo", Comercial.festejos(), "Festejo de campeón")
	_rejilla_comercial(co, "balon", Comercial.balones(), "Balón de juego")
	_rejilla_comercial(co, "cesped", [["natural", "Natural"], ["hibrido", "Híbrido"],
		["sintetico", "Sintético"]], "Tipo de césped")

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	_lista_gente.add_child(fila)
	var et := _texto(11, COL_TEXTO)
	et.text = "Color del bus del equipo"
	et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(et)
	var cp := ColorPickerButton.new()
	cp.color = Color(co.bus)
	cp.custom_minimum_size = Vector2(84, 24)
	cp.edit_alpha = false
	cp.color_changed.connect(func(nuevo: Color) -> void:
		co.bus = "#" + nuevo.to_html(false))
	fila.add_child(cp)

	var fila2 := HBoxContainer.new()
	fila2.add_theme_constant_override("separation", 6)
	_lista_gente.add_child(fila2)
	var et2 := _texto(11, COL_TEXTO)
	et2.text = "Avión propio para giras"
	et2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et2.tooltip_text = "El plantel deja de volar en línea regular: menos fatiga en los viajes largos."
	fila2.add_child(et2)
	var b := Button.new()
	b.text = "SÍ" if co.avion else _dinero(Eco.escalar(Comercial.COSTE_AVION, float(c.rep)))
	b.add_theme_font_size_override("font_size", 11)
	b.custom_minimum_size = Vector2(110, 0)
	b.pressed.connect(func() -> void:
		var msg := co.comprar_avion(mundo.mi_club())
		_escribir("[color=#c9a227]%s[/color]" % msg)
		_refrescar())
	fila2.add_child(b)

func _rejilla_comercial(co: Comercial, prop: String, opciones: Array, titulo: String) -> void:
	var lt := _texto(10, COL_SUAVE)
	lt.text = titulo
	_lista_gente.add_child(lt)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 4)
	_lista_gente.add_child(flow)
	for f: Array in opciones:
		var clave := String(f[0])
		var b := Button.new()
		b.text = String(f[1])
		b.add_theme_font_size_override("font_size", 10)
		b.toggle_mode = true
		b.button_pressed = String(co.get(prop)) == clave
		b.clip_text = true
		b.custom_minimum_size = Vector2(84, 22)
		b.pressed.connect(func() -> void:
			co.set(prop, clave)
			_refrescar())
		flow.add_child(b)





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
var _secc_gente: String = "personas"

func _pintar_gente() -> void:
	_limpiar(_lista_gente)
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 4)
	chips.add_theme_constant_override("v_separation", 4)
	_lista_gente.add_child(chips)
	for s: Array in SECCIONES_GENTE:
		var clave := String(s[0])
		var b := Button.new()
		b.text = String(s[1])
		b.add_theme_font_size_override("font_size", 11)
		b.toggle_mode = true
		b.button_pressed = _secc_gente == clave or (clave == "identidad" and _secc_gente == "kits")
		b.clip_text = true
		b.custom_minimum_size = Vector2(150, 26)
		b.pressed.connect(func() -> void:
			_secc_gente = clave
			_refrescar())
		chips.add_child(b)
	_lista_gente.add_child(HSeparator.new())
	var c := mundo.mi_club()
	match _secc_gente:
		"personas":
			_pintar_gente_personas()
		## "Equipación" (chip del grupo GENTE) vive dentro de Identidad, junto
		## al escudo: sin esta rama el chip abría una página vacía.
		"identidad", "kits":
			_pintar_identidad(c)
		"comercial":
			_pintar_comercial(c)
		"interno":
			PanelClubDentro.pintar(_lista_gente, c, mundo, _texto, _paleta_club_dentro(), _miles, _escribir, _refrescar)

func _pintar_gente_personas() -> void:
	var g := mundo.gente
	if g == null:
		return
	var t := _texto(11, COL_SUAVE)
	t.text = "LA GENTE DEL CLUB"
	_lista_gente.add_child(t)
	var intro := _texto(11, COL_SUAVE)
	intro.text = "Llevan aquí más años que tú y seguirán cuando te vayas. Tratarlos bien no sale en ninguna estadística, pero se nota."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_gente.add_child(intro)
	var media := g.confianza_media()
	_dato("Confianza media", "%d/100" % media,
		COL_VERDE if media >= 70 else (COL_ROJO if media <= 40 else COL_ORO), _lista_gente)
	_dato("Charlas esta semana", "%d de %d" % [g.charlas_esta_semana, Gente.CHARLAS_POR_SEMANA],
		COL_SUAVE, _lista_gente)
	_lista_gente.add_child(HSeparator.new())

	for fila: Array in Gente.ROLES:
		var clave := String(fila[0])
		var f := g.ficha(clave)
		if f.is_empty():
			continue
		var conf := int(f.get("confianza", 50))
		var cab := HBoxContainer.new()
		cab.add_theme_constant_override("separation", 6)
		_lista_gente.add_child(cab)
		var nom := _texto(12, COL_TEXTO)
		nom.text = "%s  %s — %s" % [String(fila[2]), String(fila[1]), String(f.get("nombre", ""))]
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nom.clip_text = true
		cab.add_child(nom)
		var cf := _texto(12, COL_VERDE if conf >= 70 else (COL_ROJO if conf <= 40 else COL_ORO))
		cf.text = str(conf)
		cf.custom_minimum_size = Vector2(32, 0)
		cab.add_child(cf)
		var b := Button.new()
		var ya := g.hablado_esta_semana(clave)
		b.text = "Ya hablasteis" if ya else "Charlar"
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = ya or g.charlas_esta_semana >= Gente.CHARLAS_POR_SEMANA
		b.custom_minimum_size = Vector2(110, 0)
		b.pressed.connect(func() -> void: _charlar_con(clave))
		cab.add_child(b)
		var d := _texto(10, COL_SUAVE)
		d.text = "%d años  ·  %d en el club  ·  %s  ·  %s" % [
			int(f.get("edad", 0)), int(f.get("anios", 0)), String(f.get("perfil", "")), String(fila[3])]
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_gente.add_child(d)

func _charlar_con(clave: String) -> void:
	var txt := mundo.gente.charlar(clave)
	if txt != "":
		_escribir("[color=#8ea595]%s[/color]" % txt)
	_refrescar()

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
var _secc_redes: String = "redes"

func _filtrar_redes() -> void:
	var titulos: Array = []
	for k: String in SECC_REDES:
		titulos.append_array(SECC_REDES[k] as Array)
	var visibles: Array = SECC_REDES.get(_secc_redes, [])
	var mostrando := true
	for n in _lista_redes.get_children():
		var l := n as Label
		if l != null and titulos.has(l.text):
			mostrando = visibles.has(l.text)
		if n is CanvasItem:
			(n as CanvasItem).visible = mostrando

func _pintar_redes() -> void:
	_limpiar(_lista_redes)
	var p := mundo.prensa
	if p == null:
		return
	var g := GridContainer.new()
	g.columns = 4
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 12)
	_lista_redes.add_child(g)
	for par in [["Seguidores", _miles(p.seguidores)], ["Funa", str(p.funa)],
			["Ánimo", str(p.animo)], ["Prestigio DT", str(p.rep_entrenador)]]:
		var col := VBoxContainer.new()
		g.add_child(col)
		var et := _texto(10, COL_SUAVE)
		et.text = String(par[0])
		col.add_child(et)
		var va := _texto(16, COL_TEXTO)
		va.text = String(par[1])
		col.add_child(va)
	var estado := _texto(11, COL_ROJO if p.funa > 60 else (COL_ORO if p.funa > 35 else COL_VERDE))
	estado.text = ("⚠️ Campaña activa en tu contra: el directorio lo está mirando."
		if p.funa > 60 else ("Hay ruido en redes, pero se aguanta."
		if p.funa > 35 else "Ambiente tranquilo en las redes."))
	estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_redes.add_child(estado)
	_lista_redes.add_child(HSeparator.new())

	var tg := _texto(11, COL_SUAVE)
	tg.text = "GABINETE DE COMUNICACIÓN"
	_lista_redes.add_child(tg)
	var ex := _texto(10, COL_SUAVE)
	ex.text = "Apoyar calma la funa pero gasta un cartucho. Callar no cuesta nada hoy. Contestar es cara o cruz: apaga el fuego o lo dobla."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_redes.add_child(ex)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	_lista_redes.add_child(fila)
	for par2 in [["apoyo", "📢 Comunicado de apoyo"], ["silencio", "🤐 Silencio de prensa"],
			["contestar", "🗣️ Contestar"]]:
		var clave := String(par2[0])
		var b := Button.new()
		b.text = String(par2[1])
		b.add_theme_font_size_override("font_size", 11)
		b.clip_text = true
		b.custom_minimum_size = Vector2(110, 0)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void: _comunicado(clave))
		fila.add_child(b)
	_lista_redes.add_child(HSeparator.new())

	_pintar_periodistas(p)
	_pintar_mesa_debate(p)
	_pintar_influencer(p)
	_pintar_medios_propios(p)
	_pintar_vocero(p)
	_pintar_derechos_tv(p)
	_pintar_portadas(p)
	_pintar_ano_contado(p)

	var tf := _texto(11, COL_SUAVE)
	tf.text = "LO QUE SE DICE"
	_lista_redes.add_child(tf)
	if p.posts.is_empty():
		var vac := _texto(12, COL_SUAVE)
		vac.text = "Todavía nadie habla de ti. Gana o pierde algo y verás."
		_lista_redes.add_child(vac)
		return
	for i in mini(25, p.posts.size()):
		var m: Dictionary = p.posts[i]
		var l := _texto(12, COL_TEXTO)
		l.text = "%s  %s" % [String(m.get("avatar", "")), String(m.get("texto", ""))]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_redes.add_child(l)
		var meta := _texto(10, COL_SUAVE)
		meta.text = "%s  ·  ♥ %s  ·  ↻ %s" % [
			String(m.get("usuario", "")), _miles(int(m.get("likes", 0))), _miles(int(m.get("rt", 0)))]
		_lista_redes.add_child(meta)

## `vPrensa()`: los cinco periodistas con nombre y cómo te tratan. `funa` mide
## el ruido; esto le pone CARA. Uno por semana: si se pudiera atender a los
## cinco, no habría que elegir a quién cuidar, que es toda la decisión.
func _pintar_periodistas(p: Prensa) -> void:
	_lista_redes.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "🎙️ LA PRENSA"
	_lista_redes.add_child(t)
	var am := p.amortiguador_prensa()
	_dato("Cómo te trata la prensa", "×%.2f sobre el ruido" % am,
		COL_VERDE if am < 1.0 else (COL_ROJO if am > 1.1 else COL_SUAVE), _lista_redes)
	for f: Array in Prensa.PERIODISTAS:
		var clave := String(f[0])
		var rel := p.relacion_con(clave)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_lista_redes.add_child(fila)
		var n := _texto(12, COL_TEXTO)
		n.text = "%s  ·  %s  ·  %s" % [String(f[1]), String(f[2]), String(f[3])]
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		n.tooltip_text = String(f[4])
		fila.add_child(n)
		var r := _texto(12, COL_VERDE if rel >= 70 else (COL_ROJO if rel <= 35 else COL_ORO))
		r.text = str(rel)
		r.custom_minimum_size = Vector2(32, 0)
		fila.add_child(r)
		var b := Button.new()
		b.text = "Atender"
		b.add_theme_font_size_override("font_size", 11)
		b.custom_minimum_size = Vector2(90, 0)
		b.pressed.connect(func() -> void: _atender_periodista(clave))
		fila.add_child(b)

## Los medios propios: la respuesta a no gustarte cómo lo cuentan. Cuestan una
## vez y rentan cada mes.
func _pintar_medios_propios(p: Prensa) -> void:
	var c := mundo.mi_club()
	_lista_redes.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "📡 MEDIOS PROPIOS"
	_lista_redes.add_child(t)
	var ex := _texto(10, COL_SUAVE)
	ex.text = "Si no te gusta cómo lo cuentan, cuéntalo tú. Se pagan una vez y rentan todos los meses."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_redes.add_child(ex)
	for f: Array in Prensa.MEDIOS_PROPIOS:
		var clave := String(f[0])
		var tengo := p.tiene_medio(clave)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_lista_redes.add_child(fila)
		var n := _texto(12, COL_VERDE if tengo else COL_TEXTO)
		n.text = "%s%s — %s" % ["✔  " if tengo else "     ", String(f[1]), String(f[4])]
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		fila.add_child(n)
		var r := _texto(11, COL_SUAVE)
		r.text = "+%s/mes" % _dinero(Eco.escalar(float(f[3]), float(c.rep)))
		r.custom_minimum_size = Vector2(96, 0)
		fila.add_child(r)
		var b := Button.new()
		var coste := Eco.escalar(float(f[2]), float(c.rep))
		b.text = "Puesto" if tengo else _dinero(coste)
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = tengo or c.saldo < coste
		b.custom_minimum_size = Vector2(96, 0)
		b.pressed.connect(func() -> void: _comprar_medio(clave, c))
		fila.add_child(b)

## EL PORTAVOZ. Nombrar a alguien que hable por ti reparte a la mitad lo que
## mueve cada rueda de prensa, para bien y para mal: es el trato que el botón
## del HTML prometía en su texto y no cobraba en ninguna cuenta.
func _pintar_vocero(p: Prensa) -> void:
	var c := mundo.mi_club()
	if c == null:
		return
	_lista_redes.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "🎤 QUIÉN DA LA CARA"
	_lista_redes.add_child(t)
	var hay := not p.vocero.is_empty()
	var ex := _texto(11, COL_ORO if hay else COL_SUAVE)
	if hay:
		ex.text = "%s habla por ti. La rueda de prensa mueve la mitad: ni te luces ni te hundes." % String(p.vocero.get("nombre", ""))
	else:
		ex.text = "Das tú la cara en cada rueda. Todo lo que digas cuenta el doble que con portavoz."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_redes.add_child(ex)
	var b := Button.new()
	b.text = "Quitar al portavoz" if hay else "Nombrar portavoz"
	b.add_theme_font_size_override("font_size", 11)
	b.pressed.connect(func() -> void:
		var msg := p.nombrar_vocero(mundo.mi_club())
		## Si el estado no cambió es que no se pudo: no hay capitán ni líder a
		## quien poner delante del micrófono.
		if (not p.vocero.is_empty()) == hay:
			_escribir("[color=#e05555]No se pudo: %s.[/color]" % msg)
		else:
			_escribir("[color=#4caf6d]%s[/color]" % msg)
		_refrescar())
	_lista_redes.add_child(b)

## LOS DERECHOS DE TELEVISIÓN: la decisión más rentable y más impopular. Vender
## solo paga un 35% más si tu club vende, y un 30% MENOS si no; en los dos casos
## la asamblea te lo apunta. Es la única palanca del juego que sube el ingreso
## más grande del club a cambio de perder aliados en la federación.
func _pintar_derechos_tv(p: Prensa) -> void:
	var c := mundo.mi_club()
	if c == null:
		return
	_lista_redes.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "📺 DERECHOS DE TELEVISIÓN"
	_lista_redes.add_child(t)
	var ex := _texto(10, COL_SUAVE)
	ex.text = "En bloque cobras lo que reparte la liga. Por tu cuenta puedes ganar mucho más… si tu club vende. Y la asamblea te lo tiene en cuenta."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_redes.add_child(ex)
	_dato("Modelo actual", "Negociación individual" if p.tv_individual else "Reparto en bloque",
		COL_TEXTO, _lista_redes)
	var ft := p.factor_tv()
	var pct := int(round((ft - 1.0) * 100.0))
	_dato("Efecto sobre tus derechos", "%s%d%%" % ["+" if pct > 0 else "", pct],
		COL_VERDE if pct > 0 else (COL_ROJO if pct < 0 else COL_SUAVE), _lista_redes)
	## El reparto de la asamblea es OTRO multiplicador, y se enseña al lado para
	## que se vea que se acumulan: votar mal en la federación y vender solo mal
	## es la forma más rápida de quedarse sin la entrada más grande del club.
	if mundo.federacion != null and not is_equal_approx(mundo.federacion.factor_tv(), 1.0):
		var fr := mundo.federacion.factor_tv()
		_dato("Reparto votado en la asamblea", "×%.2f" % fr,
			COL_VERDE if fr > 1.0 else COL_ROJO, _lista_redes)
	_dato("Cobro mensual estimado", _dinero(int(round(
		float(Finanzas.new(c, 0.0, 0, 0.0).derechos_tv_base())
		* ft * (mundo.federacion.factor_tv() if mundo.federacion != null else 1.0)))),
		COL_TEXTO, _lista_redes)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	_lista_redes.add_child(fila)
	for op: Array in [[false, "Reparto en bloque"], [true, "Negociar por mi cuenta"]]:
		var individual: bool = op[0]
		var b := Button.new()
		b.text = String(op[1])
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = p.tv_individual == individual
		b.custom_minimum_size = Vector2(140, 0)
		b.clip_text = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			var msg := p.negociar_tv(individual, mundo.mi_club())
			_escribir("[color=#e0a832]Televisión:[/color] %s" % msg)
			_refrescar())
		fila.add_child(b)

## EL ARCHIVO DE PORTADAS. Se escribían después de cada partido grande y se
## perdían al cambiar de pantalla. Juntas se leen como la hemeroteca del ciclo:
## de un vistazo se ve si el año fue de titulares buenos o de titulares malos.
## LA ENTREVISTA AL PASO (C6): si esta semana te paró un medio nuevo.
func _al_paso_nuevo() -> void:
	if mundo == null or mundo.prensa == null or mundo.prensa.al_paso.is_empty():
		return
	var n := PieDeCampo.mostrar_al_paso(self, mundo.prensa)
	if n != null:
		n.cerrado.connect(_refrescar)

func _portada_nueva() -> void:
	if mundo == null or mundo.prensa == null or mundo.prensa.portadas.is_empty():
		return
	var d: Dictionary = mundo.prensa.portadas[0]
	var nueva := bool(d.get("nueva", false))
	for x: Dictionary in mundo.prensa.portadas:
		x.erase("nueva")
	if nueva and PortadaPeriodico.auto():
		PortadaPeriodico.mostrar(self, mundo, d)

func _pintar_portadas(p: Prensa) -> void:
	_lista_redes.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "🗞️ ARCHIVO DE PORTADAS"
	_lista_redes.add_child(t)
	if p.portadas.is_empty():
		var vac := _texto(11, COL_SUAVE)
		vac.text = "Las portadas se archivan solas después de cada partido."
		vac.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_redes.add_child(vac)
		return
	for i in mini(14, p.portadas.size()):
		var d: Dictionary = p.portadas[i]
		var tipo := String(d.get("tipo", "neutro"))
		## Cada portada del archivo se abre como periódico (C20).
		var tit := Button.new()
		tit.flat = true
		tit.alignment = HORIZONTAL_ALIGNMENT_LEFT
		tit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tit.add_theme_font_size_override("font_size", 12)
		tit.add_theme_color_override("font_color", COL_VERDE if tipo == "bien" else (COL_ROJO if tipo == "mal" else COL_TEXTO))
		tit.text = "🗞 " + String(d.get("t", ""))
		tit.tooltip_text = "Abrir la portada"
		tit.pressed.connect(func() -> void: PortadaPeriodico.mostrar(self, mundo, d))
		_lista_redes.add_child(tit)
		var cu := _texto(10, COL_SUAVE)
		cu.text = "%s   ·   S%d · %d" % [String(d.get("c", "")), int(d.get("semana", 0)), int(d.get("anio", 0))]
		cu.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_redes.add_child(cu)

## EL AÑO CONTADO: un párrafo en vez de una tabla. Toda la información ya está
## repartida por seis pantallas; aquí se cuenta como se lo contaría alguien, que
## es la única forma de que una temporada se lea como una temporada.
func _pintar_ano_contado(p: Prensa) -> void:
	_lista_redes.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "📖 EL AÑO CONTADO"
	_lista_redes.add_child(t)
	var r := _texto(12, COL_TEXTO)
	r.text = p.narrador_temporada()
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_redes.add_child(r)

## `vDebate()`: LOS QUE MUEVEN MASAS. Cinco creadores con más audiencia que
## cualquier periódico del juego.
##
## Al tertuliano lo escucha el directorio; a estos los escucha la calle, y por
## eso lo que mueven no es la confianza sino los seguidores del club. Invitarlo
## cuesta dinero y da alcance; ignorarlo es gratis y se paga en índice de prensa.
func _pintar_influencer(p: Prensa) -> void:
	var op := p.opinion_influencer()
	if op.is_empty():
		return
	var c := mundo.mi_club()
	_lista_redes.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "📱 LO QUE DICEN LOS QUE MUEVEN MASAS"
	_lista_redes.add_child(t)
	var n := _texto(12, COL_TEXTO)
	n.text = "%s  ·  %s seguidores" % [String(op["nombre"]), String(op["seguidores"])]
	n.clip_text = true
	_lista_redes.add_child(n)
	var tono := String(op["tono"])
	var q := _texto(13, COL_VERDE if tono == "bien" else (COL_ROJO if tono == "mal" else COL_ORO))
	q.text = "«%s»" % String(op["texto"])
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_redes.add_child(q)
	var et := _texto(10, COL_SUAVE)
	et.text = "A favor" if tono == "bien" else ("En contra" if tono == "mal" else "Tibio")
	_lista_redes.add_child(et)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	_lista_redes.add_child(fila)
	var coste := Eco.escalar(Prensa.COSTE_INVITAR, float(c.rep)) if c != null else 0
	for op_b: Array in [[true, "🤝 Invitarlo al club  ·  %s" % _dinero(coste)], [false, "🙄 Ignorarlo"]]:
		var invitar: bool = op_b[0]
		var b := Button.new()
		b.text = String(op_b[1])
		b.add_theme_font_size_override("font_size", 11)
		b.clip_text = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = invitar and c != null and c.saldo < coste
		b.pressed.connect(func() -> void:
			var msg := p.responder_influencer(invitar, mundo.mi_club())
			_escribir("[color=#c9a227]%s[/color]" % msg)
			_refrescar())
		fila.add_child(b)

## `vDebate()`: la mesa de televisión y el escalafón de entrenadores.
##
## "No cambia un resultado, pero sí lo que el directorio escucha en el desayuno"
## —lo dice la pantalla del HTML—. Los cinco tertulianos hablan del estado REAL
## del club, no de frases al azar: si dijeran cualquier cosa, se notaría a la
## segunda semana y se dejarían de leer.
func _pintar_mesa_debate(p: Prensa) -> void:
	var mesa := p.mesa_de_debate()
	if mesa.is_empty():
		return
	_lista_redes.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "📺 MESA DE DEBATE"
	_lista_redes.add_child(t)
	for f: Dictionary in mesa:
		var n := _texto(12, COL_TEXTO)
		n.text = "%s  ·  %s" % [String(f["nombre"]), String(f["perfil"])]
		_lista_redes.add_child(n)
		var fr := _texto(12, COL_SUAVE)
		fr.text = "«%s»" % String(f["frase"])
		fr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_redes.add_child(fr)

	## EL ESCALAFÓN DE ENTRENADORES. Es la única métrica del juego que mide al
	## ENTRENADOR y no al club: premia rendir por encima de lo que el club
	## permite. Un séptimo con el decimoquinto presupuesto vale más que un
	## tercero con el primero.
	var rank := p.ranking_entrenadores()
	if rank.is_empty():
		return
	var tr := _texto(11, COL_SUAVE)
	tr.text = "🏅 RANKING DE ENTRENADORES"
	_lista_redes.add_child(tr)
	var ex := _texto(10, COL_SUAVE)
	ex.text = "No mide dónde acabas, sino cuánto le sacas a lo que tienes."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_redes.add_child(ex)
	var mi_puesto := 0
	for i in rank.size():
		if bool((rank[i] as Dictionary)["mio"]):
			mi_puesto = i + 1
	for i2 in mini(8, rank.size()):
		var f2: Dictionary = rank[i2]
		var c2: Club = f2["club"]
		_dato("%d.  %s" % [i2 + 1, c2.nombre],
			"%d  ·  va %d.º y se le esperaba %d.º" % [int(f2["nota"]), int(f2["puesto"]), int(f2["esperado"])],
			COL_ACENTO if bool(f2["mio"]) else COL_TEXTO, _lista_redes)
	if mi_puesto > 8:
		var mp := _texto(11, COL_ACENTO)
		mp.text = "Tú vas %d.º de %d." % [mi_puesto, rank.size()]
		_lista_redes.add_child(mp)

func _atender_periodista(clave: String) -> void:
	var txt := mundo.prensa.atender(clave)
	if txt != "":
		_escribir("[color=#8ea595]%s[/color]" % txt)
	_refrescar()

func _comprar_medio(clave: String, c: Club) -> void:
	var problema := mundo.prensa.comprar_medio(clave, c)
	if problema != "":
		_escribir("[color=#e05555]No se pudo comprar: %s.[/color]" % problema)
	_refrescar()

func _comunicado(tipo: String) -> void:
	var txt := mundo.prensa.comunicado(tipo)
	if txt != "":
		_escribir("[color=#8ea595]%s[/color]" % txt)
		_anotar("Gabinete de comunicación", txt)
	_refrescar()

func _pintar_correo() -> void:
	_limpiar(_lista_correo)
	var sin_leer := 0
	for it: Dictionary in _bandeja:
		if not bool(it["leida"]):
			sin_leer += 1

	var filtros := HBoxContainer.new()
	filtros.add_theme_constant_override("separation", 6)
	_lista_correo.add_child(filtros)
	var b_todo := Button.new()
	b_todo.text = "Todo (%d)" % _bandeja.size()
	b_todo.toggle_mode = true
	b_todo.button_pressed = _correo_filtro == "todo"
	b_todo.pressed.connect(func() -> void: _correo_filtro = "todo"; _pintar_correo())
	filtros.add_child(b_todo)
	var b_nuevas := Button.new()
	b_nuevas.text = "Sin leer (%d)" % sin_leer
	b_nuevas.toggle_mode = true
	b_nuevas.button_pressed = _correo_filtro == "nuevas"
	b_nuevas.pressed.connect(func() -> void: _correo_filtro = "nuevas"; _pintar_correo())
	filtros.add_child(b_nuevas)
	if sin_leer > 0:
		var b_todas := Button.new()
		b_todas.text = "✅ Marcar todo como leído"
		b_todas.pressed.connect(func() -> void:
			for it2: Dictionary in _bandeja:
				it2["leida"] = true
			_pintar_correo())
		filtros.add_child(b_todas)
	_lista_correo.add_child(HSeparator.new())

	if _bandeja.is_empty():
		var vacio := _texto(12, COL_SUAVE)
		vacio.text = "Bandeja vacía. Los avisos del club van llegando aquí solos."
		_lista_correo.add_child(vacio)
		return
	## Título en un botón plano -mismo truco que ya usa `_fila_jugador()` para
	## que la fila entera responda al clic sin inventar un control nuevo-, y el
	## cuerpo en una etiqueta aparte debajo: meter un VBoxContainer entero
	## dentro de un Button no es un patrón que ya exista en este proyecto y su
	## tamaño mínimo es el del texto, no el de sus hijos.
	var alguna := false
	for it3: Dictionary in _bandeja:
		if _correo_filtro == "nuevas" and bool(it3["leida"]):
			continue
		alguna = true
		var leida := bool(it3["leida"])
		var b := Button.new()
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = false
		b.text = "%s%s   ·   S%d/%d" % ["" if leida else "🔵 ", String(it3["titulo"]), int(it3["semana"]), int(it3["anio"])]
		b.add_theme_font_size_override("font_size", 13)
		b.add_theme_color_override("font_color", _color_de_paleta(COL_SUAVE if leida else COL_TEXTO))
		b.pressed.connect(func() -> void: it3["leida"] = true; _pintar_correo())
		_lista_correo.add_child(b)
		var cuerpo := _texto(11, COL_SUAVE)
		cuerpo.text = String(it3["cuerpo"])
		cuerpo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_correo.add_child(cuerpo)
		_lista_correo.add_child(HSeparator.new())
	if not alguna:
		var nada := _texto(12, COL_SUAVE)
		nada.text = "No queda nada por leer."
		_lista_correo.add_child(nada)

## `G.libro` del HTML, hecho pestaña: siete clases llevan meses -algunas desde
## que se escribieron- emitiendo una señal `movimiento(concepto, monto)` que
## nadie escuchaba. La caja SÍ se movía con cada una de ellas; lo único que
## faltaba era el papel que explica por qué. Ahora `Mundo.libro_financiero` las
## recoge todas y esto es lo único que hace falta para enseñarlo.
## EL BALANCE Y EL FLUJO DE CAJA, de `vContabilidad()`. El estado de resultados
## dice si el año sale bien; esto dice si el club AGUANTA. Son preguntas
## distintas: se puede ganar dinero al año y quedarse sin caja en marzo.
##
## El pasivo lo pone `Banco`: la suma de lo que se debe. Antes iba a cero con
## una nota que decía que el sistema de deuda no estaba portado; ya lo está,
## así que el patrimonio de aquí ya no miente.
## `vBanco()`: la deuda y el reloj de la liquidación. Es el único sistema del
## juego que puede terminar una partida sin perder un partido —doce semanas con
## la caja en rojo y el club se liquida—, así que el estado va arriba y grande.
## `vSponsor()`: la marca del pecho. Ofertas, contrato vigente y exigencia.
##
## Es el único ingreso grande del club que se DECIDE, y por eso tiene su bloque
## propio arriba del todo en Finanzas. Sin firmar no entra nada: la pantalla
## enseña tres cifras y quedarse sin marca también es una decisión, solo que una
## cara.
func _firmar_auspicio(i: int) -> void:
	var problema := mundo.auspicio.firmar(i)
	if problema != "":
		_escribir("[color=#e05555]No se pudo firmar: %s.[/color]" % problema)
	_refrescar()

func _lanzar_campana(clave: String) -> void:
	var problema := mundo.lanzar_campana(clave)
	if problema != "":
		_escribir("[color=#e05555]No se pudo lanzar: %s.[/color]" % problema)
	else:
		var d := Finanzas.def_campana(clave)
		_escribir("[color=#3fa06a][b]Campaña lanzada:[/b][/color] %s." % (String(d[1]) if not d.is_empty() else clave))
	_refrescar()

func _pujar_marca() -> void:
	var r := mundo.pujar_por_marca()
	if r != "":
		_escribir("[color=#c9a227]%s[/color]" % r)
		_anotar("Guerra de marcas", r)
	_refrescar()

func _pedir_credito(i: int, c: Club) -> void:
	var problema := mundo.banco.pedir(i, c)
	if problema != "":
		_escribir("[color=#e05555]No hay crédito: %s.[/color]" % problema)
	_refrescar()

func _prepagar(i: int, c: Club) -> void:
	var problema := mundo.banco.prepagar(i, c)
	if problema != "":
		_escribir("[color=#e05555]No se pudo prepagar: %s.[/color]" % problema)
	else:
		_escribir("[color=#4caf6d]Crédito cancelado.[/color] Te ahorras todos los intereses que quedaban.")
	_refrescar()

func _renegociar(i: int) -> void:
	var problema := mundo.banco.renegociar(i)
	if problema != "":
		_escribir("[color=#e05555]No se pudo renegociar: %s.[/color]" % problema)
	else:
		_escribir("[color=#c9a227]Crédito renegociado.[/color] La cuota baja, el plazo se alarga y al final pagarás más.")
	_refrescar()

func _emitir_bono(c: Club) -> void:
	var problema := mundo.banco.emitir_bono(c)
	if problema != "":
		_escribir("[color=#e05555]No se pudo emitir: %s.[/color]" % problema)
	_refrescar()

func _pintar_finanzas(c: Club) -> void:
	_limpiar(_lista_finanzas)
	## EL PRECIO DE LA ENTRADA. `Club.precio_entrada` existía y `Finanzas` lo
	## usaba de verdad -mueve la ocupación un 5% por euro y multiplica lo que
	## deja cada espectador-, pero no había ningún control para tocarlo: una
	## palanca de gestión real, escrita y funcionando, que el jugador no podía
	## mover. Va arriba del todo porque es una decisión, no un dato.
	var tp := _texto(11, COL_SUAVE)
	tp.text = "PRECIO DE LA ENTRADA"
	_lista_finanzas.add_child(tp)
	var fila_p := HBoxContainer.new()
	fila_p.add_theme_constant_override("separation", 8)
	_lista_finanzas.add_child(fila_p)
	var lp := _texto(16, COL_TEXTO)
	lp.text = Eco.dinero_euros(c.precio_entrada)
	lp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila_p.add_child(lp)
	_boton("−1", func() -> void:
		c.precio_entrada = maxf(2.0, c.precio_entrada - 1.0)
		_refrescar(), fila_p)
	_boton("+1", func() -> void:
		c.precio_entrada = minf(30.0, c.precio_entrada + 1.0)
		_refrescar(), fila_p)
	## Se enseña el efecto de las dos palancas a la vez, porque el precio es
	## justo el sitio donde subir puede recaudar MENOS: más por cabeza, pero
	## menos cabezas.
	## `Finanzas` no vive en el mundo: se construye por club y por semana dentro
	## de `Mundo.avanzar_semana()` (línea 558). Aquí se monta uno igual, solo
	## para PREGUNTARLE -no cobra nada, no mueve la caja-, con el mismo aporte de
	## instalaciones que usará el de verdad.
	var f_sim := Finanzas.new(c, mundo.obras.aporte_ocupacion(), 0, 0.0)
	f_sim.aplica_operacion = true
	f_sim.factor_operacion = mundo.obras.abarata_operacion()
	var gente := f_sim.asistencia()
	var por_cabeza := Finanzas.ingreso_por_espectador(c.precio_entrada)
	_dato("Asistencia estimada", "%s de %s  (%d%%)" % [
		_miles(gente), _miles(c.estadio_aforo),
		int(round(float(gente) * 100.0 / float(maxi(c.estadio_aforo, 1))))], COL_TEXTO, _lista_finanzas)
	_dato("Taquilla por partido", _dinero(int(round(float(gente) * por_cabeza))), COL_VERDE, _lista_finanzas)
	_lista_finanzas.add_child(HSeparator.new())

	## LA TIENDA DEL CLUB. Se paga el montaje una vez y vende todos los meses.
	## Depende de los SOCIOS y del ÁNIMO de la hinchada: rinde cuando el equipo
	## ilusiona, que es lo que la hace una decisión y no un grifo abierto.
	var tt := _texto(11, COL_SUAVE)
	tt.text = "TIENDA DEL CLUB  ·  rinde %s/mes" % _dinero(mundo.ingreso_tienda(c))
	_lista_finanzas.add_child(tt)
	for clave: String in Mundo.TIENDA:
		var linea: Dictionary = Mundo.TIENDA[clave]
		var activa := bool(mundo.tienda.get(clave, false))
		var fila_t := HBoxContainer.new()
		fila_t.add_theme_constant_override("separation", 8)
		_lista_finanzas.add_child(fila_t)
		var nt := _texto(12, COL_TEXTO if activa else COL_SUAVE)
		nt.text = "%s%s" % [String(linea["nombre"]), "   ·   a la venta" if activa else ""]
		nt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila_t.add_child(nt)
		var bt := Button.new()
		bt.text = "Retirar" if activa else "Lanzar  %s" % _dinero(Eco.escalar(int(linea["montaje"]), c.rep))
		bt.add_theme_font_size_override("font_size", 11)
		bt.pressed.connect(func() -> void:
			var err := mundo.alternar_tienda(clave, c)
			if err != "":
				_escribir("[color=#e05555]No se pudo: %s.[/color]" % err)
			_refrescar())
		fila_t.add_child(bt)
	_lista_finanzas.add_child(HSeparator.new())

	## `vContabilidad()` del HTML: el ejercicio entero de un vistazo. Sin esto,
	## la única forma de saber si el club gana o pierde dinero al AÑO era ir
	## sumando cierres de mes a ojo. No inventa cifras: multiplica las mismas
	## partidas que ya cobra y paga `Finanzas.mes()`.
	var partidos_casa := int(_liga_de(c).jornadas() / 2)
	var proy := f_sim.proyeccion_anual(partidos_casa, mundo.ingreso_tienda(c))
	var tc2 := _texto(11, COL_SUAVE)
	tc2.text = "EJERCICIO %d  ·  PROYECCIÓN ANUAL" % mundo.anio
	_lista_finanzas.add_child(tc2)
	var res: int = proy["resultado"]
	_dato("Ingresos previstos", _dinero(int(proy["total_ingresos"])), COL_VERDE, _lista_finanzas)
	_dato("Gastos previstos", _dinero(int(proy["total_gastos"])), COL_ROJO, _lista_finanzas)
	_dato("Resultado del ejercicio", _dinero(res), COL_VERDE if res >= 0 else COL_ROJO, _lista_finanzas)
	## El porcentaje de masa salarial sobre ingresos: LA cifra que mira
	## cualquiera que entienda de esto. Por encima del 70% el club va camino de
	## un problema aunque la caja de hoy se vea estupenda.
	var pct: int = proy["pct_salarial"]
	_dato("Masa salarial sobre ingresos", "%d%%" % pct,
		COL_ROJO if pct > 70 else (COL_ORO if pct > 55 else COL_VERDE), _lista_finanzas)
	if pct > 70:
		var av := _texto(11, COL_ROJO)
		av.text = "Los sueldos se comen más del 70% de lo que entra. Así no se sostiene una temporada mala."
		av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_finanzas.add_child(av)
	var te := _texto(11, COL_SUAVE)
	te.text = "ESTADO DE RESULTADOS"
	_lista_finanzas.add_child(te)
	for k: String in proy["ingresos"]:
		_dato(k, _dinero(int(proy["ingresos"][k])), COL_VERDE, _lista_finanzas)
	for k2: String in proy["gastos"]:
		_dato(k2, "−%s" % _dinero(int(proy["gastos"][k2])), COL_ROJO, _lista_finanzas)
	var pal := _paleta_ficha()
	PanelFinanzas.pintar_balance_y_caja(_lista_finanzas, c, mundo, proy, pal)
	PanelFinanzas.pintar_auspicio(_lista_finanzas, c, mundo, pal,
		func(idx: int) -> void: _firmar_auspicio(idx))
	PanelFinanzas.pintar_patrocinio(_lista_finanzas, c, mundo, pal,
		func(clave: String) -> void: _lanzar_campana(clave),
		func() -> void: _pujar_marca())
	PanelFinanzas.pintar_banco(_lista_finanzas, c, mundo, pal,
		func(i: int) -> void: _pedir_credito(i, c),
		func(i: int) -> void: _prepagar(i, c),
		func(i: int) -> void: _renegociar(i),
		func() -> void: _emitir_bono(c))
	_lista_finanzas.add_child(HSeparator.new())

	var t := _texto(11, COL_SUAVE)
	t.text = "RESUMEN"
	_lista_finanzas.add_child(t)
	_dato("Caja", _dinero(c.saldo), COL_VERDE if c.saldo >= 0 else COL_ROJO, _lista_finanzas)
	_dato("Sueldos del plantel", _dinero(c.masa_salarial()) + "/semana", COL_TEXTO, _lista_finanzas)
	if mundo.staff != null:
		_dato("Cuerpo técnico", _dinero(mundo.staff.sueldo_semanal(c.rep)) + "/semana", COL_TEXTO, _lista_finanzas)
	_lista_finanzas.add_child(HSeparator.new())

	## Otra pieza que ya funcionaba y no se veía: `cobrar_plusvalias()` corre
	## sola cada temporada -Mundo.nueva_temporada()-, pero el porcentaje que te
	## guardaste al vender no aparecía en ningún sitio hasta que se cobraba solo.
	if mundo.cesiones != null and not mundo.cesiones.plusvalias.is_empty():
		var tpv := _texto(11, COL_SUAVE)
		tpv.text = "PLUSVALÍAS PENDIENTES"
		_lista_finanzas.add_child(tpv)
		for pv: Dictionary in mundo.cesiones.plusvalias:
			if String(pv.get("beneficiario", "")) != c.id:
				continue
			var jact: Jugador = mundo.jugador_por_id(String(pv.get("pid", "")))
			var detalle := "ya no está en el mundo"
			if jact != null:
				var club_hoy: Club = mundo.clubes.get(jact.club_id)
				detalle = "hoy en %s · vale %s" % [club_hoy.nombre if club_hoy else "?", _dinero(jact.valor)]
			_dato("%s  (%d%%)" % [String(pv.get("nombre", "")), int(pv.get("pct", 0))], detalle, COL_SUAVE, _lista_finanzas)
		_lista_finanzas.add_child(HSeparator.new())

	var libro := mundo.libro_financiero
	var tm := _texto(11, COL_SUAVE)
	tm.text = "LIBRO DE MOVIMIENTOS  ·  últimos %d" % libro.size()
	_lista_finanzas.add_child(tm)
	if libro.is_empty():
		var vacio := _texto(12, COL_SUAVE)
		vacio.text = "Todavía no hay movimientos aparte de la taquilla y los sueldos. Ficha, cede, contrata staff o levanta un título: todo lo que mueve la caja por fuera de la semana normal queda anotado aquí."
		vacio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_finanzas.add_child(vacio)
		return
	for i in range(libro.size() - 1, -1, -1):
		var mov: Dictionary = libro[i]
		var monto := int(mov.get("monto", 0))
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		_lista_finanzas.add_child(fila)
		var et := _texto(11, COL_SUAVE)
		et.text = "S%d/%d" % [int(mov.get("semana", 0)), int(mov.get("anio", 0))]
		et.custom_minimum_size = Vector2(50, 0)
		fila.add_child(et)
		var co := _texto(12, COL_TEXTO)
		co.text = String(mov.get("concepto", ""))
		co.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		co.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fila.add_child(co)
		var va := _texto(12, COL_VERDE if monto >= 0 else COL_ROJO)
		va.text = ("+" if monto > 0 else "") + _dinero(monto)
		fila.add_child(va)

## `vCamarin()` del HTML: clanes, salud mental y jerarquía interna. Toda la
## maquinaria -`Vestuario.camarillas`, `mente()`/`ansiedad()`, `mediar()`,
## `dar_terapia()`, `descanso_mental()`- ya estaba escrita y probada -la
## ansiedad ya se movía sola cada semana con `_proceso_mental()`, y `mediar()`
## ya la bajaba de verdad-, pero no había ni una fila en ningún sitio del
## juego que la enseñara: la nota de esta sesión que decía "la ansiedad no
## está portada" (escrita al tocar Ojeadores y la mesa de negociación) estaba
## mal -no se había mirado con suficiente cuidado-, y queda corregida aquí.
func _pintar_camarin(c: Club) -> void:
	_limpiar(_lista_camarin)
	var v := mundo.vestuario
	if v == null:
		return
	## LAS CÁMARAS. Si aceptaste el documental, el vestuario está grabado y a la
	## gente le incomoda. Va lo primero porque explica caídas de moral que si no
	## parecerían salidas de la nada.
	if mundo.prensa != null and mundo.prensa.hay_camaras():
		var cam := _texto(12, COL_ORO)
		cam.text = "🎥 Hay cámaras en el vestuario %d semana(s) más. A los más sensibles del plantel les incomoda." % mundo.prensa.semanas_documental
		cam.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_camarin.add_child(cam)
	var pl := c.plantilla
	var moral := 60
	var ansi := 0
	if not pl.is_empty():
		var sm := 0
		var sa := 0
		for j in pl:
			sm += j.moral
			sa += v.ansiedad(j)
		moral = int(round(float(sm) / float(pl.size())))
		ansi = int(round(float(sa) / float(pl.size())))
	var cap: Jugador = null
	for j in pl:
		if j.capitan:
			cap = j
			break

	var t := _texto(11, COL_SUAVE)
	t.text = "CLIMA DEL VESTUARIO"
	_lista_camarin.add_child(t)
	var gr := GridContainer.new()
	gr.columns = 4
	gr.add_theme_constant_override("h_separation", 14)
	_lista_camarin.add_child(gr)
	for par in [["Moral media", str(moral)], ["Ansiedad media", str(ansi)],
			["Capitán", _apellido(cap.nombre) if cap else "—"], ["Grupos", str(v.camarillas.size())]]:
		var col := VBoxContainer.new()
		gr.add_child(col)
		var et := _texto(10, COL_SUAVE)
		et.text = String(par[0])
		col.add_child(et)
		var va := _texto(15, COL_ROJO if (String(par[0]) == "Ansiedad media" and ansi > 50) else COL_TEXTO)
		va.text = String(par[1])
		col.add_child(va)
	_lista_camarin.add_child(HSeparator.new())

	var tc := _texto(11, COL_SUAVE)
	tc.text = "CLANES Y CAMARILLAS"
	_lista_camarin.add_child(tc)
	if v.camarillas.is_empty():
		var vc := _texto(12, COL_SUAVE)
		vc.text = "Todavía no hay grupos definidos en el vestuario."
		_lista_camarin.add_child(vc)
	for cl: Dictionary in v.camarillas:
		var humor := int(cl.get("humor", 0))
		var lider: Jugador = mundo.jugador_por_id(String(cl.get("lider", "")))
		var miembros: Array = cl.get("miembros", [])
		var en_mi_club := 0
		var nombres: Array[String] = []
		for id in miembros:
			var jm := mundo.jugador_por_id(String(id))
			if jm != null and jm.club_id == c.id:
				en_mi_club += 1
				if nombres.size() < 7:
					nombres.append(_apellido(jm.nombre))
		var estado_txt := "enojados" if humor < -25 else ("contentos" if humor > 15 else "neutrales")
		var estado_col := COL_ROJO if humor < -25 else (COL_VERDE if humor > 15 else COL_ORO)
		var fila := VBoxContainer.new()
		_lista_camarin.add_child(fila)
		var cab := HBoxContainer.new()
		cab.add_theme_constant_override("separation", 8)
		fila.add_child(cab)
		var nom := _texto(12, COL_TEXTO)
		nom.text = "%s  ·  %d jugador%s" % [String(cl.get("nombre", "")), en_mi_club, "" if en_mi_club == 1 else "es"]
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cab.add_child(nom)
		var et2 := _texto(11, estado_col)
		et2.text = estado_txt
		cab.add_child(et2)
		var lid := _texto(11, COL_SUAVE)
		lid.text = "Líder: %s  ·  %s" % [lider.nombre if lider else "—", ", ".join(nombres)]
		lid.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fila.add_child(lid)
		if humor < -10:
			var cid := String(cl.get("id", ""))
			_boton("🕊️ Mediar con el grupo", func() -> void: _mediar_clan(cid), fila)
		_lista_camarin.add_child(HSeparator.new())

	var en_riesgo: Array[Jugador] = []
	for j in pl:
		if v.ansiedad(j) >= 48:
			en_riesgo.append(j)
	en_riesgo.sort_custom(func(a: Jugador, b: Jugador) -> bool: return v.ansiedad(a) > v.ansiedad(b))
	var tm := _texto(11, COL_SUAVE)
	tm.text = "🧠 SALUD MENTAL"
	_lista_camarin.add_child(tm)
	if en_riesgo.is_empty():
		var vm := _texto(12, COL_SUAVE)
		vm.text = "Nadie está pasándolo mal ahora mismo."
		_lista_camarin.add_child(vm)
	for j: Jugador in en_riesgo:
		var est: Dictionary = v.estado_mental(j)
		var filaj := HBoxContainer.new()
		filaj.add_theme_constant_override("separation", 8)
		_lista_camarin.add_child(filaj)
		var nomj := _texto(12, COL_TEXTO)
		nomj.text = "%s  ·  %s  ·  %d años" % [j.nombre, j.pos_e, j.edad]
		nomj.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		filaj.add_child(nomj)
		var etj := _texto(11, Color(String(est.get("color", "#8ea595"))))
		etj.text = "%s  %d" % [String(est.get("txt", "")), v.ansiedad(j)]
		filaj.add_child(etj)
		_boton("Terapia", func() -> void: _dar_terapia_mental(j), filaj)
		_boton("Descanso mental", func() -> void: _pedir_descanso_mental(j), filaj)
	_lista_camarin.add_child(HSeparator.new())

	var th := _texto(11, COL_SUAVE)
	th.text = "JERARQUÍA INTERNA"
	_lista_camarin.add_child(th)
	var jerarquia := pl.duplicate()
	jerarquia.sort_custom(func(a: Jugador, b: Jugador) -> bool:
		var va2 := float(a.ovr) + float(a.edad) * 1.6 + (25.0 if a.capitan else 0.0)
		var vb2 := float(b.ovr) + float(b.edad) * 1.6 + (25.0 if b.capitan else 0.0)
		return va2 > vb2)
	for i in mini(10, jerarquia.size()):
		var jj: Jugador = jerarquia[i]
		var etiqueta := "referente" if i < 3 else ("influyente" if i < 6 else "periférico")
		_dato("%d.  %s%s" % [i + 1, "ⓒ " if jj.capitan else "", jj.nombre], "%d  ·  %s" % [jj.ovr, etiqueta], COL_TEXTO, _lista_camarin)

func _mediar_clan(clan_id: String) -> void:
	var r := mundo.vestuario.mediar(clan_id)
	var ok := bool(r.get("ok", false))
	_escribir("[color=%s]%s[/color]" % ["#4caf6d" if ok else "#e05555", String(r.get("txt", ""))])
	_refrescar()

func _dar_terapia_mental(j: Jugador) -> void:
	var problema := mundo.vestuario.dar_terapia(j)
	if problema != "":
		_escribir("[color=#e05555]No se pudo dar terapia: %s.[/color]" % problema)
		return
	_escribir("[color=#4caf6d]Terapia deportiva para %s.[/color]" % j.nombre)
	_refrescar()

func _pedir_descanso_mental(j: Jugador) -> void:
	var problema := mundo.vestuario.descanso_mental(j)
	if problema != "":
		_escribir("[color=#e05555]No se pudo dar descanso: %s.[/color]" % problema)
		return
	_refrescar()

func _ceder_canterano(j: Jugador) -> void:
	var r := mundo.cesiones.ceder_canterano(j)
	if r.has("error"):
		_escribir("[color=#e05555]No se puede ceder: %s.[/color]" % String(r["error"]))
		return
	_escribir("[color=#4caf6d]%s sale cedido[/color] a %s." % [j.nombre, (r["destino"] as Club).nombre])
	_refrescar()

func _ceder_con_opcion(j: Jugador, tipo: String) -> void:
	var r := mundo.cesiones.ceder_con_opcion(j, tipo)
	if r.has("error"):
		_escribir("[color=#e05555]No se puede ceder: %s.[/color]" % String(r["error"]))
		return
	_escribir("[color=#4caf6d]%s sale cedido[/color] a %s." % [j.nombre, (r["destino"] as Club).nombre])
	_refrescar()

func _pactar_clausula_propia(j: Jugador) -> void:
	var ya_tenia := mundo.cesiones.clausula_de(j) > 0
	var monto := mundo.cesiones.blindar(j) if ya_tenia else mundo.cesiones.pactar_clausula(j)
	_escribir("[color=#4caf6d]Cláusula %s para %s:[/color] %s." % [
		"reforzada" if ya_tenia else "pactada", j.nombre, _dinero(monto)])
	_refrescar()

## LA EQUIPACIÓN: la camiseta real si el club tiene una de las 1.102 que
## trajo el usuario, o el dibujo de siempre si no. Es la primera vez que
## cualquiera de las dos aparece en la interfaz 2D -hasta hoy solo el visor
## 3D las usaba, y solo la real, nunca el respaldo procedural.
func _pintar_equipacion(c: Club) -> void:
	_lista_club.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = "EQUIPACIÓN"
	_lista_club.add_child(t)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	_lista_club.add_child(fila)
	var hay_real := Jersey.textura_real(c, 0) != null
	## EL SPONSOR A PECHO. `Jersey.svg_de()` ya tenía un parámetro `sp` para
	## esto desde que se escribió, pero nunca se llegó a leer -"el rasterizador
	## no pinta <text>, va encima como etiqueta de Godot" decía su propio
	## comentario, y esa etiqueta nunca se puso-. Ahora que existe `Marca` (el
	## logo real del sponsor, no solo su nombre) hay algo real que superponer:
	## el escudo del sponsor firmado, centrado sobre la camiseta procedural.
	## Solo tiene sentido en el dibujo procedural -una foto real de la
	## camiseta YA trae el sponsor de verdad impreso en la foto-.
	var auspicio := mundo.auspicio if mundo != null else null
	var contrato: Dictionary = auspicio.contrato if auspicio != null else {}
	for cual in 2:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		fila.add_child(col)
		var caja := Control.new()
		caja.custom_minimum_size = Vector2(72, 58)
		col.add_child(caja)
		var img := TextureRect.new()
		img.texture = Jersey.textura(c, cual, 128)
		img.set_anchors_preset(Control.PRESET_FULL_RECT)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		caja.add_child(img)
		if not hay_real and not contrato.is_empty():
			var logo := TextureRect.new()
			logo.texture = Marca.textura(String(contrato.get("marca", "")), String(contrato.get("color", "#e8b13a")), 24)
			logo.custom_minimum_size = Vector2(15, 15)
			logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
			## Centrado en el pecho de la camiseta -el dibujo de Jersey ocupa
			## el viewBox 64x52 centrado en la caja de 72x58, así que el pecho
			## cae un poco a la derecha y abajo del centro geométrico de la
			## caja entera.
			logo.set_anchors_preset(Control.PRESET_CENTER)
			logo.offset_left = -7.5; logo.offset_right = 7.5
			logo.offset_top = 3.0; logo.offset_bottom = 18.0
			caja.add_child(logo)
		var et := _texto(10, COL_SUAVE)
		et.text = "Titular" if cual == 0 else "Alternativa"
		et.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(et)
	var nota := _texto(11, COL_SUAVE if hay_real else COL_BORDE)
	nota.text = "Foto real del club." if hay_real else "Sin foto real para este club: dibujo por color y estampado (%s)." % Jersey.kit_de(c)
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_club.add_child(nota)
	## Aquí solo se MIRA. El editor de verdad -diseño, colores, tela- vive en
	## Gente → Identidad, junto al escudo: es la misma pantalla que antes vivía
	## sin relación bajo "Comercial", movida el 10-9-2026 para que quien busque
	## "cambiar la camiseta" la encuentre en un solo sitio.
	var ir := Button.new()
	ir.text = "🎨 Editar en Identidad"
	ir.add_theme_font_size_override("font_size", 11)
	ir.pressed.connect(func() -> void:
		_secc_gente = "identidad"
		_ir_a_pestana("Gente"))
	_lista_club.add_child(ir)

## EL CARGO: qué eres en este club y qué te dejan tocar.
##
## Se pinta como una lista de permisos en verde y rojo, no como un párrafo. Un
## rol se entiende por lo que te prohíbe, y verlo de un vistazo evita que el
## jugador pulse botones que no van a hacer nada.
## `vDespachoTactica()` del HTML: lo que le PIDES al entrenador cuando el banco
## no es tuyo. `Roles.dt_empleado` existía con su sintonía y su confianza, y no
## había forma de decirle nada: dirigías un club sin poder opinar sobre el once.
##
## Lo que lo hace una decisión y no una lista de deseos: **te hace caso según la
## sintonía, y cada indicación la desgasta**. Puedes dirigir sin dirigir, pero
## se paga en relación.
func _pintar_directrices(r: Roles) -> void:
	if r.dt_empleado.is_empty():
		return
	_lista_club.add_child(HSeparator.new())
	var es_ayudante := r.rol == Roles.AYUDANTE
	var t := _texto(11, COL_SUAVE)
	t.text = "🧢 TRABAJAS PARA ÉL" if es_ayudante else "🪑 EL BANCO NO ES TUYO"
	_lista_club.add_child(t)
	var quien := _texto(13, COL_TEXTO)
	quien.text = "%s  ·  estilo %s" % [r.dt_nombre(), String(r.dt_empleado.get("estilo", ""))]
	_lista_club.add_child(quien)
	var sin := int(r.dt_empleado.get("confianza", 45)) if es_ayudante else int(r.dt_empleado.get("sintonia", 60))
	_dato("Confianza que tiene en ti" if es_ayudante else "Sintonía contigo", "%d / 100" % sin,
		COL_ROJO if sin < 30 else (COL_ORO if sin < 60 else COL_VERDE), _lista_club)
	var aviso_caso := _texto(11, COL_SUAVE)
	aviso_caso.text = "Cada indicación que le das desgasta la relación. Con la sintonía baja, hace lo que le da la gana."
	aviso_caso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_club.add_child(aviso_caso)

	var te := _texto(11, COL_SUAVE)
	te.text = "CÓMO QUIERES QUE JUEGUE"
	_lista_club.add_child(te)
	var fila_e := HBoxContainer.new()
	fila_e.add_theme_constant_override("separation", 6)
	_lista_club.add_child(fila_e)
	for est: Array in Roles.ESTILOS_DEF:
		var clave := String(est[0])
		var be := Button.new()
		be.text = String(est[1])
		be.toggle_mode = true
		be.button_pressed = String(r.directrices.get("estilo", "equilibrio")) == clave
		be.add_theme_font_size_override("font_size", 11)
		be.pressed.connect(func() -> void: _fijar_directriz("estilo", clave))
		fila_e.add_child(be)

	for dd: Array in Roles.DIRECTRICES_DEF:
		var clave2 := String(dd[0])
		var activa := bool(r.directrices.get(clave2, false))
		var fila_d := HBoxContainer.new()
		fila_d.add_theme_constant_override("separation", 8)
		_lista_club.add_child(fila_d)
		var ld := _texto(12, COL_TEXTO if activa else COL_SUAVE)
		ld.text = String(dd[1])
		ld.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila_d.add_child(ld)
		var bd := Button.new()
		bd.text = "SÍ" if activa else "NO"
		bd.add_theme_font_size_override("font_size", 11)
		bd.pressed.connect(func() -> void: _fijar_directriz(clave2, not activa))
		fila_d.add_child(bd)
		var dsc := _texto(10, COL_SUAVE)
		dsc.text = String(dd[2])
		dsc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_club.add_child(dsc)

## La queja del entrenador no se escribe aquí: `fijar_directriz()` desgasta la
## relación y, si se rompe, sale por `roles.aviso`, que ya está conectada.
func _fijar_directriz(clave: String, valor: Variant) -> void:
	mundo.roles.fijar_directriz(clave, valor)
	_refrescar()

func _pintar_rol() -> void:
	_lista_club.add_child(HSeparator.new())
	var r := mundo.roles
	if r == null:
		return
	_pintar_directrices(r)
	var t := _texto(11, COL_SUAVE)
	t.text = "TU CARGO"
	_lista_club.add_child(t)
	var n := _texto(14, COL_ORO)
	n.text = r.nombre_del_cargo().capitalize()
	_lista_club.add_child(n)
	var permisos := {
		"Fichar": r.puede_fichar(),
		"Poner el once": r.puede_alinear(),
		"Contratar cuerpo técnico": r.puede_contratar_staff(),
		"Construir": r.puede_construir(),
		"Vender jugadores": r.puede_vender_jugadores(),
		"Contratar entrenador": r.puede_contratar_dt(),
	}
	for k: String in permisos:
		var l := _texto(12, COL_VERDE if permisos[k] else COL_ROJO)
		l.text = ("sí   " if permisos[k] else "no   ") + k
		_lista_club.add_child(l)
	var bloqueo := r.mercado_bloqueado()
	if bloqueo != "":
		var b := _texto(11, COL_ROJO)
		b.text = bloqueo
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_club.add_child(b)
	_pintar_carrera(r)

## "TU CARRERA" de `vDirectorio()`: el prestigio y la vitrina te siguen de club
## en club -a diferencia de `Directiva.trofeos`, que se quedan en el que
## dejas-, más las dos escaleras (ayudante→DT, DT→director→dueño) y lo que
## trae cada peldaño: un entrenador empleado que puedes cambiar, o -siendo
## dueño- meter capital propio y vender el club. Toda esta lógica ya estaba
## escrita y probada en `Roles`; no había ninguna pantalla que la mostrara.

func _abrir_examen() -> void:
	var ex := ExamenLicencia.mostrar(self, mundo)
	ex.cerrado.connect(_refrescar)

func _abrir_penales() -> void:
	MinijuegoPenales.mostrar(self, mundo)

func _pintar_carrera(r: Roles) -> void:
	PanelAspectoDT.pintar(_lista_club, r, _texto, {"suave": COL_SUAVE, "acento": COL_ACENTO}, _refrescar,
		func() -> void:
			var cp := CreadorPersonaje.abrir(self, mundo)
			cp.cerrado.connect(_refrescar))
	## LA REPUTACIÓN (26-9-2026): nivel del club, tu fama y lo que la movió.
	PanelReputacion.pintar(_lista_club, mundo)
	_lista_club.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE); t.text = "TU CARRERA"
	_lista_club.add_child(t)
	var pres := _texto(14, COL_ORO)
	pres.text = "Prestigio %d/99  ·  %d trofeo(s)  ·  %d temporada(s)" % [r.prestigio, r.trofeos.size(), r.temporadas]
	_lista_club.add_child(pres)
	var barra := ProgressBar.new()
	barra.min_value = 0
	barra.max_value = 99
	barra.value = r.prestigio
	barra.custom_minimum_size = Vector2(0, 14)
	barra.show_percentage = false
	_lista_club.add_child(barra)

	var escalon := r.siguiente_escalon()
	if escalon != "":
		var e := _texto(11, COL_SUAVE)
		e.text = escalon
		e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_club.add_child(e)
	if r.puede_ascender() != "":
		_boton("Ascender a %s" % Roles.PERMISOS[r.puede_ascender()]["cargo"], _ascender_rol, _lista_club)

	if not r.historial.is_empty():
		var h := _texto(11, COL_SUAVE)
		var partes: Array[String] = []
		for paso: Dictionary in r.historial:
			partes.append("%s (hasta %s)" % [String(paso.get("club", "")), str(paso.get("hasta", ""))])
		h.text = "Antes: " + ", ".join(partes)
		h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_club.add_child(h)

	## El entrenador empleado: solo existe si no diriges tú (director, dueño,
	## cantera) o si eres ayudante -ahí es tu jefe, con el mismo diccionario-.
	if not r.dt_empleado.is_empty():
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		_lista_club.add_child(fila)
		var nom := _texto(12, COL_TEXTO)
		if r.es_ayudante():
			nom.text = "Tu jefe: %s  ·  confianza en ti %d/100" % [r.jefe_nombre(), r.jefe_confianza()]
		else:
			## El HTML muestra la clave cruda ("estilo pizarron"), no la frase
			## larga de `DT_ESTILOS` -esa es para otra pantalla-; se capitaliza
			## igual que `nombre_del_cargo()` arriba, no se inventa una frase.
			nom.text = "Entrenador del banco: %s  ·  estilo %s" % [
				r.dt_nombre(), String(r.dt_empleado.get("estilo", "")).capitalize()]
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fila.add_child(nom)
		if r.puede_contratar_dt():
			var b := Button.new()
			b.text = "Cambiar  %s" % _dinero(int(Roles.COSTE_CAMBIAR_DT))
			b.add_theme_font_size_override("font_size", 11)
			b.pressed.connect(_cambiar_dt)
			fila.add_child(b)

	if r.puede_inyectar_capital():
		var restantes := r.inyecciones_restantes()
		var bi := Button.new()
		bi.text = "💰 Inyectar %s de tu bolsillo (%d/%d esta temporada)" % [
			_dinero(int(Roles.INYECCION)), Roles.INYECCIONES_POR_TEMPORADA - restantes, Roles.INYECCIONES_POR_TEMPORADA]
		bi.disabled = restantes <= 0
		bi.pressed.connect(_inyectar_capital)
		_lista_club.add_child(bi)
	if r.puede_vender_club():
		var bv := Button.new()
		bv.text = "¿SEGURO? Vender el club" if _confirmar_venta_club else "🏷️ Vender el club"
		bv.pressed.connect(_vender_club)
		_lista_club.add_child(bv)

## El mensaje de éxito no se escribe aquí -ya lo hacen `roles.aviso` y
## `roles.ascenso`/`sin_banco`, conectados una sola vez en `_conectar_noticias()`-;
## este método solo se ocupa de sacar a pantalla el motivo cuando falla.
func _ascender_rol() -> void:
	var problema := mundo.roles.ascender()
	if problema != "":
		_escribir("[color=#e05555]%s[/color]" % problema)
		return
	_refrescar()

func _cambiar_dt() -> void:
	var problema := mundo.roles.cambiar_dt()
	if problema != "":
		_escribir("[color=#e05555]No se pudo cambiar de entrenador: %s.[/color]" % problema)
		return
	_refrescar()

func _inyectar_capital() -> void:
	var problema := mundo.roles.inyectar_capital()
	if problema != "":
		_escribir("[color=#e05555]%s.[/color]" % problema)
		return
	_refrescar()

func _vender_club() -> void:
	if not _confirmar_venta_club:
		_confirmar_venta_club = true
		_refrescar()
		return
	_confirmar_venta_club = false
	var problema := mundo.roles.vender_club()
	if problema != "":
		_escribir("[color=#e05555]%s.[/color]" % problema)
	_refrescar()

# ---------------------------------------------------------------------------
#  HANDLERS DE SEÑALES — PanelMercado
#  Los conecta _construir(); los ejecuta Principal porque son los únicos
#  que tienen acceso a `mundo` para modificarlo.
# ---------------------------------------------------------------------------

## Ajusta el rol prometido en la negociación activa. La señal `"__clausula__"`
## es el caso especial de alternar la cláusula de rescisión.
func _al_ajustar_rol_neg(rol: String) -> void:
	if mundo == null or mundo.mercado.negociacion == null:
		return
	if rol == "__clausula__":
		mundo.mercado.negociacion.alternar_clausula()
	else:
		mundo.mercado.negociacion.ajustar_rol(rol)
	_refrescar()

## Ajusta un campo numérico de la negociación activa (fijo, cuotas, bonos…).
func _al_ajustar_campo_neg(campo: String, delta: int) -> void:
	if mundo == null or mundo.mercado.negociacion == null:
		return
	mundo.mercado.negociacion.ajustar(campo, delta)
	_refrescar()

## Responde a una oferta de compra RECIBIDA (otro club quiere a uno de los
## tuyos). Nombre distinto al de la negociación saliente para no colisionar
## con la firma de `_abrir_negociacion()`.
func _responder_oferta_mercado(indice: int, aceptar: bool) -> void:
	if mundo == null:
		return
	if indice < 0 or indice >= mundo.mercado.ofertas_recibidas.size():
		return
	var o: Dictionary = mundo.mercado.ofertas_recibidas[indice]
	var j: Jugador    = o["jugador"]
	var co: Club      = o.get("club")
	if aceptar:
		mundo.mercado.aceptar_oferta(indice)
		_escribir("[color=#4caf6d]Venta cerrada:[/color] %s a %s por %s." % [
			j.nombre,
			co.nombre if co else "?",
			_dinero(int(o["monto"]))])
	else:
		mundo.mercado.rechazar_oferta(indice)
		_escribir("Oferta por %s rechazada." % j.nombre)
	_refrescar()
