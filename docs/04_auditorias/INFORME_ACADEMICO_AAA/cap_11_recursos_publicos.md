# Capítulo 11. Recursos públicos gratuitos con licencia comercial: qué existe para cerrar las brechas de Dinastía

Informe académico AAA de Dinastía · Fecha de redacción y de consulta de todas las fuentes: 16-11-2026.
Complementa a `../INFORME_AAA_2026-11-16.md` (diagnóstico y 100 tareas), al capítulo 2 (`cap_02_estado_del_arte.md`, §2.9: Mixamo, Quaternius UAL, Motion-Matching de Holden, Kokoro-82M, Piper, StatsBomb), a `dinastia-godot/LICENCIAS.md` (lo que ya viaja en los builds) y a `../animaciones_gratuitas_2026-11-11.md` (catálogo de animaciones de la sesión 10). No repite lo que esos documentos ya establecen: lo cita y lo amplía.

---

## Resumen

Este capítulo cataloga, por necesidad del juego, los recursos públicos y gratuitos cuya licencia permite **usarlos y distribuirlos dentro de un juego comercial de código cerrado**, según la regla del dueño (orden 57): CC0, CC BY y CC BY-SA con atribución, MIT, Apache 2.0, BSD, zlib, ISC, SIL OFL para tipografías y términos propietarios equivalentes a los de Mixamo; nada no comercial (NC), nada sin derivadas (ND) si hay que modificarlo, nada «solo uso personal» y ningún código GPL/AGPL dentro del binario (como mucho, «solo herramienta externa»).

Se revisaron alrededor de 120 recursos en 18 categorías. La gran mayoría tiene la licencia **verificada en su fuente primaria** (página de licencia del editor, archivo `LICENSE` del repositorio o ficha de la API del sitio); una docena solo por extracto de búsqueda o fuente secundaria (nivel E), y unos 20 quedaron descartados (no comerciales, copyleft dentro del binario, sin licencia escrita) o sin verificar. Los hallazgos más útiles para el proyecto, ordenados por el hueco que cierran, son:

1. **Grada**: hay grabaciones reales de estadios de fútbol con licencia **CC0** en Freesound (un Mineirão con unos 60.000 espectadores, una plaza de Ciudad de México gritando gol en el Mundial 2014, un estadio noruego en cuatro técnicas de micrófono). Sirven de capa base de la grada sin ninguna obligación.
2. **IA del partido**: el conjunto de eventos de Wyscout publicado por Pappalardo y otros (*Scientific Data*, 2019) tiene licencia **CC BY 4.0** (1.941 partidos, 3,25 millones de eventos, 7 competiciones). A diferencia de StatsBomb (capítulo 2, prohibido para uso comercial), **sí permite calibrar un juego comercial con atribución**. Corrige en parte la hipótesis H4 del capítulo 2 («los datos de fútbol se han cerrado»): hay al menos una base de eventos grande y comercialmente utilizable.
3. **Animación procedural**: Godot 4.6 trajo de vuelta la cinemática inversa (`TwoBoneIK3D`, `FABRIK3D`, `CCDIK3D`, `SplineIK3D`, `JacobianIK3D`) sobre `SkeletonModifier3D`, junto con `LookAtModifier3D` (4.4). Están **dentro del motor** (MIT) y cubren el IK de pie al balón y la cabeza que mira el balón (tareas 12 y 13 del informe AAA) sin dependencias nuevas. Existe además un *motion matching* para Godot 4.4 como GDExtension con licencia MIT.
4. **Comentarista**: Kokoro-82M (Apache 2.0) trae **tres voces en español** (`ef_dora`, `em_alex`, `em_santa`) y tres en portugués de Brasil, pero su canal de fonemas para idiomas distintos del inglés depende de **espeak-ng (GPLv3)** y de `phonemizer` (GPL). La forma limpia de usarlo es **pre-generar los audios fuera del juego** (herramienta externa) y distribuir solo los `.ogg`. Chatterbox (MIT, 23 idiomas, marca de agua inaudible) y MeloTTS (MIT, español) son alternativas verificadas; XTTS-v2 (licencia CPML, solo no comercial) y los pesos de F5-TTS (CC BY-NC 4.0) quedan **descartados**.
5. **Luz, cielo y estadio**: Poly Haven (CC0, incluidas sus 2.389 piezas y su API, que también permite uso comercial) tiene HDRI de estadios reales (`stadium_01`, `orlando_stadium`, `stadium_exterior`, `suburban_soccer_park`), noches con luna y estrellas, tejidos de punto tipo camiseta (`cotton_jersey`, `jersey_melange`, `waffle_pique_cotton`), césped en 3D y dos balones de fútbol modelados.
6. **Interfaz**: más de 6.500 iconos MIT (Tabler), los Material Symbols (Apache 2.0) y unos 4.200 iconos de juego CC BY 3.0 (game-icons.net); tipografías condensadas OFL de Google Fonts adecuadas para dorsales y marcadores (Big Shoulders Display, Teko, Saira Condensed, Anton, Oswald, Chakra Petch…).
7. **Herramientas**: Tracy (BSD-3) y Perfetto (Apache 2.0) ya se pueden compilar dentro de Godot con la opción `profiler=` de SCons; RenderDoc (MIT) depura Vulkan y OpenGL ES en Android; GUT y gdUnit4 (MIT) son marcos de pruebas compatibles con Godot 4.7.

Dos correcciones a documentos previos: el **Bandai Namco Research Motion Dataset** figura hoy en su repositorio como **CC BY-NC 4.0** (no CC BY-NC-ND, como dice `animaciones_gratuitas_2026-11-11.md`); el veredicto no cambia (no comercial). Y la base de **CMU**, que el capítulo 2 marca como «no verificada», está verificada en `LICENCIAS.md` por el texto citado en el `READMEFIRST.txt` de la conversión de Bruce Hahne; su web (`mocap.cs.cmu.edu`) devolvió 503 también hoy.

La conclusión práctica es un **paquete de 25 recursos** (§11.7) que cubre, sin coste y con riesgo legal bajo, la grada, el balón y el árbitro, la luz y el cielo, la tela de las camisetas, los dorsales, los iconos, el IK, la calibración de la IA y el perfilado. Lo que **no existe** gratis con licencia limpia y calidad suficiente sigue siendo lo mismo que señalaba el capítulo 2: animaciones de fútbol específicas (sobre todo de **portero**), caras y piel fotorrealistas sin derecho de imagen ajeno, y voz de comentarista natural en español.

---

## 11.1 Introducción

### 11.1.1 Problema

El informe AAA (§2-§6) y el capítulo 2 coinciden en que la distancia de Dinastía con PES 2020 está en el partido y en su presentación: animación, cámara de televisión, grada, comentario, caras, camisetas y luz. Buena parte de esa distancia no se cierra con código sino con **contenido**: grabaciones, texturas, cielos, tipografías, iconos, clips de movimiento, voces y datos de referencia. Un estudio AAA lo produce o lo compra; Dinastía no tiene presupuesto (orden 57) y su regla legal es estricta: todo lo que viaje en un build público debe tener una licencia que permita **uso comercial y redistribución**.

El riesgo no es teórico. `LICENCIAS.md` todavía arrastra elementos amarillos (🟡) de origen dudoso: modelos de Sketchfab sin licencia en el zip, el pack de mocap de Gumroad sin texto de licencia, los golpes de balón de League-Soccer que no indican su origen, la música del minijuego retro. Cada uno de ellos es un posible bloqueo antes de publicar en Steam o en Google Play. Este capítulo busca **sustitutos verificados** para esos huecos y para los que el informe AAA abre.

### 11.1.2 Objetivos

1. Para cada carencia del informe AAA (animación de fútbol y portero, *motion matching* e IK, caras/pelo/piel, camisetas, estadios, público, césped, cielo y clima, sonido de grada y balón, comentarista y voz, música, fuentes, iconos, datos de fútbol para validar la IA, herramientas de QA y perfilado, traducción), reunir los mejores recursos públicos y gratuitos.
2. Verificar la licencia de cada uno **en la página real** del recurso y registrar qué obligaciones impone (atribución, *share-alike*, avisos de copyright, prohibiciones específicas como el entrenamiento de IA).
3. Valorar su encaje técnico con Godot 4.7, con el móvil (orden 22: 60 FPS; calidad por defecto la más baja) y con las reglas del proyecto (nada de LFS nuevo, scripts de menos de 450 líneas, extensión C++ con gemelo GDScript).
4. Proponer un paquete priorizado y una plantilla para anotar cada recurso en `LICENCIAS.md`.

### 11.1.3 Alcance y advertencia

El capítulo es descriptivo. **No es asesoría jurídica**. Describe lo que dicen las licencias leídas el 16-11-2026; las licencias cambian, y algunas cuestiones (por ejemplo, si un modelo de voz entrenado es obra derivada de sus grabaciones) son legalmente abiertas, como reconoce el propio proyecto Piper [R33]. Antes de publicar, el registro de licencias debería revisarlo una persona con formación jurídica.

---

## 11.2 Método

### 11.2.1 Fuentes y procedimiento

Para cada candidato se buscó la **fuente primaria de la licencia**, por este orden de preferencia:

1. **Archivo de licencia del repositorio** (`LICENSE`, `LICENSE.md`, `COPYING`), leído directamente en `raw.githubusercontent.com` (primera línea con el nombre de la licencia y el titular).
2. **Ficha de licencia de la API** del sitio: `api.polyhaven.com` (2.389 recursos, con tipo y etiquetas), `ambientcg.com/api/v2`, metadatos `license:` de la API de modelos de Hugging Face.
3. **Página de licencia o de preguntas frecuentes** del editor (Poly Haven, ambientCG, Kenney, Freesound, Sketchfab, Blender Studio, Sonniss, Incompetech, game-icons.net, AMASS, SFU).
4. **Artículo publicado** cuando la licencia de un conjunto de datos se declara en él (Pappalardo y otros, *Scientific Data*, en PubMed Central).
5. Solo si nada de lo anterior estaba accesible, **extractos de búsqueda** o fuentes secundarias.

Además se comprobó con una petición HTTP que cada URL de recurso concreto citada en las tablas responde (código 200 o redirección).

### 11.2.2 Niveles de verificación

Igual que en el capítulo 2, cada recurso lleva un nivel:

| Nivel | Significado |
|---|---|
| **L** | Licencia leída en la fuente primaria (archivo de licencia, página oficial, ficha de API o artículo). |
| **E** | Solo extracto de buscador o fuente secundaria; plausible pero sin lectura directa. No se recomienda integrar sin repetir la verificación. |
| **SV** | Sin verificar: la fuente no declara licencia, o no se pudo acceder. **No se recomienda.** |

### 11.2.3 Accesos fallidos (para no ocultarlos)

- `static.makehumancommunity.org`: el nombre no resuelve desde este contenedor (fuera de los dominios permitidos de la red de la sesión). La licencia de MakeHuman se verificó en su `LICENSE.md` de GitHub (nivel L).
- `mocap.cs.cmu.edu/faqs.php`: 503 (igual que en el capítulo 2).
- `opengameart.org/content/faq`: 403. OpenGameArt se trata como **agregador** cuyas licencias se leen pieza a pieza.
- `www.blender.org/about/license/`: 403. La posición de Blender sobre la obra producida se tomó del manual oficial y de su lista de correo (nivel E).
- `metahuman.com/license`: redirige a un inicio de sesión. Los términos de MetaHuman quedan en nivel E.
- La API de GitHub (`gh api`) no está habilitada para repositorios ajenos en esta sesión; por eso las licencias de repositorios se leyeron en el archivo `LICENSE` en bruto.

### 11.2.4 Lo que no se hizo

No se descargó ni se integró ningún recurso (el encargo es investigar; no se edita código ni se hace commit). No se probó la compatibilidad real de los complementos de Godot con la 4.7.2 del proyecto: donde la página declara otra versión, se anota como riesgo. No se escucharon todas las grabaciones; las cuatro que se recomiendan por nombre se verificaron en su ficha (licencia, duración y descripción).

---

## 11.3 Criterios de licencia

### 11.3.1 Semáforo aplicado

| Licencia o término | ¿Uso comercial? | ¿Redistribuir dentro del juego? | Obligaciones | Veredicto para Dinastía |
|---|---|---|---|---|
| **CC0 1.0** / dominio público | Sí | Sí | Ninguna (la atribución es cortesía) | 🟢 preferente |
| **MIT**, **ISC**, **BSD-2/3**, **zlib**, **Boost** | Sí | Sí | Conservar el aviso de copyright y el texto de la licencia en los créditos o en un archivo que viaje con el build | 🟢 |
| **Apache 2.0** | Sí | Sí | Conservar `LICENSE` y `NOTICE`; marcar los archivos modificados; concesión de patentes | 🟢 |
| **CC BY 3.0/4.0** | Sí | Sí | Atribución con autor, título, licencia y enlace, e indicar si se modificó | 🟢 con crédito visible |
| **CC BY-SA 3.0/4.0** | Sí | Sí | Atribución **y** compartir las adaptaciones de **esa obra** con la misma licencia | 🟡 aceptable para un recurso aislado (una textura, un sonido); evitar en recursos que se mezclan con material propio que no se quiere liberar |
| **SIL OFL 1.1** (tipografías) | Sí | Sí, incrustada | No vender la fuente sola; no usar el «nombre reservado» en una versión modificada; incluir el texto OFL | 🟢 (ya se cumple en `assets/fuentes/OFL_*.txt`) |
| Términos propietarios gratuitos (Mixamo, Sonniss GDC, MetaHuman, Rokoko) | Sí, con condiciones | Solo **integrado** en la obra; nunca el archivo suelto | Varían: no redistribuir en bruto, no entrenar IA, umbrales de ingresos | 🟡 caso a caso; guardar copia fechada de los términos |
| **GPL/LGPL/AGPL** (código) | Sí | Solo si se libera el código que lo enlaza (GPL/AGPL) | Copyleft | 🔴 dentro del binario · 🟢 **solo herramienta externa** (Blender, Krita, Audacity, espeak-ng, Piper, LibreTranslate, Weblate) cuyo **resultado** se distribuye |
| **CC BY-NC**, **CPML**, «non-commercial research», «solo uso personal» | **No** | — | — | 🔴 descartado |
| **CC BY-ND** | Sí, sin modificar | Sí | No se puede alterar (ni recortar, ni recolorear, ni retargetear) | 🔴 en la práctica (todo recurso del juego se adapta) |
| Sin licencia escrita | Desconocido | — | Por defecto, todos los derechos reservados | 🔴 hasta tener permiso escrito |

### 11.3.2 Matices que importan en un juego

1. **CC BY-SA no contamina el juego entero.** El *share-alike* se aplica a las **adaptaciones de la obra licenciada** (la textura modificada, el sonido editado), no al ejecutable que la contiene, que es una colección. Aun así, si una textura BY-SA se hornea en un atlas con texturas propias, el atlas podría considerarse adaptación: por prudencia, los recursos BY-SA se mantienen como archivos separados.
2. **Herramientas GPL y su resultado.** El manual de Blender indica que la GPL cubre la aplicación, no la obra que se crea con ella; la lista de correo del proyecto precisa que los juegos son «salida» del programa y no quedan cubiertos por la GPL, salvo los datos GPL que se incluyan dentro (por ejemplo, iconos de la propia interfaz de Blender) [R40][R41] (nivel E). El mismo razonamiento se aplica a pre-generar audios con un sintetizador GPL: **el audio no hereda la GPL del programa**, pero sí puede heredar restricciones de la **voz** (su conjunto de datos), que es otra licencia.
3. **Pesos de modelos frente a datos de entrenamiento.** Un modelo con licencia Apache o MIT puede haberse entrenado con datos CC BY (Kokoro cita dos) o desconocidos. La licencia del repositorio no resuelve la del conjunto de datos; Piper lo dice expresamente: «el proyecto no concede ninguna licencia sobre los modelos de voz» y cada voz vale lo que su `MODEL_CARD` [R33] (L).
4. **Cláusulas contra el entrenamiento de IA.** Sonniss [R27], Mixamo (capítulo 2, [64]) y MetaHuman [R18] prohíben usar sus recursos para entrenar modelos. Poly Haven prohíbe el raspado masivo de su web (no de su API) [R1]. Hoy no afecta a Dinastía, pero cierra la puerta a, por ejemplo, entrenar un *learned motion matching* con clips de Mixamo.
5. **CC0 no limpia marcas ni derecho de imagen.** Una foto CC0 de un estadio con publicidad, un escaneo CC0 de una persona real o una camiseta CC0 con un escudo siguen sujetos a marca y a derecho de imagen. Coherente con `LICENCIAS.md` §2 y con la regla «no se usan fotos de personas reales en lo público»: **ningún escaneo de persona real**, sea cual sea su licencia, entra en el build público.
6. **Datos personales.** Wikidata es CC0, pero los datos de futbolistas reales son datos personales en el sentido del RGPD; el proyecto ya los separa en `pack_real.json` (no se publica). Este capítulo solo recomienda datos abiertos para **cifras agregadas** (medias por partido, capacidades de estadios, calendarios), no para fichas de personas.

---

## 11.4 Punto de partida: lo que Dinastía ya usa

Resumen de `LICENCIAS.md` y del catálogo de animaciones (no se repite el detalle):

| Ámbito | Ya en uso | Licencia | Estado |
|---|---|---|---|
| Cuerpos, ropa, pelo base | Quaternius Universal Base Characters, Modular Outfits, Ultimate Modular Men/Women | CC0 | 🟢 |
| Animación | League-Soccer (293 + espejos), UAL 1/2 Standard, 100STYLE (2.522), CMU (144 + espejos), Mesh2Motion | Apache 2.0 / CC0 / CC BY 4.0 / «libre comercial» / CC0 | 🟢 |
| Animación de fútbol | «Free mocap pack 05: Soccer» (Rohr, 21 clips) | sin texto de licencia | 🟡 (no va en builds públicos hasta confirmarla) |
| Ciudad, muebles | Kenney (11 kits), KayKit, Poly Haven (texturas y 9 modelos) | CC0 | 🟢 |
| Caras | dibujadas por código; malla MediaPipe | propio / Apache 2.0 | 🟢 |
| Sonido | 205 efectos y 6 músicas sintetizados por código; UI de Kenney y VCSL | propio / CC0 | 🟢 |
| Golpes de balón y poste | WAV de League-Soccer | origen no indicado | 🟡 |
| Tipografías | Inter, Barlow Condensed, Bebas Neue, Cinzel, Gelasio, Noto (varias) | OFL 1.1 | 🟢 |
| Banderas | flag-icons | MIT | 🟢 |
| Iconos de menú | 16 trazos SVG propios | propio | 🟢 |

Lecciones para este capítulo: (a) el proyecto ya domina el flujo CC0 → conversión → biblioteca de uso comprimida (`anims_uso_a_res.gd`), y conviene repetirlo para sonido y texturas; (b) los únicos amarillos de sonido y animación son de **fútbol** (balón, poste, mocap de Rohr), justo donde los recursos libres escasean; (c) todo lo de terceros que no se usa vive en `terceros/` con `.gdignore`, lo que permite guardar bibliotecas completas sin engordar el build.

---

## 11.5 Recursos por necesidad del juego

Cada subsección sigue el mismo esquema: **qué falta** (con la tarea del informe AAA, §11), **candidatos** (tabla), **encaje con Godot y móvil**, **riesgo legal** y **recomendación**.

### 11.5.1 Animaciones de fútbol y de portero

**Qué falta.** Tareas 15 (10-12 animaciones clave de portero), 17 (6-8 regates legibles), 18 (reacciones a falta, caída, lesión) y la fila «cabezazo, entrada de pie, portero» que el catálogo de la sesión 10 dejó sin cubrir.

**Candidatos.**

| Recurso | URL | Licencia (nivel) | Obligaciones | Contenido útil | Encaje / riesgo |
|---|---|---|---|---|---|
| CMU Graphics Lab Motion Capture Database (ya en uso, 144 clips) | http://mocap.cs.cmu.edu | «free for use in research and commercial projects worldwide» (L vía `READMEFIRST.txt`, ver `LICENCIAS.md`) | Agradecimiento pedido (ya en `creditos.gd`) | Sujetos 10/11 (patadas), 33/34 (lanzar/atrapar), 124 (deportes), caídas (90), saltos | Ya integrado. **Lo que queda por extraer**: atrapes (33/34) y saltos laterales como base de estiradas del portero, y caídas para reacciones. Riesgo bajo |
| Rokoko Motion Library (gratis dentro de Rokoko Studio) | https://www.rokoko.com/ (biblioteca dentro de su aplicación) | Prensa y página de precios: los movimientos gratuitos se pueden usar en proyectos comerciales (E) | Cuenta; exportación desde su aplicación; no se leyó el texto de la licencia | Unos 150 clips gratuitos en su lanzamiento (2020) | **E**: no integrar hasta leer el acuerdo y confirmar si permite incrustar en un build. Riesgo medio |
| Mixamo (Adobe) | https://www.mixamo.com | Términos ya resumidos en el capítulo 2 [64] (E: página oficial 403) | No redistribuir FBX en bruto; prohibido entrenar IA | Catálogo grande de humanoides; incluye clips deportivos [C] | Descartado por la sesión 10 porque el repositorio distribuiría los FBX. **Matiz**: los términos prohíben redistribuir el archivo suelto, no la animación integrada en el juego; una conversión directa a `.res` dentro del `.pck`, sin dejar los FBX en el repo público, encaja en «términos tipo Mixamo» de la orden 57. Requiere OK del dueño |
| Truebones (mocap gratis en Gumroad) | https://truebones.gumroad.com | Extracto: «royalty free… even commercial» (términos de 2019) (E) | Las ofertas gratuitas cambian a menudo | Clips sueltos; parte son conversiones de CMU | **SV en la práctica**: no se leyó el texto vigente. No recomendado |
| SFU Motion Capture Database | https://mocap.cs.sfu.ca | «cannot be used for commercial products or resale» (L) | — | Locomoción, parkour, baile, artes marciales | 🔴 no comercial |
| AMASS | https://amass.is.tue.mpg.de/license.html | Solo investigación, educación o arte **no comerciales**; prohíbe entrenar redes para uso comercial (L) | — | Miles de secuencias | 🔴 |
| LAFAN1 (Ubisoft La Forge) | https://github.com/ubisoft/ubisoft-laforge-animation-dataset | CC BY-NC-ND 4.0 (L) | — | Locomoción, combate, caídas | 🔴 |
| Bandai Namco Research Motion Dataset 1 y 2 | https://github.com/BandaiNamcoResearchInc/Bandai-Namco-Research-Motiondataset | CC BY-NC 4.0 (L; scripts de Blender: MIT) | — | 36.000+ cuadros con estilos | 🔴 (corrección: no es ND, pero sí NC) |

**Encaje.** Ninguna base comercialmente utilizable trae estiradas de portero ni cabezazos de calidad. Lo realista es: (1) **sacar más de CMU** (atrapes, saltos laterales, caídas) y convertirlo con las herramientas que ya existen (`cmu_clips.py`, `cmu_a_res.gd`); (2) **componer** la estirada con un salto lateral más IK de brazos hacia el balón (§11.5.2): el cuerpo vuela, las manos buscan el balón; (3) si el dueño lo aprueba, sumar Mixamo **solo convertido a `.res`**, sin FBX en el repositorio, con copia fechada de los términos.

**Riesgo legal.** Bajo con CMU; medio con Mixamo y Rokoko (términos propietarios que pueden cambiar). Alto e inaceptable con AMASS, LAFAN1, SFU y Bandai Namco.

**Recomendación.** Prioridad 1: atrapes, saltos y caídas de CMU para un portero compuesto. Prioridad 2 (con OK del dueño): Mixamo convertido para 6-8 gestos de portero y cabezazo. Rokoko y Truebones solo tras leer el texto completo de su licencia.

### 11.5.2 *Motion matching*, cinemática inversa, mezcla y máquinas de estados

**Qué falta.** Tareas 11 (blend space 2D), 12 (IK de pie al balón), 13 (cabeza que mira el balón), 16 (inclinación y cadera) y la propuesta I5 del capítulo 2 (*motion matching* clásico sobre los clips existentes).

| Recurso | URL | Licencia (nivel) | Obligaciones | Qué aporta | Encaje con Godot 4.7 y móvil |
|---|---|---|---|---|---|
| **Nodos IK nativos de Godot 4.6+**: `IKModifier3D`, `TwoBoneIK3D`, `ChainIK3D`, `SplineIK3D`, `IterateIK3D`, `FABRIK3D`, `CCDIK3D`, `JacobianIK3D`; y `BoneTwistDisperser3D`, `LimitAngularVelocityModifier3D` | https://godotengine.org/article/inverse-kinematics-returns-to-godot-4-6/ · https://docs.godotengine.org/en/4.6/classes/class_ikmodifier3d.html | MIT (motor) (L) | Ninguna adicional | IK de dos huesos determinista (piernas, brazos), cadenas (columna), límite de velocidad angular para suavizar | **Excelente**: ya están en el motor que usa el proyecto; corren en C++. `TwoBoneIK3D` y `SplineIK3D` son siempre deterministas, lo que encaja con las huellas byte a byte del banco |
| **`LookAtModifier3D`** (Godot 4.4+) | https://godotengine.org/article/inverse-kinematics-returns-to-godot-4-6/ | MIT (L) | — | IK de un hueso: cabeza y mirada al balón | Resuelve la tarea 13 (`mira_balon`) con un nodo |
| **Retargeting 3D de Godot** | https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.html | MIT (L) | — | Mapa de huesos y perfil humanoide | Ya lo usa el proyecto de hecho para CMU y 100STYLE |
| **Godot Motion Matching** (Guilherme Sousa) | https://github.com/GuilhermeGSousa/godot-motion-matching | MIT, © 2024 Guilherme Sousa (L, `LICENSE.md`) | Conservar aviso MIT | *Motion matching* integrado en `AnimationTree`; base de poses con rasgos | GDExtension declarada para **Godot 4.4**: hay que recompilar contra 4.7 y medirlo. Exige **root motion** y hueso raíz a la altura del pie: los clips del proyecto no llevan desplazamiento de cadera (el motor mueve al jugador), así que haría falta reexportar. Sus datos de demostración vienen de O3DE. Riesgo técnico medio |
| Motion-Matching (Daniel Holden), referencia | https://github.com/orangeduck/Motion-Matching | MIT (L; ya citado en cap. 2 [41]) | — | Código C++ de referencia y *learned motion matching* | Útil para portar el núcleo a la extensión C++ del proyecto (con su gemelo GDScript) |
| **LimboAI** (árboles de comportamiento y máquinas de estados jerárquicas) | https://github.com/limbonaut/limboai | MIT; logo y arte de la demo CC BY 4.0 (L) | Aviso MIT | HSM y BT con depurador visual | Versión 1.8.x para Godot 4.6+ como GDExtension, y como módulo para 4.7. Encaja con el **director de TV** (estados juego vivo → evento → reacción → repetición) y con la IA. Riesgo: otra dependencia nativa que compilar para Android |
| Beehave (árboles de comportamiento en GDScript) | https://github.com/bitbrain/beehave | MIT, © 2023 bitbrain (L) | Aviso MIT | BT puro GDScript | Sin binarios: funciona igual en Android y Web. Menos rendimiento que LimboAI |

**Recomendación.** Antes que cualquier complemento, usar lo que el motor ya trae: `TwoBoneIK3D` para pie-balón y anclaje, `LookAtModifier3D` para la cabeza, `LimitAngularVelocityModifier3D` contra tirones. Es la mejora de animación con mejor relación coste/beneficio del capítulo. El *motion matching* de Sousa es un experimento de 1-2 semanas que conviene hacer **en la arena de pruebas** (orden 22) con los ciclos de 100STYLE, que sí son locomoción continua.

### 11.5.3 Caras, piel, pelo y cuerpos

**Qué falta.** Tareas 35 (piel), 37 (pelo), 38 (tipos de cuerpo), 39 (biblioteca pública de 300-500 caras). Restricción dura: nada de personas reales en lo público.

| Recurso | URL | Licencia (nivel) | Obligaciones | Qué aporta | Encaje / riesgo |
|---|---|---|---|---|---|
| **MakeHuman** (activos) | https://github.com/makehumancommunity/makehuman/blob/master/LICENSE.md | Código AGPL; **activos (malla base, objetivos, texturas, ropa, poses) CC0 1.0**; el proyecto considera que la salida exportada «no contiene lógica del programa» y es del usuario (L) | Ninguna sobre lo exportado | Cuerpos y caras paramétricos (edad, peso, musculatura, rasgos), topología única | **Solo herramienta externa** (el programa es AGPL). Ideal para generar tipos de cuerpo y una biblioteca de caras **sintéticas**, que no son de nadie. Exportar a glTF y retargetear al esqueleto del juego. Riesgo bajo |
| MB-Lab | https://github.com/animate1978/MB-Lab | Los modelos generados son **AGPL 3** por defecto; su propia licencia avisa de que puede ser «un obstáculo» para un juego de código cerrado (L) | Copyleft sobre los modelos | Personajes realistas | 🔴 descartado; repositorio archivado |
| **Blender Studio** (personajes, películas abiertas) | https://studio.blender.org/terms-and-conditions | Salvo aviso, contenido digital bajo **CC BY 4.0** (L); algunos recursos son CC BY-SA o CC0 según su ficha (E) | Atribución «© Blender Foundation», revisar la ficha de cada recurso | Personajes con rig de producción, pelo, ropa | Estilo animado, no fotorreal; útil como **referencia de rig y sombreado** de pelo. Riesgo bajo si se acredita |
| MetaHuman (Epic) | https://www.metahuman.com/license (requiere sesión) | Prensa de junio de 2025: personajes «non-engine products», utilizables en Unity o Godot sin el 5 % de regalías; gratis por debajo de 1 M USD/año; prohíbe entrenar IA (E) | EULA de Unreal; cuenta Epic | Caras y cuerpos de calidad AAA | **E y condicionado**: no se pudo leer el EULA vigente y una fuente de 2026 sostiene lo contrario. Además, mallas pesadas para móvil y pipeline Unreal-Windows. No recomendado sin lectura del EULA |
| Quaternius Ultimate Modular Men/Women (en uso) | https://quaternius.com/packs/ultimatemodularcharacters.html | CC0 (L, `LICENCIAS.md`) | — | Civiles realistas | Ya integrado |
| Avatar regalo del dueño (en uso) | — | Confirmada por el dueño (11-11) | — | Esqueleto Mixamo de 73 huesos | Ya integrado |

**Piel y pelo.** No se encontró ninguna biblioteca **gratuita y comercial** de texturas fotorrealistas de piel o de tarjetas de pelo con licencia verificada; las conocidas son de pago. La vía coherente con el informe AAA (§6.2) es procedural: el sombreado de piel *wrap lighting* con color de sangre y sudor por minuto, y los cortes de pelo del Drive (licencia confirmada por el dueño, orden 16) con sombreado anisótropo. MakeHuman aporta además texturas de piel CC0 de calidad media como punto de partida.

**Riesgo legal.** Bajo con MakeHuman y Blender Studio. Cualquier escaneo de persona real, aunque sea CC0 en Sketchfab, queda fuera por derecho de imagen (§11.3.2).

### 11.5.4 Camisetas, tela, redes y dorsales

**Qué falta.** Tareas 34 (parches claros), 36 (tela con malla, dorsal y nombre nítidos).

| Recurso | URL | Licencia (nivel) | Qué aporta | Encaje |
|---|---|---|---|---|
| Poly Haven `cotton_jersey` (punto acanalado) | https://polyhaven.com/a/cotton_jersey | CC0 (L) | Mapa normal y de rugosidad de punto de camiseta, hasta ~8K | Bajar a 512-1K, usar solo el **normal** como detalle repetido (tileado fino) sobre el color procedural del club |
| Poly Haven `jersey_melange`, `waffle_pique_cotton`, `stretch_poplin`, `terlenka`, `bi_stretch` | https://polyhaven.com/a/jersey_melange · https://polyhaven.com/a/waffle_pique_cotton | CC0 (L) | Variantes: jaspeado, piqué (cuello de polo), elástico | Una tela por «época» o estilo de uniforme |
| ambientCG, familia `Fabric` (106 materiales) | https://ambientcg.com/view?id=Fabric086 | CC0 1.0; permite incluir los archivos en bruto en un videojuego (L) | Tejidos variados con PBR | Alternativa y complemento a Poly Haven |
| ambientCG `Net001A`-`Net004B` (8 redes) | https://ambientcg.com/view?id=Net004A | CC0 (L) | Redes con canal alfa | Red de la portería y mallas de las tribunas |
| Material Maker (herramienta) | https://github.com/RodZill4/material-maker | MIT, © 2018 Rodolphe Suescun (L) | Editor de materiales procedurales hecho en Godot | Generar normales de malla deportiva (agujeros de ventilación) sin depender de fotos |
| Tipografías de dorsal (ver §11.5.12) | https://github.com/google/fonts | OFL 1.1 (L) | Números y nombres | Atlas SDF de dorsales por club |

**Recomendación.** Una sola textura de normal CC0 de punto, en 512 px y con mipmaps, aporta la lectura de «tela» a la distancia de la cámara real sin coste de memoria apreciable. Los parches claros (tarea 34) son un fallo de sombreado o de UV, no de contenido: este recurso no los arregla por sí solo.

### 11.5.5 Estadios y su entorno

**Qué falta.** Tareas 44 (20-30 estadios icónicos), 45 (butacas por color), y los modelos 🟡 de Sketchfab de `LICENCIAS.md` (`asientos_lod.glb`, `arco_entrada.glb`, `estadio.obj`).

| Recurso | URL | Licencia (nivel) | Qué aporta | Encaje / riesgo |
|---|---|---|---|---|
| Poly Haven HDRI `stadium_01` (Sergej Majboroda, 16K) | https://polyhaven.com/a/stadium_01 | CC0 (L) | Luz y reflejos de un estadio real al atardecer | Iluminación ambiental y reflejos; no como fondo visible (deformaría la geometría propia) |
| Poly Haven HDRI `orlando_stadium`, `stadium_exterior`, `suburban_football_field`, `suburban_soccer_park` | https://polyhaven.com/a/orlando_stadium · https://polyhaven.com/a/suburban_football_field | CC0 (L) | Estadio de fútbol a mediodía, exterior de estadio (para la intro), campos de barrio | Luz de partidos de liga chica y de entrenamiento |
| Poly Haven texturas de hormigón, metal y asientos | https://polyhaven.com | CC0 (L) | Materiales de gradas, túneles, vomitorios | Ya se usan (`assets/cc0/`); el descargador `bajar_cc0.py` sirve tal cual |
| ambientCG `Concrete` (67) | https://ambientcg.com | CC0 (L) | Hormigón visto, pintado, sucio | Variedad para 536 arquitecturas paramétricas |
| Kenney kits (en uso) | https://kenney.nl | CC0 (L) | Piezas modulares | Ya en el repo |
| Sketchfab, modelos con licencia **CC0** o **CC BY** | https://sketchfab.com | CC BY: se puede usar con crédito; CC0 sin crédito; NC/ND no; la licencia «Standard» prohíbe distribuir el archivo como suelto; «Editorial» prohíbe el uso comercial (L, centro de ayuda y página de licencias) | Estadios y butacas modelados por la comunidad | **Riesgo medio-alto**: la licencia la elige quien sube el modelo, que puede no ser su autor (modelos extraídos de juegos comerciales, como el `coche1.fbx` ya descartado). Exigir autor identificable, fecha y captura de la ficha |
| Blender (herramienta) | https://www.blender.org | GPL (el programa); la obra creada no queda cubierta (E) | Modelado de estadios icónicos propios | Solo herramienta externa |

**Funciones del motor que valen como «recurso».** Godot ya incluye LOD automático de mallas, rangos de visibilidad (HLOD) y `MultiMeshInstance3D` [R44][R45][R46]: las butacas por nivel y color (orden 13) son un caso de manual de `MultiMesh` con color por instancia.

**Recomendación.** Sustituir los tres modelos 🟡 de Sketchfab por piezas propias en Blender con texturas CC0, en vez de intentar verificar su origen. Para los 20-30 estadios icónicos, modelar los rasgos (cubierta, arco, fachada) en Blender: no existen modelos libres de estadios reales con licencia limpia, y además tendrían marcas y arquitectura protegida.

### 11.5.6 Público

**Qué falta.** Tareas 27 (planos al público con figuras 3D), 40 (sprites del público horneados desde modelos de calidad), 41 (carteles y pancartas).

| Recurso | URL | Licencia (nivel) | Qué aporta | Encaje |
|---|---|---|---|---|
| **Quaternius «Background Posed Humans»** (28 modelos) | https://quaternius.com/packs/backgroundposedhumans.html | CC0: «Free to use in personal, educational and commercial projects» (L) | Personas en pose para fondo | Hornear **sprites** por ángulo (tarea 40) y poblar el sector cercano en 3D |
| Mesh2Motion (en uso) | `assets/characters/quaternius/anims_m2m/` | CC0 (L, `LICENCIAS.md`) | Clips de medio cuerpo | Ya integrado |
| MakeHuman (ver §11.5.3) | — | Activos CC0 (L) | Variedad de cuerpos para el horneado | Herramienta externa |
| Godot Octahedral Impostors | https://github.com/wojtekpil/Godot-Octahedral-Impostors | MIT, © 2020 wojtekpil y K. S. Ernest (iFire) Lee (L) | Impostores octaédricos (una malla vista desde cualquier ángulo como un quad) | **Compatibilidad con Godot 4 sin confirmar** (su documentación menciona `ImmediateGeometry`, que no existe en 4.x). Vale como referencia de la técnica; el horneado se puede escribir propio |
| `MultiMeshInstance3D` (motor) | https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html | MIT (L) | Miles de instancias en una llamada de dibujo | Base de la grada 2D actual |

**Recomendación.** Usar Background Posed Humans y los civiles modulares para hornear un atlas de 8-16 ángulos por figura, y dejar el 3D animado solo en el sector que encuadra el plano de reacción. Las pancartas son texto ficticio por idioma (ya planificado) y no necesitan recurso externo.

### 11.5.7 Césped

**Qué falta.** Tarea 43 (desgaste por minuto, marcas de tacos, patrón de corte) y la pasada final del motor (pasto, orden 13; `grass.blend` del Drive a evaluar).

| Recurso | URL | Licencia (nivel) | Qué aporta | Encaje |
|---|---|---|---|---|
| ambientCG `Grass001`-`Grass008` | https://ambientcg.com/view?id=Grass004 | CC0 (L) | Texturas PBR de césped | Base del campo en MÍNIMA y MEDIA, con franjas de corte en el sombreador |
| Poly Haven `grass_medium_01/02`, `grass_bermuda_01` (modelos 3D) | https://polyhaven.com/a/grass_medium_01 | CC0 (L) | Matas de césped modeladas (la bermuda tiene ~224.000 polígonos: hay que simplificar) | Tarjetas de hierba cerca de la cámara en ALTA |
| Poly Haven `sparse_grass`, `withered_grass`, `grass_path_2/3` | https://polyhaven.com | CC0 (L) | Césped gastado, zonas de tierra | Desgaste en áreas y en la línea del portero |
| GodotGrass (2Retr0) | https://github.com/2Retr0/GodotGrass | MIT, © 2024 Ethan Truong (L) | Hierba por instancias de GPU inspirada en *Ghost of Tsushima*, viento, aglomeración | Técnica de referencia; caro en móvil (sombras de hierba «a un coste de rendimiento muy alto», según su autor). Solo ALTA |
| Proton Scatter | https://github.com/HungryProton/scatter | MIT, © 2020 HungryProton (L) | Dispersión procedural de instancias | Útil para el entorno del estadio, no para el campo |
| Spatial Gardener | https://github.com/dreadpon/godot_spatial_gardener | MIT; requiere Godot 4.2+ (L) | Pintado de vegetación | Entorno del club |
| Terrain3D | https://github.com/TokisanGames/Terrain3D | MIT (L) | Terreno con instancias de follaje y 10 LOD | Excesivo para un campo plano; útil solo si vuelve la ciudad |

**Recomendación.** El campo de fútbol es plano y lo ve una cámara alta: lo que más rinde es un **sombreador** con textura CC0, franjas de corte, un mapa de desgaste que se escribe durante el partido y, solo en ALTA, una franja de tarjetas de hierba cerca de la cámara. No hace falta un complemento.

### 11.5.8 Cielo, hora y clima

**Qué falta.** Tarea 42 (13:00, 17:00 dorado, 21:00 noche con focos; lluvia, niebla, nieve).

| Recurso | URL | Licencia (nivel) | Qué aporta | Encaje |
|---|---|---|---|---|
| Poly Haven HDRI de día: `kloppenheim_05`, `qwantani_noon`, `kloofendal_48d_partly_cloudy`, `noon_grass` | https://polyhaven.com | CC0 (L) | Cielos de mediodía, despejado y nublado | Fondo del cielo (por encima de las tribunas) y luz ambiente |
| Atardecer: `qwantani_dusk_2`, `qwantani_sunset`, `kloppenheim_01` | https://polyhaven.com | CC0 (L) | Luz dorada | Preajuste de las 17:00 |
| Noche: `kloppenheim_07`, `moonlit_golf`, `qwantani_night` (vía láctea) | https://polyhaven.com/a/kloppenheim_07 | CC0 (L) | Cielos nocturnos con luna y estrellas | Preajuste de las 21:00 (los focos los pone el estadio) |
| Nublado y tormenta: `kloofendal_overcast`, `approaching_storm`, `kloofendal_misty_morning` | https://polyhaven.com | CC0 (L) | Lluvia y niebla | Combinar con partículas de lluvia y niebla volumétrica del motor |
| Sky3D | https://github.com/TokisanGames/Sky3D | MIT; Godot 4.3+; renderizadores Forward+, Mobile y Compatibility (L) | Ciclo día-noche, sol, luna con fases, estrellas, niebla y nubes dinámicas | Útil si el partido tiene que pasar de tarde a noche en vivo; el mapa estelar exige crédito a su autor |

**Recomendación.** Tres HDRI CC0 (día, atardecer, noche) a 2K para el cielo y la luz ambiente cubren la tarea 42 con coste casi nulo en móvil; Sky3D es opcional. La lluvia y la nieve son partículas del propio Godot.

### 11.5.9 Sonido de grada, balón y árbitro

**Qué falta.** Tareas 46 (grada por capas y reacciones), 47 (cánticos por club), 48 (balón por superficie y potencia, red, poste) y la sustitución de los WAV 🟡 de League-Soccer.

**Grabaciones verificadas una a una.**

| Grabación | URL | Licencia (nivel) | Duración / formato | Uso en el juego |
|---|---|---|---|---|
| «Crowd yelling huuuuu (60k persons) during a soccer game in Brazil», felix.blume (Mineirão, Atlético-Juventude, 20-11-2021; biaural, 96 kHz/24 bit) | https://freesound.org/people/felix.blume/sounds/612131/ | **CC0** (L) | 0:54 | Capa de reacción «uy» y murmullo de estadio grande |
| «Crowd screaming GOAL during the soccer game Mexico-Holland (Fifa world cup 2014)», felix.blume (plaza central de Ciudad de México) | https://freesound.org/people/felix.blume/sounds/241630/ | **CC0** (L) | 1:01, 96 kHz/24 bit | Capa de gol (multitud enorme, exterior) |
| «Norwegian football match / soccer game ambience XY to ORTF, AB and Binaural», Vogyik (estadio Viking, Stavanger, 2013; fuente XY de habbis92, también CC0) | https://freesound.org/people/Vogyik/sounds/868982/ | **CC0** (L) | 1:30 | Murmullo base de liga media |
| «Football-crowd-GOAL.wav», paulw2k (Brentford, 2006/07) | https://freesound.org/s/196461/ | **CC BY 4.0** (L) | — | Gol en estadio pequeño, **con crédito** |

**Fuentes de catálogo.**

| Fuente | URL | Licencia (nivel) | Obligaciones | Comentario |
|---|---|---|---|---|
| Freesound, filtro «Creative Commons 0» | https://freesound.org/search/?q=football+crowd&f=license%3A%22Creative+Commons+0%22 | Por archivo: CC0, CC BY, CC BY-NC o Sampling+ (L, preguntas frecuentes) | CC BY: crédito; **BY-NC y Sampling+ prohibidos** | 112 resultados CC0 para «football crowd»; 15 para «football kick ball»; 11 para «referee whistle» (el filtro garantiza CC0, pero la descripción de cada archivo se debe escuchar y revisar) |
| Kenney «Impact Sounds» | https://kenney.nl/assets/impact-sounds | CC0 (L) | — | Golpes genéricos para toques suaves y rebotes |
| Kenney «Voiceover Pack» | https://kenney.nl/assets/voiceover-pack | CC0 (L) | — | Voces cortas de locutor en inglés («ready», «go»…) para minijuegos |
| Sonniss «GDC Game Audio Bundle» | https://sonniss.com/gdc-bundle-license/ | Licencia propia: uso comercial en juegos, **sin atribución**; prohibido redistribuir los sonidos como sonidos y **prohibido entrenar IA** (L) | Guardar copia de la licencia | Calidad profesional; encaja en «términos tipo Mixamo». Riesgo bajo si los sonidos solo viajan dentro del `.pck` |

**Encaje.** El sistema de grada por capas (murmullo → cánticos → reacciones) se construye con 6-10 grabaciones CC0 cortadas en bucles y golpes; los cánticos «por club» se pueden generar mezclando ritmos de palmas y voces sin letra (el proyecto ya sintetiza audio por código). Las grabaciones de felix.blume son de calidad de grabación de campo profesional. En móvil: OGG Vorbis a 44,1 kHz mono para capas lejanas, estéreo solo para la capa de gol.

**Riesgo legal.** Bajo con CC0. Atención a que una grabación de estadio puede contener **cánticos con letra protegida o nombres de clubes reales**: escuchar cada clip y quedarse con murmullo, silbido, «uy» y gol sin palabras.

### 11.5.10 Comentarista y voz sintética

**Qué falta.** Tareas 49-51 (comentario por fases). El capítulo 2 ya revisó Kokoro y Piper; aquí se amplía con la lista de voces en español, la dependencia GPL escondida y seis modelos más.

| Modelo | URL | Licencia del código / de los pesos (nivel) | Español | Obligaciones y advertencias | Veredicto |
|---|---|---|---|---|---|
| **Kokoro-82M** | https://huggingface.co/hexgrad/Kokoro-82M/blob/main/VOICES.md | Apache 2.0 / Apache 2.0 (L) | **Sí**: `ef_dora` (mujer), `em_alex`, `em_santa` (hombres); portugués de Brasil `pf_dora`, `pm_alex`, `pm_santa`; italiano y francés con nota baja | La voz francesa `ff_siwis` exige atribución CC BY al conjunto SIWIS. **Para idiomas distintos del inglés, la conversión a fonemas usa espeak-ng (GPLv3)** a través de `phonemizer`/`espeakng-loader` (dependencias declaradas en `kokoro` y `kokoro-onnx`) (L) | 🟢 **solo pre-generando audios fuera del juego**; no incrustar el canal de fonemas en el build |
| kokoro-onnx (ejecución ONNX) | https://github.com/thewh1teagle/kokoro-onnx | MIT (L) | Igual que Kokoro | Depende de `phonemizer` y `espeakng-loader` | Herramienta de pre-generación |
| **Chatterbox** (Resemble AI) | https://github.com/resemble-ai/chatterbox · https://huggingface.co/ResembleAI/chatterbox | MIT / MIT (L) | **Sí**: el modelo multilingüe cubre 23 idiomas, con variantes afinadas de español latinoamericano y de España, y de portugués | Cada audio lleva la **marca de agua inaudible Perth**; el proyecto está **retirado** (archivo, sin mantenimiento) | 🟢 alternativa; la marca de agua no es una obligación legal sino técnica |
| **MeloTTS** (MyShell) | https://github.com/myshell-ai/MeloTTS · https://huggingface.co/myshell-ai/MeloTTS-Spanish | MIT / MIT (L) | **Sí** (y francés, japonés, coreano, chino, inglés) | — | 🟢 ligero; calidad a evaluar |
| Bark (Suno) | https://huggingface.co/suno/bark | MIT / MIT (L) | Multilingüe [C] | Generativo, poco controlable | 🟡 no recomendado para frases exactas |
| Parler-TTS mini multilingüe 1.1 | https://huggingface.co/parler-tts/parler-tts-mini-multilingual-v1.1 | Apache 2.0 / Apache 2.0 (L) | Multilingüe europeo [C] | — | 🟢 a evaluar |
| Dia-1.6B, Zonos-v0.1, Orpheus, CSM | https://huggingface.co/nari-labs/Dia-1.6B · https://huggingface.co/Zyphra/Zonos-v0.1-transformer | Apache 2.0 (código y, donde se comprobó, pesos) (L) | Principalmente inglés [C] | — | 🟡 para voces en inglés |
| Piper (`piper1-gpl`) | https://github.com/OHF-Voice/piper1-gpl | Motor **GPL-3.0**; el proyecto «no concede licencia» sobre las voces: cada voz vale lo que diga su `MODEL_CARD` y debe viajar con ella (L) | Hay voces en español [C] | Ver la ficha de cada voz; la cuestión de obra derivada es abierta | 🟡 **solo herramienta externa**, voz a voz |
| XTTS-v2 (Coqui) | https://huggingface.co/coqui/XTTS-v2 | Código MPL 2.0 / pesos **Coqui Public Model License**: «solo uso no comercial del modelo y de sus salidas» (L) | Sí | — | 🔴 |
| F5-TTS | https://huggingface.co/SWivid/F5-TTS | Código MIT / pesos **CC BY-NC 4.0** (L) | — | — | 🔴 |
| Mozilla Common Voice 25.0, español (conjunto de datos) | https://datacollective.mozillafoundation.org | CC0 1.0; ~2.275 h grabadas, ~593 h validadas, ~26.900 hablantes (E) | — | Son voces de personas reales; clonar a una persona concreta plantea un problema ético aunque la licencia lo permita | 🟡 solo para entrenar o afinar una voz **mezclada**, no para clonar a un individuo |

**Encaje con el juego.** Ningún modelo de estos debería correr **dentro** del partido en un teléfono: un TTS neuronal en tiempo real competiría con el presupuesto de 16 ms del fotograma. El enfoque que encaja con el proyecto es el que ya usa para la narración (`montar_narracion.py`): **generar fuera** (herramienta externa en el PC del desarrollador) un banco de frases modulares y nombres, normalizarlas y guardarlas como OGG. Así, la GPL de espeak-ng o de Piper se queda en la herramienta y el juego solo distribuye audio.

**Recomendación.** Fase 1 (informe AAA §6.6): voluntarios con cesión firmada. Fase 2: Kokoro (`em_alex`, `ef_dora`) y Chatterbox en paralelo, una prueba ciega con el dueño de 30 frases de fútbol en español, y elegir. En ambos casos, anotar en `LICENCIAS.md` el modelo, la voz y la fecha de generación de cada lote.

### 11.5.11 Música

**Qué falta.** Tarea 98 (música de menú con licencia comercial; «lo maneja el dueño», según `CLAUDE.md`). Se listan opciones para que el dueño decida.

| Fuente | URL | Licencia (nivel) | Obligaciones | Comentario |
|---|---|---|---|---|
| Kevin MacLeod (Incompetech) | https://incompetech.com/music/royalty-free/faq.html | **CC BY 4.0** (L) | Crédito; en juegos, según el autor, «lo más común» es una pantalla de créditos | Advierte de que, si el juego se va a transmitir, conviene pedirle que lo ponga en lista blanca (reclamaciones automáticas en plataformas de vídeo) |
| Kenney «Music Jingles» | https://kenney.nl/assets/music-jingles | CC0 (L, licencia general de Kenney) | — | Jingles cortos para premios y avisos |
| FreePD | https://freepd.com | La portada habla de «Public Domain music», pero el sitio está **cerrado permanentemente** y no se leyó la licencia (SV) | — | No recomendado |
| Música propia sintetizada (en uso) | `nucleo/musica.gd` | propio | — | 6 piezas |

### 11.5.12 Tipografías

**Qué falta.** Tarea 56 (dos familias, cuatro tamaños, cifras tabulares) y los dorsales nítidos (tarea 36).

El repositorio de Google Fonts organiza las familias por licencia en carpetas de primer nivel (`ofl/`, `apache/`, `ufl/`), y cada familia trae su archivo de licencia [R36] (L). Se comprobó que las siguientes están en `ofl/` con su `OFL.txt`:

| Familia | URL de la licencia | Uso propuesto |
|---|---|---|
| Big Shoulders Display | https://raw.githubusercontent.com/google/fonts/main/ofl/bigshouldersdisplay/OFL.txt | Dorsales de estilo norteamericano/industrial |
| Teko | https://raw.githubusercontent.com/google/fonts/main/ofl/teko/OFL.txt | Marcador de TV y dorsales estrechos |
| Saira Condensed | https://raw.githubusercontent.com/google/fonts/main/ofl/sairacondensed/OFL.txt | Rótulos de TV (nombre del goleador) |
| Anton | https://raw.githubusercontent.com/google/fonts/main/ofl/anton/OFL.txt | Titulares de menú |
| Oswald | https://raw.githubusercontent.com/google/fonts/main/ofl/oswald/OFL.txt | Alternativa a Barlow Condensed |
| Chakra Petch, Rajdhani, Exo 2 | `ofl/chakrapetch`, `ofl/rajdhani`, `ofl/exo2` | Estilos «tecnológicos» para dorsales de clubes modernos |
| Archivo, Titillium Web, Roboto Condensed, Noto Sans | `ofl/archivo`, `ofl/titilliumweb`, `ofl/robotocondensed`, `ofl/notosans` | Texto de interfaz; Noto para los 9 idiomas |

**Obligaciones OFL.** Incluir el texto de la licencia (el proyecto ya lo hace con `assets/fuentes/OFL_*.txt`), no vender la fuente por separado y no usar el nombre reservado en una versión modificada (si se recorta a un subconjunto de glifos, conviene renombrar el archivo o comprobar que la familia no declara nombre reservado).

**Recomendación.** Mantener Inter + Barlow Condensed en la interfaz (ya cumple «dos familias») y sumar **solo para dorsales** 3-4 familias OFL condensadas, convertidas a un atlas SDF por familia (nítido a cualquier distancia y barato en móvil). Las cifras tabulares de Inter (`tnum`) resuelven las tablas.

### 11.5.13 Iconos de interfaz

**Qué falta.** Tareas 55-57 (mosaico de tarjetas, navegación); hoy hay 16 iconos propios (`iconos_ui.gd`).

| Conjunto | URL | Licencia (nivel) | Cantidad | Obligaciones | Encaje |
|---|---|---|---|---|---|
| **Tabler Icons** | https://github.com/tabler/tabler-icons | MIT (L) | 6.545 | Aviso MIT | Trazo uniforme de 2 px, como los 16 propios; el más coherente con el estilo actual |
| **Material Symbols / Material Icons** (Google) | https://github.com/google/material-design-icons | Apache 2.0 (L) | Miles (con ejes de grosor y relleno) | `LICENSE` + aviso | Muy legible en móvil; estilo reconocible de Android |
| Lucide | https://lucide.dev/license | ISC; los derivados de Feather, MIT (© Cole Bemis) (L) | ~1.500 [C] | Dos avisos | Bueno; obliga a llevar dos textos de licencia |
| Phosphor | https://github.com/phosphor-icons/homepage | MIT (L) | Varios pesos [C] | Aviso MIT | Alternativa con 6 grosores |
| Bootstrap Icons | https://github.com/twbs/icons | MIT (L) | — | Aviso MIT | — |
| Fluent UI System Icons (Microsoft) | https://github.com/microsoft/fluentui-system-icons | MIT (L) | — | Aviso MIT | — |
| **game-icons.net** | https://game-icons.net/about.html | **CC BY 3.0** (L) | ~4.178 (suma por autores) | Crédito al autor de cada icono («Icons made by {autor}. Available on https://game-icons.net») | Iconos **de juego** (trofeos, botas, balón, silbato, tarjeta…); útil para La Ruta y premios |
| Kenney «Game Icons» | https://kenney.nl/assets/game-icons | CC0 (L) | 105 archivos | — | Mandos y botones de plataforma |
| Font Awesome Free | https://github.com/FortAwesome/Font-Awesome | Iconos SVG **CC BY 4.0**, fuentes OFL, código MIT (L) | — | Atribución (ya incrustada en los archivos) | Los **iconos de marcas** son marcas registradas: no usarlos |

**Recomendación.** Tabler (MIT) como base, porque su trazo coincide con el de los iconos propios, y game-icons.net (CC BY 3.0) para los conceptos de fútbol y premios que no estén en Tabler, con su crédito por autor en la pantalla de créditos. Convertir solo los iconos usados a SVG importados o a trazos en `iconos_ui.gd`, como ya se hace.

### 11.5.14 Datos de fútbol para validar la IA y el mundo

**Qué falta.** Tarea 21 (banco «estadística de fútbol real»: 50 partidos, 10 clubes, 5 países) y la corrección I10 del capítulo 2 (no usar StatsBomb). La hipótesis H4 del capítulo 2 decía que los datos de calidad se han cerrado; esta sección encuentra excepciones.

| Fuente | URL | Licencia (nivel) | Obligaciones | Contenido | Uso en Dinastía |
|---|---|---|---|---|---|
| **Soccer match event dataset** (Pappalardo, Cintia, Rossi, Massucco, Ferragina, Pedreschi, Giannotti; datos de Wyscout) | https://figshare.com/collections/Soccer_match_event_dataset/4415000/2 · artículo: https://pmc.ncbi.nlm.nih.gov/articles/PMC6817871 | **CC BY 4.0**: «The data sets are released under the CC BY 4.0 License» (L, en el artículo) | Citar el artículo (*Scientific Data* 6:236, 2019) y la licencia | Temporada 2017/18 de las 5 grandes ligas, Mundial 2018 y Euro 2016: **1.941 partidos, 3.251.294 eventos, 4.299 jugadores** | **Calibrar** medias por partido (pases, tiros, faltas, fueras de juego, duelos, distribución espacial de eventos) del motor C4. No incluir los datos en el build (contienen jugadores reales); solo las cifras agregadas, con la cita en la documentación |
| SkillCorner Open Data | https://github.com/SkillCorner/opendata | Repositorio bajo **MIT**, © 2020 SkillCorner (L); piden «crédito a SkillCorner» | Aviso MIT y crédito | Datos de seguimiento (posiciones) de partidos emitidos [C] | Validar **colocación** (distancia entre líneas, compacidad, anchura) contra seguimiento real. Al ser MIT, el uso comercial no está restringido, pero conviene confirmarlo con la empresa porque el repositorio no distingue entre código y datos |
| openfootball (`football.json`, `worldcup.json`) | https://github.com/openfootball/football.json | **CC0 1.0** / dominio público (L) | — | Calendarios y resultados de ligas y mundiales | Calendarios reales en el `pack_real.json` local; resultados históricos agregados (goles por partido por liga) |
| **Wikidata** | https://www.wikidata.org/wiki/Wikidata:Licensing | Datos estructurados **CC0** (L); los medios enlazados no | — | Estadios (capacidad, inauguración, coordenadas), clubes, ciudades | Capacidades y años de estadios para el modo ficticio (dato no personal). Los datos de personas, solo en `pack_real.json` |
| kloppy (herramienta) | https://github.com/PySport/kloppy | BSD-3 (L) | Aviso BSD | Carga y normaliza datos de eventos y seguimiento de varios proveedores | Herramienta externa del banco de calibración |
| Google Research Football | https://github.com/google-research/football | Apache 2.0, archivado (cap. 2 [53]) | — | Escenarios académicos | Ya cubierto en el capítulo 2 |
| StatsBomb Open Data | https://github.com/statsbomb/open-data | Prohíbe la explotación comercial y los análisis derivados (cap. 2 [50]) | — | — | 🔴 |
| Metrica Sports sample data | https://github.com/metrica-sports/sample-data | **Sin licencia**: solo pide «ser responsable» y reconocer la fuente si es público (L) | — | 3 partidos anónimos de seguimiento | 🔴 sin licencia escrita (SV) |
| football-data.co.uk | https://www.football-data.co.uk/notes.txt | Las notas no contienen términos de uso ni licencia (L) | — | Resultados y cuotas | 🔴 SV: no usar sin permiso |

**Recomendación.** El banco «estadística de fútbol real» (tarea 21) puede apoyarse legalmente en las medias calculadas sobre el conjunto de Pappalardo (CC BY 4.0) y, para la colocación, en SkillCorner (MIT). El cálculo se hace con una herramienta externa (Python + kloppy) y solo las **cifras objetivo** (unas decenas de números con su intervalo) entran al repositorio, con la cita. Ningún nombre de jugador real sale de ahí.

### 11.5.15 Herramientas de QA y perfilado

**Qué falta.** Tareas 79-81 (suelo de FPS, medir en el teléfono, `probar_nativo` en Windows y Android) y la «arena de pruebas» (orden 22).

| Herramienta | URL | Licencia (nivel) | Qué resuelve | Encaje |
|---|---|---|---|---|
| **Tracy Profiler** | https://github.com/wolfpld/tracy | BSD-3 (L) | Perfilado por zonas con nanosegundos, CPU y GPU | Godot admite `profiler=tracy profiler_path=…` en SCons (requiere **compilar el motor**) [R50][R51]; también sirve para la extensión C++ del proyecto (zonas en `mover_nativo.cpp`) |
| **Perfetto** | https://github.com/google/perfetto | Apache 2.0 (L) | Trazas de sistema en Android (CPU, planificador, frecuencia) | Opción `profiler=perfetto` de Godot (sin muestreo de pila); trazas del teléfono del dueño |
| **RenderDoc** | https://github.com/baldurk/renderdoc | MIT (L) | Captura de fotogramas: llamadas de dibujo, sombreadores, texturas | Vulkan y OpenGL ES 2.0-3.2 en **Android** (L): justo lo que falta para entender los 5 FPS con GPU al 100 % de la prueba del dueño |
| GUT | https://github.com/bitwes/Gut | MIT; versión 9.7.1 para Godot 4.7.x (L) | Pruebas unitarias en GDScript | El banco propio ya cubre esto; útil para pruebas de un solo script |
| gdUnit4 | https://github.com/MikeSchulze/gdUnit4 | MIT; la línea 6.2.x soporta Godot 4.5-4.7.1 (L) | Pruebas con informes JUnit para CI | Igual: opcional |
| Phantom Camera | https://github.com/ramokz/phantom-camera | MIT; Godot 4.4+ (L) | Cámaras con prioridad y transición suave, seguimiento de grupo, «look at» | **Director de TV** (tarea 26): cada plano es una `PhantomCamera3D` con prioridad; el director solo cambia prioridades |
| Profilador y monitores integrados de Godot | https://docs.godotengine.org | MIT | Tiempos por función, memoria, llamadas | Ya en uso (`hw_modesto.sh`) |

**Recomendación.** RenderDoc en el teléfono del dueño es la medida que más información aporta hoy (la prueba del 3-11 dice GPU al 100 %, CPU al 0 %: es un problema de GPU, y RenderDoc enseña qué pasada cuesta). Tracy, para ver la extensión C++ y GDScript en la misma línea de tiempo en la laptop.

### 11.5.16 Traducción

**Qué falta.** La orden 5 fija 9 idiomas y el flujo `sumar_traducciones.py`; los textos nuevos (La Ruta, galas, menús) generan pendientes continuamente. Un modelo local de licencia comercial permite **borradores** que luego se revisan.

| Modelo o herramienta | URL | Licencia (nivel) | Idiomas | Veredicto |
|---|---|---|---|---|
| OPUS-MT (Helsinki-NLP) `opus-mt-es-en`, `opus-mt-en-es`, `opus-mt-es-fr` | https://huggingface.co/Helsinki-NLP/opus-mt-es-en | **Apache 2.0** (L) | Pares sueltos | 🟢 ligero (Marian); un modelo por par |
| OPUS-MT `opus-mt-tc-big-en-pt` | https://huggingface.co/Helsinki-NLP/opus-mt-tc-big-en-pt | **CC BY 4.0** (L) | Inglés → portugués | 🟢 con atribución en la documentación (la salida no la arrastra en la práctica, pero se anota) |
| **MADLAD-400** (Google) `madlad400-3b-mt` | https://huggingface.co/google/madlad400-3b-mt | **Apache 2.0** (L) | 400+ (la ficha dice 419 en metadatos y «más de 450» en el resumen) | 🟢 un solo modelo para los 9 idiomas |
| M2M100 418M (Meta) | https://huggingface.co/facebook/m2m100_418M | **MIT** (L) | 100 | 🟢 |
| Modelos de lenguaje generales: Qwen2.5-7B-Instruct, Mistral-7B-Instruct-v0.3, EuroLLM-9B-Instruct | https://huggingface.co/Qwen/Qwen2.5-7B-Instruct · https://huggingface.co/mistralai/Mistral-7B-Instruct-v0.3 · https://huggingface.co/utter-project/EuroLLM-9B-Instruct | **Apache 2.0** (L; EuroLLM con acceso automático) | Multilingües | 🟢 para traducir con contexto («esto es un botón de 12 caracteres») |
| CTranslate2 (inferencia) | https://github.com/OpenNMT/CTranslate2 | MIT (L) | — | 🟢 herramienta |
| NLLB-200 | https://huggingface.co/facebook/nllb-200-distilled-600M | **CC BY-NC 4.0** (L) | 200 | 🔴 |
| SeamlessM4T v2 | https://huggingface.co/facebook/seamless-m4t-v2-large | **CC BY-NC 4.0** (L) | — | 🔴 |
| TowerInstruct-7B v0.2 | https://huggingface.co/Unbabel/TowerInstruct-7B-v0.2 | **CC BY-NC 4.0** (L) | — | 🔴 |
| Gemma 3 | https://huggingface.co/google/gemma-3-4b-it | Términos propios de Gemma, acceso con aceptación (L de la etiqueta; términos no leídos) | — | SV |
| Argos Translate | https://github.com/argosopentech/argos-translate | Código MIT o CC0 (L); licencia de los paquetes de modelos no declarada en la portada | — | SV para los modelos |
| LibreTranslate | https://github.com/LibreTranslate/LibreTranslate | AGPL-3.0 (L) | — | Solo herramienta externa (servidor local) |
| Weblate | https://github.com/WeblateOrg/weblate | GPL-3.0 (L) | — | Solo herramienta externa (plataforma de revisión) |

**Recomendación.** MADLAD-400 o un modelo general Apache 2.0, ejecutado **fuera del juego** como herramienta, para el primer borrador de las frases nuevas, siempre pasando por `sumar_traducciones.py` y por la revisión del formato `json.dumps(ensure_ascii=False, indent=1)` de `idiomas_extra.json`. Nunca NLLB (no comercial), aunque sea el más citado.

### 11.5.17 Herramientas de creación (externas)

| Herramienta | URL | Licencia (nivel) | Uso | Nota |
|---|---|---|---|---|
| Blender | https://www.blender.org | GPL (programa); la obra creada es del autor (E, manual y lista del proyecto) | Estadios, horneado de sprites del público, retarget | Ya se usa para los regalos del Drive |
| MakeHuman | https://github.com/makehumancommunity/makehuman | AGPL (código) / CC0 (activos) (L) | Cuerpos y caras sintéticas | §11.5.3 |
| Material Maker | https://github.com/RodZill4/material-maker | MIT (L) | Texturas procedurales | §11.5.4 |
| Krita | https://github.com/KDE/krita | GPL-3.0 (L) | Escudos, pancartas, texturas pintadas | El resultado es del autor |
| Audacity | https://github.com/audacity/audacity | GPL-3.0 (L) | Cortar y normalizar la grada | El resultado es del autor |
| espeak-ng | https://github.com/espeak-ng/espeak-ng | GPL-3.0 (L) | Fonemas para Kokoro | **Nunca dentro del build** |

### 11.5.18 Complementos de la Godot Asset Library: cómo filtrarlos

La Asset Library exige que la licencia publicada coincida con la del repositorio y que exista un `LICENSE`/`LICENSE.md` con el texto y el titular; pero **admite licencias GPL** entre las opciones [R52] (L). Por eso el filtro del proyecto debe ser explícito: solo MIT, BSD, Apache, zlib, ISC, Boost, CC0 o MPL-2.0 (archivo a archivo), y comprobar siempre el `LICENSE` del repositorio, no solo la etiqueta de la biblioteca. Además, todo complemento con binarios nativos (GDExtension) hay que **compilarlo para Android y Web** o aceptar que esa función no exista ahí, igual que la extensión C++ propia tiene su gemelo GDScript.

Resumen de complementos verificados en este capítulo:

| Complemento | Licencia | Godot declarado | Binarios nativos | Utilidad para Dinastía |
|---|---|---|---|---|
| Godot Motion Matching | MIT | 4.4 | Sí (GDExtension) | Media-alta (experimento) |
| LimboAI | MIT (arte CC BY 4.0) | 4.6+ / módulo 4.7 | Sí | Media (director de TV, IA) |
| Beehave | MIT | 4.x [C] | No | Media |
| Phantom Camera | MIT | 4.4+ | No | **Alta** (director de TV) |
| Sky3D | MIT | 4.3+ | No [C] | Media |
| Terrain3D | MIT | 4.x | Sí | Baja (sin ciudad) |
| Spatial Gardener | MIT | 4.2+ | No [C] | Baja |
| Proton Scatter | MIT | 4.x [C] | No [C] | Baja |
| GodotGrass | MIT | 4.x [C] | No | Media (solo ALTA) |
| Octahedral Impostors | MIT | sin confirmar para 4.x | No | Referencia |
| GUT / gdUnit4 | MIT | 4.7 | No | Baja (ya hay banco) |

---

## 11.6 Descartados y por qué

| Recurso | Motivo | Fuente |
|---|---|---|
| AMASS | Solo no comercial; prohíbe entrenar para uso comercial | [R12] |
| LAFAN1 | CC BY-NC-ND 4.0 | [R13] |
| Bandai Namco Research Motion Dataset | CC BY-NC 4.0 | [R14] |
| SFU Motion Capture Database | «cannot be used for commercial products or resale» | [R15] |
| MB-Lab | Modelos generados bajo AGPL 3 | [R17] |
| XTTS-v2 | CPML: solo no comercial, incluidas las salidas | [R31] |
| F5-TTS (pesos) | CC BY-NC 4.0 | [R32] |
| NLLB-200, SeamlessM4T v2, TowerInstruct | CC BY-NC 4.0 | [R57]-[R59] |
| StatsBomb Open Data | Prohíbe la explotación comercial (cap. 2) | cap. 2 [50] |
| Metrica sample data | Sin licencia escrita | [R63] |
| football-data.co.uk | Sin términos de uso publicados | [R64] |
| Freesound BY-NC y Sampling+ | No comerciales | [R5] |
| Sketchfab NC, ND, Editorial | No comercial / sin derivadas / solo uso editorial | [R6][R7] |
| FreePD | Sitio cerrado, licencia no leída | [R38] |
| espeak-ng, Piper, LibreTranslate, Weblate **dentro del build** | GPL/AGPL | §11.5.10, §11.5.16 |
| Fuente «Daydream», «Pixeled», rótulo «World Cup» (de soccer5v5) | Solo uso personal / sin licencia / marca | `LICENCIAS.md` |

---

## 11.7 Paquete recomendado (top 25)

Orden por **impacto sobre las brechas del informe AAA** (el partido y su presentación primero, H1-H2 de la hoja de ruta) y por **riesgo legal bajo**. Esfuerzo en días de trabajo de una sesión [E], incluyendo conversión, integración, prueba en el banco y anotación en `LICENCIAS.md`.

| # | Recurso | URL | Licencia | Hueco que cierra (tarea AAA) | Obligación | Esfuerzo [E] |
|---|---|---|---|---|---|---|
| 1 | Nodos IK de Godot 4.6+ (`TwoBoneIK3D`, `LookAtModifier3D`, `LimitAngularVelocityModifier3D`) | https://godotengine.org/article/inverse-kinematics-returns-to-godot-4-6/ | MIT (motor) | IK pie-balón, cabeza al balón, suavizado (12, 13, 16) | Ninguna nueva | 5-8 d |
| 2 | Grabaciones CC0 de estadio: felix.blume 612131 y 241630, Vogyik 868982 | https://freesound.org/people/felix.blume/sounds/612131/ | CC0 | Grada por capas y reacciones (46) | Ninguna | 2-3 d |
| 3 | Soccer match event dataset (Pappalardo y otros, Wyscout) | https://figshare.com/collections/Soccer_match_event_dataset/4415000/2 | CC BY 4.0 | Banco «estadística de fútbol real» (21) | Citar el artículo | 3-5 d |
| 4 | Phantom Camera | https://github.com/ramokz/phantom-camera | MIT | Director de TV por estados (26, 30, 31) | Aviso MIT | 5-10 d |
| 5 | Kokoro-82M con pre-generación externa (voces `em_alex`, `ef_dora`) | https://huggingface.co/hexgrad/Kokoro-82M | Apache 2.0 (espeak-ng solo en la herramienta) | Comentario de nombres y frases (49-50) | Aviso Apache; no distribuir espeak-ng | 4-6 d |
| 6 | HDRI CC0 de Poly Haven: `stadium_01`, `orlando_stadium`, `qwantani_dusk_2`, `kloppenheim_07` | https://polyhaven.com/a/stadium_01 | CC0 | Preajustes de hora y luz (42) | Ninguna | 2-3 d |
| 7 | Telas CC0: Poly Haven `cotton_jersey`, `jersey_melange`, `waffle_pique_cotton`; ambientCG `Fabric*` | https://polyhaven.com/a/cotton_jersey | CC0 | Tela con malla (36) | Ninguna | 2-4 d |
| 8 | Tipografías OFL para dorsales (Big Shoulders Display, Teko, Saira Condensed) | https://github.com/google/fonts | OFL 1.1 | Dorsal y nombre nítidos (36), paquete gráfico (29) | Incluir OFL | 2-3 d |
| 9 | RenderDoc en Android | https://github.com/baldurk/renderdoc | MIT | Medir en el teléfono (80) | — (herramienta) | 1-2 d |
| 10 | Tabler Icons | https://github.com/tabler/tabler-icons | MIT | Iconos de menú y mosaico (55, 57) | Aviso MIT | 2-3 d |
| 11 | CMU: atrapes (33/34), saltos y caídas para portero compuesto | http://mocap.cs.cmu.edu | Uso comercial libre; agradecimiento | Portero (15), caídas (18) | Agradecimiento (ya está) | 5-8 d |
| 12 | Quaternius «Background Posed Humans» | https://quaternius.com/packs/backgroundposedhumans.html | CC0 | Sprites del público horneados (40), público 3D en el plano (27) | Ninguna | 3-5 d |
| 13 | ambientCG `Grass*` + Poly Haven `sparse_grass`/`withered_grass` | https://ambientcg.com/view?id=Grass004 | CC0 | Césped con desgaste (43) | Ninguna | 3-4 d |
| 14 | Freesound CC0 de golpe de balón y silbato (filtro CC0; elegir 6-10 tras escuchar) + Kenney Impact Sounds | https://freesound.org/search/?q=football+kick+ball&f=license%3A%22Creative+Commons+0%22 | CC0 | Balón, red, poste, árbitro (48); sustituir los WAV 🟡 de League | Ninguna | 2-3 d |
| 15 | Tracy (opción `profiler=tracy` de Godot) | https://github.com/wolfpld/tracy | BSD-3 | Suelo de FPS con causa (79), extensión C++ (81) | Aviso BSD si se distribuye un build perfilado | 2-3 d |
| 16 | game-icons.net (solo conceptos de fútbol y premios) | https://game-icons.net | CC BY 3.0 | Iconos de La Ruta y galas (60, 72) | Crédito por autor | 1-2 d |
| 17 | ambientCG `Net001A`-`Net004B` | https://ambientcg.com/view?id=Net004A | CC0 | Red de la portería y mallas | Ninguna | 0,5 d |
| 18 | Chatterbox multilingüe (alternativa de voz en español) | https://github.com/resemble-ai/chatterbox | MIT | Comentario (49-50), prueba ciega frente a Kokoro | Aviso MIT; marca de agua Perth | 2-3 d |
| 19 | MakeHuman (activos CC0) como herramienta externa | https://github.com/makehumancommunity/makehuman | Activos CC0 (código AGPL, no se distribuye) | Tipos de cuerpo (38), caras sintéticas (39) | Ninguna sobre lo exportado | 5-10 d |
| 20 | SkillCorner Open Data | https://github.com/SkillCorner/opendata | MIT (crédito pedido) | Validar colocación y compacidad (22, 25) | Aviso MIT y crédito | 3-4 d |
| 21 | openfootball + Wikidata (cifras no personales) | https://github.com/openfootball/football.json | CC0 | Calendarios, capacidades de estadio, medias por liga (73) | Ninguna | 2-4 d |
| 22 | MADLAD-400 3B como borrador de traducción | https://huggingface.co/google/madlad400-3b-mt | Apache 2.0 | Textos nuevos en 9 idiomas (orden 5) | Aviso Apache (herramienta) | 1-2 d |
| 23 | LimboAI (máquina de estados jerárquica) | https://github.com/limbonaut/limboai | MIT | Estados del director de TV y del árbitro (26, 94) | Aviso MIT; compilar para Android | 3-5 d |
| 24 | Godot Motion Matching (experimento en la arena) | https://github.com/GuilhermeGSousa/godot-motion-matching | MIT | Locomoción por búsqueda de poses (11) | Aviso MIT | 8-15 d |
| 25 | Sky3D | https://github.com/TokisanGames/Sky3D | MIT | Transición tarde-noche en vivo (42) | Aviso MIT; crédito del mapa estelar | 2-3 d |

**Fuera del top, pendientes de una decisión del dueño:** Mixamo convertido a `.res` sin FBX en el repositorio (portero, cabezazo); Sonniss GDC Bundle (calidad profesional, licencia propia sin atribución); Kevin MacLeod CC BY 4.0 (música, que maneja el dueño); MetaHuman (EULA por leer).

**Resultado esperado del paquete.** Si se completan los 25, las filas «Presentación TV», «Audio/comentario», «Animación» y «Estadios/público» de la matriz del informe AAA (§3) suben por **contenido** sin gastar dinero, y el registro de licencias pierde sus tres amarillos de sonido y modelos al sustituirlos por piezas CC0 verificadas.

---

## 11.8 Plantilla de anotación para `LICENCIAS.md`

Cada recurso nuevo se anota **antes** de que entre a un build, en la sección que le corresponda de `LICENCIAS.md`, con esta fila:

```
| Qué | Dónde (ruta en el repo) | Origen (autor, título, URL exacta) | Licencia (nombre + URL del texto) | Obligación cumplida | Fecha de consulta | Prueba guardada | Estado |
```

Ejemplos rellenados (para cuando se integren; hoy no están en el repo):

```
| Grada: «Crowd yelling huuuuu (60k persons)…» (bucle de 20 s) | audio/grada/murmullo_grande.ogg | felix.blume, https://freesound.org/people/felix.blume/sounds/612131/ | CC0 1.0, https://creativecommons.org/publicdomain/zero/1.0/ | — (crédito de cortesía en creditos.gd) | 16-11-2026 | captura JPG de la ficha en Drive/referencias | 🟢 |
| Medias de fútbol real para el banco (tabla de cifras) | datos/objetivos_futbol_real.json | Pappalardo et al. (2019), Scientific Data 6:236, https://figshare.com/collections/Soccer_match_event_dataset/4415000/2 | CC BY 4.0, https://creativecommons.org/licenses/by/4.0/ | Cita en el JSON y en creditos.gd | 16-11-2026 | PDF del artículo (PMC6817871) | 🟢 |
| Voz «em_alex», 400 frases pregeneradas | audio/comentario/es/ | Kokoro-82M, hexgrad, https://huggingface.co/hexgrad/Kokoro-82M | Apache 2.0 (modelo); espeak-ng GPL-3 solo en la herramienta | NOTICE en creditos.gd; espeak-ng NO viaja | 16-11-2026 | VOICES.md y LICENSE guardados | 🟢 |
```

**Lista de control antes de integrar** (se puede convertir en una sección del banco que lea `LICENCIAS.md`):

1. ¿La licencia se leyó en la fuente primaria (nivel L)? Si es E o SV, no entra.
2. ¿Es CC0/MIT/BSD/Apache/ISC/zlib/OFL/CC BY/CC BY-SA, o términos propietarios con OK del dueño y copia fechada?
3. ¿Hay obligación de atribución? → línea en `nucleo/creditos.gd` con autor, título, licencia y enlace; para Apache, el `NOTICE`.
4. ¿Hay *share-alike*? → mantener el recurso como archivo separado y anotar que sus adaptaciones se comparten con la misma licencia.
5. ¿Contiene una persona real, una marca, un escudo, un cántico con letra o un nombre de club real? → fuera del build público.
6. ¿Hay cláusula contra el entrenamiento de IA o contra la redistribución suelta? → anotarla en la fila.
7. ¿Es código nativo? → compilado para Windows, Linux, Android y Web, o con gemelo GDScript.
8. ¿Pesa? → nada nuevo en LFS (regla fija); la biblioteca completa a `terceros/` con `.gdignore` y solo lo usado al build, como con las animaciones.
9. ¿Se guardó la prueba (captura JPG de la ficha o archivo de licencia) en el Drive del dueño, `referencias_del_dueño` (orden 41)?

---

## 11.9 Limitaciones y riesgos

1. **No es asesoría jurídica.** Las descripciones son las que dan las fuentes el 16-11-2026. Antes de vender, una revisión profesional del registro.
2. **Licencias que cambian.** Términos propietarios (Mixamo, Sonniss, MetaHuman, Rokoko) y licencias de modelos pueden cambiar; por eso la plantilla pide fecha y copia guardada. La licencia CC es irrevocable para la copia obtenida, pero conviene poder demostrar cuándo y dónde se obtuvo.
3. **Pesos y datos de entrenamiento.** Que un modelo de voz o de traducción sea Apache o MIT no garantiza la limpieza de sus datos; la cuestión de si un modelo es obra derivada de su corpus está abierta (Piper lo dice expresamente [R33]).
4. **Verificación parcial.** Una docena de recursos está en nivel E (MetaHuman, Rokoko, Blender sobre la obra producida, Common Voice, Bark en español…) y varias páginas fueron inaccesibles (§11.2.3). Las cantidades marcadas [C] (por ejemplo, número de iconos de Lucide o el catálogo deportivo de Mixamo) no se comprobaron hoy.
5. **Compatibilidad con Godot 4.7.2 no probada.** Varios complementos declaran 4.2-4.6; los de binario nativo deben recompilarse. Nada de este capítulo se probó en el banco.
6. **Calidad no evaluada a fondo.** Las grabaciones recomendadas se eligieron por su ficha, no tras una escucha completa; las voces sintéticas, por su licencia y su lista de idiomas, no por una prueba ciega. Ambas pruebas son tareas del paquete.
7. **Freesound a escala.** El filtro CC0 garantiza la licencia declarada por quien sube, no que la grabación esté libre de terceros (un cántico con letra, una megafonía con un patrocinador). Escuchar antes de integrar.
8. **Datos de fútbol y personas.** Los conjuntos de Wyscout y SkillCorner contienen jugadores reales; solo se usan cifras agregadas, nunca fichas.
9. **Sesgo de selección.** El catálogo prioriza lo que encaja con Godot y con el móvil; puede haber recursos de calidad para otros motores (por ejemplo, paquetes gratuitos de tiendas de Unity o Unreal) que se omitieron porque sus EULA suelen limitar el uso a ese motor.

---

## 11.10 Conclusiones

1. **Lo que más falta en la presentación sí existe gratis y limpio**: grada (CC0 real de estadios de fútbol), luz y cielo (HDRI CC0 de estadios), tela (punto de camiseta CC0), dorsales (OFL), iconos (MIT/Apache), cámara de TV (Phantom Camera, MIT) y perfilado (Tracy, Perfetto, RenderDoc). Juntos cubren buena parte del hito H2 «Se ve como TV» con riesgo legal bajo.
2. **La animación de fútbol sigue siendo el hueco duro.** No apareció ninguna base de mocap de fútbol o de portero con licencia comercial y descarga libre, además de CMU (ya en uso). La salida es técnica, no de contenido: IK nativo de Godot 4.6, composición procedural y, con OK del dueño, Mixamo integrado sin redistribuir sus archivos.
3. **Hay datos de fútbol comercialmente utilizables.** El conjunto de Pappalardo y otros (Wyscout, CC BY 4.0) y SkillCorner (MIT) permiten construir el banco «estadística de fútbol real» de forma legal, matizando la hipótesis H4 del capítulo 2.
4. **El comentarista es posible sin presupuesto, con una condición técnica.** Kokoro y Chatterbox tienen voces en español bajo licencias permisivas, pero el canal de fonemas de Kokoro arrastra GPL: los audios se generan fuera y el juego solo distribuye OGG.
5. **El registro de licencias necesita pasar a ser una prueba.** Con la plantilla de §11.8 y la lista de control, cada recurso nuevo entra con fuente, licencia, obligación, fecha y prueba guardada; los amarillos actuales (mocap de Rohr, golpes de balón de League, modelos de Sketchfab, música del retro) tienen ya sustitutos CC0 identificados.

---

## Bibliografía

Todas las fuentes se consultaron el **16-11-2026**. Nivel: L = leída en la fuente primaria; E = extracto o fuente secundaria. Las fuentes ya citadas en el capítulo 2 se remiten a su número allí ([cap. 2, n]) y no se repiten.

**Repositorios de recursos 3D, texturas e iluminación**

[R1] Poly Haven. «License». https://polyhaven.com/license — L.
[R2] Poly Haven. *Public API* y «Poly Haven API Terms of Service». https://github.com/Poly-Haven/Public-API (ToS.md) — L. (La API es gratuita para cualquier uso, incluido el comercial; pide un «Referer» o user-agent propio de la aplicación y, solo para la API en vivo, un crédito ligero.)
[R3] Poly Haven. Fichas de recursos: `stadium_01`, `orlando_stadium`, `stadium_exterior`, `suburban_football_field`, `suburban_soccer_park`, `kloppenheim_07`, `moonlit_golf`, `qwantani_night`, `cotton_jersey`, `jersey_melange`, `waffle_pique_cotton`, `grass_medium_01`, `grass_bermuda_01`, `football`, `dirty_football`. https://polyhaven.com/a/<nombre> y https://api.polyhaven.com/info/<nombre> — L.
[R4] ambientCG. «License». https://docs.ambientcg.com/license/ ; API `https://ambientcg.com/api/v2/full_json` (búsquedas «grass», «fabric», «net», «concrete») — L.
[R5] Freesound. «Frequently Asked Questions» (licencias). https://freesound.org/help/faq/ — L.
[R6] Sketchfab. «Licenses» (Standard y Editorial). https://sketchfab.com/licenses — L.
[R7] Sketchfab Help Center. Licencias Creative Commons para descargas. https://help.sketchfab.com/en/articles/16152217 — L.
[R8] Kenney. «Support» (licencia de los recursos). https://kenney.nl/support — L.
[R9] Kenney. «Game Icons», «Impact Sounds», «Voiceover Pack», «Music Jingles», «Sports Pack». https://kenney.nl/assets/game-icons (y análogas) — L.
[R10] Quaternius. «Background Posed Humans» y listado de packs. https://quaternius.com/packs/backgroundposedhumans.html — L.
[R11] OpenGameArt. «FAQ». https://opengameart.org/content/faq — no accesible (403).

**Captura de movimiento y animación**

[R12] Max Planck Institute for Intelligent Systems. «AMASS — License». https://amass.is.tue.mpg.de/license.html — L.
[R13] Ubisoft La Forge. *ubisoft-laforge-animation-dataset* (LAFAN1). https://github.com/ubisoft/ubisoft-laforge-animation-dataset — L.
[R14] Bandai Namco Research. *Bandai-Namco-Research-Motiondataset*. https://github.com/BandaiNamcoResearchInc/Bandai-Namco-Research-Motiondataset — L.
[R15] Simon Fraser University y National University of Singapore. «SFU Motion Capture Database». https://mocap.cs.sfu.ca/ — L.
[R16] Carnegie Mellon University Graphics Lab. «CMU Graphics Lab Motion Capture Database». http://mocap.cs.cmu.edu — FAQ inaccesible (503); licencia verificada en `LICENCIAS.md` por el `READMEFIRST.txt` de la conversión BVH.
[R17] MB-Lab. Repositorio y `license.txt`. https://github.com/animate1978/MB-Lab ; https://raw.githubusercontent.com/animate1978/MB-Lab/master/license.txt — L.
[R18] Thacker, J. (2025). «You can now sell MetaHumans, or use them in Unity or Godot». CG Channel, 4-6-2025. https://www.cgchannel.com/2025/06/you-can-now-sell-metahumans-or-use-them-in-unity-or-godot/ — E (fuente secundaria; el EULA oficial requiere sesión).
[R19] Rokoko Motion Library: CG Channel (2020), «Get 150 free mocap moves from Rokoko’s Motion Library», https://www.cgchannel.com/2020/03/get-150-free-mocap-moves-from-rokokos-motion-library ; Rokoko, «Pricing», https://rokoko.com/pricing/ — E.
[R20] Truebones. Tienda en Gumroad. https://truebones.gumroad.com — E.
[R21] Godot Engine. «Inverse kinematics returns to Godot 4.6». https://godotengine.org/article/inverse-kinematics-returns-to-godot-4-6/ ; referencia de clase `IKModifier3D` y `FABRIK3D`, https://docs.godotengine.org/en/4.6/classes/class_ikmodifier3d.html — L.
[R22] Sousa, G. *Godot Motion Matching* (licencia MIT, © 2024). https://github.com/GuilhermeGSousa/godot-motion-matching — L.
[R23] Holden, D. *Motion-Matching* (MIT). Ver [cap. 2, 41].
[R24] limbonaut. *LimboAI*. https://github.com/limbonaut/limboai — L.
[R25] bitbrain. *Beehave* (MIT, © 2023). https://github.com/bitbrain/beehave — L.
[R26] MakeHuman Community. `LICENSE.md`. https://github.com/makehumancommunity/makehuman/blob/master/LICENSE.md — L.

**Sonido, voz y música**

[R27] Sonniss. «GDC Game Audio Bundle License». https://sonniss.com/gdc-bundle-license/ — L.
[R28] felix.blume. «Crowd yelling huuuuu (60k persons) during a soccer game in Brazil» (612131) y «Crowd screaming GOAL during the soccer game Mexico-Holland (Fifa world cup 2014)» (241630). Freesound. https://freesound.org/people/felix.blume/sounds/612131/ ; https://freesound.org/people/felix.blume/sounds/241630/ — L.
[R29] Vogyik. «Norwegian football match / soccer game ambience XY to ORTF, AB and Binaural» (868982). https://freesound.org/people/Vogyik/sounds/868982/ — L. paulw2k, «Football-crowd-GOAL.wav» (196461), https://freesound.org/s/196461/ — L.
[R30] hexgrad. *Kokoro-82M*, `VOICES.md`. https://huggingface.co/hexgrad/Kokoro-82M/blob/main/VOICES.md ; `kokoro` (Apache 2.0), https://github.com/hexgrad/kokoro ; `misaki` (respaldo con espeak), https://github.com/hexgrad/misaki ; `kokoro-onnx` (MIT; dependencias `phonemizer`, `espeakng-loader`), https://github.com/thewh1teagle/kokoro-onnx — L. Ver también [cap. 2, 66].
[R31] Coqui. *XTTS-v2* y «Coqui Public Model License 1.0.0». https://huggingface.co/coqui/XTTS-v2 — L.
[R32] SWivid. *F5-TTS* (código MIT; pesos CC BY-NC 4.0). https://github.com/SWivid/F5-TTS ; https://huggingface.co/SWivid/F5-TTS — L.
[R33] Open Home Foundation. *piper1-gpl*, `docs/LICENSING.md` y `docs/COMMERCIAL_USE.md`. https://github.com/OHF-Voice/piper1-gpl — L. Ver también [cap. 2, 67].
[R34] Resemble AI. *Chatterbox* (MIT). https://github.com/resemble-ai/chatterbox ; https://huggingface.co/ResembleAI/chatterbox — L.
[R35] MyShell. *MeloTTS* (MIT) y *MeloTTS-Spanish*. https://github.com/myshell-ai/MeloTTS ; https://huggingface.co/myshell-ai/MeloTTS-Spanish — L.
[R36] Google. *google/fonts* (README: licencias por carpeta) y archivos `ofl/<familia>/OFL.txt`. https://github.com/google/fonts — L.
[R37] MacLeod, K. «Royalty Free Music FAQ». Incompetech. https://incompetech.com/music/royalty-free/faq.html — L.
[R38] FreePD. https://freepd.com — L (aviso de cierre; sin licencia legible).
[R39] Mozilla Foundation. *Common Voice Scripted Speech 25.0 — Spanish* (Data Collective). https://datacollective.mozillafoundation.org/datasets/cmn4z1n52000knv07h01532dd — E.
[R40] Blender. «About Free Software and the GPL» (manual). https://docs.blender.org/manual/en/4.2/getting_started/about/license.html — E.
[R41] Blender Foundation. «Blender FAQ for Artists and the GPL», lista bf-committers, 2004. https://lists.blender.org/pipermail/bf-committers/2004-November/008253.html — E.
[R42] Suno. *Bark* (MIT). https://huggingface.co/suno/bark ; Hugging Face, *parler-tts-mini-multilingual-v1.1* (Apache 2.0), https://huggingface.co/parler-tts/parler-tts-mini-multilingual-v1.1 ; Nari Labs, *Dia-1.6B*; Zyphra, *Zonos-v0.1*; Canopy Labs, *Orpheus-TTS*; Sesame, *CSM* (Apache 2.0, archivo `LICENSE` de cada repositorio) — L.

**Iconos**

[R43] Google. *material-design-icons* (Apache 2.0). https://github.com/google/material-design-icons — L. Tabler, *tabler-icons* (MIT, 6.545 iconos), https://github.com/tabler/tabler-icons — L. Lucide, «License», https://lucide.dev/license — L. Phosphor Icons (MIT), https://github.com/phosphor-icons/homepage — L. Bootstrap Icons (MIT), https://github.com/twbs/icons — L. Microsoft, *fluentui-system-icons* (MIT), https://github.com/microsoft/fluentui-system-icons — L. Font Awesome, `LICENSE.txt`, https://github.com/FortAwesome/Font-Awesome — L. game-icons.net, «About», https://game-icons.net/about.html — L.

**Godot: documentación y complementos**

[R44] Godot Docs. «Mesh level of detail (LOD)». https://docs.godotengine.org/en/stable/tutorials/3d/mesh_lod.html — L (página accesible).
[R45] Godot Docs. «Visibility ranges (HLOD)». https://docs.godotengine.org/en/stable/tutorials/3d/visibility_ranges.html — L.
[R46] Godot Docs. «Optimization using MultiMeshes». https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html — L.
[R47] TokisanGames. *Terrain3D* (MIT) y *Sky3D* (MIT, Godot 4.3+). https://github.com/TokisanGames/Terrain3D ; https://github.com/TokisanGames/Sky3D — L.
[R48] dreadpon. *Spatial Gardener* (MIT). https://github.com/dreadpon/godot_spatial_gardener ; HungryProton, *Scatter* (MIT), https://github.com/HungryProton/scatter ; 2Retr0, *GodotGrass* (MIT), https://github.com/2Retr0/GodotGrass — L.
[R49] wojtekpil y K. S. E. Lee. *Godot-Octahedral-Impostors* (MIT). https://github.com/wojtekpil/Godot-Octahedral-Impostors — L.
[R50] Godot Docs. «Tracy» (perfiladores de trazas). https://docs.godotengine.org/en/stable/engine_details/development/profiling/tracy.html — L (página accesible).
[R51] Godot Engine. PR #104851, «Add `profiler` option to SCons builds, with support for `tracy` and `perfetto`» (vía réplica del repositorio). https://remotebranch.eu/Stowage/godot/commit/e80194e31f6944d09afd04fd7298fb09a3bc2b52 — E.
[R52] Godot Docs. «Submitting to the Asset Library». https://docs.godotengine.org/en/stable/community/asset_library/submitting_to_assetlib.html — L.
[R53] ramokz. *Phantom Camera* (MIT). https://github.com/ramokz/phantom-camera — L.

**QA, perfilado y herramientas**

[R54] wolfpld. *Tracy Profiler* (BSD-3). https://github.com/wolfpld/tracy — L. Google, *Perfetto* (Apache 2.0), https://github.com/google/perfetto — L.
[R55] Karlsson, B. *RenderDoc* (MIT). https://github.com/baldurk/renderdoc — L.
[R56] bitwes, *Gut* (MIT), https://github.com/bitwes/Gut ; Schulze, M., *gdUnit4* (MIT), https://github.com/MikeSchulze/gdUnit4 ; Suescun, R., *Material Maker* (MIT), https://github.com/RodZill4/material-maker ; KDE, *Krita* (GPL-3), https://github.com/KDE/krita ; Audacity (GPL-3), https://github.com/audacity/audacity ; *espeak-ng* (GPL-3), https://github.com/espeak-ng/espeak-ng — L.

**Traducción**

[R57] Meta. *nllb-200-distilled-600M* (CC BY-NC 4.0). https://huggingface.co/facebook/nllb-200-distilled-600M — L.
[R58] Meta. *seamless-m4t-v2-large* (CC BY-NC 4.0). https://huggingface.co/facebook/seamless-m4t-v2-large — L.
[R59] Unbabel. *TowerInstruct-7B-v0.2* (CC BY-NC 4.0). https://huggingface.co/Unbabel/TowerInstruct-7B-v0.2 — L.
[R60] Helsinki-NLP. *opus-mt-es-en*, *opus-mt-en-es*, *opus-mt-es-fr* (Apache 2.0), *opus-mt-tc-big-en-pt* (CC BY 4.0). https://huggingface.co/Helsinki-NLP — L. Google, *madlad400-3b-mt* (Apache 2.0), https://huggingface.co/google/madlad400-3b-mt — L. Meta, *m2m100_418M* (MIT), https://huggingface.co/facebook/m2m100_418M — L. Qwen2.5-7B-Instruct, Mistral-7B-Instruct-v0.3, EuroLLM-9B-Instruct (Apache 2.0), fichas en Hugging Face — L. Google, *gemma-3-4b-it* (términos Gemma) — L (etiqueta).
[R61] Argos Translate (MIT o CC0). https://github.com/argosopentech/argos-translate ; LibreTranslate (AGPL-3), https://github.com/LibreTranslate/LibreTranslate ; Weblate (GPL-3), https://github.com/WeblateOrg/weblate ; OpenNMT, *CTranslate2* (MIT), https://github.com/OpenNMT/CTranslate2 — L.

**Datos de fútbol**

[R62] Pappalardo, L.; Cintia, P.; Rossi, A.; Massucco, E.; Ferragina, P.; Pedreschi, D.; Giannotti, F. (2019). «A public data set of spatio-temporal match events in soccer competitions». *Scientific Data* 6:236. https://pmc.ncbi.nlm.nih.gov/articles/PMC6817871 ; colección en figshare: https://figshare.com/collections/Soccer_match_event_dataset/4415000/2 — L (licencia en el artículo).
[R63] Metrica Sports. *sample-data*. https://github.com/metrica-sports/sample-data — L (sin licencia).
[R64] Football-Data.co.uk. «Notes». https://www.football-data.co.uk/notes.txt — L (sin términos).
[R65] SkillCorner. *opendata* (MIT, © 2020). https://github.com/SkillCorner/opendata — L.
[R66] openfootball. *football.json* y *worldcup.json* (CC0 1.0). https://github.com/openfootball/football.json — L.
[R67] Wikidata. «Wikidata:Licensing». https://www.wikidata.org/wiki/Wikidata:Licensing — L.
[R68] PySport. *kloppy* (BSD-3). https://github.com/PySport/kloppy — L.

**Otras**

[R69] Blender Studio. «Terms and Conditions» (contenido digital bajo CC BY 4.0 salvo aviso). https://studio.blender.org/terms-and-conditions — L.

Fuentes internas: `dinastia-godot/LICENCIAS.md` · `docs/04_auditorias/animaciones_gratuitas_2026-11-11.md` · `docs/04_auditorias/INFORME_AAA_2026-11-16.md` · `docs/04_auditorias/INFORME_ACADEMICO_AAA/cap_02_estado_del_arte.md` · `CLAUDE.md` (órdenes 5, 13, 15, 16, 22, 41, 57) · `dinastia-godot/herramientas/bajar_cc0.py`.
