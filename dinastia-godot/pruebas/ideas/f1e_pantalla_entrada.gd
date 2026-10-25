extends BaseIdea
## LA PANTALLA DE ENTRADA AL CAMPEONATO (fase 1, etapa 5): contrato de etapa (configurar / terminado /
## volver), cifras de las dos tarjetas, selección del club, confirmación y lo que emite.

func _probar() -> void:
	_titulo("PANTALLA · ENTRADA AL CAMPEONATO")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 777)
	var estado := {"mundo": m, "pais": {"pais": "CHI"}, "modo": "creador",
		"config": {"nombre_club": "Club Prueba", "color1": Color("aa2233"), "color2": "#ffffff", "estadio": "El Faro"}}
	var p := PantallaEntradaCampeonato.new()
	_comprobar(p.has_signal("terminado") and p.has_signal("volver") and p.has_method("configurar"), "cumple el contrato de etapa")
	p.configurar(estado)   ## antes de entrar al árbol, como hace el orquestador
	add_child(p)
	var sug := EntradaCampeonato.candidato_sugerido(m, "CHI")
	var e := p.entrada_actual()
	_comprobar(String(e["modo"]) == "reemplazar" and String(e["club_reemplazado"]) == sug.id,
		"arranca en «reemplazar» con el colista de la división más baja (%s)" % sug.nombre)
	_comprobar(String((e["club"] as Dictionary)["nombre"]) == "Club Prueba" and String((e["club"] as Dictionary)["color1"]) == "#aa2233",
		"lee nombre y colores de la configuración del club")
	var grid_a: GridContainer = p._grid["reemplazar"]
	var grid_b: GridContainer = p._grid["pagar"]
	_comprobar(grid_a.get_child_count() == 16 and grid_b.get_child_count() == 16, "las dos tarjetas enseñan sus 8 consecuencias")
	_comprobar(_texto_de(grid_a).contains(Eco.dinero(int(e["presupuesto"]))), "la tarjeta A enseña el presupuesto real (%s)" % Eco.dinero(int(e["presupuesto"])))
	var pb := EntradaCampeonato.previsualizar(m, "pagar", "CHI")
	_comprobar(_texto_de(grid_b).contains(Eco.dinero(int(pb["cuota"]))) and _texto_de(grid_b).contains(str(int(pb["rep"]))),
		"la tarjeta B enseña la cuota (%s) y la reputación (%d) reales" % [Eco.dinero(int(pb["cuota"])), int(pb["rep"])])
	## El selector: todos los clubes de Chile, y elegir otro cambia las cifras.
	_comprobar(p._ids_selector.size() == EntradaCampeonato.candidatos(m, "CHI").size(), "el selector lista los %d clubes del país" % p._ids_selector.size())
	var grande: Club = EntradaCampeonato.candidatos(m, "CHI")[0]
	p.elegir_club(grande.id)
	_comprobar(int(p.entrada_actual()["rep"]) == grande.rep - 10 and _texto_de(grid_a).contains(grande.nombre),
		"elegir %s repinta la tarjeta (rep %d)" % [grande.nombre, grande.rep - 10])
	## Confirmación: primero se pide, luego se emite.
	var emitido: Array = []
	p.terminado.connect(func(d: Dictionary) -> void: emitido.append(d))
	var volvio: Array = []
	p.volver.connect(func() -> void: volvio.append(true))
	p.elegir_modo("pagar")
	p._pedir_confirmacion()
	_comprobar(p.confirmacion_abierta() and emitido.is_empty(), "confirmar abre la confirmación sin emitir todavía")
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	p._unhandled_key_input(esc)
	_comprobar(not p.confirmacion_abierta() and volvio.is_empty(), "Esc con la confirmación abierta solo la cierra")
	p._pedir_confirmacion()
	var n0 := m.clubes.size()
	p._confirmar()
	_comprobar(emitido.size() == 1, "«Sí, entrar así» emite terminado una vez")
	if emitido.size() == 1:
		var ent: Dictionary = emitido[0]["entrada"]
		_comprobar(String(ent["tipo"]) == "pagar" and int(ent["cuota"]) == int(pb["cuota"]) and int(ent["presupuesto"]) == int(pb["presupuesto"]),
			"emite {entrada: {tipo: pagar, cuota, presupuesto…}} con las cifras de la tarjeta")
		_comprobar(m.clubes.size() == n0 and m.mi_club_id == "", "sin «aplicar» la pantalla no toca el mundo (lo hace quien la orquesta)")
	p._unhandled_key_input(esc)
	_comprobar(volvio.size() == 1, "Esc sin confirmación abierta emite volver")
	p.queue_free()

	## Con «aplicar»: la propia pantalla aplica la entrada con `EntradaCampeonato.aplicar`.
	var q := PantallaEntradaCampeonato.new()
	estado["aplicar"] = true
	estado["entrada"] = {"tipo": "reemplazar", "reemplaza": grande.id}
	q.configurar(estado)
	add_child(q)
	_comprobar(String(q.entrada_actual()["club_reemplazado"]) == grande.id, "al volver a la etapa sale marcada la elección anterior")
	var out: Array = []
	q.terminado.connect(func(d: Dictionary) -> void: out.append(d))
	var rep_esperada := grande.rep - 10
	q._pedir_confirmacion()
	q._confirmar()
	_comprobar(out.size() == 1 and String(out[0]["entrada"].get("club_id", "")) == grande.id, "con aplicar=true añade club_id")
	_comprobar(m.mi_club() != null and m.mi_club().nombre == "Club Prueba" and m.mi_club().rep == rep_esperada and m.directiva.confianza == 60,
		"y el mundo queda con el club nuevo al mando (rep %d, confianza 60)" % rep_esperada)
	q.queue_free()

func _texto_de(n: Node) -> String:
	var s := ""
	for h in n.find_children("*", "Label", true, false):
		s += (h as Label).text + "\n"
	return s
