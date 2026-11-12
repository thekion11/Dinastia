class_name CalendarioSemanas
extends EventoPantallaCompleta
## LA VISTA DE VARIAS SEMANAS (10-11, estilo calendario del PES 2020 Master League): una tira horizontal, una columna por semana (las próximas 6) con los
## eventos de tu club (`EventosFecha`: liga con el escudo del rival, copa, continental, mercado, fin de temporada). Fondo oscuro del juego, esta semana en oro.
## Se abre desde el botón 📅 de la fila «PRÓXIMOS» (`FilaProximos.abrir_semanas`); se cierra con «Cerrar» o Esc / B del mando.
const DIAS := ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]

static func mostrar(pr: Node, m: Mundo, dia_hoy := 0) -> CalendarioSemanas:
	var c := CalendarioSemanas.new()
	c._montar_base(pr)
	c._rellenar(m, dia_hoy)
	return c

func _rellenar(m: Mundo, dia_hoy: int) -> void:
	## (12-11) Teléfono de pie: las semanas una debajo de otra, a lo ancho (seis columnas de 150 px no caben en un lienzo de 540).
	var de_pie := EscalaMovil.es_vertical()
	var ancho := ANCHO_DE_PIE if de_pie else minf(1500.0, float(get_viewport().get_visible_rect().size.x) - 80.0)
	_centro.custom_minimum_size = Vector2(ancho, 0)
	_centro.add_child(etiqueta("%s · %d" % [Idiomas.t("Calendario").to_upper(), m.anio], 15, Tema.SUAVE))
	_centro.add_child(etiqueta("📅 " + Idiomas.t("Próximas semanas"), 28 if de_pie else 40, Tema.ORO, true, false))
	var tira: BoxContainer = VBoxContainer.new() if de_pie else HBoxContainer.new()
	tira.add_theme_constant_override("separation", 10)
	_centro.add_child(tira)
	var semanas := EventosFecha.semanas(m)
	if semanas.is_empty():
		_centro.add_child(etiqueta(Idiomas.t("Temporada terminada"), 20, Tema.TEXTO))
	var primera_vez := true
	for s: Dictionary in semanas:
		tira.add_child(_columna(s, dia_hoy, primera_vez, int(ancho) - 10 if de_pie else int(ancho / maxf(1.0, float(semanas.size()))) - 10))
		primera_vez = false
	var cerrar := boton(Idiomas.t("Cerrar"), true)
	cerrar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cerrar.custom_minimum_size = Vector2(260, 58)
	cerrar.pressed.connect(_cerrar)
	_centro.add_child(cerrar)

func _columna(s: Dictionary, dia_hoy: int, es_esta: bool, ancho_col: int) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(maxi(150, ancho_col), 0)
	var est := Tema.caja(Color(1, 1, 1, 0.05), Tema.RADIO_GRANDE, Tema.ORO if es_esta else Color(1, 1, 1, 0.14))
	est.set_border_width_all(2 if es_esta else 1)
	est.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", est)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)
	var k := int(s["k"])
	col.add_child(etiqueta("%s %d" % [Idiomas.t("Semana"), int(s["semana"])], 20, Tema.ORO if es_esta else Tema.TEXTO))
	col.add_child(etiqueta(Idiomas.t("Hoy") if es_esta else "+%d" % k, 13, Tema.ORO if es_esta else Tema.SUAVE))
	var eventos: Array = s["eventos"]
	if eventos.is_empty():
		col.add_child(etiqueta(Idiomas.t("Semana sin partido"), 14, Tema.SUAVE))
	var primero := es_esta
	for e: Dictionary in eventos:
		if k == 0 and int(e["dia"]) < dia_hoy:
			continue   ## lo que ya pasó de esta semana
		col.add_child(etiqueta(Idiomas.t(DIAS[int(e["dia"])]), 12, Tema.SUAVE, false, false))
		col.add_child(TarjetaEvento.crear(e, primero and EventosFecha.es_partido(e), 120))
		if EventosFecha.es_partido(e):
			primero = false
	return panel

func _cerrar() -> void:
	terminado.emit()
	queue_free()

func _input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_cerrar()
