extends Node
## COSTE POR FUNCIÓN DEL MINUTO SIMULADO (10-11-2026, paso a C++): llama cada pieza de `Partido` por separado sobre ~100 partidos preparados de un mundo entero. Herramienta, no prueba del banco.
##   godot --headless --path . res://pruebas/zz_perfil_minuto.tscn
func _t(nombre: String, partidos: Array, f: Callable, veces := 200) -> void:
	var t0 := Time.get_ticks_usec()
	for i in veces:
		for p: Partido in partidos:
			f.call(p)
	var us := float(Time.get_ticks_usec() - t0) / (veces * partidos.size())
	print("  %-28s %8.2f µs por llamada" % [nombre, us])
func _ready() -> void:
	var m := Mundo.new()
	m.generar([], 777)
	m.reloj.sincronizar(m.anio, m.semana)
	Partido.ctx_anio = m.anio
	Partido.ctx_semana = m.semana
	var ps: Array = []
	for l: Liga in m.ligas:
		for i in range(0, l.clubes.size() - 1, 2):
			var p := Partido.new(l.clubes[i], l.clubes[i + 1])
			p.preparar()
			ps.append(p)
			if ps.size() >= 100:
				break
		if ps.size() >= 100:
			break
	Azar.sembrar(4711)
	print("COSTE POR FUNCIÓN (%d partidos preparados)" % ps.size())
	_t("fuerza(once local)", ps, func(p: Partido) -> void: p.fuerza(p.once_local, p.local), 20)
	_t("_probabilidad", ps, func(p: Partido) -> void: p._probabilidad(p._fza_local["ata"], p._fza_visita["def"]), 200)
	_t("_chequeo_arbitral", ps, func(p: Partido) -> void: p._chequeo_arbitral())
	_t("_elegir_goleador", ps, func(p: Partido) -> void: p._elegir_goleador(p.once_local), 100)
	_t("_elegir_asistente", ps, func(p: Partido) -> void: p._elegir_asistente(p.once_local, p.once_local[9], 30), 50)
	_t("_alguien", ps, func(p: Partido) -> void: p._alguien(p.once_local))
	_t("_incidencias", ps, func(p: Partido) -> void: p._incidencias(), 50)
	_t("_atacar(local)", ps, func(p: Partido) -> void: p._atacar(p.local, p.once_local, true), 50)
	_t("simular_minuto (completo)", ps, func(p: Partido) -> void:
		p.terminado_ya = false
		p.minuto = 20
		p.simular_minuto(), 50)
	get_tree().quit()
