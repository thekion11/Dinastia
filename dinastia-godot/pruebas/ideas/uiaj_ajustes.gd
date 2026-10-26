extends BaseIdea
## uiaj · AJUSTES: vídeo con «¿mantener?» y vuelta atrás, accesibilidad con vista
## previa, y la pausa del DT manejable con mando. Usa la pantalla principal de
## verdad (`escenas/principal.tscn`) y pulsa sus controles.

var _p: Principal

func _ready() -> void:
	await get_tree().process_frame
	await _probar_async()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _todos(raiz: Node, tipo: String) -> Array:
	return raiz.find_children("*", tipo, true, false)

func _etiqueta(raiz: Node, texto: String) -> Label:
	for l: Label in _todos(raiz, "Label"):
		if l.text == texto:
			return l
	return null

func _pintar(secc: String) -> void:
	_p._secc_ajustes = secc
	_p._ui_ajustes._pintar_ajustes()
	await _frames(2)

func _probar_async() -> void:
	_titulo("uiaj: ajustes de vídeo, accesibilidad y pausa del DT")
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	await _frames(8)
	_p.call("_elegir_grupo", "ajustes")
	await _frames(2)
	var raiz_ventana := get_tree().root
	var zoom0 := _p._zoom_interfaz
	var factor0 := raiz_ventana.content_scale_factor

	## 1) Tamaño de la interfaz: se aplica al momento y pregunta; «Deshacer» vuelve.
	await _pintar("pantalla")
	var sl: HSlider = null
	for s: HSlider in _todos(_p._lista_ajustes, "HSlider"):
		if is_equal_approx(s.min_value, 0.8) and is_equal_approx(s.max_value, 1.4):
			sl = s
	_comprobar(sl != null, "Pantalla tiene el deslizador del tamaño de la interfaz")
	if sl == null:
		return
	sl.value = 1.2
	await _frames(1)
	var c := ConfirmarVideo.abierta_en(_p)
	_comprobar(is_equal_approx(raiz_ventana.content_scale_factor, 1.2), "el tamaño se aplica al momento (vista previa)")
	_comprobar(c != null, "y se pregunta «¿Mantener este cambio?»")
	sl.value = 1.25
	await _frames(1)
	_comprobar(ConfirmarVideo.abierta_en(_p) == c, "seguir arrastrando reutiliza la misma pregunta (no apila diálogos)")
	if c != null:
		c.deshacer()
	await _frames(2)
	_comprobar(is_equal_approx(raiz_ventana.content_scale_factor, factor0) and is_equal_approx(_p._zoom_interfaz, zoom0),
		"«Deshacer» vuelve al tamaño de antes de empezar a arrastrar (%.2f)" % raiz_ventana.content_scale_factor)
	_comprobar(ConfirmarVideo.abierta_en(_p) == null, "y la pregunta se cierra")

	## 2) Modo televisión: «Mantener» lo deja; luego se apaga y se deja por cuenta atrás.
	var b_tv: Button = null
	var et_tv := _etiqueta(_p._lista_ajustes, Idiomas.t("Modo televisión"))
	if et_tv != null:
		for h in et_tv.get_parent().get_children():
			if h is Button:
				b_tv = h
	_comprobar(b_tv != null, "Pantalla tiene el botón del modo televisión")
	if b_tv != null:
		var tv0 := _p._modo_tv
		b_tv.pressed.emit()
		await _frames(2)
		var c2 := ConfirmarVideo.abierta_en(_p)
		_comprobar(_p._modo_tv != tv0 and c2 != null, "el modo televisión se aplica y pregunta")
		if c2 != null:
			c2._queda = 0.15
		## Sin contestar: la cuenta atrás lo deshace sola.
		var t0 := Time.get_ticks_msec()
		while ConfirmarVideo.abierta_en(_p) != null and Time.get_ticks_msec() - t0 < 3000:
			await _frames(1)
		_comprobar(_p._modo_tv == tv0 and is_equal_approx(_p._zoom_interfaz, zoom0), "sin respuesta, la cuenta atrás lo deshace sola")
	## «Mantener» deja el cambio.
	var hecho := [false]
	var c3 := ConfirmarVideo.pedir(_p, "prueba", func() -> void: hecho[0] = true)
	await _frames(1)
	c3.mantener()
	await _frames(2)
	_comprobar(not hecho[0] and ConfirmarVideo.abierta_en(_p) == null, "«Mantener» cierra sin deshacer")

	## 3) «ninguno» (mando conectado) se traduce.
	Idiomas.idioma = "en"
	await _pintar("pantalla")
	var ve := false
	for l: Label in _todos(_p._lista_ajustes, "Label"):
		if l.text.contains(": none"):
			ve = true
	Idiomas.idioma = "es"
	_comprobar(ve, "en inglés, «Mando conectado: ninguno» sale como «none»")

	## 4) Accesibilidad: vista previa del texto y de los colores, vibración, subtítulos.
	var esc0 := _p._escala_texto
	var dal0 := _p._daltonico
	_p._escala_texto = 1.30
	_p._daltonico = false
	await _pintar("acceso")
	var muestra := _etiqueta(_p._lista_ajustes, Idiomas.t("Así se leen las tablas, las fichas y las noticias con este tamaño."))
	_comprobar(muestra != null and muestra.get_theme_font_size("font_size") == 16, "la muestra de texto sale al 130 %% (12 → %d)" % (muestra.get_theme_font_size("font_size") if muestra else -1))
	var chips: Array = []
	for r: ColorRect in _todos(_p._lista_ajustes, "ColorRect"):
		chips.append(r.color)
	_comprobar(chips.has(Principal.COL_VERDE) and not chips.has(Principal.COL_VERDE_DALT), "sin daltonismo la muestra enseña el verde de siempre")
	_p._daltonico = true
	await _pintar("acceso")
	chips.clear()
	for r: ColorRect in _todos(_p._lista_ajustes, "ColorRect"):
		chips.append(r.color)
	_comprobar(chips.has(Principal.COL_VERDE_DALT) and not chips.has(Principal.COL_VERDE), "con la paleta para daltonismo la muestra cambia al azul cielo")
	_comprobar(_etiqueta(_p._lista_ajustes, Idiomas.t("Vibración del mando")) != null, "Accesibilidad tiene la vibración del mando")
	var vib0 := Mando.ayuda("vibracion")
	var b_suave: Button = null
	for b: Button in _todos(_p._lista_ajustes, "Button"):
		if b.text == Idiomas.t("Suave"):
			b_suave = b
	if b_suave != null:
		b_suave.pressed.emit()
	_comprobar(Mando.ayuda("vibracion") == "suave", "elegir «Suave» cambia la vibración del mando")
	Mando.fijar_ayuda("vibracion", vib0)
	var sub := false
	for l: Label in _todos(_p._lista_ajustes, "Label"):
		sub = sub or l.text.begins_with(Idiomas.t("Subtítulos: el juego no tiene voces. La narración del partido, la prensa y el vestuario ya salen siempre escritos.").substr(0, 10))
	_comprobar(sub, "y explica lo de los subtítulos")
	_p._escala_texto = esc0
	_p._daltonico = dal0
	await _pintar("acceso")

	## 5) La pausa del DT con mando: foco, ayuda y cuenta de cambios.
	var m := _p.mundo
	var par := m.proximo_partido()
	var pa := Partido.new(par[0], par[1])
	pa.preparar()
	var club: Club = pa.local
	var raiz := Control.new()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(raiz)
	var dt := PanelDTPartido.abrir(raiz, pa, club, null)
	await _frames(3)
	var vf := get_viewport().gui_get_focus_owner()
	_comprobar(vf == dt._seguir, "al abrir la pausa el foco está en «Seguir jugando» (A reanuda)")
	var sin_foco := 0
	for b: Button in _todos(dt, "Button"):
		if b.focus_mode == Control.FOCUS_NONE:
			sin_foco += 1
	_comprobar(sin_foco == 0, "todos los botones de la pausa se alcanzan con mando (%d sin foco)" % sin_foco)
	_comprobar(dt._estado.text != "", "la pausa explica cómo hacer un cambio")
	_comprobar(dt._titulo_banco.text.contains("0") and dt._titulo_banco.text.contains(str(Partido.MAX_CAMBIOS)), "y cuenta los cambios (%s)" % dt._titulo_banco.text)
	(dt._col_campo.get_child(dt._col_campo.get_child_count() - 1) as Button).pressed.emit()
	await _frames(3)
	var f2 := get_viewport().gui_get_focus_owner()
	_comprobar(f2 != null and f2.get_parent() == dt._col_banco and not (f2 as Button).disabled, "al elegir quién sale, el foco salta al banquillo")
	if f2 is Button:
		(f2 as Button).pressed.emit()
	await _frames(3)
	_comprobar(dt._titulo_banco.text.contains("1"), "tras el cambio la cuenta sube (%s)" % dt._titulo_banco.text)
	var f3 := get_viewport().gui_get_focus_owner()
	_comprobar(f3 != null and f3.get_parent() == dt._col_campo, "y el foco vuelve a los once del campo")
	raiz.queue_free()
	_p.queue_free()
	await _frames(2)
