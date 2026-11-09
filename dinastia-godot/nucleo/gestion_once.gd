class_name GestionOnce
extends RefCounted
## LAS ACCIONES SOBRE EL ONCE QUE ELIGE EL ENTRENADOR (9-11; las usa la plantilla a la PES): intercambiar dos jugadores, dejar el once automático y guardar o
## restaurar una foto del once (para «Deshacer»). Solo toca `Club.once_elegido`.

## INTERCAMBIAR: dos titulares se cambian de puesto; un titular y un reserva se sustituyen. false si no se puede (alguien lesionado o sancionado, el mismo jugador,
## o los dos reservas). Si el once era automático, primero se fija tal cual está.
static func intercambiar(club: Club, a: Jugador, b: Jugador) -> bool:
	if club == null or a == null or b == null or a == b or not a.disponible() or not b.disponible():
		return false
	var ids: Array[String] = []
	if club.once_elegido.size() == 11:
		ids = club.once_elegido.duplicate()
	else:
		for j: Jugador in club.once():
			ids.append(j.id)
	var ia := ids.find(a.id)
	var ib := ids.find(b.id)
	if ia < 0 and ib < 0:
		return false
	if ia >= 0 and ib >= 0:
		ids[ia] = b.id
		ids[ib] = a.id
	elif ia >= 0:
		ids[ia] = b.id
	else:
		ids[ib] = a.id
	club.once_elegido = ids
	return not club._once_manual().is_empty()

## La foto del once elegido (vacía = era automático).
static func foto(club: Club) -> Array[String]:
	return club.once_elegido.duplicate()

static func restaurar(club: Club, f: Array[String]) -> void:
	club.once_elegido = f.duplicate()

## Deja que el once vuelva a armarse solo (el mejor para cada puesto).
static func automatico(club: Club) -> void:
	club.limpiar_once()
