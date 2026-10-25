extends RefCounted
## [Capa 1/2 de `pantalla_editor.gd`] _init, _texto_con, _pintar_editor_competiciones, _fila_mas_menos, _pintar_editor_clubes, _rejilla_editor … (+6)

## EL EDITOR: competiciones, clubes, jugadores y CSV.
##
## Sale de `ui/principal.gd` (mapa de metas 15: el archivo pasaba de
## 15.000 líneas). `p` es la pantalla principal: sus ayudantes (`p._texto`,
## `p._boton`...), el mundo (`p.mundo`) y el repintado (`p._refrescar()`).

var p: Principal

func _init(principal: Principal) -> void:
	p = principal

func _texto_con(tam: int, col: Color, txt: String) -> Label:
	var l := p._texto(tam, col)
	l.text = txt
	return l

## Rótulo y control JUNTOS en una caja: dentro de una fila que se parte
## (`HFlowContainer`), sueltos se separaban -«Victoria:» al final de una línea y
## su desplegable solo en la siguiente-.
func _par(rotulo: String, control: Control) -> HBoxContainer:
	var caja := HBoxContainer.new()
	caja.add_theme_constant_override("separation", 4)
	var l := _texto_con(11, Principal.COL_SUAVE, rotulo)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caja.add_child(l)
	caja.add_child(control)
	return caja

## Los desplegables traían la letra del tema (~20 px) en filas de 11-12: se
## veían el doble de grandes que todo lo de alrededor.
func _letra_12(ob: OptionButton) -> OptionButton:
	ob.add_theme_font_size_override("font_size", 12)
	ob.get_popup().add_theme_font_size_override("font_size", 12)
	return ob

## EL EDITOR DE COMPETICIONES (28-9-2026, bloque 47): las ligas de tu país
## (nombre, cuántos bajan, puntos por victoria) y la copa (nombre y sede fija
## de la final).
func _pintar_editor_competiciones(ed: Editor) -> void:
	var mio := p.mundo.mi_club()
	if mio == null:
		return
	p._lista_editor.add_child(HSeparator.new())
	var t := p._texto(11, p.COL_ACENTO)
	t.text = Idiomas.t("COMPETICIONES")
	p._lista_editor.add_child(t)
	for l: Liga in p.mundo.ligas:
		if l.pais != mio.pais:
			continue
		## Filas que SE PARTEN (etapa 1): en una sola línea eran más anchas que la
		## columna y sacaban de la pantalla la ficha del jugador.
		var fila := HFlowContainer.new()
		fila.add_theme_constant_override("h_separation", 6)
		fila.add_theme_constant_override("v_separation", 4)
		p._lista_editor.add_child(fila)
		var nom := LineEdit.new()
		nom.text = l.nombre
		nom.custom_minimum_size = Vector2(220, 0)
		nom.add_theme_font_size_override("font_size", 12)
		var liga := l
		nom.text_submitted.connect(func(x: String) -> void:
			var p_local := ed.renombrar_liga(liga, x)
			if p_local != "":
				p._escribir("[color=#e05555]%s.[/color]" % p_local)
			p._refrescar())
		fila.add_child(nom)
		var desc := SpinBox.new()
		desc.min_value = 1
		desc.max_value = 4
		desc.value = l.plazas_descenso
		desc.get_line_edit().add_theme_font_size_override("font_size", 12)
		desc.value_changed.connect(func(v: float) -> void: ed.fijar_descensos(liga, int(v)))
		fila.add_child(_par("Bajan/suben:", desc))
		var pv := OptionButton.new()
		pv.add_item("3 puntos", 3)
		pv.add_item("2 puntos", 2)
		pv.select(0 if l.puntos_victoria == 3 else 1)
		pv.item_selected.connect(func(i: int) -> void: ed.fijar_puntos_victoria(liga, 3 if i == 0 else 2))
		fila.add_child(_par("Victoria:", _letra_12(pv)))
	if p.mundo.copa != null:
		var fila_c := HFlowContainer.new()
		fila_c.add_theme_constant_override("h_separation", 6)
		fila_c.add_theme_constant_override("v_separation", 4)
		p._lista_editor.add_child(fila_c)
		var nc := LineEdit.new()
		nc.text = p.mundo.copa.nombre
		nc.custom_minimum_size = Vector2(220, 0)
		nc.add_theme_font_size_override("font_size", 12)
		nc.text_submitted.connect(func(x: String) -> void:
			var p_local := ed.renombrar_copa(x)
			if p_local != "":
				p._escribir("[color=#e05555]%s.[/color]" % p_local)
			p._refrescar())
		fila_c.add_child(nc)
		var sede := OptionButton.new()
		sede.add_item("Cancha neutral", 0)
		var sedes: Array[Club] = []
		for c: Club in p.mundo.clubes.values():
			if c.pais == mio.pais and c.division == 1:
				sedes.append(c)
		sedes.sort_custom(func(a: Club, b: Club) -> bool: return a.estadio_aforo > b.estadio_aforo)
		for i in sedes.size():
			var c3: Club = sedes[i]
			sede.add_item("%s (%s)" % [c3.estadio_nombre if c3.estadio_nombre != "" else c3.nombre, c3.nombre], i + 1)
			if c3.id == p.mundo.copa.sede_final_id:
				sede.select(i + 1)
		sede.item_selected.connect(func(i: int) -> void: ed.fijar_sede_final(null if i == 0 else sedes[i - 1]))
		## Con tope de ancho: el nombre de un estadio largo estiraba el
		## desplegable más allá de la columna.
		sede.clip_text = true
		sede.custom_minimum_size = Vector2(200, 0)
		fila_c.add_child(_par("Sede de la final:", _letra_12(sede)))

## Una fila "etiqueta  −  valor  +". Es el patrón de todo el editor: no se
## escriben números a mano porque un campo de texto que hay que validar en cada
## pulsación es más frágil que dos botones.
func _fila_mas_menos(etiqueta: String, valor: String, accion: Callable, padre: Node) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	padre.add_child(fila)
	var et := p._texto(11, Principal.COL_TEXTO)
	et.text = etiqueta
	et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et.clip_text = true
	fila.add_child(et)
	var bm := Button.new()
	bm.text = "−"
	bm.add_theme_font_size_override("font_size", 12)
	bm.custom_minimum_size = Vector2(30, 22)
	bm.pressed.connect(func() -> void:
		accion.call(-1)
		p._refrescar())
	fila.add_child(bm)
	var v := p._texto(12, Principal.COL_ORO)
	v.text = valor
	v.custom_minimum_size = Vector2(58, 0)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fila.add_child(v)
	var bp := Button.new()
	bp.text = "+"
	bp.add_theme_font_size_override("font_size", 12)
	bp.custom_minimum_size = Vector2(30, 22)
	bp.pressed.connect(func() -> void:
		accion.call(1)
		p._refrescar())
	fila.add_child(bp)

func _pintar_editor_clubes(ed: Editor) -> void:
	p._lista_editor.add_child(HSeparator.new())
	var t := p._texto(11, p.COL_ACENTO)
	t.text = Idiomas.t("CLUBES")
	p._lista_editor.add_child(t)
	var busca := LineEdit.new()
	busca.text = p._ed_filtro
	busca.placeholder_text = Idiomas.t("Buscar en todo el mundo… (vacío: los de tu país)")
	busca.add_theme_font_size_override("font_size", 12)
	busca.text_submitted.connect(func(x: String) -> void:
		p._ed_filtro = x.strip_edges()
		p._refrescar())
	p._lista_editor.add_child(busca)

	var mio := p.mundo.mi_club()
	var lista: Array[Club] = []
	for c: Club in p.mundo.clubes.values():
		if p._ed_filtro == "":
			if mio != null and c.pais == mio.pais:
				lista.append(c)
		elif Nombres.limpiar(c.nombre).to_lower().contains(p._ed_filtro.to_lower()):
			lista.append(c)
	lista.sort_custom(func(a: Club, b: Club) -> bool: return a.rep > b.rep)

	for i in mini(30, lista.size()):
		var c2: Club = lista[i]
		var abierto := p._ed_club == c2.id
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_editor.add_child(fila)
		## Con sus iniciales (o su símbolo), como en las tablas: el SVG solo no
		## las lleva, y sin ellas medio país eran círculos de un color.
		fila.add_child(p._escudo(c2, 22))
		var b := Button.new()
		b.text = Idiomas.t("%s%s  ·  %s D%d  ·  rep %d") % ["▾ " if abierto else "▸ ",
			c2.nombre, c2.pais, c2.division, c2.rep]
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 12)
		b.add_theme_color_override("font_color", p._color_de_paleta(Principal.COL_ORO if abierto else Principal.COL_TEXTO))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		b.pressed.connect(func() -> void:
			p._ed_club = "" if abierto else c2.id
			p._ed_confirmar_regen = ""
			p._refrescar())
		fila.add_child(b)
		if not abierto:
			continue

		var campo := LineEdit.new()
		campo.text = c2.nombre
		campo.add_theme_font_size_override("font_size", 12)
		campo.text_submitted.connect(func(x: String) -> void:
			var p_local := ed.renombrar_club(c2, x)
			if p_local != "":
				p._escribir("[color=#e05555]%s.[/color]" % p_local)
			p._refrescar())
		p._lista_editor.add_child(campo)
		for par: Array in [["Color 1", "color1"], ["Color 2", "color2"]]:
			var prop := String(par[1])
			var f2 := HBoxContainer.new()
			f2.add_theme_constant_override("separation", 6)
			p._lista_editor.add_child(f2)
			var e2 := p._texto(11, Principal.COL_TEXTO)
			e2.text = String(par[0])
			e2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			f2.add_child(e2)
			var cp := ColorPickerButton.new()
			cp.color = Color(String(c2.get(prop)))
			cp.custom_minimum_size = Vector2(84, 24)
			cp.edit_alpha = false
			cp.color_changed.connect(func(nuevo: Color) -> void:
				c2.set(prop, "#" + nuevo.to_html(false))
				Escudo.limpiar_cache()
				p._refrescar())
			f2.add_child(cp)
		_fila_mas_menos("Reputación", str(c2.rep),
			func(d: int) -> void: ed.mover_reputacion(c2, d * 2), p._lista_editor)
		_fila_mas_menos("Aforo", p._miles(c2.estadio_aforo),
			func(d: int) -> void: ed.mover_aforo(c2, d * 5000), p._lista_editor)
		var br := Button.new()
		var pidiendo := p._ed_confirmar_regen == c2.id
		br.text = Idiomas.t("¿SEGURO? Se pierde la plantilla entera") if pidiendo else Idiomas.t("🎲 Regenerar plantel")
		br.add_theme_font_size_override("font_size", 11)
		br.add_theme_color_override("font_color", p._color_de_paleta(Principal.COL_ROJO if pidiendo else Principal.COL_TEXTO))
		br.pressed.connect(func() -> void:
			if not pidiendo:
				p._ed_confirmar_regen = c2.id
				p._refrescar()
				return
			p._ed_confirmar_regen = ""
			var p_local := ed.regenerar_plantel(c2)
			if p_local != "":
				p._escribir("[color=#e05555]No se puede: %s.[/color]" % p_local)
			else:
				p._escribir("[color=#c9a227]Plantel de %s regenerado.[/color]" % c2.nombre)
			p._refrescar())
		p._lista_editor.add_child(br)

func _rejilla_editor(titulo: String, opciones: Array, actual: String, accion: Callable) -> void:
	var lt := p._texto(10, Principal.COL_SUAVE)
	lt.text = titulo
	p._lista_editor.add_child(lt)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 4)
	p._lista_editor.add_child(flow)
	var vistas := {}
	for op: Variant in opciones:
		var clave := String(op)
		if vistas.has(clave):
			continue
		vistas[clave] = true
		var b := Button.new()
		b.text = clave if clave != "" else "—"
		b.add_theme_font_size_override("font_size", 10)
		b.toggle_mode = true
		b.button_pressed = actual == clave
		b.clip_text = true
		b.custom_minimum_size = Vector2(58, 22)
		b.pressed.connect(func() -> void:
			accion.call(clave)
			p._refrescar())
		flow.add_child(b)

func _rasgos_disponibles() -> Array:
	var t: Variant = Datos.tabla("RASGOS")
	if t is Dictionary:
		return (t as Dictionary).keys()
	return []

func _rejilla_colores_editor(ed: Editor, j: Jugador, clave: String, colores: Array, actual: String) -> void:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 3)
	p._lista_editor.add_child(flow)
	for col: Variant in colores:
		var hex := String(col)
		var b := Button.new()
		b.custom_minimum_size = Vector2(24, 22)
		b.text = "✔" if actual == hex else " "
		b.add_theme_font_size_override("font_size", 10)
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color(hex)
		estilo.corner_radius_top_left = 3
		estilo.corner_radius_top_right = 3
		estilo.corner_radius_bottom_left = 3
		estilo.corner_radius_bottom_right = 3
		b.add_theme_stylebox_override("normal", estilo)
		b.add_theme_stylebox_override("hover", estilo)
		b.add_theme_stylebox_override("pressed", estilo)
		b.pressed.connect(func() -> void:
			ed.fijar_look(j, clave, hex)
			p._refrescar())
		flow.add_child(b)

func _pintar_editor_ficha(ed: Editor, j: Jugador, c: Club) -> void:
	var cara := TextureRect.new()
	cara.texture = Cara.textura(j, c.color_kit1(), c.color_kit2(), 56)
	cara.custom_minimum_size = Vector2(56, 56)
	cara.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cara.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	p._lista_editor.add_child(cara)

	var campo := LineEdit.new()
	campo.text = j.nombre
	campo.add_theme_font_size_override("font_size", 12)
	campo.text_submitted.connect(func(x: String) -> void:
		var p_local := ed.fijar_campo(j, "nombre", x)
		if p_local != "":
			p._escribir("[color=#e05555]%s.[/color]" % p_local)
		p._refrescar())
	p._lista_editor.add_child(campo)

	_fila_mas_menos("Media", str(j.ovr),
		func(d: int) -> void: ed.fijar_campo(j, "ovr", j.ovr + d), p._lista_editor)
	_fila_mas_menos("Proyección", str(j.pot),
		func(d: int) -> void: ed.fijar_campo(j, "pot", j.pot + d), p._lista_editor)
	_fila_mas_menos("Edad", str(j.edad),
		func(d: int) -> void: ed.fijar_campo(j, "edad", j.edad + d), p._lista_editor)
	_fila_mas_menos("Dorsal", str(j.dorsal),
		func(d: int) -> void: ed.fijar_campo(j, "dorsal", j.dorsal + d), p._lista_editor)

	_rejilla_editor("Puesto", Editor.demarcaciones(), j.pos_e,
		func(v: String) -> void: ed.fijar_campo(j, "pos_e", v))
	_rejilla_editor("Rasgo", [""] + _rasgos_disponibles(), j.rasgo,
		func(v: String) -> void: ed.fijar_campo(j, "rasgo", v))
	var bandera: Dictionary = Datos.tabla("BANDERA")
	_rejilla_editor("País", bandera.keys(), j.pais,
		func(v: String) -> void: ed.fijar_campo(j, "pais", v))

	var ta := p._texto(10, Principal.COL_SUAVE)
	ta.text = Idiomas.t("Atributos  ·  la media se recalcula sola")
	p._lista_editor.add_child(ta)
	for k: String in j.atributos:
		var clave := k
		_fila_mas_menos(clave, str(int(j.atributos[k])),
			func(d: int) -> void: ed.mover_atributo(j, clave, d * 3), p._lista_editor)

	## LA CARA. Los quince rasgos salen de un hash del id; aquí se pisan los que
	## se toquen, y solo esos. Es lo que permite arreglar una cara sin tener que
	## redefinirla entera.
	var tl := p._texto(10, Principal.COL_SUAVE)
	tl.text = Idiomas.t("Aspecto")
	p._lista_editor.add_child(tl)
	var look := Cara.look_de(j)
	_rejilla_colores_editor(ed, j, "piel", Cara.PIELES, String(look["piel"]))
	_rejilla_colores_editor(ed, j, "peloC", Cara.PELOS, String(look["peloC"]))
	_rejilla_editor("Corte", Cara.CORTES, String(look["pelo"]),
		func(v: String) -> void: ed.fijar_look(j, "pelo", v))
	_rejilla_editor("Accesorio", Cara.ACCESORIOS, String(look["acc"]),
		func(v: String) -> void: ed.fijar_look(j, "acc", v))
	var fila_b := HBoxContainer.new()
	fila_b.add_theme_constant_override("separation", 4)
	p._lista_editor.add_child(fila_b)
	for par: Array in [["barba", "Barba", 8], ["nariz", "Nariz", 4], ["boca", "Boca", 3],
			["ojos", "Ojos", 4], ["cara", "Cara", 4], ["menton", "Mandíbula", 3]]:
		var clave2 := String(par[0])
		var tope: int = par[2]
		var bb := Button.new()
		bb.text = "%s ▸" % String(par[1])
		bb.add_theme_font_size_override("font_size", 10)
		bb.custom_minimum_size = Vector2(66, 22)
		bb.pressed.connect(func() -> void:
			ed.fijar_look(j, clave2, (int(Cara.look_de(j).get(clave2, 0)) + 1) % tope))
		fila_b.add_child(bb)
	var fila_s := HBoxContainer.new()
	fila_s.add_theme_constant_override("separation", 4)
	p._lista_editor.add_child(fila_s)
	for par2: Array in [["pecas", "Pecas"], ["lunar", "Lunar"], ["cicatriz", "Cicatriz"]]:
		var clave3 := String(par2[0])
		var bs := Button.new()
		bs.text = String(par2[1])
		bs.add_theme_font_size_override("font_size", 10)
		bs.toggle_mode = true
		bs.button_pressed = bool(look.get(clave3, false))
		bs.custom_minimum_size = Vector2(66, 22)
		bs.pressed.connect(func() -> void:
			ed.fijar_look(j, clave3, not bool(Cara.look_de(j).get(clave3, false))))
		fila_s.add_child(bs)

	var b_azar := Button.new()
	b_azar.text = Idiomas.t("🎲 Aleatorio")
	b_azar.add_theme_font_size_override("font_size", 11)
	b_azar.tooltip_text = Idiomas.t("Un aspecto entero nuevo de una sola vez, no rasgo a rasgo.")
	b_azar.pressed.connect(func() -> void:
		ed.aleatorizar_look(j)
		p._refrescar())
	p._lista_editor.add_child(b_azar)

func _pintar_editor_jugadores(ed: Editor) -> void:
	var c := p.mundo.mi_club()
	if c == null:
		return
	p._lista_editor.add_child(HSeparator.new())
	var t := p._texto(11, p.COL_ACENTO)
	t.text = Idiomas.t("JUGADORES DE TU PLANTEL")
	p._lista_editor.add_child(t)
	for j: Jugador in c.plantilla:
		var quien := j
		var abierto := p._ed_jugador == j.id
		var b := Button.new()
		b.text = Idiomas.t("%s%s  ·  %s  ·  %d años  ·  media %d") % ["▾ " if abierto else "▸ ",
			j.nombre, j.pos_e, j.edad, j.ovr]
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 12)
		b.add_theme_color_override("font_color", p._color_de_paleta(Principal.COL_ORO if abierto else Principal.COL_TEXTO))
		b.clip_text = true
		b.pressed.connect(func() -> void:
			p._ed_jugador = "" if abierto else quien.id
			p._refrescar())
		p._lista_editor.add_child(b)
		if abierto:
			_pintar_editor_ficha(ed, quien, c)
