extends "res://pruebas/banco_p25_p1.gd"
## (Parte 2 de 2 de `banco_p25.gd`.)

func _probar_ideas_entrenamiento_prensa_y_dueno() -> void:
	_titulo("IDEAS DEL DUEÑO (416-430, 642-690, 774-793, 1035): plan de entrenamiento, pretemporada, prensa propia, capital del dueño e informe de gestión")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 2435)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	c.mover_saldo(500000000)
	## Entrenamiento (416-419, 426, 429, 430).
	var en: Entrenamiento = m.entrenamiento
	en.fijar_dia(0, "descanso")
	var c0 := en.carga()
	_comprobar(en.fijar_dia(0, "fisico") == "" and en.dias[0] == "fisico", "se fija el bloque de cada día de la semana (416)")
	_comprobar(en.fijar_dia(0, "no_existe") != "" and en.fijar_dia(99, "fisico") != "", "y se rechazan bloques o días que no existen")
	var c1 := en.carga()
	_comprobar(c1.hash() != c0.hash(), "cambiar un día cambia la carga del plan (físico, progreso, riesgo, moral) (417)")
	en.fijar_intensidad("normal")
	var r_normal := en.carga_riesgo()
	_comprobar(en.fijar_intensidad("alta") == "" and en.carga_riesgo() >= r_normal, "entrenar más fuerte no baja el riesgo de lesión (418)")
	_comprobar(en.fijar_intensidad("inexistente") != "", "y una intensidad inexistente se rechaza")
	var estrella: Jugador = c.plantilla[2]
	var ai := en.asignar_individual(estrella, "regate")
	_comprobar(ai == "", "se puede asignar entrenamiento individual (419): %s" % ai.left(50))
	var caja := c.saldo
	_comprobar(en.elegir_pretemporada("dura", c, m.anio, 1) == "" and en.pretemporada == "dura", "se elige la pretemporada del año (426)")
	_comprobar(en.elegir_pretemporada("altura", c, m.anio, 1) != "", "y solo una por año (430)")
	var en2 := Entrenamiento.new(m.staff)
	_comprobar(en2.elegir_pretemporada("altura", c, m.anio, 1) == "", "el campamento de altura existe como pretemporada (430)")
	en.concentracion = true
	_comprobar(en.concentracion, "la concentración previa se puede activar (429)")
	## Dueño: capital propio y venta del club (662, 690).
	var r: Roles = m.roles
	_comprobar(r.inyectar_capital() != "", "el DT no puede meter capital propio (662)")
	r.rol = Roles.DUENO
	var s0 := c.saldo
	_comprobar(r.inyectar_capital() == "" and c.saldo > s0, "el dueño inyecta capital (662)")
	_comprobar(r.inyectar_capital() == "" and r.inyectar_capital() != "", "pero como máximo dos veces por temporada (662)")
	_comprobar(r.vender_club() == "" and r.sin_club, "y puede vender el club y retirarse (690)")
	## Prensa propia (774-793).
	var pr := m.prensa
	pr.funa = 70
	_comprobar(pr.comunicado("silencio") != "" and pr.funa == 70, "el silencio de prensa no gasta nada y la funa sigue (778)")
	var f0 := pr.funa
	pr.comunicado("apoyo")
	_comprobar(pr.funa < f0, "un comunicado de apoyo baja la funa (786)")
	var vistos := {}
	for i in 40:
		pr.funa = 70
		pr.comunicado("contestar")
		vistos[pr.funa < 70] = true
	_comprobar(vistos.size() == 2, "contestar es cara o cruz: unas veces apaga el fuego y otras lo agranda (786)")
	for medio: String in ["podcast", "stream"]:
		_comprobar(not pr.tiene_medio(medio) and pr.comprar_medio(medio, c) == "" and pr.tiene_medio(medio), "se compra el medio propio «%s» (792, 793)" % medio)
		_comprobar(pr.comprar_medio(medio, c) != "", "y no se compra dos veces")
	_comprobar(pr.renta_medios(c) > 0, "los medios propios rentan cada mes (793): %s" % _dinero(pr.renta_medios(c)))
	## Informe de gestión (1035).
	var inf := m.informe_de_gestion()
	_comprobar(inf is Array, "el informe de gestión es una lista de tareas")
	c.mover_saldo(-c.saldo - 5000000)
	var inf2 := m.informe_de_gestion()
	var grave := false
	for t: Dictionary in inf2:
		if bool(t.get("grave", false)):
			grave = true
	_comprobar(grave, "con la caja en rojo el informe avisa de algo grave (1035)")
