extends BaseIdea
## EL PARTIDO REACCIONA (01-11-2026, fase 4 «jugabilidad», «verificar jugando» 251, 361, 362 y 378). Al probarlo salieron dos
## huecos, ya arreglados: el clima no tocaba la asistencia (`Clima.factor_publico`) y los clubes de la IA nunca cambiaban de
## plan en el minuto 60 (solo había plan si lo ponía el usuario).

func _goles(m: Mundo, riesgo: bool) -> float:
	var g := 0
	for i in 40:
		var p := Partido.new(m.ligas[0].clubes[i % 8], m.ligas[0].clubes[8 + i % 8])
		p.preparar()
		p.instr_riesgo = riesgo
		while not p.terminado_ya:
			p.simular_minuto()
		g += p.goles_local + p.goles_visita
	return float(g) / 40.0

func _probar() -> void:
	_titulo("EL PARTIDO REACCIONA")
	## 251: el clima vacía la grada; el techo salva la lluvia, no la niebla.
	_comprobar(Clima.factor_publico({"clave": "lluvia"}) < 0.95 and Clima.factor_publico({"clave": "tormenta"}) < Clima.factor_publico({"clave": "lluvia"}),
		"lluvia y tormenta bajan el público (%.2f / %.2f)" % [Clima.factor_publico({"clave": "lluvia"}), Clima.factor_publico({"clave": "tormenta"})])
	_comprobar(Clima.factor_publico({"clave": "lluvia"}, true) == 1.0 and Clima.factor_publico({"clave": "niebla"}, true) < 1.0, "el techo retráctil salva la lluvia, no la niebla")
	_comprobar(Clima.factor({"clave": "lluvia"}) < 1.0, "y la lluvia sigue trabando el juego")
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	## 362: la arenga sube la moral y no se repite al minuto.
	var p := Partido.new(m.ligas[0].clubes[0], m.ligas[0].clubes[1])
	p.preparar()
	var j: Jugador = p.once_local[5]
	var moral := j.moral
	_comprobar(p.arengar(j) == "" and j.moral > moral, "la arenga sube la moral (%d → %d)" % [moral, j.moral])
	_comprobar(p.arengar(j) != "", "y no se puede repetir enseguida")
	## 361: arriesgar abre el partido.
	var normal := _goles(m, false)
	var arriesgando := _goles(m, true)
	_comprobar(arriesgando > normal, "con «arriesgar» hay más goles (%.2f frente a %.2f por partido)" % [arriesgando, normal])
	## 378: el club de la IA que va perdiendo en el 60' se vuelca.
	var a: Club = m.ligas[0].clubes[2]
	var b: Club = m.ligas[0].clubes[3]
	var q := Partido.new(a, b)
	q.preparar()
	q.goles_visita = 1
	var ment := a.tactica.mentalidad
	q._aplicar_plan()
	_comprobar(a.tactica.mentalidad > ment and String(q.plan_activado.get(a.id, "")) == "perdiendo:ofensivo", "la IA perdiendo se vuelca (%s)" % String(q.plan_activado.get(a.id, "")))
	q._devolver_tactica()
	_comprobar(a.tactica.mentalidad == ment, "y al final vuelve a su táctica")
