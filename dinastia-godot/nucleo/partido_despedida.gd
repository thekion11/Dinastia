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

## Quién se retira este cierre: id → bool. Vacío = reglas de siempre (sorteo en el propio cierre).
static var previstos: Dictionary = {}

## La regla de retiro del cierre de temporada (`mundo_p7`): lo decidido en `preparar`, o la de siempre. `j.edad` es ya la del año que empieza.
static func se_retira(j: Jugador) -> bool:
	if previstos.has(j.id):
		return bool(previstos[j.id])
	return j.edad >= EDAD_RETIRO_SEGURO or (j.edad >= EDAD_RETIRO_POSIBLE and Azar.suerte(PROB_RETIRO))

static func limpiar() -> void:
	previstos.clear()

## Decide quién se retira (con la edad del año que viene, como en el cierre) y arma el equipo de LEYENDAS con los mejores de ellos.
## Devuelve null si no hay club humano o no alcanzan once con portero.
static func preparar(m: Mundo) -> Club:
	limpiar()
	var mio := m.mi_club() if m != null else null
	if mio == null:
		return null
	var retirados: Array[Jugador] = []
	for c: Club in m.clubes.values():
		for j: Jugador in c.plantilla:
			var sera := j.edad + 1
			if sera < EDAD_RETIRO_POSIBLE or (c == mio and m.medico != null and m.medico.retiro_forzado(j)):
				continue
			var retira := sera >= EDAD_RETIRO_SEGURO or Azar.suerte(PROB_RETIRO)
			previstos[j.id] = retira
			if retira:
				retirados.append(j)
	return equipo_de(m, retirados)

## El club «Leyendas» con los mejores retirados (portero incluido). null si no hay con qué formar un once.
static func equipo_de(m: Mundo, retirados: Array[Jugador]) -> Club:
	var porteros := retirados.filter(func(j: Jugador) -> bool: return j.pos == "POR")
	if retirados.size() < MINIMO_JUGADORES or porteros.is_empty():
		return null
	var orden: Array[Jugador] = retirados.duplicate()
	orden.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	var elegidos: Array[Jugador] = []
	porteros.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	elegidos.append(porteros[0])
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
	club.plantilla.clear()
	var n := 1
	for j: Jugador in elegidos:
		j.dorsal = n
		j.lesion = 0
		j.suspension = 0
		j.fisico = 100
		n += 1
		club.plantilla.append(j)
	return club

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

## Lo que deja la noche: taquilla, ánimo de la afición y la noticia. `p` es el partido ya jugado (tu club local). Devuelve {ingreso, gf, gc}.
static func cerrar(m: Mundo, p: Partido, leyendas: Club, f: Dictionary) -> Dictionary:
	var mio := m.mi_club()
	restaurar(mio, f)
	var gf := p.goles_local
	var gc := p.goles_visita
	var ingreso := int(round(float(Finanzas.new(mio).asistencia(true)) * mio.precio_entrada * FACTOR_ENTRADAS))
	mio.saldo += ingreso
	if m.prensa != null:
		m.prensa.animo = clampi(m.prensa.animo + (6 if gf >= gc else 4), 0, 100)
		m.prensa.noticia.emit("%s %d" % [Idiomas.t("Partido de despedida de las leyendas"), m.anio],
			"%s %d-%d %s. %s %d." % [mio.nombre, gf, gc, leyendas.nombre, Idiomas.t("La taquilla deja"), ingreso])
	limpiar_equipo(leyendas)
	return {"ingreso": ingreso, "gf": gf, "gc": gc}

## Los de las Leyendas no vuelven a jugar con ese equipo: se quitan sus referencias (el cierre los retira de verdad).
static func limpiar_equipo(leyendas: Club) -> void:
	leyendas.plantilla.clear()
