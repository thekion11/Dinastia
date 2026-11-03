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

6. **Medición final** (32 partidos, semillas 1-32, versión `0c1253ea`): goles 74 → **84 (2,63 por partido)**, tiros 330 → 323 (10,1), pases buenos 1873 → 1734 (54,2), duelos 1545 → 1819, faltas 137 → 160, fueras de juego 24 → 19.
   Los goles ya están en el rango real (2,5-2,8). Pero se tira poco (≈10 tiros por partido entre los dos equipos; real ≈25) y se acierta demasiado (26 % de los tiros acaban en gol; real ≈10 %): los goles cuadran por compensación.

7. **Ciclo 7 (tiros), medido con `MEDIDA2` en 32 partidos**: la perilla `CHISPA_TIRO` sola sube los tiros solo +20 % (10,2 → 12,3 con valor 0; ojo: se SUMA al umbral, valores altos tiran menos);
   `PMOT_PUNT`/`PMOT_PALO` solo bajan los tiros a puerta del 69 % al 56-59 %. Hizo falta un modelo de fallo real (`MotorTiroLimpio.fallar`, bandera `TIRO_REAL`): fallo por ejecución (base + por metro + presión) y bloqueo por defensas en la línea de tiro,
   más alcance de tiro (`TIRO_ALCANCE`). El bono de ganas dentro del área (`TIRO_BONO`) no cambió el reparto: los tiros desde dentro no están limitados por las ganas sino por las pocas veces que se llega al área (construcción del ataque).
   Barrido (semillas 1-16): alcance 1,45 → 23 tiros, 10,3 % acierto, 2,38 goles pero 14 % de tiros desde dentro (descartado por irreal); alcance 1,2-1,3 con fallos 0,05-0,07 + 0,005-0,008 por metro → de 15 a 21 tiros y de 1,9 a 3,2 goles (ruido ±0,4).
   **Elegido y ENCENDIDO por defecto (`TIRO_REAL=0` lo apaga)**: alcance 1,25, fallo 0,07 + 0,008/m, `CHISPA_TIRO` 0 (huella nueva 1354138242; con todo apagado vuelve a 3180886866).

   | 32 partidos | Antes | Ahora | Real (orientativo) |
   |---|---|---|---|
   | Tiros por partido | 10,1 | **15,9** | ≈25 |
   | Tiros a puerta | 68,4 % | **42,7 %** | ≈33 % |
   | Acierto (goles por tiro) | 26 % | **14,7 %** | ≈10 % |
   | Goles por partido | 2,63 | 2,35 | 2,5-2,8 |
   | Tiros desde dentro del área | 44,5 % | 23,5 % | ≈60 % |
   | xG por tiro (aprox.) | 0,083 | 0,058 | ≈0,09 |
   | Pases buenos | 69,2 % | 68,2 % | 80-85 % |

   Pendiente de ajuste fino: goles algo bajos (2,35) y reparto por zona (más tiros de lejos). **Aviso**: el partido es una versión comprimida (≈39 pases por equipo, no ≈450); medir proporciones, no recuentos brutos.
8. **Ciclo 8 (pases), diagnóstico en 4 partidos**: de 313 pases, 97 fallados: 60 cortes con receptor, 15 cortes con el balón ya suelto, 22 otros (fuera/parado). `PMOT_PASE=1` no mejora (68,9 % frente a 69,5 %); subir el peso del riesgo (`PMOT_RIESGO`) 2 → 69,9 %, 3,5 → 71,3 %, a costa de ≈30 % de tiros y goles. Elegir mejor al receptor NO es la palanca principal.
9. **CI**: `probar_por_partes` y `control del equipo` salen intermitentes en esta rama; están arregladas en la rama de la líder (claude/dazzling-rubin-v7rfyi) y no se persiguen aquí.

10. **Ciclo 9 (construcción del ataque), traza de posesiones** (`MotorTraza`, solo cuenta; `MEDIDA3`), 32 partidos: 41,0 posesiones por partido, 18,3 entradas al área por partido; las pérdidas son 65 % ROBOS en un duelo y 35 % pases cortados;
   por zona: 50 % en el medio campo, 24 % último tercio, 13 % propio campo, 12 % dentro del área. Es decir, los ataques no mueren por falta de pases sino porque al portador se lo quitan en un duelo antes de soltarlo.
    - **Descarga bajo presión** (`MotorDescarga`, `PASE_DESCARGA=1`: con un rival a menos de 2,6 m decide ya, pausa mínima 0,4 s, espera 0,15): robos 64,5 → 58,4 %, pero posesiones 41,0 → 39,7, entradas al área 18,3 → 17,7, pases buenos 68,2 → 68,1 %,
      tiros 15,9 → 16,1, goles 2,34 → 2,31. NO mejora lo que importa → **se queda APAGADA**. Lo que antes era robo se pierde ahora de otra forma.
    - **Pase raso más rápido** (`PMOT_VEL`, menos tiempo para cortarlo): semillas 1-16: ×1,2 → pases 70,1 → 73,9 %, goles 2,5 → 3,25; ×1,4 → 73,8 % pero 36 controles largos (el receptor no controla). Con 32 partidos:

      | 32 partidos | Pases buenos | Tiros | Acierto | Goles | Controles largos (por 16 p.) |
      |---|---|---|---|---|---|
      | Base | 68,2 % | 15,9 | 14,8 % | 2,34 | 14,5 |
      | **Pase ×1,2 solo** | **72,6 %** | 17,8 | 14,6 % | **2,59** | 13,5 |
      | Pase ×1,2 + fallo de tiro más duro (0,11 + 0,010/m) | 72,3 % | 17,5 | 14,8 % | 2,59 | 16,0 |

      **Elegido y ENCENDIDO por defecto: `PMOT_VEL=1,2` solo** (`PMOT_VEL=1.0` lo apaga). Huella nueva 2257420708; con todo apagado vuelve a 3180886866. Mejora los pases buenos (+4,4 puntos), los tiros y devuelve los goles al rango pedido.
      Sigue lejos de 80-85 % de pases buenos: el 77 % de los fallos son cortes de un rival; faltan receptor que se ofrece y mejor elección del pase con riesgo.

11. **Ciclo 10 (robos al portador): CORRECCIÓN.** La primera traza etiquetaba como «robo» (65 %) cualquier pérdida sin pase propio en vuelo; esa etiqueta era demasiado ancha y mi lectura («hay que calibrar las entradas») era errónea.
    Contadores de `_entrada` (16 partidos): ≈10 intentos por equipo y partido, 15 % de éxito, ≈2,9 entradas con éxito por partido entre los dos equipos (reales: ≈16-20 entradas por equipo, StatMuse 2025-26; no hay fuente fiable de % de entradas ganadas ni de regates en lo que se pudo abrir).
    Barrido `ENTRADA_K` (éxito ×0,6) y `ENTRADA_ENF` (espera ×2-2,5): robos 70 → 66-68 %, sin mejorar pases ni entradas al área → **se quedan neutras (1,0) y apagadas**.
    **Traza con 5+ causas (16 partidos, 37,4 pérdidas/partido):** pase cortado 29,9 % (11,2/p); reanudación (saque de banda/córner/falta/puerta que acaba en el rival, pérdida en los 4 s tras reanudar) 27,8 % (10,4/p); balón suelto por otros motivos 20,1 % (7,5/p);
    entrada 11,4 % (4,2/p); tiro parado/desviado 8,2 % (3,1/p); toque largo 2,7 % (1,0/p). Lo que más pesa y es corregible: pase cortado y la calidad de las reanudaciones.
    Lección de método: la traza solo seguía la posesión en juego vivo; las reanudaciones dejaban el dato de «quién soltó el balón» anticuado y se leían como balones sueltos largos. Aviso: una etiqueta ancha lleva a calibrar lo que no es.
    Siguiente (ciclo 11): calidad de las reanudaciones (el receptor del saque de banda, del córner y del saque de puerta se elige y se sirve mejor) y el receptor que se ofrece.

12. **Ciclo 11 (reanudaciones).** Retención por tipo en 16 partidos (pérdida = cambio de posesión en los 4 s siguientes): puerta 72 %, banda 41 %, centro (tras gol/inicio de parte) 41 %, falta 83 %, córner 77 %.
    `MotorSaque` (`SAQUE_SEGURO=1`: banda y centro al compañero más libre a 4-22 m con la línea limpia; 32 partidos): retención banda 45 → 40 %, centro 48 → 44 %, pérdidas por reanudación 9,7 → 9,8 por partido, pases 72,6 → 73,0 %, goles 2,59 → 2,79. **No mejora → APAGADO.**
    Causa probable: la métrica cuenta cualquier cambio de posesión en los 4 s tras el saque, no solo que el rival lo coja; el receptor recibe presionado y lo pierde. A quién se saca no es la palanca.
    **`SAQUE_OFRECE=1`** (`MotorSaque.oferta`: los dos compañeros más cercanos al lanzador se ofrecen hacia dentro, uno corto y otro en diagonal; 32 partidos): retención banda 45 → 41,5 %, centro 49 → 47 %, pérdidas por reanudación 9,75 → 10,05/p, pases 72,6 → 72,4 %, goles 2,60 → 2,50. **No mejora → APAGADO.**
    Dos intervenciones distintas sobre las reanudaciones (a quién se saca; que los compañeros se ofrezcan) dan lo mismo: la retención (≈40-45 %) no depende de cómo se sirve el saque sino de lo que ocurre después (receptor presionado). Reanudaciones zanjadas.
    Dato para después (de la líder): ≈10 intentos de entrada por equipo frente a ≈16-20 reales; probar MÁS entradas (el barrido hecho solo probó menos intentos / menos éxito).
13. **Ciclo 12 (la defensa entra poco): ENCENDIDO `ENTRADA_MOMENTO`** (`MotorEntrada`: el radio de la entrada crece +0,5 m con el portador de espaldas, +0,5 con control largo (balón a >0,8 m), +0,3 pegado a la banda, tope +0,8; el resto, contención como antes).
    32 partidos: intentos de entrada por equipo 10,5 → **20,3** (real ≈16-20), éxito 13,2 → 14,7 %, entradas con éxito 2,75 → 5,95/p, faltas 4,7 → 7,6/p, entradas al área 20,9 → 20,3/p, pases 72,6 → 72,9 %, goles 2,60 → 2,56.
    Huella nueva 1143991806; con todo apagado (+ ENTRADA_MOMENTO=0) vuelve a 3180886866. Faltan: pases buenos (72,9 % frente a 80-85 %), reparto de tiros por zona, y el receptor que se ofrece en juego (los pases cortados son el 30 % de las pérdidas).
14. **Ciclo 13 (receptor que se ofrece / pases cortados).** Traza de cada pase en el instante de la patada (32 partidos, 70,2 pases/partido, 18,0 % cortados por un rival = 12,7/p): por receptor, en movimiento 60,3 pases/p con 20,2 % de corte; **quieto 9,9 pases/p con solo 4,4 %** (el «receptor quieto» NO es el problema).
    Por línea: libre 57,2 pases/p, 16,0 % de corte (9,2 cortados/p); tapada 13,0 pases/p, 26,9 % (3,5/p) → 9,2 de los 12,7 cortes ocurren con la línea LIBRE al salir el pase. Por distancia: largo 30,2 pases/p, 21,2 %; medio 28,5, 13,5 %; corto 11,5, 20,9 %.
    Clase dominante: receptor en movimiento + línea libre + pase largo = 23,0 pases/p (33 % de todos) y 4,6 cortados/p. Medido: los pases largos son 43 % de los pases.
    **`PMOT_DIST`** (penalización por metro de distancia en la nota del pase; 0,02 = la de siempre): semillas 1-16: 0,05 → pases 72,4 → 75,6 %, goles 2,56 → 2,31, entradas al área 20,1 → 18,3; 0,09 → 74,2 %, goles 1,81, área 15,9 (demasiado).
    **Confirmación en 32 partidos con 0,035: pases 72,8 → 72,3 %, cortados 12,7 → 13,2/p, goles 2,56 → 2,12 → NO mejora → se queda APAGADA (0,02).** La mejora de 16 semillas era ruido. Reducir los pases largos no reduce los cortes.
    Lección: una mejora vista en 16 partidos hay que confirmarla en 32 antes de creerla (el ruido en pases es ±1-2 puntos y en goles ±0,4).
    Sigue en 72-73 % de pases buenos tras muchas palancas (velocidad del pase, riesgo, distancia, descarga, saques, entradas): el 80-85 % probablemente exige un cambio de mecánica (geometría de intercepción, control del receptor, velocidad de los defensas), no de afinado de la nota del pase.
    CI: `control del equipo` («L3 + R3 = bloqueo de jugador») salió rojo una vez en `especiales 3/6`; es una de las pruebas inestables arregladas en la rama de la líder, no se persigue aquí.
15. **Ciclo 14 (geometría de la intercepción, control del receptor).** Traza `MotorTraza.cortar` en 32 partidos (405 pases cortados, 12,7/p): distancia del cortador a la línea del pase al patear: sobre la línea (<1,2 m) 7,4 %, cerca (1,2-3 m) 24,4 %, **corriendo (>3 m) 68,1 %**; tiempo de vuelo hasta el corte: rápido (<0,3 s) 5,4 %, normal 8,4 %, **lento (>1 s) 86,2 %**. El defensa no corta a >1,2 m sin tiempo de reacción: llega corriendo durante vuelos largos. No hay mecánica irreal que corregir.
    Control del receptor (`MotorControl`): 21-22 controles largos por 16 partidos (≈1,3/p) frente a ≈52 pases completados/p → ≈2,5 % de fallos; no es la palanca.
    Conclusión: el 72-73 % de pases buenos es el valor natural de este motor con vuelos largos (43 % de los pases son largos). Sin cambios de comportamiento en este ciclo (solo la traza, cuenta sin afectar la huella 1143991806). Falta la comparación de velocidades defensa/atacante.
16. **Ciclo 15 (distribución del pase): ENCENDIDO `PMOT_PROG=10`** (`MotorPaseMejora.progreso`: tope de 10 m al avance que cuenta en la nota del pase; antes el avance por metro no tenía tope y un envío de 30 m siempre ganaba a un pase corto). 32 partidos (clase `largo` ≥22 m según la traza): sin tope pases largos 43,1 %, pases buenos 72,8 %, goles 2,56, tiros desde dentro 24,8 %; tope 14 m: 33,1 %, 75,2 %, 2,44, 19,1 %; **tope 10 m: 31,4 %, 76,8 %, 2,47, 22,6 %**. Se enciende 10 m. Sigue lejos del objetivo (≤20 % largos, 80-85 % buenos): queda la otra palanca (apoyos cortos a 8-15 m).
    Huella nueva 1187665755; con `PMOT_PROG=999` vuelve a 1143991806.
17. **Ciclo 15b (apoyos cortos): `APOYO_ANILLO` (distancia a la que se ofrece el compañero al portador) NO se enciende.** 16 partidos (semillas 1-16, con PMOT_PROG=10): 12 m (actual) largos 31,3 %, pases 75,7 %, goles 2,06; **9 m** 29,0 %, 78,1 %, **1,56** (los goles se hunden: ataque más lento/previsible, tiros desde dentro 23 → 16 %); **7 m** 30,1 %, 74,8 %, 2,13. Ninguno mejora los pases sin bajar los goles de ~2,4; se queda 12 m. El % de pases largos casi no depende de dónde se ofrece el compañero: depende de la nota del pase (el tope PMOT_PROG sí lo movió).
18. **Ciclo 16 (giro del defensor): ya está modelado.** `motor_jugable_p5` limita el giro por velocidad (9 → 2,6 rad/s según corre), frena en giros bruscos y topa la aceleración total (`A_MAX`), igual para todos los jugadores: el defensor que sale de cara ya paga el giro. No se añade otro coste (sería contarlo dos veces).
19. **Ciclo 17 (línea de 4 al defender), medido** con `MotorTraza._linea` (1 muestra/s cuando el rival tiene el balón; 789 muestras, 8 partidos): ancho total de la línea **32,5 m**, separación entre los dos centrales **8,8 m**, desfase en profundidad entre el defensa más adelantado y el más retrasado **7,3 m**. Referencia (FIFA Training Centre, manuales de entrenadores; las cifras de los blogs discrepan, 5-7 / 6-8 / 8-12 m): 6-8 m entre defensas vecinos y línea casi plana; UEFA da ≈44 m entre laterales de la línea de 4 del Real Madrid. Diagnóstico: separación razonable, **línea bastante escalonada (7 m)** y algo estrecha. Posible bandera `LINEA_PLANA` (empujar a la línea común a los laterales); se prueba aparte (16 → 32 partidos) porque mover la defensa mueve los goles.
20. **Ciclo 19 (por qué se elige el pase largo):** traza `MotorTraza._opcion_corta` (nota sin azar del largo frente a la mejor opción corta: compañero a 4-15 m con rival a ≥3 m; 16 partidos, 364 largos): **sin opción corta libre 49 %** (180), corta con mejor nota 15 %, cercana (<0,7) 15 %, media (<2,0) 14 %, lejana 7 %. Es decir: la mitad de los largos salen porque el poseedor está presionado y sus cercanos no están libres (problema de espacio/presión), y ~44 % tenían una corta equivalente (peso de la nota). `PMOT_PROG=6` (32 partidos): largos 31,4 → 29,0 %, pases 76,8 → 77,8 %, goles 2,47 → **2,25** (<2,3), dentro 22,6 → 21,1 %: ganancia marginal con goles en el límite bajo → NO se enciende (se queda 10 m).
21. **Ciclo 19b (el largo sin opción corta: no es marcaje, es distancia).** De los 180 largos sin opción corta libre (16 partidos), en **155 no había NINGÚN compañero a 4-15 m del poseedor**; solo 25 tenían a alguien cerca pero marcado (mejor libre <1,5 m: 4; 1,5-2,2: 8; 2,2-3: 13). La hipótesis del desmarque del compañero marcado (líder) explica ≈14 % de los casos; lo común es que el bloque esté estirado. `APOYO_ALCANCE` (radio en que los compañeros se ofrecen, 18 m): 26 m → largos 31,3 → 26,6 %, pases 75,7 → 74,2 %, goles 2,06 → 2,44; 34 m → 29,4 %, 74,6 %, 2,44 (semillas 1-16). Los largos bajan pero los pases buenos NO suben (pierde en el medio: más pases cortos presionados) → no se enciende (se queda 18 m).
22. **Ciclo 20 (portero): `PARADA_K` NO se enciende sola.** Con las cifras de 32 partidos el portero para el **59,5 %** de los tiros a puerta (79 goles de 195; real ≈70 %); el motor tiene más goles por tiro a puerta (40 %) que el fútbol real (≈30 %) pero menos tiros a puerta (6,1 frente a ≈9 por partido), y los dos errores se compensan en los goles (2,47). `PARADA_K` (multiplica la probabilidad de atajar, `0,47 + reflejos·0,42`; semillas 1-16, ruido ±5 puntos): 1,0 → paradas 65,3 %, goles 2,06; 1,15 → 62,5 %, 2,44; **1,3 → 70,1 %, goles 2,00**. Subir las paradas sin más tiros a puerta hunde los goles (<2,3). Hay que hacerlo junto con más tiros a puerta (≈9/partido): queda para una pasada conjunta de tiros + portero; se queda 1,0.
23. **Ciclo 21 (compacidad del bloque): NO está estirado.** Traza `MotorTraza._bloque` (789 muestras/equipo, 8 partidos; jugadores de campo, sin portero): CON balón largo **35,5 m**, ancho **37,9 m**; SIN balón largo **35,0 m**, ancho **35,7 m**; compañero más cercano del poseedor a **10,2 m** de media. Referencia (estudio de 12 partidos de la Premier League con seguimiento, 1.413 posesiones; PMC6705862 y revisión de varias ligas): con balón ≈38 m de largo y ≈43 m de ancho (rangos 31-46 y 35-48 m). El motor está dentro de rango, algo corto en ancho (−5 m) y casi igual con y sin balón (el real se abre con balón). Conclusión: el bloque no está por encima de la referencia (la orden del líder pedía acortarlo si lo estaba) → no hay bandera de acortar. Los «155 sin nadie a 4-15 m» son momentos puntuales de presión, no un bloque estirado; si algo sobra es poco ancho con balón (posible `ANCHO_CON_BALON` +5 m, sin probar).
24. **Ciclo 22 (pasada conjunta tiros + portero): ENCENDIDO `TIRO_ALCANCE` 1,5 · `TIRO_BONO` 0,4 · `PARADA_K` 1,3.** Más tiros sin más paradas hundía/inflaba los goles; juntos se compensan. 32 partidos: antes (alcance 1,25 · bono 0,25 · K 1,0) tiros 16,6/p, a puerta 6,1, paradas 59,5 %, goles 2,47, dentro del área 22,6 %, pases 76,8 %. Pruebas intermedias (32): K 1,4 → 20,9 tiros, 7,5 a puerta, 69,3 %, goles 2,31; K 1,25 → 21,0, 8,6, 66,9 %, goles 2,84. **Valores elegidos (K 1,3): tiros 20,9/p, a puerta 8,0, paradas 68,1 %, goles 2,56, pases 75,4 %, dentro del área 12,8 %.** Cumple la orden (≈8-9 a puerta, ≈70 % paradas, goles 2,4-2,8). Costes que quedan: el reparto por zona EMPEORA (el alcance saca más tiros de lejos; real ≈60 % dentro) y los pases buenos pierden 1,4 puntos. `TIRO_BONO` casi no mueve los tiros (0,8 apenas subió de 15,3 a 16,6); la palanca del número de tiros es el alcance. Pendiente: tiros desde dentro del área (centros, llegadas al área). Huella nueva 4287091214; con 1,25 / 0,25 / 1,0 vuelve a 1187665755.

## Cifras reales de fútbol que se persiguen (orden de la sesión líder)
≈2,5-2,8 goles, ≈25 tiros, ≈80-85 % de pases buenos por partido. Estado: tiros ≈10-12 por partido y pases buenos ≈53-59 (conteo, no porcentaje): **faltan por debajo**; `zz_medir_partido` no da el porcentaje de pases, hay que añadirlo.

## Siguiente
- **Ciclo 7 (tiros y acierto):** más remates y menos acierto por remate (ganas de tirar desde la frontal, error de puntería por distancia, `CHISPA_TIRO`, `PUNTERIA`), medido contra ≈25 tiros y ≈10 % de acierto. Ojo: mover los tiros mueve los goles; recalibrar a ≈2,5-2,8.
- Medición final de 32 partidos con todo lo anterior (en curso).
- Añadir a `zz_medir_partido` la posesión y el % de pases buenos.
- Casos concretos en `pruebas/arena/arena.tscn`: amontonamientos, defensas que no cierran, porteros que no salen.
- Tabla de coordenadas por posición del balón (Delaunay/bilineal) para la formación.
