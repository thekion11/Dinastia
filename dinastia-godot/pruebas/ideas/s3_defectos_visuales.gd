extends BaseIdea
## s3 (26-10-2026): DEFECTOS VISUALES QUE ANOTÓ LA SESIÓN 2 (plan §9). Lo que se puede medir sin
## pantalla; lo visual se vio además con la cámara real (`pruebas/captura_s3_interfaz.tscn`).

func _probar() -> void:
	_titulo("S3: CARAS, CLUB NEGRO, FLUJO DE CAJA, CIFRAS, MANDO 3D Y «FORMA»")
	_caras()
	_club_negro()
	_flujo()
	_mando()
	_forma()

func _caras() -> void:
	var f := Retrato3D.fondo_de("#000000")
	_comprobar(f.get_luminance() >= Retrato3D.LUZ_FONDO, "el fondo del retrato de un club negro ya no es negro (luminosidad %.2f)" % f.get_luminance())
	var img := Retrato3D._marcador(128, f)
	var cabeza := img.get_pixel(64, 51)
	var esquina := img.get_pixel(4, 4)
	_comprobar(cabeza.get_luminance() > esquina.get_luminance() + 0.05,
		"mientras se pinta, el marcador lleva silueta (cabeza %.2f, fondo %.2f)" % [cabeza.get_luminance(), esquina.get_luminance()])

func _club_negro() -> void:
	_comprobar(EscudoMuestras.oscuro("#000000") and not EscudoMuestras.oscuro("#f2c14e"), "un escudo negro cuenta como oscuro; uno dorado, no")
	var b := EscudoMuestras.boton(null, false, 46, "", true)
	var sb := b.get_theme_stylebox("normal") as StyleBoxFlat
	_comprobar(sb != null and sb.bg_color.get_luminance() > 0.5, "las miniaturas de un club negro van sobre fondo claro")
	b.free()
	var m := _mundo(4401)
	var p: Principal = load("res://escenas/principal.tscn").instantiate()
	p.set("mundo", m)
	var c := m.mi_club()
	c.esc_color1 = "#000000"
	var e1 := p._escudo(c, 44)
	c.esc_color1 = "#2b6b45"
	var e2 := p._escudo(c, 44)
	_comprobar(e1.get_child(0) is Panel and not (e2.get_child(0) is Panel), "el escudo negro lleva un halo claro detrás; uno verde, no")
	var h := HBoxContainer.new()
	p._dato("Caja", "79.2M EUR", Color.WHITE, h)
	var cifra := (h.get_child(0) as HBoxContainer).get_child(1) as Label
	_comprobar(cifra.get_theme_stylebox("normal").content_margin_right >= 12, "las cifras de `_dato` dejan aire a la derecha (la barra ya no las tapa)")
	var h2 := VBoxContainer.new()
	PanelFinanzas._dato(h2, "Caja", "79.2M EUR", Color.WHITE, {"suave": Color.GRAY, "escala": 1.0})
	var cifra2 := (h2.get_child(0) as HBoxContainer).get_child(1) as Label
	_comprobar(cifra2.get_theme_stylebox("normal").content_margin_right >= 12, "y también las de finanzas")
	for n: Node in [e1, e2, h, h2, p]:
		n.free()

func _flujo() -> void:
	var m := _mundo(4402)
	var c := m.mi_club()
	var f := Finanzas.new(c)
	var liga: Liga = m.ligas[0]
	var proy := f.proyeccion_anual(liga.jornadas() / 2, 0)
	var s := FlujoCaja.saldos_por_mes(c, m, proy)
	_comprobar(s.size() == 13 and s[0] == c.saldo, "13 saldos: hoy y fin de cada mes (%d)" % s.size())
	var pasos := {}
	for i in 12:
		pasos[s[i + 1] - s[i]] = true
	_comprobar(pasos.size() >= 2, "el flujo ya no es una rampa de 12 trozos iguales (%d escalones distintos)" % pasos.size())
	## Lo que entra por taquilla cae en las semanas en que juegas en casa (calendario real).
	var casa := 0
	for j in mini(4, liga.calendario.size()):
		for par: Array in liga.calendario[j]:
			if par[0] == c:
				casa += 1
	var por_partido := int(proy["ingresos"]["Taquilla"]) / maxi(1, liga.jornadas() / 2)
	var cierre := 0
	for k: String in proy["ingresos"]:
		if k != "Taquilla":
			cierre += int(proy["ingresos"][k])
	for k: String in proy["gastos"]:
		cierre -= int(proy["gastos"][k])
	cierre /= Finanzas.MESES_TEMPORADA
	_comprobar(absi(s[1] - s[0] - (casa * por_partido + cierre)) <= casa + 2,
		"el primer mes suma sus %d partidos en casa y un cierre de mes (%d)" % [casa, s[1] - s[0]])

func _mando() -> void:
	var mg := MandoGiratorio.new()
	mg._fuente = ThemeDB.fallback_font
	var l := mg._lineas("Estadísticas del partido", 12, 104.0, true)
	_comprobar(l.size() == 2 and not "".join(l).contains("…"), "una etiqueta larga del mando va en dos líneas, sin «…» (%s)" % " / ".join(l))
	var l1 := mg._lineas("Moverse", 12, 104.0, true)
	_comprobar(l1.size() == 1 and l1[0] == "Moverse", "una corta sigue en una línea")
	mg.free()

func _forma() -> void:
	var antes := Idiomas.idioma
	Idiomas.idioma = "en"
	_comprobar(Idiomas.t("Forma del escudo") == "Crest shape" and Idiomas.t("Forma") == "Form",
		"«Forma del escudo» y «Forma» (física) son dos claves: «%s» / «%s»" % [Idiomas.t("Forma del escudo"), Idiomas.t("Forma")])
	Idiomas.idioma = antes
