class_name EventoSeleccion
extends EventoPantallaCompleta
## LA SELECCIÓN, A PANTALLA COMPLETA (10-11, encargo del dueño, punto 2). Dos usos, con la paleta noche y el color de la selección en los filetes:
## - `oferta`: te llama una federación (escudo, fuerza, sueldo) → «si» / «no»;
## - `partido`: el siguiente partido de tu selección en un torneo (fase, los dos escudos y tu grupo) → «jugar» / «simular» / «resto».
## Emite `elegido(op)`.
static func oferta(pr: Principal, sel: Club, fuerza: int, sueldo: int) -> EventoSeleccion:
	var e := EventoSeleccion.new()
	e.paleta_noche = true
	e.acento = Color(sel.color1) if sel.color1 != "#ffffff" else Color(sel.color2)
	e._montar_base(pr)
	e._centro.add_child(etiqueta("☎️ " + Idiomas.t("TE LLAMA UNA FEDERACIÓN"), 15, Tema.SUAVE))
	e._centro.add_child(etiqueta("%s %s" % [Idiomas.t("Seleccionador de"), sel.nombre], 42, Color.WHITE, true, false))
	e._centro.add_child(_escudo(sel, 150))
	e._centro.add_child(etiqueta("%s %d · %s %s" % [Idiomas.t("Fuerza de la selección:"), fuerza, Idiomas.t("sueldo:"),
		Idiomas.t("%s / semana") % pr._dinero(sueldo)], 18, Tema.TEXTO))
	e._centro.add_child(etiqueta(Idiomas.t("Es un cargo doble: sigues dirigiendo tu club. Elegirás tus convocados entre los jugadores de su país de todo el mundo y dirigirás sus torneos (Mundial y torneo continental), en directo o simulados."), 16, Tema.SUAVE))
	e._botones([["si", "✔ " + Idiomas.t("Aceptar el cargo"), true], ["no", Idiomas.t("Rechazar"), false]])
	return e

static func partido(pr: Principal, t: TorneoSelecciones, mia: Club, rival: Club) -> EventoSeleccion:
	var e := EventoSeleccion.new()
	e.paleta_noche = true
	e.acento = Color(mia.color1)
	e._montar_base(pr)
	e._centro.add_child(etiqueta("%s %d · %s" % [t.nombre.to_upper(), t.anio, Idiomas.t(t.nombre_fase())], 16, Tema.SUAVE))
	var duelo := HBoxContainer.new()
	duelo.alignment = BoxContainer.ALIGNMENT_CENTER
	duelo.add_theme_constant_override("separation", 40)
	e._centro.add_child(duelo)
	duelo.add_child(_escudo(mia, 130))
	duelo.add_child(etiqueta("VS", 40, Color.WHITE, true, false))
	duelo.add_child(_escudo(rival, 130))
	if t.en_grupos:
		for g: Array in t.grupos:
			if g.has(mia):
				e._centro.add_child(_tabla(t, g, mia))
	else:
		e._centro.add_child(etiqueta(Idiomas.t("Partido único: si hay empate, penaltis."), 16, Tema.SUAVE))
	e._botones([["jugar", "▶ " + Idiomas.t("Jugarlo"), true], ["simular", "⏭ " + Idiomas.t("Simularlo"), false],
		["resto", Idiomas.t("Simular el resto del torneo"), false]])
	return e

func _botones(lista: Array) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	_centro.add_child(fila)
	for par: Array in lista:
		var b := boton(String(par[1]), bool(par[2]))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var op := String(par[0])
		b.pressed.connect(func() -> void: elegido.emit(op))
		fila.add_child(b)
		if bool(par[2]):
			b.call_deferred("grab_focus")

static func _escudo(c: Club, alto: int) -> Control:
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 8)
	var tr := TextureRect.new()
	tr.texture = Escudo.textura(c, alto)
	tr.custom_minimum_size = Vector2(alto, alto)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(tr)
	var n := etiqueta(c.nombre, 22, Color.WHITE)
	n.custom_minimum_size = Vector2(220, 0)
	col.add_child(n)
	return col

## La tabla del grupo de tu selección (tu fila resaltada).
static func _tabla(t: TorneoSelecciones, g: Array, mia: Club) -> Control:
	var rej := GridContainer.new()
	rej.columns = 5
	rej.add_theme_constant_override("h_separation", 22)
	rej.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for cab: String in ["", "PJ", "GF", "GC", "PTS"]:
		rej.add_child(etiqueta(Idiomas.t(cab), 13, Tema.SUAVE, true, false))
	for f: Dictionary in t.tabla_de_grupo(g):
		var c: Club = f["club"]
		var col := Tema.ORO if c == mia else Tema.TEXTO
		rej.add_child(etiqueta(c.nombre, 16, col, false, false))
		for k: String in ["pj", "gf", "gc", "pts"]:
			rej.add_child(etiqueta(str(int(f[k])), 16, col, true, false))
	return rej
