class_name EscalaMovil
extends RefCounted
## LA INTERFAZ EN EL MÓVIL (2-11-2026, queja del dueño: «el tamaño del texto y de las pantallas es muy pequeño, cuesta leer y rellenar los cuadros»).
## La interfaz está pensada para 1280 × 720: en un móvil (2000 × 900 a ~400 ppp) un texto de 14 px mide ~1 mm. La primera vez, en Android, iOS o la web en una
## pantalla táctil, se aplica un zoom de interfaz de `ZOOM_MOVIL` (el de Ajustes → «Tamaño de la interfaz», que se puede cambiar o volver a 100 %); si el
## jugador ya eligió uno, se respeta. Los cuadros de texto (`campo_alto`) pasan a medir al menos `ALTO_CAMPO_MOVIL` px para poder tocarlos y escribir.
const ZOOM_MOVIL := 1.5
const ALTO_CAMPO_MOVIL := 56

## VERTICAL (10-11, orden 36, sesión 8): en un teléfono de pie el lienzo es de 1280/zoom de ANCHO, o sea 853 px con el zoom 1,5 del
## horizontal, y la letra de 11-14 px medía 1,1 mm. El diseño propio del vertical parte de un lienzo de `ANCHO_VERTICAL` px de ancho (el
## alto corto del horizontal, 480, con algo de aire): ahí la letra normal (14 px) mide ≈1,8 mm y un toque de 7 mm son ≈55 px. El «Tamaño de
## la interfaz» de Ajustes sigue siendo relativo al del horizontal (se multiplica por `RAZON_VERTICAL`).
const ANCHO_VERTICAL := 540.0
const RAZON_VERTICAL := (1280.0 / ANCHO_VERTICAL) / ZOOM_MOVIL
const ALTO_TOQUE_VERTICAL := 56.0   ## tope de un toque de 7 mm en vertical (a 8 px/mm del lienzo)

static var forzar := false   ## las pruebas simulan un móvil en PC (`auditoria_gestion_movil`)

## Táctil: un móvil, o una pantalla de la que se conocen los puntos por pulgada (las pruebas que simulan un teléfono). Lo usan los
## ajustes de la gestión que dependen del tamaño real (fila de próximos, cajón de objetivos, textos en dos líneas).
static func es_tactil() -> bool:
	return es_movil() or PantallaMovil.dpi() > 0.0

static func es_movil() -> bool:
	return forzar or OS.has_feature("android") or OS.has_feature("ios") or (OS.has_feature("web") and DisplayServer.is_touchscreen_available())

## ¿Un teléfono de pie? (la ventana, o la que simula una prueba, es más alta que ancha)
static func es_vertical() -> bool:
	var v := PantallaMovil.ventana()
	return es_tactil() and v.y > v.x

## El factor de escala que de verdad se pone en la raíz: el zoom de Ajustes (relativo al del horizontal) y, de pie, el de lienzo estrecho.
static func efectivo(zoom_ajustes: float) -> float:
	return zoom_ajustes * (RAZON_VERTICAL if es_vertical() and es_movil() else 1.0)

## Pone el factor en la raíz y, si el teléfono se gira, lo vuelve a poner.
static func poner(arbol: SceneTree, zoom_ajustes: float) -> void:
	arbol.root.content_scale_factor = efectivo(zoom_ajustes)
	arbol.root.set_meta("zoom_ajustes", zoom_ajustes)
	if not arbol.root.has_meta("giro_vigilado"):
		arbol.root.set_meta("giro_vigilado", true)
		arbol.root.size_changed.connect(func() -> void:
			var z := float(arbol.root.get_meta("zoom_ajustes", 1.0))
			if not is_equal_approx(arbol.root.content_scale_factor, efectivo(z)):
				arbol.root.content_scale_factor = efectivo(z))

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
	poner(arbol, zoom(guardado))
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
	return 0.0 if ppm <= 0.0 else minf(MIN_MM_TOQUE * ppm, ALTO_TOQUE_VERTICAL if es_vertical() else MAX_TOQUE)

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
		## (10-11, auditoría de gestión en el móvil) también de ANCHO: «⤢», «📅», las cabeceras «POS»/«POT» o las fichas de país
		## medían 4-5,6 mm y se fallaban con el dedo.
		if alto > b.custom_minimum_size.x:
			b.custom_minimum_size.x = alto
	elif n is LineEdit or n is HSlider:   ## los cuadros de texto y los deslizadores (6,3-6,9 mm de alto)
		var c := n as Control
		var alto2 := alto_toque(c)
		if alto2 > c.custom_minimum_size.y:
			c.custom_minimum_size.y = alto2
	if n is Label or n is Button or n is LineEdit or n is RichTextLabel:
		_letra.call_deferred(n)   ## diferido: el tamaño de letra se suele poner justo después de añadirlo

## LA LETRA MÍNIMA EN EL MÓVIL (10-11, auditoría de gestión): ningún texto por debajo de `MIN_MM_LETRA` mm (11 pt de Apple, 12 sp de
## Material). Con el zoom del móvil la letra normal ya mide ~2 mm, pero las de 11-12 px (cabeceras, filas, rótulos) se quedaban en
## 1,4-1,7 mm. Se sube solo lo que no llega; `TextoQueCabe` tampoco encoge por debajo.
const MIN_MM_LETRA := 1.8

## El tamaño de letra mínimo en píxeles del control (0 si no es un móvil o no se sabe).
static func letra_minima(c: Control) -> int:
	var ppm := PantallaMovil.px_por_mm(c)
	if ppm <= 0.0 or not c.is_inside_tree():
		return 0
	## Nunca por encima de la letra normal (`Tema.TAM_CUERPO`): si el jugador bajó el «Tamaño de la interfaz», manda su elección y solo se
	## igualan las letras pequeñas a la normal (sin tope, a 1280×720 y 400 ppp todo pasaba a 28 px y se salía de las ventanas).
	var cap := Tema.TAM_CUERPO + (2 if es_vertical() else 0)   ## de pie la letra normal ya mide 1,8 mm: el tope deja subir un par de px
	return mini(ceili(MIN_MM_LETRA * ppm / maxf(c.get_global_transform().get_scale().y, 0.01) - 0.05), cap)

static func _letra(c: Control) -> void:
	if not is_instance_valid(c) or not c.is_inside_tree():
		return
	var piso := letra_minima(c)
	if piso <= 0:
		return
	var claves := ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size", "mono_font_size"] if c is RichTextLabel else ["font_size"]
	for k: String in claves:
		if c.get_theme_font_size(k) < piso:
			c.add_theme_font_size_override(k, piso)
