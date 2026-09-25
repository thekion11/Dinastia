extends Node
## Prueba aislada del globo 3D -sin pasar por `principal.tscn`, que en esta
## sesión se puso lento/errático con el sorteo de copa disparándose solo
## durante los `_avanzar_semana()` de arranque de `captura.gd`. El globo no
## tiene nada que ver con eso: se verifica aparte, rápido y sin ruido.

var _n := 0
var _globo: Globo3D

func _ready() -> void:
	_globo = Globo3D.new()
	_globo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_globo)

func _process(_d: float) -> void:
	_n += 1
	if _n == 6:
		_globo.ir_a("AUS", true)
	if _n == 8:
		_guardar("res://pruebas/pantalla_globo_aus.png")
		_globo.ir_a("BRA", true)
	if _n == 10:
		_guardar("res://pruebas/pantalla_globo_bra.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
