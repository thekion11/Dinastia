class_name PantallaGente
extends "res://ui/pantallas/pantalla_gente_p1.gd"
## [Capa 2/2 de `pantalla_gente.gd`] _pintar_redes, _pintar_correo, _firmar_auspicio, _lanzar_campana, _pujar_marca, _pedir_credito … (+3)

func _pintar_redes() -> void:
	p._limpiar(p._lista_redes)
	var p_local := p.mundo.prensa
	if p_local == null:
		return
	var g := GridContainer.new()
	g.columns = 4
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 12)
	p._lista_redes.add_child(g)
	for par in [["Seguidores", p._miles(p_local.seguidores)], ["Funa", str(p_local.funa)],
			["Ánimo", str(p_local.animo)], ["Prestigio DT", str(p_local.rep_entrenador)]]:
		var col := VBoxContainer.new()
		g.add_child(col)
		var et := p._texto(10, Principal.COL_SUAVE)
		et.text = String(par[0])
		col.add_child(et)
		var va := p._texto(16, Principal.COL_TEXTO)
		va.text = String(par[1])
		col.add_child(va)
	var estado := p._texto(11, Principal.COL_ROJO if p_local.funa > 60 else (Principal.COL_ORO if p_local.funa > 35 else Principal.COL_VERDE))
	estado.text = (Idiomas.t("⚠️ Campaña activa en tu contra: el directorio lo está mirando.")
		if p_local.funa > 60 else (Idiomas.t("Hay ruido en redes, pero se aguanta.")
		if p_local.funa > 35 else Idiomas.t("Ambiente tranquilo en las redes.")))
	estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_redes.add_child(estado)
	p._lista_redes.add_child(HSeparator.new())

	var tg := p._texto(11, Principal.COL_SUAVE)
	tg.text = Idiomas.t("GABINETE DE COMUNICACIÓN")
	p._lista_redes.add_child(tg)
	var ex := p._texto(10, Principal.COL_SUAVE)
	ex.text = Idiomas.t("Apoyar calma la funa pero gasta un cartucho. Callar no cuesta nada hoy. Contestar es cara o cruz: apaga el fuego o lo dobla.")
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_redes.add_child(ex)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	p._lista_redes.add_child(fila)
	for par2 in [["apoyo", "📢 Comunicado de apoyo"], ["silencio", "🤐 Silencio de prensa"],
			["contestar", "🗣️ Contestar"]]:
		var clave := String(par2[0])
		var b := Button.new()
		b.text = String(par2[1])
		b.add_theme_font_size_override("font_size", 11)
		b.clip_text = true
		b.custom_minimum_size = Vector2(110, 0)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void: _comunicado(clave))
		fila.add_child(b)
	p._lista_redes.add_child(HSeparator.new())

	_pintar_periodistas(p_local)
	_pintar_mesa_debate(p_local)
	_pintar_influencer(p_local)
	_pintar_medios_propios(p_local)
	_pintar_vocero(p_local)
	_pintar_derechos_tv(p_local)
	_pintar_portadas(p_local)
	_pintar_ano_contado(p_local)

	var tf := p._texto(11, Principal.COL_SUAVE)
	tf.text = Idiomas.t("LO QUE SE DICE")
	p._lista_redes.add_child(tf)
	if p_local.posts.is_empty():
		var vac := p._texto(12, Principal.COL_SUAVE)
		vac.text = Idiomas.t("Todavía nadie habla de ti. Gana o pierde algo y verás.")
		p._lista_redes.add_child(vac)
		return
	for i in mini(25, p_local.posts.size()):
		var m: Dictionary = p_local.posts[i]
		var l := p._texto(12, Principal.COL_TEXTO)
		l.text = "%s  %s" % [String(m.get("avatar", "")), String(m.get("texto", ""))]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_redes.add_child(l)
		var meta := p._texto(10, Principal.COL_SUAVE)
		meta.text = "%s  ·  ♥ %s  ·  ↻ %s" % [
			String(m.get("usuario", "")), p._miles(int(m.get("likes", 0))), p._miles(int(m.get("rt", 0)))]
		p._lista_redes.add_child(meta)

func _pintar_correo() -> void:
	p._limpiar(p._lista_correo)
	var sin_leer := 0
	for it: Dictionary in p._bandeja:
		if not bool(it["leida"]):
			sin_leer += 1

	var filtros := HBoxContainer.new()
	filtros.add_theme_constant_override("separation", 6)
	p._lista_correo.add_child(filtros)
	var b_todo := Button.new()
	b_todo.text = Idiomas.t("Todo (%d)") % p._bandeja.size()
	b_todo.toggle_mode = true
	b_todo.button_pressed = p._correo_filtro == "todo"
	b_todo.pressed.connect(func() -> void: p._correo_filtro = "todo"; _pintar_correo())
	filtros.add_child(b_todo)
	var b_nuevas := Button.new()
	b_nuevas.text = Idiomas.t("Sin leer (%d)") % sin_leer
	b_nuevas.toggle_mode = true
	b_nuevas.button_pressed = p._correo_filtro == "nuevas"
	b_nuevas.pressed.connect(func() -> void: p._correo_filtro = "nuevas"; _pintar_correo())
	filtros.add_child(b_nuevas)
	if sin_leer > 0:
		var b_todas := Button.new()
		b_todas.text = Idiomas.t("✅ Marcar todo como leído")
		b_todas.pressed.connect(func() -> void:
			for it2: Dictionary in p._bandeja:
				it2["leida"] = true
			_pintar_correo())
		filtros.add_child(b_todas)
	p._lista_correo.add_child(HSeparator.new())

	if p._bandeja.is_empty():
		var vacio := p._texto(12, Principal.COL_SUAVE)
		vacio.text = Idiomas.t("Bandeja vacía. Los avisos del club van llegando aquí solos.")
		p._lista_correo.add_child(vacio)
		return
	## Título en un botón plano -mismo truco que ya usa `_fila_jugador()` para
	## que la fila entera responda al clic sin inventar un control nuevo-, y el
	## cuerpo en una etiqueta aparte debajo: meter un VBoxContainer entero
	## dentro de un Button no es un patrón que ya exista en este proyecto y su
	## tamaño mínimo es el del texto, no el de sus hijos.
	var alguna := false
	for it3: Dictionary in p._bandeja:
		if p._correo_filtro == "nuevas" and bool(it3["leida"]):
			continue
		alguna = true
		var leida := bool(it3["leida"])
		var b := Button.new()
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = false
		b.text = "%s%s   ·   S%d/%d" % ["" if leida else "🔵 ", String(it3["titulo"]), int(it3["semana"]), int(it3["anio"])]
		b.add_theme_font_size_override("font_size", 13)
		b.add_theme_color_override("font_color", p._color_de_paleta(Principal.COL_SUAVE if leida else Principal.COL_TEXTO))
		b.pressed.connect(func() -> void: it3["leida"] = true; _pintar_correo())
		p._lista_correo.add_child(b)
		var cuerpo := p._texto(11, Principal.COL_SUAVE)
		cuerpo.text = String(it3["cuerpo"])
		cuerpo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_correo.add_child(cuerpo)
		p._lista_correo.add_child(HSeparator.new())
	if not alguna:
		var nada := p._texto(12, Principal.COL_SUAVE)
		nada.text = Idiomas.t("No queda nada por leer.")
		p._lista_correo.add_child(nada)

## `G.libro` del HTML, hecho pestaña: siete clases llevan meses -algunas desde
## que se escribieron- emitiendo una señal `movimiento(concepto, monto)` que
## nadie escuchaba. La caja SÍ se movía con cada una de ellas; lo único que
## faltaba era el papel que explica por qué. Ahora `Mundo.libro_financiero` las
## recoge todas y esto es lo único que hace falta para enseñarlo.
## EL BALANCE Y EL FLUJO DE CAJA, de `vContabilidad()`. El estado de resultados
## dice si el año sale bien; esto dice si el club AGUANTA. Son preguntas
## distintas: se puede ganar dinero al año y quedarse sin caja en marzo.
##
## El pasivo lo pone `Banco`: la suma de lo que se debe. Antes iba a cero con
## una nota que decía que el sistema de deuda no estaba portado; ya lo está,
## así que el patrimonio de aquí ya no miente.
## `vBanco()`: la deuda y el reloj de la liquidación. Es el único sistema del
## juego que puede terminar una partida sin perder un partido —doce semanas con
## la caja en rojo y el club se liquida—, así que el estado va arriba y grande.
## `vSponsor()`: la marca del pecho. Ofertas, contrato vigente y exigencia.
##
## Es el único ingreso grande del club que se DECIDE, y por eso tiene su bloque
## propio arriba del todo en Finanzas. Sin firmar no entra nada: la pantalla
## enseña tres cifras y quedarse sin marca también es una decisión, solo que una
## cara.
func _firmar_auspicio(i: int) -> void:
	var problema := p.mundo.auspicio.firmar(i)
	if problema != "":
		p._escribir("[color=#e05555]No se pudo firmar: %s.[/color]" % problema)
	p._refrescar()

func _lanzar_campana(clave: String) -> void:
	var problema := p.mundo.lanzar_campana(clave)
	if problema != "":
		p._escribir("[color=#e05555]No se pudo lanzar: %s.[/color]" % problema)
	else:
		var d := Finanzas.def_campana(clave)
		p._escribir("[color=#3fa06a][b]Campaña lanzada:[/b][/color] %s." % (String(d[1]) if not d.is_empty() else clave))
	p._refrescar()

func _pujar_marca() -> void:
	var r := p.mundo.pujar_por_marca()
	if r != "":
		p._escribir("[color=#c9a227]%s[/color]" % r)
		p._anotar("Guerra de marcas", r)
	p._refrescar()

func _pedir_credito(i: int, c: Club) -> void:
	var problema := p.mundo.banco.pedir(i, c)
	if problema != "":
		p._escribir("[color=#e05555]No hay crédito: %s.[/color]" % problema)
	p._refrescar()

func _prepagar(i: int, c: Club) -> void:
	var problema := p.mundo.banco.prepagar(i, c)
	if problema != "":
		p._escribir("[color=#e05555]No se pudo prepagar: %s.[/color]" % problema)
	else:
		p._escribir("[color=#4caf6d]Crédito cancelado.[/color] Te ahorras todos los intereses que quedaban.")
	p._refrescar()

func _renegociar(i: int) -> void:
	var problema := p.mundo.banco.renegociar(i)
	if problema != "":
		p._escribir("[color=#e05555]No se pudo renegociar: %s.[/color]" % problema)
	else:
		p._escribir("[color=#c9a227]Crédito renegociado.[/color] La cuota baja, el plazo se alarga y al final pagarás más.")
	p._refrescar()

func _emitir_bono(c: Club) -> void:
	var problema := p.mundo.banco.emitir_bono(c)
	if problema != "":
		p._escribir("[color=#e05555]No se pudo emitir: %s.[/color]" % problema)
	p._refrescar()
