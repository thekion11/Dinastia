extends Node
## La máquina de peluches (`PanelPeluches`) en tres momentos: lista para jugar, la garra bajando y el premio cayendo. Sin la ciudad.
##   herramientas/captura.sh res://pruebas/captura_peluches.tscn → /tmp/peluches_N.png (CAPTURA_SALIDA cambia la carpeta)
var _n := 0
var _p: PanelPeluches
var _vistas := 0
var _estado := 0

func _ready() -> void:
	var capa := CanvasLayer.new()
	add_child(capa)
	var fondo := ColorRect.new()
	fondo.color = Color(0.12, 0.14, 0.2)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(fondo)
	var roles := Roles.new(Mundo.new())
	roles.cartera.efectivo = 20
	roles.peluches.conseguir("zorro")
	roles.peluches.conseguir("pollito")
	_p = PanelPeluches.abrir(capa, roles, 3, 0, Vector3.ZERO, null)
	_p._insertar()

func _guardar() -> void:
	var carpeta := OS.get_environment("CAPTURA_SALIDA") if OS.get_environment("CAPTURA_SALIDA") != "" else "/tmp"
	get_viewport().get_texture().get_image().save_png("%s/peluches_%d.png" % [carpeta, _vistas])
	_vistas += 1

func _process(_d: float) -> void:
	_n += 1
	if _estado == 0 and _n == 8:
		_guardar()
		var o: Dictionary = _p.campo[1]
		_p.garra = Vector2(float(o["x"]), float(o["y"]))
		_p.soltar()
		_estado = 1
	elif _estado == 1 and _p.fase == PanelPeluches.CIERRA:
		_guardar()
		_estado = 2
	elif _estado == 2 and _p.fase == PanelPeluches.SALE and _p._gana != "":
		_guardar()
		_estado = 3
	elif _estado == 2 and _p.fase == PanelPeluches.FIN and _p._gana == "":
		_p._insertar()
		var o2: Dictionary = _p.campo[0]
		_p.garra = Vector2(float(o2["x"]), float(o2["y"]))
		_p.soltar()
		_estado = 1
	elif _estado == 3 and _p.fase == PanelPeluches.FIN:
		_guardar()
		get_tree().quit()
	if _n > 900:
		get_tree().quit()
