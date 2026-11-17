class_name BotonesAvance
extends RefCounted
## LOS BOTONES DEL AVANCE POR DÍAS en la fila de acciones del menú central (17-11-2026, orden del dueño): «⏩ Avanzar» reemplaza al desplegable de calendario, a
## «Un día» y a «Hito» (siguen en el árbol, ocultos: las pruebas y la guía los encuentran). Abre la pantalla de avance por días; el día de partido deja
## «Jugar partido» y «Saltar partido» en su lugar; con la liga terminada, «Temporada siguiente». Lo que hace cada uno vive en `AvanceDiasUI` (se carga al usar).

static func montar(p: Principal, viejos: Array) -> void:
	for viejo: Control in viejos:
		viejo.visible = false
	var nuevos := [["avanzar", "⏩ Avanzar", "Avanza el tiempo día a día: se detiene en cada partido y en cada novedad.", func() -> void: p._avance.dias().pulsar()],
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
	p._guia.nodos["avanzar"] = p._guia.nodos["b_avanzar"]
	p._guia.nodos["avanzar_caja"] = p._botones
