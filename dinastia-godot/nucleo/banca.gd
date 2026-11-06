class_name Banca
extends RefCounted
## La banca de un club (sacada de `ui/estadio.gd` el 7-11, meta de RAM): `PrecalentarCaras` la llamaba en el MENÚ con `load("res://ui/estadio.gd")` y eso compilaba
## entero el estadio (+128 MB de RAM estática) solo para ordenar una lista. Aquí vive la lista, en un script mínimo; `VistaEstadio.disponibles_fuera_del_once` la sigue ofreciendo.

## Mejores disponibles (sin lesión/sanción, no en el once) por media, para que la banca se vea como un banco de verdad y no como un sorteo cualquiera.
static func disponibles_fuera_del_once(c: Club, once_c: Array) -> Array:
	var fuera: Array = []
	for j in c.plantilla:
		if once_c.has(j):
			continue
		if j.lesion > 0 or j.suspension > 0:
			continue
		fuera.append(j)
	fuera.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	return fuera
