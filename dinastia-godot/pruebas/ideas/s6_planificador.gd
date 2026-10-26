extends BaseIdea
## SESIÓN 6 (26-10-2026), fila 21 de la propuesta s4: el planificador de plantilla
## avisa de carencias, de lo que se va en verano, del titular que se va y de la
## línea sin relevo, con las mismas reglas que el núcleo (contratos y retiros).

func _probar() -> void:
	_titulo("S6: PLANIFICADOR DE PLANTILLA (fila 21)")
	var mins := PlanificadorPlantilla.minimos()
	_comprobar(int(mins["POR"]) == 3 and int(mins["DEF"]) == 8 and int(mins["MED"]) == 8 and int(mins["DEL"]) == 6,
		"los mínimos por línea salen de PLAN_PLANTEL (%s)" % str(mins))
	var m := _mundo(2121)
	var c := m.mi_club()
	for j: Jugador in c.plantilla:
		j.anios_contrato = 3
		j.edad = 26
	var r := PlanificadorPlantilla.analizar(c)
	var total := 0
	for g: String in PlanificadorPlantilla.LINEAS:
		total += int(r["lineas"][g]["total"])
	_comprobar(total == c.plantilla.size(), "cuenta a toda la plantilla por líneas (%d)" % total)
	var lin := ""
	for g: String in PlanificadorPlantilla.LINEAS:
		lin += "%s %d/%d " % [g, int(r["lineas"][g]["total"]), int(r["lineas"][g]["minimo"])]
	_comprobar(not _tipos(r).has("carencia"), "con una plantilla normal no hay carencias (%s · %s)" % [str(_tipos(r)), lin])
	## Carencia: quitar porteros hasta quedarse con uno.
	var porteros: Array[Jugador] = []
	for j: Jugador in c.plantilla:
		if j.pos == "POR":
			porteros.append(j)
	var guardados := porteros.slice(1)
	for j: Jugador in guardados:
		c.plantilla.erase(j)
	r = PlanificadorPlantilla.analizar(c)
	var car := _aviso(r, "carencia", "POR")
	var um := PlanificadorPlantilla.umbral("POR", int(mins["POR"]))
	_comprobar(um == 2 and PlanificadorPlantilla.umbral("DEF", 8) == 6 and PlanificadorPlantilla.umbral("DEL", 6) == 4, "imprescindibles: 2 POR, 6 DEF, 4 DEL")
	_comprobar(not car.is_empty() and int(car["n"]) == um - 1, "con un solo portero avisa de que falta %d" % (um - 1))
	for j: Jugador in guardados:
		c.plantilla.append(j)
	## Verano: a todos los delanteros les vence el contrato menos a uno y otro tiene 36.
	var dels: Array[Jugador] = []
	for j: Jugador in c.plantilla:
		if j.pos == "DEL":
			dels.append(j)
	for i in dels.size():
		dels[i].anios_contrato = 1 if i < dels.size() - 2 else 3
	dels[dels.size() - 1].edad = 36
	r = PlanificadorPlantilla.analizar(c)
	var ver := _aviso(r, "verano", "DEL")
	_comprobar(not ver.is_empty() and int(ver["vencen"]) == dels.size() - 2 and int(ver["retiro"]) == 1,
		"avisa de que en verano se quedan cortos de delanteros (%d vencen, 1 se retira)" % (dels.size() - 2))
	_comprobar(int(r["lineas"]["DEL"]["quedan"]) == 1, "y de que solo queda 1")
	## Titular que se va: alguien del once con el contrato en su último año.
	var titular: Jugador = c.once()[0]
	titular.anios_contrato = 1
	r = PlanificadorPlantilla.analizar(c)
	var tit := false
	for a: Dictionary in r["avisos"]:
		if String(a["tipo"]) == "titular_se_va" and a["jugador"] == titular:
			tit = true
	_comprobar(tit, "avisa de que vence el contrato de un titular (%s)" % titular.nombre)
	_comprobar(int(r["avisos"][0]["nivel"]) == 2, "lo grave (carencia, titular) va primero")
	## Sin relevo: el portero titular con 34 y ningún portero de 23 o menos.
	for j: Jugador in c.plantilla:
		if j.pos == "POR":
			j.edad = 34 if c.once().has(j) else 29
	r = PlanificadorPlantilla.analizar(c)
	_comprobar(not _aviso(r, "sin_relevo", "POR").is_empty(), "avisa de que el portero titular (34) no tiene relevo joven")
	_comprobar(PlanificadorPlantilla.analizar(null)["avisos"].is_empty(), "sin club no se rompe")

func _tipos(r: Dictionary) -> Array:
	var t := []
	for a: Dictionary in r["avisos"]:
		t.append(a["tipo"])
	return t

func _aviso(r: Dictionary, tipo: String, grupo: String) -> Dictionary:
	for a: Dictionary in r["avisos"]:
		if String(a["tipo"]) == tipo and String(a["grupo"]) == grupo:
			return a
	return {}
