# Auditoría de la configuración móvil (Android y Web) — 10-11-2026, sesión 5

Alcance: `dinastia-godot/project.godot` y `export_presets.cfg`, SIN hacer builds (los hace el dueño). Lo que se pudo medir, se midió (llvmpipe, 3 clubes de 3 países). Aplicado solo lo que es claramente un error: **no hizo falta cambiar nada**; lo demás va a preguntas del dueño.

## Lo que está bien (comprobado)
| Tema | Estado |
|---|---|
| Renderizador por plataforma | `rendering_method="forward_plus"` en escritorio; `.mobile` y `.web` = `gl_compatibility` ✓ (Android y Web corren en Compatibilidad, que es lo medido en los informes). `config/features` dice «GL Compatibility» aunque el método por defecto es Forward+: solo cosmético. |
| Compresión de texturas | `textures/vram_compression/import_etc2_astc=true` ✓ (el que de verdad vale en Android). La opción `vram_texture_compression/for_mobile=true` del preset Android no es una opción de ese preset en Godot 4 (existe en el de Web): casi seguro se ignora, inofensiva. |
| Texturas grandes | Las 3 de ropa `T_Peasant_*` (4096²) y las de `movil_s26` (2252²) ya se importan con `size_limit=1024` y comprimidas ✓. El globo terráqueo (`tierra4k`, `luces4k`, `fronteras4k`, 4096×2048) usa `load()` → comprimidas en GPU, ~5 MB cada una (~14 MB), solo en la pantalla de elegir club. |
| Orientación | `window/handheld/orientation=0` (apaisado) ✓. |
| Escalado de la interfaz | `canvas_items` + `expand` ✓: escala la UI y NO fija la resolución del 3D (eso lo cubre la resolución 3D automática, P1). |
| MSAA / FXAA | No hay global en `project.godot`: lo decide `Calidad` por viewport (sin MSAA en BAJA/MEDIA BAJA, y en MEDIA en Compatibilidad) ✓. |
| «Low processor mode» | No está en `project.godot` a propósito: `AhorroMenu` lo enciende y apaga en caliente (y en MEDIA ahora hay interruptor). |
| Oclusión | `use_occlusion_culling=true` no hace nada en Compatibilidad y la ciudad está apagada: inofensivo. |
| Android | solo `arm64-v8a` ✓, firma activa, `internet`, modo inmersivo; sin Gradle (plantilla precompilada). |
| Web | sin hilos ni extensiones (`thread_support=false`, `extensions_support=false`): no necesita cabeceras especiales; la extensión C++ no existe en Web y el juego usa el gemelo GDScript ✓. |

## Medido: `limits/opengl/max_lights_per_object=24` (defecto de Compatibilidad: 8)
MEDIA 1280×720, `override.cfg` temporal con 24 y con 8 (día y noche, CHI/ESP/ENG): día CHI 444 / 457 ms, ESP 357 / 382, ENG 397 / 407; noche CHI 641 / 630, ESP 518 / 519, ENG 530 / 543 (24 / 8). **Sin diferencia** (ruido, y el 8 no es más rápido): se deja en 24 (la ciudad apagada ya no lo necesita, pero bajarlo no da nada). Nota aparte: **un partido de NOCHE cuesta ~+45 % de fotograma** que uno de día (CHI 444 → 641 ms, llamadas 433 → 743; ESP 357 → 518; ENG 397 → 530): focos, omni y pasadas extra. Es la siguiente cosa a mirar si el móvil va justo de noche.

## Qué está mal o sin decidir (propuestas; nada aplicado)
1. **`bin_nativo/dinastia.gdextension` declara librerías que no existen**: `android.{debug,release}.arm64` y `linux.{debug,release}.arm64` (en `bin_nativo/` solo hay Linux x86_64 y Windows x86_64). Efecto: (a) en Android la extensión NO carga y toda la ganancia de C++ (semana del mundo 786 → ~395 ms) se pierde: queda el gemelo GDScript, que funciona igual; (b) puede dar un aviso o error al exportar/arrancar por no encontrar el `.so`. **Decisión del dueño/CI:** compilar el `.so` de Android arm64 (`herramientas/compilar_nativo.sh`, hace falta NDK) o quitar esas líneas hasta tenerlo. No lo toqué (no sé si la exportación falla o solo avisa; que lo confirme el primer build).
2. **Web: `vram_texture_compression/for_mobile=false`** (solo `for_desktop=true`). En un navegador de móvil las texturas no llevan variante ETC2/ASTC y se descomprimen en GPU (~5× más memoria de vídeo que comprimidas). Propuesta: `for_mobile=true` (el .pck/descarga crece por las variantes ASTC); sin cambio de aspecto. Decide el dueño (tamaño de descarga contra memoria).
3. **Sin tope de FPS** (`Engine.max_fps` sin fijar, vsync por defecto): en una pantalla de 120 Hz el juego intentará 120 (batería y calor). Los FPS los maneja el dueño (CLAUDE.md): se anota, no se toca.
4. **Imágenes fuente en el proyecto que se exportan sin que nadie las cargue**: `assets/logo/alas_fuente.jpg` (1,7 MB), `logo_dinastia_fuente.jpg` y `assets/characters/vrm/` (8,6 MB): ninguna referenciada en código ni escenas. No cuestan memoria (no se cargan) pero sí peso de `.pck`/APK. Propuesta: añadirlas a `exclude_filter`.
5. **Versión de Android**: `version/code=1`, `version/name="1.0"` frente a `config/version="0.9.1"` del proyecto: cosmético, pero hay que subir `version/code` en cada APK nuevo.
6. Globo terráqueo: `size_limit=2048` en las tres imágenes de 4096×2048 ahorraría ~10 MB de GPU en la pantalla de elegir club (las fronteras finas se desdibujarían algo): opcional.
