class_name PantallaIdentidad
extends RefCounted
## IDENTIDAD Y COMERCIAL: colores, escudo, equipaciones, proveedor, zonas, naming y detalles.
##
## Sale de `ui/principal.gd` (mapa de metas 15: el archivo pasaba de
## 15.000 líneas). `p` es la pantalla principal: sus ayudantes (`p._texto`,
## `p._boton`...), el mundo (`p.mundo`) y el repintado (`p._refrescar()`).

var p: Principal

func _init(principal: Principal) -> void:
	p = principal

## Una fila de color. `prop` puede ser un color del club (siempre tiene valor) o
## uno de los heredables (vacío = "el del club"), y el selector arranca con el
## color EFECTIVO en los dos casos: enseñar negro para "sin elegir" haría creer
## que el escudo es negro.
func _fila_color_identidad(c: Club, etiqueta: String, prop: String) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	p._lista_gente.add_child(fila)
	var et := p._texto(12, Principal.COL_TEXTO)
	et.text = etiqueta
	et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et.clip_text = true
	et.tooltip_text = etiqueta
	fila.add_child(et)
	var actual := String(c.get(prop))
	if actual == "":
		match prop:
			"kit_color1": actual = c.color_kit1()
			"kit_color2": actual = c.color_kit2()
			"esc_color1": actual = c.color_escudo1()
			"esc_color2": actual = c.color_escudo2()
			"ui_acento": actual = c.color_acento()
			_: actual = c.color1
	var cp := ColorPickerButton.new()
	cp.color = Color(actual)
	cp.custom_minimum_size = Vector2(90, 26)
	cp.edit_alpha = false
	## `color_changed` y no `popup_closed`: se ve el cambio mientras eliges, que
	## es la única forma de acertar con un color.
	cp.color_changed.connect(func(nuevo: Color) -> void:
		c.set(prop, "#" + nuevo.to_html(false))
		Escudo.limpiar_cache()
		p._refrescar())
	fila.add_child(cp)

## Una rejilla de opciones para un campo de texto (estampado, forma, patrón).
## Incluye un botón vacío al principio: "el que le tocó por sorteo" también es
## una elección válida y hay que poder volver a ella.
func _rejilla_identidad(c: Club, prop: String, opciones: Array, titulo: String) -> void:
	var lt := p._texto(10, Principal.COL_SUAVE)
	lt.text = titulo
	p._lista_gente.add_child(lt)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 4)
	p._lista_gente.add_child(flow)
	var actual := String(c.get(prop))
	for op: Variant in ([""] + Array(opciones)):
		var clave := String(op)
		var b := Button.new()
		b.text = clave if clave != "" else "por sorteo"
		b.add_theme_font_size_override("font_size", 10)
		b.toggle_mode = true
		b.button_pressed = actual == clave
		b.clip_text = true
		b.custom_minimum_size = Vector2(72, 24)
		b.pressed.connect(func() -> void:
			c.set(prop, clave)
			Escudo.limpiar_cache()
			p._refrescar())
		flow.add_child(b)

## El picker de escudos especiales (22-9-2026): a diferencia de
## `_rejilla_identidad()` -que alcanza con mostrar el nombre de la clave
## ("cruz", "tablero")-, un especial es una imagen de Canva sin relacion
## visible con su id ("wolf_1" no dice nada), asi que cada boton lleva la
## miniatura real en vez de texto. Solo se listan los YA desbloqueados -ver
## `Escudo.especiales_desbloqueados()`- mas un "Ninguno" para volver al
## generador procedural de arriba, la misma logica que el "por sorteo" de
## `_rejilla_identidad()`.
func _rejilla_especiales(c: Club) -> void:
	var desbloqueados: Array = Escudo.especiales_desbloqueados()
	var total: int = Escudo.ESPECIALES.size()
	var lt := p._texto(11, p.COL_ACENTO)
	lt.text = "Escudo especial (coleccionable)"
	p._lista_gente.add_child(lt)
	if not p._modo_experto:
		var info := p._texto(10, Principal.COL_SUAVE)
		info.text = "%d de %d desbloqueados según tu nivel de perfil de gestor -suben solos jugando temporadas y ganando títulos-. No reemplazan al generador de arriba: son una alternativa que podés elegir o no." % [desbloqueados.size(), total]
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_gente.add_child(info)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 4)
	p._lista_gente.add_child(flow)

	var b_ninguno := Button.new()
	b_ninguno.text = "Ninguno\n(procedural)"
	b_ninguno.add_theme_font_size_override("font_size", 9)
	b_ninguno.toggle_mode = true
	b_ninguno.button_pressed = c.esc_especial == ""
	b_ninguno.custom_minimum_size = Vector2(64, 64)
	b_ninguno.pressed.connect(func() -> void:
		c.esc_especial = ""
		p._refrescar())
	flow.add_child(b_ninguno)

	for id: String in desbloqueados:
		var b := Button.new()
		b.toggle_mode = true
		b.button_pressed = c.esc_especial == id
		b.custom_minimum_size = Vector2(64, 64)
		b.tooltip_text = id
		var tex := Escudo.textura_especial(id)
		if tex != null:
			var ic := TextureRect.new()
			ic.texture = tex
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ic.set_anchors_preset(Control.PRESET_FULL_RECT)
			ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(ic)
		b.pressed.connect(func() -> void:
			c.esc_especial = id
			p._refrescar())
		flow.add_child(b)

func _boton_heredar(c: Club, props: Array, texto: String) -> void:
	var b := Button.new()
	b.text = texto
	b.add_theme_font_size_override("font_size", 10)
	var vacios := true
	for p_local: String in props:
		if String(c.get(p_local)) != "":
			vacios = false
	b.disabled = vacios
	b.pressed.connect(func() -> void:
		for p2: String in props:
			c.set(p2, "")
		Escudo.limpiar_cache()
		p._refrescar())
	p._lista_gente.add_child(b)

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
	t.text = "💰 EXPLOTACIÓN COMERCIAL"
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
	tk.text = "👕 LAS TRES CAMISETAS"
	p._lista_gente.add_child(tk)
	var muestras := HBoxContainer.new()
	muestras.add_theme_constant_override("separation", 12)
	muestras.alignment = BoxContainer.ALIGNMENT_CENTER
	p._lista_gente.add_child(muestras)
	for cual: String in ["titular", "alt", "por"]:
		var img := TextureRect.new()
		img.texture = Jersey.textura_procedural(co.color_kit(cual, 1, c),
			co.color_kit(cual, 2, c), co.estilo_kit(cual, c), 56)
		img.custom_minimum_size = Vector2(56, 56)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.tooltip_text = {"titular": "Titular", "alt": "Alternativa", "por": "De arquero"}[cual]
		muestras.add_child(img)
	for par: Array in [["titular", "Titular"], ["alt", "Alternativa"], ["por", "De arquero"]]:
		var cual2 := String(par[0])
		var tt := p._texto(10, Principal.COL_SUAVE)
		tt.text = String(par[1])
		p._lista_gente.add_child(tt)
		for n: int in [1, 2]:
			var num := n
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 6)
			p._lista_gente.add_child(fila)
			var et := p._texto(11, Principal.COL_TEXTO)
			et.text = "Color %d" % num
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
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 4)
		flow.add_theme_constant_override("v_separation", 4)
		p._lista_gente.add_child(flow)
		for k: String in Jersey.KITS:
			var estilo := k
			var b := Button.new()
			b.text = estilo
			b.add_theme_font_size_override("font_size", 10)
			b.toggle_mode = true
			b.button_pressed = co.estilo_kit(cual2, c) == estilo
			b.clip_text = true
			b.custom_minimum_size = Vector2(66, 22)
			b.pressed.connect(func() -> void:
				co.fijar_kit(cual2, "estilo", estilo)
				p._refrescar())
			flow.add_child(b)

	## MEDIAS, SHORT Y TIPOGRAFÍA. No salen en ninguna miniatura y salen en el
	## campo: es donde de verdad se ven.
	var tm := p._texto(10, Principal.COL_SUAVE)
	tm.text = "Medias, short y tipografía de los dorsales"
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

## EL PROVEEDOR. La marca propia no paga nada y se queda el margen entero: es la
## opción del club que no quiere deberle nada a nadie.
func _pintar_proveedor(co: Comercial, c: Club) -> void:
	var t := p._texto(11, p.COL_ACENTO)
	t.text = "🏭 PROVEEDOR DE INDUMENTARIA"
	p._lista_gente.add_child(t)
	p._dato("Aporta al año", p._dinero(co.renta_proveedor(c)), Principal.COL_VERDE, p._lista_gente)
	for f: Array in Comercial.proveedores():
		var clave := String(f[0])
		var elegido := co.proveedor == clave
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_gente.add_child(fila)
		var n := p._texto(12, p.COL_ACENTO if elegido else Principal.COL_TEXTO)
		n.text = "%s%s" % ["✔  " if elegido else "     ", Nombres.limpiar(String(f[1]))]
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		n.tooltip_text = String(f[3])
		fila.add_child(n)
		var m := p._texto(11, Principal.COL_ORO)
		m.text = "×%.2f" % float(f[2]) if float(f[2]) > 0.0 else "—"
		m.custom_minimum_size = Vector2(50, 0)
		fila.add_child(m)
		var b := Button.new()
		b.text = "Firmado" if elegido else "Firmar"
		b.disabled = elegido
		b.add_theme_font_size_override("font_size", 11)
		b.custom_minimum_size = Vector2(84, 0)
		b.pressed.connect(func() -> void:
			co.proveedor = clave
			p._refrescar())
		fila.add_child(b)

## LAS CINCO ZONAS. Son contratos INDEPENDIENTES y todos ingresan a la vez, que
## es exactamente por qué las camisetas modernas están como están.
func _pintar_zonas(co: Comercial, c: Club) -> void:
	var t := p._texto(11, p.COL_ACENTO)
	t.text = "💸 PATROCINIOS POR ZONA"
	p._lista_gente.add_child(t)
	p._dato("Total de las zonas", "%s/semana" % p._dinero(co.renta_zonas()), Principal.COL_VERDE, p._lista_gente)
	for z: Array in Comercial.zonas():
		var clave := String(z[0])
		if co.zonas_firmadas.has(clave):
			var f: Dictionary = co.zonas_firmadas[clave]
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 6)
			p._lista_gente.add_child(fila)
			var n := p._texto(12, Color(String(f.get("color", "#e8b13a"))))
			n.text = "%s  ·  %s" % [String(f["marca"]), String(z[1])]
			n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			n.clip_text = true
			n.tooltip_text = "%s al año, firmado en %d por %d temporada(s)" % [
				p._dinero(int(f["monto"])), int(f["desde"]), int(f["anios"])]
			fila.add_child(n)
			var mm := p._texto(11, Principal.COL_VERDE)
			mm.text = "%s/año" % p._dinero(int(f["monto"]))
			mm.custom_minimum_size = Vector2(90, 0)
			fila.add_child(mm)
			var br := Button.new()
			br.text = "Romper"
			br.add_theme_font_size_override("font_size", 10)
			br.custom_minimum_size = Vector2(72, 0)
			br.pressed.connect(func() -> void:
				var p_local := co.romper_zona(clave, p.mundo.mi_club())
				if p_local != "":
					p._escribir("[color=#e05555]No se pudo: %s.[/color]" % p_local)
				p._refrescar())
			fila.add_child(br)
			continue
		var libre := p._texto(11, Principal.COL_SUAVE)
		libre.text = "%s  ·  libre" % String(z[1])
		p._lista_gente.add_child(libre)
		for i in (co.ofertas_zona.get(clave, []) as Array).size():
			var idx := i
			var o: Dictionary = (co.ofertas_zona[clave] as Array)[i]
			var fila2 := HBoxContainer.new()
			fila2.add_theme_constant_override("separation", 6)
			p._lista_gente.add_child(fila2)
			var n2 := p._texto(11, Color(String(o.get("color", "#e8b13a"))))
			n2.text = "     %s  ·  %d año(s)" % [String(o["marca"]), int(o["anios"])]
			n2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			n2.clip_text = true
			fila2.add_child(n2)
			var b2 := Button.new()
			b2.text = "%s/año" % p._dinero(int(o["monto"]))
			b2.add_theme_font_size_override("font_size", 10)
			b2.custom_minimum_size = Vector2(110, 0)
			b2.pressed.connect(func() -> void:
				var p_local := co.firmar_zona(clave, idx)
				if p_local != "":
					p._escribir("[color=#e05555]No se pudo firmar: %s.[/color]" % p_local)
				p._refrescar())
			fila2.add_child(b2)
	var bb := Button.new()
	bb.text = "🔄 Salir a buscar ofertas"
	bb.add_theme_font_size_override("font_size", 11)
	bb.pressed.connect(func() -> void:
		co.generar_ofertas_zona(p.mundo.mi_club(), p.mundo.roles.multiplicador_sponsor() if p.mundo.roles != null else 1.0)
		p._refrescar())
	p._lista_gente.add_child(bb)

## EL NAMING. Lo más rentable que existe y lo que más duele: la hinchada lo paga
## en ánimo el día que se firma.
func _pintar_naming(co: Comercial, c: Club) -> void:
	var t := p._texto(11, p.COL_ACENTO)
	t.text = "🏟️ NOMBRE DEL ESTADIO"
	p._lista_gente.add_child(t)
	if not co.naming.is_empty():
		var n := p._texto(13, Color(String(co.naming.get("color", "#e8b13a"))))
		n.text = String(co.naming.get("nombre", ""))
		p._lista_gente.add_child(n)
		p._dato("Contrato", "%s/año  ·  %d años desde %d" % [
			p._dinero(int(co.naming["monto"])), int(co.naming["anios"]), int(co.naming["desde"])],
			Principal.COL_VERDE, p._lista_gente)
		var br := Button.new()
		br.text = "Recuperar el nombre  ·  %s" % p._dinero(int(round(float(int(co.naming["monto"])) * 0.6)))
		br.add_theme_font_size_override("font_size", 11)
		br.pressed.connect(func() -> void:
			var p_local := co.romper_naming(p.mundo.mi_club())
			if p_local != "":
				p._escribir("[color=#e05555]No se pudo: %s.[/color]" % p_local)
			p._refrescar())
		p._lista_gente.add_child(br)
		return
	if not p._modo_experto:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = "Vender el nombre del estadio es de lo más rentable que existe… y de lo que más duele a la hinchada."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_gente.add_child(ex)
	if co.ofertas_naming.is_empty():
		var bb := Button.new()
		bb.text = "Escuchar ofertas por el nombre"
		bb.add_theme_font_size_override("font_size", 11)
		bb.pressed.connect(func() -> void:
			co.generar_ofertas_naming(p.mundo.mi_club())
			p._refrescar())
		p._lista_gente.add_child(bb)
		return
	for i in co.ofertas_naming.size():
		var idx := i
		var o: Dictionary = co.ofertas_naming[i]
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_gente.add_child(fila)
		var n2 := p._texto(12, Color(String(o.get("color", "#e8b13a"))))
		n2.text = "%s  ·  %d años" % [String(o["nombre"]), int(o["anios"])]
		n2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n2.clip_text = true
		fila.add_child(n2)
		var b := Button.new()
		b.text = "%s/año" % p._dinero(int(o["monto"]))
		b.add_theme_font_size_override("font_size", 10)
		b.custom_minimum_size = Vector2(110, 0)
		b.pressed.connect(func() -> void:
			var p_local := co.firmar_naming(idx, p.mundo.mi_club())
			if p_local != "":
				p._escribir("[color=#e05555]No se pudo: %s.[/color]" % p_local)
			p._refrescar())
		fila.add_child(b)

## EL ESTADIO PREMIUM. No es ladrillo —eso son las Obras— sino ESPECTÁCULO. El
## techo salva la taquilla cuando llueve y las luces suben el ambiente de verdad.
func _pintar_premium(co: Comercial, c: Club) -> void:
	var t := p._texto(11, p.COL_ACENTO)
	t.text = "✨ ESTADIO PREMIUM"
	p._lista_gente.add_child(t)
	for f: Array in Comercial.premium():
		var clave := String(f[0])
		var niv := co.nivel_premium(clave)
		var tope: int = int(f[2])
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_gente.add_child(fila)
		var n := p._texto(12, Principal.COL_TEXTO)
		n.text = "%s  %s%s" % [String(f[1]), "●".repeat(niv), "○".repeat(tope - niv)]
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		n.tooltip_text = String(f[4])
		fila.add_child(n)
		var b := Button.new()
		var lleno := niv >= tope
		var coste := co.coste_premium(clave, c)
		b.text = "MÁX" if lleno else p._dinero(coste)
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = lleno or c.saldo < coste
		b.custom_minimum_size = Vector2(110, 0)
		b.pressed.connect(func() -> void:
			var p_local := co.mejorar_premium(clave, p.mundo.mi_club())
			if p_local != "":
				p._escribir("[color=#e05555]No se puede: %s.[/color]" % p_local)
			p._refrescar())
		fila.add_child(b)
	p._dato("Rentan por semana", p._dinero(co.renta_premium(c)), Principal.COL_VERDE, p._lista_gente)
	if co.nivel_premium("techo") > 0:
		p._dato("Techo retráctil", "+%d%% de asistencia" % int(round((co.factor_techo() - 1.0) * 100.0)),
			Principal.COL_VERDE, p._lista_gente)
	if co.bono_ambiente() > 0:
		p._dato("Luces y pantallas", "+%d de ambiente" % co.bono_ambiente(), Principal.COL_VERDE, p._lista_gente)

## LOS DETALLES. Ninguno cambia un resultado salvo el avión, y por eso están
## todos juntos al final: son las cosas que hacen que el club sea ESE club.
func _pintar_detalles(co: Comercial, c: Club) -> void:
	var t := p._texto(11, p.COL_ACENTO)
	t.text = "🎺 DETALLES DEL CLUB"
	p._lista_gente.add_child(t)
	var campo := LineEdit.new()
	campo.text = co.lema
	campo.placeholder_text = "Lema del club. Ej: «Nunca caminarás solo»"
	campo.max_length = 60
	campo.add_theme_font_size_override("font_size", 12)
	campo.text_submitted.connect(func(x: String) -> void:
		co.escribir_lema(x)
		p._refrescar())
	campo.focus_exited.connect(func() -> void: co.escribir_lema(campo.text))
	p._lista_gente.add_child(campo)
	_rejilla_comercial(co, "festejo", Comercial.festejos(), "Festejo de campeón")
	_rejilla_comercial(co, "balon", Comercial.balones(), "Balón de juego")
	_rejilla_comercial(co, "cesped", [["natural", "Natural"], ["hibrido", "Híbrido"],
		["sintetico", "Sintético"]], "Tipo de césped")

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	p._lista_gente.add_child(fila)
	var et := p._texto(11, Principal.COL_TEXTO)
	et.text = "Color del bus del equipo"
	et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(et)
	var cp := ColorPickerButton.new()
	cp.color = Color(co.bus)
	cp.custom_minimum_size = Vector2(84, 24)
	cp.edit_alpha = false
	cp.color_changed.connect(func(nuevo: Color) -> void:
		co.bus = "#" + nuevo.to_html(false))
	fila.add_child(cp)

	var fila2 := HBoxContainer.new()
	fila2.add_theme_constant_override("separation", 6)
	p._lista_gente.add_child(fila2)
	var et2 := p._texto(11, Principal.COL_TEXTO)
	et2.text = "Avión propio para giras"
	et2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et2.tooltip_text = "El plantel deja de volar en línea regular: menos fatiga en los viajes largos."
	fila2.add_child(et2)
	var b := Button.new()
	b.text = "SÍ" if co.avion else p._dinero(Eco.escalar(Comercial.COSTE_AVION, float(c.rep)))
	b.add_theme_font_size_override("font_size", 11)
	b.custom_minimum_size = Vector2(110, 0)
	b.pressed.connect(func() -> void:
		var msg := co.comprar_avion(p.mundo.mi_club())
		p._escribir("[color=#c9a227]%s[/color]" % msg)
		p._refrescar())
	fila2.add_child(b)

func _rejilla_comercial(co: Comercial, prop: String, opciones: Array, titulo: String) -> void:
	var lt := p._texto(10, Principal.COL_SUAVE)
	lt.text = titulo
	p._lista_gente.add_child(lt)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 4)
	p._lista_gente.add_child(flow)
	for f: Array in opciones:
		var clave := String(f[0])
		var b := Button.new()
		b.text = String(f[1])
		b.add_theme_font_size_override("font_size", 10)
		b.toggle_mode = true
		b.button_pressed = String(co.get(prop)) == clave
		b.clip_text = true
		b.custom_minimum_size = Vector2(84, 22)
		b.pressed.connect(func() -> void:
			co.set(prop, clave)
			p._refrescar())
		flow.add_child(b)
