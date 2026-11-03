class_name MotorCorner
extends RefCounted
## CÓRNERES POR DESVÍO (03-11-2026, ciclo 26 de la sesión líder). El motor saca ≈2 córneres por partido (real ≈10): un tiro que sale por la línea de fondo es SIEMPRE saque de puerta
## salvo que lo toque un defensor, y casi ningún tiro lo toca. Con `CORNER_DESVIO=p` (0 = como antes) un remate fallado que sale por el fondo es córner con probabilidad `p` (un bloqueo o un
## desvío de la defensa), no saque de puerta. Solo sortea con la bandera encendida (no cambia la huella apagada).
static var P := float(OS.get_environment("CORNER_DESVIO")) if OS.get_environment("CORNER_DESVIO") != "" else 0.0

## ¿Este remate que sale por el fondo fue desviado (córner)? Llamar ANTES de `_cerrar_tiro("fallo")` (que borra el tiro en vuelo).
static func desvio(m: MotorJugable) -> bool:
	return P > 0.0 and not m._tiro_vivo.is_empty() and m._rng.randf() < P
