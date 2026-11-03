class_name MotorCorner
extends RefCounted
## CÓRNERES POR DESVÍO (03-11-2026, ciclo 26 de la sesión líder). El motor saca ≈2 córneres por partido (real ≈10): un tiro que sale por la línea de fondo es SIEMPRE saque de puerta
## salvo que lo toque un defensor, y casi ningún tiro lo toca. Con `CORNER_DESVIO=p` (0 = como antes) un remate fallado que sale por el fondo es córner con probabilidad `p` (un bloqueo o un
## desvío de la defensa), no saque de puerta. Solo sortea con la bandera encendida (no cambia la huella apagada).
static var P := float(OS.get_environment("CORNER_DESVIO")) if OS.get_environment("CORNER_DESVIO") != "" else 0.0

## ¿Este remate que sale por el fondo fue desviado (córner)? Llamar ANTES de `_cerrar_tiro("fallo")` (que borra el tiro en vuelo).
static func desvio(m: MotorJugable) -> bool:
	return P > 0.0 and not m._tiro_vivo.is_empty() and m._rng.randf() < P

## CABEZAZO CON MARCA (ciclo 26): al desviar córneres el cabezazo seguía siendo casi a puerta vacía (7 goles de 32 córneres = 22 %; real ≈3 %). Con `CABEZA_FALLO=f` (0 = como antes) el remate de cabeza
## falla con probabilidad `f` (y `f` + 0,25 si hay un rival a < 1,8 m, tope 0,95): se va fuera por un palo o por encima del larguero. Solo sortea con la bandera encendida.
static var CABEZA := float(OS.get_environment("CABEZA_FALLO")) if OS.get_environment("CABEZA_FALLO") != "" else 0.0

static func cabeza(m: MotorJugable, p: Dictionary, destino: Vector3) -> Vector3:
	if CABEZA <= 0.0:
		return destino
	var f := minf(CABEZA + (0.25 if m._presion(p) < 1.8 else 0.0), 0.95)
	if m._rng.randf() >= f:
		return destino
	var d := destino
	if m._rng.randf() < 0.6:
		d.x = (signf(d.x) if absf(d.x) > 0.3 else 1.0) * (m.PALO + m._rng.randf_range(0.4, 2.5))
	else:
		d.y = m.LARGUERO + m._rng.randf_range(0.4, 1.8)
	return d

