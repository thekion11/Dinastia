extends BaseIdea
## MEGA AUDITORÍA 4 (4-11-2026), repaso 5 CRUZADO: MUSEO, TROFEOS, ACADEMIA y OJEADORES al límite.
##   1. Museo: 0 y 500 trofeos (hitos ordenados por año, ficha de cualquier vitrina incluida −1 y 10⁶, planta 3 con contextos vacíos/absurdos), ida y vuelta por el guardado sin perder ni duplicar trofeos.
##   2. Academia: camada de 0 y de 200 chicos (semana y fin de temporada), captar sin caja y con índices absurdos, cambiar con ids/campos/valores inválidos, entregar fuera de edad, 20 temporadas.
##   3. Ojeadores: sin dinero (análisis, academias internacionales), presupuesto 0/negativo, niveles extremos.

func _probar() -> void:
	_titulo("A4 CRUZADO (gestión): museo, trofeos, academia y ojeadores al límite")
	_museo()
	await _academia()
	_ojeadores()

func _mundo_nuevo(semilla: int) -> Mundo:
	Partido.limpiar_contexto()
	var m := Mundo.new()
	var paises: Array[String] = ["CHI"]
	m.generar(paises, semilla)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	return m

func _museo() -> void:
	var m := _mundo_nuevo(12)
	m.roles.trofeos.clear()
	var base := MuseoVitrinas.hitos(m).size()
	for k in [-1, 0, 1000000]:
		var f := MuseoVitrinas.ficha(k, m)
		_comprobar(f.has("vacia") and f.has("titulo"), "ficha de la vitrina %d con %d hitos: tiene forma válida (vacía %s)" % [k, base, str(f["vacia"])])
	for i in 500:
		m.roles.trofeos.append({"anio": 2000 + (i * 7) % 60, "titulo": "Copa %d" % i, "final": "Final %d" % i, "goleadores": ["A (%d)" % i]})
	var h := MuseoVitrinas.hitos(m)
	var orden := true
	for i in range(1, h.size()):
		orden = orden and int(h[i - 1].get("anio", 0)) <= int(h[i].get("anio", 0))
	_comprobar(h.size() == base + 500 and orden, "500 trofeos: %d hitos ordenados por año (%s)" % [h.size(), "orden ok" if orden else "DESORDENADO"])
	var ultima := MuseoVitrinas.ficha(h.size() - 1, m)
	_comprobar(not bool(ultima["vacia"]) and bool(MuseoVitrinas.ficha(h.size(), m)["vacia"]), "la última vitrina tiene ficha y la siguiente está libre")
	for ctx in [{}, {"inst": {"museo": 99}}, {"inst": {"museo": -5}, "obras": {"museo": 3}}, {"hitos": [{"titulo": "x"}, {"anio": 5}]}, {"inst": {"museo": 2}, "obras": {"museo": 1}}]:
		var _a := MuseoAmpliado.existe(ctx)
		var _b := MuseoAmpliado.en_obra(ctx)
		var hs := MuseoAmpliado.hitos(ctx)
		_comprobar(hs is Array, "planta 3 con contexto %s: sin error (%d hitos)" % [str(ctx).left(50), hs.size()])
	## guardar y cargar
	var antes := (m.roles.trofeos as Array).size()
	var d := Partida.instantanea(m)
	var m2 := Partida.desde_instantanea(d)
	var despues := (m2.roles.trofeos as Array).size() if m2 != null else -1
	_comprobar(despues == antes, "guardar y cargar con %d trofeos: %d después" % [antes, despues])
	if m2 != null:
		_comprobar(MuseoVitrinas.hitos(m2).size() == h.size(), "los hitos del museo son los mismos tras cargar (%d)" % MuseoVitrinas.hitos(m2).size())
	SalasClub.vitrinas.clear()
	_comprobar(MuseoVitrinas.cercana(Vector3.ZERO).is_empty(), "sin vitrinas montadas no hay ninguna cercana")
	for i in 1000:
		SalasClub.vitrinas.append({"p": Vector3(float(i), 4, 0), "k": i})
	_comprobar(MuseoVitrinas.cercana(Vector3(500.2, 4, 0.1)).get("k", -1) == 500, "con 1000 vitrinas se reconoce la correcta")
	SalasClub.vitrinas.clear()

func _academia() -> void:
	var m := _mundo_nuevo(13)
	var ac: Academia = m.academia
	var yo := m.mi_club()
	yo.saldo = 0
	_comprobar(ac.captar(-1) != "" and ac.captar(99999) != "", "captar con índices −1 y 99 999: se rechaza")
	if not ac.candidatos.is_empty():
		var s0 := yo.saldo
		_comprobar(ac.captar(0) != "" and yo.saldo == s0, "captar sin caja: se rechaza y la caja no cambia")
	_comprobar(ac.cambiar("no_existe", "plan", "fisico") != "", "cambiar un chico inexistente: se rechaza")
	if not ac.chicos.is_empty():
		var id := String(ac.chicos[0]["id"])
		_comprobar(ac.cambiar(id, "campo_raro", "x") != "" and ac.cambiar(id, "plan", "plan_raro") != "" and ac.cambiar(id, "plan", "tactico") == "", "cambiar con campos/valores inválidos se rechaza; uno válido pasa")
		_comprobar(ac.entregar(id) != "" or ac.chicos.size() >= 0, "entregar a quien es muy chico no rompe")
		_comprobar(ac.entregar("zzz") != "", "entregar un id inexistente: se rechaza")
	## camada de 0
	ac.chicos.clear()
	ac.procesar_semana()
	_comprobar((ac.fin_de_temporada() as Array).is_empty(), "camada vacía: la semana y el fin de temporada no fallan")
	## camada de 200
	ac.chicos.clear()
	for i in 200:
		ac.chicos.append(ac._nuevo_chico(10 + i % 7))
	var t0 := Time.get_ticks_msec()
	for s in 12:
		ac.procesar_semana()
	var ms := Time.get_ticks_msec() - t0
	var d := ac.a_dic()
	var ac2 := Academia.new(m)
	ac2.desde_dic(d)
	_comprobar(ac2.chicos.size() == ac.chicos.size(), "camada de 200: guardar y cargar conserva a todos (%d)" % ac2.chicos.size())
	_comprobar(ms < 20000, "camada de 200: 12 semanas en %d ms (< 20 s)" % ms)
	var entregados := 0
	for t in 5:
		entregados += ac.fin_de_temporada().size()
		await get_tree().process_frame
	_comprobar(entregados >= 0 and ac.chicos.size() <= 200 + 40, "camada de 200: 5 fines de temporada (%d entregados, quedan %d)" % [entregados, ac.chicos.size()])
	var malos := 0
	for ch in ac.chicos:
		if int(ch["edad"]) < 8 or int(ch["edad"]) > 30:
			malos += 1
	_comprobar(malos == 0, "edades de la academia en rango (%d fuera)" % malos)
	## 20 temporadas del mundo con la academia normal
	var m2 := _mundo_nuevo(14)
	for t in 20:
		for s in 40:
			m2.avanzar_semana()
		if m2.directiva != null and m2.directiva.despedido_ya:
			m2.directiva.despedido_ya = false
			m2.directiva.confianza = 60
		m2.nueva_temporada()
		if t % 5 == 4:
			await get_tree().process_frame
	_comprobar(m2.academia.chicos.size() <= Academia.CUPO and m2.mi_club().plantilla.size() <= 40, "20 temporadas: academia %d (cupo %d), plantel %d" % [m2.academia.chicos.size(), Academia.CUPO, m2.mi_club().plantilla.size()])

func _ojeadores() -> void:
	var m := _mundo_nuevo(15)
	var o: Ojeadores = m.ojeadores
	var yo := m.mi_club()
	yo.saldo = 0
	var s0 := yo.saldo
	_comprobar(o.mejorar_analitica(yo) != "" and yo.saldo == s0, "análisis sin caja: se rechaza y la caja no cambia")
	_comprobar(o.alternar_academia("ARG", yo) != "" and yo.saldo == s0 and not o.tiene_academia("ARG"), "academia internacional sin caja: se rechaza")
	yo.saldo = -9000000
	_comprobar(o.mejorar_analitica(yo) != "" and o.alternar_academia("ARG", yo) != "", "con la caja en rojo también se rechazan")
	yo.saldo = 2000000000
	for i in 6:
		o.mejorar_analitica(yo)
	_comprobar(o.analitica_nivel <= Ojeadores.ANALITICA_MAX, "análisis nunca pasa del máximo (%d)" % o.analitica_nivel)
	for p in ["ARG", "BRA", "URU", "COL", "PER"]:
		o.alternar_academia(p, yo)
	_comprobar(o.academias.size() <= Ojeadores.ACADEMIAS_MAX, "academias internacionales ≤ %d (%d)" % [Ojeadores.ACADEMIAS_MAX, o.academias.size()])
	var antes := yo.saldo
	for p in o.academias.duplicate():
		o.alternar_academia(String(p), yo)
	_comprobar(o.academias.is_empty() and yo.saldo >= antes, "vender todas las academias devuelve dinero (%d → %d)" % [antes, yo.saldo])
	for nivel in [-3, 0, 99]:
		o.semana_analitica(nivel)
	o.presupuesto = -500000
	_comprobar(o.costo_informe() >= 0, "presupuesto negativo: el informe cuesta ≥ 0 (%d)" % o.costo_informe())
	for i in 30:
		m.avanzar_semana()
	_comprobar(o.hallazgos.size() <= 8, "hallazgos del análisis ≤ 8 (%d)" % o.hallazgos.size())
