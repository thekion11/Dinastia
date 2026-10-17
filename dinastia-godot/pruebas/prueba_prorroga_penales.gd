extends Node
## PRÓRROGA Y PENALES EN EL CÉSPED (17-10-2026). Una eliminatoria jugada con
## el motor real que se fuerza a empatar al 90' y al 120': tiene que haber
## prórroga, el reloj llegar al 120', jugarse la tanda en el 3D (la mitad con
## el usuario tirando los penales de su equipo), ganar alguien, y el acta y
## `Partido.penales()` decir lo mismo que el césped. Y en liga, nada de eso.
##   godot --headless --path . res://pruebas/prueba_prorroga_penales.tscn
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
	## Sin VAR: sus revisiones esperan un temporizador que aquí no corre.
	Partido.ctx_factor_tarjetas = 1.0
	var par := m.proximo_partido()
	await _eliminatoria(par)
	await _liga(par)
	_ok(MotorJugable.tanda_decidida([[true, true, true], [false, false, false]]), "3-0 tras tres cada uno: decidida")
	_ok(not MotorJugable.tanda_decidida([[true, true, true, true, true], [true, true, true, true, true]]), "5-5: muerte súbita")
	_ok(MotorJugable.tanda_decidida([[true, true, true, true, true, true], [true, true, true, true, true, false]]), "6-5 en la muerte súbita: decidida")
	_ok(not MotorJugable.tanda_decidida([[true, true, true, true, true, true], [true, true, true, true, true]]), "muerte súbita: el segundo aún tira")
	_fin()

## Corre el motor como `_simular_resto_motor`, empatando a mano justo antes
## del final de la segunda parte y de la prórroga.
func _eliminatoria(par: Array) -> void:
	var partido := Partido.new(par[0], par[1])
	var vista := VistaEstadio.new()
	vista.eliminatoria = true
	add_child(vista)
	vista.abrir(par[0], 0.8, par[1], partido)
	var motor: MotorJugable = vista.get("_motor")
	_ok(motor != null and motor.eliminatoria, "la eliminatoria llega al motor real")
	if motor == null:
		return
	var pen_ev: Array = []
	partido.terminado.connect(func(_gl: int, _gv: int) -> void:
		## Lo que hace `PartidoVivo._al_final`: pedir los penales al pitar.
		pen_ev.append(partido.penales().duplicate()))
	motor.autopiloto = true
	motor.control_equipo = -1
	vista.set("_descanso_hecho", true)
	vista.parar_en_descanso = false
	var relojes := {}
	var forzados := 0
	var vio_prorroga := false
	var tiros_usuario := 0
	var cargando := 0.0
	var pasos := 0
	var dt := 1.0 / 20.0
	while motor.estado != "fin" and pasos < 60 * 3600:
		## Empate forzado al final de la segunda parte y de la prórroga.
		if motor.estado == "juego" and motor.mitad in [2, 4] and motor.goles[0] != motor.goles[1] \
				and motor.t > motor.dur_mitad() + motor._anadido_de(motor.mitad) - 3.0:
			motor._gol(int(motor.goles[0]) < int(motor.goles[1]))
			forzados += 1
		if motor.prorroga:
			vio_prorroga = true
		## En la tanda manejas a tu equipo: tus penales los tiras tú.
		if motor.estado == "tanda" and motor.control_equipo < 0:
			motor.control_equipo = 0
			motor.autopiloto = false
		if motor.estado == "tanda" and String(motor.tanda.get("fase", "")) == "apuntar":
			if cargando <= 0.0:
				tiros_usuario += 1
				Input.action_press("jugar_tiro")
			cargando += dt
			if cargando > 0.55:
				Input.action_release("jugar_tiro")
		else:
			if cargando > 0.0:
				Input.action_release("jugar_tiro")
			cargando = 0.0
		motor.paso(dt)
		pasos += 1
		if motor.estado == "juego":
			relojes[motor.minuto()] = true
		if pasos % 20 == 0:
			vista.call("_sincronizar_partido")
			vista.call("_refrescar_marcador")
	Input.action_release("jugar_tiro")
	vista.call("_sincronizar_partido")
	var marcador: Label = vista.get("_marcador")
	var pen := partido.penales()
	print("ELIMINATORIA %d-%d · penales %s · tanda %s · forzados %d · tus penales %d · acta %d'" % [
		partido.goles_local, partido.goles_visita, str(pen), str(motor.tanda.get("tiros", [])), forzados, tiros_usuario, partido.minuto])
	_ok(vio_prorroga and partido.minutos_fin == 120, "empate al 90': hay prórroga y el acta sigue hasta el 120'")
	_ok(relojes.has(95) and relojes.has(110) and relojes.has(119), "el reloj del césped pasa por el 95', el 110' y el 119'")
	_ok(partido.terminado_ya and partido.minuto == 120, "el acta termina en el 120' (%d')" % partido.minuto)
	_ok(partido.goles_local == int(motor.goles[0]) and partido.goles_visita == int(motor.goles[1]), "el marcador del acta es el del césped")
	_ok(partido.goles_local == partido.goles_visita, "empate tras la prórroga")
	_ok(not motor.tanda.is_empty(), "hay tanda de penales en el césped")
	var gl := motor.goles_tanda(0)
	var gv := motor.goles_tanda(1)
	_ok(gl != gv, "gana alguien la tanda (%d-%d)" % [gl, gv])
	var tiros: Array = motor.tanda.get("tiros", [[], []])
	_ok(MotorJugable.tanda_decidida(tiros) and absi((tiros[0] as Array).size() - (tiros[1] as Array).size()) <= 1, "la tanda acaba cuando está decidida, alternando")
	_ok(partido.penales_en_cesped and int(pen[0]) == gl and int(pen[1]) == gv, "`penales()` devuelve la tanda del césped")
	_ok(pen_ev.size() == 1 and pen_ev[0] == [gl, gv], "al pitar el final, los penales ya son los del césped")
	_ok(partido.penales() == pen, "los penales no se vuelven a sortear")
	_ok(tiros_usuario >= 3, "tus penales los tiras tú (%d)" % tiros_usuario)
	var tipos := []
	for e: Dictionary in partido.cronica:
		tipos.append(String(e.get("tipo", "")))
	_ok(tipos.has("prorroga") and tipos.count("penales") == 1, "la crónica cuenta la prórroga y la tanda una vez")
	_ok(marcador != null and marcador.text.contains(Idiomas.t("PEN.")), "el marcador enseña la tanda (%s)" % (marcador.text if marcador != null else ""))
	_ok(vista.get("_marcador_tanda") != null, "hay marcador de círculos de la tanda")
	## Lo que usa la copa para saber quién pasa: el mismo objeto, el mismo ganador.
	var copa := Copa.new("Copa de prueba")
	copa.vivos.assign([partido.local, partido.visita])
	var res := copa.jugar_ronda(partido)
	var pasa: Club = (res[0] as Dictionary)["pasa"] if not res.is_empty() else null
	_ok(pasa == (partido.local if gl > gv else partido.visita), "la copa da por clasificado al que ganó la tanda del césped")
	vista.queue_free()
	await get_tree().process_frame

## En liga, con empate al 90' se acaba: ni prórroga ni tanda.
func _liga(par: Array) -> void:
	var partido := Partido.new(par[0], par[1])
	var vista := VistaEstadio.new()
	add_child(vista)
	vista.abrir(par[0], 0.8, par[1], partido)
	var motor: MotorJugable = vista.get("_motor")
	if motor == null:
		_ok(false, "liga: el motor real juega")
		return
	motor.autopiloto = true
	motor.control_equipo = -1
	vista.set("_descanso_hecho", true)
	vista.parar_en_descanso = false
	var pasos := 0
	while motor.estado != "fin" and pasos < 60 * 3600:
		if motor.estado == "juego" and motor.mitad == 2 and motor.goles[0] != motor.goles[1] \
				and motor.t > motor.dur_mitad() + motor._anadido_de(2) - 3.0:
			motor._gol(int(motor.goles[0]) < int(motor.goles[1]))
		motor.paso(1.0 / 20.0)
		pasos += 1
		if pasos % 20 == 0:
			vista.call("_sincronizar_partido")
	vista.call("_sincronizar_partido")
	_ok(not motor.prorroga and motor.tanda.is_empty() and motor.mitad == 2, "liga empatada: sin prórroga ni tanda")
	_ok(partido.terminado_ya and partido.minuto == 90 and not partido.penales_en_cesped, "liga: el acta termina en el 90'")
	vista.queue_free()
	await get_tree().process_frame

func _fin() -> void:
	print("===== FIN PRÓRROGA Y PENALES. %d fallos =====" % _fallos)
	get_tree().quit(0 if _fallos == 0 else 1)
