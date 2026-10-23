class_name PantallaAjustes
extends "res://ui/pantallas/pantalla_ajustes_p1.gd"
## (Parte 2 de 2 de `pantalla_ajustes.gd`.)

## El selector de los veinticuatro fondos. Estaba suelto dentro de
## `_pintar_ajustes()`; sale a su función para que la sección de aspecto se lea.
func _pintar_fondos_ajustes() -> void:
	var tf := p._texto(11, Principal.COL_SUAVE)
	tf.text = Idiomas.t("FONDO DE PANTALLA")
	p._lista_ajustes.add_child(tf)
	var ef := p._texto(10, Principal.COL_SUAVE)
	ef.text = Idiomas.t("Va detrás de la interfaz. Los paneles siguen siendo opacos: un fondo que deja la tabla ilegible es un fondo malo.")
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
	te.text = Idiomas.t("ESTILO DEL MENÚ")
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
	rot.text = Idiomas.t("Cambiar el diseño del menú central cada 10 minutos de juego")
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
			t1.text = Idiomas.t("SONIDO")
			p._lista_ajustes.add_child(t1)
			var fila1 := HBoxContainer.new()
			p._lista_ajustes.add_child(fila1)
			var et1 := p._texto(13, Principal.COL_TEXTO)
			et1.text = Idiomas.t("Sonidos del partido")
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
			tut.text = Idiomas.t("📖 Repetir el tutorial")
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
			t2.text = Idiomas.t("GUARDADO")
			p._lista_ajustes.add_child(t2)
			var fila2 := HBoxContainer.new()
			p._lista_ajustes.add_child(fila2)
			var et2 := p._texto(13, Principal.COL_TEXTO)
			et2.text = Idiomas.t("Autoguardado")
			et2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila2.add_child(et2)
			var b2 := Button.new()
			b2.text = "SÍ" if p._autoguardado else "NO"
			b2.pressed.connect(func() -> void:
				p._autoguardado = not p._autoguardado
				p._refrescar())
			fila2.add_child(b2)
			var ex2 := p._texto(11, Principal.COL_SUAVE)
			ex2.text = Idiomas.t("Guarda solo al avanzar cada semana o cerrar temporada, en la misma ranura de \"Guardar\".")
			ex2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_ajustes.add_child(ex2)
			p._lista_ajustes.add_child(HSeparator.new())
			var t3 := p._texto(11, Principal.COL_SUAVE)
			t3.text = Idiomas.t("ACERCA DE")
			p._lista_ajustes.add_child(t3)
			var ac := p._texto(11, Principal.COL_SUAVE)
			ac.text = Idiomas.t("DINASTÍA Fútbol Manager · motor Godot. Los nombres de clubes y futbolistas generados usan sustitución letra→número; los datos reales que sí tienen nombre e imagen vienen de fuentes con licencia libre. La música y todos los efectos están sintetizados por el propio juego: no hay ni un fichero de audio.")
			ac.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_ajustes.add_child(ac)
			## M-309: créditos y licencias de lo que no es propio.
			p._lista_ajustes.add_child(HSeparator.new())
			var t4 := p._texto(11, Principal.COL_SUAVE)
			t4.text = Idiomas.t("CRÉDITOS Y LICENCIAS")
			p._lista_ajustes.add_child(t4)
			for linea: String in Creditos.lineas():
				var cr := p._texto(10, Principal.COL_TEXTO)
				cr.text = "· " + linea
				cr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				p._lista_ajustes.add_child(cr)
			var fotos := p._texto(10, Principal.COL_SUAVE)
			fotos.text = Idiomas.t("Las fotos de futbolistas reales (solo en la versión privada) llevan su autor y su licencia bajo el retrato, en la ficha del jugador.")
			fotos.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_ajustes.add_child(fotos)

	## Esta pantalla se repinta sola al tocar una pestaña de sección, sin pasar
	## por `_refrescar()`, asi que se traduce aqui tambien.
	p._traducir_pantalla(p._lista_ajustes)
	## Cada cambio de esta pantalla vuelve a pintarla; guardar aqui recoge los
	## ajustes sin tener que colgar un guardado de cada boton.
	p._guardar_preferencias()
