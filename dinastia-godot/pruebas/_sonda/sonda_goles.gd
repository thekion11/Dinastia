extends Node
## SONDA DE GOLES DEL PARTIDO SIMULADO: goles por partido en la liga del jugador
## (modo jugador) y los del propio jugador, con el factor que se le pase.
##   FACTOR=1.0 PUESTO=DC SEMILLA=3 godot --headless --path . res://pruebas/_sonda/sonda_goles.tscn
func _ready() -> void:
	var semilla := int(OS.get_environment("SEMILLA")) if OS.get_environment("SEMILLA") != "" else 3
	var puesto := OS.get_environment("PUESTO") if OS.get_environment("PUESTO") != "" else "DC"
	var m := Mundo.new()
	m.generar(LigasActivas.para_generar(), semilla)
	m.mi_club_id = ""
	var c := CarreraJugador.crear(m, "Sonda Goles", puesto, false, semilla)
	m.carrera_jugador = c
	var of := CarreraComienzo.pruebas(m, semilla)
	CarreraComienzo.mudar(c, m, of[semilla % of.size()])
	var liga := CarreraRuta._liga_de(m, c.club(m))
	var j := c.jugador(m)
	var semanas := 0
	while m.temporada_en_curso() and semanas < 30:
		m.avanzar_semana(null)
		semanas += 1
	var goles := 0
	var partidos := 0
	for cl: Club in liga.clubes:
		var t: Dictionary = liga.tabla_puntos.get(cl.id, {})
		goles += int(t.get("gf", 0))
		partidos += int(t.get("pj", 0))
	var t_mio: Dictionary = liga.tabla_puntos.get(c.club(m).id, {})
	print("GOLES %s (%s) factor %s: %.2f por partido en la liga (%d goles, %d partidos) · mi club %d a favor y %d en contra en %d · yo %d goles en %d partidos" % [
		liga.nombre, liga.pais, OS.get_environment("FACTOR"), float(goles) / maxf(1.0, float(partidos) / 2.0), goles, partidos / 2,
		int(t_mio.get("gf", 0)), int(t_mio.get("gc", 0)), int(t_mio.get("pj", 0)), j.goles, j.partidos])
	get_tree().quit()
