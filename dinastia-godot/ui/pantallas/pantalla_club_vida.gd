class_name PantallaClubVida
extends RefCounted
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
	v.text = ("Tu cuerpo médico pierde menos semanas que la media de la liga. Se nota la inversión."
		if mejor else
		"Pierdes más semanas por lesión que la media. Mira el jefe médico, el centro médico y la carga de entrenamiento.")
	v.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_medico.add_child(v)
	if not med.brote.is_empty():
		var b := p._texto(12, Principal.COL_ROJO)
		b.text = "🤒 Brote activo: %d tocados, %d semana(s) más." % [
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
		tr.text = "EN RIESGO ESTA SEMANA"
		p._lista_medico.add_child(tr)
		for i in mini(8, riesgo.size()):
			var j3: Jugador = riesgo[i]
			p._dato("%s%s  ·  físico %d" % ["🩹 " if j3.rasgo == "fragil" else "⚠️ ", j3.nombre, j3.fisico],
				"no debería jugar" if j3.fisico < 50 else "al límite",
				Principal.COL_ROJO if j3.fisico < 50 else Principal.COL_ORO, p._lista_medico)
	p._lista_medico.add_child(HSeparator.new())

func _pintar_medico(c: Club) -> void:
	p._limpiar(p._lista_medico)
	if p.mundo.medico == null:
		return
	var nivel := p.mundo.staff.nivel("medico")
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "PARTE MÉDICO  ·  jefe médico: %s" % ("★".repeat(nivel) if nivel > 0 else "sin contratar")
	p._lista_medico.add_child(t)
	_pintar_balance_medico(c)
	var tocados := c.plantilla.filter(func(j: Jugador) -> bool: return j.lesion > 0 or j.suspension > 0)
	if tocados.is_empty():
		var vacio := p._texto(13, Principal.COL_VERDE)
		vacio.text = "Enfermería vacía: los %d están disponibles." % c.plantilla.size()
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
			pct.text = "%d%% recuperado" % p.mundo.medico.pct_recuperado(j)
			fila.add_child(pct)
			var coste := p.mundo.medico.costo_terapia(j, c.rep)
			var b := Button.new()
			b.text = "Terapia  %s" % p._dinero(coste)
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
			b2.text = "2.ª opinión  %s" % p._dinero(coste_op)
			b2.add_theme_font_size_override("font_size", 11)
			b2.disabled = coste_op > c.saldo
			b2.pressed.connect(func() -> void: _segunda_opinion(j))
			fila.add_child(b2)

	## Y el riesgo de los que están sanos pero cargados: es lo que permite rotar
	## antes de romper a alguien, en vez de enterarse cuando ya está roto.
	p._lista_medico.add_child(HSeparator.new())
	var t2 := p._texto(11, Principal.COL_SUAVE)
	t2.text = "RIESGO DE LESIÓN"
	p._lista_medico.add_child(t2)
	var sanos := c.plantilla.filter(func(j: Jugador) -> bool: return j.lesion <= 0)
	sanos.sort_custom(func(a: Jugador, b: Jugador) -> bool:
		return p.mundo.medico.riesgo_por_fatiga(a) > p.mundo.medico.riesgo_por_fatiga(b))
	for i in mini(8, sanos.size()):
		var j2: Jugador = sanos[i]
		var r := p.mundo.medico.riesgo_declarado(j2)
		var col2 := Principal.COL_ROJO if r == "alto" else (Principal.COL_ORO if r.begins_with("medio") else Principal.COL_SUAVE)
		var l := p._texto(12, col2)
		l.text = "%s  ·  riesgo %s  ·  físico %d" % [j2.nombre, r, j2.fisico]
		p._lista_medico.add_child(l)

func _terapia(j: Jugador) -> void:
	var problema := p.mundo.medico.terapia(j, p.mundo.mi_club())
	if problema != "":
		p._escribir("[color=#e05555]No se puede: %s.[/color]" % problema)
		return
	p._escribir("[color=#4caf6d]Terapia para %s:[/color] le quedan %d semanas." % [j.nombre, j.lesion])
	p._refrescar()

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
	lema.text = String(nivel["lema"]) + (("  ·  faltan %d XP para %s" % [int(nivel["faltan"]), String(nivel["siguiente"])]) if String(nivel["siguiente"]) != "" else "")
	lema.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_logros.add_child(lema)
	p._lista_logros.add_child(HSeparator.new())

	var cat := lg.catalogo()
	var hechos := 0
	for f: Dictionary in cat:
		if f["conseguido"]:
			hechos += 1
	var t := p._texto(13, Principal.COL_ORO)
	t.text = "%d de %d logros" % [hechos, cat.size()]
	p._lista_logros.add_child(t)
	for f: Dictionary in cat:
		var col := Principal.COL_VERDE if f["conseguido"] else (Principal.COL_BORDE if f["pendiente"] else Principal.COL_SUAVE)
		var l := p._texto(12, col)
		var marca := "hecho" if f["conseguido"] else ("—" if f["pendiente"] else "por hacer")
		l.text = "%s %s  ·  %s" % [String(f["icono"]), String(f["titulo"]), marca]
		p._lista_logros.add_child(l)
		var d := p._texto(11, Principal.COL_BORDE if f["pendiente"] else Principal.COL_SUAVE)
		d.text = "     " + String(f["descripcion"]) + ("   (su sistema aún no está portado)" if f["pendiente"] else "")
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_logros.add_child(d)

	if not lg.muro.is_empty():
		p._lista_logros.add_child(HSeparator.new())
		var tm := p._texto(11, Principal.COL_SUAVE)
		tm.text = "VITRINA"
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
		tg.text = "MÁXIMOS GOLEADORES DE TU ERA"
		p._lista_logros.add_child(tg)
		for fila: Dictionary in goleadores:
			var lg2 := p._texto(12, Principal.COL_TEXTO)
			lg2.text = "%s  ·  %d goles" % [String(fila["nombre"]), int(fila["goles"])]
			p._lista_logros.add_child(lg2)

	if not lg.rec.is_empty():
		p._lista_logros.add_child(HSeparator.new())
		var tr := p._texto(11, Principal.COL_SUAVE)
		tr.text = "RÉCORDS DEL CLUB"
		p._lista_logros.add_child(tr)
		if lg.rec.has("mayor_goleada"):
			var f2: Dictionary = lg.rec["mayor_goleada"]
			var lr := p._texto(12, Principal.COL_VERDE)
			lr.text = "Mayor goleada: %s a %s (%d)" % [String(f2.get("marcador", "")), String(f2.get("rival", "")), int(f2.get("anio", 0))]
			p._lista_logros.add_child(lr)
		if lg.rec.has("peor_derrota"):
			var f3: Dictionary = lg.rec["peor_derrota"]
			var lr2 := p._texto(12, Principal.COL_ROJO)
			lr2.text = "Peor derrota: %s ante %s (%d)" % [String(f3.get("marcador", "")), String(f3.get("rival", "")), int(f3.get("anio", 0))]
			p._lista_logros.add_child(lr2)
	_pintar_logros_ocultos(lg)
	_pintar_ranking_canteras()
	_pintar_palmares_por_anio(lg)
	p._pintar_museo(lg)

## `vHistoria()`: el palmarés temporada a temporada y la foto de cada plantilla.
## `Logros.muro` guarda cada título con EL ONCE que lo levantó, y `planteles` la
## plantilla entera de cada año con su MVP. Las dos cosas se escribían desde el
## porte y no se veían: era memoria que el club acumulaba para nadie.
func _pintar_palmares_por_anio(lg: Logros) -> void:
	if lg.muro.is_empty() and lg.planteles.is_empty():
		return
	p._lista_logros.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "📜 TEMPORADA A TEMPORADA"
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
	t.text = "🎖️ LOGROS OCULTOS  ·  %d/%d" % [caidos, lista.size()]
	p._lista_logros.add_child(t)
	var ex := p._texto(10, Principal.COL_SUAVE)
	ex.text = "Estos no se anuncian: aparecen solos cuando pasa algo que casi nunca pasa."
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
	t.text = "🌱 RANKING DE CANTERAS"
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
		p_local.text = "Tu club va %d.º de %d." % [mi_puesto, r.size()]
		p._lista_logros.add_child(p_local)

## La copa continental: en qué torneo estás y cómo va.
func _pintar_conti(c: Club) -> void:
	p._limpiar(p._lista_conti)
	if p.mundo.continentales.is_empty():
		var vacio := p._texto(12, Principal.COL_SUAVE)
		vacio.text = "Las copas continentales se sortean al empezar la temporada."
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
					l.text = "    %s  ·  %d pts" % [club.nombre, int(fila.get("pts", 0))]
					p._lista_conti.add_child(l)
		var cruce := t.emparejamiento_de(c)
		if cruce.size() == 2:
			var l2 := p._texto(12, Principal.COL_VERDE)
			l2.text = "  Te toca: %s  vs  %s" % [cruce[0].nombre, cruce[1].nombre]
			p._lista_conti.add_child(l2)
		var prem := p._texto(11, Principal.COL_ORO)
		prem.text = "  Premio al campeón: %s  (fijo, no escalado al tamaño del club)" % p._dinero(t.premio)
		p._lista_conti.add_child(prem)

## Las obras del club, dentro de la pestaña Club.
##
## Se enseña el nivel, lo que hace, lo que cuesta y —si está en marcha— cuántas
## semanas faltan. Ese último dato es el que hace que el sistema tenga sentido:
## las obras no son instantáneas a propósito, así que hay que poder ver en qué
## punto va cada una para decidir qué se empieza después.
func _pintar_obras(c: Club) -> void:
	p._lista_club.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "OBRAS  ·  %d niveles construidos  ·  aforo %s" % [
		p.mundo.obras.construido(), p._miles(c.estadio_aforo)]
	p._lista_club.add_child(t)
	if not p.mundo.obras.obras.is_empty():
		for k: String in p.mundo.obras.obras:
			var falta := int(p.mundo.obras.obras[k])
			var l := p._texto(12, Principal.COL_ORO)
			l.text = "  En obra: %s  —  %d semana%s" % [
				String(Instalaciones.CATALOGO[k][0]), falta, "" if falta == 1 else "s"]
			p._lista_club.add_child(l)
	for clave: String in Instalaciones.CATALOGO:
		var datos: Array = Instalaciones.CATALOGO[clave]
		var n := p.mundo.obras.nivel(clave)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		p._lista_club.add_child(fila)
		var nom := p._texto(12, Principal.COL_TEXTO)
		nom.text = "%s  %s" % ["*".repeat(n) + ".".repeat(p.mundo.obras.maximo(clave) - n), String(datos[0])]
		if n > 0:
			nom.tooltip_text = Trabajadores.texto_de(c, clave)
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(nom)
		if p.mundo.obras.en_obra(clave):
			var enc := p._texto(11, Principal.COL_ORO)
			enc.text = "en obra"
			fila.add_child(enc)
		elif n >= p.mundo.obras.maximo(clave):
			var tope := p._texto(11, Principal.COL_VERDE)
			tope.text = "al máximo"
			fila.add_child(tope)
		else:
			var precio := p.mundo.obras.coste(clave, c.rep)
			var b := Button.new()
			b.text = "Construir  %s  (%d sem)" % [p._dinero(precio), p.mundo.obras.semanas_de(clave)]
			b.add_theme_font_size_override("font_size", 11)
			b.disabled = precio > c.saldo or (p.mundo.roles != null and not p.mundo.roles.puede_construir())
			b.pressed.connect(func() -> void: _empezar_obra(clave))
			fila.add_child(b)
		var que := p._texto(11, Principal.COL_SUAVE)
		que.text = "    " + String(datos[1])
		if n > 0 and p.mundo.trabajadores != null:
			## El equipo entero, con habilidad y ánimo (26-9-2026).
			que.text += "\n    👥 " + p.mundo.trabajadores.texto_equipo(c, p.mundo.obras, clave).replace("\n", "\n    👥 ")
		que.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_club.add_child(que)

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

## EL DESPACHO DEL ENTRENADOR: el plan de la semana y el árbol de habilidades.
## `vEntrenoPlus()` del HTML, la parte que faltaba: la PRETEMPORADA y la
## CONCENTRACIÓN de la semana. `Entrenamiento.elegir_pretemporada()` estaba
## escrita entera -con su coste, sus efectos de físico y base, y su riesgo de
## romper a alguien- y no la llamaba ninguna pantalla; `concentracion` lo mismo:
## el proceso semanal ya la cobraba y daba +3 de físico, pero no había forma de
## encenderla. Dos decisiones de gestión escritas y apagadas.
func _pintar_pretemporada(c: Club, e: Entrenamiento) -> void:
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "PRETEMPORADA"
	p._lista_entren.add_child(t)
	if e.pretemporada != "":
		var hecha := p._texto(12, Principal.COL_VERDE)
		var nombre_p := e.pretemporada
		for fila: Array in e.pretemporadas():
			if String(fila[0]) == e.pretemporada:
				nombre_p = String(fila[1])
		hecha.text = "Ya hecha este año: %s. La próxima, la temporada que viene." % nombre_p
		hecha.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_entren.add_child(hecha)
	else:
		for fila: Array in e.pretemporadas():
			var clave := String(fila[0])
			var coste := Eco.escalar(float(fila[2]), float(c.rep)) if float(fila[2]) > 0.0 else 0
			var fila_p := HBoxContainer.new()
			fila_p.add_theme_constant_override("separation", 8)
			p._lista_entren.add_child(fila_p)
			var lp := p._texto(12, Principal.COL_TEXTO)
			lp.text = String(fila[1])
			lp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila_p.add_child(lp)
			var bp := Button.new()
			bp.text = "Elegir" if coste == 0 else "Elegir  %s" % p._dinero(coste)
			bp.add_theme_font_size_override("font_size", 11)
			bp.disabled = coste > c.saldo
			bp.pressed.connect(func() -> void: _elegir_pretemporada(clave, c))
			fila_p.add_child(bp)
			var dp := p._texto(10, Principal.COL_SUAVE)
			dp.text = String(fila[3])
			dp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_entren.add_child(dp)

	## La concentración: se paga cada semana y da físico. Es un grifo abierto,
	## así que se enseña lo que cuesta al lado del interruptor.
	var fila_c := HBoxContainer.new()
	fila_c.add_theme_constant_override("separation", 8)
	p._lista_entren.add_child(fila_c)
	var lc := p._texto(12, Principal.COL_TEXTO if e.concentracion else Principal.COL_SUAVE)
	lc.text = "Concentrar al plantel cada semana  ·  %s" % p._dinero(Eco.escalar(Entrenamiento.COSTE_CONCENTRACION, float(c.rep)))
	lc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila_c.add_child(lc)
	var bc := Button.new()
	bc.text = "SÍ" if e.concentracion else "NO"
	bc.add_theme_font_size_override("font_size", 11)
	bc.pressed.connect(func() -> void:
		e.concentracion = not e.concentracion
		p._refrescar())
	fila_c.add_child(bc)
	var dc := p._texto(10, Principal.COL_SUAVE)
	dc.text = "Hotel y trabajo aislado toda la semana: tres puntos de físico para todos, todas las semanas que la dejes puesta."
	dc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_entren.add_child(dc)
	p._lista_entren.add_child(HSeparator.new())

func _elegir_pretemporada(clave: String, c: Club) -> void:
	var err := p.mundo.entrenamiento.elegir_pretemporada(clave, c, p.mundo.anio, p.mundo.semana)
	if err != "":
		p._escribir("[color=#e05555]No se pudo: %s.[/color]" % err)
	else:
		p._escribir("[color=#4caf6d][b]Pretemporada elegida.[/b][/color] El plantel arranca el año con ella.")
	p._refrescar()

## MENTORÍAS: un veterano apadrina a un chico. Es lo que hace que un jugador de
## 33 que ya no es titular siga valiendo para algo -y la única forma de que un
## canterano crezca más rápido de lo que le toca-.
func _pintar_mentorias(c: Club, e: Entrenamiento) -> void:
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "MENTORÍAS  ·  %d de %d" % [e.mentorias.size(), Entrenamiento.MAX_MENTORIAS]
	p._lista_entren.add_child(t)
	for i in e.mentorias.size():
		var m: Dictionary = e.mentorias[i]
		var maestro := p.mundo.jugador_por_id(String(m["maestro"]))
		var pupilo := p.mundo.jugador_por_id(String(m["pupilo"]))
		if maestro == null or pupilo == null:
			continue
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		p._lista_entren.add_child(fila)
		## Las dos caras, maestro y pupilo: la pareja se entiende de un vistazo.
		fila.add_child(p._retrato(maestro, 24))
		fila.add_child(p._retrato(pupilo, 24))
		var l := p._texto(12, Principal.COL_TEXTO)
		l.text = "%s (%d) → %s (%d)  ·  %d semanas, +%d de media" % [
			maestro.nombre, maestro.ovr, pupilo.nombre, pupilo.ovr,
			int(m["semanas"]), int(m["subidas"])]
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(l)
		var idx := i
		p._boton("Romper", func() -> void:
			e.romper_mentoria(idx)
			p._refrescar(), fila)
	## Para crear una hace falta elegir dos: se usa el jugador seleccionado en la
	## ficha como una de las dos mitades, que es la forma de no inventar un
	## selector nuevo en una pantalla que ya tiene bastante.
	if e.mentorias.size() < Entrenamiento.MAX_MENTORIAS:
		if p._seleccionado == null or p._seleccionado.club_id != c.id:
			var pista := p._texto(11, Principal.COL_SUAVE)
			pista.text = "Para crear una: pulsa en el plantel a un veterano (%d+ años y %d+ de media) o a un chico (hasta %d), y aquí aparecerá con quién emparejarlo." % [
				Entrenamiento.MENTOR_EDAD, Entrenamiento.MENTOR_MEDIA, Entrenamiento.PUPILO_EDAD]
			pista.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_entren.add_child(pista)
		else:
			var sel := p._seleccionado
			var es_mentor := e.puede_ser_mentor(sel)
			var es_pupilo := e.puede_ser_pupilo(sel)
			if not es_mentor and not es_pupilo:
				var no := p._texto(11, Principal.COL_SUAVE)
				no.text = "%s no puede ser ni maestro (%d+ años y %d+ de media) ni pupilo (hasta %d años)." % [
					sel.nombre, Entrenamiento.MENTOR_EDAD, Entrenamiento.MENTOR_MEDIA, Entrenamiento.PUPILO_EDAD]
				no.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				p._lista_entren.add_child(no)
			else:
				var papel := "maestro" if es_mentor else "pupilo"
				var tp := p._texto(11, Principal.COL_SUAVE)
				tp.text = "%s puede ser %s. Empareja con:" % [sel.nombre, papel]
				p._lista_entren.add_child(tp)
				for otro: Jugador in c.plantilla:
					var vale := e.puede_ser_pupilo(otro) if es_mentor else e.puede_ser_mentor(otro)
					if not vale or otro == sel:
						continue
					var fila2 := HBoxContainer.new()
					fila2.add_theme_constant_override("separation", 8)
					p._lista_entren.add_child(fila2)
					var l2 := p._texto(12, Principal.COL_SUAVE)
					l2.text = "%s  ·  %d años  ·  media %d" % [otro.nombre, otro.edad, otro.ovr]
					l2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					fila2.add_child(l2)
					var maestro_f: Jugador = sel if es_mentor else otro
					var pupilo_f: Jugador = otro if es_mentor else sel
					p._boton("Emparejar", func() -> void:
						var err := e.crear_mentoria(maestro_f, pupilo_f)
						if err != "":
							p._escribir("[color=#e05555]No se pudo: %s.[/color]" % err)
						p._refrescar(), fila2)
	p._lista_entren.add_child(HSeparator.new())

## `🎓 ENTRENAMIENTO INDIVIDUAL` del HTML: trabajo específico de cinco a nueve
## semanas para que un jugador aprenda una habilidad de verdad -no puntos de
## entrenador, una habilidad del catálogo `ESPECIALES`-. El motor
## (`asignar_individual`/`plan_de`/`especial`, resuelto cada semana en
## `_trabajo_individual()`) llevaba escrito desde siempre; esta pantalla es la
## que le faltaba.
func _pintar_entrenamiento_individual(c: Club, e: Entrenamiento) -> void:
	p._lista_entren.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "🎓 ENTRENAMIENTO INDIVIDUAL  (%d/%d)" % [e.individual.size(), Entrenamiento.MAX_INDIVIDUALES]
	p._lista_entren.add_child(t)
	var intro := p._texto(10, Principal.COL_SUAVE)
	intro.text = "Trabajo específico para un jugador concreto. En cinco a nueve semanas aprende una habilidad nueva de verdad."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_entren.add_child(intro)
	## Los que ya tienen plan, con su progreso -igual que el HTML, arriba de la
	## lista de asignar-.
	for j: Jugador in c.plantilla:
		var plan := e.plan_de(j)
		if plan.is_empty():
			continue
		var esp := e.especial(String(plan.get("clave", "")))
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		p._lista_entren.add_child(fila)
		var et := p._texto(11, Principal.COL_TEXTO)
		et.text = "%s — %s" % [j.nombre, String(esp[1]) if esp.size() > 1 else String(plan["clave"])]
		et.clip_text = true
		et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(et)
		var sem := p._texto(11, Principal.COL_SUAVE)
		sem.text = "%d sem" % int(plan.get("semanas", 0))
		fila.add_child(sem)
		var bc := Button.new()
		bc.text = "Cancelar"
		bc.add_theme_font_size_override("font_size", 11)
		bc.pressed.connect(func() -> void:
			p.mundo.entrenamiento.asignar_individual(j, String(plan["clave"]))
			p._refrescar())
		fila.add_child(bc)
	## A quién asignar: los catorce con más margen hasta su potencial -no solo
	## los jóvenes, cualquiera que todavía pueda crecer-, igual que `vEntreno()`.
	var tg := p._texto(11, Principal.COL_SUAVE)
	tg.text = "ASIGNAR A UN JUGADOR"
	p._lista_entren.add_child(tg)
	var candidatos := c.plantilla.duplicate()
	candidatos.sort_custom(func(a: Jugador, b: Jugador) -> bool: return (b.pot - b.ovr) < (a.pot - a.ovr))
	var lleno := e.individual.size() >= Entrenamiento.MAX_INDIVIDUALES
	for j: Jugador in candidatos.slice(0, 14):
		var plan_j := e.plan_de(j)
		var fila_j := HBoxContainer.new()
		fila_j.add_theme_constant_override("separation", 6)
		p._lista_entren.add_child(fila_j)
		var nom := p._texto(11, Principal.COL_SUAVE)
		nom.text = "%s  (%d años · %d→%d)" % [j.nombre, j.edad, j.ovr, j.pot]
		nom.clip_text = true
		nom.custom_minimum_size = Vector2(170, 0)
		fila_j.add_child(nom)
		var flow_j := HFlowContainer.new()
		flow_j.add_theme_constant_override("h_separation", 4)
		flow_j.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila_j.add_child(flow_j)
		for esp2: Array in e.especiales():
			var clave2 := String(esp2[0])
			var be := Button.new()
			be.text = String(esp2[1])
			be.tooltip_text = String(esp2[2]) if esp2.size() > 2 else ""
			be.add_theme_font_size_override("font_size", 10)
			be.toggle_mode = true
			be.button_pressed = (String(plan_j.get("clave", "")) == clave2)
			be.disabled = lleno and plan_j.is_empty()
			be.pressed.connect(func() -> void:
				p.mundo.entrenamiento.asignar_individual(j, clave2)
				p._refrescar())
			flow_j.add_child(be)

## LA ESTACIÓN, EL CLIMA Y EL HORARIO, de `vEntrenoPlus()`. Tres cosas pequeñas
## que juntas hacen que una temporada no sean cuarenta y dos semanas iguales.
##
## El horario es la única que es una DECISIÓN, y de las buenas: cuanto más paga
## la televisión, menos gente va al estadio. No hay opción correcta —depende de
## si te falta caja o te sobra— y eso es exactamente lo que se busca.
func _pintar_ambiente_y_horario() -> void:
	var est := p.mundo.estacion()
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "LA SEMANA"
	p._lista_entren.add_child(t)
	p._dato("Estación", "%s %s" % [String(est[1]), String(est[0]).capitalize()], Principal.COL_TEXTO, p._lista_entren)
	p._dato("Tiempo previsto", p.mundo.clima().capitalize(), Principal.COL_TEXTO, p._lista_entren)

	var th := p._texto(11, Principal.COL_SUAVE)
	th.text = "HORARIO DEL PARTIDO EN CASA"
	p._lista_entren.add_child(th)
	for h: Array in Mundo.HORARIOS:
		var clave := String(h[0])
		var elegido := p.mundo.horario == clave
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_entren.add_child(fila)
		var b := Button.new()
		b.text = "%s  ·  %s" % [String(h[1]), String(h[2])]
		b.toggle_mode = true
		b.button_pressed = elegido
		b.add_theme_font_size_override("font_size", 11)
		b.clip_text = true
		b.custom_minimum_size = Vector2(200, 0)
		b.pressed.connect(func() -> void:
			p.mundo.horario = clave
			p._refrescar())
		fila.add_child(b)
		## Los dos números que importan, uno al lado del otro: es la única forma
		## de que la decisión se vea como lo que es, un intercambio.
		var pub := p._texto(11, Principal.COL_VERDE if float(h[3]) >= 1.0 else Principal.COL_ROJO)
		pub.text = "público ×%.2f" % float(h[3])
		pub.custom_minimum_size = Vector2(90, 0)
		fila.add_child(pub)
		var tv := p._texto(11, Principal.COL_VERDE if float(h[4]) > 1.0 else Principal.COL_SUAVE)
		tv.text = "TV ×%.2f" % float(h[4])
		tv.custom_minimum_size = Vector2(70, 0)
		fila.add_child(tv)
		var d := p._texto(10, Principal.COL_SUAVE)
		d.text = String(h[5])
		d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		d.clip_text = true
		## La nota de cada horario es una frase completa ("El horario de la
		## tarde..."), y en una columna angosta se corta a media palabra sin
		## avisar -encontrado con una captura real, queja del usuario ("se
		## siente recortada")-. El tooltip es la frase entera, como ya manda
		## la regla de "clip_text siempre con su texto de repuesto".
		d.tooltip_text = String(h[5])
		fila.add_child(d)
	p._lista_entren.add_child(HSeparator.new())

## LA PRETEMPORADA. Tres formas de llegar a la primera jornada, y hay que elegir
## una: el triangular en casa es gratis y da poco, la gira internacional cuesta
## y se paga sola si el club es grande, y los amistosos con la cantera dan menos
## forma al primer equipo y el doble a los chicos.
##
## Existe porque el hueco entre temporadas era un botón de «siguiente» donde no
## pasaba nada, y llegar a la primera jornada con el plantel frío no se podía
## evitar de ninguna manera.
func _pintar_amistosos(c: Club) -> void:
	p._lista_entren.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "🧳 PRETEMPORADA"
	p._lista_entren.add_child(t)
	if p.mundo.amistoso_hecho:
		var ya := p._texto(11, Principal.COL_VERDE)
		ya.text = "✔ Pretemporada jugada. La próxima, al empezar el año que viene."
		ya.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_entren.add_child(ya)
		return
	if not p._modo_experto:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = "Una por temporada. No da puntos: da FORMA, que es lo que le falta a un plantel que lleva un mes parado."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_entren.add_child(ex)
	for a: Array in Mundo.AMISTOSOS:
		var clave := String(a[0])
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_entren.add_child(fila)
		var n := p._texto(12, Principal.COL_TEXTO)
		n.text = String(a[1])
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		fila.add_child(n)
		var f := p._texto(11, Principal.COL_ORO)
		f.text = "+%d forma" % int(a[3])
		f.custom_minimum_size = Vector2(78, 0)
		fila.add_child(f)
		var b := Button.new()
		var coste := Eco.escalar(float(a[2]), float(c.rep)) if float(a[2]) > 0.0 else 0
		b.text = "gratis" if coste == 0 else p._dinero(coste)
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = coste > c.saldo
		b.custom_minimum_size = Vector2(104, 0)
		b.pressed.connect(func() -> void:
			var p_local := p.mundo.jugar_amistosos(clave)
			if p_local != "":
				p._escribir("[color=#e05555]No se pudo: %s.[/color]" % p_local)
			p._refrescar())
		fila.add_child(b)

func _pintar_entrenamiento(c: Club) -> void:
	p._limpiar(p._lista_entren)
	var e := p.mundo.entrenamiento
	if e == null:
		return
	_pintar_ambiente_y_horario()
	_pintar_pretemporada(c, e)
	_pintar_mentorias(c, e)
	_pintar_entrenamiento_individual(c, e)
	_pintar_amistosos(c)

	## LA ROTACIÓN Y EL VIDEOANÁLISIS. Los dos son preparación: se deciden antes
	## de saber cómo va el partido, que es lo que los diferencia de todo lo demás
	## de esta pantalla.
	p._lista_entren.add_child(HSeparator.new())
	var tr := p._texto(11, Principal.COL_SUAVE)
	tr.text = "🔁 ROTACIÓN Y VIDEOANÁLISIS"
	p._lista_entren.add_child(tr)
	var fila_r := HBoxContainer.new()
	fila_r.add_theme_constant_override("separation", 8)
	p._lista_entren.add_child(fila_r)
	var et_r := p._texto(12, Principal.COL_TEXTO)
	et_r.text = "Rotación automática"
	et_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et_r.tooltip_text = "En las semanas cargadas, los que lleguen por debajo de %d de físico dejan sitio a los frescos de su puesto." % Mundo.FISICO_PARA_TITULAR
	fila_r.add_child(et_r)
	var b_r := Button.new()
	b_r.text = "SÍ" if p.mundo.rotacion_activa else "NO"
	b_r.pressed.connect(func() -> void:
		p.mundo.rotacion_activa = not p.mundo.rotacion_activa
		p._refrescar())
	fila_r.add_child(b_r)
	if not p._modo_experto:
		var ex_r := p._texto(10, Principal.COL_SUAVE)
		ex_r.text = "Con liga, copa y continental en la misma quincena, el plantel llega a treinta de físico y no hay forma de evitarlo alineando a mano cada jornada."
		ex_r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_entren.add_child(ex_r)

	var b_v := Button.new()
	b_v.text = "📽️ Videoanálisis del rival de esta semana" if p.mundo.puede_analizar() \
		else "📽️ Videoanálisis (hecho hace poco)"
	b_v.add_theme_font_size_override("font_size", 11)
	b_v.disabled = not p.mundo.puede_analizar()
	b_v.tooltip_text = "Cuesta dos de físico a todo el plantel y da un empujón para ESTE partido. Contra un rival mejor que tú vale más."
	b_v.pressed.connect(func() -> void:
		var p_local := p.mundo.analizar_rival()
		if p_local != "":
			p._escribir("[color=#e05555]No se puede: %s.[/color]" % p_local)
		p._refrescar())
	p._lista_entren.add_child(b_v)
	if p.mundo.bono_analisis > 1.0:
		p._dato("Lección hecha", "+%d%% para el próximo partido" % int(round((p.mundo.bono_analisis - 1.0) * 100.0)),
			Principal.COL_VERDE, p._lista_entren)

	## Lo primero, el resumen de lo que le estás haciendo al plantel esta semana.
	## Es el único número honesto del menú: todo lo demás son etiquetas bonitas.
	var carga: Dictionary = e.carga()
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "PLAN DE LA SEMANA"
	p._lista_entren.add_child(t)
	var res := p._texto(12, Principal.COL_ROJO if float(carga["riesgo"]) > 9.0 else (Principal.COL_ORO if float(carga["riesgo"]) > 7.0 else Principal.COL_VERDE))
	res.text = "Físico %+.1f  ·  progreso %+.1f  ·  riesgo de lesión %.1f  ·  moral %+.1f" % [
		float(carga["fis"]), float(carga["ovr"]), float(carga["riesgo"]), float(carga["moral"])]
	res.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_entren.add_child(res)

	_perilla_texto(p._lista_entren, "Foco", Entrenamiento.FOCOS, e.foco,
		func(k: String) -> void:
			e.fijar_foco(k)
			p._refrescar())
	_perilla_texto(p._lista_entren, "Intensidad", Entrenamiento.INTENSIDADES, e.intensidad,
		func(k: String) -> void:
			e.fijar_intensidad(k)
			p._refrescar())

	## Los días de la semana. Cada uno con su bloque, y se cambia pulsando.
	p._lista_entren.add_child(HSeparator.new())
	var dias: Array = e.nombres_de_dias()
	var catalogo: Array = e.bloques()
	for i in e.dias.size():
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_entren.add_child(fila)
		var dia := p._texto(11, Principal.COL_SUAVE)
		dia.text = String(dias[i]) if i < dias.size() else "Día %d" % (i + 1)
		dia.custom_minimum_size = Vector2(80, 0)
		fila.add_child(dia)
		var b := OptionButton.new()
		b.add_theme_font_size_override("font_size", 11)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for k in catalogo.size():
			var f: Array = catalogo[k]
			b.add_item("%s  %s" % [String(f[2]), String(f[1])])
			b.set_item_metadata(k, String(f[0]))
			if String(f[0]) == e.dias[i]:
				b.select(k)
		b.item_selected.connect(func(idx: int) -> void:
			e.fijar_dia(i, String(b.get_item_metadata(idx)))
			p._refrescar())
		fila.add_child(b)

	## Y el árbol de habilidades del jugador seleccionado. Va aquí y no en la
	## ficha porque es una decisión de entrenamiento, no un dato del jugador.
	p._lista_entren.add_child(HSeparator.new())
	var t2 := p._texto(11, Principal.COL_SUAVE)
	if p._seleccionado == null:
		t2.text = "HABILIDADES  ·  elige un jugador en el plantel"
		p._lista_entren.add_child(t2)
		return
	var j := p._seleccionado
	t2.text = "HABILIDADES DE %s  ·  %d punto%s" % [
		j.nombre.to_upper(), e.puntos(j), "" if e.puntos(j) == 1 else "s"]
	p._lista_entren.add_child(t2)
	var suyas: Array = e.habilidades(j)
	if not suyas.is_empty():
		var ya := p._texto(12, Principal.COL_VERDE)
		var nombres: Array[String] = []
		for k: String in suyas:
			nombres.append(e.nombre_habilidad(k))
		ya.text = "Ya sabe: " + ", ".join(nombres)
		ya.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_entren.add_child(ya)
	for clave: String in e.disponibles(j):
		var fila2 := HBoxContainer.new()
		fila2.add_theme_constant_override("separation", 8)
		p._lista_entren.add_child(fila2)
		var nom := p._texto(12, Principal.COL_TEXTO)
		nom.text = e.nombre_habilidad(clave)
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila2.add_child(nom)
		var motivo := e.motivo(j, clave)
		if motivo == "":
			var b2 := Button.new()
			b2.text = "Aprender"
			b2.add_theme_font_size_override("font_size", 11)
			b2.pressed.connect(func() -> void: _aprender(j, clave))
			fila2.add_child(b2)
		else:
			## Se dice POR QUÉ no puede, no solo que no puede: sin el motivo, el
			## jugador prueba a ciegas y el árbol parece roto.
			var no := p._texto(11, Principal.COL_SUAVE)
			no.text = motivo
			fila2.add_child(no)

func _aprender(j: Jugador, clave: String) -> void:
	var problema := p.mundo.entrenamiento.aprender(j, clave)
	if problema != "":
		p._escribir("[color=#e05555]No puede aprenderla: %s.[/color]" % problema)
		return
	p._escribir("[color=#4caf6d]%s aprende %s.[/color]" % [
		j.nombre, p.mundo.entrenamiento.nombre_habilidad(clave)])
	p._refrescar()

## Una perilla de tres o más opciones a partir de un diccionario clave -> [nombre, ...].
func _perilla_texto(padre: VBoxContainer, etiqueta: String, catalogo: Dictionary,
		actual: String, al_cambiar: Callable) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	padre.add_child(h)
	var l := p._texto(11, Principal.COL_SUAVE)
	l.text = etiqueta
	l.custom_minimum_size = Vector2(80, 0)
	h.add_child(l)
	for k: String in catalogo:
		var datos: Array = catalogo[k]
		var b := Button.new()
		b.text = String(datos[0])
		b.toggle_mode = true
		b.button_pressed = (k == actual)
		b.add_theme_font_size_override("font_size", 11)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void: al_cambiar.call(k))
		h.add_child(b)

## LA FEDERACIÓN: el reglamento vigente y la votación pendiente.
## `vFederacion()` del HTML tiene cuatro bloques y en Godot solo se veía uno
## (reglamento y votación). Los otros tres estaban ESCRITOS Y CORRIENDO en
## `federacion.gd` desde hace tiempo, sin una sola línea que los enseñara:
## `requisitos_licencia()`/`auditoria_anual()` (te pueden denegar la licencia y
## dejarte sin cupo internacional), `casos`/`apelar()` (el tribunal) y
## `controles` (antidopaje). El caso más sangrante: al abrir un caso, el propio
## motor emite la noticia "Puedes apelar desde Federación" -una pantalla que no
## existía-. Le prometía al jugador algo que no podía cumplir.
## EL HISTORIAL DE LA FEDERACIÓN: cómo has votado y cómo te tratan los árbitros.
## `Federacion` guardaba las dos cosas desde el porte —`votos` y
## `enojo_arbitral`— y no se veían por ningún lado, así que el jugador no podía
## saber por qué le pitaban cada vez peor.
func _pintar_historial_federacion(f: Federacion) -> void:
	p._lista_fed.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "RELACIÓN CON EL ARBITRAJE"
	p._lista_fed.add_child(t)
	## El enojo arbitral sube cada vez que apelas y pierdes, y baja la
	## probabilidad de que te acojan la siguiente. Es un coste ACUMULADO y
	## escondido: verlo es lo que hace que apelar sea una decisión y no un botón.
	var e := f.enojo_arbitral
	p._dato("Apelaciones perdidas acumuladas", str(e),
		Principal.COL_ROJO if e >= 3 else (Principal.COL_ORO if e > 0 else Principal.COL_VERDE), p._lista_fed)
	var frase := p._texto(11, Principal.COL_SUAVE)
	if e == 0:
		frase.text = "El tribunal no tiene nada anotado contra el club. Las apelaciones salen a precio normal."
	elif e < 3:
		frase.text = "Ya han quedado constancias de que el club recurre. Cada apelación nueva es un poco más difícil."
	else:
		frase.text = "El tribunal considera que el club abusa del recurso: apelar ahora sale muy caro y casi nunca prospera."
	frase.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_fed.add_child(frase)
	p._dato("Peso político en la asamblea", str(f.aliados),
		Principal.COL_VERDE if f.aliados > 0 else (Principal.COL_ROJO if f.aliados < 0 else Principal.COL_SUAVE), p._lista_fed)

	if f.votos.is_empty():
		return
	p._lista_fed.add_child(HSeparator.new())
	var tv := p._texto(11, Principal.COL_SUAVE)
	tv.text = "HISTORIAL DE VOTACIONES"
	p._lista_fed.add_child(tv)
	for i in mini(8, f.votos.size()):
		var v: Dictionary = f.votos[i]
		var paso := bool(v.get("pasa", false))
		var vote_a := bool(v.get("vote_a", false))
		## Lo interesante no es si la moción pasó, sino si TÚ estabas del lado
		## que ganó: eso es lo que mide tu peso real en la liga.
		var acerte := paso == vote_a
		p._dato(String(v.get("t", "")),
			"%s  ·  %s" % ["aprobada" if paso else "rechazada", "votaste a favor" if vote_a else "votaste en contra"],
			Principal.COL_VERDE if acerte else Principal.COL_SUAVE, p._lista_fed)

func _pintar_licencia_y_tribunal(c: Club, f: Federacion) -> void:
	var col_lic := Principal.COL_VERDE
	if f.licencia == "condicional":
		col_lic = Principal.COL_ORO
	elif f.licencia == "denegada":
		col_lic = Principal.COL_ROJO
	var tl := p._texto(11, Principal.COL_SUAVE)
	tl.text = "LICENCIA DE CLUB"
	p._lista_fed.add_child(tl)
	var est := p._texto(14, col_lic)
	est.text = f.licencia.to_upper()
	p._lista_fed.add_child(est)
	var cumple := 0
	var reqs := f.requisitos_licencia(c, p.mundo.obras)
	for r: Dictionary in reqs:
		var ok := bool(r["ok"])
		if ok:
			cumple += 1
		p._dato("%s  %s" % ["✅" if ok else "❌", String(r["t"])], String(r["det"]),
			Principal.COL_VERDE if ok else Principal.COL_ROJO, p._lista_fed)
	var resumen := p._texto(11, Principal.COL_SUAVE)
	resumen.text = "Cumples %d de %d requisitos. Uno o dos incumplimientos son un aviso y te dejan sin cupo internacional; tres o más, multa y licencia denegada." % [cumple, reqs.size()]
	resumen.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_fed.add_child(resumen)
	p._lista_fed.add_child(HSeparator.new())

	var tt := p._texto(11, Principal.COL_SUAVE)
	tt.text = "TRIBUNAL DE DISCIPLINA"
	p._lista_fed.add_child(tt)
	if f.casos.is_empty():
		var sin := p._texto(12, Principal.COL_SUAVE)
		sin.text = "Sin expedientes abiertos. Tampoco te has metido en líos."
		p._lista_fed.add_child(sin)
	else:
		for caso: Dictionary in f.casos:
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 8)
			p._lista_fed.add_child(fila)
			var firme := String(caso.get("estado", "firme")) == "firme"
			var l := p._texto(12, Principal.COL_TEXTO if firme else Principal.COL_SUAVE)
			l.text = "%s  ·  %s  ·  %d fecha(s)  ·  %s" % [
				String(caso.get("nombre", "?")), String(caso.get("motivo", "")),
				int(caso.get("fechas", 0)), String(caso.get("estado", ""))]
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila.add_child(l)
			## Apelar una vez por caso, como manda `apelar()`: el segundo intento
			## lo rechaza ella misma, pero un botón que no se puede pulsar dice
			## la verdad mejor que un mensaje de error.
			if firme and not bool(caso.get("apelado", false)):
				var id_caso := String(caso.get("id", ""))
				p._boton("Apelar", func() -> void: _apelar_caso(id_caso), fila)
	p._lista_fed.add_child(HSeparator.new())

	if not f.controles.is_empty():
		var tc := p._texto(11, Principal.COL_SUAVE)
		tc.text = "CONTROLES ANTIDOPAJE"
		p._lista_fed.add_child(tc)
		for i in mini(6, f.controles.size()):
			var ctrl: Dictionary = f.controles[f.controles.size() - 1 - i]
			var positivo := bool(ctrl.get("positivo", false))
			p._dato("%s  (S%d/%d)" % [String(ctrl.get("nombre", "?")), int(ctrl.get("semana", 0)), int(ctrl.get("anio", 0))],
				"POSITIVO" if positivo else "negativo", Principal.COL_ROJO if positivo else Principal.COL_VERDE, p._lista_fed)
		p._lista_fed.add_child(HSeparator.new())

func _bono_staff(c: Club) -> void:
	var liga := p._liga_de(c)
	var puesto := 1
	var tabla := liga.tabla()
	for fila: Dictionary in tabla:
		if fila["club"] == c:
			break
		puesto += 1
	var r := p.mundo.staff.repartir_bono(c, p.mundo.anio, puesto, tabla.size())
	if r.has("error"):
		p._escribir("[color=#e05555]No se pudo: %s.[/color]" % String(r["error"]))
	else:
		Sonido.toca("moneda")
		p._escribir("[color=#4caf6d][b]Bono al cuerpo técnico.[/b][/color] %s repartidos entre %d escalón(es) yendo %d.º: la moral del plantel sube %d puntos." % [
			p._dinero(int(r["coste"])), int(r["escalones"]), puesto, int(r["moral"])])
		p._anotar("Bono al cuerpo técnico.", "%s repartidos. La moral del plantel sube %d puntos." % [
			p._dinero(int(r["coste"])), int(r["moral"])])
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

func _renovar(j: Jugador, con_clausula: bool) -> void:
	var r := p.mundo.cantera.renovar(j, con_clausula)
	if r.has("error"):
		p._escribir("[color=#e05555]No se pudo renovar: %s.[/color]" % String(r["error"]))
	else:
		p._escribir("[color=#4caf6d]RENOVADO: %s.[/color] %d temporadas a %s/sem%s." % [
			j.nombre, int(r["anios"]), p._dinero(int(r["sueldo"])),
			" con cláusula de %s" % p._dinero(int(r["clausula"])) if con_clausula else ""])
		Sonido.toca("fichaje")
	p._refrescar()

func _apelar_caso(id_caso: String) -> void:
	var r := p.mundo.federacion.apelar(id_caso, p.mundo.mi_club(),
		p.mundo.roles.prestigio if p.mundo.roles != null else 50)
	p._escribir("[color=#c9a227][b]⚖️ Apelación.[/b][/color] %s" % r)
	p._anotar("⚖️ Apelación.", r)
	p._refrescar()

## C15: EL GOBIERNO DEL PAÍS. Partidos y personas inventados; la estructura
## del Estado y los plazos, reales.
func _pintar_gobierno(c: Club) -> void:
	if p.mundo.politica == null:
		return
	var g := p.mundo.politica.gobierno(c.pais, p.mundo.anio)
	var pos: Array = Politica.POSTURAS[String(g["postura"])]
	var l := p._texto(12, Principal.COL_TEXTO)
	var prox := int(g["proxima"])
	l.text = "🗳️ Gobierno de %s: %s (%s) · prioridad: %s%s" % [c.pais, String(g["lider"]), String(g["partido"]),
		String(pos[0]).to_lower(), (" · elecciones en %d" % prox) if prox > 0 else " · sin elecciones nacionales"]
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.tooltip_text = String(pos[1])
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	p._lista_fed.add_child(l)
	var b := Button.new()
	b.text = "🧑‍🏫 ¿Cómo funciona el Estado aquí?"
	b.add_theme_font_size_override("font_size", 13)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.pressed.connect(func() -> void:
		MentorVoz.decir(p, p.mundo, "Cómo se gobierna %s" % c.pais, Politica.explicacion(c.pais)))
	p._lista_fed.add_child(b)
	p._lista_fed.add_child(HSeparator.new())

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
	bdh.text = "🎪 Organizar un día del hincha  ·  %s" % p._dinero(coste_dh)
	bdh.disabled = c.saldo < coste_dh
	bdh.pressed.connect(func() -> void: p._ui_opciones._organizar_dia_hincha(c))
	p._lista_estadio.add_child(bdh)
	p._ui_opciones._pintar_penas_y_ramas(c, h)

	## La encuesta, si la hay. Va arriba porque es lo único que pide respuesta.
	if not h.encuesta.is_empty():
		var te := p._texto(11, Principal.COL_ORO)
		te.text = "📊 ENCUESTA A LOS SOCIOS"
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
	ts.text = "SEGMENTOS DE LA HINCHADA"
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
	ta.text = "ABONOS DE TEMPORADA  ·  la campaña se lanza sola al empezar cada año"
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
			ba.text = "Elegido" if elegido else "Elegir"
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
	lpd.text = "Precios dinámicos"
	lpd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lpd.tooltip_text = "Sube en los partidos grandes, baja en los flojos."
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
		epd.text = "Próximo partido en casa contra %s (rep %d): se cobraría %d en vez de %d." % [
			rival_pd.nombre, rival_pd.rep, hoy_pd, base_pd]
		epd.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_estadio.add_child(epd)

func _responder_encuesta(indice: int) -> void:
	var r := p.mundo.hinchada.responder_encuesta(indice)
	if r.has("error"):
		return
	var d_animo := int(r["animo"])
	if p.mundo.prensa != null:
		p.mundo.prensa.sumar_animo(d_animo)
	if bool(r["acerto"]):
		p._escribir("[color=#4caf6d][b]📊 Hiciste lo que pedía la mayoría.[/b][/color] El ánimo sube %d y los socios se sienten escuchados." % d_animo)
	else:
		p._escribir("[color=#e05555][b]📊 Fuiste por otro lado.[/b][/color] El ánimo baja %d: la gente había votado otra cosa." % absi(d_animo))
	p._refrescar()
