class_name PantallaAjustes
extends RefCounted
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
	t.text = "FOTOGRAMAS POR SEGUNDO"
	p._lista_ajustes.add_child(t)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 4)
	p._lista_ajustes.add_child(fila)
	for v: int in Principal.FPS_OPCIONES:
		var valor := v
		var b := Button.new()
		b.text = "sin límite" if valor == 0 else "%d" % valor
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
	if not p._modo_experto:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = "Bajarlo alarga la batería del portátil y baja la temperatura. Para una interfaz, 30 se ve igual de bien; el estadio en 3D agradece 60."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_ajustes.add_child(ex)

	var fm := p._texto(10, Principal.COL_SUAVE)
	fm.text = "Mando conectado: %s  ·  cruceta o stick para moverte, A para pulsar, B para volver, gatillos para cambiar de pestaña." % (
		", ".join(Input.get_connected_joypads().map(func(i: int) -> String: return Input.get_joy_name(i)))
		if not Input.get_connected_joypads().is_empty() else "ninguno")
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
	lc.text = "Clima encima del fondo"
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
	et.text = "El clima sigue al ratón"
	et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et.tooltip_text = "El cursor inclina el viento: la lluvia se tuerce hacia donde miras y el confeti se va detrás. Apagado, cae recto."
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
	t.text = "🎨 ASPECTO DE LA INTERFAZ"
	p._lista_ajustes.add_child(t)
	if not p._modo_experto:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = "Nada de esto cambia una sola regla del juego. El color de acento sigue saliendo de la identidad de tu club: lo que se elige aquí es el lienzo."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_ajustes.add_child(ex)

	var lp := p._texto(10, Principal.COL_SUAVE)
	lp.text = "Paleta"
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
	lf.text = "Forma de las tarjetas"
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
	lm.text = "Marca de las tarjetas"
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
	et_b.text = "Brillo en las tarjetas"
	et_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et_b.tooltip_text = "El degradado cenital que le da aire de placa metálica. Sin él, las tarjetas son rectángulos planos."
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
	t.text = "ACCESIBILIDAD"
	p._lista_ajustes.add_child(t)

	var fila_tx := HBoxContainer.new()
	fila_tx.add_theme_constant_override("separation", 6)
	p._lista_ajustes.add_child(fila_tx)
	var et_tx := p._texto(12, Principal.COL_TEXTO)
	et_tx.text = "Tamaño del texto"
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

	var fila_d := HBoxContainer.new()
	fila_d.add_theme_constant_override("separation", 8)
	p._lista_ajustes.add_child(fila_d)
	var et_d := p._texto(12, Principal.COL_TEXTO)
	et_d.text = "Paleta para daltonismo"
	et_d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et_d.tooltip_text = "El verde y el rojo del juego pasan a azul cielo y bermellón, que se distinguen con cualquier daltonismo."
	fila_d.add_child(et_d)
	var b_d := Button.new()
	b_d.text = "SÍ" if p._daltonico else "NO"
	b_d.pressed.connect(func() -> void:
		p._daltonico = not p._daltonico
		p._refrescar())
	fila_d.add_child(b_d)

	## EL MERCADO A CIEGAS. `Ojeadores.modo_ciego` estaba escrito, probado, con
	## su escala de palabras y hasta con una captura de pantalla propia en las
	## pruebas —y no había un solo botón para encenderlo en toda la interfaz.
	if p.mundo.ojeadores != null:
		var fila_c := HBoxContainer.new()
		fila_c.add_theme_constant_override("separation", 8)
		p._lista_ajustes.add_child(fila_c)
		var et_c := p._texto(12, Principal.COL_TEXTO)
		et_c.text = "Mercado a ciegas"
		et_c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		et_c.tooltip_text = "Sin medias numéricas de los rivales: solo palabras («crack», «bueno», «del montón») hasta que los ojees a fondo."
		fila_c.add_child(et_c)
		var b_c := Button.new()
		b_c.text = "SÍ" if p.mundo.ojeadores.modo_ciego else "NO"
		b_c.pressed.connect(func() -> void:
			p.mundo.ojeadores.modo_ciego = not p.mundo.ojeadores.modo_ciego
			p._refrescar())
		fila_c.add_child(b_c)
		if not p._modo_experto:
			var ec := p._texto(10, Principal.COL_SUAVE)
			ec.text = "Con esto encendido, la media de un jugador ajeno no es un número hasta que un ojeador lo mira tres veces. Cambia por completo cómo se ficha."
			ec.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_ajustes.add_child(ec)
	p._lista_ajustes.add_child(HSeparator.new())

func _pintar_traspaso_partida() -> void:
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "SACAR Y METER LA PARTIDA"
	p._lista_ajustes.add_child(t)
	var ex := p._texto(10, Principal.COL_SUAVE)
	ex.text = "Exportar deja la partida en un archivo de texto y la copia al portapapeles. Importar lee lo que tengas copiado. Sirve para llevártela a otro ordenador o para guardarla fuera del juego."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_ajustes.add_child(ex)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	p._lista_ajustes.add_child(fila)
	var be := Button.new()
	be.text = "Exportar"
	be.add_theme_font_size_override("font_size", 11)
	be.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	be.pressed.connect(func() -> void: _exportar_partida())
	fila.add_child(be)
	var bi := Button.new()
	bi.text = "Importar lo copiado"
	bi.add_theme_font_size_override("font_size", 11)
	bi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bi.pressed.connect(func() -> void: _importar_partida())
	fila.add_child(bi)
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

func _pintar_ajustes() -> void:
	p._limpiar(p._lista_ajustes)
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 4)
	chips.add_theme_constant_override("v_separation", 4)
	p._lista_ajustes.add_child(chips)
	for s: Array in Principal.SECCIONES_AJUSTES:
		var clave := String(s[0])
		var b := Button.new()
		b.text = String(s[1])
		b.add_theme_font_size_override("font_size", 11)
		b.toggle_mode = true
		b.button_pressed = p._secc_ajustes == clave
		b.clip_text = true
		b.custom_minimum_size = Vector2(126, 26)
		b.pressed.connect(func() -> void:
			p._secc_ajustes = clave
			_pintar_ajustes())
		chips.add_child(b)
	p._lista_ajustes.add_child(HSeparator.new())

	match p._secc_ajustes:
		"audio":
			var t1 := p._texto(11, Principal.COL_SUAVE)
			t1.text = "SONIDO"
			p._lista_ajustes.add_child(t1)
			var fila1 := HBoxContainer.new()
			p._lista_ajustes.add_child(fila1)
			var et1 := p._texto(13, Principal.COL_TEXTO)
			et1.text = "Sonidos del partido"
			et1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila1.add_child(et1)
			var b1 := Button.new()
			b1.text = "SÍ" if Sonido.encendido else "NO"
			b1.pressed.connect(func() -> void:
				Sonido.encendido = not Sonido.encendido
				p._refrescar())
			fila1.add_child(b1)
			p._ui_opciones._pintar_mezclador()
			p._ui_opciones._pintar_musica()
		"aspecto":
			## El tutorial se repite desde aquí: la última tarjeta del propio
			## recorrido lo promete ("AJUSTES → Interfaz").
			var tut := Button.new()
			tut.text = "📖 Repetir el tutorial"
			tut.custom_minimum_size = Vector2(0, 32)
			tut.pressed.connect(func() -> void: p.abrir_tutorial())
			p._lista_ajustes.add_child(tut)
			p._lista_ajustes.add_child(HSeparator.new())
			_pintar_fondos_ajustes()
			_pintar_clima()
			p._lista_ajustes.add_child(HSeparator.new())
			_pintar_aspecto()
		"pantalla":
			_pintar_fotogramas()
			p._ui_opciones._pintar_dispositivo()
			p._ui_opciones._pintar_atajos()
		"juego":
			p._ui_opciones._pintar_idioma()
			p._ui_opciones._pintar_moneda()
			p._ui_opciones._pintar_velocidad_partido()
			p._ui_opciones._pintar_qol()
		"acceso":
			_pintar_accesibilidad()
		"partida":
			p._pintar_ranuras()
			_pintar_traspaso_partida()
			var t2 := p._texto(11, Principal.COL_SUAVE)
			t2.text = "GUARDADO"
			p._lista_ajustes.add_child(t2)
			var fila2 := HBoxContainer.new()
			p._lista_ajustes.add_child(fila2)
			var et2 := p._texto(13, Principal.COL_TEXTO)
			et2.text = "Autoguardado"
			et2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila2.add_child(et2)
			var b2 := Button.new()
			b2.text = "SÍ" if p._autoguardado else "NO"
			b2.pressed.connect(func() -> void:
				p._autoguardado = not p._autoguardado
				p._refrescar())
			fila2.add_child(b2)
			var ex2 := p._texto(11, Principal.COL_SUAVE)
			ex2.text = "Guarda solo al avanzar cada semana o cerrar temporada, en la misma ranura de \"Guardar\"."
			ex2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_ajustes.add_child(ex2)
			p._lista_ajustes.add_child(HSeparator.new())
			var t3 := p._texto(11, Principal.COL_SUAVE)
			t3.text = "ACERCA DE"
			p._lista_ajustes.add_child(t3)
			var ac := p._texto(11, Principal.COL_SUAVE)
			ac.text = "DINASTÍA Fútbol Manager · motor Godot. Los nombres de clubes y futbolistas generados usan sustitución letra→número; los datos reales que sí tienen nombre e imagen vienen de fuentes con licencia libre. La música y todos los efectos están sintetizados por el propio juego: no hay ni un fichero de audio."
			ac.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_ajustes.add_child(ac)

	## Esta pantalla se repinta sola al tocar una pestaña de sección, sin pasar
	## por `_refrescar()`, asi que se traduce aqui tambien.
	p._traducir_pantalla(p._lista_ajustes)
	## Cada cambio de esta pantalla vuelve a pintarla; guardar aqui recoge los
	## ajustes sin tener que colgar un guardado de cada boton.
	p._guardar_preferencias()

## El selector de los veinticuatro fondos. Estaba suelto dentro de
## `_pintar_ajustes()`; sale a su función para que la sección de aspecto se lea.
func _pintar_fondos_ajustes() -> void:
	var tf := p._texto(11, Principal.COL_SUAVE)
	tf.text = "FONDO DE PANTALLA"
	p._lista_ajustes.add_child(tf)
	var ef := p._texto(10, Principal.COL_SUAVE)
	ef.text = "Va detrás de la interfaz. Los paneles siguen siendo opacos: un fondo que deja la tabla ilegible es un fondo malo."
	ef.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_ajustes.add_child(ef)
	var op := OptionButton.new()
	op.add_theme_font_size_override("font_size", 11)
	op.clip_text = true
	## Sin esto el desplegable pide el ancho de su entrada más larga -386 px- y
	## empuja la raíz fuera de la ventana. Trampa ya pagada en este proyecto.
	op.fit_to_longest_item = false
	## EL ESTILO DEL MENÚ, arriba del fondo: es lo que más cambia la cara del
	## juego de un vistazo.
	var te := p._texto(11, Principal.COL_SUAVE)
	te.text = "ESTILO DEL MENÚ"
	p._lista_ajustes.add_child(te)
	var fila_estilo := HFlowContainer.new()
	fila_estilo.add_theme_constant_override("h_separation", 4)
	p._lista_ajustes.add_child(fila_estilo)
	for e: Array in Principal.ESTILOS_MENU:
		var clave := String(e[0])
		var be := Button.new()
		be.text = String(e[1])
		be.add_theme_font_size_override("font_size", 11)
		be.toggle_mode = true
		be.button_pressed = p._estilo_menu == clave
		be.custom_minimum_size = Vector2(160, 26)
		be.pressed.connect(func() -> void:
			p._estilo_menu = clave
			p._reconstruir_grupos()
			p._guardar_preferencias()
			_pintar_ajustes())
		fila_estilo.add_child(be)
	## La rotación del menú central (mapa de metas 24).
	var rot := CheckButton.new()
	rot.text = "Cambiar el diseño del menú central cada 10 minutos de juego"
	rot.button_pressed = p._rotar_diseno
	rot.toggled.connect(func(v: bool) -> void:
		p._rotar_diseno = v
		p._guardar_preferencias())
	p._lista_ajustes.add_child(rot)
	p._lista_ajustes.add_child(HSeparator.new())

	op.add_item("Sin fondo (verde plano)", 0)
	## La segunda entrada es la rotación: fijo o "que vaya cambiando", que es
	## como lo pidió el usuario. Va arriba del todo, antes de los 24 fondos,
	## porque es una decisión distinta -no es "cuál", es "uno o todos"-.
	op.add_item("🔀 Ir cambiando cada semana", 1)
	var elegido := 0
	if p._fondo_elegido == Principal.ROTAR_FONDO:
		elegido = 1
	for i in Fondo.NOMBRES.size():
		var k := String(Fondo.NOMBRES[i])
		op.add_item(String(Fondo.TITULOS.get(k, k)), i + 2)
		if k == p._fondo_elegido:
			elegido = i + 2
	op.selected = elegido
	op.item_selected.connect(func(idx: int) -> void:
		if idx == 0:
			p._fondo_elegido = ""
		elif idx == 1:
			p._fondo_elegido = Principal.ROTAR_FONDO
		else:
			p._fondo_elegido = String(Fondo.NOMBRES[idx - 2])
		p._aplicar_fondo())
	p._lista_ajustes.add_child(op)
