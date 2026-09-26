class_name DisenadorKit
extends Control
## EL DISEÑADOR DE EQUIPACIÓN (26-9-2026), a pantalla completa. Pedido: *"más
## variantes de diseño de camiseta, colores de números, hasta 5 colores, polera,
## shorts, accesorios, unos 30 botines y cambiar de colores"*.
##
## A la izquierda, la vista previa: la equipación en 2D de frente y de espaldas
## (con el número) y un jugador 3D girando con la misma equipación del partido.
## A la derecha, pestañas: Camiseta (70 diseños y 5 colores), Pantalón, Medias,
## Botines (30 modelos y 3 colores), Accesorios y Números.
## Guardar deja la equipación en `Club.kit_x`; la ve todo el juego.

signal cerrado

var _mundo: Mundo
var _club: Club
var _kit: Dictionary = {}
var _frente: TextureRect
var _espalda: TextureRect
var _dorsal_2d: Label
var _vp: SubViewport
var _jugador: Dictionary = {}
var _pivote: Node3D
var _galeria: GridContainer
var _botones_diseno: Array = []
var _pendientes: Array = []      ## miniaturas por generar (pocas por frame)
var _pestanas: TabContainer
var _colores: Array = []         ## los 5 ColorPickerButton de la camiseta
var _refresco_3d := 0.0

static func abrir(padre: Control, mundo: Mundo) -> DisenadorKit:
	var n := DisenadorKit.new()
	n._mundo = mundo
	n._club = mundo.mi_club()
	n._kit = DisenosKit.kit_de_club(n._club).duplicate(true)
	n.set_anchors_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	padre.add_child(n)
	n._montar()
	return n

func _montar() -> void:
	var fondo := ColorRect.new()
	fondo.color = Tema.FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var marco := MarginContainer.new()
	marco.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		marco.add_theme_constant_override("margin_" + lado, 24)
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
	for par: Array in [["🎲 Aleatorio", _aleatorio], ["↺ Colores del club", _restablecer], ["Cancelar", _cerrar], ["💾 Guardar", _guardar]]:
		var b := Button.new()
		b.text = String(par[0])
		b.custom_minimum_size = Vector2(130, 40)
		b.pressed.connect(par[1])
		cab.add_child(b)
	var cuerpo := HBoxContainer.new()
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_theme_constant_override("separation", 16)
	vb.add_child(cuerpo)
	cuerpo.add_child(_vista_previa())
	_pestanas = TabContainer.new()
	_pestanas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cuerpo.add_child(_pestanas)
	_pestanas.add_child(_tab_camiseta())
	_pestanas.add_child(_tab_prenda("Pantalón", "pant", DisenosKit.PANTALONES))
	_pestanas.add_child(_tab_prenda("Medias", "med", DisenosKit.MEDIAS))
	_pestanas.add_child(_tab_botines())
	_pestanas.add_child(_tab_accesorios())
	_pestanas.add_child(_tab_numeros())
	_actualizar()
	Animar.aparecer(marco)

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
	## El jugador 3D, girando.
	var cont3 := SubViewportContainer.new()
	cont3.stretch = true
	cont3.custom_minimum_size = Vector2(160, 300)
	cont3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(cont3)
	_vp = SubViewport.new()
	_vp.size = Vector2i(200, 320)
	_vp.transparent_bg = true
	_vp.msaa_3d = Viewport.MSAA_2X
	cont3.add_child(_vp)
	var mundo3 := Node3D.new()
	_vp.add_child(mundo3)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.0, 3.1)
	cam.fov = 40
	mundo3.add_child(cam)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-35, 25, 0)
	luz.light_energy = 1.2
	mundo3.add_child(luz)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.62, 0.66)
	e.ambient_light_energy = 0.9
	env.environment = e
	mundo3.add_child(env)
	_pivote = Node3D.new()
	mundo3.add_child(_pivote)
	_jugador = FutbolistaQ.crear(1.80, "male")
	if not _jugador.is_empty():
		_pivote.add_child(_jugador["nodo"])
		FutbolistaQ.terminar(_jugador, true)
		var ap: AnimationPlayer = _jugador["anim"]
		if ap.has_animation("parado"):
			ap.play("parado")
	var nota := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "Lo que ves aquí es lo que se ve en el partido: el 3D y el 2D usan la misma fórmula.")
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(nota)
	return vb

func _process(delta: float) -> void:
	if _pivote != null:
		_pivote.rotation.y += delta * 0.8
	## Miniaturas de la galería, unas pocas por frame: todas de golpe congelaban
	## la pantalla un segundo.
	for i in 4:
		if _pendientes.is_empty():
			break
		var p: Array = _pendientes.pop_front()
		var b: TextureButton = p[0]
		if is_instance_valid(b):
			b.texture_normal = DisenosKit.textura_camiseta(String(p[1]), DisenosKit.colores(_kit), int(_kit.get("trim", 1)), 64)
	if _refresco_3d > 0.0:
		_refresco_3d -= delta
		if _refresco_3d <= 0.0:
			_vestir_3d()

func _vestir_3d() -> void:
	if _jugador.is_empty():
		return
	var cols := DisenosKit.colores(_kit)
	VestidorQ.vestir_equipacion(_jugador, cols[0], cols[1], "liso", Color("c68d68"), Color(0.15, 0.1, 0.07),
		Color(0, 0, 0, 0), Color(0, 0, 0, 0), false, _kit, 10)

## Repinta la vista previa (el 3D, un instante después: si se arrastra un
## color no se rehace el material en cada paso).
func _actualizar() -> void:
	_frente.texture = DisenosKit.textura_completa(_kit, false, 170)
	_espalda.texture = DisenosKit.textura_completa(_kit, true, 170)
	_dorsal_2d.text = "10"
	_dorsal_2d.add_theme_color_override("font_color", DisenosKit._col(_kit.get("num", "ffffff")))
	_dorsal_2d.add_theme_color_override("font_outline_color", DisenosKit.colores(_kit)[0].darkened(0.4))
	_refresco_3d = 0.25

## -------------------------------------------------------------- CAMISETA

func _selector_color(hexa: String, al_cambiar: Callable) -> ColorPickerButton:
	var cp := ColorPickerButton.new()
	cp.color = DisenosKit._col(hexa)
	cp.custom_minimum_size = Vector2(56, 34)
	cp.edit_alpha = false
	cp.color_changed.connect(func(c: Color) -> void: al_cambiar.call(c.to_html(false)))
	return cp

func _tab_camiseta() -> Control:
	var sc := ScrollContainer.new()
	sc.name = "Camiseta"
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 8)
	sc.add_child(vb)
	vb.add_child(Tema.rotulo("COLORES (el diseño usa los primeros que necesite)"))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	vb.add_child(fila)
	_colores.clear()
	for i in 5:
		var cvb := VBoxContainer.new()
		fila.add_child(cvb)
		cvb.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "Color %d" % (i + 1)))
		var idx := i
		var cp := _selector_color(String((_kit["cols"] as Array)[i]), func(h: String) -> void:
			(_kit["cols"] as Array)[idx] = h
			_color_cambiado())
		cvb.add_child(cp)
		_colores.append(cp)
	var fila2 := HBoxContainer.new()
	fila2.add_theme_constant_override("separation", 8)
	vb.add_child(fila2)
	fila2.add_child(Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE, "Cuello y puños:"))
	var ob := OptionButton.new()
	for i in 5:
		ob.add_item("Color %d" % (i + 1), i)
	ob.selected = int(_kit.get("trim", 1))
	ob.item_selected.connect(func(i: int) -> void:
		_kit["trim"] = i
		_color_cambiado())
	fila2.add_child(ob)
	vb.add_child(Tema.rotulo("DISEÑOS (%d)" % DisenosKit.DISENOS.size()))
	_galeria = GridContainer.new()
	_galeria.columns = 8
	_galeria.add_theme_constant_override("h_separation", 6)
	_galeria.add_theme_constant_override("v_separation", 6)
	vb.add_child(_galeria)
	for d: Array in DisenosKit.DISENOS:
		var cont := VBoxContainer.new()
		_galeria.add_child(cont)
		var b := TextureButton.new()
		b.custom_minimum_size = Vector2(72, 58)
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		b.tooltip_text = "%s · usa %d color%s" % [String(d[1]), int(d[7]), "" if int(d[7]) == 1 else "es"]
		var clave := String(d[0])
		b.pressed.connect(func() -> void:
			_kit["dis"] = clave
			_marcar_diseno()
			_actualizar())
		cont.add_child(b)
		var l := Tema.etiqueta(10, Tema.SUAVE, String(d[1]))
		l.custom_minimum_size = Vector2(72, 0)
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cont.add_child(l)
		_botones_diseno.append([b, clave, l])
		_pendientes.append([b, clave])
	_marcar_diseno()
	return sc

func _marcar_diseno() -> void:
	var usa := int(DisenosKit.diseno(String(_kit["dis"]))[7])
	for par: Array in _botones_diseno:
		var sel := String(par[1]) == String(_kit["dis"])
		(par[0] as TextureButton).modulate = Color.WHITE if sel else Color(1, 1, 1, 0.75)
		(par[2] as Label).add_theme_color_override("font_color", Tema.ORO if sel else Tema.SUAVE)
	for i in _colores.size():
		(_colores[i] as Control).modulate = Color.WHITE if i < maxi(usa, 2) else Color(1, 1, 1, 0.4)

## Con otro color hay que rehacer las 70 miniaturas: se encolan de nuevo.
func _color_cambiado() -> void:
	_pendientes.clear()
	for par: Array in _botones_diseno:
		_pendientes.append([par[0], par[1]])
	_actualizar()

## ------------------------------------------------------ PANTALÓN Y MEDIAS

func _tab_prenda(titulo: String, clave: String, tabla: Array) -> Control:
	var vb := VBoxContainer.new()
	vb.name = titulo
	vb.add_theme_constant_override("separation", 10)
	var prenda: Dictionary = _kit[clave]
	vb.add_child(Tema.rotulo("DISEÑO"))
	var flujo := HFlowContainer.new()
	flujo.add_theme_constant_override("h_separation", 6)
	flujo.add_theme_constant_override("v_separation", 6)
	vb.add_child(flujo)
	var grupo := ButtonGroup.new()
	for f: Array in tabla:
		var b := Button.new()
		b.text = String(f[1])
		b.toggle_mode = true
		b.button_group = grupo
		b.custom_minimum_size = Vector2(150, 40)
		b.button_pressed = String(prenda.get("dis", "")) == String(f[0])
		var k := String(f[0])
		b.pressed.connect(func() -> void:
			(_kit[clave] as Dictionary)["dis"] = k
			_actualizar())
		flujo.add_child(b)
	vb.add_child(Tema.rotulo("COLORES"))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	vb.add_child(fila)
	for c: String in ["c1", "c2"]:
		fila.add_child(Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE, "Principal" if c == "c1" else "Detalle"))
		var cc := c
		fila.add_child(_selector_color(String(prenda.get(c, "ffffff")), func(h: String) -> void:
			(_kit[clave] as Dictionary)[cc] = h
			_actualizar()))
	return vb

## ---------------------------------------------------------------- BOTINES

func _tab_botines() -> Control:
	var sc := ScrollContainer.new()
	sc.name = "Botines"
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 8)
	sc.add_child(vb)
	var bot: Dictionary = _kit["bot"]
	vb.add_child(Tema.rotulo("COLORES (base, detalle y suela)"))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	vb.add_child(fila)
	var pickers: Array = []
	for c: String in ["c1", "c2", "c3"]:
		var cc := c
		var modelo: Array = DisenosKit.BOTINES[DisenosKit.indice_de(DisenosKit.BOTINES, String(bot.get("mod", "clasico")))]
		var def := String(modelo[3 + ["c1", "c2", "c3"].find(c)])
		var cp := _selector_color(String(bot.get(c, def)), func(h: String) -> void:
			(_kit["bot"] as Dictionary)[cc] = h
			_actualizar())
		fila.add_child(cp)
		pickers.append(cp)
	vb.add_child(Tema.rotulo("MODELOS (%d) · al elegir uno se ponen sus colores" % DisenosKit.BOTINES.size()))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	vb.add_child(grid)
	for m: Array in DisenosKit.BOTINES:
		var cont := VBoxContainer.new()
		grid.add_child(cont)
		var b := TextureButton.new()
		b.custom_minimum_size = Vector2(110, 55)
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		b.texture_normal = DisenosKit.textura_botin(String(m[0]), Color("#" + String(m[3])), Color("#" + String(m[4])), Color("#" + String(m[5])), 96)
		var mm := m
		b.pressed.connect(func() -> void:
			_kit["bot"] = {"mod": String(mm[0]), "c1": String(mm[3]), "c2": String(mm[4]), "c3": String(mm[5])}
			for i in 3:
				(pickers[i] as ColorPickerButton).color = Color("#" + String(mm[3 + i]))
			_actualizar())
		cont.add_child(b)
		var l := Tema.etiqueta(11, Tema.SUAVE, String(m[1]))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cont.add_child(l)
	return sc

## ------------------------------------------------------------- ACCESORIOS

func _tab_accesorios() -> Control:
	var vb := VBoxContainer.new()
	vb.name = "Accesorios"
	vb.add_theme_constant_override("separation", 8)
	vb.add_child(Tema.rotulo("LO QUE LLEVAN PUESTO TODOS (el capitán, además, su brazalete)"))
	for a: Array in DisenosKit.ACCESORIOS:
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 10)
		vb.add_child(fila)
		var k := String(a[0])
		var acc: Dictionary = _kit["acc"]
		var chk := CheckBox.new()
		chk.text = String(a[1])
		chk.custom_minimum_size = Vector2(300, 0)
		chk.button_pressed = acc.has(k)
		fila.add_child(chk)
		var cp := _selector_color(String(acc.get(k, a[2])), func(h: String) -> void:
			if (_kit["acc"] as Dictionary).has(k):
				(_kit["acc"] as Dictionary)[k] = h
				_actualizar())
		fila.add_child(cp)
		chk.toggled.connect(func(si: bool) -> void:
			if si:
				(_kit["acc"] as Dictionary)[k] = cp.color.to_html(false)
			else:
				(_kit["acc"] as Dictionary).erase(k)
			_actualizar())
	return vb

## ---------------------------------------------------------------- NÚMEROS

func _tab_numeros() -> Control:
	var vb := VBoxContainer.new()
	vb.name = "Números"
	vb.add_theme_constant_override("separation", 10)
	vb.add_child(Tema.rotulo("COLOR DE LOS NÚMEROS (espalda)"))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	vb.add_child(fila)
	fila.add_child(_selector_color(String(_kit.get("num", "ffffff")), func(h: String) -> void:
		_kit["num"] = h
		_actualizar()))
	var rapidos := HFlowContainer.new()
	rapidos.add_theme_constant_override("h_separation", 6)
	vb.add_child(rapidos)
	for i in 5:
		var b := Button.new()
		b.text = "Igual al color %d" % (i + 1)
		var idx := i
		b.pressed.connect(func() -> void:
			_kit["num"] = String((_kit["cols"] as Array)[idx])
			_actualizar())
		rapidos.add_child(b)
	return vb

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
	(func() -> void: _pestanas.current_tab = actual).call_deferred()
	_actualizar()

func _guardar() -> void:
	_club.kit_x = _kit.duplicate(true)
	## Lo de siempre, coherente con lo nuevo (fichas, escudos, prensa).
	var cols: Array = _kit["cols"]
	_club.kit_color1 = "#" + String(cols[0]).trim_prefix("#")
	_club.kit_color2 = "#" + String(cols[1]).trim_prefix("#")
	_club.kit_estilo = String(_kit["dis"])
	Aviso.mostrar(get_parent(), "logro", "🎽", "Equipación guardada", DisenosKit.diseno(String(_kit["dis"]))[1])
	_cerrar()

func _cerrar() -> void:
	cerrado.emit()
	queue_free()
