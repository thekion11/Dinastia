class_name CampanasMenu
extends RefCounted
## LAS CAMPANAS ROJAS DEL MENÚ CENTRAL (avance por días, paso 5, 17-11-2026): un aviso menor no abre pantalla; el avance se detiene y la tarjeta de su ZONA
## del mosaico lleva una campana roja con el número de avisos. Pulsar la tarjeta la apaga. `TableroInicio.tarjeta` llama a `poner` con el nombre de cada tarjeta.

## zona del aviso -> tarjeta del mosaico (el rótulo en castellano, como lo recibe `TableroInicio.tarjeta`)
const TARJETA_DE_ZONA := {"equipo": "Mi plantel", "mercado": "Mercado de fichajes", "cantera": "Academia", "finanzas": "Cuentas del club",
	"prensa": "Noticias", "vestuario": "Camarín"}
## zona -> cuántos avisos hay sin leer. Se vacía al avanzar de nuevo o al abrir la tarjeta.
static var zonas: Dictionary = {}

static func anotar(avisos: Dictionary) -> void:
	for z: String in avisos.keys():
		zonas[z] = int(zonas.get(z, 0)) + (avisos[z] as Array).size()

static func hay() -> bool:
	return not zonas.is_empty()

static func limpiar() -> void:
	zonas.clear()

## Pone la campana en la tarjeta `nombre` (ya traducido) si su zona tiene avisos.
static func poner(b: Button, nombre: String) -> void:
	for z: String in zonas.keys():
		if nombre != Idiomas.t(String(TARJETA_DE_ZONA.get(z, ""))):
			continue
		var n := int(zonas[z])
		var campana := Label.new()
		campana.name = "Campana"
		campana.text = "🔔 %d" % n if n > 1 else "🔔"
		campana.add_theme_font_size_override("font_size", Tema.letra(13))
		campana.add_theme_color_override("font_color", Color.WHITE)
		var fondo := Tema.caja(Color("c0392b"), 10)
		fondo.set_content_margin_all(3)
		campana.add_theme_stylebox_override("normal", fondo)
		campana.anchor_left = 1.0; campana.anchor_right = 1.0
		campana.offset_left = -46; campana.offset_right = -8; campana.offset_top = 8; campana.offset_bottom = 30
		campana.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		campana.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(campana)
		b.pressed.connect(func() -> void: zonas.erase(z))
		return
