# Prólogo de referencia y rueda de prensa (10-11)

Vídeo del dueño: Drive, carpeta «respaldo dinastía», «.mp4 vídeo referencia prólogo» (id `1rhcDsmS6WsHv8CtslP9dJ4gRzCHNV_wy`, 444 MB, 4:15). Es una grabación de móvil, en vertical, de un vídeo de YouTube con el arranque de la Liga Máster de un juego de fútbol comercial (PES 2020). El vídeo y sus fotogramas NO van al repo: están en el scratchpad de la sesión 3. Aquí solo hay descripción y análisis. Es una referencia de ESTRUCTURA y de dirección de cámara: no se copian sus modelos, textos, logos ni música (nombres y textos, siempre propios).

Encargo (orden 34): el prólogo nuevo es idea del dueño, y antes exige subir la calidad de las instalaciones del club y de los modelos 3D. Este documento es solo ANÁLISIS: no se implementa nada del prólogo todavía.

## 1. El prólogo, escena por escena

| Tiempo | Escena | Planos y cámara | Personajes y animación | Lugar | Texto y elección |
|---|---|---|---|---|---|
| 0:15-0:42 | Preparación (menús) | 2D | Retrato del DT elegido | Menús morados | Elegir equipo, liga, nivel, aspecto y opciones del DT |
| 0:45-0:55 | Llegada al club | Cámara al hombro detrás del DT, por un pasillo blanco con cuadros históricos | El presidente (traje) recibe al DT (camisa blanca); mano en la espalda y caminan juntos | Pasillo de oficinas, puertas con rótulo | «Omitir» abajo |
| 0:55-1:10 | Presentación del cuerpo técnico | Plano medio y plano general; cortes | Ayudantes con chándal del club; saludos de mano, gestos | Pasillos y oficinas | — |
| 1:05-1:15 | Conoce a jugadores | Plano general de la sala; subtítulo con el nombre del jugador («Se es Wilker Fariñez, el arquero») | Dos jugadores sentados en un sofá azul; el DT de pie hablando; se levantan | Sala de estar con sofá, mesa baja y ventanal | Subtítulo con el nombre |
| 1:15-1:30 | Instalaciones | Exteriores: puerta, verja y campo de entrenamiento | El presidente explica, con gestos amplios | Ciudad deportiva al aire libre | — |
| 1:35 | Corte a negro / transición | Fondo animado del menú | — | — | — |
| 1:40-2:55 | Reunión con la directiva: OBJETIVOS | Plano general de la mesa, contraplanos de cada uno, primer plano del presidente pensando | 5-6 personas sentadas en sillas de oficina; portátiles, vasos y documentos; gestos al hablar | Sala de reuniones blanca con mesa larga, plantas y ventanal | «Objetivo de liga: establecer objetivos»; menú de 3 opciones («Acabar al menos sextos» / «Centrarnos en ganar»…); el presidente responde con subtítulos |
| 3:00 | Transición | Fondo animado | — | — | — |
| 3:05-3:10 | Entrada a la rueda | Pasillo oscuro hacia una puerta iluminada; luego plano a la altura de la mesa: el DT entra por la izquierda y se acerca a su silla | El DT camina, se sienta; jefe de prensa ya sentado | Pasillo → sala de prensa | «Conocer a la prensa» |
| 3:15-4:10 | RUEDA DE PRENSA | Ver §2 | — | Sala de prensa | Preguntas con 3 respuestas; respuesta en subtítulo |

Duración del prólogo jugable (sin los menús): unos 3:30, con «Omitir» siempre visible.

## 2. La rueda de prensa: referencia y la nuestra

**En la referencia (3:05-4:10):**
- **Sala oscura y DT iluminado**: focos de techo a la vista (una barra con 5-6 focos) y la mesa como zona de luz. El contraste dirige la mirada.
- **Mesa larga frontal**, con el frente del color del club y el escudo grande en el centro. El DT está sentado (no de pie en un atril) y a su lado se sienta el jefe de prensa, con traje.
- **Ramo de 6-8 micrófonos** delante del DT y un **balón con el escudo** sobre la mesa.
- **Pared de patrocinadores en damero fino**: escudo del club alternado con varias marcas en cuadros pequeños (unas 12 × 8 piezas), con aspecto de lona impresa.
- **Periodistas en primer plano, en SILUETA** (cabezas oscuras desenfocadas) y una **cámara de TV en trípode** a un lado.
- **Planos**: (a) general frontal desde detrás de los periodistas, con la pregunta; (b) general lejano desde el fondo de la sala, con techo y focos, para elegir respuesta; (c) plano medio y primer plano del DT con los micrófonos para la respuesta, en subtítulo; (d) contraplano lateral al entrar.
- **Interfaz mínima**: la pregunta centrada abajo y 3 opciones en lista vertical, resaltada la elegida. Sin paneles laterales.

**La nuestra** (capturas de `pruebas/captura_rueda_semanas.tscn`, ARG y CHI):
- Ya tiene: pared de patrocinadores con el escudo del club y el del rival en damero, banderas a los lados (país y club), periodistas sentados de espaldas, cortes de cámara entre 3 planos con deriva y desenfoque, pregunta del periodista con medio y tono, 3 respuestas en cruz con el «Ayudante», el tono y el tiempo para contestar.
- Le falta, frente a la referencia:
  1. El DT va **de pie en un atril**, pequeño y centrado. En la referencia está **sentado a una mesa larga**, que llena el plano.
  2. **Sin micrófonos visibles en ramo ni balón** sobre la mesa. Tampoco hay **jefe de prensa**.
  3. La **pared de patrocinadores** son escudos grandes (4 × 8) sobre un fondo liso. En la referencia es un damero fino y denso, con varias marcas.
  4. **Periodistas** de colores vivos y bien iluminados, que compiten con el DT. En la referencia son siluetas oscuras.
  5. Sin **focos de techo** a la vista ni **cámara de TV en trípode**.
  6. No hay **plano medio del DT con micrófonos** para la respuesta.
  7. La interfaz ocupa medio lado derecho de la pantalla. En la referencia es mínima y está abajo.
  8. No hay **entrada** del DT (pasillo → sala → sentarse).

**Mejoras propuestas** (en orden de impacto / coste):

| # | Mejora | Coste | Riesgo |
|---|---|---|---|
| R1 | Periodistas en silueta: material más oscuro y un poco desaturado en la fila delantera, y luz de sala más baja sobre ellos | bajo | ninguno |
| R2 | Barra de focos de techo a la vista (5-6 cilindros con disco emisivo) sobre la mesa | bajo | ninguno |
| R3 | Pared en damero fino: más piezas y más pequeñas (12 × 8) alternando escudo y 3-4 marcas propias. `ParedPrensa` ya genera la textura | bajo | ninguno |
| R4 | Ramo de 6 micrófonos con colores de medios ficticios y un balón con el escudo sobre la mesa | bajo | ninguno |
| R5 | Cámara de TV en trípode a un lado de los periodistas | bajo | ninguno |
| R6 | Plano medio del DT al responder (nuevo plano en la rotación, encuadrado a la altura del pecho con los micrófonos delante) | medio | encuadre según la altura del modelo del DT |
| R7 | Mesa larga frontal con el frente del color del club, el escudo y un jefe de prensa sentado al lado; el DT SENTADO | alto | pose sentada del PersonajeDT: el pelo y la ropa ya dieron problemas al sentarlo (ver el arreglo del pelo del 10-11) |
| R8 | Entrada del DT (camina desde un lateral y se sienta) | alto | animaciones de caminar y sentarse con el PersonajeDT |
| R9 | Interfaz: la pregunta abajo centrada; la cruz de respuestas más compacta y más abajo | medio | es la del encargo inicial (cruz direccional): se mantiene, solo se compacta |

Hago R1-R5 ya; son claras y no cambian cómo se juega. R6 va después, con capturas. R7-R9 tocan modelo, animación e interfaz, así que las propongo al dueño.

## 3. Lo que tenemos ya para el prólogo y lo que falta

**Tenemos:**
- Un prólogo 3D anterior (`visor/prologo*.gd`, 26-10): de la acera al club con el mentor (vestuario, campo, enfermería), la directiva, la prensa (`prologo_prensa.gd`) y la oficina con el PC. Vive en la CIUDAD, que la orden 33 dejó apagada, así que hay que llevarlo al club.
- El edificio del club con sus salas (`EdificioClub`: museo, utilería, plantas con ascensor), el vestuario, el túnel y el paseo a pie (`ExploradorEstadio`).
- PersonajeDT (con pelo, trajes y celebraciones), modelos de jugadores con su ropa, y animaciones de fútbol y de celebración (Quaternius, League).
- Diálogos con elección (`EventoDialogo`, `CuadroDialogo`), objetivos de la directiva (`directiva.objetivo`) y la rueda de prensa 3D.

**Falta** (por escena):

| Escena | Falta |
|---|---|
| Llegada / pasillos | Pasillo de oficinas con cuadros, puertas con rótulo y buena luz (hoy el edificio es funcional, de baja calidad). Cámara al hombro que sigue a dos personajes |
| Presidente y cuerpo técnico | Modelos con TRAJE y con CHÁNDAL del club de calidad cercana (hoy: maniquíes Quaternius y el DT). Animaciones: dar la mano, mano en la espalda, gestos al hablar, caminar juntos |
| Jugadores en la sala de estar | Sala con sofá, mesa baja y ventanal; animación de levantarse del sofá; rótulo con el nombre |
| Ciudad deportiva exterior | Campo de entrenamiento con verja y edificio (hoy hay campo, pero no ciudad deportiva) |
| Reunión con la directiva | Sala de reuniones (mesa larga, 6 sillas de oficina, portátiles, vasos, plantas, ventanal); animaciones de sentado al hablar; cámara con contraplanos; el menú de objetivos (ya existe la lógica) |
| Rueda de prensa | Ver §2 (R1-R9) |
| Todo | Sistema de CINEMÁTICA con guion: planos con cortes, subtítulos con tiempo, «Omitir» y elecciones dentro de la escena. La rueda y el sorteo ya cortan planos, pero no hay un guion reutilizable. Lip-sync o, al menos, boca y gestos al hablar |

## 4. Plan por pasos (estimación en sesiones de trabajo de ~1 día)

1. **Rueda de prensa R1-R6** (esta sesión: R1-R5 hoy, R6 después) — 0,5-1.
2. **Cinemática con guion** (`Cinematica`: lista de planos {cámara, objetivo, duración, subtítulo, elección}, «Omitir», cortes y fundidos), reutilizando lo de la rueda y el sorteo — 1-2.
3. **Personas de calidad**: presidente con traje y ayudantes con chándal del club, sobre la base del PersonajeDT (es el paso que pide la orden 34 antes del prólogo) — 2-4.
4. **Animaciones sociales**: caminar al lado, dar la mano, gestos al hablar, sentarse y levantarse, señalar — 2-3 (retarget de lo que haya en League-Soccer / Drive).
5. **Salas**: pasillo de oficinas, sala de estar de jugadores, sala de reuniones y sala de prensa con mesa larga, dentro de `EdificioClub` y con calidad de las instalaciones (orden 34) — 2-3.
6. **Guion del prólogo**: llegada → cuerpo técnico → jugadores → instalaciones → objetivos → rueda → oficina, con textos propios y el club del jugador (variando por club y país: regla 34) — 1-2.
7. **Medir** (llamadas por plano, MÍNIMA/BAJA/MEDIA) y capturas Forward+ de cada escena — 0,5.

Total: unas 9-15 sesiones. El orden lo marca la orden 34: primero los pasos 3-5 (calidad de modelos e instalaciones); después 2 y 6.

## 5. Hecho en la rueda de prensa (10-11)

- R1-R5: periodistas con menos luz, barra de focos, pared en damero fino (6 × 12), ramo de 4 micrófonos de medios y balón con los colores del club (`RuedaPrensaExtras`); la cámara de TV ya existía.
- R7 (`RuedaPrensaMesa`, bandera `activa`): con el personaje 3D, MESA LARGA con el frente del color del club y el escudo, el DT SENTADO (pose «sentado»), el JEFE DE PRENSA con traje a su lado y las sillas. Sin personaje 3D (retrato) sigue el atril. Sentado, el DT solo cambia de cara (los gestos de cuerpo entero lo levantaban).
- R6: planos para la mesa: frontal, general desde el fondo, tres cuartos (entre la mesa y la primera fila) y PLANO MEDIO del DT con los micrófonos; el ciclo alterna frontal y medio. El contraplano del periodista que pregunta se pone sobre el borde de la mesa (antes quedaba detrás del DT).
- R9: la columna de respuestas, abajo sobre la franja de la pregunta (deja libre la mesa).
- Antes/después (cámara real, ARG, USA y CHI): `docs/04_auditorias/rueda_prensa_antes_despues_2026-11-10.jpg`.
- R8: el DT ENTRA por la izquierda caminando («caminar_formal»), se gira hacia la sala y se sienta; mientras entra, la cámara se queda en el plano frontal. Sentado, solo cambia de cara: las poses «Sitting_Enter» y «Sitting_Talking» de la biblioteca extra lo dejaban hundido bajo la mesa. Una luz propia para el jefe de prensa (quedaba en silueta). Secuencia: `docs/04_auditorias/rueda_prensa_entrada_2026-11-10.jpg`.
- Plató a oscuras con foco cenital, periodistas en SILUETA (capa visual 2: las luces de la mesa no los tocan), placas con el escudo, botellas y vasos.
- **Hoja final en Forward+** (cámara real, CHI/ARG/USA; antes con atril, entrada y planos con la mesa): `docs/04_auditorias/rueda_prensa_forward_2026-11-10.jpg`. Llamadas (mediana, Forward+, portadas cerradas): CHI 740 → 756, ARG 529 → 557, USA 510 → 567 (+2 % a +11 %).
