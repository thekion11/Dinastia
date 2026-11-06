# Rendimiento: tabla ANTES / DESPUÉS (6-11-2026, pista A)

Método (orden 19 del dueño): SOLO recuentos, nunca tiempo de fotograma en `--headless`. `herramientas/hw_modesto.sh res://pruebas/medir_partido.tscn -- <nivel>` (cámara de TV, partido corriendo, llvmpipe, 1366x768, 2 núcleos). Una sola máquina y una sola semilla; los números se comparan entre sí.

## Partido 3D (llamadas de dibujo · triángulos · objetos)
| Nivel | ANTES | DESPUÉS | Qué cambió |
|---|---|---|---|
| ULTRA BAJA (antes MÍNIMO) | 338 · 387 062 · 389 | **236 · 361 439 · 287** (137 MB) (−30 % de llamadas, −30 % de objetos) | oclusión corregida, sin gente de fuera, grada en 3 trozos |
| MEDIA (antes MEDIO) | 709 · 845 501 · 760 (208 MB) | **423 · 758 061 · 474** (208 MB) | oclusión corregida (−40 % de llamadas) |
| ALTA (antes ALTO) | 925 · 1 787 095 · 976 (215 MB) | 925 · 1 787 855 · 976 (215 MB) | sin cambios de código en ALTA (medido igual) |

## Cambios (todos SIN pérdida visual salvo el 3, que es visible y solo en ULTRA BAJA y BAJA)
1. **Oclusión del entorno del estadio** (`visor/entorno_oclusion.gd`, ULTRA BAJA…MEDIA, estadios cerrados): se montaba con una lista fija de nodos y el agrupado (`Optimizar.agrupar`) crea sus 95 MultiMesh DESPUÉS, que quedaban siempre visibles aunque las tribunas los taparan. Ahora recorre los hijos actuales. Medido: ULTRA BAJA 338 → 279 llamadas (−17 %), 389 → 331 objetos; MEDIA 709 → 423 (−40 %), 760 → 474 objetos. Misma imagen (solo se oculta lo que las tribunas ya tapaban; el horizonte sigue visible).
2. **Grada en 3 trozos en vez de 8 en ULTRA BAJA y BAJA** (`OptimizarGrada.tramos_de`): −13 llamadas, +28 k triángulos (medido: 338 → 325 con 3 trozos). Sin cambio visual.
3. **VISIBLE, solo ULTRA BAJA y BAJA: sin la gente de fuera del campo** (`visor/gente_fuera.gd`): se esconden suplentes sentados, cuerpo técnico, camarógrafos, recogepelotas y mascota (37 esqueletos). Medido 279 → 246 llamadas, 378 k → 330 k triángulos, 331 → 297 objetos. Los cambios no se ven afectados (el que entra se crea nuevo). MEDIA y más: nada cambia.
4. **Calidad en 7 niveles** (`visor/calidad.gd`): BAJA y MEDIA BAJA con escala 3D propia (entre la de ULTRA BAJA y la de MEDIA) y sombra del sol solo desde MEDIA BAJA; MEDIA ALTA con el alcance de sombra de ALTA. Defecto en TODOS los sistemas: ULTRA BAJA; migración `version_calidad`; prueba `ren_calidad_7_niveles`.

## Probado y descartado (con cifras)
- Recortar el horizonte (64 → 22 edificios): solo −7 llamadas, visible: NO aplicado.
- Ocultar ojos y cejas: −3 llamadas: no vale.
- Trozos de grada 1: −17 llamadas pero +176 k triángulos: no.
- Ocultar butacas + hinchas: −26 llamadas, −124 k triángulos, gradas vacías: NO aplicado.

## Meta ULTRA BAJA < 130 llamadas: NO alcanzada
Partido en ULTRA BAJA: 338 → 236 llamadas (la meta es < 130 de media entre ciudad y partido; la ciudad no está medida). Lo que queda (jugadores y árbitros ~100 llamadas, ~60 MultiMesh de butacas y ~60 de hinchas por tribuna, estructura del estadio ~200 mallas) exige fusionar mallas de jugador o impostores de grada, con riesgo visual: pendiente, no tocado. Ciudad sin medir (la primera medición no devolvió cifras).
