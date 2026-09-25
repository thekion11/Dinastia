extends Node

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 777)
	var orden := m.ligas[0].clubes.duplicate()
	orden.sort_custom(func(a: Club, b: Club) -> bool: return a.rep < b.rep)
	m.tomar_el_mando(orden[0].id)
	var mio := m.mi_club()
	print("club=", mio.nombre, " rep=", mio.rep)
	var C := Cantera.new(m)
	C.sembrar_leyendas()
	var cont := [0, 0]   # array: las lambdas de GDScript capturan por valor, los arrays por referencia
	C.canterano_robado.connect(func(_j, _d, _c) -> void: cont[0] += 1)
	for t in 12:
		m.jugar_temporada()
		var antes := mio.plantilla.size()
		m.nueva_temporada()
		var tras_repo := mio.plantilla.size()
		var chicos := C.camada_anual().size()
		for s in 38:
			C.procesar_semana()
		print("  temp ", t + 1, ": fin=", antes, " tras reposicion=", tras_repo, " +camada=", chicos,
			" fin de anio=", mio.plantilla.size(), " robados acumulados=", cont[0],
			" juv=", C.juveniles(mio, 20).size())
	print("TOTAL robados=", cont[0], " plantilla=", mio.plantilla.size())
	# ahora con residencia, sala de juegos y becas: el mismo club, protegido
	m.obras.niveles["resid"] = 5
	m.obras.niveles["esports"] = 5
	m.obras.niveles["acad"] = 5
	m.staff.niveles["cantera"] = 5
	print("con obras: retencion=", m.obras.retencion_juvenil(), " bono camada=", C.bono_de_camada())
	cont[0] = 0
	for t in 6:
		m.jugar_temporada(); m.nueva_temporada(); C.camada_anual()
		for s in 38: C.procesar_semana()
	print("protegido 6 temporadas: robados=", cont[0], " plantilla=", mio.plantilla.size(),
		" juv=", C.juveniles(mio, 20).size())
	var juv := C.juveniles(mio, 20)
	for j in juv: print("   ", j.nombre, " ", j.edad, "a ovr=", j.ovr, " pot=", j.pot, " fuga=", snappedf(C.riesgo_fuga(j), 0.001))
	get_tree().quit()
