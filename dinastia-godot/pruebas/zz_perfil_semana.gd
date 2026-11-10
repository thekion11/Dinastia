extends Node
## DÓNDE SE VA LA SEMANA (10-11-2026, paso a C++): repite el orden de `Mundo.avanzar_semana` midiendo cada fase `_semana_*` por separado (mundo entero por defecto).
##   godot --headless --path . res://pruebas/zz_perfil_semana.tscn   (PAISES=CHI,ESP o TODOS; SEMANAS=20). Herramienta, no prueba del banco.
const FASES := ["_semana_contexto_de_partidos", "_semana_once_antes_de_jugar", "_semana_jugar_ligas", "_semana_caja_y_plantillas", "_semana_memoria_del_partido", "_semana_mercado",
		"_semana_lesion_insolita", "_semana_obras", "_semana_ojeo", "_semana_prensa_e_hinchada", "_semana_vestuario_y_marca", "_semana_carrera_del_dt", "_semana_club_por_dentro",
		"_semana_modulos_del_club", "_semana_banco", "_semana_ingresos_comerciales", "_semana_enfermeria", "_semana_entrenamiento", "_semana_federacion_y_plantel"]
func _ready() -> void:
	var env := OS.get_environment("PAISES")
	var lista: Array[String] = []
	if env != "TODOS" and env != "":
		for x in env.split(","):
			lista.append(String(x))
	var n := int(OS.get_environment("SEMANAS")) if OS.get_environment("SEMANAS") != "" else 20
	var m := Mundo.new()
	m.generar(lista, 4711)
	var t := {}
	var total := 0.0
	for i in n:
		var a0 := Time.get_ticks_usec()
		for f: String in FASES:
			var a := Time.get_ticks_usec()
			if f == "_semana_jugar_ligas" or f == "_semana_caja_y_plantillas" or f == "_semana_memoria_del_partido":
				if f == "_semana_jugar_ligas":
					m.set_meta("jug", m.call(f, null))
				elif f == "_semana_caja_y_plantillas":
					m.call(f, m.get_meta("jug"))
				else:
					m.call(f, null)
			else:
				m.call(f)
			t[f] = float(t.get(f, 0.0)) + (Time.get_ticks_usec() - a)
		m.semana += 1
		Jugador.semana_global = m.anio * 100 + m.semana
		total += Time.get_ticks_usec() - a0
	var filas: Array = []
	for f: String in t:
		filas.append([float(t[f]) / n / 1000.0, f])
	filas.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	print("PERFIL SEMANA (%d clubes, %d semanas): %.1f ms por semana" % [m.clubes.size(), n, total / n / 1000.0])
	for f: Array in filas:
		print("  %7.2f ms  %s" % [float(f[0]), f[1]])
	get_tree().quit()
