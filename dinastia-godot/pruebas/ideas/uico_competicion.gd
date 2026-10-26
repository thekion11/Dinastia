extends BaseIdea
## FICHA DE COMPETICIÓN PULIDA (uico, 25-10-2026): zonas reales de la tabla,
## fila del club propio resaltada, columnas alineadas, copas en el selector,
## mando (L1/R1) y textos traducidos.
##   herramientas/ideas.sh uico_competicion

## Se sobreescribe `_ready` porque esta prueba necesita fotogramas de por medio
## (las filas se colocan en el reparto diferido de los contenedores).
func _ready() -> void:
	await get_tree().process_frame
	await _probar_con_espera()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _probar_con_espera() -> void:
	_titulo("uico · ZONAS DE LA TABLA")
	var m := _mundo(4242)
	var primera: Liga = null
	var segunda: Liga = null
	for l: Liga in m.ligas:
		if l.pais == m.mi_club().pais and l.division() == 1:
			primera = l
		elif l.pais == m.mi_club().pais and l.division() == 2:
			segunda = l
	_comprobar(primera != null and segunda != null, "el país tiene Primera y Segunda")
	_comprobar(CompeticionZonas.de_liga(m, primera).is_empty(), "sin partidos jugados no se pinta ninguna zona (sería el sorteo)")
	for i in 6:
		m.avanzar_semana()
	var t1 := primera.tabla()
	var z1 := CompeticionZonas.de_liga(m, primera, t1)
	var bajan := 0
	for v: Dictionary in z1.values():
		if String(v["zona"]) == CompeticionZonas.DESCENSO:
			bajan += 1
	_comprobar(bajan == primera.plazas_descenso, "descienden exactamente plazas_descenso (%d de %d)" % [bajan, primera.plazas_descenso])
	var ultimo: Club = t1[t1.size() - 1]["club"]
	_comprobar(String(z1.get(ultimo.id, {}).get("zona", "")) == CompeticionZonas.DESCENSO, "el último está en descenso")
	var primero: Club = t1[0]["club"]
	_comprobar(String(z1.get(primero.id, {}).get("zona", "")) == CompeticionZonas.CAMPEON, "el primero va de campeón")
	var medio: Club = t1[t1.size() / 2]["club"]
	_comprobar(String(z1.get(medio.id, {}).get("zona", "")) != CompeticionZonas.DESCENSO, "la mitad de la tabla no desciende")
	var z2 := CompeticionZonas.de_liga(m, segunda)
	var suben := 0
	var raras := 0
	for v2: Dictionary in z2.values():
		if String(v2["zona"]) == CompeticionZonas.ASCENSO:
			suben += 1
		if String(v2["zona"]) == CompeticionZonas.DESCENSO or String(v2["zona"]) == CompeticionZonas.CONTINENTAL:
			raras += 1
	_comprobar(raras == 0, "en Segunda no hay descenso ni plaza continental")
	_comprobar(suben == primera.plazas_descenso, "en Segunda suben tantos como bajan (%d)" % suben)
	m.federacion.promocion = true
	var z3 := CompeticionZonas.de_liga(m, primera)
	var prom := 0
	for v3: Dictionary in z3.values():
		if String(v3["zona"]) == CompeticionZonas.PROMOCION:
			prom += 1
	_comprobar(prom == 1, "con la promoción aprobada, un club de Primera la juega")
	m.federacion.promocion = false
	## Las plazas continentales salen del mismo reparto que el sorteo: todo
	## club marcado está de verdad en alguna lista de `Continental.plazas()`.
	var reparto := Continental.plazas(m.clubes.values(), m.ligas, m.copa.campeon if m.copa != null else null)
	var con_plaza := {}
	for k: String in reparto:
		for c: Club in (reparto[k] as Array):
			con_plaza[c.id] = true
	var mal_marcados := 0
	for id: String in z1:
		if String(z1[id]["zona"]) == CompeticionZonas.CONTINENTAL and not con_plaza.has(id):
			mal_marcados += 1
	_comprobar(mal_marcados == 0, "ninguna plaza continental inventada")
	var conti := 0
	for v4: Dictionary in z1.values():
		if String(v4["zona"]) == CompeticionZonas.CONTINENTAL:
			conti += 1
	_comprobar(conti > 0, "hay clubes marcados con plaza continental (%d)" % conti)

	_titulo("uico · LA PANTALLA")
	var v := Competicion.new()
	add_child(v)
	v.size = Vector2(1280, 720)
	v.abrir(m, primera)
	for i in 4:
		await get_tree().process_frame
	var lista: VBoxContainer = v.get("_lista")
	var filas: Array = []
	var cab: HBoxContainer = null
	for n in lista.get_children():
		if n is PanelContainer and n.has_meta("cabecera"):
			if cab == null:
				cab = (n as PanelContainer).get_child(0)
		elif n is PanelContainer:
			filas.append(n)
	_comprobar(filas.size() >= primera.clubes.size(), "una fila por club (%d)" % filas.size())
	## La fila propia lleva borde; las demás no.
	var propias := 0
	for f: PanelContainer in filas.slice(0, primera.clubes.size()):
		var e := f.get_theme_stylebox("panel") as StyleBoxFlat
		if e != null and e.border_width_left > 0:
			propias += 1
	_comprobar(propias == 1, "exactamente una fila de la tabla resaltada (la de tu club)")
	## Las columnas: el «PTS» de la cabecera encima de los puntos de cada fila.
	var pts_cab: Label = cab.get_child(cab.get_child_count() - 1)
	var fila1: HBoxContainer = (filas[0] as PanelContainer).get_child(0)
	var pts_f: Label = fila1.get_child(fila1.get_child_count() - 1)
	var dx := absf(pts_cab.get_global_rect().end.x - pts_f.get_global_rect().end.x)
	_comprobar(dx < 2.0, "«PTS» alineado con los puntos (desfase %.1f px)" % dx)
	_comprobar(pts_f.get_global_rect().end.x <= 1280.0, "las cifras caben en 1280 px")
	var sel: OptionButton = v.get("_selector")
	var hay_copa := false
	for i2 in sel.item_count:
		if sel.get_item_text(i2).begins_with("🏆"):
			hay_copa = true
	_comprobar(hay_copa, "el selector abre también la copa nacional")
	## L1/R1: la acción de la pantalla principal cambia de competición aquí.
	if not InputMap.has_action("dinastia_tab_siguiente"):
		InputMap.add_action("dinastia_tab_siguiente")
	var antes := sel.selected
	var ev := InputEventAction.new()
	ev.action = "dinastia_tab_siguiente"
	ev.pressed = true
	v._input(ev)
	_comprobar(sel.selected == posmod(antes + 1, sel.item_count), "R1 pasa a la competición siguiente")
	## Todas las entradas se pintan sin romperse (copas y continentales incluidas).
	for i3 in sel.item_count:
		sel.select(i3)
		v.call("_elegir", i3)
		await get_tree().process_frame
		_comprobar(lista.get_child_count() > 2, "se pinta «%s»" % sel.get_item_text(i3))
	## En inglés no queda el «jornada» del título.
	Idiomas.idioma = "en"
	sel.select(0)
	v.call("_elegir", 0)
	var tit: Label = lista.get_child(0)
	_comprobar(not tit.text.contains("jornada"), "título traducido: «%s»" % tit.text)
	## Las rondas y los grupos llegan del núcleo en castellano y se traducen al pintar.
	for r: String in ["Final", "Semifinales", "Cuartos de final", "Octavos de final", "Grupos · Fecha 2", "Grupo A"]:
		_comprobar(Idiomas.t(r) != r or r == "Final", "ronda traducida: «%s» → «%s»" % [r, Idiomas.t(r)])
	Idiomas.idioma = "es"
	v.queue_free()
