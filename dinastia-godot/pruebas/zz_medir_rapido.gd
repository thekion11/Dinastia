extends Node
## CUÁNTO TARDA UN CRUCE DE LA IA POR LA RUTA REAL (`PartidoRapido.simular`) y su reparto: preparar (onces, clima, árbitro) / 90 minutos nativos / cierre. Herramienta, no prueba del banco.
##   godot --headless --path . res://pruebas/zz_medir_rapido.tscn   (huella: debe ser igual con y sin DINASTIA_SIN_NATIVO=1)
func _ready() -> void:
	var m := Mundo.new()
	m.generar([], 777)
	m.reloj.sincronizar(m.anio, m.semana)
	var cruces: Array = []
	for l: Liga in m.ligas:
		var cl: Array = l.clubes
		for i in range(0, cl.size() - 1, 2):
			cruces.append([cl[i], cl[i + 1]])
	cruces = cruces.slice(0, 400)
	Partido.ctx_anio = m.anio
	Partido.ctx_semana = m.semana
	Azar.sembrar(4711)
	var huella := 0
	var t_tot := 0.0
	var t_prep := 0.0
	var t_cierre := 0.0
	for par: Array in cruces:
		var a := Time.get_ticks_usec()
		var p := Partido.new(par[0], par[1])
		var r := PartidoRapido.simular(p)
		t_tot += Time.get_ticks_usec() - a
		huella = hash([huella, r.local, r.visita, p.remates_local, p.remates_visita, p.cronica.size()])
	## preparar solo
	Azar.sembrar(4711)
	for par: Array in cruces:
		var p := Partido.new(par[0], par[1])
		var a := Time.get_ticks_usec()
		p.preparar()
		t_prep += Time.get_ticks_usec() - a
	var n := float(cruces.size())
	print("RAPIDO: %.0f µs por cruce (%d cruces, nativo=%d), preparar %.0f µs, resto %.0f µs, huella %d" % [t_tot / n, cruces.size(), PartidoRapido.por_ruta_nativa, t_prep / n, (t_tot - t_prep) / n, huella])
	get_tree().quit()
