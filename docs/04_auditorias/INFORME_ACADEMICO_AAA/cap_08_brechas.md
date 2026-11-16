# Capítulo 8. Brechas frente a PES 2020 y FC 27: síntesis con fuentes

Informe académico AAA de Dinastía · Redacción: 16-11-2026.
Convenciones: [M] medido · [D] documento del proyecto · [F n] fuente del capítulo 2 · [R n] fuente del capítulo 11 · [E] estimación. Las notas de este capítulo son **juicios** con intervalo y nivel de confianza, no mediciones.

---

## Resumen

Este capítulo cruza la evidencia de los capítulos 2 a 7 y 11 para estimar, área por área, la distancia entre Dinastía y los dos referentes. Se revisan las notas de la comparativa interna del 10-11 y del resumen ejecutivo del 16-11 con tres cambios de método: cada nota lleva un intervalo, cada área declara el tipo de evidencia que la sostiene, y se añaden dos áreas que los documentos anteriores no tenían (física del balón y reglamento; estabilidad y calidad técnica), porque los capítulos 5 a 7 aportan evidencia directa sobre ellas.

Con 18 áreas, la media simple es **4,8 para Dinastía, 6,8 para PES 2020 y 7,0 para FC 27** [E]. Con la ponderación que el propio proyecto declara (60 % partido, 25 % menús, 15 % lo demás), la distancia crece: **4,4 frente a 7,2 y 7,1** [E]. La conclusión es robusta a la incertidumbre: aun tomando el extremo superior de cada intervalo de Dinastía y el inferior de los referentes, Dinastía queda en 5,2 frente a 6,2 (PES 2020) y 6,0 (FC 27). La brecha está concentrada en las ocho áreas del partido, donde Dinastía promedia 3,8 frente a 7,5 y 7,8; en las seis áreas del «terreno propio» (gestión, modo jugador, monetización, modding, accesibilidad, rendimiento en equipos modestos) Dinastía promedia 6,8 frente a 6,2 y 5,3, pero esa ventaja descansa en diseño y no en validación con jugadores.

Se identifican cuatro brechas transversales que no aparecen en una matriz por áreas: de **sensación** (control, animación y presentación forman un solo problema), de **verificación** (cero probadores externos), de **corrección en las fronteras** (los fallos de los capítulos 5 a 7) y de **medición** (el teléfono sin medir desde el ~4-11). Se delimitan las áreas donde Dinastía ya gana y aquellas en las que no debe competir.

---

## 8.1 Introducción

### 8.1.1 Objetivo

Responder a la parte descriptiva de RQ2 (dónde está Dinastía respecto de los referentes) y preparar RQ4 (cómo superarlos), con una matriz que el capítulo 9 pueda usar para asignar prioridades.

### 8.1.2 Antecedentes

La comparativa del 10-11 puntuó 13 áreas para PES 2020 y Dinastía (medias 7,1 y 4,6), con marcas de evidencia mixtas [D: `COMPARATIVA_PES2020.md` §1]. El resumen ejecutivo del 16-11 amplió a 16 áreas y añadió FC 27 como estimación basada en la serie anterior, porque su autor no tenía información verificada del juego [D: `INFORME_AAA_2026-11-16.md` §3]. El capítulo 2 sustituye parte de esas estimaciones por fuentes; los capítulos 3 a 7 aportan evidencia interna nueva.

---

## 8.2 Método de síntesis

### 8.2.1 Escala

Se mantiene la escala 1-10 de la comparativa interna para poder comparar: 10 = referencia absoluta del género; 7 = sólido; 5 = jugable con carencias claras; 3 = esbozo [D: `COMPARATIVA_PES2020.md` §1]. Se añade el 0 para una función inexistente (online en Dinastía).

### 8.2.2 Intervalos y confianza

Cada nota lleva un intervalo que expresa la incertidumbre de quien redacta, y un nivel de confianza según el tipo de evidencia:

| Nivel | Significado |
|---|---|
| **A** | Hay evidencia directa y verificable para Dinastía (medición, prueba, fallo confirmado) y fuente externa con nivel L para los referentes |
| **B** | Evidencia documental del proyecto o fuentes externas de nivel E; sin observación directa del área en juego |
| **C** | Juicio basado en conocimiento general o en material de marketing; sin fuente que lo apoye de forma específica |

### 8.2.3 Reglas de revisión

1. Una nota del resumen ejecutivo se conserva salvo que haya evidencia nueva que la mueva.
2. Las afirmaciones del editor sobre su propia tecnología (por ejemplo, HyperMotion V o SAPIEN [F 10]) cuentan como evidencia de nivel C, porque son marketing y no mediciones independientes (capítulo 2, §2.10.2).
3. Las notas de Dinastía en áreas de diseño no probado por jugadores (gestión, La Ruta) llevan un intervalo asimétrico hacia abajo: lo que el código ofrece puede no traducirse en disfrute.
4. Las medias que se calculan son ilustrativas: la escala es ordinal y la media de notas ordinales no tiene un significado métrico estricto. Se usan para comparar perfiles, no para afirmar diferencias de «puntos».

---

## 8.3 Los referentes en una página

| Rasgo | PES 2020 | FC 27 | Fuente |
|---|---|---|---|
| Media de la crítica (OpenCritic) | 81 (71 reseñas), 79 % recomienda | 77 (84 reseñas), 64 % recomienda | [F 2][F 18] |
| Lo más elogiado | Partido: equilibrio, pase, tiro lejano, regate fino | Defensa manual, centros, entrada física, Carrera | [F 3][F 4][F 19][F 20] |
| Lo más criticado | Comentario, grada, Become a Legend, Liga Master, licencias | IA de compañeros, cambio de jugador, The Grounds, monetización | [F 4][F 5][F 6][F 19][F 20] |
| Contenido declarado | Licencias parciales, Juventus exclusiva, Euro 2020 | >21.000 jugadores, >800 clubes y selecciones, >130 estadios, >35 ligas | [F 4][F 17] |
| Monetización | myClub con monedas y fichajes aleatorios [D: `COMPARATIVA_PES2020.md` §4] | Ultimate Team; edición con 10.000 FC Points | [F 17][F 20] |
| Modding | Option files de la comunidad | Cerrado [D: resumen ejecutivo, marca C] | [F 7] |

La tabla refleja el hallazgo H1 del capítulo 2: la crítica premia el partido y castiga el entorno; en ninguno de los casos revisados la crítica principal fue «faltan licencias» o «faltan clubes» [F 4][F 16][F 19][F 20][F 57].

---

## 8.4 Área por área

### 8.4.1 Sensación de control

- **Dinastía**: el veredicto del dueño sobre la versión del 2-11 fue «jugabilidad muy mala», «movilidad del jugador horrible» [D: `PRUEBA_DUENO_MOVIL_2026-11-03.md`]. Desde entonces el motor cambió a C4 (11-11) y no hay un veredicto nuevo. El capítulo 6 encontró que en el estadio la entrada se leía dentro del paso fijo: a más de 60 FPS se perdía cerca de la mitad de las pulsaciones y a 30 o menos se duplicaban (M6-01, arreglado el 16-11), y que el pase manual de 12 m se queda en unos 8 m por usar dos leyes de rozamiento (M6-06, pendiente). Nadie ha medido la latencia de extremo a extremo (capítulo 4). Nota **3 (2-4)**, confianza B.
- **PES 2020**: «tan bien como cualquier videojuego de fútbol que se haya hecho» en equilibrio; pase dependiente del tiempo de ejecución [F 4]. Nota **8 (7-9)**, A.
- **FC 27**: el control manual de los defensores «mejor recompensado», pases al hueco que piden más puntería; pero cambio de jugador «frenético» y que «se vuelve loco» en el área [F 19][F 20]. Nota **7 (6-8)**, A.
- **Brecha**: la mayor del informe en importancia, porque el juego se decide en los primeros minutos de partido [D: resumen ejecutivo §0]. La literatura ofrece cómo medirla (umbrales de latencia [F 33][F 35]) y técnicas documentadas para la latencia de animación (*warping* en FIFA [F 37]).

### 8.4.2 IA y táctica

- **Dinastía**: trabajo sistemático y medido (banderas `C4_*` con 12+12 partidos de clubes de varios países), pero con resultados limitados: cadenas de 5 o más pases en torno a 3,5 por partido y goles que nacen «del desorden» más que de la jugada [D: `MOTOR_LEAGUE_SOCCER_PLAN.md`, sesiones 13 y 15]. La contrapresión no cambia nada con presión media o alta (F-01, capítulo 5); en los niveles bajos, la CPU veía a los rivales donde estaban al final del primer tiempo (M6-02, arreglado). Los ocho niveles de dificultad están definidos pero no conectados de verdad a la calidad de decisión [D: resumen ejecutivo §2.2]. Nota **4 (3-5)**, B.
- **PES 2020**: «Inspire» (los compañeros reaccionan al estilo del portador) [F 3]; IA irregular sin balón según reseñas recogidas en la comparativa [D]. Nota **7 (6-8)**, B.
- **FC 27**: FC IQ con 31 roles y tácticas inteligentes desde FC 25 [F 11]; pero en FC 27 los compañeros de la IA «a veces hacen tonterías» [F 19]. Se baja de 7 a **6 (5-7)**, B.
- **Brecha**: amplia, pero la de FC es menor de lo que suponía el resumen ejecutivo. La validación con datos tiene ahora una vía legal: el conjunto de Pappalardo y otros (Wyscout, CC BY 4.0) [R 62] y SkillCorner (MIT) [R 65], frente a StatsBomb, que lo prohíbe [F 50].

### 8.4.3 Física del balón y reglamento (área nueva)

- **Dinastía**: el capítulo 6 confirmó que el fuera de juego no se pitaba en remates ni pases de primera (M6-04, arreglado), que las amarillas del primer tiempo se olvidaban en el estadio del DT (M6-05, arreglado), que el clima no frena el balón suelto en C4 (M6-07) y que el portero es intocable fuera de su área (M6-10); quedan pendientes ocho defectos bajos de reglamento (M6-17 a M6-20 y otros). A favor: divisiones guardadas, azar sembrado, mayoría del reglamento correcto, sin cuelgues (cap. 6 §6.6). Nota **4 (3-5)**, A.
- **PES 2020**: Konami declaró física del balón y primer toque «mucho más realistas» [F 3]; la crítica lo llamó «el PES más realista» [F 5]. Nota **8 (7-9)**, B.
- **FC 27**: sin fuente específica sobre la física del balón; córners dinámicos declarados [F 17]. Nota **7 (6-8)**, C.

### 8.4.4 Animación y cuerpos

- **Dinastía**: 296 clips de League-Soccer y unos 25 festejos [D]; la guía de animaciones en C4 se dejó apagada porque empeoraba duelos, regates y acierto de pase y subía la CPU un 18 % [D: `MOTOR_LEAGUE_SOCCER_PLAN.md` §12]; cuerpos que se atraviesan en la foto de equipo (P4) [D: `PRUEBA_DUENO_MOVIL_2026-11-03.md`]. No hay IK en uso ni *motion matching*. Nota **4 (3-5)**, B.
- **PES 2020**: captura de movimiento, Finesse Dribble y animaciones de entrada nuevas [F 3]. Nota **8 (7-9)**, B.
- **FC 27**: HyperMotion V con datos volumétricos de más de 180 partidos [F 10]; cifras de marketing. Nota **8 (7-9)**, C (el resumen ejecutivo daba 9).
- **Brecha**: grande y la más cara de cerrar por contenido. El capítulo 11 no encontró ninguna base de captura de fútbol o de portero con licencia comercial y descarga libre, salvo CMU, ya en uso (§11.10). La vía es técnica: IK nativo de Godot 4.6+ [F 44][R 21], *motion matching* clásico sobre los clips existentes [F 38][F 41][R 22] y animación procedural [F 43].

### 8.4.5 Jugadores y caras

- **Dinastía**: biblioteca pública de 300 caras mezcladas y cara procedural; las reales solo en un paquete privado ausente de los builds [M: cap. 3 §3.5.2]. El 16-11 se arreglaron los «parches claros» de camisetas y se añadió una tela de punto CC0 [R 3], pendiente del veredicto del dueño [D: `PLAN_GENERAL.md`, «INFORME ACADÉMICO AAA»]. Nota **4 (3-5)**, B.
- **PES 2020**: caras escaneadas de muchas estrellas [D: `COMPARATIVA_PES2020.md`]. Nota **8 (7-9)**, B.
- **FC 27**: modelos con la tecnología SAPIEN [F 10]; licencias de miles de jugadores [F 17]. Nota **9 (8-10)**, C.
- **Brecha**: no se debe cerrar en fidelidad a personas reales (derecho de imagen, capítulo 1, §1.9); sí en calidad del material (piel, tela, pelo, tipos de cuerpo), con recursos CC0 y herramientas externas como MakeHuman [R 26].

### 8.4.6 Estadios, público y luz

- **Dinastía**: 2.203 estadios con firma visual distinta y 783 núcleos arquitectónicos [M]; unos 30 con piezas de estadio real [D]; en ULTRA BAJA el público «se lee como ruido de estática» en un club y mejor en otro, y los rótulos de las vallas son ilegibles [D: `INFORME_SESION_2026-11-15.md` §5]; público 2D en prototipo. Nota **4 (3-5)**, B.
- **PES 2020**: estadios e iluminación muy pulidos [D: comparativa, marca C]. Nota **8 (7-9)**, C.
- **FC 27**: más de 130 estadios declarados [F 17]. Nota **8 (7-9)**, B.
- **Brecha**: grande en calidad, invertida en cantidad. Los recursos CC0 de Poly Haven y ambientCG (HDRI de estadios, césped) [R 1][R 3][R 4] cubren luz y materiales sin coste.

### 8.4.7 Presentación televisiva

- **Dinastía**: cámara de TV de cuatro planos y repeticiones; sin planos al público, al banquillo o al árbitro; sin paquete gráfico unificado [D: resumen ejecutivo §2.5]. Nota **3 (2-4)**, B.
- **PES 2020**: presentación moderna, cinemáticas, repeticiones [D: comparativa]. Nota **7 (6-8)**, B.
- **FC 27**: sin fuente verificada sobre su presentación; la serie es referente de presentación con licencias de retransmisión [E]. Nota **9 (7-9)**, C.
- **Brecha**: es la que más rinde por hora según el resumen ejecutivo (§2.5), porque es diseño y código, no presupuesto. Phantom Camera (MIT) [R 53] y LimboAI (MIT) [R 24] permiten un director de cámara por estados.

### 8.4.8 Audio y comentario

- **Dinastía**: sonidos CC0, silbato y ambiente; **sin comentarista** [D: comparativa]. Nota **4 (3-4)**, B.
- **PES 2020**: comentario «monótono» y con «muy pocas frases nuevas»; cánticos que rara vez hacen sentir un partido real [F 4][F 6]. Nota **6 (5-7)**, A.
- **FC 27**: sin fuente específica [E]. Nota **8 (6-8)**, C.
- **Brecha**: el comentario es la crítica de presentación más repetida en PES 2020 (capítulo 2, I17). Hay grabaciones CC0 reales de estadios de fútbol [R 28][R 29] y voces sintéticas en español con licencias permisivas, con la condición de generar los audios fuera del juego por la dependencia GPL de los fonemas [R 30][R 34].

### 8.4.9 Menús e interfaz

- **Dinastía**: rediseño en curso al nivel del menú central de la Liga Master (Frente 1) [D: `PLAN_GENERAL.md`, «TRES FRENTES»]; el dueño juzga las interfaces «muy llenas» (orden 51); el menú lateral seguía «ocupado» tras cerrarse y desviaba los atajos del mando (F-02, en curso); la portada de un menú lateral abre en ~90 ms y la primera entrada a submenús grandes cuesta 150-300 ms en el contenedor [D: `PLAN_GENERAL.md`, «PEDIDOS DEL DUEÑO (15-11)»]. Nota **5 (4-6)**, B.
- **PES 2020**: menús rediseñados y fáciles de navegar, algo saturados en myClub [D: comparativa]. Nota **7 (6-8)**, B.
- **FC 27**: FC 26 criticado por la «interfaz recargada» [F 16]; The Grounds, «sobre todo un menú con tiendas de cosméticos» [F 20]. Nota **6 (5-7)**, A.
- **Brecha**: moderada y superable. Es también el mayor riesgo de producción documentado: Football Manager 25 se canceló por la interfaz y FM26 cayó al 22 % de reseñas positivas en Steam por la interfaz y el rendimiento [F 56][F 57].

### 8.4.10 Gestión del club

- **Dinastía**: finanzas con origen de cada ingreso, directiva, cantera, prensa, política, instalaciones, patrocinios [D]; el capítulo 7 la encuentra «en mejor estado» que La Ruta, con fallos de baja gravedad en la economía (G-05 a G-08) y dos del mundo que afectan también al modo entrenador (G-02 asistencias, arreglado; G-04, arreglado). Ningún jugador externo la ha probado. Nota **8 (6-8)**, B.
- **PES 2020**: Liga Master con diálogos y traspasos basados en datos reales [F 3], pero «atrapada en el mismo patrón» según extractos [F 4] y capítulo 2, §2.3.3. Nota **6 (5-7)**, A.
- **FC 27**: mercado de traspasos de Carrera reconstruido [F 17]; «Carrera es lo mejor del paquete» [F 20]; pero la IA pide traspasos sin sentido y no se puede bloquear [F 19]. Se sube de 6 a **7 (6-8)**, A.
- **Brecha**: favorable a Dinastía en profundidad, pero menor de lo que decía el resumen ejecutivo (8 frente a 6), porque FC 27 mejoró su Carrera según dos reseñas.

### 8.4.11 Modo jugador

- **Dinastía**: La Ruta, reescrita el 13-11, con habilidades por zona, premios por competición, brazalete y galas 3D por premio [D]. El capítulo 7 encontró dos fallos que perdían la carrera (R-01 y G-01, arreglados), tres reglas visibles falsas (R-02, R-03, G-02, arreglados; R-03 solo mitigado) y una economía de puntos con agujeros medibles (el portero sube unas seis veces más barato, R-08, pendiente). Concluye que su estructura es «coherente y potencialmente muy divertida» [D: cap. 7 §7.6.7]. Nota **6 (4-7)**, B.
- **PES 2020**: Become a Legend «se ha quedado rancio» [F 4]. Nota **5 (4-6)**, A.
- **FC 27**: sin fuente específica sobre la Carrera de jugador; en FC 25 la queja más extendida fue la apatía hacia el modo Carrera [F 14]. Nota **7 (6-8)**, C.

### 8.4.12 Contenido y licencias

- **Dinastía**: 2.206 clubes, 147 ligas, 135 países, 55.150 jugadores, 135 selecciones, 6 continentales de clubes y Mundial de 48 [M: cap. 3 §3.5.2]; sin licencias, por decisión del dueño; datos fijos en una fracción de los jugadores; datos de ligas pequeñas «en parte de memoria» [D]. Se sube de 4 a **5 (4-6)** por la amplitud medida, B.
- **PES 2020**: licencias parciales [F 4]. Nota **6 (5-7)**, A.
- **FC 27**: más de 21.000 jugadores, 800 clubes, 35 ligas licenciados [F 17]. Nota **10 (9-10)**, A.
- **Brecha**: en licencias, no se debe competir. En amplitud, Dinastía supera las cifras declaradas por FC 27; el valor percibido depende de la fidelidad (escudos, uniformes, estadios) y del modding.

### 8.4.13 Rendimiento en equipos modestos y móvil

- **Dinastía**: laptop i3-N300 con Intel UHD: ULTRA ~39-41, ULTRA BAJA ~100-107 FPS [D]; teléfono: 30 FPS en MÍNIMA (~4-11) y nada después [D] (capítulo 4). Nota **5 (4-6)**, B.
- **PES 2020**: estable a 60 en consola y PC [D: comparativa, marca C]; tuvo versión móvil con Unreal Engine 4 [F 1]. Nota **8 (7-9)**, C.
- **FC 27**: sin fuente verificada sobre requisitos [E]. Nota **6 (5-7)**, C.
- **Brecha**: depende casi entera de una medición que falta. Si el teléfono confirmara 60 FPS en MÍNIMA, la nota de Dinastía subiría a 7 y el área pasaría a ser un argumento de producto.

### 8.4.14 Accesibilidad e idiomas

- **Dinastía**: nueve idiomas, daltonismo, escala de texto, contraste alto, atajos editables, siete niveles de calidad, prueba de rendimiento integrada [D: comparativa]; textos de eventos de La Ruta que pueden salir sin traducir (R-12, plausible). Nota **7 (6-8)**, B.
- **PES 2020**: opciones clásicas, poca accesibilidad [D: comparativa, marca C]. Nota **5 (4-6)**, C.
- **FC 27**: sin fuente [E]. Nota **7 (6-8)**, C.

### 8.4.15 Monetización

- **Dinastía**: sin pagos, sin cartas, sin sobres (decisión del dueño, 26-10) [D]. Nota **10 (9-10)**, A.
- **PES 2020**: myClub con monedas [D: comparativa]. Nota **6 (5-7)**, B.
- **FC 27**: «el camino más rápido a un gran equipo en Ultimate Team sigue pasando por la cartera» [F 20]; edición con 10.000 FC Points [F 17]. Nota **3 (2-4)**, A.
- **Contexto**: Brasil prohíbe desde marzo de 2026 las cajas de botín en juegos accesibles a menores [F 27]; Bélgica las trata como juego de azar desde 2018 [F 22]. Con ligas sudamericanas en el juego, la ausencia de pago aleatorio es una ventaja concreta de mercado (capítulo 2, H5 e I14).

### 8.4.16 Modding y apertura

- **Dinastía**: `pack_real.json` y `caras_reales.pck` locales; escudos, uniformes y datos en JSON [D]; pero no hay un editor ni un formato de importación documentado para la comunidad (tareas 77-78 del resumen ejecutivo, pendientes). Se baja de 7 a **5 (4-7)**: es potencial, no producto. B.
- **PES 2020**: option files de la comunidad que restauran nombres, uniformes y escudos [F 7]. Nota **7 (6-8)**, B.
- **FC 27**: cerrado [D: resumen ejecutivo, marca C]. Nota **2 (1-3)**, C.

### 8.4.17 Online

- **Dinastía**: no existe; decisión del dueño de no competir [D]. Nota **0**, A.
- **PES 2020**: divisiones y myClub en línea, con fallos [D: comparativa]. Nota **6 (5-7)**, B.
- **FC 27**: Clubs, The Grounds, Ultimate Team [F 17]. Nota **9 (8-10)**, B.

### 8.4.18 Estabilidad y calidad técnica (área nueva)

- **Dinastía**: el banco termina en verde, pero las especiales tenían 8 fallos reproducibles del proyecto (capítulo 5); la auditoría estática registró 51 hallazgos (26 del motor, 25 de gestión, La Ruta y menús), de los que 16 se arreglaron el 16-11 (capítulo 9, §9.2); no se encontraron cuelgues en el camino normal (cap. 6 §6.8). Sonar con 0 avisos abiertos [D]. Nota **5 (4-6)**, A.
- **PES 2020**: producto comercial terminado [E]; no se revisaron incidencias técnicas. Nota **7 (6-8)**, C.
- **FC 27**: errores de lógica de la IA de traspasos reportados en la crítica [F 19]. Nota **7 (6-8)**, C.

---

## 8.5 Matriz de brechas

| # | Área | Dinastía | PES 2020 | FC 27 | Confianza (D / P / F) | Evidencia principal |
|---|---|---|---|---|---|---|
| 1 | Sensación de control | **3** (2-4) | 8 (7-9) | 7 (6-8) | B / A / A | cap. 4, 6 (M6-01, M6-06); [F 4][F 19][F 20] |
| 2 | IA y táctica | **4** (3-5) | 7 (6-8) | 6 (5-7) | B / B / B | cap. 5 (F-01), 6 (M6-02); [F 3][F 11][F 19] |
| 3 | Física del balón y reglamento | **4** (3-5) | 8 (7-9) | 7 (6-8) | A / B / C | cap. 6 (M6-04 a M6-07, M6-10, M6-17 a M6-20); [F 3][F 5] |
| 4 | Animación y cuerpos | **4** (3-5) | 8 (7-9) | 8 (7-9) | B / B / C | `MOTOR_LEAGUE_SOCCER_PLAN.md` §12; [F 3][F 10] |
| 5 | Jugadores y caras | **4** (3-5) | 8 (7-9) | 9 (8-10) | B / B / C | cap. 3 §3.5.2; [F 10][F 17] |
| 6 | Estadios, público y luz | **4** (3-5) | 8 (7-9) | 8 (7-9) | B / C / B | cap. 3 §3.5.2; `INFORME_SESION_2026-11-15.md`; [F 17] |
| 7 | Presentación TV | **3** (2-4) | 7 (6-8) | 9 (7-9) | B / B / C | resumen ejecutivo §2.5 |
| 8 | Audio y comentario | **4** (3-4) | 6 (5-7) | 8 (6-8) | B / A / C | [F 4][F 6] |
| 9 | Menús e interfaz | **5** (4-6) | 7 (6-8) | 6 (5-7) | B / B / A | cap. 5 (F-02); [F 16][F 20] |
| 10 | Gestión del club | **8** (6-8) | 6 (5-7) | 7 (6-8) | B / A / A | cap. 7; [F 3][F 4][F 17][F 19][F 20] |
| 11 | Modo jugador | **6** (4-7) | 5 (4-6) | 7 (6-8) | B / A / C | cap. 7 (R-01 a R-14); [F 4][F 14] |
| 12 | Contenido y licencias | **5** (4-6) | 6 (5-7) | 10 (9-10) | B / A / A | cap. 3 §3.5.2; [F 4][F 17] |
| 13 | Rendimiento modesto y móvil | **5** (4-6) | 8 (7-9) | 6 (5-7) | B / C / C | cap. 4; [F 1] |
| 14 | Accesibilidad e idiomas | **7** (6-8) | 5 (4-6) | 7 (6-8) | B / C / C | `COMPARATIVA_PES2020.md` |
| 15 | Monetización justa | **10** (9-10) | 6 (5-7) | 3 (2-4) | A / B / A | [F 17][F 20][F 27] |
| 16 | Modding y apertura | **5** (4-7) | 7 (6-8) | 2 (1-3) | B / B / C | [F 7] |
| 17 | Online | **0** | 6 (5-7) | 9 (8-10) | A / B / B | [F 17] |
| 18 | Estabilidad y calidad técnica | **5** (4-6) | 7 (6-8) | 7 (6-8) | A / C / C | cap. 5, 6, 7; [F 19] |

### 8.5.1 Agregados

| Agregado [E] | Dinastía | PES 2020 | FC 27 |
|---|---|---|---|
| Media simple de 18 áreas | 4,8 | 6,8 | 7,0 |
| Partido (áreas 1-8) | 3,8 | 7,5 | 7,8 |
| Menús (área 9) | 5,0 | 7,0 | 6,0 |
| Resto (áreas 10-18) | 5,7 | 6,2 | 6,4 |
| **Ponderada 60 / 25 / 15** | **4,4** | **7,2** | **7,1** |
| Ponderada, Dinastía en el extremo superior y referentes en el inferior | 5,2 | 6,2 | 6,0 |
| «Terreno propio» (áreas 10, 11, 13, 14, 15, 16) | 6,8 | 6,2 | 5,3 |

Cálculo: media de las notas centrales por grupo; la ponderada aplica 0,60 al grupo «partido», 0,25 a «menús» y 0,15 a «resto», la distribución del esfuerzo que propone el resumen ejecutivo [D: §0, punto 4]. La fila de sensibilidad usa los extremos de los intervalos de la matriz.

### 8.5.2 Lectura

1. **La brecha es del partido y es robusta.** En el grupo de ocho áreas del partido Dinastía está a unos 3,7 puntos de PES 2020 y a 4 de FC 27. Ni con los intervalos más favorables se cierra: 4,6 frente a 6,5 en el peor caso de los referentes [E: extremos de la matriz].
2. **Con la ponderación del proyecto, PES 2020 y FC 27 quedan prácticamente empatados** (7,2 y 7,1). Es coherente con la crítica: siete años después, FC no supera a PES 2020 en la media de los agregadores [F 2][F 18].
3. **En el terreno propio Dinastía ya va por delante sobre el papel** (6,8 frente a 6,2 y 5,3), pero ninguna de esas seis notas tiene confianza A salvo la monetización, y la de gestión y La Ruta descansan en diseño no probado por jugadores.
4. **Las dos áreas nuevas** (física y reglamento; estabilidad) muestran que una parte de la brecha no es de contenido ni de arte, sino de corrección: se cierra arreglando fallos ya localizados.

---

## 8.6 Brechas transversales

La matriz por áreas oculta cuatro brechas que atraviesan varias filas.

### 8.6.1 Brecha de sensación

Control (1), animación (4) y presentación (7) se perciben como una sola cosa: «el partido se siente bien o no». El capítulo 2 lo explica con la taxonomía de Pichlmair y Johansen [F 30]: **fisicidad** (inercia, giro, peso del balón: motor C4), **amplificación** (sonido del golpeo, cámara, red que se mueve) y **apoyo** (asistencias de pase, cambio de jugador, legibilidad en el móvil). Mejorar una fila sin las otras no cambia la percepción. Por eso el capítulo 9 agrupa en un mismo hito el perfil de manejo, el *warping* y la IK de pies y balón, y el sonido del golpeo.

### 8.6.2 Brecha de verificación

Todas las notas de jugabilidad de Dinastía dependen del dueño y de métricas automáticas. Las métricas automáticas miden lo que se les pide (goles, cadenas, duelos) en partidos de piloto automático con mitades de 240 s, no lo que siente una persona [D: `comparar_tres_motores_2026-11-11.md`]. Los fracasos recientes del género vienen de lanzar algo que el público leyó como inmaduro (eFootball 2022 [F 8][F 9]) o de cambiar la interfaz sin probarla con jugadores (FM25, FM26 [F 56][F 57]). Ningún área de la matriz pasará a confianza A sin probadores externos. Es la brecha de método más importante.

### 8.6.3 Brecha de corrección en las fronteras

Los capítulos 5 a 7 coinciden en un patrón: los fallos graves están en las fronteras que las pruebas no recorren —el descanso con el mismo motor, la carga desde disco, la frecuencia real del dispositivo, el orden de llamadas de la interfaz— y no en el camino normal [D: cap. 5 §5.7; cap. 6 §6.8; cap. 7 §7.7]. Un juego comercial se juega precisamente durante muchas temporadas, con cargas y descansos. Esta brecha afecta a las áreas 1, 2, 3, 10, 11 y 18.

### 8.6.4 Brecha de medición

El teléfono no se mide desde el ~4-11 y la latencia nunca se ha medido (capítulo 4). Mientras esto no cambie, la nota del área 13 es una estimación y el argumento de producto «corre en tu equipo modesto o tu teléfono» no puede sostenerse ante un tercero.

---

## 8.7 Dónde Dinastía ya gana

| Área | Ventaja | Condición para que sea real |
|---|---|---|
| Monetización | Sin pago, sin azar pagado; ventaja regulatoria en Brasil [F 27] | Mantenerla también en coleccionables y peluches (orden 14) y decirlo en la tienda |
| Gestión del club | Profundidad que ni PES ni FC ofrecen (finanzas con origen, política, instalaciones, cantera, prensa) [D] | Que la gestión se note en la cancha y en la narración; probarla con jugadores |
| Amplitud del mundo | 2.206 clubes, 147 ligas, 135 países [M] frente a >800 clubes y >35 ligas declarados por FC 27 [F 17] | Convertir volumen en calidad percibida (escudos, uniformes, estadios icónicos) y en modding |
| Accesibilidad | Nueve idiomas, daltonismo, contraste, remapeo [D] | Corregir textos sin traducir (R-12) |
| Modo jugador | Diseño de La Ruta con premios, rival y galas propias [D] frente a un modo «rancio» en PES 2020 [F 4] | Cerrar la economía de puntos (R-08) y el resto de fallos de La Ruta; prueba guiada de tres temporadas (cap. 7 §7.6.7) |
| Proceso de calidad | Banco, huellas, igualdad nativa, Sonar [D] | Cerrar los huecos del capítulo 5 (errores del registro, norma de líneas, oráculos) |

## 8.8 Dónde no debe competir

| Área | Motivo | Evidencia |
|---|---|---|
| Licencias | Decisión del dueño; FC 27 tiene más de 21.000 jugadores licenciados | [F 17]; orden 15 |
| Captura de movimiento propia | Coste fuera de alcance; no hay bases gratuitas de fútbol con licencia comercial | [F 54][F 55]; cap. 11 §11.10 |
| Fotogrametría de caras reales en lo público | Derecho de imagen | `CLAUDE.md`; cap. 2 §2.12 |
| Online competitivo | Decisión del dueño; requiere infraestructura y base de jugadores | resumen ejecutivo §3 |
| Espectáculo televisivo licenciado | Los éxitos pequeños recientes eligen otro terreno | [F 58][F 59][F 61]; cap. 2, I16 |

El capítulo 2 resume el patrón: Rematch eligió un formato donde la falta de licencias no importa y la sensación de control lo es todo; Sociable Soccer, la nostalgia arcade; Football Manager, la profundidad de gestión [F 58][F 59][F 61][F 62]. El terreno natural de Dinastía es la gestión profunda y el modo jugador, con un partido «suficientemente bueno y divertido».

---

## 8.9 Qué haría falta para superar a cada referente

Usando la misma ponderación (60/25/15) y las notas de la matriz [E]:

- **Superar a PES 2020 (7,2)** exige llevar el grupo del partido de 3,8 a unas 8,5 si las demás notas no cambian (0,6·x + 2,1 = 7,2), o a unas 7,0 si menús sube a 8 y el resto a 6,5 (0,6·x + 2,975 = 7,2). Con un partido en 7 (la meta 1.0 del resumen ejecutivo), menús en 8 y el resto en 6,5, la ponderada sería 7,2: un empate. **Superar a PES 2020 en conjunto requiere un partido de al menos 7 en las ocho áreas**, no solo en el control.
- **Superar a FC 27 en conjunto** con esta ponderación exige lo mismo; no es realista en caras, contenido ni presentación licenciada. Lo realista es **superarlo en el terreno propio**, donde ya está por delante sobre el papel, sin perder por goleada en el partido: el criterio del resumen ejecutivo («ganar a FC 27 en las filas propias sin perder por goleada en el partido») [D: §10].
- **El criterio del dueño** (diversión por encima del realismo, orden 38) no se puede evaluar en la matriz: exige la prueba ciega A/B/C que ya existe en el juego [D: `GUIA_PRUEBA_TELEFONO_2026-11-11.md`, parte 2] y probadores externos.

---

## 8.10 Amenazas a la validez

1. **Notas como juicio.** Las notas de los referentes proceden de reseñas y de documentos del proyecto; ninguno de los dos juegos se jugó para este informe.
2. **Asimetría de información.** De Dinastía se conocen los defectos con archivo y línea; de los referentes solo lo que la crítica cuenta. Esto tiende a penalizar a Dinastía en las áreas técnicas (18) y a favorecerla en las de diseño (10, 11), donde se juzga lo que el código ofrece y no lo que se siente.
3. **Marketing como evidencia.** Las notas de FC 27 en animación, caras y presentación descansan en parte en afirmaciones del editor [F 10] o en estimación.
4. **Medias de notas ordinales.** Los agregados ilustran perfiles; sus diferencias de décimas no son significativas.
5. **Ponderación del propio proyecto.** El 60/25/15 es una decisión de producto, no un hallazgo empírico. Con pesos iguales, la conclusión no cambia (4,8 frente a 6,8 y 7,0).

---

## 8.11 Conclusiones

1. **La brecha de Dinastía es la del partido**: 3,8 frente a 7,5 (PES 2020) y 7,8 (FC 27) en las ocho áreas del partido, robusta a la incertidumbre de las notas [E].
2. **Respecto al resumen ejecutivo**, la evidencia nueva baja la nota de FC 27 en IA (de 7 a 6) y en animación (de 9 a 8), sube la de su gestión (de 6 a 7), sube la de contenido de Dinastía (de 4 a 5, por la amplitud medida) y baja la de su modding (de 7 a 5, por no existir editor ni formato documentado).
3. **PES 2020 y FC 27 quedan casi empatados** con la ponderación del proyecto (7,2 y 7,1), igual que en la crítica (81 y 77) [F 2][F 18].
4. **Dinastía ya va por delante en su terreno** (monetización, gestión, modo jugador, accesibilidad, modding, equipos modestos) con un 6,8 frente a 6,2 y 5,3, pero con evidencia de diseño, no de juego.
5. **Hay cuatro brechas transversales**: sensación (un solo problema en tres filas), verificación (cero probadores), corrección en las fronteras y medición (teléfono y latencia). Las dos últimas son baratas de cerrar y condicionan todas las demás.
6. **Superar a PES 2020 en conjunto exige un partido de 7 en las ocho áreas**; superar a FC 27 en conjunto no es realista, pero sí en el terreno propio sin perder por goleada en el partido.
