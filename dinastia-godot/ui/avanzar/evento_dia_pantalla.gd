class_name EventoDiaPantalla
extends PantallaMaqueta
## LA PANTALLA COMPLETA DE UN EVENTO (paso 4, 17-11-2026), como la de la maqueta: fondo con el color del tipo de evento (degradado, franjas inclinadas y luces),
## a la izquierda el rótulo de la categoría, el titular en grande, el texto, tres cifras y el botón; a la derecha el ARTE del evento (dibujado en la maqueta)
## que entra animado y se mece, con confeti o polvo de luz según el evento. Emite `elegido("0")` al seguir. Al cerrar, el avance vuelve al menú.

const CONFETI := ["premio", "hito", "fiesta"]

static func mostrar(pr: Node, ev: Dictionary, m: Mundo = null) -> EventoDiaPantalla:
	var e := EventoDiaPantalla.new()
	e._armar(pr, ev, m)
	return e

func _armar(pr: Node, ev: Dictionary, m: Mundo) -> void:
	var ficha := EstiloAvanzar.ficha(ev)
	var col := EstiloAvanzar.color_de(String(ficha[1]))
	montar(pr, FondoCine.Modo.EVENTO, col, Color.BLACK, true)
	var arte_tex := EstiloAvanzar.arte(String(ficha[0]))
	var sonido := EstiloAvanzar.sonido_de(String(ficha[0]))
	if sonido != "":
		Sonido.toca(sonido)
	var izq := VBoxContainer.new()
	izq.anchor_left = 0.055; izq.anchor_right = 0.56; izq.anchor_top = 0.0; izq.anchor_bottom = 1.0
	izq.alignment = BoxContainer.ALIGNMENT_CENTER
	izq.add_theme_constant_override("separation", 12)
	_raiz.add_child(izq)
	var kicker := EstiloAvanzar.etiqueta(Idiomas.t(String(ficha[2])), 15, Color(1, 1, 1, 0.8), false, true)
	kicker.add_theme_font_override("font", EstiloAvanzar.fuente_rotulo())
	izq.add_child(kicker)
	var titulo := EstiloAvanzar.etiqueta(AvanzarTextos.titulo(ev), 76, EstiloAvanzar.TINTA, true, true)
	titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titulo.add_theme_constant_override("line_spacing", -10)
	izq.add_child(titulo)
	var texto := EstiloAvanzar.etiqueta(AvanzarTextos.texto(ev), 24, Color(1, 1, 1, 0.92))
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	izq.add_child(texto)
	var piezas: Array = [kicker, titulo, texto]
	var cifras := AvanzarTextos.cifras(ev, m)
	if not cifras.is_empty():
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 36)
		for c: Array in cifras:
			var v := VBoxContainer.new()
			v.add_theme_constant_override("separation", -2)
			v.add_child(EstiloAvanzar.etiqueta(String(c[0]), 40, Color.WHITE, true))
			v.add_child(EstiloAvanzar.etiqueta(String(c[1]), 14, Color(1, 1, 1, 0.65)))
			fila.add_child(v)
		izq.add_child(fila)
		piezas.append(fila)
	var margen := Control.new()
	margen.custom_minimum_size = Vector2(0, 14)
	izq.add_child(margen)
	var seguir := boton(Idiomas.t("Continuar"), false)
	seguir.custom_minimum_size = Vector2(240, 58)
	seguir.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	for estado: String in ["normal", "hover", "pressed"]:
		seguir.add_theme_stylebox_override(estado, _azul())
	seguir.pressed.connect(func() -> void: elegido.emit("0"))
	izq.add_child(seguir)
	piezas.append(seguir)
	seguir.grab_focus.call_deferred()
	_cascada(piezas)
	if arte_tex != null:
		_arte(arte_tex, ev, String(ficha[0]))

static func _azul() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("2f6fc4")
	s.content_margin_left = 26
	s.content_margin_right = 26
	return s

func _cascada(piezas: Array) -> void:
	if Animar.reducidas():
		return
	for i in piezas.size():
		var n: Control = piezas[i]
		n.modulate.a = 0.0
		var tw := create_tween().set_parallel(true)
		tw.tween_property(n, "modulate:a", 1.0, 0.45).set_delay(0.15 + 0.12 * i)
		n.position.y += 18.0

func _arte(tex: Texture2D, ev: Dictionary, tipo: String) -> void:
	var cont := Control.new()
	cont.anchor_left = 0.5; cont.anchor_right = 1.0; cont.anchor_top = 0.08; cont.anchor_bottom = 1.0
	cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(cont)
	var t := TextureRect.new()
	t.texture = tex
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont.add_child(t)
	if not Animar.reducidas():
		t.modulate.a = 0.0
		t.position.x += 160.0
		var tw := create_tween().set_parallel(true)
		tw.tween_property(t, "position:x", 0.0, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.2)
		tw.tween_property(t, "modulate:a", 1.0, 0.6).set_delay(0.2)
		var mece := create_tween().set_loops()
		mece.tween_interval(1.2)
		mece.tween_property(cont, "position:y", -7.0, 2.4).set_trans(Tween.TRANS_SINE).as_relative()
		mece.tween_property(cont, "position:y", 7.0, 2.4).set_trans(Tween.TRANS_SINE).as_relative()
	if tipo in CONFETI and not Animar.reducidas():
		_confeti(cont)

## Confeti de colores que cae despacio (premios, balances, fiestas).
func _confeti(padre: Control) -> void:
	var p := CPUParticles2D.new()
	p.position = Vector2(padre.size.x * 0.5, -10)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(300, 4)
	p.amount = 46
	p.lifetime = 5.0
	p.direction = Vector2(0, 1)
	p.spread = 12.0
	p.gravity = Vector2(0, 30)
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 110.0
	p.angular_velocity_min = -200.0
	p.angular_velocity_max = 200.0
	p.scale_amount_min = 4.0
	p.scale_amount_max = 8.0
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
	g.colors = PackedColorArray([Color("e5484d"), Color("f2d13b"), Color("4f8ff7"), Color("ffffff"), Color("3fb27f")])
	p.color_initial_ramp = g
	p.z_index = 2
	padre.add_child(p)
