class_name BotonesAvance
extends RefCounted
## LOS BOTONES DEL AVANCE POR DÍAS en la fila de acciones del menú central (17-11-2026, orden del dueño): «⏩ Avanzar» reemplaza al desplegable de calendario, a
## «Un día» y a «Hito» (siguen en el árbol, ocultos: las pruebas y la guía los encuentran). Abre la pantalla de avance por días; el día de partido deja
## «Jugar partido» y «Saltar partido» en su lugar; con la liga terminada, «Temporada siguiente». Lo que hace cada uno vive en `AvanceDiasUI` (se carga al usar).

static func montar(p: Principal, viejos: Array) -> void:
	for viejo: Control in viejos:
		viejo.visible = false
	var nuevos := [["avanzar", "⏩ Avanzar", "Avanza el tiempo día a día: se detiene en cada partido y en cada novedad.", func() -> void: desplegar(p)],
		["jugar", "⚽ Jugar partido", "Juega el partido de hoy.", func() -> void: p._avance.dias().jugar()],
		["saltar", "⏭ Saltar partido", "Simula el partido de hoy y sigue.", func() -> void: p._avance.dias().saltar()],
		["temporada", "🏁 Temporada siguiente", "La liga terminó: empieza la temporada siguiente.", func() -> void: p._al_elegir_calendario(3)]]
	for n: Array in nuevos:
		var bn := Button.new()
		bn.text = Idiomas.t(String(n[1]))
		bn.tooltip_text = Idiomas.t(String(n[2]))
		bn.custom_minimum_size = Vector2(150, 32)
		bn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bn.pressed.connect(n[3] as Callable)
		bn.visible = String(n[0]) == "avanzar"
		p._botones.add_child(bn)
		p._guia.nodos["b_" + String(n[0])] = bn
	var bj := Button.new()   ## (17-11) «PARTIDO JUGADO ▲ 1-0»: el popup de después del partido (`PopupPartidoJugado`); lo muestra `AvanceDiasUI.actualizar_botones`
	bj.custom_minimum_size = Vector2(150, 32)
	bj.visible = false
	bj.pressed.connect(func() -> void: p._avance.dias().abrir_jugado(bj))
	p._botones.add_child(bj)
	p._guia.nodos["b_jugado"] = bj
	p._guia.nodos["avanzar"] = p._guia.nodos["b_avanzar"]
	p._guia.nodos["avanzar_caja"] = p._botones

## El desplegable de «Avanzar» (como el del PES 2020, que ofrece «Avanzar 1 hora» y «Siguiente»): «Avanzar 1 día» y «Siguiente» (hasta el próximo evento).
static func desplegar(p: Principal, ancla: Control = null) -> void:   ## (17-11) `ancla`: de dónde cuelga el desplegable (la pestaña «Avanzar en el tiempo» del menú central)
	var b: Button = p._guia.nodos["b_avanzar"]
	var pop := b.get_node_or_null("Desplegable") as PopupMenu
	if pop == null:
		pop = PopupMenu.new()
		pop.name = "Desplegable"
		pop.add_item(Idiomas.t("Avanzar 1 día"), 0)
		pop.add_item(Idiomas.t("Siguiente"), 1)
		pop.id_pressed.connect(func(id: int) -> void: p._avance.dias().pulsar(id == 0))
		b.add_child(pop)
	var r := (ancla if ancla != null else b).get_global_rect()
	pop.popup(Rect2i(Vector2i(int(r.position.x), int(r.position.y + r.size.y)), Vector2i(maxi(int(r.size.x), 220), 0)))
