extends BaseIdea
## EL PARTIDO REACCIONA (01-11-2026, fase 4 «jugabilidad», «verificar jugando» 251, 361, 362, 378 y 1036). Al probarlo salieron dos
## huecos, ya arreglados: el clima no tocaba la asistencia (`Clima.factor_publico`) y los clubes de la IA nunca cambiaban de
## plan en el minuto 60 (solo había plan si lo ponía el usuario).

## (03-11) 40 partidos por lado daban un error de ±0,37 goles en la diferencia, del tamaño del efecto (~0,3): con cualquier cambio del partido simulado el signo salía al revés. Ahora 600 por lado (±0,1).
func _goles(m: Mundo, riesgo: bool) -> float:
	var g := 0
	for i in 600:
		## (Los partidos lesionan y suspenden en serio: sin esto, 600 partidos dejan a las plantillas hechas polvo y la medida —y las pruebas de después— se tuercen.)
		for c: Club in [m.ligas[0].clubes[i % 8], m.ligas[0].clubes[8 + i % 8]]:
			for jg: Jugador in c.plantilla:
				jg.lesion = 0
				jg.suspension = 0
		var p := Partido.new(m.ligas[0].clubes[i % 8], m.ligas[0].clubes[8 + i % 8])
		p.preparar()
		p.instr_riesgo = riesgo
		## Las instrucciones solo pegan de TU lado (`ctx_club_id`): sin un club propio, «arriesgar» no hacía NADA y la prueba comparaba dos veces lo mismo (pasaba o fallaba por suerte).
		Partido.ctx_club_id = p.local.id
		while not p.terminado_ya:
			p.simular_minuto()
		g += p.goles_local + p.goles_visita
	Partido.ctx_club_id = ""
	return float(g) / 600.0

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
	## 1036: el once elegido con un lesionado avisa.
	var c: Club = m.ligas[0].clubes[4]
	var xi := c.once()
	c.once_elegido.clear()
	for jx: Jugador in xi:
		c.once_elegido.append(jx.id)
	_comprobar(AvisoOnce.motivo(c) == "", "un once elegido sano no avisa")
	xi[3].lesion = 2
	var aviso := AvisoOnce.motivo(c)
	_comprobar(aviso.contains(xi[3].nombre) and aviso.contains("lesionado"), "con un lesionado en el once, avisa: «%s»" % aviso)
