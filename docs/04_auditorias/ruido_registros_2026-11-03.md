# Ruido de los registros (3-11-2026, «detectar fallos», orden 20 punto 6)

**Cómo se midió.** `dinastia-godot/herramientas/especiales_ruido.sh todo` es `especiales.sh todo` con una línea más: guarda el registro COMPLETO de cada prueba (184) en `/tmp/ruido/NNN_<nombre>.log`. Luego se juntó todo lo que contiene `ERROR`, `WARNING`, `SCRIPT ERROR`, `leaked`, `Condition … is true`, `Invalid access…`, aunque la prueba terminara en «0 fallos», quitando solo el ruido de la máquina (ALSA sin tarjeta de sonido, V-Sync, llvmpipe). **2.471 líneas, 35 mensajes distintos.** Para repetirlo: ejecutar esa herramienta y agrupar los mensajes cambiando los números por N.

**Los 5 fallos de «especiales» en mi contenedor NO son del código:** `banco_inicio` (hay partidas viejas en `user://partidas`: `Partida.listar()` no está vacío), `presupuesto del partido` (balón de 2.400 triángulos frente a un techo de 50: modelo del balón de esta máquina), `balance en 10 temporadas` (goles 3,2-3,4 por partido en t7-t9: sale del `meta_global.json` heredado de mis corridas) y `pruebas visuales` (llvmpipe, rojo 20/20 también en la base). La CI limpia de la rama del líder (`2e8a722`, ejecución 1222) está en verde con las 150 especiales. Salvo `ceremonia de carrera`, que sí era un fallo real y está arreglado.

## Arreglado (PR #139 y el siguiente)
| ruido | veces | causa real | arreglo |
|---|---|---|---|
| `assigned_animation on Nil` (`AnclaSuelo._process`) | 650 | el ancla seguía procesando con el reproductor ya tirado; hacía **fallar** «ceremonia de carrera» | se apaga sola si lo anclado ya no existe |
| `no 'meta' values with the key 'mando_tactil'` | 294 | `get_meta(x, null)` escribe ERROR si falta (Godot 4.7) | `has_meta` primero, en los 8 sitios del juego |
| `Signal 'movimiento' already connected` | 11 | `Noticias.conectar` reconecta sin preguntar | `Conexion.una_vez` en los 10 sitios |
| `String formatting error: unsupported format character` | 4 | dos `%` sueltos en frases formateadas («+5 % por cerrarlo en persona», «−5 % en su próxima negociación»), rotos en los 9 idiomas | `%%` en la clave y las 8 traducciones; revisadas las 769 llamadas `Idiomas.t(…) %` |
| `Error calling deferred method animar_pop … Object to Object` | 1 | llamada diferida con el móvil ya cerrado | se comprueba que sigue vivo al ejecutarse |
| `grab_focus` fuera del árbol (diferido) | 2 | 9 sitios daban el foco en diferido sin mirar | `FocoSeguro.dar` (ya existía en la entrada) |
| `Can't change the size of a SubViewport … stretch` (`mando_giratorio_p1`) | 3 | fijaba un tamaño que su contenedor ignora | se quitó la línea |
| `Nodes with non-equal opposite anchors` (`entrada_campeonato`) | 2 | fijaba el tamaño con anclajes abiertos | anclaje arriba-izquierda cuando el padre no es un `Control` |

## Pendiente, con su porqué
| ruido | veces | dónde | por qué queda |
|---|---|---|---|
| `texture_2d_get: Parameter "t" is null` | 1.305 | `repetición del gol` | solo con el renderizador ficticio de `--headless` (pide la textura de un visor que no dibuja); en pantalla no sale. Se podría callar saltando esa prueba en headless |
| `material_get_instance_shader_parameters / material_set_shader: Parameter "material" is null` | 6 | `guion f2p_prologo` | igual: renderizador ficticio |
| `Condition "p.d == 0" … unproject_position` | 12 | `m4_minijuegos_3d`, `minijuego_penales.gd:135` | probé `is_position_behind` y el tamaño del visor: no lo quitan, así que no se entiende todavía (¿cámara sin colocar en headless?). No se tocó |
| `Lambda capture at index 0 was freed` | 8 | `recorrido de pantallas` (justo tras «menú historia/8» o «gente/4», según el reloj) | una lambda de un temporizador o tween cuyo primer capturado se tiró; no sale con `RECORRIDO_SOLO=historia`, solo tras pantallas anteriores; sin traza (la llama C++). Pendiente: reproducirlo con las pantallas previas y mirar los `create_timer`/`tween_callback` |
| `grab_focus … !is_inside_tree()` | 2 | `plan_costumbre`, tras «FIN» | sale al cerrar, de un `grab_focus` diferido de otro sitio distinto de los 9 arreglados |
| `ObjectDB instances were leaked at exit` / `resources still in use at exit` / `RID allocations … leaked` / `Pages in use exist at exit in PagedAllocator` | 74 + 72 + 6 | 6 pruebas largas (`auditoría técnica`, `partidas viejas abren`, `simular temporada con barra`, `modos de juego`, `menú ciudad a pie`, `estadio y ciudad por partes`) | las pruebas terminan con `quit()` sin liberar la escena (38.187 objetos vivos en la peor). Es de la prueba, no del juego: la auditoría técnica ya comprueba nodos huérfanos al abrir y cerrar la principal |
| `1 ObjectDB instance was leaked` / `1 RID of type "CanvasItem" was leaked` | 4 | `pasos y guardia del portero`, `ent1_unico_camino`, `emergencias y sirenas`, `p6_boton_e_minimapa` | un objeto suelto en cada una; sin importancia visible, sin investigar |
| `Camera2D overridden to physics process mode` | 1 | `minijuego retro 5v5` | aviso de Godot por la interpolación de física con esa cámara: se podría fijar `process_callback` a física |
| `Nodes with non-equal opposite anchors` | 3 | `controles táctiles del partido` (`tac_controles.gd`) | lo monta la prueba con `Control.new()` colgado de un `Node` |
| `An input event object is being parsed more than once` | 1 | `f0m_visor_ciudad` | la prueba reutiliza el mismo evento |
| `decompress err != 1`, `la huella no cuadra (archivo dañado)`, `SONDA_REG_…`, `no hay sección «no_existe»` | 1 + 1 + 1 + 1 | `exim`, `sav`, `PantallaPlantel` | **esperados**: las pruebas provocan el aviso a propósito (archivo dañado, sonda, sección inexistente) |
| `Failed to load cached shader, recompiling` | 1 | una prueba | caché de shaders de otra versión del motor en `user://`; se arregla sola |
| `ALSA lib …`, `All audio drivers failed` | – | todas | la máquina no tiene tarjeta de sonido |
