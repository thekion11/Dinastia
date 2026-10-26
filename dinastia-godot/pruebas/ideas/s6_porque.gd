extends BaseIdea
## SESIÓN 6 (26-10-2026), fila 16: la ayuda «¿por qué sube o baja?» de la ficha
## cuenta las MISMAS reglas que el núcleo (si alguien cambia la curva o los
## umbrales de los puntos de habilidad, esta prueba avisa) y se pinta bien.

func _probar() -> void:
	_titulo("S6: ¿POR QUÉ SUBE O BAJA? (ficha del jugador)")
	var m := _mundo(6006)
	var c := m.mi_club()
	## 1) La curva de edad dibujada = el freno por edad de ProgresoJugador.
	var j: Jugador = c.plantilla[0]
	var iguales := true
	for e in range(16, 24):
		j.edad = e
		j.pot = 99
		j.ovr = 50
		iguales = iguales and is_equal_approx(FichaPorque.ritmo_por_edad(e), ProgresoJugador.freno(j))
	j.edad = 24
	_comprobar(iguales and ProgresoJugador.freno(j) == 0.0 and FichaPorque.ritmo_por_edad(24) == 0.0,
		"la curva dibujada (16-24) es el freno por edad de ProgresoJugador")
	_comprobar(FichaPorque.ritmo_por_edad(29) == 0.0 and FichaPorque.ritmo_por_edad(30) < 0.0 and FichaPorque.ritmo_por_edad(33) < FichaPorque.ritmo_por_edad(31),
		"plano de 24 a 29 y cuesta abajo desde los 30, cada vez más")
	## 2) Los umbrales de los puntos de habilidad = Entrenamiento.repartir_puntos().
	var a: Jugador = c.plantilla[1]
	var b: Jugador = c.plantilla[2]
	var d: Jugador = c.plantilla[3]
	for x: Jugador in c.plantilla:
		x.partidos = 0
	a.edad = 25; a.partidos = FichaPorque.PJ_PUNTO
	b.edad = FichaPorque.EDAD_JOVEN; b.partidos = FichaPorque.PJ_JOVEN
	d.edad = FichaPorque.EDAD_JOVEN; d.partidos = FichaPorque.PJ_PUNTO
	var antes := {a.id: m.entrenamiento.puntos(a), b.id: m.entrenamiento.puntos(b), d.id: m.entrenamiento.puntos(d)}
	m.entrenamiento.repartir_puntos(c)
	_comprobar(m.entrenamiento.puntos(a) - int(antes[a.id]) == 1 and FichaPorque.faltan(a)["punto"] == 0 and FichaPorque.faltan(a)["joven"] == -1,
		"con %d partidos y 25 años: 1 punto, y la ficha dice que ya lo tiene" % FichaPorque.PJ_PUNTO)
	_comprobar(m.entrenamiento.puntos(b) - int(antes[b.id]) == 1 and FichaPorque.faltan(b)["punto"] == FichaPorque.PJ_PUNTO - FichaPorque.PJ_JOVEN and FichaPorque.faltan(b)["joven"] == 0,
		"con %d partidos y %d años: el punto de joven, y le faltan %d para el otro" % [FichaPorque.PJ_JOVEN, FichaPorque.EDAD_JOVEN, FichaPorque.PJ_PUNTO - FichaPorque.PJ_JOVEN])
	_comprobar(m.entrenamiento.puntos(d) - int(antes[d.id]) == 2, "joven con %d partidos: los dos puntos" % FichaPorque.PJ_PUNTO)
	b.partidos = FichaPorque.PJ_JOVEN - 1
	var antes_b := m.entrenamiento.puntos(b)
	m.entrenamiento.repartir_puntos(c)
	_comprobar(m.entrenamiento.puntos(b) == antes_b and FichaPorque.faltan(b)["joven"] == 1, "con un partido menos no gana nada y la ficha dice que le falta 1")
	## 3) El bloque se pinta, plegado, y se despliega.
	FichaPorque.abierto = false
	var lista := VBoxContainer.new()
	add_child(lista)
	var pal := {"suave": Color.GRAY, "texto": Color.WHITE, "acento": Color.CYAN, "verde": Color.GREEN, "rojo": Color.RED, "oro": Color.GOLD, "escala": 1.0}
	j.edad = 19; j.ovr = 60; j.pot = 75; j.partidos = 5
	FichaJugadorInfo.pintar_historial(lista, j, pal)
	var boton: Button = null
	var caja: VBoxContainer = null
	for h in lista.get_children():
		if h is Button and boton == null:
			boton = h
		if h is VBoxContainer and caja == null:
			caja = h
	_comprobar(boton != null and boton.text.contains("¿POR QUÉ SUBE O BAJA?") and caja != null and not caja.visible,
		"la ficha propia trae el plegable «¿por qué?», cerrado")
	boton.pressed.emit()
	_comprobar(caja.visible and boton.text.begins_with("▾"), "al pulsarlo se abre")
	var textos := ""
	for l in caja.find_children("*", "Label", true, false):
		textos += (l as Label).text + "\n"
	_comprobar(textos.contains("19 años") and textos.contains("Le quedan 15 puntos hasta su techo (75)") and textos.contains("de los 19 a los 26"),
		"habla de SU edad, de SU techo y del techo que se gasta")
	_comprobar(textos.contains("Lleva 5 partidos") and textos.contains("Con 7 más gana 1 punto") and textos.contains("con 3 más gana otro"),
		"y de los partidos que le faltan para los puntos de habilidad")
	var curva: Control = null
	for h in caja.get_children():
		if h is FichaPorque.CurvaEdad:
			curva = h
	curva.size = Vector2(260, 74)
	_comprobar(curva != null and TrazoSuave.cuantas(curva) == 2, "la curva de edad son dos líneas suaves (eje y curva)")
	## 4) Cada fase de la curva tiene su frase y está traducida.
	var ok_fases := true
	for e: int in [17, 21, 23, 26, 30, 33]:
		Idiomas.idioma = "es"
		var es := FichaPorque.fase_edad(e)
		Idiomas.idioma = "en"
		var en := FichaPorque.fase_edad(e)
		ok_fases = ok_fases and es != "" and en != es
	_comprobar(ok_fases and Idiomas.t("¿POR QUÉ SUBE O BAJA?") == "WHY DOES HE GO UP OR DOWN?", "las frases de las seis fases salen en inglés")
	Idiomas.idioma = "es"
	FichaPorque.abierto = false
	lista.queue_free()
