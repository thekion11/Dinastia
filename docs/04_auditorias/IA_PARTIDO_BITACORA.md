# Bitácora viva de la IA del partido (rama `ccr-454350d9-9chain`, PR #128)

Método (orden de la sesión líder, 3-11): 1) medir (`pruebas/zz_medir_partido.tscn`, IA contra IA, semillas fijas), 2) investigar y anotar la fuente, 3) un cambio pequeño tras una bandera `SIN_…=1`,
4) volver a medir y quedarse solo con lo que mejora. Con todas las banderas apagadas (y `PMOT_ANT=0`) la huella del motor es **3180886866**, la de siempre; se comprueba antes de cada subida.
Medida de referencia («antes»): 32 partidos (semillas 1-32), todo apagado = **74 goles (2,31 por partido)**, 330 tiros (10,3), 1873 pases buenos (58,5), 1545 duelos, 137 faltas, 24 fueras de juego.

## Qué se hizo y de dónde sale cada idea
| Pieza | Módulo | Idea / fuente | Bandera |
|---|---|---|---|
| F1 colocación sin balón con memoria | `motor_colocacion.gd` | League-Soccer `GetAdaptedFormationPosition` (Apache 2.0, escrita aparte); SBSP de FC Portugal (Reis, Lau, Oliveira 2001: posición base de la formación ajustada por balón y situación) | `SIN_COLOCACION` |
| F2 roles dinámicos | `motor_roles.gd` | League-Soccer `CalculateDynamicRoles`; algoritmo húngaro | `SIN_ROLES_DIN` |
| F3 apoyo por campo de fuerzas | `motor_apoyo.gd` | League-Soccer `GetSupportPosition_ForceField` | `SIN_APOYO` |
| F4 marcaje a los 3 más peligrosos | `motor_marcaje.gd` | League-Soccer `CalculateManMarking` | `SIN_MARCAJE` |
| F5 carreras al espacio | `motor_carreras.gd` | League-Soccer `SelectAttackingRunPlayer` | `SIN_CARRERAS` |
| F6 tiro por línea limpia | `motor_tiro_limpio.gd` | League-Soccer `GetOnTheBallCommands` | `SIN_TIRO_LIMPIO` |
| F7 portero se desliza | `motor_parada.gd` (`destino`) | League-Soccer `goalie_default.cpp` | `SIN_ANTICIPA` |
| F8 imagen mental / dificultad | `motor_mente.gd` | League-Soccer `mentalimage.cpp` | `SIN_MENTE` |
| Ancla a la posición base | `motor_ancla.gd` | vídeo del dueño («enjambre»); regla de líneas del motor | `SIN_ANCLA` |
| Mapa de regiones numeradas y ocupación | `motor_regiones.gd` | Buckland, *Simple Soccer* (regiones numeradas, región de casa); mapas de influencia (Unity Game AI Cookbook) | `SIN_REGIONES` |
| Adaptación al rival, habilidades, formación, entorno | `motor_adaptacion.gd` | pedido del dueño; SBSP (tipo de jugador) | `SIN_ADAPTA` |
| Intercepción del que presiona | `motor_jugable_p8_p1.gd` (`ANTICIPA`) | sonda `PMOT_ANT` ya existente, encendida | `PMOT_ANT=0` |
| Física del balón (modo `disparar`) | `balon_3d.gd` | arrastre cuadrático ≈0,0122·v² (Carré et al. 2005; Pszota 2020); notas públicas de PES 6 como inspiración | (constantes) |

Pendiente de estudiar (fuentes ya localizadas): triangulación de Delaunay para la formación como tabla de coordenadas por posición del balón (Gliders2d, arXiv 1812.10202; ThunderLeague 2021 reporta −22 % de goles encajados frente a Agent2D).

## Ciclos de medida
1. **Primera pasada F1-F8** (16 partidos, semillas 1-16): goles 40 → 42, tiros 177 → 164, pases buenos 954 → 930, fueras de juego 12 → 3.
2. **Vídeo del dueño**: enjambre, defensas que abandonan la zona. Causa propia: F4 puntuaba como peligrosos a rivales pegados al balón y F1 sobreactuaba el seguimiento. Se añadieron ancla, regiones, adaptación; se devolvieron los pesos de F1; se encendió la intercepción.
   Resultado en 32 partidos: **101 goles (3,16 por partido)**, 373 tiros, 1690 pases buenos, 1711 duelos → demasiados goles.
3. **Ablaciones** (semillas 17-32; antes 34 goles, con todo 56): sin F6 56, sin intercepción 65 (ayuda a defender), **sin F4 43**, sin bloque defensivo 30, sin bloque ofensivo 28.
   Causa principal: los marcadores F4 rompían la línea defensiva común (regla M-123). Se corrigió: marcaje que respeta la línea (38 goles).
4. **Fallos encontrados en revisión de código**: (a) F1 usaba un balón con retardo de hasta 3,8 s justo cuando el rival atacaba → ahora 0,5 s y el sesgo de posesión cae en 0,8 s; (b) F7 solo actuaba un fotograma → ahora se desliza mientras la parada está pendiente;
   (c) los pesos de F1 con la bandera apagada no eran exactos (los `Vector3` de Godot son de 32 bits): se usan arreglos de 64 bits.
5. **Ruido**: con 16 partidos, ±6 goles; las ablaciones de una sola pieza no son concluyentes (sin F7 dio 33 contra 44 con él, con el F7 defectuoso). Para decidir se necesitan ≥32 partidos por lado.

## Cifras reales de fútbol que se persiguen (orden de la sesión líder)
≈2,5-2,8 goles, ≈25 tiros, ≈80-85 % de pases buenos por partido. Estado: tiros ≈10-12 por partido y pases buenos ≈53-59 (conteo, no porcentaje): **faltan por debajo**; `zz_medir_partido` no da el porcentaje de pases, hay que añadirlo.

## Siguiente
- Medición final de 32 partidos con todo lo anterior (en curso).
- Añadir a `zz_medir_partido` la posesión y el % de pases buenos.
- Casos concretos en `pruebas/arena/arena.tscn`: amontonamientos, defensas que no cierran, porteros que no salen.
- Tabla de coordenadas por posición del balón (Delaunay/bilineal) para la formación.
