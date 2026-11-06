class_name DisenadorKit
extends "res://ui/componentes/disenador_kit_p1.gd"
## [Capa 2/2 de `disenador_kit.gd`] _tab_sponsors, _rehacer, _aleatorio, _restablecer, _cerrar, _guardar … (+5)

## ------------------------------------------------------- PATROCINADORES

## Los sponsors que lleva la camiseta: salen de los contratos (Finanzas ›
## Patrocinio y Zonas); aquí se ven y se decide si se estampan o no.
func _tab_sponsors() -> Control:
	var sc := ScrollContainer.new()
	sc.name = "Patrocinadores"
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 10)
	sc.add_child(vb)
	vb.add_child(Tema.rotulo("PATROCINADORES EN LA EQUIPACIÓN"))
	var ayuda := Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE,
		"Salen de los contratos que firmas en Finanzas (el principal va al pecho; manga, espalda y pantalón son las zonas). Un contrato nuevo cambia la camiseta sola.")
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(ayuda)
	var todos := SponsorKit.de_club(_club, _mundo)
	var ocultos: Array = _kit.get("sp_ocultar", [])
	var fondo := Color(String((_kit["cols"] as Array)[0]))
	for z: Array in [["pecho", "Pecho (principal)"], ["manga", "Manga"], ["espalda", "Espalda"], ["short", "Pantalón"]]:
		var zona := String(z[0])
		var pc := PanelContainer.new()
		pc.add_theme_stylebox_override("panel", Tema.caja(Tema.TARJETA, Tema.RADIO, Color(1, 1, 1, 0.08)))
		vb.add_child(pc)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 12)
		pc.add_child(fila)
		var nom := Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, String(z[1]))
		nom.custom_minimum_size = Vector2(170, 0)
		fila.add_child(nom)
		if not todos.has(zona):
			var sin := Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE, "Sin contrato: la zona va limpia.")
			sin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila.add_child(sin)
			continue
		var info: Dictionary = todos[zona]
		var hx := String(info.get("color", "#ffffff"))
		var muestra := PanelContainer.new()
		var sbm := StyleBoxFlat.new()
		sbm.bg_color = fondo
		sbm.set_corner_radius_all(6)
		sbm.content_margin_left = 8
		sbm.content_margin_right = 8
		muestra.add_theme_stylebox_override("panel", sbm)
		var tr := TextureRect.new()
		tr.texture = ImageTexture.create_from_image(SponsorKit.imagen(String(info.get("marca", "")), hx, SponsorKit.color_letras(hx, fondo), zona == "manga" or zona == "short"))
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(220, 56)
		muestra.add_child(tr)
		fila.add_child(muestra)
		var marca := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, String(info.get("marca", "")))
		marca.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(marca)
		var cb := CheckBox.new()
		cb.text = Idiomas.t("Estampar")
		cb.button_pressed = not ocultos.has(zona)
		cb.toggled.connect(func(on: bool) -> void:
			var lista: Array = _kit.get("sp_ocultar", []).duplicate()
			if on:
				lista.erase(zona)
			elif not lista.has(zona):
				lista.append(zona)
			_kit["sp_ocultar"] = lista
			_aplicar_sponsors()
			_actualizar())
		fila.add_child(cb)
	return sc

## Rehace las pestañas con el kit nuevo (colores de los selectores, etc.).
func _rehacer() -> void:
	var actual := _pestanas.current_tab
	## Se sacan antes de liberarlas: si no, las nuevas no pueden llevar el
	## mismo nombre y la pestaña enseña "@ScrollContainer@6463".
	for h in _pestanas.get_children():
		_pestanas.remove_child(h)
		h.queue_free()
	_botones_diseno.clear()
	_pendientes.clear()
	_pestanas.add_child(_tab_camiseta())
	_pestanas.add_child(_tab_prenda("Pantalón", "pant", DisenosKit.PANTALONES))
	_pestanas.add_child(_tab_prenda("Medias", "med", DisenosKit.MEDIAS))
	_pestanas.add_child(_tab_botines())
	_pestanas.add_child(_tab_accesorios())
	_pestanas.add_child(_tab_numeros())
	_pestanas.add_child(_tab_sponsors())
	(func() -> void: _pestanas.current_tab = actual).call_deferred()
	_actualizar()

## ---------------------------------------------------------------- ACCIONES

func _aleatorio() -> void:
	var r := RandomNumberGenerator.new()
	r.randomize()
	var paleta: Array = []
	for i in 5:
		paleta.append(Color.from_hsv(r.randf(), r.randf_range(0.35, 0.95), r.randf_range(0.2, 1.0)).to_html(false))
	_kit["cols"] = paleta
	_kit["dis"] = String(DisenosKit.DISENOS[r.randi() % DisenosKit.DISENOS.size()][0])
	var m: Array = DisenosKit.BOTINES[r.randi() % DisenosKit.BOTINES.size()]
	_kit["bot"] = {"mod": String(m[0]), "c1": String(m[3]), "c2": String(m[4]), "c3": String(m[5])}
	(_kit["pant"] as Dictionary)["c1"] = paleta[r.randi() % 2]
	(_kit["med"] as Dictionary)["c1"] = paleta[r.randi() % 2]
	_rehacer()

func _restablecer() -> void:
	var guardado := _club.kit_x
	_club.kit_x = {}
	_kit = DisenosKit.kit_de_club(_club).duplicate(true)
	_club.kit_x = guardado
	_rehacer()

func _cerrar() -> void:
	if is_instance_valid(_menu):
		_menu.visible = true
	cerrado.emit()
	if _capa != null:
		_capa.queue_free()
	else:
		queue_free()

func _guardar() -> void:
	_club.kit_x = _kit.duplicate(true)
	## Los patrocinadores salen de los contratos cada vez: no se guardan.
	_club.kit_x.erase("sp")
	## Lo de siempre, coherente con lo nuevo (fichas, escudos, prensa).
	var cols: Array = _kit["cols"]
	_club.kit_color1 = "#" + String(cols[0]).trim_prefix("#")
	_club.kit_color2 = "#" + String(cols[1]).trim_prefix("#")
	_club.kit_estilo = String(_kit["dis"])
	Aviso.mostrar(_menu if is_instance_valid(_menu) else get_parent() as Control, "logro", "🎽", "Equipación guardada", DisenosKit.diseno(String(_kit["dis"]))[1])
	_cerrar()

## ------------------------------------------------------------ VISTA PREVIA

func _vista_previa() -> Control:
	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(520, 0)
	vb.add_theme_constant_override("separation", 8)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	vb.add_child(fila)
	for i in 2:
		var cont := VBoxContainer.new()
		fila.add_child(cont)
		cont.add_child(Tema.rotulo("DE FRENTE" if i == 0 else "DE ESPALDA"))
		var tr := TextureRect.new()
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(170, 300)
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		cont.add_child(tr)
		if i == 0:
			_frente = tr
		else:
			_espalda = tr
			_dorsal_2d = Label.new()
			_dorsal_2d.add_theme_font_size_override("font_size", 40)
			_dorsal_2d.add_theme_constant_override("outline_size", 6)
			_dorsal_2d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_dorsal_2d.position = Vector2(55, 48)
			_dorsal_2d.size = Vector2(60, 50)
			tr.add_child(_dorsal_2d)
	var nota := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "Lo que ves aquí es lo que se ve en el partido: la camiseta se pinta con la misma fórmula.")
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(nota)
	return vb

func _montar() -> void:
	if not _incrustado:
		var fondo := ColorRect.new()
		fondo.color = Tema.FONDO
		fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(fondo)
	var marco := MarginContainer.new()
	marco.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		marco.add_theme_constant_override("margin_" + lado, 0 if _incrustado else 24)
	add_child(marco)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	marco.add_child(vb)
	## Cabecera.
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 8)
	vb.add_child(cab)
	var t := Tema.etiqueta(Tema.TAM_TITULO + 4, Tema.ORO, "🎽 DISEÑADOR DE EQUIPACIÓN")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(t)
	var botones_cab: Array = [["🎲 Aleatorio", _aleatorio], ["↺ Colores del club", _restablecer]]
	if not _incrustado:
		botones_cab += [["Cancelar", _cerrar], ["💾 Guardar", _guardar]]
	for par: Array in botones_cab:
		var b := Button.new()
		b.text = String(par[0])
		b.custom_minimum_size = Vector2(130, 40)
		b.pressed.connect(par[1])
		cab.add_child(b)
	## Incrustado cabe poco a lo ancho: la vista previa arriba y las pestañas debajo.
	var cuerpo: BoxContainer = VBoxContainer.new() if _incrustado else HBoxContainer.new()
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_theme_constant_override("separation", 16)
	vb.add_child(cuerpo)
	cuerpo.add_child(_vista_previa())
	_pestanas = TabContainer.new()
	_pestanas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pestanas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if _incrustado:
		_pestanas.custom_minimum_size = Vector2(0, 470)
	cuerpo.add_child(_pestanas)
	_pestanas.add_child(_tab_camiseta())
	_pestanas.add_child(_tab_prenda("Pantalón", "pant", DisenosKit.PANTALONES))
	_pestanas.add_child(_tab_prenda("Medias", "med", DisenosKit.MEDIAS))
	_pestanas.add_child(_tab_botines())
	_pestanas.add_child(_tab_accesorios())
	_pestanas.add_child(_tab_numeros())
	_pestanas.add_child(_tab_sponsors())
	_actualizar(true)
	Animar.aparecer(marco)

func _process(delta: float) -> void:
	## Miniaturas de la galería, unas pocas por frame: todas de golpe congelaban
	## la pantalla un segundo.
	## Con un PRESUPUESTO de 6 ms por fotograma (al menos una): en un móvil lento no se congela la pantalla, y en el PC salen igual de rápido.
	var t0 := Time.get_ticks_usec()
	while not _pendientes.is_empty():
		var p: Array = _pendientes.pop_front()
		var b: TextureButton = p[0]
		if is_instance_valid(b):
			b.texture_normal = DisenosKit.textura_camiseta(String(p[1]), DisenosKit.colores(_kit), int(_kit.get("trim", 1)), 64)
		if Time.get_ticks_usec() - t0 > 6000:
			break
	if _mejora_2d > 0.0:
		_mejora_2d -= delta
		if _mejora_2d <= 0.0 and _refresco_2d <= 0.0:
			_ss_2d = 2
			_pintar_2d()
	if _refresco_2d > 0.0:
		_refresco_2d -= delta
		if _refresco_2d <= 0.0:
			_pintar_2d()

## Esc cierra sin guardar, como "Cancelar".
func _unhandled_input(ev: InputEvent) -> void:
	if _incrustado:
		return
	if ev is InputEventKey and (ev as InputEventKey).pressed and (ev as InputEventKey).keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_cerrar()
