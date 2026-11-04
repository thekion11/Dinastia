# Mega auditoría 4 — gestion

Prueba al límite del área: `dinastia-godot/pruebas/ideas/a4_gestion_limite.tscn` (8 temporadas con guardado cada dos años, integridad,
caja −250 M, todos lesionados y sancionados, club con 48 jugadores y otro vacío, año 2099).

- [A4-GES-001] (repaso 3, gravedad: alto) Tras CERRAR UNA TEMPORADA (`jugar_temporada` + `nueva_temporada`), guardar y cargar NO devuelve el
  mismo mundo (temporadas 2, 4, 6 y 8). El banco `guardado` solo lo probaba dentro de la primera temporada. Reproducir: `a4_gestion_limite`.
  Causa: `Citas.desde_dic` guardaba las citas por REFERENCIA y `semana()` las caducaba en el sitio, estropeando los datos cargados.
  Arreglo: copia profunda al cargar (`nucleo/citas.gd`). Estado: ARREGLADO (8 temporadas con guardado exacto; en `especiales.sh`).
- [A4-GES-002] (repaso 3, gravedad: alto, cambia el juego) Quedaban OFERTAS RECIBIDAS por jugadores que ya NO eran del club (vendidos
  o libres al cerrar la temporada): se podía aceptar y VENDER a un jugador ajeno. Arreglo: `Mercado.a_dic` no guarda esas ofertas y
  `responder_oferta` no hace nada si el jugador ya no es tuyo (`nucleo/mercado_p1.gd`). Estado: ARREGLADO.
- [A4-GES-003] (repaso 3, gravedad: medio, cambia cifras) La FICHA MENTAL (ansiedad/confianza) se creaba con `Azar` al LEERLA
  (`factor_animo` en el partido): al cargar una partida salía distinta y además consumía azar según el orden de lectura. Arreglo:
  la ficha inicial sale de un hash del id del jugador y leer no la crea (`nucleo/vestuario_p1.gd`). `igualdad_mundo` → 31094042.
  Estado: ARREGLADO.
- [A4-GES-004] (repaso 3, gravedad: bajo) El EDITOR no llegaba a la media pedida cerca del suelo de 20 (6 vueltas de `_cuadrar_media`
  no bastaban: los atributos topan en 20); fallo intermitente del banco según el azar. Arreglo: 40 vueltas (`nucleo/editor.gd`). ARREGLADO.
- Sin hallazgos: integridad del mundo en 8 temporadas (un club por jugador, club_id, libres, contratos, sueldos, edades, medias, cajas,
  planteles, ligas y divisiones); caja a −250 M seis semanas; club con todos lesionados y sancionados (saca 11); club con 48 jugadores y
  otro vacío; año 2099.
