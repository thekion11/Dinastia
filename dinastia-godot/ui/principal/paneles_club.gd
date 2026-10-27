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

## Pasa al bloque de al lado. Es lo que usan L1/R1 del mando, las flechas del
## teclado y el arrastre con el dedo en Android: una sola puerta para las
## tres formas de pedir lo mismo.
func _bloque_vecino(paso: int) -> void:
	var i := p._indice_grupo(p._grupo_actual)
	var siguiente := (i + paso + Principal.GRUPOS.size()) % Principal.GRUPOS.size()
	## Se saltan los grupos que viven en el panel lateral.
	for _k in Principal.GRUPOS.size():
		if not MenuLateral.EN_PANEL.has(String(Principal.GRUPOS[siguiente]["id"])):
			break
		siguiente = (siguiente + paso + Principal.GRUPOS.size()) % Principal.GRUPOS.size()
	p._elegir_grupo(String(Principal.GRUPOS[siguiente]["id"]))
## Las columnas se alinean con un GridContainer, no rellenando con espacios: la
## fuente es proporcional y un "%-22s" no alinea nada.
func _rejilla(lista: VBoxContainer, columnas: int) -> GridContainer:
	p._limpiar(lista)
	var g := GridContainer.new()
	g.columns = columnas
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 3)
	lista.add_child(g)
	return g
func _fila_jugador(g: GridContainer, j: Jugador, columnas: Array, colores: Array) -> void:
	## La cara del jugador delante del nombre. Es lo que pedia el usuario hace
	## meses ("en la plantilla debe aparecer la cara del jugador") y es lo que
	## convierte una lista de nombres en un plantel.
	var celda := HBoxContainer.new()
	celda.add_theme_constant_override("separation", 5)
	var equipo: Club = p.mundo.clubes.get(j.club_id)
	var retrato := TextureRect.new()
	retrato.texture = Cara.textura(j, equipo.color1 if equipo else "#2b6b45",
		equipo.color2 if equipo else "#ffffff", 22)
	retrato.custom_minimum_size = Vector2(22, 22)
	retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	celda.add_child(retrato)
	var b := Button.new()
	b.text = columnas[0]
	b.flat = true
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_color_override("font_color", p._color_de_paleta(colores[0]))
	## Pulsar a un jugador hace DOS cosas: enseña su ficha a la derecha y salta
	## al plantel en el centro. Antes solo hacía lo primero, así que tocar a
	## alguien desde la enfermería o la cantera te dejaba mirando su ficha con
	## la pestaña equivocada delante, y había que ir a buscarlo a mano.
	b.pressed.connect(func() -> void:
		p._ver_ficha(j)
		p._ir_a_pestana("Mi plantel"))
	celda.add_child(b)
	g.add_child(celda)
	for i in range(1, columnas.size()):
		p._celda(g, columnas[i], colores[i], i >= 2)
func _fijar_modo_simulacion(comp: String, modo: String) -> void:
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(Principal.SECCION_SIMULACION, comp, modo)
	cfg.save(CajonAjustes.RUTA)
## El selector, encima del botón de jugar: cinco fichas y la explicación de la
## elegida. Cambiarla la guarda para esa competición.
func _selector_modo_partido(padre: Node) -> void:
	var comp := p._competicion_de_la_semana()
	## La frase entera por competición: con «DE %s» salía «DE EL TORNEO CONTINENTAL» y, en otro
	## idioma, el nombre de la competición se quedaba en castellano.
	var t := p._texto(11, p.COL_SUAVE)
	if comp == "copa":
		t.text = Idiomas.t("CÓMO QUIERES VER LOS PARTIDOS DE LA COPA")
	elif comp == "conti":
		t.text = Idiomas.t("CÓMO QUIERES VER LOS PARTIDOS DEL TORNEO CONTINENTAL")
	else:
		t.text = Idiomas.t("CÓMO QUIERES VER LOS PARTIDOS DE LA LIGA")
	padre.add_child(t)
	var fila := HFlowContainer.new()
	fila.add_theme_constant_override("h_separation", 6)
	fila.add_theme_constant_override("v_separation", 6)
	padre.add_child(fila)
	var actual := p._modo_simulacion(comp)
	var desc := p._texto(11, p.COL_SUAVE)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var grupo := ButtonGroup.new()
	for m: Array in Principal.MODOS_SIMULACION:
		var clave := String(m[0])
		var b := Button.new()
		b.text = String(m[1])
		b.toggle_mode = true
		b.button_group = grupo
		b.button_pressed = clave == actual
		b.tooltip_text = String(m[2])
		b.custom_minimum_size = Vector2(0, 30)
		b.pressed.connect(func() -> void:
			_fijar_modo_simulacion(comp, clave)
			desc.text = String(m[2]))
		fila.add_child(b)
		if clave == actual:
			desc.text = String(m[2])
	padre.add_child(desc)
func _pintar_pendientes() -> void:
	for cont: Variant in p._pendientes.keys():
		if not is_instance_valid(cont):
			p._pendientes.erase(cont)
			continue
		var ctl := cont as Control
		if ctl.is_visible_in_tree():
			var pintar: Callable = p._pendientes[cont]
			p._pendientes.erase(cont)
			pintar.call()
			p._traducir_pantalla(ctl)
## Candidatos: gente de otros clubes que mejora tu plantel. Se mira una muestra,
## no los 8.448 del mundo: recorrerlos todos para repintar una lista de 30 sería
## tirar el trabajo que costó que la simulación fuera rápida.
func _objetivos(mio: Club) -> Array[Jugador]:
	var media := mio.media()
	var vistos := {}
	var salida: Array[Jugador] = []
	var clubes: Array = p.mundo.clubes.values()
	for intento in 400:
		if salida.size() >= 30:
			break
		var otro: Club = clubes[Azar.ent(0, clubes.size() - 1)]
		if otro.id == mio.id or otro.plantilla.is_empty():
			continue
		var j: Jugador = otro.plantilla[Azar.ent(0, otro.plantilla.size() - 1)]
		if vistos.has(j.id) or float(j.ovr) < media:
			continue
		vistos[j.id] = true
		salida.append(j)
	salida.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	return salida
