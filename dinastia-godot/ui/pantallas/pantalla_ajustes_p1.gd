extends RefCounted
## [Capa 1/2 de `pantalla_ajustes.gd`] _init, _pintar_fotogramas, _color_pal, _pal_borde, _pintar_clima, _pintar_aspecto … (+5)

## AJUSTES DE INTERFAZ: fotogramas, clima, aspecto, accesibilidad, traspaso de partida y fondos.
##
## Sale de `ui/principal.gd` (mapa de metas 15: el archivo pasaba de
## 15.000 líneas). `p` es la pantalla principal: sus ayudantes (`p._texto`,
## `p._boton`...), el mundo (`p.mundo`) y el repintado (`p._refrescar()`).

var p: Principal

func _init(principal: Principal) -> void:
	p = principal

func _pintar_fotogramas() -> void:
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("FOTOGRAMAS POR SEGUNDO")
	p._lista_ajustes.add_child(t)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 4)
	p._lista_ajustes.add_child(fila)
	for v: int in Principal.FPS_OPCIONES:
		var valor := v
		var b := Button.new()
		b.text = Idiomas.t("sin límite") if valor == 0 else "%d" % valor
		b.add_theme_font_size_override("font_size", 11)
		b.toggle_mode = true
		b.button_pressed = p._fps_elegido == valor
		b.custom_minimum_size = Vector2(72, 0)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			p._fps_elegido = valor
			Engine.max_fps = valor
			p._refrescar())
		fila.add_child(b)
	## M-358: el contador de FPS en una esquina, en todas las escenas.
	var bf := Button.new()
	bf.text = Idiomas.t("Mostrar contador de FPS")
	bf.toggle_mode = true
	bf.button_pressed = ContadorFps.visible_pref
	bf.add_theme_font_size_override("font_size", 11)
	bf.toggled.connect(func(on: bool) -> void:
		ContadorFps.poner(p.get_tree(), on)
		p._guardar_preferencias())
	p._lista_ajustes.add_child(bf)
	if not p._modo_experto:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = Idiomas.t("Bajarlo alarga la batería del portátil y baja la temperatura. Para una interfaz, 30 se ve igual de bien; el estadio en 3D agradece 60.")
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_ajustes.add_child(ex)

	var fm := p._texto(10, Principal.COL_SUAVE)
	fm.text = Idiomas.t("Mando conectado: %s  ·  cruceta o stick para moverte, A para pulsar, B para volver, gatillos para cambiar de pestaña.") % (
		", ".join(Input.get_connected_joypads().map(func(i: int) -> String: return Input.get_joy_name(i)))
		if not Input.get_connected_joypads().is_empty() else Idiomas.t("ninguno"))
	fm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_ajustes.add_child(fm)
	p._lista_ajustes.add_child(HSeparator.new())

func _color_pal(i: int, por_defecto: Color) -> Color:
	var p_local: Array = Principal.PALETAS.get(p._paleta, [])
	if p_local.size() <= i:
		return por_defecto
	return Color(String(p_local[i]))

func _pal_borde() -> Color: return _color_pal(3, Principal.COL_BORDE)

## EL CLIMA. Diez, y ninguno es un fondo: son una capa de partículas que va
## por encima del dibujo, así que cualquiera de los veinticuatro fondos puede
## tener lluvia o confeti sin dibujar doscientos cuarenta fondos.
func _pintar_clima() -> void:
	var lc := p._texto(10, Principal.COL_SUAVE)
	lc.text = Idiomas.t("Clima encima del fondo")
	p._lista_ajustes.add_child(lc)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 4)
	p._lista_ajustes.add_child(flow)
	for k: String in FondoAnimado.MODOS:
		var clave := k
		var b := Button.new()
		b.text = String(FondoAnimado.MODOS[k])
		b.add_theme_font_size_override("font_size", 10)
		b.toggle_mode = true
		b.button_pressed = p._clima_elegido == clave
		b.clip_text = true
		b.custom_minimum_size = Vector2(118, 24)
		b.pressed.connect(func() -> void:
			p._clima_elegido = clave
			p._aplicar_fondo()
			p._refrescar())
		flow.add_child(b)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	p._lista_ajustes.add_child(fila)
	var et := p._texto(12, Principal.COL_TEXTO)
	et.text = Idiomas.t("El clima sigue al ratón")
	et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et.tooltip_text = Idiomas.t("El cursor inclina el viento: la lluvia se tuerce hacia donde miras y el confeti se va detrás. Apagado, cae recto.")
	fila.add_child(et)
	var b2 := Button.new()
	b2.text = "SÍ" if p._clima_interactivo else "NO"
	b2.pressed.connect(func() -> void:
		p._clima_interactivo = not p._clima_interactivo
		p._aplicar_fondo()
		p._refrescar())
	fila.add_child(b2)

func _pintar_aspecto() -> void:
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("🎨 ASPECTO DE LA INTERFAZ")
	p._lista_ajustes.add_child(t)
	if not p._modo_experto:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = Idiomas.t("Nada de esto cambia una sola regla del juego. El color de acento sigue saliendo de la identidad de tu club: lo que se elige aquí es el lienzo.")
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_ajustes.add_child(ex)

	var lp := p._texto(10, Principal.COL_SUAVE)
	lp.text = Idiomas.t("Paleta")
	p._lista_ajustes.add_child(lp)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 4)
	p._lista_ajustes.add_child(flow)
	for k: String in Principal.PALETAS:
		var clave := k
		var datos: Array = Principal.PALETAS[k]
		var b := Button.new()
		b.text = String(datos[0])
		b.add_theme_font_size_override("font_size", 10)
		b.toggle_mode = true
		b.button_pressed = p._paleta == clave
		b.clip_text = true
		b.custom_minimum_size = Vector2(104, 24)
		## El botón se pinta con SU paleta: se elige mirando, no leyendo.
		var muestra := StyleBoxFlat.new()
		muestra.bg_color = Color(String(datos[2]))
		muestra.border_color = Color(String(datos[3]))
		muestra.set_border_width_all(1)
		muestra.set_corner_radius_all(4)
		b.add_theme_stylebox_override("normal", muestra)
		b.add_theme_color_override("font_color", Color(String(datos[4])))
		b.pressed.connect(func() -> void:
			p._paleta = clave
			p._aplicar_aspecto()
			p._refrescar())
		flow.add_child(b)

	var lf := p._texto(10, Principal.COL_SUAVE)
	lf.text = Idiomas.t("Forma de las tarjetas")
	p._lista_ajustes.add_child(lf)
	var flow2 := HFlowContainer.new()
	flow2.add_theme_constant_override("h_separation", 4)
	p._lista_ajustes.add_child(flow2)
	for k2: String in Principal.FORMAS_TARJETA:
		var clave2 := k2
		var b2 := Button.new()
		b2.text = String((Principal.FORMAS_TARJETA[k2] as Array)[0])
		b2.add_theme_font_size_override("font_size", 10)
		b2.toggle_mode = true
		b2.button_pressed = p._forma_tarjeta == clave2
		b2.clip_text = true
		b2.custom_minimum_size = Vector2(96, 24)
		b2.pressed.connect(func() -> void:
			p._forma_tarjeta = clave2
			## La forma tambien manda en el radio de los botones y las pestanas, que
			## viven en el tema y no se rehacen al repintar.
			p._aplicar_aspecto()
			p._refrescar())
		flow2.add_child(b2)

	p._pintar_tipografia()
	var lm := p._texto(10, Principal.COL_SUAVE)
	lm.text = Idiomas.t("Marca de las tarjetas")
	p._lista_ajustes.add_child(lm)
	var flow3 := HFlowContainer.new()
	flow3.add_theme_constant_override("h_separation", 4)
	flow3.add_theme_constant_override("v_separation", 4)
	p._lista_ajustes.add_child(flow3)
	for k3: String in MarcaPanel.ESTILOS:
		var clave3 := k3
		var b3 := Button.new()
		b3.text = String(MarcaPanel.ESTILOS[k3])
		b3.add_theme_font_size_override("font_size", 10)
		b3.toggle_mode = true
		b3.button_pressed = p._marca_tarjeta == clave3
		b3.clip_text = true
		b3.custom_minimum_size = Vector2(130, 24)
		b3.pressed.connect(func() -> void:
			p._marca_tarjeta = clave3
			p._aplicar_aspecto()
			p._refrescar())
		flow3.add_child(b3)

	var fila_b := HBoxContainer.new()
	fila_b.add_theme_constant_override("separation", 8)
	p._lista_ajustes.add_child(fila_b)
	var et_b := p._texto(12, Principal.COL_TEXTO)
	et_b.text = Idiomas.t("Brillo en las tarjetas")
	et_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et_b.tooltip_text = Idiomas.t("El degradado cenital que le da aire de placa metálica. Sin él, las tarjetas son rectángulos planos.")
	fila_b.add_child(et_b)
	var b_b := Button.new()
	b_b.text = "SÍ" if p._brillo_tarjetas else "NO"
	b_b.pressed.connect(func() -> void:
		p._brillo_tarjetas = not p._brillo_tarjetas
		p._aplicar_aspecto()
		p._refrescar())
	fila_b.add_child(b_b)
	p._lista_ajustes.add_child(HSeparator.new())

## Recorre la pantalla y le da a cada tarjeta el color y la forma de la paleta
## nueva. Tambien enciende o apaga su brillo: es el hijo `TextureRect` que le
## cuelga `_panel()`, y se oculta en vez de borrarlo para que volver a encender
## el brillo no exija reconstruir nada.
func _repintar_tarjetas(n: Node) -> void:
	if n is PanelContainer and n.has_meta("tarjeta"):
		var p_local := n as PanelContainer
		var e := StyleBoxFlat.new()
		e.bg_color = p._pal_panel()
		e.border_color = _pal_borde()
		var forma: Array = Principal.FORMAS_TARJETA.get(p._forma_tarjeta, ["", 8, 1])
		e.set_border_width_all(int(forma[2]))
		e.set_corner_radius_all(int(forma[1]))
		p_local.add_theme_stylebox_override("panel", e)
		var tiene_marca := false
		for h in p_local.get_children():
			if h is TextureRect and (h as TextureRect).texture == Principal._brillo_panel:
				(h as TextureRect).visible = p._brillo_tarjetas
			elif h is MarcaPanel:
				(h as MarcaPanel).poner(p._marca_tarjeta, p.COL_ACENTO)
				tiene_marca = true
		## Una tarjeta creada cuando la marca estaba en «ninguno» no tiene el nodo:
		## se le cuelga ahora, o encender las escuadras solo valdria para lo que se
		## pintara despues.
		if not tiene_marca and p._marca_tarjeta != "ninguno":
			var mk2 := MarcaPanel.new()
			mk2.poner(p._marca_tarjeta, p.COL_ACENTO)
			p_local.add_child(mk2)
	for h2 in n.get_children():
		_repintar_tarjetas(h2)

func _pintar_accesibilidad() -> void:
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("ACCESIBILIDAD")
	p._lista_ajustes.add_child(t)

	var fila_tx := HBoxContainer.new()
	fila_tx.add_theme_constant_override("separation", 6)
	p._lista_ajustes.add_child(fila_tx)
	var et_tx := p._texto(12, Principal.COL_TEXTO)
	et_tx.text = Idiomas.t("Tamaño del texto")
	et_tx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila_tx.add_child(et_tx)
	for e: float in Principal.ESCALAS_TEXTO:
		var esc := e
		var b := Button.new()
		b.text = "%d%%" % int(round(esc * 100.0))
		b.add_theme_font_size_override("font_size", 11)
		b.toggle_mode = true
		b.button_pressed = is_equal_approx(p._escala_texto, esc)
		b.custom_minimum_size = Vector2(52, 0)
		b.pressed.connect(func() -> void:
			p._escala_texto = esc
			p._refrescar())
		fila_tx.add_child(b)
	AjustesAcceso.muestra_texto(p)

	var fila_d := HBoxContainer.new()
	fila_d.add_theme_constant_override("separation", 8)
	p._lista_ajustes.add_child(fila_d)
	var et_d := p._texto(12, Principal.COL_TEXTO)
	et_d.text = Idiomas.t("Paleta para daltonismo")
	et_d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et_d.tooltip_text = Idiomas.t("El verde y el rojo del juego pasan a azul cielo y bermellón, que se distinguen con cualquier daltonismo.")
	fila_d.add_child(et_d)
	var b_d := Button.new()
	b_d.text = "SÍ" if p._daltonico else "NO"
	b_d.pressed.connect(func() -> void:
		p._daltonico = not p._daltonico
		p._refrescar())
	fila_d.add_child(b_d)
	AjustesAcceso.muestra_colores(p)
	AjustesAcceso.animaciones(p)
	AjustesAcceso.vibracion(p)
	AjustesAcceso.nota_subtitulos(p)
	p._lista_ajustes.add_child(HSeparator.new())

	## EL MERCADO A CIEGAS. `Ojeadores.modo_ciego` estaba escrito, probado, con
	## su escala de palabras y hasta con una captura de pantalla propia en las
	## pruebas —y no había un solo botón para encenderlo en toda la interfaz.
	if p.mundo.ojeadores != null:
		var fila_c := HBoxContainer.new()
		fila_c.add_theme_constant_override("separation", 8)
		p._lista_ajustes.add_child(fila_c)
		var et_c := p._texto(12, Principal.COL_TEXTO)
		et_c.text = Idiomas.t("Mercado a ciegas")
		et_c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		et_c.tooltip_text = Idiomas.t("Sin medias numéricas de los rivales: solo palabras («crack», «bueno», «del montón») hasta que los ojees a fondo.")
		fila_c.add_child(et_c)
		var b_c := Button.new()
		b_c.text = "SÍ" if p.mundo.ojeadores.modo_ciego else "NO"
		b_c.pressed.connect(func() -> void:
			p.mundo.ojeadores.modo_ciego = not p.mundo.ojeadores.modo_ciego
			p._refrescar())
		fila_c.add_child(b_c)
		if not p._modo_experto:
			var ec := p._texto(10, Principal.COL_SUAVE)
			ec.text = Idiomas.t("Con esto encendido, la media de un jugador ajeno no es un número hasta que un ojeador lo mira tres veces. Cambia por completo cómo se ficha.")
			ec.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_ajustes.add_child(ec)
	p._lista_ajustes.add_child(HSeparator.new())

func _exportar_partida() -> void:
	## Se exporta el retrato en base64 y no el JSON en claro: el JSON de una
	## partida son varios megabytes de texto que ningún chat deja pegar de una
	## pieza, y comprimido cabe. Es el mismo formato del guardado en disco.
	var datos := Partida.instantanea(p.mundo)
	var crudo := JSON.stringify(datos).to_utf8_buffer()
	var comprimido := crudo.compress(FileAccess.COMPRESSION_DEFLATE)
	var cabecera := PackedByteArray()
	cabecera.resize(4)
	cabecera.encode_u32(0, crudo.size())
	var texto := Marshalls.raw_to_base64(cabecera + comprimido)
	var f := FileAccess.open(Principal.FICHERO_EXPORTADO, FileAccess.WRITE)
	if f != null:
		f.store_string(texto)
		f.close()
	DisplayServer.clipboard_set(texto)
	p._escribir("[color=#4caf6d]Partida exportada.[/color] Copiada al portapapeles y escrita en %s (%d KB de texto)." % [
		ProjectSettings.globalize_path(Principal.FICHERO_EXPORTADO), texto.length() / 1024])

func _importar_partida() -> void:
	var texto := DisplayServer.clipboard_get().strip_edges()
	if texto.length() < 32:
		p._escribir("[color=#e05555]No hay ninguna partida en el portapapeles.[/color] Copia primero el texto exportado.")
		return
	var bruto := Marshalls.base64_to_raw(texto)
	if bruto.size() < 8:
		p._escribir("[color=#e05555]Lo copiado no es una partida de DINASTÍA.[/color]")
		return
	var tamano := bruto.decode_u32(0)
	var cuerpo_b := bruto.slice(4)
	var crudo := cuerpo_b.decompress(tamano, FileAccess.COMPRESSION_DEFLATE)
	if crudo.is_empty():
		p._escribir("[color=#e05555]La partida copiada está incompleta o dañada.[/color]")
		return
	var leido: Variant = JSON.parse_string(crudo.get_string_from_utf8())
	if not (leido is Dictionary):
		p._escribir("[color=#e05555]La partida copiada no se entiende.[/color]")
		return
	var m := Partida.desde_instantanea(leido as Dictionary)
	if m == null:
		p._escribir("[color=#e05555]No se pudo abrir la partida copiada.[/color]")
		return
	p.mundo = m
	p._conectar_noticias()
	p._seleccionado = null
	p._pila_deshacer.clear()
	p._llenar_selector()
	p._escribir("[color=#3fa06a]Partida importada:[/color] %s, %d, semana %d." % [
		p.mundo.mi_club().nombre, p.mundo.anio, p.mundo.semana])
	p._refrescar()

func _pintar_traspaso_partida() -> void:
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("SACAR Y METER LA PARTIDA")
	p._lista_ajustes.add_child(t)
	var ex := p._texto(10, Principal.COL_SUAVE)
	ex.text = Idiomas.t("Exportar deja la partida en un archivo de texto y la copia al portapapeles. Importar lee lo que tengas copiado. Sirve para llevártela a otro ordenador o para guardarla fuera del juego.")
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_ajustes.add_child(ex)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	p._lista_ajustes.add_child(fila)
	var be := Button.new()
	be.text = Idiomas.t("Exportar")
	be.add_theme_font_size_override("font_size", 11)
	be.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	be.pressed.connect(func() -> void: _exportar_partida())
	fila.add_child(be)
	var bi := Button.new()
	bi.text = Idiomas.t("Importar lo copiado")
	bi.add_theme_font_size_override("font_size", 11)
	bi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bi.pressed.connect(func() -> void: _importar_partida())
	fila.add_child(bi)
	p._lista_ajustes.add_child(HSeparator.new())
