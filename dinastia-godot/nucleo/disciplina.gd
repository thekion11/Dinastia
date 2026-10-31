class_name Disciplina
extends RefCounted
## SUSPENSIÓN POR ACUMULACIÓN DE AMARILLAS (27-10-2026, fila 811 de la clasificación): la regla básica que faltaba. Cada `AMARILLAS_CICLO`
## amarillas de la temporada (5, 10, 15…) el jugador se pierde el siguiente partido. `Jugador.amarillas` ya se pone a cero al cerrar el año
## (`mundo_p7`); el descuento de la fecha lo hace la semana (`mundo_p5_p1`), igual que con una roja.
const AMARILLAS_CICLO := 5

## Llamar justo DESPUÉS de sumar la amarilla. Devuelve true si esta tarjeta completa un ciclo y deja al jugador sancionado.
static func acumula(j: Jugador) -> bool:
	if j == null or j.amarillas <= 0 or j.amarillas % AMARILLAS_CICLO != 0:
		return false
	sanciona(j)
	return true

## Un partido de sanción que cae en el partido de ESTA semana. Hasta ahora `_semana_del_plantel` descontaba esa fecha en cuanto acababa la
## jornada y la roja no hacía perderse ningún partido: se apunta la semana para que se cumpla en el siguiente.
static func sanciona(j: Jugador) -> void:
	if j.suspension <= 0:
		j.susp_semana = Jugador.semana_global
	j.suspension = maxi(j.suspension, 1)

static func frase(j: Jugador) -> String:
	return Idiomas.t("%s ve su amarilla número %d de la temporada: se pierde el próximo partido.") % [j.nombre, j.amarillas]
