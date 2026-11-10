extends Node
## DÓNDE SE VA `Partido.preparar()` (10-11-2026, paso a C++): por piezas, sobre cruces de la IA de un mundo entero. Herramienta, no prueba del banco.
##   godot --headless --path . res://pruebas/zz_perfil_preparar.tscn
func _ready() -> void:
	var m := Mundo.new()
	m.generar([], 777)
	var clubes: Array = m.clubes.values()
	var t := {"preparar() entero": 0.0, "  once x2": 0.0, "  Clima.del_partido": 0.0, "  Previa.arbitro_de": 0.0, "  bucle notas/titulares": 0.0}
	var n := 0
	for v in 3:
		for i in range(0, clubes.size() - 1, 2):
			var l: Club = clubes[i]
			var vi: Club = clubes[i + 1]
			var p := Partido.new(l, vi)
			p.sin_rastro = true
			var a := Time.get_ticks_usec()
			p.preparar()
			var b := Time.get_ticks_usec()
			var o1 := l.once()
			var o2 := vi.once()
			var c := Time.get_ticks_usec()
			Clima.del_partido(l.pais, p.ctx_semana, p.ctx_anio, l.id + vi.id)
			var d := Time.get_ticks_usec()
			Previa.arbitro_de(vi.id, p.ctx_semana)
			var e := Time.get_ticks_usec()
			var notas := {}
			var tit := {}
			for j in o1 + o2:
				notas[j.id] = 6.0
				tit[j.id] = true
			var f := Time.get_ticks_usec()
			t["preparar() entero"] += b - a
			t["  once x2"] += c - b
			t["  Clima.del_partido"] += d - c
			t["  Previa.arbitro_de"] += e - d
			t["  bucle notas/titulares"] += f - e
			n += 1
	for k: String in t:
		print("   %-28s %7.1f µs por cruce" % [k, float(t[k]) / n])
	get_tree().quit()
