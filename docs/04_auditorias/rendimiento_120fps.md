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

## Menú en MÍNIMA: ahorro de la gráfica (3-11, prueba del dueño: menú a 28 FPS con la GPU al 100 %)
La pantalla central son ~407 llamadas de dibujo (539 elementos visibles, nada en 3D) y se repintaba ENTERA en cada
fotograma: las partículas del fondo («motas», el clima elegido) cambian siempre. `AhorroMenu` (ui/componentes/ahorro_menu.gd),
solo en calidad MÍNIMA y sin 3D a la vista: modo de bajo consumo de Godot (`OS.low_processor_usage_mode`: repinta solo
cuando algo cambia) y las partículas del fondo en pausa (lo único que deja de verse; en MEDIA o más, todo igual).
Medido (`pruebas/zz_medir_menu_gpu.tscn`, xvfb + opengl3, pantalla central quieta 3 s): 50 → 1 fotogramas dibujados.
Al tocar algo repinta al momento. Falta medirlo en el teléfono del dueño.
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

## MEMORIA en MÍNIMO (3-11) — qué la ocupa y qué se bajó
`medir_prologo` (con ventana, opengl3, MÍNIMO) ahora imprime memoria de vídeo (`vram`, texturas, buffers); `TEXTURAS=1` lista las texturas únicas de los materiales con su tamaño y dónde cuelgan; `hw_modesto` da el pico de RAM del proceso.
- Base antes de empezar el prólogo: 576 MB estáticos (autocargas, datos, mundo generado) y 11 MB de vídeo. Tras cargar el prólogo: +455 MB estáticos y +420 MB de vídeo.
- **Hallazgo**: UNA textura de 3745×4096 (78 MB de vídeo + su copia en RAM) era el escudo pintado en el círculo central del campo (`StadiumBuilder`): `Escudo.textura(club, alto)` rasteriza a 4× el alto pedido y se pedían 1024.
  Ahora se piden 256 (1024 px, 114 px/m en un círculo de 9 m), 512 en ULTRA y 128 en MÍNIMO (512 px).
| | Antes | Ahora (MÍNIMO) |
|---|---|---|
| Prólogo: memoria de vídeo | 430 MB (texturas 313) | **275 MB** (texturas 158) |
| Prólogo: texturas únicas estimadas | 205 MB | 128 MB |
| Partido (TV): pico de RAM del proceso (`hw_modesto`, software) | 2 362 MB | **2 152 MB** |
Sin medir / pendiente: el resto de la memoria estática (1,0 GB en el prólogo: mallas del renderizador, nodos, cachés) y el audio sintetizado (`Sonido._sintetizar`, cargado en RAM); lo siguiente más grande por texturas son los dos cuerpos base de 2048² (5 MB cada uno) y ~100 texturas procedurales de 512² (1,3 MB cada una) de gradas, túnel y exterior del estadio.

## MEMORIA en MÍNIMO, 2.ª tanda (3-11)
- **Granos y normales a 256²** (`Texturas._lado`) en MÍNIMO (antes 512²; ULTRA sigue en 1024): los ~100 ruidos procedurales de gradas, túnel, fachadas y suelo ocupan un cuarto, se generan 4× más rápido y se guardan en disco aparte.
  Captura del partido (cámara de TV, 1280×720) idéntica a ojo. Vídeo del partido 169 → **132 MB**; vídeo del prólogo 275 → **216 MB** (texturas 158 → 99). Acumulado desde el 3-11 por la mañana: prólogo 430 → 216 MB (−50 %).
- **Los dos cuerpos base de 2048²** (5 MB cada uno): no se tocan; bajarlos a 1024² solo ahorra ~8 MB y se vería peor de cerca.
- **Qué ocupa los ~750 MB estáticos del menú** (medido con `load()` de un script y `Performance.MEMORY_STATIC`, headless):
  - motor + autocargas: 31 MB → 77 MB tras el primer fotograma (autocargas ≈ 46 MB, sobre todo `idiomas_extra.json` con sus 9 idiomas).
  - **+479 MB: compilar GDScript.** Cargar CUALQUIER script que nombre `Roles`/`Mundo` (p. ej. `cartera_dt.gd`, `roles_p1.gd`, `principal.gd`, `city_builder.gd`) compila de golpe casi todo el proyecto (~900 scripts por las anotaciones de tipo): ~0,5 MB por script, 14 MB solo `anim_futbol` o `anim_quaternius` (tablas `const` de fotogramas clave).
  - los JSON grandes se cargan solo al usarlos: `caras_reales_mallas.json` (9,6 MB de texto, ~85 MB en memoria) al aparecer una cara real.
  - No hay precargas que sobren (`preload` solo se usa 19 veces, todas scripts o shaders pequeños).
  Palancas que quedan (cambios de arquitectura, no se hicieron): desacoplar los tipos `Roles`/`Mundo` en las firmas para que el menú no compile el partido y la ciudad; sacar las tablas `const` de animación a recursos `.res` cargados al entrar al partido.

### Confirmado con scripts precompilados (3-11)
Sin plantillas de exportación en este contenedor, pero `godot --export-pack "Windows"` (con `script_export_mode=2`, tokens binarios, el mismo que usan los presets) produce el `.pck` y se corre con el binario del editor: `godot --main-pack juego.pck --script mem3.gd`.
Resultado: `load(principal.tscn)` = **455 MB** (editor: 509 MB) y el primer fotograma del menú **696 MB** (editor: 751 MB). El coste de compilar GDScript se confirma en el export (~423 MB de los 455); los tokens binarios solo quitan ~55 MB.
Lo de `anim_futbol`/`anim_quaternius` (14 MB cada uno): NO son tablas `const` sino funciones con los fotogramas escritos dentro (el código compilado), así que sacarlas a recursos exige reescribir los constructores de animación
(~2 000 líneas) por ~4 % de los 750 MB: no se hace. El desacoplado de tipos `Roles`/`Mundo`, tampoco (orden de la líder): queda documentado con esta cifra.

### Idiomas bajo demanda (3-11)
`Idiomas` cargaba `idiomas_extra.json` con los 9 idiomas al arrancar (~36-46 MB). Ahora `_asegurar(idioma)` lee solo la tabla del idioma ELEGIDO (setter de `Idiomas.idioma`): en castellano no se carga ninguna; al cambiar se suma la nueva y `origen()` mira solo los ya cargados (un texto solo puede estar en un idioma que se haya cargado). `_asegurar_todos()` para las pruebas y herramientas que recorren los 9.
Menú, primer fotograma (editor, sin ventana): **749 → 713 MB (−36 MB)** en castellano; autocargas 77 → 44 MB. Prueba: `p6_idiomas_perezoso`. En un idioma no castellano el ahorro es de ~30 MB (se carga solo el suyo).

### Caras reales y autocargas (3-11)
- Los JSON de caras reales (`caras_reales_mallas.json` 9,6 MB, `biblioteca_caras`, `reales_lista`, `caras_reales_*`) están en el `exclude_filter` de TODOS los presets: el juego público NO los lleva. Medido en `medir_prologo` (CPU, sin ventana, MÍNIMO) con esos archivos ocultos
  (equivale al build del teléfono): **memoria estática del prólogo 972 MB** frente a 1 199 MB con ellos (en el repo de desarrollo, los datos reales cuestan ~225 MB). El teléfono parte, pues, de ~970 MB estáticos en el prólogo, no de 1,2 GB.
- Autocargas restantes: tras los idiomas bajo demanda quedan ~13 MB sobre el motor (31 → 44 MB al primer fotograma): no hay nada que merezca tocar.
- Estado de la RAM del juego en MÍNIMO (prólogo, estático + vídeo): ~970 MB + 216 MB de vídeo; el grueso, ~420 MB de compilar GDScript (ver `compilacion_menu_2026-11-03.md`).

## MÍNIMO: el entorno del estadio, llamadas por función (3-11, sesión de ciudad)
`medir_partido -- minimo` (TV, opengl3 llvmpipe 640x360): base 453 llamadas. Quitando cada función de `EntornoEstadio.montar` (ENT_SIN temporal): suelos 0 · avenida −2 · jardín −2 · árboles y farolas −15 · **aparcamientos −151** · horizonte −8 · banderas 0.
El impostor del horizonte (un cilindro con la silueta) se probó y se descartó: 492 vs 493 llamadas.
Palanca aplicada en MÍNIMO: de cada 3 coches aparcados se queda 1 (el azar se gasta igual, el resto del entorno sale idéntico): **453 → 361 llamadas**, 502 → 409 objetos, −18 k triángulos. MEDIO+ igual. Captura TV antes/después: `capturas_ciudad_c2/aparcamiento_minimo_tv_{antes,despues}.jpg` (los aparcamientos no salen en la cámara de TV; los coches faltantes solo se notan desde fuera del estadio).

## Ciudad en MÍNIMO: llamadas de dibujo por grupo (3-11, `medir_prologo` GRUPOS=2 / RUTAS=<malla>)
Recién cargada (opengl3 llvmpipe 640x360, MÍNIMO): **2 062 llamadas**, 19 452 nodos. Por tipo (se oculta cada tipo y se resta): Mesh −1 302 · MultiMesh −422 · Label3D −290 (2 553 nodos, ya con alcance ≤50 m) · luces −23 · partículas −32.
- `zonas_vista` ENCENDIDA en MÍNIMA: 2 062 → 2 062 recién cargado y 2 007 vs 2 003 tras caminar 120 m (661 piezas ocultas de 1 617): **sin efecto** (se probó y se dejó apagada).
- Peatones (`PeatonQ`): de 85 cuerpos Superhero solo ~18 están a <150 m del punto de medida; acortar su alcance a 55 m (22 m ojos) no cambió nada (2 062 → 2 062): no son el coste.
- Las sombras ya están apagadas en MÍNIMO; `Optimizar.distancias` (CORTE 180/320/600 m según tamaño) ya está aplicado a la ciudad.
- Grupos con más llamadas por nodo (ocultar el grupo, con solapes entre ellos): Semáforos 15 nodos −111 · carrocerías 49 nodos −132 · maletines 52 nodos −87 · zócalos de edificios 56 −78 · ejes 242 −85 · paraderos 124 −65 · carteles 124 −56 · conos 100 −54 · ruedas 4×44 −55 c/u. Son los candidatos a fundir por material o a MultiMesh; ninguno pasa de ~130 llamadas.
**Corrección (3-11, mismo día):** las cifras por grupo de arriba salieron mal (la ciudad seguía cambiando mientras se medía: cada resta se hacía contra la base del inicio). `medir_prologo` GRUPOS=2 ya mide cada grupo contra su propia base inmediata (y `HIJOS=.` / `HIJOS=<nodo>` / `NOMBRADOS=1` / `ESCENAS=1`). Valores buenos (MÍNIMO, ciudad recién cargada, 2 062 llamadas): MultiMesh sueltos (5 541 nodos) −305 · MeshInstance3D sueltos (1 718) −204 · Tráfico −140 · máquinas expendedoras −52 · semáforos −35 · señales de velocidad −11 · rótulos Label3D −10 (ya limitados) · paraderos −17 · edificios sueltos casi 0.
- PROBADO Y DESCARTADO: fundir los edificios/accesorios sueltos por celda y material (`FundirCiudad`, ~800 escenas): 2 062 → 1 998 llamadas (−64) a cambio de +786 ms de carga, +50 k triángulos (sin corte por LOD) y +20 MB de vídeo. No vale. Los edificios ya costaban poco (el recorte por distancia los deja fuera).
- HECHO: máquina expendedora con materiales compartidos y fundida (18 cajas → 1 malla): −17 llamadas.
- Queda el grueso en el TRÁFICO (−140: ~50 coches con carrocería + 4 ruedas + placas/faros por separado; fundirlos rompería los faros de noche) y en los miles de MultiMesh/Mesh sueltos de la propia ciudad y del estadio. No hay una palanca única; llegar a ≤900 llamadas no es realista sin recortar contenido.

## Recortes de contenido AUTORIZADOS por el dueño (3-11), solo MÍNIMO (media y alta iguales) — medidos uno a uno (`medir_prologo`, opengl3 640x360)
Base (con la expendedora fundida): 2 052 llamadas recién cargada · 19 330 nodos · 39 041 objetos · 943 MB · 217 MB de vídeo.
- (b) SIN detalles de fachada (`EdificiosDet_*`): −85 nodos, −200 objetos, **±0 llamadas** (los MultiMesh por celda ya los recortaba la distancia). **No se aplicó**: quitaba contenido sin ganancia medible.
- (a) Tráfico y peatones del ANILLO a la mitad (`CityBuilder._n_pro` ×0,5 en MÍNIMO): **2 052 → 1 975 llamadas (−77)**, 19 330 → 18 752 nodos (−580), −7 MB de vídeo. Tras caminar 120 m: 1 990 → 1 963.
- (c) Menos peatones de reserva (los 34 de `CiudadExpansion` → 17): 1 975 → 1 973 llamadas, −510 nodos, −4 MB de vídeo. Los peatones lejanos ya no se dibujan (alcance), así que el ahorro es de nodos y memoria, no de llamadas.
Total (a)+(c): 2 052 → 1 973 llamadas (−4 %), nodos −1 090 (−5,6 %), vídeo −11 MB. La meta de ≤900 llamadas sigue sin ser alcanzable solo con recortes: el grueso son los ~5 500 MultiMesh y ~1 700 mallas sueltas de la ciudad y el estadio.

## MultiMesh sueltos de la ciudad en MÍNIMO (4-11): unirlos por (malla, material, celda) — PROBADO Y DESCARTADO
`medir_prologo` MMHIST=1: 5 708 `MultiMeshInstance3D` en la ciudad, 759 combinaciones distintas (malla, material, celda de 160 m, sombra, alcance), 316 con varias; la mayoría con 1-4 instancias (787 con 1, 1 308 con 2, 668 con 3). Se unió (`UnirMultiMesh`, solo los hijos directos sin nombre propio, sin grupo/meta/script): nodos 18 228 → 15 870 (−2 358), objetos 37 701 → 32 974, RAM −10 MB, vídeo igual, **llamadas 1 973 → 1 951 (−22, −1 %)**, triángulos +2 k, a cambio de **+411 ms de carga** (más en un móvil). No compensa: se retiró (el código no queda). Las llamadas de dibujo siguen en lo que sí se ve (estadio, tráfico, mallas sueltas) y no en el número de nodos.

## Memoria antes de la ciudad (4-11-2026, sesión ejecutora; pedido del líder)
Medido con el `.pck` precompilado (`godot --headless --path . --export-pack Windows x.pck` con `script_export_mode=2` y `godot --headless --main-pack x.pck --script mem.gd`: carga `principal.tscn`, la instancia y mide la memoria estática tras 2 fotogramas). Herramienta de inventario: `pruebas/a4_mem_cache.tscn` (qué scripts quedan compilados tras abrir el menú, por carpeta y por tamaño).
| | Carga de la escena | 1.er fotograma | Scripts compilados (dev) |
|---|---|---|---|
| Antes (rama del líder 4-11) | 188 MB | 373 MB | 433 (3.719 KB de fuente) |
| Después | **163 MB** | **352 MB** (−21 MB, −5,6 %) | **387** (3.288 KB) |
Qué se hizo (nada visible cambia; todo se carga al USAR, por `load("res://…")` o `_pantalla_perezosa`):
- `Principal` creaba al instanciarse `PantallaPlantel`, `PantallaFicha`, `PantallaLegado`, `PantallaOpciones`, `PantallaDespacho` y `PantallaElegirClub`: pasan a `_pantalla_perezosa` (mismos nombres de acceso). Plantel, ficha y opciones ya no se crean al arrancar (`avance_semana.gd` usa `_abrir_perezosa.bind(…)`; la señal del mercado es una lambda); legado, despacho y elegir club sí se crean en el primer fotograma (el Inicio y el selector de club los usan).
- `situacion_musical()` (antes en `PantallaOpciones`, la llamaba cada refresco del menú) vive en `AvanceSemana`.
- Modales por ruta: `EscenaDespido`, `PresentacionFichaje` (y con ella `CinematicaFichaje`), `DocumentalTemporada`, `MesaAgenteUI`, `PreguntaPlan`, `Sorteo` (+ `SorteoEscena3D`, ≈ 100 KB), `CelebracionTrofeo`; `PcOficina` se reconoce por `Script.get_global_name()` en vez de nombrarlo.
- Tipos explícitos donde antes se inferían del valor de una pantalla perezosa (`var pal: Dictionary = …`).
- `mem_menu_estadio` comprueba ahora también estas 11 clases (no deben estar en memoria tras abrir el menú). Banco 0 fallos; `prueba_menu_ciudad_pie` 0.
Lo que queda a propósito (el menú lo usa al arrancar): `nucleo/` (186 scripts, 1,9 MB: la partida entera), `Tutorial` (lo usa el panel de objetivos), los kits/camisetas, el retrato 3D del DT, `Legado` (pestaña Inicio). Siguiente corte posible (no hecho): ~25 scripts de `ui/` con 150 KB (`carrera_jugador_ui`, `trofeo_3d`, competiciones) con un punto único `abrir(...)`.
**2.º corte (4-11, misma sesión)**: `VitrinaTrofeos`, `PanelVida`, `ArbolHabilidades`, `PanelMaestrias` (secciones de Legado), `Competicion`, `FichaPorque`, `GraficoEvolucion`, `MapaPais` y `CarreraJugadorUI` (también su cierre en `principal_p9`, solo si ya se cargó) pasan a `load("res://…")`. Precompilado: carga de la escena 163 → **160 MB**, 1.er fotograma 352 → **349 MB** (total del día: 188/373 → 160/349, −28 MB y −24 MB, −6,4 %); scripts compilados 387 → 373. `mem_menu_estadio` vigila también estas 9 clases; banco 0 fallos, `prueba_menu_ciudad_pie`, `aud4_movil_flujo`, `aud4_movil_modales`, `aud4_teclado_solo` y el recorrido de 134 pantallas sin errores. Lo que queda cargado en `ui/` es lo que el menú usa de verdad (`PantallaMenu`, `MenusLaterales`, `PanelObjetivos`, `Hubs`, `FondoAnimado`, `TableroInicio`, fuentes, atajos…); los rendimientos decrecientes (≈3 MB por 9 clases) dicen que el siguiente salto no está en `ui/` sino en `nucleo/` (1,9 MB de fuente: la partida entera, que el menú necesita) o en las texturas y sonidos.
**Recursos tras el 1.er fotograma (4-11, 3.er corte)** — inventario con `pruebas/a4_mem_recursos.tscn` (recursos en caché con su tamaño; con `ESPERA_S=25` mide el estado estable): solo hay 14 recursos de archivo en caché (11 sonidos .ogg de la interfaz, 20 KB como mucho, y 3 iconos); las texturas del menú son procedurales (1 fondo de 5 MB en caché), la música son 6 piezas / 5 MB y la partida entera (290 clubes, 7.250 jugadores) ≈ 47 MB. **Lo único grande eran los sonidos sintetizados: 800 flujos / 42 MB** que un hilo iba haciendo durante los primeros segundos (la estática subía de 385 a 408 MB en 25 s) aunque el menú de gestión solo usa un puñado.
- `Sonido` (`nucleo/sonido.gd`): el hilo de fondo sintetiza solo los 40 `BASICOS` (clics, avisos, dinero, fichajes, silbato…); en cuanto se pide el primer sonido de partido/ciudad/evento (`banco()` lo detecta) o se llama a `Sonido.completar()`, sigue con el catálogo entero. El banco que se genera a demanda es idéntico (mismas recetas, sin `Azar`; la prueba `aud4_sonido_perezoso` compara los bytes de «gol» con una síntesis nueva): **no cambia lo que suena**, solo cuándo se hace. La primera petición sintetiza ese banco al momento (ms, como ya hacía el diseño original) y el resto llega en segundos.
- Medido con el `.pck` precompilado a los 25 s del menú: **381 → 344 MB (−37 MB, −9,7 %)**; Sonido pasa de 42 MB (215 bancos) a 5 MB (40 bancos). Con los dos cortes de scripts, el menú estable baja de ≈ 396 a 344 MB (−13 %).
- Pruebas: banco 0 fallos; `acc_avisos_sonido`, `r5_cache_audio`, `s7_sonidos_sistema`, `sui_grabados`, `mem_menu_estadio` 0; nueva especial `aud4_sonido_perezoso`.
- No tocado: `Musica` (6 piezas, 5 MB: poco, y si se compusieran a demanda la música tardaría ~1 s en sonar la primera vez: eso sí se oiría).

## GPU del partido 3D: inventario por variantes (4-11-2026, A4-PARTIDO-R01; pedido del líder tras el 5 FPS del dueño en su teléfono)
Herramienta: `herramientas/hw_modesto.sh res://pruebas/inventario_partido_gpu.tscn -- medio|minimo` (con `HW_DRIVER=opengl3 HW_RES=1280x720`, 2 núcleos). Cámara de TV, partido corriendo; apaga UNA cosa respecto a la base y mide la mediana de 14 fotogramas de **reloj de pared** (llvmpipe está limitada por relleno de píxeles y vértices, como la GPU de un teléfono: sirve para comparar qué pesa, NO para sacar FPS). Cada variante restaura el estado original (lo que el juego ya tenía oculto sigue oculto); las llamadas y triángulos que salen en algunas filas varían por LOD/recortes dinámicos, el tiempo es lo comparable.
| Variante | MEDIO (base 2.134 ms) | MÍNIMO (base 483 ms, 3D al 50 %) |
|---|---|---|
| **sin MSAA** | **−80 %** | **−70 %** |
| 3D al 50 % / al 35 % | −54 % / −69 % | +1 % / −28 % (ya está al 50 %) |
| sin el entorno exterior del estadio | **−33 %** (hoy se dibuja en MEDIO) | −21 % (ya se tapa solo en MÍNIMO: la variante lo deja visible vs el ocultado automático, medida de referencia) |
| sin sombras de todas las luces | −19 % | −3 % |
| sin ajuste de color (brillo/contraste/saturación) | −9 % | −18 % |
| sin focos (26 OmniLight) | −9 % | −12 % |
| sin butacas / sin hinchas | −8 % / −6 % | −11 % / −18 % |
| sin niebla / cielo plano | −7 % / −6 % | −6 % / −7 % |
| sin rótulos 3D (Label3D) | −7 % | −15 % |
| sin jugadores | −2 % | −5 % |
| tonemap lineal en vez de ACES | +3 % | +6 % (no ayuda) |
Inventario: ≈ 2.100 geometrías visibles en MEDIO (1.000 en MÍNIMO), 853 materiales (602), 125 con transparencia (114), 13-14 shaders propios, 1 luz direccional + 26 OmniLight; MEDIO: MSAA x2, escala 100 %, niebla, ajuste de color, tonemap ACES y sombras del sol; MÍNIMO: sin sombras del sol, escala 50 %, MSAA x2 (hasta hoy).
**Lectura**: lo que más pesa en relleno de píxeles NO son los triángulos sino el **MSAA x2** (en una GPU de móvil sin Tile-resolve en Compatibilidad es ancho de banda de memoria ×2 más una resolución), seguido de la resolución del 3D, el entorno exterior (solo en MEDIO) y las sombras. Ajuste de color, focos, rótulos y niebla pesan 6-18 % cada uno en MÍNIMO (en conjunto casi lo mismo que la mitad del fotograma).
**Aplicado (decisión del dueño, R01)**: **MSAA apagado en MÍNIMO** (`Calidad.aplicar_viewport` y `Calidad.msaa_ui` para las vistas 3D secundarias: retratos, sorteo, casa…). MEDIO, ALTO y ULTRA igual que antes. Coste visual: bordes más dentados (líneas finas del campo lejanas, retratos 3D). La prueba `ideas_p2` (calidad mínima) lo refleja: MÍNIMO sin MSAA, MEDIO conserva x2, `msaa_ui` apagado en MÍNIMO.
**Queda (no hecho, para decidir)**: (1) tapar el entorno exterior también en MEDIO con la cámara dentro del recinto (`EntornoOclusion`, hoy solo MÍNIMO; −33 % en MEDIO, sin cambio visible porque las tribunas lo tapan); (2) en MÍNIMO, ajuste de color y rótulos 3D y focos como escalón extra (−12-18 % cada uno, se vería un cambio de color/rótulos); (3) medir en el teléfono del dueño: nada de esto sustituye al aparato real (los porcentajes son de llvmpipe).

## Sesión 14 (12-11): partido jugable en MÍNIMA (`hw_modesto.sh res://pruebas/medir_partido_jugable.tscn`, opengl3 1280×720)
- Antes/después de lo visual de la sesión 14 (botas, cara, pelo, acciones, aro del portador): 0 llamadas nuevas salvo 1 malla del aro;
  vídeo 197 → 197 MB; llamadas 691 → 679 (instantes distintos: el conteo del partido en marcha baila entre ~430 y ~690).
- Qué pesa (escena congelada, reloj de pared comparativo, ruido ±10 ms): base ~153 ms; interfaz 2D −18 ms (−107 llamadas: 31 controles
  táctiles + 77 HUD); jugadores −12 ms (−91 llamadas); el mundo 3D, el resto (~85 ms), repartido en piezas de 1-18 llamadas (`POR_HIJO=1`).
- Quitado: el fondo negro a pantalla completa detrás del visor 3D (tapado; 1 pasada de pantalla completa por fotograma). Detalle en
  `partido_visual_2026-11-12.md` (bloque 4). Siguiente palanca: el HUD 2D del partido, a medir en el teléfono.
- HUD del partido (12-11, `POR_HUD=1` de `medir_partido_jugable`, mismo instante congelado, MÍNIMA): **95 → 40 llamadas 2D**.
  Mando táctil 31 → 16 (fondos, aros y triangulitos como rectángulos de un atlas generado en código: en Compatibility cada círculo, arco o
  polígono era su propia llamada; y se dibuja por fases: todas las formas, luego contornos, luego textos); estadísticas 32 → 12,
  ficha del jugador 20 → 8 y marcador 12 → 4 (sin la sombra del texto, que partía el lote, en las etiquetas sobre panel oscuro; el aviso
  grande sobre el césped la conserva). Misma información, mismos tamaños de toque (`captura_tactil_movil` y `captura_tactil_partido` en 0).

## Sesión 16, 13-11: pulido de código en `ui/` y `visor/` (sin cambiar comportamiento) — mediciones
Método: microbenchmarks de CPU de GDScript (valen en headless; no son tiempo de fotograma) y recuentos de objetos.
- **Perfil por clase estable** (`medir_partido_jugable` con `CPU=1 REPETIR=12`, base 8,0 ms de proceso por fotograma): lo que pesa son los `AnimationPlayer` (×60, −1,0 ms) y, de nuestros scripts, `ancla_suelo.gd` (×26, −0,36 ms) y `anim_transiciones.gd` (×50, −0,20 ms). Con 1 repetición la misma lectura es ruido (`puerta_animada` dio −2,4, −1,7 y −0,3 ms; con 12, −0,04).
- **Puertas del club** (`PuertaAnimada`, 12): ~11 µs por fotograma en total (`pruebas/micro_puertas.tscn`). Saltar la escritura de `rotation.y` quieta no cambió la medida (9-13 µs) → NO se aplicó.
- **`StadiumBuilder.ocultar_techo_ante`** (cada fotograma): 12 piezas, ~5,7 µs por llamada → no se toca.
- **Fugas al entrar y salir de pantallas** (`pruebas/micro_fugas_pantallas.tscn`, todas las pestañas + competición, 6 rondas): 0 objetos, 0 nodos, 0 huérfanos y 0 recursos de crecimiento tras el calentamiento.
- **Construcción del estadio** (`TIEMPOS=1`): total ≈ 0,8 s; lo mayor, `tunel_edificio_club` 255 ms y de ahí la Enfermería 196 ms = primera carga (compilación) del script `InteriorInstalacion` vía `CargaCiudad.de` (única por sesión, deliberada por la regla de memoria del menú; cada pieza ~1 ms). La marca `pitch_cesped` salía con 6,4-7 s FALSOS (el cronómetro arrancaba en 0 = tiempo desde el arranque del proceso): arreglado (`build_pitch` arranca el cronómetro).
- Funciones idénticas duplicadas (≥ 7 líneas): 9 grupos pequeños (p. ej. `_textura_brillo_panel` ×2, texturas de 4×128 px); sin ganancia que justifique acoplar clases.
- SIGUIENTE: `ancla_suelo.gd` (único script propio con coste visible) con microbenchmark antes/después.
