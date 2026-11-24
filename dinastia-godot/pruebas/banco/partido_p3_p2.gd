extends "res://pruebas/banco/partido_p3_p1.gd"
## [Capa 3b de `partido.gd`] _fallos_dentro_del_arco, _fallos_rasos_altos: auxiliares del tiro fallido.

## Cuántos de 200 tiros fallidos caen dentro del arco (tiene que ser ninguno).
func _fallos_dentro_del_arco(motor: MotorJugable, tirador: Dictionary, destino: Vector3) -> int:
	var dentro := 0
	for i in 200:
		var d := MotorTiroLimpio.fallar(motor, tirador, destino, 28.0, 1.0)
		if d != destino and absf(d.x) < motor.PALO and d.y < motor.LARGUERO:
			dentro += 1
	return dentro

## Cuántos de 200 tiros rasos fallidos suben por encima de 0,8 m (tiene que ser ninguno).
func _fallos_rasos_altos(motor: MotorJugable, tirador: Dictionary, objetivo: Vector3) -> int:
	var altos := 0
	for i in 200:
		if MotorTiroLimpio.fallar(motor, tirador, objetivo, 28.0, 1.0).y > 0.8:
			altos += 1
	return altos
