class_name PresetsTacticaUI
extends RefCounted
## Los presets de pizarra con nombre en la pestaña de táctica (fila 382): guardar la pizarra actual con un nombre, cargar uno con un clic y borrarlo.
## La lógica está en `PresetsTactica` (nucleo); aquí solo se pintan los botones.

static func pintar(p: Principal, c: Club) -> void:
	var presets: PresetsTactica = p.mundo.roles.presets_tactica
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("PRESETS DE PIZARRA")
	p._lista_tactica.add_child(t)
	var fila := VBoxContainer.new()   ## en vertical: la columna de táctica es estrecha y en una fila el botón de guardar quedaba cortado
	fila.add_theme_constant_override("separation", 4)
	p._lista_tactica.add_child(fila)
	var campo := LineEdit.new()
	campo.placeholder_text = Idiomas.t("Nombre del preset")
	campo.max_length = PresetsTactica.LARGO_NOMBRE
	campo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	campo.name = "NombrePreset"
	fila.add_child(campo)
	var guardar := Button.new()
	guardar.text = Idiomas.t("Guardar pizarra")
	guardar.clip_text = true
	guardar.add_theme_font_size_override("font_size", 11)
	guardar.name = "GuardarPreset"
	guardar.pressed.connect(func() -> void:
		var r := presets.guardar(campo.text, c.tactica)
		p._escribir(("[color=#4caf6d]%s[/color]" % (Idiomas.t("Pizarra guardada como «%s».") % PresetsTactica.limpiar_nombre(campo.text))) if r == "" else ("[color=#e05555]%s[/color]" % r))
		p._refrescar())
	fila.add_child(guardar)
	var nombres := presets.nombres()
	if nombres.is_empty():
		var vacio := p._texto(11, Principal.COL_SUAVE)
		vacio.text = Idiomas.t("Aún no has guardado ninguna. Deja la pizarra como te gusta, ponle nombre y guárdala.")
		vacio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_tactica.add_child(vacio)
	for n: String in nombres:
		var f := HBoxContainer.new()
		f.add_theme_constant_override("separation", 4)
		p._lista_tactica.add_child(f)
		var x := Button.new()
		x.text = "🗑"
		x.tooltip_text = Idiomas.t("Borrar este preset")
		x.pressed.connect(func() -> void:
			presets.borrar(n)
			p._escribir("[color=#c9a227]%s[/color]" % (Idiomas.t("Preset «%s» borrado.") % n))
			p._refrescar())
		f.add_child(x)
		var b := Button.new()
		b.text = n
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		b.custom_minimum_size = Vector2(60, 0)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.tooltip_text = Idiomas.t("Cargar este preset: %s") % String((presets.datos[n] as Dictionary).get("formacion", ""))
		b.add_theme_font_size_override("font_size", 12)
		b.pressed.connect(func() -> void:
			var r := presets.cargar(n, c)
			p._escribir(("[color=#4caf6d]%s[/color]" % (Idiomas.t("Pizarra «%s» cargada.") % n)) if r == "" else ("[color=#e05555]%s[/color]" % r))
			p._refrescar())
		f.add_child(b)
	p._lista_tactica.add_child(HSeparator.new())
