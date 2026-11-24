class_name ProbarNativoFuerza
extends RefCounted
## (17-11-2026) LA FUERZA DE LOS ONCES CON TODA LA PIZARRA. El fallo del 17-11 (la táctica y los roles dejaron de influir en el partido simulado con la
## extensión: `fuerza_dos` no aplica los roles por jugador de `partido.gd`) pasó porque `probar_nativo` solo comparaba la fuerza con la táctica por
## defecto. Aquí se compara `invalidar_fuerza` (camino C++ + roles) con `fuerza()` (GDScript) en clubes de tres países con: sin roles, cada rol del
## catálogo puesto a los jugadores de su línea (carrileros, laterales cerrados, pivote…), las 3 mentalidades × 3 líneas × 3 ritmos, presión, amplitud,
## verticalidad y tras pérdida en sus extremos y los cuatro interruptores. Devuelve {comparadas, distintas, variantes}.
static func probar() -> Dictionary:
	var m := Mundo.new()
	m.generar(["ITA", "ARG", "ENG"] as Array[String], 4242)
	var clubes: Array = []
	for liga: Liga in m.ligas:
		if int(liga.div) == 1 and liga.clubes.size() >= 6:
			clubes.append(liga.clubes[1])
			clubes.append(liga.clubes[4])
	var variantes: Array[Callable] = [func(_c: Club) -> void: pass]
	for rol: String in RolTactico.CATALOGO:
		variantes.append(func(c: Club) -> void:
			for j: Jugador in c.once():
				c.tactica.poner_rol(j, rol))
	for men in 3:
		for lin in 3:
			for rit in 3:
				variantes.append(func(c: Club) -> void:
					c.tactica.mentalidad = men
					c.tactica.linea = lin
					c.tactica.ritmo = rit)
	for k: String in ["presion", "amplitud", "verticalidad", "tras_perdida"]:
		for v in [0, 2]:
			variantes.append(func(c: Club) -> void: c.tactica.set(k, v))
	for k: String in ["salida_corta", "marca_al_hombre", "fuera_de_juego", "tiro_lejano"]:
		variantes.append(func(c: Club) -> void: c.tactica.set(k, true))
	## Y una mezcla: roles de todas las líneas a la vez con una pizarra extrema.
	variantes.append(func(c: Club) -> void:
		for j: Jugador in c.once():
			for rol: String in ["carrilero", "pivote", "nueve_area", "portero_libero"]:
				c.tactica.poner_rol(j, rol)
		c.tactica.mentalidad = 2
		c.tactica.linea = 2)
	Partido.comparar_fuerza = true
	Partido.fuerza_comparadas = 0
	Partido.fuerza_distintas = 0
	for i in clubes.size():
		var a: Club = clubes[i]
		var b: Club = clubes[(i + 3) % clubes.size()]
		for v: Callable in variantes:
			var ta := a.tactica.duplicar()
			var tb := b.tactica.duplicar()
			v.call(a)
			v.call(b)
			var p := Partido.new(a, b)
			p.preparar()
			p.invalidar_fuerza()
			a.tactica = ta
			b.tactica = tb
	Partido.comparar_fuerza = false
	return {"comparadas": Partido.fuerza_comparadas, "distintas": Partido.fuerza_distintas, "variantes": variantes.size()}
