class_name PremioMensual
extends RefCounted
## EL JUGADOR DEL MES (10-11; idea de los premios mensuales del PES). Cada 4 semanas de liga se elige al mejor de TU liga por la media de sus últimas
## cuatro notas (con al menos 3 partidos): queda en su ficha (`Jugador.premios`), sale en la prensa y, si es tuyo, sube su moral. No cambia nada más.
const CADA := 4
const MINIMO_NOTAS := 3

## El ganador del mes en la liga de `m.mi_club()` (o null si nadie llega al mínimo).
static func elegir(m: Mundo) -> Jugador:
	var mio := m.mi_club()
	var liga := m.liga_de(mio) if mio != null else null
	if liga == null:
		return null
	var mejor: Jugador = null
	var mejor_media := -1.0
	for c: Club in liga.clubes:
		for j: Jugador in c.plantilla:
			if j.notas.size() < MINIMO_NOTAS:
				continue
			var ult := j.notas.slice(-4)
			var media := 0.0
			for n: float in ult:
				media += n
			media /= float(ult.size())
			if media > mejor_media or (is_equal_approx(media, mejor_media) and mejor != null and j.ovr > mejor.ovr):
				mejor_media = media
				mejor = j
	return mejor

## Se llama cada semana (tras jugar): solo actúa en las semanas múltiplo de `CADA`. Devuelve el premiado (o null).
static func revisar(m: Mundo) -> Jugador:
	if m.semana <= 0 or m.semana % CADA != 0 or not m.temporada_en_curso():
		return null
	var j := elegir(m)
	if j == null:
		return null
	j.premios.append({"anio": m.anio, "premio": "Jugador del mes"})
	var mio := m.mi_club()
	var es_mio := mio != null and j.club_id == mio.id
	if es_mio:
		j.cambiar_moral(5, "Jugador del mes")
	if m.prensa != null:
		var club: Club = m.clubes.get(j.club_id)
		m.prensa.noticia.emit("🏅 Jugador del mes: %s" % Nombres.visible(j.nombre),
			"%s (%s) se lleva el premio al mejor del mes en la liga.%s" % [Nombres.visible(j.nombre), club.nombre if club != null else "—",
			" ¡Es de tu club!" if es_mio else ""])
	return j
