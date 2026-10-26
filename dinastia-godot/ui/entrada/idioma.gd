class_name PantallaIdioma
extends "res://ui/entrada/idioma_p1.gd"
## [Capa 2/2 de `idioma.gd`] la lógica: foco, elección, confirmación, volver y sonido.
##
## LA PANTALLA DEL IDIOMA (fase 1 del MEGAPLAN, etapa 1 del flujo de entrada;
## 25-10-2026). La primera decisión del jugador, antes del menú de modos: en qué
## idioma va a jugar. Pantalla completa con estética propia (un cielo de noche
## con el borde de un planeta, `idioma_fondo.gdshader`) y los nueve idiomas de
## `Idiomas.NOMBRES` en tarjetas, cada uno con su nombre en su propia lengua y su
## bandera dibujada y ondeando (`BanderaIdioma`).
##
## QUÉ ENSEÑA MIENTRAS ELIGES. Toda la pantalla habla el idioma que tienes
## enfocado: el título, la vista previa con un saludo, cómo se verán los menús
## de verdad («Plantel», «Táctica»… sacados de la tabla del juego) y las ayudas
## de abajo. Así se ve el idioma ANTES de elegirlo, y quien no lee castellano
## encuentra el suyo sin entender nada de lo demás. El fondo se tiñe con los
## colores de la bandera enfocada.
##
## CÓMO SE MANEJA. Ratón (pasar = enfocar), teclado (flechas, Intro, Esc) y mando
## (cruceta o palanca, A, B): las tarjetas son botones y el foco de Godot ya sabe
## moverse entre ellos por su posición. Suena un tic al pasar por una tarjeta, un
## «abrir» al elegirla y un «aceptar» al confirmar. Antes de seguir pide
## CONFIRMACIÓN (`ConfirmacionIdioma`); al confirmar aplica el idioma
## (`Idiomas.idioma`) y emite `terminado({"idioma": código})`. Guardarlo en las
## preferencias es cosa del orquestador (`OrquestadorMundo.aplicar_idioma`).
##
## CONTRATO de las pantallas de entrada (ver `orquestador.gd`): `terminado`,
## `volver` y `configurar(estado)`; se crea con `Script.new()` y se configura
## antes de entrar al árbol. Del estado lee `idioma` (el que sale enfocado) y
## `puede_volver` (false = sin botón ni Esc para volver; por defecto, true).

signal terminado(datos: Dictionary)
signal volver()

## El último sonido pedido (las pruebas lo leen: sin audio en modo headless).
static var ultimo_sonido := ""
static var _ultimo_ms := {}

func configurar(estado: Dictionary) -> void:
	var c := String(estado.get("idioma", Idiomas.idioma))
	_inicial = c if Idiomas.NOMBRES.has(c) else "es"
	_puede_volver = bool(estado.get("puede_volver", true))
	if is_node_ready():
		if is_instance_valid(_boton_volver):
			_boton_volver.visible = _puede_volver
		enfocar(_inicial)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	BotonFx.activar(get_tree())
	preparar_mando()
	_actual = Idiomas.idioma if Idiomas.NOMBRES.has(Idiomas.idioma) else "es"
	if not Idiomas.NOMBRES.has(_inicial):
		_inicial = _actual
	_serif = _fuente_serif(600, false)
	_serif_cursiva = _fuente_serif(400, true)
	for c: String in Idiomas.NOMBRES:
		_textos[c] = _calcular_textos(c)
	_construir()
	_conectar()
	## El foco inicial no suena: el tic es para cuando el jugador se mueve.
	enfocar(_inicial, false)
	_listo = true

# --- API (también la usan las pruebas) -------------------------------------------

func codigos() -> Array:
	return Idiomas.NOMBRES.keys()

func codigo_enfocado() -> String:
	return _foco

func tarjeta(c: String) -> Button:
	return _tarjetas.get(c, null)

func confirmacion() -> ConfirmacionIdioma:
	return _confirmacion if is_instance_valid(_confirmacion) else null

func titulo_visible() -> String:
	return _lbl_titulo.text if _lbl_titulo != null else ""

func saludo_visible() -> String:
	return _lbl_saludo.text if _lbl_saludo != null else ""

## Los textos de la pantalla en el idioma `c` (ya traducidos).
func textos_de(c: String) -> Dictionary:
	return _textos.get(c, {})

## Enfoca un idioma: la vista previa, el título, las ayudas y el fondo pasan a él.
func enfocar(c: String, animar: bool = true) -> void:
	if not _textos.has(c) or c == _foco:
		return
	_foco = c
	var tx: Dictionary = _textos[c]
	_lbl_titulo.text = String(tx["titulo"])
	_lbl_vista.text = String(tx["vista"])
	_lbl_nombre.text = String((Idiomas.NOMBRES[c] as Array)[0])
	_lbl_etiqueta.text = String(ETIQUETAS.get(c, c.to_upper()))
	_lbl_saludo.text = String(tx["saludo"])
	_lbl_menus.text = String(tx["menus"])
	for h in _chips.get_children():
		_chips.remove_child(h)
		h.queue_free()
	for k in (tx["chips"] as Array).size():
		_chips.add_child(_chip(String((tx["chips"] as Array)[k]), k == 0))
	var p: Array = tx["pistas"]
	for k in _pistas.size():
		_pistas[k].text = String(p[k])
	if is_instance_valid(_boton_volver):
		_boton_volver.text = "‹  " + String(tx["volver"])
	_bandera_grande.poner(c)
	for k: String in _banderas:
		(_banderas[k] as BanderaIdioma).fuerza = 1.0 if k == c else 0.18
	var colores: Array = BanderaIdioma.COLORES.get(c, [Color.DARK_RED, Color.GOLD])
	if animar:
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_mat_fondo, "shader_parameter/tinte_a", colores[0], 0.6).set_trans(Tween.TRANS_SINE)
		tw.tween_property(_mat_fondo, "shader_parameter/tinte_b", colores[1], 0.6).set_trans(Tween.TRANS_SINE)
		for l: Control in [_lbl_titulo, _vista]:
			l.modulate.a = 0.35
			tw.tween_property(l, "modulate:a", 1.0, 0.22)
	else:
		_mat_fondo.set_shader_parameter("tinte_a", colores[0])
		_mat_fondo.set_shader_parameter("tinte_b", colores[1])
	var b: Button = _tarjetas.get(c, null)
	if b != null and b.is_inside_tree() and not b.has_focus() and confirmacion() == null:
		_foco_callado(b)

## Abre la confirmación del idioma `c` (lo que hace pulsar una tarjeta).
func elegir(c: String) -> void:
	if not _textos.has(c) or _cerrando or confirmacion() != null:
		return
	enfocar(c)
	_sonar("abrir")
	_confirmacion = ConfirmacionIdioma.new()
	_confirmacion.preparar(c, _textos[c], {} if c == _actual else _textos[_actual], _serif)
	## Mientras se pregunta, las tarjetas no se pueden enfocar (el mando no se
	## escapa por detrás del cuadro).
	for t: Button in _tarjetas.values():
		t.focus_mode = Control.FOCUS_NONE
	if is_instance_valid(_boton_volver):
		_boton_volver.focus_mode = Control.FOCUS_NONE
	add_child(_confirmacion)
	_con_sonido(_confirmacion.boton_si)
	_con_sonido(_confirmacion.boton_otro)
	_confirmacion.aceptado.connect(_al_aceptar)
	_confirmacion.cancelado.connect(_al_cancelar)

# --- confirmar y volver ------------------------------------------------------------

func _al_aceptar(c: String) -> void:
	if _cerrando:
		return
	_cerrando = true
	Idiomas.idioma = c
	_sonar("menu_aceptar")
	var datos := {"idioma": c}
	if duracion_salida <= 0.0:
		_limpiar_confirmacion()
		terminado.emit(datos)
		return
	var tw := create_tween().set_parallel(true)
	if confirmacion() != null:
		tw.tween_property(_confirmacion, "modulate:a", 0.0, duracion_salida * 0.7)
	var b: Button = _tarjetas[c]
	b.pivot_offset = b.size * 0.5
	tw.tween_property(b, "scale", Vector2(1.06, 1.06), duracion_salida * 0.5).set_trans(Tween.TRANS_SINE)
	tw.chain().tween_property(b, "scale", Vector2.ONE, duracion_salida * 0.5).set_trans(Tween.TRANS_SINE)
	tw.chain().tween_callback(func() -> void:
		_limpiar_confirmacion()
		terminado.emit(datos))

func _limpiar_confirmacion() -> void:
	if confirmacion() != null:
		_confirmacion.queue_free()
	_confirmacion = null

func _al_cancelar() -> void:
	_sonar("menu_atras")
	_confirmacion = null
	for t: Button in _tarjetas.values():
		t.focus_mode = Control.FOCUS_ALL
	if is_instance_valid(_boton_volver):
		_boton_volver.focus_mode = Control.FOCUS_ALL
	var b: Button = _tarjetas.get(_foco, null)
	if b != null:
		_foco_callado(b)

func _pedir_volver() -> void:
	if not _puede_volver or _cerrando or confirmacion() != null:
		return
	_sonar("menu_atras")
	volver.emit()

func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel") and confirmacion() == null:
		get_viewport().set_input_as_handled()
		_pedir_volver()

func _notification(que: int) -> void:
	if que == NOTIFICATION_RESIZED and _mat_fondo != null and size.y > 0.0:
		_mat_fondo.set_shader_parameter("aspecto", Vector2(size.x / size.y, 1.0))

## EL MANDO EN LA ENTRADA (encontrado por la prueba, 25-10-2026). Godot no trae la
## A ni la B del mando en `ui_accept`/`ui_cancel`, y `Principal._preparar_mando`
## las añade… pero Principal aún no existe en la entrada al juego: con mando se
## podía mover el foco por las tarjetas y no elegir. Se añaden aquí igual que allí
## (A, B, cruceta y stick izquierdo); sin duplicar si ya están.
static func preparar_mando() -> void:
	for par: Array in [["ui_accept", JOY_BUTTON_A], ["ui_cancel", JOY_BUTTON_B], ["ui_up", JOY_BUTTON_DPAD_UP],
			["ui_down", JOY_BUTTON_DPAD_DOWN], ["ui_left", JOY_BUTTON_DPAD_LEFT], ["ui_right", JOY_BUTTON_DPAD_RIGHT]]:
		var accion := String(par[0])
		if not InputMap.has_action(accion):
			InputMap.add_action(accion)
		var ev := InputEventJoypadButton.new()
		ev.button_index = par[1]
		if not InputMap.action_has_event(accion, ev):
			InputMap.action_add_event(accion, ev)
	for eje: Array in [["ui_up", JOY_AXIS_LEFT_Y, -1.0], ["ui_down", JOY_AXIS_LEFT_Y, 1.0],
			["ui_left", JOY_AXIS_LEFT_X, -1.0], ["ui_right", JOY_AXIS_LEFT_X, 1.0]]:
		var em := InputEventJoypadMotion.new()
		em.axis = eje[1]
		em.axis_value = eje[2]
		if not InputMap.action_has_event(String(eje[0]), em):
			InputMap.action_add_event(String(eje[0]), em)

# --- sonido --------------------------------------------------------------------------

## Como `BotonFx._sonar`, con tope de 60 ms por sonido (pasar el ratón deprisa
## por la rejilla no hace una ráfaga). Las tarjetas llevan «sin_sonido» para que
## BotonFx no suene además: aquí cada gesto tiene el suyo.
func _sonar(nombre: String) -> void:
	var ahora := Time.get_ticks_msec()
	if ahora - int(_ultimo_ms.get(nombre, -1000)) < 60:
		return
	_ultimo_ms[nombre] = ahora
	ultimo_sonido = nombre
	var s := get_node_or_null("/root/Sonido")
	if s != null and s.has_method("toca"):
		s.call("toca", nombre, 2)

## Un foco puesto por código (abrir, cerrar el cuadro, `enfocar`) no suena: solo
## suena lo que hace el jugador, y así no se pisa con «abrir» o «menu_atras».
func _foco_callado(b: Control) -> void:
	var antes := _listo
	_listo = false
	b.grab_focus()
	_listo = antes

func _con_sonido(b: BaseButton) -> void:
	b.focus_entered.connect(func() -> void:
		if _listo:
			_sonar("clic_suave"))
	b.mouse_entered.connect(func() -> void:
		if b.focus_mode != Control.FOCUS_NONE and not b.has_focus():
			b.grab_focus())

## Las tarjetas y el botón de volver, ya construidos, se enganchan aquí.
func _conectar() -> void:
	for c: String in _tarjetas:
		var b: Button = _tarjetas[c]
		b.focus_entered.connect(func() -> void:
			enfocar(c)
			if _listo:
				_sonar("clic_suave"))
		b.mouse_entered.connect(func() -> void:
			if b.focus_mode != Control.FOCUS_NONE and not b.has_focus():
				b.grab_focus())
		b.pressed.connect(elegir.bind(c))
	_boton_volver.pressed.connect(_pedir_volver)
	_con_sonido(_boton_volver)
