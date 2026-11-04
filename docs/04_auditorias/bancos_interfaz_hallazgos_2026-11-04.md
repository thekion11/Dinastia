# Bancos de interfaz (fase 2): lo que encontraron (4-11-2026)

Bancos: `idiomas`, `menu_navegacion`, `accesibilidad_tutorial`, `arranque` (`dinastia-godot/pruebas/bancos/<banco>.gd`; se corren con
`python3 dinastia-godot/herramientas/bancos_especiales.py <banco>`).

## Arreglado al escribirlos
- **Mando con un menú del panel lateral abierto**: L1/R1 (submenú) y L2/R2 (menú) no navegaban, porque `AtajosMenu._input` salía por
  `_capa_modal_encima()` (el propio menú cuenta como capa) antes de llegar a la rama del panel. Ahora usa `_capa_modal_ajena()`.

## Hallazgos abiertos (no son fallos del banco: están medidos y con tope de regresión)
1. **Texto sin traducir en pantallas** (recorrido de todas las pantallas, por idioma): `en`, `de`, `tr` limpios; `pt` 25, `ca` 15, `fr` 11,
   `it` 5, `pl` 1 frases que la heurística toma por castellano (muchas son falsos positivos: nombres de columna de un CSV, «menus», cognados;
   revisar con `RECORRIDO_IDIOMA=<l> RECORRIDO_FALTAN=/tmp/faltan.txt godot --headless --path dinastia-godot res://pruebas/recorrido_pantallas.tscn`).
   Reales a revisar: «hombros» suelto en una frase en portugués, «Escritório (menus)», líneas de retos del día («Não sofras golos»…) en pt.
2. **Escala de texto 160 % en idiomas de palabras largas** (de, fr, tr): ~44 controles se salen por la derecha en 5 pantallas
   (en castellano 0). Ejemplo: «POR · 33 yaş · Lautaro FC · öz» en la ficha del plantel se sale 31 px. Tope actual del banco: 120.
3. **Pruebas de toque sin pantalla**: el viewport sin ventana no entrega ratón ni toques a la interfaz (`Viewport.gui_get_hovered_control` es
   nulo y `push_input` no llega a los botones), así que el banco busca con las reglas del motor el control que recibiría el toque
   (nada tapa los botones del riel, con el central y con un menú abierto) y no el clic real.

## Cifras de los bancos
- `menu_navegacion`: 14 menús, 59 submenús con sección + 11 acciones, Esc/Volver/mando/riel en todos.
- `accesibilidad_tutorial`: contraste WCAG (texto ≥ 7:1, suave ≥ 4,5:1), daltonismo simulado (Machado) en 3 tipos, escala 0,7-1,6, 340 pasos de
  tutorial (8 modos × 4 configuraciones: 1,0/1,6 es, 1,3 de, 1,6 en), lector de pantalla y avisos de sonido.
- `arranque`: 8 modos de club (10 arranques con 3 dificultades en el DT), tutorial de 7 modos, guardar/cargar/Continuar, escenas de entrada.
- `idiomas`: 8 tablas de ~7.400 claves (mismas claves, marcadores `%s/%d`, etiquetas BBCode, glifos), 532 patrones con números, `Idiomas.t`.
