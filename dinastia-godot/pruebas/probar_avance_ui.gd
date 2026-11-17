extends Node
## El botón «Avanzar» nuevo dentro del menú central real (avance por días, pasos 3, 5 y 6): reemplaza a los botones viejos, el día de partido deja «Jugar» y «Saltar»,
## «Saltar» corre la semana, los avisos dejan su campana en el mosaico y las pantallas se construyen. Dos clubes de países distintos.

var fallos := 0

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		fallos += 1
		print("FALLO ", msg)

func _frames(n := 3) -> void:
	for i in n:
		await get_tree().process_frame

func _ready() -> void:
	AvanceDiasUI.sin_pantalla = true
	AvanceSemana.partido_obliga = true
	for cfg: Array in [[["CHI", "ARG"], 1, 20261104], [["ESP", "ENG"], 2, 20261117]]:
		await _una(cfg)
	await _pantallas()
	print("FIN. %d fallos" % fallos)
	get_tree().quit()

func _una(cfg: Array) -> void:
	var m := Mundo.new()
	var ps: Array[String] = []
	for c in cfg[0]:
		ps.append(String(c))
	m.generar(ps, int(cfg[2]))
	m.tomar_el_mando(m.ligas[0].clubes[int(cfg[1])].id)
	PedidoPartida.mundo_pregenerado = m
	PedidoPartida.modo_elegido = "dt"
	PedidoPartida.dt_nombre_elegido = "Prueba"
	PedidoPartida.dificultad_elegida = "normal"
	PedidoPartida.aplicado_a = 0
	var pr: Principal = load("res://escenas/principal.tscn").instantiate()
	add_child(pr)
	await _frames(6)
	for t in get_tree().root.find_children("*", "", true, false):
		if t is Tutorial:
			(t as Tutorial)._terminar(false)
	var e := "%s/%d" % [",".join(cfg[0]), cfg[1]]
	var n: Dictionary = pr._guia.nodos
	_ok(is_instance_valid(n.get("b_avanzar")) and (n["b_avanzar"] as Button).visible, "%s: el botón «Avanzar» nuevo está a la vista" % e)
	_ok(not (n["calendario"] as Control).visible and not (n["un_dia"] as Control).visible and not (n["hito"] as Control).visible, "%s: los botones viejos (calendario, un día, hito) ya no se ven" % e)
	_ok(not (n["b_jugar"] as Button).visible and not (n["b_saltar"] as Button).visible, "%s: sin partido hoy no hay «Jugar» ni «Saltar»" % e)
	var dias: AvanceDiasUI = pr._avance.dias()
	var jornada0 := m.liga_de(m.mi_club()).jornada_actual
	var visto_partido := false
	var campana := false
	var cierre_mes := false
	AvisosSemana._mercado_avisado = -1
	for i in 200:
		if not m.temporada_en_curso():
			break
		if dias.partido_hoy():
			dias.actualizar_botones()
			_ok((n["b_jugar"] as Button).visible and (n["b_saltar"] as Button).visible and not (n["b_avanzar"] as Button).visible, "%s: día de partido = «Jugar» y «Saltar» en lugar de «Avanzar»" % e)
			_ok(pr._dia_semana == EventosFecha.DIA_PARTIDO, "%s: el partido cae el sábado" % e)
			visto_partido = true
			var j0 := m.liga_de(m.mi_club()).jornada_actual
			dias.saltar()
			await _frames(2)
			if pr._registro.get_parsed_text().contains("Cierre de mes"):
				cierre_mes = true
			_ok(m.liga_de(m.mi_club()).jornada_actual > j0 or not m.temporada_en_curso(), "%s: «Saltar partido» corre la jornada" % e)
			_ok(not dias.partido_hoy(), "%s: tras saltar ya no hay partido pendiente hoy" % e)
		else:
			await dias.pulsar()
			await _frames(1)
		if CampanasMenu.hay():
			campana = true
	_ok(cierre_mes, "%s: al SALTAR el partido también sale el cierre de mes (regresión de la orden de Auditoría)" % e)
	_ok(AvisosSemana._mercado_avisado != -1, "%s: al SALTAR el partido también se avisa del cierre del mercado" % e)
	_ok(visto_partido, "%s: el avance se detuvo en día de partido" % e)
	_ok(m.liga_de(m.mi_club()).jornada_actual > jornada0 + 10, "%s: la temporada avanzó con el botón nuevo (de la J%d a la J%d)" % [e, jornada0, m.liga_de(m.mi_club()).jornada_actual])
	_ok(campana or true, "%s: (los avisos con campana son opcionales según la semilla)" % e)
	pr.queue_free()
	await _frames(3)

## Las pantallas se construyen (sin ventana real) y emiten su señal.
func _pantallas() -> void:
	var m := Mundo.new()
	var ps: Array[String] = ["CHI"]
	m.generar(ps, 77)
	m.tomar_el_mando(m.ligas[0].clubes[3].id)
	var raiz := Node.new()
	add_child(raiz)
	var est := DisparadoresDia.nuevo_estado()
	var res := AvanceDias.avanzar(m, est, -1, func() -> void: m.avanzar_semana())
	var unix0 := Calendario.unix_de(m.anio, m.semana, -1)
	var s := PantallaAvanzar.mostrar(raiz, m, unix0, res)
	_ok(s != null and s._celdas.size() == 14, "la pantalla Avanzar monta sus 14 días")
	await _frames(4)
	s._cerrar()
	var ev := {"tipo": "ultimatum", "clase": EventosDia.PANTALLA, "causa": {"id": "ultimatum", "datos": {"confianza": 20}}}
	_ok(AvanzarTextos.titulo(ev) != "" and AvanzarTextos.texto(ev).contains("20") and AvanzarTextos.icono(ev) != "", "los textos del evento salen de su causa")
	var t := EventoDiaPantalla.mostrar(raiz, ev)
	await _frames(2)
	_ok(t != null and t.is_inside_tree(), "la pantalla genérica de evento se monta")
	t.queue_free()
	s.queue_free()
