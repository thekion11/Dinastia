class_name PantallaIdentidad
extends "res://ui/pantallas/pantalla_identidad_p1.gd"
## [Capa 2/2 de `pantalla_identidad.gd`] _pintar_comercial, _pintar_kits

## `vIdentidadPlus()`: LO QUE SE VENDE DEL CLUB.
##
## Aquí no se decide cómo juega el equipo: se decide cuánto vale la camiseta.
## Todo lo de esta pantalla paga, y todo lo de esta pantalla cuesta algo que no
## es dinero —el nombre del estadio, el aspecto del uniforme, la paciencia de la
## hinchada—, que es lo que la hace una pantalla de decisiones y no una lista de
## mejoras.
func _pintar_comercial(c: Club) -> void:
	var co := p.mundo.comercial
	if co == null:
		return
	p._lista_gente.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("💰 EXPLOTACIÓN COMERCIAL")
	p._lista_gente.add_child(t)
	p._dato("Entra cada semana", p._dinero(co.renta_semanal(c)), Principal.COL_VERDE, p._lista_gente)

	## Las camisetas se editan en el chip "Identidad" ahora, junto al escudo y
	## los colores del club -no aquí, junto a proveedor/zonas/naming, que es
	## puro trato comercial y no aspecto visual-.
	_pintar_proveedor(co, c)
	_pintar_zonas(co, c)
	_pintar_naming(co, c)
	_pintar_premium(co, c)
	_pintar_detalles(co, c)

## LAS TRES CAMISETAS. La de arquero existe por una razón que no es estética: en
## el campo tiene que distinguirse de las otras veintiuna.
func _pintar_kits(co: Comercial, c: Club) -> void:
	var tk := p._texto(11, p.COL_ACENTO)
	tk.text = Idiomas.t("👕 LAS TRES CAMISETAS")
	p._lista_gente.add_child(tk)
	var nombres := {"titular": "Titular", "alt": "Alternativa", "por": "De arquero"}
	## LAS TRES, GRANDES Y CON NOMBRE. A 56 px y sin rótulo no se distinguía la
	## alternativa de la de arquero, y la textura salía a tamaño exacto -borrosa
	## en cuanto la interfaz escala-: ahora van a doble resolución.
	var muestras := HBoxContainer.new()
	muestras.add_theme_constant_override("separation", 18)
	muestras.alignment = BoxContainer.ALIGNMENT_CENTER
	p._lista_gente.add_child(muestras)
	for cual: String in ["titular", "alt", "por"]:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		muestras.add_child(col)
		var img := TextureRect.new()
		img.texture = EscudoMuestras.camiseta(co.color_kit(cual, 1, c), co.color_kit(cual, 2, c),
			co.estilo_kit(cual, c), 80)
		img.custom_minimum_size = Vector2(80, 78)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		col.add_child(img)
		var pie := p._texto(10, Principal.COL_SUAVE)
		pie.text = String(nombres[cual])
		pie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(pie)
	for cual2: String in ["titular", "alt", "por"]:
		var tt := p._texto(11, Principal.COL_TEXTO)
		tt.text = String(nombres[cual2])
		p._lista_gente.add_child(tt)
		for n: int in [1, 2]:
			var num := n
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 6)
			p._lista_gente.add_child(fila)
			var et := p._texto(11, Principal.COL_TEXTO)
			et.text = Idiomas.t("Color %d") % num
			et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila.add_child(et)
			var cp := ColorPickerButton.new()
			cp.color = Color(co.color_kit(cual2, num, c))
			cp.custom_minimum_size = Vector2(84, 24)
			cp.edit_alpha = false
			cp.color_changed.connect(func(nuevo: Color) -> void:
				co.fijar_kit(cual2, "c%d" % num, "#" + nuevo.to_html(false))
				p._refrescar())
			fila.add_child(cp)
		## Cada estampado dibujado con los colores de ESTA camiseta: se elige
		## viendo el resultado, no leyendo «sash» o «vertical3».
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 4)
		flow.add_theme_constant_override("v_separation", 4)
		p._lista_gente.add_child(flow)
		var c1 := co.color_kit(cual2, 1, c)
		var c2 := co.color_kit(cual2, 2, c)
		for k: String in Jersey.KITS:
			var estilo := k
			var b := EscudoMuestras.boton(EscudoMuestras.camiseta(c1, c2, estilo, 36),
				co.estilo_kit(cual2, c) == estilo, 44)
			b.pressed.connect(func() -> void:
				co.fijar_kit(cual2, "estilo", estilo)
				p._refrescar())
			flow.add_child(b)

	## MEDIAS, SHORT Y TIPOGRAFÍA. No salen en ninguna miniatura y salen en el
	## campo: es donde de verdad se ven.
	var tm := p._texto(10, Principal.COL_SUAVE)
	tm.text = Idiomas.t("Medias, short y tipografía de los dorsales")
	p._lista_gente.add_child(tm)
	for par2: Array in [["medias", "Color de las medias"], ["pantalon", "Color del short"]]:
		var prop := String(par2[0])
		var fila2 := HBoxContainer.new()
		fila2.add_theme_constant_override("separation", 6)
		p._lista_gente.add_child(fila2)
		var et2 := p._texto(11, Principal.COL_TEXTO)
		et2.text = String(par2[1])
		et2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila2.add_child(et2)
		var actual := String(co.get(prop))
		var cp2 := ColorPickerButton.new()
		cp2.color = Color(actual if actual != "" else c.color_kit2())
		cp2.custom_minimum_size = Vector2(84, 24)
		cp2.edit_alpha = false
		cp2.color_changed.connect(func(nuevo: Color) -> void:
			co.set(prop, "#" + nuevo.to_html(false))
			p._refrescar())
		fila2.add_child(cp2)
	var flow_t := HFlowContainer.new()
	flow_t.add_theme_constant_override("h_separation", 4)
	p._lista_gente.add_child(flow_t)
	for f: Array in Comercial.tipografias():
		var clave := String(f[0])
		var b2 := Button.new()
		b2.text = String(f[1])
		b2.add_theme_font_size_override("font_size", 10)
		b2.toggle_mode = true
		b2.button_pressed = co.tipografia == clave
		b2.custom_minimum_size = Vector2(72, 22)
		b2.pressed.connect(func() -> void:
			co.tipografia = clave
			p._refrescar())
		flow_t.add_child(b2)
