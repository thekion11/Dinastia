class_name CarruselQuieto
extends RefCounted
## EL CARRUSEL QUIETO (16-11, frente 1; plan «Mundo suave, fase 2», inspirado en la maqueta del dueño): lo que antes cambiaba SOLO cada
## 30 s (la portada del menú de inicio y el fondo de la página) se queda quieto y se cambia a mano, con flechas ◂ ▸ y puntos
## en medio (el de la actual, encendido), como los carruseles de los menús de PES 2020 / FC. El cambio sigue fundido.
## `poner(banner, al_paso)` monta flechas y puntos sobre `banner`; `marcar(banner, total, actual)` enciende el punto que toca.

const LADO := 28.0

## Una sola fila arriba al centro del banner (◂ ● ● ● ▸): ahí no pisa el título ni el lema, que van abajo a la izquierda.
static func poner(banner: Control, al_paso: Callable) -> void:
	var lado := 48.0 if EscalaMovil.es_tactil() else LADO   ## en el teléfono, 7 mm de toque
	var fila := HBoxContainer.new()
	fila.name = "Carrusel"
	fila.add_theme_constant_override("separation", 8)
	fila.anchor_left = 0.5; fila.anchor_right = 0.5
	fila.grow_horizontal = Control.GROW_DIRECTION_BOTH
	fila.offset_top = 8; fila.offset_bottom = 8 + lado
	banner.add_child(fila)
	var puntos := HBoxContainer.new()
	puntos.name = "CarruselPuntos"
	puntos.add_theme_constant_override("separation", 4)
	puntos.alignment = BoxContainer.ALIGNMENT_CENTER
	puntos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for d in [-1, 1]:
		var b := Button.new()
		b.text = "◂" if d < 0 else "▸"
		b.name = "CarruselAnterior" if d < 0 else "CarruselSiguiente"
		b.tooltip_text = Idiomas.t("Portada anterior") if d < 0 else Idiomas.t("Portada siguiente")
		b.custom_minimum_size = Vector2(lado, lado)
		b.add_theme_font_size_override("font_size", Tema.letra(13))
		b.add_theme_stylebox_override("normal", Tema.caja(Color(0, 0, 0, 0.45), int(lado / 2.0), Color(1, 1, 1, 0.25)))
		var enc := Tema.caja(Color(0, 0, 0, 0.7), int(lado / 2.0), Tema.al_mundo(Tema.ORO, 2))
		for k: String in ["hover", "focus", "pressed"]:
			b.add_theme_stylebox_override(k, enc)
		b.pressed.connect(al_paso.bind(d))
		fila.add_child(b)
		if d < 0:
			fila.add_child(puntos)
	puntos.size_flags_vertical = Control.SIZE_SHRINK_CENTER

static func marcar(banner: Control, total: int, actual: int) -> void:
	var puntos := banner.get_node_or_null("Carrusel/CarruselPuntos") as HBoxContainer
	if puntos == null:
		return
	while puntos.get_child_count() < total:
		var r := ColorRect.new()
		r.custom_minimum_size = Vector2(6, 6)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		puntos.add_child(r)
	for i in puntos.get_child_count():
		var r := puntos.get_child(i) as ColorRect
		r.visible = i < total
		r.custom_minimum_size = Vector2(14 if i == actual else 6, 6)
		r.color = Tema.al_mundo(Tema.ORO, 2) if i == actual else Color(1, 1, 1, 0.35)
