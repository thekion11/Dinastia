class_name PlantillaHabilidades
extends RefCounted
## MAPA DE CALOR Y HABILIDADES CON ESTRELLAS EN LA PLANTILLA (orden del dueño, 9-11; hecho el 10-11; como la «Información del jugador» del PES):
## el radar de atributos con el MAPA DE CALOR a su lado (`MapaCalorJugador`) y, bajo el estilo de juego, las HABILIDADES individuales con
## ★★★ (`HabilidadesJugador`). Lo usa `PlantillaPes._pintar_info`.

## El radar y, a su derecha, el mapa de calor del jugador.
static func junto_al_mapa(radar: Control, j: Jugador) -> Control:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	radar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(radar)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.add_child(_rotulo(Idiomas.t("MAPA DE CALOR"), 12, Tema.ORO))
	col.add_child(MapaCalorJugador.crear(j, Vector2(132, 180)))
	fila.add_child(col)
	return fila

## La lista de habilidades con sus estrellas (o el aviso de que no tiene ninguna destacada).
static func pintar(j: Jugador, caja: Container) -> void:
	caja.add_child(_rotulo(Idiomas.t("HABILIDADES"), 12, Tema.ORO))
	var lista := HabilidadesJugador.de(j)
	if lista.is_empty():
		caja.add_child(_rotulo(Idiomas.t("Sin habilidades destacadas todavía."), 12, Tema.SUAVE))
		return
	var rejilla := GridContainer.new()
	rejilla.columns = 2
	rejilla.add_theme_constant_override("h_separation", 14)
	for h: Dictionary in lista:
		var n := int(h["estrellas"])
		var l := _rotulo("%s  %s" % ["★".repeat(n) + "☆".repeat(3 - n), Idiomas.t(String(h["nombre"]))], 13, Tema.ORO if n == 3 else Tema.TEXTO)
		l.tooltip_text = "%s: %d" % [Idiomas.t("Puntuación"), int(round(float(h["puntos"])))]
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		rejilla.add_child(l)
	caja.add_child(rejilla)

static func _rotulo(texto: String, tam: int, color: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", Tema.letra(tam))
	l.add_theme_color_override("font_color", color)
	return l

## El brazalete del capitán: una «C» en una chapa amarilla (lo usan la lista de la plantilla y su ficha).
static func brazalete() -> Control:
	var pc := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color("ffd600")
	st.set_corner_radius_all(4)
	st.content_margin_left = 5
	st.content_margin_right = 5
	pc.add_theme_stylebox_override("panel", st)
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pc.tooltip_text = Idiomas.t("Capitán")
	var l := _rotulo("C", 12, Color(0.1, 0.1, 0.1))
	pc.add_child(l)
	return pc
