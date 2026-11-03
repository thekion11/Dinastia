class_name MotorDescarga
extends RefCounted
## DESCARGA BAJO PRESIÓN (03-11-2026, ciclo 9 de la sesión líder: apoyos cortos ante presión). La traza de posesiones (`MotorTraza`) midió en 32 partidos que el 65 % de
## las pérdidas son ROBOS en un duelo y el 50 % ocurren en el medio campo: el portador solo volvía a decidir cada 0,7-1,35 s con un rival encima, y en ese tiempo
## lo alcanzaban. Con la bandera `PASE_DESCARGA=1`: (1) si un rival está a menos de `UMBRAL` m, decide YA (no espera al reloj de decisión), con una pausa mínima de
## `PAUSA` s entre decisiones y no justo tras recibir el balón (`TRAS_RECIBIR` s); (2) la espera entre decisiones con presión es `HOLGURA` (0,15) y no 0,5.
## Apagado (por defecto): no cambia nada.
const UMBRAL := 2.6
const PAUSA := 0.4
const TRAS_RECIBIR := 0.3
const HOLGURA := 0.15
static var _on := OS.get_environment("PASE_DESCARGA") == "1"

static func urge(m: MotorJugable, p: Dictionary, presion: float) -> bool:
	if not _on or presion >= UMBRAL:
		return false
	if m.t - float(p.get("tomo_en", -9.0)) < TRAS_RECIBIR or m.t - float(p.get("_urge_t", -9.0)) < PAUSA:
		return false
	p["_urge_t"] = m.t
	return true

static func holgura(base: float) -> float:
	return HOLGURA if _on and base < 0.6 else base
