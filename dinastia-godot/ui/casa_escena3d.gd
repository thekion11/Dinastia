class_name CasaEscena3D
extends "res://ui/casa_escena3d_p2.gd"
## [Capa 3/3 de `casa_escena3d.gd`] abrir

# --- la pantalla completa -----------------------------------------------------

## Abre la escena sobre `p` (principal), con las últimas noticias de la
## bandeja convertidas en publicaciones de redes.
static func abrir(p: Control, m: Mundo, _bandeja: Array = []) -> Control:
	var pop := Control.new()
	pop.set_anchors_preset(Control.PRESET_FULL_RECT)
	pop.mouse_filter = Control.MOUSE_FILTER_STOP
	p.add_child(pop)
	var fondo := ColorRect.new()
	fondo.color = Color(0.03, 0.035, 0.04)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	pop.add_child(fondo)
	var vp_cont := SubViewportContainer.new()
	vp_cont.stretch = true
	vp_cont.set_anchors_preset(Control.PRESET_FULL_RECT)
	vp_cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pop.add_child(vp_cont)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp_cont.add_child(vp)
	var escena := CasaEscena3D.new()
	vp.add_child(escena)
	var c := m.mi_club()
	var viv := m.vida.vivienda if m.vida != null else "casa"
	var tra := m.vida.transporte if m.vida != null else "micro"
	escena.m_actual = m
	escena.montar(viv, tra, m.roles.aspecto_3d() if m.roles != null else {},
		Color(c.color1) if c != null else Color("1f5fa8"), Color(c.color2) if c != null else Color.WHITE)

	## El rótulo de abajo a la izquierda: dónde vives.
	var rot := Tema.etiqueta(Tema.TAM_DESTACADO + 4, Tema.TEXTO, "%s %s" % [
		String(VidaDT.VIVIENDAS.get(viv, ["", 0, 0, "🏠"])[3]), String(VidaDT.VIVIENDAS.get(viv, ["Tu casa"])[0])])
	rot.add_theme_constant_override("outline_size", 8)
	rot.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	rot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	rot.offset_left = 36
	rot.offset_top = -70
	rot.offset_bottom = -30
	pop.add_child(rot)

	## LO QUE SE PUEDE HACER EN LA ESCENA (28-9-2026, "la escena debe ser
	## animada y poder interactuar"). La zona del 3D recoge el arrastre y la
	## rueda para la cámara libre.
	var zona := Control.new()
	zona.set_anchors_preset(Control.PRESET_FULL_RECT)
	zona.mouse_filter = Control.MOUSE_FILTER_PASS
	zona.gui_input.connect(func(ev: InputEvent) -> void:
		if not escena.libre:
			return
		if ev is InputEventMouseMotion and ((ev as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			escena.arrastrar((ev as InputEventMouseMotion).relative)
		elif ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			var bi := (ev as InputEventMouseButton).button_index
			if bi == MOUSE_BUTTON_WHEEL_UP:
				escena.acercar(-0.4)
			elif bi == MOUSE_BUTTON_WHEEL_DOWN:
				escena.acercar(0.4)
		elif ev is InputEventScreenDrag:
			escena.arrastrar((ev as InputEventScreenDrag).relative))
	pop.add_child(zona)
	var acciones := HBoxContainer.new()
	acciones.add_theme_constant_override("separation", 8)
	acciones.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	acciones.offset_left = 36
	acciones.offset_top = -124
	acciones.offset_bottom = -84
	pop.add_child(acciones)
	var b_cafe := Button.new()
	b_cafe.text = Idiomas.t("☕ Tomar un café")
	b_cafe.pressed.connect(escena.tomar_cafe)
	acciones.add_child(b_cafe)
	var b_mirar := Button.new()
	b_mirar.text = Idiomas.t("🌅 Mirar el paisaje")
	b_mirar.pressed.connect(escena.mirar_paisaje)
	acciones.add_child(b_mirar)
	var b_cam := Button.new()
	b_cam.text = Idiomas.t("🎥 Cámara libre")
	b_cam.toggle_mode = true
	b_cam.toggled.connect(func(si: bool) -> void:
		escena.libre = si
		b_cam.text = Idiomas.t("🎬 Planos de cine") if si else Idiomas.t("🎥 Cámara libre"))
	acciones.add_child(b_cam)
	var b_hora := Button.new()
	b_hora.text = Idiomas.t("🌙 Atardecer")
	b_hora.pressed.connect(func() -> void:
		b_hora.text = Idiomas.t("☀️ De día") if escena.alternar_hora() else Idiomas.t("🌙 Atardecer"))
	acciones.add_child(b_hora)
	var b_foto := Button.new()
	b_foto.text = Idiomas.t("📷 Foto")
	b_foto.pressed.connect(func() -> void: ModoFoto.abrir(pop, m.mi_club(), "en casa"))
	acciones.add_child(b_foto)
	## El móvil de verdad: Tribuna, interactivo (publicar, responder, me gusta).
	if m.redes != null:
		var tel := Telefono.crear(m, p.get("_bandeja") if p.get("_bandeja") != null else [])
		tel.estetica_cambiada.connect(escena.aplicar_funda.bind(m))
		tel.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
		tel.offset_left = -Telefono.ANCHO - 30
		tel.offset_right = -30
		tel.offset_top = 76
		tel.offset_bottom = -24
		pop.add_child(tel)
	var cerrar := Button.new()
	cerrar.text = Idiomas.t("✕ Volver")
	cerrar.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	cerrar.offset_left = -130
	cerrar.offset_right = -30
	cerrar.offset_top = 24
	cerrar.offset_bottom = 60
	cerrar.pressed.connect(pop.queue_free)
	pop.add_child(cerrar)
	return pop
