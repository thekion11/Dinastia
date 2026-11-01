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

## EL ESTILO PROPIO DE CADA CLUB (01-11-2026, IA U8, idea de League-Soccer `TeamAIController`: parámetros tácticos continuos por
## equipo). La pizarra son enteros 0-2 y dos clubes con la misma pizarra jugaban idéntico. Ahora cada club suma a su `linea` y
## su `amplitud` un matiz continuo de ±`MATIZ`, fijo para ese club (sale de su país y sus colores, iguales en la base real y en
## la ficticia) y un poco de su reputación (el grande juega algo más arriba). Va en la táctica que arma el estadio
## (`f_linea`, `f_amplitud`) y lo lee `_forma`. `SIN_ESTILO_CLUB=1` = antes.
const MATIZ := 0.35
static var _sin_estilo := OS.has_environment("SIN_ESTILO_CLUB")

static func estilo_club(c: Club) -> Dictionary:
	if _sin_estilo or c == null:
		return {}
	var h := absi(hash("%s|%s|%s" % [c.pais, c.color1, c.color2]))
	var a := float(h % 1000) / 999.0 * 2.0 - 1.0
	var b := float((h / 1000) % 1000) / 999.0 * 2.0 - 1.0
	return {"f_linea": clampf(a * MATIZ + (float(c.rep) - 75.0) / 100.0, -0.5, 0.5), "f_amplitud": b * MATIZ}

## El matiz continuo `k` («linea», «amplitud») del equipo en la táctica del motor (0 si no lo trae).
static func f(m: MotorJugable, local: bool, k: String) -> float:
	return float((m.tacticas[0 if local else 1] as Dictionary).get("f_" + k, 0.0))

## TRES PERILLAS QUE EL 3D NO OÍA (01-11-2026, verificación de jugabilidad 389-391): «salida corta», «marca al hombre» y «tiro
## lejano» solo cambiaban el motor simulado (`Tactica.multiplicador_*`); `tactica_desde` no se las pasaba al partido 3D. Ahora
## llegan como 0/1 (sin la clave = no, como antes) y las leen el portero (`_ia_portero`), la defensa (`_ia_defensa`) y el portador
## (`_ia_portador`).
static func bandera(m: MotorJugable, local: bool, k: String) -> bool:
	return int((m.tacticas[0 if local else 1] as Dictionary).get(k, 0)) == 1

## Con salida corta el portero juega en corto 19 de cada 20 veces (sin ella, 4 de 5: la de siempre).
static func prob_salida_jugada(m: MotorJugable, local: bool) -> float:
	return 0.95 if bandera(m, local, "salida_corta") else 0.8
