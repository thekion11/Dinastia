# Análisis completo de la ciudad (7-11-2026)
Pedido del dueño: «análisis completo de toda la ciudad; ver si hay partes que no sirven y sería más rentable eliminar, y si la ciudad respeta el estilo del juego». **Solo análisis: no se ha cambiado nada del juego.**
Método: `pruebas/analisis_ciudad.tscn` (reparte TODA la geometría construida entre las manzanas de `CiudadExpansion.bloques` según dónde cae; ULTRA BAJA, 2 núcleos, `HW_RAM_MB=12000`), medición del pasto con `pruebas/captura_pasto.tscn` (con y sin `PASTO_DRIVE=0`), capturas Forward+ a 1280×720 con la cámara a pie y la aérea (`capturas_analisis_ciudad/`), y la auditoría visual anterior (`ciudad_26_10.md`, pasadas 1-3 del 4-11).
Aviso: «triángulos» = geometría CONSTRUIDA (suma de instancias), no lo que se dibuja cada fotograma (el recorte por distancia y por cámara descarta casi todo).

## 1. Dónde está el coste (geometría construida: 137,9 M de triángulos)
| Zona | Manzanas | Mallas | Instancias | Triángulos | % |
|---|---|---|---|---|---|
| casas (barrios de casas) | 33 | 1.459 | 10.421 | 66,3 M | 48,1 % |
| parque (5 parques) | 5 | 607 | 36.550 | 27,9 M | 20,2 % |
| comercial | 53 | 2.806 | 16.197 | 12,0 M | 8,7 % |
| río (orillas) | 27 | 393 | 1.624 | 8,2 M | 5,9 % |
| Parque del Lago | 1 | 127 | 6.537 | 5,0 M | 3,6 % |
| torres | 24 | 953 | 2.636 | 2,1 M | 1,5 % |
| pisos | 58 | 1.896 | 28.612 | 1,0 M | 0,7 % |
| industrial | 80 | 1.016 | 3.646 | 1,0 M | 0,7 % |
| casa grande, feria, puerto, estación, gasolineras, desguace, centro comercial, solar, plaza, obra… (≈25 zonas) | ≈30 | <300 c/u | — | **0,9 M en total** | <1 % |
| lejano (relleno del horizonte, 178 manzanas) | 178 | 596 | 1.933 | 0,03 M | 0,0 % |
| Fuera de manzanas (calles, mobiliario, personas, coches, metro…) | — | ≈24.000 | ≈135.000 | ≈12 M | 9 % |

**Hallazgo principal: el 77 % de toda la geometría (≈106 M de triángulos) son DOS mallas, las matas de pasto del Drive** (`mata_1`: 8.256 triángulos, `mata_2`: 6.672, ≈12.000 instancias en manzanas de casas, parques, orillas del río y comercio; 15.749 matas sembradas en total). Se dibujan solo a menos de 42 m (celdas de 24 m), por eso la ciudad a pie sigue en ~580 k triángulos, pero:
- **Medido dentro de un parque (ULTRA BAJA):** con pasto 730 k triángulos / 1.012 llamadas; sin pasto 626 k / 984. Y a la altura de una persona, en el borde de un parque: 246 k frente a 131 k (**+88 % de triángulos**, +24 llamadas). Es lo único del mapa que, por sí solo, pesa como media ciudad, y en un móvil limitado por la GPU (5 FPS, GPU al 100 %) es justo el tipo de coste que duele.
- No tiene ninguna puerta de calidad: se siembra igual en ULTRA BAJA que en ULTRA ALTA (`pasto_ciudad.gd` solo se apaga con `PASTO_DRIVE=0`).
- Opciones, de menos a más visibles: (a) en ULTRA BAJA/BAJA sembrar con una malla de ~300-500 triángulos (mismo aspecto desde 5 m, 94 % menos triángulos); (b) en ULTRA BAJA/BAJA bajar la distancia de 42 a 20 m; (c) en ULTRA BAJA/BAJA no sembrar (sigue el césped plano y las flores). Cambia lo que se ve → **necesita tu OK** (regla «no quitar nada sin decirlo»).

## 2. ¿Qué sobra, qué se puede quitar con ganancia real?
Criterio: quitar solo compensa si ahorra coste medible; si no, quitarlo es perder contenido sin ganar nada.
| Parte | Coste | Veredicto |
|---|---|---|
| **Pasto del Drive en ULTRA BAJA/BAJA** | 77 % de la geometría; +88 % de triángulos en un parque | **SÍ rebajarlo** (opción a, b o c). Es la mayor ganancia de la ciudad. |
| **Flores** (9 por mata, tallo + cabeza) | ≈100 k instancias pequeñas; ya cortadas a 38 m | Dudoso: sumar a la opción c si se apaga el pasto. |
| **Orillas del río** (27 manzanas: pasto + paseo) | 8,2 M, todo pasto | Cae con el pasto; sin él, queda barato. |
| Zonas especiales (hospital, cine, comisaría, bomberos, universidad, escuela, instituto, mercado, gasolineras, cocheras, desguace, granja, feria, puerto, obra, parque solar, villa moderna, plaza, ayuntamiento, estación) | <1 % de la geometría en conjunto; 8-300 mallas cada una | **NO quitar**: no ahorran nada medible. Todas se leen en el mapa aéreo y dan vida/identidad; las que tienen puerta (comercios, `mercado`, `peluches`, `banco`) son jugables. |
| «lejano» (178 manzanas de horizonte) | 30 k triángulos, 1.933 instancias | **NO quitar**: casi gratis y es lo que evita el borde vacío. |
| Parque solar, villa moderna, granja | 6-36 k triángulos | Sin ganancia. Si algún día se recorta contenido, son los candidatos por «aportan poco al juego», no por rendimiento. |
| Lo que sí pesa en OBJETOS (no en triángulos): ~24.000 mallas y ~135.000 instancias fuera de manzanas (calles, aceras, farolas, mobiliario) | el coste de CPU de recorrerlas | Se ataca fundiendo/troceando (trabajo de código puro en curso: `trocear`, `agrupar`, `obstaculos`), no quitando. |

Resumen: **no hay ninguna zona entera que convenga eliminar por rendimiento**; lo rentable es rebajar UN elemento (el pasto) en las calidades bajas.

## 3. ¿Se respeta el estilo del juego?
El estilo del juego es **«maqueta de juguete»**: edificios de bloques de colores sólidos, árboles redondos, gente de pocos polígonos, luz clara. Veredicto: **se respeta en general**, con cuatro desvíos (capturas en `capturas_analisis_ciudad/`):
1. **Suelo fotográfico**: el asfalto de plazas y manzanas vacías es una textura realista agrietada, que choca con edificios planos de color (se ve en `hospital_pie`, `mercado_pie`, `parque_pie`: media pantalla de grietas grises). Es el desvío más visible a pie. Arreglo barato: textura lisa o con ruido suave y más oscuro/claro por zonas (sin coste).
2. **Pasto silvestre fotorrealista** (texturas «verde y naranja» de hierba salvaje, 7-8 mil triángulos) en un mundo de formas simples. En los parques el resultado con flores funciona (`parque_pie`), pero es el elemento más «de otro juego» y además el más caro.
3. **Cajas gigantes sin fachada**: el hospital y el centro comercial (`centro_comercial_aerea`) son un bloque blanco enorme con ventanas negras, sin puerta, rótulo ni marquesina. Los edificios de las manzanas de al lado tienen más detalle que los singulares (que son los que el jugador busca). Ya estaba en la auditoría del 26-10 y sigue pendiente en los servicios.
4. **Ventanas negras opacas**: en `hospital_pie` y `mercado_pie` los cristales son negros planos, mientras que en los edificios de la calle de al lado se ven azules y con reflejo. Parte del aspecto «sin terminar».
Bien resuelto (la vara de medir): parques de barrio, feria, puerto, estación (bóveda y escalinata), paraderos «Red», casas del sur.

## 4. Propuestas (todas esperan tu OK; ninguna aplicada)
| # | Qué | Efecto | Riesgo visual |
|---|---|---|---|
| 1 | Pasto con malla simple en ULTRA BAJA/BAJA (opción a) | −90 % de triángulos del pasto cercano (≈ −100 k por parque a la vista) | casi nulo a distancia de paseo |
| 2 | Textura de suelo más suave (estilo juguete) | 0 de coste; arregla el desvío visual n.º 1 | cambia el aspecto del suelo de TODA la ciudad |
| 3 | Fachada mínima (puerta + rótulo + marquesina) en hospital, centro comercial, comisaría, cine, ayuntamiento | +pocas mallas | aporta, no quita |
| 4 | Cristales azulados en lugar de negros en los singulares | 0 | mejora |
Siguen igual las líneas de código puro que no cambian lo visual (en curso).
