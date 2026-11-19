class_name MejorasC4Bloque
extends RefCounted
## BLOQUE MÁS JUNTO AL DEFENDER (16-11-2026, frente 3; toca COLOCACIÓN: solo en C4 y con bandera). Medido con `pruebas/sonda_mando_f3.tscn`
## (parte B): sin balón, la línea de medios de C4 queda a ~13,6 m de la de defensas y el bloque mide ~39 m de largo; un bloque compacto de
## verdad deja ~8-12 m entre líneas (manuales de entrenadores, FIFA Training Centre) y en PES 2020 la IA defiende «en acordeón».
## `C4_BLOQUE=1`: al defender, los medios se retrasan `C4_BLOQUE_M` m y los delanteros `C4_BLOQUE_D` m (la línea de defensas no cambia).
static var ACTIVO := OS.get_environment("C4_BLOQUE") == "1"
static var medios := float(OS.get_environment("C4_BLOQUE_M")) if OS.get_environment("C4_BLOQUE_M") != "" else 2.5
static var delanteros := float(OS.get_environment("C4_BLOQUE_D")) if OS.get_environment("C4_BLOQUE_D") != "" else 4.0
const ROLES_MEDIO: Array[String] = ["MC", "MCD", "MCO", "MD", "MI"]   ## puesto de la formación (`slot_code`), no `_rol` (que junta MD con ED)
const ROLES_DELANTE: Array[String] = ["DC", "SD", "DEL", "ED", "EI"]

## La posición de la formación `r` del jugador `p` cuando su equipo no tiene el balón.
static func retrasar(_m: MotorJugable, p: Dictionary, r: Vector3) -> Vector3:
	if not ACTIVO:
		return r
	var rol := String(p.get("slot_code", ""))
	var atras := medios if ROLES_MEDIO.has(rol) else (delanteros if ROLES_DELANTE.has(rol) else 0.0)
	if atras <= 0.0:
		return r
	var d := MotorJugable.dir_ataque(bool(p["es_local"]))
	r.z = clampf(r.z - d * atras, -MotorJugable.LARGO + 4.0, MotorJugable.LARGO - 4.0)
	return r
