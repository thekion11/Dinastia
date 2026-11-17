# Público y césped con la cámara de TV (17-11)

Orden de la sesión de auditoría (comparación con FC Mobile, `COMPARACION_REFERENCIAS_PARTIDO_2026-11-16.md` y `TV_CESPED_LUZ_2026-11-16.md`):
el público se leía como butacas del club vacías con gente suelta, y el césped seguía verde saturado y plano. Solo VISUAL: el motor no se
toca (`igualdad_motor`, huella 4068298361) y nada suma llamadas de dibujo ni triángulos (ver cifras).

## 1. Público: butacas vacías en sombra (`visor/grada_butacas.gd`, `stadium_builder_p6.gd`)

- Cada grupo de tres butacas se oscurece y se apaga según cuántos de sus TRES asientos quedan libres (`GradaButacas.color_vacia`:
  hasta −58 % de brillo y −45 % de saturación con los tres libres). La grada llena conserva el color del club por nivel (orden 13); la
  vacía se hunde hacia el tono del hormigón, como la sombra entre la gente. Se mira DESPUÉS de repartir la hinchada, así que el azar se
  consume igual: nadie cambia de sitio ni de ropa.
- En MÍNIMA (un hincha por grupo) es donde más se nota: el mar de plástico claro (celeste en Eastlands, granate en Navigli) pasa a ser una
  masa oscura con la gente encima. En ALTA (hasta tres por grupo) el cambio es suave: solo los huecos.
- Coste: CERO. Es el color de instancia que cada grupo ya llevaba (sin mallas, materiales ni llamadas nuevas).
- No se hizo (pendiente, cuesta): más figuras por grupo en MÍNIMA o variar poses/escala más allá de lo que ya hay. La variedad de ropa
  (4 de cada 10 con los colores del club, resto de calle), talla ±10 %, anchura y clips de reposo distintos ya venían del 16-11.

## 2. Césped (`visor/cesped_comun.gdshaderinc`, `cesped_textura.gd`, `cesped_capas.gd`, `stadium_builder_p4.gd`)

- **Franjas según el sentido de la cortadora** (`eje_corte`, `CespedTextura.eje_corte`): la franja cambia de tono cuando se la mira en el
  sentido en que pasó la cortadora. Antes el brillo se tomaba SIEMPRE de la vista en Z, y la cámara de TV mira en X: con «rayas» las
  franjas salían a medio gas justo en la cámara del partido. Ahora «rayas» (y liso, mitades, espiga) van en X, «rayasH» en Z y los dibujos
  mixtos (damero, círculos, cruz, rombos, abanico, diagonal) en diagonal. `marca_franjas` 0,26 → 0,30.
- **Desgaste** (`cesped_desgaste` + `cesped_grano`): primero césped pisado (seco y amarillento) y en el centro de la calva TIERRA con matas
  sueltas, en la boca de cada arco (óvalo de ~11 × 6 m pegado a la línea), el punto de penal con su halo de ~2,5 m y el centro del campo
  (calva de ~1,6 m y halo de 4,5 m). Antes era un tinte marrón muy suave que no se distinguía desde la TV.
- **Manchas a gran escala** más marcadas (±16 % en vez de ±12 %, y las zonas secas pesan 0,6 en vez de 0,5) y **saturación** 0,74 → 0,68.
- **Coste del césped barato (MÍNIMA/ULTRA BAJA)**: MENOS que antes. El desgaste usaba un `fbm` de 4 ruidos en CADA píxel del campo; ahora
  son 2 ruidos y solo dentro de las calvas (rama `if (gast > 0.0)`; el resto del campo solo hace la cuenta de distancias). Lo mismo para el
  shader completo y las capas de hierba (las tres usan la misma función, así la hierba en relieve casa con el suelo).

## Cifras de dibujo (cámara de TV «Transmisión», llvmpipe, 1280x720)

`pruebas/medir_partido.tscn` (club 3 de la liga, modo rendimiento encendido como en el juego instalado):

| País | Nivel | Antes: llamadas / triángulos / objetos | Después |
|---|---|---|---|
| ITA | ULTRA BAJA | 94 / 142.216 / 220 | 98 / 150.075 / 197 |
| ITA | ALTA | 677 / 1.215.635 / 818 | 678 / 1.219.230 / 819 |
| ENG | ULTRA BAJA | 67 / 91.564 / 203 | 66 / 90.200 / 205 |
| ENG | ALTA | 587 / 917.109 / 732 | 586 / 914.173 / 730 |

`pruebas/captura_publico_cesped.tscn` (media de 24 fotogramas con la cámara de TV, del 36 al 59):

| Cruce | Nivel | Antes | Después |
|---|---|---|---|
| ITA-ARG (Navigli FC, «damGrande») | MÍNIMA | 84 / 117.149 / 90 | 77 / 127.555 / 84 |
| ITA-ARG | ALTA | 144 / 298.784 / 150 | 144 / 299.367 / 149 |
| ENG-BRA (Eastlands FC, «diagonal») | MÍNIMA | 125 / 147.479 / 127 | 104 / 139.610 / 108 |
| ENG-BRA | ALTA | 177 / 823.578 / 178 | 176 / 828.179 / 178 |
| JPN-FRA (Yokohama Bay, «circular») | MÍNIMA | 117 / 201.845 / 119 | 115 / 197.614 / 118 |
| JPN-FRA | ALTA | 446 / 1.533.628 / 451 | 446 / 1.533.921 / 452 |

Ninguna pieza nueva: las diferencias (±10 %) son del encuadre, porque la cámara sigue el balón y el partido no repite igual entre dos
procesos en MÍNIMA. En ALTA, donde sí repite, las cifras coinciden (±0,5 %). Los FPS reales, en la laptop del dueño.

## Capturas (`capturas_publico_cesped_2026-11-17/`)

`herramientas/captura.sh res://pruebas/captura_publico_cesped.tscn` (Forward+, 1280x720, `PAIS=ITA,ARG CALIDAD=minima|alta`):
`tv_*` = cámara de TV «Transmisión» (la de por defecto) en el fotograma 60; `lejana_*` = la cámara «TV lejana» del juego (enseña más
grada) 40 fotogramas después. Cada `*_antes_despues.jpg` va lado a lado (antes a la izquierda), reducido a 1280 px, calidad 80. El
«antes» se sacó de una copia de la rama base (72d05e3c, con el HUD de TV nuevo) sin estos cambios, así el marcador es el mismo.

Mejores: `lejana_eng_bra_minima_antes_despues.jpg` (grada celeste vacía → masa oscura; calva en la boca del arco),
`lejana_ita_arg_minima_antes_despues.jpg` (grada granate y calva del centro), `tv_eng_bra_alta_antes_despues.jpg` (franjas diagonales y
verde más natural), `lejana_jpn_fra_alta_antes_despues.jpg` (huecos azules de la grada en sombra).

## Pruebas

- Banco, sección nueva `_probar_publico_cesped` (grupo «estadio»): grupo lleno = color del club, más asientos libres = más oscuro sin irse a
  negro, el alfa (marca del sector visitante) no se toca; eje del corte de cada dibujo unitario y «rayas»/«rayasH» en X/Z.
- `pruebas/bancos/estadio_3d.gd` (banco especializado con pantalla): la comprobación «85 % de butacas con el color del club» acepta
  también el color del club en sombra (`GradaButacas.color_vacia`). Cambio intencionado.

## Pendiente

- Veredicto del dueño con las capturas: en ALTA el cambio de la grada es suave; si quiere más, subir el 0,58 de `color_vacia` o bajar el
  hueco entre vecinos (34 %) en `_hinchas_del_asiento`.
- Más figuras en MÍNIMA (cuesta triángulos: 45 por persona) o el público 2D (`Publico2D`, prototipo apagado) para densidad real.
- Cielo HDRI y planos al público: siguen fuera (ver `TV_CESPED_LUZ_2026-11-16.md` e `INFORME_AAA_2026-11-16.md`).
