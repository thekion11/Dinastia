class_name PartidoDespedida
extends RefCounted
## EL PARTIDO DE DESPEDIDA (9-11; idea del PES 2020; ajustado por el dueño): al FINAL de la temporada, tu equipo juega contra el equipo de los
## jugadores que SE RETIRAN esa temporada (los de todo el mundo, las «Leyendas»). Se decide ANTES del cierre quién se retira (`preparar`), se juega
## (en directo o simulado) y el cierre de temporada respeta esa decisión (`se_retira`). Es un partido de gala: no cuenta para la liga, deja taquilla,
## sube el ánimo de la afición y NO deja consecuencias en tus jugadores (lesiones, cansancio, tarjetas y estadísticas se restauran).
const EDAD_RETIRO_SEGURO := 38
const EDAD_RETIRO_POSIBLE := 35
const PROB_RETIRO := 0.4
const MINIMO_JUGADORES := 11
const MAXIMO_JUGADORES := 18
## Cuánto más paga la gente un día así respecto de una jornada normal.
const FACTOR_ENTRADAS := 1.6
## Para el homenaje propio y la camiseta retirada de TU club.
const EDAD_MINIMA_HOMENAJE := 34
const OVR_LEYENDA := 74
const TEMPORADAS_LEYENDA := 6

## Quién se retira este cierre: id → bool, GUARDADO en la partida (`Prensa.retiros_previstos`): lo decidido sobrevive a guardar y cargar.
## Vacío = reglas de siempre (sorteo en el propio cierre).
static func _previstos(m: Mundo) -> Dictionary:
	return m.prensa.retiros_previstos if m != null and m.prensa != null else {}

## La regla de retiro del cierre de temporada (`mundo_p7`): lo decidido antes del partido, o la de siempre. `j.edad` es ya la del año que empieza.
static func se_retira(m: Mundo, j: Jugador) -> bool:
	var pr := _previstos(m)
	if pr.has(j.id):
		return bool(pr[j.id])
	return j.edad >= EDAD_RETIRO_SEGURO or (j.edad >= EDAD_RETIRO_POSIBLE and Azar.suerte(PROB_RETIRO))

static func limpiar(m: Mundo) -> void:
	if m != null and m.prensa != null:
		m.prensa.retiros_previstos = {}

## ¿Es un dorsal retirado en el club de la persona? (las camisetas retiradas no se reparten)
static func dorsal_retirado(m: Mundo, c: Club, n: int) -> bool:
	if m == null or m.prensa == null or c == null or c.id != m.mi_club_id:
		return false
	for e: Dictionary in m.prensa.dorsales_retirados:
		if int(e.get("dorsal", -1)) == n:
			return true
	return false

## ¿Merece homenaje propio? Edad, y (capitán, o muchas temporadas, o un nivel alto).
static func merece(j: Jugador) -> bool:
	return j != null and j.edad >= EDAD_MINIMA_HOMENAJE and (j.capitan or j.historial.size() >= TEMPORADAS_LEYENDA or j.ovr >= OVR_LEYENDA)

## Decide quién se retira (con la edad del año que viene, como en el cierre) y arma el equipo de LEYENDAS con los mejores de ellos.
## Devuelve null si no hay club humano o no alcanzan once con portero.
static func preparar(m: Mundo) -> Club:
	var mio := m.mi_club() if m != null else null
	if mio == null or m.prensa == null:
		return null
	var retirados: Array[Jugador] = []
	var pr := _previstos(m)
	if pr.is_empty():   ## primera vez este cierre: se decide (y queda guardado)
		for c: Club in m.clubes.values():
			for j: Jugador in c.plantilla:
				var sera := j.edad + 1
				if sera < EDAD_RETIRO_POSIBLE or (c == mio and m.medico != null and m.medico.retiro_forzado(j)):
					continue
				pr[j.id] = sera >= EDAD_RETIRO_SEGURO or Azar.suerte(PROB_RETIRO)
		m.prensa.retiros_previstos = pr
	for c2: Club in m.clubes.values():   ## lo ya decidido (también tras cargar una partida guardada)
		for j2: Jugador in c2.plantilla:
			if bool(pr.get(j2.id, false)):
				retirados.append(j2)
	return equipo_de(m, retirados)

## Los 5 escudos de las Leyendas (orden del dueño, 9-11): cada temporada toca uno distinto (`anio % 5`), siempre dorados sobre un fondo oscuro que cambia.
const ESCUDOS_LEYENDAS := [
	{"forma": "corona", "patron": "estrella", "c1": "#c9a227", "c2": "#0c1510"},
	{"forma": "hex", "patron": "estrella8", "c1": "#e0b84a", "c2": "#14301f"},
	{"forma": "escudo", "patron": "cruz", "c1": "#c9a227", "c2": "#3a1018"},
	{"forma": "ovalo", "patron": "estrella6", "c1": "#d9b13a", "c2": "#10213f"},
	{"forma": "ojiva", "patron": "chevron", "c1": "#c9a227", "c2": "#1a1a1a"},
]

## El diseño de escudo que le toca a las Leyendas de esa temporada.
static func escudo_del_anio(anio: int) -> Dictionary:
	return ESCUDOS_LEYENDAS[posmod(anio, ESCUDOS_LEYENDAS.size())]

## El club «Leyendas» con los mejores retirados (portero incluido). null si no hay con qué formar un once.
## El dorsal que llevaban antes de ponerles el de las Leyendas (para la camiseta retirada).
static var dorsales_originales: Dictionary = {}

const NUCLEO := [["DEF", 4], ["MED", 3], ["DEL", 2]]   ## lo mínimo por línea que se asegura a las Leyendas, si hay retirados de ese puesto
static func equipo_de(m: Mundo, retirados: Array[Jugador]) -> Club:
	var porteros := retirados.filter(func(j: Jugador) -> bool: return j.pos == "POR")
	if retirados.size() < MINIMO_JUGADORES or porteros.is_empty():
		return null
	var orden: Array[Jugador] = retirados.duplicate()
	orden.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	var elegidos: Array[Jugador] = []
	porteros.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	elegidos.append(porteros[0])
	## (12-11) Primero un once que pueda jugar: los mejores 4 defensas, 3 medios y 2 delanteros que haya (antes entraban los 17 mejores por
	## nota sin mirar el puesto y las Leyendas salían con 5 delanteros y UN defensa). Después, el resto por nota hasta completar.
	for cupo: Array in NUCLEO:
		var de_linea := 0
		for j: Jugador in orden:
			if de_linea < int(cupo[1]) and j.pos == String(cupo[0]) and not elegidos.has(j):
				elegidos.append(j)
				de_linea += 1
	for j: Jugador in orden:
		if elegidos.size() >= MAXIMO_JUGADORES:
			break
		if not elegidos.has(j):
			elegidos.append(j)
	var mio := m.mi_club()
	var club := Club.new("leyendas_%d" % m.anio, "%s %d" % [Idiomas.t("Leyendas"), m.anio])
	club.pais = mio.pais
	club.rep = mio.rep
	club.color1 = "#c9a227"
	club.color2 = "#0c1510"
	var esc := escudo_del_anio(m.anio)
	club.esc_forma = String(esc["forma"])
	club.esc_patron = String(esc["patron"])
	club.esc_color1 = String(esc["c1"])
	club.esc_color2 = String(esc["c2"])
	club.plantilla.clear()
	var n := 1
	dorsales_originales.clear()
	for j: Jugador in elegidos:
		dorsales_originales[j.id] = j.dorsal
		j.dorsal = n
		j.lesion = 0
		j.suspension = 0
		j.fisico = 100
		n += 1
		club.plantilla.append(j)
	return club

## Cuántos hay por línea en una lista de jugadores: {POR, DEF, MED, DEL}.
static func por_linea(lista: Array) -> Dictionary:
	var n := {"POR": 0, "DEF": 0, "MED": 0, "DEL": 0}
	for j: Jugador in lista:
		n[j.pos] = int(n.get(j.pos, 0)) + 1
	return n

## La foto del estado de tus jugadores antes del partido de gala, para devolverlo tal cual después.
static func foto(club: Club) -> Dictionary:
	var f := {}
	for j: Jugador in club.plantilla:
		f[j.id] = {"lesion": j.lesion, "suspension": j.suspension, "fisico": j.fisico, "amarillas": j.amarillas, "goles": j.goles,
			"asistencias": j.asistencias, "partidos": j.partidos, "forma": j.forma, "moral": j.moral, "notas": j.notas.duplicate()}
	return f

static func restaurar(club: Club, f: Dictionary) -> void:
	for j: Jugador in club.plantilla:
		if not f.has(j.id):
			continue
		var d: Dictionary = f[j.id]
		j.lesion = int(d["lesion"]); j.suspension = int(d["suspension"]); j.fisico = int(d["fisico"]); j.amarillas = int(d["amarillas"])
		j.goles = int(d["goles"]); j.asistencias = int(d["asistencias"]); j.partidos = int(d["partidos"]); j.forma = int(d["forma"]); j.moral = int(d["moral"])
		j.notas.clear()
		for x in d["notas"]:
			j.notas.append(float(x))

## Lo que deja la noche: taquilla, ánimo de la afición, la noticia y el HOMENAJE a los de tu club que se retiran (camiseta retirada). `p` es el partido ya
## jugado (tu club local). Devuelve {ingreso, gf, gc, homenajeados: [{jugador, dorsal}]}.
static func cerrar(m: Mundo, p: Partido, leyendas: Club, f: Dictionary) -> Dictionary:
	var mio := m.mi_club()
	restaurar(mio, f)
	var gf := p.goles_local
	var gc := p.goles_visita
	var ingreso := int(round(float(Finanzas.new(mio).asistencia(true)) * mio.precio_entrada * FACTOR_ENTRADAS))
	mio.saldo += ingreso
	var homenajeados: Array = []
	for j: Jugador in leyendas.plantilla:
		if j.club_id == mio.id and merece(j):
			var dorsal := int(dorsales_originales.get(j.id, 0))
			homenajeados.append({"jugador": j, "dorsal": dorsal})
			if dorsal > 1 and not dorsal_retirado(m, mio, dorsal):   ## el 1 (portero) se reparte siempre al mejor arquero: no se retira
				m.prensa.dorsales_retirados.append({"dorsal": dorsal, "nombre": j.nombre, "anio": m.anio})
	m.prensa.despedida_anio = m.anio
	m.prensa.animo = clampi(m.prensa.animo + (6 if gf >= gc else 4) + (2 if not homenajeados.is_empty() else 0), 0, 100)
	m.prensa.noticia.emit("%s %d" % [Idiomas.t("Partido de despedida de las leyendas"), m.anio],
		"%s %d-%d %s. %s %d." % [mio.nombre, gf, gc, leyendas.nombre, Idiomas.t("La taquilla deja"), ingreso])
	return {"ingreso": ingreso, "gf": gf, "gc": gc, "homenajeados": homenajeados}
