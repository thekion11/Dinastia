class_name PantallaMenu
extends Control
## UN MENÚ ENTERO, A PANTALLA COMPLETA (29-9-2026, mapa de metas 23). Pedido del usuario: *"las cosas más importantes deben
## tener su propio menú y no estar incrustadas en un mini menú sobre el menú central"*, con fondo animado, como en Soccer Manager.
##
## DOS ESTADOS: PORTADA (título grande y una tarjeta por submenú con su icono, qué hay y un dato vivo: «3 sin leer») y
## DETALLE (los submenús como pestañas arriba y el contenido en el centro; la ficha al lado solo en Plantel).
## No hay una segunda copia de cada pantalla: el contenido de verdad -el `TabContainer` de la principal y la columna de la
## ficha- se MUDA aquí mientras está en detalle y vuelve a su sitio al salir: todo lo que ya funcionaba sigue.

signal cerrada

const SHADER := preload("res://ui/fondo_menu.gdshader")

var _p: Principal
var _menu: Dictionary
var _fondo: ColorRect
var _raiz: VBoxContainer
var _cuerpo: Control
var _pestanas_sub: HBoxContainer
var _titulo_sub: Label
var _btn_portada: Button
var _hueco_contenido: PanelContainer
var _hueco_ficha: Control
var _devolver: Array = []   ## [nodo, padre, índice, flags h, ratio]
var _activo := -1
var _cerrando := false
## (10-11, auditoría de gestión en el móvil) LA CABECERA COMPACTA: en el teléfono en horizontal (480 px lógicos de alto) la cabecera grande y el
## botón «Portada» se comían ~40 % del alto y lo que se trabaja quedaba en ~200 px. En una sola línea: volver, icono, título y sección, «Portada»
## y el club. Solo en lo táctil (`EscalaMovil.es_tactil`) y si no se apaga en Ajustes («Cabecera compacta en el móvil»); en PC, como siempre.
static var compacta_pref := true
static var compacta_pc := false   ## (10-11) también en PC, como opción de Ajustes (apagada por defecto)
static func compacta() -> bool:
	return compacta_pref if EscalaMovil.es_tactil() else compacta_pc

static func abrir(p: Principal, menu: Dictionary, sub: int = -1) -> PantallaMenu:
	var n := PantallaMenu.new()
	n._p = p
	n._menu = menu
	n.name = "PantallaMenu"
	n.set_meta("id", String(menu["id"]))
	n.set_anchors_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	p.add_child(n)
	FocoMando.aislar(n)   ## (10-11) con el menú encima, la cruceta no se va a lo de detrás
	n._montar()
	if sub >= 0:
		n.elegir(sub)
	else:
		n.portada()
	FocoMando.enfocar.call_deferred(n)
	return n

func _exit_tree() -> void:
	FocoMando.liberar(self)

func _color(i: int) -> Color:
	return Color(String((_menu["colores"] as Array)[i]))

func _montar() -> void:
	_fondo = ColorRect.new()
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("estilo", int(_menu["estilo"]))
	mat.set_shader_parameter("c1", _color(0))
	mat.set_shader_parameter("c2", _color(1))
	mat.set_shader_parameter("c3", _color(2))
	## M-288 (20-10): con el motor ligero (gama baja), fondo de color fijo: el
	## shader usa TIME y obliga a redibujar la pantalla en cada fotograma.
	if AhorroMenu.fondo_estatico():
		_fondo.color = _color(1)
	else:
		_fondo.material = mat
	add_child(_fondo)
	resized.connect(_al_redimensionar)

	_raiz = VBoxContainer.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.offset_left = 22.0 + MenuLateral.ANCHO_RIEL
	_raiz.offset_right = -22
	var cmp := compacta()
	_raiz.offset_top = 6 if cmp else 16
	_raiz.offset_bottom = -6 if cmp else -16
	_raiz.add_theme_constant_override("separation", 6 if cmp else 12)
	add_child(_raiz)

	## LA CABECERA: volver, icono grande, el nombre del menú y dónde estás.
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 10 if cmp else 16)
	_raiz.add_child(cab if cmp else ProfundidadUI.banda(cab, _color(2)))   ## (10-11, estética) la cabecera en una banda con sombra y filo de color
	var volver := _boton_plano("◂  Volver", 14 if cmp else 16)
	volver.tooltip_text = Idiomas.t("Volver al menú central (Esc)")
	volver.custom_minimum_size = Vector2(0, 0) if cmp else Vector2(118, 44)
	volver.pressed.connect(cerrar)
	cab.add_child(volver)
	var icono := IconosUI.control(String(_menu["icono"]), 22 if cmp else 42)   ## (10-11) emoji o icono dibujado (Ajustes)
	if icono is Label:
		(icono as Label).vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cab.add_child(icono)
	var titulos := VBoxContainer.new()
	titulos.add_theme_constant_override("separation", -4)
	titulos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(titulos)
	var t := Label.new()
	t.text = String(_menu["nombre"]).to_upper()
	t.add_theme_font_size_override("font_size", 18 if cmp else 36)
	t.add_theme_color_override("font_color", _color(2).lightened(0.35))
	t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	t.add_theme_constant_override("shadow_offset_y", 3)
	t.add_theme_constant_override("shadow_outline_size", 6)   ## (10-11) sombra difusa: el título se despega del fondo
	titulos.add_child(t)
	_titulo_sub = Label.new()
	_titulo_sub.add_theme_font_size_override("font_size", 13 if cmp else 14)
	titulos.alignment = BoxContainer.ALIGNMENT_CENTER
	_titulo_sub.add_theme_color_override("font_color", Color(1, 1, 1, 0.72))
	titulos.add_child(_titulo_sub)
	if _p.mundo != null and _p.mundo.mi_club() != null:
		var club := Label.new()
		club.text = Nombres.visible(_p.mundo.mi_club().nombre) if cmp else "%s  ·  %s" % [Nombres.visible(_p.mundo.mi_club().nombre), _p.fecha_larga()]
		club.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		club.add_theme_font_size_override("font_size", 13)
		club.add_theme_color_override("font_color", Color(1, 1, 1, 0.65))
		cab.add_child(club)

	## LAS PESTAÑAS DE SUBMENÚ (solo en detalle).
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	if cmp:   ## en la misma línea que el título, antes del club
		cab.add_child(fila)
		cab.move_child(fila, titulos.get_index() + 1)
	else:
		_raiz.add_child(fila)
	_btn_portada = _boton_plano("◂  Portada: todos los apartados", 13 if cmp else 14)
	_btn_portada.custom_minimum_size = Vector2(0, 0 if cmp else 36)
	_btn_portada.pressed.connect(portada)
	fila.add_child(_btn_portada)
	## Sin carril de pestañas hacia la derecha (pedido del usuario al ver la
	## portada: "que sean así, grandes y hacia abajo"). Se vuelve a las
	## tarjetas con Portada; L1/R1 siguen pasando de submenú.
	var carril := ScrollContainer.new()
	carril.visible = false
	fila.add_child(carril)
	_pestanas_sub = HBoxContainer.new()
	_pestanas_sub.add_theme_constant_override("separation", 6)
	carril.add_child(_pestanas_sub)
	var subs: Array = _menu["subs"]
	for i in subs.size():
		_pestanas_sub.add_child(_pestana(subs[i], i))

	_cuerpo = Control.new()
	_cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_raiz.add_child(_cuerpo)
	## Estos menús no se repintan con la principal: se traducen aquí (el volver,
	## el título y las pestañas; el contenido de cada submenú lo traduce la
	## principal al repintar).
	Idiomas.traducir_arbol(cab)
	Idiomas.traducir_arbol(fila)

	## La entrada: desde la izquierda, que es de donde viene el panel.
	## Se anima el MARGEN y no `position`: tocar la posición de un control
	## anclado pisa su margen y el contenido acababa debajo del riel.
	modulate.a = 0.0
	var base := _raiz.offset_left
	_raiz.offset_left = base - 40.0
	var tw := create_tween().set_parallel(true)
	## (10-11, estética; PES 2020/eFootball pasan de pantalla en ~0,2 s) 0,25/0,3 → 0,18/0,22 s: la entrada se siente ágil, no lenta
	tw.tween_property(self, "modulate:a", 1.0, 0.18)
	tw.tween_property(_raiz, "offset_left", base, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	Sonido.toca("abrir" if Sonido.NOMBRES.has("abrir") else "clic", Sonido.Bus.INTERFAZ)
	_al_redimensionar()

func _boton_plano(texto: String, tam: int) -> Button:
	var b := Button.new()
	b.text = texto
	b.add_theme_font_size_override("font_size", tam)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0, 0, 0, 0.45)
	st.border_color = Color(1, 1, 1, 0.14)
	st.set_border_width_all(1)
	st.set_corner_radius_all(10)
	st.content_margin_left = 14
	st.content_margin_right = 14
	var enc := st.duplicate() as StyleBoxFlat
	enc.bg_color = Color(_color(2), 0.25)
	b.add_theme_stylebox_override("normal", st)
	b.add_theme_stylebox_override("hover", enc)
	b.add_theme_stylebox_override("focus", enc)
	b.add_theme_stylebox_override("pressed", enc)
	ProfundidadUI.boton(b)   ## (10-11, estética) relieve: sombra en reposo, se hunde al pulsar
	return b

func _pestana(sub: Dictionary, i: int) -> Button:
	var b := Button.new()
	b.text = "%s  %s" % [String(sub.get("icono", "")), String(sub["label"])]
	b.toggle_mode = not sub.has("accion")
	b.add_theme_font_size_override("font_size", 13)
	b.custom_minimum_size = Vector2(0, 36)
	var radio := 18
	var reposo := StyleBoxFlat.new()
	reposo.bg_color = Color(0, 0, 0, 0.42)
	reposo.border_color = Color(1, 1, 1, 0.12)
	reposo.set_border_width_all(1)
	reposo.set_corner_radius_all(radio)
	reposo.content_margin_left = 14
	reposo.content_margin_right = 14
	var encima := reposo.duplicate() as StyleBoxFlat
	encima.bg_color = Color(_color(2), 0.25)
	var activa := reposo.duplicate() as StyleBoxFlat
	activa.bg_color = _color(2).lightened(0.15)
	b.add_theme_stylebox_override("normal", reposo)
	b.add_theme_stylebox_override("hover", encima)
	b.add_theme_stylebox_override("focus", encima)
	b.add_theme_stylebox_override("pressed", activa)
	b.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	b.add_theme_color_override("font_pressed_color", _color(0))
	b.add_theme_color_override("font_hover_pressed_color", _color(0))
	b.pressed.connect(elegir.bind(i))
	return b

# ---------------------------------------------------------------- portada

## La portada: el lema del menú y una tarjeta grande por submenú.
var _ancho_tarjeta := 310.0   ## medidas de las tarjetas de la portada (las fija `portada()` según la ventana)
var _alto_tarjeta := 168.0

func portada() -> void:
	if _cerrando:
		return
	_devolver_contenido()
	_activo = -1
	_titulo_sub.text = Idiomas.t(String(_menu.get("lema", "")))
	_btn_portada.get_parent().visible = false
	for n in _cuerpo.get_children():
		_cuerpo.remove_child(n)
		n.queue_free()
	var sc := ScrollContainer.new()
	sc.set_anchors_preset(Control.PRESET_FULL_RECT)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_cuerpo.add_child(sc)
	## (9-11) Rejilla dinámica: columnas y ancho de tarjeta salen de la ventana (hasta 4), alineada arriba.
	var marco := MarginContainer.new()
	marco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	marco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	marco.add_theme_constant_override("margin_top", int(clampf(get_viewport_rect().size.y * 0.05, 12.0, 56.0)))
	sc.add_child(marco)
	var subs: Array = _menu["subs"]
	var rej := GridContainer.new()
	var ancho := get_viewport_rect().size.x - MenuLateral.ANCHO_RIEL - 60.0
	rej.columns = clampi(int((ancho + 18.0) / 358.0), 1, 4)
	if subs.size() <= 3:
		rej.columns = maxi(1, mini(subs.size(), rej.columns))
	for sep: String in ["h_separation", "v_separation"]:
		rej.add_theme_constant_override(sep, 18)
	rej.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	marco.add_child(rej)
	_ancho_tarjeta = clampf((ancho - 18.0 * float(rej.columns - 1)) / float(rej.columns), 300.0, 440.0)
	_alto_tarjeta = clampf(get_viewport_rect().size.y * 0.25, 176.0, 220.0)
	for i in subs.size():
		var tarjeta := TarjetaPortada.crear(self, subs[i], i)
		rej.add_child(tarjeta)
		Idiomas.traducir_arbol(tarjeta)
		## M-285 (2-11): con mando, la primera tarjeta toma el foco; la cruceta pasa de una a otra y A entra.
		if i == 0 and not Input.get_connected_joypads().is_empty():
			FocoSeguro.dar(tarjeta)
		## Entran escalonadas.
		tarjeta.modulate.a = 0.0
		var tw := tarjeta.create_tween()
		tw.tween_interval(0.05 * i)
		tw.tween_property(tarjeta, "modulate:a", 1.0, 0.25)

# ---------------------------------------------------------------- detalle

## Abre el submenú `i`: una sección (como los chips de siempre) o una acción (estadio 3D, casa, móvil...).
func elegir(i: int) -> void:
	## Una pantalla que ya se está cerrando no vuelve a coger el contenido: se
	## borraría con ella (estrés de menús, 17-10-2026).
	if _cerrando:
		return
	var subs: Array = _menu["subs"]
	if i < 0 or i >= subs.size():
		return
	var sub: Dictionary = subs[i]
	if sub.has("accion"):
		MenuLateral.ejecutar(_p, String(sub["accion"]))
		_marcar_pestana()
		return
	if _activo < 0:
		_montar_detalle()
	_activo = i
	_marcar_pestana()
	_titulo_sub.text = "%s  %s" % [String(sub.get("icono", "")), Idiomas.t(String(sub["label"]))]
	var antes: bool = _p._redirigiendo   ## la pestaña se cambia aquí dentro: que no se vuelva a elegir ni abra otro menú
	_p._redirigiendo = true
	_p._ir_a_chip(sub)
	_p._redirigiendo = antes
	_p._refrescar()
	if _hueco_contenido != null:
		_hueco_contenido.modulate.a = 0.35
		create_tween().tween_property(_hueco_contenido, "modulate:a", 1.0, 0.18)

func _marcar_pestana() -> void:
	for k in _pestanas_sub.get_child_count():
		(_pestanas_sub.get_child(k) as Button).set_pressed_no_signal(k == _activo)

func _montar_detalle() -> void:
	_btn_portada.get_parent().visible = true
	for n in _cuerpo.get_children():
		_cuerpo.remove_child(n)
		n.queue_free()
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.add_theme_constant_override("separation", 14)
	_cuerpo.add_child(h)
	_hueco_contenido = PanelContainer.new()
	_hueco_contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hueco_contenido.size_flags_stretch_ratio = 2.6
	var caja := StyleBoxFlat.new()
	caja.bg_color = Color(0.03, 0.04, 0.05, 0.74)
	caja.border_color = Color(_color(2), 0.45)
	caja.set_border_width_all(1)
	caja.border_width_top = 3
	caja.set_corner_radius_all(14)
	caja.content_margin_left = 12; caja.content_margin_right = 12
	caja.content_margin_top = 10; caja.content_margin_bottom = 10
	_hueco_contenido.add_theme_stylebox_override("panel", caja)
	h.add_child(_hueco_contenido)
	_hueco_ficha = null
	## Sin ficha del jugador en estos menús (pedido del usuario): el contenido ocupa todo el ancho.
	if bool(_menu.get("ficha", false)):
		_hueco_ficha = MarginContainer.new()
		_hueco_ficha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_hueco_ficha.size_flags_stretch_ratio = 1.3
		h.add_child(_hueco_ficha)
	_mudar(_p._marco_paginas, _hueco_contenido)
	if _hueco_ficha != null and _p._col_derecha != null:
		_mudar(_p._col_derecha, _hueco_ficha)
		_ver_ficha(true)

func submenu_activo() -> int:
	return _activo

## Pasa al submenú de al lado (L1/R1 del mando, o las flechas).
func submenu_vecino(paso: int) -> void:
	var subs: Array = _menu["subs"]
	var i := _activo
	for _k in subs.size():
		i = (i + paso + subs.size()) % subs.size()
		if not (subs[i] as Dictionary).has("accion"):
			break
	elegir(i)

func menu() -> Dictionary:   ## el menú que enseña (datos de `MenusLaterales`)
	return _menu

func cerrando() -> bool:
	return _cerrando

func _mudar(nodo: Control, a: Control) -> void:
	if _cerrando or nodo == null or nodo.get_parent() == null:
		return
	var padre := nodo.get_parent()
	_devolver.append([nodo, padre, nodo.get_index(), nodo.size_flags_horizontal, nodo.size_flags_stretch_ratio])
	padre.remove_child(nodo)
	a.add_child(nodo)
	nodo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nodo.size_flags_vertical = Control.SIZE_EXPAND_FILL

## Devuelve el contenido a su sitio en la pantalla principal.
func _devolver_contenido() -> void:
	for d: Array in _devolver:
		if not is_instance_valid(d[0]) or not is_instance_valid(d[1]):
			continue
		var nodo: Control = d[0]
		var padre: Node = d[1]
		if nodo.get_parent() != null:
			nodo.get_parent().remove_child(nodo)
		padre.add_child(nodo)
		padre.move_child(nodo, mini(int(d[2]), padre.get_child_count() - 1))
		nodo.size_flags_horizontal = int(d[3])
		nodo.size_flags_stretch_ratio = float(d[4])
	_devolver.clear()
	_ver_ficha(false)

## La ficha del jugador va oculta en el central (rediseño 3-11) y se ve aquí.
func _ver_ficha(si: bool) -> void:
	if _p._bloque_ficha != null and is_instance_valid(_p._bloque_ficha): _p._bloque_ficha.visible = si

func _al_redimensionar() -> void:
	if _fondo != null and _fondo.material != null and size.y > 0.0:
		(_fondo.material as ShaderMaterial).set_shader_parameter("aspecto", Vector2(size.x / size.y, 1.0))

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		## En detalle, Esc vuelve a la portada; en la portada, al menú central.
		if _activo >= 0:
			portada()
		else:
			cerrar()
		get_viewport().set_input_as_handled()

func cerrar() -> void:
	if _cerrando:
		return
	_cerrando = true
	FocoMando.liberar(self)
	_devolver_contenido()
	cerrada.emit()
	if is_inside_tree():
		_p._elegir_grupo("central")
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_callback(queue_free)
