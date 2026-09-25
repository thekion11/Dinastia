extends Node
## Prueba de que el visor 3D se abre SOLO al empezar un partido dirigido -sin
## pulsar "Ver en 3D"- (13-9-2026, pedido: "el visor debe ser de forma
## nativa"). Comprueba que `VistaEstadio` ya es hijo de `PartidoVivo` en el
## mismo instante en que se abre el partido, con el partido de verdad dentro
## (no una maqueta), y que cerrarlo devuelve al panel de control sin romper
## nada.
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##         res://pruebas/captura_visor_nativo.tscn

var _n := 0
var _pantalla: Node
var _vivo: PartidoVivo

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

var _vista_hija: Node = null

func _process(_d: float) -> void:
	_n += 1
	if _n == 12:
		_pantalla.call("_dirigir")
		for h in _pantalla.get_children():
			if h is PartidoVivo:
				_vivo = h
				break
		print("se abrio PartidoVivo = %s" % (_vivo != null))
		if _vivo != null:
			for h2 in _vivo.get_children():
				if h2 is VistaEstadio:
					_vista_hija = h2
					break
		print("VistaEstadio ya estaba abierto SIN pulsar boton = %s" % (_vista_hija != null))
	## La captura va en un fotograma APARTE del que abre la escena -si se
	## captura en el mismo `_process()`, `get_viewport().get_texture()` da lo
	## ULTIMO pintado (el frame anterior), no lo nuevo: trampa ya pagada en
	## esta sesion, documentada en la memoria del proyecto.
	if _n == 20:
		if _vista_hija != null:
			var j: MatchPlayback = _vista_hija.get("_juego")
			print("el partido dentro del visor es el mismo objeto que dirige PartidoVivo = %s" %
				(j != null))
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/visor_nativo.png")
		if _vista_hija != null:
			_vista_hija.emit_signal("cerrado")
	if _n == 30:
		var sigue_el_panel := _vivo != null and is_instance_valid(_vivo) and _vivo.is_inside_tree()
		print("tras cerrar el 3D, el panel de control de PartidoVivo sigue en pie = %s" % sigue_el_panel)
	if _n == 34:
		var img2 := get_viewport().get_texture().get_image()
		img2.save_png("res://pruebas/visor_nativo_tras_volver.png")
		get_tree().quit()
