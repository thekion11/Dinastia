class_name Inicio
extends "res://ui/inicio_p2.gd"
## [Capa 3/3 de `inicio.gd`] _rotar_pagina, _ready, _construir_nuevo_juego, _nuevo_juego

## LA ENTRADA NUEVA (fase 1, 25-10-2026): «Nuevo juego» abre `OrquestadorEntrada`
## (intro, idioma, modo, país, club, entrada al campeonato y personaje, una pantalla
## completa por etapa). El menú de siempre sigue debajo y entero -«Continuar» y las
## tarjetas de modo con su camino viejo- hasta que el dueño apruebe el nuevo; en falso,
## el botón desaparece y todo queda exactamente como antes.
static var flujo_nuevo := true

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
	_construir_nuevo_juego()
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

## El botón grande de «Nuevo juego», justo debajo de la partida en curso.
func _construir_nuevo_juego() -> void:
	if not flujo_nuevo or _panel_continuar == null:
		return
	var raiz := _panel_continuar.get_parent()
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", Tema.caja(Tema.PANEL, Tema.RADIO_GRANDE, COL_ACENTO))
	raiz.add_child(caja)
	raiz.move_child(caja, _panel_continuar.get_index() + 1)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	caja.add_child(fila)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(v)
	v.add_child(Tema.etiqueta(Tema.TAM_TITULO, COL_TEXTO, Idiomas.t("NUEVO JUEGO")))
	var nota := Tema.etiqueta(Tema.TAM_ROTULO, COL_SUAVE, Idiomas.t("Paso a paso: idioma, modo, país, tu club, cómo entras al campeonato y tu personaje. Más abajo sigue el menú de siempre."))
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(nota)
	var b := Button.new()
	b.text = Idiomas.t("▶ Empezar")
	b.custom_minimum_size = Vector2(150, 44)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(_nuevo_juego)
	fila.add_child(b)

func _nuevo_juego() -> void:
	## Lo que ya se tocó en este menú (nombre y dificultad) no se pierde.
	var nombre := _campo_nombre.text.strip_edges() if _campo_nombre != null else ""
	OrquestadorEntrada.estado_inicial = {"dificultad": _dificultad}
	if nombre != "" and nombre != Idiomas.t("Míster"):
		OrquestadorEntrada.estado_inicial["nombre"] = nombre
	get_tree().change_scene_to_file("res://escenas/entrada.tscn")
