# Mega auditoría 4 — gestion

Prueba al límite del área: `dinastia-godot/pruebas/ideas/a4_gestion_limite.tscn` (8 temporadas con guardado cada dos años, integridad,
caja −250 M, todos lesionados y sancionados, club con 48 jugadores y otro vacío, año 2099).

- [A4-GES-001] (repaso 3, gravedad: alto) Tras CERRAR UNA TEMPORADA (`jugar_temporada` + `nueva_temporada`), guardar y cargar NO devuelve el
  mismo mundo (temporadas 2, 4, 6 y 8). El banco `guardado` solo lo probaba dentro de la primera temporada. Reproducir: `a4_gestion_limite`.
  Estado: abierto (buscando el campo que cambia).
- Sin hallazgos: integridad del mundo en 8 temporadas (un club por jugador, club_id, libres, contratos, sueldos, edades, medias, cajas,
  planteles, ligas y divisiones); caja a −250 M seis semanas; club con todos lesionados y sancionados (saca 11); club con 48 jugadores y
  otro vacío; año 2099.
