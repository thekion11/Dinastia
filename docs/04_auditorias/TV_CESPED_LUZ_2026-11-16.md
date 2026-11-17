# Cámara de TV, césped y luz hacia la referencia de FC Mobile (16-11)

Encargo del dueño («Sí» a los puntos 1-3 de `COMPARACION_REFERENCIAS_PARTIDO_2026-11-16.md`): jugadores grandes y legibles con la
cámara de TV, césped natural y luz suave. Solo VISUAL: `pruebas/igualdad_motor.gd` da «FIN. 0 fallos» sin tocarla.

## 1. Cámara: la TV cercana por defecto (`visor/camera_rig_p1.gd`, `camera_rig.gd`)

| | Antes («TV lejana») | Ahora («Transmisión») |
|---|---|---|
| Apertura vertical | 33° | **21°** |
| Altura | 17 m | **15,5 m** |
| Distancia (x del raíl) | `_dist_tele` (dx − 7, máx. 46) | **4 m más cerca del campo**, nunca por debajo de x = 38 |
| Cierre en el área / apertura en la contra | 7,5° / 6° | 4° / 5° (ya va cerrada) |
| El foco hacia la banda de la cámara | hasta x = 4 (10 con el plano cerrado) | 4 m más (el balón de esa banda no se va al borde) |
| Jugador junto al balón (media de 160 fotogramas, `ALTO_JUGADOR`) | **1/14 – 1/15,5** del alto | **1/7,9 – 1/9,2** del alto |

- La de antes sigue entera como cámara **«TV lejana»** (la última del ciclo 📷, así no se mueven los índices de las demás). La que se
  elige con 📷 entre «Transmisión» y «TV lejana» se recuerda (`tv_lejana` en el archivo de ajustes) y es la que abre el siguiente partido.
- **Pantallas más estrechas que 16:9** (tableta 4:3, ventana cuadrada, teléfono en vertical): `CameraRig.fov_para_aspecto` abre la
  apertura lo justo para ver el MISMO ancho de campo que en 16:9 (si no, con 21° en vertical solo se veían 2-3 jugadores). Ahí el
  jugador sale algo más pequeño; en 16:9 o más ancho (PC, teléfono en horizontal, 19,5:9) no cambia nada.
- Lo demás de la transmisión (zona muerta, anticipación, balón siempre en cuadro, raíl, techo, saltos) no cambia.

## 2. Césped (`visor/cesped_comun.gdshaderinc`, `cesped.gdshader`, `cesped_textura.gd`)

- **Verde natural**: saturación 1,15 → **0,74** y tinte hacia el amarillo `(1.04, 0.95, 0.64)` (antes `(0.94, 0.99, 0.92)`), como
  uniformes (`saturacion`, `tinte`). Mismo coste: solo cambian constantes; vale también para el césped barato y las capas de hierba.
- **Franjas más marcadas**: el brillo de la franja según el ángulo pasa de ±10 % a ±26 % (`marca_franjas`).
- **Franjas más anchas**: «rayas» 20 → **16** a lo largo (~7,3 m), «rayasH» 20 → 14, y las de «liso» y «mitades» también a 16. El
  dibujo de cada club (rayas, damero, cruz, círculos…) no cambia; la caché de la textura se invalida sola (huella del script).
- **Variación de tono a gran escala**: la mancha de ~20 m (`fbm` que ya existía) pesa el doble y añade zonas algo más secas y amarillas;
  sin `fbm` nuevos.
- **Brizna de foto CC0** (solo `cesped.gdshader`, no el barato): la luminancia pasa-alto de «Grass005» de ambientCG
  (`assets/cc0/grass005/detalle.jpg`, 512 px en gris, 114 KB, fuera de LFS, con mipmaps; fila en `LICENCIAS.md`) multiplica ±22 % en
  teselas de 1,7 m. De lejos se promedia a gris medio (no cambia el tono); de cerca da grano real. Coste: una lectura de textura por
  píxel del campo (el shader ya hacía ~10 de ruido).
- `cesped_barato` (MÍNIMA/ULTRA BAJA y modo rendimiento) **no gana nada de coste**: no lleva la foto ni ruido nuevo.

## 3. Luz (`visor/ambience.gd`)

- Ya había ACES (`TONE_MAPPER_ACES`): se queda.
- **Más luz del cielo de día**: `ambient_light_energy` 1,0 → **1,35** (de noche igual, 1,0).
- **Sol más alto**: −58° → **−67°** (de noche igual, −40°): sombras cortas bajo los pies y la de la tribuna llega menos al césped. Su
  energía baja de 1,35 a **1,2** porque sube la del cielo (la prueba `f0m_visor_estadio` se actualizó a 1,2: cambio intencionado).
- **Sombras menos negras**: `shadow_opacity` 0,72 de día (1,0 de noche). La sombra de la tribuna sobre el césped **se queda** (no se
  apagó), pero más clara y con la penumbra más abierta: `light_angular_distance` 0,5 → **1,2** (el borde duro de medio campo se suaviza).
  Ninguna de las tres cosas añade pasadas ni muestras de sombra.
- **Cielo HDRI (Poly Haven)**: NO se puso. Con la TV cercana el cielo casi no sale en cuadro y la luz ambiente ya sale del cielo
  procedural; un HDRI suma un panorama en memoria y el filtrado del radiance al cambiarlo, para casi nada visible. Queda anotado para la
  vista de la grada o las celebraciones, si el dueño lo pide.

## Coste (medido con `pruebas/medir_partido.tscn`, España, cámara de TV, llvmpipe a 1366x768; sin el tiempo de fotograma)

| Nivel | Antes: llamadas / triángulos / objetos | Después | Diferencia |
|---|---|---|---|
| ULTRA BAJA | 165 / 249.216 / 231 | **143 / 210.360 / 206** | −13 % llamadas, −16 % triángulos |
| ALTA | 641 / 1.694.956 / 710 | **594 / 1.569.421 / 663** | −7 % llamadas, −7 % triángulos |

La cámara más cerrada deja fuera de cuadro parte de la grada: el partido pide MENOS a la gráfica. VRAM igual (244 / 440 MB). Los
FPS reales, en la laptop del dueño.

Nota de método: `herramientas/hw_modesto.sh` mete el proceso en un cgroup de 4 GB y el estadio en Forward+ pasó de ese tope en esta
máquina (código 137): las medidas de antes se tomaron con `HW_RAM_MB=12000` y las de después con el mismo `taskset -c 0,1` sin cgroup
(las llamadas y triángulos no dependen de la RAM).

## Capturas (`capturas_tv_cesped_luz_2026-11-16/`)

`herramientas/captura.sh res://pruebas/captura_tv_cesped_luz.tscn` (Forward+, ALTA, 1920x1080 reducidas a 1280x720), tres cruces de
países: Brasil-Japón (Morumbi FC, césped «cruz»), Argentina-España (Avellaneda, «cruz») y México-Italia (Cerro Silla FC, «damGrande»).
`tv_*` = cámara real a los ~2' de juego, `tv2_*` = unos segundos después, `cerca1_*` = plano a ~8 m del que lleva el balón;
`*_antes_despues.jpg` las pone lado a lado. `tv_lejana_mex_ita_despues.jpg` = la opción «TV lejana» con el césped y la luz nuevos.
El estadio no repite exactamente igual de una tanda a otra, así que algunas parejas no son el mismo instante; las `tv2_mex_ita_*`
caen en la realización de un gol (cámara de la grada), no en la TV.

Mejores: `tv_arg_esp_antes_despues.jpg`, `tv_mex_ita_antes_despues.jpg`, `tv2_bra_jpn_antes_despues.jpg`, `cerca1_mex_ita_antes_despues.jpg`.

## Pruebas

- `pcam_encuadre` (balón siempre en cuadro en 4 estadios × 2 alturas, saque de banda, despeje alto): 0 fallos sin tocarla.
- Banco `_probar_transmision_y_estadisticas`: la apertura de referencia pasa a `fov_para_aspecto(FOV_TRANSMISION, aspecto)` (sin
  pantalla la ventana es 1:1, más estrecha que 16:9). Cambio intencionado.
- `igualdad_motor`: 0 fallos (la huella del motor no cambia).

## Pendiente

- Veredicto del dueño con las capturas y EN EL TELÉFONO (horizontal y vertical): si 1/8 le parece cerca o lejos, se ajusta
  `FOV_TRANSMISION` (21°) y `ALTURA_TRANSMISION` (15,5 m).
- En las capturas, justo tras saltar 360 pasos del motor de golpe el plano aún llega con retraso y el balón queda abajo del cuadro
  (`tv_bra_jpn_despues`); en juego normal no pasa (el foco lo alcanza), pero conviene mirarlo en el teléfono en los saques rápidos.
- Puntos 4-8 de la comparación (marcador, nombres, radar, animaciones, mando): sin tocar.
