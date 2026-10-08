class_name CreadorPersonaje
extends Control
## EL CREADOR DE PERSONAJE (26-9-2026), a pantalla completa. Pedido del
## usuario: *"ve por el modelo de nuestro personaje, el modificable"*.
##
## A la izquierda, tu personaje en 3D en un estudio con tres luces, girando
## (se puede arrastrar para girarlo a mano). A la derecha, pestañas:
##   Cuerpo · Piel y pelo · Ropa · Accesorios · Conjuntos
## Arriba: Aleatorio, Deshacer, Cancelar y Guardar. Guardar deja el aspecto en
## `Roles.look["p3d"]`: es el mismo que se ve en la banda de cada partido.

signal cerrado

var _mundo: Mundo
var _asp: Dictionary = {}
var _historial: Array = []           ## para Deshacer
var _vp: SubViewport
var _pivote: Node3D
var _actual: Dictionary = {}
var _pendiente := 0.0                ## rearmar el 3D tras un respiro
var _girar := true
var _arrastrando := false
var _pestanas: TabContainer
var _capa: CanvasLayer = null
var _menu: Control = null
var _c1 := Color("1f5fa8")
var _c2 := Color.WHITE

static func abrir(padre: Control, mundo: Mundo) -> CreadorPersonaje:
	var n := CreadorPersonaje.new()
	n._mundo = mundo
	n._asp = PersonajeDT.aspecto(mundo.roles.aspecto_3d())
	var club := mundo.mi_club()
	if club != null:
		n._c1 = Color(club.color1)
		n._c2 = Color(club.color2)
	n.set_anchors_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	if padre.is_inside_tree():
		n._capa = CanvasLayer.new()
		n._capa.layer = 60
		n._capa.name = "PantallaPersonaje"
		padre.get_tree().root.add_child(n._capa)
		n._capa.add_child(n)
		n._menu = padre
		padre.visible = false
	else:
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
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 8)
	vb.add_child(cab)
	var t := Tema.etiqueta(Tema.TAM_TITULO + 4, Tema.ORO, "🧍 TU PERSONAJE")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(t)
	for par: Array in [["🎲 Aleatorio", _aleatorio], ["↶ Deshacer", _deshacer], ["Cancelar", _cerrar], ["💾 Guardar", _guardar]]:
		var b := Button.new()
		b.text = String(par[0])
		b.custom_minimum_size = Vector2(130, 40)
		b.pressed.connect(par[1])
		cab.add_child(b)
	var cuerpo := HBoxContainer.new()
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_theme_constant_override("separation", 16)
	vb.add_child(cuerpo)
	cuerpo.add_child(_estudio())
	_pestanas = TabContainer.new()
	_pestanas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pestanas.custom_minimum_size = Vector2(460, 0)
	cuerpo.add_child(_pestanas)
	_pintar_pestanas()
	_rearmar()
	Animar.aparecer(marco)

func _pintar_pestanas() -> void:
	var cual := _pestanas.current_tab if _pestanas.get_tab_count() > 0 else 0
	for h in _pestanas.get_children():
		_pestanas.remove_child(h)
		h.queue_free()
	_pestanas.add_child(_tab_cuerpo())
	_pestanas.add_child(_tab_pelo())
	_pestanas.add_child(_tab_ropa())
	_pestanas.add_child(_tab_accesorios())
	_pestanas.add_child(_tab_conjuntos())
	_pestanas.current_tab = clampi(cual, 0, _pestanas.get_tab_count() - 1)

## ------------------------------------------------------------ EL ESTUDIO

func _estudio() -> Control:
	var cont := SubViewportContainer.new()
	cont.stretch = true
	cont.custom_minimum_size = Vector2(460, 500)
	cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cont.gui_input.connect(_arrastre)
	_vp = SubViewport.new()
	_vp.size = Vector2i(600, 700)
	_vp.msaa_3d = Viewport.MSAA_4X
	_vp.own_world_3d = true
	cont.add_child(_vp)
	var mundo3 := Node3D.new()
	_vp.add_child(mundo3)
	var cam := Camera3D.new()
	cam.fov = 38
	## Sin `look_at`: aquí la cámara todavía no está en el árbol.
	cam.transform = Transform3D(Basis.looking_at(Vector3(0, 0.92, 0) - Vector3(0, 1.1, 4.0), Vector3.UP), Vector3(0, 1.1, 4.0))
	mundo3.add_child(cam)
	## Luz de tres puntos: principal cálida, relleno frío y contraluz.
	## Etapa 2 (8-10-2026): más suaves. Con 1,25 + 0,45 + 0,9 y ambiente 0,8 la
	## escena estaba quemada: la piel clara salía BLANCA (manos y cuello
	## «enguantados») y la tarima casi negra se veía gris claro.
	var luces := [[Vector3(-30, 35, 0), 0.95, Color(1.0, 0.95, 0.88)], [Vector3(-10, -40, 0), 0.3, Color(0.8, 0.88, 1.0)], [Vector3(-20, 170, 0), 0.55, Color(1, 1, 1)]]
	for i in luces.size():
		var l: Array = luces[i]
		var luz := DirectionalLight3D.new()
		luz.rotation_degrees = l[0]
		luz.light_energy = float(l[1])
		luz.light_color = l[2]
		luz.shadow_enabled = i == 0
		mundo3.add_child(luz)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.09, 0.11, 0.13)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.57, 0.62)
	e.ambient_light_energy = 0.45
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_exposure = 0.95
	e.tonemap_white = 6.0
	env.environment = e
	mundo3.add_child(env)
	## La tarima: un disco con borde del color del club.
	var tarima := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.75
	cm.bottom_radius = 0.8
	cm.height = 0.08
	tarima.mesh = cm
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(0.13, 0.14, 0.16)
	mt.roughness = 0.8
	tarima.material_override = mt
	tarima.position.y = -0.04
	mundo3.add_child(tarima)
	var aro := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.76
	tm.outer_radius = 0.8
	aro.mesh = tm
	var ma := StandardMaterial3D.new()
	ma.albedo_color = _c1
	ma.emission_enabled = true
	ma.emission = _c1
	ma.emission_energy_multiplier = 0.8
	aro.material_override = ma
	aro.position.y = 0.0
	mundo3.add_child(aro)
	_pivote = Node3D.new()
	mundo3.add_child(_pivote)
	return cont

func _arrastre(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_arrastrando = (ev as InputEventMouseButton).pressed
		if _arrastrando:
			_girar = false
	elif ev is InputEventMouseMotion and _arrastrando:
		_pivote.rotation.y += (ev as InputEventMouseMotion).relative.x * 0.01
	elif ev is InputEventScreenDrag:
		_girar = false
		_pivote.rotation.y += (ev as InputEventScreenDrag).relative.x * 0.01

func _process(delta: float) -> void:
	if _pivote != null and _girar:
		_pivote.rotation.y += delta * 0.6
	if _pendiente > 0.0:
		_pendiente -= delta
		if _pendiente <= 0.0:
			_rearmar()

func _rearmar() -> void:
	if not _actual.is_empty() and is_instance_valid(_actual.get("nodo")):
		(_actual["nodo"] as Node).queue_free()
	_actual = PersonajeDT.crear(_pivote, _asp, _c1, _c2)

## Cambia un rasgo (guardando el anterior para Deshacer) y rearma en un rato.
func _cambiar(clave: String, valor: Variant, repintar := false) -> void:
	if _asp.get(clave) == valor:
		return
	_historial.append(_asp.duplicate())
	if _historial.size() > 40:
		_historial.pop_front()
	_asp[clave] = valor
	_pendiente = 0.18
	if repintar:
		_pintar_pestanas()

## ------------------------------------------------------------ PESTAÑAS

func _hoja(nombre: String) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.name = nombre
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 10)
	sc.add_child(vb)
	return vb

func _deslizador(vb: VBoxContainer, rotulo: String, clave: String, minimo: float, maximo: float, paso: float, fmt: String) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	vb.add_child(fila)
	var et := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, rotulo)
	et.custom_minimum_size = Vector2(120, 0)
	fila.add_child(et)
	var s := HSlider.new()
	s.min_value = minimo
	s.max_value = maximo
	s.step = paso
	s.value = float(_asp[clave])
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.custom_minimum_size = Vector2(200, 28)
	fila.add_child(s)
	var val := Tema.etiqueta(Tema.TAM_CUERPO, Tema.ORO, fmt % float(_asp[clave]))
	val.custom_minimum_size = Vector2(60, 0)
	fila.add_child(val)
	s.value_changed.connect(func(v: float) -> void:
		val.text = fmt % v
		_cambiar(clave, v))

func _opciones(vb: VBoxContainer, rotulo: String, clave: String, lista: Array) -> void:
	vb.add_child(Tema.rotulo(rotulo))
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	vb.add_child(flow)
	for par: Variant in lista:
		var valor: Variant = par[0] if par is Array else par
		var nombre := String(par[1]) if par is Array else String(par).capitalize()
		var b := Button.new()
		b.text = nombre
		b.toggle_mode = true
		b.button_pressed = _asp.get(clave) == valor
		b.custom_minimum_size = Vector2(96, 32)
		b.pressed.connect(func() -> void: _cambiar(clave, valor, true))
		flow.add_child(b)

func _muestras(vb: VBoxContainer, rotulo: String, clave: String, colores: Array) -> void:
	vb.add_child(Tema.rotulo(rotulo))
	var fila := HFlowContainer.new()
	fila.add_theme_constant_override("h_separation", 6)
	vb.add_child(fila)
	for hexa: String in colores:
		var b := Button.new()
		b.custom_minimum_size = Vector2(38, 38)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(hexa)
		sb.set_corner_radius_all(19)
		sb.border_color = Tema.ORO if String(_asp.get(clave, "")) == hexa else Color(0, 0, 0, 0.4)
		sb.set_border_width_all(3)
		for estado in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(estado, sb)
		b.pressed.connect(func() -> void: _cambiar(clave, hexa, true))
		fila.add_child(b)
	var picker := ColorPickerButton.new()
	picker.color = Color(String(_asp.get(clave, "ffffff")))
	picker.custom_minimum_size = Vector2(60, 38)
	picker.color_changed.connect(func(c: Color) -> void: _cambiar(clave, c.to_html(false)))
	fila.add_child(picker)

func _interruptor(vb: VBoxContainer, rotulo: String, clave: String) -> void:
	var c := CheckButton.new()
	c.text = rotulo
	c.button_pressed = bool(_asp.get(clave, false))
	c.toggled.connect(func(on: bool) -> void: _cambiar(clave, on))
	vb.add_child(c)

func _tab_cuerpo() -> Control:
	var vb := _hoja("Cuerpo")
	_opciones(vb, "Cuerpo", "cuerpo", [["male", "Hombre"], ["female", "Mujer"]])
	_deslizador(vb, "Estatura", "altura", 1.55, 2.02, 0.01, "%.2f m")
	_deslizador(vb, "Complexión", "complexion", -1.0, 1.0, 0.05, "%+.2f")
	_deslizador(vb, "Hombros", "hombros", -1.0, 1.0, 0.05, "%+.2f")
	_deslizador(vb, "Barriga", "barriga", -1.0, 1.0, 0.05, "%+.2f")
	_deslizador(vb, "Piernas", "piernas", -1.0, 1.0, 0.05, "%+.2f")
	_deslizador(vb, "Cabeza", "cabeza", -1.0, 1.0, 0.05, "%+.2f")
	var nota := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "Arrastra el personaje para girarlo. Todo lo que cambies aquí se ve en la banda en cada partido.")
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(nota)
	return vb.get_parent()

func _tab_pelo() -> Control:
	var vb := _hoja("Piel y pelo")
	_muestras(vb, "Tono de piel", "piel", PersonajeDT.PIELES)
	_opciones(vb, "Peinado", "pelo", PersonajeDT.CORTES)
	_muestras(vb, "Color de pelo", "color_pelo", PersonajeDT.COLORES_PELO)
	_interruptor(vb, "Barba (cara clásica)", "barba")
	## BIBLIOTECA MODULAR: caras mezcladas (del tono elegido) y cortes medidos.
	if BibliotecaCaras.hay():
		var n_caras := BibliotecaCaras.del_tono(Color(String(_asp.get("piel", "c68d68")))).size()
		var caras: Array = [[-1, "Clásica"]]
		for i in n_caras:
			caras.append([i, "Cara %d" % (i + 1)])
		_selector(vb, "Cara (biblioteca)", "cara", caras)
		var cortes: Array = [["", "Ninguno (el peinado)"]]
		var cuenta := {}
		for k: String in BibliotecaCaras.pelos():
			var nom := BibliotecaCaras.nombre_pelo(k)
			cuenta[nom] = int(cuenta.get(nom, 0)) + 1
			cortes.append([k, "%s %d" % [nom.replace("_", " ").capitalize(), cuenta[nom]]])
		_selector(vb, "Corte medido (con cara de biblioteca)", "corte_med", cortes)
		vb.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE,
			"Las caras de la biblioteca mezclan rasgos de varias personas: no son la cara de nadie. Por ahora, solo con cuerpo de hombre."))
	return vb.get_parent()

## ◀ nombre ▶ para listas largas (las caras y cortes de la biblioteca).
func _selector(vb: VBoxContainer, rotulo: String, clave: String, lista: Array) -> void:
	vb.add_child(Tema.rotulo(rotulo))
	var fila := HBoxContainer.new()
	vb.add_child(fila)
	var actual := 0
	for i in lista.size():
		if (lista[i] as Array)[0] == _asp.get(clave):
			actual = i
	var et := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, String((lista[actual] as Array)[1]))
	et.custom_minimum_size = Vector2(220, 0)
	et.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for paso: int in [-1, 1]:
		var b := Button.new()
		b.text = "◀" if paso < 0 else "▶"
		b.custom_minimum_size = Vector2(40, 32)
		b.pressed.connect(func() -> void:
			var j := 0
			for i in lista.size():
				if (lista[i] as Array)[0] == _asp.get(clave):
					j = i
			j = posmod(j + paso, lista.size())
			et.text = String((lista[j] as Array)[1])
			_cambiar(clave, (lista[j] as Array)[0]))
		fila.add_child(b)
		if paso < 0:
			fila.add_child(et)

func _tab_ropa() -> Control:
	var vb := _hoja("Ropa")
	_opciones(vb, "Estilo", "ropa", PersonajeDT.ROPAS)
	_muestras(vb, "Color principal (chaqueta, polo…)", "c_ropa",
		["1f2a44", "111111", "3a3a3a", "5a4636", "2e3f2a", "6a1b2a", "20354d", "c9c1b0", _c1.to_html(false)])
	_muestras(vb, "Color secundario (camisa, detalles)", "c_ropa2",
		["f2f2f2", "cfe0f5", "e8e0d0", "ffc9c9", "d9d9d9", "111111", _c2.to_html(false)])
	_interruptor(vb, "Corbata (con traje o abrigo)", "corbata")
	var nota := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "El chándal usa siempre los colores del club.")
	vb.add_child(nota)
	return vb.get_parent()

func _tab_accesorios() -> Control:
	var vb := _hoja("Accesorios")
	_opciones(vb, "Gafas", "gafas", PersonajeDT.GAFAS)
	_interruptor(vb, "Gorra del club", "gorra")
	_interruptor(vb, "Bufanda del club", "bufanda")
	_interruptor(vb, "Auriculares", "auriculares")
	_interruptor(vb, "Reloj", "reloj")
	return vb.get_parent()

## Hasta cinco conjuntos guardados con nombre: para cambiar de traje de gala a
## chándal de entrenamiento sin rehacerlo todo.
func _tab_conjuntos() -> Control:
	var vb := _hoja("Conjuntos")
	vb.add_child(Tema.rotulo("Guardar el aspecto actual"))
	var fila := HBoxContainer.new()
	vb.add_child(fila)
	var nombre := LineEdit.new()
	nombre.placeholder_text = "Nombre (p. ej. Gala, Entrenamiento)"
	nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(nombre)
	var bg := Button.new()
	bg.text = "Guardar conjunto"
	fila.add_child(bg)
	var conjuntos: Array = _mundo.roles.look.get("p3d_conjuntos", [])
	bg.pressed.connect(func() -> void:
		var n := nombre.text.strip_edges()
		if n == "":
			n = "Conjunto %d" % (conjuntos.size() + 1)
		conjuntos.append({"n": n, "a": _asp.duplicate()})
		while conjuntos.size() > 5:
			conjuntos.pop_front()
		_mundo.roles.look["p3d_conjuntos"] = conjuntos
		_pintar_pestanas())
	vb.add_child(Tema.rotulo("Tus conjuntos"))
	if conjuntos.is_empty():
		vb.add_child(Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE, "Todavía no guardaste ninguno."))
	for i in conjuntos.size():
		var cj: Dictionary = conjuntos[i]
		var f := HBoxContainer.new()
		vb.add_child(f)
		var et := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, "👔 " + String(cj.get("n", "")))
		et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		f.add_child(et)
		var bp := Button.new()
		bp.text = "Ponérmelo"
		bp.pressed.connect(func() -> void:
			_historial.append(_asp.duplicate())
			_asp = PersonajeDT.aspecto(cj.get("a", {}))
			_pendiente = 0.05
			_pintar_pestanas())
		f.add_child(bp)
		var bb := Button.new()
		bb.text = "✕"
		var idx := i
		bb.pressed.connect(func() -> void:
			conjuntos.remove_at(idx)
			_mundo.roles.look["p3d_conjuntos"] = conjuntos
			_pintar_pestanas())
		f.add_child(bb)
	return vb.get_parent()

## ------------------------------------------------------------ BOTONES

func _aleatorio() -> void:
	_historial.append(_asp.duplicate())
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_asp = PersonajeDT.aleatorio(rng)
	_pendiente = 0.05
	_pintar_pestanas()

func _deshacer() -> void:
	if _historial.is_empty():
		return
	_asp = _historial.pop_back()
	_pendiente = 0.05
	_pintar_pestanas()

func _guardar() -> void:
	_mundo.roles.look["p3d"] = _asp.duplicate()
	## El retrato 2D (fichas, prensa) sigue al 3D: mismo pelo, piel, barba y
	## gafas. Una entrenadora no puede salir con barba en su ficha.
	var l: Dictionary = _mundo.roles.look
	if String(_asp["pelo"]) in CaraDT.CORTES:
		l["pelo"] = String(_asp["pelo"])
	l["pelo_c"] = "#" + String(_asp["color_pelo"])
	l["piel"] = "#" + String(_asp["piel"])
	l["barba"] = 1 if bool(_asp["barba"]) and String(_asp["cuerpo"]) == "male" else 0
	l["gafas"] = String(_asp["gafas"]) != ""
	Genero.fijar(String(_asp["cuerpo"]) == "female")
	Aviso.mostrar(_menu if is_instance_valid(_menu) else get_parent() as Control, "logro", "🧍", "Personaje guardado", "Así te verán en la banda")
	_cerrar()

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and (ev as InputEventKey).pressed and (ev as InputEventKey).keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_cerrar()

func _cerrar() -> void:
	if is_instance_valid(_menu):
		_menu.visible = true
	cerrado.emit()
	if _capa != null:
		_capa.queue_free()
	else:
		queue_free()
