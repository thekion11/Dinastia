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
2. **Cargar y seguir ≠ seguir sin cargar** (`int_flujo_menu_a_guardado`) — **ARREGLADO el 5-11**: el guardado no incluía la FASE DE GRUPOS de los torneos continentales (`Continental.grupos`, `marcador`, `_de_grupos`): una partida cargada a mitad de temporada perdía los grupos y la tabla, y el azar de esas fechas no se gastaba, así que el futuro cambiaba desde la 2.ª semana. Hallado con una traza del estado del azar por paso de la semana (primer paso distinto: `_semana_continental`). Ahora se guardan como claves opcionales (los guardados viejos abren como antes) y las 4 semanas coinciden.
3. `Actualizador.sistema()` devuelve «escritorio» también en Web/macOS: confirmar que el parche de escritorio sirve ahí. **Pendiente de confirmar** (sesión de plataformas).
4. `probar_nativo` exige la extensión en todos los sistemas; donde no hay binario (Web, macOS, Android sin compilar) fallaría. `int_nativo_por_sistema` ya usa la expectativa propia.

## Mutaciones: cada prueba falla de verdad (5-11, `herramientas/mutaciones_so.py`)

Se rompe a propósito lo que cada prueba vigila, se corre y se deshace. Resultado: **todas detectadas** (las 34 + `est_propiedades_semillas`). Tres pruebas SOBREVIVÍAN a su primera mutación y se reforzaron hasta detectarla. Para repetirlo: `python3 herramientas/mutaciones_so.py [--lentas]`.

| prueba | mutación (lo que se rompe) | resultado |
|---|---|---|
| `com_idiomas_nueve_sin_vacios` | una traducción vacía en el JSON | DETECTADA |
| `com_idiomas_cambio_en_vivo` | t() deja de traducir | DETECTADA |
| `com_guardado_ida_vuelta` | las partidas van a res:// (no escribible) | DETECTADA |
| `com_arranque_autoloads` | desaparece el autoload Registro | DETECTADA |
| `com_entrada_por_sistema` | el toque deja de emular el ratón | DETECTADA (tras reforzarla: sobrevivía) |
| `err_guardado_danado` | se quita la comprobación de la huella MD5 | DETECTADA |
| `err_instantanea_invalida` | se quita el rechazo de guardados sin claves | DETECTADA |
| `err_pck_y_pack_ausentes` | Parches busca otro prefijo | DETECTADA |
| `err_entradas_invalidas` | mayusculas('') ya no es '' | DETECTADA |
| `err_rafaga_entrada` | un error de intérprete al recibir cualquier entrada | DETECTADA |
| `err_poca_memoria` | ante poca memoria la calidad sube en vez de bajar | DETECTADA |
| `est_calendario_liga` | la victoria suma 2 puntos en la tabla | DETECTADA |
| `est_economia_invariantes` | escalar() puede dar 0 | DETECTADA |
| `est_datos_coherencia` | a Argentina le falta su tier económico | DETECTADA |
| `est_datos_tablas_vs_codigo` | el código pide una tabla que no existe | DETECTADA |
| `est_partido_simulado_reglas` | el visitante marca 20 goles de más | DETECTADA |
| `int_nativo_por_sistema` | la extensión C++ no carga aunque debería | DETECTADA |
| `int_paquetes_y_parches` | Parches busca otro prefijo que el actualizador | DETECTADA |
| `int_flujo_menu_a_guardado` | cargar no restaura los grupos del continental (la causa real de la divergencia) | DETECTADA |
| `fun_azar_puro` | ent(a,b) se pasa del rango | DETECTADA |
| `fun_calendario_fechas` | la Pascua se calcula con un día de error | DETECTADA |
| `fun_formato_y_demarcaciones` | los millones se escriben con K | DETECTADA |
| `fun_nativo_datos_aleatorios` | la rampa en GDScript copia mal el canal verde | DETECTADA |
| `int_actualizador_por_sistema` | el actualizador cree que todo es Android | DETECTADA |
| `vis_partido_forward` | la referencia del partido es otra pantalla | DETECTADA |
| `vis_partido_compat` | la referencia del partido es otra pantalla | DETECTADA |
| `vis_menu_pantallas` | la referencia de una pantalla es otra | DETECTADA (tras afinar la tolerancia: sobrevivía) |
| `vis_pantallas_sin_vacios` | cambiar de pestaña no hace nada | DETECTADA |
| `vis_referencias_integras` | dos referencias son la misma imagen | DETECTADA |
| `ren_partido_presupuesto` | el partido dibuja una esfera de 2,9 M de triángulos de más | DETECTADA (mutación hecha el 5-11 en tanda aparte, ~3 min) |
| `ren_menu_y_mundo_memoria` | cada mundo generado retiene 80 MB | DETECTADA |
| `ren_peso_archivos` | un archivo de datos de 131 MB | DETECTADA |
| `ren_sin_tiempo_en_headless` | una prueba afirma sobre los FPS sin pantalla | DETECTADA |
| `est_propiedades_semillas` | la victoria suma 2 puntos en la tabla (en 50 mundos distintos) | DETECTADA |

## Caza de pruebas frágiles (6-11, `herramientas/cazar_fragiles.py`)

Corre cada especial varias veces en limpio, con carga de CPU (2×nproc bucles) y, con `--sucia`, compartiendo la carpeta `user://`. **Examinadas hasta hoy: ~50 de ~340** (6-11 tarde: 27 más de la parte 0/6, solo en limpio, 2 ejecuciones: ninguna frágil; la parte 1/6 con carga de CPU era demasiado lenta y se paró) (22 rápidas de la parte 4/6 del reparto, 2 ejecuciones por modo, y `partidas viejas abren`): **0 frágiles**. No es una garantía: las intermitentes del CI de estos días (`a4_comercios_horario`, `p1_movimiento_natural`, `a4_sirena_movimiento`, `auditoria_vida_global_limite`) no se reproducían con 2 ejecuciones; hacen falta muchas repeticiones (la de vida de la app: 38 en local sin un fallo y 2 en CI). Se examinó a fondo `auditoria_vida_global_limite`: falló en 2 CI sin cambios que la toquen; no se reproduce; la causa no está hallada. Se hizo robusta (espera a la condición en vez de N fotogramas) y, si vuelve a fallar, el log trae el estado (`ESTADO (…)`) y la semilla del mundo.

Otros medios para encontrar dependencias de orden: `ESPECIALES_ORDEN=aleatorio` en `especiales.sh` (cola barajada, semilla impresa, `ESPECIALES_SEMILLA=n` para repetir). Para una ejecución nocturna del CI hace falta tocar el workflow (sesión de plataformas).

## Cobertura por funciones de `nucleo/` (6-11)
Godot 4.7.2 no ofrece cobertura de líneas para GDScript (`godot --help` no tiene opción de cobertura) y no se ha verificado ninguna herramienta de terceros. Alternativa: `herramientas/cobertura_funciones.py` mide qué funciones públicas tienen su nombre en alguna prueba: **83 % (1514 de 1834)**. Informe por archivo: `cobertura_funciones_2026-11-06.md`. Peores: `entrenamiento.gd` (37 %), `club_dentro.gd` y `cantera_p2.gd` (44 %).
