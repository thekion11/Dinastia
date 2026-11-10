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
