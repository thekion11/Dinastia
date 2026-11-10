class_name CompeticionFaseFinal
extends RefCounted
## LA FASE FINAL EN LA FICHA DE LA LIGA (10-11-2026): los grupos de campeonato y descenso de Egipto y los cuadros de playoffs de Argentina y la
## MLS, ronda a ronda, con quién pasó (en verde) y las series al mejor de 3. Los datos salen de `FaseFinalLiga.secciones`.

static func pintar(lista: VBoxContainer, liga: Liga, mio: Club) -> void:
	if liga.formato == null:
		return
	lista.add_child(HSeparator.new())
	CompeticionFilas.titulo(lista, Idiomas.t("FASE FINAL"), Tema.ORO, 14)
	var secciones := liga.formato.secciones(liga)
	if secciones.is_empty():
		CompeticionFilas.titulo(lista, Idiomas.t("Se define al terminar la fase regular."), Tema.SUAVE, 13)
		return
	for s: Dictionary in secciones:
		CompeticionFilas.titulo(lista, Idiomas.t(String(s["titulo"])).to_upper(), Tema.SUAVE, 12)
		if s.has("filas"):
			CompeticionFilas.cabecera(lista, ["PJ", "G", "E", "P", "DG", "PTS"])
			var puesto := 0
			for f: Dictionary in s["filas"]:
				puesto += 1
				var c: Club = f["club"]
				var dg := int(f["gf"]) - int(f["gc"])
				CompeticionFilas.fila_tabla(lista, puesto, c, [str(f["pj"]), str(f["g"]), str(f["e"]), str(f["p"]),
					("+%d" % dg) if dg > 0 else str(dg), str(f["pts"])], c == mio, puesto % 2 == 0)
			continue
		for c: Dictionary in s["cruces"]:
			CompeticionFilas.fila_partido(lista, c["a"], c["b"], _goles(c, 0), _goles(c, 1), mio, _resumen(c))

## Goles (o victorias, en una serie) de cada lado; -1 si todavía no se jugó.
static func _goles(c: Dictionary, lado: int) -> int:
	var r: Array = c["r"]
	if r.is_empty():
		return -1
	if r.size() == 1:
		return int(r[0][lado])
	var v := 0
	for x: Array in r:
		v += 1 if int(x[lado]) > int(x[1 - lado]) else 0
	return v

static func _resumen(c: Dictionary) -> String:
	var r: Array = c["r"]
	var txt := ""
	if r.size() > 1:
		txt = ", ".join(r.map(func(x: Array) -> String: return "%d-%d" % [int(x[0]), int(x[1])]))
	if c["g"] != null:
		txt += ("  " if txt != "" else "") + "→ " + Nombres.visible((c["g"] as Club).nombre)
	return txt
