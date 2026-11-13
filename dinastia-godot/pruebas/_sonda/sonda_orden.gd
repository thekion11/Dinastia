extends Node
func _playoff() -> String:
	var m := Mundo.new()
	m.generar(["ENG"] as Array[String], 602)
	var eng2: Liga = m.ligas.filter(func(l: Liga) -> bool: return l.division() == 2)[0]
	var cuatro: Array[Club] = []
	for i in 4:
		cuatro.append(eng2.clubes[i])
	var s := ""
	for i in 6:
		Azar.sembrar(700 + i)
		s += AscensosPais.playoff_de_ascenso(m, cuatro).nombre.substr(0, 6) + " "
	return s + " | reps " + str(cuatro.map(func(c: Club) -> int: return c.rep)) + " medias " + str(cuatro.map(func(c: Club) -> int: return roundi(c.media())))
func _ready() -> void:
	print("LIMPIO  ", _playoff())
	var m := Mundo.new()
	m.generar([OS.get_environment("PAISES")], 20261103)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	print("TRAS GENERAR+MANDO  ", _playoff())
	for s in 4:
		m.avanzar_semana()
	print("TRAS 4 SEMANAS  ", _playoff())
	get_tree().quit()
