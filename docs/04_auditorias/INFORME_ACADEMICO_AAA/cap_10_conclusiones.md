# Capítulo 10. Conclusiones, recomendaciones y bibliografía unificada

Informe académico AAA de Dinastía · Redacción: 16-11-2026.
Convenciones: [M] medido · [D] documento del proyecto · [F n] fuente externa (numeración unificada de §10.7: [F 1]-[F 68] del capítulo 2; [F 69]-[F 137] = [R 1]-[R 69] del capítulo 11) · [E] estimación.

---

## Resumen

Este capítulo responde a las cinco preguntas de investigación, formula diez recomendaciones priorizadas —cinco principales—, resume las lecciones de método, propone trabajo futuro y reúne la bibliografía de los capítulos 2 y 11 con su numeración original. La respuesta corta es que el nivel AAA en sentido literal no es alcanzable ni necesario; que Dinastía está a unos cuatro puntos de los referentes en el partido y por delante en su propio terreno; que sus fallos graves están en las fronteras que las pruebas no recorrían, y dieciséis ya se arreglaron; que superar a PES 2020 exige un partido de 7 en ocho áreas y superar a FC 27 solo es realista en el terreno propio; y que los recursos públicos cubren casi toda la presentación, pero no la animación de fútbol, que debe resolverse con técnica.

---

## 10.1 Respuestas a las preguntas de investigación

### RQ1. ¿Qué es «AAA» y qué parte es aplicable a Dinastía?

«AAA» es una categoría de producción, no una propiedad del producto: presupuestos del orden de cientos de millones de dólares (unos 315 millones para un título de Insomniac, según una filtración [F 54]) y campus de miles de personas (unas 2.400 en EA Vancouver [F 55]). De los ocho rasgos que el resumen ejecutivo asocia a lo AAA, cuatro dependen de dinero (captura de movimiento propia, licencias, fotogrametría, control de calidad masivo) y cuatro de criterio y horas (sensación de control, presentación televisiva, estabilidad y pulido, recorte de alcance) [D: `INFORME_AAA_2026-11-16.md` §1]. El capítulo 2 confirma que esa división es la pertinente con tres evidencias: la crítica premia el partido y castiga el entorno —interfaz, IA de compañeros, comentario, monetización— y nunca señaló la falta de licencias como crítica principal [F 4][F 16][F 19][F 20]; los éxitos pequeños recientes del género eligieron un terreno distinto del de FC [F 58][F 59][F 61]; y los grandes fracasos recientes vienen de interfaces nuevas no probadas o de lanzamientos inmaduros [F 8][F 56][F 57]. **Lo aplicable a Dinastía es la calidad percibida en sensación, presentación y estabilidad, más la profundidad de su terreno propio; no lo es la escala de contenido licenciado ni la captura de movimiento.**

### RQ2. ¿Dónde está Dinastía?

**En código**, es un proyecto grande para su equipo: 338.521 líneas de GDScript propio (224.495 de juego y 112.101 de pruebas) y 3.052 de C++ con 39 métodos nativos y gemelas byte a byte [M: cap. 3]. La norma de 450 líneas se cumple casi siempre, pero ha producido 265 capas por herencia y un acantilado de 68 scripts a cinco líneas o menos del límite [M]. **En contenido**, genera 2.206 clubes en 147 ligas de 135 países, 55.150 jugadores y 135 selecciones [M], más que lo declarado por FC 27 [F 17], con una fidelidad mucho menor. **En rendimiento**, la laptop del dueño da ~39-41 FPS en ULTRA y ~100-107 en ULTRA BAJA, con un suelo de unos 10 ms de CPU y presentación que no depende del contenido [D: cap. 4]; el teléfono no se mide desde el ~4-11 (30 FPS en MÍNIMA) y la latencia de extremo a extremo nunca se ha medido. **En calidad percibida**, la matriz del capítulo 8 da 4,4 sobre 10 con la ponderación del proyecto, frente a 7,2 de PES 2020 y 7,1 de FC 27; en las ocho áreas del partido, 3,8 frente a 7,5 y 7,8; en las seis del terreno propio, 6,8 frente a 6,2 y 5,3 [E]. Las conclusiones resisten la incertidumbre de las notas.

### RQ3. ¿Qué fallos tiene?

Los capítulos 5 a 7 registran **64 defectos** del proyecto: 13 de la ejecución de pruebas, 26 del motor del partido y 25 de gestión, La Ruta y menús. Ninguno cuelga el juego en el camino normal; los graves comparten un patrón: **están en las fronteras que las pruebas no recorren**. En el motor, el reloj de la mitad vuelve a cero frente a 31 plazos absolutos (M6-02, M6-03, M6-08, M6-09), la entrada se leía dentro del paso fijo y fallaba a 30 y a 120 FPS (M6-01), el fuera de juego no se pitaba en remates de primera (M6-04) y el balón de C4 tiene dos leyes de rozamiento: un pase de 12 m se queda en unos 8 (M6-06). En La Ruta, el mundo podía retirar al futbolista del jugador (R-01) y cada carga borraba la temporada por un tipo de número del JSON (G-01). En el proceso, el banco terminaba en verde con ocho fallos reproducibles en las especiales, sin vigilar los errores del registro ni la norma de líneas (cap. 5). **Al 16-11 se arreglaron 16 defectos, incluidos los dos críticos y diez de los once altos**; quedan 46, entre ellos la táctica inerte (F-01), la física del balón de C4 (M6-06, M6-07) y la economía de puntos de La Ruta (R-08) (cap. 9, §9.2).

### RQ4. ¿Cómo superar a PES 2020 y a FC 27?

Con la ponderación del propio proyecto, **superar a PES 2020 en conjunto exige llevar las ocho áreas del partido a una media de 7**, con los menús en 8 y el resto en 6,5 [E: cap. 8 §8.9]; subir solo el control no basta. **Superar a FC 27 en conjunto no es realista** en caras, contenido licenciado, presentación ni juego en línea; sí lo es **superarlo en el terreno propio** (gestión, modo jugador, sin pago aleatorio, modding, accesibilidad, equipos modestos) sin perder por goleada en el partido, donde ya va por delante sobre el papel. El camino es el plan del capítulo 9: un hito de saneamiento y medición (H0) y cuatro hitos con criterios de aceptación verificables («se juega bien», «se ve y se oye como TV», «se entiende y engancha», «1.0 cerrada»), de 20 a 28 semanas en serie o 16 a 20 con dos líneas de trabajo [E]. El criterio del dueño —diversión por encima del realismo— solo puede verificarse con la prueba ciega que ya existe en el juego y con probadores externos, que hoy son cero.

### RQ5. ¿Qué recursos públicos lo hacen posible?

El capítulo 11 revisó unos 120 recursos y propone un paquete de 25 con riesgo legal bajo [D: cap. 11 §11.7]. Cubren casi toda la presentación: grada con grabaciones reales de estadios en CC0 [F 96][F 97], cámara por estados (Phantom Camera, MIT) [F 121], luz y cielo con HDRI de estadios en CC0 [F 71], tela de punto en CC0 (ya integrada el 16-11), tipografías OFL para dorsales [F 104], iconos MIT [F 111], perfiladores [F 122][F 123] y voces sintéticas en español con licencias permisivas, a condición de generar los audios fuera del juego por la dependencia GPL de los fonemas [F 98][F 102]. Para la IA hay datos legales: el conjunto de Pappalardo y otros (CC BY 4.0) [F 130] y SkillCorner (MIT) [F 133], frente a StatsBomb, que prohíbe el uso comercial [F 50]. **Lo que no existe gratis con licencia limpia** son las animaciones de fútbol y de portero, las caras fotorrealistas sin derecho de imagen ajeno y una voz de comentarista natural: la animación debe resolverse con técnica —IK nativo de Godot 4.6+ [F 44], *warping* [F 37], *motion matching* clásico [F 38][F 41]— y no con contenido.

---

## 10.2 Recomendaciones priorizadas

Las cinco primeras son las principales; el orden refleja dependencia (lo que desbloquea a lo demás va antes) y relación entre impacto y coste.

| # | Recomendación | Brecha o fallo que ataca | Evidencia | Hito |
|---|---|---|---|---|
| **1** | **Medir antes de decidir**: campaña en el teléfono y la laptop con el protocolo del cap. 4 (tres clubes de tres países, cinco repeticiones, percentil 1, caída por calor), primera medición de la latencia de extremo a extremo con una cámara a 240 imágenes/s, y `probar_nativo` en Windows real y Android | Brecha de medición; área 13; riesgo de libm | Cap. 4 §4.6-4.9; [F 33][F 35]; `PASO_CPP_PLAN.md` §2j | H0 |
| **2** | **Sanear antes de pulir**: cerrar F-01, M6-10, M6-13, R-04 a R-07, R-09 y terminar F-02 y L-01; especiales en verde en una copia aislada; banco que falle ante `ERROR:`; norma de líneas en el criterio de subida; pruebas de frontera (mitad, entrada a 30 y 120 FPS, ida y vuelta JSON, semana por la interfaz, premios negativos); revisión independiente de los 16 arreglos | Brecha de corrección en las fronteras; área 18 | Cap. 5 §5.7; cap. 6 §6.8; cap. 7 §7.7 | H0 |
| **3** | **Hacer de la sensación de control el producto**: unificar la física del balón de C4 (M6-06, M6-07); perfil de manejo medible; *warping*, IK de pie y cabeza al balón; congelar el motor C4 ocho semanas; prueba ciega A/B/C con 5-10 personas externas | Brecha de sensación; áreas 1-4 | Cap. 2 §2.5-2.6; [F 30][F 37][F 44]; cap. 6 §6.7.3 | H1 |
| **4** | **Presentación y sonido con el paquete gratuito**: director de cámara por estados, planos de reacción, repeticiones con contexto, grada real CC0, luz por hora y primer comentario pregenerado | Áreas 6-8; la mejor relación impacto/hora según el resumen ejecutivo | Cap. 11 §11.7 (tops 2, 4, 5, 6, 8, 14, 23, 25); [F 4][F 6] | H2 |
| **5** | **Recortar el alcance de 1.0 y competir en el terreno propio**: club, partido, La Ruta y cinco ligas pulidas; ciudad 3D fuera del build; no competir en licencias, captura de movimiento ni juego en línea; decirlo en la tienda («sin pagos, sin cartas, corre en tu equipo») | Riesgos 1, 7 y 8 del cap. 3; áreas 10-17 | Cap. 2 §2.8, I13, I14, I16; [F 27][F 56][F 59] | H4 (decisión ya) |
| 6 | Cerrar la economía y la legibilidad de La Ruta (R-08, dos monedas con nombres parecidos, tres sistemas de botas, dos caminos al brazalete) y probarla con un cuestionario tras tres temporadas | Área 11 | Cap. 7 §7.6 | H3 |
| 7 | Calibrar la IA con bandas de fútbol real y datos con licencia comercial; xG y PPDA propios; recalibrar el partido simulado (conversión del 27 % frente al ~12 % real) | Área 2 | [F 45][F 47][F 48][F 49][F 130]; `PLAN_GENERAL.md` §0 | H1 |
| 8 | Probar cualquier rediseño de menús con personas antes de sustituir el anterior, que se conserva detrás de una opción | Área 9; mayor riesgo de producción documentado | [F 56][F 57]; cap. 2, I12 | H3 |
| 9 | Convertir el registro de licencias en una prueba (plantilla del cap. 11) y pedir revisión jurídica antes de vender | Riesgo legal | Cap. 11 §11.8-11.9 | H2-H4 |
| 10 | Reducir deuda solo donde ya hubo fallos: reloj monótono para plazos, modelo físico del balón como pieza de C4, retirar banderas descartadas, separar el histórico de `PLAN_GENERAL.md` | Riesgos 2-4, 7 y 11 del cap. 3 | Cap. 3 §3.10; cap. 6 §6.7 | H0-H1 |

---

## 10.3 Lecciones de método

1. **Un banco en verde no basta.** Dos decisiones legítimas de rendimiento y dos incumplimientos de la norma de líneas entraron con el banco en verde y dejaron las especiales en rojo (cap. 5). El criterio de subida debe incluir lo que el proyecto dice que vigila.
2. **Las pruebas deben recorrer las fronteras.** Diccionarios en memoria en lugar de ida y vuelta por disco, orden de llamadas distinto del de la interfaz, partidos de piloto automático que no cruzan el descanso con el mismo motor: tres hábitos que explican la mayoría de los fallos graves (cap. 6 §6.7.1; cap. 7 §7.7).
3. **La igualdad entre gemelas no es corrección.** Las gemelas C++ reproducen también los fallos (M6-03 estaba en ambos lenguajes) [D: cap. 6 §6.7.5].
4. **Una cifra sin fecha y sin fuente envejece mal.** Los documentos del proyecto daban 1.069, 1.541 y 2.208 clubes para el mismo mundo (cap. 3 §3.5.2). Las cifras deben salir de herramientas reproducibles y citarse con fecha.
5. **El marketing no es evidencia.** Las afirmaciones del editor sobre su tecnología se trataron como evidencia débil (cap. 8 §8.2.3), y eso cambió dos notas de FC 27.
6. **Sin personas no hay nota fiable.** Ningún área de la matriz alcanzará confianza alta sin probadores externos (cap. 8 §8.6.2).

---

## 10.4 Trabajo futuro

1. **Validación con jugadores**: prueba ciega A/B/C del partido con 5-10 personas y cuestionario de comprensión de La Ruta; después, 10-30 probadores con nota 1-100 cada dos semanas (resumen ejecutivo §9).
2. **Juego directo de los referentes**: capturas o vídeos de PES 2020 y FC 27 en el Drive del dueño (`referencias_del_dueño`) y una sesión de juego comparada con un protocolo de observación, para sustituir las notas de confianza C de la matriz.
3. **Estudio de latencia propio**: repetir con mando y pantalla táctil los experimentos de detección [F 33][F 34] sobre el partido de Dinastía, para fijar umbrales específicos del género.
4. **Perfilado del suelo de 10 ms** con Tracy o Perfetto [F 118][F 119][F 122] para separar CPU del motor gráfico y presentación.
5. **Motion matching clásico** sobre los clips de League-Soccer y CMU en la arena de pruebas, con medición de su coste en el teléfono [F 41][F 90].
6. **Datos de fútbol de más ligas**: bandas de varias temporadas y ligas con el conjunto CC BY de Wyscout [F 130], que cubre siete competiciones, para superar la limitación de una sola liga del capítulo 2 (§2.12, punto 5).
7. **Revisión jurídica** de licencias, modding y derecho de imagen antes de vender.
8. **Segunda auditoría estática** sobre lo que este informe no cubrió: interfaz de gestión más allá de lo muestreado, estadio y club 3D, minijuegos, exportación y plataformas.

---

## 10.5 Limitaciones globales

Las limitaciones de cada capítulo se recogen en sus secciones propias (cap. 1 §1.8; cap. 2 §2.12; cap. 4 §4.10; cap. 5 §5.6; cap. 8 §8.10; cap. 11 §11.9). Tres afectan a todo el informe: ningún juego se jugó para redactarlo; las mediciones en hardware real proceden de un solo portátil y de una sola prueba en el teléfono; y quien audita forma parte del mismo proceso que escribió y arregló el código, lo que exige una revisión independiente de los arreglos.

---

## 10.6 Cierre

Dinastía no será un AAA, y no necesita serlo. Lo que el material de este informe sostiene es una tesis más modesta y más útil: un juego de fútbol con un partido «suficientemente bueno y divertido», una gestión y un modo jugador que ningún referente ofrece con esa profundidad, sin pago aleatorio y capaz de correr en equipos modestos, puede competir con ventaja en su terreno. Para llegar ahí, el orden importa: medir, sanear, hacer que el partido se sienta bien, hacer que se vea y se oiga como una retransmisión, y cerrar un alcance que se pueda terminar.

---

## 10.7 Bibliografía unificada

Todas las fuentes se consultaron el 16-11-2026. Nivel: **L** = leída en la fuente primaria o en un agregador que reproduce el dato; **E** = verificada por extracto del buscador o fuente secundaria. Se conservan las descripciones de los capítulos de origen. Las fuentes del capítulo 11 llevan su número original [R n] junto al unificado [F 68+n]; en ellas, «[cap. 2, n]» remite a [F n].

### 10.7.1 Fuentes del capítulo 2 (numeración original [F 1]-[F 68])

[F 1] Wikipedia. «eFootball PES 2020». https://en.wikipedia.org/wiki/EFootball_PES_2020 — L.

[F 2] OpenCritic. «eFootball PES 2020». https://opencritic.com/game/8187/efootball-pes-2020 — L.

[F 3] Konami Digital Entertainment. «eFootball PES 2020» (ficha oficial del producto). https://www.konami.com/games/eu/en/products/pes2020/ — L.

[F 4] Gorman, D. (13-09-2019). «PES 2020: Mastery on the pitch, but frustrating off it». *The Irish Times*. https://www.irishtimes.com/culture/games/game-reviews/pes-2020-mastery-on-the-pitch-but-frustrating-off-it-1.4017264 — L.

[F 5] GamesRadar+ (2019). «eFootball PES 2020 review: “A faithful replication of the beautiful game… the most realistic PES to date”». https://www.gamesradar.com/pes-2020-review/ — E (solo titular leído).

[F 6] Cubed3 (2019). «eFootball PES 2020» (reseña, Xbox One). https://www.cubed3.com/games/reviews/xbox-one/efootball-pes-2020 — E.

[F 7] GamesRadar+. «PES 2020 option file guide: How to get all the official kits and badges». https://www.gamesradar.com/pes-2020-option-file-official-kits-badges-names-guide — E.

[F 8] PC Gamer (2021). «Does eFootball deserve to be the worst reviewed game on Steam?». https://www.pcgamer.com/what-the-hell-is-going-on-with-efootball — E.

[F 9] Video Games Chronicle (2021). «Konami apologises for eFootball’s disastrous launch, promises improvements». https://www.videogameschronicle.com/news/konami-apologises-for-efootballs-disastrous-launch-promises-improvements — E.

[F 10] MP1st (18-07-2023). «EA Sports FC 24 Gameplay Deep Dive Details HyperMotionV, PlayStyles, and the Frostbite Engine». https://mp1st.com/news/ea-sports-fc-24-gameplay-deep-dive-details-hypermotionv-playstyles-and-the-frostbite-engine — L.

[F 11] Caleffi, T., Sabatino, K. y Thompson, B. (21-08-2024). «EA SPORTS FC 25 | FC IQ Deep Dive». Electronic Arts. https://www.ea.com/games/ea-sports-fc/fc-25/news/pitch-notes-fc-25-fc-iq-deep-dive — L.

[F 12] Electronic Arts (2024). «Pitch Notes: FC 25 Football Ultimate Team Deep Dive». https://www.ea.com/games/ea-sports-fc/fc-25/news/pitch-notes-fc-25-football-ultimate-team-deep-dive — E.

[F 13] OpenCritic. «EA Sports FC 25». https://opencritic.com/game/17121/ea-sports-fc-25 — L.

[F 14] GamesRadar+ (2024). «EA FC 25 review: “Highly playable, yet naggingly familiar”». https://gamesradar.com/games/ea-sports-fc/ea-sports-fc-25-review — E.

[F 15] Electronic Arts (22-07-2025). «Pitch Notes: FC 26 Gameplay Deep Dive». https://www.ea.com/games/ea-sports-fc/fc-26/news/pitch-notes-fc26-gameplay-deep-dive — E.

[F 16] OpenCritic. «EA Sports FC 26». https://opencritic.com/game/18960/ea-sports-fc-26 — L.

[F 17] Electronic Arts (23-07-2026). «Kylian Mbappé and Jude Bellingham Welcome You to EA SPORTS FC 27, Launching Worldwide on September 25» (nota de prensa). https://news.ea.com/press-releases/press-releases-details/2026/Kylian-Mbapp-and-Jude-Bellingham-Welcome-You-to-EA-SPORTS-FC-27-Launching-Worldwide-on-September-25/default.aspx — L.

[F 18] OpenCritic. «EA Sports FC 27». https://opencritic.com/game/21101/a — L.

[F 19] Kato, M. (25-09-2026). «EA Sports FC 27 Review: More Build Up Play Than The Long Ball». *Game Informer*. https://gameinformer.com/review/ea-sports-fc-27/more-build-up-play-than-the-long-ball — L.

[F 20] Perić, L. (26-09-2026). «EA Sports FC 27 Review: Better Football, Same Old Shop». *Stadion Gaming*. https://www.stadiongaming.eu/en/news/ea-sports-fc-27-review-better-football-same-old-shop — L.

[F 21] Electronic Arts Inc. (2025). *Form 10-K, fiscal year ended March 31, 2025*. U.S. Securities and Exchange Commission. https://www.sec.gov/Archives/edgar/data/712515/000071251525000022/ea-20250331.htm — E.

[F 22] Video Games Chronicle (29-01-2019). «EA stops selling FIFA loot boxes in Belgium». https://www.videogameschronicle.com/news/ea-stops-selling-fifa-loot-boxes-in-belgium-jan-29-2019/ — L.

[F 23] Xiao, L. Y. (2023). «Breaking Ban: Belgium’s Ineffective Gambling Law Regulation of Video Game Loot Boxes». *Collabra: Psychology*, 9(1). Ficha: https://pure.itu.dk/en/publications/breaking-ban-belgiums-ineffective-gambling-law-regulation-of-vide/ — E.

[F 24] Video Games Chronicle (10-03-2022). «Dutch court overrules decision to fine EA €10 million for FIFA loot boxes». https://videogameschronicle.com/news/dutch-court-overrules-decision-to-fine-ea-e10-million-for-fifa-loot-boxes — L.

[F 25] Gobierno del Reino Unido, DCMS (18-07-2022). «Government response to the call for evidence on loot boxes in video games». https://gov.uk/government/consultations/loot-boxes-in-video-games-call-for-evidence/outcome/government-response-to-the-call-for-evidence-on-loot-boxes-in-video-games — E.

[F 26] Gobierno de Australia, Department of Infrastructure (2023-2024). «New mandatory minimum classifications for gambling-like games content». https://infrastructure.gov.au/department/media/news/new-mandatory-minimum-classifications-gambling-games-content — E.

[F 27] Brasil, Ley 15.211/2025 (ECA Digital). Cobertura: *Jurist* (09-2025), «Brazil passes new law to protect children’s online privacy», https://www.jurist.org/news/2025/09/brazil-passes-new-law-to-protect-childrens-online-privacy/ ; Mattos Filho, «Brazil’s ECA Digital in practice: how the law affects different sectors», https://www.mattosfilho.com.br/en/unico/brazils-eca-digital/ — E.

[F 28] Zendle, D. y Cairns, P. (2018). «Video game loot boxes are linked to problem gambling: Results of a large-scale survey». *PLOS ONE*, 13(11): e0206767. https://eprints.whiterose.ac.uk/139116/1/journal.pone.0206767.pdf — E.

[F 29] Swink, S. (2008). *Game Feel: A Game Designer’s Guide to Virtual Sensation*. Morgan Kaufmann/CRC Press. ISBN 978-0123743282. Definición citada a través de [30] — E (libro no consultado directamente).

[F 30] Pichlmair, M. y Johansen, M. (2022). «Designing Game Feel: A Survey». *IEEE Transactions on Games*, 14(2). DOI 10.1109/TG.2021.3072241. Preprint: https://arxiv.org/abs/2011.09201 — E.

[F 31] Jonasson, M. y Purho, P. (2012). «Juice It or Lose It». GDC Europe, Independent Games Summit. https://gdcvault.com/play/1016789/Juice-It-or-Lose — E.

[F 32] Hicks, K., Gerling, K., Dickinson, P. y Vanden Abeele, V. (2019). «Juicy Game Design: Understanding the Impact of Visual Embellishments on Player Experience». *CHI PLAY 2019*, pp. 185-197. DOI 10.1145/3311350.3347171 — E.

[F 33] Raaen, K., Eg, R. y Griwodz, C. (2014). «Can gamers detect cloud delay?». *13th Annual Workshop on Network and Systems Support for Games (NetGames)*. DOI 10.1109/NetGames.2014.7008962. PDF: https://web-backend.simula.no/sites/default/files/publications/files/paper_5.pdf — L.

[F 34] Raaen, K. y Eg, R. (2016). «How to demonstrate delay? Let’s play!». *ACM MMSys 2016*. https://mmsys2016.itec.aau.at/papers/MMSYS/a28-westerdals.pdf — L.

[F 35] Eg, R., Raaen, K. y Claypool, M. (2018). «Playing with delay: With poor timing comes poor performance, and experience follows suit». *10th International Conference on Quality of Multimedia Experience (QoMEX)*. https://www.uni-marburg.de/en/irtg1901/study-program/seminars/eg-et-al-2018-2.pdf — L.

[F 36] Claypool, M. y Claypool, K. (2006). «Latency and Player Actions in Online Games». *Communications of the ACM*, 49(11). DOI 10.1145/1167838.1167860. Informe técnico: https://ftp.cs.wpi.edu/pub/techreports/pdf/06-13.pdf — L (informe técnico).

[F 37] McComas, P. y Sanmiya, J. (2010). «Animation Warping for Responsiveness in FIFA Soccer». GDC 2010, Electronic Arts. https://gdcvault.com/play/1012342/Animation-Warping-for-Responsiveness-in — L (ficha).

[F 38] Clavet, S. (2016). «Motion Matching and The Road to Next-Gen Animation». GDC 2016, Ubisoft Montreal. https://www.gdcvault.com/play/1022985/Motion-Matching-and-The-Road — L (ficha).

[F 39] Allen, H. (2021). «Animation Summit: Environmental and Motion Matched Interactions; ‘Madden’, ‘FIFA’ and Beyond!». GDC 2021, Electronic Arts. https://www.gdcvault.com/play/1027465/Animation-Summit-Environmental-and-Motion — L (ficha).

[F 40] Holden, D., Kanoun, O., Perepichka, M. y Popa, T. (2020). «Learned Motion Matching». *ACM Transactions on Graphics*, 39(4). DOI 10.1145/3386569.3392440. https://www.theorangeduck.com/page/learned-motion-matching — L.

[F 41] Holden, D. (2021). *Motion-Matching* (código fuente, licencia MIT). https://github.com/orangeduck/Motion-Matching — L (licencia).

[F 42] Holden, D., Komura, T. y Saito, J. (2017). «Phase-Functioned Neural Networks for Character Control». *ACM Transactions on Graphics*, 36(4), art. 42. DOI 10.1145/3072959.3073663. https://www.ipab.inf.ed.ac.uk/cgvu/phasefunction.pdf — E.

[F 43] Rosen, D. (2014). «Animation Bootcamp: An Indie Approach to Procedural Animation». GDC 2014, Wolfire Games. https://gdcvault.com/play/1020049/Animation-Bootcamp-An-Indie-Approach — E.

[F 44] Godot Engine (2025-2026). «Inverse Kinematics returns to Godot 4.6». https://godotengine.org/article/inverse-kinematics-returns-to-godot-4-6/ ; notas de versión: https://godotengine.org/releases/4.6/ — E.

[F 45] Robberechts, P. y Davis, J. (2020). «How data availability affects the ability to learn good xG models». En *Machine Learning and Data Mining for Sports Analytics (MLSA 2020)*, CCIS 1324, Springer, pp. 17-27. https://link.springer.com/doi/10.1007/978-3-030-64912-8_2 — E.

[F 46] Decroos, T., Bransen, L., Van Haaren, J. y Davis, J. (2019). «Actions Speak Louder than Goals: Valuing Player Actions in Soccer». *KDD ’19*. Preprint: https://arxiv.org/abs/1802.07127 — E.

[F 47] Trainor, C. (2014). «Defensive Metrics: Measuring the Intensity of a High Press». StatsBomb. https://statsbomb.com/?p=10118 — E.

[F 48] Premier League (24-05-2024). «The numbers that show this has been a season like no other». https://www.premierleague.com/news/4031506 — L.

[F 49] Segar, D. (29-03-2024). «The Numbers Behind the Premier League Goal Explosion». *Opta Analyst*. https://theanalyst.com/2024/03/numbers-behind-premier-league-goal-explosion — L.

[F 50] StatsBomb. *Open Data* (repositorio) y *StatsBomb Public Data User Agreement* (LICENSE.pdf). https://github.com/statsbomb/open-data — L.

[F 51] Awful Announcing (01-2026). «Sports Reference pulls advanced data after agreement violation dispute». https://awfulannouncing.com/soccer/sports-reference-pulls-advanced-data-agreement-violation-dispute.html — E.

[F 52] Kurach, K., Raichuk, A., Stańczyk, P., Zając, M., Bachem, O., Espeholt, L., Riquelme, C., Vincent, D., Michalski, M., Bousquet, O. y Gelly, S. (2020). «Google Research Football: A Novel Reinforcement Learning Environment». *AAAI-20*, pp. 4501-4510. DOI 10.1609/aaai.v34i04.5878. https://arxiv.org/abs/1907.11180 — L.

[F 53] Google Research. *football* (repositorio, licencia Apache 2.0; archivado el 19-08-2026). https://github.com/google-research/football — L.

[F 54] Game World Observer (19-12-2023). «PlayStation PC game sales leak, Insomniac budgets and ROI». https://gameworldobserver.com/2023/12/19/playstation-pc-game-sales-leak-insomniac-budgets-roi — E.

[F 55] Electronic Arts. «EA SPORTS — Job opportunities» (descripción de EA Vancouver). https://www.ea.com/ea-studios/ea-sports/job-opportunities — E.

[F 56] Kerr, C. (07-02-2025). «SEGA and Sports Interactive cancel Football Manager 25 after missing quality target». *Game Developer*. https://www.gamedeveloper.com/production/sega-and-sports-interactive-cancel-football-manager-25-after-missing-quality-target- — L.

[F 57] OpenCritic News (05-11-2025). «Football Manager 26 Now Has ‘Mostly Negative’ Reviews on Steam». https://opencritic.com/news/23193/football-manager-26-now-has-mostly-negative-reviews-on-steam — L.

[F 58] Video Games Chronicle (02-2024). «Football Manager 2024 hits a series record 7 million players». https://videogameschronicle.com/news/football-manager-2024-hits-a-series-record-7-million-players — E.

[F 59] Gematsu (24-06-2025). «Rematch sales top one million». https://www.gematsu.com/2025/06/rematch-sales-top-one-million — L.

[F 60] Gamereactor (2025). «Rematch reaches 5 million unique players». https://www.gamereactor.eu/rematch-reaches-5-million-unique-players-1576873/ — E.

[F 61] Game Developer (16-11-2023). «Sociable Soccer 24 out today on Steam» (nota de prensa). https://gamedeveloper.com/press-release/sociable-soccer-24-out-today-on-steam — E.

[F 62] FourFourTwo. «Sociable Soccer 24 review: Sensible Soccer made for a new generation of football fans». https://www.fourfourtwo.com/us/reviews/sociable-soccer-24-review-sensible-soccer-made-for-a-new-generation-of-football-fans — E.

[F 63] Steam. «Pro Soccer Online». https://store.steampowered.com/app/1583320/Pro_Soccer_Online/ — E.

[F 64] Adobe. «Mixamo | Common questions». https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html ; y Adobe Community, «Mixamo FAQ: Licensing, Royalties, Ownership, EULA and TOS», https://community.adobe.com/t5/mixamo-discussions/mixamo-faq-licensing-royalties-ownership-eula-and-tos/td-p/13234775 — E (página oficial inaccesible: 403).

[F 65] Quaternius. «Universal Animation Library». https://quaternius.com/packs/universalanimationlibrary.html — L.

[F 66] hexgrad. «Kokoro-82M» (ficha del modelo, licencia Apache 2.0). https://huggingface.co/hexgrad/Kokoro-82M — L.

[F 67] Open Home Foundation. *piper1-gpl* (versiones; «Change license to GPLv3» en v1.7.0). https://github.com/OHF-Voice/piper1-gpl/releases — E.

[F 68] 4TU.ResearchData (2024). «FBX Conversion Of The CMU Graphics Lab Motion Capture Database» (CC BY-NC 4.0). https://data.4tu.nl/datasets/0448aab2-3332-449f-a8e2-d208cb58c7df — E.


### 10.7.2 Fuentes del capítulo 11 (numeración original [R 1]-[R 69]; en la numeración unificada, [F 69]-[F 137])


*Repositorios de recursos 3D, texturas e iluminación*

[F 69] = [R 1] Poly Haven. «License». https://polyhaven.com/license — L.

[F 70] = [R 2] Poly Haven. *Public API* y «Poly Haven API Terms of Service». https://github.com/Poly-Haven/Public-API (ToS.md) — L. (La API es gratuita para cualquier uso, incluido el comercial; pide un «Referer» o user-agent propio de la aplicación y, solo para la API en vivo, un crédito ligero.)

[F 71] = [R 3] Poly Haven. Fichas de recursos: `stadium_01`, `orlando_stadium`, `stadium_exterior`, `suburban_football_field`, `suburban_soccer_park`, `kloppenheim_07`, `moonlit_golf`, `qwantani_night`, `cotton_jersey`, `jersey_melange`, `waffle_pique_cotton`, `grass_medium_01`, `grass_bermuda_01`, `football`, `dirty_football`. https://polyhaven.com/a/<nombre> y https://api.polyhaven.com/info/<nombre> — L.

[F 72] = [R 4] ambientCG. «License». https://docs.ambientcg.com/license/ ; API `https://ambientcg.com/api/v2/full_json` (búsquedas «grass», «fabric», «net», «concrete») — L.

[F 73] = [R 5] Freesound. «Frequently Asked Questions» (licencias). https://freesound.org/help/faq/ — L.

[F 74] = [R 6] Sketchfab. «Licenses» (Standard y Editorial). https://sketchfab.com/licenses — L.

[F 75] = [R 7] Sketchfab Help Center. Licencias Creative Commons para descargas. https://help.sketchfab.com/en/articles/16152217 — L.

[F 76] = [R 8] Kenney. «Support» (licencia de los recursos). https://kenney.nl/support — L.

[F 77] = [R 9] Kenney. «Game Icons», «Impact Sounds», «Voiceover Pack», «Music Jingles», «Sports Pack». https://kenney.nl/assets/game-icons (y análogas) — L.

[F 78] = [R 10] Quaternius. «Background Posed Humans» y listado de packs. https://quaternius.com/packs/backgroundposedhumans.html — L.

[F 79] = [R 11] OpenGameArt. «FAQ». https://opengameart.org/content/faq — no accesible (403).


*Captura de movimiento y animación*

[F 80] = [R 12] Max Planck Institute for Intelligent Systems. «AMASS — License». https://amass.is.tue.mpg.de/license.html — L.

[F 81] = [R 13] Ubisoft La Forge. *ubisoft-laforge-animation-dataset* (LAFAN1). https://github.com/ubisoft/ubisoft-laforge-animation-dataset — L.

[F 82] = [R 14] Bandai Namco Research. *Bandai-Namco-Research-Motiondataset*. https://github.com/BandaiNamcoResearchInc/Bandai-Namco-Research-Motiondataset — L.

[F 83] = [R 15] Simon Fraser University y National University of Singapore. «SFU Motion Capture Database». https://mocap.cs.sfu.ca/ — L.

[F 84] = [R 16] Carnegie Mellon University Graphics Lab. «CMU Graphics Lab Motion Capture Database». http://mocap.cs.cmu.edu — FAQ inaccesible (503); licencia verificada en `LICENCIAS.md` por el `READMEFIRST.txt` de la conversión BVH.

[F 85] = [R 17] MB-Lab. Repositorio y `license.txt`. https://github.com/animate1978/MB-Lab ; https://raw.githubusercontent.com/animate1978/MB-Lab/master/license.txt — L.

[F 86] = [R 18] Thacker, J. (2025). «You can now sell MetaHumans, or use them in Unity or Godot». CG Channel, 4-6-2025. https://www.cgchannel.com/2025/06/you-can-now-sell-metahumans-or-use-them-in-unity-or-godot/ — E (fuente secundaria; el EULA oficial requiere sesión).

[F 87] = [R 19] Rokoko Motion Library: CG Channel (2020), «Get 150 free mocap moves from Rokoko’s Motion Library», https://www.cgchannel.com/2020/03/get-150-free-mocap-moves-from-rokokos-motion-library ; Rokoko, «Pricing», https://rokoko.com/pricing/ — E.

[F 88] = [R 20] Truebones. Tienda en Gumroad. https://truebones.gumroad.com — E.

[F 89] = [R 21] Godot Engine. «Inverse kinematics returns to Godot 4.6». https://godotengine.org/article/inverse-kinematics-returns-to-godot-4-6/ ; referencia de clase `IKModifier3D` y `FABRIK3D`, https://docs.godotengine.org/en/4.6/classes/class_ikmodifier3d.html — L.

[F 90] = [R 22] Sousa, G. *Godot Motion Matching* (licencia MIT, © 2024). https://github.com/GuilhermeGSousa/godot-motion-matching — L.

[F 91] = [R 23] Holden, D. *Motion-Matching* (MIT). Ver [cap. 2, 41].

[F 92] = [R 24] limbonaut. *LimboAI*. https://github.com/limbonaut/limboai — L.

[F 93] = [R 25] bitbrain. *Beehave* (MIT, © 2023). https://github.com/bitbrain/beehave — L.

[F 94] = [R 26] MakeHuman Community. `LICENSE.md`. https://github.com/makehumancommunity/makehuman/blob/master/LICENSE.md — L.


*Sonido, voz y música*

[F 95] = [R 27] Sonniss. «GDC Game Audio Bundle License». https://sonniss.com/gdc-bundle-license/ — L.

[F 96] = [R 28] felix.blume. «Crowd yelling huuuuu (60k persons) during a soccer game in Brazil» (612131) y «Crowd screaming GOAL during the soccer game Mexico-Holland (Fifa world cup 2014)» (241630). Freesound. https://freesound.org/people/felix.blume/sounds/612131/ ; https://freesound.org/people/felix.blume/sounds/241630/ — L.

[F 97] = [R 29] Vogyik. «Norwegian football match / soccer game ambience XY to ORTF, AB and Binaural» (868982). https://freesound.org/people/Vogyik/sounds/868982/ — L. paulw2k, «Football-crowd-GOAL.wav» (196461), https://freesound.org/s/196461/ — L.

[F 98] = [R 30] hexgrad. *Kokoro-82M*, `VOICES.md`. https://huggingface.co/hexgrad/Kokoro-82M/blob/main/VOICES.md ; `kokoro` (Apache 2.0), https://github.com/hexgrad/kokoro ; `misaki` (respaldo con espeak), https://github.com/hexgrad/misaki ; `kokoro-onnx` (MIT; dependencias `phonemizer`, `espeakng-loader`), https://github.com/thewh1teagle/kokoro-onnx — L. Ver también [cap. 2, 66].

[F 99] = [R 31] Coqui. *XTTS-v2* y «Coqui Public Model License 1.0.0». https://huggingface.co/coqui/XTTS-v2 — L.

[F 100] = [R 32] SWivid. *F5-TTS* (código MIT; pesos CC BY-NC 4.0). https://github.com/SWivid/F5-TTS ; https://huggingface.co/SWivid/F5-TTS — L.

[F 101] = [R 33] Open Home Foundation. *piper1-gpl*, `docs/LICENSING.md` y `docs/COMMERCIAL_USE.md`. https://github.com/OHF-Voice/piper1-gpl — L. Ver también [cap. 2, 67].

[F 102] = [R 34] Resemble AI. *Chatterbox* (MIT). https://github.com/resemble-ai/chatterbox ; https://huggingface.co/ResembleAI/chatterbox — L.

[F 103] = [R 35] MyShell. *MeloTTS* (MIT) y *MeloTTS-Spanish*. https://github.com/myshell-ai/MeloTTS ; https://huggingface.co/myshell-ai/MeloTTS-Spanish — L.

[F 104] = [R 36] Google. *google/fonts* (README: licencias por carpeta) y archivos `ofl/<familia>/OFL.txt`. https://github.com/google/fonts — L.

[F 105] = [R 37] MacLeod, K. «Royalty Free Music FAQ». Incompetech. https://incompetech.com/music/royalty-free/faq.html — L.

[F 106] = [R 38] FreePD. https://freepd.com — L (aviso de cierre; sin licencia legible).

[F 107] = [R 39] Mozilla Foundation. *Common Voice Scripted Speech 25.0 — Spanish* (Data Collective). https://datacollective.mozillafoundation.org/datasets/cmn4z1n52000knv07h01532dd — E.

[F 108] = [R 40] Blender. «About Free Software and the GPL» (manual). https://docs.blender.org/manual/en/4.2/getting_started/about/license.html — E.

[F 109] = [R 41] Blender Foundation. «Blender FAQ for Artists and the GPL», lista bf-committers, 2004. https://lists.blender.org/pipermail/bf-committers/2004-November/008253.html — E.

[F 110] = [R 42] Suno. *Bark* (MIT). https://huggingface.co/suno/bark ; Hugging Face, *parler-tts-mini-multilingual-v1.1* (Apache 2.0), https://huggingface.co/parler-tts/parler-tts-mini-multilingual-v1.1 ; Nari Labs, *Dia-1.6B*; Zyphra, *Zonos-v0.1*; Canopy Labs, *Orpheus-TTS*; Sesame, *CSM* (Apache 2.0, archivo `LICENSE` de cada repositorio) — L.


*Iconos*

[F 111] = [R 43] Google. *material-design-icons* (Apache 2.0). https://github.com/google/material-design-icons — L. Tabler, *tabler-icons* (MIT, 6.545 iconos), https://github.com/tabler/tabler-icons — L. Lucide, «License», https://lucide.dev/license — L. Phosphor Icons (MIT), https://github.com/phosphor-icons/homepage — L. Bootstrap Icons (MIT), https://github.com/twbs/icons — L. Microsoft, *fluentui-system-icons* (MIT), https://github.com/microsoft/fluentui-system-icons — L. Font Awesome, `LICENSE.txt`, https://github.com/FortAwesome/Font-Awesome — L. game-icons.net, «About», https://game-icons.net/about.html — L.


*Godot: documentación y complementos*

[F 112] = [R 44] Godot Docs. «Mesh level of detail (LOD)». https://docs.godotengine.org/en/stable/tutorials/3d/mesh_lod.html — L (página accesible).

[F 113] = [R 45] Godot Docs. «Visibility ranges (HLOD)». https://docs.godotengine.org/en/stable/tutorials/3d/visibility_ranges.html — L.

[F 114] = [R 46] Godot Docs. «Optimization using MultiMeshes». https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html — L.

[F 115] = [R 47] TokisanGames. *Terrain3D* (MIT) y *Sky3D* (MIT, Godot 4.3+). https://github.com/TokisanGames/Terrain3D ; https://github.com/TokisanGames/Sky3D — L.

[F 116] = [R 48] dreadpon. *Spatial Gardener* (MIT). https://github.com/dreadpon/godot_spatial_gardener ; HungryProton, *Scatter* (MIT), https://github.com/HungryProton/scatter ; 2Retr0, *GodotGrass* (MIT), https://github.com/2Retr0/GodotGrass — L.

[F 117] = [R 49] wojtekpil y K. S. E. Lee. *Godot-Octahedral-Impostors* (MIT). https://github.com/wojtekpil/Godot-Octahedral-Impostors — L.

[F 118] = [R 50] Godot Docs. «Tracy» (perfiladores de trazas). https://docs.godotengine.org/en/stable/engine_details/development/profiling/tracy.html — L (página accesible).

[F 119] = [R 51] Godot Engine. PR #104851, «Add `profiler` option to SCons builds, with support for `tracy` and `perfetto`» (vía réplica del repositorio). https://remotebranch.eu/Stowage/godot/commit/e80194e31f6944d09afd04fd7298fb09a3bc2b52 — E.

[F 120] = [R 52] Godot Docs. «Submitting to the Asset Library». https://docs.godotengine.org/en/stable/community/asset_library/submitting_to_assetlib.html — L.

[F 121] = [R 53] ramokz. *Phantom Camera* (MIT). https://github.com/ramokz/phantom-camera — L.


*QA, perfilado y herramientas*

[F 122] = [R 54] wolfpld. *Tracy Profiler* (BSD-3). https://github.com/wolfpld/tracy — L. Google, *Perfetto* (Apache 2.0), https://github.com/google/perfetto — L.

[F 123] = [R 55] Karlsson, B. *RenderDoc* (MIT). https://github.com/baldurk/renderdoc — L.

[F 124] = [R 56] bitwes, *Gut* (MIT), https://github.com/bitwes/Gut ; Schulze, M., *gdUnit4* (MIT), https://github.com/MikeSchulze/gdUnit4 ; Suescun, R., *Material Maker* (MIT), https://github.com/RodZill4/material-maker ; KDE, *Krita* (GPL-3), https://github.com/KDE/krita ; Audacity (GPL-3), https://github.com/audacity/audacity ; *espeak-ng* (GPL-3), https://github.com/espeak-ng/espeak-ng — L.


*Traducción*

[F 125] = [R 57] Meta. *nllb-200-distilled-600M* (CC BY-NC 4.0). https://huggingface.co/facebook/nllb-200-distilled-600M — L.

[F 126] = [R 58] Meta. *seamless-m4t-v2-large* (CC BY-NC 4.0). https://huggingface.co/facebook/seamless-m4t-v2-large — L.

[F 127] = [R 59] Unbabel. *TowerInstruct-7B-v0.2* (CC BY-NC 4.0). https://huggingface.co/Unbabel/TowerInstruct-7B-v0.2 — L.

[F 128] = [R 60] Helsinki-NLP. *opus-mt-es-en*, *opus-mt-en-es*, *opus-mt-es-fr* (Apache 2.0), *opus-mt-tc-big-en-pt* (CC BY 4.0). https://huggingface.co/Helsinki-NLP — L. Google, *madlad400-3b-mt* (Apache 2.0), https://huggingface.co/google/madlad400-3b-mt — L. Meta, *m2m100_418M* (MIT), https://huggingface.co/facebook/m2m100_418M — L. Qwen2.5-7B-Instruct, Mistral-7B-Instruct-v0.3, EuroLLM-9B-Instruct (Apache 2.0), fichas en Hugging Face — L. Google, *gemma-3-4b-it* (términos Gemma) — L (etiqueta).

[F 129] = [R 61] Argos Translate (MIT o CC0). https://github.com/argosopentech/argos-translate ; LibreTranslate (AGPL-3), https://github.com/LibreTranslate/LibreTranslate ; Weblate (GPL-3), https://github.com/WeblateOrg/weblate ; OpenNMT, *CTranslate2* (MIT), https://github.com/OpenNMT/CTranslate2 — L.


*Datos de fútbol*

[F 130] = [R 62] Pappalardo, L.; Cintia, P.; Rossi, A.; Massucco, E.; Ferragina, P.; Pedreschi, D.; Giannotti, F. (2019). «A public data set of spatio-temporal match events in soccer competitions». *Scientific Data* 6:236. https://pmc.ncbi.nlm.nih.gov/articles/PMC6817871 ; colección en figshare: https://figshare.com/collections/Soccer_match_event_dataset/4415000/2 — L (licencia en el artículo).

[F 131] = [R 63] Metrica Sports. *sample-data*. https://github.com/metrica-sports/sample-data — L (sin licencia).

[F 132] = [R 64] Football-Data.co.uk. «Notes». https://www.football-data.co.uk/notes.txt — L (sin términos).

[F 133] = [R 65] SkillCorner. *opendata* (MIT, © 2020). https://github.com/SkillCorner/opendata — L.

[F 134] = [R 66] openfootball. *football.json* y *worldcup.json* (CC0 1.0). https://github.com/openfootball/football.json — L.

[F 135] = [R 67] Wikidata. «Wikidata:Licensing». https://www.wikidata.org/wiki/Wikidata:Licensing — L.

[F 136] = [R 68] PySport. *kloppy* (BSD-3). https://github.com/PySport/kloppy — L.


*Otras*

[F 137] = [R 69] Blender Studio. «Terms and Conditions» (contenido digital bajo CC BY 4.0 salvo aviso). https://studio.blender.org/terms-and-conditions — L.

