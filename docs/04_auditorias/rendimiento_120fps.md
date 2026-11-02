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
