class_name MenuLateral
extends Control
## EL PANEL LATERAL (29-9-2026, mapa de metas 23). Pedido del usuario, con
## Soccer Manager de ejemplo: un apartado a la izquierda del menú central, por
## encima de él, que se toca o se desliza, con los accesos a los menús grandes
## -Historia, Gente, Mi Carrera, Operaciones, Mi Vida, Editar, Ajustes, Ciudad
## 3D y Estadio 3D- y a cada uno de sus submenús. Tocar un menú o un submenú
## abre su `PantallaMenu`, a pantalla completa y con su fondo animado.
##
## Plegado es un riel de iconos; desplegado (tocando ☰, o arrastrando hacia la
## derecha) muestra cada menú con sus submenús. Arrastrar hacia la izquierda, o
## tocar fuera, lo vuelve a plegar.

const ANCHO_RIEL := 62.0
const ANCHO_ABIERTO := 310.0

## Cada menú y sus submenús viven en `MenusLaterales` (3-11: el archivo pasaba de 450 líneas al sumar Partido y Reglas).
const MENUS := MenusLaterales.MENUS

## Un dato vivo para la tarjeta de cada submenú en la portada del menú.
static func dato(p: Principal, sub: Dictionary) -> String:
	return DatoTarjeta.de(p, String(sub.get("label", "")))   ## M-290

## Los grupos de la barra de arriba que ahora viven aquí (la barra se queda
## con CENTRAL y CLUB).
const EN_PANEL := ["gente", "historia", "operaciones", "vida", "ajustes"]

var _p: Principal
var _riel: VBoxContainer
var _cajon: PanelContainer
var _lista: VBoxContainer
var _velo: ColorRect
var _abierto := false
var _arrastre := 0.0
var pantalla_abierta: PantallaMenu
var _botones_riel := {}

static func crear(p: Principal) -> MenuLateral:
	var m := MenuLateral.new()
	m._p = p
	m.name = "MenuLateral"
	m._montar()
	return m

static func menu_por_id(id: String) -> Dictionary:
	for m: Dictionary in MENUS:
		if String(m["id"]) == id:
			return m
	return {}

## Las acciones que no son una pantalla de la interfaz.
static func ejecutar(p: Principal, accion: String) -> void:
	match accion:
		"casa":
			CasaAcceso.abrir(p, p.mundo, p.get("_bandeja") if p.get("_bandeja") != null else [])
		"movil":
			load("res://ui/componentes/telefono.gd").abrir(p, p.mundo)   ## (por load: el móvil no se compila al abrir el menú)
		"ver_estadio":
			p._ver_estadio_con_carga()
		"ciudad_pie", "ciudad_coche":
			if not InterruptorCiudad.activa:
				InterruptorCiudad.avisar_apagada(p)
				return
			p._ver_ciudad_explorando("coche" if accion == "ciudad_coche" else "pie")
		"mi_personaje":
			load("res://ui/componentes/creador_personaje.gd").abrir(p, p.mundo)
		"album":
			PanelMeta.abrir(p, p.mundo)
		"elegir_club":
			## El menú de Competiciones se cierra: «Elegir club» es una ventana propia y debajo quedaba su fondo marrón.
			var ml: Variant = p.get("_menu_lateral")
			if ml != null and is_instance_valid(ml.pantalla_abierta) and not ml.pantalla_abierta.cerrando():
				ml.pantalla_abierta.cerrar()
			p._abrir_elegir_club()
		"minijuegos":
			load("res://ui/componentes/sala_minijuegos.gd").abrir(p, p.mundo)
		"plantilla_pes":
			load("res://ui/componentes/plantilla_pes.gd").abrir(p)
		"capitulos":
			load("res://ui/componentes/capitulos_selector.gd").abrir(p)
		"documental":
			## El último cerrado; si todavía no hay, el avance de la que se juega.
			var documental: GDScript = load("res://ui/componentes/documental_temporada.gd")   ## (A4 memoria) por ruta
			var caps: Array = documental.ultimo if not documental.ultimo.is_empty() else documental.guion(p.mundo)
			documental.abrir(p, caps, p._retrato)

func _montar() -> void:
	set_anchors_preset(Control.PRESET_LEFT_WIDE)
	offset_right = ANCHO_RIEL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	## El velo oscurece el resto al abrir el cajón, y tocarlo lo cierra.
	_velo = ColorRect.new()
	_velo.color = Color(0, 0, 0, 0.0)
	_velo.visible = false
	_velo.mouse_filter = Control.MOUSE_FILTER_STOP
	_velo.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			plegar())
	add_child(_velo)
	var fondo_riel := PanelContainer.new()
	fondo_riel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	fondo_riel.offset_right = ANCHO_RIEL
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.02, 0.03, 0.04, 0.9)
	st.border_color = Color(1, 1, 1, 0.08)
	st.border_width_right = 1
	fondo_riel.add_theme_stylebox_override("panel", st)
	fondo_riel.mouse_filter = Control.MOUSE_FILTER_STOP
	fondo_riel.gui_input.connect(_al_arrastrar)
	add_child(fondo_riel)
	_riel = VBoxContainer.new()
	_riel.add_theme_constant_override("separation", 3)
	_riel.alignment = BoxContainer.ALIGNMENT_BEGIN
	## (3-11) Con Partido y Reglas son 16 botones: en pantallas bajas (el teléfono apaisado) el riel se desliza en vez de salirse por abajo.
	var desliza := ScrollContainer.new()
	desliza.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	desliza.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	desliza.add_child(_riel)
	_riel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fondo_riel.add_child(desliza)
	var hamb := _boton_riel("☰", "Abrir el panel (o deslizar hacia la derecha)")
	hamb.pressed.connect(alternar)
	_riel.add_child(hamb)
	## (3-11, C7 del dueño: «¿dónde está lo de salir al mundo abierto?») Siempre a la vista, arriba del riel.
	## (9-11, «solo club») Con la ciudad apagada, este botón entra al club (el estadio y sus plantas) en vez de al mundo abierto.
	var salir := _boton_riel("🚶" if InterruptorCiudad.activa else "🏟️", "Salir al mundo abierto" if InterruptorCiudad.activa else "Entrar al club")
	salir.pressed.connect(func() -> void: ejecutar(_p, "ciudad_pie" if InterruptorCiudad.activa else "ver_estadio"))
	_riel.add_child(salir)
	_riel.add_child(HSeparator.new())
	for m: Dictionary in MENUS:
		var b := _boton_riel(String(m["icono"]), String(m["nombre"]))
		var id := String(m["id"])
		b.toggle_mode = true
		b.pressed.connect(func() -> void: abrir_menu(id, -1))
		_riel.add_child(b)
		_botones_riel[id] = b

	## EL CAJÓN: cada menú con sus submenús.
	_cajon = PanelContainer.new()
	_cajon.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_cajon.offset_left = ANCHO_RIEL
	_cajon.offset_right = ANCHO_RIEL + ANCHO_ABIERTO
	var sc := StyleBoxFlat.new()
	sc.bg_color = Color(0.03, 0.045, 0.06, 0.97)
	sc.border_color = Color(1, 1, 1, 0.1)
	sc.border_width_right = 1
	sc.shadow_color = Color(0, 0, 0, 0.5)
	sc.shadow_size = 18
	sc.content_margin_left = 10; sc.content_margin_right = 10; sc.content_margin_top = 12
	_cajon.add_theme_stylebox_override("panel", sc)
	_cajon.visible = false
	_cajon.mouse_filter = Control.MOUSE_FILTER_STOP
	_cajon.gui_input.connect(_al_arrastrar)
	add_child(_cajon)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_cajon.add_child(scroll)
	_lista = VBoxContainer.new()
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista.add_theme_constant_override("separation", 2)
	scroll.add_child(_lista)
	var mundo := Button.new()   ## y el primero del cajón, con letra grande
	mundo.set_meta("_es", ["cab", "🚶" if InterruptorCiudad.activa else "🏟️", "Salir al mundo abierto" if InterruptorCiudad.activa else "Entrar al club"])
	mundo.alignment = HORIZONTAL_ALIGNMENT_LEFT
	mundo.add_theme_font_size_override("font_size", Tema.letra(16))
	mundo.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	mundo.pressed.connect(func() -> void:
		plegar()
		ejecutar(_p, "ciudad_pie" if InterruptorCiudad.activa else "ver_estadio"))
	_lista.add_child(mundo)
	_lista.add_child(HSeparator.new())
	for m: Dictionary in MENUS:
		var id := String(m["id"])
		var cab := Button.new()
		cab.set_meta("_es", ["cab", String(m["icono"]), String(m["nombre"])])
		cab.alignment = HORIZONTAL_ALIGNMENT_LEFT
		cab.flat = true
		cab.add_theme_font_size_override("font_size", Tema.letra(15))
		cab.add_theme_color_override("font_color", Color(String((m["colores"] as Array)[2])).lightened(0.2))
		cab.pressed.connect(func() -> void: abrir_menu(id, -1))
		_lista.add_child(cab)
		var subs: Array = m["subs"]
		for i in subs.size():
			var sb := Button.new()
			sb.set_meta("_es", ["sub", "▶ " if (subs[i] as Dictionary).has("accion") else "", String(subs[i]["label"])])
			sb.alignment = HORIZONTAL_ALIGNMENT_LEFT
			sb.flat = true
			sb.add_theme_font_size_override("font_size", Tema.letra(12))
			sb.add_theme_color_override("font_color", Color(1, 1, 1, 0.72))
			var k := i
			sb.pressed.connect(func() -> void: abrir_menu(id, k))
			_lista.add_child(sb)
		_lista.add_child(HSeparator.new())
	_traducir()

## TEXTOS EN EL IDIOMA ELEGIDO (25-10-2026, uitm). El cajón y los avisos del
## riel se escribían en castellano siempre: los nombres de los menús y submenús
## ya estaban traducidos -los usa `PantallaMenu`- pero aquí no se pedían. Cada
## botón guarda su texto original y se vuelve a traducir al desplegar, por si
## se cambió de idioma con el panel ya montado.
func _traducir() -> void:
	for b: Node in _lista.get_children():
		if b is Button and b.has_meta("_es"):
			var d: Array = b.get_meta("_es")
			if String(d[0]) == "cab":
				(b as Button).text = "%s  %s" % [String(d[1]), Idiomas.mayusculas(Idiomas.t(String(d[2])))]
			else:
				(b as Button).text = "      %s%s" % [String(d[1]), Idiomas.t(String(d[2]))]
	for b: Node in _riel.get_children():
		if b is Button and b.has_meta("_es_tip"):
			(b as Button).tooltip_text = Idiomas.t(String(b.get_meta("_es_tip")))

## El botón del riel de un menú (la guía del tutorial lo señala).
func boton_de(id: String) -> Button:
	return _botones_riel.get(id, null)

func _boton_riel(texto: String, tip: String) -> Button:
	var b := Button.new()
	b.text = texto
	b.set_meta("_es_tip", tip)
	b.tooltip_text = Idiomas.t(tip)
	b.flat = true
	## El del menú abierto queda marcado con una franja a la izquierda.
	var marcado := StyleBoxFlat.new()
	marcado.bg_color = Color(1, 1, 1, 0.1)
	marcado.border_color = Color(1, 1, 1, 0.85)
	marcado.border_width_left = 4
	b.add_theme_stylebox_override("pressed", marcado)
	b.add_theme_stylebox_override("hover_pressed", marcado)
	b.custom_minimum_size = Vector2(ANCHO_RIEL, 40)
	b.add_theme_font_size_override("font_size", 24)
	return b

func _al_arrastrar(e: InputEvent) -> void:
	var dx := 0.0
	if e is InputEventScreenDrag:
		dx = (e as InputEventScreenDrag).relative.x
	elif e is InputEventMouseMotion and ((e as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		dx = (e as InputEventMouseMotion).relative.x
	elif e is InputEventMouseButton and not (e as InputEventMouseButton).pressed:
		_arrastre = 0.0
		return
	if dx == 0.0:
		return
	_arrastre += dx
	if _arrastre > 40.0 and not _abierto:
		desplegar()
		_arrastre = 0.0
	elif _arrastre < -40.0 and _abierto:
		plegar()
		_arrastre = 0.0

func alternar() -> void:
	if _abierto:
		plegar()
	else:
		desplegar()

func desplegar() -> void:
	if _abierto:
		return
	_abierto = true
	_traducir()
	## Encima de todo lo que flota sobre el centro (el consejo del presidente,
	## abajo a la izquierda, tapaba la mitad del cajón): abrirlo es lo último
	## que pidió el jugador. Mismo movimiento que hace `abrir_menu()`.
	if get_parent() != null:
		get_parent().move_child(self, get_parent().get_child_count() - 1)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_velo.visible = true
	_velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cajon.visible = true
	if Animar.reducidas():   ## M-304: con animaciones reducidas, el cajón aparece sin deslizarse
		_cajon.modulate.a = 1.0
		_cajon.position.x = ANCHO_RIEL
		_velo.color.a = 0.45
		return
	_cajon.modulate.a = 0.0
	_cajon.position.x = ANCHO_RIEL - 40.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_cajon, "modulate:a", 1.0, 0.18)
	tw.tween_property(_cajon, "position:x", ANCHO_RIEL, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_velo, "color:a", 0.45, 0.2)

func plegar() -> void:
	if not _abierto:
		return
	_abierto = false
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_cajon, "modulate:a", 0.0, 0.15)
	tw.tween_property(_velo, "color:a", 0.0, 0.15)
	tw.chain().tween_callback(func() -> void:
		_cajon.visible = false
		_velo.visible = false
		set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
		offset_right = ANCHO_RIEL)

func abierto() -> bool:
	return _abierto

## Abre el menú `id` a pantalla completa: en su portada (`sub` = -1) o
## directamente en el submenú `sub`. Si ya hay uno abierto se cierra antes
## (una sola mudanza a la vez); si es el mismo menú, solo cambia de submenú.
func abrir_menu(id: String, sub: int = -1) -> PantallaMenu:
	plegar()
	var m := menu_por_id(id)
	if m.is_empty() or _p.mundo == null:
		return null
	var subs: Array = m["subs"]
	var es_accion: bool = sub >= 0 and sub < subs.size() and (subs[sub] as Dictionary).has("accion")
	if is_instance_valid(pantalla_abierta) and pantalla_abierta.cerrando():
		pantalla_abierta = null
	if is_instance_valid(pantalla_abierta) and String(pantalla_abierta.get_meta("id", "")) == id:
		if sub < 0:
			pantalla_abierta.portada()
		else:
			pantalla_abierta.elegir(sub)
		return pantalla_abierta
	if is_instance_valid(pantalla_abierta):
		pantalla_abierta.cerrar()
	## La tarjeta de ayuda del menú anterior no pasa al siguiente.
	for c in _p.find_children("CapaTutorial", "", false, false):
		c.queue_free()
	## Mientras se abre, la pantalla cambia de pestaña por dentro: eso no debe abrir OTRO menú (`_abrir_en_lateral`).
	var antes: bool = _p._redirigiendo
	_p._redirigiendo = true
	pantalla_abierta = PantallaMenu.abrir(_p, m, -1 if es_accion else sub)
	_p._redirigiendo = antes
	pantalla_abierta.cerrada.connect(_marcar_riel.bind(""))
	## (3-11, rediseño) Al cerrar, el central vuelve a su Inicio (ya no tiene pestañas para volver a mano).
	pantalla_abierta.cerrada.connect(func() -> void:
		if not is_instance_valid(pantalla_abierta) or pantalla_abierta.cerrando():
			_p._ir_a_pestana("Inicio"))
	## El panel queda por encima de la pantalla del menú.
	get_parent().move_child(self, get_parent().get_child_count() - 1)
	_marcar_riel(id)
	if es_accion:
		ejecutar(_p, String(subs[sub]["accion"]))
	return pantalla_abierta

func _marcar_riel(id: String) -> void:
	for k: String in _botones_riel:
		(_botones_riel[k] as Button).set_pressed_no_signal(k == id)

## El menú de al lado, en el orden del riel (L2/R2 con un menú abierto).
func menu_vecino(paso: int) -> void:
	var i := 0
	if is_instance_valid(pantalla_abierta):
		for k in MENUS.size():
			if String(MENUS[k]["id"]) == String(pantalla_abierta.get_meta("id", "")):
				i = k
	i = (i + paso + MENUS.size()) % MENUS.size()
	abrir_menu(String(MENUS[i]["id"]), -1)

## Hay algo del panel encima del menú central (el cajón o un menú abierto).
func ocupado() -> bool:
	return _abierto or is_instance_valid(pantalla_abierta)

func _unhandled_input(e: InputEvent) -> void:
	## Con el cajón abierto, Esc lo pliega antes que nada.
	if _abierto and e.is_action_pressed("ui_cancel"):
		plegar()
		get_viewport().set_input_as_handled()
