class_name MotorPaseDirigido
extends RefCounted
## EL PASE DIRIGIDO (4-11-2026, mega auditoría 4: lo que le faltaba al táctil frente a FC Mobile y DLS: «tocar a un compañero = pase a él»). El pase del usuario iba al compañero que estuviera
## en la dirección del stick (`_companero_en_direccion`). Con los controles táctiles, un toque sobre un compañero en la pantalla (`PaseTactil`) lo guarda aquí durante `VENTANA` segundos y el siguiente pase
## del usuario con balón va a ÉL, sea cual sea la dirección del stick. Si caduca o ya no es válido (rival, portero, el mismo jugador), se usa el de la dirección de siempre.
const VENTANA := 0.6

## Pide que el siguiente pase vaya a `q` (un compañero del jugador que llevas).
static func pedir(m: MotorJugable, q: Dictionary) -> void:
	m.pase_dirigido = q
	m.pase_dirigido_hasta = m.t + VENTANA

## ¿Es `q` un receptor válido para `p`? (compañero de campo, no el mismo)
static func valido(p: Dictionary, q: Dictionary) -> bool:
	return not q.is_empty() and bool(q["es_local"]) == bool(p["es_local"]) and not bool(q["por"]) and String(q["id"]) != String(p["id"])

## El receptor del pase de `p`: el que se tocó (si vale y no ha caducado) o el de la dirección `dir`. Gasta la petición.
static func receptor(m: MotorJugable, p: Dictionary, dir: Vector3) -> Dictionary:
	var q: Dictionary = m.pase_dirigido
	m.pase_dirigido = {}
	if m.t < m.pase_dirigido_hasta and valido(p, q):
		return q
	return m._companero_en_direccion(p, dir)
