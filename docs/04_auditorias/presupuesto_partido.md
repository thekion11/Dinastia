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

## Rebajas propuestas (NO aplicadas; a pedido del líder, 27-10)
Ordenadas de más barata (menos código y menos riesgo) a más cara. Los ahorros son **estimaciones** hechas con la propia medición y con lo que ya existe en `visor/optimizar*.gd`; al aplicar cada una, la prueba `presupuesto_partido` dirá el ahorro real y se bajan los techos.

| # | Rebaja | Dónde está lo caro | Ahorro estimado | Qué hace falta |
|---|---|---|---|---|
| 1 | **Butacas lejanas con la malla ligera**: llamar en el partido a `Optimizar.butacas_livianas(raiz, true)` (hoy solo la usa la ciudad, `city_builder_p11.gd:216`) para `ButacasCerca` salvo las filas de delante | `ButacasCerca`: 1 405 instancias de 1 944 triángulos = 1,55 M visibles; la malla ligera (`_malla_butaca_lejos`) tiene 84 | **−1,4 M triángulos** con todas ligeras (el total pasa de 2,57 M a ~1,2 M); −1,0 M si se dejan con detalle las 2 primeras filas | Una llamada y decidir las filas de detalle (`filas_detalle` en `stadium_builder_p6.gd`); mirar que el respaldo/clearcoat no se note a distancia de cámara de TV |
| 2 | **Unir las mallas del entorno por material y celda**: `Optimizar.agrupar(entorno)` (ya existe: junta piezas quietas con la misma malla y materiales en un MultiMesh por celda) sobre `EntornoEstadio` | 1 190 mallas sueltas con 127 materiales distintos = 1 724 de las 2 125 llamadas | **−1 000 a −1 400 llamadas** (de 1 724 a unas 300-700, según cuántas piezas compartan malla; las que no, se unen antes con `_mat_unico`) | Una llamada; comprobar que nada del entorno se anima (la función ya salta lo que cuelga de un script o un grupo) |
| 3 | **Distancias de corte del entorno**: `Optimizar.distancias(entorno)` (rango de visibilidad por tamaño; hoy solo en la ciudad) | piezas pequeñas lejanas del entorno que no se ven desde la cámara del partido | −100 a −300 llamadas y ~−10 % de sus triángulos | Una llamada; revisar con la cámara de repetición |
| 4 | **Público más ligero desde la 2.ª fila**: bajar las personas `PersonasCerca` (658 triángulos) a las de nivel medio (`PersonasMedio`) fuera de las primeras filas | 0,77 M triángulos de público | −0,3 a −0,45 M triángulos | Cambiar `filas_detalle`/`filas_medio` por calidad; mirar el aspecto con la cámara real |
| 5 | **Butacas lejanas en un solo MultiMesh con rango de visibilidad** (`ButacasCerca` con `visibility_range_end` ~40 m y su sustituta ligera detrás) en vez de elegirlas al construir | lo que queda de #1 | −0,1 a −0,2 M triángulos más y mejor comportamiento al mover la cámara | Cambio de estructura en `stadium_builder_p6.gd`; es lo más caro y lo que menos aporta si #1 se hace |

Con #1 y #2 el partido bajaría de **2,57 M triángulos / 2 125 llamadas a ~1,2 M / ~900-1 100**, sin tocar a los jugadores (69 k, no son el problema). No se aplica ninguna sin orden: cambian el aspecto de la grada.
