extends BaseIdea
## FASE 0 · EL RELOJ ÚNICO (`nucleo/reloj.gd`): avanzar minutos, horas y días, las señales de
## hora/día/semana, el tope del domingo, la fecha y el guardado. Sin mundo: el reloj suelto.

var _horas: Array = []
var _dias: Array = []
var _semanas: Array = []
var _agotadas: Array = []
var _minutos: Array = [0]

var _r
var _pasados

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
	_r = Reloj.new()
	_escuchar(_r)
	_probar_01()
	_probar_02()
	_probar_03()
	_probar_04()
	_probar_05()
	_probar_06()
	_probar_07()
	_probar_08()
	_probar_09()
	_probar_10()

func _probar_01() -> void:
	## La primera sincronización es silenciosa: el reloj aún no vivía en ninguna semana.
	_comprobar(_r.sincronizar(2026, 1), "la primera sincronización coloca el reloj")
	_comprobar(_horas.is_empty() and _dias.is_empty() and _semanas.is_empty(),
		"la primera sincronización no emite señales (no pasó tiempo)")
	_comprobar(_r.dia == 0 and _r.texto_hora() == "08:00", "arranca el lunes a las 08:00 (%s, día %d)" % [_r.texto_hora(), _r.dia])
	_comprobar(not _r.sincronizar(2026, 1), "sincronizar con la misma semana no hace nada")

func _probar_02() -> void:
	## Horas: tres horas, tres señales de hora en punto y 180 minutos _pasados.
	_comprobar(_r.avanzar_horas(3, "trabajo") == 180, "avanzar 3 horas devuelve 180 minutos")
	_comprobar(_r.texto_hora() == "11:00", "tras 3 horas son las 11:00 (%s)" % _r.texto_hora())
	_comprobar(_horas == [[9, 0], [10, 0], [11, 0]], "una señal por cada hora en punto: %s" % str(_horas))
	_comprobar(_minutos[0] == 180, "tiempo_pasado suma los 180 minutos (%d)" % _minutos[0])
	_limpiar()
	_r.avanzar_minutos(30)
	_comprobar(_r.texto_hora() == "11:30" and _horas.is_empty(), "media hora no da hora en punto (%s)" % _r.texto_hora())
	_comprobar(absf(_r.hora_decimal() - 11.5) < 0.0001, "hora decimal 11.5 para la luz del 3D")

func _probar_03() -> void:
	## Días: esperar hasta las 08:00 cruza la medianoche una vez.
	_limpiar()
	var esperado := (24 * 60 - 690) + 8 * 60
	_comprobar(_r.esperar_hasta(8) == esperado, "esperar hasta las 08:00 son %d minutos" % esperado)
	_comprobar(_r.dia == 1 and _r.texto_hora() == "08:00", "es martes a las 08:00 (día %d, %s)" % [_r.dia, _r.texto_hora()])
	_comprobar(_dias == [[1, 1, 2026]], "una sola señal de día nuevo: %s" % str(_dias))
	_comprobar(_horas.size() == 21 and _horas[12] == [0, 1], "21 horas en punto, la medianoche con el día nuevo (%d)" % _horas.size())
	_comprobar(_r.esperar_hasta(8) == 1440 and _r.dia == 2, "esperar a la hora que ya es espera un día entero")

func _probar_04() -> void:
	## Adelantar días con rutina.
	_comprobar(_r.avanzar_dias(1) == 1440 and _r.dia == 3 and _r.texto_hora() == "08:00", "avanzar un día deja el jueves a la misma hora")

func _probar_05() -> void:
	## La jornada, la noche y el fin de semana.
	_r.esperar_hasta(10)
	_comprobar(_r.es_jornada_laboral() and not _r.es_de_noche(), "jueves 10:00: jornada laboral, de día")
	_r.esperar_hasta(22)
	_comprobar(not _r.es_jornada_laboral() and _r.es_de_noche(), "jueves 22:00: fuera de jornada, de noche")
	_r.esperar_hasta(10)
	_r.esperar_hasta(10)
	_comprobar(_r.dia == 5 and _r.es_fin_de_semana() and not _r.es_jornada_laboral(), "el sábado a las 10:00 no hay jornada")

func _probar_06() -> void:
	## EL TOPE: el reloj nunca pasa del domingo 23:59 por su cuenta.
	_limpiar()
	var antes = _r.minuto_de_semana()
	_pasados = _r.avanzar_dias(10)
	_comprobar(_pasados == Reloj.TOPE_SEMANA - antes, "adelantar 10 días solo llega al tope (%d min)" % _pasados)
	_comprobar(_r.dia == 6 and _r.texto_hora() == "23:59" and _r.agotada(), "se queda el domingo a las 23:59")
	_comprobar(_agotadas.size() == 1, "avisa una vez de que la semana se agotó (%d)" % _agotadas.size())
	_comprobar(_r.avanzar_horas(5) == 0 and _agotadas.size() == 1, "ya no avanza más y no repite el aviso")
	_comprobar(_r.minutos_hasta_fin_de_semana() == 0, "no quedan minutos de semana")

func _probar_07() -> void:
	## La semana la manda el mundo: al sincronizar, salta al lunes 08:00 y dice cuánto se saltó.
	_limpiar()
	_comprobar(_r.sincronizar(2026, 2), "la semana 2 llega")
	_comprobar(_semanas == [[2, 2026, 481]], "del domingo 23:59 al lunes 08:00 se saltan 481 minutos: %s" % str(_semanas))
	_comprobar(_dias == [[0, 2, 2026]] and _horas == [[8, 0]], "y avisa del lunes y de las 08:00")
	_comprobar(_r.dia == 0 and _r.texto_hora() == "08:00" and not _r.agotada(), "lunes 08:00 de la semana nueva")
	_limpiar()
	_r.sincronizar(2026, 3)
	_comprobar(_semanas == [[3, 2026, 10080]], "una semana avanzada sin vivirla son 10.080 minutos: %s" % str(_semanas))

func _probar_08() -> void:
	## La fecha cuadra con la tira de días de la pantalla principal (`Calendario.fecha`).
	var f = _r.fecha()
	var cal := Calendario.fecha(2026, 3, 0)
	_comprobar(int(f["year"]) == int(cal["year"]) and int(f["month"]) == int(cal["month"])
		and int(f["day"]) == int(cal["day"]) and int(f["hour"]) == 8 and int(f["minute"]) == 0,
		"la fecha del reloj es la del calendario a las 08:00 (%s)" % str(f))
	_comprobar(int(f["weekday"]) == 1, "y es lunes")

func _probar_09() -> void:
	## Guardar y cargar.
	_r.avanzar_minutos(2 * 1440 + 7 * 60 + 13)
	var d = _r.a_dic()
	var r2 := Reloj.new()
	_escuchar(r2)
	_limpiar()
	r2.desde_dic(JSON.parse_string(JSON.stringify(d)))
	_comprobar(r2.anio == _r.anio and r2.semana == _r.semana and r2.dia == _r.dia and r2.minuto == _r.minuto,
		"guardar y cargar conserva el día y la hora (%s %s)" % [str(d), r2.texto_hora()])
	_comprobar(_horas.is_empty() and _semanas.is_empty(), "cargar es silencioso")
	var r3 := Reloj.new()
	r3.desde_dic({})
	r3.sincronizar(2026, 9)
	_comprobar(r3.dia == 0 and r3.texto_hora() == "08:00", "un guardado sin reloj arranca el lunes a las 08:00")
	var r4 := Reloj.new()
	r4.desde_dic({"anio": 2026, "sem": 1, "dia": 9, "min": 99999})
	_comprobar(r4.dia == 6 and r4.minuto == 1439, "un guardado roto se recorta al tope de la semana")

func _probar_10() -> void:
	## Determinismo: dos relojes con los mismos pasos acaban igual, y trocear el tiempo no cambia nada.
	var x := Reloj.new()
	var y := Reloj.new()
	x.sincronizar(2027, 5)
	y.sincronizar(2027, 5)
	x.avanzar_minutos(2000)
	for i in 2000:
		y.avanzar_minutos(1)
	_comprobar(x.a_dic() == y.a_dic(), "2000 minutos de una vez = 2000 veces un minuto")
