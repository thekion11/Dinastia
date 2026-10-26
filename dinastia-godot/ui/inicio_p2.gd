extends "res://ui/inicio_p1.gd"
## [Capa 2/3 de `inicio.gd`] _guardar_ajuste, _degradado, _pintar_banner, _actualizar_picker … (+11)

func _guardar_ajuste(k: String) -> void:
	var c := ConfigFile.new()
	c.load(CONFIG_RUTA)
	c.set_value("portada", "clave", k)
	c.save(CONFIG_RUTA)

## El degradado que hace legible el texto encima de la foto. La prensa tiene
## fondo claro -papel-, así que su degradado es claro y no negro: uno negro
## sobre un fondo de periódico se habría comido las letras oscuras igual.
func _degradado(k: String) -> GradientTexture2D:
	var g := Gradient.new()
	if k == "prensa":
		g.set_color(0, Color(0.937, 0.906, 0.847, 0.93))
		g.add_point(0.55, Color(0.937, 0.906, 0.847, 0.72))
		g.set_color(1, Color(0.937, 0.906, 0.847, 0.0))
	else:
		g.set_color(0, Color(0, 0, 0, 0.68))
		g.add_point(0.46, Color(0, 0, 0, 0.4))
		g.set_color(1, Color(0, 0, 0, 0.0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_LINEAR
	t.fill_from = Vector2(0, 1)
	t.fill_to = Vector2(0, 0)
	t.width = 4
	t.height = 200
	return t

# --- la portada ---------------------------------------------------------------

func _pintar_banner() -> void:
	## Se pide el doble de la resolución real y se deja que STRETCH_KEEP_ASPECT_
	## COVERED la encoja: es la misma regla que ya deja escrita Portada.gd para
	## la tabla y el plantel, y aquí el lienzo ocupa toda la pantalla.
	_fondo_banner.texture = _textura_de(_clave)
	_fondo_banner.self_modulate = _brillo_de(_clave)
	_overlay.texture = _degradado(_clave)
	_lbl_titulo.add_theme_color_override("font_color", Color(String(COLOR_TITULO.get(_clave, "eef3ee"))))
	_lbl_sub.add_theme_color_override("font_color", Color(String(COLOR_SUB.get(_clave, "3fa06a"))))
	_lbl_claim.add_theme_color_override("font_color", Color(String(COLOR_CLAIM.get(_clave, "c3d2c7"))))

func _actualizar_picker() -> void:
	var lista := rotacion()
	for i in mini(lista.size(), _fila_picker.get_child_count()):
		var b: Button = _fila_picker.get_child(i)
		b.button_pressed = (String(lista[i]) == _clave)

func _clave_tinte(k: String) -> void:
	var c := Color(String(TINTE.get(k, "ffffff")))
	for e: FondoParticulas in [_motas, _bokeh_fondo, _bokeh_banner]:
		if is_instance_valid(e):
			e.tenir(c)

func _tenir_particulas() -> void:
	_clave_tinte(_clave)

func _elegir(k: String) -> void:
	_clave = k
	_guardar_ajuste(k)
	_pintar_banner()
	_actualizar_picker()
	_tenir_particulas()
	if _reloj_portada != null:
		_reloj_portada.start()

func _construir_selector_portada(raiz: VBoxContainer) -> void:
	raiz.add_child(HSeparator.new())
	var panel_picker := _panel()
	raiz.add_child(panel_picker)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 14; v.offset_top = 10; v.offset_right = -14; v.offset_bottom = -10
	v.add_theme_constant_override("separation", 8)
	panel_picker.add_child(v)
	var t := _texto(11, COL_SUAVE)
	t.text = Idiomas.t("PORTADA DEL JUEGO")
	v.add_child(t)
	_fila_picker = HBoxContainer.new()
	_fila_picker.add_theme_constant_override("separation", 6)
	var scroll_picker := ScrollContainer.new()
	scroll_picker.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_picker.add_child(_fila_picker)
	v.add_child(scroll_picker)
	for k: String in rotacion():
		var b := Button.new()
		b.text = ("🖼 " + String(Fondo.TITULOS[k.substr(PREFIJO_FONDO.length())])) if k.begins_with(PREFIJO_FONDO) else String(Portada.TITULOS[k])
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(0, 32)
		b.pressed.connect(func() -> void: _elegir(k))
		_fila_picker.add_child(b)

# --- construcción ------------------------------------------------------------

func _construir() -> void:
	var fondo := ColorRect.new()
	fondo.color = COL_FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	## Detrás de toda la página, los 24 fondos de pantalla completa rotando
	## (dos capas para el fundido). Atenuados: el menú se tiene que leer.
	for k in 2:
		var tr := TextureRect.new()
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.self_modulate = Color(0.78, 0.78, 0.78)
		tr.modulate.a = 1.0 if k == 0 else 0.0
		add_child(tr)
		if k == 0:
			_pagina = tr
		else:
			_pagina2 = tr
	_i_pagina = int(Time.get_unix_time_from_system()) % Fondo.NOMBRES.size()
	_pagina.texture = Fondo.textura(String(Fondo.NOMBRES[_i_pagina]))

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	## Un margen a los lados sin gastar otro nodo por lado: un solo
	## MarginContainer envolviendo todo el contenido.
	var margen := MarginContainer.new()
	margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margen.add_theme_constant_override("margin_left", 24)
	margen.add_theme_constant_override("margin_right", 24)
	margen.add_theme_constant_override("margin_top", 20)
	margen.add_theme_constant_override("margin_bottom", 24)
	scroll.add_child(margen)

	var raiz := VBoxContainer.new()
	raiz.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	raiz.add_theme_constant_override("separation", 14)
	margen.add_child(raiz)

	_construir_banner(raiz)

	_panel_continuar = VBoxContainer.new()
	_panel_continuar.add_theme_constant_override("separation", 8)
	raiz.add_child(_panel_continuar)

	_construir_perfil(raiz)
	_construir_meta(raiz)
	_construir_datos_dt(raiz)

	_construir_selector_portada(raiz)

	## El fondo animado -"iniciarPhaserMenu()" del HTML-: motas de luz subiendo
	## despacio por toda la pantalla. Va la última, fuera del scroll -como el
	## canvas de Phaser, que flota encima de #main sin desplazarse con la
	## página- y cubriendo el viewport, no el contenido entero.
	## Etapa 1 (8-10-2026): DETRÁS del contenido (entre el fondo y el scroll).
	## Encima, las motas tapaban letras y botones como manchas blancas.
	_bokeh_fondo = FondoParticulas.new("bokeh")
	_bokeh_fondo.ajustar_area(get_viewport_rect().size)
	add_child(_bokeh_fondo)
	move_child(_bokeh_fondo, 3)
	_motas = FondoParticulas.new("motas")
	_motas.ajustar_area(get_viewport_rect().size)
	add_child(_motas)
	move_child(_motas, 4)

# --- arrancar partida ---------------------------------------------------------

func _hay_partida() -> bool:
	return not Partida.listar().is_empty()

func _dinero(n: int) -> String:
	return Eco.dinero(n)

func _continuar() -> void:
	var m := _mundo_guardado if _mundo_guardado != null else Partida.cargar("partida")
	if m == null:
		return
	Principal.mundo_a_cargar = m
	get_tree().change_scene_to_file("res://escenas/principal.tscn")

func _borrar_partida() -> void:
	Partida.borrar("partida")
	_mundo_guardado = null
	_actualizar_continuar()

## Exportar / importar / abrir otra partida (plan §10): siempre visible, porque
## importar tiene sentido justo cuando todavía no hay ninguna.
var _archivo_ui: PartidaArchivoUI

func _poner_botones_archivo() -> void:
	if _archivo_ui == null:
		_archivo_ui = PartidaArchivoUI.new()
		add_child(_archivo_ui)
		_archivo_ui.lista_cambiada.connect(_actualizar_continuar)
		_archivo_ui.abrir_pedido.connect(_abrir_partida)
	var fila := _archivo_ui.construir_botones()
	_panel_continuar.add_child(fila)
	## Debajo de la tarjeta de «Continuar», que se añade después.
	fila.move_to_front.call_deferred()

func _abrir_partida(nombre: String) -> void:
	var m := Partida.cargar(nombre)
	if m == null:
		return
	Principal.mundo_a_cargar = m
	get_tree().change_scene_to_file("res://escenas/principal.tscn")

# --- partida en curso ---------------------------------------------------------

## "PARTIDA EN CURSO" -`panelEstadoPartida()` del HTML-: escudo, club, la
## jornada en la que vas y un resumen corto, con Continuar/Borrar. Se carga la
## partida UNA vez -barata, ~50 ms medidos en el banco de pruebas- y se
## conserva para no leer el fichero dos veces si el jugador pulsa Continuar.
func _actualizar_continuar() -> void:
	for h in _panel_continuar.get_children():
		_panel_continuar.remove_child(h)
		h.free()
	_poner_botones_archivo()
	if not _hay_partida():
		return
	_mundo_guardado = Partida.cargar("partida")
	if _mundo_guardado == null:
		return
	var c := _mundo_guardado.mi_club()
	if c == null:
		return
	var caja := _panel()
	_panel_continuar.add_child(caja)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	fila.set_anchors_preset(Control.PRESET_FULL_RECT)
	fila.offset_left = 14; fila.offset_top = 10; fila.offset_right = -14; fila.offset_bottom = -10
	caja.add_child(fila)

	var escudo := TextureRect.new()
	escudo.texture = Escudo.textura(c, 40)
	escudo.custom_minimum_size = Vector2(40, 44)
	## Sin esto el escudo sale a su tamaño real de rasterizado -4x, para que
	## las curvas no salgan dentadas al escalar- en vez de los 40 px pedidos.
	escudo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	escudo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fila.add_child(escudo)

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 2)
	fila.add_child(v)
	var et := _texto(9, COL_ACENTO)
	et.text = Idiomas.t("PARTIDA EN CURSO")
	v.add_child(et)
	var nom := _texto(15, COL_TEXTO)
	nom.text = c.nombre
	v.add_child(nom)
	var l := _mundo_guardado.liga_de(c)
	var puesto := 0
	var pts := 0
	if l != null:
		var tabla := l.tabla()
		for i in tabla.size():
			if tabla[i]["club"] == c:
				puesto = i + 1
				pts = int(tabla[i]["pts"])
				break
	var resumen := _texto(11, COL_SUAVE)
	var trofeos := _mundo_guardado.directiva.trofeos.size() if _mundo_guardado.directiva != null else 0
	resumen.text = Idiomas.t("Año %d · %dº con %d pts · Caja %s · %d título(s)") % [
		_mundo_guardado.anio, puesto, pts, _dinero(c.saldo), trofeos]
	resumen.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(resumen)

	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 8)
	fila.add_child(botones)
	var bc := Button.new()
	bc.text = Idiomas.t("▶ Continuar")
	bc.custom_minimum_size = Vector2(110, 32)
	bc.pressed.connect(_continuar)
	botones.add_child(bc)
	var bx := Button.new()
	bx.text = "✕"
	bx.custom_minimum_size = Vector2(32, 32)
	bx.pressed.connect(_borrar_partida)
	botones.add_child(bx)

## Cada 30 s: la siguiente variante, fundida encima de la actual (1,4 s).
func _rotar_portada() -> void:
	if not is_inside_tree() or not is_visible_in_tree():
		return
	var lista := rotacion()
	var i := lista.find(_clave)
	var sig := String(lista[(i + 1) % lista.size()])
	_fondo_banner2.texture = _textura_de(sig)
	_fondo_banner2.self_modulate = _brillo_de(sig)
	_fondo_banner2.modulate.a = 0.0
	var tw := _fondo_banner2.create_tween()
	tw.tween_property(_fondo_banner2, "modulate:a", 1.0, 1.4).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void:
		_clave = sig
		_pintar_banner()
		_fondo_banner2.modulate.a = 0.0
		_actualizar_picker())
	_clave_tinte(sig)
