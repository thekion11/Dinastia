extends "res://pruebas/banco/base.gd"
## [Banco · grupo «paises_csv»] Países importados desde una tabla (`herramientas/importar_pais.py`): TUR, SCO, SUI, AUT, GRE y QAT (sesión 6, 10-11).

const ESPERADOS := {"TUR": 18, "SCO": 12, "SUI": 12, "AUT": 12, "GRE": 14, "QAT": 12, "SWE": 16, "NOR": 16, "POL": 18, "CZE": 16, "ROU": 16, "SRB": 16, "UKR": 16, "CHN": 16, "ISR": 14, "RUS": 16, "HUN": 12, "SVK": 12, "BUL": 16, "UAE": 14, "IRN": 16, "VEN": 14}

func _probar_paises_csv() -> void:
	_titulo("PAÍSES DESDE UNA TABLA: TUR, SCO, SUI, AUT, GRE Y QAT")
	var codigos: Array[String] = ["TUR", "SCO", "SUI", "AUT", "GRE", "QAT", "SWE", "NOR", "POL", "CZE", "ROU", "SRB", "UKR", "CHN", "ISR", "RUS", "HUN", "SVK", "BUL", "UAE", "IRN", "VEN", "CHI", "ESP", "POR", "DEN"]
	var m := Mundo.new()
	m.generar(codigos, 701)
	for p: String in ESPERADOS:
		var liga: Liga = null
		for l: Liga in m.ligas:
			if l.pais == p and l.division() == 1:
				liga = l
		_comprobar(liga != null and liga.clubes.size() == int(ESPERADOS[p]), "%s: liga con sus %d clubes reales (%d)" % [p, int(ESPERADOS[p]), liga.clubes.size() if liga else 0])
		_comprobar(Datos.tabla("PAIS_SELECCION").has(p) and Datos.tabla("TIER_PAIS").has(p) and Datos.tabla("GLOBO_PAIS").has(p), "%s: selección, nivel y lugar en el globo" % p)
	var completos := true
	var faltas: Array[String] = []
	for p: String in ESPERADOS:
		var checks := {"reglas": not LeyesPais.reglas(p).is_empty(), "copa": Copa.COPAS_POR_PAIS.has(p), "política": Politica.ESTRUCTURA.has(p),
			"jornada": Contratos.JORNADA.has(p), "fiestas": Calendario.FIJAS.has(p), "silueta": MapaPais.SILUETAS.has(p), "monumentos": PaisDatos.MONUMENTOS.has(p),
			"oficial": PaisDatos.OFICIAL.has(p), "capital": Globo3D.CAPITAL.has(p), "globo": Globo3D.GLOBO_PAIS.has(p),
			"bandera": (Banderas.ISO.has(p) and ResourceLoader.exists("res://assets/banderas/%s.svg" % Banderas.ISO.get(p, "xx"))) or (["CHN", "RUS", "UAE"].has(p) and Banderas.textura(p) != null),
			"país": Paises.conocido(p)}
		for k: String in checks:
			if not bool(checks[k]):
				faltas.append("%s:%s" % [p, k])
				completos = false
	_comprobar(completos, "los países nuevos tienen: reglas de extranjeros, copa, política, jornada, fiestas, silueta, monumentos, nombre oficial, globo y bandera (faltan: %s)" % str(faltas))
	var europa: Array = []
	var asia: Array = []
	for fila: Array in PaisDatos.CONTINENTES:
		if String(fila[0]) == "Europa":
			europa = fila[1]
		if String(fila[0]) == "Asia":
			asia = fila[1]
	_comprobar(["TUR", "SCO", "SUI", "AUT", "GRE", "SWE", "NOR", "POL", "CZE", "ROU", "SRB", "UKR", "ISR", "RUS", "HUN", "SVK", "BUL"].all(func(p: String) -> bool: return europa.has(p)) and asia.has("QAT") and asia.has("CHN") and asia.has("UAE") and asia.has("IRN"), "se pueden elegir en la entrada (Europa y Asia)")
	var nombres := {}
	var repetidos := 0
	for c: Club in m.clubes.values():
		if nombres.has(c.nombre):
			repetidos += 1
		nombres[c.nombre] = true
	_comprobar(repetidos == 0, "ningún nombre de club repetido en el mundo (%d)" % repetidos)
	## Las copas continentales: cada país europeo nuevo tiene sus cupos y Catar entra en Asia.
	var plazas := Continental.plazas(m.clubes.values(), m.ligas, null)
	var paises_ucl := {}
	for c: Club in plazas["ucl"]:
		paises_ucl[c.pais] = int(paises_ucl.get(c.pais, 0)) + 1
	_comprobar(plazas["ucl"].size() == 36 and int(paises_ucl.get("ESP", 0)) >= 5 and int(paises_ucl.get("TUR", 0)) >= 1 and int(paises_ucl.get("GRE", 0)) >= 1, "Champions: 36 clubes, ESP 5+ y TUR/GRE con plaza (%s)" % str(paises_ucl))
	var qat_asia := 0
	for c: Club in plazas["asia"]:
		if c.pais == "QAT":
			qat_asia += 1
	_comprobar(qat_asia >= 1, "Catar manda clubes a la Copa Asiática (%d)" % qat_asia)
	var europeos := 0
	for k: String in ["ucl", "uel", "uecl"]:
		for c: Club in plazas[k]:
			if ["TUR", "SCO", "SUI", "AUT", "GRE", "SWE", "NOR", "POL", "CZE", "ROU", "SRB", "UKR", "ISR", "HUN", "SVK", "BUL"].has(c.pais):
				europeos += 1
	_comprobar(europeos >= 18, "los cinco europeos nuevos juegan competiciones de la UEFA (%d plazas)" % europeos)
	## Una temporada entera se juega: todos tienen partidos y la media de goles es normal.
	var goles := 0
	var partidos := 0
	for sem in 20:
		m.avanzar_semana()
	var otros_goles := 0
	var otros_partidos := 0
	for l: Liga in m.ligas:
		for id: String in l.tabla_puntos:
			if ESPERADOS.has(l.pais):
				partidos += int(l.tabla_puntos[id]["pj"])
				goles += int(l.tabla_puntos[id]["gf"])
			elif l.division() == 1:
				otros_partidos += int(l.tabla_puntos[id]["pj"])
				otros_goles += int(l.tabla_puntos[id]["gf"])
	var media := float(goles) / maxf(1.0, float(partidos) / 2.0)
	var media_otros := float(otros_goles) / maxf(1.0, float(otros_partidos) / 2.0)
	_comprobar(partidos > 0 and absf(media - media_otros) < 0.8, "las ligas nuevas no suben los goles: %.2f frente a %.2f de las primeras de CHI, ESP, POR y DEN" % [media, media_otros])

## Las selecciones de los países nuevos (sesión 6, 10-11): existen en el escalafón, se convocan y entran en los torneos que les tocan (Rusia, suspendida, en ninguno).
func _probar_selecciones_nuevas() -> void:
	_titulo("SELECCIONES DE LOS PAÍSES NUEVOS: ESCALAFÓN, CONVOCATORIA Y TORNEOS")
	var nombres := {"ISR": "Israel", "ROU": "Rumanía", "SVK": "Eslovaquia", "BUL": "Bulgaria", "CHN": "China", "RUS": "Rusia", "CZE": "Rep. Checa", "UAE": "Emiratos", "SWE": "Suecia", "TUR": "Turquía", "IRN": "Irán"}
	var lista: Array = Datos.tabla("SELECCIONES")
	var en_lista := true
	var cod_ok := true
	for cod: String in nombres:
		en_lista = en_lista and lista.has(nombres[cod])
		cod_ok = cod_ok and SeleccionEquipo.codigo_de(String(nombres[cod])) == cod
	_comprobar(en_lista, "las 11 están en la lista de selecciones (%d en total)" % lista.size())
	_comprobar(cod_ok, "y cada nombre devuelve su país")
	var m := Mundo.new()
	var paises: Array[String] = ["ISR", "ROU", "SVK", "BUL", "CHN", "RUS", "CZE", "UAE", "SWE", "TUR", "IRN", "CHI", "ESP"]
	m.generar(paises, 901)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var sel := Selecciones.new(m)
	var fuerzas := nombres.values().all(func(n: String) -> bool: return sel.fuerza(n) >= 70 and sel.fuerza(n) <= 99)
	_comprobar(fuerzas, "todas tienen fuerza en el escalafón")
	var ranking := sel.ranking(0)
	var en_rank := nombres.values().all(func(n: String) -> bool: return ranking.any(func(f: Dictionary) -> bool: return String(f["nombre"]) == n))
	_comprobar(en_rank and ranking.size() >= 69, "el escalafón las incluye (%d selecciones)" % ranking.size())
	for n: String in ["Rumanía", "China", "Rusia", "Rep. Checa"]:
		var club := SeleccionEquipo.club_de(m, n, sel.fuerza(n), 2026)
		_comprobar(club.plantilla.size() >= 20 and club.pais == SeleccionEquipo.codigo_de(n), "%s: convocatoria de %d jugadores (%d de su país en el juego)" % [n, club.plantilla.size(), SeleccionEquipo.candidatos(m, n).size()])
	var mundial := SeleccionesTorneos.mundial(sel, m, 2026)
	var mundial_nombres: Array = mundial.equipos.map(func(c: Club) -> String: return c.nombre)
	_comprobar(mundial.equipos.size() == 48 and not mundial_nombres.has("Rusia"), "Mundial de 48 sin Rusia (%d equipos)" % mundial.equipos.size())
	var euro := SeleccionesTorneos.continental(sel, m, "ucl", "Eurocopa", 2028).equipos.map(func(c: Club) -> String: return c.nombre)
	_comprobar(["Rumanía", "Eslovaquia", "Bulgaria", "Israel", "Rep. Checa", "Turquía"].all(func(n: String) -> bool: return euro.has(n)) and not euro.has("Rusia"), "la Eurocopa lleva a Rumanía, Eslovaquia, Bulgaria, Israel, Rep. Checa y Turquía, y no a Rusia (%d)" % euro.size())
	var asia := SeleccionesTorneos.continental(sel, m, "asia", "Copa de Asia", 2027).equipos.map(func(c: Club) -> String: return c.nombre)
	_comprobar(["China", "Emiratos", "Irán"].all(func(n: String) -> bool: return asia.has(n)), "la Copa de Asia lleva a China, Emiratos e Irán (%d)" % asia.size())

## (10-11) TANDA 1 DE «PAÍSES SIN LIGA»: NGA, GHA, SEN, CIV, ALG, TUN, CMR, CAN, CRC, IRL (las selecciones que tenían 0 convocables). Su liga con la cantidad real de clubes, su copa,
## su confederación y sus selecciones con jugadores del mundo de verdad (antes: plantilla inventada).
func _probar_pais_sin_liga_tanda1() -> void:
	_titulo("PAÍSES SIN LIGA, TANDA 1: LIGA, COPA, CONFEDERACIÓN Y SELECCIÓN")
	_comprobar_tanda({"NGA": [20, "Nigeria", "afr"], "GHA": [18, "Ghana", "afr"], "SEN": [16, "Senegal", "afr"], "CIV": [14, "Costa de Marfil", "afr"], "ALG": [16, "Argelia", "afr"],
		"TUN": [16, "Túnez", "afr"], "CMR": [16, "Camerún", "afr"], "CAN": [8, "Canadá", "conc"], "CRC": [12, "Costa Rica", "conc"], "IRL": [10, "Irlanda", "ucl"]}, 1103)

## (10-11) TANDA 2: las 9 selecciones que seguían con 0 convocables (Gales, Honduras, Irak, Jamaica, Jordania, Malí, N. Zelanda, Panamá, Uzbekistán) más Finlandia, Eslovenia y Chipre.
## Listas de clubes de Wikipedia 2025-26 (Malí: la de 2021-22, sin verificar).
func _probar_pais_sin_liga_tanda2() -> void:
	_titulo("PAÍSES SIN LIGA, TANDA 2: LIGA, COPA, CONFEDERACIÓN Y SELECCIÓN")
	_comprobar_tanda({"WAL": [12, "Gales", "ucl"], "SVN": [10, "Eslovenia", "ucl"], "JOR": [10, "Jordania", "asia"], "CYP": [14, "Chipre", "ucl"], "IRQ": [20, "Irak", "asia"], "UZB": [16, "Uzbekistán", "asia"],
		"FIN": [12, "Finlandia", "ucl"], "JAM": [14, "Jamaica", "conc"], "HON": [11, "Honduras", "conc"], "PAN": [12, "Panamá", "conc"], "NZL": [11, "N. Zelanda", "oce"], "MLI": [18, "Malí", "afr"]}, 1104)

## (10-11) TANDA 3: 14 países de la UEFA (Bosnia, Montenegro, Islandia, Estonia, Kazajistán, Azerbaiyán, Bielorrusia, Letonia, Albania, Macedonia del Norte, Georgia, Lituania, Irlanda del Norte, Luxemburgo).
## Listas de clubes de Wikipedia 2025-26 / 2026. Bielorrusia NO está suspendida (solo vetada como local) y entra en los torneos como cualquier otra.
func _probar_pais_sin_liga_tanda3() -> void:
	_titulo("PAÍSES SIN LIGA, TANDA 3: LIGA, COPA, CONFEDERACIÓN Y SELECCIÓN")
	_comprobar_tanda({"BIH": [10, "Bosnia", "ucl"], "MNE": [10, "Montenegro", "ucl"], "ISL": [12, "Islandia", "ucl"], "EST": [10, "Estonia", "ucl"], "KAZ": [16, "Kazajistán", "ucl"], "AZE": [12, "Azerbaiyán", "ucl"],
		"BLR": [16, "Bielorrusia", "ucl"], "LVA": [10, "Letonia", "ucl"], "ALB": [10, "Albania", "ucl"], "MKD": [12, "Macedonia del Norte", "ucl"], "GEO": [10, "Georgia", "ucl"], "LTU": [10, "Lituania", "ucl"],
		"NIR": [12, "Irlanda del Norte", "ucl"], "LUX": [16, "Luxemburgo", "ucl"]}, 1105)
	_comprobar(not SeleccionesTorneos.SUSPENDIDAS.has("Bielorrusia"), "Bielorrusia no está suspendida (solo vetada como local)")

## (10-11) TANDA 4: 16 países de Asia, África, UEFA y CONCACAF (Tailandia, Indonesia, Vietnam, India, Malasia, Baréin, Omán, RD Congo, Burkina Faso, Zambia, Guinea, Kenia, Armenia, Moldavia, El Salvador, Guatemala).
## Listas de Wikipedia 2025-26 (Omán, Guinea y Burkina Faso: listas viejas sin verificar; RD Congo: 16 de los 31 del Linafoot).
func _probar_pais_sin_liga_tanda4() -> void:
	_titulo("PAÍSES SIN LIGA, TANDA 4: LIGA, COPA, CONFEDERACIÓN Y SELECCIÓN")
	_comprobar_tanda({"THA": [16, "Tailandia", "asia"], "IDN": [18, "Indonesia", "asia"], "VIE": [14, "Vietnam", "asia"], "IND": [14, "India", "asia"], "MAS": [13, "Malasia", "asia"], "BHR": [12, "Baréin", "asia"],
		"OMA": [12, "Omán", "asia"], "COD": [16, "RD Congo", "afr"], "BFA": [14, "Burkina Faso", "afr"], "ZAM": [18, "Zambia", "afr"], "GUI": [14, "Guinea", "afr"], "KEN": [18, "Kenia", "afr"],
		"ARM": [10, "Armenia", "ucl"], "MDA": [8, "Moldavia", "ucl"], "ESA": [12, "El Salvador", "conc"], "GUA": [12, "Guatemala", "conc"]}, 1106)

## Cada país del caso [clubes, selección, copa continental]: su liga con la cantidad real de clubes, su copa continental, su copa nacional, su selección y jugadores del mundo para convocar.
func _comprobar_tanda(casos: Dictionary, semilla: int) -> void:
	var m := Mundo.new()
	var paises: Array[String] = []
	paises.assign(casos.keys())
	m.generar(paises, semilla)
	var confed: Dictionary = Datos.tabla("CONFED") as Dictionary
	for cod: String in casos:
		var datos: Array = casos[cod]
		var clubes := 0
		for l: Liga in m.ligas:
			if l.pais == cod and l.division() == 1:
				clubes = l.clubes.size()
		_comprobar(clubes == int(datos[0]), "%s: la liga tiene su cantidad real de clubes (%d de %d)" % [cod, clubes, int(datos[0])])
		_comprobar((confed[String(datos[2])]["paises"] as Array).has(cod), "%s: juega la copa continental «%s»" % [cod, String(datos[2])])
		_comprobar(String((Datos.tabla("COPA_NOM") as Dictionary).get(cod, "")) != "" and SeleccionEquipo.codigo_de(String(datos[1])) == cod, "%s: tiene copa y su selección (%s) devuelve el país" % [cod, String(datos[1])])
		var cands := SeleccionEquipo.candidatos(m, String(datos[1])).size()
		_comprobar(cands >= 20, "%s: la selección de %s convoca con jugadores del mundo (%d candidatos, antes 0)" % [cod, String(datos[1]), cands])


## (10-11) LIGAS ACTIVAS: el juego solo carga los países elegidos. Mundos de 1, 2 y 5 países (y todos): tres temporadas sin errores, continentales con equipos, guardado/carga con la lista y AÑADIR países a mitad de partida.
func _probar_ligas_activas() -> void:
	_titulo("LIGAS ACTIVAS: MUNDOS PARCIALES, GUARDADO Y AÑADIR PAÍSES")
	var mio := LigasActivas.pais_del_dispositivo()
	var pc := LigasActivas.por_defecto(false)
	var movil := LigasActivas.por_defecto(true)
	_comprobar(LigasActivas.todos().size() >= 80 and pc.size() == 15 and pc[0] == mio and pc.has("CHI") and pc.has("ENG") and pc.has("BRA") and pc.has("USA"), "PC: los 15 principales con el país del dispositivo (%s) y Chile (%s)" % [mio, ",".join(pc)])
	_comprobar(movil[0] == mio and movil.size() <= 5 and ["ENG", "ESP", "ITA", "GER"].all(func(x: String) -> bool: return movil.has(x)), "móvil: el país del dispositivo y ENG, ESP, ITA, GER (%s)" % ",".join(movil))
	_comprobar(LigasActivas.es_entero(LigasActivas.todos()) and not LigasActivas.es_entero(pc), "«mundo entero» solo si están todos")
	var c_pc := LigasActivas.coste(LigasActivas.todos(), false)
	var c_mov := LigasActivas.coste(LigasActivas.todos(), true)
	_comprobar(int(c_pc["clubes"]) > 1500 and absf(float(c_mov["s_semana"]) - 3.0 * float(c_pc["s_semana"])) < 0.001 and float(c_pc["gb"]) > 1.5, "la estimación de coste del mundo entero: %d clubes, %.1f s/semana en PC, %.1f en móvil, %.1f GB" % [int(c_pc["clubes"]), float(c_pc["s_semana"]), float(c_mov["s_semana"]), float(c_pc["gb"])])
	for caso: Array in [["CHI"], ["BRA", "NGA"], ["ENG", "ESP", "ITA", "GER", "FRA"]]:
		var paises: Array[String] = []
		paises.assign(caso)
		var m := Mundo.new()
		m.generar(paises, 4242)
		var activos := LigasActivas.de(m)
		activos.sort()
		var esperados := paises.duplicate()
		esperados.sort()
		_comprobar(activos == esperados, "%s: el mundo solo carga esos países (%d clubes)" % [str(caso), m.clubes.size()])
		m.tomar_el_mando(m.ligas[0].clubes[3].id)
		var anio0 := m.anio
		for _t in 3:
			m.jugar_temporada()
			m.cerrar_temporada()
		_comprobar(m.anio == anio0 + 3 and not m.continentales.is_empty(), "%s: tres temporadas completas y con torneos continentales (%s)" % [str(caso), str(m.continentales.keys())])
		var m2 := Partida.desde_instantanea(JSON.parse_string(JSON.stringify(Partida.instantanea(m))))
		var act2 := LigasActivas.de(m2)
		act2.sort()
		_comprobar(act2 == esperados and m2.clubes.size() == m.clubes.size(), "%s: guardar y cargar conserva la lista de países" % str(caso))
	## AÑADIR países a mitad de partida (al cerrar la temporada): lo que ya existe no se mueve.
	var base: Array[String] = ["CHI"]
	var mb := Mundo.new()
	mb.generar(base, 4243)
	mb.tomar_el_mando(mb.ligas[0].clubes[2].id)
	mb.jugar_temporada()
	mb.cerrar_temporada()
	var ids_antes := mb.clubes.keys()
	var jugador_antes: String = (mb.clubes[ids_antes[0]] as Club).plantilla[0].id
	var antes := mb.clubes.size()
	var r := LigasActivas.agregar(mb, ["ENG", "NGA", "CHI", "XXX"])
	_comprobar((r["paises"] as Array).size() == 2 and mb.clubes.size() > antes, "añadir ENG y NGA (CHI ya estaba y XXX no existe): +%d clubes" % int(r["clubes"]))
	_comprobar(ids_antes.all(func(id: Variant) -> bool: return mb.clubes.has(id)) and (mb.clubes[ids_antes[0]] as Club).plantilla[0].id == jugador_antes, "los clubes y jugadores que ya existían conservan sus ids")
	var act := LigasActivas.de(mb)
	_comprobar(act.has("ENG") and act.has("NGA") and act.has("CHI") and LigasActivas.agregar(mb, ["ENG"])["clubes"] == 0, "la lista crece y añadir lo que ya está no hace nada")
	_comprobar(mb.continentales.has("afr") or mb.continentales.has("ucl"), "los continentales de los países nuevos entran en la temporada (%s)" % str(mb.continentales.keys()))
	mb.jugar_temporada()
	mb.cerrar_temporada()
	_comprobar(mb.anio >= 2028, "la temporada con los países añadidos se juega y se cierra sin errores")
	_comprobar(LigasActivas.faltan(mb).size() == LigasActivas.todos().size() - LigasActivas.de(mb).size(), "faltan (%d) = todos − activos" % LigasActivas.faltan(mb).size())

## Todos los países (86): generar (≈2 s), una temporada entera (≈40 s) y cerrarla, con todos los torneos continentales y los de la FIFA armados.
func _probar_ligas_activas_todos() -> void:
	_titulo("LIGAS ACTIVAS: TODOS LOS PAÍSES, UNA TEMPORADA COMPLETA")
	var m := Mundo.new()
	m.generar([] as Array[String], 4244)
	_comprobar(LigasActivas.de(m).size() == LigasActivas.todos().size() and LigasActivas.faltan(m).is_empty(), "todos los países cargados (%d, %d clubes)" % [LigasActivas.de(m).size(), m.clubes.size()])
	m.tomar_el_mando(m.ligas[0].clubes[3].id)
	var anio0 := m.anio
	m.jugar_temporada()
	m.cerrar_temporada()
	_comprobar(m.anio == anio0 + 1 and m.continentales.size() >= 8, "una temporada completa con los torneos continentales (%s)" % str(m.continentales.keys()))

## La pantalla «Ligas activas» (etapa de la entrada): casillas por país, atajos, resumen y confirmación. No toca el guardado real de la máquina (se restaura al terminar).
func _probar_ligas_activas_pantalla() -> void:
	_titulo("LIGAS ACTIVAS: LA PANTALLA")
	var cfg_previo := FileAccess.file_exists(LigasActivas.RUTA_ELECCION)
	var bytes_previos: PackedByteArray = FileAccess.get_file_as_bytes(LigasActivas.RUTA_ELECCION) if cfg_previo else PackedByteArray()
	var elegidas_previas := LigasActivas.elegidas.duplicate()
	DirAccess.remove_absolute(LigasActivas.RUTA_ELECCION)
	LigasActivas.elegidas.clear()
	var p := LigasActivasPantalla.new()
	add_child(p)
	var n_paises := LigasActivas.todos().size()
	var defecto := LigasActivas.por_defecto(OS.has_feature("mobile"))
	_comprobar(p._casillas.size() == n_paises and p.marcados().size() == defecto.size(), "una casilla por país (%d) y las de la plataforma marcadas (%d)" % [p._casillas.size(), p.marcados().size()])
	p._atajo("todas")
	_comprobar(p.marcados().size() == n_paises and "⚠" in p._resumen.text or OS.has_feature("mobile"), "«Mundo entero» marca todos y avisa del coste")
	p._atajo("defecto")
	_comprobar(p.marcados().size() == defecto.size() and defecto.all(func(x: String) -> bool: return p.marcados().has(x)), "«Por defecto» marca los de la plataforma (%s)" % ",".join(p.marcados()))
	p._atajo("ninguna")
	_comprobar(p.marcados().is_empty() and p._continuar.disabled, "sin ninguna marcada no se puede continuar")
	var recibido: Array = []
	p.terminado.connect(func(d: Dictionary) -> void: recibido.append(d))
	p.confirmar()
	_comprobar(recibido.is_empty(), "confirmar sin países no avanza")
	p._atajo("defecto")
	p.confirmar()
	var paises: Array = ((recibido[0] as Dictionary)["ligas"] as Dictionary)["paises"] if recibido.size() == 1 else []
	_comprobar(paises.size() == defecto.size() and ",".join(LigasActivas.elegidas) == ",".join(PackedStringArray(paises)), "confirmar devuelve {ligas: {paises}} y deja la elección en LigasActivas (%s)" % str(paises))
	_comprobar(",".join(LigasActivas.para_generar()) == ",".join(PackedStringArray(paises)), "el generador recibe la lista elegida")
	_comprobar(",".join(LigasActivas.cargar_eleccion()) == ",".join(PackedStringArray(paises)), "la elección se recuerda para la próxima partida")
	p.free()
	## Se deja la máquina como estaba.
	LigasActivas.elegidas.assign(elegidas_previas)
	if cfg_previo:
		var f := FileAccess.open(LigasActivas.RUTA_ELECCION, FileAccess.WRITE)
		f.store_buffer(bytes_previos)
		f.close()
	else:
		DirAccess.remove_absolute(LigasActivas.RUTA_ELECCION)

## La pantalla en modo AÑADIR (al cerrar la temporada): solo los países que faltan, sin tocar la elección guardada de la máquina.
func _probar_ligas_activas_agregar_pantalla() -> void:
	_titulo("LIGAS ACTIVAS: AÑADIR AL CERRAR LA TEMPORADA")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"] as Array[String], 4245)
	var antes := FileAccess.file_exists(LigasActivas.RUTA_ELECCION)
	var p := LigasActivasPantalla.new()
	p.mundo_agregar = m
	add_child(p)
	var faltan := LigasActivas.faltan(m)
	_comprobar(p._casillas.size() == faltan.size() and not p._casillas.has("CHI") and not p._casillas.has("ARG"), "solo se enseñan los países que faltan (%d)" % faltan.size())
	var recibido: Array = []
	p.terminado.connect(func(d: Dictionary) -> void: recibido.append(d))
	p.confirmar()
	_comprobar(recibido.size() == 1 and ((recibido[0] as Dictionary)["ligas"] as Dictionary)["paises"] == [], "sin marcar nada, «Añadir» equivale a «Ahora no»")
	p._atajo("todas")
	p.confirmar()
	_comprobar(recibido.size() == 2 and (((recibido[1] as Dictionary)["ligas"] as Dictionary)["paises"] as Array).size() == faltan.size(), "«Todas» devuelve los %d que faltan" % faltan.size())
	_comprobar(FileAccess.file_exists(LigasActivas.RUTA_ELECCION) == antes, "añadir no cambia la elección guardada de la máquina")
	p.free()
	var r := LigasActivas.agregar(m, ["ESP", "ENG"])
	_comprobar((r["paises"] as Array).size() == 2 and LigasActivas.de(m).has("ESP") and not LigasActivas.faltan(m).has("ENG"), "lo añadido deja de faltar")
