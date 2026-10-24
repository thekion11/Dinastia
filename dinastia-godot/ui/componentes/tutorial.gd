class_name Tutorial
extends "res://ui/componentes/tutorial_p2.gd"
## [Capa 3/3 de `tutorial.gd`] _construir_prologo, iniciar, fase, guion_actual, aspecto_actual, indice … (+3)

## EL PRÓLOGO: franjas de cine, el escudo, el lugar y la escena a máquina.
func _construir_prologo(mundo: Mundo, ctx: Dictionary) -> void:
	_prologo = Control.new()
	_prologo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_prologo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_prologo)
	var fondo := ColorRect.new()
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color(0.02, 0.03, 0.03, 0.96)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prologo.add_child(fondo)
	## Un velo con el color del club, que sube desde abajo.
	var c1 := Color(String(ctx["c1"]))
	var grad := Gradient.new()
	grad.set_color(0, Color(c1, 0.0))
	grad.set_color(1, Color(c1, 0.38))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	var velo := TextureRect.new()
	velo.texture = gt
	velo.stretch_mode = TextureRect.STRETCH_SCALE
	velo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prologo.add_child(velo)
	## Las franjas negras de cine.
	for arriba: bool in [true, false]:
		var f := ColorRect.new()
		f.color = Color.BLACK
		f.mouse_filter = Control.MOUSE_FILTER_IGNORE
		f.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if arriba else Control.PRESET_BOTTOM_WIDE)
		f.custom_minimum_size = Vector2(0, 66)
		## La de abajo crece hacia arriba: anclada al borde, crecer hacia
		## abajo la dejaría fuera de la pantalla.
		if not arriba:
			f.grow_vertical = Control.GROW_DIRECTION_BEGIN
		_prologo.add_child(f)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prologo.add_child(centro)
	## El mentor de cuerpo medio al lado de la escena: la persona que te está
	## esperando, antes de que hable.
	var fila_prologo := HBoxContainer.new()
	fila_prologo.add_theme_constant_override("separation", 28)
	fila_prologo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.add_child(fila_prologo)
	var ancho_texto := minf(720.0, get_viewport_rect().size.x - 48.0)
	if PersonaRealista.disponible() and get_viewport_rect().size.x > 900.0:
		var figura := PersonaRealista.retrato(_aspecto, Vector2i(250, 380), Color(0.03, 0.04, 0.04), "medio")
		figura.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila_prologo.add_child(figura)
		ancho_texto = minf(600.0, get_viewport_rect().size.x - 350.0)
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(ancho_texto, 0)
	v.add_theme_constant_override("separation", 16)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila_prologo.add_child(v)
	if mundo != null and mundo.mi_club() != null:
		var esc := TextureRect.new()
		esc.texture = Escudo.textura(mundo.mi_club(), 110)
		esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		esc.custom_minimum_size = Vector2(110, 110)
		esc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(esc)
	var lugar := Label.new()
	lugar.text = String(_guion.get("lugar", "")).to_upper()
	if int(ctx["anio"]) > 0:
		lugar.text += Idiomas.t("  ·  TEMPORADA %d") % int(ctx["anio"])
	lugar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lugar.add_theme_font_size_override("font_size", 13)
	lugar.add_theme_color_override("font_color", COL_ORO)
	v.add_child(lugar)
	_lbl_prologo = RichTextLabel.new()
	_lbl_prologo.bbcode_enabled = true
	_lbl_prologo.fit_content = true
	_lbl_prologo.scroll_active = false
	_lbl_prologo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lbl_prologo.add_theme_font_size_override("normal_font_size", 20)
	_lbl_prologo.add_theme_font_size_override("bold_font_size", 20)
	_lbl_prologo.add_theme_font_override("bold_font", _negrita())
	_lbl_prologo.add_theme_font_size_override("italics_font_size", 20)
	_lbl_prologo.add_theme_color_override("default_color", COL_TEXTO)
	v.add_child(_lbl_prologo)
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 14)
	v.add_child(fila)
	var saltar := Button.new()
	saltar.text = Idiomas.t("Saltar tutorial")
	saltar.flat = true
	saltar.add_theme_color_override("font_color", COL_SUAVE)
	saltar.pressed.connect(func() -> void: _terminar(false))
	fila.add_child(saltar)
	_btn_prologo = Button.new()
	_btn_prologo.text = Idiomas.t("Entrar ▸")
	_btn_prologo.custom_minimum_size = Vector2(150, 40)
	_btn_prologo.add_theme_font_size_override("font_size", 16)
	_btn_prologo.pressed.connect(pulsar_prologo)
	CuadroDialogo.respuesta(_btn_prologo)
	_btn_prologo.add_theme_font_size_override("font_size", 16)
	fila.add_child(_btn_prologo)
	## Un clic en cualquier parte acaba de escribir la escena.
	_prologo.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and _escribiendo:
			_completar_escritura())

# ---------------------------------------------------------------------------
#  INTERFAZ
# ---------------------------------------------------------------------------

func iniciar(principal: Node, modo: String, club: String) -> void:
	_principal = principal
	var mundo: Mundo = null
	if principal != null and "mundo" in principal:
		mundo = principal.get("mundo")
	var ctx := contexto(mundo, club)
	_modo = modo
	_guion = guion(modo, ctx)
	_aspecto = aspecto_mentor(modo, _guion["mentor"])
	_pasos = _guion["pasos"]
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	## Las cuatro sombras rodean el hueco del control resaltado: atenúan el
	## resto de la pantalla sin taparle los clics a nadie.
	for k in 4:
		var s := ColorRect.new()
		s.color = Color(0, 0, 0, 0.45)
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(s)
		_sombras.append(s)
	_marco = Panel.new()
	_marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var borde := StyleBoxFlat.new()
	borde.bg_color = Color(0, 0, 0, 0)
	borde.border_color = COL_ORO
	borde.set_border_width_all(3)
	borde.set_corner_radius_all(8)
	_marco.add_theme_stylebox_override("panel", borde)
	add_child(_marco)
	_construir_tarjeta(ctx)
	_construir_prologo(mundo, ctx)
	_tarjeta.visible = false
	_marco.visible = false
	_fase = "prologo"
	_escribir(_lbl_prologo, String(_guion["prologo"]))
	_sonar(String(_guion.get("sonido", "")))

func fase() -> String:
	return _fase

func guion_actual() -> Dictionary:
	return _guion

func aspecto_actual() -> Dictionary:
	return _aspecto

func indice() -> int:
	return _i

func misiones_cumplidas() -> int:
	return _cumplidas.size()

func escribiendo() -> bool:
	return _escribiendo

func _process(delta: float) -> void:
	## Siempre por encima: los hubs y los avisos se cuelgan de la misma raíz
	## después de nosotros.
	if get_parent() != null and get_index() != get_parent().get_child_count() - 1:
		move_to_front()
	_t += delta
	if _escribiendo:
		var lbl := _etiqueta_activa()
		if lbl != null:
			var total := lbl.get_total_character_count()
			lbl.visible_characters = mini(total, lbl.visible_characters + maxi(1, int(ceil(LETRAS_SEG * delta))))
			if lbl.visible_characters >= total:
				_completar_escritura()
	if _fase == "prologo":
		_btn_prologo.text = "▸▸" if _escribiendo else Idiomas.t("Entrar ▸")
		return
	var paso := paso_actual()
	## La misión se cumple cuando el jugador HACE la cosa: el paso pasa de
	## no-hecho a hecho. Si ya estaba hecho al llegar, primero tiene que dejar
	## de estarlo -si no, un paso se "cumpliría" solo sin que nadie tocara nada-.
	if _t_cumplida < 0.0 and paso.has("hecho") and not _cumplidas.has(_i) and _t > 0.3:
		var ahora := _hecho(paso)
		if ahora and not _hecho_al_entrar:
			_cumplidas[_i] = true
			_t_cumplida = _t
			PanelObjetivos.marcar_mision(_modo, String(paso["mision"]))
			_pintar_mision()
			_sonar("logro")
		elif not ahora:
			_hecho_al_entrar = false
	if _t_cumplida >= 0.0 and _t - _t_cumplida > 1.1:
		_t_cumplida = -1.0
		_mostrar(_i + 1)
		return
	_colocar()
