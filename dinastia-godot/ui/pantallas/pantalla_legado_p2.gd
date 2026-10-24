extends "res://ui/pantallas/pantalla_legado_p1.gd"
## [Capa 2/3 de `pantalla_legado.gd`] _pintar_sucesion, _retirarse, _pintar_fin_de_carrera, _pintar_epilogo, _pintar_legado, _pintar_vida … (+4)

## LA SUCESIÓN. A quién le dejas el club. No cambia tu partida —ya se acabó— y
## por eso importa: es lo único que solo sirve para decidir cómo quieres que se
## recuerde lo que hiciste.
func _pintar_sucesion(r: Roles) -> void:
	if r.retirado.is_empty():
		return
	p._lista_legado.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("🪑 LA SUCESIÓN")
	p._lista_legado.add_child(t)
	if not r.sucesor.is_empty():
		var n := p._texto(13, Principal.COL_ORO)
		n.text = String(r.sucesor.get("nombre", ""))
		p._lista_legado.add_child(n)
		var d := p._texto(11, Principal.COL_SUAVE)
		d.text = Idiomas.t("%s El directorio le da un margen de %d partidos.") % [
			String(r.sucesor.get("desc", "")), int(r.sucesor.get("margen", 0))]
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_legado.add_child(d)
		return
	var ex := p._texto(10, Principal.COL_SUAVE)
	ex.text = Idiomas.t("Te retiraste. Lo último que decides es a quién le dejas el banquillo.")
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
		l.text = Idiomas.t("%s  ·  margen %d partidos") % [String(cand["nombre"]), int(cand["margen"])]
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.clip_text = true
		l.tooltip_text = String(cand["desc"])
		fila.add_child(l)
		var b := Button.new()
		b.text = Idiomas.t("Elegir")
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

func _pintar_fin_de_carrera(r: Roles) -> void:
	var tf := p._texto(11, Principal.COL_SUAVE)
	tf.text = Idiomas.t("🏁 FIN DE CARRERA")
	p._lista_legado.add_child(tf)
	if not r.retirado.is_empty():
		var ya := p._texto(12, Principal.COL_ORO)
		ya.text = Idiomas.t("Te retiraste en %d con %d título(s) y %s puntos.") % [
			int(r.retirado.get("anio", 0)), r.trofeos.size(), p._miles(int(r.retirado.get("puntaje", 0)))]
		ya.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_legado.add_child(ya)
	else:
		var av := p._texto(11, Principal.COL_SUAVE)
		av.text = Idiomas.t("Cuando quieras cerrar la historia, puedes anunciar tu retirada y ver el balance completo de tu carrera. No se puede deshacer.")
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
	te.text = Idiomas.t("📖 TU CARRERA HASTA AQUÍ")
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

func _pintar_legado() -> void:
	p._limpiar(p._lista_legado)
	var r := p.mundo.roles
	if r == null:
		return
	var p_local: Dictionary = p.mundo.puntaje_carrera()

	## C4: LA HISTORIA DEL CLUB, antes que la tuya.
	var hi := p._ui_plantel._historia_de(p.mundo.mi_club())
	var th := p._texto(11, Principal.COL_SUAVE)
	th.text = Idiomas.t("HISTORIA DEL CLUB")
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
	t.text = Idiomas.t("TU LEGADO")
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
		fi.text = Idiomas.t("📚 Tu escuela táctica: %s  (%s)") % [String(r.filosofia["nombre"]), String(r.filosofia.get("formacion", ""))]
		fi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_legado.add_child(fi)
	p._lista_legado.add_child(HSeparator.new())

	var tp := p._texto(11, Principal.COL_SUAVE)
	tp.text = Idiomas.t("PALMARÉS POR COMPETICIÓN")
	p._lista_legado.add_child(tp)
	var palmares := r.palmares_por_tipo()
	if palmares.is_empty():
		var vac := p._texto(12, Principal.COL_SUAVE)
		vac.text = Idiomas.t("Sin títulos todavía.")
		p._lista_legado.add_child(vac)
	else:
		for f: Dictionary in palmares:
			p._dato("🏆 %s" % String(f["titulo"]), "×%d" % int(f["veces"]), Principal.COL_ORO, p._lista_legado)
	p._lista_legado.add_child(HSeparator.new())

	var tc := p._texto(11, Principal.COL_SUAVE)
	tc.text = Idiomas.t("📈 CARRERA PROFESIONAL")
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
		to.text = Idiomas.t("☎️ TE QUIEREN EN OTRO CLUB")
		p._lista_legado.add_child(to)
		var no := p._texto(13, Principal.COL_ORO)
		no.text = String(r.oferta_de_club["nombre"])
		p._lista_legado.add_child(no)
		p._dato("Salto de categoría", "+%d de reputación" % int(r.oferta_de_club["mejora"]),
			Principal.COL_VERDE, p._lista_legado)
		p._dato("Tu sueldo allí", "%s / semana" % p._dinero(int(r.oferta_de_club["sueldo"])),
			Principal.COL_ORO, p._lista_legado)
		var eo := p._texto(10, Principal.COL_SUAVE)
		eo.text = Idiomas.t("Aceptar cierra tu capítulo aquí y abre otro: el currículum se lo lleva todo. Rechazar sube la confianza de esta directiva, que se entera igual.")
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

## El ÁRBOL DE CARRERA DEL ENTRENADOR de `vCarrera()`: cinco ramas, un punto
## cada diez semanas, y nodos encadenados por requisito. Otro sistema entero
## escrito, probado y sin una sola llamada desde la interfaz —los puntos se
## acumulaban solos temporada tras temporada sin que hubiera dónde gastarlos.
##
## Va en Legado y no en el Club porque es de la CARRERA: como el prestigio y la
## vitrina, te sigue cuando cambias de banquillo.
## MI VIDA (26-9-2026).
func _pintar_vida() -> void:
	if p._lista_vida == null:
		return
	PanelVida.pintar(p._lista_vida, p, p.mundo, p._secc_vida)

## EL ÁRBOL DE HABILIDADES, COMO ESQUEMA (26-9-2026): columnas por rama, nodos
## y líneas de requisito, y la ficha de la elegida debajo.
func _pintar_habilidades() -> void:
	if p._lista_habilidades == null:
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
	grande.text = Idiomas.t("⛶ En grande")
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

## El mensaje de éxito lo escribe `entrenamiento.noticia`, ya conectada; aquí
## solo se saca el motivo cuando falla.
func _aprender_dt(clave: String) -> void:
	var problema := p.mundo.entrenamiento.dt_aprender(clave)
	if problema != "":
		p._escribir("[color=#e05555]No puedes aprender eso: %s.[/color]" % problema)
	p._refrescar()

func _pintar_arbol_dt() -> void:
	var e := p.mundo.entrenamiento
	if e == null:
		return
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("🎓 TUS HABILIDADES DE ENTRENADOR")
	p._lista_legado.add_child(t)
	var pts := p._texto(14, Principal.COL_ORO if e.dt_puntos > 0 else Principal.COL_SUAVE)
	pts.text = Idiomas.t("%d punto(s) por gastar  ·  se gana uno cada %d semanas") % [
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
			b.text = Idiomas.t("%d pto(s)") % e.dt_coste(clave) if motivo == "" else motivo
			b.add_theme_font_size_override("font_size", 10)
			b.disabled = motivo != ""
			b.custom_minimum_size = Vector2(140, 0)
			var k := clave
			b.pressed.connect(func() -> void: _aprender_dt(k))
			fila.add_child(b)
	p._lista_legado.add_child(HSeparator.new())

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
