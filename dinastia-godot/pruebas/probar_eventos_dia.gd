extends Node
## El modelo de eventos del día (avance por días, paso 1): clases, zonas, paradas y plan de parada, con varios mundos (no siempre el mismo país).

var fallos := 0

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		fallos += 1
		print("FALLO ", msg)

func correr(padre: Node = null) -> int:
	var mundos := [[["CHI"], 11], [["ARG", "BRA"], 22], [["ESP", "ENG"], 33], [["GER", "ITA", "FRA"], 44]]
	var vistos := {"partido": 0, "pantalla": 0, "aviso": 0}
	for cfg: Array in mundos:
		var m := Mundo.new()
		var paises: Array[String] = []
		for c in cfg[0]:
			paises.append(String(c))
		m.generar(paises, int(cfg[1]))
		m.tomar_el_mando(m.ligas[0].clubes[1 + int(cfg[1]) % 3].id)
		var etiqueta := "%s/%d" % [",".join(cfg[0]), cfg[1]]
		var semanas := EventosFecha.semanas(m, 8)
		_ok(not semanas.is_empty(), "%s: hay semanas por delante" % etiqueta)
		for s: Dictionary in semanas:
			var total := (s["eventos"] as Array).size()
			for d in 7:
				total += EventosDia.del_calendario(m, int(s["k"]), d).size()
			var contados := 0
			for d in 7:
				var dia := EventosDia.del_dia(m, int(s["k"]), d)
				contados += dia.size()
				for e: Dictionary in dia:
					var clase := String(e["clase"])
					vistos[clase] = int(vistos[clase]) + 1
					_ok(clase in [EventosDia.PARTIDO, EventosDia.PANTALLA, EventosDia.AVISO], "%s: clase válida (%s)" % [etiqueta, clase])
					if clase == EventosDia.AVISO:
						_ok(EventosDia.ZONAS.has(String(e["zona"])), "%s: el aviso tiene zona del menú (%s)" % [etiqueta, e["zona"]])
					else:
						_ok(String(e["zona"]) == "", "%s: solo los avisos tienen zona" % etiqueta)
					if EventosFecha.es_partido(e):
						_ok(clase == EventosDia.PARTIDO, "%s: un partido es PARTIDO" % etiqueta)
			_ok(contados == total, "%s: semana %d: los eventos por día (competición + calendario nacional) suman los de la semana (%d/%d)" % [etiqueta, int(s["k"]), contados, total])
		var p := EventosDia.proxima_parada(m)
		_ok(not p.is_empty(), "%s: hay una próxima parada" % etiqueta)
		if not p.is_empty():
			var mejor := 1 << 30
			for s: Dictionary in semanas:
				for e: Dictionary in s["eventos"]:
					mejor = mini(mejor, int(s["k"]) * 7 + int(e["dia"]))
				for d in 7:
					if not EventosDia.del_calendario(m, int(s["k"]), d).is_empty():
						mejor = mini(mejor, int(s["k"]) * 7 + d)
			_ok(int(p["k"]) * 7 + int(p["dia"]) == mejor, "%s: la parada es el primer día con eventos" % etiqueta)
			for e: Dictionary in p["eventos"]:
				_ok(int(e["dia"]) == int(p["dia"]), "%s: los eventos de la parada son del mismo día" % etiqueta)
			var sig := EventosDia.proxima_parada(m, int(p["k"]), int(p["dia"]) + 1)
			if not sig.is_empty():
				_ok(int(sig["k"]) * 7 + int(sig["dia"]) > int(p["k"]) * 7 + int(p["dia"]), "%s: la siguiente parada es posterior" % etiqueta)
			var plan := EventosDia.plan_de_parada(p["eventos"])
			_ok(bool(plan["vuelve_al_menu"]), "%s: toda parada vuelve al menú" % etiqueta)
			_ok(bool(plan["dia_de_partido"]) == not (plan["partidos"] as Array).is_empty(), "%s: día de partido = hay partidos" % etiqueta)
		_ok(EventosDia.proxima_parada(m, 99, 0).is_empty(), "%s: sin eventos más allá del horizonte" % etiqueta)
		# Calendario nacional del país del club: memoria e independencia son PANTALLA; el resto, AVISO; nada escrito a mano aquí
		var hay_fechas := 0
		for k in 52:
			for d in 7:
				for f: Dictionary in EventosDia.del_calendario(m, k, d):
					hay_fechas += 1
					var sub := String(f["subtipo"])
					if sub == "memoria" or sub == "independencia":
						_ok(String(f["clase"]) == EventosDia.PANTALLA, "%s: %s es PANTALLA (%s)" % [etiqueta, sub, f["nombre"]])
						_ok(String(f["reflexion"]) != "", "%s: %s trae su frase de reflexión (%s)" % [etiqueta, sub, f["nombre"]])
					else:
						_ok(String(f["clase"]) == EventosDia.AVISO and EventosDia.ZONAS.has(String(f["zona"])), "%s: %s es un AVISO con zona (%s)" % [etiqueta, sub, f["nombre"]])
					_ok(bool(f["sobrio"]) == (sub == "memoria"), "%s: solo la memoria es sobria (%s)" % [etiqueta, f["nombre"]])
		_ok(hay_fechas > 0, "%s: el calendario nacional trae fechas" % etiqueta)
		vistos["fechas"] = int(vistos.get("fechas", 0)) + hay_fechas
	# Clasificación directa (no depende del mundo)
	_ok(EventosDia.clase_de({"tipo": "liga"}) == EventosDia.PARTIDO, "liga es PARTIDO")
	_ok(EventosDia.clase_de({"tipo": "conti"}) == EventosDia.PARTIDO, "conti es PARTIDO")
	_ok(EventosDia.clase_de({"tipo": "fin"}) == EventosDia.PANTALLA, "fin es PANTALLA")
	_ok(EventosDia.clase_de({"tipo": "mercado_abre"}) == EventosDia.AVISO, "mercado_abre es AVISO")
	_ok(EventosDia.clase_de({"tipo": "mercado_cierra"}) == EventosDia.PANTALLA and EventosDia.zona_de({"tipo": "mercado_cierra"}) == "", "mercado_cierra es un HITO (PANTALLA, sin campana)")
	_ok(EventosDia.clase_de({"tipo": "tipo_desconocido"}) == EventosDia.AVISO, "lo desconocido es un AVISO, nunca ocupa la pantalla")
	_ok(EventosDia.zona_de({"tipo": "tipo_desconocido"}) == EventosDia.ZONA_POR_DEFECTO, "lo desconocido va a la zona por defecto")
	var plan2 := EventosDia.plan_de_parada([{"tipo": "liga"}, {"tipo": "copa"}, {"tipo": "mercado_cierra"}, {"tipo": "fin"}])
	_ok((plan2["partidos"] as Array).size() == 2 and (plan2["partido"] as Dictionary)["tipo"] == "liga", "con dos partidos el primero es el del día")
	_ok((plan2["pantallas"] as Array).size() == 2 and (plan2["avisos"] as Dictionary).is_empty(), "pantallas (mercado cierra y fin) y avisos por zona")
	_ok(not bool(EventosDia.plan_de_parada([])["vuelve_al_menu"]), "sin eventos no vuelve al menú")
	_ok(int(vistos["partido"]) > 0, "en estos mundos se vieron partidos")
	print("clases vistas: ", vistos)
	return fallos

func _ready() -> void:
	correr(self)
	print("FIN. %d fallos" % fallos)
	get_tree().quit()
