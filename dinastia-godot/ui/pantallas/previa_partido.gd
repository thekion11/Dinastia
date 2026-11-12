class_name PreviaPartido
extends RefCounted
## LA PREVIA DEL PRÓXIMO PARTIDO (pestaña «Partido»). Salió de `pantalla_plantel_p3.gd` el 12-11 al partirla en TRES PANTALLAS (nota del dueño:
## menús subdivididos a pantalla completa, como el PES 2020), una por submenú de «Partido» (`p._secc_extra["Partido"]`):
##   previa  → juegos mentales, árbitro y DT rival      informe → fuerzas, casa de apuestas e informe del rival      onces → los dos onces
## Las tres llevan arriba el cartel del partido y la banda de cuotas (`CifrasClave`) y abajo el botón de jugar. Otra sección = todo, como antes.
const SECCIONES := ["previa", "informe", "onces"]

static func pintar(p: Principal, pantalla: Object, c: Club) -> void:
	p._limpiar(p._lista_partido)
	if not p.mundo.temporada_en_curso():
		var fin := p._texto(13, Principal.COL_SUAVE)
		fin.text = Idiomas.t("La temporada está terminada. Pulsa «Temporada siguiente».")
		p._lista_partido.add_child(fin)
		return
	var par := p.mundo.partido_de_copa()
	var es_copa := not par.is_empty()
	if not es_copa:
		par = p.mundo.proximo_partido()
	if par.is_empty():
		var descansa := p._texto(13, Principal.COL_SUAVE)
		descansa.text = Idiomas.t("Tu club descansa esta jornada.")
		p._lista_partido.add_child(descansa)
		return

	var local: Club = par[0]
	var visita: Club = par[1]
	var de_local := local == c
	var rival: Club = visita if de_local else local

	var cab := p._texto(11, Principal.COL_SUAVE)
	cab.text = Idiomas.mayusculas(CompeticionInfo.nombre_visible(p.mundo.copa.nombre)) if es_copa else Idiomas.t("JORNADA %d  ·  %s") % [
		p._liga_de(c).jornada_actual, CompeticionInfo.nombre_visible(p._liga_de(c).nombre)]
	p._lista_partido.add_child(cab)
	var vs := p._texto(17, Principal.COL_TEXTO)
	vs.text = "%s   vs   %s" % [local.nombre, visita.nombre]
	p._lista_partido.add_child(vs)
	var donde := p._texto(12, Principal.COL_SUAVE)
	donde.text = Idiomas.t("Juegas de %s  ·  %s") % [Idiomas.t("LOCAL") if de_local else Idiomas.t("VISITA"), rival.nombre]
	p._lista_partido.add_child(donde)
	if p.mundo.es_clasico(c, rival):
		var clasico := p._texto(13, Principal.COL_ORO)
		var nom_cl := HistoriaClub.nombre_clasico(c.nombre, rival.nombre)
		clasico.text = "🔥 ¡%s!" % (nom_cl.to_upper() if nom_cl != "" else Idiomas.t("ES CLÁSICO"))
		p._lista_partido.add_child(clasico)
	## LA FRASE DE LA PARED, justo antes de salir. Es lo que el HTML prometia
	## en la pantalla del club por dentro -"se lee en el tunel antes de cada
	## partido"- y no cumplia en ninguna parte.
	if p.mundo.club_dentro != null and p.mundo.club_dentro.frase != "":
		var fr := p._texto(13, Color(p.mundo.club_dentro.color_ct2(c)))
		fr.text = "«%s»" % p.mundo.club_dentro.frase
		fr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p._lista_partido.add_child(fr)
		var fr2 := p._texto(10, Principal.COL_SUAVE)
		fr2.text = Idiomas.t("En la pared del túnel")
		fr2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p._lista_partido.add_child(fr2)
	p._lista_partido.add_child(HSeparator.new())

	var secc := String(p._secc_extra.get("Partido", "previa"))
	var todo := not SECCIONES.has(secc)
	## Las fuerzas salen de un `Partido` de mentira, montado solo para medir: es
	## el mismo cálculo que usará el de verdad, así que lo que dice la previa es
	## lo que va a pasar en el campo.
	var medidor := Partido.new(local, visita)
	medidor.preparar()
	var f_local := medidor.fuerza(medidor.once_local, local)
	var f_visita := medidor.fuerza(medidor.once_visita, visita)
	var f_mia: Dictionary = f_local if de_local else f_visita
	var f_suya: Dictionary = f_visita if de_local else f_local
	var cuo := Previa.cuotas(f_mia, f_suya, de_local)
	if not todo:
		p._lista_partido.get_child(p._lista_partido.get_child_count() - 1).queue_free()   ## el separador del cartel: la banda ya separa
		p._lista_partido.add_child(CifrasClave.banda([
			[Idiomas.t("Ganas tú"), "%.2f" % float(cuo["cuota_gano"]), SelectorDireccional.acento_legible(p.COL_ACENTO)],
			[Idiomas.t("Empate"), "%.2f" % float(cuo["cuota_empate"]), Principal.COL_SUAVE],
			[Idiomas.t("Gana %s") % rival.nombre, "%.2f" % float(cuo["cuota_pierdo"]), Principal.COL_TEXTO],
			[Idiomas.t("Tu ataque vs su defensa"), "%d / %d" % [int(round(f_mia["ata"])), int(round(f_suya["def"]))], Principal.COL_ORO]], Principal.COL_SUAVE))
	if todo or secc == "previa":
		pantalla._pintar_juegos_mentales(rival)

		var arb := Previa.arbitro_de(rival.id, p.mundo.semana)
		var con_el := p.mundo.federacion.texto_arbitro(String(arb["nombre"])) if p.mundo.federacion != null else ""
		p._dato("👨‍⚖️ Árbitro", "%s — %s%s" % [String(arb["nombre"]), String(arb["descripcion"]), ("  ·  " + con_el) if con_el != "" else ""], Principal.COL_SUAVE, p._lista_partido)
		var dtr := Previa.dt_de(rival)
		p._dato("🎩 DT rival", "%s — %s" % [String(dtr["nombre"]), String(dtr["descripcion"])], Principal.COL_SUAVE, p._lista_partido)
		p._lista_partido.add_child(HSeparator.new())

	if todo or secc == "informe":
		var ti := p._texto(11, Principal.COL_SUAVE)
		ti.text = Idiomas.t("INFORME")
		p._lista_partido.add_child(ti)
		p._dato("Tu ataque vs su defensa", "%d / %d" % [int(round(f_mia["ata"])), int(round(f_suya["def"]))], Principal.COL_TEXTO, p._lista_partido)
		p._dato("Tu defensa vs su ataque", "%d / %d" % [int(round(f_mia["def"])), int(round(f_suya["ata"]))], Principal.COL_TEXTO, p._lista_partido)

		var tc := p._texto(11, Principal.COL_SUAVE)
		tc.text = Idiomas.t("🎰 CASA DE APUESTAS")
		p._lista_partido.add_child(tc)
		if todo:   ## en su pantalla, las cuotas ya están en la banda de arriba
			p._dato("Ganas tú", "%.2f" % float(cuo["cuota_gano"]), Principal.COL_TEXTO, p._lista_partido)
			p._dato("Empate", "%.2f" % float(cuo["cuota_empate"]), Principal.COL_SUAVE, p._lista_partido)
			p._dato("Gana %s" % rival.nombre, "%.2f" % float(cuo["cuota_pierdo"]), Principal.COL_TEXTO, p._lista_partido)
		var lectura := p._texto(11, Principal.COL_SUAVE)
		var p_gano: float = cuo["p_gano"]
		var p_pierdo: float = cuo["p_pierdo"]
		var p_empate: float = cuo["p_empate"]
		if p_gano > p_pierdo + 0.08 and p_gano > p_empate:
			lectura.text = Idiomas.t("Las cuotas te tienen como favorito: si el resultado no acompaña, la prensa y la hinchada lo van a leer peor de lo normal.")
		elif p_pierdo > p_gano + 0.08 and p_pierdo > p_empate:
			lectura.text = Idiomas.t("Vas de underdog en las apuestas: sumar acá se festeja como una machada.")
		else:
			lectura.text = Idiomas.t("Cuotas parejas: partido de pronóstico cerrado, sin favorito claro para las casas.")
		lectura.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_partido.add_child(lectura)

		## El informe del rival no es gratis: en el HTML pide la habilidad `lectura`
		## del DT o haberlo espiado. Aquí lo abre la sala de vídeo -`Instalaciones.
		## lectura_del_rival()`, que ya existía y no la miraba nadie-: si has
		## construido el análisis, ves su plan; si no, no.
		if p.mundo.obras.lectura_del_rival() > 0:
			p._lista_partido.add_child(HSeparator.new())
			var tv := p._texto(11, Principal.COL_SUAVE)
			tv.text = Idiomas.t("👁️ INFORME DEL RIVAL  (sala de vídeo)")
			p._lista_partido.add_child(tv)
			p._dato("Sistema previsto", rival.tactica.formacion, Principal.COL_TEXTO, p._lista_partido)
			p._dato("Estilo", Idiomas.t(String(EstiloClub.NOMBRES.get(EstiloClub.estilo_de(rival), "Equilibrado"))), Principal.COL_TEXTO, p._lista_partido)   ## (10-11) el de la vida real
			p._dato("Mentalidad", [Idiomas.t("Defensiva"), Idiomas.t("Equilibrada"), Idiomas.t("Ofensiva")][rival.tactica.mentalidad], Principal.COL_TEXTO, p._lista_partido)
			p._dato("Punto débil", "la última línea" if f_suya["def"] < f_suya["ata"] else "la generación de juego", Principal.COL_TEXTO, p._lista_partido)

	if todo or secc == "onces":
		## `vAlineacion()` del HTML: los dos onces tal como van a salir, con su
		## ranura en la formación y su dorsal. El `medidor` de arriba ya los tiene
		## armados -es el mismo `preparar()` que usará el partido de verdad-, así
		## que enseñarlos no cuesta ni un cálculo más.
		p._lista_partido.add_child(HSeparator.new())
		var ta := p._texto(11, Principal.COL_SUAVE)
		ta.text = Idiomas.t("LOS ONCES")
		p._lista_partido.add_child(ta)
		var g := GridContainer.new()
		CebraRejilla.poner(g)
		g.columns = 4
		g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_theme_constant_override("h_separation", 12)
		p._lista_partido.add_child(g)
		p._celda(g, "", Principal.COL_SUAVE)
		p._celda(g, "%s  (%s)" % [local.nombre, local.tactica.formacion], p.COL_ACENTO if de_local else Principal.COL_TEXTO, false, 12)
		p._celda(g, "", Principal.COL_SUAVE)
		p._celda(g, "%s  (%s)" % [visita.nombre, visita.tactica.formacion], Principal.COL_TEXTO if de_local else p.COL_ACENTO, false, 12)
		for i in maxi(medidor.once_local.size(), medidor.once_visita.size()):
			if i < medidor.once_local.size():
				var jl: Jugador = medidor.once_local[i]
				g.add_child(p._retrato(jl, Principal.RETRATO_FILA))
				p._celda(g, "%s  %s" % [jl.pos_e, jl.nombre], Principal.COL_TEXTO, false, 11)
			else:
				p._celda(g, "", Principal.COL_SUAVE)
				p._celda(g, "", Principal.COL_SUAVE)
			if i < medidor.once_visita.size():
				var jv: Jugador = medidor.once_visita[i]
				g.add_child(p._retrato(jv, Principal.RETRATO_FILA))
				p._celda(g, "%s  %s" % [jv.pos_e, jv.nombre], Principal.COL_TEXTO, false, 11)
			else:
				p._celda(g, "", Principal.COL_SUAVE)
				p._celda(g, "", Principal.COL_SUAVE)

	p._lista_partido.add_child(HSeparator.new())
	p._selector_modo_partido(p._lista_partido)
	p._boton("▶ Jugar el partido", p._dirigir, p._lista_partido)
