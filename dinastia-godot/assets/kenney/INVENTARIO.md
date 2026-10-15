# Inventario de kits 3D de Kenney (guardados para después)

Regalo del usuario (15-10-2026). Todos son de **Kenney (www.kenney.nl), licencia CC0**:
uso libre, también comercial; acreditar no es obligatorio. Cada carpeta lleva su
`License.txt` y una `Preview.png`.

**Estado: GUARDADOS, AÚN SIN USAR.** Ningún script ni escena los carga todavía.

## Cómo están guardados

- Solo el formato **GLB** (nada de FBX/OBJ/DAE/STL). Los GLB leen la textura externa
  `Textures/colormap.png` (paleta de colores), que va al lado en cada carpeta;
  el kit de muebles no usa textura (colores por material).
- **Sin Git LFS**: cada carpeta tiene su regla de excepción en `.gitattributes` de la raíz.
- Los `.import` se versionan. `mini_arcade/prize-wheel.glb.import` lleva
  `nodes/use_node_type_suffixes=false`: el nodo «prize-wheel» acaba en «-wheel» y Godot
  lo convertía en `VehicleWheel3D`, con lo que la animación de la rueda perdía su nodo.
- Comprobado: los 930 GLB importan y se instancian sin errores en Godot 4.7.2.
- Uso: `load("res://assets/kenney/<kit>/<pieza>.glb").instantiate()`. Las piezas de
  ciudad de Kenney miden en «casillas» de ~1 m; hay que escalarlas a la ciudad
  (ver `CityBuilder.MEDIDAS_REALES` y cómo se usan los `assets/ciudad/kenney_*`).
- Algunos modelos traen animaciones (`AnimationPlayer`): puertas que abren/cierran
  (`kit_edificios/door-rotate-*`, `*/wall-door-rotate`, `mini_mercado/fence-door-rotate`),
  la grúa y la rueda de premios del arcade, y los personajes `character-*`
  (idle, walk, sprint, sit, drive, pick-up, emote-yes/no, interact…).

## Kits no duplicados

- **City Kit Roads**: los 95 GLB y el `colormap.png` del zip son idénticos (byte a byte)
  a `assets/ciudad/kenney_roads/` (guardado el 14-10-2026). No se copió otra vez.
- **City Kit Commercial 2.1**: sus 41 GLB y el `colormap.png` ya están, idénticos, repartidos
  entre `assets/ciudad/kenney_comercial/`, `kenney_comercial_extra/` y `kenney_buildings/`
  (rascacielos). No faltaba nada; no se copió.

## Kits guardados

| Carpeta | Kit (versión) | Modelos | Tamaño |
|---|---|---:|---:|
| `muebles/` | Furniture Kit (2.0) | 140 | 2,3 MB |
| `edificios_modulares/` | Modular Buildings (2.1) | 108 | 1,0 MB |
| `kit_edificios/` | Building Kit (1.0) | 79 | 1,1 MB |
| `suburbano/` | City Kit Suburban (2.0) | 40 | 2,8 MB |
| `industrial/` | City Kit Industrial (2.0) | 37 | 3,4 MB |
| `tren/` | Train Kit (1.1) | 103 | 7,2 MB |
| `montana_rusa/` | Coaster Kit (1.0) | 183 | 7,0 MB |
| `mini_mercado/` | Mini Market (1.0) | 20 | 0,9 MB |
| `comida/` | Food Kit (2.0) | 200 | 3,7 MB |
| `mini_arcade/` | Mini Arcade (1.2) | 20 | 1,2 MB |
| **Total** | 10 kits | **930** | **≈ 30,6 MB** |

### `muebles/` — Furniture Kit
- **Piezas**: cocina completa (20: muebles altos/bajos, fregadero, horno, nevera, campana,
  cafetera…), mesas (10), sofás y sillones `lounge*` (9), sillas y taburetes, camas,
  baño (lavabo, inodoro, ducha, bañera, espejo, armarios), librerías, lámparas (pie, mesa,
  techo), alfombras, cojines, plantas, televisores, ordenadores y portátil, escritorios,
  lavadora y secadora, altavoces, radio, perchero, cajas de cartón, papelera, oso de peluche;
  también paredes, puertas (`doorway*`), suelos, escaleras y revestimientos.
- **Para el juego**: interiores de casas y oficinas (`InteriorInstalacion`, la Casa Grande,
  los edificios en los que se entra caminando), oficina del DT y despachos del estadio,
  personalizar habitaciones (ESTADIO_INTERACTIVO_2).

### `edificios_modulares/` — Modular Buildings
- **Piezas**: 48 bloques de edificio por pisos/esquinas, 30 tejados, 22 ventanas,
  6 puertas y detalles. Se apilan para armar fachadas de varios pisos.
- **Para el juego**: etapa 6 de `ETAPAS_FINALES.md` («cada edificio distinto»): combinar
  bloques, ventanas y tejados para que no haya dos fachadas iguales en la ciudad.

### `kit_edificios/` — Building Kit
- **Piezas**: paredes (22, con ventanas y huecos), puertas (8, varias animadas que abren y
  cierran), suelos, escaleras (8), tejados, columnas, canalones, bordes, barricadas, chapas.
- **Para el juego**: casas y locales por piezas a los que se pueda entrar (etapa 6), obras y
  andamios de `EstadioPropio.obra`, puertas animadas en interiores.

### `suburbano/` — City Kit Suburban
- **Piezas**: 21 casas `building-type-a…u`, vallas (9 medidas), caminos y losas, entradas de
  coche, árboles, jardinera.
- **Para el juego**: barrios residenciales con casas distintas (etapa 6), jardines con valla y
  camino de entrada; complementa los 5 arquetipos de casa actuales.

### `industrial/` — City Kit Industrial
- **Piezas**: 20 naves y fábricas `building-a…t`, chimeneas (4), depósitos, contenedores de
  barco (3), paneles solares (5), molinos de viento, torre de agua.
- **Para el juego**: polígono industrial y puerto (`ciudad_expansion.gd`: zona portuaria),
  parque eólico/solar, variedad de edificios (etapa 6).

### `tren/` — Train Kit
- **Piezas**: 54 tramos de vía (rectas, curvas, rampas, cruces, desvíos, vía dañada),
  42 trenes y vagones: metro `train-electric-subway-a/b/c`, tranvías (clásico, moderno,
  redondo), trenes urbanos, de dos pisos, bala, diésel, locomotoras de pasajeros, vagones de
  mercancías y contenedores; piezas `track`/`spline` para trazar.
- **Para el juego**: el metro (`metro_ciudad.gd`: L1 elevada y L2) con trenes de verdad, un
  tranvía o tren de cercanías en la ciudad, mercancías en el puerto.

### `montana_rusa/` — Coaster Kit
- **Piezas**: 6 tipos de montaña rusa (acero, madera, colgante, ratón loco, monorraíl y
  troncos/agua) con ~23 tramos cada una, trenes, soportes (12), estación y puertas, colas,
  caminos, puestos (bebidas, comida, información, aseos), entrada del parque, bancos,
  árboles, papelera.
- **Para el juego**: un parque de atracciones en la ciudad y minijuegos en él.

### `mini_mercado/` — Mini Market
- **Piezas**: estanterías (bolsas, cajas, cabecera), expositores de pan y fruta, congeladores,
  caja registradora, carrito y cesta, máquina de devolver botellas, paredes/suelo/columna/vallas, puerta de valla animada, dependiente
  animado (`character-employee`).
- **Para el juego**: tiendas y supermercados por dentro (interiores de comercios con NPC
  trabajando), tienda del club.

### `comida/` — Food Kit
- **Piezas**: 200 alimentos y utensilios: hamburguesas, pizza, sushi, perritos, tacos, tartas,
  dónuts, helados, fruta y verdura, carne y pescado, panes, refrescos, vino, cócteles, tazas,
  platos, ollas, sartenes, tablas, cubiertos.
- **Para el juego**: bares, restaurantes y puestos de la ciudad y del estadio, cocina de las
  casas, comedor del club, mesas del vestuario.

### `mini_arcade/` — Mini Arcade
- **Piezas**: máquina recreativa, pinball, mesa de air hockey, canasta, máquina
  de baile, grúa (animada), tragaperras, rueda de premios (animada), máquina de tickets,
  premios, máquina expendedora, caja, paredes/suelo/columna, puerta animada y dos personajes
  animados (empleado y jugador).
- **Para el juego**: la sala de minijuegos (Mi Vida → minijuegos, `mini3d.gd`), una sala de
  recreativos en la ciudad, zona de ocio del vestuario.

## Notas

- `mini_arcade` y `mini_mercado` comparten piezas con el mismo nombre (paredes, suelo,
  columna, `character-employee`); cada kit tiene su propio `colormap.png`, así que se
  guardan los dos.
- No se copiaron las texturas de variación (`Models/Textures/variation-*.png`, otras paletas
  del mismo `colormap`) que traen los kits de edificios, mercado y arcade: los GLB no las
  usan. Si algún día se quieren, están en los zips (basta con cambiar la textura del material).
