extends BaseIdea
## FASE 0 · EL RELOJ ÚNICO (`nucleo/reloj.gd`): avanzar minutos, horas y días, las señales de
## hora/día/semana, el tope del domingo, la fecha y el guardado. Sin mundo: el reloj suelto.

var _horas: Array = []
var _dias: Array = []
var _semanas: Array = []
var _agotadas: Array = []
var _minutos: Array = [0]

func _escuchar(r: Reloj) -> void:
	r.hora_cambiada.connect(func(h: int, d: int) -> void: _horas.append([h, d]))
	r.dia_cambiado.connect(func(d: int, s: int, a: int) -> void: _dias.append([d, s, a]))
	r.semana_cambiada.connect(func(s: int, a: int, m: int) -> void: _semanas.append([s, a, m]))
	r.semana_agotada.connect(func() -> void: _agotadas.append(true))
	r.tiempo_pasado.connect(func(m: int, _act: String) -> void: _minutos[0] += m)

func _limpiar() -> void:
	_horas.clear()
	_dias.clear()
	_semanas.clear()
	_agotadas.clear()
	_minutos[0] = 0

func _probar() -> void:
	_titulo("FASE 0: EL RELOJ ÚNICO")
	var r := Reloj.new()
	_escuchar(r)

	## La primera sincronización es silenciosa: el reloj aún no vivía en ninguna semana.
	_comprobar(r.sincronizar(2026, 1), "la primera sincronización coloca el reloj")
	_comprobar(_horas.is_empty() and _dias.is_empty() and _semanas.is_empty(),
		"la primera sincronización no emite señales (no pasó tiempo)")
	_comprobar(r.dia == 0 and r.texto_hora() == "08:00", "arranca el lunes a las 08:00 (%s, día %d)" % [r.texto_hora(), r.dia])
	_comprobar(not r.sincronizar(2026, 1), "sincronizar con la misma semana no hace nada")

	## Horas: tres horas, tres señales de hora en punto y 180 minutos pasados.
	_comprobar(r.avanzar_horas(3, "trabajo") == 180, "avanzar 3 horas devuelve 180 minutos")
	_comprobar(r.texto_hora() == "11:00", "tras 3 horas son las 11:00 (%s)" % r.texto_hora())
	_comprobar(_horas == [[9, 0], [10, 0], [11, 0]], "una señal por cada hora en punto: %s" % str(_horas))
	_comprobar(_minutos[0] == 180, "tiempo_pasado suma los 180 minutos (%d)" % _minutos[0])
	_limpiar()
	r.avanzar_minutos(30)
	_comprobar(r.texto_hora() == "11:30" and _horas.is_empty(), "media hora no da hora en punto (%s)" % r.texto_hora())
	_comprobar(absf(r.hora_decimal() - 11.5) < 0.0001, "hora decimal 11.5 para la luz del 3D")

	## Días: esperar hasta las 08:00 cruza la medianoche una vez.
	_limpiar()
	var esperado := (24 * 60 - 690) + 8 * 60
	_comprobar(r.esperar_hasta(8) == esperado, "esperar hasta las 08:00 son %d minutos" % esperado)
	_comprobar(r.dia == 1 and r.texto_hora() == "08:00", "es martes a las 08:00 (día %d, %s)" % [r.dia, r.texto_hora()])
	_comprobar(_dias == [[1, 1, 2026]], "una sola señal de día nuevo: %s" % str(_dias))
	_comprobar(_horas.size() == 21 and _horas[12] == [0, 1], "21 horas en punto, la medianoche con el día nuevo (%d)" % _horas.size())
	_comprobar(r.esperar_hasta(8) == 1440 and r.dia == 2, "esperar a la hora que ya es espera un día entero")

	## Adelantar días con rutina.
	_comprobar(r.avanzar_dias(1) == 1440 and r.dia == 3 and r.texto_hora() == "08:00", "avanzar un día deja el jueves a la misma hora")

	## La jornada, la noche y el fin de semana.
	r.esperar_hasta(10)
	_comprobar(r.es_jornada_laboral() and not r.es_de_noche(), "jueves 10:00: jornada laboral, de día")
	r.esperar_hasta(22)
	_comprobar(not r.es_jornada_laboral() and r.es_de_noche(), "jueves 22:00: fuera de jornada, de noche")
	r.esperar_hasta(10)
	r.esperar_hasta(10)
	_comprobar(r.dia == 5 and r.es_fin_de_semana() and not r.es_jornada_laboral(), "el sábado a las 10:00 no hay jornada")

	## EL TOPE: el reloj nunca pasa del domingo 23:59 por su cuenta.
	_limpiar()
	var antes := r.minuto_de_semana()
	var pasados := r.avanzar_dias(10)
	_comprobar(pasados == Reloj.TOPE_SEMANA - antes, "adelantar 10 días solo llega al tope (%d min)" % pasados)
	_comprobar(r.dia == 6 and r.texto_hora() == "23:59" and r.agotada(), "se queda el domingo a las 23:59")
	_comprobar(_agotadas.size() == 1, "avisa una vez de que la semana se agotó (%d)" % _agotadas.size())
	_comprobar(r.avanzar_horas(5) == 0 and _agotadas.size() == 1, "ya no avanza más y no repite el aviso")
	_comprobar(r.minutos_hasta_fin_de_semana() == 0, "no quedan minutos de semana")

	## La semana la manda el mundo: al sincronizar, salta al lunes 08:00 y dice cuánto se saltó.
	_limpiar()
	_comprobar(r.sincronizar(2026, 2), "la semana 2 llega")
	_comprobar(_semanas == [[2, 2026, 481]], "del domingo 23:59 al lunes 08:00 se saltan 481 minutos: %s" % str(_semanas))
	_comprobar(_dias == [[0, 2, 2026]] and _horas == [[8, 0]], "y avisa del lunes y de las 08:00")
	_comprobar(r.dia == 0 and r.texto_hora() == "08:00" and not r.agotada(), "lunes 08:00 de la semana nueva")
	_limpiar()
	r.sincronizar(2026, 3)
	_comprobar(_semanas == [[3, 2026, 10080]], "una semana avanzada sin vivirla son 10.080 minutos: %s" % str(_semanas))

	## La fecha cuadra con la tira de días de la pantalla principal (`Calendario.fecha`).
	var f := r.fecha()
	var cal := Calendario.fecha(2026, 3, 0)
	_comprobar(int(f["year"]) == int(cal["year"]) and int(f["month"]) == int(cal["month"])
		and int(f["day"]) == int(cal["day"]) and int(f["hour"]) == 8 and int(f["minute"]) == 0,
		"la fecha del reloj es la del calendario a las 08:00 (%s)" % str(f))
	_comprobar(int(f["weekday"]) == 1, "y es lunes")

	## Guardar y cargar.
	r.avanzar_minutos(2 * 1440 + 7 * 60 + 13)
	var d := r.a_dic()
	var r2 := Reloj.new()
	_escuchar(r2)
	_limpiar()
	r2.desde_dic(JSON.parse_string(JSON.stringify(d)))
	_comprobar(r2.anio == r.anio and r2.semana == r.semana and r2.dia == r.dia and r2.minuto == r.minuto,
		"guardar y cargar conserva el día y la hora (%s %s)" % [str(d), r2.texto_hora()])
	_comprobar(_horas.is_empty() and _semanas.is_empty(), "cargar es silencioso")
	var r3 := Reloj.new()
	r3.desde_dic({})
	r3.sincronizar(2026, 9)
	_comprobar(r3.dia == 0 and r3.texto_hora() == "08:00", "un guardado sin reloj arranca el lunes a las 08:00")
	var r4 := Reloj.new()
	r4.desde_dic({"anio": 2026, "sem": 1, "dia": 9, "min": 99999})
	_comprobar(r4.dia == 6 and r4.minuto == 1439, "un guardado roto se recorta al tope de la semana")

	## Determinismo: dos relojes con los mismos pasos acaban igual, y trocear el tiempo no cambia nada.
	var x := Reloj.new()
	var y := Reloj.new()
	x.sincronizar(2027, 5)
	y.sincronizar(2027, 5)
	x.avanzar_minutos(2000)
	for i in 2000:
		y.avanzar_minutos(1)
	_comprobar(x.a_dic() == y.a_dic(), "2000 minutos de una vez = 2000 veces un minuto")
