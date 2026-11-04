extends Node
## CUÁNTO TARDA UN PARTIDO SIMULADO (3-11-2026): el que juegan las ligas de la IA cada semana (`Partido.simular`). Desglosa por fases sobre ~200 cruces de un mundo entero:
## crear el partido, el clima, los dos onces, el árbitro, el resto de `preparar`, los 90 minutos (con `_atacar`, `_incidencias` y el chequeo arbitral por separado) y el cierre.
## Imprime también una huella de los resultados (marcadores y goleadores) para comprobar que optimizar no cambia nada. Herramienta, no prueba del banco.
##   godot --headless --path . res://pruebas/zz_medir_simular.tscn
func _ready() -> void:
	var m := Mundo.new()
	m.generar([], 777)
	m.reloj.sincronizar(m.anio, m.semana)
	var cruces: Array = []
	for l: Liga in m.ligas:
		var cl: Array = l.clubes
		for i in range(0, cl.size() - 1, 2):
			cruces.append([cl[i], cl[i + 1]])
	cruces = cruces.slice(0, 200)
	Partido.ctx_anio = m.anio
	Partido.ctx_semana = m.semana
	var t := {"new": 0.0, "clima": 0.0, "once x2": 0.0, "árbitro": 0.0, "resto de preparar": 0.0, "90 minutos": 0.0, "cierre": 0.0}
	var huella := 0
	Azar.sembrar(4711)
	for par: Array in cruces:
		var a := Time.get_ticks_usec()
		var p := Partido.new(par[0], par[1])
		var b := Time.get_ticks_usec()
		p.fijar_clima(Clima.del_partido(p.local.pais, Partido.ctx_semana, Partido.ctx_anio, p.local.id + p.visita.id))
		var c := Time.get_ticks_usec()
		var o1 := p.local.once()
		var o2 := p.visita.once()
		var d := Time.get_ticks_usec()
		var arb := Previa.arbitro_de(p.visita.id, Partido.ctx_semana)
		var e := Time.get_ticks_usec()
		p.preparar()   ## repite clima/onces/árbitro: se resta al final lo medido arriba
		var f := Time.get_ticks_usec()
		while not p.terminado_ya:
			p.simular_minuto()
		var g := Time.get_ticks_usec()
		p._cerrar_notas()
		p.guardar_si_es_mio()
		var h := Time.get_ticks_usec()
		t["new"] += b - a
		t["clima"] += c - b
		t["once x2"] += d - c
		t["árbitro"] += e - d
		t["resto de preparar"] += (f - e) - ((c - b) + (d - c) + (e - d))
		t["90 minutos"] += g - f
		t["cierre"] += h - g
		huella = hash([huella, p.goles_local, p.goles_visita, p.remates_local, p.remates_visita, p.cronica.size(), arb])
		o1.size(); o2.size()
	var total := 0.0
	for k: String in t:
		total += float(t[k])
	for k: String in t:
		print("   %-18s %7.0f µs por partido  (%2.0f %%)" % [k, float(t[k]) / cruces.size(), 100.0 * float(t[k]) / total])
	print("partido simulado: %.0f µs en total, %d partidos, huella %d" % [total / cruces.size(), cruces.size(), huella])
	get_tree().quit()
