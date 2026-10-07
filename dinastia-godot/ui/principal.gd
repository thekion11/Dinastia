class_name Principal
extends Control

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
	_panel_mercado.fichar_pedido.connect(_ui_plantel._abrir_negociacion)
	_panel_mercado.oferta_respondida.connect(_responder_oferta_mercado)
	_panel_mercado.oferta_enviada.connect(_enviar_oferta_negociacion)
	_panel_mercado.negociacion_cancelada.connect(_ui_plantel._cancelar_negociacion)
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
	_col_derecha = der
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

	## EL PANEL LATERAL (mapa de metas 23): a la izquierda y por encima del menú
	## central; el contenido se corre lo que mide el riel para no quedar tapado.
	raiz.offset_left = 18.0 + MenuLateral.ANCHO_RIEL
	_menu_lateral = MenuLateral.crear(self)
	add_child(_menu_lateral)
	_reloj_diseno = Timer.new()
	_reloj_diseno.wait_time = ROTAR_CADA
	_reloj_diseno.autostart = true
	_reloj_diseno.timeout.connect(_siguiente_diseno)
	add_child(_reloj_diseno)

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

func _siguiente_diseno() -> void:
	if not _rotar_diseno:
		return
	_diseno_i = (_diseno_i + 1) % DISENOS_CENTRAL.size()
	var d: Array = DISENOS_CENTRAL[_diseno_i]
	## Un fundido corto para que el cambio se lea como una transición y no
	## como un parpadeo.
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(velo)
	var tw := create_tween()
	tw.tween_property(velo, "color:a", 0.55, 0.35)
	tw.tween_callback(func() -> void:
		_paleta = String(d[0])
		_estilo_menu = String(d[1])
		_forma_tarjeta = String(d[2])
		_fondo_elegido = String(d[3])
		_aplicar_aspecto()
		_aplicar_fondo()
		_reconstruir_grupos()
		if mundo != null:
			_refrescar())
	tw.tween_property(velo, "color:a", 0.0, 0.45)
	tw.tween_callback(velo.queue_free)

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
		## Los que ahora tienen menú propio en el panel lateral no se ven arriba
		## (siguen existiendo: la navegación y el tutorial van por índice).
		b.visible = not MenuLateral.EN_PANEL.has(gid)
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
## La columna de la ficha, para mudarla a los menús a pantalla completa.
var _col_derecha: Control
var _menu_lateral: MenuLateral

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
	## Se saltan los grupos que viven en el panel lateral.
	for _k in GRUPOS.size():
		if not MenuLateral.EN_PANEL.has(String(GRUPOS[siguiente]["id"])):
			break
		siguiente = (siguiente + paso + GRUPOS.size()) % GRUPOS.size()
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
	e.border_color = _ui_ajustes._pal_borde()
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
		## FONDO DE INVERSIÓN (26-9-2026): el fondo arranca con su propia caja.
		if Principal.modo_elegido == "fondo" and mundo.mi_club() != null:
			mundo.fondo = FondoInversion.new()
			mundo.fondo.caja = int(round(Eco.ref_caja(70.0) * 2.5))
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
	## Cambios de ley y avisos de la regla de la liga (7-10-2026: la señal
	## existía pero nadie la escuchaba).
	if mundo.contratos != null and not mundo.contratos.noticia.is_connected(_noticia_contratos):
		mundo.contratos.noticia.connect(_noticia_contratos)
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
		for fuente: Object in [mundo.fondo, mundo.redes, mundo.mercado_av, mundo.insolvencia, mundo.trabajadores, mundo.eventos_cantera, mundo.calendario, mundo.politica, mundo.contratos, mundo.vida, mundo.maestria]:
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
		## Fuera del árbol YA, no al final del cuadro: si no, durante ese cuadro
		## hay dos ventanas exclusivas y Godot se queja (visto en el recorrido).
		_dlg_club.exclusive = false
		_dlg_club.hide()
		if _dlg_club.get_parent() != null:
			_dlg_club.get_parent().remove_child(_dlg_club)
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
	## EL DOCUMENTAL (fase 5): se arma ANTES del cierre, que reinicia la tabla
	## y las estadísticas; se proyecta al final del cierre.
	var guion_doc := DocumentalTemporada.guion(mundo)
	if mundo.mercado != null:
		mundo.mercado.fichajes_temporada.clear()
	var resumen := mundo.nueva_temporada()
	if not guion_doc.is_empty():
		(func() -> void: DocumentalTemporada.abrir(self, guion_doc, _retrato)).call_deferred()
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
	_registro.append_text(_bbcode_accesible(_traducir_bbcode(bbcode)) + "\n")

## El registro es texto enriquecido y no pasa por el traductor de etiquetas:
## se traduce cada tramo de texto entre etiquetas BBCode (título y cuerpo de
## la noticia van en tramos distintos).
var _re_tramos_bb: RegEx

func _traducir_bbcode(bb: String) -> String:
	if Idiomas.idioma == "es":
		return bb
	if _re_tramos_bb == null:
		_re_tramos_bb = RegEx.create_from_string("\\]([^\\[]+)")
	var salida := bb
	for m: RegExMatch in _re_tramos_bb.search_all(bb):
		var tramo := m.get_string(1)
		var limpio := tramo.strip_edges()
		if limpio == "":
			continue
		var tr_ := Idiomas.t(limpio)
		if tr_ != limpio:
			salida = salida.replace(tramo, tramo.replace(limpio, tr_))
	return salida

## Complementa a `_escribir()`, no lo reemplaza: `_escribir()` sigue pintando
## el registro exactamente igual que antes -no se le tocó una línea, cero
## riesgo de que una captura ya verificada cambie de aspecto-, esto solo
## archiva la misma noticia en la bandeja de "Correo" para poder filtrarla y
## marcarla leída más tarde.
func _noticia_contratos(titulo: String, cuerpo: String) -> void:
	_escribir("[color=#c9a227][b]%s[/b][/color] %s" % [titulo, cuerpo])
	_anotar(titulo, cuerpo)

func _anotar(titulo: String, cuerpo: String) -> void:
	_bandeja.push_front({"titulo": titulo, "cuerpo": cuerpo, "semana": mundo.semana, "anio": mundo.anio, "leida": false})
	## Lo que pasa también se comenta en Tribuna (las redes del móvil).
	if mundo.redes != null:
		mundo.redes.desde_noticia(mundo, titulo, cuerpo)
	## Y si es cosa de alguien (la directiva, la familia...), te escribe.
	if mundo.movil != null:
		var de := Movil.remitente_de(titulo, cuerpo)
		if not de.is_empty():
			mundo.movil.recibir(String(de[0]), String(de[1]), "%s %s" % [titulo, cuerpo], mundo.anio, mundo.semana)
	if _bandeja.size() > BANDEJA_MAX:
		_bandeja.resize(BANDEJA_MAX)

# --- pintado ----------------------------------------------------------------

var _panel_obj: PanelObjetivos

## PINTAR SOLO LO QUE SE VE (29-9-2026, auditoría). `_refrescar` repintaba las
## ~40 pantallas del juego en cada clic, se vieran o no: 2-4 segundos por
## refresco medidos sin gráfica (entrenamiento 0,5 s, estadio 0,4 s, ficha
## 0,4 s...). Ahora las pestañas que no están a la vista quedan PENDIENTES y se
## pintan el cuadro en que aparecen (`_process`). `pintar_todo` lo desactiva.
var pintar_todo := false
var _pendientes := {}   ## Control -> Callable

func _perezoso(cont: Control, pintar: Callable) -> void:
	if pintar_todo or cont == null or not cont.is_inside_tree() or cont.is_visible_in_tree():
		_pendientes.erase(cont)
		pintar.call()
	else:
		_pendientes[cont] = pintar

func _pintar_pendientes() -> void:
	for cont: Variant in _pendientes.keys():
		if not is_instance_valid(cont):
			_pendientes.erase(cont)
			continue
		var ctl := cont as Control
		if ctl.is_visible_in_tree():
			var pintar: Callable = _pendientes[cont]
			_pendientes.erase(cont)
			pintar.call()
			_traducir_pantalla(ctl)

func _process(_d: float) -> void:
	if not _pendientes.is_empty():
		_pintar_pendientes()

func _refrescar() -> void:
	var c := mundo.mi_club()
	## Los objetivos, fijos en el borde derecho (PanelObjetivos).
	if not is_instance_valid(_panel_obj):
		_panel_obj = PanelObjetivos.crear(self, mundo.roles.modo_actual() if mundo.roles != null else "dt")
		add_child(_panel_obj)
	_panel_obj.refrescar()
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
	_ui_plantel._pintar_plantel(c)
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
	_perezoso(_lista_copa, _ui_plantel._pintar_copa.bind(c))
	_perezoso(_lista_club, _ui_ficha._pintar_club.bind(c))
	_perezoso(_lista_conti, _ui_club_vida._pintar_conti.bind(c))
	_perezoso(_lista_medico, _ui_club_vida._pintar_medico.bind(c))
	_perezoso(_lista_logros, _ui_club_vida._pintar_logros)
	_perezoso(_lista_entren, _ui_club_vida._pintar_entrenamiento.bind(c))
	_perezoso(_lista_fed, _pintar_federacion.bind(c))
	_perezoso(_lista_estadio, _pintar_estadio.bind(c))
	_perezoso(_lista_seleccion, _ui_cantera._pintar_seleccion.bind(c))
	_perezoso(_lista_cantera, _ui_cantera._pintar_cantera.bind(c))
	_perezoso(_lista_contratos, _ui_cantera._pintar_contratos.bind(c))
	_perezoso(_lista_comparar, _ui_cantera._pintar_comparar)
	_perezoso(_lista_records, func() -> void:
		_ui_legado._pintar_records()
		_ui_legado._filtrar_records())
	_perezoso(_lista_legado, _ui_legado._pintar_legado)
	_ui_legado._pintar_inicio(c)
	## Las otras tres viven DENTRO de `_pintar_gente()` ahora -un chip por
	## sección, solo se pinta la que está activa- en vez de apilarse las
	## cuatro siempre, aunque solo una se vea.
	_perezoso(_lista_gente, _ui_gente._pintar_gente)
	_perezoso(_lista_finanzas, _pintar_finanzas.bind(c))
	_perezoso(_lista_camarin, _pintar_camarin.bind(c))
	_perezoso(_lista_ciudad, _pintar_ciudad.bind(c))
	_perezoso(_lista_editor, _ui_editor._pintar_editor)
	_perezoso(_lista_glosario, _ui_opciones._pintar_glosario)
	_perezoso(_lista_ajustes, _ui_ajustes._pintar_ajustes)
	_perezoso(_lista_correo, _ui_gente._pintar_correo)
	_perezoso(_lista_redes, func() -> void:
		_ui_gente._pintar_redes()
		_ui_gente._filtrar_redes())
	_ui_legado._pintar_vida()
	_ui_legado._pintar_habilidades()
	_perezoso(_lista_libres, _ui_plantel._pintar_libres.bind(c))
	_perezoso(_lista_premios, _ui_plantel._pintar_premios)
	_perezoso(_lista_clubes, _pintar_clubes)
	_perezoso(_lista_desafios, _ui_plantel._pintar_desafios)
	_perezoso(_lista_tactica, _ui_plantel._pintar_tactica.bind(c))
	_perezoso(_lista_partido, _ui_plantel._pintar_partido.bind(c))
	_perezoso(_lista_calendario, _ui_plantel._pintar_calendario.bind(c))
	_pintar_dias()
	_actualizar_badges()
	_ui_despacho._pintar_despacho()
	_ver_ficha(_seleccionado if _seleccionado != null else _jugador_de_la_semana(c))
	## LO ÚLTIMO DE TODO: traducir. Ver `nucleo/idiomas.gd` -la interfaz se pinta
	## siempre en castellano y se traduce al final, para no tener que marcar dos
	## mil cadenas con `tr()` en un archivo de diez mil líneas-.
	_traducir_pantalla(self)
	## Y la música, que también depende de lo que esté pasando.
	Musica.ambientar(_ui_opciones._situacion_musical())

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
	_ui_plantel._pintar_rivalidades()

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
		_ui_plantel._pintar_ficha_club(_clubes_ficha)
	_ui_plantel._pintar_goleadores(_clubes_pais)

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

func _ver_ficha(j: Jugador) -> void:
	if j == null or (_seleccionado != null and j.id != _seleccionado.id):
		_confirmar_rescision_id = ""
	_seleccionado = j
	## La pestaña Entrenar muestra el árbol de habilidades DEL SELECCIONADO, pero
	## no pasa por aquí cuando se pulsa una fila del plantel -eso llama solo a
	## _ver_ficha(), no a _refrescar()-, así que sin esto el árbol se quedaba con
	## el jugador anterior hasta la siguiente semana.
	## Diferido (29-9-2026): solo se repinta si la pestaña está a la vista; si
	## no, al abrirla. Era 0,3-0,5 s en cada clic de la ficha.
	_perezoso(_lista_entren, _ui_club_vida._pintar_entrenamiento.bind(mundo.mi_club()))
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
		FichaJugadorInfo.pintar_ciega(_ficha, j, mundo, _ui_ficha._paleta_ficha())
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
		bo.pressed.connect(func() -> void: _ui_ficha._pedir_informe_ojeo(j))
		_ficha.add_child(bo)

	## compararJug(pid) del HTML: funciona igual para un jugador propio que
	## ajeno -por eso va aquí, antes de que la ficha se bifurque-.
	var en_comparador := _comparar_ids.has(j.id)
	var bc2 := Button.new()
	bc2.text = "Quitar del comparador" if en_comparador else "Comparar"
	bc2.disabled = not en_comparador and _comparar_ids.size() >= 3
	bc2.pressed.connect(func() -> void: _ui_cantera._alternar_comparar(j))
	_ficha.add_child(bc2)

	if propio:
		var pal := _ui_ficha._paleta_ficha()
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
	var pal_ajeno := _ui_ficha._paleta_ficha()
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
		_boton("Negociar en la mesa", func() -> void: _ui_plantel._abrir_negociacion(j), fila)
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
			bc.pressed.connect(func() -> void: _ui_ficha._pagar_clausula(j))
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

func _dinero(n: int) -> String:
	return Eco.dinero(n)

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

## LA INFRAESTRUCTURA: las obras del club y la equipación que se ve en el
## campo. Lo que se construye, no lo que se contrata.
func _club_infra(c: Club) -> void:
	_ui_club_vida._pintar_obras(c)
	_pintar_equipacion(c)

## MI CARRERA: qué eres en este club, qué te dejan tocar y qué llevas hecho.
## `_pintar_rol()` ya llama a `_pintar_carrera(r)` por dentro: aquí no se
## vuelve a llamar o saldría dos veces.
func _club_carrera(_c: Club) -> void:
	_ui_finanzas._pintar_rol()

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

func _pintar_decision(e: Dictionary) -> void:
	var v := _ui_despacho._marco_aviso(COL_ORO)
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

	raiz.add_child(_ui_despacho._fila_posturas())
	_rueda_opciones = _ui_despacho._fila_opciones_rueda(e)
	raiz.add_child(_rueda_opciones)
	raiz.add_child(_ui_despacho._fila_texto_libre())
	## EL RELOJ DE LA SALA (B5, "lenguaje corporal"): una barra que se llena en
	## `Prensa.TITUBEO_SEG` segundos. Cuando se llena, contestar ya cuenta como
	## titubeo. Se ve para que no sea una trampa.
	var reloj := ProgressBar.new()
	reloj.show_percentage = false
	reloj.custom_minimum_size = Vector2(0, 6)
	reloj.max_value = Prensa.TITUBEO_SEG
	raiz.add_child(reloj)
	_rueda_reloj = reloj
	_ui_despacho._pintar_pregunta_rueda(e)

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
	raiz.add_child(_ui_despacho._fila_posturas())
	raiz.move_child(raiz.get_child(raiz.get_child_count() - 1), 2)

func _responder(i: int) -> void:
	_ui_despacho._tras_responder(mundo.prensa.responder(i, _ui_despacho._segundos_rueda()))

# --- las tres pestañas nuevas ----------------------------------------------

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
	_ui_club_vida._pintar_gobierno(c)
	_ui_club_vida._pintar_licencia_y_tribunal(c, f)
	_ui_club_vida._pintar_historial_federacion(f)
	var t := _texto(11, COL_SUAVE)
	t.text = "REGLAMENTO VIGENTE"
	_lista_fed.add_child(t)
	for regla in f.reglas_vigentes(c.pais if c != null else ""):
		var l := _texto(12, COL_TEXTO)
		l.text = "· " + String(regla)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_fed.add_child(l)
	## CUMPLIR O INCUMPLIR LAS REGLAS DE LA LIGA (7-10-2026): una decisión
	## del club, con su precio.
	if c != null:
		var inf: Dictionary = f.infracciones_de(mundo.anio)
		var est := _texto(12, COL_SUAVE)
		est.text = "Política con el reglamento: %s · esta temporada: %d semana(s) con el plantel fuera de cupo, %d alineación(es) indebida(s)" % [
			"CUMPLIR (el once se corrige solo)" if c.ley_politica == "cumplir" else "INCUMPLIR (pagas multas; a la tercera alineación indebida, 3 puntos menos cada vez)",
			int(inf.get("plantel", 0)), int(inf.get("alin", 0))]
		est.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_fed.add_child(est)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		for op: Array in [["cumplir", "✅ Cumplir el reglamento"], ["incumplir", "⚠️ Incumplir y asumir multas"]]:
			var bt := Button.new()
			bt.text = String(op[1])
			bt.toggle_mode = true
			bt.button_pressed = c.ley_politica == String(op[0])
			var valor := String(op[0])
			bt.pressed.connect(func() -> void:
				c.ley_politica = valor
				_pintar_federacion(c))
			fila.add_child(bt)
		_lista_fed.add_child(fila)

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
	_ui_club_estadio._pintar_estilos_estadio(c)
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
	_ui_club_vida._pintar_hinchada(c)
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
			["LA ESTRUCTURA", ["forma", "fachada", "fachadaCol", "techo", "techoCol", "focos", "luzFocos", "focosCol", "pantalla"]],
			["EL CAMPO", ["superficie", "cesped", "cespedTono", "lineaCol", "arcoCol", "redCol", "redTipo"]],
			["LA GRADA", ["asientoP", "banderas", "escudoDonde", "corner"]],
			## Sin "clima" (26-9-2026): el tiempo lo pone la ciudad, no el
			## diseñador. Elegir "lluvia" como se elige un color era ilógico.
			["LOS DETALLES", ["banquillo", "banquilloCol", "vallaCol", "ledPaleta", "ledFondo", "ledTinta", "tunel", "sonidoGol"]],
		]:
		var tb := _texto(11, COL_ACENTO)
		tb.text = String(bloque[0])
		_lista_estadio.add_child(tb)
		for campo: String in (bloque[1] as Array):
			_ui_club_estadio._fila_diseno_estadio(e, p, campo)

	## LAS TRIBUNAS, cada una con su propio estilo (16-9-2026, Fase 1 de "el
	## estadio por MÓDULOS" del ROADMAP). Con el interruptor apagado -el caso de
	## siempre- esto no pinta nada más que el aviso: activar es el paso que dice
	## "quiero decidir esto tribuna por tribuna" y por eso cuesta.
	_lista_estadio.add_child(HSeparator.new())
	var tt := _texto(11, COL_ACENTO)
	tt.text = "LAS TRIBUNAS"
	_lista_estadio.add_child(tt)
	_ui_club_estadio._fila_interruptor_estadio(e.ajustes, "personalizar_bandejas", "Personalizar cada tribuna",
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
		_ui_club_estadio._fila_diseno_estadio(e, p, "bandeja_%s_asientoP" % _bandeja_actual)
		_ui_club_estadio._fila_diseno_estadio(e, p, "bandeja_%s_techo" % _bandeja_actual)
		_ui_club_estadio._fila_diseno_estadio(e, p, "bandeja_%s_col1" % _bandeja_actual)
		_ui_club_estadio._fila_diseno_estadio(e, p, "bandeja_%s_col2" % _bandeja_actual)
		## Cada anillo de esta tribuna, por separado (28-9-2026).
		for n_an in mini(5, maxi(1, int(p.get("niveles", 1)))):
			_ui_club_estadio._fila_diseno_estadio(e, p, "anillo_%s_%d" % [_bandeja_actual, n_an + 1])

	## LOS TERCIOS: estilos mixtos DENTRO de una misma tribuna (18/22-9-2026,
	## Fase 3 de "el estadio por MÓDULOS", la última de las tres). El spike del
	## 18-9 confirmó que el corte se sostiene visualmente -ver LEEME.md-, esta
	## es la pantalla real. Interruptor PROPIO, independiente del de arriba: se
	## puede mezclar por tercios una tribuna sin haber activado "Personalizar
	## cada tribuna" en ninguna, y viceversa. Reusa el mismo selector
	## `_bandeja_actual` que el bloque de arriba -es la misma pregunta ("¿qué
	## tribuna estoy mirando?") para las dos reformas, no hace falta un
	## segundo estado que se pueda desincronizar del primero.
	_ui_club_estadio._fila_interruptor_estadio(e.ajustes, "personalizar_tramos", "Mezclar patrones por tercios",
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
			_ui_club_estadio._fila_diseno_estadio(e, p, "tramo_%s_%d" % [_bandeja_actual, tercio])

	## Los dos interruptores. No son desplegables y por eso se quedaron fuera
	## del catálogo: la pista de atletismo aleja la grada del campo y le quita
	## ambiente, y las vallas perimetrales son la diferencia entre un recinto de
	## los ochenta y uno moderno. Ambos estaban implementados y sin manera de
	## tocarlos.
	_lista_estadio.add_child(HSeparator.new())
	var ti := _texto(11, COL_ACENTO)
	ti.text = "EL RECINTO"
	_lista_estadio.add_child(ti)
	_ui_club_estadio._fila_interruptor_estadio(e.ajustes, "pista", "Pista de atletismo",
		"Aleja la grada del campo: -3,5 de ambiente.")
	_ui_club_estadio._fila_interruptor_estadio(e.ajustes, "vallas", "Vallas perimetrales",
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
	_ui_ciudad._pintar_luces_ciudad(ci)

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

	_ui_ciudad._pintar_terrenos(ci, c)
	_ui_ciudad._pintar_negocios(ci, c)
	_ui_ciudad._pintar_conciertos(ci, c)
	_ui_ciudad._pintar_municipalidad(ci, c)
	_ui_ciudad._pintar_sostenibilidad(ci, c)
	_ui_ciudad._pintar_seguridad(ci, c)

## Mismo motivo y mismo arreglo que `_ver_estadio_propio()`: `VistaCiudad`
## tampoco trae fondo opaco -para que el 3D se vea de verdad-, así que hay
## que esconder el resto de la pantalla mientras está abierta.
## El ídolo del club para la estatua de la ciudad: la última leyenda retirada
## del club; si no hay, el capitán; si no, el de más media.
func _idolo_del_club(c: Club) -> String:
	if mundo.cantera != null:
		for k in range(mundo.cantera.leyendas.size() - 1, -1, -1):
			var L: Dictionary = mundo.cantera.leyendas[k]
			if String(L.get("club_id", "")) == c.id:
				return String(L.get("nombre", ""))
	var mejor: Jugador = null
	for j: Jugador in c.plantilla:
		if j.capitan:
			return j.nombre
		if mejor == null or j.ovr > mejor.ovr:
			mejor = j
	return mejor.nombre if mejor != null else ""

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
	vista.construir = _ui_club_vida._empezar_obra
	var prox := mundo.proximo_partido()
	vista.dia_partido = not prox.is_empty() and prox[0] == c
	vista.animo = CiudadAnimo.de(mundo, c)
	vista.idolo = _idolo_del_club(c)
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
	elif n is LineEdit:
		## El texto de ayuda del campo ("🔎 Buscar..."), no lo que escribe el jugador.
		var le := n as LineEdit
		var actual_ph := le.placeholder_text
		if actual_ph != "":
			var fue_mio_ph: bool = le.has_meta("_i18n_ph_out") and String(le.get_meta("_i18n_ph_out")) == actual_ph
			var base_ph: String = String(le.get_meta("_i18n_ph_src")) if fue_mio_ph else actual_ph
			var nuevo_ph := base_ph if Idiomas.idioma == "es" else Idiomas.t(base_ph)
			le.set_meta("_i18n_ph_src", base_ph)
			le.set_meta("_i18n_ph_out", nuevo_ph)
			le.placeholder_text = nuevo_ph
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
	var borde := _ui_ajustes._pal_borde()
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
	## CON EL PANEL LATERAL ENCIMA (mapa de metas 23) los mismos botones
	## navegan ESE menú y no el central de detrás: L1/R1 pasan de submenú,
	## L2/R2 de menú, y el desliz con el dedo no cambia páginas escondidas.
	if _menu_lateral != null and _menu_lateral.ocupado():
		var pm: PantallaMenu = _menu_lateral.pantalla_abierta if is_instance_valid(_menu_lateral.pantalla_abierta) else null
		if pm != null and evento.is_action_pressed("dinastia_tab_siguiente"):
			pm.submenu_vecino(1)
			get_viewport().set_input_as_handled()
		elif pm != null and evento.is_action_pressed("dinastia_tab_anterior"):
			pm.submenu_vecino(-1)
			get_viewport().set_input_as_handled()
		elif evento.is_action_pressed("dinastia_bloque_siguiente"):
			_menu_lateral.menu_vecino(1)
			get_viewport().set_input_as_handled()
		elif evento.is_action_pressed("dinastia_bloque_anterior"):
			_menu_lateral.menu_vecino(-1)
			get_viewport().set_input_as_handled()
		_arrastre_x = 0.0
		_arrastre_y = 0.0
		return
	## Un desliz que empieza sobre el riel es del panel (abrirlo), no del menú.
	if evento is InputEventScreenDrag and (evento as InputEventScreenDrag).position.x < MenuLateral.ANCHO_RIEL + 30.0:
		return
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

## Los cuatro colores del lienzo. Se leen a través de estas funciones y no de la
## constante para que cambiar de paleta repinte todo de una vez.
func _pal_fondo() -> Color: return _ui_ajustes._color_pal(1, COL_FONDO)
## El panel conserva el 0,94 de opacidad de siempre: es lo que deja ver el
## fondo de pantalla por debajo sin que la tabla pierda contraste.
func _pal_panel() -> Color:
	var c := _ui_ajustes._color_pal(2, COL_PANEL)
	c.a = 0.94
	return c
func _pal_texto() -> Color: return _ui_ajustes._color_pal(4, COL_TEXTO)
func _pal_suave() -> Color: return _ui_ajustes._color_pal(5, COL_SUAVE)

## Repinta el lienzo. Solo hace falta al cambiar de paleta: el resto se aplica
## solo al reconstruir las pantallas.
func _aplicar_aspecto() -> void:
	if _fondo_raiz != null:
		_fondo_raiz.color = _pal_fondo()
	_aplicar_tema()
	_ui_ajustes._repintar_tarjetas(self)

## SACAR Y METER LA PARTIDA. El HTML pegaba el guardado en un `<textarea>` porque
## el navegador no le dejaba tocar el disco. Aquí sí se puede, así que se hacen
## las dos cosas: se escribe un archivo suelto en una carpeta que se puede abrir
## y se copia el mismo contenido al portapapeles, que es lo que hace falta para
## mandárselo a alguien por chat.
const FICHERO_EXPORTADO := "user://dinastia-exportada.txt"

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
	var firma := "%s|%s|%s|%s|%.2f|%s|%.2f|%s|%d|%s|%s|%s|%s|%s|%s|%s|%s|%.2f|%s|%s|%s|%d|%s" % [_paleta, _forma_tarjeta,
		_brillo_tarjetas, _fondo_elegido, _escala_texto, _daltonico, _zoom_interfaz,
		_modo_tv, _fps_elegido, _modo_experto, Sonido.encendido, _clima_elegido,
		_clima_interactivo, _marca_tarjeta, _tipografia, Idiomas.idioma,
		Musica.encendida, Musica.volumen, Musica.pieza, Musica.automatica, _estilo_menu,
		_velocidad_partido, _rotar_diseno]
	firma += "|%s|%s" % [VestidorQ.ropa_aparte, Cara.usar_fotos]
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
	cf.set_value("aspecto", "rotar_diseno", _rotar_diseno)
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
	cf.set_value("pantalla", "caras_foto", Cara.usar_fotos)
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
	_rotar_diseno = bool(cf.get_value("aspecto", "rotar_diseno", true))
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
	Cara.usar_fotos = bool(cf.get_value("pantalla", "caras_foto", Cara.usar_fotos))
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

	_ui_identidad._fila_color_identidad(c, "1 · Color principal del club", "color1")
	_ui_identidad._fila_color_identidad(c, "1 · Color secundario del club", "color2")

	var tk := _texto(11, COL_ACENTO)
	tk.text = "2 · UNIFORME%s" % ("" if c.kit_color1 == "" and c.kit_color2 == "" else "  ·  propio")
	_lista_gente.add_child(tk)
	_ui_identidad._fila_color_identidad(c, "Color 1 de la camiseta", "kit_color1")
	_ui_identidad._fila_color_identidad(c, "Color 2 de la camiseta", "kit_color2")
	_ui_identidad._rejilla_identidad(c, "kit_estilo", Jersey.KITS, "Diseño")
	_ui_identidad._boton_heredar(c, ["kit_color1", "kit_color2"], "Volver a los colores del club")

	var te := _texto(11, COL_ACENTO)
	te.text = "3 · ESCUDO%s" % ("" if c.esc_color1 == "" and c.esc_color2 == "" else "  ·  propio")
	_lista_gente.add_child(te)
	_ui_identidad._fila_color_identidad(c, "Fondo del escudo", "esc_color1")
	_ui_identidad._fila_color_identidad(c, "Borde y patrón", "esc_color2")
	_ui_identidad._rejilla_identidad(c, "esc_forma", Escudo.FORMAS, "Forma")
	_ui_identidad._rejilla_identidad(c, "esc_patron", Escudo.PATRONES, "Patrón interior")
	## "ESC_SIM" del HTML: un emoji en vez de las iniciales. El campo llevaba
	## semanas guardándose -`Club.esc_simbolo` ya viaja en el guardado- sin que
	## `Escudo` lo leyera ni hubiera dónde elegirlo. `Datos.tabla("ESC_SIM")`
	## trae un "" propio en el índice 0 -el mismo "por sorteo" que ya antepone
	## `_rejilla_identidad`-, así que se recorta para no duplicar ese botón.
	var lista_sim: Array = Datos.tabla("ESC_SIM")
	_ui_identidad._rejilla_identidad(c, "esc_simbolo",
		lista_sim.slice(1) if lista_sim != null and lista_sim.size() > 1 else [], "Símbolo (reemplaza las iniciales)")
	if not _modo_experto:
		var ee := _texto(10, COL_SUAVE)
		ee.text = "Veintiseis formas × treinta patrones × dos colores: miles de escudos distintos."
		ee.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_gente.add_child(ee)
	_ui_identidad._boton_heredar(c, ["esc_color1", "esc_color2"], "Volver a los colores del club")
	_ui_identidad._rejilla_especiales(c)

	var tu := _texto(11, COL_ACENTO)
	tu.text = "4 · INTERFAZ%s" % ("" if c.ui_acento == "" else "  ·  propia")
	_lista_gente.add_child(tu)
	_ui_identidad._fila_color_identidad(c, "Color de acento (botones y menú)", "ui_acento")
	_ui_identidad._boton_heredar(c, ["ui_acento"], "Usar el color del club")

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
		_ui_identidad._pintar_kits(mundo.comercial, c)

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
	var pal := _ui_ficha._paleta_ficha()
	PanelFinanzas.pintar_balance_y_caja(_lista_finanzas, c, mundo, proy, pal)
	PanelFinanzas.pintar_auspicio(_lista_finanzas, c, mundo, pal,
		func(idx: int) -> void: _ui_gente._firmar_auspicio(idx))
	PanelFinanzas.pintar_patrocinio(_lista_finanzas, c, mundo, pal,
		func(clave: String) -> void: _ui_gente._lanzar_campana(clave),
		func() -> void: _ui_gente._pujar_marca())
	PanelFinanzas.pintar_banco(_lista_finanzas, c, mundo, pal,
		func(i: int) -> void: _ui_gente._pedir_credito(i, c),
		func(i: int) -> void: _ui_gente._prepagar(i, c),
		func(i: int) -> void: _ui_gente._renegociar(i),
		func() -> void: _ui_gente._emitir_bono(c))
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
			["Capitán", _ui_cantera._apellido(cap.nombre) if cap else "—"], ["Grupos", str(v.camarillas.size())]]:
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
					nombres.append(_ui_cantera._apellido(jm.nombre))
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
			_boton("🕊️ Mediar con el grupo", func() -> void: _ui_finanzas._mediar_clan(cid), fila)
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
		_boton("Terapia", func() -> void: _ui_finanzas._dar_terapia_mental(j), filaj)
		_boton("Descanso mental", func() -> void: _ui_finanzas._pedir_descanso_mental(j), filaj)
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

## "TU CARRERA" de `vDirectorio()`: el prestigio y la vitrina te siguen de club
## en club -a diferencia de `Directiva.trofeos`, que se quedan en el que
## dejas-, más las dos escaleras (ayudante→DT, DT→director→dueño) y lo que
## trae cada peldaño: un entrenador empleado que puedes cambiar, o -siendo
## dueño- meter capital propio y vender el club. Toda esta lógica ya estaba
## escrita y probada en `Roles`; no había ninguna pantalla que la mostrara.

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
		## `responder_oferta()`: `aceptar_oferta()` no existió nunca y el botón
		## del panel de mercado rompía (lo encontró el recorrido de pantallas).
		mundo.mercado.responder_oferta(indice, true)
		_escribir("[color=#4caf6d]Venta cerrada:[/color] %s a %s por %s." % [
			j.nombre,
			co.nombre if co else "?",
			_dinero(int(o["monto"]))])
	else:
		mundo.mercado.responder_oferta(indice, false)
		_escribir("Oferta por %s rechazada." % j.nombre)
	_refrescar()
