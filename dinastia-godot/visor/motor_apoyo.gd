class_name MotorApoyo
extends RefCounted
## DESMARQUES DE APOYO POR CAMPO DE FUERZAS (03-11-2026, IA F3 de `docs/04_auditorias/terceros_ia_motor_2026-11-01.md`; idea de
## League-Soccer `GetSupportPosition_ForceField`, escrita aparte). Antes los dos compañeros más cercanos al portador se ofrecían
## SIEMPRE en el mismo sitio (9 m al lado y 5 m adelante), sin importar quién más estaba ahí ni si el pase estaba tapado.
## Ahora cada compañero cercano (< `ALCANCE` m del portador) suma fuerzas sobre su puesto de formación:
##  · ANILLO: busca una distancia cómoda de pase (`ANILLO` m) al portador: más lejos lo atrae, más cerca lo empuja;
##  · REPULSIÓN de compañeros (< `SEPARA` m) para no amontonarse, y de rivales (< `LEJOS_RIVAL` m) para no quedarse pegado a uno;
##  · LÍNEA DE PASE: si un rival tapa la línea al portador, sale hacia el lado libre;
##  · AVANCE: delanteros y extremos empujan hacia el arco rival; defensas, un poco hacia atrás.
## La fuerza total se limita a `TOPE` m para que el compañero no se vaya de su zona. `SIN_APOYO=1` = el ofrecimiento fijo de antes.
static var ALCANCE := float(OS.get_environment("APOYO_ALCANCE")) if OS.get_environment("APOYO_ALCANCE") != "" else 18.0   ## perilla ciclo 19 (3-11)
static var ANILLO := float(OS.get_environment("APOYO_ANILLO")) if OS.get_environment("APOYO_ANILLO") != "" else 12.0   ## perilla del ciclo 15 (3-11)
const SEPARA := 9.0
const LEJOS_RIVAL := 6.0
const TOPE := 12.0
static var _sin := OS.has_environment("SIN_APOYO")

static func activo() -> bool:
	return not _sin

## Fuerza (en el plano XZ) que actúa sobre `p` para ofrecerse al portador `c`. Vector3.ZERO = nada.
static func fuerza(m: MotorJugable, p: Dictionary, c: Dictionary) -> Vector3:
	var yo := m.pos(p)
	var pc := m.pos(c)
	var dz := m.dir_ataque(bool(p["es_local"]))
	var f := Vector3.ZERO
	## Anillo de pase alrededor del portador.
	var a := Vector3(yo.x - pc.x, 0, yo.z - pc.z)
	var d := a.length()
	if d < 0.01:
		a = Vector3(1, 0, 0)
		d = 0.01
	f += -a / d * clampf(d - ANILLO, -6.0, 6.0) * 0.8
	## Repulsión de compañeros y de rivales.
	for q: Dictionary in m.jugadores:
		if q == p or q == c or bool(q["por"]):
			continue
		var v := Vector3(yo.x - m.pos(q).x, 0, yo.z - m.pos(q).z)
		var dq := v.length()
		if bool(q["es_local"]) == bool(p["es_local"]):
			if dq < SEPARA and dq > 0.01:
				f += v / dq * (SEPARA - dq) * 0.7
		elif dq < LEJOS_RIVAL and dq > 0.01:
			f += v / dq * (LEJOS_RIVAL - dq) * 0.6
	## Línea de pase tapada: sale al lado libre (perpendicular a la línea).
	var seg := Vector3(yo.x - pc.x, 0, yo.z - pc.z)
	var largo := seg.length()
	if largo > 1.0:
		var lado := Vector3(-seg.z, 0, seg.x) / largo
		for q: Dictionary in m.jugadores:
			if bool(q["es_local"]) != bool(p["es_local"]) and not bool(q["por"]):
				var w := Vector3(m.pos(q).x - pc.x, 0, m.pos(q).z - pc.z)
				var t := w.dot(seg) / (largo * largo)
				if t > 0.1 and t < 0.9:
					var perp := w.dot(lado)
					if absf(perp) < 1.6:
						f += -lado * signf(perp if perp != 0.0 else 1.0) * (1.6 - absf(perp)) * 2.5
	## Avance según el puesto.
	match m._rol(p):
		"DC", "ED", "EI":
			f.z += dz * 3.0
		"DFC", "LD", "LI":
			f.z -= dz * 1.5
	if f.length() > TOPE:
		f = f.normalized() * TOPE
	return f

## Dónde se ofrece `p` al portador `c`, a partir de su puesto `obj`. Si no está al alcance, `obj` sin cambios.
static func punto(m: MotorJugable, p: Dictionary, c: Dictionary, obj: Vector3) -> Vector3:
	if _sin or m.pos(p).distance_to(m.pos(c)) > ALCANCE:
		return obj
	var f := fuerza(m, p, c)
	var o := m.pos(p) + f
	## Mezcla con su puesto para que no se vaya de su zona: manda la fuerza, pero el puesto ancla.
	var res := Vector3(lerpf(obj.x, o.x, 0.65), 0, lerpf(obj.z, o.z, 0.65))
	res.x = clampf(res.x, -m.ANCHO + 1.5, m.ANCHO - 1.5)
	res.z = clampf(res.z, -m.LARGO + 3.0, m.LARGO - 3.0)
	return res
