# Informe de la sesión del 15-11-2026 (rendimiento, C++ y público 2D)

Rama de trabajo: `ccr-09090baa-6kiyeq`. A `main` se subió solo el primer bloque (autorizado por el dueño: «sube a Main y registrá», `main` = 09c50a4d). Lo posterior está en la rama, sin PR.

## 1. Encargo
Pasar el código a C++ y «duplicar la velocidad de ejecución» de todo el juego, en todas las plataformas. Después, un público mucho más realista, animado, con planos de cámara al público y más barato que el actual.

## 2. Preparación del entorno (en este contenedor)
- Godot 4.7.2 (bajado de las releases de GitHub) e importación del proyecto; `git lfs pull`.
- Extensión C++ de Linux recompilada con godot-cpp (`e103d34`) y scons; `probar_nativo` termina en «FIN. 0 fallos».
- Web (wasm32), Windows y Android no se recompilaron aquí.

## 3. Velocidad: qué se midió y qué se hizo
**Perfil del motor del partido** (`zz_perfil_motor`, 1.500 pasos): `_ia_defensa` (22 jugadores) ~860 µs, `_ia_equipos` ~650 µs, `_presion` ~130 µs, `_rival_mas_cercano` ~90 µs. El paso entero ronda 1,5 ms, ~9 % de un fotograma a 60 FPS.

**Aplicado**
| Cambio | Resultado | Estado |
|---|---|---|
| `_ia_defensa` lee la posición directa cuando no hay retardo de vista | −3 a −6 % en esa función; huella del motor 2244399493 idéntica; `probar_nativo` 0 fallos | en `main` |
| Modo rendimiento (sin glow ni sombra del sol, césped barato) encendido por defecto también en PC | ≈ −24 % de fotograma relativo según `rendimiento_movil_2026-11-10.md` (llvmpipe, no hardware real); quien ya guardó su elección la conserva | en `main` |
| Prueba «MEDIO conserva las sombras» ajustada para no depender de ese valor | banco «FIN. 0 fallos» | en `main` |
| Comentario de `modo_rendimiento.gd` corregido (ya venía encendido en móvil, orden 36) | solo documentación | en `main` |

**Probado y descartado (con cifras)**
- Caché plana de posiciones de los 22 en `_ia_equipos`: misma huella, paso 1,49-1,52 ms contra 1,46-1,58 sin ella: ruido. Revertida.
- Bajar `LOD_PUBLICO` de 55 a 30 m: 337.432 → 337.618 triángulos en MÍNIMA. Revertido.
- Arrays planos de atributos de jugador (punto 1 del pedido): `Club.once()` 158 µs (nativo 76, ranuras+orden 34, `ajustar_once` 21, `disponibles` 11) × 466 clubes ≈ 74 ms de ~395 ms por semana; el techo de ahorro son ~20 ms (−5 %) y exige invalidar el volcado en ~93 puntos que escriben `atributos`, `forma` o `moral`. No se hace por sí solo.
- Caras y pelo (punto 3): `CaraMalla._cargar` 280 ms una vez (JSON 138 + base64 113 + biblioteca 28), `_datos` 157 µs por cara. El JSON es de caras reales (excluido de builds públicos). Alternativa medida sin C++: mallas ya decodificadas con `var_to_bytes`, 250 → 18-35 ms. PENDIENTE de OK del dueño por el riesgo de que se cuele en un build público.
- Web wasm32 (punto 4): no se intentó (exige `extensions_support`, Emscripten igual al de la plantilla y prueba en navegador).

**Conclusión de los informes del repositorio** (`rendimiento_movil_2026-11-10.md`, `rendimiento_120fps.md`, `PRUEBA_DUENO_MOVIL_2026-11-03.md`): el partido está limitado por relleno de píxeles de la GPU (`fotograma ≈ 0,47·F + 0,53·F·escala²`). Lo que ya duplicó velocidad: sin MSAA (−58 a −69 %), resolución 3D automática en móvil (−23 a −31 %), oclusión del estadio (−43 a −52 % a pie), menú en bajo consumo (−98 % de repintados). Falta una medición real en el móvil/PC del dueño (`-- --medir` o Ajustes → «Prueba de rendimiento»; desde el 3-11 no hay ninguna). Con C++ o cachés de la IA no se duplica nada.

**Palancas de píxeles pendientes de decisión del dueño** (cambian lo visible): 3D al 40 % en MÍNIMA (−36 % de píxeles), siluetas planas de jugadores lejanos (−12 a −23 % de triángulos), sin ajuste de color en MÍNIMA, hinchada de MÍNIMA con menos densidad o impostores (~145 k triángulos, 43 % del partido).

## 4. Registro en el plan
`docs/PLAN_GENERAL.md`: «MÁXIMA PRIORIDAD» (partido simulado de la IA entero en C++ con gemela GDScript, solo anotado, no trabajado), «ESTADO AL 15-11» (hecho, descartes medidos, pendientes) y «PÚBLICO 2D HIPERREALISTA».

## 5. Público: revisión en calidad más baja
Capturas con la cámara de TV (ULTRA BAJA, Compatibilidad, 1280x720; CHI y ESP): el público se lee como ruido de estática en CHI (blanco y negro) y mejor en ESP (colores vivos); rótulos de vallas ilegibles. Causa: 3D al 50 % sin MSAA y figuras diminutas.

## 6. Público 2D: prototipo (apagado por defecto, `PUBLICO_2D=1`)
- `herramientas/hornear_publico_2d.gd`: fotografía las figuras 3D de la hinchada (sin fotos de personas) en 6 clips × 3 cuadros × 12 variantes; 4 pasadas por sprite para sacar la máscara (R = ropa, G = bufanda/raya 1, B = bufanda/raya 2). Salida: `assets/ciudad/publico/publico2d_{albedo,mascara}.png`.
- `visor/hinchada_2d.gdshader` + `visor/publico_2d.gd`: un cuadro plano por hincha (2 triángulos); mismos parámetros de reacción que la hinchada 3D (ola, onda de gol, protesta, «¡uy!», nervios). `hinchada.gdshader` ganó `tiempo_fijo` y `clip_fijo` (en −1 no cambia nada en el juego); `OlaGrada` encuentra también el material 2D.
- Medido (ULTRA BAJA, cámara de TV): CHI 340.395 → 202.655 triángulos (−40 %), 232 → 165 llamadas; ESP 286.608 → 170.812 (−40 %), 198 → 174. No se midieron FPS reales.
- Banco completo «FIN. 0 fallos» antes de subir (commits 35ac86ac y 9f929985).
- Límites actuales: los sprites son bustos de la malla «cerca» de 658 triángulos; la piel sale del atlas (sin `piel_sesgo` por país); sin luz de noche ni cabezas que sigan el balón; mipmaps con posible sangrado entre celdas.

## 7. Sesiones y Drive
- Sesión «Acceso a tu PC» (sesión local del dueño en `C:\Juegos\Dinastia`): el dueño pidió obedecerla. No ha enviado órdenes a esta sesión. Se coordina con ella, pero nada irreversible sin confirmación del dueño. Dijo que subirá 3 commits a `main`: revisar conflictos.
- Drive (`Dinastia_respaldo_2026-10-24` y `referencias_del_dueño`): capturas de FC Mobile y PES 2020, ficha de atributos, 4 vídeos (57-806 MB, no abribles con las herramientas disponibles), modelos (`Realistic+Male`, `Chair.glb`, `stadium_light.blend`, trofeo, césped). No se encontró un ejemplo del público o los planos al público de FC 27.

## 8. Qué sigue (orden propuesto)
1. Mejorar los sprites: hornearlos desde los futbolistas vestidos con pelo y cara, o desde `avatar_regalo` / `persona_realista.glb`, no desde la malla de 658 triángulos.
2. Director de cámara de planos al público (falta grave, roja, gol, ocasión, penal) con figuras 3D solo en ese sector.
3. Carteles y pancartas (atlas de ~24 textos ficticios por idioma).
4. Piel por país, luz de noche, cabezas que siguen el balón.
5. Medir con tres clubes de tres países y dejar capturas antes y después para el veredicto.

## 9. Decisiones y datos que necesito del dueño
- Capturas (o minuto de un vídeo) del público y los planos al público que quiere imitar, guardadas en `referencias_del_dueño`.
- OK para las palancas visibles de píxeles de la sección 3.
- OK para las mallas de caras ya decodificadas (la alternativa de 18-35 ms) con su exclusión en los presets.
- Medición real en su móvil y su PC.
- Confirmar el orden de la sección 8.
