extends BaseSO
## FUNCIONES · fechas del calendario: la Pascua (algoritmo gregoriano) acierta años conocidos, `unix_de` avanza de día en día y de semana en
## semana, el día 0 de la semana es lunes, el ramadán da fechas válidas y la hora es la misma en todos los sistemas (UTC, sin zona local).
func _nombre() -> String:
	return "fun_calendario_fechas"

func _probar() -> void:
	_titulo("FUNCIONES · fechas [%s]" % sistema())
	var conocidas := {2000: [4, 23], 2008: [3, 23], 2019: [4, 21], 2024: [3, 31], 2025: [4, 20], 2026: [4, 5], 2027: [3, 28], 2030: [4, 21], 2038: [4, 25]}
	for anio: int in conocidas:
		var p := Calendario.pascua(anio)
		_comprobar(p == conocidas[anio], "Pascua %d = %s (esperado %s)" % [anio, str(p), str(conocidas[anio])])
	var malas := 0
	for anio in range(1990, 2100):
		var p := Calendario.pascua(anio)
		var dentro := (int(p[0]) == 3 and int(p[1]) >= 22) or (int(p[0]) == 4 and int(p[1]) <= 25)
		malas += int(not dentro)
	_comprobar(malas == 0, "la Pascua de 1990-2099 cae siempre entre el 22 de marzo y el 25 de abril")
	var u0 := Calendario.unix_de(2026, 1, 0)
	_comprobar(Calendario.unix_de(2026, 1, 1) - u0 == 86400, "un día después = +86400 s")
	_comprobar(Calendario.unix_de(2026, 2, 0) - u0 == 7 * 86400, "una semana después = +7 días")
	_comprobar(Calendario.unix_de(2026, 0, 0) == u0, "la semana 0 se trata como la 1")
	var dow := int(Calendario.fecha(2026, 1, 0).get("weekday", -1))
	_comprobar(dow == 1, "el día 0 de la semana 1 es lunes (weekday=%d)" % dow)
	var cada_lunes := true
	for sem in range(1, 40):
		cada_lunes = cada_lunes and int(Calendario.fecha(2026, sem, 0).get("weekday", -1)) == 1
	_comprobar(cada_lunes, "día 0 es lunes en las 39 primeras semanas")
	var fecha := Calendario.fecha(2028, 20, 3)
	_comprobar(int(fecha["year"]) >= 2028 and int(fecha["month"]) >= 1 and int(fecha["day"]) >= 1, "fecha(2028, 20, 3) válida: %s" % str(fecha))
	## Independiente de la zona horaria del equipo: el unix de mediodía UTC del 1-ene-2026 es fijo.
	var ref := int(Time.get_unix_time_from_datetime_dict({"year": 2026, "month": 1, "day": 1, "hour": 12, "minute": 0, "second": 0}))
	_comprobar(ref == 1767268800, "12:00 UTC del 1-ene-2026 = 1767268800 en %s" % sistema())
	var r := Calendario.ramadan(2026)
	var ok := not r.is_empty()
	for fila: Array in r:
		ok = ok and int(fila[0]) >= 1 and int(fila[0]) <= 12 and int(fila[1]) >= 1 and int(fila[1]) <= 31 and String(fila[2]) != ""
	_comprobar(ok, "ramadán 2026: %s" % str(r))
