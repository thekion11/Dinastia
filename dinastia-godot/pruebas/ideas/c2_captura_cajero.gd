extends Node
## El panel del cajero (pieza B de §2.2h): teclado de PIN y menú. `herramientas/captura.sh res://pruebas/ideas/c2_captura_cajero.tscn`
var _n := 0
var _p: PanelCajero
var _m: Mundo
var _r: Roles

func _ready() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0.08, 0.1, 0.14)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var capa := CanvasLayer.new()
	add_child(capa)
	_m = Mundo.new()
	_r = Roles.new(_m)
	_r.patrimonio = 400
	_r.cartera.efectivo = 35
	_p = PanelCajero.abrir(capa, _r.cartera, _r, 1, "Caja Costera", 2, Vector3.ZERO, null)
	_p._tecla("0")
	_p._tecla("0")

func _process(_d: float) -> void:
	_n += 1
	if _n == 6:
		_foto("pin")
		_p._tecla("0")
		_p._tecla("0")
	if _n == 12:
		_foto("menu")
		get_tree().quit()

func _foto(nombre: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/cajero_%s.png" % nombre)
	print("CAPTURA OK ", nombre)
