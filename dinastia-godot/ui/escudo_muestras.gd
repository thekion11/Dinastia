class_name EscudoMuestras
extends RefCounted
## LAS MINIATURAS DE LA PANTALLA DE IDENTIDAD (25-10-2026, paquete uiid).
##
## Las rejillas de forma, patrón y estampado eran botones con la clave cruda
## («penta», «banda_cinta», «vertical3»): había que pulsar cada una y subir a la
## vista previa para saber qué era. Ahora cada botón ES la vista previa: el
## escudo del club con esa forma o ese patrón, la camiseta con ese estampado,
## con los colores que el club lleva puestos en ese momento. Además así no hay
## nada que traducir: un dibujo se lee igual en los nueve idiomas.
##
## Por qué una caché propia y ACOTADA, y no la de `Escudo`/`Jersey`: cada
## arrastre del selector de color repinta la pantalla con un color nuevo, y las
## cachés de esas clases guardan cada variante para siempre (están pensadas para
## los escudos de una tabla, que se repiten). Aquí son ~90 miniaturas por color;
## sin tope, un minuto eligiendo color serían cientos de megas.

const TOPE_CACHE := 400
const TINTA := Color("#1a1a1a")

static var _cache: Dictionary = {}

## El escudo del club con otra forma (o con otro patrón), sin tocar el club: se
## cambia el campo, se construye la cadena SVG y se deja como estaba, todo en
## la misma llamada -no hay señales ni repintados por medio-.
static func escudo_con(c: Club, campo: String, valor: String, alto_px: int) -> Texture2D:
	var antes := String(c.get(campo))
	c.set(campo, valor)
	var svg := Escudo.svg_de(c)
	c.set(campo, antes)
	## A doble resolución: el botón la encoge y así no sale borrosa con el zoom
	## de la interfaz ni en 1920x1080.
	return _rasterizar(svg, float(alto_px) * 2.0 / 70.0)

## La camiseta procedural con un estampado dado, a doble resolución.
static func camiseta(c1: String, c2: String, estilo: String, ancho_px: int) -> Texture2D:
	if not Jersey.KITS.has(estilo):
		return Jersey.textura_procedural(c1, c2, estilo, ancho_px * 2)
	return _rasterizar(Jersey.svg_de(c1, c2, estilo), float(ancho_px) * 2.0 / 64.0)

static func _rasterizar(svg: String, escala: float) -> Texture2D:
	var clave := "%d_%.3f" % [svg.hash(), escala]
	if _cache.has(clave):
		return _cache[clave]
	if _cache.size() >= TOPE_CACHE:
		_cache.clear()
	var img := Image.new()
	if img.load_svg_from_string(svg, escala) != OK:
		return null
	var t := ImageTexture.create_from_image(img)
	_cache[clave] = t
	return t

## Cuántas hay guardadas (para las pruebas: la caché no puede crecer sin fin).
static func en_cache() -> int:
	return _cache.size()

## Un botón-miniatura de las rejillas: se marca el elegido (toggle) y lleva la
## miniatura como icono a tamaño fijo. Con mando o teclado se recorre igual que
## los de texto: es un `Button` normal, con su foco.
static func boton(tex: Texture2D, elegido: bool, lado: int, ayuda: String = "") -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.button_pressed = elegido
	b.icon = tex
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.custom_minimum_size = Vector2(lado, lado)
	b.focus_mode = Control.FOCUS_ALL
	b.tooltip_text = ayuda
	return b

## EL ESCUDO EN UNA TINTA, como sale impreso en el periódico o en un marcador de
## un solo color (`Escudo.textura_mono`), sobre papel y con sus iniciales: el
## rasterizador no dibuja `<text>`, así que van encima como en `Principal._escudo`.
## Sirve para ver si el diseño AGUANTA sin color -un patrón con dos colores de la
## misma luminosidad se queda en una mancha-, que es lo que no enseña la vista en
## color.
static func escudo_prensa(c: Club, alto: int) -> Control:
	var papel := PanelContainer.new()
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color("#f1ece0")
	fondo.set_corner_radius_all(4)
	fondo.set_content_margin_all(4)
	papel.add_theme_stylebox_override("panel", fondo)
	var caja := Control.new()
	caja.custom_minimum_size = Vector2(alto, alto)
	papel.add_child(caja)
	var t := TextureRect.new()
	t.texture = Escudo.textura_mono(c, alto, TINTA)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.add_child(t)
	var l := Label.new()
	var simbolo := Escudo.simbolo_de(c)
	l.text = simbolo if simbolo != "" else Escudo.iniciales(c)
	l.add_theme_font_size_override("font_size", maxi(9, int(float(alto) * (0.55 if simbolo != "" else 0.36))))
	## El fondo del escudo pasa a tinta si es oscuro y a blanco si es claro
	## (mismo umbral que `textura_mono`): las letras, al revés.
	var oscuro := Color(c.color_escudo1()).get_luminance() < 0.55
	l.add_theme_color_override("font_color", Color.WHITE if oscuro else TINTA)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.offset_top = -float(alto) * 0.10
	caja.add_child(l)
	return papel


## La fila de vista previa junto a los controles del escudo: en color (el
## de la pantalla principal, con iniciales) y en una tinta, con su rótulo. Va
## pegada a las rejillas porque la vista previa de arriba ya no se ve cuando
## uno baja a elegir forma y patrón.
static func fila_previa(en_color: Control, c: Club, alto: int, rotulo: Label) -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	en_color.tooltip_text = Idiomas.t("En color: camiseta, estadio y tablas")
	fila.add_child(en_color)
	var prensa := escudo_prensa(c, alto)
	prensa.tooltip_text = Idiomas.t("En una tinta: prensa y marcadores")
	fila.add_child(prensa)
	rotulo.text = Idiomas.t("Así se ve tu escudo")
	rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fila.add_child(rotulo)
	return fila
