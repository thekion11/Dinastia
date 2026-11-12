class_name TacticaSecciones
extends RefCounted
## LA PESTAÑA DE TÁCTICA. Salió de `pantalla_plantel_p2.gd` el 12-11 al partirla en CUATRO PANTALLAS (nota del dueño: menús subdivididos a
## pantalla completa, como el PES 2020), una por submenú (`p._secc_extra["Táctica"]`):
##   pizarra → el pizarrón, los presets y la formación        ordenes → las siete perillas, los interruptores, los roles y la moda de la era
##   balon   → el balón parado y el reglamento interno        once    → quién sale
## Otra sección = la página entera, en el orden de siempre.
const SECCIONES := ["pizarra", "ordenes", "balon", "once"]

static func pintar(p: Principal, pantalla: Object, c: Club) -> void:
	p._limpiar(p._lista_tactica)
	var secc := String(p._secc_extra.get("Táctica", "pizarra"))
	var todo := not SECCIONES.has(secc)
	if not todo:
		var nivel := [Idiomas.t("Defensiva"), Idiomas.t("Equilibrada"), Idiomas.t("Ofensiva")]
		p._lista_tactica.add_child(CifrasClave.banda([
			[Idiomas.t("Formación"), c.tactica.formacion, p.COL_ACENTO],
			[Idiomas.t("Mentalidad"), String(nivel[clampi(c.tactica.mentalidad, 0, 2)]), Principal.COL_TEXTO],
			[Idiomas.t("El once"), Idiomas.t("%d de 11") % c.once_elegido.size() if c.once_elegido.size() > 0 else Idiomas.t("automático"), Principal.COL_ORO]],
			Principal.COL_SUAVE))
	if todo or secc == "pizarra":
		_pizarra(p, pantalla, c)
	if todo or secc == "ordenes":
		_ordenes(p, c)
		pantalla._pintar_roles_tacticos(c)
	if todo or secc == "balon":
		pantalla._pintar_balon_parado(c)
		_normas(p)
	if todo or secc == "once":
		_once(p, c)
	if todo or secc == "ordenes":
		## La moda de la era y la tabla de lo que te funciona: lectura, no mandos.
		pantalla._pintar_moda_tactica(c)

static func _pizarra(p: Principal, pantalla: Object, c: Club) -> void:
	## El pizarrón va PRIMERO: es lo que se viene a mirar aquí. Las perillas y los
	## interruptores se tocan una vez cada varias semanas; el once se mira cada
	## domingo.
	pantalla._pintar_pizarron(c)
	PresetsTacticaUI.pintar(p, c)   ## presets de pizarra con nombre (fila 382)
	pantalla._boton_deshacer(c)
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("FORMACIÓN")
	p._lista_tactica.add_child(t)
	var forms: Dictionary = Datos.tabla("FORMS")
	var fila_f: HBoxContainer = null
	var i_f := 0
	for nombre_f: String in forms.keys():
		if i_f % 5 == 0:
			fila_f = HBoxContainer.new()
			fila_f.add_theme_constant_override("separation", 4)
			p._lista_tactica.add_child(fila_f)
		var bf := Button.new()
		bf.text = nombre_f
		bf.toggle_mode = true
		bf.button_pressed = c.tactica.formacion == nombre_f
		bf.add_theme_font_size_override("font_size", 11)
		bf.pressed.connect(func() -> void:
			DeshacerTactica.apuntar(c)
			c.tactica.formacion = nombre_f
			## Cambiar de dibujo invalida el once elegido: las ranuras son otras.
			c.limpiar_once()
			p._refrescar())
		fila_f.add_child(bf)
		i_f += 1
	EditorFormacion.botones(p, c)   ## formaciones propias, como el «Editar posición» del PES (10-11)
	p._lista_tactica.add_child(HSeparator.new())


static func _ordenes(p: Principal, c: Club) -> void:
	## Las siete perillas, con los mismos tres niveles que usa el partido en vivo.
	var perillas := [
		["Mentalidad", "mentalidad", ["Defensiva", "Equilibrada", "Ofensiva"]],
		["Presión", "presion", ["Baja", "Media", "Alta"]],
		["Ritmo", "ritmo", ["Lento", "Medio", "Alto"]],
		["Línea", "linea", ["Baja", "Media", "Adelantada"]],
		["Amplitud", "amplitud", ["Estrecha", "Media", "Abierta"]],
		## 3-11 (orden 22 U6): las dos que el partido ya usaba y la pizarra no enseñaba.
		["Verticalidad", "verticalidad", ["Paciente", "Mixta", "Vertical"]],
		["Tras perder el balón", "tras_perdida", ["Replegar", "Equilibrio", "Contrapresión"]],
	]
	var tp := p._texto(11, Principal.COL_SUAVE)
	tp.text = Idiomas.t("PIZARRA")
	p._lista_tactica.add_child(tp)
	for p_local: Array in perillas:
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_tactica.add_child(fila)
		var et := p._texto(12, Principal.COL_SUAVE)
		et.text = String(p_local[0])
		et.custom_minimum_size = Vector2(90, 0)
		fila.add_child(et)
		var prop := String(p_local[1])
		var opciones: Array = p_local[2]
		for n in opciones.size():
			var b := Button.new()
			b.text = String(opciones[n])
			b.toggle_mode = true
			b.button_pressed = int(c.tactica.get(prop)) == n
			b.add_theme_font_size_override("font_size", 11)
			var valor := n
			b.pressed.connect(func() -> void:
				DeshacerTactica.apuntar(c)
				c.tactica.set(prop, valor)
				p._refrescar())
			fila.add_child(b)

	## Los cuatro interruptores. Hasta esta tanda tampoco se guardaban.
	var interruptores := [
		["Salida corta", "salida_corta"], ["Marca al hombre", "marca_al_hombre"],
		["Trampa del fuera de juego", "fuera_de_juego"], ["Tiro lejano", "tiro_lejano"],
	]
	for it: Array in interruptores:
		var fila2 := HBoxContainer.new()
		fila2.add_theme_constant_override("separation", 6)
		p._lista_tactica.add_child(fila2)
		var et2 := p._texto(12, Principal.COL_SUAVE)
		et2.text = String(it[0])
		et2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila2.add_child(et2)
		var prop2 := String(it[1])
		var b2 := Button.new()
		b2.text = "SÍ" if bool(c.tactica.get(prop2)) else "NO"
		b2.add_theme_font_size_override("font_size", 11)
		b2.pressed.connect(func() -> void:
			DeshacerTactica.apuntar(c)
			c.tactica.set(prop2, not bool(c.tactica.get(prop2)))
			p._refrescar())
		fila2.add_child(b2)
	p._lista_tactica.add_child(HSeparator.new())


static func _normas(p: Principal) -> void:
	## `vNormas()` del HTML: el reglamento interno. Va aquí, en Táctica, porque
	## son decisiones del mismo tipo -cómo se dirige al grupo- y ninguna de las
	## dos daba para pestaña propia.
	var tn := p._texto(11, Principal.COL_SUAVE)
	tn.text = Idiomas.t("REGLAMENTO INTERNO")
	p._lista_tactica.add_child(tn)
	for norma: Array in Mundo.NORMAS_DEF:
		var clave := String(norma[0])
		var activa := bool(p.mundo.normas.get(clave, false))
		var fila_n := HBoxContainer.new()
		fila_n.add_theme_constant_override("separation", 6)
		p._lista_tactica.add_child(fila_n)
		var en := p._texto(12, Principal.COL_TEXTO if activa else Principal.COL_SUAVE)
		en.text = String(norma[1])
		en.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila_n.add_child(en)
		var bn := Button.new()
		bn.text = "SÍ" if activa else "NO"
		bn.add_theme_font_size_override("font_size", 11)
		bn.pressed.connect(func() -> void:
			p.mundo.normas[clave] = not bool(p.mundo.normas.get(clave, false))
			p._refrescar())
		fila_n.add_child(bn)
		var dn := p._texto(11, Principal.COL_SUAVE)
		dn.text = String(norma[2])
		dn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_tactica.add_child(dn)
	p._lista_tactica.add_child(HSeparator.new())


static func _once(p: Principal, c: Club) -> void:
	## EL ONCE. Se marca con un botón por jugador: los once primeros marcados
	## salen. Si el once no llega a once o alguien se lesiona, `Club.once()` se
	## vuelve al automático solo -su propia red de seguridad-, así que aquí no
	## hace falta impedir nada, solo contarlo.
	var to := p._texto(11, Principal.COL_SUAVE)
	to.text = Idiomas.t("EL ONCE  ·  %d de 11 elegidos%s") % [
		c.once_elegido.size(),
		"" if c.once_elegido.size() == 11 else Idiomas.t("   (con menos de once manda el automático)")]
	p._lista_tactica.add_child(to)
	## ALINEACIÓN INDEBIDA A LA VISTA (M-246, 20-10): si el once elegido se salta
	## la ley de cupos del país, se avisa aquí, en la pizarra, antes del partido
	## (y no solo con la multa de la federación después).
	var manual: Array[Jugador] = c._once_manual()
	var infr: Array = LeyesPais.infracciones_once(c, manual) if manual.size() == 11 else []
	if not infr.is_empty():
		var partes: Array[String] = []
		for i: Dictionary in infr:
			partes.append(String(i["texto"]))
		var av := p._texto(12, Color(1.0, 0.45, 0.35))
		av.text = Idiomas.t("⚠ ALINEACIÓN INDEBIDA (ley de %s): %s") % [c.pais, "; ".join(partes)] + "\n" + Idiomas.t(
			"→ el ayudante cambiará a quien haga falta (cumples la ley)" if c.ley_politica != "incumplir"
			else "→ saldrá así y la federación multará (decidiste incumplir)")
		av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_tactica.add_child(av)
	var fila_b := HBoxContainer.new()
	fila_b.add_theme_constant_override("separation", 6)
	p._lista_tactica.add_child(fila_b)
	p._boton("Que lo arme el ayudante", func() -> void:
		DeshacerTactica.apuntar(c)
		c.limpiar_once()
		p._refrescar(), fila_b)
	p._boton("Vaciar", func() -> void:
		DeshacerTactica.apuntar(c)
		c.once_elegido.clear()
		p._refrescar(), fila_b)

	var g := GridContainer.new()
	CebraRejilla.poner(g)
	g.columns = 7
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 8)
	p._lista_tactica.add_child(g)
	for enc in ["", "", "NOMBRE", "POS", "MED", "FORMA", "ESTADO"]:
		p._celda(g, enc, Principal.COL_SUAVE, enc in ["MED", "FORMA"], 11)
	var orden := c.plantilla.duplicate()
	orden.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	for j: Jugador in orden:
		var dentro := c.once_elegido.has(j.id)
		var b := Button.new()
		b.text = "✔" if dentro else "＋"
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = not j.disponible() and not dentro
		b.pressed.connect(func() -> void:
			DeshacerTactica.apuntar(c)
			if dentro:
				c.once_elegido.erase(j.id)
			elif c.once_elegido.size() < 11:
				c.once_elegido.append(j.id)
			p._refrescar())
		g.add_child(b)
		g.add_child(p._retrato(j, Principal.RETRATO_FILA))
		var col := p.COL_ACENTO if dentro else (Principal.COL_ROJO if not j.disponible() else Principal.COL_TEXTO)
		p._celda(g, j.nombre, col, false, 12)
		p._celda(g, j.pos_e, Principal.COL_SUAVE, false, 11)
		p._celda(g, str(j.ovr), col, true, 12)
		p._celda(g, str(j.forma), Principal.COL_SUAVE, true, 11)
		var estado := "listo"
		if j.lesion > 0:
			estado = "lesionado %d sem" % j.lesion
		elif j.suspension > 0:
			estado = "sancionado %d" % j.suspension
		p._celda(g, estado, Principal.COL_ROJO if not j.disponible() else Principal.COL_SUAVE, false, 11)
