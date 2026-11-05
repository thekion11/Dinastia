# Inventario de pruebas — 2026-11-05

Generado por `herramientas/inventario_pruebas.py --escribir` (análisis estático del código; los tiempos son los medidos en el contenedor del 5-11). La sección «Gestión» del final es a mano y se conserva al regenerar.

## 1. Resumen

- **1021 scripts de prueba** (961 escenas `.tscn` en `pruebas/`), con ~8063 aserciones; el banco tiene **219 secciones** (`func _probar_*`) en `pruebas/banco/`; `especiales.sh` lanza 270 escenas.
- Reparto por familia (clasificación por nombre y contenido; una prueba puede rozar varias, se cuenta en la primera que encaja):

| familia | scripts | qué cubre |
|---|---|---|
| comunes | 28 | arranque, menús, idiomas, guardado, ajustes, entrada |
| estándar | 351 | reglas, economía, calendario, datos, mundo, partido simulado |
| errores | 33 | límites, absurdos, corrupción, entradas inválidas, ráfagas |
| integración | 69 | recorridos de punta a punta, nativo, escenas completas, móvil |
| visualización | 36 | capturas, texturas, retratos, referencias |
| funciones | 4 | funciones puras de `nucleo/` |
| rendimiento | 20 | triángulos, llamadas, memoria, nodos, caché |
| captura / diagnóstico (sin veredicto) | 480 | escenas que sacan fotos o miden y solo imprimen: sirven a una persona, no al CI |

## 2. Dónde vive cada cosa

- `pruebas/banco.gd` + `pruebas/banco/*.gd` — el BANCO (sin ventana, un proceso, en paralelo por grupos): 219 secciones. Lo corre `banco.sh`.
- `pruebas/ideas/*.tscn` — ideas y auditorías, una escena por prueba (`BaseIdea`): 339. Las que cuelgan de `especiales.sh` son las «especiales».
- `pruebas/bancos/*.tscn` — banco especializado por área (fase 2 de la megarreforma): 16.
- `pruebas/so/` — **pruebas por sistema** (5-11): `BaseSO`, marcador «OK/FALLO nombre [sistema]», `LISTA.txt` (nombre|familia|sistemas|escena|requiere) y lanzador `herramientas/pruebas_so.py`: 33.
- `pruebas/*.tscn` sueltas (`prueba_*`, `auditoria_*`, `probar_*`, `captura_*`, `a4_*`): 569.
- `pruebas/visual/` — 20 pantallas contra referencias JPG (necesita Vulkan). `pruebas/partidas_viejas/` — guardados de versiones viejas. `pruebas/arena/` — arena aislada.

## 3. Dependen del sistema (cuántos scripts)

| dependencia | scripts | riesgo en Windows / Web / Android |
|---|---|---|
| ruta /tmp | 79 | Windows no tiene `/tmp`; usar `user://` o `OS.get_user_data_dir()` |
| xvfb / pantalla | 111 | solo Linux con xvfb; Windows/Android tienen pantalla propia |
| variable de entorno | 218 | Web y Android no tienen variables de entorno: los parámetros no llegan |
| OS.get_name / has_feature | 7 | ya sabe de sistema; revisar que no se SALTE nada |
| ruta absoluta del disco | 50 | Web no tiene disco real; Android sólo la carpeta privada |
| renderizador / Vulkan | 274 | Web/móvil usan Compatibilidad; Forward+ no existe |
| audio | 21 | Web arranca el audio tras un gesto del usuario; Android puede no tener salida en CI |
| hilos | 3 | Web exporta sin hilos por defecto |
| red | 2 | Web no abre sockets TCP; Android pide permiso |
| mayúsculas en nombres de archivo | 26 | Windows/macOS no distinguen mayúsculas, Linux/Android/Web sí |

- **ruta /tmp** (79): `arena/arena.gd`, `arena/arena_metricas.gd`, `captura_adelantar.gd`, `captura_apagon.gd`, `captura_aspecto_clubes.gd`, `captura_banderas_grada.gd`, `captura_bus_interior.gd`, `captura_bus_modelo.gd`, `captura_bus_puerta.gd`, `captura_butacas.gd`, `captura_cabeza_perfil.gd`, `captura_cabina.gd`, `captura_cabina_sola.gd`, `captura_cables.gd` …
- **variable de entorno** (218): `a4_captura_rend.gd`, `a4_mem_recursos.gd`, `a4_rend_luces.gd`, `a4_rend_memoria.gd`, `a4_rend_nodos.gd`, `a4_rend_ui.gd`, `arena/arena.gd`, `arena/arena_metricas.gd`, `auditar_textos_movil.gd`, `auditar_textos_vistos.gd`, `auditoria_biomecanica.gd`, `auditoria_fugas_limite.gd`, `auditoria_partido3d_limite.gd`, `banco.gd` …
- **xvfb / pantalla** (111): `a4_captura_rend.gd`, `a4_rend_luces.gd`, `a4_rend_memoria.gd`, `a4_rend_nodos.gd`, `a4_rend_ui.gd`, `bancos/estadio_3d.gd`, `captura_adelantar.gd`, `captura_apagon.gd`, `captura_biblioteca.gd`, `captura_butacas.gd`, `captura_cabina_sola.gd`, `captura_cables.gd`, `captura_cara_3d.gd`, `captura_caras_reales.gd` …

## 4. Lo débil

- **Sin aserciones** (más de 15 líneas y ninguna comprobación; solo imprimen o miden): 52. `a4_mem_cache.gd`, `a4_mem_recursos.gd`, `a4_rend_luces.gd`, `a4_rend_memoria.gd`, `a4_rend_ui.gd`, `arena/arena.gd`, `arena/arena_camaras.gd`, `arena/arena_metricas.gd`, `auditar_textos_movil.gd`, `auditar_textos_vistos.gd`, `auditoria_biomecanica.gd`, `auditoria_clubes.gd`, `auditoria_datos.gd`, `auditoria_tecnica.gd`, `claude_juega.gd`, `estres_corner.gd`, `estres_menus.gd`, `estres_tirolibre.gd`, `frases_2_0.gd`, `frases_sin_traducir.gd`, `huella_mundo.gd`, `ideas/_pgra_dbg.gd`, `ideas/f1o_video.gd`, `ideas/pani_diag_clips.gd`, `inventario_partido_gpu.gd`
- **Con esperas fijas** (`create_timer(N)`, `delay_msec`) y aserciones: 11 — frágiles según la velocidad de la máquina. `auditoria_fps_malos_limite.gd`, `bancos/arranque.gd`, `ideas/a4_museo_limite.gd`, `ideas/a4_rotulos_perezosos.gd`, `ideas/act_actualizador.gd`, `ideas/aud4_movil_partido.gd`, `ideas/aud4_sonido_perezoso.gd`, `ideas/f0m_nucleo.gd`, `ideas/f1l_idioma.gd`, `ideas/fugas_menus.gd`, `probar_cesped_textura.gd`
- **Con escena pero sin lanzar** (ni en `especiales.sh` ni en un banco): 110. `ideas/_pgra_dbg.gd`, `ideas/cant_estabilidad.gd`, `ideas/car_precalentar.gd`, `ideas/e1_butacas.gd`, `ideas/e2_zancas_pasillos.gd`, `ideas/e3_torre_focos.gd`, `ideas/eco_medicion.gd`, `ideas/eq_crisis_caja.gd`, `ideas/f0_cimientos.gd`, `ideas/f0b_huella.gd`, `ideas/f0e_resolver.gd`, `ideas/f0m_visor_personas.gd`, `ideas/f0m_visor_piezas.gd`, `ideas/f0r_necesidades.gd`, `ideas/f0s_huellas_sonido.gd`, `ideas/f1g_pais.gd`, `ideas/f1o_video.gd`, `ideas/fcp_crear_partida.gd`, `ideas/fnt_recursos.gd`, `ideas/foto_brazos.gd`, `ideas/optA_persona.gd`, `ideas/p1_movimiento_natural.gd`, `ideas/p2_inclinacion.gd`, `ideas/p2_postura.gd`, `ideas/p3_arbitros.gd`, `ideas/p3_banquillo_tour.gd`, `ideas/p3_clips_ual.gd`, `ideas/p3_escaleras.gd`, `ideas/p3_escaparates.gd`, `ideas/p3_grupo.gd`
- **Posibles duplicadas** (mismo código salvo comentarios): 4 grupos. `captura_camisetas_cerca.gd`/`captura_futbolistas_acabado.gd`; `captura_comparar.gd`/`captura_league_carrera.gd`; `estres_corner.gd`/`estres_tirolibre.gd`; `video_jugada_corner.gd`/`video_jugada_tirolibre.gd`
- **Lentas conocidas**: aud4_largo_plazo_ui, textos largos en alemán, paneles más anchos que su hueco (móvil, alemán), paneles más anchos que su hueco (móvil, francés), controles sin foco o sin nombre para el lector (todas las pantallas), sin castellano en alemán, apertura de pantallas (M-287, tope 2 s sin GPU). El bloque «todo» de `especiales.sh` añade ~9 min (recorrido de pantallas, balance a largo plazo, visuales con Vulkan).

## 5. Huecos que cubren las pruebas nuevas (`pruebas/so/`)

Ver `docs/04_auditorias/cobertura_pruebas_2026-11-05.md` (tabla familia × sistema).

## Gestión
- Hecho en esta rama (`sonar/bancos`): 34 pruebas nuevas por sistema (`pruebas/so/`), marcador uniforme, lanzador `pruebas_so.py`, registro en `especiales.sh` (bloque 5d y final de «todo») y banco `pruebas_por_sistema` en `bancos_especiales.py`.
- Pruebas existentes reforzadas: `probar_nativo` (expectativa por sistema, antes exigía la extensión siempre), `err_guardado_danado` cubre la huella MD5 (la mutación «quitar la comprobación de huella» sobrevivía).
- Comprobación de que fallan de verdad (mutación y vuelta atrás): idiomas vacíos, puntos de victoria, Pascua, rango del azar, huella del guardado y `escalar()` — las 6 mutaciones se detectan.
- Pendiente: las ~100 escenas huérfanas con aserciones (ver sección 4) y los «sin aserciones» que imprimen sin veredicto.
