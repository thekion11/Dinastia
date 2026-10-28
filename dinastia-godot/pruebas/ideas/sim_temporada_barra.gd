extends BaseIdea
## IDEA 1032 (28-10-2026): «Simular toda la temporada» va semana a semana con un panel de progreso (barra, «Jornada N de M»
## y «Detener»). Se detiene a medias (la temporada sigue en curso, como avanzada a mano) y luego se acaba entera.
##   herramientas/ideas.sh sim_temporada_barra

func _ready() -> void:
	await get_tree().process_frame
	_titulo("1032: SIMULAR LA TEMPORADA CON BARRA DE PROGRESO")
	var pr: Principal = load("res://escenas/principal.tscn").instantiate()
	add_child(pr)
	pr._autoguardado = false
	var j := pr._jornada
	var liga: Liga = pr._liga_de(pr.mundo.mi_club())
	var desde := liga.jornada_actual
	j._jugar_temporada()
	await get_tree().process_frame
	await get_tree().process_frame
	var velo: Control = null
	for h in pr.get_children():
		if h is ColorRect and h.has_meta("barra"):
			velo = h
	_comprobar(velo != null and j._simulando, "al pulsar sale el panel y la simulación corre por semanas")
	var barra: ProgressBar = velo.get_meta("barra") if velo != null else null
	for i in 6:
		await get_tree().process_frame
	_comprobar(barra != null and barra.value > 0.0 and liga.jornada_actual > desde, "la barra avanza (%.0f %%, jornada %d)" % [barra.value if barra else 0.0, liga.jornada_actual])
	_comprobar(String((velo.get_meta("rotulo") as Label).text).contains(str(liga.calendario.size())), "dice «Jornada N de %d»" % liga.calendario.size())
	j._jugar_temporada()
	_comprobar(j._simulando, "pulsar otra vez no lanza una segunda simulación")
	j._detener = true
	while j._simulando:
		await get_tree().process_frame
	_comprobar(pr.mundo.temporada_en_curso() and (not is_instance_valid(velo) or velo.is_queued_for_deletion()), "«Detener» para a medias: la temporada sigue en curso y el panel se va")
	var anio := pr.mundo.anio
	var hubo := [false]
	pr.mundo.temporada_terminada.connect(func(_a: int, _c: Variant) -> void: hubo[0] = true)
	j._jugar_temporada()
	var t0 := Time.get_ticks_msec()
	while j._simulando and Time.get_ticks_msec() - t0 < 240000:
		await get_tree().process_frame
	_comprobar(not pr.mundo.temporada_en_curso() and hubo[0], "otra vez hasta el final: temporada %d acabada y señal de cierre emitida" % anio)
	pr.queue_free()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)
