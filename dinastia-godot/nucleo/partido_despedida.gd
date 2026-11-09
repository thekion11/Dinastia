class_name PartidoDespedida
extends RefCounted
## EL PARTIDO DE DESPEDIDA (9-11, idea del PES 2020 que le gusta al dueño): cuando una leyenda de TU club cuelga las botas, el club le
## hace un homenaje con un amistoso. Entran lo que paga la gente que llena el estadio, sube el ánimo de la afición y la prensa lo cuenta.
## Es un amistoso simulado (no se juega en directo) y no toca la liga. Se llama desde el cierre de temporada (`mundo_p7`).
const EDAD_MINIMA := 34
const OVR_LEYENDA := 74
const TEMPORADAS_LEYENDA := 6
## Cuánto más paga la gente un día así respecto de una jornada normal.
const FACTOR_ENTRADAS := 1.6

## ¿Merece homenaje? Edad, y (capitán, o muchas temporadas, o un nivel alto).
static func merece(j: Jugador, club: Club) -> bool:
	if j == null or club == null or j.edad < EDAD_MINIMA:
		return false
	return j.capitan or j.historial.size() >= TEMPORADAS_LEYENDA or j.ovr >= OVR_LEYENDA

## Celebra el homenaje. Devuelve {} si no corresponde, o {rival, gf, gc, marca_el_homenajeado, ingreso}.
static func celebrar(m: Mundo, j: Jugador, club: Club) -> Dictionary:
	if m == null or not merece(j, club) or club.id != m.mi_club_id:
		return {}
	var liga := m.liga_de(club)
	var rival: Club = null
	if liga != null:
		var otros: Array = liga.clubes.filter(func(c: Club) -> bool: return c != club)
		if not otros.is_empty():
			rival = otros[Azar.ent(0, otros.size() - 1)]
	var marca := Azar.suerte(0.55)   ## el homenajeado suele marcar: es la noche de él
	var gf := Azar.ent(1, 4) if marca else Azar.ent(0, 3)
	var gc := Azar.ent(0, 2)
	var finanzas := Finanzas.new(club)
	var ingreso := int(round(float(finanzas.asistencia(true)) * club.precio_entrada * FACTOR_ENTRADAS))
	club.saldo += ingreso
	if m.prensa != null:
		m.prensa.animo = clampi(m.prensa.animo + 4, 0, 100)
		var rival_txt := rival.nombre if rival != null else "un invitado de lujo"
		m.prensa.noticia.emit("Partido de despedida: %s" % j.nombre,
			"El estadio se llena para decir adiós a %s tras %d años. Amistoso ante %s: %d-%d%s. La taquilla deja %d." % [
				j.nombre, j.edad, rival_txt, gf, gc,
				", con gol del homenajeado" if marca else "", ingreso])
	return {"rival": rival, "gf": gf, "gc": gc, "marca_el_homenajeado": marca, "ingreso": ingreso}
