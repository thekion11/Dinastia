extends BaseIdea
## SESIÓN 6 (26-10-2026), fila 19 de la propuesta s4: el mercado de entrenadores de
## la IA. Termómetro de presión, despidos con su gracia, el DT nuevo que manda en la
## previa, noticia, efecto del cambio, tu club fuera, guardado y carga.

func _probar() -> void:
	_titulo("S6: MERCADO DE ENTRENADORES DE LA IA (fila 19)")
	var m := _mundo(1919)
	var mdt := MercadoDT.de(m)
	_comprobar(mdt != null and MercadoDT.de(m) == mdt, "vive en el mundo (una sola instancia)")
	_comprobar(MercadoDT.presion(m, m.mi_club()) == -1, "antes de la jornada 8 no se juzga a nadie")
	for i in 10:
		m.avanzar_semana()
	var termo := mdt.termometro(m)
	var orden := true
	for i in range(1, termo.size()):
		orden = orden and int(termo[i - 1]["presion"]) >= int(termo[i]["presion"])
	_comprobar(not termo.is_empty() and orden, "a la jornada 10 hay termómetro de %d banquillos, el más caliente primero" % termo.size())
	## Un despido a mano: el DT nuevo manda en la previa.
	var c: Club = null
	for f: Dictionary in termo:
		if not bool(f["mio"]) and not mdt.cambios.has((f["club"] as Club).id):
			c = f["club"]
			break
	var antes := String(Previa.dt_de(c)["nombre"])
	var moral := c.plantilla[0].moral
	var avisos: Array = []
	mdt.noticia.connect(func(t: String, _b: String) -> void: avisos.append(t))
	var nuevo := mdt.cambiar_dt(m, c)
	_comprobar(String(Previa.dt_de(c)["nombre"]) == String(nuevo["nombre"]) and String(nuevo["nombre"]) != antes,
		"%s cambia de DT: sale %s, entra %s, y la previa lo sabe" % [c.nombre, antes, String(nuevo["nombre"])])
	_comprobar(not avisos.is_empty() and mdt.historial.size() >= 1 and mdt.parados.size() >= 1, "con noticia, historial y el despedido en la lista de parados")
	_comprobar(c.plantilla[0].moral == mini(100, moral + MercadoDT.EFECTO_CAMBIO), "efecto del cambio: moral +%d" % MercadoDT.EFECTO_CAMBIO)
	## Muchas semanas: hay despidos, nunca del tuyo, y con gracia para el que llega.
	for i in 20:
		m.avanzar_semana()
	var mio_cambiado := mdt.cambios.has(m.mi_club_id)
	_comprobar(not mio_cambiado, "tu club no entra en el mercado (te juzga tu directiva)")
	var gracia_ok := true
	var por_club := {}
	for h: Dictionary in mdt.historial:
		var k := String(h["club"])
		var t := int(h["anio"]) * 60 + int(h["semana"])
		if por_club.has(k) and t - int(por_club[k]) < MercadoDT.GRACIA:
			gracia_ok = false
		por_club[k] = t
	_comprobar(gracia_ok, "nadie echa a un DT antes de %d semanas (%d cambios en 30 semanas)" % [MercadoDT.GRACIA, mdt.historial.size()])
	## 20 semanas más (más el despido a mano): entre 1 y 5 por liga, como en una liga real.
	var n := mdt.historial.size()
	_comprobar(n >= m.ligas.size() and n <= m.ligas.size() * 5, "el mercado se mueve sin volverse loco (%d cambios en %d ligas)" % [n, m.ligas.size()])
	## Guardado y carga.
	var dic := mdt.a_dic()
	var m2 := _mundo(2121)
	var mdt2 := MercadoDT.de(m2)
	mdt2.desde_dic(m2, JSON.parse_string(JSON.stringify(dic)))
	var c2: Club = m2.clubes.get(c.id)
	_comprobar(c2 != null and mdt2.historial.size() == mdt.historial.size()
		and String(Previa.dt_de(c2)["nombre"]) == String(Previa.dt_de(c)["nombre"]), "al cargar, cada club recupera su DT")
	m2.generar(["CHI", "ARG"], 77)
	_comprobar(not m2.has_meta("mercado_dt") or MercadoDT.de(m2).cambios.is_empty(), "un mundo nuevo empieza sin cambios")
