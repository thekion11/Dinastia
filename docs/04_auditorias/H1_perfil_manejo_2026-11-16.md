# H1 · Perfil de manejo y fútbol plausible del motor C4 (16-11-2026)

Parte de MEDIDA y CALIBRACIÓN del hito H1 «Se juega bien» del informe AAA (`INFORME_ACADEMICO_AAA/cap_09_plan.md`, criterios A1.1-A1.7).
Motor medido: C4 (`combinado_c4`, el de por defecto). Siempre con varios clubes y países (orden 34).

## Herramientas nuevas

| Qué | Dónde | Coste |
|---|---|---|
| Perfil de manejo (A1.1, A1.2) | `dinastia-godot/pruebas/_sonda/perfil_manejo.tscn` | ~35 s, 3 partidos (CHI, ESP, ITA) |
| Fútbol plausible (A1.3-A1.6) | `dinastia-godot/pruebas/_sonda/futbol_plausible.tscn` (`N`, `DESDE`, `MITAD`, `PPDA=1`, `MOTOR`) | ~75 s por partido a 1/60 s |
| Banco: pase manual de 12 m y latencia de pulsación | `pruebas/banco/partido_p6.gd` → `_probar_perfil_manejo_c4` (grupo `partido`) | ~4 s, 2 partidos (URU-GER, JPN-POR) |

El perfil abre un partido real con `VistaEstadio`, mueve el motor a mano a pasos de 1/60 s (como `VistaEstadio._paso_motor`),
mantiene lo sostenido con `Input.action_press` e inyecta las pulsaciones con `Mando.pasos_inyectar` (las consume el primer paso).
Dirección «campo» (arriba = hacia el arco rival, sin depender de la cámara), cambio manual; los rivales se enfrían y se apartan a 7 m
mientras se mide (se mide el mando, no el duelo). La sonda plausible juega partidos completos de CPU contra CPU con la duración del
ritmo «normal» (45 × 5,5 s por parte) y 10 clubes de 5 países (ESP, ARG, ITA, BRA, GER; dos por país, cruces entre países).

## 1. Perfil de manejo (C4, tres clubes)

| Medida | CHI (Lautaro, MCD) | ESP (Neptuno, MC) | ITA (Tevere, MC) |
|---|---|---|---|
| Latencia pase (cuenta / balón sale) | 1 / 1 paso | 1 / 1 | 1 / 1 |
| Latencia tiro (al soltar; cargado y toque) | 1 / 1 | 1 / 1 | 1 / 1 |
| Latencia cambio de jugador | 1 | 1 | 1 |
| Sin balón: punta trote / sprint | 4,50 / 7,24 m/s | 4,68 / 7,50 | 4,25 / 6,85 |
| Sin balón: 90 % de la punta (sprint) | 0,80 s | 0,82 s | 0,77 s |
| Con balón: punta trote / sprint | 3,93 / 6,35 m/s | 4,12 / 6,64 | 3,74 / 6,03 |
| Con balón: 90 % de la punta (sprint) | 0,68 s | 0,70 s | 0,67 s |
| Giro 90° a punta sin balón: rumbo nuevo (±10°) / radio | 0,53 s / 2,3 m | 0,57 s / 2,6 m | 0,52 s / 2,1 m |
| Giro 90° con balón: rumbo (±20°) / pérdida de velocidad | 0,40 s / −19 % | 0,43 s / −19 % | 0,38 s / −19 % |
| Giro 180° con balón: rumbo / pérdida | 0,75 s / −44 % | 0,80 s / −43 % | 0,73 s / −44 % |
| Error angular del pase manual (6 direcciones) | 0,0-2,2° | 0,0-2,2° | 0,0-2,2° |
| Pase manual raso de 12 m: dónde se para | **12,0-12,9 m (media 12,5)** | igual | igual |
| Primer toque (pase de la IA de 14 m) | controlado a 1,30 s (llega a 5,7 m/s); se aleja ≤ 1,17 m | 1,30 s; ≤ 1,18 m | 1,27 s; ≤ 1,19 m |

- **A1.1 (latencia)**: dentro del motor, la reacción es en el MISMO paso de 1/60 s (16,7 ms) para pase, tiro y cambio. La latencia de
  extremo a extremo (entrada del sistema + fotograma + pantalla) sigue sin medir: necesita la laptop y el teléfono del dueño (cap. 4 §4.9).
- **A1.2**: ANTES 8,3 m de media (7,9-8,8: FUERA); AHORA 12,5 m (dentro de 12 ± 1,5). Ver §3.
- Lo demás no tiene umbral en H1: queda como línea base para la prueba ciega. Es un manejo rápido, de arcade (90 % de la punta en
  ~0,8 s; en el fútbol real son 2-3 s); el giro de 180° con balón cuesta casi la mitad de la velocidad, el de 90° una quinta parte.
  El error angular del pase manual es muy bajo (≤ 2,2°) y no depende del jugador: el pase manual es casi perfecto.

## 2. Fútbol plausible (C4 CPU contra CPU)

Línea base, 13 partidos completos (7 + 6; `DESDE=0` y `DESDE=7`), con los cambios de este documento (que no tocan la IA):

| Criterio | Banda | Medido | Estado |
|---|---|---|---|
| A1.3 Goles por partido | 2,5-3,3 (alarma) | **6,15** (reparto 3-10) | ALARMA |
| A1.4 Remates por partido | 22-28 | 23,8 | ok |
| A1.4 Remates dentro del área | ≥ 60 % | ~48 % | fuera |
| A1.5 Goles / xG propio | diferencia ≤ 25 % | 1,51 (+51 %) | fuera |
| Conversión por remate | (real ~11 %) | 25,8 % | — |
| A1.6 PPDA presión ALTA frente a BLOQUE BAJO (5 cruces × 2) | menor con presión alta | **5,37 frente a 8,69** (menor en 4 de 5 cruces) | ok |

De dónde salen los goles (6 partidos, por partido; un gol es «del» remate si entra en ≤ 4 s sin otro remate en medio):

| Zona del remate | Remates | Goles | Conversión | Real aprox. |
|---|---|---|---|---|
| Dentro del área (< 16,5 m, sin penales) | 9,5 | 3,67 | **39 %** | 13-15 % |
| Frontal (16,5-25 m) | 6,0 | 0,50 | 8 % | 5 % |
| Lejos (> 25 m) | 6,2 | 0,67 | 11 % | 2-3 % |
| Penal | 1,0 | 0,50 | 50 % | 75 % (y ~0,3 penales por partido) |

Otros contadores por partido: a puerta con el pie 9,3 de 17,5 (53 %; real ~33 %), cabezazos 3,2 (0,67 goles), rechaces del portero 5,2.

**Causa probada y descartada (sin cambio en el motor por defecto):** el remate dentro del área entra demasiado. Se probó el portero:
bandera nueva `C4_ALCANCE_AREA=k` (gancho neutro `_alcance_extra` en `motor_jugable_p7_p1.gd`, `MejorasC4Avance.alcance`; el alcance
del portero ante remates desde < 17 m se multiplica por k). Con k = 1,5: 5,33 goles y 37 % dentro; k = 2,0: 5,33 y 34 %; k = 1,5 con
`C4_ERROR_AREA` = 1,4: 5,50. Con 6 partidos el ruido es de ±0,7 goles: **el portero no es el cuello de botella** (lo mismo que encontró
la sesión 15 con `C4_PARADA_AREA`). En remates aislados (tirador solo contra el portero, 120 por distancia) C4 y el motor de siempre dan
cifras parecidas: la diferencia está en las SITUACIONES de remate (rematadores libres dentro del área, poca presión y pocos bloqueos),
es decir, en la IA defensiva (colocación sin balón, marcaje y bloqueo del tiro), que es trabajo del frente 3 (jugabilidad) y del dueño.
La bandera queda APAGADA (0); con ella apagada el motor no cambia (huella igual).

Por orden 38/39 del dueño (diversión por encima de las cifras) y el propio cap. 9 («A1.3-A1.7 son detectores»), la alarma se
documenta: con los mismos ajustes, C4 daba ~4,4 goles el 12-11 (MITAD 240 a 1/30 s); hoy, con los pasos de 1/60 s del estadio y los
cambios de H0 (pases más tensos, más balón a media altura), ~6. **Pendiente** para quien siga con C4: subir la presión y el bloqueo
sobre el rematador dentro del área (no el portero ni la puntería) y volver a medir con esta sonda en dos muestras de países.

Nota sobre el PPDA: se cuenta como acciones defensivas cada recuperación del balón (robo o corte) y cada falta del equipo que defiende
dentro del 60 % del campo del que tiene el balón; los pases son los que da ese equipo en esa zona. Los valores absolutos (5-9) salen
más bajos que los reales (8-15) porque C4 da menos pases por posesión; lo que pide A1.6 es la diferencia, y se cumple.

## 3. Lo que se cambió (y qué cambia al jugar)

1. **Pase manual raso con la ley que mueve el balón (A1.2, causa del fallo M6-06 que quedaba).** `_pase_manual` (capa 9) pedía la
   velocidad con la ley del motor de siempre (`velocidad_para(dist, 4.0)`, estática) aunque en C4 el balón rueda con la de League: un
   12 m rodaba 8,3 m. La prueba del banco de H0 medía `_velocidad_pase`, que el botón no usa. Ahora `_pase_manual` llama al método
   `_velocidad_pase_manual(dist)`: en el motor de siempre, igual que antes (`LeyBalon.velocidad_siempre(dist, 4.0)`); en
   `MotorLeague`/C4, `LeyBalon.velocidad_league(dist + SOBRA_MANUAL)` con `SOBRA_MANUAL` = 0 (el balón muere en el punto apuntado;
   con el medio metro que sale por delante del pie, un 12 m para a ~12,5 m; con 1 m de sobra paraba a 13,5, en el borde).
   **Cambia cómo se juega** con la ayuda de pase MANUAL: el pase de 12 m (16 con RB) llega donde apuntas, más fuerte que antes.
   El pase asistido, el de la IA y el motor de siempre no cambian.
2. **Gancho `_alcance_extra` + bandera `C4_ALCANCE_AREA`** (apagada): herramienta de medida, no cambia el juego.
3. Banco: `_probar_perfil_manejo_c4` (A1.2 por el camino real del botón y latencia de pulsación ≤ 1 paso, manual y asistido).

Huella `igualdad_motor`: **4068298361 sin cambios** (dos corridas seguidas iguales; su guion usa el pase asistido). Sin cambios en
C++ (`nativo/src`): no hace falta recompilar.

## 4. Partido simulado (A1.7)

Ya estaba recalibrado: `pruebas/ideas/cifras_partido.tscn` (1.110 partidos) da 2,75 goles, 23,9 remates, 8,3 a puerta, **11,5 % de
conversión** (banda 9-15 %) y el portero para el 67 %; `pruebas/ideas/a4_partido_cruzado.tscn`: el mejor (71) contra el peor (41)
promedia 4,3 goles y la goleada máxima es 9 (antes 15-0). Se borró de `PLAN_GENERAL.md` la nota vieja del 4-11 (27 %). El «hoy 27 %»
de la tabla del cap. 9 del informe (A1.7 y la fila de la tabla de brechas) está desactualizado: hoy 11,5 %.

## 5. Pendiente

- A1.3-A1.5 fuera de banda en C4 (alarma, ver §2): IA defensiva dentro del área; medir con `futbol_plausible` (50 partidos ≈ 1 h a
  1/60 s: partir en tandas con `DESDE`/`N`).
- A1.1 de extremo a extremo y A1.8-A1.10: necesitan al dueño (laptop, teléfono, nota, prueba ciega, FPS).
- La sonda plausible a 1/60 s cuesta ~75 s por partido en esta máquina: los 50 partidos del criterio no cupieron en esta pasada
  (13 de línea base + 10 del PPDA + 18 de calibración).
