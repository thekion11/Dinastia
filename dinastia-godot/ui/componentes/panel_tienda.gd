class_name PanelTienda
extends PanelContainer
## LA CAJA DE LA TIENDA (27-10-2026, pieza C de `PLAN_DEL_LUNES.md` §2.2h): una lista del surtido con su precio y un botón por artículo. No sabe cobrar: llama a
## `al_comprar(item) -> String` (en `VidaCiudad.comprar_surtido`: cartera, hambre y energía) y enseña el mensaje que devuelve, ya traducido. Se cierra sola si el DT se aleja.
const DISTANCIA_MAX := 6.0

signal cerrado

var al_comprar: Callable
var saldo_texto: Callable          ## () -> String: «Efectivo … · Cuenta …», se repinta tras cada compra
var surtido: Array = []
var cajero_pos := Vector3.ZERO
var jugador: Node3D
var _aviso := ""
var _caja := VBoxContainer.new()

static func abrir(capa: CanvasLayer, titulo: String, surtido_: Array, al_comprar_: Callable, saldo_: Callable, pos: Vector3, quien: Node3D) -> PanelTienda:
	var p := PanelTienda.new()
	p.surtido = surtido_
	p.al_comprar = al_comprar_
	p.saldo_texto = saldo_
	p.cajero_pos = pos
	p.jugador = quien
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.offset_left = -240
	p.offset_right = 240
	p.offset_top = -230
	p.offset_bottom = 230
	p.add_theme_stylebox_override("panel", CuadroDialogo.estilo_panel())
	p._caja.add_theme_constant_override("separation", 6)
	p.add_child(p._caja)
	p.set_meta("titulo", titulo)
	capa.add_child(p)
	p._pintar()
	return p

func _process(_d: float) -> void:
	if jugador != null and is_instance_valid(jugador) and jugador.global_position.distance_to(cajero_pos) > DISTANCIA_MAX:
		salir()

func salir() -> void:
	cerrado.emit()
	queue_free()

func comprar(item: Dictionary) -> void:
	_aviso = String(al_comprar.call(item))
	_pintar()

func _pintar() -> void:
	for h in _caja.get_children():
		h.queue_free()
	_caja.add_child(CuadroDialogo.placa("🛒 " + String(get_meta("titulo"))))
	var saldo := Label.new()
	saldo.text = String(saldo_texto.call()) if saldo_texto.is_valid() else ""
	saldo.add_theme_font_size_override("font_size", 17)
	_caja.add_child(saldo)
	if _aviso != "":
		var av := Label.new()
		av.text = _aviso
		av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		av.add_theme_font_size_override("font_size", 17)
		av.add_theme_color_override("font_color", Color(1.0, 0.8, 0.35))
		_caja.add_child(av)
	for it: Dictionary in surtido:
		var b := Button.new()
		b.text = "%s — %s" % [Idiomas.t(String(it["nombre"])), Eco.dinero_euros(float(it["precio"]))]
		b.pressed.connect(comprar.bind(it))
		_caja.add_child(b)
	var bs := Button.new()
	bs.text = Idiomas.t("Salir")
	bs.pressed.connect(salir)
	_caja.add_child(bs)
