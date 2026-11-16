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

## 6. Segunda pasada (16-11, tarde): ¿por qué ~6 goles en C4?

**¿Regresión de H0?** Misma sonda y mismos cruces en el commit anterior a H0 (`bfae8e7f`, worktree aparte) y en el actual:

| Muestra (6 partidos cada una) | Antes de H0 | Con H0 |
|---|---|---|
| `DESDE=0` | 3,50 | 6,00 |
| `DESDE=7` | 5,17 | 5,83 |
| `DESDE=13` | 4,50 | 4,67 |
| **18 partidos** | **4,39** | **5,50** |

+1,1 goles con un error de ~0,7 (la desviación por partido es ~2 goles): posible subida parcial, no concluyente, y ANTES de H0
C4 ya estaba muy por encima de la banda (4,4). Con las dos piezas sospechosas de H0 vueltas atrás en la muestra `DESDE=0` (6,00 con H0):
pase de C4 pedido con la ley de siempre (bandera temporal, ya borrada) → 6,67; sin contrapresión (`SIN_CONTRAPRESION=1`) → 5,17. Ninguna
explica la diferencia: no se toca H0.

**Lo que se probó para bajar los goles (todo en C4, con bandera; todo APAGADO al final):**

| Bandera | Qué hace | Medido | Veredicto |
|---|---|---|---|
| `C4_ALCANCE_AREA=k` | alcance del portero ×k ante remates desde < 17 m | k 1,5 / 2,0: 5,33 / 5,33 goles (6 partidos) | sin efecto medible |
| `C4_ALCANCE_TIEMPO=v` | el alcance sigue creciendo con el tiempo de vuelo (`v·(tz − 0,5)` m; antes se saturaba a 0,52 s) | aislado: gol de lo que va a puerta desde 22-28 m 35/27 % → 28/20 % | ayuda de lejos, poco en partido |
| `C4_CIERRE_AREA=1` | con el balón rival a < 24 m: el 2.º presionador tapa la línea de tiro y el compañero libre más cercano marca a cada rival del área | 6,17 (base 6,00) | sin efecto medible |
| `C4_TIRO_COMPANERO=1` | un compañero del rematador no «controla» un tiro a > 12 m/s que le pasa cerca (hoy se queda el balón con ~85 % y remata a quemarropa) | 5,17 (base 6,00) | dentro del ruido |
| las tres juntas + `C4_ALCANCE_TIEMPO=3` | — | muestra 1 (ESP, ARG, ITA, BRA, GER), 12 partidos: 5,67 (base 6,42); muestra 2 (ENG, FRA, MEX, POR, NED): 6,58 (base 5,67) | NO baja |
| `C4_PRESION_AREA=k` | el error del remate desde < 17 m crece con lo cerca que esté el rival | sin medir en partido | apagada |
| `C4_ERROR_AREA` 1,8 / 2,5 (de la sesión 15) | más error en el remate del área | aislado: más fuera, pero los que van a puerta entran igual (32-37 %) | sin efecto |

**Lo que se aprendió (diagnóstico, con contadores temporales ya quitados):**
- Remate AISLADO (tirador solo contra el portero, `pruebas/_sonda/sonda_remate_portero.tscn`, nueva): C4 y el motor de siempre conceden
  ~35 % de lo que va a puerta (real ~30 %; desde 22-28 m 27-35 %, real ~15 %). El portero no está roto; casi todos los goles son remates
  fuera de su alcance (`lat ≥ alcance`) y ni `PARADA_K` 1,8 ni `PARADA_SUELO` 0,7 lo mueven.
- En partido, de 8,3 paradas decididas por partido solo se hacen 3,3: el resto se anulan porque otro toca el balón antes (2,3 un compañero
  del rematador, 1,0 un defensa, 1,0 el propio portero). Es el «desorden» que ya había visto la sesión 15.
- Al encajar, el portero está a 1,5-4,5 m del balón en lateral en la mayoría de los goles (vencido), y a 4-8 m de su arco en ~1/3.
- C4 tira ~10 a puerta con el pie y ~3 de cabeza por partido (real ~8,5 en total) con un 40-45 % de gol de lo que va a puerta: sobran
  tanto el volumen a puerta como la calidad de cada ocasión.

**Conclusión:** sigue la alarma A1.3 (≈ 5,5-6 goles). Ninguna palanca local (portero, cierre, rematador, error) la baja de forma medible
con 12 partidos por muestra; el ruido (±0,6) tapa efectos de < 1 gol. Lo siguiente tendría que ser estructural (cuántos jugadores
defienden dentro del área cuando llega el balón y cuántas llegadas limpias hay), con 24+ partidos por variante, o aceptar la cifra si
el dueño y la prueba ciega prefieren C4 así (cap. 9, «detectores»). Huella `igualdad_motor` sin cambios (4068298361, dos corridas): con
las banderas apagadas los ganchos nuevos (`_alcance_extra`, `_puede_tomar_tiro`) no cambian nada. Banco `BANCO_PARTES=2`: «FIN. 0 fallos».
