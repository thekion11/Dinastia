extends Node
## COSTE DE SIMULAR SEMANAS (etapa 3 / bucle de optimización): mundo con varias
## ligas, N semanas seguidas sin interfaz. Imprime ms por semana y, con PERFIL=1,
## el desglose por funciones de `Mundo` usando el profiler de GDScript simple
## (tiempos acumulados por llamada marcada). Sin gráfica.
##   godot --headless --path . res://pruebas/medir_semanas.tscn
func _ready() -> void:
	var m := Mundo.new()
	var t0 := Time.get_ticks_usec()
	m.generar(["CHI", "ARG", "ESP", "ENG", "BRA", "ITA"], 99)
	print("MEDIDA generar mundo (6 ligas): %.0f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var tiempos: Array[float] = []
	for i in 40:
		var t := Time.get_ticks_usec()
		m.avanzar_semana()
		tiempos.append((Time.get_ticks_usec() - t) / 1000.0)
	var s := 0.0
	var mx := 0.0
	for x in tiempos:
		s += x
		mx = maxf(mx, x)
	print("MEDIDA semana: media %.1f ms, peor %.1f ms (40 semanas)" % [s / tiempos.size(), mx])
	get_tree().quit()
