extends "res://ui/pantallas/pantalla_plantel_p2.gd"
## [Capa 3/4 de `pantalla_plantel.gd`] _pintar_premios, _pintar_juegos_mentales, _pintar_partido, _pintar_proximas_fechas, _pintar_calendario

## `vPremios()` del HTML: la gala de fin de año. El acta la calcula entera
## `Logros.premios_temporada()` desde hace tiempo -equipo ideal, mejor joven,
## mejor entrenador, fair play, club más popular, mejor hinchada, mejor
## estadio- y hasta hoy no se veía en ningún sitio: se calculaba, se guardaba y
## ahí moría. Esto es solo la vitrina de lo que ya se entregaba a puerta
## cerrada.
func _pintar_premios() -> void:
	p._limpiar(p._lista_premios)
	var lg := p.mundo.logros
	if lg == null or lg.premios.is_empty():
		var vacio := p._texto(12, Principal.COL_SUAVE)
		vacio.text = Idiomas.t("Las galas se celebran al cerrar cada temporada. Todavía no hay ninguna.")
		vacio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_premios.add_child(vacio)
		return
	for acta: Dictionary in lg.premios:
		var t := p._texto(13, Principal.COL_ORO)
		t.text = Idiomas.t("GALA %d") % int(acta.get("anio", 0))
		p._lista_premios.add_child(t)
		## Lo que se llevó TU club va primero y en verde: es lo que el jugador
		## viene a mirar. Si no ganó nada, se dice, en vez de dejar un hueco.
		var ganados: Array = acta.get("ganados", [])
		if ganados.is_empty():
			var nada := p._texto(12, Principal.COL_SUAVE)
			nada.text = Idiomas.t("Tu club se fue de vacío esta temporada.")
			p._lista_premios.add_child(nada)
		else:
			for premio in ganados:
				var g := p._texto(12, Principal.COL_VERDE)
				g.text = "🏆  %s" % String(premio)
				g.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				p._lista_premios.add_child(g)
		## `str()` y no `String()`: es la trampa 37 del proyecto -el constructor
		## `String()` revienta con tipos que `str()` traga sin quejarse-.
		p._dato("🎩 Mejor entrenador", str(acta.get("dt", "—")), Principal.COL_VERDE if bool(acta.get("dt_es_mio", false)) else Principal.COL_TEXTO, p._lista_premios)
		p._dato("🌱 Mejor joven", str(acta.get("joven", "—")), Principal.COL_TEXTO, p._lista_premios)
		p._dato("🤝 Fair Play", str(acta.get("fairplay", "—")), Principal.COL_VERDE if bool(acta.get("fairplay_es_mio", false)) else Principal.COL_TEXTO, p._lista_premios)
		p._dato("❤️ Club más popular", str(acta.get("popular", "—")), Principal.COL_TEXTO, p._lista_premios)
		p._dato("📣 Mejor hinchada", str(acta.get("hinchada", "—")), Principal.COL_VERDE if bool(acta.get("hinchada_es_mia", false)) else Principal.COL_TEXTO, p._lista_premios)
		p._dato("🏟️ Mejor estadio", str(acta.get("estadio", "—")), Principal.COL_VERDE if bool(acta.get("estadio_es_mio", false)) else Principal.COL_TEXTO, p._lista_premios)
		var ti := p._texto(11, Principal.COL_SUAVE)
		ti.text = Idiomas.t("EQUIPO IDEAL")
		p._lista_premios.add_child(ti)
		var ideal := p._texto(12, Principal.COL_TEXTO)
		## `acta["ideal"]` es un ARRAY de nombres, no un texto: `String()` de un
		## array no existe y reventaba en silencio al cerrar la temporada.
		var once_ideal: Array = acta.get("ideal", [])
		ideal.text = ", ".join(PackedStringArray(once_ideal)) if not once_ideal.is_empty() else "—"
		ideal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_premios.add_child(ideal)
		p._lista_premios.add_child(HSeparator.new())

## `vPrevia()` del HTML: la pantalla de antes del partido. Todo lo que enseña
## es DERIVADO -no toca ni guarda nada-, así que se puede repintar cuantas veces
## haga falta sin consecuencias. Usa el mismo emparejamiento que `_dirigir()`
## (la copa manda sobre la liga) para no enseñar un rival y jugar contra otro.
## LOS JUEGOS MENTALES de `vPrevia()`. `Prensa` ENCIENDE dos banderas —el sobre
## con el informe del rival y la promesa hecha en conferencia— y hasta ahora no
## las apagaba nadie: `consumir_dato_del_rival()` y `consumir_presion()` estaban
## escritas, probadas y sin una sola llamada en todo el proyecto. Pagabas 80.000
## por espiar al rival y no pasaba absolutamente nada.
##
## Aquí es donde tienen que cobrarse las dos: en la previa, que es el momento en
## que la información sirve para algo.
func _pintar_juegos_mentales(rival: Club) -> void:
	if p.mundo.prensa == null:
		return
	var p_local := p.mundo.prensa
	## EL NODO «LECTURA» DEL ARBOL da el informe del rival SIEMPRE, sin tener que
	## comprarlo. `ve_tactica_rival()` estaba escrita y no la llamaba nadie: la
	## habilidad que existe para leer al rival no leia nada.
	var por_arbol := p.mundo.entrenamiento != null and p.mundo.entrenamiento.ve_tactica_rival()
	if not p_local.dato_del_rival and not p_local.presion_prometida and not por_arbol:
		return
	var t := p._texto(11, Principal.COL_ORO)
	t.text = Idiomas.t("🎭 JUEGOS MENTALES")
	p._lista_partido.add_child(t)
	if p_local.dato_del_rival or por_arbol:
		## El informe del rival: el once que va a sacar y sus dos bajas. Se
		## consume al MIRAR la previa, no al jugar: lo que compraste fue saberlo
		## antes de decidir tu alineación, y si se gastara al pitido inicial
		## llegaría tarde para lo único que sirve.
		var e := p._texto(12, Principal.COL_VERDE)
		e.text = Idiomas.t("📄 Informe reservado: sabes con qué sale %s.") % rival.nombre
		p._lista_partido.add_child(e)
		var once := rival.once()
		var media := 0.0
		for j in once:
			media += float(j.ovr)
		if not once.is_empty():
			media /= float(once.size())
		p._dato("Once probable del rival", "media %.1f" % media, Principal.COL_TEXTO, p._lista_partido)
		var nombres: Array[String] = []
		for j2 in once:
			nombres.append("%s (%s)" % [j2.nombre, j2.pos_e])
		var l := p._texto(11, Principal.COL_SUAVE)
		l.text = ", ".join(nombres)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_partido.add_child(l)
		var bajas: Array[String] = []
		for j3 in rival.plantilla:
			if j3.lesion > 0 or j3.suspension > 0:
				bajas.append(j3.nombre)
		if not bajas.is_empty():
			p._dato("Bajas del rival", ", ".join(bajas), Principal.COL_VERDE, p._lista_partido)
		## EXTENSIÓN TÁCTICA (22-9-2026, Fase 3 del ROADMAP: "extender el
		## espionaje... a información táctica"). Mismo informe, más datos: con
		## qué mentalidad/presión/línea sale el rival, no solo su once. Lee
		## `rival.tactica` directo -el mismo dial que decide `multiplicador_
		## ataque()`/`multiplicador_defensa()` en el partido real, así que esto
		## nunca puede quedar desincronizado de lo que de verdad va a pasar-.
		##
		## CAVEAT HONESTO, no escondido: ningún club de la IA cambia su
		## `tactica` fuera de un partido en curso (`Tactica.plan_para()`, según
		## el marcador) o de un DT EMPLEADO en TU propio club
		## (`Roles.aplicar_directrices()`, que nunca toca un rival). Así que
		## para casi cualquier rival esto va a leer "Equilibrada / Media /
		## Media" siempre -el valor de fábrica de `Tactica`-, partido tras
		## partido. Es dato real y no inventado -si mañana algún club de la IA
		## sale con una mentalidad propia, este informe la va a leer
		## corectamente sin tocar una línea más-, pero se documenta la
		## limitación en vez de venderlo como más dinámico de lo que es: darle
		## personalidad táctica real a la IA tocaría el balance de CADA
		## partido de la liga (multiplicador_ataque/defensa), una decisión de
		## diseño más grande que esta pantalla, no tomada hoy sin que el
		## usuario la pida.
		var tact := rival.tactica
		## `: String =`, no `:=` -indexar un Array literal sin tipar no deja
		## que el analizador infiera el tipo ("Cannot infer the type... doesn't
		## have a set type"), un error de PARSEO real que se lleva puesto todo
		## `principal.gd` -no solo esta función-. Ya documentado una vez en
		## `ui/escudo.gd` (ver LEEME.md, "GENERADOR DE ESCUDOS, SEGUNDA
		## TANDA"), y esta vez lo atrapó `captura_previa.gd` con pantalla real
		## -el banco headless no carga `principal.gd`, así que "0 fallos" no
		## lo vio-.
		var ment_nombre: String = ["Defensiva", "Equilibrada", "Ofensiva"][tact.mentalidad]
		var nivel_nombre := ["Baja", "Media", "Alta"]
		p._dato("Mentalidad del rival", ment_nombre, Principal.COL_TEXTO, p._lista_partido)
		p._dato("Presión del rival", nivel_nombre[tact.presion], Principal.COL_TEXTO, p._lista_partido)
		p._dato("Línea defensiva del rival", nivel_nombre[tact.linea], Principal.COL_TEXTO, p._lista_partido)
		p_local.consumir_dato_del_rival()
	if p_local.presion_prometida:
		var pr := p._texto(12, Principal.COL_ORO)
		pr.text = Idiomas.t("🗣️ Prometiste ganar en rueda de prensa. Si no ganas, la hinchada te lo va a cobrar.")
		pr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_partido.add_child(pr)
	p._lista_partido.add_child(HSeparator.new())

func _pintar_partido(c: Club) -> void:
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
	cab.text = p.mundo.copa.nombre.to_upper() if es_copa else Idiomas.t("JORNADA %d  ·  %s") % [
		p._liga_de(c).jornada_actual, p._liga_de(c).nombre]
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

	_pintar_juegos_mentales(rival)

	var arb := Previa.arbitro_de(rival.id, p.mundo.semana)
	var con_el := p.mundo.federacion.texto_arbitro(String(arb["nombre"])) if p.mundo.federacion != null else ""
	p._dato("👨‍⚖️ Árbitro", "%s — %s%s" % [String(arb["nombre"]), String(arb["descripcion"]), ("  ·  " + con_el) if con_el != "" else ""], Principal.COL_SUAVE, p._lista_partido)
	var dtr := Previa.dt_de(rival)
	p._dato("🎩 DT rival", "%s — %s" % [String(dtr["nombre"]), String(dtr["descripcion"])], Principal.COL_SUAVE, p._lista_partido)
	p._lista_partido.add_child(HSeparator.new())

	## Las fuerzas salen de un `Partido` de mentira, montado solo para medir: es
	## el mismo cálculo que usará el de verdad, así que lo que dice la previa es
	## lo que va a pasar en el campo.
	var medidor := Partido.new(local, visita)
	medidor.preparar()
	var f_local := medidor.fuerza(medidor.once_local, local)
	var f_visita := medidor.fuerza(medidor.once_visita, visita)
	var f_mia: Dictionary = f_local if de_local else f_visita
	var f_suya: Dictionary = f_visita if de_local else f_local
	var ti := p._texto(11, Principal.COL_SUAVE)
	ti.text = Idiomas.t("INFORME")
	p._lista_partido.add_child(ti)
	p._dato("Tu ataque vs su defensa", "%d / %d" % [int(round(f_mia["ata"])), int(round(f_suya["def"]))], Principal.COL_TEXTO, p._lista_partido)
	p._dato("Tu defensa vs su ataque", "%d / %d" % [int(round(f_mia["def"])), int(round(f_suya["ata"]))], Principal.COL_TEXTO, p._lista_partido)

	var cuo := Previa.cuotas(f_mia, f_suya, de_local)
	var tc := p._texto(11, Principal.COL_SUAVE)
	tc.text = Idiomas.t("🎰 CASA DE APUESTAS")
	p._lista_partido.add_child(tc)
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
		p._dato("Mentalidad", [Idiomas.t("Defensiva"), Idiomas.t("Equilibrada"), Idiomas.t("Ofensiva")][rival.tactica.mentalidad], Principal.COL_TEXTO, p._lista_partido)
		p._dato("Punto débil", "la última línea" if f_suya["def"] < f_suya["ata"] else "la generación de juego", Principal.COL_TEXTO, p._lista_partido)

	## `vAlineacion()` del HTML: los dos onces tal como van a salir, con su
	## ranura en la formación y su dorsal. El `medidor` de arriba ya los tiene
	## armados -es el mismo `preparar()` que usará el partido de verdad-, así
	## que enseñarlos no cuesta ni un cálculo más.
	p._lista_partido.add_child(HSeparator.new())
	var ta := p._texto(11, Principal.COL_SUAVE)
	ta.text = Idiomas.t("LOS ONCES")
	p._lista_partido.add_child(ta)
	var g := GridContainer.new()
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
			g.add_child(p._retrato(jl, 22))
			p._celda(g, "%s  %s" % [jl.pos_e, jl.nombre], Principal.COL_TEXTO, false, 11)
		else:
			p._celda(g, "", Principal.COL_SUAVE)
			p._celda(g, "", Principal.COL_SUAVE)
		if i < medidor.once_visita.size():
			var jv: Jugador = medidor.once_visita[i]
			g.add_child(p._retrato(jv, 22))
			p._celda(g, "%s  %s" % [jv.pos_e, jv.nombre], Principal.COL_TEXTO, false, 11)
		else:
			p._celda(g, "", Principal.COL_SUAVE)
			p._celda(g, "", Principal.COL_SUAVE)

	p._lista_partido.add_child(HSeparator.new())
	p._selector_modo_partido(p._lista_partido)
	p._boton("▶ Jugar el partido", p._dirigir, p._lista_partido)

## `vCalendario` -pantalla nueva, sin equivalente en el HTML-: el usuario la
## pidió después de ver una referencia de otro manager (grilla con los
## próximos partidos marcados, escudo del rival, desde la que se simula de
## corrido o se salta el partido entero sin dirigirlo). En vez de inventar un
## sistema de fechas nuevo, lee el mismo `Liga.calendario` que ya arma la
## temporada entera desde el sorteo.
## C13: lo que viene en el calendario del país (fiestas, memoria, festividades)
## y el gran torneo del año, si lo hay.
func _pintar_proximas_fechas(c: Club) -> void:
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("PRÓXIMAS FECHAS EN %s") % c.pais
	p._lista_calendario.add_child(t)
	for f: Dictionary in Calendario.proximas(c.pais, p.mundo.anio, p.mundo.semana, 5):
		var l := p._texto(12, Principal.COL_ROJO if String(f["tipo"]) == "memoria" else Principal.COL_TEXTO)
		var faltan := int(f["faltan"])
		var cuando := "%d de %s" % [int(f["dia"]), Principal.MESES_LARGOS[int(f["mes"]) - 1]]
		## "11 de septiembre" ya es la fecha: no repetirla.
		var nom := String(f["nombre"])
		l.text = "%s %s%s  (%s)" % [Calendario.icono(String(f["tipo"])), cuando,
			"" if nom == cuando else " · " + nom, Idiomas.t("esta semana") if faltan < 7 else Idiomas.t("en %d días") % faltan]
		l.tooltip_text = String(f["texto"])
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		p._lista_calendario.add_child(l)
	for tor: Dictionary in Calendario.torneos(p.mundo.anio):
		var sedes: Array = tor["sedes"]
		var l2 := p._texto(12, Principal.COL_ORO)
		l2.text = Idiomas.t("🌍 %s %d: del %d/%d al %d/%d%s") % [String(tor["nombre"]), p.mundo.anio,
			int(tor["desde"][1]), int(tor["desde"][0]), int(tor["hasta"][1]), int(tor["hasta"][0]),
			(Idiomas.t(" · sede: ") + ", ".join(sedes)) if not sedes.is_empty() else ""]
		p._lista_calendario.add_child(l2)
	p._lista_calendario.add_child(HSeparator.new())

func _pintar_calendario(c: Club) -> void:
	p._limpiar(p._lista_calendario)
	if not p.mundo.temporada_en_curso():
		var fin := p._texto(13, Principal.COL_SUAVE)
		fin.text = Idiomas.t("La temporada está terminada. Pulsa «Temporada siguiente».")
		p._lista_calendario.add_child(fin)
		return

	_pintar_proximas_fechas(c)
	## PRÓXIMO PARTIDO, con el MISMO orden que usa `_dirigir()` -copa antes que
	## liga-: mostrar aquí un partido distinto del que se juega al pulsar el
	## botón sería peor que no mostrar nada.
	var tp := p._texto(11, Principal.COL_SUAVE)
	tp.text = Idiomas.t("PRÓXIMO PARTIDO")
	p._lista_calendario.add_child(tp)
	var par := p.mundo.partido_de_copa()
	var es_copa := not par.is_empty()
	if not es_copa:
		par = p.mundo.proximo_partido()
	if par.is_empty():
		var descansa := p._texto(13, Principal.COL_SUAVE)
		descansa.text = Idiomas.t("Tu club descansa esta jornada.")
		p._lista_calendario.add_child(descansa)
	else:
		var local: Club = par[0]
		var visita: Club = par[1]
		var de_local := local == c
		var rival: Club = visita if de_local else local
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		p._lista_calendario.add_child(fila)
		fila.add_child(p._escudo(rival, 36))
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(info)
		var nom := p._texto(15, Principal.COL_TEXTO)
		nom.text = rival.nombre
		info.add_child(nom)
		var sub := p._texto(11, Principal.COL_SUAVE)
		sub.text = "%s  ·  %s" % [
			p.mundo.copa.nombre if es_copa else p._liga_de(c).nombre,
			Idiomas.t("Local") if de_local else Idiomas.t("Visitante")]
		info.add_child(sub)
		## Si además hay ronda continental esta misma semana -`CONTI_EN` no
		## evita que caiga junto a una jornada normal, ver nota en el LEEME-,
		## se avisa aparte: el botón de abajo dirige lo mismo que dirigiría
		## `_dirigir()`, nunca el continental, así que mostrarlo como "el
		## próximo partido" habría sido mentir.
		var mi_conti := p.mundo.mi_continental()
		if Continental.toca_ronda(p.mundo.semana) >= 0 and mi_conti != null and mi_conti.en_curso():
			var av := p._texto(10, Principal.COL_ORO)
			av.text = Idiomas.t("También hay ronda de %s esta semana.") % Continental.nombre_conti(mi_conti.clave)
			av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			info.add_child(av)
		if p.mundo.es_clasico(c, rival):
			var clasico := p._texto(12, Principal.COL_ORO)
			var nom_cl2 := HistoriaClub.nombre_clasico(c.nombre, rival.nombre)
			clasico.text = "🔥 ¡%s!" % (nom_cl2 if nom_cl2 != "" else Idiomas.t("Es clásico"))
			p._lista_calendario.add_child(clasico)
		var filab := HBoxContainer.new()
		filab.add_theme_constant_override("separation", 6)
		p._lista_calendario.add_child(filab)
		p._selector_modo_partido(p._lista_calendario)
		p._lista_calendario.move_child(filab, p._lista_calendario.get_child_count() - 1)
		p._boton("▶ Jugar el partido", p._dirigir, filab)

	p._lista_calendario.add_child(HSeparator.new())
	p._boton("⏭⏭ Simular toda la temporada", p._jugar_temporada, p._lista_calendario)
	p._lista_calendario.add_child(HSeparator.new())

	## EL CALENDARIO DE LIGA COMPLETO. Se recorre `Liga.calendario` a mano -no
	## `emparejamiento_de()`, que solo conoce la jornada ACTUAL- desde hoy
	## hasta el final: son datos que ya existen enteros desde que se sorteó la
	## temporada, así que enseñarlos no inventa nada nuevo, solo lo hace
	## visible.
	var liga := p._liga_de(c)
	var tl := p._texto(11, Principal.COL_SUAVE)
	tl.text = Idiomas.t("CALENDARIO DE %s") % liga.nombre.to_upper()
	p._lista_calendario.add_child(tl)
	for i in range(liga.jornada_actual, liga.calendario.size()):
		var jornada: Array = liga.calendario[i]
		for pareja: Array in jornada:
			var loc: Club = pareja[0]
			var vis: Club = pareja[1]
			if loc != c and vis != c:
				continue
			var de_loc := loc == c
			var riv: Club = vis if de_loc else loc
			var actual := i == liga.jornada_actual
			var fj := HBoxContainer.new()
			fj.add_theme_constant_override("separation", 8)
			p._lista_calendario.add_child(fj)
			var lj := p._texto(11, Principal.COL_ORO if actual else Principal.COL_SUAVE)
			lj.text = "J%d" % (i + 1)
			lj.custom_minimum_size = Vector2(34, 0)
			fj.add_child(lj)
			fj.add_child(p._escudo(riv, 20))
			var nj := p._texto(12, Principal.COL_TEXTO if actual else Principal.COL_SUAVE)
			nj.text = "%s  (%s)" % [riv.nombre, "L" if de_loc else "V"]
			nj.clip_text = true
			nj.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fj.add_child(nj)
			break
