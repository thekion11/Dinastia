extends Node
## SONDA DEL RITMO DE «LA RUTA»: juega N temporadas simuladas con un jugador
## sensato (descansa con menos de 40 de energía, entrena lo más bajo de lo que
## le sirve a su puesto, resuelve la primera opción) y escribe, por temporada,
## media, nivel, capítulo, fama, partidos, goles, nota y energía media.
##   PUESTO=DC TEMPORADAS=6 SEMILLA=7 godot --headless --path . res://pruebas/_sonda/sonda_ruta.tscn
func _ready() -> void:
	var puesto := OS.get_environment("PUESTO") if OS.get_environment("PUESTO") != "" else "DC"
	var n := maxi(1, int(OS.get_environment("TEMPORADAS"))) if OS.get_environment("TEMPORADAS") != "" else 5
	var semilla := int(OS.get_environment("SEMILLA")) if OS.get_environment("SEMILLA") != "" else 7
	var m := Mundo.new()
	m.generar(LigasActivas.para_generar(), semilla)
	m.mi_club_id = ""
	var c := CarreraJugador.crear(m, "Sonda Ruta", puesto, false, semilla)
	m.carrera_jugador = c
	var of := CarreraComienzo.pruebas(m, semilla)
	CarreraComienzo.mudar(c, m, of[semilla % of.size()])
	print("SONDA %s en %s (%s)" % [puesto, c.club(m).nombre, c.club(m).pais])
	for t in n:
		var energia := 0
		var semanas := 0
		var tope := 80
		while m.temporada_en_curso() and tope > 0:
			tope -= 1
			var j := c.jugador(m)
			while not c.eventos.is_empty():
				c.resolver(m, 0, 0)
			if not c.ofertas.is_empty() and (m.clubes.get(String(c.ofertas[0]["club_id"])) as Club).rep > c.club(m).rep + 3:
				c.aceptar_oferta(m, 0)
			var focos := CarreraPortero.focos_para(j)
			if c.energia < 40:
				c.foco = "descanso"
			else:
				var mejor := ""
				for f: String in focos:
					var a := String(focos[f][1])
					if a != "" and j.atributos.has(a) and (mejor == "" or int(j.atributos[a]) < int(j.atributos[String(focos[mejor][1])])):
						mejor = f
				c.foco = mejor
			c.entrenar(m)
			var titular := c.es_titular(m)
			var goles_antes := j.goles
			m.avanzar_semana(null)
			if titular:
				var g := j.goles - goles_antes
				j.goles -= g
				var nota := clampf(5.6 + float(j.ovr - 55) * 0.04 + float(g) * 0.9 + randf_range(-0.6, 0.6), 4.0, 9.5)
				c.tras_partido(m, {"minutos": 90, "goles": g, "asist": 0, "nota": snappedf(nota, 0.1), "titular": true, "encajados": randi_range(0, 2)})
			c.semana(m)
			energia += c.energia
			semanas += 1
		var j2 := c.jugador(m)
		var s: Dictionary = c.stats_temp
		print("T%d %s | media %d (techo %d) edad %d | nivel %d %s | fama %d rel %d | pj %d goles %d nota %.2f | energia media %d | talentos %d+%d | premios %s" % [
			t + 1, c.club(m).nombre, j2.ovr, j2.pot, j2.edad, CarreraRuta.nivel(c), CarreraRuta.capitulo(c)[1], c.fama, c.relacion_dt,
			int(s["pj"]), int(s["goles"]), c.nota_media(), energia / maxi(1, semanas), (c.ruta["talentos"] as Dictionary).size(), int(c.ruta["puntos"]),
			""])
		c.fin_de_temporada(m)
		print("   premios: %s · misiones cobradas: %s" % [str((c.ruta["temporada"] as Dictionary)["premios"]), str((c.ruta.get("misiones_hechas", {}) as Dictionary).keys())])
		m.nueva_temporada()
	get_tree().quit()
