class_name PanelCajero
extends PanelContainer
## EL CAJERO AUTOMÁTICO (27-10-2026, pieza B de `PLAN_DEL_LUNES.md` §2.2h): un panel con teclado de PIN y, dentro, retirar (20/50/100/200 €), ingresar todo el
## efectivo y cambiar el PIN. Lo abre `VidaCiudad.usar_cajero` (E ante un `cajero_<n>`), se cierra solo si el DT se aleja o pulsa «Salir». Las reglas
## están en `CarteraDT` (límite de cajero, comisión de banco ajeno, bloqueo a los tres PIN malos); aquí solo se pinta y se teclea. Dinero en euros de pantalla.
const IMPORTES := [20, 50, 100, 200]
const DISTANCIA_MAX := 6.0

signal cerrado

var cartera: CarteraDT
var roles: Roles
var dia := 0
var banco := ""
var comision := 0                 ## € por retirar en un cajero de otro banco
var cajero_pos := Vector3.ZERO
var jugador: Node3D
var ventanilla := false           ## en la sucursal: sin PIN, desbloquea y restablece el PIN, enseña los movimientos y no da efectivo

var _estado := "pin"              ## pin | menu | pin_actual (cambiar PIN: el de ahora) | pin_nuevo
var _tecleado := ""
var _pin_valido := ""             ## el PIN que acaba de validarse (para las operaciones)
var _aviso := ""
var _caja := VBoxContainer.new()

static func abrir(capa: CanvasLayer, c: CarteraDT, r: Roles, dia_: int, banco_: String, comision_: int, pos: Vector3, quien: Node3D, ventanilla_ := false) -> PanelCajero:
	var p := PanelCajero.new()
	p.cartera = c
	p.roles = r
	p.dia = dia_
	p.banco = banco_
	p.comision = comision_
	p.cajero_pos = pos
	p.jugador = quien
	p.ventanilla = ventanilla_
	if ventanilla_:
		p._estado = "menu"
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.offset_left = -230
	p.offset_right = 230
	p.offset_top = -250
	p.offset_bottom = 250
	p.add_theme_stylebox_override("panel", CuadroDialogo.estilo_panel())
	p.add_child(p._caja)
	p._caja.add_theme_constant_override("separation", 6)
	capa.add_child(p)
	p._pintar()
	return p

func _process(_d: float) -> void:
	if jugador != null and is_instance_valid(jugador) and jugador.global_position.distance_to(cajero_pos) > DISTANCIA_MAX:
		salir()

func salir() -> void:
	cerrado.emit()
	queue_free()

func _euros(n: int) -> String:
	return Eco.dinero_euros(float(n))

func _pintar() -> void:
	for h in _caja.get_children():
		h.queue_free()
	_caja.add_child(CuadroDialogo.placa("🏧 " + banco))
	if _aviso != "":
		var av := Label.new()
		av.text = _aviso
		av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		av.add_theme_font_size_override("font_size", 17)
		av.add_theme_color_override("font_color", Color(1.0, 0.8, 0.35))
		_caja.add_child(av)
	if _estado == "menu":
		(_pintar_ventanilla() if ventanilla else _pintar_menu())
	else:
		_pintar_teclado()

func _pintar_teclado() -> void:
	var titulo := Label.new()
	match _estado:
		"pin_actual":
			titulo.text = Idiomas.t("Teclea tu PIN actual")
		"pin_nuevo":
			titulo.text = Idiomas.t("Teclea el PIN nuevo (4 cifras)")
		_:
			titulo.text = Idiomas.t("Introduce tu PIN")
	titulo.add_theme_font_size_override("font_size", 19)
	_caja.add_child(titulo)
	var pantalla := Label.new()
	pantalla.text = "•".repeat(_tecleado.length()) + "·".repeat(4 - _tecleado.length())
	pantalla.add_theme_font_size_override("font_size", 34)
	pantalla.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caja.add_child(pantalla)
	var rejilla := GridContainer.new()
	rejilla.columns = 3
	rejilla.add_theme_constant_override("h_separation", 6)
	rejilla.add_theme_constant_override("v_separation", 6)
	_caja.add_child(rejilla)
	for t in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "⌫", "0", "✕"]:
		var b := Button.new()
		b.text = t
		b.custom_minimum_size = Vector2(120, 54)
		b.add_theme_font_size_override("font_size", 24)
		b.pressed.connect(_tecla.bind(t))
		rejilla.add_child(b)

func _pintar_ventanilla() -> void:
	var saldos := Label.new()
	saldos.text = "%s: %s\n%s: %s" % [Idiomas.t("Cuenta"), _euros(cartera.cuenta_eur(roles)), Idiomas.t("En el bolsillo"), _euros(cartera.efectivo)]
	saldos.add_theme_font_size_override("font_size", 20)
	_caja.add_child(saldos)
	if cartera.bloqueada:
		var bd := Button.new()
		bd.text = Idiomas.t("Desbloquear la tarjeta")
		bd.pressed.connect(func() -> void:
			cartera.desbloquear()
			_aviso = Idiomas.t("Tarjeta desbloqueada.")
			_pintar())
		_caja.add_child(bd)
	var br := Button.new()
	br.text = Idiomas.t("Restablecer el PIN")
	br.pressed.connect(func() -> void:
		_estado = "pin_nuevo"
		_tecleado = ""
		_aviso = ""
		_pintar())
	_caja.add_child(br)
	var bi := Button.new()
	bi.text = Idiomas.t("Ingresar todo el efectivo (%s)") % _euros(cartera.efectivo)
	bi.disabled = cartera.efectivo <= 0
	bi.pressed.connect(ingresar_todo)
	_caja.add_child(bi)
	var cab := Label.new()
	cab.text = Idiomas.t("Últimos movimientos")
	cab.add_theme_font_size_override("font_size", 16)
	_caja.add_child(cab)
	var n := cartera.movimientos.size()
	for i in range(n - 1, maxi(-1, n - 6), -1):
		var mv: Dictionary = cartera.movimientos[i]
		var fila := Label.new()
		fila.text = "%s  %s" % [Idiomas.t(String(mv["concepto"])), _euros(int(mv["importe"]))]
		fila.add_theme_font_size_override("font_size", 15)
		_caja.add_child(fila)
	var bs := Button.new()
	bs.text = Idiomas.t("Salir")
	bs.pressed.connect(salir)
	_caja.add_child(bs)

func _pintar_menu() -> void:
	var saldos := Label.new()
	saldos.text = "%s: %s\n%s: %s" % [Idiomas.t("Cuenta"), _euros(cartera.cuenta_eur(roles)), Idiomas.t("En el bolsillo"), _euros(cartera.efectivo)]
	saldos.add_theme_font_size_override("font_size", 20)
	_caja.add_child(saldos)
	if comision > 0:
		var nota := Label.new()
		nota.text = Idiomas.t("Cajero de otro banco: comisión de %s por retirada.") % _euros(comision)
		nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nota.add_theme_font_size_override("font_size", 15)
		_caja.add_child(nota)
	for n: int in IMPORTES:
		var b := Button.new()
		b.text = Idiomas.t("Retirar %s") % _euros(n)
		b.pressed.connect(retirar.bind(n))
		_caja.add_child(b)
	var bi := Button.new()
	bi.text = Idiomas.t("Ingresar todo el efectivo (%s)") % _euros(cartera.efectivo)
	bi.disabled = cartera.efectivo <= 0
	bi.pressed.connect(ingresar_todo)
	_caja.add_child(bi)
	var bp := Button.new()
	bp.text = Idiomas.t("Cambiar el PIN")
	bp.pressed.connect(func() -> void:
		_estado = "pin_actual"
		_tecleado = ""
		_aviso = ""
		_pintar())
	_caja.add_child(bp)
	var bs := Button.new()
	bs.text = Idiomas.t("Salir")
	bs.pressed.connect(salir)
	_caja.add_child(bs)

func _tecla(t: String) -> void:
	if t == "✕":
		salir()
		return
	if t == "⌫":
		_tecleado = _tecleado.substr(0, maxi(0, _tecleado.length() - 1))
	elif _tecleado.length() < 4:
		_tecleado += t
	if _tecleado.length() == 4:
		_validar()
	else:
		_pintar()

func _validar() -> void:
	var tec := _tecleado
	_tecleado = ""
	match _estado:
		"pin":
			var r := cartera.comprobar_pin(tec)
			if r == "":
				_pin_valido = tec
				_estado = "menu"
				_aviso = Idiomas.t("PIN correcto.") + (" " + Idiomas.t("Sigue siendo el de fábrica: cámbialo.") if cartera.pin_inicial else "")
			elif r == "bloqueada":
				_aviso = Idiomas.t("Tarjeta bloqueada. Pasa por el banco para desbloquearla.")
			else:
				_aviso = Idiomas.t("PIN incorrecto. Te quedan %d intentos.") % cartera.intentos_restantes()
		"pin_actual":
			if cartera.comprobar_pin(tec) == "":
				_pin_valido = tec
				_estado = "pin_nuevo"
				_aviso = ""
			else:
				_estado = "menu" if not cartera.bloqueada else "pin"
				_aviso = Idiomas.t("PIN incorrecto.") if not cartera.bloqueada else Idiomas.t("Tarjeta bloqueada. Pasa por el banco para desbloquearla.")
		"pin_nuevo":
			if (cartera.restablecer_pin(tec) if ventanilla else cartera.cambiar_pin(_pin_valido, tec)) == "":
				_pin_valido = tec
				_aviso = Idiomas.t("PIN restablecido.") if ventanilla else Idiomas.t("PIN cambiado.")
			else:
				_aviso = Idiomas.t("No se pudo cambiar el PIN.")
			_estado = "menu"
	_pintar()

func retirar(importe: int) -> void:
	match cartera.retirar(roles, importe, _pin_valido, dia, comision):
		"":
			_aviso = Idiomas.t("Retiras %s.") % _euros(importe)
		"limite":
			_aviso = Idiomas.t("Has llegado al límite de retirada de hoy.")
		"saldo":
			_aviso = Idiomas.t("No hay saldo suficiente en la cuenta.")
		"bloqueada":
			_aviso = Idiomas.t("Tarjeta bloqueada. Pasa por el banco para desbloquearla.")
		_:
			_aviso = Idiomas.t("No se pudo retirar.")
	_pintar()

func ingresar_todo() -> void:
	var n := cartera.efectivo
	if cartera.ingresar(roles, n, dia) == "":
		_aviso = Idiomas.t("Ingresas %s.") % _euros(n)
	else:
		_aviso = Idiomas.t("No tienes efectivo que ingresar.")
	_pintar()
