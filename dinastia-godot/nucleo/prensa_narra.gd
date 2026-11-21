extends "res://nucleo/prensa_p6.gd"
## [Capa intermedia de `prensa.gd`, entre `prensa_p6.gd` y `prensa.gd`] _narrar_puesto, _narrar_trofeos y _narrar_rachas (20-11, orden 63: partido en funciones).

## El puesto de tu club en sus ligas, y la frase de la temporada.
func _narrar_puesto(m: Mundo, mio: Club, partes: PackedStringArray) -> void:
	var puesto := 0
	for l: Liga in m.ligas:
		if not l.clubes.has(mio):
			continue
		var n := 0
		for f: Dictionary in l.tabla():
			n += 1
			if f["club"] == mio:
				puesto = n
				break
	if puesto > 0:
		partes.append("La temporada %d de %s terminó en el puesto %d." % [m.anio, mio.nombre, puesto])
	else:
		partes.append("La temporada %d de %s todavía se está jugando." % [m.anio, mio.nombre])

## Los títulos del año (o que no hubo).
func _narrar_trofeos(m: Mundo, partes: PackedStringArray) -> void:
	if m.roles != null:
		var del_anio: PackedStringArray = []
		for t: Dictionary in m.roles.trofeos:
			if int(t.get("anio", 0)) == m.anio:
				del_anio.append(String(t.get("titulo", "")))
		if del_anio.size() > 0:
			partes.append("Se levantaron %d título%s: %s." % [
				del_anio.size(), "" if del_anio.size() == 1 else "s",
				", ".join(del_anio)])
		else:
			partes.append("Sin títulos esta vez.")

## Las rachas, las goleadas, la peor derrota y el hombre gol del año.
func _narrar_rachas(m: Mundo, partes: PackedStringArray) -> void:
	if m.logros != null:
		var r: Dictionary = m.logros.rachas
		if int(r.get("invicto_max", 0)) >= 8:
			partes.append("Hubo una racha de %d partidos sin perder que hizo soñar a la ciudad." % int(r["invicto_max"]))
		if int(r.get("sin_ganar_max", 0)) >= 6:
			partes.append("También hubo un bache de %d partidos sin ganar que puso todo en duda." % int(r["sin_ganar_max"]))
		var rec: Dictionary = m.logros.rec
		var mg: Variant = rec.get("mayor_goleada")
		if mg is Dictionary and int((mg as Dictionary).get("anio", 0)) == m.anio:
			partes.append("La noche grande fue el %s a %s." % [
				String((mg as Dictionary).get("marcador", "")), String((mg as Dictionary).get("rival", ""))])
		var pd: Variant = rec.get("peor_derrota")
		if pd is Dictionary and int((pd as Dictionary).get("anio", 0)) == m.anio:
			partes.append("La peor, el %s con %s." % [
				String((pd as Dictionary).get("marcador", "")), String((pd as Dictionary).get("rival", ""))])
		## El hombre gol. `rec["goles"]` va por NOMBRE visible con su número de goles (así lo escribe `Logros`). (13-11) Aquí se leía
		## como si fuera por id con {nombre, n}: reventaba en cuanto había un gol anotado, y no se vio porque simulando la lista estaba vacía.
		var mejor := ""
		var mejor_n := 0
		var goles: Dictionary = rec.get("goles", {})
		for quien: String in goles:
			var g: Variant = goles[quien]
			var n := int((g as Dictionary).get("n", 0)) if g is Dictionary else int(g)
			if n > mejor_n:
				mejor_n = n
				mejor = String((g as Dictionary).get("nombre", "")) if g is Dictionary else quien
		if mejor != "" and mejor_n > 0:
			partes.append("%s fue el hombre gol con %d tantos." % [mejor, mejor_n])
