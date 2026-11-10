class_name LeagueReglas
extends RefCounted
## REGLAS Y AJUSTES DE JUEGO DE LEAGUE-SOCCER (10-11-2026; L `gameplaytuning.hpp`), portados a GDScript como funciones puras.
## Atribución Apache 2.0: `terceros/league_soccer/NOTICE_DINASTIA.md`. Plan: `docs/04_auditorias/MOTOR_LEAGUE_SOCCER_PLAN.md`.

## L gameplaytuning.hpp EvaluateAdvantage: 0 = seguir, 1 = volver a la falta, 2 = ventaja jugada.
static func ventaja(ahora_ms: float, falta_ms: float, perdio: bool) -> int:
	var pasado := ahora_ms - falta_ms
	if pasado > 3500.0:
		return 2
	if pasado > 600.0 and perdio:
		return 1
	return 0

## L gameplaytuning.hpp GetFatigueWorkloadFactor.
static func carga_fatiga(vel: float, vmax: float, con_balon: bool) -> float:
	if vmax <= 0.0:
		return 1.0
	var sprint := clampf((clampf(vel / vmax, 0.0, 1.0) - 0.55) / 0.45, 0.0, 1.0)
	return 0.90 + sprint * sprint * 0.36 + (sprint * 0.06 if con_balon else 0.0)

## L aitactics.hpp ShouldStartZonePressure: presión de zona al perder el balón, según la palanca, el campo y el primer defensor.
static func empezar_presion_zona(presion: float, territorio: float, dist_primero: float) -> bool:
	var s := clampf(presion, 0.0, 1.0)
	if s < 0.05:
		return false
	return territorio >= 0.55 - s * 0.90 and dist_primero <= 5.0 + s * 8.0

## L aitactics.hpp GetZonePressureDuration_ms (en segundos).
static func duracion_presion_zona(presion: float) -> float:
	return (700.0 + clampf(presion, 0.0, 1.0) * 1600.0) / 1000.0

## L aitactics.hpp GetAttackingRunThreshold / GetAttackingRunDuration_ms.
static func umbral_carrera(contra: float) -> float:
	return 0.62 - clampf(contra, 0.0, 1.0) * 0.24

static func duracion_carrera_ms(contra: float) -> float:
	return 2800.0 + clampf(contra, 0.0, 1.0) * 2200.0

## L aitactics.hpp GetSupportWebScale (palanca «support_distance»).
static func red_apoyo(distancia := 0.5) -> float:
	return 0.68 + clampf(distancia, 0.0, 1.0) * 0.20
