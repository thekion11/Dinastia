class_name Inicio
extends "res://ui/inicio_p2.gd"
## (Parte 3 de 3 de `inicio.gd`.)

## Cada 30 s (a destiempo de la portada): el siguiente fondo de pantalla
## completa, fundido sobre el actual en 2 s.
func _rotar_pagina() -> void:
	if not is_inside_tree() or _pagina == null:
		return
	_i_pagina = (_i_pagina + 1) % Fondo.NOMBRES.size()
	_pagina2.texture = Fondo.textura(String(Fondo.NOMBRES[_i_pagina]))
	_pagina2.modulate.a = 0.0
	var tw := _pagina2.create_tween()
	tw.tween_property(_pagina2, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void:
		_pagina.texture = _pagina2.texture
		_pagina2.modulate.a = 0.0)

func _ready() -> void:
	## Lo gráfico va primero: si el jugador eligió el motor ligero, el juego
	## se relanza con él antes de montar nada.
	Calidad.cargar()
	BotonFx.activar(get_tree())
	if Calidad.relanzar_si_hace_falta(get_tree()):
		return
	## Mientras se mira el menú, los modelos pesados se cargan en un hilo.
	Precarga.empezar(get_tree())
	_clave = _leer_ajuste()
	_construir()
	_pintar_banner()
	_actualizar_picker()
	_actualizar_continuar()
	_reloj_portada = Timer.new()
	_reloj_portada.wait_time = SEG_PORTADA
	_reloj_portada.timeout.connect(_rotar_portada)
	add_child(_reloj_portada)
	_reloj_portada.start()
	## El fondo de la página cambia a destiempo de la portada (15 s después):
	## cada 15 s se mueve algo, nunca las dos cosas a la vez.
	_reloj_pagina = Timer.new()
	_reloj_pagina.wait_time = SEG_PORTADA
	_reloj_pagina.timeout.connect(_rotar_pagina)
	add_child(_reloj_pagina)
	get_tree().create_timer(SEG_PORTADA * 0.5).timeout.connect(func() -> void:
		if is_instance_valid(_reloj_pagina):
			_rotar_pagina()
			_reloj_pagina.start())
	_tenir_particulas()
	_banner.resized.connect(func() -> void:
		if is_instance_valid(_bokeh_banner):
			_bokeh_banner.ajustar_area(_banner.size))
