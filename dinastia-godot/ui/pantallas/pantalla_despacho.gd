class_name PantallaDespacho
extends "res://ui/pantallas/pantalla_despacho_p1.gd"
## (Parte 2 de 2 de `pantalla_despacho.gd`.)

## La pregunta en pantalla y el reloj a cero. La usa también la repregunta,
## que cambia el texto sin rehacer el plató 3D.
func _pintar_pregunta_rueda(e: Dictionary) -> void:
	var quien_txt := String(e.get("quien", "Periodista"))
	var per := String(e.get("periodista", ""))
	if per != "":
		var rel := p.mundo.prensa.relacion_con(per)
		var trato := "te aprecia" if rel >= 65 else ("no te quiere" if rel <= 35 else "sin bando")
		quien_txt += "  ·  %s, %s" % [String(e.get("perfil", "")), trato]
	if bool(e.get("memoria", false)):
		quien_txt += "  ·  🧠 recuerda lo que dijiste"
	p._rueda_quien.text = "🎙️ " + quien_txt.to_upper()
	p._rueda_pregunta.text = String(e.get("pregunta", ""))
	p._rueda_desde = Time.get_ticks_msec()
	if is_instance_valid(p._rueda_reloj):
		p._rueda_reloj.value = 0.0
		p._rueda_reloj.modulate = Color.WHITE
		var tw := p._rueda_reloj.create_tween()
		tw.tween_property(p._rueda_reloj, "value", Prensa.TITUBEO_SEG, Prensa.TITUBEO_SEG)
		tw.tween_callback(func() -> void:
			if is_instance_valid(p._rueda_reloj):
				p._rueda_reloj.modulate = Tema.MAL)
		p._rueda_reloj.set_meta("tween", tw)

func _segundos_rueda() -> float:
	return float(Time.get_ticks_msec() - p._rueda_desde) / 1000.0

func _fila_opciones_rueda(e: Dictionary) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	var ops: Array = e.get("opciones", [])
	for i in ops.size():
		var op: Variant = ops[i]
		var b2 := Button.new()
		## Las opciones del guion son DICCIONARIOS -{txt, moral, confianza,
		## socios}-, no arrays ni cadenas: `String(op)` reventaba en cada rueda
		## de prensa y el boton se quedaba sin texto. No se veia porque la rueda
		## no llegaba a abrirse nunca en una partida de verdad.
		if op is Dictionary:
			b2.text = String((op as Dictionary).get("txt", ""))
		elif op is Array:
			b2.text = String((op as Array)[0])
		else:
			b2.text = str(op)
		b2.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b2.custom_minimum_size = Vector2(0, 42)
		## Mismo estilo que los diálogos (13-10-2026): píldora con borde dorado
		## al pasar, numerada.
		CuadroDialogo.respuesta(b2)
		b2.text = "%d.  %s" % [i + 1, b2.text]
		b2.add_theme_font_size_override("font_size", 15)
		b2.pressed.connect(func() -> void: p._responder(i))
		col.add_child(b2)
	return col

func _tras_responder(r: Dictionary) -> void:
	if r.is_empty():
		return
	## La frase y el "cómo" ya los escribe `Prensa.noticia`; aquí solo lo que
	## movió, que es lo que no dice la noticia.
	var col := "#4caf6d" if int(r.get("confianza", 0)) >= 0 else "#e05555"
	p._escribir("[color=%s]🎙 moral %+d · confianza %+d · socios %+d[/color]" % [
		col, int(r.get("moral", 0)), int(r.get("confianza", 0)), int(r.get("socios", 0))])
	## LA REPREGUNTA: el mismo plató, otra pregunta y otras opciones.
	if bool(r.get("sigue", false)) and p._rueda_pop != null and p.mundo.prensa.hay_rueda():
		var e := p.mundo.prensa.entrevista
		var viejas := p._rueda_opciones
		p._rueda_opciones = _fila_opciones_rueda(e)
		viejas.add_sibling(p._rueda_opciones)
		viejas.queue_free()
		_pintar_pregunta_rueda(e)
		Animar.aparecer(p._rueda_opciones)
		Sonido.toca("cambio", Sonido.Bus.INTERFAZ)
		return
	## Se cierra la cinemática -ya respondiste, no hay nada más que ver- y se
	## vuelve al juego normal.
	if p._rueda_pop != null:
		p._rueda_pop.queue_free()
		p._rueda_pop = null
	p._refrescar()

## Responder con tus palabras. El tono lo decide `Prensa.clasificar_respuesta()`
## por palabras clave, en local: nada sale del ordenador.
func _fila_texto_libre() -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	var campo := LineEdit.new()
	campo.placeholder_text = Idiomas.t("…o responde con tus propias palabras")
	campo.max_length = 120
	campo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(campo)
	var b := Button.new()
	b.text = Idiomas.t("Responder")
	fila.add_child(b)
	var enviar := func(_t: String = "") -> void:
		if campo.text.strip_edges() != "":
			var dicho := campo.text
			campo.clear()   ## si llega la repregunta, el campo vuelve vacío
			_tras_responder(p.mundo.prensa.responder_texto(dicho, _segundos_rueda()))
	b.pressed.connect(func() -> void: enviar.call())
	campo.text_submitted.connect(enviar)
	return fila

## "Cómo lo dices". Vive aparte de `_abrir_rueda_pantalla_completa()` porque
## se repinta sola al tocar una postura -sin cerrar ni reabrir el plató 3D
## entero, que sería tirar y rehacer el `SubViewport` por nada-.
func _fila_posturas() -> HBoxContainer:
	var posturas := HBoxContainer.new()
	posturas.add_theme_constant_override("separation", 6)
	var et := p._texto(11, Principal.COL_SUAVE)
	et.text = Idiomas.t("Cómo lo dices:")
	et.custom_minimum_size = Vector2(96, 0)
	posturas.add_child(et)
	var lista_cuerpos: Dictionary = p.mundo.prensa.cuerpos()
	for k: String in lista_cuerpos:
		var datos: Array = lista_cuerpos[k]
		var b := Button.new()
		b.text = "%s %s" % [String(datos[0]), String(datos[1])]
		b.toggle_mode = true
		b.button_pressed = (k == p.mundo.prensa.cuerpo)
		b.add_theme_font_size_override("font_size", 11)
		b.pressed.connect(func() -> void:
			p.mundo.prensa.fijar_cuerpo(k)
			p._repintar_posturas())
		posturas.add_child(b)
	return posturas
