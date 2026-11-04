extends BaseIdea
## EL ENTRENAMIENTO SE NOTA (01-11-2026, fase 9 «entrenamiento» de la orden del dueño). El MISMO club (mismo mundo y semilla)
## entrena 12 semanas con decisiones distintas y se comparan el progreso (suma de medias), el físico y las lesiones: la
## intensidad, el foco y el plan de días tienen que cambiar el resultado, no ser adornos.

## (4-11, A4-GES-006) 8 semillas sumadas: con una sola, +9 contra +10 en una decena de jóvenes era ruido del azar (cualquier ajuste del entrenamiento movía el resultado).
const SEMILLAS := [4711, 4712, 4713, 4714, 4715, 4716, 4717, 4718]

func _entrenar(config: Callable) -> Dictionary:
	var tot := {"sube": 0, "jovenes": 0, "fisico": 0.0, "lesiones": 0}
	for semilla in SEMILLAS:
		var r := _entrenar_una(config, semilla)
		for k: String in tot:
			tot[k] = tot[k] + r[k]
	return tot

func _entrenar_una(config: Callable, semilla: int) -> Dictionary:
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
	_comprobar(int(tecnico["jovenes"]) > int(normal["jovenes"]), "el foco técnico hace crecer más a los jóvenes (%+d frente a %+d)" % [int(tecnico["jovenes"]), int(normal["jovenes"])])
	_comprobar(float(descanso["fisico"]) > float(normal["fisico"]) and int(descanso["sube"]) < int(normal["sube"]), "todo descanso: más físico y menos progreso")
