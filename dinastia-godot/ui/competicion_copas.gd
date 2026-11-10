class_name CompeticionCopas
extends RefCounted
## LAS COPAS EN LA FICHA DE COMPETICIÓN (25-10-2026). Hasta ahora la ficha solo
## sabía de ligas: la copa nacional y la Libertadores existían en la columna del
## hub nada más que la semana en que tocaban, y no había dónde mirar el cuadro
## entero, los grupos ni quién eliminó a quién. Aquí se pinta cualquier `Copa`
## (y `Continental`, que hereda de ella): campeón, grupos, próxima ronda y todas
## las rondas jugadas, de la última a la primera.

## Las rondas llegan en castellano desde el núcleo ("Cuartos de final",
## "Grupos · Fecha 2"): se traducen al pintar.
static func ronda(txt: String) -> String:
	return Idiomas.t(txt)

static func pintar(lista: VBoxContainer, copa: Copa, mio: Club) -> void:
	var conti := copa as Continental
	var nombre := CompeticionInfo.nombre_visible(Continental.nombre_conti(conti.clave) if conti != null else copa.nombre)
	var estado := ""
	if copa.campeon != null:
		estado = Idiomas.t("Terminada")
	elif copa.en_curso():
		estado = ronda(copa.nombre_de_ronda())
	CompeticionFilas.titulo(lista, ("%s  ·  %s" % [nombre, estado]) if estado != "" else nombre, Tema.ORO, 16)
	if copa.campeon != null:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		lista.add_child(h)
		h.add_child(CompeticionFilas.escudo(copa.campeon, 32))
		h.add_child(CompeticionFilas.etiqueta(Idiomas.t("🏆 Campeón: %s") % Nombres.visible(copa.campeon.nombre), 16,
			Tema.ACENTO if copa.campeon == mio else Tema.ORO))
	if mio != null and copa.participantes.has(mio) and copa.campeon != mio:
		var sigue := copa.vivos.has(mio) or (conti != null and conti.en_fase_de_grupos())
		CompeticionFilas.titulo(lista, Idiomas.t("Tu club sigue en carrera.") if sigue and copa.en_curso()
			else Idiomas.t("Tu club ya quedó fuera."), Tema.ACENTO if sigue else Tema.SUAVE, 13)
	## Con la primera fase jugada, el cuadro (próxima ronda y resultados) va ANTES que las tablas: una fase de liga de 36 clubes
	## ocupa la pantalla entera y dejaría el cuadro fuera de la vista.
	var tablas_al_final := conti != null and conti.por_grupos and not conti.en_fase_de_grupos()
	if conti != null and conti.por_grupos and not tablas_al_final:
		_pintar_grupos(lista, conti, mio)
	if copa.en_curso() and conti != null and conti.en_fase_de_grupos():
		lista.add_child(HSeparator.new())
		CompeticionFilas.titulo(lista, Idiomas.t("PRÓXIMA FECHA  ·  %s") % ronda(copa.nombre_de_ronda()).to_upper(), Tema.SUAVE, 12)
		for par: Array in conti.cruces_de_la_fecha():
			CompeticionFilas.fila_partido(lista, par[0], par[1], -1, -1, mio)
	elif copa.en_curso():
		lista.add_child(HSeparator.new())
		CompeticionFilas.titulo(lista, Idiomas.t("PRÓXIMA RONDA  ·  %s") % ronda(copa.nombre_de_ronda()).to_upper(), Tema.SUAVE, 12)
		## En la vuelta de una eliminatoria a doble partido se invierte el campo.
		var vuelta := conti != null and int(conti.hueco_actual().get("pata", 0)) == 2
		for par: Array in copa.cruces():
			if vuelta:
				CompeticionFilas.fila_partido(lista, par[1], par[0], -1, -1, mio)
			else:
				CompeticionFilas.fila_partido(lista, par[0], par[1], -1, -1, mio)
	_pintar_historial(lista, copa, mio)
	if tablas_al_final:
		_pintar_grupos(lista, conti, mio)

## Los grupos (o la tabla única de la fase de liga), uno debajo de otro, con los que pasan marcados. Es la
## misma fila de la tabla de liga, así que se lee igual.
static func _pintar_grupos(lista: VBoxContainer, t: Continental, mio: Club) -> void:
	for i in t.grupos.size():
		lista.add_child(HSeparator.new())
		CompeticionFilas.titulo(lista, Idiomas.t(t.nombre_de_grupo(i)).to_upper(), Tema.SUAVE, 12)
		CompeticionFilas.cabecera(lista, ["PJ", "GF", "GC", "DG", "PTS"])
		var puesto := 0
		var jugado := false
		for f: Dictionary in t.tabla_de_grupo(i):
			jugado = jugado or int(f["pj"]) > 0
		for f: Dictionary in t.tabla_de_grupo(i):
			puesto += 1
			var c: Club = f["club"]
			var dg := int(f["dif"])
			## Los que pasan: verde de ascenso, que es lo que significa. En la fase de liga, los de la franja del playoff van en
			## la zona continental (azul). Antes de jugar nada no se marca: sería el sorteo.
			var zona := {}
			var destino := t.destino_en_primera_fase(puesto)
			if jugado and destino == "directo":
				zona = {"zona": CompeticionZonas.ASCENSO, "texto": Idiomas.t(t.texto_de_pase())}
			elif jugado and destino == "playoff":
				zona = {"zona": CompeticionZonas.CONTINENTAL, "texto": Idiomas.t("Playoff")}
			CompeticionFilas.fila_tabla(lista, puesto, c, [str(f["pj"]), str(f["gf"]), str(f["gc"]),
				("+%d" % dg) if dg > 0 else str(dg), str(f["pts"])], c == mio, puesto % 2 == 0, zona)

## Todas las rondas jugadas, de la más reciente a la primera: quién pasó y por
## cuánto. En grupos, cada partido lleva su grupo; en eliminatoria, los penales.
static func _pintar_historial(lista: VBoxContainer, copa: Copa, mio: Club) -> void:
	lista.add_child(HSeparator.new())
	CompeticionFilas.titulo(lista, Idiomas.t("RESULTADOS"), Tema.SUAVE, 12)
	if copa.historial.is_empty():
		CompeticionFilas.titulo(lista, Idiomas.t("Todavía no se ha jugado ninguna ronda."), Tema.SUAVE, 13)
		return
	for i in range(copa.historial.size() - 1, -1, -1):
		var h: Dictionary = copa.historial[i]
		CompeticionFilas.titulo(lista, ronda(String(h.get("ronda", ""))), Tema.ORO, 11)
		for r: Dictionary in (h.get("resultados", []) as Array):
			var extra := ""
			var pen: Array = r.get("penales", [])
			if r.has("agregado"):
				var agr: Array = r["agregado"]
				extra = Idiomas.t("Global %d-%d") % [int(agr[0]), int(agr[1])]
				if pen.size() >= 2:
					extra += "  " + Idiomas.t("(%d-%d pen.)") % [int(pen[0]), int(pen[1])]
			elif pen.size() >= 2:
				extra = Idiomas.t("(%d-%d pen.)") % [int(pen[0]), int(pen[1])]
			elif r.has("etiqueta"):
				extra = Idiomas.t(String(r["etiqueta"]))
			elif r.has("grupo") and copa is Continental:
				extra = Idiomas.t((copa as Continental).nombre_de_grupo(int(r["grupo"])))
			CompeticionFilas.fila_partido(lista, r["local"], r["visita"], int(r["gl"]), int(r["gv"]), mio, extra)
