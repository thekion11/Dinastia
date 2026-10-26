extends BaseIdea
## LO QUE EL NÚCLEO CUENTA POR `noticia`/`aviso` Y `noticias_p1.gd` REENVÍA (agente trad, 26-10-2026): la
## federación (asambleas, elecciones), el banco (créditos, bono, mora, veedor) y las ventas. Se guarda en
## castellano (bandeja, móvil) y se traduce al pintar, así que aquí se disparan de verdad con una partida y se
## exige que, en inglés, el título y el cuerpo salgan sin castellano (quitando nombres de clubes y personas).
var _rx := RegEx.create_from_string("[áéíóúñ¿¡]|\\b(el|la|los|las|del|que|con|para|por|una|sin|más|está|tu|tus|su|sus|se|de|en|y|al)\\b")
var _vistas: Array = []

func _probar() -> void:
	_titulo("TRAD · noticias del núcleo (federación, banco, ventas) traducidas")
	var m := _mundo(2800)
	var c := m.mi_club()
	var oir := func(t: String, cu: String) -> void: _vistas.append([t, cu])
	m.federacion.noticia.connect(oir)
	m.banco.aviso.connect(oir)
	m.cesiones.noticia.connect(oir)
	## Asambleas: cada moción, votando a favor y en contra.
	for v: Dictionary in m.federacion.catalogo():
		for op: String in ["a", "b"]:
			m.federacion.voto_pendiente = v.duplicate(true)
			m.federacion.votar(op, c, m.ligas[0].clubes)
	## Elecciones: varias, para que salgan «gana» y «renueva».
	for anio in range(2026, 2080, 4):
		m.federacion.revisar_presidencia(anio)
	## El banco: los tres créditos, el bono y la caja en rojo semanas seguidas.
	for i in 3:
		m.banco.pedir(i, c)
	m.banco.emitir_bono(c)
	c.saldo = -500000000
	for s in 14:
		m.banco.semana(c)
	_comprobar(_vistas.size() >= 25, "noticias disparadas de verdad: %d" % _vistas.size())
	var propios: Array[String] = []
	for l in m.ligas:
		for x: Club in l.clubes:
			propios.append(x.nombre)
	for n: String in m.federacion._PRES_NOMBRES + m.federacion._PRES_APELLIDOS:
		propios.append(n)
	propios.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
	Idiomas.idioma = "en"
	var malas: Array[String] = []
	var titulos := {}
	for par: Array in _vistas:
		titulos[String(par[0])] = true
		for s: String in [String(par[0]), String(par[0]) + ".", String(par[1])]:
			var t := Idiomas.t(s)
			var limpio := t
			for n: String in propios:
				limpio = limpio.replace(n, "")
			if _rx.search(limpio.to_lower()) != null:
				malas.append(t.left(110))
	Idiomas.idioma = "es"
	_comprobar(titulos.size() >= 8, "títulos distintos: %d" % titulos.size())
	_comprobar(malas.is_empty(), "en inglés no queda castellano (%d%s)" % [malas.size(), "" if malas.is_empty() else ": " + " | ".join(malas.slice(0, 4))])
