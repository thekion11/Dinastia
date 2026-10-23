extends Control
## (Parte 1 de 2 de `disenador_kit.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `disenador_kit.gd`, conserva la clase.)

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

## PANTALLA PROPIA (26-9-2026, pedido: "debe tener su propio menú, que tenga
## la totalidad de la pantalla, no encima del menú central"). No se cuelga del
## menú: va en su propia capa sobre la raíz y el menú se OCULTA mientras está
## abierto (no se ve detrás ni recibe clics). Al cerrar, el menú vuelve tal
## cual estaba.
var _capa: CanvasLayer = null
var _menu: Control = null

## [nombre, prueba(diseño) -> bool]
const FILTROS := [
	["Todos los diseños", ""], ["Un color", "c1"], ["Dos colores", "c2"], ["Tres colores", "c3"],
	["Cuatro o cinco colores", "c45"], ["Clásicos", "clasico"], ["Modernos", "moderno"],
	["Geométricos", "geo"], ["Rayas y franjas", "rayas"],
]
var _filtro := 0
var _busqueda := ""

static func abrir(padre: Control, mundo: Mundo) -> DisenadorKit:
	var n := DisenadorKit.new()
	n._mundo = mundo
	n._club = mundo.mi_club()
	n._kit = DisenosKit.kit_de_club(n._club).duplicate(true)
	n.set_anchors_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	if padre.is_inside_tree():
		n._capa = CanvasLayer.new()
		n._capa.layer = 60
		n._capa.name = "PantallaEquipacion"
		padre.get_tree().root.add_child(n._capa)
		n._capa.add_child(n)
		n._menu = padre
		padre.visible = false
	else:
		padre.add_child(n)
	n._montar()
	return n

## -------------------------------------------------------------- CAMISETA

func _selector_color(hexa: String, al_cambiar: Callable) -> ColorPickerButton:
	var cp := ColorPickerButton.new()
	cp.color = DisenosKit._col(hexa)
	cp.custom_minimum_size = Vector2(56, 34)
	cp.edit_alpha = false
	cp.color_changed.connect(func(c: Color) -> void: al_cambiar.call(c.to_html(false)))
	return cp

## Repinta la vista previa (el 3D, un instante después: si se arrastra un
## color no se rehace el material en cada paso).
func _actualizar() -> void:
	_frente.texture = DisenosKit.textura_completa(_kit, false, 170)
	_espalda.texture = DisenosKit.textura_completa(_kit, true, 170)
	_dorsal_2d.text = "10"
	_dorsal_2d.add_theme_color_override("font_color", DisenosKit._col(_kit.get("num", "ffffff")))
	_dorsal_2d.add_theme_color_override("font_outline_color", DisenosKit.colores(_kit)[0].darkened(0.4))
	_refresco_3d = 0.25

## Con otro color hay que rehacer las 70 miniaturas: se encolan de nuevo.
func _color_cambiado() -> void:
	_pendientes.clear()
	for par: Array in _botones_diseno:
		_pendientes.append([par[0], par[1]])
	_actualizar()

func _pasa_filtro(d: Array) -> bool:
	var n := int(d[7])
	var f := int(d[2])
	var nombre := String(d[1]).to_lower()
	if _busqueda.strip_edges() != "" and not nombre.contains(_busqueda.strip_edges().to_lower()):
		return false
	match String(FILTROS[_filtro][1]):
		"c1": return n == 1
		"c2": return n == 2
		"c3": return n == 3
		"c45": return n >= 4
		"clasico": return f >= 100 or f <= 14
		"moderno": return f >= 30 and f < 100
		"geo": return f in [8, 17, 18, 19, 27, 29, 33, 37, 38, 48, 49, 55, 59, 60, 61]
		"rayas": return f in [1, 2, 14, 28, 39, 46, 50, 52, 53, 57, 101, 105, 108] or nombre.contains("franja")
	return true

func _filtrar(cuenta: Label) -> void:
	var vis := 0
	for par: Array in _botones_diseno:
		var ok := _pasa_filtro(DisenosKit.diseno(String(par[1])))
		((par[0] as Control).get_parent() as Control).visible = ok
		if ok:
			vis += 1
	cuenta.text = "%d de %d" % [vis, _botones_diseno.size()]

func _marcar_diseno() -> void:
	var usa := int(DisenosKit.diseno(String(_kit["dis"]))[7])
	for par: Array in _botones_diseno:
		var sel := String(par[1]) == String(_kit["dis"])
		(par[0] as TextureButton).modulate = Color.WHITE if sel else Color(1, 1, 1, 0.75)
		(par[2] as Label).add_theme_color_override("font_color", Tema.ORO if sel else Tema.SUAVE)
	for i in _colores.size():
		(_colores[i] as Control).modulate = Color.WHITE if i < maxi(usa, 2) else Color(1, 1, 1, 0.4)

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
	## El corte del cuello (26-9-2026): pico, redondo, polo con tapeta o mao.
	fila2.add_child(Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE, "   Cuello:"))
	var oc := OptionButton.new()
	for i in DisenosKit.CUELLOS.size():
		oc.add_item(String(DisenosKit.CUELLOS[i]), i)
	oc.selected = int(_kit.get("cuello", 0))
	oc.item_selected.connect(func(i: int) -> void:
		_kit["cuello"] = i
		_color_cambiado())
	fila2.add_child(oc)
	vb.add_child(Tema.rotulo("DISEÑOS (%d)" % DisenosKit.DISENOS.size()))
	## Filtros de la galería: por colores, por estilo y por nombre.
	var filtros := HBoxContainer.new()
	filtros.add_theme_constant_override("separation", 8)
	vb.add_child(filtros)
	var of := OptionButton.new()
	for f: Array in FILTROS:
		of.add_item(String(f[0]))
	of.selected = _filtro
	filtros.add_child(of)
	var busca := LineEdit.new()
	busca.placeholder_text = Idiomas.t("🔎 Buscar diseño…")
	busca.custom_minimum_size = Vector2(240, 0)
	busca.text = _busqueda
	filtros.add_child(busca)
	var cuenta := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "")
	filtros.add_child(cuenta)
	of.item_selected.connect(func(i: int) -> void:
		_filtro = i
		_filtrar(cuenta))
	busca.text_changed.connect(func(t: String) -> void:
		_busqueda = t
		_filtrar(cuenta))
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
		b.tooltip_text = (Idiomas.t("%s · usa %d color") if int(d[7]) == 1 else Idiomas.t("%s · usa %d colores")) % [String(d[1]), int(d[7])]
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
	_filtrar(cuenta)
	return sc

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
		b.text = Idiomas.t("Igual al color %d") % (i + 1)
		var idx := i
		b.pressed.connect(func() -> void:
			_kit["num"] = String((_kit["cols"] as Array)[idx])
			_actualizar())
		rapidos.add_child(b)
	return vb

## Recalcula los sponsors del kit en edición respetando los que se ocultan.
func _aplicar_sponsors() -> void:
	var sp := SponsorKit.de_club(_club, _mundo)
	for z: String in _kit.get("sp_ocultar", []):
		sp.erase(z)
	_kit["sp"] = sp
