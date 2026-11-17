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

## En qué pestaña del mosaico (0 Avanzar, 1 Dirección del equipo, 2 Información del club) está la tarjeta de cada zona.
const PESTANA_DE_ZONA := {"equipo": 1, "mercado": 1, "cantera": 1, "vestuario": 1, "finanzas": 2, "prensa": 0}

## Un punto rojo en el botón de la pestaña `i` si algún aviso sin leer está en una tarjeta de esa pestaña (para no perder una campana en otra pestaña).
static func marcar_pestana(b: Button, i: int) -> void:
	for z: String in zonas.keys():
		if int(PESTANA_DE_ZONA.get(z, -1)) != i:
			continue
		var punto := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("e5242f")
		sb.set_corner_radius_all(7)
		sb.set_border_width_all(2)
		sb.border_color = Color.WHITE
		punto.add_theme_stylebox_override("panel", sb)
		punto.anchor_left = 1.0; punto.anchor_right = 1.0
		punto.offset_left = -22; punto.offset_right = -8; punto.offset_top = 6; punto.offset_bottom = 20
		punto.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(punto)
		return

## Pone la campana en la tarjeta `nombre` (ya traducido) si su zona tiene avisos.
static func poner(b: Button, nombre: String) -> void:
	for z: String in zonas.keys():
		if nombre != Idiomas.t(String(TARJETA_DE_ZONA.get(z, ""))):
			continue
		var n := int(zonas[z])
		## La campana de la maqueta: un círculo rojo con borde blanco y la campana de trazo, saliendo de la esquina de la tarjeta.
		var campana := PanelContainer.new()
		campana.name = "Campana"
		var fondo := StyleBoxFlat.new()
		fondo.bg_color = Color("e5242f")
		fondo.set_corner_radius_all(16)
		fondo.set_border_width_all(2)
		fondo.border_color = Color.WHITE
		fondo.set_content_margin_all(4)
		campana.add_theme_stylebox_override("panel", fondo)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 3)
		var ic := TextureRect.new()
		ic.texture = EstiloAvanzar.icono("campana", Color.WHITE, 40, 2.2)
		ic.custom_minimum_size = Vector2(20, 20)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fila.add_child(ic)
		if n > 1:
			fila.add_child(EstiloAvanzar.etiqueta(str(n), 13, Color.WHITE, true))
		campana.add_child(fila)
		campana.anchor_left = 1.0; campana.anchor_right = 1.0
		campana.offset_left = -(34 if n <= 1 else 52); campana.offset_right = 6; campana.offset_top = -8; campana.offset_bottom = 26
		campana.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.clip_contents = false
		b.add_child(campana)
		b.pressed.connect(func() -> void: zonas.erase(z))
		return
