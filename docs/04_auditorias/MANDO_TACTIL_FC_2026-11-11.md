# Mando táctil del partido al estilo FC Mobile (pedido del dueño, 11-11-2026)

Referencia que mandó el dueño: la guía de juego de EA (`ea.com/es-mx/inside-ea/news/gameplay-guide`) y dos capturas de
FC Mobile (CON balón y SIN balón). «Yo copiaría lo mismo; los colores del izquierdo son más bonitos y modernos». Se copia
el ESQUEMA (posición, función y gestos, que son la convención del género); el dibujo y los textos son nuestros (sin logos ni
arte de EA). Los vídeos de la guía están en YouTube y no se pudieron ver desde el contenedor: lo de abajo sale del texto de la
guía y de las capturas.

## Lo que hay hoy (`ui/componentes/controles_tactiles.gd`)
Stick flotante a la izquierda (bien, igual que FC Mobile). A la derecha, un arco de 6-7 botones (Pase, Tiro, Centro, Al hueco,
Cambiar, Sprint y Mod), con colores sueltos (Al hueco verde, Sprint blanco) y etiquetas dobles («Pase/Presión»). Es más que el
esquema de 4 de FC Mobile y no tiene sus gestos por botón.

## Lo que se pide: SIEMPRE 4 botones en las MISMAS 4 posiciones; cambian de función y color con la posesión

Disposición (esquina inferior derecha, como en las capturas): **grande abajo a la derecha**, **mediano abajo a la izquierda**,
**mediano arriba a la izquierda**, **mediano arriba a la derecha**.

| Posición | CON balón | Color | SIN balón | Color |
|---|---|---|---|---|
| Grande, abajo a la derecha | **SPRINT Y REGATE** | verde | **SPRINT Y ENTRADA** | blanco |
| Abajo a la izquierda | **PASE** | azul cian | **CAMBIAR** | azul cian |
| Arriba a la izquierda | **AL HUECO** | amarillo | **2.º DEFENSOR** | amarillo |
| Arriba a la derecha | **TIRO** | rojo | **BARRIDA** | naranja/rojo |

Estilo: fondo oscuro translúcido, ARO de color, texto en MAYÚSCULAS. En el aro, TRIANGULITOS del color del botón que indican
hacia dónde se puede deslizar (como en las capturas). Al cambiar la posesión, transición corta (~0,15 s) de etiqueta y color.

## Gestos por botón (de la guía de EA; acciones que YA existen en `Mando.MAPA`)

**SPRINT Y REGATE** (`jugar_sprint`, `jugar_regate`, filigranas): mantener = sprint · tocar o deslizar en una dirección = regate
o finta hacia allí · deslizar abajo = adelantar el balón · deslizar a la izquierda = parada en seco.

**PASE** (`jugar_pase`, `jugar_centro`, `jugar_pase_largo`): tocar = pase raso · deslizar arriba = pase elevado · deslizar abajo
= pase y correr (pared) · doble toque = pase picado. Cerca del área por la banda: deslizar arriba = centro, a la derecha =
centro bajo, a la izquierda = centro raso (así desaparece el botón de Centro).

**AL HUECO** (`jugar_filtrado`): tocar = al hueco raso · deslizar arriba = al hueco elevado · doble toque = picado.

**TIRO** (`jugar_tiro`, `jugar_mod`): tocar o mantener = tiro (la fuerza va con lo que se mantiene) · deslizar abajo = tiro
colocado (rosca) · deslizar arriba = vaselina · deslizar a la izquierda = amago de tiro.

**SPRINT Y ENTRADA** (sin balón): mantener = correr y presionar al que lleva el balón si está cerca · tocar = entrada.

**CAMBIAR**: tocar = el compañero mejor colocado (como hoy). Ajustes: cambio automático / manual / solo en balones aéreos.

**2.º DEFENSOR** (`jugar_mod` sin balón): mantener = el compañero más cercano presiona · deslizar abajo = salida del portero
(`jugar_filtrado` sin balón).

**BARRIDA** (`jugar_centro` sin balón): tocar = entrada deslizante · en tu mitad y con el balón suelto = despeje (`jugar_tiro`).

Se conservan: stick flotante, botón II de pausa, Ajustes → Dispositivo (tamaño, opacidad, separación, modo
Botones/Gestos/Ambos, zurdo), las medidas (Pase y Tiro ≥ 10 mm, el resto ≥ 7 mm, ≥ 2 mm entre bordes), el vertical (sesión 8)
y que el mando físico y el teclado sigan igual (el táctil solo pulsa acciones del InputMap).

## Cómo se comprueba
- Capturas en Forward+ a 2400×1080 y 1080×2400, con balón y sin balón, en partidos de 2 clubes de países distintos.
- Prueba del banco: 4 botones a la vez, posiciones fijas, sin solaparse, tamaños en mm, y que cada gesto pulse la acción correcta.
- `mem_menu_estadio` en 0 y el banco en «FIN. 0 fallos».
- El veredicto final es del dueño en su teléfono (`GUIA_PRUEBA_TELEFONO_2026-11-11.md`).
