class_name MotorCambioPortero
extends RefCounted
## EL CAMBIO DE PORTERO (26-10-2026, prefijo cpor). Hasta esta fecha el cambio
## del motor era solo de jugador de campo: el que esperaba en la banda perdía
## su «por» y el portero de la Carrera nunca entraba ni salía. Ahora:
##   · un portero solo cambia por el portero (el que está bajo palos);
##   · un jugador de campo nunca deja fuera al portero;
##   · si expulsan al portero y en la banda espera otro, entra él bajo palos y
##     sale el jugador de campo más cansado (el equipo sigue con uno menos).
## Vive aparte para no inflar las capas del motor (todas rozan las 450 líneas).

## Quién deja su sitio a `entra`.
static func quien_sale(m: MotorJugable, entra: Dictionary) -> Dictionary:
	var local := bool(entra["es_local"])
	if bool(entra.get("por", false)):
		for q: Dictionary in m.jugadores:
			if bool(q["por"]) and bool(q["es_local"]) == local:
				return q
	## Jugador de campo (o portero sin nadie bajo palos): el de su línea más cansado.
	var grupo := String((entra.get("jugador", {}) as Dictionary).get("pos", "MED"))
	var peor: Dictionary = {}
	for q: Dictionary in m.jugadores:
		if bool(q["es_local"]) != local or bool(q["por"]):
			continue
		var g := String((q.get("jugador", {}) as Dictionary).get("pos", ""))
		var nota := m.forma_fisica(q) + (0.0 if g == grupo else 0.5)
		if peor.is_empty() or nota < float(peor["_nota_cambio"]):
			q["_nota_cambio"] = nota
			peor = q
	return peor

## Entras desde el banco en tu minuto. Si eres portero, es que el titular se
## lesionó (en el fútbol el portero suplente no entra por táctica).
static func entrar_usuario(m: MotorJugable) -> void:
	var sale := quien_sale(m, m.extra)
	if bool(m.extra.get("por", false)) and bool(sale.get("por", false)):
		var nom := String((sale.get("jugador", {}) as Dictionary).get("nombre", ""))
		m.aviso.emit("🚑 Se lesiona el portero %s" % nom)
	m._cambiar(sale, m.extra, true)

## Tras la roja a `p`: si era el portero y en la banda espera un portero de su
## equipo, entra ya (por el de campo más cansado) y toma su sitio bajo palos.
static func tras_expulsion(m: MotorJugable, p: Dictionary) -> void:
	var e := m.extra
	if not bool(p["por"]) or e.is_empty() or m._cambio_hecho or not bool(e.get("por", false)) \
			or bool(e["es_local"]) != bool(p["es_local"]):
		return
	var sale := quien_sale(m, e)
	if sale.is_empty():
		return
	m._cambiar(sale, e, m.entra_usuario_min >= 0)
	e["slot_code"] = p["slot_code"]
	e["base_pos"] = p["base_pos"]
	m.aviso.emit("🧤 Roja al portero: entra %s bajo palos" % String((e.get("jugador", {}) as Dictionary).get("nombre", "")))

## La probabilidad de que el DT cambie a su portero titular: solo si lo están
## goleando (con una noche normal no se le toca).
static func prob_dt_portero(nota: float, extra_prueba: float) -> float:
	return maxf(0.0, 5.2 - nota) * 0.35 + extra_prueba
