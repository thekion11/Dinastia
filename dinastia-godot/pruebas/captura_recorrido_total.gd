extends Node
## RECORRIDO TOTAL DE LA INTERFAZ (etapa 1, segunda pasada, 8-10-2026): la
## pantalla principal, los 9 menús laterales y TODAS las pestañas, en hojas de
## seis (`pruebas/capturas/recorrido_N.png`) para revisarlas una a una.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_recorrido_total.tscn
var _t := 0.0
var _p: Node
var _cola: Array = []
var _fotos: Array = []   ## [nombre, Image]
var _i := 0
var _pend := ""

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _armar_cola() -> void:
	_cola.append(["principal", func() -> void: pass])
	for id: String in ["historia", "gente", "carrera", "operaciones", "vida", "editar", "ajustes", "ciudad", "estadio"]:
		_cola.append(["menu_" + id, func() -> void:
			var ml: MenuLateral = _p.get("_menu_lateral")
			ml.abrir_menu(id, -1)])
	_cola.append(["cerrar_menus", func() -> void:
		var ml: MenuLateral = _p.get("_menu_lateral")
		for h in _p.get_tree().root.find_children("*", "PantallaMenu", true, false):
			(h as Node).queue_free()])
	var pest: TabContainer = _p.get("_pestanas")
	for i in pest.get_tab_count():
		var titulo := pest.get_tab_title(i)
		_cola.append(["tab_" + titulo, func() -> void: _p.call("_ir_a_pestana", titulo)])

func _process(d: float) -> void:
	_t += d
	if _cola.is_empty() and _i == 0:
		if _t < 2.0:
			return
		_armar_cola()
		_t = 0.0
	if _t < 1.2:
		return
	_t = 0.0
	if _pend != "":
		var img := get_viewport().get_texture().get_image()
		img.resize(800, 450)
		if _pend != "cerrar_menus":
			_fotos.append([_pend, img])
		print("FOTO ", _pend)
		_pend = ""
	if _i >= _cola.size():
		_hojas()
		get_tree().quit()
		return
	var paso: Array = _cola[_i]
	_i += 1
	(paso[1] as Callable).call()
	_pend = String(paso[0])

func _hojas() -> void:
	var n := 0
	for k in range(0, _fotos.size(), 6):
		var hoja := Image.create(800 * 3, 450 * 2, false, Image.FORMAT_RGBA8)
		for j in range(k, mini(k + 6, _fotos.size())):
			var img: Image = _fotos[j][1]
			img.convert(Image.FORMAT_RGBA8)
			hoja.blit_rect(img, Rect2i(0, 0, 800, 450), Vector2i(((j - k) % 3) * 800, ((j - k) / 3) * 450))
		n += 1
		hoja.save_png("res://pruebas/capturas/recorrido_%d.png" % n)
		var nombres := []
		for j in range(k, mini(k + 6, _fotos.size())):
			nombres.append(_fotos[j][0])
		print("HOJA ", n, " ", nombres)
