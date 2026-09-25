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

const ANCHO := 340.0
const ALTO := 74.0
const MARGEN := 16.0
const ENTRADA := 0.42
const QUEDARSE := 3.4
const SALIDA := 0.45
const MAX_EN_COLA := 8   ## por si una temporada dispara veinte: se ven ocho

const COL_PANEL := Color("1b2620")
const COL_TEXTO := Color("e9eeea")
const COL_SUAVE := Color("8ea595")

## etiqueta · color de acento · sonido
const TIPOS := {
	"logro":    {"et": "LOGRO DESBLOQUEADO", "col": Color("c9a227"), "sfx": "logro"},
	"record":   {"et": "NUEVO RÉCORD",       "col": Color("c9a227"), "sfx": "logro"},
	"nivel":    {"et": "SUBES DE NIVEL",     "col": Color("4caf6d"), "sfx": "logro"},
	"dinero":   {"et": "INGRESO",            "col": Color("4caf6d"), "sfx": "moneda"},
	"gasto":    {"et": "SALE DE LA CAJA",    "col": Color("e05555"), "sfx": "moneda"},
	"mercado":  {"et": "MERCADO",            "col": Color("c9a227"), "sfx": "fichaje"},
	"alerta":   {"et": "AVISO",              "col": Color("e05555"), "sfx": "cambio"},
	"contrato": {"et": "CONTRATOS",          "col": Color("c9a227"), "sfx": "cambio"},
	"titulo":   {"et": "¡CAMPEÓN!",          "col": Color("c9a227"), "sfx": "trofeo"},
}

static var _cola: Array[Dictionary] = []
static var _mostrando := false

## Único punto de entrada. Se le pasa el padre porque el aviso tiene que colgar
## de algo vivo: colgado del árbol raíz, cambiar de escena lo dejaría huérfano
## a media animación.
static func mostrar(padre: Node, tipo: String, icono: String, titulo: String, descripcion: String) -> void:
	if _cola.size() >= MAX_EN_COLA:
		return
	_cola.append({"padre": padre, "tipo": tipo, "icono": icono, "titulo": titulo, "desc": descripcion})
	if not _mostrando:
		_siguiente()

static func _siguiente() -> void:
	if _cola.is_empty():
		_mostrando = false
		return
	var d: Dictionary = _cola.pop_front()
	var padre: Node = d["padre"]
	if padre == null or not is_instance_valid(padre) or not padre.is_inside_tree():
		_siguiente()
		return
	_mostrando = true
	var aviso := Aviso.new()
	aviso._tipo = String(d["tipo"])
	aviso._icono = String(d["icono"])
	aviso._titulo = String(d["titulo"])
	aviso._desc = String(d["desc"])
	padre.add_child(aviso)

var _tipo := "logro"
var _icono := "🏆"
var _titulo := ""
var _desc := ""

func _ready() -> void:
	var def: Dictionary = TIPOS.get(_tipo, TIPOS["logro"])
	var acento: Color = def["col"]
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(ANCHO, ALTO)
	size = Vector2(ANCHO, ALTO)
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = COL_PANEL
	estilo.border_color = acento
	estilo.set_border_width_all(1)
	estilo.border_width_left = 3
	estilo.set_corner_radius_all(6)
	estilo.content_margin_left = 12
	estilo.content_margin_right = 12
	estilo.content_margin_top = 8
	estilo.content_margin_bottom = 8
	add_theme_stylebox_override("panel", estilo)

	var caja := HBoxContainer.new()
	caja.add_theme_constant_override("separation", 10)
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caja)
	var ico := Label.new()
	ico.text = _icono
	ico.add_theme_font_size_override("font_size", 30)
	ico.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_child(ico)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_child(col)
	var arriba := Label.new()
	arriba.text = String(def["et"])
	arriba.add_theme_font_size_override("font_size", 9)
	arriba.add_theme_color_override("font_color", COL_SUAVE)
	arriba.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(arriba)
	var tit := Label.new()
	tit.text = _titulo
	tit.add_theme_font_size_override("font_size", 14)
	tit.add_theme_color_override("font_color", acento)
	tit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(tit)
	var des := Label.new()
	des.text = _desc
	des.add_theme_font_size_override("font_size", 10)
	des.add_theme_color_override("font_color", COL_TEXTO)
	des.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	des.custom_minimum_size = Vector2(ANCHO - 70.0, 0)
	des.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(des)

	Sonido.toca(String(def["sfx"]), Sonido.Bus.INTERFAZ)
	_animar()

func _animar() -> void:
	var padre := get_parent_control()
	var ancho_padre := padre.size.x if padre != null else 1600.0
	position = Vector2(ancho_padre, MARGEN)
	modulate.a = 0.0
	var destino := Vector2(ancho_padre - ANCHO - MARGEN, MARGEN)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(self, "position", destino, ENTRADA).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "modulate:a", 1.0, ENTRADA * 0.6)
	t.set_parallel(false)
	t.tween_interval(QUEDARSE)
	t.set_parallel(true)
	t.tween_property(self, "position:x", ancho_padre, SALIDA).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_property(self, "modulate:a", 0.0, SALIDA)
	t.set_parallel(false)
	t.tween_callback(func() -> void:
		queue_free()
		Aviso._siguiente())
