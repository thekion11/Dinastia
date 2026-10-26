class_name PantallaLegado
extends "res://ui/pantallas/pantalla_legado_p2.gd"
## [Capa 3/3 de `pantalla_legado.gd`] _pintar_records

func _pintar_records() -> void:
	p._limpiar(p._lista_records)
	var lg := p.mundo.logros
	if lg == null:
		return

	var tr := p._texto(11, Principal.COL_SUAVE)
	tr.text = Idiomas.t("RACHAS")
	p._lista_records.add_child(tr)
	var gr := GridContainer.new()
	gr.columns = 4
	gr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gr.add_theme_constant_override("h_separation", 14)
	p._lista_records.add_child(gr)
	var r: Dictionary = lg.rachas
	for par in [["Invicto máximo", "invicto_max"], ["Más victorias seguidas", "ganando_max"],
			["Peor sequía", "sin_ganar_max"], ["Racha actual", "invicto"]]:
		var col := VBoxContainer.new()
		gr.add_child(col)
		var et := p._texto(10, Principal.COL_SUAVE)
		et.text = Idiomas.t(String(par[0]))
		col.add_child(et)
		var va := p._texto(16, Principal.COL_TEXTO)
		va.text = str(int(r.get(par[1], 0)))
		col.add_child(va)
	p._lista_records.add_child(HSeparator.new())

	var rec: Dictionary = lg.rec
	if rec.has("mayor_goleada"):
		var tm := p._texto(11, Principal.COL_SUAVE)
		tm.text = Idiomas.t("MARCAS DEL CLUB")
		p._lista_records.add_child(tm)
		var mg: Dictionary = rec["mayor_goleada"]
		p._dato("Mayor goleada", Idiomas.t("%s con %s (%d)") % [String(mg.get("marcador", "")), String(mg.get("rival", "")), int(mg.get("anio", 0))], Principal.COL_VERDE, p._lista_records)
		if rec.has("peor_derrota"):
			var pd: Dictionary = rec["peor_derrota"]
			p._dato("Peor derrota", Idiomas.t("%s con %s (%d)") % [String(pd.get("marcador", "")), String(pd.get("rival", "")), int(pd.get("anio", 0))], Principal.COL_ROJO, p._lista_records)
		if rec.has("mas_goles"):
			var mgo: Dictionary = rec["mas_goles"]
			p._dato("Más goles en un partido", "%d vs %s (%d)" % [int(mgo.get("g", 0)), String(mgo.get("rival", "")), int(mgo.get("anio", 0))], Principal.COL_TEXTO, p._lista_records)
		if rec.has("mas_publico"):
			var mp: Dictionary = rec["mas_publico"]
			p._dato("Récord de público", "%s vs %s (%d)" % [p._miles(int(mp.get("n", 0))), String(mp.get("rival", "")), int(mp.get("anio", 0))], Principal.COL_TEXTO, p._lista_records)
		p._lista_records.add_child(HSeparator.new())

	## `vMemoria()`: el salón de la fama. No es una lista guardada aparte -sería
	## otro sitio más que mantener al día-: sale de los goles, los partidos y los
	## títulos que ya se llevan anotados. Estar en el once de un título pesa
	## mucho, que es lo que separa a un buen jugador de uno que se recuerda.
	var fama := lg.salon_de_la_fama(12)
	if not fama.is_empty():
		var tf := p._texto(11, Principal.COL_SUAVE)
		tf.text = Idiomas.t("SALÓN DE LA FAMA DEL CLUB")
		p._lista_records.add_child(tf)
		for i in fama.size():
			var f3: Dictionary = fama[i]
			var col_f := Principal.COL_ORO if int(f3["titulos"]) > 0 else Principal.COL_TEXTO
			p._dato("%d.  %s%s" % [i + 1, "🏆 " if int(f3["titulos"]) > 0 else "", String(f3["nombre"])],
				Idiomas.t(String(f3["motivo"])), col_f, p._lista_records)
		p._lista_records.add_child(HSeparator.new())

	var goleadores := lg.goleadores_historicos(10)
	if not goleadores.is_empty():
		var tg := p._texto(11, Principal.COL_SUAVE)
		tg.text = Idiomas.t("GOLEADORES HISTÓRICOS DE TU ERA")
		p._lista_records.add_child(tg)
		for i in goleadores.size():
			var f: Dictionary = goleadores[i]
			p._dato("%d.  %s" % [i + 1, String(f["nombre"])], str(int(f["goles"])), Principal.COL_TEXTO, p._lista_records)
		p._lista_records.add_child(HSeparator.new())

	var mas_pj := lg.mas_partidos(10)
	if not mas_pj.is_empty():
		var tp := p._texto(11, Principal.COL_SUAVE)
		tp.text = Idiomas.t("MÁS PARTIDOS DISPUTADOS")
		p._lista_records.add_child(tp)
		for i in mas_pj.size():
			var f2: Dictionary = mas_pj[i]
			p._dato("%d.  %s" % [i + 1, String(f2["nombre"])], str(int(f2["partidos"])), Principal.COL_TEXTO, p._lista_records)
		p._lista_records.add_child(HSeparator.new())

	if not lg.h2h.is_empty():
		var th := p._texto(11, Principal.COL_SUAVE)
		th.text = Idiomas.t("CARA A CARA")
		p._lista_records.add_child(th)
		var g2 := GridContainer.new()
		g2.columns = 5
		g2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g2.add_theme_constant_override("h_separation", 10)
		p._lista_records.add_child(g2)
		for t2 in ["CLUB", "PJ", "G", "E", "P"]:
			p._celda(g2, CompeticionFilas.sigla(t2), Principal.COL_SUAVE, t2 != "CLUB", 11)
		var ids := lg.h2h.keys()
		ids.sort_custom(func(a: String, b: String) -> bool: return int(lg.h2h[a]["pj"]) > int(lg.h2h[b]["pj"]))
		for id: String in ids:
			var h: Dictionary = lg.h2h[id]
			var rival: Club = p.mundo.clubes.get(id)
			## Los clásicos se marcan: `es_clasico()` ya existía -se portó para
			## el desafío "derbis"- y no la miraba ninguna pantalla. Un cara a
			## cara sin saber cuál de esos rivales es EL rival es media tabla.
			var es_derbi := rival != null and p.mundo.es_clasico(p.mundo.mi_club(), rival)
			p._celda(g2, ("🔥 %s" % rival.nombre) if es_derbi else (rival.nombre if rival != null else "?"),
				Principal.COL_ORO if es_derbi else Principal.COL_TEXTO)
			p._celda(g2, str(int(h["pj"])), Principal.COL_TEXTO, true)
			p._celda(g2, str(int(h["pg"])), Principal.COL_VERDE, true)
			p._celda(g2, str(int(h["pe"])), Principal.COL_SUAVE, true)
			p._celda(g2, str(int(h["pp"])), Principal.COL_ROJO, true)
		p._lista_records.add_child(HSeparator.new())

	if not lg.efemerides.is_empty():
		var te := p._texto(11, Principal.COL_SUAVE)
		te.text = Idiomas.t("UN DÍA COMO HOY")
		p._lista_records.add_child(te)
		var efes: Array = lg.efemerides
		for i in range(efes.size() - 1, maxi(-1, efes.size() - 11), -1):
			var e: Dictionary = efes[i]
			var le := p._texto(11, Principal.COL_SUAVE)
			le.text = "S%d/%d  ·  %s" % [int(e.get("semana", 0)), int(e.get("anio", 0)), Idiomas.t(String(e.get("texto", "")))]
			le.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_records.add_child(le)
		p._lista_records.add_child(HSeparator.new())

	if not lg.planteles.is_empty():
		var tpl := p._texto(11, Principal.COL_SUAVE)
		tpl.text = Idiomas.t("ARCHIVO DE PLANTELES")
		p._lista_records.add_child(tpl)
		if not p._modo_experto:
			var epl := p._texto(10, Principal.COL_SUAVE)
			epl.text = Idiomas.t("Pulsa un año para abrir aquel plantel entero: quién estaba, con qué dorsal, cuánto jugó y cuánto marcó.")
			epl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_records.add_child(epl)
		var pls: Array = lg.planteles
		for i in range(pls.size() - 1, maxi(-1, pls.size() - 9), -1):
			var p_local: Dictionary = pls[i]
			var anio_p := int(p_local.get("anio", 0))
			var abierto := p._plantel_abierto == anio_p
			var bp := Button.new()
			bp.text = Idiomas.t("%s%d  ·  %dº  ·  MVP: %s") % ["▾ " if abierto else "▸ ", anio_p,
				int(p_local.get("puesto", 0)), String(p_local.get("mvp", "—"))]
			bp.flat = true
			bp.alignment = HORIZONTAL_ALIGNMENT_LEFT
			bp.add_theme_font_size_override("font_size", 12)
			bp.add_theme_color_override("font_color", p._color_de_paleta(Principal.COL_ORO if abierto else Principal.COL_TEXTO))
			bp.pressed.connect(func() -> void:
				p._plantel_abierto = 0 if p._plantel_abierto == anio_p else anio_p
				p._refrescar())
			p._lista_records.add_child(bp)
			if not abierto:
				continue
			var rej := GridContainer.new()
			rej.columns = 6
			rej.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			p._lista_records.add_child(rej)
			for cab: String in ["#", "Pos", "Nombre", "Media", "PJ", "Goles"]:
				p._celda(rej, cab, Principal.COL_SUAVE, cab != "Nombre" and cab != "Pos")
			for reg: Variant in (p_local.get("jugadores", []) as Array):
				## LOS ARCHIVOS VIEJOS guardaban una cadena "Fulano (78)" y no un
				## registro. Se siguen leyendo: una partida de hace veinte
				## temporadas no debería perder su memoria por un cambio de
				## formato.
				if reg is Dictionary:
					var d: Dictionary = reg
					p._celda(rej, str(int(d.get("d", 0))) if int(d.get("d", 0)) > 0 else "·", Principal.COL_SUAVE, true)
					p._celda(rej, String(d.get("pos", "")), Principal.COL_SUAVE, false)
					p._celda(rej, String(d.get("n", "")), Principal.COL_TEXTO, false)
					p._celda(rej, str(int(d.get("ovr", 0))), Principal.COL_TEXTO, true)
					p._celda(rej, str(int(d.get("pj", 0))), Principal.COL_SUAVE, true)
					p._celda(rej, str(int(d.get("g", 0))), Principal.COL_ORO if int(d.get("g", 0)) > 0 else Principal.COL_SUAVE, true)
				else:
					p._celda(rej, "·", Principal.COL_SUAVE, true)
					p._celda(rej, "", Principal.COL_SUAVE, false)
					p._celda(rej, str(reg), Principal.COL_TEXTO, false)
					p._celda(rej, "—", Principal.COL_SUAVE, true)
					p._celda(rej, "—", Principal.COL_SUAVE, true)
					p._celda(rej, "—", Principal.COL_SUAVE, true)
