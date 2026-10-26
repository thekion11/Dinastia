extends BaseIdea
## Carrera de Jugador: los avisos de la semana se traducen frase a frase. Antes
## se unían con «·» con los números dentro y en otros idiomas salían en castellano.

func _probar() -> void:
	_titulo("PCAR: AVISOS DE LA SEMANA EN OTRO IDIOMA")
	var m := _mundo(4243)
	var c := CarreraJugador.crear(m, "Tomás Prueba", "DC", false, 78)
	var j := c.jugador(m)
	var antes := Idiomas.idioma
	Idiomas.idioma = "en"
	c.agenda = "social"
	c.energia = 90
	var a := CarreraAgenda.aplicar(c, j)
	_comprobar(a.begins_with("Social life: +"), "agenda social en inglés («%s»)" % a)
	c.agenda = "descanso"
	a = CarreraAgenda.aplicar(c, j)
	_comprobar(a == "Rest and physio: +12 energy." or not a.contains("Descanso"), "agenda de descanso en inglés («%s»)" % a)
	c.foco = "descanso"
	var e := c.entrenar(m)
	_comprobar(e.begins_with("You rested: energy "), "descanso de entrenamiento en inglés («%s»)" % e)
	c.foco = "tiro"
	c.energia = 90
	e = c.entrenar(m)
	_comprobar(not e.contains("sube a") and not e.contains("Semana dura"), "entrenamiento en inglés («%s»)" % e)
	for f: String in ["Final %d-%d, tu nota %.1f (%d').", "No saliste del banco.", "Terminó la temporada.", "El DT te cambió.",
			"Jugaste (simulado): %d gol(es), nota %.1f.", "Entraste en el %d' (simulado): nota %.1f.", "¡%s!",
			"Calentaste toda la segunda parte, pero el DT no te hizo entrar."]:
		_comprobar(Idiomas.t(f) != f, "traducida: «%s»" % f)
	Idiomas.idioma = antes
	_comprobar(CarreraAgenda.aplicar(c, j).begins_with("Descanso y fisio"), "en castellano no cambia")
