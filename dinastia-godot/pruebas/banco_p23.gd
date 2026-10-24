extends "res://pruebas/banco_p22.gd"
## [Capa 25/27 de `banco.gd`] _probar_disenos_kit, _jug_ley, _probar_leyes_pais, _probar_incumplir_ley, _probar_b6_formas_led, _probar_region_reales … (+5)

func _probar_disenos_kit() -> void:
	_titulo("EQUIPACIÓN: DISEÑOS, COLORES, BOTINES Y ACCESORIOS")
	var claves := DisenosKit.claves()
	_comprobar(claves.size() >= 62, "hay al menos 50 diseños nuevos (%d en total)" % claves.size())
	var unicas := {}
	for k: String in claves:
		unicas[k] = true
	_comprobar(unicas.size() == claves.size(), "sin claves repetidas")
	_comprobar(Jersey.KITS.all(func(k: String) -> bool: return claves.has(k)), "los 12 estilos de siempre siguen")
	_comprobar(DisenosKit.BOTINES.size() == 30, "30 modelos de botín")
	var de_dos := DisenosKit.DISENOS.filter(func(d: Array) -> bool: return int(d[2]) >= 43 and int(d[2]) <= 62 and int(d[7]) == 2)
	var de_tres := DisenosKit.DISENOS.filter(func(d: Array) -> bool: return int(d[2]) >= 43 and int(d[2]) <= 62 and int(d[7]) == 3)
	_comprobar(de_dos.size() == 20 and de_tres.size() == 20, "20 diseños nuevos de dos colores y 20 de tres")
	var cols3: Array[Color] = [Color.RED, Color.WHITE, Color.BLUE, Color.BLACK, Color.GREEN]
	var usados := {}
	for d: Array in de_dos:
		for i in 60:
			usados[DisenosKit.color_en(d, cols3, float(i % 10) / 5.0 - 1.0, float(i / 10) / 6.0).to_html(false)] = true
	_comprobar(not usados.has(Color.BLUE.to_html(false)) and not usados.has(Color.BLACK.to_html(false)), "los de dos colores no usan un tercero")
	## Patrocinadores.
	var ms := Mundo.new()
	ms.generar(["CHI"], 31)
	ms.tomar_el_mando(ms.ligas[0].clubes[0].id)
	_comprobar(SponsorKit.de_club(ms.mi_club(), ms).is_empty(), "sin contrato, tu camiseta va limpia")
	ms.auspicio.contrato = {"marca": "Cerveza Andin4", "color": "#e8b13a", "monto": 1, "exig_pos": 5, "anio": 2026}
	var spk := DisenosKit.kit_de_club(ms.mi_club())
	_comprobar((spk["sp"] as Dictionary).has("pecho") and String(spk["sp"]["pecho"]["marca"]) == "Cerveza Andina", "el contrato principal va al pecho (sin la cubierta)")
	var ajenos := 0
	for cc: Club in ms.ligas[0].clubes:
		if cc != ms.mi_club() and not SponsorKit.de_club(cc, ms).is_empty():
			ajenos += 1
	_comprobar(ajenos > 0 and SponsorKit.de_club(ms.ligas[0].clubes[3], ms) == SponsorKit.de_club(ms.ligas[0].clubes[3], ms), "los rivales llevan sus sponsors, siempre los mismos")
	var im := SponsorKit.imagen("Seguros Patagonia", "#8fa3b5", Color.WHITE)
	_comprobar(im.get_width() > im.get_height() and SponsorKit.lineas_de("SEGUROS PATAGONIA").size() == 2, "los nombres largos van en dos líneas")
	var un := DisenosKit.uniforms(spk, 9)
	_comprobar(bool(un["hay_sp_pecho"]) and un["sp_pecho"] is Texture2D, "el sponsor llega al shader 3D")
	ms.mi_club().kit_x = {"sp_ocultar": ["pecho"]}
	_comprobar(not (DisenosKit.kit_de_club(ms.mi_club())["sp"] as Dictionary).has("pecho"), "se puede no estampar una zona")
	_comprobar(DisenosKit.ACCESORIOS.size() >= 6, "accesorios para los jugadores")
	var cinco := DisenosKit.DISENOS.filter(func(d: Array) -> bool: return int(d[7]) == 5)
	_comprobar(not cinco.is_empty(), "hay diseños que usan los 5 colores")
	## La fórmula 2D da colores de la paleta.
	var cols: Array[Color] = [Color.RED, Color.WHITE, Color.BLUE, Color.YELLOW, Color.BLACK]
	var vistos := {}
	var d := DisenosKit.diseno("franjas_cinco")
	for i in 40:
		vistos[DisenosKit.color_en(d, cols, -1.0 + float(i) / 20.0, 0.5).to_html()] = true
	_comprobar(vistos.size() >= 4, "«Franjas de cinco colores» usa varios colores (%d)" % vistos.size())
	## El kit de un club, guardado y leído.
	var m := Mundo.new()
	m.generar(["CHI"], 5158)
	var c: Club = m.ligas[0].clubes[0]
	var k := DisenosKit.kit_de_club(c)
	_comprobar((k["cols"] as Array).size() == 5 and k.has("bot") and k.has("acc"), "la equipación completa tiene 5 colores, botines y accesorios")
	c.kit_x = {"dis": "tartan", "bot": {"mod": "fuego"}, "acc": {"guantes": "111111"}}
	var dic := c.identidad_a_dic()
	var c2 := Club.new()
	c2.identidad_desde_dic(dic)
	_comprobar(String(DisenosKit.kit_de_club(c2)["dis"]) == "tartan", "el diseño elegido se guarda con el club")
	var u := DisenosKit.uniforms(DisenosKit.kit_de_club(c2), 10)
	_comprobar(int(u["familia"]) == 26 and (u["acc_guantes"] as Color).a > 0.5 and int(u["dorsal"]) == 10, "el shader recibe diseño, accesorios y dorsal")
	_comprobar(DisenosKit.textura_camiseta("tartan", cols, 1, 64) != null, "la miniatura 2D se dibuja")


## LAS REGLAS DE CADA PAÍS (7-10-2026): cada club con las de su liga.
func _jug_ley(id: String, pais: String, pos: String, ovr: int, edad: int = 26) -> Jugador:
	var j := Jugador.new()
	j.id = id
	j.nombre = id
	j.pais = pais
	j.pos = pos
	j.pos_e = {"POR": "POR", "DEF": "DFC", "MED": "MC", "DEL": "DC"}[pos]
	j.ovr = ovr
	j.edad = edad
	return j

func _probar_leyes_pais() -> void:
	_titulo("LEYES POR PAÍS: CUPOS Y JUVENILES SEGÚN LA LIGA DEL CLUB")
	## Chile: 6 extranjeros en el plantel, 5 en cancha y un sub-21 en el once.
	var c := Club.new("chi_test", "Prueba CHI")
	c.pais = "CHI"
	var lineas := ["POR", "DEF", "DEF", "DEF", "DEF", "MED", "MED", "MED", "DEL", "DEL", "DEL"]
	for k in 11:
		c.plantilla.append(_jug_ley("e%d" % k, "ARG" if k < 7 else "CHI", lineas[k], 80 if k < 7 else 70))
	for k in 6:
		c.plantilla.append(_jug_ley("b%d" % k, "CHI", lineas[(k % 10) + 1], 65, 19 if k == 0 else 27))
	for j: Jugador in c.plantilla:
		j.club_id = c.id
	var once := c.once()
	var de_fuera := 0
	var sub21 := false
	for j: Jugador in once:
		if j.pais != "CHI":
			de_fuera += 1
		if j.edad <= 21:
			sub21 = true
	_comprobar(once.size() == 11 and de_fuera <= 5 and sub21, "Chile: once con %d extranjeros (máx. 5) y sub-21 = %s" % [de_fuera, sub21])
	_comprobar(LeyesPais.motivo_fichaje(c, _jug_ley("nuevo", "URU", "DEL", 75)) != "", "Chile: con 7 extranjeros no se ficha otro")
	_comprobar(LeyesPais.motivo_fichaje(c, _jug_ley("local", "CHI", "DEL", 75)) == "", "Chile: un chileno siempre cabe")
	## España: cuentan los extracomunitarios, no los europeos.
	var e := Club.new("esp_test", "Prueba ESP")
	e.pais = "ESP"
	for k in 3:
		e.plantilla.append(_jug_ley("br%d" % k, "BRA", "MED", 75))
	_comprobar(LeyesPais.motivo_fichaje(e, _jug_ley("arg", "ARG", "DEL", 75)) != "", "España: el cuarto extracomunitario no entra")
	_comprobar(LeyesPais.motivo_fichaje(e, _jug_ley("fra", "FRA", "DEL", 75)) == "", "España: un francés no ocupa cupo")
	## Brasil: sin tope en el plantel, 9 en cancha.
	var b := Club.new("bra_test", "Prueba BRA")
	b.pais = "BRA"
	for k in 12:
		b.plantilla.append(_jug_ley("x%d" % k, "URU", "MED", 75))
	_comprobar(LeyesPais.motivo_fichaje(b, _jug_ley("otro", "ARG", "DEL", 75)) == "", "Brasil: sin tope de extranjeros en el plantel")
	## Cada liga tiene su resumen para la pantalla de Federación.
	_comprobar(LeyesPais.resumen("MEX").size() >= 3 and LeyesPais.resumen("ZZZ").is_empty(), "resumen de reglas por país")
	var sin_ley := 0
	for p in ["CHI", "ARG", "BRA", "URU", "PAR", "PER", "ECU", "COL", "VEN", "BOL", "ESP", "ENG", "ITA", "GER", "FRA", "JPN", "KOR", "KSA", "EGY", "MAR", "RSA", "AUS", "MEX", "USA"]:
		if LeyesPais.reglas(p).is_empty() or not Contratos.JORNADA.has(p):
			sin_ley += 1
	_comprobar(sin_ley == 0, "los 24 países del juego tienen reglas de liga y jornada (%d sin)" % sin_ley)


## INCUMPLIR LA LEY SE PAGA (7-10-2026): multas que crecen y, desde la
## tercera alineación indebida, puntos menos.
func _probar_incumplir_ley() -> void:
	_titulo("LEYES POR PAÍS: INCUMPLIR A CAMBIO DE MULTAS")
	var m := Mundo.new()
	m.generar(["CHI"], 7311)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var mi := m.mi_club()
	mi.saldo = 500000000
	## Seis extranjeros en el once elegido (Chile permite 5 en cancha).
	var once := mi.once()
	var ids: Array[String] = []
	for k in once.size():
		if k >= 1 and k <= 7:
			once[k].pais = "ARG"
		ids.append(once[k].id)
	mi.once_elegido = ids
	var cuenta := 0
	for j: Jugador in mi.once():
		if j.pais != "CHI":
			cuenta += 1
	_comprobar(cuenta <= 5, "cumpliendo, el once se corrige solo (%d extranjeros)" % cuenta)
	mi.ley_politica = "incumplir"
	var cuenta2 := 0
	for j: Jugador in mi.once():
		if j.pais != "CHI":
			cuenta2 += 1
	var elegido := 0
	for k in once.size():
		if once[k].pais != "CHI":
			elegido += 1
	_comprobar(cuenta2 == elegido and cuenta2 > 5, "incumpliendo, sale el once que elegiste (%d extranjeros)" % cuenta2)
	var liga: Liga = null
	for l: Liga in m.ligas:
		if l.clubes.has(mi):
			liga = l
	var pts0 := int(liga.tabla_puntos[mi.id]["pts"])
	var s0 := mi.saldo
	m.federacion.revisar_leyes_pais(m, mi)
	var multa1 := s0 - mi.saldo
	m.federacion.revisar_leyes_pais(m, mi)
	var multa2 := s0 - mi.saldo - multa1
	m.federacion.revisar_leyes_pais(m, mi)
	_comprobar(multa1 > 0 and multa2 > multa1, "la multa crece al reincidir (%d → %d)" % [multa1, multa2])
	_comprobar(int(liga.tabla_puntos[mi.id]["pts"]) == pts0 - 3, "a la tercera alineación indebida, 3 puntos menos")
	_comprobar(int(m.federacion.infracciones_de(m.anio)["alin"]) == 3, "las infracciones se cuentan por temporada")
	## Plantel: incumpliendo se puede fichar por encima del cupo.
	var j_ext := Jugador.new()
	j_ext.pais = "BRA"
	_comprobar(m.federacion.puede_fichar_extranjero(mi, j_ext) == "", "incumpliendo, el mercado te deja pasarte del cupo")
	mi.ley_politica = "cumplir"
	_comprobar(m.federacion.puede_fichar_extranjero(mi, j_ext) != "", "cumpliendo, no (7 extranjeros, cupo 6)")
	mi.ley_politica = "incumplir"
	_comprobar(Partida._dic_a_club(Partida._club_a_dic(mi)).ley_politica == "incumplir", "la política se guarda con la partida")

func _probar_b6_formas_led() -> void:
	_titulo("B6: FORMAS NUEVAS DE ESTADIO Y COLORES DE LAS LED")
	var g := StadiumBuilder.geom_de_forma("dos")
	_comprobar(0 in g["abiertas"] and 1 in g["abiertas"], "«dos tribunas» deja abiertos los dos fondos")
	_comprobar(int(StadiumBuilder.geom_de_forma("principal").get("principal", -1)) == 2,
		"«tribuna de honor» agranda el lateral de los banquillos")
	var ep := EstadioPropio.new()
	var formas: Array = ep.opciones("forma").map(func(o): return o["clave"])
	_comprobar("dos" in formas and "principal" in formas, "las formas nuevas salen en el diseñador")
	ep.ajustes["forma"] = "dos"
	_comprobar(ep.ambiente() < 0, "sin fondos el estadio hace menos ruido (%d)" % ep.ambiente())
	var leds: Array = ep.opciones("ledPaleta").map(func(o): return o["clave"])
	_comprobar(leds.size() >= 7 and "arcoiris" in leds, "7 paletas de LED en el diseñador")
	var neon := StadiumBuilder._anuncios_de({"ledPaleta": "neon"}, null)
	_comprobar(neon.all(func(a): return (a["fondo"] as Color).get_luminance() < 0.1), "neón: paneles negros")
	var propia := StadiumBuilder._anuncios_de({"ledFondo": "#6b2d8f", "ledTinta": "#e8c21a"}, null)
	_comprobar(propia.all(func(a): return a["fondo"] == Color("#6b2d8f") and a["tinta"] == Color("#e8c21a")),
		"colores elegidos a mano: fondo y letra")
	var solo_fondo := StadiumBuilder._anuncios_de({"ledFondo": "#ffffff"}, null)
	_comprobar(solo_fondo.all(func(a): return (a["tinta"] as Color).get_luminance() < 0.3),
		"solo fondo blanco: la letra se oscurece sola")

func _probar_region_reales() -> void:
	_titulo("REGIÓN REAL: VASCOS FUERA DEL ATHLETIC")
	var antes := Datos.usar_base_real(true)
	Reales.invalidar()
	var m := Mundo.new()
	m.generar(["ESP"], 4242)
	var ath: Club = null
	var vascos := 0
	var falsos := 0
	for c: Club in m.clubes.values():
		if Nombres.limpiar(c.nombre) == "Ath. Bilbao":
			ath = c
		for j: Jugador in c.plantilla:
			if not j.real:
				continue
			## Con la cubierta de nombres, algún apellido sale en minúscula.
			var n := Nombres.limpiar(j.nombre).to_lower()
			if n in ["mikel oyarzabal", "martín zubimendi", "aimar oroz"]:
				if j.region == "EUS":
					vascos += 1
			elif n in ["pedri", "koke", "iago aspas", "isco"] and j.region != "":
				falsos += 1
	_comprobar(vascos >= 3, "Oyarzabal, Zubimendi y Oroz son de Euskal Herria (%d)" % vascos)
	_comprobar(falsos == 0, "los reales de otras regiones no heredan una región sorteada")
	if ath != null:
		var oya: Jugador = null
		for c: Club in m.clubes.values():
			for j: Jugador in c.plantilla:
				if Nombres.limpiar(j.nombre).to_lower() == "mikel oyarzabal":
					oya = j
		_comprobar(oya != null and Regiones.admite(ath, oya), "el Athletic puede fichar a Oyarzabal")
	Datos.usar_base_real(antes)
	Reales.invalidar()

func _probar_tunel_navegable() -> void:
	_titulo("TÚNEL DE VERDAD Y ESTADIO A PIE")
	var t: Array = StadiumBuilder._tramos_sin_hueco(0.0, 100.0, -3.2, 3.2)
	_comprobar(t.size() == 2 and is_equal_approx((t[0] as Vector2).y + (t[1] as Vector2).y, 93.6), "el hueco parte la bandeja en dos trozos")
	_comprobar(StadiumBuilder._tramos_sin_hueco(0.0, 10.0, 20.0, 26.0).size() == 1, "si el hueco no la toca, queda entera")
	## En las 8 formas y con túnel central y de esquina: del vestuario se llega
	## caminando al centro del campo.
	var fallos := []
	for forma: String in ["cuenco", "oval", "rect", "caldera", "herradura", "ingles", "dos", "principal"]:
		for tunel: String in ["central", "esquina"]:
			var est := {"forma": forma, "tunel": tunel}
			var ex := ExploradorEstadio.new()
			ex._datos = TunelVestuario.datos(est, 2)
			ex.zonas = ex._datos["zonas"]
			ex.cuerpo = Node3D.new()
			ex.cuerpo.position = ex._datos["inicio"]
			ex.rumbo = PI
			## Hacia el eje del túnel y luego recto al campo.
			var x0: float = ex._datos["x0"]
			for i in 400:
				var p: Vector3 = ex.cuerpo.position
				## Al eje del túnel, recto por él hasta la cancha y luego al centro.
				var objetivo := Vector3(x0 * 0.5, 0, 0.0)
				if p.z > float(ex._datos["z_out"]):
					objetivo = Vector3(x0, 0, float(ex._datos["z_out"]) - 1.0)
				elif p.z > 52.0:
					objetivo = Vector3(x0, 0, 50.0)
				var dir := (objetivo - p)
				dir.y = 0
				ex.rumbo = atan2(dir.x, dir.z)
				ex.paso(Vector2(0, 1), true, 1.0 / 10.0)
			if ex.zona_en(ex.cuerpo.position).get("nombre", "") != "Campo" or ex.cuerpo.position.z > 30.0:
				fallos.append("%s/%s z=%.1f" % [forma, tunel, ex.cuerpo.position.z])
			ex.cuerpo.free()
			ex.free()
	_comprobar(fallos.is_empty(), "del vestuario al campo a pie en las 8 formas %s" % str(fallos))
	## Fuera de las zonas no se puede pisar (la grada, por ejemplo).
	var ex2 := ExploradorEstadio.new()
	ex2.zonas = TunelVestuario.datos({"forma": "cuenco"}, 2)["zonas"]
	_comprobar(ex2.zona_en(Vector3(20, 0, 64)).is_empty(), "la grada no se pisa")
	ex2.free()
	## El estadio se construye con el pasillo y el vestuario.
	var raiz := Node3D.new()
	StadiumBuilder.build(raiz, {"forma": "cuenco", "niveles": 2}, 30000, 0.8, 7)
	var tv := raiz.get_node_or_null("TunelVestuario")
	var cuerpos := 0
	if tv != null:
		for h in tv.get_children():
			if h is StaticBody3D:
				cuerpos += 1
	_comprobar(tv != null and cuerpos >= 10, "el túnel y el vestuario tienen colisión (%d piezas)" % cuerpos)
	raiz.free()

func _probar_edificio_club() -> void:
	_titulo("ESTADIO 2.0: EL EDIFICIO DEL CLUB POR PLANTAS")
	var d := TunelVestuario.datos({"forma": "cuenco"}, 2)
	var zonas: Array = d["zonas"]
	var x0: float = d["x0"]
	var sin_asc := []
	for p in EdificioClub.plantas():
		var hay := false
		for z: Dictionary in zonas:
			if int(z.get("planta", 0)) == p and String(z["nombre"]) == "Ascensor":
				hay = true
		if not hay:
			sin_asc.append(p)
	_comprobar(sin_asc.is_empty(), "ascensor en las 5 plantas %s" % str(sin_asc))
	## Cada sala: se pisa su centro, y desde su puerta se llega al pasillo.
	var mal := []
	var z_tab: float = float(d["z_fin"]) - EdificioClub.PASILLO - 0.1
	for f: Array in EdificioClub.PLANTAS:
		for sala: Array in f[2]:
			var c := x0 + (float(sala[1]) + float(sala[2])) / 2.0
			var centro := Vector3(c, 0, (float(d["z_out"]) + z_tab) / 2.0)
			if String(TunelVestuario.zona_en(zonas, centro, int(f[0])).get("nombre", "")) != String(sala[0]):
				mal.append(String(sala[0]))
			## Del centro de la sala al pasillo, recto por la puerta.
			var z := centro.z
			var ok := true
			while z < z_tab + 0.8:
				if TunelVestuario.zona_en(zonas, Vector3(c, 0, z), int(f[0])).is_empty():
					ok = false
					break
				z += 0.2
			if not ok:
				mal.append(String(sala[0]) + " (puerta)")
	_comprobar(mal.is_empty(), "las 11 salas se pisan y se sale al pasillo %s" % str(mal))
	## Sin plantilla a mano, las taquillas no inventan nombres.
	var antes := EdificioClub.ctx
	EdificioClub.ctx = {"plantilla": [[10, "Prueba Diez"]]}
	var raiz := Node3D.new()
	TunelVestuario.montar(raiz, {"forma": "cuenco", "club_nombre": "Mi Club"}, 2, null)
	var con_nombre := false
	for n in raiz.find_children("*", "Label3D", true, false):
		if (n as Label3D).text.contains("Prueba Diez"):
			con_nombre = true
	_comprobar(con_nombre, "la taquilla lleva el dorsal y el nombre del jugador")
	_comprobar(raiz.find_child("EdificioClub", true, false) != null, "el edificio del club se construye")
	raiz.free()
	EdificioClub.ctx = antes

func _probar_personal_estadio() -> void:
	_titulo("ESTADIO 2.0: LA GENTE DEL CLUB EN SU PUESTO")
	var d := TunelVestuario.datos({"forma": "cuenco"}, 2)
	var pe := PersonalEstadio.new()
	pe.preparar(d, Color.RED, Color.WHITE)
	var mal := []
	for clave: String in PersonalEstadio.PUESTOS:
		var p: Array = PersonalEstadio.PUESTOS[clave]
		var ruta := pe._ruta(clave, int(p[0]), String(p[1]))
		if ruta.size() < 2:
			mal.append(clave + " sin ruta")
			continue
		## Cada tramo de la rutina se camina sin salir de las zonas.
		for i in range(ruta.size() - 1):
			var a: Vector3 = ruta[i]
			var b: Vector3 = ruta[i + 1]
			for k in 11:
				var q := a.lerp(b, float(k) / 10.0)
				## El portero y el hincha trabajan FUERA, en la acera de la
				## entrada: ni dentro del edificio ni dentro de la garita.
				if clave in ["portero", "hincha"]:
					var rg := EntradaClub.rect_garita(float(d["x0"]), float(d["z_fin"]))
					if q.z < float(d["z_fin"]) + 0.4 or rg.grow(0.3).has_point(Vector2(q.x, q.z)):
						mal.append("%s tramo %d" % [clave, i])
						break
				elif TunelVestuario.zona_en(d["zonas"], q, int(p[0])).is_empty():
					mal.append("%s tramo %d" % [clave, i])
					break
	_comprobar(mal.is_empty(), "las %d personas tienen puesto y rutina en su sitio %s" % [PersonalEstadio.PUESTOS.size(), str(mal)])
	_comprobar(PersonalEstadio.PUESTOS.has("portero"), "hay portero en la entrada del club")
	_comprobar(String(PersonalEstadio.PUESTOS["utilero"][1]) == "Utilería" and String(PersonalEstadio.PUESTOS["presidente"][1]) == "Despacho del presidente",
		"el utilero en la utilería y el presidente en su despacho")
	pe.free()

func _probar_sancion_dt() -> void:
	_titulo("ESTADIO 2.0: SANCIÓN AL DT Y LA GRADA")
	var m := Mundo.new()
	m.generar(["CHI"], 515)
	var f := m.federacion
	f.sancionar_dt(2)
	_comprobar(not f.dt_sancionado(), "el partido de la expulsión no cuenta como sanción")
	f.cumplir_sancion_dt()
	_comprobar(f.dt_sancionado() and f.dt_suspension == 2, "los dos siguientes, desde la grada (%d)" % f.dt_suspension)
	f.cumplir_sancion_dt()
	f.cumplir_sancion_dt()
	_comprobar(not f.dt_sancionado() and f.dt_suspension == 0, "cumplida, vuelve a la banda")
	f.sancionar_dt(1)
	var f2 := Federacion.new()
	f2.desde_dic(f.a_dic())
	_comprobar(f2.dt_suspension == 1 and f2.dt_susp_nueva, "la sanción se guarda con la partida")
	var b := RecorridoClub.butaca({"forma": "cuenco"}, 1.0, 10.0)
	_comprobar((b["pos"] as Vector3).x > 43.5 and (b["pos"] as Vector3).y > 2.0, "la butaca está en la primera bandeja de la grada")
	_comprobar(RecorridoClub.junto_a_la_grada(Vector3(35, 0, 0), 0) and not RecorridoClub.junto_a_la_grada(Vector3(0, 0, 0), 0), "solo se sienta uno desde la banda")
	## 21-10: los pasillos de la grada y la cinta LED existen. (La butaca real y
	## el hincha que se aparta se comprueban con pantalla: sin ella, Godot no
	## guarda las posiciones de los MultiMesh — `captura_sentarse`.)
	var raiz_b := Node3D.new()
	add_child(raiz_b)
	StadiumBuilder.build(raiz_b, {"forma": "cuenco", "niveles": 2}, 30000, 0.9, 7)
	_comprobar(raiz_b.find_children("Pasillos", "MultiMeshInstance3D", true, false).size() >= 4
		and raiz_b.find_children("Barandillas", "MultiMeshInstance3D", true, false).size() >= 4, "la grada tiene pasillos con escalera y barandilla")
	_comprobar(raiz_b.find_children("CintaLED", "MeshInstance3D", true, false).size() >= 1, "el peto de la bandeja de arriba lleva cinta LED")
	raiz_b.free()

func _probar_interiores_club() -> void:
	_titulo("ESTADIO 2.0: DECORAR LAS SALAS")
	var it := InterioresClub.new()
	it.pintar("Oficina del DT", "pared", "1f3f6b")
	_comprobar(it.poner("Oficina del DT", "bufanda"), "en tu oficina caben tus objetos propios")
	_comprobar(not it.poner("Sala de prensa", "bufanda"), "tu bufanda no va a la sala de prensa")
	for k in 6:
		it.poner("Museo del club", "planta")
	_comprobar(not it.poner("Museo del club", "sofa"), "seis huecos por sala, ni uno más")
	it.quitar_ultima("Museo del club")
	_comprobar((it.sala("Museo del club")["deco"] as Array).count("planta") == 5, "se quita el último objeto")
	it.colgar("Oficina del DT", "user://fotos/foto_x.png")
	var m := Mundo.new()
	m.generar(["CHI"], 616)
	m.interiores = it
	var m2 := Mundo.new()
	m2.generar(["CHI"], 616)
	m2.interiores.desde_dic(m.interiores.a_dic())
	_comprobar(String(m2.interiores.sala("Oficina del DT")["pared"]) == "1f3f6b" and (m2.interiores.sala("Oficina del DT")["fotos"] as Array).has("user://fotos/foto_x.png"),
		"la decoración y las fotos se guardan con la partida")
	## El edificio la pinta: con decoración hay más piezas que sin ella.
	EdificioClub.ctx = {"interiores": InterioresClub.new()}
	var r1 := Node3D.new()
	EdificioClub.montar(r1, 0.0, 70.0, 83.0, Color.RED, Color.WHITE, StandardMaterial3D.new(), StandardMaterial3D.new(), "X")
	var antes := r1.find_children("*", "MeshInstance3D", true, false).size()
	EdificioClub.ctx = {"interiores": it}
	var r2 := Node3D.new()
	EdificioClub.montar(r2, 0.0, 70.0, 83.0, Color.RED, Color.WHITE, StandardMaterial3D.new(), StandardMaterial3D.new(), "X")
	var despues := r2.find_children("*", "MeshInstance3D", true, false).size()
	_comprobar(despues > antes, "el edificio pinta la decoración (%d → %d piezas)" % [antes, despues])
	r1.free()
	r2.free()
	EdificioClub.ctx = {}
