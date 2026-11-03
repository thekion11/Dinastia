class_name MotorAncla
extends RefCounted
## EL ANCLA A LA POSICIÓN BASE (03-11-2026, vídeo del dueño: «enjambre», defensas que abandonan su zona). Nadie, salvo el que presiona y el
## segundo (que `MotorPresion` elige y limita a dos), puede alejar su objetivo de su puesto (el dinámico de `MotorRoles`) más de un RADIO
## que depende de su línea: defensas 15 m, medios 20 m, extremos 24 m, delanteros 26 m. Así el deseo de seguir el balón o a un rival no
## rompe la formación: el objetivo se recorta al borde del círculo, en la misma dirección. `SIN_ANCLA=1` = sin ancla, como antes.
const RADIOS := {"DFC": 15.0, "LD": 15.0, "LI": 15.0, "MC": 20.0, "ED": 24.0, "EI": 24.0, "DC": 26.0}
const RADIO_DEFECTO := 22.0
static var _sin := OS.has_environment("SIN_ANCLA")

static func radio(m: MotorJugable, p: Dictionary) -> float:
	return float(RADIOS.get(m._rol(p), RADIO_DEFECTO)) * MotorAdaptacion.escala_radio(m, p)   ## habilidades, formación y clima (3-11)

static func limitar(m: MotorJugable, p: Dictionary, obj: Vector3) -> Vector3:
	if _sin:
		return obj
	var base: Vector3 = MotorRoles.base(m, p)
	var v := Vector3(obj.x - base.x, 0.0, obj.z - base.z)
	var r := radio(m, p)
	if v.length() <= r:
		return obj
	var res := base + v.normalized() * r
	return Vector3(res.x, obj.y, res.z)
