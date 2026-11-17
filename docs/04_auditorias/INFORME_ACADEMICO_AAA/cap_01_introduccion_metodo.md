# Capítulo 1. Introducción, preguntas de investigación y método

Informe académico AAA de Dinastía · Redacción: 16-11-2026.
Convenciones (detalladas en §1.6): [M] medido · [D] documento del proyecto · [F n] fuente externa del capítulo 2 · [R n] fuente externa del capítulo 11 · [E] estimación. La bibliografía unificada está en el capítulo 10.

---

## Resumen

Este capítulo fija el problema, las cinco preguntas de investigación (RQ1-RQ5), las definiciones operativas, el método y las limitaciones del informe. Dinastía es un juego de fútbol desarrollado en Godot 4.7.2 por un único dueño con sesiones de trabajo asistidas; combina gestión de club, un partido jugable en 3D y un modo de carrera de jugador («La Ruta»). Al 16-11-2026 el proyecto suma 2.354 scripts propios de GDScript con 338.521 líneas y una extensión nativa de 3.052 líneas de C++ [M, cap. 3], y genera un mundo de 2.206 clubes en 147 ligas de 135 países [M, cap. 3]. El encargo del dueño es determinar qué le falta para alcanzar un nivel de calidad percibida comparable al de un juego AAA y cómo superar a dos referentes concretos: eFootball PES 2020 (Konami, 2019; media de la crítica 81 en OpenCritic [F 2]) y EA Sports FC 27 (Electronic Arts, 25-09-2026; media 77 [F 18]).

El informe combina cuatro técnicas: revisión de fuentes con niveles de verificación explícitos (capítulos 2 y 11), auditoría estática de corrección del código (capítulos 6 y 7), ejecución real de la batería de pruebas del proyecto (capítulo 5) y mediciones del código y del rendimiento (capítulos 3 y 4). Los capítulos 8, 9 y 10 sintetizan los resultados en una matriz de brechas, un plan hacia la versión 1.0 con criterios de aceptación y unas conclusiones con recomendaciones priorizadas. La limitación principal es de validez externa: ningún capítulo incluye una prueba con jugadores ajenos al proyecto, y las únicas mediciones de rendimiento en hardware real proceden de la laptop del dueño y de una prueba en su teléfono del 3-11 [D].

---

## 1.1 Contexto

### 1.1.1 El proyecto

Dinastía nació como un juego «4 juegos en 1» (gestión del club, partido, ciudad e instalaciones, minijuegos) y, por decisión del dueño del 9-11, se reestructuró en torno al club: la ciudad 3D quedó apagada mediante un interruptor en el código, sin borrarse, y el menú se redujo a la gestión 2D y a «Entrar al estadio» [D: `CLAUDE.md`, orden 33]. Desde el 11-11 el partido jugable usa por defecto el motor **C4**, que combina el núcleo portado del proyecto de código abierto League-Soccer (Apache 2.0) con tres piezas propias (decisión con balón, colocación sin balón y locomoción); el motor anterior queda como respaldo detrás de una bandera [D: `CLAUDE.md`, órdenes 38-39; `MOTOR_LEAGUE_SOCCER_PLAN.md` §12]. El 13-11 se reescribió el modo jugador como «La Ruta» [D: orden 47], y el 16-11 el dueño abrió tres frentes de trabajo —menús, aspecto del partido y jugabilidad— con la condición de usar solo recursos gratuitos con licencia comercial [D: orden 57].

El proyecto tiene rasgos de proceso poco habituales en un desarrollo pequeño: un banco de pruebas automático con 5.457 comprobaciones que debe terminar en «FIN. 0 fallos» antes de cada subida, unas 397 pruebas especiales adicionales, huellas de simulación reproducibles byte a byte, una regla que prohíbe scripts de más de 450 líneas, análisis estático continuo con SonarCloud y una extensión C++ en la que cada función tiene una «gemela» en GDScript que se compara byte a byte [M, cap. 5; D: `CLAUDE.md`, reglas fijas]. Al mismo tiempo acumula los riesgos típicos de un alcance grande con pocas manos: cambios de motor en pocas semanas, muchas sesiones paralelas y un documento de planificación de 2.856 líneas [M, cap. 3].

### 1.1.2 Los referentes

**eFootball PES 2020** se publicó el 10-09-2019 y obtuvo 81-82 en Metacritic y 81 en OpenCritic, con un 79 % de recomendación [F 1][F 2]. La crítica lo resumió como «maestría en el campo, frustrante fuera de él» [F 4]: elogió el equilibrio del partido, el pase dependiente del tiempo de ejecución y el *Finesse Dribble* [F 3][F 4], y criticó el comentario, la grada, la Liga Master estancada y la falta de licencias [F 4][F 5][F 6]. Es el referente de jugabilidad que el dueño ha nombrado de forma reiterada (órdenes 46, 51 y 57).

**EA Sports FC 27** se lanzó el 25-09-2026 para nueve plataformas, con más de 21.000 jugadores, más de 800 clubes y selecciones y más de 35 ligas declarados [F 17]. A siete semanas del lanzamiento su media de la crítica era 77 sobre 84 reseñas, con un 64 % de recomendación [F 18]. Las reseñas destacan una defensa más manual, centros que vuelven a importar y un modo Carrera que una de ellas considera «lo mejor del paquete», y critican la IA de los compañeros, el cambio de jugador, la parte social nueva y la monetización de Ultimate Team [F 19][F 20].

El capítulo 2 muestra que, siete años después, el referente comercial no supera en la crítica al referente de jugabilidad (81 frente a 76-80 en 2024-2026) [F 2][F 13][F 16][F 18]. Esa observación condiciona todo el informe: «superar» a ambos no significa lo mismo, y no se mide con una sola escala.

### 1.1.3 El encargo y su antecedente

El dueño pidió el 16-11 un informe de nivel académico que analizara todo el juego, encontrara fallos e investigara con fuentes qué hace falta para llegar al nivel AAA y superar a PES 2020 y a FC 27 [D: `00_INDICE.md`]. El mismo día se redactó un resumen ejecutivo (`INFORME_AAA_2026-11-16.md`) con una matriz de brechas, una hoja de ruta de cuatro hitos y cien tareas [D]. Ese documento declara sus límites: buena parte de lo que dice sobre los competidores está marcado como conocimiento general no verificado, y lo que dice de FC 27 es una proyección de la serie anterior [D: `INFORME_AAA_2026-11-16.md`, cabecera]. El presente informe sustituye esas marcas por fuentes con nivel de verificación (capítulos 2 y 11), añade evidencia propia del código (capítulos 3 a 7) y reconstruye la síntesis y el plan sobre esa base (capítulos 8 a 10).

---

## 1.2 Problema

El problema de investigación puede formularse así: **dado un juego de fútbol desarrollado por un equipo mínimo, sin presupuesto para licencias ni captura de movimiento, ¿qué parte de la calidad percibida de un juego AAA es alcanzable, dónde está hoy el proyecto respecto de ella, qué defectos lo separan de ese nivel y con qué recursos y en qué orden puede cerrarse la distancia?**

Tres características hacen que el problema no sea trivial.

1. **«AAA» no es una propiedad medible del producto**, sino una categoría de producción asociada a presupuestos de cientos de millones de dólares y a equipos de miles de personas (la única cifra concreta documentada es la filtración de Insomniac Games: unos 315 millones de dólares para un título [F 54]; el campus de EA Vancouver, donde se desarrolla FC, reúne unas 2.400 personas [F 55]). La pregunta útil es qué rasgos de la *calidad percibida* AAA dependen de dinero y cuáles de criterio y horas.
2. **Los referentes no son comparables entre sí**: PES 2020 destaca en el partido y fracasa en el entorno; FC 27 destaca en licencias, presentación y contenido y es criticado en interfaz, IA de compañeros y monetización [F 4][F 16][F 19][F 20]. Superar a uno no implica superar al otro.
3. **El objeto de estudio se mueve**: durante la redacción del informe se aplicaron dieciséis arreglos derivados de los capítulos 6 y 7, y otras sesiones subieron cambios a la misma rama (capítulo 5, §5.6). Las cifras se fechan y se refieren a un commit o a un día concreto.

---

## 1.3 Preguntas de investigación

| Id | Pregunta | Subpreguntas | Capítulos que la responden |
|---|---|---|---|
| **RQ1** | ¿Qué es «AAA» y qué parte es aplicable a Dinastía? | ¿Qué rasgos de un AAA dependen de presupuesto y cuáles de criterio y tiempo? ¿Qué han conseguido equipos pequeños en el género? ¿Qué penaliza la crítica a los juegos de fútbol grandes? | 2, 8, 10 |
| **RQ2** | ¿Dónde está Dinastía? | ¿Qué tamaño y estructura tiene el código? ¿Qué rendimiento tiene en el hardware disponible? ¿Qué notas por área se sostienen con evidencia y con qué incertidumbre? | 3, 4, 8 |
| **RQ3** | ¿Qué fallos tiene? | ¿Qué defectos de corrección hay en el motor del partido, en la gestión, en La Ruta y en los menús? ¿Pasa el proyecto sus propias pruebas? ¿Por qué no las detectó el proceso? | 5, 6, 7 |
| **RQ4** | ¿Cómo superar a PES 2020 y a FC 27? | ¿En qué áreas hay que igualar, en cuáles se puede ganar y en cuáles no se debe competir? ¿Con qué hitos, métricas y criterios de aceptación? | 8, 9, 10 |
| **RQ5** | ¿Qué recursos públicos lo hacen posible? | ¿Qué recursos gratuitos con licencia comercial cierran cada brecha? ¿Qué no existe gratis con licencia limpia? ¿Qué riesgos legales tienen? | 2 (§2.9), 11, 9 |

Las preguntas siguen un orden deliberado: primero se acota el objetivo (RQ1), luego se describe el punto de partida (RQ2 y RQ3), después se diseña el camino (RQ4) y, por último, se comprueba que el camino es practicable con los medios disponibles (RQ5). Una respuesta a RQ4 que dependiera de recursos inexistentes o de licencias no comerciales no sería válida bajo la orden 57 del dueño.

---

## 1.4 Definiciones operativas

**Calidad percibida AAA.** Conjunto de rasgos que el jugador y la crítica asocian a un producto de gran presupuesto: sensación de control, animación creíble, presentación televisiva, estabilidad y pulido, contenido abundante y licenciado. Se adopta la distinción del resumen ejecutivo entre rasgos «de dinero» (captura de movimiento propia, licencias, fotogrametría, control de calidad masivo) y rasgos «de criterio y horas» (sensación de control, presentación, estabilidad, recorte de alcance) [D: `INFORME_AAA_2026-11-16.md` §1], y se contrasta con fuentes en el capítulo 2 (§2.8).

**Superar a un referente.** Se usan tres sentidos, que no se confunden en el texto:
- *por áreas*: tener mejor nota en un área concreta de la matriz del capítulo 8;
- *en conjunto ponderado*: tener mejor media con los pesos que fija el propio proyecto (60 % partido, 25 % menús y flujo, 15 % lo demás [D: `INFORME_AAA_2026-11-16.md` §0]);
- *por el criterio del dueño*: jugabilidad y diversión por encima de las cifras reales (orden 38), que solo puede verificarse jugando.

**Brecha.** Diferencia entre la nota de Dinastía y la del referente en un área, acompañada de su evidencia y de una estimación de incertidumbre (capítulo 8, §8.2).

**Fallo.** Defecto de corrección: el código no hace lo que anuncia al jugador, a otra parte del código o a una regla fija del proyecto. Se excluyen las preferencias de estilo y las decisiones de diseño, salvo cuando producen un efecto que el propio código declara no querer. Cada fallo lleva archivo y línea, escenario reproducible, propuesta de arreglo, gravedad y veredicto.

**Veredicto.** CONFIRMADO cuando el camino de ejecución se demostró por lectura completa de los llamadores o se reprodujo; PLAUSIBLE cuando el defecto está en el código pero su efecto depende de condiciones no fijadas estáticamente; NO REPRODUCIDO cuando una observación no se repitió aislada (capítulo 5).

**Recurso público utilizable.** Recurso gratuito cuya licencia permite usarlo y distribuirlo dentro de un juego comercial de código cerrado: CC0, CC BY, CC BY-SA, MIT, Apache 2.0, BSD, zlib, ISC, SIL OFL y términos propietarios equivalentes; se excluyen NC, ND cuando haya que modificar, «solo uso personal» y código GPL o AGPL dentro del binario (capítulo 11, §11.3).

---

## 1.5 Método

### 1.5.1 Diseño general

El informe es un estudio de caso único con triangulación de métodos. Ninguna técnica basta por sí sola: la revisión de fuentes no dice nada del código; la auditoría estática encuentra defectos de lógica pero no dice si el proyecto pasa sus pruebas; las pruebas automáticas dicen si se cumple lo que comprueban, no si comprueban lo importante; y las mediciones dicen cuánto, no por qué. El diseño cruza las cuatro para que cada conclusión de los capítulos de síntesis tenga, al menos, dos apoyos de naturaleza distinta.

| Técnica | Capítulos | Unidad de análisis | Producto | Debilidad principal |
|---|---|---|---|---|
| Revisión de fuentes | 2, 11 | Fuente externa (reseña, artículo, licencia, ficha oficial) | Hechos con nivel L/E; catálogo de recursos | Acceso parcial; sin juego propio de los referentes |
| Auditoría estática | 6, 7 | Función o camino de ejecución | Hallazgos con archivo:línea, escenario, arreglo y veredicto | Efectos deducidos, no observados |
| Pruebas reales | 5 | Prueba del banco o especial | OK/FALLO, clasificación proyecto/entorno, fallos latentes | Sin GPU; copia de trabajo en movimiento |
| Mediciones | 3, 4 | Archivo, carpeta, escena o fotograma | Conteos y tiempos | En la nube, solo cifras relativas; en hardware real, pocas muestras |

### 1.5.2 Revisión de fuentes

Los capítulos 2 y 11 aplican una búsqueda dirigida por temas, con preferencia por la fuente primaria (página del editor, nota de prensa, ficha oficial de congreso, artículo publicado, archivo `LICENSE` del repositorio). Cada entrada de la bibliografía lleva un nivel: **L** si el contenido se leyó en la fuente o en un agregador que reproduce el dato, y **E** si solo se verificó por el extracto del buscador. Los accesos fallidos se documentan en lugar de ocultarse (capítulo 2, §2.2.3; capítulo 11, §11.2.3). El capítulo 2 reúne 68 fuentes y el 11 otras 69 [M: recuento de sus bibliografías].

### 1.5.3 Auditoría estática

Los capítulos 6 y 7 leen el código del motor del partido (unas 12.700 líneas en 54 archivos, 8.900 en lectura completa) y de la gestión, La Ruta y los menús, siguiendo cada sospecha hasta sus llamadores [D: cap. 6 §6.2; cap. 7 §7.2]. Las preguntas guía cubren estado no reiniciado en fronteras (mitad, partido, motor), aplicación real de banderas y ajustes, igualdad de las gemelas C++, reglamento, determinismo, ida y vuelta del guardado y cumplimiento de las reglas fijas de `CLAUDE.md`. Dos sospechas se resolvieron con una reproducción mínima en Godot 4.7.2 sin pantalla (capítulo 7, G-01) o con un cálculo numérico reproducible (capítulo 6, M6-06).

### 1.5.4 Pruebas reales

El capítulo 5 ejecuta la batería del proyecto tal como la define `CLAUDE.md` en un contenedor Linux de cuatro núcleos sin GPU: importación, banco (`herramientas/banco.sh`), especiales (`herramientas/especiales.sh`, repartidas en tres procesos) y norma de líneas (`revisar_lineas.py`). Cada FALLO se repite de forma aislada y se clasifica como del proyecto o del entorno con un criterio explícito (capítulo 5, §5.2.3). Se analizan además los errores que el registro del banco contiene aunque el banco termine en verde.

### 1.5.5 Mediciones

Las mediciones son de dos clases. Las **estructurales** (capítulo 3) cuentan archivos, líneas, capas, clases, métodos nativos y contenido generado con herramientas de sistema (`find`, `wc`, `grep`) y con la herramienta del proyecto `herramientas/medir_contenido.tscn`; son reproducibles con los comandos que se citan. Las de **rendimiento** (capítulo 4) proceden de tres orígenes con validez distinta: la laptop del dueño (cifras absolutas válidas para ese equipo), el contenedor en la nube con renderizado por software (solo cifras relativas: llamadas de dibujo, triángulos y memoria) y el teléfono del dueño (una sola prueba documentada, del 3-11). El capítulo 4 no produce mediciones nuevas de FPS: la nube no tiene GPU y la regla del proyecto lo prohíbe (orden 19; orden 57).

### 1.5.6 Síntesis

El capítulo 8 parte de la escala 1-10 de la comparativa interna del 10-11 (`COMPARATIVA_PES2020.md`) y del resumen ejecutivo, y revisa cada nota con la evidencia de los capítulos 2 a 7 y 11. Cada nota lleva un intervalo de incertidumbre y el tipo de evidencia que la sostiene. El capítulo 9 traduce las brechas y los fallos en hitos con métricas y criterios de aceptación verificables, y el 10 responde a las preguntas de investigación.

---

## 1.6 Convenciones

### 1.6.1 Marcas de evidencia

| Marca | Significado | Ejemplo |
|---|---|---|
| **[M]** | Medido o calculado en este informe, con comando o herramienta citados | 338.521 líneas de GDScript propio [M] |
| **[D]** | Dato de un documento del proyecto (se cita el archivo) | ULTRA ~39-41 FPS en la laptop [D: `PLAN_GENERAL.md`] |
| **[F n]** | Fuente externa número *n* de la bibliografía del capítulo 2 | media 81 en OpenCritic [F 2] |
| **[R n]** | Fuente externa número *n* de la bibliografía del capítulo 11; en la bibliografía unificada del capítulo 10 equivale a [F 68+n] | grabaciones CC0 de estadio [R 28] |
| **[E]** | Estimación de quien redacta, con su razonamiento | 3-4 semanas de trabajo [E] |

Una cifra sin marca no debe aparecer en el informe. Cuando dos documentos del proyecto dan cifras distintas para la misma magnitud, se dice y se prefiere la medición más reciente (por ejemplo, el número de clubes del mundo generado, capítulo 3, §3.5.2).

### 1.6.2 Identificadores de los fallos

| Prefijo | Origen | Ámbito |
|---|---|---|
| M6-01 … M6-26 | Capítulo 6 | Motor del partido jugable |
| R-01 … R-14 | Capítulo 7 | La Ruta (modo jugador) |
| G-01 … G-08 | Capítulo 7 | Gestión, mundo simulado y guardado |
| V-01 | Capítulo 7 | Visor 3D (gala de premios) |
| M-01, M-02 | Capítulo 7 | Menús e interfaz general |
| F-01 … F-05 | Capítulo 5 | Fallos reproducibles de las especiales |
| L-01 … L-04 | Capítulo 5 | Fallos latentes en el registro del banco |
| E-01 … E-05 | Capítulo 5 | Fallos atribuidos al entorno |
| **R5-01 … R5-03** | Capítulo 5 (allí «R-01 … R-03») | Recursos con errores de importación |

El capítulo 5 usa «R-01 … R-03» para los recursos, lo que choca con los identificadores de La Ruta del capítulo 7. A partir de este capítulo, esos tres se citan como **R5-01, R5-02 y R5-03**. Algunos hallazgos son el mismo defecto visto desde dos métodos: M6-12, M-02 y F-03 son la misma infracción de la norma de 450 líneas, y V-01 (capítulo 7) y F-04 (capítulo 5) tocan el mismo archivo con defectos distintos.

### 1.6.3 Gravedad

Se conservan las escalas de cada capítulo: crítica, alta, media y baja en el capítulo 7; alta, media y baja en el 6; ALTA, MEDIA-ALTA, MEDIA y BAJA en el 5. En los capítulos de síntesis una gravedad «crítica» significa pérdida de datos o de la partida; «alta», una regla visible al jugador que no se cumple o un control que falla en el modo principal; «media», un efecto de equilibrio, coherencia o rendimiento; «baja», ruido, casos raros o defectos sin efecto observable.

---

## 1.7 Entorno y fechas

- **Fecha de corte**: 16-11-2026. Las fuentes externas se consultaron ese día.
- **Código**: rama de trabajo `ccr-8ca5e329-7uzbi2`, al día con `main`. Los capítulos 6 y 7 auditaron el estado anterior a los arreglos del 16-11 (commit `b2f4f80d` para el capítulo 7); el capítulo 5 ejecutó el banco sobre `ae23b25b`; los capítulos 3 y 9 se refieren al commit `3db6e8eb`, con dos archivos modificados sin subir por otra sesión (`ui/componentes/menu_lateral.gd` y `visor/interior_oculto.gd`, que corresponden a F-02 y L-01; capítulo 9, §9.2).
- **Motor**: Godot 4.7.2 estable oficial.
- **Contenedor**: Linux x86_64, CPU Intel Xeon de cuatro núcleos a 2,30 GHz, 15 GB de RAM compartidos, sin GPU (renderizado por software llvmpipe) [D: cap. 5 §5.2.1].
- **Hardware del dueño**: laptop Acer AL14-31P con Intel Core i3-N300 y gráfica Intel UHD integrada, medida a 1280x720 [D: `PLAN_GENERAL.md`, «ESTADO AL CIERRE DEL 16-11»]; teléfono Android en el que se hizo la prueba del 3-11 [D: `PRUEBA_DUENO_MOVIL_2026-11-03.md`].

---

## 1.8 Limitaciones y amenazas a la validez

1. **Ningún juego se jugó para este informe.** Ni PES 2020 ni FC 27 se probaron; sus valoraciones proceden de la crítica [F 2][F 18]. Tampoco se jugó Dinastía con mando: los efectos de los fallos son deducciones del código, y las notas de jugabilidad proceden del dueño (veredicto del 3-11, «jugabilidad muy mala» [D]) y de métricas automáticas del motor.
2. **FC 27 es reciente.** Siete semanas después del lanzamiento las medias pueden moverse y no hay análisis técnicos independientes (capítulo 2, §2.12).
3. **Validez externa del rendimiento.** Las cifras absolutas proceden de un único portátil, que además se calienta tras varias pasadas y muestra un ruido de ±15 FPS entre repeticiones [D: `PLAN_GENERAL.md`, «ESTADO AL 15-11»]. Del teléfono solo hay una prueba documentada (3-11) y un dato posterior comunicado por el dueño (~4-11) [D: `COMPARATIVA_PES2020.md` §0].
4. **Validez de constructo de las notas.** La escala 1-10 de la matriz es ordinal y procede de documentos del proyecto; el capítulo 8 la revisa con evidencia, pero sigue siendo un juicio. Por eso cada nota lleva un intervalo y el tipo de evidencia.
5. **Objeto en movimiento.** El capítulo 5 documenta dos FALLO debidos a commits concurrentes en la misma copia de trabajo (E-01). Las cifras de este informe se fechan; un arreglo posterior puede invalidarlas.
6. **Independencia del auditor.** Quien redacta forma parte del mismo proceso de desarrollo asistido que escribió buena parte del código auditado, y los arreglos del 16-11 los hizo la misma sesión que auditó. Es un riesgo de sesgo de confirmación: tiende a infravalorar los defectos de diseño propio y a sobrevalorar la eficacia de los arreglos. Se mitiga con la regla de citar archivo y línea, con pruebas reproducibles y con la recomendación (capítulo 9) de que una sesión distinta revise los arreglos.
7. **Sin asesoría jurídica.** Lo que se dice de licencias, derecho de imagen y regulación describe las fuentes; no sustituye una revisión profesional antes de vender (capítulo 2, §2.12; capítulo 11, §11.9).
8. **Sesgo de idioma de las fuentes.** Casi todas están en inglés; la crítica en español, italiano o portugués no se revisó de forma sistemática (capítulo 2, §2.2.4).
9. **Sin datos de mercado propios.** No hay telemetría, ventas ni encuestas; las afirmaciones sobre qué valora el público proceden de la crítica y de casos publicados [F 56]-[F 63].

---

## 1.9 Consideraciones éticas y de datos

El informe respeta las reglas fijas del proyecto sobre datos personales y derechos: los datos reales de clubes y jugadores viven solo en `pack_real.json` y las caras reales solo en `caras_reales.pck`, que no se publica ni va al repositorio [D: `CLAUDE.md`]; en los ejemplos se usan nombres ficticios y se varían club y país (orden 34). Las bases de datos de fútbol con jugadores reales que se recomiendan para calibrar la IA se usan solo como cifras agregadas, nunca como fichas (capítulo 11, §11.9). El capítulo 2 documenta, además, la evidencia sobre los daños asociados a las cajas de botín [F 28] y la regulación vigente [F 22]-[F 27], que es relevante para una decisión de producto del propio proyecto (sin pago aleatorio, decisión del dueño del 26-10 [D: `PLAN_GENERAL.md` §0]).

---

## 1.10 Estructura del informe

Los capítulos 2 a 7 y 11 aportan la evidencia (estado del arte; arquitectura; rendimiento; pruebas; fallos del motor; fallos de gestión, La Ruta y menús; recursos públicos) y los capítulos 8 a 10 la síntesis (brechas, plan y conclusiones). La correspondencia entre preguntas y capítulos está en la tabla de §1.3. El capítulo 11 se numera al final porque se redactó como anexo de catálogo; se lee junto al capítulo 9, que lo usa para asignar recursos a cada hito.
