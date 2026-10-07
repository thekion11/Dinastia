extends Control
## LA MESA DEL REPRESENTANTE (fase 4): dos capturas, a mitad del regateo y
## con el trato cerrado.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_mesa_agente.tscn
var _ui: MesaAgenteUI
var _mesa: MesaAgente
var _n := 0

func _ready() -> void:
	var f := ColorRect.new()
	f.color = Color("101812")
	f.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(f)
	_mesa = MesaAgente.new({"tipo": "mejora", "agente": "R. Maldonado", "perfil": "tiburon", "pid": "j9"}, 0, 0.0, 4242)
	_mesa.regatear(_mesa.ofertas()[2])
	_ui = MesaAgenteUI.new(_mesa, func(_m: MesaAgente) -> void: pass)
	add_child(_ui)

func _process(_d: float) -> void:
	_n += 1
	if _n == 8:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/mesa_agente_1.png")
		_mesa.farol()
		if _mesa.estado == "abierta":
			_mesa.regatear(_mesa.ofertas()[0])
		if _mesa.estado == "abierta":
			_mesa.ceder()
		_ui._pintar()
	if _n == 16:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/mesa_agente_2.png")
		get_tree().quit()
