class_name CarreraCopa
extends RefCounted
## LA COPA EN LA CARRERA DE JUGADOR (26-10-2026, aprobado por el dueño). Las
## semanas de copa (una de cada cuatro, como en el modo entrenador) el partido
## de tu club es el cruce de copa, a partido único: si acaba empatado hay
## PRÓRROGA (2×15') y, si sigue igual, TANDA DE PENALES. La liga nunca tiene
## prórroga. Jugado en el césped lo resuelve `MotorJugable` (`eliminatoria`);
## simulado, `simular()` de aquí, con la misma regla. En los dos casos el
## partido vuelve a `Mundo.avanzar_semana(ya_jugado)` y la copa lo anota tal
## cual (`Copa.jugar_ronda` no lo vuelve a simular).

## El cruce de copa de tu club esta semana, o vacío.
static func partido(m: Mundo, c: Club) -> Array:
	if m == null or c == null or m.copa == null or c != m.club_de_la_copa():
		return []
	return m.partido_de_copa()

## ¿Este cruce es el de copa de esta semana?
static func es_copa(m: Mundo, par: Array) -> bool:
	if par.size() < 2 or m == null:
		return false
	var cp := m.partido_de_copa()
	return cp.size() == 2 and cp[0] == par[0] and cp[1] == par[1]

## Un partido de eliminatoria simulado entero: con empate al 90' sigue al 120'
## (`prorroga_externa`, el mismo camino que el motor real) y, si sigue el
## empate, se tiran los penales del acta (`Partido.penales()`).
static func simular(p: Partido) -> void:
	p.preparar()
	while not p.terminado_ya:
		if p.minuto == Partido.MINUTOS - 1 and p.minutos_fin == Partido.MINUTOS and p.goles_local == p.goles_visita:
			p.prorroga_externa()
		p.simular_minuto()
	p._cerrar_notas()
	p.guardar_si_es_mio()
	if p.goles_local == p.goles_visita:
		p.penales()

## El texto de la tanda para el aviso de la semana («gana 4-3 en penales»).
static func texto_penales(p: Partido, club: Club) -> String:
	if p == null or p.goles_local != p.goles_visita:
		return ""
	var pen := p.penales()
	if pen.size() < 2:
		return ""
	var mios := int(pen[0]) if p.local == club else int(pen[1])
	var suyos := int(pen[1]) if p.local == club else int(pen[0])
	return (Idiomas.t("¡Pasáis en los penales (%d-%d)!") if mios > suyos else Idiomas.t("Eliminados en los penales (%d-%d).")) % [mios, suyos]
