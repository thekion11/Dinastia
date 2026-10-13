extends Node
## Sonda de realismo del fútbol (13-10-2026): una temporada de tres ligas y las
## cifras que tiene el fútbol de verdad (aprox.): ~2,6-2,8 goles por partido,
## ~25 % empates, ~45 % victorias locales, campeón con ~70-90 % de los puntos
## posibles en ligas largas, máximo goleador con ~20-35 goles.
##   godot --headless --path . res://pruebas/sonda_futbol.tscn
func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI", "ARG", "ESP"], 31)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	for l: Liga in m.ligas:
		var medias: Array = []
		for c: Club in l.clubes:
			var o := c.once()
			var suma := 0
			for j: Jugador in o:
				suma += j.ovr
			medias.append(snappedf(float(suma) / maxf(1.0, o.size()), 0.1))
		medias.sort()
		print("%s medias del once: %s" % [l.nombre, medias])
	m.jugar_temporada()
	var p := 0
	var goles := 0
	var emp := 0
	var loc := 0
	var vis := 0
	var goleadas := 0
	for l: Liga in m.ligas:
		for jornada: Array in l.historial:
			for r: Dictionary in jornada:
				p += 1
				goles += int(r["gl"]) + int(r["gv"])
				if int(r["gl"]) == int(r["gv"]):
					emp += 1
				elif int(r["gl"]) > int(r["gv"]):
					loc += 1
				else:
					vis += 1
				if absi(int(r["gl"]) - int(r["gv"])) >= 4:
					goleadas += 1
		var t := l.tabla()
		if not t.is_empty():
			var posibles := int(t[0]["pj"]) * l.puntos_victoria
			print("%s: campeón %s con %d de %d pts (%d%%) · último %d pts" % [l.nombre, (t[0]["club"] as Club).nombre, int(t[0]["pts"]), posibles, 100 * int(t[0]["pts"]) / maxi(1, posibles), int(t[t.size() - 1]["pts"])])
	print("partidos %d · goles/partido %.2f · empates %d%% · local %d%% · visita %d%% · goleadas(4+) %d%%" % [p, float(goles) / p, 100 * emp / p, 100 * loc / p, 100 * vis / p, 100 * goleadas / p])
	var max_gol := 0
	var quien := ""
	var valores: Array = []
	for j: Jugador in m.jugadores():
		valores.append(j.valor)
		var g := j.goles
		if g > max_gol:
			max_gol = g
			quien = j.nombre
	valores.sort()
	print("máximo goleador: %s %d · valor mediano %d mil · máximo %d M" % [quien, max_gol, int(valores[valores.size() / 2]) / 1000, int(valores[valores.size() - 1]) / 1000000])
	## Coherencia de personas: lesiones, edades, valores por media.
	var lesionados := 0
	var largos := 0
	var edades := {}
	var por_media := {}
	for j: Jugador in m.jugadores():
		if j.lesion > 0:
			lesionados += 1
		if j.edad < 15:
			print("NIÑO: ", j.nombre, " ", j.edad, " años, club ", j.club_id, " ovr ", j.ovr, " id ", j.id, " formación ", j.club_formacion)
		if j.lesion > 30:
			largos += 1
		var tramo := int(j.edad / 5) * 5
		edades[tramo] = int(edades.get(tramo, 0)) + 1
		var mt := int(j.ovr / 10) * 10
		if not por_media.has(mt):
			por_media[mt] = []
		(por_media[mt] as Array).append(j.valor)
	print("lesionados al cierre: %d (más de 30 sem.: %d) de %d" % [lesionados, largos, m.jugadores().size()])
	print("edades por tramo: ", edades)
	for mt: int in [50, 60, 70, 80]:
		var arr: Array = por_media.get(mt, [])
		arr.sort()
		if not arr.is_empty():
			print("media %d-%d: %d jugadores, valor mediano %d mil" % [mt, mt + 9, arr.size(), int(arr[arr.size() / 2]) / 1000])
	get_tree().quit()
