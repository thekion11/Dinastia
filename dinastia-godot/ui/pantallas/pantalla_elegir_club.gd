class_name PantallaElegirClub
extends RefCounted
## ELEGIR CLUB (fase 6, paso 4 del plan §7.1; sale de `Principal`, capa 12, el 27-10-2026): el selector
## de club de la barra, el diálogo con el mapa de países y escudos, y tomar el mando de un club.
## `p` es la pantalla principal: el selector, el diálogo abierto, el país elegido y el mundo siguen
## en ella; `Principal` conserva puentes de una línea con los nombres de siempre.

var p: Principal
## Estado propio de esta pantalla (fase 6, paso 7: antes eran variables de `Principal`).
## ELEGIR CLUB: MAPA DEL PAÍS Y ESCUDOS, no un desplegable de 383 líneas.
##
## «La forma de elegir el club debe estar mejor visualmente; cuando se selecciona
## un país debe aparecer un mapa y enmarcar el país que seleccionaste, y ahí se
## despliegan los clubes». Del documento de instrucciones.
##
## Hasta ahora era un `OptionButton` con los trescientos ochenta y tres clubes
## del mundo en una lista plana: para encontrar el tuyo había que bajar por un
## menú interminable, y todos se veían exactamente igual.
##
## AHORA SON DOS PASOS. Primero el país -con su silueta dibujada y el número de
## clubes-, y dentro los clubes de ese país con su escudo, su reputación, su
## división y su aforo, que es lo que de verdad se compara al elegir dónde
## empezar. El desplegable de arriba sigue existiendo para cambiar rápido.
var _dlg_club: Window = null
var _pais_elegido: String = ""

func _init(principal: Principal) -> void:
	p = principal

func _al_elegir_club(indice: int) -> void:
	p.mundo.tomar_el_mando(String(p._selector.get_item_metadata(indice)))
	## tomar_el_mando() crea una Seleccion nueva -la del pais de este club-, asi
	## que hay que volver a engancharle el aviso de noticias.
	p._conectar_noticias()
	p._seleccionado = null
	p._refrescar()

func _llenar_selector() -> void:
	p._selector.clear()
	var i := 0
	for l in p.mundo.ligas:
		for c in l.clubes:
			## Corto («Lautaro FC · CHI 1.ª», s3): en los 208 px del selector, «Lautaro
			## FC · Primera División» salía cortado en todas las pantallas. La liga
			## entera va en la ayuda.
			p._selector.add_item("%s · %s %d.ª" % [c.nombre, l.pais, l.division()])
			p._selector.set_item_metadata(i, c.id)
			p._selector.set_item_tooltip(i, "%s  ·  %s" % [c.nombre, l.nombre])
			if c.id == p.mundo.mi_club_id:
				p._selector.select(i)
				p._selector.tooltip_text = "%s  ·  %s" % [c.nombre, l.nombre]
			i += 1

func _tomar_club(id: String) -> void:
	p.mundo.tomar_el_mando(id)
	p._conectar_noticias()
	p._seleccionado = null
	_llenar_selector()
	if _dlg_club != null and is_instance_valid(_dlg_club):
		_dlg_club.queue_free()
		_dlg_club = null
	p._escribir("[color=#3fa06a][b]Tomas el mando de %s.[/b][/color] %s" % [
		p.mundo.mi_club().nombre, p.mundo.directiva.objetivo if p.mundo.directiva != null else ""])
	p._refrescar()

func _pintar_elegir_club(col: VBoxContainer) -> void:
	for h in col.get_children():
		h.queue_free()

	var t := p._texto(14, p.COL_ACENTO)
	t.text = Idiomas.t("¿DÓNDE QUIERES EMPEZAR?")
	col.add_child(t)

	## Los países que tienen liga, con cuántos clubes hay en cada uno.
	var por_pais := {}
	for l: Liga in p.mundo.ligas:
		por_pais[l.pais] = int(por_pais.get(l.pais, 0)) + l.clubes.size()
	var nombres: Dictionary = Datos.tabla("PAIS_SELECCION")

	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	col.add_child(flow)
	for cod: String in por_pais:
		var pais := cod
		var b := Button.new()
		b.text = "%s  (%d)" % [String(nombres.get(pais, pais)) if nombres != null else pais, int(por_pais[pais])]
		b.add_theme_font_size_override("font_size", 11)
		b.toggle_mode = true
		b.button_pressed = _pais_elegido == pais
		b.clip_text = true
		b.custom_minimum_size = Vector2(120, 26)
		b.pressed.connect(func() -> void:
			_pais_elegido = pais
			_pintar_elegir_club(col))
		flow.add_child(b)

	if _pais_elegido == "":
		return

	## EL MAPA. Se pinta con el color del club que ya diriges, para que el país
	## no sea un dibujo suelto sino EL sitio donde está tu club.
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	fila.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(fila)

	var marco := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = p._pal_panel()
	estilo.border_color = p.COL_ACENTO
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(8)
	estilo.content_margin_left = 10
	estilo.content_margin_right = 10
	estilo.content_margin_top = 10
	estilo.content_margin_bottom = 10
	marco.add_theme_stylebox_override("panel", estilo)
	marco.custom_minimum_size = Vector2(240, 0)
	fila.add_child(marco)
	var colm := VBoxContainer.new()
	colm.add_theme_constant_override("separation", 6)
	marco.add_child(colm)
	var tn := p._texto(13, p.COL_TEXTO)
	tn.text = String(nombres.get(_pais_elegido, _pais_elegido)) if nombres != null else _pais_elegido
	tn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	colm.add_child(tn)
	var lienzo := Control.new()
	lienzo.custom_minimum_size = Vector2(200, 240)
	colm.add_child(lienzo)
	var pol := MapaPais.poligono(_pais_elegido, Vector2(200, 240))
	if pol.size() >= 3:
		var forma := Polygon2D.new()
		forma.polygon = pol
		forma.color = p.COL_ACENTO
		lienzo.add_child(forma)
		## El contorno por encima, más claro: una silueta plana se lee como una
		## mancha, y con borde se reconoce el país.
		var borde := Line2D.new()
		borde.points = pol
		borde.closed = true
		borde.width = 2.0
		borde.default_color = p.COL_TEXTO
		lienzo.add_child(borde)
	else:
		var sin := p._texto(10, p.COL_SUAVE)
		sin.text = Idiomas.t("(sin silueta para este país)")
		colm.add_child(sin)

	## LOS CLUBES DEL PAÍS, con lo que de verdad se compara al elegir: escudo,
	## reputación, división y aforo.
	var lista := ScrollContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fila.add_child(lista)
	var colc := VBoxContainer.new()
	colc.add_theme_constant_override("separation", 3)
	colc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_child(colc)

	var clubes: Array[Club] = []
	for l2: Liga in p.mundo.ligas:
		if l2.pais == _pais_elegido:
			for c2: Club in l2.clubes:
				clubes.append(c2)
	clubes.sort_custom(func(a: Club, b: Club) -> bool: return a.rep > b.rep)
	for c3: Club in clubes:
		var club := c3
		var f := HBoxContainer.new()
		f.add_theme_constant_override("separation", 8)
		colc.add_child(f)
		var esc := TextureRect.new()
		esc.texture = Escudo.textura(club, 26)
		esc.custom_minimum_size = Vector2(26, 26)
		esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		f.add_child(esc)
		var b2 := Button.new()
		var mio := club.id == p.mundo.mi_club_id
		b2.text = "%s%s" % ["★ " if mio else "", club.nombre]
		b2.flat = true
		b2.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b2.add_theme_font_size_override("font_size", 13)
		b2.add_theme_color_override("font_color", p._color_de_paleta(p.COL_ORO if mio else p.COL_TEXTO))
		b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b2.clip_text = true
		b2.pressed.connect(func() -> void:
			_tomar_club(club.id))
		f.add_child(b2)
		var d := p._texto(11, p.COL_SUAVE)
		d.text = Idiomas.t("D%d  ·  rep %d  ·  %s butacas") % [club.division, club.rep, p._miles(club.estadio_aforo)]
		d.custom_minimum_size = Vector2(190, 0)
		f.add_child(d)

func _abrir_elegir_club() -> void:
	if _dlg_club != null and is_instance_valid(_dlg_club):
		## Fuera del árbol YA, no al final del cuadro: si no, durante ese cuadro
		## hay dos ventanas exclusivas y Godot se queja (visto en el recorrido).
		_dlg_club.exclusive = false
		_dlg_club.hide()
		if _dlg_club.get_parent() != null:
			_dlg_club.get_parent().remove_child(_dlg_club)
		_dlg_club.queue_free()
	_dlg_club = Window.new()
	_dlg_club.title = Idiomas.t("Elegir club")
	_dlg_club.size = Vector2i(880, 620)
	_dlg_club.transient = true
	_dlg_club.exclusive = true
	_dlg_club.close_requested.connect(func() -> void:
		_dlg_club.queue_free()
		_dlg_club = null)
	p.add_child(_dlg_club)
	var fondo := ColorRect.new()
	fondo.color = p._pal_fondo()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dlg_club.add_child(fondo)
	var caja := MarginContainer.new()
	caja.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.add_theme_constant_override("margin_left", 14)
	caja.add_theme_constant_override("margin_right", 14)
	caja.add_theme_constant_override("margin_top", 12)
	caja.add_theme_constant_override("margin_bottom", 12)
	_dlg_club.add_child(caja)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	caja.add_child(col)
	_pais_elegido = p.mundo.mi_club().pais if p.mundo.mi_club() != null else ""
	_pintar_elegir_club(col)
	_dlg_club.popup_centered()
