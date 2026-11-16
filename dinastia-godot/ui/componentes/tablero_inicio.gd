class_name TableroInicio
extends RefCounted
## EL MENÚ CENTRAL COMO MOSAICO (16-11, orden 57 del dueño, frente 1: «menús al nivel PES 2020»).
## Referencia: el menú central de la Liga Master de PES 2020 (Drive del dueño, `referencias_del_dueño`): una barra de
## PESTAÑAS arriba («Avanzar en el tiempo / Dirección del equipo / Información del club») y debajo un MOSAICO de tarjetas
## grandes de tamaños distintos (una principal de 2x2, columnas altas y una fila baja), cada una con su nombre abajo, un
## dato vivo y un borde que se ENCIENDE al pasar o con el foco del mando (las reseñas del PES 2020 se quejaban de que en
## su menú se perdía de vista lo seleccionado: aquí el foco es un borde grueso del color del club). Lo que antes eran la
## tabla (columna izquierda) y «Lo que va pasando» (derecha) son tarjetas del mosaico; esas columnas quedan ocultas en el
## central (no se borran: siguen existiendo para las pruebas y la columna derecha vuelve a verse con la ficha en Plantel).
## El contenido de las tarjetas de la primera pestaña está en `MosaicoTarjetas`.

const PESTANAS := ["Avanzar en el tiempo", "Dirección del equipo", "Información del club"]
const ALTO_ALTA := 190.0   ## fila de arriba: tarjeta principal y columnas altas
const ALTO_BAJA := 88.0   ## fila de abajo
const SEP := 10

## La pestaña elegida sobrevive a los repintados del central.
static var pestana := 0

## (Dirección del equipo / Información del club) Tarjetas que abren un submenú del panel lateral, por su rótulo en
## `MenusLaterales` (el primero que lo tenga). La primera es la grande; luego dos columnas de dos; luego la fila baja.
const EQUIPO := ["*plantel", "Pizarra y dibujo", "Entrenamiento", "Mercado de fichajes", "Academia",
	"Enfermería", "Contratos", "Personal del club", "Camarín"]
const CLUB := ["*cuentas", "Patrocinadores", "Hinchada y socios", "Diseño del estadio", "Historia del club",
	"Ligas y clubes", "Correo", "Récords", "*sistema"]

static func pintar(p: Principal, raiz: VBoxContainer, c: Club, liga: Liga, dias_al_partido: int = 0) -> void:
	ocultar_columnas(p)
	var mos := VBoxContainer.new()
	mos.name = "Mosaico"
	mos.add_theme_constant_override("separation", SEP)
	raiz.add_child(mos)
	var barra := HBoxContainer.new()
	barra.add_theme_constant_override("separation", 4)
	mos.add_child(barra)
	var cuerpo := VBoxContainer.new()
	cuerpo.add_theme_constant_override("separation", SEP)
	mos.add_child(cuerpo)
	var acento := p._con_contraste(p._acento_de(c))
	var botones: Array[Button] = []
	for i in PESTANAS.size():
		var b := _boton_pestana(Idiomas.t(String(PESTANAS[i])).to_upper(), acento)
		barra.add_child(b)
		botones.append(b)
		b.pressed.connect(func() -> void:
			pestana = i
			_marcar(botones)
			_cuerpo(p, cuerpo, c, liga, dias_al_partido, acento))
	_marcar(botones)
	_cuerpo(p, cuerpo, c, liga, dias_al_partido, acento)

## La tabla (izquierda) y la columna derecha del central dejan su sitio al mosaico. La derecha se oculta solo mientras
## está en el central: el menú Plantel se la lleva como columna de la ficha y la vuelve a mostrar (`PantallaMenu._ver_ficha`).
static func ocultar_columnas(p: Principal) -> void:
	if p._col_derecha == null or p._lista_tabla == null:
		return
	var fila := p._col_derecha.get_parent()
	if fila == null or not (fila is BoxContainer):   ## de pie (`DisenoVertical.apilar`) es una VBoxContainer
		return
	if p._col_derecha.get_parent() == fila:
		p._col_derecha.visible = false
	var n: Node = p._lista_tabla
	while n != null and n.get_parent() != fila:
		n = n.get_parent()
	if n is Control:
		(n as Control).visible = false
	## La fila de PRÓXIMOS de arriba repite la tarjeta «Calendario» del mosaico: se oculta (sigue llenándose y su 📅 funciona).
	var prox: Variant = p._guia.nodos.get("fila_proximos")
	var q: Node = prox if is_instance_valid(prox) else null
	while q != null and q.get_parent() != null and not q.get_parent().is_ancestor_of(fila):
		q = q.get_parent()
	if q is Control:
		(q as Control).visible = false

static func _marcar(botones: Array[Button]) -> void:
	for i in botones.size():
		botones[i].button_pressed = i == pestana

static func _cuerpo(p: Principal, cuerpo: VBoxContainer, c: Club, liga: Liga, dias: int, acento: Color) -> void:
	for h in cuerpo.get_children():
		h.queue_free()
	match pestana:
		1: _de_subs(p, cuerpo, c, EQUIPO, acento)
		2: _de_subs(p, cuerpo, c, CLUB, acento)
		_: MosaicoTarjetas.avanzar(p, cuerpo, c, liga, dias, acento)

## Coloca el mosaico: `grande` (2 de ancho), `altas` (columnas de 1 o 2 tarjetas) y `bajas` (la fila de abajo).
## De pie (teléfono vertical) todo baja a dos columnas.
static func colocar(cuerpo: VBoxContainer, grande: Control, altas: Array, bajas: Array) -> void:
	if DisenoVertical.activo():
		grande.custom_minimum_size.y = ALTO_ALTA
		cuerpo.add_child(grande)
		var g := GridContainer.new()
		g.columns = 2
		g.add_theme_constant_override("h_separation", SEP)
		g.add_theme_constant_override("v_separation", SEP)
		cuerpo.add_child(g)
		for col: Array in altas:
			for t: Control in col:
				t.custom_minimum_size.y = ALTO_BAJA * (2.0 if col.size() == 1 else 1.0)
				t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				g.add_child(t)
		for t: Control in bajas:
			t.custom_minimum_size.y = ALTO_BAJA
			t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			g.add_child(t)
		return
	var arriba := HBoxContainer.new()
	arriba.add_theme_constant_override("separation", SEP)
	arriba.custom_minimum_size.y = ALTO_ALTA
	cuerpo.add_child(arriba)
	grande.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grande.size_flags_stretch_ratio = 2.0
	arriba.add_child(grande)
	for col: Array in altas:
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", SEP)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		arriba.add_child(v)
		for t: Control in col:
			t.size_flags_vertical = Control.SIZE_EXPAND_FILL
			v.add_child(t)
	var abajo := HBoxContainer.new()
	abajo.add_theme_constant_override("separation", SEP)
	abajo.custom_minimum_size.y = ALTO_BAJA
	cuerpo.add_child(abajo)
	for t: Control in bajas:
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t.size_flags_stretch_ratio = float(t.get_meta("ancho", 1.0))
		abajo.add_child(t)

## Una TARJETA del mosaico: un botón entero (se pulsa, recibe el foco del mando), su contenido en `contenido` (lo que
## devuelve, un VBox) y el NOMBRE abajo a la izquierda, en mayúsculas, como en el PES. `al_pulsar` abre su pantalla.
static func tarjeta(nombre: String, acento: Color, al_pulsar: Callable, fondo := Color(0.03, 0.06, 0.045, 0.86)) -> Array:
	var b := Button.new()
	b.clip_contents = true
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.custom_minimum_size = Vector2(150, ALTO_BAJA)
	var st := StyleBoxFlat.new()
	st.bg_color = fondo
	st.border_color = Color(1, 1, 1, 0.12)
	st.set_border_width_all(1)
	st.set_corner_radius_all(6)
	st.shadow_color = Color(0, 0, 0, 0.45)
	st.shadow_size = 10
	st.shadow_offset = Vector2(0, 5)
	var enc := st.duplicate() as StyleBoxFlat
	enc.bg_color = fondo.lerp(acento, 0.16)
	enc.border_color = acento
	enc.set_border_width_all(3)
	enc.shadow_color = Color(acento, 0.35)
	enc.shadow_size = 16
	enc.shadow_offset = Vector2.ZERO
	b.add_theme_stylebox_override("normal", st)
	for k: String in ["hover", "focus", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(k, enc)
	var filo := ColorRect.new()   ## el filo de color arriba, como las pestañas de cartón de las tarjetas del PES
	filo.color = Color(acento, 0.85)
	filo.anchor_right = 1.0
	filo.offset_left = 10; filo.offset_right = -10; filo.offset_top = 0; filo.offset_bottom = 3
	b.add_child(filo)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 14; v.offset_right = -14; v.offset_top = 9; v.offset_bottom = -25
	v.add_theme_constant_override("separation", 3)
	b.add_child(v)
	var pie := Label.new()   ## el nombre de la tarjeta, abajo
	pie.text = nombre.to_upper()
	pie.add_theme_font_size_override("font_size", Tema.letra(12))
	pie.add_theme_color_override("font_color", Color(1, 1, 1, 0.92))
	pie.anchor_top = 1.0; pie.anchor_bottom = 1.0; pie.anchor_right = 1.0
	pie.offset_left = 14; pie.offset_right = -30; pie.offset_top = -24; pie.offset_bottom = -4
	pie.clip_text = true
	b.add_child(pie)
	var flecha := Label.new()
	flecha.text = "▸"
	flecha.add_theme_font_size_override("font_size", Tema.letra(14))
	flecha.add_theme_color_override("font_color", acento)
	flecha.anchor_left = 1.0; flecha.anchor_top = 1.0; flecha.anchor_right = 1.0; flecha.anchor_bottom = 1.0
	flecha.offset_left = -26; flecha.offset_top = -25; flecha.offset_right = -10; flecha.offset_bottom = -4
	b.add_child(flecha)
	b.mouse_entered.connect(func() -> void:   ## ratón y mando comparten un solo «seleccionado» (sin robárselo a un campo de texto)
		if b.is_inside_tree() and not (b.get_viewport().gui_get_focus_owner() is LineEdit):
			b.grab_focus())
	if al_pulsar.is_valid():
		b.pressed.connect(al_pulsar)
	return [b, v]

## Ignora el ratón en todo lo de dentro (el botón es el que se pulsa). Llamar al terminar de llenar la tarjeta.
static func cerrar(b: Control) -> void:
	for n in b.find_children("*", "Control", true, false):
		(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

static func etiqueta(texto: String, tam: int, col: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", Tema.letra(tam))
	l.add_theme_color_override("font_color", col)
	return l

## Abre el submenú del panel lateral con ese rótulo («*sistema» = la portada de Ajustes).
static func abrir(p: Principal, rotulo: String) -> void:
	if p._menu_lateral == null:
		return
	if rotulo == "*sistema":
		p._menu_lateral.abrir_menu("ajustes", -1)
		return
	var sitio := buscar(rotulo)
	if not sitio.is_empty():
		p._menu_lateral.abrir_menu(String(sitio[0]), int(sitio[1]))

## [id del menú, índice del submenú] del primero que se llama así, o [].
static func buscar(rotulo: String) -> Array:
	for m: Dictionary in MenusLaterales.MENUS:
		var subs: Array = m["subs"]
		for i in subs.size():
			if String((subs[i] as Dictionary).get("label", "")) == rotulo:
				return [String(m["id"]), i]
	return []

static func _de_subs(p: Principal, cuerpo: VBoxContainer, c: Club, lista: Array, acento: Color) -> void:
	var t: Array[Control] = []
	for rot: String in lista:
		var dest := rot
		if rot == "*plantel":
			t.append(MosaicoTarjetas.plantel(p, c, acento))
			continue
		if rot == "*cuentas":
			t.append(MosaicoTarjetas.cuentas(p, c, acento))
			continue
		var sitio := buscar(rot)
		var sub: Dictionary = {}
		if not sitio.is_empty():
			sub = (MenusLaterales.menu_por_id(String(sitio[0]))["subs"] as Array)[int(sitio[1])]
		elif rot == "*sistema":
			sub = {"label": "Sistema", "icono": "⚙️", "desc": "Guardar, cargar, pantalla, sonido y controles."}
		var tc := tarjeta(Idiomas.t(String(sub.get("label", rot))), acento, func() -> void: abrir(p, dest))
		var v: VBoxContainer = tc[1]
		(tc[0] as Button).tooltip_text = Idiomas.t(String(sub.get("desc", "")))   ## la descripción, al pasar: la tarjeta lleva icono y dato vivo
		var fila := HBoxContainer.new()
		fila.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(fila)
		var ic := IconosUI.control(String(sub.get("icono", "•")), 32)
		ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		fila.add_child(ic)
		var dato := MenuLateral.dato(p, sub) if not sub.is_empty() else ""
		var d := etiqueta(dato, 16, acento)
		d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		d.size_flags_vertical = Control.SIZE_SHRINK_END
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		d.clip_text = true
		fila.add_child(d)
		cerrar(tc[0])
		t.append(tc[0])
	colocar(cuerpo, t[0], [[t[1], t[2]], [t[3], t[4]]], t.slice(5))

static func _boton_pestana(texto: String, acento: Color) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.text = texto
	b.focus_mode = Control.FOCUS_ALL
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(60, 34)
	b.clip_text = true   ## de pie no caben enteras: se recortan en vez de ensanchar la pantalla
	b.tooltip_text = texto
	b.add_theme_font_size_override("font_size", Tema.letra(11 if DisenoVertical.activo() else 13))
	b.add_theme_color_override("font_color", Tema.SUAVE.lightened(0.15))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0.35)
	normal.set_corner_radius_all(4)
	normal.border_color = Color(1, 1, 1, 0.08)
	normal.border_width_bottom = 2
	var activa := normal.duplicate() as StyleBoxFlat
	activa.bg_color = Color(acento, 0.22)
	activa.border_color = acento
	activa.border_width_bottom = 4
	var enc := activa.duplicate() as StyleBoxFlat
	enc.border_width_top = 1; enc.border_width_left = 1; enc.border_width_right = 1
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("pressed", activa)
	b.add_theme_stylebox_override("hover", enc)
	b.add_theme_stylebox_override("hover_pressed", enc)
	b.add_theme_stylebox_override("focus", enc)
	return b
