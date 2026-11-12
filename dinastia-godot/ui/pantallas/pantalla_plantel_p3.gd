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
		## `ui/escudo.gd` (ver LEEME.md del historial de git, "GENERADOR DE ESCUDOS, SEGUNDA
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

## La previa del próximo partido: desde el 12-11 vive en `PreviaPartido` (tres pantallas: previa, informe y onces).
func _pintar_partido(c: Club) -> void:
	PreviaPartido.pintar(p, self, c)

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
		l.text = "%s %s%s  (%s)" % [Calendario.icono(String(f["tipo"])), Idiomas.t(cuando),
			"" if nom == cuando else " · " + Idiomas.t(nom), Idiomas.t("esta semana") if faltan < 7 else Idiomas.t("en %d días") % faltan]
		l.tooltip_text = Idiomas.t(String(f["texto"]))
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		p._lista_calendario.add_child(l)
	for tor: Dictionary in Calendario.torneos(p.mundo.anio):
		var sedes: Array = tor["sedes"]
		var l2 := p._texto(12, Principal.COL_ORO)
		l2.text = Idiomas.t("🌍 %s %d: del %d/%d al %d/%d%s") % [CompeticionInfo.nombre_visible(String(tor["nombre"])), p.mundo.anio,
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
			CompeticionInfo.nombre_visible(p.mundo.copa.nombre if es_copa else p._liga_de(c).nombre),
			Idiomas.t("Local") if de_local else Idiomas.t("Visitante")]
		info.add_child(sub)
		## Si además hay ronda continental esta misma semana -`CONTI_EN` no
		## evita que caiga junto a una jornada normal, ver nota en el LEEME-,
		## se avisa aparte: el botón de abajo dirige lo mismo que dirigiría
		## `_dirigir()`, nunca el continental, así que mostrarlo como "el
		## próximo partido" habría sido mentir.
		var mi_conti := p.mundo.mi_continental()
		if mi_conti != null and mi_conti.toca(p.mundo.semana):
			var av := p._texto(10, Principal.COL_ORO)
			av.text = Idiomas.t("También hay ronda de %s esta semana.") % CompeticionInfo.nombre_visible(Continental.nombre_conti(mi_conti.clave))
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

	p._lista_calendario.add_child(HSeparator.new())   ## (9-11) sin «Simular toda la temporada»

	## EL CALENDARIO DE LIGA COMPLETO. Se recorre `Liga.calendario` a mano -no
	## `emparejamiento_de()`, que solo conoce la jornada ACTUAL- desde hoy
	## hasta el final: son datos que ya existen enteros desde que se sorteó la
	## temporada, así que enseñarlos no inventa nada nuevo, solo lo hace
	## visible.
	var liga := p._liga_de(c)
	var tl := p._texto(11, Principal.COL_SUAVE)
	tl.text = Idiomas.t("CALENDARIO DE %s") % Idiomas.mayusculas(CompeticionInfo.nombre_visible(liga.nombre))
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
