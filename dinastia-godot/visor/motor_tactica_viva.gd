class_name MotorTacticaViva
extends RefCounted
## LA TÁCTICA SEGÚN EL MARCADOR Y EL RELOJ (01-11-2026, IA U2 de `docs/04_auditorias/terceros_ia_motor_2026-11-01.md`, idea de
## League-Soccer `UpdateTactics`). Antes el bloque de un equipo de la CPU jugaba igual 0-0 en el minuto 5 que 0-1 en el 88. Ahora
## a su mentalidad (−1, 0, 1 en `_forma`) se le suma la URGENCIA: `POR_GOL` por gol de diferencia (pierde = adelanta, gana =
## repliega), con tope `TOPE`, y que pesa más cuanto más avanzado está el partido (nada antes del 30 %, del todo al 100 %).
## No toca al equipo que maneja el usuario (su táctica la elige él). `SIN_TACTICA_VIVA=1` = antes.
const POR_GOL := 0.35
const TOPE := 0.7
static var _sin := OS.has_environment("SIN_TACTICA_VIVA")

static func urgencia(m: MotorJugable, local: bool) -> float:
	var eq := 0 if local else 1
	if _sin or eq == m.control_equipo:
		return 0.0
	var dif := int(m.goles[1 - eq]) - int(m.goles[eq])
	if dif == 0:
		return 0.0
	var frac := m.tiempo_jugado() / maxf(2.0 * m.duracion_mitad, 0.001)
	return clampf(float(dif) * POR_GOL, -TOPE, TOPE) * smoothstep(0.3, 1.0, frac)
