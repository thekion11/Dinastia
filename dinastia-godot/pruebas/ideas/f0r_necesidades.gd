extends BaseIdea
## FASE 0 · LAS NECESIDADES DEL DT (`nucleo/necesidades.gd`) movidas por el reloj: suben y bajan
## según lo que se hace, topes, efectos, umbrales y guardado. Y el enganche al MUNDO: la semana de
## siempre da exactamente lo mismo uses o no el reloj, y guardar/cargar conserva los dos.

var _estados: Array = []
var _agotamientos: Array = []

func _par() -> Array:
	var r := Reloj.new()
	var n := Necesidades.new()
	n.seguir_a(r)
	r.sincronizar(2026, 1)
	n.estado_cambiado.connect(func(que: String, nivel: int) -> void: _estados.append([que, nivel]))
	n.agotamiento.connect(func() -> void: _agotamientos.append(true))
	return [r, n]

func _probar() -> void:
	_titulo("FASE 0: LAS NECESIDADES")
	_rutina()
	_sube_y_baja()
	_topes_y_efectos()
	_guardado()
	_titulo("FASE 0: RELOJ Y NECESIDADES EN EL MUNDO")
	_en_el_mundo()

## Un día de rutina (dormir, comer, trabajar) deja al DT como estaba: adelantar días no castiga.
func _rutina() -> void:
	var p := _par()
	var r: Reloj = p[0]
	var n: Necesidades = p[1]
	_comprobar(n.energia() == 95 and n.hambre() == 2, "arranca descansado y desayunado (%d/%d)" % [n.energia(), n.hambre()])
	var peor_hambre := [0]
	var peor_energia := [100]
	r.hora_cambiada.connect(func(_h: int, _d: int) -> void:
		peor_hambre[0] = maxi(peor_hambre[0], n.hambre())
		peor_energia[0] = mini(peor_energia[0], n.energia()))
	var e0 := n.energia_m
	r.avanzar_dias(3)
	_comprobar(absi(n.energia_m - e0) <= 3000, "tras 3 días de rutina la energía sigue igual (%d → %d)" % [e0 / 1000, n.energia()])
	_comprobar(peor_hambre[0] < Necesidades.HAMBRE_UMBRALES[0], "con tres comidas el hambre nunca llega a aviso (máx %d)" % peor_hambre[0])
	_comprobar(peor_energia[0] > Necesidades.ENERGIA_UMBRALES[0], "durmiendo 8 h la energía nunca llega a aviso (mín %d)" % peor_energia[0])
	_comprobar(_estados.is_empty() and n.factor_riesgo() == 1.0, "la rutina no dispara avisos ni riesgo")

func _sube_y_baja() -> void:
	_estados.clear()
	var p := _par()
	var r: Reloj = p[0]
	var n: Necesidades = p[1]
	## Trabajar sin parar: baja la energía y sube el hambre.
	var e0 := n.energia()
	r.avanzar_horas(10, "trabajo")
	_comprobar(n.energia() == e0 - 45, "10 h de trabajo cuestan 45 de energía (%d → %d)" % [e0, n.energia()])
	_comprobar(n.hambre() > 55, "y dan hambre (%d)" % n.hambre())
	r.avanzar_horas(1, "horas_extra")
	_comprobar(_estados.has(["hambre", 1]), "al cruzar 60 de hambre avisa: hambriento (%s)" % str(_estados))
	## Comer media hora deja el hambre a cero.
	r.avanzar_minutos(30, "comer")
	_comprobar(n.hambre() == 0 and _estados.back() == ["hambre", 0], "media hora comiendo: hambre 0 y vuelve a bien")
	## Seguir despierto hasta caer.
	r.avanzar_horas(10, "horas_extra")
	_comprobar(n.nivel_energia() >= 1 and _estados.has(["energia", 1]), "las horas extra dejan al DT cansado (%d)" % n.energia())
	## Dormir 8 h recupera ~61 puntos.
	var antes := n.energia_m
	r.avanzar_horas(8, "dormir")
	_comprobar(n.energia_m - antes == 127 * 480, "8 h de sueño suben %d de energía" % ((n.energia_m - antes) / 1000))
	_comprobar(_estados.back() == ["energia", 0], "y deja de estar cansado")
	## Picar algo sin gastar tiempo.
	r.avanzar_horas(6)
	var h := n.hambre()
	var minuto := r.minuto_de_semana()
	n.picar(10)
	_comprobar(n.hambre() == maxi(h - 10, 0) and r.minuto_de_semana() == minuto, "picar quita 10 de hambre sin pasar el tiempo")
	n.pasar(30, "actividad_inventada")
	_comprobar(n.hambre() >= 0, "una actividad desconocida cuenta como libre sin romper nada")

func _topes_y_efectos() -> void:
	_estados.clear()
	_agotamientos.clear()
	var n := Necesidades.new()
	n.estado_cambiado.connect(func(que: String, nivel: int) -> void: _estados.append([que, nivel]))
	n.agotamiento.connect(func() -> void: _agotamientos.append(true))
	n.pasar(48 * 60, "dormir")
	_comprobar(n.energia_m == Necesidades.MAXIMO, "dormir 48 h no pasa de 100 de energía")
	_comprobar(n.nivel_hambre() == 2 and n.factor_riesgo() > 1.0, "pero se despierta famélico y con más riesgo (%.2f)" % n.factor_riesgo())
	n.pasar(30, "comer")
	_comprobar(n.factor_riesgo() == 1.0 and n.factor_rendimiento() == 1.0, "descansado y comido: riesgo ×1 y rendimiento ×1")
	n.pasar(60 * 60, "libre")
	_comprobar(n.energia_m == 0 and n.hambre_m == Necesidades.MAXIMO, "60 h despierto y sin comer: energía 0 y hambre 100 (topes)")
	_comprobar(_agotamientos.size() == 1, "con la energía a 0 avisa de agotamiento (una vez)")
	n.pasar(60, "libre")
	_comprobar(_agotamientos.size() == 1, "no repite el agotamiento en el mismo episodio")
	_comprobar(_estados.has(["energia", 2]) and _estados.has(["hambre", 2]), "los dos llegan a grave: %s" % str(_estados))
	_comprobar(absf(n.factor_riesgo() - 1.8) < 0.0001, "en el fondo el riesgo es ×1.8 (%.3f)" % n.factor_riesgo())
	_comprobar(absf(n.factor_rendimiento() - 0.75) < 0.0001, "y el rendimiento 0.75 (%.3f)" % n.factor_rendimiento())
	_comprobar(absf(n.probabilidad_de_fallo(0.1) - 0.18) < 0.0001 and n.probabilidad_de_fallo(0.9) == 1.0,
		"una probabilidad de fallo de 10%% pasa a 18%%, y nunca supera el 100%%")
	n.pasar(10 * 60, "dormir")
	n.pasar(30, "comer")
	_comprobar(n.factor_riesgo() < 1.8 and n.factor_rendimiento() > 0.75, "dormir y comer bajan el riesgo (%.2f)" % n.factor_riesgo())
	_comprobar(_agotamientos.size() == 1, "recuperarse no emite agotamiento")
	n.pasar(100 * 60, "libre")
	_comprobar(_agotamientos.size() == 2, "recuperado, un segundo desfallecimiento vuelve a avisar")

func _guardado() -> void:
	var p := _par()
	var r: Reloj = p[0]
	var n: Necesidades = p[1]
	r.avanzar_horas(13, "trabajo")
	var d: Dictionary = JSON.parse_string(JSON.stringify(n.a_dic()))
	var n2 := Necesidades.new()
	var emitidos := [0]
	n2.estado_cambiado.connect(func(_q: String, _n: int) -> void: emitidos[0] += 1)
	n2.desde_dic(d)
	_comprobar(n2.energia_m == n.energia_m and n2.hambre_m == n.hambre_m, "guardar y cargar conserva energía y hambre exactas")
	_comprobar(n2.nivel_hambre() == n.nivel_hambre() and emitidos[0] == 0, "cargar recalcula los niveles sin emitir avisos")
	var n3 := Necesidades.new()
	n3.desde_dic({})
	_comprobar(n3.energia_m == Necesidades.ENERGIA_RUTINA and n3.hambre_m == Necesidades.HAMBRE_RUTINA, "un guardado sin necesidades arranca con la rutina")
	n3.desde_dic({"en": -500, "ha": 9999999})
	_comprobar(n3.energia_m == 0 and n3.hambre_m == Necesidades.MAXIMO, "un guardado roto se recorta a los topes")

## Lo que importa de la fase 0: el mundo no cambia por tener reloj.
func _sin_reloj(i: Dictionary) -> String:
	var copia := i.duplicate(true)
	copia.erase("guardado")
	copia.erase("reloj")
	copia.erase("necesidades")
	return JSON.stringify(copia, "", true).sha256_text()

func _en_el_mundo() -> void:
	## Dos mundos con la misma semilla en el MISMO proceso no salen iguales (hay estado estático
	## del núcleo, p. ej. `LeyesPais.tick`, que sobrevive entre mundos), así que aquí se comprueba lo
	## que sí se puede: vivir el reloj no toca ni el mundo ni `Azar`. Que el avance de semana dé lo
	## mismo con el enganche lo dice la prueba diferencial (`pruebas/huella_mundo.tscn`).
	var b := _mundo(4242)
	_comprobar(b.reloj.texto_hora() == "08:00" and b.reloj.semana == b.semana and b.reloj.anio == b.anio,
		"el reloj del mundo nace en su semana, el lunes a las 08:00")
	var semana0 := b.semana
	var semanas := []
	b.reloj.semana_cambiada.connect(func(s: int, _a: int, m: int) -> void: semanas.append([s, m]))
	var intactos := true
	for i in 3:
		var antes := _sin_reloj(Partida.instantanea(b))
		var estado_azar: int = Azar._rng.state
		b.reloj.avanzar_dias(2)
		b.reloj.avanzar_horas(14, "horas_extra")
		b.necesidades.picar(5)
		intactos = intactos and antes == _sin_reloj(Partida.instantanea(b)) and estado_azar == Azar._rng.state
		b.avanzar_semana()
	_comprobar(intactos, "vivir días y horas no cambia NADA del mundo ni consume Azar (determinismo)")
	_comprobar(semanas.size() == 3 and int(semanas[0][0]) == semana0 + 1, "cada avanzar_semana mueve el reloj a la semana nueva: %s" % str(semanas))
	_comprobar(b.reloj.semana == b.semana and b.reloj.dia == 0 and b.reloj.texto_hora() == "08:00", "tras avanzar la semana es lunes 08:00")
	_comprobar(b.necesidades.energia_m == Necesidades.ENERGIA_RUTINA, "la semana saltada se da por vivida con rutina")

	## Viviendo hasta el tope del domingo, el salto al lunes es la noche: se duerme.
	b.reloj.avanzar_dias(7)
	var e_domingo := b.necesidades.energia_m
	b.avanzar_semana()
	_comprobar(int(semanas.back()[1]) == 481 and b.necesidades.energia_m > e_domingo, "del domingo 23:59 al lunes se duermen 481 minutos")

	## Guardar a media semana y cargar.
	b.reloj.avanzar_horas(30, "trabajo")
	var guardado := Partida.instantanea(b)
	var c := Partida.desde_instantanea(JSON.parse_string(JSON.stringify(guardado)))
	_comprobar(c != null and c.reloj.dia == b.reloj.dia and c.reloj.minuto == b.reloj.minuto and c.reloj.semana == b.semana,
		"cargar devuelve el mismo día y hora (%s)" % (c.reloj.texto_hora() if c != null else "-"))
	_comprobar(c != null and c.necesidades.energia_m == b.necesidades.energia_m and c.necesidades.hambre_m == b.necesidades.hambre_m,
		"y las mismas necesidades")
	if c != null:
		c.avanzar_semana()
		_comprobar(c.reloj.semana == c.semana and c.reloj.texto_hora() == "08:00", "el mundo cargado sigue moviendo su reloj")

	## Un guardado anterior a la fase 0 (sin las claves) carga en el lunes 08:00 con rutina.
	guardado.erase("reloj")
	guardado.erase("necesidades")
	var viejo := Partida.desde_instantanea(JSON.parse_string(JSON.stringify(guardado)))
	_comprobar(viejo != null and viejo.reloj.texto_hora() == "08:00" and viejo.reloj.semana == viejo.semana
		and viejo.necesidades.energia_m == Necesidades.ENERGIA_RUTINA, "un guardado viejo carga en el lunes 08:00 con rutina")

	## `nueva_temporada()` pone `semana = 1` sin señal: el reloj se pone al día al leerlo.
	semanas.clear()
	b.anio += 1
	b.semana = 1
	_comprobar(b.reloj.texto_hora() == "08:00" and b.reloj.semana == 1 and b.reloj.anio == b.anio and semanas.size() == 1,
		"al leer el reloj tras una temporada nueva salta a la semana 1 y lo avisa")
