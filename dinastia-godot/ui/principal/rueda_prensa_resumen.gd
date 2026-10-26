extends Control
## EL RESUMEN AL CERRAR LA RUEDA DE PRENSA (26-10, pedido del dueño tras
## compararla con Football Manager y EA FC): las consecuencias se VEN. Antes
## los efectos solo salían en una línea del registro; ahora, al contestar la
## última pregunta, una tarjeta dice qué movió la rueda entera (moral del
## vestuario, confianza de la directiva, socios), cómo queda la relación con
## el periodista y el titular que saldrá mañana. Se cierra con Continuar
## (ratón, Enter/Espacio, Escape o A del mando).
##
## Es un nodo aparte y no la propia rueda: la rueda se libera al contestar
## (Principal y las pruebas cuentan con ello) y esto queda encima un momento.

## Abre el resumen sobre `p`. `suma`: {moral, confianza, socios};
## `titular`: `Prensa.titular_pendiente` ({t, c}); `medio`: «Nombre · Medio».
static func mostrar(p: Principal, suma: Dictionary, titular: Dictionary, medio: String, periodista: String) -> Control:
	if p == null or not p.is_inside_tree():
		return null
	var viejo := p.get_node_or_null("ResumenRueda")
	if viejo != null:
		viejo.name = "ResumenRuedaViejo"
		viejo.queue_free()
	var n: Control = load("res://ui/principal/rueda_prensa_resumen.gd").new()
	n.name = "ResumenRueda"
	n.set_anchors_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	n.z_index = 100
	n.add_to_group(MentorVoz.GRUPO_TAPA)
	p.add_child(n)
	n.call("_montar", p, suma, titular, medio, periodista)
	return n

func _montar(p: Principal, suma: Dictionary, titular: Dictionary, medio: String, periodista: String) -> void:
	var velo := ColorRect.new()
	velo.color = Color(0.02, 0.025, 0.03, 0.86)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(velo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var caja := PanelContainer.new()
	caja.custom_minimum_size = Vector2(560, 0)
	var sb := Tema.caja(Tema.PANEL, Tema.RADIO_GRANDE, Tema.ACENTO)
	sb.content_margin_left = 28; sb.content_margin_right = 28
	sb.content_margin_top = 22; sb.content_margin_bottom = 22
	caja.add_theme_stylebox_override("panel", sb)
	centro.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	caja.add_child(v)
	v.add_child(Tema.etiqueta(20, Tema.ORO, Idiomas.t("🎙️ Fin de la rueda de prensa")))
	var filas := GridContainer.new()
	filas.columns = 2
	filas.add_theme_constant_override("h_separation", 24)
	filas.add_theme_constant_override("v_separation", 6)
	v.add_child(filas)
	for par: Array in [["moral", Idiomas.t("Moral del vestuario")], ["confianza", Idiomas.t("Confianza de la directiva")],
			["socios", Idiomas.t("Socios")]]:
		var val := int(suma.get(par[0], 0))
		filas.add_child(Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, String(par[1])))
		var num := Tema.etiqueta(Tema.TAM_DESTACADO, Tema.BIEN if val > 0 else (Tema.MAL if val < 0 else Tema.SUAVE), "%+d" % val)
		filas.add_child(num)
	if periodista != "" and p.mundo.prensa != null:
		filas.add_child(Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, Idiomas.t("Relación con %s") % medio))
		filas.add_child(Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, "%d/100" % p.mundo.prensa.relacion_con(periodista)))
	var t := String(titular.get("t", ""))
	if t != "":
		v.add_child(HSeparator.new())
		v.add_child(Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE, Idiomas.t("📰 Mañana en portada")))
		var tit := Tema.etiqueta(Tema.TAM_DESTACADO + 2, Tema.TEXTO, Idiomas.t(t))
		tit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tit.custom_minimum_size = Vector2(500, 0)
		v.add_child(tit)
	var b := Button.new()
	b.name = "Continuar"
	b.text = Idiomas.t("Continuar")
	b.custom_minimum_size = Vector2(0, 40)
	CuadroDialogo.respuesta(b)
	b.pressed.connect(cerrar)
	v.add_child(b)
	b.grab_focus.call_deferred()
	Animar.aparecer(caja, 0.05, 0.3)

func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel") or ev.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		cerrar()

func cerrar() -> void:
	if is_queued_for_deletion():
		return
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.tween_callback(queue_free)
