class_name PanelPagoPin
extends PanelContainer
## EL PIN AL PAGAR (U6, 3-11): a partir de `CarteraDT.SIN_PIN` € la tarjeta no paga sin contacto y pide el PIN en el comercio (tienda, gasolinera, expendedora).
## Pinta el concepto y el importe con el teclado de `TecladoPin`; el PIN lo comprueba `CarteraDT.comprobar_pin` (tres fallos = tarjeta bloqueada, como en el cajero).
## Con el PIN bueno llama a `al_validar(pin)` y se cierra; el cargo lo hace quien lo abrió (`PagoCiudad`). Se cierra sola si el DT se aleja.
const DISTANCIA_MAX := 6.0

signal cerrado

var cartera: CarteraDT
var importe := 0
var concepto := ""
var al_validar: Callable
var pos := Vector3.ZERO
var jugador: Node3D
var _tecleado := ""
var _aviso := ""
var _caja := VBoxContainer.new()

static func abrir(capa: CanvasLayer, c: CarteraDT, importe_: int, concepto_: String, al_validar_: Callable, pos_: Vector3, quien: Node3D) -> PanelPagoPin:
	var p := PanelPagoPin.new()
	p.cartera = c
	p.importe = importe_
	p.concepto = concepto_
	p.al_validar = al_validar_
	p.pos = pos_
	p.jugador = quien
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
	if jugador != null and is_instance_valid(jugador) and jugador.global_position.distance_to(pos) > DISTANCIA_MAX:
		salir()

func salir() -> void:
	cerrado.emit()
	queue_free()

func _pintar() -> void:
	for h in _caja.get_children():
		h.queue_free()
	_caja.add_child(CuadroDialogo.placa("💳 %s · %s" % [Idiomas.t(concepto), Eco.dinero_euros(float(importe))]))
	if _aviso != "":
		var av := Label.new()
		av.text = _aviso
		av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		av.add_theme_font_size_override("font_size", 17)
		av.add_theme_color_override("font_color", Color(1.0, 0.8, 0.35))
		_caja.add_child(av)
	if cartera.bloqueada:
		var bs := Button.new()
		bs.text = Idiomas.t("Salir")
		bs.pressed.connect(salir)
		_caja.add_child(bs)
		return
	TecladoPin.pintar(_caja, Idiomas.t("Introduce tu PIN"), _tecleado, _tecla)

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
	match cartera.comprobar_pin(tec):
		"":
			var f := al_validar
			salir()
			f.call(tec)
			return
		"bloqueada":
			_aviso = Idiomas.t("Tarjeta bloqueada. Pasa por el banco para desbloquearla.")
		_:
			_aviso = Idiomas.t("PIN incorrecto. Te quedan %d intentos.") % cartera.intentos_restantes()
	_pintar()
