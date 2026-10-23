extends RefCounted
## (Parte 1 de 3 de `pantalla_cantera.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `pantalla_cantera.gd`, conserva la clase.)

## CANTERA Y CONTRATOS: selecciones, fondos, el mapa del talento, la cantera, las agencias, los contratos y el comparador.
##
## Sale de `ui/principal.gd` (mapa de metas 15: el archivo pasaba de
## 15.000 líneas). `p` es la pantalla principal: sus ayudantes (`p._texto`,
## `p._boton`...), el mundo (`p.mundo`) y el repintado (`p._refrescar()`).

var p: Principal

func _init(principal: Principal) -> void:
	p = principal

## LA SELECCIÓN: a quién te llevan, el escalafón mundial, y la nacionalización
## deportiva de tus extranjeros con residencia.
## EL MUNDIAL, EL MUNDIAL DE CLUBES Y LOS CAMPEONES CONTINENTALES, de
## `vSeleccion()`. `Selecciones` los guarda los tres desde el porte —los juega,
## los resuelve y los archiva— y no se veía ninguno: el Mundial de Clubes es el
## techo del juego, el sitio al que solo llegas ganando tu continente, y pasaba
## sin que quedara constancia en ninguna pantalla.
func _pintar_palmares_mundial(s: Selecciones) -> void:
	if not s.mundial.is_empty():
		p._lista_seleccion.add_child(HSeparator.new())
		var t := p._texto(11, Principal.COL_SUAVE)
		t.text = Idiomas.t("COPA DEL MUNDO")
		p._lista_seleccion.add_child(t)
		p._dato("Último campeón", "%s (%d)" % [String(s.mundial.get("campeon", "—")), int(s.mundial.get("anio", 0))],
			Principal.COL_ORO, p._lista_seleccion)

	if not s.mundial_clubes.is_empty():
		p._lista_seleccion.add_child(HSeparator.new())
		var t2 := p._texto(11, Principal.COL_SUAVE)
		t2.text = Idiomas.t("MUNDIAL DE CLUBES")
		p._lista_seleccion.add_child(t2)
		var mio := bool(s.mundial_clubes.get("mio", false))
		p._dato("Campeón", "%s (%d)" % [String(s.mundial_clubes.get("campeon", "—")), int(s.mundial_clubes.get("anio", 0))],
			Principal.COL_ORO if mio else Principal.COL_TEXTO, p._lista_seleccion)
		var relato := String(s.mundial_clubes.get("relato", ""))
		if relato != "":
			var r := p._texto(11, Principal.COL_ORO if mio else Principal.COL_SUAVE)
			r.text = relato
			r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_seleccion.add_child(r)

	if not s.campeones_continentales.is_empty():
		p._lista_seleccion.add_child(HSeparator.new())
		var t3 := p._texto(11, Principal.COL_SUAVE)
		t3.text = Idiomas.t("CAMPEONES CONTINENTALES")
		p._lista_seleccion.add_child(t3)
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = Idiomas.t("Son los que se clasifican al Mundial de Clubes del año siguiente.")
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_seleccion.add_child(ex)
		var mi_id := p.mundo.mi_club_id
		for f: Dictionary in s.campeones_continentales:
			var propio := String(f.get("club_id", "")) == mi_id
			p._dato("%s %d" % [String(f.get("torneo", "")), int(f.get("anio", 0))],
				String(f.get("campeon", "")), p.COL_ACENTO if propio else Principal.COL_TEXTO, p._lista_seleccion)

func _nacionalizar(j: Jugador) -> void:
	var problema := p.mundo.selecciones.nacionalizar(j)
	if problema != "":
		p._escribir("[color=#e05555]No se puede nacionalizar: %s.[/color]" % problema)
		return
	p._refrescar()

func _pintar_seleccion(c: Club) -> void:
	p._limpiar(p._lista_seleccion)
	var s := p.mundo.selecciones
	if s == null:
		return
	_pintar_palmares_mundial(s)
	var t := p._texto(13, Principal.COL_ORO)
	t.text = Idiomas.t("%s  ·  fuerza %d") % [s.nombre_seleccion(), s.fuerza(s.nombre_seleccion())]
	p._lista_seleccion.add_child(t)

	## Lo tuyo primero: la nómina si ya está cerrada, si no la prenómina, si no
	## nada. Es la misma jerarquía que usa el HTML -lo más cocinado manda.
	var mios_nomina := s.convocados().filter(func(j: Jugador) -> bool: return j.club_id == c.id)
	var mios_pre := s.prenominados().filter(func(j: Jugador) -> bool: return j.club_id == c.id)
	if not mios_nomina.is_empty():
		var l := p._texto(12, Principal.COL_VERDE)
		var nombres: Array[String] = []
		for j: Jugador in mios_nomina:
			nombres.append("%s (%d caps)" % [j.nombre, s.caps_de(j)])
		l.text = Idiomas.t("Convocados ahora: ") + ", ".join(nombres)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_seleccion.add_child(l)
	elif not mios_pre.is_empty():
		var l2 := p._texto(12, Principal.COL_ORO)
		var nombres2: Array[String] = []
		for j: Jugador in mios_pre:
			nombres2.append(j.nombre)
		l2.text = Idiomas.t("En la prenómina: ") + ", ".join(nombres2)
		l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_seleccion.add_child(l2)
	else:
		var vacio := p._texto(12, Principal.COL_SUAVE)
		vacio.text = Idiomas.t("Nadie de tu club convocado en este momento.")
		p._lista_seleccion.add_child(vacio)


	## PEDIR QUE NO SE LO LLEVEN. `Selecciones.pedir_descanso()` estaba escrita
	## desde el porte y no tenía un solo botón: la única defensa del club contra
	## una convocatoria que te devuelve al jugador reventado no existía.
	##
	## Se pide por los CONVOCADOS y por los prenominados: cuando ya viajó es
	## tarde, y cuando todavía no está en ninguna lista no hay nada que pedir.
	var pedibles: Array[Jugador] = []
	for j: Jugador in mios_nomina:
		pedibles.append(j)
	for j2: Jugador in mios_pre:
		if not pedibles.has(j2):
			pedibles.append(j2)
	if not pedibles.is_empty():
		var td := p._texto(11, Principal.COL_SUAVE)
		td.text = Idiomas.t("PEDIR DESCANSO")
		p._lista_seleccion.add_child(td)
		if not p._modo_experto:
			var ed := p._texto(10, Principal.COL_SUAVE)
			ed.text = Idiomas.t("Le pides a la federación que no se lo lleve. No siempre te hacen caso, y al jugador no le suele gustar que decidas por él.")
			ed.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_seleccion.add_child(ed)
		for jd: Jugador in pedibles:
			var quien := jd
			var pedido := s.pidio_descanso(jd)
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 6)
			p._lista_seleccion.add_child(fila)
			var n := p._texto(12, Principal.COL_ORO if pedido else Principal.COL_TEXTO)
			var nac := s.nacionalidad_deportiva(jd)
			n.text = "%s  ·  %s%s" % [jd.nombre, jd.pais,
				Idiomas.t("  (nacionalizado %s)") % nac if nac != "" else ""]
			n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			n.clip_text = true
			fila.add_child(n)
			var b := Button.new()
			b.text = Idiomas.t("Pedido") if pedido else Idiomas.t("Pedir descanso")
			b.add_theme_font_size_override("font_size", 11)
			b.disabled = pedido
			b.custom_minimum_size = Vector2(120, 0)
			b.pressed.connect(func() -> void:
				var problema := s.pedir_descanso(quien)
				if problema != "":
					p._escribir("[color=#e05555]No se pudo pedir: %s.[/color]" % problema)
				else:
					p._escribir("[color=#c9a227]Pedido presentado por %s.[/color] La federación decidirá; no siempre hacen caso." % quien.nombre)
				p._refrescar())
			fila.add_child(b)
	if not s.resultados.is_empty():
		p._lista_seleccion.add_child(HSeparator.new())
		var tr := p._texto(11, Principal.COL_SUAVE)
		tr.text = Idiomas.t("ÚLTIMOS RESULTADOS")
		p._lista_seleccion.add_child(tr)
		for linea: String in s.resultados:
			var lr := p._texto(12, Principal.COL_TEXTO)
			lr.text = linea
			p._lista_seleccion.add_child(lr)

	## La nacionalización: solo si hay algún candidato, para no ensuciar la
	## pantalla con una sección vacía la primera temporada.
	var candidatos := s.candidatos_a_nacionalizar()
	if not candidatos.is_empty():
		p._lista_seleccion.add_child(HSeparator.new())
		var tn := p._texto(11, Principal.COL_SUAVE)
		tn.text = Idiomas.t("NACIONALIZACIÓN DEPORTIVA")
		p._lista_seleccion.add_child(tn)
		for fila: Dictionary in candidatos:
			var j: Jugador = fila["jugador"]
			var fila_h := HBoxContainer.new()
			fila_h.add_theme_constant_override("separation", 8)
			p._lista_seleccion.add_child(fila_h)
			var nom := p._texto(12, Principal.COL_TEXTO)
			nom.text = Idiomas.t("%s  ·  %d temporadas en el país") % [j.nombre, int(fila["temporadas"])]
			nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila_h.add_child(nom)
			var costo := s.costo_nacionalizacion(j)
			var b := Button.new()
			b.text = Idiomas.t("Nacionalizar  %s") % p._dinero(costo)
			b.add_theme_font_size_override("font_size", 11)
			b.disabled = costo > c.saldo
			b.pressed.connect(func() -> void: _nacionalizar(j))
			fila_h.add_child(b)

	p._lista_seleccion.add_child(HSeparator.new())
	var tm := p._texto(11, Principal.COL_SUAVE)
	tm.text = Idiomas.t("MÁS INTERNACIONALES DEL MUNDO")
	p._lista_seleccion.add_child(tm)
	for fila2: Dictionary in s.mas_convocados(8):
		var j2: Jugador = fila2["jugador"]
		var col := p.COL_ACENTO if j2.club_id == c.id else Principal.COL_TEXTO
		var lm := p._texto(12, col)
		lm.text = Idiomas.t("%s  ·  %d caps") % [j2.nombre, int(fila2["caps"])]
		p._lista_seleccion.add_child(lm)

	p._lista_seleccion.add_child(HSeparator.new())
	var te := p._texto(11, Principal.COL_SUAVE)
	te.text = Idiomas.t("ESCALAFÓN MUNDIAL")
	p._lista_seleccion.add_child(te)
	for fila3: Dictionary in s.ranking(14):
		var propia := String(fila3["nombre"]) == s.nombre_seleccion()
		var le := p._texto(12, p.COL_ACENTO if propia else Principal.COL_SUAVE)
		le.text = "%s%s  ·  %d" % ["> " if propia else "   ", String(fila3["nombre"]), int(fila3["fuerza"])]
		p._lista_seleccion.add_child(le)

## LA CANTERA: las categorías inferiores, quién está listo para debutar, y las
## becas que evitan que un grande se lleve gratis a un chico sin ficha profesional.
## `vLinaje()` del HTML: las dinastías del club. `Cantera.familias()` lleva
## tiempo agrupando hijos de leyenda y parejas de hermanos, y su propio
## comentario dice que existe "para poder enseñarlas juntas en una pantalla" —
## una pantalla que no se había hecho. Las dinastías se construían solas y no se
## veían: el hijo de tu viejo capitán era un canterano más de la lista.
## FONDOS DE INVERSIÓN. Dinero hoy a cambio de un porcentaje del traspaso de un
## canterano mañana.
##
## Es la palanca más peligrosa del juego y por eso está aquí, en Cantera, al
## lado de los chicos: la cifra que ofrecen es tentadora justo cuando peor estás
## de caja, que es exactamente cuando peor se decide. Y a partir de que firmas,
## el fondo tiene voz: aparece cada tanto pidiendo que lo vendas.
func _pintar_fondos(c: Club) -> void:
	var ce := p.mundo.cesiones
	if ce == null:
		return
	p._lista_cantera.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("💸 FONDOS DE INVERSIÓN")
	p._lista_cantera.add_child(t)
	if not p._modo_experto:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = Idiomas.t("Compran un porcentaje del PRÓXIMO traspaso de un chico y te lo pagan hoy. Pagan por debajo de lo que vale porque asumen el riesgo, y el día que lo vendas ese porcentaje ya no es tuyo. Como mucho el %d%% de cada jugador.") % Cesiones.PCT_MAX
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_cantera.add_child(ex)

	var jovenes: Array[Jugador] = []
	for j: Jugador in c.plantilla:
		if j.edad <= 23:
			jovenes.append(j)
	jovenes.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.valor > b.valor)
	if jovenes.is_empty():
		var vac := p._texto(10, Principal.COL_SUAVE)
		vac.text = Idiomas.t("No tienes ningún futbolista de 23 años o menos: los fondos solo compran derechos de jóvenes.")
		vac.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_cantera.add_child(vac)
		return

	for i in mini(6, jovenes.size()):
		var j2: Jugador = jovenes[i]
		var vendido := ce.participacion_de(j2)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_cantera.add_child(fila)
		var n := p._texto(12, Principal.COL_ORO if vendido > 0 else Principal.COL_TEXTO)
		n.text = Idiomas.t("%s  ·  %d años  ·  %s") % [j2.nombre, j2.edad, p._dinero(j2.valor)]
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		fila.add_child(n)
		if vendido > 0:
			var v := p._texto(11, Principal.COL_ROJO)
			v.text = Idiomas.t("%d%% vendido") % vendido
			v.custom_minimum_size = Vector2(90, 0)
			fila.add_child(v)
		if vendido >= Cesiones.PCT_MAX:
			continue
		## Un solo tramo del 25%: si se pudiera elegir el porcentaje al punto, la
		## decisión se convertiría en un cálculo y no en una apuesta.
		for f: Array in Cesiones.FONDOS:
			var clave := String(f[0])
			var b := Button.new()
			b.text = "%s  %s" % [String(f[1]).split(" ")[0], p._dinero(ce.oferta_de_fondo(j2, clave, 25))]
			b.add_theme_font_size_override("font_size", 10)
			b.clip_text = true
			b.tooltip_text = Idiomas.t("%s  ·  vende el 25%% del próximo traspaso de %s") % [String(f[3]), j2.nombre]
			b.custom_minimum_size = Vector2(120, 0)
			b.pressed.connect(func() -> void:
				var p_local := ce.vender_participacion(j2, clave, 25, p.mundo.mi_club())
				if p_local != "":
					p._escribir("[color=#e05555]No se pudo: %s.[/color]" % p_local)
				p._refrescar())
			fila.add_child(b)

## `vLinajeExtra()`: EL MAPA DEL TALENTO. Qué países atraviesan una época dorada
## y cuáles una decadencia.
##
## Es la única pantalla del juego que dice DÓNDE hay que estar, y tiene fecha de
## caducidad escrita: una época dura entre cuatro y nueve años y después se
## apaga. Sin esto, el mundo es plano y poner ojeadores en un país o en otro solo
## cambia lo que cuesta el billete.
func _pintar_mapa_del_talento() -> void:
	if p.mundo.eras == null:
		return
	var mapa := p.mundo.eras.mapa_del_talento(p.mundo.anio)
	p._lista_cantera.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("🌍 EL MAPA DEL TALENTO")
	p._lista_cantera.add_child(t)
	if mapa.is_empty():
		var vac := p._texto(11, Principal.COL_SUAVE)
		vac.text = Idiomas.t("Ningún país atraviesa hoy una época marcada. Las generaciones irrepetibles aparecen solas, cada varios años, y duran lo que duran.")
		vac.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_cantera.add_child(vac)
		return
	for e: Dictionary in mapa:
		var dorada := bool(e["dorada"])
		var n := p._texto(12, Principal.COL_ORO if dorada else Principal.COL_ROJO)
		n.text = "%s %s  ·  %s" % ["✨" if dorada else "🥀", String(e["pais"]),
			Idiomas.t("Época dorada") if dorada else Idiomas.t("Decadencia")]
		p._lista_cantera.add_child(n)
		var d := p._texto(10, Principal.COL_SUAVE)
		d.text = (Idiomas.t("%d–%d (queda %d año)  ·  %s  %s") if int(e["quedan"]) == 1 else Idiomas.t("%d–%d (quedan %d años)  ·  %s  %s")) % [
			int(e["desde"]), int(e["hasta"]), int(e["quedan"]),
			String(e["texto"]), String(e["consejo"])]
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_cantera.add_child(d)

func _pintar_linaje(c: Club) -> void:
	_pintar_fondos(c)
	_pintar_mapa_del_talento()
	if p.mundo.cantera == null:
		return
	var fams := p.mundo.cantera.familias()
	## Solo las de TU club: las de los otros 383 son ruido.
	var mias := {}
	for clave: String in fams:
		var miembros: Array = fams[clave]
		var aqui: Array[Jugador] = []
		for j: Jugador in miembros:
			if j.club_id == c.id:
				aqui.append(j)
		if not aqui.is_empty():
			mias[clave] = aqui
	if mias.is_empty():
		return
	p._lista_cantera.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("ÁRBOL GENEALÓGICO  ·  %d familia(s) en el plantel") % mias.size()
	p._lista_cantera.add_child(t)
	for clave: String in mias:
		var titulo := ""
		if clave.begins_with("L:"):
			titulo = "⭐ Estirpe de %s" % Nombres.visible(clave.substr(2))
		else:
			var primero: Jugador = (mias[clave] as Array)[0]
			var partes := primero.nombre.split(" ")
			titulo = "👨‍👦 Hermanos %s" % Nombres.visible(partes[partes.size() - 1])
		var lt := p._texto(12, Principal.COL_ORO)
		lt.text = titulo
		p._lista_cantera.add_child(lt)
		for j: Jugador in mias[clave]:
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 8)
			p._lista_cantera.add_child(fila)
			fila.add_child(p._retrato(j, 24))
			var b := Button.new()
			b.text = j.nombre
			b.flat = true
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.add_theme_font_size_override("font_size", 12)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.pressed.connect(func() -> void: p._ver_ficha(j))
			fila.add_child(b)
			var d := p._texto(11, Principal.COL_SUAVE)
			d.text = Idiomas.t("%d años  ·  %s  ·  media %d") % [j.edad, j.pos_e, j.ovr]
			fila.add_child(d)
			## EL APELLIDO QUE PESA. `Cantera` le cuelga una etiqueta al hijo de
			## una leyenda y cada semana mide si está a la altura: si rinde lo
			## bendicen, si no lo entierran. Todo eso corría sin que se viera
			## nada, así que la presión existía y el jugador no sabía por qué al
			## chico se le hundía la moral.
			var et: Dictionary = p.mundo.cantera.etiqueta_de(j)
			if not et.is_empty():
				var presion := int(et.get("presion", 0))
				var e2 := p._texto(11, Principal.COL_ROJO if presion >= 4 else (Principal.COL_VERDE if int(et.get("cumple", 0)) >= 4 else Principal.COL_SUAVE))
				e2.text = Idiomas.t("«el nuevo %s»  ·  presión %d/6") % [String(et.get("ref", "—")), presion]
				e2.tooltip_text = Idiomas.t("La prensa lo compara con su padre en cada partido. A las seis semanas malas le pasa factura; a los ocho aciertos se lo quitan de encima para siempre.")
				fila.add_child(e2)

func _becar(j: Jugador) -> void:
	var problema := p.mundo.cantera.becar(j)
	if problema != "":
		p._escribir("[color=#e05555]No se puede becar: %s.[/color]" % problema)
		return
	p._escribir("[color=#4caf6d]%s tiene beca.[/color] Menos riesgo de que se lo lleven gratis." % j.nombre)
	p._refrescar()

func _fila_canterano(j: Jugador, ct: Cantera, c: Club) -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	fila.add_child(p._retrato(j, 24))
	var listo := ct.listo_para_debutar(j)
	var nom := p._texto(12, Principal.COL_VERDE if listo else Principal.COL_TEXTO)
	var linaje: Dictionary = ct.linaje_de(j)
	var etiqueta := (" · hijo de %s" % String(linaje.get("padre", ""))) if not linaje.is_empty() else ""
	nom.text = Idiomas.t("%s  ·  %d años  ·  %d/%d%s") % [j.nombre, j.edad, j.ovr, j.pot, etiqueta]
	nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fila.add_child(nom)
	## EL RIESGO DE FUGA. `riesgo_fuga()` corría desde el principio -se resuelve
	## solo en el pulso semanal de la cantera- pero no se veía en ninguna parte,
	## y sin verlo la beca es un gasto sin motivo: lo que la justifica es
	## exactamente este número, que baja dos puntos al becar. Cuanto mejor es el
	## chico (más `pot` sobre `ovr`), más se lo quieren llevar.
	## DE DÓNDE SALIÓ. `Cantera.origen_de()` estaba escrita, el dato se sorteaba
	## y se guardaba en la ficha de cada chico… y no la llamaba NADIE, ni
	## siquiera dentro del propio núcleo. Es una línea de historia por canterano
	## -de un potrero, de un colegio, del hijo del utilero- que existía y no se
	## leía en ninguna parte.
	var org: Dictionary = ct.origen_de(j)
	if not org.is_empty():
		var o := p._texto(11, Principal.COL_SUAVE)
		o.text = "%s %s" % [String(org.get("icono", "")), String(org.get("frase", ""))]
		o.tooltip_text = String(org.get("historia", ""))
		o.custom_minimum_size = Vector2(150, 0)
		o.clip_text = true
		fila.add_child(o)
	var fuga := ct.riesgo_fuga(j)
	if fuga > 0.0:
		var rf := p._texto(11, Principal.COL_ROJO if fuga >= 0.05 else Principal.COL_SUAVE)
		rf.text = Idiomas.t("fuga %.1f%%") % (fuga * 100.0)
		rf.tooltip_text = Idiomas.t("Probabilidad de que se lo lleve otro club esta semana. La beca la baja, y las instalaciones de cantera también.")
		rf.custom_minimum_size = Vector2(64, 0)
		fila.add_child(rf)
	if ct.tiene_beca(j):
		var tag := p._texto(11, Principal.COL_VERDE)
		tag.text = Idiomas.t("becado")
		fila.add_child(tag)
	else:
		var costo := ct.coste_beca()
		var b := Button.new()
		b.text = Idiomas.t("Becar  %s") % p._dinero(costo)
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = costo > c.saldo
		b.pressed.connect(func() -> void: _becar(j))
		fila.add_child(b)
	return fila
