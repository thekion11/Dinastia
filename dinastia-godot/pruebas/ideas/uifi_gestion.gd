extends BaseIdea
## PAQUETE uifi (sesión 2, 25-10-2026): finanzas, mercado y mesa del representante.
## Comprueba los arreglos de verdad, sobre los componentes reales (no copias):
##  · pintar el mercado NO gasta el azar determinista de la partida y la lista de
##    objetivos no cambia entre repintados de la misma semana;
##  · cambiar un filtro no se lleva la mesa de negociación; estados vacíos;
##  · la mesa enseña la respuesta del club y la barra de «cuánto cubre» se mueve;
##  · los gráficos de finanzas y el «hoy» del punto más bajo;
##  · la mesa del representante: desenlace con color propio y foco visible;
##  · los textos nuevos salen traducidos.

func _textos(n: Node, salida: Array[String]) -> Array[String]:
	if n.is_queued_for_deletion():
		return salida
	if n is Label:
		salida.append((n as Label).text)
	elif n is Button:
		salida.append((n as Button).text)
	for h in n.get_children():
		_textos(h, salida)
	return salida

func _hay(n: Node, trozo: String) -> bool:
	for t in _textos(n, []):
		if t.contains(trozo):
			return true
	return false

func _contar(n: Node, clase: String) -> int:
	var k := 0
	for h in n.get_children():
		if h.is_queued_for_deletion():
			continue
		if h.is_class(clase) or (h.get_script() != null and (h.get_script() as Script).get_global_name() == clase):
			k += 1
		k += _contar(h, clase)
	return k

func _nombres_lista(panel: PanelMercado) -> Array[String]:
	var salida: Array[String] = []
	if panel._caja_lista == null:
		return salida
	for b in panel._caja_lista.find_children("*", "Button", true, false):
		salida.append((b as Button).text)
	return salida

func _paleta() -> Dictionary:
	return {"suave": Color("8ea595"), "texto": Color("e9eeea"), "acento": Color("3fa06a"),
		"verde": Color("4caf6d"), "rojo": Color("e05555"), "oro": Color("c9a227"), "escala": 1.0}

func _probar() -> void:
	_titulo("uifi: MERCADO")
	var m := _mundo(2611)
	var panel := PanelMercado.new()
	add_child(panel)
	var estado0 := Azar._rng.state
	panel.inicializar(m, {})
	var lista1 := _nombres_lista(panel)
	panel.pintar()
	var lista2 := _nombres_lista(panel)
	_comprobar(Azar._rng.state == estado0, "pintar el mercado dos veces no gasta números de Azar (la partida sigue igual)")
	_comprobar(not lista1.is_empty() and lista1 == lista2, "la lista de objetivos es la misma en dos repintados (%d jugadores)" % lista1.size())
	_comprobar(_hay(panel, "Nadie ha pujado por tus jugadores"), "sin ofertas recibidas se dice en una línea")

	## La mesa abierta con el primer objetivo de la lista.
	var objetivo: Jugador = panel._objetivos(m.mi_club())[0]
	_comprobar(m.mercado.abrir_negociacion(objetivo) == "", "se abre la mesa con %s" % objetivo.nombre)
	var n := m.mercado.negociacion
	n.fijo = 0
	panel.pintar()
	_comprobar(_hay(panel, "Cubre lo que piden"), "la mesa enseña cuánto cubre la oferta")
	var pct0 := int(round(float(n.valor_percibido()) * 100.0 / float(n.pedido)))
	_comprobar(_hay(panel, "%d %%" % pct0), "la barra dice %d %% (lo que perciben / lo que piden)" % pct0)
	n.ajustar("fijo", 4)
	panel.pintar()
	var pct1 := int(round(float(n.valor_percibido()) * 100.0 / float(n.pedido)))
	_comprobar(pct1 > pct0 and _hay(panel, "%d %%" % pct1), "subir el fijo mueve la barra (%d %% → %d %%)" % [pct0, pct1])
	_comprobar(_hay(panel, "Paciencia del club: %d" % n.paciencia), "se ve la paciencia que le queda al club")

	## Cambiar un filtro rehace SOLO la lista: las rejillas de la mesa siguen.
	var rejillas := _contar(panel, "GridContainer")
	panel._filtro_texto = "zzzzqqq"
	panel._repintar_lista(m.mi_club())
	_comprobar(_hay(panel, "Fijo") and _hay(panel, "Ficha/semana"), "filtrar la lista no se lleva la mesa de negociación")
	_comprobar(_contar(panel, "GridContainer") == rejillas - 1, "solo desaparece la rejilla de la lista (%d → %d)" % [rejillas, _contar(panel, "GridContainer")])
	_comprobar(_hay(panel, "Ningún jugador cumple esos filtros"), "un filtro sin resultados lo dice")
	panel._filtro_texto = ""

	## La respuesta del club se ve EN la mesa, no solo en el registro.
	panel.inicializar(m, {}, {"tipo": "club_pide_mas", "falta": 120000, "prefiere": "una cifra fija mayor"})
	_comprobar(_hay(panel, "CONTRAOFERTA DEL CLUB") and _hay(panel, "una cifra fija mayor"), "la contraoferta del club sale en la mesa")
	panel.inicializar(m, {}, {"tipo": "sin_caja", "hace_falta": 999999999})
	_comprobar(_hay(panel, "NO TE ALCANZA"), "«no te alcanza» sale en la mesa")
	panel.inicializar(m, {}, {"tipo": "jugador_no", "motivo": "", "pide": n.sueldo * 3})
	_comprobar(_hay(panel, "FALTA ÉL") and _hay(panel, "Pide una ficha de al menos"), "si el club acepta y él no, se dice qué ficha pide")

	## Teclado/mando: el nombre es un botón, y el foco vuelve al «+» tras repintar.
	var bmas: Button = panel._buscar_foco(panel, "fijo+")
	_comprobar(bmas != null and bmas.focus_mode != Control.FOCUS_NONE, "el «+» del fijo es un botón enfocable")
	panel._foco = "fijo+"
	panel.pintar()
	var nuevo: Button = panel._buscar_foco(panel, "fijo+")
	_comprobar(nuevo != null and nuevo != bmas, "tras repintar se localiza el «+» nuevo para devolverle el foco")
	m.mercado.cerrar_negociacion()
	panel.queue_free()

	_titulo("uifi: FINANZAS")
	var c := m.mi_club()
	var lista := VBoxContainer.new()
	add_child(lista)
	PanelFinanzas.pintar_balance_y_caja(lista, c, m, {"resultado": 1200000, "total_ingresos": 9000000, "total_gastos": 7800000}, _paleta())
	_comprobar(_contar(lista, "GraficoFinanzas") == 2, "balance y flujo de caja llevan su gráfico")
	_comprobar(_hay(lista, "(hoy)") and not _hay(lista, "(mes 0)"), "si lo más bajo es la caja de hoy, dice «hoy» y no «mes 0»")
	var lista2b := VBoxContainer.new()
	add_child(lista2b)
	PanelFinanzas.pintar_balance_y_caja(lista2b, c, m, {"resultado": -(c.saldo + 12000000) * 2, "total_ingresos": 1000, "total_gastos": 9000}, _paleta())
	_comprobar(_hay(lista2b, "se queda en negativo"), "con la caja en negativo avisa del mes")
	var g := GraficoFinanzas.flujo([100, 50, -20] as Array[int], _paleta())
	g.size = Vector2(300, 150)
	_comprobar(g._get_tooltip(Vector2(g._area_flujo().end.x - 2.0, 40)).contains("mes 2") and g._get_tooltip(Vector2(g._area_flujo().position.x + 2.0, 40)).begins_with("Caja hoy"), "la ayuda del gráfico da la cifra del mes bajo el ratón")
	_comprobar(g._marcas_y(-20, 100) == ([100, 0, -20] as Array[int]), "el eje Y marca el máximo, el cero y el mínimo")
	g.free()

	_titulo("uifi: MESA DEL REPRESENTANTE")
	var mesa := MesaAgente.new({"tipo": "mejora", "agente": "R. Prueba", "perfil": "tiburon", "pid": "x"}, 0, 0.0, 4242)
	var ui := MesaAgenteUI.new(mesa, func(_mm: MesaAgente) -> void: pass)
	add_child(ui)
	var botones := ui.find_children("*", "Button", true, false)
	_comprobar(not botones.is_empty() and (botones[0] as Button).has_theme_stylebox_override("focus"), "los botones de la mesa tienen un foco visible propio")
	mesa.plantarse()
	ui._pintar()
	_comprobar(ui._pide.text.contains("PLANTASTE"), "plantarse se lee como desenlace")
	var col_plantado := ui._pide.get_theme_color("font_color")
	var mesa2 := MesaAgente.new({"tipo": "mejora", "agente": "R. Prueba", "perfil": "tiburon", "pid": "x"}, 0, 0.0, 4242)
	mesa2.ceder()
	var ui2 := MesaAgenteUI.new(mesa2, func(_mm: MesaAgente) -> void: pass)
	add_child(ui2)
	_comprobar(mesa2.estado == "acuerdo" and ui2._pide.text.contains("TRATO"), "ceder cierra trato y se dice")
	_comprobar(ui2._pide.get_theme_color("font_color") != col_plantado, "trato y plantón tienen colores distintos")
	ui.queue_free()
	ui2.queue_free()

	_titulo("uifi: TEXTOS TRADUCIDOS")
	var antes := Idiomas.idioma
	Idiomas.idioma = "en"
	_comprobar(Idiomas.t("MERCADO ABIERTO  ·  quedan %d semana(s)").begins_with("MARKET OPEN"), "el estado del mercado sale en inglés")
	_comprobar(Idiomas.t("+28 % de sueldo") == "+28 % salary", "el detalle de la mesa del representante se traduce por patrón")
	_comprobar(Idiomas.t("Insinuar que lo pones en venta") != "Insinuar que lo pones en venta", "el farol se traduce")
	Idiomas.idioma = antes
