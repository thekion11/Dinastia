# Presupuesto de triángulos y llamadas de dibujo del partido (M-338)

Medido el 27-10-2026 con `pruebas/presupuesto_partido.gd` (partido jugable real, 1280×720, saque inicial) con el renderizador **Compatibility (OpenGL3)**, que es el del móvil y la web: el más exigente. El 17-10 se anotó «partido ALTO 0,76 M triáng. / 630 llamadas» con otro método y otra cámara; las cifras de aquí son más altas porque Compatibility cuenta también las pasadas de sombras y porque el estadio ha crecido (accesos, vallas, público) desde entonces. En Forward+ (PC) las llamadas serán otras: repetir con `herramientas/captura.sh` cuando haya GPU. Son los números del **cuadro visible desde la cámara del partido**
(`Viewport.get_render_info`: ya con recorte de visibilidad y niveles de detalle), no los de toda la escena: toda la escena sumaría ~9 M de triángulos.
Cada categoría se mide apagándola y viendo lo que baja del total. El **techo** es lo medido más un 15 %; la prueba falla si algo se pasa.

| Categoría | Qué es | Medido (triáng. / llamadas) | Techo (triáng. / llamadas) |
|---|---|---|---|
| total | todo el cuadro | 2 568 116 / 2 125 | 2 953 334 / 2 444 |
| jugadores | los 22 (con sus niveles de detalle) | 69 481 / 54 | 79 904 / 63 |
| estadio | tribunas, techos, accesos, vallas, porterías… **incluye público y butacas** | 2 406 309 / 208 | 2 767 256 / 240 |
| · publico | personas de la grada (MultiMesh) | 773 834 / 20 | 889 910 / 27 |
| · butacas | asientos (MultiMesh) | 1 553 616 / 0* | 1 786 659 / 20 |
| entorno | ciudad y edificios de alrededor (`EntornoEstadio`) | 514 771 / 1 724 | 591 987 / 1 983 |
| extras | mascota, camarógrafo, túnel, focos, vallas LED, sombras | 0 | 60 000 / 40 |
| cesped | césped y líneas | 0 | 100 / 8 |
| balon | el balón | 0 | 4 000 / 10 |

\* Las butacas son instancias de un MultiMesh: el contador de llamadas no baja al apagarlas. Los tres últimos miden 0 con la cámara del saque (fuera de cuadro o demasiado pequeños para
verse en el contador): sus techos son holguras, no medidas.

## Lo que dice la medición
- El coste de **triángulos** está en la grada: butacas (60 %) y público (30 %) son el 90 % del estadio. El de **llamadas de dibujo** está en el entorno (1 724 de 2 125): muchas mallas sueltas de edificios.
- Los jugadores cuestan muy poco (69 k triángulos, 54 llamadas): no son el problema.
- Si hay que recortar para móvil: primero butacas y público (más distancia de nivel de detalle lejano), luego fusionar las mallas del entorno (`EntornoEstadio`).

## Cómo se usa
- Con pantalla: `godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/presupuesto_partido.tscn` (con `MEDIR=1` solo imprime la tabla y los techos sugeridos).
- Va en `herramientas/especiales.sh todo` (con `xvfb-run`; ~5 min). Sin pantalla no mide nada.
- Subir un techo exige decir aquí por qué.
- LÍMITES: solo Compatibility; es una cámara (la del saque inicial): una repetición o un córner con otra vista darían otros números; no mide memoria ni coste de sombras.

## Rebajas #1-#3 APLICADAS (28-10, orden del líder)
Medido con el mundo congelado (`Engine.time_scale = 0`, así cada cuadro es el mismo) y cada categoría en pareja (cuadro antes y después de apagarla); `REBAJAS=0` apaga las tres para volver al «antes».

| Categoría | Antes (triáng. / llamadas) | Después (triáng. / llamadas) | Techo nuevo (+15 %) |
|---|---|---|---|
| **total** | 2 569 666 / 2 147 | **1 752 277 / 1 216** (−32 % / −43 %) | 2 015 119 / 1 399 |
| jugadores | 71 425 / 66 | 71 370 / 66 | 82 076 / 76 |
| estadio (incluye lo de abajo) | 2 402 815 / 315 | 1 604 875 / 315 | 1 845 607 / 363 |
| · publico | 769 536 / 46 | 769 536 / 46 | 884 967 / 53 |
| · butacas | 1 486 056 / 4 | 688 116 / 4 | 791 334 / 8 |
| entorno | 157 791 / 1 751 | 138 397 / 820 | 159 157 / 943 |
| extras · cesped · balon | 4 320 · 2 · 0 | 4 320 · 2 · 0 | holguras |

- **#1 butacas** (`StadiumBuilder.butaca_detalle_filas = 2`): solo las 2 primeras filas de la bandeja de abajo llevan la butaca con respaldo curvo (1 944 triángulos); el resto, la ligera (84) con los mismos colores por nivel (la semilla del azar no cambia: nada se mueve ni cambia de color). Ahorro real: **−0,80 M triángulos** (butacas 1,49 → 0,69 M). Menos que lo estimado (−1,4 M) porque la ligera sigue siendo 84 triángulos × todas las instancias.
- **#2 y #3 entorno** (`EntornoEstadio.montar(..., true)` → `Optimizar.agrupar` + `Optimizar.distancias`): **−931 llamadas** (1 751 → 820; lo estimado era −1 000 a −1 400) y −12 % de triángulos del entorno.
- Los jugadores y el público no se tocan. #4 y #5 siguen sin aplicar.
- **FPS de referencia en esta máquina** (llvmpipe por software, sin GPU, 1280×720, Compatibility): **0,70 → 0,75** fotogramas/s. Vale solo como referencia: por software manda el relleno de píxeles y las sombras, no los triángulos. En una GPU de verdad la mejora de triángulos y llamadas pesa mucho más; hay que repetir en el equipo del dueño.
- **Aspecto**: capturas `c52_rebajas_tv_*` (cámara de TV del partido) y `c52_rebajas_pie_de_campo_*` (cámara a pie de campo mirando a la grada, para los planos de repetición laterales, que cambian de plano de una vez a otra): desde la TV no se aprecia diferencia; a pie de campo, el 4,9 % de los píxeles cambia (más de 40/255) por el ruido del césped y de la grada, y se mantienen el respaldo curvo de las dos primeras filas y los colores de butaca por nivel.

## Tanda de rendimiento 1: culling por trozos de la grada (M-345, 28-10)
`OptimizarGrada.trocear` (se llama desde `EntornoEstadio.montar(..., true)`, o sea solo en el partido jugable) parte el MultiMesh de butacas y el de hinchas de cada tribuna en 8 trozos de igual número de instancias a lo largo de su eje largo: cada trozo tiene su caja envolvente y el culling descarta los que quedan fuera de cámara (antes, con un solo rincón a la vista se dibujaba toda la tribuna). Mismo material y sombra; el nombre se conserva con sufijo (`ButacasCerca_3`).

| Categoría (tri / llamadas) | Antes | Después | Techo nuevo |
|---|---|---|---|
| total | 1 752 277 / 1 216 | 1 694 194 / 1 224 | 1 948 324 / 1 408 |
| butacas | 688 116 / 4 | 629 988 / 12 | 724 487 / 14 |
| estadio | 1 604 875 / 315 | 1 546 747 / 323 | 1 778 760 / 372 |

−3,3 % de triángulos con la cámara de TV (que ve casi toda la grada de un lado); +8 llamadas por los trozos. Con cámaras más cercanas a una tribuna (visita, repeticiones a pie de campo) el descarte es mayor. **M-344 (sobredibujo)**: `presupuesto_partido` imprime ahora el brillo medio del modo `overdraw` con y sin grada, pero en Compatibility/llvmpipe se satura (0,85 con todo, 0,83 sin grada): no discrimina. Un oclusor propio de la grada no se aplica sin una medida que lo justifique; queda pendiente medir en GPU real.

## Tanda de rendimiento 2: memoria de vídeo del partido (M-347, 28-10)
Medida con `RenderingServer.get_rendering_info(RENDERING_INFO_VIDEO_MEM_USED)` en `presupuesto_partido` (`TEXTURAS=1` lista además las texturas más pesadas del árbol). Estaba en **603 MB** (texturas 532 MB, búferes 69 MB; la cifra vieja de 539 MB ya había crecido), y el 60 % eran **~60 `NoiseTexture2D` de 1024² (5,3 MB cada una con mipmaps)** de `Texturas._tex_ruido`: una por cada rugosidad, grano y mapa de normales, pedidas de nuevo por cada estadio y edificio.

| Paso | Vídeo total | Texturas |
|---|---|---|
| Antes | 603 MB | 532 MB |
| Granos y rugosidades a 512² (la frecuencia del ruido se duplica para que el grano mida lo mismo) | 467 MB | 398 MB |
| + mismos parámetros = misma textura compartida (caché `_cache_ruido`) | **311 MB** | 242 MB |

−48 %. Los mapas de normales conservan 1024² en calidad ALTO. Techo nuevo en la prueba: `TECHO_VRAM_MB = 380`. Capturas `c54_texturas_{antes,despues}_{tv,repe}.jpg`: el césped y las gradas se ven igual (el grano cambia de píxel pero no de escala). Lo que queda: 128 texturas en el árbol (119 MB leídas de la CPU) y 69 MB de búferes (mallas); medir en GPU real con texturas comprimidas queda para el equipo del dueño.

## Tanda de rendimiento 5: VRAM del partido 312 → 253 MB (H-06/H-07, 2-11)
Desglose (`TEXTURAS=45`): 11 mapas de normales de ruido de 1024² (5,3 MB cada uno) + 13 ruidos de 512², los 9 + 4 mapas de `assets/regalos` (sillón de oficina y torre de focos, sin comprimir: 1 MB cada uno) y los colormaps de Kenney. Cambios: (1) los mapas de normales de ruido bajan a 512² también en ALTO (1024² solo en ULTRA); (2) 65 texturas 3D de `assets/{regalos,peluches,kenney,ciudad,personas,objetos,trofeos,pasto}` pasan de `compress/mode=0` (sin comprimir) a `2` (VRAM comprimida), salvo `Preview.png` (interfaz), las de normales y las máscaras de equipación (son datos). **312 → 253 MB (−19 %)**; techo en la prueba 380 → 300 MB. Capturas `c56_vram_{antes,despues}_{tv,repe}.jpg`: iguales a ojo. Sin tocar: las ~3.400 texturas 2D de interfaz (caras, iconos, banderas: no se cargan juntas en un partido; comprimirlas estropea el borde nítido) y las creadas en ejecución (`ImageTexture` de escudos y uniformes: comprimir en ejecución cuesta tiempo en la primera apertura, ver M-348).

## Rebajas aún propuestas (NO aplicadas)
| # | Rebaja | Ahorro estimado |
|---|---|---|
| 4 | **Público más ligero desde la 2.ª fila**: `PersonasCerca` (658 triángulos) → `PersonasMedio` fuera de las primeras filas (`filas_detalle`/`filas_medio` por calidad) | −0,3 a −0,45 M triángulos |
| 5 | **Butacas lejanas en un solo MultiMesh con `visibility_range`** en vez de elegirlas al construir | −0,1 a −0,2 M y mejor comportamiento al mover la cámara; lo más caro de las tres |

Subir un techo exige decir aquí por qué.

### El balón (3-11)
El techo de `balon` pasó de 50 triángulos / 4 llamadas (una holgura: «mide 0 con la cámara del saque») a **2.760 / 4**. El balón es una `SphereMesh` de 48 × 24 (`visor/balon_3d.gd`; ~2.400 triángulos con las tapas, 1 llamada), y no cambia desde el 30-10. Cuando entra en cuadro cuesta eso; cuando no entra mide 0. Que entre depende del instante del saque y de la velocidad de la máquina: en llvmpipe (6 FPS) entra, también con `XDG_DATA_HOME` vacío (comprobado), y en la CI no, así que con la holgura de 50 la prueba fallaba en unas máquinas y pasaba en otras sin que hubiera cambiado el balón. Sube un techo, así que se dice: no es una regresión, es dejar de suponer que mide 0.
