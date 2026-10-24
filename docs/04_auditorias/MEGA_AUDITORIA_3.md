# MEGA AUDITORÍA 3 — 24-10-2026

Cifras repetibles: `python3 herramientas/auditoria_repo.py` (datos del día en `datos_auditoria_2026-10-24.json`).
Lo que no sale de ahí lo dice la propia línea. Nada de esto es opinión sin medir; lo que es estimación está marcado.

## 1. Resumen
| Área | Estado | Nota |
|---|---|---|
| Código | Sólido y ordenado | 902 scripts (476 del juego, 135.462 líneas), 0 scripts > 450 líneas, todos compilan, banco 1.862 comprobaciones en 0 fallos |
| Pruebas | Buenas, con huecos de módulo | 395 escenas de prueba; 53 sin ninguna mención (candidatas a archivar); sin comparación automática de imágenes |
| Juego | Completo y jugable | 108 pantallas sin error de script; modos, ciudad, estadio, partido con motor real |
| Visual | Fuerte, con deuda de peso | texturas sin comprimir (ver §4) |
| Idiomas | 9 idiomas | 506 frases medidas sin traducir (`docs/05_referencia/textos_sin_traducir.txt`) |
| Plugins/addons | Ninguno | `addons/` vacío, sin `editor_plugins` — nada que auditar |
| Conectores | Solo 2 sirven | GitHub y Google Drive; el resto (Adobe, Canva, Figma, Miro, monday, Spotify…) no se usan o fallan por el proxy |
| Documentos | Reordenados | 32 `.md` (1,3 MB) ahora en jerarquía numerada |
| Repo | Ligero en `main` | 17.720 archivos, 272 en LFS, historial reescrito (803,7 MiB) |

## 2. Código
- Funciones: 6.375; **143 de más de 100 líneas, 21 de más de 200** (la mayor, `Principal._construir`, 403). Son la deuda real: la norma de 450 fue de tamaño de archivo, no de responsabilidad (MEGAPLAN §7.1).
- `_process` definido 60 veces, `_physics_process` 3: revisar los que sondean (panel_objetivos ya pasó a señales).
- 236 señales, 261 `class_name`, 318 `is_instance_valid` (defensivo, bien).
- Marcas: 37 `TODO`, 2 `XXX`. 16 `print` sueltos y 25 `push_error/warning` en código del juego: limpiar los `print`.
- Capas `_pN`: 233 archivos. Legibles con `docs/05_referencia/indice_de_capas.md`; la herencia en cadena es un andamio, no una arquitectura final.
- Fallo conocido: `pruebas/estres_menus.tscn` no termina en headless (sin veredicto si ya pasaba antes).
- Colisiones: cubiertas en el club (`ColisionClub`); **ciudad fuera del club sin revisar**.

## 3. Juego y visual (de ESTADO_MEJORAS, 356 ideas abiertas)
223 pendientes · 115 parciales · 10 sin verificar · 8 del dueño. Por fase del megaplan: F6 pulido 136 (82+31+17+6), F4 personas 56, F3 vida en 3D 42, F1 entrada 36, F0 cimientos 33, F5 club 26, dueño 27. Prioridad: 1 P0, 42 P1, 302 P2, 11 P3. Lista viva: `docs/03_estado/ideas_pendientes.csv`.
Ojo: algunas filas están desactualizadas (p. ej. M-278 cita `principal.gd` de 6.777 líneas, que ya está partido en capas). Hay que reverificar cada fila al tocarla.

## 4. Optimización (medido / estimado)
- Texturas importadas: 3.168; **3.103 sin pérdida (modo 0)**, 65 comprimidas en VRAM. Estimación (no medida en GPU): si todas las imágenes se cargaran sin comprimir serían ≈5,1 GiB de VRAM vs ≈1,3 GiB comprimidas; en juego solo se cargan las usadas, pero las caras reales (≈4.700 imágenes en 4 carpetas) y las de 4096² (`T_Peasant_*`, tierra 4k) dominan.
- Quick wins: comprimir VRAM las `caras_reales_*` y `assets/characters`; bajar a 2048 las 23 imágenes ≥ 2048 px que no lo necesiten.
- Duplicados exactos dentro del juego: 36 grupos, 38 archivos (sobre todo caras reales y `kenney_comercial_extra`). No se borraron: los `.import` los referencian por ruta; hay que reapuntarlos antes.
- Partido en ALTO: 0,76 M tris / 630 llamadas (17-10). FPS en hardware real: **pendiente del dueño** (M-337, P0).
- Lenguaje: todo el juego es GDScript; C++/GDExtension solo si el perfil en hardware real lo pide.

## 5. Idiomas
9 idiomas; `idiomas_extra.json` tiene 2.562 frases en inglés y 64 patrones. 506 frases visibles sin traducir (medidas con `auditar_textos_vistos`). Plan: traducir por lotes y dejar la prueba de paridad exigiendo 0.

## 6. Documentos y ficheros
- Antes: raíz y `dinastia-godot/` con ~40 documentos mezclados (informes, planes hechos, notas). Ahora: `docs/00_INDICE.md` + 7 carpetas numeradas.
- Quitado: salidas y registros, 7 duplicados exactos, carpetas XML de prueba, 476 capturas sin uso (23-10).
- Archivado en `docs/99_archivo/`: planes ya ejecutados (ROADMAP, MEGAPLAN fases 1-6, ETAPAS_FINALES, ESTADIO 2.0, PLAN_DE_RUTA, MAPA_DE_METAS).
- Código y comentarios aún citan nombres viejos (ROADMAP, LEEME, MEGAPLAN…): la tabla de equivalencias está en `docs/00_INDICE.md`.

## 7. Aristas y riesgos
1. CI `export-windows` roto (`cd "Dinastía Godot"` no existe): del dueño.
2. 8 ramas viejas + etiqueta `latest` con historia vieja: las borra el dueño (lista en `docs/06_historial/PENDIENTES_hasta_2026-10-24.md` §0.a).
3. Originales de los packs LFS solo están en GitHub: no tocar LFS.
4. `CLAUDE.md` pesaba 62 KB (se cargaba entero cada sesión): reescrito corto, memoria vieja en `docs/06_historial/`.
5. Respaldo en Drive limitado por el conector (el contenido va dentro de la llamada): solo texto. Binarios → `herramientas/drive_subir.ps1` (rclone), del dueño.

## 8. Qué se hizo en esta auditoría
Jerarquía de docs, limpieza de excedentes, tablero de ideas, método Cascada + V (`docs/01_metodo/METODO.md`), tablero de tareas (`docs/03_estado/TABLERO.md`), memoria corta, respaldo de texto en Drive. Qué queda: ver TABLERO.
