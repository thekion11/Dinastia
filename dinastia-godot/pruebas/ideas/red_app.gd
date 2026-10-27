extends BaseIdea
## LA APP «RED» DEL MÓVIL (27-10-2026, orden del dueño 16): la tabla de recorridos (`RecorridosRed`), el cartel del poste
## (`ParaderoRed`) y la app del teléfono (`AppRed`) dicen lo mismo para un mismo código «PA####».

var _rx_rec := RegEx.create_from_string("^(\\d{3}|C\\d{2})[ce]?$")
var _rx_pat := RegEx.create_from_string("^[BCDFGHJKLPRSTVWXYZ]{4}-\\d{2}$")

func _probar() -> void:
	_titulo("APP RED · TABLA DE RECORRIDOS")
	_tabla()
	_titulo("APP RED · HORARIO Y PATENTES")
	_horario()
	_titulo("APP RED · EL CARTEL Y LA APP DICEN LO MISMO")
	_cartel_y_app()

func _tabla() -> void:
	_comprobar(RecorridosRed.NUC_X0 == CiudadExpansion.NUC_X0 and RecorridosRed.NUC_X1 == CiudadExpansion.NUC_X1
		and RecorridosRed.NUC_Z0 == CiudadExpansion.NUC_Z0 and RecorridosRed.NUC_Z1 == CiudadExpansion.NUC_Z1
		and RecorridosRed.RIO_X == CityBuilder.RIO_X and RecorridosRed.RIO_MEDIO == CiudadExpansion.RIO_MEDIO,
		"las medidas de las zonas son las de la ciudad")
	_comprobar(RecorridosRed.sector_de(Vector3(0, 0, -150)) == 100 and RecorridosRed.sector_de(Vector3(0, 0, -800)) == 200
		and RecorridosRed.sector_de(Vector3(800, 0, 0)) == 300 and RecorridosRed.sector_de(Vector3(0, 0, 900)) == 400
		and RecorridosRed.sector_de(Vector3(-800, 0, 0)) == 500 and RecorridosRed.sector_de(Vector3(1250, 0, 0)) == 600,
		"un sector por zona: club 100, centro 200, este 300, sur 400, oeste 500, periferia 600")
	var n_rec := 0
	var n_c := 0
	var n_e := 0
	var n_local := 0
	var malos: Array[String] = []
	var tamanos_ok := true
	var codigos := {}
	for sector in [100, 200, 300, 400, 500, 600]:
		for semilla in 400:
			var cod := RecorridosRed.codigo(semilla * 37 + 5, sector)
			codigos[cod] = true
			if not cod.begins_with("PA%d" % (sector / 100)) or cod.length() != 6 or RecorridosRed.sector_del_codigo(cod) != sector:
				malos.append(cod)
			var rs := RecorridosRed.recorridos(cod)
			tamanos_ok = tamanos_ok and rs.size() >= 3 and rs.size() <= 5 and rs == RecorridosRed.recorridos(cod)
			var propios := 0
			for r: String in rs:
				n_rec += 1
				if _rx_rec.search(r) == null:
					malos.append(r)
					continue
				if r.ends_with("c"):
					n_c += 1
				if r.ends_with("e"):
					n_e += 1
				if r.begins_with("C"):
					n_local += 1
					continue
				var s := int(r.substr(0, 1)) * 100
				if s == sector:
					propios += 1
				elif not (RecorridosRed.VECINOS[sector] as Array).has(s):
					malos.append("%s en %s" % [r, cod])
			if propios < 1:
				malos.append("%s sin recorridos de su sector" % cod)
	_comprobar(malos.is_empty(), "códigos «PA» + sector + 3 cifras y recorridos con el número del sector o de un vecino %s" % str(malos.slice(0, 4)))
	_comprobar(tamanos_ok, "cada paradero tiene de 3 a 5 recorridos y la tabla es determinista")
	var pc := float(n_c) / float(n_rec)
	var pe := float(n_e) / float(n_rec)
	_comprobar(pc > 0.3 and pc < 0.7, "«c» (sentido contrario) en el %d %% de los recorridos" % int(pc * 100.0))
	_comprobar(n_e > 0 and pe < 0.05, "«e» (alternativa) muy rara: %d de %d (%.1f %%)" % [n_e, n_rec, pe * 100.0])
	_comprobar(n_local > 0, "hay recorridos locales «C..» (%d)" % n_local)
	## 400 paraderos por sector en 1.000 códigos: al azar quedarían ~1.980 distintos (la ciudad tiene unas decenas por sector).
	_comprobar(codigos.size() > 1900, "códigos repartidos por paradero (%d distintos de 2400)" % codigos.size())
	_comprobar(RecorridosRed.normalizar(" pa 1234 ") == "PA1234" and RecorridosRed.normalizar("3205") == "PA3205"
		and RecorridosRed.normalizar("hola") == "", "el código escrito a mano se normaliza («pa 1234» → PA1234)")
	var n1 := RecorridosRed.nombre_parada("PA1234")
	_comprobar(n1 == RecorridosRed.nombre_parada("PA1234") and n1.contains(" / ") and n1 != RecorridosRed.nombre_parada("PA1235"),
		"nombre de la parada estable: %s" % n1)

func _horario() -> void:
	var cod := "PA2417"
	var ok_f := true
	for r: String in ["122", "217c", "C09c", "301e"]:
		for dia in 7:
			for md in range(0, 1440, 30):
				var f := RecorridosRed.frecuencia(r, md, dia)
				ok_f = ok_f and f >= 6 and f <= 15
	_comprobar(ok_f, "frecuencias de 6 a 15 minutos a toda hora")
	_comprobar(RecorridosRed.frecuencia("217", 8 * 60, 1) < RecorridosRed.frecuencia("217", 22 * 60, 1), "más seguido en punta que de noche")
	var noche := RecorridosRed.llegadas(cod, 2 * 1440 + 23 * 60 + 45)
	_comprobar(noche.is_empty(), "de noche tarde (23:45) no pasan micros")
	var madrugada := RecorridosRed.llegadas(cod, 2 * 1440 + 3 * 60)
	var primera := 9999
	for l: Dictionary in madrugada:
		primera = mini(primera, int(l["hora"]))
	_comprobar(not madrugada.is_empty() and primera >= RecorridosRed.INICIO_SERVICIO, "a las 03:00 la primera es desde las 05:30 (%02d:%02d)" % [primera / 60, primera % 60])
	var ls := RecorridosRed.llegadas(cod, 1440 + 18 * 60 + 7)
	var orden := true
	var pats := true
	for i in ls.size():
		if i > 0 and int(ls[i]["minutos"]) < int(ls[i - 1]["minutos"]):
			orden = false
		pats = pats and _rx_pat.search(String(ls[i]["patente"])) != null
	_comprobar(ls.size() >= 3 and orden, "%d llegadas ordenadas por minutos" % ls.size())
	_comprobar(pats, "patentes de bus chilenas (4 letras y 2 cifras): %s" % (String(ls[0]["patente"]) if not ls.is_empty() else "-"))
	_comprobar(RecorridosRed.patente("122", 3) == RecorridosRed.patente("122c", 3)
		and RecorridosRed.patente("122", 3) == RecorridosRed.patente("122", 3 + RecorridosRed.flota("122")),
		"la patente es la del bus: la misma a la ida, a la vuelta y en su siguiente vuelta")
	## «Llegando»: justo en el minuto de una pasada.
	var r0: String = RecorridosRed.recorridos(cod)[0]
	var p0: int = RecorridosRed.pasadas(cod, r0, 1)[20]
	var justo := RecorridosRed.llegadas(cod, 1440 + p0)
	_comprobar(not justo.is_empty() and int(justo[0]["minutos"]) == 0, "en el minuto de la pasada el %s está a 0 min" % r0)

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
	## En otro idioma: lo de la app se traduce y la marca, las calles y las patentes no.
	Idiomas.idioma = "en"
	tel.abrir_app("red")
	var en := _textos(tel)
	var sin_es := not en.has("PRÓXIMAS LLEGADAS") and not en.has("Buscar") and not en.has("Llegando")
	var nuevas := ["PRÓXIMAS LLEGADAS", "Buscar", "Llegando", "%d min", "Con asientos", "De pie", "Lleno", "Cerca", "Código escrito",
		"A %d m de ti", "No hay un paradero cerca", "Sin servicio a esta hora. Los recorridos vuelven a pasar desde las 05:30.",
		"Tiempos estimados según el horario de cada recorrido.", "⚠️ El código es «PA» y cuatro cifras, como en el poste.",
		"Acércate a menos de 40 m de un paradero o escribe el código PA del poste."]
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
