# Capítulo 2. Estado del arte: simuladores de fútbol comerciales, sensación de control, animación, analítica y producción

Informe académico AAA de Dinastía · Fecha de redacción y de consulta de todas las fuentes: 16-11-2026.
Complementa a `docs/04_auditorias/INFORME_AAA_2026-11-16.md` (diagnóstico interno) y a `docs/04_auditorias/COMPARATIVA_PES2020.md` (notas por área). Este capítulo no repite sus cifras internas: aporta el marco externo, con fuentes verificables, contra el que esas cifras deben leerse.

---

## Resumen

Este capítulo revisa el estado del arte en seis frentes que condicionan la ambición de Dinastía de acercarse a la calidad percibida de un juego de fútbol AAA: (1) eFootball PES 2020 como referente declarado de jugabilidad; (2) la serie EA Sports FC (24 a 27) como referente comercial, incluida su monetización y la respuesta regulatoria a las cajas de botín; (3) la literatura de *game feel* y de latencia de entrada; (4) las técnicas de animación de personajes interactivos (*motion matching*, sus variantes aprendidas, el *warping* de animación usado en FIFA y la cinemática inversa procedural); (5) la analítica de fútbol aplicable a validar una IA de partido (xG, VAEP, PPDA, medias por partido, entornos de simulación de investigación); y (6) la economía de producción AAA frente a la de estudios pequeños, con casos recientes de éxito y de fracaso, y el inventario de recursos gratuitos con licencia comercial para animación y voz.

Se citan 68 fuentes. Cada cita lleva un nivel de verificación (L = leída directamente en la fuente primaria o en una página que la reproduce; E = verificada solo por el extracto que devuelve el buscador, sin acceso al texto completo). Las conclusiones más firmes son: la recepción crítica de la serie FC se ha estancado en torno a 76-80 de media de la crítica entre 2024 y 2026, con quejas recurrentes por la familiaridad, la interfaz recargada y la monetización de Ultimate Team; PES 2020 obtuvo 81-82 con elogios centrados en el partido y críticas centradas en todo lo que lo rodea (comentario, licencias, Liga Master estancada); la percepción de latencia motor-visual empieza en torno a los 26-40 ms en las personas más sensibles y la mediana se sitúa en 51-90 ms, mientras que la calidad de experiencia cae de forma significativa hacia los 190 ms; el *motion matching* y su versión aprendida tienen implementaciones de referencia con licencia MIT; los datos abiertos de StatsBomb **no** pueden explotarse comercialmente; y Brasil prohíbe desde marzo de 2026 las cajas de botín en juegos accesibles a menores, lo que convierte la ausencia de pago aleatorio en una ventaja de mercado concreta para un juego con ligas sudamericanas.

---

## 2.1 Introducción

### 2.1.1 Problema

El informe interno del 16-11 sitúa a Dinastía en torno a 4,6/10 frente a 7,1/10 de PES 2020 en una escala propia por áreas, con la brecha concentrada en el partido (jugabilidad, animación, presentación) y no en el contenido ni en la gestión. Ese diagnóstico se hizo con marcas «[C] conocimiento general no verificado» en buena parte de lo que dice sobre los competidores, y con una proyección explícita sobre FC 27, que salió después de la última revisión del equipo. Un informe de alcance académico necesita lo contrario: que cada afirmación externa sea rastreable.

### 2.1.2 Objetivos del capítulo

1. Sustituir las afirmaciones «[C]» sobre PES 2020 y la serie FC por datos con fuente, y separar en FC 27 lo **verificado** (publicado por EA o por la crítica tras el lanzamiento del 24-25 de septiembre de 2026) de lo **anunciado**.
2. Reunir la literatura que permita convertir la «sensación de control» en algo medible, como propone el informe interno (§5.1), con umbrales tomados de estudios experimentales y no de la intuición.
3. Identificar técnicas de animación cuyo coste encaja en un estudio sin captura de movimiento, y cuyas implementaciones de referencia tengan una licencia compatible con un juego comercial.
4. Establecer cifras de referencia de fútbol real para validar la IA del partido, y revisar qué fuentes de datos se pueden usar legalmente para ello.
5. Situar el proyecto en la economía real del sector: cuánto cuesta un AAA, qué han conseguido equipos pequeños, y qué fracasos recientes enseñan algo aplicable.
6. Inventariar recursos gratuitos de animación y de voz sintética cuya licencia permita distribución comercial, de acuerdo con la orden 57 del dueño (solo contenido gratuito con licencia comercial; nada NC).

### 2.1.3 Alcance

El capítulo es descriptivo y comparativo. No evalúa Dinastía jugando (eso corresponde a otros capítulos y a la prueba del dueño), y no ofrece asesoría jurídica: las secciones sobre licencias y regulación describen lo que dicen las fuentes y señalan dónde hace falta una revisión profesional antes de publicar.

---

## 2.2 Metodología de búsqueda

### 2.2.1 Estrategia

Se usó un buscador web general con consultas en inglés (la mayoría de las fuentes primarias lo están) y lectura directa de páginas cuando el servidor lo permitía. Para los artículos académicos se descargaron los PDF disponibles en repositorios de autor o de institución y se leyó el texto completo con una herramienta de extracción. Las consultas se agruparon por los seis temas del encargo; para cada afirmación relevante se buscó primero la fuente primaria (página del editor, nota de prensa, ficha oficial del congreso, artículo publicado) y, solo si no estaba accesible, una fuente secundaria reputada.

### 2.2.2 Criterios de inclusión

- **Juegos comerciales**: páginas oficiales de Konami y EA; agregadores de crítica (OpenCritic, Metacritic vía Wikipedia); reseñas firmadas de medios con línea editorial reconocida.
- **Literatura técnica**: artículos revisados por pares (ACM, IEEE, Springer, PLOS, Collabra) y sesiones de la Game Developers Conference con ficha en GDC Vault.
- **Datos y regulación**: documentos oficiales (gobierno del Reino Unido, gobierno de Australia, tribunales neerlandeses según la prensa especializada), acuerdos de licencia leídos en su texto.
- **Exclusión**: páginas generadas automáticamente, foros sin autor identificable (salvo para señalar una contradicción), y cualquier cifra que solo apareciera en una fuente sin corroborar.

### 2.2.3 Niveles de verificación

Varias páginas importantes devolvieron errores de acceso (403, 503, 530) o llegaron truncadas: la reseña de GameSpot de PES 2020, la de PC Gamer, la de GamesRadar+, la página de preguntas frecuentes de Mixamo en Adobe, la de la base de datos de captura de movimiento de Carnegie Mellon y la ficha de la reseña de Trusted Reviews. Para no ocultarlo, cada entrada de la bibliografía lleva una marca:

- **L**: contenido leído en la fuente (o en un agregador que reproduce el dato, como OpenCritic para las notas).
- **E**: contenido verificado solo a través del extracto devuelto por el buscador. Se usa para hechos sencillos (fechas, títulos, cifras) y se evita para interpretaciones.

Ninguna cita de este capítulo procede de memoria. Cuando un dato del encargo no se pudo verificar, se dice en §2.12.

### 2.2.4 Límites conocidos del método

- Sesgo de idioma: casi todas las fuentes están en inglés; la crítica en español, italiano o portugués no se revisó de forma sistemática.
- Sesgo temporal: para FC 27 solo han pasado siete semanas desde el lanzamiento; las notas de agregadores pueden moverse.
- Las cifras de jugadores de títulos con suscripción (Game Pass, EA Play) no son ventas.

---

## 2.3 eFootball PES 2020: el referente de jugabilidad

### 2.3.1 Ficha y recepción

PES 2020 fue desarrollado por PES Productions y publicado por Konami el 10 de septiembre de 2019 (12 de septiembre en Japón), con el Fox Engine en PC y consolas y Unreal Engine 4 en móviles; fue la última entrega con la marca «PES» antes del paso a eFootball [1]. En Metacritic obtuvo 82/100 en PS4 y Xbox One y 81/100 en PC [1]. OpenCritic le asigna una media de la crítica de 81 sobre 71 reseñas, con un 79 % de recomendación; GameSpot le dio 9/10 e IGN 8,3/10, y Eurogamer lo reseñó sin nota numérica [2]. La franquicia acumulaba 106,8 millones de copias a finales de septiembre de 2019 y la versión móvil superó los 300 millones de descargas en junio de 2020 [1].

La lectura que interesa a Dinastía no es la nota en sí, sino su reparto. El titular de la reseña de The Irish Times resume el consenso: «Mastery on the pitch, but frustrating off it» [4]. El autor, David Gorman, escribe que PES 2020 tiene el equilibrio «tan bien como cualquier videojuego de fútbol que se haya hecho», que el pase es preciso y depende del tiempo de ejecución, y que el tiro lejano se convirtió en una vía de gol más legítima; en cambio, califica el comentario de «monótono», señala que los cánticos de la grada rara vez hacen sentir un partido real, y que Become a Legend «se ha quedado rancio» [4]. GamesRadar+ tituló su reseña con la frase «una réplica fiel del juego bonito… el PES más realista hasta la fecha» [5].

### 2.3.2 Sistemas de jugabilidad declarados por Konami

La página oficial del producto enumera las novedades del partido [3]:

- **Finesse Dribble**: técnica avanzada para «serpentear entre defensores con una agilidad excepcional», desarrollada en consulta con Andrés Iniesta y activada con el stick derecho [3]. Varias reseñas la describieron como la principal novedad jugable; una la consideró difícil de dominar pero útil una vez entendida (extractos de [5] y de otras reseñas; nivel E).
- **Control del balón (trapping)**: el jugador elige la técnica de recepción según su estilo y la situación; Konami afirma que los futbolistas muestran «mayor inteligencia al interactuar con un balón que se acerca» [3]. Las recepciones nuevas incluyen el *No Touch Control* (correr junto al balón sin tocarlo) y el *Trick Trap* (amagar el control hacia un lado y salir por el otro) (extracto de la ficha oficial, nivel E sobre los nombres).
- **Precisión de golpeo según la postura**: la precisión de cada tiro y pase «cambia en función de cómo esté colocado el jugador en el campo» [3].
- **Defensa**: animaciones nuevas de entrada en plancha, despejes de cabeza mejores y la opción de **falta intencionada** como último recurso [3].
- **Física del balón y primer toque**: «las interacciones del primer toque se representan ahora con mucho más realismo» [3].
- **Inspire**: los compañeros reaccionan al estilo del jugador con balón; cuando un creador conocido conduce, «sus compañeros se colocan de forma más agresiva» [3].

Sobre el término «Kinetic Flow» que figura en el encargo: no aparece en la ficha oficial, en Wikipedia ni en las reseñas consultadas, y una búsqueda específica no encontró ningún sistema con ese nombre ni en Konami ni en EA (§2.12).

### 2.3.3 Liga Master

Konami describe tres cambios: un sistema de diálogos interactivos que hace avanzar el modo según las respuestas, un algoritmo de traspasos «basado en una rica biblioteca de datos reales» de fichajes y salarios, y la posibilidad de usar como avatar a entrenadores célebres [3]. Wikipedia añade que el modo ganó escenas en reuniones de cuerpo técnico, entrenamientos y ruedas de prensa, y objetivos ligados a las respuestas [1].

La crítica fue mixta. The Irish Times valoró las escenas y unas negociaciones más realistas, pero observó que las respuestas en rueda de prensa no parecen afectar al rendimiento del equipo y que los retirados «regenerados» rompen la inmersión tras unas temporadas [4]. Según los extractos de GameSpot, el modo es más disfrutable pero «sigue atrapado en el mismo patrón de espera de hace años»; Gamingbolt pidió una reinvención y Gamereactor dijo que había cambiado poco (todos nivel E). La conclusión, coherente con la comparativa interna, es que la gestión era la parte más débil del referente de jugabilidad, y que las mejoras que se notaron fueron las de **traspasos** y **escenas**, no las de estructura.

### 2.3.4 Licencias, comentario y modding

PES 2020 compensó la falta de licencias de liga con acuerdos exclusivos: The Irish Times señala la exclusiva de la Juventus, casi todas las selecciones UEFA licenciadas y el patrocinio oficial de la Euro 2020 [4]. El comentario de Peter Drury y Jim Beglin fue la crítica de presentación más repetida; según los extractos, GamesRadar+ lo calificó de «anticuado», Culture Vultures de «tan aburrido como siempre» y Cubed3 señaló que se añadieron «muy pocas frases nuevas» [5][6] (nivel E).

La comunidad suplió las licencias con *option files*: archivos que el jugador descarga y carga desde un USB en la carpeta `WEPES` mediante el menú de edición (Editar → Importar/Exportar → Importar equipo) y que restauran nombres, uniformes y escudos; las guías indican que en Xbox One no era posible y que el contenido importado solo lo ve quien lo instala [7] (nivel E). Es un precedente directo de la estrategia del proyecto (`pack_real.json`, `caras_reales.pck` fuera de la distribución pública): el editor más una vía de importación de datos de la comunidad sostuvo durante años a una serie sin licencias completas.

### 2.3.5 El contraejemplo: eFootball 2022

El sucesor gratuito de PES, eFootball 2022, se lanzó a finales de septiembre de 2021 y en 24 horas acumuló más de 11.500 reseñas en Steam con solo un 9 % positivas; PC Gamer matizó que parte de la reacción tenía rasgos de *review bombing* [8] (nivel E). Konami pidió disculpas el 1 de octubre de 2021 y prometió actualizaciones de equilibrio en velocidad de pase y defensa [9] (nivel E). La lección es de producción, no de diseño: una base jugable sólida (PES 2020) no protege de una salida que el público percibe como «una demo».

---

## 2.4 EA Sports FC (24-27): el referente comercial

### 2.4.1 FC 24: HyperMotion V y PlayStyles

En la presentación del 18 de julio de 2023, EA describió HyperMotion V como un sistema que usa «datos volumétricos de más de 180 partidos profesionales masculinos y femeninos», con 1.200 estilos de carrera característicos [10]. Los **PlayStyles** se presentaron como habilidades distintivas derivadas de datos reales de partido de Opta «y otras fuentes»; los **PlayStyles+** elevan una habilidad al nivel de élite (el ejemplo era el tiro potente de Haaland) [10]. El mismo anuncio atribuía al motor Frostbite mejorado con la tecnología de personajes SAPIEN unos modelos «diez veces más precisos anatómicamente» [10]. Conviene leer estas cifras como lo que son: afirmaciones de marketing del editor, no mediciones independientes.

La idea de diseño que sí es transferible es la de los PlayStyles: **comportamientos discretos y nombrados** que hacen que dos jugadores con la misma media se sientan distintos. Es más barata que una animación nueva por jugador y comunica mejor al jugador por qué algo salió bien.

### 2.4.2 FC 25: FC IQ, roles y Rush

El análisis oficial de FC IQ (21 de agosto de 2024, Thomas Caleffi y otros) lo define como «el nuevo sistema táctico y posicional central de EA SPORTS FC 25», con tres componentes: **Roles de jugador**, **Tácticas de equipo** y **Tácticas inteligentes** [11]. Datos concretos:

- 31 roles con 1-3 «focos» cada uno, 52 combinaciones en el lanzamiento; los roles gobiernan el comportamiento sin balón [11].
- Tres niveles de familiaridad: rol base (competente), Rol+ (destacado) y Rol++ (de clase mundial); «todo jugador de FC 25 tiene al menos un Rol+». Fuera de posición se marca con un aviso amarillo y un rol simplificado [11].
- La familiaridad la asigna un modelo de IA «alimentado con datos reales» y pesa entre el 10 % y el 40 % de los cálculos de colocación según el contexto [11].
- Las tácticas se construyen con formación, enfoque defensivo (Bajo, Equilibrado, Alto, Agresivo) y estilo de salida (Pase corto, Equilibrado, Contraataque); hasta cinco tácticas personalizadas [11].
- Las Tácticas inteligentes son sugerencias en tiempo real según el marcador, el minuto, las expulsiones, la posesión y el xG, aplicables con la cruceta [11].
- Se eliminaron el ritmo de trabajo (*work rate*), las instrucciones individuales, la posición de mediapunta (CF) y los carrileros (LWB/RWB) [11].

**Rush** es un modo 5 contra 5 con porteros controlados por la IA, en el que se juega con hasta tres amigos o en solitario con emparejamiento; sus recompensas se pueden usar en el Ultimate Team de 11 contra 11 [12] (nivel E).

La recepción de FC 25 fue la más floja de las tres entregas revisadas: media de la crítica de 76 sobre 93 reseñas, 63 % de recomendación, IGN 6/10, GameSpot 6/10, Eurogamer 3/5, con el consenso «sólido pero demasiado familiar» [13]. Rush fue lo más elogiado; GamesRadar+ habló de un modo «brillante», y la queja más extendida fue la apatía hacia el modo Carrera [14] (nivel E).

### 2.4.3 FC 26: dos ajustes de jugabilidad

Las notas de diseño del 22 de julio de 2025 introdujeron un cambio de enfoque interesante para Dinastía: dos **presets** de jugabilidad. El *Competitivo* está ajustado para «mayor respuesta y control», pensado para el juego en línea; el *Auténtico*, para «mayor realismo y un tempo de partido fiel a la realidad» en los modos sin conexión como Carrera [15] (nivel E). EA volvió a tres tipos de aceleración «para un ritmo de juego más predecible», eliminó el regate ágil por su bajo uso y para hacer más coherente la protección del balón, y retocó el posicionamiento y la toma de decisiones de los porteros [15] (nivel E).

FC 26 fue la entrega mejor recibida de las revisadas: media de 80 sobre 112 reseñas, 80 % de recomendación, IGN 7/10, GameSpot 8/10. El consenso de OpenCritic elogia el juego más afilado, los dos estilos diferenciados y la IA mejorada, y critica la interfaz recargada, la monetización agresiva de Ultimate Team y la progresión familiar [16].

### 2.4.4 FC 27: lo verificado y lo anunciado

**Verificado (nota de prensa oficial del 23 de julio de 2026 y reseñas posteriores al lanzamiento):**

- Lanzamiento mundial el 25 de septiembre de 2026, con acceso anticipado desde el 18 de septiembre para las ediciones Ultimate y Ultimate Plus; plataformas PS5, PS4, Xbox Series X|S, Xbox One, PC, Switch y Switch 2 [17]. OpenCritic registra el 24 de septiembre como fecha de salida [18].
- Novedades declaradas: **The Grounds**, un «patio de fútbol social» con tres distritos, solo en plataformas de nueva generación y que amplía Clubs; un **mercado de traspasos de Carrera reconstruido**; la **Galería** de Ultimate Team para coleccionar series y calificar cartas; córners dinámicos, «mayor conciencia ofensiva», «defensa de la IA reequilibrada» y «control y fluidez mejorados» [17].
- Contenido declarado: más de 21.000 jugadores, más de 800 clubes y selecciones, más de 130 estadios y más de 35 ligas [17]. La edición Ultimate Plus incluye hasta 10.000 FC Points en cinco entregas mensuales y pases premium de las temporadas 1 a 5 [17].
- Recepción a 16-11-2026: media de la crítica de 77 sobre 84 reseñas, 64 % de recomendación; Eurogamer 3/5, IGN 7/10 [18]. La frase de IGN recogida por el agregador es que la serie «sigue buscando el equilibrio entre innovar y hacer que el juego base funcione» [18].
- Game Informer (Matthew Kato, 25-09-2026, 7,25/10): la defensa exige más control manual («el control manual de tus defensores está mejor recompensado»), los pases al hueco piden más puntería, las carreras curvas mantienen al delantero en posición legal; pero los compañeros de la IA «a veces hacen tonterías», el cambio de jugador es frenético, The Grounds es «nuevo pero viejo», y en Carrera los jugadores de la IA piden el traspaso aunque el club comprador no les interese, sin que se pueda bloquear [19].
- Stadion Gaming (Luka Perić, 26-09-2026, 7/10): el cambio se nota «en diez minutos»; los centros vuelven a importar porque los porteros son más débiles en los córners; la entrada es más física y menos guionizada; Carrera es lo mejor del paquete; pero el camino más rápido a un gran equipo en Ultimate Team «sigue pasando por la cartera», el cambio de jugador «se vuelve loco» en las melés del área y The Grounds es «sobre todo un menú con tiendas de cosméticos» [20].

**Anunciado o sin confirmar:** una beta cerrada del 5 al 25 de agosto fue publicada por un medio pero no confirmada por EA, y el alcance completo de las licencias y de The Grounds no estaba confirmado en las primeras coberturas (extractos de búsqueda, nivel E). Este capítulo no usa esas afirmaciones.

### 2.4.5 Tabla comparada de recepción

| Juego | Media crítica (OpenCritic) | Recomiendan | IGN | GameSpot | Eurogamer | Fuente |
|---|---|---|---|---|---|---|
| PES 2020 (2019) | 81 (71 reseñas) | 79 % | 8,3 | 9 | sin nota | [2] |
| FC 25 (2024) | 76 (93) | 63 % | 6 | 6 | 3/5 | [13] |
| FC 26 (2025) | 80 (112) | 80 % | 7 | 8 | — | [16] |
| FC 27 (2026) | 77 (84) | 64 % | 7 | — | 3/5 | [18] |

Lectura: siete años después, el referente comercial no ha superado en la crítica al PES de 2019, y su mejor año reciente coincide con el que separó un ajuste «auténtico» de uno «competitivo». La crítica a FC no se dirige a los gráficos ni a las licencias (donde no tiene rival) sino a la **familiaridad**, la **interfaz**, la **IA de los compañeros** y la **monetización**. Son los frentes en los que un proyecto pequeño puede competir.

### 2.4.6 Monetización: el peso económico de Ultimate Team

El formulario 10-K del ejercicio fiscal 2025 de Electronic Arts declara reservas netas de servicios en vivo de 5.338 millones de dólares (−2 % interanual) sobre un total de 7.355 millones, y atribuye parte de la caída a menores ventas de contenido extra de Ultimate Team en la franquicia de fútbol [21] (nivel E). El mismo documento muestra que el fútbol americano (College Football 25) superó los 1.000 millones en reservas, un 70 % más [21] (nivel E). No se encontró una cifra separada de Ultimate Team en fuentes públicas.

### 2.4.7 Regulación de las cajas de botín

**Bélgica.** En abril de 2018 la Comisión de Juego belga concluyó que las cajas de botín pagadas, incluidos los sobres de FIFA Ultimate Team, constituyen juego de azar según la ley existente, y recomendó acciones penales contra quien siguiera vendiéndolas; Valve y Blizzard las retiraron. EA dejó de vender FIFA Points en Bélgica en enero de 2019 [22]. La eficacia de la prohibición es discutida: un informe registrado de Leon Y. Xiao, publicado en *Collabra: Psychology* en 2023, concluye que la «prohibición» belga no se ha hecho cumplir de forma efectiva y que no puede recomendarse como modelo a otros países [23] (nivel E).

**Países Bajos.** La Autoridad de Juego neerlandesa impuso a EA una multa coercitiva de 500.000 € semanales con un tope de 10 millones, confirmada en primera instancia en octubre de 2020. En marzo de 2022 la Sección de lo Contencioso-Administrativo del Consejo de Estado la anuló: los sobres «no son un juego independiente» sino parte de un juego de habilidad, y por tanto no requieren licencia [24]. La sentencia no declara que las cajas de botín no sean dañinas; interpreta el ámbito de la ley de juego.

**Reino Unido.** La respuesta del Gobierno del 18 de julio de 2022 a su consulta reconoció una asociación entre cajas de botín y daños por juego, pero consideró «prematuro» legislar sin probar antes medidas de la industria, y pidió que los menores no puedan comprarlas sin aprobación parental; la guía de la industria (Ukie) se publicó en julio de 2023 [25] (nivel E).

**Australia.** Desde septiembre de 2024, los juegos con compras ligadas al azar (incluidas las cajas de botín pagadas) tienen una clasificación mínima M (orientativa) y los juegos con juego simulado, R18+ (vinculante) [26] (nivel E).

**Brasil.** La Ley 15.211/2025 (ECA Digital), promulgada el 17 de septiembre de 2025 y en vigor desde marzo de 2026, prohíbe en su artículo 20 las cajas de botín en juegos dirigidos a menores o de probable acceso por ellos; el decreto que la desarrolla permite como alternativa versiones sin cajas o con la función restringida por defecto [27] (nivel E). Es la medida más restrictiva de las revisadas y afecta a uno de los mercados de fútbol más grandes del mundo.

**Evidencia sobre daños.** Zendle y Cairns (PLOS ONE, 2018), con 7.422 jugadores, hallaron una relación entre el gasto en cajas de botín y la gravedad del juego problemático (η² = 0,054), sin poder establecer la dirección causal; los autores la replicaron en 2019 [28] (nivel E).

---

## 2.5 Sensación de control y latencia de entrada

### 2.5.1 Definiciones: game feel y «juice»

La referencia canónica es Steve Swink, *Game Feel: A Game Designer's Guide to Virtual Sensation* (CRC Press/Morgan Kaufmann, 2008; algunas fuentes citan 2009), que define el *game feel* como «control en tiempo real de objetos virtuales en un espacio simulado, con interacciones enfatizadas por el pulido» [29][30]. La definición tiene tres componentes —control en tiempo real, espacio simulado y pulido— y su utilidad práctica es que separa lo que se mide (el control) de lo que se decora (el pulido).

Pichlmair y Johansen revisaron más de 200 fuentes académicas y profesionales en *Designing Game Feel: A Survey* (IEEE Transactions on Games, 14(2), 2022) y propusieron tres dominios de experiencia —**fisicidad**, **amplificación** y **apoyo**— con tres prácticas de pulido asociadas: **ajuste** (*tuning*), **jugo** (*juicing*) y **racionalización** (*streamlining*). El ajuste crea cohesión y predictibilidad en los objetos del juego; el jugo da una retroalimentación más clara [30].

El término «juice» se popularizó con la charla «Juice It or Lose It» de Martin Jonasson y Petri Purho (Independent Games Summit, GDC Europe 2012), que demostró en directo cómo pequeños efectos audiovisuales hacen más satisfactorio un juego simple [31] (nivel E). La investigación empírica posterior matiza el entusiasmo: Hicks, Gerling, Dickinson y Vanden Abeele (CHI PLAY 2019) estudiaron el efecto de los adornos visuales sobre la experiencia y discuten cuándo su integración ayuda [32] (nivel E; no se pudieron verificar sus tamaños de efecto).

Para un juego de fútbol, la taxonomía de Pichlmair y Johansen es útil porque los tres dominios se corresponden con tres equipos de trabajo distintos: **fisicidad** = inercia, giro, aceleración, peso del balón (motor C4); **amplificación** = sonido del golpeo, vibración, cámara, red que se mueve; **apoyo** = asistencias de pase, ayudas al cambio de jugador, legibilidad en el móvil.

### 2.5.2 Latencia: umbrales experimentales

Los estudios disponibles distinguen tres cosas que se confunden a menudo: el umbral de **detección**, el umbral a partir del cual cae la **calidad de experiencia** y el umbral a partir del cual cae el **rendimiento**.

**Detección.** Raaen, Eg y Griwodz (NetGames 2014) pidieron a los participantes que ajustaran el retardo entre pulsar un botón y un cambio visual simple. Los más sensibles percibieron retardos de 26-40 ms; la mediana de detección quedó en 51-90 ms, y una minoría no percibía retrasos menores de 97-182 ms [33] (L). En un experimento de discriminación posterior con 51 participantes (botón y disco giratorio, retardos de 0 a 500 ms, con unos 50 ms de retardo propio del sistema), el mismo grupo situó el punto en que detectar y no detectar son igual de probables cerca de 200 ms, con grandes diferencias individuales [34] (L).

**Calidad de experiencia y rendimiento.** Eg, Raaen y Claypool (QoMEX 2018) hicieron jugar a 51 personas a interceptar un objetivo que rebota con el ratón, con retardos totales de 40 a 440 ms. El rendimiento empeoró de forma creciente con el retardo y la valoración media de la experiencia empezó a bajar hacia los 140 ms, de forma significativa a los 190 ms; ni la habilidad declarada ni la experiencia con otras actividades temporales explicaron el rendimiento, salvo la práctica musical [35] (L).

**Tolerancia por tipo de juego.** Claypool y Claypool (*Communications of the ACM*, 2006) clasificaron las acciones según su precisión y su plazo, y la perspectiva del jugador. Su tabla resumen asigna a los juegos con avatar en tercera persona —el ejemplo es un juego deportivo, Madden NFL— una sensibilidad «media» y un umbral de 500 ms de latencia **de red** antes de una caída significativa del rendimiento, frente a 100 ms para primera persona y 1.000 ms para juegos omnipresentes como la estrategia [36] (L, versión de informe técnico).

**Interpretación para un juego de fútbol.** Las cifras de Claypool se refieren a la latencia de red en juego en línea y al **rendimiento**; las de Raaen y Eg, a la latencia local y a la **percepción**. Para la sensación de control de un partido sin conexión, la referencia relevante es la segunda: la mitad de los jugadores percibe retrasos por encima de unos 51-90 ms, y la experiencia se degrada claramente hacia los 140-190 ms. El objetivo interno de Dinastía (≤ 2 cuadros, ≤ 33 ms entre la entrada y el cambio de estado del motor; `INFORME_AAA` §5.1) está por debajo incluso del umbral de los más sensibles, pero mide solo un tramo de la cadena. La latencia total que percibe el jugador suma además la cola de entrada, el cuadro de simulación, la animación hasta el primer cuadro visible, el *render*, la sincronía vertical y el retardo de la pantalla; en un televisor o un móvil esa suma puede superar fácilmente los 100 ms.

### 2.5.3 Cómo lo resuelven los juegos de fútbol comerciales

La literatura técnica pública de EA muestra que el conflicto central de un juego de fútbol no es la latencia del sistema sino la **latencia de animación**: el tiempo que tarda un cuerpo capturado en movimiento en obedecer. McComas y Sanmiya (GDC 2010, «Animation Warping for Responsiveness in FIFA Soccer») explicaron cómo FIFA alteraba de forma procedural las animaciones de giro, en tiempo real, para hacerlas más reactivas, y cómo extendían la técnica a cualquier animación que tuviera que llegar a una posición concreta en un instante concreto; la charla termina comparando el *warping* con la mezcla clásica [37] (L). Es el mismo problema que el informe interno describe como «locomoción poco natural» y «pases sin peso» en el motor C4: si el cuerpo obedece al instante parece de goma; si espera a la animación parece lento. El *warping* es la técnica documentada para tener las dos cosas.

---

## 2.6 Animación de personajes interactivos

### 2.6.1 Motion matching

Simon Clavet (Ubisoft Montreal) presentó en la GDC 2016 «Motion Matching and The Road to Next-Gen Animation», la técnica usada en *For Honor*. En lugar de construir a mano máquinas de estados con clips de transición, el equipo graba varios minutos de captura de movimiento, los importa casi sin tocar y marca solo la lógica que no se puede inferir (tipos de ataque, guardias); en tiempo de ejecución el sistema busca de forma continua en toda la base de datos el cuadro que mejor encaja con la pose actual y con la trayectoria futura deseada, y mezcla brevemente hacia él. El resultado parece captura de movimiento casi en bruto y sigue respondiendo al mando [38] (L). Las coberturas japonesas de la charla subrayan su contrapartida: necesita mucha captura y sesiones periódicas para rellenar huecos (extracto, nivel E).

EA aplicó la idea a interacciones entre varios personajes. Henry Allen (GDC 2021, «Environmental and Motion Matched Interactions; Madden, FIFA and Beyond!») presentó el sistema genérico de interacciones multipersonaje de EA con ejemplos de Madden y FIFA, y dos formas de combinar *motion matching* con interacciones manteniendo el control: usar *motion matching* de un personaje para que la entrada en una animación conjunta sea creíble, y *motion matching* sincronizado entre varios personajes [39] (L). Es la línea técnica detrás de los duelos hombro con hombro que el informe interno echa de menos.

### 2.6.2 Motion matching aprendido y redes con función de fase

Holden, Kanoun, Perepichka y Popa (*Learned Motion Matching*, ACM Transactions on Graphics 39(4), SIGGRAPH 2020) descomponen el *motion matching* en sus pasos y sustituyen tres de ellos por redes neuronales entrenadas. El sistema conserva la calidad, el control y la rapidez de iteración del método original, pero no necesita guardar en memoria la animación ni los metadatos de búsqueda: el uso de memoria deja de crecer linealmente con la cantidad de datos [40] (L). El código de ejemplo del autor está publicado con **licencia MIT** (Daniel Holden, 2021) [41] (L), lo que lo hace utilizable en un producto comercial.

La generación anterior, *Phase-Functioned Neural Networks for Character Control* (Holden, Komura y Saito, ACM TOG 36(4), SIGGRAPH 2017), genera en cada cuadro los pesos de una red de regresión a partir de una variable de fase del ciclo de paso [42] (nivel E). Su código y datos se publicaron para uso **académico y no comercial** según el repositorio de referencia (nivel E), por lo que no cumple la orden 57.

### 2.6.3 Animación procedural para equipos pequeños

David Rosen (Wolfire Games) presentó en el Animation Bootcamp de la GDC 2014 «An Indie Approach to Procedural Animation»: técnicas sencillas para conseguir animación interactiva y fluida con muy pocos fotogramas clave, con ejemplos de *Overgrowth*, *Receiver* y *Black Shades* [43] (nivel E). Es el enfoque más próximo a la situación de Dinastía: pocas animaciones (296 de League-Soccer y unas 25 propias según el informe interno) y mucho trabajo procedural para esconderlo.

### 2.6.4 Cinemática inversa en el motor del proyecto

Godot 4.6 (enero de 2026) reintrodujo la cinemática inversa sobre el `SkeletonModifier3D` renovado, con la clase base `IKModifier3D` y una familia de resolutores: `TwoBoneIK3D` y `SplineIK3D` (siempre deterministas) e iterativos como `FABRIK3D`, `CCDIK3D` y `JacobianIK3D` (deterministas o no según las opciones), además de restricciones de giro y de velocidad angular [44] (nivel E). Dinastía usa Godot 4.7.2 y por tanto los tiene disponibles. La propiedad de determinismo de `TwoBoneIK3D` es relevante para el proyecto, cuyo banco de pruebas depende de huellas reproducibles byte a byte: un pie que busca el balón con un resolutor determinista no rompe la reproducibilidad de un partido con semilla fija.

---

## 2.7 Analítica de fútbol aplicable a validar la IA

### 2.7.1 Por qué validar con datos reales, y hasta dónde

La orden 38 del dueño fija el criterio: **jugabilidad y diversión por encima de las cifras reales**. Eso no hace inútiles las cifras reales; cambia su papel. No son el objetivo, sino un **detector de anomalías**: un partido con 45 tiros, 0 faltas o 80 % de posesión sostenida en todos los encuentros indica un fallo de la IA aunque sea divertido una vez. La literatura ofrece tres tipos de referencia: métricas de calidad de ocasión (xG), métricas de valor de cada acción (VAEP) y métricas de estilo (PPDA), además de las medias de liga.

### 2.7.2 Goles esperados (xG)

Un modelo de xG asigna a cada tiro la probabilidad de gol según sus características. La práctica estándar es una regresión logística sobre la distancia y el ángulo a la portería, con el tipo de remate (cabeza o pie) como variable relevante; la distancia suele ser la característica dominante (extractos de varias fuentes, nivel E). Robberechts y Davis (KU Leuven; *Machine Learning and Data Mining for Sports Analytics*, Springer CCIS 1324, 2020) estudiaron cuántos datos necesita un modelo de xG: usar datos antiguos apenas empeora el resultado, los modelos por liga no mejoran de forma apreciable, y no conviene mezclar proveedores de datos porque cambian las distribuciones [45] (nivel E).

Para un juego, la consecuencia práctica es que un xG sencillo de distancia, ángulo y cabeza basta para clasificar las ocasiones que genera la IA, y que se puede calcular sobre los propios partidos simulados: si la conversión real de Dinastía está muy por encima de su xG, los porteros o los remates están desajustados; si está muy por debajo, los tiros son de mala calidad o el portero es imbatible.

### 2.7.3 Valor de las acciones (VAEP)

Decroos, Bransen, Van Haaren y Davis («Actions Speak Louder than Goals: Valuing Player Actions in Soccer», KDD 2019, premio al mejor artículo de ciencia de datos aplicada) observaron que tiros y goles son menos del 2 % de las acciones con balón, y propusieron valorar cada acción por el cambio en la probabilidad de marcar menos el cambio en la probabilidad de encajar [46] (nivel E). Es una herramienta potente para la IA de decisión con balón: permite comparar si un pase atrás de la CPU era razonable o un error, más allá del resultado.

### 2.7.4 Intensidad de presión (PPDA)

Colin Trainor definió en StatsBomb (2014) el PPDA como los pases permitidos al rival divididos por las acciones defensivas propias en una zona del campo (en su versión, más allá del 40 % propio); cuanto menor, más intensa la presión. Las acciones defensivas incluyen duelos ganados, entradas, intercepciones y faltas, y se cuentan tengan éxito o no, por lo que el PPDA mide la intensidad, no la eficacia, de la presión [47] (nivel E). En un juego con estilos tácticos (como el de FC 25, con enfoques Bajo/Equilibrado/Alto/Agresivo [11]) el PPDA es la forma más barata de comprobar que una «presión alta» se comporta de verdad distinto de un «bloque bajo».

### 2.7.5 Medias de referencia

La Premier League 2023-24 cerró con 3,28 goles por partido (1.246 en 380), la primera temporada de su historia por encima de tres, con un xG sin penaltis de 3,2 por partido, un 14 % más que la anterior y un 23 % más que la media de las siete previas [48] (L). A mitad de temporada (283 partidos), Opta Analyst registraba [49] (L):

| Métrica por partido (ambos equipos) | 2023-24 (parcial) | Comparación |
|---|---|---|
| Goles | 3,24 | 2,85 en 2022-23; 2,82 en 2021-22 |
| Tiros | 27,2 | 25,3 en 2022-23; 25,7 en 2021-22 |
| xG | 3,13 | goles 0,11 por encima del xG |
| Conversión de tiro | 11,9 % | 11,3 % en 2022-23 |
| Penaltis | 0,28 | — |
| Tiros dentro del área | 18,4 | media desde 2003-04: 15,3 |
| Tiros fuera del área | 9,0 | media desde 2003-04: 11,3 |
| Distancia media del tiro | 14,9 m | −0,5 m en dos temporadas |
| Remates de cabeza | 4,0 | estable desde 2003-04 |
| Tiempo de balón en juego | 58 min 25 s | — |
| Goles tras pérdida alta | 0,33 | 0,25 en 2022-23 |

Dos lecturas metodológicas. Primera: una sola liga y una sola temporada no definen «el fútbol»; 2023-24 fue atípica por arriba, y 2022-23 da 2,85 goles. Segunda: la tendencia (menos tiros lejanos, más dentro del área, tiros más cercanos) es exactamente la que una IA de decisión con balón debe reproducir para parecer moderna.

### 2.7.6 Fuentes de datos y sus licencias

**StatsBomb Open Data.** El repositorio público ofrece eventos de competiciones seleccionadas y datos 360 de algunos partidos [50] (L). Su acuerdo de usuario, leído en el texto completo, lo define como «herramienta de investigación» y prohíbe expresamente distribuir o reproducir los datos a terceros y «explotar comercialmente los datos o cualquier análisis derivado del uso del Servicio», además de exigir el logotipo de StatsBomb en cualquier publicación de análisis [50] (L). Para un juego comercial esto es determinante: **no** se pueden incluir esos datos en el juego ni, según una lectura prudente, usar análisis derivados de ellos para calibrarlo. Cualquier uso exigiría consulta jurídica o permiso.

**FBref.** El 20 de enero de 2026 Sports Reference retiró de FBref las estadísticas avanzadas con efecto inmediato, después de que Stats Perform (Opta) cancelara su acceso alegando un incumplimiento de contrato [51] (nivel E). La fuente gratuita más usada por aficionados para xG y métricas avanzadas de las cinco grandes ligas dejó de estar disponible; el informe interno, que cita «FBref/StatsBomb abiertos» como fuente de métricas objetivo (§5.3), debe actualizarse.

**Cifras agregadas publicadas.** Las medias de liga que publican la propia Premier League [48] y Opta Analyst [49] son hechos agregados citados en prensa; usarlas como banda de referencia en un banco de pruebas interno es un uso muy distinto de redistribuir una base de eventos. Aun así, la recomendación prudente es citarlas con su fuente y no reproducir tablas completas.

### 2.7.7 Entornos de simulación de investigación

Kurach y otros diez autores (Google Research) presentaron *Google Research Football: A Novel Reinforcement Learning Environment* (arXiv 1907.11180, julio de 2019; AAAI 2020, pp. 4501-4510): un simulador de fútbol en 3D basado en física, pensado para aprendizaje por refuerzo, con licencia abierta permisiva, soporte multijugador y multiagente, tres escenarios de partido completo de dificultad creciente (los *Football Benchmarks*), escenarios simples de entrenamiento (*Football Academy*) y resultados de referencia con IMPALA, PPO y Ape-X DQN [52] (L). El repositorio, con licencia Apache 2.0, indica que está basado en el juego de código abierto *Gameplay Football* de Bastiaan Konings Schuiling, y quedó **archivado en modo de solo lectura el 19 de agosto de 2026** [53] (L).

Para Dinastía, el interés no es el aprendizaje por refuerzo (caro y difícil de hacer divertido), sino dos ideas de diseño: (a) **escenarios académicos** aislados (un 3 contra 1, un contraataque, un córner) como pruebas unitarias de la IA, que es lo que el dueño pidió con la «arena de pruebas» (orden 22); y (b) **una IA de referencia de otro motor** contra la que medir la propia, del mismo modo que el comparador A/B/C de la orden 38.

---
## 2.8 Producción AAA frente a estudios pequeños

### 2.8.1 El orden de magnitud del gasto AAA

Las cifras de presupuesto de los juegos deportivos de EA y Konami no son públicas. La referencia documentada más citada del gasto AAA reciente procede de la filtración de documentos internos de Insomniac Games en diciembre de 2023, según la cual *Marvel's Spider-Man 2* costó unos 315 millones de dólares, y se proyectaban 385 millones para su secuela [54] (nivel E). Sobre la escala de los equipos, la página de empleo de EA describe el campus de EA Vancouver (Burnaby), centro de desarrollo de EA SPORTS FC, NHL y UFC, con unas 2.400 personas [55] (nivel E); la cifra es del campus entero, no del equipo de FC, y EA Romania (Bucarest) trabaja también en la franquicia. No se encontró ningún dato público fiable del número de personas que hacen FC.

Lo que estas cifras justifican es la tesis del informe interno (§1): de los rasgos que definen un AAA, los que dependen de dinero (captura de movimiento propia, licencias, fotogrametría, QA masivo) no son alcanzables, y los que dependen de criterio y horas (sensación de control, presentación, estabilidad, recorte de alcance) sí lo son.

### 2.8.2 Fracasos recientes de estudios con experiencia

**Football Manager 25.** El 7 de febrero de 2025, Sports Interactive y SEGA cancelaron FM25 semanas antes de su lanzamiento previsto en marzo, tras dos retrasos. El comunicado dice que «quedó inequívocamente claro que no alcanzaríamos el nivel requerido, incluso con el calendario ajustado» y que «la experiencia general del jugador y la interfaz no están donde tienen que estar»; el estudio consideró «la decisión equivocada» publicar y arreglar después, y devolvió las reservas [56] (L).

**Football Manager 26.** Salió el 4 de noviembre de 2025. Al día siguiente sus reseñas de Steam eran «mayormente negativas», con un 22 % positivas sobre más de 4.000, y las quejas se centraban en la nueva interfaz («torpe»), el rendimiento y cambios de juego decepcionantes [57] (L). La crítica profesional fue más benévola que los usuarios (extractos, nivel E).

**Football Manager 24**, en cambio, había batido el récord de la serie con 7 millones de jugadores en menos de 100 días (febrero de 2024) [58] (nivel E). La serie demuestra a la vez que un juego de **gestión** de fútbol puede ser un gran negocio sin partido en 3D de nivel AAA, y que **rehacer la interfaz** de un juego de gestión profundo es uno de los mayores riesgos de producción que existen, incluso para un estudio con treinta años de experiencia.

**eFootball 2022** (§2.3.5) completa el cuadro: Konami, con la mejor base jugable del género, lanzó algo que el público leyó como una demo y obtuvo un 9 % de reseñas positivas en Steam [8].

### 2.8.3 Éxitos recientes de alcance acotado

**Rematch** (Sloclap, autores de *Sifu*): fútbol 5 contra 5 en tercera persona, sin licencias reales, en el que cada jugador controla a un solo futbolista. Salió el 19 de junio de 2025 para PS5, Xbox Series y PC; superó el millón de unidades vendidas en el primer fin de semana y los 2,5 millones de jugadores totales (con Game Pass) [59] (L), y los 5 millones de jugadores únicos a finales de julio de 2025 [60] (nivel E). Sloclap no ha actualizado públicamente su cifra de ventas desde el primer millón (extracto, nivel E).

**Sociable Soccer 24** (Tower Studios, de Jon Hare, creador de *Sensible Soccer*): salió en Steam el 16 de noviembre de 2023 a 29,99 $, tras un acceso anticipado en 2017 [61] (nivel E); FourFourTwo lo describió como un fútbol arcade divertido que recuerda «todo lo que nos gustaba del género» de jóvenes [62] (nivel E). Su sucesor, *Sociable Soccer 25*, sustituyó a la edición 24 en la tienda (extracto, nivel E).

**Pro Soccer Online**: fútbol en línea en primera y tercera persona, «muy basado en la habilidad», publicado en acceso anticipado en Steam [63] (nivel E). Una nota de parche de su desarrollador principal reconoce que el juego llevaba tiempo estancado en actualizaciones (extracto, nivel E).

El patrón común es nítido: los éxitos pequeños de fútbol de los últimos años **no compiten con FC en lo mismo**. Rematch elige un formato (5 contra 5, un jugador por persona) donde la ausencia de licencias no importa y la sensación de control lo es todo; Sociable Soccer elige la nostalgia arcade; Football Manager elige la profundidad de gestión. Ninguno intentó un 11 contra 11 licenciado de aspecto televisivo.

### 2.8.4 Modding como estrategia de producto

La continuidad de PES con licencias incompletas descansó durante años en el editor y en los *option files* de la comunidad [7]. Para un proyecto que por decisión legal publica nombres modificados (orden 15) y guarda lo real en paquetes privados, la lección es que **el editor y el formato de importación son parte del producto**, no un extra: si la comunidad puede rellenar nombres, escudos y uniformes en un formato documentado, el coste de licencias se traslada a la comunidad sin infringir nada por parte del estudio. La responsabilidad sobre el contenido importado y la distribución de esos paquetes por terceros requiere, igualmente, revisión jurídica.

---

## 2.9 Recursos gratuitos con licencia comercial: animación y voz

La orden 57 del dueño limita los recursos a contenido gratuito con licencia que permita uso comercial (CC0, CC-BY, MIT, Apache, Mixamo…; nada NC). La tabla resume lo verificado.

| Recurso | Qué ofrece | Licencia / términos | Restricciones relevantes | Nivel |
|---|---|---|---|---|
| Mixamo (Adobe) | Personajes y animaciones humanoides con auto-rig | Uso libre de regalías en proyectos personales, comerciales y sin ánimo de lucro, incluidos videojuegos; gratuito [64] | No redistribuir los archivos en bruto (paquetes de recursos, plantillas, DLC con los FBX); prohibido usarlos para entrenar modelos; solo bípedos; no disponible con cuentas de empresa o país China [64] | E |
| Quaternius, *Universal Animation Library* | 120+ animaciones sobre un esqueleto humanoide universal (locomoción en 8 direcciones, *sprint*, empujar, sentarse, etc.), listo para retargeting en Godot | **CC0**: «libre para proyectos personales, educativos y comerciales»; versión Standard gratuita (60-70 %), Pro gratuita, Source de pago [65] | Ninguna de licencia; el catálogo no es de fútbol | L |
| Motion-Matching (D. Holden) | Implementación de referencia de *motion matching* y *learned motion matching* | **MIT** [41] | Requiere datos de captura propios | L |
| PFNN (Holden et al.) | Red con función de fase para locomoción | Académico, **no comercial** [42] | Incompatible con la orden 57 | E |
| CMU Graphics Lab Motion Capture Database | Gran base de captura de movimiento | **No verificado**: la página oficial no respondió; fuentes secundarias se contradicen, y una conversión a FBX publicada en 2024 está bajo **CC BY-NC 4.0** [68] | No usar conversiones NC; verificar la página original antes de cualquier uso | E |
| Kokoro-82M (TTS) | Modelo de voz de 82 millones de parámetros; v1.0 (27-01-2025) con 8 idiomas y 54 voces | **Apache 2.0** [66] | Entrenado en parte con dos conjuntos CC BY (Koniwa, CC BY 3.0; SIWIS, CC BY 4.0) que piden atribución; revisar la lista de voces y su cobertura del español | L |
| Piper (TTS) | Motor de voz local rápido | El repositorio original (MIT) quedó archivado; el desarrollo sigue en `piper1-gpl`, que cambió a **GPLv3** en su versión 1.7.0 [67] | Enlazar o distribuir el motor GPL dentro de un juego cerrado puede obligar a liberar código; las voces tienen licencias individuales | E |
| League-Soccer (ya en el repo) | 296 animaciones y motor base | Apache 2.0 (según documentos del proyecto) | Ya integrado; fuera del alcance de esta revisión | — |

Observaciones:

1. **Ninguna biblioteca gratuita verificada es de fútbol.** Los gestos específicos (control orientado, tiro con el empeine, entrada en plancha, despeje, estirada del portero) tendrán que salir de League-Soccer, de Mixamo (sin redistribuir los FBX en bruto) o de modificación procedural. Esto refuerza §2.6: el valor está en el *warping*, la IK y la mezcla, no en el número de clips.
2. **Mixamo prohíbe el uso para entrenar modelos.** Si el proyecto quisiera algún día un *learned motion matching* entrenado con clips de Mixamo, chocaría con sus términos según la FAQ comunitaria de Adobe (nivel E). Un *motion matching* clásico (búsqueda en la base de datos, sin entrenamiento) no tiene ese problema.
3. **Para el comentarista, Kokoro-82M es el candidato con licencia más limpia** de los revisados (Apache 2.0, pesos abiertos, atribución CC BY de dos conjuntos menores). Piper, popular en proyectos locales, quedó bajo GPLv3 en 2025, lo que lo hace delicado para un juego de código cerrado.

---

## 2.10 Síntesis crítica

### 2.10.1 Cinco hallazgos transversales

**H1. La crítica premia el partido y castiga el entorno.** PES 2020 fue «maestría en el campo, frustrante fuera de él» [4]; FC 26 y FC 27 reciben elogios por el juego y críticas por interfaz, familiaridad, IA de compañeros y monetización [16][19][20]. FM26 se hundió en Steam por la interfaz y el rendimiento [57]. En ninguno de los casos revisados la crítica principal fue «faltan licencias» o «faltan clubes». El volumen de contenido de Dinastía (1.069 clubes según el informe interno) no compensa un entorno torpe: la orden 51 del dueño («las interfaces están muy llenas») apunta exactamente al defecto que más ha penalizado a FC 26 y FM26.

**H2. La industria separa ya lo «auténtico» de lo «competitivo».** FC 26 lo convirtió en dos presets [15], y su mejor recepción reciente coincide con esa decisión [16]. Para Dinastía, el comparador A/B/C de motores (orden 38) y el criterio de «diversión sobre realismo» (orden 38) encajan con esta tendencia: no hay que elegir una sola sensación de juego, sino ofrecer un ajuste de partido para la carrera y la gestión (más pausado y fiel) y otro para el partido rápido (más reactivo).

**H3. La sensación de control es medible y tiene umbrales conocidos.** La mediana de detección de retardo motor-visual está en 51-90 ms y la experiencia se degrada claramente hacia los 140-190 ms [33][35]; los más sensibles detectan 26-40 ms [33]. El problema propio del fútbol es la latencia de animación, para la que existe una técnica documentada en FIFA desde 2010 (*warping*) [37], y un método más moderno (*motion matching*) con implementación MIT [38][41].

**H4. Los datos de fútbol de calidad se han cerrado, no abierto.** StatsBomb prohíbe la explotación comercial de sus datos abiertos y de los análisis derivados [50], FBref perdió sus estadísticas avanzadas en enero de 2026 [51], y Google archivó su entorno de investigación en agosto de 2026 [53]. Un proyecto comercial tiene que validar su IA con **medias agregadas publicadas** y con **sus propios partidos**, no con bases de eventos ajenas.

**H5. El pago aleatorio pasó de ser un riesgo reputacional a uno legal en mercados clave.** Bélgica (2018) lo trató como juego de azar [22]; los Países Bajos lo permitieron por interpretación judicial [24]; el Reino Unido optó por la autorregulación [25]; Australia lo etiqueta [26]; y Brasil lo prohíbe en juegos accesibles a menores desde marzo de 2026 [27]. La evidencia de asociación con juego problemático existe, aunque sin dirección causal establecida [28].

### 2.10.2 Tensiones y contradicciones en las fuentes

- **Realismo frente a diversión.** La comparativa interna y las reseñas de PES 2020 elogian el «realismo», pero el éxito comercial más claro de los últimos dos años en fútbol pequeño (Rematch [59]) no es realista en formato. El criterio del dueño (orden 38) es coherente con los datos de mercado, no solo con una preferencia personal.
- **Medias de liga variables.** El informe interno fijó como objetivo 2,5-2,9 goles y 2,5-3,0 de xG por partido (§5.3). La Premier League 2022-23 (2,85 goles) está dentro; la 2023-24 (3,28 goles, xG sin penaltis 3,2) queda por encima [48][49]. Una banda de validación robusta debe construirse con varias temporadas y ligas, y aceptar que el propio fútbol cambia.
- **Promesas de los editores.** Las cifras de HyperMotion V (180 partidos, 1.200 estilos de carrera, modelos «diez veces más precisos») [10] son de marketing; las reseñas de FC 27 muestran que la IA de los compañeros y el cambio de jugador siguen siendo fuentes de frustración [19][20]. La sofisticación declarada del pipeline no se traduce automáticamente en sensación de control.
- **Licencias de datos y herramientas.** Muchas guías de aficionados describen los datos de StatsBomb o la base de CMU como «libres»; las fuentes primarias dicen otra cosa (StatsBomb) o no se pudieron verificar (CMU). La regla de leer siempre el texto de la licencia está justificada por los propios hallazgos de este capítulo.

### 2.10.3 Dónde está la oportunidad

Cruzando H1-H5 con la matriz de brechas del informe interno, la oportunidad de Dinastía no está en los ejes donde FC es fuerte (licencias, captura de movimiento, gráficos), sino en los cinco ejes donde la crítica lleva años señalando a FC y a PES:

1. **Modo Carrera y gestión profundos** (apatía hacia Carrera en FC 25 [14]; Liga Master «en el mismo patrón» en PES 2020; IA de traspasos defectuosa en FC 27 [19]).
2. **Interfaz clara** (FC 26 [16], FM26 [57], FM25 [56]).
3. **IA de compañeros y cambio de jugador fiables** (FC 27 [19][20]).
4. **Ausencia de pago aleatorio** (FC 26-27 [16][20] y regulación [22]-[27]).
5. **Comentario y ambiente** (PES 2020 [4][5][6]).

---

## 2.11 Implicaciones concretas para Dinastía

Cada implicación indica la fuente que la sustenta y el punto del informe interno (`INFORME_AAA_2026-11-16.md`) o de las órdenes del dueño con el que se relaciona. Ninguna cambia el juego por sí sola: son propuestas para el plan (`docs/PLAN_GENERAL.md`), que decide el dueño.

### 2.11.1 Partido y sensación de control

**I1. Medir la latencia de extremo a extremo, no solo la del motor.** El objetivo interno de ≤ 2 cuadros entre entrada y cambio de estado (§5.1) es correcto pero parcial. Propuesta: añadir al «perfil de manejo» una medición de cadena completa (pulsación → primer cuadro en pantalla con el cambio visible del cuerpo o del balón) con objetivo ≤ 100 ms en la laptop del dueño y en su móvil, y una alarma si supera 140 ms, el punto donde la experiencia empieza a caer [33][35]. Las medidas en la nube no sirven (orden 57: sin GPU).

**I2. Separar latencia de control y latencia de animación con *warping*.** El método de FIFA 2010 [37] —deformar de forma procedural el giro y la llegada a un punto en un instante— ataca directamente el síntoma «locomoción poco natural» y «pases sin peso» del motor C4 (informe interno §2.1, §5.2). Debe ir detrás de una bandera `C4_*`, como exige la orden 43.

**I3. Dos ajustes de partido, «Auténtico» y «Rápido».** Siguiendo FC 26 [15][16], y con el comparador A/B/C ya existente (orden 38), ofrecer un ajuste pausado por defecto en la gestión y en La Ruta, y uno reactivo para el partido rápido. Es una decisión de producto que debe aprobar el dueño; se anota como pregunta.

**I4. Pulido con taxonomía.** Clasificar las tareas de pulido del partido en los tres dominios de Pichlmair y Johansen [30] —fisicidad (C4), amplificación (sonido, cámara, vibración), apoyo (asistencias, legibilidad móvil)— para que el banco de pruebas y las notas del dueño se asignen a quien corresponde.

### 2.11.2 Animación

**I5. *Motion matching* clásico sobre los clips que ya hay.** La implementación MIT de Holden [41] y la descripción de Clavet [38] permiten un buscador de pose sobre los 296 clips de League-Soccer más los propios, sin entrenamiento. Debe respetar la regla de la extensión nativa del proyecto (versión C++ con gemelo GDScript) si se pasa a C++. No usar PFNN (licencia no comercial) [42].

**I6. IK determinista en pies y en el toque de balón.** `TwoBoneIK3D` en Godot 4.6+ es determinista [44], compatible con las huellas reproducibles del banco. Encaja con las tareas 12 («IK de pie al balón en el toque») del informe interno.

**I7. Animación procedural antes que más clips.** El enfoque de Rosen [43] (pocos fotogramas clave, mucha interpolación procedural) es el adecuado para un estudio sin captura; las bibliotecas CC0 (Quaternius [65]) sirven para gestos genéricos, pero no hay bibliotecas gratuitas de gestos de fútbol verificadas.

### 2.11.3 IA y validación

**I8. Banco de «fútbol plausible» con bandas, no con objetivos.** Reemplazar los objetivos fijos de §5.3 del informe interno por bandas construidas con varias temporadas (por ejemplo, goles 2,5-3,3 por partido; tiros totales 22-28; proporción de tiros dentro del área ≥ 60 %; remates de cabeza ~4; penaltis ~0,2-0,3), citando las fuentes agregadas [48][49], y tratarlas como **detector de anomalías** sobre muchos partidos con semilla fija, coherente con la orden 38 (diversión sobre cifras). El 2,3 de goles por partido que cita la comparativa interna para el arnés de la IA quedaría por debajo de la banda.

**I9. xG propio y PPDA sobre los partidos simulados.** Un xG logístico de distancia, ángulo y cabeza [45] calculado sobre los propios tiros del juego permite comparar conversión real frente a esperada; el PPDA [47] permite comprobar que los enfoques defensivos (presión alta frente a bloque bajo) se comportan distinto. VAEP [46] es la herramienta para juzgar decisiones con balón de la CPU más allá del resultado.

**I10. No usar StatsBomb Open Data para calibrar el juego.** Su acuerdo prohíbe la explotación comercial de los datos y de los análisis derivados [50]. Corregir la mención «FBref/StatsBomb abiertos» del informe interno: FBref ya no ofrece estadísticas avanzadas [51].

**I11. Escenarios académicos como pruebas unitarias de la IA.** La idea de *Football Academy* de Google Research Football [52] (3 contra 1, contraataque, córner, salida del portero) se corresponde con la «arena de pruebas» pedida por el dueño (orden 22) y con los bancos especializados (orden 26). El código de GRF es Apache 2.0 [53] y está archivado: se puede consultar como referencia, sin depender de él.

### 2.11.4 Interfaz, modos y negocio

**I12. La interfaz es el mayor riesgo de producción documentado.** FM25 se canceló por la interfaz y la experiencia general [56]; FM26 cayó al 22 % positivo en Steam por la interfaz y el rendimiento [57]; FC 26 recibe la crítica de «interfaz recargada» [16]. Las órdenes 46 y 51 (subdividir menús en pantallas completas al estilo PES 2020) están respaldadas por la evidencia. Recomendación metodológica: cualquier rediseño grande de menús se prueba con jugadores externos antes de sustituir al anterior, y el anterior se conserva detrás de una opción hasta entonces.

**I13. Nunca publicar algo que se lea como una demo.** eFootball 2022 [8][9] y la decisión de Sports Interactive con FM25 [56] apuntan a lo mismo. El recorte de alcance propuesto en el informe interno (versión 1.0 = club + partido + La Ruta + 5 ligas) es coherente con esta evidencia.

**I14. Sin pago aleatorio, y decirlo.** Con ligas de Argentina y Brasil en el juego, la Ley 15.211/2025 de Brasil [27] convierte la ausencia de cajas de botín en una ventaja concreta. Los coleccionables y peluches con logros (orden 14) deben seguir sin dinero real y sin azar pagado; si algún día se vendiera algo, que nunca sea aleatorio. Es además el eje donde la crítica a FC 26-27 es más dura [16][20].

**I15. El editor y la importación son producto.** El precedente de los *option files* de PES [7] respalda invertir en un formato de importación documentado para `pack_real.json` y las caras, con revisión jurídica previa sobre la responsabilidad del contenido que importe la comunidad.

**I16. Elegir el terreno.** Los éxitos pequeños recientes compiten en terrenos que FC no ocupa [58][59][61]. El terreno natural de Dinastía es la combinación de gestión profunda y modo jugador con partido jugable decente; el informe interno ya lo identifica (§8). La evidencia de mercado sugiere no intentar ganar a FC en espectáculo televisivo licenciado.

### 2.11.5 Voz y comentario

**I17. Comentario por fases con licencias limpias.** El comentario es la crítica de presentación más repetida en PES 2020 [4][5][6]. Fase 1: frases grabadas (como propone el informe interno, §6.6); fase 2: nombres con TTS local. Kokoro-82M (Apache 2.0, con atribución CC BY de dos conjuntos) es el candidato con licencia más limpia de los revisados [66]; Piper (GPLv3 desde 2025) solo si se resuelve el problema de la licencia copyleft [67]. Antes de usar cualquier voz, comprobar su cobertura del español y su ficha individual.

---

## 2.12 Limitaciones

1. **Acceso.** Varias reseñas clave (GameSpot, PC Gamer, GamesRadar+ y Trusted Reviews para PES 2020; Tom's Guide para FC 26; PC Gamer para FM26) no se pudieron leer completas. Sus notas proceden de agregadores (L) y sus frases, de extractos (E).
2. **Juegos no jugados.** Este capítulo no incluye pruebas propias de PES 2020 ni de FC 27; todas las valoraciones son de terceros.
3. **FC 27 reciente.** Siete semanas tras el lanzamiento; las medias de los agregadores pueden variar y faltan análisis técnicos independientes.
4. **Estudios de latencia.** Los experimentos citados usan tareas simples con ratón o botón, no un mando ni un juego de fútbol; los umbrales son orientativos para un juego en tercera persona.
5. **Datos de fútbol.** Las medias proceden de una sola liga (Premier League); no se pudieron obtener medias comparables de las otras cuatro grandes ligas con fuentes primarias accesibles tras la retirada de las estadísticas avanzadas de FBref.
6. **Licencias.** Las descripciones de licencias no sustituyen a una revisión jurídica, en especial para Mixamo (página oficial inaccesible), CMU (no verificada) y la importación de contenido de la comunidad.
7. **Costes y equipos.** No hay datos públicos fiables del presupuesto ni del tamaño del equipo de FC o eFootball; la única cifra AAA concreta procede de una filtración [54].

### 2.12.1 Lo que el encargo pedía y no se pudo verificar

- **«Kinetic Flow»**: no aparece en la ficha de Konami, en Wikipedia ni en las reseñas de PES 2020, y una búsqueda específica no lo encontró en ningún juego de Konami o EA. Puede tratarse de un nombre recordado de forma inexacta; no se usa en este capítulo.
- **Reseñas de IGN y Eurogamer de PES 2020**: solo se verificó la nota de IGN (8,3) y que Eurogamer no puso nota numérica, a través de OpenCritic [2].
- **Mensaje sobre el «dribbling de Messi»**: la ficha oficial vincula el Finesse Dribble a Iniesta y el paquete de animaciones especiales a Ronaldinho [3]; no se encontró una fuente primaria que vincule ese sistema a Messi.
- **Base de datos de CMU**: términos no verificados (§2.9).
- **Tamaño de los equipos de FC y eFootball**: sin datos públicos fiables.
- **Charla de Kristjan Zadziuk (Ubisoft Toronto) en la GDC 2016 sobre *motion matching***: existe según fuentes secundarias, pero su título exacto no se pudo confirmar; la ficha verificada de GDC Vault corresponde a Simon Clavet [38].

---

## 2.13 Conclusiones

1. Siete años después, la serie FC no supera en la crítica a PES 2020 (76-80 frente a 81) [2][13][16][18].
2. La crítica penaliza sistemáticamente interfaz, familiaridad, IA de compañeros, comentario y monetización, no la falta de licencias [4][16][19][20][57].
3. FC 26 separó el juego en dos ajustes, «Auténtico» y «Competitivo», y fue su entrega mejor valorada del periodo [15][16].
4. La percepción del retardo motor-visual tiene umbrales conocidos (mediana 51-90 ms; caída de experiencia hacia 140-190 ms) [33][35].
5. La latencia de animación tiene soluciones documentadas: *warping* en FIFA (2010) y *motion matching* (2016), con implementación MIT disponible [37][38][41].
6. Godot 4.6+ incluye IK determinista, compatible con las pruebas reproducibles del proyecto [44].
7. Las referencias de fútbol real cambian por temporada (Premier League: 2,85 goles en 2022-23, 3,28 en 2023-24) [48][49]; deben usarse como bandas.
8. Los datos abiertos de StatsBomb no admiten explotación comercial, y FBref ya no ofrece estadísticas avanzadas [50][51].
9. Brasil prohíbe desde marzo de 2026 las cajas de botín en juegos accesibles a menores [27].
10. Los éxitos pequeños de fútbol eligen un terreno distinto al de FC; los grandes fracasos recientes del género vienen de interfaces nuevas o de lanzamientos inmaduros [8][56][57][59].

---

## Bibliografía

Todas las fuentes se consultaron el 16-11-2026. Nivel: **L** = leída en la fuente o en un agregador que reproduce el dato; **E** = verificada por el extracto del buscador, sin texto completo.

[1] Wikipedia. «eFootball PES 2020». https://en.wikipedia.org/wiki/EFootball_PES_2020 — L.

[2] OpenCritic. «eFootball PES 2020». https://opencritic.com/game/8187/efootball-pes-2020 — L.

[3] Konami Digital Entertainment. «eFootball PES 2020» (ficha oficial del producto). https://www.konami.com/games/eu/en/products/pes2020/ — L.

[4] Gorman, D. (13-09-2019). «PES 2020: Mastery on the pitch, but frustrating off it». *The Irish Times*. https://www.irishtimes.com/culture/games/game-reviews/pes-2020-mastery-on-the-pitch-but-frustrating-off-it-1.4017264 — L.

[5] GamesRadar+ (2019). «eFootball PES 2020 review: “A faithful replication of the beautiful game… the most realistic PES to date”». https://www.gamesradar.com/pes-2020-review/ — E (solo titular leído).

[6] Cubed3 (2019). «eFootball PES 2020» (reseña, Xbox One). https://www.cubed3.com/games/reviews/xbox-one/efootball-pes-2020 — E.

[7] GamesRadar+. «PES 2020 option file guide: How to get all the official kits and badges». https://www.gamesradar.com/pes-2020-option-file-official-kits-badges-names-guide — E.

[8] PC Gamer (2021). «Does eFootball deserve to be the worst reviewed game on Steam?». https://www.pcgamer.com/what-the-hell-is-going-on-with-efootball — E.

[9] Video Games Chronicle (2021). «Konami apologises for eFootball’s disastrous launch, promises improvements». https://www.videogameschronicle.com/news/konami-apologises-for-efootballs-disastrous-launch-promises-improvements — E.

[10] MP1st (18-07-2023). «EA Sports FC 24 Gameplay Deep Dive Details HyperMotionV, PlayStyles, and the Frostbite Engine». https://mp1st.com/news/ea-sports-fc-24-gameplay-deep-dive-details-hypermotionv-playstyles-and-the-frostbite-engine — L.

[11] Caleffi, T., Sabatino, K. y Thompson, B. (21-08-2024). «EA SPORTS FC 25 | FC IQ Deep Dive». Electronic Arts. https://www.ea.com/games/ea-sports-fc/fc-25/news/pitch-notes-fc-25-fc-iq-deep-dive — L.

[12] Electronic Arts (2024). «Pitch Notes: FC 25 Football Ultimate Team Deep Dive». https://www.ea.com/games/ea-sports-fc/fc-25/news/pitch-notes-fc-25-football-ultimate-team-deep-dive — E.

[13] OpenCritic. «EA Sports FC 25». https://opencritic.com/game/17121/ea-sports-fc-25 — L.

[14] GamesRadar+ (2024). «EA FC 25 review: “Highly playable, yet naggingly familiar”». https://gamesradar.com/games/ea-sports-fc/ea-sports-fc-25-review — E.

[15] Electronic Arts (22-07-2025). «Pitch Notes: FC 26 Gameplay Deep Dive». https://www.ea.com/games/ea-sports-fc/fc-26/news/pitch-notes-fc26-gameplay-deep-dive — E.

[16] OpenCritic. «EA Sports FC 26». https://opencritic.com/game/18960/ea-sports-fc-26 — L.

[17] Electronic Arts (23-07-2026). «Kylian Mbappé and Jude Bellingham Welcome You to EA SPORTS FC 27, Launching Worldwide on September 25» (nota de prensa). https://news.ea.com/press-releases/press-releases-details/2026/Kylian-Mbapp-and-Jude-Bellingham-Welcome-You-to-EA-SPORTS-FC-27-Launching-Worldwide-on-September-25/default.aspx — L.

[18] OpenCritic. «EA Sports FC 27». https://opencritic.com/game/21101/a — L.

[19] Kato, M. (25-09-2026). «EA Sports FC 27 Review: More Build Up Play Than The Long Ball». *Game Informer*. https://gameinformer.com/review/ea-sports-fc-27/more-build-up-play-than-the-long-ball — L.

[20] Perić, L. (26-09-2026). «EA Sports FC 27 Review: Better Football, Same Old Shop». *Stadion Gaming*. https://www.stadiongaming.eu/en/news/ea-sports-fc-27-review-better-football-same-old-shop — L.

[21] Electronic Arts Inc. (2025). *Form 10-K, fiscal year ended March 31, 2025*. U.S. Securities and Exchange Commission. https://www.sec.gov/Archives/edgar/data/712515/000071251525000022/ea-20250331.htm — E.

[22] Video Games Chronicle (29-01-2019). «EA stops selling FIFA loot boxes in Belgium». https://www.videogameschronicle.com/news/ea-stops-selling-fifa-loot-boxes-in-belgium-jan-29-2019/ — L.

[23] Xiao, L. Y. (2023). «Breaking Ban: Belgium’s Ineffective Gambling Law Regulation of Video Game Loot Boxes». *Collabra: Psychology*, 9(1). Ficha: https://pure.itu.dk/en/publications/breaking-ban-belgiums-ineffective-gambling-law-regulation-of-vide/ — E.

[24] Video Games Chronicle (10-03-2022). «Dutch court overrules decision to fine EA €10 million for FIFA loot boxes». https://videogameschronicle.com/news/dutch-court-overrules-decision-to-fine-ea-e10-million-for-fifa-loot-boxes — L.

[25] Gobierno del Reino Unido, DCMS (18-07-2022). «Government response to the call for evidence on loot boxes in video games». https://gov.uk/government/consultations/loot-boxes-in-video-games-call-for-evidence/outcome/government-response-to-the-call-for-evidence-on-loot-boxes-in-video-games — E.

[26] Gobierno de Australia, Department of Infrastructure (2023-2024). «New mandatory minimum classifications for gambling-like games content». https://infrastructure.gov.au/department/media/news/new-mandatory-minimum-classifications-gambling-games-content — E.

[27] Brasil, Ley 15.211/2025 (ECA Digital). Cobertura: *Jurist* (09-2025), «Brazil passes new law to protect children’s online privacy», https://www.jurist.org/news/2025/09/brazil-passes-new-law-to-protect-childrens-online-privacy/ ; Mattos Filho, «Brazil’s ECA Digital in practice: how the law affects different sectors», https://www.mattosfilho.com.br/en/unico/brazils-eca-digital/ — E.

[28] Zendle, D. y Cairns, P. (2018). «Video game loot boxes are linked to problem gambling: Results of a large-scale survey». *PLOS ONE*, 13(11): e0206767. https://eprints.whiterose.ac.uk/139116/1/journal.pone.0206767.pdf — E.

[29] Swink, S. (2008). *Game Feel: A Game Designer’s Guide to Virtual Sensation*. Morgan Kaufmann/CRC Press. ISBN 978-0123743282. Definición citada a través de [30] — E (libro no consultado directamente).

[30] Pichlmair, M. y Johansen, M. (2022). «Designing Game Feel: A Survey». *IEEE Transactions on Games*, 14(2). DOI 10.1109/TG.2021.3072241. Preprint: https://arxiv.org/abs/2011.09201 — E.

[31] Jonasson, M. y Purho, P. (2012). «Juice It or Lose It». GDC Europe, Independent Games Summit. https://gdcvault.com/play/1016789/Juice-It-or-Lose — E.

[32] Hicks, K., Gerling, K., Dickinson, P. y Vanden Abeele, V. (2019). «Juicy Game Design: Understanding the Impact of Visual Embellishments on Player Experience». *CHI PLAY 2019*, pp. 185-197. DOI 10.1145/3311350.3347171 — E.

[33] Raaen, K., Eg, R. y Griwodz, C. (2014). «Can gamers detect cloud delay?». *13th Annual Workshop on Network and Systems Support for Games (NetGames)*. DOI 10.1109/NetGames.2014.7008962. PDF: https://web-backend.simula.no/sites/default/files/publications/files/paper_5.pdf — L.

[34] Raaen, K. y Eg, R. (2016). «How to demonstrate delay? Let’s play!». *ACM MMSys 2016*. https://mmsys2016.itec.aau.at/papers/MMSYS/a28-westerdals.pdf — L.

[35] Eg, R., Raaen, K. y Claypool, M. (2018). «Playing with delay: With poor timing comes poor performance, and experience follows suit». *10th International Conference on Quality of Multimedia Experience (QoMEX)*. https://www.uni-marburg.de/en/irtg1901/study-program/seminars/eg-et-al-2018-2.pdf — L.

[36] Claypool, M. y Claypool, K. (2006). «Latency and Player Actions in Online Games». *Communications of the ACM*, 49(11). DOI 10.1145/1167838.1167860. Informe técnico: https://ftp.cs.wpi.edu/pub/techreports/pdf/06-13.pdf — L (informe técnico).

[37] McComas, P. y Sanmiya, J. (2010). «Animation Warping for Responsiveness in FIFA Soccer». GDC 2010, Electronic Arts. https://gdcvault.com/play/1012342/Animation-Warping-for-Responsiveness-in — L (ficha).

[38] Clavet, S. (2016). «Motion Matching and The Road to Next-Gen Animation». GDC 2016, Ubisoft Montreal. https://www.gdcvault.com/play/1022985/Motion-Matching-and-The-Road — L (ficha).

[39] Allen, H. (2021). «Animation Summit: Environmental and Motion Matched Interactions; ‘Madden’, ‘FIFA’ and Beyond!». GDC 2021, Electronic Arts. https://www.gdcvault.com/play/1027465/Animation-Summit-Environmental-and-Motion — L (ficha).

[40] Holden, D., Kanoun, O., Perepichka, M. y Popa, T. (2020). «Learned Motion Matching». *ACM Transactions on Graphics*, 39(4). DOI 10.1145/3386569.3392440. https://www.theorangeduck.com/page/learned-motion-matching — L.

[41] Holden, D. (2021). *Motion-Matching* (código fuente, licencia MIT). https://github.com/orangeduck/Motion-Matching — L (licencia).

[42] Holden, D., Komura, T. y Saito, J. (2017). «Phase-Functioned Neural Networks for Character Control». *ACM Transactions on Graphics*, 36(4), art. 42. DOI 10.1145/3072959.3073663. https://www.ipab.inf.ed.ac.uk/cgvu/phasefunction.pdf — E.

[43] Rosen, D. (2014). «Animation Bootcamp: An Indie Approach to Procedural Animation». GDC 2014, Wolfire Games. https://gdcvault.com/play/1020049/Animation-Bootcamp-An-Indie-Approach — E.

[44] Godot Engine (2025-2026). «Inverse Kinematics returns to Godot 4.6». https://godotengine.org/article/inverse-kinematics-returns-to-godot-4-6/ ; notas de versión: https://godotengine.org/releases/4.6/ — E.

[45] Robberechts, P. y Davis, J. (2020). «How data availability affects the ability to learn good xG models». En *Machine Learning and Data Mining for Sports Analytics (MLSA 2020)*, CCIS 1324, Springer, pp. 17-27. https://link.springer.com/doi/10.1007/978-3-030-64912-8_2 — E.

[46] Decroos, T., Bransen, L., Van Haaren, J. y Davis, J. (2019). «Actions Speak Louder than Goals: Valuing Player Actions in Soccer». *KDD ’19*. Preprint: https://arxiv.org/abs/1802.07127 — E.

[47] Trainor, C. (2014). «Defensive Metrics: Measuring the Intensity of a High Press». StatsBomb. https://statsbomb.com/?p=10118 — E.

[48] Premier League (24-05-2024). «The numbers that show this has been a season like no other». https://www.premierleague.com/news/4031506 — L.

[49] Segar, D. (29-03-2024). «The Numbers Behind the Premier League Goal Explosion». *Opta Analyst*. https://theanalyst.com/2024/03/numbers-behind-premier-league-goal-explosion — L.

[50] StatsBomb. *Open Data* (repositorio) y *StatsBomb Public Data User Agreement* (LICENSE.pdf). https://github.com/statsbomb/open-data — L.

[51] Awful Announcing (01-2026). «Sports Reference pulls advanced data after agreement violation dispute». https://awfulannouncing.com/soccer/sports-reference-pulls-advanced-data-agreement-violation-dispute.html — E.

[52] Kurach, K., Raichuk, A., Stańczyk, P., Zając, M., Bachem, O., Espeholt, L., Riquelme, C., Vincent, D., Michalski, M., Bousquet, O. y Gelly, S. (2020). «Google Research Football: A Novel Reinforcement Learning Environment». *AAAI-20*, pp. 4501-4510. DOI 10.1609/aaai.v34i04.5878. https://arxiv.org/abs/1907.11180 — L.

[53] Google Research. *football* (repositorio, licencia Apache 2.0; archivado el 19-08-2026). https://github.com/google-research/football — L.

[54] Game World Observer (19-12-2023). «PlayStation PC game sales leak, Insomniac budgets and ROI». https://gameworldobserver.com/2023/12/19/playstation-pc-game-sales-leak-insomniac-budgets-roi — E.

[55] Electronic Arts. «EA SPORTS — Job opportunities» (descripción de EA Vancouver). https://www.ea.com/ea-studios/ea-sports/job-opportunities — E.

[56] Kerr, C. (07-02-2025). «SEGA and Sports Interactive cancel Football Manager 25 after missing quality target». *Game Developer*. https://www.gamedeveloper.com/production/sega-and-sports-interactive-cancel-football-manager-25-after-missing-quality-target- — L.

[57] OpenCritic News (05-11-2025). «Football Manager 26 Now Has ‘Mostly Negative’ Reviews on Steam». https://opencritic.com/news/23193/football-manager-26-now-has-mostly-negative-reviews-on-steam — L.

[58] Video Games Chronicle (02-2024). «Football Manager 2024 hits a series record 7 million players». https://videogameschronicle.com/news/football-manager-2024-hits-a-series-record-7-million-players — E.

[59] Gematsu (24-06-2025). «Rematch sales top one million». https://www.gematsu.com/2025/06/rematch-sales-top-one-million — L.

[60] Gamereactor (2025). «Rematch reaches 5 million unique players». https://www.gamereactor.eu/rematch-reaches-5-million-unique-players-1576873/ — E.

[61] Game Developer (16-11-2023). «Sociable Soccer 24 out today on Steam» (nota de prensa). https://gamedeveloper.com/press-release/sociable-soccer-24-out-today-on-steam — E.

[62] FourFourTwo. «Sociable Soccer 24 review: Sensible Soccer made for a new generation of football fans». https://www.fourfourtwo.com/us/reviews/sociable-soccer-24-review-sensible-soccer-made-for-a-new-generation-of-football-fans — E.

[63] Steam. «Pro Soccer Online». https://store.steampowered.com/app/1583320/Pro_Soccer_Online/ — E.

[64] Adobe. «Mixamo | Common questions». https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html ; y Adobe Community, «Mixamo FAQ: Licensing, Royalties, Ownership, EULA and TOS», https://community.adobe.com/t5/mixamo-discussions/mixamo-faq-licensing-royalties-ownership-eula-and-tos/td-p/13234775 — E (página oficial inaccesible: 403).

[65] Quaternius. «Universal Animation Library». https://quaternius.com/packs/universalanimationlibrary.html — L.

[66] hexgrad. «Kokoro-82M» (ficha del modelo, licencia Apache 2.0). https://huggingface.co/hexgrad/Kokoro-82M — L.

[67] Open Home Foundation. *piper1-gpl* (versiones; «Change license to GPLv3» en v1.7.0). https://github.com/OHF-Voice/piper1-gpl/releases — E.

[68] 4TU.ResearchData (2024). «FBX Conversion Of The CMU Graphics Lab Motion Capture Database» (CC BY-NC 4.0). https://data.4tu.nl/datasets/0448aab2-3332-449f-a8e2-d208cb58c7df — E.
