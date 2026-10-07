class_name PanelClubDentro
extends RefCounted
## "EL CLUB POR DENTRO" (GENTE → El club por dentro): vestuario, sala de
## prensa, palco, app y web del club. Sacado de `principal.gd` el 25-9-2026 con
## el patrón de `FichaJugadorAcciones`: clase estática que pinta una vez por
## refresco, con lo que era de `Principal` pasado por parámetro -el `_texto()`
## de siempre (paleta, daltonismo, escala), `_miles()`, `_escribir()` para los
## errores y `_refrescar()` como `al_cambiar`-. Los tres botones de acción
## (`_elegir_espacio`, `_lanzar_app`, `_lanzar_web`) solo se usaban aquí y se
## vinieron con la pantalla.

static func pintar(raiz: VBoxContainer, c: Club, mundo: Mundo, texto: Callable, colores: Dictionary,
		miles: Callable, escribir: Callable, al_cambiar: Callable) -> void:
	var cd := mundo.club_dentro
	if cd == null:
		return
	raiz.add_child(HSeparator.new())
	var t: Label = texto.call(11, colores["suave"])
	t.text = "🚪 EL CLUB POR DENTRO"
	raiz.add_child(t)
	var intro: Label = texto.call(10, colores["suave"])
	intro.text = "Lo que no sale en la tabla: dónde se cambian, dónde te preguntan y dónde se sientan los que firman los cheques."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	raiz.add_child(intro)

	for bloque in [
		["vestuario", "🚪 VESTUARIO", ClubDentro.VESTUARIO, cd.vestuario,
			"Un vestuario cuidado sostiene la moral del plantel semana a semana."],
		["prensa", "🎙️ SALA DE PRENSA", ClubDentro.SALA_PRENSA, cd.sala_prensa,
			"Cuanto mejor la sala, menos se te pega el ruido: amortigua la funa."],
		["palco", "🥂 PALCO PRESIDENCIAL", ClubDentro.PALCO, cd.palco,
			"Donde se cierran los patrocinios. Un buen palco mejora lo que te ofrecen."],
	]:
		var que := String(bloque[0])
		var lista: Array = bloque[2]
		var actual := String(bloque[3])
		var tb: Label = texto.call(11, colores["acento"])
		tb.text = String(bloque[1])
		raiz.add_child(tb)
		var db: Label = texto.call(10, colores["suave"])
		db.text = String(bloque[4])
		db.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		raiz.add_child(db)
		for f: Array in lista:
			var clave := String(f[0])
			var tengo := clave == actual
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 6)
			raiz.add_child(fila)
			var nom: Label = texto.call(12, colores["verde"] if tengo else colores["texto"])
			nom.text = "%s%s" % ["✔  " if tengo else "     ", String(f[1])]
			nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			nom.clip_text = true
			nom.tooltip_text = String(f[2])
			fila.add_child(nom)
			var bono: Label = texto.call(11, colores["oro"])
			bono.text = "+%d" % int(f[4])
			bono.custom_minimum_size = Vector2(34, 0)
			fila.add_child(bono)
			var b := Button.new()
			b.text = "Puesto" if tengo else (Eco.dinero(Eco.escalar(float(f[3]), float(c.rep))) if int(f[3]) > 0 else "gratis")
			b.add_theme_font_size_override("font_size", 11)
			b.disabled = tengo
			b.custom_minimum_size = Vector2(96, 0)
			b.pressed.connect(func() -> void: _elegir_espacio(mundo, que, clave, c, escribir, al_cambiar))
			fila.add_child(b)

	var td: Label = texto.call(11, colores["acento"])
	td.text = "📱 LO DIGITAL"
	raiz.add_child(td)
	var dd: Label = texto.call(10, colores["suave"])
	dd.text = "Crecen solas cada semana -más rápido si vienes ganando en liga- y lo que dejan entra directo a la caja."
	dd.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	raiz.add_child(dd)
	## App
	if not cd.app.is_empty():
		var fa := HBoxContainer.new()
		fa.add_theme_constant_override("separation", 6)
		raiz.add_child(fa)
		var na: Label = texto.call(12, colores["verde"])
		na.text = "✔  %s" % String(cd.app["nombre"])
		na.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		na.clip_text = true
		fa.add_child(na)
		var ra: Label = texto.call(11, colores["suave"])
		ra.text = "%s subs" % miles.call(int(cd.app["subs"]))
		ra.custom_minimum_size = Vector2(96, 0)
		fa.add_child(ra)
	else:
		var ta: Label = texto.call(11, colores["texto"])
		ta.text = "📱 App oficial del club"
		raiz.add_child(ta)
		var fila_a := HBoxContainer.new()
		fila_a.add_theme_constant_override("separation", 6)
		raiz.add_child(fila_a)
		var campo_a := LineEdit.new()
		campo_a.placeholder_text = "%s Oficial" % c.nombre
		campo_a.max_length = 28
		campo_a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila_a.add_child(campo_a)
		var b_a := Button.new()
		b_a.text = Eco.dinero(Eco.escalar(ClubDentro.COSTE_APP, float(c.rep)))
		b_a.add_theme_font_size_override("font_size", 11)
		b_a.custom_minimum_size = Vector2(96, 0)
		b_a.pressed.connect(func() -> void: _lanzar_app(mundo, campo_a.text, c, escribir, al_cambiar))
		fila_a.add_child(b_a)
	## Web
	if not cd.web.is_empty():
		var fw := HBoxContainer.new()
		fw.add_theme_constant_override("separation", 6)
		raiz.add_child(fw)
		var nw: Label = texto.call(12, colores["verde"])
		nw.text = "✔  %s" % String(cd.web["dominio"])
		nw.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nw.clip_text = true
		fw.add_child(nw)
		var rw: Label = texto.call(11, colores["suave"])
		rw.text = "%s vis." % miles.call(int(cd.web["visitas"]))
		rw.custom_minimum_size = Vector2(96, 0)
		fw.add_child(rw)
	else:
		var tw: Label = texto.call(11, colores["texto"])
		tw.text = "🌐 Sitio web del club"
		raiz.add_child(tw)
		var fila_w := HBoxContainer.new()
		fila_w.add_theme_constant_override("separation", 6)
		raiz.add_child(fila_w)
		var campo_w := LineEdit.new()
		campo_w.placeholder_text = "%s.cl" % c.nombre.to_lower().replace(" ", "")
		campo_w.max_length = 30
		campo_w.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila_w.add_child(campo_w)
		var b_w := Button.new()
		b_w.text = Eco.dinero(Eco.escalar(ClubDentro.COSTE_WEB, float(c.rep)))
		b_w.add_theme_font_size_override("font_size", 11)
		b_w.custom_minimum_size = Vector2(96, 0)
		b_w.pressed.connect(func() -> void: _lanzar_web(mundo, campo_w.text, c, escribir, al_cambiar))
		fila_w.add_child(b_w)

	## EL UNIFORME DEL CUERPO TÉCNICO. No mueve un número y sale en el banquillo
	## todos los domingos: es de esas cosas que hacen que el club sea tuyo.
	raiz.add_child(HSeparator.new())
	var tct: Label = texto.call(11, colores["acento"])
	tct.text = "👔 UNIFORME DEL CUERPO TÉCNICO"
	raiz.add_child(tct)
	var muestra := TextureRect.new()
	muestra.texture = Jersey.textura_procedural(cd.color_ct1(c), cd.color_ct2(c), "liso", 72)
	muestra.custom_minimum_size = Vector2(72, 72)
	muestra.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	muestra.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	raiz.add_child(muestra)
	var rej_ct := GridContainer.new()
	rej_ct.columns = 3
	rej_ct.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	raiz.add_child(rej_ct)
	for r: Array in ClubDentro.CT_ROPA:
		var clave_r := String(r[0])
		var b_r := Button.new()
		b_r.text = String(r[1])
		b_r.add_theme_font_size_override("font_size", 11)
		b_r.clip_text = true
		b_r.toggle_mode = true
		b_r.button_pressed = cd.ct_ropa == clave_r
		b_r.custom_minimum_size = Vector2(90, 0)
		b_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b_r.pressed.connect(func() -> void:
			cd.vestir(clave_r)
			al_cambiar.call())
		rej_ct.add_child(b_r)
	var fila_col := HBoxContainer.new()
	fila_col.add_theme_constant_override("separation", 6)
	raiz.add_child(fila_col)
	for par_col: Array in [["Principal", cd.color_ct1(c), 1], ["Secundario", cd.color_ct2(c), 2]]:
		var cual: int = par_col[2]
		var l_col: Label = texto.call(11, colores["suave"])
		l_col.text = String(par_col[0])
		l_col.custom_minimum_size = Vector2(72, 0)
		fila_col.add_child(l_col)
		var pk := ColorPickerButton.new()
		pk.color = Color(String(par_col[1]))
		pk.custom_minimum_size = Vector2(56, 26)
		pk.color_changed.connect(func(nuevo: Color) -> void:
			if cual == 1:
				cd.ct_color1 = "#" + nuevo.to_html(false)
			else:
				cd.ct_color2 = "#" + nuevo.to_html(false))
		fila_col.add_child(pk)
	var b_igual := Button.new()
	b_igual.text = "Igualar a los colores del club"
	b_igual.add_theme_font_size_override("font_size", 11)
	b_igual.pressed.connect(func() -> void:
		cd.ct_color1 = ""
		cd.ct_color2 = ""
		al_cambiar.call())
	raiz.add_child(b_igual)

	## LA FRASE DE LA PARED. El HTML prometía que "se lee en el túnel antes de
	## cada partido" y no salía en ninguna pantalla más. Aquí sale de verdad en
	## la previa, que es el único sitio donde esa promesa significa algo.
	raiz.add_child(HSeparator.new())
	var tfr: Label = texto.call(11, colores["acento"])
	tfr.text = "🧱 FRASE EN LA PARED DEL VESTUARIO"
	raiz.add_child(tfr)
	var campo_fr := LineEdit.new()
	campo_fr.text = cd.frase
	campo_fr.placeholder_text = "Lo que quieres que lean antes de salir"
	campo_fr.max_length = ClubDentro.FRASE_MAX
	campo_fr.add_theme_font_size_override("font_size", 12)
	campo_fr.text_submitted.connect(func(t: String) -> void:
		cd.escribir_frase(t)
		al_cambiar.call())
	campo_fr.focus_exited.connect(func() -> void:
		cd.escribir_frase(campo_fr.text))
	raiz.add_child(campo_fr)
	var vista_fr: Label = texto.call(13, Color(cd.color_ct2(c)) if cd.frase != "" else colores["suave"])
	vista_fr.text = "«%s»" % cd.frase if cd.frase != "" else "Se lee en el túnel antes de cada partido."
	vista_fr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vista_fr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	raiz.add_child(vista_fr)

static func _elegir_espacio(mundo: Mundo, que: String, clave: String, c: Club, escribir: Callable, al_cambiar: Callable) -> void:
	var problema := mundo.club_dentro.elegir(que, clave, c)
	if problema != "":
		escribir.call("[color=#e05555]No se pudo: %s.[/color]" % problema)
	al_cambiar.call()

static func _lanzar_app(mundo: Mundo, nombre: String, c: Club, escribir: Callable, al_cambiar: Callable) -> void:
	var problema := mundo.club_dentro.lanzar_app(c, nombre, mundo.anio)
	if problema != "":
		escribir.call("[color=#e05555]No se pudo: %s.[/color]" % problema)
	al_cambiar.call()

static func _lanzar_web(mundo: Mundo, dominio: String, c: Club, escribir: Callable, al_cambiar: Callable) -> void:
	var problema := mundo.club_dentro.lanzar_web(c, dominio, mundo.anio)
	if problema != "":
		escribir.call("[color=#e05555]No se pudo: %s.[/color]" % problema)
	al_cambiar.call()
