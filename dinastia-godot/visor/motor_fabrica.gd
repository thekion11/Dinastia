class_name MotorFabrica
extends RefCounted
## LA FÁBRICA DEL MOTOR DEL PARTIDO (11-11-2026, sesión 11). Una sola puerta para crear el motor: según `MotorEleccion` (la letra
## que el dueño eligió a ciegas en Ajustes; por defecto, el de siempre) o, con la bandera vieja `MOTOR_LEAGUE=1` / `MotorLeague.activo`,
## el de League. `motor_id` queda anotado en el motor (`set_meta`) para el voto y las cifras.

static func crear(forzar := "") -> MotorJugable:
	var cual := forzar if MotorEleccion.TODOS.has(forzar) else MotorEleccion.motor_activo()
	if cual == "siempre" and MotorLeague.activo:
		cual = "league"
	var m: MotorJugable
	match cual:
		"league":
			m = MotorLeague.new()
		"combinado", "combinado_c2", "combinado_c3", "combinado_c4":
			m = MotorCombinado.new()
			(m as MotorCombinado).aplicar_variante(cual)
		_:
			m = MotorJugable.new()
	m.set_meta("motor_id", cual)
	return m
