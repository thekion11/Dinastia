class_name PantallaClubVida
extends "res://ui/pantallas/pantalla_club_vida_p3.gd"
## [Capa 4/4 de `pantalla_club_vida.gd`] _pintar_hinchada

## TU ESTADIO: lo que se puede reformar y lo que cuesta.
## `vHinchada()` del HTML: los cinco grupos de la afición, el plan de abonos y
## la encuesta abierta. La idea que lo sostiene es que **no se puede contentar a
## todos a la vez**: el abono popular llena el estadio y gana al barrio pero
## recauda poco; el premium da dinero y enfada a las familias.
func _pintar_hinchada(c: Club) -> void:
	var h := p.mundo.hinchada
	if h == null:
		return
	p._lista_estadio.add_child(HSeparator.new())
	if h.abonados > 0:
		p._dato("Abonados", "%s  ·  %s" % [p._miles(h.abonados), h.nombre_abono()], Principal.COL_TEXTO, p._lista_estadio)
	if p.mundo.prensa != null:
		var fp := h.fair_play(p.mundo.prensa.funa, p.mundo.prensa.animo)
		p._dato("Fair play de la hinchada", "%d / 100" % fp,
			Principal.COL_VERDE if fp >= 70 else (Principal.COL_ROJO if fp < 35 else Principal.COL_ORO), p._lista_estadio)
	## EL DÍA DEL HINCHA. Es la única acción del juego que sube TODOS los
	## segmentos a la vez: bajar el precio de la entrada contenta al que paga,
	## esto contenta al que viene. Por eso vale lo que vale.
	p._dato("Días del hincha organizados", str(h.dias_hincha), Principal.COL_TEXTO, p._lista_estadio)
	var coste_dh := Eco.escalar(Hinchada.COSTE_DIA_HINCHA, float(c.rep))
	var bdh := Button.new()
	bdh.text = Idiomas.t("🎪 Organizar un día del hincha  ·  %s") % p._dinero(coste_dh)
	bdh.disabled = c.saldo < coste_dh
	bdh.pressed.connect(func() -> void: p._ui_opciones._organizar_dia_hincha(c))
	p._lista_estadio.add_child(bdh)
	p._ui_opciones._pintar_penas_y_ramas(c, h)

	## La encuesta, si la hay. Va arriba porque es lo único que pide respuesta.
	if not h.encuesta.is_empty():
		var te := p._texto(11, Principal.COL_ORO)
		te.text = Idiomas.t("📊 ENCUESTA A LOS SOCIOS")
		p._lista_estadio.add_child(te)
		var pr := p._texto(13, Principal.COL_TEXTO)
		pr.text = String(h.encuesta["pregunta"])
		pr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_estadio.add_child(pr)
		var opciones: Array = h.encuesta["opciones"]
		var pcts: Array = h.encuesta["pct"]
		for i in opciones.size():
			var fila_e := HBoxContainer.new()
			fila_e.add_theme_constant_override("separation", 8)
			p._lista_estadio.add_child(fila_e)
			var lo := p._texto(12, Principal.COL_SUAVE)
			lo.text = "%s  ·  %d%%" % [String(opciones[i]), int(pcts[i])]
			lo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila_e.add_child(lo)
			var idx := i
			p._boton("Hacer esto", func() -> void: _responder_encuesta(idx), fila_e)

	var ts := p._texto(11, Principal.COL_SUAVE)
	ts.text = Idiomas.t("SEGMENTOS DE LA HINCHADA")
	p._lista_estadio.add_child(ts)
	var tabla: Variant = Datos.tabla("SEGMENTOS")
	if tabla is Array:
		for fila: Array in (tabla as Array):
			var clave := String(fila[0])
			var v := int(h.segmentos.get(clave, 50))
			p._dato(String(fila[1]), "%d" % v,
				Principal.COL_VERDE if v > 70 else (Principal.COL_ROJO if v < 35 else Principal.COL_ORO), p._lista_estadio)
			var d := p._texto(10, Principal.COL_SUAVE)
			d.text = String(fila[2])
			d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_estadio.add_child(d)

	var ta := p._texto(11, Principal.COL_SUAVE)
	ta.text = Idiomas.t("ABONOS DE TEMPORADA  ·  la campaña se lanza sola al empezar cada año")
	ta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_estadio.add_child(ta)
	var planes: Variant = Datos.tabla("PLANES_ABONO")
	if planes is Array:
		for fila2: Array in (planes as Array):
			var clave2 := String(fila2[0])
			var elegido := h.abono == clave2
			var fila_a := HBoxContainer.new()
			fila_a.add_theme_constant_override("separation", 8)
			p._lista_estadio.add_child(fila_a)
			var la := p._texto(12, p.COL_ACENTO if elegido else Principal.COL_SUAVE)
			la.text = "%s  ×%.2f" % [String(fila2[1]).strip_edges(), float(fila2[2])]
			la.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila_a.add_child(la)
			var ba := Button.new()
			ba.text = Idiomas.t("Elegido") if elegido else Idiomas.t("Elegir")
			ba.disabled = elegido
			ba.add_theme_font_size_override("font_size", 11)
			ba.pressed.connect(func() -> void:
				h.fijar_abono(clave2)
				p._refrescar())
			fila_a.add_child(ba)
			var da := p._texto(10, Principal.COL_SUAVE)
			da.text = String(fila2[3])
			da.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_estadio.add_child(da)

	## PRECIOS DINÁMICOS. La otra palanca de la taquilla, además del precio fijo:
	## cobrar más el día que viene el líder y menos el día que viene el colista.
	## No es dinero gratis —subirle la entrada a la gente el día del clásico
	## cuesta ánimo—, y por eso es un interruptor y no una mejora.
	var fila_pd := HBoxContainer.new()
	fila_pd.add_theme_constant_override("separation", 8)
	p._lista_estadio.add_child(fila_pd)
	var lpd := p._texto(12, Principal.COL_TEXTO)
	lpd.text = Idiomas.t("Precios dinámicos")
	lpd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lpd.tooltip_text = Idiomas.t("Sube en los partidos grandes, baja en los flojos.")
	fila_pd.add_child(lpd)
	var bpd := Button.new()
	bpd.text = "SÍ" if h.precio_dinamico else "NO"
	bpd.add_theme_font_size_override("font_size", 11)
	bpd.pressed.connect(func() -> void:
		var msg := h.alternar_precio_dinamico()
		p._escribir("[color=#c9a227]%s[/color]" % msg)
		p._refrescar())
	fila_pd.add_child(bpd)
	## Lo que se cobraría en el próximo partido en casa, para que el interruptor
	## no sea una promesa abstracta: se ve la cifra antes de encenderlo.
	var par_pd := p._liga_de(c).emparejamiento_de(c)
	if par_pd.size() == 2 and par_pd[0] == c:
		var rival_pd: Club = par_pd[1]
		var base_pd := int(round(c.precio_entrada))
		var hoy_pd := h.precio_efectivo(base_pd, rival_pd.rep)
		var epd := p._texto(10, Principal.COL_VERDE if hoy_pd > base_pd else (Principal.COL_ROJO if hoy_pd < base_pd else Principal.COL_SUAVE))
		epd.text = Idiomas.t("Próximo partido en casa contra %s (rep %d): se cobraría %d en vez de %d.") % [
			rival_pd.nombre, rival_pd.rep, hoy_pd, base_pd]
		epd.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_estadio.add_child(epd)
