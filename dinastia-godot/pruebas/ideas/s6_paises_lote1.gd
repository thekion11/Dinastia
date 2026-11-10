extends BaseIdea
## SESIÓN 6 (26-10-2026), fila 26 s4, LOTE 1 de países jugables: Portugal, Holanda,
## Bélgica, Croacia y Dinamarca. Ligas y clubes ficticios en `datos/paises_extra.json`
## (Datos los suma encima de tablas.json), bolsas de nombres, reglas de plantel, copa,
## política, calendario, jornada, mapa, globo y monumentos. Comprueba que el mundo se
## genera con ellos, que aguanta 3 temporadas con 3 semillas y que nada se repite.

const LOTE := ["POR", "NED", "BEL", "CRO", "DEN"]

## (10-11) Desde las segundas divisiones (Portugal 18, Países Bajos 20…) un mundo trae más ligas y clubes que la primera división: se mide solo la primera.
func _primeras(m: Mundo) -> Array:
	var n := 0
	var clubes := 0
	for l: Liga in m.ligas:
		if l.div == 1:
			n += 1
			clubes += l.clubes.size()
	return [n, clubes]

func _esperadas() -> Array:
	var pl: Dictionary = Datos.tabla("PAISES_LIGAS")
	var clubes := 0
	for p: String in LOTE:
		clubes += (pl[p]["clubes"] as Array).size()
	return [LOTE.size(), clubes]

func _probar() -> void:
	_titulo("S6: PAÍSES JUGABLES, LOTE 1 (POR, NED, BEL, CRO, DEN)")
	var pl: Dictionary = Datos.tabla("PAISES_LIGAS")
	var ps: Dictionary = Datos.tabla("PAIS_SELECCION")
	var pools: Dictionary = Datos.tabla("POOLS_EU")
	var ucl: Array = (Datos.tabla("CONFED") as Dictionary)["ucl"]["paises"]
	var datos_ok := true
	var codigo_ok := true
	for p: String in LOTE:
		datos_ok = datos_ok and pl.has(p) and ps.has(p) and pools.has(p) and ucl.has(p) and (pl[p]["clubes"] as Array).size() >= 10 and (pl[p]["clubes"] as Array).size() % 2 == 0
		codigo_ok = codigo_ok and not LeyesPais.reglas(p).is_empty() and Copa.COPAS_POR_PAIS.has(p) and Politica.ESTRUCTURA.has(p) \
			and Contratos.JORNADA.has(p) and Calendario.FIJAS.has(p) and MapaPais.SILUETAS.has(p) and PaisDatos.MONUMENTOS.has(p) \
			and PaisDatos.OFICIAL.has(p) and Globo3D.CAPITAL.has(p) and Paises.conocido(p)
	_comprobar(datos_ok, "las tablas (liga de 16, selección, nombres, Champions) traen a los 5 (cada liga con su tamaño real, par: Croacia 10, Dinamarca 12, Bélgica 16, Países Bajos y Portugal 18)")
	_comprobar(codigo_ok, "y los datos de cada sistema: plantel, copa, política, jornada, fiestas, mapa, monumentos, globo")
	var europa: Array = []
	for fila: Array in PaisDatos.CONTINENTES:
		if String(fila[0]) == "Europa":
			europa = fila[1]
	_comprobar(LOTE.all(func(p: String) -> bool: return europa.has(p)), "se pueden elegir en la entrada (Europa)")
	## El mundo: 3 semillas × 3 temporadas.
	var sin_errores := true
	var duplicados := 0
	var ligas_ok := true
	var nombres_de_casa := true
	for semilla: int in [101, 202, 303]:
		var m := Mundo.new()
		m.generar(["POR", "NED", "BEL", "CRO", "DEN"], semilla)
		m.tomar_el_mando(m.ligas[0].clubes[0].id)
		ligas_ok = ligas_ok and _primeras(m) == _esperadas()
		var vistos := {}
		for c: Club in m.clubes.values():
			if vistos.has(c.nombre):
				duplicados += 1
			vistos[c.nombre] = true
		## Un jugador portugués se llama como un portugués (bolsa de POR).
		var por: Club = null
		for c2: Club in m.clubes.values():
			if c2.pais == "POR":
				por = c2
				break
		var bolsas: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string("res://datos/bolsas_nombres.json")) as Dictionary)["bolsas"]
		var pool_por: Array = (pools["POR"][1] as Array) + (bolsas["POR"][1] as Array)
		var de_casa := 0
		for j: Jugador in por.plantilla:
			if j.pais == "POR":
				for ap: String in pool_por:
					if j.nombre.ends_with(ap):
						de_casa += 1
						break
		nombres_de_casa = nombres_de_casa and de_casa >= por.plantilla.size() / 2
		var anio0 := m.anio
		for t in 3:
			m.jugar_temporada()
			m.nueva_temporada()
		sin_errores = sin_errores and _primeras(m) == _esperadas() and m.anio == anio0 + 3
	_comprobar(ligas_ok, "cada mundo trae las 5 primeras divisiones con sus clubes de la tabla (%s)" % str(_esperadas()))
	_comprobar(duplicados == 0, "ningún club repetido")
	_comprobar(nombres_de_casa, "los portugueses llevan apellidos portugueses")
	_comprobar(sin_errores, "3 semillas × 3 temporadas sin romperse")
