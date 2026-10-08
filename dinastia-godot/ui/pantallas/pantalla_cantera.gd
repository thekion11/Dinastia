class_name PantallaCantera
extends RefCounted
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
		t.text = "COPA DEL MUNDO"
		p._lista_seleccion.add_child(t)
		p._dato("Último campeón", "%s (%d)" % [String(s.mundial.get("campeon", "—")), int(s.mundial.get("anio", 0))],
			Principal.COL_ORO, p._lista_seleccion)

	if not s.mundial_clubes.is_empty():
		p._lista_seleccion.add_child(HSeparator.new())
		var t2 := p._texto(11, Principal.COL_SUAVE)
		t2.text = "MUNDIAL DE CLUBES"
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
		t3.text = "CAMPEONES CONTINENTALES"
		p._lista_seleccion.add_child(t3)
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = "Son los que se clasifican al Mundial de Clubes del año siguiente."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_seleccion.add_child(ex)
		var mi_id := p.mundo.mi_club_id
		for f: Dictionary in s.campeones_continentales:
			var propio := String(f.get("club_id", "")) == mi_id
			p._dato("%s %d" % [String(f.get("torneo", "")), int(f.get("anio", 0))],
				String(f.get("campeon", "")), p.COL_ACENTO if propio else Principal.COL_TEXTO, p._lista_seleccion)

func _pintar_seleccion(c: Club) -> void:
	p._limpiar(p._lista_seleccion)
	var s := p.mundo.selecciones
	if s == null:
		return
	_pintar_palmares_mundial(s)
	var t := p._texto(13, Principal.COL_ORO)
	t.text = "%s  ·  fuerza %d" % [s.nombre_seleccion(), s.fuerza(s.nombre_seleccion())]
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
		l.text = "Convocados ahora: " + ", ".join(nombres)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_seleccion.add_child(l)
	elif not mios_pre.is_empty():
		var l2 := p._texto(12, Principal.COL_ORO)
		var nombres2: Array[String] = []
		for j: Jugador in mios_pre:
			nombres2.append(j.nombre)
		l2.text = "En la prenómina: " + ", ".join(nombres2)
		l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_seleccion.add_child(l2)
	else:
		var vacio := p._texto(12, Principal.COL_SUAVE)
		vacio.text = "Nadie de tu club convocado en este momento."
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
		td.text = "PEDIR DESCANSO"
		p._lista_seleccion.add_child(td)
		if not p._modo_experto:
			var ed := p._texto(10, Principal.COL_SUAVE)
			ed.text = "Le pides a la federación que no se lo lleve. No siempre te hacen caso, y al jugador no le suele gustar que decidas por él."
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
				"  (nacionalizado %s)" % nac if nac != "" else ""]
			n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			n.clip_text = true
			fila.add_child(n)
			var b := Button.new()
			b.text = "Pedido" if pedido else "Pedir descanso"
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
		tr.text = "ÚLTIMOS RESULTADOS"
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
		tn.text = "NACIONALIZACIÓN DEPORTIVA"
		p._lista_seleccion.add_child(tn)
		for fila: Dictionary in candidatos:
			var j: Jugador = fila["jugador"]
			var fila_h := HBoxContainer.new()
			fila_h.add_theme_constant_override("separation", 8)
			p._lista_seleccion.add_child(fila_h)
			var nom := p._texto(12, Principal.COL_TEXTO)
			nom.text = "%s  ·  %d temporadas en el país" % [j.nombre, int(fila["temporadas"])]
			nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila_h.add_child(nom)
			var costo := s.costo_nacionalizacion(j)
			var b := Button.new()
			b.text = "Nacionalizar  %s" % p._dinero(costo)
			b.add_theme_font_size_override("font_size", 11)
			b.disabled = costo > c.saldo
			b.pressed.connect(func() -> void: _nacionalizar(j))
			fila_h.add_child(b)

	p._lista_seleccion.add_child(HSeparator.new())
	var tm := p._texto(11, Principal.COL_SUAVE)
	tm.text = "MÁS INTERNACIONALES DEL MUNDO"
	p._lista_seleccion.add_child(tm)
	for fila2: Dictionary in s.mas_convocados(8):
		var j2: Jugador = fila2["jugador"]
		var col := p.COL_ACENTO if j2.club_id == c.id else Principal.COL_TEXTO
		var lm := p._texto(12, col)
		lm.text = "%s  ·  %d caps" % [j2.nombre, int(fila2["caps"])]
		p._lista_seleccion.add_child(lm)

	p._lista_seleccion.add_child(HSeparator.new())
	var te := p._texto(11, Principal.COL_SUAVE)
	te.text = "ESCALAFÓN MUNDIAL"
	p._lista_seleccion.add_child(te)
	for fila3: Dictionary in s.ranking(14):
		var propia := String(fila3["nombre"]) == s.nombre_seleccion()
		var le := p._texto(12, p.COL_ACENTO if propia else Principal.COL_SUAVE)
		le.text = "%s%s  ·  %d" % ["> " if propia else "   ", String(fila3["nombre"]), int(fila3["fuerza"])]
		p._lista_seleccion.add_child(le)

func _nacionalizar(j: Jugador) -> void:
	var problema := p.mundo.selecciones.nacionalizar(j)
	if problema != "":
		p._escribir("[color=#e05555]No se puede nacionalizar: %s.[/color]" % problema)
		return
	p._refrescar()

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
	t.text = "💸 FONDOS DE INVERSIÓN"
	p._lista_cantera.add_child(t)
	if not p._modo_experto:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = "Compran un porcentaje del PRÓXIMO traspaso de un chico y te lo pagan hoy. Pagan por debajo de lo que vale porque asumen el riesgo, y el día que lo vendas ese porcentaje ya no es tuyo. Como mucho el %d%% de cada jugador." % Cesiones.PCT_MAX
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_cantera.add_child(ex)

	var jovenes: Array[Jugador] = []
	for j: Jugador in c.plantilla:
		if j.edad <= 23:
			jovenes.append(j)
	jovenes.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.valor > b.valor)
	if jovenes.is_empty():
		var vac := p._texto(10, Principal.COL_SUAVE)
		vac.text = "No tienes ningún futbolista de 23 años o menos: los fondos solo compran derechos de jóvenes."
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
		n.text = "%s  ·  %d años  ·  %s" % [j2.nombre, j2.edad, p._dinero(j2.valor)]
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		fila.add_child(n)
		if vendido > 0:
			var v := p._texto(11, Principal.COL_ROJO)
			v.text = "%d%% vendido" % vendido
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
			b.tooltip_text = "%s  ·  vende el 25%% del próximo traspaso de %s" % [String(f[3]), j2.nombre]
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
	t.text = "🌍 EL MAPA DEL TALENTO"
	p._lista_cantera.add_child(t)
	if mapa.is_empty():
		var vac := p._texto(11, Principal.COL_SUAVE)
		vac.text = "Ningún país atraviesa hoy una época marcada. Las generaciones irrepetibles aparecen solas, cada varios años, y duran lo que duran."
		vac.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_cantera.add_child(vac)
		return
	for e: Dictionary in mapa:
		var dorada := bool(e["dorada"])
		var n := p._texto(12, Principal.COL_ORO if dorada else Principal.COL_ROJO)
		n.text = "%s %s  ·  %s" % ["✨" if dorada else "🥀", String(e["pais"]),
			"Época dorada" if dorada else "Decadencia"]
		p._lista_cantera.add_child(n)
		var d := p._texto(10, Principal.COL_SUAVE)
		d.text = "%d–%d (quedan %d año%s)  ·  %s  %s" % [
			int(e["desde"]), int(e["hasta"]), int(e["quedan"]),
			"" if int(e["quedan"]) == 1 else "s",
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
	t.text = "ÁRBOL GENEALÓGICO  ·  %d familia(s) en el plantel" % mias.size()
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
			d.text = "%d años  ·  %s  ·  media %d" % [j.edad, j.pos_e, j.ovr]
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
				e2.text = "«el nuevo %s»  ·  presión %d/6" % [String(et.get("ref", "—")), presion]
				e2.tooltip_text = "La prensa lo compara con su padre en cada partido. A las seis semanas malas le pasa factura; a los ocho aciertos se lo quitan de encima para siempre."
				fila.add_child(e2)

func _pintar_cantera(c: Club) -> void:
	p._limpiar(p._lista_cantera)
	var ct := p.mundo.cantera
	if ct == null:
		return
	## LA ACADEMIA (10-16 años) va primero: es la cantera ANTES de la cantera,
	## y la que decide cómo llegan los que aparecen más abajo.
	PanelAcademia.pintar(p._lista_cantera, p.mundo, p._ui_ficha._paleta_ficha(), func(error: String) -> void:
		if error != "":
			p._escribir("[color=#e05555]%s.[/color]" % error.capitalize())
		p._refrescar())

	## "LEYENDAS DEL CLUB" -su propia tarjeta en `vHistoria()` de vistas.js-:
	## `Cantera.leyendas` alimenta de verdad la camada anual (`registrar_retiro()`
	## mete a cada figura retirada, `camada_anual()` puede darle un hijo con su
	## apellido años después) pero hasta esta tanda no había ni una fila en
	## ningún sitio del juego que dijera qué leyendas tiene el club esperando:
	## el jugador nunca se enteraba de que Fulano se retiró como figura y que su
	## hijo podría debutar en unos años.
	var leyendas_del_club: Array[Dictionary] = []
	for l: Dictionary in ct.leyendas:
		if String(l.get("club_id", "")) == c.id:
			leyendas_del_club.append(l)
	if not leyendas_del_club.is_empty():
		var tley := p._texto(11, Principal.COL_ORO)
		tley.text = "LEYENDAS DEL CLUB"
		p._lista_cantera.add_child(tley)
		for l: Dictionary in leyendas_del_club:
			var lf := p._texto(12, Principal.COL_SUAVE if bool(l.get("usado", false)) else Principal.COL_TEXTO)
			lf.text = "%s  ·  %s  ·  nivel %d%s" % [
				String(l.get("nombre", "")), String(l.get("pos", "")), int(l.get("nivel", 0)),
				"  · su hijo ya debutó" if bool(l.get("usado", false)) else "  · puede tener un hijo en %d" % int(l.get("anio_hijo", 0))]
			lf.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_cantera.add_child(lf)
		p._lista_cantera.add_child(HSeparator.new())

	var camada := ct.camada_actual()
	if not camada.is_empty():
		var tc := p._texto(11, Principal.COL_ORO)
		tc.text = "LA CAMADA DE ESTE AÑO"
		p._lista_cantera.add_child(tc)
		for j: Jugador in camada:
			p._lista_cantera.add_child(_fila_canterano(j, ct, c))
		p._lista_cantera.add_child(HSeparator.new())

	var listos := ct.candidatos_a_debutar()
	if not listos.is_empty():
		var tl := p._texto(11, Principal.COL_VERDE)
		tl.text = "LISTOS PARA DEBUTAR"
		p._lista_cantera.add_child(tl)
		var nombres: Array[String] = []
		for j: Jugador in listos:
			nombres.append(j.nombre)
		var ll := p._texto(12, Principal.COL_TEXTO)
		ll.text = ", ".join(nombres)
		ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_cantera.add_child(ll)
		p._lista_cantera.add_child(HSeparator.new())

	var cats := ct.por_categoria(c)
	for clave: String in cats:
		var datos: Dictionary = cats[clave]
		var jugadores: Array = datos["jugadores"]
		if jugadores.is_empty():
			continue
		var tcat := p._texto(11, Principal.COL_SUAVE)
		tcat.text = String(datos["nombre"]).to_upper()
		p._lista_cantera.add_child(tcat)
		for j: Jugador in jugadores:
			p._lista_cantera.add_child(_fila_canterano(j, ct, c))
	## Las dinastías van al final: se leen después de la camada, que es lo que
	## se viene a mirar aquí todas las semanas.
	_pintar_linaje(c)

func _fila_canterano(j: Jugador, ct: Cantera, c: Club) -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	fila.add_child(p._retrato(j, 24))
	var listo := ct.listo_para_debutar(j)
	var nom := p._texto(12, Principal.COL_VERDE if listo else Principal.COL_TEXTO)
	var linaje: Dictionary = ct.linaje_de(j)
	var etiqueta := (" · hijo de %s" % String(linaje.get("padre", ""))) if not linaje.is_empty() else ""
	nom.text = "%s  ·  %d años  ·  %d/%d%s" % [j.nombre, j.edad, j.ovr, j.pot, etiqueta]
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
		rf.text = "fuga %.1f%%" % (fuga * 100.0)
		rf.tooltip_text = "Probabilidad de que se lo lleve otro club esta semana. La beca la baja, y las instalaciones de cantera también."
		rf.custom_minimum_size = Vector2(64, 0)
		fila.add_child(rf)
	if ct.tiene_beca(j):
		var tag := p._texto(11, Principal.COL_VERDE)
		tag.text = "becado"
		fila.add_child(tag)
	else:
		var costo := ct.coste_beca()
		var b := Button.new()
		b.text = "Becar  %s" % p._dinero(costo)
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = costo > c.saldo
		b.pressed.connect(func() -> void: _becar(j))
		fila.add_child(b)
	return fila

func _becar(j: Jugador) -> void:
	var problema := p.mundo.cantera.becar(j)
	if problema != "":
		p._escribir("[color=#e05555]No se puede becar: %s.[/color]" % problema)
		return
	p._escribir("[color=#4caf6d]%s tiene beca.[/color] Menos riesgo de que se lo lleven gratis." % j.nombre)
	p._refrescar()

## CONTRATOS: cesiones, cláusulas de rescisión y a quién prestar. La letra
## pequeña de un fichaje, que hasta hoy corría sola por dentro y no se podía
## ni ver ni decidir desde ningún lado.
## Los ROLES PROMETIDOS de `vContratos()`: qué papel le has jurado a cada uno.
##
## `Vestuario` lleva la promesa, la ventana de cumplimiento y el castigo de moral
## desde hace tanto que solo la renovación escribía ahí: fuera de la mesa de
## negociación no había forma de cambiarle el papel a nadie. Y es media mitad del
## sistema, porque prometer titular a un suplente y no darle minutos es
## exactamente lo que revienta un vestuario.
##
## `acepta_rol()` es lo que hace que no sea un desplegable tonto: el mejor de su
## puesto no acepta menos que titular, y a un quinto no le puedes prometer ser
## intocable porque sabe que no lo vas a cumplir.
func _pintar_roles_prometidos(c: Club) -> void:
	var v := p.mundo.vestuario
	if v == null:
		return
	var tabla := v.tabla_roles()
	if tabla.is_empty():
		return
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "ROLES PROMETIDOS"
	p._lista_contratos.add_child(t)
	var ex := p._texto(10, Principal.COL_SUAVE)
	ex.text = "Lo que le has prometido a cada uno. Bajarle el escalafón cuesta moral en el acto; subírselo la sube. Y prometer sin cumplir se paga después."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_contratos.add_child(ex)
	var plantel := c.plantilla.duplicate()
	plantel.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	for j: Jugador in plantel:
		var actual := v.rol_plantel(j)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_contratos.add_child(fila)
		fila.add_child(p._retrato(j, 22))
		var nom := p._texto(12, Principal.COL_TEXTO)
		nom.text = "%s  %s  ·  %d" % [j.pos_e, j.nombre, j.ovr]
		nom.custom_minimum_size = Vector2(170, 0)
		fila.add_child(nom)
		var op := OptionButton.new()
		op.add_theme_font_size_override("font_size", 11)
		op.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var elegido := 0
		for n in tabla.size():
			var f: Array = tabla[n]
			op.add_item(String(f[1]), n)
			if String(f[0]) == actual:
				elegido = n
			## Los que no aceptaría salen en la lista pero apagados: ver lo que
			## NO puedes ofrecerle explica su sitio en el plantel mejor que
			## cualquier texto.
			if not bool(v.acepta_rol(j, String(f[0]))["ok"]):
				op.set_item_disabled(n, true)
		op.selected = elegido
		var jug := j
		var filas := tabla
		op.item_selected.connect(func(idx: int) -> void:
			_cambiar_rol_prometido(jug, String((filas[idx] as Array)[0])))
		fila.add_child(op)
		## Los minutos que exige el papel: es la promesa concreta, y lo que se
		## va a comprobar cuando toque.
		var def := v.def_rol(actual)
		if not def.is_empty():
			var mn := p._texto(11, Principal.COL_SUAVE)
			mn.text = "%d%% min." % int(def[3])
			mn.custom_minimum_size = Vector2(56, 0)
			fila.add_child(mn)
	p._lista_contratos.add_child(HSeparator.new())

func _cambiar_rol_prometido(j: Jugador, rol: String) -> void:
	var r: Dictionary = p.mundo.vestuario.cambiar_rol(j, rol)
	var txt := String(r.get("txt", ""))
	if txt != "":
		var col := "#4caf6d" if bool(r.get("ok", false)) else "#e05555"
		p._escribir("[color=%s][b]%s.[/b][/color] %s" % [col, j.nombre, txt])
	p._refrescar()

## LA GUERRA DE AGENTES. `Cantera.sortear_guerra_agentes()` corre CADA SEMANA
## desde `Mundo` y presiona de verdad: un representante con dos o más clientes
## tuyos te exige cosas. Pero `agencias_del_plantel()` -quién controla a quién y
## cuánto confía en ti- no la llamaba ninguna pantalla, así que la presión te
## llegaba sin que pudieras ver de dónde venía ni prepararte.
func _pintar_agencias(c: Club) -> void:
	if p.mundo.cantera == null:
		return
	var lista := p.mundo.cantera.agencias_del_plantel()
	if lista.is_empty():
		return
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "🕴️ AGENCIAS DEL PLANTEL"
	p._lista_contratos.add_child(t)
	var ex := p._texto(10, Principal.COL_SUAVE)
	ex.text = "Un representante con dos o más clientes tuyos tiene con qué apretarte. Aquí se ve quién los tiene."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_contratos.add_child(ex)
	for f: Dictionary in lista:
		var jugadores: Array = f["jugadores"]
		var ag: Dictionary = f["agente"]
		var conf := int(f.get("confianza", 50))
		## En rojo los que tienen fuerza para exigir: dos clientes o más es
		## exactamente el umbral que usa el sorteo semanal.
		var peligro := jugadores.size() >= 2
		var l := p._texto(12, Principal.COL_ROJO if peligro and conf < 45 else Principal.COL_TEXTO)
		l.text = "%s  ·  %s  ·  %d jugador(es)  ·  confianza %d" % [
			String(ag.get("nombre", "un representante")), String(ag.get("perfil", "")),
			jugadores.size(), conf]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_contratos.add_child(l)
		var nombres: Array[String] = []
		for j: Jugador in jugadores:
			nombres.append(j.nombre)
		var n := p._texto(10, Principal.COL_SUAVE)
		n.text = "    " + ", ".join(nombres)
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_contratos.add_child(n)
	p._lista_contratos.add_child(HSeparator.new())

func _pintar_contratos(c: Club) -> void:
	p._limpiar(p._lista_contratos)
	_pintar_agencias(c)
	_pintar_roles_prometidos(c)
	var ce := p.mundo.cesiones
	if ce == null:
		return

	var fuera := ce.cedidos_de(c.id)
	if not fuera.is_empty():
		var tf := p._texto(11, Principal.COL_SUAVE)
		var ahorro := ce.ahorro_salarial(c.id)
		tf.text = "CEDIDOS FUERA  ·  te ahorras %s/semana" % p._dinero(ahorro)
		p._lista_contratos.add_child(tf)
		for fila: Dictionary in fuera:
			var j: Jugador = fila["jugador"]
			var destino: Club = fila["club"]
			var d: Dictionary = fila["cesion"]
			var tipo := String(d.get("tipo", ""))
			var letra := "opción de compra" if tipo == Cesiones.CESION_OPCION \
				else ("obligación de compra" if tipo == Cesiones.CESION_OBLIGA else "préstamo simple")
			var l := p._texto(12, Principal.COL_TEXTO)
			l.text = "%s  ·  en %s  ·  %s  ·  vuelve en %d" % [j.nombre, destino.nombre, letra, int(d.get("vuelve", 0))]
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_contratos.add_child(l)
		p._lista_contratos.add_child(HSeparator.new())

	## A quién prestar: juveniles hasta 21 -formación, cesión simple- y gente que
	## no juega -ya no es formación, es venta a plazo con opción u obligación.
	var candidatos_prestamo := c.plantilla.filter(func(j: Jugador) -> bool:
		return not ce.esta_cedido(j.id) and j.edad <= Cesiones.EDAD_CANTERANO)
	var candidatos_venta := c.plantilla.filter(func(j: Jugador) -> bool:
		return not ce.esta_cedido(j.id) and j.edad > Cesiones.EDAD_CANTERANO and j.partidos == 0)
	## Ceder es una decisión de mercado como fichar o vender: el mismo permiso.
	var puede_ceder := p.mundo.roles == null or p.mundo.roles.puede_fichar()
	if not puede_ceder:
		var np := p._texto(12, Principal.COL_SUAVE)
		np.text = String(p.mundo.roles.motivo_bloqueo("fichar"))
		np.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_contratos.add_child(np)
		p._lista_contratos.add_child(HSeparator.new())
	elif not candidatos_prestamo.is_empty() or not candidatos_venta.is_empty():
		var tc := p._texto(11, Principal.COL_SUAVE)
		tc.text = "A QUIÉN CEDER"
		p._lista_contratos.add_child(tc)
		for j: Jugador in candidatos_prestamo:
			var fila2 := HBoxContainer.new()
			fila2.add_theme_constant_override("separation", 8)
			p._lista_contratos.add_child(fila2)
			var nom := p._texto(12, Principal.COL_TEXTO)
			nom.text = "%s  ·  %d años  ·  cantera" % [j.nombre, j.edad]
			nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila2.add_child(nom)
			p._boton("Ceder a préstamo", func() -> void: p._ui_finanzas._ceder_canterano(j), fila2)
		for j: Jugador in candidatos_venta:
			var fila3 := HBoxContainer.new()
			fila3.add_theme_constant_override("separation", 6)
			p._lista_contratos.add_child(fila3)
			var nom2 := p._texto(12, Principal.COL_SUAVE)
			nom2.text = "%s  ·  %d años  ·  0 partidos" % [j.nombre, j.edad]
			nom2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila3.add_child(nom2)
			p._boton("Con opción", func() -> void: p._ui_finanzas._ceder_con_opcion(j, Cesiones.CESION_OPCION), fila3)
			p._boton("Con obligación", func() -> void: p._ui_finanzas._ceder_con_opcion(j, Cesiones.CESION_OBLIGA), fila3)
		p._lista_contratos.add_child(HSeparator.new())

	## RENOVACIONES. `Cantera.pide_para_renovar()` llevaba tiempo sabiendo
	## calcular lo que pide cada uno -sueldo actual, recargo por moral baja y por
	## rendir por encima del club, y el multiplicador de su agente- y no había
	## forma de decirle que sí. Un contrato que se acaba y no se puede renovar es
	## un jugador que se pierde solo.
	##
	## Se listan los que entran en su último año, que son los que urgen.
	if ce != null and p.mundo.cantera != null and puede_ceder:
		var por_renovar := c.plantilla.filter(func(j: Jugador) -> bool: return j.anios_contrato <= 1)
		var tr := p._texto(11, Principal.COL_SUAVE)
		tr.text = "RENOVACIONES  ·  último año de contrato"
		p._lista_contratos.add_child(tr)
		if por_renovar.is_empty():
			var sin := p._texto(12, Principal.COL_SUAVE)
			sin.text = "Nadie termina contrato esta temporada."
			p._lista_contratos.add_child(sin)
		for j: Jugador in por_renovar:
			var pide := p.mundo.cantera.pide_para_renovar(j)
			var fila_r := HBoxContainer.new()
			fila_r.add_theme_constant_override("separation", 6)
			p._lista_contratos.add_child(fila_r)
			var nr := p._texto(12, Principal.COL_TEXTO)
			nr.text = "%s  ·  %d años  ·  media %d  ·  cobra %s → pide %s" % [
				j.nombre, j.edad, j.ovr, p._dinero(j.sueldo), p._dinero(pide)]
			nr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila_r.add_child(nr)
			p._boton("Renovar", func() -> void: p._ui_club_vida._renovar(j, false), fila_r)
			## Con cláusula cobra un 10% menos: le pones precio de salida y a
			## cambio te ahorras ficha. Es la decisión, no un adorno.
			p._boton("Con cláusula (−10%)", func() -> void: p._ui_club_vida._renovar(j, true), fila_r)
		p._lista_contratos.add_child(HSeparator.new())

	## Las cláusulas de tu plantel: la protección va al revés que un fichaje, se
	## paga para que NADIE pueda llevarse a tu figura por la puerta de atrás.
	var tcl := p._texto(11, Principal.COL_SUAVE)
	tcl.text = "CLÁUSULAS DE RESCISIÓN"
	p._lista_contratos.add_child(tcl)
	var orden := c.plantilla.duplicate()
	orden.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	for j: Jugador in orden:
		var clau := ce.clausula_de(j)
		var fila4 := HBoxContainer.new()
		fila4.add_theme_constant_override("separation", 8)
		p._lista_contratos.add_child(fila4)
		var nom3 := p._texto(12, Principal.COL_TEXTO if clau > 0 else Principal.COL_SUAVE)
		nom3.text = "%s  ·  %s" % [j.nombre, p._dinero(clau) if clau > 0 else "sin cláusula"]
		nom3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila4.add_child(nom3)
		var b := Button.new()
		b.text = "Blindar" if clau > 0 else "Pactar cláusula"
		b.add_theme_font_size_override("font_size", 11)
		b.pressed.connect(func() -> void: p._ui_finanzas._pactar_clausula_propia(j))
		fila4.add_child(b)

## `vComparador()` de vistas.js -un archivo aparte de juego.js que esta sesión
## no había mirado hasta ahora, y donde vive el render real de las 33
## sub-pestañas de "Club"-: hasta tres jugadores lado a lado, con el mejor
## valor de cada fila resaltado en verde. Fuera de alcance a propósito: la
## fila "Ansiedad" del HTML no tiene equivalente -Godot no tiene portado
## `j.mente.ansiedad`, es un sistema propio, no un olvido de esta fila-. El
## "modo ciego" sí se portó después (`Ojeadores.modo_ciego`): esta tabla en
## particular no usa la palabra cualitativa de `ovr_palabra()` -el HTML tampoco
## lo hace aquí-, sino un simple "?" en la fila Media, igual que ya hacía la
## fila Proyección para quien no conocías.
func _pintar_comparar() -> void:
	p._limpiar(p._lista_comparar)
	var jugadores: Array[Jugador] = []
	for id in p._comparar_ids:
		var j := p.mundo.jugador_por_id(id)
		if j != null:
			jugadores.append(j)
	## Si alguno se vendió, se retiró o fue rescindido entre medio, desaparece
	## solo del comparador -no queda un id muerto señalando a nadie-.
	p._comparar_ids.clear()
	for j in jugadores:
		p._comparar_ids.append(j.id)

	if jugadores.is_empty():
		var vacio := p._texto(12, Principal.COL_SUAVE)
		vacio.text = "Abre la ficha de cualquier jugador y pulsa «Comparar» para ponerlo aquí. Puedes enfrentar hasta tres a la vez, de tu club o de cualquier otro."
		vacio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_comparar.add_child(vacio)
		return

	var cabecera := HBoxContainer.new()
	cabecera.add_theme_constant_override("separation", 12)
	p._lista_comparar.add_child(cabecera)
	for j in jugadores:
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cabecera.add_child(col)
		var retrato := TextureRect.new()
		var suyo: Club = p.mundo.clubes.get(j.club_id)
		retrato.texture = Cara.textura(j, suyo.color1 if suyo else "#2b6b45", suyo.color2 if suyo else "#ffffff", 48)
		retrato.custom_minimum_size = Vector2(48, 48)
		retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		retrato.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(retrato)
		var nom := p._texto(11, Principal.COL_TEXTO)
		nom.text = _apellido(j.nombre)
		nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(nom)
		var bq := Button.new()
		bq.text = "✕"
		bq.custom_minimum_size = Vector2(0, 26)
		bq.pressed.connect(func() -> void: _alternar_comparar(j))
		col.add_child(bq)
	p._lista_comparar.add_child(HSeparator.new())

	var g := GridContainer.new()
	g.columns = 1 + jugadores.size()
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 3)
	p._lista_comparar.add_child(g)

	## `mostrar_de` es aparte de `valor_de` para que Valor/Sueldo comparen el
	## número de verdad (`j.valor`/`j.sueldo`) y no la cadena ya formateada
	## ("7.4M EUR" nunca es `is int`, así que comparar cadenas dejaba a los
	## tres empatados en 0 y los resaltaba a los tres, o a ninguno).
	var conoce := func(j: Jugador) -> bool: return j.club_id == p.mundo.mi_club_id or p.mundo.ojeados.has(j.id)
	## `cegado()` del HTML: en "mercado a ciegas" ni la Media se enseña de
	## quien no conoces -aquí se ve un "?", no la palabra cualitativa de
	## `ovr_palabra()`, tal cual hace el HTML en ESTA tabla en particular-.
	var cegado := func(j: Jugador) -> bool:
		return p.mundo.ojeadores != null and p.mundo.ojeadores.modo_ciego and not conoce.call(j)
	var edad_de := func(j: Jugador) -> Variant: return j.edad
	var valor_de := func(j: Jugador) -> Variant: return j.valor
	var sueldo_de := func(j: Jugador) -> Variant: return j.sueldo
	var como_dinero := func(v: Variant) -> String: return p._dinero(int(v))
	_fila_comparar(g, jugadores, "Media", func(j: Jugador) -> Variant: return "?" if cegado.call(j) else j.ovr)
	_fila_comparar(g, jugadores, "Proyección", func(j: Jugador) -> Variant: return j.pot if conoce.call(j) else "?")
	_fila_comparar(g, jugadores, "Edad", edad_de, false)
	_fila_comparar(g, jugadores, "Valor", valor_de, true, como_dinero)
	_fila_comparar(g, jugadores, "Sueldo", sueldo_de, false, como_dinero)
	var claves := jugadores[0].atributos.keys() if not jugadores.is_empty() else []
	for k: String in claves:
		var clave := k
		_fila_comparar(g, jugadores, String(Principal.NOMBRES_ATRIBUTOS.get(clave, clave)),
			func(j: Jugador) -> Variant: return int(j.atributos.get(clave, 0)) if j.atributos.has(clave) else "—")
	_fila_comparar(g, jugadores, "Forma", func(j: Jugador) -> Variant: return j.forma)
	_fila_comparar(g, jugadores, "Físico", func(j: Jugador) -> Variant: return j.fisico)
	_fila_comparar(g, jugadores, "Goles", func(j: Jugador) -> Variant: return j.goles)
	_fila_comparar(g, jugadores, "Partidos", func(j: Jugador) -> Variant: return j.partidos)

	if p.mundo.entrenamiento != null:
		p._lista_comparar.add_child(HSeparator.new())
		var th := p._texto(11, Principal.COL_SUAVE)
		th.text = "HABILIDADES"
		p._lista_comparar.add_child(th)
		for j in jugadores:
			var claves_hab: Array = p.mundo.entrenamiento.habilidades(j)
			var nombres: Array[String] = []
			for k2 in claves_hab:
				nombres.append(p.mundo.entrenamiento.nombre_habilidad(String(k2)))
			var fh := HBoxContainer.new()
			p._lista_comparar.add_child(fh)
			var eq := p._texto(11, Principal.COL_TEXTO)
			eq.text = _apellido(j.nombre)
			eq.custom_minimum_size = Vector2(90, 0)
			fh.add_child(eq)
			var vh := p._texto(11, Principal.COL_SUAVE)
			vh.text = ", ".join(nombres) if not nombres.is_empty() else "—"
			vh.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			vh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fh.add_child(vh)

	var vaciar := func() -> void:
		p._comparar_ids.clear()
		_pintar_comparar()
	p._boton("Vaciar comparador", vaciar, p._lista_comparar)

## Una fila del comparador: etiqueta a la izquierda, un valor por jugador, con
## el mejor resaltado en verde -`mayor_mejor=false` para Edad y Sueldo, donde
## menos es mejor-. Los valores no numéricos (el "?" de una proyección sin
## ojear) cuentan como 0 y nunca ganan el resaltado, igual que `+v||0` en el
## HTML.
func _fila_comparar(g: GridContainer, jugadores: Array[Jugador], etiqueta: String, valor_de: Callable,
		mayor_mejor: bool = true, formatear: Callable = Callable()) -> void:
	p._celda(g, etiqueta, Principal.COL_SUAVE)
	var valores: Array = []
	var numeros: Array[float] = []
	for j in jugadores:
		var v: Variant = valor_de.call(j)
		valores.append(v)
		numeros.append(float(v) if (v is int or v is float) else 0.0)
	var mejor := numeros[0]
	for n in numeros:
		if (mayor_mejor and n > mejor) or (not mayor_mejor and n < mejor):
			mejor = n
	## Igual que `(+v||0)===mejor` en el HTML: si todos empatan -incluido un
	## "?" contra otro "?"- se resaltan todos, no ninguno. No es un caso raro
	## que valga la pena tratar distinto, es lo que ya hacía el original.
	for i in valores.size():
		var texto: String = formatear.call(valores[i]) if formatear.is_valid() else str(valores[i])
		p._celda(g, texto, Principal.COL_VERDE if numeros[i] == mejor else Principal.COL_TEXTO, true)

func _apellido(nombre: String) -> String:
	var partes := nombre.split(" ")
	return partes[partes.size() - 1] if not partes.is_empty() else nombre

func _alternar_comparar(j: Jugador) -> void:
	if p._comparar_ids.has(j.id):
		p._comparar_ids.erase(j.id)
	elif p._comparar_ids.size() < 3:
		p._comparar_ids.append(j.id)
	_pintar_comparar()
	p._ver_ficha(j)

## `vRecords()` de vistas.js: rachas, marcas, goleadores e historial cara a
## cara. Todo esto ya lo llevaba `Logros` -`h2h`, `rachas`, `rec`, `efemerides`,
## `planteles`- desde que se enganchó la memoria del club, probado y guardado,
## pero la pestaña Logros solo enseñaba la vitrina de títulos y el top 5 de
## goleadores: el resto vivía en el guardado sin que nadie lo viera nunca.
## `vLegado()`: lo que queda de ti cuando te vas. Es la ÚNICA pantalla del juego
## que no habla del club sino del entrenador: el club se pierde al cambiar de
## banco, esto te sigue. Cuatro bloques, en el orden del HTML — el resumen, el
## palmarés, la escalera de rol y los homenajes— más el epílogo, que solo aparece
## a partir de la tercera temporada porque antes no hay carrera que resumir.
## `vInicio()`: la portada del club. Es la pantalla que el HTML abre por defecto
## cada semana y la que aquí no existía: se entraba directamente al Estadio y
## había que ir tabulando para saber si tenías gente lesionada o cómo iba la
## caja.
##
## No repite información: la RESUME y la enlaza. Los cuatro recuadros son atajos
## -pulsarlos lleva a la pestaña donde de verdad se decide-, que es lo que hace
## que una portada sirva para algo en vez de ser un adorno de bienvenida.
## EL INFORME DE GESTIÓN. Lo primero de la pantalla de Inicio: las seis cosas
## que hay que mirar cada lunes, juntas y con el botón que lleva a arreglarlas.
##
## No añade ninguna mecánica: junta lo que ya está repartido por ocho pestañas.
## Este juego tiene dieciocho, y sin esto un jugador nuevo no sabe cuáles mirar
## y uno veterano se olvida siempre de la misma.
func _pintar_informe() -> void:
	var lineas := p.mundo.informe_de_gestion()
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "📋 INFORME DE LA SEMANA"
	p._lista_inicio.add_child(t)
	for f: Dictionary in lineas:
		var grave := bool(f["grave"])
		var tab := String(f.get("tab", ""))
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_inicio.add_child(fila)
		var n := p._texto(12, Principal.COL_ROJO if grave else Principal.COL_TEXTO)
		## Traducido ANTES de ponerle la viñeta: los patrones con números
		## («5 contratos terminan…») empiezan en la frase, no en «●».
		n.text = "%s %s" % ["●" if grave else "○", Idiomas.t(String(f["txt"]))]
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fila.add_child(n)
		if tab == "":
			continue
		var b := Button.new()
		b.text = Idiomas.t(tab)
		b.add_theme_font_size_override("font_size", 10)
		b.clip_text = true
		b.custom_minimum_size = Vector2(92, 24)
		b.pressed.connect(func() -> void: p._ir_a_pestana(tab))
		fila.add_child(b)
	p._lista_inicio.add_child(HSeparator.new())
