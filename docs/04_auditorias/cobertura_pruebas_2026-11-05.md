# Cobertura de pruebas por familia y sistema — 5-11-2026 (rama `sonar/bancos`)

Complementa `inventario_pruebas_2026-11-05.md`. Sistemas: **L**inux · **W**indows · **m**acOS · **A**ndroid · **Web**.
«Hoy» = lo que corría antes de esta rama. «Nuevo» = `pruebas/so/` (marcador `OK|FALLO <nombre> [<sistema>]`, lanzador `herramientas/pruebas_so.py`).

| familia | Linux (CI) | Windows | macOS | Android | Web | Nuevo (pruebas) | Huecos |
|---|---|---|---|---|---|---|---|
| comunes | banco + especiales headless | solo exporta | no | solo exporta | solo exporta | `com_idiomas_nueve_sin_vacios`, `com_idiomas_cambio_en_vivo`, `com_guardado_ida_vuelta`, `com_arranque_autoloads`, `com_entrada_por_sistema` (todos los sistemas, cada uno con su expectativa: mayúsculas en rutas, táctil, toque→clic) | Ejecutarlas de verdad en W/A/Web depende del flujo `plataformas.yml` (otra sesión). El clic real no se reparte en `--headless`: se cubre con pantalla (xvfb). |
| estándar | banco (219 secciones) | — | — | — | — | `est_calendario_liga`, `est_economia_invariantes`, `est_datos_coherencia`, `est_datos_tablas_vs_codigo` (solo con código fuente; en export comprueba la inversa), `est_partido_simulado_reglas` | Reglas finas del partido 3D (fuera de juego, penales) siguen solo en el banco. |
| errores | ideas `*_limite`, `sav_fosiles` | — | — | — | — | `err_guardado_danado`, `err_instantanea_invalida` (destapó un fallo real, ver abajo), `err_pck_y_pack_ausentes`, `err_entradas_invalidas`, `err_rafaga_entrada`, `err_poca_memoria` | Memoria baja REAL (cgroup) solo con `hw_modesto.sh`; aquí se simula con la notificación del sistema. Disco lleno no simulable. |
| integración | especiales (`probar_nativo`, `prueba_modos`, `aud4_*`) | nativo .dll no se ejecuta | — | .so arm64 sin probar | sin nativo | `int_nativo_por_sistema` (expectativa por sistema/arquitectura), `int_paquetes_y_parches` (PCKPacker real), `int_flujo_menu_a_guardado`, `int_actualizador_por_sistema` | Menú→ciudad 3D→estadio→partido completo en un solo proceso sigue partido en varias pruebas (memoria). |
| visualización | `visual.sh` (20 pantallas, Forward+) | — | — | — | — | `vis_partido_forward`, `vis_partido_compat` (cámara real + JPG + referencia), `vis_menu_pantallas`, `vis_pantallas_sin_vacios` (estructural, sin GPU), `vis_referencias_integras` | Referencias hechas con llvmpipe/lavapipe: en GPU real hay que regenerarlas por método (`VISUAL=referencias`). Sin referencias para móvil. |
| funciones | secciones sueltas del banco | — | — | — | — | `fun_azar_puro`, `fun_calendario_fechas`, `fun_formato_y_demarcaciones`, `fun_nativo_datos_aleatorios` | Quedan cientos de funciones puras de `nucleo/` sin prueba directa. |
| rendimiento | `presupuesto.sh`, `a4_rend_*`, `hw_modesto.sh` | — | — | — | — | `ren_partido_presupuesto` (con `hw_modesto.sh`), `ren_menu_y_mundo_memoria`, `ren_peso_archivos`, `ren_sin_tiempo_en_headless` (regla «nunca el tiempo de fotograma en headless» hecha prueba) | Presupuestos de móvil son estimados: faltan medidas en teléfono real (orden 22). |

## Fallos reales que destapó

1. **`Partida.desde_instantanea` reventaba con un guardado sin claves imprescindibles** (`semilla`, `anio`, `semana`, `clubes`, `ligas`, `mi_club`; «azar» es opcional: los guardados viejos no lo traen) o con `clubes`/`ligas`/`mi_club` de otro tipo: errores de intérprete y mundo a medias. **Arreglado** (rechaza con `push_error` y devuelve null, como una versión futura).
2. **Cargar y seguir ≠ seguir sin cargar a partir de la 3.ª semana** (`int_flujo_menu_a_guardado`): el azar y la liga coinciden 2 semanas; después algún estado por jugador (forma, partidos jugados) deja de coincidir. Las 2 primeras semanas se vigilan; el resto se informa (`INFO`). **Pendiente** (`PLAN_GENERAL.md`).
3. `Actualizador.sistema()` devuelve «escritorio» también en Web/macOS: confirmar que el parche de escritorio sirve ahí. **Pendiente de confirmar** (sesión de plataformas).
4. `probar_nativo` exige la extensión en todos los sistemas; donde no hay binario (Web, macOS, Android sin compilar) fallaría. `int_nativo_por_sistema` ya usa la expectativa propia.
