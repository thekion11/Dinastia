# Presupuesto de triángulos y llamadas de dibujo del partido (M-338)

Medido el 27-10-2026 con `pruebas/presupuesto_partido.gd` (partido jugable real, 1280×720, saque inicial) con el renderizador **Compatibility (OpenGL3)**, que es el del móvil y la web: el más exigente. El 17-10 se anotó «partido ALTO 0,76 M triáng. / 630 llamadas» con otro método y otra cámara; las cifras de aquí son más altas porque Compatibility cuenta también las pasadas de sombras y porque el estadio ha crecido (accesos, vallas, público) desde entonces. En Forward+ (PC) las llamadas serán otras: repetir con `herramientas/captura.sh` cuando haya GPU. Son los números del **cuadro visible desde la cámara del partido**
(`Viewport.get_render_info`: ya con recorte de visibilidad y niveles de detalle), no los de toda la escena: toda la escena sumaría ~9 M de triángulos.
Cada categoría se mide apagándola y viendo lo que baja del total. El **techo** es lo medido más un 15 %; la prueba falla si algo se pasa.

| Categoría | Qué es | Medido (triáng. / llamadas) | Techo (triáng. / llamadas) |
|---|---|---|---|
| total | todo el cuadro | 2 568 116 / 2 125 | 2 953 334 / 2 444 |
| jugadores | los 22 (con sus niveles de detalle) | 69 481 / 54 | 79 904 / 63 |
| estadio | tribunas, techos, accesos, vallas, porterías… **incluye público y butacas** | 2 406 309 / 208 | 2 767 256 / 240 |
| · publico | personas de la grada (MultiMesh) | 773 834 / 20 | 889 910 / 23 |
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
