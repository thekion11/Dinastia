class_name TextoQueCabe
## M-467 (27-10-2026): EL TEXTO QUE NO CABE SE ENCOGE ANTES DE CORTARSE. En alemán, «Gehaltsverhandlung» o
## «Assistent aufstellen lassen» no caben en botones pensados para el español, y con `clip_text` o «…» se leían a
## medias. Al entrar en el árbol (y al cambiar de tamaño) cada botón o etiqueta de una línea que recorta su texto
## baja la letra lo justo para que quepa, hasta `MINIMO` de su tamaño; si ni así cabe, recorta como antes.
## Lo mide `pruebas/recorrido_pantallas.gd` con RECORRIDO_IDIOMA=de RECORRIDO_LARGOS=<ruta>.

const MINIMO := 0.72

## Se llama una vez, al arrancar (`Idiomas._ready`).
static func vigilar(arbol: SceneTree) -> void:
	if not arbol.node_added.is_connected(_al_entrar):
		arbol.node_added.connect(_al_entrar)

static func _al_entrar(n: Node) -> void:
	if not (n is Button or n is Label):
		return
	var c := n as Control
	if not _recorta(c):
		return
	if not c.has_meta("cabe_vigilado"):
		c.set_meta("cabe_vigilado", true)
		c.resized.connect(ajustar.bind(c))
		## La traducción (y cualquier cambio de rótulo) llega a menudo DESPUÉS de entrar en el árbol: al cambiar
		## el texto el control se redibuja, y ahí se vuelve a medir. Solo si el texto es otro, así que sale barato.
		c.draw.connect(_si_cambio.bind(c))
	ajustar.call_deferred(c)

static func _si_cambio(c: Control) -> void:
	if String(c.get("text")) != String(c.get_meta("texto_medido", "")):
		ajustar.call_deferred(c)

static func _recorta(c: Control) -> bool:
	if c is Label and (c as Label).autowrap_mode != TextServer.AUTOWRAP_OFF:
		return false
	if c is Button and (c as Button).autowrap_mode != TextServer.AUTOWRAP_OFF:
		return false
	return bool(c.get("clip_text")) or int(c.get("text_overrun_behavior")) != TextServer.OVERRUN_NO_TRIMMING

## Deja la letra en el tamaño más grande (hasta el original) con el que el texto cabe en el control.
static func ajustar(c: Control) -> void:
	if not is_instance_valid(c) or not c.is_inside_tree() or c.size.x < 8.0:
		return
	var t := String(c.get("text"))
	c.set_meta("texto_medido", t)
	if t == "" or t.contains("\n"):
		return
	if not c.has_meta("tam_base"):
		c.set_meta("tam_base", c.get_theme_font_size("font_size"))
	var base := int(c.get_meta("tam_base"))
	var hueco := c.size.x
	if c is Button:
		var b := c as Button
		hueco -= b.get_theme_stylebox("normal").get_minimum_size().x
		if b is OptionButton:
			hueco -= float(b.get_theme_icon("arrow").get_width()) + float(b.get_theme_constant("arrow_margin"))
		if b.icon != null:
			hueco -= float(b.icon.get_width()) + float(b.get_theme_constant("h_separation"))
	var f := c.get_theme_font("font")
	var ancho := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, base).x
	var tam := base
	if ancho > hueco and ancho > 0.0:
		tam = maxi(int(ceil(base * MINIMO)), int(floor(base * hueco / ancho)))
		## Si ni al mínimo cabe, el botón parte el rótulo en dos líneas: más alto, pero se lee entero.
		if c is Button and ancho * float(tam) / float(base) > hueco and t.contains(" "):
			(c as Button).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	## Solo se toca la letra de los que no caben; al que ya se encogió se le devuelve su tamaño si vuelve a caber.
	if tam != base or c.has_meta("tam_tocado"):
		c.set_meta("tam_tocado", true)
		c.add_theme_font_size_override("font_size", tam)
