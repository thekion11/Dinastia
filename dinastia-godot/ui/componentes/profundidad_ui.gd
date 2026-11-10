class_name ProfundidadUI
extends RefCounted
## PROFUNDIDAD EN LOS MENÚS (orden del dueño, estética: «profundidad de cabeceras, portadas, Ajustes y botones»; hecho el 10-11). Antes todo era
## plano: cajas negras translúcidas con un borde de 1 px. Aquí, con StyleBoxFlat (sin texturas ni shaders, coste ~0):
## - BOTONES con RELIEVE: sombra proyectada hacia abajo en reposo y al pasar por encima (se «levanta»), y al pulsar se HUNDE (sin sombra y el
##   texto baja 2 px). Vale para el tema de toda la interfaz (Ajustes incluido) y para los botones propios de la cabecera.
## - CABECERA en una BANDA: fondo oscuro, filo inferior del color del menú y sombra debajo, para que se separe del contenido.
## - TARJETAS de portada con BRILLO arriba (un degradado claro que se apaga hacia abajo y un filo de luz de 1 px) y sombra más larga.
const SOMBRA := Color(0, 0, 0, 0.42)

## Relieve de un estilo de botón en reposo/encima (`levantado`: un poco más de sombra).
static func relieve(st: StyleBoxFlat, levantado := false) -> StyleBoxFlat:
	st.shadow_color = SOMBRA
	st.shadow_size = 6 if levantado else 4
	st.shadow_offset = Vector2(0, 4 if levantado else 2)
	return st

## El mismo estilo, HUNDIDO (pulsado): sin sombra y el contenido 2 px más abajo.
static func hundido(st: StyleBoxFlat) -> StyleBoxFlat:
	var h := st.duplicate() as StyleBoxFlat
	h.shadow_size = 0
	h.shadow_offset = Vector2.ZERO
	h.content_margin_top = maxf(st.content_margin_top, 0.0) + 2.0
	h.content_margin_bottom = maxf(st.content_margin_bottom - 2.0, 0.0)
	return h

## Aplica relieve a los estados de un botón ya estilado (`normal`, `hover`, `focus`, `pressed`).
static func boton(b: Button) -> void:
	for estado: String in ["normal", "hover", "focus"]:
		var st := b.get_theme_stylebox(estado) as StyleBoxFlat
		if st != null:
			b.add_theme_stylebox_override(estado, relieve(st.duplicate() as StyleBoxFlat, estado != "normal"))
	var p := b.get_theme_stylebox("pressed") as StyleBoxFlat
	if p != null:
		b.add_theme_stylebox_override("pressed", hundido(p))

## Mete la cabecera `cab` (ya montada) en una banda con fondo, filo de color abajo y sombra. Devuelve la banda (va en el lugar de `cab`).
static func banda(cab: Control, acento: Color) -> PanelContainer:
	var pc := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0, 0, 0, 0.32)
	st.border_color = Color(acento, 0.85)
	st.border_width_bottom = 2
	st.set_corner_radius_all(14)
	st.shadow_color = Color(0, 0, 0, 0.35)
	st.shadow_size = 12
	st.shadow_offset = Vector2(0, 5)
	st.content_margin_left = 10
	st.content_margin_right = 16
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	pc.add_theme_stylebox_override("panel", st)
	pc.add_child(cab)
	return pc

## Brillo de una tarjeta: un degradado claro arriba (se apaga a la mitad) y un filo de luz de 1 px en el borde superior.
static func brillo(tarjeta: Control, radio := 16) -> void:
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 0.09))
	grad.set_color(1, Color(1, 1, 1, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 0.55)
	gt.width = 8
	gt.height = 64
	var tr := TextureRect.new()
	tr.texture = gt
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.offset_left = 2
	tr.offset_right = -2
	tr.offset_top = 1
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tarjeta.add_child(tr)
	var filo := ColorRect.new()
	filo.color = Color(1, 1, 1, 0.16)
	filo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	filo.offset_left = radio
	filo.offset_right = -radio
	filo.offset_top = 1
	filo.offset_bottom = 2
	filo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tarjeta.add_child(filo)
