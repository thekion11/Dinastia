class_name PantallaOpciones
extends RefCounted
## GLOSARIO, IDIOMA, MONEDA, MÚSICA, PEÑAS, ATAJOS Y DISPOSITIVO.
##
## Sale de `ui/principal.gd` (mapa de metas 15: el archivo pasaba de
## 15.000 líneas). `p` es la pantalla principal: sus ayudantes (`p._texto`,
## `p._boton`...), el mundo (`p.mundo`) y el repintado (`p._refrescar()`).

var p: Principal

func _init(principal: Principal) -> void:
	p = principal

func _pintar_glosario() -> void:
	p._limpiar(p._lista_glosario)
	var gl: Array = Datos.tabla("GLOSARIO")
	if gl == null:
		return
	for par in gl:
		var termino := p._texto(13, Principal.COL_TEXTO)
		termino.text = String(par[0])
		p._lista_glosario.add_child(termino)
		var definicion := p._texto(11, Principal.COL_SUAVE)
		definicion.text = String(par[1])
		definicion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_glosario.add_child(definicion)
		p._lista_glosario.add_child(HSeparator.new())

## EL SELECTOR DE IDIOMA. Dice la cobertura de verdad -cuántas frases hay
## traducidas- en vez de prometer un juego entero en otro idioma: la narración
## sigue en castellano y eso hay que verlo antes de cambiar, no después.
func _pintar_idioma() -> void:
	p._lista_ajustes.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "IDIOMA"
	p._lista_ajustes.add_child(t)
	var ex := p._texto(10, Principal.COL_SUAVE)
	ex.text = "Están traducidos los menús, las pestañas, los botones y los títulos. Las noticias, las preguntas de la prensa y los diálogos del vestuario siguen en castellano: son varios miles de frases y traducirlas a medias se lee peor que no traducirlas."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_ajustes.add_child(ex)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 4)
	p._lista_ajustes.add_child(flow)
	for k: String in Idiomas.NOMBRES:
		var clave := k
		var ficha: Array = Idiomas.NOMBRES[k]
		var b := Button.new()
		b.text = "%s  %s" % [String(ficha[1]), String(ficha[0])]
		b.add_theme_font_size_override("font_size", 11)
		b.toggle_mode = true
		b.button_pressed = Idiomas.idioma == clave
		b.clip_text = true
		b.custom_minimum_size = Vector2(150, 26)
		b.tooltip_text = "Idioma original, sin traducir nada." if clave == "es" else "%d frases de interfaz traducidas." % Idiomas.cobertura(clave)
		b.pressed.connect(func() -> void:
			Idiomas.idioma = clave
			p._refrescar())
		flow.add_child(b)

## LA MONEDA (25-9-2026). Solo cambia cómo se escribe el dinero: el tipo de
## cambio es fijo y el motor no se entera (ver `Eco.MONEDAS`).
func _pintar_moneda() -> void:
	p._lista_ajustes.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "MONEDA"
	p._lista_ajustes.add_child(t)
	var ex := p._texto(10, Principal.COL_SUAVE)
	ex.text = "Cambia cómo se muestra el dinero en todo el juego. Es un tipo de cambio fijo: tu caja y el valor de tu plantel no suben ni bajan por elegir otra."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_ajustes.add_child(ex)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 4)
	p._lista_ajustes.add_child(flow)
	for k: String in Eco.MONEDAS:
		var codigo := k
		var b := Button.new()
		b.text = "%s  %s" % [codigo, String(Eco.MONEDAS[codigo]["nombre"])]
		b.add_theme_font_size_override("font_size", 11)
		b.toggle_mode = true
		b.button_pressed = Eco.moneda == codigo
		b.clip_text = true
		b.custom_minimum_size = Vector2(190, 26)
		b.pressed.connect(func() -> void:
			Eco.elegir_moneda(codigo)
			p._refrescar())
		flow.add_child(b)

func _pintar_musica() -> void:

	p._lista_ajustes.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "MÚSICA"
	p._lista_ajustes.add_child(t)
	if not p._modo_experto:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = "Compuesta por el juego, no grabada: por eso cambia con lo que pasa —hay una pieza para los últimos minutos y otra para la vuelta olímpica— y por eso no pesa nada."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_ajustes.add_child(ex)

	var f1 := HBoxContainer.new()
	f1.add_theme_constant_override("separation", 8)
	p._lista_ajustes.add_child(f1)
	var e1 := p._texto(12, Principal.COL_TEXTO)
	e1.text = "Música"
	e1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	f1.add_child(e1)
	var b1 := Button.new()
	b1.text = "SÍ" if Musica.encendida else "NO"
	b1.pressed.connect(func() -> void:
		Musica.encendida = not Musica.encendida
		if Musica.encendida:
			Musica.ambientar(_situacion_musical())
		else:
			Musica.parar()
		p._refrescar())
	f1.add_child(b1)

	var f2 := HBoxContainer.new()
	f2.add_theme_constant_override("separation", 8)
	p._lista_ajustes.add_child(f2)
	var e2 := p._texto(12, Principal.COL_TEXTO if Musica.encendida else Principal.COL_SUAVE)
	e2.text = "Volumen"
	e2.custom_minimum_size = Vector2(70, 0)
	f2.add_child(e2)
	var sl := HSlider.new()
	sl.min_value = 0.0
	sl.max_value = 1.0
	sl.step = 0.05
	sl.value = Musica.volumen
	sl.editable = Musica.encendida
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pct := p._texto(11, Principal.COL_SUAVE)
	pct.text = "%d%%" % int(round(Musica.volumen * 100.0))
	pct.custom_minimum_size = Vector2(38, 0)
	sl.value_changed.connect(func(v: float) -> void:
		Musica.volumen = v
		pct.text = "%d%%" % int(round(v * 100.0))
		## El volumen sí se aplica al arrastrar: es lo único que se puede juzgar
		## oyéndolo, y la pieza ya está sonando.
		Musica.aplicar_volumen())
	f2.add_child(sl)
	f2.add_child(pct)

	var f3 := HBoxContainer.new()
	f3.add_theme_constant_override("separation", 8)
	p._lista_ajustes.add_child(f3)
	var e3 := p._texto(12, Principal.COL_TEXTO if Musica.encendida else Principal.COL_SUAVE)
	e3.text = "Que la elija el juego"
	e3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	e3.tooltip_text = "Encendido, la pieza cambia con lo que pasa: oficina en los menús, tensión en los últimos minutos, gloria al levantar algo. Apagado, suena siempre la que elijas."
	f3.add_child(e3)
	var b3 := Button.new()
	b3.text = "SÍ" if Musica.automatica else "NO"
	b3.disabled = not Musica.encendida
	b3.pressed.connect(func() -> void:
		Musica.automatica = not Musica.automatica
		Musica.ambientar(_situacion_musical())
		p._refrescar())
	f3.add_child(b3)

	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 4)
	p._lista_ajustes.add_child(flow)
	for k: String in Musica.PIEZAS:
		var clave := k
		var p_local: Dictionary = Musica.PIEZAS[k]
		var b := Button.new()
		b.text = String(p_local["nombre"])
		b.add_theme_font_size_override("font_size", 10)
		b.toggle_mode = true
		b.button_pressed = Musica.pieza == clave and not Musica.automatica
		b.disabled = not Musica.encendida
		b.clip_text = true
		b.custom_minimum_size = Vector2(168, 24)
		b.tooltip_text = String(p_local["desc"])
		b.pressed.connect(func() -> void:
			## Elegir una a mano apaga el automático: si no, el siguiente cambio
			## de pantalla te la quitaría y parecería que el botón no funciona.
			Musica.automatica = false
			Musica.pieza = clave
			Musica.poner(clave)
			p._refrescar())
		flow.add_child(b)

## Qué le toca sonar según lo que está pasando en la partida. Es la única regla
## de la música que sabe algo del juego, y por eso vive aquí y no en `Musica`.
func _situacion_musical() -> String:
	if p.mundo == null:
		return "menu"
	var c := p.mundo.mi_club()
	if c == null:
		return "menu"
	## Las tres últimas jornadas del año: tensión. Es lo único que sabe la música
	## de la partida, y con esto basta —el resto de situaciones las manda quien
	## llama, no una regla que hay que mantener al día.
	var liga := p._liga_de(c)
	if liga != null and liga.jornada_actual >= liga.jornadas() - 2:
		return "final"
	return "menu"

func _pintar_mezclador() -> void:

	for b: Array in Principal.BUSES_AUDIO:
		var bus: int = b[0]
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		p._lista_ajustes.add_child(fila)
		var et := p._texto(12, Principal.COL_TEXTO if Sonido.encendido else Principal.COL_SUAVE)
		et.text = String(b[1])
		et.custom_minimum_size = Vector2(70, 0)
		fila.add_child(et)
		var sl := HSlider.new()
		sl.min_value = 0.0
		sl.max_value = 1.0
		sl.step = 0.05
		sl.value = float(Sonido.volumen.get(bus, 0.5))
		sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sl.editable = Sonido.encendido
		var pct := p._texto(11, Principal.COL_SUAVE)
		pct.text = "%d%%" % int(round(sl.value * 100.0))
		pct.custom_minimum_size = Vector2(38, 0)
		## El número se actualiza al arrastrar, pero el sonido de prueba NO suena
		## en cada paso del deslizador: serían veinte pitidos por gesto.
		sl.value_changed.connect(func(v: float) -> void:
			Sonido.volumen[bus] = v
			pct.text = "%d%%" % int(round(v * 100.0)))
		fila.add_child(sl)
		fila.add_child(pct)
		var bp := Button.new()
		bp.text = "▶"
		bp.tooltip_text = String(b[3])
		bp.add_theme_font_size_override("font_size", 11)
		bp.disabled = not Sonido.encendido
		var muestra := String(b[2])
		bp.pressed.connect(func() -> void: Sonido.toca(muestra, bus))
		fila.add_child(bp)

## LAS PEÑAS Y LAS RAMAS: las dos formas de que el club sea más que un equipo.
##
## Las peñas suman socios donde no llegas. Las ramas CUESTAN todos los meses y
## no dan dinero: dan reputación. Es deliberado que sean un gasto puro —un club
## que solo hace lo que da dinero no es un club, es una empresa— y sostener el
## femenino aunque no pague es de las decisiones que definen qué llevas.
func _pintar_penas_y_ramas(c: Club, h: Hinchada) -> void:
	p._lista_estadio.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "🧣 PEÑAS  ·  %d" % h.penas.size()
	p._lista_estadio.add_child(t)
	if not h.penas.is_empty():
		var nombres: Array[String] = []
		for p_local: Dictionary in h.penas:
			nombres.append("%s (%s socios)" % [String(p_local.get("ciudad", "")), p._miles(int(p_local.get("socios", 0)))])
		var l := p._texto(11, Principal.COL_SUAVE)
		l.text = ", ".join(nombres)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_estadio.add_child(l)
	var coste_p := Eco.escalar(Hinchada.COSTE_PENA, float(c.rep))
	var bp := Button.new()
	bp.text = "Fundar una peña  ·  %s" % p._dinero(coste_p)
	bp.disabled = c.saldo < coste_p
	bp.pressed.connect(func() -> void: _fundar_pena(c))
	p._lista_estadio.add_child(bp)

	var tr := p._texto(11, Principal.COL_SUAVE)
	tr.text = "🏛️ RAMAS DEL CLUB  ·  cuestan %s/mes" % p._dinero(h.coste_ramas(c))
	p._lista_estadio.add_child(tr)
	if not p._modo_experto:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = "No dan dinero: dan reputación. Sostenerlas cuando aprieta la caja es una decisión de verdad."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_estadio.add_child(ex)
	for f: Array in Hinchada.RAMAS:
		var clave := String(f[0])
		var abierta := h.tiene_rama(clave)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_estadio.add_child(fila)
		var n := p._texto(12, Principal.COL_VERDE if abierta else Principal.COL_TEXTO)
		n.text = "%s  %s" % [String(f[1]), String(f[2])]
		n.custom_minimum_size = Vector2(150, 0)
		n.tooltip_text = String(f[7])
		fila.add_child(n)
		var rep := p._texto(11, Principal.COL_ORO)
		rep.text = ("%d temp." % int(h.anios_rama.get(clave, 0))) if abierta else "+%d rep" % int(f[5])
		rep.custom_minimum_size = Vector2(58, 0)
		fila.add_child(rep)
		var mens := p._texto(11, Principal.COL_SUAVE)
		mens.text = "%s/mes" % p._dinero(Eco.escalar(float(f[4]), float(c.rep)))
		mens.custom_minimum_size = Vector2(80, 0)
		fila.add_child(mens)
		var b := Button.new()
		var coste_r := Eco.escalar(float(f[3]), float(c.rep))
		b.text = "Cerrar" if abierta else p._dinero(coste_r)
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = not abierta and c.saldo < coste_r
		b.custom_minimum_size = Vector2(96, 0)
		b.pressed.connect(func() -> void: _alternar_rama(clave, c, abierta))
		fila.add_child(b)
		if not p._modo_experto:
			var d := p._texto(10, Principal.COL_SUAVE)
			d.text = "     %s" % String(f[7])
			d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			d.clip_text = true
			fila.add_child(d)
	_pintar_palmares_ramas(h)

## EL PALMARÉS DE LAS RAMAS (C12): títulos y podios de cada temporada.
func _pintar_palmares_ramas(h: Hinchada) -> void:
	if h.palmares_ramas.is_empty():
		return
	var t := p._texto(11, Principal.COL_ORO)
	t.text = "🏅 PALMARÉS DE LAS RAMAS"
	p._lista_estadio.add_child(t)
	for d: Dictionary in h.palmares_ramas.slice(0, 8):
		var l := p._texto(11, Principal.COL_TEXTO)
		l.text = "%d · %s · %s" % [int(d["anio"]), String(d["rama"]), "🏆 Campeón" if int(d["puesto"]) == 1 else "🥉 Podio (%d.º)" % int(d["puesto"])]
		p._lista_estadio.add_child(l)

func _fundar_pena(c: Club) -> void:
	var r := p.mundo.hinchada.fundar_pena(c)
	if r.length() > 40 or r == "":
		p._escribir("[color=#e05555]No se pudo fundar: %s.[/color]" % r)
	else:
		p._escribir("[color=#3fa06a][b]Nueva peña en %s.[/b][/color] Gente que se organiza sola para seguir al club desde lejos." % r)
		p._anotar("Nueva peña en %s" % r, "El club llega a donde no llegaba.")
	p._refrescar()

func _alternar_rama(clave: String, c: Club, abierta: bool) -> void:
	var problema := p.mundo.hinchada.cerrar_rama(clave, c) if abierta else p.mundo.hinchada.abrir_rama(clave, c)
	if problema != "":
		p._escribir("[color=#e05555]No se pudo: %s.[/color]" % problema)
	else:
		var d := p.mundo.hinchada.def_rama(clave)
		if abierta:
			p._escribir("[color=#e05555]Se cierra la rama de %s.[/color] El club pierde reputación, y la gente de esa sección no lo va a olvidar." % String(d[2]))
		else:
			p._escribir("[color=#3fa06a]Se abre la rama de %s.[/color] %s" % [String(d[2]), String(d[7])])
	p._refrescar()

func _organizar_dia_hincha(c: Club) -> void:
	var problema := p.mundo.hinchada.dia_del_hincha(c, p.mundo.prensa)
	if problema != "":
		p._escribir("[color=#e05555]No se pudo organizar: %s.[/color]" % problema)
		p._refrescar()
		return
	p._escribir("[color=#c9a227][b]🎪 Día del hincha.[/b][/color] Puertas abiertas, entrenamiento a la vista de todos, firma de autógrafos y partido de leyendas. El estadio fue una fiesta y los socios lo van a recordar.")
	p._anotar("Día del hincha", "El club abrió las puertas y la gente respondió. Todos los segmentos de la hinchada suben.")
	Aviso.mostrar(p, "logro", "🎪", "Día del hincha", "El estadio fue una fiesta.")
	p._refrescar()

## La tabla de atajos que le faltaba a `vAjustes()`. Se escribió recién ahora
## -no antes- porque hasta corregir el bug de L1/R1 de más abajo (`_input()`)
## una tabla como esta habría podido documentar un comportamiento con mando
## que en los hechos no existía. Solo referencia: no cambia ningún ajuste.
func _pintar_atajos() -> void:
	p._lista_ajustes.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "ATAJOS DE TECLADO Y MANDO"
	p._lista_ajustes.add_child(t)
	for fila_a: Array in [
			["Cambiar de chip (dentro del bloque)", "Q  /  E", "L1  /  R1"],
			["Cambiar de bloque maestro", "Ctrl+Q  /  Ctrl+E", "L2  /  R2"],
			["Moverse por la pantalla", "Flechas", "Cruceta o stick izq."],
			["Aceptar / Volver", "Enter / Esc", "A / B"],
	]:
		var f := HBoxContainer.new()
		f.add_theme_constant_override("separation", 8)
		p._lista_ajustes.add_child(f)
		var et := p._texto(11, Principal.COL_TEXTO)
		et.text = String(fila_a[0])
		et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		et.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		f.add_child(et)
		var tec := p._texto(11, Principal.COL_SUAVE)
		tec.text = String(fila_a[1])
		tec.custom_minimum_size = Vector2(120, 0)
		f.add_child(tec)
		var man := p._texto(11, Principal.COL_SUAVE)
		man.text = String(fila_a[2])
		man.custom_minimum_size = Vector2(120, 0)
		f.add_child(man)
	var nota := p._texto(10, Principal.COL_SUAVE)
	nota.text = "En pantalla táctil, un desliz horizontal largo también cambia de bloque maestro."
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_ajustes.add_child(nota)

func _pintar_dispositivo() -> void:
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "PANTALLA Y DISPOSITIVO"
	p._lista_ajustes.add_child(t)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	p._lista_ajustes.add_child(fila)
	var et := p._texto(12, Principal.COL_TEXTO)
	et.text = "Pantalla completa"
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
	et2.text = "Tamaño de la interfaz"
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
	ex.text = "No se guarda con la partida: es de esta máquina, no de este club."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_ajustes.add_child(ex)

	## MODO TELEVISIÓN. Para HDMI y pantallas grandes: se mira desde el sofá, a
	## tres metros, y lo que a medio metro es cómodo a tres metros no se lee. Es
	## un zoom fuerte de golpe, no un ajuste fino.
	var fila_tv := HBoxContainer.new()
	fila_tv.add_theme_constant_override("separation", 8)
	p._lista_ajustes.add_child(fila_tv)
	var et_tv := p._texto(12, Principal.COL_TEXTO)
	et_tv.text = "Modo televisión"
	et_tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et_tv.tooltip_text = "Para HDMI y pantallas grandes: todo más grande, pensado para mirarse desde lejos."
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
	et_ra.text = "Ropa 3D en piezas separadas"
	et_ra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et_ra.tooltip_text = "La equipación con volumen propio (más realista). Cuesta tres mallas más por jugador en el partido."
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
		et_cf.text = "Caras reales"
		et_cf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		et_cf.tooltip_text = "FOTO: la foto libre (Wikimedia Commons) en la ficha y en el 3D. RECREACIÓN: una cara dibujada con la piel, el pelo y la barba del jugador."
		fila_cf.add_child(et_cf)
		var b_cf := Button.new()
		b_cf.text = "FOTO" if Cara.usar_fotos else "RECREACIÓN"
		b_cf.pressed.connect(func() -> void:
			Cara.usar_fotos = not Cara.usar_fotos
			p._guardar_preferencias()
			p._refrescar())
		fila_cf.add_child(b_cf)

	## CALIDAD GRÁFICA. Manda en el visor 3D del estadio, que es lo único del
	## juego que puede ir lento: la interfaz son etiquetas y no cuesta nada.
	## `Calidad` ya tenía los tres niveles montados desde el porte del visor.
	var tc := p._texto(10, Principal.COL_SUAVE)
	tc.text = "Calidad gráfica del estadio en 3D"
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
			p._refrescar())
		fila_c.add_child(b_c)
	var ad := CheckButton.new()
	ad.text = "Ajustar sola para mantener 40 FPS en el partido"
	ad.tooltip_text = "Si tu equipo no llega a 40 FPS, el partido apaga por escalones la oclusión ambiental, acorta las sombras y baja la resolución del 3D."
	ad.button_pressed = Calidad.adaptativa
	ad.add_theme_font_size_override("font_size", 11)
	ad.toggled.connect(func(si: bool) -> void: Calidad.adaptativa = si)
	p._lista_ajustes.add_child(ad)
	if not p._modo_experto:
		var ec := p._texto(10, Principal.COL_SUAVE)
		ec.text = "Si el estadio en 3D se siente lento, baja la calidad. La interfaz no cambia: son etiquetas y no cuestan nada."
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
	t.text = "VELOCIDAD DE PARTIDO POR DEFECTO"
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
	t.text = "LA INTERFAZ A TU MEDIDA"
	p._lista_ajustes.add_child(t)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	p._lista_ajustes.add_child(fila)
	var et := p._texto(12, Principal.COL_TEXTO)
	et.text = "Modo experto"
	et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et.tooltip_text = "Oculta las explicaciones y los consejos de todas las pantallas. No quita ninguna función."
	fila.add_child(et)
	var b := Button.new()
	b.text = "SÍ" if p._modo_experto else "NO"
	b.pressed.connect(func() -> void:
		p._modo_experto = not p._modo_experto
		p._refrescar())
	fila.add_child(b)
	if not p._modo_experto:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = "Con el modo experto encendido desaparecen las notas explicativas como esta."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_ajustes.add_child(ex)

	## ANIMACIONES REDUCIDAS (plan maestro B11): apaga las mini animaciones de
	## la interfaz (entradas escalonadas, cifras que cuentan, latidos).
	var fila_an := HBoxContainer.new()
	fila_an.add_theme_constant_override("separation", 8)
	p._lista_ajustes.add_child(fila_an)
	var et_an := p._texto(12, Principal.COL_TEXTO)
	et_an.text = "Animaciones reducidas"
	et_an.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et_an.tooltip_text = "Sin entradas escalonadas, cifras que cuentan ni latidos: todo aparece al instante."
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
	et_vc.text = "Vista compacta"
	et_vc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et_vc.tooltip_text = "Filas más juntas: cabe más información en pantalla."
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
	et_dh.text = "Deshacer la última decisión"
	et_dh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et_dh.tooltip_text = "Se guarda la partida entera antes de vender o rescindir. Como mucho tres pasos atrás."
	fila_dh.add_child(et_dh)
	var b_dh := Button.new()
	b_dh.text = "↩ Deshacer (%d)" % p._pila_deshacer.size() if not p._pila_deshacer.is_empty() else "↩ Nada que deshacer"
	b_dh.disabled = p._pila_deshacer.is_empty()
	b_dh.pressed.connect(func() -> void: p._deshacer())
	fila_dh.add_child(b_dh)
	if not p._pila_deshacer.is_empty() and not p._modo_experto:
		var ed := p._texto(10, Principal.COL_SUAVE)
		ed.text = "Lo último: %s." % String((p._pila_deshacer[p._pila_deshacer.size() - 1] as Dictionary)["motivo"])
		ed.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_ajustes.add_child(ed)

	## LOS FAVORITOS. Seis atajos a las pestañas que más usas, que salen en la
	## portada del club. Seis y no doce: si caben todas deja de ser una elección.
	var tf := p._texto(11, Principal.COL_SUAVE)
	tf.text = "⭐ ACCESOS RÁPIDOS  ·  %d de %d" % [p._favoritos.size(), Principal.FAVORITOS_MAX]
	p._lista_ajustes.add_child(tf)
	var ef := p._texto(10, Principal.COL_SUAVE)
	ef.text = "Aparecen en Inicio. Marca aquí las pestañas a las que más vuelves."
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
