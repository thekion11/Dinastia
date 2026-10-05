extends Node
## PRUEBA LARGA (MEGAPLAN fase 1, «jugar 10 temporadas × 3 como humano»):
## diez temporadas seguidas con tres semillas distintas y, cada año, los
## invariantes del banco: tablas que cuadran, nadie de más de 40, plantillas
## sanas, caja y sueldos con sentido, medias en rango. Al final, que hubo
## ascensos y descensos, retiros y jugadores nuevos (regens).
## Tarda varios minutos: no va en el banco de cada subida, es la prueba de la
## noche.
##   godot --headless --path . res://pruebas/prueba_larga.tscn
## TEMPORADAS=n / SEMILLAS=a,b,c para cambiarla.
var _fallos: Array[String] = []

func _ready() -> void:
	var temporadas := int(OS.get_environment("TEMPORADAS")) if OS.get_environment("TEMPORADAS") != "" else 10
	var semillas: Array = [11, 222, 3333]
	if OS.get_environment("SEMILLAS") != "":
		semillas = Array(OS.get_environment("SEMILLAS").split(",")).map(func(x: String) -> int: return int(x))
	var t0 := Time.get_ticks_msec()
	for s: int in semillas:
		_una(int(s), temporadas)
	print("")
	print("===== PRUEBA LARGA: %d temporadas x %d semillas en %d s =====" % [
		temporadas, semillas.size(), (Time.get_ticks_msec() - t0) / 1000])
	for f in _fallos:
		print("  FALLO ", f)
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _comprobar(c: bool, que: String) -> void:
	if not c:
		_fallos.append(que)
		print("  FALLO ", que)

func _una(semilla: int, temporadas: int) -> void:
	print("")
	print("===== SEMILLA %d =====" % semilla)
	var m := Mundo.new()
	m.generar(["CHI", "ARG", "ESP"], semilla)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var ids_inicio := {}
	for j in m.jugadores():
		ids_inicio[j.id] = true
	var cambios_div := 0
	for t in temporadas:
		var div_antes := {}
		for c: Club in m.clubes.values():
			div_antes[c.id] = c.division
		m.jugar_temporada()
		var et := "%d (semilla %d)" % [m.anio, semilla]
		## Tablas.
		for liga: Liga in m.ligas:
			var gf := 0
			var gc := 0
			for fila: Dictionary in liga.tabla():
				_comprobar(int(fila["pts"]) == int(fila["g"]) * liga.puntos_victoria + int(fila["e"]),
					"%s: puntos mal sumados en %s" % [et, fila["club"].nombre])
				_comprobar(int(fila["pj"]) == int(fila["g"]) + int(fila["e"]) + int(fila["p"]),
					"%s: partidos mal sumados en %s" % [et, fila["club"].nombre])
				gf += int(fila["gf"])
				gc += int(fila["gc"])
			_comprobar(gf == gc, "%s: goles a favor != en contra en %s (%d/%d)" % [et, liga.nombre, gf, gc])
		m.nueva_temporada()
		for c: Club in m.clubes.values():
			if int(div_antes.get(c.id, c.division)) != c.division:
				cambios_div += 1
		## Clubes y jugadores.
		var viejos := 0
		var cortas := 0
		var deformes := 0
		var medias_raras := 0
		var sueldos_raros := 0
		var cajas_raras := 0
		for c: Club in m.clubes.values():
			if c.plantilla.size() < 18:
				cortas += 1
			if absi(c.saldo) > 50_000_000_000:
				cajas_raras += 1
			var porteros := 0
			var lineas := {}
			for j in c.plantilla:
				lineas[Datos.grupo(j.pos_e)] = true
				if j.es_portero():
					porteros += 1
				if j.edad > 40:
					viejos += 1
				if j.ovr < 1 or j.ovr > 99 or j.pot < j.ovr - 1:
					medias_raras += 1
					if medias_raras <= 3:
						print("    media rara: %s %d años ovr %d pot %d (%s)" % [j.nombre, j.edad, j.ovr, j.pot, c.nombre])
				if j.sueldo <= 0:
					sueldos_raros += 1
			if lineas.size() < 4 or porteros > 5 or porteros < 1:
				deformes += 1
				if deformes <= 2:
					print("    deforme: %s (div %d, %s) %d jugadores, %d porteros, líneas %s" % [
						c.nombre, c.division, c.pais, c.plantilla.size(), porteros, lineas.keys()])
		_comprobar(viejos == 0, "%s: %d jugadores de más de 40" % [et, viejos])
		_comprobar(cortas == 0, "%s: %d plantillas por debajo de 18" % [et, cortas])
		_comprobar(deformes == 0, "%s: %d plantillas deformes" % [et, deformes])
		_comprobar(medias_raras == 0, "%s: %d medias fuera de rango" % [et, medias_raras])
		_comprobar(sueldos_raros == 0, "%s: %d sueldos en cero o negativos" % [et, sueldos_raros])
		_comprobar(cajas_raras == 0, "%s: %d cajas absurdas" % [et, cajas_raras])
		var campeon: Dictionary = m.ligas[0].historial[-1] if not m.ligas[0].historial.is_empty() and m.ligas[0].historial[-1] is Dictionary else {}
		print("  %d: %d jugadores, mi club %s (div %d, caja %d M)%s" % [m.anio, m.cuantos_jugadores(),
			m.mi_club().nombre, m.mi_club().division, m.mi_club().saldo / 1_000_000,
			("  campeón: " + str(campeon.get("campeon", ""))) if not campeon.is_empty() else ""])
	var siguen := 0
	var nuevos := 0
	for j in m.jugadores():
		if ids_inicio.has(j.id):
			siguen += 1
		else:
			nuevos += 1
	var retirados := ids_inicio.size() - siguen
	print("  ascensos/descensos: %d · retirados o fuera: %d · nuevos: %d" % [cambios_div, retirados, nuevos])
	_comprobar(cambios_div > 0, "semilla %d: ningún ascenso ni descenso en %d temporadas" % [semilla, temporadas])
	_comprobar(retirados > 0, "semilla %d: nadie se retiró" % semilla)
	_comprobar(nuevos > 0, "semilla %d: no llegó ningún jugador nuevo" % semilla)
