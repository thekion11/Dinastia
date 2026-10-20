extends Node
## EL ACTA CUADRA CON EL CÉSPED (13-10-2026). El partido del DT jugado con el
## motor real: se abre en 3D, se simula hasta el final y se comprueba que lo
## que va a la tabla es lo que pasó en el campo.
##   godot --headless --path . res://pruebas/prueba_partido_motor.tscn
var _fallos := 0
func _ok(c: bool, txt: String) -> void:
	print(("  ok    " if c else "  FALLO ") + txt)
	if not c:
		_fallos += 1

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	Partido.ctx_club_id = m.mi_club_id
	var par := m.proximo_partido()
	var partido := Partido.new(par[0], par[1])
	var vista := VistaEstadio.new()
	add_child(vista)
	vista.abrir(par[0], 0.8, par[1], partido)
	var motor: MotorJugable = vista.get("_motor")
	_ok(motor != null, "el partido del DT lo juega el motor real")
	if motor == null:
		_fin()
		return
	_ok(partido.motor_externo, "el acta no sortea goles mientras juega el motor")
	var goles_ev := [0]
	partido.gol.connect(func(_c: Club, _a: Jugador, _m: int, _s: Jugador) -> void: goles_ev[0] += 1)
	var cambios := [0]
	partido.cambio_hecho.connect(func(_s: Jugador, _e: Jugador, _m: int) -> void: cambios[0] += 1)
	vista.call("_simular_resto_motor")
	print("FINAL %s %d-%d %s · motor %s · remates %d-%d · posesión %.0f · córners %d-%d · cambios %d" % [
		partido.local.nombre, partido.goles_local, partido.goles_visita, partido.visita.nombre, str(motor.goles),
		partido.remates_local, partido.remates_visita, partido.posesion_local, partido.corners_local, partido.corners_visita, cambios[0]])
	_ok(partido.terminado_ya and partido.minuto >= 90, "el partido termina en el 90'")
	_ok(partido.goles_local == int(motor.goles[0]) and partido.goles_visita == int(motor.goles[1]), "el marcador del acta es el del césped")
	var anulados := 0
	for e: Dictionary in partido.cronica:
		if String(e.get("tipo", "")) == "gol_anulado":
			anulados += 1
	_ok(goles_ev[0] == partido.goles_local + partido.goles_visita + anulados, "cada gol se anota una vez (%d anulados por el VAR)" % anulados)
	_ok(partido.remates_local >= partido.goles_local and partido.remates_visita >= partido.goles_visita, "los remates incluyen los goles")
	_ok(partido.fueras_local == int(motor.fueras_de_juego[0]) and partido.fueras_visita == int(motor.fueras_de_juego[1]),
		"los fueras de juego del acta son los del césped (%d-%d)" % [partido.fueras_local, partido.fueras_visita])
	_ok(partido.remates_local + partido.remates_visita >= 4, "hay remates de verdad (%d)" % (partido.remates_local + partido.remates_visita))
	var en_cronica := 0
	for e: Dictionary in partido.cronica:
		if String(e.get("tipo", "")) == "gol":
			en_cronica += 1
	_ok(en_cronica == partido.goles_local + partido.goles_visita, "la crónica tiene todos los goles")
	_ok(cambios[0] >= 1, "el DT de la IA hace cambios con los cansados (%d)" % cambios[0])
	## LAS ESTADÍSTICAS EN VIVO (16-10-2026): ven los mismos remates que el acta.
	var st: EstadisticasVivo = vista.get("_stats")
	_ok(st != null, "hay estadísticas en vivo")
	if st != null:
		var vistos := st.n_tiros(true) + st.n_tiros(false)
		var acta := partido.remates_local + partido.remates_visita
		var goles_st := 0
		for t: Dictionary in st.tiros:
			if String(t["res"]) == "gol":
				goles_st += 1
		print("ESTADÍSTICAS tiros %d (acta %d) · xG %.2f-%.2f · goles en el mapa %d" % [vistos, acta, st.xg(true), st.xg(false), goles_st])
		_ok(vistos == acta, "el mapa de tiros tiene los remates del acta (%d vs %d)" % [vistos, acta])
		_ok(goles_st == partido.goles_local + partido.goles_visita, "cada gol está en el mapa de tiros")
		var muestras := 0
		for eq in 2:
			for n: int in (st.calor[eq] as PackedInt32Array):
				muestras += n
		_ok(muestras > 1000, "el mapa de calor tiene muestras de todo el partido (%d)" % muestras)
		var filas := st.resumen(partido, motor)
		_ok(filas.size() >= 10, "el panel tiene %d filas de estadísticas" % filas.size())
	## EL VAR ANULA (17-10-2026): el gol vuelve atrás en acta, goleador y crónica.
	var p2 := Partido.new(par[0], par[1])
	var autor: Jugador = p2.local.plantilla[0] if not p2.local.plantilla.is_empty() else null
	var g0 := autor.goles if autor != null else 0
	p2.gol_externo(true, autor.id if autor != null else "", "")
	p2.anular_gol_externo(true, autor.id if autor != null else "")
	var marcado := false
	for e: Dictionary in p2.cronica:
		if String(e.get("tipo", "")) == "gol_anulado":
			marcado = true
	_ok(p2.goles_local == 0 and (autor == null or autor.goles == g0) and marcado, "el VAR anula el gol en el acta, el goleador y la crónica")
	vista.queue_free()
	await get_tree().process_frame
	_ok(not partido.motor_externo, "al cerrar el 3D el partido vuelve a jugarse solo")
	_fin()

func _fin() -> void:
	print("===== FIN PARTIDO MOTOR. %d fallos =====" % _fallos)
	get_tree().quit(0 if _fallos == 0 else 1)
