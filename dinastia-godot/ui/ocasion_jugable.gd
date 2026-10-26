class_name OcasionJugable
extends "res://ui/ocasion_jugable_p1.gd"
## [Capa 2/2 de `ocasion_jugable.gd`] la pantalla: franjas de cine, botones con porcentajes, cuenta atrás y aviso del resultado.

# ---------------------------------------------------------------------------
#  LA PANTALLA
# ---------------------------------------------------------------------------

func _construir() -> void:
	## Franjas de cine arriba y abajo: se lee «pausa» sin tapar la jugada.
	for arriba: bool in [true, false]:
		var f := ColorRect.new()
		f.color = Color(0, 0, 0, 0.62)
		f.mouse_filter = Control.MOUSE_FILTER_IGNORE
		f.anchor_right = 1.0
		f.anchor_top = 0.0 if arriba else 1.0
		f.anchor_bottom = 0.0 if arriba else 1.0
		f.offset_top = 0.0 if arriba else -46.0
		f.offset_bottom = 46.0 if arriba else 0.0
		f.visible = false
		add_child(f)
		_franjas.append(f)
	_caja = PanelContainer.new()
	_caja.name = "OcasionCaja"
	var sb := Tema.caja(Color(0.04, 0.07, 0.05, 0.9), Tema.RADIO_GRANDE, Tema.ORO)
	sb.set_border_width_all(2)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	_caja.add_theme_stylebox_override("panel", sb)
	_caja.anchor_left = 0.5
	_caja.anchor_right = 0.5
	_caja.anchor_top = 1.0
	_caja.anchor_bottom = 1.0
	_caja.offset_left = -390
	_caja.offset_right = 390
	_caja.offset_top = -222
	_caja.offset_bottom = -58
	_caja.visible = false
	add_child(_caja)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	_caja.add_child(col)
	_cabecera = Tema.etiqueta(17, Tema.ORO)
	_cabecera.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_cabecera)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(fila)
	for k: String in CLAVES:
		var b := Button.new()
		b.name = "Ocasion_" + k
		b.custom_minimum_size = Vector2(236, 66)
		b.add_theme_font_size_override("font_size", 16)
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(elegir.bind(k))
		fila.add_child(b)
		_botones[k] = b
	_consejo = Tema.etiqueta(13, Tema.SUAVE)
	_consejo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_consejo)
	_barra = ProgressBar.new()
	_barra.show_percentage = false
	_barra.custom_minimum_size = Vector2(0, 6)
	_barra.max_value = OcasionesDT.SEGUNDOS_ELEGIR
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(1, 1, 1, 0.1)
	var lleno := StyleBoxFlat.new()
	lleno.bg_color = Tema.ORO
	_barra.add_theme_stylebox_override("background", fondo)
	_barra.add_theme_stylebox_override("fill", lleno)
	col.add_child(_barra)
	_aviso = Tema.etiqueta(30, Tema.TEXTO)
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_aviso.offset_top = 96
	_aviso.offset_left = -300
	_aviso.offset_right = 300
	_aviso.add_theme_constant_override("outline_size", 6)
	_aviso.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_aviso.modulate.a = 0.0
	add_child(_aviso)

func _franjas_visibles(si: bool) -> void:
	for f in _franjas:
		f.visible = si

func _pintar() -> void:
	var jd: Dictionary = _portador.get("jugador", {})
	var nom := Nombres.visible(String(jd.get("nombre", "")))
	_cabecera.text = Idiomas.t("⚡ OCASIÓN %d/%d · %d' · %s a %d m del arco") % [hechas, cupo, motor.minuto(),
		nom, int(round(float(_lect.get("dist_arco", 0.0))))]
	for k: String in CLAVES:
		var b: Button = _botones[k]
		b.visible = _lect.has(k)
		if not b.visible:
			continue
		var pr := int(round(float(_lect[k]["prob"]) * 100.0))
		var linea := ""
		match k:
			"tiro": linea = Idiomas.t("Tirar · %d %% de gol") % pr
			"conducir": linea = Idiomas.t("Conducir · %d %%") % pr
			"pase":
				var q := _jugador_3d(String(_lect["pase"]["receptor_id"]))
				var qn := Nombres.visible(String((q.get("jugador", {}) as Dictionary).get("nombre", "")))
				linea = Idiomas.t("Pase a %s · %d %%") % [qn.get_slice(" ", qn.get_slice_count(" ") - 1), pr]
		b.text = "[%s]  %s %s%s" % [TECLAS[k], ICONOS[k], linea, "  ⭐" if String(_lect["recomendada"]) == k else ""]
	_consejo.text = Idiomas.t("⭐ lo que recomienda el cuerpo técnico (si no eliges, lo hace él)")
	_barra.max_value = _t_elegir
	_barra.value = _t_elegir
	_caja.visible = true
	_franjas_visibles(true)
	var b0: Button = _botones[String(_lect["recomendada"])]
	b0.call_deferred("grab_focus")

func _avisar(resultado: String) -> void:
	var txt := ""
	match resultado:
		"gol": txt = Idiomas.t("⚽ ¡GOOOL!")
		"atajada": txt = Idiomas.t("🧤 ¡La saca el portero!")
		"poste": txt = Idiomas.t("🥅 ¡Al palo!")
		"fallo": txt = Idiomas.t("😩 Se va fuera")
		"perdida": txt = Idiomas.t("❌ Te la quitaron")
	if txt == "" or _aviso == null:
		return
	_aviso.text = txt
	_aviso.modulate.a = 1.0
	_t_aviso = 1.8
