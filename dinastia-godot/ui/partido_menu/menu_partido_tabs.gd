class_name MenuPartidoTabs
extends RefCounted
## LAS PESTAÑAS INFORMATIVAS DEL MENÚ DEL PARTIDO (17-11-2026): previa (forma, mejores, consejos), uniforme, estadio y plan de juego. Solo leen datos del juego.

const COLOR_V := Color("3fa06a")
const COLOR_E := Color("c9a227")
const COLOR_D := Color("c0392b")

static func _txt(padre: Control, texto: String, tam := Tema.TAM_CUERPO, col := Tema.TEXTO) -> Label:
	var l := Tema.etiqueta(tam, col, texto)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	padre.add_child(l)
	return l

static func _escudo(c: Club, px: int) -> TextureRect:
	var t := TextureRect.new()
	t.texture = Escudo.textura(c, px)
	t.custom_minimum_size = Vector2(px, px)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return t

## La racha: una ficha por partido, V / E / D con su color.
static func _racha(padre: Control, racha: Array) -> void:
	var f := HBoxContainer.new()
	f.add_theme_constant_override("separation", 4)
	for r: String in racha:
		var l := Tema.etiqueta(Tema.TAM_CUERPO, Color.WHITE, r)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.custom_minimum_size = Vector2(28, 26)
		var sb := Tema.caja({"V": COLOR_V, "E": COLOR_E}.get(r, COLOR_D), 4)
		l.add_theme_stylebox_override("normal", sb)
		f.add_child(l)
	padre.add_child(f)

static func _columna(padre: Control, club: Club, d: Dictionary, es_rival: bool) -> void:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 6)
	padre.add_child(v)
	var cab := HBoxContainer.new()
	cab.add_child(_escudo(club, 34))
	cab.add_child(Tema.etiqueta(Tema.TAM_DESTACADO, Tema.ORO, " " + club.nombre))
	v.add_child(cab)
	_txt(v, Idiomas.t("Media del once: %.1f") % float(d["media_rival" if es_rival else "media_mia"]), Tema.TAM_CUERPO, Tema.SUAVE)
	if es_rival:
		_txt(v, Idiomas.t("Puesto %d · %d pts") % [int(d["puesto"]), int(d["pts"])], Tema.TAM_CUERPO, Tema.SUAVE)
		_racha(v, d["racha"])
		for j: Jugador in d["mejores"]:
			_txt(v, "%s · %s · %d" % [Nombres.visible(j.nombre), j.pos_e, j.ovr])
		if int(d["bajas"]) > 0:
			_txt(v, Idiomas.t("Lesionados: %d") % int(d["bajas"]), Tema.TAM_CUERPO, COLOR_D)
	else:
		var orden: Array = club.once().duplicate()
		orden.sort_custom(func(x: Jugador, y: Jugador) -> bool: return x.ovr > y.ovr)
		for j: Jugador in orden.slice(0, 3):
			_txt(v, "%s · %s · %d" % [Nombres.visible(j.nombre), j.pos_e, j.ovr])

static func previa(padre: VBoxContainer, mio: Club, rival: Club, liga_rival: Liga) -> void:
	var d := InformeRival.datos(rival, mio, liga_rival)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 30)
	padre.add_child(fila)
	_columna(fila, mio, d, false)
	_columna(fila, rival, d, true)
	padre.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.ORO, Idiomas.t("CONSEJOS").to_upper()))
	for c: String in d["consejos"]:
		_txt(padre, "• " + Idiomas.t(c))

static func _kit(padre: Control, c: Club, titulo: String) -> void:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	padre.add_child(v)
	v.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, Idiomas.t(titulo)))
	v.add_child(Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, c.nombre))
	var f := HBoxContainer.new()
	for hexa: String in [c.kit_color1 if c.kit_color1 != "" else c.color1, c.kit_color2 if c.kit_color2 != "" else c.color2]:
		var r := ColorRect.new()
		r.color = Color(hexa)
		r.custom_minimum_size = Vector2(96, 96)
		f.add_child(r)
	v.add_child(f)

static func uniforme(padre: VBoxContainer, local: Club, visita: Club) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 30)
	padre.add_child(fila)
	_kit(fila, local, "Local")
	_kit(fila, visita, "Visitante")

static func estadio(padre: VBoxContainer, local: Club, clima: Dictionary) -> void:
	padre.add_child(Tema.etiqueta(Tema.TAM_TITULO, Tema.ORO, local.estadio_nombre if local.estadio_nombre != "" else Idiomas.t("Estadio de %s") % local.nombre))
	_txt(padre, Idiomas.t("Aforo: %d espectadores") % local.estadio_aforo)
	if not clima.is_empty():
		_txt(padre, "%s %s" % [Clima.icono(clima), String(clima.get("texto", ""))])

static func plan(padre: VBoxContainer, mio: Club) -> void:
	if mio.tactica != null:
		_txt(padre, InformeRival.texto_pizarra(mio.tactica))
	_txt(padre, Idiomas.t("La pizarra se cambia desde el club (Pizarra y dibujo) y, durante el partido, con Esc."), Tema.TAM_CUERPO, Tema.SUAVE)
