# Banco automático de rendimiento (5-11-2026)

Mide el juego **solo**, sin que nadie toque nada, y deja un CSV con una fila por fotograma. Corre en GitHub Actions (gratis, Godot 4.7.2 oficial)
o en local.

## Piezas

| Archivo | Qué hace |
|---|---|
| `dinastia-godot/pruebas/benchmark/benchmark_manager.gd` | **`BenchmarkManager`**: se añade a cualquier escena (o se usa `benchmark.tscn`). Monta el escenario, espera a que cargue, calienta 2 s, mide `duracion` s (60 en el partido) y cierra con `get_tree().quit()`. Escribe `perf_log.csv`. |
| `…/benchmark_escenarios.gd` | Los escenarios que corren solos: `partido`, `ciudad`, `menu`, `gestion`, `museo`, `minijuego` (y `actual`: no monta nada, mide la escena que lleve el gestor). |
| `dinastia-godot/herramientas/benchmark_matriz.sh` | Un perfil de hardware × escenarios × calidades → un CSV por combinación + resumen. |
| `dinastia-godot/herramientas/benchmark_resumen.py` | Estadística y **diagnóstico** (alertas con topes) de los CSV; compara dos carpetas con `--base`. |
| `.github/workflows/fps_benchmark.yml` | El flujo: `perf_log` (partido 60 s headless), `matriz` (5 perfiles en paralelo), `resumen`. |

## Qué guarda cada fotograma (`perf_log.csv`)

`t, fotograma, fase (carga|calentar|juego), escenario, calidad, fps, fps_inst, ms_fotograma, ms_proceso, ms_fisica_monitor, ms_fisica_medido,
ticks_fisica, ms_motor, pasos_motor, ms_motor_jugador, mem_estatica_mb, mem_pico_mb, llamadas, triangulos, objetos, nodos, vram_mb`

- **Memoria estática**: `OS.get_static_memory_usage()` (y su pico).
- **Los 22 jugadores**: el motor del partido (`MotorJugable.paso`) NO corre en `_physics_process`: `VistaEstadio._paso_motor` lo llama desde `_process`
  a 60 pasos por segundo de juego. Por eso `ui/estadio.gd` apunta el tiempo real de cada paso en `Engine.get_meta(&"us_motor")` (2 llamadas por paso,
  coste despreciable) y el gestor lo lee: `ms_motor` (por fotograma), `pasos_motor` y `ms_motor_jugador` (= `ms_motor` ÷ 22).
- **`_physics_process` de verdad**: dos sondas con prioridad extrema (antes y después de todos los nodos) miden cuánto tardan, juntas, todas las
  físicas de cada fotograma (`ms_fisica_medido`, por `ticks_fisica`); `ms_fisica_monitor` es el monitor del motor, de contraste.
- Las filas de las fases «carga» y «calentar» se guardan (se ve cuánto tarda en montarse) pero el resumen solo cuenta la fase «juego».

## Ejecutarlo

```bash
# Local, el partido de 60 s sin gráfica (lo que corre el flujo para perf_log.csv):
godot --headless --path dinastia-godot res://pruebas/benchmark/benchmark.tscn -- --escenario=partido --calidad=media --salida=perf_log.csv
# Una matriz entera de un perfil (necesita xvfb-run salvo «headless»):
dinastia-godot/herramientas/benchmark_matriz.sh modesto /tmp/bench_modesto        # RAPIDO=1 para una pasada corta
python3 dinastia-godot/herramientas/benchmark_resumen.py /tmp/bench_modesto
```
Ajustes del gestor (variable `BENCH_X` o argumento `-- --x=valor`): `escenario`, `duracion`, `calidad` (minima|media|alta|ultra), `salida`, `semilla`,
`adaptativa` (0 por defecto: se mide el coste real de cada calidad), `ligero` («Partido ligero»), `calentar`, `limite`. Poner `DINASTIA_SIN_AUTO=1`
para que el juego no cambie la calidad solo ni escriba `user://grafica.cfg` (la matriz y el flujo ya lo ponen).

En GitHub: **Actions → «Rendimiento (FPS, memoria, motor)» → Run workflow** (modo `completo` o `rapido`). También corre solo los lunes y, en modo rápido,
al tocar el propio banco en un PR.

## Perfiles de hardware (imitados, no reales)

| Perfil | CPU | Gráfica | Resolución |
|---|---|---|---|
| `headless` | 4 núcleos | ninguna (`--headless`) | – |
| `modesto` | 2 núcleos (Pentium) | OpenGL por software (llvmpipe, 2 hilos) | 1366×768 |
| `medio` | 4 núcleos | OpenGL por software | 1920×1080 |
| `movil` | 2 núcleos | OpenGL por software | 1280×576 |
| `vulkan` | 4 núcleos | Forward+ con Vulkan por software (lavapipe); se omite si el equipo no tiene Vulkan | 1920×1080 |

**Límite honesto:** un runner de GitHub no tiene GPU. Los FPS de llvmpipe/lavapipe y en headless (suelo de 6,9 ms por fotograma) **no valen como absolutos**;
sirven para **comparar versiones y calidades**. Lo que sí es comparable entre máquinas: ms del motor por paso, física, memoria, nodos, llamadas de dibujo
y triángulos. Los FPS reales de una Intel UHD o un teléfono solo se miden en ese equipo (pendiente del dueño, `Registro`/orden 19). La RAM de 4 GB no se
limita (un runner no deja crear cgroups): se vigila con el tope de memoria estática pico (2 GB).

## Cómo pedirle el diagnóstico a Claude

Cuando el flujo termine, en una sesión con acceso a este repositorio, escribe:

> **«Lee la última ejecución de “Rendimiento (FPS, memoria, motor)” y dame el diagnóstico de optimización.»**

Claude lista las ejecuciones del flujo (`actions_list`), abre la última, lee del registro de `🩺 resumen y diagnóstico` (el resumen entero se imprime ahí)
las tablas y las alertas y, si hace falta el detalle fotograma a fotograma, descarga el artefacto `perf_log` (o `benchmark-<perfil>`). Si prefieres darle el
CSV tú: descarga el artefacto, súbelo a la sesión y di «analiza este perf_log.csv». Claude corre `benchmark_resumen.py` sobre él, busca los picos
por fotograma, el crecimiento de memoria y la causa en el código, y propone cambios medibles (con `--base antes/ despues/` se comprueba que mejoran).

## Topes del diagnóstico (en `benchmark_resumen.py`)

Motor de los 22: >4 ms por paso (p95 >8 ms) · cuadro p99 >33 ms (con gráfica) · memoria pico >2048 MB · crecimiento >20 MB/min · >1500 llamadas de dibujo ·
>2 M de triángulos. Son avisos para investigar, no suspensos; se ajustan en el script.
