class_name BanquilloTour
extends RefCounted
## LOS SUPLENTES EN EL BANQUILLO FUERA DEL PARTIDO (calidad visual P3, 27-10-2026). En el estadio de la ciudad (la visita) los
## banquillos estaban vacíos: los suplentes solo se montaban en el visor del partido. Ahora el banquillo local lleva a los cinco
## mejores jugadores sin lesión ni sanción de la plantilla, SENTADOS con su equipación y la pose «sentado» (`PlayerSpawner`
## .spawn_sentados, el mismo banco que el partido). Si el club no trae plantilla suficiente no se monta nada.

const CUANTOS := 5

## Sienta a los suplentes del club local en `estadio` (el nodo del recinto). Devuelve los cuerpos creados.
static func montar(estadio: Node3D, club: Club) -> Array:
	if estadio == null or club == null or club.plantilla.size() < 12:
		return []
	var titulares: Array = []
	var ordenados: Array = club.plantilla.duplicate()
	ordenados.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	for j: Jugador in ordenados.slice(0, 11):
		titulares.append(j)
	var disponibles: Array = VistaEstadio.disponibles_fuera_del_once(club, titulares)
	if disponibles.is_empty():
		return []
	var sp := PlayerSpawner.new()
	return sp.spawn_sentados(estadio, disponibles.slice(0, CUANTOS), true, Puente3D.kit(club), Puente3D.kit_portero(club))
