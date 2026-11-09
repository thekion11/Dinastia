extends BaseIdea
## M-292 (2-11): seguir a un club: su resultado de cada jornada llega a la bandeja, y la lista se guarda con la partida.
##   herramientas/ideas.sh seg_clubes

func _ready() -> void:
	await get_tree().process_frame
	_titulo("M-292: SEGUIR CLUBES")
	var pr: Principal = load("res://escenas/principal.tscn").instantiate()
	add_child(pr)
	pr._autoguardado = false
	var mio := pr.mundo.mi_club()
	var otro: Club = null
	for c: Club in pr._liga_de(mio).clubes:
		if c != mio:
			otro = c
			break
	_comprobar(pr.mundo.ojeadores.alternar_club(otro) and pr.mundo.ojeadores.sigue_club(otro), "se puede seguir a %s" % otro.nombre)
	AvanceSemana.partido_obliga = false
	pr._bandeja.clear()
	pr._avanzar_semana()
	pr._avanzar_semana()
	var avisos := 0
	for it: Dictionary in pr._bandeja:
		if String(it["titulo"]).begins_with("📌") and String(it["titulo"]).contains(otro.nombre) and String(it["cuerpo"]).contains(otro.nombre):
			avisos += 1
	_comprobar(avisos >= 1 and avisos <= 2, "tras dos semanas hay su resultado en la bandeja, uno por jornada (%d)" % avisos)
	var d := Partida.instantanea(pr.mundo)
	var m2 := Partida.desde_instantanea(d.duplicate(true))
	_comprobar(m2.ojeadores.clubes_seguidos.has(otro.id), "la lista de clubes seguidos se guarda con la partida")
	_comprobar(not pr.mundo.ojeadores.alternar_club(otro) and not pr.mundo.ojeadores.sigue_club(otro), "y se deja de seguir")
	pr.queue_free()
	await get_tree().process_frame
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)
