extends RefCounted
## (Parte 1 de 4 de `pantalla_club_vida.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `pantalla_club_vida.gd`, conserva la clase.)

## LA VIDA DEL CLUB: el médico, los logros, el museo, las obras, la pretemporada, las mentorías, el entrenamiento, la federación y la hinchada.
##
## Sale de `ui/principal.gd` (mapa de metas 15: el archivo pasaba de
## 15.000 líneas). `p` es la pantalla principal: sus ayudantes (`p._texto`,
## `p._boton`...), el mundo (`p.mundo`) y el repintado (`p._refrescar()`).

var p: Principal

func _init(principal: Principal) -> void:
	p = principal

## La enfermería: quién está fuera, con qué y cuánto le queda, y qué se puede
## hacer al respecto. Es la pantalla que hace que contratar al jefe médico y
## pagar una terapia signifiquen algo.
## EL BALANCE DEL DEPARTAMENTO MÉDICO, de `vMedico()`. La pantalla enseñaba los
## partes uno a uno pero no respondía a la pregunta que de verdad se hace el
## jugador: ¿mi cuerpo médico es bueno o estoy tirando el dinero? Eso solo se
## contesta con el ACUMULADO de la temporada y comparándolo con la liga.
func _pintar_balance_medico(c: Club) -> void:
	var med := p.mundo.medico
	var r: Dictionary = med.ranking_liga(c, p._liga_de(c))
	var g := GridContainer.new()
	g.columns = 4
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 12)
	p._lista_medico.add_child(g)
	var enfermeria := 0
	for j in c.plantilla:
		if j.lesion > 0:
			enfermeria += 1
	for par in [["En la enfermería", str(enfermeria)], ["Días perdidos", str(med.dias_perdidos)],
			["En la liga", "%d.º de %d" % [int(r["puesto"]), int(r["total"])]],
			["Media de la liga", "%d sem" % int(r["media"])]]:
		var col := VBoxContainer.new()
		g.add_child(col)
		var et := p._texto(10, Principal.COL_SUAVE)
		et.text = String(par[0])
		col.add_child(et)
		var va := p._texto(16, Principal.COL_TEXTO)
		va.text = String(par[1])
		col.add_child(va)
	## El veredicto en una frase. Un puesto en una tabla no dice qué hacer; esto
	## sí, y es lo que convierte la pantalla en una decisión.
	var mejor := int(r["mias"]) < int(r["media"])
	var v := p._texto(11, Principal.COL_VERDE if mejor else Principal.COL_ORO)
	v.text = (Idiomas.t("Tu cuerpo médico pierde menos semanas que la media de la liga. Se nota la inversión.")
		if mejor else
		Idiomas.t("Pierdes más semanas por lesión que la media. Mira el jefe médico, el centro médico y la carga de entrenamiento."))
	v.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_medico.add_child(v)
	if not med.brote.is_empty():
		var b := p._texto(12, Principal.COL_ROJO)
		b.text = Idiomas.t("🤒 Brote activo: %d tocados, %d semana(s) más.") % [
			int(med.brote.get("n", 0)), int(med.brote.get("semanas", 0))]
		p._lista_medico.add_child(b)
	## LOS DE RIESGO: quién llega justo al domingo. Es la lista que evita la
	## lesión antes de que pase, que es más útil que el parte de la que ya pasó.
	var riesgo: Array[Jugador] = []
	for j2 in c.plantilla:
		if j2.lesion <= 0 and (j2.fisico < 62 or j2.rasgo == "fragil"):
			riesgo.append(j2)
	riesgo.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.fisico < b.fisico)
	if not riesgo.is_empty():
		p._lista_medico.add_child(HSeparator.new())
		var tr := p._texto(11, Principal.COL_SUAVE)
		tr.text = Idiomas.t("EN RIESGO ESTA SEMANA")
		p._lista_medico.add_child(tr)
		for i in mini(8, riesgo.size()):
			var j3: Jugador = riesgo[i]
			p._dato("%s%s  ·  físico %d" % ["🩹 " if j3.rasgo == "fragil" else "⚠️ ", j3.nombre, j3.fisico],
				"no debería jugar" if j3.fisico < 50 else "al límite",
				Principal.COL_ROJO if j3.fisico < 50 else Principal.COL_ORO, p._lista_medico)
	p._lista_medico.add_child(HSeparator.new())

func _terapia(j: Jugador) -> void:
	var problema := p.mundo.medico.terapia(j, p.mundo.mi_club())
	if problema != "":
		p._escribir("[color=#e05555]No se puede: %s.[/color]" % problema)
		return
	p._escribir("[color=#4caf6d]Terapia para %s:[/color] le quedan %d semanas." % [j.nombre, j.lesion])
	p._refrescar()

func _segunda_opinion(j: Jugador) -> void:
	var r := p.mundo.medico.segunda_opinion(j, p.mundo.mi_club())
	if r.has("error"):
		p._escribir("[color=#e05555]No se pudo: %s.[/color]" % String(r["error"]))
	else:
		var delta := int(r["delta"])
		var color := "#4caf6d" if delta < 0 else ("#e05555" if delta > 0 else "#8ea595")
		p._escribir("[color=%s][b]🩺 Segunda opinión: %s.[/b][/color] %s Se queda en %d semana(s)." % [
			color, j.nombre, String(r["texto"]), int(r["semanas"])])
		p._anotar("🩺 Segunda opinión: %s." % j.nombre, String(r["texto"]))
	p._refrescar()

func _pintar_medico(c: Club) -> void:
	p._limpiar(p._lista_medico)
	if p.mundo.medico == null:
		return
	var nivel := p.mundo.staff.nivel("medico")
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("PARTE MÉDICO  ·  jefe médico: %s") % ("★".repeat(nivel) if nivel > 0 else Idiomas.t("sin contratar"))
	p._lista_medico.add_child(t)
	_pintar_balance_medico(c)
	var tocados := c.plantilla.filter(func(j: Jugador) -> bool: return j.lesion > 0 or j.suspension > 0)
	if tocados.is_empty():
		var vacio := p._texto(13, Principal.COL_VERDE)
		vacio.text = Idiomas.t("Enfermería vacía: los %d están disponibles.") % c.plantilla.size()
		p._lista_medico.add_child(vacio)
	tocados.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.lesion > b.lesion)
	for j: Jugador in tocados:
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		p._lista_medico.add_child(fila)
		fila.add_child(p._retrato(j, 24))
		var nom := p._texto(12, Principal.COL_ROJO)
		var diag := p.mundo.medico.diagnostico(j) if j.lesion > 0 else "sancionado"
		nom.text = "%s  ·  %s" % [j.nombre, diag]
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(nom)
		if j.lesion > 0:
			var pct := p._texto(11, Principal.COL_SUAVE)
			pct.text = Idiomas.t("%d%% recuperado") % p.mundo.medico.pct_recuperado(j)
			fila.add_child(pct)
			var coste := p.mundo.medico.costo_terapia(j, c.rep)
			var b := Button.new()
			b.text = Idiomas.t("Terapia  %s") % p._dinero(coste)
			b.add_theme_font_size_override("font_size", 11)
			b.disabled = coste > c.saldo
			b.pressed.connect(func() -> void: _terapia(j))
			fila.add_child(b)
			## La segunda opinión: puede acortar el plazo, alargarlo o
			## confirmarlo. Cuanto mejor es tu cuerpo médico, menos hay que
			## corregir -pero también menos sustos-, que es lo que la convierte
			## en una apuesta y no en un botón de "curar más rápido".
			var coste_op := p.mundo.medico.coste_segunda_opinion(j, c)
			var b2 := Button.new()
			b2.text = Idiomas.t("2.ª opinión  %s") % p._dinero(coste_op)
			b2.add_theme_font_size_override("font_size", 11)
			b2.disabled = coste_op > c.saldo
			b2.pressed.connect(func() -> void: _segunda_opinion(j))
			fila.add_child(b2)

	## Y el riesgo de los que están sanos pero cargados: es lo que permite rotar
	## antes de romper a alguien, en vez de enterarse cuando ya está roto.
	p._lista_medico.add_child(HSeparator.new())
	var t2 := p._texto(11, Principal.COL_SUAVE)
	t2.text = Idiomas.t("RIESGO DE LESIÓN")
	p._lista_medico.add_child(t2)
	var sanos := c.plantilla.filter(func(j: Jugador) -> bool: return j.lesion <= 0)
	sanos.sort_custom(func(a: Jugador, b: Jugador) -> bool:
		return p.mundo.medico.riesgo_por_fatiga(a) > p.mundo.medico.riesgo_por_fatiga(b))
	for i in mini(8, sanos.size()):
		var j2: Jugador = sanos[i]
		var r := p.mundo.medico.riesgo_declarado(j2)
		var col2 := Principal.COL_ROJO if r == "alto" else (Principal.COL_ORO if r.begins_with("medio") else Principal.COL_SUAVE)
		var l := p._texto(12, col2)
		l.text = Idiomas.t("%s  ·  riesgo %s  ·  físico %d") % [j2.nombre, r, j2.fisico]
		p._lista_medico.add_child(l)

## LOS LOGROS OCULTOS. No se anuncian y no se listan: hasta que caen se ven como
## "???". Esa es toda la gracia —premian cosas que casi nunca pasan y que nadie
## va a perseguir porque no sabe que existen—, así que enseñar el enunciado los
## estropearía.
func _pintar_logros_ocultos(lg: Logros) -> void:
	var lista := lg.catalogo_oculto()
	if lista.is_empty():
		return
	p._lista_logros.add_child(HSeparator.new())
	var caidos := 0
	for f: Dictionary in lista:
		if bool(f["conseguido"]):
			caidos += 1
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("🎖️ LOGROS OCULTOS  ·  %d/%d") % [caidos, lista.size()]
	p._lista_logros.add_child(t)
	var ex := p._texto(10, Principal.COL_SUAVE)
	ex.text = Idiomas.t("Estos no se anuncian: aparecen solos cuando pasa algo que casi nunca pasa.")
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_logros.add_child(ex)
	for f2: Dictionary in lista:
		var hecho := bool(f2["conseguido"])
		var l := p._texto(12, Principal.COL_ORO if hecho else Principal.COL_SUAVE)
		l.text = "%s  %s — %s" % ["🎖️" if hecho else "❔", String(f2["titulo"]), String(f2["descripcion"])]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_logros.add_child(l)

## EL RANKING DE CANTERAS. Mide quién forma de verdad -cantidad Y techo juntos-
## y, sobre todo, dónde estás tú. Es la única pantalla del juego que compara tu
## trabajo de cantera con el de los otros 383 clubes.
func _pintar_ranking_canteras() -> void:
	if p.mundo.cantera == null:
		return
	var r := p.mundo.cantera.ranking_canteras()
	if r.is_empty():
		return
	p._lista_logros.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("🌱 RANKING DE CANTERAS")
	p._lista_logros.add_child(t)
	var mio := p.mundo.mi_club()
	var mi_puesto := 0
	for i in r.size():
		if (r[i] as Dictionary)["club"] == mio:
			mi_puesto = i + 1
	for i in mini(10, r.size()):
		var f: Dictionary = r[i]
		var c: Club = f["club"]
		var propio := c == mio
		p._dato("%d.  %s" % [i + 1, c.nombre],
			"%d juveniles  ·  %d" % [int(f["juveniles"]), int(f["nota"])],
			p.COL_ACENTO if propio else Principal.COL_TEXTO, p._lista_logros)
	## Si no estás entre los diez, se dice en qué puesto estás: un ranking en el
	## que no te encuentras no sirve de nada.
	if mi_puesto > 10:
		var p_local := p._texto(11, p.COL_ACENTO)
		p_local.text = Idiomas.t("Tu club va %d.º de %d.") % [mi_puesto, r.size()]
		p._lista_logros.add_child(p_local)

## `vHistoria()`: el palmarés temporada a temporada y la foto de cada plantilla.
## `Logros.muro` guarda cada título con EL ONCE que lo levantó, y `planteles` la
## plantilla entera de cada año con su MVP. Las dos cosas se escribían desde el
## porte y no se veían: era memoria que el club acumulaba para nadie.
func _pintar_palmares_por_anio(lg: Logros) -> void:
	if lg.muro.is_empty() and lg.planteles.is_empty():
		return
	p._lista_logros.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("📜 TEMPORADA A TEMPORADA")
	p._lista_logros.add_child(t)
	## Se agrupan los títulos por año para que un año con tres copas salga en una
	## sola línea y no en tres: lo que se lee aquí es la HISTORIA, no el listado.
	var por_anio := {}
	for e: Dictionary in lg.muro:
		var a := int(e.get("anio", 0))
		if not por_anio.has(a):
			por_anio[a] = []
		(por_anio[a] as Array).append(String(e.get("titulo", "")))
	## De más reciente a más antiguo: lo que pasó el año pasado importa más.
	var anios := []
	for p_local: Dictionary in lg.planteles:
		anios.append(int(p_local.get("anio", 0)))
	for a2: int in por_anio:
		if not anios.has(a2):
			anios.append(a2)
	anios.sort()
	anios.reverse()
	for a3: int in anios:
		var titulos: Array = por_anio.get(a3, [])
		var puesto := ""
		var mvp := ""
		for p2: Dictionary in lg.planteles:
			if int(p2.get("anio", 0)) == a3:
				puesto = "%d.º" % int(p2.get("puesto", 0))
				mvp = String(p2.get("mvp", ""))
		var partes: Array[String] = []
		if puesto != "":
			partes.append(puesto)
		if not titulos.is_empty():
			partes.append("🏆 " + ", ".join(PackedStringArray(titulos)))
		if mvp != "":
			partes.append("figura: %s" % mvp)
		p._dato(str(a3), "  ·  ".join(partes) if not partes.is_empty() else "—",
			Principal.COL_ORO if not titulos.is_empty() else Principal.COL_SUAVE, p._lista_logros)

## Los logros. Se enseñan los conseguidos y los que faltan; los que dependen de
## un sistema que todavía no está portado salen marcados aparte, en vez de
## fingir que se pueden conseguir.
func _pintar_logros() -> void:
	p._limpiar(p._lista_logros)
	if p.mundo.logros == null:
		return
	var lg := p.mundo.logros

	## El perfil de gestor: la carrera que sobrevive a esta partida. Va primero
	## porque es lo único de esta pestaña que no se pierde ni empezando de cero.
	var perfil := Logros.perfil_leer()
	var nivel := Logros.perfil_nivel(int(perfil["xp"]))
	var tp := p._texto(13, p.COL_ACENTO)
	tp.text = "%s  ·  %d XP" % [String(nivel["nombre"]), int(nivel["xp"])]
	p._lista_logros.add_child(tp)
	var barra := ProgressBar.new()
	barra.min_value = 0
	barra.max_value = 100
	barra.value = int(nivel["pct"])
	barra.custom_minimum_size = Vector2(0, 14)
	barra.show_percentage = false
	p._lista_logros.add_child(barra)
	var lema := p._texto(11, Principal.COL_SUAVE)
	lema.text = String(nivel["lema"]) + ((Idiomas.t("  ·  faltan %d XP para %s") % [int(nivel["faltan"]), String(nivel["siguiente"])]) if String(nivel["siguiente"]) != "" else "")
	lema.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_logros.add_child(lema)
	p._lista_logros.add_child(HSeparator.new())

	var cat := lg.catalogo()
	var hechos := 0
	for f: Dictionary in cat:
		if f["conseguido"]:
			hechos += 1
	var t := p._texto(13, Principal.COL_ORO)
	t.text = Idiomas.t("%d de %d logros") % [hechos, cat.size()]
	p._lista_logros.add_child(t)
	for f: Dictionary in cat:
		var col := Principal.COL_VERDE if f["conseguido"] else (Principal.COL_BORDE if f["pendiente"] else Principal.COL_SUAVE)
		var l := p._texto(12, col)
		var marca := "hecho" if f["conseguido"] else ("—" if f["pendiente"] else "por hacer")
		l.text = "%s %s  ·  %s" % [String(f["icono"]), String(f["titulo"]), marca]
		p._lista_logros.add_child(l)
		var d := p._texto(11, Principal.COL_BORDE if f["pendiente"] else Principal.COL_SUAVE)
		d.text = "     " + String(f["descripcion"]) + (Idiomas.t("   (su sistema aún no está portado)") if f["pendiente"] else "")
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_logros.add_child(d)

	if not lg.muro.is_empty():
		p._lista_logros.add_child(HSeparator.new())
		var tm := p._texto(11, Principal.COL_SUAVE)
		tm.text = Idiomas.t("VITRINA")
		p._lista_logros.add_child(tm)
		for i in range(lg.muro.size() - 1, maxi(-1, lg.muro.size() - 6), -1):
			var trofeo: Dictionary = lg.muro[i]
			var lt := p._texto(12, Principal.COL_ORO)
			lt.text = "%d  ·  %s" % [int(trofeo.get("anio", 0)), String(trofeo.get("titulo", ""))]
			p._lista_logros.add_child(lt)

	var goleadores := lg.goleadores_historicos(5)
	if not goleadores.is_empty():
		p._lista_logros.add_child(HSeparator.new())
		var tg := p._texto(11, Principal.COL_SUAVE)
		tg.text = Idiomas.t("MÁXIMOS GOLEADORES DE TU ERA")
		p._lista_logros.add_child(tg)
		for fila: Dictionary in goleadores:
			var lg2 := p._texto(12, Principal.COL_TEXTO)
			lg2.text = Idiomas.t("%s  ·  %d goles") % [String(fila["nombre"]), int(fila["goles"])]
			p._lista_logros.add_child(lg2)

	if not lg.rec.is_empty():
		p._lista_logros.add_child(HSeparator.new())
		var tr := p._texto(11, Principal.COL_SUAVE)
		tr.text = Idiomas.t("RÉCORDS DEL CLUB")
		p._lista_logros.add_child(tr)
		if lg.rec.has("mayor_goleada"):
			var f2: Dictionary = lg.rec["mayor_goleada"]
			var lr := p._texto(12, Principal.COL_VERDE)
			lr.text = Idiomas.t("Mayor goleada: %s a %s (%d)") % [String(f2.get("marcador", "")), String(f2.get("rival", "")), int(f2.get("anio", 0))]
			p._lista_logros.add_child(lr)
		if lg.rec.has("peor_derrota"):
			var f3: Dictionary = lg.rec["peor_derrota"]
			var lr2 := p._texto(12, Principal.COL_ROJO)
			lr2.text = Idiomas.t("Peor derrota: %s ante %s (%d)") % [String(f3.get("marcador", "")), String(f3.get("rival", "")), int(f3.get("anio", 0))]
			p._lista_logros.add_child(lr2)
	_pintar_logros_ocultos(lg)
	_pintar_ranking_canteras()
	_pintar_palmares_por_anio(lg)
	p._pintar_museo(lg)

## La copa continental: en qué torneo estás y cómo va.
func _pintar_conti(c: Club) -> void:
	p._limpiar(p._lista_conti)
	if p.mundo.continentales.is_empty():
		var vacio := p._texto(12, Principal.COL_SUAVE)
		vacio.text = Idiomas.t("Las copas continentales se sortean al empezar la temporada.")
		p._lista_conti.add_child(vacio)
		return
	var mia := p.mundo.mi_continental()
	for k: String in p.mundo.continentales:
		var t: Continental = p.mundo.continentales[k]
		var propia := t == mia
		var cab := p._texto(13, p.COL_ACENTO if propia else Principal.COL_SUAVE)
		var estado := ("campeón: " + t.campeon.nombre) if t.campeon != null else t.nombre_de_ronda()
		cab.text = "%s%s  —  %s" % ["> " if propia else "   ", Continental.nombre_conti(k), estado]
		p._lista_conti.add_child(cab)
		if not propia:
			continue
		if t.en_fase_de_grupos():
			for i in t.grupos.size():
				var g := p._texto(11, Principal.COL_SUAVE)
				g.text = "  " + t.nombre_de_grupo(i)
				p._lista_conti.add_child(g)
				for fila: Dictionary in t.tabla_de_grupo(i):
					var club: Club = fila["club"]
					var l := p._texto(12, p.COL_ACENTO if club == c else Principal.COL_TEXTO)
					l.text = Idiomas.t("    %s  ·  %d pts") % [club.nombre, int(fila.get("pts", 0))]
					p._lista_conti.add_child(l)
		var cruce := t.emparejamiento_de(c)
		if cruce.size() == 2:
			var l2 := p._texto(12, Principal.COL_VERDE)
			l2.text = Idiomas.t("  Te toca: %s  vs  %s") % [cruce[0].nombre, cruce[1].nombre]
			p._lista_conti.add_child(l2)
		var prem := p._texto(11, Principal.COL_ORO)
		prem.text = Idiomas.t("  Premio al campeón: %s  (fijo, no escalado al tamaño del club)") % p._dinero(t.premio)
		p._lista_conti.add_child(prem)

## Devuelve "" si arrancó o el motivo. La usan el panel y el mapa 3D (B7).
func _empezar_obra(clave: String) -> String:
	if p.mundo.roles != null and not p.mundo.roles.puede_construir():
		return "tu cargo no puede autorizar obras"
	var problema := p.mundo.obras.iniciar(clave, p.mundo.mi_club())
	if problema != "":
		p._escribir("[color=#e05555]No se puede empezar la obra: %s.[/color]" % problema)
		return problema
	var datos: Array = Instalaciones.CATALOGO[clave]
	p._escribir("[color=#c9a227]Obra iniciada:[/color] %s, nivel %d. Estará lista en %d semanas." % [
		String(datos[0]), p.mundo.obras.nivel(clave) + 1, p.mundo.obras.semanas_de(clave)])
	p._refrescar()
	return ""
