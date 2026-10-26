extends BaseIdea
## LA RUEDA DE PRENSA EN OTRO IDIOMA (agente trad, 26-10-2026). Las preguntas y respuestas se arman en
## castellano en `nucleo/prensa*` y `_para_mostrar` las traduce justo antes de dárselas a la pantalla. Aquí se
## abren, en inglés, todas las preguntas del guion de siempre, las de identidad, clima, memoria y repregunta,
## el pie de campo y varias «al paso», y se exige que no quede ni una palabra castellana (quitando los nombres
## de periodistas y medios). Y en castellano todo sigue igual que antes.
var _rx := RegEx.create_from_string("[áéíóúñ¿¡]|\\b(el|la|los|las|del|que|con|para|por|una|sin|más|está|tu|tus|su|sus|usted|hoy|qué|esta|este|se|lo|le)\\b")
var _nombres: Array[String] = []
var _sin_traducir: Array[String] = []
var _vistos := 0

func _probar() -> void:
	_titulo("TRAD · rueda de prensa, pie de campo y al paso traducidos")
	var m := _mundo(2700)
	var pr: Prensa = m.prensa
	for f: Array in pr.PERIODISTAS:
		_nombres.append(String(f[1]))
		_nombres.append(String(f[2]))
	for f: Array in pr.MEDIOS_NUEVOS:
		_nombres.append(String(f[0]))
	## En castellano no cambia nada: la pregunta sale tal cual del guion.
	Idiomas.idioma = "es"
	pr.pregunta_pendiente = (pr._GANE[0] as Dictionary).duplicate(true)
	var es := pr.abrir_rueda(true, false)
	_comprobar(String(es["pregunta"]) == String(pr._GANE[0]["pregunta"]).trim_prefix("Prensa: ") and String(es["opciones"][0]["txt"]) == String(pr._GANE[0]["opciones"][0]["txt"]),
		"en castellano la rueda sale igual que siempre")
	pr.entrevista = {}
	Idiomas.idioma = "en"
	for par: Array in [[pr._GANE, true, false], [pr._EMPATE, false, true], [pr._PERDI, false, false]]:
		for q: Dictionary in par[0]:
			pr.memoria = {}
			pr.pregunta_pendiente = q.duplicate(true)
			_mirar("guion", pr.abrir_rueda(bool(par[1]), bool(par[2])))
			pr.entrevista = {}
	pr.memoria = {}
	pr.cambio_identidad = "escudo y camiseta"
	_mirar("identidad", pr.abrir_rueda(true, false))
	pr.entrevista = {}
	for gane: bool in [true, false]:
		pr.pregunta_pendiente = pr._pregunta_clima({"texto": "Calor intenso y seco, en la altura"}, gane, false)
		_mirar("clima", pr.abrir_rueda(gane, false))
		pr.entrevista = {}
	## La memoria: la frase soberbia que vuelve y el que no contestó la última vez.
	for tono: String in ["soberbia", "evasiva"]:
		for f: Array in pr.PERIODISTAS:
			pr.memoria[String(f[0])] = {"frase": "Sí: que se preparen los de arriba", "tono": tono, "fecha": -10}
		pr.pregunta_pendiente = (pr._PERDI[0] as Dictionary).duplicate(true)
		_mirar("memoria " + tono, pr.abrir_rueda(false, false))
		## La repregunta: contestar evasivo deja la puerta abierta.
		var ev := 0
		for i in (pr.entrevista["opciones"] as Array).size():
			if String(pr.entrevista["opciones"][i].get("tono", "")) == "evasiva":
				ev = i
		var r := pr.responder(ev, 20.0)
		if bool(r.get("sigue", false)):
			_mirar("repregunta", pr.entrevista)
		pr.entrevista = {}
	pr.memoria = {}
	for g: Array in [[true, false, 3, 1], [false, true, 1, 1], [false, false, 0, 2]]:
		var pie := pr.pie_de_campo(bool(g[0]), bool(g[1]), int(g[2]), int(g[3]))
		_mirar("pie de campo", pie, true)
		pr.pie = {}
	var al_paso := 0
	for sem in range(1, 400):
		pr.al_paso = {}
		pr.pie = {}
		var e := pr.revisar_al_paso(2026 + sem / 40, sem % 40)
		if not e.is_empty():
			al_paso += 1
			_mirar("al paso", e, true)
	Idiomas.idioma = "es"
	_comprobar(al_paso >= 10, "salen varias entrevistas «al paso» (%d)" % al_paso)
	_comprobar(_vistos >= 30, "textos de prensa revisados en inglés: %d" % _vistos)
	_comprobar(_sin_traducir.is_empty(), "nada en castellano (%d%s)" % [_sin_traducir.size(), "" if _sin_traducir.is_empty() else ": " + " | ".join(_sin_traducir.slice(0, 5))])

func _mirar(que: String, e: Dictionary, con_quien: bool = false) -> void:
	if e.is_empty():
		_sin_traducir.append(que + ": no salió entrevista")
		return
	var textos: Array[String] = [String(e.get("pregunta", ""))]
	for o: Dictionary in e.get("opciones", []):
		textos.append(String(o.get("txt", "")))
	if con_quien:
		textos.append(String(e.get("quien", "")))
	for t: String in textos:
		_vistos += 1
		var limpio := t
		for n: String in _nombres:
			limpio = limpio.replace(n, "")
		if limpio.strip_edges() == "" or _rx.search(limpio.to_lower()) != null:
			_sin_traducir.append("%s: %s" % [que, t.left(80)])
