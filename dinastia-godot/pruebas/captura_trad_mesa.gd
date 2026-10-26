extends Control
## LA MESA DEL REPRESENTANTE EN OTRO IDIOMA (paquete trad, 25-10-2026): comprueba que el saludo, la
## última frase con su señal y los botones salen traducidos y caben. IDIOMA=en|de|… (por defecto en).
##   IDIOMA=de RESOLUCION=1280x720 herramientas/captura.sh res://pruebas/captura_trad_mesa.tscn
var _ui: MesaAgenteUI
var _mesa: MesaAgente
var _n := 0

func _ready() -> void:
	Idiomas.idioma = OS.get_environment("IDIOMA") if OS.get_environment("IDIOMA") != "" else "en"
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
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/trad_mesa_%s_%s.png" % [Idiomas.idioma, OS.get_environment("RESOLUCION")])
		get_tree().quit()
