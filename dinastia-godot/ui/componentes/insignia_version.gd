class_name InsigniaVersion
extends HBoxContainer
## LA MARCA DE LA VERSIÓN (2-11-2026): icono de color + «Windows · 0.9.0 · a1b2c3d» en una esquina, para que
## el jugador sepa qué descargó. Solo aparece en builds hechos por el CI (ver InfoBuild).

## Pone la insignia arriba a la derecha de `padre`; devuelve null (y no pone nada) si no hay datos de build.
static func poner(padre: Control, ruta: String = InfoBuild.RUTA) -> InsigniaVersion:
	var texto := InfoBuild.etiqueta(ruta)
	if texto == "":
		return null
	var ins := InsigniaVersion.new()
	ins.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ins.modulate = Color(1, 1, 1, 0.85)
	ins.add_theme_constant_override("separation", 8)
	var ico := InfoBuild.icono()
	if ico != null:
		var r := TextureRect.new()
		r.texture = ico
		r.custom_minimum_size = Vector2(28, 28)
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ins.add_child(r)
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Tema.SUAVE)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ins.add_child(l)
	ins.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 14)
	ins.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	padre.add_child(ins)
	return ins
