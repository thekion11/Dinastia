# Reevaluación del informe técnico del 21-10-2026 (nota de partida: 74/100)

Informe del dueño: «Auditoría técnica estructural exhaustiva», 16 puntos. Se contrastó
cada punto con el código y se aplicó lo aceptado por el dueño (oclusión, texturas,
señales, reutilización modular; el punto 16 —la ciudad en un .pck aparte— lo rechazó).

| # | Punto del informe | Antes | Ahora | Evidencia |
|---|---|---|---|---|
| 1-3 | «Feature creep»: la ciudad come el presupuesto (RECHAZADO por el dueño el 21-10: la ciudad es parte de la idea del juego) | no aplicaba: ciudad y partido nunca conviven | igual | `Principal._ver_ciudad_propia` / `_ver_estadio`: cada visor se crea y se libera |
| 4 | Escenas aisladas | ya | ya | idem |
| 5-6 | Datos en un singleton, guardado en disco | ya (`Mundo` + JSON seguro con .bak) | ya | `nucleo/partida.gd` |
| 7 | Física por código, sin RigidBody | ya | ya | sin `RigidBody3D` en el juego |
| 8 | Oclusión en la ciudad | **no había** | **hecho**: −16 % de llamadas a pie de calle | `visor/oclusores_ciudad.gd`, `pruebas/medir_oclusion.tscn` (12.128 → 10.192) |
| 8b | Iluminación precalculada | no | no (choca con el ciclo día/noche) | — |
| 9 | Interfaz por señales | 235 señales; algún panel sondeaba | panel de objetivos por señal + respaldo 3 s | `Principal.vista_cambiada` |
| 10 | IA repartida entre fotogramas | no | no (sin medición que lo pida) | — |
| 11 | Reutilización (object pooling) | parcial (peatones, MultiMesh) | **hecho, y modular para todo**: reserva, unir/separar conjuntos, guardarlos como datos | `visor/modulos.gd`, `_probar_modulos` |
| 12 | NavMesh en la ciudad, steering en el campo | red vial propia; steering | igual | `camino_entre` |
| 13 | Texturas grandes y comprimidas | ya: las de 3D en VRAM y limitadas | revisado (ropa 4K → 1024; caras e iconos sin pérdida a propósito) | `.import` |
| 14 | Ramas | ya | ya | rama + PR a main |
| 15 | Profiling en hardware real | 🔒 dueño | 🔒 dueño (medidas por software: llamadas de dibujo) | — |
| 16 | La ciudad en un .pck aparte | — | rechazado por el dueño | — |

Además (no estaba en el informe, salió del vídeo de gameplay): ocasiones de gol según la
duración real (`MotorJugable.prisa`, ritmos 4 / 5,5 / 7,5 s por minuto: ~2,6 goles y
~15 tiros en el «normal»), sin controles táctiles en PC, el mentor ya no tapa la prensa,
haces de farola suaves, malabares con racha, manos del público, y el edificio del club
amueblado con piezas de verdad (7 objetos de decoración nuevos).

## Nota

Con el mismo criterio del informe (penaliza rendimiento y arquitectura), lo que movió
la aguja son los puntos 8, 9 y 11: **≈ 78/100 (+4)**. No sube más sin el punto 15
(perfil en hardware real, del dueño) y sin la decisión de diseño de los puntos 1-3, que
el informe castiga y que aquí es parte de la idea del juego. Es una estimación propia:
la nota «oficial» la daría quien hizo el informe al volver a pasarlo.
