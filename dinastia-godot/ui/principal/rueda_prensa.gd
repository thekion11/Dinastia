extends "res://ui/principal/rueda_prensa_base.gd"
## LA RUEDA DE PRENSA (fase 0, paso 6b: sale de `Principal`, capas 2/17 y de
## `PantallaDespacho`, capa 2/2).
##
## Una sola responsabilidad: la cinemática de pantalla completa de la rueda -plató
## 3D, pregunta, "cómo lo dices", opciones, texto libre y reloj de titubeo-, con
## su estado propio. Principal solo la abre (`_abrir_rueda_pantalla_completa(e)`)
## y guarda la que está abierta en `_rueda_pop`; los métodos viejos
## (`_repintar_posturas()`, `_responder(i)`, `_rueda_desde`) quedan como puentes
## para las pruebas y capturas que ya los usan.
##
## Es el propio `Control` modal. Hijos: [fondo, Plato (3D), Capa (interfaz)];
## en la capa, cabecera, Franja (pregunta) y Columna (respuestas).
##
## Cómo se usa: `var r := _PrincipalRuedaPrensa.new(p); p.add_child(r); r.abrir(e)`. Se
## cuelga del árbol ANTES de `abrir()` porque el plató 3D se monta ya dentro.

func _init(principal: Principal = null) -> void:
	p = principal
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group(MentorVoz.GRUPO_TAPA)

## Se cierra y deja libre el hueco de Principal (`_rueda_pop`).
##
## SALIDA SUAVE: el nodo se libera ya (las pruebas y Principal cuentan con
## ello), pero deja en su lugar un telón del mismo color que se desvanece en
## ~0,3 s, para que el juego no aparezca de golpe.
func cerrar() -> void:
	if p != null and p._rueda_pop == self:
		p._rueda_pop = null
	if p != null and is_inside_tree() and not Animar.reducidas():
		var telon := ColorRect.new()
		telon.color = COL_FONDO
		telon.set_anchors_preset(Control.PRESET_FULL_RECT)
		telon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(telon)
		var tw := telon.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(telon, "modulate:a", 0.0, 0.3)
		tw.tween_callback(telon.queue_free)
	queue_free()

## Contesta la opción `i` (los botones numerados y los atajos).
func responder(i: int) -> void:
	tras_responder(p.mundo.prensa.responder(i, segundos()))

## Repinta solo el bloque de posturas -el botón que se marca al tocar una-, sin
## tocar el plató 3D ni las opciones. Se cambia en su mismo sitio de la columna.
func repintar_posturas() -> void:
	if _posturas == null or not is_instance_valid(_posturas) or _posturas.get_parent() == null:
		return
	var vieja := _posturas
	var padre := vieja.get_parent()
	var idx := vieja.get_index()
	var f := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var tenia_foco := f != null and vieja.is_ancestor_of(f)
	padre.remove_child(vieja)
	vieja.queue_free()
	_posturas = _fila_posturas()
	padre.add_child(_posturas)
	padre.move_child(_posturas, idx)
	## Si el foco estaba en la fila vieja (ratón o Tab), pasa a la marcada.
	if tenia_foco or f == null:
		for b in _posturas.find_children("*", "Button", true, false):
			if (b as Button).button_pressed:
				(b as Button).grab_focus()

## LA RUEDA DE PRENSA, EN EL PLATÓ 3D (26-10, pedido del dueño).
##
## El plató (`RuedaPrensaEscena3D`: sala, DT en el atril, periodistas y la
## cámara que cambia de plano sola) ocupa TODA la pantalla, y la interfaz va
## encima como en una retransmisión, sin cajas apiladas:
##   - arriba a la izquierda, el rótulo y la placa del DT, pequeños;
##   - a la derecha, una columna semitransparente con las respuestas, el
##     «cómo lo dices», el texto libre (plegado) y el reloj discreto;
##   - abajo, la franja de televisión: periodista, medio y la pregunta.
## El plató se desplaza a la izquierda medio ancho de columna, para que el DT
## quede en el centro de lo que se ve y la columna no le tape la cara.
## Si no hay club (o el 3D no se puede montar), queda el fondo liso: respaldo.
##
## SIGUE SIN INVENTAR DIÁLOGO: los datos son los de `Prensa.entrevista`.
func abrir(e: Dictionary) -> void:
	z_index = 100
	clip_contents = true
	var fondo := ColorRect.new()
	fondo.color = COL_FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	_fondo = fondo
	_montar_plato()
	var capa := Control.new()
	capa.name = "Capa"
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(capa)
	capa.add_child(_cabecera())
	_franja = _franja_tv()
	capa.add_child(_franja)
	_columna = _columna_respuestas(e)
	capa.add_child(_columna)
	pintar_pregunta(e)
	_tapar_lo_demas()
	_entrar()
	Animar.aparecer(_opciones, 0.2)
	_enfocar.call_deferred()

## El plató 3D a pantalla completa (corrido medio ancho de columna).
func _montar_plato() -> void:
	var mio := p.mundo.mi_club()
	if mio == null:
		return
	var vp_cont := SubViewportContainer.new()
	vp_cont.name = "Plato"
	vp_cont.stretch = true
	vp_cont.set_anchors_preset(Control.PRESET_FULL_RECT)
	vp_cont.offset_left = -float(ANCHO_COLUMNA)
	vp_cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vp_cont)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = false
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp_cont.add_child(vp)
	var escena := RuedaPrensaEscena3D.new()
	vp.add_child(escena)
	## Tras una copa o un continental (C1), los escudos de ESA competición;
	## si no, los de tu liga.
	var clubes: Array = []
	if p.mundo.prensa != null and p.mundo.prensa.competicion_rueda != "liga" and not p.mundo.prensa.clubes_rueda.is_empty():
		clubes = p.mundo.prensa.clubes_rueda
	else:
		var liga := p.mundo.liga_de(mio)
		if liga != null:
			clubes = liga.clubes
	escena.montar(mio, p.COL_ACENTO, Calidad.ALTO, _look_dt(), clubes)

## QUIÉN HABLA DE VERDAD (14-9-2026): si el DT es un empleado (ayudante,
## director deportivo, dueño con el banco delegado), da él la rueda, con un
## aspecto fijo por su nombre; si no, tú con tu aspecto.
func _nombre_dt() -> String:
	if p.mundo.roles == null:
		return ""
	return p.mundo.roles.dt_nombre() if not p.mundo.roles.dt_empleado.is_empty() else p.mundo.roles.nombre

func _look_dt() -> Dictionary:
	if p.mundo.roles == null:
		return {}
	if not p.mundo.roles.dt_empleado.is_empty():
		return CaraDT.look_de_nombre(p.mundo.roles.dt_nombre())
	return p.mundo.roles.look_efectivo()

## Caja semitransparente común (columna, cabecera, franja).
static func _caja(alfa: float, radio: int, margen: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.025, 0.03, alfa)
	sb.set_corner_radius_all(radio)
	sb.content_margin_left = margen; sb.content_margin_right = margen
	sb.content_margin_top = margen * 0.7; sb.content_margin_bottom = margen * 0.7
	return sb

## Arriba a la izquierda: «RUEDA DE PRENSA» y la placa del DT (foto y nombre).
func _cabecera() -> Control:
	var placa := PanelContainer.new()
	placa.position = Vector2(MARGEN, MARGEN)
	placa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placa.add_theme_stylebox_override("panel", _caja(0.55, 8, 10.0))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	placa.add_child(fila)
	var nombre := _nombre_dt()
	if not nombre.is_empty():
		var foto := TextureRect.new()
		foto.texture = CaraDT.textura(_look_dt(), 32)
		foto.custom_minimum_size = Vector2(32, 32)
		foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		foto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fila.add_child(foto)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	fila.add_child(col)
	var t := p._texto(11, p.COL_ACENTO)
	t.text = Idiomas.t("🎙️ RUEDA DE PRENSA")
	t.uppercase = true
	col.add_child(t)
	if not nombre.is_empty():
		var nom := p._texto(13, Principal.COL_TEXTO)
		nom.text = nombre
		col.add_child(nom)
	return placa

## Abajo, a todo el ancho: la franja de televisión con periodista y pregunta.
func _franja_tv() -> PanelContainer:
	var franja := PanelContainer.new()
	franja.name = "Franja"
	franja.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	franja.offset_top = -float(ALTO_FRANJA)
	franja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := _caja(0.78, 0, 22.0)
	sb.border_width_top = 3
	sb.border_color = Color(p.COL_ACENTO, 0.7)
	franja.add_theme_stylebox_override("panel", sb)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	franja.add_child(col)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	col.add_child(fila)
	_quien = p._texto(14, p.COL_ACENTO)
	fila.add_child(_quien)
	_medio = p._texto(12, Principal.COL_SUAVE)
	_medio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_medio.clip_text = true
	_medio.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_medio.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fila.add_child(_medio)
	_pregunta = p._texto(19, Principal.COL_TEXTO)
	_pregunta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pregunta.max_lines_visible = 2
	_pregunta.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	col.add_child(_pregunta)
	return franja

## A la derecha, entre la cabecera y la franja: la columna de respuestas.
## Su alto es el de su contenido (sin caja vacía debajo); en el peor idioma
## mide ~380 px y el hueco libre a 1280×720 es de ~570, así que no llega a la
## franja (la prueba r6b lo comprueba).
func _columna_respuestas(e: Dictionary) -> PanelContainer:
	var caja := PanelContainer.new()
	caja.name = "Columna"
	caja.anchor_left = 1.0; caja.anchor_right = 1.0
	caja.offset_left = -float(ANCHO_COLUMNA + MARGEN); caja.offset_right = -float(MARGEN)
	caja.offset_top = float(MARGEN)
	caja.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	caja.add_theme_stylebox_override("panel", _caja(0.6, 10, 14.0))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	caja.add_child(v)
	var tit := p._texto(11, Principal.COL_SUAVE)
	tit.text = Idiomas.t("Tu respuesta")
	tit.uppercase = true
	v.add_child(tit)
	_opciones = _fila_opciones(e)
	v.add_child(_opciones)
	_posturas = _fila_posturas()
	v.add_child(_posturas)
	v.add_child(_fila_texto_libre())
	v.add_child(_fila_reloj())
	return caja

## Mientras dura, ni el panel de objetivos ni el mentor se ven (el mentor ya
## respeta `GRUPO_TAPA`); y la rueda vuelve al frente si Principal cuelga
## algo nuevo encima (los objetivos se crean al refrescar).
func _tapar_lo_demas() -> void:
	if is_instance_valid(p._panel_obj) and p._panel_obj.visible:
		p._panel_obj.visible = false
		_objetivos_ocultos = true
	if not p.child_entered_tree.is_connected(_al_frente):
		p.child_entered_tree.connect(_al_frente)

func _al_frente(n: Node) -> void:
	if n is PanelObjetivos:
		(n as Control).visible = false
		_objetivos_ocultos = true
	_subir.call_deferred()

func _subir() -> void:
	if get_parent() != null and not is_queued_for_deletion():
		get_parent().move_child(self, -1)

## Deshace `_tapar_lo_demas()` al irse (también si se libera sin `cerrar()`).
func _exit_tree() -> void:
	if p == null:
		return
	if p.child_entered_tree.is_connected(_al_frente):
		p.child_entered_tree.disconnect(_al_frente)
	if _objetivos_ocultos and is_instance_valid(p._panel_obj):
		p._panel_obj.visible = true


## La pregunta en pantalla y el reloj a cero. La usa también la repregunta,
## que cambia el texto sin rehacer el plató 3D.
func pintar_pregunta(e: Dictionary) -> void:
	## «Nombre · Medio» (y a veces «, a pie de campo» o «(repregunta)», que
	## vienen en castellano del núcleo): el nombre arriba, el resto al lado.
	var quien_txt := String(e.get("quien", Idiomas.t("Periodista")))
	var repregunta := quien_txt.ends_with(" (repregunta)")
	quien_txt = quien_txt.trim_suffix(" (repregunta)")
	var partes := quien_txt.split(" · ", true, 1)
	var extra: Array[String] = []
	if partes.size() > 1:
		extra.append(partes[1])
	if repregunta:
		extra.append(Idiomas.t("Repregunta"))
	var per := String(e.get("periodista", ""))
	if per != "":
		var rel := p.mundo.prensa.relacion_con(per)
		var trato := Idiomas.t("te aprecia") if rel >= 65 else (Idiomas.t("no te quiere") if rel <= 35 else Idiomas.t("sin bando"))
		extra.append("%s, %s" % [Idiomas.t(String(e.get("perfil", ""))), trato])
	if bool(e.get("memoria", false)):
		extra.append(Idiomas.t("  ·  🧠 recuerda lo que dijiste").trim_prefix("  ·  "))
	_quien.text = "🎙️ " + String(partes[0]).to_upper()
	if _medio != null:
		_medio.text = "  ·  ".join(extra)
	var pregunta := String(e.get("pregunta", ""))
	_pregunta.text = pregunta
	desde = Time.get_ticks_msec() + int(_lectura(pregunta) * 1000.0)
	if _atajos != null and _opciones != null:
		_atajos.text = Idiomas.t("1-%d o ↑↓ + Enter · LB/RB: tono") % _opciones.get_child_count()
	if is_instance_valid(_reloj):
		_reloj.value = 0.0
		_reloj.modulate = Color.WHITE

func _fila_opciones(e: Dictionary) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	var ops: Array = e.get("opciones", [])
	for i in ops.size():
		var op: Variant = ops[i]
		var b2 := Button.new()
		## Las opciones del guion son DICCIONARIOS -{txt, moral, confianza,
		## socios}-, no arrays ni cadenas: `String(op)` reventaba en cada rueda
		## de prensa y el boton se quedaba sin texto. No se veia porque la rueda
		## no llegaba a abrirse nunca en una partida de verdad.
		if op is Dictionary:
			b2.text = String((op as Dictionary).get("txt", ""))
		elif op is Array:
			b2.text = String((op as Array)[0])
		else:
			b2.text = str(op)
		b2.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b2.custom_minimum_size = Vector2(0, 40)
		## Salta de línea dentro de la columna en vez de salirse de ella.
		b2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		## Mismo estilo que los diálogos (13-10-2026): píldora con borde dorado
		## al pasar, numerada.
		CuadroDialogo.respuesta(b2)
		b2.text = "%d.  %s" % [i + 1, b2.text]
		b2.add_theme_font_size_override("font_size", 14)
		b2.pressed.connect(func() -> void: responder(i))
		col.add_child(b2)
	return col

func tras_responder(r: Dictionary) -> void:
	if r.is_empty():
		return
	## La frase y el "cómo" ya los escribe `Prensa.noticia`; aquí solo lo que
	## movió, que es lo que no dice la noticia.
	var col := "#4caf6d" if int(r.get("confianza", 0)) >= 0 else "#e05555"
	p._escribir("[color=%s]🎙 moral %+d · confianza %+d · socios %+d[/color]" % [
		col, int(r.get("moral", 0)), int(r.get("confianza", 0)), int(r.get("socios", 0))])
	## LA REPREGUNTA: el mismo plató, otra pregunta y otras opciones.
	if bool(r.get("sigue", false)) and is_instance_valid(self) and not is_queued_for_deletion() and p.mundo.prensa.hay_rueda():
		var e := p.mundo.prensa.entrevista
		var viejas := _opciones
		_opciones = _fila_opciones(e)
		viejas.add_sibling(_opciones)
		viejas.queue_free()
		pintar_pregunta(e)
		Animar.aparecer(_opciones)
		_enfocar.call_deferred()
		Sonido.toca("cambio", Sonido.Bus.INTERFAZ)
		return
	## Se cierra la cinemática -ya respondiste, no hay nada más que ver- y se
	## vuelve al juego normal.
	cerrar()
	p._refrescar()

## Responder con tus palabras. El tono lo decide `Prensa.clasificar_respuesta()`
## por palabras clave, en local: nada sale del ordenador.
## Va PLEGADO (26-10): un botón lo despliega, para no apilar un campo vacío
## bajo las opciones.
func _fila_texto_libre() -> VBoxContainer:
	var bloque := VBoxContainer.new()
	bloque.add_theme_constant_override("separation", 6)
	var abre := Button.new()
	abre.name = "AbrirTextoLibre"
	abre.text = Idiomas.t("✍️ Con tus palabras")
	abre.flat = true
	abre.alignment = HORIZONTAL_ALIGNMENT_LEFT
	abre.add_theme_font_size_override("font_size", 12)
	bloque.add_child(abre)
	var fila := HBoxContainer.new()
	fila.name = "TextoLibre"
	fila.visible = false
	fila.add_theme_constant_override("separation", 6)
	bloque.add_child(fila)
	var campo := LineEdit.new()
	campo.placeholder_text = Idiomas.t("…o responde con tus propias palabras")
	campo.max_length = 120
	campo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(campo)
	var b := Button.new()
	b.text = Idiomas.t("Responder")
	fila.add_child(b)
	var enviar := func(_t: String = "") -> void:
		if campo.text.strip_edges() != "":
			var dicho := campo.text
			campo.clear()   ## si llega la repregunta, el campo vuelve vacío
			tras_responder(p.mundo.prensa.responder_texto(dicho, segundos()))
	b.pressed.connect(func() -> void: enviar.call())
	campo.text_submitted.connect(enviar)
	abre.pressed.connect(func() -> void:
		fila.visible = not fila.visible
		if fila.visible:
			campo.grab_focus())
	return bloque

## "Cómo lo dices". Vive aparte de `abrir()` porque
## se repinta sola al tocar una postura -sin cerrar ni reabrir el plató 3D
## entero, que sería tirar y rehacer el `SubViewport` por nada-.
func _fila_posturas() -> VBoxContainer:
	var bloque := VBoxContainer.new()
	bloque.add_theme_constant_override("separation", 4)
	var et := p._texto(11, Principal.COL_SUAVE)
	et.text = Idiomas.t("Cómo lo dices:")
	bloque.add_child(et)
	## Fila que salta de línea: en alemán o polaco no se sale de la columna.
	var posturas := HFlowContainer.new()
	posturas.add_theme_constant_override("h_separation", 6)
	posturas.add_theme_constant_override("v_separation", 6)
	bloque.add_child(posturas)
	var lista_cuerpos: Dictionary = p.mundo.prensa.cuerpos()
	for k: String in lista_cuerpos:
		var datos: Array = lista_cuerpos[k]
		var b := Button.new()
		b.text = Idiomas.t("%s %s" % [String(datos[0]), String(datos[1])])
		b.toggle_mode = true
		b.button_pressed = (k == p.mundo.prensa.cuerpo)
		b.add_theme_font_size_override("font_size", 11)
		b.pressed.connect(func() -> void:
			p.mundo.prensa.fijar_cuerpo(k)
			repintar_posturas())
		posturas.add_child(b)
	return bloque
