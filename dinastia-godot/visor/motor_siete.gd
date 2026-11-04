class_name MotorSiete
extends RefCounted
## MENOS DE SIETE EN EL 3D JUGABLE (caza de fallos, 4-11-2026): el reglamento no deja jugar a un equipo con menos de 7. El `Partido` del núcleo ya lo
## aplicaba (`_revisar_siete`, modo DT); el motor del partido jugable (carrera del jugador) seguía jugando con 5. Ahora, tras cada roja: si un equipo
## se queda con menos de 7 en el campo, el partido se SUSPENDE y se le da por perdido 3-0 (o con el marcador, si su rival ya ganaba por 3 o más).

static func revisar(m: MotorJugable) -> void:
	if m.estado == "fin" or m.estado == "tanda":
		return
	for lado_local: bool in [true, false]:
		var quedan := m.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["es_local"]) == lado_local).size()
		if quedan >= 7:
			continue
		var i := 0 if lado_local else 1
		if int(m.goles[1 - i]) - int(m.goles[i]) < 3:
			m.goles[i] = 0
			m.goles[1 - i] = 3
		m.suspendido = true
		m.aviso.emit("🚫 Partido suspendido: %s se queda con menos de siete jugadores y lo pierde %d-%d" % ["local" if lado_local else "visitante", m.goles[0], m.goles[1]])
		m._terminar()
		return
