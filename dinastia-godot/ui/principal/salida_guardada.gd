class_name SalidaGuardada
extends Node
## AL SALIR DEL JUEGO, ¿GUARDAR? (3-11-2026, rediseño del menú central, etapa 4). Cerrar la ventana, Alt+F4 y el botón «atrás» de Android pasan por aquí: con una partida en
## marcha se pregunta «¿Guardar antes de salir?» (Guardar y salir / Salir sin guardar / Cancelar); sin partida, se sale directamente. Mientras `Principal` existe el
## árbol no acepta el cierre solo (`auto_accept_quit = false`, `quit_on_go_back = false`); al salir de `Principal` se devuelve como estaba.
## En Android/iOS el sistema puede matar la aplicación al pasarla a segundo plano sin avisar: ahí se guarda en `NOTIFICATION_APPLICATION_PAUSED`.
## (El autoguardado de cada día, de cada semana y de cada partido está en `CicloPartida` + `GuardadoSegundoPlano`.)

var p: Principal
var _dialogo: ConfirmationDialog = null
var _acepta_antes := true
var _atras_antes := true
## Las pruebas lo ponen a false para comprobar el guardado sin cerrar el proceso.
static var salir_de_verdad := true

func _init(principal: Principal) -> void:
	p = principal
	name = "SalidaGuardada"

func _ready() -> void:
	_acepta_antes = get_tree().auto_accept_quit
	_atras_antes = get_tree().quit_on_go_back
	get_tree().auto_accept_quit = false
	get_tree().quit_on_go_back = false

func _exit_tree() -> void:
	var arbol := get_tree()
	if arbol != null:
		arbol.auto_accept_quit = _acepta_antes
		arbol.quit_on_go_back = _atras_antes

func _notification(que: int) -> void:
	match que:
		## (Diferido: mientras el árbol reparte la notificación `Principal` no deja colgarle hijos, y el diálogo es un hijo.)
		NOTIFICATION_WM_CLOSE_REQUEST:
			pedir_salir.call_deferred(false)
		## «Atrás» lo atiende `VidaGlobal` (cierra la ventana o vuelve; solo si nadie lo atiende llega aquí `pedir_salir(true)`) o el partido (`VidaApp`).
		NOTIFICATION_WM_GO_BACK_REQUEST:
			pass
		NOTIFICATION_APPLICATION_PAUSED:
			if p != null and p.mundo != null and OS.has_feature("mobile"):
				guardar_ya()

func hay_partida() -> bool:
	return p != null and is_instance_valid(p) and p.mundo != null and p.mundo.mi_club() != null

## Guardar a mano: espera al autoguardado en curso y escribe la ranura de siempre. Devuelve si salió bien.
func guardar_ya() -> bool:
	GuardadoSegundoPlano.esperar()
	return Partida.guardar(p.mundo, p._partida._ranura())

## `atras`: viene del botón «atrás» de Android (si el diálogo ya está abierto, lo cierra: es lo que espera el dedo).
func pedir_salir(atras: bool) -> void:
	if not hay_partida():
		_salir()
		return
	if _dialogo != null and _dialogo.visible:
		if atras:
			_dialogo.hide()
		return
	if _dialogo == null:
		_dialogo = ConfirmationDialog.new()
		_dialogo.name = "DialogoSalir"
		_dialogo.title = Idiomas.t("Salir del juego")
		_dialogo.dialog_text = Idiomas.t("¿Guardar antes de salir?")
		_dialogo.ok_button_text = Idiomas.t("Guardar y salir")
		_dialogo.cancel_button_text = Idiomas.t("Cancelar")
		_dialogo.add_button(Idiomas.t("Salir sin guardar"), true, "sin_guardar")
		_dialogo.confirmed.connect(guardar_y_salir)
		_dialogo.custom_action.connect(func(accion: StringName) -> void:
			if accion == &"sin_guardar":
				_dialogo.hide()
				_salir())
		p.add_child(_dialogo)
	_dialogo.popup_centered(Vector2i(520, 160))

func guardar_y_salir() -> void:
	if hay_partida() and not guardar_ya():
		push_warning("SalidaGuardada: no se pudo guardar al salir")
	_salir()

func _salir() -> void:
	GuardadoSegundoPlano.esperar()
	if salir_de_verdad:
		get_tree().quit()
