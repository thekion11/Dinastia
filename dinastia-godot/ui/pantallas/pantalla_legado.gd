class_name PantallaLegado
extends RefCounted
## INICIO, CARRERA Y LEGADO: la portada, el legado, el rival DT, las filiales, la sucesión, el árbol de habilidades, el fin de carrera y los récords.
##
## Sale de `ui/principal.gd` (mapa de metas 15: el archivo pasaba de
## 15.000 líneas). `p` es la pantalla principal: sus ayudantes (`p._texto`,
## `p._boton`...), el mundo (`p.mundo`) y el repintado (`p._refrescar()`).

var p: Principal

func _init(principal: Principal) -> void:
	p = principal

func _pintar_inicio(c: Club) -> void:
	p._limpiar(p._lista_inicio)
	var liga := p._liga_de(c)
	## EL TABLERO (25-9-2026): próximo partido con los dos escudos, anillos de
	## valoración, la cara de la estrella y la racha. Ver `TableroInicio`.
	TableroInicio.pintar(p._lista_inicio, c, p.mundo, liga, p._ir_a_pestana, p._ver_ficha)
	p._lista_inicio.add_child(HSeparator.new())
	p._ui_cantera._pintar_informe()
	p._lista_inicio.add_child(HSeparator.new())

	## LOS ACCESOS RÁPIDOS. Se marcan en Ajustes y salen aquí, que es donde se
	## usan: entras al club y saltas a lo tuyo sin recorrer seis grupos.
	if not p._favoritos.is_empty():
		var tfav := p._texto(11, Principal.COL_SUAVE)
		tfav.text = "⭐ ACCESOS RÁPIDOS"
		p._lista_inicio.add_child(tfav)
		var rej := HBoxContainer.new()
		rej.add_theme_constant_override("separation", 4)
		p._lista_inicio.add_child(rej)
		for tab: String in p._favoritos:
			var b := Button.new()
			b.text = tab
			b.add_theme_font_size_override("font_size", 11)
			b.clip_text = true
			b.custom_minimum_size = Vector2(70, 0)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.pressed.connect(func() -> void: p._ir_a_pestana(tab))
			rej.add_child(b)
		p._lista_inicio.add_child(HSeparator.new())

	## ÚLTIMOS RESULTADOS. Sale de `Liga.historial`, que se guarda desde la misma
	## tanda que la pantalla de competición: antes el resultado viajaba en una
	## señal y se perdía.
	var tr := p._texto(11, Principal.COL_SUAVE)
	tr.text = "ÚLTIMOS RESULTADOS"
	p._lista_inicio.add_child(tr)
	var puestos := 0
	for i in range(liga.historial.size() - 1, -1, -1):
		if puestos >= 5:
			break
		for r: Dictionary in liga.historial[i]:
			if r["local"] != c and r["visita"] != c:
				continue
			var gl := int(r["gl"])
			var gv := int(r["gv"])
			var mios := gl if r["local"] == c else gv
			var suyos := gv if r["local"] == c else gl
			var col := Principal.COL_VERDE if mios > suyos else (Principal.COL_ROJO if mios < suyos else Principal.COL_SUAVE)
			p._dato("J%d  %s %d-%d %s" % [i + 1, (r["local"] as Club).nombre, gl, gv, (r["visita"] as Club).nombre],
				"✔" if mios > suyos else ("✕" if mios < suyos else "="), col, p._lista_inicio)
			puestos += 1
	if puestos == 0:
		var vac := p._texto(12, Principal.COL_SUAVE)
		vac.text = "Aún sin partidos jugados."
		p._lista_inicio.add_child(vac)
	p._lista_inicio.add_child(HSeparator.new())

	## CORREO RECIENTE: los tres últimos de la bandeja, con el punto de "sin
	## leer". Es el gancho para que el correo no se quede sin abrir nunca.
	var tc := p._texto(11, Principal.COL_SUAVE)
	tc.text = "CORREO RECIENTE"
	p._lista_inicio.add_child(tc)
	if p._bandeja.is_empty():
		var vac2 := p._texto(12, Principal.COL_SUAVE)
		vac2.text = "Sin novedades."
		p._lista_inicio.add_child(vac2)
	else:
		for i in mini(3, p._bandeja.size()):
			var m: Dictionary = p._bandeja[i]
			var b := Button.new()
			b.text = ("●  " if not bool(m.get("leida", false)) else "     ") + String(m.get("titulo", ""))
			b.flat = true
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.clip_text = true
			b.custom_minimum_size = Vector2(120, 0)
			b.add_theme_font_size_override("font_size", 12)
			b.add_theme_color_override("font_color", p._color_de_paleta(Principal.COL_TEXTO if not bool(m.get("leida", false)) else Principal.COL_SUAVE))
			b.pressed.connect(func() -> void: p._ir_a_pestana("Correo"))
			p._lista_inicio.add_child(b)

## La frase de "qué toca esta semana". Sale del mismo sitio que decide qué se
## juega al pulsar «Dirigir el partido», para que las dos no puedan discrepar.
func _texto_proximo_compromiso(c: Club) -> String:
	if not p.mundo.partido_de_copa().is_empty() and p.mundo.copa != null:
		return "%s · %s" % [p.mundo.copa.nombre, p.mundo.copa.nombre_de_ronda()]
	var liga := p._liga_de(c)
	var par := liga.emparejamiento_de(c)
	if par.is_empty():
		return "Semana sin partido: entrenamiento doble."
	var rival: Club = par[0] if par[0] != c else par[1]
	var de_local: bool = par[0] == c
	return "vs %s  ·  %s  ·  jornada %d de %s" % [
		rival.nombre, "Local" if de_local else "Visita",
		liga.jornada_actual + 1, liga.nombre]

func _pintar_legado() -> void:
	p._limpiar(p._lista_legado)
	var r := p.mundo.roles
	if r == null:
		return
	var p_local: Dictionary = p.mundo.puntaje_carrera()

	## C4: LA HISTORIA DEL CLUB, antes que la tuya.
	var hi := p._ui_plantel._historia_de(p.mundo.mi_club())
	var th := p._texto(11, Principal.COL_SUAVE)
	th.text = "HISTORIA DEL CLUB"
	p._lista_legado.add_child(th)
	for linea: String in [HistoriaClub.resumen(hi), HistoriaClub.texto_historia(hi), HistoriaClub.texto_clasicos(hi), String(hi["epoca"])]:
		if linea.strip_edges() == "":
			continue
		var lh := p._texto(12, Principal.COL_TEXTO)
		lh.text = linea
		lh.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_legado.add_child(lh)
	p._lista_legado.add_child(HSeparator.new())

	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "TU LEGADO"
	p._lista_legado.add_child(t)
	var g := GridContainer.new()
	g.columns = 4
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 14)
	p._lista_legado.add_child(g)
	for par in [["Temporadas", str(p.mundo.anio - 2026 + 1)], ["Títulos", str(r.trofeos.size())],
			["Prestigio", str(r.prestigio)], ["Puntaje", p._miles(int(p_local["total"]))]]:
		var col := VBoxContainer.new()
		g.add_child(col)
		var et := p._texto(10, Principal.COL_SUAVE)
		et.text = String(par[0])
		col.add_child(et)
		var va := p._texto(16, Principal.COL_ORO)
		va.text = String(par[1])
		col.add_child(va)
	## El multiplicador solo se enseña si es distinto de 1: si no, es una línea
	## que dice "×1.0" y no significa nada.
	if absf(float(p_local["multiplicador"]) - 1.0) > 0.001:
		p._dato("Multiplicador de desafíos", "×%.2f sobre %s de base" % [float(p_local["multiplicador"]), p._miles(int(p_local["base"]))],
			Principal.COL_VERDE, p._lista_legado)
	if not r.filosofia.is_empty():
		var fi := p._texto(12, p.COL_ACENTO)
		fi.text = "📚 Tu escuela táctica: %s  (%s)" % [String(r.filosofia["nombre"]), String(r.filosofia.get("formacion", ""))]
		fi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_legado.add_child(fi)
	p._lista_legado.add_child(HSeparator.new())

	var tp := p._texto(11, Principal.COL_SUAVE)
	tp.text = "PALMARÉS POR COMPETICIÓN"
	p._lista_legado.add_child(tp)
	var palmares := r.palmares_por_tipo()
	if palmares.is_empty():
		var vac := p._texto(12, Principal.COL_SUAVE)
		vac.text = "Sin títulos todavía."
		p._lista_legado.add_child(vac)
	else:
		for f: Dictionary in palmares:
			p._dato("🏆 %s" % String(f["titulo"]), "×%d" % int(f["veces"]), Principal.COL_ORO, p._lista_legado)
	p._lista_legado.add_child(HSeparator.new())

	var tc := p._texto(11, Principal.COL_SUAVE)
	tc.text = "📈 CARRERA PROFESIONAL"
	p._lista_legado.add_child(tc)
	p._dato("Rol actual", r.nombre_del_cargo().capitalize(), Principal.COL_TEXTO, p._lista_legado)
	## LA LICENCIA Y EL MINIJUEGO (C7).
	if p.mundo.licencia != null:
		var lic := p._texto(12, Principal.COL_TEXTO)
		lic.text = "🎓 %s" % p.mundo.licencia.nombre()
		p._lista_club.add_child(lic)
		var motivo := p.mundo.licencia.puede_presentarse(p.mundo.anio, p.mundo.semana)
		if motivo == "":
			p._boton("Presentarse al examen de %s" % Licencia.NIVELES[p.mundo.licencia.nivel + 1], p._ui_finanzas._abrir_examen, p._lista_club)
		else:
			var m2 := p._texto(11, Principal.COL_SUAVE)
			m2.text = motivo
			p._lista_club.add_child(m2)
		p._boton("🎮 Minijuegos: penales, tiros libres y trivia", func() -> void: SalaMinijuegos.abrir(p, p.mundo), p._lista_club)

	var escalon := r.siguiente_escalon()
	if escalon != "":
		var e := p._texto(11, Principal.COL_SUAVE)
		e.text = escalon
		e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_legado.add_child(e)
	if r.puede_ascender() != "":
		p._boton("📈 Ascender a %s" % Roles.PERMISOS[r.puede_ascender()]["cargo"], p._ui_finanzas._ascender_rol, p._lista_legado)
	p._lista_legado.add_child(HSeparator.new())

	## LA OFERTA DE OTRO CLUB. Va arriba del legado porque es lo unico de esta
	## pantalla que caduca: si no contestas, sigue ahi, pero es la decision mas
	## grande que se toma en todo el juego.
	if not r.oferta_de_club.is_empty():
		p._lista_legado.add_child(HSeparator.new())
		var to := p._texto(11, Principal.COL_ORO)
		to.text = "☎️ TE QUIEREN EN OTRO CLUB"
		p._lista_legado.add_child(to)
		var no := p._texto(13, Principal.COL_ORO)
		no.text = String(r.oferta_de_club["nombre"])
		p._lista_legado.add_child(no)
		p._dato("Salto de categoría", "+%d de reputación" % int(r.oferta_de_club["mejora"]),
			Principal.COL_VERDE, p._lista_legado)
		p._dato("Tu sueldo allí", "%s / semana" % p._dinero(int(r.oferta_de_club["sueldo"])),
			Principal.COL_ORO, p._lista_legado)
		var eo := p._texto(10, Principal.COL_SUAVE)
		eo.text = "Aceptar cierra tu capítulo aquí y abre otro: el currículum se lo lleva todo. Rechazar sube la confianza de esta directiva, que se entera igual."
		eo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_legado.add_child(eo)
		var fila_o := HBoxContainer.new()
		fila_o.add_theme_constant_override("separation", 6)
		p._lista_legado.add_child(fila_o)
		for par_o: Array in [[true, "Aceptar y marcharme"], [false, "Quedarme aquí"]]:
			var si_o: bool = par_o[0]
			var bo := Button.new()
			bo.text = String(par_o[1])
			bo.add_theme_font_size_override("font_size", 11)
			bo.clip_text = true
			bo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bo.pressed.connect(func() -> void:
				var msg := r.responder_oferta_de_club(si_o)
				p._escribir("[color=#c9a227]%s[/color]" % msg)
				if si_o:
					p._conectar_noticias()
					p._seleccionado = null
					p._llenar_selector()
				p._refrescar())
			fila_o.add_child(bo)

	_pintar_desgaste(r)
	_pintar_rival_dt(r)
	_pintar_leyenda_viva(r)
	_pintar_patrimonio_dt(r)
	_pintar_filiales(r)
	_pintar_acceso_arbol()
	_pintar_homenajes(r)
	_pintar_sucesion(r)
	_pintar_fin_de_carrera(r)
	_pintar_epilogo(r)

## EL DESGASTE Y EL CURRÍCULUM. Las dos cosas que hacen que esto sea una carrera
## y no una partida: lo que te cuesta el cargo, y por dónde has pasado.
func _pintar_desgaste(r: Roles) -> void:
	p._lista_legado.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "🔥 DESGASTE EN EL CARGO"
	p._lista_legado.add_child(t)
	p._dato("Nivel", "%d de 100" % r.desgaste,
		Principal.COL_ROJO if r.quemado() else (Principal.COL_ORO if r.desgaste >= 55 else Principal.COL_VERDE), p._lista_legado)
	var d := p._texto(10, Principal.COL_ROJO if r.quemado() else Principal.COL_SUAVE)
	if r.quemado():
		d.text = "Estás quemado. Duermes mal y se te nota: lo que dices en rueda de prensa vale la mitad. Cambiar de aire lo arregla; seguir aquí, no."
	elif r.desgaste >= 55:
		d.text = "Se te empieza a notar el ciclo. Ganar descansa; la funa quema el doble."
	else:
		d.text = "Entero. Cada semana en el cargo cansa un poco; ganar lo compensa."
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_legado.add_child(d)

	if r.curriculum.is_empty():
		return
	p._lista_legado.add_child(HSeparator.new())
	var tc := p._texto(11, Principal.COL_SUAVE)
	tc.text = "📄 CURRÍCULUM"
	p._lista_legado.add_child(tc)
	for i in range(r.curriculum.size() - 1, -1, -1):
		var c: Dictionary = r.curriculum[i]
		var hasta := int(c.get("hasta", 0))
		var l := p._texto(12, Principal.COL_ORO if hasta == 0 else Principal.COL_TEXTO)
		l.text = "%s  ·  %d–%s" % [String(c.get("nombre", "")), int(c.get("desde", 0)),
			"hoy" if hasta == 0 else str(hasta)]
		p._lista_legado.add_child(l)
		if hasta != 0:
			var m := p._texto(10, Principal.COL_SUAVE)
			m.text = "     %d título(s) al irte  ·  %s" % [int(c.get("trofeos", 0)), String(c.get("motivo", ""))]
			p._lista_legado.add_child(m)

## `vCarrera()`: EL RIVAL PERSONAL. No se elige y no se puede quitar: nace del
## club con el que más te has picado, y a partir de ahí cada cruce se cuenta
## aparte. Es la única estadística del juego que no es del club, es tuya.
func _pintar_rival_dt(r: Roles) -> void:
	if r.rival_dt.is_empty():
		return
	p._lista_legado.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "👔 TU RIVAL"
	p._lista_legado.add_child(t)
	var c: Club = p.mundo.clubes.get(String(r.rival_dt.get("club_id", "")))
	var n := p._texto(13, Principal.COL_ROJO)
	n.text = "%s  ·  %s" % [String(r.rival_dt.get("nombre", "")), c.nombre if c else "?"]
	p._lista_legado.add_child(n)
	var e := p._texto(10, Principal.COL_SUAVE)
	e.text = String(r.rival_dt.get("estilo", ""))
	e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_legado.add_child(e)
	var pj := int(r.rival_dt.get("pj", 0))
	p._dato("Cara a cara desde %d" % int(r.rival_dt.get("desde", 0)),
		"%d–%d–%d en %d duelo%s" % [int(r.rival_dt.get("g", 0)), int(r.rival_dt.get("e", 0)),
			int(r.rival_dt.get("p", 0)), pj, "" if pj == 1 else "s"],
		Principal.COL_TEXTO, p._lista_legado)
	var tension := int(r.rival_dt.get("tension", 0))
	p._dato("Tensión", "%d de 100" % tension,
		Principal.COL_ROJO if tension >= 80 else (Principal.COL_ORO if tension >= 60 else Principal.COL_SUAVE), p._lista_legado)
	if tension >= 80 and not p._modo_experto:
		var av := p._texto(10, Principal.COL_ROJO)
		av.text = "Está a punto de salirse de la cancha. El próximo cruce puede acabar en el túnel y con los micrófonos abiertos."
		av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_legado.add_child(av)

## LA LEYENDA VIVA. Un ex jugador ligado al club de por vida. No entrena, no
## fila y no sale en ninguna estadística: viene, habla con los chicos y está.
func _pintar_leyenda_viva(r: Roles) -> void:
	p._lista_legado.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "🕰️ LEYENDA VIVA DEL CLUB"
	p._lista_legado.add_child(t)
	if not r.leyenda_viva.is_empty():
		var n := p._texto(13, Principal.COL_ORO)
		n.text = "%s  ·  %s" % [String(r.leyenda_viva.get("nombre", "")), String(r.leyenda_viva.get("pos", ""))]
		p._lista_legado.add_child(n)
		p._dato("Ligado al club desde", str(int(r.leyenda_viva.get("desde", 0))), Principal.COL_SUAVE, p._lista_legado)
		var d := p._texto(10, Principal.COL_SUAVE)
		d.text = "Cada seis semanas se sienta con un juvenil del plantel. Le sube la moral y a veces algo más."
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_legado.add_child(d)
		return
	## Solo veteranos de la casa: nombrar leyenda a un fichaje de enero sería
	## un chiste, y el juego se lo tomaría en serio.
	var mio := p.mundo.mi_club()
	var candidatos: Array[Jugador] = []
	if mio != null:
		for j: Jugador in mio.plantilla:
			if j.edad >= 32 and j.club_formacion == mio.id:
				candidatos.append(j)
	if candidatos.is_empty():
		var vac := p._texto(10, Principal.COL_SUAVE)
		vac.text = "Todavía no hay a quién nombrar. Hace falta un veterano de 32 años o más formado en la casa."
		vac.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_legado.add_child(vac)
		return
	var ex := p._texto(10, Principal.COL_SUAVE)
	ex.text = "Nombrar a alguien lo liga al club de por vida. La hinchada lo agradece de inmediato."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_legado.add_child(ex)
	for j: Jugador in candidatos:
		var quien := j
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_legado.add_child(fila)
		var l := p._texto(12, Principal.COL_TEXTO)
		l.text = "%s  ·  %s, %d años" % [j.nombre, j.pos_e, j.edad]
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.clip_text = true
		fila.add_child(l)
		var b := Button.new()
		b.text = "Nombrar"
		b.add_theme_font_size_override("font_size", 11)
		b.custom_minimum_size = Vector2(90, 0)
		b.pressed.connect(func() -> void:
			var msg := r.nombrar_leyenda_viva(quien)
			if msg != "":
				p._escribir("[color=#e05555]No se pudo: %s.[/color]" % msg)
			p._refrescar())
		fila.add_child(b)

## LOS CLUBES FILIALES. `Entrenamiento.puede_comprar_filiales()` estaba escrita
## desde el porte y no la llamaba nadie: la habilidad «Magnate» del árbol se
## podía comprar con un punto y no servía absolutamente para nada.
func _pintar_filiales(r: Roles) -> void:
	if p.mundo.entrenamiento == null:
		return
	var puede := p.mundo.entrenamiento.puede_comprar_filiales()
	if not puede and r.filiales.is_empty():
		return
	p._lista_legado.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "🏦 TUS CLUBES"
	p._lista_legado.add_child(t)
	if not r.filiales.is_empty():
		for cid: String in r.filiales:
			var c: Club = p.mundo.clubes.get(cid)
			if c == null:
				continue
			p._dato(c.nombre, "rep %d  ·  dividendo %s cada %d semanas" % [
				c.rep, p._dinero(c.rep * c.rep * 40), Roles.SEMANAS_DIVIDENDO],
				Principal.COL_ORO, p._lista_legado)
	if not puede:
		var av := p._texto(10, Principal.COL_SUAVE)
		av.text = "Para comprar un club hace falta la habilidad «Magnate» del árbol de entrenador."
		av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_legado.add_child(av)
		return
	if not p._modo_experto:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = "Se compran con TU dinero, no con el del club. Cuesta tres veces la caja de referencia del club y devuelve dividendos cada tres meses."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_legado.add_child(ex)
	## Los cinco más baratos que todavía no son tuyos: la lista entera serían
	## trescientos ochenta y tres botones.
	var comprables: Array[Club] = []
	for c2: Club in p.mundo.clubes.values():
		if c2.id == p.mundo.mi_club_id or r.filiales.has(c2.id):
			continue
		comprables.append(c2)
	comprables.sort_custom(func(a: Club, b: Club) -> bool: return a.rep < b.rep)
	for i in mini(5, comprables.size()):
		var c3: Club = comprables[i]
		var precio := r.precio_filial(c3)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_legado.add_child(fila)
		var l2 := p._texto(12, Principal.COL_TEXTO)
		l2.text = "%s  ·  rep %d" % [c3.nombre, c3.rep]
		l2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l2.clip_text = true
		fila.add_child(l2)
		var b2 := Button.new()
		b2.text = p._dinero(precio)
		b2.add_theme_font_size_override("font_size", 11)
		b2.disabled = r.patrimonio < precio
		b2.custom_minimum_size = Vector2(110, 0)
		b2.pressed.connect(func() -> void:
			var msg := r.comprar_filial(c3)
			if msg != "":
				p._escribir("[color=#e05555]No se pudo comprar: %s.[/color]" % msg)
			p._refrescar())
		fila.add_child(b2)

## LA SUCESIÓN. A quién le dejas el club. No cambia tu partida —ya se acabó— y
## por eso importa: es lo único que solo sirve para decidir cómo quieres que se
## recuerde lo que hiciste.
func _pintar_sucesion(r: Roles) -> void:
	if r.retirado.is_empty():
		return
	p._lista_legado.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "🪑 LA SUCESIÓN"
	p._lista_legado.add_child(t)
	if not r.sucesor.is_empty():
		var n := p._texto(13, Principal.COL_ORO)
		n.text = String(r.sucesor.get("nombre", ""))
		p._lista_legado.add_child(n)
		var d := p._texto(11, Principal.COL_SUAVE)
		d.text = "%s El directorio le da un margen de %d partidos." % [
			String(r.sucesor.get("desc", "")), int(r.sucesor.get("margen", 0))]
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_legado.add_child(d)
		return
	var ex := p._texto(10, Principal.COL_SUAVE)
	ex.text = "Te retiraste. Lo último que decides es a quién le dejas el banquillo."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_legado.add_child(ex)
	var lista := r.candidatos_sucesion()
	for i in lista.size():
		var idx := i
		var cand: Dictionary = lista[i]
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_legado.add_child(fila)
		var l := p._texto(12, Principal.COL_TEXTO)
		l.text = "%s  ·  margen %d partidos" % [String(cand["nombre"]), int(cand["margen"])]
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.clip_text = true
		l.tooltip_text = String(cand["desc"])
		fila.add_child(l)
		var b := Button.new()
		b.text = "Elegir"
		b.add_theme_font_size_override("font_size", 11)
		b.custom_minimum_size = Vector2(80, 0)
		b.pressed.connect(func() -> void:
			r.elegir_sucesor(idx)
			p._refrescar())
		fila.add_child(b)
		var d2 := p._texto(10, Principal.COL_SUAVE)
		d2.text = String(cand["desc"])
		d2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_legado.add_child(d2)

## `vCarrera()`: tu patrimonio personal y en qué lo inviertes.
##
## Hasta ahora el entrenador no cobraba: el club pagaba sueldos y él no tenía
## bolsillo. Y sin bolsillo no hay carrera personal, solo gestión de un club.
##
## Lo que se compra aquí NO mejora al equipo: mejora al ENTRENADOR, y te sigue
## cuando cambias de banquillo. Es dinero tuyo, no del club, y esa separación es
## todo el sentido de la pantalla.
func _pintar_patrimonio_dt(r: Roles) -> void:
	p._lista_legado.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "💼 TU PATRIMONIO"
	p._lista_legado.add_child(t)
	p._dato("Ahorros", p._dinero(r.patrimonio), Principal.COL_ORO, p._lista_legado)
	p._dato("Tu sueldo", "%s / semana" % p._dinero(r.sueldo_semanal()), Principal.COL_TEXTO, p._lista_legado)
	p._dato("Semanas dirigiendo", str(r.semanas_trabajadas), Principal.COL_SUAVE, p._lista_legado)
	var lic := ["ninguna", "Licencia B", "Licencia A", "Licencia PRO"]
	p._dato("Titulación", String(lic[clampi(r.licencia, 0, 3)]),
		Principal.COL_VERDE if r.licencia > 0 else Principal.COL_SUAVE, p._lista_legado)
	if not p._modo_experto:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = "Es dinero TUYO, no del club. Lo que compres aquí te sigue cuando cambies de banquillo."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_legado.add_child(ex)
	for f: Array in Roles.COMPRAS_DT:
		var clave := String(f[0])
		var tengo := r.tiene(clave)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_legado.add_child(fila)
		var n := p._texto(12, Principal.COL_VERDE if tengo else Principal.COL_TEXTO)
		n.text = "%s%s" % ["✔  " if tengo else "     ", String(f[1])]
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		n.tooltip_text = String(f[3])
		fila.add_child(n)
		var b := Button.new()
		b.text = "Puesto" if tengo else p._dinero(int(f[2]))
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = tengo or r.patrimonio < int(f[2])
		b.custom_minimum_size = Vector2(96, 0)
		b.pressed.connect(func() -> void: _comprar_dt(clave))
		fila.add_child(b)
		if not tengo and not p._modo_experto:
			var d := p._texto(10, Principal.COL_SUAVE)
			d.text = "     %s" % String(f[3])
			d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_legado.add_child(d)

func _comprar_dt(clave: String) -> void:
	var problema := p.mundo.roles.comprar_dt(clave)
	if problema != "":
		p._escribir("[color=#e05555]No se pudo: %s.[/color]" % problema)
	p._refrescar()

## El ÁRBOL DE CARRERA DEL ENTRENADOR de `vCarrera()`: cinco ramas, un punto
## cada diez semanas, y nodos encadenados por requisito. Otro sistema entero
## escrito, probado y sin una sola llamada desde la interfaz —los puntos se
## acumulaban solos temporada tras temporada sin que hubiera dónde gastarlos.
##
## Va en Legado y no en el Club porque es de la CARRERA: como el prestigio y la
## vitrina, te sigue cuando cambias de banquillo.
## MI VIDA (26-9-2026).
func _pintar_vida() -> void:
	if p._lista_vida == null or not p._lista_vida.is_visible_in_tree():
		return
	PanelVida.pintar(p._lista_vida, p, p.mundo, p._secc_vida)

## EL ÁRBOL DE HABILIDADES, COMO ESQUEMA (26-9-2026): columnas por rama, nodos
## y líneas de requisito, y la ficha de la elegida debajo.
func _pintar_habilidades() -> void:
	if p._lista_habilidades == null or not p._lista_habilidades.is_visible_in_tree():
		return
	p._limpiar(p._lista_habilidades)
	var e := p.mundo.entrenamiento
	if e == null:
		return
	var cab := HBoxContainer.new()
	p._lista_habilidades.add_child(cab)
	## El título se recorta en vez de ensanchar el panel (recorrido D4): con
	## las columnas laterales abiertas empujaba la ficha fuera de pantalla.
	var tit := Tema.etiqueta(Tema.TAM_DESTACADO + 2, Tema.ORO, "🎓 HABILIDADES")
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tit.clip_text = true
	tit.custom_minimum_size.x = 60
	cab.add_child(tit)
	var pts := Tema.etiqueta(Tema.TAM_CUERPO, Tema.ORO if e.dt_puntos > 0 else Tema.SUAVE,
		"%d punto%s por gastar" % [e.dt_puntos, "" if e.dt_puntos == 1 else "s"])
	cab.add_child(pts)
	if e.dt_puntos > 0:
		(func() -> void: Animar.pulso(pts, 1.15)).call_deferred()
	var grande := Button.new()
	grande.text = "⛶ En grande"
	grande.pressed.connect(func() -> void: ArbolHabilidades.abrir_en_grande(p, e, p._refrescar))
	cab.add_child(grande)
	var arbol := ArbolHabilidades.crear(e)
	p._lista_habilidades.add_child(arbol)
	p._lista_habilidades.add_child(arbol.ficha())
	## Las 15 maestrías de 30 niveles, debajo del árbol.
	PanelMaestrias.pintar(p._lista_habilidades, p.mundo, p)
	arbol.aprendida.connect(func(_k: String) -> void:
		Aviso.mostrar(p, "nivel", "🎓", "Habilidad aprendida", e.dt_nombre(_k))
		p._refrescar())
	Animar.aparecer(arbol)

## En Legado queda un resumen con el acceso al árbol, que vive en MI VIDA.
func _pintar_acceso_arbol() -> void:
	## El álbum de cromos y el museo de todas tus carreras (`Meta`).
	var sobres := int(Meta.leer()["sobres"])
	var alb := Button.new()
	alb.text = "📒 Álbum de cromos y museo de tus carreras" + ("  ·  🎁 %d sobre%s" % [sobres, "" if sobres == 1 else "s"] if sobres > 0 else "")
	alb.pressed.connect(func() -> void: PanelMeta.abrir(p, p.mundo))
	p._lista_legado.add_child(alb)
	var e := p.mundo.entrenamiento
	if e == null:
		return
	var hb := HBoxContainer.new()
	p._lista_legado.add_child(hb)
	var t := p._texto(12, Principal.COL_ORO if e.dt_puntos > 0 else Principal.COL_SUAVE)
	t.text = "🎓 Habilidades de entrenador · %d punto(s) por gastar" % e.dt_puntos
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(t)
	var b := Button.new()
	b.text = "Ver el árbol"
	b.pressed.connect(func() -> void:
		p._elegir_grupo("vida")
		p._ir_a_chip({"tab": "Habilidades", "label": "Habilidades"}))
	hb.add_child(b)
	p._lista_legado.add_child(HSeparator.new())

func _pintar_arbol_dt() -> void:
	var e := p.mundo.entrenamiento
	if e == null:
		return
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "🎓 TUS HABILIDADES DE ENTRENADOR"
	p._lista_legado.add_child(t)
	var pts := p._texto(14, Principal.COL_ORO if e.dt_puntos > 0 else Principal.COL_SUAVE)
	pts.text = "%d punto(s) por gastar  ·  se gana uno cada %d semanas" % [
		e.dt_puntos, Entrenamiento.SEMANAS_POR_PUNTO_DT]
	p._lista_legado.add_child(pts)
	for rama: String in e.dt_ramas():
		var tr := p._texto(10, p.COL_ACENTO)
		tr.text = rama.to_upper()
		p._lista_legado.add_child(tr)
		for clave: String in (e.dt_ramas()[rama] as Array):
			var tengo := e.dt_tiene(clave)
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 6)
			p._lista_legado.add_child(fila)
			var nom := p._texto(12, Principal.COL_VERDE if tengo else Principal.COL_TEXTO)
			nom.text = "%s  %s" % [e.dt_icono(clave), e.dt_nombre(clave)]
			nom.custom_minimum_size = Vector2(170, 0)
			fila.add_child(nom)
			var desc := p._texto(11, Principal.COL_SUAVE)
			desc.text = e.dt_descripcion(clave)
			desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			fila.add_child(desc)
			if tengo:
				var ya := p._texto(11, Principal.COL_VERDE)
				ya.text = "✔"
				ya.custom_minimum_size = Vector2(70, 0)
				fila.add_child(ya)
				continue
			## Cuando no se puede, el botón dice POR QUÉ en vez de estar gris y
			## mudo: "antes: Pizarra fina" y "te faltan 2 punto(s)" son dos
			## problemas distintos y el jugador tiene que poder distinguirlos.
			var motivo := e.dt_motivo(clave)
			var b := Button.new()
			b.text = "%d pto(s)" % e.dt_coste(clave) if motivo == "" else motivo
			b.add_theme_font_size_override("font_size", 10)
			b.disabled = motivo != ""
			b.custom_minimum_size = Vector2(140, 0)
			var k := clave
			b.pressed.connect(func() -> void: _aprender_dt(k))
			fila.add_child(b)
	p._lista_legado.add_child(HSeparator.new())

## El mensaje de éxito lo escribe `entrenamiento.noticia`, ya conectada; aquí
## solo se saca el motivo cuando falla.
func _aprender_dt(clave: String) -> void:
	var problema := p.mundo.entrenamiento.dt_aprender(clave)
	if problema != "":
		p._escribir("[color=#e05555]No puedes aprender eso: %s.[/color]" % problema)
	p._refrescar()

## Las leyendas de TU club, con el botón de homenaje. Se filtran por club a
## propósito: homenajear en el Madrid a una leyenda del Boca no significa nada.
func _pintar_homenajes(r: Roles) -> void:
	var th := p._texto(11, Principal.COL_SUAVE)
	th.text = "🎖️ HOMENAJES"
	p._lista_legado.add_child(th)
	var c := p.mundo.mi_club()
	var mias: Array[Dictionary] = []
	if p.mundo.cantera != null:
		for l: Dictionary in p.mundo.cantera.leyendas:
			if String(l.get("club", "")) == c.id and mias.size() < 6:
				mias.append(l)
	if mias.is_empty():
		var vac := p._texto(12, Principal.COL_SUAVE)
		vac.text = "Sin leyendas registradas en este club todavía."
		p._lista_legado.add_child(vac)
	else:
		var coste := Eco.escalar(Roles.COSTE_HOMENAJE, c.rep)
		for l2: Dictionary in mias:
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 8)
			p._lista_legado.add_child(fila)
			var nom := p._texto(12, Principal.COL_TEXTO)
			nom.text = "%s  ·  %s · nivel %d" % [String(l2.get("nombre", "")), String(l2.get("pos", "")), int(l2.get("nivel", 1))]
			nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila.add_child(nom)
			var b := Button.new()
			b.text = "Homenajear  %s" % p._dinero(coste)
			b.add_theme_font_size_override("font_size", 11)
			b.disabled = c.saldo < coste
			var quien := String(l2.get("nombre", ""))
			b.pressed.connect(func() -> void: _homenajear(quien))
			fila.add_child(b)
		var nota := p._texto(10, Principal.COL_SUAVE)
		nota.text = "Un homenaje llena el estadio, sube el ánimo y la moral del plantel, y deja al club un poco más grande."
		nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_legado.add_child(nota)
	p._lista_legado.add_child(HSeparator.new())

func _pintar_fin_de_carrera(r: Roles) -> void:
	var tf := p._texto(11, Principal.COL_SUAVE)
	tf.text = "🏁 FIN DE CARRERA"
	p._lista_legado.add_child(tf)
	if not r.retirado.is_empty():
		var ya := p._texto(12, Principal.COL_ORO)
		ya.text = "Te retiraste en %d con %d título(s) y %s puntos." % [
			int(r.retirado.get("anio", 0)), r.trofeos.size(), p._miles(int(r.retirado.get("puntaje", 0)))]
		ya.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_legado.add_child(ya)
	else:
		var av := p._texto(11, Principal.COL_SUAVE)
		av.text = "Cuando quieras cerrar la historia, puedes anunciar tu retirada y ver el balance completo de tu carrera. No se puede deshacer."
		av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_legado.add_child(av)
		p._boton("¿SEGURO? Anunciar mi retirada" if p._confirmar_retiro else "🏁 Anunciar mi retirada",
			_retirarse, p._lista_legado)

## `epilogoHTML()`: el resumen con veredicto. Antes de la tercera temporada no
## sale, porque juzgar una carrera de dos años es ruido.
func _pintar_epilogo(r: Roles) -> void:
	var anios := p.mundo.anio - 2026
	if anios < 3:
		return
	p._lista_legado.add_child(HSeparator.new())
	var te := p._texto(11, Principal.COL_SUAVE)
	te.text = "📖 TU CARRERA HASTA AQUÍ"
	p._lista_legado.add_child(te)
	var invicto := int(p.mundo.logros.rachas.get("invicto_max", 0)) if p.mundo.logros != null else 0
	## Los canteranos que DEBUTARON, no los que subieron a la lista: subir a un
	## chico al primer equipo y no ponerlo nunca no es hacer cantera.
	var canteranos := p.mundo.logros.canteranos_debutados.size() if p.mundo.logros != null else 0
	var g := GridContainer.new()
	g.columns = 3
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 14)
	p._lista_legado.add_child(g)
	for par in [["Temporadas", str(anios)], ["Títulos", str(r.trofeos.size())],
			["Clubes", str(r.historial.size() + 1)], ["Prestigio", str(r.prestigio)],
			["Invicto máx.", str(invicto)], ["Canteranos", str(canteranos)]]:
		var col := VBoxContainer.new()
		g.add_child(col)
		var et := p._texto(10, Principal.COL_SUAVE)
		et.text = String(par[0])
		col.add_child(et)
		var va := p._texto(15, Principal.COL_TEXTO)
		va.text = String(par[1])
		col.add_child(va)
	var v: Dictionary = r.veredicto_carrera()
	var tonos := {"oro": Principal.COL_ORO, "verde": Principal.COL_VERDE, "ambar": p.COL_ACENTO, "suave": Principal.COL_SUAVE}
	var frase := p._texto(13, tonos.get(String(v["tono"]), Principal.COL_SUAVE))
	frase.text = String(v["texto"])
	frase.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_legado.add_child(frase)
	## La vitrina cierra el epílogo: los doce últimos, que es lo que cabe sin
	## que la lista se coma la pantalla.
	if not r.trofeos.is_empty():
		var ult := r.trofeos.slice(maxi(0, r.trofeos.size() - 12))
		var partes: Array[String] = []
		for tro: Dictionary in ult:
			partes.append("🏆 %s %s" % [String(tro.get("titulo", "")), str(tro.get("anio", ""))])
		var vit := p._texto(11, Principal.COL_ORO)
		vit.text = "  ·  ".join(partes)
		vit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_legado.add_child(vit)

func _homenajear(nombre: String) -> void:
	var problema := p.mundo.roles.homenajear(nombre)
	if problema != "":
		p._escribir("[color=#e05555]No se pudo hacer el homenaje: %s.[/color]" % problema)
	p._refrescar()

func _retirarse() -> void:
	if not p._confirmar_retiro:
		p._confirmar_retiro = true
		p._refrescar()
		return
	p._confirmar_retiro = false
	var problema := p.mundo.roles.retirarse()
	if problema != "":
		p._escribir("[color=#e05555]%s.[/color]" % problema)
	p._refrescar()

func _filtrar_records() -> void:
	var titulos: Array = []
	for k: String in Principal.SECC_RECORDS:
		titulos.append_array(Principal.SECC_RECORDS[k] as Array)
	var visibles: Array = Principal.SECC_RECORDS.get(p._secc_records, [])
	## Antes del primer título no hay sección: eso se ve siempre -es la
	## cabecera de la pantalla-.
	var mostrando := true
	for n in p._lista_records.get_children():
		var l := n as Label
		if l != null and titulos.has(l.text):
			mostrando = visibles.has(l.text)
		if n is CanvasItem:
			(n as CanvasItem).visible = mostrando
	## FALLA VISUAL (recorrido D4): al empezar una partida Memoria, Rivales y
	## Vitrina salían en blanco -sus secciones solo se pintan cuando hay datos-.
	## Una página en blanco parece un error; esto dice qué va a aparecer ahí.
	var alguno := false
	for n in p._lista_records.get_children():
		if n is CanvasItem and (n as CanvasItem).visible and not n.is_queued_for_deletion():
			alguno = true
			break
	if not alguno:
		var vacio := p._texto(13, Principal.COL_SUAVE)
		vacio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vacio.text = String(Principal.VACIO_RECORDS.get(p._secc_records, "Todavía no hay nada que mostrar aquí: se llena al jugar."))
		p._lista_records.add_child(vacio)

func _pintar_records() -> void:
	p._limpiar(p._lista_records)
	var lg := p.mundo.logros
	if lg == null:
		return

	var tr := p._texto(11, Principal.COL_SUAVE)
	tr.text = "RACHAS"
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
		et.text = String(par[0])
		col.add_child(et)
		var va := p._texto(16, Principal.COL_TEXTO)
		va.text = str(int(r.get(par[1], 0)))
		col.add_child(va)
	p._lista_records.add_child(HSeparator.new())

	var rec: Dictionary = lg.rec
	if rec.has("mayor_goleada"):
		var tm := p._texto(11, Principal.COL_SUAVE)
		tm.text = "MARCAS DEL CLUB"
		p._lista_records.add_child(tm)
		var mg: Dictionary = rec["mayor_goleada"]
		p._dato("Mayor goleada", "%s con %s (%d)" % [String(mg.get("marcador", "")), String(mg.get("rival", "")), int(mg.get("anio", 0))], Principal.COL_VERDE, p._lista_records)
		if rec.has("peor_derrota"):
			var pd: Dictionary = rec["peor_derrota"]
			p._dato("Peor derrota", "%s con %s (%d)" % [String(pd.get("marcador", "")), String(pd.get("rival", "")), int(pd.get("anio", 0))], Principal.COL_ROJO, p._lista_records)
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
		tf.text = "SALÓN DE LA FAMA DEL CLUB"
		p._lista_records.add_child(tf)
		for i in fama.size():
			var f3: Dictionary = fama[i]
			var col_f := Principal.COL_ORO if int(f3["titulos"]) > 0 else Principal.COL_TEXTO
			p._dato("%d.  %s%s" % [i + 1, "🏆 " if int(f3["titulos"]) > 0 else "", String(f3["nombre"])],
				String(f3["motivo"]), col_f, p._lista_records)
		p._lista_records.add_child(HSeparator.new())

	var goleadores := lg.goleadores_historicos(10)
	if not goleadores.is_empty():
		var tg := p._texto(11, Principal.COL_SUAVE)
		tg.text = "GOLEADORES HISTÓRICOS DE TU ERA"
		p._lista_records.add_child(tg)
		for i in goleadores.size():
			var f: Dictionary = goleadores[i]
			p._dato("%d.  %s" % [i + 1, String(f["nombre"])], str(int(f["goles"])), Principal.COL_TEXTO, p._lista_records)
		p._lista_records.add_child(HSeparator.new())

	var mas_pj := lg.mas_partidos(10)
	if not mas_pj.is_empty():
		var tp := p._texto(11, Principal.COL_SUAVE)
		tp.text = "MÁS PARTIDOS DISPUTADOS"
		p._lista_records.add_child(tp)
		for i in mas_pj.size():
			var f2: Dictionary = mas_pj[i]
			p._dato("%d.  %s" % [i + 1, String(f2["nombre"])], str(int(f2["partidos"])), Principal.COL_TEXTO, p._lista_records)
		p._lista_records.add_child(HSeparator.new())

	if not lg.h2h.is_empty():
		var th := p._texto(11, Principal.COL_SUAVE)
		th.text = "CARA A CARA"
		p._lista_records.add_child(th)
		var g2 := GridContainer.new()
		g2.columns = 5
		g2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g2.add_theme_constant_override("h_separation", 10)
		p._lista_records.add_child(g2)
		for t2 in ["CLUB", "PJ", "G", "E", "P"]:
			p._celda(g2, t2, Principal.COL_SUAVE, t2 != "CLUB", 11)
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
		te.text = "UN DÍA COMO HOY"
		p._lista_records.add_child(te)
		var efes: Array = lg.efemerides
		for i in range(efes.size() - 1, maxi(-1, efes.size() - 11), -1):
			var e: Dictionary = efes[i]
			var le := p._texto(11, Principal.COL_SUAVE)
			le.text = "S%d/%d  ·  %s" % [int(e.get("semana", 0)), int(e.get("anio", 0)), String(e.get("texto", ""))]
			le.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_records.add_child(le)
		p._lista_records.add_child(HSeparator.new())

	if not lg.planteles.is_empty():
		var tpl := p._texto(11, Principal.COL_SUAVE)
		tpl.text = "ARCHIVO DE PLANTELES"
		p._lista_records.add_child(tpl)
		if not p._modo_experto:
			var epl := p._texto(10, Principal.COL_SUAVE)
			epl.text = "Pulsa un año para abrir aquel plantel entero: quién estaba, con qué dorsal, cuánto jugó y cuánto marcó."
			epl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_records.add_child(epl)
		var pls: Array = lg.planteles
		for i in range(pls.size() - 1, maxi(-1, pls.size() - 9), -1):
			var p_local: Dictionary = pls[i]
			var anio_p := int(p_local.get("anio", 0))
			var abierto := p._plantel_abierto == anio_p
			var bp := Button.new()
			bp.text = "%s%d  ·  %dº  ·  MVP: %s" % ["▾ " if abierto else "▸ ", anio_p,
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
