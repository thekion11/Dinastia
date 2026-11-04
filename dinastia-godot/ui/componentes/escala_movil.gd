class_name EscalaMovil
extends RefCounted
## LA INTERFAZ EN EL MÓVIL (2-11-2026, queja del dueño: «el tamaño del texto y de las pantallas es muy pequeño, cuesta leer y rellenar los cuadros»).
## La interfaz está pensada para 1280 × 720: en un móvil (2000 × 900 a ~400 ppp) un texto de 14 px mide ~1 mm. La primera vez, en Android, iOS o la web en una
## pantalla táctil, se aplica un zoom de interfaz de `ZOOM_MOVIL` (el de Ajustes → «Tamaño de la interfaz», que se puede cambiar o volver a 100 %); si el
## jugador ya eligió uno, se respeta. Los cuadros de texto (`campo_alto`) pasan a medir al menos `ALTO_CAMPO_MOVIL` px para poder tocarlos y escribir.
const ZOOM_MOVIL := 1.5
const ALTO_CAMPO_MOVIL := 56

static func es_movil() -> bool:
	return OS.has_feature("android") or OS.has_feature("ios") or (OS.has_feature("web") and DisplayServer.is_touchscreen_available())

## El zoom que toca: el guardado en las preferencias, o el del móvil si no hay y es un móvil, o 1.
static func zoom(guardado: Variant) -> float:
	if guardado != null:
		return clampf(float(guardado), 0.7, 1.8)
	return ZOOM_MOVIL if es_movil() else 1.0

## Lo llama la primera escena: pone el zoom de interfaz de esta máquina (sin tocar nada guardado).
static func aplicar(arbol: SceneTree, prefs_ruta: String) -> void:
	var cf := ConfigFile.new()
	var guardado: Variant = null
	if cf.load(prefs_ruta) == OK and cf.has_section_key("pantalla", "zoom"):
		guardado = cf.get_value("pantalla", "zoom")
	arbol.root.content_scale_factor = zoom(guardado)
	vigilar(arbol)   ## desde el arranque: también las pantallas de entrada (idioma, país, club, personaje) con botones de 7 mm

## Alto mínimo de un cuadro de texto: el normal en escritorio, mayor en el móvil.
static func campo_alto(normal: int) -> int:
	return maxi(normal, ALTO_CAMPO_MOVIL) if es_movil() else normal

## EL TOQUE (4-11-2026, caza de fallos del móvil): un botón de 25 px en un 6,5" a 2400×1080 mide ≈3,5 mm y se falla con el dedo. En el móvil los botones, desplegables, casillas y pestañas
## miden al menos `MIN_MM_TOQUE` mm de alto (con tope `MAX_TOQUE` px del lienzo para que la pantalla no se llene de botones gordos). En PC (sin puntos por pulgada) no cambia nada.
const MIN_MM_TOQUE := 7.0
const MAX_TOQUE := 52.0

## Alto mínimo de un toque en píxeles del lienzo (0 si no es un móvil o no se sabe).
static func alto_toque(nodo: Node) -> float:
	var ppm := PantallaMovil.px_por_mm(nodo)
	return 0.0 if ppm <= 0.0 else minf(MIN_MM_TOQUE * ppm, MAX_TOQUE)

## Estira los márgenes de arriba y abajo de los botones del tema hasta que midan `alto` con la letra por defecto.
static func ampliar_toque(t: Theme, alto: float) -> void:
	if alto <= 0.0:
		return
	var letra := float(t.default_font_size if t.default_font_size > 0 else 16)
	var margen := maxf(0.0, (alto - letra * 1.25) * 0.5)
	for clase: String in ["Button", "OptionButton", "MenuButton", "CheckBox", "CheckButton"]:
		for estado: String in ["normal", "hover", "pressed", "disabled", "focus"]:
			var sb := t.get_stylebox(estado, clase) if t.has_stylebox(estado, clase) else null
			if sb is StyleBoxFlat:
				var f := sb as StyleBoxFlat
				f.content_margin_top = maxf(f.content_margin_top, margen)
				f.content_margin_bottom = maxf(f.content_margin_bottom, margen)
	for estado2: String in ["tab_selected", "tab_unselected", "tab_hovered"]:
		var sb2 := t.get_stylebox(estado2, "TabContainer") if t.has_stylebox(estado2, "TabContainer") else null
		if sb2 is StyleBoxFlat:
			var g := sb2 as StyleBoxFlat
			g.content_margin_top = maxf(g.content_margin_top, margen)
			g.content_margin_bottom = maxf(g.content_margin_bottom, margen)

## Red de seguridad: los botones con estilo propio (chips de asuntos, muestras de tema, ✕ de las tarjetas) no pasan por el tema; los que nacen después de llamar a `vigilar` se estiran a `alto_toque`.
static func vigilar(arbol: SceneTree) -> void:
	if arbol.root.has_meta("toque_vigilado") or alto_toque(arbol.root) <= 0.0:
		return
	arbol.root.set_meta("toque_vigilado", true)
	arbol.node_added.connect(_nodo_nuevo)

static func _nodo_nuevo(n: Node) -> void:
	if n is BaseButton and n is Button:
		var b := n as Button
		var alto := alto_toque(b)
		if alto > b.custom_minimum_size.y:
			b.custom_minimum_size.y = alto
