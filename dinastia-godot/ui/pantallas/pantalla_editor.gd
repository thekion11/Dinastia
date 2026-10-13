class_name PantallaEditor
extends RefCounted
## EL EDITOR: competiciones, clubes, jugadores y CSV.
##
## Sale de `ui/principal.gd` (mapa de metas 15: el archivo pasaba de
## 15.000 líneas). `p` es la pantalla principal: sus ayudantes (`p._texto`,
## `p._boton`...), el mundo (`p.mundo`) y el repintado (`p._refrescar()`).

var p: Principal

func _init(principal: Principal) -> void:
	p = principal

func _pintar_editor() -> void:
	p._limpiar(p._lista_editor)
	var ed := p._ui_ciudad._editor_de()
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "🛠️ EDITOR"
	p._lista_editor.add_child(t)
	if not p._modo_experto:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = "Renombra, repinta y reconstruye el mundo del juego: clubes, escudos, plantillas, atributos, puestos y caras. Los cambios van al guardado como cualquier otra cosa."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_editor.add_child(ex)

	_pintar_editor_competiciones(ed)
	_pintar_editor_clubes(ed)
	_pintar_editor_jugadores(ed)
	_pintar_editor_csv(ed)

## EL EDITOR DE COMPETICIONES (28-9-2026, bloque 47): las ligas de tu país
## (nombre, cuántos bajan, puntos por victoria) y la copa (nombre y sede fija
## de la final).
func _pintar_editor_competiciones(ed: Editor) -> void:
	var mio := p.mundo.mi_club()
	if mio == null:
		return
	p._lista_editor.add_child(HSeparator.new())
	var t := p._texto(11, p.COL_ACENTO)
	t.text = "COMPETICIONES"
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
		fila.add_child(_texto_con(11, Principal.COL_SUAVE, "Bajan/suben:"))
		var desc := SpinBox.new()
		desc.min_value = 1
		desc.max_value = 4
		desc.value = l.plazas_descenso
		desc.value_changed.connect(func(v: float) -> void: ed.fijar_descensos(liga, int(v)))
		fila.add_child(desc)
		fila.add_child(_texto_con(11, Principal.COL_SUAVE, "Victoria:"))
		var pv := OptionButton.new()
		pv.add_item("3 puntos", 3)
		pv.add_item("2 puntos", 2)
		pv.select(0 if l.puntos_victoria == 3 else 1)
		pv.item_selected.connect(func(i: int) -> void: ed.fijar_puntos_victoria(liga, 3 if i == 0 else 2))
		fila.add_child(pv)
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
		fila_c.add_child(_texto_con(11, Principal.COL_SUAVE, "Sede de la final:"))
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
		fila_c.add_child(sede)

func _texto_con(tam: int, col: Color, txt: String) -> Label:
	var l := p._texto(tam, col)
	l.text = txt
	return l

func _pintar_editor_clubes(ed: Editor) -> void:
	p._lista_editor.add_child(HSeparator.new())
	var t := p._texto(11, p.COL_ACENTO)
	t.text = "CLUBES"
	p._lista_editor.add_child(t)
	var busca := LineEdit.new()
	busca.text = p._ed_filtro
	busca.placeholder_text = "Buscar en todo el mundo… (vacío: los de tu país)"
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
		var esc := TextureRect.new()
		esc.texture = Escudo.textura(c2, 20)
		esc.custom_minimum_size = Vector2(20, 20)
		esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fila.add_child(esc)
		var b := Button.new()
		b.text = "%s%s  ·  %s D%d  ·  rep %d" % ["▾ " if abierto else "▸ ",
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
		br.text = "¿SEGURO? Se pierde la plantilla entera" if pidiendo else "🎲 Regenerar plantel"
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

func _pintar_editor_jugadores(ed: Editor) -> void:
	var c := p.mundo.mi_club()
	if c == null:
		return
	p._lista_editor.add_child(HSeparator.new())
	var t := p._texto(11, p.COL_ACENTO)
	t.text = "JUGADORES DE TU PLANTEL"
	p._lista_editor.add_child(t)
	for j: Jugador in c.plantilla:
		var quien := j
		var abierto := p._ed_jugador == j.id
		var b := Button.new()
		b.text = "%s%s  ·  %s  ·  %d años  ·  media %d" % ["▾ " if abierto else "▸ ",
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
	ta.text = "Atributos  ·  la media se recalcula sola"
	p._lista_editor.add_child(ta)
	for k: String in j.atributos:
		var clave := k
		_fila_mas_menos(clave, str(int(j.atributos[k])),
			func(d: int) -> void: ed.mover_atributo(j, clave, d * 3), p._lista_editor)

	## LA CARA. Los quince rasgos salen de un hash del id; aquí se pisan los que
	## se toquen, y solo esos. Es lo que permite arreglar una cara sin tener que
	## redefinirla entera.
	var tl := p._texto(10, Principal.COL_SUAVE)
	tl.text = "Aspecto"
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
	b_azar.text = "🎲 Aleatorio"
	b_azar.add_theme_font_size_override("font_size", 11)
	b_azar.tooltip_text = "Un aspecto entero nuevo de una sola vez, no rasgo a rasgo."
	b_azar.pressed.connect(func() -> void:
		ed.aleatorizar_look(j)
		p._refrescar())
	p._lista_editor.add_child(b_azar)

func _rasgos_disponibles() -> Array:
	var t: Variant = Datos.tabla("RASGOS")
	if t is Dictionary:
		return (t as Dictionary).keys()
	return []

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

## EL IMPORTADOR. Formato del HTML sin tocar, para que una base hecha para el
## HTML se pueda pegar aquí tal cual.
func _pintar_editor_csv(ed: Editor) -> void:
	p._lista_editor.add_child(HSeparator.new())
	var t := p._texto(11, p.COL_ACENTO)
	t.text = "IMPORTAR UNA BASE (CSV)"
	p._lista_editor.add_child(t)
	var ex := p._texto(10, Principal.COL_SUAVE)
	ex.text = "Una línea por futbolista: Club;Nombre;POS;Edad;Media[;País;Proyección;Pie]. POS admite grupos (POR/DEF/MED/DEL) o puestos concretos. Con %d filas o más de un mismo club, se REEMPLAZA su plantilla; con menos, se añaden." % Editor.FILAS_PARA_REEMPLAZAR
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_editor.add_child(ex)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	p._lista_editor.add_child(fila)
	var etc := p._texto(11, Principal.COL_TEXTO)
	etc.text = "Censurar los nombres importados"
	etc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etc.tooltip_text = "Sustituye algunas letras por números, como hace el resto del juego con los nombres generados."
	fila.add_child(etc)
	var bc := Button.new()
	bc.text = "SÍ" if p._ed_censura else "NO"
	bc.pressed.connect(func() -> void:
		p._ed_censura = not p._ed_censura
		p._refrescar())
	fila.add_child(bc)

	var caja := TextEdit.new()
	caja.text = p._ed_csv
	caja.placeholder_text = "C0lo-C0lo;Arturo Vidal;MED;38;79\nB0ca Juni0rs;Edinson Cavani;DEL;39;80;URU;80"
	caja.custom_minimum_size = Vector2(0, 120)
	caja.add_theme_font_size_override("font_size", 11)
	caja.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	caja.text_changed.connect(func() -> void: p._ed_csv = caja.text)
	p._lista_editor.add_child(caja)

	var bi := Button.new()
	bi.text = "📥 Importar"
	bi.add_theme_font_size_override("font_size", 11)
	bi.pressed.connect(func() -> void: _importar_csv(ed))
	p._lista_editor.add_child(bi)
	var bp := Button.new()
	bp.text = "📋 Pegar desde el portapapeles"
	bp.add_theme_font_size_override("font_size", 11)
	bp.pressed.connect(func() -> void:
		p._ed_csv = DisplayServer.clipboard_get()
		p._refrescar())
	p._lista_editor.add_child(bp)

	p._lista_editor.add_child(HSeparator.new())
	var te := p._texto(11, p.COL_ACENTO)
	te.text = "EXPORTAR LA BASE (CSV)"
	p._lista_editor.add_child(te)
	var ee := p._texto(10, Principal.COL_SUAVE)
	ee.text = "Mismo formato que el importador, con el pie hábil de regalo -no se puede reimportar, es calculado, no guardado- y sin habilidades -esas viven en el árbol de entrenamiento de cada club, no en el jugador-. Se copia al portapapeles."
	ee.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_editor.add_child(ee)
	var fila_ex := HBoxContainer.new()
	fila_ex.add_theme_constant_override("separation", 8)
	p._lista_editor.add_child(fila_ex)
	var b_mi := Button.new()
	b_mi.text = "Mi liga"
	b_mi.add_theme_font_size_override("font_size", 11)
	b_mi.pressed.connect(func() -> void: _exportar_csv(ed, true))
	fila_ex.add_child(b_mi)
	var b_todo := Button.new()
	b_todo.text = "Todo el mundo"
	b_todo.add_theme_font_size_override("font_size", 11)
	b_todo.pressed.connect(func() -> void: _exportar_csv(ed, false))
	fila_ex.add_child(b_todo)

## `solo_mi_liga`, no `todo` -a un botón "Todo el mundo" nombrar el parámetro
## al revés de lo que dice fue justo el bug que cazó la captura de pruebas:
## el nombre invertido hacía fácil pasar el booleano equivocado sin que nada
## avisara.
func _exportar_csv(ed: Editor, solo_mi_liga: bool) -> void:
	var texto := ed.exportar_csv(solo_mi_liga)
	if texto == "":
		p._escribir("[color=#c9a227]No hay nada que exportar.[/color]")
		return
	DisplayServer.clipboard_set(texto)
	p._escribir("[color=#4caf6d]Base exportada.[/color] Copiada al portapapeles (%d líneas)." % (texto.count("\n") + 1))

func _importar_csv(ed: Editor) -> void:
	if p._ed_csv.strip_edges() == "":
		p._escribir("[color=#c9a227]No hay nada que importar.[/color]")
		return
	var r := ed.importar_csv(p._ed_csv, p._ed_censura)
	if r.has("error"):
		p._escribir("[color=#e05555]No se pudo importar: %s.[/color]" % String(r["error"]))
		p._refrescar()
		return
	p._escribir("[color=#4caf6d]Importadas %d fichas en %d club(es).[/color]" % [
		int(r["filas"]), int(r["clubes"])])
	for p_local: String in (r["problemas"] as Array):
		p._escribir("[color=#e0a832]  %s[/color]" % p_local)
	p._refrescar()
