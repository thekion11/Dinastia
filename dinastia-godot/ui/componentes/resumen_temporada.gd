class_name ResumenTemporada
extends EventoPantallaCompleta
## LA PANTALLA ÚNICA DEL FINAL DE TEMPORADA (orden del dueño, 9-11; hecha el 10-11), a pantalla completa como todos los eventos. Sale al pulsar
## «Temporada siguiente», con el orden del dueño: fin de liga → partido de despedida → gala (dentro del cierre) → este resumen → nueva temporada
## (el documental de la temporada se proyecta después). Reúne lo que antes eran líneas sueltas del registro y avisos: el campeón y tu puesto,
## la copa, el continental, ascensos y descensos de tu país, los premios de la gala y el veredicto de la directiva.
## `foto` = `CierreTorneos.foto(mundo)` tomada ANTES del cierre; `resumen` = lo que devuelve `Mundo.nueva_temporada()`.
const ANCHO_TARJETA := 360

static func mostrar(pr: Node, foto: Dictionary, resumen: Dictionary) -> ResumenTemporada:
	var e := ResumenTemporada.new()
	e._montar_base(pr)
	e._rellenar(foto, resumen)
	return e

## Los datos que pinta la pantalla, en limpio (también los usa la prueba sin pantalla).
static func datos(foto: Dictionary, resumen: Dictionary) -> Dictionary:
	var d := {"anio": int(foto.get("anio", 0)), "liga": String(foto.get("liga", "")), "puesto": int(foto.get("puesto", 0)),
		"equipos": int(foto.get("equipos", 0)), "puntos": int(foto.get("puntos", 0))}
	var mio: Club = foto.get("club")
	d["club"] = mio
	d["campeon"] = null
	for c: Dictionary in resumen.get("campeones", []):
		if (c["liga"] as Liga).nombre == d["liga"]:
			d["campeon"] = c["club"]
	d["copa"] = String(foto.get("copa", ""))
	d["copa_campeon"] = foto.get("copa_campeon")
	d["conti"] = String(foto.get("conti", ""))
	d["conti_campeon"] = foto.get("conti_campeon")
	var pais := mio.pais if mio != null else ""
	var suben: Array = []
	var bajan: Array = []
	for c2: Variant in resumen.get("suben", []):
		if c2 is Club and (c2 as Club).pais == pais:
			suben.append(c2)
	for c3: Variant in resumen.get("bajan", []):
		if c3 is Club and (c3 as Club).pais == pais:
			bajan.append(c3)
	d["suben"] = suben
	d["bajan"] = bajan
	var acta: Dictionary = resumen.get("logros", {})
	d["premios"] = (acta.get("ganados", []) as Array).duplicate()
	d["pichichi"] = String(acta.get("pichichi", ""))
	d["joven"] = String(acta.get("joven", ""))
	d["directiva"] = resumen.get("directiva", {})
	d["torneos_cerrados"] = resumen.get("torneos_cerrados", [])
	return d

func _rellenar(foto: Dictionary, resumen: Dictionary) -> void:
	var d := datos(foto, resumen)
	## (12-11) En el teléfono de pie (lienzo de 540 px de ancho) todo va en UNA columna: a dos columnas la mitad derecha quedaba fuera.
	var de_pie := EscalaMovil.es_vertical()
	_centro.custom_minimum_size = Vector2(ANCHO_DE_PIE if de_pie else ANCHO_TARJETA * 2 + 24, 0)
	_centro.add_theme_constant_override("separation", 8)   ## compacto: que el botón quepa a 1080 px con la franja del patrocinador
	var arriba: BoxContainer = VBoxContainer.new() if de_pie else HBoxContainer.new()
	arriba.alignment = BoxContainer.ALIGNMENT_CENTER
	arriba.add_theme_constant_override("separation", 4 if de_pie else 18)
	arriba.add_child(etiqueta("%s · %d" % [Idiomas.t("FIN DE TEMPORADA"), int(d["anio"])], 15, Tema.SUAVE, false, false))
	var pat: Dictionary = foto.get("patrocinador", {})
	if String(pat.get("marca", "")) != "":   ## (10-11, idea del PES) el patrocinador oficial, como en sus pantallas de temporada
		arriba.add_child(_patrocinador(String(pat["marca"]), String(pat.get("color", "#ffffff"))))
	_centro.add_child(arriba)
	_centro.add_child(etiqueta("🏆 " + Idiomas.t("Resumen de la temporada"), 24 if de_pie else 30, Tema.ORO, true, false))
	var cabecera := _cabecera(d)
	_centro.add_child(cabecera)
	var rejilla := GridContainer.new()
	rejilla.columns = 1 if de_pie else 2
	rejilla.add_theme_constant_override("h_separation", 24)
	rejilla.add_theme_constant_override("v_separation", 12)
	_centro.add_child(rejilla)
	rejilla.add_child(_tarjeta_torneo("🏅 " + (String(d["copa"]) if d["copa"] != "" else Idiomas.t("Copa")), d["copa_campeon"], d["club"]))
	rejilla.add_child(_tarjeta_torneo("🌎 " + (String(d["conti"]) if d["conti"] != "" else Idiomas.t("Continental")), d["conti_campeon"], d["club"]))
	rejilla.add_child(_tarjeta_movimientos(d))
	rejilla.add_child(_tarjeta_premios(d))
	var veredicto := _veredicto(d["directiva"])
	_centro.add_child(veredicto)
	var seguir := boton("▶ " + Idiomas.t("Empezar la temporada %d") % (int(d["anio"]) + 1), true)
	seguir.pressed.connect(_cerrar)
	fijar_abajo(seguir)   ## (12-11) siempre a la vista: con los objetivos secundarios quedaba bajo el pliegue
	## (12-11) Entrada por tarjetas: tu club, las cuatro tarjetas, el veredicto de la directiva y, al final, el botón.
	entrada_en_cascada([cabecera] + rejilla.get_children() + [veredicto, seguir])

func _cerrar() -> void:
	var t := create_tween()
	t.tween_property(_raiz, "modulate:a", 0.0, 0.3)
	t.tween_callback(func() -> void: terminado.emit())

func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_cerrar()

## Tu club y tu puesto, y a su lado el campeón de tu liga.
func _cabecera(d: Dictionary) -> Control:
	var de_pie := EscalaMovil.es_vertical()
	var fila: BoxContainer = VBoxContainer.new() if de_pie else HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 10 if de_pie else 40)
	var mio: Club = d["club"]
	var campeon: Club = d["campeon"]
	var puesto := int(d["puesto"])
	var linea := "%d.º / %d · %d pts" % [puesto, int(d["equipos"]), int(d["puntos"])] if puesto > 0 else "—"
	fila.add_child(_bloque_club(mio, Idiomas.t("Tu club"), linea, Tema.ORO if puesto == 1 else Tema.TEXTO))
	if campeon != null and campeon != mio:
		fila.add_child(_bloque_club(campeon, String(d["liga"]), "👑 " + Idiomas.t("Campeón de liga"), Tema.ORO))
	elif campeon == mio and mio != null:
		fila.add_child(etiqueta("👑 " + Idiomas.t("¡CAMPEÓN DE LIGA!"), 24 if de_pie else 30, Tema.ORO, true, false))
	return fila

func _bloque_club(c: Club, rotulo: String, linea: String, color: Color, alto := 84) -> Control:
	var caja := HBoxContainer.new()
	caja.add_theme_constant_override("separation", 12)
	if c != null:
		var tr := TextureRect.new()
		tr.texture = Escudo.textura(c, alto)
		tr.custom_minimum_size = Vector2(alto, alto)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		caja.add_child(tr)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(etiqueta(rotulo, 13, Tema.SUAVE, false, false))
	col.add_child(etiqueta(c.nombre if c != null else "—", 22 if alto > 64 else 18, Tema.TEXTO, false, false))
	col.add_child(etiqueta(linea, 17, color, false, false))
	caja.add_child(col)
	return caja

func _tarjeta(titulo: String) -> Array:
	var panel := PanelContainer.new()
	var est := Tema.caja(Color(Tema.TARJETA, 0.92), Tema.RADIO_GRANDE, Color(Tema.ORO, 0.35))
	est.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", est)
	panel.custom_minimum_size = Vector2(ANCHO_DE_PIE if EscalaMovil.es_vertical() else ANCHO_TARJETA, 110)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)
	col.add_child(etiqueta(titulo, 18, Tema.ORO, false))
	return [panel, col]

func _tarjeta_torneo(titulo: String, campeon: Variant, mio: Club) -> Control:
	var t := _tarjeta(titulo)
	var col: VBoxContainer = t[1]
	if campeon is Club:
		var c := campeon as Club
		col.add_child(_bloque_club(c, Idiomas.t("Campeón"), "👑 " + Idiomas.t("¡Es tu club!") if c == mio else "", Tema.ORO, 56))
	else:
		col.add_child(etiqueta(Idiomas.t("No se disputó esta temporada."), 15, Tema.SUAVE, false))
	return t[0]

func _tarjeta_movimientos(d: Dictionary) -> Control:
	var t := _tarjeta("⬆⬇ " + Idiomas.t("Ascensos y descensos"))
	var col: VBoxContainer = t[1]
	var mio: Club = d["club"]
	for par: Array in [[d["suben"], "⬆ ", Tema.BIEN], [d["bajan"], "⬇ ", Tema.MAL]]:
		var nombres: Array[String] = []
		for c: Club in par[0]:
			nombres.append(("[%s]" % c.nombre) if c == mio else c.nombre)
		if not nombres.is_empty():
			col.add_child(etiqueta(String(par[1]) + ", ".join(nombres), 15, par[2], false))
	if col.get_child_count() == 1:
		col.add_child(etiqueta(Idiomas.t("Sin cambios de categoría en tu país."), 15, Tema.SUAVE, false))
	elif (d["suben"] as Array).has(mio):
		col.add_child(etiqueta("¡" + Idiomas.t("ASCENSO") + "!", 20, Tema.BIEN, false))
	elif (d["bajan"] as Array).has(mio):
		col.add_child(etiqueta(Idiomas.t("DESCENSO"), 20, Tema.MAL, false))
	return t[0]

func _tarjeta_premios(d: Dictionary) -> Control:
	var t := _tarjeta("🎖️ " + Idiomas.t("Gala de premios"))
	var col: VBoxContainer = t[1]
	if String(d["pichichi"]) != "":
		col.add_child(etiqueta("⚽ " + Idiomas.t("Goleador:") + " " + String(d["pichichi"]), 14, Tema.TEXTO, false))
	if String(d["joven"]) != "":
		col.add_child(etiqueta("🌱 " + Idiomas.t("Mejor joven:") + " " + String(d["joven"]), 14, Tema.TEXTO, false))
	var premios: Array = d["premios"]
	if premios.is_empty():
		col.add_child(etiqueta(Idiomas.t("Tu club no se llevó premios este año."), 14, Tema.SUAVE, false))
	for pm: Variant in premios:
		col.add_child(etiqueta("★ " + String(pm), 14, Tema.ORO, false))
	return t[0]

## El veredicto de la directiva, lo último y con su color: es lo único del cierre que puede acabar con la partida.
func _veredicto(v: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var bien := bool(v.get("cumplido", false))
	var color := Tema.BIEN if bien else Tema.MAL
	var est := Tema.caja(Color(color, 0.16), Tema.RADIO_GRANDE, color)
	est.set_border_width_all(2)
	est.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", est)
	var col := VBoxContainer.new()
	panel.add_child(col)
	if v.is_empty():
		col.add_child(etiqueta("🏛️ " + Idiomas.t("La directiva no ha dado veredicto."), 17, Tema.SUAVE))
		return panel
	var titulo := Idiomas.t("Objetivo CUMPLIDO") if bien else Idiomas.t("Objetivo FALLADO")
	col.add_child(etiqueta("🏛️ %s: %s" % [titulo, String(v.get("objetivo", ""))], 20, color))
	col.add_child(etiqueta("%s %d.º · %s %d.º · %s %d" % [Idiomas.t("Acabaste"), int(v.get("puesto", 0)), Idiomas.t("te pedían"),
		int(v.get("meta", 0)), Idiomas.t("confianza"), int(v.get("confianza", 0))], 16, Tema.TEXTO))
	## (10-11) Objetivos por club: los secundarios que se juzgaron (con su peso en la confianza) y el proyecto a 3 temporadas si terminó.
	for o: Dictionary in v.get("secundarios", []):
		if bool(o.get("aplica", false)):
			var ok := bool(o.get("cumplido", false))
			col.add_child(etiqueta("%s %s (%+d)" % ["✔" if ok else "✘", Idiomas.t(String(o.get("texto", ""))), ObjetivosCierre.delta_de(int(o.get("peso", 0)), ok)], 15, Tema.BIEN if ok else Tema.MAL))
	var pr: Dictionary = v.get("proyecto", {})
	if not pr.is_empty():
		var ok2 := bool(pr.get("cumplido", false))
		col.add_child(etiqueta("%s %s: %s (%+d)" % ["🏁", Idiomas.t("Proyecto"), Idiomas.t(String(pr.get("texto", ""))), int(pr.get("delta", 0))], 16, Tema.BIEN if ok2 else Tema.MAL))
	if bool(v.get("despedido", false)):
		col.add_child(etiqueta(Idiomas.t("ESTÁS DESPEDIDO.") + " " + Idiomas.t("Elige otro club para empezar de nuevo."), 18, Tema.MAL))
	return panel

## La franja del patrocinador oficial: el rótulo y el logo de la marca del pecho (`SponsorKit`).
func _patrocinador(marca: String, hex: String) -> Control:
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 12)
	fila.add_child(etiqueta(Idiomas.t("Patrocinador oficial"), 13, Tema.SUAVE, false, false))
	var fondo := Color(0.1, 0.12, 0.11)
	var tr := TextureRect.new()
	tr.texture = SponsorKit.textura(marca, hex, SponsorKit.color_letras(hex, fondo))
	tr.custom_minimum_size = Vector2(120, 26)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fila.add_child(tr)
	return fila
