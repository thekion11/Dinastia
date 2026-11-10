extends "res://pruebas/banco/base.gd"
## [Banco · grupo «continentales»] Los formatos reales de los torneos continentales (sesión 6, 10-11).

## Un club de relleno para probar el motor sin generar un mundo entero.
func _clubes_de_prueba(n: int, prefijo: String, pais: String) -> Array[Club]:
	var salida: Array[Club] = []
	for i in n:
		var c := Club.new("%s%d" % [prefijo, i], "%s %d" % [prefijo, i])
		c.pais = pais
		c.rep = 90 - (i % 40)
		salida.append(c)
	return salida

func _probar_continentales_tabla_de_formatos() -> void:
	_titulo("CONTINENTALES · LA TABLA DE FORMATOS")
	var malos := 0
	for id: String in FormatosConti.FORMATOS:
		var huecos := FormatosConti.huecos(id)
		var semanas := FormatosConti.semanas(id, id, huecos.size())
		var ok := semanas.size() == huecos.size()
		for i in semanas.size():
			if i > 0 and int(semanas[i]) <= int(semanas[i - 1]):
				ok = false
			if id != FormatosConti.CLASICO and int(semanas[i]) % 4 == 0:
				ok = false   ## los múltiplos de 4 son de la copa nacional
		var f := FormatosConti.formato(id)
		if String(f["fase"]) == "liga" and int(f["plazas"]) % 4 != 0:
			ok = false
		_linea("  %-8s %2d plazas, %2d partidos por torneo, última semana %d" % [id, int(f["plazas"]), huecos.size(), int(semanas[semanas.size() - 1])])
		if not ok:
			malos += 1
	_comprobar(malos == 0, "cada formato tiene una semana por partido, crecientes y fuera de las de la copa (%d mal)" % malos)
	_comprobar(FormatosConti.huecos("ucl").size() == 17, "Champions: 8 de liga + playoff (2) + octavos (2) + cuartos (2) + semis (2) + final = 17")
	_comprobar(FormatosConti.huecos("lib").size() == 13, "Libertadores: 6 de grupo + octavos, cuartos y semis a ida y vuelta + final = 13")
	_comprobar(FormatosConti.huecos("clasico").size() == 6, "el formato de antes (partidas viejas) sigue siendo de 6 partidos")
	var europa := 0
	for k in ["ucl", "uel", "uecl"]:
		europa += FormatosConti.plazas(k)
	_comprobar(europa == 108, "Europa reparte 36 + 36 + 36 plazas (%d)" % europa)
	_comprobar(Continental.claves().has("uecl") and Continental.nombre_conti("uecl") != "uecl", "la Conference existe como torneo, con su nombre")

## Valida el sorteo de la fase de liga y devuelve cuántos clubes se desvían de «dos rivales de cada bombo».
func _validar_fase_de_liga(clubes: Array[Club], dias: Array, que: String) -> int:
	var n := clubes.size()
	var m := n / 4
	_comprobar(dias.size() == 8, "%s: 8 fechas (%d)" % [que, dias.size()])
	var por_club := {}
	var vistos := {}
	var repetidos := 0
	var dobles := 0
	for dia: Array in dias:
		var hoy := {}
		for par: Array in dia:
			var a: Club = par[0]
			var b: Club = par[1]
			if hoy.has(a.id) or hoy.has(b.id):
				dobles += 1
			hoy[a.id] = true
			hoy[b.id] = true
			var k := "%s|%s" % [a.id, b.id] if a.id < b.id else "%s|%s" % [b.id, a.id]
			if vistos.has(k):
				repetidos += 1
			vistos[k] = true
			if not por_club.has(a.id):
				por_club[a.id] = []
			if not por_club.has(b.id):
				por_club[b.id] = []
			por_club[a.id].append(b)
			por_club[b.id].append(a)
	var sin_ocho := 0
	for c: Club in clubes:
		if (por_club.get(c.id, []) as Array).size() != 8:
			sin_ocho += 1
	_comprobar(sin_ocho == 0, "%s: cada club juega 8 partidos (%d no)" % [que, sin_ocho])
	_comprobar(dobles == 0, "%s: nadie juega dos veces en la misma fecha (%d casos)" % [que, dobles])
	_comprobar(repetidos == 0, "%s: nadie se enfrenta dos veces (%d repetidos)" % [que, repetidos])
	var bombo_de := {}
	for i in n:
		bombo_de[clubes[i].id] = i / m
	var fuera := 0
	for c: Club in clubes:
		var cuenta := [0, 0, 0, 0]
		for r: Club in por_club.get(c.id, []):
			cuenta[bombo_de[r.id]] += 1
		var ok := true
		for x in 4:
			ok = ok and cuenta[x] == 2
		if not ok:
			fuera += 1
	return fuera

func _probar_continentales_fase_de_liga() -> void:
	_titulo("CONTINENTALES · SORTEO DE LA FASE DE LIGA (bombos)")
	var casos := [["ESP", 36, 11], ["ENG", 36, 12], ["JPN", 24, 13], ["FRA", 36, 14]]
	for caso: Array in casos:
		Azar.sembrar(int(caso[2]))
		var clubes := _clubes_de_prueba(int(caso[1]), String(caso[0]), String(caso[0]))
		var dias := SorteoLigaConti.armar(clubes)
		var fuera := _validar_fase_de_liga(clubes, dias, "%d clubes (semilla %d)" % [int(caso[1]), int(caso[2])])
		var tope := 8 if int(caso[1]) / 4 % 2 == 1 else 0
		_linea("  %d clubes: %d con una desviación de bombo" % [int(caso[1]), fuera])
		_comprobar(fuera <= tope, "bombos de %d: como mucho %d clubes se desvían de dos rivales por bombo (%d)" % [int(caso[1]), tope, fuera])
	var distintos := {}
	for s in 4:
		Azar.sembrar(100 + s)
		var cl := _clubes_de_prueba(36, "X", "ESP")
		var dias2 := SorteoLigaConti.armar(cl)
		distintos[JSON.stringify(dias2[0].map(func(par: Array) -> String: return (par[0] as Club).id + (par[1] as Club).id))] = true
	_comprobar(distintos.size() >= 3, "el sorteo cambia con la semilla (%d de 4 distintos)" % distintos.size())

func _jugar_hasta_el_final(t: Continental, tope: int = 40) -> int:
	var vueltas := 0
	while t.en_curso() and vueltas < tope:
		t.jugar_ronda()
		vueltas += 1
	return vueltas

func _probar_continentales_champions() -> void:
	_titulo("CONTINENTALES · CHAMPIONS CON FASE DE LIGA")
	for caso: Array in [["ESP", 21], ["ITA", 22], ["GER", 23]]:
		Azar.sembrar(int(caso[1]))
		var clubes := _clubes_de_prueba(36, String(caso[0]), String(caso[0]))
		var t := Continental.crear("ucl")
		t.preparar(clubes)
		_comprobar(t.formato == "ucl" and t.es_fase_de_liga() and t.grupos.size() == 1 and t.grupos[0].size() == 36, "%s: 36 clubes en una sola tabla" % caso[0])
		_comprobar(t.nombre_de_ronda() == "Fase de liga · Fecha 1", "arranca en la fecha 1 de la fase de liga")
		for i in 8:
			t.jugar_ronda()
		var pj_mal := 0
		for fila: Dictionary in t.tabla_de_grupo(0):
			if int(fila["pj"]) != 8:
				pj_mal += 1
		_comprobar(pj_mal == 0, "%s: cada club jugó 8 partidos en la fase de liga (%d mal)" % [caso[0], pj_mal])
		var orden := t.tabla_de_grupo(0)
		_comprobar(t.nombre_de_ronda() == "Playoff · Ida" and t.vivos.size() == 16, "después de la fase de liga: playoff a ida y vuelta con 16 clubes (%s, %d)" % [t.nombre_de_ronda(), t.vivos.size()])
		_comprobar(t.vivos[0] == orden[8]["club"] and t.vivos[1] == orden[23]["club"], "el 9.º juega el playoff contra el 24.º")
		var directos: Array = []
		for i in 8:
			directos.append(orden[i]["club"])
		_comprobar(t.clasificados().size() == 24, "pasan 24 de la fase de liga (los 8 directos y los 16 del playoff): %d" % t.clasificados().size())
		t.jugar_ronda()
		_comprobar(t.nombre_de_ronda() == "Playoff · Vuelta", "la ida es una ronda y la vuelta otra")
		var res := t.jugar_ronda()
		_comprobar(res.size() == 8 and res[0].has("agregado") and res[0].has("pasa"), "la vuelta trae el global y quién pasa")
		_comprobar(t.vivos.size() == 16 and t.nombre_de_ronda() == "Octavos de final · Ida", "octavos con 16 clubes: 8 directos + 8 ganadores del playoff")
		var directos_en_octavos := 0
		for c in directos:
			if t.vivos.has(c):
				directos_en_octavos += 1
		_comprobar(directos_en_octavos == 8, "los 8 primeros de la fase de liga están en octavos (%d)" % directos_en_octavos)
		var saldo0 := 0
		for c: Club in t.vivos:
			saldo0 += c.saldo
		var rondas := 0
		while t.vivos.size() > 2 and t.en_curso():
			t.jugar_ronda()
			rondas += 1
		var finalistas: Array[Club] = t.vivos.duplicate()
		var antes := [finalistas[0].saldo, finalistas[1].saldo]
		t.jugar_ronda()
		rondas += 1
		_comprobar(t.campeon != null and rondas == 17 - 10, "%s: campeón con %s tras sus 17 partidos (%d más)" % [caso[0], t.campeon.nombre if t.campeon else "-", rondas])
		var ultima: Dictionary = t.historial[t.historial.size() - 1]
		_comprobar(ultima["ronda"] == "Final" and ultima["resultados"].size() == 1, "la final es a partido único")
		var i_c := finalistas.find(t.campeon)
		_comprobar(t.campeon.saldo - int(antes[i_c]) == t.premio, "el campeón cobra el premio de la copa (%d de %d)" % [t.campeon.saldo - int(antes[i_c]), t.premio])

func _probar_continentales_libertadores() -> void:
	_titulo("CONTINENTALES · LIBERTADORES (8 GRUPOS) Y SUDAMERICANA")
	for caso: Array in [["ARG", 31], ["BRA", 32], ["COL", 33]]:
		Azar.sembrar(int(caso[1]))
		var clubes := _clubes_de_prueba(32, String(caso[0]), String(caso[0]))
		var t := Continental.crear("lib" if caso[0] != "COL" else "sud")
		t.preparar(clubes)
		_comprobar(t.grupos.size() == 8 and t.grupos[0].size() == 4 and t.por_grupos, "%s: 8 grupos de 4" % caso[0])
		for i in 6:
			t.jugar_ronda()
		var mal := 0
		for g in 8:
			for fila: Dictionary in t.tabla_de_grupo(g):
				if int(fila["pj"]) != 6:
					mal += 1
		_comprobar(mal == 0, "%s: cada club juega 6 partidos de grupo, ida y vuelta (%d mal)" % [caso[0], mal])
		_comprobar(t.vivos.size() == 16 and t.nombre_de_ronda() == "Octavos de final · Ida" and t.clasificados().size() == 16, "pasan 16 a octavos (%s)" % t.nombre_de_ronda())
		var ida := t.jugar_ronda()
		var vuelta := t.jugar_ronda()
		_comprobar(ida.size() == 8 and not ida[0].has("pasa") and vuelta[0].has("agregado"), "octavos a ida y vuelta: la ida no decide")
		_comprobar(vuelta[0]["local"] == ida[0]["visita"] and vuelta[0]["visita"] == ida[0]["local"], "en la vuelta se invierte el campo")
		_jugar_hasta_el_final(t)
		_comprobar(t.campeon != null and t.historial.size() == 13, "%s: campeón tras los 13 partidos del formato" % caso[0])

func _probar_continentales_otras_confederaciones() -> void:
	_titulo("CONTINENTALES · ASIA, ÁFRICA, OCEANÍA Y CONCACAF")
	var esperados := {"asia": [24, "liga", 13], "afr": [16, "grupos", 12], "oce": [8, "grupos", 9], "conc": [16, "ko", 8]}
	for k: String in esperados:
		Azar.sembrar(40 + k.length())
		var f: Array = esperados[k]
		var t := Continental.crear(k)
		t.preparar(_clubes_de_prueba(int(f[0]), k.to_upper(), "JPN"))
		_comprobar(t.formato == k and t.huecos().size() == int(f[2]), "%s: %d clubes, %d partidos" % [k, int(f[0]), t.huecos().size()])
		if String(f[1]) == "ko":
			_comprobar(not t.por_grupos and t.vivos.size() == 16, "%s: eliminación directa desde el principio" % k)
		else:
			_comprobar(t.por_grupos and t.vivos.is_empty(), "%s: arranca con la primera fase" % k)
		var finales := 0
		while t.en_curso() and finales < 40:
			var h := t.hueco_actual()
			var res := t.jugar_ronda()
			if t.campeon != null and int(h["pata"]) == 2 and h["vivos"] == 2:
				finales += 1
				_comprobar(res.size() == 1 and res[0].has("agregado"), "%s: la final es a ida y vuelta" % k)
		_comprobar(t.campeon != null and t.historial.size() == int(f[2]), "%s: campeón en los %d partidos previstos (%d)" % [k, int(f[2]), t.historial.size()])
	## Con menos clubes que plazas se juega a eliminación directa, como siempre.
	Azar.sembrar(77)
	var pocos := Continental.crear("ucl")
	pocos.preparar(_clubes_de_prueba(11, "P", "ESP"))
	_comprobar(pocos.formato == FormatosConti.KO and not pocos.por_grupos and pocos.vivos.size() == 8, "con 11 clubes la Champions se juega por eliminación directa de 8")
	_jugar_hasta_el_final(pocos)
	_comprobar(pocos.campeon != null, "y tiene campeón")

func _probar_continentales_semanas_y_guardado() -> void:
	_titulo("CONTINENTALES · SEMANAS, JORNADA REAL Y PARTIDAS VIEJAS")
	for s in [["ESP", 51], ["ARG", 52], ["JPN", 53]]:
		var m := Mundo.new()
		m.generar([String(s[0])], int(s[1]))
		m.tomar_el_mando(m.ligas[0].clubes[0].id)
		var jugados := 0
		var en_mi_torneo := 0
		var mi: Continental = m.mi_continental()
		for sem in 36:
			if mi != null and mi.toca(m.semana) and not m.partido_continental().is_empty():
				en_mi_torneo += 1
			m.avanzar_semana()
		for k: String in m.continentales:
			var t: Continental = m.continentales[k]
			if t.ronda > 0:
				jugados += 1
		_linea("  %s: %d torneos jugaron algo en 36 semanas; mi torneo: %s, %d partidos míos" % [s[0], jugados, mi.nombre if mi else "-", en_mi_torneo])
		_comprobar(jugados >= 1, "%s: los continentales avanzan solos con las semanas (%d)" % [s[0], jugados])
	## Partida vieja: un continental «clasico» a medias se guarda, se abre y sigue igual.
	Azar.sembrar(61)
	var viejo := Continental.crear("lib")
	viejo.preparar_con(_clubes_de_prueba(16, "V", "CHI"), FormatosConti.CLASICO)
	viejo.jugar_ronda()
	var copia := Continental.crear("lib")
	var todos := {}
	for c: Club in viejo.participantes:
		todos[c.id] = c
	copia.por_grupos = true
	var d: Dictionary = JSON.parse_string(JSON.stringify(viejo.grupos_a_dic()))
	d.erase("formato")   ## un guardado de antes no traía la clave
	copia.participantes = viejo.participantes.duplicate()
	copia.ronda = viejo.ronda
	copia.fecha = viejo.fecha
	copia.grupos_desde_dic(d, todos)
	_comprobar(copia.formato == FormatosConti.CLASICO and copia.huecos().size() == 6, "un guardado sin «formato» se abre como el torneo de antes")
	Azar.sembrar(62)
	_jugar_hasta_el_final(copia)
	_comprobar(copia.campeon != null and copia.historial.size() == 5, "y sigue su curso hasta el campeón (grupos de 3 fechas + cuartos, semis y final)")
	## Un guardado NUEVO a mitad de la fase de liga conserva sorteo, tabla y ida de la ronda.
	Azar.sembrar(63)
	var nuevo := Continental.crear("uel")
	var cl36 := _clubes_de_prueba(36, "N", "ENG")
	nuevo.preparar(cl36)
	for i in 3:
		nuevo.jugar_ronda()
	var ids := {}
	for c: Club in cl36:
		ids[c.id] = c
	var otro := Continental.crear("uel")
	otro.por_grupos = true
	otro.participantes = nuevo.participantes.duplicate()
	otro.ronda = nuevo.ronda
	otro.fecha = nuevo.fecha
	otro.grupos_desde_dic(JSON.parse_string(JSON.stringify(nuevo.grupos_a_dic())), ids)
	_comprobar(JSON.stringify(otro.grupos_a_dic()) == JSON.stringify(nuevo.grupos_a_dic()), "guardar y abrir una fase de liga a medias da lo mismo")
	_comprobar(otro.nombre_de_ronda() == nuevo.nombre_de_ronda() and otro.en_fase_de_grupos(), "y sigue en la misma fecha (%s)" % otro.nombre_de_ronda())
	var a := nuevo.jugar_ronda()
	Azar.sembrar(63)
	_comprobar(a.size() == 18, "una fecha de 36 clubes tiene 18 partidos (%d)" % a.size())

func _probar_continentales_temporada_europea() -> void:
	_titulo("CONTINENTALES · UNA TEMPORADA ENTERA CON EUROPA (3 países distintos)")
	var europa: Array[String] = ["ESP", "ENG", "ITA", "GER", "FRA", "POR", "NED", "BEL", "CRO", "DEN"]
	for caso: Array in [["ITA", 71], ["POR", 72]]:
		var m := Mundo.new()
		m.generar(europa, int(caso[1]))
		var mio_pais := String(caso[0])
		var elegido: Club = null
		for c: Club in m.clubes.values():
			if c.pais == mio_pais and c.division == 1 and (elegido == null or c.rep > elegido.rep):
				elegido = c
		m.tomar_el_mando(elegido.id)
		var ucl: Continental = m.continentales.get("ucl")
		var uel: Continental = m.continentales.get("uel")
		var uecl: Continental = m.continentales.get("uecl")
		_comprobar(ucl != null and uel != null and uecl != null, "%s: se sortean las tres copas europeas" % mio_pais)
		_comprobar(ucl.participantes.size() == 36 and uel.participantes.size() == 36 and uecl.participantes.size() == 36, "%s: de 36 clubes cada una (%d, %d, %d)" % [mio_pais, ucl.participantes.size(), uel.participantes.size(), uecl.participantes.size()])
		var repetidos := 0
		var visto := {}
		for t: Continental in [ucl, uel, uecl]:
			for c: Club in t.participantes:
				if visto.has(c.id):
					repetidos += 1
				visto[c.id] = true
		_comprobar(repetidos == 0, "%s: ningún club juega dos copas europeas (%d repetidos)" % [mio_pais, repetidos])
		var mi_torneo := m.mi_continental()
		var mis_partidos := 0
		var semana_campeon := {}
		for sem in 34:
			if mi_torneo != null and not m.partido_continental().is_empty():
				mis_partidos += 1
			m.avanzar_semana()
			for k in ["ucl", "uel", "uecl"]:
				var t2: Continental = m.continentales[k]
				if t2.campeon != null and not semana_campeon.has(k):
					semana_campeon[k] = m.semana - 1
		_linea("  %s con %s: %d partidos continentales míos; campeones en %s" % [mio_pais, mi_torneo.nombre if mi_torneo else "-", mis_partidos, str(semana_campeon)])
		if mi_torneo != null:
			var jugados_mios := 0
			for h: Dictionary in mi_torneo.historial:
				for r: Dictionary in h["resultados"]:
					if r["local"] == elegido or r["visita"] == elegido:
						jugados_mios += 1
			_comprobar(jugados_mios == mis_partidos, "%s: los partidos que la agenda me ofrece (%d) son los que el torneo anota de mi club (%d)" % [mio_pais, mis_partidos, jugados_mios])
			var puesto := 0
			var tab := mi_torneo.tabla_de_grupo(0)
			for i in tab.size():
				if tab[i]["club"] == elegido:
					puesto = i + 1
			_linea("  puesto en la fase de liga: %d de %d; clasificados %d; esta en clasificados: %s" % [puesto, tab.size(), mi_torneo.clasificados().size(), str(mi_torneo.clasificados().has(elegido))])
		_comprobar(semana_campeon.size() == 3, "%s: las tres copas europeas se deciden jugando semana a semana, sin esperar al cierre (%s)" % [mio_pais, str(semana_campeon)])
		_comprobar(mi_torneo != null and mis_partidos >= 8, "%s: mi club tuvo al menos sus 8 partidos de la primera fase (%d)" % [mio_pais, mis_partidos])

## Cierra a mano los torneos de una confederación para tener campeones.
func _cerrar_torneos(m: Mundo, claves: Array) -> void:
	for k: String in claves:
		var t: Continental = m.continentales.get(k)
		if t != null:
			_jugar_hasta_el_final(t)

func _probar_continentales_supercopas() -> void:
	_titulo("CONTINENTALES · SUPERCOPAS (Europa, Sudamérica, África)")
	var europa: Array[String] = ["ESP", "ENG", "ITA", "GER", "FRA", "POR", "NED", "BEL", "CRO", "DEN"]
	var sur: Array[String] = ["CHI", "ARG", "BRA", "COL", "URU", "PER", "ECU", "PAR"]
	var africa: Array[String] = ["EGY", "MAR", "RSA"]
	var casos := [
		[europa, 81, "Supercopa de Europa", "ucl", "uel", "ITA"],
		[sur, 82, "Recopa Sudamericana", "lib", "sud", "BRA"],
		[africa, 83, "Supercopa CAF", "afr", "afr2", "MAR"],
	]
	for caso: Array in casos:
		var paises: Array[String] = caso[0]
		var m := Mundo.new()
		m.generar(paises, int(caso[1]))
		var mio: Club = null
		for c: Club in m.clubes.values():
			if c.pais == String(caso[5]) and c.division == 1 and (mio == null or c.rep > mio.rep):
				mio = c
		m.tomar_el_mando(mio.id)
		var grande: Continental = m.continentales.get(String(caso[3]))
		var chica: Continental = m.continentales.get(String(caso[4]))
		_comprobar(grande != null and chica != null, "%s: se sortean las dos copas de la confederación (%s y %s)" % [caso[2], caso[3], caso[4]])
		if grande == null or chica == null:
			continue
		_comprobar(SupercopasConti.jugar(m).is_empty(), "%s: sin campeones todavía, no hay supercopa" % caso[2])
		_cerrar_torneos(m, [caso[3], caso[4]])
		var a := grande.campeon
		var b := chica.campeon
		var saldo_a := a.saldo
		var saldo_b := b.saldo
		var jugadas := SupercopasConti.jugar(m)
		_comprobar(jugadas.size() == 1 and jugadas[0]["nombre"] == caso[2], "%s: una supercopa, la de su confederación" % caso[2])
		var j: Dictionary = jugadas[0]
		_comprobar(j["local"] == a and j["visita"] == b, "%s: campeón de la grande contra campeón de la segunda (%s vs %s)" % [caso[2], a.nombre, b.nombre])
		var gana: Club = j["campeon"]
		_comprobar(gana == a or gana == b, "tiene campeón (%s, %d-%d)" % [gana.nombre, int(j["gl"]), int(j["gv"])])
		_comprobar((j["gl"] != j["gv"]) == (j["penales"] as Array).is_empty(), "un empate se decide en los penales")
		var premio := 0
		for fila: Dictionary in SupercopasConti.TABLA:
			if fila["nombre"] == caso[2]:
				premio = int(fila["premio"])
		var cobro := gana.saldo - (saldo_a if gana == a else saldo_b)
		_comprobar(cobro == premio and premio > 0, "el campeón cobra el premio de la supercopa (%d de %d)" % [cobro, premio])
		var en_palmares := m.palmares_mundo.filter(func(t: Dictionary) -> bool: return String(t["torneo"]) == String(caso[2]) and String(t["club"]) == gana.id)
		_comprobar(en_palmares.size() == 1, "queda en el palmarés del mundo")
		_comprobar(TipoTitulo.de(m, String(caso[2])) == "supercopa", "se festeja como una supercopa")
		_linea("  %s: %s %d-%d %s" % [caso[2], a.nombre, int(j["gl"]), int(j["gv"]), b.nombre])

func _probar_continentales_mundial_de_clubes() -> void:
	_titulo("CONTINENTALES · MUNDIAL DE CLUBES DE 32")
	for caso: Array in [["ESP", 91], ["ARG", 92], ["JPN", 93]]:
		Azar.sembrar(int(caso[1]))
		var clubes := _clubes_de_prueba(32, String(caso[0]), String(caso[0]))
		var t := Continental.crear("mundial")
		_comprobar(t is MundialClubes and t.es_fifa(), "%s: la fábrica crea un Mundial de Clubes" % caso[0])
		t.preparar(clubes)
		_comprobar(t.formato == "mundial" and t.grupos.size() == 8 and t.grupos[0].size() == 4, "%s: 8 grupos de 4" % caso[0])
		## Cada grupo recibe un club de cada bombo de reputación (los 8 primeros, los 8 siguientes…).
		var por_rep: Array[Club] = clubes.duplicate()
		por_rep.sort_custom(PlazasConti.mas_reputado)
		var bombos_mal := 0
		for g: Array in t.grupos:
			var bombos := {}
			for c: Club in g:
				bombos[por_rep.find(c) / 8] = true
			if bombos.size() != 4:
				bombos_mal += 1
		_comprobar(bombos_mal == 0, "%s: cada grupo tiene un club de cada bombo (%d mal)" % [caso[0], bombos_mal])
		_comprobar(t.huecos().size() == 7, "%s: 3 fechas de grupo + octavos, cuartos, semifinales y final" % caso[0])
		for i in 3:
			t.jugar_ronda()
		_comprobar(t.vivos.size() == 16 and t.nombre_de_ronda() == "Octavos de final" and t.clasificados().size() == 16, "%s: pasan 16 a octavos (%s)" % [caso[0], t.nombre_de_ronda()])
		var finalistas := 0
		while t.vivos.size() > 2:
			t.jugar_ronda()
		var finalistas_club: Array[Club] = t.vivos.duplicate()
		var saldos := [finalistas_club[0].saldo, finalistas_club[1].saldo]
		t.jugar_ronda()
		finalistas = t.vivos.size()
		_comprobar(t.campeon != null and finalistas == 1, "%s: campeón del mundo: %s" % [caso[0], t.campeon.nombre if t.campeon else "-"])
		_comprobar(t.historial.size() == 7 and t.historial[6]["resultados"][0]["ronda"] == "Final", "%s: 7 rondas y la última es la final a partido único" % caso[0])
		_comprobar(t.premio_de_ronda(8) == 0, "no paga por rondas, solo el 28 % de entrar al cuadro y el premio del campeón")
		var cobro := t.campeon.saldo - int(saldos[finalistas_club.find(t.campeon)])
		_comprobar(cobro == t.premio and t.premio == 1800000, "%s: el campeón del mundo cobra los 1.800.000 (%d)" % [caso[0], cobro])
	## Con menos campeones se achica solo, como el Mundial de Clubes de antes.
	for n in [20, 9, 6, 3]:
		Azar.sembrar(94 + n)
		var t2 := Continental.crear("mundial")
		t2.preparar(_clubes_de_prueba(n, "Q%d_" % n, "CHI"))
		var esperado := "mundial16" if n >= 16 else ("mundial8" if n >= 8 else FormatosConti.BYES)
		_jugar_hasta_el_final(t2)
		_comprobar(t2.formato == esperado and t2.campeon != null, "con %d campeones: formato %s y hay campeón" % [n, t2.formato])
		_comprobar(t2.participantes.size() == (16 if n >= 16 else (8 if n >= 8 else n)), "con %d campeones juegan %d" % [n, t2.participantes.size()])

func _probar_continentales_intercontinental() -> void:
	_titulo("CONTINENTALES · COPA INTERCONTINENTAL")
	for caso: Array in [[95, "JPN"], [96, "EGY"], [97, "MEX"]]:
		Azar.sembrar(int(caso[0]))
		var cinco := _clubes_de_prueba(5, String(caso[1]), String(caso[1]))
		var t := Continental.crear("interc")
		_comprobar(t is CopaIntercontinental and t.es_fifa(), "%s: la fábrica crea la Copa Intercontinental" % caso[1])
		t.preparar(cinco)
		_comprobar(t.huecos().size() == 3 and t.nombre_de_ronda() == "Challenger Cup y Derbi de las Américas", "%s: tres rondas (%s)" % [caso[1], t.nombre_de_ronda()])
		var r1 := t.jugar_ronda()
		_comprobar(r1.size() == 2 and r1[0]["etiqueta"] == "Challenger Cup" and r1[1]["etiqueta"] == "Derbi de las Américas", "%s: Asia-África es la Challenger Cup y las Américas, el Derbi" % caso[1])
		_comprobar(r1[0]["local"] == cinco[0] and r1[0]["visita"] == cinco[1] and r1[1]["local"] == cinco[2] and r1[1]["visita"] == cinco[3], "los cruces salen del orden de los campeones")
		_comprobar(t.vivos.size() == 3 and t.vivos[2] == cinco[4], "el campeón de Europa espera sin jugar")
		var r2 := t.jugar_ronda()
		_comprobar(r2.size() == 1 and t.nombre_de_ronda() == "Final" and t.vivos.has(cinco[4]), "semifinal entre los dos ganadores y final contra Europa")
		var r3 := t.jugar_ronda()
		_comprobar(t.campeon != null and r3[0]["local"] != null and t.historial.size() == 3, "%s: campeón %s" % [caso[1], t.campeon.nombre if t.campeon else "-"])
	## Con menos de cinco campeones continentales también se juega.
	Azar.sembrar(98)
	var tres := Continental.crear("interc")
	tres.preparar(_clubes_de_prueba(3, "T", "AUS"))
	_jugar_hasta_el_final(tres)
	_comprobar(tres.campeon != null, "con tres campeones: hay Copa Intercontinental igual")

func _probar_continentales_fifa_en_la_temporada() -> void:
	_titulo("CONTINENTALES · LOS TORNEOS DE LA FIFA ENTRAN EN EL CALENDARIO")
	var mundo_chico: Array[String] = ["CHI", "ARG", "BRA", "ESP", "ENG", "ITA", "JPN", "MEX", "EGY", "MAR"]
	for caso: Array in [["BRA", 101], ["ENG", 102]]:
		var m := Mundo.new()
		m.generar(mundo_chico, int(caso[1]))
		var mio: Club = null
		for c: Club in m.clubes.values():
			if c.pais == String(caso[0]) and c.division == 1 and (mio == null or c.rep > mio.rep):
				mio = c
		m.tomar_el_mando(mio.id)
		_comprobar(not m.continentales.has("mundial") and not m.continentales.has("interc"), "%s: el primer año no hay torneos de la FIFA (aún no hay campeones)" % caso[0])
		_cerrar_torneos(m, m.continentales.keys())
		var campeones := 0
		for k: String in Continental.PRINCIPALES:
			if m.continentales.has(k) and (m.continentales[k] as Continental).campeon != null:
				campeones += 1
		var previos := m.continentales
		FifaClubes.sumar(m, previos)
		var mundial: Continental = m.continentales.get("mundial")
		_comprobar(mundial != null, "%s: con %d campeones continentales se arma el Mundial de Clubes" % [caso[0], campeones])
		if mundial == null:
			continue
		_linea("  %s: Mundial de Clubes con %d clubes (%s)" % [caso[0], mundial.participantes.size(), mundial.formato])
		_comprobar(mundial.participantes.size() >= 8, "%s: hay al menos 8 clubes (%d)" % [caso[0], mundial.participantes.size()])
		var campeon_ucl: Club = previos["ucl"].campeon if previos.has("ucl") else null
		_comprobar(campeon_ucl == null or mundial.participa(campeon_ucl), "el campeón de Europa está en el Mundial")
		var repetidos := 0
		var vistos := {}
		for c: Club in mundial.participantes:
			if vistos.has(c.id):
				repetidos += 1
			vistos[c.id] = true
		_comprobar(repetidos == 0, "%s: ningún club repetido" % caso[0])
		var interc: Continental = m.continentales.get("interc")
		_comprobar(interc != null and interc.participantes.size() == 5, "%s: y la Copa Intercontinental con los 5 campeones (%d)" % [caso[0], interc.participantes.size() if interc else 0])
		if interc != null:
			_comprobar(interc.participantes[4] == previos["ucl"].campeon and interc.participantes[0] == previos["asia"].campeon, "%s: Europa espera la final y Asia abre el cuadro" % caso[0])
		## Un guardado a mitad del Mundial conserva el torneo y su clase.
		mundial.jugar_ronda()
		var dic := Partida._continentales_a_dic(m.continentales)
		_comprobar(dic.has("mundial") and dic.has("interc") and String(dic["mundial"].get("formato", "")) == mundial.formato, "%s: el guardado trae los dos torneos y su formato" % caso[0])
		var avance := m.semana
		var jugados_fifa := 0
		for sem in 12:
			var antes := mundial.ronda
			m.avanzar_semana()
			if mundial.ronda > antes:
				jugados_fifa += 1
		_comprobar(jugados_fifa >= 3, "%s: el Mundial avanza solo con las semanas del calendario (%d rondas en 12 semanas desde la %d)" % [caso[0], jugados_fifa, avance])
