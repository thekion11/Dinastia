class_name PantallaModos
extends Control
## EL MENÚ INICIAL DE MODOS (fase 1 del megaplan, etapa 2). Una pantalla para
## UNA sola decisión: con qué modo se juega. A la izquierda la lista de modos
## (los de `MODOS_JUEGO`, agrupados por `MODO_SECCIONES`, como la pantalla de
## título); a la derecha la ficha del modo que se mira; detrás, un fondo que
## funde hacia el ambiente de ese modo (`MenuModosFondo`). Ratón, teclado y
## mando se tratan igual: pasar el cursor por un modo le da el foco, y el foco
## es lo que decide qué se ve.
##
## Contrato de las pantallas de entrada: `configurar(estado)` antes o después
## de entrar al árbol (`estado.modo` deja preseleccionado el que ya se había
## elegido, para cuando se vuelve atrás); `terminado({"modo": clave})` tras
## confirmar, con la clave de `MODOS_JUEGO` («dt», «dir», «cantera»,
## «carrera-m»…); `volver()` con Esc / B / el botón de volver.
##
## Esta pantalla no arranca ninguna partida ni toca `Principal`: quien la usa
## decide qué hacer con la clave (lo mismo que hoy hace `Inicio._al_pulsar_modo`).

signal terminado(datos: Dictionary)
signal volver()

## A los cuántos segundos aparece el logo arriba a la derecha.
const SEG_LOGO := 20.0
## Categorías que todavía no llevan a una partida: se ven (apagadas) pero no se
## pueden confirmar. Las mismas que en `Inicio`.
const CATS_SIN_JUGAR := ["proximo"]
const ANCHO_LISTA := 340.0

var _estado: Dictionary = {}
var _modos: Array[Dictionary] = []
var _botones: Array[Button] = []
var _sel := -1
var _hecho := false

var _fondo: MenuModosFondo
var _bokeh: FondoParticulas
var _logo: MenuModosLogo
var _reloj_logo: Timer
var _confirmar: MenuModosConfirmar
var _lista: VBoxContainer
var _ficha: MenuModosFicha

# --- contrato -------------------------------------------------------------------

func configurar(estado: Variant) -> void:
	_estado = (estado as Dictionary).duplicate() if estado is Dictionary else {}
	if is_inside_tree() and not _botones.is_empty():
		_preseleccionar()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	## Colgada de un nodo que no es Control (una escena de prueba, una capa),
	## los anclajes no tienen rectángulo al que agarrarse y la pantalla quedaba
	## en 0×0: lista, fondo y ficha aplastados en la esquina. Entonces se ajusta
	## a la ventana a mano y la sigue al redimensionar.
	if not get_parent() is Control:
		set_anchors_preset(Control.PRESET_TOP_LEFT)
		_a_la_ventana()
		get_viewport().size_changed.connect(_a_la_ventana)
	_modos = leer_modos()
	_construir()
	_preseleccionar()
	_reloj_logo = Timer.new()
	_reloj_logo.one_shot = true
	_reloj_logo.wait_time = SEG_LOGO
	_reloj_logo.timeout.connect(_mostrar_logo)
	add_child(_reloj_logo)
	_reloj_logo.start()
	resized.connect(func() -> void:
		if is_instance_valid(_bokeh):
			_bokeh.ajustar_area(size))

func _a_la_ventana() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size

## Los modos en el orden del menú: por secciones (`MODO_SECCIONES`) y, dentro,
## en el de `MODOS_JUEGO`. Cada uno lleva su sección en `_sec`/`_sec_desc`.
## Un modo de una categoría sin sección no se pierde: va al final.
static func leer_modos() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	var modos: Variant = Datos.tabla("MODOS_JUEGO")
	if not modos is Array:
		return salida
	var secciones: Variant = Datos.tabla("MODO_SECCIONES")
	var orden: Array = secciones if secciones is Array else []
	var todos: Array = modos
	var vistos := {}
	for fila: Array in orden:
		for m: Dictionary in todos:
			if String(m.get("cat", "")) == String(fila[0]):
				var d := m.duplicate()
				d["_sec"] = String(fila[1])
				d["_sec_desc"] = String(fila[2])
				salida.append(d)
				vistos[String(m.get("id", ""))] = true
	for m: Dictionary in todos:
		if not vistos.has(String(m.get("id", ""))):
			salida.append(m.duplicate())
	return salida

# --- consultas (pruebas y quien coordine la entrada) ---------------------------

func modo_seleccionado() -> String:
	return String(_modos[_sel].get("id", "")) if _sel >= 0 and _sel < _modos.size() else ""

func modos() -> Array[Dictionary]:
	return _modos

func botones() -> Array[Button]:
	return _botones

func fondo() -> MenuModosFondo:
	return _fondo

func logo() -> MenuModosLogo:
	return _logo

func reloj_logo() -> Timer:
	return _reloj_logo

func confirmacion() -> MenuModosConfirmar:
	return _confirmar

func ficha() -> MenuModosFicha:
	return _ficha

static func jugable(m: Dictionary) -> bool:
	return not CATS_SIN_JUGAR.has(String(m.get("cat", "")))

# --- selección ------------------------------------------------------------------

## El modo que mira el jugador: fondo, ficha, acento de la lista y luz de las
## partículas cambian a la vez. La primera vez, sin fundido ni sonido.
func seleccionar(i: int) -> void:
	if i < 0 or i >= _modos.size() or i == _sel:
		return
	var primera := _sel < 0
	_sel = i
	var m := _modos[i]
	_fondo.mostrar(m, primera)
	if is_instance_valid(_bokeh):
		_bokeh.tenir(MenuModosFondo.luz_de(m))
	_pintar_lista()
	_ficha.pintar(m, jugable(m), primera)
	if not primera:
		_sonar("menu_mover")

## Pulsar un modo (clic, Intro, A): se pide confirmación. Uno que todavía no
## se puede jugar lo dice en vez de fingir que lleva a algún sitio.
func elegir(i: int) -> void:
	if _hecho or i < 0 or i >= _modos.size() or _confirmar.abierto():
		return
	seleccionar(i)
	var m := _modos[i]
	if not jugable(m):
		_ficha.avisar(Idiomas.t("Todavía no se puede jugar. Está en la lista para cuando esté listo."))
		_sonar("error")
		return
	_sonar("abrir")
	_confirmar.abrir(Idiomas.t(String(m.get("titulo", ""))), Idiomas.t(String(m.get("sub", ""))),
		MenuModosFondo.luz_de(m))

func _confirmado() -> void:
	if _hecho or _sel < 0:
		return
	_hecho = true
	_sonar("menu_aceptar")
	terminado.emit({"modo": modo_seleccionado()})

func _cancelado() -> void:
	_sonar("menu_atras")
	if _sel >= 0 and _sel < _botones.size() and is_inside_tree():
		_botones[_sel].grab_focus()

func _volver() -> void:
	if _hecho:
		return
	_sonar("menu_atras")
	volver.emit()

func _mostrar_logo() -> void:
	if is_instance_valid(_logo) and not _logo.visible:
		_logo.aparecer()
		_sonar("menu_seccion")

func _preseleccionar() -> void:
	if _modos.is_empty():
		return
	var i := 0
	var pedido := String(_estado.get("modo", ""))
	for k in _modos.size():
		if String(_modos[k].get("id", "")) == pedido:
			i = k
			break
	if is_inside_tree() and _botones[i].is_visible_in_tree():
		_botones[i].grab_focus()
	seleccionar(i)

func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _confirmar.abierto():
			_confirmar.cancelar()
		else:
			_volver()
	elif (ev.is_action_pressed("ui_down") or ev.is_action_pressed("ui_up")) and not _confirmar.abierto():
		## Sin foco (se hizo clic en el fondo): las flechas o la cruceta lo
		## devuelven al modo que se estaba mirando.
		if get_viewport().gui_get_focus_owner() == null and _sel >= 0:
			get_viewport().set_input_as_handled()
			_botones[_sel].grab_focus()

func _notification(que: int) -> void:
	## El botón «atrás» de Android hace lo mismo que Esc o B.
	if que == NOTIFICATION_WM_GO_BACK_REQUEST and is_visible_in_tree():
		if _confirmar != null and _confirmar.abierto():
			_confirmar.cancelar()
		else:
			_volver()

## Con el mismo tope que `BotonFx` (los botones de aquí llevan «sin_sonido»).
func _sonar(nombre: String) -> void:
	if not is_inside_tree():
		return
	var s := get_tree().root.get_node_or_null("Sonido")
	if s != null and s.has_method("toca"):
		s.call("toca", nombre, 2)

# --- construcción -------------------------------------------------------------

func _construir() -> void:
	_fondo = MenuModosFondo.new()
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fondo)
	## Las luces desenfocadas de la portada, teñidas del color del modo.
	_bokeh = FondoParticulas.new("bokeh")
	_bokeh.ajustar_area(get_viewport_rect().size)
	add_child(_bokeh)

	var cab := VBoxContainer.new()
	cab.position = Vector2(48, 34)
	cab.add_theme_constant_override("separation", 2)
	cab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cab)
	var titulo := _etiqueta(30, Tema.TEXTO)
	titulo.text = Idiomas.t("ELIGE TU CAMINO")
	cab.add_child(titulo)
	var ayuda := _etiqueta(14, Tema.SUAVE)
	ayuda.text = Idiomas.t("Pasa por cada modo para verlo. Cuando lo tengas claro, elígelo.")
	cab.add_child(ayuda)

	var sc := ScrollContainer.new()
	sc.anchor_top = 0.0
	sc.anchor_bottom = 1.0
	sc.offset_left = 40
	sc.offset_right = 40 + ANCHO_LISTA
	## A 1280×720 lógicos caben los doce modos y sus cuatro secciones sin
	## barra de desplazamiento (si se suman modos, el scroll sigue al foco).
	sc.offset_top = 108
	sc.offset_bottom = -60
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	## El foco con teclado o mando arrastra el scroll hasta el botón.
	sc.follow_focus = true
	add_child(sc)
	_lista = VBoxContainer.new()
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista.add_theme_constant_override("separation", 3)
	sc.add_child(_lista)
	_construir_lista()

	_ficha = MenuModosFicha.new()
	_ficha.elegir_pulsado.connect(func() -> void: elegir(_sel))
	add_child(_ficha)
	_construir_pie()

	_logo = MenuModosLogo.new()
	_logo.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_logo.offset_left = -_logo.custom_minimum_size.x - 34
	_logo.offset_right = -34
	_logo.offset_top = 22
	_logo.offset_bottom = 22 + _logo.custom_minimum_size.y
	add_child(_logo)

	_confirmar = MenuModosConfirmar.new()
	_confirmar.aceptado.connect(_confirmado)
	_confirmar.cancelado.connect(_cancelado)
	add_child(_confirmar)

func _construir_lista() -> void:
	var sec_previa := "\u0000"
	for i in _modos.size():
		var m := _modos[i]
		var sec := String(m.get("_sec", ""))
		if sec != sec_previa and sec != "":
			var cab := _etiqueta(12, Tema.ORO)
			cab.text = Idiomas.t(sec).to_upper()
			cab.custom_minimum_size = Vector2(0, 24)
			cab.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			_lista.add_child(cab)
		sec_previa = sec
		var b := Button.new()
		b.text = Idiomas.t(String(m.get("titulo", "")))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 33)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.focus_mode = Control.FOCUS_ALL
		b.add_theme_font_size_override("font_size", 15)
		b.set_meta("sin_sonido", true)
		b.set_meta("modo", String(m.get("id", "")))
		if not jugable(m):
			b.modulate = Color(1, 1, 1, 0.55)
		b.focus_entered.connect(seleccionar.bind(i))
		## El ratón da el foco: así ratón, teclado y mando recorren lo mismo.
		b.mouse_entered.connect(func() -> void:
			if not _confirmar.abierto() and not _hecho:
				b.grab_focus())
		b.pressed.connect(elegir.bind(i))
		_lista.add_child(b)
		_botones.append(b)
	## La lista da la vuelta: de la última a la primera y al revés.
	if _botones.size() > 1:
		var primero := _botones[0]
		var ultimo := _botones[_botones.size() - 1]
		primero.focus_neighbor_top = primero.get_path_to(ultimo)
		ultimo.focus_neighbor_bottom = ultimo.get_path_to(primero)
	_pintar_lista()

## El acento de la lista sigue la luz del modo que se mira; el elegido conserva
## la marca aunque el ratón se vaya.
func _pintar_lista() -> void:
	var luz := MenuModosFondo.luz_de(_modos[_sel]) if _sel >= 0 else Tema.ACENTO
	for i in _botones.size():
		var b := _botones[i]
		var marcado := i == _sel
		for estado in ["normal", "hover", "pressed", "focus", "disabled"]:
			var e := StyleBoxFlat.new()
			e.set_corner_radius_all(Tema.RADIO)
			e.content_margin_left = 16
			e.content_margin_right = 12
			if estado == "focus":
				e.draw_center = false
			elif marcado:
				e.bg_color = Color(luz, 0.22)
				e.border_width_left = 4
				e.border_color = luz
			else:
				e.bg_color = Color(Tema.PANEL, 0.78 if estado == "normal" else 0.95)
				e.border_width_left = 4
				e.border_color = Color(1, 1, 1, 0.0 if estado == "normal" else 0.18)
			b.add_theme_stylebox_override(estado, e)
		var col := Color.WHITE if marcado else Tema.TEXTO
		for k in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
			b.add_theme_color_override(k, col)

func _construir_pie() -> void:
	var pie := HBoxContainer.new()
	pie.anchor_top = 1.0
	pie.anchor_bottom = 1.0
	pie.anchor_right = 1.0
	pie.offset_left = 40
	pie.offset_right = -56
	pie.offset_top = -58
	pie.offset_bottom = -18
	pie.add_theme_constant_override("separation", 18)
	add_child(pie)
	var atras := Button.new()
	atras.text = "← " + Idiomas.t("Volver")
	atras.flat = true
	atras.focus_mode = Control.FOCUS_NONE
	atras.add_theme_font_size_override("font_size", 15)
	atras.add_theme_color_override("font_color", Tema.SUAVE)
	atras.set_meta("sin_sonido", true)
	atras.pressed.connect(_volver)
	pie.add_child(atras)
	var hueco := Control.new()
	hueco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hueco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pie.add_child(hueco)
	## La chuleta de controles: lo que hace cada tecla con teclado y con mando.
	var ayuda := _etiqueta(13, Tema.SUAVE)
	ayuda.text = "%s   ·   %s   ·   %s" % [Idiomas.t("↑ ↓ cambiar de modo"),
		Idiomas.t("Intro / A: elegir"), Idiomas.t("Esc / B: volver")]
	ayuda.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pie.add_child(ayuda)

func _etiqueta(tam: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
