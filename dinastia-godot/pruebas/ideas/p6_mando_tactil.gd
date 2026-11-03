extends BaseIdea
## C5 + C6 (3-11, prueba del dueño): en el móvil, palanca analógica suave a la izquierda y mirar arrastrando a la derecha; el paseo la lee y el cabeceo llega a la cámara de primera persona.

func _toque(m: MandoTactil, idx: int, pos: Vector2, pulsado: bool) -> void:
	var t := InputEventScreenTouch.new()
	t.index = idx
	t.position = pos
	t.pressed = pulsado
	m._input(t)

func _arrastre(m: MandoTactil, idx: int, pos: Vector2, rel: Vector2) -> void:
	var d := InputEventScreenDrag.new()
	d.index = idx
	d.position = pos
	d.relative = rel
	m._input(d)

func _probar() -> void:
	_titulo("P6: MANDO TACTIL · PALANCA ANALOGICA Y MIRAR CON EL DEDO")
	var e := ExploradorCiudad.new()
	add_child(e)
	var capa := Control.new()
	add_child(capa)
	var m := MandoTactil.new()
	m.explorador = e
	e.set_meta(MandoTactil.META, m)
	capa.add_child(m)
	await get_tree().process_frame
	var t := m.get_viewport_rect().size
	_comprobar(MandoTactil.leer(e, Vector2(0.3, 0.3)) == Vector2(0.3, 0.3), "sin tocar, el paseo usa el respaldo (teclado)")
	var base := Vector2(t.x * 0.15, t.y * 0.75)
	_toque(m, 0, base, true)
	_arrastre(m, 0, base + Vector2(0, -MandoTactil.RADIO * 0.5), Vector2.ZERO)   ## medio recorrido hacia delante
	for i in 30:
		await get_tree().process_frame
	var medio := m.valor
	_comprobar(medio.y > 0.15 and medio.y < 0.65 and absf(medio.x) < 0.05, "medio recorrido hacia delante = avance a medias (%.2f), sin girar" % medio.y)
	_comprobar(not MandoTactil.corre(e), "a medias no corre")
	_arrastre(m, 0, base + Vector2(MandoTactil.RADIO, -MandoTactil.RADIO), Vector2.ZERO)
	for i in 30:
		await get_tree().process_frame
	_comprobar(m.valor.y > 0.6 and m.valor.x > 0.6, "diagonal a tope = avanza y gira a la derecha (%.2f, %.2f)" % [m.valor.x, m.valor.y])
	_arrastre(m, 0, base + Vector2(0, -MandoTactil.RADIO), Vector2.ZERO)
	for i in 40:
		await get_tree().process_frame
	_comprobar(MandoTactil.corre(e), "a tope hacia delante corre")
	_toque(m, 0, base, false)
	var anterior := m.valor.y
	var bajada_suave := true
	var saltos := 0.0
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 1500 and m.valor != Vector2.ZERO:
		await get_tree().process_frame
		saltos = maxf(saltos, anterior - m.valor.y)
		if m.valor.y > anterior + 0.0001:
			bajada_suave = false
		anterior = m.valor.y
	_comprobar(m.valor == Vector2.ZERO and bajada_suave and saltos < 0.35, "al soltar se frena sin tirones (mayor salto %.2f por fotograma)" % saltos)
	## El pulgar derecho mira.
	var rumbo0: float = e.rumbo
	var der := Vector2(t.x * 0.7, t.y * 0.5)
	_toque(m, 1, der, true)
	_arrastre(m, 1, der + Vector2(-100, -60), Vector2(-100, -60))
	await get_tree().process_frame
	await get_tree().process_frame
	_comprobar(e.rumbo > rumbo0 + 0.3, "arrastrar a la izquierda gira el rumbo (%.2f rad)" % (e.rumbo - rumbo0))
	_comprobar(float(e.get_meta("cabeceo", -0.15)) > -0.15 + 0.2, "arrastrar hacia arriba levanta la mirada (primera persona)")
	_toque(m, 1, der, false)
	## Los botones de la esquina no mueven la mirada.
	_toque(m, 2, Vector2(t.x - 100.0, t.y - 60.0), true)
	_arrastre(m, 2, Vector2(t.x - 140.0, t.y - 60.0), Vector2(-40, 0))
	var r1: float = e.rumbo
	await get_tree().process_frame
	_comprobar(absf(e.rumbo - r1) < 0.001, "tocar la zona de los botones (E, cámara, Salir) no gira la mirada")
