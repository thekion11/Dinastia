# Capítulo 9. Plan hacia la versión 1.0: hitos, métricas y criterios de aceptación

Informe académico AAA de Dinastía · Redacción: 16-11-2026.
Convenciones: [M] medido · [D] documento del proyecto · [F n] fuente del capítulo 2 · [R n] fuente del capítulo 11 · [E] estimación. Los números «top n» remiten al paquete recomendado del capítulo 11 (§11.7); «tarea n», a las cien tareas del resumen ejecutivo (§11). Este plan es una propuesta: las decisiones de alcance y de producto son del dueño.

---

## Resumen

Se propone un plan de cinco hitos hacia la versión 1.0, que añade al esquema de cuatro hitos del resumen ejecutivo un hito previo de **saneamiento (H0)**. H0 cierra los fallos pendientes de gravedad alta y media de los capítulos 5 a 7, deja las especiales en verde, incorpora al criterio de subida las comprobaciones que el capítulo 5 encontró ausentes y obtiene la primera serie de mediciones del teléfono con el protocolo del capítulo 4. Los hitos H1 a H4 («se juega bien», «se ve y se oye como TV», «se entiende y engancha», «1.0 cerrada») se reformulan con métricas medibles, umbrales con fuente y criterios de aceptación verificables, y se ligan a los identificadores de fallo y a los recursos públicos del capítulo 11.

Al 16-11 se arreglaron **16 de los 64 defectos** registrados por los capítulos 5 a 7 (el plan del proyecto dice «15»; la lista que da tiene 16 identificadores): M6-01, M6-02, M6-03, M6-04, M6-05, M6-08, M6-09, M6-11, G-01, G-02, G-03, G-04, R-01, R-02, R-03 (este último mitigado, no resuelto en su causa) y V-01. Después se arreglaron también F-02 (menú lateral), L-01 (`InteriorOculto`) y L-04 (mensajes con `%`), y F-04 se cerró como excepción declarada por decisión del dueño (commits `6bbbdabb` y `344d0964`); F-01 (contrapresión) está en curso con autorización del dueño. Quedan pendientes, entre otros, todos los de La Ruta de gravedad media, la unificación de la física del balón de C4 (M6-06, M6-07) y la táctica inerte (F-01). La duración total estimada es de 20 a 28 semanas de trabajo enfocado [E].

---

## 9.1 Principios del plan

1. **Primero corregir, después pulir.** No tiene sentido equilibrar premios calculados con contadores que se borran al cargar (cap. 7 §7.8), ni ajustar el pase con dos leyes de rozamiento distintas (cap. 6 §6.7.3).
2. **Cada hito tiene criterios de aceptación verificables** por una herramienta existente o por una prueba con personas, y un responsable del veredicto (el dueño para lo que se siente; el banco para lo que se comprueba).
3. **Los umbrales se toman de fuentes cuando existen** (latencia [F 33][F 35]; bandas de fútbol real [F 48][F 49]) y del dueño cuando son decisiones de producto (FPS, notas). Donde no hay fuente ni decisión, se mide la tendencia y no se fija un umbral.
4. **Diversión por encima del realismo** (orden 38): las bandas de fútbol real son detectores de anomalías, no objetivos (cap. 2, I8).
5. **Solo recursos gratuitos con licencia comercial** (orden 57), anotados con la plantilla del capítulo 11 (§11.8). El dueño aprobó el paquete de 25 y las cuatro opciones que esperaban su permiso [D: `PLAN_GENERAL.md`, «INFORME ACADÉMICO AAA»].
6. **Reglas del proyecto como invariante**: banco en «FIN. 0 fallos», ningún script de más de 450 líneas, gemelas C++ iguales byte a byte, Sonar sin avisos nuevos, memoria del menú [D: `CLAUDE.md`].

---

## 9.2 Estado de los fallos al 16-11

### 9.2.1 Arreglados el 16-11

| Id | Gravedad | Qué se hizo | Commit [D] | Observación |
|---|---|---|---|---|
| M6-01 | Alta | Las pulsaciones del estadio se acumulan por fotograma y las consume el primer paso del motor (`Mando.pulsado`) | `965eb8f7` | Falta medir la respuesta a 30 y 120 FPS |
| M6-02, M6-03, M6-08, M6-09 | Alta / media | Al empezar cada mitad se desplazan todos los plazos absolutos y se borra la memoria de la CPU | `965eb8f7`, `56d865f1` | Arreglo «mínimo» (rebase), no el estructural del cap. 6 §6.7.1 (reloj monótono); cada plazo nuevo deberá registrarse |
| M6-04 | Alta | Fuera de juego juzgado en cabezazos y remates de primera; se borra al reiniciar con un saque | `1f694bb9` | Debe reducir goles de cabeza en C4: falta medirlo |
| M6-05 | Alta | El motor del descanso recibe las amarillas del acta; la segunda es roja | `965eb8f7` | — |
| M6-11 | Media | El segundo tiempo hereda las estadísticas del acta | `56d865f1` | — |
| G-01 | Crítica | Un número flotante del JSON vale donde se espera un entero (estadísticas de temporada) | `965eb8f7` | Falta la prueba de ida y vuelta por JSON (cap. 7 §7.7) |
| G-02 | Alta | El simulado acredita al asistente; las asistencias se reinician por temporada | `bef7ec3b` | Cambia estadísticas del mundo |
| G-03 | Alta | Los continentales se reconstruyen al cargar La Ruta | `56d865f1` | — |
| G-04 | Alta | El mundo entrena semanalmente en La Ruta | `56d865f1` | Cambia el equilibrio: medir con `sonda_ruta` |
| R-01 | Crítica | El mundo no retira ni deja libre al futbolista de La Ruta | `965eb8f7` | — |
| R-02 | Alta | Los retos se juzgan con los de la semana del partido | `4a69a55d` | — |
| R-03 | Alta | Los premios por nota piden 6 notas (8 para el mejor del mundo), la ventana que guarda `Jugador` | `965eb8f7` | **Mitigado**: compara las 8 últimas notas, no la media de la temporada; el acumulador propuesto en cap. 7 sigue pendiente |
| V-01 | Media | Al cerrar la gala, el atlas de sombras vuelve al de la calidad elegida | `bef7ec3b` | — |

Todos con el banco en «FIN. 0 fallos» según el plan del proyecto [D]. **Las especiales no se han vuelto a ejecutar después de estos arreglos**: la ejecución del capítulo 5 es anterior (commit `ae23b25b`). Además, los arreglos los hizo la misma sesión que auditó; se recomienda una revisión independiente (capítulo 1, §1.8, punto 6).

También el 16-11, fuera del informe: los «parches claros» de camisetas y pantalones se arreglaron (el relieve de arrugas se sumaba sin girarlo a cada isla del atlas) y se añadió tela de punto CC0 (Poly Haven `cotton_jersey` [R 3]), con capturas de tres clubes de tres países; queda el veredicto del dueño, medir FPS en la laptop y revisar el canalé de las medias, que usa la misma suma [D: `PLAN_GENERAL.md`, «INFORME ACADÉMICO AAA»; commit `e1775cda`].

### 9.2.2 En curso (sin subir al cerrar este capítulo)

| Id | Estado observado en la copia de trabajo [M: `git diff`] |
|---|---|
| F-02 | `MenuLateral` suelta `pantalla_abierta` al cerrarse y `ocupado()` exige que la pantalla esté en el árbol y no cerrándose |
| L-01 | `InteriorOculto` usa un `bool` `_buscado` en lugar del centinela que fallaba |

### 9.2.3 Pendientes

| Grupo | Ids | Gravedad | Hito |
|---|---|---|---|
| Física del balón de C4 | M6-06, M6-07 | Media | H1 |
| Portero y cambios | M6-10, M6-13 | Media | H0 |
| Regla de 450 líneas | M6-12 = M-02 = F-03 | Media | H0 |
| Reglamento y estadísticas | M6-14 a M6-20, M6-22, M6-25, M6-26 | Baja | H1 (por lotes) |
| Determinismo y robustez | M6-21, M6-23, M6-24 | Baja | H0 |
| Táctica inerte | F-01 | Alta | H0 |
| Gala 3D y calidad | F-04 | Decisión del dueño | H0 |
| Pruebas desfasadas | F-05 | Baja (rojo permanente) | H0 |
| Ruido del registro | L-02, L-03, L-04 | Baja | H0 |
| Recursos de importación | R5-01, R5-02, R5-03 | Baja | H0 |
| Herramienta en clon superficial | E-04 | Proceso | H0 |
| La Ruta, equilibrio y coherencia | R-04, R-05, R-06, R-07, R-09 | Media | H0 |
| La Ruta, economía de puntos | R-08 | Media (decisión de diseño) | H3 |
| La Ruta, bajos | R-10 a R-14 | Baja | H3 |
| Gestión, bajos | G-05 a G-08 | Baja | H3 |
| Menús | M-01 | Baja | H3 |
| Ciudad 3D (apagada) | nº 2 y nº 5 de «FALLOS DETECTADOS» | Alta / baja | fuera de 1.0 |
| Partido simulado | Recalibrar remates: 10 por partido y 27 % de conversión frente a ~25 y ~11 % reales; goleadas de hasta 15-0 entre divisiones [D: `PLAN_GENERAL.md` §0, 4-11]; el dueño lo aprobó el 4-11 (orden 32), estado sin verificar en este informe | — | H1 |

Recuento: capítulo 5, 13 identificadores del proyecto (F-01 a F-05, L-01 a L-04, R5-01 a R5-03, E-04); capítulo 6, 26; capítulo 7, 25. Total 64, de los que 20 cerrados (16 + F-02, L-01, L-04 y F-04), 1 en curso (F-01) y 43 pendientes (incluidos los duplicados M6-12/M-02/F-03, que son un solo defecto) [M: recuento de las tablas].

---

## 9.3 Los hitos

### H0 · «Sano y medido» — 3-4 semanas [E]

**Objetivo.** Que el proyecto pase sus propias pruebas, que el proceso detecte las clases de fallo que se le escaparon y que exista la primera serie de mediciones del teléfono.

**Contenido.**
1. Fallos: F-01 (la contrapresión debe añadir un segundo presionador con presión media o alta, cap. 5), M6-10, M6-13, M6-21, M6-23, M6-24, R-04 a R-07, R-09, L-02 a L-04, R5-01 a R5-03; terminar F-02 y L-01; partir `motor_jugable_p5.gd` y `calidad.gd` con `partir_gd.py` (recompilando si se toca la gemela).
2. Oráculos: actualizar las cuatro pruebas de F-05 para que lean `Calidad.escala_ultra` y fijen `modo_rendimiento`; decisión del dueño sobre F-04 (excepción explícita o gala limitada en MEDIA y móvil) y modo rápido de la prueba de la gala.
3. Proceso (cap. 5 §5.7; cap. 6 §6.8; cap. 7 §7.7):
   - el banco falla ante `ERROR:` con pila de `res://` fuera de una lista blanca;
   - la cuenta de líneas entra en el criterio de subida (`comprobar_scripts.gd`) y `revisar_lineas.py --nuevos` cae a `--todos` sin base común;
   - prueba de **frontera de mitad** (mismo motor dos mitades y prórroga; ningún `*_hasta` más de 10 s en el futuro al empezar una parte);
   - prueba de **entrada a 30 y 120 FPS** simulados en el estadio;
   - utilidad de banco `ida_y_vuelta(m)` por `JSON.stringify`/`JSON.parse` en todas las pruebas de guardado;
   - prueba de una semana de La Ruta por la interfaz y de una temporada hasta el arranque de la siguiente;
   - pruebas negativas para cada premio comparativo.
4. Medición: primera campaña con el protocolo del capítulo 4 (§4.9) en el teléfono y la laptop, incluida la latencia de extremo a extremo; `probar_nativo` en un Windows real y en el teléfono [D: `PASO_CPP_PLAN.md` §2j].
5. Perfilado: compilar una versión con `profiler=tracy` [R 50][R 51][R 54] para separar CPU y presentación en el suelo de ~10 ms (cap. 4 §4.4.3). Top 15.

**Criterios de aceptación.**

| # | Criterio | Instrumento | Valor exigido |
|---|---|---|---|
| A0.1 | Banco | `banco.sh` | «FIN. 0 fallos», incluido el nuevo control de `ERROR:` |
| A0.2 | Especiales | `especiales.sh` en copia aislada (`git worktree`) | 0 FALLO del proyecto |
| A0.3 | Norma de líneas | `revisar_lineas.py --todos` | «pasan de 450 líneas: 0» |
| A0.4 | Igualdad nativa | `probar_nativo.tscn` en Linux, Windows real y Android | «FIN. 0 fallos» en los tres |
| A0.5 | Pruebas nuevas | frontera de mitad, entrada 30/120, ida y vuelta JSON, semana por la interfaz, premios negativos | existen y habrían fallado antes de los arreglos del 16-11 (comprobado revirtiendo en una rama) |
| A0.6 | Teléfono | prueba integrada larga, protocolo §4.9 | informe guardado con FPS medio, percentil 1 y `caida_pct` en MÍNIMA y BAJA, 3 clubes de 3 países |
| A0.7 | Latencia | cámara a 240 imágenes/s, §4.9.3 | medida y registrada (sin umbral en H0) |
| A0.8 | Revisión independiente | otra sesión revisa los 16 arreglos del 16-11 | informe breve con veredicto por arreglo |

### H1 · «Se juega bien» — 6-8 semanas [E]

**Objetivo.** Que el partido de C4 tenga una sensación de control medible y aprobada por personas, con la física y el reglamento coherentes.

**Contenido.**
1. Física: unificar la ley de rodadura de C4 (M6-06; gancho en la capa 1 sobrescrito en `MotorLeague`) y llevar el clima al balón suelto (M6-07); recalibrar con las sondas.
2. Perfil de manejo (tareas 1-9): escena que reproduce entradas grabadas y vuelca latencia, aceleración, radio de giro, coste del giro con balón, error angular del pase, ventana del tiro y primer toque.
3. Animación (tareas 11-15): *warping* de giros y llegadas [F 37], IK de pie al balón y cabeza al balón con `TwoBoneIK3D` y `LookAtModifier3D` (deterministas, compatibles con las huellas) [F 44][R 21], top 1; experimento de *motion matching* en la arena de pruebas [R 22], top 24; portero compuesto con clips de CMU [R 16], top 11.
4. IA: banco «fútbol plausible» (tarea 21) con bandas y xG/PPDA propios [F 45][F 47], calibrado con el conjunto de Pappalardo y otros (CC BY 4.0) [R 62] y SkillCorner (MIT) [R 65]; tops 3 y 20. No usar StatsBomb [F 50].
5. Reglamento: M6-14 a M6-20, M6-22, M6-25, M6-26 por lotes; recalibrar el partido simulado (remates y goleadas).
6. Producto: decisión del dueño sobre dos ajustes de partido, «Auténtico» y «Rápido» (cap. 2, I3 [F 15][F 16]).

**Métricas y criterios de aceptación.**

| # | Métrica | Umbral | Fuente del umbral |
|---|---|---|---|
| A1.1 | Latencia de extremo a extremo, mediana / percentil 90 (laptop con mando; teléfono táctil) | ≤ 100 ms / ≤ 140 ms | [F 33][F 35]; cap. 2, I1 |
| A1.2 | Pase manual raso de 12 m | el balón se detiene a 12 ± 1,5 m | coherencia interna (M6-06) [E] |
| A1.3 | Goles por partido (C4 CPU contra CPU, 50 partidos, 10 clubes de 5 países) | dentro de 2,5-3,3, como **alarma**, no objetivo | [F 48][F 49]; cap. 2, I8 |
| A1.4 | Tiros por partido; proporción dentro del área | 22-28; ≥ 60 % | [F 49]; cap. 2, I8 |
| A1.5 | Conversión real frente a xG propio | diferencia ≤ 25 % relativa | [F 45]; criterio [E] |
| A1.6 | PPDA con «presión alta» frente a «bloque bajo» | significativamente menor con presión alta | [F 47]; F-01 |
| A1.7 | Partido simulado: conversión de remate | 9-15 % (hoy 27 %) | [F 49]: 11,9 % en la Premier League 2023-24 |
| A1.8 | Nota del dueño al partido | ≥ 65/100 | resumen ejecutivo §10 |
| A1.9 | Prueba ciega con 5-10 personas externas (selector A/B/C) | media ≥ 60/100 y C4 preferido o empatado | resumen ejecutivo §10, tarea 10 |
| A1.10 | FPS (puerta de no regresión, laptop) | ULTRA ≥ 38, ULTRA BAJA ≥ 95 | resumen ejecutivo §6.4 |

Los criterios A1.3-A1.7 son detectores: si el partido se sale de la banda y aun así el dueño y los probadores lo prefieren, se documenta la decisión y se acepta (orden 38).

### H2 · «Se ve y se oye como TV» — 4-6 semanas [E]

**Objetivo.** Que, con la cámara real, el partido se lea como una retransmisión: director de cámara, paquete gráfico, grada viva, luz por hora y un primer comentario.

**Contenido y recursos.**

| Tarea | Recurso (top n del cap. 11) | Licencia |
|---|---|---|
| Director de cámara por estados: juego, evento, reacción, repetición (tareas 26-31) | Phantom Camera [R 53] (top 4); LimboAI [R 24] (top 23) | MIT |
| Grada por capas y reacciones (tarea 46) | Grabaciones de estadio de felix.blume y Vogyik [R 28][R 29] (top 2) | CC0 |
| Balón, red, poste, silbato (tarea 48) | Freesound CC0 y Kenney Impact Sounds [R 5][R 9] (top 14) | CC0 |
| Luz por hora y cielo (tarea 42) | HDRI de Poly Haven [R 3] (top 6); Sky3D [R 47] (top 25) | CC0; MIT |
| Paquete gráfico y dorsales (tareas 29, 36) | Big Shoulders Display, Teko, Saira Condensed [R 36] (top 8) | OFL |
| Tela, red, césped (tareas 36, 43) | `cotton_jersey` (hecho), ambientCG `Net*` y `Grass*` [R 4] (tops 7, 13, 17) | CC0 |
| Público en el plano de reacción (tarea 27) | Quaternius «Background Posed Humans» [R 10] (top 12); público 2D del proyecto | CC0 |
| Comentario, fase 1 (tareas 49-50) | Kokoro-82M con voces en español, audios pregenerados fuera del juego [R 30] (top 5); Chatterbox como alternativa [R 34] (top 18) | Apache 2.0; MIT |

**Criterios de aceptación.**

| # | Criterio | Instrumento | Valor |
|---|---|---|---|
| A2.1 | Planos de reacción en falta grave, roja, gol, ocasión y penal | prueba de escena con eventos forzados | 5 de 5 tipos con plano de 2-3 s |
| A2.2 | Repetición con 2 ángulos y contexto (marcador, minuto, nombre) | captura con la cámara real | en todo gol |
| A2.3 | Vídeo de un partido de 3 clubes de 3 países | veredicto del dueño | «se confunde a primera vista con un juego comercial» (resumen ejecutivo §10) |
| A2.4 | Comentario | partido completo | ninguna frase repetida en el mismo partido (resumen ejecutivo §6.6) |
| A2.5 | Licencias | `LICENCIAS.md` | 100 % de los recursos nuevos con la plantilla del cap. 11 §11.8; sin amarillos de sonido |
| A2.6 | Rendimiento | protocolo §4.9 | puerta de la laptop y, si existe, la del teléfono |

### H3 · «Se entiende y engancha» — 4-6 semanas [E]

**Objetivo.** Que un jugador nuevo entienda los menús, que La Ruta y la gestión se sostengan varias temporadas y que la gestión se note en la cancha.

**Contenido.**
1. Menús (Frente 1; tareas 53-60): menú central de 4-5 destinos con tarea del día, mosaico de tarjetas como el de la Liga Master, transiciones únicas; iconos Tabler (MIT) [R 43] (top 10) y game-icons.net (CC BY 3.0) para La Ruta (top 16).
2. La Ruta: economía de puntos (R-08; decisión del dueño), R-10 a R-14, legibilidad (dos monedas de puntos con nombres parecidos, tres sistemas de botas, dos caminos al brazalete; cap. 7 §7.6.7); acumulador de media de temporada para premios (cierre de R-03).
3. Gestión: G-05 a G-08, M-01; que la moral, el estadio lleno o vacío y la prensa cambien el partido y la narración (tareas 61-64).
4. Prueba de juego guiada de tres temporadas con cuestionario de comprensión (cap. 7 §7.6.7).

**Criterios de aceptación.**

| # | Criterio | Instrumento | Valor | Fuente |
|---|---|---|---|---|
| A3.1 | Tres tareas sin ayuda («jugar el próximo partido», «fichar», «cambiar la táctica») | 3 personas, cronómetro | < 30 s cada una | resumen ejecutivo §7 |
| A3.2 | Apertura de una pantalla | medición en la laptop | < 150 ms | resumen ejecutivo §7 |
| A3.3 | Sesión de juego media | probadores | ≥ 45 min | resumen ejecutivo §10 |
| A3.4 | Economía de La Ruta | `sonda_ruta` en 3 clubes de 3 países | coste de +1 de zona independiente del número de sub-habilidades; portero y delantero dentro de ±20 % [E] | cap. 7 R-08 |
| A3.5 | Comprensión de La Ruta | cuestionario tras tres temporadas | ≥ 80 % de respuestas correctas sobre monedas, brazalete y retos [E] | cap. 7 §7.6.7 |
| A3.6 | Larga duración | crear un futbolista de 34 años y cerrar cuatro temporadas; 22 temporadas simuladas del mundo | sin pérdida de la carrera ni del guardado | cap. 7 §7.7 |

### H4 · «1.0 cerrada» — 3-4 semanas [E]

**Objetivo.** Producto publicable dentro del alcance aprobado.

**Contenido.** Alcance 1.0 por escrito (tarea 84; propuesta del resumen ejecutivo: club, partido, La Ruta y cinco ligas completas pulidas, con el resto detrás de banderas); editor e importación JSON documentados para modding (tareas 77-78, con revisión jurídica de la responsabilidad del contenido importado, cap. 2 §2.8.4); política de privacidad publicada antes de cualquier telemetría (tarea 90); comentario de fase 2; caza de fallos; builds de Windows y Android; página de tienda («sin pagos, sin cartas, corre en tu equipo»).

**Criterios de aceptación.**

| # | Criterio | Valor |
|---|---|---|
| A4.1 | Fallos conocidos de gravedad crítica o alta | 0 |
| A4.2 | Nota media de los probadores (10-30 personas) | ≥ 75/100 (resumen ejecutivo §10) |
| A4.3 | Ciudad 3D | fuera del build 1.0 y de las especiales rápidas |
| A4.4 | Registro de licencias | revisión profesional antes de vender (cap. 11 §11.9) |
| A4.5 | Puertas de rendimiento | laptop y teléfono, con el protocolo del cap. 4 |

---

## 9.4 Tablero de métricas

| Métrica | Hoy | Meta 1.0 | Instrumento | Estado de la medición |
|---|---|---|---|---|
| Banco | «FIN. 0 fallos» [D] | igual | `banco.sh` | sí |
| Especiales del proyecto en FALLO | 8 (antes de los arreglos del 16-11) [D: cap. 5] | 0 | `especiales.sh` | repetir tras los arreglos |
| Scripts > 450 líneas | 2 [M] | 0 | `revisar_lineas.py` | sí |
| Scripts de 445-450 líneas | 68 [M] | tendencia a la baja | `wc -l` | sí |
| Fallos conocidos críticos/altos pendientes | F-01 + decisión F-04 | 0 | tablas de §9.2 | sí |
| ULTRA / ULTRA BAJA en la laptop | ~39-41 / ~100-107 FPS [D] | ≥ 38 / ≥ 95 | `perfilar_gpu` | sí |
| Partido en MÍNIMA en el teléfono | 30 FPS (~4-11) [D] | 60 (orden 22) | prueba integrada | **no desde ~4-11** |
| Latencia de extremo a extremo | sin medir | mediana ≤ 100 ms, p90 ≤ 140 ms | cámara 240 imágenes/s | **no** |
| Goles por partido C4 (mitades de 240 s, piloto automático) | ~4,4 [D] | banda 2,5-3,3 como alarma | `comparar_tres_motores` | sí, con otra duración |
| Conversión de remate, partido simulado | 27 % [D] | 9-15 % | banco `partido_porteros` | sí |
| Cadenas de 5+ pases por partido (C4) | ~3,5 [D] | tendencia al alza (sin umbral con fuente) | `medidor_diversion` | sí |
| Nota del dueño al partido | «muy mala» (3-11) [D] | ≥ 65/100 | formulario | sin nota sobre C4 |
| Probadores externos | 0 [D] | 10-30 | formulario | **no** |
| Recursos con licencia anotada | parcial | 100 % | `LICENCIAS.md` | sí |

---

## 9.5 Decisiones del dueño que condicionan el plan

| # | Decisión | Afecta a | Propuesta del informe |
|---|---|---|---|
| 1 | Alcance de 1.0 y cuáles cinco ligas | H3, H4; riesgos 1, 7, 8 del cap. 3 | Aprobar el recorte del resumen ejecutivo §9.1 |
| 2 | Congelar el motor C4 ocho semanas (solo banderas) | H1 | Sí: el motor cambió tres veces en tres semanas |
| 3 | F-04: calidad forzada de la gala 3D | H0 | Limitar la «calidad máxima» a ALTA/ULTRA; en móvil y por debajo de MEDIA, escala 1,0 y MSAA 2x |
| 4 | R-08: economía de puntos de La Ruta | H3 | Coste por punto de zona, no de sub-habilidad |
| 5 | Dos ajustes de partido, «Auténtico» y «Rápido» | H1 | Probar en la prueba ciega antes de decidir |
| 6 | Probadores externos | H1-H4 | 5-10 en H1, 10-30 en H4 |
| 7 | Voluntarios para la voz o solo síntesis | H2 | Síntesis pregenerada en H2; voluntarios con cesión firmada si aparecen |
| 8 | Tiempo para la campaña de medición del teléfono | H0 | 30-40 min con la guía existente |

Las decisiones 3 y 4 cumplen la regla de la orden 44 (preguntas que se acumulan y se envían juntas); con las del resumen ejecutivo suman más de cinco.

---

## 9.6 Calendario y ruta crítica

| Hito | Duración [E] | Depende de | Ruta crítica |
|---|---|---|---|
| H0 | 3-4 semanas | decisión 3; tiempo del dueño para el teléfono | medición del teléfono |
| H1 | 6-8 semanas | H0; decisiones 2 y 5; probadores | prueba ciega con personas externas |
| H2 | 4-6 semanas | H0; puede solaparse con el final de H1 | director de cámara |
| H3 | 4-6 semanas | H0; decisión 4 | prueba de comprensión |
| H4 | 3-4 semanas | H1-H3; decisión 1 | alcance aprobado |
| **Total** | **20-28 semanas** | | |

Con dos líneas de trabajo en paralelo (partido; visual y menús), máximo recomendado por el resumen ejecutivo, H2 puede solaparse con H1 y H3 con H2, lo que acercaría el total a 16-20 semanas [E]. La ruta crítica no es técnica: son la medición del teléfono, los probadores y las decisiones del dueño.

---

## 9.7 Riesgos del plan

| Riesgo | Probabilidad [E] | Impacto | Mitigación |
|---|---|---|---|
| El partido no llega a «divertido» con C4 | Media | Fatal | Perfil de manejo y prueba ciega desde H1; el comparador A/B/C permite volver atrás |
| El teléfono queda lejos de 60 FPS | Alta | Alto | Medir en H0; palancas de relleno de píxeles ya identificadas (cap. 4 §4.5.1) |
| Los arreglos del 16-11 introducen regresiones | Media | Medio | Especiales en copia aislada y revisión independiente (A0.2, A0.8) |
| Recalibrar el simulado cambia la huella del mundo | Alta | Medio | Nueva huella de referencia aprobada; banco `partido_porteros` |
| Licencias mal anotadas | Baja | Alto | A2.5 y A4.4 |
| Desgaste del dueño | Media | Alto | Bloques cortos, builds semanales, preguntas agrupadas |

---

## 9.8 Conclusiones

1. Se arreglaron 16 de 64 defectos registrados: los dos de gravedad crítica y diez de los once de gravedad alta (R-03 solo mitigado). Queda abierto el alto F-01 (táctica inerte) y pendiente la decisión del dueño sobre F-04.
2. El plan añade un hito H0 de saneamiento y medición, porque el proceso dejó pasar fallos en las fronteras y porque el teléfono no se mide desde el ~4-11.
3. Cada hito tiene criterios de aceptación verificables; los umbrales de latencia y de fútbol real tienen fuente externa, y los de FPS y notas son decisiones del dueño.
4. Los recursos del capítulo 11 cubren casi todo H2 sin coste; la animación de fútbol sigue siendo el hueco que solo se cierra con técnica (IK, *warping*, *motion matching*).
5. La duración estimada es de 20 a 28 semanas en serie y de 16 a 20 con dos líneas de trabajo [E]; la ruta crítica la marcan la medición del teléfono, los probadores externos y ocho decisiones del dueño.
