extends BaseIdea
## s6r · LOS RETOS DE LA SEMANA (semana 6 del plan, tipo Manager Live, 27-10-2026; `RetosSemana`). Al tomar
## el mando salen tres retos para el próximo partido; se juzgan con el marcador (dirigido o simulado), pagan a
## la caja un porcentaje de la masa salarial, se cuentan y se guardan; salen otros para la semana siguiente; y
## no tocan el azar de la partida (el estado del generador `Azar` no se mueve).

func _probar() -> void:
	_titulo("S6R: los retos de la semana")
	var m := _mundo(4242)
	var r := m.retos_semana
	_comprobar(r.activos.size() == 3, "al tomar el mando hay tres retos (%d)" % r.activos.size())
	var ids: Array = r.activos.map(func(a: Dictionary) -> String: return String(a["id"]))
	var distintos := {}
	for i: String in ids:
		distintos[i] = true
	_comprobar(distintos.size() == 3, "los tres son distintos (%s)" % str(ids))
	var m2 := _mundo(4242)
	_comprobar(m2.retos_semana.activos.map(func(a: Dictionary) -> String: return String(a["id"])) == ids, "la misma partida da los mismos retos")
	var masa := m.mi_club().masa_salarial()
	var suma := 0
	for a: Dictionary in r.activos:
		suma += int(a["premio"])
	_comprobar(suma > 0 and suma < masa, "el premio es una parte de la masa salarial semanal (%d de %d)" % [suma, masa])
	## Juzgar: un 3-0 cumple ganar, ganar por dos, portería a cero, marcar...; un 0-2, casi nada.
	_comprobar(RetosSemana.cumple("ganar_2", 3, 0) and RetosSemana.cumple("cero", 3, 0) and not RetosSemana.cumple("ganar", 0, 2) and RetosSemana.cumple("encajar_1", 1, 1),
		"cada reto se juzga con el marcador")
	var antes := m.mi_club().saldo
	var ok := r.evaluar(m, 3, 0)
	_comprobar(ok >= 1 and m.mi_club().saldo > antes and r.cumplidos_total == ok, "con un 3-0 se cumplen %d y la caja cobra (%d €)" % [ok, m.mi_club().saldo - antes])
	_comprobar(r.activos.is_empty() and r.ultimo.size() == 3, "tras juzgarlos se vacían y queda el resumen")
	## Una semana de verdad: avanzar genera los de la siguiente y juzga los de esta.
	r.generar(m)
	var d := r.a_dic()
	var r2 := RetosSemana.new()
	r2.desde_dic(d)
	_comprobar(r2.activos.size() == 3 and r2.cumplidos_total == r.cumplidos_total, "se guardan y se cargan")
	m.avanzar_semana()
	_comprobar(r.activos.size() == 3, "tras la semana hay retos para el próximo partido (%d)" % r.activos.size())
	_comprobar(r.cumplidos_total >= ok, "y el recuento sigue (%d cumplidos)" % r.cumplidos_total)
	## No tocan el azar: generar y juzgar los retos no mueve el estado del generador de la partida (`Azar`).
	r.activos = []
	var st: int = Azar._rng.state
	r.generar(m)
	r.evaluar(m, 2, 1)
	r.generar(m)
	_comprobar(Azar._rng.state == st, "no tocan el azar de la partida (el estado de Azar sigue igual)")
