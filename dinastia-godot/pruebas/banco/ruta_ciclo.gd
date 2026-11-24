extends "res://pruebas/banco/ruta_ciclo_p1.gd"
## (Parte 2 de 2 de `ruta_ciclo.gd`.)

## La selección no toca el azar ni los ids del mundo (R-13).
func _rt_seleccion(st: Dictionary) -> void:
	var m: Mundo = st["m"]
	var c: CarreraJugador = st["c"]
	var j: Jugador = st["j"]
	## La selección no toca el azar ni los ids del mundo (R-13).
	c.convocatoria = {"pais": j.pais, "nombre": "Selección de prueba", "rival": "Croacia"}
	var azar0 := Azar._rng.state
	var seq0: int = m._seq_jugador
	var eq := c.equipos_seleccion(m)
	_comprobar(eq.size() == 2 and Azar._rng.state == azar0 and m._seq_jugador == seq0 and (eq[1] as Club).plantilla.size() >= 11,
		"  los equipos de la selección se arman sin mover el azar ni el contador del mundo (R-13)")
	c.convocatoria = {}


## Los textos con nombres: se traduce la plantilla y después se ponen los nombres (R-12).
func _rt_textos(st: Dictionary) -> void:
	var c: CarreraJugador = st["c"]
	var libre: Club = st["libre"]
	## Los textos con nombres: se traduce la plantilla y después se ponen los nombres (R-12).
	var antes_i := Idiomas.idioma
	Idiomas.idioma = "en"
	var ev := c._ev("x", "Vuelves a %s", "Un periodista te pregunta si te ves de titular en %s.", [], false, {"titulo_datos": [libre.nombre], "texto_datos": [libre.nombre]})
	var tit := CarreraEventosRuta.texto(ev, "titulo")
	var txt := CarreraEventosRuta.texto(ev, "texto")
	_comprobar(tit.contains(libre.nombre) and not tit.begins_with("Vuelves") and txt.contains(libre.nombre) and not txt.begins_with("Un periodista"),
		"  en inglés, «%s» y «%s»" % [tit, txt])
	Idiomas.idioma = antes_i
