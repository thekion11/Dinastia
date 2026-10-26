extends Node
## Capturas del MENÚ INICIAL DE MODOS (fase 1, etapa 2) en Forward+, con el ratón de verdad
## (eventos de movimiento, no llamadas directas): el fondo de «Director Técnico» bajo el cursor,
## el fundido a mitad camino hacia «Dueño de Club», el de Dueño ya con el logo, y la
## confirmación de «Director de Cantera».
##   herramientas/captura.sh res://pruebas/captura_f1m_modos.tscn

var _p: PantallaModos

func _ready() -> void:
	_p = PantallaModos.new()
	_p.configurar({"modo": "dt"})
	add_child(_p)
	_guion()

func _guion() -> void:
	await _esperar(2.0)
	_raton_a("dt")
	await _esperar(1.6)
	await _guardar("f1m_1_dt")
	_raton_a("imperio")
	await _esperar(0.2)
	await _guardar("f1m_2_fundido")
	await _esperar(1.6)
	_p.call("_mostrar_logo")
	await _esperar(3.4)
	await _guardar("f1m_3_imperio_logo")
	_raton_a("cantera")
	await _esperar(1.6)
	_p.elegir(_indice("cantera"))
	await _esperar(0.7)
	await _guardar("f1m_4_confirmar")
	get_tree().quit()

func _esperar(s: float) -> void:
	await get_tree().create_timer(s).timeout

func _indice(id: String) -> int:
	for i in _p.modos().size():
		if String(_p.modos()[i].get("id", "")) == id:
			return i
	return -1

## Mueve el ratón al centro del botón del modo, como lo haría el jugador.
func _raton_a(id: String) -> void:
	var b := _p.botones()[_indice(id)]
	var pos := b.get_global_transform_with_canvas() * (b.size * 0.5)
	## Directo al viewport: bajo xvfb, `Input.parse_input_event` no llega a dar hover.
	var ev := InputEventMouseMotion.new()
	ev.position = pos
	ev.global_position = pos
	get_viewport().push_input(ev, true)

func _guardar(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var ruta := "res://pruebas/capturas/%s.png" % nombre
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d) modo=%s" % [ruta, img.get_width(), img.get_height(), _p.modo_seleccionado()])
