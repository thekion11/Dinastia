class_name PalmaresMundoUI
extends EventoPantallaCompleta
## EL PALMARÉS DEL MUNDO (10-11, encargo del dueño, punto 1 «torneos»): los campeones de las ligas, copas y supercopas de TODOS los
## países (`Mundo.palmares_mundo`, lo apunta `CopasMundo`) y los de los torneos de selecciones, a pantalla completa, por temporada
## (lo más nuevo arriba) y con un filtro por país. Se abre desde Competiciones › Palmarés del mundo.
static func abrir(pr: Principal) -> PalmaresMundoUI:
	var e := PalmaresMundoUI.new()
	e.paleta_noche = true
	e._montar_base(pr)
	e._pintar(pr, "")
	return e

func _pintar(pr: Principal, pais: String) -> void:
	for h in _centro.get_children():
		h.queue_free()
	var m := pr.mundo
	_centro.add_child(etiqueta("🌍 " + Idiomas.t("PALMARÉS DEL MUNDO"), 34, Color.WHITE, true, false))
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 10)
	_centro.add_child(fila)
	var sel := OptionButton.new()
	sel.add_item(Idiomas.t("Todos los países"))
	sel.set_item_metadata(0, "")
	var paises := {}
	for t: Dictionary in m.palmares_mundo:
		paises[String(t["pais"])] = true
	var nombres: Dictionary = Datos.tabla("PAIS_SELECCION") if Datos.tabla("PAIS_SELECCION") is Dictionary else {}
	var orden := paises.keys()
	orden.sort()
	for p: String in orden:
		sel.add_item(Idiomas.t(String(nombres.get(p, p))))   ## (10-11) el país en el idioma del juego
		sel.set_item_metadata(sel.item_count - 1, p)
		if p == pais:
			sel.select(sel.item_count - 1)
	sel.item_selected.connect(func(i: int) -> void: _pintar(pr, String(sel.get_item_metadata(i))))
	fila.add_child(sel)
	var cerrar := boton(Idiomas.t("Cerrar"), true)
	cerrar.custom_minimum_size = Vector2(160, 44)
	cerrar.pressed.connect(func() -> void: queue_free())
	fila.add_child(cerrar)
	cerrar.call_deferred("grab_focus")
	var lista := m.palmares_mundo.duplicate()
	lista.reverse()
	var anio := -1
	var n := 0
	for t: Dictionary in lista:
		if pais != "" and String(t["pais"]) != pais:
			continue
		if int(t["anio"]) != anio:
			anio = int(t["anio"])
			_centro.add_child(etiqueta(str(anio), 22, Tema.ORO, false, false))
		var c: Club = m.clubes.get(String(t["club"]))
		var linea := "🏆 %s · %s — %s" % [String(nombres.get(String(t["pais"]), t["pais"])), Idiomas.t(String(t["torneo"])), c.nombre if c != null else "?"]
		_centro.add_child(etiqueta(linea, 16, Tema.TEXTO, false))
		n += 1
		if n >= 300:
			break
	var s := m.selecciones
	if s != null and pais == "":
		if not s.mundial.is_empty():
			_centro.add_child(etiqueta("🌐 %s %d — %s" % [Idiomas.t("Copa del Mundo"), int(s.mundial.get("anio", 0)), String(s.mundial.get("campeon", ""))], 18, Tema.ORO, false))
		for f: Dictionary in s.finalissimas:   ## (10-11) campeón de Europa contra campeón de América
			_centro.add_child(etiqueta("🏆 %s %d — %s (%s %s)" % [Finalissima.NOMBRE, int(f.get("anio", 0)), String(f.get("campeon", "")), Idiomas.t("contra"), String(f.get("rival", ""))], 17, Tema.ORO, false))
		for o: Dictionary in s.olimpicos:   ## (10-11) el fútbol de los Juegos Olímpicos (sub-23)
			_centro.add_child(etiqueta("🥇 %s %d — %s (%s %s)" % [Idiomas.t(Olimpicos.NOMBRE), int(o.get("anio", 0)), String(o.get("oro", "")), Idiomas.t("plata:"), String(o.get("plata", ""))], 17, Tema.ORO, false))
		for h: Dictionary in s.cargo.historial:
			_centro.add_child(etiqueta("🎌 %s %d — %s %s" % [Idiomas.t(String(h["torneo"])), int(h["anio"]), s.cargo.seleccion, Idiomas.t(String(Selecciones.PUESTOS_TORNEO[int(h["puesto"])]))], 16, Tema.TEXTO, false))
	if n == 0:
		_centro.add_child(etiqueta(Idiomas.t("Todavía no se ha cerrado ningún torneo esta partida: los campeones aparecen al terminar cada copa y cada liga."), 16, Tema.SUAVE))
