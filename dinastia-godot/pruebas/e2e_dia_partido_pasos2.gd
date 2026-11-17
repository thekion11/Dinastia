extends RefCounted
## La segunda mitad de `e2e_dia_partido` (pausa, cambio, simular el resto, final, repetición, momentos, popup y vuelta al menú central).

var t: Node
var p: Principal
var a: RefCounted   ## los pasos de la primera mitad (buscar botones)

func _init(prueba: Node, pasos: RefCounted) -> void:
	t = prueba
	p = prueba.p
	a = pasos

func despues_de_jugar(c: Club, vista: VistaEstadio, partido: Partido, liga: Liga, jugados0: int, mem0: float, huerf0: int) -> void:
	var pais := c.pais
	var dias = p._avance.dias()
	## 7) PAUSA → TÁCTICA Y CAMBIOS: un cambio de verdad
	vista.abrir_pausa()
	await t.esperar(5)
	var pausa: Node = t.buscar(vista, "MenuPausaPartido")
	t.ok(pausa != null, "[%s] la pausa se abre" % pais)
	var bt: BaseButton = pausa.find_child("tactica", true, false) if pausa != null else null
	if bt != null:
		bt.pressed.emit()
	var panel: Node = null
	await t.hasta(func() -> bool:
		var panel_ = vista.get("_panel_dt")
		return panel_ != null, 5.0)
	panel = vista.get("_panel_dt")
	t.ok(panel != null, "[%s] «Táctica y cambios» abre la pizarra del partido" % pais)
	var once_mio := partido.once_local if partido.local == c else partido.once_visita
	var sale: Jugador = null
	var entra_nombre := ""
	if panel != null:
		var col_campo: Node = panel.get("_col_campo")
		for b in col_campo.get_children():
			if b is Button and not String((b as Button).text).begins_with("POR"):
				(b as Button).pressed.emit()
				break
		await t.esperar(3)
		sale = panel.get("_sale")
		var col_banco: Node = panel.get("_col_banco")
		for b in col_banco.get_children():
			if b is Button and not (b as Button).disabled and not b.is_queued_for_deletion():
				entra_nombre = String((b as Button).text)
				(b as Button).pressed.emit()
				break
		await t.esperar(3)
	var cambio: Array = partido.cronica.filter(func(e: Dictionary) -> bool: return String(e.get("tipo", "")) == "cambio")
	once_mio = partido.once_local if partido.local == c else partido.once_visita
	t.ok(sale != null and cambio.size() == 1 and String(cambio[0]["sale"]) == sale.nombre and not once_mio.has(sale),
		"[%s] el cambio queda en el acta y en el once (%s → %s)" % [pais, sale.nombre if sale else "?", entra_nombre])
	if panel != null:
		panel.cerrar()
	## 8) REANUDAR: el partido sigue
	var m0 := partido.minuto
	var j = load("res://pruebas/e2e_dia_partido_pasos.gd").Jugando.new()
	t.add_child(j)
	await t.hasta(func() -> bool: return partido.minuto > m0, 120.0)
	j.queue_free()
	load("res://pruebas/e2e_dia_partido_pasos.gd").Jugando.soltar()
	t.ok(partido.minuto > m0, "[%s] tras cerrar la pizarra el partido sigue (minuto %d → %d)" % [pais, m0, partido.minuto])
	## 9) SIMULAR EL RESTO (pide confirmarlo con una segunda pulsación)
	vista.abrir_pausa()
	await t.esperar(5)
	pausa = t.buscar(vista, "MenuPausaPartido")
	var bs: BaseButton = pausa.find_child("simular", true, false) if pausa != null else null
	if bs != null:
		bs.pressed.emit()
		await t.esperar(2)
		bs.pressed.emit()
	## Al acabar el 3D, la crónica del partido (2D) con su «Volver»: lo que pulsa el jugador para ir al resultado.
	await t.hasta(func() -> bool:
		var v_ = t.buscar(p, "PartidoVivo")
		return v_ != null and v_.get("_btn_volver") != null and (v_.get("_btn_volver") as Control).visible, 120.0)
	var vivo_fin: Node = t.buscar(p, "PartidoVivo")
	t.ok(vivo_fin != null and (vivo_fin.get("_btn_volver") as Control).visible, "[%s] tras simular, la crónica del partido ofrece «Volver»" % pais)
	if vivo_fin != null:
		(vivo_fin.get("_btn_volver") as BaseButton).pressed.emit()
	var rp: ResultadoPartido = null
	await t.hasta(func() -> bool:
		var rp_ = t.buscar(p, "ResultadoPartido") as ResultadoPartido
		return rp_ != null and rp_.visible, 120.0)
	rp = t.buscar(p, "ResultadoPartido") as ResultadoPartido
	t.ok(partido.terminado_ya, "[%s] «Simular el resto» termina el partido (%d-%d)" % [pais, partido.goles_local, partido.goles_visita])
	if not t.ok(rp != null, "[%s] sale el resultado final" % pais):
		return
	await t.esperar(10)
	## 10) EL FINAL: tarjetas, goleadores y marcador
	var mio_local := partido.local == c
	var gl := 0
	for g: String in ResumenPartidoCine.goleadores(partido, partido.local):
		gl += g.count("'")
	t.ok(gl == partido.goles_local, "[%s] los goleadores cuadran con el marcador (%d)" % [pais, partido.goles_local])
	var tarjetas := partido.amarillas_local + partido.amarillas_visita + partido.rojas_local + partido.rojas_visita
	var rotulos := ResumenPartidoCine.estadisticas(partido).map(func(f: Array) -> String: return String(f[0]))
	t.ok(rotulos.has("Tarjetas amarillas") and rotulos.has("Pases"), "[%s] el final muestra tarjetas (%d) y los pases del césped" % [pais, tarjetas])
	## 11) REPETICIÓN DE LOS GOLES (o los momentos si no hubo goles) → «Jugar desde el minuto N»
	var hubo_goles := partido.goles_local + partido.goles_visita > 0
	var br: BaseButton = a._boton_con(rp._raiz, Idiomas.t("Repetición de los goles") if hubo_goles else Idiomas.t("Jugar momentos"))
	t.ok(br != null, "[%s] el final ofrece %s" % [pais, "la repetición de los goles" if hubo_goles else "los momentos"])
	if br != null:
		br.pressed.emit()
		var mo: MomentosPartido = null
		await t.hasta(func() -> bool:
			var mo_ = t.buscar(p, "MomentosPartido") as MomentosPartido
			return mo_ != null, 10.0)
		mo = t.buscar(p, "MomentosPartido") as MomentosPartido
		var bj: BaseButton = a._boton_con(mo._raiz, "Jugar desde el minuto") if mo != null else null
		t.ok(bj != null, "[%s] los momentos tienen «Jugar desde el minuto N»" % pais)
		if bj != null:
			var vistas0 := p.find_children("*", "VistaEstadio", true, false).size()
			bj.pressed.emit()
			var hay := [null]   ## (las lambdas capturan por valor: el resultado va en un arreglo)
			await t.hasta(func() -> bool:
				for v in p.find_children("*", "VistaEstadio", true, false):
					if not v.is_queued_for_deletion() and v.get("_motor") != null:
						hay[0] = v
				return hay[0] != null, 120.0)
			var vr: VistaEstadio = hay[0]
			t.ok(vr != null and vistas0 == 0, "[%s] «Jugar desde el minuto» abre la réplica jugable" % pais)
			var pj_liga := int((liga.tabla_puntos.get(c.id, {}) as Dictionary).get("pj", 0))
			await t.esperar(60)
			if vr != null:
				t.ok(vr.partido != partido and vr.partido.local != partido.local, "[%s] la réplica juega con clubes clonados (no toca la partida)" % pais)
				var vivo: Node = vr.get_parent()
				if vivo != null and vivo.has_signal("cerrado"):
					vivo.emit_signal("cerrado")   ## volver (como el «Salir del partido»)
			await t.esperar(20)
			t.ok(int((liga.tabla_puntos.get(c.id, {}) as Dictionary).get("pj", 0)) == pj_liga, "[%s] la réplica no cambia la tabla" % pais)
	## 12) CONTINUAR → pie de campo → menú central
	rp = t.buscar(p, "ResultadoPartido") as ResultadoPartido
	if rp != null:
		rp._seguir()
	var pie: Node = null
	await t.hasta(func() -> bool:
		var pie_ = t.buscar(p, "PieDeCampo")
		return pie_ != null or not dias.partido_hoy(), 15.0)
	pie = t.buscar(p, "PieDeCampo")
	if pie != null:
		pie.call("_elegir", -1)
	await t.hasta(func() -> bool: return t.buscar(p, "ResultadoPartido") == null and t.buscar(p, "PieDeCampo") == null, 15.0)
	await t.esperar(30)
	## 13) EL MENÚ CENTRAL AL DÍA: la tabla, el último resultado y el popup «Partido jugado»
	t.ok(int((liga.tabla_puntos.get(c.id, {}) as Dictionary).get("pj", 0)) == jugados0 + 1, "[%s] la tabla suma el partido (PJ %d → %d)" % [pais, jugados0, int((liga.tabla_puntos.get(c.id, {}) as Dictionary).get("pj", 0))])
	var gf := partido.goles_local if mio_local else partido.goles_visita
	var gc := partido.goles_visita if mio_local else partido.goles_local
	t.ok(MomentosPartido.ultimo == partido, "[%s] el último resultado del menú es este partido (%d-%d)" % [pais, gf, gc])
	dias.actualizar_botones()
	var bjug: Variant = p._guia.nodos.get("b_jugado")
	t.ok(bjug is Button and (bjug as Button).visible and String((bjug as Button).text).contains("%d-%d" % [partido.goles_local, partido.goles_visita]),
		"[%s] el botón «Partido jugado» del menú central muestra %d-%d" % [pais, partido.goles_local, partido.goles_visita])
	if bjug is Button:
		dias.abrir_jugado(bjug)
		await t.esperar(10)
		var pop: Node = t.buscar(p, "PopupPartidoJugado")
		t.ok(pop != null, "[%s] el popup «Partido jugado» se abre" % pais)
		if pop != null:
			pop.queue_free()
	## 14) SIN RESTOS: nodos huérfanos y memoria al volver
	for i in 90:
		await t.get_tree().process_frame
	var mem1 := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	var huerf1 := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	t.ok(t.buscar(p, "VistaEstadio") == null and t.buscar(p, "PartidoVivo") == null, "[%s] no queda ningún estadio ni partido abierto" % pais)
	t.ok(huerf1 - huerf0 <= 5, "[%s] no quedan nodos huérfanos (%d → %d)" % [pais, huerf0, huerf1])
	t.resumen.append("%s %-22s %d-%d · tarjetas %d · memoria %.0f → %.0f MB (%+.0f) · huérfanos %d → %d" % [pais, Nombres.visible(c.nombre), partido.goles_local,
		partido.goles_visita, tarjetas, mem0, mem1, mem1 - mem0, huerf0, huerf1])
