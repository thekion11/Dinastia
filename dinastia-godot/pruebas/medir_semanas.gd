extends Node
## COSTE DE SIMULAR SEMANAS (etapa 3 / bucle de optimización): mundo con varias
## ligas, N semanas seguidas sin interfaz. Imprime ms por semana y, con PERFIL=1,
## el desglose por funciones de `Mundo` usando el profiler de GDScript simple
## (tiempos acumulados por llamada marcada). Sin gráfica.
##   godot --headless --path . res://pruebas/medir_semanas.tscn
func _ready() -> void:
	## TODAS=1: la base real con todos los países del juego (el mundo más grande que se juega).
	var todas := OS.get_environment("TODAS") != ""
	if todas:
		Datos.usar_base_real(true)
	var m := Mundo.new()
	var t0 := Time.get_ticks_usec()
	var paises: Array[String] = ["CHI", "ARG", "ESP", "ENG", "BRA", "ITA"]
	if todas:
		paises = ["CHI", "ARG", "BRA", "URU", "PAR", "PER", "COL", "ECU", "ESP", "ENG", "ITA", "GER", "FRA", "MEX", "KSA", "POR", "NED", "TUR"]
	m.generar(paises, 99)
	print("MEDIDA generar mundo (%d ligas): %.0f ms" % [m.ligas.size(), (Time.get_ticks_usec() - t0) / 1000.0])
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var tiempos: Array[float] = []
	for i in int(OS.get_environment("SEMANAS")) if OS.get_environment("SEMANAS") != "" else 40:
		var t := Time.get_ticks_usec()
		m.avanzar_semana()
		tiempos.append((Time.get_ticks_usec() - t) / 1000.0)
	var s := 0.0
	var mx := 0.0
	for x in tiempos:
		s += x
		mx = maxf(mx, x)
	print("MEDIDA semana: media %.1f ms, peor %.1f ms (%d semanas)" % [s / tiempos.size(), mx, tiempos.size()])
	get_tree().quit()
