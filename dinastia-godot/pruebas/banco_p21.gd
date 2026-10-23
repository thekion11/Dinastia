extends "res://pruebas/banco_p20.gd"
## (Parte 21 de 25 de `banco.gd`.)

func _probar_calendario_c13() -> void:
	_titulo("C13/C16: CALENDARIO, DÍAS NACIONALES, MEMORIA Y FESTIVIDADES")
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
	var usa := Calendario.del_anio("USA", 2026)
	_comprobar(not usa.any(func(f: Dictionary) -> bool: return int(f["mes"]) == 5 and int(f["dia"]) == 1)
		and usa.any(func(f: Dictionary) -> bool: return String(f["nombre"]) == "Labor Day" and int(f["dia"]) == 7),
		"en EE. UU. no es el 1 de mayo sino el Labor Day (7 de septiembre de 2026)")
	_comprobar(Calendario.del_anio("URU", 2026).any(func(f: Dictionary) -> bool: return String(f["nombre"]) == "Semana de Turismo"), "en Uruguay es la Semana de Turismo")
	_comprobar(Calendario.del_anio("KSA", 2026).any(func(f: Dictionary) -> bool: return String(f["nombre"]).begins_with("Empieza el Ramadán")), "Arabia Saudí tiene el Ramadán en su calendario")
	## Buscar la semana del 18 de septiembre en Chile (fiesta) y la del 11 (memoria).
	var sem_fiesta := -1
	var sem_memoria := -1
	for s in range(1, 50):
		for f: Dictionary in Calendario.de_la_semana("CHI", 2026, s):
			if String(f["nombre"]) == "Fiestas Patrias":
				sem_fiesta = s
			if String(f["nombre"]) == "11 de septiembre":
				sem_memoria = s
	_comprobar(sem_fiesta > 0 and sem_memoria > 0 and sem_fiesta != sem_memoria, "Fiestas Patrias y el 11 caen en semanas distintas (%d y %d)" % [sem_fiesta, sem_memoria])
	_comprobar(Calendario.factor_publico("CHI", 2026, sem_fiesta) > 1.0, "la semana de Fiestas Patrias llena más el estadio")
	_comprobar(Calendario.factor_publico("CHI", 2026, sem_memoria) == 1.0 and Calendario.hay_memoria("CHI", 2026, sem_memoria), "la del 11 de septiembre no tiene bonus de fiesta")
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
	_comprobar(noticias.any(func(t: String) -> bool: return t.contains("11 de septiembre")) and mentor.has("11 de septiembre"), "el 11 sale en las noticias y el mentor lo explica")
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
	_comprobar(cal2.explicadas.has("11 de septiembre"), "se guarda lo que el mentor ya explicó")
	_comprobar(Calendario.proximas("CHI", 2026, 1, 5).size() == 5, "hay próximas fechas para el calendario")
## M-237 (20-10): sin capitán, el vestuario vota la cinta.
func _probar_capitan_votado() -> void:
	_titulo("M-237: EL VESTUARIO VOTA AL CAPITÁN")
	var m := Mundo.new()
	m.generar(["CHI"], 3737)
	var c: Club = m.ligas[0].clubes[0]
	m.tomar_el_mando(c.id)
	for j: Jugador in c.plantilla:
		j.capitan = false
	var noticias: Array = []
	m.vestuario.noticia.connect(func(t: String, b: String) -> void: noticias.append([t, b]))
	var v := m.vestuario.votar_capitan(c)
	var g: Jugador = v.get("ganador")
	var suma := 0
	for n: int in (v["votos"] as Dictionary).values():
		suma += n
	_comprobar(g != null and suma == c.plantilla.size(), "votan todos (%d votos) y sale un ganador" % suma)
	var mas_jovenes := 0
	for j: Jugador in c.plantilla:
		if j.edad < g.edad:
			mas_jovenes += 1
	_comprobar(mas_jovenes * 2 >= c.plantilla.size(), "gana alguien con peso: %s, %d años (mayor que la mitad del plantel)" % [g.nombre, g.edad])
	m.vestuario.semana(1)
	var capitanes := c.plantilla.filter(func(j: Jugador) -> bool: return j.capitan)
	_comprobar(capitanes.size() == 1, "tras la semana hay exactamente un capitán")
	_comprobar(noticias.any(func(x: Array) -> bool: return String(x[0]).contains("capitán")), "y sale la noticia de la votación")
	m.vestuario.semana(2)
	_comprobar(c.plantilla.filter(func(j: Jugador) -> bool: return j.capitan).size() == 1, "con capitán ya no se vuelve a votar")

## M-335 (20-10): la letra del juego tiene TODOS los caracteres que usan las
## traducciones (ą ł ż del polaco, ğ ş ı İ del turco, ç à del catalán...). Una
## letra que falta sale como un cuadrado vacío.
## M-331 (20-10): con las bolsas de nombres por país, un mundo no se llena de
## tocayos. Se mide cuántos nombres completos se repiten en tres ligas.
## M-059 y M-062 (20-10): en un mundo grande, ninguna marca de patrocinio sale
## más del doble de la media, y los escudos (forma + dibujo + colores + iniciales
## o símbolo) no se repiten entre clubes.
## M-175 (20-10): de noche los coches llevan faros y se avivan al frenar.
func _probar_piel_por_pais() -> void:
	_titulo("PIEL Y PELO SEGÚN EL PAÍS (jugadores inventados)")
	var medias := {}
	var rubios := {}
	for pais: String in ["GER", "BRA", "JPN", "RSA"]:
		var suma := 0.0
		var rub := 0
		for k in 400:
			var j := Jugador.new()
			j.id = "pp_%s_%d" % [pais, k]
			j.pais = pais
			j.edad = 24
			var l := Cara.look_de(j)
			suma += float(Cara.PIELES.find(String(l["piel"])))
			if String(l["peloC"]) in ["#c8a05a", "#8a6a3a"]:
				rub += 1
		medias[pais] = suma / 400.0
		rubios[pais] = rub
	_comprobar(float(medias["GER"]) < float(medias["BRA"]) and float(medias["BRA"]) < float(medias["RSA"]), "la piel sigue el país: GER %.1f < BRA %.1f < RSA %.1f (índice de tono)" % [medias["GER"], medias["BRA"], medias["RSA"]])
	_comprobar(int(rubios["GER"]) > 40 and int(rubios["JPN"]) == 0, "rubios: %d de 400 en GER, %d en JPN" % [rubios["GER"], rubios["JPN"]])
	_comprobar(float(medias["BRA"]) > 1.5 and float(medias["BRA"]) < 6.0, "y dentro de un país hay variedad (BRA de media %.1f)" % medias["BRA"])

func _probar_modulos() -> void:
	_titulo("PIEZAS MODULARES: RECICLAR, UNIR, SEPARAR Y GUARDAR")
	_comprobar(Modulos.listar("muebles").size() >= 100, "el kit de muebles tiene %d piezas en el catálogo común" % Modulos.listar("muebles").size())
	_comprobar(Modulos.listar("suburbano").has("suburbano/tree-large"), "las piezas de otros kits llevan el kit delante")
	var silla := Modulos.tomar("chairDesk")
	_comprobar(silla.has_meta("pieza") and silla.get_child(0).get_child_count() > 0, "una pieza sale con sus mallas")
	_comprobar(absf((silla.get_meta("escala") as Vector3).x - 2.0) < 0.01, "los muebles salen a medidas reales (×2)")
	Modulos.vaciar_reserva()
	Modulos.devolver(silla)
	_comprobar(Modulos.en_reserva("chairDesk") == 0, "una pieza teñida (silla de despacho) se guarda en su propio montón")
	var mesa := Modulos.tomar("desk")
	Modulos.devolver(mesa)
	_comprobar(Modulos.en_reserva("desk") == 1, "devuelta, la mesa espera en la reserva")
	var otra := Modulos.tomar("desk")
	_comprobar(otra == mesa and otra.visible and Modulos.en_reserva("desk") == 0, "y la siguiente que se pide es la misma, reciclada")
	var raiz := Node3D.new()
	add_child(raiz)
	raiz.add_child(otra)
	otra.position = Vector3(2, 0, 3)
	var lampara := Modulos.tomar("lampRoundFloor")
	raiz.add_child(lampara)
	lampara.position = Vector3(3, 0, 3)
	lampara.rotation.y = 1.0
	var c := Modulos.unir([otra, lampara], "Rincon")
	_comprobar(c.get_parent() == raiz and c.get_child_count() == 2, "unir: la mesa y la lámpara forman un conjunto")
	_comprobar(lampara.global_position.distance_to(Vector3(3, 0, 3)) < 0.01, "unir no mueve las piezas de su sitio (%s)" % str(lampara.global_position))
	var datos := Modulos.a_datos(c)
	_comprobar(datos.size() == 2 and String(datos[1]["pieza"]) == "lampRoundFloor", "el conjunto se guarda como datos")
	c.position += Vector3(10, 0, 0)
	var sueltas := Modulos.separar(c)
	_comprobar(sueltas.size() == 2 and sueltas[1].get_parent() == raiz and sueltas[1].global_position.distance_to(Vector3(13, 0, 3)) < 0.01, "separar: las piezas quedan sueltas donde estaban (movidas con el conjunto)")
	var copia := Modulos.de_datos(JSON.parse_string(JSON.stringify(datos)))
	_comprobar(copia.get_child_count() == 2 and absf((copia.get_child(1) as Node3D).rotation.y - 1.0) < 0.01, "y se rearma igual desde los datos guardados")
	var deco := EdificioClub.datos_deco("tele")
	_comprobar(deco.size() == 2 and float((deco[1]["p"] as Array)[1]) > 0.3, "la tele de la decoración va ENCIMA de su mueble")
	for k: String in EdificioClub.DECO_MODULAR:
		for d: Array in EdificioClub.DECO_MODULAR[k]:
			_comprobar(Modulos.existe(String(d[0])), "la pieza %s de «%s» existe" % [d[0], k])
	copia.free()
	raiz.free()
	Modulos.vaciar_reserva()

func _probar_faros_coches() -> void:
	_titulo("M-175: FAROS Y LUCES DE FRENO")
	var t := TraficoCiudad.new()
	add_child(t)
	var ruta := t.agregar_ruta(PackedVector3Array([Vector3(0, 0, 0), Vector3(0, 0, 100), Vector3(50, 0, 100)]))
	var coche := Node3D.new()
	var caja := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.8, 1.4, 4.3)
	caja.mesh = bm
	caja.position.y = 0.7
	coche.add_child(caja)
	t.agregar_vehiculo(coche, ruta, 10.0, 12.0, 0.0, 0.0)
	t.faros(0.0)
	_comprobar(coche.get_node_or_null("Faros") == null, "de día no se crean faros")
	t.faros(0.9)
	var f := coche.get_node_or_null("Faros") as MeshInstance3D
	_comprobar(f != null and f.mesh != null and f.mesh.get_faces().size() == 24, "de noche cada coche lleva 4 luces en una sola malla")
	_comprobar(f != null and f.get_aabb().end.z > 2.1 and f.get_aabb().position.z < -2.1, "delante y detrás del coche (%s)" % (str(f.get_aabb()) if f != null else "-"))
	_comprobar(t._mat_faros != null and is_equal_approx(float(t._mat_faros.get_shader_parameter("noche")), 0.9), "el brillo sigue a la noche")
	## M-183: de madrugada hay menos gente por la calle.
	var gente: Array[Node3D] = []
	for k in 40:
		var pe := Node3D.new()
		t.agregar_vehiculo(pe, ruta, float(k) * 2.0, 1.4, 0.1, 0.0)
		gente.append(pe)
	t.faros(0.0)
	var de_dia := gente.filter(func(x: Node3D) -> bool: return x.visible).size()
	t.faros(1.0)
	var de_noche := gente.filter(func(x: Node3D) -> bool: return x.visible).size()
	_comprobar(de_dia == 40 and de_noche >= 8 and de_noche <= 20, "M-183: de día 40 por la calle, de madrugada %d" % de_noche)
	t.free()

func _probar_marcas_y_escudos() -> void:
	_titulo("M-059/M-062: MARCAS Y ESCUDOS EN TODO EL MUNDO")
	var m := Mundo.new()
	var paises: Array[String] = []
	for pais: String in (Datos.tabla("PAISES_LIGAS") as Dictionary):
		paises.append(pais)
	m.generar(paises, 5962)
	var cuenta := {}
	var zonas := 0
	var firmas := {}
	var repetidos: Array = []
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
	var media := float(zonas) / float(maxi(1, Auspicio.marcas().size()))
	var peor := ""
	for k: String in cuenta:
		if peor == "" or int(cuenta[k]) > int(cuenta[peor]):
			peor = k
	_linea("  %d clubes, %d zonas patrocinadas, %d marcas; media %.1f, la que más: %s ×%d" % [m.clubes.size(), zonas, cuenta.size(), media, peor, int(cuenta.get(peor, 0))])
	_comprobar(m.clubes.size() > 300, "un mundo grande (%d clubes)" % m.clubes.size())
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
	_comprobar(repetidos.is_empty(), "M-062: ningún escudo repetido entre clubes (%d: %s)" % [repetidos.size(), str(repetidos.slice(0, 5))])
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
	_comprobar(DisenosKit.marca_de(mf.ligas[0].clubes[0]) == DisenosKit.marca_de(mf.ligas[0].clubes[0]), "el fabricante de un club es fijo")
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

func _probar_nombres_repetidos() -> void:
	_titulo("M-331: NOMBRES REPETIDOS EN UN MUNDO")
	var m := Mundo.new()
	m.generar(["CHI", "ESP", "BRA"], 331)
	var vistos := {}
	var total := 0
	for l in m.ligas:
		for c: Club in l.clubes:
			for j: Jugador in c.plantilla:
				total += 1
				vistos[j.nombre] = int(vistos.get(j.nombre, 0)) + 1
	var rep := 0
	var peor := ""
	for k: String in vistos:
		rep += maxi(0, int(vistos[k]) - 1)
		if peor == "" or int(vistos[k]) > int(vistos[peor]):
			peor = k
	var pct := 100.0 * float(rep) / float(maxi(total, 1))
	_linea("  %d jugadores, %d nombres repetidos (%.1f %%); el más repetido: %s ×%d" % [total, rep, pct, peor, int(vistos.get(peor, 0))])
	_comprobar(total > 500, "hay mundo que medir (%d jugadores)" % total)
	_comprobar(pct < 3.0, "menos de un 3 %% de tocayos (%.1f %%)" % pct)
	_comprobar(int(vistos.get(peor, 0)) <= 3, "nadie se llama igual que otros tres")

func _probar_glifos_idiomas() -> void:
	_titulo("M-335: GLIFOS DE LOS 9 IDIOMAS")
	var fuente: Font = ThemeDB.fallback_font
	var vistos := {}
	for idi: String in Idiomas.ORDEN:
		for v: Variant in (Idiomas._extra.get(idi, {}) as Dictionary).values():
			for ch in String(v):
				vistos[ch] = idi
	var faltan: Array = []
	for ch: String in vistos:
		var cp := ch.unicode_at(0)
		## Emojis y símbolos gráficos los pone la fuente de emojis del sistema.
		if cp >= 0x2190 or cp < 0x20 or (cp >= 0x200B and cp <= 0x200F):
			continue
		if not fuente.has_char(cp):
			faltan.append("%s (%s)" % [ch, vistos[ch]])
	_comprobar(vistos.size() > 100, "caracteres distintos en las traducciones: %d" % vistos.size())
	_comprobar(faltan.is_empty(), "la letra los tiene todos (faltan: %s)" % str(faltan.slice(0, 12)))

func _listar_gd(dir: String, out: Array) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for sub in d.get_directories():
		_listar_gd(dir + "/" + sub, out)

func _probar_palabras_prohibidas() -> void:
	_titulo("M-240: SIN POLÍTICA NI RELIGIÓN REAL EN LOS TEXTOS")
	var re_pol := RegEx.create_from_string("(?i)\\b(" + PROHIBIDAS_POLITICA + ")\\b")
	var re_rel := RegEx.create_from_string("(?i)(?<![\\wáéíóúñ])(" + PROHIBIDAS_RELIGION + ")(?![\\wáéíóúñ])")
	var archivos: Array = []
	for dir in ["res://nucleo", "res://ui", "res://visor"]:
		_listar_gd(dir, archivos)
	archivos.append_array(["res://datos/narracion.json", "res://datos/idiomas_extra.json"])
	var malos: Array = []
	for f: String in archivos:
		if f.ends_with("calendario.gd"):
			continue
		var txt := FileAccess.get_file_as_string(f)
		for r: RegEx in [re_pol, re_rel]:
			var m := r.search(txt)
			if m != null:
				malos.append("%s: %s" % [f.get_file(), m.get_string()])
	_comprobar(re_rel.search("un delantero Católico") != null and re_pol.search("votó a Trump") != null
		and re_rel.search("catolicismo") == null, "el detector caza lo prohibido (y no palabras parecidas)")
	_comprobar(archivos.size() > 100, "se revisan los textos de todo el juego (%d archivos)" % archivos.size())
	_comprobar(malos.is_empty(), "ningún político, partido ni religión real (%s)" % str(malos))

func _probar_politica_c15() -> void:
	_titulo("C15: POLÍTICA Y ESTADO (FICTICIA Y NEUTRAL)")
	_comprobar(Politica.ESTRUCTURA.size() == 24, "los 24 países tienen su estructura de Estado")
	_comprobar(Politica.sistema("CHI") == "presidencial" and Politica.mandato("CHI") == 4, "Chile: presidencial, cada 4 años")
	_comprobar(Politica.sistema("ESP") == "monarquia_parlamentaria" and Politica.mandato("MEX") == 6, "España monarquía parlamentaria; México vota cada 6")
	_comprobar(Politica.mandato("KSA") == 0, "Arabia Saudí no tiene elecciones nacionales")
	var m := Mundo.new()
	m.generar(["CHI"], 5152)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	var pol := m.politica
	var g := pol.gobierno("CHI", 2026)
	_comprobar(Politica.PARTIDOS.has(String(g["partido"])) and Politica.POSTURAS.has(String(g["postura"])), "el gobierno es de un partido inventado y con una postura neutra")
	_comprobar(pol.gobierno("CHI", 2026) == g, "el gobierno no cambia al volver a pedirlo")
	var noticias: Array = []
	var mentor: Array = []
	pol.noticia.connect(func(t: String, _b: String) -> void: noticias.append(t))
	pol.mentor.connect(func(t: String, _b: String) -> void: mentor.append(t))
	## Forzar elecciones este año y recorrer las semanas.
	g["proxima"] = 2026
	var saldo0 := c.saldo
	for s in range(1, 45):
		pol.semana(c, 2026, s, m.prensa)
	_comprobar(mentor.size() == 1, "el mentor explica el Estado una sola vez")
	_comprobar(noticias.has("🗳️ Campaña electoral") and noticias.has("🗳️ Elecciones en CHI"), "hay campaña y hay resultado")
	var g2 := pol.gobierno("CHI", 2026)
	_comprobar(int(g2["desde"]) == 2026 and int(g2["proxima"]) == 2030, "el nuevo gobierno dura 4 años")
	_comprobar(c.saldo != saldo0, "la postura del gobierno se nota en la caja")
	## Arabia Saudí: nunca vota.
	var c2 := m.ligas[0].clubes[1]
	c2.pais = "KSA"
	var n0 := noticias.size()
	for s in range(1, 45):
		pol.semana(c2, 2026, s, m.prensa)
	_comprobar(not noticias.slice(n0).any(func(t: String) -> bool: return t.begins_with("🗳️")), "en Arabia Saudí no hay elecciones")
	_comprobar(Politica.explicacion("KSA").contains("No hay elecciones"), "y el mentor lo explica")
	## Nombres ficticios y sin partidos reales.
	_comprobar(not Politica.nombre_ficticio("CHI", "x").is_empty(), "los políticos tienen nombre inventado")
	var d := pol.a_dic()
	var p2 := Politica.new()
	p2.desde_dic(d)
	_comprobar(p2.gobierno("CHI", 2026)["partido"] == g2["partido"], "el gobierno se guarda")

func _probar_historia_c4() -> void:
	_titulo("C4: HISTORIA DE LOS CLUBES, CON GUIÑO AL REAL")
	Datos.usar_base_real(false)
	var m := Mundo.new()
	m.generar(["CHI"], 5153)
	var clubes: Array = m.ligas[0].clubes
	var por_nombre := {}
	for c: Club in m.clubes.values():
		por_nombre[c.nombre] = c
	var lautaro: Club = por_nombre.get("Lautaro FC")
	var andina: Club = por_nombre.get("U. Andina")
	var precord: Club = por_nombre.get("Precordillera")
	_comprobar(lautaro != null and andina != null and precord != null, "están los tres grandes de la base ficticia")
	var hl := HistoriaClub.de(lautaro, clubes)
	_comprobar(bool(hl["con_guino"]) and String(hl["estadio"]) == "la Ruca" and int(hl["fundado"]) == 1925, "Lautaro FC guiña a su original: fundado en 1925, juega en la Ruca")
	_comprobar(HistoriaClub.nombre_clasico("Lautaro FC", "U. Andina") == "Superclásico", "Lautaro-Andina es el Superclásico")
	_comprobar(HistoriaClub.nombre_clasico("U. Andina", "Precordillera") == "Clásico Universitario", "Andina-Precordillera es el Clásico Universitario")
	_comprobar(HistoriaClub.nombre_clasico("Precordillera", "Lautaro FC") == "el Clásico", "Precordillera-Lautaro es el Clásico")
	_comprobar(m.es_clasico(lautaro, andina), "y el juego lo trata como clásico")
	## Todos los clubes del mundo tienen historia con guiño.
	var m2 := Mundo.new()
	m2.generar([], 5155)
	var sin := 0
	var faltan: Array = []
	for c: Club in m2.clubes.values():
		if HistoriaClub.dato(c.nombre).is_empty():
			sin += 1
			faltan.append(c.nombre)
	if sin > 0:
		print("    sin historia: ", faltan)
	_comprobar(sin == 0, "los %d clubes tienen su fila de historia (%d sin ella)" % [m2.clubes.size(), sin])
	var grande: Club = clubes[0]
	var chico: Club = clubes[clubes.size() - 1]
	_comprobar(int(HistoriaClub.de(grande, clubes)["titulos"]) > int(HistoriaClub.de(chico, clubes)["titulos"]), "el grande tiene más títulos que el chico")
	_comprobar(HistoriaClub.de(grande, clubes) == HistoriaClub.de(grande, clubes), "el mismo club tiene siempre la misma historia")
	_comprobar(HistoriaClub.color_de("#ffffff") == "blanco" and HistoriaClub.color_de("#d50032") == "rojo" and HistoriaClub.color_de("#003da5") == "azul", "el apodo generado sale del color")
	m.tomar_el_mando(clubes[0].id)
	var t := m.prensa.titular_prensa(true, false, true, "x", "Superclásico")
	_comprobar(String(t["tit"]).begins_with("SUPERCLÁSICO: "), "la portada dice SUPERCLÁSICO")
	## Con el pack real, los mismos datos con los nombres reales.
	if Datos.hay_pack_real():
		Datos.usar_base_real(true)
		_comprobar(int(HistoriaClub.dato("C0lo-C0lo").get("fundado", 0)) == 1925 and HistoriaClub.nombre_clasico("C0lo-C0lo", "U. de Ch1le") == "Superclásico", "con el pack real: Colo-Colo 1925 y el Superclásico con la U")
		Datos.usar_base_real(false)
