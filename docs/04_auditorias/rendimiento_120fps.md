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
