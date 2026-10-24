extends RefCounted
## [Capa 1/2 de `pantalla_opciones.gd`] _init, _pintar_glosario, _pintar_idioma, _pintar_moneda, _situacion_musical, _pintar_musica … (+7)

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
	t.text = Idiomas.t("IDIOMA")
	p._lista_ajustes.add_child(t)
	var ex := p._texto(10, Principal.COL_SUAVE)
	ex.text = Idiomas.t("Están traducidos los menús, las pestañas, los botones y los títulos. Las noticias, las preguntas de la prensa y los diálogos del vestuario siguen en castellano: son varios miles de frases y traducirlas a medias se lee peor que no traducirlas.")
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
		b.tooltip_text = Idiomas.t("Idioma original, sin traducir nada.") if clave == "es" else Idiomas.t("%d frases de interfaz traducidas.") % Idiomas.cobertura(clave)
		b.pressed.connect(func() -> void:
			Idiomas.idioma = clave
			p._refrescar())
		flow.add_child(b)

## LA MONEDA (25-9-2026). Solo cambia cómo se escribe el dinero: el tipo de
## cambio es fijo y el motor no se entera (ver `Eco.MONEDAS`).
func _pintar_moneda() -> void:
	p._lista_ajustes.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("MONEDA")
	p._lista_ajustes.add_child(t)
	var ex := p._texto(10, Principal.COL_SUAVE)
	ex.text = Idiomas.t("Cambia cómo se muestra el dinero en todo el juego. Es un tipo de cambio fijo: tu caja y el valor de tu plantel no suben ni bajan por elegir otra.")
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

func _pintar_musica() -> void:

	p._lista_ajustes.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("MÚSICA")
	p._lista_ajustes.add_child(t)
	if not p._modo_experto:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = Idiomas.t("Compuesta por el juego, no grabada: por eso cambia con lo que pasa —hay una pieza para los últimos minutos y otra para la vuelta olímpica— y por eso no pesa nada.")
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_ajustes.add_child(ex)

	var f1 := HBoxContainer.new()
	f1.add_theme_constant_override("separation", 8)
	p._lista_ajustes.add_child(f1)
	var e1 := p._texto(12, Principal.COL_TEXTO)
	e1.text = Idiomas.t("Música")
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
	e2.text = Idiomas.t("Volumen")
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
	e3.text = Idiomas.t("Que la elija el juego")
	e3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	e3.tooltip_text = Idiomas.t("Encendido, la pieza cambia con lo que pasa: oficina en los menús, tensión en los últimos minutos, gloria al levantar algo. Apagado, suena siempre la que elijas.")
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

## EL PALMARÉS DE LAS RAMAS (C12): títulos y podios de cada temporada.
func _pintar_palmares_ramas(h: Hinchada) -> void:
	if h.palmares_ramas.is_empty():
		return
	var t := p._texto(11, Principal.COL_ORO)
	t.text = Idiomas.t("🏅 PALMARÉS DE LAS RAMAS")
	p._lista_estadio.add_child(t)
	for d: Dictionary in h.palmares_ramas.slice(0, 8):
		var l := p._texto(11, Principal.COL_TEXTO)
		l.text = "%d · %s · %s" % [int(d["anio"]), String(d["rama"]), Idiomas.t("🏆 Campeón") if int(d["puesto"]) == 1 else Idiomas.t("🥉 Podio (%d.º)") % int(d["puesto"])]
		p._lista_estadio.add_child(l)

## LAS PEÑAS Y LAS RAMAS: las dos formas de que el club sea más que un equipo.
##
## Las peñas suman socios donde no llegas. Las ramas CUESTAN todos los meses y
## no dan dinero: dan reputación. Es deliberado que sean un gasto puro —un club
## que solo hace lo que da dinero no es un club, es una empresa— y sostener el
## femenino aunque no pague es de las decisiones que definen qué llevas.
func _pintar_penas_y_ramas(c: Club, h: Hinchada) -> void:
	p._lista_estadio.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("🧣 PEÑAS  ·  %d") % h.penas.size()
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
	bp.text = Idiomas.t("Fundar una peña  ·  %s") % p._dinero(coste_p)
	bp.disabled = c.saldo < coste_p
	bp.pressed.connect(func() -> void: _fundar_pena(c))
	p._lista_estadio.add_child(bp)

	var tr := p._texto(11, Principal.COL_SUAVE)
	tr.text = Idiomas.t("🏛️ RAMAS DEL CLUB  ·  cuestan %s/mes") % p._dinero(h.coste_ramas(c))
	p._lista_estadio.add_child(tr)
	if not p._modo_experto:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = Idiomas.t("No dan dinero: dan reputación. Sostenerlas cuando aprieta la caja es una decisión de verdad.")
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
		rep.text = (Idiomas.t("%d temp.") % int(h.anios_rama.get(clave, 0))) if abierta else Idiomas.t("+%d rep") % int(f[5])
		rep.custom_minimum_size = Vector2(58, 0)
		fila.add_child(rep)
		var mens := p._texto(11, Principal.COL_SUAVE)
		mens.text = Idiomas.t("%s/mes") % p._dinero(Eco.escalar(float(f[4]), float(c.rep)))
		mens.custom_minimum_size = Vector2(80, 0)
		fila.add_child(mens)
		var b := Button.new()
		var coste_r := Eco.escalar(float(f[3]), float(c.rep))
		b.text = Idiomas.t("Cerrar") if abierta else p._dinero(coste_r)
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
	t.text = Idiomas.t("ATAJOS DE TECLADO Y MANDO")
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
	nota.text = Idiomas.t("En pantalla táctil, un desliz horizontal largo también cambia de bloque maestro.")
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_ajustes.add_child(nota)
