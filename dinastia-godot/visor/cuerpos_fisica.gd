class_name CuerposFisica
extends RefCounted
## LA GEOMETRÍA DEL CHOQUE ENTRE DOS CUERPOS, UNA SOLA VEZ (M-391, 3-11). `MatchPlayback._resolver_choques` (reparto a medias) y `MotorJugable._cuerpos`
## (reparto por masa y con velocidades) calculaban cada uno por su lado cuánto se pisan dos jugadores y por qué línea apartarlos. Aquí vive eso; cada uno
## sigue aplicando el reparto a su manera. La aritmética es la misma de antes, operación por operación (`igualdad_motor` lo comprueba).

## Dos cuerpos con diferencia de posición (dx, dz): devuelve (normal.x, solape, normal.z), con la normal unitaria de A hacia B, o `Vector3.ZERO` si no se tocan
## (`d >= minimo`). Si coinciden exactamente (d ≤ 1 mm) la normal sale de un giro fijo según `semilla` (`i * 7 + j`: siempre el mismo para el mismo par);
## `giro_z` es +1 o −1 según el sentido del giro (cada motor lo tenía en el suyo: `Vector2.rotated` frente a `Vector3.rotated` sobre Y).
static func solape(dx: float, dz: float, minimo: float, semilla: float, giro_z := 1.0) -> Vector3:
	var d2 := dx * dx + dz * dz
	if d2 >= minimo * minimo:
		return Vector3.ZERO
	var d := sqrt(d2)
	var nrm := Vector2(dx, dz) / d if d > 0.001 else Vector2(1.0, 0.0).rotated(semilla)
	if d <= 0.001 and giro_z < 0.0:
		nrm.y = -nrm.y
	return Vector3(nrm.x, minimo - d, nrm.y)
