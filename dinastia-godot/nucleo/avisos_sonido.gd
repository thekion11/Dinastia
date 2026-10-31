class_name AvisosSonido
extends CanvasLayer
## M-283 (28-10-2026): AVISOS VISUALES DE SONIDO, para quien juega sin oír (o con el sonido apagado). Cada efecto con
## significado (silbato, gol, ovación, tarjeta roja, sirena…) sale escrito abajo al centro, «🔊 Silbato», unos segundos;
## caben tres a la vez. Se enciende en Ajustes → Accesibilidad y se guarda en el mismo archivo que el resto de ajustes.
## `Sonido.toca` llama a `avisar(nombre)` siempre (también con el sonido apagado); aquí se decide si se ve.

const RUTA := "user://ajustes.cfg"
const DURA := 2.6
const MAX := 3
## Solo los sonidos que dicen algo del juego; los de interfaz (clic, menú, pasos) no.
const TEXTOS := {
	"silbato": "Silbato", "pitido_final": "Pitido final", "medio_tiempo": "Pitido: descanso", "saque_inicial": "Pitido inicial",
	"reanudacion": "Pitido: se reanuda", "gol": "¡Gol! La grada estalla", "gol_agonico": "¡Gol en el último suspiro! La grada estalla",
	"gol_rapido": "¡Gol tempranero! La grada estalla", "gol_rival": "Gol rival: silencio en la grada", "ovacion": "Ovación",
	"abucheo": "Abucheos", "murmullo": "Murmullo en la grada", "tension_publico": "La grada contiene el aliento",
	"suspiro_grada": "La grada se lamenta", "ocasion": "¡Uy! La grada se levanta", "atajada": "Paradón",
	"travesano": "¡Al travesaño!", "remate_fuera": "Remate fuera", "roja": "Tarjeta roja", "descuento_anunciado": "Megafonía: tiempo añadido",
	"ultimo_minuto": "Último minuto", "sirena": "Sirena", "trueno": "Trueno", "lluvia_fuerte": "Lluvia fuerte",
	"notificacion": "Notificación", "fichaje": "Fichaje cerrado", "trofeo": "Trofeo", "logro": "Logro desbloqueado",
	"salida_tunel": "Los equipos salen al campo", "cambio": "Cambio",
}

static var _activo := -1

static func activo() -> bool:
	if _activo < 0:
		var cfg := ConfigFile.new()
		_activo = 1 if cfg.load(RUTA) == OK and bool(cfg.get_value("acceso", "avisos_sonido", false)) else 0
	return _activo == 1

static func fijar(si: bool) -> void:
	_activo = 1 if si else 0
	var cfg := ConfigFile.new()
	cfg.load(RUTA)
	cfg.set_value("acceso", "avisos_sonido", si)
	cfg.save(RUTA)

var _caja := VBoxContainer.new()

func _ready() -> void:
	layer = 120
	_caja.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_caja.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_caja.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_caja.position.y -= 70.0
	_caja.alignment = BoxContainer.ALIGNMENT_END
	_caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_caja)

## Lo que se escribe para un sonido ("" si ese sonido no lleva aviso).
static func texto(nombre: String) -> String:
	return ("🔊 " + Idiomas.t(String(TEXTOS[nombre]))) if TEXTOS.has(nombre) else ""

func avisar(nombre: String) -> void:
	var t := texto(nombre)
	if t == "" or not activo():
		return
	## El mismo sonido dos veces seguidas no repite la línea: se renueva.
	for h in _caja.get_children():
		if h is Label and (h as Label).text == t:
			h.set_meta("hasta", Time.get_ticks_msec() + int(DURA * 1000.0))
			return
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0, 0, 0, 0.6)
	fondo.set_corner_radius_all(6)
	fondo.content_margin_left = 12
	fondo.content_margin_right = 12
	fondo.content_margin_top = 3
	fondo.content_margin_bottom = 3
	l.add_theme_stylebox_override("normal", fondo)
	l.set_meta("hasta", Time.get_ticks_msec() + int(DURA * 1000.0))
	_caja.add_child(l)
	while _caja.get_child_count() > MAX:
		var viejo := _caja.get_child(0)
		_caja.remove_child(viejo)
		viejo.queue_free()

func _process(_d: float) -> void:
	var ahora := Time.get_ticks_msec()
	for h in _caja.get_children():
		if ahora > int(h.get_meta("hasta", 0)):
			_caja.remove_child(h)
			h.queue_free()
