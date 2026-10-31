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
				co.estilo_kit(cual2, c) == estilo, 44, "", EscudoMuestras.oscuro(c1))
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

## La sección IDENTIDAD VISUAL: diseñador, vista previa, colores, uniforme (desde `Principal`, 27-10).
func _pintar_identidad(c: Club) -> void:

	## EL DISEÑADOR DE EQUIPACIÓN (26-9-2026): 70 diseños, 5 colores, pantalón,
	## medias, 30 botines, accesorios y color de números, con vista 3D.
	var bd := Button.new()
	bd.text = Idiomas.t("🎽  Abrir el diseñador de equipación")
	bd.custom_minimum_size = Vector2(0, 44)
	bd.add_theme_font_size_override("font_size", 16)
	bd.pressed.connect(func() -> void:
		var dz := DisenadorKit.abrir(p, p.mundo)
		dz.cerrado.connect(p._refrescar))
	p._lista_gente.add_child(bd)
	p._lista_gente.add_child(HSeparator.new())
	var t := p._texto(11, p.COL_SUAVE)
	t.text = Idiomas.t("🎨 IDENTIDAD VISUAL")
	p._lista_gente.add_child(t)
	if not p._modo_experto:
		var ex := p._texto(10, p.COL_SUAVE)
		ex.text = Idiomas.t("Cada cosa se pinta por separado: el uniforme no arrastra el color del menú ni el del escudo. Lo que no toques, lo hereda del club.")
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_gente.add_child(ex)

	## LA VISTA PREVIA. Escudo y camiseta juntos, con lo que hay puesto ahora
	## mismo: sin esto hay que salir de la pantalla para ver si acertaste.
	var previa := HBoxContainer.new()
	previa.add_theme_constant_override("separation", 14)
	previa.alignment = BoxContainer.ALIGNMENT_CENTER
	p._lista_gente.add_child(previa)
	## EL ESCUDO CON SUS INICIALES (o su símbolo): `p._escudo()` es el mismo que
	## se ve en el resto del juego. Antes iba solo la textura, sin las letras, y
	## la vista previa no enseñaba el escudo tal como sale en la tabla.
	var esc_img := p._escudo(c, 54)
	esc_img.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	previa.add_child(esc_img)
	var kit_img := TextureRect.new()
	kit_img.texture = Jersey.textura_procedural(c.color_kit1(), c.color_kit2(),
		Jersey.kit_de(c, c.kit_estilo), 58)
	kit_img.custom_minimum_size = Vector2(58, 58)
	kit_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	kit_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	previa.add_child(kit_img)
	## LA MUESTRA DEL ACENTO como una ficha redondeada con borde, centrada en
	## la fila: un ColorRect suelto se estiraba al alto de la fila y parecía un
	## rectángulo blanco cuando el acento es claro.
	var muestra_ui := Panel.new()
	var caja_acento := StyleBoxFlat.new()
	caja_acento.bg_color = p._acento_de(c)
	caja_acento.set_corner_radius_all(10)
	caja_acento.set_border_width_all(2)
	caja_acento.border_color = Color(1, 1, 1, 0.35)
	muestra_ui.add_theme_stylebox_override("panel", caja_acento)
	muestra_ui.custom_minimum_size = Vector2(40, 40)
	muestra_ui.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	muestra_ui.tooltip_text = Idiomas.t("Color de acento (botones y menú)")
	previa.add_child(muestra_ui)

	_fila_color_identidad(c, "1 · Color principal del club", "color1")
	_fila_color_identidad(c, "1 · Color secundario del club", "color2")

	var tk := p._texto(11, p.COL_ACENTO)
	tk.text = Idiomas.t("2 · UNIFORME%s") % ("" if c.kit_color1 == "" and c.kit_color2 == "" else Idiomas.t("  ·  propio"))
	p._lista_gente.add_child(tk)
	_fila_color_identidad(c, "Color 1 de la camiseta", "kit_color1")
	_fila_color_identidad(c, "Color 2 de la camiseta", "kit_color2")
	_rejilla_identidad(c, "kit_estilo", Jersey.KITS, "Diseño")
	_boton_heredar(c, ["kit_color1", "kit_color2"], "Volver a los colores del club")

	var te := p._texto(11, p.COL_ACENTO)
	te.text = Idiomas.t("3 · ESCUDO%s") % ("" if c.esc_color1 == "" and c.esc_color2 == "" else Idiomas.t("  ·  propio"))
	p._lista_gente.add_child(te)
	_fila_color_identidad(c, "Fondo del escudo", "esc_color1")
	_fila_color_identidad(c, "Borde y patrón", "esc_color2")
	_rejilla_identidad(c, "esc_forma", Escudo.FORMAS, "Forma del escudo")
	_rejilla_identidad(c, "esc_patron", Escudo.PATRONES, "Patrón interior")
	## "ESC_SIM" del HTML: un emoji en vez de las iniciales. El campo llevaba
	## semanas guardándose -`Club.esc_simbolo` ya viaja en el guardado- sin que
	## `Escudo` lo leyera ni hubiera dónde elegirlo. `Datos.tabla("ESC_SIM")`
	## trae un "" propio en el índice 0 -el mismo "por sorteo" que ya antepone
	## `_rejilla_identidad`-, así que se recorta para no duplicar ese botón.
	var lista_sim: Array = Datos.tabla("ESC_SIM")
	_rejilla_identidad(c, "esc_simbolo",
		lista_sim.slice(1) if lista_sim != null and lista_sim.size() > 1 else [], "Símbolo (reemplaza las iniciales)")
	if not p._modo_experto:
		var ee := p._texto(10, p.COL_SUAVE)
		ee.text = Idiomas.t("Veintiseis formas × treinta patrones × dos colores: miles de escudos distintos.")
		ee.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_gente.add_child(ee)
	_boton_heredar(c, ["esc_color1", "esc_color2"], "Volver a los colores del club")
	_rejilla_especiales(c)

	var tu := p._texto(11, p.COL_ACENTO)
	tu.text = Idiomas.t("4 · INTERFAZ%s") % ("" if c.ui_acento == "" else Idiomas.t("  ·  propia"))
	p._lista_gente.add_child(tu)
	_fila_color_identidad(c, "Color de acento (botones y menú)", "ui_acento")
	_boton_heredar(c, ["ui_acento"], "Usar el color del club")

	var b_todo := Button.new()
	b_todo.text = Idiomas.t("🎨 Igualar todo a los colores del club")
	b_todo.add_theme_font_size_override("font_size", 11)
	b_todo.pressed.connect(func() -> void:
		c.igualar_identidad()
		Escudo.limpiar_cache()
		p._refrescar())
	p._lista_gente.add_child(b_todo)

	## LAS TRES CAMISETAS. Vivían dentro del chip "Comercial" -Club→Equipación
	## solo tenía una VISTA PREVIA sin controles, y el editor de verdad estaba
	## enterrado junto a proveedor/zonas/naming, sin relación temática-. Un
	## editor de camiseta es identidad visual, así que se pinta aquí, donde ya
	## está el resto del escudo y los colores del club.
	if p.mundo.comercial != null:
		p._lista_gente.add_child(HSeparator.new())
		_pintar_kits(p.mundo.comercial, c)

## EL ARCHIVO DE PORTADAS. Se escribían después de cada partido grande y se
## perdían al cambiar de pantalla. Juntas se leen como la hemeroteca del ciclo:
## de un vistazo se ve si el año fue de titulares buenos o de titulares malos.
## LA ENTREVISTA AL PASO (C6): si esta semana te paró un medio nuevo.

## El contrato de la pantalla (`PantallaBase`, fase 0 §7.2): sus secciones, que se abren con `abrir(sección)`.
func secciones() -> Dictionary:
	return {"identidad": _pintar_identidad}
