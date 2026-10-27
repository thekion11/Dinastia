class_name Principal
extends "res://ui/principal_p17.gd"
## [Capa 17/17 de `principal.gd`] _ready, _capa_modal_encima, _input, _pintar_identidad, _al_paso_nuevo, _portada_nueva

## Los hijos que ya estaban al terminar `_ready()` (el menú, el riel, el reloj…).
## Todo Control a pantalla completa que se añada DESPUÉS y pare el ratón es una
## capa modal (móvil, diseñador, diálogos): ver `_capa_modal_encima()`.
var _hijos_base: Dictionary = {}

func _ready() -> void:
	super()
	for h: Node in get_children():
		_hijos_base[h.get_instance_id()] = true

## ¿Hay una capa modal tapando el menú? Con el móvil u otro popup abierto, los
## gatillos y Ctrl+Q/E no deben cambiar la pestaña escondida detrás.
func _capa_modal_encima() -> bool:
	for h: Node in get_children():
		if _hijos_base.has(h.get_instance_id()) or not (h is Control):
			continue
		var c := h as Control
		if c.visible and not c.is_queued_for_deletion() \
				and c.mouse_filter == Control.MOUSE_FILTER_STOP \
				and c.anchor_left == 0.0 and c.anchor_top == 0.0 \
				and c.anchor_right == 1.0 and c.anchor_bottom == 1.0:
			return true
	return false

func _input(evento: InputEvent) -> void:
	## Con una capa modal encima, ni gatillos ni Ctrl+Q/E ni desliz tocan las
	## pestañas de detrás. No se consume el evento: Q y E sueltas también son
	## «pestaña» y hay campos de texto en el móvil donde hay que poder teclearlas.
	if _capa_modal_encima():
		_arrastre_x = 0.0
		_arrastre_y = 0.0
		return
	## CON EL PANEL LATERAL ENCIMA (mapa de metas 23) los mismos botones
	## navegan ESE menú y no el central de detrás: L1/R1 pasan de submenú,
	## L2/R2 de menú, y el desliz con el dedo no cambia páginas escondidas.
	if _menu_lateral != null and _menu_lateral.ocupado():
		var pm: PantallaMenu = _menu_lateral.pantalla_abierta if is_instance_valid(_menu_lateral.pantalla_abierta) else null
		if pm != null and evento.is_action_pressed("dinastia_tab_siguiente"):
			pm.submenu_vecino(1)
			get_viewport().set_input_as_handled()
		elif pm != null and evento.is_action_pressed("dinastia_tab_anterior"):
			pm.submenu_vecino(-1)
			get_viewport().set_input_as_handled()
		elif evento.is_action_pressed("dinastia_bloque_siguiente"):
			_menu_lateral.menu_vecino(1)
			get_viewport().set_input_as_handled()
		elif evento.is_action_pressed("dinastia_bloque_anterior"):
			_menu_lateral.menu_vecino(-1)
			get_viewport().set_input_as_handled()
		_arrastre_x = 0.0
		_arrastre_y = 0.0
		return
	## Un desliz que empieza sobre el riel es del panel (abrirlo), no del menú.
	if evento is InputEventScreenDrag and (evento as InputEventScreenDrag).position.x < MenuLateral.ANCHO_RIEL + 30.0:
		return
	## Los atajos del menú central (1-9, 0, N, F3, F5; s3).
	if AtajosCentrales.manejar(self, evento):
		get_viewport().set_input_as_handled()
		return
	## Los gatillos cambian de pestaña. Se mira aquí y no en `_unhandled_input`
	## porque los contenedores de la interfaz se comen los eventos de navegación
	## antes de que lleguen abajo.
	if evento.is_action_pressed("dinastia_tab_siguiente"):
		_saltar_pestana(1)
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("dinastia_tab_anterior"):
		_saltar_pestana(-1)
		get_viewport().set_input_as_handled()
	## L2/R2 y Ctrl+Q/E cambian de BLOQUE MAESTRO, no de chip: es el nivel de
	## arriba. NO son L1/R1 -esos ya los toma `dinastia_tab_siguiente`/
	## `anterior`, dos líneas más arriba, para el chip- porque un mismo botón
	## físico no puede disparar dos acciones a la vez: con L1/R1 aquí también,
	## esta rama nunca se habría alcanzado (quedó comprobado: era justo el bug
	## que tenía este bloque antes de corregirlo).
	elif evento.is_action_pressed("dinastia_bloque_siguiente"):
		_bloque_vecino(1)
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("dinastia_bloque_anterior"):
		_bloque_vecino(-1)
		get_viewport().set_input_as_handled()
	elif evento is InputEventKey and evento.pressed and not evento.echo:
		var k := evento as InputEventKey
		if k.keycode == KEY_E and k.ctrl_pressed:
			_bloque_vecino(1)
			get_viewport().set_input_as_handled()
		elif k.keycode == KEY_Q and k.ctrl_pressed:
			_bloque_vecino(-1)
			get_viewport().set_input_as_handled()
	## EL ARRASTRE CON EL DEDO (Android). Un desliz horizontal largo pasa de
	## bloque, como en FC26. El umbral de 90 px y el 1,6 de proporción están
	## para que un scroll vertical con el pulgar torcido no cambie de página
	## sin querer: tiene que ser un gesto claramente lateral.
	elif evento is InputEventScreenDrag:
		var dr := evento as InputEventScreenDrag
		_arrastre_x += dr.relative.x
		_arrastre_y += absf(dr.relative.y)
		if absf(_arrastre_x) > 90.0 and absf(_arrastre_x) > _arrastre_y * 1.6:
			_bloque_vecino(-1 if _arrastre_x > 0.0 else 1)
			_arrastre_x = 0.0
			_arrastre_y = 0.0
	elif evento is InputEventScreenTouch and not (evento as InputEventScreenTouch).pressed:
		_arrastre_x = 0.0
		_arrastre_y = 0.0

## Puente (fase 6, paso 6): la sección Identidad la pinta `PantallaIdentidad`.
func _pintar_identidad(c: Club) -> void: _ui_identidad._pintar_identidad(c)

func _al_paso_nuevo() -> void:
	if mundo == null or mundo.prensa == null or mundo.prensa.al_paso.is_empty():
		return
	## Si hay un periódico abierto (de esta semana o de otra que pasó de
	## corrido), la entrevista espera a que se cierre.
	for h in get_children():
		if h is PortadaPeriodico and not h.is_queued_for_deletion():
			if not h.cerrado.is_connected(_al_paso_nuevo):
				h.cerrado.connect(_al_paso_nuevo)
			return
	for h in get_children():
		if h is PieDeCampo and not h.is_queued_for_deletion():
			return
	var n := PieDeCampo.mostrar_al_paso(self, mundo.prensa)
	if n != null:
		n.cerrado.connect(_refrescar)

func _portada_nueva() -> void:
	if mundo == null or mundo.prensa == null or mundo.prensa.portadas.is_empty():
		_al_paso_nuevo()
		return
	var d: Dictionary = mundo.prensa.portadas[0]
	var nueva := bool(d.get("nueva", false))
	for x: Dictionary in mundo.prensa.portadas:
		x.erase("nueva")
	if nueva and PortadaPeriodico.auto():
		PortadaPeriodico.mostrar(self, mundo, d)
	_al_paso_nuevo()
