extends BaseIdea
## LA APP «RED» DEL MÓVIL (27-10-2026, orden del dueño 16): la tabla de recorridos (`RecorridosRed`), el cartel del poste
## (`ParaderoRed`) y la app del teléfono (`AppRed`) dicen lo mismo para un mismo código «PA####».

var _rx_rec := RegEx.create_from_string("^(\\d{3}|C\\d{2})[ce]?$")
var _rx_pat := RegEx.create_from_string("^[BCDFGHJKLPRSTVWXYZ]{4}-\\d{2}$")

func _probar() -> void:
	_titulo("APP RED · CALLES Y RECORRIDOS SOBRE EL MAPA")
	_mapa()
	_titulo("APP RED · PARADEROS")
	_paraderos()
	_titulo("APP RED · HORARIO Y PATENTES")
	_horario()
	_titulo("APP RED · BUSES DE VERDAD Y MINUTOS EN VIVO")
	_en_vivo()
	_titulo("APP RED · EL CARTEL Y LA APP DICEN LO MISMO")
	_cartel_y_app()

## La red vial de la ciudad montada en datos (sin escena), para comparar.
func _red() -> CiudadExpansion:
	var e := CiudadExpansion.new(null)
	e.armar_red()
	return e

## ¿El tramo recto a→c va por calles que existen? Cada 5 m, el punto está en una calle del club o en una cuadra de la rejilla que existe.
func _por_calles(a: Vector2, c: Vector2) -> bool:
	var n := ceili(a.distance_to(c) / 5.0)
	for k in n + 1:
		var p := a.lerp(c, float(k) / float(n))
		var ok := false
		for s: Array in CallesCiudad.NUCLEO:
			ok = ok or CallesCiudad._sobre(p, s)
		var gi := p / CallesCiudad.CELDA
		var en_x := absf(gi.x - roundf(gi.x)) < 0.001
		var en_z := absf(gi.y - roundf(gi.y)) < 0.001
		if not ok and en_x:
			var j0 := floori(gi.y + 0.0001) if not en_z else roundi(gi.y)
			var ka := Vector2i(roundi(gi.x), j0)
			ok = CallesCiudad.existe_tramo(ka, ka + Vector2i(0, 1)) or (en_z and CallesCiudad.existe_tramo(ka, ka - Vector2i(0, 1)))
		if not ok and en_z:
			var i0 := floori(gi.x + 0.0001) if not en_x else roundi(gi.x)
			var kb := Vector2i(i0, roundi(gi.y))
			ok = CallesCiudad.existe_tramo(kb, kb + Vector2i(1, 0)) or (en_x and CallesCiudad.existe_tramo(kb, kb - Vector2i(1, 0)))
		if not ok:
			return false
	return true

func _mapa() -> void:
	_comprobar(RecorridosRed.NUC_X0 == CiudadExpansion.NUC_X0 and RecorridosRed.NUC_X1 == CiudadExpansion.NUC_X1
		and RecorridosRed.NUC_Z0 == CiudadExpansion.NUC_Z0 and RecorridosRed.NUC_Z1 == CiudadExpansion.NUC_Z1
		and RecorridosRed.RIO_X == CityBuilder.RIO_X and RecorridosRed.RIO_MEDIO == CiudadExpansion.RIO_MEDIO
		and CallesCiudad.NUC_X0 == CiudadExpansion.NUC_X0 and CallesCiudad.FINCA == CiudadExpansion.FINCA_GRANDE and CallesCiudad.K == CiudadExpansion.K,
		"las medidas de las zonas y de la rejilla son las de la ciudad")
	_comprobar(CityBuilder.RING_X == 205.0 and CityBuilder.RING_Z_NORTE == -320.0 and CityBuilder.RING_Z_SUR == 350.0 and CityBuilder.EX_N == -282.0
		and CityBuilder.EX_S == 262.0 and CityBuilder.BARRIO_EN.x == -60.0, "las calles del club (`CallesCiudad.NUCLEO`) siguen donde las pone `CityBuilder`")
	## Los nombres: uno por fila y por columna, todos distintos, chilenos (sin «Calle de…» ni «Avenida»).
	var nombres := {}
	for n: String in CallesCiudad.FILAS + CallesCiudad.COLUMNAS:
		nombres[n] = true
	_comprobar(CallesCiudad.FILAS.size() == 25 and CallesCiudad.COLUMNAS.size() == 25 and nombres.size() == 50, "50 nombres de calle distintos (25 filas y 25 columnas)")
	var av_ok := true
	for k in range(-12, 13):
		av_ok = av_ok and CallesCiudad.nombre_fila(k).begins_with("Av. ") == CallesCiudad.es_avenida_fila(k) and CallesCiudad.nombre_columna(k).begins_with("Av. ") == CallesCiudad.es_avenida_columna(k)
	_comprobar(av_ok, "las avenidas (una de cada tres y el bulevar del club) llevan «Av.»; las calles, no")
	## La regla de las cuadras es la de la ciudad: los mismos tramos que arma `CiudadExpansion`.
	var e := _red()
	var reales := {}
	for t: Dictionary in e.tramos:
		if t.has("ka"):
			reales["%s|%s" % [t["ka"], t["kb"]]] = true
	var iguales := true
	var n_estat := 0
	for i in range(-12, 13):
		for j in range(-12, 13):
			for d: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
				var ka := Vector2i(i, j)
				if CallesCiudad.existe_tramo(ka, ka + d):
					n_estat += 1
					iguales = iguales and reales.has("%s|%s" % [ka, ka + d])
	_comprobar(iguales and n_estat == reales.size(), "`CallesCiudad.existe_tramo` da las %d cuadras de la red vial" % n_estat)
	_comprobar(CallesCiudad.calle_en(Vector3(0, 0, -990)).contains(" con ") and CallesCiudad.calle_en(Vector3(205, 0, -100)) == "Av. Los Hinchas"
		and CallesCiudad.calle_en(Vector3(-470, 0, 0)) == "Av. La Herradura" and CallesCiudad.calle_en(Vector3(60, 0, 60)) == ""
		and e.nombre_calle_en(Vector3(165, 0, -660)) == "Av. Los Pimientos", "`calle_en`: cruces, el anillo del club, el puente y nada dentro de una manzana")
	## Los recorridos.
	var servs := RecorridosMapa.servicios()
	var mal: Array[String] = []
	var n_e := 0
	var locales := 0
	for num: String in servs:
		var sv := RecorridosMapa.servicio(num)
		var ejes: PackedVector2Array = sv["ejes"]
		for i in ejes.size() - 1:
			if not _por_calles(ejes[i], ejes[i + 1]):
				mal.append("%s %s→%s" % [num, ejes[i], ejes[i + 1]])
		if num.begins_with("C"):
			locales += 1
		elif not num.ends_with("c") and int(num.substr(0, 1)) * 100 != int(sv["sector"]):
			mal.append("%s nace en el sector %d" % [num, sv["sector"]])
		if num.ends_with("e"):
			n_e += 1
		if num.ends_with("c"):
			continue
		var vu := RecorridosMapa.servicio(RecorridosMapa.vuelta_de(num))
		var inv := PackedVector2Array(ejes)
		inv.reverse()
		if vu.is_empty() or (not num.ends_with("e") and PackedVector2Array(vu["ejes"]) != inv) or String(sv["destino"]) == "" or String(vu["destino"]) == "":
			mal.append("%s sin su «c» o sin destino" % num)
	_comprobar(mal.is_empty(), "%d servicios por calles reales, con el número de su sector, su «c» y sus destinos %s" % [servs.size(), str(mal.slice(0, 4))])
	_comprobar(n_e >= 1 and n_e <= 2 and locales >= 2, "%d alternativa «e» y %d servicios locales «C..»" % [n_e, locales])

func _paraderos() -> void:
	var d := RecorridosMapa.datos()
	var rx := RegEx.create_from_string("^PA[1-6]\\d{3}$")
	var mal: Array[String] = []
	var codigos := {}
	var por_sector := {}
	for cod: String in d["orden"]:
		var p := RecorridosMapa.paradero(cod)
		codigos[cod] = true
		por_sector[p["sector"]] = int(por_sector.get(p["sector"], 0)) + 1
		var e2: Vector2 = p["eje"]
		if rx.search(cod) == null or RecorridosRed.sector_del_codigo(cod) != RecorridosRed.sector_de(Vector3(e2.x, 0, e2.y)):
			mal.append(cod)
		## El nombre: la calle real del mapa en ese punto y la esquina.
		var calle := CallesCiudad.calle_en(Vector3(e2.x, 0, e2.y))
		if String(p["calle"]) != calle or not String(p["nombre"]).begins_with(calle + " / ") or String(p["cruce"]) == calle:
			mal.append("%s «%s» ≠ «%s»" % [cod, p["nombre"], calle])
		var rs := RecorridosRed.recorridos(cod)
		if rs.size() < 2 or rs.size() > 5:
			mal.append("%s con %d recorridos" % [cod, rs.size()])
		## Cada recorrido del paradero pasa de verdad por él, en su sentido.
		for r: String in rs:
			if not _pasa(RecorridosMapa.servicio(r), e2, p["dir"]) or not (RecorridosMapa.servicio(r)["paraderos"] as Array).has(cod):
				mal.append("%s no pasa por %s" % [r, cod])
	_comprobar(mal.is_empty(), "%d paraderos con código «PA» + sector + 3 cifras, nombre de su calle y de 2 a 5 recorridos que pasan por él %s" % [d["orden"].size(), str(mal.slice(0, 4))])
	_comprobar(codigos.size() == d["orden"].size() and codigos.size() >= 100, "%d códigos, ninguno repetido · por sector %s" % [codigos.size(), por_sector])
	var p1 := RecorridosMapa.paradero(RecorridosRed.paradero_en(Vector3(192, 0, -170)))
	_comprobar(not p1.is_empty() and String(p1["nombre"]) == "Av. Los Hinchas / Estadio" and bool(p1["club"]), "el paradero del estadio en el anillo: %s" % p1.get("nombre", "-"))
	_comprobar(RecorridosRed.normalizar(" pa 1234 ") == "PA1234" and RecorridosRed.normalizar("3205") == "PA3205"
		and RecorridosRed.normalizar("hola") == "" and not RecorridosRed.existe("PA9999") and RecorridosRed.recorridos("PA9999").is_empty(),
		"el código escrito a mano se normaliza y uno inventado no existe")

func _pasa(sv: Dictionary, p: Vector2, dir: Vector2) -> bool:
	var ejes: PackedVector2Array = sv["ejes"]
	for i in ejes.size() - 1:
		if Geometry2D.get_closest_point_to_segment(p, ejes[i], ejes[i + 1]).distance_to(p) < 0.5 and (ejes[i + 1] - ejes[i]).normalized().is_equal_approx(dir):
			return true
	return false

func _horario() -> void:
	var cod := RecorridosRed.codigo(5, 200)
	var ok_f := true
	for r: String in ["122", "217c", "C09c", "301e"]:
		for dia in 7:
			for md in range(0, 1440, 30):
				var f := RecorridosRed.frecuencia(r, md, dia)
				ok_f = ok_f and f >= 6 and f <= 15
	_comprobar(ok_f, "frecuencias de 6 a 15 minutos a toda hora")
	_comprobar(RecorridosRed.frecuencia("217", 8 * 60, 1) < RecorridosRed.frecuencia("217", 22 * 60, 1), "más seguido en punta que de noche")
	var noche := RecorridosRed.llegadas(cod, 2 * 1440 + 23 * 60 + 59)
	_comprobar(noche.is_empty() or int(noche[0]["minutos"]) <= 15, "de noche tarde solo queda alguna última pasada")
	var madrugada := RecorridosRed.llegadas(cod, 2 * 1440 + 3 * 60)
	var primera := 9999
	for l: Dictionary in madrugada:
		primera = mini(primera, int(l["hora"]))
	_comprobar(not madrugada.is_empty() and primera >= RecorridosRed.INICIO_SERVICIO, "a las 03:00 la primera es desde las 05:30 (%02d:%02d)" % [primera / 60, primera % 60])
	var ls := RecorridosRed.llegadas(cod, 1440 + 18 * 60 + 7)
	var orden := true
	var pats := true
	var de_aqui := true
	for i in ls.size():
		if i > 0 and int(ls[i]["minutos"]) < int(ls[i - 1]["minutos"]):
			orden = false
		pats = pats and _rx_pat.search(String(ls[i]["patente"])) != null
		de_aqui = de_aqui and RecorridosRed.recorridos(cod).has(String(ls[i]["recorrido"]))
	_comprobar(ls.size() >= 3 and orden and de_aqui, "%d llegadas ordenadas por minutos, solo de los recorridos que paran ahí" % ls.size())
	_comprobar(pats, "patentes de bus chilenas (4 letras y 2 cifras): %s" % (String(ls[0]["patente"]) if not ls.is_empty() else "-"))
	_comprobar(RecorridosRed.patente("122", 3) == RecorridosRed.patente("122c", 3)
		and RecorridosRed.patente("122", 3) == RecorridosRed.patente("122", 3 + RecorridosRed.flota("122")),
		"la patente es la del bus: la misma a la ida, a la vuelta y en su siguiente vuelta")
	## La misma salida llega más tarde a un paradero más lejano de la cabecera: el tiempo es la distancia real por sus calles.
	var sv := RecorridosMapa.servicio("278")
	var c0 := String(sv["paraderos"][0])
	var c1 := String(sv["paraderos"][(sv["paraderos"] as Array).size() - 1])
	var p0 := RecorridosRed.pasadas(c0, "278", 1)
	var p1 := RecorridosRed.pasadas(c1, "278", 1)
	var esperado := roundi(RecorridosRed.distancia(c1, "278") / RecorridosRed.VEL_COMERCIAL) - roundi(RecorridosRed.distancia(c0, "278") / RecorridosRed.VEL_COMERCIAL)
	_comprobar(p0.size() == p1.size() and p1[10] - p0[10] == esperado and esperado > 3,
		"el 278 tarda %d min de %s a %s (%d m por sus calles)" % [esperado, c0, c1, roundi(RecorridosRed.distancia(c1, "278") - RecorridosRed.distancia(c0, "278"))])
	var r0: String = RecorridosRed.recorridos(cod)[0]
	var q0: int = RecorridosRed.pasadas(cod, r0, 1)[20]
	var justo := RecorridosRed.llegadas(cod, 1440 + q0)
	_comprobar(not justo.is_empty() and int(justo[0]["minutos"]) == 0, "en el minuto de la pasada el %s está a 0 min" % r0)

## Los buses de la calle: cada recorrido una ruta cerrada (ida + vuelta) en `TraficoCiudad`, con su patente, y la app con su posición.
func _en_vivo() -> void:
	var cb := CityBuilder.new()
	var e := CiudadExpansion.new(cb)
	e.armar_red()
	var t := TraficoCiudad.new()
	add_child(t)
	var n := BusesRed.montar(e, t)
	var g := t.get_node("BusesRed") as BusesRed
	var pats := {}
	var nums := {}
	for b: Dictionary in g.buses:
		pats[(b["nodo"] as Node).get_meta("red_patente")] = true
		nums[b["ida"]] = true
	_comprobar(n >= 22 and pats.size() == n and nums.size() == 22, "%d buses en %d recorridos, cada uno con su patente distinta" % [n, nums.size()])
	## El primer bus del 217: a 900 m de un paradero suyo, a 9 m/s.
	var b0: Dictionary = {}
	for b: Dictionary in g.buses:
		if String(b["ida"]) == "217":
			b0 = b
			break
	var cod := String(RecorridosMapa.servicio("217")["paraderos"][2])
	var v: Dictionary = g._vehiculos()[b0["nodo"]]
	var s_par := float(b0["paradas"][cod])
	v["s"] = fposmod(s_par - 900.0, float(b0["largo"]))
	var entre := 0
	for s2: float in (b0["paradas"] as Dictionary).values():
		var dd := fposmod(s2 - float(v["s"]), float(b0["largo"]))
		if dd > 0.5 and dd < 899.5:
			entre += 1
	var ls := BusesRed.llegadas(get_tree(), cod)
	var mio: Dictionary = {}
	for l: Dictionary in ls:
		if String(l["patente"]) == String((b0["nodo"] as Node).get_meta("red_patente")):
			mio = l
	var espera := 900.0 / BusesRed.VEL + float(entre) * (BusesRed.ESPERA + BusesRed.ARRANQUE_Y_FRENADA)
	_comprobar(not mio.is_empty() and absf(float(mio["segundos"]) - espera) < 0.5 and String(mio["recorrido"]) == "217" and bool(mio["en_vivo"]),
		"el 217 a 900 m (y %d paradas en medio) llega en %.0f s según su posición real (%s)" % [entre, float(mio.get("segundos", -1.0)), cod])
	var orden := true
	for i in range(1, ls.size()):
		orden = orden and int(ls[i]["minutos"]) >= int(ls[i - 1]["minutos"]) and RecorridosRed.recorridos(cod).has(String(ls[i]["recorrido"]))
	_comprobar(ls.size() >= 2 and orden, "%d llegadas en vivo ordenadas, solo de los recorridos del paradero" % ls.size())
	## En la vuelta, el mismo bus es el «217c» y el letrero lo dice.
	var cod_c := String(RecorridosMapa.servicio("217c")["paraderos"][1])
	v["s"] = fposmod(float(b0["paradas"][cod_c]) - 50.0, float(b0["largo"]))
	g._t = 0.0
	g._process(0.1)
	var vuelta := false
	for l: Dictionary in BusesRed.llegadas(get_tree(), cod_c):
		vuelta = vuelta or (String(l["recorrido"]) == "217c" and String(l["patente"]) == String((b0["nodo"] as Node).get_meta("red_patente")))
	_comprobar(vuelta and (b0["rotulo"] as Label3D).text.begins_with("217c · "), "de vuelta es el 217c («%s»)" % (b0["rotulo"] as Label3D).text)
	t.free()
	cb.free()

func _cartel_y_app() -> void:
	## Un paradero montado en el Este (sector 300), como en la ciudad.
	var raiz := Node3D.new()
	raiz.position = Vector3(720, 0, 120)
	add_child(raiz)
	ParaderoRed.montar(raiz, 3.6, 4321)
	var cod := String(raiz.get_meta("codigo_red", ""))
	var textos: Array[String] = []
	for l: Node in raiz.find_children("*", "Label3D", true, false):
		textos.append((l as Label3D).text)
	_comprobar(cod.begins_with("PA3") and textos.has(cod), "el cartel del Este lleva su código del sector 300 (%s)" % cod)
	var rs := RecorridosRed.recorridos(cod)
	var en_cartel := true
	for r: String in rs:
		en_cartel = en_cartel and textos.has(r)
	_comprobar(en_cartel, "el cartel lleva los recorridos de la tabla: %s" % ", ".join(rs))
	var m := _mundo(4321)
	if m.reloj != null:
		m.reloj._al_dia()
	var tel := Telefono.crear(m)
	tel.custom_minimum_size = Vector2(Telefono.ANCHO, 760)
	add_child(tel)
	tel.en_la_calle = true
	tel.posicion_dt = raiz.position + Vector3(6, 0, 4)
	tel.abrir_app("red")
	var lb := _textos(tel)
	_comprobar(lb.has(cod) and lb.has(RecorridosRed.nombre_parada(cod)), "la app encuentra el paradero cercano (%s · %s)" % [cod, RecorridosRed.nombre_parada(cod)])
	var chips_ok := true
	for r: String in rs:
		chips_ok = chips_ok and lb.has(r)
	_comprobar(chips_ok, "y muestra los mismos recorridos que el cartel")
	var mins: Array[int] = []
	var pats := true
	for n: Node in tel.find_children("Minutos", "Label", true, false):
		var t := (n as Label).text
		mins.append(0 if t == "Llegando" else int(t.split(" ")[0]))
	for n: Node in tel.find_children("Patente", "Label", true, false):
		pats = pats and _rx_pat.search((n as Label).text) != null
	var esperado := RecorridosRed.llegadas(cod, AppRed.minuto_semana(m))
	var ordenadas := mins.size() == esperado.size() and mins.size() >= 3
	for i in mins.size():
		ordenadas = ordenadas and (i == 0 or mins[i] >= mins[i - 1]) and i < esperado.size() and mins[i] == int(esperado[i]["minutos"])
	_comprobar(ordenadas, "la app lista %d llegadas ordenadas por minutos (%s)" % [mins.size(), str(mins.slice(0, 6))])
	_comprobar(pats and mins.size() > 0, "con patentes de bus con el formato")
	## Lejos de todo paradero: el campo del código.
	tel.posicion_dt = Vector3(5000, 0, 5000)
	tel.abrir_app("red")
	_comprobar(not _textos(tel).has(cod), "a más de 40 m no hay paradero cercano")
	tel.codigo_red = RecorridosRed.normalizar(cod.to_lower())
	tel.abrir_app("red")
	_comprobar(_textos(tel).has(cod), "escribiendo el código («%s») sale el mismo paradero" % cod.to_lower())
	tel.codigo_red = "PA9999"
	tel.abrir_app("red")
	_comprobar(_textos(tel).has("Ese paradero no existe"), "un código que no está en el mapa: «Ese paradero no existe»")
	tel.codigo_red = cod
	## En otro idioma: lo de la app se traduce y la marca, las calles y las patentes no.
	Idiomas.idioma = "en"
	tel.abrir_app("red")
	var en := _textos(tel)
	var sin_es := not en.has("PRÓXIMAS LLEGADAS") and not en.has("Buscar") and not en.has("Llegando")
	var nuevas := ["PRÓXIMAS LLEGADAS", "Buscar", "Llegando", "%d min", "Con asientos", "De pie", "Lleno", "Cerca", "Código escrito",
		"A %d m de ti", "No hay un paradero cerca", "Sin servicio a esta hora. Los recorridos vuelven a pasar desde las 05:30.",
		"Tiempos estimados según el horario de cada recorrido.", "⚠️ El código es «PA» y cuatro cifras, como en el poste.",
		"Acércate a menos de 40 m de un paradero o escribe el código PA del poste.", "Ese paradero no existe",
		"Revisa el código del poste: «PA» y cuatro cifras.", "Tiempos según la posición real de cada bus."]
	var faltan: Array[String] = []
	for f: String in nuevas:
		if Idiomas.t(f) == f and f != "%d min":
			faltan.append(f)
	_comprobar(sin_es and faltan.is_empty(), "en inglés la app se traduce %s" % str(faltan))
	_comprobar(en.has("Red") and en.has(cod) and en.has(RecorridosRed.nombre_parada(cod)), "y «Red», el código y la calle quedan igual")
	var hay_min := false
	for t: String in en:
		hay_min = hay_min or t.ends_with(" min") or t == Idiomas.t("Llegando")
	_comprobar(hay_min, "los minutos se leen en inglés")
	tel.abrir_app("inicio")
	_comprobar(_textos(tel).has("Red"), "el icono de la app se llama «Red» también en inglés")
	Idiomas.idioma = "es"
	tel.queue_free()

func _textos(n: Node) -> Array[String]:
	var out: Array[String] = []
	for l: Node in n.find_children("*", "Label", true, false):
		if _vivo(l, n):
			out.append((l as Label).text)
	for b: Node in n.find_children("*", "Button", true, false):
		if _vivo(b, n):
			out.append((b as Button).text)
	return out

## Lo que `abrir_app` acaba de mandar a borrar sigue en el árbol hasta el fotograma siguiente.
func _vivo(x: Node, raiz: Node) -> bool:
	while x != null and x != raiz:
		if x.is_queued_for_deletion():
			return false
		x = x.get_parent()
	return true
