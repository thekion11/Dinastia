class_name Aviso
extends PanelContainer
## El aviso deslizante del juego, al estilo de las consolas: entra desde el
## borde derecho, se queda unos segundos y se va solo.
##
## POR QUÉ EXISTE. El registro ("LO QUE VA PASANDO") recibe quince líneas por
## semana, así que lo importante se pierde entre lo rutinario: un logro se
## desbloqueaba y el jugador no se enteraba, un club pagaba una cláusula por tu
## figura y era una línea gris más. Esto es para los momentos que MERECEN
## interrumpir: no todo pasa por aquí, o dejaría de funcionar.
##
## CADA TIPO TRAE SU COLOR, SU ETIQUETA Y SU SONIDO. Están en `TIPOS` y en un
## solo sitio a propósito: dar sonido propio a un tipo nuevo es añadir una fila
## y una receta en `Sonido._sintetizar()`, sin tocar nada más.
##
## DOS REGLAS QUE LO HACEN NO MOLESTAR:
##  1. `mouse_filter = IGNORE` en todo: flota por encima de la pantalla, así que
##     si atrapara el ratón bloquearía botones que están debajo.
##  2. Se encolan. Al cerrar una temporada pueden caer cuatro de golpe; sin
##     cola, el último pisaría al primero y no se leería ninguno.
##  3. NO TAPA (25-10-2026, paquete uitm). Sale arriba a la derecha, encima de
##     la caja y la fecha del centro. Si el ratón pasa por debajo -porque
##     quieres leer o tocar lo que tapa-, se vuelve casi transparente mientras
##     sigas ahí. Como no atrapa el ratón, el clic llega igual a lo de debajo.
##
## ARREGLO (25-10-2026): la salida corría A LA VEZ que la espera
## (`set_parallel(true)` tras `tween_interval` une lo siguiente al paso de la
## espera), así que el aviso entraba y se iba en menos de un segundo y luego la
## cola esperaba 3,4 s sin nada en pantalla. Ahora va en pasos encadenados.

## 13-10-2026: más grande y legible (letras de 9-10 px no se leían).
const ANCHO := 400.0
const ALTO := 84.0
const MARGEN := 16.0
const ENTRADA := 0.42
const QUEDARSE := 3.4
const SALIDA := 0.45
const MAX_EN_COLA := 8   ## por si una temporada dispara veinte: se ven ocho
## Opacidad con el ratón encima y lo que tarda en llegar a ella (en segundos).
const ALFA_DEBAJO := 0.16
const FUNDIDO_DEBAJO := 0.15

const COL_PANEL := Color(0.06, 0.07, 0.1, 0.97)
const COL_TEXTO := Tema.TEXTO
const COL_SUAVE := Tema.SUAVE

## etiqueta · color de acento · sonido
const TIPOS := {
	"logro":    {"et": "LOGRO DESBLOQUEADO", "col": Tema.ORO, "sfx": "logro"},
	"record":   {"et": "NUEVO RÉCORD",       "col": Tema.ORO, "sfx": "logro"},
	"nivel":    {"et": "SUBES DE NIVEL",     "col": Tema.BIEN, "sfx": "logro"},
	"dinero":   {"et": "INGRESO",            "col": Tema.BIEN, "sfx": "moneda"},
	"gasto":    {"et": "SALE DE LA CAJA",    "col": Tema.MAL, "sfx": "moneda"},
	"mercado":  {"et": "MERCADO",            "col": Tema.ORO, "sfx": "fichaje"},
	"alerta":   {"et": "AVISO",              "col": Tema.MAL, "sfx": "cambio"},
	"contrato": {"et": "CONTRATOS",          "col": Tema.ORO, "sfx": "cambio"},
	"prensa":   {"et": "PRENSA",             "col": Tema.SUAVE, "sfx": "cambio"},
	"titulo":   {"et": "¡CAMPEÓN!",          "col": Tema.ORO, "sfx": "trofeo"},
	"vida":     {"et": "MI VIDA",            "col": Tema.ORO, "sfx": "cambio"},
}

static var _cola: Array[Dictionary] = []
static var _mostrando := false

## Único punto de entrada. Se le pasa el padre porque el aviso tiene que colgar
## de algo vivo: colgado del árbol raíz, cambiar de escena lo dejaría huérfano
## a media animación.
## `sfx` (25-9-2026): un sonido propio para ESTE aviso, en vez del genérico
## de su tipo -el despido no suena como cualquier alerta, ni el cierre del
## mercado como cualquier fichaje-. Vacío, el del tipo.
static func mostrar(padre: Node, tipo: String, icono: String, titulo: String, descripcion: String, sfx: String = "") -> void:
	if _cola.size() >= MAX_EN_COLA:
		return
	_cola.append({"padre": padre, "tipo": tipo, "icono": icono, "titulo": titulo, "desc": descripcion, "sfx": sfx})
	if not _mostrando:
		_siguiente()

static func _siguiente() -> void:
	if _cola.is_empty():
		_mostrando = false
		return
	var d: Dictionary = _cola.pop_front()
	## Se mira ANTES de asignarlo a una variable tipada: asignar un nodo ya
	## liberado a `var padre: Node` es un error de script que cortaba la cola
	## (los avisos encolados para una pantalla que se cerró la dejaban muda).
	var v: Variant = d["padre"]
	if not is_instance_valid(v) or not (v as Node).is_inside_tree():
		_siguiente()
		return
	var padre: Node = v
	_mostrando = true
	var aviso := Aviso.new()
	aviso._tipo = String(d["tipo"])
	aviso._icono = String(d["icono"])
	aviso._titulo = String(d["titulo"])
	aviso._desc = String(d["desc"])
	aviso._sfx = String(d.get("sfx", ""))
	padre.add_child(aviso)

var _tipo := "logro"
var _icono := "🏆"
var _titulo := ""
var _desc := ""
var _sfx := ""
## 0→1→0 con la animación de entrada y salida; el alfa final es esto por el
## fundido de «el ratón está debajo» (`_debajo`, 0 = fuera, 1 = dentro).
var _aparicion := 0.0
var _debajo := 0.0
## Ya avisó a la cola de que acabó (para no avisar dos veces).
var _terminado := false

func _ready() -> void:
	var def: Dictionary = TIPOS.get(_tipo, TIPOS["logro"])
	## El acento pasa por la paleta para daltonismo (oro/verde/rojo).
	var acento: Color = Tema.accesible(def["col"])
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(ANCHO, ALTO)
	size = Vector2(ANCHO, ALTO)
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = COL_PANEL
	estilo.border_color = acento
	estilo.set_border_width_all(1)
	estilo.border_width_left = 4
	estilo.set_corner_radius_all(14)
	estilo.shadow_color = Color(0, 0, 0, 0.45)
	estilo.shadow_size = 12
	estilo.content_margin_left = 16
	estilo.content_margin_right = 16
	estilo.content_margin_top = 10
	estilo.content_margin_bottom = 10
	add_theme_stylebox_override("panel", estilo)

	var caja := HBoxContainer.new()
	caja.add_theme_constant_override("separation", 10)
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caja)
	var ico := Label.new()
	ico.text = _icono
	ico.add_theme_font_size_override("font_size", Tema.letra(30))
	ico.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_child(ico)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_child(col)
	var arriba := Label.new()
	arriba.text = Idiomas.t(String(def["et"]))
	arriba.add_theme_font_size_override("font_size", Tema.letra(12))
	arriba.add_theme_color_override("font_color", COL_SUAVE)
	arriba.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(arriba)
	var tit := Label.new()
	## Muchos avisos llegan con el texto en castellano desde la lógica: se
	## traducen aquí, en el único sitio por el que pasan todos.
	tit.text = Idiomas.t(_titulo)
	tit.add_theme_font_size_override("font_size", Tema.letra(18))
	tit.add_theme_color_override("font_color", acento)
	tit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(tit)
	var des := Label.new()
	des.text = Idiomas.t(_desc) if _desc != "" else ""
	des.visible = _desc != ""
	des.add_theme_font_size_override("font_size", Tema.letra(14))
	des.add_theme_color_override("font_color", COL_TEXTO)
	des.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	des.custom_minimum_size = Vector2(ANCHO - 80.0, 0)
	des.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(des)

	Sonido.toca(_sfx if _sfx != "" and Sonido.NOMBRES.has(_sfx) else String(def["sfx"]), Sonido.Bus.INTERFAZ)
	_animar()

func _animar() -> void:
	## Por encima de la interfaz que se dibuja después (botones de la barra).
	z_index = 150
	var padre := get_parent_control()
	var ancho_padre := padre.size.x if padre != null else 1600.0
	position = Vector2(ancho_padre, MARGEN)
	_aparicion = 0.0
	modulate.a = 0.0
	var destino := Vector2(ancho_padre - ANCHO - MARGEN, MARGEN)
	## Pasos encadenados: entrar (posición y alfa a la vez), quedarse, salir
	## (posición y alfa a la vez) y dar paso al siguiente.
	var t := create_tween()
	t.tween_property(self, "position", destino, ENTRADA).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(self, "_aparicion", 1.0, ENTRADA * 0.6)
	t.tween_interval(QUEDARSE)
	t.tween_property(self, "position:x", ancho_padre, SALIDA).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(self, "_aparicion", 0.0, SALIDA)
	t.tween_callback(func() -> void:
		_dar_paso()
		queue_free())

func _process(delta: float) -> void:
	var dentro := get_global_rect().has_point(get_global_mouse_position())
	_debajo = move_toward(_debajo, 1.0 if dentro else 0.0, delta / FUNDIDO_DEBAJO)
	modulate.a = _aparicion * lerpf(1.0, ALFA_DEBAJO, _debajo)

## Avisa a la cola UNA vez. Si el padre desaparece a media animación (cambio de
## pantalla), el tween muere con el aviso y su callback no llega nunca: sin
## esto `_mostrando` se quedaba en true y no volvía a salir ningún aviso.
func _dar_paso() -> void:
	if _terminado:
		return
	_terminado = true
	var arbol := Engine.get_main_loop() as SceneTree
	if arbol != null and arbol.process_frame.is_connected(Aviso._siguiente):
		return
	if arbol != null:
		## Diferido: en medio de un `queue_free` o de una salida del árbol no
		## se debe colgar otro nodo de un padre que quizá también se va.
		arbol.process_frame.connect(Aviso._siguiente, CONNECT_ONE_SHOT)
	else:
		Aviso._siguiente()

func _exit_tree() -> void:
	_dar_paso()
