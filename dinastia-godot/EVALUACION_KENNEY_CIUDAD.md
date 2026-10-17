# Evaluación: kits de Kenney para la ciudad 3D y sus interiores (15-10-2026)

Es una evaluación: aquí no se implementa nada. No se tocó ningún script ni escena del
juego. Lo único nuevo es una escena de prueba, `pruebas/muestrario_kenney.tscn/.gd`,
con sus capturas.

**Método.** La ciudad se recorrió con las herramientas que ya existen, todas en
**Forward+**: `captura_paseo` (6 paradas a pie), `captura_entrar` (entrar en el
hospital, un bar y una casa, en tercera y primera persona) y `captura_metro_usable`.
Se midió la caja (AABB) y los triángulos de los **1.025 GLB** (930 de los kits nuevos y
95 de `kenney_roads`) con un script aparte, sin errores de carga. El muestrario monta
cada kit con la escala propuesta junto a referencias de medida real (persona roja de
1,8 m, barra de piso de 3 m, marco de puerta de 2 m y caja azul de coche de 4,5 m) y,
para comparar el estilo, junto a un edificio del kit comercial tal y como lo usa la
ciudad (×5,6).

Todas las capturas citadas están en `pruebas/capturas/` (JPG).

---

## 1. Estado actual de la ciudad (recorrido)

### Lo que se ve bien
- **Zona comercial y del ensanche** (`paseo_5_cruce`, `paseo_6_calle`): las fachadas del
  kit comercial, teñidas con `CityBuilder.tenir`, con rótulos, terrazas con sombrillas,
  placas con el nombre de la calle, guirnaldas y bolardos. Es la parte más «ciudad»,
  aunque el estilo es de dibujo animado.
- **Puente y río** (`paseo_4_puente`): la rampa y la barandilla de piedra se leen bien, y el
  horizonte tiene variedad de torres.
- **Parque** (`paseo_3_parque`): pórtico con nombre, caminos de losa, parterres con flores,
  árboles low-poly coherentes y gente.
- **Entrar en los edificios funciona**: la salida devuelve al jugador a la misma
  posición (`SALIDA … pos_igual=true` en los tres casos), el mobiliario da colisión
  (`círculos=10/16/11`) y hay gente trabajando.

### Lo que se ve mal (por orden de gravedad)
1. **El barrio de casas** (`paseo_2_casas`): las casas son **cajas lisas enormes**
   (15 m de frente y 5-7,5 m de alto; parecen naves), de color pastel tan claro que con
   la exposición del día salen **casi blancas**, con dos o cuatro ventanitas y el tejado
   en forma de prisma. Desde la acera de enfrente no se ve ni la puerta. Es lo peor de
   la ciudad y es justo donde más aporta un kit.
2. **Interiores de cajas y salas demasiado grandes** (`entrar_1_tercera`,
   `entrar_2_primera`, `entrar_0_tercera`): todas las salas miden 20-24 × 14-16 m con
   5-6 m de techo (una vivienda real tiene unos 2,6 m), el mobiliario son prismas de
   color plano (sofá de bloques azules, tele como caja negra de 2,6 m, mesas del bar que
   son cilindros de 1,4 m de diámetro) y los espacios quedan vacíos.
3. **Gente sentada en el aire**: en el hospital los pacientes están **sentados en el
   aire** en la cabecera de las camas, con las piernas por encima del colchón (deberían
   estar tumbados o sentados en el borde), y en la sala de espera un hombre flota
   delante de su silla; en el bar, un cliente parece sentado en el borde de la mesa
   (`entrar_0_tercera`, `entrar_1_tercera`).
4. **Industria y puerto**: naves que son cajas grises con dientes de sierra hechos con
   cajas giradas, contenedores en MultiMesh de cajas y una chimenea de cilindro. Se ve
   al fondo de `paseo_3_parque`.
5. **Luz en Forward+**: (a) las zonas en sombra salen **azules** (la acera y la calzada
   en sombra de `paseo_1_avenida` y `paseo_2_casas`; la textura `Texturas.baldosa` es
   gris neutro, así que es la luz ambiente del cielo, demasiado fuerte y azul donde no
   llega el sol); (b) el asfalto tiene un **brillo especular que quema** a contraluz (abajo
   a la izquierda de `paseo_3`, `paseo_4` y `paseo_6`).
6. **Farolas**: la cabeza es un paralelepípedo amarillo plano (`paseo_4_puente`,
   `paseo_6_calle`). Los brazos curvos de Kenney solo están en las avenidas.
7. **Pasos de cebra** rotos o torcidos en la esquina del puente (`paseo_4_puente`).
8. **Avenida del este** (`paseo_1_avenida`): a la izquierda, una pared lisa azul sin
   detalle tapa medio plano y la torre de la derecha muestra ventanas gigantes. Es la
   torre ya apuntada en ETAPAS_FINALES («ventanas grandes azul cielo»).
9. **Metro** (`metro_2_anden`, `metro_3_dentro`, `metro_6_anden_subterraneo`): funciona
   (calle → andén → tren → túnel), y el coche por dentro tiene proporciones creíbles
   (asientos, barras, puertas). Pero los andenes están **vacíos de gente y de
   mobiliario** (solo arbustos de esfera y un banco); dentro del tren, el cartel del
   andén («…cine») se ve a través de la pared, que deja pasar demasiada luz, y en el
   andén elevado el rótulo de la estación queda cortado detrás del tren. Aquí sirven
   `vending-machine` (arcade ×2,4), `bench` y `trash` (montaña rusa ×2,2) y las papeleras
   del mobiliario urbano; no hace falta el kit `tren` para el coche usable.
10. **El tutorial de la ciudad** sale en todas las capturas (el script no lo cierra) y
   tapa el tercio inferior. Es un problema de la herramienta, no del juego.

---

## 2. Medidas de los kits (AABB del GLB, en unidades del modelo)

| Kit | Referencia medida | Escala propuesta | Resultado |
|---|---|---|---|
| `suburbano` (casas `building-type-*`) | casa 0,74-1,24 de alto | **×5,6** (la del kit comercial) | casas de 7-10 m de frente y 4-8 m de alto (`kenney_exteriores`) |
| `industrial` (`building-a…t`) | nave 0,7-1,9 de alto, 0,9-2,5 de ancho | **×9-10** (a ×5,6 la nave mide 10-14 m: pequeña para una nave) | naves de 18-25 m |
| `industrial/shipping-container-*` | 0,82 de largo | **×7,4** (contenedor de 20 pies, 6,1 m) | — |
| `edificios_modulares` | 1 bloque = 0,62 de alto (un piso); puerta 0,5 | **×4,8** (piso de 3 m, puerta de 2,4 m) | casas de 5-10 m y torres de 12-15 m (`kenney_modulares`) |
| `kit_edificios` | **ya está en metros**: pared 2,4 m, puerta 2,1 m | **×1,0-1,15** (×1,25 deja la puerta en 2,6 m) | — |
| `muebles` | silla 0,47; nevera 0,92; pared 1,29 | **×2,0** (nevera de 1,84 m, mesa de 0,66 m) | proporcionados al lado de la persona de 1,8 m (`kenney_salon`) |
| `mini_mercado`, `mini_arcade` | pared 1,0; empleado 0,72 | **×2,4** (empleado de 1,73 m; estanterías de ~2,1 m) | `kenney_tienda` |
| `comida` | plato 0,89; lata 0,35 | **×0,3** (plato de 27 cm; lata de 10 cm) | se lee bien encima de la barra (`kenney_bar`) |
| `montana_rusa` (puestos, entrada) | puesto 1,4-1,9 de alto | **×2,2** (puesto de 3,1-4,1 m); entrada ×2,5 (6 m) | `kenney_parque` |
| `montana_rusa` (vías, tren) | recta de 4,0; tren 0,62 de alto | ×2,2 para que quepa la gente; **×4** para un looping de 16 m | — |
| `tren` (metro, tranvía) | coche 1,1-1,35 de ancho × **2,4-2,8 de largo** (de juguete) | ancho ×2,2 y **largo ×6,9** (no uniforme) | `kenney_tren` |
| `kenney_roads` (en uso) | calzada de 1 unidad; farola curva 0,67 | ×12 (ya es así en `_kenney_calles`) | — |

**Triángulos por pieza** (media del kit): suburbano ≈750 (casas de 770 a 2.060),
industrial ≈960, tren ≈730 (coche de metro ≈1.550), montaña rusa ≈410, mini mercado ≈290,
arcade ≈360, muebles ≈190, comida ≈170, kit de edificios ≈105, modulares ≈64.
Ninguno es pesado por pieza; el coste está en **cuántas** se pongan y en no
agruparlas (cada GLB es un nodo con su malla).

**Estilo.** Todos los kits comparten la paleta «colormap» de Kenney: blancos lila, techos
**verde menta**, azul claro y naranja. Va con las fachadas comerciales que ya usa la
ciudad, pero no con los peatones (modelos humanos realistas) ni con las texturas de
asfalto y acera. Hace falta `tenir` (o una variante que solo cambie el tejado) para
quitar el verde menta repetido. Los **personajes** de los kits (`character-employee`,
`character-gamer`) son cabezones de dibujo animado (`kenney_bar`, `kenney_salon`): **no
se recomiendan**, porque chocan con la gente del juego.

---

## 3. Recomendaciones por kit

### 3.1 `suburbano` — City Kit Suburban · **PRIORIDAD 1**
- **Piezas**: las 21 casas `building-type-a…u`; `fence-1x2/1x3/1x4/2x2/3x3`, `fence-low`,
  `driveway-long/short`, `path-long`, `path-stones-long/messy`, `planter`.
  `tree-large/small` no: los árboles actuales del parque valen.
- **Dónde**: el barrio sur (`CiudadExpansion._casas(r)`, zona «sur», unas 380 casas).
  Sustituir la caja de `_casas_t` y el prisma de `_techos_t` por un modelo elegido con el
  mismo `hr` (semilla por posición) que hoy elige el arquetipo, para que la ciudad no
  cambie de sitio. La puerta del GLB marca el `_puertas_t`, que sigue siendo el punto de
  entrada (`puntos_clic` → `edificio_vivienda`).
- **Escala**: ×5,6 uniforme (como el kit comercial; nunca estirar, ver el comentario de
  `_fachadas`). La parcela da unos 15 m de frente: entra una casa con un camino de entrada
  o una valla al lado.
- **Color**: `tenir(n, hash(pos))` para el cuerpo, más un cambio del tejado verde menta
  por una de las tres tejas actuales (rojo teja, gris pizarra, marrón) leyendo
  `COLORES_CASA`. Ojo: `tenir` multiplica todo el material (cuerpo y tejado) porque el
  GLB usa una sola textura de paleta; para teñir solo el tejado hay que cambiar la
  textura (copiar `colormap.png` con la celda del tejado repintada, un material por
  tono) o usar las `variation-*.png` de los zips, que no se copiaron.
- **Riesgos**: 380 casas × ~1.300 triángulos ≈ 0,5 M si se vieran todas; con el corte
  por distancia de `Optimizar.trocear` y agrupando por modelo (un MultiMesh por cada
  `building-type`, 21 llamadas) no debería costar más que hoy. Mantener el
  `_detalle_casa` solo para lo que el GLB no trae (buzón, contraventanas no).

### 3.2 `muebles` + `comida` — interiores · **PRIORIDAD 2**
- **Piezas**: salón (`loungeSofa`, `loungeSofaCorner`, `loungeChair`, `tableCoffee`,
  `rugRectangle/rugRound`, `cabinetTelevision`, `televisionModern`, `bookcaseOpen/Closed`,
  `lampRoundFloor`, `pottedPlant`, `plantSmall1-3`); cocina (`kitchenCabinet*`,
  `kitchenSink`, `kitchenStove`, `kitchenFridgeLarge`, `kitchenMicrowave`,
  `kitchenCoffeeMachine`, `hoodModern`); comedor (`table`, `tableCloth`, `chairCushion`,
  `tableRound`); bar (`kitchenBar`, `kitchenBarEnd`, `stoolBar`); oficina (`desk`,
  `deskCorner`, `chairDesk`, `computerScreen`, `computerKeyboard`, `laptop`,
  `bookcaseClosedWide`); dormitorio y baño (`bedDouble`, `bedSingle`, `cabinetBed*`,
  `toilet`, `bathroomSink`, `shower`, `bathtub`) para la Casa Grande; `washer/dryer`
  para el taller o la residencia. Comida: `plate-dinner`, `burger*`, `pizza`, `fries`,
  `soda-can`, `glass-wine`, `cocktail`, `cup-coffee`, `croissant`, `loaf*`, `donut*`,
  `sandwich`, `bread`, `cake`.
- **Dónde**: `ui/componentes/interior_instalacion.gd`. Cambiar las ayudas de mueble
  (`_escritorio`, `_silla`, `_mostrador`, `_estanteria`, `_planta`, `_cama`) para que
  instancien el GLB en vez de cajas, y rehacer los salones de `_vivienda`, `_bar`,
  `_panaderia`, `_libreria`, `_oficina`, `_comedor` y `_prensa`. Como
  `InteriorInstalacion.en_mundo` usa el mismo código, la mejora sirve a la vez para la
  ficha («Ver por dentro») y para entrar caminando.
- **Escala**: muebles ×2,0; comida ×0,3 (pizza ×0,4).
- **Antes de amueblar, reducir las salas**: `_sala(Vector3(22, 5.5, 16)…)` → vivienda
  ~12 × 2,8 × 9 m; bar ~14 × 3,2 × 10 m. Con salas de 22 m, cualquier mueble a escala
  real se pierde.
- **Riesgos**: `Optimizar.obstaculos` saca la colisión de las cajas de las mallas: con
  GLB funciona igual (cada pieza es una sola malla), pero alfombras y platos quedan
  fuera por altura, que es lo correcto. Las paredes `wall*` del kit miden 2,6 m a ×2: no
  usarlas como sala (el suelo y las paredes de `_sala` valen) salvo para tabiques.

### 3.3 `mini_mercado` y `mini_arcade` — tiendas y recreativos · **PRIORIDAD 3**
- **Piezas**: `shelf-bags`, `shelf-boxes`, `shelf-end`, `display-fruit`, `display-bread`,
  `freezer`, `freezers-standing`, `cash-register`, `shopping-cart`, `shopping-basket`,
  `bottle-return`. Arcade: `arcade-machine`, `pinball`, `air-hockey`, `claw-machine`
  (animada), `dance-machine`, `basketball-game`, `gambling-machine`, `ticket-machine`,
  `prize-wheel` (animada), `prizes`, `vending-machine`. Nada de `character-*`.
- **Dónde**: `_tienda()` (centro comercial, tienda de la gasolinera, tienda del club
  «com»), `_mercado()` y `_panaderia()` (los expositores de pan y fruta) en
  `interior_instalacion.gd`; las máquinas expendedoras, en `_estacion()`, `_hospital()` y
  `_gimnasio()`. Arcade: una sala nueva «recreativos» (otra entrada en `SALAS_EDIFICIO` y
  en `ExploradorCiudad.EDIFICIOS`) y la zona de ocio de `esports`; encaja con los
  minijuegos (`Mini3D`).
- **Escala**: ×2,4. **Color**: la paleta lila-azul es muy de juguete; `tenir` con un tono
  neutro.

### 3.4 `industrial` — polígono y puerto · **PRIORIDAD 4**
- **Piezas**: naves `building-a, c, e, f, l, m, q, r, t`, `chimney-large/medium`,
  `detail-tank-large`, `water-tower`, `shipping-container-a/b/c`,
  `solar-panel-landscape-group`, `solar-panel-portrait-group`, `windmill`.
- **Dónde**: `CiudadExpansion._industrial(r)` (zona oeste, entre z -700 y 700): una nave del
  kit en lugar de la caja con dientes, contenedores GLB en vez de la MultiMesh de cajas y
  la chimenea del kit. `_puerto(r)`: el almacén y una pila de contenedores.
  `_deposito_agua()`: `water-tower`. Las placas solares, en azoteas de `_detalle_edificio`
  (azotea plana) y en la cubierta de las naves.
- **Escala**: naves ×9-10; contenedores ×7,4; chimeneas ×9.
- **Riesgos**: casi ninguno. El estilo es igual que el del kit comercial ya en uso.

### 3.5 `kit_edificios` — Building Kit · **PRIORIDAD 5**
- **Piezas**: `door-rotate-square-a…d`/`door-rotate-round-*` (puertas **animadas**),
  `wall-doorway-*`, `wall-window-*-detailed`, `stairs-open/closed`, `column*`,
  `gutter-vertical*`, `roof-flat-*`, `barricade-*` y `plating*`.
- **Dónde**: (a) la puerta animada en `ExploradorCiudad._entrar_en_edificio`, en la fachada
  antes del fundido (hoy se entra «a través» de la pared); (b) la puerta de cada sala de
  `InteriorInstalacion._sala` (la pared de delante es baja y no tiene puerta); (c)
  `barricade-*` y `plating*` para las obras y los andamios de `EstadioPropio.obra` y
  `_obras_en_calle`; (d) canalones y columnas en `_detalle_edificio`.
- **Escala**: ×1,0-1,15 (ya está en metros).

### 3.6 `tren` — metro y tranvía · **PRIORIDAD 6 (con cuidado)**
- **Piezas**: `train-electric-subway-a/b/c` (metro), `train-tram-modern` y
  `train-tram-classic` (tranvía), `train-carriage-container-*` y `train-locomotive-*`
  (mercancías en el puerto).
- **Problema**: los trenes son de juguete: a escala uniforme ×2,2 el coche de metro mide
  **5,7 m de largo** contra los 16 m de cada coche de `MetroCiudad._tren_real`. Estirado
  a lo largo (×2,2; ×2,2; ×6,9) se lee como un metro de verdad visto desde fuera
  (`kenney_tren`, segundo tren), pero las puertas y ventanas se ensanchan. Además, el
  metro de `metro_ciudad.gd` es **usable por dentro** (asientos, barras, puertas que
  corren), así que el modelo de Kenney **solo sirve como carcasa vista desde fuera**
  (L1 elevada vista desde la calle) y como tren de los túneles en rayos X. No sustituir
  el coche usable.
- **Mejor uso**: un **tren de mercancías** parado en el puerto y un **tranvía**
  decorativo (×2,3 uniforme: 6 m, aceptable como coche corto) en el bulevar.
- **Vías**: `track-single` ×3 no casa con el viaducto propio; no hace falta.

### 3.7 `montana_rusa` — parque de atracciones · **PRIORIDAD 7 (contenido nuevo)**
- **Piezas**: `park-entrance`, `stall-food`, `stall-drinks`, `stall-information`,
  `stall-toilets`, `bench`, `trash`, `flowers`; una montaña rusa `coaster-steel-*` con
  `support-*` y `coaster-train*`.
- **Dónde**: los puestos (×2,2) valen YA para los parques (`_detalles_parque`), la Plaza
  Mayor, el exterior del estadio el día de partido y el puerto. Una feria completa
  sería una instalación nueva en `_instalacion(uso, r)` sobre una manzana especial
  (`ESPECIALES`).
- **Riesgos**: los tramos de vía tienen el origen al principio y bajan 1 unidad (AABB
  con `min_y = -1`): hay que encadenarlos con un trazador propio. En el muestrario,
  colocados a ojo, quedan sueltos (`kenney_parque`). Un looping creíble necesita ×4.

### 3.8 `edificios_modulares` — Modular Buildings · **PRIORIDAD 8**
- **Piezas**: las muestras `building-sample-house-a/b/c` y `building-sample-tower-a…d`
  tal cual, y las piezas por piso (`building-window-*`, `building-door-*`,
  `building-window-balcony`, `building-window-awnings`, `roof-flat-*`, `roof-gable*`) para
  fachadas propias.
- **Dónde**: barrio de pisos (`_pisos(r)`, zonas «norte», «este lejos» y «oeste»), que hoy
  repite los mismos edificios comerciales, y las casas adosadas estrechas (5 m) en las
  calles de los bordes del barrio sur. Componer fachadas pieza a pieza (3 columnas × N
  pisos) da «cada edificio distinto» de la etapa 6.
- **Escala**: ×4,8. **Orientación**: la fachada mira a **+Z** (al revés que el kit
  suburbano, que mira a −Z): en el primer muestrario se pusieron al revés y se veían por
  la espalda.
- **Riesgos**: armar por piezas son muchas instancias (9-30 por edificio, 64 triángulos
  cada una): hay que agruparlas por pieza (MultiMesh) desde el principio.

### 3.9 `kenney_roads` (ya en uso en parte)
- Ya se usan farolas curvas, postes con cable, carteles colgantes y piezas de obra.
- **Añadir**: `light-curved`/`light-square-double` también en las calles de barrio y en
  el puente (sustituyen a la cabeza de farola amarilla de `_farolas()`);
  `bridge-pillar-wide` bajo los puentes (`_puente`, ×12 → 6 m); `dumpster` (×12 → 3,4 ×
  4,4 m: mejor ×7) en las traseras; `road-sign-*` como señales.
- **No** sustituir las calzadas por las piezas `road-*` (la decisión del 14-10 sigue
  siendo buena: la red y los semáforos dependen de las calzadas actuales).

---

## 4. Plan priorizado (más impacto visual con menos riesgo primero)

| # | Qué | Archivo · función | Impacto | Riesgo |
|---|---|---|---|---|
| 1 | Casas del barrio sur con `suburbano` ×5,6 (modelo por `hr`, tinte por posición, tejado sin verde menta), valla y camino de entrada | `visor/ciudad_expansion.gd` · `_casas`, `_detalle_casa`, `_casas_multimesh` | Muy alto | Bajo-medio (puertas: mantener `_puertas_t`) |
| 2 | Reducir las salas y amueblarlas con `muebles` + `comida` | `ui/componentes/interior_instalacion.gd` · `_sala`, `_escritorio`, `_silla`, `_mostrador`, `_estanteria`, `_planta`, `_cama`, `_vivienda`, `_bar`, `_oficina`, `_comedor` | Muy alto (dentro) | Bajo |
| 3 | Arreglar a la gente sentada en el aire (altura del asiento del mueble y pacientes tumbados) | `interior_instalacion.gd` · `_trabajador` (sentado), `_hospital`, `_bar` | Alto | Bajo |
| 4 | Tiendas, mercado y panadería con `mini_mercado`; máquinas expendedoras en estación, hospital y gimnasio | `interior_instalacion.gd` · `_tienda`, `_mercado`, `_panaderia`, `_estacion` | Alto | Bajo |
| 5 | Polígono y puerto con `industrial` (naves ×9-10, contenedores ×7,4, chimenea, depósito) | `ciudad_expansion.gd` · `_industrial`, `_puerto`, `_deposito_agua` | Medio-alto | Bajo |
| 6 | Farolas de barrio y puente con `light-curved`; pilares de puente | `ciudad_expansion.gd` · `_farolas`, `_puente` | Medio | Bajo |
| 7 | Puerta animada `door-rotate-*` al entrar y salir de un edificio | `visor/explorador_ciudad.gd` · `_entrar_en_edificio`, `_salir_del_edificio`; `interior_instalacion.gd` · `_sala` | Medio | Medio (tiempos del fundido) |
| 8 | Puestos de la feria en parques, plaza y alrededores del estadio | `ciudad_expansion.gd` · `_detalles_parque`, `_instalacion("plaza_mayor")` | Medio | Bajo |
| 9 | Sala «Recreativos» con `mini_arcade` | `interior_instalacion.gd` (sala nueva) + `ExploradorCiudad.EDIFICIOS` | Medio | Bajo |
| 10 | Bloques de pisos distintos con `edificios_modulares` | `ciudad_expansion.gd` · `_pisos` | Alto (etapa 6) | Medio (muchas instancias) |
| 10b | Andenes del metro con máquinas expendedoras, bancos y papeleras del kit, y gente esperando | `visor/metro_ciudad.gd` · `_decorar_estacion`, `_banco` | Medio | Bajo |
| 11 | Tren de mercancías en el puerto y tranvía decorativo | `ciudad_expansion.gd` · `_puerto`; `metro_ciudad.gd` solo para la vista desde fuera | Bajo-medio | Medio (escala de juguete) |
| 12 | Parque de atracciones con montaña rusa | instalación nueva en `_instalacion` + `ESPECIALES` | Medio (contenido) | Alto (trazado de vías) |

Reglas comunes:
1. Escala **uniforme** salvo el tren.
2. Agrupar en MultiMesh por modelo (como hacen `Optimizar.agrupar`/`trocear`).
3. Usar el azar de la **posición** (no `_rng`) para no mover la ciudad.
4. Comprobar con capturas en Forward+ a la altura de los ojos y desde el coche.

---

## 5. Bugs y cosas raras vistas al recorrer

| Gravedad | Qué | Dónde se ve | Origen probable |
|---|---|---|---|
| Alta | Gente **sentada en el aire**: pacientes encima de las camas, un hombre entre dos sillas de la sala de espera, un cliente en el borde de una mesa del bar | `entrar_0_tercera`, `entrar_1_tercera` | `InteriorInstalacion._trabajador(sentado=true)` pone el clip «sentado» en la `p` que se le da, sin mirar el asiento: en `_hospital` los pacientes van a y = 0,3 en la cabecera (z −6,9; el colchón está a 0,6 m), con las piernas colgando por encima de la cama; en la sala de espera se adelantan 0,2 m a la silla (z 4,3 frente a 4,5). Hace falta una altura de asiento por mueble |
| Alta | El **rótulo de la fachada no corresponde a lo que hay dentro**: el rótulo sale de `_rng` en `_rotulo_comercio` (16 tipos: Farmacia, Banco…) y el interior de `ExploradorCiudad.edificio_en` sale de un `hash` de la celda de 14 m (7 tipos). Una «Farmacia» puede abrir un taller | revisión del código | `ciudad_expansion.gd` · `_rotulo_comercio` vs `explorador_ciudad.gd` · `edificio_en` |
| Alta | Casas como **cajas blancas gigantes**: los pastel de `COLORES_CASA` se queman con la exposición | `paseo_2_casas` | `_casas` + `COLORES_CASA` |
| Media | **Sombras azules** en aceras y calzada (luz ambiente del cielo muy fuerte y azul en Forward+) | `paseo_1_avenida`, `paseo_2_casas` | `ui/ciudad_vista.gd` (~l. 420): en Forward+ la luz ambiente sale del cielo con shader (azul) a energía 1,0; solo en Compatibilidad se pasa a un color neutro. Esto explica por qué en las capturas antiguas (Compatibilidad) no se veía |
| Media | **Asfalto que deslumbra** a contraluz (zona blanca quemada) | `paseo_3_parque`, `paseo_4_puente`, `paseo_6_calle` | rugosidad o especular del asfalto de `Texturas.asfalto` en Forward+ |
| Media | Salas interiores de 22 × 16 × 5,5 m, sin escala humana | `entrar_*` | `InteriorInstalacion._sala` |
| Media | Pasos de cebra rotos o torcidos junto al puente | `paseo_4_puente` | `_dibujar_calles` cerca de la rampa |
| Baja | La cámara a pie queda **detrás de una farola** (el poste parte la imagen en dos) | `paseo_3_parque` | `ExploradorCiudad._colocar_camara` no evita postes finos |
| Baja | El nombre del parque sale **dos veces** (rótulo del pórtico y Label3D flotante encima) | `paseo_3_parque` | `_detalles_parque` |
| Baja | Un deportivo «01» aparcado en mitad del paso de cebra del cruce | `paseo_5_cruce` | coche del jugador o extra de `_poner_extra` dejado en la calzada |
| Baja | Guirnaldas: bolas de colores flotando sin cable visible de día | `paseo_6_calle` | `_guirnaldas` (cable muy fino o sin material) |
| Herramienta | El tutorial de la ciudad tapa todas las capturas | todas | `captura_paseo`/`captura_entrar` no cierran el tutorial (`AjustesCiudad`) |
| Herramienta | `captura_paseo` y `captura_entrar` guardan PNG con el nombre de los PNG antiguos: `captura.sh` los cambia por JPG y el PNG versionado aparece como borrado | git | normal según la regla del 15-10; se aceptó el cambio |

---

## 6. Archivos de esta evaluación

- `pruebas/muestrario_kenney.gd/.tscn`: escena de prueba (`SOLO=grupo` para una foto).
- Capturas nuevas: `kenney_exteriores`, `kenney_exteriores_calle`, `kenney_modulares`,
  `kenney_tren`, `kenney_salon`, `kenney_tienda`, `kenney_bar`, `kenney_parque`; recorrido:
  `paseo_1…6`, `entrar_0…2_tercera/primera`, `metro_1…8`.
