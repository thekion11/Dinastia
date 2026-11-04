# Bancos de interfaz (fase 2): lo que encontraron (4-11-2026)

Bancos: `idiomas`, `menu_navegacion`, `accesibilidad_tutorial`, `arranque` (`dinastia-godot/pruebas/bancos/<banco>.gd`; se corren con
`python3 dinastia-godot/herramientas/bancos_especiales.py <banco>`).

## Arreglado al escribirlos
- **Mando con un menú del panel lateral abierto**: L1/R1 (submenú) y L2/R2 (menú) no navegaban, porque `AtajosMenu._input` salía por
  `_capa_modal_encima()` (el propio menú cuenta como capa) antes de llegar a la rama del panel. Ahora usa `_capa_modal_ajena()`.

## Hallazgos cerrados en el pulido (4-11)
1. **Castellano suelto en pantallas**: eran casi todo falsos positivos del detector (palabras que son también de pt/ca/it/fr/pl: «que», «se», «para», «por»,
   «tu», «del», «una», «semanas»…; y frases ya traducidas que volvían a pasar por `Idiomas.t`). El detector (`COMPARTIDAS` en `recorrido_pantallas.gd`) las descuenta por idioma.
   Real: la frase «La federación convoca sobre: …» (votación de la asamblea) no tenía patrón → añadido en los 8 idiomas. Ahora 0-1 por idioma (tope del banco 3).
2. **Texto al 160 % en de/fr/tr**: los «44 controles que se salen por la derecha» eran falsos positivos (estaban dentro de columnas con desplazamiento horizontal, p. ej. la ficha del
   jugador). Medido bien da 0 en de/fr/tr (y en castellano); el banco lo exige (tope 0 de salidas y 12 cortados).
3. **Pantalla de controles del mando**: el manual gana ancho (acciones de 3-4 líneas a 2), filas alternas con guía, y el aviso del mando 3D en dos líneas.

## Hallazgo abierto
- **Pruebas de toque sin pantalla**: el viewport sin ventana no entrega ratón ni toques a la interfaz (`Viewport.gui_get_hovered_control` es
   nulo y `push_input` no llega a los botones), así que el banco busca con las reglas del motor el control que recibiría el toque
   (nada tapa los botones del riel, con el central y con un menú abierto) y no el clic real.

## Cifras de los bancos
- `menu_navegacion`: 14 menús, 59 submenús con sección + 11 acciones, Esc/Volver/mando/riel en todos.
- `accesibilidad_tutorial`: contraste WCAG (texto ≥ 7:1, suave ≥ 4,5:1), daltonismo simulado (Machado) en 3 tipos, escala 0,7-1,6, 340 pasos de
  tutorial (8 modos × 4 configuraciones: 1,0/1,6 es, 1,3 de, 1,6 en), lector de pantalla y avisos de sonido.
- `arranque`: 8 modos de club (10 arranques con 3 dificultades en el DT), tutorial de 7 modos, guardar/cargar/Continuar, escenas de entrada.
- `idiomas`: 8 tablas de ~7.400 claves (mismas claves, marcadores `%s/%d`, etiquetas BBCode, glifos), 532 patrones con números, `Idiomas.t`.
