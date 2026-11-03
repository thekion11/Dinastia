# Rendimiento 120 FPS en equipos modestos (2-11-2026)

Objetivo del dueño: mínimo 120 FPS en cualquier dispositivo (4 GB DDR3, Intel UHD/HD, CPU tipo Pentium). Aquí se documenta
el MÉTODO de medición y las cifras antes/después. Lo que no se pueda certificar sin hardware real se dice.

## Método (herramientas/hw_modesto.sh)
`herramientas/hw_modesto.sh res://pruebas/medir_partido.tscn -- medio` imita un equipo modesto en este contenedor:
- CPU: `taskset` a N núcleos (`HW_NUCLEOS`, por defecto 0,1) y `LP_NUM_THREADS` = N (hilos de llvmpipe).
- RAM: cgroup v1 de memoria (`HW_RAM_MB`, 4096 por defecto) si /sys/fs/cgroup/memory es escribible; informa el pico (VmHWM).
- Gráfica: llvmpipe (software). `HW_DRIVER=opengl3` = Compatibilidad (lo que usaría una iGPU vieja); `vulkan` = Forward+.
  `HW_RES` = resolución (por defecto 1366x768). No hay /dev/kvm: QEMU sería emulado y no sirve para FPS.
- Los FPS absolutos de llvmpipe NO valen. Se compara RELATIVO antes/después: ms de CPU por fotograma, llamadas de dibujo,
  triángulos, objetos y memoria (estos cuatro no dependen de la máquina).

## Hallazgos del método
- Forward+ (Vulkan/lavapipe) con el partido 3D se queda colgado tras montar el estadio (CPU parada, RSS fijo) tanto a 2 como a
  4 núcleos; en Compatibilidad (opengl3) avanza. Por eso la línea base se mide en Compatibilidad.
- El partido en ALTO con Forward+ superó los 4 GB de RAM (cgroup lo mató) → candidato a recorte de memoria.
- La salida de Godot a un archivo va con búfer: el script no muestra nada hasta que termina el proceso.

## Línea base (antes) — partido con cámara de TV, MEDIO, Compatibilidad (llvmpipe, 4 núcleos, 640x360)
`pruebas/medir_partido.tscn`: **794 llamadas de dibujo · 1 335 662 triángulos · 848 objetos · 194 MB de vídeo · pico de RAM 3 145 MB**
(fotograma 374 ms en llvmpipe: no comparable entre máquinas). Para 120 FPS en una UHD interesa sobre todo bajar triángulos y llamadas.

## Tanda 1 (2-11) — partido, MEDIO, Compatibilidad (llvmpipe), `medir_partido`
| Variante | Triángulos | Llamadas | Pico RAM |
|---|---|---|---|
| Base | 1 335 662 | 794 | 3 145 MB |
| Butacas cercanas livianas desde el inicio (**aplicado en MEDIO**, `OptimizarGrada.trocear`) | 883 602 | 794 | 2 366 MB |
| + sombra a 160 m en vez de 320 | 882 324 | 793 | 2 371 MB |
| + grada sin sombra propia | 882 389 | 793 | 2 307 MB |
| (referencia) sin sombras de la luz solar | 1 093 563 (sobre base) | 543 | — |

Desglose por grupo (base): butacas 655 k triángulos, sombras 430 k y 319 llamadas, pelo 199 k, hinchas 116 k, jugadores 116 k.
- **Aplicado**: butacas livianas en MEDIO (ALTO/ULTRA no cambian). Cambio visual: las butacas cercanas pierden el respaldo curvo (84 triángulos).
- **Descartado** (sin efecto medido, revertido): acortar la sombra y quitar la sombra de la grada.
- **Pendiente de decidir**: apagar la sombra solar quitaría −251 llamadas (−32 %) pero es quitar un efecto; iría como escalón del modo ligero, dicho al jugador.

## Benchmark dentro del juego (PC y Android) — `nucleo/medicion.gd`
- **Cómo lanzarlo**: PC: `DINASTIA.exe -- --medir` (corto, ~1 min) o `-- --benchmark` (largo: el partido dura 3 min). Cualquier plataforma, **sin argumentos**:
  Ajustes → Rendimiento → «Prueba de rendimiento (unos 6 min)» (modo largo).
- **Qué hace**: apaga el vsync y el tope de FPS durante la prueba (los devuelve al acabar), recorre menú → estadio con la cámara de TV → ciudad y mide, por parte:
  FPS medio, p1 y mínimo, peor fotograma, ms de CPU por fotograma, llamadas de dibujo, triángulos, objetos, memoria estática y de vídeo. En modo largo añade FPS del primer
  tercio frente al último de cada parte (`caida_pct`): sirve para ver si el móvil baja por calor. También guarda GPU, CPU, hilos, RAM, modelo, SO, renderizador, versión y Hz de pantalla.
- **Dónde queda el informe**: `user://mediciones/medicion_<fecha>.txt` y `.json`. Además se copia al portapapeles, se muestra en pantalla con su ruta y un botón «Cerrar» (vuelve al menú) y
  se vuelca a la salida estándar (`MEDICION ...` y `MEDICION_JSON {...}`; en Android sale por `adb logcat -s godot`, pero no hace falta adb: basta pegar el portapapeles).
  En Android la carpeta es la privada de la app (`/data/data/<paquete>/files/...`): por eso el informe está en pantalla y en el portapapeles.
- **Pendiente (necesita dispositivo)**: el tiempo de cada parte se mide con el reloj del juego; en un Vivo Y36 5G (60/90 Hz) queda por ver si el sistema impone un tope de fotogramas aunque el vsync esté apagado.
- **Perfil móvil**: en móvil `CalidadAuto` parte siempre de MEDIO (el renderizador ya es Compatibilidad por `renderer/rendering_method.mobile`), con la calidad adaptativa encendida.
- **Presupuesto**: `herramientas/presupuesto.sh` (en `especiales.sh todo`) corre el benchmark corto con límites de equipo modesto y falla si llamadas, triángulos, memoria o vídeo pasan de `herramientas/presupuesto_benchmark.json`.

### Generar la APK (el dueño maneja los builds)
Actions → «compilar» → Run workflow → `objetivo` = `android` (arm64, depuración o release firmado con `android_release`), `android-armv7` (móviles de 32 bits) o `android-aab` (tienda).
La rama: `ccr-120fps-optimizar` (o la que se una a `main`). El release firmado necesita los secretos `ANDROID_KEYSTORE_BASE64/USER/PASSWORD`. El artefacto se descarga de la propia ejecución.

## Tanda 2 (2-11) — sombras y llamadas (partido, MEDIO, Compatibilidad)
Desglose por nodo (`ARBOL=1`, base 741 llamadas): **EntornoEstadio 333** (527 hijos; ya agrupado con `Optimizar.agrupar`), **sombra solar 205 llamadas / 205 k triángulos**, VallasLed 56 (rótulos `Label3D`; los paneles ya son 2 MultiMesh), arcos y fachada ~19 cada uno.
La luz del partido se configura en `visor/ambience.gd` (no en `Calidad.sol`): MEDIO ya usa 160 m y 2 cascadas.
| Prueba | Llamadas | Triángulos | Veredicto |
|---|---|---|---|
| Cascada ortogonal única (`ambience.gd`) | 784 | 823 k | **Descartada**: −7 % de triángulos pero la iluminación del césped cambia (más clara, menos relieve) |
| Cambiar `Calidad.sol` (distancia/modo) | 793 | 882 k | Sin efecto: esa luz no es la del partido |
Aplicado como último recurso: **escalón 6 de `RendimientoAdaptativo` «sin sombra del sol»** (−205 llamadas): solo si tras SSAO, sombras cortas, butacas, 80 % y 67 % el equipo sigue bajo 40 FPS; el pie del partido lo avisa. Pendiente: EntornoEstadio (333 llamadas), rótulos de las vallas en un atlas.

## Tanda 3 (2-11) — qué hay en `EntornoEstadio` (333 llamadas en vista)
Herramienta: `pruebas/medir_entorno_nodos.tscn` (sin pantalla; recuento por tipo y superficies). Resultado: 445 superficies visibles en 27 tipos; **241 son `MultiMeshInstance3D`** (el agrupado por malla+material+celda de 160 m de `Optimizar.agrupar`), 52 ruedas + 13 coches + 13 carrocerías sueltas, 38 quads, ~65 edificios de ~15 modelos distintos.
Ya está al límite de lo que da agrupar piezas iguales; lo que queda necesita **fusionar mallas distintas** (coches: carrocería+4 ruedas en una malla por coche, ~−50 llamadas; edificios: atlas de materiales) o apagar la sombra solar (−205 llamadas, quita un efecto). Candidatos ordenados por llamadas ahorradas: sombra solar en «ligero» (205, con aviso) > coches fusionados (≈50) > quads/planos (47).
`Optimizar.agrupar` y `distancias` no se tocan: están cubiertos por el banco y por el presupuesto.

## Tanda 4 (2-11) — CPU de la ciudad a pie (`CPU=1 pruebas/medir_ciudad.tscn`, sin pantalla, 2 núcleos)
Base **8,91 ms** por fotograma (35 k nodos). Por clase de script (lo que baja al apagarla): tráfico 2,08 · AnimationPlayer ×204 1,55 · personal_estadio 0,97 · explorador 0,88 · anim_transiciones 0,81 · ciudad_lavado 0,76 · metro 0,64 · semáforos 0,56 · estación 0,50 · mascota 0,47 · vallas LED 0,39.
Aplicado: los peatones a más de 260 m (donde ya no se dibujan) **pausan su AnimationPlayer** (`TraficoCiudad._pausar_anim`, vuelve al acercarse). Resultado: **7,23 ms (−19 %)**. Limitación: medido desde (20, 0, 300), con casi todos los peatones lejos; en el centro la ganancia es menor.
Siguiente por ms: `personal_estadio` (0,97, solo debería correr con el estadio a la vista), `anim_transiciones` (0,81), `ciudad_lavado` (0,76), `metro_ciudad` (0,64), `semaforos` (0,56): candidatos a apagar `_process` cuando no se ven o a tick a 10-20 Hz.

### Tanda 4b (2-11) — tres recortes pequeños, SIN ganancia demostrada
Personal del estadio con la cámara a >260 m (1 de cada 10 fotogramas, tiempo acumulado), `AnimTransiciones` solo con reproductor activo y semáforos reescritos solo cada medio segundo. Base medida después: **7,48 ms** (antes 7,23): dentro del ruido de la medición (~0,5 ms; clases que antes valían 0 salen con −0,5). Se dejan porque son lógicamente correctos, de bajo riesgo (banco ciudad y estadio 0 fallos) y costaban 0,5-1 ms por separado en la primera medición, pero **no se puede afirmar que bajen el tiempo total**. Para medir cambios de menos de 0,5 ms hace falta repetir ≥5 veces y promediar, o un perfilador de scripts en hardware real.

## CORRECCIÓN sobre las tandas 4 y 4b (2-11) — el tiempo de fotograma sin pantalla tiene un SUELO de 6,9 ms
Una escena vacía con `godot --headless` da **6,90 ms por fotograma** (con o sin `--max-fps`, `--disable-vsync`): el bucle sin render espera hasta ese mínimo. Por eso:
- Las cifras de CPU de la ciudad («8,91 → 7,23 → 7,48 ms») NO son coste de scripts puro: mezclan el suelo; el −19 % de la pausa de AnimationPlayer no se puede afirmar con ese método, y el «ruido de ~0,5 ms» tampoco era ruido de scripts. La medición del partido (todo −0,00 ms, base 6,90) estaba totalmente tapada por el suelo.
- Los cambios de la tanda 4/4b (pausa de AnimationPlayer a >260 m, personal lejano, AnimTransiciones, semáforos) siguen siendo correctos (banco 0 fallos) pero **sin ganancia demostrada**.
- Método válido: **CPU del proceso** (`/proc/self/stat`, utime+stime, todos los hilos) por fotograma, como hace `pruebas/medir_cpu_partido.gd`, en máquina SIN otras cargas y con ≥150 fotogramas por muestra (el reloj de /proc va a 10 ms). El primer intento de esa medición salió inservible (otras cargas en paralelo); falta repetirla en limpio.
- Lo que sí es fiable y comparable: triángulos, llamadas, objetos y memoria (tandas 1-3), y el presupuesto del recorrido.

## Nivel gráfico MÍNIMO, la versión ultra ligera dentro del juego (2-11-2026, pedido del dueño)
Un cuarto nivel por debajo de MEDIO (`Calidad.MINIMO = -1`, lo guardado antes sigue valiendo): sin sombras del sol (ciudad y estadio),
suavizado mínimo (MSAA x2: sin él, a 70 %, las líneas lejanas del campo salían entrecortadas), el 3D al 70 % de resolución (la calidad adaptativa parte de ahí), sin reflejos del cielo ni debanding, y grada,
gente, festejos y césped como en MEDIO. Se elige en Ajustes («Mínima») y en la configuración inicial, y `CalidadAuto` lo pone solo la
primera vez en equipos muy débiles (≤ 3 GB de RAM, gráficas de móvil antiguas Mali-400/T, Adreno 3xx/4xx, PowerVR, o gráfica débil con
2 hilos). Mismo juego en todas las plataformas: la versión «ligera» de cada dispositivo es este nivel elegido por detección, no builds aparte.
Medido con `hw_modesto.sh` (partido, lavapipe 2 núcleos, sin tope de RAM; por software, solo para comparar):

| nivel | llamadas | triángulos | VRAM | fotograma (software) | pico RAM |
|---|---|---|---|---|---|
| MEDIO | 830 | 1.002.242 | 356 MB | 809 ms | 7.470 MB |
| MÍNIMO | 568 | 741.502 | 274 MB | 473 ms | 6.327 MB |

Con el motor de compatibilidad (el de los equipos débiles): MEDIO 824 llamadas y 204 MB de vídeo → MÍNIMO 565 y 192 MB. Hoja antes/después con la cámara real del partido: `capturas_ciudad_c2/partido_medio_vs_minimo.jpg` (arriba MEDIO, abajo MÍNIMO).

## R3 (3-11) — ¿streaming/ocultar lo lejano de la ciudad? MEDIDO: casi no sirve
Prólogo en calidad MÍNIMA con motor ligero, Compatibilidad (llvmpipe, 960x540), `pruebas/medir_prologo.tscn` (`CALIDAD=minimo`):
- Recién cargado: **2 170–2 270 llamadas de dibujo · 1,57 M triángulos · 19 550 nodos · 40 400 objetos · 1 026 MB** de memoria estática.
- Reparto de la geometría por distancia al jugador (`MEDIDA zonas`, headless, solo mallas): <200 m 0,91 M · 200-400 m 0,29 M · 400-700 m 2,28 M · 700-1000 m 1,08 M · >1000 m 0,38 M triángulos «potenciales» (cuentan piezas
  que luego el frustum o `limitar_vista` descartan); las multimallas (público, hierba) suman ~34 M potenciales y están a <200 m (el estadio).
- `ZonasVista` (oculta lo GRANDE a más de 640 m con histéresis 560 m; no crea ni destruye nada): **−95 llamadas (−4 %) y 0 % de triángulos** (2 272→2 177 llamadas; 1,574 M→1,573 M).
  Conclusión: el coste de dibujo está CERCA (el estadio, su público y las butacas), no en lo lejano. Queda apagada por defecto (ajuste `zonas_vista`); el streaming real (crear/destruir manzanas) no compensa el riesgo
  (colisiones, agrupado de mallas) para ese 4 %. Siguiente palanca para la GPU del teléfono: el estadio en el prólogo (público como impostores, butacas, sombras) y la resolución del 3D en MÍNIMO.
- Carga: el cuadro más largo del prólogo pasó de 3,4 s a 0,5 s (lo diferido corría en un solo fotograma) y «hasta ver la ciudad» de ~5,3 s a ~2,9 s (servidor, MÍNIMO).

## Estadio en MÍNIMO (3-11) — reparto y resolución 3D
`medir_partido -- minimo` (cámara de TV, opengl3 llvmpipe 640x360, `PARTES=1`): **454 k triángulos · 542 llamadas**. Quitando cada grupo: butacas −103 k tris/−47 llamadas · público (hinchas) −51 k/−32 · jugadores −55 k/−60 ·
pelo −34 k/−27 · resto de multimallas −91 k/−123 · sombras 0 (ya apagadas en MÍNIMO). Las butacas livianas ya se aplican siempre (`OptimizarGrada.trocear` → `butacas_livianas(true)`): no hay más que ganar ahí.
El público entero pesa ~11 % de los triángulos: pasarlo a impostores ahorraría como mucho eso, así que no se tocó.
**Resolución 3D de MÍNIMO 70 % → 50 %** (`Calidad.ESCALA_MINIMO`): mismo partido a 1280x720, fotograma en llvmpipe (limitado por relleno de píxeles) **754 ms → 546 ms (−28 %)**, mismos triángulos y llamadas.
Coste visual: más suave (rótulos de vallas y líneas finas); el HUD 2D no se escala. Se cambia con la constante; veredicto del dueño pendiente.

## R2 tanda 2 (3-11) — MÍNIMO: jugadores, pelo y resolución elegible
- `Viewport.mesh_lod_threshold` = 6 en MÍNIMO (1 en el resto): los jugadores cambian antes a sus mallas de bajo detalle (−55 k → −33 k triángulos medidos al quitarlos).
- Pelo por capas en MÍNIMO: 4 capas cerca y 2 lejos (antes 14 y 4): el pelo pasa de −34 k a ~0 triángulos.
- Total del partido en MÍNIMO (TV, 640x360): **454 k → 376 k triángulos (−17 %)**, mismas llamadas (542).
- La resolución del 3D en MÍNIMO ya es elegible en Ajustes → Dispositivo (35-100 %, por defecto 50 %; se guarda en `grafica/escala_minimo`). Para medir sin tocar Ajustes: variable `ESCALA3D=0.35`.
  Fotograma del mismo partido a 1280x720 (llvmpipe, limitado por relleno): 70 % 754 ms · 50 % 518 ms · 35 % 414 ms.

## R2 tanda 3 (3-11) — el entorno exterior del estadio, tapado en MÍNIMO
Medido con `OCULTAR=EntornoEstadio` (partido, TV, MÍNIMO, 640x360): **560 → 337 llamadas (−40 %), 451 k → 366 k triángulos**, sin cambio visible (las tribunas lo tapan).
`EntornoOclusion` lo oculta solo en MÍNIMO, en estadios cerrados y mientras la cámara está dentro del recinto a menos de 45 m de altura; fuera o más alto vuelve a verse. Captura 1280x720 idéntica (559 → 335 llamadas).
Herramientas nuevas en `medir_partido`: `LISTA_MM=1` (mallas/multimallas por nombre con triángulos potenciales) y más grupos de `PARTES` (el método de apagar-y-comparar sale desordenado a partir de «sombras»: úsalo con `OCULTAR=` para medir una pieza suelta).

## Filas cerradas del plan (3-11)
- **M-339 césped en capas (230 k tris/57 llamadas)**: ya no es así. `CespedCapas` solo existe en ALTO (8 capas) y ULTRA (12) y son capas de UN quad: medido en ALTO (TV) con `OCULTAR=CespedCapas`: −2 k triángulos, 0 llamadas (1 objeto) de 1,66 M; en MEDIO y MÍNIMO no existe.
- **M-356 memoria de la ciudad por celdas / streaming**: medido (apartado R3): ocultar lo lejano quita −4 % de llamadas y 0 % de triángulos; crear/destruir manzanas no compensa su riesgo. Descartado; queda `ZonasVista` (apagada, ajuste `zonas_vista`).
- **M-355 modo batería**: botón «🔋 Modo batería» en Ajustes → Fotogramas: 30 FPS + calidad Mínima de un toque (8 idiomas). Para volver, se eligen otros FPS y otra calidad.

## TABLA FINAL EN MÍNIMO (3-11) — para comparar con el teléfono del dueño
Medido en este servidor SIN GPU (llvmpipe, `opengl3`): las llamadas, triángulos y memoria SÍ se comparan con otras máquinas; los milisegundos NO.
| | Antes (2-11, MEDIA/MÍNIMO viejo) | Ahora (MÍNIMO) |
|---|---|---|
| Partido, cámara de TV: llamadas de dibujo | 794 (MEDIA) / 559 (MÍNIMO) | **336** |
| Partido, cámara de TV: triángulos | 884 k (MEDIA) / 454 k (MÍNIMO) | **365 k** |
| Partido: resolución 3D | 100 % (MEDIA) / 70 % | **50 %** (elegible 35-100 % en Ajustes) |
| Partido: pico de RAM del proceso (`hw_modesto`, software) | 2 366 MB (MEDIA) | 2 362 MB (incluye el renderizador por software) |
| Prólogo a pie: llamadas / triángulos | 2 170-2 270 / 1,57 M | **2 154 / 1,33 M** (con los rótulos a ≤ 45 m) |
| Prólogo: memoria estática | 1 026 MB | 1 031 MB |
| Prólogo: «hasta ver la ciudad» (CPU, sin dibujo) | 7,2 s | **2,9-4,1 s** (según la pasada) |
| Prólogo: cuadro más largo durante la carga | 3,4 s (un solo cuadro con todo lo diferido) | **0,5 s** |
| Ciudad entera diferida: hasta verla | 5,7 s | 1,5 s |
En el teléfono el cuello era la GPU (5 FPS en MEDIA, GPU al 100 %, CPU al 0 %): lo que más ayuda es lo que baja llamadas y relleno de píxeles (entorno tapado −40 % llamadas, 3D al 50 %, LOD de jugadores, pelo simple).
Pendiente de medir en el teléfono: FPS reales, tiempo hasta ver la ciudad y si el prólogo ya carga (C1).
A pie de calle (prólogo, MÍNIMO) lo que más llamadas cuesta: MultiMesh −455, Mesh −1 377 (de 2 279), rótulos Label3D −429 antes del tope de 45 m y −311 después.
