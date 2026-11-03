extends Node
## CUÁNTO TARDA UNA SEMANA (01-11-2026, fase 5 «optimización»): mide `Mundo.avanzar_semana()` en un mundo de 6 países con el
## perfilador de funciones apagado; imprime la media, el máximo y las 3 semanas más lentas. Herramienta, no prueba del banco.
##   godot --headless --path . res://pruebas/zz_medir_semana.tscn   (PAISES=CHI,ESP,ENG o PAISES=TODOS; SEMANAS=20)
func _ready() -> void:
	var paises := (OS.get_environment("PAISES") if OS.get_environment("PAISES") != "" else "CHI,ARG,BRA,ESP,ENG,ITA").split(",")
	var n := int(OS.get_environment("SEMANAS")) if OS.get_environment("SEMANAS") != "" else 20
	var m := Mundo.new()
	var t0 := Time.get_ticks_usec()
	var lista: Array[String] = []
	if paises != PackedStringArray(["TODOS"]):   ## PAISES=TODOS: el mundo entero (las ligas de todos los países), como en la partida
		for x in paises:
			lista.append(String(x))
	m.generar(lista, 4711)
	print("generar: %.0f ms (%d clubes)" % [(Time.get_ticks_usec() - t0) / 1000.0, m.clubes.size()])
	var tiempos: Array = []
	for i in n:
		var t := Time.get_ticks_usec()
		m.avanzar_semana()
		tiempos.append([(Time.get_ticks_usec() - t) / 1000.0, m.semana])
	var suma := 0.0
	for x: Array in tiempos:
		suma += float(x[0])
	tiempos.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	print("SEMANA media %.0f ms, máx %.0f ms (semana %d); lentas: %s" % [suma / n, float(tiempos[0][0]), int(tiempos[0][1]), str(tiempos.slice(0, 3))])
	get_tree().quit()
