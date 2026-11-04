extends BaseIdea
## EL ENTRENAMIENTO SE NOTA (01-11-2026, fase 9 «entrenamiento» de la orden del dueño). El MISMO club (mismo mundo y semilla)
## entrena 12 semanas con decisiones distintas y se comparan el progreso (suma de medias), el físico y las lesiones: la
## intensidad, el foco y el plan de días tienen que cambiar el resultado, no ser adornos.

func _entrenar(config: Callable, semilla := 4711) -> Dictionary:
	var m := Mundo.new()
	m.generar(["CHI"], semilla)
	var c: Club = m.ligas[0].clubes[0]
	var e := Entrenamiento.new()
	config.call(e)
	var antes := 0
	var jovenes_antes := 0
	for j: Jugador in c.plantilla:
		antes += j.ovr
		j.fisico = 70
		if j.edad < 24:
			jovenes_antes += j.ovr
	var lesiones := 0
	var fisico := 0.0
	for s in 12:
		for j: Jugador in c.plantilla:
			j.fisico = clampi(j.fisico - 30, 10, 100)   ## el partido de la semana cansa
		var r := e.procesar_semana(c, 2026, 10 + s)
		lesiones += (r["lesionados"] as Array).size()
		for j: Jugador in c.plantilla:
			fisico += float(j.fisico) / float(c.plantilla.size() * 12)   ## el físico con que llega al partido
	var despues := 0
	var jovenes := 0
	for j: Jugador in c.plantilla:
		despues += j.ovr
		if j.edad < 24:
			jovenes += j.ovr
	return {"sube": despues - antes, "jovenes": jovenes - jovenes_antes, "fisico": fisico, "lesiones": lesiones}

func _probar() -> void:
	_titulo("EL ENTRENAMIENTO SE NOTA")
	var normal := _entrenar(func(_e: Entrenamiento) -> void: pass)
	var suave := _entrenar(func(e: Entrenamiento) -> void: e.fijar_intensidad("baja"))
	var duro := _entrenar(func(e: Entrenamiento) -> void: e.fijar_intensidad("alta"))
	var recup := _entrenar(func(e: Entrenamiento) -> void: e.fijar_foco("recup"))
	var tecnico := _entrenar(func(e: Entrenamiento) -> void: e.fijar_foco("tecnico"))
	var descanso := _entrenar(func(e: Entrenamiento) -> void:
		for i in e.dias.size():
			e.fijar_dia(i, "descanso"))
	_linea("  normal %s · suave %s · al límite %s · recuperación %s · técnico %s · todo descanso %s" % [normal, suave, duro, recup, tecnico, descanso])
	_comprobar(int(duro["sube"]) > int(suave["sube"]), "al límite se progresa más que suave (%+d frente a %+d)" % [int(duro["sube"]), int(suave["sube"])])
	_comprobar(int(duro["lesiones"]) >= int(suave["lesiones"]), "y se lesiona igual o más (%d frente a %d)" % [int(duro["lesiones"]), int(suave["lesiones"])])
	_comprobar(float(recup["fisico"]) > float(normal["fisico"]), "el foco recuperación llega con más físico (%.0f frente a %.0f)" % [float(recup["fisico"]), float(normal["fisico"])])
	## (4-11, A4) Con el freno y el tope de la temporada, una sola semilla de 12 semanas daba +9 frente a +10 por puro azar: se suman 4 semillas.
	var jt := 0
	var jn := 0
	for sem in [4711, 4712, 4713, 4714]:
		jt += int(_entrenar(func(e: Entrenamiento) -> void: e.fijar_foco("tecnico"), sem)["jovenes"])
		jn += int(_entrenar(func(_e: Entrenamiento) -> void: pass, sem)["jovenes"])
	_comprobar(jt > jn, "el foco técnico hace crecer más a los jóvenes (%+d frente a %+d en 4 semillas)" % [jt, jn])
	_comprobar(float(descanso["fisico"]) > float(normal["fisico"]) and int(descanso["sube"]) < int(normal["sube"]), "todo descanso: más físico y menos progreso")
