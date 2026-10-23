class_name PantallaOpciones
extends "res://ui/pantallas/pantalla_opciones_p1.gd"
## (Parte 2 de 2 de `pantalla_opciones.gd`.)

func _pintar_dispositivo() -> void:
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("PANTALLA Y DISPOSITIVO")
	p._lista_ajustes.add_child(t)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	p._lista_ajustes.add_child(fila)
	var et := p._texto(12, Principal.COL_TEXTO)
	et.text = Idiomas.t("Pantalla completa")
	et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(et)
	var completa := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	var b := Button.new()
	b.text = "SÍ" if completa else "NO"
	b.pressed.connect(func() -> void:
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED if completa else DisplayServer.WINDOW_MODE_FULLSCREEN)
		p._refrescar())
	fila.add_child(b)

	var fila2 := HBoxContainer.new()
	fila2.add_theme_constant_override("separation", 8)
	p._lista_ajustes.add_child(fila2)
	var et2 := p._texto(12, Principal.COL_TEXTO)
	et2.text = Idiomas.t("Tamaño de la interfaz")
	et2.custom_minimum_size = Vector2(150, 0)
	fila2.add_child(et2)
	var sl := HSlider.new()
	sl.min_value = 0.8
	sl.max_value = 1.4
	sl.step = 0.05
	sl.value = p._zoom_interfaz
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pct := p._texto(11, Principal.COL_SUAVE)
	pct.text = "%d%%" % int(round(p._zoom_interfaz * 100.0))
	pct.custom_minimum_size = Vector2(44, 0)
	sl.value_changed.connect(func(v: float) -> void:
		p._zoom_interfaz = v
		pct.text = "%d%%" % int(round(v * 100.0))
		## `content_scale_factor` escala la interfaz ENTERA de golpe. Tocar el
		## tamaño de fuente de cada etiqueta a mano sería repintar todo y dejaría
		## los anchos mínimos descuadrados.
		p.get_tree().root.content_scale_factor = v)
	fila2.add_child(sl)
	fila2.add_child(pct)
	var ex := p._texto(10, Principal.COL_SUAVE)
	ex.text = Idiomas.t("No se guarda con la partida: es de esta máquina, no de este club.")
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_ajustes.add_child(ex)

	## MODO TELEVISIÓN. Para HDMI y pantallas grandes: se mira desde el sofá, a
	## tres metros, y lo que a medio metro es cómodo a tres metros no se lee. Es
	## un zoom fuerte de golpe, no un ajuste fino.
	var fila_tv := HBoxContainer.new()
	fila_tv.add_theme_constant_override("separation", 8)
	p._lista_ajustes.add_child(fila_tv)
	var et_tv := p._texto(12, Principal.COL_TEXTO)
	et_tv.text = Idiomas.t("Modo televisión")
	et_tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et_tv.tooltip_text = Idiomas.t("Para HDMI y pantallas grandes: todo más grande, pensado para mirarse desde lejos.")
	fila_tv.add_child(et_tv)
	var b_tv := Button.new()
	b_tv.text = "SÍ" if p._modo_tv else "NO"
	b_tv.pressed.connect(func() -> void:
		p._modo_tv = not p._modo_tv
		p._zoom_interfaz = Principal.ZOOM_TV if p._modo_tv else 1.0
		p.get_tree().root.content_scale_factor = p._zoom_interfaz
		p._refrescar())
	fila_tv.add_child(b_tv)

	## ROPA APARTE (26-9-2026): camiseta, pantalón y medias como mallas propias
	## con volumen en el partido 3D (en el diseñador siempre).
	var fila_ra := HBoxContainer.new()
	fila_ra.add_theme_constant_override("separation", 8)
	p._lista_ajustes.add_child(fila_ra)
	var et_ra := p._texto(12, Principal.COL_TEXTO)
	et_ra.text = Idiomas.t("Ropa 3D en piezas separadas")
	et_ra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et_ra.tooltip_text = Idiomas.t("La equipación con volumen propio (más realista). Cuesta tres mallas más por jugador en el partido.")
	fila_ra.add_child(et_ra)
	var b_ra := Button.new()
	b_ra.text = "SÍ" if VestidorQ.ropa_aparte else "NO"
	b_ra.pressed.connect(func() -> void:
		VestidorQ.ropa_aparte = not VestidorQ.ropa_aparte
		p._guardar_preferencias()
		p._refrescar())
	fila_ra.add_child(b_ra)

	## CARAS REALES (29-9-2026): con la base real, la foto libre del jugador o
	## solo su recreación (piel, pelo y barba sacados de la foto).
	if Datos.base_real:
		var fila_cf := HBoxContainer.new()
		fila_cf.add_theme_constant_override("separation", 8)
		p._lista_ajustes.add_child(fila_cf)
		var et_cf := p._texto(12, Principal.COL_TEXTO)
		et_cf.text = Idiomas.t("Caras reales")
		et_cf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		et_cf.tooltip_text = Idiomas.t("FOTO: la foto libre (Wikimedia Commons) en la ficha y en el 3D. RECREACIÓN: una cara dibujada con la piel, el pelo y la barba del jugador.")
		fila_cf.add_child(et_cf)
		var b_cf := Button.new()
		b_cf.text = Idiomas.t("FOTO") if Cara.usar_fotos else Idiomas.t("RECREACIÓN")
		b_cf.pressed.connect(func() -> void:
			Cara.usar_fotos = not Cara.usar_fotos
			p._guardar_preferencias()
			p._refrescar())
		fila_cf.add_child(b_cf)

	## CONTROLES DEL PARTIDO (14-10-2026): teclas, mando y ayudas, los mismos
	## que se abren desde el ⚙ del estadio y la pausa de la Carrera de Jugador.
	var fila_ct := HBoxContainer.new()
	fila_ct.add_theme_constant_override("separation", 8)
	p._lista_ajustes.add_child(fila_ct)
	var et_ct := p._texto(12, Principal.COL_TEXTO)
	et_ct.text = Idiomas.t("Controles del partido")
	et_ct.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et_ct.tooltip_text = Idiomas.t("Esquema de teclado, cada tecla y botón del mando, y las ayudas de pase, tiro y cambio de jugador.")
	fila_ct.add_child(et_ct)
	var b_ct := Button.new()
	b_ct.text = Idiomas.t("🎮 Configurar")
	b_ct.pressed.connect(func() -> void: PanelControles.abrir(p))
	fila_ct.add_child(b_ct)

	## CALIDAD GRÁFICA. Manda en el visor 3D del estadio, que es lo único del
	## juego que puede ir lento: la interfaz son etiquetas y no cuesta nada.
	## `Calidad` ya tenía los tres niveles montados desde el porte del visor.
	var tc := p._texto(10, Principal.COL_SUAVE)
	tc.text = Idiomas.t("Calidad gráfica del estadio en 3D")
	p._lista_ajustes.add_child(tc)
	var fila_c := HBoxContainer.new()
	fila_c.add_theme_constant_override("separation", 4)
	p._lista_ajustes.add_child(fila_c)
	for nivel: Array in [
			[Calidad.ULTRA, "Ultra", "Todos los efectos, sombras y reflejos"],
			[Calidad.ALTO, "Alta", "El equilibrio: sombras sí, lo más caro no"],
			[Calidad.MEDIO, "Media", "Sin efectos pesados: máxima fluidez"],
		]:
		var clave: int = nivel[0]
		var b_c := Button.new()
		b_c.text = String(nivel[1])
		b_c.add_theme_font_size_override("font_size", 11)
		b_c.toggle_mode = true
		b_c.button_pressed = Calidad.elegida == clave
		b_c.tooltip_text = String(nivel[2])
		b_c.custom_minimum_size = Vector2(70, 0)
		b_c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b_c.pressed.connect(func() -> void:
			Calidad.elegida = clave
			Calidad.guardar()
			p._refrescar())
		fila_c.add_child(b_c)
	var ad := CheckButton.new()
	ad.text = Idiomas.t("Ajustar sola para mantener 40 FPS en el partido")
	ad.tooltip_text = Idiomas.t("Si tu equipo no llega a 40 FPS, el partido apaga por escalones la oclusión ambiental, acorta las sombras y baja la resolución del 3D.")
	ad.button_pressed = Calidad.adaptativa
	ad.add_theme_font_size_override("font_size", 11)
	ad.toggled.connect(func(si: bool) -> void:
		Calidad.adaptativa = si
		Calidad.guardar())
	p._lista_ajustes.add_child(ad)
	## MOTOR GRÁFICO (etapa 3): el ligero (OpenGL) para gráficas integradas
	## viejas. Hay que reiniciar el juego: se ofrece hacerlo en el momento.
	var ml := CheckButton.new()
	ml.text = Idiomas.t("Motor gráfico ligero (para equipos modestos; reinicia el juego)")
	ml.tooltip_text = Idiomas.t("Usa el renderizador de compatibilidad (OpenGL). En gráficas integradas antiguas va más fluido; se pierden algunos efectos de luz.")
	ml.button_pressed = Calidad.motor_ligero
	ml.disabled = not Calidad.puede_relanzar()
	ml.add_theme_font_size_override("font_size", 11)
	ml.toggled.connect(func(si: bool) -> void:
		Calidad.motor_ligero = si
		Calidad.guardar()
		if Calidad.es_compatibilidad() != si and Calidad.puede_relanzar():
			var dlg := ConfirmationDialog.new()
			dlg.dialog_text = Idiomas.t("El cambio de motor se aplica al reiniciar. ¿Reiniciar ahora? (la partida guardada se conserva)")
			dlg.confirmed.connect(func() -> void:
				if p.get("mundo") != null:
					p.call("_guardar")
				Calidad.relanzar(p.get_tree()))
			p.add_child(dlg)
			dlg.popup_centered())
	p._lista_ajustes.add_child(ml)
	if not p._modo_experto:
		var ec := p._texto(10, Principal.COL_SUAVE)
		ec.text = Idiomas.t("Si el estadio en 3D se siente lento, baja la calidad. La interfaz no cambia: son etiquetas y no cuestan nada.")
		ec.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_ajustes.add_child(ec)
	p._lista_ajustes.add_child(HSeparator.new())

## "Velocidad de partido por defecto" de `vAjustes()`: con qué velocidad
## arranca cada partido dirigido en vivo. Antes de esta tanda el juego lo
## arrancaba siempre en "Normal" sin que hubiera dónde cambiarlo -no era un
## dato guardado, era un número fijo dentro de `PartidoVivo`-.
func _pintar_velocidad_partido() -> void:
	p._lista_ajustes.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("VELOCIDAD DE PARTIDO POR DEFECTO")
	p._lista_ajustes.add_child(t)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	p._lista_ajustes.add_child(fila)
	## Del 1 al 3: "Pausa" (índice 0) no tiene sentido como velocidad de
	## arranque -nadie quiere que el partido empiece parado-, igual que el
	## HTML se salta esa opción en este mismo selector.
	for i in range(1, PartidoVivo.VELOCIDADES.size()):
		var idx := i
		var b := Button.new()
		b.text = String(PartidoVivo.VELOCIDADES[i]["txt"])
		b.toggle_mode = true
		b.button_pressed = (p._velocidad_partido == idx)
		b.custom_minimum_size = Vector2(90, 30)
		b.pressed.connect(func() -> void:
			p._velocidad_partido = idx
			p._refrescar())
		fila.add_child(b)

func _pintar_qol() -> void:
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("LA INTERFAZ A TU MEDIDA")
	p._lista_ajustes.add_child(t)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	p._lista_ajustes.add_child(fila)
	var et := p._texto(12, Principal.COL_TEXTO)
	et.text = Idiomas.t("Modo experto")
	et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et.tooltip_text = Idiomas.t("Oculta las explicaciones y los consejos de todas las pantallas. No quita ninguna función.")
	fila.add_child(et)
	var b := Button.new()
	b.text = "SÍ" if p._modo_experto else "NO"
	b.pressed.connect(func() -> void:
		p._modo_experto = not p._modo_experto
		p._refrescar())
	fila.add_child(b)
	if not p._modo_experto:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = Idiomas.t("Con el modo experto encendido desaparecen las notas explicativas como esta.")
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_ajustes.add_child(ex)

	## ANIMACIONES REDUCIDAS (plan maestro B11): apaga las mini animaciones de
	## la interfaz (entradas escalonadas, cifras que cuentan, latidos).
	var fila_an := HBoxContainer.new()
	fila_an.add_theme_constant_override("separation", 8)
	p._lista_ajustes.add_child(fila_an)
	var et_an := p._texto(12, Principal.COL_TEXTO)
	et_an.text = Idiomas.t("Animaciones reducidas")
	et_an.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et_an.tooltip_text = Idiomas.t("Sin entradas escalonadas, cifras que cuentan ni latidos: todo aparece al instante.")
	fila_an.add_child(et_an)
	var b_an := Button.new()
	b_an.text = "SÍ" if Animar.reducidas() else "NO"
	b_an.pressed.connect(func() -> void:
		Animar.fijar_reducidas(not Animar.reducidas())
		p._refrescar())
	fila_an.add_child(b_an)

	## LA VISTA COMPACTA. Aprieta las filas de todas las pantallas a la vez: en
	## una tabla de veinte jugadores es la diferencia entre ver media plantilla y
	## verla entera sin desplazarse.
	var fila_vc := HBoxContainer.new()
	fila_vc.add_theme_constant_override("separation", 8)
	p._lista_ajustes.add_child(fila_vc)
	var et_vc := p._texto(12, Principal.COL_TEXTO)
	et_vc.text = Idiomas.t("Vista compacta")
	et_vc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et_vc.tooltip_text = Idiomas.t("Filas más juntas: cabe más información en pantalla.")
	fila_vc.add_child(et_vc)
	var b_vc := Button.new()
	b_vc.text = "SÍ" if p._vista_compacta else "NO"
	b_vc.pressed.connect(func() -> void:
		p._vista_compacta = not p._vista_compacta
		p._aplicar_vista_compacta()
		p._refrescar())
	fila_vc.add_child(b_vc)

	## DESHACER. La pila guarda la partida entera antes de las decisiones que se
	## toman con el dedo: vender a alguien y rescindir un contrato.
	var fila_dh := HBoxContainer.new()
	fila_dh.add_theme_constant_override("separation", 8)
	p._lista_ajustes.add_child(fila_dh)
	var et_dh := p._texto(12, Principal.COL_TEXTO)
	et_dh.text = Idiomas.t("Deshacer la última decisión")
	et_dh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et_dh.tooltip_text = Idiomas.t("Se guarda la partida entera antes de vender o rescindir. Como mucho tres pasos atrás.")
	fila_dh.add_child(et_dh)
	var b_dh := Button.new()
	b_dh.text = Idiomas.t("↩ Deshacer (%d)") % p._pila_deshacer.size() if not p._pila_deshacer.is_empty() else Idiomas.t("↩ Nada que deshacer")
	b_dh.disabled = p._pila_deshacer.is_empty()
	b_dh.pressed.connect(func() -> void: p._deshacer())
	fila_dh.add_child(b_dh)
	if not p._pila_deshacer.is_empty() and not p._modo_experto:
		var ed := p._texto(10, Principal.COL_SUAVE)
		ed.text = Idiomas.t("Lo último: %s.") % String((p._pila_deshacer[p._pila_deshacer.size() - 1] as Dictionary)["motivo"])
		ed.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_ajustes.add_child(ed)

	## LOS FAVORITOS. Seis atajos a las pestañas que más usas, que salen en la
	## portada del club. Seis y no doce: si caben todas deja de ser una elección.
	var tf := p._texto(11, Principal.COL_SUAVE)
	tf.text = Idiomas.t("⭐ ACCESOS RÁPIDOS  ·  %d de %d") % [p._favoritos.size(), Principal.FAVORITOS_MAX]
	p._lista_ajustes.add_child(tf)
	var ef := p._texto(10, Principal.COL_SUAVE)
	ef.text = Idiomas.t("Aparecen en Inicio. Marca aquí las pestañas a las que más vuelves.")
	ef.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_ajustes.add_child(ef)
	var rej := GridContainer.new()
	rej.columns = 4
	rej.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p._lista_ajustes.add_child(rej)
	## BUG REAL, encontrado por accidente probando otra cosa (11-9-2026):
	## `g["tabs"]` no es una lista de strings -lo era antes de que existieran
	## los chips `{tab, secc, label}`-, así que `for tab: String in ...`
	## reventaba con "Trying to assign value of type 'Dictionary' to a
	## variable of type 'String'" en cuanto alguien abriera esta sección.
	## Ningún banco lo vio nunca -no carga `ui/`- y ninguna captura de esta
	## sesión había entrado a Ajustes → Juego hasta ahora. Se extrae el
	## nombre de pestaña de cada chip, sin repetir: varios chips comparten
	## la misma pestaña (distinto `secc`) y un botón por chip habría
	## duplicado "Club" media docena de veces.
	var vistas: Array[String] = []
	for g: Dictionary in Principal.GRUPOS:
		for chip: Dictionary in (g["tabs"] as Array):
			var tab := String(chip["tab"])
			if vistas.has(tab):
				continue
			vistas.append(tab)
			var fav := p._favoritos.has(tab)
			var bt := Button.new()
			bt.text = ("★ " if fav else "") + tab
			bt.toggle_mode = true
			bt.button_pressed = fav
			bt.add_theme_font_size_override("font_size", 11)
			bt.clip_text = true
			bt.custom_minimum_size = Vector2(90, 0)
			bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bt.disabled = not fav and p._favoritos.size() >= Principal.FAVORITOS_MAX
			bt.pressed.connect(func() -> void: p._alternar_favorito(tab))
			rej.add_child(bt)
	p._lista_ajustes.add_child(HSeparator.new())
