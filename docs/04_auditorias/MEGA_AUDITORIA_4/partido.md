# Mega auditoría 4 — partido

## Repaso 5 cruzado (líder, desde gestión) — partido SIMULADO
Prueba al límite: `dinastia-godot/pruebas/ideas/a4_partido_cruzado.tscn` (99 contra 20, mejor contra peor del mundo, 200 partidos de liga,
equipos de 7 y sin portero; en `especiales.sh`).

- [A4-PAR-L01] (repaso 5, gravedad: alto, cambia el juego) DISCIPLINA del simulado: (a) la tarjeta caía también en jugadores ya cambiados o
  ya expulsados (uno vio DOS rojas en el mismo partido); (b) la «segunda amarilla» se decidía con las amarillas de TODA la temporada (cualquier
  total par, con `P_ROJA_SEGUNDA`); (c) la roja no sacaba a nadie del once (se jugaba con 11). Arreglo: `Partido._amonestar` (partido.gd):
  amarillas del PARTIDO, la 2.ª es roja y saca del once (con menos de 7 se suspende, `suspendido = true`, 3-0 de mesa); el amonestado se cuida
  (evita la 2.ª el 60 %); tarjetas y lesiones solo a quien está en el campo; `P_AMARILLA` 0,040 → 0,045. Medido: 3,65 amarillas y 0,16 rojas
  por partido (real ~3,5-4 y ~0,1-0,2). `igualdad_mundo` → 2563391786. ARREGLADO.
- [A4-PAR-L02] (repaso 5, gravedad: medio, calibración) Goleadas: el mejor club (71) contra el peor (48) promedia 7,7 goles y llega a 15-0.
  Va con la deuda de recalibración del simulado (`PLAN_GENERAL.md`); la prueba vigila que no empeore (tope 20).
- Sin hallazgos: marcador = señales de gol, tiros a puerta ≥ goles, remates ≥ a puerta, cambios ≤ máximo, posesión y xG finitos en 150
  partidos absurdos; el equipo de 7 y el sin portero terminan.
