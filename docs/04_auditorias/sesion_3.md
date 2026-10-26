# Sesión 3 (26-10-2026) — rama `ccr-76d707c5-dwse9h-s3`

Tareas: rendimiento de menús, peatones que esquivan (ciudad), textos fijos del núcleo a claves traducibles y las
peticiones 2 y 8 de la sesión 2. Cada bloque con su prueba en `pruebas/ideas/s3_*` y el banco en «FIN. 0 fallos».

## 1. Rendimiento de menús: nodos creados por vuelta

**Medida.** `fugas_menus` solo mide lo que queda vivo (no crece). La prueba nueva `pruebas/ideas/s3_rotacion_menus.gd`
hereda su vuelta (todos los menús y submenús, cada chip, 8 fichas) y cuenta cada nodo que entra en el árbol
(`node_added`), separando los NUEVOS de los que solo se mudan de sitio (la pantalla de menú mueve el contenido de la
Principal a su hueco y lo devuelve), y apunta quién lo crea con `Engine.capture_script_backtraces()` (4 funciones de `ui/`).

| | antes | después |
|---|---:|---:|
| nodos NUEVOS por vuelta | 111 178 | 17 447 (−84 %) |
| nodos que se mudan de sitio | 54 960 | 32 310 |
| total que entra en el árbol | 166 138 | 49 757 (−70 %) |

**Causa.** `Principal._refrescar()` (en `ui/principal_p9.gd`) repintaba en CADA refresco —cada chip, cada submenú—
la tabla de la liga (~23 000 nodos por vuelta), el plantel (~26 000), el mercado (~26 000), el tablero de inicio
(~11 000) y la ficha (~10 000) aunque estuvieran ocultos. El resto de pestañas ya iban por `_perezoso()`.

**Arreglo.** Esas cinco pasan también por `_perezoso()`: si se ven, se pintan en el acto como antes; si no, quedan
pendientes y `_pintar_pendientes()` las pinta (y traduce) el primer fotograma en que se ven, con los datos de ese
momento. El título de la tabla se sigue poniendo siempre (es un texto). En `_ver_ficha()` (principal_p8) una ficha
pedida a mano borra la diferida, para que nunca la pise una vieja. Lo que se ve no cambia.

**Comprobado:** `s3_rotacion_menus` (exige ≤ la mitad de la línea base), `fugas_menus`, `uipl_plantel`, `uipl_textos`,
`uifi_gestion`, `uico_competicion`, `uiid_identidad`, mini-banco gestion/competicion/textos y
`captura_verificar_tabla|mercado|plantel` (sus dos «MAL» —verde daltónico del mercado y cabecera NOMBRE— fallan igual
sin el cambio: son de esas pruebas viejas de captura, no de esto).
