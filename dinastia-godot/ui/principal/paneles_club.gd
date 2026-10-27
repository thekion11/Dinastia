class_name PanelesClub
extends RefCounted
## (fase 6, paso 7 del plan §7.1: sale de `Principal`, ui/principal_p16.gd, el 27-10-2026). `p` es la pantalla principal;
## sus miembros se usan como `p.x` y `Principal` conserva puentes de una línea con los nombres de siempre.

var p: Principal

func _init(principal: Principal) -> void:
	p = principal

## LA EQUIPACIÓN: la camiseta real si el club tiene una de las 1.102 que
## trajo el usuario, o el dibujo de siempre si no. Es la primera vez que
## cualquiera de las dos aparece en la interfaz 2D -hasta hoy solo el visor
## 3D las usaba, y solo la real, nunca el respaldo procedural.
func _pintar_equipacion(c: Club) -> void:
	p._lista_club.add_child(HSeparator.new())
	var t := p._texto(11, p.COL_SUAVE)
	t.text = Idiomas.t("EQUIPACIÓN")
	p._lista_club.add_child(t)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	p._lista_club.add_child(fila)
	var hay_real := Jersey.textura_real(c, 0) != null
	## EL SPONSOR A PECHO. `Jersey.svg_de()` ya tenía un parámetro `sp` para
	## esto desde que se escribió, pero nunca se llegó a leer -"el rasterizador
	## no pinta <text>, va encima como etiqueta de Godot" decía su propio
	## comentario, y esa etiqueta nunca se puso-. Ahora que existe `Marca` (el
	## logo real del sponsor, no solo su nombre) hay algo real que superponer:
	## el escudo del sponsor firmado, centrado sobre la camiseta procedural.
	## Solo tiene sentido en el dibujo procedural -una foto real de la
	## camiseta YA trae el sponsor de verdad impreso en la foto-.
	var auspicio := p.mundo.auspicio if p.mundo != null else null
	var contrato: Dictionary = auspicio.contrato if auspicio != null else {}
	for cual in 2:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		fila.add_child(col)
		var caja := Control.new()
		caja.custom_minimum_size = Vector2(72, 58)
		col.add_child(caja)
		var img := TextureRect.new()
		img.texture = Jersey.textura(c, cual, 128)
		img.set_anchors_preset(Control.PRESET_FULL_RECT)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		caja.add_child(img)
		if not hay_real and not contrato.is_empty():
			var logo := TextureRect.new()
			logo.texture = Marca.textura(String(contrato.get("marca", "")), String(contrato.get("color", "#e8b13a")), 24)
			logo.custom_minimum_size = Vector2(15, 15)
			logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
			## Centrado en el pecho de la camiseta -el dibujo de Jersey ocupa
			## el viewBox 64x52 centrado en la caja de 72x58, así que el pecho
			## cae un poco a la derecha y abajo del centro geométrico de la
			## caja entera.
			logo.set_anchors_preset(Control.PRESET_CENTER)
			logo.offset_left = -7.5; logo.offset_right = 7.5
			logo.offset_top = 3.0; logo.offset_bottom = 18.0
			caja.add_child(logo)
		var et := p._texto(10, p.COL_SUAVE)
		et.text = Idiomas.t("Titular") if cual == 0 else Idiomas.t("Alternativa")
		et.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(et)
	var nota := p._texto(11, p.COL_SUAVE if hay_real else p.COL_BORDE)
	nota.text = Idiomas.t("Foto real del club.") if hay_real else Idiomas.t("Sin foto real para este club: dibujo por color y estampado (%s).") % Jersey.kit_de(c)
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_club.add_child(nota)
	## Aquí solo se MIRA. El editor de verdad -diseño, colores, tela- vive en
	## Gente → Identidad, junto al escudo: es la misma pantalla que antes vivía
	## sin relación bajo "Comercial", movida el 10-9-2026 para que quien busque
	## "cambiar la camiseta" la encuentre en un solo sitio.
	var ir := Button.new()
	ir.text = Idiomas.t("🎨 Editar en Identidad")
	ir.add_theme_font_size_override("font_size", 11)
	ir.pressed.connect(func() -> void:
		p._secc_gente = "identidad"
		p._ir_a_pestana("Gente"))
	p._lista_club.add_child(ir)
## LA INFRAESTRUCTURA: las obras del club y la equipación que se ve en el
## campo. Lo que se construye, no lo que se contrata.
func _club_infra(c: Club) -> void:
	p._ui_club_vida._pintar_obras(c)
	_pintar_equipacion(c)
## MI CARRERA: qué eres en este club, qué te dejan tocar y qué llevas hecho.
## `_pintar_rol()` ya llama a `_pintar_carrera(r)` por dentro: aquí no se
## vuelve a llamar o saldría dos veces.
func _club_carrera(_c: Club) -> void:
	p._ui_finanzas._pintar_rol()
func _resolver(op: String) -> void:
	var r := p.mundo.prensa.resolver(op)
	var titulo := String(r.get("titulo", "Decisión tomada"))
	var cuerpo := String(r.get("cuerpo", ""))
	## Al registro ya lo escribe `Prensa.noticia` (ver `_conectar_noticias()`):
	## escribirlo aquí también lo duplicaba. Aquí solo el aviso destacado.
	if not r.is_empty():
		Aviso.mostrar(p, "contrato", "📰", titulo, cuerpo)
	p._refrescar()
func _pintar_decision(e: Dictionary) -> void:
	var v := p._ui_despacho._marco_aviso(p.COL_ORO)
	var t := p._texto(11, p.COL_ORO)
	t.text = Idiomas.t("HAY QUE DECIDIR")
	v.add_child(t)
	var fila_cuerpo := HBoxContainer.new()
	fila_cuerpo.add_theme_constant_override("separation", 12)
	v.add_child(fila_cuerpo)
	var txt_evento := String(e.get("txt", ""))
	var j: Jugador = null
	var pid := String(e.get("pid", ""))
	if pid != "" and p.mundo.mi_club() != null:
		for x: Jugador in p.mundo.mi_club().plantilla:
			if x.id == pid:
				j = x
	if j != null:
		fila_cuerpo.add_child(p._retrato(j, 56))
	else:
		## El primer carácter del texto es el emoji del tema (🎙️, 🕯️, 🚨...).
		var icono := Label.new()
		icono.text = txt_evento.substr(0, 2).strip_edges() if txt_evento != "" else "❗"
		icono.add_theme_font_size_override("font_size", 34)
		icono.custom_minimum_size = Vector2(56, 56)
		icono.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icono.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fila_cuerpo.add_child(icono)
	var txt := p._texto(13, p.COL_TEXTO)
	txt.text = txt_evento
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila_cuerpo.add_child(txt)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	v.add_child(fila)
	p._boton(String(e.get("opcion_a", "Sí")), func() -> void: _resolver("a"), fila)
	p._boton(String(e.get("opcion_b", "No")), func() -> void: _resolver("b"), fila)
	## Respuestas con el estilo de los diálogos (13-10-2026).
	for b in fila.get_children():
		if b is Button:
			CuadroDialogo.respuesta(b as Button)
			(b as Button).add_theme_font_size_override("font_size", 16)
	var clave := "%s|%s" % [String(e.get("id", "")), pid]
	if clave != p._decision_mostrada:
		p._decision_mostrada = clave
		Sonido.toca("notificacion" if Sonido.NOMBRES.has("notificacion") else "cambio", Sonido.Bus.INTERFAZ)
		var caja := v.get_parent() as Control
		if caja != null:
			(func() -> void: Animar.pulso(caja, 1.03)).call_deferred()
