class_name MotorVentaja
extends RefCounted
## LA VENTAJA DE VERDAD (01-11-2026, IA R1 de `docs/04_auditorias/terceros_ia_motor_2026-11-01.md`, idea de League-Soccer
## `EvaluateAdvantage`). Antes el árbitro daba la ventaja y se olvidaba: si el atacante perdía el balón al segundo, nada.
## Ahora guarda la falta: si en `DADA_A` s de juego el equipo de la víctima pierde el balón (lo tiene un rival), vuelve a la
## falta y la pita donde fue; pasado ese tiempo, la ventaja se da por jugada. Si el juego se para antes (fuera, gol, otra
## falta), también. En el área no hay ventaja (ya lo filtra `_falta`). Sin tiradas de azar nuevas: el partido no cambia
## hasta que de verdad se vuelve a una falta.
const DADA_A := 3.5

## El árbitro deja seguir: brazos adelante y la falta queda pendiente.
static func dar(m: MotorJugable, lugar: Vector3, atacante_local: bool, nombre: String) -> void:
	m.aviso.emit("Ventaja")
	m._gesto_arbitro("arbitro_ventaja", 0.0, 1.6, {"mira": lugar})
	m.set_meta("ventaja", {"t": m.t, "te": m._t_estado, "lugar": lugar, "local": atacante_local, "nombre": nombre})

## La ventaja pendiente ({} si no hay).
static func pendiente(m: MotorJugable) -> Dictionary:
	return m.get_meta("ventaja", {})

## Cada paso de juego: ¿se dio por jugada, o se vuelve a la falta?
static func revisar(m: MotorJugable) -> void:
	var v := pendiente(m)
	if v.is_empty():
		return
	## `_t_estado` vuelve a cero al cambiar de estado: si es menor que al dar la ventaja, el juego se paró entre medias.
	if m.estado != "juego" or m._t_estado < float(v["te"]) or m.t - float(v["t"]) > DADA_A:
		m.remove_meta("ventaja")
		return
	if m.poseedor.is_empty() or bool(m.poseedor["es_local"]) == bool(v["local"]):
		return
	m.remove_meta("ventaja")
	var lugar: Vector3 = v["lugar"]
	m.duelos["ventaja_vuelta"] = int(m.duelos.get("ventaja_vuelta", 0)) + 1
	m.aviso.emit("No hubo ventaja: falta de %s" % String(v["nombre"]))
	m._gesto_arbitro("arbitro_silbato", 0.0, 0.9, {"mira": lugar})
	m._gesto_arbitro("senalar_falta", 0.8, 1.6, {"mira": lugar + Vector3(0, 0, m.dir_ataque(bool(v["local"])) * 10.0)})
	m._empezar_saque("falta", bool(v["local"]), Vector3(lugar.x, m.R, lugar.z))
