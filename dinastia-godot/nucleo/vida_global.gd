extends Node
## (Sin `class_name`: autoload `VidaGlobal`.) LA VIDA DE LA APP FUERA DEL PARTIDO (caza de fallos, 4-11-2026, orden de la líder). `VidaApp` cuida los partidos; esto cuida TODO lo demás
## (la ciudad 3D andando, en el metro o en un interior, el menú de gestión con ventanas abiertas, el prólogo, el tutorial):
##   · segundo plano / llamada / pantalla bloqueada (solo en móvil): el ÁRBOL se pausa (no corren el reloj de la ciudad, el tráfico, la música ni los temporizadores) y se sueltan las
##     entradas; al volver se reanuda tras dos fotogramas (el primero trae el tiempo que estuvo fuera y se lo comería). Con un partido abierto lo atiende el partido (su pausa es una decisión);
##   · «atrás» de Android en CUALQUIER pantalla: cierra la ventana modal que esté abierta; si no, manda un Escape (todas las pantallas lo atienden: cierran su ventana o vuelven); si nadie lo
##     atiende, pregunta antes de salir (nunca sale solo: `quit_on_go_back = false`);
##   · poca memoria del sistema: calidad mínima al momento.
static var forzar_movil := false   ## (pruebas) hacerse pasar por un teléfono
var _pausado_por_mi := false
var esperando_escape := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().quit_on_go_back = false

func _es_movil() -> bool:
	return forzar_movil or OS.has_feature("mobile")

func hay_partido() -> bool:
	return get_tree().root.find_child("VidaApp", true, false) != null

func _notification(que: int) -> void:
	match que:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			if _es_movil():
				Musica.en_segundo_plano(true)   ## la música se calla donde está (también con un partido abierto)
				if not hay_partido():
					pausar_arbol()
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_WM_WINDOW_FOCUS_IN:
			Musica.en_segundo_plano(false)
			reanudar_arbol()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			atras.call_deferred()
		NOTIFICATION_OS_MEMORY_WARNING:
			Calidad.elegida = Calidad.MINIMO
			Calidad.aplicar_viewport(get_viewport(), Calidad.MINIMO)

func pausar_arbol() -> void:
	soltar_entradas()
	if _pausado_por_mi or get_tree().paused:
		return
	_pausado_por_mi = true
	get_tree().paused = true

func reanudar_arbol() -> void:
	if not _pausado_por_mi:
		return
	_pausado_por_mi = false
	await get_tree().process_frame   ## el primer fotograma de la vuelta trae el tiempo que estuvo fuera
	await get_tree().process_frame
	if not _pausado_por_mi:
		get_tree().paused = false

func soltar_entradas() -> void:
	for a: StringName in InputMap.get_actions():
		Input.action_release(a)

## El «atrás»: (1) la ventana modal abierta, (2) un Escape que cada pantalla atiende a su manera, (3) si nadie lo atiende, la pregunta de salir.
func atras() -> void:
	if hay_partido():
		return   ## el partido tiene su `VidaApp`
	for w in get_tree().root.find_children("*", "Window", true, false):
		if (w as Window).visible and w != get_tree().root and (w is Popup or w is AcceptDialog):
			(w as Window).hide()
			return
	esperando_escape = true
	for pulsa in [true, false]:
		var e := InputEventKey.new()
		e.keycode = KEY_ESCAPE
		e.physical_keycode = KEY_ESCAPE
		e.pressed = pulsa
		e.set_meta("vida_global", true)
		Input.parse_input_event(e)
	await get_tree().process_frame
	await get_tree().process_frame
	esperando_escape = false

## Un Escape SINTÉTICO que llega hasta aquí (el último en la cadena de «sin atender») no lo atendió nadie: se pregunta antes de salir.
func _unhandled_input(ev: InputEvent) -> void:
	if not (ev is InputEventKey) or not ev.has_meta("vida_global") or not (ev as InputEventKey).pressed:
		return
	esperando_escape = false
	var s := get_tree().root.find_child("SalidaGuardada", true, false)
	if s != null:
		s.pedir_salir(true)
		return
	var d := ConfirmationDialog.new()
	d.title = Idiomas.t("Salir del juego")
	d.dialog_text = Idiomas.t("¿Salir del juego?")
	d.ok_button_text = Idiomas.t("Salir sin guardar")
	d.cancel_button_text = Idiomas.t("Cancelar")
	d.confirmed.connect(func() -> void: get_tree().quit())
	d.canceled.connect(d.queue_free)
	get_tree().root.add_child(d)
	d.popup_centered(Vector2i(520, 160))
