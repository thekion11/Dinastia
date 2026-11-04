# Mega auditoría 4 — mundo_3d


## Repaso 5 (cruzado, sesión «Búsqueda de fallos», 4-11)
- [A4-M3D-001] (repaso 5 cruzado, gravedad: alto) FUGA al entrar y salir de la ciudad: cada `CityBuilder.build()` + liberar dejaba vivos +123 objetos y +5 MB de memoria estática, para siempre (en una sesión larga entrando 20 veces a la ciudad, +100 MB). Causa: `Optimizar._tris_cache` (clave = la malla) y `Optimizar._unidad` (clave = el material) eran `static var` que nunca se vaciaban y retenían las mallas/materiales de cada ciudad construida. Reproducir: `CICLOS=12 godot --headless --path . res://pruebas/ideas/a4_m3d_ciclos.tscn` (antes: objetos 7195 → 8425, memoria 806 → 857 MB). Archivo: `visor/optimizar_p1.gd` (`agrupar`). Estado: **arreglado**: se vacían al empezar cada `agrupar` (ahora +2 objetos y +0,2 MB por ciclo); la prueba nueva `a4_m3d_ciclos` (en `especiales.sh`) falla sin el arreglo y pasa con él. No cambia cómo se juega.
- Comprobado sin hallazgos: nodos (25 → 25) y huérfanos (0) estables entre ciclos; `CityBuilder.altura_en` devuelve valores finitos en posiciones extremas (±1e7, 1e-9, negativas).
- Pendiente del cruzado: estadio y transporte al límite (cargas repetidas del estadio, señales sin desconectar), `queue_free` pendientes.
