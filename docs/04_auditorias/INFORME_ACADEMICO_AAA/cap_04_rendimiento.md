# Capítulo 4. Rendimiento medido

Informe académico AAA de Dinastía · Redacción: 16-11-2026.
Convenciones: [M] medido en este informe · [D] documento del proyecto (se cita el archivo) · [F n] fuente externa del capítulo 2 · [E] estimación. Este capítulo **no produce mediciones nuevas de FPS**: el contenedor no tiene GPU y las reglas del proyecto lo prohíben (órdenes 19 y 57). Reúne, ordena y critica las mediciones existentes.

---

## Resumen

El rendimiento de Dinastía se ha medido en tres lugares con validez distinta: la laptop del dueño (Acer AL14-31P, Intel Core i3-N300, gráfica Intel UHD integrada, 1280x720), el contenedor en la nube con renderizado por software, y una prueba en el teléfono del dueño. En la laptop, con la cámara de TV del partido, ULTRA rinde **~39-41 FPS** (con el 3D al 60 %) y ULTRA BAJA **~100-107 FPS**, con un fotograma de 9,4-10 ms del que la GPU ocupa solo 4-6 ms [D]. Ese fotograma tiene un **suelo de unos 10 ms** que no baja al ocultar a los 22 jugadores, al apagar las animaciones ni al quitar el entorno del estadio; con la escena quieta baja a 6,4 ms [D]. La conclusión del proyecto, que este capítulo comparte, es que el suelo es de CPU y de presentación del propio motor gráfico, no de contenido ni del motor del partido, que cuesta ~1 ms por fotograma [D].

Frente a los umbrales del dueño (ULTRA ≥ 30, ULTRA BAJA ≥ 100), la laptop cumple, la segunda con un margen inferior al ruido medido entre pasadas (±15 FPS). Frente a los objetivos más ambiciosos (120 FPS en equipos modestos, orden 19; 150 en ULTRA BAJA, 15-11) no cumple, y el análisis del suelo indica que no cumplirá sin cambios en el motor gráfico. En el teléfono, la única prueba documentada (3-11) dio **5 FPS en MEDIA con la GPU al 100 % y la CPU al 0 %**, y un dato posterior del dueño (~4-11) **30 FPS en el partido en MÍNIMA** [D]; desde entonces no hay ninguna medición en el teléfono, pese a una docena de cambios que deberían mejorarla. Ningún lugar ha medido la **latencia de extremo a extremo**, la magnitud que la literatura relaciona directamente con la sensación de control [F 33][F 35]. Se propone un protocolo de medición para el teléfono y la laptop.

---

## 4.1 Introducción

### 4.1.1 Por qué importa el rendimiento para la pregunta AAA

El rendimiento interviene de dos formas en la calidad percibida. La primera es directa: un partido que se dibuja a pocos fotogramas por segundo no se puede jugar, y es lo primero que el dueño observó en su teléfono (5 FPS, «jugabilidad muy mala») [D: `PRUEBA_DUENO_MOVIL_2026-11-03.md`]. La segunda es indirecta, a través de la latencia: cada fotograma añade tiempo entre la pulsación y la respuesta visible, y la literatura sitúa la mediana de detección del retardo motor-visual en 51-90 ms y la caída significativa de la calidad de experiencia hacia los 140-190 ms [F 33][F 35]. Además, el proyecto ha hecho del rendimiento en equipos modestos un argumento de producto frente a FC, que exige más hardware en PC [D: `INFORME_AAA_2026-11-16.md` §8.5].

### 4.1.2 Preguntas

- P1. ¿Qué rendimiento tiene el partido en el hardware real disponible, por nivel de calidad?
- P2. ¿Dónde se va el tiempo de un fotograma, y qué parte depende del motor del partido y de la extensión C++?
- P3. ¿Qué se sabe del teléfono, y con qué fiabilidad?
- P4. ¿Cómo se comparan esas cifras con los objetivos del dueño y con los umbrales de la literatura?
- P5. ¿Qué falta medir y cómo debe medirse?

---

## 4.2 Marco de referencia

### 4.2.1 Del fotograma a la latencia

| FPS | Duración del fotograma |
|---|---|
| 30 | 33,3 ms |
| 40 | 25,0 ms |
| 60 | 16,7 ms |
| 100 | 10,0 ms |
| 120 | 8,3 ms |

La latencia que percibe el jugador no es un fotograma, sino la suma de una cadena: muestreo de la entrada, espera hasta el siguiente paso de simulación, el paso, la animación hasta el primer cuadro en que el cambio es visible, el dibujo, la sincronía vertical y el retardo de la pantalla [F 36]; el capítulo 2 lo resume en §2.5.2. En un juego que dibuja a 40 FPS, una cadena de tres o cuatro fotogramas, que es habitual con doble búfer y vsync, sumaría unos 75-100 ms antes de contar la pantalla [E]. A 100 FPS la misma cadena ocuparía 30-40 ms [E]. Las cifras de FPS de este capítulo deben leerse, por tanto, como el **componente variable** de una latencia que nadie ha medido completa.

### 4.2.2 Umbrales de la literatura (capítulo 2)

| Umbral | Valor | Fuente | Tarea del estudio |
|---|---|---|---|
| Detección por los más sensibles | 26-40 ms | [F 33] | botón y cambio visual simple |
| Mediana de detección | 51-90 ms | [F 33] | ídem |
| Punto de detección al 50 % en discriminación | ~200 ms (grandes diferencias individuales) | [F 34] | botón y disco giratorio |
| Inicio de la caída de calidad de experiencia | ~140 ms | [F 35] | interceptar un objetivo con el ratón |
| Caída significativa de calidad de experiencia | ~190 ms | [F 35] | ídem |
| Tolerancia de red para avatar en tercera persona (deportes) | 500 ms | [F 36] | latencia de red en línea; rendimiento, no percepción |

Ninguno de esos estudios usa un mando ni un juego de fútbol (capítulo 2, §2.12, punto 4). Su papel aquí es orientativo: definen una **banda** dentro de la cual la sensación de control empieza a degradarse.

### 4.2.3 Objetivos del dueño

| Objetivo | Origen | Valor |
|---|---|---|
| Equipos modestos (4 GB DDR3, Intel UHD/HD, Pentium) | orden 19 (2-11) | ≥ 120 FPS |
| Teléfono | orden 22 (3-11) | 60 FPS en el partido; calidad por defecto la más baja |
| Teléfono, configuración por defecto | orden 36 (10-11) | modo rendimiento y ahorro de menús encendidos; tope de 90 FPS |
| Laptop, ULTRA | 15-11 | ≥ 30 FPS (después, «ULTRA ALTA 40») |
| Laptop, ULTRA BAJA | 15-11 | ≥ 100 FPS (después, 150) |
| Suelo de no regresión propuesto | resumen ejecutivo §6.4 | ULTRA ≥ 38 y ULTRA BAJA ≥ 95 en la laptop |

[D: `CLAUDE.md`; `PLAN_GENERAL.md`, «ESTADO AL 15-11» y «ESTADO AL CIERRE DEL 16-11»; `INFORME_AAA_2026-11-16.md` §6.4]

---

## 4.3 Fuentes de medición y su validez

| Fuente | Qué mide bien | Qué no mide | Herramientas |
|---|---|---|---|
| **Laptop del dueño** | FPS y ms absolutos en ese equipo; GPU y CPU por separado; variantes que apagan piezas | Otros equipos; el teléfono; latencia | `pruebas/perfilar_gpu.tscn` con variables `OCULTAR_JUG`, `ANIM_OFF`, `OCULTAR_NODO`, `SUBVP_OFF`, `APAGAR=VISTA`, `PAIS`, `CLUB`, `CAM` [D] |
| **Contenedor (llvmpipe)** | Llamadas de dibujo, triángulos, objetos, memoria (no dependen de la máquina); coste **relativo** de variantes | FPS y ms absolutos; Forward+ (no hay Vulkan) | `herramientas/hw_modesto.sh`, `medir_partido*.tscn`, `inventario_partido_gpu.tscn` [D: `rendimiento_120fps.md`] |
| **Contenedor sin pantalla** | Coste de CPU de funciones y del motor del partido (µs por paso), con precauciones | Fotograma: tiene un suelo de **6,9 ms** aunque la escena esté vacía | `zz_perfil_*`, `perfil_colocacion`, `medir_motor_cpu` [D: `rendimiento_120fps.md`, «CORRECCIÓN»] |
| **Teléfono del dueño** | Lo único que importa para el móvil | Hasta ahora: una prueba con capturas (3-11) y un dato oral (~4-11) | Contador de FPS del juego; prueba integrada `nucleo/medicion.gd` (`--medir`, «Prueba de rendimiento») [D] |

Dos advertencias metodológicas del propio proyecto son importantes y se respetan aquí: (a) el tiempo de fotograma `--headless` tiene un suelo de 6,9 ms y no sirve para comparar scripts, lo que invalidó algunas conclusiones de la tanda del 2-11 [D: `rendimiento_120fps.md`]; y (b) en el contenedor no existe Forward+, de modo que capturas y mediciones salen en Compatibilidad, lo que contradice la regla de revisar lo visual en Forward+ [D: `PLAN_GENERAL.md`, «FALLOS DETECTADOS», nº 6].

---

## 4.4 Resultados en la laptop del dueño

### 4.4.1 Evolución de ULTRA

| Fecha | Configuración de ULTRA | FPS (cámara del partido, 1280x720) | Fuente |
|---|---|---|---|
| antes del 15-11 | MSAA x8, sombras con atlas grande, 3D al 100 % | ~13 | [D: «ESTADO AL 15-11»] |
| 15-11 | sin MSAA x8, con TAA + FXAA, atlas de sombras 2048, 3D al 75 % | ~30 | ídem |
| 16-11 | 3D al 60 % (`escala_ultra` 0,75 → 0,6) | **~39-41** en frío | [D: «ESTADO AL CIERRE DEL 16-11»] |

Desglose de la GPU en ULTRA medido con `perfilar_gpu` [D: «ESTADO AL 15-11»]:

| Efecto | Coste de GPU |
|---|---|
| MSAA x8 | ≈ 19 ms |
| Sombras | ≈ 11 ms |
| SSAO | ≈ 4,5 ms de ~31 ms (bajar su calidad no ahorra: el coste es el pre-paso de normales) |
| SDFGI, SSIL, SSR, niebla, glow | ≤ 4 ms cada uno |
| FSR2 | no ayuda en esta gráfica integrada |

Lectura: la subida de 13 a 40 FPS se consiguió quitando lo que la gráfica integrada no puede pagar (MSAA x8) y bajando la resolución interna. El coste visual («bordes algo menos nítidos y sombras menos definidas») lo aceptó el dueño [D]. ULTRA en esta laptop es, por tanto, una calidad alta **reescalada**, no la calidad máxima del motor.

### 4.4.2 ULTRA BAJA

| Medida (cámara de TV, 1280x720) | Valor | Fuente |
|---|---|---|
| FPS, mediana de 5 repeticiones (15-11) | ~99 (90-110) | [D: «ESTADO AL 15-11»] |
| FPS, 3 repeticiones por variante (15-11 tarde) | ~100-107 | ídem |
| Fotograma | 9,4-10 ms | ídem |
| GPU | 4-6 ms | ídem |
| Llamadas de dibujo / triángulos | 147 / 247 k | ídem |
| Ruido entre pasadas seguidas | ±15 FPS (86-118 en tres repeticiones) | ídem |
| Renderizador de Compatibilidad | 87-91 FPS (peor que Forward+) | ídem |
| Público 2D (`PUBLICO_2D=1`) | −35 % de triángulos (171 k), **mismo fotograma** | ídem |

Condiciones que invalidan medidas, según el propio proyecto: la laptop se calienta tras varias pasadas y las cifras caen; con otras sesiones abriendo Godot a la vez las medidas no valen («llegó a haber 32 procesos») [D: «ESTADO AL CIERRE DEL 16-11»].

### 4.4.3 El suelo de unos 10 ms

Los experimentos del 15-11 por la noche son el resultado más informativo del conjunto [D: «ESTADO AL 15-11», «MEDIDO el 15-11 (noche)»]:

| Variante (ULTRA BAJA, 3 repeticiones) | Fotograma |
|---|---|
| Base | ~9,5-10 ms |
| Ocultar a los 22 jugadores (`OCULTAR_JUG=1`) | sin cambio |
| Desactivar todos los `AnimationPlayer` (`ANIM_OFF=1`) | sin cambio |
| Ocultar `EntornoEstadio`, `TunelVestuario`, cámara, directivas o mascota (`OCULTAR_NODO=`) | sin cambio |
| Sin el `SubViewport` de la escena (`SUBVP_OFF=1`) | sin cambio |
| Bajar la escala del 3D | GPU 8 → 5,5 ms; fotograma ~10 ms |
| Escena quieta: sin motor, sin animar, balón quieto (`APAGAR=VISTA`) | **6,4 ms** |

La GPU no manda (4-6 ms de 10) y quitar contenido no mueve el fotograma; solo lo baja detener la escena. Los ~3,5 ms que separan la escena viva de la quieta se reparten entre el motor del partido (~0,9-1 ms medidos en `_process` de `VistaEstadio`) y el trabajo del motor gráfico por fotograma con nodos en movimiento, «sin un punto caliente» [D]. La conclusión del proyecto —«~10 ms es un suelo de CPU/presentación, no de contenido: ni más C++ del motor del partido ni quitar objetos llegan a 150 FPS aquí»— es coherente con los datos. Dos matices:

1. **No se ha separado la presentación de la CPU del motor gráfico.** El experimento no distingue entre el coste de recorrer y actualizar la escena (transformaciones, esqueletos, culling) y el de la sincronía con la pantalla o el compositor del sistema. Un perfilador de trazas con marcas del motor (Tracy o Perfetto, que Godot ya puede compilar con la opción `profiler=` de SCons [R 50][R 51][R 54]) resolvería esa ambigüedad.
2. **6,4 ms con la escena quieta es ya un 64 % del fotograma.** Incluso con un motor gráfico más eficiente por nodo, 150 FPS (6,7 ms) exigiría bajar del suelo de una escena estática. Con lo medido, 150 FPS en ULTRA BAJA no es un objetivo realista en esta laptop [E basada en D].

### 4.4.4 Desglose de CPU por método

| Medida | Valor | Fuente |
|---|---|---|
| Paso del motor del partido (antes del 15-11) | ~2,3 ms/paso | [D: «ESTADO AL 15-11»] |
| `_mover_jugadores` | 853 µs (37 %) | ídem |
| `_estado_league` | 463 µs | ídem |
| `_estado_sin_balon` | 279 µs | ídem |
| Física de los 22 tras pasar a C++ | 238 → 96 µs/paso; ≈ 0,15 ms en el fotograma real | ídem |
| `_process` de `VistaEstadio` entero | ≈ 1 ms (motor 0,9 ms; techo, rótulos y HUD < 50 µs) | ídem |
| Paso de C4 (`perfil_colocacion`, contenedor) | ~1.160 → ~960 µs tras el estado por paso en C++ (±10-20 %) | [D: `PASO_CPP_PLAN.md` §2j] |
| Peso del paso del motor en un fotograma a 60 FPS | ~9 % | [D: `INFORME_SESION_2026-11-15.md` §3] |

Lectura: el motor del partido pasó de ~2,3 ms a ~1 ms por fotograma en la laptop gracias a la extensión C++ y a recortes de cálculo, pero en el contexto de un suelo de 10 ms esa mejora es de un 10-13 % del fotograma como máximo, y se pierde dentro del ruido de ±15 FPS entre pasadas. Para el objetivo de FPS, el C++ del partido ya ha dado lo que podía dar. Para otros objetivos —simulación del mundo (semana −50 %, capítulo 3, §3.7.3) y margen de CPU en el móvil— sí sigue siendo útil.

---

## 4.5 Resultados en el contenedor (cifras relativas)

### 4.5.1 Coste por variante de la GPU del partido

El inventario del 4-11 mide, con renderizado por software limitado por relleno de píxeles como la gráfica de un teléfono, cuánto baja el tiempo de fotograma al quitar una pieza [D: `rendimiento_120fps.md`, «GPU del partido 3D»]:

| Variante | MEDIO | MÍNIMO (3D al 50 %) |
|---|---|---|
| sin MSAA | −80 % | −70 % |
| 3D al 50 % / al 35 % | −54 % / −69 % | +1 % / −28 % |
| sin el entorno exterior del estadio | −33 % | −21 % |
| sin sombras de todas las luces | −19 % | −3 % |
| sin ajuste de color | −9 % | −18 % |
| sin focos (26 luces omnidireccionales) | −9 % | −12 % |
| sin butacas / sin hinchas | −8 % / −6 % | −11 % / −18 % |
| sin rótulos 3D | −7 % | −15 % |
| sin jugadores | −2 % | −5 % |

Estas cifras motivaron decisiones ya aplicadas: MSAA apagado en MÍNIMA (R01, 4-11), entorno exterior tapado también en MEDIA durante el partido (orden 32, punto 6) y «Partido ligero» sin ajuste de color, rótulos 3D ni focos (orden 32, punto 7) [D: `CLAUDE.md`].

### 4.5.2 Presupuesto de dibujo por nivel

| Nivel (partido, cámara de TV) | Llamadas | Triángulos | Memoria de vídeo | Fuente |
|---|---|---|---|---|
| MÍNIMO (6-11) | 338 | 387.062 | 137 MB | [D: `calidad_7_niveles_2026-11-06.md`] |
| MEDIO (6-11) | 709 | 845.501 | 208 MB | ídem |
| ALTO (6-11) | 925 | 1.787.095 | 215 MB | ídem |
| ULTRA BAJA en la laptop (15-11) | 147 | 247 k | — | [D: «ESTADO AL 15-11»] |
| HUD del partido en MÍNIMA (12-11) | 95 → 40 llamadas 2D | — | — | [D: `rendimiento_120fps.md`, sesión 14] |
| Público 2D en ULTRA BAJA (Chile / España) | 232 → 165 / 198 → 174 | −40 % / −40 % | — | [D: `INFORME_SESION_2026-11-15.md` §6] |

La meta de diseño de ULTRA BAJA era menos de 130 llamadas de media [D: `calidad_7_niveles_2026-11-06.md`]; la laptop mide 147 en el partido. El público 2D reduce mucho la geometría sin cambiar el fotograma de la laptop, lo que confirma que en ese equipo la GPU no es el límite; en el teléfono, cuyo cuello era la GPU, podría ser decisivo, y no se ha medido.

### 4.5.3 Simulación del mundo

| Medida | Antes | Después | Fuente |
|---|---|---|---|
| Semana del mundo entero (521 clubes) | 792 ms | 395 ms | [D: `PASO_CPP_PLAN.md` §2c] |
| Cruce de la IA (partido simulado) | ~2.400-2.700 µs sin extensión | ~790 µs | [D: §2i] |
| Once automático (`Club.once()`) | 166 µs | ~130 µs | [D: §2i] |

La semana del mundo afecta al tiempo de espera entre partidos, no a los FPS. A 395 ms por semana en el contenedor, avanzar una temporada de 38 semanas cuesta unos 15 s de cálculo [E: 38 × 0,395 s]; en un teléfono de gama media podría ser varias veces más [E], y sin extensión nativa (Android hasta el 16-11, Web antes del 16-11) unas dos veces más [D: `PASO_CPP_PLAN.md` §2.2]. El 16-11 se compilaron los binarios de Android arm64 y Web, pero ninguno se ha probado en un teléfono [D: §2j].

---

## 4.6 El teléfono

### 4.6.1 Lo medido

| Fecha | Versión | Calidad | Resultado | Fuente |
|---|---|---|---|---|
| 3-11 | 2-11, 17:00 | MEDIA | Partido 3-10 FPS (media 5); salidas y foto 3-6; menú 28; **GPU al 100 %, CPU al 0 %**; 2,8 h de partida, 36 % de batería | [D: `PRUEBA_DUENO_MOVIL_2026-11-03.md`] |
| ~4-11 | posterior | MÍNIMA | Partido 30 FPS; menú 60 | [D: `COMPARATIVA_PES2020.md` §0, «dato del dueño, 11-11»] |
| después | — | — | **sin medir** | [D: `PLAN_GENERAL.md`, «PENDIENTES DE LA SESIÓN DE RENDIMIENTO», punto 5] |

### 4.6.2 Cambios posteriores que no se han medido en el teléfono

Entre el 4-11 y el 16-11 entraron, al menos: MSAA apagado en MÍNIMA (−70 % relativo en el contenedor), resolución 3D automática en el móvil (−23 a −31 %), entorno exterior tapado, HUD del partido de 95 a 40 llamadas, modo rendimiento por defecto (≈ −24 % relativo), 3D al 40 % en ULTRA BAJA, siluetas de jugadores lejanos, tope de 90 FPS y extensión nativa para Android; el público 2D, que en el contenedor quita un 40 % de triángulos, existe como prototipo apagado [D: `rendimiento_120fps.md`; `rendimiento_movil_2026-11-10.md`; `INFORME_SESION_2026-11-15.md`; `CLAUDE.md`, orden 36]. También entraron cambios que pueden empeorar el teléfono: la gala 3D de La Ruta fuerza escala 2,0, MSAA 8x, SSAO y sombras sea cual sea la calidad (F-04, sin decisión) y dejaba el atlas de sombras global en 4096 hasta el arreglo de V-01 del 16-11 [D: cap. 5 F-04; cap. 7 V-01].

Las reducciones relativas del contenedor no se pueden multiplicar entre sí ni trasladar al teléfono: el proyecto lo advierte en cada tabla («los porcentajes son de llvmpipe») [D]. Con la última cifra real en 30 FPS, alcanzar 60 exige reducir el fotograma a la mitad; es plausible que lo aplicado lo consiga, pero no está demostrado [E].

### 4.6.3 Por qué falta la medición

El proyecto tiene la herramienta (prueba integrada de seis minutos que copia el informe al portapapeles, con FPS medio, percentil 1, peor fotograma, caída por calor, llamadas, triángulos y memoria) y una guía de prueba de 30-40 minutos para el dueño [D: `rendimiento_120fps.md`, «Benchmark dentro del juego»; `GUIA_PRUEBA_TELEFONO_2026-11-11.md`]. La medición depende del tiempo del dueño, que es el recurso más escaso del proyecto. El resumen ejecutivo la sitúa entre las decisiones que «desbloquean todo lo demás» [D: `PLAN_GENERAL.md`, «ESTADO AL 15-11»].

---

## 4.7 Comparación con objetivos y umbrales

| Indicador | Objetivo | Medido | Cumple | Comentario |
|---|---|---|---|---|
| ULTRA, laptop | ≥ 30 FPS (dueño, 15-11) | ~39-41 | Sí | Con 3D al 60 %; «en frío» |
| ULTRA, laptop | 40 FPS («ULTRA ALTA 40») | ~39-41 | En el límite | Dentro del ruido |
| ULTRA BAJA, laptop | ≥ 100 FPS (dueño, 15-11) | ~99 (mediana) a ~100-107 | En el límite | El ruido (±15) es mayor que el margen |
| ULTRA BAJA, laptop | 150 FPS (15-11) | ~100-107 | No | Suelo de ~10 ms; no alcanzable con lo medido |
| Equipo modesto | ≥ 120 FPS (orden 19) | ~100-107 en la laptop | No | La laptop es un equipo modesto típico (i3-N300, UHD) |
| Teléfono, partido | 60 FPS (orden 22) | 30 (~4-11) | No (última cifra) | Sin medir desde entonces |
| Latencia de extremo a extremo | ≤ 100 ms, alarma > 140 ms (I1 del cap. 2) [F 33][F 35] | no medida | — | El fallo M6-01 (entrada leída dentro del paso fijo) afectaba precisamente a la respuesta a 30 y 120 FPS; arreglado el 16-11 sin medir su efecto |
| Llamadas de dibujo en ULTRA BAJA | < 130 (diseño del 6-11) | 147 (laptop) | No | Cerca |

Dos observaciones.

**Primera: los objetivos se han movido más que las mediciones.** Entre el 2-11 y el 15-11 el objetivo de la laptop pasó de 120 a 100 y luego a 150 FPS en ULTRA BAJA, y de 30 a 40 en ULTRA. El capítulo 2 no ofrece fundamento externo para ninguna cifra concreta de FPS; sí lo ofrece para la latencia. Se recomienda sustituir los objetivos de FPS sueltos por un **presupuesto de latencia** (≤ 100 ms de extremo a extremo en la laptop y en el teléfono, con alarma a 140 ms) más un **suelo de no regresión** de FPS (ULTRA ≥ 38 y ULTRA BAJA ≥ 95 en la laptop, como propone el resumen ejecutivo), y medir ambos con el protocolo de §4.9.

**Segunda: el cuello de botella es distinto en cada dispositivo.** En la laptop limita la CPU y la presentación (GPU a 4-6 ms de 10). En el teléfono, el 3-11, limitaba la GPU (100 % frente a 0 % de CPU). Las palancas eficaces son, por tanto, opuestas: en la laptop, reducir trabajo por nodo y por fotograma del motor gráfico; en el teléfono, reducir relleno de píxeles (resolución, MSAA, efectos de pantalla completa, transparencias del público). Optimizar con la laptop como única referencia puede dejar intacto el problema del teléfono.

---

## 4.8 Qué falta medir

| # | Qué | Dónde | Por qué | Instrumento existente |
|---|---|---|---|---|
| 1 | FPS medio, percentil 1 y peor fotograma del partido en MÍNIMA, BAJA y MEDIA | Teléfono del dueño | Última cifra del ~4-11; doce cambios sin verificar | Prueba integrada (`--medir` o Ajustes) |
| 2 | Caída por calor (primer tercio frente al último) | Teléfono y laptop | La laptop ya muestra caída; el teléfono probablemente más | Prueba larga (`caida_pct`) |
| 3 | Latencia de extremo a extremo | Teléfono (táctil y mando) y laptop (mando) | Única magnitud con umbrales en la literatura | No existe; §4.9.3 |
| 4 | `probar_nativo` en Windows real y en Android | PC con Windows y teléfono | Riesgo de libm distinta; binario Android sin probar | `probar_nativo.tscn` [D: `PASO_CPP_PLAN.md` §2j] |
| 5 | Export Web en el navegador del dueño | PC y teléfono | wasm32 con extensión probado solo en Chromium con SwiftShader | Export Web [D: §2i] |
| 6 | Gala 3D de La Ruta | Teléfono | Calidad forzada (F-04): riesgo de segundos por fotograma o falta de memoria | Prueba de la gala con `GALA_PRUEBA=1` propuesta en cap. 5 |
| 7 | Memoria máxima del proceso | Teléfono de 4 GB | En el contenedor, ALTO con Forward+ superó 4 GB [D: `rendimiento_120fps.md`] | Prueba integrada |
| 8 | Tiempo hasta jugar (arranque y apertura del estadio) | Teléfono | Medido solo en el contenedor | `medir_apertura.tscn` [D] |
| 9 | Público 2D frente a 3D | Teléfono | En la laptop no cambia el fotograma; en una GPU limitada debería | `PUBLICO_2D=1` |
| 10 | Batería por hora de partido | Teléfono | 36 % en 2,8 h el 3-11 [D] | Sistema operativo |

---

## 4.9 Protocolo de medición propuesto

### 4.9.1 Principios

1. **Mismo build, mismos datos.** Un único export de publicación (no de depuración) por plataforma, con la extensión nativa, identificado por su commit. Se descarta cualquier medición hecha con varias sesiones de Godot abiertas.
2. **Tres clubes de tres países.** Por la regla del dueño (orden 34), cada escena se mide con tres partidos de clubes de países distintos, rotando de una campaña a otra.
3. **Condiciones controladas.** Teléfono con batería por encima del 50 % y sin cargar, brillo fijo, sin otras aplicaciones, diez minutos de reposo antes; laptop enchufada, en el mismo perfil de energía, sin otros procesos pesados, diez minutos de reposo antes de cada serie.
4. **Repetición y estadística robusta.** Cinco repeticiones por condición; se informa la mediana y el rango intercuartílico de FPS medio, percentil 1 y peor fotograma. Con un ruido observado de ±15 FPS en la laptop [D], un cambio se considera mejora solo si las medianas difieren más que la suma de los rangos intercuartílicos, o si una prueba no paramétrica (Mann-Whitney) da p < 0,05 con las cinco muestras por lado [E: criterio propuesto].
5. **Registro.** Cada campaña deja un informe (`user://mediciones/medicion_<fecha>.json`, que ya genera el juego) y una línea en `docs/04_auditorias/rendimiento_*.md` con commit, dispositivo, condición y resultado.

### 4.9.2 Escenas y duración

| Escena | Duración | Calidades | Notas |
|---|---|---|---|
| Menú principal | 60 s | MÍNIMA | con y sin ahorro de menús |
| Club a pie | 60 s | MÍNIMA | interiores |
| Partido, balón en el centro del campo | 60 s | MÍNIMA, BAJA, MEDIA | cámara de TV |
| Partido, ataque con muchos jugadores cerca del área | 60 s | MÍNIMA | peor caso de geometría |
| Repetición y celebración | 30 s | MÍNIMA | picos |
| Gala 3D de un premio de La Ruta | 1 gala | la elegida | solo tras decidir F-04 |
| Prueba integrada larga | ~6 min | MÍNIMA | da `caida_pct` |

### 4.9.3 Latencia de extremo a extremo

El juego no puede medir por sí mismo el tiempo hasta que la pantalla emite luz. Se propone un método externo de bajo coste:

1. Grabar con una segunda cámara a alta velocidad (240 imágenes por segundo, disponible en muchos teléfonos) el mando o el dedo y la pantalla en el mismo plano.
2. Repetir 20 veces una acción con respuesta visual inmediata y sin ambigüedad: cambiar de jugador (el indicador salta) y pase (el balón sale del pie).
3. Contar imágenes entre el contacto (botón hundido o dedo en el cristal) y el primer cambio visible; a 240 imágenes por segundo, cada imagen son 4,2 ms.
4. Informar mediana y percentil 90 por acción, dispositivo y calidad.

Objetivo: mediana ≤ 100 ms y percentil 90 ≤ 140 ms (capítulo 2, I1) [F 33][F 35]. Para separar las causas, el juego puede registrar a la vez las marcas internas (pulsación recibida, paso del motor que la consume, primer fotograma con el cambio), de modo que la diferencia con la medida externa sea la cadena de presentación y la pantalla.

### 4.9.4 Puerta de no regresión

Mientras no haya mediciones del teléfono, la laptop actúa como puerta: ningún cambio visual entra si baja ULTRA de 38 o ULTRA BAJA de 95 FPS con el protocolo anterior (tres clubes, cinco repeticiones, medianas) [D: `INFORME_AAA_2026-11-16.md` §6.4]. Cuando exista una serie del teléfono, se añade su puerta: el partido en MÍNIMA no baja de la mediana medida menos un 10 % [E].

---

## 4.10 Amenazas a la validez

Todas las cifras absolutas proceden de una sola laptop (representativa de un equipo modesto actual, no de los Pentium con 4 GB DDR3 de la orden 19), que se calienta y cuyas cifras caen; las tablas mezclan fechas del 3-11 al 16-11, entre las que cambiaron el motor, la calidad y la escena; los porcentajes del contenedor reflejan un rasterizador por software y su correspondencia con una GPU de teléfono es cualitativa; y la cifra del ~4-11 es una comunicación oral del dueño, no un informe de la prueba integrada.

---

## 4.11 Conclusiones

1. **En la laptop, los objetivos del 15-11 se cumplen en el límite**: ULTRA ~39-41 FPS y ULTRA BAJA ~100-107 FPS [D]. ULTRA es una calidad alta reescalada al 60 %.
2. **El fotograma tiene un suelo de unos 10 ms de CPU y presentación** que no depende de los jugadores, las animaciones ni el entorno [D]. Con lo medido, 120 o 150 FPS en ULTRA BAJA no son alcanzables en ese equipo; el objetivo debe revisarse o atacarse en el motor gráfico, no en el motor del partido.
3. **La extensión C++ ha llevado el motor del partido a ~1 ms por fotograma** y ha reducido a la mitad la semana del mundo [D]; para los FPS de la laptop ya no es la palanca.
4. **El teléfono es la mayor incógnita del proyecto**: la última cifra (30 FPS en MÍNIMA, ~4-11) es anterior a una docena de cambios y nadie la ha repetido. Como el cuello del teléfono era la GPU y el de la laptop es la CPU, optimizar solo con la laptop puede no servir al teléfono.
5. **Nadie ha medido la latencia de extremo a extremo**, la única magnitud con umbrales experimentales publicados [F 33][F 35]. Se propone medirla con una cámara a 240 imágenes por segundo y fijar como objetivo una mediana de 100 ms y un percentil 90 de 140 ms.
6. Se propone un protocolo de medición (§4.9) con tres clubes de tres países, cinco repeticiones, estadística robusta y una puerta de no regresión.
