class_name RotuloRepeticion
extends Control
## EL AVISO DE «REPETICIÓN» DEL PARTIDO EN EL ESTADIO (17-11, HUD de TV, referencia FC Mobile). Antes era un rótulo rojo grande arriba
## al centro que tapaba el juego. Ahora es una pastilla PEQUEÑA arriba a la derecha (bajo «Volver» y ⚙) con la marca de repetición
## (un cuadro rojo con «R», como en las transmisiones), la palabra y cómo saltarla, que ENTRA con una cortinilla desde la derecha y
## SALE igual. Dibujado en un `_draw` (rectángulos y el texto en dos tamaños: 3 llamadas). Lo usa `VistaEstadio._lanzar_repeticion`.

const ALTO := 30.0
const ROJO := Color(0.86, 0.1, 0.14)

var escala := 1.0
var texto := ""
var pista := ""
var _fuente: Font
var _tw: Tween

## Lo crea la primera vez (arriba a la derecha de `vista`, a `arriba` px del borde; por defecto bajo «Volver» y ⚙) y lo hace entrar;
## devuelve el rótulo para guardarlo.
static func entrar(vista: Control, r: RotuloRepeticion, arriba := -1.0) -> RotuloRepeticion:
	if r == null or not is_instance_valid(r):
		r = RotuloRepeticion.new()
		r.name = "RotuloRepeticion"
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.escala = HudTactil.f(vista)
		r.texto = Idiomas.t("⟲  REPETICIÓN").trim_prefix("⟲").strip_edges()   ## la misma frase de siempre (ya traducida), sin el símbolo: la marca «R» lo dibuja
		r.pista = "%s · %s" % [Mando.corto_de("jugar_repeticion"), Idiomas.t("Saltar")]
		r.clip_contents = true
		vista.add_child(r)
		r._medir()
		r.anchor_left = 1.0
		r.anchor_right = 1.0
		r.offset_right = -16.0 - HudTactil.margen(vista).y
		r.offset_left = r.offset_right - r.custom_minimum_size.x
		r.offset_top = arriba if arriba >= 0.0 else 64.0 * r.escala
		r.offset_bottom = r.offset_top + ALTO * r.escala
	r.visible = true
	r._cortinilla(true)
	return r

## Sale con la cortinilla (y se esconde al terminar).
static func salir(r: Control) -> void:
	if r == null or not is_instance_valid(r):
		return
	if r is RotuloRepeticion:
		(r as RotuloRepeticion)._cortinilla(false)
	else:
		r.visible = false

func _ready() -> void:
	_fuente = MarcadorTV.fuente()

func _medir() -> void:
	if _fuente == null:
		_fuente = MarcadorTV.fuente()
	var e := escala
	var w := (ALTO + 8.0) * e + _fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, int(20 * e)).x \
		+ 12.0 * e + _fuente.get_string_size(pista, HORIZONTAL_ALIGNMENT_LEFT, -1, int(14 * e)).x + 12.0 * e
	custom_minimum_size = Vector2(w, ALTO * e)

## La cortinilla: el contenido corre desde el borde derecho (entrar) o hacia él (salir); `clip_contents` lo recorta.
var desliz := 0.0:
	set(v):
		desliz = v
		queue_redraw()

func _cortinilla(entra: bool) -> void:
	if is_instance_valid(_tw):
		_tw.kill()
	if Animar.reducidas():
		desliz = 0.0 if entra else 1.0
		visible = entra
		return
	if entra:
		desliz = 1.0
	_tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT if entra else Tween.EASE_IN)
	_tw.tween_property(self, "desliz", 0.0 if entra else 1.0, 0.22)
	if not entra:
		_tw.tween_callback(func() -> void: visible = false)

func _draw() -> void:
	if _fuente == null:
		return
	var e := escala
	var dx := desliz * size.x
	var h := size.y
	draw_rect(Rect2(dx, 0, size.x, h), Color(0.05, 0.06, 0.08, 0.86))
	draw_rect(Rect2(dx, h - 2.0 * e, size.x, 2.0 * e), ROJO)
	var c := Vector2(dx + h * 0.5 + 4.0 * e, h * 0.5 - 1.0 * e)
	var lado := h * 0.68
	draw_rect(Rect2(c - Vector2(lado, lado) * 0.5, Vector2(lado, lado)), ROJO)   ## la marca: un cuadro rojo con «R» (un rectángulo más: misma llamada)
	var tr := int(14 * e)   ## el mismo tamaño que la pista: un atlas de letra menos
	var wr := _fuente.get_string_size("R", HORIZONTAL_ALIGNMENT_LEFT, -1, tr).x
	draw_string(_fuente, Vector2(c.x - wr * 0.5, c.y + (_fuente.get_ascent(tr) - _fuente.get_descent(tr)) * 0.5), "R", HORIZONTAL_ALIGNMENT_LEFT, -1, tr, Color.WHITE)
	var t := int(20 * e)
	var y := h * 0.5 + (_fuente.get_ascent(t) - _fuente.get_descent(t)) * 0.5 - 1.0 * e
	var x := dx + (ALTO + 8.0) * e
	draw_string(_fuente, Vector2(x, y), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, t, Color.WHITE)
	x += _fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, t).x + 12.0 * e
	draw_string(_fuente, Vector2(x, y - 1.0 * e), pista, HORIZONTAL_ALIGNMENT_LEFT, -1, int(14 * e), Color(1, 1, 1, 0.65))
