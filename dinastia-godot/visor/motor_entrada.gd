class_name MotorEntrada
extends RefCounted
## ENTRAR EN EL MOMENTO BUENO (03-11-2026, ciclo 12 de la sesión líder: «la defensa entra poco»). Hoy la IA intenta la entrada siempre que un rival está a menos de ≈1,25 m del portador,
## sin mirar el momento: ≈10 intentos por equipo y partido (reales ≈16-20). Con `ENTRADA_MOMENTO` (por defecto; `=0` lo apaga) el radio de la entrada CRECE en los momentos en que el fútbol real manda entrar:
##  · el portador va de ESPALDAS al defensor (+`ESPALDAS` m);
##  · el balón se le ha ido (más de `LARGO_MIN` m de su pie: control largo) (+`LEJOS` m);
##  · está pegado a la banda (a menos de `BANDA_MAX` m de la línea) (+`BANDA` m);
## con tope de `TOPE` m de aumento. En el resto del tiempo no cambia nada (contención). Apagado: devuelve el radio base.
const ESPALDAS := 0.5
const LEJOS := 0.5
const BANDA := 0.3
const LARGO_MIN := 0.8
const BANDA_MAX := 3.0
const TOPE := 0.8
static var _on := OS.get_environment("ENTRADA_MOMENTO") != "0"   ## ENCENDIDO por defecto desde el 3-11 (ciclo 12: intentos por equipo 10,5 → 20,3, goles 2,56 en 32 partidos); `ENTRADA_MOMENTO=0` = como antes

static func radio(m: MotorJugable, p: Dictionary, victima: Dictionary, base: float) -> float:
	if not _on:
		return base
	var extra := 0.0
	var pv := m.pos(victima)
	var n: Node3D = victima["node"]
	var hacia_def := (m.pos(p) - pv)
	hacia_def.y = 0.0
	if hacia_def.length() > 0.05:
		var fwd := Vector3(sin(n.rotation.y), 0.0, cos(n.rotation.y))
		if fwd.dot(hacia_def.normalized()) < -0.2:
			extra += ESPALDAS
	if m.balon.position.distance_to(pv) > LARGO_MIN:
		extra += LEJOS
	if absf(pv.x) > m.ANCHO - BANDA_MAX:
		extra += BANDA
	return base + minf(extra, TOPE)
