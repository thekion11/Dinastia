extends "res://pruebas/banco/varios_p7.gd"
## [Capa de `varios_p8.gd`, 21-11 refactor de forma] Secciones de CALENDARIO (C13/C16) y de MARCAS Y
## ESCUDOS (M-059/M-062). El recuento compartido de marcas va en un diccionario; el orden de las
## comprobaciones y los textos son los de antes.


## CALENDARIO, parte 1: las fechas (semana 1, Pascua, Ramadán, días de memoria e independencia).
func _cal_fechas() -> void:
	## Las fechas: el lunes de la semana 1 de 2026 es el 26 de enero.
	var d := Calendario.fecha(2026, 1, 0)
	_comprobar(int(d["month"]) == 1 and int(d["day"]) == 26, "la semana 1 de 2026 empieza el lunes 26 de enero")
	var p := Calendario.pascua(2026)
	_comprobar(int(p[0]) == 4 and int(p[1]) == 5, "Pascua 2026 cae el 5 de abril")
	var p2 := Calendario.pascua(2027)
	_comprobar(int(p2[0]) == 3 and int(p2[1]) == 28, "Pascua 2027 cae el 28 de marzo")
	var ram := Calendario.ramadan(2026)
	_comprobar(ram.size() == 2 and int(ram[0][0]) == 2 and absi(int(ram[0][1]) - 18) <= 1, "el Ramadán 2026 empieza hacia el 18 de febrero")
	## El 11 de septiembre, en Chile y en EE. UU., es de memoria.
	var chi := Calendario.del_anio("CHI", 2026)
	var once_chi := chi.filter(func(f: Dictionary) -> bool: return int(f["mes"]) == 9 and int(f["dia"]) == 11)
	var once_usa := Calendario.del_anio("USA", 2026).filter(func(f: Dictionary) -> bool: return int(f["mes"]) == 9 and int(f["dia"]) == 11)
	_comprobar(once_chi.size() == 1 and String(once_chi[0]["tipo"]) == "memoria" and once_usa.size() == 1 and String(once_usa[0]["tipo"]) == "memoria",
		"el 11 de septiembre es fecha de memoria en Chile y en EE. UU.")
	_comprobar(chi.any(func(f: Dictionary) -> bool: return int(f["mes"]) == 5 and int(f["dia"]) == 1), "el 1 de mayo está en Chile")
	## (17-11) Días de la independencia: los que faltaban se suman con la marca «indep» y se reconocen los de siempre.
	var con_indep := 0
	for pais: String in Calendario.FIJAS.keys():
		con_indep += 1 if Calendario.del_anio(pais, 2026).any(func(f: Dictionary) -> bool: return CalendarioMemorias.es_independencia(f)) else 0
	_comprobar(con_indep >= 75 and CalendarioMemorias.INDEPENDENCIAS.keys().all(func(p2: String) -> bool: return Calendario.del_anio(p2, 2026).any(func(f: Dictionary) -> bool: return f.has("indep"))),
		"%d países con día de independencia y los 11 añadidos están en su calendario" % con_indep)
	var usa := Calendario.del_anio("USA", 2026)
	_comprobar(not usa.any(func(f: Dictionary) -> bool: return int(f["mes"]) == 5 and int(f["dia"]) == 1)
		and usa.any(func(f: Dictionary) -> bool: return String(f["nombre"]) == "Labor Day" and int(f["dia"]) == 7),
		"en EE. UU. no es el 1 de mayo sino el Labor Day (7 de septiembre de 2026)")
	_comprobar(Calendario.del_anio("URU", 2026).any(func(f: Dictionary) -> bool: return String(f["nombre"]) == "Semana de Turismo"), "en Uruguay es la Semana de Turismo")
	_comprobar(Calendario.del_anio("KSA", 2026).any(func(f: Dictionary) -> bool: return String(f["nombre"]).begins_with("Empieza el Ramadán")), "Arabia Saudí tiene el Ramadán en su calendario")


## CALENDARIO, parte 2: en qué semana cae Fiestas Patrias y en cuál el 11 de septiembre. Devuelve las dos.
func _cal_semanas() -> Array:
	## Buscar la semana del 18 de septiembre en Chile (fiesta) y la del 11 (memoria).
	var sem_fiesta := -1
	var sem_memoria := -1
	for s in range(1, 50):
		for f: Dictionary in Calendario.de_la_semana("CHI", 2026, s):
			if String(f["nombre"]) == "Fiestas Patrias":
				sem_fiesta = s
			if String(f["nombre"]) == "Conmemoración del golpe de Estado":
				sem_memoria = s
	_comprobar(sem_fiesta > 0 and sem_memoria > 0 and sem_fiesta != sem_memoria, "Fiestas Patrias y el 11 caen en semanas distintas (%d y %d)" % [sem_fiesta, sem_memoria])
	_comprobar(Calendario.factor_publico("CHI", 2026, sem_fiesta) > 1.0, "la semana de Fiestas Patrias llena más el estadio")
	_comprobar(is_equal_approx(Calendario.factor_publico("CHI", 2026, sem_memoria), 1.0) and Calendario.hay_memoria("CHI", 2026, sem_memoria), "la del 11 de septiembre no tiene bonus de fiesta")
	return [sem_fiesta, sem_memoria]


## CALENDARIO, parte 3: los torneos y, en el mundo, la noticia de la memoria y el mentor que la explica una vez.
func _cal_mundo(sem_fiesta: int, sem_memoria: int) -> void:
	## Los torneos.
	_comprobar(Calendario.torneos(2026).any(func(t: Dictionary) -> bool: return String(t["nombre"]) == "Copa del Mundo"), "2026 es año de Mundial")
	_comprobar(not Calendario.torneos(2027).any(func(t: Dictionary) -> bool: return String(t["nombre"]) == "Copa del Mundo"), "2027 no")
	## En el mundo: la semana de memoria da noticia y el mentor la explica una vez.
	var m := Mundo.new()
	m.generar(["CHI"], 5151)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	var noticias: Array = []
	var mentor: Array = []
	m.calendario.noticia.connect(func(t: String, _b: String) -> void: noticias.append(t))
	m.calendario.mentor.connect(func(t: String, _b: String) -> void: mentor.append(t))
	var moral0 := c.plantilla[0].moral
	m.calendario.semana(c, 2026, sem_memoria)
	_comprobar(noticias.any(func(t: String) -> bool: return t.contains("Conmemoración del golpe de Estado")) and mentor.has("Conmemoración del golpe de Estado"), "el 11 sale en las noticias y el mentor lo explica")
	_comprobar(c.plantilla[0].moral == moral0, "la memoria no sube la moral como una fiesta")
	m.calendario.semana(c, 2026, sem_fiesta)
	_comprobar(c.plantilla[0].moral == mini(moral0 + 1, 99), "la semana de fiesta sube la moral")
	var m2 := mentor.size()
	m.calendario.ultima_semana = -1
	m.calendario.semana(c, 2027, sem_fiesta + 1 if Calendario.de_la_semana("CHI", 2027, sem_fiesta).is_empty() else sem_fiesta)
	_comprobar(not mentor.slice(m2).has("Fiestas Patrias"), "el mentor no repite la explicación al año siguiente")
	var dic := m.calendario.a_dic()
	var cal2 := Calendario.new()
	cal2.desde_dic(dic)
	_comprobar(cal2.explicadas.has("Conmemoración del golpe de Estado"), "se guarda lo que el mentor ya explicó")
	_comprobar(Calendario.proximas("CHI", 2026, 1, 5).size() == 5, "hay próximas fechas para el calendario")


## MARCAS, parte 1: el mundo grande y el recuento de patrocinios, escudos y uniformes repetidos.
## Devuelve el diccionario compartido por las demás secciones.
func _mk_recuento() -> Dictionary:
	var m := Mundo.new()
	var paises: Array[String] = []
	for pais: String in (Datos.tabla("PAISES_LIGAS") as Dictionary):
		paises.append(pais)
	m.generar(paises, 5962)
	var cuenta := {}
	var zonas := 0
	var firmas := {}
	var repetidos: Array = []
	var kits_liga := {}   ## liga|diseño|colores|pantalón|medias
	var kits_repetidos: Array = []
	var kits_mundo := {}
	for c: Club in m.clubes.values():
		var sp := SponsorKit.de_club(c)
		for z: String in sp:
			var marca := String((sp[z] as Dictionary).get("marca", ""))
			cuenta[marca] = int(cuenta.get(marca, 0)) + 1
			zonas += 1
		var firma := "%s|%s|%s|%s|%s|%s" % [Escudo.forma_de(c), Escudo.patron_de(c), c.color1.to_lower(), c.color2.to_lower(),
			Escudo.simbolo_de(c), Escudo.iniciales(c) if Escudo.simbolo_de(c) == "" else ""]
		if firmas.has(firma):
			repetidos.append("%s = %s" % [c.nombre, firmas[firma]])
		firmas[firma] = c.nombre
		var kd: Dictionary = DisenosKit.kit_de_club(c)
		var kf := "%s|%s|%s|%s|%s|%s" % [c.pais + str(c.division), kd["dis"], String((kd["cols"] as Array)[0]).to_lower(), String((kd["cols"] as Array)[1]).to_lower(),
			String(kd["pant"]["c1"]).to_lower(), String(kd["med"]["c1"]).to_lower()]
		if kits_liga.has(kf):
			kits_repetidos.append("%s = %s" % [c.nombre, kits_liga[kf]])
		kits_liga[kf] = c.nombre
		kits_mundo[kf.substr(kf.find("|") + 1)] = true
	var media := float(zonas) / float(maxi(1, Auspicio.marcas().size()))
	var peor := ""
	for k: String in cuenta:
		if peor == "" or int(cuenta[k]) > int(cuenta[peor]):
			peor = k
	return {"m": m, "cuenta": cuenta, "zonas": zonas, "media": media, "peor": peor,
		"repetidos": repetidos, "kits_repetidos": kits_repetidos, "kits_mundo": kits_mundo}


## MARCAS, parte 2: el resumen, los 25 de cada plantilla, la marca que más se repite y las canas.
func _mk_marcas_canas(st: Dictionary) -> void:
	var m: Mundo = st["m"]
	var cuenta: Dictionary = st["cuenta"]
	var zonas: int = st["zonas"]
	var media: float = st["media"]
	var peor: String = st["peor"]
	_linea("  %d clubes, %d zonas patrocinadas, %d marcas; media %.1f, la que más: %s ×%d" % [m.clubes.size(), zonas, cuenta.size(), media, peor, int(cuenta.get(peor, 0))])
	_comprobar(m.clubes.size() > 300, "un mundo grande (%d clubes)" % m.clubes.size())
	var sin25: Array[String] = []
	for c2: Club in m.clubes.values():
		if c2.plantilla.size() != 25:
			sin25.append("%s (%d)" % [c2.nombre, c2.plantilla.size()])
	_comprobar(sin25.is_empty(), "M-207: todos los clubes del mundo tienen plantilla de 25 (fallan %d: %s)" % [sin25.size(), ", ".join(sin25.slice(0, 5))])
	_comprobar(float(cuenta.get(peor, 0)) <= 2.0 * media, "M-059: ninguna marca pasa del doble de la media (%s ×%d, media %.1f)" % [peor, int(cuenta.get(peor, 0)), media])
	## M-085: canas con la edad en los inventados.
	var jv: Jugador = null
	for c: Club in m.clubes.values():
		for j: Jugador in c.plantilla:
			if not j.real and jv == null:
				jv = j
	var edad0 := jv.edad
	jv.edad = 24
	var joven := Color(String(Cara.look_de(jv).get("peloC", "#000000")))
	jv.edad = 39
	var viejo := Color(String(Cara.look_de(jv).get("peloC", "#000000")))
	jv.edad = edad0
	_comprobar(viejo.s < joven.s, "M-085: a los 39 el pelo tiene canas (%s → %s)" % [joven.to_html(false), viejo.to_html(false)])


## MARCAS, parte 3: escudos y uniformes sin repetir (dentro de una liga) y la variedad global.
func _mk_escudos_kits(st: Dictionary) -> void:
	var m: Mundo = st["m"]
	var repetidos: Array = st["repetidos"]
	var kits_repetidos: Array = st["kits_repetidos"]
	var kits_mundo: Dictionary = st["kits_mundo"]
	_comprobar(repetidos.is_empty(), "M-062: ningún escudo repetido entre clubes (%d: %s)" % [repetidos.size(), str(repetidos.slice(0, 5))])
	_linea("  uniformes: %d combinaciones distintas en %d clubes (misma combinación en dos ligas distintas es válida)" % [kits_mundo.size(), m.clubes.size()])
	_comprobar(kits_repetidos.is_empty(), "M-062b: ningún uniforme repetido dentro de una misma liga (%d: %s)" % [kits_repetidos.size(), str(kits_repetidos.slice(0, 5))])
	_comprobar(kits_mundo.size() >= 550, "M-062b: variedad global de uniformes (%d combinaciones distintas, mínimo 550)" % kits_mundo.size())


## MARCAS, parte 4: el escudo monocromo (solo tinta y blanco) y los datos de escudos y camisetas.
func _mk_textura_datos(m: Mundo) -> void:
	## M-066 (25-10): el escudo monocromo solo tiene la tinta, blanco y transparencia.
	var tm := Escudo.textura_mono(m.clubes.values()[0] as Club, 26)
	var im: Image = tm.get_image() if tm != null else null
	var extras := 0
	for yy in range(0, im.get_height() if im != null else 0, 3):
		for xx in range(0, im.get_width(), 3):
			var pm := im.get_pixel(xx, yy)
			extras += 1 if pm.a > 0.0 and pm.r != pm.g and not (pm.r == pm.b) else 0
			extras += 1 if pm.a > 0.0 and pm.r > 0.01 and pm.r < 0.99 else 0
	_comprobar(im != null and extras == 0, "M-066: Escudo.textura_mono solo usa tinta y blanco (%d píxeles de otro color)" % extras)
	## M-063/M-068 (25-10): más clubes con escudo y camiseta de rasgo propio en la tabla.
	var con_esc := 0
	var con_cam := 0
	for fila: Variant in (Datos.tabla("ESTADIO_CLUB") as Dictionary).values():
		con_esc += 1 if (fila as Dictionary).has("escudo") else 0
		con_cam += 1 if (fila as Dictionary).has("camiseta") else 0
	_comprobar(con_esc >= 46 and con_cam >= 98,   ## (10-11) 98: Fortaleza (BRA) descendió y salió de la liga con su camiseta
			"M-063/M-068: %d escudos y %d camisetas con rasgo del club real" % [con_esc, con_cam])


## MARCAS, parte 5: los fabricantes de la camiseta y las formas de estadio según el tamaño.
func _mk_fabricantes_formas() -> void:
	## Los fabricantes en la camiseta 3D (21-10-2026, M-057).
	var mf := Mundo.new()
	mf.generar(["CHI"], 4711)
	var vistos := {}
	for c: Club in mf.ligas[0].clubes:
		var marca := DisenosKit.marca_de(c)
		if not vistos.has(marca):
			_comprobar(DisenosKit.MARCA_FORMA.has(marca) and marca != "propia", "fabricante de %s: %s (conocido, no la marca propia)" % [c.nombre, marca])
		vistos[marca] = true
	_comprobar(vistos.size() >= 4, "los clubes de una liga visten de %d fabricantes distintos" % vistos.size())
	var rep1_a = DisenosKit.marca_de(mf.ligas[0].clubes[0])
	var rep1_b = DisenosKit.marca_de(mf.ligas[0].clubes[0])
	_comprobar(rep1_a == rep1_b, "el fabricante de un club es fijo")
	## Las formas de estadio de los clubes según su tamaño (21-10-2026, M-002).
	var mf2 := Mundo.new()
	mf2.generar(["CHI", "ESP", "ARG", "ENG", "GER", "ITA"], 31)
	var formas := {}
	var chicos_mal := 0
	for c: Club in mf2.clubes.values():
		var fo := String(c.perfil_estadio()["forma"])
		formas[fo] = true
		if c.estadio_aforo < 10000 and fo in ["oval", "caldera"]:
			chicos_mal += 1
	_comprobar(formas.size() >= 8, "los clubes usan %d formas de estadio %s" % [formas.size(), str(formas.keys())])
	_comprobar(chicos_mal == 0, "ningún club de menos de 10.000 butacas tiene un ovalado o una caldera")
	for fo: String in ["estrecho", "asimetrico"]:
		_comprobar(StadiumBuilder.geom_de_forma(fo)["dz"] != StadiumBuilder.geom_de_forma("cuenco")["dz"], "la forma «%s» tiene su geometría" % fo)


## CANTERA, parte 1: toda la plantilla es de Euskal Herria por origen, y los vascos son una parte de los españoles.
func _cn_plantilla_vasca(m: Mundo, bilbao: Club) -> void:
	var todos_vascos := true
	for j: Jugador in bilbao.plantilla:
		todos_vascos = todos_vascos and j.region == "EUS"
	## Nacido o formado allí, aunque juegue con otra selección: cuenta la
	## región, no la nacionalidad.
	_comprobar(todos_vascos, "toda la plantilla es de Euskal Herria (por origen, no por pasaporte)")
	var espanoles := 0
	var vascos := 0
	for c: Club in m.clubes.values():
		if c == bilbao:
			continue
		for j: Jugador in c.plantilla:
			if j.pais == "ESP":
				espanoles += 1
				if j.region == "EUS":
					vascos += 1
	var pct := 100.0 * float(vascos) / float(maxi(1, espanoles))
	_comprobar(pct > 3.0 and pct < 18.0, "los vascos son una parte de los españoles, no todos (%.1f %%)" % pct)
	var apellido_vasco := false
	for j: Jugador in bilbao.plantilla:
		for ap: String in Regiones.APELLIDOS_EUS:
			if j.nombre.ends_with(ap):
				apellido_vasco = true
	_comprobar(apellido_vasco, "apellidos vascos en el Athletic")


## CANTERA, parte 2: el mercado (un español no vasco no entra, uno vasco sí) y el guardado de la región.
func _cn_mercado_guardado(m: Mundo, bilbao: Club, otro: Club) -> void:
	## El mercado: un español no vasco no entra; uno vasco sí.
	var no_vasco: Jugador = null
	var vasco: Jugador = null
	for j: Jugador in otro.plantilla:
		if j.region == "" and no_vasco == null:
			no_vasco = j
	for c: Club in m.clubes.values():
		if c != bilbao:
			for j: Jugador in c.plantilla:
				if j.region == "EUS" and vasco == null:
					vasco = j
	_comprobar(not Regiones.admite(bilbao, no_vasco), "el Athletic no puede fichar a un no vasco")
	_comprobar(vasco == null or Regiones.admite(bilbao, vasco), "sí a uno de Euskal Herria")
	m.tomar_el_mando(bilbao.id)
	var motivo := m.mercado.abrir_negociacion(no_vasco)
	_comprobar(String(motivo).to_lower().contains("euskal herria"), "si diriges al Athletic, la regla vale para ti: «%s»" % motivo)
	## Guardado.
	var d := Partida._jugador_a_dic(bilbao.plantilla[0])
	_comprobar(Partida._dic_a_jugador(d).region == "EUS", "la región se guarda con la partida")
