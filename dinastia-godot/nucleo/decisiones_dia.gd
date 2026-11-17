class_name DecisionesDia
extends RefCounted
## LAS DECISIONES CON OPCIONES DEL AVANCE POR DÍAS (17-11-2026, orden de Auditoría: «con su efecto real en el club y una prueba en el banco»). Un evento importante puede
## traer opciones: aquí se sacan del sistema que lo originó (la guerra de agentes de `Cantera`, los asuntos de la academia de `EventosCantera`) y se RESUELVEN con el
## mismo código que ya usaban esas pantallas (`Cantera.resolver_agente`, `EventosCantera.resolver`): el efecto es el de siempre (confianza del agente, moral, saldo,
## fichajes, chicos que se quedan o se van). Este archivo no inventa efectos ni textos: reparte lo que dicen los sistemas.

## Las opciones del evento ahora mismo: [{"id": "a", "titulo": …}, {"id": "b", "titulo": …}] o [] si no hay decisión abierta.
static func opciones(m: Mundo, ev: Dictionary) -> Array:
	match String((ev.get("causa", {}) as Dictionary).get("id", "")):
		"guerra_agentes":
			if m.cantera != null and not m.cantera.exigencia.is_empty():
				var e: Dictionary = m.cantera.exigencia
				return [{"id": "a", "titulo": String(e.get("opcion_a", ""))}, {"id": "b", "titulo": String(e.get("opcion_b", ""))}]
		"evento_cantera":
			if m.eventos_cantera != null and not m.eventos_cantera.pendiente.is_empty():
				var p: Dictionary = m.eventos_cantera.pendiente
				return [{"id": "a", "titulo": String(p.get("a", ""))}, {"id": "b", "titulo": String(p.get("b", ""))}]
	return []

## Aplica la decisión `op` ("a" o "b") y devuelve {titulo, cuerpo} (lo que dice el sistema), o {} si ya no había nada que decidir.
static func resolver(m: Mundo, ev: Dictionary, op: String) -> Dictionary:
	match String((ev.get("causa", {}) as Dictionary).get("id", "")):
		"guerra_agentes":
			return m.cantera.resolver_agente(op) if m.cantera != null else {}
		"evento_cantera":
			return m.eventos_cantera.resolver(op, m.academia, m.mi_club()) if m.eventos_cantera != null else {}
	return {}
