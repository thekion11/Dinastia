# Sesión 6 (26-10-2026) — recursos libres, líneas suaves, «¿por qué?», logros largos y Novedades

Rama `ccr-76d707c5-dwse9h-s6`. Encargo aprobado por el dueño: filas 7, 15 y 16 de
`investigacion_s4/03_propuesta.md` y, del plan §10, los logros a largo plazo y la pantalla «Novedades».
No se tocaron las zonas de las sesiones 3 y 5 ni la lista de archivos reservados.

## 1. Fila 7: quitar los 🟡 de licencias (parcial: 3 de los modelos; el resto, anotado)

| Recurso 🟡 | Qué se hizo | Estado |
|---|---|---|
| `complejo_residencial.glb` (Sketchfab, sin licencia, texturas con nombre de fotos de redes) | La Casa Grande de la finca son ahora **cuatro bloques de KayKit City Builder Bits 1.0** (`building_E…H`, CC0). Licencia leída en el repositorio (commit `63976910`), copiada a `assets/ciudad/kaykit/LICENSE.txt`. 430 KB: **fuera de LFS** con excepción en `.gitattributes` (nada que subir por LFS). Los bloques miden lo de un bloque de pisos (~38 m de alto, 2 filas, fachada al portón), no se estiran a la finca | 🔴→ ya no se usa; excluido de las 4 exportaciones |
| `estadio.obj` (sin origen) | Solo era el respaldo cuando no llega perfil de estadio: ahora es una maqueta de 4 gradas de caja alrededor de un campo de 105 × 68 (`city_builder_p4.gd`) | excluido de las exportaciones |
| `farola.obj` (sin origen) | Ya no se cargaba (las farolas son por código desde el 12-9); quitada la constante | excluido de las exportaciones |
| `persona_realista.glb` → MPFB2 | **No hecho**: hace falta Blender (no está en el contenedor) y el dueño ya tiene en curso el «modelo B» de MakeHuman | anotado en el plan §8 |
| `anims_futbol/` → CMU | **No encaja ahora**: la licencia de CMU sirve («free for use in research and commercial projects»), pero son BVH con otro esqueleto que hay que retargetear en Blender y no trae regates (sustituiría solo tiros y protestas; las 21 de Gumroad seguirían). Lo barato es la captura de la página de Gumroad (dueño) | anotado en LICENCIAS y en el plan §8 |

Los archivos viejos **siguen en LFS sin tocar** (regla del dueño): solo dejan de usarse y de exportarse
(`export_presets.cfg`, `exclude_filter` de los 4 presets). `docs/05_referencia/LICENCIAS.md` actualizado
(filas nuevas de KayKit, Antialiased Line2D y Debug Menu; «Pendiente antes de vender» punto 2 y 3).
Captura con la cámara real (a pie delante del portón, Forward+): `/tmp/capturas/s6/s6_casa_rumbo0.jpg`.

## 2. Fila 15: Antialiased Line2D y Debug Menu (MIT)

- `addons/antialiased_line2d/` (MIT, Calinou, commit `808343e4`) y su autoload `AntialiasedLine2DTexture` en `project.godot`.
  Ayudante común nuevo `ui/componentes/trazo_suave.gd` (`TrazoSuave.linea/arco/rect/limpiar`): como es un nodo, las
  líneas fijas se crean una vez y se rehacen solo al cambiar datos o tamaño.
  - `ui/componentes/radar_atributos.gd`: malla (detrás del relleno) y borde suaves; puntos con `antialiased`.
  - `ui/radar_partido.gd`: fondo, borde, medio campo, círculo y áreas fijos y detrás de los puntos; jugadores y balón con `antialiased`.
  - `ui/componentes/pizarra_tactica.gd` (`CampoDibujado`): las 7 líneas del campo.
  - `ui/componentes/minimapa_ciudad.gd`: la ruta morada son dos líneas suaves entre dos lienzos (calles debajo; marcas, N y flecha encima);
    como el mapa gira cada fotograma, solo se les cambian los puntos. Calles y marcas: `antialiased` de Godot.
- `addons/debug_menu/` (MIT, commit `ff124615`): el contador de FPS de Ajustes (`ui/componentes/contador_fps.gd`) lo lleva dentro
  en modo compacto; **F9** pasa a detallado (CPU/GPU por fotograma, mín./máx., gráficas) y a oculto. F3, su tecla de fábrica,
  es la táctica rápida del partido (`nucleo/mando.gd`), por eso F9. Si el complemento no carga, queda la etiqueta de siempre.
- Avisos MIT en `addons/LICENCIAS_TERCEROS.txt` (los `.md` se excluyen de la exportación y MIT pide llevar el aviso).
- `debug_menu.gd` mide 480 líneas: es código de terceros y se deja como viene; `herramientas/revisar_lineas.py` excluye
  `addons/` (como ya hacía `pruebas/comprobar_scripts.gd`). **Decisión declarada: el dueño puede revertirla.**

Capturas: ficha con el radar (`s6_ficha_radar.jpg`), pizarra (`s6_pizarra.jpg`), minimapa (`recorte_minimapa.jpg`).

## 3. Fila 16: «¿por qué sube o baja?» en la ficha

La ficha se monta en `ui/principal_p8.gd` (zona de la sesión 3), así que el bloque se engancha desde
`FichaJugadorInfo.pintar_historial` (encima de «Crecimiento por temporada», sale aunque aún no haya temporadas).
Componente nuevo `ui/componentes/ficha_porque.gd`: plegable, con una curva de edad 16-36 (relleno verde «sube»,
rojo «baja», punto en su edad) y tres frases con los números DEL jugador:
- fase de la curva con la regla real de `ProgresoJugador` (17-20 crece más, hasta 23 más despacio, 24-29 quieto, 30 la mitad de los años −1, 31+ −0-3);
- techo: cuánto le falta y, de 19 a 26, que el techo se gasta 0-2 por año si no lo alcanza;
- partidos: cuántos lleva y cuántos le faltan para los puntos de habilidad del cierre (`Entrenamiento.repartir_puntos`: 12, y 8 si tiene ≤21).

`pruebas/ideas/s6_porque.gd` compara la curva y los umbrales con el núcleo (si alguien los cambia, avisa).
Captura: `s6_ficha_porque.jpg` y `recorte_porque.jpg`.

## 4. Plan §10: 30 logros a largo plazo y «Novedades»

**Logros** (`nucleo/logros_largo.gd`, catálogo + medición; añadido a `Logros` sin romper los 20 ni los ocultos):
años al mando (1, 5, 15, 25), partidos (100, 500, 1000) y victorias (50, 250, 500), 10 seguidas, 40 sin perder,
títulos (3, 5, 50), canteranos (5, 40), un goleador con 50 y 150, un jugador con 200 partidos, 50.000 de público,
estadio de 90.000, caja de 10 y 500 M, 50.000 socios, reputación 90, once de media 80, mejor entrenador ×3,
Fair Play y 5 en el equipo ideal de una gala.
- Se ven desde el primer día con su barra («312 / 500»), en la pestaña Logros, debajo de los 20 (`ui/componentes/lista_logros_largo.gd`).
- Partidos y victorias **cuentan jugando y simulando** (decisión del dueño del 26-10): contador nuevo `Logros.carrera`; una partida vieja lo rehace con el cara a cara.
- Los de estado del club (aforo, socios, reputación, caja, once) que ya se cumplían al llegar se apuntan como **«heredado»**, sin aviso.
- Solo dan reconocimiento (aviso y lista), no puntos del árbol: 30 puntos más cambiarían el equilibrio. Se guardan con la partida.
- `pruebas/ideas/s6_logros.gd`: los 30, uno por uno, a un paso de la meta no caen y en la meta sí; heredados; guardado; pantalla.

**Novedades** (`ui/pantallas/pantalla_novedades.gd` + `datos/novedades.json`, notas de la 0.9.0 en 4 secciones y 13 puntos):
botón «✨ Novedades 0.9.0» en el pie del menú de modos, con un punto mientras no se hayan visto (`user://novedades.cfg`);
Esc/B/«Cerrar» la cierran. Cierra M-310 (sin «Novedades») y M-429 (versión sin número visible).
Captura: `s6_novedades.jpg`, `s6_logros_largos.jpg`. Arreglado tras verla: el panel salía arriba a la izquierda
(`set_anchors_preset` conserva el rectángulo de tamaño 0; ahora `set_anchors_and_offsets_preset`).

Traducciones: 106 frases × 8 idiomas con `herramientas/sumar_traducciones.py` (ninguna rechazada).

## 5. Comprobación

- Pruebas nuevas (todas «FIN. 0 fallos»): `s6_recursos`, `s6_porque`, `s6_logros`, `s6_novedades`; además `uipl_textos` y `prueba_contador_fps` (ajustada al Debug Menu).
- Banco entero antes de cada subida: «FIN. 0 fallos» (2.601 comprobaciones).
- Especiales `todo`: «ESPECIALES: todo en orden» (10 de 10: norma, compilación, colisiones del club, partido con motor real, control del equipo, modos, ciudad a pie, balance en 10 temporadas, rendimiento en 20, recorrido de todas las pantallas).
- Capturas (Forward+, cámara real; JPG) en `/tmp/capturas/s6/` (fuera del repo, como pide la regla).

## 6. Sin hacer y por qué

- MPFB2 para `persona_realista.glb` y CMU para `anims_futbol/`: necesitan Blender (y CMU no cubre regates). Anotados en el plan §8.
- `vagabond.obj`, `arco_entrada`, `asientos_lod`, `podio_prensa`, insignias de Canva: fuera del encargo; siguen 🟡.
- El aviso emergente de logro y el registro de noticias muestran el título tal como llega (`noticias_p1.gd`, ya así con los 20 de siempre): `Aviso` lo traduce; la línea del registro no.

## 7. Peticiones a otras zonas

- Sesión 3 (`ui/principal_p8.gd`): nada obligatorio; si se rehace la ficha, mantener la llamada a `FichaJugadorInfo.pintar_historial` (lleva dentro el plegable «¿por qué?»).
- `ui/pantallas/pantalla_ajustes*` (reservado): el texto del contador de FPS podría decir «F9: detallado».

## 8. Segunda tanda: auditoría visual de la ciudad y el estadio (Forward+, cámara real)

Capturas (en `/tmp/capturas/s6/`): mapa de día y de noche, a pie de noche y de día, estadio desde el mapa
lejos y cerca, partido de día y de noche (escenas `pruebas/captura_s6_auditoria_{ciudad,estadio,partido}.tscn`).

- **Arreglado: el estadio se veía como un bloque BLANCO desde la vista por defecto del mapa** (a más de 520 m).
  Causa: el LOD jerárquico de `Optimizar.agrupar` (`visor/optimizar_p1.gd`) ponía una caja «de color medio» a
  cada malla pesada, también a las que SOLO proyectan sombra (`StadiumBuilder._sombra_unica`, con el material
  por defecto, blanco) y cortaba las gradas a 520 m. `_sin_lod()` era un hueco que siempre decía «no»: ahora
  excluye las mallas de solo sombra y todo lo que cuelga de un nodo `sin_corte` (el estadio en el mapa, que ya
  pedía «sin cortes por distancia»). Prueba: `pruebas/ideas/s6_auditoria.gd`; antes/después: `x_normal.jpg` → `x_arreglo.jpg`.
- Visto y sin defectos: ciudad de día y de noche (farolas, ventanas, luces), calle a pie, estadio de cerca
  (gradas, campo, fachada, tienda), partido de día y de noche (ceremonia de salida, focos, vallas).
- Anotado, no arreglado (criterio): el horizonte lejano son cajas muy claras (es el mismo LOD, «un poco más claro
  y sin brillo» a propósito); se lee como maqueta. Si se quiere más color, bajar el aclarado de `_color_medio`.
