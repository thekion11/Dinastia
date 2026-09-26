class_name Retos
extends RefCounted
## LOS RETOS (26-9-2026, E16: "terminar los modos de juego faltantes"). La
## tarjeta "Retos" del menú prometía "cinco situaciones montadas a mano con
## una meta concreta" y no llevaba a ningún sitio. Cada reto elige el club, lo
## prepara (deudas, plantel, confianza...) y fija UNA meta que se juzga al
## cerrar la temporada: se cumple o no, con su puntaje y su trofeo en la
## vitrina de la carrera. Después la partida sigue como una carrera normal.

## [id, icono, título, planteamiento, meta]
const LISTA := [
	["david", "🪨", "David contra Goliat", "Tomas al club de menor reputación de la Primera chilena.", "Terminar entre los ocho primeros"],
	["ascenso", "📈", "Del barro a la gloria", "El colista de Ascenso, con un plantel corto.", "Ascender: terminar entre los dos primeros de Ascenso"],
	["deuda", "💸", "El club en ruinas", "Un club grande con una deuda enorme y los acreedores en la puerta.", "Cerrar la temporada con la caja en positivo"],
	["cantera", "🌱", "La generación dorada", "Un club medio sin dinero para fichar: la solución está en la academia.", "Terminar con seis canteranos en el plantel y sin descender"],
	["titulo", "🏆", "Obligados a ganar", "El grande de la liga, con la directiva impaciente: confianza al mínimo.", "Salir campeón"],
]

static func datos(id: String) -> Array:
	for r: Array in LISTA:
		if String(r[0]) == id:
			return r
	return []

## Elige el club del reto y lo prepara. Devuelve el club, o null.
static func montar(m: Mundo, id: String) -> Club:
	var primera: Array[Club] = []
	var ascenso: Array[Club] = []
	for c: Club in m.clubes.values():
		if c.pais != "CHI":
			continue
		if c.division == 1:
			primera.append(c)
		elif c.division == 2:
			ascenso.append(c)
	primera.sort_custom(func(a: Club, b: Club) -> bool: return a.rep < b.rep)
	ascenso.sort_custom(func(a: Club, b: Club) -> bool: return a.rep < b.rep)
	var c: Club = null
	match id:
		"david":
			c = primera[0] if not primera.is_empty() else null
		"ascenso":
			c = ascenso[0] if not ascenso.is_empty() else null
			if c != null:
				## Plantel corto: se van los cinco mejores.
				var orden := c.plantilla.duplicate()
				orden.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
				for j: Jugador in orden.slice(0, mini(5, maxi(0, orden.size() - 16))):
					c.soltar(j)
		"deuda":
			c = primera[primera.size() - 2] if primera.size() >= 2 else null
			if c != null:
				c.saldo = -int(round(Eco.ref_caja(float(c.rep)) * 0.35))
		"cantera":
			c = primera[primera.size() / 2] if not primera.is_empty() else null
			if c != null:
				c.saldo = int(round(Eco.ref_caja(float(c.rep)) * 0.03))
		"titulo":
			c = primera[primera.size() - 1] if not primera.is_empty() else null
			if c != null:
				c.confianza = 25
	if c == null:
		return null
	m.tomar_el_mando(c.id)
	m.reto = {"id": id, "club": c.id, "anio": m.anio, "juzgado": false}
	return c

## Al cerrar la temporada del reto: ¿se cumplió? Devuelve {cumplido, titulo,
## texto} o vacío si no hay reto por juzgar.
static func juzgar(m: Mundo, puesto: int, descendio: bool, ascendio: bool) -> Dictionary:
	if m.reto.is_empty() or bool(m.reto.get("juzgado", false)):
		return {}
	var id := String(m.reto["id"])
	var r := datos(id)
	var c := m.mi_club()
	if r.is_empty() or c == null:
		return {}
	var ok := false
	match id:
		"david":
			ok = puesto > 0 and puesto <= 8
		"ascenso":
			ok = ascendio or (c.division == 2 and puesto > 0 and puesto <= 2)
		"deuda":
			ok = c.saldo >= 0
		"cantera":
			var n := 0
			if m.cantera != null:
				for j: Jugador in c.plantilla:
					if m.cantera.es_canterano(j):
						n += 1
			ok = n >= 6 and not descendio
		"titulo":
			ok = puesto == 1
	m.reto["juzgado"] = true
	m.reto["cumplido"] = ok
	if ok and m.roles != null:
		m.roles.sumar_trofeo("Reto: %s" % String(r[2]))
		m.roles.sumar_prestigio(6)
	return {"cumplido": ok, "titulo": ("%s Reto cumplido: %s" % [String(r[1]), String(r[2])]) if ok else ("❌ Reto fallido: %s" % String(r[2])),
		"texto": ("Meta: %s. ¡Lo lograste! Queda en tu vitrina." % String(r[4]).to_lower()) if ok else ("Meta: %s. No alcanzó. La carrera sigue igual." % String(r[4]).to_lower())}
