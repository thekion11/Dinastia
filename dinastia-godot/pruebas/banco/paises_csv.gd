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
