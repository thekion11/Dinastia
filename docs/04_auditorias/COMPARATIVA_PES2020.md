# Comparativa de CALIDAD: Dinastía frente a eFootball PES 2020 (actualizada el 10-11-2026 con cifras medidas)

Pedido: informe honesto de en qué punto está Dinastía respecto a un referente del género. Solo lectura de código/documentos; no se tocó nada más.
Marcas: [V] = dato leído en un documento del proyecto o en una reseña citada al final; [C] = conocimiento general de PES 2020 sin verificar ahora; [E] = estimación mía.
Límite del método: no se jugó Dinastía en esta sesión. Las notas de Dinastía salen de los documentos del propio proyecto (algunos desfasados unos días) y de la prueba del dueño en su teléfono (3-11). Las de PES 2020 salen de reseñas de 2019 y de lo que se sabe del juego.

## 0. Contexto

- **PES 2020** (Konami, sept. 2019): producto de un estudio grande con más de 20 años de serie; Metacritic PS4 82 (54 críticas), PC 81 (5 críticas) [V]. Fortaleza: el partido y los gráficos de jugadores. Debilidades: licencias (vs. FIFA 20), comentarista repetitivo, Liga Master «en el mismo punto desde hace años», online con fallos [V].
- **Dinastía**: proyecto pequeño en Godot 4.7, GDScript con partes en C++; «4 juegos en 1» (gestión del club, partido, ciudad/instalaciones, minijuegos). **1.069 clubes en 62 ligas de 50 países, 26.725 jugadores, 69 selecciones, 9 idiomas** [medido con `herramientas/medir_contenido.tscn`; ver AUDITORIA_CONTENIDO]. Veredicto del dueño sobre su versión del 2-11: «visualmente es bueno, jugabilidad muy mala»; 5 FPS en su teléfono en calidad media, GPU al 100 % [V: PRUEBA_DUENO_MOVIL]. El motor del partido se está reemplazando por la base de League-Soccer (en GDScript, tras una bandera) [V: MOTOR_LEAGUE_SOCCER_PLAN].
- Desde el 9-11 el juego base pasa a ser «solo club»: la ciudad 3D queda apagada y el menú se reduce a «Diseño de la ciudad» (gestión 2D) y «Entrar al estadio» [V: PLAN_GENERAL]. Esto cambia la lectura de las notas de «ciudad».
- El documento `ESTADIOS_REALISTAS_PLAN.md` no existe todavía; lo de estadios sale de la auditoría de contenido y de PLAN_GENERAL.

## 1. Tabla por áreas (nota 1-10)

Escala: 10 = referencia absoluta del género hoy; 7 = sólido; 5 = jugable con carencias claras; 3 = esbozo.

| Área | PES 2020 | Dinastía | Justificación |
|---|---|---|---|
| Jugabilidad del partido | **8** | **3** | PES: «el PES más realista», control sensible pero profundo, aunque con pases/entradas a veces erráticos [V]. Dinastía: veredicto del dueño «muy mala», movilidad del jugador «horrible»; el motor se está reemplazando y aún no está integrado del todo [V]. |
| IA (compañeros, rivales, portero) | **7** | **4** | PES: IA irregular sin balón (defensas que no persiguen balones sueltos) pero con niveles y estilos de juego [V]. Dinastía: hay trabajo serio y medible (F1-F8, 32 partidos de semilla fija, 2,3 goles/partido) pero es un arnés de investigación, sin años de ajuste y sin validar con jugadores. |
| Físicas y animaciones | **8** | **4** | PES: captura de movimiento y balón convincentes (motion capture, nuevo sistema de tiro [C]). Dinastía: 296 animaciones de League-Soccer disponibles, ~25 festejos propios, física del balón con arrastre cuadrático; pero hitboxes que atraviesan cuerpos (fallo P4) y locomoción poco natural. |
| Gráficos de jugadores y caras | **8** | **4** | PES: caras escaneadas de muchas estrellas, a menudo mejores que FIFA [V]. Dinastía: 300 caras de biblioteca «mezcladas» + procedural; las 1.219 fotos reales están solo en un `.pck` no público; el build público cae al dibujo procedural [V]. |
| Estadios | **8** | **4** | PES: ~tantos estadios reales con licencia más genéricos, con iluminación y público muy pulidos [C]. Dinastía: 1.069 perfiles paramétricos pero solo 99 combinaciones distintas (forma, niveles, techo, focos, fachada), 0 modelos individuales; con interior recorrible y estadio propio editable. |
| Presentación TV y narración | **7** | **3** | PES: presentación moderna, cinemáticas, repeticiones; comentarista repetitivo y con volumen irregular [V]. Dinastía: cámara de TV de 4 planos y repeticiones, pero sin comentarista (narración por voz «después del lanzamiento») [V]. |
| Menús / interfaz | **7** | **5** | PES: menús rediseñados, fáciles de navegar, algo saturados en myClub [V]. Dinastía: muy completos, 9 idiomas, atajos editables, contraste alto; rediseño del menú central en curso; riesgo de complejidad y de sobrecarga. |
| Modo carrera / gestión | **6** | **8** | PES: Liga Master con diálogos y mercado mejorado, pero «sin mucha profundidad» [V]. Dinastía: finanzas, cantera, prensa, política, instalaciones, directiva, roles; mucho más profundo (la profundidad no está probada por jugadores). |
| Licencias y contenido | **6** | **4** | PES: licencias parciales (Juventus exclusiva, algunos clubes top, varias ligas; faltan Premier y Serie A completa, parchables con archivos de opción) [V][C]. Dinastía: todo con nombres modificados; 1.069 de ~4.000 clubes profesionales y 62 ligas de 50 países [medido]; sin licencias, intencionalmente. Escudos y uniformes propios en los 1.069 clubes. |
| Selecciones y torneos | **6** | **6** | PES: selecciones con licencia limitada y UEFA Euro 2020 añadida por actualización [V]; torneos propios. Dinastía (10-11): 69 selecciones, Mundial de 48 y continentales jugados con partidos, Finalissima, Olímpicos, cargo de seleccionador, Mundial de Clubes de 32 y Copa Intercontinental, continentales de clubes con formato real [medido]; faltan Nations League, eliminatorias y amistosos jugables (no probado por jugadores). |
| Rendimiento móvil / PC modesto | **8** (PC/consola; no existió versión móvil de esta entrega) | **3** | PES: estable a 60 en consola/PC medio [C]. Dinastía: 5 FPS en su teléfono el 2-11 (desde entonces hubo mejoras no medidas en hardware real); método de medición bueno, pero meta de 120 FPS sin certificar [V]. |
| Sonido | **7** | **4** | PES: música licenciada/ambiente, gritos de grada, comentarista flojo [V]. Dinastía: sonidos CC0, silbato, ambiente; sin comentarista, sin música licenciada (lo maneja el dueño). |
| Opciones y accesibilidad | **5** | **7** | PES: opciones clásicas, poca accesibilidad [C]. Dinastía: modo daltónico, escala de texto, contraste alto, atajos editables, 9 idiomas, siete niveles de calidad, «Partido ligero», prueba de rendimiento integrada [V]. |

Medias aproximadas: PES 2020 ≈ 7,1; Dinastía ≈ 4,6 [E] (subió desde 4,2 por contenido: licencias/contenido 2→4 y selecciones/torneos 3→6; el partido no cambió). La diferencia se concentra en el partido; no es uniforme.

## 1b. PES 2020 frente a Dinastía, por apartado (con cifras)

PES 2020: [C] = conocimiento general no verificado hoy; [E] = estimación. Dinastía: medido hoy sobre el mundo generado.

| Apartado | PES 2020 | Dinastía (medido) | Lo que ganamos | Lo que perdemos | Lo que falta para igualar |
|---|---|---|---|---|---|
| Licencias y clubes | licencias parciales (Juventus exclusiva, algunos clubes top, varias ligas); nombres reales en lo licenciado [C] | 1.069 clubes con nombre modificado, escudo y uniforme propios; 3.911 jugadores con datos fijos | ningún parche de comunidad, libre de derechos | nombres y escudos reales | solo contenido y acuerdos; decisión del dueño: no licencias |
| Ligas | alrededor de 30 ligas, muchas parciales [E] | 62 ligas en 50 países (50 primeras, 12 segundas) con su cantidad real de clubes | segundas divisiones y fases finales de 15 países | licencias | 85 países y ~100 primeras divisiones del mundo |
| Selecciones | decenas de selecciones, pocas con licencia plena [E] | 69, con Mundial de 48, 6 continentales, Finalissima, Olímpicos y cargo de seleccionador | gestión de la selección | Nations League y eliminatorias | 142 selecciones FIFA, eliminatorias, Nations League |
| Torneos de clubes | Champions y Europa League licenciadas; Libertadores [C] | 6 continentales con formato real, supercopas, Mundial de Clubes de 32 e Intercontinental, copas de todos los países | formatos 2025-26 al día | licencia | jugar las copas de los otros países, no solo simularlas |
| Modos | partido, Liga Master, ML online, myClub [V] | club, partido, instalaciones, minijuegos, entrenamiento, selección | gestión profunda (finanzas, cantera, política) | online | decisión: sin online |
| Gráficos | caras escaneadas, estadios con licencia [V][C] | 300 caras mezcladas + procedural; 99 perfiles de estadio; 0 modelos individuales | 9 idiomas, accesibilidad, 7 niveles de calidad | fidelidad de caras y estadios | 150 estadios icónicos, biblioteca de caras en el build público |
| Jugabilidad | «el PES más realista» [V] | «muy mala» según el dueño (3-11); motor en reemplazo | — | todo | perfil de manejo medible y prueba ciega (brecha 1) |
| Rendimiento | estable a 60 FPS en consola/PC [C] | 5 FPS en el móvil del dueño (2-11); mejoras sin medir en hardware real | banco de rendimiento integrado | fluidez real | medir de nuevo en teléfono y PC modesto |

## 2. Dónde Dinastía ya supera (o puede superar) a PES 2020

1. **Gestión del club.** PES 2020 ofrece Liga Master (transferencias, contratos, entrenador) pero sin economía interna. Dinastía añade finanzas con origen de cada ingreso/gasto, directiva, cantera, prensa y rueda de prensa, política, instalaciones y patrocinios [V]. Es el diferenciador real.
2. **Instalaciones y estadio propio** (diseño de la ciudad/club, museo, despacho, casa del personaje): PES no tiene nada equivalente.
3. **Mundo de clubes más amplio de lo habitual en un indie**: 1.069 clubes, 62 ligas, 50 países, 69 selecciones, con generador de plantillas y datos por país; PES 2020 tenía licencias de menos ligas y, por contrato, solo las de sus socios [C].
4. **Accesibilidad y localización**: 9 idiomas, daltonismo, escala de texto, contraste alto, remapeo; PES apenas ofrecía esto [C].
5. **Rendimiento escalable y medible por diseño**: banco de >30 pruebas, presupuesto de llamadas/triángulos, siete niveles de calidad. Aún sin cumplir su meta en el teléfono, la infraestructura es mejor que lo habitual.
6. **Edición y apertura**: contenido propio sin licencias sin tener que parchar archivos de opción (en PES el contenido real se completaba con parches de la comunidad [C]).
7. **Variedad**: minijuegos, entrenamiento, 4 «juegos en 1».

Matiz honesto: en 1-3 la ventaja es de **diseño**, no de pulido: PES no los tiene, pero Dinastía todavía no demostró que se disfruten durante cientos de horas.

## 3. Las 15 brechas más grandes (por impacto en el jugador)

| # | Brecha | Por qué importa | Acción concreta y realista |
|---|---|---|---|
| 1 | **Sensación del control del partido**: manejo, respuesta, inercia, pase/tiro/regate | Es lo primero que el jugador nota; el dueño la calificó «muy mala». Sin esto lo demás no importa | Fijar un «perfil de manejo» mínimo y medible (latencia entrada→acción, radio de giro, aceleración) y ajustarlo con prueba ciega semanal; terminar de integrar la locomoción guiada por animaciones de League-Soccer (opción B del plan) y ponerla detrás de la bandera hasta que gane al motor actual en 5 partidos reales |
| 2 | **Rendimiento en móvil y PC modesto** (5 FPS medidos; meta 60/120) | Un juego que no corre no se juega | Medir de nuevo en el teléfono del dueño con el banco integrado (`--medir`); fijar presupuesto por calidad (ya existe en `presupuesto.sh`) y no subir de nivel hasta cumplirlo; píxel 50 %, impostores para la grada y recorte de ciudad (ya empezado) |
| 3 | **Animación y físicas creíbles**: atravesar cuerpos, transiciones bruscas, falta de entradas/contactos | PES gana por la sensación de cuerpo | Corregir las hitboxes (P4) con prueba automática de interpenetración; mezclar animaciones con transiciones (blend) y fijar el «toque en el cuadro de contacto» como hace League-Soccer |
| 4 | **IA sin balón y colocación** | Define si el partido «se parece al fútbol» | Seguir la bitácora (F1-F8), pero medir con métricas de fútbol real (posesión, pases, tiros, distancia entre líneas) y compararlas con datos públicos de ligas, no solo con goles/partido |
| 5 | **Caras y personajes de jugadores** | PES se vende por caras reconocibles | Sin fotos reales en el build público (política legal), subir la biblioteca de mezclas de 72 a 300-500, publicarla en el build, y mejorar el modelo procedural (pelo, tono de piel, barba); mantener las fotos solo en `.pck` |
| 6 | **Comentarista y audio de partido** | PES recibió críticas pero tiene comentario; su ausencia hace el partido «mudo» | Ya hay guion de narración generado; lanzar con textos en pantalla y «voz» con efectos de grada reactivos; la voz hablada ya es decisión del dueño «después del lanzamiento». Subir mientras tanto la reactividad de la grada (oooh, olés, silbidos) |
| 7 | **Presentación de TV** (intro de equipos, repeticiones, gráficos del marcador) | Dinastía ya tiene cámara de 4 planos y repeticiones; faltan cohesión y pulido | Plantilla única de «paquete gráfico» (marcador, rótulos, intro, repetición) con 1-2 estilos, sin añadir planos nuevos |
| 8 | **Estadios individuales y su iluminación** | Los estadios son la identidad visual del club | Hacer 20-30 modelos icónicos con pieza característica (arco, cubierta, fachada) en lugar de 150; el resto por perfil paramétrico; luces y público de calidad en ALTA |
| 9 | **Selecciones: lo que falta** | El cargo de seleccionador y los torneos ya existen; no hay Nations League, eliminatorias ni amistosos jugables, y nadie lo probó jugando | Probar el flujo completo con 3 selecciones distintas (Chile, Japón, Marruecos) y sumar eliminatorias antes que Nations League |
| 10 | **Contenido de ligas y clubes** (1.069 clubes; las ligas hechas ya tienen su cantidad real; 85 países sin liga; 434 combinaciones de uniforme para 1.012 kits; 99 perfiles de estadio) | Menos clubes que los juegos comerciales y mucha repetición visual | Seguir con `importar_pais.py` (ya cargó 22 países); diversificar uniformes y estadios por perfil antes de sumar más clubes |
| 11 | **Calidad de los modos de partido** (penales, saques, árbitro, repeticiones) | Los detalles del reglamento dan sensación de producto terminado | Banco de «casos de reglamento» (fuera de juego, ventaja, tarjetas) ya existe; usarlo como contrato de calidad y revisar con vídeos de 3 clubes distintos |
| 12 | **Menús: sobrecarga y claridad** | La estructura de Dinastía es enorme (gestión, ciudad, minijuegos); un jugador nuevo se pierde | Reducir el menú central a 4-5 destinos con progresión y una «tarea del día»; ya planeado con el rediseño; probar con 3 personas sin ayuda |
| 13 | **Opciones de juego y dificultad** | PES ofrece niveles (principiante a leyenda) y ajustes de cámara/controles | Ya hay 8 niveles planeados para la CPU; ligarlos a la IA (F8 «imagen mental») y exponer 3 cámaras y sensibilidad de mando |
| 14 | **Online / multijugador** | PES 2020 tiene Divisiones y myClub online (con fallos) [V]; Dinastía no tiene | NO prioritario para el lanzamiento; si se hace, solo partidos locales (dos mandos en el mismo dispositivo / Bluetooth) |
| 15 | **Pulido, estabilidad y rodaje del producto** (fallos en prólogo, ciudad, hitbox, regresiones) | PES parece terminado porque lo es | Mantener el «modo caza de fallos», ejecutar el banco antes de cada subida, y definir una versión de lanzamiento pequeña pero cerrada (solo club + partido + una liga completa) en lugar de 4 juegos a medias |

## 4. Qué NO conviene copiar de PES 2020

- **myClub / cartas / sobres / monedas** (Ultimate Team): fue criticado por onboarding abrumador y por incentivos de gasto [V]; el dueño ya decidió «sin pago ni gacha».
- **Matchday y eventos con horario fijo** (3-6 PM UTC): problemas de disponibilidad en las reseñas [V]; no hay base de jugadores que lo justifique.
- **Comentario reutilizado de entregas anteriores**: mejor poco y bien dicho que mucho y repetitivo.
- **Control hipersensible**: la crítica más repetida es que el balón se pierde con facilidad [V]; en móvil y con mando esto es peor. Mejor prioridad a la claridad que al realismo extremo.
- **Licencias parciales como argumento de venta**: Dinastía ya eligió nombres modificados; no gastar tiempo en acuerdos.
- **Fotogrametría de caras reales públicas**: riesgo legal (derecho de imagen), ya resuelto con `.pck` fuera del build.
- **Más modos nuevos** hasta cerrar el partido: las ideas nuevas están en pausa por orden 26 del dueño.
- **Liga Master «lineal»** sin economía propia: es justamente donde Dinastía puede ser distinta.

## 5. Conclusión honesta

Dinastía ofrece más **gestión** y más **amplitud** de lo que PES 2020 ofreció en su modo carrera, pero la **experiencia central** (el partido) está muy por debajo, y es lo que decide si alguien vuelve a jugar. Si hay un orden, es: partido y rendimiento (1-4), luego identidad visual de jugador/estadio (5, 8), después contenido (10, 9). Con un equipo mínimo, el techo realista a corto plazo es un juego de gestión muy bueno con un partido «correcto», no un rival directo de PES en sensación de juego.

## Fuentes

- Metacritic, eFootball PES 2020 (PS4/PC): https://legacy.prod.metacritic.com/game/playstation-4/efootball-pes-2020 y https://legacy.prod.metacritic.com/game/pc/efootball-pes-2020
- The Sixth Axis, reseña (7/10; juego inconsistente, comentario repetitivo, gráficos elogiados): https://www.thesixthaxis.com/2019/09/17/efootball-pes-2020-review/
- GamesRadar, reseña («el PES más realista»): https://www.gamesradar.com/uk/pes-2020-review/
- FourFourTwo, reseña (Liga Master mejorada, online con problemas): https://fourfourtwo.com/features/pes-2020-review-new-features-master-league-online-myclub-licenses
- GameSpot, resumen de reseñas: https://www.gamespot.com/articles/pes-2020-review-roundup/1100-6469826/
- GameSpot, reseña (licencias, Juventus exclusiva, Liverpool/Man United): https://www.gamespot.com/reviews/efootball-pes-2020-review-back-of-the-net/1900-6417297/
- Trusted Reviews, FIFA 20 vs PES 2020: https://www.trustedreviews.com/opinion/fifa-20-vs-pes-2020-3942152
- Goal, FIFA 20 vs PES 2020: https://www.goal.com/en-gb/news/fifa-20-vs-pro-evolution-soccer-2020-which-one-should-i-get/1d81v9c1n7b5h15s3i1uhtwu5f
- Clubic, FIFA 20 vs PES 2020: https://www.clubic.com/mag/jeux-video/article-871049-1-duel-fifa-20-pes-2020.html
- Engadget, reseña: https://www.engadget.com/2019-09-09-efootball-pes-2020-pro-evolution-soccer-review.html
- Documentos del proyecto: `docs/04_auditorias/AUDITORIA_CONTENIDO_2026-11-10.md`, `PRUEBA_DUENO_MOVIL_2026-11-03.md`, `MOTOR_LEAGUE_SOCCER_PLAN.md`, `rendimiento_120fps.md`, `IA_PARTIDO_BITACORA.md`, `calidad_7_niveles_2026-11-06.md`, `docs/PLAN_GENERAL.md`.

Nota sobre las fuentes: las reseñas de FourFourTwo, GamesRadar y GameSpot se abrieron solo en parte (texto truncado); lo que se cita de ellas viene de los resúmenes de búsqueda. Los datos de licencias detallados de PES 2020 son [C].
