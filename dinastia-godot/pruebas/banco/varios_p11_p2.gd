extends "res://pruebas/banco/varios_p11_p1.gd"
## [Capa de `varios_p11.gd`] _probar_objetivos_por_club y sus tres secciones (paquetes, plazas y tamaño de la liga, cierre y en vivo).

func _probar_objetivos_por_club() -> void:
	_titulo("OBJETIVOS POR CLUB: PAQUETE PROPIO, CIERRE Y GUARDADO")
	_objetivos_paquetes()
	_objetivos_plazas_y_tamano()
	_objetivos_cierre_y_vivo()

func _objetivos_paquetes() -> void:
	var distintos := {}
	var mal: Array[String] = []
	var clubes := 0
	var metas_desc := {}
	for grupo: Array in [["CHI", "ESP", "ENG"], ["BRA", "JPN", "USA"], ["ARG", "GER", "MEX"]]:
		Partido.limpiar_contexto()
		var m := Mundo.new()
		var g: Array[String] = []
		g.assign(grupo)
		m.generar(g, 91 + clubes)
		for l: Liga in m.ligas:
			var n := l.clubes.size()
			var pl := ObjetivosClub.plazas_continentales(l.pais, n)
			for c: Club in l.clubes:
				_revisar_club(m, c, l, n, pl, mal, metas_desc, distintos)
				clubes += 1
	_comprobar(mal.is_empty(), "%d clubes de 9 países: meta dentro de su liga, salvarse = puesto seguro real, plazas continentales reales, 3-6 secundarios con peso y proyecto (%d fallos%s)" % [clubes, mal.size(), "" if mal.is_empty() else ": " + str(mal.slice(0, 3))])
	_comprobar(distintos.size() >= 8, "los paquetes se parecen poco entre clubes (%d combinaciones distintas)" % distintos.size())
	_comprobar(metas_desc.keys().size() < 2 or metas_desc.values().min() != metas_desc.values().max(), "«Evitar el descenso» cambia con el tamaño de la liga (%s)" % str(metas_desc))

## Un club: su paquete de objetivos tiene que cuadrar con su liga (meta, plazas y secundarios).
func _revisar_club(m: Mundo, c: Club, l: Liga, n: int, pl: Dictionary, mal: Array[String],
		metas_desc: Dictionary, distintos: Dictionary) -> void:
	var p := ObjetivosClub.generar(m, c)
	if p.is_empty():
		mal.append("%s sin paquete" % c.nombre)
		return
	var pr: Dictionary = p["principal"]
	var meta := int(pr["meta"])
	if meta < 1 or meta > n:
		mal.append("%s (%d clubes): meta %d" % [c.nombre, n, meta])
	if String(pr["texto"]) == "Evitar el descenso":
		metas_desc[n] = meta
		if meta != n - l.plazas_descenso:
			mal.append("%s: salvarse es el %d.º y la meta es %d" % [c.nombre, n - l.plazas_descenso, meta])
	if String(pr["texto"]).begins_with("Clasificar") and c.division == 1 and meta > int(pl["elite"]) + int(pl["segunda"]):
		mal.append("%s: pide %d plazas continentales y la liga da %d" % [c.nombre, meta, int(pl["elite"]) + int(pl["segunda"])])
	var sec: Array = p["secundarios"]
	if sec.size() < 3 or sec.size() > 6 or (p["proyecto"] as Dictionary).is_empty():
		mal.append("%s: %d secundarios o sin proyecto" % [c.nombre, sec.size()])
	var ids: Array = []
	for o: Dictionary in sec:
		ids.append(String(o["id"]))
		if int(o["peso"]) < 1 or int(o["peso"]) > 10:
			mal.append("%s: peso %d" % [c.nombre, int(o["peso"])])
	distintos["%s|%s|%s" % [pr["texto"], str(ids), (p["proyecto"] as Dictionary)["id"]]] = true


func _objetivos_plazas_y_tamano() -> void:
	var esp := ObjetivosClub.plazas_continentales("ESP", 20)
	var chi := ObjetivosClub.plazas_continentales("CHI", 16)
	var cupo_esp := 0
	for f: Array in FormatosConti.cupos("ucl"):
		if f[0] == "ESP":
			cupo_esp = int(f[1])
	_comprobar(int(esp["elite"]) == cupo_esp and cupo_esp == 5 and int(chi["elite"]) == 3, "ESP da las 5 plazas de la Champions de 36 y CHI 3 de Libertadores (%d y %d)" % [int(esp["elite"]), int(chi["elite"])])
	## El tamaño de la liga manda: el colista de una liga de 12, 20 o 24 con 2, 3 y 4 descensos (las ligas generadas hoy son de 16).
	var chico := Club.new()
	chico.pais = "ESP"
	chico.division = 1
	var salv: Array[int] = []
	for caso: Array in [[12, 2], [20, 3], [24, 4]]:
		var pe := ObjetivosClub.principal(chico, int(caso[0]), int(caso[0]), int(caso[1]), ObjetivosClub.plazas_continentales("ESP", int(caso[0])))
		salv.append(int(pe["meta"]))
	_comprobar(salv == [10, 17, 20] and String(ObjetivosClub.principal(chico, 1, 20, 3, {"elite": 4, "segunda": 3})["texto"]) == "Salir campeón", "el colista debe salvarse según su liga: 12→10.º, 20 (3 descensos)→17.º, 24 (4 descensos)→20.º (%s) y el favorito, el título" % str(salv))

func _objetivos_cierre_y_vivo() -> void:
	## EL CIERRE
	var m2 := Mundo.new()
	m2.generar(["CHI", "ESP"], 77)
	m2.tomar_el_mando(m2.ligas[1].clubes[4].id)
	var d := m2.directiva
	_comprobar(d.objetivos.size() >= 3 and not d.proyecto.is_empty() and d.meta_puesto >= 1, "el club del jugador trae su paquete (%d secundarios, proyecto «%s»)" % [d.objetivos.size(), String(d.proyecto.get("texto", ""))])
	var c2 := m2.mi_club()
	d.objetivos.clear()
	d.proyecto = {}
	d.bases = {"saldo": 0, "socios": 100}
	d.objetivos.append({"id": "eco", "tipo": "economia", "texto": "Salir de los números rojos", "meta": 0, "peso": 8})
	d.objetivos.append({"id": "cantera", "tipo": "cantera", "texto": "x", "meta": 99, "peso": 5})
	d.confianza = 50
	c2.saldo = 5000000
	var r := ObjetivosCierre.cerrar(m2, d, 5, false)
	_comprobar(int(r["delta"]) == 8 - 7 and d.confianza == 51, "cumplir la economía (+8) y fallar la cantera (−7: el peso 5 +25 %%) mueve la confianza +1 (%d)" % d.confianza)
	d.proyecto = {"id": "sanear", "texto": "Sanear", "meta": 0, "temporadas": 3, "cierres": 2, "mejor_puesto": 0, "titulos": 0, "puesto_base": 5, "saldo_base": -1}
	d.objetivos.clear()
	var r2 := ObjetivosCierre.cerrar(m2, d, 5, false)
	_comprobar(bool((r2["proyecto"] as Dictionary).get("cumplido", false)) and int(r2["delta"]) == ObjetivosClub.PESO_PROYECTO_OK, "al cerrar la 3.ª temporada el proyecto saneado suma +%d" % ObjetivosClub.PESO_PROYECTO_OK)
	## GUARDADO: el paquete sobrevive y una partida vieja (sin los campos) abre con el suyo.
	d.generar_objetivos(m2)
	var textos: Array = d.objetivos.map(func(o: Dictionary) -> String: return String(o["texto"]))
	var inst: Dictionary = JSON.parse_string(JSON.stringify(Partida.instantanea(m2)))
	var m3 := Partida.desde_instantanea(inst)
	_comprobar(m3.directiva.objetivos.map(func(o: Dictionary) -> String: return String(o["texto"])) == textos and String(m3.directiva.proyecto.get("id", "")) == String(d.proyecto.get("id", "")), "los objetivos y el proyecto sobreviven a guardar y cargar")
	for k: String in ["objetivos", "proyecto", "bases"]:
		(inst["directiva"] as Dictionary).erase(k)
	var m4 := Partida.desde_instantanea(inst)
	_comprobar(m4.directiva.objetivos.size() >= 3 and m4.directiva.meta_puesto == d.meta_puesto, "una partida vieja sin los campos nuevos abre y estrena los objetivos de su club")
	## EN VIVO: una barra por objetivo secundario y por el proyecto, con progreso 0-100 y estado; cambia con lo que pasa (caja en rojo → en riesgo).
	for grupo2: Array in [["BRA"], ["JPN"], ["GER"]]:
		Partido.limpiar_contexto()
		var m5 := Mundo.new()
		var g5: Array[String] = []
		g5.assign(grupo2)
		m5.generar(g5, 33)
		var lg: Liga = m5.ligas[0]
		m5.tomar_el_mando(lg.clubes[lg.clubes.size() / 2].id)
		var vivo := ObjetivosEnVivo.lista(m5, m5.directiva)
		var rango_ok := true
		for f: Dictionary in vivo:
			if int(f["progreso"]) < 0 or int(f["progreso"]) > 100 or not ["cumplido", "bien", "riesgo", "perdido"].has(String(f["estado"])):
				rango_ok = false
		_comprobar(vivo.size() >= 2 and rango_ok, "%s: el progreso en vivo trae %d filas con progreso 0-100 y estado válido" % [grupo2[0], vivo.size()])
		var ui := ObjetivoDirectiva.secundarios(m5)
		_comprobar(ui != null and ui.find_children("*", "ProgressBar", true, false).size() == vivo.size(), "%s: el menú central pinta una barra por fila" % grupo2[0])
		if ui != null:
			ui.free()
	var eco := {"id": "eco", "tipo": "economia", "texto": "Salir de los números rojos", "meta": 0, "peso": 8}
	d.objetivos = [eco]
	d.bases = {"saldo": -4000000, "socios": 0}
	c2.saldo = -1000000
	var peor := ObjetivosEnVivo.lista(m2, d)
	c2.saldo = 500000
	var mejor := ObjetivosEnVivo.lista(m2, d)
	_comprobar(String(peor[0]["estado"]) != "cumplido" and int(peor[0]["progreso"]) < 100 and String(mejor[0]["estado"]) == "cumplido", "salir del rojo: de −1 M (%d %%) a +0,5 M (cumplido)" % int(peor[0]["progreso"]))
	_comprobar(ObjetivosCierre.delta_de(8, true) == 8 and ObjetivosCierre.delta_de(8, false) == -10, "cumplir suma el peso y fallar resta un 25 % más (8 → +8 / −10)")
