extends Control
## LA RUEDA DE PRENSA 2D (fase 0, paso 6b: sale de `Principal`, capas 2/17 y de
## `PantallaDespacho`, capa 2/2).
##
## Una sola responsabilidad: la cinemática de pantalla completa de la rueda -plató
## 3D, pregunta, "cómo lo dices", opciones, texto libre y reloj de titubeo-, con
## su estado propio. Principal solo la abre (`_abrir_rueda_pantalla_completa(e)`)
## y guarda la que está abierta en `_rueda_pop`; los métodos viejos
## (`_repintar_posturas()`, `_responder(i)`, `_rueda_desde`) quedan como puentes
## para las pruebas y capturas que ya los usan.
##
## Es el propio `Control` modal (antes era un `Control` suelto que armaba
## Principal): sus hijos siguen siendo [fondo, raiz] y en la raíz la fila de
## posturas sigue en el índice 2, como esperan las capturas.
##
## Cómo se usa: `var r := _PrincipalRuedaPrensa.new(p); p.add_child(r); r.abrir(e)`. Se
## cuelga del árbol ANTES de `abrir()` porque el plató 3D se monta ya dentro.

var p: Principal
## Lo que la repregunta cambia sin rehacer el plató (B5).
var _quien: Label
var _pregunta: Label
var _opciones: VBoxContainer
var _reloj: ProgressBar
## Cuándo salió la pregunta en pantalla (ms), para medir el titubeo.
var desde := 0

func _init(principal: Principal = null) -> void:
	p = principal
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group(MentorVoz.GRUPO_TAPA)

## Se cierra y deja libre el hueco de Principal (`_rueda_pop`).
func cerrar() -> void:
	if p != null and p._rueda_pop == self:
		p._rueda_pop = null
	queue_free()

## Contesta la opción `i` (los botones numerados y los atajos).
func responder(i: int) -> void:
	tras_responder(p.mundo.prensa.responder(i, segundos()))

## Repinta solo la fila de posturas -el botón que se marca al tocar una-, sin
## tocar el plató 3D ni las opciones.
func repintar_posturas() -> void:
	var raiz := get_child(1) as VBoxContainer
	if raiz == null or raiz.get_child_count() < 3:
		return
	var vieja := raiz.get_child(2)
	raiz.remove_child(vieja)
	vieja.queue_free()
	raiz.add_child(_fila_posturas())
	raiz.move_child(raiz.get_child(raiz.get_child_count() - 1), 2)


## LA RUEDA DE PRENSA, DE PANTALLA COMPLETA.
##
## El usuario la comparó con la conferencia de prensa de FC26 -pantalla
## entera, cámara y todo lo demás oculto mientras dura- y marcó que "eso
## debería tener su propio lugar". La primera versión la encogía dentro de
## la misma tarjetita de "asuntos pendientes" que comparte con el agente que
## presiona o el jugador que te busca: un `SubViewport` de 900×360 compitiendo
## por espacio con la barra superior y la tabla de posiciones. Ahora es una
## cinemática de pantalla completa, MISMO PATRÓN que `Sorteo`
## (`ui/principal/sorteos.gd`): un `Control` colgado
## directo de `self`, por encima de todo, que se cierra solo al responder.
##
## SIGUE SIN INVENTAR DIÁLOGO. La pregunta, las opciones y el "cómo lo dices"
## son exactamente los mismos datos de siempre (`Prensa.entrevista`); esto
## solo cambia DÓNDE se presentan.
func abrir(e: Dictionary) -> void:
	var pop: Control = self

	var fondo := ColorRect.new()
	fondo.color = Color(0.035, 0.038, 0.045)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	pop.add_child(fondo)

	var raiz := VBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.offset_left = 48.0; raiz.offset_right = -48.0
	raiz.offset_top = 28.0; raiz.offset_bottom = -28.0
	raiz.add_theme_constant_override("separation", 10)
	pop.add_child(raiz)

	var t := p._texto(13, p.COL_ACENTO)
	t.text = Idiomas.t("🎙️ RUEDA DE PRENSA")
	raiz.add_child(t)

	## EL PLATÓ 3D. Con pantalla completa ya no hace falta encogerlo a 220 px
	## de alto: se le da la mayor parte del espacio -`SIZE_EXPAND_FILL`- y una
	## resolución de `SubViewport` bastante mayor, para que se note el salto.
	var caja := Control.new()
	caja.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caja.clip_contents = true
	raiz.add_child(caja)

	var vp_cont := SubViewportContainer.new()
	vp_cont.stretch = true
	vp_cont.set_anchors_preset(Control.PRESET_FULL_RECT)
	vp_cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_child(vp_cont)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = false
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.size = Vector2i(1600, 720)
	vp_cont.add_child(vp)
	var escena := RuedaPrensaEscena3D.new()
	vp.add_child(escena)
	var mio := p.mundo.mi_club()
	## QUIÉN HABLA DE VERDAD (14-9-2026). Si el jugador no es él mismo el
	## entrenador -ayudante de campo, director deportivo, dueño con el banco
	## delegado-, `Roles.dt_empleado` no está vacío: es ESE quien da la rueda
	## de prensa, no el jugador -mostrar tu propia cara ahí sería que el dueño
	## del club diera la conferencia técnica en tu lugar-. El empleado no
	## tiene editor de aspecto propio -nadie personaliza a alguien que no
	## eres tú-, así que `CaraDT.look_de_nombre()` le da uno determinístico
	## por su nombre: el mismo empleado siempre sale igual.
	var nombre_dt := ""
	var look_dt := {}
	if p.mundo.roles != null:
		if not p.mundo.roles.dt_empleado.is_empty():
			nombre_dt = p.mundo.roles.dt_nombre()
			look_dt = CaraDT.look_de_nombre(nombre_dt)
		else:
			nombre_dt = p.mundo.roles.nombre
			look_dt = p.mundo.roles.look_efectivo()
	## EL FONDO: los escudos de tu liga, no sponsors genéricos (14-9-2026). La
	## rueda de prensa solo se abre tras un partido de LIGA
	## (`Mundo.rueda_tras_resultado()`, ver `nucleo/prensa.gd`), así que la
	## competencia correspondiente es siempre tu propia liga.
	var clubes_competencia: Array = []
	## Tras una copa o un continental (C1), los escudos de ESA competición.
	if p.mundo.prensa != null and p.mundo.prensa.competicion_rueda != "liga" and not p.mundo.prensa.clubes_rueda.is_empty():
		clubes_competencia = p.mundo.prensa.clubes_rueda
	elif mio != null:
		var liga := p.mundo.liga_de(mio)
		if liga != null:
			clubes_competencia = liga.clubes
	if mio != null:
		escena.montar(mio, p.COL_ACENTO, Calidad.ALTO, look_dt, clubes_competencia)

	## LA PLACA DEL DT, arriba a la izquierda -mismo "chyron" con foto y
	## nombre que pone cualquier transmisión de verdad cuando habla alguien-.
	if not nombre_dt.is_empty():
		var placa := PanelContainer.new()
		placa.set_anchors_preset(Control.PRESET_TOP_LEFT)
		placa.offset_left = 14.0; placa.offset_top = 14.0
		placa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb_placa := StyleBoxFlat.new()
		sb_placa.bg_color = Color(0, 0, 0, 0.6)
		sb_placa.content_margin_left = 8.0; sb_placa.content_margin_right = 12.0
		sb_placa.content_margin_top = 6.0; sb_placa.content_margin_bottom = 6.0
		sb_placa.corner_radius_top_left = 6; sb_placa.corner_radius_top_right = 6
		sb_placa.corner_radius_bottom_left = 6; sb_placa.corner_radius_bottom_right = 6
		placa.add_theme_stylebox_override("panel", sb_placa)
		caja.add_child(placa)
		var fila_placa := HBoxContainer.new()
		fila_placa.add_theme_constant_override("separation", 8)
		placa.add_child(fila_placa)
		var foto_dt := TextureRect.new()
		foto_dt.texture = CaraDT.textura(look_dt, 36)
		foto_dt.custom_minimum_size = Vector2(36, 36)
		foto_dt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		foto_dt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fila_placa.add_child(foto_dt)
		var nom_dt := p._texto(12, Principal.COL_TEXTO)
		nom_dt.text = nombre_dt
		nom_dt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fila_placa.add_child(nom_dt)

	## EL SUBTÍTULO, sobre la imagen -el "lower third" de la foto de Ancelotti
	## que mandó el usuario-. Alto fijo con `offset_top` negativo, no un
	## preset a secas: un `Control` no recorta a sus hijos solo, y un preset
	## sin offset propio da alto CERO justo donde termina la caja, así que el
	## contenido se derrama hacia abajo -se vio en la primera captura, tapando
	## los controles de más abajo-.
	var subt := PanelContainer.new()
	subt.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	subt.offset_top = -84.0
	subt.offset_bottom = 0.0
	subt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.72)
	sb.content_margin_left = 18.0; sb.content_margin_right = 18.0
	sb.content_margin_top = 10.0; sb.content_margin_bottom = 10.0
	subt.add_theme_stylebox_override("panel", sb)
	caja.add_child(subt)
	var col_subt := VBoxContainer.new()
	col_subt.add_theme_constant_override("separation", 3)
	subt.add_child(col_subt)
	var quien := p._texto(11, p.COL_ACENTO)
	col_subt.add_child(quien)
	var q := p._texto(15, Principal.COL_TEXTO)
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col_subt.add_child(q)
	_quien = quien
	_pregunta = q

	raiz.add_child(_fila_posturas())
	_opciones = _fila_opciones(e)
	raiz.add_child(_opciones)
	raiz.add_child(_fila_texto_libre())
	## EL RELOJ DE LA SALA (B5, "lenguaje corporal"): una barra que se llena en
	## `Prensa.TITUBEO_SEG` segundos. Cuando se llena, contestar ya cuenta como
	## titubeo. Se ve para que no sea una trampa.
	var reloj := ProgressBar.new()
	reloj.show_percentage = false
	reloj.custom_minimum_size = Vector2(0, 6)
	reloj.max_value = Prensa.TITUBEO_SEG
	raiz.add_child(reloj)
	_reloj = reloj
	pintar_pregunta(e)

## Repinta solo la fila de posturas -el botón que se marca al tocar una-, sin


## La pregunta en pantalla y el reloj a cero. La usa también la repregunta,
## que cambia el texto sin rehacer el plató 3D.
func pintar_pregunta(e: Dictionary) -> void:
	var quien_txt := String(e.get("quien", "Periodista"))
	var per := String(e.get("periodista", ""))
	if per != "":
		var rel := p.mundo.prensa.relacion_con(per)
		var trato := Idiomas.t("te aprecia") if rel >= 65 else (Idiomas.t("no te quiere") if rel <= 35 else Idiomas.t("sin bando"))
		quien_txt += "  ·  %s, %s" % [Idiomas.t(String(e.get("perfil", ""))), trato]
	if bool(e.get("memoria", false)):
		quien_txt += Idiomas.t("  ·  🧠 recuerda lo que dijiste")
	_quien.text = "🎙️ " + quien_txt.to_upper()
	_pregunta.text = String(e.get("pregunta", ""))
	desde = Time.get_ticks_msec()
	if is_instance_valid(_reloj):
		_reloj.value = 0.0
		_reloj.modulate = Color.WHITE
		var tw := _reloj.create_tween()
		tw.tween_property(_reloj, "value", Prensa.TITUBEO_SEG, Prensa.TITUBEO_SEG)
		tw.tween_callback(func() -> void:
			if is_instance_valid(_reloj):
				_reloj.modulate = Tema.MAL)
		_reloj.set_meta("tween", tw)

func segundos() -> float:
	return float(Time.get_ticks_msec() - desde) / 1000.0

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
		b2.custom_minimum_size = Vector2(0, 42)
		## Mismo estilo que los diálogos (13-10-2026): píldora con borde dorado
		## al pasar, numerada.
		CuadroDialogo.respuesta(b2)
		b2.text = "%d.  %s" % [i + 1, b2.text]
		b2.add_theme_font_size_override("font_size", 15)
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
		Sonido.toca("cambio", Sonido.Bus.INTERFAZ)
		return
	## Se cierra la cinemática -ya respondiste, no hay nada más que ver- y se
	## vuelve al juego normal.
	cerrar()
	p._refrescar()

## Responder con tus palabras. El tono lo decide `Prensa.clasificar_respuesta()`
## por palabras clave, en local: nada sale del ordenador.
func _fila_texto_libre() -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
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
	return fila

## "Cómo lo dices". Vive aparte de `abrir()` porque
## se repinta sola al tocar una postura -sin cerrar ni reabrir el plató 3D
## entero, que sería tirar y rehacer el `SubViewport` por nada-.
func _fila_posturas() -> HBoxContainer:
	var posturas := HBoxContainer.new()
	posturas.add_theme_constant_override("separation", 6)
	var et := p._texto(11, Principal.COL_SUAVE)
	et.text = Idiomas.t("Cómo lo dices:")
	et.custom_minimum_size = Vector2(96, 0)
	posturas.add_child(et)
	var lista_cuerpos: Dictionary = p.mundo.prensa.cuerpos()
	for k: String in lista_cuerpos:
		var datos: Array = lista_cuerpos[k]
		var b := Button.new()
		b.text = "%s %s" % [String(datos[0]), String(datos[1])]
		b.toggle_mode = true
		b.button_pressed = (k == p.mundo.prensa.cuerpo)
		b.add_theme_font_size_override("font_size", 11)
		b.pressed.connect(func() -> void:
			p.mundo.prensa.fijar_cuerpo(k)
			repintar_posturas())
		posturas.add_child(b)
	return posturas
