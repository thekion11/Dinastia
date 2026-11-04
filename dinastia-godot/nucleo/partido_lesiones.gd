class_name PartidoLesiones
extends RefCounted
## EL LESIONADO SALE DEL CAMPO (caza de fallos, 4-11-2026, orden de la líder: reglas al límite). Antes un lesionado seguía jugando como si nada (el aviso «Te toca mover el banquillo»
## era solo un texto): con los cambios agotados, o sin suplente de su puesto, la lesión no costaba nada. Ahora:
##   · el rival (la CPU) cambia al lesionado en el acto si le quedan cambios y suplente; el DT del jugador tiene `ESPERA_DT` minutos para mover el banquillo y, si no lo hace, lo hace el ayudante;
##   · sin cambios (o sin nadie en el banco que pueda entrar) el lesionado SALE IGUAL y el equipo sigue con uno menos (`baja_sin_cambio`); si era el portero, un jugador de campo se pone bajo
##     los palos (la fuerza supone un «portero» de 35: `Partido.fuerza`); con menos de siete se suspende (`_revisar_siete`).
const ESPERA_DT := 3   ## minutos que el DT del jugador tiene para mover el banquillo antes de que lo haga su ayudante

static func nueva(p: Partido, j: Jugador) -> void:
	var d: Dictionary = p.get_meta("lesionados", {})
	d[j.id] = p.minuto
	p.set_meta("lesionados", d)

## Una vez por minuto (`Partido.simular_minuto`).
static func atender(p: Partido) -> void:
	var d: Dictionary = p.get_meta("lesionados", {})
	if d.is_empty():
		return
	for id: String in d.keys():
		var j := p._por_id(id)
		var en_local := j != null and p.once_local.has(j)
		if j == null or (not en_local and not p.once_visita.has(j)):
			d.erase(id)   ## ya salió (cambio a mano, roja…)
			continue
		var club: Club = p.local if en_local else p.visita
		var mio := club.id == Partido.ctx_club_id
		var hechos := p.cambios_local if en_local else p.cambios_visita
		var suplente: Jugador = null
		if hechos < Partido.MAX_CAMBIOS + p.cambios_extra:
			suplente = _suplente(p, club, j)
		if suplente != null:
			if not mio or p.minuto - int(d[id]) >= ESPERA_DT:
				p.cambiar(j, suplente)
				d.erase(id)
		else:
			(p.once_local if en_local else p.once_visita).erase(j)
			p.invalidar_fuerza()
			p.baja_sin_cambio.emit(j, p.minuto)
			d.erase(id)
			p._revisar_siete()
			if p.terminado_ya:
				return

## El mejor suplente que puede entrar por `sale`: de su puesto (el portero solo por otro portero), disponible y que no haya jugado ya.
static func _suplente(p: Partido, club: Club, sale: Jugador) -> Jugador:
	var mejor: Jugador = null
	for c: Jugador in club.plantilla:
		if c == sale or p.once_local.has(c) or p.once_visita.has(c) or not c.disponible() or p.ya_salio(c) or c.es_portero() != sale.es_portero():
			continue
		if mejor == null or (c.pos == sale.pos and mejor.pos != sale.pos) or (c.pos == mejor.pos and c.ovr > mejor.ovr) or (mejor.pos != sale.pos and c.pos != sale.pos and c.ovr > mejor.ovr):
			mejor = c
	return mejor
