class_name PantallaGente
extends RefCounted
## GENTE Y MEDIOS: personas, redes, periodistas, medios propios, derechos de TV, portadas y correo.
##
## Sale de `ui/principal.gd` (mapa de metas 15: el archivo pasaba de
## 15.000 líneas). `p` es la pantalla principal: sus ayudantes (`p._texto`,
## `p._boton`...), el mundo (`p.mundo`) y el repintado (`p._refrescar()`).

var p: Principal

func _init(principal: Principal) -> void:
	p = principal

func _pintar_gente() -> void:
	p._limpiar(p._lista_gente)
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 4)
	chips.add_theme_constant_override("v_separation", 4)
	p._lista_gente.add_child(chips)
	for s: Array in Principal.SECCIONES_GENTE:
		var clave := String(s[0])
		var b := Button.new()
		b.text = String(s[1])
		b.add_theme_font_size_override("font_size", 11)
		b.toggle_mode = true
		b.button_pressed = p._secc_gente == clave or (clave == "identidad" and p._secc_gente == "kits")
		b.clip_text = true
		b.custom_minimum_size = Vector2(150, 26)
		b.pressed.connect(func() -> void:
			p._secc_gente = clave
			p._refrescar())
		chips.add_child(b)
	p._lista_gente.add_child(HSeparator.new())
	var c := p.mundo.mi_club()
	match p._secc_gente:
		"personas":
			_pintar_gente_personas()
		## "Equipación" (chip del grupo GENTE) vive dentro de Identidad, junto
		## al escudo: sin esta rama el chip abría una página vacía.
		"identidad", "kits":
			p._pintar_identidad(c)
		"comercial":
			p._ui_identidad._pintar_comercial(c)
		"interno":
			PanelClubDentro.pintar(p._lista_gente, c, p.mundo, p._texto, p._ui_ficha._paleta_club_dentro(), p._miles, p._escribir, p._refrescar)

func _pintar_gente_personas() -> void:
	var g := p.mundo.gente
	if g == null:
		return
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "LA GENTE DEL CLUB"
	p._lista_gente.add_child(t)
	var intro := p._texto(11, Principal.COL_SUAVE)
	intro.text = "Llevan aquí más años que tú y seguirán cuando te vayas. Tratarlos bien no sale en ninguna estadística, pero se nota."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_gente.add_child(intro)
	var media := g.confianza_media()
	p._dato("Confianza media", "%d/100" % media,
		Principal.COL_VERDE if media >= 70 else (Principal.COL_ROJO if media <= 40 else Principal.COL_ORO), p._lista_gente)
	p._dato("Charlas esta semana", "%d de %d" % [g.charlas_esta_semana, Gente.CHARLAS_POR_SEMANA],
		Principal.COL_SUAVE, p._lista_gente)
	p._lista_gente.add_child(HSeparator.new())

	for fila: Array in Gente.ROLES:
		var clave := String(fila[0])
		var f := g.ficha(clave)
		if f.is_empty():
			continue
		var conf := int(f.get("confianza", 50))
		var cab := HBoxContainer.new()
		cab.add_theme_constant_override("separation", 6)
		p._lista_gente.add_child(cab)
		var nom := p._texto(12, Principal.COL_TEXTO)
		nom.text = "%s  %s — %s" % [String(fila[2]), String(fila[1]), String(f.get("nombre", ""))]
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nom.clip_text = true
		cab.add_child(nom)
		var cf := p._texto(12, Principal.COL_VERDE if conf >= 70 else (Principal.COL_ROJO if conf <= 40 else Principal.COL_ORO))
		cf.text = str(conf)
		cf.custom_minimum_size = Vector2(32, 0)
		cab.add_child(cf)
		var b := Button.new()
		var ya := g.hablado_esta_semana(clave)
		b.text = "Ya hablasteis" if ya else "Charlar"
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = ya or g.charlas_esta_semana >= Gente.CHARLAS_POR_SEMANA
		b.custom_minimum_size = Vector2(110, 0)
		b.pressed.connect(func() -> void: _charlar_con(clave))
		cab.add_child(b)
		var d := p._texto(10, Principal.COL_SUAVE)
		d.text = "%d años  ·  %d en el club  ·  %s  ·  %s" % [
			int(f.get("edad", 0)), int(f.get("anios", 0)), String(f.get("perfil", "")), String(fila[3])]
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_gente.add_child(d)

func _charlar_con(clave: String) -> void:
	var txt := p.mundo.gente.charlar(clave)
	if txt != "":
		p._escribir("[color=#8ea595]%s[/color]" % txt)
	p._refrescar()

func _filtrar_redes() -> void:
	var titulos: Array = []
	for k: String in Principal.SECC_REDES:
		titulos.append_array(Principal.SECC_REDES[k] as Array)
	var visibles: Array = Principal.SECC_REDES.get(p._secc_redes, [])
	var mostrando := true
	for n in p._lista_redes.get_children():
		var l := n as Label
		if l != null and titulos.has(l.text):
			mostrando = visibles.has(l.text)
		if n is CanvasItem:
			(n as CanvasItem).visible = mostrando

func _pintar_redes() -> void:
	p._limpiar(p._lista_redes)
	var p_local := p.mundo.prensa
	if p_local == null:
		return
	var g := GridContainer.new()
	g.columns = 4
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 12)
	p._lista_redes.add_child(g)
	for par in [["Seguidores", p._miles(p_local.seguidores)], ["Funa", str(p_local.funa)],
			["Ánimo", str(p_local.animo)], ["Prestigio DT", str(p_local.rep_entrenador)]]:
		var col := VBoxContainer.new()
		g.add_child(col)
		var et := p._texto(10, Principal.COL_SUAVE)
		et.text = String(par[0])
		col.add_child(et)
		var va := p._texto(16, Principal.COL_TEXTO)
		va.text = String(par[1])
		col.add_child(va)
	var estado := p._texto(11, Principal.COL_ROJO if p_local.funa > 60 else (Principal.COL_ORO if p_local.funa > 35 else Principal.COL_VERDE))
	estado.text = ("⚠️ Campaña activa en tu contra: el directorio lo está mirando."
		if p_local.funa > 60 else ("Hay ruido en redes, pero se aguanta."
		if p_local.funa > 35 else "Ambiente tranquilo en las redes."))
	estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_redes.add_child(estado)
	p._lista_redes.add_child(HSeparator.new())

	var tg := p._texto(11, Principal.COL_SUAVE)
	tg.text = "GABINETE DE COMUNICACIÓN"
	p._lista_redes.add_child(tg)
	var ex := p._texto(10, Principal.COL_SUAVE)
	ex.text = "Apoyar calma la funa pero gasta un cartucho. Callar no cuesta nada hoy. Contestar es cara o cruz: apaga el fuego o lo dobla."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_redes.add_child(ex)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	p._lista_redes.add_child(fila)
	for par2 in [["apoyo", "📢 Comunicado de apoyo"], ["silencio", "🤐 Silencio de prensa"],
			["contestar", "🗣️ Contestar"]]:
		var clave := String(par2[0])
		var b := Button.new()
		b.text = String(par2[1])
		b.add_theme_font_size_override("font_size", 11)
		b.clip_text = true
		b.custom_minimum_size = Vector2(110, 0)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void: _comunicado(clave))
		fila.add_child(b)
	p._lista_redes.add_child(HSeparator.new())

	_pintar_periodistas(p_local)
	_pintar_mesa_debate(p_local)
	_pintar_influencer(p_local)
	_pintar_medios_propios(p_local)
	_pintar_vocero(p_local)
	_pintar_derechos_tv(p_local)
	_pintar_portadas(p_local)
	_pintar_ano_contado(p_local)

	var tf := p._texto(11, Principal.COL_SUAVE)
	tf.text = "LO QUE SE DICE"
	p._lista_redes.add_child(tf)
	if p_local.posts.is_empty():
		var vac := p._texto(12, Principal.COL_SUAVE)
		vac.text = "Todavía nadie habla de ti. Gana o pierde algo y verás."
		p._lista_redes.add_child(vac)
		return
	for i in mini(25, p_local.posts.size()):
		var m: Dictionary = p_local.posts[i]
		var l := p._texto(12, Principal.COL_TEXTO)
		l.text = "%s  %s" % [String(m.get("avatar", "")), String(m.get("texto", ""))]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_redes.add_child(l)
		var meta := p._texto(10, Principal.COL_SUAVE)
		meta.text = "%s  ·  ♥ %s  ·  ↻ %s" % [
			String(m.get("usuario", "")), p._miles(int(m.get("likes", 0))), p._miles(int(m.get("rt", 0)))]
		p._lista_redes.add_child(meta)

## `vPrensa()`: los cinco periodistas con nombre y cómo te tratan. `funa` mide
## el ruido; esto le pone CARA. Uno por semana: si se pudiera atender a los
## cinco, no habría que elegir a quién cuidar, que es toda la decisión.
func _pintar_periodistas(p_local: Prensa) -> void:
	p._lista_redes.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "🎙️ LA PRENSA"
	p._lista_redes.add_child(t)
	var am := p_local.amortiguador_prensa()
	p._dato("Cómo te trata la prensa", "×%.2f sobre el ruido" % am,
		Principal.COL_VERDE if am < 1.0 else (Principal.COL_ROJO if am > 1.1 else Principal.COL_SUAVE), p._lista_redes)
	for f: Array in Prensa.PERIODISTAS:
		var clave := String(f[0])
		var rel := p_local.relacion_con(clave)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_redes.add_child(fila)
		var n := p._texto(12, Principal.COL_TEXTO)
		n.text = "%s  ·  %s  ·  %s" % [String(f[1]), String(f[2]), String(f[3])]
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		n.tooltip_text = String(f[4])
		fila.add_child(n)
		var r := p._texto(12, Principal.COL_VERDE if rel >= 70 else (Principal.COL_ROJO if rel <= 35 else Principal.COL_ORO))
		r.text = str(rel)
		r.custom_minimum_size = Vector2(32, 0)
		fila.add_child(r)
		var b := Button.new()
		b.text = "Atender"
		b.add_theme_font_size_override("font_size", 11)
		b.custom_minimum_size = Vector2(90, 0)
		b.pressed.connect(func() -> void: _atender_periodista(clave))
		fila.add_child(b)

## Los medios propios: la respuesta a no gustarte cómo lo cuentan. Cuestan una
## vez y rentan cada mes.
func _pintar_medios_propios(p_local: Prensa) -> void:
	var c := p.mundo.mi_club()
	p._lista_redes.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "📡 MEDIOS PROPIOS"
	p._lista_redes.add_child(t)
	var ex := p._texto(10, Principal.COL_SUAVE)
	ex.text = "Si no te gusta cómo lo cuentan, cuéntalo tú. Se pagan una vez y rentan todos los meses."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_redes.add_child(ex)
	for f: Array in Prensa.MEDIOS_PROPIOS:
		var clave := String(f[0])
		var tengo := p_local.tiene_medio(clave)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_redes.add_child(fila)
		var n := p._texto(12, Principal.COL_VERDE if tengo else Principal.COL_TEXTO)
		n.text = "%s%s — %s" % ["✔  " if tengo else "     ", String(f[1]), String(f[4])]
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		fila.add_child(n)
		var r := p._texto(11, Principal.COL_SUAVE)
		r.text = "+%s/mes" % p._dinero(Eco.escalar(float(f[3]), float(c.rep)))
		r.custom_minimum_size = Vector2(96, 0)
		fila.add_child(r)
		var b := Button.new()
		var coste := Eco.escalar(float(f[2]), float(c.rep))
		b.text = "Puesto" if tengo else p._dinero(coste)
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = tengo or c.saldo < coste
		b.custom_minimum_size = Vector2(96, 0)
		b.pressed.connect(func() -> void: _comprar_medio(clave, c))
		fila.add_child(b)

## EL PORTAVOZ. Nombrar a alguien que hable por ti reparte a la mitad lo que
## mueve cada rueda de prensa, para bien y para mal: es el trato que el botón
## del HTML prometía en su texto y no cobraba en ninguna cuenta.
func _pintar_vocero(p_local: Prensa) -> void:
	var c := p.mundo.mi_club()
	if c == null:
		return
	p._lista_redes.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "🎤 QUIÉN DA LA CARA"
	p._lista_redes.add_child(t)
	var hay := not p_local.vocero.is_empty()
	var ex := p._texto(11, Principal.COL_ORO if hay else Principal.COL_SUAVE)
	if hay:
		ex.text = "%s habla por ti. La rueda de prensa mueve la mitad: ni te luces ni te hundes." % String(p_local.vocero.get("nombre", ""))
	else:
		ex.text = "Das tú la cara en cada rueda. Todo lo que digas cuenta el doble que con portavoz."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_redes.add_child(ex)
	var b := Button.new()
	b.text = "Quitar al portavoz" if hay else "Nombrar portavoz"
	b.add_theme_font_size_override("font_size", 11)
	b.pressed.connect(func() -> void:
		var msg := p_local.nombrar_vocero(p.mundo.mi_club())
		## Si el estado no cambió es que no se pudo: no hay capitán ni líder a
		## quien poner delante del micrófono.
		if (not p_local.vocero.is_empty()) == hay:
			p._escribir("[color=#e05555]No se pudo: %s.[/color]" % msg)
		else:
			p._escribir("[color=#4caf6d]%s[/color]" % msg)
		p._refrescar())
	p._lista_redes.add_child(b)

## LOS DERECHOS DE TELEVISIÓN: la decisión más rentable y más impopular. Vender
## solo paga un 35% más si tu club vende, y un 30% MENOS si no; en los dos casos
## la asamblea te lo apunta. Es la única palanca del juego que sube el ingreso
## más grande del club a cambio de perder aliados en la federación.
func _pintar_derechos_tv(p_local: Prensa) -> void:
	var c := p.mundo.mi_club()
	if c == null:
		return
	p._lista_redes.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "📺 DERECHOS DE TELEVISIÓN"
	p._lista_redes.add_child(t)
	var ex := p._texto(10, Principal.COL_SUAVE)
	ex.text = "En bloque cobras lo que reparte la liga. Por tu cuenta puedes ganar mucho más… si tu club vende. Y la asamblea te lo tiene en cuenta."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_redes.add_child(ex)
	p._dato("Modelo actual", "Negociación individual" if p_local.tv_individual else "Reparto en bloque",
		Principal.COL_TEXTO, p._lista_redes)
	var ft := p_local.factor_tv()
	var pct := int(round((ft - 1.0) * 100.0))
	p._dato("Efecto sobre tus derechos", "%s%d%%" % ["+" if pct > 0 else "", pct],
		Principal.COL_VERDE if pct > 0 else (Principal.COL_ROJO if pct < 0 else Principal.COL_SUAVE), p._lista_redes)
	## El reparto de la asamblea es OTRO multiplicador, y se enseña al lado para
	## que se vea que se acumulan: votar mal en la federación y vender solo mal
	## es la forma más rápida de quedarse sin la entrada más grande del club.
	if p.mundo.federacion != null and not is_equal_approx(p.mundo.federacion.factor_tv(), 1.0):
		var fr := p.mundo.federacion.factor_tv()
		p._dato("Reparto votado en la asamblea", "×%.2f" % fr,
			Principal.COL_VERDE if fr > 1.0 else Principal.COL_ROJO, p._lista_redes)
	p._dato("Cobro mensual estimado", p._dinero(int(round(
		float(Finanzas.new(c, 0.0, 0, 0.0).derechos_tv_base())
		* ft * (p.mundo.federacion.factor_tv() if p.mundo.federacion != null else 1.0)))),
		Principal.COL_TEXTO, p._lista_redes)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	p._lista_redes.add_child(fila)
	for op: Array in [[false, "Reparto en bloque"], [true, "Negociar por mi cuenta"]]:
		var individual: bool = op[0]
		var b := Button.new()
		b.text = String(op[1])
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = p_local.tv_individual == individual
		b.custom_minimum_size = Vector2(140, 0)
		b.clip_text = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			var msg := p_local.negociar_tv(individual, p.mundo.mi_club())
			p._escribir("[color=#e0a832]Televisión:[/color] %s" % msg)
			p._refrescar())
		fila.add_child(b)

func _pintar_portadas(p_local: Prensa) -> void:
	p._lista_redes.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "🗞️ ARCHIVO DE PORTADAS"
	p._lista_redes.add_child(t)
	if p_local.portadas.is_empty():
		var vac := p._texto(11, Principal.COL_SUAVE)
		vac.text = "Las portadas se archivan solas después de cada partido."
		vac.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_redes.add_child(vac)
		return
	for i in mini(14, p_local.portadas.size()):
		var d: Dictionary = p_local.portadas[i]
		var tipo := String(d.get("tipo", "neutro"))
		## Cada portada del archivo se abre como periódico (C20).
		var tit := Button.new()
		tit.flat = true
		tit.alignment = HORIZONTAL_ALIGNMENT_LEFT
		tit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tit.add_theme_font_size_override("font_size", 12)
		tit.add_theme_color_override("font_color", Principal.COL_VERDE if tipo == "bien" else (Principal.COL_ROJO if tipo == "mal" else Principal.COL_TEXTO))
		tit.text = "🗞 " + String(d.get("t", ""))
		tit.tooltip_text = "Abrir la portada"
		tit.pressed.connect(func() -> void: PortadaPeriodico.mostrar(p, p.mundo, d))
		p._lista_redes.add_child(tit)
		var cu := p._texto(10, Principal.COL_SUAVE)
		cu.text = "%s   ·   S%d · %d" % [String(d.get("c", "")), int(d.get("semana", 0)), int(d.get("anio", 0))]
		cu.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_redes.add_child(cu)

## EL AÑO CONTADO: un párrafo en vez de una tabla. Toda la información ya está
## repartida por seis pantallas; aquí se cuenta como se lo contaría alguien, que
## es la única forma de que una temporada se lea como una temporada.
func _pintar_ano_contado(p_local: Prensa) -> void:
	p._lista_redes.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "📖 EL AÑO CONTADO"
	p._lista_redes.add_child(t)
	var r := p._texto(12, Principal.COL_TEXTO)
	r.text = p_local.narrador_temporada()
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_redes.add_child(r)

## `vDebate()`: LOS QUE MUEVEN MASAS. Cinco creadores con más audiencia que
## cualquier periódico del juego.
##
## Al tertuliano lo escucha el directorio; a estos los escucha la calle, y por
## eso lo que mueven no es la confianza sino los seguidores del club. Invitarlo
## cuesta dinero y da alcance; ignorarlo es gratis y se paga en índice de prensa.
func _pintar_influencer(p_local: Prensa) -> void:
	var op := p_local.opinion_influencer()
	if op.is_empty():
		return
	var c := p.mundo.mi_club()
	p._lista_redes.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "📱 LO QUE DICEN LOS QUE MUEVEN MASAS"
	p._lista_redes.add_child(t)
	var n := p._texto(12, Principal.COL_TEXTO)
	n.text = "%s  ·  %s seguidores" % [String(op["nombre"]), String(op["seguidores"])]
	n.clip_text = true
	p._lista_redes.add_child(n)
	var tono := String(op["tono"])
	var q := p._texto(13, Principal.COL_VERDE if tono == "bien" else (Principal.COL_ROJO if tono == "mal" else Principal.COL_ORO))
	q.text = "«%s»" % String(op["texto"])
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_redes.add_child(q)
	var et := p._texto(10, Principal.COL_SUAVE)
	et.text = "A favor" if tono == "bien" else ("En contra" if tono == "mal" else "Tibio")
	p._lista_redes.add_child(et)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	p._lista_redes.add_child(fila)
	var coste := Eco.escalar(Prensa.COSTE_INVITAR, float(c.rep)) if c != null else 0
	for op_b: Array in [[true, "🤝 Invitarlo al club  ·  %s" % p._dinero(coste)], [false, "🙄 Ignorarlo"]]:
		var invitar: bool = op_b[0]
		var b := Button.new()
		b.text = String(op_b[1])
		b.add_theme_font_size_override("font_size", 11)
		b.clip_text = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = invitar and c != null and c.saldo < coste
		b.pressed.connect(func() -> void:
			var msg := p_local.responder_influencer(invitar, p.mundo.mi_club())
			p._escribir("[color=#c9a227]%s[/color]" % msg)
			p._refrescar())
		fila.add_child(b)

## `vDebate()`: la mesa de televisión y el escalafón de entrenadores.
##
## "No cambia un resultado, pero sí lo que el directorio escucha en el desayuno"
## —lo dice la pantalla del HTML—. Los cinco tertulianos hablan del estado REAL
## del club, no de frases al azar: si dijeran cualquier cosa, se notaría a la
## segunda semana y se dejarían de leer.
func _pintar_mesa_debate(p_local: Prensa) -> void:
	var mesa := p_local.mesa_de_debate()
	if mesa.is_empty():
		return
	p._lista_redes.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "📺 MESA DE DEBATE"
	p._lista_redes.add_child(t)
	for f: Dictionary in mesa:
		var n := p._texto(12, Principal.COL_TEXTO)
		n.text = "%s  ·  %s" % [String(f["nombre"]), String(f["perfil"])]
		p._lista_redes.add_child(n)
		var fr := p._texto(12, Principal.COL_SUAVE)
		fr.text = "«%s»" % String(f["frase"])
		fr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_redes.add_child(fr)

	## EL ESCALAFÓN DE ENTRENADORES. Es la única métrica del juego que mide al
	## ENTRENADOR y no al club: premia rendir por encima de lo que el club
	## permite. Un séptimo con el decimoquinto presupuesto vale más que un
	## tercero con el primero.
	var rank := p_local.ranking_entrenadores()
	if rank.is_empty():
		return
	var tr := p._texto(11, Principal.COL_SUAVE)
	tr.text = "🏅 RANKING DE ENTRENADORES"
	p._lista_redes.add_child(tr)
	var ex := p._texto(10, Principal.COL_SUAVE)
	ex.text = "No mide dónde acabas, sino cuánto le sacas a lo que tienes."
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_redes.add_child(ex)
	var mi_puesto := 0
	for i in rank.size():
		if bool((rank[i] as Dictionary)["mio"]):
			mi_puesto = i + 1
	for i2 in mini(8, rank.size()):
		var f2: Dictionary = rank[i2]
		var c2: Club = f2["club"]
		p._dato("%d.  %s" % [i2 + 1, c2.nombre],
			"%d  ·  va %d.º y se le esperaba %d.º" % [int(f2["nota"]), int(f2["puesto"]), int(f2["esperado"])],
			p.COL_ACENTO if bool(f2["mio"]) else Principal.COL_TEXTO, p._lista_redes)
	if mi_puesto > 8:
		var mp := p._texto(11, p.COL_ACENTO)
		mp.text = "Tú vas %d.º de %d." % [mi_puesto, rank.size()]
		p._lista_redes.add_child(mp)

func _atender_periodista(clave: String) -> void:
	var txt := p.mundo.prensa.atender(clave)
	if txt != "":
		p._escribir("[color=#8ea595]%s[/color]" % txt)
	p._refrescar()

func _comprar_medio(clave: String, c: Club) -> void:
	var problema := p.mundo.prensa.comprar_medio(clave, c)
	if problema != "":
		p._escribir("[color=#e05555]No se pudo comprar: %s.[/color]" % problema)
	p._refrescar()

func _comunicado(tipo: String) -> void:
	var txt := p.mundo.prensa.comunicado(tipo)
	if txt != "":
		p._escribir("[color=#8ea595]%s[/color]" % txt)
		p._anotar("Gabinete de comunicación", txt)
	p._refrescar()

func _pintar_correo() -> void:
	p._limpiar(p._lista_correo)
	var sin_leer := 0
	for it: Dictionary in p._bandeja:
		if not bool(it["leida"]):
			sin_leer += 1

	var filtros := HBoxContainer.new()
	filtros.add_theme_constant_override("separation", 6)
	p._lista_correo.add_child(filtros)
	var b_todo := Button.new()
	b_todo.text = "Todo (%d)" % p._bandeja.size()
	b_todo.toggle_mode = true
	b_todo.button_pressed = p._correo_filtro == "todo"
	b_todo.pressed.connect(func() -> void: p._correo_filtro = "todo"; _pintar_correo())
	filtros.add_child(b_todo)
	var b_nuevas := Button.new()
	b_nuevas.text = "Sin leer (%d)" % sin_leer
	b_nuevas.toggle_mode = true
	b_nuevas.button_pressed = p._correo_filtro == "nuevas"
	b_nuevas.pressed.connect(func() -> void: p._correo_filtro = "nuevas"; _pintar_correo())
	filtros.add_child(b_nuevas)
	if sin_leer > 0:
		var b_todas := Button.new()
		b_todas.text = "✅ Marcar todo como leído"
		b_todas.pressed.connect(func() -> void:
			for it2: Dictionary in p._bandeja:
				it2["leida"] = true
			_pintar_correo())
		filtros.add_child(b_todas)
	p._lista_correo.add_child(HSeparator.new())

	if p._bandeja.is_empty():
		var vacio := p._texto(12, Principal.COL_SUAVE)
		vacio.text = "Bandeja vacía. Los avisos del club van llegando aquí solos."
		p._lista_correo.add_child(vacio)
		return
	## Título en un botón plano -mismo truco que ya usa `_fila_jugador()` para
	## que la fila entera responda al clic sin inventar un control nuevo-, y el
	## cuerpo en una etiqueta aparte debajo: meter un VBoxContainer entero
	## dentro de un Button no es un patrón que ya exista en este proyecto y su
	## tamaño mínimo es el del texto, no el de sus hijos.
	var alguna := false
	for it3: Dictionary in p._bandeja:
		if p._correo_filtro == "nuevas" and bool(it3["leida"]):
			continue
		alguna = true
		var leida := bool(it3["leida"])
		var b := Button.new()
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = false
		b.text = "%s%s   ·   S%d/%d" % ["" if leida else "🔵 ", String(it3["titulo"]), int(it3["semana"]), int(it3["anio"])]
		b.add_theme_font_size_override("font_size", 13)
		b.add_theme_color_override("font_color", p._color_de_paleta(Principal.COL_SUAVE if leida else Principal.COL_TEXTO))
		b.pressed.connect(func() -> void: it3["leida"] = true; _pintar_correo())
		p._lista_correo.add_child(b)
		var cuerpo := p._texto(11, Principal.COL_SUAVE)
		cuerpo.text = String(it3["cuerpo"])
		cuerpo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_correo.add_child(cuerpo)
		p._lista_correo.add_child(HSeparator.new())
	if not alguna:
		var nada := p._texto(12, Principal.COL_SUAVE)
		nada.text = "No queda nada por leer."
		p._lista_correo.add_child(nada)

## `G.libro` del HTML, hecho pestaña: siete clases llevan meses -algunas desde
## que se escribieron- emitiendo una señal `movimiento(concepto, monto)` que
## nadie escuchaba. La caja SÍ se movía con cada una de ellas; lo único que
## faltaba era el papel que explica por qué. Ahora `Mundo.libro_financiero` las
## recoge todas y esto es lo único que hace falta para enseñarlo.
## EL BALANCE Y EL FLUJO DE CAJA, de `vContabilidad()`. El estado de resultados
## dice si el año sale bien; esto dice si el club AGUANTA. Son preguntas
## distintas: se puede ganar dinero al año y quedarse sin caja en marzo.
##
## El pasivo lo pone `Banco`: la suma de lo que se debe. Antes iba a cero con
## una nota que decía que el sistema de deuda no estaba portado; ya lo está,
## así que el patrimonio de aquí ya no miente.
## `vBanco()`: la deuda y el reloj de la liquidación. Es el único sistema del
## juego que puede terminar una partida sin perder un partido —doce semanas con
## la caja en rojo y el club se liquida—, así que el estado va arriba y grande.
## `vSponsor()`: la marca del pecho. Ofertas, contrato vigente y exigencia.
##
## Es el único ingreso grande del club que se DECIDE, y por eso tiene su bloque
## propio arriba del todo en Finanzas. Sin firmar no entra nada: la pantalla
## enseña tres cifras y quedarse sin marca también es una decisión, solo que una
## cara.
func _firmar_auspicio(i: int) -> void:
	var problema := p.mundo.auspicio.firmar(i)
	if problema != "":
		p._escribir("[color=#e05555]No se pudo firmar: %s.[/color]" % problema)
	p._refrescar()

func _lanzar_campana(clave: String) -> void:
	var problema := p.mundo.lanzar_campana(clave)
	if problema != "":
		p._escribir("[color=#e05555]No se pudo lanzar: %s.[/color]" % problema)
	else:
		var d := Finanzas.def_campana(clave)
		p._escribir("[color=#3fa06a][b]Campaña lanzada:[/b][/color] %s." % (String(d[1]) if not d.is_empty() else clave))
	p._refrescar()

func _pujar_marca() -> void:
	var r := p.mundo.pujar_por_marca()
	if r != "":
		p._escribir("[color=#c9a227]%s[/color]" % r)
		p._anotar("Guerra de marcas", r)
	p._refrescar()

func _pedir_credito(i: int, c: Club) -> void:
	var problema := p.mundo.banco.pedir(i, c)
	if problema != "":
		p._escribir("[color=#e05555]No hay crédito: %s.[/color]" % problema)
	p._refrescar()

func _prepagar(i: int, c: Club) -> void:
	var problema := p.mundo.banco.prepagar(i, c)
	if problema != "":
		p._escribir("[color=#e05555]No se pudo prepagar: %s.[/color]" % problema)
	else:
		p._escribir("[color=#4caf6d]Crédito cancelado.[/color] Te ahorras todos los intereses que quedaban.")
	p._refrescar()

func _renegociar(i: int) -> void:
	var problema := p.mundo.banco.renegociar(i)
	if problema != "":
		p._escribir("[color=#e05555]No se pudo renegociar: %s.[/color]" % problema)
	else:
		p._escribir("[color=#c9a227]Crédito renegociado.[/color] La cuota baja, el plazo se alarga y al final pagarás más.")
	p._refrescar()

func _emitir_bono(c: Club) -> void:
	var problema := p.mundo.banco.emitir_bono(c)
	if problema != "":
		p._escribir("[color=#e05555]No se pudo emitir: %s.[/color]" % problema)
	p._refrescar()
