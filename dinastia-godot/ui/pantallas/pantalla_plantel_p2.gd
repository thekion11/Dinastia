extends "res://ui/pantallas/pantalla_plantel_p1.gd"
## [Capa 2/4 de `pantalla_plantel.gd`] _pintar_tactica, _pintar_desafios, _pintar_rivalidades, _frase_clasico, _historia_de, _pintar_ficha_club … (+1)

## La pestaña de Táctica: desde el 12-11 vive en `TacticaSecciones` (cuatro pantallas: pizarra, órdenes, balón parado y el once).
func _pintar_tactica(c: Club) -> void:
	TacticaSecciones.pintar(p, self, c)

## `vDesafios()` del HTML: el puntaje de la carrera y los ocho desafíos. Se
## eligen al empezar la partida y no cambian, pero hasta hoy, una vez dentro,
## no había forma de recordar cuáles llevabas ni de ver para qué servían -el
## multiplicador es la única razón de elegir uno duro-.
func _pintar_desafios() -> void:
	p._limpiar(p._lista_desafios)
	var p_local := p.mundo.puntaje_carrera()
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("PUNTAJE DE CARRERA")
	p._lista_desafios.add_child(t)
	var total := p._texto(22, Principal.COL_ORO)
	total.text = p._miles(int(p_local["total"]))
	p._lista_desafios.add_child(total)
	var mult := p._texto(12, Principal.COL_SUAVE)
	mult.text = Idiomas.t("%s de base  ×  %.2f de multiplicador") % [p._miles(int(p_local["base"])), float(p_local["multiplicador"])]
	p._lista_desafios.add_child(mult)
	p._lista_desafios.add_child(HSeparator.new())

	var td := p._texto(11, Principal.COL_SUAVE)
	td.text = Idiomas.t("DE DÓNDE SALE")
	p._lista_desafios.add_child(td)
	p._dato("Títulos  (× 1.000)", "%d  →  %s" % [int(p_local["titulos"]), p._miles(int(p_local["titulos"]) * 1000)], Principal.COL_TEXTO, p._lista_desafios)
	p._dato("Prestigio  (× 40)", "%d  →  %s" % [int(p_local["prestigio"]), p._miles(int(p_local["prestigio"]) * 40)], Principal.COL_TEXTO, p._lista_desafios)
	p._dato("Logros  (× 300)", "%d  →  %s" % [int(p_local["logros"]), p._miles(int(p_local["logros"]) * 300)], Principal.COL_TEXTO, p._lista_desafios)
	p._dato("Temporadas  (× 120)", "%d  →  %s" % [int(p_local["temporadas"]), p._miles(int(p_local["temporadas"]) * 120)], Principal.COL_TEXTO, p._lista_desafios)
	p._lista_desafios.add_child(HSeparator.new())

	var tt := p._texto(11, Principal.COL_SUAVE)
	tt.text = Idiomas.t("LOS OCHO DESAFÍOS")
	p._lista_desafios.add_child(tt)
	var tabla: Variant = DesafiosDificultad.todos()
	if not (tabla is Array):
		return
	for fila: Array in (tabla as Array):
		var clave := String(fila[0])
		var activo := p.mundo.desafios.has(clave)
		var fila_ui := HBoxContainer.new()
		fila_ui.add_theme_constant_override("separation", 8)
		p._lista_desafios.add_child(fila_ui)
		var nom := p._texto(12, Principal.COL_VERDE if activo else Principal.COL_SUAVE)
		nom.text = "%s %s%s" % [String(fila[2]), String(fila[1]), Idiomas.t("   ✓ activo") if activo else ""]
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila_ui.add_child(nom)
		var x := p._texto(12, Principal.COL_ORO if activo else Principal.COL_SUAVE)
		x.text = "×%.2f" % float(fila[4])
		fila_ui.add_child(x)
		var desc := p._texto(11, Principal.COL_SUAVE)
		desc.text = String(fila[3])
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_desafios.add_child(desc)
	if not p.mundo.fin_partida.is_empty():
		p._lista_desafios.add_child(HSeparator.new())
		var fin := p._texto(12, Principal.COL_ROJO)
		fin.text = Idiomas.t("💀 Partida marcada como terminada: cayó la primera derrota con el desafío del invicto activo (semana %d de %d). Puedes seguir jugando, pero el desafío está perdido.") % [
			int(p.mundo.fin_partida.get("semana", 0)), int(p.mundo.fin_partida.get("anio", 0))]
		fin.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_desafios.add_child(fin)

## `vFichaClub()`: el plantel de un club cualquiera, con lo que se sabe de él.
## Las medias de los ajenos pasan por el mismo filtro de ojeo que el resto del
## juego -si no lo has visto jugar, no sabes exactamente cuánto vale-.
## `vRivalidades()`: el mapa de a quién le tienes ganas y por qué. No hay un
## contador nuevo detrás: la rivalidad se DEDUCE del cara a cara que `Logros` ya
## lleva partido a partido, más los clásicos de origen. Un contador aparte sería
## otra cosa que mantener al día y que puede desincronizarse.
func _pintar_rivalidades() -> void:
	if p.mundo.logros == null:
		return
	var lista := p.mundo.logros.rivalidades()
	if lista.is_empty():
		return
	p._lista_clubes.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("🔥 MAPA DE RIVALIDADES")
	p._lista_clubes.add_child(t)
	var ex := p._texto(10, Principal.COL_SUAVE)
	ex.text = Idiomas.t("La rivalidad no se declara: se construye. Sube con cada cruce y, sobre todo, con cada derrota.")
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_clubes.add_child(ex)
	for i in mini(8, lista.size()):
		var f: Dictionary = lista[i]
		var c: Club = f["club"]
		var v := int(f["valor"])
		var h: Dictionary = f["h2h"]
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_clubes.add_child(fila)
		fila.add_child(p._escudo(c, 22))
		var nom := p._texto(12, Principal.COL_TEXTO)
		nom.text = "%s  ·  %s" % [c.nombre, String(f["nivel"])]
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nom.clip_text = true
		fila.add_child(nom)
		## El cara a cara en crudo, que es lo que justifica el número: quien mira
		## esto quiere saber si le gana o le pierde, no solo cuánto le odia.
		var hh := p._texto(11, Principal.COL_SUAVE)
		hh.text = "%d PJ  ·  %d-%d-%d  ·  %d:%d" % [
			int(h["pj"]), int(h["pg"]), int(h["pe"]), int(h["pp"]), int(h["gf"]), int(h["gc"])]
		hh.custom_minimum_size = Vector2(150, 0)
		fila.add_child(hh)
		var val := p._texto(13, Principal.COL_ROJO if v >= 60 else Principal.COL_ORO)
		val.text = str(v)
		val.custom_minimum_size = Vector2(30, 0)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		fila.add_child(val)

## "Es el Superclásico" / "Es el Clásico Universitario" / "Es un clásico tuyo".
func _frase_clasico(a: Club, b: Club) -> String:
	var n := HistoriaClub.nombre_clasico(a.nombre, b.nombre)
	if n == "":
		return "Es un clásico tuyo"
	return "Es " + n if n.begins_with("el ") else "Es el " + n

## C4: la historia del club (generada en la base ficticia, real con el pack).
func _historia_de(club: Club) -> Dictionary:
	var del_pais: Array = []
	for o: Club in p.mundo.clubes.values():
		if o.pais == club.pais:
			del_pais.append(o)
	return HistoriaClub.de(club, del_pais)

func _pintar_ficha_club(club: Club) -> void:
	var t := p._texto(13, Principal.COL_ORO)
	t.text = Idiomas.t("%s  ·  reputación %d  ·  aforo %s") % [club.nombre, club.rep, p._miles(club.estadio_aforo)]
	p._lista_clubes.add_child(t)
	## M-292 (2-11): seguir al club: su resultado de cada semana llega a la bandeja.
	if p.mundo.ojeadores != null and club != p.mundo.mi_club():
		var bs := p._boton(Idiomas.t("👁️ Dejar de seguir al club") if p.mundo.ojeadores.sigue_club(club) else Idiomas.t("👁️ Seguir al club"), func() -> void:
			p.mundo.ojeadores.alternar_club(club)
			_pintar_ficha_club_refresco(), p._lista_clubes)
		bs.tooltip_text = Idiomas.t("Cada semana, su resultado te llega al correo.")
	var hi_c := _historia_de(club)
	for linea: String in ["📜 " + HistoriaClub.resumen(hi_c), HistoriaClub.texto_historia(hi_c), HistoriaClub.texto_clasicos(hi_c), HistoriaClub.texto_palmares(hi_c)]:
		if linea.strip_edges() == "":
			continue
		var hist := p._texto(11, Principal.COL_TEXTO)
		hist.text = linea
		hist.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_clubes.add_child(hist)
	var sub := p._texto(11, Principal.COL_SUAVE)
	sub.text = Idiomas.t("%d jugadores  ·  media %.1f  ·  masa salarial %s/sem") % [
		club.plantilla.size(), club.media(), p._dinero(club.masa_salarial())]
	p._lista_clubes.add_child(sub)
	## LO QUE FALTABA DE `vFichaClub()`: la media del MEJOR ONCE, la forma, quién
	## lo entrena y si es clásico tuyo. Mirar la ficha de un rival es prepararse
	## un partido, y la media de la plantilla entera engaña —incluye a los nueve
	## suplentes que no van a jugar—.
	var once := club.once()
	var media_once := 0.0
	for j2 in once:
		media_once += float(j2.ovr)
	if not once.is_empty():
		media_once /= float(once.size())
	p._dato("Media del mejor once", "%.1f" % media_once, Principal.COL_TEXTO, p._lista_clubes)
	ComparaClubes.pintar(p._lista_clubes, p.mundo.mi_club(), club, Principal.COL_SUAVE, Principal.COL_TEXTO, Principal.COL_VERDE, Principal.COL_ROJO)   ## M-294
	if p.mundo.roles != null and club == p.mundo.mi_club() and not p.mundo.roles.dt_empleado.is_empty():
		p._dato("Entrenador", p.mundo.roles.dt_nombre(), Principal.COL_TEXTO, p._lista_clubes)
	## El aviso de clásico: cambia cómo se juega ese partido -aforo, ánimo,
	## presión- y por eso tiene que verse aquí y no solo el día del choque.
	if club != p.mundo.mi_club() and p.mundo.es_clasico(p.mundo.mi_club(), club):
		var cl := p._texto(12, Principal.COL_ORO)
		cl.text = Idiomas.t("⚔️  %s: estadio lleno, prensa encima y el doble de presión.") % _frase_clasico(p.mundo.mi_club(), club)
		cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_clubes.add_child(cl)
	var g := GridContainer.new()
	CebraRejilla.poner(g)
	g.columns = 7
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 10)
	p._lista_clubes.add_child(g)
	## Los AÑOS DE CONTRATO son la columna que convierte una plantilla ajena en
	## una lista de la compra: al que le queda uno se le puede precontratar.
	for enc in ["NOMBRE", "POS", "EDAD", "MED", "GOLES", "VALOR", "CONTR."]:
		p._celda(g, enc, Principal.COL_SUAVE, enc in ["EDAD", "MED", "GOLES", "VALOR", "CONTR."], 11)
	var orden := club.plantilla.duplicate()
	orden.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	for j: Jugador in orden:
		var med := str(j.ovr) if club == p.mundo.mi_club() else (
			p.mundo.ojeadores.ovr_texto(j) if p.mundo.ojeadores != null else str(j.ovr))
		p._fila_jugador(g, j,
			[j.nombre, j.pos_e, str(j.edad), med, str(j.goles), p._dinero(j.valor),
				"%d año%s" % [j.anios_contrato, "" if j.anios_contrato == 1 else "s"]],
			[Principal.COL_TEXTO, Principal.COL_SUAVE, Principal.COL_SUAVE, Principal.COL_TEXTO,
				Principal.COL_VERDE if j.goles > 0 else Principal.COL_SUAVE, Principal.COL_SUAVE,
				Principal.COL_ORO if j.anios_contrato <= 1 else Principal.COL_SUAVE])
	p._lista_clubes.add_child(HSeparator.new())

## `vGoleadores()`: la tabla de artilleros del país elegido. Se arma recorriendo
## las plantillas, que es donde viven los goles: no hace falta un registro
## aparte que mantener al día.
func _pintar_goleadores(pais: String) -> void:
	var todos: Array[Jugador] = []
	for l in p.mundo.ligas:
		if l.pais != pais:
			continue
		for club: Club in l.clubes:
			for j: Jugador in club.plantilla:
				if j.goles > 0:
					todos.append(j)
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("GOLEADORES  ·  %s") % pais
	p._lista_clubes.add_child(t)
	if todos.is_empty():
		var nada := p._texto(12, Principal.COL_SUAVE)
		nada.text = Idiomas.t("Todavía no hay goles en esta liga.")
		p._lista_clubes.add_child(nada)
		return
	todos.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.goles > b.goles)
	var g := GridContainer.new()
	CebraRejilla.poner(g)
	g.columns = 5
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 10)
	p._lista_clubes.add_child(g)
	for enc in ["#", "", "JUGADOR", "CLUB", "GOLES"]:
		p._celda(g, enc, Principal.COL_SUAVE, enc == "GOLES", 11)
	for i in mini(15, todos.size()):
		var j: Jugador = todos[i]
		var suyo: Club = p.mundo.clubes.get(j.club_id)
		p._celda(g, str(i + 1), Principal.COL_SUAVE, false, 11)
		g.add_child(p._retrato(j, Principal.RETRATO_FILA))
		var b := Button.new()
		b.text = j.nombre
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 12)
		b.pressed.connect(func() -> void: p._ver_ficha(j))
		g.add_child(b)
		p._celda(g, suyo.nombre if suyo else "—", Principal.COL_SUAVE, false, 11)
		p._celda(g, str(j.goles), Principal.COL_VERDE, true, 12)

## M-300: «↶ Deshacer» el último cambio de la pizarra (dibujo, perillas, interruptores u once). Apagado si no hay nada.
func _boton_deshacer(c: Club) -> void:
	var n := DeshacerTactica.pasos(c)
	var b := p._boton(Idiomas.t("↶ Deshacer") + ("  (%d)" % n if n > 0 else ""), func() -> void:
		if DeshacerTactica.deshacer(c):
			p._refrescar(), p._lista_tactica)
	b.disabled = n == 0
	b.tooltip_text = Idiomas.t("Vuelve atrás el último cambio de la táctica o del once (hasta 20).")

func _pintar_ficha_club_refresco() -> void:
	p._vistas._pintar_clubes()
