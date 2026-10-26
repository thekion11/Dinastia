extends BaseIdea
## Propuestas s4 (26-10): fila 5 (vida privada regulable) y fila 13 (imprevistos con contexto).

func _probar() -> void:
	_titulo("S4 · VIDA REGULABLE E IMPREVISTOS")
	_vida()
	_imprevistos()

func _vida() -> void:
	var n := Necesidades.new()
	n.pasar(20 * 60, "horas_extra")
	_comprobar(n.nivel_energia() == 2 and n.factor_riesgo() > 1.0, "completa: 20 h de horas extra agotan y suben el riesgo")
	var l := Necesidades.new()
	l.poner_modo("ligera")
	l.pasar(20 * 60, "horas_extra")
	l.pasar(30 * 60, "trabajo")
	_comprobar(l.nivel_energia() < 2 and l.nivel_hambre() < 2, "ligera: nunca llega a grave (%d, %d)" % [l.energia(), l.hambre()])
	_comprobar(l.factor_riesgo() == 1.0 and l.factor_rendimiento() == 1.0, "ligera: sin castigo")
	_comprobar(l.energia() < 95, "ligera: la energía sí se mueve (%d)" % l.energia())
	var a := Necesidades.new()
	a.pasar(20 * 60, "horas_extra")
	a.poner_modo("apagada")
	_comprobar(a.energia() == 95 and a.nivel_energia() == 0, "apagada: vuelve a la rutina al apagarla")
	a.pasar(40 * 60, "horas_extra")
	_comprobar(a.energia() == 95 and a.factor_riesgo() == 1.0, "apagada: el tiempo no castiga")
	var b := Necesidades.new()
	b.desde_dic(a.a_dic())
	_comprobar(b.modo == "apagada", "el modo se guarda")
	var v := Necesidades.new()
	v.desde_dic({"en": 1000})
	_comprobar(v.modo == "completa", "guardado viejo: vida completa")
	## En una partida guardada y cargada.
	var m := _mundo(4401)
	m.necesidades.poner_modo("ligera")
	m.imprevistos.recientes = ["intox"]
	var m2 := Partida.desde_instantanea(JSON.parse_string(JSON.stringify(Partida.instantanea(m))))
	_comprobar(m2.necesidades.modo == "ligera", "la partida conserva el modo de vida")
	_comprobar(m2.imprevistos.recientes == ["intox"], "la partida conserva los imprevistos")

func _imprevistos() -> void:
	var m := _mundo(4402)
	var c := m.mi_club()
	var imp := Imprevistos.new()
	_comprobar(Imprevistos.CATALOGO.size() >= 40, "catálogo de %d imprevistos" % Imprevistos.CATALOGO.size())
	## Todos los textos traducidos al inglés.
	var extra: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://datos/idiomas_extra.json"))
	var sin := 0
	for f: Dictionary in Imprevistos.CATALOGO:
		for l: String in ["en", "pt", "fr", "it", "de", "ca", "pl", "tr"]:
			if not (extra[l] as Dictionary).has(String(f["txt"])):
				sin += 1
	_comprobar(sin == 0, "todos los imprevistos tienen traducción")
	## Contexto: un lesionado largo no recibe imprevistos que exigen estar sano.
	for j: Jugador in c.plantilla:
		j.lesion = 8
	var rng := RandomNumberGenerator.new()
	for i in 60:
		rng.seed = i
		var r := imp.sortear(m, c, rng, false)
		if not r.is_empty() and r["jugador"] != null:
			var conds: Array = r["fila"]["c"]
			_comprobar(not conds.has("sano") and not conds.has("sin_lesion_larga"),
				"con todos lesionados largo no sale «%s»" % r["fila"]["id"])
		imp.recientes.clear()
	for j: Jugador in c.plantilla:
		j.lesion = 0
	## Toque de queda: nada de noche.
	var noches := 0
	for i in 80:
		rng.seed = 1000 + i
		var r := imp.sortear(m, c, rng, true)
		if not r.is_empty() and (r["fila"]["c"] as Array).has("noche"):
			noches += 1
		imp.recientes.clear()
	_comprobar(noches == 0, "con toque de queda no hay imprevistos de noche")
	## Jugadores reales: solo los deportivos.
	for j: Jugador in c.plantilla:
		j.real = true
	var privados := 0
	for i in 80:
		rng.seed = 2000 + i
		var r := imp.sortear(m, c, rng, false)
		if not r.is_empty() and r["jugador"] != null and not bool(r["fila"].get("dep", false)):
			privados += 1
		imp.recientes.clear()
	_comprobar(privados == 0, "a los jugadores reales solo les pasan imprevistos deportivos")
	for j: Jugador in c.plantilla:
		j.real = false
	## Efecto que dura: la morriña baja la moral varias semanas y luego se acaba.
	var fila: Dictionary = {}
	for f: Dictionary in Imprevistos.CATALOGO:
		if f["id"] == "morrina":
			fila = f
	var j0: Jugador = c.plantilla[0]
	j0.moral = 80
	imp.activos.clear()
	imp.aplicar(m, c, fila, j0, 3)
	for s in 5:
		imp.correr_activos(c)
	_comprobar(j0.moral == 71 and imp.activos.is_empty(), "la morriña dura 3 semanas (-9 de moral: %d)" % j0.moral)
	## Recorte: el dinero se va semana a semana.
	var antes := c.saldo
	for f: Dictionary in Imprevistos.CATALOGO:
		if f["id"] == "recorte":
			imp.aplicar(m, c, f, null, 4)
	for s in 4:
		imp.correr_activos(c)
	_comprobar(c.saldo < antes, "el recorte resta caja durante semanas")
	## Oferta loca: entra en el despacho.
	var n_of := m.mercado.ofertas_recibidas.size()
	for f: Dictionary in Imprevistos.CATALOGO:
		if f["id"] == "oferta_loca":
			imp.aplicar(m, c, f, j0, 0)
	_comprobar(m.mercado.ofertas_recibidas.size() == n_of + 1, "la oferta loca llega al despacho")
	## Guardado.
	imp.activos.append({"id": "x", "jid": j0.id, "q": "moral_sem", "v": -1, "s": 2})
	var imp2 := Imprevistos.new()
	imp2.desde_dic(imp.a_dic())
	_comprobar(imp2.activos.size() == imp.activos.size(), "los efectos en marcha se guardan")
	## Una temporada entera: salen imprevistos y no rompe nada.
	var vistos: Array = []      ## las lambdas copian los enteros: se cuenta en un Array
	m.prensa.noticia.connect(func(t: String, _x: String) -> void:
		for v: String in Imprevistos.TITULOS.values():
			if t == Idiomas.t(v):
				vistos.append(t))
	for s in 30:
		m.avanzar_semana()
	_comprobar(vistos.size() >= 1, "en 30 semanas salieron %d imprevistos" % vistos.size())
