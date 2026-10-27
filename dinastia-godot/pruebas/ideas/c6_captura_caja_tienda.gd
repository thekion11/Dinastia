extends Node
## El panel del cajero (pieza B de §2.2h): teclado de PIN y menú. `herramientas/captura.sh res://pruebas/ideas/c6_captura_caja_tienda.tscn`
var _n := 0
var _panel: PanelTienda
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
	var al := func(it: Dictionary) -> String: return "%s por %d € (tarjeta)." % [it["nombre"], it["precio"]]
	var saldo := func() -> String: return "En el bolsillo: 35 EUR  ·  Cuenta: 4k EUR"
	_panel = PanelTienda.abrir(capa, "Tienda de la gasolinera", TiendaGasolinera.SURTIDO, al, saldo, Vector3.ZERO, null)

func _process(_d: float) -> void:
	_n += 1
	if _n == 4:
		_panel.comprar(TiendaGasolinera.SURTIDO[0])
	if _n == 10:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/caja_tienda.png")
		print("CAPTURA OK")
		get_tree().quit()
